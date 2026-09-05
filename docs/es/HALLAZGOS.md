# Hallazgos

Lo que apareció al desmontarlo. Cada cosa con la dirección donde se ve.

## El fuera de juego, con sus tres condiciones y una excepción

Un cartucho de 32 KB de 1985 lleva la regla dentro. `0xB667` corre en el
momento del pase y pide tres cosas a la vez:

1. que la pelota vaya hacia la portería contraria —el signo del byte alto de
   `(0xE2A8)`—;
2. que el que la recibe esté en la mitad de campo rival: pasado el píxel
   `0x140` de los 640 que mide el campo, o antes de él según el bando;
3. que esté por delante de **los seis** rivales, y se recorren uno a uno con
   un margen de ocho píxeles.

El árbitro no pita ahí. `0xB6F2` espera a que la pelota caiga —`(0xE2AB)`, su
velocidad vertical, a cero— y entonces mira `(0xE546)`: **si por el camino
rebotó en alguien, la falta se anula**. Sólo si el pase llegó y se controló
suena el `0x25` y sale el rótulo OFFSIDE.

Y hay una condición más: con dos jugadores se pita **siempre**; con uno solo,
**sólo del nivel 3 en adelante** (`cp 003h` en `0xB671`). En los niveles 1 y 2
la regla no existe.

El saque de la falta va en tres subescenas: agotar el rótulo —`0x60` cuadros,
casi dos segundos—, esperar el botón, y veinte cuadros andando. Con un detalle
bonito: **cuando el que saca es la máquina, la espera se acorta a la mitad**
—`0x40` cuadros en vez de `0x80`—, porque nadie va a pulsar nada.

## Seis jugadores son casillas y seis son sprites

Un MSX1 sólo saca cuatro sprites por línea. Con doce jugadores y dos porteros
no hay manera, así que el cartucho parte el problema y dibuja **cada bando de
una manera distinta**. Está en el orden del cuadro, `0x5882`-`0x5892`:

1. `guarda_el_fondo_del_bando` apunta las 3x3 casillas que va a tapar cada
   jugador;
2. `estampa_el_bando_en_el_mapa` estampa los seis parches **sobre el mapa**,
   que vive en la RAM;
3. `pon_el_bando_en_sprites` saca al otro bando con cinco sprites por jugador;
4. `vuelca_el_campo` tira el mapa entero a la VRAM;
5. `devuelve_el_fondo_al_mapa` vuelve a poner el césped que taparon.

Por eso el mapa de la RAM, mirado en el emulador en cualquier otro momento,
está **limpio**: sus 1.840 casillas coinciden con las que salen de
descomprimir `0x853E`, y las dos únicas que bailan son los dos porteros.

Y el bando de los sprites tiene sus propios dos trucos, los dos en
`sube_los_sprites` (`0x472B`):

- **El jugador que llevas nunca desaparece.** Antes de subir la lista se
  intercambian los dieciséis bytes de su grupo con los del primero, así que
  queda delante de todos y gana siempre la prioridad del VDP.
- **Los demás parpadean en vez de desaparecer.** El bit 0 del contador de
  cuadros parte los veinte sprites del medio en dos: en los cuadros pares
  suben en orden, y en los impares suben primero los ocho últimos y detrás los
  doce primeros. El orden se da la vuelta cada cuadro, y el quinto de una
  línea deja de ser siempre el mismo.

## La puntería no se calcula: se consulta

El Z80 no multiplica ni divide, y hay que decidir con qué fuerza sale un pase
para que caiga donde se quiere. `0x92E2` lo resuelve sin calcular nada.

Se miden las dos distancias al objetivo y se parten en escalones de dieciséis
—quedarse con el nibble alto—: sale un número de **0 a 15** para el ancho y
otro de **0 a 11** para el alto. Con esos dos se entra en dos tablas de dos
niveles al final del cartucho: la de `0xBF0F` da el empuje vertical y la de
`0xBD6F` las dos componentes del suelo.

Encima quedan dos correcciones. En el saque de banda el golpe se ablanda a
**tres cuartos** —o a la mitad si el objetivo está a menos de tres escalones
en las dos direcciones—, y en el saque de centro el empuje vertical y la
gravedad se **doblan**.

## Un bloque comprimido, dos camisetas

Los dos equipos comparten los mismos dibujos, y lo que cambia es la tabla de
COLOR. La escribe el mismo descompresor pasando cada byte por `0x4846`, que
parte el byte en sus dos nibbles —la tinta arriba, el fondo abajo—, mete cada
uno en una paleta de cinco entradas y los vuelve a juntar. A dónde apunta la
paleta lo dice `(0xE52A)`.

`0x6F31` deja cuatro volcados de patrón en `0x2320`, `0x2458`, `0x2590` y
`0x26C8` —dos derechos y dos espejados— y `0x742D` los pinta: los dos primeros
con la paleta de `0xE051` y los dos últimos con la de `0xE056`.

Las paletas se arman en **dos pasos**. `0x5A45` copia 39 bytes de fábrica a
`0xE050`, y después `0x5C02` machaca las entradas 2, 3 y 4 de cada una con el
juego de tres tonos elegido en el menú. Montando la pantalla sin ese segundo
paso, la tabla de COLOR sale distinta en **4.092 de sus 6.144 bytes**.

## Un `jp (bc)` escrito a mano

El Z80 tiene `jp (hl)`, pero no `jp (bc)`. En `0xB2DA` el cartucho lo escribe
a mano: apila BC y hace `ret`. Para cualquier trazador eso es el final de una
rutina, y detrás había **283 bytes** que nadie alcanzaba, con su tabla de
cinco entradas en `0xB2DC`.

Lo que fija la cuenta en cinco y no en seis es que la sexta palabra ya cae
fuera del cartucho. Es el **único** `push bc / ret` de los 32 KB.

## Dos marcadores comparados con una sola resta

Al final del partido hay que saber si hubo penaltis, o sea si los dos equipos
acabaron empatados. Cada marcador son dos bytes: la cifra en BCD y el acarreo,
y comparar dos parejas pide dos restas.

`0xB903` hace una. Arma **dos parejas cruzadas** —una cifra baja de cada
equipo con un acarreo de cada equipo— y las resta con un solo `sbc hl,bc` de
16 bits. El resultado es cero exactamente cuando coinciden las dos
comparaciones a la vez.

## La entrada que no sale acaba en choque

Robar la pelota depende del ángulo. `0xABCA` compara el rumbo del que entra
con el del que la lleva, y si coinciden —o van a cinco de distancia— el robo
sale con su pitido. Si no, chocan.

Al que la llevaba le caen **16 cuadros** quieto; al que entró se le redondea
el rumbo a la diagonal siguiente, se le pone el dibujo 4 —por el suelo— y
**resbala dos veces, ocho píxeles cada una y ocho cuadros entre ellas**, con
la pelota siguiéndole a los pies. Al levantarse, la lleva él.

Mientras dura, la física de la pelota **no corre**: las entradas 6 y 7 de la
tabla de `0x8C70` —el choque y el fuera de juego— son un `ret` pelado.

## Nadie corre en línea recta hacia la pelota

`0xB52A` decide hacia dónde mira cada ficha que no lleva un mando. Compara su
posición con la de la pelota, junta los dos bits que salen y con eso indexa la
tabla de `0xB578`. Los cuatro índices que alcanza dan **las cuatro
diagonales**: 2, 4, 8 y 6. Las dos primeras entradas de la tabla —el 1 y el 5,
derecha e izquierda— no las lee nadie.

Y hay un temblor encima. Cada ficha lleva un contador propio en su `+0x1B`, y
las dos instrucciones de `0xB55C` son las únicas de los 32 KB que lo tocan.
**De cada 64 cuentas, en nueve la ficha se olvida de la pelota y mira a la
portería contraria.** Como el contador sólo baja cuando a la ficha le toca
turno —y no le toca si está ocupada o si la lleva un mando—, los seis se
desincronizan solos y no se mueven como un banco de peces.

## Los diez tipos de saque, y los puestos

`(0xE533)` guarda qué saque hay en marcha, y los valores van del 1 al 10:

| | arriba | abajo |
|---|---|---|
| banda | 1 | 2 |
| esquina izquierda | 3 | 4 |
| esquina derecha | 5 | 6 |
| puerta izquierda | 7 | 8 |
| puerta derecha | 9 | 10 |

Quién lo saca sale de la lista de puestos de `(0xE410)`. Los saques sólo usan
seis códigos: el 3, el 4 y el 5 del primer bando y el 6, el 7 y el 8 del
segundo, y son **arriba, en medio y abajo**. La esquina de arriba la saca el 3
o el 6, la de abajo el 5 o el 8, y el saque de puerta el 4 o el 7. El saque de
la falta por fuera de juego elige con la misma regla, por la franja de campo
en que se pitó.

## Los dos fondos, escritos dos veces

`0x9853` y `0x9A46` hacen lo mismo con los números cambiados: los cuatro
píxeles de palo, el larguero, el gol y el saque que sale de ahí. **La red está
en el píxel `0x12` y en el `0x267`**: ahí se clava la pelota, con el sonido
`0x47`, y de paso se le recorta la altura para que no se salga por encima del
palo. El larguero devuelve **media velocidad** —`0x98A7` niega y divide entre
dos— y el poste sólo le cambia el signo al desvío.

## Las quince zonas del campo

`0xA219` parte el terreno en cinco franjas a lo ancho —los cortes están en
`0xD0`, `0x100`, `0x180` y `0x1B0`— por tres a lo alto —`0x49` y `0x78`— según
dónde esté la pelota, y deja el número en `(0xE52B)`. La formación del equipo
se saca de la tabla de `0xA880` con ese número: **5 × 3 × 12 bytes × 2 equipos
son los 360 bytes justos** que ocupa la tabla. La formación cambia según por
dónde ande el balón.

## La máquina pulsa el mando

Ni el guion de la demostración (`0x5965`), ni la inteligencia del penalti
(`0x6907`), ni la del partido mueven nada a mano: **escriben en el mismo byte
de mando que leería un humano**. Y el azar sale de los bits bajos del contador
de cuadros, `(0xE003)`.

## La misma tecla es pase y tiro

Soltarla es pase al compañero. Mantenerla **catorce cuadros** (`0x946C`) la
convierte en tiro, y entonces el objetivo deja de ser un jugador y pasa a ser
una portería: el píxel 15 o el 624 de los 640 del campo.

## Código muerto, y tres rarezas

- **Los trozos de `0xAAEE` y `0xAAFA` no se ejecutan nunca.** Sólo corren si
  `(0xE545)` vale 1, y `(0xE545)` aparece **una** vez en los 32 KB, que es una
  lectura. Además `0x5648` borra `0xE100`-`0xE5FF` al montar cada jugada.
- **Un salto a mitad de instrucción.** `0xAEAF` trae `28 01` —un `jr z,+1`— y
  aterriza en `0xAEB2`, que no es una instrucción sino el operando del
  `ld l,0C0h` de `0xAEB1`. Ese `0xC0` suelto se ejecuta como `ret nz`, y como
  a `0xAEB2` sólo se llega con Z, nunca retorna. Es la única etiqueta del
  cartucho que no cae en posición emitida. No ahorra ni un byte ni un ciclo,
  así que es rareza y no truco.
- **Dos escrituras muertas a la propia ROM**: `0x4028` escribe en `(0x410A)` y
  `0x4056` en `(0x4116)`. Los bytes no cambian, claro.
- **Una lectura muerta y un `jr` que no salta**: el `ld a,(0e003h)` de
  `0xB97D` no lo mira nadie —`0xB9AE` machaca A en sus tres caminos— y el
  `jr` de `0xB9A5` va a `0xB9A7`, que es la instrucción siguiente.
