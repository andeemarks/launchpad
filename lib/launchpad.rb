require 'launchpad/interaction'

# All the fun of launchpad in one module!
# 
# See Launchpad::Device for basic access to launchpad input/ouput
# and Launchpad::Interaction for advanced interaction features.
# 
# The following parameters will be used throughout the library, so here are the ranges:
# 
# [+type+]              type of the button, one of
#                       <tt>
#                       :grid,
#                       :up, :down, :left, :right, :session, :user1, :user2, :mixer,
#                       :scene1 - :scene8
#                       </tt>
# [<tt>x/y</tt>]        x/y coordinate (used when type is set to :grid),
#                       <tt>0-7</tt> (from left to right/bottom to top),
#                       mandatory when +type+ is set to <tt>:grid</tt>
# [<tt>color</tt>]  	color of the LED (value between 0 and 127 inclusive)
#                       optional, defaults to <tt>:off</tt>
# [+state+]             whether the button is pressed or released, <tt>:down/:up</tt>
module Launchpad
end
