require 'helper'

describe LaunchpadMk2::Device do
  
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

  STATES = {
    :down     => 127,
    :up       => 0
  }
  
  def expects_output(device, *args)
    args = [args] unless args.first.is_a?(Array)
    messages = args.collect {|data| {:message => data, :timestamp => 0}}
    device.instance_variable_get('@output').expects(:write).with(messages)
  end

  def expects_sysex_message(device, message)
    device.instance_variable_get('@output').expects(:write_sysex).with(LaunchpadMk2::Device::SYSEX_HEADER + message  + LaunchpadMk2::Device::SYSEX_FOOTER)
  end
  
  def stub_input(device, *args)
    device.instance_variable_get('@input').stubs(:read).returns(args)
  end
  
  describe '#initialize' do
    
    it 'tries to initialize both input and output when not specified' do
      Portmidi.expects(:input_devices).returns(mock_devices)
      Portmidi.expects(:output_devices).returns(mock_devices)
      d = LaunchpadMk2::Device.new
      refute_nil d.instance_variable_get('@input')
      refute_nil d.instance_variable_get('@output')
    end
    
    it 'does not try to initialize input when set to false' do
      Portmidi.expects(:input_devices).never
      d = LaunchpadMk2::Device.new(:input => false)
      assert_nil d.instance_variable_get('@input')
      refute_nil d.instance_variable_get('@output')
    end
    
    it 'does not try to initialize output when set to false' do
      Portmidi.expects(:output_devices).never
      d = LaunchpadMk2::Device.new(:output => false)
      refute_nil d.instance_variable_get('@input')
      assert_nil d.instance_variable_get('@output')
    end
    
    it 'does not try to initialize any of both when set to false' do
      Portmidi.expects(:input_devices).never
      Portmidi.expects(:output_devices).never
      d = LaunchpadMk2::Device.new(:input => false, :output => false)
      assert_nil d.instance_variable_get('@input')
      assert_nil d.instance_variable_get('@output')
    end
    
    it 'initializes the correct input output devices when specified by name' do
      Portmidi.stubs(:input_devices).returns(mock_devices(:id => 4, :name => 'Launchpad Name'))
      Portmidi.stubs(:output_devices).returns(mock_devices(:id => 5, :name => 'Launchpad Name'))
      d = LaunchpadMk2::Device.new(:device_name => 'Launchpad Name')
      assert_equal Portmidi::Input, (input = d.instance_variable_get('@input')).class
      assert_equal 4, input.device_id
      assert_equal Portmidi::Output, (output = d.instance_variable_get('@output')).class
      assert_equal 5, output.device_id
    end
    
    it 'initializes the correct input output devices when specified by id' do
      Portmidi.stubs(:input_devices).returns(mock_devices(:id => 4))
      Portmidi.stubs(:output_devices).returns(mock_devices(:id => 5))
      d = LaunchpadMk2::Device.new(:input_device_id => 4, :output_device_id => 5, :device_name => 'nonexistant')
      assert_equal Portmidi::Input, (input = d.instance_variable_get('@input')).class
      assert_equal 4, input.device_id
      assert_equal Portmidi::Output, (output = d.instance_variable_get('@output')).class
      assert_equal 5, output.device_id
    end
    
    it 'raises NoSuchDeviceError when requested input device does not exist' do
      assert_raises LaunchpadMk2::NoSuchDeviceError do
        Portmidi.stubs(:input_devices).returns(mock_devices(:name => 'Launchpad Input'))
        LaunchpadMk2::Device.new
      end
    end
    
    it 'raises NoSuchDeviceError when requested output device does not exist' do
      assert_raises LaunchpadMk2::NoSuchDeviceError do
        Portmidi.stubs(:output_devices).returns(mock_devices(:name => 'Launchpad Output'))
        LaunchpadMk2::Device.new
      end
    end
    
    it 'raises DeviceBusyError when requested input device is busy' do
      assert_raises LaunchpadMk2::DeviceBusyError do
        Portmidi::Input.stubs(:new).raises(RuntimeError)
        LaunchpadMk2::Device.new
      end
    end
    
    it 'raises DeviceBusyError when requested output device is busy' do
      assert_raises LaunchpadMk2::DeviceBusyError do
        Portmidi::Output.stubs(:new).raises(RuntimeError)
        LaunchpadMk2::Device.new
      end
    end
    
    it 'stores the logger given' do
      logger = Logger.new(nil)
      device = LaunchpadMk2::Device.new(:logger => logger)
      assert_same logger, device.logger
    end
    
  end
  
  describe '#close' do
    
    it 'does not fail when neither input nor output are there' do
      LaunchpadMk2::Device.new(:input => false, :output => false).close
    end
    
    describe 'with input and output devices' do
      
      before do
        Portmidi::Input.stubs(:new).returns(@input = mock('input'))
        Portmidi::Output.stubs(:new).returns(@output = mock('output'))
        @device = LaunchpadMk2::Device.new
      end
      
      it 'closes input/output and raise NoInputAllowedError/NoOutputAllowedError on subsequent read/write accesses' do
        @input.expects(:close)
        @output.expects(:close)
        @device.close
        assert_raises LaunchpadMk2::NoInputAllowedError do
          @device.read_pending_actions
        end
        assert_raises LaunchpadMk2::NoOutputAllowedError do
          @device.change(:session)
        end
      end
      
    end
    
  end
  
  describe '#closed?' do
    
    it 'returns true when neither input nor output are there' do
      assert LaunchpadMk2::Device.new(:input => false, :output => false).closed?
    end
    
    it 'returns false when initialized with input' do
      assert !LaunchpadMk2::Device.new(:input => true, :output => false).closed?
    end
    
    it 'returns false when initialized with output' do
      assert !LaunchpadMk2::Device.new(:input => false, :output => true).closed?
    end
    
    it 'returns false when initialized with both but true after calling close' do
      d = LaunchpadMk2::Device.new
      assert !d.closed?
      d.close
      assert d.closed?
    end
    
  end

  describe 'top level API initialized with output' do
    before do
      @device = LaunchpadMk2::Device.new(:input => false)
    end

    describe '#rgb1' do
      [[1, 4, 0, 0, 63], [0, 6, 63, 0, 0]].each do |message|
        it "sends 11, #{(message[1] + 1) * 10 + (message[0] + 1)}, #{message[2]}, #{message[3]}, #{message[4]} when given #{message}" do
          expects_sysex_message(@device, [11, (message[1] + 1) * 10 + (message[0] + 1), message[2], message[3], message[4]])
          @device.rgb1(message[0], message[1], message[2], message[3], message[4])
        end
      end
    end

    describe '#rgbn' do
      it "sends one message for each set of coordinates received" do
        [[1, 4], [0, 6]].each do |coords|
          expects_sysex_message(@device, [11, (coords[1] + 1) * 10 + (coords[0] + 1), 31, 15, 63])
        end
        @device.rgbn([[1, 4], [0, 6]], 31, 15, 63)
      end
    end

    describe '#pulse1' do
      [[1, 4, 24], [0, 6, 27]].each do |message|
        it "sends 40, 0, #{(message[1] + 1) * 10 + (message[0] + 1)}, #{message[2]} when given #{message}" do
          expects_sysex_message(@device, [40, 0, (message[1] + 1) * 10 + (message[0] + 1), message[2]])
          @device.pulse1(message[0], message[1], message[2])
        end
      end
    end

    describe '#pulsen' do
      it "sends one message for each set of coordinates received" do
        [[1, 4], [0, 6]].each do |coords|
          expects_sysex_message(@device, [40, 0, (coords[1] + 1) * 10 + (coords[0] + 1), 24])
        end
        @device.pulsen([[1, 4], [0, 6]], 24)
      end
    end

    describe '#flash1' do
      [[1, 4, 24], [0, 6, 27]].each do |message|
        it "sends 35, 0, #{(message[1] + 1) * 10 + (message[0] + 1)}, #{message[2]} when given #{message}" do
          expects_sysex_message(@device, [35, 0, (message[1] + 1) * 10 + (message[0] + 1), message[2]])
          @device.flash1(message[0], message[1], message[2])
        end
      end
    end

    describe '#flashn' do
      it "sends one message for each set of coordinates received" do
        [[1, 4], [0, 6]].each do |coords|
          expects_sysex_message(@device, [35, 0, (coords[1] + 1) * 10 + (coords[0] + 1), 24, 0])
        end
        @device.flashn([[1, 4], [0, 6]], 24)
      end
    end

    describe '#light_all' do
      [24, 27].each do |message|
        it "sends 14, #{message[0]} when given #{message}" do
          expects_sysex_message(@device, [14, message[0]])
          @device.light_all(message[0])
        end
      end
    end

    describe '#reset_all' do
      it "sends 14, 0" do
        expects_sysex_message(@device, [14, 0])
        @device.reset_all()
      end
    end

    describe '#light1_row' do
      [[1, 24], [0, 27]].each do |message|
        it "sends 13, #{message[0]}, #{message[1]} when given #{message}" do
          expects_sysex_message(@device, [13, message[0], message[1]])
          @device.light1_row(message[0], message[1])
        end
      end
    end

    describe '#light1_column' do
      [[1, 24], [0, 27]].each do |message|
        it "sends 12, #{message[0]}, #{message[1]} when given #{message}" do
          expects_sysex_message(@device, [12, message[0], message[1]])
          @device.light1_column(message[0], message[1])
        end
      end
    end
  end

  describe '#change' do
    
    it 'raises NoOutputAllowedError when not initialized with output' do
      assert_raises LaunchpadMk2::NoOutputAllowedError do
        LaunchpadMk2::Device.new(:output => false).change(:up)
      end
    end
    
    describe 'initialized with output' do
      
      before do
        @device = LaunchpadMk2::Device.new(:input => false)
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
          assert_raises LaunchpadMk2::NoValidGridCoordinatesError do
            @device.change(:grid, :y => 1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if x is below 0' do
          assert_raises LaunchpadMk2::NoValidGridCoordinatesError do
            @device.change(:grid, :x => -1, :y => 1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if x is above 7' do
          assert_raises LaunchpadMk2::NoValidGridCoordinatesError do
            @device.change(:grid, :x => 8, :y => 1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if y is not specified' do
          assert_raises LaunchpadMk2::NoValidGridCoordinatesError do
            @device.change(:grid, :x => 1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if y is below 0' do
          assert_raises LaunchpadMk2::NoValidGridCoordinatesError do
            @device.change(:grid, :x => 1, :y => -1)
          end
        end
        
        it 'raises NoValidGridCoordinatesError if y is above 7' do
          assert_raises LaunchpadMk2::NoValidGridCoordinatesError do
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
        
        it 'raises NoValidColorError if color is below 0' do
          assert_raises LaunchpadMk2::NoValidColorError do
            @device.change(:grid, :x => 0, :y => 0, :color => -1)
          end
        end
        
        it 'raises NoValidColorError if color is above 127' do
          assert_raises LaunchpadMk2::NoValidColorError do
            @device.change(:grid, :x => 0, :y => 0, :color => 128)
          end
        end
        
        it 'raises NoValidColorError if color is an unknown symbol' do
          assert_raises LaunchpadMk2::NoValidColorError do
            @device.change(:grid, :x => 0, :y => 0, :color => :unknown)
          end
        end
        
      end
      
      describe 'mode' do
        
        it 'sends 0 when nothing given' do
          expects_output(@device, 0x90, 11, 0)
          @device.change(:grid, :x => 0, :y => 0)
        end
        
      end
      
    end
    
  end
  
  describe '#read_pending_actions' do
    
    it 'raises NoInputAllowedError when not initialized with input' do
      assert_raises LaunchpadMk2::NoInputAllowedError do
        LaunchpadMk2::Device.new(:input => false).read_pending_actions
      end
    end
    
    describe 'initialized with input' do
      
      before do
        @device = LaunchpadMk2::Device.new(:output => false)
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
