; CHESSZOOM 1K, for the 1K ZX81
; File derived from Dr. Beep's optimal lowres ZX81 machine code template

; N.B. Lines marked (SMC) are self-modifying code

; Gamecoding course ZX81 machinecode
; Base model for optimal ZX81 code in lowres 
; 12 bytes from #4000 to #400B free reuseble for own "variables"

    org #4009

; in LOWRES more sysvar are used, but in this way the shortest code
; over sysvar to start machinecode. This saves 11 bytes of BASIC

; Spare bytes: -- -- -- -- -- -- -- -- -- -- --
;              -- 37 38 39 3A

copyByteSize: equ 30                    ; Must be AT LEAST 30 bytes (for row drawing routines)

wrxGfx:         equ $4380               ; 128 byte store for graphics (8 rows, 32 byte each)
rowTab:         equ $4360               ; 32 byte store for row indices
stackPtr:       equ $4025               ; 28 byte stack
edgeTab:        equ $4000               ; 8 byte edge table
frameCount:     equ $4008               ; 1 byte - used to time text scroller
xCheck:         equ $4029               ; 1 byte
yCheck:         equ $4036               ; 1 byte
xPos:           equ $402a               ; 2 bytes
yPos:           equ $402c               ; 2 bytes
xCoord:         equ $402e               ; 2 bytes
yCoord:         equ $4030               ; 2 bytes
lineWidth:      equ $4032               ; 2 bytes

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

textOffset:
        db $7f                          ; Address into string

waitFrame:
        ld a,wrxDriver % 256            ; Address of driver for central display

        cp ixl
        jr nz,$-2                       ; Loop if we are at bottom part of display
        cp ixl
        jr z,$-2                        ; Loop if we are at top part of display

demoLoop:
        ld a,(xCoord + 1)
        add a,1
        ld (xCoord + 1),a

        ld a,(yCoord + 1)
        add a,1
        ld (yCoord + 1),a

        ld bc,0-256
        ld hl,(lineWidth)
        add hl,bc
        ld a,$24
        cp h
        jr c,$+4
        ld h,$ff
        ld h,$25
        ld (lineWidth),hl

; X coord
        ld a,(xCoord + 1)
        ld b,$40
        call lineOffsetCalc
        ld (xPos),hl
        ld (xCheck),a

; Y coord
        ld a,(yCoord + 1)
        ld b,$2e
        call lineOffsetCalc
        ld (yPos),hl
        ld (yCheck),a

endOfCase:
; Rendering
        ld bc,$aa80
        ld a,b
        ld hl,(xPos)
        ld de,(lineWidth)
        call renderLine

        ld bc,$aac0
        xor a
        ld hl,(xPos)
        call renderLine

        ld bc,$55a0
        ld a,b
        ld hl,(xPos)
        call renderLine

        ld bc,$55e0
        xor a
        ld hl,(xPos)
        call renderLine

        ld a,(xCoord + 1)
        xor (iy + (xCheck - $4000))
        xor (iy + (yCoord + 1 - $4000))
        xor (iy + (yCheck - $4000))

        rlca
        sbc a,a
        ld bc,$ff60
        ld hl,(yPos)
        call renderLine

textScroll:
        ld a,(frameCount)
        inc a
        ld (frameCount),a

        and $e0
        jr nz,textScrollEnd

textScrollDo:
        ld a,(textOffset)
        inc a
        and $7f
        ld (textOffset),a
        add a,textData % 256
        ld l,a
        adc a,textData / 256
        sub l
        ld h,a

        push hl                         ; Save off text pointer for later

        ld hl,displayRoutine + 3
        ld de,displayRoutine + 2
        ld a,(de)                       ; Get character to be scrolled-out
        ld bc,31
        ldir                            ; Scroll text left

        pop hl
        ld b,(hl)
        ld (hl),a                       ; Swap old text into buffer

        ld a,b
        ld (de),a

textScrollEnd:
        jp waitFrame                     ; Just hit bottom of display - loop back



lineOffsetCalc:
        ld hl,(lineWidth)
        push bc
        and $7f
        ld e,a
        call multiplyH_E
        pop bc
        ld c,$00
        add hl,bc

        ld de,(lineWidth)
        srl d
        rr e
        xor a
getEdgePos:
        inc a
        sbc hl,de
        jp nc,getEdgePos
        add hl,de
        add hl,hl
        rrca
        ccf
        sbc a,a
        ret



multiplyH_E:
        ld d,0                          ; Combining the overhead and
        sla h                           ; optimised first iteration
        sbc a,a
        and e
        ld l,a

        ld b,7
multiplyH_Eloop:
        add hl,hl          
        jr nc,$+3
        add hl,de
   
        djnz multiplyH_Eloop
   
        ret



renderLine:
; NOTE - PUT START HERE
        ld (renderLineTextureLoad + 1),a
        ld a,b
        ld (renderLineTextureSwap + 1),a

        ; Map set initialisation
        ld b,$40
        ld a,c

        exx
        ; Line set initialisation
        ld de,$02ff
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

        exx
        ret                             ; We're at the end of the line



wrxDriver:
; Total time from display driver entry to first display byte must be
; 174 T-states.
; Code from label wrxLoop to first display byte takes 56 T-states
; Tasks to carry out during initialisation include:
;   - Disable interrupts
;   - Load appropriate registers
; TODO: Consider moving LD HL to top, then LD A,nn to LD A,H
        di                              ; [ 4] WRX needs interrupts off
        ld a,wrxGfx / 256               ; [ 7] 
        ld i,a                          ; [ 9] Point to RAM for WRX display

        ld a,$c9                        ; [ 7]
        ld (displayRoutine + $22),a     ; [13] Patch in RET instruction

        ld hl,rowTab - 1                ; [10] Load row table pointer
        inc hl                          ; [ 6] --- DELAY ---

                                        ;  50  T-STATES so far

        ld b,$03                        ; [ 7]
        djnz $                          ; [34]
        nop                             ; [ 4] --- DELAY ---

        ld b,$17                        ; [ 7] 23 rows of 8 pixels
        ld de,$8202                     ; [10] TODO: COMMENT THIS

wrxLoop:
        ld c,(hl)                       ; [ 7] Get first display byte
        ld a,$02                        ; [ 7] A holds d0000010
        rlc c                           ; [ 8] Get next bit off line
        rra                             ; [ 4] A holds fd000001
        rrca                            ; [ 4] A holds 1fd00000
                                        ;  30  T-STATES since loop label

        call displayRoutine + $8000     ; [17] Call the WRX display routine
                                        ; 147  T-STATES spent in displayRoutine

        dec (hl)                        ; [11]
        inc hl                          ; [ 6]
        dec hl                          ; [ 6] --- DELAY ---

        ld a,d                          ; [ 4] A holds d0000010
        rlc c                           ; [ 8] Get next bit off line
        rra                             ; [ 4] A holds fd000001
        rrca                            ; [ 4] A holds 1fd00000

        call displayRoutine + $8000     ; [17] Call the WRX display routine
                                        ; 147  T-STATES spent in displayRoutine

        inc (hl)                        ; [11]
        inc hl                          ; [ 6]
        dec hl                          ; [ 6] --- DELAY ---

        ld a,e                          ; [ 4] A holds d0000010
        rlc c                           ; [ 8] Get next bit off line
        rra                             ; [ 4] A holds fd000001
        rrca                            ; [ 4] A holds 1fd00000

        call displayRoutine + $8000     ; [17] Call the WRX display routine
                                        ; 147  T-STATES spent in displayRoutine

        dec (hl)                        ; [11]
        inc hl                          ; [ 6]
        dec hl                          ; [ 6] --- DELAY ---

        ld a,d                          ; [ 4] A holds d0000010
        rlc c                           ; [ 8] Get next bit off line
        rra                             ; [ 4] A holds fd000001
        rrca                            ; [ 4] A holds 1fd00000

        call displayRoutine + $8000     ; [17] Call the WRX display routine
                                        ; 147  T-STATES spent in displayRoutine

        inc (hl)                        ; [11]
        inc hl                          ; [ 6]
        dec hl                          ; [ 6] --- DELAY ---

        ld a,e                          ; [ 4] A holds d0000010
        rlc c                           ; [ 8] Get next bit off line
        rra                             ; [ 4] A holds fd000001
        rrca                            ; [ 4] A holds 1fd00000

        call displayRoutine + $8000     ; [17] Call the WRX display routine
                                        ; 147  T-STATES spent in displayRoutine

        dec (hl)                        ; [11]
        inc hl                          ; [ 6]
        dec hl                          ; [ 6] --- DELAY ---

        ld a,d                          ; [ 4] A holds d0000010
        rlc c                           ; [ 8] Get next bit off line
        rra                             ; [ 4] A holds fd000001
        rrca                            ; [ 4] A holds 1fd00000

        call displayRoutine + $8000     ; [17] Call the WRX display routine
                                        ; 147  T-STATES spent in displayRoutine

        inc (hl)                        ; [11]
        inc hl                          ; [ 6]
        dec hl                          ; [ 6] --- DELAY ---

        ld a,e                          ; [ 4] A holds d0000010
        rlc c                           ; [ 8] Get next bit off line
        rra                             ; [ 4] A holds fd000001
        rrca                            ; [ 4] A holds 1fd00000

        call displayRoutine + $8000     ; [17] Call the WRX display routine
                                        ; 147  T-STATES spent in displayRoutine

        ld a,(iy + 0)                   ; [19] --- DELAY ---

        inc l                           ; [ 4] Move to next byte of line
        ld a,d                          ; [ 4] A holds d0000010
        rlc c                           ; [ 8] Get next bit off line
        rra                             ; [ 4] A holds fd000001
        rrca                            ; [ 4] A holds 1fd00000

        call displayRoutine + $8000     ; [17] Call the WRX display routine
                                        ; 147  T-STATES spent in displayRoutine

        djnz wrxLoop                    ; [13] Loop if there are rows left

wrxText:
; Total time from last hi-res display byte to Sinclair ROM driver call must be
; 155 T-states
; Time spent before this label = 18 T-states

        ld a,$76                        ; [ 7] 
        ld (displayRoutine + $22),a     ; [13] Patch in HALT instruction

        ld b,3                          ; [ 7]
        djnz $                          ; [21]
        dec hl                          ; [ 6] --- DELAY ---
        inc hl
        nop

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

textData:
        ; ZX81 character encoding of ' HELLO TO DR BEEP, PAUL FARROW, '
        db $00, $2d, $2a, $31, $31, $34, $00, $39, $34, $00, $29, $37, $00, $27, $2a, $2a
        db $35, $1a, $00, $35, $26, $3a, $31, $00, $2b, $26, $37, $37, $34, $3c, $1a, $00

        ; ZX81 character encoding of '  NOLLKOLLTROLL,  WILF RIGTER,  '
        db $00, $00, $33, $34, $31, $31, $30, $34, $31, $31, $39, $37, $34, $31, $31, $1a
        db $00, $00, $3c, $2e, $31, $2b, $00, $37, $2e, $2c, $39, $2a, $37, $1a, $00, $00

        ; ZX81 character encoding of '  EVERYONE AT SINCLAIR ZX WORLD '
        db $00, $00, $2a, $3b, $2a, $37, $3e, $34, $33, $2a, $00, $26, $39, $00, $38, $2e
        db $33, $28, $31, $26, $2e, $37, $00, $3f, $3d, $00, $3c, $34, $37, $31, $29, $00

        ; ZX81 character encoding of '   ...AND SPECTRUM COMPUTING.   '
        db $00, $00, $00, $1b, $1b, $1b, $26, $33, $29, $00, $38, $35, $2a, $28, $39, $37
        db $3a, $32, $00, $28, $34, $32, $35, $3a, $39, $2e, $33, $2c, $1b, $00, $00, $00


IF ($ > rowTab)
    .ERROR "Code not allowed to exceed rowTab"
ENDIF

org rowTab

initDemo:
; Set up variables hidden in BASIC system area, clear out 
; Since this code is only run once, I've kept it in the graphics buffer, since
; it can be destroyed without consequence following execution
        out ($fd),a                     ; Turn off NMI generator
        out ($fd),a                     ; In case NMI triggered during last instruction
        ld sp,stackPtr                  ; Build stack downwards from row table
        ld ix,wrxDriver                 ; Set up pointer to our hi-res driver
        out ($fe),a                     ; Turn on NMI generator

        ld hl,edgeTabTop
        ld de,edgeTab
        ld bc,9
        ldir                            ; Copy the edge table to correct location

        ld hl,$5320
        ld (lineWidth),hl

        ld hl,$0000
        ld (xPos),hl
        ld (yPos),hl
        ld (xCoord),hl
        ld (yCoord),hl

        jp waitFrame

edgeTabTop:
        db $7f, $3f, $1f, $0f, $07, $03, $01, $00
frameStart:
        db $20

; the display file, Code the lines needed.
dfile:  
        halt
; this byte fills the unused part of the screen
        jp (hl)
    
vars    db 128
last    equ $       

