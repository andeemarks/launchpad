# launchpad_mk2

[<img src="https://travis-ci.org/andeemarks/launchpad.png?branch=master" alt="Build Status" />](https://travis-ci.org/andeemarks/launchpad)

![Overview diagram](https://github.com/andeemarks/launchpad/blob/master/launchpad-gem-overview.gif)

This gem provides a Ruby interface to access the [Novation Launchpad MK2](https://global.novationmusic.com/launch/launchpad#) programmatically. The code started life as a clone of [Thomas Jachman's gem](https://github.com/thomasjachmann/launchpad) and was subsequently updated to handle the MK2 version of the Launchpad.  The mapping of buttons and specification of colours completely changed when the MK2 was released, so lots of the original code in these areas has been re-written, but the interaction code is still largely intact.

## More Info

*   Novation's Launchpad MK2 MIDI [programmer's reference](https://global.novationmusic.com/sites/default/files/novation/downloads/10529/launchpad-mk2-programmers-reference-guide_0.pdf) was the sole source for helping me understand how to interact with the Launchpad.

*   Due to limitations in the Portmidi gem, it's not possible to specify which channel is used to send MIDI     messages.  As such, all interaction with the Launchpad are done over the default channel 1.  This means some workarounds have been needed to access functionality like flash and pulse, which usually require channel 2 messages.  All of these workarounds have been implemented via sending [System Exclusive messages](http://electronicmusic.wikia.com/wiki/System_exclusive) as per the above reference guide.

## Requirements

*   Roger B. Dannenberg's [portmidi library](http://sourceforge.net/projects/portmedia/)
*   Jan Krutisch's [portmidi gem](http://github.com/halfbyte/portmidi)

## Compatibility

The gem is known to be compatible with the following ruby versions:

*   MRI 2.3.1

## Installation

The gem is hosted on [RubyGems](https://rubygems.org/), so in order to use it, you're gonna gem install it:

    gem install launchpad_mk2

## Usage

There are two main entry points:

*   `require 'launchpad_mk2/device'`, providing `LaunchpadMk2::Device`, which handles all the basic input/output stuff

*   `require 'launchpad_mk2/interaction'` or just `'launchpad_mk2'`, additionally providing `LaunchpadMk2::Interaction`, which lets you respond to actions (button presses/releases)

This is a simple example (only requiring the device for output) that resets the launchpad and then lights the grid button at position 4/4 (from bottom left of 0/0).

    require 'launchpad_mk2/device'

    device = LaunchpadMk2::Device.new
    device.reset_all
    device.change :grid, :x => 4, :y => 4, :color => 72

This is an interaction example lighting all grid buttons in red when pressed and keeping them lit.

    require 'launchpad_mk2'

    interaction = LaunchpadMk2::Interaction.new
    interaction.response_to(:grid, :down) do |interaction, action|
      interaction.device.change(:grid, action.merge(:color => 72))
    end
    interaction.response_to(:mixer, :down) do |interaction, action|
      interaction.stop
    end

    interaction.start

For more details, see the examples. examples/color_picker.rb is the most complex example of interaction.

## Examples

All examples can be found in the `examples` folder and run as standalone Ruby applications (i.e., `ruby examples/<file>.rb`).

| Name              | Purpose                                                           |
| ---               | ---                                                               |
| binary_clock.rb   | Dynamic HH:MM:SS binary clock                                     |
| brightness.rb     | Uses #rgb1 and #rgbn methods to demonstrate brightness variations |
| color_picker.rb   | WIP                                                               |
| colors.rb         | Shows entire 128 colour palette                                   |
| corners.rb        | Basic demonstration of coordinate mapping                         |
| doodle.rb         | WIP                                                               |
| drawing_board.rb  | WIP                                                               |
| feedback.rb       | Lights up buttons on press                                        |
| pong.rb           | WIP                                                               |
| sysex.rb          | Tests most of the sysex based messages (e.g., #pulse1, #flashn, #light_all, #scroll_once etc) |

## To Do

*   Ensure all examples are working with MK2

## Copyright

Copyright (c) 2017 Andy Marks. See LICENSE for details.

