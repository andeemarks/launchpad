require 'launchpad'

device = Launchpad::Device.new

on = { :color => 56 }
off = { :color => 72 }

digit_map = [
  [off, off, off, off],
  [on , off, off, off],
  [off, on , off, off],
  [on , on , off, off],
  [off, off, on , off],
  [on , off, on , off],
  [off, on , on , off],
  [on , on , on , off],
  [off, off, off, on ],
  [on , off, off, on ]
]

while true do
  Time.now.strftime('%H%M%S').split('').each_with_index do |digit, x|
    digit_map[digit.to_i].each_with_index do |color, y|
      device.change :grid, color.merge(:x => x, :y => y)
    end
  end

  sleep 0.25
end
