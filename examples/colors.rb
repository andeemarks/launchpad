require 'launchpad_mk2'

device = LaunchpadMk2::Device.new(:input => false, :output => true)

color = 0
# first page of colors
(0..7).each do |row|
  (0..7).each do |column|
    device.change :grid, :x => column, :y => row, :color => color
    color = color + 1
  end
end

sleep 2

# second page of colors
(0..7).each do |row|
  (0..7).each do |column|
    device.change :grid, :x => column, :y => row, :color => color
    color = color + 1
  end
end

# sleep so that the messages can be sent before the program terminates
sleep 2

device.reset_all()
