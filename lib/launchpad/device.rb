require 'portmidi'

require 'launchpad/errors'
require 'launchpad/midi_codes'
require 'launchpad/version'

module Launchpad
  
  class Device
    
    include MidiCodes
    
    # Initializes the launchpad
    # {
    #   :device_name  => Name of the MIDI device to use, optional, defaults to Launchpad
    #   :input        => true/false, whether to use MIDI input for user interaction, optional, defaults to true
    #   :output       => true/false, whether to use MIDI output for data display, optional, defaults to true
    # }
    def initialize(opts = nil)
      opts = {
        :device_name  => 'Launchpad',
        :input        => true,
        :output       => true
      }.merge(opts || {})
      
      Portmidi.start
      
      if opts[:input]
        input_device = Portmidi.input_devices.select {|device| device.name == opts[:device_name]}.first
        raise NoSuchDeviceError.new("MIDI input device #{opts[:device_name]} doesn't exist") if input_device.nil?
        begin
          @input = Portmidi::Input.new(input_device.device_id)
        rescue RuntimeError => e
          raise DeviceBusyError.new(e)
        end
      end
      
      if opts[:output]
        output_device = Portmidi.output_devices.select {|device| device.name == opts[:device_name]}.first
        raise NoSuchDeviceError.new("MIDI output device #{opts[:device_name]} doesn't exist") if output_device.nil?
        begin
          @output = Portmidi::Output.new(output_device.device_id)
        rescue RuntimeError => e
          raise DeviceBusyError.new(e)
        end
        reset
      end
    end
    
    # Resets the launchpad - all settings are reset and all LEDs are switched off
    def reset
      output(Status::CC, Status::NIL, Status::NIL)
    end
    
    # Lights all LEDs (for testing purposes)
    # takes an optional parameter brightness (:off/:low/:medium/:high, defaults to :high)
    def test_leds(brightness = :high)
      brightness = brightness(brightness)
      if brightness == 0
        reset
      else
        output(Status::CC, Status::NIL, Velocity::TEST_LEDS + brightness)
      end
    end
    
    # Changes a single LED
    # type   => one of :grid, :up, :down, :left, :right, :session, :user1, :user2, :mixer, :scene1 - :scene8
    # opts => {
    #   :x      => x coordinate (0 based from top left, mandatory if type is :grid)
    #   :y      => y coordinate (0 based from top left, mandatory if type is :grid)
    #   :red    => brightness of red LED (0-3, optional, defaults to 0)
    #   :green  => brightness of red LED (0-3, optional, defaults to 0)
    #   :mode   => button behaviour (:normal, :flashing, :buffering, optional, defaults to :normal)
    # }
    def change(type, opts = nil)
      opts ||= {}
      status = %w(up down left right session user1 user2 mixer).include?(type.to_s) ? Status::CC : Status::ON
      output(status, note(type, opts), velocity(opts))
    end
    
    # Changes all LEDs at once
    # velocities is an array of arrays, each containing a
    # color value calculated using the formula
    # color = 16 * green + red
    # with green and red each ranging from 0-3
    # first the grid, then the scene buttons (top to bottom), then the top control buttons (left to right), maximum 80 values
    def change_all(*colors)
      # ensure that colors is at least and most 80 elements long
      colors = colors.flatten[0..79]
      colors += [0] * (80 - colors.size) if colors.size < 80
      # HACK switch off first grid LED to reset rapid LED change pointer
      output(Status::ON, 0, 0)
      # send colors in slices of 2
      colors.each_slice(2) do |c1, c2|
        output(Status::MULTI, velocity(c1), velocity(c2))
      end
    end
    
    # Switches LEDs marked as flashing on (when using custom timer for flashing)
    def flashing_on
      output(Status::CC, Status::NIL, Velocity::FLASHING_ON)
    end
    
    # Switches LEDs marked as flashing off (when using custom timer for flashing)
    def flashing_off
      output(Status::CC, Status::NIL, Velocity::FLASHING_OFF)
    end
    
    # Starts flashing LEDs marked as flashing automatically (stop by calling #flashing_on or #flashing_off)
    def flashing_auto
      output(Status::CC, Status::NIL, Velocity::FLASHING_AUTO)
    end
    
    #   def start_buffering
    #     output(CC, 0x00, 0x31)
    #     @buffering = true
    #   end
    #   
    #   def flush_buffer(end_buffering = true)
    #     output(CC, 0x00, 0x34)
    #     if end_buffering
    #       output(CC, 0x00, 0x30)
    #       @buffering = false
    #     end
    #   end
    
    # Reads user actions (button presses/releases) that aren't handled yet
    # [
    #   {
    #     :timestamp  => integer indicating the time when the action occured
    #     :state      => :down/:up, whether the button has been pressed or released
    #     :type       => which button has been pressed, one of :grid, :up, :down, :left, :right, :session, :user1, :user2, :mixer, :scene1 - :scene8
    #     :x          => x coordinate (0-7), only set when :type is :grid
    #     :y          => y coordinate (0-7), only set when :type is :grid
    #   }, ...
    # ]
    def read_pending_actions
      Array(input).collect do |midi_message|
        (code, note, velocity) = midi_message[:message]
        data = {
          :timestamp  => midi_message[:timestamp],
          :state      => (velocity == 127 ? :down : :up)
        }
        data[:type] = case code
        when Status::ON
          case note
          when SceneButton::SCENE1 then :scene1
          when SceneButton::SCENE2 then :scene2
          when SceneButton::SCENE3 then :scene3
          when SceneButton::SCENE4 then :scene4
          when SceneButton::SCENE5 then :scene5
          when SceneButton::SCENE6 then :scene6
          when SceneButton::SCENE7 then :scene7
          when SceneButton::SCENE8 then :scene8
          else
            data[:x] = note % 16
            data[:y] = note / 16
            :grid
          end
        when Status::CC
          case note
          when ControlButton::UP       then :up
          when ControlButton::DOWN     then :down
          when ControlButton::LEFT     then :left
          when ControlButton::RIGHT    then :right
          when ControlButton::SESSION  then :session
          when ControlButton::USER1    then :user1
          when ControlButton::USER2    then :user2
          when ControlButton::MIXER    then :mixer
          end
        end
        data
      end
    end
    
    private
    
    def input
      raise NoInputAllowedError if @input.nil?
      @input.read(16)
    end
    
    def output(*args)
      raise NoOutputAllowedError if @output.nil?
      @output.write([{:message => args, :timestamp => 0}])
      nil
    end
    
    def note(type, opts)
      case type
      when :up      then ControlButton::UP
      when :down    then ControlButton::DOWN
      when :left    then ControlButton::LEFT
      when :right   then ControlButton::RIGHT
      when :session then ControlButton::SESSION
      when :user1   then ControlButton::USER1
      when :user2   then ControlButton::USER2
      when :mixer   then ControlButton::MIXER
      when :scene1  then SceneButton::SCENE1
      when :scene2  then SceneButton::SCENE2
      when :scene3  then SceneButton::SCENE3
      when :scene4  then SceneButton::SCENE4
      when :scene5  then SceneButton::SCENE5
      when :scene6  then SceneButton::SCENE6
      when :scene7  then SceneButton::SCENE7
      when :scene8  then SceneButton::SCENE8
      else
        x = (opts[:x] || -1).to_i
        y = (opts[:y] || -1).to_i
        raise NoValidGridCoordinatesError.new("you need to specify valid coordinates (x/y, 0-7, from top left), you specified: x=#{x}, y=#{y}") if x < 0 || x > 7 || y < 0 || y > 7
        y * 16 + x
      end
    end
    
    def velocity(opts)
      color = if opts.is_a?(Hash)
        red = brightness(opts[:red] || 0)
        green = brightness(opts[:green] || 0)
        16 * green + red
      else
        opts.to_i
      end
      flags = case opts[:mode]
      when :flashing  then  8
      when :buffering then  0
      else                  12
      end
      color + flags
    end
    
    def brightness(brightness)
      case brightness
      when 0, :off            then 0
      when 1, :low,     :lo   then 1
      when 2, :medium,  :med  then 2
      when 3, :high,    :hi   then 3
      else
        raise NoValidBrightnessError.new("you need to specify the brightness as 0/1/2/3, :off/:low/:medium/:high or :off/:lo/:hi, you specified: #{brightness}")
      end
    end
    
  end
  
end
