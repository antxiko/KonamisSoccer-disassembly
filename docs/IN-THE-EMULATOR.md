# In the emulator

The emulator here is not for taking captures: it is for **checking that what we
say is true**. The pictures on this site are drawn by Python running the
cartridge's own steps, and the emulator is what says whether those steps are
read right.

## Starting it

    openmsx -machine Philips_VG_8020 -cart soccer.rom

It is a 32 KB cartridge with an "AB" header and a single entry point, so it
starts on any MSX1 with 8 KB of RAM.

## Dumping the VRAM

    make vram

That does three things:

1. launches openMSX with `tools/omsx_vram.tcl`, which sets **not one
   breakpoint**: the dumps are scheduled on emulated time, which is the only
   thing that does not choke the emulator;
2. at seven moments dumps the 16 KB of VRAM, the eight VDP registers, the 4 KB
   of working RAM and a screenshot;
3. compares the dumps against what `tools/graficos.py` builds, byte for byte,
   with `tools/coteja_vram.py`.

The script has a 240-second watchdog on **real** time: a broken script cannot
leave the emulator hanging.

## What the comparison says

    titulo   COLOUR 0    PATTERNS 0    NAMES 0
    campo    COLOUR 0    PATTERNS 0    SPR PATT 0
             MAP at 0xE600, 80x23:   2 of 1840
             WINDOW of 23x32:       44 of 736, and 42 are player patches

The title screen comes out **identical across all three tables**. On the pitch,
the three graphics tables too, and the differences that remain are explained:

- the **two** map tiles are the two goalkeepers, which do not come in the
  compressed block: they are stamped when the play starts;
- of the 44 in the window, 42 are the 3x3 patches of the players who happened
  to be on screen at that moment, and the other two are those same
  goalkeepers.

The comparison deliberately leaves out the sprite attribute table —it changes
every frame— and tiles `0x5C` to `0x63`, which the match rewrites as it runs to
stamp the patches. That the pitch map uses none of them —its tiles run from
`0x01` to `0x58`— is what makes it possible to draw the whole pitch without
playing the game, and there is a test watching it.

## The eight registers, checked

The table at `0x4889` says `02 E2 0E 7F 07 76 03 E4`, and the emulator returns
exactly that on the start-up screen. During the match only R7 changes, to
`0x00`: the pitch's backdrop is black.

## Looking at the RAM

The dump includes the 4 KB from `0xE000` to `0xEFFF`, and the whole state of the
match can be read there: the two kit palettes at `0xE051` and `0xE056`, the
twelve pieces from `0xE100`, the pitch map at `0xE600`, and the four strides
per frame at `0xE06A`-`0xE071`. At level 1 they come out as `0x0100` and
`0x0150` for the human's side and `0x00E0` and `0x0130` for the machine's,
which is what the table at `0x57EF` says.

## One caveat

`tools/omsx_vram.tcl` crosses the menu by pressing the space bar at fixed
times. If Konami changed its mind, or if a slower machine is used, the dumps
can land on a different scene: each `info_NN.txt` carries the scene and the
sub-state written down, so it shows up straight away.
