; CHESSZOOM 1K, for the 1K ZX81
; File derived from Dr. Beep's optimal lowres ZX81 machine code template

; Gamecoding course ZX81 machinecode
; Base model for optimal ZX81 code in lowres 
; 12 bytes from #4000 to #400B free reuseble for own "variables"

    org #4009

; in LOWRES more sysvar are used, but in this way the shortest code
; over sysvar to start machinecode. This saves 11 bytes of BASIC

; DO NOT CHANGE AFTER BASIC+3 (=DFILE)
basic   ld h,dfile/256                  ; highbyte of dfile
        jr init1

        db 236                          ; BASIC over DFILE data
        db 212,28            
        db 126,143,0,18

eline:  dw last
chadd:  dw last-1
        db 0,0,0,0,0,0                  ; x
berg:   db 0                            ; x

mem:    db 0,0                          ; x OVERWRITTEN ON LOAD

init1:  ld l, dfile mod 256             ; low byte of dfile
        jr init2            

lastk   db 255,255,255
margin  db 55

nxtlin  dw basic                        ; BASIC-line over sysvar    

flagx   equ init2+2
init2   ld (basic+3),hl                 ; repair correct DFILE flagx will be set with 64, the correct value

        db 0,0,0                        ; x used by ZX81, not effective code after loading
        db 0,0,33                       ; skip frames with LD HL,NN

frames  dw 65535

        jp gamecode                     ; YOUR ACTUAL GAMECODE, can be everywhere
        db 0,0

cdflag  db 64
; DO NOT CHANGE SYSVAR ABOVE!

; free codeable memory
gamecode:
        ld ix,wrxDriver
gameloop:
        jr gameloop

wrxDriver:
; Total time from display driver entry to first display byte must be
; 174 T-states.
; Code from label wrxLoop to first display byte takes 56 T-states
; Tasks to carry out during initialisation include:
;   - Disable interrupts
;   - Load appropriate registers
        di                              ; [ 4] WRX needs interrupts off
        ld a,$40                        ; [ 7] 
        ld i,a                          ; [ 9] Point to RAM for WRX display

        ld a,$c9                        ; [ 7] Opcode for RET
        ld (displayRoutine + 34),a      ; [13] Set up correct exit from hi-res

        ld hl,rowTab                    ; [10] Load row table pointer

                                        ;  50  T-STATES so far

        ld b,4                          ; [ 7]
        djnz $                          ; [47]
        nop                             ; [ 4] --- DELAY ---

        ld bc,$b8aa                     ; [10] B holds number of rows (184)
                                        ;      C holds dither offset pattern

wrxLoop:
        rlc c                           ; [ 8] Get dither bit in carry
        ld a,(hl)                       ; [ 7] Get row index from table
        rra                             ; [ 4] Stick dither bit in MSB
        inc hl                          ; [ 6] Move pointer to next index
        ret c                           ; [ 5] --- DELAY ---

        call displayRoutine + $8000     ; [17] Call the WRX display routine

                                        ; 147  T-STATES spent in displayRoutine

        djnz wrxLoop                    ; [13] Loop if there are rows left

wrxText:
; Total time from last hi-res display byte to Sinclair ROM driver call must be
; 155 T-states
; Time spent before this label = 18 T-states

        ld a,$76                        ; [ 7] Opcode for HALT
        ld (displayRoutine + 34),a      ; [13] Set up correct exit from lo-res

        ld b,3                          ; [ 7]
        djnz $                          ; [34]
        nop                             ; [ 4]
        nop                             ; [ 4]
        nop                             ; [ 4]
        nop                             ; [ 4]

; Total for following set-up section = 60
        ld bc,$0108                     ; [10] 1 row, 8 lines
        ld hl,displayRoutine + $8002    ; [10] Point to our text line
        ld a,$1e                        ; [ 7] 
        ld i,a                          ; [ 9] Point to our ROM character set
        ld a,$f5                        ; [ 7] SLOW mode timing value for R
        call $2b5                       ; [17] Generate the text with the ROM display driver
        call $292                       ; [17] Exit the display driver

; V-sync
        call $220                       ; [17] V-sync routine
        ld ix,wrxDriver                 ; [14] Load the hi-res vector
        jp $2a4                         ; [10] Exit the display driver

displayRoutine:
        ld r,a

        db $0b, $28, $2d, $2a, $38, $38, $3f, $34, $34, $32, $00, $1d, $30, $0b, $1a, $00
        db $3f, $3d, $24, $1d, $1a, $00, $35, $37, $34, $38, $32, $00, $1e, $1c, $1e, $1f

        ret

rowTab:
        ds 184


; the display file, Code the lines needed.
dfile:   
; this byte fills the unused part of the screen
        jp (hl)
    
vars    db 128
last    equ $       

