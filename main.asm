
; 2017.09.13
;
; marcel timm, rhinodevel

; cbm pet

*=634 ;tape buf. #1 and #2 used (192+192 bytes)

; system sub routines

clrscr   = $e236          ;$e246
;strout   = $ca27          ;$ca1c
crlf     = $c9d2          ;$c9e2
wrt      = $ffd2
get      = $ffe4

; "constants"

chr_stop = 3
chr_0    = $30
chr_a    = $41
chr_spc  = $20

cursor   = $e0          ;$c4
time     = 514          ;143          ;low byte of time
di       = 59459          ;data direction reg.
io       = 59471          ;i/o port

adptr    = 6           ;15 ;unused terminal & src. width
de       = 1           ;1/60secs.bit read delay

; *** main ***

         jsr clrscr
         lda #chr_a
         jsr wrt  
         jsr crlf       
         lda #1
         sta run
         jmp begin

         jsr clrscr
         lda #0
         sta run

begin    cld ;probably not necessary

         jsr out2high

         lda di
         ora #2
         sta di

         jsr togout

         jsr readbyte
         sta adptr
         jsr readbyte
         sta adptr+1
         lda adptr+1
         jsr printby
         lda adptr
         jsr printby
         
         lda #chr_spc
         jsr wrt

         jsr readbyte
         sta lel
         jsr readbyte
         sta leh
         lda leh
         jsr printby
         lda lel
         jsr printby
         jsr crlf

keywait  jsr get
         beq keywait
         cmp #chr_stop
         bne cursave
         jsr out2high
         rts

cursave  lda cursor
         sta deb0
         lda cursor+1
         sta deb1
         lda cursor+2
         sta deb2
nextpl   jsr get
         beq contpl
         cmp #chr_stop
         bne contpl
         jsr out2high
         rts
contpl   lda deb0
         sta cursor
         lda deb1
         sta cursor+1
         lda deb2
         sta cursor+2
         lda adptr+1
         jsr printby
         lda adptr
         jsr printby
         lda #chr_spc
         jsr wrt
         lda leh
         jsr printby
         lda lel
         jsr printby
         jsr readbyte
         ldy #0
         sta (adptr),y
         inc adptr
         bne decle
         inc adptr+1
decle    dec lel
         lda lel
         cmp #$ff
         bne nextpl
         dec leh
         lda leh
         cmp #$ff
         bne nextpl
         jsr crlf

         jsr out2high

         lda run
         beq end
         jmp (adptr)

end      rts

; *** "toggle" output based on variable o ***

togout   lda o         ;"toggle" depending on o
         beq toghigh
         lda io        ;toggle output to low
         and #253
         jmp togdo
toghigh  lda io        ;toggle output to high
         ora #2
togdo    sta io        ;does not work in vice (v3.1)!
         lda #1
         sec
         sbc o
         sta o
         rts

; *** set output to high ***

out2high lda #0
         sta o
         jsr togout
         rts

; *** wait 1/60 secs.in constant de ***

waitde   sei           ;no update during read
         lda time      ;read low byte of time
         cli
         clc
         adc #de       ;calculate resume time
delay    cmp time      ;loop, untile resume
         bne delay     ;time is reached
         rts

;*** read a byte into accumulator ***

readbyte ldy #0        ;byte buffer during read
         ldx #1        ;to hold 2^exp
readloop jsr waitde
         lda io
         and #1
         beq readnext  ;bit read is zero
         stx buf       ;bit read is one, add to byte (buffer)
         tya           ;get current byte buffer content
         ora buf       ;"add" current bit read
         tay           ;save into byte buffer
readnext txa           ;get next 2^exp
         asl
         tax
         jsr togout    ;acknowledge
         cpx #0        ; last bit read?
         bne readloop
         tya           ;get byte read into accumulator
         rts

; *** print "hexadigit" (hex.0-f) stored in accumulator ***

printhd  and #$0f      ;ignore left 4 bits
         cmp #$0a
         bcc printd
         clc           ;more or equal $0a - a to f
         adc #chr_a-$0a
         bcc print
printd   clc           ;less than $0a - 0 to 9
         adc #chr_0
print    jsr wrt
         rts

; *** print byte in accumulator as hexadecimal value ***

printby  ldx #4
         tay
prbloop  lsr a
         dex
         bne prbloop
         jsr printhd
         tya
         jsr printhd
         rts

; variables

run      byte 0 ;run after load yes/no
o        byte 0 ;output val.
buf      byte 0 ;byte buffer ;todo: use zero page
lel      byte 0 ;count of payload bytes
leh      byte 0 ;
deb0     byte 0
deb1     byte 0
deb2     byte 0

; data
