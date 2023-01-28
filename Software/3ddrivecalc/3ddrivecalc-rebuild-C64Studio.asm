*= $0801
;simple basic start sys4096
!byte $0c,$08,$0a,$00,$9e,$34,$30,$39,$36,$00,$00,$00,$00


;special for c&a fan polish mag
;simple drivecalc vectors
;ca-fan.com.pl

;- drive variables
anglex   = $10  ;x,y,z angle
angley   = $11  ; 
anglez   = $12
zoom     = $13  ;zoom factor
ktoryw   = $15  ;actual point in structure
dana1    = $16  ;for calculations 
;-

ypoint   = $17   ;moment memory
zpoint   = $18   ;

angx     = $19   ;
angy     = $1a   ; offset for add to angle x,y,z
angz     = $1b   ;
;-
sinx     = $1c   ;actual sinus value x,y,z unsigned
siny     = $1d
sinz     = $1e

sinxsign = $1f   ;sign of sine x,y,x
sinysign = $20
sinzsign = $21

cosx     = $22    ;cosine value unsigned
cosy     = $23
cosz     = $24

cosxsign = $25    ;sign of cosine
cosysign = $26
coszsign = $27

;-
xprim    = $28   ;for rotations 3d moment values
yprim    = $29
zprim    = $2a

xbis     = $2b
ybis     = $2c

xlast    = $2d
zlast    = $2e
;-
sign     = $33  ;for multiply sign of result

mnozna   = $34  ;data for multiply
mnoznik  = $35
liczew   = $36   ;actual point in structure


tabx2d   = $50   ;tab of x,y after perspective
taby2d   = $68

ilew     = $80   ;how many point in structure
bryla    = $81   ;data structure to calculations

;--------
         *= $1000
;--------
;here basic started
         jmp runprg
;-
;send one byte to drive
senddriv
         pha
         lsr a
         lsr a
         lsr a
         lsr a
         tax

         bit $dd00
         bvc *-3

         sec
x4       lda $d012
         sbc #$32
         bcs x4    ;now only on the top and bottom border transfer
      ;  and #$07
      ;  beq x4
x5
         lda #$03
         sta $dd00
         lda tabkon,x
         sta $dd00
         lsr a
         lsr a
         and #$f7
         sta $dd00
         pla
         and #$0f
         tax
         lda tabkon,x
         sta $dd00
         lsr a
         lsr a
         and #$f7
         sta $dd00
         lda #$23
         nop
         nop
         nop
         sta $dd00
         rts
;- 
;nybbles to conversion send and $dd00 save
tabkon   !byte $07,$87,$27,$a7,$47,$c7
         !byte $67,$e7
         !byte $17,$97,$37,$b7,$57,$d7
         !byte $77,$f7
;-
;get one byte from drive
pob3     bit $dd00
         bvc *-3
         sec
         sei
raster   lda $d012
         sbc #$32
         bcc pob3a
         and #$07
         beq raster
pob3a
         lda #$03
         sta $dd00
         nop
         nop
         nop
         lda #$ff
         ldx #$23
         eor $dd00
         lsr a
         lsr a
         eor $dd00
         lsr a
         lsr a
         eor $dd00
         lsr a
         lsr a
         eor $dd00
         stx $dd00
         rts
;-
runprg
;soft iinit system
         sei
         lda #$37
         sta $01
         jsr $fda3
         jsr $ff5b
         lda #$01
         sta $0286
         jsr $e544
;print the info
         lda #<text
         sta $fb
         lda #>text
         sta $fc
         ldy #$00

cntprint
         lda ($fb),y
         beq exitprint
         jsr $ffd2
         iny
         bne cntprint
         inc $fc
         bne cntprint

exitprint

         sta $c6
         jsr $ffe4
         beq *-3
;wait for key

;set the vector for drive program in the ram c64
         lda #<adstart
         sta mew3+1

         lda #0
         sta mwrt

         lda #>adstart
         sta mew3+2
         lda $ba
         cmp #$08
         bcs notdrv
         lda #$08   ;drive  nr
         sta $ba
notdrv
;---
;error - drive not present
         ldx #3

mew      jsr listen
         bcc mewcnt
         rts
;memory write continue 3*32 bytes send under $0300 in drive
mewcnt
         ldy #$05
mew2     lda txmw,y
         jsr $ffa8
         dey
         bpl mew2

         ldy #$20
mew3     lda 1000
         jsr $ffa8
         inc mwrt
         inc mew3+1
         bne mew4
         inc mew3+2
mew4
         dey
         bne mew3
         jsr $ffae
         dex
         bne mew

;-
         jsr listen
;after memory write memory execute now
         ldy #$04

mex1     lda mex,y
         jsr $ffa8
         dey
         bpl mex1
         jsr $ffae
         sei
         lda #$23
         sta $dd00

         bit $dd00
;wait for drive program
         bvs *-3

;ok! now fast send data of all drive code
         iny
         sty $fd
         lda #<save
         sta $fb
         lda #>save
         sta $fc
         ldy #$00

send
         lda ($fb),y
         jsr senddriv
         iny
         bne send
         inc $fc
         inc $fd
         lda $fd
         cmp #$05
         bne send

;ok program resided in drive now
;-
         jmp dalej
;-

listen
         lda #$00
         sta $90
         lda $ba
         jsr $ffb1
         lda #$6f
         jsr $ff93
         lda $90
         bmi nodrive
         clc
         rts
nodrive  sec
         rts
;-
txmw
         !byte $20
         !byte 3
mwrt     !byte 0
         !text "w-m"
;-
mex
         !byte 3
         !byte 0
         !text "e-m"
;-
size1    !byte 44

cvect    !byte 0
;ĺĺĺĺĺĺĺ
lcface   !byte 2
walls    !byte 0,1,1,2,2,3,3,0,255,1 ;trace of drawing
         !byte 4,5,5,6,6,7,7,4,255,2
colors   !byte 1,2
pozwall  !byte 0
nrface   !byte 0
;ĺĺĺĺĺĺĺ
dalej
         sei

         ldy size1  ;value point of cube 44 now
         lda brylax
         asl a
         adc brylax
         tax

resize
         lda brylax,x
         php
         tya
         plp
         bpl noweb
         eor #$ff  ;or -44
         clc
         adc #$01
noweb
         sta brylax,x
         dex
         bne resize


         jsr initmltchr ;prepare multicolor chargen
         jsr sendall    ;send data to drive

;main loop here
loopto
         sei

calcos
         jsr getrot ;get precalculated data
         jsr sendrot;send operation type calculate again
         jsr clrchr;clear buffer


         lda #$00    ;drawing faces from 0 number of face
         sta pozwall
         sta nrface

loopcolor
         ldx nrface
         lda colors,x
         sta color
loopwall
         lda pozwall
         asl a
         tax

         lda walls,x
         bmi endsc

         tay
         lda mtabx2d,y
         clc

         adc #64
         lsr a  ;multicolor
         sta mx1

         lda mtaby2d,y
         clc
         adc #64
         sta my1

         inx
         lda walls,x
         tay

         lda mtabx2d,y
         clc
         adc #64
         lsr a  ;multicolor
         sta mx2

         lda mtaby2d,y
         clc
         adc #64
         sta my2

         jsr draw  ;draw line 

         inc pozwall
         jmp loopwall

endsc    inc pozwall 
         inc nrface  ;counter of faces 
         lda nrface
         cmp lcface  
         bne loopcolor

;-
;slow filled routine
         ldx #$00

         lda #$ff

         eor $3000,x
         sta $2000,x

         inx
         bne *-7


         lda #$ff

         eor $3100,x
         sta $2100,x

         inx
         bne *-7

         lda #$ff

         eor $3200,x
         sta $2200,x

         inx
         bne *-7


         lda #$ff

         eor $3300,x
         sta $2300,x

         inx
         bne *-7

         lda #$ff
         eor $3400,x
         sta $2400,x

         inx
         bne *-7


         lda #$ff
         eor $3500,x
         sta $2500,x

         inx
         bne *-7


         lda #$ff
         eor $3600,x
         sta $2600,x

         inx
         bne *-7


         lda #$ff

         eor $3700,x
         sta $2700,x

         inx
         cpx #$f8
         bne *-9

;test key for change rotation zoom etc.
         sei
         lda #$fd
         sta $dc00
         lda $dc01
         ora #$80
         cmp #$ff
         bne testkey
         ldx #$02
         stx $dc00
         cmp $dc01
         beq cntn

testkey
         lda #$7f
         sta $dc00
         lda $dc01

         jmp chkey

cntn2
         lda $dc01
         cmp $dc01
         beq *-3
cntn
         jmp loopto

;ĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺ
chkey
         cmp #$ef
         bne chkey0
         cmp $dc01
         beq *-3
         lda #$00
         sta $dc00

         lda $dc01
         cmp $dc01
         beq *-3
         jmp cntn2

chkey0
         cmp #$bf  ;q
         bne chkey01
         cmp $dc01
         beq *-3
         jsr getrot
         lda #$00
         jsr senddriv
         lda #$08
    ;    sta $de00
    ;    jmp ($fffc)
         jmp $9000

chkey01
         lda #$fd
         sta $dc00
         lda $dc01
         ldx #$fe
         stx $dc00
         cmp #$7f
         bne chkey5
         lda $dc01
         cmp #$f7   ;f8
         bne chkey2
         lda zomik
         sec
         sbc #$0a
         bcc sendprm
storezom
         sta zomik
sendprm
         jsr getrot
         jsr sendpar
         jmp cntn
chkey2
         cmp #$bf   ;f6
         bne chkey3
         dec manglez
         jmp sendkey

chkey3
         cmp #$df   ;f4
         bne chkey4
         dec mangley
         jmp sendkey

chkey4
         cmp #$ef   ;f2
         bne chkey9    ;!!!
         dec manglex
         jmp sendkey
chkey5
         lda $dc01
         cmp #$f7   ;f7
         bne chkey6
         lda zomik
         clc
         adc #$0a
         bcc storezom
         bcs sendprm
chkey6
         cmp #$bf   ;f5
         bne chkey7
         inc manglez
         jmp sendkey

chkey7
         cmp #$df   ;f3
         bne chkey8
         inc mangley
         jmp sendkey

chkey8
         cmp #$ef   ;f1
         bne chkey9
         inc manglex
         jmp sendkey
chkey9
         lda #$fb
         sta $dc00
         lda $dc01
         cmp #$7f  ;x
         bne chkey10
         lda manglex
         eor #$ff
         clc
         adc #$01
         sta manglex
sendkey
         lda $dc01
         cmp $dc01
         beq *-3
         jmp sendprm
chkey10
         cmp #$ef ;c
         bne chkey10a
         lda cvect
         eor #"c"
         sta cvect
         cmp #"c"
         bne chkey10b
         jsr cyber
         jmp test10b
chkey10b
         jsr nocyber
test10b
         jmp cntn2


chkey10a
         cmp #$fd   ;r
         bne chkey11
         cmp $dc01
         beq *-3
         jsr getrot
         lda #"z"
         jsr senddriv
         jsr sendpar
         jmp cntn
chkey11
         lda #$fd
         sta $dc00
         lda $dc01
         cmp #$ef   ;z
         bne chkey12
         lda manglez
         eor #$ff
         clc
         adc #$01
         sta manglez
         jmp sendkey

chkey12
         lda #$f7
         sta $dc00
         lda $dc01
         cmp #$fd   ;y
         bne chkey13
         lda mangley
         eor #$ff
         clc
         adc #$01
         sta mangley
         jmp sendkey
chkey13
         cmp #$ef   ;b
         bne chkey14
         ldx #$02
chk13a
         lda manglex,x
         eor #$ff
         clc
         adc #$01
         sta manglex,x
         dex
         bpl chk13a
         jmp sendkey

chkey14
         lda #$ef
         sta $dc00
         lda $dc01
         cmp #$f7   ;0
         bne chkey16
         lda #$00
         sta manglex
         sta mangley
         sta manglez
         jmp sendkey

chkey16
         jmp cntn
;ĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺĺ
;--- get data after projection
getrot
         bit $dd00
         bvc *-3
         sei
         sec
         lda $d012
         sbc #$32
         bcs *-5
         ldy #$00
getrot2
         jsr pob3
         sta mtabx2d,y
         jsr pob3
         sta mtaby2d,y
         iny
         cpy brylax
         bne getrot2
         rts
;--- operation type rotate - calculate again
sendrot
         lda #"r"
         jmp senddriv
;---
sendall
         ldy #$00
sal2
         lda mdata,y
         jsr senddriv
         iny
         cpy lenobj  ;length of data
         bne sal2
         rts
;ĺĺ
sendpar
         ldy #$00
sendp2
         lda params,y
         jsr senddriv
         iny
         cpy #$06
         bne sendp2
         rts
;--------
lenobj   !byte 32  ;length data
mdata    !text "w" ;operation type


brylax   !byte 8   ;8 point to calculate in structure
;--------
;point of figure x,y,z 8 times
brylka
;---           x  y  z

         !byte 50,50,50
         !byte 50,$ce,50
         !byte $ce,$ce,50
         !byte $ce,50,50

         !byte 50,50,$ce
         !byte 50,$ce,$ce
         !byte $ce,$ce,$ce
         !byte $ce,50,$ce
;---

params   !text "p" ;operation send params for drive

manglex  !byte 3  ;value angle x,y,z
mangley  !byte 0
manglez  !byte 4
zomik    !byte $ff  ;zoom factor
         !text "r" ;operation code read

;data after projections
mtabx2d
         !byte $ff,$ff,$ff,$ff,$ff,$ff
         !byte $ff,$ff,$ff,$ff,$ff,$ff
         !byte $ff,$ff,$ff,$ff,$ff,$ff
         !byte $ff,$ff,$ff,$ff,$ff,$ff
mtaby2d
         !byte $ff,$ff,$ff,$ff,$ff,$ff
         !byte $ff,$ff,$ff,$ff,$ff,$ff
         !byte $ff,$ff,$ff,$ff,$ff,$ff
         !byte $ff,$ff,$ff,$ff,$ff,$ff
;----------------
tbadln   = $4000 ;tabels addres 

strtln   = $3000  ;start of buffer
endln    = $3800  ;end of buffer

vline    = $4800 ;vertical line draving 
fline    = $4d00 ;flat line

bits     = $e0  ;color of line

dx       = $32   ;delta x,y
dy       = $33

x1       = $2a   ;points of lines to drawing
x2       = $2b

y1       = $2c
y2       = $2d

vectr1   = $fb  ;vector for read many data (pointer)
;--------
initmltchr

         jsr clrchr    ;clear chargen
         jsr prepline  ;make speedcode drawnig line
         jsr nocyber   ;no cyber vector presentation

;now graph init
         lda #$18
         sta $d018

         lda $d016
         ora #$10
         sta $d016

         lda #$00
         sta $d020
         lda #$06
         sta $d021

         lda #$05
         sta $d022

         lda #$04
         sta $d023

         lda #$03
         sta $d024

         lda #$04
         sta $d025
         ldx #$00

fkl
         lda #$09

         sta $d800,x
         sta $d8e0,x
         lda #$0a
         sta $d9e0,x
         sta $da00,x
         sta $daf8,x

         inx
         bne fkl

         rts
;--------
;cyber vector presentation
cyber

         lda #$04
         sta $fc
         ldx #$00
         lda #$04
         sta $fb
         lda #$00

cyber1
         sta $0400,x
         sta $0500,x
         sta $0600,x
         sta $06f8,x
         inx
         bne cyber1

         ldx #$02

cyber2
         txa

         ldy #$00
cyber3
         sta ($fb),y
         iny
         sta ($fb),y
         clc
         adc #$10
         iny
         bcc cyber3
         lda $fb
         clc
         adc #$28
         sta $fd
         lda $fc
         adc #$00
         sta $fe
         cpx #14
         beq cyber5
         ldy #$27
cyber4
         lda ($fb),y
         sta ($fd),y
         dey
         bpl cyber4
cyber5
         lda $fb
         clc
         adc #$50
         sta $fb
         lda $fc
         adc #$00
         sta $fc
         inx
         cpx #15
         bne cyber2


         rts
;ĺĺĺĺ
;prepare view of chargen 128x128
nocyber
         lda #$04
         sta $fc
         ldx #$00
         lda #$ac
         sta $fb
         lda #$00

filed1
         sta $0400,x
         sta $0500,x
         sta $0600,x
         sta $06f8,x
         inx
         bne filed1

         ldx #$00

plan1
         txa

         ldy #$00
plan2
         sta ($fb),y
         clc
         adc #$10
         iny
         bcc plan2
         lda $fb
         clc
         adc #$28
         sta $fb
         lda $fc
         adc #$00
         sta $fc
         inx
         cpx #$10
         bne plan1

         lda $fb
         sec
         sbc #$28
         sta $fb

         lda $fc
         sbc #$00
         sta $fc
         lda #$00
         ldy #$0f
         sta ($fb),y
         rts
;--------
;make speedcode for drawing line
prepline
         lda #<vline
         sta $fb
         lda #>vline
         sta $fc
         lda #<fline
         sta $fd
         lda #>fline
         sta $fe
         lda #<strtln
         sta adln1
         sta adln1a
         lda #>strtln
         sta adln1+1
         sta adln1a+1
         ldx #$ff

lop0prp
         lda #<bits
         sta cell

lop1prp
         lda #$c8
         sta linia1b

         ldy #$00
prepl1
         lda linia1,y
         sta ($fb),y
         iny
         cpy #$13
         bne prepl1

         ldy #$00

         lda #$88
         sta linia1b

prepl2
         lda linia1,y
         sta ($fd),y
         iny
         cpy #$13
         bne prepl2

         inx
         lda $fc
         sta tbadln+$40,x
         lda $fe
         sta tbadln+$80,x

         lda $fb
         sta tbadln,x

        ;lda $fb
         clc
         adc #$13
         sta $fb
         sta $fd
         bcc prepl3
         inc $fc
         inc $fe
prepl3   ldy cell
         iny
         sty cell
         cpy #<bits+4
         bcc lop1prp

         lda adln1
         clc
         adc #$80
         sta adln1
         sta adln1a
         bcc prepl4
         inc adln1+1
         inc adln1a+1
prepl4   lda adln1+1
         cmp #>endln
         bcc lop0prp

         rts
;--------
linia1
         txa
         adc dy
         bcc linia1a

linia1b  iny
         sbc dx
         bcs linia1b
linia1a  tax

cell     = *+1
         lda $e0

adln1    = *+1
         eor $2000,y

adln1a   = *+1
         sta $2000,y
;------
;clear data buffer
clrchr
         ldx #$00
         txa

clrc2    sta strtln,x
         sta strtln+$0100,x
         sta strtln+$0200,x
         sta strtln+$0300,x
         sta strtln+$0400,x
         sta strtln+$0500,x
         sta strtln+$0600,x
         sta strtln+$0700,x
         inx
         bne clrc2

drwex    rts
;---
;draw line now
draw

         lda color
         and #$03
         sta bits+3
         asl a
         asl a
         sta bits+2
         asl a
         asl a
         sta bits+1
         asl a
         asl a
         sta bits

         lda my1
         sta y1
         lda my2
         sta y2
         lda mx1
         sta x1
         lda mx2
         sta x2

       ; lda x2
         sec
         sbc x1
         beq drwex
         bcs storedx
         ldx x1
         ldy x2
         stx x2
         sty x1

         ldx y1
         ldy y2
         stx y2
         sty y1
         eor #$ff
         adc #$01
storedx
         sta dx
         sec
         lda y2
         sbc y1
         ldx x1
         ldy x2
         bcs verline
         eor #$ff
         adc #$01
         sta dy

         lda tbadln+$80,x
         sta adlin1+1

         lda tbadln+$80,y
         sta vectr1+1
rysuje
         lda tbadln,x
         sta adlin1
         lda tbadln,y
         sta vectr1

         lda #$60
         ldy #$00
         sta (vectr1),y
         ldx #$ff
         ldy y1

         sei

         clc
adlin1   = *+1
         jsr $1000
         ldy #$00
         lda #$8a
         sta (vectr1),y
         rts
verline
         sta dy

         lda tbadln+$40,x
         sta adlin1+1

         lda tbadln+$40,y
         sta vectr1+1

         jmp rysuje

;---
mx1      !byte 0
mx2      !byte 63
my1      !byte 0
my2      !byte 127
color    !byte 3
;---
text
         !text "wegi for c&a fan - driv"
         !text "ecalc vectors"
         !byte 13,13,13
         !text "f1/f2 x axis rotate +/-"
         !byte 13
         !text "f3/f4 y axis rotate +/-"
         !byte 13
         !text "f5/f6 z axis rotate +/-"
         !byte 13,13
         !text "f7/f8 zoom +/-"
         !byte 13,13
         !text "x inverse x rotation"
         !byte 13
         !text "y inverse y rotation"
         !byte 13
         !text "z inverse z rotation"
         !byte 13,13
         !text "b back all rotation"
         !byte 13
         !text "0 stop rotation"
         !byte 13,13
         !text "r reset position"
         !byte 13
         !text "c cyber vector switch!"
         !byte 13,13,13
         !text "q to quit or space "
         !text "key to pause"
         !byte 13,13,13
         !text "made in poland 2010.01."
         !text "14"
         !byte 0
;--------
;---     start drive code
;--------
save
;--------
.driverun = $0300
         pseudopc = driverun
         .offs = save-psuedopc
.ofsetto  = driverun-save
;--------
.adstart  = save+$0300-driverun
;---
starter
         sei
         lda #$7a
         sta $1802
         jsr setline
         ;delay loop
         jsr $f5e9
         ldx #$05
gtprg
         jsr readblok
         inc addr
         dex
         bne gtprg
         jmp runldr
;---
readone
;get one byte from c64
         ldy #$ff
         !byte $2c
;-
readblok ldy #$00
;-
readbt
         lda #$00
         sta $1800
wtr1     lda $1800
         bne *-3
         php
         lda $1800
         asl a
         plp
         eor $1800
         asl a
         asl a
         asl a
         nop
         nop
         nop
         eor $1800
         asl a
         nop
         nop
         nop
         eor $1800
addr     = *+2
         sta $0300,y
         sta lastget
       ; nop
         iny
         bne wtr1
setline
         lda #$08
         sta $1800
lastget  = *+1
         lda #$00
         rts
;--------
;rewrite on the self ! :)
;--------
;nybbles to convert $1800 serial port
bin2ser  !byte $0f,$07,$0d,$05,$0b,$03
         !byte $09,$01
         !byte $0e,$06,$0c,$04,$0a,$02
         !byte $08,$00
;--------
;send one byte to c64
sendone  tay
         and #$0f
         tax
         tya
         lsr a
         lsr a
         lsr a
         lsr a
         tay
         sei
         lda #$00
         sta $1800
         lda bin2ser,x
         ldx $1800
         bne *-3
         sta $1800
         asl a
         and #$0a
         sta $1800
         lda bin2ser,y
         sta $1800
         asl a
         and #$0a
         sta $1800
         jmp setline
;-
; stop rotates
zeroang
         lda #$00
         sta angx
         sta angy
         sta angz
         rts
;-
;slow multiply routine
procka
         bpl lp1
         eor #$ff
         clc
         adc #$01

lp1      sta mnozna
         sty mnoznik

         lda #$00
         ldx #$08
lp1a
         ror mnoznik
         bcc lp2
         clc
         adc mnozna
lp2      ror a
         dex
         bne lp1a


         bit sign
         bpl lp3

         eor #$ff
         clc
         adc #$01
lp3
         rts

;--------
rotates
         ldx #$02
;--------
; cosinus zyx & sign cosinus zyx
;--------
findsine
;---
         lda #$00        ;sign +
         sta cosxsign,x

         lda anglex,x
         clc
         adc angx,x

         sta angx,x

         cmp #$40        ;cos angle zyx
         bcc finds3      ;sign +
         cmp #$c0
         bcs finds2      ;sign +
         dec cosxsign,x  ;sign -
finds2
         clc      ;add quarter period
finds3   adc #$40 ;to cos.
         and #$7f ;modulo half period
         tay
         lda sine,y
         sta cosx,x
;------
;---     sinus zyx
;------
         lda angx,x  ;ang is also sign
         and #$7f    ;like before
         tay
         lda sine,y
         sta sinx,x
;---
         dex
         bpl findsine

;--------
         inx
;--------
rotpoints
         txa
         sta liczew

         asl a
         adc liczew
         tax        ;pointnr *3
         ldy #$00

         lda bryla,x
         sta xprim     ;xprim=x
         lda bryla+1,x
         sta ypoint
         lda bryla+2,x
         sta zpoint

;--------
;-  y prim
;--------
;if you wanna test rotate you can deleted ";" char
      ;  ldx anglex
      ;  bne axisx
      ;  ldx ypoint
      ;  stx ybis
      ;  jmp storezprim

axisx
         ldy sinx
                   ;in acc zpoint
         eor angx
         sta sign
         lda zpoint   ;sin(angx)*z
         jsr procka
         sta dana1

         ldy cosx
         lda ypoint   ;cos(angx)*y
         eor cosxsign

         sta sign
         lda ypoint

         jsr procka
         sec       ;cos(x)*y - sin(x)*z
         sbc dana1 ;substr.

         sta ybis  ;y prim = y bis

;--------
;--- z prim
;--------

         ldy sinx
         lda ypoint

         eor angx
         sta sign
         lda ypoint   ;sin(angx)*y
         jsr procka
         sta dana1

         ldy cosx
         lda zpoint   ;cos(angx)*z
         eor cosxsign

         sta sign
         lda zpoint

         jsr procka
         clc        ;sin(x)*y + cos(x)*z
         adc dana1  ;sum

storezprim

         sta zprim
;--------
;--- x bis
;--------
      ;  ldx angley
      ;  bne axisy
      ;  ldx xprim
      ;  stx xbis
      ;  jmp storezlast
axisy
         ldy cosy
         lda xprim
         eor cosysign
         sta sign
         lda xprim    ;cos(angy)*x'
         jsr procka
         sta dana1

         ldy siny
         lda zprim    ;sin(angy)*z'
         eor angy
         sta sign
         lda zprim

         jsr procka

                ;cos(y)*x' + sin(y)*z'
         clc
         adc dana1  ;sum

         sta xbis
;--------
;--- z bis = z last
;--------

         ldy siny
         lda xprim
         eor angy
         sta sign
         lda xprim    ;sin(angy)*x'
         jsr procka
         sta dana1

         ldy cosy
         lda zprim    ;cos(angy)*z'
         eor cosysign

         sta sign
         lda zprim

         jsr procka
         sec
                 ;sin(y)*x' - cos(y)*z'

         sbc dana1  ;substr.

storezlast
               ;!!!rule for z observ.
         clc
         adc #$80
         tay
         lda zdiv,y
         sta zlast    ;zbis = zlast
;--------
;--- x last
;--------
      ;  lda ybis
      ;  ldx anglez
      ;  bne axisz
      ;  ldx xbis
      ;  stx xlast
      ;  jmp getylast
axisz
         ldy sinz
         lda ybis
         eor angz
         sta sign
         lda ybis     ;sin(angz)*y''
         jsr procka
         sta dana1

         ldy cosz
         lda xbis     ;cos(angz)*x''
         eor coszsign
         sta sign
         lda xbis

         jsr procka
         sec
              ;sin(z)*y'' - cos(z)*x''

         sbc dana1  ;substr.
         sta xlast
;--------
;--- y last
;--------
         ldy sinz
         lda xbis
         eor angz
         sta sign
         lda xbis     ;sin(angz)*x
         jsr procka
         sta dana1

         ldy cosz
         lda ybis     ;cos(angz)*y
         eor coszsign
         sta sign
         lda ybis

         jsr procka
         clc        ;sin(z)*x + cos(z)*y
         adc dana1  ;sum

getylast
        ;tay        ;ylast
;-------
prspct
;---
         ldy zlast
         eor zlast  ;lose acc
         sta sign
         eor zlast  ;recall acc

         jsr procka
         ldy zoom
         cpy #$fc  ;zoom  factor =1?
         bcs storey2d
         sta sign
         tax       ;only for bpl/bmi
         jsr procka
storey2d
         ldx liczew
         sta taby2d,x
;----------
         ldy zlast
         lda xlast
         eor zlast ;lose acc
         sta sign
         eor zlast ;recall acc
persp4
         jsr procka
         ldy zoom
         cpy #$fc
         bcs storex2d
         sta sign
         tax
         jsr procka

storex2d
         ldx liczew
         sta tabx2d,x
cntrot
         inx
         cpx ilew
         beq rtpsex
         jmp rotpoints
rtpsex
         rts
;--------
sine
         !byte $00,$06,$0c,$12,$19,$1f
         !byte $25,$2b,$31,$38,$3e,$44
         !byte $4a,$50,$56,$5c,$61,$67
         !byte $6d,$73,$78,$7e,$83,$88
         !byte $8e,$93,$98,$9d,$a2,$a7
         !byte $ab,$b0,$b5,$b9,$bd,$c1
         !byte $c5,$c9,$cd,$d1,$d4,$d8
         !byte $db,$de,$e1,$e4,$e7,$ea
         !byte $ec,$ee,$f1,$f3,$f4,$f6
         !byte $f8,$f9,$fb,$fc,$fd,$fe
         !byte $fe,$ff,$ff,$ff,$ff,$ff
         !byte $ff,$ff,$fe,$fe,$fd,$fc
         !byte $fb,$f9,$f8,$f6,$f4,$f3
         !byte $f1,$ee,$ec,$ea,$e7,$e4
         !byte $e1,$de,$db,$d8,$d4,$d1
         !byte $cd,$c9,$c5,$c1,$bd,$b9
         !byte $b5,$b0,$ab,$a7,$a2,$9d
         !byte $98,$93,$8e,$88,$83,$7e
         !byte $78,$73,$6d,$67,$61,$5c
         !byte $56,$50,$4a,$44,$3e,$38
         !byte $31,$2b,$25,$1f,$19,$12
         !byte $0c,$06
;-----
runldr
;-----
;main loop in drive

         lda #$00
         sta addr
zerujobr
         jsr zeroang

mainloop
         jsr readone
         cmp #"z"
         beq zerujobr ;zeroang
         cmp #"p"
         bne mlp2
         ldx #$00     ;getparams
mlp1
         jsr readone
         sta anglex,x
         inx
         cpx #$04
         bne mlp1
         beq mainloop

mlp2     cmp #"r"     ;rotate3d
         bne mlp3
         jsr rotates
         lda $1c00 ;blink
         eor #$08
         sta $1c00
         ldx #$00
         stx liczew
         
         ;send data after projection
mlp2a
         lda tabx2d,x
         jsr sendone
         ldx liczew
         lda taby2d,x
         jsr sendone
         inc liczew
         ldx liczew
         cpx ilew
         bne mlp2a
         beq mainloop

mlp3     cmp #"w"
         bne reset
         jsr readone
         sta ilew
         asl a
         clc
         adc ilew
         sta dana1
         ldx #$00
mlp3a
         jsr readone
         sta bryla,x
         inx
         cpx dana1
         bne mlp3a
         beq mainloop
reset
         jmp ($fffc)
;--------
;codes:
;z - zeroang
;p - get 3 params
;r - rotate3d and send 2d
;w - write data of object
;--------
zdiv
         !byte $eb,$eb,$eb,$eb,$eb,$eb
         !byte $eb,$eb,$eb,$eb,$eb,$ea
         !byte $ea,$ea,$ea,$ea,$ea,$ea
         !byte $ea,$ea,$ea,$e9,$e9,$e9
         !byte $e9,$e9,$e9,$e9,$e9,$e9
         !byte $e8,$e8,$e8,$e8,$e8,$e8
         !byte $e8,$e8,$e8,$e7,$e7,$e7
         !byte $e7,$e7,$e7,$e7,$e7,$e6
         !byte $e6,$e6,$e6,$e6,$e6,$e6
         !byte $e5,$e5,$e5,$e5,$e5,$e5
         !byte $e5,$e4,$e4,$e4,$e4,$e4
         !byte $e4,$e3,$e3,$e3,$e3,$e3
         !byte $e3,$e2,$e2,$e2,$e2,$e2
         !byte $e2,$e1,$e1,$e1,$e1,$e1
         !byte $e0,$e0,$e0,$e0,$e0,$df
         !byte $df,$df,$df,$de,$de,$de
         !byte $de,$dd,$dd,$dd,$dd,$dc
         !byte $dc,$dc,$dc,$db,$db,$db
         !byte $db,$da,$da,$da,$d9,$d9
         !byte $d9,$d9,$d8,$d8,$d8,$d7
         !byte $d7,$d7,$d6,$d6,$d6,$d5
         !byte $d5,$d4,$d4,$d4,$d3,$d3
         !byte $d2,$d2,$d2,$d1,$d1,$d0
         !byte $d0,$cf,$cf,$ce,$ce,$cd
         !byte $cd,$cc,$cc,$cb,$cb,$ca
         !byte $ca,$c9,$c8,$c8,$c7,$c6
         !byte $c6,$c5,$c4,$c4,$c3,$c2
         !byte $c1,$c1,$c0,$bf,$be,$bd
         !byte $bc,$bb,$bb,$ba,$b9,$b8
         !byte $b7,$b5,$b4,$b3,$b2,$b1
         !byte $af,$ae,$ad,$ab,$aa,$a9
         !byte $a7,$a5,$a4,$a2,$a0,$9e
         !byte $9c,$9b,$98,$96,$94,$92
         !byte $8f,$8d,$8a,$87,$84,$81
         !byte $81,$81,$81,$81,$81,$81
         !byte $81,$81,$81,$81,$81,$81
         !byte $81,$81,$81,$81,$81,$81
         !byte $81,$81,$81,$81,$81,$81
         !byte $81,$81,$81,$81,$81,$81
         !byte $81,$81,$81,$81,$81,$81
         !byte $81,$81,$81,$81,$7f,$7f
         !byte $7f,$7f,$7f,$7f,$7f,$7f
         !byte $7f,$7f,$7f,$7f