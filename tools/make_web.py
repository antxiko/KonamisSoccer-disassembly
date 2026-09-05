#!/usr/bin/env python3
"""Genera la portada de la web de Konami's Soccer, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibuja tools/graficos.py a
partir de los propios bytes de la ROM, ejecutando en Python el descompresor y
el interprete de rotulos que corre el Z80. Ninguna se ha retocado, y las cuatro
estan cotejadas byte a byte contra la VRAM del emulador con tools/coteja_vram.py.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a
# ojo: 32768 = 20116 + 12652, que es lo que imprime tools/presupuesto.py
# (make sanity). RUTINAS son los bloques con nombre que cuenta densidad.py y
# DENSIDAD la proporcion de instrucciones comentadas, las dos de
# tools/densidad.py (make densidad).
CODIGO = 20116
DATOS = 12652
RUTINAS = 1213
INSTRUCCIONES = 9755
COMENTARIOS = 3561
DENSIDAD = "36,5"
DENSIDAD_EN = "36.5"


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Konami's Soccer - desensamblado comentado",
        aviso="<b>Aqui no hay ninguna captura.</b> Todas las imagenes estan "
              "<b>dibujadas desde los bytes de la ROM</b>, ejecutando en "
              "Python el descompresor y el interprete de rotulos que corre el "
              "Z80, y <b>cotejadas byte a byte contra la VRAM de openMSX</b>: "
              "el titulo da cero diferencias y el campo tambien. El listado y "
              "las cifras se reproducen con <code>make</code>, y el "
              "reensamblado devuelve la ROM <b>byte a byte</b>.",
        claim="Un futbol de 1985 que <b>pita el fuera de juego</b> -y solo "
              "del nivel 3 en adelante cuando juegas contra la maquina-, doce "
              "jugadores que no son sprites sino parches de tres por tres "
              "casillas sobre un campo de ochenta columnas guardado en la "
              "RAM, y una punteria que no se calcula: se consulta en dos "
              "tablas.",
        ficha=["Konami - <b>(c) Konami 1985</b>",
               "Cartucho <b>RC-732</b>, 32 KB",
               "MSX1 - <b>paginas 1 y 2</b>", "Volcado <b>b9536809...</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El codigo"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que aparecio al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas con nombre"),
                (DENSIDAD + " %", "del listado comentado"),
                (mil(CODIGO, "es"), "bytes de codigo"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen esta de donde sale y que se esta "
                 "viendo.",
        pie_leg="Esto es trabajo de documentacion y preservacion: el codigo y "
                "los graficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Konami's Soccer - a commented disassembly",
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from "
              "the bytes of the ROM</b>, by running in Python the same "
              "decompressor and label interpreter the Z80 runs, and then "
              "<b>checked byte for byte against openMSX's VRAM</b>: the title "
              "screen comes out with zero differences, and so does the pitch. "
              "The listing and the numbers are reproducible with "
              "<code>make</code>, and reassembling gives back the ROM "
              "<b>byte for byte</b>.",
        claim="A 1985 football game that <b>calls offside</b> -and only "
              "from level 3 up when you play the machine-, twelve players "
              "that are not sprites but three-by-three tile patches over an "
              "eighty-column pitch held in RAM, and an aim that is never "
              "computed: it is looked up in two tables.",
        ficha=["Konami - <b>(c) Konami 1985</b>",
               "An <b>RC-732</b> 32 KB cartridge",
               "MSX1 - <b>pages 1 and 2</b>", "Dump <b>b9536809...</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "named routines"),
                (DENSIDAD_EN + "%", "of the listing commented"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

# El contenido propio de este cartucho vive aparte, en contenido_web.py:
# asi el generador no lleva dentro ni un texto del juego anterior.
from contenido_web import HALLAZGOS, GALERIA        # noqa: E402


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que el propio cartucho pinta en su pantalla de titulo, dibujado desde la
    # ROM por graficos.py. Si el PNG no esta, el trabajo NO esta hecho: se cae
    # al texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Konami&#39;s Soccer">'
                if os.path.exists(ruta_logo)
                else "<h1>Konami&#39;s Soccer</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        # un "{}" en el nombre se sustituye por el idioma: asi la lamina de
        # figuras sale rotulada en el idioma de la pagina
        if "{}" in fich:
            fich = fich.format("" if idioma == "es" else "_" + idioma)
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' - '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
