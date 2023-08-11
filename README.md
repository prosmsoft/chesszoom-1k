# 1K Chessboard zoomer

Planning started on 5th June 2023  
Programming started on 6th June 2023

## The general idea

Two layer chessboard zoomer effect  
Number of lines needed for effect:
- Two layers, two states each = 4 combinations
- Two line dithering pattern on back layer = 2 combinations  
Overall, 8 lines needed for our effect = 256 bytes

Only about 10,000 T-states for everything each frame

Strategy - draw the dithered lines first, then do the solid lines on top. Therefore, only need OR at the edges of the solid lines - main loop can be LD.

Can save memory by ORing edges of all lines

Which arrangement to take for the line buffer? My general idea is this:

DFBxxxxx

where
- **D** is the dithering pattern
- **B** is the background checkerboard
- **F** is the foreground checkerboard

Therefore the 

## The four parts

The four parts required to complete this program are:
- The position calculation
- The line drawing section
- The vertical processing section
- The display driver

## Position calculation

## Line drawing section

## Vertical processing section

## Display driver

Looks like 170 T-states from hi-res routine start to 1st display byte

207 T-states per scanline, 128 T-states for display

79 T-states for non-display code each line (need LD R,A so only 70 T-states for logic and control flow)

LD R,A should happen AFTER the jump into VRAM, therefore five LSBs can be 0.

Depending on the arrangement of the vertical data, we could do something like:

- XOR A (4)
- shift vertical data into accumulator (24)
- rotate dither pattern into accumulator (8)
- 

