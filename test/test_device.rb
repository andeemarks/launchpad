require 'helper'

describe Launchpad::Device do
  
  CONTROL_BUTTONS = {
    :up       => 0x68,
    :down     => 0x69,
    :left     => 0x6A,
    :right    => 0x6B,
    :session  => 0x6C,
    :user1    => 0x6D,
    :user2    => 0x6E,
    :mixer    => 0x6F
  }
  SCENE_BUTTONS = {
    :scene1   => 0x59,
    :scene2   => 0x4F,
    :scene3   => 0x45,
    :scene4   => 0x3B,
    :scene5   => 0x31,
    :scene6   => 0x27,
    :scene7   => 0x1D,
    :scene8   => 0x13
  }
  COLORS = {
    nil => 0, 0 => 0, :off => 0,
    1 => 1, :lo => 1, :low => 1,
    2 => 2, :med => 2, :medium => 2,
    3 => 3, :hi => 3, :high => 3
  }
  STATES = {
    :down     => 127,
    :up       => 0
  }
  
  def expects_output(device, *args)
    args = [args] unless args.first.is_a?(Array)
    messages = args.collect {|data| {:message => data, :timestamp => 0}}
    device.instance_variable_get('@output').expects(:write).with(messages)
  end
  
  def stub_input(device, *args)
    device.instance_variable_get('@input').stubs(:read).returns(args)
  end
  
  describe '#initialize' do
    
    it 'tries to initialize both input and output when not specified' do
      Portmidi.expects(:input_devices).returns(mock_devices)
      Portmidi.expects(:output_devices).returns(mock_devices)
      d = Launchpad::Device.new
      refute_nil d.instance_variable_get('@input')
      refute_nil d.instance_variable_get('@output')
    end
    
    it 'does not try to initialize input when set to false' do
      Portmidi.expects(:input_devices).never
      d = Launchpad::Device.new(:input => false)
      assert_nil d.instance_variable_get('@input')
      refute_nil d.instance_variable_get('@output')
    end
    
    it 'does not try to initialize output when set to false' do
      Portmidi.expects(:output_devices).never
      d = Launchpad::Device.new(:output => false)
      refute_nil d.instance_variable_get('@input')
      assert_nil d.instance_variable_get('@output')
    end
    
    it 'does not try to initialize any of both when set to false' do
      Portmidi.expects(:input_devices).never
      Portmidi.expects(:output_devices).never
      d = Launchpad::Device.new(:input => false, :output => false)
      assert_nil d.instance_variable_get('@input')
      assert_nil d.instance_variable_get('@output')
    end
    
    it 'initializes the correct input output devices when specified by name' do
      Portmidi.stubs(:input_devices).returns(mock_devices(:id => 4, :name => 'Launchpad Name'))
      Portmidi.stubs(:output_devices).returns(mock_devices(:id => 5, :name => 'Launchpad Name'))
      d = Launchpad::Device.new(:device_name => 'Launchpad Name')
      assert_equal Portmidi::Input, (input = d.instance_variable_get('@input')).class
      assert_equal 4, input.device_id
      assert_equal Portmidi::Output, (output = d.instance_variable_get('@output')).class
      assert_equal 5, output.device_id
    end
    
    it 'initializes the correct input output devices when specified by id' do
      Portmidi.stubs(:input_devices).returns(mock_devices(:id => 4))
      Portmidi.stubs(:output_devices).returns(mock_devices(:id => 5))
      d = Launchpad::Device.new(:input_device_id => 4, :output_device_id => 5, :device_name => 'nonexistant')
      assert_equal Portmidi::Input, (input = d.instance_variable_get('@input')).class
      assert_equal 4, input.device_id
      assert_equal Portmidi::Output, (output = d.instance_variable_get('@output')).class
      assert_equal 5, output.device_id
    end
    
    it 'raises NoSuchDeviceError when requested input device does not exist' do
      assert_raises Launchpad::NoSuchDeviceError do
        Portmidi.stubs(:input_devices).returns(mock_devices(:name => 'Launchpad Input'))
        Launchpad::Device.new
      end
    end
    
    it 'raises NoSuchDeviceError when requested output device does not exist' do
      assert_raises Launchpad::NoSuchDeviceError do
        Portmidi.stubs(:output_devices).returns(mock_devices(:name => 'Launchpad Output'))
        Launchpad::Device.new
      end
    end
    
    it 'raises DeviceBusyError when requested input device is busy' do
      assert_raises Launchpad::DeviceBusyError do
        Portmidi::Input.stubs(:new).raises(RuntimeError)
        Launchpad::Device.new
      end
    end
    
    it 'raises DeviceBusyError when requested output device is busy' do
      assert_raises Launchpad::DeviceBusyError do
        Portmidi::Output.stubs(:new).raises(RuntimeError)
        Launchpad::Device.new
      end
    end
    
    it 'stores the logger given' do
      logger = Logger.new(nil)
      device = Launchpad::Device.new(:logger => logger)
      assert_same logger, device.logger
    end
    
  end
  
  describe '#close' do
    
    it 'does not fail when neither input nor output are there' do
      Launchpad::Device.new(:input => false, :output => false).close
    end
    
    describe 'with input and output devices' do
      
      before do
        Portmidi::Input.stubs(:new).returns(@input = mock('input'))
        Portmidi::Output.stubs(:new).returns(@output = mock('output', :write => nil, :write_sysex => nil))
        @device = Launchpad::Device.new
      end
      
      it 'closes input/output and raise NoInputAllowedError/NoOutputAllowedError on subsequent read/write accesses' do
        @input.expects(:close)
        @output.expects(:close)
        @device.close
        assert_raises Launchpad::NoInputAllowedError do
          @device.read_pending_actions
        end
        assert_raises Launchpad::NoOutputAllowedError do
          @device.change(:session)
        end
      end
      
    end
    
  end
  
  describe '#closed?' do
    
    it 'returns true when neither input nor output are there' do
      assert Launchpad::Device.new(:input => false, :output => false).closed?
    end
    
    it 'returns false when initialized with input' do
      assert !Launchpad::Device.new(:input => true, :output => false).closed?
    end
    
    it 'returns false when initialized with output' do
      assert !Launchpad::Device.new(:input => false, :output => true).closed?
    end
    
    it 'returns false when initialized with both but true after calling close' do
      d = Launchpad::Device.new
      assert !d.closed?
      d.close
      assert d.closed?
    end
    
  end
  
  {
    :reset          => [0xB0, 0x00, 0x00]
  }.each do |method, codes|
    describe "##{method}" do
    
      it 'raises NoOutputAllowedError when not initialized with output' do
        assert_raises Launchpad::NoOutputAllowedError do
          Launchpad::Device.new(:output => false).send(method)
        end
      end
    
      it "sends #{codes.inspect}" do
        d = Launchpad::Device.new
        expects_output(d, *codes)
        d.send(method)
      end
    
    end
  end
  
  describe '#change' do
    
    it 'raises NoOutputAllowedError when not initialized with output' do
      assert_raises Launchpad::NoOutputAllowedError do
        Launchpad::Device.new(:output => false).change(:up)
      end
    end
    
    describe 'initialized with output' do
      
      before do
        @device = Launchpad::Device.new(:input => false)
      end
      
      it 'returns nil' do
        assert_nil @device.change(:up)
      end
      
      describe 'control buttons' do
        CONTROL_BUTTONS.each do |type, value|
          it "sends 0xB0, #{value}, 0 when given #{type}" do
            expects_output(@device, 0xB0, value, 0)
            @device.change(type)
          end
        end
      end
      
      describe 'scene buttons' do
        SCENE_BUTTONS.each do |type, value|
          it "sends 0x90, #{value}, 0 when given #{type}" do
            expects_output(@device, 0x90, value, 0)
            @device.change(type)
          end
        end
      end
      
      describe 'grid buttons' do
        8.times do |x|
          8.times do |y|
            it "sends 0x90, #{10 * (y + 1) + (x + 1)}, 0 when given :grid, :x => #{x}, :y => #{y}" do
              expects_output(@device, 0x90, (10 * (y + 1)) + (x + 1), 0)
              @device.change(:grid, :x => x, :y => y)
            end
          end
        end
        
        it 'raises NoValidGridCoordinatesError if x is not specified' do
          assert_raises Launchpad::NoValidGridCoordinatesError do
            @device.change(:grid, :y => 1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if x is below 0' do
          assert_raises Launchpad::NoValidGridCoordinatesError do
            @device.change(:grid, :x => -1, :y => 1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if x is above 7' do
          assert_raises Launchpad::NoValidGridCoordinatesError do
            @device.change(:grid, :x => 8, :y => 1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if y is not specified' do
          assert_raises Launchpad::NoValidGridCoordinatesError do
            @device.change(:grid, :x => 1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if y is below 0' do
          assert_raises Launchpad::NoValidGridCoordinatesError do
            @device.change(:grid, :x => 1, :y => -1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if y is above 7' do
          assert_raises Launchpad::NoValidGridCoordinatesError do
            @device.change(:grid, :x => 1, :y => 8)
          end
        end
        
      end
      
      describe 'colors' do
        (0..127).each do |color_key|
          it "sends 0x90, 0, #{color_key} when given :color => #{color_key}" do
            expects_output(@device, 0x90, 11, color_key)
            @device.change(:grid, :x => 0, :y => 0, :color => color_key)
          end
        end
        
        it 'raises NoValidBrightnessError if color is below 0' do
          assert_raises Launchpad::NoValidBrightnessError do
            @device.change(:grid, :x => 0, :y => 0, :color => -1)
          end
        end
        
        it 'raises NoValidBrightnessError if color is above 127' do
          assert_raises Launchpad::NoValidBrightnessError do
            @device.change(:grid, :x => 0, :y => 0, :color => 128)
          end
        end
        
        it 'raises NoValidBrightnessError if color is an unknown symbol' do
          assert_raises Launchpad::NoValidBrightnessError do
            @device.change(:grid, :x => 0, :y => 0, :color => :unknown)
          end
        end
        
      end
      
      describe 'mode' do
        
        it 'sends 0 when nothing given' do
          expects_output(@device, 0x90, 11, 0)
          @device.change(:grid, :x => 0, :y => 0)
        end
        
        it 'sends 0 when given :normal' do
          expects_output(@device, 0x90, 11, 0)
          @device.change(:grid, :x => 0, :y => 0, :mode => :normal)
        end
        
        it 'sends 8 when given :flashing' do
          expects_output(@device, 0x90, 11, 8)
          @device.change(:grid, :x => 0, :y => 0, :mode => :flashing)
        end
        
        it 'sends 0 when given :buffering' do
          expects_output(@device, 0x90, 11, 0)
          @device.change(:grid, :x => 0, :y => 0, :mode => :buffering)
        end
        
      end
      
    end
    
  end
  
  describe '#buffering_mode' do
    
    it 'raises NoOutputAllowedError when not initialized with output' do
      assert_raises Launchpad::NoOutputAllowedError do
        Launchpad::Device.new(:output => false).buffering_mode
      end
    end
    
    {
      nil                     => [0xB0, 0x00, 0x20],
      {}                      => [0xB0, 0x00, 0x20],
      {:display_buffer => 1}  => [0xB0, 0x00, 0x21],
      {:update_buffer => 1}   => [0xB0, 0x00, 0x24],
      {:copy => true}         => [0xB0, 0x00, 0x30],
      {:flashing => true}     => [0xB0, 0x00, 0x28],
      {
        :display_buffer => 1,
        :update_buffer  => 1,
        :copy           => true,
        :flashing       => true
      }                       => [0xB0, 0x00, 0x3D]
    }.each do |opts, codes|
      it "sends #{codes.inspect} when called with #{opts.inspect}" do
        d = Launchpad::Device.new
        expects_output(d, *codes)
        d.buffering_mode(opts)
      end
    end
    
  end
  
  describe '#read_pending_actions' do
    
    it 'raises NoInputAllowedError when not initialized with input' do
      assert_raises Launchpad::NoInputAllowedError do
        Launchpad::Device.new(:input => false).read_pending_actions
      end
    end
    
    describe 'initialized with input' do
      
      before do
        @device = Launchpad::Device.new(:output => false)
      end
      
      describe 'control buttons' do
        CONTROL_BUTTONS.each do |type, value|
          STATES.each do |state, velocity|
            it "builds proper action for control button #{type}, #{state}" do
              stub_input(@device, {:timestamp => 0, :message => [0xB0, value, velocity]})
              assert_equal [{:timestamp => 0, :state => state, :type => type}], @device.read_pending_actions
            end
          end
        end
      end
      
      describe 'scene buttons' do
        SCENE_BUTTONS.each do |type, value|
          STATES.each do |state, velocity|
            it "builds proper action for scene button #{type}, #{state}" do
              stub_input(@device, {:timestamp => 0, :message => [0x90, value, velocity]})
              assert_equal [{:timestamp => 0, :state => state, :type => type}], @device.read_pending_actions
            end
          end
        end
      end
      
      describe '#grid buttons' do
        8.times do |x|
          8.times do |y|
            STATES.each do |state, velocity|
              it "builds proper action for grid button #{x},#{y}, #{state}" do
                stub_input(@device, {:timestamp => 0, :message => [0x90, 10 * (y + 1) + (x + 1), velocity]})
                assert_equal [{:timestamp => 0, :state => state, :type => :grid, :x => x, :y => y}], @device.read_pending_actions
              end
            end
          end
        end
      end
      
      it 'builds proper actions for multiple pending actions' do
        stub_input(@device, {:timestamp => 1, :message => [0x90, 11, 127]}, {:timestamp => 2, :message => [0xB0, 0x68, 0]})
        assert_equal [{:timestamp => 1, :state => :down, :type => :grid, :x => 0, :y => 0}, {:timestamp => 2, :state => :up, :type => :up}], @device.read_pending_actions
      end
      
    end
    
  end
  
end
