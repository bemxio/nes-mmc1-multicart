wait_for_vblank:
    bit PPU_STATUS ; read PPU status register
    bpl wait_for_vblank ; loop until vblank flag is set

    rts ; return from subroutine

reset_scroll:
    lda #0 ; value for horizontal and vertical scroll

    sta PPU_SCROLL ; send value to PPU scroll register (horizontal)
    sta PPU_SCROLL ; send value to PPU scroll register (vertical)

    rts ; return from subroutine

read_joystick: ; https://www.nesdev.org/wiki/Controller_reading_code#Basic_Example
    lda #1 ; controller port latch bit
    sta JOY1 ; send value to controller port

    sta controls ; store accumulator in controls

    lsr ; reset accumulator
    sta JOY1 ; send value to controller port

    read_joystick_loop:
        lda JOY1 ; read value from controller port

        lsr ; shift value right to get next button state
        rol controls ; rotate bits left in controls

        bcc read_joystick_loop ; loop until all button states have been read

    rts ; return from subroutine

render_entry:
    lda #$20 ; high byte of background data address in PPU memory
    sta address + 1 ; store value in variable

    txa ; transfer offset to accumulator
    ldy #0 ; counter for multiplication

    render_entry_multiply:
        asl ; multiply offset by 2
        bcc :+ ; if carry bit is clear, skip incrementing high byte

        inc address + 1 ; increment high byte of entry title address
    :
        iny ; increment counter
        cpy #5 ; check if offset was shifted 5 times
        bne render_entry_multiply ; loop if not done

    clc ; clear carry bit
    adc #$20 ; skip first overscan line of background data
    sta address ; store result in variable

    lda PPU_STATUS ; reset address latch

    lda address + 1 ; high byte of background data address in PPU memory
    sta PPU_ADDR ; send value to PPU address register

    lda address ; low byte of address
    sta PPU_ADDR ; send value to PPU address register

    txa ; transfer offset to accumulator
    asl ; multiply offset by 2
    tay ; transfer result to Y register

    lda entry_titles, y ; load low byte of entry title address
    sta address ; store address in low byte of variable

    lda entry_titles + 1, y ; load high byte of entry title address
    sta address + 1 ; store address in high byte of variable

    lda title_lengths, x ; load length of entry title
    sta temp ; store length in temporary variable

    ldy #0 ; offset for entry title data

    render_entry_loop:
        lda (address), y ; load character from entry title

        cpx entry_index ; check if current entry is selected
        bne :+ ; if not, skip incrementing tile index

        clc ; clear carry bit
        adc #1 ; increment tile index
    :
        sta PPU_DATA ; send character to PPU data register

        iny ; increment offset for next character
        cpy temp ; check if all characters have been copied
        bne render_entry_loop ; loop if not done

    rts ; return from subroutine