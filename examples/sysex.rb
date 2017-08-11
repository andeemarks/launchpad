require 'launchpad'

device = Launchpad::Device.new(:input => false, :output => true)

device.reset()
# sleep 0.5
device.lightn_column([0, 3,6], 45)
# sleep 0.5
device.lightn_row([7,6, 2], 22)
# sleep 0.5
# device.light_all(63)
# sleep 0.5
# device.reset()
# sleep 0.5
# device.light_all(79)
# sleep 0.5
# device.reset()
# sleep 0.5
# device.flash1(4, 4, 63)
# sleep 2
device.flashn([[1, 1],[2, 2],[3, 3],[4, 4]], 63)
device.pulsen([[4, 1],[4, 2],[4, 3],[4, 4]], 63)
sleep 2
# device.pulse(3, 3, 45)
# sleep 2
device.reset()
# device.pulse(3, 3, 63)
# sleep 2
# device.scroll_once(45, "Oscar is a snot monster")
# sleep 10
# device.scroll_stop()

# sleep so that the messages can be sent before the program terminates
sleep 0.1
