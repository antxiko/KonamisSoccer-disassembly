#!/usr/bin/env python3
"""Saca del listado TODOS los volcados de la ROM a la VRAM, y los mide.

Los cargadores del cartucho tienen todos la misma forma: se pone el origen en
DE, a veces el destino en HL, y se llama a una de las puertas del
descompresor. Esto los busca en el .asm, los ejecuta con tools/rle.py y dice
cuanto ocupa cada bloque de verdad -lo marca su 0x00 final, no una
estimacion-.

Las puertas, y lo que hace cada una:

    L_47B7 / descomprime                    destino en HL, sin espejo
    L_47DE / descomprime_sin_espejo         destino en HL, sin espejo
    L_47E2 / descomprime_con_espejo         destino en HL, CON espejo
    L_47AF / descomprime_con_destino_dentro destino en los dos primeros bytes
    L_4698 / descomprime_en_los_tres_tercios          HL, HL+0x800, HL+0x1000
    L_46A8 / descomprime_espejado_en_los_tres_tercios  igual, espejado
    L_469A / L_46AA                          las mismas, con la cuenta en B

Uso: volcados.py <rom> <org> <asm>
"""
import re
import sys

from rle import descomprime

# nombre de la puerta -> (espejo, destino_dentro)
PUERTAS = {
    "descomprime":                          (False, False),
    "descomprime_sin_espejo":               (False, False),
    "descomprime_con_espejo":               (True,  False),
    "descomprime_con_destino_dentro":       (False, True),
    "descomprime_en_los_tres_tercios":      (False, False),
    "descomprime_espejado_en_los_tres_tercios": (True, False),
    "L_47B7": (False, False), "L_47DE": (False, False),
    "L_47E2": (True,  False), "L_47AF": (False, True),
    "L_4698": (False, False), "L_46A8": (True,  False),
    "L_469A": (False, False), "L_46AA": (True,  False),
}
TERCIOS = ("descomprime_en_los_tres_tercios",
           "descomprime_espejado_en_los_tres_tercios",
           "L_4698", "L_46A8", "L_469A", "L_46AA")


def main():
    rom = open(sys.argv[1], "rb").read()
    org = int(sys.argv[2], 0)
    lineas = open(sys.argv[3], encoding="utf-8").read().splitlines()

    de = hl = b = None
    de_en = None
    salida = []
    for ln in lineas:
        m = re.match(r"^\t(.*?)\s*;([0-9a-f]{4})", ln)
        if not m:
            continue
        ins, pc = m.group(1).strip(), int(m.group(2), 16)
        q = re.match(r"^ld de,0([0-9a-f]{4})h$", ins)
        if q:
            de, de_en = int(q.group(1), 16), pc
            continue
        q = re.match(r"^ld hl,0([0-9a-f]{4})h$", ins)
        if q:
            hl = int(q.group(1), 16)
            continue
        q = re.match(r"^ld b,0([0-9a-f]{2})h$", ins)
        if q:
            b = int(q.group(1), 16)
            continue
        q = re.match(r"^(?:call|jp) (\w+)$", ins)
        if not q:
            continue
        destino = q.group(1)
        # El `ld de,00800h` de dentro de los bucles de tres tercios es el salto
        # entre tercios, no un origen: un bloque siempre vive en el cartucho.
        if destino not in PUERTAS or de is None or de < org:
            continue
        espejo, dentro = PUERTAS[destino]
        vram = None if dentro else hl
        if vram is None and not dentro:
            continue
        r = descomprime(rom, org, de, vram, espejo)
        if r is None:
            salida.append((de, pc, destino, espejo, None, None, None))
        else:
            fin, _, tocado, tramos = r
            salida.append((de, pc, destino, espejo, fin, sum(tocado), tramos))
        de = hl = None

    print("%-19s %-8s %-6s %s" % ("BLOQUE EN LA ROM", "->VRAM", "espejo",
                                  "quien lo carga / donde cae"))
    print("-" * 78)
    vistos = {}
    for de, pc, destino, espejo, fin, n, tramos in sorted(salida):
        if fin is None:
            print("0x%04X  NO cierra          %-6s desde 0x%04X (%s)"
                  % (de, "si" if espejo else "no", pc, destino))
            continue
        rango = "0x%04X..0x%04X" % (de, fin - 1)
        tres = " x3" if destino in TERCIOS else ""
        donde = ", ".join("0x%04X(%d)" % (v, c) for v, c in tramos[:3])
        if len(tramos) > 3:
            donde += ", +%d" % (len(tramos) - 3)
        print("%-19s %5d B  %-6s desde 0x%04X%s -> %s"
              % (rango, n, "si" if espejo else "no", pc, tres, donde))
        vistos.setdefault(de, (fin, n))
    print("-" * 78)
    print("%d volcados, %d bloques distintos" % (len(salida), len(vistos)))


if __name__ == "__main__":
    main()
