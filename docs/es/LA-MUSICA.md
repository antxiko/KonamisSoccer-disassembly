# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`tic_del_sonido`, 0x4F25, y `pide_un_sonido_siempre`, 0x4E5B, que le reparte los canales; lo llama el latido de la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- el tercer rótulo (0x9B), sus primeros 232 cuadros de 385;
- la pieza 0xAE, sus primeros 233 cuadros de 450.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`pide_un_sonido_siempre` recibe el número en A (`pide_un_sonido` hace lo mismo solo con partida, bit 6 de 0xE002; las presentaciones y los menús entran por la primera). Los números bajos son efectos y del 0x81 en adelante hay música. Cada voz ocupa catorce bytes desde 0xE010 y 0xE03A guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten la 0x9A, la 0x9C y la 0xAC, de minutos de duración.

## Las músicas

**El tercer rótulo** (0x9B)

Lo pide `escena_rotulo_3`: suena el 0x9B y se esperan 0x50 cuadros; dura 6,4 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_9B.mp3?v=1eb9462c"></audio>

**La pieza del 0xB8B6** (0xAE)

Lo pide `L_B8B6`; dura 7,5 s.

<audio controls preload="none" src="../audio/musica_AE.mp3?v=8ce6badb"></audio>

**Pista 0xAD de la tabla** (0xAD)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 7,5 s.

<audio controls preload="none" src="../audio/musica_AD.mp3?v=a02111a6"></audio>

**Pista 0xAF de la tabla** (0xAF)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 7,5 s.

<audio controls preload="none" src="../audio/musica_AF.mp3?v=db278e35"></audio>

**Pista 0xB0 de la tabla** (0xB0)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 7,5 s.

<audio controls preload="none" src="../audio/musica_B0.mp3?v=c860259e"></audio>

**Pista 0xB1 de la tabla** (0xB1)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,9 s.

<audio controls preload="none" src="../audio/musica_B1.mp3?v=3bcbb48a"></audio>

**Pista 0xB2 de la tabla** (0xB2)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,9 s.

<audio controls preload="none" src="../audio/musica_B2.mp3?v=89e468ed"></audio>
