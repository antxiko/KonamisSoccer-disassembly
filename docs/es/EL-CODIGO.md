# El código

## Todo cuelga de la interrupción

`0x4070` engancha `H.KEYI` y se queda parado en un `jr $`. A partir de ahí, el
programa entero es lo que corre cada cincuentavo de segundo. `0x40C8` reparte
la escena que diga `(0xE000)` con la tabla de nueve entradas de `0x40E3`, y
`(0xE001)` reparte el paso dentro de ella con una cadena de `djnz`.

| variable | qué es |
|---|---|
| `(0xE000)` | la escena |
| `(0xE001)` | el paso dentro de la escena |
| `(0xE003)` | el contador de cuadros, que hace de azar |
| `(0xE004)` | la cuenta de espera |
| `(0xE005)` | el cerrojo de reentrada |

## El repartidor de tablas pegadas

Casi todo el programa es una máquina de estados, y el mecanismo se repite
trece veces: un `call 0x4066` con la tabla de punteros **pegada justo detrás
del `call`**. La rutina saca la dirección de retorno de la pila, la usa como
base de la tabla, indexa con A y salta.

Cuántas entradas tiene cada tabla no está escrito en ninguna parte. Lo fija un
encaje: **ninguna entrada puede apuntar dentro de su propia tabla**, así que la
primera marca dónde acaba. Ese encaje corrigió dos que parecían de 24 y 29
entradas y son de 9 y 4.

## El del `push bc / ret`

Hay un catorceavo repartidor que no se parece a los demás. `0xB2CC` saca el
destino de la tabla de `0xB2DC`, lo apila y hace `push bc / ret`: un
`jp (bc)`, que el Z80 no tiene, escrito a mano. Para un trazador eso es el
final de una rutina, y detrás quedaban **283 bytes** que nadie alcanzaba.

## El descompresor

Casi todos los gráficos van comprimidos, con un formato de un mandato por byte
que escribe directo a la VRAM. Lo hace `L_47B7`:

| mandato | qué hace |
|---|---|
| `0x00` | cierra el bloque; es lo **único** que marca dónde acaba |
| `0x01`-`0x7F` | el byte que sigue, repetido esa cuenta |
| `0x80` | los dos bytes que siguen son una dirección de VRAM nueva |
| `0x81`-`0xFF` | copia tal cual los (mandato `& 0x7F`) bytes que siguen |

Como el tamaño no está escrito en ninguna parte, **ejecutar el descompresor es
la única forma honesta de saber dónde acaba cada bloque**. Es lo que hace
`tools/rle.py`, y es de donde salen los límites de los 125 rangos de datos
declarados.

Encima de ese formato hay dos añadidos, y los dos ahorran ROM:

- **El espejo.** `L_4836` lee cada byte y, si el bit 0 de C está puesto,
  `L_483B` lo saca con los ocho bits del revés, que en SCREEN 2 es reflejar el
  patrón. Hay dos puertas, `L_47DE` con C=0 y `L_47E2` con C=1, y las dos caen
  en el mismo bucle. El mismo bloque comprimido sirve para las dos mitades de
  un dibujo simétrico.
- **El recoloreado.** `L_4707` es el mismo bucle pasando cada byte por
  `0x4846`, que cambia los dos nibbles del byte de color por una paleta de
  cinco entradas en RAM. El mismo bloque pinta las dos camisetas.

Las puertas de volcado, todas en el mismo tramo:

| dirección | qué hace |
|---|---|
| `0x4680` | LDIRVM, un bloque sin comprimir |
| `0x4684` | FILVRM |
| `0x4687` | FILVRM en los tres tercios |
| `0x4698` | descomprime en los tres tercios |
| `0x46A8` | igual, con espejo |
| `0x46B8` | igual, cambiando el color |
| `0x47AF` | el destino va en los dos primeros bytes del bloque |

## El cuadro del partido

`0x5805` es lo que corre en cada interrupción mientras se juega, y **el orden
importa**: cada rutina cuenta con lo que dejó la anterior.

    el árbitro y las reglas          0x5818
    las tres subescenas de la falta  0x581B
    la cuenta atrás del saque        0x5828
    en qué zona está la pelota       0x582B
    cambiar de jugador con el botón  0x582E
    quién ocupa cada puesto          0x5831
    la máquina elige compañero       0x5834
    el destacado de cada mando       0x5837
    el aviso del cambio de jugador   0x583A
    el subestado del choque          0x583D
    un cuadro de la táctica          0x5840
    la lógica de los dos porteros    0x5843
    todos miran a la pelota          0x5846

Y el dibujo, después:

    guarda el fondo del bando        0x5882
    estampa el bando en el mapa      0x5885
    pone el otro bando en sprites    0x5888
    vuelca el campo a la VRAM        0x588F
    devuelve el fondo al mapa        0x5892

## Las variables del partido

| variable | qué es |
|---|---|
| `(0xE100)` | las doce fichas, 32 bytes cada una |
| `(0xE280)` | el subestado del partido |
| `(0xE281)` | el subestado de la pelota |
| `(0xE2A1)` `(0xE2A5)` | la altura y el ancho de la pelota |
| `(0xE2AB)` | su velocidad vertical |
| `(0xE2C1)` | por dónde va la ventana del campo |
| `(0xE410)` | la lista de puestos de las doce fichas |
| `(0xE527)` | el bando que lleva la cámara |
| `(0xE528)` | quién lleva la pelota |
| `(0xE52C)` `(0xE52D)` | el destacado de cada mando |
| `(0xE533)` | qué tipo de saque hay en marcha, de 1 a 10 |
| `(0xE600)` | el mapa del campo, 80 por 23 |

Dentro de una ficha, los desplazamientos que más se usan:

| +N | qué es |
|---|---|
| +0x03 | el rumbo, de 1 a 8 |
| +0x04 | la altura |
| +0x06 +0x07 | el ancho, en 16 bits |
| +0x0A +0x0B | la posición en pantalla; `0xE0` en la altura es "no se ve" |
| +0x0C | el grupo de dibujo |
| +0x0D | el dibujo dentro del grupo; el 4 es por el suelo |
| +0x15 | el número de ficha, de 0 a 11 |
| +0x16..+0x18 | a dónde tiene que ir |
| +0x1A | los cuadros que le faltan para reaccionar |

## Los ocho rumbos

Se usan a cada paso, y siempre igual:

    6  7  8
    5  ·  1
    4  3  2

El primer bando —las fichas 0 a 5— **ataca a la izquierda** y el segundo —las
6 a 11— **a la derecha**. Se comprueba por tres caminos: por dónde tiene que
estar el que recibe un pase para que sea fuera de juego, hacia dónde mira el
que saca una falta, y hacia dónde camina mientras se coloca.
