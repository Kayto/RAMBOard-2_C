;- ========================================
;- Project    RAMBOard1541FORMAT 41 Tracks ASM (CBM prg Studio)
;- Target     Commodore 64
;- Comments   ASM Drive Code based on 64'er format41 adapted and commented
;-            by AdamT117, to use the RAMBOard. 
;-            Save to disk as format.1541.obj
;- Author     AdamT117. https://github.com/Kayto
;- ========================================
;drivecode
*=$8000
          LDA            $43       ;Number of sectors per track for formatting
          BPL            b8014
          LDA            #$00
          STA            $44       ;Temp. work area; Scratch pad
          LDA            $1C00     ;PB, control port B
          AND            #$9F
          STA            $1C00     ;PB, control port B
          LDA            #$11
          STA            $43       ;Number of sectors per track for formatting
b8014     LDA            $40       ;Byte counter for GCR conversion
          CMP            $51       ;Current track number for formatting [FF]
          BNE            b801d
          JMP            $FB00     ; check for write protect tab
b801d     JMP            $FD96     ; all track done;exit
          BRK
          BRK
          BRK
          BRK
          BRK
          BRK
          BRK
          BRK
          BRK
          LDY            #$06      ;#$06
          LDA            $0503     ;Disk ID, drive 0
          STA            $12
          LDA            $0504
          STA            $13
          JSR            $D307     ;$D307 Close all channels
          JSR            $CC7C     ;load .a with the .y th character from the command string
          CPX            #$01
          BEQ            b8042
          JMP            $CC26     ;load .a with $31 to indicate a bad command and jmp to CMDERR ($c1c8)
b8042     LDA            $0285     ;Sector of a file
          STA            $0C       ;Track and sector for buffer 3
          LDA            #$00
          STA            $0D
          JSR            $C100     ;$C100 Turn LED on for current drive
          BIT            $6A       ;Number of read attempts [5]
          BMI            b805a
          LDA            #$C0
          STA            $03       ;Command code for buffer 3
b8056     LDA            $03       ;Command code for buffer 3
          BMI            b8056
b805a     LDA            #$A0
          STA            $8021
          LDA            #$0F
          STA            $8022
          LDA            $0C       ;Track and sector for buffer 3
          STA            $51       ;Current track number for formatting [FF]
          LDA            #$E0
          STA            $03       ;Command code for buffer 3
b806c     LDA            $03       ;Command code for buffer 3
          BMI            b806c
          CMP            #$02
          BCC            b8079
          LDX            #$03
          JMP            $E60A     ;$E60A Prepare error number and message
b8079     INC            $0C       ;Track and sector for buffer 3
          LDA            $0286
          CMP            $0C       ;Track and sector for buffer 3
          BCS            $8064
          RTS