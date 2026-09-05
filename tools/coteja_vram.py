#!/usr/bin/env python3
"""Compara la VRAM que monta graficos.py con la que vuelca el emulador.

Mirar el dibujo no basta: dos imagenes pueden parecerse y tener las tablas
distintas. Esto compara BYTE A BYTE las tablas -color, patrones, patrones de
sprite y nombres- contra los volcados de tools/omsx_vram.tcl, y dice en cual y
en cuantos bytes se diferencian.

Lo que NO se compara, y por que:

  - la tabla de ATRIBUTOS de sprite (0x3B00), porque cambia cada cuadro;
  - en el campo, los tiles 0x5C..0x63 y el 0x63 de los otros dos tercios: son
    el pozo que el juego reescribe en marcha para estampar los parches de 3x3
    de los jugadores. graficos.py monta el DECORADO, que es lo que dice montar,
    y no juega un partido;
  - en el campo, la tabla de NOMBRES entera, que se compara aparte contra el
    mapa de 80x23 -ahi si, casilla a casilla-.

Con la escena `campo` se comprueban ademas dos cosas que la VRAM sola no dice:

  - el MAPA de 80x23 casillas que 0x8538 descomprime en 0xE600, contra la RAM
    de verdad del emulador;
  - la VENTANA de 32 columnas que `vuelca_el_campo` (0x5DD6) asoma a la
    pantalla, contra la tabla de nombres.

Uso: coteja_vram.py <rom> <vram.bin> <escena> [ram.bin]
     escena: titulo | fuente | campo
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import graficos

TABLAS = (
    ("COLOR    ", 0x0000, 0x1800),
    ("SPR PATR ", 0x1800, 0x2000),
    ("PATRONES ", 0x2000, 0x3800),
    ("NOMBRES  ", 0x3800, 0x3B00),
)

# El pozo de los parches de jugador, que el partido reescribe cada cuadro.
POZO = ((0x02E0, 0x0320), (0x0B18, 0x0B20), (0x1318, 0x1320),
        (0x22E0, 0x2320), (0x2B18, 0x2B20), (0x3318, 0x3320))


def en_el_pozo(a):
    return any(i <= a < f for i, f in POZO)


def coteja_el_mapa(rom, ram):
    """El mapa de 80x23 de 0xE600, contra la RAM del emulador."""
    mio = graficos.mapa_del_campo(rom)
    real = ram[0x600:0x600 + 80 * 23]
    d = [i for i in range(80 * 23) if mio[i] != real[i]]
    print("  MAPA 0xE600, 80x23 casillas  %s" % (
        "OK" if not d else "%d de %d" % (len(d), 80 * 23)))
    for i in d[:6]:
        print("       fila %2d columna %2d: 0x%02X contra 0x%02X"
              % (i // 80, i % 80, mio[i], real[i]))
    return len(d)


def coteja_la_ventana(rom, real, ram):
    """Las 32 columnas que se asoman, contra la tabla de nombres."""
    mio = graficos.mapa_del_campo(rom)
    off = ram[0x2C1]                              # (0xE2C1)
    d = altos = 0
    for f in range(23):
        for c in range(32):
            r = real[0x3820 + f * 32 + c]
            if mio[f * 80 + off + c] != r:
                d += 1
                if r > 0x58:
                    altos += 1
    print("  VENTANA de 23x32 en 0x3820, corrida %d columnas  %s" % (
        off, "OK" if not d else "%d de %d, y %d son parches de jugador"
        % (d, 23 * 32, altos)))
    return d - altos


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    rom = open(sys.argv[1], "rb").read()
    real = open(sys.argv[2], "rb").read()
    escena = sys.argv[3]
    ram = open(sys.argv[4], "rb").read() if len(sys.argv) > 4 else None
    mio = {
        "titulo": graficos.escena_titulo,
        "fuente": graficos.escena_fuente,
        "campo": graficos.escena_campo,
    }[escena](rom)

    print("  %s contra %s" % (escena, os.path.basename(sys.argv[2])))
    print("  " + "-" * 58)
    total = 0
    for nombre, ini, fin in TABLAS:
        if escena == "campo" and nombre.startswith("NOMBRES"):
            continue                              # se compara contra el mapa
        if escena != "campo" and nombre.startswith("SPR"):
            continue                              # esas escenas no traen sprites
        d = [a for a in range(ini, fin)
             if mio[a] != real[a] and not (escena == "campo" and en_el_pozo(a))]
        total += len(d)
        n = fin - ini
        marca = "OK" if not d else "%d de %d (%.1f %%)" % (
            len(d), n, 100.0 * len(d) / n)
        print("  %s 0x%04X..0x%04X  %s" % (nombre, ini, fin - 1, marca))
        if d:
            print("       primeros: %s" % " ".join("0x%04X" % a for a in d[:8]))
    if escena == "campo" and ram is not None:
        total += coteja_el_mapa(rom, ram)
        total += coteja_la_ventana(rom, real, ram)
    print("  " + "-" * 58)
    print("  %d diferencias" % total)
    return 0 if total == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
