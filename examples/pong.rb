require 'launchpad'

interaction = Launchpad::Interaction.new

UP = -1
DOWN = 1

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
		move_left_flipper(interaction.device, UP)
	elsif (x == 0 && y == 7)
		move_left_flipper(interaction.device, DOWN)
	elsif (x == 7 && y == 0)
		move_right_flipper(interaction.device, UP)
	elsif (x == 7 && y == 7)
		move_right_flipper(interaction.device, DOWN)
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

def run_ball_movement(d) 
	Thread.new {
		loop do
			sleep 0.5
			hide_ball(d, @ball_x, @ball_y)
			if ((@ball_x + @lat_delta) < 1 || (@ball_x + @lat_delta) > 6)
				@lat_delta = -@lat_delta
			end
			@ball_x = @ball_x + @lat_delta
			if ((@ball_y + @lon_delta) < 0 || (@ball_y + @lon_delta) > 7)
				@lon_delta = -@lon_delta
			end
			@ball_y = @ball_y + @lon_delta
			show_ball(d, @ball_x, @ball_y)
		end
	}
end

def show_ball(d, x, y)
	d.change(:grid, :x => x, :y => y, :color => 72)	
end

def hide_ball(d, x, y)
	d.change(:grid, :x => x, :y => y, :color => 0)	
end

def start_ball(d)
	@lat_delta = rand(2) == 0 ? -1 : 1
	@lon_delta = rand(2) == 0 ? -1 : 1
	@ball_x = @lat_delta == -1 ? 4 : 3
	@ball_y = @lon_delta == -1 ? 4 : 3
	puts "Ball moving using " + @lat_delta.to_s + ", " + @lon_delta.to_s + " from " + @ball_x.to_s + ", " + @ball_y.to_s
	show_ball(d, @ball_x, @ball_y)
end

show_flipper(interaction.device, 0, @left_bottom_edge)
show_flipper(interaction.device, 7, @right_bottom_edge)
start_ball(interaction.device)
run_ball_movement(interaction.device)
# start interacting
interaction.start

# sleep so that the messages can be sent before the program terminates
sleep 0.1
