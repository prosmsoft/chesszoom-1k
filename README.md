# Chesszoom 1K
Written by John Connolly (PROSM)

Finished 2023-08-20

## Running the demo

Your emulator must be capable of emulating WRX hi-res graphics - make sure you have it turned on before loading this demo.

This program should work on all un-expanded 50Hz ZX81s, and with RAM packs capable of true hi-res. On 60Hz machines, there is slowdown and screen flickering, so it is not recommended that you run this program.

## Assembling the source

The source was assembled with Pasmo 0.5.3, but other assemblers should work as well. You can assemble it by running:

`pasmo main.asm main.p`

This produces a ZX81 .P format tape file.

## Development

I had the idea for this demo back in June, realising that it would be a good fit for the ZX81's hardware, given that only a few unique lines would have to be rendered, which could then be repeated down the screen to create the desired display. I wrote a preliminary test in C with the SDL library later that month, and after some time on the back burner, I started writing the ZX81 version in August.

My original idea was to have two layers of the board: a background board with a dithering pattern applied and a foreground board of solid black to accentuate the 3D effect of bouncing in and out from the board. Unfortunately, I realised after getting one of the boards up that CPU time was a scarcer resource than I had reckoned it would be. I changed tact and instead decided to just go with one board, but to vary the dithering pattern applied to it, so it would appear to get darker the closer the camera came to it.

After a bit of size optimisation here and there, I managed to fit the entire program into the 1K RAM, with 2 spare bytes in the system variable area. Obviously, I only freed up as much space as I needed to fit in everything I wanted, so I'm sure you could still shrink it down a bit more here and there. The primary target would probably be the display driver - this was a bit of a rush-job as I had to completely rewrite the core of it when I made the switch from two layers to one layer. You might try replacing the RLC C instructions with RLC (HL), to allow for the removal of some of the delay instructions; I was going to do that if things got desperate, but I found optimisations elsewhere that removed the need for it. You could also try rolling it up rather than having it unrolled to 8 iterations, but I had trouble trying to fit the pointer increment in - again, it can almost certainly be done, but I got tired and called it a day. Maybe I'll fix it another time.

I've tested this demo on a real un-expanded ZX81, and EightyOne V1.39 (which has a life-saving annotation tool that lets me see how much time my code takes as a proportion of the video frame).

## Thanks

Thanks must go to the following people:

- **Dr BEEP**, whose 1K games inspired me to try out programming on the ZX81.
- **Adam Klotblixt (NollKollTroll)**, whose source code for VBARS8 I consulted when writing my display driver code.
- **Wilf Rigter**, whose technical writings helped me understand the finer details of ZX81 hi-res graphics.
- **Paul Farrow**, for his comprehensive Sinclair website and his own hi-res programs.
- **Everyone at Sinclair ZX World** and the **Spectrum Computing forums**, for keeping the memory of these old machines alive by fostering a lively and welcoming community.
