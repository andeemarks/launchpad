require 'portmidi'

require 'launchpad/errors'
require 'launchpad/logging'
require 'launchpad/midi_codes'
require 'launchpad/version'

module Launchpad
  
  # This class is used to exchange data with the launchpad.
  # It provides methods to light LEDs and to get information about button presses/releases.
  # 
  # Example:
  # 
  #   require 'launchpad/device'
  #   
  #   device = Launchpad::Device.new
  #   device.test_leds
  #   sleep 1
  #   device.reset
  #   sleep 1
  #   device.change :grid, :x => 4, :y => 4, :red => :high, :green => :low
  class Device
    
    include Logging
    include MidiCodes

    MK2_DEVICE_NAME = 'Launchpad MK2 MIDI 1'

    CODE_NOTE_TO_DATA_TYPE = {
      [Status::ON, SceneButton::SCENE1]     => :scene1,
      [Status::ON, SceneButton::SCENE2]     => :scene2,
      [Status::ON, SceneButton::SCENE3]     => :scene3,
      [Status::ON, SceneButton::SCENE4]     => :scene4,
      [Status::ON, SceneButton::SCENE5]     => :scene5,
      [Status::ON, SceneButton::SCENE6]     => :scene6,
      [Status::ON, SceneButton::SCENE7]     => :scene7,
      [Status::ON, SceneButton::SCENE8]     => :scene8,
      [Status::CC, ControlButton::UP]       => :up,
      [Status::CC, ControlButton::DOWN]     => :down,
      [Status::CC, ControlButton::LEFT]     => :left,
      [Status::CC, ControlButton::RIGHT]    => :right,
      [Status::CC, ControlButton::SESSION]  => :session,
      [Status::CC, ControlButton::USER1]    => :user1,
      [Status::CC, ControlButton::USER2]    => :user2,
      [Status::CC, ControlButton::MIXER]    => :mixer
    }.freeze

    TYPE_TO_NOTE = {
      :up       => ControlButton::UP,
      :down     => ControlButton::DOWN,
      :left     => ControlButton::LEFT,
      :right    => ControlButton::RIGHT,
      :session  => ControlButton::SESSION,
      :user1    => ControlButton::USER1,
      :user2    => ControlButton::USER2,
      :mixer    => ControlButton::MIXER,
      :scene1   => SceneButton::SCENE1,
      :scene2   => SceneButton::SCENE2,
      :scene3   => SceneButton::SCENE3,
      :scene4   => SceneButton::SCENE4,
      :scene5   => SceneButton::SCENE5,
      :scene6   => SceneButton::SCENE6,
      :scene7   => SceneButton::SCENE7,
      :scene8   => SceneButton::SCENE8
    }.freeze

    # Initializes the launchpad device. When output capabilities are requested,
    # the launchpad will be reset.
    # 
    # Optional options hash:
    # 
    # [<tt>:input</tt>]             whether to use MIDI input for user interaction,
    #                               <tt>true/false</tt>, optional, defaults to +true+
    # [<tt>:output</tt>]            whether to use MIDI output for data display,
    #                               <tt>true/false</tt>, optional, defaults to +true+
    # [<tt>:input_device_id</tt>]   ID of the MIDI input device to use,
    #                               optional, <tt>:device_name</tt> will be used if omitted
    # [<tt>:output_device_id</tt>]  ID of the MIDI output device to use,
    #                               optional, <tt>:device_name</tt> will be used if omitted
    # [<tt>:device_name</tt>]       Name of the MIDI device to use,
    #                               optional, defaults to "Launchpad"
    # [<tt>:logger</tt>]            [Logger] to be used by this device instance, can be changed afterwards
    # 
    # Errors raised:
    # 
    # [Launchpad::NoSuchDeviceError] when device with ID or name specified does not exist
    # [Launchpad::DeviceBusyError] when device with ID or name specified is busy
    def initialize(opts = nil)
      @input = nil
      @output = nil
      opts = {
        :input        => true,
        :output       => true
      }.merge(opts || {})
      
      self.logger = opts[:logger]
      logger.debug "initializing Launchpad::Device##{object_id} with #{opts.inspect}"

      Portmidi.start
      
      @input = create_device!(Portmidi.input_devices, Portmidi::Input,
        :id => opts[:input_device_id],
        :name => opts[:device_name]
      ) if opts[:input]
      @output = create_device!(Portmidi.output_devices, Portmidi::Output,
        :id => opts[:output_device_id],
        :name => opts[:device_name]
      ) if opts[:output]
    end
    
    # Closes the device - nothing can be done with the device afterwards.
    def close
      logger.debug "closing Launchpad::Device##{object_id}"
      @input.close unless @input.nil?
      @input = nil
      @output.close unless @output.nil?
      @output = nil
    end
    
    # Determines whether this device has been closed.
    def closed?
      !(input_enabled? || output_enabled?)
    end
    
    # Determines whether this device can be used to read input.
    def input_enabled?
      !@input.nil?
    end
    
    # Determines whether this device can be used to output data.
    def output_enabled?
      !@output.nil?
    end
    
    # Changes a single LED.
    # 
    # Parameters (see Launchpad for values):
    # 
    # [+type+] type of the button to change
    # 
    # Optional options hash (see Launchpad for values):
    # 
    # [<tt>:x</tt>]     x coordinate
    # [<tt>:y</tt>]     y coordinate
    # [<tt>color</tt>]  color of the LED (value between 0 and 127 inclusive)
    #                   optional, defaults to <tt>:off</tt>
    # 
    # Errors raised:
    # 
    # [Launchpad::NoValidGridCoordinatesError] when coordinates aren't within the valid range
    # [Launchpad::NoValidColorError] when color value isn't within the valid range
    # [Launchpad::NoOutputAllowedError] when output is not enabled
    def change(type, opts = nil)
      opts ||= {}
      status = %w(up down left right session user1 user2 mixer).include?(type.to_s) ? Status::CC : Status::ON
      output(status, note(type, opts), velocity(opts))
    end

    SYSEX_HEADER = [240, 0, 32, 41, 2, 24]
    SYSEX_FOOTER = [247]

    def pulse1(x, y, color_key)
      note = note(:grid, {:x => x, :y => y})
      output_sysex(SYSEX_HEADER + [40, 0, note, color_key] + SYSEX_FOOTER)
    end

    def pulsen(notes, color_key)
      notes.each { |coord|
        note = note(:grid, {:x => coord[0], :y => coord[1]})
        output_sysex(SYSEX_HEADER + [40, 0, note, color_key] + SYSEX_FOOTER)
      }
    end
    
    def flash1(x, y, color_key)
      note = note(:grid, {:x => x, :y => y})
      output_sysex(SYSEX_HEADER + [35, 0, note, color_key] + SYSEX_FOOTER)
    end
    
    def flashn(notes, color_key)
      notes.each { |coord|
        note = note(:grid, {:x => coord[0], :y => coord[1]})
        output_sysex(SYSEX_HEADER + [35, 0, note, color_key, 0] + SYSEX_FOOTER)
      }
    end
    
    def scroll(color_key, text, mode)
      output_sysex(SYSEX_HEADER + [20, color_key, mode] + text.chars.map(&:ord) + SYSEX_FOOTER)
    end
    
    def scroll_forever(color_key, text)
      scroll(color_key, text, 1)
    end
    
    def scroll_once(color_key, text)
      scroll(color_key, text, 0)
    end
    
    def scroll_stop()
      output_sysex(SYSEX_HEADER + [20] + SYSEX_FOOTER)
    end

    def light_all(color_key)
      output_sysex(SYSEX_HEADER + [14, color_key] + SYSEX_FOOTER)
    end
    
    def reset_all()
      light_all(0)
    end
    
    def lightn_column(column_keys, color_key)
      column_keys.each { |column_key|
        output_sysex(SYSEX_HEADER + [12, column_key, color_key] + SYSEX_FOOTER)
      }
    end
    
    def light1_column(column_key, color_key)
      output_sysex(SYSEX_HEADER + [12, column_key, color_key] + SYSEX_FOOTER)
    end
    
    def lightn_row(rows_keys, color_key)
      rows_keys.each { |row_key|
      output_sysex(SYSEX_HEADER + [13, row_key, color_key] + SYSEX_FOOTER)
      }
    end
    
    def light1_row(row_key, color_key)
      output_sysex(SYSEX_HEADER + [13, row_key, color_key] + SYSEX_FOOTER)
    end
    
    # Reads user actions (button presses/releases) that haven't been handled yet.
    # This is non-blocking, so when nothing happend yet you'll get an empty array.
    # 
    # Returns:
    # 
    # an array of hashes with (see Launchpad for values):
    # 
    # [<tt>:timestamp</tt>] integer indicating the time when the action occured
    # [<tt>:state</tt>]     state of the button after action
    # [<tt>:type</tt>]      type of the button
    # [<tt>:x</tt>]         x coordinate
    # [<tt>:y</tt>]         y coordinate
    # 
    # Errors raised:
    # 
    # [Launchpad::NoInputAllowedError] when input is not enabled
    def read_pending_actions
      Array(input).collect do |midi_message|
        (code, note, velocity) = midi_message[:message]
        data = {
          :timestamp  => midi_message[:timestamp],
          :state      => (velocity == 127 ? :down : :up)
        }
        data[:type] = CODE_NOTE_TO_DATA_TYPE[[code, note]] || :grid
        if data[:type] == :grid
          data[:x] = (note % 10) - 1
          data[:y] = (note / 10) - 1
        end
        data
      end
    end
    
    private
    
    # Creates input/output devices.
    # 
    # Parameters:
    # 
    # [+devices+]     array of portmidi devices
    # [+device_type]  class to instantiate (<tt>Portmidi::Input/Portmidi::Output</tt>)
    # 
    # Options hash:
    # 
    # [<tt>:id</tt>]    id of the MIDI device to use
    # [<tt>:name</tt>]  name of the MIDI device to use,
    #                   only used when <tt>:id</tt> is not specified,
    #                   defaults to "Launchpad"
    # 
    # Returns:
    # 
    # newly created device
    # 
    # Errors raised:
    # 
    # [Launchpad::NoSuchDeviceError] when device with ID or name specified does not exist
    # [Launchpad::DeviceBusyError] when device with ID or name specified is busy
    def create_device!(devices, device_type, opts)
      logger.debug "creating #{device_type} with #{opts.inspect}, choosing from portmidi devices #{devices.inspect}"
      id = opts[:id]
      if id.nil?
        name = opts[:name] || MK2_DEVICE_NAME
        device = devices.select {|current_device| current_device.name == name}.first
        id = device.device_id unless device.nil?
      end
      if id.nil?
        message = "MIDI device #{opts[:id] || opts[:name]} doesn't exist"
        logger.fatal message
        raise NoSuchDeviceError.new(message)
      end
      device_type.new(id)
    rescue RuntimeError => e
      logger.fatal "error creating #{device_type}: #{e.inspect}"
      raise DeviceBusyError.new(e)
    end
    
    # Reads input from the MIDI device.
    # 
    # Returns:
    # 
    # an array of hashes with:
    # 
    # [<tt>:message</tt>]   an array of
    #                       MIDI status code,
    #                       MIDI data 1 (note),
    #                       MIDI data 2 (velocity)
    #                       and a fourth value
    # [<tt>:timestamp</tt>] integer indicating the time when the MIDI message was created
    # 
    # Errors raised:
    # 
    # [Launchpad::NoInputAllowedError] when output is not enabled
    def input
      if @input.nil?
        logger.error "trying to read from device that's not been initialized for input"
        raise NoInputAllowedError
      end
      @input.read(16)
    end
    
    # Writes data to the MIDI device.
    # 
    # Parameters:
    # 
    # [+status+]  MIDI status code
    # [+data1+]   MIDI data 1 (note)
    # [+data2+]   MIDI data 2 (velocity)
    # 
    # Errors raised:
    # 
    # [Launchpad::NoOutputAllowedError] when output is not enabled
    def output(status, data1, data2)
      output_messages([message(status, data1, data2)])
    end
    
    # Writes several messages to the MIDI device.
    # 
    # Parameters:
    # 
    # [+messages+]  an array of hashes (usually created with message) with:
    #               [<tt>:message</tt>]   an array of
    #                                     MIDI status code,
    #                                     MIDI data 1 (note),
    #                                     MIDI data 2 (velocity)
    #               [<tt>:timestamp</tt>] integer indicating the time when the MIDI message was created
    def output_messages(messages)
      if @output.nil?
        logger.error "trying to write to device that's not been initialized for output"
        raise NoOutputAllowedError
      end
      logger.debug "writing messages to launchpad:\n  #{messages.join("\n  ")}" if logger.debug?
      @output.write(messages)
      nil
    end

    def output_sysex(messages)
      if @output.nil?
        logger.error "trying to write to device that's not been initialized for output"
        raise NoOutputAllowedError
      end
      logger.debug "writing sysex to launchpad:\n  #{messages.join("\n  ")}" if logger.debug?
      @output.write_sysex(messages)
      nil
    end
    
    # Calculates the MIDI data 1 value (note) for a button.
    # 
    # Parameters (see Launchpad for values):
    # 
    # [+type+] type of the button
    # 
    # Options hash:
    # 
    # [<tt>:x</tt>]     x coordinate
    # [<tt>:y</tt>]     y coordinate
    # 
    # Returns:
    # 
    # integer to be used for MIDI data 1
    # 
    # Errors raised:
    # 
    # [Launchpad::NoValidGridCoordinatesError] when coordinates aren't within the valid range
    def note(type, opts)
      note = TYPE_TO_NOTE[type]
      if note.nil?
        x = (opts[:x] || -1).to_i
        y = (opts[:y] || -1).to_i
        if x < 0 || x > 7 || y < 0 || y > 7
          logger.error "wrong coordinates specified: x=#{x}, y=#{y}"
          raise NoValidGridCoordinatesError.new("you need to specify valid coordinates (x/y, 0-7, from top left), you specified: x=#{x}, y=#{y}")
        end
        note = (y + 1) * 10 + (x + 1)
      end
      note
    end
    
    # Calculates the MIDI data 2 value (velocity) for given brightness and mode values.
    # 
    # Options hash:
    # 
    # [<tt>color</tt>]  color of the LED (value between 0 and 127 inclusive)
    #                   optional, defaults to <tt>:off</tt>
    # 
    # Returns:
    # 
    # integer to be used for MIDI data 2
    def velocity(opts)
      if opts.is_a?(Hash)
        color = color(opts[:color]) || 0
      else
        opts.to_i + 12
      end
    end
    
    def color(color_key)
      if color_key.nil?
        0
      else
        if (not (color_key.is_a? Integer))
          logger.error "wrong color specified: color_key=#{color_key}"
          raise NoValidColorError.new("you need to specify a valid color (0-127), you specified: color_key=#{color_key}")
        end

        if color_key < 0 || color_key > 127
          logger.error "wrong color specified: color_key=#{color_key}"
          raise NoValidColorError.new("you need to specify a valid color (0-127), you specified: color_key=#{color_key}")
        end

        color_key
      end
    end
    
    # Creates a MIDI message.
    # 
    # Parameters:
    # 
    # [+status+]  MIDI status code
    # [+data1+]   MIDI data 1 (note)
    # [+data2+]   MIDI data 2 (velocity)
    # 
    # Returns:
    # 
    # an array with:
    # 
    # [<tt>:message</tt>]   an array of
    #                       MIDI status code,
    #                       MIDI data 1 (note),
    #                       MIDI data 2 (velocity)
    # [<tt>:timestamp</tt>] integer indicating the time when the MIDI message was created, in this case 0
    def message(status, data1, data2)
      {:message => [status, data1, data2], :timestamp => 0}
    end
    
  end
  
end
