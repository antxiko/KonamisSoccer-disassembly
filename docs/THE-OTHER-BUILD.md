# The other build: Konami's Football

The same cartridge also came out as **Konami's Football**. Same year, same
size, and **the same catalogue number, RC-732**. The question is what changes,
and the answer fits in one figure: **one instruction out of 9,755**.

    Konami's Soccer      b9536809a1784afb2e49a43d80ba9c6c8c15cd31ecbd6c284e9bf62c6927dcd4
    Konami's Football    1fee5ce4d4d5f48a92849eb7bed7ebb653f7e773fd4467824c27f54204b0fe7f

![Konami's Football's title screen](imagenes/titulo_football.png)

## The byte-by-byte diff is worth nothing

Compared byte by byte, the two cartridges differ in **28,586 bytes out of
32,768**, that is 87.2 %. That number says nothing: the second build is
**shifted**. Football's logo takes less room than Soccer's, everything behind
it moves, and from then on every `call` points somewhere else even though it
calls exactly the same thing.

Aligning the two ROMs, the shift changes only **four times** in 32 KB:

| from | to | shift |
|---|---|---|
| `0x4000` | `0x4D1C` | 0 |
| `0x4E1D` | `0x6DBC` | −46 |
| `0x6DDE` | `0x73C9` | −44 |
| `0x73CA` | `0x8599` | −40 |
| `0x85A9` | `0xBFF3` | −38 |

So Football starts 46 bytes shorter and gets 2, 4 and 2 back at three points.
And `0xBFF3` lines up again because Konami's mark is glued to the very end.

## Instruction by instruction

With that map the two builds can be compared the way they have to be: by
disassembling both and translating one's addresses into the other's space, so
that a `call 04ef7h` in Football and a `call 04f25h` in Soccer look the same,
which is what they are. `tools/coteja_builds.py` does it:

    python3 tools/coteja_builds.py soccer.rom football.rom \
            work/soccer.trace.json 0x4000

    9755 instrucciones cotejadas, 1 distintas (0.01 %)
      0x4cdb  A: ld c,005h    B(0x4cdb): ld c,004h

**That is the whole code difference between the two cartridges.** And it is on
the title screen: `0x4CDB` loads into C the number of rows of the big logo,
which `0x4CDD` walks stamping fourteen consecutive patterns per row. Soccer
paints **five rows** of tiles and Football **four**.

## And in the data, four things

Of the 125 declared data blocks, **97 are identical byte for byte**. Of the
remaining 28, twenty-four are pointer tables —sub-scenes, patches, sounds—
that change only because the addresses they point at have moved. Four real
changes are left, and all four are the same change:

| block | what it is | what changes |
|---|---|---|
| `patrones_4d1c` | the big title logo | 262 of 280 bytes: it is a different drawing |
| `patrones_6d8d` | the pitch tiles | Football writes **104 bytes of VRAM instead of 96**: one tile more |
| `color_739b` | the colour of those tiles | 7 of 120 bytes |
| `mapa_del_campo` | the pitch's 1,840 tiles | **7 tiles**, all on row 1, columns 41 to 48 |

Those seven tiles are **the advertising hoarding** that runs across the top of
the pitch.

![Konami's Football's pitch](imagenes/campo_football.png)

Compare it with [Soccer's](THE-GAME.html): it is the same pitch, line for
line, and the only thing that changes is what the hoarding says.

## What does NOT change

- The header from `0x4000` to `0x4025` is **identical byte for byte**: same
  "AB", same INIT at `0x4070` and the same Konami Game Master header at
  `0x4010` with its `0x07` and its `0x32`.
- **Konami's hidden mark** too: the thirteen bytes at `0xBFF3` are the same,
  `BA 85 B5 8A 00 98 00 9F 94 89 0A 32 AA`. The katakana title the cartridge
  carries hidden inside **still reads サッカー**, Soccer, even though the label
  says Football.
- And the game. The five difficulty tables, the aim, the offside, the player
  patches, the sound: the 97 identical blocks.

## Checked against the emulator

Football's pitch above is built by running the cartridge's own steps in Python,
and checked against an openMSX VRAM dump just like Soccer's:

    COLOUR 0    PATTERNS 0    SPR PATT 0
    MAP at 0xE600, 80x23:   2 of 1840   (the two goalkeepers)
    WINDOW of 23x32:       44 of 736    (42 are player patches)

Exactly the same figures as Soccer's.
