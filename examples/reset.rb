require File.expand_path('../setup', __FILE__)

Launchpad::Device.new.reset

# sleep so that the messages can be sent before the program terminates
sleep 0.1
