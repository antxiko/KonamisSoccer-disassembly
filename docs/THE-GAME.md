# The game

*Konami's Soccer* came out in 1985 for the MSX, on a 32 KB cartridge with
catalogue number **RC-732**. A six-a-side football match plus goalkeepers, with
a clock, a penalty shoot-out and a name editor for both teams.

![The whole pitch, drawn from the ROM](imagenes/campo.png)

## The pitch does not fit on the screen

An MSX1 shows 32 tiles across. This game's pitch is **80** wide, and it lives
decompressed in RAM at `0xE600`: 80 columns by 23 rows, 1,840 tiles. The screen
is a 32-column window sliding over it, and where it sits is held in
`(0xE2C1)`, which starts at 24.

That measurement is written nowhere in the cartridge: it is fixed by the
arithmetic of `vuelca_el_campo` (`0x5DD6`), which pushes out 32 tiles with
`outi` and then **skips 48** before the next row. 32 plus 48 is 80.

In pixels the pitch is 640 wide. The touchlines are at heights `0x1D` and
`0xB3` —150 pixels apart—, the goal lines at pixel 30 and 601, the posts take
up `0x49`-`0x4A` and `0x81`-`0x82` —two pixels thick each— and between them
there are **54 pixels of goal**. The net is at pixel `0x12` and at `0x267`:
that is where a scoring ball is pinned, with its own sound.

## The players

![The 51 player poses](imagenes/fichas.png)

The twelve outfield players are not drawn the same way. One side is **stamped
onto the map**, as three-by-three tile patches; the other is drawn with **five
sprites per player**. [Findings](FINDINGS.html) has the reason and the exact
order of the frame.

The poses come from a two-level tree: `(ix+0x0C)` picks the group and
`(ix+0x0D)` the drawing within it. There are **26 poses for one side and 25 for
the other**, and they are all above.

The two goalkeepers are not pieces like the rest: they are two patches with
their own table and their own background store, stamped after the six.

## The rules the cartridge carries

- **Offside is called.** With two players, always; against the machine, only
  from **level 3 up**.
- **Winning the ball depends on the angle.** If the tackler and the carrier are
  not facing each other, instead of a tackle there is a collision: both go
  down.
- **The crossbar returns half the speed**, and the post only flips the sign of
  the sideways drift, with its own sound.
- **Level at the end: penalties**, and the shoot-out has its own steps, its own
  goalkeeper and its own aim.

## The five levels

There is no separate intelligence per level: there are **dead bands and
permissions**.

| level | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| height at which the keeper stops reacting | 32 | **44** | 24 | 20 | 16 |
| frames the machine takes to react | 16 | 14 | 12 | 10 | 8 |
| machine's stride with the ball | 0x0E0 | 0x0F0 | **0x100** | 0x110 | 0x120 |
| machine's stride when loose | 0x130 | 0x140 | **0x150** | 0x160 | 0x170 |

The human's side reacts **always in 8 frames**, so the machine never gets to
beat it: at level 5 it matches it. And **level 3 is the level that is level**:
it is where the machine's stride is exactly the human's —`0x100` with the ball
and `0x150` loose, the two fixed values `0x5721` gives side 0—. Below 3 the
machine walks slower than you; above, faster.

The odd one out is the **level 2** keeper, who at 44 is the most passive of the
five, more than the level 1 one. From 3 to 5 the progression falls cleanly.

And there are four things the machine only does from a certain level up:

| what it does | from level |
|---|---|
| aim where the target will be, not where it is (`0x9260`) | 4 |
| the diagonal feint (`0xB12C`) | 3 |
| clearing after a shot (`0xB19D`) | 4 |
| correcting to the corner away from the keeper (`0xB266`) | 4 |
| calling offside (`0xB671`) | 3 |

At level 1, on top of that, half the passes do not even dodge (`0xB0D4`).

## The menu

![The title screen and its menu](imagenes/titulo.png)

You choose one or two players, the kit colour of each team —eight sets of
three tones, and the menu will not let them match—, the level and the length of
a half. The team names are edited letter by letter, and out of the factory they
are **EAGLES** and **STONES**.
