* =$8100
        lda $b4
        pha
        lda $b5
        pha

; saving the value $0300 to $00b4 (low byte order)
        lda #$00
        sta $b4
        lda #$03
        sta $b5
        ldy #$00
;adding 5 to the value of every memory address from $0300 to $0304
loop
        clc
        lda #$05
        adc ($b4),y
        sta ($b4),y
        iny
        cpy #$08
        bne loop
; restoring saved values
        pla
        sta $b5
        pla
        sta $b4
;return from subroutine
        rts