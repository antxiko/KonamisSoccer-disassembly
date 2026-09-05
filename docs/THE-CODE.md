# The code

## Everything hangs off the interrupt

`0x4070` hooks `H.KEYI` and then sits still in a `jr $`. From there on, the
whole program is what runs every fiftieth of a second. `0x40C8` dispatches the
scene `(0xE000)` names with the nine-entry table at `0x40E3`, and `(0xE001)`
dispatches the step inside it with a chain of `djnz`.

| variable | what it is |
|---|---|
| `(0xE000)` | the scene |
| `(0xE001)` | the step within the scene |
| `(0xE003)` | the frame counter, which doubles as randomness |
| `(0xE004)` | the wait count |
| `(0xE005)` | the reentrancy lock |

## The dispatcher with the table right behind

Almost the whole program is a state machine, and the mechanism repeats
thirteen times: a `call 0x4066` with the pointer table **stuck right behind the
`call`**. The routine takes the return address off the stack, uses it as the
base of the table, indexes with A and jumps.

How many entries each table has is written nowhere. It is fixed by a fit: **no
entry can point inside its own table**, so the first one marks where it ends.
That fit corrected two that looked like 24 and 29 entries and are 9 and 4.

## The one with the `push bc / ret`

There is a fourteenth dispatcher that looks like none of the others.
`0xB2CC` takes the destination from the table at `0xB2DC`, pushes it and does
`push bc / ret`: a `jp (bc)`, which the Z80 does not have, written by hand. To
a tracer that is the end of a routine, and behind it sat **283 bytes** nobody
reached.

## The decompressor

Almost all the graphics are compressed, in a one-command-per-byte format that
writes straight to VRAM. `L_47B7` does it:

| command | what it does |
|---|---|
| `0x00` | closes the block; it is the **only** thing marking where it ends |
| `0x01`-`0x7F` | the byte that follows, repeated that many times |
| `0x80` | the two bytes that follow are a new VRAM address |
| `0x81`-`0xFF` | copies the next (command `& 0x7F`) bytes as they are |

Since the size is written nowhere, **running the decompressor is the only
honest way to know where each block ends**. That is what `tools/rle.py` does,
and it is where the limits of the 125 declared data ranges come from.

On top of that format there are two additions, and both save ROM:

- **The mirror.** `L_4836` reads each byte and, if bit 0 of C is set, `L_483B`
  puts it out with its eight bits reversed, which in SCREEN 2 is reflecting the
  pattern. There are two doors, `L_47DE` with C=0 and `L_47E2` with C=1, and
  both fall into the same loop. The same compressed block does both halves of a
  symmetric drawing.
- **The recolouring.** `L_4707` is the same loop passing each byte through
  `0x4846`, which swaps the two nibbles of the colour byte for a five-entry
  palette in RAM. The same block paints both kits.

The dumping doors, all in the same stretch:

| address | what it does |
|---|---|
| `0x4680` | LDIRVM, an uncompressed block |
| `0x4684` | FILVRM |
| `0x4687` | FILVRM in all three thirds |
| `0x4698` | decompresses into all three thirds |
| `0x46A8` | the same, mirrored |
| `0x46B8` | the same, changing the colour |
| `0x47AF` | the destination is in the block's first two bytes |

## The match frame

`0x5805` is what runs on every interrupt while the game is on, and **the order
matters**: each routine relies on what the previous one left.

    the referee and the rules        0x5818
    the three offside sub-scenes     0x581B
    the restart countdown            0x5828
    which zone the ball is in        0x582B
    switching player with the button 0x582E
    who holds which position         0x5831
    the machine picks a team-mate    0x5834
    each pad's highlighted player    0x5837
    the player-change beep           0x583A
    the collision sub-state          0x583D
    a frame of the tactics           0x5840
    the two goalkeepers' logic       0x5843
    everybody faces the ball         0x5846

And the drawing, afterwards:

    save the side's background       0x5882
    stamp the side onto the map      0x5885
    put the other side in sprites    0x5888
    dump the pitch to VRAM           0x588F
    put the background back          0x5892

## The match variables

| variable | what it is |
|---|---|
| `(0xE100)` | the twelve pieces, 32 bytes each |
| `(0xE280)` | the match sub-state |
| `(0xE281)` | the ball sub-state |
| `(0xE2A1)` `(0xE2A5)` | the ball's height and horizontal position |
| `(0xE2AB)` | its vertical speed |
| `(0xE2C1)` | where the pitch window sits |
| `(0xE410)` | the position list of the twelve pieces |
| `(0xE527)` | the side the camera follows |
| `(0xE528)` | who has the ball |
| `(0xE52C)` `(0xE52D)` | each pad's highlighted player |
| `(0xE533)` | which restart is under way, from 1 to 10 |
| `(0xE600)` | the pitch map, 80 by 23 |

Inside a piece, the offsets that get used most:

| +N | what it is |
|---|---|
| +0x03 | the heading, 1 to 8 |
| +0x04 | the height |
| +0x06 +0x07 | the horizontal position, in 16 bits |
| +0x0A +0x0B | the on-screen position; `0xE0` in the height means "not visible" |
| +0x0C | the drawing group |
| +0x0D | the drawing within the group; 4 is on the ground |
| +0x15 | the piece number, 0 to 11 |
| +0x16..+0x18 | where it has to go |
| +0x1A | the frames left before it reacts |

## The eight headings

They are used at every turn, and always the same way:

    6  7  8
    5  ·  1
    4  3  2

The first side —pieces 0 to 5— **attacks to the left** and the second —6 to
11— **to the right**. It checks out three independent ways: where the receiver
of a pass has to be for offside, which way the taker of a free kick faces, and
which way he walks while getting into place.
