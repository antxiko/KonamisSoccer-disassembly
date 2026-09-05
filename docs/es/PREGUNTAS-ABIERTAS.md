# Preguntas abiertas

Lo que **no** se sabe, dicho tal cual. Los 32.768 bytes están explicados y el
listado reproduce la ROM byte a byte, pero eso no quiere decir que todo tenga
sentido.

## Los veintisiete `push hl / ret`

El repartidor de `0xB2DA` es un `push bc / ret`, un `jp (bc)` escrito a mano,
y escondía 283 bytes de código. Es el único `push bc / ret` del cartucho, pero
hay **veintisiete** `push hl / ret`, y no se han repasado uno a uno. La mayoría
serán retornos apilados a mano —hay unos cuantos, y están comentados—, pero si
alguno esconde otro salto indirecto, ahí queda cobertura por ganar.

## Cuatro variables sin nombre

- `(0xE551)` — se borra en cada subestado que no sea el 1, y se limpia también
  al coger la pelota. No se ha visto quién la pone.
- `(0xE566)` y `(0xE567)` — los dos se llaman "cerrojos del rebote" en el
  listado porque se limpian juntos antes de un robo, pero qué cuentan
  exactamente no está cerrado.
- `(0xE546)` sí se sabe: marca que la pelota rebotó en alguien en vez de
  dejarse controlar, y es lo que anula el fuera de juego. Se pone en `0xAA63`
  y se quita en `0xAAB8`.

## Por qué a la pelota se le supone un rumbo

Al coger la pelota, `0xAAC2` mira el modo del que la coge: si venía andando,
`(0xE53A)` se pone a **3**; si estaba parado, a **0**. Ese 3 no se ha
explicado. Por qué precisamente ese valor, y qué diferencia hace después, sigue
abierto.

## La tabla de demora de dos humanos es más rápida

`0xA85E` tiene dos tablas de cinco bytes indexadas por el nivel:

    10 0E 0C 0A 08     y     0B 0A 08 06 04

La primera es la de la partida contra la máquina; la segunda sale con dos
jugadores. Los cuadros de reacción de la segunda son **menores**, o sea que
las fichas que no lleva nadie reaccionan más rápido cuando hay dos humanos.
Tiene su lógica —las doce están repartidas entre dos mandos, y ninguna es "de
la máquina"—, pero no se ha comprobado sobre el juego.

## El emparejamiento a cinco de distancia

`0xABCE` decide si una entrada sale comparando rumbos. Además del choque
frontal, acepta que estén **a cinco de distancia**: con los rumbos numerados
del 1 al 8, lo natural sería cuatro —el opuesto—, y cinco empareja el 1 con el
6, el 2 con el 7 y el 3 con el 8. Puede ser una tolerancia buscada, o un
desplazamiento heredado de cómo se numeran los rumbos. No está cerrado.

## Un `inc l` que quizá sobra

En `0xA741` hay un `inc l` que deja el puntero en la parte fina de la X y no en
la altura. Si es un fallo, el efecto sería pequeño y difícil de ver jugando; si
no lo es, falta entender qué se está indexando. Se deja apuntado.

## Los diecisiete bytes de la cabecera del Game Master

La segunda cabecera "AB" de `0x4010` es la del **Konami Game Master**, y eso
está cerrado. Lo que no está es el reparto de los diecisiete bytes que van
detrás, en `0x4014`. Leídos como palabras dan `0x6700`, `0xE000` y `0xE002`
—las dos variables de cabecera del juego, que encajan—, y luego ceros y un
`0x05`. Pero **ese reparto no es común a los otros tres cartuchos** que llevan
la cabecera, así que aquí queda como lectura razonada y no como hecho.

## Cuál de los dos equipos es "el bueno"

El bando 0 ataca a la izquierda y el 1 a la derecha; el mando 1 lleva al 0 y
el 2 al 1. Pero **cuál de los dos se dibuja con parches y cuál con sprites
depende de `(0xE527)`**, que es el bando que lleva la cámara, o sea el que
tiene la pelota. Es decir: el reparto **cambia durante el partido**. Lo que no
se ha medido es si eso se nota jugando —si el equipo dibujado con sprites
parpadea más, por ejemplo—.

## La demostración

La demostración de la presentación no es una partida calculada: es un **guion
grabado** (`0x5965`) que escribe en los bytes de mando. Lo que no se ha
extraído es el guion en sí, ni cuánto dura, ni si es siempre el mismo partido.
