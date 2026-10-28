; PRG-ROM
.segment "BANK0"
    .incbin "../roms/balloon_fight.nes", $10, $4000
.segment "BANK1"
    .incbin "../roms/bomberman.nes", $10, $4000
.segment "BANK2"
    .incbin "../roms/donkey_kong.nes", $10, $4000
.segment "BANK3"
    .incbin "../roms/duck_hunt.nes", $10, $4000
.segment "BANK4"
    .incbin "../roms/excitebike.nes", $10, $4000
.segment "BANK5"
    .incbin "../roms/ice_climber.nes", $10, $4000
.segment "BANK6"
    .incbin "../roms/mario_bros.nes", $10, $4000
.segment "BANK7"
    .incbin "../roms/pacman.nes", $10, $4000
.segment "BANK8"
    .incbin "../roms/pinball.nes", $10, $4000
.segment "BANK9"
    .incbin "../roms/tennis.nes", $10, $4000

; CHR-ROM
.segment "BANK10"
    .incbin "../roms/balloon_fight.nes", $4010, $2000
    .incbin "../roms/bomberman.nes", $4010, $2000
.segment "BANK11"
    .incbin "../roms/donkey_kong.nes", $4010, $2000
    .incbin "../roms/duck_hunt.nes", $4010, $2000
.segment "BANK12"
    .incbin "../roms/excitebike.nes", $4010, $2000
    .incbin "../roms/ice_climber.nes", $4010, $2000
.segment "BANK13"
    .incbin "../roms/mario_bros.nes", $4010, $2000
    .incbin "../roms/pacman.nes", $4010, $2000
.segment "BANK14"
    .incbin "../roms/pinball.nes", $4010, $2000
    .incbin "../roms/tennis.nes", $4010, $2000
