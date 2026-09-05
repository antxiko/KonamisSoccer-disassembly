#!/usr/bin/env python3
"""Compara DOS compilaciones del mismo juego, instruccion a instruccion.

Por que hace falta. Konami's Football y Konami's Soccer son el mismo RC-732 con
otro nombre en la etiqueta, y el diff byte a byte dice que se diferencian en el
87 % de los 32.768 bytes. Ese numero no vale para nada: la segunda compilacion
esta CORRIDA -46 bytes al principio, y a partir de ahi todo cae desalineado.
Lo que hay que comparar son las INSTRUCCIONES, no los bytes.

Como lo hace:

  1. Alinea las dos ROM con difflib y se queda con los bloques de coincidencia
     grandes. De ahi sale un mapa de direcciones A -> B a trozos, con su
     desplazamiento en cada tramo. En este par el desplazamiento solo cambia
     cuatro veces en 32 KB.
  2. Para cada rango de CODIGO del trazado de la primera ROM, desensambla los
     dos con z80dasm: la primera en su direccion y la segunda en la que dice el
     mapa.
  3. Normaliza: toda direccion de la segunda que caiga dentro del cartucho se
     traduce hacia atras con el mapa. Asi un `call 4ef7h` de la segunda y un
     `call 4f25h` de la primera se ven iguales, que es lo que son.
  4. Y compara los dos flujos ya normalizados.

Lo que sale por pantalla son las diferencias que QUEDAN, que son las de verdad.

Uso: coteja_builds.py <rom A> <rom B> <trace A.json> <org>
"""
import difflib
import json
import os
import re
import subprocess
import sys

TMP = os.path.join(os.environ.get("TEMP", "."), "coteja_builds.bin")


def mapa_de_direcciones(a, b, minimo=16):
    """Los tramos (ini_a, fin_a, desplazamiento) que alinean A con B."""
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    tramos = []
    for m in sm.get_matching_blocks():
        if m.size < minimo:
            continue
        d = m.b - m.a
        if tramos and tramos[-1][2] == d:
            tramos[-1][1] = m.a + m.size          # se alarga el tramo anterior
        else:
            tramos.append([m.a, m.a + m.size, d])
    return [tuple(t) for t in tramos]


def traduce(off, tramos):
    """De un desplazamiento en A al que le toca en B."""
    d = None
    for ini, fin, dd in tramos:
        if ini <= off < fin:
            return off + dd
        if off >= fin:
            d = dd
    return off + d if d is not None else off


def desensambla(datos, org, ini, fin):
    """z80dasm sobre un trozo, devuelto como lista de (direccion, texto)."""
    with open(TMP, "wb") as f:
        f.write(datos[ini - org:fin - org])
    dtmp = os.path.dirname(TMP) or "."
    r = subprocess.run(["z80dasm", "-a", "-g", hex(ini), TMP],
                       capture_output=True, text=True,
                       env=dict(os.environ, TMP=dtmp, TEMP=dtmp))
    os.unlink(TMP)
    if r.returncode != 0:
        raise SystemExit("z80dasm fallo en %#06x: %s" % (ini, r.stderr))
    out = []
    for ln in r.stdout.splitlines():
        m = re.search(r"^\s+(.*?)\s*;([0-9a-f]{4})\s*$", ln)
        if m:
            out.append((int(m.group(2), 16), m.group(1).strip()))
    return out


def normaliza(texto, tramos, org, fin_rom):
    """Traduce de B a A las direcciones del cartucho que cite la instruccion.

    Es lo que hace comparables los dos flujos: un `call 04ef7h` de la segunda
    compilacion y un `call 04f25h` de la primera son la MISMA llamada, y aqui
    se ven iguales.

    Ojo con la forma en que z80dasm escribe las direcciones: lleva un cero
    delante (`04ef7h`, cinco digitos), asi que el patron tiene que admitirlo o
    no casa ni una.
    """
    def sust(m):
        v = int(m.group(1), 16)
        if not (org <= v < fin_rom):
            return m.group(0)
        for ini, f, d in tramos:                  # la A cuya traduccion da esta B
            if ini + d <= v - org < f + d:
                return "0%04xh" % (v - d)
        return m.group(0)
    return re.sub(r"\b(0[0-9a-f]{4}|[0-9a-f]{4})h\b", sust, texto)


def main(argv):
    if len(argv) < 5:
        print(__doc__)
        return 2
    a = open(argv[1], "rb").read()
    b = open(argv[2], "rb").read()
    org = int(argv[4], 0)
    fin_rom = org + len(a)
    with open(argv[3], encoding="utf-8") as f:
        bloques = json.load(f)["blocks"]

    tramos = mapa_de_direcciones(a, b)
    print("  el mapa de alineacion, %d tramos:" % len(tramos))
    for ini, fin, d in tramos:
        print("    %#06x..%#06x  ->  %#06x   desplazamiento %+d"
              % (org + ini, org + fin, org + ini + d, d))
    print()

    total = distintas = 0
    avisos = []
    for tipo, ini, fin in bloques:
        if tipo != "c":
            continue
        jini, jfin = traduce(ini - org, tramos) + org, traduce(fin - org - 1, tramos) + org + 1
        if jfin - jini != fin - ini:
            avisos.append("  %#06x..%#06x: el tramo cambia de tamano (%d -> %d)"
                          % (ini, fin, fin - ini, jfin - jini))
        ia = desensambla(a, org, ini, fin)
        ib = desensambla(b, org, jini, jini + (fin - ini))
        for (da, ta), (db, tb) in zip(ia, ib):
            total += 1
            if ta == tb:
                continue                          # identicas, no hay nada que mirar
            # y si no, se comparan con las direcciones de B traducidas a A.
            # El orden importa: normalizar SIEMPRE daria falsos positivos con
            # los valores inmediatos que parecen direcciones -0x6A00 es la
            # altura de la pelota, no un destino- y aqui ya se sabe que los dos
            # textos no son iguales de partida.
            if ta != normaliza(tb, tramos, org, fin_rom):
                distintas += 1
                avisos.append("  %#06x  A: %-28s   B(%#06x): %s"
                              % (da, ta, db, tb))

    print("  %d instrucciones cotejadas, %d distintas (%.2f %%)"
          % (total, distintas, 100.0 * distintas / total if total else 0))
    if avisos:
        print("\n  las diferencias:")
        for x in avisos[:200]:
            print(x)
        if len(avisos) > 200:
            print("  ... y %d mas" % (len(avisos) - 200))
    return 0 if distintas == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
