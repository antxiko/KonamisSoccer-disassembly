# Findings

What turned up when we took it apart. Each thing with the address where it can
be seen.

## Offside, with its three conditions and one exception

A 32 KB cartridge from 1985 carries the rule inside. `0xB667` runs the moment
the pass is made and asks for three things at once:

1. that the ball is heading for the opposing goal —the sign of the high byte of
   `(0xE2A8)`—;
2. that the receiver is in the opponents' half: past pixel `0x140` of the 640
   the pitch is wide, or short of it depending on the side;
3. that he is ahead of **all six** opponents, walked through one by one with an
   eight-pixel margin.

The referee does not blow there. `0xB6F2` waits for the ball to land
—`(0xE2AB)`, its vertical speed, at zero— and then checks `(0xE546)`: **if it
bounced off anyone on the way, the call is dropped**. Only if the pass arrived
and was controlled does `0x25` sound and the OFFSIDE banner come up.

And there is one more condition: with two players it is called **always**; with
one, **only from level 3 up** (`cp 003h` at `0xB671`). At levels 1 and 2 the
rule does not exist.

The free kick runs in three sub-scenes: run out the banner —`0x60` frames,
nearly two seconds—, wait for the button, and twenty frames of walking. With a
nice touch: **when the machine is the one taking it, the wait is halved**
—`0x40` frames instead of `0x80`— because nobody is going to press anything.

## Six players are tiles and six are sprites

An MSX1 shows only four sprites per scanline. With twelve players and two
goalkeepers that is hopeless, so the cartridge splits the problem and draws
**each side a different way**. It is in the order of the frame, `0x5882`-`0x5892`:

1. `guarda_el_fondo_del_bando` notes the 3x3 tiles each player is about to
   cover;
2. `estampa_el_bando_en_el_mapa` stamps the six patches **onto the map**, which
   lives in RAM;
3. `pon_el_bando_en_sprites` draws the other side with five sprites per player;
4. `vuelca_el_campo` throws the whole map at the VRAM;
5. `devuelve_el_fondo_al_mapa` puts the covered grass back.

That is why the RAM map, looked at in the emulator at any other moment, is
**clean**: its 1,840 tiles match the ones that come out of decompressing
`0x853E`, and the only two that differ are the two goalkeepers.

And the sprite side has two tricks of its own, both in `sube_los_sprites`
(`0x472B`):

- **The player you control never disappears.** Before the list goes up, the
  sixteen bytes of his group are swapped with the first one's, so he sits ahead
  of everybody and always wins the VDP's priority.
- **The rest flicker instead of vanishing.** Bit 0 of the frame counter splits
  the middle twenty sprites in two: on even frames they go up in order, on odd
  frames the last eight go first and the first twelve behind. The order flips
  every frame, so the fifth on a line is never the same one twice.

## The aim is never computed: it is looked up

The Z80 has neither multiply nor divide, and something has to decide how hard a
pass leaves so it lands where you want. `0x92E2` solves it by computing
nothing.

The two distances to the target are measured and split into steps of sixteen
—keeping the high nibble—: that gives a number from **0 to 15** for the
horizontal and one from **0 to 11** for the vertical. Those two index two
two-level tables at the end of the cartridge: the one at `0xBF0F` gives the
vertical impulse and the one at `0xBD6F` the two ground components.

Two corrections sit on top. On a throw-in the kick is softened to **three
quarters** —or to a half if the target is under three steps away in both
directions— and on the kick-off the vertical impulse and gravity are
**doubled**.

## One compressed block, two kits

Both teams share the same drawings, and what changes is the COLOUR table. The
same decompressor writes it, passing every byte through `0x4846`, which splits
the byte into its two nibbles —ink on top, paper below—, runs each through a
five-entry palette and puts them back together. Where the palette points is
held in `(0xE52A)`.

`0x6F31` leaves four pattern dumps at `0x2320`, `0x2458`, `0x2590` and
`0x26C8` —two straight and two mirrored— and `0x742D` paints them: the first
two with the palette at `0xE051` and the last two with the one at `0xE056`.

The palettes are built in **two steps**. `0x5A45` copies 39 factory bytes to
`0xE050`, and then `0x5C02` overwrites entries 2, 3 and 4 of each with the set
of three tones chosen in the menu. Building the screen without that second step
gets the COLOUR table wrong in **4,092 of its 6,144 bytes**.

## A hand-written `jp (bc)`

The Z80 has `jp (hl)`, but no `jp (bc)`. At `0xB2DA` the cartridge writes one
by hand: it pushes BC and does `ret`. To any tracer that is the end of a
routine, and behind it were **283 bytes** nobody reached, with their five-entry
table at `0xB2DC`.

What fixes the count at five and not six is that the sixth word already falls
outside the cartridge. It is the **only** `push bc / ret` in the 32 KB.

## Two scores compared with a single subtraction

At the end of the match you have to know whether there were penalties, that is,
whether the two teams finished level. Each score is two bytes: the BCD digit
and the carry, and comparing two pairs takes two subtractions.

`0xB903` does one. It builds **two crossed pairs** —one low digit from each
team with one carry from each team— and subtracts them with a single 16-bit
`sbc hl,bc`. The result is zero exactly when both comparisons hold at once.

## The tackle that fails ends in a collision

Winning the ball depends on the angle. `0xABCA` compares the tackler's heading
with the carrier's, and if they match —or are five apart— the tackle works,
with its whistle. If not, they crash.

The carrier gets **16 frames** frozen; the tackler has his heading rounded to
the next diagonal, is given drawing 4 —on the ground— and **slides twice, eight
pixels each time and eight frames apart**, with the ball following at his feet.
He gets up with it.

While it lasts, the ball physics **do not run**: entries 6 and 7 of the table
at `0x8C70` —the collision and the offside— are a bare `ret`.

## Nobody runs at the ball in a straight line

`0xB52A` decides which way each piece not held by a pad faces. It compares its
position with the ball's, joins the two bits that come out and indexes the
table at `0xB578` with them. The four indices it reaches give **the four
diagonals**: 2, 4, 8 and 6. The first two entries of the table —1 and 5, right
and left— are read by nobody.

And there is a wobble on top. Each piece carries a counter of its own at
`+0x1B`, and the two instructions at `0xB55C` are the only ones in the 32 KB
that touch it. **Nine counts out of every 64, the piece forgets the ball and
faces the opposing goal.** Since the counter only ticks down when the piece
gets its turn —and it does not if it is busy or if a pad is holding it— the six
drift apart on their own and do not move like a shoal of fish.

## The ten kinds of restart, and the positions

`(0xE533)` holds which restart is under way, and the values run from 1 to 10:

| | top | bottom |
|---|---|---|
| touchline | 1 | 2 |
| left corner | 3 | 4 |
| right corner | 5 | 6 |
| left goal kick | 7 | 8 |
| right goal kick | 9 | 10 |

Who takes it comes out of the position list at `(0xE410)`. The restarts only
use six codes: 3, 4 and 5 for the first side and 6, 7 and 8 for the second, and
they mean **top, middle and bottom**. The top corner is taken by 3 or 6, the
bottom one by 5 or 8, and the goal kick by 4 or 7. The offside free kick picks
by the same rule, from the band of the pitch where it was called.

## The two goal lines, written out twice

`0x9853` and `0x9A46` do the same thing with the numbers swapped: the four post
pixels, the crossbar, the goal and the restart that comes out of it. **The net
is at pixel `0x12` and at `0x267`**: that is where the ball is pinned, with
sound `0x47`, and its height is clipped on the way so it cannot leave over the
top of the post. The crossbar returns **half the speed** —`0x98A7` negates and
halves— and the post only flips the sign of the drift.

## The fifteen zones of the pitch

`0xA219` cuts the ground into five bands across —the cuts are at `0xD0`,
`0x100`, `0x180` and `0x1B0`— by three down —`0x49` and `0x78`— according to
where the ball is, and leaves the number in `(0xE52B)`. The team's formation
comes from the table at `0xA880` with that number: **5 × 3 × 12 bytes × 2 teams
are exactly the 360 bytes** the table takes. The formation changes with where
the ball is.

## The machine presses the pad

Neither the demo script (`0x5965`), nor the penalty intelligence (`0x6907`),
nor the match one moves anything by hand: they **write into the same pad byte a
human would be read from**. And the randomness comes from the low bits of the
frame counter, `(0xE003)`.

## The same key is pass and shot

Letting go passes to a team-mate. Holding it for **fourteen frames** (`0x946C`)
turns it into a shot, and then the target stops being a player and becomes a
goal: pixel 15 or pixel 624 of the pitch's 640.

## Dead code, and three oddities

- **The stretches at `0xAAEE` and `0xAAFA` never run.** They only do if
  `(0xE545)` is 1, and `(0xE545)` appears **once** in the 32 KB, as a read. On
  top of that `0x5648` wipes `0xE100`-`0xE5FF` when each play is set up.
- **A jump into the middle of an instruction.** `0xAEAF` holds `28 01` —a
  `jr z,+1`— and lands on `0xAEB2`, which is not an instruction but the operand
  of the `ld l,0C0h` at `0xAEB1`. That loose `0xC0` executes as `ret nz`, and
  since `0xAEB2` is only reached with Z set, it never returns. It is the only
  label in the cartridge that does not fall on an emitted position. It saves
  neither a byte nor a cycle, so it is an oddity and not a trick.
- **Two dead writes to the ROM itself**: `0x4028` writes to `(0x410A)` and
  `0x4056` to `(0x4116)`. The bytes do not change, of course.
- **A dead read and a `jr` that goes nowhere**: nobody looks at the
  `ld a,(0e003h)` at `0xB97D` —`0xB9AE` clobbers A on all three of its paths—
  and the `jr` at `0xB9A5` goes to `0xB9A7`, the very next instruction.
