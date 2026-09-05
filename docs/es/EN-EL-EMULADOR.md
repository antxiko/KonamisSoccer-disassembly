# En el emulador

El emulador aquí no sirve para hacer capturas: **sirve para comprobar que lo
que decimos es verdad**. Las imágenes de esta web las dibuja Python
ejecutando los pasos del cartucho, y el emulador es quien dice si esos pasos
están bien leídos.

## Arrancarlo

    openmsx -machine Philips_VG_8020 -cart soccer.rom

Es un cartucho de 32 KB con cabecera "AB" y un solo punto de entrada, así que
arranca en cualquier MSX1 con 8 KB de RAM.

## Volcar la VRAM

    make vram

Eso hace tres cosas:

1. lanza openMSX con `tools/omsx_vram.tcl`, que **no pone ni un punto de
   ruptura**: los volcados van por reloj emulado, que es lo único que no ahoga
   al emulador;
2. en siete instantes vuelca los 16 KB de VRAM, los ocho registros del VDP, los
   4 KB de RAM de trabajo y una captura;
3. compara los volcados contra lo que monta `tools/graficos.py`, byte a byte,
   con `tools/coteja_vram.py`.

El guion tiene un perro guardián de 240 segundos de tiempo **real**: un guion
roto no puede dejar el emulador colgado.

## Lo que dice el cotejo

    titulo   COLOR 0    PATRONES 0    NOMBRES 0
    campo    COLOR 0    PATRONES 0    SPR PATR 0
             MAPA de 0xE600, 80x23:  2 de 1840
             VENTANA de 23x32:      44 de 736, y 42 son parches de jugador

La pantalla de título sale **idéntica en las tres tablas**. En el campo, las
tres tablas de gráficos también, y las diferencias que quedan están
explicadas:

- las **dos** casillas del mapa son los dos porteros, que no vienen en el
  bloque comprimido: se estampan al arrancar la jugada;
- de las 44 de la ventana, 42 son los parches de 3x3 de los jugadores que
  había en pantalla en ese momento, y las otras dos son esos mismos porteros.

El cotejo deja fuera a propósito la tabla de atributos de sprite —cambia cada
cuadro— y los tiles `0x5C` a `0x63`, que el partido reescribe en marcha para
estampar los parches. Que el mapa del campo no use ninguno de ellos —sus
casillas van del `0x01` al `0x58`— es lo que permite dibujar el campo entero
sin jugar la partida, y hay un test que lo vigila.

## Los ocho registros, comprobados

La tabla de `0x4889` dice `02 E2 0E 7F 07 76 03 E4`, y el emulador devuelve
exactamente eso en la pantalla de arranque. Durante el partido sólo cambia R7,
que pasa a `0x00`: el fondo del campo es negro.

## Mirar la RAM

El volcado incluye los 4 KB de `0xE000` a `0xEFFF`, y ahí se puede leer el
estado entero del partido: las dos paletas de camiseta en `0xE051` y `0xE056`,
las doce fichas desde `0xE100`, el mapa del campo en `0xE600`, y los cuatro
pasos por cuadro en `0xE06A`-`0xE071`. Con el nivel 1 salen `0x0100` y `0x0150`
para el bando del humano y `0x00E0` y `0x0130` para el de la máquina, que es
lo que dice la tabla de `0x57EF`.

## Un aviso

`tools/omsx_vram.tcl` cruza el menú pulsando la barra espaciadora en unos
tiempos fijos. Si Konami cambiara de idea, o si se usa otra máquina más lenta,
los volcados pueden caer en otra escena: cada `info_NN.txt` lleva la escena y
el subestado apuntados, así que se ve enseguida.
