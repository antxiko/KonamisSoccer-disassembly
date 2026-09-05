# Getting started

The repository ships the listing already generated, but what matters is that it
can be **rebuilt from the cartridge** and that the result is the ROM byte for
byte. That is what makes the notes believable.

## What you need

- **Python 3** (that is all: not one dependency)
- **pasmo**, the Z80 assembler, for the reassembly check
- **make**
- For the checks against the machine, **openMSX**

## The cartridge

It does not travel with the repository. Put it in the root as `soccer.rom`,
32,768 bytes exactly:

    b9536809a1784afb2e49a43d80ba9c6c8c15cd31ecbd6c284e9bf62c6927dcd4

To check it is the same one:

    make comprueba

## Rebuilding everything

    make

That chains the four things that matter:

| step | what it does |
|---|---|
| `make listado` | traces the flow from the entry points and writes `src/soccer.asm` |
| `make verify` | reassembles with pasmo and compares the sha256 against the cartridge |
| `make sanity` | what reassembling CANNOT catch (see below) |
| `make test` | the 39 tests |

## Why `make verify` is not enough

Reassembling proves the **bytes** are the same, not that what we say about them
is true. A range of graphics read as code reassembles identically —the bytes
do not change, only how they are read— and inflates the coverage on the way.
That is why `make sanity` runs three more checks:

| check | what it watches |
|---|---|
| `check_trace.py` | that the ranges in `.nocode` were not traced as code |
| `check_datos_como_codigo.py` | that none of the **125 declared data ranges** comes out as code |
| `check_entradas.py` | that no entry point falls inside a data range |
| `presupuesto.py` | that code and data add up to the 32,768 bytes, with no gaps |

## The rest

    make densidad     # how many instructions carry a comment, routine by routine
    make imagenes     # draws the five plates from the ROM
    make vram         # checks them byte for byte against openMSX's VRAM
    make web          # regenerates this site

## Where everything is

| file | what it is |
|---|---|
| `src/soccer.asm` | the listing, generated |
| `src/soccer.notes` | the annotations: names, comments and data ranges |
| `src/soccer.entries` | the entry points that cannot be deduced, each one justified |
| `src/soccer.nocode` | the ranges the tracer must not step into |
| `tools/` | the tracer, the listing generator, the decompressor and the drawing tools |
| `tests/` | the 39 tests, which run without the cartridge |

The tests do not need the ROM: they rebuild the data bytes by reading the
`defb` rows of the listing itself, which carry their address in the comment.
