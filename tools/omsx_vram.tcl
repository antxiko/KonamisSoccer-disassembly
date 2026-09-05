# omsx_vram.tcl - Vuelca la VRAM de verdad del cartucho, para comprobar los PNG.
#
# Para que sirve: tools/graficos.py monta las imagenes ejecutando en Python los
# pasos del cartucho (el descompresor L_47B7, el espejo de L_4836, la
# traduccion de color de 0x4846 y el interprete de rotulos L_46CE). Mirar el
# dibujo no basta: hay que comparar sus bytes con los que el VDP tiene de
# verdad. Esto deja correr el juego y en varios instantes vuelca los 16 KB de
# VRAM, los ocho registros del VDP y las variables que dicen QUE se estaba
# dibujando.
#
# No pone NINGUN punto de ruptura: los volcados van por reloj emulado, que es
# lo unico que no ahoga al emulador.
#
# Variables de entorno:
#   SO_SALIDA  carpeta de salida (por defecto work/omsx)
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart soccer.rom -script tools/omsx_vram.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion SO_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/SOCCER_DISAM/work/omsx}]
file mkdir $::SALIDA
set ::n 0

proc vuelca {etiqueta} {
    set i [format %02d $::n]
    incr ::n
    # los 16 KB de VRAM tal cual los ve el VDP: el cartucho pone R1 = 0xE2, o
    # sea modo de 16K, asi que por encima de 0x4000 no hay nada que mirar
    set datos [debug read_block VRAM 0 16384]
    set f [open $::SALIDA/vram_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f $datos
    close $f
    # y la RAM de trabajo entera, de 0xE000 a 0xEFFF: ahi viven las dos
    # paletas de camiseta (0xE051 y 0xE056), las doce fichas (0xE100) y el
    # mapa del campo de 80x23 casillas (0xE600), que tambien hay que cotejar
    set ram [debug read_block memory 0xE000 4096]
    set f [open $::SALIDA/ram_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f $ram
    close $f
    # los ocho registros, que dicen donde esta cada tabla
    set r {}
    for {set k 0} {$k < 8} {incr k} {
        lappend r [format %02X [debug read {VDP regs} $k]]
    }
    set f [open $::SALIDA/info_$i.txt w]
    puts $f [format {etiqueta %s} $etiqueta]
    puts $f [format {tiempo %s} [machine_info time]]
    puts $f [format {regs %s} [join $r { }]]
    # Las variables de trabajo empiezan en 0xE000. Estos nombres son los del
    # listado de Konami's Soccer, no los de una plantilla: 0xE000 es la escena
    # que reparte 0x40C8 y 0xE001 el escalon de la cadena de `djnz`; 0xE002
    # lleva en el bit 5 si hay dos jugadores y en el 6 si se esta jugando;
    # 0xE003 es el reloj de cuadros; 0xE050 el paso del menu y 0xE069 el nivel;
    # 0xE280 el subestado del partido y 0xE281 el de la pelota; 0xE2C1 por
    # donde va la ventana del campo, que es lo que decide que 32 de las 80
    # columnas del mapa se ven; 0xE0F5 y 0xE0F6 los dos goles, en BCD.
    foreach {nombre dir} {escena 0xE000 subescena 0xE001 modo 0xE002
                          reloj 0xE003 espera 0xE004 paso_del_menu 0xE050
                          nivel 0xE069 subestado 0xE280 subestado_pelota 0xE281
                          ventana 0xE2C1 goles_1 0xE0F5 goles_2 0xE0F6} {
        puts $f [format {%s %d} $nombre [debug read memory $dir]]
    }
    close $f
    catch { screenshot -raw $::SALIDA/pant_$i.png }
}

# --- la barra de espacio, que es con lo que se elige y se saca ---------------
proc pulsa {} {
    keymatrixdown 8 0x01
    after time 0.4 suelta
}
proc suelta {} {
    keymatrixup 8 0x01
}

# --- calendario -------------------------------------------------------------
# El cartucho arranca por la escena del logotipo y de ahi pasa al titulo y al
# menu; antes de los 6 s la VRAM esta a medio pintar y no es comparable con
# nada. Se pulsa espacio para cruzar el menu y arrancar el partido, y a partir
# de ahi los volcados cogen el campo ya montado.
after time  6.0 { vuelca arranque }
after time 10.0 { vuelca titulo }
after time 14.0 { vuelca titulo }
after time 18.0 { vuelca titulo }
after time 22.0 { pulsa }
after time 24.0 { pulsa }
after time 26.0 { pulsa }
after time 28.0 { pulsa }
after time 34.0 { vuelca campo }
after time 40.0 { vuelca campo }
after time 46.0 { vuelca campo }
after time 48.0 { exit }

# perro guardian de tiempo REAL: un guion roto no puede colgar el emulador
after realtime 240 {
    puts {PERRO GUARDIAN a los 240 s reales}
    exit
}
