#!/usr/bin/env python3
"""El descompresor del cartucho, rehecho en Python para MEDIR y DIBUJAR.

La rutina es L_47B7, y escribe DIRECTAMENTE en la VRAM: no deja el resultado
en memoria, lo saca por el puerto de datos del VDP. Traducida instruccion a
instruccion, con DE apuntando al flujo y HL a la direccion de VRAM:

    L_47B7  call L_4674        fija la direccion de escritura (SETWRT con HL)
    L_47BA  ld a,(de)
            and a / ret z      un 0x00 TERMINA el bloque
            inc de
            ld b,a             B se queda con el byte ENTERO
            and 07fh / cp b    si coinciden, el bit 7 estaba a cero
            jr z,L_47D3        bit 7 = 0 -> repeticion
            and a / jr z,L_47AF    el byte 0x80 -> direccion nueva
            ld b,a
    L_47C8  call L_4836 / out (c),a / djnz     literal de B bytes
            jr L_47BA
    L_47D3  call L_4836
    L_47D6  out (c),a / djnz                   el byte, B veces
            jr L_47BA

    L_47AF  ex de,hl / ld e,(hl) / inc hl / ld d,(hl) / ex de,hl / inc de
            call L_4674        HL = la palabra leida, y se fija ahi la escritura

O sea, un mandato por byte:

    0x00           cierra el bloque
    0x01..0x7F     el byte que sigue, repetido esa cuenta
    0x80           los dos bytes que siguen son una direccion de VRAM NUEVA,
                   y a partir de ahi se escribe alli
    0x81..0xFF     copia tal cual los (mandato & 0x7F) bytes que siguen

Hasta aqui es, byte por byte, el MISMO formato que el de Konami's Ping Pong.
Lo que este cartucho anade es el ESPEJO, y no esta en el bucle sino en la
lectura de cada byte:

    L_4836  ld a,(de) / inc de / bit 0,c / ret z
    L_483B  push bc / ld c,a / ld b,008h
    L_483F  rr c / rla / djnz L_483F
            pop bc / ret

o sea que si el bit 0 de C esta puesto, cada byte sale con sus ocho bits DEL
REVES, que en un patron de SCREEN 2 es reflejarlo horizontalmente. Hay dos
puertas justo por eso: L_47DE entra con C=0 y L_47E2 con C=1, y las dos caen
en el mismo L_47B7. El mismo bloque comprimido sirve para las dos mitades de
un dibujo simetrico.

El espejo se aplica a los bytes de DATOS -tanto al literal como al valor que
se repite-, nunca a los mandatos ni a la direccion del 0x80: esos se leen con
`ld a,(de)` a pelo, antes de L_4836.

Las direcciones van con el BIT DE ESCRITURA ya puesto: el cartucho pide 0x6200
donde la VRAM tiene 0x2200. No es un error suyo -SETWRT (0x0053) hace
`and 03fh` sobre H antes de nada, asi que los dos bits de arriba se tiran-, de
modo que aqui hay que enmascarar igual con 0x3FFF o los bloques caen fuera.

Ejecutarlo es la unica forma honesta de saber donde acaba cada bloque: el
tamano no esta escrito en ninguna parte, lo marca el propio 0x00 final.

Hay DOS puertas. Por L_47B7 la direccion de VRAM llega en HL, puesta por quien
llama. Por L_47AF la direccion va DENTRO del bloque, en sus dos primeros
bytes. Aqui, `auto` para esa.

Uso: rle.py <rom> <org> [--espejo] <dir vram|auto> <dir dato> [<dir dato> ...]
     rle.py <rom> <org> [--espejo] --tramos <dir vram|auto> <dir dato>
"""
import sys

VRAM = 0x4000       # tamano de la VRAM de un MSX1


def refleja(v):
    """Los ocho bits del reves, que es lo que hace L_483B."""
    r = 0
    for _ in range(8):
        r = (r << 1) | (v & 1)
        v >>= 1
    return r


def descomprime(rom, org, inicio, vram_ini, espejo=False):
    """Ejecuta el bloque. Devuelve (fin, vram, tocado, tramos) o None.

    `vram` es una imagen de 16 KB con lo escrito, `tocado` marca que bytes se
    escribieron y `tramos` la lista de (direccion de vram, cuantos bytes) en
    el orden en que se escribieron.

    Con vram_ini a None se entra por L_47AF: los dos primeros bytes del bloque
    son la direccion de destino.

    Con espejo, cada byte de DATO sale reflejado, que es entrar por L_47E2
    (C=1) en vez de por L_47DE (C=0).
    """
    p = inicio - org
    if p < 0 or p >= len(rom):
        return None
    if vram_ini is None:                      # puerta L_47AF
        if p + 1 >= len(rom):
            return None
        vram_ini = rom[p] | (rom[p + 1] << 8)
        p += 2
    vram = bytearray(VRAM)
    tocado = bytearray(VRAM)
    tramos = []
    dst = vram_ini & 0x3FFF
    ini_tramo = dst
    escritos = 0

    def cierra_tramo():
        if escritos:
            tramos.append((ini_tramo, escritos))

    while True:
        if p >= len(rom):
            return None                       # se sale: no era un bloque
        ctrl = rom[p]
        p += 1
        if ctrl == 0x00:
            cierra_tramo()
            return inicio + (p - (inicio - org)), vram, tocado, tramos
        if ctrl == 0x80:
            if p + 1 >= len(rom):
                return None
            cierra_tramo()
            dst = (rom[p] | (rom[p + 1] << 8)) & 0x3FFF
            p += 2
            ini_tramo, escritos = dst, 0
            continue
        if ctrl & 0x80:                       # literal
            n = ctrl & 0x7F
            if p + n > len(rom):
                return None
            for i in range(n):
                v = rom[p + i]
                vram[dst & 0x3FFF] = refleja(v) if espejo else v
                tocado[dst & 0x3FFF] = 1
                dst += 1
            p += n
            escritos += n
        else:                                 # repeticion
            if p >= len(rom):
                return None
            v = rom[p]
            p += 1
            if espejo:
                v = refleja(v)
            for _ in range(ctrl):
                vram[dst & 0x3FFF] = v
                tocado[dst & 0x3FFF] = 1
                dst += 1
            escritos += ctrl


def main():
    rom = open(sys.argv[1], 'rb').read()
    org = int(sys.argv[2], 0)
    args = sys.argv[3:]
    espejo = False
    if args and args[0] == '--espejo':
        espejo = True
        args = args[1:]
    detalle = False
    if args and args[0] == '--tramos':
        detalle = True
        args = args[1:]
    vram_ini = None if args[0] == 'auto' else int(args[0], 0)
    for a in args[1:]:
        d = int(a, 0)
        r = descomprime(rom, org, d, vram_ini, espejo)
        if r is None:
            print('0x%04X  NO cierra dentro de la ROM' % d)
            continue
        fin, vram, tocado, tramos = r
        n = sum(tocado)
        print('0x%04X..0x%04X  %5d bytes comprimidos -> %5d de VRAM, %d tramos'
              % (d, fin - 1, fin - d, n, len(tramos)))
        if detalle:
            for v, c in tramos:
                print('      vram 0x%04X  %5d bytes' % (v, c))


if __name__ == '__main__':
    main()
