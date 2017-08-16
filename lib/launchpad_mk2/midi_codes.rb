module Launchpad
  
  # Module defining constants for MIDI codes.
  module MidiCodes
    
    # Module defining MIDI status codes.
    module Status
      NIL           = 0x00
      OFF           = 0x80
      ON            = 0x90
      CC            = 0xB0
    end
    
    # Module defininig MIDI data 1 (note) codes for control buttons.
    module ControlButton
      UP            = 0x68
      DOWN          = 0x69
      LEFT          = 0x6A
      RIGHT         = 0x6B
      SESSION       = 0x6C
      USER1         = 0x6D
      USER2         = 0x6E
      MIXER         = 0x6F
    end
    
    # Module defininig MIDI data 1 (note) codes for scene buttons.
    module SceneButton
      SCENE1        = 0x59
      SCENE2        = 0x4F
      SCENE3        = 0x45
      SCENE4        = 0x3B
      SCENE5        = 0x31
      SCENE6        = 0x27
      SCENE7        = 0x1D
      SCENE8        = 0x13
    end
    
  end
  
end
