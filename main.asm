
; 2017.09.13
;
; marcel timm, rhinodevel

; cbm pet

; configured for basic 2.0 / rom v3.
; can be reconfigured for basic 1.0 / rom v2 by
; replacing values with following values in comments
; (if there are no commented-out values following,
; these addresses are equal).

*=634 ;tape buf. #1 and #2 used (192+192=384 bytes)

; -------------------
; system sub routines
; -------------------

crlf     = $c9e2       ;$c9d2 <- basic 1.0 / rom v2 value
wrt      = $ffd2
get      = $ffe4

run      = $c785       ;$c775 ;basic run
clrscr   = $e229       ;$e236
;new      = $c55b       ;$c551 ;basic new
;clr      = $c577       ;$c770 ;basic clr
;strout   = $ca1c       ;$ca27

; ---------------
; system pointers
; ---------------

varstptr = 42;124 ;pointer to start of basic variables
;varenptr = 44;126 ;pointer to end of basic variables
;arrenptr = 46;128 ;pointer to end of basic arrays

;runl1ptr = 49172 ;pointer-1 to basic run cmd.
;newl1ptr = 49220 ;pointer-1 to basic new cmd.
;clrl1ptr = 49208 ;pointer-1 to basic clr cmd.

; -----------
; "constants"
; -----------

chr_stop = 3
chr_0    = $30
chr_a    = $41
chr_spc  = $20

tapbufin = $bb         ;$271 ;tape buffer #1 and #2 indices to next char (2 bytes)
cursor   = $c4         ;$e0
time     = 143         ;514 ;low byte of time
di       = 59459       ;data direction reg.
io       = 59471       ;i/o port
defbasic = $401        ;default start addr.of basic prg

adptr    = 15          ;6 ;unused terminal & src. width
de       = 1           ;1/60secs.bit read delay

; ------
; macros
; ------

;; **********************************************
;; *** call a basic command and exit to basic ***
;; **********************************************
;
;defm  basiccmx
;      lda /1+1
;      pha
;      lda /1
;      pha
;      lda #0
;      rts
;      endm

;; *********************************
;; *** just call a basic command ***
;; *********************************
;
;defm basiccmd
;      lda #0
;      jsr /1
;      lda rtsadr+1             ;restore return addr. on stack (removed by basic cmd.)
;      pha
;      lda rtsadr
;      pha
;      endm

; ---------
; functions
; ---------

; ************
; *** main ***
; ************

         cld

         pla             ;save return address (basic cmds.remove this fr.stack)
         sta rtsadr      ;$fc = low byte of address
         pla
         sta rtsadr+1    ;$c6 = high byte of address
         pha
         lda rtsadr
         pha

         ;basiccmd new    ;shouldn't be necessary.

         jsr clrscr

         jsr out2high

         lda di
         ora #2
         sta di

         jsr togout

         jsr readbyte
         sta adptr
         sta loadadr
         jsr readbyte
         sta adptr+1
         sta loadadr+1

         ;lda adptr+1
         jsr printby
         lda adptr
         jsr printby

         lda #chr_spc
         jsr wrt

         jsr readbyte
         sta le
         jsr readbyte
         sta le+1

         ;lda le+1
         jsr printby
         lda le
         jsr printby
         jsr crlf

         lda adptr     ;return,if dest.addr.=$ffff
         cmp #$ff
         bne keywait
         lda adptr+1
         cmp #$ff
         beq break

keywait  jsr get
         beq keywait
         cmp #chr_stop
         bne cursave
break    jsr out2high  ;return with output set to high
         rts

cursave  lda cursor
         sta crsrbuf
         lda cursor+1
         sta crsrbuf+1
         lda cursor+2
         sta crsrbuf+2
nextpl   jsr get
         beq contpl
         cmp #chr_stop
         beq break
contpl   lda crsrbuf
         sta cursor
         lda crsrbuf+1
         sta cursor+1
         lda crsrbuf+2
         sta cursor+2
         lda adptr+1
         jsr printby
         lda adptr
         jsr printby
         lda #chr_spc
         jsr wrt
         lda le+1
         jsr printby
         lda le
         jsr printby
         jsr readbyte
         ldy #0
         sta (adptr),y
         inc adptr
         bne decle
         inc adptr+1
decle    dec le
         lda le
         cmp #$ff
         bne nextpl
         dec le+1
         lda le+1
         cmp #$ff
         bne nextpl
         jsr crlf

         jsr out2high

         lda loadadr    ;decide,if basic or asm prg loaded
         cmp #<defbasic ;(decision based on start address, only..)
         bne runasm
         lda loadadr+1
         cmp #>defbasic
         bne runasm
  
         lda adptr+1     ;set basic variables start pointer to behind loaded prg
         sta varstptr+1
         lda adptr
         sta varstptr
         ;basiccmd clr ;done by run called below

         jsr crlf

;         lda loadadr+1
;         jsr printby
;         lda loadadr
;         jsr printby
;         lda #chr_spc
;         jsr wrt
;         lda #>defbasic
;         jsr printby
;         lda #<defbasic
;         jsr printby

         ;basiccmx runl1ptr ;returns to basic
         ;
         lda #0
         jmp run
         
runasm   jmp (loadadr)

; *****************************************
; *** "toggle" output based on tapbufin ***
; *****************************************

togout   lda tapbufin  ;"toggle" depending on tapbufin
         beq toghigh
         lda io        ;toggle output to low
         and #253
         jmp togdo
toghigh  lda io        ;toggle output to high
         ora #2
togdo    sta io        ;does not work in vice (v3.1)!
         lda #1
         sec
         sbc tapbufin
         sta tapbufin
         rts

; **************************
; *** set output to high ***
; **************************

out2high lda #0
         sta tapbufin
         jsr togout
         rts

; *************************************
; *** wait 1/60 secs.in constant de ***
; *************************************

waitde   sei           ;no update during read
         lda time      ;read low byte of time
         cli
         clc
         adc #de       ;calculate resume time
delay    cmp time      ;loop, untile resume
         bne delay     ;time is reached
         rts

; ***********************************
;*** read a byte into accumulator ***
; ***********************************

readbyte ldy #0        ;byte buffer during read
         ldx #1        ;to hold 2^exp
readloop jsr waitde    ;todo: decrease wait delay
         lda io
         and #1
         beq readnext  ;bit read is zero
         stx tapbufin+1       ;bit read is one, add to byte (buffer)
         tya           ;get current byte buffer content
         ora tapbufin+1       ;"add" current bit read
         tay           ;save into byte buffer
readnext txa           ;get next 2^exp
         asl
         tax
         jsr togout    ;acknowledge
         cpx #0        ; last bit read?
         bne readloop
         tya           ;get byte read into accumulator
         rts

; *********************************************************
; *** print "hexadigit" (hex.0-f) stored in accumulator ***
; *********************************************************

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

; ******************************************************
; *** print byte in accumulator as hexadecimal value ***
; ******************************************************

printby  ldx #4
         tay
prbloop  lsr a
         dex
         bne prbloop
         jsr printhd
         tya
         jsr printhd
         rts

;; **********************************
;; *** debug: print stack pointer ***
;; **********************************
;
;printsp  tsx
;         txa
;         clc         ;ignore change caused by calling
;         adc #2      ;this sub routine.
;         jsr printby
;         rts

; ---------
; variables
; ---------

le       byte 0, 0 ;count of payload bytes
crsrbuf  byte 0, 0, 0
loadadr  byte 0, 0 ;hold start address of loaded prg
rtsadr   byte 0, 0 ;hold return address found on stack at start of execution

; ----
; data
; ----

; (e.g. add strings, here)
