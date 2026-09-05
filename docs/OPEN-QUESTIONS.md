# Open questions

What is **not** known, said plainly. All 32,768 bytes are accounted for and the
listing reproduces the ROM byte for byte, but that does not mean everything
makes sense.

## The twenty-seven `push hl / ret`

The dispatcher at `0xB2DA` is a `push bc / ret`, a hand-written `jp (bc)`, and
it hid 283 bytes of code. It is the only `push bc / ret` in the cartridge, but
there are **twenty-seven** `push hl / ret`, and they have not been gone through
one by one. Most will be hand-pushed returns —there are a few, and they are
commented— but if one of them hides another indirect jump, there is coverage to
be won there.

## Four variables without a name

- `(0xE551)` — it is cleared in every sub-state other than 1, and cleared again
  when the ball is taken. Who sets it has not been seen.
- `(0xE566)` and `(0xE567)` — the listing calls them "the bounce latches"
  because they are cleared together before a tackle, but exactly what they
  count is not settled.
- `(0xE546)` is known: it marks that the ball bounced off someone instead of
  being controlled, and it is what drops an offside call. It is set at `0xAA63`
  and cleared at `0xAAB8`.

## Why the ball is given a heading

When the ball is taken, `0xAAC2` looks at the mode of whoever took it: if he
was walking, `(0xE53A)` is set to **3**; if he was standing still, to **0**.
That 3 has not been explained. Why that value in particular, and what
difference it makes afterwards, is still open.

## The two-human delay table is faster

`0xA85E` holds two five-byte tables indexed by the level:

    10 0E 0C 0A 08     and     0B 0A 08 06 04

The first is the one for playing the machine; the second comes out with two
players. The reaction frames in the second are **smaller**, that is, the pieces
nobody is holding react faster when there are two humans. There is logic to
that —the twelve are shared between two pads, and none of them is "the
machine's"— but it has not been checked against the game.

## Pairing at five apart

`0xABCE` decides whether a tackle works by comparing headings. Besides the
head-on case, it accepts them being **five apart**: with headings numbered 1 to
8, the natural figure would be four —the opposite— and five pairs 1 with 6, 2
with 7 and 3 with 8. It could be a deliberate tolerance, or an offset inherited
from how the headings are numbered. Not settled.

## An `inc l` that may be one too many

At `0xA741` there is an `inc l` that leaves the pointer on the fine part of the
X and not on the height. If it is a bug, the effect would be small and hard to
see while playing; if it is not, what is being indexed still needs
understanding. Noted here.

## The seventeen bytes of the Game Master header

The second "AB" header at `0x4010` is the **Konami Game Master**'s, and that is
settled. What is not is the layout of the seventeen bytes behind it, at
`0x4014`. Read as words they give `0x6700`, `0xE000` and `0xE002` —the game's
two header variables, which fit— and then zeros and a `0x05`. But **that layout
is not shared with the other three cartridges** that carry the header, so here
it stands as a reasoned reading and not as a fact.

## Which of the two teams is "the good one"

Side 0 attacks left and side 1 right; pad 1 drives 0 and pad 2 drives 1. But
**which of the two is drawn with patches and which with sprites depends on
`(0xE527)`**, the side the camera follows, that is, the one with the ball.
Which means the split **changes during the match**. What has not been measured
is whether that shows while playing —whether the sprite-drawn team flickers
more, for instance—.

## The demo

The demo on the title screen is not a computed match: it is a **recorded
script** (`0x5965`) that writes into the pad bytes. What has not been extracted
is the script itself, nor how long it lasts, nor whether it is always the same
match.
