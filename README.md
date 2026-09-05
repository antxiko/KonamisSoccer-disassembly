# Konami's Soccer (Konami, 1985) — a commented disassembly

A complete, commented disassembly of the MSX1 cartridge **Konami's Soccer**
(Konami, catalogue number **RC-732**, 32 KB), reproducible byte for byte.

**Web: <https://antxiko.github.io/KonamisSoccer-disassembly/>** · [En castellano](README.es.md)

|  |  |
|---|---|
| Of the binary explained | **100%** — 0 bytes unaccounted for, of 32,768 |
| Reassembles | **byte for byte**, to the same sha256 |
| Listing commented | **36.5%** — 3,561 comments over 9,755 instructions |
| Routines below the 10% bar | **0** of 1,213 |
| Instructions differing from Konami's Football | **1** of 9,755 |
| Pictures checked against the emulator's VRAM | title **0** bytes different, pitch **0** |

## What is in here

    src/soccer.asm            the listing, generated
    src/soccer.notes          what is understood: data blocks and comments
    src/soccer.entries        the entry points, each with its reason
    src/soccer.nocode         the ranges that are not code
    tools/                    the tracer, the listing generator and the checks
    tests/                    39 tests over the listing and the site
    docs/                     the site, in English and Spanish

The cartridge itself is **not** distributed. Put it in the root as
`soccer.rom`; `make comprueba` verifies its sha256.

## Rebuilding it

    make

Traces the flow, writes the listing, reassembles it and checks that the result
is the ROM byte for byte, then runs the sanity checks and the tests. See
[Getting started](https://antxiko.github.io/KonamisSoccer-disassembly/GETTING-STARTED.html).

## Some of what turned up

- **It calls offside.** Three conditions checked at the moment of the pass, the
  call dropped if the ball bounced off anyone on the way — and, against the
  machine, the rule only exists **from level 3 up**.
- **Six players are tiles and six are sprites.** One side is stamped as 3x3
  patches onto an 80-column pitch map held in RAM, the other is drawn with five
  sprites each. That is how twelve players fit on a machine that shows four
  sprites per line.
- **The aim is never computed: it is looked up.** Two distances, split into
  steps of sixteen, index two two-level tables at the end of the cartridge.
- **One compressed block, two kits.** The same drawings, recoloured through a
  five-entry palette as they are decompressed.
- **A hand-written `jp (bc)`** — `push bc / ret` — that hid 283 bytes of code
  from the tracer.
- **Konami's hidden mark** in the last thirteen bytes, a finding of
  **Manuel Pazos**.
- And **one instruction out of 9,755** is all that separates this cartridge
  from **Konami's Football**, the same RC-732 under another name: the `ld c,nn`
  that says how many rows of tiles the title logo is tall. See
  [The other build](https://antxiko.github.io/KonamisSoccer-disassembly/THE-OTHER-BUILD.html).

All of it, with the measurement next to each claim, in
[Findings](https://antxiko.github.io/KonamisSoccer-disassembly/FINDINGS.html).

## The pictures are drawn from the ROM

There is not one screen capture in this repository. `tools/graficos.py` builds
the screens by running in Python the same steps the Z80 runs, and
`tools/coteja_vram.py` compares the result byte for byte against a VRAM dump
taken from openMSX.

## Licence

The tools, the notes and the site are published under the MIT licence (see
[LICENSE](LICENSE)). The code and artwork of the game remain the property of
their authors and of Konami; see [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
