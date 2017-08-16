require 'launchpad_mk2'

device = Launchpad::Device.new

on = { :color => 16 }
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

def offset_x(x)
  if (x == 0 or x == 1)
    return x
  end

  if (x == 2 or x == 3)
    return (x + 1)
  end

  return (x + 2)
end

while true do
  Time.now.strftime('%H%M%S').split('').each_with_index do |digit, x|
    digit_map[digit.to_i].each_with_index do |color, y|
      device.change :grid, color.merge(:x => offset_x(x), :y => (y + 2))
    end
  end

  sleep 0.25
end
