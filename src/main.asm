; constants
.include "constants.asm"

; segments
.segment "HEADER"
    .byte "NES", $1a ; identification string
    .byte 1 ; size of PRG-ROM in 16K units
    .byte 0 ; size of CHR-ROM in 8K units (CHR-RAM)

    .byte %00000000 ; lower nibble of mapper, mirroring, battery, trainer
    .byte %00000000 ; upper nibble of mapper, VS/Playchoice, NES 2.0

    .byte 0 ; PRG-RAM size
    .byte 0 ; TV system (0 = NTSC, 1 = PAL)
    .byte 0 ; TV system, PRG-RAM presence, bus conflicts

    .res 5 ; padding

.segment "ZEROPAGE"
    flags: .res 1 ; various flags, mainly for vblank
    controls: .res 1 ; state of controller buttons
    previous_controls: .res 1 ; state of controller buttons from previous frame
    entry_index: .res 1 ; index of currently selected entry
    address: .res 2 ; source/destination address
    temp: .res 1 ; temporary variable

.segment "CODE"
    ; interrupt handlers
    on_reset:
        sei ; disable interrupts
        cld ; disable decimal mode

        ; initalize stack pointer
        ldx #$ff ; stack address
        txs ; transfer value to stack pointer

        ; disable NMI, rendering, and DMC IRQs
        lda #0 ; value to send to appropriate registers

        sta PPU_CTRL ; send value to PPU control register
        sta PPU_MASK ; send value to PPU mask register
        sta APU_DMC ; send value to APU DMC

        ; disable APU IRQs
        lda #%01000000 ; mode 0 (4-step), IRQ inhibit flag enabled
        sta APU_FRAME_COUNTER ; send value to APU frame counter

        bit PPU_STATUS ; clear vblank flag
        jsr wait_for_vblank ; wait for vblank to ensure PPU is ready

        ; clear internal RAM
        ldx #0 ; offset for RAM

        clear_ram:
            lda #0 ; value to clear RAM with

            sta $0000, x ; zero page
            sta $0100, x ; stack page
            ;sta $0200, x
            sta $0300, x
            sta $0400, x
            sta $0500, x
            sta $0600, x
            sta $0700, x

            lda #$ff ; needed to not display garbage
            sta OAM_BUFFER, x ; OAM buffer

            inx ; increment offset
            bne clear_ram ; loop if not done

        jsr wait_for_vblank ; wait for vblank again

        ; clear tile and background data in PPU memory
        lda PPU_STATUS ; reset address latch

        lda #0 ; value to clear PPU memory with
        ldx #36 ; number of pages
        ldy #0 ; byte counter

        sty PPU_ADDR ; send value to PPU address register (low byte of destination address)
        sty PPU_ADDR ; send value to PPU address register (high byte of destination address)

        clear_ppu:
            sta PPU_DATA ; send value to PPU data register

            iny ; increment counter
            bne clear_ppu ; loop if not done

            dex ; decrement number of pages
            bne clear_ppu ; loop if not done

        ; copy tile data to PPU
        lda PPU_STATUS ; reset address latch

        lda #<font_data ; low byte of tile data address
        sta address ; store value in variable

        lda #>font_data ; high byte of tile data address
        sta address + 1 ; store value in variable

        lda #$10 ; high byte of tile data address in PPU memory
        sta PPU_ADDR ; send value to PPU address register

        lda #$00 ; low byte of address
        sta PPU_ADDR ; send value to PPU address register

        ldx #FONT_SIZE ; number of pages of tile data
        ldy #0 ; offset for tile data

        copy_tiles:
            lda (address), y ; load byte of tile data
            sta PPU_DATA ; send value to PPU data register

            iny ; increment offset
            bne copy_tiles ; loop if not done

            inc address + 1 ; increment high byte of tile data address

            dex ; decrement number of pages of tile data
            bne copy_tiles ; loop if not done

        ; copy palette data to PPU
        lda PPU_STATUS ; reset address latch

        lda #$3f ; high byte of palette data address in PPU memory
        sta PPU_ADDR ; send value to PPU address register

        lda #$00 ; low byte of address
        sta PPU_ADDR ; send value to PPU address register

        ldx #0 ; offset for palette data

        copy_palettes:
            lda palette_data, x ; load byte of palette data
            sta PPU_DATA ; send value to PPU data register

            inx ; increment offset

            cpx #32 ; check if all bytes of palette data have been sent
            bne copy_palettes ; loop if not done

        ; render entry titles to background
        ldx #0 ; offset for entry title

        render_entries:
            jsr render_entry ; render entry title to background

            inx ; increment offset for next entry
            cpx #ENTRY_AMOUNT ; check if all entry titles have been rendered
            bne render_entries ; loop if not done

        jsr reset_scroll ; reset scroll position

        ; set up NMI
        lda #%10010000 ; enable NMI on vblank, 8x8 sprite size, $1000 as background pattern table address
        sta PPU_CTRL ; send value to PPU control register

        ; show sprites and background
        lda #%00011110 ; enable background and sprite rendering, show both in leftmost 8 pixels
        sta PPU_MASK ; send value to PPU mask register

        menu_loop:
            bit flags ; check if vblank has occurred
            bpl menu_loop ; loop if not

            lda controls ; load previous controller state
            sta previous_controls ; store in variable

            jsr read_joystick ; read controller input

            ; down button check
            controller_check_down:
                lda controls ; load controller state to accumulator
                and #%00000100 ; check if button is pressed
                beq controller_check_up ; jump if it is not

                lda previous_controls ; load previous controller state
                and #%00000100 ; check if button was pressed in previous frame
                bne controller_check_up ; jump if it was

                ; increment entry index
                lda entry_index ; load current entry index
                cmp #ENTRY_AMOUNT - 1 ; check if current entry is last one
                beq controller_check_up ; skip incrementing if true

                inc entry_index ; increment entry index

                ; re-render previously selected entry and current entry
                tax ; transfer accumulator to X register
                jsr render_entry ; render previous entry title to background

                inx ; increment entry index
                jsr render_entry ; render current entry title to background

                jsr reset_scroll ; reset scroll position

            ; up button check
            controller_check_up:
                lda controls ; load controller state to accumulator
                and #%00001000 ; check if button is pressed
                beq :+ ; jump if it is not

                lda previous_controls ; load previous controller state
                and #%00001000 ; check if button was pressed in previous frame
                bne :+ ; jump if it was

                ; decrement entry index
                lda entry_index ; load current entry index
                beq :+ ; skip decrementing if current entry is first one

                dec entry_index ; decrement entry index

                ; re-render previously selected entry and current entry
                tax ; transfer accumulator to X register
                jsr render_entry ; render previous entry title to background

                dex ; decrement entry index
                jsr render_entry ; render current entry title to background

                jsr reset_scroll ; reset scroll position
        :
            ; reset vblank bit inside flags
            lda flags ; load current flags
            and #%01111111 ; clear vblank bit
            sta flags ; store updated flags

            jmp menu_loop ; loop forever

    on_vblank:
        pha ; push accumulator onto stack

        ; copy OAM buffer to PPU
        lda #0 ; OAM destination address
        sta OAM_ADDR ; send value to OAM address register

        lda #>OAM_BUFFER ; page number
        sta OAM_DMA ; send value to OAM DMA register

        ; set vblank bit for main loop
        lda flags ; load current flags
        ora #%10000000 ; set vblank bit
        sta flags ; store updated flags

        pla ; pull accumulator from stack
        rti ; return from interrupt

    ; subroutines
    .include "subroutines.asm"

.segment "RODATA"
    entry_titles:
        ; lookup table
        .word hello_world_title
        .word test_title
        .word lorem_ipsum_title

        ; string lengths
        title_lengths:
            .byte test_title - hello_world_title
            .byte lorem_ipsum_title - test_title
            .byte palette_data - lorem_ipsum_title

        ; string data
        hello_world_title:
            .byte $50, $8a, $98, $98, $9e, $18, $00, $ae, $9e, $a4, $98, $88, $02 ; "Hello, world!"
        test_title:
            .byte $68, $90, $92, $a6, $00, $92, $a6, $00, $82, $00, $a8, $8a, $a6, $a8, $1c ; "This is a test."
        lorem_ipsum_title:
            .byte $58, $9e, $a4, $8a, $9a, $00, $92, $a0, $a6, $aa, $9a, $00, $88, $9e, $98, $9e, $a4, $00, $a6, $92, $a8, $00, $82, $9a, $8a, $a8 ; "Lorem ipsum dolor sit amet"

    palette_data:
        ; background
        .byte $00, TEXT_COLOR, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; sprites
        .byte BACKGROUND_COLOR, $00, $00, $00 ; index 0 used as backdrop color
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

    font_data:
        .incbin "assets/font.chr" ; tile data for font characters

.segment "VECTORS"
    .word on_vblank ; NMI handler address
    .word on_reset ; reset handler address