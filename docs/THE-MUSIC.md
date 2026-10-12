# The music

Everything you hear here comes from running the cartridge's own sound engine (`tic_del_sonido`, 0x4F25, and `pide_un_sonido_siempre`, 0x4E5B, which hands it the channels; the interrupt's beat calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the third sign (0x9B), its first 232 frames of 385;
- tune 0xAE, its first 233 frames of 450.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`pide_un_sonido_siempre` takes the number in A (`pide_un_sonido` does the same only during a game, bit 6 of 0xE002; presentations and menus come in through the first). Low numbers are effects and from 0x81 up there is music. Each voice takes fourteen bytes from 0xE010 and 0xE03A holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; 0x9A, 0x9C and 0xAC, minutes long, are left out.

## The tunes

**The third sign** (0x9B)

Asked for by `escena_rotulo_3`: suena el 0x9B y se esperan 0x50 cuadros; lasts 6.4 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_9B.mp3?v=1eb9462c"></audio>

**The tune at 0xB8B6** (0xAE)

Asked for by `L_B8B6`; lasts 7.5 s.

<audio controls preload="none" src="audio/musica_AE.mp3?v=8ce6badb"></audio>

**Table track 0xAD** (0xAD)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 7.5 s.

<audio controls preload="none" src="audio/musica_AD.mp3?v=a02111a6"></audio>

**Table track 0xAF** (0xAF)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 7.5 s.

<audio controls preload="none" src="audio/musica_AF.mp3?v=db278e35"></audio>

**Table track 0xB0** (0xB0)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 7.5 s.

<audio controls preload="none" src="audio/musica_B0.mp3?v=c860259e"></audio>

**Table track 0xB1** (0xB1)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.9 s.

<audio controls preload="none" src="audio/musica_B1.mp3?v=3bcbb48a"></audio>

**Table track 0xB2** (0xB2)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.9 s.

<audio controls preload="none" src="audio/musica_B2.mp3?v=89e468ed"></audio>
