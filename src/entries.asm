entry_titles:
    ; lookup table
    .word balloon_fight_title
    .word bomberman_title
    .word donkey_kong_title
    .word duck_hunt_title
    .word excitebike_title
    .word ice_climber_title
    .word mario_bros_title
    .word pacman_title
    .word pinball_title
    .word tennis_title

    ; string lengths
    title_lengths:
        .byte bomberman_title - balloon_fight_title
        .byte donkey_kong_title - bomberman_title
        .byte duck_hunt_title - donkey_kong_title
        .byte excitebike_title - duck_hunt_title
        .byte ice_climber_title - excitebike_title
        .byte mario_bros_title - ice_climber_title
        .byte pacman_title - mario_bros_title
        .byte pinball_title - pacman_title
        .byte tennis_title - pinball_title
        .byte entry_flags - tennis_title

    ; string data
    balloon_fight_title:
        .byte $44, $82, $98, $98, $9e, $9e, $9c, $00, $4c, $92, $8e, $90, $a8 ; "Balloon Fight"
    bomberman_title:
        .byte $44, $9e, $9a, $84, $8a, $a4, $9a, $82, $9c ; "Bomberman"
    donkey_kong_title:
        .byte $48, $9e, $9c, $96, $8a, $b2, $00, $56, $9e, $9c, $8e ; "Donkey Kong"
    duck_hunt_title:
        .byte $48, $aa, $86, $96, $00, $50, $aa, $9c, $a8 ; "Duck Hunt"
    excitebike_title:
        .byte $4a, $b0, $86, $92, $a8, $8a, $84, $92, $96, $8a ; "Excitebike"
    ice_climber_title:
        .byte $52, $86, $8a, $00, $46, $98, $92, $9a, $84, $8a, $a4 ; "Ice Climber"
    mario_bros_title:
        .byte $5a, $82, $a4, $92, $9e, $00, $44, $a4, $9e, $a6, $1c ; "Mario Bros."
    pacman_title:
        .byte $60, $82, $86, $1a, $5a, $82, $9c ; "Pac-Man"
    pinball_title:
        .byte $60, $92, $9c, $84, $82, $98, $98 ; "Pinball"
    tennis_title:
        .byte $68, $8a, $9c, $9c, $92, $a6 ; "Tennis"

; MMC1 control flags
entry_flags:
    .byte %01011, %01010, %01011, %01010, %01010, %01011, %01011, %01011, %01011, %01011
