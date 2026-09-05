#!/usr/bin/env python3
"""Convierte el catalogo de volcados en directivas D para el .notes.

tools/volcados.py encuentra cada bloque comprimido y lo MIDE ejecutando el
descompresor del propio cartucho. Esto coge esa medida y escribe la directiva,
poniendole a cada bloque el nombre de lo que es SEGUN DONDE CAE en la VRAM,
que es el unico dato que no admite interpretacion: el reparto lo fijan los
ocho bytes de 0x4889.

    0x0000..0x17FF   COLOR
    0x1800..0x1FFF   patrones de SPRITE
    0x2000..0x37FF   PATRONES
    0x3800..0x3AFF   NOMBRES
    0x3B00..0x3BFF   atributos de sprite

Un bloque que cae en varios sitios a la vez -los que llevan mandatos 0x80- se
nombra por el primero y la directiva lo dice.

Uso: notas_de_volcados.py <rom> <org> <asm>
"""
import re
import subprocess
import sys
import os

PAT = re.compile(r"0x([0-9A-Fa-f]{4})\.\.0x([0-9A-Fa-f]{4})\s+(\d+) B\s+"
                 r"(si|no)\s+desde 0x([0-9A-Fa-f]{4})(\s*x3)?\s*->\s*(.*)$")


def zona(v):
    if v < 0x1800:
        return "color"
    if v < 0x2000:
        return "patrones_de_sprite"
    if v < 0x3800:
        return "patrones"
    if v < 0x3B00:
        return "nombres"
    return "atributos_de_sprite"


def main():
    aqui = os.path.dirname(os.path.abspath(__file__))
    r = subprocess.run([sys.executable, os.path.join(aqui, "volcados.py"),
                        os.path.abspath(sys.argv[1]), sys.argv[2],
                        os.path.abspath(sys.argv[3])],
                       capture_output=True, text=True, cwd=aqui)
    if r.returncode:
        sys.exit("volcados.py fallo:\n" + r.stderr)
    out = r.stdout
    bl = {}
    for ln in out.splitlines():
        m = PAT.search(ln)
        if not m:
            continue
        a, b = int(m.group(1), 16), int(m.group(2), 16)
        bl.setdefault((a, b), []).append(
            (int(m.group(3)), m.group(4) == "si", int(m.group(5), 16),
             bool(m.group(6)), m.group(7)))

    claves = sorted(bl)
    # Un bloque que cae ENTERO dentro de otro no es un bloque aparte: es el
    # mismo flujo reentrado por la mitad. Se queda el de fuera.
    dentro = {k for k in claves
              if any(o != k and o[0] <= k[0] and k[1] <= o[1] for o in claves)}
    quedan = [k for k in claves if k not in dentro]

    solapes = [(quedan[i], quedan[i + 1]) for i in range(len(quedan) - 1)
               if quedan[i][1] >= quedan[i + 1][0]]

    print("# %d bloques medidos, %d bytes" % (len(quedan),
                                              sum(b - a + 1 for a, b in quedan)))
    if dentro:
        print("# %d reentrados por la mitad de otro, no llevan directiva propia:"
              % len(dentro))
        for a, b in sorted(dentro):
            print("#     0x%04X..0x%04X" % (a, b))
    if solapes:
        print("# CUIDADO, %d solapes parciales que hay que mirar a mano:"
              % len(solapes))
        for x, y in solapes:
            print("#     0x%04X..0x%04X con 0x%04X..0x%04X"
                  % (x[0], x[1], y[0], y[1]))
    print()

    for a, b in quedan:
        usos = bl[(a, b)]
        n, espejo, pc, x3, donde = usos[0]
        v = int(donde.split("(")[0], 16)
        nom = "%s_%04x" % (zona(v), a)
        quien = ", ".join("0x%04X" % u[2] for u in usos)
        det = "%d bytes comprimidos que dan %d de VRAM en 0x%04X" % (b - a + 1, n, v)
        if len(usos) > 1:
            det += "; lo cargan %d sitios (%s)" % (len(usos), quien)
        else:
            det += "; lo carga 0x%04X" % pc
        if any(u[1] for u in usos):
            det += ". Se vuelca tambien ESPEJADO, con los ocho bits de cada byte del reves"
        if x3:
            det += ". Va a los TRES tercios de SCREEN 2"
        if "," in donde:
            det += ". Se reparte en varios tramos (mandatos 0x80): %s" % donde
        print("D 0x%04x 0x%04x %s  %s" % (a, b + 1, nom, det))
        print("F 0x%04x 1" % a)


if __name__ == "__main__":
    main()
