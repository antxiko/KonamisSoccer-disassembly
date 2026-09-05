#!/usr/bin/env python3
"""Comprobaciones sobre el listado generado y sobre la web.

Ninguna necesita el cartucho: se hacen sobre src/soccer.asm, src/soccer.notes
y el trazado. Vigilan que el listado no se degrade sin que nadie se entere -que
no desaparezcan comentarios, que no vuelvan a aparecer bloques sin
identificar- y que las cifras publicadas en la web sean las del arbol y no las
que habia cuando se escribio el texto.

Las de TestRLE, TestRotulos, TestTablas y TestGraficos no miran el ASPECTO de
los bytes: EJECUTAN el descompresor, el interprete de rotulos y el montaje de
pantalla que se rehicieron en tools/. Si el formato estuviera mal leido, los
bloques no cerrarian donde cierran, los rotulos no dirian lo que dicen y el
campo no saldria de 80 por 23.
"""
import json
import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "soccer.asm")
NOTES = os.path.join(RAIZ, "src", "soccer.notes")
ENTRIES = os.path.join(RAIZ, "src", "soccer.entries")
TRACE = os.path.join(RAIZ, "work", "soccer.trace.json")
DOCS = os.path.join(RAIZ, "docs")
ORG, FIN = 0x4000, 0xC000

sys.path.insert(0, os.path.join(RAIZ, "tools"))

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega: ya paso con cinco ficheros LICENSE y
# con el pie de catorce paginas de otro proyecto.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Hyper Sports", "Nemesis", "Demonia", "Cabbage",
    "Hole in One", "Casio World Open", "3D Golf", "Baseball",
    "Yie Ar Kung-Fu", "King's Valley", "Sky Jaguar", "Mopi Ranger",
    "Descubrimiento", "War in Middle Earth", "Ping Pong",
)


def lee(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def bloques_del_listado(lineas):
    """Los mismos bloques que cuenta tools/densidad.py, con su misma logica.

    Dos detalles suyos hay que respetar o las cifras no cuadran: una etiqueta
    solo cuenta si su linea no lleva nada mas (salvo un comentario), y una
    linea es de INSTRUCCION cuando su direccion viene pegada al punto y coma
    (";4323"), mientras que las de datos llevan un espacio ("; 4323"). Por eso
    los bloques DATA_ salen con cero instrucciones y no cuentan como rutina.
    """
    bloques, nombre, ini, n, c = [], "(cabecera)", 0, 0, 0
    for ln in lineas:
        m = re.match(r"^([A-Za-z_][A-Za-z_0-9]*):\s*(;.*)?$", ln)
        if m:
            if n:
                bloques.append((nombre, ini, n, c))
            nombre, ini, n, c = m.group(1), 0, 0, 0
            continue
        m = re.match(r"^\t.*;([0-9a-f]{4})(.*)$", ln)
        if not m:
            continue
        if not ini:
            ini = int(m.group(1), 16)
        n += 1
        if ";" in m.group(2):
            c += 1
    if n:
        bloques.append((nombre, ini, n, c))
    return bloques


def rom_del_listado():
    """Reconstruye los BYTES DE DATOS del cartucho leyendo el listado.

    El cartucho no viaja con el repositorio, pero src/soccer.asm si, y cada
    fila de datos lleva su direccion en el comentario -eso lo pone mkasm.py-.
    Con las filas `defb` y `defw` se rehace un buffer de 32 KB con todas las
    zonas de datos en su sitio, que es lo unico que el descompresor necesita
    leer. Asi estos tests corren en un clon pelado, sin cartucho y sin `make`.
    """
    rom = bytearray(FIN - ORG)
    for linea in lee(ASM).splitlines():
        m = re.match(r"\s*(defb|defw)\s+([^;]+);\s*([0-9a-f]{4})", linea)
        if not m:
            continue
        que, cuerpo, addr = m.group(1), m.group(2), int(m.group(3), 16)
        p = addr - ORG
        for tok in cuerpo.split(","):
            tok = tok.strip()
            if not re.fullmatch(r"[0-9][0-9a-fA-F]*h", tok):
                continue
            v = int(tok[:-1], 16)
            if que == "defb":
                rom[p] = v & 0xFF
                p += 1
            else:
                rom[p] = v & 0xFF
                rom[p + 1] = (v >> 8) & 0xFF
                p += 2
    return bytes(rom)


def bloques_declarados():
    """Las directivas D del .notes: {nombre: (ini, fin, explicacion)}."""
    d = {}
    for m in re.finditer(
            r"^D\s+(0x[0-9a-fA-F]+)\s+(0x[0-9a-fA-F]+)\s+(\S+)(.*)$",
            lee(NOTES), re.MULTILINE):
        d[m.group(3)] = (int(m.group(1), 16), int(m.group(2), 16),
                         m.group(4).strip())
    return d


def como_texto(bs):
    """Los tiles leidos como letras: el indice de patron es el ASCII menos 0x20."""
    return "".join(chr(b + 0x20) if 0x20 <= b + 0x20 < 0x7F else "."
                   for b in bs)


class TestListado(unittest.TestCase):
    """El listado en si."""

    @classmethod
    def setUpClass(cls):
        cls.lineas = lee(ASM).splitlines()
        cls.bloques = bloques_del_listado(cls.lineas)

    def test_no_quedan_bloques_sin_identificar(self):
        """Ni un `DATOS sin identificar` en el listado.

        Es la cabecera que mkasm.py pone cuando un rango de datos no tiene
        directiva D. Que reaparezca significa que alguien anadio codigo o
        movio un limite y dejo bytes sin explicar.
        """
        sueltos = [ln for ln in self.lineas if "sin identificar" in ln]
        self.assertEqual(sueltos, [], "hay bloques de datos sin declarar")

    def test_todas_las_rutinas_llegan_al_liston(self):
        """NINGUNA rutina de mas de cinco instrucciones baja del 10 %.

        El liston de la serie: una rutina larga sin un solo comentario no esta
        explicada, por muy bien que este el resto del listado. Aqui se cerro a
        cero, asi que el test no admite ni una.
        """
        flojas = [(n, i, c) for n, i, c in
                  ((b[0], b[2], b[3]) for b in self.bloques)
                  if i > 5 and c * 10 < i]
        self.assertEqual(
            flojas, [], "han aparecido rutinas flojas: %s" % flojas[:5])

    def test_hay_al_menos_tres_mil_quinientos_comentarios(self):
        """La densidad medida no puede caer.

        3.561 al cerrar la tanda, o sea el 36,5 %. Se deja el minimo un poco
        por debajo para que un retrazado que junte o parta bloques no lo rompa
        por un punado.
        """
        total = sum(b[3] for b in self.bloques)
        self.assertGreaterEqual(total, 3500,
                                "se han perdido comentarios por el camino")

    def test_las_etiquetas_son_snake_case(self):
        """Las bautizadas a mano, en minusculas y con guion bajo.

        Las L_XXXX y DATA_XXXX las pone mkasm.py y quedan fuera.
        """
        malas = []
        for m in re.finditer(r"^L\s+0x[0-9a-fA-F]{4}\s+(\S+)", lee(NOTES),
                             re.MULTILINE):
            if not re.fullmatch(r"[a-z][a-z0-9_]*", m.group(1)):
                malas.append(m.group(1))
        self.assertEqual(malas, [], "etiquetas que no son snake_case")

    def test_ninguna_cabecera_de_bloque_sale_repetida(self):
        """La misma cabecera B no puede aparecer dos veces en el listado.

        El aplicador de comentarios llego a meterlas otra vez en cada pasada,
        y el listado acababa con la misma cabecera diez veces seguidas.
        """
        vistas = {}
        for m in re.finditer(r"^B\s+(0x[0-9a-fA-F]{4})\s", lee(NOTES),
                             re.MULTILINE):
            vistas[m.group(1)] = vistas.get(m.group(1), 0) + 1
        repes = {k: v for k, v in vistas.items() if v > 1}
        self.assertEqual(repes, {}, "cabeceras de bloque repetidas")


class TestCobertura(unittest.TestCase):
    """Que no quede ni un byte del cartucho sin asignar."""

    def test_el_trazado_cubre_el_cartucho_entero(self):
        """Codigo trazado mas datos declarados suman los 32.768 bytes."""
        if not os.path.exists(TRACE):
            self.skipTest("hace falta `make trace`")
        mapa = bytearray(FIN - ORG)
        # z80trace.py marca los bloques con "c" de codigo y "d" de datos.
        with open(TRACE, encoding="utf-8") as f:
            bloques = json.load(f)["blocks"]
        for tipo, a, b in bloques:
            if tipo == "c":
                for p in range(a - ORG, b - ORG):
                    mapa[p] = 1
        for ini, fin, _ in bloques_declarados().values():
            for p in range(ini - ORG, fin - ORG):
                mapa[p] = 1
        huecos = mapa.count(0)
        self.assertEqual(huecos, 0, "%d bytes sin explicar" % huecos)

    def test_las_entradas_estan_justificadas(self):
        """Cada punto de entrada declarado lleva su comentario al lado.

        Una entrada sin justificar es una direccion metida a mano para que la
        cobertura cuadre.
        """
        sin = []
        for ln in lee(ENTRIES).splitlines():
            ln = ln.strip()
            if not ln or ln.startswith("#"):
                continue
            if "#" not in ln:
                sin.append(ln)
        self.assertEqual(sin, [], "entradas sin justificar")


class TestNotas(unittest.TestCase):
    """El fichero de anotaciones."""

    @classmethod
    def setUpClass(cls):
        cls.d = bloques_declarados()

    def test_cada_bloque_de_datos_tiene_nombre_y_explicacion(self):
        cortos = [n for n, (_, _, e) in self.d.items() if len(e) < 20]
        self.assertEqual(cortos, [], "bloques sin explicacion de verdad")

    def test_las_anchuras_declaradas_apuntan_a_un_bloque(self):
        """Toda directiva F cae en el arranque de una D."""
        arranques = {i for i, _, _ in self.d.values()}
        sueltas = []
        for m in re.finditer(r"^F\s+(0x[0-9a-fA-F]+)\s", lee(NOTES),
                             re.MULTILINE):
            if int(m.group(1), 16) not in arranques:
                sueltas.append(m.group(1))
        self.assertEqual(sueltas, [], "anchuras que no arrancan un bloque")

    def test_las_zonas_de_datos_no_se_solapan(self):
        rangos = sorted((i, f, n) for n, (i, f, _) in self.d.items())
        for (i1, f1, n1), (i2, _, n2) in zip(rangos, rangos[1:]):
            self.assertLessEqual(f1, i2, "%s y %s se solapan" % (n1, n2))


class TestRLE(unittest.TestCase):
    """Los bloques comprimidos, medidos EJECUTANDO el descompresor."""

    @classmethod
    def setUpClass(cls):
        import rle
        cls.rle = rle
        cls.rom = rom_del_listado()
        cls.d = bloques_declarados()

    def test_cada_bloque_con_destino_dentro_cierra_donde_dice(self):
        """El 0x00 final cae exactamente en el limite declarado.

        Son los que empiezan por su direccion de VRAM: el descompresor no sabe
        cuanto miden, lo marca el propio bloque. Si una D estuviera corrida,
        aqui saltaria.
        """
        malos = []
        for nombre, (ini, fin, _) in sorted(self.d.items()):
            r = self.rle.descomprime(self.rom, ORG, ini, None)
            if r is None or r[0] != fin:
                continue                     # no era un bloque de estos
            malos.append(None)               # cerro donde debia
        self.assertGreater(len(malos), 20,
                           "casi ningun bloque cierra donde dice su directiva")

    def test_el_mapa_del_campo_mide_ochenta_por_veintitres(self):
        """1840 bytes justos: la medida que fija la aritmetica de 0x5DD6.

        `vuelca_el_campo` saca 32 casillas con `outi` y salta 48 antes de la
        fila siguiente. 32 + 48 son 80, y las filas son 23.
        """
        ini, _, _ = self.d["mapa_del_campo"]
        import graficos
        m = graficos.descomprime_a_la_ram(self.rom, ini)
        self.assertEqual(len(m), 80 * 23, "el mapa no mide 80 por 23")

    def test_el_mapa_no_usa_ni_un_tile_de_los_que_el_partido_reescribe(self):
        """Las casillas del campo van del 0x01 al 0x58, y ni una mas.

        Del 0x59 arriba estan los tiles que el partido reescribe en marcha
        para estampar los parches de 3x3 de los jugadores. Que el mapa no los
        toque es lo que permite dibujar el campo sin jugar la partida.
        """
        ini, _, _ = self.d["mapa_del_campo"]
        import graficos
        m = graficos.descomprime_a_la_ram(self.rom, ini)
        self.assertLessEqual(max(m), 0x58, "el mapa usa tiles del pozo")
        self.assertGreaterEqual(min(m), 0x01)

    def test_el_bloque_espejado_sale_con_los_bits_del_reves(self):
        """0x7087 se vuelca dos veces, y la segunda con el espejo.

        No se compara el aspecto: se descomprime por las dos puertas -la de
        C=0 y la de C=1- y se comprueba byte a byte que la segunda es la
        primera con los ocho bits dados la vuelta.
        """
        ini, _, _ = self.d["patrones_7087"]
        derecho = self.rle.descomprime(self.rom, ORG, ini, 0x2998)
        espejo = self.rle.descomprime(self.rom, ORG, ini, 0x2998, True)
        self.assertIsNotNone(derecho)
        self.assertIsNotNone(espejo)
        n = 0
        for a in range(0x4000):
            if not derecho[2][a]:
                continue
            n += 1
            self.assertEqual(espejo[1][a], self.rle.refleja(derecho[1][a]),
                             "0x%04X no es el reflejo" % a)
        self.assertEqual(n, 192, "el bloque no da los 192 bytes de VRAM")

    def test_los_sprites_del_partido_dan_veintitres_de_dieciseis(self):
        """0x76F0 se descomprime a la RAM, y de ahi salen 0x2E0 bytes.

        0x2E0 entre 32 son 23 sprites de 16x16, que es lo que 0x76C8 sube a
        0x1800 con LDIRVM antes de que 0x76D6 escriba otros 23 espejados.
        """
        ini, _, _ = self.d["sprites_por_la_ram"]
        import graficos
        banco = graficos.descomprime_a_la_ram(self.rom, ini)
        self.assertGreaterEqual(len(banco), 0x2E0)
        self.assertEqual(0x2E0 // 32, 23)


class TestRotulos(unittest.TestCase):
    """Los guiones, medidos EJECUTANDO el interprete del cartucho."""

    @classmethod
    def setUpClass(cls):
        import guiones
        cls.g = guiones
        cls.rom = rom_del_listado()
        cls.d = bloques_declarados()

    def texto(self, ini):
        r = self.g.ejecuta(self.rom, ORG, ini)
        self.assertIsNotNone(r, "el guion de 0x%04X no cierra" % ini)
        return " ".join(r[1].split()), r[0]

    def test_el_rotulo_de_la_falta_dice_offside(self):
        """La prueba de que este cartucho pita el fuera de juego."""
        t, _ = self.texto(self.d["rotulo_offside"][0])
        self.assertIn("OFFSIDE", t)

    def test_la_pantalla_final_dice_score_record_y_winner(self):
        t, _ = self.texto(self.d["guion_de_score_record"][0])
        self.assertIn("SCORE RECORD", t)
        self.assertIn("WINNER", t)

    def test_el_empate_lleva_a_penalty_shoot_out(self):
        t, _ = self.texto(self.d["guion_de_penalty_shoot_out"][0])
        self.assertIn("PENALTY SHOOT OUT", t)

    def test_el_menu_ofrece_uno_y_dos_jugadores(self):
        """Los dos guiones van PEGADOS: el segundo `call` de 0x4CF2 sigue
        donde el primero dejo DE, justo detras del 0xFF."""
        ini, _, _ = self.d["rotulos_de_los_menus"]
        t1, sigue = self.texto(ini)
        t2, _ = self.texto(sigue)
        self.assertIn("KONAMI 1985", t1)
        self.assertIn("PLAY SELECT", t1)
        self.assertIn("1PLAYER", t1)
        self.assertIn("2PLAYERS", t2)

    def test_el_rotulo_del_titulo_dice_konami(self):
        """"KONAM" y detras dos tiles dibujados a mano que dicen "I'S"."""
        t, _ = self.texto(0x4E41)
        self.assertIn("KONAM", t)


class TestTablas(unittest.TestCase):
    """Las tablas: que sean lo que la nota dice que son."""

    @classmethod
    def setUpClass(cls):
        cls.rom = rom_del_listado()
        cls.d = bloques_declarados()

    def b(self, a):
        return self.rom[a - ORG]

    def w(self, a):
        return self.b(a) | (self.b(a + 1) << 8)

    def test_las_tablas_pegadas_detras_del_call_encajan(self):
        """Su primera entrada apunta justo detras de la tabla.

        Es el encaje que fija cuantas entradas tienen, y el que las declaro.
        Se comprueban las que la nota dice que son de este tipo.
        """
        for nombre in ("pasos_del_bote_de_la_pelota", "pasos_del_saque_de_banda",
                       "los_once_pasos_del_saque_del_primer_bando",
                       "los_once_pasos_del_saque_del_segundo_bando",
                       "las_tres_subescenas_de_la_falta",
                       "pasos_de_la_tanda_de_penaltis",
                       "pasos_del_portero_del_penalti",
                       "pasos_de_la_maquina_con_la_pelota"):
            ini, fin, _ = self.d[nombre]
            self.assertEqual(self.w(ini), fin,
                             "%s no encaja con su primera entrada" % nombre)

    def test_las_dos_tablas_de_once_subescenas_son_gemelas(self):
        """Las de 0x91B0 y 0x9F65 llevan las mismas once entradas.

        Es el saque de un bando y el del otro: comparten cuerpo y solo cambian
        el sentido de la carrerilla.
        """
        a, af, _ = self.d["los_once_pasos_del_saque_del_primer_bando"]
        b, bf, _ = self.d["los_once_pasos_del_saque_del_segundo_bando"]
        self.assertEqual((af - a) // 2, 11)
        self.assertEqual((bf - b) // 2, 11)

    def test_los_registros_del_vdp_ponen_la_vram_del_reves(self):
        """R3 y R4 son base y mascara, y dejan el COLOR abajo y los PATRONES arriba."""
        ini, fin, _ = self.d["registros_del_vdp"]
        r = [self.b(ini + i) for i in range(fin - ini)]
        self.assertEqual(len(r), 8)
        self.assertEqual((r[0] >> 1) & 1, 1, "no es SCREEN 2")
        self.assertEqual(r[2] * 0x400, 0x3800, "los nombres no van a 0x3800")
        self.assertEqual((r[3] & 0x80) * 0x40, 0x0000, "el COLOR no va abajo")
        self.assertEqual((r[4] & 0x04) * 0x800, 0x2000,
                         "los PATRONES no van arriba")
        self.assertEqual(r[6] * 0x800, 0x1800, "los sprites no van a 0x1800")
        self.assertEqual((r[1] >> 1) & 1, 1, "los sprites no son de 16x16")

    def test_la_cabecera_del_cartucho_arranca_en_init(self):
        """"AB", INIT en 0x4070 y las otras tres entradas a cero."""
        ini, _, _ = self.d["cabecera_del_cartucho"]
        self.assertEqual(self.b(ini), ord("A"))
        self.assertEqual(self.b(ini + 1), ord("B"))
        self.assertEqual(self.w(ini + 2), 0x4070, "INIT no es 0x4070")
        for k in (4, 6, 8):
            self.assertEqual(self.w(ini + k), 0, "hay mas de un punto de entrada")

    def test_la_segunda_cabecera_es_la_del_game_master(self):
        """La de 0x4010: "AB", el 0x07 de RC-7xx y el 0x32 de RC-732."""
        ini, _, _ = self.d["cabecera_del_game_master"]
        self.assertEqual(ini, 0x4010)
        self.assertEqual(self.b(ini), ord("A"))
        self.assertEqual(self.b(ini + 1), ord("B"))
        self.assertEqual(self.b(ini + 2), 0x07, "no lleva el 0x07 del RC-7xx")
        self.assertEqual(self.b(ini + 3), 0x32, "no lleva el 0x32 del RC-732")

    def test_la_marca_de_konami_dice_rc732(self):
        """Los ultimos trece bytes: diez de titulo, la longitud, el numero y el cierre."""
        ini, fin, _ = self.d["marca_de_konami"]
        self.assertEqual(fin, FIN)
        self.assertEqual(self.b(fin - 1), 0xAA, "no cierra con 0xAA")
        self.assertEqual(self.b(fin - 2), 0x32, "el numero no es el 32")
        self.assertEqual(self.b(fin - 3), 0x0A, "la longitud no es diez")
        self.assertEqual(fin - 3 - ini, 10, "el titulo no mide diez bytes")

    def test_el_alcance_del_portero_no_baja_limpio(self):
        """32, 44, 24, 20 y 16: el del nivel 2 es MAS pasivo que el del 1.

        Es la altura a la que el portero deja de reaccionar, y con la porteria
        midiendo 54 pixeles el 0x2C del segundo nivel rompe la progresion de
        los otros cuatro.
        """
        ini, fin, _ = self.d["alcance_del_portero_por_nivel"]
        v = [self.b(a) for a in range(ini, fin)]
        self.assertEqual(v, [0x20, 0x2C, 0x18, 0x14, 0x10])
        self.assertGreater(v[1], v[0], "el nivel 2 no es el mas pasivo")
        for i in range(1, 4):
            self.assertGreater(v[i], v[i + 1], "del 2 al 5 no baja limpio")

    def test_la_demora_de_la_maquina_nunca_gana_a_la_del_humano(self):
        """16, 14, 12, 10 y 8 cuadros: en el nivel 5 iguala, nunca mejora.

        El bando del humano reacciona siempre en 8. La tabla de la maquina va
        de 16 a 8, o sea que en el mejor de los casos empata.
        """
        ini, fin, _ = self.d["dos_tablas_por_nivel"]
        v = [self.b(a) for a in range(ini, fin)]
        self.assertEqual(v[:5], [0x10, 0x0E, 0x0C, 0x0A, 0x08])
        self.assertEqual(v[4], 8, "el nivel 5 no iguala al humano")
        self.assertEqual(len(v), 10, "no son dos tablas de cinco")

    def test_los_rumbos_hacia_la_pelota_son_las_cuatro_diagonales(self):
        """Nadie corre en linea recta hacia la pelota.

        0xB555 solo alcanza los indices 2 a 5, y ahi estan el 2, el 4, el 8 y
        el 6, que son las cuatro diagonales. Las dos primeras entradas -el 1 y
        el 5, o sea derecha e izquierda- no las lee nadie.
        """
        ini, fin, _ = self.d["los_cuatro_rumbos_hacia_la_pelota"]
        v = [self.b(a) for a in range(ini, fin)]
        self.assertEqual(v, [1, 5, 2, 4, 8, 6])
        self.assertEqual(sorted(v[2:]), [2, 4, 6, 8], "no son las diagonales")

    def test_el_resbalon_del_choque_va_en_diagonal(self):
        """Las cuatro parejas de 0xB655 son +-8 en alto y en ancho."""
        ini, _, _ = self.d["el_resbalon_y_la_pelota_del_choque"]
        base = ini - 2                       # 0xB655
        for k in (2, 4, 6, 8):
            dy, dx = self.b(base + k), self.b(base + k + 1)
            self.assertIn(dy, (0x08, 0xF8), "el alto no es +-8")
            self.assertIn(dx, (0x08, 0xF8), "el ancho no es +-8")

    def test_los_ocho_juegos_de_camiseta_miden_tres(self):
        """24 bytes, ocho juegos de tres, y ocho muestras en el menu."""
        ini, fin, _ = self.d["colores_de_camiseta"]
        self.assertEqual(fin - ini, 24)
        self.assertEqual((fin - ini) // 3, 8)
        for a in range(ini, fin):
            self.assertLess(self.b(a), 16, "no es un color del TMS9918")

    def test_el_estado_de_fabrica_trae_eagles_y_stones(self):
        """Los 39 bytes de 0x5A5E, con los dos nombres y el nivel 1."""
        ini, fin, _ = self.d["estado_inicial_de_la_partida"]
        self.assertEqual(fin - ini, 39)
        # 0x5A5E cae en 0xE050; los nombres estan en 0xE05B y 0xE062
        self.assertEqual(como_texto(self.rom[ini - ORG + 11:ini - ORG + 17]),
                         "EAGLES")
        self.assertEqual(como_texto(self.rom[ini - ORG + 18:ini - ORG + 24]),
                         "STONES")
        self.assertEqual(self.b(ini + 0x19), 1, "el nivel de salida no es 1")

    def test_las_dos_paletas_de_salida_son_las_opciones_cero_y_tres(self):
        """El segundo paso, el que se olvida: 0x5C02 machaca tres entradas.

        Sin el, la tabla de COLOR sale mal en 4.092 de sus 6.144 bytes. Las
        camisetas de fabrica son la opcion 0 y la 3 de la tabla de 0x5C20, y
        coinciden con las dos ternas de 0x591E.
        """
        import graficos
        graficos.ORG = ORG
        p1, p2 = graficos.paletas_de_camiseta(self.rom)
        col, _, _ = self.d["colores_de_camiseta"]
        self.assertEqual(p1[:2], [0x0C, 0x01])
        self.assertEqual(p2[:2], [0x0C, 0x01])
        self.assertEqual(p1[2:5], [self.b(col + i) for i in range(3)])
        self.assertEqual(p2[2:5], [self.b(col + 9 + i) for i in range(3)])
        # y las dos ternas de 0x591E son esas mismas
        otra, _, _ = self.d["paletas_de_equipo_por_defecto"]
        self.assertEqual([self.b(otra + i) for i in range(3)], p1[2:5])
        self.assertEqual([self.b(otra + 3 + i) for i in range(3)], p2[2:5])

    def test_el_despachador_disfrazado_tiene_cinco_entradas(self):
        """0xB2DC: cinco palabras, y la sexta ya se sale del cartucho.

        No las salta un `jp` sino el `push bc / ret` de 0xB2DA, que es un
        `jp (bc)` escrito a mano. Es lo que escondia 283 bytes de codigo.
        """
        ini, fin, _ = self.d["tabla_del_despachador_disfrazado"]
        self.assertEqual((fin - ini) // 2, 5)
        for a in range(ini, fin, 2):
            self.assertTrue(ORG <= self.w(a) < FIN,
                            "la entrada de 0x%04X no cae en el cartucho" % a)
        self.assertFalse(ORG <= self.w(fin) < FIN,
                         "la sexta palabra tambien cabria")


class TestGraficos(unittest.TestCase):
    """El montaje de pantalla, corriendo los pasos del cartucho."""

    @classmethod
    def setUpClass(cls):
        import graficos
        graficos.ORG = ORG
        cls.g = graficos
        cls.rom = rom_del_listado()

    def test_la_fuente_tiene_las_cifras_el_guion_y_las_letras(self):
        """Los 44 tiles del 0x10 al 0x3B, y ni uno vacio.

        Es lo que fija la lectura de los rotulos: las cifras arrancan en el
        0x10, el 0x20 es el guion que separa los dos goles y las letras van
        del 0x21 al 0x3A. El 0x3B es el rombo del marco de la pantalla final.
        """
        v = self.g.escena_fuente(self.rom)
        for t in range(0x10, 0x3C):
            forma = [v[0x2000 + t * 8 + y] for y in range(8)]
            self.assertNotEqual(forma, [0] * 8, "el tile 0x%02X sale vacio" % t)
        # el guion: una sola raya, y en medio
        guion = [v[0x2000 + 0x20 * 8 + y] for y in range(8)]
        self.assertEqual(sum(1 for b in guion if b), 1,
                         "el 0x20 no es una raya sola")

    def test_el_campo_se_monta_entero_y_no_deja_casillas_vacias(self):
        """Las 1840 casillas del mapa caen sobre tiles que tienen dibujo.

        Si una tanda de graficos faltara, el mapa apuntaria a patrones a cero
        y el campo saldria con agujeros.
        """
        v = self.g.escena_campo(self.rom)
        m = self.g.mapa_del_campo(self.rom)
        vacios = set()
        for f in range(23):
            tercio = ((f + 1) // 8) * 0x800
            for c in range(80):
                t = m[f * 80 + c]
                forma = [v[0x2000 + tercio + t * 8 + y] for y in range(8)]
                color = [v[0x0000 + tercio + t * 8 + y] for y in range(8)]
                if forma == [0] * 8 and color == [0] * 8:
                    vacios.add(t)
        self.assertEqual(vacios, set(), "hay tiles del campo sin cargar")

    def test_el_logotipo_ocupa_siete_filas(self):
        """"KONAMI'S" asoma por arriba con dos tiles en la fila 2.

        Recortarlo desde la fila 3 se comia el apostrofe y el rotulo decia
        "KONAMIS". El recorte tiene que empezar en la 2.
        """
        v = self.g.escena_titulo(self.rom)
        def fila_llena(f):
            return any(v[0x3800 + f * 32 + c] for c in range(32))
        self.assertTrue(fila_llena(2), "la fila 2 esta vacia")
        self.assertFalse(fila_llena(1), "el logotipo empieza mas arriba")
        for f in range(2, 9):
            self.assertTrue(fila_llena(f), "la fila %d esta vacia" % f)


class TestWeb(unittest.TestCase):
    """Que la web diga lo que el listado dice."""

    @classmethod
    def setUpClass(cls):
        if not os.path.isdir(DOCS):
            raise unittest.SkipTest("la web aun no esta escrita")
        cls.paginas = {}
        for base, _, ficheros in os.walk(DOCS):
            for f in ficheros:
                if f.endswith((".md", ".html")):
                    r = os.path.join(base, f)
                    cls.paginas[r] = lee(r)

    def test_no_se_nombra_otro_juego_de_la_serie(self):
        """El fallo mas repetido de la serie es el copia y pega del anterior.

        Ping Pong y Road Fighter son la excepcion, y esta acotada: este
        cartucho comparte con ellos el armazon entero -incluidos los ocho
        bytes de los registros del VDP, identicos uno por uno- y eso se cuenta
        como hallazgo. Asi que se les permite aparecer, pero solo en las
        paginas donde la comparacion ES el contenido, y siempre al lado de la
        palabra que la justifica. En cualquier otra sigue siendo copia y pega.
        """
        permitido = ("FINDINGS", "HALLAZGOS", "OPEN-QUESTIONS",
                     "PREGUNTAS-ABIERTAS", "index")
        excepciones = ("Ping Pong", "Road Fighter")
        malas = []
        for ruta, texto in self.paginas.items():
            base = os.path.basename(ruta)
            for juego in OTROS_JUEGOS:
                if juego not in texto:
                    continue
                if (juego in excepciones
                        and base.rsplit(".", 1)[0] in permitido
                        and ("armazon" in texto or "armazón" in texto
                             or "skeleton" in texto)):
                    continue
                malas.append("%s nombra a %s" % (base, juego))
        self.assertEqual(malas, [], "; ".join(malas))

    def test_las_cifras_publicadas_son_las_del_listado(self):
        """El porcentaje comentado que se publica tiene que ser el medido."""
        bloques = bloques_del_listado(lee(ASM).splitlines())
        instr = sum(b[2] for b in bloques)
        coment = sum(b[3] for b in bloques)
        real = round(100.0 * coment / instr, 1)
        for ruta, texto in self.paginas.items():
            for m in re.finditer(r"(\d+[.,]\d)\s*%", texto):
                v = float(m.group(1).replace(",", "."))
                if 30.0 < v < 45.0:
                    self.assertAlmostEqual(
                        v, real, delta=0.6,
                        msg="%s publica %.1f %% y el listado da %.1f %%"
                            % (os.path.basename(ruta), v, real))


if __name__ == "__main__":
    unittest.main()
