
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

crlf     = $c9e2          ;$c9d2 <- basic 1.0 / rom v2 value
wrt      = $ffd2
;strout   = $ca1c       ;$ca27
get      = $ffe4
clrscr   = $e229          ;$e236

; --------------
; basic commands
; --------------

run      = $c785          ;$c775 ;basic run
;new      = $c55b       ;$c551 ;basic new
;clr      = $c577       ;$c770 ;basic clr

; ---------------
; system pointers
; ---------------

varstptr = 42          ;124 ;pointer to start of basic variables
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

tapbufin = $bb          ;$271 ;tape buffer #1 and #2 indices to next char (2 bytes)
cursor   = $c4          ;$e0
;time     = 143         ;514 ;low byte of time
counter  = $e849          ;read timer 2 counter high byte
di       = 59459          ;data direction reg.
io       = 59471          ;i/o port
defbasic = $401          ;default start addr.of basic prg

adptr    = 15          ;6 ;unused terminal & src. width
;de       = 8        ;bit read delay (see function for details)

; ---------
; functions
; ---------

; ************
; *** main ***
; ************

         ;cld

         ;jsr clrscr

; needed,if you want to use basiccmd macro:
;
;         pla           ;save return address (basic cmds.remove this fr.stack)
;         sta rtsadr    ;$fc = low byte of address
;         pla
;         sta rtsadr+1  ;$c6 = high byte of address
;         pha
;         lda rtsadr
;         pha

         lda #0        ;make sure that initial write ready signal
         sta wrmo+1    ;to expect is set to zero.

         jsr out2high  ;make sure that line 2 will be high, when set as output

         lda #2        ;setup i/o line 2 as output, 1 and 3 must be inputs
         sta di

         jsr togout    ;set line 2 to low

         jsr readbyte  ;read start address
         sta adptr     ;store for transfer
         sta loadadr   ;store for later autostart
         jsr readbyte
         sta adptr+1
         sta loadadr+1

         ;lda adptr+1    ;print start address
         jsr printby
         lda adptr
         jsr printby

         lda #chr_spc
         jsr wrt

         jsr readbyte  ;read payload byte count
         sta le
         jsr readbyte
         sta le+1

         ;lda le+1       ;print payload byte count
         jsr printby
         lda le
         jsr printby
         jsr crlf

keywait  jsr get       ;wait for user key press
         beq keywait
         cmp #chr_stop
         bne cursave   ;exit,if run/stop was pressed
break    jsr out2high  ;return with output set to high
         rts

cursave  lda cursor    ;remember cursor position for progress updates
         sta crsrbuf
         lda cursor+1
         sta crsrbuf+1
         lda cursor+2
         sta crsrbuf+2

nextpl   lda crsrbuf   ;reset cursor position for progress update on screen
         sta cursor
         lda crsrbuf+1
         sta cursor+1
         lda crsrbuf+2
         sta cursor+2

         lda adptr+1   ;print current byte address
         jsr printby
         lda adptr
         jsr printby

         lda #chr_spc
         jsr wrt

         lda le+1      ;print current count of bytes left
         jsr printby
         lda le
         jsr printby

         jsr readbyte  ;read byte
         ldy #0        ;store byte at current address
         sta (adptr),y

;         lda #chr_spc
;         jsr wrt
;         ;ldy #0
;         lda (adptr),y ;print byte read
;         jsr printby

         inc adptr
         bne decle
         inc adptr+1

decle    lda le
         cmp #1
         bne dodecle
         lda le+1      ;low byte is 1
         beq readdone  ;read done,if high byte is 0
dodecle  dec le        ;read is not done
         lda le
         cmp #$ff
         bne nextpl
         dec le+1      ;decrement high byte,too
         jmp nextpl

readdone jsr crlf

         jsr out2high

         lda loadadr   ;decide,if basic or asm prg loaded
         cmp #<defbasic;(decision based on start address, only..)
         bne runasm
         lda loadadr+1
         cmp #>defbasic
         bne runasm

         lda adptr+1   ;set basic variables start pointer to behind loaded prg
         sta varstptr+1
         lda adptr
         sta varstptr

         jsr crlf

         lda #0        ;this actually
         jmp run       ;is ok (checked stack pointer values)

runasm   jmp (loadadr)

; *****************************************
; *** "toggle" output based on tapbufin ***
; *****************************************

togout   lda tapbufin  ;"toggle" depending on tapbufin
         beq toghigh
         dec tapbufin  ;toggle output to low
         lda io        
         and #253
         jmp togdo
toghigh  inc tapbufin  ;toggle output to high
         lda io        
         ora #2
togdo    sta io        ;does not work in vice (v3.1)!
         rts

; **************************
; *** set output to high ***
; **************************

out2high lda #0
         sta tapbufin
         jsr togout
         rts

;; *************************************
;; *** wait 1/60 secs.in constant de ***
;; *************************************
;
;waitde   sei           ;no update during read
;         lda time      ;read low byte of time
;         cli
;         clc
;         adc #de       ;calculate resume time
;delay    cmp time      ;loop, untile resume
;         bne delay     ;time is reached
;         rts

;; *******************************************************
;; *** wait constant de multiplied by 256 microseconds ***
;; *******************************************************

;waitde   lda #de
;         sta counter
;delay    cmp counter
;         bcs delay     ;branch, if de is equal or greater than counter
;         rts

; ************************************
; *** read a byte into accumulator ***
; ***                              ***
; *** must be used by main, only!  ***
; ************************************

readbyte ldy #0        ;byte buffer during read
         ldx #1        ;to hold 2^exp
readloop jsr get       ;let user be able to break execution with run/stop key
         beq readcont
         cmp #chr_stop
         bne readcont  ;exit,if run/stop was pressed

         pla           ;hard-coded break -
         pla           ;function usable by main only,
         jmp break     ;because of this..

readcont lda io        ;wait for write ready signal
         and #4        ;write ready line
         lsr a
         lsr a
wrmo     cmp #0        ;this value will be toggled between 0 and 1 in-place.
         bne readloop

         eor #1        ;toggle next write ready val.to expect
         sta wrmo+1
         lda io
         and #1        ;data line
         beq readnext  ;bit read is zero
         stx tapbufin+1;bit read is one, add to byte (buffer)
         tya           ;get current byte buffer content
         ora tapbufin+1;"add" current bit read
         tay           ;save into byte buffer
readnext txa           ;get next 2^exp
         asl
         tax
         jsr togout    ;acknowledge
         cpx #0        ;last bit read?
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
printd   ;clc           ;less than $0a - 0 to 9
         adc #chr_0
print    jsr wrt
         rts

; ******************************************************
; *** print byte in accumulator as hexadecimal value ***
; ******************************************************

printby  pha
prbloop  lsr a
         lsr a
         lsr a
         lsr a
         jsr printhd
         pla
         jsr printhd
         rts

; ---------
; variables
; ---------

le       byte 0, 0 ;count of payload bytes
crsrbuf  byte 0, 0, 0
loadadr  byte 0, 0 ;hold start address of loaded prg

; needed,if you want to use basiccmd macro:
;
;rtsadr   byte 0, 0 ;hold return address found on stack at start of execution

; ----
; data
; ----

; (e.g. add strings, here)

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
;      lda rtsadr+1      ;restore return addr. on stack (removed by basic cmd.)
;      pha
;      lda rtsadr
;      pha
;      endm
