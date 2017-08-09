require 'launchpad'

device = Launchpad::Device.new(:input => false, :output => true)

device.change :grid, :x => 0, :y => 0, :red => :high, :green => :low
device.change :grid, :x => 7, :y => 7, :red => :medium, :green => :low
device.change :grid, :x => 0, :y => 7, :red => :low, :green => :high
device.change :grid, :x => 7, :y => 0, :red => :low, :green => :medium

# sleep so that the messages can be sent before the program terminates
sleep 0.1
