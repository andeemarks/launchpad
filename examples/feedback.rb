require 'launchpad_mk2'

interaction = LaunchpadMk2::Interaction.new

# yellow feedback for grid buttons
interaction.response_to(:grid) do |interaction, action|
  	interaction.device.change(:grid, :x => action[:x], :y => action[:y], :color => 72)
end

# red feedback for top control buttons
interaction.response_to([:up, :down, :left, :right, :session, :user1, :user2, :mixer]) do |interaction, action|
  interaction.device.change(action[:type], :color => 13)
end

# green feedback for scene buttons
interaction.response_to([:scene1, :scene2, :scene3, :scene4, :scene5, :scene6, :scene7, :scene8]) do |interaction, action|
  interaction.device.change(action[:type], :color => 16)
end

# mixer button terminates interaction on button up
interaction.response_to(:mixer, :up) do |interaction, action|
	interaction.device.reset_all()
  interaction.stop
end

# start interacting
interaction.start

# sleep so that the messages can be sent before the program terminates
sleep 0.1
