; PRG-ROM
.segment "BANK0"
    .incbin "roms/Balloon Fight (USA).nes", $10, $4000
.segment "BANK1"
    .incbin "roms/Bomberman (USA).nes", $10, $4000
.segment "BANK2"
    .incbin "roms/Donkey Kong (World) (Rev 1).nes", $10, $4000
.segment "BANK3"
    .incbin "roms/Duck Hunt (World).nes", $10, $4000
.segment "BANK4"
    .incbin "roms/Excitebike (Japan, USA) (En).nes", $10, $4000
.segment "BANK5"
    .incbin "roms/Ice Climber (USA, Europe, Asia) (En).nes", $10, $4000
.segment "BANK6"
    .incbin "roms/Mario Bros. (World).nes", $10, $4000
.segment "BANK7"
    .incbin "roms/Pac-Man (USA) (Namco).nes", $10, $4000
.segment "BANK8"
    .incbin "roms/Pinball (Japan, USA) (En).nes", $10, $4000
.segment "BANK9"
    .incbin "roms/Tennis (Japan, USA) (En).nes", $10, $4000

; CHR-ROM
.segment "BANK10"
    .incbin "roms/Balloon Fight (USA).nes", $4010, $2000
    .incbin "roms/Bomberman (USA).nes", $4010, $2000
.segment "BANK11"
    .incbin "roms/Donkey Kong (World) (Rev 1).nes", $4010, $2000
    .incbin "roms/Duck Hunt (World).nes", $4010, $2000
.segment "BANK12"
    .incbin "roms/Excitebike (Japan, USA) (En).nes", $4010, $2000
    .incbin "roms/Ice Climber (USA, Europe, Asia) (En).nes", $4010, $2000
.segment "BANK13"
    .incbin "roms/Mario Bros. (World).nes", $4010, $2000
    .incbin "roms/Pac-Man (USA) (Namco).nes", $4010, $2000
.segment "BANK14"
    .incbin "roms/Pinball (Japan, USA) (En).nes", $4010, $2000
    .incbin "roms/Tennis (Japan, USA) (En).nes", $4010, $2000
