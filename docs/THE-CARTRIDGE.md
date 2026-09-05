# The cartridge

## The machine

An MSX1: Z80 at 3.58 MHz, **TMS9918** VDP, **AY-3-8910** sound generator, 16 KB
of VRAM and 8 KB of RAM. The cartridge brings 32 KB of ROM and carries neither
a mapper nor RAM of its own.

## The two pages

At 32 KB the cartridge takes **two pages** of the memory map, from `0x4000` to
`0xBFFF`. The working RAM starts at `0xE000`.

| range | what is there |
|---|---|
| `0x4000`-`0x4010` | the "AB" header and the entry point |
| `0x4010`-`0x4025` | a **second "AB" header** this cartridge never reads |
| `0x4025`-`0x4C19` | the skeleton: scenes, VDP, VRAM, sound, labels |
| `0x4C19`-`0x5645` | the presentation, the menu and the sound interpreter |
| `0x5645`-`0x651E` | setting up the match, the frame, the clock and the goal |
| `0x651E`-`0x6BD8` | the penalty shoot-out |
| `0x6BD8`-`0x6D18` | the logo scene |
| `0x6D18`-`0x853E` | the graphics and their loaders |
| `0x853E`-`0x8787` | the pitch map, compressed |
| `0x8787`-`0x9408` | the pieces, the ball physics and the aim |
| `0x9408`-`0xA219` | the pass, the shot, the goal lines and the restarts |
| `0xA219`-`0xB4C3` | the tactics and the intelligence |
| `0xB4C3`-`0xB9F9` | offside and the final screen |
| `0xB9F9`-`0xBFF3` | the trajectory and sprite tables |
| `0xBFF3`-`0xC000` | Konami's hidden mark |

## The header

The first four bytes say everything the BIOS needs:

    41 42 70 40    "AB", and INIT at 0x4070

The other three entries —STATEMENT, DEVICE and TEXT— are zero, and so are the
six reserved bytes. This is a single-entry-point cartridge.

`0x4070` hooks the interrupt at H.KEYI and settles into the `jr $` at `0x40BE`.
**The whole game hangs off the interrupt**: there is no main loop.

## The second header, the one this cartridge does not read

At `0x4010` there is another "AB", with the `0x07` of RC-7xx and the `0x32` of
RC-732 inside. Nothing here reads it. It is the header of the **Konami Game
Master**, the cheat cartridge that plugs into the other slot and looks there
for the addresses it may touch. Only four of Konami's cartridges carry it.

## The VRAM, the wrong way round

The eight VDP registers come from the table at `0x4889`, and they are

    02 E2 0E 7F 07 76 03 E4

| register | value | what it sets |
|---|---|---|
| R0 | 0x02 | SCREEN 2 |
| R1 | 0xE2 | 16K, screen on, interrupt, **16x16 sprites** |
| R2 | 0x0E | NAME table at `0x3800` |
| R3 | 0x7F | COLOUR table at **`0x0000`** |
| R4 | 0x07 | PATTERN table at **`0x2000`** |
| R5 | 0x76 | sprite ATTRIBUTES at `0x3B00` |
| R6 | 0x03 | sprite PATTERNS at `0x1800` |
| R7 | 0xE4 | border and backdrop |

R3 and R4 are not addresses: they are **base and mask**. Here they leave the
COLOUR table low and the PATTERNS high, exactly the opposite of the usual
layout. From that comes a rule that holds for all ten graphics batches: **the
colour of a pattern dump sits `0x2000` bytes lower, at the same address**. The
patterns at `0x2828` have their colour at `0x0828`, the ones at `0x2998` at
`0x0998`, and so on.

R7 changes with the scene: `0xE4` at start-up and `0x00` during the match, so
the pitch's backdrop is **black**, not blue.

## The sound

An interpreter of its own at `0x4E50`, with **54 sequences** pointed at by the
table at `0x50DA`. The tones come from twelve bytes at `0x50CE`, one per
semitone, and the octave is got by shifting left.

## Konami's hidden mark

The last thirteen bytes of the cartridge, from `0xBFF3` to `0xBFFF`:

    ... 0A 32 AA

Ten bytes with the title in katakana —コナミのサッカー— written backwards, its
length (`0x0A`), the **`0x32` of RC-732** and the closing `0xAA`.

That this mark exists and what shape it has was discovered by **Manuel Pazos**,
and this comes from him: all that was done here was checking that this
cartridge carries it and that the number inside is its own.
