require 'launchpad'

device = Launchpad::Device.new(:input => false, :output => true)

device.light_all(0)
sleep 0.5
device.light_column(0, 45)
sleep 0.5
device.light_row(4, 45)
sleep 0.5
device.light_all(63)
sleep 0.5
device.light_all(0)
sleep 0.5
device.light_all(79)
sleep 0.5
device.light_all(0)
sleep 0.5
device.flash(4, 4, 63)
sleep 2
device.pulse(3, 3, 63)
sleep 2
device.scroll_once(45, "hello")
sleep 5
device.scroll_stop()

# sleep so that the messages can be sent before the program terminates
sleep 0.1
