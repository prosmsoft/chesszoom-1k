; CHESSZOOM 1K, for the 1K ZX81
; File derived from Dr. Beep's optimal lowres ZX81 machine code template

; N.B. Lines marked (SMC) are self-modifying code

; Gamecoding course ZX81 machinecode
; Base model for optimal ZX81 code in lowres 
; 12 bytes from #4000 to #400B free reuseble for own "variables"

    org #4009

; in LOWRES more sysvar are used, but in this way the shortest code
; over sysvar to start machinecode. This saves 11 bytes of BASIC

copyByteSize: equ 30                    ; Must be AT LEAST 30 bytes (for row drawing routines)

wrxGfx:         equ $4300               ; 256-byte store for graphics (8 rows, 32 byte each)
rowTab:         equ $4248               ; 184-byte store for row indices
stackPtr:       equ $4025               ; 29-byte stack
edgeTab:        equ $4000               ; 8-byte edge table
textureByte:    equ $4008
textureByteOff: equ $08

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

        jp initDemo                     ; YOUR ACTUAL GAMECODE, can be everywhere
        db 0,0

cdflag  db 64
; DO NOT CHANGE SYSVAR ABOVE!

; free codeable memory
demoLoop:
;       ld hl,wrxGfx
;       rrc (hl)
;       ld de,wrxGfx + 1
;       ld bc,$007f
;       ldir
        
;       inc hl
;       inc de
;       rlc (hl)
;       ld bc,$007f
;       ldir

        ld a,(xPos)
        inc a
        and $0f
        ld (xPos),a
        ld h,a

        ld a,$aa
        ld (renderLineTextureSwap + 1),a
        ld (renderLineTextureLoad + 1),a
        ld a,$00
        ld l,0
        ld de,$2300
        call renderLine

        ld a,(xPos)
        ld h,a

        ld a,$aa
        ld (renderLineTextureSwap + 1),a
        ld (renderLineTextureLoad + 1),a
        ld a,$20
        ld l,$00
        ld de,$2300
        call renderLine

        ld a,(xPos)
        ld h,a

        ld a,$55
        ld (renderLineTextureSwap + 1),a
        ld (renderLineTextureLoad + 1),a
        ld a,$80
        ld l,$00
        ld de,$2300
        call renderLine

        ld a,(xPos)
        ld h,a

        ld a,$55
        ld (renderLineTextureSwap + 1),a
        ld (renderLineTextureLoad + 1),a
        ld a,$80
        ld l,$00
        ld de,$2300
        call renderLine

        ld a,(xPos)
        ld h,a

        ld a,$55
        ld (renderLineTextureSwap + 1),a
        ld (renderLineTextureLoad + 1),a
        ld a,$80
        ld l,$00
        ld de,$2300
        call renderLine

textScroll:
        ld hl,displayRoutine + 3
        ld de,displayRoutine + 2
        ld bc,31
        ldir

waitFrame:
        ld a,wrxDriver % 256            ; Address of driver for central display

        cp ixl
        jr nz,$-2                       ; Loop if we are at bottom part of display
        cp ixl
        jr z,$-2                        ; Loop if we are at top part of display

        jp demoLoop                     ; Just hit bottom of display - loop back

xPos:
        db 0



renderLine:
; NOTE - PUT START HERE
        ; Map set initialisation
        ld b,$40

        exx
        ; Line set initialisation
        ld de,$02ff                     ; D holds initial left edge + 2,
                                        ; E holds initial mask
        ld h,$43
        ld l,a

        ld (hl),0
        exx
renderLineLoop:
        ld a,h
        and 7
        ld c,a                          ; Form address to edge table
        ld a,h                          ; Copy right edge integer part

        exx                             ; LINE SET =============================
        
        ld c,a                          ; Make temp. copy of X
        rrca
        rrca
        rrca
        and 31                          ; Get byte-wise position

        ld b,a
        inc b                           ; This will set the carry flag for lines
        inc b                           ; with no run of bytes in the middle

        sub d
        ld d,b

renderLineTextureLoad:
        ld b,$00                        ; Load texture byte (SMC)
        jr c,renderLineEdge             ; Jump ahead for edge handling

        add a,a                         ; Double run length
        cpl
        add a,(copyByteSize * 2) - 1    ; Equivalent to subtracting from copyByteSize * 2
        ld (copyBytesJump + 1),a        ; Store offset

        ld a,e
        and b
        or (hl)
        ld (hl),a
        inc l

copyBytesJump:
        jr $                            ; Jump into appropriate part (SMC)
rept 30
        ld (hl),b
        inc l
endm

        exx                             ; MAP SET ==============================
        ld a,(bc)
        exx                             ; LINE SET =============================
        ld e,a
        cpl
        and b
        ld (hl),a

renderLineEndRun:
; Texture swap here! XOR against old byte?
        ld a,b
renderLineTextureSwap:
        xor $00                         ; (SMC)
        ld (renderLineTextureLoad + 1),a

        exx                             ; MAP SET ==============================

        ld a,255
        cp h                            ; End of line?
        ret z                           ; Return if so

        add hl,de
        jp nc,renderLineLoop
        
        ld h,a
        jr renderLineLoop

renderLineEdge:
; This branch handles lines made up of only two edges (9 - 16px)
        inc a                           ; Just a single edge?
        jr nz,renderLineEdgeSingle

; This is a double edge situation
        ld a,e                          ; Get old mask
        and b                           ; AND against texture byte
        or (hl)                         ; OR to the buffer
        ld (hl),a                       ; Store back in buffer

        inc l

renderLineEdgeLeft:
        exx                             ; MAP SET ==============================
        ld a,(bc)                       ; Get new mask
        exx                             ; LINE SET =============================

        ld e,a                          ; Store new mask
        cpl                             ; Invert mask
        and b                           ; AND against graphic
        ld (hl),a                       ; Load into buffer

        jr renderLineEndRun

renderLineEdgeSingle:
        inc c
        jr nz,renderLineEdgeLeft        ; Branch if edge on left hand side

renderLineEdgeCore:
; Possibility - hide this in BASIC system variables if memory gets tight?
        ld a,e                          ; Get old mask
        and b                           ; AND against texture byte
        or (hl)                         ; OR to the buffer
        ld (hl),a                       ; Store back in buffer
        
        ret                             ; We're at the end of the line



wrxDriver:
; Total time from display driver entry to first display byte must be
; 174 T-states.
; Code from label wrxLoop to first display byte takes 56 T-states
; Tasks to carry out during initialisation include:
;   - Disable interrupts
;   - Load appropriate registers
        di                              ; [ 4] WRX needs interrupts off
        ld a,wrxGfx / 256               ; [ 7] 
        ld i,a                          ; [ 9] Point to RAM for WRX display

        ld hl,displayRoutine + $22      ; [10] Address of exit from hi-res
        ld (hl),$c9                     ; [10] Patch in RET instruction

        ld de,rowTab                    ; [10] Load row table pointer

                                        ;  50  T-STATES so far

        ld b,4                          ; [ 7]
        djnz $                          ; [47]
        nop                             ; [ 4] --- DELAY ---

        ld bc,$b8aa                     ; [10] B holds number of rows (184)
                                        ;      C holds dither offset pattern

wrxLoop:
        rlc c                           ; [ 8] Get dither bit in carry
        ld a,(de)                       ; [ 7] Get row index from table
        rra                             ; [ 4] Stick dither bit in MSB
        inc de                          ; [ 6] Move pointer to next index
        ret c                           ; [ 5] --- DELAY ---

        call displayRoutine + $8000     ; [17] Call the WRX display routine

                                        ; 147  T-STATES spent in displayRoutine

        djnz wrxLoop                    ; [13] Loop if there are rows left

wrxText:
; Total time from last hi-res display byte to Sinclair ROM driver call must be
; 155 T-states
; Time spent before this label = 18 T-states

        ld (hl),$76                     ; [10] Set up correct exit from lo-res

        ld b,5                          ; [ 7]
        djnz $                          ; [60] --- DELAY ---

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
        ld r,a                          ; [ 9] Load R with low byte of graphics pointer

        ; ZX81 character encoding of '"CHESSZOOM 1K", ZX81, PROSM 2023'
        db $0b, $28, $2d, $2a, $38, $38, $3f, $34, $34, $32, $00, $1d, $30, $0b, $1a, $00
        db $3f, $3d, $24, $1d, $1a, $00, $35, $37, $34, $38, $32, $00, $1e, $1c, $1e, $1f

        ret                             ; Exit from displayRoutine (SMC)



IF ($ > rowTab)
    .ERROR "Code not allowed to exceed rowTab"
ENDIF

org rowTab
        db $f0



org wrxGfx

initDemo:
; Since this code is only run once, I've kept it in the graphics buffer, since
; it can be destroyed without consequence following execution
        out ($fd),a                     ; Turn off NMI generator
        out ($fd),a                     ; In case NMI triggered during last instruction
        ld sp,stackPtr                  ; Build stack downwards from row table
        ld ix,wrxDriver                 ; Set up pointer to our hi-res driver

        ld hl,rowTab
        ld de,rowTab + 1
        ld bc,184 - 1
        ld (hl),$00
        ldir                            ; Clear the row table

        ld hl,edgeTabTop
        ld de,edgeTab
        ld c,8
        ldir                            ; Copy the edge table to its lower location

        out ($fe),a                     ; Turn on NMI generator
        ld hl,$4300
        ld (hl),$80
        ld l,$80
        ld (hl),$80

        jp demoLoop

edgeTabTop:
        db $7f, $3f, $1f, $0f, $07, $03, $01, $00

; the display file, Code the lines needed.
dfile:  
        halt
; this byte fills the unused part of the screen
        jp (hl)
    
vars    db 128
last    equ $       

