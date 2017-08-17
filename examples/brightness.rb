require 'launchpad_mk2'

device = LaunchpadMk2::Device.new(:input => false, :output => true)

device.reset_all()

# first quadrant of colors = red
brightness = 0
(0..3).each do |row|
  (0..3).each do |column|
		device.rgb1 column, row, brightness, 0, 0
		brightness = brightness + 4
  end
end

# second quadrant of colors = green
brightness = 0
(4..7).each do |row|
  (4..7).each do |column|
		device.rgb1 column, row, 0, brightness, 0
		brightness = brightness + 4
  end
end

# third quadrant of colors = blue
brightness = 0
(0..3).each do |row|
  (4..7).each do |column|
		device.rgb1 column, row, 0, 0, brightness
		brightness = brightness + 4
  end
end

# third quadrant of colors = white
brightness = 0
(4..7).each do |row|
  (0..3).each do |column|
		device.rgb1 column, row, brightness, brightness, brightness
		brightness = brightness + 4
  end
end

# sleep so that the messages can be sent before the program terminates
sleep 2

device.reset_all()
