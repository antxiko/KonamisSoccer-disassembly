# Konami's Soccer (Konami, 1985) — desensamblado comentado

Desensamblado completo y comentado del cartucho de MSX1 **Konami's Soccer**
(Konami, número de catálogo **RC-732**, 32 KB), reproducible byte a byte.

**Web: <https://antxiko.github.io/KonamisSoccer-disassembly/es/>** · [In English](README.md)

|  |  |
|---|---|
| Del binario explicado | **100 %** — 0 bytes sin asignar, de 32.768 |
| Reensambla | **byte a byte**, al mismo sha256 |
| Del listado comentado | **36,5 %** — 3.561 comentarios sobre 9.755 instrucciones |
| Rutinas por debajo del listón del 10 % | **0** de 1.213 |
| Instrucciones distintas de Konami's Football | **1** de 9.755 |
| Imágenes cotejadas contra la VRAM del emulador | título **0** bytes distintos, campo **0** |

## Qué hay aquí

    src/soccer.asm            el listado, generado
    src/soccer.notes          lo que se entiende: bloques de datos y comentarios
    src/soccer.entries        los puntos de entrada, cada uno con su razón
    src/soccer.nocode         los rangos que no son código
    tools/                    el trazador, el generador de listado y las comprobaciones
    tests/                    39 tests sobre el listado y la web
    docs/                     la web, en castellano y en inglés

El cartucho **no** se distribuye. Hay que ponerlo en la raíz como
`soccer.rom`; `make comprueba` verifica su sha256.

## Rehacerlo

    make

Traza el flujo, escribe el listado, lo reensambla y comprueba que el resultado
es la ROM byte a byte; luego corre las comprobaciones de cordura y los tests.
Ver [Empezar](https://antxiko.github.io/KonamisSoccer-disassembly/es/EMPEZAR.html).

## Algo de lo que apareció

- **Se pita el fuera de juego.** Tres condiciones comprobadas en el momento del
  pase, la falta anulada si la pelota rebotó en alguien por el camino y, contra
  la máquina, la regla sólo existe **del nivel 3 en adelante**.
- **Seis jugadores son casillas y seis son sprites.** Un bando se estampa como
  parches de 3x3 sobre un mapa de campo de 80 columnas guardado en la RAM; el
  otro se dibuja con cinco sprites cada uno. Así caben doce jugadores en una
  máquina que sólo saca cuatro sprites por línea.
- **La puntería no se calcula: se consulta.** Dos distancias, partidas en
  escalones de dieciséis, indexan dos tablas de dos niveles al final del
  cartucho.
- **Un bloque comprimido, dos camisetas.** Los mismos dibujos, recoloreados al
  vuelo con una paleta de cinco entradas mientras se descomprimen.
- **Un `jp (bc)` escrito a mano** —`push bc / ret`— que escondía 283 bytes de
  código al trazador.
- **La marca oculta de Konami** en los trece últimos bytes, un hallazgo de
  **Manuel Pazos**.
- Y **una instrucción de 9.755** es todo lo que separa este cartucho de
  **Konami's Football**, el mismo RC-732 con otro nombre: el `ld c,nn` que dice
  cuántas filas de tiles mide el rótulo del título. Ver
  [La otra compilación](https://antxiko.github.io/KonamisSoccer-disassembly/es/LA-OTRA-COMPILACION.html).

Todo, con la medida al lado de cada afirmación, en
[Hallazgos](https://antxiko.github.io/KonamisSoccer-disassembly/es/HALLAZGOS.html).

## Las imágenes están dibujadas desde la ROM

Aquí no hay ni una captura de pantalla. `tools/graficos.py` monta las pantallas
ejecutando en Python los mismos pasos que corre el Z80, y
`tools/coteja_vram.py` compara el resultado byte a byte contra un volcado de
VRAM sacado de openMSX.

## Licencia

Las herramientas, las notas y la web se publican con licencia MIT (ver
[LICENSE](LICENSE)). El código y los gráficos del juego siguen siendo de sus
autores y de Konami; ver [AVISO-LEGAL.md](AVISO-LEGAL.md).
