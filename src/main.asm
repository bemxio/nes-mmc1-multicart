; constants
.include "constants.asm"

; segments
.segment "HEADER"
    .byte "NES", $1a ; identification string
    .byte 16 ; size of PRG-ROM in 16K units
    .byte 0 ; size of CHR-ROM in 8K units (CHR-RAM)

    ; iNES Mapper 1 (MMC1)
    .byte %00010000 ; lower nibble of mapper, mirroring, battery, trainer
    .byte %00000000 ; upper nibble of mapper, VS/Playchoice, NES 2.0

    .byte 0 ; PRG-RAM size
    .byte 0 ; TV system (0 = NTSC, 1 = PAL)
    .byte 0 ; TV system, PRG-RAM presence, bus conflicts

    .res 5 ; padding

.segment "ZEROPAGE"
    state: .res 1 ; used for vblank and previous up/down button presses
    controls: .res 1 ; state of controller buttons
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

        ; reset mapper
        lda #$80 ; reset MMC1 shift register
        sta MMC1_CTRL ; send value to MMC1 control register

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

        sty PPU_ADDR ; send value to PPU address register (high byte of destination address)
        sty PPU_ADDR ; send value to PPU address register (low byte of destination address)

        clear_ppu:
            sta PPU_DATA ; send value to PPU data register

            iny ; increment counter
            bne clear_ppu ; loop if not done

            dex ; decrement number of pages
            bne clear_ppu ; loop if not done

        ; copy entry loader to RAM
        lda #$07 ; high byte of destination address
        sta address + 1 ; store value in destination address

        lda #$00 ; low byte of destination address
        sta address ; store value in destination address

        ldy #0 ; offset for entry loader

        copy_entry_loader:
            lda entry_loader, y ; load byte of entry loader
            sta (address), y ; store byte to destination address

            iny ; increment offset
            cpy #(entry_loader_end - entry_loader) ; check if all bytes have been copied
            bne copy_entry_loader ; loop if not done

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
            bit state ; check if vblank has occurred
            bpl menu_loop ; loop if not

            jsr read_joystick ; read controller input

            ; down button check
            controller_check_down:
                lda controls ; load controller state to accumulator
                and #%00000100 ; check if button is pressed
                beq controller_unset_down ; jump to unsetting bit if it is not

                lda state ; load menu state to accumulator
                and #%00100000 ; check if button was pressed in previous frame
                bne controller_check_up ; jump if it was

                lda state ; load menu state to accumulator
                ora #%00100000 ; set down button pressed bit
                sta state ; store updated menu state

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
                jmp :+ ; jump to end of loop

            controller_unset_down:
                lda state ; load menu state to accumulator
                and #%11011111 ; clear down button pressed bit
                sta state ; store updated menu state

            ; up button check
            controller_check_up:
                lda controls ; load controller state to accumulator
                and #%00001000 ; check if button is pressed
                beq controller_unset_up ; jump to unsetting bit if it is not

                lda state ; load menu state to accumulator
                and #%01000000 ; check if button was pressed in previous frame
                bne controller_check_start ; jump if it was

                lda state ; load menu state to accumulator
                ora #%01000000 ; set up button pressed bit
                sta state ; store updated menu state

                ; decrement entry index
                lda entry_index ; load current entry index
                beq controller_check_start ; skip decrementing if current entry is first one

                dec entry_index ; decrement entry index

                ; re-render previously selected entry and current entry
                tax ; transfer accumulator to X register
                jsr render_entry ; render previous entry title to background

                dex ; decrement entry index
                jsr render_entry ; render current entry title to background

                jsr reset_scroll ; reset scroll position
                jmp :+ ; jump to end of loop

            controller_unset_up:
                lda state ; load menu state to accumulator
                and #%10111111 ; clear up button pressed bit
                sta state ; store updated menu state

            controller_check_start:
                lda controls ; load controller state to accumulator
                and #%00010000 ; check if button is pressed
                beq :+ ; jump to end of loop if not

                lda #0 ; disable rendering
                sta PPU_MASK ; send value to PPU mask register

                ; calculate source address
                lda entry_index ; load current entry index
                and #%00000001 ; get modulo 2 of entry index

                .repeat 5 ; multiply by 32 to get offset for source address
                    asl ; shift value left
                .endrep

                clc ; clear carry flag
                adc #$80 ; add base address to high byte of source address
                sta address + 1 ; store result in source address

                lda #$00 ; low byte of source address
                sta address ; store value in source address

                ; calculate bank number
                lda entry_index ; load current entry index
                lsr ; divide by 2

                clc ; clear carry flag
                adc #10 ; add offset to get bank number

                jsr switch_bank ; switch to selected bank

                ; copy CHR data to PPU
                lda PPU_STATUS ; reset address latch

                ldx #32 ; number of pages of data
                ldy #0 ; offset for data

                sty PPU_ADDR ; send value to PPU address register (high byte of destination address)
                sty PPU_ADDR ; send value to PPU address register (low byte of destination address)

                copy_entry_tiles:
                    lda (address), y ; load byte of data
                    sta PPU_DATA ; send value to PPU data register

                    iny ; increment offset
                    bne copy_entry_tiles ; loop if not done

                    inc address + 1 ; increment high byte of source address

                    dex ; decrement number of pages of data
                    bne copy_entry_tiles ; loop if not done

                ldx entry_index ; load current entry index
                ldy entry_banks, x ; load bank number for selected entry

                jmp $0700 ; jump to entry loader in RAM
        :
            ; unset vblank bit inside state
            lda state ; load current state
            and #%01111111 ; clear vblank bit
            sta state ; store updated state

            jmp menu_loop ; loop forever

    on_vblank:
        pha ; push accumulator onto stack

        ; copy OAM buffer to PPU
        lda #0 ; OAM destination address
        sta OAM_ADDR ; send value to OAM address register

        lda #>OAM_BUFFER ; page number
        sta OAM_DMA ; send value to OAM DMA register

        ; set vblank bit for main loop
        lda state ; load current state
        ora #%10000000 ; set vblank bit
        sta state ; store updated state

        pla ; pull accumulator from stack
        rti ; return from interrupt

    ; entry loader (running in RAM)
    entry_loader:
        ; set entry MMC1 control flags
        lda entry_flags, x ; load MMC1 control flags for selected entry
        sta MMC1_CTRL ; send first bit to MMC1 control register

        .repeat 4 ; repeat 4 times to send remaining bits
            lsr a ; shift accumulator right to get next bit
            sta MMC1_CTRL ; send next bit to MMC1 control register
        .endrep

        ; switch to appropriate PRG-ROM bank
        tya ; transfer bank number to accumulator
        sta MMC1_PRG ; send first bit to MMC1 PRG-ROM bank register

        .repeat 4 ; repeat 4 times to send remaining bits
            lsr ; shift accumulator right to get next bit
            sta MMC1_PRG ; send next bit to MMC1 PRG-ROM bank register
        .endrep

        jmp ($FFFC) ; jump to entry code
    entry_loader_end:

    ; subroutines
    .include "subroutines.asm"

.segment "RODATA"
    .include "entries.asm" ; entry titles and MMC1 control flags

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
    font_data_end:

.segment "VECTORS"
    .word on_vblank ; NMI handler address
    .word on_reset ; reset handler address

.include "data.asm" ; PRG-ROM and CHR-ROM entry data