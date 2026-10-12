#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `pide_un_sonido_siempre` (0x4E5B, A = numero; `pide_un_sonido`,
0x4E50, solo suena con partida en marcha) y corre `tic_del_sonido` (0x4F25),
que el latido de la interrupcion llama cada cuadro. Tres voces de 14 bytes
desde 0xE010; la copia del registro 7 del PSG, en 0xE03A.
Uso:  musica.py registros 0x9B [cuadros] | mp3 0x9B f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xBF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x9B, "El tercer rótulo", "The third sign",
      "`escena_rotulo_3`: suena el 0x9B y se esperan 0x50 cuadros"),
    P(0xAE, "La pieza del 0xB8B6", "The tune at 0xB8B6", "`L_B8B6`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0xAD, 0xAF, 0xB0, 0xB1, 0xB2)]

PAGINA = motor_musica.pagina_basica(
    "`tic_del_sonido`, 0x4F25, y `pide_un_sonido_siempre`, 0x4E5B, que le "
    "reparte los canales; lo llama el latido de la interrupción",
    "`tic_del_sonido`, 0x4F25, and `pide_un_sonido_siempre`, 0x4E5B, which "
    "hands it the channels; the interrupt's beat calls it",
    "C-BIOS MSX1 japonés",
    [("el tercer rótulo (0x9B), sus primeros 232 cuadros de 385",
      "the third sign (0x9B), its first 232 frames of 385"),
     ("la pieza 0xAE, sus primeros 233 cuadros de 450",
      "tune 0xAE, its first 233 frames of 450")],
    [("Cómo se pide una pieza",
      "`pide_un_sonido_siempre` recibe el número en A (`pide_un_sonido` hace "
      "lo mismo solo con partida, bit 6 de 0xE002; las presentaciones y los "
      "menús entran por la primera). Los números bajos son efectos y del "
      "0x81 en adelante hay música. Cada voz ocupa catorce bytes desde "
      "0xE010 y 0xE03A guarda la copia del mezclador del PSG, que el "
      "arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de "
      "pistas pero ninguna rutina las pide con un `ld a`; se omiten la 0x9A, "
      "la 0x9C y la 0xAC, de minutos de duración.",
      "How a piece is asked for",
      "`pide_un_sonido_siempre` takes the number in A (`pide_un_sonido` does "
      "the same only during a game, bit 6 of 0xE002; presentations and menus "
      "come in through the first). Low numbers are effects and from 0x81 up "
      "there is music. Each voice takes fourteen bytes from 0xE010 and "
      "0xE03A holds the copy of the PSG mixer, which start-up leaves at "
      "0xB8. The tracks marked «in the table» are in the track table but no "
      "routine asks for them with an `ld a`; 0x9A, 0x9C and 0xAC, minutes "
      "long, are left out.")])

CFG = dict(rom="soccer.rom", org=0x4000, frame=0x4F25, pide=0x4E5B,
           ram=(0xE010, 0xE03B), ram0=[(0xE03A, 0xB8)],
           excluye=[0xE019, 0xE027, 0xE035], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x9B, 385, 1), (0xAE, 450, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
