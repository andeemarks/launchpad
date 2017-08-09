require 'launchpad'

device = Launchpad::Device.new(:input => false, :output => true)

device.change :grid, :x => 0, :y => 0, :color => 56 # fuschia
device.change :grid, :x => 7, :y => 7, :color => 63 # olive
device.change :grid, :x => 0, :y => 7, :color => 72 # red
device.change :grid, :x => 7, :y => 0, :color => 8  # orange

# sleep so that the messages can be sent before the program terminates
sleep 0.1
