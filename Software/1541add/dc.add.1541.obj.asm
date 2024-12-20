;
; This assembly file provides code to be loaded and executed on the Commodore 1541 disk drive.
; It corresponds to the BASIC program described in the README, which initializes the drive, loads this code,
; and executes it to perform addition operations within the 1541 drive.
; The BASIC program uses direct access commands to load this code into the drive's memory and execute it.
;

* =$8100
; Start of the program at memory location $8100 - this assumes a RAMBOard
; if no RAMBOArd present then change to $0400, this uses the 1541 RAM buffer.

        lda $b4
        pha
        lda $b5
        pha
; Save the current values of $b4 and $b5 (used for indirect addressing) onto the stack

; saving the value $0300 to $00b4 (low byte order)
; the value $0300 relates to the memory address of the input/output numbers, this address is within the 1541 RAM buffer
        lda #$00
        sta $b4
        lda #$03
        sta $b5
; Set $b4 and $b5 to point to the memory address $0300 (low byte first, then high byte)

        ldy #$00
; Initialize Y register to 0, used as an index for looping

;adding 5 to the value of every memory address from $0300 to $0304
loop
        clc
        lda #$05
        adc ($b4),y
        sta ($b4),y
; Add 5 to the value at the memory address pointed to by ($b4),y and store the result back

        iny
        cpy #$08
; Increment Y and compare it to 8 (loop limit)

        bne loop
; If Y is not equal to 8, repeat the loop

; Restore the original values of $b4 and $b5 from the stack
        pla
        sta $b5
        pla
        sta $b4

        rts
; Return from subroutine
