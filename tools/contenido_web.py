#!/usr/bin/env python3
"""El CONTENIDO de la portada: los hallazgos y los pies de la galeria.

Va aparte de make_web.py a proposito. make_web.py es el generador -la
plantilla, la maquetacion, el HTML- y no cambia de un juego al siguiente; esto
es lo unico que hay que reescribir entero en cada cartucho. Teniendolo separado
no hay que ir buscando los textos del juego anterior dentro del generador, que
es justo como se han colado los nombres equivocados otras veces.

Cada hallazgo es (titulo, html) y cada entrada de galeria
(fichero, pie en castellano, pie en ingles).

Todas las cifras de aqui estan medidas sobre este cartucho, con las
herramientas de tools/, y no copiadas de ningun otro proyecto.
"""

HALLAZGOS = {
    "es": [
        ("Se pita el fuera de juego",
         "<p>Un cartucho de 32 KB de 1985, y lleva la regla dentro. "
         "<code>0xB667</code> corre en el momento del pase, y pide tres cosas "
         "a la vez: que la pelota vaya hacia la porteria contraria -el signo "
         "del byte alto de <code>(0xE2A8)</code>-, que el que la recibe este "
         "en la mitad de campo rival -pasado el pixel <code>0x140</code> de "
         "los 640 que mide el campo- y que este por delante de <b>los seis</b> "
         "rivales, uno por uno.</p>"
         "<p>El arbitro no pita ahi: espera. <code>0xB6F2</code> deja que la "
         "pelota caiga -<code>(0xE2AB)</code>, su velocidad vertical, a cero- "
         "y entonces mira <code>(0xE546)</code>: <b>si por el camino reboto en "
         "alguien, la falta se anula</b>. Solo si el pase llego y se controlo "
         "suena el 0x25 y sale el rotulo OFFSIDE.</p>"
         "<p>Y hay una condicion mas, que cambia como se juega: con dos "
         "jugadores se pita <b>siempre</b>; con uno solo, <b>solo del nivel 3 "
         "en adelante</b> (<code>cp 003h</code> en <code>0xB671</code>). En "
         "los niveles 1 y 2 la regla no existe.</p>"),

        ("Seis jugadores son casillas y seis son sprites",
         "<p>Un MSX1 solo saca cuatro sprites por linea de pantalla. Con "
         "veintidos figuras en el campo no hay manera, asi que el cartucho "
         "parte el problema por la mitad y dibuja <b>cada bando de una manera "
         "distinta</b>. Se ve en el orden del cuadro, en "
         "<code>0x5882..0x5892</code>:</p>"
         "<ol><li><code>guarda_el_fondo_del_bando</code> apunta las 3x3 "
         "casillas que va a tapar cada jugador</li>"
         "<li><code>estampa_el_bando_en_el_mapa</code> estampa los seis "
         "parches <b>sobre el mapa del campo</b>, que vive en la RAM</li>"
         "<li><code>pon_el_bando_en_sprites</code> saca al otro bando con "
         "cinco sprites por jugador</li>"
         "<li><code>vuelca_el_campo</code> tira el mapa entero a la VRAM</li>"
         "<li><code>devuelve_el_fondo_al_mapa</code> vuelve a poner el cesped "
         "que taparon los parches</li></ol>"
         "<p>Por eso el mapa de la RAM, mirado en el emulador en cualquier "
         "otro momento, esta <b>limpio</b>: las 1.840 casillas coinciden con "
         "las que salen de descomprimir <code>0x853E</code>, y las unicas dos "
         "que bailan son los dos porteros.</p>"
         "<p>Las poses no son sprites guardados: son un arbol de dos niveles "
         "-<code>(ix+0x0C)</code> elige el grupo y <code>(ix+0x0D)</code> la "
         "pose- con hojas de once bytes, dos de correccion y las nueve "
         "casillas. Salen <b>26 poses para un bando y 25 para el otro</b>, y "
         "estan todas dibujadas mas abajo.</p>"),

        ("La punteria no se calcula: se consulta",
         "<p>El Z80 no multiplica ni divide, y aqui hay que decidir con que "
         "fuerza sale un pase para que caiga donde se quiere. La solucion de "
         "<code>0x92E2</code> es no calcular nada.</p>"
         "<p>Se miden las dos distancias al objetivo y se parten en escalones "
         "de dieciseis, que es quedarse con el nibble alto de cada una: sale "
         "un numero de <b>0 a 15</b> para el ancho y otro de <b>0 a 11</b> "
         "para el alto. Con esos dos se entra en dos tablas de dos niveles "
         "que viven al final del cartucho: la de <code>0xBF0F</code> da el "
         "empuje vertical y la de <code>0xBD6F</code> las dos componentes del "
         "suelo. La trayectoria entera esta tabulada.</p>"
         "<p>Encima quedan dos correcciones. En el saque de banda el golpe se "
         "ablanda a <b>tres cuartos</b> -o a la mitad si el objetivo esta a "
         "menos de tres escalones en las dos direcciones-, y en el saque de "
         "centro el empuje vertical y la gravedad se <b>doblan</b>.</p>"),

        ("Un bloque comprimido, dos camisetas",
         "<p>Los dos equipos comparten los mismos dibujos. Lo que cambia es "
         "la tabla de COLOR, y la escribe el mismo descompresor pasando cada "
         "byte por <code>0x4846</code>, que parte el byte en sus dos nibbles "
         "-la tinta arriba, el fondo abajo-, mete cada uno en una paleta de "
         "cinco entradas y los vuelve a juntar. A donde apunta la paleta lo "
         "dice <code>(0xE52A)</code>.</p>"
         "<p><code>0x6F31</code> deja cuatro volcados de patron en "
         "<code>0x2320</code>, <code>0x2458</code>, <code>0x2590</code> y "
         "<code>0x26C8</code> -dos derechos y dos espejados-, y "
         "<code>0x742D</code> los pinta: los dos primeros con la paleta de "
         "<code>0xE051</code> y los dos ultimos con la de "
         "<code>0xE056</code>.</p>"
         "<p>Las paletas se arman en <b>dos pasos</b>, y saltarse el segundo "
         "cuesta caro: <code>0x5A45</code> copia 39 bytes de fabrica a "
         "<code>0xE050</code>, y despues <code>0x5C02</code> machaca las "
         "entradas 2, 3 y 4 de cada una con el juego de tres tonos que se "
         "eligio en el menu. Montando la pantalla sin ese segundo paso, la "
         "tabla de COLOR sale distinta en <b>4.092 de sus 6.144 bytes</b>.</p>"),

        ("Un `jp (bc)` escrito a mano, y 283 bytes de codigo detras",
         "<p>El Z80 tiene <code>jp (hl)</code>, pero no <code>jp (bc)</code>. "
         "En <code>0xB2DA</code> el cartucho lo escribe a mano: apila BC y "
         "hace <code>ret</code>. Para cualquier trazador eso es el final de "
         "una rutina, y ahi se paraba: detras habia <b>283 bytes</b> que "
         "nadie alcanzaba, con su tabla de cinco entradas en "
         "<code>0xB2DC</code>.</p>"
         "<p>El encaje que la fija en cinco y no en seis es que la sexta "
         "palabra ya cae fuera del cartucho. Es el <b>unico</b> "
         "<code>push bc / ret</code> de los 32 KB; de <code>push hl / ret</code> "
         "hay veintisiete, y esos no se han repasado uno a uno.</p>"),

        ("Dos marcadores comparados con una sola resta",
         "<p>Al final del partido hay que saber si hubo penaltis, o sea si "
         "los dos equipos acabaron empatados. Cada marcador son dos bytes: la "
         "cifra en BCD y el acarreo. Comparar dos parejas pide dos restas.</p>"
         "<p><code>0xB903</code> hace una. Arma <b>dos parejas cruzadas</b> "
         "-una cifra baja de cada equipo con un acarreo de cada equipo- y las "
         "resta con un solo <code>sbc hl,bc</code> de 16 bits. El resultado es "
         "cero exactamente cuando coinciden las dos comparaciones a la vez.</p>"),

        ("La entrada que no sale acaba en choque",
         "<p>Robar la pelota depende de por donde se entra. <code>0xABCA</code> "
         "compara el rumbo del que entra con el del que la lleva, y si "
         "coinciden -o van a cinco de distancia- el robo sale, con su pitido. "
         "Si no, chocan.</p>"
         "<p>Y el choque esta escrito con detalle. Al que la llevaba le caen "
         "<b>16 cuadros</b> quieto; al que entro se le redondea el rumbo a la "
         "diagonal siguiente, se le pone el dibujo 4 -por el suelo- y "
         "<b>resbala dos veces, ocho pixeles cada una y ocho cuadros entre "
         "ellas</b>, con la pelota siguiendole a los pies. Al levantarse, la "
         "lleva el.</p>"
         "<p>Mientras dura, la fisica de la pelota <b>no corre</b>: las "
         "entradas 6 y 7 de la tabla de <code>0x8C70</code> -el choque y el "
         "fuera de juego- son un <code>ret</code> pelado.</p>"),
    ],

    "en": [
        ("It calls offside",
         "<p>A 32 KB cartridge from 1985, and the rule is in there. "
         "<code>0xB667</code> runs the moment the pass is made, and it asks "
         "for three things at once: that the ball is heading for the opposing "
         "goal -the sign of the high byte of <code>(0xE2A8)</code>-, that the "
         "receiver is in the opponents' half -past pixel <code>0x140</code> of "
         "the 640 the pitch is wide- and that he is ahead of <b>all six</b> "
         "opponents, one by one.</p>"
         "<p>The referee does not blow there: he waits. <code>0xB6F2</code> "
         "lets the ball land -<code>(0xE2AB)</code>, its vertical speed, at "
         "zero- and then checks <code>(0xE546)</code>: <b>if it bounced off "
         "anyone on the way, the call is dropped</b>. Only if the pass "
         "arrived and was controlled does sound 0x25 play and the OFFSIDE "
         "banner appear.</p>"
         "<p>And there is one more condition, and it changes how the game "
         "plays: with two players it is called <b>always</b>; with one, "
         "<b>only from level 3 up</b> (<code>cp 003h</code> at "
         "<code>0xB671</code>). At levels 1 and 2 the rule does not "
         "exist.</p>"),

        ("Six players are tiles and six are sprites",
         "<p>An MSX1 shows only four sprites per scanline. With twenty-two "
         "figures on the pitch that is hopeless, so the cartridge splits the "
         "problem in half and draws <b>each side a different way</b>. It is "
         "there in the order of the frame, at <code>0x5882..0x5892</code>:</p>"
         "<ol><li><code>guarda_el_fondo_del_bando</code> notes the 3x3 tiles "
         "each player is about to cover</li>"
         "<li><code>estampa_el_bando_en_el_mapa</code> stamps the six patches "
         "<b>onto the pitch map</b>, which lives in RAM</li>"
         "<li><code>pon_el_bando_en_sprites</code> draws the other side with "
         "five sprites per player</li>"
         "<li><code>vuelca_el_campo</code> throws the whole map at the "
         "VRAM</li>"
         "<li><code>devuelve_el_fondo_al_mapa</code> puts the grass the "
         "patches covered back</li></ol>"
         "<p>That is why the RAM map, looked at in the emulator at any other "
         "moment, is <b>clean</b>: its 1,840 tiles match the ones that come "
         "out of decompressing <code>0x853E</code>, and the only two that "
         "differ are the two goalkeepers.</p>"
         "<p>The poses are not stored sprites: they are a two-level tree "
         "-<code>(ix+0x0C)</code> picks the group and <code>(ix+0x0D)</code> "
         "the pose- with eleven-byte leaves, two of correction and the nine "
         "tiles. There are <b>26 poses for one side and 25 for the other</b>, "
         "and they are all drawn below.</p>"),

        ("The aim is never computed: it is looked up",
         "<p>The Z80 has neither multiply nor divide, and here you have to "
         "decide how hard a pass leaves so that it lands where you want. "
         "<code>0x92E2</code> solves it by computing nothing.</p>"
         "<p>The two distances to the target are measured and split into "
         "steps of sixteen, which is keeping the high nibble of each: that "
         "gives a number from <b>0 to 15</b> for the horizontal and one from "
         "<b>0 to 11</b> for the vertical. Those two index two two-level "
         "tables at the end of the cartridge: the one at <code>0xBF0F</code> "
         "gives the vertical impulse and the one at <code>0xBD6F</code> the "
         "two ground components. The whole trajectory is tabulated.</p>"
         "<p>Two corrections sit on top. On a throw-in the kick is softened "
         "to <b>three quarters</b> -or to a half if the target is under three "
         "steps away in both directions- and on the kick-off the vertical "
         "impulse and gravity are <b>doubled</b>.</p>"),

        ("One compressed block, two kits",
         "<p>Both teams share the same drawings. What changes is the COLOUR "
         "table, and the same decompressor writes it, passing every byte "
         "through <code>0x4846</code>, which splits the byte into its two "
         "nibbles -ink on top, paper below-, runs each through a five-entry "
         "palette and puts them back together. Where the palette points is "
         "held in <code>(0xE52A)</code>.</p>"
         "<p><code>0x6F31</code> leaves four pattern dumps at "
         "<code>0x2320</code>, <code>0x2458</code>, <code>0x2590</code> and "
         "<code>0x26C8</code> -two straight and two mirrored- and "
         "<code>0x742D</code> paints them: the first two with the palette at "
         "<code>0xE051</code> and the last two with the one at "
         "<code>0xE056</code>.</p>"
         "<p>The palettes are built in <b>two steps</b>, and skipping the "
         "second is expensive: <code>0x5A45</code> copies 39 factory bytes to "
         "<code>0xE050</code>, and then <code>0x5C02</code> overwrites "
         "entries 2, 3 and 4 of each with the set of three tones chosen in "
         "the menu. Building the screen without that second step gets the "
         "COLOUR table wrong in <b>4,092 of its 6,144 bytes</b>.</p>"),

        ("A hand-written `jp (bc)`, with 283 bytes of code behind it",
         "<p>The Z80 has <code>jp (hl)</code>, but no <code>jp (bc)</code>. At "
         "<code>0xB2DA</code> the cartridge writes one by hand: it pushes BC "
         "and does <code>ret</code>. To any tracer that is the end of a "
         "routine, and that is where it stopped: behind it were <b>283 "
         "bytes</b> nobody reached, with their five-entry table at "
         "<code>0xB2DC</code>.</p>"
         "<p>What fixes the count at five and not six is that the sixth word "
         "already falls outside the cartridge. It is the <b>only</b> "
         "<code>push bc / ret</code> in the 32 KB; there are twenty-seven "
         "<code>push hl / ret</code>, and those have not been gone through "
         "one by one.</p>"),

        ("Two scores compared with a single subtraction",
         "<p>At the end of the match you have to know whether there were "
         "penalties, that is, whether the two teams finished level. Each "
         "score is two bytes: the BCD digit and the carry. Comparing two "
         "pairs takes two subtractions.</p>"
         "<p><code>0xB903</code> does one. It builds <b>two crossed pairs</b> "
         "-one low digit from each team with one carry from each team- and "
         "subtracts them with a single 16-bit <code>sbc hl,bc</code>. The "
         "result is zero exactly when both comparisons hold at once.</p>"),

        ("The tackle that fails ends in a collision",
         "<p>Winning the ball depends on the angle you come in at. "
         "<code>0xABCA</code> compares the tackler's heading with the "
         "carrier's, and if they match -or are five apart- the tackle works, "
         "with its whistle. If not, they crash.</p>"
         "<p>And the crash is written out in detail. The carrier gets <b>16 "
         "frames</b> frozen; the tackler has his heading rounded to the next "
         "diagonal, is given drawing 4 -on the ground- and <b>slides twice, "
         "eight pixels each time and eight frames apart</b>, with the ball "
         "following at his feet. He gets up with it.</p>"
         "<p>While it lasts, the ball physics <b>do not run</b>: entries 6 and "
         "7 of the table at <code>0x8C70</code> -the collision and the "
         "offside- are a bare <code>ret</code>.</p>"),
    ],
}

GALERIA = [
    ("campo.png",
     "El campo entero: 80 columnas por 23 filas, 640 por 184 pixeles. No es "
     "una captura ni un montaje de capturas: es el mapa que 0x8538 "
     "descomprime en 0xE600, dibujado casilla a casilla con los patrones y "
     "los colores que dejan las diez tandas de graficos de 0x4279. La "
     "pantalla solo asoma 32 de esas 80 columnas.",
     "The whole pitch: 80 columns by 23 rows, 640 by 184 pixels. Not a "
     "capture nor a montage of captures: it is the map 0x8538 decompresses "
     "into 0xE600, drawn tile by tile with the patterns and colours the ten "
     "graphics batches at 0x4279 leave behind. The screen only ever shows 32 "
     "of those 80 columns."),

    ("fichas.png",
     "Las 51 poses de los jugadores, sacadas del arbol de parches: 26 de un "
     "bando y 25 del otro, cada una nueve casillas de 8x8. Son los mismos "
     "dibujos con dos tablas de color distintas. El cesped de detras es el "
     "tile 0x01, el mismo con el que el mapa llena el campo.",
     "The 51 player poses, taken from the patch tree: 26 for one side and 25 "
     "for the other, each of them nine 8x8 tiles. They are the same drawings "
     "with two different colour tables. The grass behind is tile 0x01, the "
     "same one the map fills the pitch with."),

    ("titulo.png",
     "La pantalla de titulo con su menu, montada paso a paso como la monta el "
     "cartucho. El rotulo grande no es una imagen guardada: son cinco filas "
     "de catorce patrones CONSECUTIVOS que 0x4CD3 estampa desde el 0x40. "
     "Cotejada contra la VRAM del emulador: cero bytes distintos en las tres "
     "tablas.",
     "The title screen with its menu, assembled step by step the way the "
     "cartridge does it. The big logo is not a stored image: it is five rows "
     "of fourteen CONSECUTIVE patterns that 0x4CD3 stamps from 0x40 on. "
     "Checked against the emulator's VRAM: zero bytes different across all "
     "three tables."),

    ("fuente.png",
     "Los 44 tiles de la fuente, del 0x10 al 0x3B, puestos en fila para "
     "poder mirarlos. El reparto explica los rotulos: las diez cifras "
     "arrancan en el 0x10, el 0x20 es el guion que separa los dos goles del "
     "marcador, las letras van del 0x21 al 0x3A y el 0x3B es el rombo con el "
     "que se dibuja a mano el marco de la pantalla final.",
     "The 44 tiles of the font, from 0x10 to 0x3B, laid out in a row so they "
     "can be looked at. The layout explains the labels: the ten digits start "
     "at 0x10, 0x20 is the dash between the two goal counts, the letters run "
     "from 0x21 to 0x3A, and 0x3B is the diamond the final screen's frame is "
     "hand-drawn with."),
]
