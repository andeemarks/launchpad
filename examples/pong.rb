require 'launchpad'

interaction = Launchpad::Interaction.new

@left_bottom_edge = @right_bottom_edge = 3

def move_flipper(flipper, d, delta, column)
	flipper = flipper + delta
	if (flipper < 0 || flipper > 5)
		return flipper - delta
	end
	show_flipper(d, column, flipper)

	return flipper
end

def move_left_flipper(d, delta)
	@left_bottom_edge = move_flipper(@left_bottom_edge, d, delta, 0)
end

def move_right_flipper(d, delta)
	@right_bottom_edge = move_flipper(@right_bottom_edge, d, delta, 7)
end

def show_flipper(d, x, bottom_edge)
	d.light1_column(x, 0)
	d.change(:grid, :x => x, :y => bottom_edge, :color => 16)
	d.change(:grid, :x => x, :y => bottom_edge + 1, :color => 16)
	d.change(:grid, :x => x, :y => bottom_edge + 2, :color => 16)
end

# yellow feedback for grid buttons
interaction.response_to(:grid, :down) do |interaction, action|
	x = action[:x]
	y = action[:y]
	if (x == 0 && y == 0)
		move_left_flipper(interaction.device, -1)
	elsif (x == 0 && y == 7)
		move_left_flipper(interaction.device, 1)
	elsif (x == 7 && y == 0)
		move_right_flipper(interaction.device, -1)
	elsif (x == 7 && y == 7)
		move_right_flipper(interaction.device, 1)
	end
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

show_flipper(interaction.device, 0, @left_bottom_edge)
show_flipper(interaction.device, 7, @right_bottom_edge)
# start interacting
interaction.start

# sleep so that the messages can be sent before the program terminates
sleep 0.1
