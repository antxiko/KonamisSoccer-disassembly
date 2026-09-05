# El cartucho

## La máquina

Un MSX1: Z80 a 3,58 MHz, VDP **TMS9918**, generador de sonido **AY-3-8910**,
16 KB de VRAM y 8 KB de RAM. El cartucho aporta 32 KB de ROM y no lleva ni
mapper ni RAM propia.

## Las dos páginas

Con 32 KB el cartucho ocupa **dos páginas** del mapa de memoria, de `0x4000` a
`0xBFFF`. La RAM de trabajo empieza en `0xE000`.

| tramo | qué hay |
|---|---|
| `0x4000`-`0x4010` | la cabecera "AB" y el punto de entrada |
| `0x4010`-`0x4025` | una **segunda cabecera "AB"** que este cartucho no lee |
| `0x4025`-`0x4C19` | el armazón: escenas, VDP, VRAM, sonido, rótulos |
| `0x4C19`-`0x5645` | la presentación, el menú y el intérprete de sonido |
| `0x5645`-`0x651E` | el montaje del partido, el cuadro, el reloj y el gol |
| `0x651E`-`0x6BD8` | la tanda de penaltis |
| `0x6BD8`-`0x6D18` | la escena del logotipo |
| `0x6D18`-`0x853E` | los gráficos y sus cargadores |
| `0x853E`-`0x8787` | el mapa del campo, comprimido |
| `0x8787`-`0x9408` | las fichas, la física de la pelota y la puntería |
| `0x9408`-`0xA219` | el pase, el tiro, los fondos y los saques |
| `0xA219`-`0xB4C3` | la táctica y la inteligencia |
| `0xB4C3`-`0xB9F9` | el fuera de juego y la pantalla final |
| `0xB9F9`-`0xBFF3` | las tablas de trayectoria y de sprites |
| `0xBFF3`-`0xC000` | la marca oculta de Konami |

## La cabecera

Los cuatro primeros bytes dicen todo lo que la BIOS necesita:

    41 42 70 40    "AB", y el INIT en 0x4070

Las otras tres entradas —STATEMENT, DEVICE y TEXT— están a cero, y los seis
bytes reservados también. Es un cartucho de un solo punto de entrada.

`0x4070` engancha la interrupción en H.KEYI y se queda en el `jr $` de
`0x40BE`. **Todo el juego cuelga de la interrupción**: el bucle principal no
existe.

## La segunda cabecera, la que este cartucho no lee

En `0x4010` hay otro "AB", con el `0x07` del RC-7xx y el `0x32` del RC-732
dentro. No la lee nadie desde aquí. Es la cabecera del **Konami Game Master**,
el cartucho de trucos que se conecta en la otra ranura y busca ahí las
direcciones que puede tocar. Sólo cuatro de los cartuchos de Konami la llevan.

## La VRAM, del revés de lo acostumbrado

Los ocho registros del VDP salen de la tabla de `0x4889`, y son

    02 E2 0E 7F 07 76 03 E4

| registro | valor | qué deja |
|---|---|---|
| R0 | 0x02 | SCREEN 2 |
| R1 | 0xE2 | 16K, pantalla encendida, interrupción, **sprites de 16x16** |
| R2 | 0x0E | tabla de NOMBRES en `0x3800` |
| R3 | 0x7F | tabla de COLOR en **`0x0000`** |
| R4 | 0x07 | tabla de PATRONES en **`0x2000`** |
| R5 | 0x76 | ATRIBUTOS de sprite en `0x3B00` |
| R6 | 0x03 | PATRONES de sprite en `0x1800` |
| R7 | 0xE4 | borde y fondo |

R3 y R4 no son direcciones: son **base y máscara**. Aquí dejan el COLOR abajo
y los PATRONES arriba, justo al revés del reparto habitual. De ahí sale una
regla que vale para las diez tandas de gráficos: **el color de un volcado de
patrón está `0x2000` bytes más abajo, en la misma dirección**. Los patrones de
`0x2828` tienen su color en `0x0828`, los de `0x2998` en `0x0998`, y así con
todos.

R7 cambia con la escena: `0xE4` al arrancar y `0x00` durante el partido, o sea
que el fondo del campo es **negro**, no azul.

## El sonido

Un intérprete propio en `0x4E50`, con **54 secuencias** apuntadas por la tabla
de `0x50DA`. Los tonos salen de doce bytes en `0x50CE`, uno por semitono, y la
octava se consigue desplazando a la izquierda.

## La marca oculta de Konami

Los trece últimos bytes del cartucho, de `0xBFF3` a `0xBFFF`:

    ... 0A 32 AA

Diez bytes con el título en katakana —コナミのサッカー— escrito del revés, su
longitud (`0x0A`), el **`0x32` del RC-732** y el `0xAA` de cierre.

Que esa marca existía y qué forma tiene lo descubrió **Manuel Pazos**, y de él
sale esto: aquí sólo se ha comprobado que este cartucho la lleva y que el
número que trae dentro es el suyo.
