# Empezar

El repositorio trae el listado ya generado, pero lo que de verdad importa es
que se puede **rehacer entero desde el cartucho** y que el resultado vuelve a
ser la ROM byte a byte. Eso es lo que hace que las notas se puedan creer.

## Lo que hace falta

- **Python 3** (nada más: ni una dependencia)
- **pasmo**, el ensamblador de Z80, para la prueba del reensamblado
- **make**
- Para las comprobaciones contra la máquina, **openMSX**

## El cartucho

No viaja con el repositorio. Hay que ponerlo en la raíz como `soccer.rom`,
32.768 bytes exactos:

    b9536809a1784afb2e49a43d80ba9c6c8c15cd31ecbd6c284e9bf62c6927dcd4

Para comprobar que es el mismo:

    make comprueba

## Rehacerlo todo

    make

Eso encadena las cuatro cosas que importan:

| paso | qué hace |
|---|---|
| `make listado` | traza el flujo desde los puntos de entrada y escribe `src/soccer.asm` |
| `make verify` | reensambla con pasmo y compara el sha256 con el del cartucho |
| `make sanity` | lo que el reensamblado NO puede cazar (ver abajo) |
| `make test` | los 39 tests |

## Por qué `make verify` no basta

El reensamblado demuestra que los **bytes** son los mismos, no que lo que
decimos de ellos sea cierto. Un rango de gráficos leído como código sale
idéntico al reensamblar —los bytes no cambian, cambia cómo se leen— y de paso
infla la cobertura. Por eso `make sanity` corre otras tres comprobaciones:

| comprobación | qué vigila |
|---|---|
| `check_trace.py` | que las zonas del `.nocode` no se hayan trazado como código |
| `check_datos_como_codigo.py` | que ninguno de los **125 rangos de datos** declarados salga como código |
| `check_entradas.py` | que ningún punto de entrada caiga dentro de una zona de datos |
| `presupuesto.py` | que código y datos sumen los 32.768 bytes, sin huecos |

## Lo demás

    make densidad     # cuántas instrucciones llevan comentario, rutina a rutina
    make imagenes     # dibuja las cinco láminas desde la ROM
    make vram         # las coteja byte a byte contra la VRAM de openMSX
    make web          # regenera esta web

## Dónde está cada cosa

| fichero | qué es |
|---|---|
| `src/soccer.asm` | el listado, generado |
| `src/soccer.notes` | las anotaciones: nombres, comentarios y rangos de datos |
| `src/soccer.entries` | los puntos de entrada que no se deducen solos, cada uno justificado |
| `src/soccer.nocode` | los rangos que el trazador no debe pisar |
| `tools/` | el trazador, el generador de listado, el descompresor y los dibujantes |
| `tests/` | los 39 tests, que corren sin el cartucho |

Los tests no necesitan la ROM: reconstruyen los bytes de datos leyendo las
filas `defb` del propio listado, que llevan su dirección en el comentario.
