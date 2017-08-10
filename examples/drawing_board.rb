require 'launchpad'

interaction = Launchpad::Interaction.new

# yellow feedback for grid buttons
interaction.response_to(:grid, :down) do |interaction, action|
  interaction.device.change(:grid, :x => action[:x], :y => action[:y], :color => 13)
end

# mixer button terminates interaction on button up
interaction.response_to(:mixer) do |interaction, action|
  interaction.device.change(:mixer, :color => action[:state] == :down ? 5 : 61)
  interaction.stop if action[:state] == :up
end

# start interacting
interaction.start

# sleep so that the messages can be sent before the program terminates
sleep 0.1
