#!/usr/bin/env python3
"""Rehace la VRAM del cartucho y la DIBUJA, sin capturar nada del emulador.

No hay ni una captura de pantalla en este repositorio: cada imagen sale de
correr en Python lo que hace el Z80, paso por paso y citando la direccion de
cada paso.

LA GEOMETRIA, QUE VA AL REVES DE LO NORMAL
------------------------------------------
Los ocho registros del VDP los escribe L_4878 leyendolos de la tabla de
0x4889, que son `02 E2 0E 7F 07 76 03 E4`:

    R0 = 0x02   SCREEN 2
    R1 = 0xE2   16K, pantalla encendida, interrupcion, SPRITES DE 16x16
    R2 = 0x0E   tabla de NOMBRES en 0x0E * 0x400 = 0x3800
    R3 = 0x7F   tabla de COLORES: el bit 7 esta a CERO, o sea base 0x0000
    R4 = 0x07   tabla de PATRONES: el bit 2 puesto, o sea base 0x2000
    R5 = 0x76   ATRIBUTOS de sprite en 0x76 * 0x80 = 0x3B00
    R6 = 0x03   PATRONES de sprite en 0x03 * 0x800 = 0x1800
    R7 = 0xE4   borde y fondo

Lo importante es R3 y R4: NO son una direccion, son base y mascara. Aqui
dejan los COLORES en 0x0000 y los PATRONES en 0x2000, justo al reves del
reparto habitual. El propio cartucho lo confirma en L_4A4B: llena de ceros
0x2000..0x207F -dieciseis tiles en blanco- y acto seguido escribe en
0x0000..0x007F los valores 0 a 15, ocho bytes cada uno. Eso solo tiene
sentido si 0x0000 es la tabla de COLOR: deja los tiles 0 a 15 como bloques
solidos de cada uno de los dieciseis colores, que es la paleta que el juego
usa despues. Como patrones no significarian nada.

Estos ocho bytes son, uno por uno, los mismos que los de Konami's Ping Pong
y los de Road Fighter.

Uso: graficos.py <rom> <org> <carpeta destino>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rle import descomprime

ORG = 0x4000
COLORES = 0x0000        # R3 = 0x7F
PATRONES = 0x2000       # R4 = 0x07
NOMBRES = 0x3800        # R2 = 0x0E
SPRITES = 0x1800        # R6 = 0x03
ATRIBUTOS = 0x3B00      # R5 = 0x76

# La paleta del TMS9918. El color 0 es TRANSPARENTE: se ve el fondo, que lo
# dice el nibble bajo de R7.
PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]
FONDO = PALETA[4]


def usa_fondo(c):
    """El color de fondo, que lo dice el nibble bajo de R7."""
    global FONDO
    FONDO = PALETA[c]


def png(pix, ancho, alto, ruta, zoom=1):
    import struct
    import zlib
    if zoom > 1:
        grande = [None] * (ancho * zoom * alto * zoom)
        for y in range(alto):
            for x in range(ancho):
                c = pix[y * ancho + x]
                for dy in range(zoom):
                    for dx in range(zoom):
                        grande[(y * zoom + dy) * ancho * zoom + x * zoom + dx] = c
        pix, ancho, alto = grande, ancho * zoom, alto * zoom
    filas = bytearray()
    for y in range(alto):
        filas.append(0)
        for x in range(ancho):
            filas += bytes(pix[y * ancho + x])

    def trozo(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos
                + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))
    open(ruta, "wb").write(
        b"\x89PNG\r\n\x1a\n"
        + trozo(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 2, 0, 0, 0))
        + trozo(b"IDAT", zlib.compress(bytes(filas), 9))
        + trozo(b"IEND", b""))


# ----------------------------------------------------------------------
# Los pasos del cartucho, cada uno con la direccion de donde sale
# ----------------------------------------------------------------------

def carga(vram, rom, destino, origen, tercios=3, espejo=False):
    """L_4698: el bloque, en los TRES tercios, sumandole 0x800 al destino.

    El `push de` / `pop de` de 0x469B devuelve DE al principio del bloque en
    cada vuelta, o sea que se descomprime el MISMO bloque en cada tercio.
    Con espejo es L_46A8, que entra por la puerta C=1.
    """
    for t in range(tercios):
        r = descomprime(rom, ORG, origen, (destino + t * 0x800) & 0x3FFF, espejo)
        if r is None:
            raise SystemExit("0x%04X no descomprime" % origen)
        _, img, tocado, _ = r
        for i in range(0x4000):
            if tocado[i]:
                vram[i] = img[i]


def carga_directa(vram, rom, origen, espejo=False):
    """L_47AF: igual, pero el destino va en los dos primeros bytes."""
    r = descomprime(rom, ORG, origen, None, espejo)
    if r is None:
        raise SystemExit("0x%04X no descomprime" % origen)
    _, img, tocado, _ = r
    for i in range(0x4000):
        if tocado[i]:
            vram[i] = img[i]


def carga_en(vram, rom, origen, destino, espejo=False):
    """L_47DE / L_47E2: una sola vez, con el destino en HL."""
    r = descomprime(rom, ORG, origen, destino & 0x3FFF, espejo)
    if r is None:
        raise SystemExit("0x%04X no descomprime" % origen)
    _, img, tocado, _ = r
    for i in range(0x4000):
        if tocado[i]:
            vram[i] = img[i]


def paletas_de_camiseta(rom):
    """Las dos tablas de traduccion de color, con las camisetas de salida.

    Son dos pasos, y saltarse el segundo da colores equivocados:

      1. 0x5A45 copia 39 bytes de 0x5A5E a 0xE050. Ahi quedan las dos paletas
         -0xE051 y 0xE056- y, entre lo demas, los dos numeros de camiseta de
         fabrica en 0xE074 y 0xE075.
      2. `aplica_los_colores_de_camiseta` (0x5C02) machaca las entradas 2, 3 y
         4 de cada paleta con el juego de tres tonos que le toque de la tabla
         de 0x5C20. Las entradas 0 y 1 -0x0C y 0x01- se quedan como estaban.

    La rutina que las usa, 0x4846, indexa con un nibble entero, o sea de 0 a
    15, asi que la tabla que ve el Z80 son los DIECISEIS bytes que siguen a
    cada direccion. Los bloques comprimidos solo gastan los cinco primeros,
    pero aqui se devuelve lo que el Z80 leeria.
    """
    ram = bytearray(0x30)                            # 0xE050..0xE07F
    p = 0x5A5E - ORG
    ram[0:39] = rom[p:p + 39]                        # 0x5A4B, el `ldir`
    for base, quien in ((0x03, 0x24), (0x08, 0x25)):  # 0xE053/0xE074, 0xE058/0xE075
        j = (0x5C20 - ORG) + ram[quien] * 3          # 0x5C11: por tres
        ram[base:base + 3] = rom[j:j + 3]            # 0x5C1D, el `ldir` de tres
    return list(ram[0x01:0x11]), list(ram[0x06:0x16])


def carga_recoloreada(vram, rom, destino, origen, paleta, tercios=1):
    """L_4707: el mismo RLE, pero cada byte pasa por la paleta de (0xE52A).

    0x4846 parte el byte en sus dos nibbles -la tinta arriba y el fondo
    abajo-, mete cada uno en la tabla y los vuelve a juntar. Por eso el MISMO
    bloque comprimido pinta las dos camisetas: solo cambia a donde apunta
    (0xE52A). Esta puerta no admite el mandato 0x80: el destino viene en HL.
    """
    for t in range(tercios):
        r = descomprime(rom, ORG, origen, (destino + t * 0x800) & 0x3FFF)
        if r is None:
            raise SystemExit("0x%04X no descomprime" % origen)
        _, img, tocado, _ = r
        for i in range(0x4000):
            if tocado[i]:
                b = img[i]
                vram[i] = (paleta[b >> 4] << 4) | paleta[b & 15]


def espeja_byte(b):
    """0x483B: los ocho bits del reves, que en SCREEN 2 refleja el dibujo."""
    r = 0
    for _ in range(8):
        r = (r << 1) | (b & 1)
        b >>= 1
    return r


def espeja_sprites(vram, origen, destino, n, ram=None):
    """0x47E6 y 0x47F2: N sprites de 16x16, escritos reflejados.

    El truco esta en el destino. Un sprite de 16x16 guarda sus 32 bytes por
    MITADES -los 16 primeros son la columna izquierda y los 16 siguientes la
    derecha-, asi que reflejarlo es escribir la izquierda donde iba la derecha
    y al reves. Eso lo hace la aritmetica de 0x4810: se suma 0x10 escribiendo
    y luego se resta 0x20, de modo que la primera vuelta cae en la mitad de
    arriba y la segunda en la de abajo. Por eso los llamadores pasan el
    destino con 0x10 ya sumado, y aqui se recibe la base limpia.
    """
    for s in range(n):
        for mitad in range(2):
            for i in range(16):
                b = ram[s * 32 + mitad * 16 + i] if ram is not None \
                    else vram[(origen + s * 32 + mitad * 16 + i) & 0x3FFF]
                d = destino + s * 32 + (0x10 if mitad == 0 else 0x00) + i
                vram[d & 0x3FFF] = espeja_byte(b)


def llena(vram, destino, n, valor, tercios=3):
    """L_4687: FILVRM el mismo valor en los tres tercios."""
    for t in range(tercios):
        d = (destino + t * 0x800) & 0x3FFF
        for i in range(n):
            vram[(d + i) & 0x3FFF] = valor


def llena_plano(vram, destino, n, valor):
    """L_4684: FILVRM de una sola vez, sin repetir por tercios."""
    for i in range(n):
        vram[(destino + i) & 0x3FFF] = valor


def guion(vram, rom, origen, mascara=0xFF):
    """L_46CE: el interprete de ROTULOS, que escribe en la tabla de NOMBRES.

    No pinta formas: dice QUE TILE va en cada casilla. El guion empieza por
    una palabra con el destino, y luego:

        0xFF   cierra
        0xFE   los dos bytes siguientes son un destino nuevo
        resto  se escribe en la casilla, pasado por `and c`

    Con la mascara a 0x00 -que es entrar por L_46E5- el mismo guion BORRA el
    rotulo en vez de pintarlo, porque escribe ceros en las mismas casillas.

    Devuelve la direccion en que quedo DE, o sea justo detras del 0xFF de
    cierre. El cartucho cuenta con eso: 0x4CEF y 0x4CF2 son dos `call`
    seguidos, y el segundo pinta el guion que va PEGADO al primero sin volver
    a cargar DE.
    """
    p = origen - ORG
    hl = rom[p] | (rom[p + 1] << 8)
    p += 2
    while True:
        a = rom[p]
        p += 1
        if a == 0xFF:
            return p + ORG
        if a == 0xFE:
            hl = rom[p] | (rom[p + 1] << 8)
            p += 2
            continue
        vram[hl & 0x3FFF] = a & mascara
        hl += 1


def descomprime_a_la_ram(rom, origen):
    """L_46E9: el mismo RLE, pero dejando el resultado en la RAM de 0xE600.

    Es la puerta que usan el mapa del campo y los sprites que hay que retocar
    antes de subirlos: la rutina no sabe de VRAM, solo escribe bytes
    seguidos. Aqui devuelve la tira tal cual.
    """
    p = origen - ORG
    out = bytearray()
    while True:
        ctrl = rom[p]
        p += 1
        if ctrl == 0x00:
            return out
        if ctrl & 0x80:
            n = ctrl & 0x7F
            out += rom[p:p + n]
            p += n
        else:
            out += bytes([rom[p]]) * ctrl
            p += 1


def vram_limpia():
    return bytearray(0x4000)


# ----------------------------------------------------------------------
# Las escenas
# ----------------------------------------------------------------------

def monta_la_paleta_y_la_fuente(v, rom):
    """L_4A36, que son dos cosas: la paleta de bloques y la fuente.

    L_4A4B deja los tiles 0 a 15 en blanco (0x2000, 0x80 bytes a cero) y les
    pone de color 0, 1, 2 ... 15, ocho bytes cada uno, en 0x0000. O sea
    dieciseis bloques solidos, uno por color.

    Luego vienen los 352 bytes de patrones de 0x4A6C en 0x2080 y su color, los
    otros 352 de 0x4BB8 en 0x0080: son 44 tiles, la fuente del juego.
    """
    llena(v, 0x2000, 0x80, 0x00)                 # 0x4A4B
    for i in range(0x10):                        # 0x4A5D, dieciseis vueltas
        llena(v, 0x0000 + i * 8, 8, i)
    carga(v, rom, 0x2080, 0x4A6C)                # 0x4A3F
    carga(v, rom, 0x0080, 0x4BB8)                # 0x4A48


def escena_titulo(rom):
    """L_4CB0: la pantalla del titulo, paso por paso.

        0x4CB0  ld b,0e0h / pone_el_color_del_borde   fondo NEGRO
        0x4CB5  L_4668, que limpia la tabla de nombres
        0x4CB8  L_4A36, la paleta y la fuente
        0x4CBB  los patrones del rotulo, 0x4D1C -> 0x2200
        0x4CC4  y su color, 0x4E34 -> 0x0200
        0x4CCD  el guion de 0x4E41, que pone el logotipo de la casa
        0x4CD3  y el rotulo: cinco filas de catorce tiles CONSECUTIVOS desde
                el 0x40, empezando en 0x3889 y con paso de fila 0x20
    """
    usa_fondo(0)                                 # 0x4CB0: R7 = 0xE0
    v = vram_limpia()
    llena_plano(v, 0x3800, 0x300, 0x00)          # 0x4668
    monta_la_paleta_y_la_fuente(v, rom)          # 0x4CB8
    carga(v, rom, 0x2200, 0x4D1C)                # 0x4CC1
    carga(v, rom, 0x0200, 0x4E34)                # 0x4CCA
    guion(v, rom, 0x4E41)                        # 0x4CD0
    hl, a = 0x3889, 0x40                         # 0x4CD3
    for _ in range(5):                           # 0x4CDB: C = 5 filas
        p = hl
        for _ in range(14):                      # 0x4CDD: B = 14 columnas
            v[p & 0x3FFF] = a
            p += 1
            a = (a + 1) & 0xFF
        hl += 0x20                               # 0x4CD6: DE = 0x20
    # 0x4CEC y 0x4CEF: "(c)KONAMI 1985", "PLAY SELECT" y "1PLAYER"; y como el
    # interprete deja DE detras del 0xFF, el segundo `call` de 0x4CF2 sigue
    # con el guion que va pegado, el del "2PLAYERS"
    sigue = guion(v, rom, 0x494A)
    guion(v, rom, sigue)
    return v


def escena_campo(rom):
    """Las diez tandas de 0x4279 y las cuatro de 0x5752, en su orden.

    Cada `call` de aqui abajo es uno de los de `carga_los_graficos_del_campo`
    (0x4279..0x4294) o de `monta_el_partido` (0x5752..0x5766), y lleva al
    lado la direccion de la rutina que hace lo mismo en el Z80. No se dibuja
    ni un pixel a mano: se corre el descompresor del cartucho.
    """
    usa_fondo(0)                                     # 0x4242: R7 = 0x00
    v = vram_limpia()
    p1, p2 = paletas_de_camiseta(rom)

    # 0x424B, monta_la_pantalla_de_datos: la fuente y el marcador de arriba
    monta_la_paleta_y_la_fuente(v, rom)              # 0x4A36
    carga(v, rom, 0x2230, 0x5E69)                    # 0x5E32
    carga(v, rom, 0x0230, 0x5EB2)
    carga(v, rom, 0x2500, 0x4A6C)                    # la fuente, otra vez
    llena(v, 0x0500, 0x180, 0x4F)                    # y en azul sobre blanco
    carga_directa(v, rom, 0x5F08)                    # siete sprites
    espeja_sprites(v, 0x1800, 0x18E0, 7)             # y otros siete, del reves

    carga_directa(v, rom, 0x6D48)                    # L_6D18, tanda 1
    carga_directa(v, rom, 0x6D75)
    carga_en(v, rom, 0x6D65, 0x2250, espejo=True)
    carga_en(v, rom, 0x6D77, 0x2288, espejo=True)
    carga_directa(v, rom, 0x6D8D)
    carga_directa(v, rom, 0x6DE0)
    carga_directa(v, rom, 0x6DEA)

    carga_directa(v, rom, 0x6E25)                    # L_6E16, tanda 2
    carga_en(v, rom, 0x6E27, 0x28E0, espejo=True)

    carga_directa(v, rom, 0x6EC8)                    # L_6EB9, tanda 3
    carga_en(v, rom, 0x6ECE, 0x30A8, espejo=True)

    carga(v, rom, 0x2808, 0x6F19, tercios=2)         # L_6F0E, tanda 4

    carga(v, rom, 0x2998, 0x7087, tercios=2)         # L_7071, tanda 5
    carga(v, rom, 0x2A58, 0x7087, tercios=2, espejo=True)

    carga_directa(v, rom, 0x738A)                    # L_731F, tanda 6
    carga_directa(v, rom, 0x7396)
    carga_directa(v, rom, 0x736D)
    carga_en(v, rom, 0x738C, 0x0250)
    carga_en(v, rom, 0x7398, 0x0288)
    carga_directa(v, rom, 0x739B)
    carga_directa(v, rom, 0x73CC)
    carga_recoloreada(v, rom, 0x0228, 0x7393, p1)    # 0x7352: la camiseta 1
    carga_recoloreada(v, rom, 0x02E8, 0x7393, p2)    # 0x7361: y la 2

    carga_directa(v, rom, 0x73F2)                    # L_73E3, tanda 7
    carga_en(v, rom, 0x73F4, 0x08E0)

    carga_directa(v, rom, 0x7412)                    # L_7403, tanda 8
    carga_en(v, rom, 0x7416, 0x10A8)

    carga(v, rom, 0x0808, 0x7424, tercios=2)         # L_7419, tanda 9

    carga_recoloreada(v, rom, 0x0998, 0x74FE, p1, 2)  # L_74DC, tanda 10
    carga_recoloreada(v, rom, 0x0A58, 0x74FE, p2, 2)

    carga(v, rom, 0x2320, 0x6F55)                    # L_6F31, las fichas
    carga(v, rom, 0x2590, 0x6F55)
    carga(v, rom, 0x2458, 0x6F55, espejo=True)
    carga(v, rom, 0x26C8, 0x6F55, espejo=True)

    carga_recoloreada(v, rom, 0x0320, 0x745D, p1, 3)  # L_742D, su color
    carga_recoloreada(v, rom, 0x0458, 0x745D, p1, 3)
    carga_recoloreada(v, rom, 0x0590, 0x745D, p2, 3)
    carga_recoloreada(v, rom, 0x06C8, 0x745D, p2, 3)

    # L_76BC: los sprites del partido no van derechos a la VRAM
    banco = descomprime_a_la_ram(rom, 0x76F0)        # 0x76BF, a 0xE600
    for i in range(0x2E0):                           # 0x76C8, LDIRVM a 0x1800
        v[0x1800 + i] = banco[i]
    espeja_sprites(v, None, 0x1AE0, 0x17, ram=banco)  # 0x76D6, otros 23
    carga_directa(v, rom, 0x78F6)                    # 0x76DC
    return v


def mapa_del_campo(rom):
    """L_8538: los 1840 bytes del mapa, descomprimidos a 0xE600.

    Son 80 columnas por 23 filas, y la pantalla solo ensena 32 de ancho: lo
    fija la aritmetica de `vuelca_el_campo` (0x5DD6), que saca 32 casillas
    con `outi` y salta 48 antes de la fila siguiente.
    """
    m = descomprime_a_la_ram(rom, 0x853E)
    if len(m) != 80 * 23:
        raise SystemExit("el mapa mide %d bytes, no %d" % (len(m), 80 * 23))
    return m


def campo_entero(rom, ruta):
    """El campo de 80x23 casillas, dibujado de una pieza.

    La ventana de la pantalla arranca en 0x3820, o sea la FILA 1 de la tabla
    de nombres -la 0 se la queda el marcador-, asi que la fila N del mapa se
    pinta con las tablas del tercio (N+1)//8, que es el que le tocaria en
    pantalla.
    """
    v = escena_campo(rom)
    m = mapa_del_campo(rom)
    ancho, alto = 80 * 8, 23 * 8
    pix = [FONDO] * (ancho * alto)
    for f in range(23):
        for c in range(80):
            tercio = ((f + 1) // 8) * 0x800
            tile = m[f * 80 + c]
            for y in range(8):
                forma = v[PATRONES + tercio + tile * 8 + y]
                color = v[COLORES + tercio + tile * 8 + y]
                tinta = PALETA[color >> 4] if (color >> 4) else FONDO
                papel = PALETA[color & 15] if (color & 15) else FONDO
                for x in range(8):
                    pix[(f * 8 + y) * ancho + c * 8 + x] = \
                        tinta if forma & (0x80 >> x) else papel
    png(pix, ancho, alto, ruta)


def hojas_del_arbol_de_parches(rom, base):
    """Las poses de un bando, sacadas del arbol de dos niveles de 0x887D.

    El arbol lo recorre `estampa_un_parche`: (ix+0x0C) elige el grupo en la
    tabla de nueve palabras que hay en `base`, y (ix+0x0D) la pose dentro del
    grupo. Cada hoja son once bytes: dos de correccion, que 0x889D se salta, y
    las NUEVE casillas del parche de 3x3.

    Cuantas entradas tiene cada grupo no esta escrito en ninguna parte: lo
    dice el encaje, porque las hojas van pegadas detras de su propia subtabla.
    Asi que la primera palabra de un grupo marca donde acaba ese grupo.
    """
    def w(a):
        return rom[a - ORG] | (rom[a - ORG + 1] << 8)
    grupos = []
    for i in range(9):                               # 0x8889: nueve palabras
        g = w(base + i * 2)
        if g not in grupos:
            grupos.append(g)
    hojas = []
    for g in grupos:
        for i in range((w(g) - g) // 2):
            h = w(g + i * 2)
            if h not in hojas:
                hojas.append(h)
    return sorted(hojas)


def lamina_de_fichas(rom, ruta, cols=13):
    """Las poses de los DOS bandos, montadas casilla a casilla."""
    v = escena_campo(rom)
    lotes = [hojas_del_arbol_de_parches(rom, 0x7D14),   # 0x8824, un bando
             hojas_del_arbol_de_parches(rom, 0x7EA4)]   # 0x8829, el otro
    filas = sum((len(l) + cols - 1) // cols for l in lotes)
    ancho, alto = cols * 24, filas * 24
    pix = [FONDO] * (ancho * alto)

    def casilla(t, px, py):
        for y in range(8):
            forma = v[PATRONES + 0x800 + t * 8 + y]
            color = v[COLORES + 0x800 + t * 8 + y]
            tinta = PALETA[color >> 4] if (color >> 4) else FONDO
            papel = PALETA[color & 15] if (color & 15) else FONDO
            for x in range(8):
                pix[(py + y) * ancho + px + x] = \
                    tinta if forma & (0x80 >> x) else papel

    # el fondo es el cesped de verdad: el tile 0x01, el mismo con el que el
    # mapa llena el campo
    for py in range(0, alto, 8):
        for px in range(0, ancho, 8):
            casilla(0x01, px, py)
    f0 = 0
    for lote in lotes:
        for i, h in enumerate(lote):
            f, c = f0 + i // cols, i % cols
            for k in range(9):                       # las 3x3 casillas
                casilla(rom[h - ORG + 2 + k],
                        c * 24 + (k % 3) * 8, f * 24 + (k // 3) * 8)
        f0 += (len(lote) + cols - 1) // cols
    png(pix, ancho, alto, ruta, 2)


def escena_fuente(rom):
    """Solo la fuente, con sus 44 tiles puestos en fila para poder MIRARLOS."""
    usa_fondo(0)
    v = vram_limpia()
    llena_plano(v, 0x3800, 0x300, 0x00)
    monta_la_paleta_y_la_fuente(v, rom)
    # los 44 tiles van del 0x10 al 0x3B, en filas de 16
    for i in range(44):
        v[(0x3800 + (2 + i // 16) * 32 + 4 + i % 16) & 0x3FFF] = 0x10 + i
    return v


# ----------------------------------------------------------------------
# El pintado
# ----------------------------------------------------------------------

def pinta_celda(vram, fila, col, tile, pix, ancho):
    """Una celda de 8x8, con las tablas del tercio que le toca.

    En SCREEN 2 la pantalla son tres tercios independientes: la fila decide
    que copia de las tablas se usa, y por eso el mismo indice de patron puede
    dar dibujos distintos arriba y abajo.
    """
    tercio = (fila // 8) * 0x800
    for y in range(8):
        forma = vram[PATRONES + tercio + tile * 8 + y]
        color = vram[COLORES + tercio + tile * 8 + y]
        tinta = PALETA[color >> 4] if (color >> 4) else FONDO
        papel = PALETA[color & 15] if (color & 15) else FONDO
        for x in range(8):
            pix[(fila * 8 + y) * ancho + col * 8 + x] = \
                tinta if forma & (0x80 >> x) else papel


def pinta_sprites(vram, pix, ancho=256):
    """Los sprites de 16x16 de la tabla de atributos, encima del decorado.

    Cuatro bytes por sprite -Y, X, patron y color-, y un 0xD0 en la Y corta
    la lista. Con sprites de 16x16 el numero de patron va en saltos de
    cuatro, y sus 32 bytes se guardan por MITADES: los 16 primeros son la
    columna izquierda y los 16 siguientes la derecha.
    """
    for s in range(32):
        y, x, patron, color = vram[ATRIBUTOS + s * 4:ATRIBUTOS + s * 4 + 4]
        if y == 0xD0:
            return
        if y == 0xE0 or not (color & 0x0F):
            continue                     # escondido, o de color transparente
        y = (y + 1) & 0xFF               # el VDP dibuja una linea mas abajo
        if color & 0x80:                 # el bit 7 corre el sprite 32 a la izquierda
            x -= 32
        base = SPRITES + (patron & 0xFC) * 8
        tinta = PALETA[color & 0x0F]
        for mitad in range(2):
            for dy in range(16):
                b = vram[(base + mitad * 16 + dy) & 0x3FFF]
                for dx in range(8):
                    if not (b & (0x80 >> dx)):
                        continue
                    px, py = x + mitad * 8 + dx, y + dy
                    if 0 <= px < ancho and 0 <= py < 192:
                        pix[py * ancho + px] = tinta


def pantalla(vram, ruta):
    pix = [FONDO] * (256 * 192)
    for f in range(24):
        for c in range(32):
            pinta_celda(vram, f, c, vram[NOMBRES + f * 32 + c], pix, 256)
    pinta_sprites(vram, pix)
    png(pix, 256, 192, ruta)


def recorte(vram, ruta, fila, col, filas, cols, zoom=2):
    """Un trozo de la pantalla montada, sin dibujar nada a mano."""
    pix = [FONDO] * (256 * 192)
    for f in range(24):
        for c in range(32):
            pinta_celda(vram, f, c, vram[NOMBRES + f * 32 + c], pix, 256)
    pinta_sprites(vram, pix)
    w, h = cols * 8, filas * 8
    trozo = [pix[(fila * 8 + y) * 256 + col * 8 + x]
             for y in range(h) for x in range(w)]
    png(trozo, w, h, ruta, zoom)


def main():
    rom = open(sys.argv[1], "rb").read()
    global ORG
    ORG = int(sys.argv[2], 0)
    salida = sys.argv[3]
    os.makedirs(salida, exist_ok=True)

    v = escena_titulo(rom)
    pantalla(v, os.path.join(salida, "titulo.png"))
    # El rotulo son DOS cosas de sitios distintos, y las dos salen del mismo
    # montaje, sin tocar nada a mano:
    #   el "KONAMI'S" lo pone el guion de 0x4E41 en 0x3869, que es la fila 3
    #   (0x3869 = 0x3800 + 3*32 + 9), columna 9, y le asoman por arriba dos
    #   tiles mas -el 0x88 y el 0x89- en la fila 2;
    #   el "SOCCER" son las cinco filas de catorce tiles consecutivos que
    #   estampa 0x4CD3 desde 0x3889, o sea la fila 4 de la misma columna.
    # Siete filas desde la 2 los cogen los dos, con una columna de margen.
    recorte(v, os.path.join(salida, "rotulo.png"), 2, 8, 7, 16)
    print("titulo.png y rotulo.png")

    v = escena_fuente(rom)
    recorte(v, os.path.join(salida, "fuente.png"), 2, 4, 3, 16)
    print("fuente.png")

    campo_entero(rom, os.path.join(salida, "campo.png"))
    print("campo.png")

    lamina_de_fichas(rom, os.path.join(salida, "fichas.png"))
    print("fichas.png")


if __name__ == "__main__":
    main()
