; ==========================================================================
; KONAMI'S SOCCER - Konami - MSX1 - cartucho RC-732 de 32 KB en las paginas 1 y 2
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Etiquetas que no caen en ninguna posicion emitida del listado
; (destinos fuera del binario o dentro de una instruccion).
; ----------------------------------------------------------------------
L_AEB2:	equ 0x0aeb2

; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
l4440h:	equ 0x04440
l8fech:	equ 0x08fec
laf34h:	equ 0x0af34
lb244h:	equ 0x0b244
lb4c2h:	equ 0x0b4c2

; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x4070);
;   STATEMENT, DEVICE y TEXT a cero, y los seis bytes reservados tambien
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,04070h,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ----------------------------------------------------------------------
; DATOS cabecera_del_game_master: "AB", el 0x07 de RC-7xx y el 0x32 de RC-732;
;   la lee el Konami Game Master desde la otra ranura, no este cartucho. Solo
;   cuatro de las 46 ROM de la coleccion la llevan
;   0x4010..0x4014  (4 bytes)
DATA_cabecera_del_game_master:
	defb 041h	; 4010
	defb 042h	; 4011
	defb 007h	; 4012
	defb 032h	; 4013

; ----------------------------------------------------------------------
; DATOS punteros_del_game_master: diecisiete bytes que en este cartucho se
;   leen como 0x6700, 0xE000 y 0xE002 -las dos variables de cabecera del
;   juego- y luego ceros y un 0x05. El reparto NO es comun a los otros tres
;   cartuchos que llevan la cabecera, asi que queda como lectura razonada
;   0x4014..0x4025  (17 bytes)
DATA_punteros_del_game_master:
	defw 06700h,0e000h,0e002h,00000h,00000h,00000h,00000h,00000h	; 4014
	defb 005h	; 4024

; ======================================================================
; CODIGO 0x4025..0x40e3  (190 bytes)
; ======================================================================


L_4025:
	ld hl,0c9e1h		;4025
	ld (0410ah),hl		;4028
	jp carga_los_tiles_del_logotipo		;402b

; ----------------------------------------------------------------------
; ===== EL LATIDO: el gancho de la interrupcion =====
; ----------------------------------------------------------------------
latido:		; H.KEYI: todo el juego cuelga de aqui, una vez por cuadro
	call 0013eh		;402e   ; BIOS RDVDP - Reads VDP status register | RDVDP: leer el estado del VDP es lo que ACEPTA la interrupcion
	di			;4031   ; con la interrupcion cerrada, el sonido: es lo unico que no puede perder un cuadro
	call tic_del_sonido		;4032
	ld hl,0e005h		;4035   ; (0xE005) es el cerrojo de reentrada
	bit 0,(hl)		;4038   ; si ya hay un cuadro dentro, no se entra otra vez
	jr nz,L_4049		;403a
	inc (hl)			;403c   ; echa el cerrojo
	ei			;403d   ; y lo demas ya puede correr con la interrupcion abierta
	call lee_los_mandos		;403e   ; primero lo que toca al VDP, que es lo que tiene prisa
	call corre_la_escena		;4041   ; y despues la escena que toque
	ld a,000h		;4044   ; suelta el cerrojo
	ld (0e005h),a		;4046
L_4049:
	call 0013eh		;4049   ; BIOS RDVDP - Reads VDP status register | segunda lectura del estado del VDP
	or a			;404c   ; el bit 7 es el aviso de interrupcion
	di			;404d
	call m,tic_del_sonido		;404e   ; si estaba puesto, otra pasada de sonido
	ei			;4051
	ret			;4052
pone_registro_del_vdp:		; escribe un registro del VDP, y de paso borra su copia
	ld hl,00000h		;4053
	ld (04116h),hl		;4056   ; 0x4116 cae dentro de la propia ROM, o sea que esta escritura no llega a ninguna parte
	jp 00047h		;4059   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP con lo que traiga BC

; ----------------------------------------------------------------------
; ===== Las dos sumas de 8 sobre 16 bits =====
; ----------------------------------------------------------------------
suma_a_hl:		; HL = HL + A, con el acarreo a mano
	add a,l			;405c
	ld l,a			;405d
	ret nc			;405e   ; si no hubo acarreo ya esta
	inc h			;405f   ; y si lo hubo, sube el byte alto
	ret			;4060
suma_a_de:		; DE = DE + A, la misma cuenta sobre el otro par
	add a,e			;4061
	ld e,a			;4062
	ret nc			;4063
	inc d			;4064
	ret			;4065

; ----------------------------------------------------------------------
; ===== EL DESPACHADOR, con la tabla pegada detras =====
; ----------------------------------------------------------------------
despacha:		; salta a la entrada A de la tabla que venga pegada detras del `call`
	pop hl			;4066   ; el `pop` recupera la direccion de retorno, que ES la tabla
	add a,a			;4067   ; el indice se dobla porque las entradas son palabras
	call suma_a_hl		;4068   ; y se le suma a la direccion de la tabla
	ld e,(hl)			;406b   ; saca la entrada
	inc hl			;406c
	ld d,(hl)			;406d
	ex de,hl			;406e
	jp (hl)			;406f   ; y salta ahi, sin volver: la tabla se ha comido el retorno

; ----------------------------------------------------------------------
; ===== INIT: lo unico que hace es enganchar la interrupcion =====
; ----------------------------------------------------------------------
init:		; la direccion que trae la cabecera del cartucho
	di			;4070
	im 1		;4071
	call 00138h		;4073   ; BIOS RSLREG - Reads the primary slot register | RSLREG y la cuenta de los cuatro bytes de 0xFCC1: de que ranura se esta ejecutando esto
	rrca			;4076
	rrca			;4077
	and 003h		;4078
	ld c,a			;407a
	ld b,000h		;407b
	ld hl,0fcc1h		;407d
	add hl,bc			;4080
	or (hl)			;4081
	ld c,a			;4082
	inc hl			;4083
	inc hl			;4084
	inc hl			;4085
	inc hl			;4086
	ld a,(hl)			;4087
	and 00ch		;4088
	or c			;408a
	ld h,080h		;408b   ; la pagina 2, que es la mitad de arriba del cartucho
	call 00024h		;408d   ; BIOS ENASLT - Switches to specified slot and page definitively | ENASLT deja la ranura puesta para siempre: son 32 KB, no caben en una pagina
	ld a,0c3h		;4090   ; un 0xC3, o sea un `jp`, en el primer byte de H.KEYI
	ld (0fd9ah),a		;4092
	ld hl,latido		;4095   ; y detras la direccion del latido
	ld (0fd9bh),hl		;4098
	ld sp,0f380h		;409b   ; la pila, por debajo de las variables
	ld hl,0e000h		;409e   ; borra los 0x1380 bytes de variables de 0xE000 en adelante
	ld de,0e001h		;40a1
	ld bc,0137fh		;40a4
	ld (hl),000h		;40a7
	ldir		;40a9
	ld a,001h		;40ab   ; echa el cerrojo ANTES de tocar el VDP
	ld (0e005h),a		;40ad
	call prepara_la_pantalla		;40b0   ; prepara la pantalla
	call pon_el_estado_de_fabrica		;40b3   ; y el resto del arranque
	xor a			;40b6
	ld (0e005h),a		;40b7   ; suelta el cerrojo
	call 0013eh		;40ba   ; BIOS RDVDP - Reads VDP status register | acepta la interrupcion que hubiera pendiente
	ei			;40bd
L_40BE:
	jr L_40BE		;40be   ; a partir de aqui no hace nada mas: el juego entero corre en la interrupcion
L_40C0:
	ld hl,0488ah		;40c0
	res 6,(hl)		;40c3
	jp pide_un_sonido_siempre		;40c5

; ----------------------------------------------------------------------
; ===== La escena del cuadro =====
; ----------------------------------------------------------------------
corre_la_escena:		; mira el estado y despacha la escena que toque
	ld hl,0e003h		;40c8   ; (0xE003) es el contador de cuadros, y sube uno por interrupcion
	inc (hl)			;40cb
	ld a,(0e002h)		;40cc   ; el bit 6 de (0xE002) distingue la partida de la presentacion
	and 040h		;40cf
	jr nz,L_40D6		;40d1
	ld hl,04564h		;40d3   ; fuera de la partida, 0x4564 va a la pila como retorno de la escena
L_40D6:
	ld bc,(0e000h)		;40d6   ; (0xE000) trae la escena en C y su subestado en B
	ld a,c			;40da
	cp 003h		;40db   ; las tres primeras escenas son las que llevan ese retorno detras
	jr nc,L_40E0		;40dd
	push hl			;40df
L_40E0:
	call despacha		;40e0   ; y a la tabla de nueve que va pegada aqui detras

; ----------------------------------------------------------------------
; DATOS tabla_de_escenas: 9 entradas, la mas alta del juego: reparte segun
;   (0xE000) el logotipo, el titulo, el partido y el final
;   0x40e3..0x40f5  (18 bytes)
DATA_tabla_de_escenas:
	defw 040f5h,04127h,041a2h,041cfh,04208h,042cdh,042ddh,043f7h	; 40e3
	defw 04539h	; 40f3  -> escena_final

; ======================================================================
; CODIGO 0x40f5..0x4889  (1940 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== ESCENA 0: la presentacion se monta =====
; ----------------------------------------------------------------------
escena_presentacion:		; tres pasos, contados hacia atras con el `djnz` de la escena
	djnz escena_presentacion_2		;40f5   ; el subestado llega en B, y cada `djnz` se come uno: B=1 sigue aqui, B=2 salta al segundo, B=3 al tercero
	ld a,(0e003h)		;40f7   ; el contador de cuadros
	rra			;40fa   ; el bit 0: uno de cada dos cuadros
	ret nc			;40fb
	call sube_el_logotipo_una_fila		;40fc   ; va bajando la cortina, y avisa cuando ha terminado
	ret nz			;40ff
	ld de,04939h		;4100   ; el rotulo, con su destino de VRAM dentro del propio bloque
	call descomprime_con_destino_dentro		;4103
	xor a			;4106
	jp espera_n_y_avanza_paso		;4107   ; y a esperar 32 cuadros
escena_presentacion_2:		; el segundo paso: espera y limpia
	djnz escena_presentacion_3		;410a
	ld hl,0e004h		;410c   ; la cuenta de espera
	dec (hl)			;410f
	ret nz			;4110   ; hasta que no llegue a cero no se sigue
	call monta_la_pantalla_de_titulo		;4111
	xor a			;4114
	jp espera_n_y_avanza_escena		;4115
escena_presentacion_3:		; el tercero: la pantalla entera de nuevo
	call pone_la_pantalla		;4118   ; los ocho registros del VDP
	call limpia_la_pantalla		;411b
	call carga_la_fuente		;411e
	call arranca_el_logotipo_de_konami		;4121   ; y los patrones de la cortina
	jp avanza_paso		;4124

; ----------------------------------------------------------------------
; ===== ESCENA 1: el logotipo, que entra por partes =====
; ----------------------------------------------------------------------
escena_logotipo:		; (0xE55E) es una mascara de bits: cada bit, un trozo que falta por entrar
	call copia_los_sprites		;4127
	ld a,(0e003h)		;412a   ; el contador de cuadros
	rra			;412d
	jr c,L_4134		;412e
	ld hl,0e558h		;4130   ; (0xE558) es el reloj de la escena, y solo avanza un cuadro de cada dos
	inc (hl)			;4133
L_4134:
	ld a,(0e55eh)		;4134   ; la mascara de lo que queda por hacer
	rra			;4137   ; se va mirando bit a bit, de arriba abajo
	rra			;4138
	jr c,L_417A		;4139
	rra			;413b
	jr c,L_4161		;413c
	rra			;413e
	jr c,L_4155		;413f
	rra			;4141
	jr c,L_4146		;4142
	jr L_419B		;4144
L_4146:
	call corre_el_jugador		;4146   ; el trozo que toque
	call el_chute		;4149
	ld a,(0e558h)		;414c   ; cada trozo tiene su instante: aqui el 0x78 del reloj
	cp 078h		;414f
	jr nz,L_418B		;4151
	jr L_4184		;4153
L_4155:
	call el_trallazo		;4155   ; otro trozo, y su instante 0x79
	ld a,(0e558h)		;4158
	cp 079h		;415b
	jr nz,L_418B		;415d
	jr L_4184		;415f
L_4161:
	call L_6CDD		;4161   ; otro, en el 0x94; ademas arranca el sonido y enciende (0xE55C)
	ld a,(0e558h)		;4164
	cp 094h		;4167
	jr nz,L_418B		;4169
	call para_la_pelota		;416b
	ld a,0e8h		;416e
	ld (0e2a1h),a		;4170
	ld a,001h		;4173
	ld (0e55ch),a		;4175
	jr L_4184		;4178
L_417A:
	call corre_el_jugador_despacio		;417a   ; el ultimo, en el 0xF0
	ld a,(0e558h)		;417d
	cp 0f0h		;4180
	jr nz,L_418B		;4182
L_4184:
	ld hl,0e55eh		;4184   ; hecho el trozo, se apaga su bit y se pasa al siguiente
	sra (hl)		;4187
	jr L_418B		;4189
L_418B:
	call dibuja_al_jugador_del_logotipo		;418b   ; lo que se hace en todos los cuadros, haya trozo o no
	call mueve_y_dibuja_la_pelota_del_logotipo		;418e
	call mueve_y_dibuja_la_pelota_del_logotipo		;4191
	ld a,(0e003h)		;4194   ; y una pasada mas uno de cada dos cuadros
	rra			;4197
	call c,parpadea_el_cursor_del_menu		;4198
L_419B:
	ld a,(0e55eh)		;419b   ; cuando ya no queda ningun bit encendido, la escena ha terminado
	rra			;419e
	ret nc			;419f
	jr espera_y_avanza_escena		;41a0

; ----------------------------------------------------------------------
; ===== ESCENA 2: la espera del titulo =====
; ----------------------------------------------------------------------
escena_titulo:		; espera a que alguien pulse, o a que se acabe el tiempo
	djnz escena_titulo_2		;41a2
	ld a,(0e00bh)		;41a4   ; el bit 0 de (0xE00B)
	rra			;41a7
	call c,mueve_el_guion_de_la_demostracion		;41a8
	call un_cuadro_de_la_demostracion		;41ab   ; el mando
	ld a,(0e0f1h)		;41ae   ; (0xE0F1) mientras no sea cero, se sigue esperando
	or a			;41b1
	ret nz			;41b2
L_41B3:
	xor a			;41b3   ; se vuelve a la escena 0: la presentacion da otra vuelta
	ld (0e000h),a		;41b4
	ld a,020h		;41b7   ; con 32 cuadros de espera
	ld (0e004h),a		;41b9
	jr empieza_la_escena		;41bc
escena_titulo_2:		; el segundo paso, ya con la pulsacion hecha
	call baja_la_cortina		;41be   ; espera a que la cortina termine
	ret p			;41c1
	call arranca_la_demostracion		;41c2
espera_y_avanza_paso:		; pone 0x20 cuadros de espera y pasa al paso siguiente
	ld a,020h		;41c5
espera_n_y_avanza_paso:		; la espera llega en A
	ld (0e004h),a		;41c7
avanza_paso:		; (0xE001) es el paso dentro de la escena
	ld hl,0e001h		;41ca
	inc (hl)			;41cd
	ret			;41ce

; ----------------------------------------------------------------------
; ===== ESCENA 3: el rotulo que parpadea =====
; ----------------------------------------------------------------------
escena_rotulo:		; mientras corre la cuenta atras, enciende y apaga un rotulo
	djnz escena_rotulo_2		;41cf
	ld hl,0e004h		;41d1
	dec (hl)			;41d4   ; la cuenta atras
	jr z,avanza_paso		;41d5   ; al llegar a cero, al paso siguiente
	ld a,(0e002h)		;41d7
	bit 5,a		;41da   ; el bit 5 de (0xE002) elige cual de los dos rotulos
	ld de,04967h		;41dc
	jr z,L_41E4		;41df
	ld de,04971h		;41e1
L_41E4:
	bit 2,(hl)		;41e4   ; el bit 2 de la propia cuenta es lo que hace el parpadeo: cuatro cuadros puesto y cuatro quitado
	jp z,escribe_un_rotulo		;41e6   ; una puerta lo pinta...
	jp borra_un_rotulo		;41e9   ; ...y la otra lo borra
escena_rotulo_2:		; el segundo paso
	djnz escena_rotulo_3		;41ec
	call borra_las_variables_del_partido		;41ee
espera_y_avanza_escena:		; 0x20 cuadros y a la escena siguiente
	ld a,020h		;41f1
espera_n_y_avanza_escena:		; la espera llega en A
	ld (0e004h),a		;41f3
avanza_escena:		; (0xE000) sube uno...
	ld hl,0e000h		;41f6
	inc (hl)			;41f9
empieza_la_escena:		; ...y el paso vuelve a cero
	xor a			;41fa
	ld (0e001h),a		;41fb
	ret			;41fe
escena_rotulo_3:		; el tercero: suena el 0x9B y se esperan 0x50 cuadros
	ld a,09bh		;41ff
	call pide_un_sonido		;4201
	ld a,050h		;4204
	jr espera_n_y_avanza_paso		;4206

; ----------------------------------------------------------------------
; ===== ESCENA 4: el partido se prepara =====
; ----------------------------------------------------------------------
escena_prepara_partido:		; ocho pasos, del saque de banderin al pitido
	djnz escena_prepara_partido_2		;4208
	call un_cuadro_de_las_opciones		;420a
	ld a,(0e006h)		;420d   ; (0xE006) y (0xE008) son los dos mandos juntos
	ld hl,0e008h		;4210
	or (hl)			;4213
	and 010h		;4214   ; el bit 4: el boton de disparo
	ret z			;4216   ; sin pulsacion no se sigue
	ld a,(0e002h)		;4217
	bit 5,a		;421a   ; el bit 5 de (0xE002) elige de cual de los dos jugadores se lee la eleccion
	ld a,(0e0a0h)		;421c
	jr z,L_4224		;421f
	ld a,(0e0a1h)		;4221
L_4224:
	ld (0e069h),a		;4224   ; y queda apuntada en (0xE069)
	xor a			;4227
	ld (0e0f7h),a		;4228
	jr avanza_paso		;422b
escena_prepara_partido_2:		; suena el 0xB1
	djnz escena_prepara_partido_3		;422d
	call marca_partida_empezada		;422f
L_4232:
	ld a,0b1h		;4232
	call pide_un_sonido		;4234
	jp espera_y_avanza_paso		;4237
escena_prepara_partido_3:		; el borde a negro y el marcador a su sitio
	djnz escena_prepara_partido_4		;423a
	call baja_la_cortina		;423c
	ret p			;423f   ; espera a que la cortina termine
	ld b,000h		;4240
	call pone_el_color_del_borde		;4242   ; borde negro
	ld hl,(0e072h)		;4245   ; (0xE072) se copia a (0xE0F3)
	ld (0e0f3h),hl		;4248
	call monta_la_pantalla_de_datos		;424b
	call arranca_la_jugada		;424e
	jp avanza_paso		;4251
escena_prepara_partido_4:		; espera al bit 1 de (0xE525)
	djnz escena_prepara_partido_5		;4254
	call anima_la_valla		;4256
	call espera_a_que_calle_el_sonido		;4259
	ld a,(0e525h)		;425c
	rra			;425f
	rra			;4260
	ret nc			;4261
	xor a			;4262   ; y lo apaga al pasar
	ld (0e525h),a		;4263
	jp avanza_paso		;4266
escena_prepara_partido_5:		; aqui se carga TODO el decorado del campo
	djnz escena_prepara_partido_6		;4269
	call limpia_la_pantalla		;426b   ; los registros del VDP otra vez
	call carga_los_graficos_del_campo		;426e   ; las diez tandas de graficos
L_4271:
	call monta_el_partido		;4271
	ld a,080h		;4274   ; 0x80 cuadros de espera
	jp espera_n_y_avanza_paso		;4276
carga_los_graficos_del_campo:		; diez tandas seguidas, cada una pegada a sus propios datos
	call L_6D18		;4279   ; cada uno de estos diez lleva sus bloques comprimidos justo detras, y los vuelca el mismo
	call L_6E16		;427c
	call L_6EB9		;427f
	call L_6F0E		;4282
	call L_7071		;4285
	call L_731F		;4288
	call L_73E3		;428b
	call L_7403		;428e
	call L_7419		;4291
	jp L_74DC		;4294
escena_prepara_partido_6:		; la primera cuenta atras
	djnz escena_prepara_partido_7		;4297
	ld hl,0e004h		;4299   ; (0xE004) es la cuenta de espera que dejo puesta el paso anterior
	dec (hl)			;429c
	ret nz			;429d
	ld a,040h		;429e   ; y cumplida, 0x40 cuadros mas para el paso siguiente
	jp espera_n_y_avanza_paso		;42a0
escena_prepara_partido_7:		; la segunda, con un aviso a mitad
	djnz escena_prepara_partido_8		;42a3
	ld hl,0e004h		;42a5
	dec (hl)			;42a8
	jr z,L_42B4		;42a9
	ld a,(hl)			;42ab
	cp 020h		;42ac   ; a falta de 0x20 cuadros...
	ret nz			;42ae
	ld a,025h		;42af   ; ...suena el 0x25
	jp pide_un_sonido		;42b1
L_42B4:
	xor a			;42b4
	ld (0e003h),a		;42b5   ; el contador de cuadros se pone a cero: el partido empieza a contar desde aqui
	jp avanza_escena		;42b8
escena_prepara_partido_8:		; el borde a azul y arranca
	call baja_la_cortina		;42bb
	ret p			;42be
	call monta_la_pantalla_de_opciones		;42bf
	ld b,004h		;42c2   ; el 4 es el azul del cesped
	call pone_el_color_del_borde		;42c4
	call escribe_los_rotulos_de_opciones		;42c7
	jp avanza_paso		;42ca

; ----------------------------------------------------------------------
; ===== ESCENA 5: el descanso =====
; ----------------------------------------------------------------------
escena_descanso:		; espera a que (0xE0F0) diga que se puede seguir
	call un_cuadro_del_partido		;42cd
	ld a,(0e0f0h)		;42d0
	and a			;42d3
	ret z			;42d4
	call sube_los_sprites		;42d5
	ld a,030h		;42d8   ; 0x30 cuadros y a la escena siguiente
	jp espera_n_y_avanza_escena		;42da

; ----------------------------------------------------------------------
; ===== ESCENA 6: el gol, y el final de cada tiempo =====
; ----------------------------------------------------------------------
escena_gol:		; el paso 1: el marcador del que ha marcado sube un gol
	djnz escena_gol_2		;42dd   ; el paso llega en B y cada djnz se come uno; el paso 0, que es B=0, atraviesa los cinco y cae en 0x43DB
	ld a,062h		;42df   ; el 0x62 es el sonido del gol: el mismo que suena en el penalti marcado, en 0x442A
	call pide_un_sonido		;42e1
	ld a,(0e0f0h)		;42e4   ; (0xE0F0) dice por que se ha parado el juego: bit 0 gol de uno, bit 1 gol del otro, bit 2 se acabo el tiempo
	rra			;42e7
	ld hl,0e0f5h		;42e8   ; (0xE0F5) es la cifra BCD del equipo de la derecha del rotulo, el que se pinta en 0x380B
	ld de,0e0e0h		;42eb   ; (0xE0E0) es su byte alto, el que solo recoge el acarreo del BCD
	ld a,001h		;42ee   ; (0xE0F7) se queda con cual de los dos ha marcado, y sobrevive al gol
	jr c,L_42F9		;42f0
	ld hl,0e0f6h		;42f2   ; y si el bit 0 estaba apagado, el gol es del otro: (0xE0F6) y (0xE0E1)
	ld de,0e0e1h		;42f5
	xor a			;42f8
L_42F9:
	ld (0e0f7h),a		;42f9   ; 0x5694 lo lee para elegir con cual de las dos tablas de 12 por 3 bytes, 0x579F o 0x57C3, se colocan los jugadores
	ld a,(hl)			;42fc
	add a,001h		;42fd   ; un gol mas...
	daa			;42ff   ; ...en BCD, que es como el marcador se pinta luego sin dividir por diez
	ld (hl),a			;4300
	ld a,(de)			;4301   ; el byte alto solo suma el acarreo: harian falta cien goles para moverlo
	adc a,000h		;4302
	ld (de),a			;4304
	call pinta_el_marcador		;4305   ; el marcador de arriba, ya con la cifra nueva
	call pon_a_celebrar		;4308   ; 0x635F cambia de postura a los seis jugadores de un equipo...
	call pon_a_los_seis_en_reposo		;430b   ; ...y 0x64D3 a los seis del otro: unos celebran y los otros no
	jp avanza_paso		;430e
escena_gol_2:		; el paso 2: la cifra del que ha marcado parpadea hasta que la celebracion acaba
	djnz escena_gol_3		;4311
	ld a,(0e0f0h)		;4313   ; el mismo bit 0 vuelve a elegir de que equipo es la cifra que parpadea
	ld de,0e0f5h		;4316
	ld hl,0380bh		;4319   ; 0x380B es la casilla del tanteo de la derecha, en la fila de arriba
	rra			;431c
	jr c,L_4322		;431d
	inc de			;431f
	ld l,008h		;4320   ; y 0x3808 la del tanteo de la izquierda
L_4322:
	ld b,001h		;4322   ; este B=1 no lo mira ninguna de las dos rutinas de cifras; es un adorno que se repite en toda la ROM
	ld a,(0e003h)		;4324
	bit 3,a		;4327   ; el bit 3 del contador de cuadros: ocho cuadros puesta y ocho quitada
	jr z,L_4330		;4329
	call escribe_dos_blancos		;432b   ; los cuadros en que no se ve, dos casillas en blanco
	jr L_4333		;432e
L_4330:
	call escribe_dos_cifras		;4330   ; y los cuadros en que se ve, las dos cifras
L_4333:
	call corre_la_celebracion		;4333
	call parpadea_el_marcador		;4336
	ld a,(0e003h)		;4339
	bit 2,a		;433c
	ld de,04044h		;433e   ; las dos casillas que se van alternando, 0x40 y 0x44
	jr z,L_4346		;4341   ; el bit 2 del contador: el cambio va cuatro veces mas rapido que el de la cifra
	ld de,l4440h		;4343   ; no es una direccion: son esas dos mismas casillas al reves, 0x44 y 0x40. Que 0x4440 caiga encima de una instruccion es casualidad
L_4346:
	ld hl,0e600h		;4346   ; 0xE600 es la copia en RAM de la tabla de nombres del campo; 0x5DD6 sube desde ahi las 23 filas a 0x3820
	ld b,028h		;4349   ; cuarenta parejas, o sea 80 casillas: dos filas y media del campo
L_434B:
	ld (hl),d			;434b
	inc hl			;434c
	ld (hl),e			;434d
	inc hl			;434e
	djnz L_434B		;434f
	ld a,(0e308h)		;4351   ; (0xE308) lo enciende 0x64CD cuando la celebracion se ha terminado
	rra			;4354
	ret nc			;4355   ; y hasta entonces la escena se queda dando vueltas en este paso
	xor a			;4356
	ld (0e308h),a		;4357
	call pinta_el_marcador		;435a   ; repinta las dos cifras enteras, para que no se quede una a medias del parpadeo
	ld hl,(0e0f3h)		;435d   ; el reloj: (0xE0F3) son los segundos en BCD y (0xE0F4) los minutos, y se leen juntos como una palabra
	ld a,l			;4360
	or h			;4361
	ld a,001h		;4362   ; con reloj todavia vivo, un solo cuadro de espera y a seguir
	jr nz,L_4368		;4364
	ld a,080h		;4366   ; si el reloj esta a 0:00 se esperan 0x80 cuadros, que es lo que dura el pitido
L_4368:
	jp espera_n_y_avanza_paso		;4368
escena_gol_3:		; el paso 3: la espera, y el pitido final si el reloj se agoto durante el gol
	djnz escena_gol_4		;436b
	ld hl,0e004h		;436d
	dec (hl)			;4370
	jp z,avanza_paso		;4371   ; al llegar la cuenta a cero, al paso siguiente
	ld c,(hl)			;4374
	ld hl,(0e0f3h)		;4375   ; solo interesa si el reloj esta parado en 0:00
	ld a,l			;4378
	or h			;4379
	ret nz			;437a
	ld a,c			;437b
	cp 060h		;437c   ; a falta de 0x60 cuadros exactos, o sea a mitad de la espera...
	ret nz			;437e
	ld a,004h		;437f   ; ...se marca el bit 2: se acabo el tiempo
	ld (0e0f0h),a		;4381
	ld a,02bh		;4384   ; y suena el 0x2B, el pitido del arbitro; 0x6318 toca el mismo cuando el reloj llega a cero jugando
	jp pide_un_sonido		;4386
escena_gol_4:		; el paso 4: decide si se saca de centro, si empieza la otra parte o si el partido acabo
	djnz escena_gol_5		;4389
	call limpia_la_pantalla		;438b   ; la tabla de nombres a cero y los sprites fuera
	ld a,(0e0f0h)		;438e
	and 003h		;4391   ; los dos bits de gol: si alguno esta puesto, ha sido gol
	jr z,L_439E		;4393
	ld hl,00504h		;4395   ; escena 4 y paso 5: se vuelve a la preparacion del partido
	ld (0e000h),hl		;4398
	jp L_4271		;439b   ; y por 0x4271, que es el trozo de esa escena que va DESPUES de cargar los graficos: el campo ya esta puesto
L_439E:
	ld hl,0e0f2h		;439e   ; sin bits de gol, lo que se acabo fue el tiempo
	ld a,(hl)			;43a1   ; (0xE0F2) es el numero de parte: 0x58F5 lo arranca en 1
	rra			;43a2   ; si la parte que termina es impar, o sea la primera...
	jr nc,L_43AA		;43a3
	ld a,001h		;43a5   ; ...se enciende (0xE0F7), que es lo que hace que la segunda parte se coloque con la otra tabla
	ld (0e0f7h),a		;43a7
L_43AA:
	inc (hl)			;43aa   ; una parte mas
	ld a,(hl)			;43ab
	rra			;43ac   ; dos partes: al llegar a 3 el partido esta acabado y se pasa al paso 5
	jr c,L_43F4		;43ad
	ld hl,00204h		;43af   ; escena 4 y paso 2, para montar la segunda parte desde el principio
	ld (0e000h),hl		;43b2
	jp L_4232		;43b5   ; por 0x4232, o sea con el aviso 0xB1 sonando
escena_gol_5:		; el paso 5: se comparan los dos tanteos y se decide si hay penaltis
	djnz escena_gol_espera		;43b8
	ld hl,(0e0f5h)		;43ba   ; HL trae (0xE0F6) arriba y (0xE0F5) abajo, que son las dos cifras bajas
	ld bc,(0e0e0h)		;43bd   ; y BC los dos bytes altos
	ld a,c			;43c1   ; estas tres lineas recomponen los pares: HL = (0xE0E0):(0xE0F5) y BC = (0xE0E1):(0xE0F6), un tanteo entero en cada uno
	ld c,h			;43c2
	ld h,a			;43c3
	and a			;43c4
	sbc hl,bc		;43c5
	jp z,avanza_escena		;43c7   ; empate: se pasa a la escena 7, la tanda de penaltis
	ld a,001h		;43ca   ; gana el equipo de (0xE0F5), el de la derecha
	jr nc,L_43CF		;43cc
	inc a			;43ce   ; y si hubo acarreo gana el otro
L_43CF:
	ld (0e520h),a		;43cf   ; (0xE520) es el ganador: 0xB94A lo vuelve a leer para escribir su nombre en la pantalla final
	ld hl,00007h		;43d2   ; escena 7 y paso 0...
	ld (0e000h),hl		;43d5
	jp espera_y_avanza_escena		;43d8   ; ...pero avanza_escena la sube en el acto a la 8: sin empate no hay penaltis, se va derecho al final
escena_gol_espera:		; el paso 0: la espera de entrada, y el atajo cuando lo que se acabo fue el tiempo
	ld hl,0e004h		;43db   ; aqui es donde cae la cadena de djnz cuando el paso vale 0, o sea al entrar en la escena
	dec (hl)			;43de   ; la cuenta que dejo puesta la escena anterior, 0x30 cuadros
	ret nz			;43df
	ld a,(0e0f0h)		;43e0
	and 004h		;43e3   ; el bit 2: se acabo el tiempo, no hubo gol
	jr z,L_43F1		;43e5
	ld hl,0e001h		;43e7   ; entonces no hay marcador que subir: el paso se pone a 2...
	ld (hl),002h		;43ea
	ld a,040h		;43ec   ; ...y avanza a 3, saltandose el gol y su parpadeo
	jp espera_n_y_avanza_paso		;43ee
L_43F1:
	call reanuda_tras_el_gol		;43f1   ; y si fue gol, 0x632D reparte otra vez a los doce jugadores y recarga los graficos del saque
L_43F4:
	jp avanza_paso		;43f4

; ----------------------------------------------------------------------
; ===== ESCENA 7: la tanda de penaltis =====
; ----------------------------------------------------------------------
escena_penaltis:		; cinco tiros cada uno, y muerte subita si siguen empatados
	djnz escena_penaltis_2		;43f7
	ld hl,0e004h		;43f9   ; la cuenta que dejo puesta el paso 0
	dec (hl)			;43fc
	ret nz			;43fd
	call limpia_la_pantalla		;43fe   ; la tabla de nombres a cero: se quita el rotulo de PENALTY SHOOT OUT
	jp avanza_paso		;4401
escena_penaltis_2:		; el paso 2: 0x6B1F monta el tiro que toca
	djnz escena_penaltis_3		;4404
	call monta_la_pantalla_de_penaltis		;4406
	jp avanza_paso		;4409
escena_penaltis_3:		; el paso 3: el tiro, hasta que (0xE0F8) diga que ha terminado
	djnz escena_penaltis_4		;440c
	call un_cuadro_de_los_penaltis		;440e   ; 0x651E sube los sprites y despacha la subescena que toque
	call pinta_los_penaltis		;4411   ; y de paso se refresca el marcador de penaltis de la fila de arriba
	ld a,(0e0f8h)		;4414   ; (0xE0F8) lo enciende 0x6B90 al empezar el tiro
	and a			;4417
	ret nz			;4418   ; mientras siga puesto, el tiro sigue en el aire
	jp avanza_paso		;4419
escena_penaltis_4:		; el paso 4: si el penalti entro, se apunta
	djnz escena_penaltis_5		;441c
	ld a,(0e0f0h)		;441e   ; el mismo (0xE0F0) del partido, con los mismos dos bits de gol
	ld c,a			;4421
	and a			;4422
	ld a,080h		;4423   ; fallado: 0x80 cuadros y a otra cosa
	jp z,espera_n_y_avanza_paso		;4425
	ld a,062h		;4428   ; marcado: el 0x62, el mismo sonido del gol del partido
	call pide_un_sonido		;442a
	ld a,c			;442d
	ld hl,0e0f9h		;442e   ; (0xE0F9) son los penaltis del equipo de la derecha y (0xE0FA) los del de la izquierda
	rra			;4431
	jr c,L_4435		;4432
	inc hl			;4434
L_4435:
	inc (hl)			;4435   ; uno mas
	xor a			;4436   ; con A=0 la espera vale 256 cuadros, el doble que la del fallo: da tiempo a celebrarlo
	jp espera_n_y_avanza_paso		;4437
escena_penaltis_5:		; el paso 5: la cifra del que acaba de marcar parpadea
	djnz escena_penaltis_6		;443a
	ld a,(0e0f0h)		;443c   ; sin gol no hay nada que hacer parpadear
	and a			;443f
L_4440:
	jr z,L_445F		;4440   ; esta instruccion es la que otro `ld de` de mas arriba usa como si fuera un numero
	ld de,0e0f9h		;4442
	ld hl,0381ch		;4445   ; 0x381C es la casilla de los penaltis de la derecha...
	rra			;4448
	jr c,L_444E		;4449
	inc de			;444b
	ld l,019h		;444c   ; ...y 0x3819 la de la izquierda; las dos caen donde durante el partido va el reloj
L_444E:
	ld b,001h		;444e
	ld a,(0e003h)		;4450
	bit 3,a		;4453   ; el mismo parpadeo de ocho cuadros del gol
	jr z,L_445C		;4455
	call escribe_dos_blancos		;4457
	jr L_445F		;445a
L_445C:
	call escribe_dos_cifras		;445c
L_445F:
	ld hl,0e004h		;445f
	dec (hl)			;4462
	ret nz			;4463
	jp avanza_paso		;4464
escena_penaltis_6:		; el paso 6: cierra el tiro y mira si la tanda ya esta decidida
	dec b			;4467   ; con el paso 6, B llega aqui valiendo 1; con el paso 0 vale 0xFB y se va al arranque
	jp nz,escena_penaltis_arranca		;4468
	ld a,(0e0fch)		;446b   ; (0xE0FC) dice a quien le toca tirar
	rra			;446e
	jr c,penaltis_cierra_la_ronda		;446f
	xor a			;4471   ; se borra la marca de gol para el tiro siguiente
	ld (0e0f0h),a		;4472
	inc a			;4475
	ld (0e0fch),a		;4476   ; y el turno pasa al segundo equipo
	ld (0e001h),a		;4479   ; el paso se deja en 1 para que el avanza_paso de abajo lo suba a 2, que es el que monta el tiro
	ld a,(0e0fbh)		;447c   ; (0xE0FB) es la ronda; con las cinco cumplidas ya no se decide nada por aqui
	cp 005h		;447f
	jr z,L_44A0		;4481
	ld a,(0e0f9h)		;4483   ; la diferencia entre los dos, sin signo todavia
	ld hl,0e0fah		;4486
	sub (hl)			;4489
	jr z,L_44A0		;448a   ; empatados: se sigue tirando
	jr nc,L_4499		;448c   ; y aqui se separan los dos signos de la diferencia
	neg		;448e   ; el otro va por delante: la diferencia se pasa a positiva
	ld c,a			;4490
	ld a,(0e0fdh)		;4491   ; (0xE0FD) son los tiros que le quedan a este equipo
	cp c			;4494
	jr c,penaltis_resuelve		;4495   ; si le quedan menos tiros que goles de desventaja, la tanda esta decidida y no se sigue
	jr L_44A0		;4497
L_4499:
	ld c,a			;4499   ; la ventaja es de este equipo
	ld a,(0e0feh)		;449a   ; (0xE0FE) son los tiros que le quedan al otro
	cp c			;449d
	jr c,penaltis_resuelve		;449e
L_44A0:
	jp avanza_paso		;44a0   ; y si no, al paso 2 a montar el tiro siguiente
penaltis_cierra_la_ronda:		; lo mismo, pero cuando el que ha tirado es el segundo: aqui la ronda se cierra
	ld a,(0e0fbh)		;44a3
	cp 005h		;44a6   ; con las cinco rondas cumplidas se va directo a cerrar la ronda
	jr z,L_44C7		;44a8
	ld a,(0e0f9h)		;44aa
	ld hl,0e0fah		;44ad
	sub (hl)			;44b0
	jr z,L_44C7		;44b1
	jr nc,L_44C0		;44b3
	neg		;44b5
	ld c,a			;44b7
	ld a,(0e0fdh)		;44b8   ; la misma comparacion de tiros que quedan contra goles de desventaja
	cp c			;44bb
	jr c,penaltis_resuelve		;44bc
	jr L_44C7		;44be
L_44C0:
	ld c,a			;44c0
	ld a,(0e0feh)		;44c1
	cp c			;44c4
	jr c,penaltis_resuelve		;44c5
L_44C7:
	ld hl,0e0fbh		;44c7   ; una ronda mas
	inc (hl)			;44ca
	ld a,(hl)			;44cb
	cp 005h		;44cc   ; con menos de cinco todavia se sigue tirando...
	jr c,penaltis_siguiente_tiro		;44ce
	ld (hl),005h		;44d0   ; ...y con cinco la cuenta se queda clavada ahi y la tanda se resuelve
	jr penaltis_resuelve		;44d2
penaltis_siguiente_tiro:		; el turno vuelve al primero y la escena se va al paso 2
	xor a			;44d4
	ld (0e0fch),a		;44d5
	ld (0e0f0h),a		;44d8
	inc a			;44db
	ld (0e001h),a		;44dc   ; paso 1, que el avanza_paso de la linea siguiente sube a 2
	jp avanza_paso		;44df
penaltis_resuelve:		; con la tanda decidida, apunta al ganador y se va a la pantalla final
	ld a,(0e0f9h)		;44e2
	ld hl,0e0fah		;44e5
	sub (hl)			;44e8
	jr z,penaltis_muerte_subita		;44e9   ; si siguen empatados no hay ganador: muerte subita
	ld a,001h		;44eb   ; gana el de (0xE0F9), el de la derecha
	jr nc,L_44F1		;44ed
	ld a,002h		;44ef
L_44F1:
	ld (0e520h),a		;44f1   ; el mismo (0xE520) que rellena el final del partido
	ld hl,0e0f9h		;44f4   ; antes de irse hay que quitar la marca de la muerte subita de las dos cuentas
	call quita_la_marca_de_los_diez		;44f7
	inc hl			;44fa
	call quita_la_marca_de_los_diez		;44fb
	jp espera_y_avanza_escena		;44fe   ; a la escena 8: la pantalla final
penaltis_muerte_subita:		; las dos cuentas se ponen a diez, que es la marca que las deja en blanco
	ld a,00ah		;4501   ; el 0x0A es justo el valor que 0x463D pinta como dos casillas vacias: durante la muerte subita el marcador de penaltis se apaga
	ld (0e0f9h),a		;4503
	ld (0e0fah),a		;4506
	jr penaltis_siguiente_tiro		;4509   ; y a seguir tirando, ronda a ronda
quita_la_marca_de_los_diez:		; deshace el 0x0A de la muerte subita para recuperar la cuenta de verdad
	ld a,(hl)			;450b
	cp 00ah		;450c
	ret c			;450e   ; por debajo de diez no hay marca que quitar
	sub 00ah		;450f
	ld (hl),a			;4511
	ret			;4512
escena_penaltis_arranca:		; el paso 0: pone la tanda a cero y saca el rotulo
	xor a			;4513
	ld (0e0fbh),a		;4514   ; la ronda a cero
	ld (0e0fch),a		;4517   ; y el turno, al primero
	ld (0e0f0h),a		;451a
	ld a,005h		;451d   ; cinco tiros para cada uno
	ld (0e0fdh),a		;451f
	ld (0e0feh),a		;4522
	call carga_la_fuente		;4525
	ld de,04997h		;4528   ; el rotulo PENALTY SHOOT OUT, que va a la fila 8 de la pantalla
	call escribe_un_rotulo		;452b
	ld hl,0394ch		;452e   ; en la partida de un jugador, 0x5FC1 escribe ahi el nivel elegido; en la de dos se vuelve sin hacer nada
	call L_5FC1		;4531
	ld a,080h		;4534
	jp espera_n_y_avanza_paso		;4536

; ----------------------------------------------------------------------
; ===== ESCENA 8: la pantalla final =====
; ----------------------------------------------------------------------
escena_final:		; el paso 1: espera a que la cortina acabe de borrar la pantalla
	djnz escena_final_2		;4539
	call baja_la_cortina		;453b   ; la cortina va borrando una columna por cuadro; hasta que no termina no se sigue
	ret p			;453e
	xor a			;453f
	ld (0e561h),a		;4540
	jp avanza_paso		;4543
escena_final_2:		; el paso 2: el resumen del partido, y de ahi otra vez a la presentacion
	djnz escena_final_entra		;4546
	call L_B8A2		;4548   ; 0xB8A2 escribe el resultado, los penaltis si los hubo, y el nombre del ganador
	ld a,(0e562h)		;454b   ; (0xE562) avisa de que el resumen ha terminado
	and a			;454e
	ret z			;454f
	ld hl,0e002h		;4550
	ld a,(hl)			;4553
	and 0bfh		;4554   ; se apaga el bit 6 de (0xE002): ya no se esta en un partido, y las escenas vuelven a llevar detras el gancho de la tecla
	ld (hl),a			;4556
	jp L_41B3		;4557   ; y por 0x41B3 se vuelve a la escena 0, la presentacion
escena_final_entra:		; el paso 0: la cortina y los graficos de texto otra vez
	call baja_la_cortina		;455a
	ret p			;455d
	call carga_la_fuente		;455e   ; 0x4A36 devuelve a la VRAM la fuente y los colores de las pantallas de texto
	jp avanza_paso		;4561

; ----------------------------------------------------------------------
; ===== EL MODO DE ATRACCION: la tecla que se cuela por detras =====
; ----------------------------------------------------------------------
mira_si_alguien_pulsa:		; nadie la llama: 0x40D3 la mete en la pila como retorno de las escenas 0, 1 y 2
	call lee_el_mando_1		;4564   ; los dos mandos se leen aqui otra vez, y se juntan en uno
	ld c,a			;4567
	push bc			;4568
	call lee_el_mando_2		;4569
	pop bc			;456c
	or c			;456d
	ld hl,0e041h		;456e   ; (0xE041) guarda lo pulsado y (0xE040) lo RECIEN pulsado, que es lo que interesa
	call guarda_y_marca_lo_recien_pulsado		;4571
	or a			;4574
	ret z			;4575   ; sin pulsacion nueva no hay nada que hacer
	ld hl,0e004h		;4576   ; la cuenta de espera a cero...
	ld (hl),000h		;4579   ; ...y de paso ese cero sirve para bajar HL a 0xE000, que es la escena
	ld l,(hl)			;457b
	ld de,0e042h		;457c   ; (0xE042) es la eleccion de uno o dos jugadores
	ld b,(hl)			;457f
	djnz L_459B		;4580   ; solo la escena 1, la del logotipo, sigue por aqui; la 0 y la 2 se van a L_459B
	and 030h		;4582   ; los bits 4 y 5 son los dos disparos
	jr z,cambia_de_uno_a_dos_jugadores		;4584
	ld a,(de)			;4586   ; con (0xE042) a cero, 0x40: solo el bit 6, la partida
	or a			;4587
	ld a,040h		;4588
	jr z,L_458E		;458a
	ld a,060h		;458c   ; y si no, 0x60: el bit 6 mas el bit 5, que es la partida de dos
L_458E:
	ld (0e002h),a		;458e   ; (0xE002) se queda con esas banderas para todo el partido
	ld (hl),003h		;4591   ; escena 3, la del rotulo que parpadea
	inc hl			;4593
	ld c,000h		;4594
	ld (hl),c			;4596
	dec c			;4597
	jp L_4D02		;4598
L_459B:
	ld (hl),001h		;459b   ; y desde la presentacion o el titulo, cualquier tecla lleva al logotipo
	jp monta_la_pantalla_de_titulo		;459d
cambia_de_uno_a_dos_jugadores:		; sin disparo, la tecla solo hace de interruptor
	ld a,(de)			;45a0
	xor 001h		;45a1   ; el bit 0 se da la vuelta: uno pasa a dos y dos pasa a uno
	ld (de),a			;45a3
	ret			;45a4

; ----------------------------------------------------------------------
; ===== El arranque del partido, la cortina y los sprites aparcados =====
; ----------------------------------------------------------------------
borra_las_variables_del_partido:		; 0x11A0 bytes a cero, de 0xE0E0 a 0xF27F
	ld hl,0e0e0h		;45a5
	ld bc,0119fh		;45a8   ; 0x119F es uno menos: el primer byte lo pone el `ld (hl),a` y el ldir arrastra el resto
	ld d,h			;45ab
	ld e,l			;45ac
	inc e			;45ad
	xor a			;45ae
	ld (hl),a			;45af
	ldir		;45b0
	ld hl,0e0f0h		;45b2   ; y detras del borron, tres valores a mano
	ld (hl),a			;45b5
	inc a			;45b6
	inc hl			;45b7
	ld (hl),a			;45b8   ; (0xE0F1) a 1: el titulo se queda esperando mientras no valga cero
	inc hl			;45b9
	ld (hl),a			;45ba   ; (0xE0F2) a 1: la primera parte
	ret			;45bb
baja_la_cortina:		; borra la pantalla de izquierda a derecha, una columna por cuadro
	ld hl,0e004h		;45bc
	dec (hl)			;45bf   ; la cuenta de espera hace de columna; los que la llaman arrancan con 0x20
	ret m			;45c0   ; cuando pasa de cero la cortina ha terminado, y el `ret p` del que llama deja de volverse
	ld a,(hl)			;45c1
	ld h,038h		;45c2   ; la fila de arriba de la tabla de nombres
	xor 01fh		;45c4   ; el xor da la vuelta a la cuenta: la columna 0 se borra la primera y la 31 la ultima
	ld l,a			;45c6
	ld b,018h		;45c7   ; veinticuatro filas
	xor a			;45c9
	ld de,00020h		;45ca   ; de una fila a la de abajo hay 32 casillas
L_45CD:
	call 0004dh		;45cd   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;45d0
	djnz L_45CD		;45d1   ; asi que se borra una columna entera por cuadro
aparca_los_sprites:		; los treinta y dos, a una Y por debajo de la pantalla
	ld hl,0e390h		;45d3
	ld b,020h		;45d6   ; los 32 sprites de la copia en RAM
L_45D8:
	ld (hl),0e0h		;45d8   ; la Y a 0xE0, que cae fuera de las 192 lineas
	inc hl			;45da
	inc hl			;45db   ; los otros tres bytes del sprite -X, patron y color- se quedan como estaban
	inc hl			;45dc
	inc hl			;45dd
	djnz L_45D8		;45de
	call copia_los_sprites		;45e0   ; y la copia se sube a la VRAM en el acto
	xor a			;45e3   ; el cero que se deja aqui es el que 0x4668 usa luego para rellenar
	ret			;45e4

; ----------------------------------------------------------------------
; ===== EL ROTULO DE ARRIBA: nombres, marcador, penaltis y reloj =====
; ----------------------------------------------------------------------
pinta_los_nombres_de_los_equipos:		; el guion del medio y los dos nombres, que viven en la RAM
	ld de,0497fh		;45e5   ; el rotulo de 0x497F es una sola casilla: el guion que separa los dos tanteos, en 0x380A
	call escribe_un_rotulo		;45e8
	ld hl,0380eh		;45eb   ; 0x380E, la mitad derecha de la fila: el nombre de (0xE05B), que es el equipo de (0xE0F5)
	ld de,0e05bh		;45ee
	call escribe_el_rotulo_en_hl		;45f1
	ld hl,03801h		;45f4   ; y 0x3801 el de (0xE062); los dos son de siete letras y acaban en 0xFF
	ld de,0e062h		;45f7
	jp escribe_el_rotulo_en_hl		;45fa
pinta_el_marcador:		; las dos cifras de goles de la fila de arriba
	ld hl,0380bh		;45fd   ; 0x380B y 0x380C: el tanteo de la derecha
	ld de,0e0f5h		;4600
	call escribe_dos_cifras		;4603
	ld hl,03808h		;4606   ; 0x3808 y 0x3809: el de la izquierda
	inc de			;4609
	jr escribe_dos_cifras		;460a
pinta_los_penaltis:		; el rotulo PK y las dos cuentas de la tanda
	ld de,0498eh		;460c   ; el rotulo de 0x498E: PK en 0x3816 y el guion en 0x381B
	call escribe_un_rotulo		;460f
	ld hl,0381ch		;4612   ; 0x381C, los penaltis del equipo de la derecha
	ld de,0e0f9h		;4615
	call escribe_dos_cifras		;4618
	ld hl,03819h		;461b   ; 0x3819, los del de la izquierda
	inc de			;461e
	jr escribe_dos_cifras		;461f
pinta_el_reloj:		; los minutos y los segundos, que van en dos bytes BCD
	ld de,04983h		;4621   ; el rotulo de 0x4983: TIME en 0x3815 y los dos puntos en 0x381C
	call escribe_un_rotulo		;4624
	ld de,0e0f4h		;4627   ; (0xE0F4) son los minutos y (0xE0F3), un byte mas abajo, los segundos
	ld hl,0381ah		;462a   ; 0x381A y 0x381B, a la izquierda de los dos puntos
	call escribe_dos_cifras_sin_cero		;462d   ; los minutos se pintan sin el cero de delante
	dec de			;4630   ; y de ahi se baja a los segundos...
	inc hl			;4631   ; ...y se salta la casilla de los dos puntos, que ya esta puesta
	inc hl			;4632
	jr escribe_dos_cifras		;4633
escribe_dos_blancos:		; las dos casillas a cero: asi se apaga una cifra
	xor a			;4635
	call 0004dh		;4636   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4639
	xor a			;463a
	jr L_4665		;463b
escribe_dos_cifras:		; un byte BCD en dos casillas, con los dos codigos especiales de la tanda de penaltis
	ld a,(de)			;463d
	cp 00ah		;463e   ; el 0x0A no es un numero: es la marca de la muerte subita, y sale en blanco
	jr z,escribe_dos_blancos		;4640
	cp 00bh		;4642   ; el 0x0B es esa misma marca con un penalti metido, y saca un blanco y la casilla 0x21
	jr nz,L_4654		;4644
	xor a			;4646
	call 0004dh		;4647   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;464a
	ld a,021h		;464b
	jr L_4665		;464d
escribe_dos_cifras_sin_cero:		; igual, pero si la decena es cero no toca su casilla
	ld a,(de)			;464f
	and 0f0h		;4650   ; sin decena no se escribe nada ahi: se cuenta con que la casilla ya este en blanco
	jr z,L_465F		;4652
L_4654:
	rra			;4654   ; el nibble de arriba baja a su sitio...
	rra			;4655
	rra			;4656
	rra			;4657
	and 00fh		;4658
	add a,010h		;465a   ; ...y el 0x10 es donde empieza el cero en la tabla de patrones: las diez cifras van del 0x10 al 0x19
	call 0004dh		;465c   ; BIOS WRTVRM - Writes data in VRAM
L_465F:
	ld a,(de)			;465f   ; y el de abajo, en la casilla siguiente
	inc hl			;4660
	and 00fh		;4661
	add a,010h		;4663
L_4665:
	jp 0004dh		;4665   ; BIOS WRTVRM - Writes data in VRAM
limpia_la_pantalla:		; aparca los sprites y deja la tabla de nombres entera a cero
	call aparca_los_sprites		;4668
	ld hl,03800h		;466b
	ld bc,00300h		;466e   ; 0x300 casillas, o sea las 24 filas por 32 columnas
	jp rellena_la_vram		;4671

; ----------------------------------------------------------------------
; ===== LA VRAM: las puertas de escritura =====
; ----------------------------------------------------------------------
abre_la_vram:		; fija la direccion de escritura y deja el puerto de datos en C'
	ex af,af'			;4674
	call 00053h		;4675   ; BIOS SETWRT - Enables VDP to write | SETWRT con HL; hace `and 03fh` sobre H, asi que se le pueden pasar direcciones con los dos bits de arriba puestos
	exx			;4678
	ld a,(00007h)		;4679   ; (0x0007) es donde la BIOS guarda el puerto base del VDP
	ld c,a			;467c   ; el puerto de datos queda en el C del juego alterno, para poder sacar bytes con `out (c),a` sin recalcularlo
	exx			;467d
	ex af,af'			;467e
	ret			;467f
copia_a_la_vram:		; LDIRVM: bloque tal cual, sin comprimir
	ex de,hl			;4680
	jp 0005ch		;4681   ; BIOS LDIRVM - Block transfers to VRAM from memory
rellena_la_vram:		; FILVRM: el mismo byte, BC veces
	jp 00056h		;4684   ; BIOS FILVRM - Fills VRAM with value
rellena_los_tres_tercios:		; el mismo relleno en los tres tercios de SCREEN 2
	ld d,003h		;4687   ; tres vueltas, una por tercio
L_4689:
	push bc			;4689
	push de			;468a
	call rellena_la_vram		;468b
	ld de,00800h		;468e   ; los tercios estan a 0x800 uno de otro
	add hl,de			;4691
	pop de			;4692
	pop bc			;4693
	dec d			;4694
	jr nz,L_4689		;4695
	ret			;4697
descomprime_en_los_tres_tercios:		; el mismo bloque comprimido, repetido en los tres tercios
	ld b,003h		;4698
L_469A:
	push bc			;469a
	push de			;469b   ; DE se salva y se restaura en cada vuelta: es el MISMO bloque el que se vuelve a descomprimir
	call descomprime_sin_espejo		;469c   ; por la puerta sin espejo
	ld de,00800h		;469f
	add hl,de			;46a2
	pop de			;46a3
	pop bc			;46a4
	djnz L_469A		;46a5
	ret			;46a7
descomprime_espejado_en_los_tres_tercios:		; igual, pero cada byte con los ocho bits del reves
	ld b,003h		;46a8
L_46AA:
	push bc			;46aa
	push de			;46ab
	call descomprime_con_espejo		;46ac   ; esta es la unica diferencia con la de arriba: la puerta con espejo
	ld de,00800h		;46af
	add hl,de			;46b2
	pop de			;46b3
	pop bc			;46b4
	djnz L_46AA		;46b5
	ret			;46b7
L_46B8:
	ld b,003h		;46b8   ; tres vueltas: los tres tercios de SCREEN 2
L_46BA:
	push bc			;46ba   ; y por aqui se entra pidiendo menos, que no todos los dibujos ocupan los tres
	push de			;46bb
	push hl			;46bc
	call descomprime_cambiando_el_color		;46bd   ; el descompresor que traduce el color de camiseta
	pop hl			;46c0
	ld de,00800h		;46c1   ; 0x800 de un tercio al siguiente
	add hl,de			;46c4
	pop de			;46c5
	pop bc			;46c6
	djnz L_46BA		;46c7
	ret			;46c9

; ----------------------------------------------------------------------
; ===== LOS ROTULOS: texto suelto sobre la tabla de nombres =====
; ----------------------------------------------------------------------
escribe_el_rotulo_en_hl:		; el destino ya viene en HL; el bloque son solo casillas
	ld c,0ffh		;46ca
	jr L_46D6		;46cc
escribe_un_rotulo:		; el destino va en los dos primeros bytes del propio bloque
	ld c,0ffh		;46ce   ; el 0xFF de la mascara deja pasar la casilla tal cual
L_46D0:
	ex de,hl			;46d0   ; el 0xFE del guion cae aqui: los dos bytes que siguen son la casilla nueva
	ld e,(hl)			;46d1
	inc hl			;46d2
	ld d,(hl)			;46d3
	ex de,hl			;46d4
	inc de			;46d5
L_46D6:
	ld a,(de)			;46d6   ; un byte, una casilla
	inc de			;46d7
	ld b,a			;46d8
	inc b			;46d9
	ret z			;46da   ; el 0xFF cierra el rotulo
	inc b			;46db
	jr z,L_46D0		;46dc   ; y el 0xFE cambia de destino: detras vienen los dos bytes de la casilla nueva
	and c			;46de   ; aqui es donde la mascara decide: 0xFF escribe y 0x00 deja un blanco
	call 0004dh		;46df   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;46e2
	jr L_46D6		;46e3
borra_un_rotulo:		; el mismo recorrido con la mascara a cero: cada casilla sale en blanco
	ld c,000h		;46e5
	jr L_46D0		;46e7
descomprime_en_la_ram:		; el mismo formato del descompresor, pero volcando en 0xE600 en vez de en la VRAM
	ld hl,0e600h		;46e9   ; 0xE600 es el desvan: unas veces la copia de la tabla de nombres del campo y otras, como en 0x76BF, un banco de sprites de paso
L_46EC:
	ld a,(de)			;46ec
	and a			;46ed
	ret z			;46ee
	inc de			;46ef
	ld b,a			;46f0
	and 07fh		;46f1   ; la cuenta, sin el bit 7
	cp b			;46f3   ; si el byte no cambio, el bit 7 estaba a cero: repeticion
	jr z,L_46FF		;46f4
	ld b,a			;46f6
L_46F7:
	ld a,(de)			;46f7   ; copia tal cual: los bytes que siguen, uno a uno
	ld (hl),a			;46f8
	inc de			;46f9
	inc hl			;46fa
	djnz L_46F7		;46fb
	jr L_46EC		;46fd
L_46FF:
	ld a,(de)			;46ff
	inc de			;4700
L_4701:
	ld (hl),a			;4701
	inc hl			;4702
	djnz L_4701		;4703
	jr L_46EC		;4705
descomprime_cambiando_el_color:		; como el descompresor normal, pero cada byte pasa por la tabla de (0xE52A)
	call abre_la_vram		;4707   ; no admite el mandato 0x80: el destino tiene que venir puesto en HL
L_470A:
	ld a,(de)			;470a   ; el mismo formato de mandatos que el descompresor de VRAM, pero sin el 0x80: aqui el destino tiene que venir ya puesto
	and a			;470b
	ret z			;470c   ; el cero cierra el bloque
	inc de			;470d
	ld b,a			;470e
	and 07fh		;470f   ; la cuenta va en los siete bits bajos...
	cp b			;4711   ; ...y el bit 7 separa el copiado de la repeticion
	jr z,L_4720		;4712
	ld b,a			;4714
L_4715:
	call traduce_los_dos_colores		;4715   ; y aqui, en vez del byte del flujo, va el byte ya traducido
	exx			;4718
	out (c),a		;4719
	exx			;471b
	djnz L_4715		;471c
	jr L_470A		;471e
L_4720:
	call traduce_los_dos_colores		;4720   ; y en la repeticion basta con traducirlo una vez
L_4723:
	exx			;4723
	out (c),a		;4724
	exx			;4726
	djnz L_4723		;4727
	jr L_470A		;4729

; ----------------------------------------------------------------------
; ===== LOS SPRITES: la rotacion que los hace parpadear en vez de desaparecer =====
; ----------------------------------------------------------------------
sube_los_sprites:		; vuelca la copia de RAM en 0x3B00, rotando el grupo del medio en cuadros alternos
	ld a,(0e537h)		;472b   ; con el bit 7 de (0xE537) puesto, el jugador destacado se saca de la tabla del equipo
	and a			;472e
	jp p,L_473D		;472f
	ld a,(0e527h)		;4732   ; (0xE527) elige equipo, y (0xE52C) o (0xE52D) traen su jugador
	ld hl,0e52ch		;4735
	and a			;4738
	jr z,L_473C		;4739
	inc l			;473b
L_473C:
	ld a,(hl)			;473c
L_473D:
	cp 006h		;473d   ; hasta dos veces se le quitan seis, y lo que pase de once se va a cero: seis jugadores por equipo
	jr c,L_4743		;473f
	sub 006h		;4741
L_4743:
	cp 006h		;4743
	jr c,L_4748		;4745
	xor a			;4747
L_4748:
	add a,a			;4748   ; por 16, que es lo que ocupan cuatro sprites
	add a,a			;4749
	add a,a			;474a
	add a,a			;474b
	ld hl,0e3a0h		;474c   ; 0xE3A0 es el sprite 4 de la copia; el grupo elegido se cambia por el primero...
	ld e,l			;474f
	ld d,h			;4750
	call suma_a_hl		;4751
	ld b,010h		;4754   ; ...intercambiando los dieciseis bytes uno a uno
L_4756:
	ld c,(hl)			;4756
	ld a,(de)			;4757
	ld (hl),a			;4758
	ld a,c			;4759
	ld (de),a			;475a
	inc hl			;475b
	inc de			;475c
	djnz L_4756		;475d
	ld a,(00007h)		;475f   ; el puerto de datos del VDP, que la BIOS deja en 0x0007
	ld c,a			;4762
	ld hl,03b00h		;4763   ; los ocho primeros sprites van siempre en el mismo sitio
	ld b,020h		;4766
	ld de,0e390h		;4768
	call sube_un_trozo_de_sprites		;476b
	ld hl,03b70h		;476e   ; y los cuatro ultimos, tambien
	ld de,0e400h		;4771
	ld b,010h		;4774
	call sube_un_trozo_de_sprites		;4776
	ld hl,03b20h		;4779
	ld a,(0e003h)		;477c   ; el bit 0 del contador de cuadros parte los veinte del medio en dos
	rra			;477f
	jr c,L_4789		;4780
	ld de,0e3b0h		;4782   ; en los cuadros pares, los veinte seguidos y en orden
	ld b,050h		;4785
	jr sube_un_trozo_de_sprites		;4787
L_4789:
	ld de,0e3e0h		;4789   ; y en los impares, los ocho ultimos primero...
	ld b,020h		;478c
	call sube_un_trozo_de_sprites		;478e
	ld hl,03b40h		;4791   ; ...y los doce primeros detras: el orden se da la vuelta cada cuadro, que es lo que hace que parpadeen en vez de desaparecer el quinto
	ld de,0e3b0h		;4794
	ld b,030h		;4797
sube_un_trozo_de_sprites:		; B bytes de DE a la VRAM, por el puerto de datos
	call 00053h		;4799   ; BIOS SETWRT - Enables VDP to write
L_479C:
	ld a,(de)			;479c
	out (c),a		;479d
	inc de			;479f
	djnz L_479C		;47a0
	ret			;47a2
copia_los_sprites:		; los 0x80 bytes de la copia de RAM a 0x3B00, sin rotar nada
	ld hl,03b00h		;47a3
	ld de,0e390h		;47a6
	ld bc,00080h		;47a9
	jp copia_a_la_vram		;47ac

; ----------------------------------------------------------------------
; ===== EL DESCOMPRESOR =====
; ----------------------------------------------------------------------
descomprime_con_destino_dentro:		; el destino de VRAM va en los dos primeros bytes del propio bloque
	ld c,000h		;47af   ; sin espejo
	ex de,hl			;47b1   ; saca la palabra de la cabecera del bloque
	ld e,(hl)			;47b2
	inc hl			;47b3
	ld d,(hl)			;47b4
	ex de,hl			;47b5
	inc de			;47b6   ; y el flujo empieza detras de ella
descomprime:		; un mandato por byte: 0x00 cierra, 0x80 cambia de destino, el bit 7 dice literal o repeticion
	call abre_la_vram		;47b7
L_47BA:
	ld a,(de)			;47ba   ; el mandato
	and a			;47bb   ; un 0x00 cierra el bloque, y es lo unico que marca donde acaba
	ret z			;47bc
	inc de			;47bd
	ld b,a			;47be   ; B se queda con el byte ENTERO, para poder compararlo
	and 07fh		;47bf   ; y aqui se le quita el bit 7
	cp b			;47c1   ; si coinciden es que el bit 7 estaba a cero: repeticion
	jr z,L_47D3		;47c2
	and a			;47c4   ; y si lo que queda es cero, el mandato era 0x80 exacto: destino nuevo
	jr z,descomprime_con_destino_dentro		;47c5
	ld b,a			;47c7
L_47C8:
	call lee_byte_del_flujo		;47c8   ; literal: (mandato & 0x7F) bytes tal cual
	exx			;47cb
	out (c),a		;47cc   ; por el puerto de datos, sin volver a fijar la direccion
	exx			;47ce
	djnz L_47C8		;47cf
	jr L_47BA		;47d1
L_47D3:
	call lee_byte_del_flujo		;47d3   ; repeticion: un solo byte...
L_47D6:
	exx			;47d6   ; ...sacado B veces
	out (c),a		;47d7
	exx			;47d9
	djnz L_47D6		;47da
	jr L_47BA		;47dc
descomprime_sin_espejo:		; la puerta C=0
	ld c,000h		;47de
	jr descomprime		;47e0
descomprime_con_espejo:		; la puerta C=1: el mismo bloque sirve para las dos mitades de un dibujo simetrico
	ld c,001h		;47e2
	jr descomprime		;47e4

; ----------------------------------------------------------------------
; ===== ESPEJAR SPRITES DE 16x16 =====
; ----------------------------------------------------------------------
espeja_sprites_en_la_vram:		; C sprites de 16x16, leidos de la VRAM y devueltos a la VRAM del reves
	call espeja_un_sprite_en_la_vram		;47e6
	ld a,020h		;47e9   ; de un sprite de 16x16 al siguiente hay 32 bytes
	call suma_a_de		;47eb
	dec c			;47ee
	jr nz,espeja_sprites_en_la_vram		;47ef
	ret			;47f1
espeja_sprites_desde_la_ram:		; los mismos C sprites, pero leidos de la RAM
	call espeja_un_sprite_desde_la_ram		;47f2   ; los C sprites, de 32 bytes cada uno
	ld a,020h		;47f5   ; 32 bytes mide un sprite de 16x16
	call suma_a_hl		;47f7
	dec c			;47fa
	jr nz,espeja_sprites_desde_la_ram		;47fb
	ret			;47fd
espeja_un_sprite_desde_la_ram:		; los 32 bytes de un 16x16, con las dos columnas cambiadas
	push hl			;47fe
L_47FF:
	ld b,010h		;47ff   ; dieciseis bytes, que es una columna del sprite
	call abre_la_vram		;4801
L_4804:
	ld a,(de)			;4804
	call espeja		;4805
	exx			;4808
	out (c),a		;4809
	exx			;480b
	inc l			;480c   ; el `inc l` no sale de la pagina: el sprite entero cabe en 256 bytes
	inc de			;480d
	djnz L_4804		;480e
	ld a,l			;4810   ; y aqui esta el truco: restando 0x20 despues de haber sumado 0x10 se retrocede media vuelta
	sub 020h		;4811
	ld l,a			;4813
	bit 4,l		;4814   ; el bit 4 dice si ya se han hecho las dos columnas
	jr z,L_47FF		;4816   ; asi que se escribe primero la columna derecha y luego la izquierda: eso es reflejar el dibujo entero
	pop hl			;4818
	ret			;4819
espeja_un_sprite_en_la_vram:		; igual, pero leyendo de la VRAM con RDVRM en vez de de la RAM
	push de			;481a
L_481B:
	ld b,010h		;481b
L_481D:
	call 0004ah		;481d   ; BIOS RDVRM - Reads the content of VRAM
	call espeja		;4820
	ex de,hl			;4823
	call 0004dh		;4824   ; BIOS WRTVRM - Writes data in VRAM
	ex de,hl			;4827
	inc e			;4828   ; el destino avanza con el salto de media vuelta y el origen, seguido
	inc hl			;4829
	djnz L_481D		;482a
	ld a,e			;482c
	sub 020h		;482d
	ld e,a			;482f
	bit 4,e		;4830
	jr z,L_481B		;4832
	pop de			;4834
	ret			;4835
lee_byte_del_flujo:		; saca el siguiente byte del bloque, y lo espeja si toca
	ld a,(de)			;4836
	inc de			;4837
	bit 0,c		;4838   ; el bit 0 de C es el que manda: 0 tal cual, 1 del reves
	ret z			;483a
espeja:		; los ocho bits del reves, que en un patron de SCREEN 2 es reflejarlo horizontalmente
	push bc			;483b
	ld c,a			;483c
	ld b,008h		;483d
L_483F:
	rr c		;483f   ; cada `rr` saca el bit de abajo y cada `rla` lo mete por arriba: ocho vueltas y el byte queda dado la vuelta
	rla			;4841
	djnz L_483F		;4842
	pop bc			;4844
	ret			;4845
traduce_los_dos_colores:		; cada nibble del byte pasa por la tabla de 16 entradas de (0xE52A)
	ld hl,(0e52ah)		;4846   ; (0xE52A) apunta a la tabla de traduccion; 0x7352 y 0x7361 la cambian para pintar lo mismo con los colores de cada equipo
	push hl			;4849
	ld a,(de)			;484a
	and 0f0h		;484b   ; el nibble de arriba, que en un byte de color de SCREEN 2 es la tinta
	rra			;484d
	rra			;484e
	rra			;484f
	rra			;4850
	call suma_a_hl		;4851   ; la tabla se indexa con el color viejo...
	ld a,(hl)			;4854
	rla			;4855   ; ...y el nuevo vuelve a su sitio de arriba; ojo, que este primer `rla` arrastra el acarreo que dejo suma_a_hl
	rla			;4856
	rla			;4857
	rla			;4858
	ld c,a			;4859
	pop hl			;485a
	ld a,(de)			;485b   ; y el nibble de abajo, el fondo, por la misma tabla
	and 00fh		;485c
	call suma_a_hl		;485e
	ld a,(hl)			;4861
	or c			;4862   ; los dos juntos otra vez en un byte
	inc de			;4863
	ret			;4864
prepara_la_pantalla:		; el arranque del VDP: los 16 KB de VRAM a cero y detras los ocho registros
	ld a,0b8h		;4865
	call escribe_el_mezclador		;4867
	ld a,034h		;486a
	call L_40C0		;486c
	xor a			;486f
	ld h,a			;4870
	ld l,a			;4871
	ld bc,04000h		;4872   ; 0x4000 bytes: la VRAM entera
	call rellena_la_vram		;4875

; ----------------------------------------------------------------------
; ===== La pantalla: los ocho registros del VDP =====
; ----------------------------------------------------------------------
pone_la_pantalla:		; vuelca los ocho bytes de 0x4889 en R0..R7
	ld hl,04889h		;4878   ; los ocho bytes
	ld d,008h		;487b   ; ocho registros
	ld c,000h		;487d   ; empezando por R0
L_487F:
	ld b,(hl)			;487f
	call 00047h		;4880   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP con el valor en B y el numero de registro en C
	inc hl			;4883
	inc c			;4884
	dec d			;4885
	jr nz,L_487F		;4886
	ret			;4888

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: R0..R7 tal como los vuelca L_4878; SCREEN 2 con
;   NOMBRES en 0x3800, COLOR en 0x0000 y PATRONES en 0x2000. Los OCHO bytes
;   son identicos a los de Ping Pong y Road Fighter
;   0x4889..0x4891  (8 bytes)
DATA_registros_del_vdp:
	defb 002h	; 4889
	defb 0e2h	; 488a
	defb 00eh	; 488b
	defb 07fh	; 488c
	defb 007h	; 488d
	defb 076h	; 488e
	defb 003h	; 488f
	defb 0e4h	; 4890

; ======================================================================
; CODIGO 0x4891..0x4939  (168 bytes)
; ======================================================================


pone_el_color_del_borde:		; R7, que es tinta y fondo a la vez
	ld c,007h		;4891
	jp pone_registro_del_vdp		;4893

; ----------------------------------------------------------------------
; ===== LOS DOS MANDOS =====
; ----------------------------------------------------------------------
lee_los_mandos:		; el latido la llama una vez por cuadro, antes que a nada
	call lee_el_mando_1		;4896
	ld hl,0e007h		;4899   ; (0xE007) es lo que hay pulsado y (0xE006) lo recien pulsado
	call guarda_y_marca_lo_recien_pulsado		;489c
	ld a,(0e000h)		;489f   ; por debajo de la escena 5, o sea en la presentacion, el segundo mando se lee siempre
	cp 005h		;48a2
	jr c,L_48AC		;48a4
	ld a,(0e002h)		;48a6   ; y ya en el partido, solo si el bit 5 dice que son dos jugadores
	bit 5,a		;48a9
	ret z			;48ab
L_48AC:
	call lee_el_mando_2		;48ac
	ld hl,0e009h		;48af   ; (0xE009) y (0xE008), los mismos dos bytes del segundo
guarda_y_marca_lo_recien_pulsado:		; deja lo pulsado en (HL) y en (HL-1) solo lo que acaba de cambiar de apagado a encendido
	ld c,(hl)			;48b2   ; lo de antes
	ld (hl),a			;48b3
	xor c			;48b4   ; los bits que han cambiado...
	and (hl)			;48b5   ; ...y de esos, los que ahora estan puestos: los recien pulsados
	dec hl			;48b6
	ld (hl),a			;48b7
	ret			;48b8
lee_el_mando_1:		; el mando del puerto 1, mas las teclas de cursor y la barra
	ld e,08fh		;48b9   ; el 0x8F en el registro 15 del PSG elige el puerto de mandos 1
	ld a,00fh		;48bb
	call 00093h		;48bd   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;48c0   ; y el 14 es donde se lee
	di			;48c2
	call 00096h		;48c3   ; BIOS RDPSG - Reads value from PSG-register
	ei			;48c6
	cpl			;48c7   ; el mando da 0 al pulsar, asi que se le da la vuelta
	and 03fh		;48c8   ; seis bits: arriba, abajo, izquierda, derecha y los dos disparos
	push af			;48ca
	ld a,007h		;48cb   ; la fila 7 de la matriz del teclado
	call 00141h		;48cd   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;48d0
	rrca			;48d1   ; un giro deja su bit 6 en el bit 5, que en el mando es el segundo disparo
	and 020h		;48d2
	ld e,a			;48d4
	ld a,008h		;48d5   ; y la fila 8, que es donde estan las cuatro flechas y la barra
	call 00141h		;48d7   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;48da
	rrca			;48db
	rrca			;48dc
	ld b,a			;48dd
	and 004h		;48de   ; dos giros: la izquierda cae en el bit 2
	or e			;48e0
	ld c,a			;48e1
	ld a,b			;48e2
	rrca			;48e3
	rrca			;48e4
	ld b,a			;48e5
	and 018h		;48e6   ; cuatro: la derecha en el bit 3 y la barra en el bit 4, que es el disparo
	or c			;48e8
	ld c,a			;48e9
	ld a,b			;48ea
	rrca			;48eb   ; cinco: arriba en el bit 0 y abajo en el bit 1
	and 003h		;48ec
	or c			;48ee
	pop bc			;48ef   ; y encima de todo eso, lo que dijera el mando
	or b			;48f0
	ret			;48f1
lee_el_mando_2:		; el mando del puerto 2, mas las teclas E, S, D, F y C alrededor de la D
	ld e,0cfh		;48f2   ; el 0xCF en el registro 15 elige el puerto de mandos 2
	ld a,00fh		;48f4
	call 00093h		;48f6   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;48f9
	di			;48fb
	call 00096h		;48fc   ; BIOS RDPSG - Reads value from PSG-register
	ei			;48ff
	cpl			;4900
	and 03fh		;4901
	push af			;4903
	ld a,005h		;4904   ; la fila 5 de la matriz, la de la S
	call 00141h		;4906   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4909
	rlca			;490a   ; dos giros a la izquierda dejan la S en el bit 2, que es la izquierda
	rlca			;490b
	and 004h		;490c
	ld e,a			;490e
	ld a,003h		;490f   ; la fila 3, la de la C, la E y la F
	call 00141h		;4911   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4914
	ld b,a			;4915
	and 008h		;4916   ; la F ya esta en el bit 3, que es la derecha
	or e			;4918
	ld e,a			;4919
	ld a,b			;491a
	rlca			;491b   ; un giro deja la C en el bit 1, que es abajo
	ld b,a			;491c
	and 002h		;491d
	or e			;491f
	ld e,a			;4920
	ld a,b			;4921
	rrca			;4922   ; y tres a la derecha dejan la E en el bit 0, que es arriba
	rrca			;4923
	rrca			;4924
	and 001h		;4925
	or e			;4927
	ld e,a			;4928
	ld a,006h		;4929   ; la fila 6, la de las teclas de control
	call 00141h		;492b   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;492e
	rlca			;492f   ; cuatro giros dejan su bit 0 en el bit 4: el disparo
	rlca			;4930
	rlca			;4931
	rlca			;4932
	and 010h		;4933
	or e			;4935
	pop bc			;4936
	or b			;4937
	ret			;4938

; ----------------------------------------------------------------------
; DATOS nombres_4939: 17 bytes comprimidos que dan 20 de VRAM en 0x394A; lo
;   carga 0x4103. Se reparte en varios tramos (mandatos 0x80): 0x394A(12),
;   0x396C(8)
;   0x4939..0x494a  (17 bytes)
DATA_nombres_4939:
	defb 04ah	; 4939
	defb 039h	; 493a
	defb 00ch	; 493b
	defb 05ah	; 493c
	defb 080h	; 493d
	defb 06ch	; 493e
	defb 039h	; 493f
	defb 088h	; 4940
	defb 033h	; 4941
	defb 02fh	; 4942
	defb 026h	; 4943
	defb 034h	; 4944
	defb 037h	; 4945
	defb 021h	; 4946
	defb 032h	; 4947
	defb 025h	; 4948
	defb 000h	; 4949

; ----------------------------------------------------------------------
; DATOS rotulos_de_los_menus: los 22 guiones de la presentacion y los menus,
;   uno detras de otro y sin hueco; los pinta el interprete de L_46CE
;   0x494a..0x4a36  (236 bytes)
DATA_rotulos_de_los_menus:
	defb 04ah	; 494a
	defb 039h	; 494b
	defb 01ah	; 494c
	defb 02bh	; 494d
	defb 02fh	; 494e
	defb 02eh	; 494f
	defb 021h	; 4950
	defb 02dh	; 4951
	defb 029h	; 4952
	defb 000h	; 4953
	defb 011h	; 4954
	defb 019h	; 4955
	defb 018h	; 4956
	defb 015h	; 4957
	defb 0feh	; 4958
	defb 00bh	; 4959
	defb 03ah	; 495a
	defb 030h	; 495b
	defb 02ch	; 495c
	defb 021h	; 495d
	defb 039h	; 495e
	defb 000h	; 495f
	defb 033h	; 4960
	defb 025h	; 4961
	defb 02ch	; 4962
	defb 025h	; 4963
	defb 023h	; 4964
	defb 034h	; 4965
	defb 0feh	; 4966
	defb 06dh	; 4967
	defb 03ah	; 4968
	defb 011h	; 4969
	defb 030h	; 496a
	defb 02ch	; 496b
	defb 021h	; 496c
	defb 039h	; 496d
	defb 025h	; 496e
	defb 032h	; 496f
	defb 0ffh	; 4970
	defb 0adh	; 4971
	defb 03ah	; 4972
	defb 012h	; 4973
	defb 030h	; 4974
	defb 02ch	; 4975
	defb 021h	; 4976
	defb 039h	; 4977
	defb 025h	; 4978
	defb 032h	; 4979
	defb 033h	; 497a
	defb 0ffh	; 497b
	defb 01bh	; 497c
	defb 01ch	; 497d
	defb 0ffh	; 497e
	defb 00ah	; 497f
	defb 038h	; 4980
	defb 020h	; 4981
	defb 0ffh	; 4982
	defb 015h	; 4983
	defb 038h	; 4984
	defb 034h	; 4985
	defb 029h	; 4986
	defb 02dh	; 4987
	defb 025h	; 4988
	defb 000h	; 4989
	defb 000h	; 498a
	defb 000h	; 498b
	defb 01eh	; 498c
	defb 0ffh	; 498d
	defb 016h	; 498e
	defb 038h	; 498f
	defb 030h	; 4990
	defb 02bh	; 4991
	defb 0feh	; 4992
	defb 01bh	; 4993
	defb 038h	; 4994
	defb 020h	; 4995
	defb 0ffh	; 4996
	defb 008h	; 4997
	defb 039h	; 4998
	defb 030h	; 4999
	defb 025h	; 499a
	defb 02eh	; 499b
	defb 021h	; 499c
	defb 02ch	; 499d
	defb 034h	; 499e
	defb 039h	; 499f
	defb 000h	; 49a0
	defb 033h	; 49a1
	defb 028h	; 49a2
	defb 02fh	; 49a3
	defb 02fh	; 49a4
	defb 034h	; 49a5
	defb 000h	; 49a6
	defb 02fh	; 49a7
	defb 035h	; 49a8
	defb 034h	; 49a9
	defb 0ffh	; 49aa
	defb 044h	; 49ab
	defb 038h	; 49ac
	defb 034h	; 49ad
	defb 025h	; 49ae
	defb 021h	; 49af
	defb 02dh	; 49b0
	defb 000h	; 49b1
	defb 023h	; 49b2
	defb 02fh	; 49b3
	defb 02ch	; 49b4
	defb 02fh	; 49b5
	defb 032h	; 49b6
	defb 0feh	; 49b7
	defb 084h	; 49b8
	defb 039h	; 49b9
	defb 033h	; 49ba
	defb 02bh	; 49bb
	defb 029h	; 49bc
	defb 02ch	; 49bd
	defb 02ch	; 49be
	defb 000h	; 49bf
	defb 02ch	; 49c0
	defb 025h	; 49c1
	defb 036h	; 49c2
	defb 025h	; 49c3
	defb 02ch	; 49c4
	defb 0feh	; 49c5
	defb 092h	; 49c6
	defb 039h	; 49c7
	defb 011h	; 49c8
	defb 000h	; 49c9
	defb 012h	; 49ca
	defb 000h	; 49cb
	defb 013h	; 49cc
	defb 000h	; 49cd
	defb 014h	; 49ce
	defb 000h	; 49cf
	defb 015h	; 49d0
	defb 0feh	; 49d1
	defb 0e4h	; 49d2
	defb 039h	; 49d3
	defb 028h	; 49d4
	defb 021h	; 49d5
	defb 02ch	; 49d6
	defb 026h	; 49d7
	defb 000h	; 49d8
	defb 034h	; 49d9
	defb 029h	; 49da
	defb 02dh	; 49db
	defb 025h	; 49dc
	defb 0feh	; 49dd
	defb 0f2h	; 49de
	defb 039h	; 49df
	defb 013h	; 49e0
	defb 000h	; 49e1
	defb 000h	; 49e2
	defb 000h	; 49e3
	defb 015h	; 49e4
	defb 000h	; 49e5
	defb 000h	; 49e6
	defb 011h	; 49e7
	defb 010h	; 49e8
	defb 0feh	; 49e9
	defb 044h	; 49ea
	defb 03ah	; 49eb
	defb 025h	; 49ec
	defb 02eh	; 49ed
	defb 034h	; 49ee
	defb 025h	; 49ef
	defb 032h	; 49f0
	defb 000h	; 49f1
	defb 039h	; 49f2
	defb 02fh	; 49f3
	defb 035h	; 49f4
	defb 032h	; 49f5
	defb 000h	; 49f6
	defb 034h	; 49f7
	defb 025h	; 49f8
	defb 021h	; 49f9
	defb 02dh	; 49fa
	defb 000h	; 49fb
	defb 02eh	; 49fc
	defb 021h	; 49fd
	defb 02dh	; 49fe
	defb 025h	; 49ff
	defb 01fh	; 4a00
	defb 0feh	; 4a01
	defb 086h	; 4a02
	defb 03ah	; 4a03
	defb 011h	; 4a04
	defb 035h	; 4a05
	defb 030h	; 4a06
	defb 020h	; 4a07
	defb 0feh	; 4a08
	defb 091h	; 4a09
	defb 03ah	; 4a0a
	defb 023h	; 4a0b
	defb 030h	; 4a0c
	defb 035h	; 4a0d
	defb 020h	; 4a0e
	defb 0feh	; 4a0f
	defb 0aah	; 4a10
	defb 03ah	; 4a11
	defb 070h	; 4a12
	defb 070h	; 4a13
	defb 070h	; 4a14
	defb 070h	; 4a15
	defb 070h	; 4a16
	defb 070h	; 4a17
	defb 0feh	; 4a18
	defb 0b5h	; 4a19
	defb 03ah	; 4a1a
	defb 070h	; 4a1b
	defb 070h	; 4a1c
	defb 070h	; 4a1d
	defb 070h	; 4a1e
	defb 070h	; 4a1f
	defb 070h	; 4a20
	defb 0ffh	; 4a21
	defb 084h	; 4a22
	defb 039h	; 4a23
	defb 028h	; 4a24
	defb 021h	; 4a25
	defb 02eh	; 4a26
	defb 024h	; 4a27
	defb 029h	; 4a28
	defb 023h	; 4a29
	defb 021h	; 4a2a
	defb 030h	; 4a2b
	defb 000h	; 4a2c
	defb 000h	; 4a2d
	defb 000h	; 4a2e
	defb 0ffh	; 4a2f
	defb 02ch	; 4a30
	defb 025h	; 4a31
	defb 036h	; 4a32
	defb 025h	; 4a33
	defb 02ch	; 4a34
	defb 0ffh	; 4a35

; ======================================================================
; CODIGO 0x4a36..0x4a6c  (54 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LA FUENTE DE TEXTO Y LOS DIECISEIS BLOQUES DE COLOR =====
; ----------------------------------------------------------------------
carga_la_fuente:		; deja los tiles 0x00..0x0F como cuadrados de color y encima carga las letras
	call pinta_los_tiles_de_color		;4a36   ; antes de la fuente, los dieciseis primeros tiles
	ld de,04a6ch		;4a39   ; el bloque comprimido de la fuente: 332 bytes que dan 352 de VRAM
	ld hl,02080h		;4a3c   ; 0x2080 son los PATRONES a partir del tile 0x10 (0x80 entre 8 son dieciseis tiles)
	call descomprime_en_los_tres_tercios		;4a3f   ; 352 bytes son 44 tiles, del 0x10 al 0x3B: las diez cifras, unos cuantos signos y las veintiseis letras
	ld de,04bb8h		;4a42   ; y ahora el COLOR de esos mismos 44 tiles
	ld hl,00080h		;4a45   ; 0x0080 es la casilla de color del tile 0x10; casi todo sale 0xF0, tinta blanca sobre fondo transparente
	jp descomprime_en_los_tres_tercios		;4a48
pinta_los_tiles_de_color:		; el tile N queda como un cuadrado macizo del color N del MSX
	ld hl,02000h		;4a4b   ; 0x2000 es el patron del tile 0x00
	ld bc,00080h		;4a4e   ; 0x80 bytes son las ocho lineas de los dieciseis primeros tiles
	xor a			;4a51   ; todos los bits a cero: ni un pixel de tinta, el dibujo entero es fondo
	call rellena_los_tres_tercios		;4a52   ; y en los tres tercios, que en SCREEN 2 son tres juegos de patrones independientes
	ld hl,00000h		;4a55   ; ahora la tabla de COLOR, que en este juego empieza en 0x0000
	ld de,00008h		;4a58   ; el paso de un tile al siguiente: ocho bytes, uno por linea
	ld b,010h		;4a5b   ; los dieciseis tiles, del 0x00 al 0x0F
L_4A5D:
	push bc			;4a5d   ; se guarda la cuenta de tiles...
	ld bc,00008h		;4a5e   ; ...porque BC es la cuenta de BYTES del relleno: las ocho lineas del tile
	push hl			;4a61
	call rellena_los_tres_tercios		;4a62   ; el color del tile N queda valiendo N, o sea tinta 0 (transparente) y fondo N
	pop hl			;4a65
	add hl,de			;4a66   ; al color del tile siguiente
	inc a			;4a67   ; y al color siguiente: con el patron a cero, el tile N se ve como un cuadrado macizo del color N
	pop bc			;4a68
	djnz L_4A5D		;4a69   ; asi los dieciseis
	ret			;4a6b

; ----------------------------------------------------------------------
; DATOS patrones_4a6c: 332 bytes comprimidos que dan 352 de VRAM en 0x2080; lo
;   cargan 2 sitios (0x4A3F, 0x5E4A). Va a los TRES tercios de SCREEN 2
;   0x4a6c..0x4bb8  (332 bytes)
DATA_patrones_4a6c:
	defb 082h	; 4a6c
	defb 01ch	; 4a6d
	defb 022h	; 4a6e
	defb 003h	; 4a6f
	defb 063h	; 4a70
	defb 085h	; 4a71
	defb 022h	; 4a72
	defb 01ch	; 4a73
	defb 000h	; 4a74
	defb 018h	; 4a75
	defb 038h	; 4a76
	defb 004h	; 4a77
	defb 018h	; 4a78
	defb 0aeh	; 4a79
	defb 07eh	; 4a7a
	defb 000h	; 4a7b
	defb 03eh	; 4a7c
	defb 063h	; 4a7d
	defb 003h	; 4a7e
	defb 00eh	; 4a7f
	defb 03ch	; 4a80
	defb 070h	; 4a81
	defb 07fh	; 4a82
	defb 000h	; 4a83
	defb 03eh	; 4a84
	defb 063h	; 4a85
	defb 003h	; 4a86
	defb 00eh	; 4a87
	defb 003h	; 4a88
	defb 063h	; 4a89
	defb 03eh	; 4a8a
	defb 000h	; 4a8b
	defb 00eh	; 4a8c
	defb 01eh	; 4a8d
	defb 036h	; 4a8e
	defb 066h	; 4a8f
	defb 066h	; 4a90
	defb 07fh	; 4a91
	defb 006h	; 4a92
	defb 000h	; 4a93
	defb 07fh	; 4a94
	defb 060h	; 4a95
	defb 07eh	; 4a96
	defb 063h	; 4a97
	defb 003h	; 4a98
	defb 063h	; 4a99
	defb 03eh	; 4a9a
	defb 000h	; 4a9b
	defb 03eh	; 4a9c
	defb 063h	; 4a9d
	defb 060h	; 4a9e
	defb 07eh	; 4a9f
	defb 063h	; 4aa0
	defb 063h	; 4aa1
	defb 03eh	; 4aa2
	defb 000h	; 4aa3
	defb 07fh	; 4aa4
	defb 063h	; 4aa5
	defb 006h	; 4aa6
	defb 00ch	; 4aa7
	defb 003h	; 4aa8
	defb 018h	; 4aa9
	defb 09bh	; 4aaa
	defb 000h	; 4aab
	defb 03eh	; 4aac
	defb 063h	; 4aad
	defb 063h	; 4aae
	defb 03eh	; 4aaf
	defb 063h	; 4ab0
	defb 063h	; 4ab1
	defb 03eh	; 4ab2
	defb 000h	; 4ab3
	defb 03eh	; 4ab4
	defb 063h	; 4ab5
	defb 063h	; 4ab6
	defb 03fh	; 4ab7
	defb 003h	; 4ab8
	defb 063h	; 4ab9
	defb 03eh	; 4aba
	defb 000h	; 4abb
	defb 03ch	; 4abc
	defb 042h	; 4abd
	defb 099h	; 4abe
	defb 0a1h	; 4abf
	defb 0a1h	; 4ac0
	defb 099h	; 4ac1
	defb 042h	; 4ac2
	defb 03ch	; 4ac3
	defb 00fh	; 4ac4
	defb 01fh	; 4ac5
	defb 004h	; 4ac6
	defb 0ffh	; 4ac7
	defb 089h	; 4ac8
	defb 00fh	; 4ac9
	defb 000h	; 4aca
	defb 000h	; 4acb
	defb 0feh	; 4acc
	defb 0e0h	; 4acd
	defb 0e0h	; 4ace
	defb 0c0h	; 4acf
	defb 0c0h	; 4ad0
	defb 080h	; 4ad1
	defb 007h	; 4ad2
	defb 000h	; 4ad3
	defb 002h	; 4ad4
	defb 030h	; 4ad5
	defb 002h	; 4ad6
	defb 000h	; 4ad7
	defb 002h	; 4ad8
	defb 038h	; 4ad9
	defb 085h	; 4ada
	defb 000h	; 4adb
	defb 038h	; 4adc
	defb 038h	; 4add
	defb 000h	; 4ade
	defb 018h	; 4adf
	defb 003h	; 4ae0
	defb 03ch	; 4ae1
	defb 084h	; 4ae2
	defb 018h	; 4ae3
	defb 000h	; 4ae4
	defb 018h	; 4ae5
	defb 018h	; 4ae6
	defb 003h	; 4ae7
	defb 000h	; 4ae8
	defb 081h	; 4ae9
	defb 07eh	; 4aea
	defb 004h	; 4aeb
	defb 000h	; 4aec
	defb 092h	; 4aed
	defb 01ch	; 4aee
	defb 036h	; 4aef
	defb 063h	; 4af0
	defb 063h	; 4af1
	defb 07fh	; 4af2
	defb 063h	; 4af3
	defb 063h	; 4af4
	defb 000h	; 4af5
	defb 07eh	; 4af6
	defb 063h	; 4af7
	defb 063h	; 4af8
	defb 07eh	; 4af9
	defb 063h	; 4afa
	defb 063h	; 4afb
	defb 07eh	; 4afc
	defb 000h	; 4afd
	defb 03eh	; 4afe
	defb 063h	; 4aff
	defb 003h	; 4b00
	defb 060h	; 4b01
	defb 085h	; 4b02
	defb 063h	; 4b03
	defb 03eh	; 4b04
	defb 000h	; 4b05
	defb 07ch	; 4b06
	defb 066h	; 4b07
	defb 003h	; 4b08
	defb 063h	; 4b09
	defb 08fh	; 4b0a
	defb 066h	; 4b0b
	defb 07ch	; 4b0c
	defb 000h	; 4b0d
	defb 07fh	; 4b0e
	defb 060h	; 4b0f
	defb 060h	; 4b10
	defb 07eh	; 4b11
	defb 060h	; 4b12
	defb 060h	; 4b13
	defb 07fh	; 4b14
	defb 000h	; 4b15
	defb 07fh	; 4b16
	defb 060h	; 4b17
	defb 060h	; 4b18
	defb 07eh	; 4b19
	defb 003h	; 4b1a
	defb 060h	; 4b1b
	defb 089h	; 4b1c
	defb 000h	; 4b1d
	defb 03eh	; 4b1e
	defb 063h	; 4b1f
	defb 060h	; 4b20
	defb 067h	; 4b21
	defb 063h	; 4b22
	defb 063h	; 4b23
	defb 03fh	; 4b24
	defb 000h	; 4b25
	defb 003h	; 4b26
	defb 063h	; 4b27
	defb 081h	; 4b28
	defb 07fh	; 4b29
	defb 003h	; 4b2a
	defb 063h	; 4b2b
	defb 082h	; 4b2c
	defb 000h	; 4b2d
	defb 03ch	; 4b2e
	defb 005h	; 4b2f
	defb 018h	; 4b30
	defb 083h	; 4b31
	defb 03ch	; 4b32
	defb 000h	; 4b33
	defb 01fh	; 4b34
	defb 004h	; 4b35
	defb 006h	; 4b36
	defb 08bh	; 4b37
	defb 066h	; 4b38
	defb 03ch	; 4b39
	defb 000h	; 4b3a
	defb 063h	; 4b3b
	defb 066h	; 4b3c
	defb 06ch	; 4b3d
	defb 078h	; 4b3e
	defb 07ch	; 4b3f
	defb 06eh	; 4b40
	defb 067h	; 4b41
	defb 000h	; 4b42
	defb 006h	; 4b43
	defb 060h	; 4b44
	defb 093h	; 4b45
	defb 07fh	; 4b46
	defb 000h	; 4b47
	defb 063h	; 4b48
	defb 077h	; 4b49
	defb 07fh	; 4b4a
	defb 07fh	; 4b4b
	defb 06bh	; 4b4c
	defb 063h	; 4b4d
	defb 063h	; 4b4e
	defb 000h	; 4b4f
	defb 063h	; 4b50
	defb 073h	; 4b51
	defb 07bh	; 4b52
	defb 07fh	; 4b53
	defb 06fh	; 4b54
	defb 067h	; 4b55
	defb 063h	; 4b56
	defb 000h	; 4b57
	defb 03eh	; 4b58
	defb 005h	; 4b59
	defb 063h	; 4b5a
	defb 083h	; 4b5b
	defb 03eh	; 4b5c
	defb 000h	; 4b5d
	defb 07eh	; 4b5e
	defb 003h	; 4b5f
	defb 063h	; 4b60
	defb 085h	; 4b61
	defb 07eh	; 4b62
	defb 060h	; 4b63
	defb 060h	; 4b64
	defb 000h	; 4b65
	defb 03eh	; 4b66
	defb 003h	; 4b67
	defb 063h	; 4b68
	defb 095h	; 4b69
	defb 06fh	; 4b6a
	defb 066h	; 4b6b
	defb 03dh	; 4b6c
	defb 000h	; 4b6d
	defb 07eh	; 4b6e
	defb 063h	; 4b6f
	defb 063h	; 4b70
	defb 062h	; 4b71
	defb 07ch	; 4b72
	defb 066h	; 4b73
	defb 063h	; 4b74
	defb 000h	; 4b75
	defb 03eh	; 4b76
	defb 063h	; 4b77
	defb 060h	; 4b78
	defb 03eh	; 4b79
	defb 003h	; 4b7a
	defb 063h	; 4b7b
	defb 03eh	; 4b7c
	defb 000h	; 4b7d
	defb 07eh	; 4b7e
	defb 006h	; 4b7f
	defb 018h	; 4b80
	defb 081h	; 4b81
	defb 000h	; 4b82
	defb 006h	; 4b83
	defb 063h	; 4b84
	defb 082h	; 4b85
	defb 03eh	; 4b86
	defb 000h	; 4b87
	defb 004h	; 4b88
	defb 063h	; 4b89
	defb 098h	; 4b8a
	defb 036h	; 4b8b
	defb 01ch	; 4b8c
	defb 008h	; 4b8d
	defb 000h	; 4b8e
	defb 063h	; 4b8f
	defb 063h	; 4b90
	defb 06bh	; 4b91
	defb 06bh	; 4b92
	defb 07fh	; 4b93
	defb 077h	; 4b94
	defb 022h	; 4b95
	defb 000h	; 4b96
	defb 063h	; 4b97
	defb 076h	; 4b98
	defb 03ch	; 4b99
	defb 01ch	; 4b9a
	defb 01eh	; 4b9b
	defb 037h	; 4b9c
	defb 063h	; 4b9d
	defb 000h	; 4b9e
	defb 066h	; 4b9f
	defb 066h	; 4ba0
	defb 07eh	; 4ba1
	defb 03ch	; 4ba2
	defb 003h	; 4ba3
	defb 018h	; 4ba4
	defb 088h	; 4ba5
	defb 000h	; 4ba6
	defb 07fh	; 4ba7
	defb 007h	; 4ba8
	defb 00eh	; 4ba9
	defb 01ch	; 4baa
	defb 038h	; 4bab
	defb 070h	; 4bac
	defb 07fh	; 4bad
	defb 003h	; 4bae
	defb 000h	; 4baf
	defb 086h	; 4bb0
	defb 018h	; 4bb1
	defb 03ch	; 4bb2
	defb 03ch	; 4bb3
	defb 018h	; 4bb4
	defb 000h	; 4bb5
	defb 000h	; 4bb6
	defb 000h	; 4bb7

; ----------------------------------------------------------------------
; DATOS color_4bb8: 13 bytes comprimidos que dan 352 de VRAM en 0x0080; lo
;   carga 0x4A48. Va a los TRES tercios de SCREEN 2
;   0x4bb8..0x4bc5  (13 bytes)
DATA_color_4bb8:
	defb 07fh	; 4bb8
	defb 0f0h	; 4bb9
	defb 07fh	; 4bba
	defb 0f0h	; 4bbb
	defb 05ch	; 4bbc
	defb 0f0h	; 4bbd
	defb 002h	; 4bbe
	defb 0b0h	; 4bbf
	defb 002h	; 4bc0
	defb 0a0h	; 4bc1
	defb 002h	; 4bc2
	defb 000h	; 4bc3
	defb 000h	; 4bc4

; ======================================================================
; CODIGO 0x4bc5..0x4c19  (84 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL LOGOTIPO DE KONAMI, QUE SUBE DESDE ABAJO =====
; ----------------------------------------------------------------------
arranca_el_logotipo_de_konami:		; lo coloca abajo del todo y le pone catorce pasadas de subida
	ld a,00eh		;4bc5   ; catorce pasadas, que son catorce filas de pantalla
	ld (0e00ah),a		;4bc7   ; (0xE00A) lleva la cuenta de las que quedan
	ld hl,03aaah		;4bca   ; 0x3AAA en la tabla de NOMBRES es la fila 21, columna 10: el borde de abajo
	ld (0e00eh),hl		;4bcd   ; (0xE00E) es la casilla donde toca dibujarlo la proxima vez
	jp L_4025		;4bd0   ; pasa por 0x4025 y vuelve aqui mismo, a la carga de los tiles
carga_los_tiles_del_logotipo:		; los veintisiete dibujos con que se arma la palabra KONAMI
	ld de,04c19h		;4bd3   ; el bloque comprimido, 151 bytes que dan 216 de VRAM
	ld hl,02200h		;4bd6   ; 0x2200 son los patrones a partir del tile 0x40
	call descomprime_en_los_tres_tercios		;4bd9   ; 216 bytes son 27 tiles, del 0x40 al 0x5A: la K grande, ONAMI y el circulito de la (c)
	ld hl,00200h		;4bdc   ; 0x0200 es el color de esos mismos tiles
	ld bc,000d8h		;4bdf   ; las mismas 216 casillas
	ld a,0f0h		;4be2   ; 0xF0 en todas: tinta blanca y fondo transparente, el logotipo entero de un solo color
	jp rellena_los_tres_tercios		;4be4
sube_el_logotipo_una_fila:		; lo repinta una fila mas arriba y borra el rastro que deja debajo
	ld hl,(0e00eh)		;4be7   ; la casilla donde quedo la vez anterior
	ld de,0ffe0h		;4bea   ; 0xFFE0 es -32, que es una fila entera de pantalla hacia arriba
	add hl,de			;4bed
	ld (0e00eh),hl		;4bee   ; y se apunta para la proxima pasada
	ld a,040h		;4bf1   ; los tiles del logotipo estan numerados en el mismo orden en que se pintan, a partir del 0x40
	ld b,003h		;4bf3   ; la fila de arriba solo lleva tres tiles: el brazo alto de la K, que es mas alta que las demas letras
	call pinta_una_fila_de_tiles_seguidos		;4bf5   ; tiles 0x40..0x42, y HL sale apuntando a la fila de abajo
	ld bc,00b0ch		;4bf8   ; B = 11 tiles para la fila de en medio, y de paso C se queda con los 12 de la de abajo
	call pinta_una_fila_de_tiles_seguidos		;4bfb   ; tiles 0x43..0x4D: la mitad alta de las letras
	ld b,c			;4bfe   ; la fila de abajo, que es la mas ancha
	call pinta_una_fila_de_tiles_seguidos		;4bff   ; tiles 0x4E..0x59: la mitad baja de las letras y la (c) de copyright
	xor a			;4c02   ; y ahora se borra el rastro
	call rellena_la_vram		;4c03   ; BC vale 12 de la ultima vuelta y HL esta en la fila de debajo del logotipo: se limpian las doce casillas que acaba de dejar atras
	ld hl,0e00ah		;4c06   ; una pasada menos
	dec (hl)			;4c09   ; vuelve con Z cuando se agotan: el logotipo ha llegado arriba y la escena puede seguir
	ret			;4c0a
pinta_una_fila_de_tiles_seguidos:		; B casillas con los tiles A, A+1, A+2...; deja HL en la fila de abajo
	push hl			;4c0b   ; se guarda el principio de la fila
L_4C0C:
	call 0004dh		;4c0c   ; BIOS WRTVRM - Writes data in VRAM | una casilla de la tabla de nombres
	inc hl			;4c0f
	inc a			;4c10   ; el tile siguiente: el dibujo va numerado de corrido, asi que no hace falta ninguna tabla
	djnz L_4C0C		;4c11
	pop de			;4c13
	ld hl,00020h		;4c14   ; 32 casillas son una fila de pantalla
	add hl,de			;4c17   ; HL sale en la misma columna pero una fila mas abajo
	ret			;4c18

; ----------------------------------------------------------------------
; DATOS patrones_4c19: 151 bytes comprimidos que dan 216 de VRAM en 0x2200; lo
;   carga 0x4BD9. Va a los TRES tercios de SCREEN 2
;   0x4c19..0x4cb0  (151 bytes)
DATA_patrones_4c19:
	defb 00fh	; 4c19
	defb 000h	; 4c1a
	defb 001h	; 4c1b
	defb 001h	; 4c1c
	defb 006h	; 4c1d
	defb 000h	; 4c1e
	defb 082h	; 4c1f
	defb 0ffh	; 4c20
	defb 0feh	; 4c21
	defb 008h	; 4c22
	defb 00fh	; 4c23
	defb 084h	; 4c24
	defb 0c3h	; 4c25
	defb 0c7h	; 4c26
	defb 0cfh	; 4c27
	defb 0dfh	; 4c28
	defb 003h	; 4c29
	defb 0ffh	; 4c2a
	defb 089h	; 4c2b
	defb 0feh	; 4c2c
	defb 0fch	; 4c2d
	defb 0f8h	; 4c2e
	defb 0f0h	; 4c2f
	defb 0e0h	; 4c30
	defb 0c0h	; 4c31
	defb 080h	; 4c32
	defb 007h	; 4c33
	defb 007h	; 4c34
	defb 005h	; 4c35
	defb 000h	; 4c36
	defb 083h	; 4c37
	defb 003h	; 4c38
	defb 0cfh	; 4c39
	defb 0dfh	; 4c3a
	defb 005h	; 4c3b
	defb 000h	; 4c3c
	defb 083h	; 4c3d
	defb 0e1h	; 4c3e
	defb 0f9h	; 4c3f
	defb 07dh	; 4c40
	defb 005h	; 4c41
	defb 000h	; 4c42
	defb 083h	; 4c43
	defb 0efh	; 4c44
	defb 0ffh	; 4c45
	defb 0f7h	; 4c46
	defb 005h	; 4c47
	defb 000h	; 4c48
	defb 083h	; 4c49
	defb 007h	; 4c4a
	defb 08fh	; 4c4b
	defb 09eh	; 4c4c
	defb 005h	; 4c4d
	defb 000h	; 4c4e
	defb 083h	; 4c4f
	defb 0f0h	; 4c50
	defb 0f8h	; 4c51
	defb 078h	; 4c52
	defb 005h	; 4c53
	defb 000h	; 4c54
	defb 083h	; 4c55
	defb 0f7h	; 4c56
	defb 0ffh	; 4c57
	defb 0fbh	; 4c58
	defb 005h	; 4c59
	defb 000h	; 4c5a
	defb 08bh	; 4c5b
	defb 08fh	; 4c5c
	defb 0dfh	; 4c5d
	defb 0f7h	; 4c5e
	defb 00ch	; 4c5f
	defb 01eh	; 4c60
	defb 01eh	; 4c61
	defb 00ch	; 4c62
	defb 000h	; 4c63
	defb 01eh	; 4c64
	defb 09eh	; 4c65
	defb 09eh	; 4c66
	defb 008h	; 4c67
	defb 00fh	; 4c68
	defb 090h	; 4c69
	defb 0ffh	; 4c6a
	defb 0ffh	; 4c6b
	defb 0dfh	; 4c6c
	defb 0cfh	; 4c6d
	defb 0c7h	; 4c6e
	defb 0c3h	; 4c6f
	defb 0c1h	; 4c70
	defb 0c0h	; 4c71
	defb 007h	; 4c72
	defb 087h	; 4c73
	defb 0c7h	; 4c74
	defb 0efh	; 4c75
	defb 0ffh	; 4c76
	defb 0ffh	; 4c77
	defb 0ffh	; 4c78
	defb 0fch	; 4c79
	defb 004h	; 4c7a
	defb 0deh	; 4c7b
	defb 084h	; 4c7c
	defb 09eh	; 4c7d
	defb 09fh	; 4c7e
	defb 00fh	; 4c7f
	defb 003h	; 4c80
	defb 005h	; 4c81
	defb 03dh	; 4c82
	defb 083h	; 4c83
	defb 07dh	; 4c84
	defb 0f9h	; 4c85
	defb 0e1h	; 4c86
	defb 008h	; 4c87
	defb 0e3h	; 4c88
	defb 090h	; 4c89
	defb 0dch	; 4c8a
	defb 0c0h	; 4c8b
	defb 0c7h	; 4c8c
	defb 0deh	; 4c8d
	defb 0dch	; 4c8e
	defb 0deh	; 4c8f
	defb 0cfh	; 4c90
	defb 0c3h	; 4c91
	defb 03ch	; 4c92
	defb 07ch	; 4c93
	defb 0fch	; 4c94
	defb 03ch	; 4c95
	defb 03ch	; 4c96
	defb 07ch	; 4c97
	defb 0fch	; 4c98
	defb 0deh	; 4c99
	defb 008h	; 4c9a
	defb 0f1h	; 4c9b
	defb 008h	; 4c9c
	defb 0e3h	; 4c9d
	defb 008h	; 4c9e
	defb 0deh	; 4c9f
	defb 088h	; 4ca0
	defb 038h	; 4ca1
	defb 044h	; 4ca2
	defb 0bah	; 4ca3
	defb 0aah	; 4ca4
	defb 0b2h	; 4ca5
	defb 0aah	; 4ca6
	defb 044h	; 4ca7
	defb 038h	; 4ca8
	defb 003h	; 4ca9
	defb 000h	; 4caa
	defb 001h	; 4cab
	defb 0ffh	; 4cac
	defb 004h	; 4cad
	defb 000h	; 4cae
	defb 000h	; 4caf

; ======================================================================
; CODIGO 0x4cb0..0x4d1c  (108 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LA PANTALLA DE TITULO Y EL MENU DE UNO O DOS JUGADORES =====
; ----------------------------------------------------------------------
monta_la_pantalla_de_titulo:		; el rotulo SOCCER, el KONAMI'S de encima y las dos opciones de abajo
	ld b,0e0h		;4cb0   ; 0xE0 al registro 7: el nibble bajo es el color de fondo, aqui 0, que es transparente y se ve negro
	call pone_el_color_del_borde		;4cb2
	call limpia_la_pantalla		;4cb5   ; borra las 768 casillas de la tabla de nombres antes de escribir nada
	call carga_la_fuente		;4cb8   ; la fuente, que hace falta para los rotulos de texto
	ld de,04d1ch		;4cbb   ; el bloque del rotulo grande
	ld hl,02200h		;4cbe   ; otra vez 0x2200, o sea el tile 0x40: pisa los tiles del logotipo de Konami, que ya no hacen falta
	call descomprime_en_los_tres_tercios		;4cc1   ; 592 bytes son 74 tiles, del 0x40 al 0x89
	ld de,04e34h		;4cc4   ; y el color de esos 74
	ld hl,00200h		;4cc7   ; 0xC0 en los 70 primeros: tinta verde oscuro para el rotulo, y blanco para los cuatro ultimos
	call descomprime_en_los_tres_tercios		;4cca
	ld de,04e41h		;4ccd   ; el guion de "KONAM" mas dos tiles dibujados a mano, el 0x86 y el 0x87, que juntos dicen "I'S"
	call escribe_un_rotulo		;4cd0
	ld hl,03889h		;4cd3   ; 0x3889 es la fila 4, columna 9: la esquina de arriba a la izquierda del rotulo
	ld de,00020h		;4cd6   ; 32 casillas para bajar de fila
	ld a,040h		;4cd9   ; el rotulo se pinta con los tiles 0x40..0x85 seguidos...
	ld c,005h		;4cdb   ; ...repartidos en cinco filas...
L_4CDD:
	ld b,00eh		;4cdd   ; ...de catorce tiles cada una: 70 casillas, o sea 112 por 40 pixeles
	push hl			;4cdf
L_4CE0:
	call 0004dh		;4ce0   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4ce3
	inc a			;4ce4   ; y siempre el tile siguiente, sin tabla ninguna
	djnz L_4CE0		;4ce5
	pop hl			;4ce7
	add hl,de			;4ce8   ; a la fila de abajo
	dec c			;4ce9
	jr nz,L_4CDD		;4cea
	ld de,0494ah		;4cec   ; el guion de los textos: "KONAMI 1985", "PLAY SELECT" y "1PLAYER"
	call escribe_un_rotulo		;4cef   ; al volver, DE ha quedado justo detras del 0xFF de cierre...
	call escribe_un_rotulo		;4cf2   ; ...asi que esta segunda llamada sigue con el guion que va pegado detras, el del "2PLAYERS"
	jp monta_la_escena_del_logotipo		;4cf5
parpadea_el_cursor_del_menu:		; enciende y apaga la marca de la opcion elegida
	ld hl,0e003h		;4cf8   ; el contador de cuadros
	bit 3,(hl)		;4cfb   ; el bit 3 cambia cada ocho cuadros: de ahi sale el parpadeo
	ld c,0ffh		;4cfd   ; C = 0xFF deja pasar el tile tal cual
	jr nz,L_4D02		;4cff
	inc c			;4d01   ; C = 0x00 hace que se escriba un cero: la casilla se borra
L_4D02:
	ld hl,03a6ah		;4d02   ; 0x3A6A es la fila 19, columna 10: justo delante del "1PLAYER"
	ld de,03aaah		;4d05   ; 0x3AAA es la fila 21: delante del "2PLAYERS"
	ld a,(0e042h)		;4d08   ; (0xE042) es la opcion elegida: 0 un jugador, 1 dos
	or a			;4d0b
	jr z,L_4D0F		;4d0c
	ex de,hl			;4d0e   ; con dos jugadores se intercambian, y la marca baja a la otra linea
L_4D0F:
	push de			;4d0f   ; la opcion no elegida se guarda para borrarla
	call pinta_el_cursor_del_menu		;4d10   ; la elegida se pinta con el parpadeo
	pop hl			;4d13
	ld c,000h		;4d14   ; y la otra siempre en blanco
pinta_el_cursor_del_menu:		; los dos tiles de la marca en la casilla HL, o dos blancos si C viene a cero
	ld de,0497ch		;4d16   ; el guion son solo dos tiles, el 0x1B y el 0x1C, con su 0xFF detras
	jp L_46D6		;4d19   ; entra por 0x46D6 y no por 0x46CE: asi no lee direccion del guion, que ya viene en HL

; ----------------------------------------------------------------------
; DATOS patrones_4d1c: 280 bytes comprimidos que dan 592 de VRAM en 0x2200; lo
;   carga 0x4CC1. Va a los TRES tercios de SCREEN 2
;   0x4d1c..0x4e34  (280 bytes)
DATA_patrones_4d1c:
	defb 005h	; 4d1c
	defb 000h	; 4d1d
	defb 083h	; 4d1e
	defb 03fh	; 4d1f
	defb 07fh	; 4d20
	defb 0ffh	; 4d21
	defb 005h	; 4d22
	defb 000h	; 4d23
	defb 003h	; 4d24
	defb 0ffh	; 4d25
	defb 005h	; 4d26
	defb 000h	; 4d27
	defb 083h	; 4d28
	defb 003h	; 4d29
	defb 087h	; 4d2a
	defb 0cfh	; 4d2b
	defb 005h	; 4d2c
	defb 000h	; 4d2d
	defb 003h	; 4d2e
	defb 0ffh	; 4d2f
	defb 005h	; 4d30
	defb 000h	; 4d31
	defb 083h	; 4d32
	defb 0e0h	; 4d33
	defb 0f0h	; 4d34
	defb 0f9h	; 4d35
	defb 005h	; 4d36
	defb 000h	; 4d37
	defb 083h	; 4d38
	defb 07fh	; 4d39
	defb 0ffh	; 4d3a
	defb 0ffh	; 4d3b
	defb 005h	; 4d3c
	defb 000h	; 4d3d
	defb 083h	; 4d3e
	defb 0fch	; 4d3f
	defb 0feh	; 4d40
	defb 0ffh	; 4d41
	defb 005h	; 4d42
	defb 000h	; 4d43
	defb 083h	; 4d44
	defb 00fh	; 4d45
	defb 01fh	; 4d46
	defb 03fh	; 4d47
	defb 005h	; 4d48
	defb 000h	; 4d49
	defb 003h	; 4d4a
	defb 0ffh	; 4d4b
	defb 005h	; 4d4c
	defb 000h	; 4d4d
	defb 083h	; 4d4e
	defb 087h	; 4d4f
	defb 0c7h	; 4d50
	defb 0e7h	; 4d51
	defb 005h	; 4d52
	defb 000h	; 4d53
	defb 003h	; 4d54
	defb 0ffh	; 4d55
	defb 005h	; 4d56
	defb 000h	; 4d57
	defb 003h	; 4d58
	defb 0f3h	; 4d59
	defb 005h	; 4d5a
	defb 000h	; 4d5b
	defb 003h	; 4d5c
	defb 0ffh	; 4d5d
	defb 005h	; 4d5e
	defb 000h	; 4d5f
	defb 082h	; 4d60
	defb 0fch	; 4d61
	defb 0feh	; 4d62
	defb 00ch	; 4d63
	defb 0ffh	; 4d64
	defb 005h	; 4d65
	defb 03fh	; 4d66
	defb 008h	; 4d67
	defb 0cfh	; 4d68
	defb 003h	; 4d69
	defb 0ffh	; 4d6a
	defb 005h	; 4d6b
	defb 0f3h	; 4d6c
	defb 008h	; 4d6d
	defb 0f9h	; 4d6e
	defb 003h	; 4d6f
	defb 0ffh	; 4d70
	defb 005h	; 4d71
	defb 0feh	; 4d72
	defb 003h	; 4d73
	defb 0ffh	; 4d74
	defb 005h	; 4d75
	defb 07fh	; 4d76
	defb 008h	; 4d77
	defb 03fh	; 4d78
	defb 003h	; 4d79
	defb 0ffh	; 4d7a
	defb 005h	; 4d7b
	defb 0cfh	; 4d7c
	defb 008h	; 4d7d
	defb 0e7h	; 4d7e
	defb 003h	; 4d7f
	defb 0ffh	; 4d80
	defb 005h	; 4d81
	defb 0f8h	; 4d82
	defb 003h	; 4d83
	defb 0f3h	; 4d84
	defb 005h	; 4d85
	defb 003h	; 4d86
	defb 003h	; 4d87
	defb 0ffh	; 4d88
	defb 005h	; 4d89
	defb 0fch	; 4d8a
	defb 00fh	; 4d8b
	defb 0ffh	; 4d8c
	defb 081h	; 4d8d
	defb 07fh	; 4d8e
	defb 003h	; 4d8f
	defb 000h	; 4d90
	defb 005h	; 4d91
	defb 0ffh	; 4d92
	defb 004h	; 4d93
	defb 00fh	; 4d94
	defb 081h	; 4d95
	defb 08fh	; 4d96
	defb 003h	; 4d97
	defb 0cfh	; 4d98
	defb 008h	; 4d99
	defb 0f3h	; 4d9a
	defb 008h	; 4d9b
	defb 0f9h	; 4d9c
	defb 008h	; 4d9d
	defb 0feh	; 4d9e
	defb 005h	; 4d9f
	defb 07fh	; 4da0
	defb 003h	; 4da1
	defb 000h	; 4da2
	defb 008h	; 4da3
	defb 03fh	; 4da4
	defb 005h	; 4da5
	defb 0cfh	; 4da6
	defb 003h	; 4da7
	defb 0c0h	; 4da8
	defb 005h	; 4da9
	defb 0e7h	; 4daa
	defb 003h	; 4dab
	defb 007h	; 4dac
	defb 003h	; 4dad
	defb 0f8h	; 4dae
	defb 005h	; 4daf
	defb 0ffh	; 4db0
	defb 003h	; 4db1
	defb 003h	; 4db2
	defb 005h	; 4db3
	defb 0f3h	; 4db4
	defb 005h	; 4db5
	defb 0fch	; 4db6
	defb 008h	; 4db7
	defb 0ffh	; 4db8
	defb 084h	; 4db9
	defb 0feh	; 4dba
	defb 0fch	; 4dbb
	defb 0f8h	; 4dbc
	defb 03fh	; 4dbd
	defb 003h	; 4dbe
	defb 000h	; 4dbf
	defb 005h	; 4dc0
	defb 0ffh	; 4dc1
	defb 007h	; 4dc2
	defb 03fh	; 4dc3
	defb 008h	; 4dc4
	defb 0cfh	; 4dc5
	defb 008h	; 4dc6
	defb 0f3h	; 4dc7
	defb 008h	; 4dc8
	defb 0f9h	; 4dc9
	defb 008h	; 4dca
	defb 0feh	; 4dcb
	defb 008h	; 4dcc
	defb 07fh	; 4dcd
	defb 008h	; 4dce
	defb 03fh	; 4dcf
	defb 008h	; 4dd0
	defb 0cfh	; 4dd1
	defb 008h	; 4dd2
	defb 0e7h	; 4dd3
	defb 002h	; 4dd4
	defb 0ffh	; 4dd5
	defb 006h	; 4dd6
	defb 0f8h	; 4dd7
	defb 002h	; 4dd8
	defb 0f3h	; 4dd9
	defb 006h	; 4dda
	defb 003h	; 4ddb
	defb 004h	; 4ddc
	defb 0ffh	; 4ddd
	defb 005h	; 4dde
	defb 0fch	; 4ddf
	defb 081h	; 4de0
	defb 0feh	; 4de1
	defb 00ch	; 4de2
	defb 0ffh	; 4de3
	defb 081h	; 4de4
	defb 07fh	; 4de5
	defb 003h	; 4de6
	defb 03fh	; 4de7
	defb 006h	; 4de8
	defb 0ffh	; 4de9
	defb 006h	; 4dea
	defb 0cfh	; 4deb
	defb 084h	; 4dec
	defb 087h	; 4ded
	defb 003h	; 4dee
	defb 0f3h	; 4def
	defb 0f3h	; 4df0
	defb 006h	; 4df1
	defb 0ffh	; 4df2
	defb 006h	; 4df3
	defb 0f9h	; 4df4
	defb 084h	; 4df5
	defb 0f0h	; 4df6
	defb 0e0h	; 4df7
	defb 0feh	; 4df8
	defb 0feh	; 4df9
	defb 005h	; 4dfa
	defb 0ffh	; 4dfb
	defb 003h	; 4dfc
	defb 07fh	; 4dfd
	defb 004h	; 4dfe
	defb 0ffh	; 4dff
	defb 082h	; 4e00
	defb 0feh	; 4e01
	defb 0fch	; 4e02
	defb 006h	; 4e03
	defb 03fh	; 4e04
	defb 084h	; 4e05
	defb 01fh	; 4e06
	defb 00fh	; 4e07
	defb 0cfh	; 4e08
	defb 0cfh	; 4e09
	defb 006h	; 4e0a
	defb 0ffh	; 4e0b
	defb 006h	; 4e0c
	defb 0e7h	; 4e0d
	defb 084h	; 4e0e
	defb 0c7h	; 4e0f
	defb 087h	; 4e10
	defb 0f8h	; 4e11
	defb 0f8h	; 4e12
	defb 006h	; 4e13
	defb 0ffh	; 4e14
	defb 002h	; 4e15
	defb 003h	; 4e16
	defb 006h	; 4e17
	defb 0f3h	; 4e18
	defb 008h	; 4e19
	defb 0fch	; 4e1a
	defb 008h	; 4e1b
	defb 0ffh	; 4e1c
	defb 081h	; 4e1d
	defb 03dh	; 4e1e
	defb 005h	; 4e1f
	defb 018h	; 4e20
	defb 089h	; 4e21
	defb 03ch	; 4e22
	defb 000h	; 4e23
	defb 03eh	; 4e24
	defb 063h	; 4e25
	defb 060h	; 4e26
	defb 03eh	; 4e27
	defb 003h	; 4e28
	defb 063h	; 4e29
	defb 03eh	; 4e2a
	defb 008h	; 4e2b
	defb 000h	; 4e2c
	defb 081h	; 4e2d
	defb 001h	; 4e2e
	defb 007h	; 4e2f
	defb 000h	; 4e30
	defb 081h	; 4e31
	defb 080h	; 4e32
	defb 000h	; 4e33

; ----------------------------------------------------------------------
; DATOS color_4e34: 13 bytes comprimidos que dan 592 de VRAM en 0x0200; lo
;   carga 0x4CCA. Va a los TRES tercios de SCREEN 2
;   0x4e34..0x4e41  (13 bytes)
DATA_color_4e34:
	defb 07fh	; 4e34
	defb 0c0h	; 4e35
	defb 07fh	; 4e36
	defb 0c0h	; 4e37
	defb 07fh	; 4e38
	defb 0c0h	; 4e39
	defb 07fh	; 4e3a
	defb 0c0h	; 4e3b
	defb 034h	; 4e3c
	defb 0c0h	; 4e3d
	defb 020h	; 4e3e
	defb 0f0h	; 4e3f
	defb 000h	; 4e40

; ----------------------------------------------------------------------
; DATOS guion_del_logotipo_de_konami: pone los tiles 0x88 y 0x89 y, en 0x3869,
;   "KONAM" con dos tiles propios detras: el logotipo de la casa. Lo lanza
;   0x4CCD
;   0x4e41..0x4e50  (15 bytes)
DATA_guion_del_logotipo_de_konami:
	defb 04eh	; 4e41
	defb 038h	; 4e42
	defb 088h	; 4e43
	defb 089h	; 4e44
	defb 0feh	; 4e45
	defb 069h	; 4e46
	defb 038h	; 4e47
	defb 02bh	; 4e48
	defb 02fh	; 4e49
	defb 02eh	; 4e4a
	defb 021h	; 4e4b
	defb 02dh	; 4e4c
	defb 086h	; 4e4d
	defb 087h	; 4e4e
	defb 0ffh	; 4e4f

; ======================================================================
; CODIGO 0x4e50..0x50ce  (638 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL SONIDO: LA PUERTA PARA PEDIR UN SONIDO =====
; ----------------------------------------------------------------------
pide_un_sonido:		; arranca el sonido numero A, pero solo si hay partida en marcha
	di			;4e50   ; se llama desde cualquier sitio, tambien desde fuera de la interrupcion: hay que cerrarla
	push hl			;4e51
	ld hl,0e002h		;4e52   ; las banderas de estado
	bit 6,(hl)		;4e55   ; el bit 6 se enciende al aceptar el menu; sin partida los efectos se tragan y no suena nada
	jr z,L_4E6E		;4e57
	jr L_4E5D		;4e59
pide_un_sonido_siempre:		; lo mismo pero sin mirar la bandera: por aqui entran la presentacion y los menus
	di			;4e5b
	push hl			;4e5c
L_4E5D:
	push de			;4e5d   ; se salva todo, hasta IX e IY, porque quien pide un sonido no espera perder ningun registro
	push bc			;4e5e
	push af			;4e5f
	push ix		;4e60   ; IX e IY tambien, que el sonido los usa y quien lo pide puede estar a mitad de una ficha
	push iy		;4e62
	call arranca_el_sonido		;4e64   ; y ya se puede hablar con el generador
	pop iy		;4e67
	pop ix		;4e69
	pop af			;4e6b
	pop bc			;4e6c
	pop de			;4e6d
L_4E6E:
	pop hl			;4e6e
	ei			;4e6f   ; la interrupcion no se vuelve a abrir hasta aqui
	ret			;4e70
arranca_el_sonido:		; reparte el sonido A entre uno, dos o tres canales, si le gana en prioridad al que ya suena
	ld c,a			;4e71   ; C se queda el numero entero, con sus dos banderas
	and 03fh		;4e72   ; los seis bits de abajo son el numero de sonido; el bit 6 dice que lleva RUIDO y el 7 que es melodia con notas
	ld b,002h		;4e74   ; de partida, dos canales
	ld hl,0e012h		;4e76   ; 0xE012 es el campo +2 del primer canal, donde vive el numero del sonido que esta sonando
	cp 009h		;4e79   ; los sonidos del 0 al 8 ocupan un solo canal...
	jr c,L_4E84		;4e7b
	cp 01fh		;4e7d   ; ...del 9 al 0x1E, dos...
	jr c,L_4E88		;4e7f
	inc b			;4e81   ; ...y del 0x1F para arriba, los tres: son las melodias
	jr L_4E88		;4e82
L_4E84:
	dec b			;4e84   ; un canal nada mas...
	ld hl,0e02eh		;4e85   ; ...y es el tercero, el bloque que empieza en 0xE02C
L_4E88:
	ld a,(hl)			;4e88   ; lo que esta sonando ahora mismo en ese canal
	and 03fh		;4e89
	ld e,a			;4e8b
	ld a,c			;4e8c
	and 03fh		;4e8d
	cp e			;4e8f   ; si lo que suena tiene numero MAS ALTO, no se le interrumpe: la prioridad es el propio numero de sonido
	ret c			;4e90
	add a,a			;4e91   ; dos bytes por puntero
	ld de,050d8h		;4e92   ; 0x50D8 es la base de la tabla de punteros a las secuencias; la entrada 0 no apunta a nada, el primer sonido de verdad es el 1
	call suma_a_de		;4e95
	dec hl			;4e98   ; del campo +2 se vuelve al principio del bloque del canal
	dec hl			;4e99
L_4E9A:
	ld (hl),001h		;4e9a   ; +0: la cuenta atras de la nota, a 1 para que la primera suene ya en el proximo cuadro
	inc hl			;4e9c
	ld (hl),001h		;4e9d   ; +1: la duracion base, tambien 1 mientras la secuencia no diga otra cosa
	inc hl			;4e9f
	ld (hl),c			;4ea0   ; +2: el numero del sonido con sus banderas; distinto de cero significa canal ocupado
	inc hl			;4ea1
	ld a,(de)			;4ea2
	ld (hl),a			;4ea3   ; +3: el puntero de lectura, byte bajo
	inc hl			;4ea4
	inc de			;4ea5
	ld a,(de)			;4ea6
	ld (hl),a			;4ea7   ; +4: y el byte alto
	ld a,005h		;4ea8   ; de +4 a +9
	call suma_a_hl		;4eaa
	ld (hl),000h		;4ead   ; +9: las vueltas dadas en el mandato de bucle, a cero
	ld a,005h		;4eaf   ; de +9 a +14, que es el principio del canal siguiente: cada bloque ocupa catorce bytes
	call suma_a_hl		;4eb1
	inc de			;4eb4   ; y en la tabla, el puntero del canal siguiente: un sonido de tres canales se lleva tres entradas seguidas
	djnz L_4E9A		;4eb5
	ld ix,0e02ch		;4eb7   ; el tercer canal, que es donde suena la pelota
	ld a,c			;4ebb
	cp 003h		;4ebc   ; los sonidos 3 y 5 no leen ninguna secuencia de la ROM...
	jr nz,L_4EC7		;4ebe
	ld a,010h		;4ec0   ; ...sino tres bytes montados aqui mismo en RAM; el 3 arranca con periodo 0x0110
	ld (0e03dh),a		;4ec2
	jr L_4ED0		;4ec5
L_4EC7:
	ld a,c			;4ec7
	cp 005h		;4ec8   ; el otro sonido de pelota
	ret nz			;4eca
	ld a,060h		;4ecb   ; arranca mas grave, con periodo 0x0160
	ld (0e03dh),a		;4ecd
L_4ED0:
	ld a,091h		;4ed0   ; el byte de la nota: nibble alto 9 = volumen, nibble bajo 1 = los cuatro bits altos del periodo
	ld (0e03ch),a		;4ed2   ; va al segundo de los tres bytes de RAM
	ld a,021h		;4ed5   ; 0x2n es el mandato "duracion n": duracion 1, o sea nota nueva en cada cuadro
	ld (0e03bh),a		;4ed7   ; y este es el primero de los tres
	jp apunta_el_canal_a_la_nota_de_ram		;4eda   ; apunta el canal a esos tres bytes de RAM en lugar de a la ROM: la nota se relee cada cuadro y por eso el tono puede ir corriendo
mandato_de_bucle:		; el 0xFE de la secuencia: repite desde una direccion un numero de veces
	inc hl			;4edd   ; detras del 0xFE viene la cuenta de vueltas
	ld a,(ix+009h)		;4ede   ; +9 lleva las vueltas dadas
	inc a			;4ee1
	cp (hl)			;4ee2   ; con la cuenta a 0 nunca hay igualdad: eso es el bucle sin fin
	jr z,L_4EF8		;4ee3
	jp m,L_4EE9		;4ee5   ; aun quedan vueltas
	dec a			;4ee8   ; y si se hubiera pasado, se queda clavado en la cuenta
L_4EE9:
	ld (ix+009h),a		;4ee9   ; se apunta la vuelta
	inc hl			;4eec
	ld a,(hl)			;4eed
	ld (ix+003h),a		;4eee   ; +3 y +4: la direccion de salto, que viene en los dos bytes siguientes al mandato
	inc hl			;4ef1
	ld a,(hl)			;4ef2
	ld (ix+004h),a		;4ef3
	jr L_4F01		;4ef6
L_4EF8:
	inc hl			;4ef8   ; gastadas las vueltas, se salta la cuenta y la direccion...
	inc hl			;4ef9
	ld (ix+009h),000h		;4efa   ; ...se pone el contador a cero por si se vuelve a pasar por este mismo bucle...
	call guarda_el_puntero		;4efe   ; ...y se sigue leyendo detras del mandato
L_4F01:
	inc (ix+000h)		;4f01   ; se sube la cuenta atras para que el `dec` de mas abajo la deje como estaba: asi el mandato siguiente se atiende en este mismo cuadro
	jp mira_si_toca_nota_nueva		;4f04
enciende_o_apaga_el_ruido:		; toca el bit de este canal en el mezclador: D=1 lo apaga, cualquier otra cosa lo enciende
	ld a,(0e03ah)		;4f07   ; (0xE03A) es la copia en RAM del registro 7, que en el PSG no se puede releer
	ld e,a			;4f0a
	ld a,c			;4f0b   ; C vale 1, 3 o 5 segun el canal
	cp 001h		;4f0c   ; el 1 se queda como esta; el 3 pasa a 2 y el 5 a 4
	jr z,L_4F11		;4f0e
	dec a			;4f10
L_4F11:
	rlca			;4f11   ; tres desplazamientos convierten 1, 2 y 4 en 8, 16 y 32...
	rlca			;4f12
	rlca			;4f13   ; ...que son los bits 3, 4 y 5 del registro 7, los del RUIDO de cada canal
	dec d			;4f14   ; poner el bit es CALLAR el ruido: en el PSG el registro 7 va del reves
	jr z,L_4F1B		;4f15
	cpl			;4f17
	and e			;4f18   ; y borrarlo, encenderlo
	jr escribe_el_mezclador		;4f19
L_4F1B:
	or e			;4f1b
escribe_el_mezclador:		; guarda la copia en RAM y manda el byte al registro 7 del PSG
	ld (0e03ah),a		;4f1c   ; la copia, que es la unica forma de saber como estaba
	ld e,a			;4f1f
	ld a,007h		;4f20   ; registro 7: el mezclador de tonos y ruidos de los tres canales
	jp 00093h		;4f22   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; ===== EL SONIDO: LA PASADA DE CADA CUADRO =====
; ----------------------------------------------------------------------
tic_del_sonido:		; una vuelta a los tres canales; el latido lo llama antes que nada, con la interrupcion cerrada
	ld a,(0e03ah)		;4f25   ; se reescribe el mezclador tal como esta guardado, por si algo lo hubiera movido
	call escribe_el_mezclador		;4f28
	ld c,001h		;4f2b   ; C = 1: los registros 0 y 1 son el periodo del canal A
	ld ix,0e010h		;4f2d   ; el bloque del primer canal, en 0xE010
	exx			;4f31   ; la cuenta de canales y el paso se guardan en el juego alterno...
	ld b,003h		;4f32
	ld de,0000eh		;4f34   ; ...catorce bytes de un canal al siguiente...
L_4F37:
	exx			;4f37   ; ...y dentro del cuerpo se vuelve al juego principal: asi BC' y DE' quedan quietos y B y D libres para el interprete
	ld a,(ix+002h)		;4f38   ; +2: que esta sonando en este canal
	cp 003h		;4f3b   ; los sonidos 3 y 5 son la pelota en el aire, que no lee notas sino que va corriendo el tono cuadro a cuadro
	call z,sonido_de_la_pelota_en_el_aire		;4f3d
	cp 005h		;4f40
	call z,sonido_de_la_pelota_en_el_aire		;4f42
	ld a,(ix+002h)		;4f45   ; se vuelve a leer porque la pelota ha podido apagarse sola
	or a			;4f48   ; cero es canal libre
	jr nz,L_4F50		;4f49
	call calla_el_canal		;4f4b   ; se le manda callar, por si venia sonando
	jr L_4F53		;4f4e
L_4F50:
	call avanza_el_canal		;4f50   ; y si esta ocupado, se avanza su secuencia
L_4F53:
	inc c			;4f53   ; de 1 a 3 y de 3 a 5: los pares de registros de periodo de los canales B y C
	inc c			;4f54
	exx			;4f55
	add ix,de		;4f56   ; al bloque del canal siguiente
	djnz L_4F37		;4f58
	ret			;4f5a

; ----------------------------------------------------------------------
; ===== EL SONIDO: LA PELOTA EN EL AIRE =====
; ----------------------------------------------------------------------
sonido_de_la_pelota_en_el_aire:		; el periodo corre arriba o abajo segun el signo de la velocidad vertical de la pelota
	ld hl,0e03dh		;4f5b   ; 0xE03D es el byte bajo del periodo, el que se mueve
	ld b,a			;4f5e   ; A se salva porque abajo se cambia de juego de registros
	ld a,(0e543h)		;4f5f   ; (0xE543) lo ponen 0x8CEC y 0x8CFD: dice si a la pelota le queda movimiento vertical
	rra			;4f62
	jr c,L_4F72		;4f63   ; si lo tiene, el tono sigue corriendo
	exx			;4f65   ; se cambia de juego para usar HL' de recadero: el HL bueno apunta al periodo y no se puede perder
	ld hl,0e2ach		;4f66   ; (0xE2AB) es la velocidad con que la pelota sube o baja; 0x8CB0 le suma la gravedad de (0xE2AD) y 0x8CE3 se la suma a la altura de (0xE2A9)
	ld a,(0e2abh)		;4f69
	or (hl)			;4f6c
	exx			;4f6d
	ld a,b			;4f6e
	jp z,apaga_el_sonido_de_la_pelota		;4f6f   ; quieta y sin velocidad: se corta el sonido del todo
L_4F72:
	ld a,(0e2ach)		;4f72   ; el bit 7 del byte alto es el signo de la velocidad
	rla			;4f75
	jr nc,acorta_el_periodo_de_la_pelota		;4f76   ; con un signo el periodo se acorta, o sea el tono sube
	inc (hl)			;4f78   ; con el otro sube de dos en dos, y el tono baja
	inc (hl)			;4f79
	dec hl			;4f7a   ; y si el byte bajo se ha dado la vuelta...
	jr nz,apunta_el_canal_a_la_nota_de_ram		;4f7b
	inc (hl)			;4f7d   ; ...se acarrea al alto
apunta_el_canal_a_la_nota_de_ram:		; deja el puntero de lectura en 0xE03B, la nota de tres bytes montada en RAM
	dec hl			;4f7e   ; HL retrocede de 0xE03C a 0xE03B, el primero de los tres bytes
	ld (ix+003h),l		;4f7f   ; +3 y +4: el canal lee de la RAM en cada cuadro, y por eso el tono cambia solo sin tocar la secuencia
	ld (ix+004h),h		;4f82
	ret			;4f85
acorta_el_periodo_de_la_pelota:		; dos menos, que en el PSG es tono mas agudo
	dec (hl)			;4f86
	dec (hl)			;4f87
	ld a,(hl)			;4f88
	dec hl			;4f89
	cp 0feh		;4f8a   ; al bajar de 0x00 se llega a 0xFE: hay que pedir prestado
	jr nz,apunta_el_canal_a_la_nota_de_ram		;4f8c
	dec (hl)			;4f8e   ; al byte alto del periodo
	jr apunta_el_canal_a_la_nota_de_ram		;4f8f

; ----------------------------------------------------------------------
; ===== EL SONIDO: EL INTERPRETE DE LAS SECUENCIAS =====
; ----------------------------------------------------------------------
avanza_el_canal:		; un cuadro de la secuencia que este sonando en este canal
	bit 6,a		;4f91   ; el bit 6 del numero de sonido es el que dice si lleva ruido
	ld d,001h		;4f93   ; si no lo lleva, se apaga el ruido de este canal en el mezclador
	call z,enciende_o_apaga_el_ruido		;4f95
mira_si_toca_nota_nueva:		; descuenta un cuadro de la nota en curso
	ld a,(ix+002h)		;4f98   ; el numero de sonido, con sus banderas
	or a			;4f9b
	jp m,apaga_la_nota_poco_a_poco		;4f9c   ; el bit 7 marca las melodias, que ademas van apagando la nota poco a poco
	dec (ix+000h)		;4f9f   ; un cuadro menos de la nota
	ret nz			;4fa2   ; mientras quede cuenta no hay nada que hacer: la nota sigue igual
lee_el_mandato_siguiente:		; saca el proximo byte de la secuencia y lo despacha
	ld l,(ix+003h)		;4fa3   ; +3 y +4: por donde iba la lectura
	ld h,(ix+004h)		;4fa6
	ld a,(hl)			;4fa9
	cp 0feh		;4faa   ; 0xFE es el mandato de bucle
	jp z,mandato_de_bucle		;4fac
	jr nc,calla_el_canal		;4faf   ; 0xFF cierra la secuencia y deja el canal libre
	bit 7,(ix+002h)		;4fb1   ; el bit 7 del numero de sonido elige el formato: puesto, notas y octavas; sin poner, el periodo tal cual
	jp nz,lee_una_nota_de_melodia		;4fb5
	and 0f0h		;4fb8   ; en el formato de periodo crudo, un 0x2n fija cuanto van a durar las notas
	cp 020h		;4fba
	ld a,(hl)			;4fbc
	jr nz,nota_de_periodo_crudo		;4fbd
	and 00fh		;4fbf
	ld (ix+001h),a		;4fc1   ; +1: la duracion, en cuadros
	inc hl			;4fc4
	ld a,(hl)			;4fc5   ; este `ld a,(hl)` lo repite la linea de abajo, asi que sobra
nota_de_periodo_crudo:		; el par de bytes que llevan el volumen y los doce bits del periodo
	ld a,(hl)			;4fc6
	ld b,a			;4fc7
	and 0f0h		;4fc8   ; manda el nibble alto
	cp 010h		;4fca   ; un 0x1n enciende el RUIDO en este canal
	jr nz,escribe_el_periodo_y_el_volumen		;4fcc
	ld a,(hl)			;4fce
	and 01fh		;4fcf   ; los cinco bits de abajo son el periodo del ruido, que asi sale siempre entre 16 y 31
	ld e,a			;4fd1
	ld a,006h		;4fd2   ; registro 6: el periodo del ruido, que es uno solo para todo el PSG
	call 00093h		;4fd4   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;4fd7   ; D=0: se enciende el ruido de este canal en el mezclador
	call enciende_o_apaga_el_ruido		;4fd9
	inc hl			;4fdc
	ld a,(hl)			;4fdd
escribe_el_periodo_y_el_volumen:		; nibble alto el volumen, nibble bajo mas el byte siguiente el periodo
	and 0f0h		;4fde   ; B se queda con el nibble alto
	ld b,a			;4fe0
	xor (hl)			;4fe1   ; y el xor deja en D el nibble bajo: los cuatro bits altos del periodo
	ld d,a			;4fe2
	inc hl			;4fe3
	ld e,(hl)			;4fe4   ; el byte siguiente son los ocho bits bajos
	call guarda_el_puntero		;4fe5   ; la lectura queda ya en el mandato de despues
	ex de,hl			;4fe8
	call escribe_el_periodo		;4fe9   ; los doce bits al par de registros de periodo del canal
	ld a,b			;4fec
	rrca			;4fed   ; el volumen baja a los bits de abajo: queda entre 0 y 15
	rrca			;4fee
	rrca			;4fef
	rrca			;4ff0
recarga_la_duracion:		; deja la nota sonando los cuadros que toque y arma el contador con que se apagara
	ld h,a			;4ff1
	ld e,(ix+001h)		;4ff2   ; +1 es la duracion, y +0 la cuenta atras que se descuenta cada cuadro
	ld (ix+000h),e		;4ff5
	ld a,(ix+00ch)		;4ff8   ; +8 arranca en la duracion mas (ix+C), y luego baja el doble de deprisa que +0: se cruzan justo (ix+C) cuadros despues
	add a,e			;4ffb
	ld (ix+008h),a		;4ffc
	jr escribe_el_volumen		;4fff
calla_el_canal:		; volumen a cero, ruido fuera y el canal marcado como libre
	ld d,001h		;5001   ; D=1: apagar el ruido en el mezclador
	call enciende_o_apaga_el_ruido		;5003
	ld (ix+002h),000h		;5006   ; +2 a cero: nadie esta usando este canal
	ld h,000h		;500a   ; volumen 0, que en el PSG es el silencio
	jr escribe_el_volumen		;500c
apaga_la_nota_poco_a_poco:		; la envolvente de las melodias: cae, se queda quieta y vuelve a caer al final
	dec (ix+000h)		;500e   ; un cuadro menos de nota
	jp z,lee_el_mandato_siguiente		;5011   ; agotada la nota, al mandato siguiente
	dec (ix+008h)		;5014   ; +8 baja dos por cuadro y +0 solo uno...
	ld a,(ix+008h)		;5017
	cp (ix+000h)		;501a   ; ...asi que se igualan exactamente (ix+C) cuadros despues de empezar la nota
	jr nz,L_5028		;501d
	ld e,a			;501f
	ld a,(ix+00dh)		;5020   ; y ahi manda (ix+D): mientras a la nota le queden mas de (ix+D) cuadros el volumen se congela, y vuelve a caer en los (ix+D) ultimos
	cp e			;5023
	ld a,e			;5024
	jr nc,L_502B		;5025
	ret			;5027
L_5028:
	dec (ix+008h)		;5028
L_502B:
	ld a,(ix+007h)		;502b   ; +7 es el volumen que suena ahora mismo
	dec a			;502e
	ret m			;502f   ; llegado a cero se deja de bajar, que si no daria la vuelta
	ld (ix+007h),a		;5030
	ld h,a			;5033
escribe_el_volumen:		; el volumen de H al registro que le toca a este canal
	ld a,c			;5034   ; C es 1, 3 o 5...
	rrca			;5035
	add a,088h		;5036   ; ...y el `rrca` mas 0x88 los convierte en 8, 9 y 10, que son los tres registros de volumen del PSG
	ld e,h			;5038
	jp 00093h		;5039   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; ===== EL SONIDO: EL FORMATO DE MELODIA, CON NOTAS Y OCTAVAS =====
; ----------------------------------------------------------------------
lee_una_nota_de_melodia:		; los mandatos 0xDn, 0xFn y 0xEn, y detras el byte de la nota
	ld a,(hl)			;503c   ; el nibble alto es el que elige mandato
	and 0f0h		;503d
	cp 0d0h		;503f   ; 0xDn fija el compas: lo que dura la unidad de duracion
	ld a,(hl)			;5041
	jr nz,L_504B		;5042
	and 00fh		;5044
	ld (ix+00ah),a		;5046   ; +A: los cuadros que dura una unidad
	inc hl			;5049
	ld a,(hl)			;504a   ; este `ld a,(hl)` lo repite la linea de abajo, igual que en el otro formato
L_504B:
	ld a,(hl)			;504b
	cp 0f0h		;504c   ; de 0xF0 a 0xFD: el volumen de arranque y los dos ajustes de la envolvente (el 0xFE y el 0xFF ya se han atendido antes)
	jr c,L_5061		;504e
	and 00fh		;5050
	ld (ix+006h),a		;5052   ; +6: el volumen con que empieza cada nota
	inc hl			;5055
	ld a,(hl)			;5056
	ld (ix+00ch),a		;5057   ; +C: cuantos cuadros cae el volumen al principio de la nota
	inc hl			;505a
	ld a,(hl)			;505b
	ld (ix+00dh),a		;505c   ; +D: cuantos vuelve a caer al final
	inc hl			;505f
	ld a,(hl)			;5060
L_5061:
	cp 0e0h		;5061   ; 0xEn fija la octava
	jr c,L_506C		;5063
	and 00fh		;5065
	ld (ix+005h),a		;5067   ; +5: cuantas veces se dobla el periodo, que es cuantas octavas se baja
	inc hl			;506a
	ld a,(hl)			;506b
L_506C:
	and 00fh		;506c   ; ya es el byte de la nota, y su nibble bajo es lo que dura
	ld b,a			;506e
	ld a,(ix+00ah)		;506f   ; la duracion sale de la unidad del mandato 0xDn...
	jr z,L_5079		;5072
L_5074:
	add a,(ix+00ah)		;5074   ; ...sumada tantas veces como diga el nibble bajo, mas una
	djnz L_5074		;5077
L_5079:
	ld (ix+001h),a		;5079   ; +1: la duracion que se recargara al empezar la nota
	ld a,(hl)			;507c   ; el byte de la nota otra vez
	call guarda_el_puntero		;507d   ; y la lectura ya queda en el mandato siguiente
	and 0f0h		;5080   ; el nibble alto es la nota dentro de la octava...
	rrca			;5082
	rrca			;5083
	rrca			;5084
	rrca			;5085
	ld b,a			;5086   ; ...del 0 al 11, los doce semitonos
	sub 00ch		;5087   ; el 12 es el silencio: volumen cero y ya esta
	jr z,L_508E		;5089
	ld a,(ix+006h)		;508b   ; y si no, el volumen de arranque que dejo puesto el mandato 0xFn
L_508E:
	ld (ix+007h),a		;508e   ; +7: el volumen de ahora mismo, el que ira bajando
	call recarga_la_duracion		;5091   ; se recarga la duracion y se manda el volumen al PSG
	ld a,b			;5094
	ld hl,050ceh		;5095   ; en 0x50CE hay doce bytes, los periodos de una octava entera: van de 0x6B a 0x39, o sea del DO de unos 1046 Hz al SI de 1962
	call suma_a_hl		;5098
	ld l,(hl)			;509b   ; el periodo de la octava mas alta cabe en un byte
	ld h,000h		;509c
	ld a,(ix+005h)		;509e   ; la octava que dejo puesta el mandato 0xEn
	or a			;50a1
	jr z,escribe_el_periodo		;50a2
	ld b,a			;50a4
L_50A5:
	add hl,hl			;50a5   ; doblar el periodo es bajar una octava justa
	djnz L_50A5		;50a6
escribe_el_periodo:		; los doce bits de HL a los dos registros de periodo del canal
	ld a,c			;50a8   ; C es 1, 3 o 5: el registro del byte ALTO del periodo
	ld e,h			;50a9
	call 00093h		;50aa   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;50ad
	dec a			;50ae   ; y el de debajo, 0, 2 o 4, el del byte bajo
	ld e,l			;50af
	jp 00093h		;50b0   ; BIOS WRTPSG - Writes data to PSG-register
guarda_el_puntero:		; deja apuntada la lectura en el byte siguiente al que se acaba de gastar
	inc hl			;50b3
	ld (ix+003h),l		;50b4
	ld (ix+004h),h		;50b7
	ret			;50ba
apaga_el_sonido_de_la_pelota:		; borra la nota de RAM y calla el canal; lo llama 0x8F58 al parar la pelota
	xor a			;50bb   ; los tres bytes de la nota montada en RAM, a cero
	ld (0e03bh),a		;50bc
	ld (0e03ch),a		;50bf
	ld (0e03dh),a		;50c2
	ld ix,0e02ch		;50c5   ; la pelota siempre suena en el tercer canal
	ld c,005h		;50c9   ; C = 5: los registros 4 y 5 del periodo, y el 10 del volumen
	jp calla_el_canal		;50cb

; ----------------------------------------------------------------------
; DATOS tabla_de_tonos_del_psg: doce bytes, un semitono cada uno; la octava
;   sale desplazando a la izquierda por (ix+5). Lo lee 0x5095
;   0x50ce..0x50da  (12 bytes)
DATA_tabla_de_tonos_del_psg:
	defb 06bh	; 50ce
	defb 065h	; 50cf
	defb 05fh	; 50d0
	defb 05ah	; 50d1
	defb 055h	; 50d2
	defb 050h	; 50d3
	defb 04ch	; 50d4
	defb 047h	; 50d5
	defb 043h	; 50d6
	defb 040h	; 50d7
	defb 03ch	; 50d8
	defb 039h	; 50d9

; ----------------------------------------------------------------------
; DATOS tabla_de_los_sonidos: 54 punteros a las secuencias; 0x4E92 hace `ld
;   de,050d8h` y le suma dos veces el numero de sonido
;   0x50da..0x5146  (108 bytes)
DATA_tabla_de_los_sonidos:
	defw 05146h,05174h,051a4h,05180h,051a4h,051a5h,051bch,05644h	; 50da
	defw 051cdh,051dfh,051e0h,051f8h,05210h,0522bh,05237h,05249h	; 50ea
	defw 0524ah,05260h,05275h,05285h,05295h,052a9h,052bdh,052ceh	; 50fa
	defw 052ddh,052f6h,054eah,0550fh,0537fh,053d6h,05345h,0535fh	; 510a
	defw 0536fh,0537fh,053d6h,05495h,0530fh,0531ah,05324h,05314h	; 511a
	defw 0531fh,05324h,05325h,05335h,05324h,055a7h,055e4h,05612h	; 512a
	defw 05542h,0556bh,0557fh,05644h,05644h,05644h	; 513a

; ----------------------------------------------------------------------
; DATOS secuencias_de_sonido: las 54 melodias y efectos, destinos de la tabla
;   de arriba; las recorre el interprete de 0x4E50
;   0x5146..0x5645  (1279 bytes)
DATA_secuencias_de_sonido:
	defb 021h	; 5146
	defb 0d1h	; 5147
	defb 018h	; 5148
	defb 0c1h	; 5149
	defb 015h	; 514a
	defb 0c1h	; 514b
	defb 013h	; 514c
	defb 0c1h	; 514d
	defb 010h	; 514e
	defb 0b1h	; 514f
	defb 00ch	; 5150
	defb 0b1h	; 5151
	defb 008h	; 5152
	defb 0a1h	; 5153
	defb 003h	; 5154
	defb 0a0h	; 5155
	defb 0fch	; 5156
	defb 090h	; 5157
	defb 0f8h	; 5158
	defb 090h	; 5159
	defb 0f3h	; 515a
	defb 080h	; 515b
	defb 0ech	; 515c
	defb 080h	; 515d
	defb 0e8h	; 515e
	defb 080h	; 515f
	defb 0e3h	; 5160
	defb 070h	; 5161
	defb 0dch	; 5162
	defb 070h	; 5163
	defb 0d8h	; 5164
	defb 070h	; 5165
	defb 0d3h	; 5166
	defb 060h	; 5167
	defb 0cch	; 5168
	defb 060h	; 5169
	defb 0c8h	; 516a
	defb 060h	; 516b
	defb 0c3h	; 516c
	defb 060h	; 516d
	defb 0c8h	; 516e
	defb 060h	; 516f
	defb 0cah	; 5170
	defb 060h	; 5171
	defb 0d0h	; 5172
	defb 0ffh	; 5173
	defb 022h	; 5174
	defb 0d0h	; 5175
	defb 0cah	; 5176
	defb 0c0h	; 5177
	defb 0cdh	; 5178
	defb 0a0h	; 5179
	defb 0cah	; 517a
	defb 080h	; 517b
	defb 0cdh	; 517c
	defb 050h	; 517d
	defb 0cah	; 517e
	defb 0ffh	; 517f
	defb 021h	; 5180
	defb 0d0h	; 5181
	defb 0fch	; 5182
	defb 0f0h	; 5183
	defb 0edh	; 5184
	defb 0d0h	; 5185
	defb 0e7h	; 5186
	defb 0c0h	; 5187
	defb 0cdh	; 5188
	defb 0c0h	; 5189
	defb 0c5h	; 518a
	defb 0c0h	; 518b
	defb 0c1h	; 518c
	defb 0b0h	; 518d
	defb 0c9h	; 518e
	defb 0b0h	; 518f
	defb 0cdh	; 5190
	defb 0b0h	; 5191
	defb 0d1h	; 5192
	defb 0a0h	; 5193
	defb 0d9h	; 5194
	defb 090h	; 5195
	defb 0ddh	; 5196
	defb 080h	; 5197
	defb 0d0h	; 5198
	defb 070h	; 5199
	defb 0e3h	; 519a
	defb 060h	; 519b
	defb 0e6h	; 519c
	defb 050h	; 519d
	defb 0e9h	; 519e
	defb 040h	; 519f
	defb 0f2h	; 51a0
	defb 039h	; 51a1
	defb 0e3h	; 51a2
	defb 0ffh	; 51a3
	defb 0ffh	; 51a4
	defb 021h	; 51a5
	defb 018h	; 51a6
	defb 0b1h	; 51a7
	defb 070h	; 51a8
	defb 0d1h	; 51a9
	defb 000h	; 51aa
	defb 0b1h	; 51ab
	defb 0a0h	; 51ac
	defb 0c1h	; 51ad
	defb 040h	; 51ae
	defb 0a1h	; 51af
	defb 000h	; 51b0
	defb 091h	; 51b1
	defb 090h	; 51b2
	defb 081h	; 51b3
	defb 040h	; 51b4
	defb 071h	; 51b5
	defb 000h	; 51b6
	defb 061h	; 51b7
	defb 020h	; 51b8
	defb 051h	; 51b9
	defb 010h	; 51ba
	defb 0ffh	; 51bb
	defb 021h	; 51bc
	defb 01fh	; 51bd
	defb 0c2h	; 51be
	defb 030h	; 51bf
	defb 0a2h	; 51c0
	defb 000h	; 51c1
	defb 0b2h	; 51c2
	defb 030h	; 51c3
	defb 0b1h	; 51c4
	defb 0f0h	; 51c5
	defb 082h	; 51c6
	defb 030h	; 51c7
	defb 0b1h	; 51c8
	defb 0f0h	; 51c9
	defb 082h	; 51ca
	defb 030h	; 51cb
	defb 0ffh	; 51cc
	defb 021h	; 51cd
	defb 018h	; 51ce
	defb 0a2h	; 51cf
	defb 020h	; 51d0
	defb 082h	; 51d1
	defb 070h	; 51d2
	defb 000h	; 51d3
	defb 000h	; 51d4
	defb 080h	; 51d5
	defb 000h	; 51d6
	defb 060h	; 51d7
	defb 000h	; 51d8
	defb 000h	; 51d9
	defb 000h	; 51da
	defb 0feh	; 51db
	defb 005h	; 51dc
	defb 0d9h	; 51dd
	defb 051h	; 51de
	defb 0ffh	; 51df
	defb 026h	; 51e0
	defb 0b1h	; 51e1
	defb 000h	; 51e2
	defb 0b1h	; 51e3
	defb 000h	; 51e4
	defb 0a1h	; 51e5
	defb 000h	; 51e6
	defb 0b1h	; 51e7
	defb 000h	; 51e8
	defb 0a1h	; 51e9
	defb 000h	; 51ea
	defb 091h	; 51eb
	defb 000h	; 51ec
	defb 081h	; 51ed
	defb 000h	; 51ee
	defb 071h	; 51ef
	defb 000h	; 51f0
	defb 061h	; 51f1
	defb 000h	; 51f2
	defb 051h	; 51f3
	defb 000h	; 51f4
	defb 041h	; 51f5
	defb 000h	; 51f6
	defb 0ffh	; 51f7
	defb 026h	; 51f8
	defb 0c0h	; 51f9
	defb 0e0h	; 51fa
	defb 0b0h	; 51fb
	defb 0e0h	; 51fc
	defb 0a0h	; 51fd
	defb 0e0h	; 51fe
	defb 0b0h	; 51ff
	defb 0e0h	; 5200
	defb 0a0h	; 5201
	defb 0e0h	; 5202
	defb 090h	; 5203
	defb 0e0h	; 5204
	defb 080h	; 5205
	defb 0e0h	; 5206
	defb 070h	; 5207
	defb 0e0h	; 5208
	defb 060h	; 5209
	defb 0e0h	; 520a
	defb 050h	; 520b
	defb 0e0h	; 520c
	defb 040h	; 520d
	defb 0e0h	; 520e
	defb 0ffh	; 520f
	defb 022h	; 5210
	defb 011h	; 5211
	defb 000h	; 5212
	defb 000h	; 5213
	defb 0feh	; 5214
	defb 006h	; 5215
	defb 012h	; 5216
	defb 052h	; 5217
	defb 0d0h	; 5218
	defb 0fah	; 5219
	defb 0c1h	; 521a
	defb 000h	; 521b
	defb 0b1h	; 521c
	defb 00ah	; 521d
	defb 0a1h	; 521e
	defb 00ah	; 521f
	defb 091h	; 5220
	defb 00ah	; 5221
	defb 081h	; 5222
	defb 00ah	; 5223
	defb 071h	; 5224
	defb 00ah	; 5225
	defb 061h	; 5226
	defb 00ah	; 5227
	defb 051h	; 5228
	defb 00ah	; 5229
	defb 0ffh	; 522a
	defb 022h	; 522b
	defb 0f1h	; 522c
	defb 00ah	; 522d
	defb 0f1h	; 522e
	defb 00dh	; 522f
	defb 0d1h	; 5230
	defb 00ah	; 5231
	defb 0b1h	; 5232
	defb 00dh	; 5233
	defb 091h	; 5234
	defb 00bh	; 5235
	defb 0ffh	; 5236
	defb 021h	; 5237
	defb 010h	; 5238
	defb 0b0h	; 5239
	defb 000h	; 523a
	defb 0c0h	; 523b
	defb 000h	; 523c
	defb 0b0h	; 523d
	defb 000h	; 523e
	defb 0a0h	; 523f
	defb 000h	; 5240
	defb 090h	; 5241
	defb 000h	; 5242
	defb 080h	; 5243
	defb 000h	; 5244
	defb 070h	; 5245
	defb 000h	; 5246
	defb 060h	; 5247
	defb 000h	; 5248
	defb 0ffh	; 5249
	defb 021h	; 524a
	defb 0b2h	; 524b
	defb 040h	; 524c
	defb 0a2h	; 524d
	defb 04ah	; 524e
	defb 0b2h	; 524f
	defb 030h	; 5250
	defb 092h	; 5251
	defb 01ah	; 5252
	defb 082h	; 5253
	defb 01bh	; 5254
	defb 072h	; 5255
	defb 025h	; 5256
	defb 062h	; 5257
	defb 020h	; 5258
	defb 052h	; 5259
	defb 02bh	; 525a
	defb 042h	; 525b
	defb 02bh	; 525c
	defb 032h	; 525d
	defb 02bh	; 525e
	defb 0ffh	; 525f
	defb 021h	; 5260
	defb 082h	; 5261
	defb 04bh	; 5262
	defb 092h	; 5263
	defb 04bh	; 5264
	defb 082h	; 5265
	defb 02bh	; 5266
	defb 072h	; 5267
	defb 01bh	; 5268
	defb 062h	; 5269
	defb 01ch	; 526a
	defb 052h	; 526b
	defb 02bh	; 526c
	defb 042h	; 526d
	defb 02bh	; 526e
	defb 032h	; 526f
	defb 02bh	; 5270
	defb 021h	; 5271
	defb 022h	; 5272
	defb 02bh	; 5273
	defb 0ffh	; 5274
	defb 021h	; 5275
	defb 0a1h	; 5276
	defb 05fh	; 5277
	defb 092h	; 5278
	defb 050h	; 5279
	defb 081h	; 527a
	defb 0cfh	; 527b
	defb 072h	; 527c
	defb 080h	; 527d
	defb 061h	; 527e
	defb 0afh	; 527f
	defb 052h	; 5280
	defb 0dfh	; 5281
	defb 041h	; 5282
	defb 050h	; 5283
	defb 0ffh	; 5284
	defb 021h	; 5285
	defb 0b2h	; 5286
	defb 020h	; 5287
	defb 0b3h	; 5288
	defb 010h	; 5289
	defb 0a2h	; 528a
	defb 090h	; 528b
	defb 083h	; 528c
	defb 010h	; 528d
	defb 063h	; 528e
	defb 070h	; 528f
	defb 042h	; 5290
	defb 070h	; 5291
	defb 041h	; 5292
	defb 0a0h	; 5293
	defb 0ffh	; 5294
	defb 021h	; 5295
	defb 0c1h	; 5296
	defb 0e0h	; 5297
	defb 0a1h	; 5298
	defb 0e0h	; 5299
	defb 0b2h	; 529a
	defb 0e0h	; 529b
	defb 0a2h	; 529c
	defb 000h	; 529d
	defb 092h	; 529e
	defb 0e0h	; 529f
	defb 082h	; 52a0
	defb 000h	; 52a1
	defb 072h	; 52a2
	defb 0e0h	; 52a3
	defb 062h	; 52a4
	defb 000h	; 52a5
	defb 052h	; 52a6
	defb 0e0h	; 52a7
	defb 0ffh	; 52a8
	defb 021h	; 52a9
	defb 0c1h	; 52aa
	defb 040h	; 52ab
	defb 0a1h	; 52ac
	defb 0b0h	; 52ad
	defb 0b2h	; 52ae
	defb 000h	; 52af
	defb 0a1h	; 52b0
	defb 0b0h	; 52b1
	defb 092h	; 52b2
	defb 000h	; 52b3
	defb 081h	; 52b4
	defb 0b0h	; 52b5
	defb 072h	; 52b6
	defb 000h	; 52b7
	defb 061h	; 52b8
	defb 0b0h	; 52b9
	defb 052h	; 52ba
	defb 000h	; 52bb
	defb 0ffh	; 52bc
	defb 021h	; 52bd
	defb 01fh	; 52be
	defb 0e1h	; 52bf
	defb 023h	; 52c0
	defb 0c3h	; 52c1
	defb 034h	; 52c2
	defb 0e1h	; 52c3
	defb 056h	; 52c4
	defb 0c3h	; 52c5
	defb 067h	; 52c6
	defb 0a5h	; 52c7
	defb 023h	; 52c8
	defb 086h	; 52c9
	defb 034h	; 52ca
	defb 067h	; 52cb
	defb 033h	; 52cc
	defb 0ffh	; 52cd
	defb 021h	; 52ce
	defb 01fh	; 52cf
	defb 081h	; 52d0
	defb 060h	; 52d1
	defb 0c0h	; 52d2
	defb 000h	; 52d3
	defb 061h	; 52d4
	defb 040h	; 52d5
	defb 0b0h	; 52d6
	defb 000h	; 52d7
	defb 041h	; 52d8
	defb 020h	; 52d9
	defb 0e0h	; 52da
	defb 000h	; 52db
	defb 0ffh	; 52dc
	defb 021h	; 52dd
	defb 01eh	; 52de
	defb 0b3h	; 52df
	defb 030h	; 52e0
	defb 0b3h	; 52e1
	defb 030h	; 52e2
	defb 0b3h	; 52e3
	defb 030h	; 52e4
	defb 000h	; 52e5
	defb 000h	; 52e6
	defb 000h	; 52e7
	defb 000h	; 52e8
	defb 0b3h	; 52e9
	defb 030h	; 52ea
	defb 0c3h	; 52eb
	defb 04ah	; 52ec
	defb 0b3h	; 52ed
	defb 030h	; 52ee
	defb 0c3h	; 52ef
	defb 04ah	; 52f0
	defb 0b3h	; 52f1
	defb 030h	; 52f2
	defb 0c3h	; 52f3
	defb 04ah	; 52f4
	defb 0ffh	; 52f5
	defb 021h	; 52f6
	defb 01fh	; 52f7
	defb 082h	; 52f8
	defb 0a2h	; 52f9
	defb 0b2h	; 52fa
	defb 0a2h	; 52fb
	defb 082h	; 52fc
	defb 0a2h	; 52fd
	defb 000h	; 52fe
	defb 000h	; 52ff
	defb 000h	; 5300
	defb 000h	; 5301
	defb 0b2h	; 5302
	defb 0a2h	; 5303
	defb 0c2h	; 5304
	defb 0cch	; 5305
	defb 0b2h	; 5306
	defb 0a4h	; 5307
	defb 0c2h	; 5308
	defb 0ceh	; 5309
	defb 0b2h	; 530a
	defb 0a6h	; 530b
	defb 0c2h	; 530c
	defb 0d0h	; 530d
	defb 0ffh	; 530e
	defb 02ah	; 530f
	defb 0c0h	; 5310
	defb 08eh	; 5311
	defb 0c0h	; 5312
	defb 08eh	; 5313
	defb 026h	; 5314
	defb 0c0h	; 5315
	defb 08eh	; 5316
	defb 060h	; 5317
	defb 08eh	; 5318
	defb 0ffh	; 5319
	defb 02ah	; 531a
	defb 0c0h	; 531b
	defb 06ah	; 531c
	defb 0c0h	; 531d
	defb 06ah	; 531e
	defb 026h	; 531f
	defb 0c0h	; 5320
	defb 06ah	; 5321
	defb 060h	; 5322
	defb 06ah	; 5323
	defb 0ffh	; 5324
	defb 02ah	; 5325
	defb 0c0h	; 5326
	defb 08eh	; 5327
	defb 060h	; 5328
	defb 08eh	; 5329
	defb 02bh	; 532a
	defb 0c0h	; 532b
	defb 08eh	; 532c
	defb 0c0h	; 532d
	defb 08eh	; 532e
	defb 028h	; 532f
	defb 0c0h	; 5330
	defb 08eh	; 5331
	defb 060h	; 5332
	defb 08eh	; 5333
	defb 0ffh	; 5334
	defb 02ah	; 5335
	defb 0c0h	; 5336
	defb 06ah	; 5337
	defb 060h	; 5338
	defb 06ah	; 5339
	defb 02bh	; 533a
	defb 0c0h	; 533b
	defb 06ah	; 533c
	defb 0c0h	; 533d
	defb 06ah	; 533e
	defb 028h	; 533f
	defb 0c0h	; 5340
	defb 06ah	; 5341
	defb 060h	; 5342
	defb 06ah	; 5343
	defb 0ffh	; 5344
	defb 021h	; 5345
	defb 0d1h	; 5346
	defb 020h	; 5347
	defb 0c2h	; 5348
	defb 010h	; 5349
	defb 0b1h	; 534a
	defb 090h	; 534b
	defb 0a3h	; 534c
	defb 010h	; 534d
	defb 092h	; 534e
	defb 070h	; 534f
	defb 0c1h	; 5350
	defb 070h	; 5351
	defb 0b2h	; 5352
	defb 0a0h	; 5353
	defb 0b1h	; 5354
	defb 010h	; 5355
	defb 071h	; 5356
	defb 010h	; 5357
	defb 061h	; 5358
	defb 010h	; 5359
	defb 051h	; 535a
	defb 010h	; 535b
	defb 041h	; 535c
	defb 010h	; 535d
	defb 0ffh	; 535e
	defb 021h	; 535f
	defb 0e5h	; 5360
	defb 010h	; 5361
	defb 0d6h	; 5362
	defb 000h	; 5363
	defb 0c5h	; 5364
	defb 080h	; 5365
	defb 0b7h	; 5366
	defb 000h	; 5367
	defb 0a6h	; 5368
	defb 060h	; 5369
	defb 0d5h	; 536a
	defb 060h	; 536b
	defb 0c6h	; 536c
	defb 090h	; 536d
	defb 0ffh	; 536e
	defb 021h	; 536f
	defb 0e2h	; 5370
	defb 010h	; 5371
	defb 0d3h	; 5372
	defb 000h	; 5373
	defb 0c2h	; 5374
	defb 080h	; 5375
	defb 0b4h	; 5376
	defb 000h	; 5377
	defb 0a3h	; 5378
	defb 060h	; 5379
	defb 0d2h	; 537a
	defb 060h	; 537b
	defb 0c3h	; 537c
	defb 090h	; 537d
	defb 0ffh	; 537e
	defb 023h	; 537f
	defb 01fh	; 5380
	defb 090h	; 5381
	defb 000h	; 5382
	defb 090h	; 5383
	defb 000h	; 5384
	defb 0a0h	; 5385
	defb 000h	; 5386
	defb 0a0h	; 5387
	defb 000h	; 5388
	defb 022h	; 5389
	defb 0b0h	; 538a
	defb 020h	; 538b
	defb 0b0h	; 538c
	defb 022h	; 538d
	defb 0b0h	; 538e
	defb 024h	; 538f
	defb 0c0h	; 5390
	defb 026h	; 5391
	defb 0c0h	; 5392
	defb 028h	; 5393
	defb 0c0h	; 5394
	defb 02ah	; 5395
	defb 021h	; 5396
	defb 0c0h	; 5397
	defb 000h	; 5398
	defb 022h	; 5399
	defb 0c0h	; 539a
	defb 020h	; 539b
	defb 0c0h	; 539c
	defb 022h	; 539d
	defb 0c0h	; 539e
	defb 024h	; 539f
	defb 0c0h	; 53a0
	defb 026h	; 53a1
	defb 0c0h	; 53a2
	defb 028h	; 53a3
	defb 0c0h	; 53a4
	defb 02ah	; 53a5
	defb 0c0h	; 53a6
	defb 000h	; 53a7
	defb 025h	; 53a8
	defb 0c0h	; 53a9
	defb 000h	; 53aa
	defb 0c0h	; 53ab
	defb 000h	; 53ac
	defb 021h	; 53ad
	defb 0c0h	; 53ae
	defb 000h	; 53af
	defb 090h	; 53b0
	defb 000h	; 53b1
	defb 090h	; 53b2
	defb 000h	; 53b3
	defb 0a0h	; 53b4
	defb 000h	; 53b5
	defb 0a0h	; 53b6
	defb 000h	; 53b7
	defb 0feh	; 53b8
	defb 003h	; 53b9
	defb 089h	; 53ba
	defb 053h	; 53bb
	defb 023h	; 53bc
	defb 01fh	; 53bd
	defb 0b0h	; 53be
	defb 000h	; 53bf
	defb 0a0h	; 53c0
	defb 000h	; 53c1
	defb 090h	; 53c2
	defb 000h	; 53c3
	defb 090h	; 53c4
	defb 000h	; 53c5
	defb 080h	; 53c6
	defb 000h	; 53c7
	defb 060h	; 53c8
	defb 000h	; 53c9
	defb 060h	; 53ca
	defb 000h	; 53cb
	defb 050h	; 53cc
	defb 000h	; 53cd
	defb 050h	; 53ce
	defb 000h	; 53cf
	defb 022h	; 53d0
	defb 040h	; 53d1
	defb 000h	; 53d2
	defb 030h	; 53d3
	defb 000h	; 53d4
	defb 0ffh	; 53d5
	defb 021h	; 53d6
	defb 01fh	; 53d7
	defb 0b0h	; 53d8
	defb 000h	; 53d9
	defb 0c0h	; 53da
	defb 000h	; 53db
	defb 0b0h	; 53dc
	defb 000h	; 53dd
	defb 0c0h	; 53de
	defb 000h	; 53df
	defb 0d0h	; 53e0
	defb 000h	; 53e1
	defb 0e0h	; 53e2
	defb 000h	; 53e3
	defb 0d0h	; 53e4
	defb 000h	; 53e5
	defb 0e0h	; 53e6
	defb 000h	; 53e7
	defb 022h	; 53e8
	defb 0e0h	; 53e9
	defb 000h	; 53ea
	defb 0d0h	; 53eb
	defb 000h	; 53ec
	defb 0e0h	; 53ed
	defb 000h	; 53ee
	defb 0d0h	; 53ef
	defb 000h	; 53f0
	defb 0e0h	; 53f1
	defb 000h	; 53f2
	defb 0d0h	; 53f3
	defb 000h	; 53f4
	defb 0e0h	; 53f5
	defb 000h	; 53f6
	defb 0c0h	; 53f7
	defb 000h	; 53f8
	defb 0d0h	; 53f9
	defb 000h	; 53fa
	defb 0c0h	; 53fb
	defb 000h	; 53fc
	defb 0d0h	; 53fd
	defb 000h	; 53fe
	defb 0d0h	; 53ff
	defb 000h	; 5400
	defb 0d0h	; 5401
	defb 000h	; 5402
	defb 0c0h	; 5403
	defb 000h	; 5404
	defb 0d0h	; 5405
	defb 000h	; 5406
	defb 0c0h	; 5407
	defb 000h	; 5408
	defb 0d0h	; 5409
	defb 000h	; 540a
	defb 0f0h	; 540b
	defb 000h	; 540c
	defb 0e0h	; 540d
	defb 000h	; 540e
	defb 0d0h	; 540f
	defb 000h	; 5410
	defb 0c0h	; 5411
	defb 000h	; 5412
	defb 0e0h	; 5413
	defb 000h	; 5414
	defb 0e0h	; 5415
	defb 000h	; 5416
	defb 0d0h	; 5417
	defb 000h	; 5418
	defb 0c0h	; 5419
	defb 000h	; 541a
	defb 0d0h	; 541b
	defb 000h	; 541c
	defb 0c0h	; 541d
	defb 000h	; 541e
	defb 0d0h	; 541f
	defb 000h	; 5420
	defb 0c0h	; 5421
	defb 000h	; 5422
	defb 0b0h	; 5423
	defb 000h	; 5424
	defb 0a0h	; 5425
	defb 000h	; 5426
	defb 0b0h	; 5427
	defb 000h	; 5428
	defb 0a0h	; 5429
	defb 000h	; 542a
	defb 0b0h	; 542b
	defb 000h	; 542c
	defb 0a0h	; 542d
	defb 000h	; 542e
	defb 024h	; 542f
	defb 01eh	; 5430
	defb 0b0h	; 5431
	defb 000h	; 5432
	defb 0a0h	; 5433
	defb 000h	; 5434
	defb 0a0h	; 5435
	defb 000h	; 5436
	defb 022h	; 5437
	defb 0b0h	; 5438
	defb 000h	; 5439
	defb 0a0h	; 543a
	defb 000h	; 543b
	defb 0b0h	; 543c
	defb 000h	; 543d
	defb 0a0h	; 543e
	defb 000h	; 543f
	defb 0b0h	; 5440
	defb 000h	; 5441
	defb 0a0h	; 5442
	defb 000h	; 5443
	defb 0a0h	; 5444
	defb 000h	; 5445
	defb 090h	; 5446
	defb 000h	; 5447
	defb 0a0h	; 5448
	defb 000h	; 5449
	defb 090h	; 544a
	defb 000h	; 544b
	defb 0a0h	; 544c
	defb 000h	; 544d
	defb 090h	; 544e
	defb 000h	; 544f
	defb 0a0h	; 5450
	defb 000h	; 5451
	defb 0b0h	; 5452
	defb 000h	; 5453
	defb 0a0h	; 5454
	defb 000h	; 5455
	defb 0b0h	; 5456
	defb 000h	; 5457
	defb 0a0h	; 5458
	defb 000h	; 5459
	defb 0b0h	; 545a
	defb 000h	; 545b
	defb 0c0h	; 545c
	defb 000h	; 545d
	defb 0b0h	; 545e
	defb 000h	; 545f
	defb 0c0h	; 5460
	defb 000h	; 5461
	defb 0b0h	; 5462
	defb 000h	; 5463
	defb 0c0h	; 5464
	defb 000h	; 5465
	defb 0b0h	; 5466
	defb 000h	; 5467
	defb 0b0h	; 5468
	defb 000h	; 5469
	defb 0a0h	; 546a
	defb 000h	; 546b
	defb 0b0h	; 546c
	defb 000h	; 546d
	defb 0a0h	; 546e
	defb 000h	; 546f
	defb 0b0h	; 5470
	defb 000h	; 5471
	defb 0a0h	; 5472
	defb 000h	; 5473
	defb 090h	; 5474
	defb 000h	; 5475
	defb 080h	; 5476
	defb 000h	; 5477
	defb 090h	; 5478
	defb 000h	; 5479
	defb 080h	; 547a
	defb 000h	; 547b
	defb 090h	; 547c
	defb 000h	; 547d
	defb 080h	; 547e
	defb 000h	; 547f
	defb 070h	; 5480
	defb 000h	; 5481
	defb 060h	; 5482
	defb 000h	; 5483
	defb 070h	; 5484
	defb 000h	; 5485
	defb 060h	; 5486
	defb 000h	; 5487
	defb 050h	; 5488
	defb 000h	; 5489
	defb 060h	; 548a
	defb 000h	; 548b
	defb 050h	; 548c
	defb 000h	; 548d
	defb 040h	; 548e
	defb 000h	; 548f
	defb 030h	; 5490
	defb 000h	; 5491
	defb 040h	; 5492
	defb 000h	; 5493
	defb 0ffh	; 5494
	defb 023h	; 5495
	defb 000h	; 5496
	defb 000h	; 5497
	defb 000h	; 5498
	defb 000h	; 5499
	defb 000h	; 549a
	defb 000h	; 549b
	defb 000h	; 549c
	defb 000h	; 549d
	defb 022h	; 549e
	defb 080h	; 549f
	defb 020h	; 54a0
	defb 080h	; 54a1
	defb 022h	; 54a2
	defb 080h	; 54a3
	defb 024h	; 54a4
	defb 090h	; 54a5
	defb 026h	; 54a6
	defb 090h	; 54a7
	defb 028h	; 54a8
	defb 090h	; 54a9
	defb 02ah	; 54aa
	defb 021h	; 54ab
	defb 090h	; 54ac
	defb 000h	; 54ad
	defb 022h	; 54ae
	defb 090h	; 54af
	defb 020h	; 54b0
	defb 090h	; 54b1
	defb 022h	; 54b2
	defb 090h	; 54b3
	defb 024h	; 54b4
	defb 090h	; 54b5
	defb 026h	; 54b6
	defb 090h	; 54b7
	defb 028h	; 54b8
	defb 090h	; 54b9
	defb 02ah	; 54ba
	defb 090h	; 54bb
	defb 000h	; 54bc
	defb 025h	; 54bd
	defb 000h	; 54be
	defb 000h	; 54bf
	defb 000h	; 54c0
	defb 000h	; 54c1
	defb 021h	; 54c2
	defb 000h	; 54c3
	defb 000h	; 54c4
	defb 000h	; 54c5
	defb 000h	; 54c6
	defb 000h	; 54c7
	defb 000h	; 54c8
	defb 000h	; 54c9
	defb 000h	; 54ca
	defb 000h	; 54cb
	defb 000h	; 54cc
	defb 0feh	; 54cd
	defb 003h	; 54ce
	defb 09eh	; 54cf
	defb 054h	; 54d0
	defb 023h	; 54d1
	defb 000h	; 54d2
	defb 000h	; 54d3
	defb 000h	; 54d4
	defb 000h	; 54d5
	defb 000h	; 54d6
	defb 000h	; 54d7
	defb 000h	; 54d8
	defb 000h	; 54d9
	defb 000h	; 54da
	defb 000h	; 54db
	defb 000h	; 54dc
	defb 000h	; 54dd
	defb 000h	; 54de
	defb 000h	; 54df
	defb 000h	; 54e0
	defb 000h	; 54e1
	defb 000h	; 54e2
	defb 000h	; 54e3
	defb 022h	; 54e4
	defb 000h	; 54e5
	defb 000h	; 54e6
	defb 000h	; 54e7
	defb 000h	; 54e8
	defb 0ffh	; 54e9
	defb 0d6h	; 54ea
	defb 0fch	; 54eb
	defb 003h	; 54ec
	defb 003h	; 54ed
	defb 0e1h	; 54ee
	defb 021h	; 54ef
	defb 0e2h	; 54f0
	defb 0b0h	; 54f1
	defb 0e1h	; 54f2
	defb 000h	; 54f3
	defb 021h	; 54f4
	defb 073h	; 54f5
	defb 023h	; 54f6
	defb 021h	; 54f7
	defb 005h	; 54f8
	defb 023h	; 54f9
	defb 0e2h	; 54fa
	defb 091h	; 54fb
	defb 0b1h	; 54fc
	defb 0e1h	; 54fd
	defb 005h	; 54fe
	defb 0e2h	; 54ff
	defb 091h	; 5500
	defb 0e1h	; 5501
	defb 003h	; 5502
	defb 0e2h	; 5503
	defb 091h	; 5504
	defb 0b1h	; 5505
	defb 0e1h	; 5506
	defb 001h	; 5507
	defb 02ch	; 5508
	defb 0c2h	; 5509
	defb 0feh	; 550a
	defb 0ffh	; 550b
	defb 0eah	; 550c
	defb 054h	; 550d
	defb 0ffh	; 550e
	defb 0d6h	; 550f
	defb 0fch	; 5510
	defb 000h	; 5511
	defb 00fh	; 5512
	defb 0e3h	; 5513
	defb 071h	; 5514
	defb 0fah	; 5515
	defb 001h	; 5516
	defb 005h	; 5517
	defb 0e2h	; 5518
	defb 070h	; 5519
	defb 070h	; 551a
	defb 0feh	; 551b
	defb 008h	; 551c
	defb 00fh	; 551d
	defb 055h	; 551e
	defb 0fch	; 551f
	defb 000h	; 5520
	defb 00fh	; 5521
	defb 0e3h	; 5522
	defb 051h	; 5523
	defb 0fah	; 5524
	defb 001h	; 5525
	defb 005h	; 5526
	defb 0e2h	; 5527
	defb 050h	; 5528
	defb 050h	; 5529
	defb 0feh	; 552a
	defb 004h	; 552b
	defb 01fh	; 552c
	defb 055h	; 552d
	defb 0fch	; 552e
	defb 000h	; 552f
	defb 00fh	; 5530
	defb 0e3h	; 5531
	defb 071h	; 5532
	defb 0fah	; 5533
	defb 001h	; 5534
	defb 005h	; 5535
	defb 0e2h	; 5536
	defb 070h	; 5537
	defb 070h	; 5538
	defb 0feh	; 5539
	defb 004h	; 553a
	defb 02eh	; 553b
	defb 055h	; 553c
	defb 0feh	; 553d
	defb 0ffh	; 553e
	defb 00fh	; 553f
	defb 055h	; 5540
	defb 0ffh	; 5541
	defb 0d6h	; 5542
	defb 0fch	; 5543
	defb 002h	; 5544
	defb 006h	; 5545
	defb 0e1h	; 5546
	defb 005h	; 5547
	defb 0e2h	; 5548
	defb 071h	; 5549
	defb 0e1h	; 554a
	defb 045h	; 554b
	defb 020h	; 554c
	defb 000h	; 554d
	defb 021h	; 554e
	defb 073h	; 554f
	defb 0fch	; 5550
	defb 003h	; 5551
	defb 000h	; 5552
	defb 0b2h	; 5553
	defb 0fch	; 5554
	defb 002h	; 5555
	defb 006h	; 5556
	defb 0e0h	; 5557
	defb 020h	; 5558
	defb 000h	; 5559
	defb 0e1h	; 555a
	defb 0b0h	; 555b
	defb 0e0h	; 555c
	defb 020h	; 555d
	defb 000h	; 555e
	defb 0e1h	; 555f
	defb 0b0h	; 5560
	defb 070h	; 5561
	defb 095h	; 5562
	defb 051h	; 5563
	defb 0b3h	; 5564
	defb 0e0h	; 5565
	defb 000h	; 5566
	defb 020h	; 5567
	defb 0c0h	; 5568
	defb 04bh	; 5569
	defb 0ffh	; 556a
	defb 0d6h	; 556b
	defb 0fch	; 556c
	defb 002h	; 556d
	defb 008h	; 556e
	defb 0e2h	; 556f
	defb 045h	; 5570
	defb 041h	; 5571
	defb 077h	; 5572
	defb 0b1h	; 5573
	defb 0e1h	; 5574
	defb 023h	; 5575
	defb 079h	; 5576
	defb 055h	; 5577
	defb 001h	; 5578
	defb 073h	; 5579
	defb 040h	; 557a
	defb 050h	; 557b
	defb 0c0h	; 557c
	defb 07bh	; 557d
	defb 0ffh	; 557e
	defb 0d6h	; 557f
	defb 0fch	; 5580
	defb 001h	; 5581
	defb 005h	; 5582
	defb 0e3h	; 5583
	defb 001h	; 5584
	defb 0e2h	; 5585
	defb 000h	; 5586
	defb 000h	; 5587
	defb 0feh	; 5588
	defb 004h	; 5589
	defb 07fh	; 558a
	defb 055h	; 558b
	defb 0e3h	; 558c
	defb 071h	; 558d
	defb 0e2h	; 558e
	defb 070h	; 558f
	defb 070h	; 5590
	defb 0feh	; 5591
	defb 004h	; 5592
	defb 08ch	; 5593
	defb 055h	; 5594
	defb 0e3h	; 5595
	defb 051h	; 5596
	defb 0e2h	; 5597
	defb 050h	; 5598
	defb 050h	; 5599
	defb 0feh	; 559a
	defb 002h	; 559b
	defb 095h	; 559c
	defb 055h	; 559d
	defb 0e3h	; 559e
	defb 072h	; 559f
	defb 070h	; 55a0
	defb 090h	; 55a1
	defb 0b0h	; 55a2
	defb 0c0h	; 55a3
	defb 0e2h	; 55a4
	defb 00bh	; 55a5
	defb 0ffh	; 55a6
	defb 0d7h	; 55a7
	defb 0fch	; 55a8
	defb 002h	; 55a9
	defb 001h	; 55aa
	defb 0e1h	; 55ab
	defb 061h	; 55ac
	defb 071h	; 55ad
	defb 051h	; 55ae
	defb 020h	; 55af
	defb 0e2h	; 55b0
	defb 0b0h	; 55b1
	defb 0c0h	; 55b2
	defb 070h	; 55b3
	defb 0b0h	; 55b4
	defb 0e1h	; 55b5
	defb 020h	; 55b6
	defb 0c0h	; 55b7
	defb 071h	; 55b8
	defb 050h	; 55b9
	defb 041h	; 55ba
	defb 071h	; 55bb
	defb 041h	; 55bc
	defb 000h	; 55bd
	defb 0e2h	; 55be
	defb 070h	; 55bf
	defb 0c0h	; 55c0
	defb 070h	; 55c1
	defb 0e1h	; 55c2
	defb 000h	; 55c3
	defb 040h	; 55c4
	defb 0c0h	; 55c5
	defb 071h	; 55c6
	defb 040h	; 55c7
	defb 0e2h	; 55c8
	defb 090h	; 55c9
	defb 0e1h	; 55ca
	defb 010h	; 55cb
	defb 040h	; 55cc
	defb 091h	; 55cd
	defb 081h	; 55ce
	defb 070h	; 55cf
	defb 060h	; 55d0
	defb 020h	; 55d1
	defb 0e2h	; 55d2
	defb 090h	; 55d3
	defb 0b1h	; 55d4
	defb 0e1h	; 55d5
	defb 021h	; 55d6
	defb 070h	; 55d7
	defb 060h	; 55d8
	defb 020h	; 55d9
	defb 0e2h	; 55da
	defb 090h	; 55db
	defb 0e1h	; 55dc
	defb 041h	; 55dd
	defb 010h	; 55de
	defb 0e2h	; 55df
	defb 091h	; 55e0
	defb 0e1h	; 55e1
	defb 027h	; 55e2
	defb 0ffh	; 55e3
	defb 0d7h	; 55e4
	defb 0fch	; 55e5
	defb 002h	; 55e6
	defb 003h	; 55e7
	defb 0e3h	; 55e8
	defb 0b1h	; 55e9
	defb 0e2h	; 55ea
	defb 071h	; 55eb
	defb 0c1h	; 55ec
	defb 0e2h	; 55ed
	defb 071h	; 55ee
	defb 021h	; 55ef
	defb 0c1h	; 55f0
	defb 0e3h	; 55f1
	defb 0b1h	; 55f2
	defb 0e2h	; 55f3
	defb 021h	; 55f4
	defb 001h	; 55f5
	defb 041h	; 55f6
	defb 071h	; 55f7
	defb 0e2h	; 55f8
	defb 041h	; 55f9
	defb 001h	; 55fa
	defb 041h	; 55fb
	defb 071h	; 55fc
	defb 0e1h	; 55fd
	defb 001h	; 55fe
	defb 0e2h	; 55ff
	defb 041h	; 5600
	defb 091h	; 5601
	defb 011h	; 5602
	defb 091h	; 5603
	defb 021h	; 5604
	defb 061h	; 5605
	defb 071h	; 5606
	defb 0b1h	; 5607
	defb 091h	; 5608
	defb 061h	; 5609
	defb 071h	; 560a
	defb 041h	; 560b
	defb 061h	; 560c
	defb 0e3h	; 560d
	defb 091h	; 560e
	defb 0e2h	; 560f
	defb 023h	; 5610
	defb 0ffh	; 5611
	defb 0d7h	; 5612
	defb 0fch	; 5613
	defb 002h	; 5614
	defb 003h	; 5615
	defb 0e4h	; 5616
	defb 0b2h	; 5617
	defb 0e3h	; 5618
	defb 020h	; 5619
	defb 072h	; 561a
	defb 020h	; 561b
	defb 0e4h	; 561c
	defb 0b2h	; 561d
	defb 070h	; 561e
	defb 0b2h	; 561f
	defb 0e3h	; 5620
	defb 020h	; 5621
	defb 002h	; 5622
	defb 040h	; 5623
	defb 072h	; 5624
	defb 040h	; 5625
	defb 002h	; 5626
	defb 0e4h	; 5627
	defb 070h	; 5628
	defb 0e3h	; 5629
	defb 002h	; 562a
	defb 040h	; 562b
	defb 0e4h	; 562c
	defb 092h	; 562d
	defb 0e3h	; 562e
	defb 040h	; 562f
	defb 092h	; 5630
	defb 0e2h	; 5631
	defb 010h	; 5632
	defb 0e3h	; 5633
	defb 022h	; 5634
	defb 060h	; 5635
	defb 072h	; 5636
	defb 0b0h	; 5637
	defb 092h	; 5638
	defb 0e2h	; 5639
	defb 020h	; 563a
	defb 0e3h	; 563b
	defb 092h	; 563c
	defb 0e2h	; 563d
	defb 010h	; 563e
	defb 021h	; 563f
	defb 0e3h	; 5640
	defb 061h	; 5641
	defb 023h	; 5642
	defb 0ffh	; 5643
	defb 0ffh	; 5644

; ======================================================================
; CODIGO 0x5645..0x579f  (346 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL MONTAJE DEL PARTIDO =====
; ----------------------------------------------------------------------
monta_el_partido:		; borra la RAM de la jugada, coloca a los doce en el saque y pinta el marcador
	ld hl,0e100h		;5645   ; la RAM de la jugada empieza en 0xE100
	ld bc,004ffh		;5648   ; y son 0x500 bytes: 0xE100..0xE5FF, o sea las doce fichas, el marcador y el estado
	ld d,h			;564b   ; DE = HL+1, el truco de siempre para borrar con un `ldir`
	ld e,l			;564c
	inc de			;564d
	xor a			;564e
	ld (hl),a			;564f   ; siembra el primer cero, y el `ldir` lo arrastra hasta el final
	ldir		;5650
	ld (0e0f0h),a		;5652   ; (0xE0F0) tambien a cero: no hay gol ni fin de tiempo pendiente
	ld a,018h		;5655   ; el campo asoma por la columna 24 de las 80 que tiene
	ld (0e2c1h),a		;5657   ; (0xE2C1) es el desplazamiento del campo, el que mueve la ventana de 32
	ld hl,000c0h		;565a   ; el borde izquierdo de la ventana, en pixeles: 0xC0 son las 24 columnas de arriba por ocho
	ld (0e2c3h),hl		;565d
	ld hl,001bfh		;5660   ; y el derecho, 0x1BF, que es el izquierdo mas 255: el mismo ancho que le recalcula 0x8D7E
	ld (0e2c6h),hl		;5663
	ld hl,06a00h		;5666   ; (0xE2A0) parte baja a 0x00, alta a 0x6A
	ld (0e2a0h),hl		;5669
	ld h,03ch		;566c
	ld (0e2a4h),hl		;566e   ; (0xE2A4) = 0x3C00, reaprovechando la L que ya vale 0x00
	ld a,001h		;5671
	ld (0e2a6h),a		;5673   ; (0xE2A6) = 1
	ld h,l			;5676   ; H = L = 0, o sea HL = 0x0000, otro reaprovechamiento
	ld (0e2a9h),hl		;5677
	ld hl,00ee4h		;567a   ; (0xE2B3) = 0x0EE4
	ld (0e2b3h),hl		;567d
	ld hl,001ech		;5680   ; (0xE2B5) = 0x01EC, medio pixel menos que
	ld (0e2b5h),hl		;5683
	ld hl,001f4h		;5686   ; (0xE2B7) = 0x01F4, las dos rayas de la porteria
	ld (0e2b7h),hl		;5689

; ----------------------------------------------------------------------
; ----- los doce jugadores a sus puestos del saque -----
; ----------------------------------------------------------------------
	ld b,00ch		;568c   ; doce fichas, que es lo que hay: seis por bando, cinco de campo y el portero
	ld hl,0e104h		;568e   ; las fichas van de 32 bytes desde 0xE100 -asi las indexa 0xA201-, y el +4 es la altura
	ld de,0579fh		;5691   ; la tabla de un bando...
	ld a,(0e0f7h)		;5694   ; ...pero (0xE0F7) dice quien saca
	and a			;5697
	jr z,L_569D		;5698
	ld de,057c3h		;569a   ; ...y si no es cero se colocan con la otra tabla, la de los puestos espejados
L_569D:
	ld a,(de)			;569d   ; byte 0 de la entrada: la altura, al +4 de la ficha
	ld (hl),a			;569e
	inc hl			;569f   ; el +5 se lo salta: ahi va la parte fina que el saque no toca
	inc hl			;56a0
	inc de			;56a1
	ld a,(de)			;56a2   ; byte 1: la parte baja del ancho, al +6
	ld (hl),a			;56a3
	inc hl			;56a4
	inc de			;56a5
	ld a,(de)			;56a6   ; byte 2: la parte alta, al +7; el campo mide 640 pixeles y no cabe en un byte
	ld (hl),a			;56a7
	inc de			;56a8
	ld a,01dh		;56a9   ; y de +7 al +4 de la siguiente van 0x1D, que es 0x20 menos los tres avanzados
	call suma_a_hl		;56ab
	djnz L_569D		;56ae   ; hasta las doce

; ----------------------------------------------------------------------
; ----- cada jugador se aprende su numero -----
; ----------------------------------------------------------------------
	ld hl,0e115h		;56b0   ; el +0x15 de la primera ficha
	ld de,0e410h		;56b3   ; y la lista paralela de 0xE410, la que el orden de dibujo recorre
	ld b,00ch		;56b6   ; las mismas doce
	xor a			;56b8
L_56B9:
	ld (hl),a			;56b9   ; el numero, en la ficha
	ld (de),a			;56ba   ; y el mismo numero, en la lista de dibujo
	inc de			;56bb
	inc a			;56bc   ; siguiente numero
	ex af,af'			;56bd   ; el contador se guarda, que A hace falta para la suma
	ld a,020h		;56be   ; 0x20 es lo que mide una ficha
	call suma_a_hl		;56c0
	ex af,af'			;56c3   ; y se recupera el numero
	djnz L_56B9		;56c4
	call L_B50C		;56c6   ; y las doce, mirando hacia la pelota: aqui sin exentos, que todavia no hay destacados

; ----------------------------------------------------------------------
; ----- el estado del partido -----
; ----------------------------------------------------------------------
	ld a,0ffh		;56c9
	ld (0e528h),a		;56cb   ; 0xFF = ninguno: nadie lleva la pelota todavia
	ld (0e537h),a		;56ce
	ld (0e534h),a		;56d1
	ld a,001h		;56d4   ; (0xE532) = 1
	ld (0e532h),a		;56d6
	ld a,(0e0f7h)		;56d9   ; el bando que saca...
	ld (0e527h),a		;56dc   ; ...queda apuntado tambien en (0xE527)
	and a			;56df
	ld hl,00701h		;56e0   ; un bando arranca con estos valores...
	ld de,0e180h		;56e3
	ld a,004h		;56e6
	jr z,L_56F2		;56e8   ; ...y si el que saca es el otro, con estos
	ld hl,00a04h		;56ea
	ld de,0e1e0h		;56ed
	ld a,007h		;56f0
L_56F2:
	ld (0e542h),a		;56f2
	ld (0e52ch),hl		;56f5
	ld a,0ffh		;56f8   ; 0xFF cierra la lista con el centinela de siempre
	ld (de),a			;56fa
	ld a,070h		;56fb   ; 0x70 al reloj de las dos cuentas
	ld (0e291h),a		;56fd
	ld (0e292h),a		;5700
	ld hl,0ea11h		;5703   ; y los dos punteros de 0xEA11 y 0xEA5E
	ld (0e294h),hl		;5706
	ld hl,0ea5eh		;5709
	ld (0e296h),hl		;570c

; ----------------------------------------------------------------------
; ----- los dos porteros -----
; ----------------------------------------------------------------------
	ld hl,057e7h		;570f   ; los cinco bytes de portero de 0x57E7
	ld de,0e333h		;5712   ; al primero...
	ld bc,00005h		;5715
	ldir		;5718
	ld de,0e353h		;571a   ; ...y los cinco siguientes al segundo, que el `ldir` dejo HL ya en 0x57EC
	ld c,005h		;571d
	ldir		;571f
	ld hl,00100h		;5721   ; (0xE06A) = 0x0100
	ld (0e06ah),hl		;5724
	ld l,050h		;5727   ; y (0xE06C) = 0x0150 aprovechando la H que ya vale 1
	ld (0e06ch),hl		;5729

; ----------------------------------------------------------------------
; ----- la dificultad, segun el nivel -----
; ----------------------------------------------------------------------
	ld hl,057efh		;572c   ; la tabla de un modo...
	ld a,(0e002h)		;572f   ; el bit 5 de (0xE002) es el que separa los dos modos de juego
	and 020h		;5732
	jr z,L_5739		;5734
	ld hl,057f9h		;5736   ; ...y esta la del otro
L_5739:
	ld a,(0e069h)		;5739   ; el nivel elegido en el menu
	add a,a			;573c   ; dos bytes por entrada
	call suma_a_hl		;573d
	ld e,(hl)			;5740   ; el primer byte...
	ld d,000h		;5741
	inc hl			;5743
	ex de,hl			;5744
	add hl,hl			;5745   ; ...doblado, porque la velocidad se lleva en medios pixeles
	ld (0e06eh),hl		;5746   ; a (0xE06E)
	ex de,hl			;5749
	ld e,(hl)			;574a   ; y el segundo byte igual, a (0xE070)
	ld d,000h		;574b
	ex de,hl			;574d
	add hl,hl			;574e
	ld (0e070h),hl		;574f

; ----------------------------------------------------------------------
; ----- y a pintar -----
; ----------------------------------------------------------------------
	call coloca_a_los_seis		;5752
	call coloca_a_los_seis_defensas		;5755
	ld a,0ffh		;5758   ; (0xE53C) = 0xFF, otro "todavia ninguno"
	ld (0e53ch),a		;575a
	call L_6F31		;575d
	call L_742D		;5760
	call L_76BC		;5763
	call L_8538		;5766
	call pinta_los_nombres_de_los_equipos		;5769
	call pinta_el_marcador		;576c
	call pinta_el_reloj		;576f
	ld a,0e0h		;5772   ; los dos sprites del final de la lista, fuera de la pantalla visible
	ld (0e398h),a		;5774
	ld (0e39ch),a		;5777
	ld a,007h		;577a   ; con sus colores, 7 y 9
	ld (0e39bh),a		;577c
	ld a,009h		;577f
	ld (0e39fh),a		;5781
	call pasa_la_pelota_a_pantalla		;5784
	call pon_la_pelota_en_sus_sprites		;5787
L_578A:
	call pasa_los_doce_a_la_ventana		;578a
	call guarda_el_fondo_del_bando		;578d
	call estampa_el_bando_en_el_mapa		;5790
	call pon_el_bando_en_sprites		;5793
L_5796:
	call vuelca_el_campo		;5796   ; el primer volcado del campo ya montado
	call copia_los_sprites		;5799   ; y los sprites detras
	jp devuelve_el_fondo_al_mapa		;579c   ; y de aqui ya no se vuelve: entra en el bucle del partido

; ----------------------------------------------------------------------
; DATOS tablas_del_saque: cinco tablas: 0x579F y 0x57C3 son doce jugadores por
;   tres bytes, una por bando segun (0xE0F7), que 0x5691 reparte en las fichas
;   de 0xE104; 0x57E7 y 0x57EC son los cinco bytes de cada portero; y 0x57EF y
;   0x57F9 cinco parejas indexadas por el nivel, con la base una entrada mas
;   abajo
;   0x579f..0x5805  (102 bytes)
DATA_tablas_del_saque:
	defb 018h	; 579f
	defb 050h	; 57a0
	defb 001h	; 57a1
	defb 040h	; 57a2
	defb 044h	; 57a3
	defb 001h	; 57a4
	defb 098h	; 57a5
	defb 050h	; 57a6
	defb 001h	; 57a7
	defb 030h	; 57a8
	defb 0a0h	; 57a9
	defb 001h	; 57aa
	defb 058h	; 57ab
	defb 040h	; 57ac
	defb 001h	; 57ad
	defb 090h	; 57ae
	defb 0a0h	; 57af
	defb 001h	; 57b0
	defb 020h	; 57b1
	defb 0e0h	; 57b2
	defb 000h	; 57b3
	defb 040h	; 57b4
	defb 0d0h	; 57b5
	defb 000h	; 57b6
	defb 098h	; 57b7
	defb 0e0h	; 57b8
	defb 000h	; 57b9
	defb 018h	; 57ba
	defb 028h	; 57bb
	defb 001h	; 57bc
	defb 068h	; 57bd
	defb 010h	; 57be
	defb 001h	; 57bf
	defb 098h	; 57c0
	defb 028h	; 57c1
	defb 001h	; 57c2
	defb 018h	; 57c3
	defb 058h	; 57c4
	defb 001h	; 57c5
	defb 068h	; 57c6
	defb 060h	; 57c7
	defb 001h	; 57c8
	defb 098h	; 57c9
	defb 058h	; 57ca
	defb 001h	; 57cb
	defb 020h	; 57cc
	defb 0b0h	; 57cd
	defb 001h	; 57ce
	defb 040h	; 57cf
	defb 0a0h	; 57d0
	defb 001h	; 57d1
	defb 098h	; 57d2
	defb 0b0h	; 57d3
	defb 001h	; 57d4
	defb 018h	; 57d5
	defb 0e0h	; 57d6
	defb 000h	; 57d7
	defb 058h	; 57d8
	defb 034h	; 57d9
	defb 001h	; 57da
	defb 090h	; 57db
	defb 0e0h	; 57dc
	defb 000h	; 57dd
	defb 018h	; 57de
	defb 020h	; 57df
	defb 001h	; 57e0
	defb 040h	; 57e1
	defb 030h	; 57e2
	defb 001h	; 57e3
	defb 098h	; 57e4
	defb 020h	; 57e5
	defb 001h	; 57e6
	defb 001h	; 57e7
	defb 058h	; 57e8
	defb 000h	; 57e9
	defb 048h	; 57ea
	defb 002h	; 57eb
	defb 002h	; 57ec
	defb 058h	; 57ed
	defb 000h	; 57ee
	defb 030h	; 57ef
	defb 000h	; 57f0
	defb 070h	; 57f1
	defb 098h	; 57f2
	defb 078h	; 57f3
	defb 0a0h	; 57f4
	defb 080h	; 57f5
	defb 0a8h	; 57f6
	defb 088h	; 57f7
	defb 0b0h	; 57f8
	defb 090h	; 57f9
	defb 0b8h	; 57fa
	defb 060h	; 57fb
	defb 088h	; 57fc
	defb 070h	; 57fd
	defb 098h	; 57fe
	defb 080h	; 57ff
	defb 0a8h	; 5800
	defb 090h	; 5801
	defb 0b8h	; 5802
	defb 0a0h	; 5803
	defb 0c8h	; 5804

; ======================================================================
; CODIGO 0x5805..0x590d  (264 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== UN CUADRO DEL PARTIDO =====
; ----------------------------------------------------------------------
un_cuadro_del_partido:		; la lista de todo lo que pasa en un fotograma, en el orden en que pasa
	call sube_los_sprites		;5805   ; lo primero, los sprites del cuadro anterior a la VRAM: asi el volcado cae dentro del retrazo
	ld hl,0e53ch		;5808   ; (0xE53C) es una cuenta atras...
	ld a,(hl)			;580b
	and a			;580c   ; ...y solo baja mientras no haya llegado a cero: no da la vuelta
	jr z,L_5810		;580d
	dec (hl)			;580f
L_5810:
	ld hl,0e544h		;5810   ; (0xE544) es la otra cuenta atras, misma cautela
	ld a,(hl)			;5813
	and a			;5814
	jr z,L_5818		;5815
	dec (hl)			;5817
L_5818:
	call L_B6F2		;5818   ; el arbitro y las reglas
	call L_B72A		;581b
	ld a,(0e280h)		;581e   ; (0xE280) es el subestado del partido...
	dec a			;5821   ; ...y el 1 es el unico que conserva (0xE551)
	jr z,L_5828		;5822
	xor a			;5824   ; en cualquier otro, se borra
	ld (0e551h),a		;5825

; ----------------------------------------------------------------------
; ----- la logica, en su orden -----
; ----------------------------------------------------------------------
L_5828:
	call cuenta_atras_del_saque		;5828   ; de aqui abajo va todo el cuadro, y el ORDEN importa: cada rutina cuenta con lo que dejo la anterior
	call en_que_zona_esta_la_pelota		;582b
	call cambia_de_jugador_con_el_boton		;582e
	call apunta_quien_ocupa_cada_puesto		;5831
	call la_maquina_elige_companero		;5834
	call elige_el_destacado_de_la_izquierda		;5837
	call avisa_del_cambio_de_jugador		;583a
	call L_B5C9		;583d
	call un_cuadro_de_la_tactica		;5840
	call la_logica_de_los_dos_porteros		;5843
	call L_B511		;5846
	call apunta_al_companero		;5849
	ld a,(0e532h)		;584c   ; (0xE532) distingue el juego en marcha de las pausas
	and a			;584f
	jr nz,L_5855		;5850
	call arranca_el_cuadro_de_la_pelota		;5852   ; y solo con el a cero corre esta
L_5855:
	ld a,(0e280h)		;5855   ; otra vez el subestado
	dec a			;5858
	jr z,L_5861		;5859
	ld a,(0e540h)		;585b   ; (0xE540) bit 0: con el puesto, la de 0x8C80 se hace una vez mas
	rra			;585e
	jr nc,L_5864		;585f
L_5861:
	call un_cuadro_de_la_pelota		;5861   ; la tercera pasada, la del caso especial
L_5864:
	call un_cuadro_de_la_pelota		;5864   ; y dos pasadas fijas, que son las que se hacen siempre
	call un_cuadro_de_la_pelota		;5867

; ----------------------------------------------------------------------
; ----- y ahora a dibujar -----
; ----------------------------------------------------------------------
	call elige_al_companero		;586a
	call pon_la_sombra_de_la_pelota		;586d
	call mueve_a_los_porteros		;5870
	call estampa_a_los_porteros		;5873
	call mira_si_alguien_toca_la_pelota		;5876
	call el_portero_va_a_por_la_pelota		;5879
	call L_9E88		;587c
	call pasa_los_doce_a_la_ventana		;587f
	call guarda_el_fondo_del_bando		;5882
	call estampa_el_bando_en_el_mapa		;5885
	call pon_el_bando_en_sprites		;5888
	ld a,(0e5c7h)		;588b   ; (0xE5C7) tapa el volcado del campo cuando hay algo mas urgente en la VRAM
	and a			;588e
	call z,vuelca_el_campo		;588f   ; el campo solo se vuelca si no lo tapan
	call devuelve_el_fondo_al_mapa		;5892
	jp corre_el_reloj		;5895   ; y sale por el reparto de subestados, no por un `ret`

; ----------------------------------------------------------------------
; ===== EL PITIDO AL CAMBIAR DE JUGADOR =====
; ----------------------------------------------------------------------
avisa_del_cambio_de_jugador:		; pita cuando el jugador que llevas deja de ser el que era
	ld a,(0e280h)		;5898   ; el subestado del partido...
	cp 002h		;589b   ; ...y solo se avisa en los dos primeros, o sea con el juego vivo
	ret nc			;589d
	ld a,(0e012h)		;589e   ; (0xE012) es el sonido que esta sonando ahora mismo
	cp 049h		;58a1   ; si ya esta sonando este mismo pitido, no se pide otra vez
	ret z			;58a3
	ld a,(0e52ch)		;58a4   ; el jugador destacado del primer mando
	call pita_si_cambio		;58a7   ; y si ese ya ha dado el aviso, se acabo
	ret nz			;58aa
	ld a,(0e002h)		;58ab   ; el bit 5 de (0xE002) es el que dice si hay un segundo jugador
	and 020h		;58ae
	ret z			;58b0   ; sin el, no hay segundo mando que mirar
	ld a,(0e52dh)		;58b1   ; y el destacado del segundo mando pasa por lo mismo
pita_si_cambio:		; compara el jugador que se le pasa con el que llevaba la pelota
	ld c,a			;58b4   ; el jugador a comprobar, a salvo en C
	ld a,(0e528h)		;58b5   ; (0xE528) es quien llevaba la pelota
	cp c			;58b8   ; si es el mismo, no ha cambiado nada
	ret z			;58b9
	ld a,c			;58ba
	call L_A201		;58bb   ; IX a la ficha del jugador, que son 32 bytes desde 0xE100
	ld a,(ix+003h)		;58be   ; el +3 de la ficha
	and a			;58c1
	ret z			;58c2   ; a cero no se pita
	ld a,049h		;58c3   ; el 0x49 es el pitido del cambio
	call pide_un_sonido		;58c5
	or 0ffh		;58c8   ; vuelve con NZ, que es el "ya avisado" que mira quien llama
	ret			;58ca

; ----------------------------------------------------------------------
; ===== LA DEMOSTRACION =====
; ----------------------------------------------------------------------
arranca_la_demostracion:		; prepara la partida que el cartucho juega solo en el menu
	ld a,001h		;58cb   ; (0xE0F1) a uno: la senal de que esto es demostracion y no partida
	ld (0e0f1h),a		;58cd
	ld de,0e053h		;58d0   ; las tres entradas altas de la paleta de camiseta del primer equipo
	ld hl,0591eh		;58d3
	ld bc,00003h		;58d6
	ldir		;58d9
	ld de,0e058h		;58db   ; y las del segundo, que el `ldir` dejo HL ya en los tres siguientes
	ld c,003h		;58de
	ldir		;58e0
	ld hl,0e00bh		;58e2   ; (0xE00B) cuenta las veces que se ha entrado
	inc (hl)			;58e5
	ld a,(hl)			;58e6
	rra			;58e7   ; el bit 0 a la bandera: una de cada dos veces se monta el partido...
	jr nc,$+40		;58e8   ; ...y la otra se sale sin montar nada, para que la demostracion alterne
	xor a			;58ea
	ld (0e0f7h),a		;58eb   ; el bando que saca, siempre el mismo en la demostracion
	ld (0e002h),a		;58ee   ; y (0xE002) y (0xE003) a cero: ni segundo jugador ni cuadros contados
	ld (0e003h),a		;58f1
	inc a			;58f4
	ld (0e0f2h),a		;58f5   ; (0xE0F2) a uno
	ld (0e069h),a		;58f8   ; y el nivel a uno, el mas facil: lo que se ve es una exhibicion, no un reto
	call carga_los_graficos_del_campo		;58fb   ; las diez tandas de graficos del campo
	call monta_el_partido		;58fe   ; y el mismo montaje del partido que usa la partida de verdad
	ld bc,00003h		;5901   ; los tres bytes de arranque de 0x590D
	ld de,0e588h		;5904
	ld hl,0590dh		;5907
	ldir		;590a
	ret			;590c

; ----------------------------------------------------------------------
; DATOS arranque_de_la_demostracion: tres bytes que 0x5907 copia a 0xE588:
;   contador a uno, mando a cero e indice a cero
;   0x590d..0x5910  (3 bytes)
DATA_arranque_de_la_demostracion:
	defb 001h	; 590d
	defb 000h	; 590e
	defb 000h	; 590f

; ======================================================================
; CODIGO 0x5910..0x591e  (14 bytes)
; ======================================================================


borra_las_banderas_del_partido:		; deja a cero las cuatro que sobreviven de una partida a la siguiente
	xor a			;5910
	ld (0e0fbh),a		;5911   ; (0xE0FB) y (0xE0FC)
	ld (0e0fch),a		;5914
	ld (0e0f0h),a		;5917   ; (0xE0F0), o sea el motivo de parada: ni gol ni fin de tiempo
	ld (0e00ch),a		;591a   ; y (0xE00C)
	ret			;591d

; ----------------------------------------------------------------------
; DATOS paletas_de_equipo_por_defecto: dos tandas de tres bytes que 0x58D3
;   copia a 0xE053 y 0xE058, o sea las entradas 3, 4 y 5 de las dos paletas de
;   camiseta. Coinciden con las opciones 0 y 3 de la tabla de 0x5C20
;   0x591e..0x5924  (6 bytes)
DATA_paletas_de_equipo_por_defecto:
	defb 001h	; 591e
	defb 00bh	; 591f
	defb 006h	; 5920
	defb 006h	; 5921
	defb 00bh	; 5922
	defb 004h	; 5923

; ======================================================================
; CODIGO 0x5924..0x5990  (108 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LA DEMOSTRACION =====
; ----------------------------------------------------------------------
un_cuadro_de_la_demostracion:		; alterna partido y penaltis segun el bit 0 de (0xE00B)
	ld a,(0e00bh)		;5924   ; (0xE00B) lo llevo subiendo el arranque de la demostracion
	rra			;5927   ; y su bit 0 es el que alterna: una vez partido, la otra penaltis
	jr nc,L_5935		;5928
	call un_cuadro_del_partido		;592a   ; el mismo cuadro de partido que juega el humano, sin descuento
	ld a,(0e0f0h)		;592d   ; (0xE0F0) trae el motivo de parada...
	and 003h		;5930   ; ...y los dos bits bajos son los goles
	ret z			;5932   ; sin gol, la demostracion sigue
	jr cierra_la_demostracion		;5933   ; con gol, se corta: ya ha ensenado lo que tenia que ensenar

; ----------------------------------------------------------------------
; ----- la otra mitad: los penaltis -----
; ----------------------------------------------------------------------
L_5935:
	ld a,(0e00ch)		;5935   ; el bit 0 de (0xE00C) dice si el decorado ya esta montado
	rra			;5938
	jr c,L_5947		;5939
	call monta_la_pantalla_de_penaltis		;593b   ; y si no lo esta, se monta
	ld a,040h		;593e   ; (0xE312) = 0x40 de salida
	ld (0e312h),a		;5940
	ld hl,0e00ch		;5943   ; y queda marcado, para no volver a montarlo
	inc (hl)			;5946
L_5947:
	call un_cuadro_de_los_penaltis		;5947
	call pinta_los_penaltis		;594a   ; el dibujo de la tanda
	ld a,(0e0f8h)		;594d   ; (0xE0F8) distinto de cero: hay algo en marcha y no toca contar
	and a			;5950
	ret nz			;5951
	ld a,(0e0fch)		;5952   ; (0xE0FC) se conmuta entre 0 y 1 en cada pasada
	cpl			;5955
	and 001h		;5956
	ld (0e0fch),a		;5958
	ld hl,0e00ch		;595b   ; y (0xE00C) sube
	inc (hl)			;595e
	ld a,(hl)			;595f
	cp 006h		;5960   ; a los seis penaltis se acaba
	ret nz			;5962   ; antes de los seis, se vuelve a por otro
	jr cierra_la_demostracion		;5963

; ----------------------------------------------------------------------
; ===== EL GUION: una partida grabada -----
; ----------------------------------------------------------------------
mueve_el_guion_de_la_demostracion:		; saca del guion el mando de mentira que juega la partida grabada
	ld hl,0e588h		;5965   ; (0xE588) es lo que le queda al movimiento de turno
	dec (hl)			;5968   ; un cuadro menos
	inc hl			;5969
	ld a,(hl)			;596a   ; (0xE589) es el mando que se esta repitiendo
	jr nz,L_5985		;596b   ; mientras queden cuadros, se repite el mismo: por eso el guion es tan corto
	inc hl			;596d   ; (0xE58A) es el indice dentro del guion...
	inc (hl)			;596e   ; ...y avanza a la entrada siguiente
	ld a,(hl)			;596f
	ex de,hl			;5970
	ld l,a			;5971
	ld h,000h		;5972   ; dos bytes por entrada
	add hl,hl			;5974
	ld bc,0598eh		;5975   ; la base es 0x598E, o sea el guion menos una entrada, porque el indice empieza en 1
	add hl,bc			;5978
	ld c,(hl)			;5979   ; el primer byte: los cuadros que dura
	inc c			;597a   ; el 0xFF de cierre se caza sumandole uno
	jr z,cierra_la_demostracion		;597b   ; y ahi se acaba la demostracion
	dec c			;597d
	inc hl			;597e
	ld a,(hl)			;597f   ; el segundo byte: el mando
	ex de,hl			;5980
	dec hl			;5981
	ld (hl),a			;5982   ; a (0xE589)
	dec hl			;5983
	ld (hl),c			;5984   ; y los cuadros a (0xE588)
L_5985:
	ld hl,0e007h		;5985   ; (0xE007) es donde el juego espera encontrar el mando...
	jp guarda_y_marca_lo_recien_pulsado		;5988   ; ...y entra por la misma puerta que el mando de verdad: al partido no le consta la diferencia
cierra_la_demostracion:
	xor a			;598b
	ld (0e0f1h),a		;598c   ; (0xE0F1) a cero: se acabo la exhibicion
	ret			;598f

; ----------------------------------------------------------------------
; DATOS guion_de_la_demostracion: 23 parejas de [cuadros, mando] y un 0xFF de
;   cierre; lo recorre 0x5975 con la base en 0x598E, o sea una entrada mas
;   abajo. 23 por 2 mas 1 son los 47 bytes justos
;   0x5990..0x59bf  (47 bytes)
DATA_guion_de_la_demostracion:
	defw 00014h,01010h,0000bh,00428h,00217h,01201h,01001h,0001dh	; 5990
	defw 00807h,00001h,00114h,0050dh,00130h,00520h,00414h,00520h	; 59a0
	defw 00420h,01402h,00402h,00008h,00612h,01620h,00620h	; 59b0
	defb 0ffh	; 59be

; ======================================================================
; CODIGO 0x59bf..0x5a5e  (159 bytes)
; ======================================================================


monta_la_pantalla_de_opciones:
	call aparca_los_sprites		;59bf   ; los sprites fuera de en medio antes de tocar la VRAM
	call carga_la_fuente		;59c2   ; la fuente, que esta pantalla es casi toda texto
	call L_713B		;59c5
	call L_755D		;59c8
	jp L_7C86		;59cb
escribe_los_rotulos_de_opciones:
	ld de,049abh		;59ce
	call escribe_un_rotulo		;59d1   ; el primer rotulo, el que sale siempre
	ld a,(0e002h)		;59d4   ; el bit 5 de (0xE002) dice si hay dos jugadores...
	bit 5,a		;59d7
	jr z,L_59E1		;59d9   ; ...y sin el, el segundo rotulo no se escribe
	ld de,04a22h		;59db
	call escribe_un_rotulo		;59de
L_59E1:
	ld de,07195h		;59e1
	call descomprime_con_destino_dentro		;59e4   ; el bloque de 0x7195 se lleva su propio destino en los dos primeros bytes
	call L_5DBE		;59e7
	ld de,0e390h		;59ea   ; los 36 bytes de atributos de sprite de 0x5A86
	ld hl,05a86h		;59ed
	ld bc,00024h		;59f0
	ldir		;59f3
	jp rotula_el_segundo_marcador		;59f5   ; y a montar los marcadores del menu
un_cuadro_de_las_opciones:
	call sube_los_sprites		;59f8   ; los sprites del cuadro anterior, primero
	call un_cuadro_del_menu		;59fb
	call pon_los_cursores_de_color		;59fe
	call pon_el_cursor_del_nivel		;5a01
	call pon_el_cursor_del_tiempo		;5a04
	ld a,(0e076h)		;5a07   ; (0xE076) es la duracion de parte elegida: 0, 1 o 2
	cp 002h		;5a0a   ; con la tercera opcion el marcador va aparte
	jr nc,L_5A27		;5a0c
	and a			;5a0e   ; con la primera...
	ld bc,0108fh		;5a0f
	jr z,L_5A17		;5a12   ; ...estos dos bytes, y con la segunda los otros
	ld bc,010afh		;5a14
L_5A17:
	ld a,b			;5a17   ; la altura, a los dos sprites del par
	ld (0e3a6h),a		;5a18
	ld (0e3aah),a		;5a1b
	ld a,c			;5a1e   ; y el ancho, a los otros dos
	ld (0e3a5h),a		;5a1f
	ld (0e3a9h),a		;5a22
	jr L_5A31		;5a25
L_5A27:
	ld a,014h		;5a27   ; la tercera opcion lleva altura fija en los dos, sin ancho que tocar
	ld (0e3a6h),a		;5a29
	ld a,018h		;5a2c
	ld (0e3aah),a		;5a2e
L_5A31:
	call pon_el_cursor_del_nombre_1		;5a31
	jp pon_el_cursor_del_nombre_2		;5a34
marca_partida_empezada:
	ld a,001h		;5a37
	ld (0e00dh),a		;5a39   ; (0xE00D) a uno
	call aplica_los_colores_de_camiseta		;5a3c
	jp alinea_los_nombres		;5a3f

; ----------------------------------------------------------------------
; ===== LO QUE TRAE EL CARTUCHO DE FABRICA =====
; ----------------------------------------------------------------------
pon_el_estado_de_fabrica:		; deja en 0xE050 las paletas, los nombres EAGLES y STONES y el nivel de salida
	ld de,0e050h		;5a42   ; el estado de la partida vive de 0xE050 en adelante
	ld hl,05a5eh		;5a45
	ld bc,00027h		;5a48   ; los 39 bytes de 0x5A5E: dos paletas de cinco, los dos nombres y las velocidades
	ldir		;5a4b
	xor a			;5a4d
	ld (0e07fh),a		;5a4e   ; (0xE07F) y (0xE080) a cero
	ld (0e080h),a		;5a51
	inc a			;5a54
	ld (0e0a0h),a		;5a55   ; el nivel del primer jugador, el 1
	add a,002h		;5a58   ; y el del segundo, el 3: la maquina sale un punto mas dura que tu
	ld (0e0a1h),a		;5a5a
	ret			;5a5d

; ----------------------------------------------------------------------
; DATOS estado_inicial_de_la_partida: los 39 bytes que 0x5A45 copia a 0xE050:
;   las dos paletas de cinco, los nombres de fabrica "EAGLES" y "STONES", el
;   nivel 1 y las velocidades de 16 bits
;   0x5a5e..0x5a85  (39 bytes)
DATA_estado_inicial_de_la_partida:
	defb 000h	; 5a5e
	defb 00ch	; 5a5f
	defb 001h	; 5a60
	defb 006h	; 5a61
	defb 00bh	; 5a62
	defb 001h	; 5a63
	defb 00ch	; 5a64
	defb 001h	; 5a65
	defb 001h	; 5a66
	defb 006h	; 5a67
	defb 00fh	; 5a68
	defb 025h	; 5a69
	defb 021h	; 5a6a
	defb 027h	; 5a6b
	defb 02ch	; 5a6c
	defb 025h	; 5a6d
	defb 033h	; 5a6e
	defb 0ffh	; 5a6f
	defb 033h	; 5a70
	defb 034h	; 5a71
	defb 02fh	; 5a72
	defb 02eh	; 5a73
	defb 025h	; 5a74
	defb 033h	; 5a75
	defb 0ffh	; 5a76
	defb 001h	; 5a77
	defb 080h	; 5a78
	defb 000h	; 5a79
	defb 0c0h	; 5a7a
	defb 000h	; 5a7b
	defb 080h	; 5a7c
	defb 000h	; 5a7d
	defb 0c0h	; 5a7e
	defb 000h	; 5a7f
	defb 000h	; 5a80
	defb 003h	; 5a81
	defb 000h	; 5a82
	defb 003h	; 5a83
	defb 000h	; 5a84

; ----------------------------------------------------------------------
; DATOS byte_que_nadie_copia: un byte suelto entre el estado inicial y los
;   sprites; el `ldir` de 0x5A45 cuenta 39 y se para antes de el
;   0x5a85..0x5a86  (1 bytes)
DATA_byte_que_nadie_copia:
	defb 000h	; 5a85

; ----------------------------------------------------------------------
; DATOS sprites_del_menu: nueve sprites de cuatro bytes que 0x59ED copia a
;   0xE390
;   0x5a86..0x5aaa  (36 bytes)
DATA_sprites_del_menu:
	defb 00fh	; 5a86
	defb 010h	; 5a87
	defb 000h	; 5a88
	defb 00eh	; 5a89
	defb 00fh	; 5a8a
	defb 010h	; 5a8b
	defb 004h	; 5a8c
	defb 001h	; 5a8d
	defb 0e0h	; 5a8e
	defb 000h	; 5a8f
	defb 008h	; 5a90
	defb 00fh	; 5a91
	defb 0e0h	; 5a92
	defb 000h	; 5a93
	defb 00ch	; 5a94
	defb 00fh	; 5a95
	defb 05dh	; 5a96
	defb 08fh	; 5a97
	defb 010h	; 5a98
	defb 006h	; 5a99
	defb 075h	; 5a9a
	defb 087h	; 5a9b
	defb 014h	; 5a9c
	defb 006h	; 5a9d
	defb 075h	; 5a9e
	defb 097h	; 5a9f
	defb 018h	; 5aa0
	defb 006h	; 5aa1
	defb 09eh	; 5aa2
	defb 050h	; 5aa3
	defb 01ch	; 5aa4
	defb 006h	; 5aa5
	defb 09eh	; 5aa6
	defb 0c8h	; 5aa7
	defb 01ch	; 5aa8
	defb 006h	; 5aa9

; ======================================================================
; CODIGO 0x5aaa..0x5ac3  (25 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL MENU DE OPCIONES =====
; ----------------------------------------------------------------------
un_cuadro_del_menu:		; mueve el cursor y despacha al paso en el que este
	ld a,03fh		;5aaa
	ld (0e398h),a		;5aac   ; los dos sprites del cursor a la altura 0x3F de salida
	ld a,03fh		;5aaf
	ld (0e39ch),a		;5ab1
	call sube_o_baja_el_cursor		;5ab4   ; primero se mira si el cursor cambia de fila
	push af			;5ab7   ; y la respuesta se guarda, que la de dibujar el cursor pisa las banderas
	call pon_el_cursor_del_menu		;5ab8   ; el cursor a su sitio
	pop af			;5abb
	ret c			;5abc   ; si el paso ha cambiado en este cuadro, no se toca lo de dentro: un cambio por cuadro
	ld a,(0e050h)		;5abd   ; (0xE050) es el paso del menu, de 0 a 3
	call despacha		;5ac0   ; y cada paso tiene su rutina en la tabla que va pegada aqui detras

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_5ac3: 4 entradas; detras NO sigue ninguna de
;   ellas, sino `ld a,(0e006h) / ld hl,0e008h / or (hl)`
;   0x5ac3..0x5acb  (8 bytes)
DATA_tabla_de_subescenas_5ac3:
	defw 05b56h,05c38h,05c8ch,05cedh	; 5ac3  -> elige_las_camisetas elige_el_nivel mueve_el_cursor_del_tiempo edita_los_nombres_de_equipo

; ======================================================================
; CODIGO 0x5acb..0x5b06  (59 bytes)
; ======================================================================


sube_o_baja_el_cursor:		; entre los cuatro pasos, sin dar la vuelta
	ld a,(0e006h)		;5acb   ; lo RECIEN pulsado en el mando 1 -(0xE007) es lo mantenido y (0xE006) el flanco-...
	ld hl,0e008h		;5ace   ; ...y lo del 2, juntos: el menu lo maneja cualquiera de los dos
	or (hl)			;5ad1
	and 003h		;5ad2   ; los bits 0 y 1: arriba y abajo
	ret pe			;5ad4   ; paridad par, o sea ninguno o los dos a la vez: no se hace nada
	ld c,a			;5ad5
	ld hl,0e050h		;5ad6   ; (0xE050), el paso de ahora
	rra			;5ad9   ; el bit 0 al acarreo
	jr c,L_5ADE		;5ada
	jr L_5AE9		;5adc
L_5ADE:
	dec (hl)			;5ade   ; arriba: el truco de bajar y subir para poner la bandera sin cambiar nada
	inc (hl)			;5adf
	ret z			;5ae0   ; ya esta en el primero, no hay adonde subir
	ld a,001h		;5ae1
	dec (hl)			;5ae3   ; y ahora si, uno menos
	call pide_un_sonido		;5ae4   ; el 1 es el clic del menu
	xor a			;5ae7   ; vuelve sin acarreo: el paso NO ha cambiado de sitio
	ret			;5ae8
L_5AE9:
	ld a,(hl)			;5ae9
	cp 003h		;5aea   ; el 3 es el ultimo paso
	ret z			;5aec   ; ya esta abajo del todo
	inc (hl)			;5aed
	ld a,001h		;5aee
	call pide_un_sonido		;5af0
	scf			;5af3   ; vuelve con acarreo: ha habido cambio
	ret			;5af4
pon_el_cursor_del_menu:
	ld a,(0e050h)		;5af5
	ld hl,05b06h		;5af8   ; las cuatro alturas de 0x5B06
	call suma_a_hl		;5afb
	ld a,(hl)			;5afe
	ld (0e390h),a		;5aff   ; el mismo valor a los dos sprites que forman el cursor
	ld (0e394h),a		;5b02
	ret			;5b05

; ----------------------------------------------------------------------
; DATOS alturas_del_cursor_del_menu: las cuatro Y del cursor -0x0F, 0x5F,
;   0x77, 0x8F-, indexadas por el paso del menu en (0xE050); van a los sprites
;   0 y 1
;   0x5b06..0x5b0a  (4 bytes)
DATA_alturas_del_cursor_del_menu:
	defb 00fh	; 5b06
	defb 05fh	; 5b07
	defb 077h	; 5b08
	defb 08fh	; 5b09

; ======================================================================
; CODIGO 0x5b0a..0x5b4f  (69 bytes)
; ======================================================================


rotula_el_segundo_marcador:		; pone "2UP-" o esconde el sprite, segun haya uno o dos jugadores
	ld a,(0e002h)		;5b0a
	bit 5,a		;5b0d   ; el bit 5 de (0xE002): dos jugadores
	jr z,L_5B21		;5b0f   ; sin el, no hay nada que rotular
	ld a,00ch		;5b11
	ld (0e39eh),a		;5b13   ; (0xE39E) = 0x0C: el sprite baja a la vista
	ld a,006h		;5b16
	ld (0e3b3h),a		;5b18   ; (0xE3B3) = 6
	ld de,05b4fh		;5b1b   ; y el guion de "2UP-", que sustituye al "CPU-" de una maquina
	jp escribe_un_rotulo		;5b1e
L_5B21:
	ld a,020h		;5b21   ; con un solo jugador...
	ld (0e39eh),a		;5b23   ; ...la altura 0x20 aparca el sprite fuera
	ret			;5b26

; ----------------------------------------------------------------------
; ===== LOS DOS NOMBRES, CADA UNO A SU LADO =====
; ----------------------------------------------------------------------
alinea_los_nombres:		; pega el nombre de la izquierda a la izquierda y el de la derecha a la derecha
	ld b,005h		;5b27   ; cinco pasadas: seis letras dan como mucho cinco huecos que correr
L_5B29:
	push bc			;5b29
	ld bc,00005h		;5b2a   ; los cinco bytes que se arrastran
	ld de,0e05bh		;5b2d   ; el primer byte del nombre de la izquierda
	ld a,(de)			;5b30
	and a			;5b31   ; si no es hueco, ya esta pegado
	jr nz,L_5B3B		;5b32
	ld hl,0e05ch		;5b34   ; y si lo es, todo el nombre corre una letra a la izquierda
	ldir		;5b37
	xor a			;5b39   ; el hueco que deja atras, a cero
	ld (de),a			;5b3a
L_5B3B:
	ld de,0e067h		;5b3b   ; el ultimo byte del nombre de la derecha
	ld a,(de)			;5b3e
	and a			;5b3f   ; si no es hueco, ya esta pegado
	jr nz,L_5B4B		;5b40
	ld hl,0e066h		;5b42   ; y si lo es, se corre a la derecha, que por eso este va con `lddr`
	ld c,005h		;5b45
	lddr		;5b47
	xor a			;5b49
	ld (de),a			;5b4a
L_5B4B:
	pop bc			;5b4b
	djnz L_5B29		;5b4c   ; hasta las cinco
	ret			;5b4e

; ----------------------------------------------------------------------
; DATOS rotulo_2up: el guion de "2UP-" en 0x3A91, que 0x5B1B pone en lugar de
;   "CPU-" cuando el bit 5 de (0xE002) dice dos jugadores
;   0x5b4f..0x5b56  (7 bytes)
DATA_rotulo_2up:
	defb 091h	; 5b4f
	defb 03ah	; 5b50
	defb 012h	; 5b51
	defb 035h	; 5b52
	defb 030h	; 5b53
	defb 020h	; 5b54
	defb 0ffh	; 5b55

; ======================================================================
; CODIGO 0x5b56..0x5c20  (202 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LOS COLORES DE CAMISETA =====
; ----------------------------------------------------------------------
elige_las_camisetas:		; cada mando cambia su color, y los dos no pueden coincidir
	ld bc,(0e074h)		;5b56   ; C es el color de un equipo y B el del otro
	ld a,(0e006h)		;5b5a   ; lo recien pulsado en el mando 1, que es el flanco y no lo mantenido
	ld d,a			;5b5d   ; a salvo, que la comprobacion pisa A
	bit 2,a		;5b5e   ; izquierda...
	call nz,baja_el_color_1		;5b60
	ld a,d			;5b63
	bit 3,a		;5b64   ; ...y derecha
	call nz,sube_el_color_1		;5b66
	ld (0e074h),bc		;5b69   ; se guardan los dos, que el cruce ha podido mover tambien el ajeno
	ld a,(0e008h)		;5b6d   ; y ahora el mando 2, sobre los mismos dos bytes
	ld d,a			;5b70
	bit 2,a		;5b71
	call nz,baja_el_color_2		;5b73
	ld a,d			;5b76
	bit 3,a		;5b77
	call nz,sube_el_color_2		;5b79
	ld (0e074h),bc		;5b7c
	call pon_los_cursores_de_color		;5b80   ; los sprites de muestra al color nuevo
	jp aplica_los_colores_de_camiseta		;5b83
baja_el_color_1:
	ld a,002h		;5b86
	call pide_un_sonido		;5b88   ; el 2 es el clic de cambiar valor
	dec c			;5b8b   ; un color menos
	ld a,c			;5b8c
	cp 0ffh		;5b8d   ; por debajo de cero...
	jr nz,L_5B93		;5b8f
	ld c,007h		;5b91   ; ...se da la vuelta al 7: son ocho colores
L_5B93:
	ld a,b			;5b93
	cp c			;5b94   ; y si ha ido a caer justo en el del otro equipo...
	jr nz,L_5B98		;5b95
	dec b			;5b97   ; ...es al OTRO al que se aparta, no a este: el que pulsa manda
L_5B98:
	ld a,0ffh		;5b98
	cp b			;5b9a   ; y si al apartarlo se ha salido por abajo
	ret nz			;5b9b
	ld b,007h		;5b9c   ; tambien da la vuelta
	ret			;5b9e
sube_el_color_1:
	ld a,002h		;5b9f
	call pide_un_sonido		;5ba1
	inc c			;5ba4   ; un color mas
	ld a,c			;5ba5
	cp 008h		;5ba6   ; pasado el ultimo...
	jr nz,L_5BAC		;5ba8
	ld c,000h		;5baa   ; ...vuelve al primero
L_5BAC:
	ld a,b			;5bac
	cp c			;5bad   ; misma cortesia: si choca con el del otro equipo
	jr nz,L_5BB1		;5bae
	inc b			;5bb0   ; se aparta el ajeno
L_5BB1:
	ld a,008h		;5bb1
	cp b			;5bb3   ; y si ese se sale por arriba
	ret nz			;5bb4
	ld b,000h		;5bb5   ; da la vuelta el tambien
	ret			;5bb7
baja_el_color_2:
	ld a,002h		;5bb8
	call pide_un_sonido		;5bba
	dec b			;5bbd   ; aqui el que se mueve es B, que es el otro equipo
	ld a,b			;5bbe
	cp 0ffh		;5bbf
	jr nz,L_5BC5		;5bc1
	ld b,007h		;5bc3
L_5BC5:
	ld a,b			;5bc5
	cp c			;5bc6   ; y el apartado seria C
	jr nz,L_5BCA		;5bc7
	dec b			;5bc9
L_5BCA:
	ld a,b			;5bca
	cp 0ffh		;5bcb
	ret nz			;5bcd
	ld b,007h		;5bce
	ret			;5bd0
sube_el_color_2:
	ld a,002h		;5bd1
	call pide_un_sonido		;5bd3
	inc b			;5bd6
	ld a,c			;5bd7
	cp 008h		;5bd8   ; el que se comprueba aqui es C, no B: la unica de las cuatro que mira el ajeno para dar la vuelta
	jr nz,L_5BDE		;5bda
	ld b,000h		;5bdc
L_5BDE:
	ld a,b			;5bde
	cp c			;5bdf
	jr nz,L_5BE3		;5be0
	inc b			;5be2
L_5BE3:
	ld a,b			;5be3
	cp 008h		;5be4
	ret nz			;5be6
	ld b,000h		;5be7
	ret			;5be9
pon_los_cursores_de_color:		; mueve las dos flechas a la muestra elegida de las ocho
	ld a,(0e074h)		;5bea   ; el color del primer equipo
	ld hl,0e399h		;5bed   ; la X del sprite de su flecha
	call L_5BF8		;5bf0
	ld l,09dh		;5bf3   ; y la del segundo, veinte sprites mas alla
	ld a,(0e075h)		;5bf5   ; con su propio color
L_5BF8:
	add a,a			;5bf8   ; por ocho...
	add a,a			;5bf9
	add a,a			;5bfa
	ld b,a			;5bfb
	add a,a			;5bfc   ; ...y a eso se le suma el doble: 24 pixeles, que es lo que separa una muestra de la siguiente
	add a,b			;5bfd
	add a,02ah		;5bfe   ; mas 0x2A, que es donde empieza la primera
	ld (hl),a			;5c00
	ret			;5c01
aplica_los_colores_de_camiseta:		; lleva los tres tonos elegidos a las dos paletas de recoloreado
	ld de,0e053h		;5c02   ; las entradas 3, 4 y 5 de la paleta del primer equipo
	ld a,(0e074h)		;5c05   ; con el color que eligio su mando
	call L_5C11		;5c08
	ld a,(0e075h)		;5c0b   ; y lo mismo para el segundo
	ld de,0e058h		;5c0e
L_5C11:
	ld hl,05c20h		;5c11   ; los ocho juegos de tres bytes
	ld b,a			;5c14   ; por tres, que es lo que ocupa cada juego
	add a,a			;5c15
	add a,b			;5c16
	call suma_a_hl		;5c17
	ld bc,00003h		;5c1a
	ldir		;5c1d   ; y los tres tonos entran en la paleta que usa el recoloreado de 0x4846
	ret			;5c1f

; ----------------------------------------------------------------------
; DATOS colores_de_camiseta: ocho juegos de tres bytes, que es lo que se elige
;   en el menu de TEAM COLOR; (0xE074) y (0xE075) dan la vuelta en 0..7 y en
;   la pantalla hay exactamente ocho muestras dibujadas
;   0x5c20..0x5c38  (24 bytes)
DATA_colores_de_camiseta:
	defb 001h	; 5c20
	defb 00bh	; 5c21
	defb 006h	; 5c22
	defb 00bh	; 5c23
	defb 006h	; 5c24
	defb 00fh	; 5c25
	defb 006h	; 5c26
	defb 00bh	; 5c27
	defb 001h	; 5c28
	defb 006h	; 5c29
	defb 00bh	; 5c2a
	defb 004h	; 5c2b
	defb 001h	; 5c2c
	defb 006h	; 5c2d
	defb 00fh	; 5c2e
	defb 00bh	; 5c2f
	defb 006h	; 5c30
	defb 001h	; 5c31
	defb 006h	; 5c32
	defb 00bh	; 5c33
	defb 00dh	; 5c34
	defb 004h	; 5c35
	defb 00bh	; 5c36
	defb 001h	; 5c37

; ======================================================================
; CODIGO 0x5c38..0x5cea  (178 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL NIVEL =====
; ----------------------------------------------------------------------
elige_el_nivel:		; cinco niveles que dan la vuelta, sobre (0xE0A0) o (0xE0A1)
	ld a,(0e006h)		;5c38
	ld hl,0e008h		;5c3b
	or (hl)			;5c3e   ; lo recien pulsado en los dos mandos
	ld c,a			;5c3f   ; a salvo en C, que A hace falta para mirar el modo
	ld a,(0e002h)		;5c40
	bit 5,a		;5c43   ; el bit 5 de (0xE002): dos jugadores
	ld hl,0e0a0h		;5c45   ; con uno solo se ajusta (0xE0A0)...
	jr z,L_5C4D		;5c48
	ld hl,0e0a1h		;5c4a   ; ...y con dos, (0xE0A1): cada modo tiene su propio nivel guardado
L_5C4D:
	bit 2,c		;5c4d   ; izquierda...
	call nz,baja_el_nivel		;5c4f
	bit 3,c		;5c52   ; ...y derecha
	call nz,sube_el_nivel		;5c54
	jr pon_el_cursor_del_nivel		;5c57
baja_el_nivel:
	ld a,002h		;5c59
	call pide_un_sonido		;5c5b
	ld a,(hl)			;5c5e
	dec a			;5c5f   ; un nivel menos...
	jr nz,L_5C64		;5c60   ; ...y si se pasa del 1
	ld a,005h		;5c62   ; da la vuelta al 5: los niveles van de 1 a 5, no de 0 a 4
L_5C64:
	ld (hl),a			;5c64
	ret			;5c65
sube_el_nivel:
	ld a,002h		;5c66
	call pide_un_sonido		;5c68
	ld a,(hl)			;5c6b
	inc a			;5c6c   ; un nivel mas...
	cp 006h		;5c6d   ; ...y pasado el 5
	jr nz,L_5C73		;5c6f
	ld a,001h		;5c71   ; vuelve al 1
L_5C73:
	ld (hl),a			;5c73
	ret			;5c74
pon_el_cursor_del_nivel:
	ld a,(0e002h)		;5c75
	bit 5,a		;5c78   ; otra vez el modo de juego...
	ld a,(0e0a0h)		;5c7a   ; ...para leer el nivel del sitio que toca
	jr z,L_5C82		;5c7d
	ld a,(0e0a1h)		;5c7f
L_5C82:
	add a,a			;5c82   ; por 16, que es lo que separa una cifra de la siguiente
	add a,a			;5c83
	add a,a			;5c84
	add a,a			;5c85
	add a,07fh		;5c86   ; mas 0x7F: como el nivel 1 es el primero, la cuenta ya sale corrida a su sitio
	ld (0e3a1h),a		;5c88
	ret			;5c8b
mueve_el_cursor_del_tiempo:		; izquierda y derecha sobre las tres duraciones de parte
	ld a,020h		;5c8c
	ld (0e077h),a		;5c8e   ; (0xE077) = 0x20, el cuadro de espera antes de aceptar otra pulsacion
	ld a,(0e006h)		;5c91   ; lo RECIEN pulsado en los dos mandos, junto: en un menu no vale lo mantenido
	ld hl,0e008h		;5c94
	or (hl)			;5c97
	ld b,a			;5c98
	bit 2,b		;5c99   ; el bit 2 es izquierda...
	jr nz,L_5CA1		;5c9b
	bit 3,b		;5c9d   ; ...y el 3 derecha
	jr z,L_5CA6		;5c9f
L_5CA1:
	ld a,002h		;5ca1
	call pide_un_sonido		;5ca3   ; con cualquiera de los dos, el clic del menu
L_5CA6:
	ld a,(0e076h)		;5ca6   ; la opcion de ahora
	bit 2,b		;5ca9
	jr z,L_5CB5		;5cab
	dec a			;5cad   ; izquierda: una menos...
	jp p,L_5CB5		;5cae   ; ...y si se pasa de cero
	ld a,002h		;5cb1   ; da la vuelta a la ultima
	jr L_5CBF		;5cb3
L_5CB5:
	bit 3,b		;5cb5
	jr z,L_5CBF		;5cb7
	inc a			;5cb9   ; derecha: una mas...
	cp 003h		;5cba   ; ...y a la cuarta
	jr nz,L_5CBF		;5cbc
	xor a			;5cbe   ; vuelve a la primera: las tres opciones dan la vuelta
L_5CBF:
	ld (0e076h),a		;5cbf
	call pon_el_cursor_del_tiempo		;5cc2
	jr apunta_el_tiempo_de_parte		;5cc5
pon_el_cursor_del_tiempo:		; mueve los dos sprites del cursor a la opcion elegida
	ld a,(0e076h)		;5cc7
	add a,a			;5cca   ; por 32, que es lo que separa una opcion de la siguiente en la pantalla
	add a,a			;5ccb
	add a,a			;5ccc
	add a,a			;5ccd
	add a,a			;5cce
	add a,087h		;5ccf   ; mas 0x87, el ancho de la primera
	ld (0e3a5h),a		;5cd1
	add a,010h		;5cd4   ; y el segundo sprite, 16 pixeles a la derecha del primero
	ld (0e3a9h),a		;5cd6
	ret			;5cd9
apunta_el_tiempo_de_parte:
	ld a,(0e076h)		;5cda
	ld hl,05ceah		;5cdd   ; los tres tiempos: 3, 5 y 10
	call suma_a_hl		;5ce0
	ld h,(hl)			;5ce3   ; el valor es el byte ALTO
	ld l,000h		;5ce4   ; la parte baja a cero
	ld (0e072h),hl		;5ce6   ; y asi (0xE072) queda con los minutos por 256, que es como los cuenta el reloj
	ret			;5ce9

; ----------------------------------------------------------------------
; DATOS tiempos_de_parte: los tres del menu HALF TIME -0x03, 0x05 y 0x10-, que
;   pasan a (0xE072) como byte alto
;   0x5cea..0x5ced  (3 bytes)
DATA_tiempos_de_parte:
	defb 003h	; 5cea
	defb 005h	; 5ceb
	defb 010h	; 5cec

; ======================================================================
; CODIGO 0x5ced..0x5e69  (380 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL EDITOR DE NOMBRES =====
; ----------------------------------------------------------------------
edita_los_nombres_de_equipo:		; seis letras por bando, un cursor por mando
	ld a,(0e006h)		;5ced   ; lo recien pulsado en el mando 1
	ld c,a			;5cf0
	bit 2,c		;5cf1   ; izquierda: el cursor atras
	call nz,cursor_de_nombre_atras		;5cf3
	bit 3,c		;5cf6   ; derecha: el cursor adelante
	call nz,cursor_de_nombre_adelante		;5cf8
	call pon_el_cursor_del_nombre_1		;5cfb   ; y el sprite del cursor a su sitio
	ld a,(0e008h)		;5cfe   ; ahora el mando 2, con su propio cursor
	ld c,a			;5d01
	bit 2,c		;5d02
	call nz,cursor_de_nombre_2_atras		;5d04
	bit 3,c		;5d07
	call nz,cursor_de_nombre_2_adelante		;5d09
	call pon_el_cursor_del_nombre_2		;5d0c
	ld a,(0e006h)		;5d0f   ; para cambiar la letra valen los dos mandos...
	ld hl,0e008h		;5d12
	or (hl)			;5d15
	ld hl,0e077h		;5d16   ; (0xE077) es la espera de la repeticion automatica
	and 002h		;5d19   ; ...y aqui se mira el bit 1, que es arriba
	jr z,L_5D25		;5d1b
	ld (hl),028h		;5d1d   ; recien pulsado: 0x28 cuadros de gracia antes de que empiece a repetir
	xor a			;5d1f   ; y la cuenta fina a cero
	ld (0e07ah),a		;5d20
	jr L_5D32		;5d23
L_5D25:
	ld a,(hl)			;5d25   ; sin pulsacion nueva, se gasta la espera larga
	and a			;5d26
	jr z,L_5D2B		;5d27
	dec (hl)			;5d29   ; mientras quede, no se repite
	ret nz			;5d2a
L_5D2B:
	ld l,07ah		;5d2b   ; agotada la espera, entra la cuenta fina
	inc (hl)			;5d2d
	ld a,(hl)			;5d2e
	and 007h		;5d2f   ; una letra cada ocho cuadros: la repeticion, ya a ritmo
	ret nz			;5d31

; ----------------------------------------------------------------------
; ----- cambiar la letra, y verla cambiar -----
; ----------------------------------------------------------------------
L_5D32:
	ld de,03a95h		;5d32   ; el sitio en la VRAM del segundo nombre
	ld hl,0e062h		;5d35   ; y donde vive en la RAM
	ld a,(0e009h)		;5d38   ; lo mantenido del mando 2, que es lo que repite
	ld b,a			;5d3b
	ld a,(0e079h)		;5d3c   ; y su cursor
	call L_5D4F		;5d3f
	ld de,03a8ah		;5d42   ; lo mismo para el primer nombre
	ld hl,0e05bh		;5d45
	ld a,(0e007h)		;5d48
	ld b,a			;5d4b
	ld a,(0e078h)		;5d4c
L_5D4F:
	push af			;5d4f   ; el cursor, a salvo: hace falta dos veces, en la RAM y en la VRAM
	call suma_a_hl		;5d50   ; HL a la letra que el cursor senala
	ld c,(hl)			;5d53   ; la letra de ahora
	call siguiente_letra		;5d54   ; y la de al lado, si es que toca cambiarla
	ld (hl),c			;5d57   ; se guarda en la RAM
	pop af			;5d58
	ex de,hl			;5d59
	call suma_a_hl		;5d5a   ; y el mismo desplazamiento sirve en la VRAM, porque el nombre se pinta seguido
	ld a,c			;5d5d
	jp 0004dh		;5d5e   ; BIOS WRTVRM - Writes data in VRAM | la letra a la pantalla, sin pasar por el volcado del cuadro: es un menu, no hay prisa
cursor_de_nombre_atras:
	ld hl,0e078h		;5d61   ; el cursor del primer nombre
L_5D64:
	ld a,(hl)			;5d64
	dec a			;5d65   ; una letra atras...
	cp 0ffh		;5d66   ; ...y si se sale por la izquierda
	jr nz,L_5D6C		;5d68
	ld a,005h		;5d6a   ; da la vuelta a la sexta: los nombres son de seis letras
L_5D6C:
	ld (hl),a			;5d6c
	ld a,002h		;5d6d   ; el 2 es el clic de mover el cursor
	jp pide_un_sonido		;5d6f
cursor_de_nombre_adelante:
	ld hl,0e078h		;5d72
L_5D75:
	ld a,(hl)			;5d75
	inc a			;5d76   ; una letra adelante...
	cp 006h		;5d77   ; ...y pasada la sexta
	jr nz,L_5D6C		;5d79
	xor a			;5d7b   ; vuelve a la primera
	jr L_5D6C		;5d7c
pon_el_cursor_del_nombre_1:
	ld a,(0e078h)		;5d7e
	add a,a			;5d81   ; por ocho: cada letra ocupa una casilla
	add a,a			;5d82
	add a,a			;5d83
	add a,050h		;5d84   ; mas 0x50, que es donde empieza el primer nombre en la pantalla
	ld (0e3adh),a		;5d86
	ret			;5d89
cursor_de_nombre_2_atras:
	ld hl,0e079h		;5d8a   ; lo mismo, pero sobre el cursor del segundo mando
	jr L_5D64		;5d8d
cursor_de_nombre_2_adelante:
	ld hl,0e079h		;5d8f
	jr L_5D75		;5d92
pon_el_cursor_del_nombre_2:
	ld a,(0e079h)		;5d94
	add a,a			;5d97
	add a,a			;5d98
	add a,a			;5d99
	add a,0a8h		;5d9a   ; mas 0xA8: el segundo nombre esta a la derecha del marcador
	ld (0e3b1h),a		;5d9c
	ret			;5d9f

; ----------------------------------------------------------------------
; ----- el abecedario, con sus saltos -----
; ----------------------------------------------------------------------
siguiente_letra:		; avanza la letra saltandose los tres huecos del juego de caracteres
	ld a,b			;5da0   ; lo mantenido del mando
	rra			;5da1
	rra			;5da2   ; el bit 1: arriba
	ret nc			;5da3   ; sin el, la letra se queda como esta
	ld a,002h		;5da4   ; el 2 otra vez, el clic
	call pide_un_sonido		;5da6
	ld a,c			;5da9
	inc a			;5daa   ; la letra siguiente...
	cp 001h		;5dab   ; ...y del hueco -el 0, que es el espacio- se salta
	jr nz,L_5DB1		;5dad
	ld a,010h		;5daf   ; a 0x10, la primera cifra
L_5DB1:
	cp 01ah		;5db1   ; pasadas las cifras, en 0x1A
	jr nz,L_5DB7		;5db3
	ld a,01dh		;5db5   ; se salta a 0x1D, que es donde siguen los signos
L_5DB7:
	cp 03bh		;5db7   ; y detras de la Z, en 0x3B
	jr nz,L_5DBC		;5db9
	xor a			;5dbb   ; se vuelve al espacio: la rueda cierra
L_5DBC:
	ld c,a			;5dbc
	ret			;5dbd
L_5DBE:
	ld de,0e062h		;5dbe   ; los dos nombres de equipo, seis casillas cada uno, en la fila de arriba
	ld hl,03a95h		;5dc1
	ld bc,00006h		;5dc4
	call copia_a_la_vram		;5dc7
	ld de,0e05bh		;5dca
	ld hl,03a8ah		;5dcd
	ld bc,00006h		;5dd0
	jp copia_a_la_vram		;5dd3

; ----------------------------------------------------------------------
; ===== EL CAMPO: la ventana que se asoma al mapa =====
; ----------------------------------------------------------------------
vuelca_el_campo:		; copia 23 filas de 32 casillas del mapa de la RAM a la tabla de nombres
	ld a,(0e2c1h)		;5dd6   ; (0xE2C1) es por donde va la ventana: cuanto se ha corrido el campo a la derecha
	ld de,0e600h		;5dd9   ; el mapa vive en la RAM, en 0xE600, y no en la ROM: lo dejo ahi el descompresor
	add a,e			;5ddc
	ld e,a			;5ddd
	jr nc,L_5DE1		;5dde
	inc d			;5de0
L_5DE1:
	ld hl,03820h		;5de1   ; 0x3820 es la fila 1 de la tabla de nombres; la fila 0 se la queda el marcador
	call abre_la_vram		;5de4   ; fija la escritura una sola vez, para todo el volcado
	ex de,hl			;5de7
	ld a,(00007h)		;5de8   ; el puerto de datos, que aqui se usa con `outi` y no con WRTVRM
	ld c,a			;5deb
	ld a,017h		;5dec   ; 23 filas
L_5DEE:
	ld b,020h		;5dee   ; 32 casillas por fila, que es lo ancho que tiene la pantalla
L_5DF0:
	outi		;5df0   ; `outi` saca el byte y avanza el puntero de la RAM en el mismo golpe
	nop			;5df2   ; el `nop` da al VDP el respiro que necesita entre dos escrituras seguidas
	jr nz,L_5DF0		;5df3
	ld de,00030h		;5df5   ; y aqui esta la medida del mapa: tras las 32 casillas se saltan 48 mas
	add hl,de			;5df8   ; 32 + 48 son 80, o sea que el mapa tiene OCHENTA columnas y la pantalla solo ensena 32
	dec a			;5df9
	jr nz,L_5DEE		;5dfa
	ret			;5dfc

; ----------------------------------------------------------------------
; ===== La pantalla del marcador se monta =====
; ----------------------------------------------------------------------
monta_la_pantalla_de_datos:		; la fuente, los tiles del marcador y sus sprites
	call carga_la_fuente		;5dfd   ; la paleta de bloques y la fuente, en su sitio de siempre
	call carga_los_tiles_del_marcador		;5e00
	jp borra_el_estado_del_jingle		;5e03
arranca_la_jugada:		; reparte segun el bit 0 de (0xE0F8)
	call pinta_los_nombres_de_los_equipos		;5e06   ; el marcador de arriba: los nombres y los goles siempre...
	call pinta_el_marcador		;5e09
	ld a,(0e0f8h)		;5e0c   ; ...y luego, o los penaltis o el reloj, segun el bit 0 de (0xE0F8)
	rra			;5e0f
	jr nc,L_5E17		;5e10
	call pinta_los_penaltis		;5e12
	jr L_5E1A		;5e15
L_5E17:
	call pinta_el_reloj		;5e17
L_5E1A:
	jp L_5FAB		;5e1a
espera_a_que_calle_el_sonido:		; hasta que (0xE012) no diga que ha terminado, no se sigue
	call copia_los_sprites		;5e1d
	call mueve_el_jingle		;5e20
	ld a,(0e012h)		;5e23   ; (0xE012) es el canal de sonido: mientras suene algo, no
	and a			;5e26
	ret nz			;5e27
	ld a,002h		;5e28
	ld (0e525h),a		;5e2a
	ld a,05dh		;5e2d   ; y entonces pide el sonido 0x5D
	jp pide_un_sonido		;5e2f
carga_los_tiles_del_marcador:		; los patrones, su color, una SEGUNDA copia de la fuente y los sprites
	ld de,05e69h		;5e32
	ld hl,02230h		;5e35   ; 22 tiles propios en 0x2230
	call descomprime_en_los_tres_tercios		;5e38
	ld de,05eb2h		;5e3b
	ld hl,00230h		;5e3e   ; y su color, en la misma casilla de la tabla de COLOR
	call descomprime_en_los_tres_tercios		;5e41
	ld hl,02500h		;5e44
	ld de,04a6ch		;5e47   ; la MISMA fuente de 0x4A6C que ya esta en 0x2080, pero puesta tambien en 0x2500
	call descomprime_en_los_tres_tercios		;5e4a
	ld hl,00500h		;5e4d
	ld a,04fh		;5e50   ; 0x4F es tinta 4 sobre fondo 15: la segunda copia de la fuente se pinta al reves que la primera, azul sobre blanco
	ld bc,00180h		;5e52   ; 0x180 bytes son los 48 tiles que ocupa la fuente
	call rellena_los_tres_tercios		;5e55
	ld de,05f08h		;5e58
	call descomprime_con_destino_dentro		;5e5b   ; siete sprites, con su destino dentro del propio bloque
	ld hl,01800h		;5e5e   ; y aqui se hacen otros siete SIN gastar un byte mas de cartucho:
	ld de,018f0h		;5e61   ; se leen los de 0x1800 y se dejan reflejados en 0x18F0
	ld c,007h		;5e64   ; siete, de 32 bytes cada uno
	jp espeja_sprites_en_la_vram		;5e66

; ----------------------------------------------------------------------
; DATOS patrones_5e69: 73 bytes comprimidos que dan 176 de VRAM en 0x2230; lo
;   carga 0x5E38. Va a los TRES tercios de SCREEN 2
;   0x5e69..0x5eb2  (73 bytes)
DATA_patrones_5e69:
	defb 002h	; 5e69
	defb 000h	; 5e6a
	defb 00ah	; 5e6b
	defb 0ffh	; 5e6c
	defb 084h	; 5e6d
	defb 040h	; 5e6e
	defb 0e0h	; 5e6f
	defb 043h	; 5e70
	defb 007h	; 5e71
	defb 004h	; 5e72
	defb 0ffh	; 5e73
	defb 087h	; 5e74
	defb 040h	; 5e75
	defb 0e0h	; 5e76
	defb 046h	; 5e77
	defb 08fh	; 5e78
	defb 007h	; 5e79
	defb 003h	; 5e7a
	defb 070h	; 5e7b
	defb 003h	; 5e7c
	defb 006h	; 5e7d
	defb 08bh	; 5e7e
	defb 074h	; 5e7f
	defb 0ffh	; 5e80
	defb 08fh	; 5e81
	defb 006h	; 5e82
	defb 0e0h	; 5e83
	defb 0f0h	; 5e84
	defb 0f2h	; 5e85
	defb 0f6h	; 5e86
	defb 0e6h	; 5e87
	defb 0ffh	; 5e88
	defb 000h	; 5e89
	defb 007h	; 5e8a
	defb 0ffh	; 5e8b
	defb 081h	; 5e8c
	defb 000h	; 5e8d
	defb 00eh	; 5e8e
	defb 0ffh	; 5e8f
	defb 081h	; 5e90
	defb 000h	; 5e91
	defb 010h	; 5e92
	defb 080h	; 5e93
	defb 010h	; 5e94
	defb 001h	; 5e95
	defb 010h	; 5e96
	defb 074h	; 5e97
	defb 010h	; 5e98
	defb 02eh	; 5e99
	defb 081h	; 5e9a
	defb 000h	; 5e9b
	defb 015h	; 5e9c
	defb 0ffh	; 5e9d
	defb 003h	; 5e9e
	defb 000h	; 5e9f
	defb 084h	; 5ea0
	defb 03fh	; 5ea1
	defb 01fh	; 5ea2
	defb 00fh	; 5ea3
	defb 007h	; 5ea4
	defb 003h	; 5ea5
	defb 003h	; 5ea6
	defb 085h	; 5ea7
	defb 000h	; 5ea8
	defb 0fch	; 5ea9
	defb 0f8h	; 5eaa
	defb 0f0h	; 5eab
	defb 0e0h	; 5eac
	defb 003h	; 5ead
	defb 0c0h	; 5eae
	defb 008h	; 5eaf
	defb 03fh	; 5eb0
	defb 000h	; 5eb1

; ----------------------------------------------------------------------
; DATOS color_5eb2: 86 bytes comprimidos que dan 176 de VRAM en 0x0230; lo
;   carga 0x5E41. Va a los TRES tercios de SCREEN 2
;   0x5eb2..0x5f08  (86 bytes)
DATA_color_5eb2:
	defb 008h	; 5eb2
	defb 040h	; 5eb3
	defb 0a0h	; 5eb4
	defb 0f0h	; 5eb5
	defb 0b0h	; 5eb6
	defb 0e0h	; 5eb7
	defb 0f0h	; 5eb8
	defb 014h	; 5eb9
	defb 0b6h	; 5eba
	defb 01dh	; 5ebb
	defb 015h	; 5ebc
	defb 0f0h	; 5ebd
	defb 0b0h	; 5ebe
	defb 0e0h	; 5ebf
	defb 0f0h	; 5ec0
	defb 014h	; 5ec1
	defb 0b6h	; 5ec2
	defb 01dh	; 5ec3
	defb 015h	; 5ec4
	defb 0b6h	; 5ec5
	defb 0b5h	; 5ec6
	defb 01ch	; 5ec7
	defb 061h	; 5ec8
	defb 0dbh	; 5ec9
	defb 04ah	; 5eca
	defb 0a5h	; 5ecb
	defb 010h	; 5ecc
	defb 0b6h	; 5ecd
	defb 0b5h	; 5ece
	defb 01ch	; 5ecf
	defb 016h	; 5ed0
	defb 0bdh	; 5ed1
	defb 0a4h	; 5ed2
	defb 0a5h	; 5ed3
	defb 010h	; 5ed4
	defb 008h	; 5ed5
	defb 0e1h	; 5ed6
	defb 008h	; 5ed7
	defb 0e9h	; 5ed8
	defb 008h	; 5ed9
	defb 0efh	; 5eda
	defb 081h	; 5edb
	defb 010h	; 5edc
	defb 017h	; 5edd
	defb 01eh	; 5ede
	defb 081h	; 5edf
	defb 010h	; 5ee0
	defb 007h	; 5ee1
	defb 01eh	; 5ee2
	defb 081h	; 5ee3
	defb 010h	; 5ee4
	defb 017h	; 5ee5
	defb 0efh	; 5ee6
	defb 081h	; 5ee7
	defb 010h	; 5ee8
	defb 007h	; 5ee9
	defb 0efh	; 5eea
	defb 008h	; 5eeb
	defb 0c1h	; 5eec
	defb 081h	; 5eed
	defb 010h	; 5eee
	defb 004h	; 5eef
	defb 0e0h	; 5ef0
	defb 002h	; 5ef1
	defb 0f0h	; 5ef2
	defb 081h	; 5ef3
	defb 010h	; 5ef4
	defb 008h	; 5ef5
	defb 0cfh	; 5ef6
	defb 081h	; 5ef7
	defb 0c1h	; 5ef8
	defb 004h	; 5ef9
	defb 0ceh	; 5efa
	defb 002h	; 5efb
	defb 0cfh	; 5efc
	defb 002h	; 5efd
	defb 0c1h	; 5efe
	defb 004h	; 5eff
	defb 0ceh	; 5f00
	defb 002h	; 5f01
	defb 0cfh	; 5f02
	defb 081h	; 5f03
	defb 0c1h	; 5f04
	defb 008h	; 5f05
	defb 0cfh	; 5f06
	defb 000h	; 5f07

; ----------------------------------------------------------------------
; DATOS patrones_de_sprite_5f08: 163 bytes comprimidos que dan 224 de VRAM en
;   0x1800; lo carga 0x5E5B
;   0x5f08..0x5fab  (163 bytes)
DATA_patrones_de_sprite_5f08:
	defb 000h	; 5f08
	defb 018h	; 5f09
	defb 028h	; 5f0a
	defb 000h	; 5f0b
	defb 087h	; 5f0c
	defb 003h	; 5f0d
	defb 007h	; 5f0e
	defb 00eh	; 5f0f
	defb 00eh	; 5f10
	defb 00ah	; 5f11
	defb 008h	; 5f12
	defb 00ch	; 5f13
	defb 009h	; 5f14
	defb 000h	; 5f15
	defb 088h	; 5f16
	defb 0e0h	; 5f17
	defb 0f0h	; 5f18
	defb 0f8h	; 5f19
	defb 0a8h	; 5f1a
	defb 0a0h	; 5f1b
	defb 000h	; 5f1c
	defb 040h	; 5f1d
	defb 070h	; 5f1e
	defb 00ah	; 5f1f
	defb 000h	; 5f20
	defb 002h	; 5f21
	defb 001h	; 5f22
	defb 084h	; 5f23
	defb 005h	; 5f24
	defb 007h	; 5f25
	defb 003h	; 5f26
	defb 007h	; 5f27
	defb 00bh	; 5f28
	defb 000h	; 5f29
	defb 002h	; 5f2a
	defb 050h	; 5f2b
	defb 094h	; 5f2c
	defb 0f0h	; 5f2d
	defb 0b0h	; 5f2e
	defb 080h	; 5f2f
	defb 00fh	; 5f30
	defb 007h	; 5f31
	defb 003h	; 5f32
	defb 007h	; 5f33
	defb 00fh	; 5f34
	defb 00ch	; 5f35
	defb 00fh	; 5f36
	defb 00fh	; 5f37
	defb 006h	; 5f38
	defb 000h	; 5f39
	defb 000h	; 5f3a
	defb 001h	; 5f3b
	defb 001h	; 5f3c
	defb 009h	; 5f3d
	defb 00fh	; 5f3e
	defb 007h	; 5f3f
	defb 020h	; 5f40
	defb 004h	; 5f41
	defb 0f0h	; 5f42
	defb 083h	; 5f43
	defb 010h	; 5f44
	defb 0f0h	; 5f45
	defb 090h	; 5f46
	defb 004h	; 5f47
	defb 000h	; 5f48
	defb 002h	; 5f49
	defb 0c0h	; 5f4a
	defb 003h	; 5f4b
	defb 000h	; 5f4c
	defb 097h	; 5f4d
	defb 018h	; 5f4e
	defb 03ch	; 5f4f
	defb 078h	; 5f50
	defb 060h	; 5f51
	defb 063h	; 5f52
	defb 000h	; 5f53
	defb 000h	; 5f54
	defb 001h	; 5f55
	defb 007h	; 5f56
	defb 007h	; 5f57
	defb 00eh	; 5f58
	defb 00eh	; 5f59
	defb 006h	; 5f5a
	defb 000h	; 5f5b
	defb 000h	; 5f5c
	defb 0c0h	; 5f5d
	defb 000h	; 5f5e
	defb 008h	; 5f5f
	defb 008h	; 5f60
	defb 00ch	; 5f61
	defb 0ech	; 5f62
	defb 008h	; 5f63
	defb 060h	; 5f64
	defb 003h	; 5f65
	defb 0f0h	; 5f66
	defb 081h	; 5f67
	defb 0e0h	; 5f68
	defb 004h	; 5f69
	defb 000h	; 5f6a
	defb 091h	; 5f6b
	defb 00fh	; 5f6c
	defb 007h	; 5f6d
	defb 003h	; 5f6e
	defb 007h	; 5f6f
	defb 007h	; 5f70
	defb 000h	; 5f71
	defb 003h	; 5f72
	defb 00fh	; 5f73
	defb 001h	; 5f74
	defb 000h	; 5f75
	defb 020h	; 5f76
	defb 030h	; 5f77
	defb 038h	; 5f78
	defb 018h	; 5f79
	defb 000h	; 5f7a
	defb 000h	; 5f7b
	defb 020h	; 5f7c
	defb 003h	; 5f7d
	defb 0f0h	; 5f7e
	defb 085h	; 5f7f
	defb 0e0h	; 5f80
	defb 000h	; 5f81
	defb 0e0h	; 5f82
	defb 0d0h	; 5f83
	defb 080h	; 5f84
	defb 004h	; 5f85
	defb 000h	; 5f86
	defb 08fh	; 5f87
	defb 028h	; 5f88
	defb 03ch	; 5f89
	defb 01ch	; 5f8a
	defb 000h	; 5f8b
	defb 018h	; 5f8c
	defb 01ch	; 5f8d
	defb 038h	; 5f8e
	defb 038h	; 5f8f
	defb 01fh	; 5f90
	defb 00ch	; 5f91
	defb 000h	; 5f92
	defb 00eh	; 5f93
	defb 01fh	; 5f94
	defb 01fh	; 5f95
	defb 00eh	; 5f96
	defb 004h	; 5f97
	defb 000h	; 5f98
	defb 081h	; 5f99
	defb 0c0h	; 5f9a
	defb 003h	; 5f9b
	defb 000h	; 5f9c
	defb 08ch	; 5f9d
	defb 010h	; 5f9e
	defb 0f8h	; 5f9f
	defb 018h	; 5fa0
	defb 020h	; 5fa1
	defb 070h	; 5fa2
	defb 070h	; 5fa3
	defb 078h	; 5fa4
	defb 038h	; 5fa5
	defb 038h	; 5fa6
	defb 010h	; 5fa7
	defb 000h	; 5fa8
	defb 000h	; 5fa9
	defb 000h	; 5faa

; ======================================================================
; CODIGO 0x5fab..0x5fd4  (41 bytes)
; ======================================================================


L_5FAB:
	ld de,05fd4h		;5fab   ; la fila de arriba entera, que viene comprimida
	call descomprime_con_destino_dentro		;5fae
	ld a,(0e0f2h)		;5fb1   ; y con (0xE0F2) a 2 se le anade un rotulo mas
	cp 002h		;5fb4
	jr nz,L_5FBE		;5fb6
	ld de,060afh		;5fb8
	call escribe_un_rotulo		;5fbb
L_5FBE:
	ld hl,0394ch		;5fbe
L_5FC1:
	ld a,(0e002h)		;5fc1   ; el nivel solo se escribe en la partida de un jugador
	bit 5,a		;5fc4
	ret nz			;5fc6
	ld de,04a30h		;5fc7
	call escribe_el_rotulo_en_hl		;5fca
	inc hl			;5fcd
	ld de,0e069h		;5fce
	jp escribe_dos_cifras_sin_cero		;5fd1

; ----------------------------------------------------------------------
; DATOS nombres_5fd4: 219 bytes comprimidos que dan 736 de VRAM en 0x3820; lo
;   carga 0x5FAE
;   0x5fd4..0x60af  (219 bytes)
DATA_nombres_5fd4:
	defb 020h	; 5fd4
	defb 038h	; 5fd5
	defb 020h	; 5fd6
	defb 046h	; 5fd7
	defb 020h	; 5fd8
	defb 004h	; 5fd9
	defb 0e0h	; 5fda
	defb 047h	; 5fdb
	defb 048h	; 5fdc
	defb 047h	; 5fdd
	defb 048h	; 5fde
	defb 047h	; 5fdf
	defb 048h	; 5fe0
	defb 047h	; 5fe1
	defb 048h	; 5fe2
	defb 047h	; 5fe3
	defb 048h	; 5fe4
	defb 047h	; 5fe5
	defb 048h	; 5fe6
	defb 047h	; 5fe7
	defb 048h	; 5fe8
	defb 047h	; 5fe9
	defb 048h	; 5fea
	defb 047h	; 5feb
	defb 048h	; 5fec
	defb 047h	; 5fed
	defb 048h	; 5fee
	defb 047h	; 5fef
	defb 048h	; 5ff0
	defb 047h	; 5ff1
	defb 048h	; 5ff2
	defb 047h	; 5ff3
	defb 048h	; 5ff4
	defb 047h	; 5ff5
	defb 048h	; 5ff6
	defb 047h	; 5ff7
	defb 048h	; 5ff8
	defb 047h	; 5ff9
	defb 048h	; 5ffa
	defb 049h	; 5ffb
	defb 04ah	; 5ffc
	defb 049h	; 5ffd
	defb 04ah	; 5ffe
	defb 049h	; 5fff
	defb 04ah	; 6000
	defb 049h	; 6001
	defb 04ah	; 6002
	defb 049h	; 6003
	defb 04ah	; 6004
	defb 049h	; 6005
	defb 04ah	; 6006
	defb 049h	; 6007
	defb 04ah	; 6008
	defb 049h	; 6009
	defb 04ah	; 600a
	defb 049h	; 600b
	defb 04ah	; 600c
	defb 049h	; 600d
	defb 04ah	; 600e
	defb 049h	; 600f
	defb 04ah	; 6010
	defb 049h	; 6011
	defb 04ah	; 6012
	defb 049h	; 6013
	defb 04ah	; 6014
	defb 049h	; 6015
	defb 04ah	; 6016
	defb 049h	; 6017
	defb 04ah	; 6018
	defb 049h	; 6019
	defb 04ah	; 601a
	defb 04ah	; 601b
	defb 049h	; 601c
	defb 04ah	; 601d
	defb 049h	; 601e
	defb 04ah	; 601f
	defb 049h	; 6020
	defb 04ah	; 6021
	defb 049h	; 6022
	defb 04ah	; 6023
	defb 049h	; 6024
	defb 04ah	; 6025
	defb 049h	; 6026
	defb 04ah	; 6027
	defb 049h	; 6028
	defb 04ah	; 6029
	defb 049h	; 602a
	defb 04ah	; 602b
	defb 049h	; 602c
	defb 04ah	; 602d
	defb 049h	; 602e
	defb 04ah	; 602f
	defb 049h	; 6030
	defb 04ah	; 6031
	defb 049h	; 6032
	defb 04ah	; 6033
	defb 049h	; 6034
	defb 04ah	; 6035
	defb 049h	; 6036
	defb 04ah	; 6037
	defb 049h	; 6038
	defb 04ah	; 6039
	defb 049h	; 603a
	defb 02bh	; 603b
	defb 00fh	; 603c
	defb 08ah	; 603d
	defb 0b6h	; 603e
	defb 0b9h	; 603f
	defb 0c2h	; 6040
	defb 0c3h	; 6041
	defb 0c4h	; 6042
	defb 00fh	; 6043
	defb 0b8h	; 6044
	defb 0b1h	; 6045
	defb 0bch	; 6046
	defb 0b6h	; 6047
	defb 02bh	; 6048
	defb 00fh	; 6049
	defb 006h	; 604a
	defb 04bh	; 604b
	defb 082h	; 604c
	defb 04eh	; 604d
	defb 052h	; 604e
	defb 010h	; 604f
	defb 000h	; 6050
	defb 082h	; 6051
	defb 055h	; 6052
	defb 051h	; 6053
	defb 006h	; 6054
	defb 04bh	; 6055
	defb 006h	; 6056
	defb 04ch	; 6057
	defb 082h	; 6058
	defb 04fh	; 6059
	defb 053h	; 605a
	defb 010h	; 605b
	defb 000h	; 605c
	defb 082h	; 605d
	defb 054h	; 605e
	defb 050h	; 605f
	defb 00ch	; 6060
	defb 04ch	; 6061
	defb 082h	; 6062
	defb 04fh	; 6063
	defb 053h	; 6064
	defb 010h	; 6065
	defb 000h	; 6066
	defb 082h	; 6067
	defb 054h	; 6068
	defb 050h	; 6069
	defb 006h	; 606a
	defb 04ch	; 606b
	defb 006h	; 606c
	defb 00eh	; 606d
	defb 082h	; 606e
	defb 04fh	; 606f
	defb 053h	; 6070
	defb 010h	; 6071
	defb 000h	; 6072
	defb 082h	; 6073
	defb 054h	; 6074
	defb 050h	; 6075
	defb 00ch	; 6076
	defb 00eh	; 6077
	defb 082h	; 6078
	defb 04fh	; 6079
	defb 053h	; 607a
	defb 010h	; 607b
	defb 000h	; 607c
	defb 082h	; 607d
	defb 054h	; 607e
	defb 050h	; 607f
	defb 006h	; 6080
	defb 00eh	; 6081
	defb 006h	; 6082
	defb 04dh	; 6083
	defb 082h	; 6084
	defb 04fh	; 6085
	defb 053h	; 6086
	defb 010h	; 6087
	defb 000h	; 6088
	defb 082h	; 6089
	defb 054h	; 608a
	defb 050h	; 608b
	defb 006h	; 608c
	defb 04dh	; 608d
	defb 007h	; 608e
	defb 056h	; 608f
	defb 081h	; 6090
	defb 05ah	; 6091
	defb 010h	; 6092
	defb 057h	; 6093
	defb 081h	; 6094
	defb 059h	; 6095
	defb 007h	; 6096
	defb 056h	; 6097
	defb 060h	; 6098
	defb 00ch	; 6099
	defb 020h	; 609a
	defb 058h	; 609b
	defb 010h	; 609c
	defb 00ch	; 609d
	defb 081h	; 609e
	defb 05bh	; 609f
	defb 01fh	; 60a0
	defb 00ch	; 60a1
	defb 081h	; 60a2
	defb 05bh	; 60a3
	defb 01fh	; 60a4
	defb 00ch	; 60a5
	defb 081h	; 60a6
	defb 05bh	; 60a7
	defb 01fh	; 60a8
	defb 00ch	; 60a9
	defb 081h	; 60aa
	defb 05bh	; 60ab
	defb 00fh	; 60ac
	defb 00ch	; 60ad
	defb 000h	; 60ae

; ----------------------------------------------------------------------
; DATOS rotulo_second: seis tiles que 0x5FB8 escribe en 0x38EA solo en la
;   segunda parte: convierten el "FIRST HALF" de fabrica en "SECOND HALF"
;   0x60af..0x60b8  (9 bytes)
DATA_rotulo_second:
	defb 0eah	; 60af
	defb 038h	; 60b0
	defb 0c3h	; 60b1
	defb 0b5h	; 60b2
	defb 0b3h	; 60b3
	defb 0bfh	; 60b4
	defb 0beh	; 60b5
	defb 0b4h	; 60b6
	defb 0ffh	; 60b7

; ======================================================================
; CODIGO 0x60b8..0x6186  (206 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL JINGLE: las figuras que saltan =====
; ----------------------------------------------------------------------
mueve_el_jingle:		; un cuadro entero de la animacion: lanza, mueve, colorea y dibuja
	call lanza_una_pareja		;60b8   ; primero, si toca lanzar una pareja nueva
	call mueve_las_cuatro_figuras		;60bb   ; luego se mueven las cuatro figuras
	call pon_los_patrones_del_jingle		;60be   ; los patrones, segun vayan subiendo o bajando
	call colorea_el_jingle		;60c1   ; los colores y el parpadeo
	jp reparte_los_sprites_del_jingle		;60c4   ; y al final se reparten los sprites
mueve_las_cuatro_figuras:
	ld b,004h		;60c7   ; cuatro figuras: dos parejas
	ld hl,0e07eh		;60c9   ; la primera terna, en 0xE07E
L_60CC:
	push hl			;60cc
	ld de,0e07ch		;60cd
	call mueve_una_figura		;60d0
	pop hl			;60d3
	inc hl			;60d4   ; y de una terna a la siguiente van tres bytes: modo, Y y X
	inc hl			;60d5
	inc hl			;60d6
	djnz L_60CC		;60d7
	ret			;60d9
mueve_una_figura:		; cuatro modos, que son las cuatro mitades de la parabola
	ld a,(hl)			;60da   ; el modo, y HL queda ya sobre la Y
	inc hl			;60db
	dec a			;60dc   ; modo 0: la figura esta aparcada
	ret m			;60dd   ; y de ahi no se sigue
	jr z,sube_a_la_derecha		;60de   ; modo 1: sube y va a la derecha
	dec a			;60e0
	jr z,sube_a_la_izquierda		;60e1   ; modo 2: sube y va a la izquierda
	dec a			;60e3
	jr z,baja_a_la_derecha		;60e4   ; modo 3: baja y va a la derecha
	inc (hl)			;60e6   ; modo 4 -el que queda-: baja, dos pixeles por cuadro
	inc (hl)			;60e7
	ld a,(hl)			;60e8   ; la Y, ya movida, y HL a la X
	inc hl			;60e9
	dec (hl)			;60ea   ; y a la izquierda, un pixel: baja el doble de deprisa que se desplaza
	ld c,a			;60eb   ; la altura, a salvo
	cp 088h		;60ec   ; pasada de 0x88...
	jr c,L_60F2		;60ee
	xor a			;60f0   ; ...se apaga (0xE07C), que es lo que deja lanzar la pareja siguiente
	ld (de),a			;60f1
L_60F2:
	ld a,c			;60f2
	cp 0d0h		;60f3   ; en 0xD0 la figura ya esta abajo del todo
	ret c			;60f5   ; antes de eso no hay nada que hacer
	jr nz,L_60FB		;60f6
	xor a			;60f8
	ld (de),a			;60f9
	ret			;60fa
L_60FB:
	cp 0d1h		;60fb   ; y justo en 0xD1
	ret nz			;60fd
	dec hl			;60fe   ; se aparca: la Y a 0xE0, fuera de la pantalla
	ld (hl),0e0h		;60ff
	dec hl			;6101
	ld (hl),000h		;6102   ; y el modo a 0, que la deja libre para el proximo lanzamiento
	ret			;6104
baja_a_la_derecha:
	inc (hl)			;6105   ; la Y, dos pixeles abajo
	inc (hl)			;6106
	ld a,(hl)			;6107
	inc hl			;6108
	inc (hl)			;6109   ; y la X, un pixel a la derecha: el otro lado de la misma parabola
	ld c,a			;610a
	cp 088h		;610b
	jr c,L_6111		;610d
	xor a			;610f
	ld (de),a			;6110
L_6111:
	ld a,c			;6111
	cp 0d0h		;6112
	ret c			;6114
	jr nz,L_60FB		;6115   ; el final es el mismo de la otra, y se comparte el codigo
	xor a			;6117
	ld (de),a			;6118
	ret			;6119
sube_a_la_derecha:
	dec (hl)			;611a   ; dos pixeles arriba
	dec (hl)			;611b
	ld a,(hl)			;611c
	inc hl			;611d
	inc (hl)			;611e   ; y uno a la derecha
	cp 057h		;611f   ; 0x57 es la cumbre del salto
	ret nz			;6121   ; antes de llegar, nada
	dec l			;6122   ; y ahi HL vuelve al modo
	dec l			;6123
	ld a,001h		;6124
	ld (hl),003h		;6126   ; que pasa a 3: la misma X, pero ya bajando
	ld (0e07bh),a		;6128   ; y (0xE07B) marca que la pareja ha coronado, para cambiarle el dibujo
	ret			;612b
sube_a_la_izquierda:
	dec (hl)			;612c
	dec (hl)			;612d
	ld a,(hl)			;612e
	inc hl			;612f
	dec (hl)			;6130   ; uno a la izquierda
	cp 057h		;6131   ; la misma cumbre
	ret nz			;6133
	dec l			;6134
	dec l			;6135
	ld a,001h		;6136
	ld (hl),004h		;6138   ; y el modo 4, que baja por el lado izquierdo
	ld (0e07bh),a		;613a
	ret			;613d
lanza_una_pareja:		; siete parejas como mucho, y solo si hay hueco
	ld a,(0e07ch)		;613e   ; (0xE07C) distinto de cero: hay una pareja en el aire...
	and a			;6141
	ret nz			;6142   ; ...y entonces no se lanza otra
	ld a,(0e08ah)		;6143   ; (0xE08A) cuenta las parejas ya lanzadas
	cp 007h		;6146   ; y a las siete se acabo el jingle
	ret nc			;6148
	ld b,002h		;6149   ; dos parejas caben a la vez
	ld de,00006h		;614b   ; seis bytes ocupa cada una: dos ternas
	ld hl,0e07eh		;614e
L_6151:
	ld a,(hl)			;6151   ; el modo de la primera terna
	and a			;6152
	jr z,L_6159		;6153   ; a cero: esta libre
	add hl,de			;6155   ; si no, a mirar la otra
	djnz L_6151		;6156
	ret			;6158   ; con las dos ocupadas no hay sitio
L_6159:
	ld a,(0e08ah)		;6159
	inc a			;615c   ; una parada mas
	ld (0e08ah),a		;615d
	ex de,hl			;6160   ; DE al hueco encontrado
	ld hl,0e07dh		;6161   ; (0xE07D) es el indice del guion
	inc (hl)			;6164
	ld a,(hl)			;6165
	cp 007h		;6166   ; siete guiones hay
	jr nz,L_616B		;6168
	xor a			;616a   ; y despues se vuelve al primero
L_616B:
	ld (hl),a			;616b
	ld hl,06198h		;616c   ; la tabla de los siete punteros
	add a,a			;616f   ; dos bytes por puntero
	call suma_a_hl		;6170
	ld c,(hl)			;6173
	inc hl			;6174
	ld h,(hl)			;6175
	ld l,c			;6176
	ld bc,00006h		;6177   ; seis bytes: las dos ternas de la pareja
	ldir		;617a
	xor a			;617c
	ld (0e07bh),a		;617d   ; (0xE07B) a cero: la pareja nueva todavia no ha coronado
	ld a,001h		;6180
	ld (0e07ch),a		;6182   ; y (0xE07C) a uno, que cierra la puerta hasta que esta caiga
	ret			;6185

; ----------------------------------------------------------------------
; DATOS sprites_del_jingle_del_gol: tres arranques de seis bytes -dos ternas
;   de estado, Y y X- y una tabla de siete punteros; son los dos grupos de
;   ocho sprites que cruzan la pantalla mientras suena el jingle
;   0x6186..0x61a6  (32 bytes)
DATA_sprites_del_jingle_del_gol:
	defb 001h	; 6186
	defb 071h	; 6187
	defb 098h	; 6188
	defb 002h	; 6189
	defb 071h	; 618a
	defb 058h	; 618b
	defb 001h	; 618c
	defb 071h	; 618d
	defb 088h	; 618e
	defb 002h	; 618f
	defb 071h	; 6190
	defb 068h	; 6191
	defb 001h	; 6192
	defb 071h	; 6193
	defb 078h	; 6194
	defb 002h	; 6195
	defb 071h	; 6196
	defb 078h	; 6197
	defb 086h	; 6198
	defb 061h	; 6199
	defb 092h	; 619a
	defb 061h	; 619b
	defb 08ch	; 619c
	defb 061h	; 619d
	defb 086h	; 619e
	defb 061h	; 619f
	defb 08ch	; 61a0
	defb 061h	; 61a1
	defb 092h	; 61a2
	defb 061h	; 61a3
	defb 08ch	; 61a4
	defb 061h	; 61a5

; ======================================================================
; CODIGO 0x61a6..0x6394  (494 bytes)
; ======================================================================


reparte_los_sprites_del_jingle:		; las dos figuras de cada pareja comparten la altura
	ld hl,0e07fh		;61a6   ; la Y de la primera pareja
	ld de,0e080h		;61a9   ; y su X
	ld ix,0e3b0h		;61ac   ; los ocho sprites del primer grupo
	call L_61BD		;61b0
	ld hl,0e085h		;61b3   ; la segunda pareja, con su propia altura
	ld de,0e086h		;61b6
	ld ix,0e3d0h		;61b9   ; y sus otros ocho sprites
L_61BD:
	ld a,(hl)			;61bd   ; la altura...
	ld (ix+000h),a		;61be   ; ...a los cuatro sprites de arriba de las dos figuras
	ld (ix+004h),a		;61c1
	ld (ix+010h),a		;61c4
	ld (ix+014h),a		;61c7
	add a,010h		;61ca   ; y 16 pixeles mas abajo
	ld (ix+008h),a		;61cc   ; para los cuatro de abajo: cada figura son 2x2 sprites, o sea 32x32 pixeles
	ld (ix+00ch),a		;61cf
	ld (ix+018h),a		;61d2
	ld (ix+01ch),a		;61d5
	ld a,(de)			;61d8   ; la X de la primera figura
	ld (ix+001h),a		;61d9
	ld (ix+005h),a		;61dc
	ld (ix+009h),a		;61df
	ld (ix+00dh),a		;61e2
	inc e			;61e5   ; tres bytes mas alla esta la X de su companera
	inc e			;61e6
	inc e			;61e7
	ld a,(de)			;61e8   ; que va a los otros cuatro sprites
	ld (ix+011h),a		;61e9
	ld (ix+015h),a		;61ec
	ld (ix+019h),a		;61ef
	ld (ix+01dh),a		;61f2
	ret			;61f5
pon_los_patrones_del_jingle:
	ld a,(0e07bh)		;61f6   ; (0xE07B) dice si la pareja ya paso por la cumbre
	and a			;61f9
	jr z,L_6200		;61fa
	ld a,0ffh		;61fc   ; y entonces se dibujan con estos patrones
	jr L_6202		;61fe
L_6200:
	ld a,077h		;6200   ; y si aun sube, con estos otros
L_6202:
	ld hl,0e390h		;6202
	call L_620A		;6205   ; los cuatro primeros sprites
	add a,008h		;6208   ; y los cuatro de abajo, ocho patrones mas alla
L_620A:
	ld b,004h		;620a   ; cuatro sprites
L_620C:
	ld (hl),a			;620c
	inc hl			;620d   ; de cuatro bytes cada uno
	inc hl			;620e
	inc hl			;620f
	inc hl			;6210
	djnz L_620C		;6211
	ret			;6213
borra_el_estado_del_jingle:
	ld hl,0e390h		;6214   ; los 32 bytes de la tabla de sprites
	ld bc,00020h		;6217
L_621A:
	ld (hl),000h		;621a
	inc l			;621c
	dec bc			;621d
	ld a,b			;621e
	or c			;621f
	jr nz,L_621A		;6220
	ld hl,0e07bh		;6222   ; y los 16 del estado de la animacion
	ld bc,00010h		;6225
L_6228:
	ld (hl),000h		;6228
	inc l			;622a
	dec bc			;622b
	ld a,b			;622c
	or c			;622d
	jr nz,L_6228		;622e
	ld a,012h		;6230   ; (0xE08C) = 0x12
	ld (0e08ch),a		;6232
	ld hl,0e082h		;6235   ; las alturas de las companeras
	ld de,00003h		;6238   ; tres bytes de una terna a la otra
	ld b,002h		;623b
L_623D:
	ld (hl),0c1h		;623d   ; 0xC1: abajo del todo, que es de donde salen
	add hl,de			;623f
	djnz L_623D		;6240
	ret			;6242
colorea_el_jingle:
	ld a,004h		;6243
	ld hl,0e3b2h		;6245   ; los patrones del primer grupo
	call numera_cuatro_sprites		;6248
	ld a,020h		;624b   ; y el segundo juego, que empieza en 0x20
	call numera_cuatro_sprites		;624d
	ld a,004h		;6250
	call numera_cuatro_sprites		;6252
	ld a,020h		;6255
	call numera_cuatro_sprites		;6257
	ld hl,0e053h		;625a   ; la paleta de un equipo...
	ld de,0e3b3h		;625d
	call colorea_cuatro_sprites		;6260
	ld hl,0e058h		;6263   ; ...y la del otro: las figuras van vestidas como los equipos del partido
	call colorea_cuatro_sprites		;6266
	ld hl,0e053h		;6269
	call colorea_cuatro_sprites		;626c
	ld hl,0e058h		;626f
	call colorea_cuatro_sprites		;6272
	ld hl,0e08dh		;6275   ; (0xE08D) cuenta cuadros
	inc (hl)			;6278
	ld a,(hl)			;6279   ; y su bit 2 hace el parpadeo, uno de cada cuatro cuadros
	and 004h		;627a
	ret z			;627c
	ld a,014h		;627d   ; los patrones alternativos, los del destello
	ld (0e3bah),a		;627f
	ld a,018h		;6282
	ld (0e3beh),a		;6284
	ld a,030h		;6287
	ld (0e3cah),a		;6289
	ld a,034h		;628c
	ld (0e3ceh),a		;628e
	ld a,014h		;6291
	ld (0e3dah),a		;6293
	ld a,018h		;6296
	ld (0e3deh),a		;6298
	ld a,030h		;629b
	ld (0e3eah),a		;629d
	ld a,034h		;62a0
	ld (0e3eeh),a		;62a2
	ret			;62a5
numera_cuatro_sprites:
	ld b,004h		;62a6   ; cuatro
L_62A8:
	ld (hl),a			;62a8
	inc hl			;62a9   ; de cuatro bytes cada uno
	inc hl			;62aa
	inc hl			;62ab
	inc hl			;62ac
	add a,004h		;62ad   ; y el patron sube de cuatro en cuatro: cada figura de 16x16 gasta cuatro tiles
	djnz L_62A8		;62af
	ret			;62b1
colorea_cuatro_sprites:
	ld b,003h		;62b2   ; tres colores de la paleta
L_62B4:
	ld a,(hl)			;62b4
	inc hl			;62b5
	ld (de),a			;62b6
	inc de			;62b7   ; uno a cada sprite
	inc de			;62b8
	inc de			;62b9
	inc de			;62ba
	djnz L_62B4		;62bb
	dec hl			;62bd   ; y el cuarto sprite repite el tercero, que la paleta solo trae tres
	dec hl			;62be
	ld a,(hl)			;62bf
	ld (de),a			;62c0
	inc de			;62c1
	inc de			;62c2
	inc de			;62c3
	inc de			;62c4
	ret			;62c5
anima_la_valla:		; dos filas de tiles que se alternan cada cuatro cuadros
	ld a,(0e003h)		;62c6   ; el contador de cuadros
	bit 2,a		;62c9   ; su bit 2: cuatro cuadros con una pareja de tiles...
	ld de,04748h		;62cb
	jr nz,L_62D3		;62ce
	ld de,04847h		;62d0   ; ...y cuatro con la misma pareja al reves
L_62D3:
	ld hl,03860h		;62d3   ; la fila 3 de la tabla de nombres
	call L_62E0		;62d6
	inc d			;62d9   ; y la fila de abajo lleva los dos tiles siguientes
	inc d			;62da
	inc e			;62db
	inc e			;62dc
	call L_62E0		;62dd
L_62E0:
	ld b,010h		;62e0   ; dieciseis parejas: 32 casillas, la pantalla entera de ancho
L_62E2:
	ld a,e			;62e2
	call 0004dh		;62e3   ; BIOS WRTVRM - Writes data in VRAM | aqui no hay prisa de retrazo, asi que se escribe con la BIOS
	inc hl			;62e6
	ld a,d			;62e7
	call 0004dh		;62e8   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;62eb
	djnz L_62E2		;62ec
	ret			;62ee

; ----------------------------------------------------------------------
; ===== EL RELOJ =====
; ----------------------------------------------------------------------
corre_el_reloj:		; un segundo cada 30 cuadros, en BCD, y avisa cuando se acaba
	ld hl,0e560h		;62ef   ; (0xE560) cuenta cuadros
	inc (hl)			;62f2
	ld a,(hl)			;62f3
	sub 01eh		;62f4   ; treinta cuadros por segundo de partido
	ret nz			;62f6   ; hasta los treinta, nada
	ld (hl),a			;62f7   ; y ahi vuelve a cero, que A ya vale cero tras la resta
	ld hl,0e0f4h		;62f8   ; el reloj son dos bytes: (0xE0F3) los segundos y (0xE0F4) los minutos
	ld a,(hl)			;62fb
	dec l			;62fc
	or (hl)			;62fd   ; si los dos estan a cero, se acabo el tiempo
	jr z,L_6318		;62fe
	ld a,(0e54ah)		;6300   ; (0xE54A) distinto de cero: hay una jugada parada, y el reloj no corre
	and a			;6303
	ret nz			;6304
	ld a,(hl)			;6305
	sub 001h		;6306   ; un segundo menos...
	daa			;6308   ; ...en BCD, que es como esta escrito para poder pintarlo tal cual
	ld (hl),a			;6309
	jr nc,L_6315		;630a   ; sin pedir prestado, ya esta
	ld a,059h		;630c   ; y al bajar de cero, los segundos vuelven a 59
	ld (hl),a			;630e
	inc hl			;630f
	ld a,(hl)			;6310
	sub 001h		;6311   ; con un minuto menos, tambien en BCD
	daa			;6313
	ld (hl),a			;6314
L_6315:
	jp pinta_el_reloj		;6315   ; y a repintarlo
L_6318:
	ld a,(0e52eh)		;6318   ; (0xE52E) distinto de cero: hay algo en marcha, el final espera
	and a			;631b
	ret nz			;631c
	ld a,(0e0f0h)		;631d   ; y si ya habia gol pendiente
	and 003h		;6320
	ret nz			;6322   ; tampoco: un aviso cada vez
	ld a,004h		;6323   ; el bit 2 de (0xE0F0) es "se acabo el tiempo"
	ld (0e0f0h),a		;6325
	ld a,02bh		;6328   ; y el 0x2B es el pitido final
	jp pide_un_sonido		;632a

; ----------------------------------------------------------------------
; ===== LA CELEBRACION =====
; ----------------------------------------------------------------------
reanuda_tras_el_gol:
	ld a,(0e0f0h)		;632d   ; el bit 0 de (0xE0F0) dice cual de los dos ha marcado
	rra			;6330
	ld a,001h		;6331
	jr nc,L_6336		;6333
	dec a			;6335
L_6336:
	ld (0e527h),a		;6336   ; y ese pasa a ser el equipo al que sigue la camara
	ld hl,0e10dh		;6339   ; el +0x0D de la primera ficha
	ld b,00ch		;633c   ; las doce
L_633E:
	ld (hl),000h		;633e
	ld de,00020h		;6340   ; de 32 en 32, que es lo que mide una ficha
	add hl,de			;6343
	djnz L_633E		;6344
	xor a			;6346
	ld (0e33dh),a		;6347
	ld (0e35dh),a		;634a
	ld (ix+00dh),a		;634d   ; y el +0x0D de la que traiga IX
	call lleva_la_pelota_a_sus_sprites		;6350
	call L_578A		;6353
	call L_76DF		;6356
	call L_71FD		;6359
	jp L_763B		;635c
pon_a_celebrar:		; pone a los seis del equipo que ha marcado en modo festejo
	ld a,(0e0f0h)		;635f   ; otra vez quien ha marcado
	rra			;6362
	ld ix,0e1c0h		;6363   ; los seis del segundo equipo empiezan en 0xE1C0, que es 0xE100 mas seis fichas
	ld c,005h		;6367
	jr nc,L_6371		;6369
	ld ix,0e100h		;636b   ; y los del primero, en 0xE100
	ld c,001h		;636f
L_6371:
	ld b,006h		;6371   ; seis por equipo
L_6373:
	ld (ix+00ch),c		;6373   ; el +0x0C, que es el modo en que se mueve la ficha
	ld hl,06394h		;6376   ; y el paso de animacion sale de la tabla de 0x6394
	ld a,b			;6379
	dec a			;637a   ; uno por jugador
	call suma_a_hl		;637b
	ld a,(hl)			;637e
	ld (ix+01ch),a		;637f   ; al +0x1C
	ld de,00020h		;6382   ; la ficha siguiente
	add ix,de		;6385
	djnz L_6373		;6387
	ld a,(0e554h)		;6389   ; (0xE554) es el que ha marcado...
	call L_A201		;638c
	ld (ix+01ch),000h		;638f   ; ...y a ese se le pone el paso 0: su animacion es aparte de la de sus companeros
	ret			;6393

; ----------------------------------------------------------------------
; DATOS tablas_de_animacion: tres: seis bytes que van a (ix+0x1C) de los seis
;   jugadores, 32 parejas de [patron, incremento de Y], y el ciclo de andar de
;   cuatro pasos 07, 08, 07, 08
;   0x6394..0x63de  (74 bytes)
DATA_tablas_de_animacion:
	defb 000h	; 6394
	defb 001h	; 6395
	defb 002h	; 6396
	defb 003h	; 6397
	defb 000h	; 6398
	defb 001h	; 6399
	defb 007h	; 639a
	defb 000h	; 639b
	defb 007h	; 639c
	defb 000h	; 639d
	defb 007h	; 639e
	defb 000h	; 639f
	defb 008h	; 63a0
	defb 000h	; 63a1
	defb 008h	; 63a2
	defb 000h	; 63a3
	defb 008h	; 63a4
	defb 000h	; 63a5
	defb 007h	; 63a6
	defb 000h	; 63a7
	defb 007h	; 63a8
	defb 000h	; 63a9
	defb 007h	; 63aa
	defb 000h	; 63ab
	defb 008h	; 63ac
	defb 000h	; 63ad
	defb 008h	; 63ae
	defb 000h	; 63af
	defb 008h	; 63b0
	defb 000h	; 63b1
	defb 009h	; 63b2
	defb 0feh	; 63b3
	defb 009h	; 63b4
	defb 0fdh	; 63b5
	defb 009h	; 63b6
	defb 0fch	; 63b7
	defb 009h	; 63b8
	defb 0fdh	; 63b9
	defb 009h	; 63ba
	defb 0feh	; 63bb
	defb 009h	; 63bc
	defb 0ffh	; 63bd
	defb 009h	; 63be
	defb 000h	; 63bf
	defb 009h	; 63c0
	defb 000h	; 63c1
	defb 009h	; 63c2
	defb 000h	; 63c3
	defb 009h	; 63c4
	defb 000h	; 63c5
	defb 009h	; 63c6
	defb 000h	; 63c7
	defb 009h	; 63c8
	defb 000h	; 63c9
	defb 009h	; 63ca
	defb 000h	; 63cb
	defb 009h	; 63cc
	defb 000h	; 63cd
	defb 009h	; 63ce
	defb 001h	; 63cf
	defb 009h	; 63d0
	defb 002h	; 63d1
	defb 009h	; 63d2
	defb 003h	; 63d3
	defb 009h	; 63d4
	defb 004h	; 63d5
	defb 007h	; 63d6
	defb 003h	; 63d7
	defb 007h	; 63d8
	defb 002h	; 63d9
	defb 007h	; 63da
	defb 008h	; 63db
	defb 007h	; 63dc
	defb 008h	; 63dd

; ======================================================================
; CODIGO 0x63de..0x652b  (333 bytes)
; ======================================================================


corre_la_celebracion:		; los cinco corren a un lado y el goleador hace lo suyo
	ld a,(0e0f0h)		;63de   ; quien ha marcado
	rra			;63e1
	ld hl,0e10ah		;63e2   ; el +0x0A del primero de un equipo...
	jr c,L_63E9		;63e5
	ld l,0cah		;63e7   ; ...o del otro
L_63E9:
	ld b,006h		;63e9
L_63EB:
	ld a,(hl)			;63eb   ; 0xE0 en el +0x0A es la marca de ficha aparcada
	cp 0e0h		;63ec
	jr nz,L_63F9		;63ee   ; en cuanto una no lo esta, hay celebracion en marcha
	ld de,00020h		;63f0
	add hl,de			;63f3
	djnz L_63EB		;63f4
	jp marca_el_fin_de_la_celebracion		;63f6   ; y con las seis aparcadas, la celebracion ha terminado
L_63F9:
	ld a,(0e0f0h)		;63f9
	rra			;63fc
	ld ix,0e100h		;63fd
	jr c,L_6407		;6401
	ld ix,0e1c0h		;6403
L_6407:
	ld b,006h		;6407
L_6409:
	ld a,(ix+015h)		;6409   ; el numero del jugador
	ld hl,0e554h		;640c
	cp (hl)			;640f   ; si es el goleador, se le salta: su animacion va aparte
	jr z,L_644F		;6410
	ld a,(ix+00ah)		;6412
	cp 0e0h		;6415   ; y a los aparcados tambien
	jr z,L_644F		;6417
	ld a,(0e003h)		;6419   ; un paso de animacion cada cuatro cuadros
	and 003h		;641c
	jr nz,L_6436		;641e
	ld a,(ix+01ch)		;6420
	inc a			;6423
	cp 004h		;6424   ; cuatro dibujos tiene el ciclo de correr
	jr nz,L_6429		;6426
	xor a			;6428   ; y vuelve al primero
L_6429:
	ld (ix+01ch),a		;6429
	ld hl,063dah		;642c   ; la tabla de los cuatro patrones
	call suma_a_hl		;642f
	ld a,(hl)			;6432
	ld (ix+00dh),a		;6433   ; al +0x0D, que es el dibujo con el que se estampa la ficha
L_6436:
	ld l,(ix+006h)		;6436   ; la X entera, de 16 bits
	ld h,(ix+007h)		;6439
	ld a,(0e0f0h)		;643c
	rra			;643f
	ld de,00002h		;6440   ; dos pixeles hacia un lado...
	jr c,L_6448		;6443
	ld de,0fffeh		;6445   ; ...o hacia el otro, segun quien haya marcado: cada equipo festeja hacia su campo
L_6448:
	add hl,de			;6448
	ld (ix+006h),l		;6449   ; y de vuelta a la ficha
	ld (ix+007h),h		;644c
L_644F:
	ld de,00020h		;644f
	add ix,de		;6452
	djnz L_6409		;6454

; ----------------------------------------------------------------------
; ----- y el goleador, aparte -----
; ----------------------------------------------------------------------
	ld a,(0e0f0h)		;6456
	rra			;6459
	ld a,(0e554h)		;645a   ; el numero del que ha marcado
	jr c,L_6465		;645d
	cp 006h		;645f   ; los seis primeros son de un equipo y los seis siguientes del otro...
	jr c,L_64BB		;6461
	jr L_6469		;6463
L_6465:
	cp 006h		;6465
	jr nc,L_64BB		;6467   ; ...asi que un goleador del equipo que no toca no tiene celebracion propia
L_6469:
	call L_A201		;6469   ; IX a su ficha
	ld a,(ix+00ah)		;646c
	cp 0e0h		;646f
	jp z,L_64BB		;6471   ; aparcado, no hay nada que animar
	ld a,(ix+01ch)		;6474
	inc a			;6477
	cp 020h		;6478   ; su animacion es de 32 pasos, ocho veces mas larga que la de correr
	jr nz,L_647D		;647a
	xor a			;647c
L_647D:
	ld (ix+01ch),a		;647d
	ld hl,0639ah		;6480
	add a,a			;6483
	call suma_a_hl		;6484   ; dos bytes por paso
	ld a,(hl)			;6487
	ld (ix+00dh),a		;6488   ; el primero es el dibujo
	ex de,hl			;648b
	inc de			;648c
	ld a,(de)			;648d   ; y el segundo, cuanto sube o baja
	ld c,a			;648e
	ld a,(ix+004h)		;648f
	add a,c			;6492   ; que se suma a la altura: por eso el goleador da saltos y los otros no
	ld (ix+004h),a		;6493
	ld bc,00001h		;6496   ; un pixel entero hacia un lado...
	ld d,080h		;6499
	ld a,(0e0f0h)		;649b
	rra			;649e
	jr c,L_64A6		;649f
	ld bc,0fffeh		;64a1   ; ...o dos hacia el otro
	ld d,080h		;64a4
L_64A6:
	ld a,(ix+005h)		;64a6   ; el +5 es la parte FINA de la X: la posicion se lleva en 24 bits
	add a,d			;64a9
	ld (ix+005h),a		;64aa   ; medio pixel por cuadro
	ld l,(ix+006h)		;64ad
	ld h,(ix+007h)		;64b0
	adc hl,bc		;64b3   ; y lo que se desborde de la fraccion entra aqui, con el `adc`
	ld (ix+006h),l		;64b5
	ld (ix+007h),h		;64b8
L_64BB:
	call lleva_la_pelota_a_sus_sprites		;64bb   ; la pelota a sus sprites
	call pasa_los_doce_a_la_ventana		;64be
	call guarda_el_fondo_del_bando		;64c1
	call estampa_el_bando_en_el_mapa		;64c4
	call pon_el_bando_en_treinta_sprites		;64c7
	jp L_5796		;64ca
marca_el_fin_de_la_celebracion:
	ld a,001h		;64cd
	ld (0e308h),a		;64cf   ; (0xE308) a uno: las seis fichas estan aparcadas y el juego puede seguir
	ret			;64d2
pon_a_los_seis_en_reposo:
	ld hl,0e10ch		;64d3   ; el +0x0C de la primera ficha de un equipo...
	ld a,(0e0f0h)		;64d6
	rra			;64d9
	jr nc,L_64DE		;64da
	ld l,0cch		;64dc   ; ...o de la del otro
L_64DE:
	push af			;64de   ; la respuesta se guarda, que hace falta otra vez abajo
	ld b,006h		;64df
L_64E1:
	ld (hl),003h		;64e1   ; modo 3
	inc hl			;64e3
	ld (hl),005h		;64e4   ; y dibujo 5: quietos y de frente
	ld de,0001fh		;64e6   ; 0x1F porque el `inc hl` de arriba ya avanzo uno
	add hl,de			;64e9
	djnz L_64E1		;64ea
	pop af			;64ec
	ld hl,0e33dh		;64ed
	jr nc,L_64F4		;64f0
	ld l,05dh		;64f2
L_64F4:
	ld (hl),00ah		;64f4   ; y 0x0A al sprite del equipo que toque
	ret			;64f6
parpadea_el_marcador:
	ld a,(0e003h)		;64f7
	bit 3,a		;64fa   ; el bit 3 del contador de cuadros: ocho cuadros con uno y ocho con el otro
	ld a,00ah		;64fc
	jr nz,L_6501		;64fe   ; y el 0x0A o el 0x0B, que son los dos dibujos del destello
	inc a			;6500
L_6501:
	ld (0e33dh),a		;6501
	ld (0e35dh),a		;6504
	ret			;6507
lleva_la_pelota_a_sus_sprites:
	ld hl,(0e2afh)		;6508   ; la posicion de la pelota
	ld (0e408h),hl		;650b   ; a sus dos sprites, que van en pareja
	ld (0e40ch),hl		;650e
	ld hl,(0e2b3h)		;6511   ; y las dos alturas de la sombra
	ld (0e40ah),hl		;6514
	ld hl,(0e2b5h)		;6517
	ld (0e40eh),hl		;651a
	ret			;651d

; ----------------------------------------------------------------------
; ===== LA TANDA DE PENALTIS =====
; ----------------------------------------------------------------------
un_cuadro_de_los_penaltis:
	call copia_los_sprites		;651e   ; los sprites del cuadro anterior, lo primero
	ld hl,06a03h		;6521   ; la vuelta se apila a mano: los pasos salen por 0x6A03 y no por aqui
	push hl			;6524
	ld a,(0e310h)		;6525   ; (0xE310) es el paso de la tanda
	call despacha		;6528   ; y cada uno tiene su rutina en la tabla que va pegada detras

; ----------------------------------------------------------------------
; DATOS pasos_de_la_tanda_de_penaltis: 6 entradas, repartidas por (0xE310)
;   desde 0x6528. La vuelta se apila a mano en 0x6524, asi que los seis pasos
;   salen por 0x6A03 y no por quien los llamo
;   0x652b..0x6537  (12 bytes)
DATA_pasos_de_la_tanda_de_penaltis:
	defw 06537h,0654dh,06555h,06584h,06618h,0670ch	; 652b

; ======================================================================
; CODIGO 0x6537..0x6604  (205 bytes)
; ======================================================================


penalti_1_prepara:
	ld hl,0e312h		;6537   ; (0xE312) es la espera
	dec (hl)			;653a
	ret nz			;653b   ; hasta que se agote, nada
	ld a,028h		;653c   ; el 0x28 anuncia el lanzamiento
	call pide_un_sonido		;653e
	ld a,020h		;6541   ; 0x20 cuadros para el paso siguiente
	ld (0e312h),a		;6543
	add a,a			;6546   ; y el doble para (0xE004), que es la espera larga
	ld (0e004h),a		;6547
	jp pasa_al_paso_siguiente		;654a
penalti_2_espera:
	ld hl,0e004h		;654d
	dec (hl)			;6550   ; se agota la espera larga
	ret nz			;6551   ; y hasta entonces no se pasa de paso
	jp pasa_al_paso_siguiente		;6552
penalti_3_mueve_la_mira:
	ld hl,0e312h		;6555
	dec (hl)			;6558   ; la espera de este paso
	jr z,penalti_alarga_la_espera		;6559   ; agotada, se pasa al disparo automatico
	call mueve_la_mira		;655b   ; la mira, un paso
	ld a,(0e5a1h)		;655e   ; (0xE5A1) baja: es la carrerilla del lanzador
	sub 001h		;6561
	ld (0e5a1h),a		;6563
	ld a,(0e003h)		;6566   ; el contador de cuadros
	ld c,a			;6569
	and 004h		;656a   ; su bit 2: cuatro cuadros con una pierna...
	ld a,001h		;656c
	jr z,L_6571		;656e
	inc a			;6570   ; ...y cuatro con la otra
L_6571:
	ld (0e5a4h),a		;6571   ; al dibujo del lanzador
	ld a,(0e002h)		;6574
	bit 6,a		;6577   ; el bit 6 de (0xE002) distingue quien lanza
	ret z			;6579   ; y si no toca, aqui se acaba
	jp suena_el_paso		;657a
penalti_alarga_la_espera:
	ld a,050h		;657d
	ld (0e312h),a		;657f   ; 0x50 cuadros mas antes del disparo forzado
	jr pasa_al_paso_siguiente		;6582

; ----------------------------------------------------------------------
; ----- el disparo -----
; ----------------------------------------------------------------------
penalti_4_dispara:
	call mueve_la_mira		;6584   ; la mira sigue moviendose mientras no se dispare
	ld a,(0e002h)		;6587
	bit 6,a		;658a   ; otra vez el bit 6: quien tiene el turno
	jr nz,L_65A1		;658c
	ld a,(0e0fch)		;658e   ; (0xE0FC) alterna los dos bandos en la tanda
	rra			;6591
	ld de,0e006h		;6592   ; y segun eso se lee un mando...
	jr nc,L_659A		;6595
	ld de,0e008h		;6597   ; ...o el otro
L_659A:
	push de			;659a
	call la_maquina_lanza		;659b
	pop hl			;659e
	jr L_65B7		;659f
L_65A1:
	ld a,(0e0fch)		;65a1
	rra			;65a4
	ld hl,0e006h		;65a5   ; en el otro turno el reparto es al reves
	jr nc,L_65B7		;65a8
	ld a,(0e002h)		;65aa
	bit 5,a		;65ad   ; el bit 5 dice si hay segundo jugador humano
	ld de,0e008h		;65af
	push de			;65b2
	call z,la_maquina_lanza		;65b3   ; y sin el, la maquina apunta sola
	pop hl			;65b6
L_65B7:
	ld a,(hl)			;65b7
	and 010h		;65b8   ; el bit 4 es el disparo
	jr nz,L_65CB		;65ba   ; pulsado, se tira ya
	ld hl,0e312h		;65bc
	ld a,(hl)			;65bf   ; y si no, se sigue gastando la espera
	and a			;65c0
	jr z,L_65C5		;65c1
	dec (hl)			;65c3
	ret nz			;65c4   ; mientras quede, no pasa nada
L_65C5:
	ld a,(0e313h)		;65c5
	cp 013h		;65c8   ; y en la posicion 19, la ultima, se dispara solo aunque nadie pulse
	ret nz			;65ca

; ----------------------------------------------------------------------
; ----- la mira se convierte en angulo -----
; ----------------------------------------------------------------------
L_65CB:
	ld a,(0e313h)		;65cb   ; la posicion de la mira, de 0 a 19
	ld hl,06604h		;65ce   ; la tabla de veinte angulos: de -27 a +30, de tres en tres
	call suma_a_hl		;65d1
	ld l,(hl)			;65d4
	bit 7,l		;65d5   ; el bit 7 dice si el angulo es negativo...
	ld h,0ffh		;65d7   ; ...y estas tres lineas le extienden el signo a 16 bits
	jr nz,L_65DC		;65d9
	inc h			;65db
L_65DC:
	add hl,hl			;65dc   ; por dieciseis: la velocidad se lleva en dieciseisavos de pixel
	add hl,hl			;65dd
	add hl,hl			;65de
	add hl,hl			;65df
	ld (0e2a7h),hl		;65e0   ; y ese es el desvio lateral del disparo
	ld hl,0fe00h		;65e3   ; 0xFE00 es la velocidad de subida: negativa, o sea hacia arriba
	ld (0e2a2h),hl		;65e6
	ld hl,00040h		;65e9   ; (0xE2AB) = 0x40, el empuje hacia la porteria
	ld (0e2abh),hl		;65ec
	ld hl,00000h		;65ef   ; y las dos que quedan, a cero
	ld (0e2adh),hl		;65f2
	ld a,003h		;65f5   ; el dibujo 3 del lanzador: el del pie ya en la pelota
	ld (0e5a4h),a		;65f7
	ld a,057h		;65fa   ; y el 0x57, que es el golpe
	call pide_un_sonido_siempre		;65fc
pasa_al_paso_siguiente:
	ld hl,0e310h		;65ff
	inc (hl)			;6602   ; (0xE310) sube un paso
	ret			;6603

; ----------------------------------------------------------------------
; DATOS velocidades_del_balon: veinte valores con signo en progresion de tres,
;   de -27 a +30; 0x65CE los lee, extiende el signo con `bit 7,l` y los
;   multiplica por 16 antes de dejarlos en (0xE2A7)
;   0x6604..0x6618  (20 bytes)
DATA_velocidades_del_balon:
	defb 0e5h	; 6604
	defb 0e8h	; 6605
	defb 0ebh	; 6606
	defb 0eeh	; 6607
	defb 0f1h	; 6608
	defb 0f4h	; 6609
	defb 0f7h	; 660a
	defb 0fah	; 660b
	defb 0fdh	; 660c
	defb 000h	; 660d
	defb 003h	; 660e
	defb 006h	; 660f
	defb 009h	; 6610
	defb 00ch	; 6611
	defb 00fh	; 6612
	defb 012h	; 6613
	defb 015h	; 6614
	defb 018h	; 6615
	defb 01bh	; 6616
	defb 01eh	; 6617

; ======================================================================
; CODIGO 0x6618..0x6727  (271 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----- el vuelo, y como acaba -----
; ----------------------------------------------------------------------
vuela_la_pelota_del_penalti:		; reparte por zonas de la mira: gol, palo o fuera
	call mueve_al_portero_del_penalti		;6618   ; primero el portero, que se mueve en paralelo
	ld a,(0e316h)		;661b   ; (0xE316) distinto de cero: la jugada ya ha terminado
	and a			;661e
	jp nz,para_la_pelota_del_penalti		;661f
	ld a,(0e313h)		;6622   ; y si no, la posicion de la mira dice por donde va
	and a			;6625
	jr z,L_665D		;6626   ; la 0 se va fuera por un lado
	cp 001h		;6628
	jr z,L_667F		;662a   ; la 1
	cp 004h		;662c   ; de la 2 a la 3
	jp c,L_66C2		;662e
	cp 00fh		;6631   ; de la 4 a la 14, que es el ancho de la porteria
	jr c,L_663E		;6633
	cp 011h		;6635   ; de la 15 a la 16
	jp c,L_66C2		;6637
	jr z,L_667F		;663a   ; la 17
	jr L_665D		;663c   ; y de la 18 en adelante, fuera por el otro lado
L_663E:
	ld a,(0e2a1h)		;663e   ; (0xE2A1) es la altura de la pelota
	cp 02bh		;6641
	ret nc			;6643   ; por encima de 0x2B pasa por encima del larguero
	ld a,047h		;6644   ; el 0x47 es la red
	call pide_un_sonido_siempre		;6646
	ld a,02bh		;6649
	ld (0e2a1h),a		;664b   ; y la pelota se queda clavada en el fondo
	ld a,(0e0fch)		;664e   ; (0xE0FC) dice de quien era el turno
	rra			;6651
	ld a,001h		;6652
	jr nc,L_6657		;6654
	inc a			;6656
L_6657:
	ld (0e0f0h),a		;6657   ; y (0xE0F0) apunta el gol al bando que toca
	jp para_la_pelota_del_penalti		;665a
L_665D:
	ld a,(0e2a1h)		;665d   ; la altura otra vez
	cp 002h		;6660   ; por debajo de 2 la pelota ya esta en el suelo
	jr c,L_6674		;6662
	cp 020h		;6664
	ret nc			;6666   ; y por encima de 0x20 todavia vuela alto
	ld hl,(0e2a2h)		;6667   ; en medio, cae: la velocidad vertical baja de 16 en 16
	ld de,00010h		;666a
	and a			;666d
	sbc hl,de		;666e
	ld (0e2a2h),hl		;6670
	ret			;6673
L_6674:
	ld a,0e0h		;6674   ; al tocar suelo, la pelota se aparca en 0xE0
	ld (0e2a1h),a		;6676
	xor a			;6679
	ld (0e0f0h),a		;667a   ; y (0xE0F0) a cero: penalti fallado, no hay gol que apuntar
	jr para_la_pelota_del_penalti		;667d
L_667F:
	ld c,a			;667f   ; el 0x0B es el poste
	ld a,(0e314h)		;6680   ; (0xE314) marca que ya reboto una vez: no se rebota dos
	rra			;6683
	jr c,L_66B4		;6684
	ld a,(0e2a1h)		;6686   ; y solo por encima de 0x40, que es donde esta el marco
	cp 040h		;6689
	ret nc			;668b
	ld a,001h		;668c
	ld (0e314h),a		;668e
	ld a,00bh		;6691
	call pide_un_sonido_siempre		;6693
	ld a,c			;6696
	cp 003h		;6697
	ld hl,0ff80h		;6699
	jr c,L_66A1		;669c
	ld hl,00080h		;669e
L_66A1:
	ld (0e2a7h),hl		;66a1   ; el rebote: se le cambia el traves...
	ld hl,00100h		;66a4   ; ...y se le pone un empuje fijo hacia atras, con su gravedad
	ld (0e2a2h),hl		;66a7
	dec hl			;66aa
	ld (0e2abh),hl		;66ab
	ld hl,0fffch		;66ae
	ld (0e2adh),hl		;66b1
L_66B4:
	ld a,(0e2aah)		;66b4   ; el bit alto de (0xE2AA): la pelota ya salio de la pantalla
	rla			;66b7
	ret nc			;66b8
	xor a			;66b9   ; se olvida el vuelo y el gol, y la jugada se para
	ld (0e2aah),a		;66ba
	ld (0e0f0h),a		;66bd
	jr para_la_pelota_del_penalti		;66c0

; ----------------------------------------------------------------------
; ===== EL PENALTI: la pelota contra el marco de la porteria =====
; ----------------------------------------------------------------------
L_66C2:
	cp 002h		;66c2   ; las cuatro alturas del larguero, una por sitio de la porteria: B es donde queda la pelota y C la altura a la que pega
	ld bc,05039h		;66c4
	jr z,L_66D8		;66c7
	cp 003h		;66c9
	ld c,031h		;66cb
	jr z,L_66D8		;66cd
	cp 010h		;66cf
	ld bc,0a837h		;66d1
	jr z,L_66D8		;66d4
	ld c,02fh		;66d6
L_66D8:
	ld a,(0e2a1h)		;66d8   ; por debajo de esa altura no hay larguero
	cp c			;66db
	ret nc			;66dc
	ld a,047h		;66dd   ; el 0x47 es el golpe contra el marco
	call pide_un_sonido_siempre		;66df
	ld a,02bh		;66e2   ; y la pelota cae clavada en 0x2B, justo debajo
	ld (0e2a1h),a		;66e4
	ld a,b			;66e7
	ld (0e2a5h),a		;66e8
	ld a,(0e0fch)		;66eb   ; (0xE0FC) dice quien tira, y de ahi sale el rebote
	rra			;66ee
	ld a,001h		;66ef
	jr nc,L_66F4		;66f1
	inc a			;66f3
L_66F4:
	ld (0e0f0h),a		;66f4
para_la_pelota_del_penalti:
	ld hl,00000h		;66f7   ; las cinco variables de vuelo a cero de golpe
	ld (0e2a7h),hl		;66fa
	ld (0e2a2h),hl		;66fd
	ld (0e2abh),hl		;6700
	ld (0e2adh),hl		;6703
	ld (0e2a9h),hl		;6706
	jp pasa_al_paso_siguiente		;6709   ; y a por el paso siguiente
cierra_la_tanda:
	call mueve_al_portero_del_penalti		;670c
	ld a,(0e315h)		;670f
	cp 007h		;6712   ; el paso 7 del portero es el ultimo
	jr z,L_6718		;6714
	and a			;6716   ; y con cualquier otro que no sea el 0, todavia no
	ret nz			;6717
L_6718:
	xor a			;6718
	ld (0e0f8h),a		;6719   ; (0xE0F8) a cero: se sale de los penaltis
L_671C:
	ret			;671c
mueve_al_portero_del_penalti:
	ld hl,0689eh		;671d   ; la vuelta, apilada a mano
	push hl			;6720
	ld a,(0e315h)		;6721   ; (0xE315) es el paso del portero
	call despacha		;6724

; ----------------------------------------------------------------------
; DATOS pasos_del_portero_del_penalti: 8 entradas, repartidas por (0xE315)
;   desde 0x6724; el paso 7 es el ultimo y es el que cierra la tanda. La
;   vuelta tambien va apilada a mano, por 0x689E
;   0x6727..0x6737  (16 bytes)
DATA_pasos_del_portero_del_penalti:
	defw 06737h,0677bh,067b1h,067c4h,067f8h,06806h,06817h,0671ch	; 6727

; ======================================================================
; CODIGO 0x6737..0x681e  (231 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL PORTERO DEL PENALTI =====
; ----------------------------------------------------------------------
lee_la_estirada:		; el mando del portero decide a que lado se tira
	ld a,(0e002h)		;6737
	bit 6,a		;673a   ; el bit 6 de (0xE002) dice a quien le toca parar
	jr nz,L_6751		;673c
	ld a,(0e0fch)		;673e   ; (0xE0FC) alterna los turnos de la tanda
	rra			;6741
	ld de,0e006h		;6742   ; y con eso se elige el mando que para...
	jr c,L_674A		;6745
	ld de,0e008h		;6747   ; ...que es siempre el contrario al que tira
L_674A:
	push de			;674a
	call la_maquina_para		;674b   ; mientras, el otro apunta
	pop hl			;674e
	jr L_6767		;674f
L_6751:
	ld a,(0e0fch)		;6751
	rra			;6754
	ld hl,0e006h		;6755
	jr c,L_6767		;6758
	ld a,(0e002h)		;675a
	bit 5,a		;675d
	ld de,0e008h		;675f
	push de			;6762
	call z,la_maquina_para		;6763   ; con un solo jugador humano, la maquina para sola
	pop hl			;6766
L_6767:
	ld a,(hl)			;6767
	and 00ch		;6768   ; los bits 2 y 3: izquierda y derecha
	ret z			;676a   ; sin ninguno de los dos, el portero se queda en el centro
	bit 2,a		;676b   ; el bit 2 es un lado...
	ld hl,0e315h		;676d
	jr nz,L_6774		;6770
	inc (hl)			;6772   ; ...y el otro se lleva dos pasos mas: los cuatro pasos de estirada van en dos parejas
	inc (hl)			;6773
L_6774:
	inc (hl)			;6774
	ld a,020h		;6775
	ld (0e5a9h),a		;6777   ; 0x20 cuadros dura la estirada
	ret			;677a
estirada_a_un_lado:
	ld a,001h		;677b   ; el dibujo 1
	call avanza_la_estirada_reflejada		;677d
	cp 010h		;6780   ; hasta que la cuenta baje de 0x10 no se cambia de paso
	ret nc			;6782
	jr pasa_al_paso_del_portero		;6783
avanza_la_estirada_reflejada:		; el vector de la tabla, con la componente horizontal cambiada de signo
	ld hl,0e5aah		;6785   ; (0xE5AA) es el dibujo del portero
	ld (hl),a			;6788
	dec hl			;6789
	dec (hl)			;678a   ; (0xE5A9) es la cuenta de la estirada, que baja
	ld a,(hl)			;678b
	push af			;678c
	add a,a			;678d   ; por cuatro: dos vectores de 16 bits por paso
	add a,a			;678e
	ld hl,0681eh		;678f   ; la tabla de vectores
	call suma_a_hl		;6792
	ld c,(hl)			;6795   ; el primero, en BC
	inc hl			;6796
	ld b,(hl)			;6797
	inc hl			;6798
	ld e,(hl)			;6799   ; y el segundo, en DE
	inc hl			;679a
	ld d,(hl)			;679b
	ex de,hl			;679c
	call L_A211		;679d   ; y aqui esta el espejo: se niega, para que la misma tabla sirva para el otro lado
	ex de,hl			;67a0
	pop af			;67a1
	ld hl,(0e5a5h)		;67a2   ; la posicion del portero, a lo ancho
	add hl,bc			;67a5   ; mas el vector
	ld (0e5a5h),hl		;67a6
	ld hl,(0e5a7h)		;67a9   ; y a lo alto
	add hl,de			;67ac
	ld (0e5a7h),hl		;67ad
	ret			;67b0
estirada_a_un_lado_2:
	ld a,002h		;67b1   ; el dibujo 2
	call avanza_la_estirada_reflejada		;67b3
	and a			;67b6
	ret nz			;67b7   ; hasta que la cuenta llegue a cero, nada
	ld a,020h		;67b8
	ld (0e5a9h),a		;67ba   ; y otros 0x20 cuadros
	ld hl,0e315h		;67bd   ; tres pasos de golpe: el portero ya esta en el suelo
	inc (hl)			;67c0
	inc (hl)			;67c1
	inc (hl)			;67c2
	ret			;67c3
estirada_al_otro_lado:
	ld a,003h		;67c4   ; el dibujo 3
	call avanza_la_estirada		;67c6
	cp 010h		;67c9
	ret nc			;67cb   ; misma cuenta, mismo umbral
pasa_al_paso_del_portero:
	ld hl,0e315h		;67cc
	inc (hl)			;67cf   ; (0xE315) sube
	ret			;67d0
avanza_la_estirada:		; la misma tabla que 0x6785, pero sin reflejar
	ld hl,0e5aah		;67d1   ; el dibujo
	ld (hl),a			;67d4
	dec hl			;67d5
	dec (hl)			;67d6   ; la misma cuenta
	ld a,(hl)			;67d7
	push af			;67d8
	add a,a			;67d9
	add a,a			;67da
	ld hl,0681eh		;67db   ; la MISMA tabla que la del otro lado
	call suma_a_hl		;67de
	ld c,(hl)			;67e1   ; y aqui el vector se usa tal cual: esa es la unica diferencia entre las dos rutinas
	inc hl			;67e2
	ld b,(hl)			;67e3
	inc hl			;67e4
	ld e,(hl)			;67e5
	inc hl			;67e6
	ld d,(hl)			;67e7
	pop af			;67e8
	ld hl,(0e5a5h)		;67e9   ; a lo ancho
	add hl,bc			;67ec
	ld (0e5a5h),hl		;67ed
	ld hl,(0e5a7h)		;67f0   ; y a lo alto
	add hl,de			;67f3
	ld (0e5a7h),hl		;67f4
	ret			;67f7
estirada_al_otro_lado_2:
	ld a,004h		;67f8   ; el dibujo 4
	call avanza_la_estirada		;67fa
	and a			;67fd
	ret nz			;67fe
	ld a,020h		;67ff
	ld (0e5a9h),a		;6801   ; y su cuenta
	jr pasa_al_paso_del_portero		;6804
el_portero_se_levanta:
	ld hl,0e5a9h		;6806
	dec (hl)			;6809   ; se agota la espera
	ret nz			;680a
	ld a,030h		;680b   ; (0xE5A6) = 0x30: de vuelta al centro de la porteria
	ld (0e5a6h),a		;680d
	ld (hl),020h		;6810   ; y la cuenta se rearma
	inc hl			;6812
	ld (hl),000h		;6813   ; con el dibujo 0, el de estar de pie
	jr pasa_al_paso_del_portero		;6815
espera_del_portero:
	ld hl,0e5a9h		;6817
	dec (hl)			;681a   ; solo gasta cuadros
	ret nz			;681b
	jr pasa_al_paso_del_portero		;681c

; ----------------------------------------------------------------------
; DATOS desplazamientos_del_balon: 32 entradas de cuatro bytes: dos palabras
;   con signo (dx, dy) que 0x678F y 0x67DB suman a la posicion del balon en
;   (0xE5A5) y (0xE5A7)
;   0x681e..0x689e  (128 bytes)
DATA_desplazamientos_del_balon:
	defw 00000h,00000h,00000h,00000h,00000h,00000h,00000h,00000h	; 681e
	defw 00000h,00000h,00000h,00000h,00000h,00000h,00000h,00000h	; 682e
	defw 00040h,00180h,00040h,00180h,00040h,00180h,00040h,00180h	; 683e
	defw 00040h,00180h,00040h,00180h,00040h,00180h,00400h,00800h	; 684e
	defw 00080h,00100h,00070h,00100h,00060h,00100h,00050h,00100h	; 685e
	defw 00040h,00100h,00020h,00100h,00010h,00100h,00000h,00100h	; 686e
	defw 00000h,00100h,00000h,000c0h,00000h,000c0h,0fff0h,000c0h	; 687e
	defw 0ffe0h,000c0h,0ffc0h,000c0h,0ffa0h,000c0h,0ff80h,00c00h	; 688e

; ======================================================================
; CODIGO 0x689e..0x6939  (155 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LA PARADA =====
; ----------------------------------------------------------------------
comprueba_la_parada:
	ld a,(0e316h)		;689e   ; (0xE316) distinto de cero: la jugada ya esta resuelta
	and a			;68a1
	jr nz,L_68D9		;68a2
	ld a,(0e2a1h)		;68a4   ; la altura de la pelota
	cp 040h		;68a7   ; solo se comprueba en 0x40, que es la altura a la que pasa por el portero
	ret nz			;68a9
	ld a,(0e5aah)		;68aa   ; el dibujo del portero
	cp 001h		;68ad   ; tirado a un lado, su alcance se corre cuatro pixeles...
	ld c,004h		;68af
	jr z,L_68BB		;68b1
	cp 003h		;68b3
	ld c,0fch		;68b5   ; ...y al otro lado, cuatro en el otro sentido
	jr z,L_68BB		;68b7
	ld c,000h		;68b9   ; y de pie, sin correccion
L_68BB:
	ld hl,0e2a5h		;68bb
	ld a,(0e5a8h)		;68be   ; donde esta el portero, mas su alcance
	add a,c			;68c1
	sub (hl)			;68c2   ; menos donde esta la pelota
	jr nc,L_68C7		;68c3
	neg		;68c5   ; el valor absoluto de la diferencia
L_68C7:
	cp 00ch		;68c7   ; doce pixeles: mas cerca que eso, la para
	ret nc			;68c9   ; y mas lejos, no llega
	ld a,01fh		;68ca   ; el 0x1F es el guantazo
	call pide_un_sonido_siempre		;68cc
	ld a,001h		;68cf
	ld (0e316h),a		;68d1   ; (0xE316) marca la jugada como resuelta
	ld a,0e0h		;68d4
	ld (0e3a8h),a		;68d6   ; y la pelota se aparca en 0xE0, fuera de la pantalla
L_68D9:
	ld a,(0e5aah)		;68d9
	and a			;68dc
	ld a,(0e5a6h)		;68dd   ; la altura del portero
	jr nz,L_68E4		;68e0
	add a,008h		;68e2   ; de pie va ocho pixeles mas alto que tirado
L_68E4:
	ld (0e2a1h),a		;68e4   ; y de ahi salen las dos coordenadas con las que se dibuja
	ld a,(0e5a8h)		;68e7
	ld (0e2a5h),a		;68ea
	ret			;68ed
mueve_la_mira:		; ocho pixeles por paso, veinte pasos y vuelta a empezar
	ld a,(0e311h)		;68ee
	add a,008h		;68f1   ; ocho pixeles por paso
	ld (0e311h),a		;68f3
	ld hl,0e313h		;68f6
	inc (hl)			;68f9   ; y (0xE313) cuenta el paso, de 0 a 19
	cp 0d0h		;68fa   ; en 0xD0 se ha acabado el recorrido
	ret nz			;68fc
	ld a,030h		;68fd   ; que vuelve a 0x30: de 0x30 a 0xD0 de ocho en ocho son los veinte pasos justos de la tabla de angulos
	ld (0e311h),a		;68ff
	xor a			;6902
	ld (0e313h),a		;6903   ; y el contador, a cero
	ret			;6906

; ----------------------------------------------------------------------
; ===== LA MAQUINA, TIRANDO =====
; ----------------------------------------------------------------------
la_maquina_lanza:		; elige la posicion de disparo segun el nivel y pulsa ella misma
	ld a,(0e317h)		;6907   ; (0xE317) es la posicion elegida...
	inc a			;690a   ; ...y el 0xFF significa que aun no ha elegido
	jr nz,L_692D		;690b
	ld a,(0e069h)		;690d   ; el nivel de juego
	cp 001h		;6910   ; el 1 tiene su tabla...
	ld hl,06939h		;6912
	jr z,L_6921		;6915
	cp 004h		;6917   ; ...del 2 al 3 otra...
	ld hl,06959h		;6919
	jr c,L_6921		;691c
	ld hl,06979h		;691e   ; ...y del 4 en adelante la tercera: la maquina apunta mejor cuanto mas alto el nivel
L_6921:
	ld a,(0e003h)		;6921
	and 01fh		;6924   ; los cinco bits bajos del contador de cuadros: 32 entradas, y de ahi sale el azar
	call suma_a_hl		;6926
	ld a,(hl)			;6929
	ld (0e317h),a		;692a   ; la posicion queda apuntada
L_692D:
	ld a,(0e317h)		;692d   ; y cuando la mira llega a ella...
	ld hl,0e313h		;6930
	cp (hl)			;6933
	ret nz			;6934
	ld a,010h		;6935   ; ...se pone el bit 4 en el mando: la maquina dispara pulsando, igual que un humano
	ld (de),a			;6937
	ret			;6938

; ----------------------------------------------------------------------
; DATOS tiros_de_la_maquina: tres tablas de 32 para el disparo en los
;   penaltis, una por tramo de nivel (1, 2-3, 4-5); se indexan con el contador
;   de cuadros y al coincidir con (0xE313) se mete el disparo en el mando
;   simulado
;   0x6939..0x6999  (96 bytes)
DATA_tiros_de_la_maquina:
	defb 002h	; 6939
	defb 003h	; 693a
	defb 004h	; 693b
	defb 005h	; 693c
	defb 006h	; 693d
	defb 007h	; 693e
	defb 008h	; 693f
	defb 009h	; 6940
	defb 00ah	; 6941
	defb 00bh	; 6942
	defb 00ch	; 6943
	defb 00dh	; 6944
	defb 00eh	; 6945
	defb 00fh	; 6946
	defb 010h	; 6947
	defb 002h	; 6948
	defb 003h	; 6949
	defb 004h	; 694a
	defb 005h	; 694b
	defb 006h	; 694c
	defb 007h	; 694d
	defb 008h	; 694e
	defb 009h	; 694f
	defb 00ah	; 6950
	defb 00bh	; 6951
	defb 00ch	; 6952
	defb 00dh	; 6953
	defb 00eh	; 6954
	defb 00fh	; 6955
	defb 010h	; 6956
	defb 002h	; 6957
	defb 003h	; 6958
	defb 002h	; 6959
	defb 003h	; 695a
	defb 004h	; 695b
	defb 005h	; 695c
	defb 006h	; 695d
	defb 007h	; 695e
	defb 008h	; 695f
	defb 009h	; 6960
	defb 00ah	; 6961
	defb 00bh	; 6962
	defb 00ch	; 6963
	defb 00dh	; 6964
	defb 00eh	; 6965
	defb 00fh	; 6966
	defb 010h	; 6967
	defb 002h	; 6968
	defb 003h	; 6969
	defb 004h	; 696a
	defb 005h	; 696b
	defb 006h	; 696c
	defb 007h	; 696d
	defb 00bh	; 696e
	defb 00ch	; 696f
	defb 00dh	; 6970
	defb 00eh	; 6971
	defb 00fh	; 6972
	defb 010h	; 6973
	defb 002h	; 6974
	defb 003h	; 6975
	defb 009h	; 6976
	defb 00fh	; 6977
	defb 010h	; 6978
	defb 002h	; 6979
	defb 003h	; 697a
	defb 004h	; 697b
	defb 005h	; 697c
	defb 006h	; 697d
	defb 007h	; 697e
	defb 008h	; 697f
	defb 009h	; 6980
	defb 00ah	; 6981
	defb 00bh	; 6982
	defb 00ch	; 6983
	defb 00dh	; 6984
	defb 00eh	; 6985
	defb 00fh	; 6986
	defb 010h	; 6987
	defb 002h	; 6988
	defb 003h	; 6989
	defb 004h	; 698a
	defb 005h	; 698b
	defb 00dh	; 698c
	defb 00eh	; 698d
	defb 00fh	; 698e
	defb 010h	; 698f
	defb 002h	; 6990
	defb 003h	; 6991
	defb 004h	; 6992
	defb 00eh	; 6993
	defb 00fh	; 6994
	defb 010h	; 6995
	defb 008h	; 6996
	defb 009h	; 6997
	defb 00ah	; 6998

; ======================================================================
; CODIGO 0x6999..0x69c7  (46 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LA MAQUINA, PARANDO =====
; ----------------------------------------------------------------------
la_maquina_para:		; elige a que altura se tira, y a que lado segun por donde vaya la mira
	ld a,(0e313h)		;6999   ; la posicion de la mira
	cp 009h		;699c   ; el 9 es el centro: ahi no hay a que lado tirarse
	ret z			;699e
	ld b,004h		;699f   ; a un lado el bit 2...
	jr c,L_69A5		;69a1
	ld b,008h		;69a3   ; ...y al otro el 3
L_69A5:
	ld c,a			;69a5   ; la posicion, a salvo
	ld a,(0e069h)		;69a6   ; y otra vez el nivel
	cp 001h		;69a9
	ld hl,069c7h		;69ab   ; una tabla por nivel, como en el disparo
	jr z,L_69BA		;69ae
	cp 004h		;69b0
	ld hl,069dbh		;69b2
	jr c,L_69BA		;69b5
	ld hl,069efh		;69b7
L_69BA:
	ld a,c			;69ba
	call suma_a_hl		;69bb   ; indexada por la posicion de la mira
	ld c,(hl)			;69be   ; la altura a la que este portero se lanza
	ld a,(0e2a1h)		;69bf   ; la altura de la pelota ahora
	cp c			;69c2
	ret nz			;69c3   ; y hasta que coincidan, quieto
	ld a,b			;69c4   ; y ahi la maquina "pulsa" izquierda o derecha en el mando
	ld (de),a			;69c5
	ret			;69c6

; ----------------------------------------------------------------------
; DATOS porteros_de_la_maquina: tres tablas de 20 para el movimiento del
;   portero, con el mismo reparto por nivel. Son veinte porque (0xE311) va de
;   0x30 a 0xD0 de ocho en ocho, que son veinte pasos justos
;   0x69c7..0x6a03  (60 bytes)
DATA_porteros_de_la_maquina:
	defb 050h	; 69c7
	defb 050h	; 69c8
	defb 050h	; 69c9
	defb 050h	; 69ca
	defb 050h	; 69cb
	defb 050h	; 69cc
	defb 050h	; 69cd
	defb 050h	; 69ce
	defb 048h	; 69cf
	defb 040h	; 69d0
	defb 048h	; 69d1
	defb 050h	; 69d2
	defb 050h	; 69d3
	defb 050h	; 69d4
	defb 050h	; 69d5
	defb 050h	; 69d6
	defb 050h	; 69d7
	defb 050h	; 69d8
	defb 050h	; 69d9
	defb 050h	; 69da
	defb 058h	; 69db
	defb 058h	; 69dc
	defb 058h	; 69dd
	defb 058h	; 69de
	defb 058h	; 69df
	defb 058h	; 69e0
	defb 058h	; 69e1
	defb 050h	; 69e2
	defb 048h	; 69e3
	defb 040h	; 69e4
	defb 048h	; 69e5
	defb 050h	; 69e6
	defb 058h	; 69e7
	defb 058h	; 69e8
	defb 058h	; 69e9
	defb 058h	; 69ea
	defb 058h	; 69eb
	defb 058h	; 69ec
	defb 058h	; 69ed
	defb 058h	; 69ee
	defb 060h	; 69ef
	defb 060h	; 69f0
	defb 060h	; 69f1
	defb 060h	; 69f2
	defb 060h	; 69f3
	defb 060h	; 69f4
	defb 058h	; 69f5
	defb 050h	; 69f6
	defb 048h	; 69f7
	defb 040h	; 69f8
	defb 048h	; 69f9
	defb 050h	; 69fa
	defb 058h	; 69fb
	defb 060h	; 69fc
	defb 060h	; 69fd
	defb 060h	; 69fe
	defb 060h	; 69ff
	defb 060h	; 6a00
	defb 060h	; 6a01
	defb 060h	; 6a02

; ======================================================================
; CODIGO 0x6a03..0x6bbb  (440 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LOS SPRITES DEL PENALTI =====
; ----------------------------------------------------------------------
dibuja_la_escena_del_penalti:
	ld hl,0e3a0h		;6a03   ; el primer sprite de la escena
	ld b,00dh		;6a06   ; trece
L_6A08:
	ld (hl),0e0h		;6a08   ; todos a 0xE0, o sea aparcados: lo que se vea se pondra abajo
	inc hl			;6a0a   ; de cuatro en cuatro, que es lo que ocupa un sprite
	inc hl			;6a0b
	inc hl			;6a0c
	inc hl			;6a0d
	djnz L_6A08		;6a0e
	exx			;6a10   ; el juego alterno de registros lleva la paleta durante todo el montaje
	ld a,(0e0fch)		;6a11   ; (0xE0FC) dice de quien es el turno...
	rra			;6a14
	ld de,0e056h		;6a15   ; ...y con eso se elige la camiseta del portero
	jr nc,L_6A1D		;6a18
	ld de,0e051h		;6a1a
L_6A1D:
	exx			;6a1d
	ld hl,084cah		;6a1e   ; la tabla de dibujos del portero
	ld (0e521h),hl		;6a21   ; (0xE521) es el apoyo donde se deja la tabla que se esta usando
	ld a,(0e5aah)		;6a24   ; el dibujo del portero
	add a,a			;6a27   ; dos bytes por puntero
	call suma_a_hl		;6a28
	ld e,(hl)			;6a2b
	inc hl			;6a2c
	ld d,(hl)			;6a2d
	ld hl,0e3ach		;6a2e   ; los sprites del portero empiezan aqui
	ld a,(0e5a6h)		;6a31   ; su altura, en C: es la que sale de (0xE5A6), la misma que compara la parada
	ld c,a			;6a34
	ld a,(0e5a8h)		;6a35   ; y su posicion a lo ancho, en B
	ld b,a			;6a38
	call monta_un_sprite		;6a39   ; cinco sprites: un portero de 32x32 pixeles con un trozo de mas
	call monta_un_sprite		;6a3c
	call monta_un_sprite		;6a3f
	call monta_un_sprite		;6a42
	call monta_un_sprite		;6a45

; ----------------------------------------------------------------------
; ----- la pelota -----
; ----------------------------------------------------------------------
	call tira_de_la_pelota_hacia_abajo		;6a48   ; la gravedad
	call suma_las_velocidades_de_la_pelota		;6a4b   ; y con ella, el movimiento
	ld hl,(0e2a0h)		;6a4e   ; la posicion de la pelota...
	ld de,(0e2a9h)		;6a51   ; ...menos la altura a la que vuela
	and a			;6a55
	sbc hl,de		;6a56
	ld a,h			;6a58   ; el byte alto es el pixel: la posicion se lleva con parte fina
	ld (0e2afh),a		;6a59
	ld a,(0e2a5h)		;6a5c   ; y a lo ancho, tal cual
	ld (0e2b0h),a		;6a5f
	ld hl,(0e2a7h)		;6a62   ; las tres velocidades: si las tres son cero...
	ld a,h			;6a65
	or l			;6a66
	ld hl,(0e2a2h)		;6a67
	or h			;6a6a
	or l			;6a6b
	ld hl,(0e2abh)		;6a6c
	or h			;6a6f
	or l			;6a70
	jr z,L_6A99		;6a71   ; ...la pelota esta quieta y no gira
	ld hl,0e29ah		;6a73   ; (0xE29A) cuenta cuadros para el giro
	inc (hl)			;6a76
	ld a,(hl)			;6a77
	and 00ch		;6a78   ; cuatro cuadros por dibujo
	rra			;6a7a
	rra			;6a7b
	cp 003h		;6a7c   ; y al tercero
	jr nz,L_6A82		;6a7e
	xor a			;6a80   ; vuelve al primero: la pelota tiene TRES dibujos, no cuatro
	ld (hl),a			;6a81
L_6A82:
	and a			;6a82
	ld hl,02c20h		;6a83   ; el primero...
	jr z,L_6A91		;6a86
	dec a			;6a88
	ld hl,03024h		;6a89   ; ...el segundo...
	jr z,L_6A91		;6a8c
	ld hl,03428h		;6a8e   ; ...y el tercero
L_6A91:
	ld a,l			;6a91
	ld (0e2b3h),a		;6a92   ; y los dos bytes van a los dos sprites que forman la pelota
	ld a,h			;6a95
	ld (0e2b5h),a		;6a96
L_6A99:
	ld hl,(0e2afh)		;6a99   ; la posicion de la pelota
	ld a,l			;6a9c
	sub 008h		;6a9d   ; ocho pixeles menos: los sprites se anclan por la esquina y la pelota se quiere centrada
	ld l,a			;6a9f
	ld (0e3a0h),hl		;6aa0   ; a sus dos sprites
	ld (0e3a4h),hl		;6aa3
	ld hl,(0e2b3h)		;6aa6   ; con sus dos dibujos
	ld (0e3a6h),hl		;6aa9
	ld hl,(0e2b5h)		;6aac
	ld (0e3a2h),hl		;6aaf
	ld a,(0e316h)		;6ab2   ; (0xE316): con la jugada resuelta, la pelota ya no se mueve
	and a			;6ab5
	jr nz,L_6AC9		;6ab6
	ld a,(0e2a1h)		;6ab8   ; la altura del rebote
	ld l,a			;6abb
	ld a,(0e2b0h)		;6abc
	ld h,a			;6abf
	ld (0e3a8h),hl		;6ac0   ; al sprite de la sombra
	ld hl,(0e2b7h)		;6ac3
	ld (0e3aah),hl		;6ac6
L_6AC9:
	ld l,050h		;6ac9   ; y el sprite de la mira, que va a media altura fija
	ld a,(0e311h)		;6acb
	ld h,a			;6ace
	ld (0e3c0h),hl		;6acf

; ----------------------------------------------------------------------
; ----- el lanzador -----
; ----------------------------------------------------------------------
	exx			;6ad2
	ld a,(0e0fch)		;6ad3   ; la misma pareja de paletas, pero para el otro equipo
	rra			;6ad6
	ld de,0e056h		;6ad7
	jr c,L_6ADF		;6ada
	ld de,0e051h		;6adc
L_6ADF:
	exx			;6adf
	ld hl,08492h		;6ae0   ; y otra tabla de dibujos, la del que tira
	ld (0e521h),hl		;6ae3
	ld a,(0e5a4h)		;6ae6   ; su dibujo, el que puso la carrerilla
	add a,a			;6ae9
	call suma_a_hl		;6aea
	ld e,(hl)			;6aed
	inc hl			;6aee
	ld d,(hl)			;6aef
	ld hl,0e390h		;6af0   ; sus sprites van al principio de la lista
	ld a,(0e5a1h)		;6af3
	ld c,a			;6af6
	ld a,(0e5a3h)		;6af7
	ld b,a			;6afa
	call monta_un_sprite		;6afb   ; tres sprites, que es lo que ocupa un jugador de pie
	call monta_un_sprite		;6afe
	call monta_un_sprite		;6b01
monta_un_sprite:		; saca de la tabla el desplazamiento, el dibujo y el color, y pasa el color por la paleta
	ld a,(de)			;6b04   ; el desplazamiento a lo alto: en el MSX el primer byte de un sprite es su Y...
	inc de			;6b05
	add a,c			;6b06   ; ...sumado a donde esta la figura
	ld (hl),a			;6b07
	inc hl			;6b08
	ld a,(de)			;6b09   ; y el segundo, la X
	inc de			;6b0a
	add a,b			;6b0b
	ld (hl),a			;6b0c
	inc hl			;6b0d
	ld a,(de)			;6b0e   ; el dibujo, que se copia tal cual
	ld (hl),a			;6b0f
	inc de			;6b10
	inc hl			;6b11
	ld a,(de)			;6b12   ; el cuarto byte NO es un color: es un numero de entrada en la paleta
	exx			;6b13   ; al juego alterno, donde espera la paleta del equipo
	ld l,e			;6b14
	ld h,d			;6b15
	call suma_a_hl		;6b16
	ld a,(hl)			;6b19   ; y de ahi sale el color de verdad: por eso los dos equipos comparten dibujos
	exx			;6b1a
	ld (hl),a			;6b1b
	inc de			;6b1c
	inc hl			;6b1d
	ret			;6b1e

; ----------------------------------------------------------------------
; ===== EL DECORADO DE LOS PENALTIS =====
; ----------------------------------------------------------------------
monta_la_pantalla_de_penaltis:
	ld hl,0e100h		;6b1f   ; desde 0xE100...
	ld bc,0117fh		;6b22   ; ...y 0x1180 bytes: toda la RAM de la jugada, de golpe
	ld d,h			;6b25
	ld e,l			;6b26
	inc de			;6b27   ; el `ldir` que borra, con DE un byte por delante
	ld (hl),000h		;6b28
	ldir		;6b2a
	ld a,(0e0fch)		;6b2c
	rra			;6b2f   ; de quien es el turno
	ld h,007h		;6b30   ; y el color del cesped, distinto en cada mitad de la tanda
	jr nc,L_6B36		;6b32
	ld h,009h		;6b34
L_6B36:
	ld l,0fch		;6b36   ; con la altura 0xFC
	ld (0e3c2h),hl		;6b38
	ld hl,07850h		;6b3b   ; la mira arranca en 0x50 de ancho y 0x78 de alto
	ld (0e3c0h),hl		;6b3e
	ld a,h			;6b41   ; (0xE311) es la posicion en pixeles...
	ld (0e311h),a		;6b42
	ld a,009h		;6b45
	ld (0e313h),a		;6b47   ; ...y (0xE313) el paso: el 9, o sea el centro
	ld hl,06bc6h		;6b4a   ; los doce bytes de arranque de la pelota
	ld de,0e2a0h		;6b4d
	ld c,00ch		;6b50
	ldir		;6b52
	ld hl,06bd2h		;6b54   ; y los seis de sus dibujos
	ld de,0e2b3h		;6b57
	ld c,006h		;6b5a
	ldir		;6b5c
	ld hl,06bbbh		;6b5e
	ld de,0e5a5h		;6b61
	ld c,006h		;6b64
	ldir		;6b66
	ld hl,06bc1h		;6b68
	ld de,0e5a0h		;6b6b
	ld c,005h		;6b6e
	ldir		;6b70
	ld a,(0e002h)		;6b72
	bit 6,a		;6b75
	jr nz,L_6B7D		;6b77
	xor a			;6b79
	ld (0e006h),a		;6b7a

; ----------------------------------------------------------------------
; ===== LA TANDA DE PENALTIS: el montaje =====
; ----------------------------------------------------------------------
L_6B7D:
	xor a			;6b7d   ; (0xE310), (0xE315) y (0xE314) a cero: ni tiro, ni rebote, ni marca
	ld (0e310h),a		;6b7e
	ld (0e315h),a		;6b81
	ld (0e314h),a		;6b84
	ld (0e008h),a		;6b87   ; y el segundo mando en blanco, que aqui se turnan
	dec a			;6b8a   ; (0xE317) a 0xFF, todavia ninguno
	ld (0e317h),a		;6b8b
	ld a,001h		;6b8e   ; (0xE0F8) a 1: el marcador de arriba pasa a ser el de penaltis, no el reloj
	ld (0e0f8h),a		;6b90
	ld a,080h		;6b93   ; y 0x80 cuadros de espera
	ld (0e312h),a		;6b95
	ld a,(0e0fch)		;6b98   ; al que le toca tirar se le descuenta un penalti de los que le quedan
	rra			;6b9b
	ld hl,0e0fdh		;6b9c
	jr nc,L_6BA2		;6b9f
	inc hl			;6ba1
L_6BA2:
	dec (hl)			;6ba2   ; y ahi va
	call L_729F		;6ba3   ; los graficos de la escena: patrones, color y sprites
	call L_7697		;6ba6
	call L_7AF1		;6ba9
	call pinta_los_nombres_de_los_equipos		;6bac
	call pinta_el_marcador		;6baf
	call pinta_los_penaltis		;6bb2
	call L_8787		;6bb5
	jp dibuja_la_escena_del_penalti		;6bb8

; ----------------------------------------------------------------------
; DATOS arranques_de_los_penaltis: cuatro tandas que 0x6B4A copia a 0xE2A0,
;   0xE2B3, 0xE5A5 y 0xE5A0: doce, seis, seis y cinco bytes
;   0x6bbb..0x6bd8  (29 bytes)
DATA_arranques_de_los_penaltis:
	defb 000h	; 6bbb
	defb 030h	; 6bbc
	defb 000h	; 6bbd
	defb 07ch	; 6bbe
	defb 000h	; 6bbf
	defb 000h	; 6bc0
	defb 000h	; 6bc1
	defb 0a8h	; 6bc2
	defb 000h	; 6bc3
	defb 07ch	; 6bc4
	defb 000h	; 6bc5
	defb 000h	; 6bc6
	defb 08ch	; 6bc7
	defb 000h	; 6bc8
	defb 000h	; 6bc9
	defb 000h	; 6bca
	defb 07ch	; 6bcb
	defb 000h	; 6bcc
	defb 000h	; 6bcd
	defb 000h	; 6bce
	defb 000h	; 6bcf
	defb 000h	; 6bd0
	defb 000h	; 6bd1
	defb 020h	; 6bd2
	defb 00eh	; 6bd3
	defb 02ch	; 6bd4
	defb 001h	; 6bd5
	defb 0f4h	; 6bd6
	defb 001h	; 6bd7

; ======================================================================
; CODIGO 0x6bd8..0x6cde  (262 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL LOGOTIPO: el jugador que chuta =====
; ----------------------------------------------------------------------
monta_la_escena_del_logotipo:
	call L_76BC		;6bd8
	xor a			;6bdb   ; (0xE558) es el reloj de la escena, y arranca a cero
	ld (0e558h),a		;6bdc
	ld a,010h		;6bdf   ; 0x10: los cuatro trozos por hacer, mas el bit que los cierra
	ld (0e55eh),a		;6be1
	ld de,0e559h		;6be4   ; los cinco bytes del jugador: altura, ancho de 16 bits y dibujo
	ld hl,06ce3h		;6be7
	ld bc,00005h		;6bea
	ldir		;6bed
	ld de,0e2a0h		;6bef   ; y los 32 de la pelota
	ld hl,06ce8h		;6bf2
	ld c,020h		;6bf5
	ldir		;6bf7
	ret			;6bf9
corre_el_jugador:
	ld de,00084h		;6bfa   ; 0x84 por cuadro, en dieciseisavos: poco mas de ocho pixeles
L_6BFD:
	ld hl,(0e55ah)		;6bfd   ; la posicion a lo ancho, de 16 bits
	and a			;6c00
	sbc hl,de		;6c01   ; restar es correr hacia la izquierda
	ld (0e55ah),hl		;6c03
	ld a,(0e003h)		;6c06   ; el contador de cuadros
	and 007h		;6c09   ; un cambio de dibujo cada ocho cuadros
	ret nz			;6c0b
	ld a,(0e55ch)		;6c0c
	inc a			;6c0f   ; el dibujo siguiente...
	cp 003h		;6c10   ; ...y al tercero
	jr nz,L_6C16		;6c12
	sub 002h		;6c14   ; vuelve al primero: dos dibujos alternos, que es una zancada
L_6C16:
	ld (0e55ch),a		;6c16
	ret			;6c19
dibuja_al_jugador_del_logotipo:
	ld de,0e390h		;6c1a   ; los sprites de la escena
	ld hl,08218h		;6c1d   ; la tabla de dibujos de este jugador
	ld (0e521h),hl		;6c20
	ld (0e523h),de		;6c23   ; y donde se van dejando
	exx			;6c27
	ld de,06cdeh		;6c28   ; la paleta, en el juego alterno de registros
	exx			;6c2b
	ld a,(0e559h)		;6c2c   ; la altura del jugador
	cp 0e0h		;6c2f   ; con 0xE0 esta aparcado y no se dibuja
	ret z			;6c31
	ld hl,(0e521h)		;6c32
	ld a,(0e55ch)		;6c35   ; su dibujo de ahora
	add a,a			;6c38   ; dos bytes por puntero
	call suma_a_hl		;6c39
	ld e,(hl)			;6c3c
	inc hl			;6c3d
	ld d,(hl)			;6c3e
	ld hl,(0e523h)		;6c3f
	ld a,(0e559h)		;6c42
	ld c,a			;6c45   ; la altura, en C
	ld a,(0e55bh)		;6c46
	ld b,a			;6c49   ; y el ancho, en B: el byte alto de la posicion fina
	call monta_un_sprite		;6c4a   ; cuatro sprites, que es un jugador entero
	call monta_un_sprite		;6c4d
	call monta_un_sprite		;6c50
	jp monta_un_sprite		;6c53
el_chute:
	ld a,(0e55dh)		;6c56   ; (0xE55D) cuenta los cuadros del chute
	inc a			;6c59
	ld (0e55dh),a		;6c5a
	and 01fh		;6c5d   ; y da la vuelta cada 32
	push af			;6c5f
	cp 001h		;6c60   ; en el primero...
	jr nz,L_6C69		;6c62
	ld a,013h		;6c64   ; ...suena el 0x13, que es el golpe al balon
	call pide_un_sonido_siempre		;6c66
L_6C69:
	pop af			;6c69
	sub 010h		;6c6a   ; los dieciseis primeros cuadros
	ld hl,00000h		;6c6c
	jr c,L_6C7B		;6c6f   ; no llevan desvio: la pelota aun no ha salido
	ld hl,06d08h		;6c71   ; y pasados, la tabla de 0x6D08 da el desvio
	call suma_a_hl		;6c74
	ld l,(hl)			;6c77   ; con 0xFF de byte alto: todos los valores son negativos
	ld h,0ffh		;6c78
	add hl,hl			;6c7a   ; doblado
L_6C7B:
	ld (0e2a7h),hl		;6c7b   ; al desvio lateral de la pelota
	ld hl,00000h		;6c7e
	ld (0e2a2h),hl		;6c81   ; y la velocidad vertical a cero, que este es un tiro raso
	ret			;6c84
el_trallazo:
	ld a,003h		;6c85   ; el dibujo 3, el de la pierna estirada
	ld (0e55ch),a		;6c87
	ld hl,00000h		;6c8a
	ld (0e2a2h),hl		;6c8d   ; sin velocidad vertical...
	ld l,0e0h		;6c90
	ld (0e2abh),hl		;6c92   ; ...pero con 0xE0 de empuje hacia adelante
	ld hl,0ff00h		;6c95
	ld (0e2a7h),hl		;6c98   ; y desvio hacia el otro lado
	ld l,0fdh		;6c9b
	ld (0e2adh),hl		;6c9d
	ld a,057h		;6ca0   ; el 0x57 es el mismo golpe que el penalti
	jp pide_un_sonido_siempre		;6ca2
corre_el_jugador_despacio:
	ld de,000a0h		;6ca5   ; 0xA0 por cuadro, algo mas que antes, y por lo demas es la misma
	jp L_6BFD		;6ca8
mueve_y_dibuja_la_pelota_del_logotipo:
	call tira_de_la_pelota_hacia_abajo		;6cab   ; la gravedad
	call suma_las_velocidades_de_la_pelota		;6cae   ; y el movimiento
	ld hl,(0e2a0h)		;6cb1   ; la posicion...
	ld de,(0e2a9h)		;6cb4   ; ...menos la altura a la que vuela
	and a			;6cb8
	sbc hl,de		;6cb9
	ld a,h			;6cbb   ; el byte alto es el pixel de pantalla
	ld (0e2afh),a		;6cbc
	ld a,(0e2a5h)		;6cbf
	ld (0e2b0h),a		;6cc2
	call anima_la_pelota_si_rueda		;6cc5   ; y si rueda, cambia de dibujo
	ld hl,(0e2afh)		;6cc8   ; a sus dos sprites
	ld (0e3a0h),hl		;6ccb
	ld (0e3a4h),hl		;6cce
	ld hl,(0e2b3h)		;6cd1   ; con sus dos dibujos
	ld (0e3a6h),hl		;6cd4
	ld hl,(0e2b5h)		;6cd7
	ld (0e3a2h),hl		;6cda
L_6CDD:
	ret			;6cdd

; ----------------------------------------------------------------------
; DATOS cuatro_tablas_de_la_pelota: los cinco colores de sprite que L_6B04 usa
;   para el atributo; cinco bytes a 0xE559; 32 a 0xE2A0; y dieciseis entradas
;   que, extendidas con signo y dobladas, dan la rampa de velocidad del balon
;   0x6cde..0x6d18  (58 bytes)
DATA_cuatro_tablas_de_la_pelota:
	defb 00ch	; 6cde
	defb 001h	; 6cdf
	defb 006h	; 6ce0
	defb 00bh	; 6ce1
	defb 004h	; 6ce2
	defb 060h	; 6ce3
	defb 080h	; 6ce4
	defb 0f7h	; 6ce5
	defb 001h	; 6ce6
	defb 000h	; 6ce7
	defb 000h	; 6ce8
	defb 06fh	; 6ce9
	defb 000h	; 6cea
	defb 000h	; 6ceb
	defb 080h	; 6cec
	defb 0e6h	; 6ced
	defb 000h	; 6cee
	defb 000h	; 6cef
	defb 000h	; 6cf0
	defb 000h	; 6cf1
	defb 000h	; 6cf2
	defb 000h	; 6cf3
	defb 000h	; 6cf4
	defb 000h	; 6cf5
	defb 000h	; 6cf6
	defb 06eh	; 6cf7
	defb 0f0h	; 6cf8
	defb 000h	; 6cf9
	defb 000h	; 6cfa
	defb 0e4h	; 6cfb
	defb 00eh	; 6cfc
	defb 0ech	; 6cfd
	defb 001h	; 6cfe
	defb 000h	; 6cff
	defb 000h	; 6d00
	defb 000h	; 6d01
	defb 000h	; 6d02
	defb 000h	; 6d03
	defb 000h	; 6d04
	defb 000h	; 6d05
	defb 000h	; 6d06
	defb 000h	; 6d07
	defb 0fch	; 6d08
	defb 0f8h	; 6d09
	defb 0f4h	; 6d0a
	defb 0f0h	; 6d0b
	defb 0e8h	; 6d0c
	defb 0e0h	; 6d0d
	defb 0d0h	; 6d0e
	defb 0c0h	; 6d0f
	defb 0b8h	; 6d10
	defb 0b0h	; 6d11
	defb 0a0h	; 6d12
	defb 090h	; 6d13
	defb 08ch	; 6d14
	defb 088h	; 6d15
	defb 084h	; 6d16
	defb 080h	; 6d17

; ======================================================================
; CODIGO 0x6d18..0x6d48  (48 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LAS DIEZ TANDAS DE GRAFICOS DEL CAMPO =====
; ----------------------------------------------------------------------
L_6D18:
	ld de,06d48h		;6d18   ; tanda 1: el cesped y las lineas. Los bloques con destino dentro traen los dos primeros bytes diciendo a que direccion de VRAM van
	call descomprime_con_destino_dentro		;6d1b
	ld de,06d75h		;6d1e
	call descomprime_con_destino_dentro		;6d21
	ld de,06d65h		;6d24   ; y estos dos van ESPEJADOS: el mismo bloque comprimido, con los ocho bits de cada byte del reves
	ld hl,02250h		;6d27
	call descomprime_con_espejo		;6d2a
	ld de,06d77h		;6d2d
	ld hl,02288h		;6d30
	call descomprime_con_espejo		;6d33
	ld de,06d8dh		;6d36
	call descomprime_con_destino_dentro		;6d39
	ld de,06de0h		;6d3c
	call descomprime_con_destino_dentro		;6d3f
	ld de,06deah		;6d42
	jp descomprime_con_destino_dentro		;6d45

; ----------------------------------------------------------------------
; DATOS patrones_6d48: 45 bytes comprimidos que dan 80 de VRAM en 0x2200; lo
;   carga 0x6D1B
;   0x6d48..0x6d75  (45 bytes)
DATA_patrones_6d48:
	defb 000h	; 6d48
	defb 022h	; 6d49
	defb 002h	; 6d4a
	defb 0ffh	; 6d4b
	defb 086h	; 6d4c
	defb 0f9h	; 6d4d
	defb 0a9h	; 6d4e
	defb 0f9h	; 6d4f
	defb 074h	; 6d50
	defb 0ffh	; 6d51
	defb 0ffh	; 6d52
	defb 018h	; 6d53
	defb 000h	; 6d54
	defb 002h	; 6d55
	defb 0ffh	; 6d56
	defb 086h	; 6d57
	defb 0f0h	; 6d58
	defb 0adh	; 6d59
	defb 049h	; 6d5a
	defb 019h	; 6d5b
	defb 0ffh	; 6d5c
	defb 0ffh	; 6d5d
	defb 004h	; 6d5e
	defb 000h	; 6d5f
	defb 084h	; 6d60
	defb 001h	; 6d61
	defb 001h	; 6d62
	defb 006h	; 6d63
	defb 007h	; 6d64
	defb 006h	; 6d65
	defb 000h	; 6d66
	defb 002h	; 6d67
	defb 003h	; 6d68
	defb 00ah	; 6d69
	defb 0feh	; 6d6a
	defb 086h	; 6d6b
	defb 0fdh	; 6d6c
	defb 0fbh	; 6d6d
	defb 0f7h	; 6d6e
	defb 0cfh	; 6d6f
	defb 03fh	; 6d70
	defb 0ffh	; 6d71
	defb 008h	; 6d72
	defb 0fch	; 6d73
	defb 000h	; 6d74

; ----------------------------------------------------------------------
; DATOS patrones_6d75: 24 bytes comprimidos que dan 24 de VRAM en 0x2270; lo
;   carga 0x6D21
;   0x6d75..0x6d8d  (24 bytes)
DATA_patrones_6d75:
	defb 070h	; 6d75
	defb 022h	; 6d76
	defb 090h	; 6d77
	defb 0fch	; 6d78
	defb 0f8h	; 6d79
	defb 0f1h	; 6d7a
	defb 0e3h	; 6d7b
	defb 0c6h	; 6d7c
	defb 085h	; 6d7d
	defb 01bh	; 6d7e
	defb 035h	; 6d7f
	defb 000h	; 6d80
	defb 000h	; 6d81
	defb 0bfh	; 6d82
	defb 05fh	; 6d83
	defb 0eeh	; 6d84
	defb 0f5h	; 6d85
	defb 0fbh	; 6d86
	defb 0f5h	; 6d87
	defb 007h	; 6d88
	defb 01ch	; 6d89
	defb 081h	; 6d8a
	defb 00ch	; 6d8b
	defb 000h	; 6d8c

; ----------------------------------------------------------------------
; DATOS patrones_6d8d: 83 bytes comprimidos que dan 96 de VRAM en 0x2008; lo
;   carga 0x6D39
;   0x6d8d..0x6de0  (83 bytes)
DATA_patrones_6d8d:
	defb 008h	; 6d8d
	defb 020h	; 6d8e
	defb 010h	; 6d8f
	defb 0ffh	; 6d90
	defb 089h	; 6d91
	defb 063h	; 6d92
	defb 066h	; 6d93
	defb 06ch	; 6d94
	defb 078h	; 6d95
	defb 07ch	; 6d96
	defb 06eh	; 6d97
	defb 067h	; 6d98
	defb 000h	; 6d99
	defb 03eh	; 6d9a
	defb 005h	; 6d9b
	defb 063h	; 6d9c
	defb 09ch	; 6d9d
	defb 03eh	; 6d9e
	defb 000h	; 6d9f
	defb 063h	; 6da0
	defb 073h	; 6da1
	defb 07bh	; 6da2
	defb 07fh	; 6da3
	defb 06fh	; 6da4
	defb 067h	; 6da5
	defb 063h	; 6da6
	defb 000h	; 6da7
	defb 01ch	; 6da8
	defb 036h	; 6da9
	defb 063h	; 6daa
	defb 063h	; 6dab
	defb 07fh	; 6dac
	defb 063h	; 6dad
	defb 063h	; 6dae
	defb 000h	; 6daf
	defb 063h	; 6db0
	defb 077h	; 6db1
	defb 07fh	; 6db2
	defb 07fh	; 6db3
	defb 06bh	; 6db4
	defb 063h	; 6db5
	defb 063h	; 6db6
	defb 000h	; 6db7
	defb 079h	; 6db8
	defb 033h	; 6db9
	defb 004h	; 6dba
	defb 030h	; 6dbb
	defb 08ch	; 6dbc
	defb 078h	; 6dbd
	defb 000h	; 6dbe
	defb 03eh	; 6dbf
	defb 063h	; 6dc0
	defb 060h	; 6dc1
	defb 03eh	; 6dc2
	defb 003h	; 6dc3
	defb 063h	; 6dc4
	defb 03eh	; 6dc5
	defb 000h	; 6dc6
	defb 03eh	; 6dc7
	defb 063h	; 6dc8
	defb 003h	; 6dc9
	defb 060h	; 6dca
	defb 093h	; 6dcb
	defb 063h	; 6dcc
	defb 03eh	; 6dcd
	defb 000h	; 6dce
	defb 07fh	; 6dcf
	defb 060h	; 6dd0
	defb 060h	; 6dd1
	defb 07eh	; 6dd2
	defb 060h	; 6dd3
	defb 060h	; 6dd4
	defb 07fh	; 6dd5
	defb 000h	; 6dd6
	defb 07eh	; 6dd7
	defb 063h	; 6dd8
	defb 063h	; 6dd9
	defb 062h	; 6dda
	defb 07ch	; 6ddb
	defb 066h	; 6ddc
	defb 063h	; 6ddd
	defb 000h	; 6dde
	defb 000h	; 6ddf

; ----------------------------------------------------------------------
; DATOS patrones_6de0: 10 bytes comprimidos que dan 8 de VRAM en 0x22E8; lo
;   carga 0x6D3F
;   0x6de0..0x6dea  (10 bytes)
DATA_patrones_6de0:
	defb 0e8h	; 6de0
	defb 022h	; 6de1
	defb 004h	; 6de2
	defb 000h	; 6de3
	defb 002h	; 6de4
	defb 080h	; 6de5
	defb 082h	; 6de6
	defb 060h	; 6de7
	defb 0e0h	; 6de8
	defb 000h	; 6de9

; ----------------------------------------------------------------------
; DATOS patrones_6dea: 44 bytes comprimidos que dan 40 de VRAM en 0x22A0; lo
;   carga 0x6D45
;   0x6dea..0x6e16  (44 bytes)
DATA_patrones_6dea:
	defb 0a0h	; 6dea
	defb 022h	; 6deb
	defb 087h	; 6dec
	defb 067h	; 6ded
	defb 06eh	; 6dee
	defb 07ch	; 6def
	defb 079h	; 6df0
	defb 07dh	; 6df1
	defb 06fh	; 6df2
	defb 067h	; 6df3
	defb 003h	; 6df4
	defb 000h	; 6df5
	defb 081h	; 6df6
	defb 01ch	; 6df7
	defb 003h	; 6df8
	defb 0b6h	; 6df9
	defb 081h	; 6dfa
	defb 01ch	; 6dfb
	defb 003h	; 6dfc
	defb 000h	; 6dfd
	defb 085h	; 6dfe
	defb 0d1h	; 6dff
	defb 0fah	; 6e00
	defb 0d9h	; 6e01
	defb 0dbh	; 6e02
	defb 0dbh	; 6e03
	defb 003h	; 6e04
	defb 000h	; 6e05
	defb 08ah	; 6e06
	defb 0cdh	; 6e07
	defb 06fh	; 6e08
	defb 0edh	; 6e09
	defb 06dh	; 6e0a
	defb 0edh	; 6e0b
	defb 000h	; 6e0c
	defb 006h	; 6e0d
	defb 000h	; 6e0e
	defb 066h	; 6e0f
	defb 0f6h	; 6e10
	defb 003h	; 6e11
	defb 0b6h	; 6e12
	defb 081h	; 6e13
	defb 000h	; 6e14
	defb 000h	; 6e15

; ======================================================================
; CODIGO 0x6e16..0x6e25  (15 bytes)
; ======================================================================


L_6E16:
	ld de,06e25h		;6e16   ; tanda 2: patrones en 0x2828...
	call descomprime_con_destino_dentro		;6e19
	ld de,06e27h		;6e1c   ; ...y su espejo en 0x28E0
	ld hl,028e0h		;6e1f
	jp descomprime_con_espejo		;6e22

; ----------------------------------------------------------------------
; DATOS patrones_6e25: 148 bytes comprimidos que dan 184 de VRAM en 0x2828; lo
;   carga 0x6E19
;   0x6e25..0x6eb9  (148 bytes)
DATA_patrones_6e25:
	defb 028h	; 6e25
	defb 028h	; 6e26
	defb 002h	; 6e27
	defb 01ch	; 6e28
	defb 082h	; 6e29
	defb 09ch	; 6e2a
	defb 01ch	; 6e2b
	defb 003h	; 6e2c
	defb 09ch	; 6e2d
	defb 0a1h	; 6e2e
	defb 08ch	; 6e2f
	defb 000h	; 6e30
	defb 000h	; 6e31
	defb 0bfh	; 6e32
	defb 05fh	; 6e33
	defb 0eeh	; 6e34
	defb 0f5h	; 6e35
	defb 0fbh	; 6e36
	defb 0f5h	; 6e37
	defb 03fh	; 6e38
	defb 01fh	; 6e39
	defb 007h	; 6e3a
	defb 001h	; 6e3b
	defb 030h	; 6e3c
	defb 03ch	; 6e3d
	defb 03fh	; 6e3e
	defb 03fh	; 6e3f
	defb 02eh	; 6e40
	defb 01fh	; 6e41
	defb 03fh	; 6e42
	defb 01fh	; 6e43
	defb 02eh	; 6e44
	defb 035h	; 6e45
	defb 03bh	; 6e46
	defb 035h	; 6e47
	defb 0eeh	; 6e48
	defb 05fh	; 6e49
	defb 0bfh	; 6e4a
	defb 05fh	; 6e4b
	defb 0eeh	; 6e4c
	defb 0f5h	; 6e4d
	defb 0fbh	; 6e4e
	defb 0f5h	; 6e4f
	defb 007h	; 6e50
	defb 00ch	; 6e51
	defb 002h	; 6e52
	defb 004h	; 6e53
	defb 006h	; 6e54
	defb 024h	; 6e55
	defb 092h	; 6e56
	defb 020h	; 6e57
	defb 02eh	; 6e58
	defb 01fh	; 6e59
	defb 03fh	; 6e5a
	defb 01fh	; 6e5b
	defb 02eh	; 6e5c
	defb 035h	; 6e5d
	defb 03bh	; 6e5e
	defb 035h	; 6e5f
	defb 0eeh	; 6e60
	defb 05fh	; 6e61
	defb 0bfh	; 6e62
	defb 05fh	; 6e63
	defb 0eeh	; 6e64
	defb 0f5h	; 6e65
	defb 0fbh	; 6e66
	defb 0f5h	; 6e67
	defb 020h	; 6e68
	defb 003h	; 6e69
	defb 030h	; 6e6a
	defb 004h	; 6e6b
	defb 03ch	; 6e6c
	defb 002h	; 6e6d
	defb 000h	; 6e6e
	defb 081h	; 6e6f
	defb 07eh	; 6e70
	defb 005h	; 6e71
	defb 0feh	; 6e72
	defb 086h	; 6e73
	defb 0ffh	; 6e74
	defb 0f8h	; 6e75
	defb 0e0h	; 6e76
	defb 083h	; 6e77
	defb 00fh	; 6e78
	defb 03fh	; 6e79
	defb 006h	; 6e7a
	defb 0ffh	; 6e7b
	defb 08bh	; 6e7c
	defb 0feh	; 6e7d
	defb 0fch	; 6e7e
	defb 0f8h	; 6e7f
	defb 0f1h	; 6e80
	defb 0e3h	; 6e81
	defb 0e7h	; 6e82
	defb 0c7h	; 6e83
	defb 0cfh	; 6e84
	defb 08fh	; 6e85
	defb 09fh	; 6e86
	defb 01fh	; 6e87
	defb 003h	; 6e88
	defb 03fh	; 6e89
	defb 086h	; 6e8a
	defb 01fh	; 6e8b
	defb 09fh	; 6e8c
	defb 09fh	; 6e8d
	defb 08fh	; 6e8e
	defb 0cfh	; 6e8f
	defb 0c7h	; 6e90
	defb 008h	; 6e91
	defb 0feh	; 6e92
	defb 008h	; 6e93
	defb 03fh	; 6e94
	defb 085h	; 6e95
	defb 0e3h	; 6e96
	defb 0f1h	; 6e97
	defb 0f8h	; 6e98
	defb 0fch	; 6e99
	defb 0feh	; 6e9a
	defb 006h	; 6e9b
	defb 0ffh	; 6e9c
	defb 084h	; 6e9d
	defb 03fh	; 6e9e
	defb 007h	; 6e9f
	defb 080h	; 6ea0
	defb 0f0h	; 6ea1
	defb 007h	; 6ea2
	defb 0feh	; 6ea3
	defb 002h	; 6ea4
	defb 000h	; 6ea5
	defb 008h	; 6ea6
	defb 03ch	; 6ea7
	defb 003h	; 6ea8
	defb 03fh	; 6ea9
	defb 08dh	; 6eaa
	defb 03ch	; 6eab
	defb 030h	; 6eac
	defb 001h	; 6ead
	defb 007h	; 6eae
	defb 03fh	; 6eaf
	defb 02ch	; 6eb0
	defb 018h	; 6eb1
	defb 031h	; 6eb2
	defb 023h	; 6eb3
	defb 006h	; 6eb4
	defb 005h	; 6eb5
	defb 01bh	; 6eb6
	defb 035h	; 6eb7
	defb 000h	; 6eb8

; ======================================================================
; CODIGO 0x6eb9..0x6ec8  (15 bytes)
; ======================================================================


L_6EB9:
	ld de,06ec8h		;6eb9   ; tanda 3: patrones en 0x3048...
	call descomprime_con_destino_dentro		;6ebc
	ld de,06eceh		;6ebf   ; ...y su espejo en 0x30A8
	ld hl,030a8h		;6ec2
	jp descomprime_con_espejo		;6ec5

; ----------------------------------------------------------------------
; DATOS patrones_6ec8: 70 bytes comprimidos que dan 96 de VRAM en 0x3048; lo
;   carga 0x6EBC
;   0x6ec8..0x6f0e  (70 bytes)
DATA_patrones_6ec8:
	defb 048h	; 6ec8
	defb 030h	; 6ec9
	defb 006h	; 6eca
	defb 0ffh	; 6ecb
	defb 002h	; 6ecc
	defb 000h	; 6ecd
	defb 008h	; 6ece
	defb 000h	; 6ecf
	defb 084h	; 6ed0
	defb 08ch	; 6ed1
	defb 04ch	; 6ed2
	defb 08ch	; 6ed3
	defb 04ch	; 6ed4
	defb 003h	; 6ed5
	defb 0cch	; 6ed6
	defb 085h	; 6ed7
	defb 0c4h	; 6ed8
	defb 02eh	; 6ed9
	defb 01fh	; 6eda
	defb 000h	; 6edb
	defb 000h	; 6edc
	defb 004h	; 6edd
	defb 0ffh	; 6ede
	defb 084h	; 6edf
	defb 0eeh	; 6ee0
	defb 05fh	; 6ee1
	defb 000h	; 6ee2
	defb 000h	; 6ee3
	defb 004h	; 6ee4
	defb 0ffh	; 6ee5
	defb 084h	; 6ee6
	defb 0e4h	; 6ee7
	defb 044h	; 6ee8
	defb 000h	; 6ee9
	defb 000h	; 6eea
	defb 004h	; 6eeb
	defb 0fch	; 6eec
	defb 08eh	; 6eed
	defb 02eh	; 6eee
	defb 01fh	; 6eef
	defb 03fh	; 6ef0
	defb 01fh	; 6ef1
	defb 02eh	; 6ef2
	defb 035h	; 6ef3
	defb 03bh	; 6ef4
	defb 035h	; 6ef5
	defb 0ffh	; 6ef6
	defb 03fh	; 6ef7
	defb 0cfh	; 6ef8
	defb 0f7h	; 6ef9
	defb 0fbh	; 6efa
	defb 0fdh	; 6efb
	defb 00ah	; 6efc
	defb 0feh	; 6efd
	defb 002h	; 6efe
	defb 0fch	; 6eff
	defb 006h	; 6f00
	defb 0ffh	; 6f01
	defb 008h	; 6f02
	defb 0fch	; 6f03
	defb 088h	; 6f04
	defb 0eeh	; 6f05
	defb 05fh	; 6f06
	defb 0bfh	; 6f07
	defb 05fh	; 6f08
	defb 0eeh	; 6f09
	defb 0f5h	; 6f0a
	defb 0fbh	; 6f0b
	defb 0f5h	; 6f0c
	defb 000h	; 6f0d

; ======================================================================
; CODIGO 0x6f0e..0x6f19  (11 bytes)
; ======================================================================


L_6F0E:
	ld de,06f19h		;6f0e   ; tanda 4: 32 bytes en 0x2808, en los tres tercios
	ld hl,02808h		;6f11
	ld b,002h		;6f14
	jp L_469A		;6f16

; ----------------------------------------------------------------------
; DATOS patrones_6f19: 24 bytes comprimidos que dan 32 de VRAM en 0x2808; lo
;   carga 0x6F16. Va a los TRES tercios de SCREEN 2
;   0x6f19..0x6f31  (24 bytes)
DATA_patrones_6f19:
	defb 008h	; 6f19
	defb 0ffh	; 6f1a
	defb 002h	; 6f1b
	defb 000h	; 6f1c
	defb 006h	; 6f1d
	defb 0ffh	; 6f1e
	defb 090h	; 6f1f
	defb 010h	; 6f20
	defb 018h	; 6f21
	defb 0fch	; 6f22
	defb 0feh	; 6f23
	defb 0fch	; 6f24
	defb 018h	; 6f25
	defb 010h	; 6f26
	defb 000h	; 6f27
	defb 008h	; 6f28
	defb 018h	; 6f29
	defb 03fh	; 6f2a
	defb 07fh	; 6f2b
	defb 03fh	; 6f2c
	defb 018h	; 6f2d
	defb 008h	; 6f2e
	defb 000h	; 6f2f
	defb 000h	; 6f30

; ======================================================================
; CODIGO 0x6f31..0x6f55  (36 bytes)
; ======================================================================


L_6F31:
	ld de,06f55h		;6f31   ; los cuatro volcados de las fichas: dos derechos...
	ld hl,02320h		;6f34
	call descomprime_en_los_tres_tercios		;6f37
	ld de,06f55h		;6f3a
	ld hl,02590h		;6f3d
	call descomprime_en_los_tres_tercios		;6f40
	ld de,06f55h		;6f43   ; ...y dos espejados, que son los mismos jugadores mirando al otro lado
	ld hl,02458h		;6f46
	call descomprime_espejado_en_los_tres_tercios		;6f49
	ld de,06f55h		;6f4c
	ld hl,026c8h		;6f4f
	jp descomprime_espejado_en_los_tres_tercios		;6f52

; ----------------------------------------------------------------------
; DATOS patrones_6f55: 284 bytes comprimidos que dan 312 de VRAM en 0x2320; lo
;   cargan 4 sitios (0x6F37, 0x6F40, 0x6F49, 0x6F52). Se vuelca tambien
;   ESPEJADO, con los ocho bits de cada byte del reves. Va a los TRES tercios
;   de SCREEN 2
;   0x6f55..0x7071  (284 bytes)
DATA_patrones_6f55:
	defb 004h	; 6f55
	defb 0ffh	; 6f56
	defb 002h	; 6f57
	defb 0feh	; 6f58
	defb 003h	; 6f59
	defb 0ffh	; 6f5a
	defb 002h	; 6f5b
	defb 07fh	; 6f5c
	defb 003h	; 6f5d
	defb 03fh	; 6f5e
	defb 002h	; 6f5f
	defb 07fh	; 6f60
	defb 081h	; 6f61
	defb 0ffh	; 6f62
	defb 004h	; 6f63
	defb 0feh	; 6f64
	defb 002h	; 6f65
	defb 0fch	; 6f66
	defb 006h	; 6f67
	defb 0ffh	; 6f68
	defb 002h	; 6f69
	defb 0feh	; 6f6a
	defb 006h	; 6f6b
	defb 0ffh	; 6f6c
	defb 08ch	; 6f6d
	defb 07fh	; 6f6e
	defb 03fh	; 6f6f
	defb 03fh	; 6f70
	defb 0ffh	; 6f71
	defb 07fh	; 6f72
	defb 07fh	; 6f73
	defb 03fh	; 6f74
	defb 03fh	; 6f75
	defb 07fh	; 6f76
	defb 0ffh	; 6f77
	defb 0ffh	; 6f78
	defb 0feh	; 6f79
	defb 005h	; 6f7a
	defb 0fch	; 6f7b
	defb 002h	; 6f7c
	defb 0f8h	; 6f7d
	defb 083h	; 6f7e
	defb 0ffh	; 6f7f
	defb 0feh	; 6f80
	defb 0feh	; 6f81
	defb 004h	; 6f82
	defb 0fch	; 6f83
	defb 09fh	; 6f84
	defb 0f8h	; 6f85
	defb 001h	; 6f86
	defb 000h	; 6f87
	defb 080h	; 6f88
	defb 080h	; 6f89
	defb 081h	; 6f8a
	defb 0bdh	; 6f8b
	defb 001h	; 6f8c
	defb 001h	; 6f8d
	defb 080h	; 6f8e
	defb 001h	; 6f8f
	defb 003h	; 6f90
	defb 001h	; 6f91
	defb 081h	; 6f92
	defb 0ffh	; 6f93
	defb 083h	; 6f94
	defb 040h	; 6f95
	defb 0ffh	; 6f96
	defb 0ffh	; 6f97
	defb 0feh	; 6f98
	defb 0feh	; 6f99
	defb 0fch	; 6f9a
	defb 0fch	; 6f9b
	defb 0feh	; 6f9c
	defb 0ffh	; 6f9d
	defb 0ffh	; 6f9e
	defb 07fh	; 6f9f
	defb 03fh	; 6fa0
	defb 01fh	; 6fa1
	defb 09fh	; 6fa2
	defb 09fh	; 6fa3
	defb 005h	; 6fa4
	defb 0ffh	; 6fa5
	defb 004h	; 6fa6
	defb 07fh	; 6fa7
	defb 086h	; 6fa8
	defb 0ffh	; 6fa9
	defb 087h	; 6faa
	defb 0c3h	; 6fab
	defb 0c0h	; 6fac
	defb 0e0h	; 6fad
	defb 0f8h	; 6fae
	defb 003h	; 6faf
	defb 0ffh	; 6fb0
	defb 088h	; 6fb1
	defb 0f0h	; 6fb2
	defb 0e1h	; 6fb3
	defb 0e3h	; 6fb4
	defb 0c3h	; 6fb5
	defb 0c7h	; 6fb6
	defb 087h	; 6fb7
	defb 0ffh	; 6fb8
	defb 0ffh	; 6fb9
	defb 003h	; 6fba
	defb 0fch	; 6fbb
	defb 091h	; 6fbc
	defb 0feh	; 6fbd
	defb 0ffh	; 6fbe
	defb 0ffh	; 6fbf
	defb 0feh	; 6fc0
	defb 0f8h	; 6fc1
	defb 009h	; 6fc2
	defb 013h	; 6fc3
	defb 00bh	; 6fc4
	defb 087h	; 6fc5
	defb 087h	; 6fc6
	defb 0a3h	; 6fc7
	defb 043h	; 6fc8
	defb 007h	; 6fc9
	defb 0ffh	; 6fca
	defb 0ffh	; 6fcb
	defb 0feh	; 6fcc
	defb 0feh	; 6fcd
	defb 006h	; 6fce
	defb 0ffh	; 6fcf
	defb 081h	; 6fd0
	defb 0feh	; 6fd1
	defb 003h	; 6fd2
	defb 0fch	; 6fd3
	defb 081h	; 6fd4
	defb 0feh	; 6fd5
	defb 003h	; 6fd6
	defb 0ffh	; 6fd7
	defb 004h	; 6fd8
	defb 03fh	; 6fd9
	defb 086h	; 6fda
	defb 0bfh	; 6fdb
	defb 0ffh	; 6fdc
	defb 0ffh	; 6fdd
	defb 0feh	; 6fde
	defb 0feh	; 6fdf
	defb 0fch	; 6fe0
	defb 003h	; 6fe1
	defb 0f8h	; 6fe2
	defb 085h	; 6fe3
	defb 0f0h	; 6fe4
	defb 0e0h	; 6fe5
	defb 0c1h	; 6fe6
	defb 0c3h	; 6fe7
	defb 083h	; 6fe8
	defb 006h	; 6fe9
	defb 0ffh	; 6fea
	defb 002h	; 6feb
	defb 07fh	; 6fec
	defb 0e3h	; 6fed
	defb 01eh	; 6fee
	defb 006h	; 6fef
	defb 003h	; 6ff0
	defb 0c1h	; 6ff1
	defb 080h	; 6ff2
	defb 001h	; 6ff3
	defb 003h	; 6ff4
	defb 001h	; 6ff5
	defb 000h	; 6ff6
	defb 07ch	; 6ff7
	defb 000h	; 6ff8
	defb 000h	; 6ff9
	defb 081h	; 6ffa
	defb 080h	; 6ffb
	defb 0c0h	; 6ffc
	defb 0c0h	; 6ffd
	defb 081h	; 6ffe
	defb 03eh	; 6fff
	defb 080h	; 7000
	defb 004h	; 7001
	defb 001h	; 7002
	defb 000h	; 7003
	defb 001h	; 7004
	defb 0c3h	; 7005
	defb 0e3h	; 7006
	defb 071h	; 7007
	defb 073h	; 7008
	defb 0e7h	; 7009
	defb 083h	; 700a
	defb 0b1h	; 700b
	defb 0f8h	; 700c
	defb 0f0h	; 700d
	defb 0e0h	; 700e
	defb 0fdh	; 700f
	defb 003h	; 7010
	defb 003h	; 7011
	defb 080h	; 7012
	defb 0b0h	; 7013
	defb 038h	; 7014
	defb 01ch	; 7015
	defb 01ch	; 7016
	defb 080h	; 7017
	defb 038h	; 7018
	defb 041h	; 7019
	defb 070h	; 701a
	defb 001h	; 701b
	defb 003h	; 701c
	defb 083h	; 701d
	defb 081h	; 701e
	defb 0c1h	; 701f
	defb 0c3h	; 7020
	defb 0c7h	; 7021
	defb 0e2h	; 7022
	defb 03eh	; 7023
	defb 03ch	; 7024
	defb 01dh	; 7025
	defb 01bh	; 7026
	defb 0f8h	; 7027
	defb 0fch	; 7028
	defb 0feh	; 7029
	defb 081h	; 702a
	defb 040h	; 702b
	defb 0e0h	; 702c
	defb 0e0h	; 702d
	defb 0c0h	; 702e
	defb 080h	; 702f
	defb 03dh	; 7030
	defb 003h	; 7031
	defb 083h	; 7032
	defb 001h	; 7033
	defb 050h	; 7034
	defb 0d0h	; 7035
	defb 0f4h	; 7036
	defb 0bch	; 7037
	defb 018h	; 7038
	defb 081h	; 7039
	defb 08eh	; 703a
	defb 011h	; 703b
	defb 031h	; 703c
	defb 030h	; 703d
	defb 078h	; 703e
	defb 078h	; 703f
	defb 03ch	; 7040
	defb 038h	; 7041
	defb 083h	; 7042
	defb 001h	; 7043
	defb 008h	; 7044
	defb 0a8h	; 7045
	defb 0aah	; 7046
	defb 0feh	; 7047
	defb 0dch	; 7048
	defb 01ch	; 7049
	defb 0ffh	; 704a
	defb 0ffh	; 704b
	defb 0feh	; 704c
	defb 0feh	; 704d
	defb 0ffh	; 704e
	defb 0feh	; 704f
	defb 0feh	; 7050
	defb 004h	; 7051
	defb 0ffh	; 7052
	defb 003h	; 7053
	defb 07fh	; 7054
	defb 002h	; 7055
	defb 0ffh	; 7056
	defb 092h	; 7057
	defb 023h	; 7058
	defb 021h	; 7059
	defb 070h	; 705a
	defb 078h	; 705b
	defb 0fch	; 705c
	defb 0fch	; 705d
	defb 0ffh	; 705e
	defb 0ffh	; 705f
	defb 0c0h	; 7060
	defb 083h	; 7061
	defb 083h	; 7062
	defb 001h	; 7063
	defb 000h	; 7064
	defb 0feh	; 7065
	defb 001h	; 7066
	defb 001h	; 7067
	defb 083h	; 7068
	defb 001h	; 7069
	defb 003h	; 706a
	defb 000h	; 706b
	defb 002h	; 706c
	defb 080h	; 706d
	defb 081h	; 706e
	defb 0c1h	; 706f
	defb 000h	; 7070

; ======================================================================
; CODIGO 0x7071..0x7087  (22 bytes)
; ======================================================================


L_7071:
	ld de,07087h		;7071   ; tanda 5: el mismo bloque en 0x2998 y, espejado, en 0x2A58
	ld hl,02998h		;7074
	ld b,002h		;7077
	call L_469A		;7079
	ld de,07087h		;707c
	ld hl,02a58h		;707f
	ld b,002h		;7082
	jp L_46AA		;7084

; ----------------------------------------------------------------------
; DATOS patrones_7087: 180 bytes comprimidos que dan 192 de VRAM en 0x2998; lo
;   cargan 2 sitios (0x7079, 0x7084). Se vuelca tambien ESPEJADO, con los ocho
;   bits de cada byte del reves. Va a los TRES tercios de SCREEN 2
;   0x7087..0x713b  (180 bytes)
DATA_patrones_7087:
	defb 084h	; 7087
	defb 006h	; 7088
	defb 007h	; 7089
	defb 003h	; 708a
	defb 001h	; 708b
	defb 008h	; 708c
	defb 000h	; 708d
	defb 088h	; 708e
	defb 001h	; 708f
	defb 003h	; 7090
	defb 003h	; 7091
	defb 001h	; 7092
	defb 007h	; 7093
	defb 003h	; 7094
	defb 001h	; 7095
	defb 001h	; 7096
	defb 004h	; 7097
	defb 000h	; 7098
	defb 002h	; 7099
	defb 001h	; 709a
	defb 081h	; 709b
	defb 000h	; 709c
	defb 003h	; 709d
	defb 001h	; 709e
	defb 002h	; 709f
	defb 000h	; 70a0
	defb 085h	; 70a1
	defb 087h	; 70a2
	defb 0c3h	; 70a3
	defb 0c0h	; 70a4
	defb 0e0h	; 70a5
	defb 0f8h	; 70a6
	defb 003h	; 70a7
	defb 0ffh	; 70a8
	defb 081h	; 70a9
	defb 017h	; 70aa
	defb 003h	; 70ab
	defb 03fh	; 70ac
	defb 08dh	; 70ad
	defb 01bh	; 70ae
	defb 038h	; 70af
	defb 077h	; 70b0
	defb 00fh	; 70b1
	defb 083h	; 70b2
	defb 001h	; 70b3
	defb 020h	; 70b4
	defb 0a0h	; 70b5
	defb 0e8h	; 70b6
	defb 0b8h	; 70b7
	defb 010h	; 70b8
	defb 081h	; 70b9
	defb 000h	; 70ba
	defb 007h	; 70bb
	defb 080h	; 70bc
	defb 089h	; 70bd
	defb 04eh	; 70be
	defb 0feh	; 70bf
	defb 0feh	; 70c0
	defb 0ffh	; 70c1
	defb 06fh	; 70c2
	defb 077h	; 70c3
	defb 0ffh	; 70c4
	defb 01eh	; 70c5
	defb 080h	; 70c6
	defb 003h	; 70c7
	defb 000h	; 70c8
	defb 004h	; 70c9
	defb 080h	; 70ca
	defb 0c0h	; 70cb
	defb 0f7h	; 70cc
	defb 0efh	; 70cd
	defb 0ffh	; 70ce
	defb 0ffh	; 70cf
	defb 08dh	; 70d0
	defb 0ffh	; 70d1
	defb 0efh	; 70d2
	defb 00fh	; 70d3
	defb 00eh	; 70d4
	defb 0efh	; 70d5
	defb 0ffh	; 70d6
	defb 08ch	; 70d7
	defb 0ffh	; 70d8
	defb 0ffh	; 70d9
	defb 0efh	; 70da
	defb 0f7h	; 70db
	defb 081h	; 70dc
	defb 000h	; 70dd
	defb 006h	; 70de
	defb 00fh	; 70df
	defb 00fh	; 70e0
	defb 0feh	; 70e1
	defb 0bch	; 70e2
	defb 098h	; 70e3
	defb 062h	; 70e4
	defb 000h	; 70e5
	defb 000h	; 70e6
	defb 01eh	; 70e7
	defb 07ch	; 70e8
	defb 0feh	; 70e9
	defb 050h	; 70ea
	defb 0d0h	; 70eb
	defb 0f4h	; 70ec
	defb 0bch	; 70ed
	defb 019h	; 70ee
	defb 084h	; 70ef
	defb 0cfh	; 70f0
	defb 0deh	; 70f1
	defb 09ch	; 70f2
	defb 000h	; 70f3
	defb 083h	; 70f4
	defb 001h	; 70f5
	defb 028h	; 70f6
	defb 0a8h	; 70f7
	defb 0fah	; 70f8
	defb 0deh	; 70f9
	defb 018h	; 70fa
	defb 081h	; 70fb
	defb 07eh	; 70fc
	defb 07fh	; 70fd
	defb 0ffh	; 70fe
	defb 0ffh	; 70ff
	defb 0c1h	; 7100
	defb 0ffh	; 7101
	defb 0ffh	; 7102
	defb 09dh	; 7103
	defb 03fh	; 7104
	defb 07ch	; 7105
	defb 0f8h	; 7106
	defb 0d8h	; 7107
	defb 080h	; 7108
	defb 041h	; 7109
	defb 07fh	; 710a
	defb 03fh	; 710b
	defb 004h	; 710c
	defb 000h	; 710d
	defb 002h	; 710e
	defb 001h	; 710f
	defb 084h	; 7110
	defb 006h	; 7111
	defb 007h	; 7112
	defb 0ffh	; 7113
	defb 0ffh	; 7114
	defb 004h	; 7115
	defb 03fh	; 7116
	defb 08fh	; 7117
	defb 0bfh	; 7118
	defb 0ffh	; 7119
	defb 0ffh	; 711a
	defb 07fh	; 711b
	defb 03fh	; 711c
	defb 03bh	; 711d
	defb 03fh	; 711e
	defb 03fh	; 711f
	defb 0f0h	; 7120
	defb 0fch	; 7121
	defb 0e0h	; 7122
	defb 0e3h	; 7123
	defb 0c3h	; 7124
	defb 087h	; 7125
	defb 08fh	; 7126
	defb 003h	; 7127
	defb 0ffh	; 7128
	defb 090h	; 7129
	defb 081h	; 712a
	defb 030h	; 712b
	defb 078h	; 712c
	defb 0f0h	; 712d
	defb 0e0h	; 712e
	defb 0fdh	; 712f
	defb 003h	; 7130
	defb 073h	; 7131
	defb 09eh	; 7132
	defb 0c1h	; 7133
	defb 0c7h	; 7134
	defb 0c3h	; 7135
	defb 0e1h	; 7136
	defb 0f0h	; 7137
	defb 0f0h	; 7138
	defb 0e1h	; 7139
	defb 000h	; 713a

; ======================================================================
; CODIGO 0x713b..0x715c  (33 bytes)
; ======================================================================


L_713B:
	ld hl,02200h		;713b   ; las ocho muestras de color del menu: el mismo dibujo ocho veces
	ld b,008h		;713e
L_7140:
	push bc			;7140   ; 48 bytes cada una, subiendo de 0x30 en 0x30
	ld de,0715ch		;7141
	push hl			;7144
	ld bc,00030h		;7145
	call copia_a_la_vram		;7148
	pop hl			;714b
	ld de,00030h		;714c
	add hl,de			;714f
	pop bc			;7150
	djnz L_7140		;7151
	ld de,0718ch		;7153   ; y detras, el resto de la pantalla del menu
	ld hl,02380h		;7156
	jp descomprime_en_los_tres_tercios		;7159

; ----------------------------------------------------------------------
; DATOS patrones_de_la_muestra_de_color: seis patrones que 0x7141 sube OCHO
;   veces seguidas a 0x2200 con paso 0x30: las ocho muestras del menu son el
;   mismo dibujo, y solo se diferencian en la tabla de COLOR
;   0x715c..0x718c  (48 bytes)
DATA_patrones_de_la_muestra_de_color:
	defb 000h	; 715c
	defb 000h	; 715d
	defb 000h	; 715e
	defb 000h	; 715f
	defb 001h	; 7160
	defb 001h	; 7161
	defb 000h	; 7162
	defb 000h	; 7163
	defb 083h	; 7164
	defb 001h	; 7165
	defb 050h	; 7166
	defb 0d0h	; 7167
	defb 0f4h	; 7168
	defb 0bch	; 7169
	defb 018h	; 716a
	defb 081h	; 716b
	defb 0fch	; 716c
	defb 0fch	; 716d
	defb 0fch	; 716e
	defb 0feh	; 716f
	defb 0feh	; 7170
	defb 0feh	; 7171
	defb 0fch	; 7172
	defb 0f8h	; 7173
	defb 083h	; 7174
	defb 0b1h	; 7175
	defb 0f8h	; 7176
	defb 0f0h	; 7177
	defb 0e0h	; 7178
	defb 0fdh	; 7179
	defb 003h	; 717a
	defb 003h	; 717b
	defb 0f0h	; 717c
	defb 0f1h	; 717d
	defb 0f0h	; 717e
	defb 0f8h	; 717f
	defb 0f0h	; 7180
	defb 0e0h	; 7181
	defb 0ffh	; 7182
	defb 0ffh	; 7183
	defb 003h	; 7184
	defb 0c3h	; 7185
	defb 0c1h	; 7186
	defb 0e1h	; 7187
	defb 0e0h	; 7188
	defb 0f0h	; 7189
	defb 0f0h	; 718a
	defb 0e0h	; 718b

; ----------------------------------------------------------------------
; DATOS patrones_718c: 9 bytes comprimidos que dan 16 de VRAM en 0x2380; lo
;   carga 0x7159. Va a los TRES tercios de SCREEN 2
;   0x718c..0x7195  (9 bytes)
DATA_patrones_718c:
	defb 081h	; 718c
	defb 07fh	; 718d
	defb 007h	; 718e
	defb 000h	; 718f
	defb 004h	; 7190
	defb 0ffh	; 7191
	defb 004h	; 7192
	defb 000h	; 7193
	defb 000h	; 7194

; ----------------------------------------------------------------------
; DATOS nombres_7195: 104 bytes comprimidos que dan 192 de VRAM en 0x3880; lo
;   carga 0x59E4
;   0x7195..0x71fd  (104 bytes)
DATA_nombres_7195:
	defb 080h	; 7195
	defb 038h	; 7196
	defb 004h	; 7197
	defb 000h	; 7198
	defb 01ah	; 7199
	defb 00ch	; 719a
	defb 006h	; 719b
	defb 000h	; 719c
	defb 09ah	; 719d
	defb 00ch	; 719e
	defb 040h	; 719f
	defb 041h	; 71a0
	defb 00ch	; 71a1
	defb 046h	; 71a2
	defb 047h	; 71a3
	defb 00ch	; 71a4
	defb 04ch	; 71a5
	defb 04dh	; 71a6
	defb 00ch	; 71a7
	defb 052h	; 71a8
	defb 053h	; 71a9
	defb 00ch	; 71aa
	defb 058h	; 71ab
	defb 059h	; 71ac
	defb 00ch	; 71ad
	defb 05eh	; 71ae
	defb 05fh	; 71af
	defb 00ch	; 71b0
	defb 064h	; 71b1
	defb 065h	; 71b2
	defb 00ch	; 71b3
	defb 06ah	; 71b4
	defb 06bh	; 71b5
	defb 00ch	; 71b6
	defb 00ch	; 71b7
	defb 006h	; 71b8
	defb 000h	; 71b9
	defb 09ah	; 71ba
	defb 00ch	; 71bb
	defb 042h	; 71bc
	defb 043h	; 71bd
	defb 00ch	; 71be
	defb 048h	; 71bf
	defb 049h	; 71c0
	defb 00ch	; 71c1
	defb 04eh	; 71c2
	defb 04fh	; 71c3
	defb 00ch	; 71c4
	defb 054h	; 71c5
	defb 055h	; 71c6
	defb 00ch	; 71c7
	defb 05ah	; 71c8
	defb 05bh	; 71c9
	defb 00ch	; 71ca
	defb 060h	; 71cb
	defb 061h	; 71cc
	defb 00ch	; 71cd
	defb 066h	; 71ce
	defb 067h	; 71cf
	defb 00ch	; 71d0
	defb 06ch	; 71d1
	defb 06dh	; 71d2
	defb 00ch	; 71d3
	defb 00ch	; 71d4
	defb 006h	; 71d5
	defb 000h	; 71d6
	defb 09ah	; 71d7
	defb 00ch	; 71d8
	defb 044h	; 71d9
	defb 045h	; 71da
	defb 00ch	; 71db
	defb 04ah	; 71dc
	defb 04bh	; 71dd
	defb 00ch	; 71de
	defb 050h	; 71df
	defb 051h	; 71e0
	defb 00ch	; 71e1
	defb 056h	; 71e2
	defb 057h	; 71e3
	defb 00ch	; 71e4
	defb 05ch	; 71e5
	defb 05dh	; 71e6
	defb 00ch	; 71e7
	defb 062h	; 71e8
	defb 063h	; 71e9
	defb 00ch	; 71ea
	defb 068h	; 71eb
	defb 069h	; 71ec
	defb 00ch	; 71ed
	defb 06eh	; 71ee
	defb 06fh	; 71ef
	defb 00ch	; 71f0
	defb 00ch	; 71f1
	defb 006h	; 71f2
	defb 000h	; 71f3
	defb 01ah	; 71f4
	defb 00ch	; 71f5
	defb 006h	; 71f6
	defb 000h	; 71f7
	defb 01ah	; 71f8
	defb 00ch	; 71f9
	defb 002h	; 71fa
	defb 000h	; 71fb
	defb 000h	; 71fc

; ======================================================================
; CODIGO 0x71fd..0x720f  (18 bytes)
; ======================================================================


L_71FD:
	ld de,0720fh		;71fd   ; los patrones de la celebracion del gol, derechos y espejados
	ld hl,02370h		;7200
	call descomprime_en_los_tres_tercios		;7203
	ld de,0720fh		;7206
	ld hl,025e0h		;7209
	jp descomprime_espejado_en_los_tres_tercios		;720c

; ----------------------------------------------------------------------
; DATOS patrones_720f: 144 bytes comprimidos que dan 160 de VRAM en 0x2370; lo
;   cargan 2 sitios (0x7203, 0x720C). Se vuelca tambien ESPEJADO, con los ocho
;   bits de cada byte del reves. Va a los TRES tercios de SCREEN 2
;   0x720f..0x729f  (144 bytes)
DATA_patrones_720f:
	defb 002h	; 720f
	defb 0ffh	; 7210
	defb 091h	; 7211
	defb 0feh	; 7212
	defb 0ffh	; 7213
	defb 0ffh	; 7214
	defb 0feh	; 7215
	defb 0feh	; 7216
	defb 0ffh	; 7217
	defb 0ffh	; 7218
	defb 081h	; 7219
	defb 000h	; 721a
	defb 0efh	; 721b
	defb 02fh	; 721c
	defb 00bh	; 721d
	defb 043h	; 721e
	defb 0e6h	; 721f
	defb 0c0h	; 7220
	defb 0f8h	; 7221
	defb 0f8h	; 7222
	defb 003h	; 7223
	defb 0f0h	; 7224
	defb 002h	; 7225
	defb 0e0h	; 7226
	defb 004h	; 7227
	defb 0ffh	; 7228
	defb 08ch	; 7229
	defb 03fh	; 722a
	defb 00fh	; 722b
	defb 080h	; 722c
	defb 080h	; 722d
	defb 088h	; 722e
	defb 008h	; 722f
	defb 009h	; 7230
	defb 013h	; 7231
	defb 0c7h	; 7232
	defb 078h	; 7233
	defb 0f8h	; 7234
	defb 0fch	; 7235
	defb 007h	; 7236
	defb 0ffh	; 7237
	defb 081h	; 7238
	defb 07fh	; 7239
	defb 004h	; 723a
	defb 03fh	; 723b
	defb 0a4h	; 723c
	defb 07fh	; 723d
	defb 08ch	; 723e
	defb 0c4h	; 723f
	defb 088h	; 7240
	defb 0ffh	; 7241
	defb 0ffh	; 7242
	defb 0feh	; 7243
	defb 0ffh	; 7244
	defb 0feh	; 7245
	defb 0feh	; 7246
	defb 0ffh	; 7247
	defb 0ffh	; 7248
	defb 081h	; 7249
	defb 000h	; 724a
	defb 0afh	; 724b
	defb 02fh	; 724c
	defb 00bh	; 724d
	defb 042h	; 724e
	defb 0e4h	; 724f
	defb 0c0h	; 7250
	defb 0f8h	; 7251
	defb 098h	; 7252
	defb 080h	; 7253
	defb 0c0h	; 7254
	defb 0e0h	; 7255
	defb 0f1h	; 7256
	defb 0e3h	; 7257
	defb 0e3h	; 7258
	defb 088h	; 7259
	defb 008h	; 725a
	defb 009h	; 725b
	defb 013h	; 725c
	defb 0c7h	; 725d
	defb 0f8h	; 725e
	defb 0f8h	; 725f
	defb 0fch	; 7260
	defb 005h	; 7261
	defb 0ffh	; 7262
	defb 002h	; 7263
	defb 0feh	; 7264
	defb 006h	; 7265
	defb 0ffh	; 7266
	defb 002h	; 7267
	defb 07fh	; 7268
	defb 002h	; 7269
	defb 0ffh	; 726a
	defb 082h	; 726b
	defb 0c3h	; 726c
	defb 081h	; 726d
	defb 004h	; 726e
	defb 000h	; 726f
	defb 092h	; 7270
	defb 081h	; 7271
	defb 0feh	; 7272
	defb 0feh	; 7273
	defb 0fch	; 7274
	defb 0f8h	; 7275
	defb 0f8h	; 7276
	defb 0fch	; 7277
	defb 0feh	; 7278
	defb 0ffh	; 7279
	defb 07fh	; 727a
	defb 07fh	; 727b
	defb 03fh	; 727c
	defb 01fh	; 727d
	defb 01fh	; 727e
	defb 03fh	; 727f
	defb 07fh	; 7280
	defb 0ffh	; 7281
	defb 018h	; 7282
	defb 004h	; 7283
	defb 000h	; 7284
	defb 087h	; 7285
	defb 0bdh	; 7286
	defb 081h	; 7287
	defb 000h	; 7288
	defb 0e7h	; 7289
	defb 018h	; 728a
	defb 03ch	; 728b
	defb 03ch	; 728c
	defb 004h	; 728d
	defb 018h	; 728e
	defb 081h	; 728f
	defb 0ffh	; 7290
	defb 004h	; 7291
	defb 0feh	; 7292
	defb 002h	; 7293
	defb 0ffh	; 7294
	defb 082h	; 7295
	defb 0feh	; 7296
	defb 0ffh	; 7297
	defb 004h	; 7298
	defb 07fh	; 7299
	defb 002h	; 729a
	defb 0ffh	; 729b
	defb 081h	; 729c
	defb 07fh	; 729d
	defb 000h	; 729e

; ======================================================================
; CODIGO 0x729f..0x72b1  (18 bytes)
; ======================================================================


L_729F:
	ld de,072b1h		;729f   ; los del penalti, igual
	ld hl,02200h		;72a2
	call descomprime_en_los_tres_tercios		;72a5
	ld de,072cch		;72a8
	ld hl,02290h		;72ab
	jp descomprime_espejado_en_los_tres_tercios		;72ae

; ----------------------------------------------------------------------
; DATOS patrones_72b1: 110 bytes comprimidos que dan 144 de VRAM en 0x2200; lo
;   carga 0x72A5. Va a los TRES tercios de SCREEN 2
;   0x72b1..0x731f  (110 bytes)
DATA_patrones_72b1:
	defb 004h	; 72b1
	defb 0ffh	; 72b2
	defb 096h	; 72b3
	defb 077h	; 72b4
	defb 0aah	; 72b5
	defb 0ddh	; 72b6
	defb 0aah	; 72b7
	defb 000h	; 72b8
	defb 0bdh	; 72b9
	defb 0dbh	; 72ba
	defb 0e7h	; 72bb
	defb 0e7h	; 72bc
	defb 0dbh	; 72bd
	defb 0bdh	; 72be
	defb 07eh	; 72bf
	defb 07eh	; 72c0
	defb 0bdh	; 72c1
	defb 0dbh	; 72c2
	defb 0e7h	; 72c3
	defb 0e7h	; 72c4
	defb 0dbh	; 72c5
	defb 0bdh	; 72c6
	defb 07eh	; 72c7
	defb 000h	; 72c8
	defb 000h	; 72c9
	defb 00eh	; 72ca
	defb 0ffh	; 72cb
	defb 088h	; 72cc
	defb 0ffh	; 72cd
	defb 0fbh	; 72ce
	defb 0fdh	; 72cf
	defb 0feh	; 72d0
	defb 0fdh	; 72d1
	defb 0fbh	; 72d2
	defb 0f7h	; 72d3
	defb 0ffh	; 72d4
	defb 008h	; 72d5
	defb 0f0h	; 72d6
	defb 004h	; 72d7
	defb 0ffh	; 72d8
	defb 0a0h	; 72d9
	defb 00eh	; 72da
	defb 0e5h	; 72db
	defb 073h	; 72dc
	defb 0a9h	; 72dd
	defb 0dch	; 72de
	defb 0a8h	; 72df
	defb 074h	; 72e0
	defb 0a8h	; 72e1
	defb 0dch	; 72e2
	defb 0a8h	; 72e3
	defb 074h	; 72e4
	defb 0a8h	; 72e5
	defb 0dch	; 72e6
	defb 0a8h	; 72e7
	defb 074h	; 72e8
	defb 0a9h	; 72e9
	defb 0d9h	; 72ea
	defb 0a3h	; 72eb
	defb 073h	; 72ec
	defb 0a7h	; 72ed
	defb 0c7h	; 72ee
	defb 08fh	; 72ef
	defb 04fh	; 72f0
	defb 09fh	; 72f1
	defb 09fh	; 72f2
	defb 03fh	; 72f3
	defb 03fh	; 72f4
	defb 07fh	; 72f5
	defb 000h	; 72f6
	defb 000h	; 72f7
	defb 0f3h	; 72f8
	defb 0f3h	; 72f9
	defb 004h	; 72fa
	defb 0fch	; 72fb
	defb 004h	; 72fc
	defb 03fh	; 72fd
	defb 004h	; 72fe
	defb 0cfh	; 72ff
	defb 004h	; 7300
	defb 0f3h	; 7301
	defb 004h	; 7302
	defb 0fch	; 7303
	defb 002h	; 7304
	defb 000h	; 7305
	defb 003h	; 7306
	defb 01fh	; 7307
	defb 002h	; 7308
	defb 08fh	; 7309
	defb 085h	; 730a
	defb 0c7h	; 730b
	defb 0e3h	; 730c
	defb 0f1h	; 730d
	defb 0f8h	; 730e
	defb 0fch	; 730f
	defb 006h	; 7310
	defb 0ffh	; 7311
	defb 086h	; 7312
	defb 07fh	; 7313
	defb 01fh	; 7314
	defb 007h	; 7315
	defb 0c0h	; 7316
	defb 0f0h	; 7317
	defb 0feh	; 7318
	defb 006h	; 7319
	defb 0ffh	; 731a
	defb 082h	; 731b
	defb 03fh	; 731c
	defb 007h	; 731d
	defb 000h	; 731e

; ======================================================================
; CODIGO 0x731f..0x736d  (78 bytes)
; ======================================================================


L_731F:
	ld de,0738ah		;731f   ; tanda 6: LOS JUGADORES. Siete bloques de patron, y detras las dos camisetas
	call descomprime_con_destino_dentro		;7322
	ld de,07396h		;7325
	call descomprime_con_destino_dentro		;7328
	ld de,0736dh		;732b
	call descomprime_con_destino_dentro		;732e
	ld de,0738ch		;7331
	ld hl,00250h		;7334
	call descomprime_sin_espejo		;7337
	ld de,07398h		;733a
	ld hl,00288h		;733d
	call descomprime_sin_espejo		;7340
	ld de,0739bh		;7343
	call descomprime_con_destino_dentro		;7346
	ld de,073cch		;7349
	call descomprime_con_destino_dentro		;734c
	ld hl,0e051h		;734f   ; la paleta del primer equipo, en 0xE051...
	ld (0e52ah),hl		;7352
	ld de,07393h		;7355   ; ...con la que se pinta el color de 0x0228
	ld hl,00228h		;7358
	call descomprime_cambiando_el_color		;735b
	ld hl,0e056h		;735e   ; y la del segundo, en 0xE056...
	ld (0e52ah),hl		;7361
	ld de,07393h		;7364   ; ...con el MISMO bloque comprimido pintando 0x02E8: un dibujo, dos camisetas
	ld hl,002e8h		;7367
	jp descomprime_cambiando_el_color		;736a

; ----------------------------------------------------------------------
; DATOS color_736d: 29 bytes comprimidos que dan 40 de VRAM en 0x0200; lo
;   carga 0x732E
;   0x736d..0x738a  (29 bytes)
DATA_color_736d:
	defb 000h	; 736d
	defb 002h	; 736e
	defb 088h	; 736f
	defb 000h	; 7370
	defb 0e0h	; 7371
	defb 016h	; 7372
	defb 0bdh	; 7373
	defb 0a8h	; 7374
	defb 0a4h	; 7375
	defb 010h	; 7376
	defb 0f0h	; 7377
	defb 008h	; 7378
	defb 0bch	; 7379
	defb 081h	; 737a
	defb 000h	; 737b
	defb 00dh	; 737c
	defb 00ch	; 737d
	defb 002h	; 737e
	defb 00fh	; 737f
	defb 088h	; 7380
	defb 000h	; 7381
	defb 0e0h	; 7382
	defb 016h	; 7383
	defb 0dbh	; 7384
	defb 08ah	; 7385
	defb 04ah	; 7386
	defb 010h	; 7387
	defb 0f0h	; 7388
	defb 000h	; 7389

; ----------------------------------------------------------------------
; DATOS color_738a: 9 bytes comprimidos que dan 32 de VRAM en 0x0230; lo carga
;   0x7322
;   0x738a..0x7393  (9 bytes)
DATA_color_738a:
	defb 030h	; 738a
	defb 002h	; 738b
	defb 006h	; 738c
	defb 00ch	; 738d
	defb 002h	; 738e
	defb 0fch	; 738f
	defb 018h	; 7390
	defb 0cfh	; 7391
	defb 000h	; 7392

; ----------------------------------------------------------------------
; DATOS color_recoloreado_7393: tres bytes que dan ocho de VRAM; van a 0x0228
;   con la paleta de un equipo y a 0x02E8 con la del otro
;   0x7393..0x7396  (3 bytes)
DATA_color_recoloreado_7393:
	defb 008h	; 7393
	defb 030h	; 7394
	defb 000h	; 7395

; ----------------------------------------------------------------------
; DATOS color_7396: 5 bytes comprimidos que dan 24 de VRAM en 0x0270; lo carga
;   0x7328
;   0x7396..0x739b  (5 bytes)
DATA_color_7396:
	defb 070h	; 7396
	defb 002h	; 7397
	defb 018h	; 7398
	defb 0cfh	; 7399
	defb 000h	; 739a

; ----------------------------------------------------------------------
; DATOS color_739b: 49 bytes comprimidos que dan 120 de VRAM en 0x0008; lo
;   carga 0x7346
;   0x739b..0x73cc  (49 bytes)
DATA_color_739b:
	defb 008h	; 739b
	defb 000h	; 739c
	defb 008h	; 739d
	defb 0c0h	; 739e
	defb 007h	; 739f
	defb 0e0h	; 73a0
	defb 081h	; 73a1
	defb 000h	; 73a2
	defb 007h	; 73a3
	defb 04eh	; 73a4
	defb 081h	; 73a5
	defb 000h	; 73a6
	defb 007h	; 73a7
	defb 04eh	; 73a8
	defb 081h	; 73a9
	defb 000h	; 73aa
	defb 007h	; 73ab
	defb 04eh	; 73ac
	defb 081h	; 73ad
	defb 000h	; 73ae
	defb 007h	; 73af
	defb 04eh	; 73b0
	defb 081h	; 73b1
	defb 000h	; 73b2
	defb 007h	; 73b3
	defb 04eh	; 73b4
	defb 081h	; 73b5
	defb 000h	; 73b6
	defb 007h	; 73b7
	defb 04eh	; 73b8
	defb 081h	; 73b9
	defb 000h	; 73ba
	defb 007h	; 73bb
	defb 04eh	; 73bc
	defb 081h	; 73bd
	defb 000h	; 73be
	defb 007h	; 73bf
	defb 04eh	; 73c0
	defb 081h	; 73c1
	defb 000h	; 73c2
	defb 007h	; 73c3
	defb 04eh	; 73c4
	defb 081h	; 73c5
	defb 000h	; 73c6
	defb 007h	; 73c7
	defb 04eh	; 73c8
	defb 019h	; 73c9
	defb 000h	; 73ca
	defb 000h	; 73cb

; ----------------------------------------------------------------------
; DATOS color_73cc: 23 bytes comprimidos que dan 40 de VRAM en 0x02A0; lo
;   carga 0x734C
;   0x73cc..0x73e3  (23 bytes)
DATA_color_73cc:
	defb 0a0h	; 73cc
	defb 002h	; 73cd
	defb 007h	; 73ce
	defb 04eh	; 73cf
	defb 081h	; 73d0
	defb 041h	; 73d1
	defb 007h	; 73d2
	defb 04eh	; 73d3
	defb 081h	; 73d4
	defb 041h	; 73d5
	defb 007h	; 73d6
	defb 04eh	; 73d7
	defb 081h	; 73d8
	defb 041h	; 73d9
	defb 007h	; 73da
	defb 04eh	; 73db
	defb 081h	; 73dc
	defb 041h	; 73dd
	defb 007h	; 73de
	defb 04eh	; 73df
	defb 081h	; 73e0
	defb 041h	; 73e1
	defb 000h	; 73e2

; ======================================================================
; CODIGO 0x73e3..0x73f2  (15 bytes)
; ======================================================================


L_73E3:
	ld de,073f2h		;73e3   ; tanda 7: el color de los patrones de 0x2828, que cae en 0x0828
	call descomprime_con_destino_dentro		;73e6
	ld de,073f4h		;73e9
	ld hl,008e0h		;73ec
	jp descomprime_sin_espejo		;73ef

; ----------------------------------------------------------------------
; DATOS color_73f2: 17 bytes comprimidos que dan 184 de VRAM en 0x0828; lo
;   carga 0x73E6
;   0x73f2..0x7403  (17 bytes)
DATA_color_73f2:
	defb 028h	; 73f2
	defb 008h	; 73f3
	defb 03ah	; 73f4
	defb 0cfh	; 73f5
	defb 002h	; 73f6
	defb 0efh	; 73f7
	defb 006h	; 73f8
	defb 0cfh	; 73f9
	defb 002h	; 73fa
	defb 0efh	; 73fb
	defb 006h	; 73fc
	defb 0cfh	; 73fd
	defb 002h	; 73fe
	defb 0efh	; 73ff
	defb 06ch	; 7400
	defb 0cfh	; 7401
	defb 000h	; 7402

; ======================================================================
; CODIGO 0x7403..0x7412  (15 bytes)
; ======================================================================


L_7403:
	ld de,07412h		;7403   ; tanda 8: el color de los de 0x3048, en 0x1048
	call descomprime_con_destino_dentro		;7406
	ld de,07416h		;7409
	ld hl,010a8h		;740c
	jp descomprime_sin_espejo		;740f

; ----------------------------------------------------------------------
; DATOS color_7412: 7 bytes comprimidos que dan 96 de VRAM en 0x1048; lo carga
;   0x7406
;   0x7412..0x7419  (7 bytes)
DATA_color_7412:
	defb 048h	; 7412
	defb 010h	; 7413
	defb 008h	; 7414
	defb 0cfh	; 7415
	defb 058h	; 7416
	defb 0cfh	; 7417
	defb 000h	; 7418

; ======================================================================
; CODIGO 0x7419..0x7424  (11 bytes)
; ======================================================================


L_7419:
	ld de,07424h		;7419   ; tanda 9: el color de los de 0x2808, en 0x0808
	ld hl,00808h		;741c
	ld b,002h		;741f
	jp L_469A		;7421

; ----------------------------------------------------------------------
; DATOS color_7424: 9 bytes comprimidos que dan 32 de VRAM en 0x0808; lo carga
;   0x7421. Va a los TRES tercios de SCREEN 2
;   0x7424..0x742d  (9 bytes)
DATA_color_7424:
	defb 008h	; 7424
	defb 0c0h	; 7425
	defb 008h	; 7426
	defb 0cfh	; 7427
	defb 008h	; 7428
	defb 07ch	; 7429
	defb 008h	; 742a
	defb 09ch	; 742b
	defb 000h	; 742c

; ======================================================================
; CODIGO 0x742d..0x745d  (48 bytes)
; ======================================================================


L_742D:
	ld hl,0e051h		;742d   ; el color de los cuatro volcados de 0x6F31, con la paleta del primer equipo...
	ld (0e52ah),hl		;7430
	ld de,0745dh		;7433
	ld hl,00320h		;7436
	call L_46B8		;7439
	ld de,0745dh		;743c
	ld hl,00458h		;743f
	call L_46B8		;7442
	ld hl,0e056h		;7445   ; ...y los otros dos con la del segundo
	ld (0e52ah),hl		;7448
	ld de,0745dh		;744b
	ld hl,00590h		;744e
	call L_46B8		;7451
	ld de,0745dh		;7454
	ld hl,006c8h		;7457
	jp L_46B8		;745a

; ----------------------------------------------------------------------
; DATOS color_recoloreado_745d: 127 bytes que dan 312 de VRAM, tirados cuatro
;   veces a 0x0320, 0x0458, 0x0590 y 0x06C8: exactamente el color de los
;   cuatro volcados de patron de 0x6F55
;   0x745d..0x74dc  (127 bytes)
DATA_color_recoloreado_745d:
	defb 020h	; 745d
	defb 003h	; 745e
	defb 005h	; 745f
	defb 004h	; 7460
	defb 083h	; 7461
	defb 003h	; 7462
	defb 004h	; 7463
	defb 004h	; 7464
	defb 00dh	; 7465
	defb 003h	; 7466
	defb 003h	; 7467
	defb 004h	; 7468
	defb 081h	; 7469
	defb 000h	; 746a
	defb 005h	; 746b
	defb 003h	; 746c
	defb 003h	; 746d
	defb 004h	; 746e
	defb 00fh	; 746f
	defb 034h	; 7470
	defb 024h	; 7471
	defb 003h	; 7472
	defb 002h	; 7473
	defb 004h	; 7474
	defb 008h	; 7475
	defb 003h	; 7476
	defb 081h	; 7477
	defb 004h	; 7478
	defb 006h	; 7479
	defb 003h	; 747a
	defb 01eh	; 747b
	defb 004h	; 747c
	defb 003h	; 747d
	defb 003h	; 747e
	defb 002h	; 747f
	defb 004h	; 7480
	defb 002h	; 7481
	defb 003h	; 7482
	defb 002h	; 7483
	defb 004h	; 7484
	defb 004h	; 7485
	defb 003h	; 7486
	defb 004h	; 7487
	defb 004h	; 7488
	defb 004h	; 7489
	defb 003h	; 748a
	defb 008h	; 748b
	defb 034h	; 748c
	defb 081h	; 748d
	defb 004h	; 748e
	defb 005h	; 748f
	defb 034h	; 7490
	defb 083h	; 7491
	defb 004h	; 7492
	defb 034h	; 7493
	defb 004h	; 7494
	defb 007h	; 7495
	defb 034h	; 7496
	defb 081h	; 7497
	defb 004h	; 7498
	defb 006h	; 7499
	defb 034h	; 749a
	defb 002h	; 749b
	defb 004h	; 749c
	defb 004h	; 749d
	defb 034h	; 749e
	defb 084h	; 749f
	defb 003h	; 74a0
	defb 034h	; 74a1
	defb 034h	; 74a2
	defb 043h	; 74a3
	defb 004h	; 74a4
	defb 003h	; 74a5
	defb 003h	; 74a6
	defb 004h	; 74a7
	defb 081h	; 74a8
	defb 003h	; 74a9
	defb 004h	; 74aa
	defb 034h	; 74ab
	defb 002h	; 74ac
	defb 003h	; 74ad
	defb 002h	; 74ae
	defb 004h	; 74af
	defb 007h	; 74b0
	defb 034h	; 74b1
	defb 002h	; 74b2
	defb 002h	; 74b3
	defb 005h	; 74b4
	defb 032h	; 74b5
	defb 082h	; 74b6
	defb 003h	; 74b7
	defb 034h	; 74b8
	defb 005h	; 74b9
	defb 003h	; 74ba
	defb 002h	; 74bb
	defb 004h	; 74bc
	defb 002h	; 74bd
	defb 002h	; 74be
	defb 006h	; 74bf
	defb 032h	; 74c0
	defb 002h	; 74c1
	defb 003h	; 74c2
	defb 002h	; 74c3
	defb 002h	; 74c4
	defb 008h	; 74c5
	defb 003h	; 74c6
	defb 004h	; 74c7
	defb 004h	; 74c8
	defb 081h	; 74c9
	defb 043h	; 74ca
	defb 004h	; 74cb
	defb 003h	; 74cc
	defb 004h	; 74cd
	defb 004h	; 74ce
	defb 003h	; 74cf
	defb 034h	; 74d0
	defb 081h	; 74d1
	defb 004h	; 74d2
	defb 003h	; 74d3
	defb 034h	; 74d4
	defb 005h	; 74d5
	defb 002h	; 74d6
	defb 083h	; 74d7
	defb 032h	; 74d8
	defb 002h	; 74d9
	defb 002h	; 74da
	defb 000h	; 74db

; ======================================================================
; CODIGO 0x74dc..0x74fe  (34 bytes)
; ======================================================================


L_74DC:
	ld hl,0e051h		;74dc   ; tanda 10: el color de los dos volcados de 0x7071, tambien uno por equipo
	ld (0e52ah),hl		;74df
	ld de,074feh		;74e2
	ld hl,00998h		;74e5
	ld b,002h		;74e8
	call L_46BA		;74ea
	ld hl,0e056h		;74ed   ; y el segundo, con la otra paleta
	ld (0e52ah),hl		;74f0
	ld de,074feh		;74f3
	ld hl,00a58h		;74f6
	ld b,002h		;74f9
	jp L_46BA		;74fb

; ----------------------------------------------------------------------
; DATOS color_recoloreado_74fe: 95 bytes que dan 192 de VRAM, a 0x0998 y
;   0x0A58: el color de los patrones de 0x7087
;   0x74fe..0x755d  (95 bytes)
DATA_color_recoloreado_74fe:
	defb 020h	; 74fe
	defb 030h	; 74ff
	defb 005h	; 7500
	defb 003h	; 7501
	defb 003h	; 7502
	defb 000h	; 7503
	defb 005h	; 7504
	defb 030h	; 7505
	defb 003h	; 7506
	defb 040h	; 7507
	defb 002h	; 7508
	defb 002h	; 7509
	defb 005h	; 750a
	defb 032h	; 750b
	defb 081h	; 750c
	defb 003h	; 750d
	defb 005h	; 750e
	defb 040h	; 750f
	defb 084h	; 7510
	defb 030h	; 7511
	defb 040h	; 7512
	defb 040h	; 7513
	defb 034h	; 7514
	defb 004h	; 7515
	defb 030h	; 7516
	defb 003h	; 7517
	defb 040h	; 7518
	defb 005h	; 7519
	defb 030h	; 751a
	defb 003h	; 751b
	defb 040h	; 751c
	defb 082h	; 751d
	defb 034h	; 751e
	defb 030h	; 751f
	defb 003h	; 7520
	defb 034h	; 7521
	defb 006h	; 7522
	defb 040h	; 7523
	defb 003h	; 7524
	defb 034h	; 7525
	defb 083h	; 7526
	defb 030h	; 7527
	defb 034h	; 7528
	defb 004h	; 7529
	defb 00bh	; 752a
	defb 034h	; 752b
	defb 002h	; 752c
	defb 024h	; 752d
	defb 005h	; 752e
	defb 032h	; 752f
	defb 081h	; 7530
	defb 043h	; 7531
	defb 004h	; 7532
	defb 030h	; 7533
	defb 002h	; 7534
	defb 002h	; 7535
	defb 005h	; 7536
	defb 032h	; 7537
	defb 081h	; 7538
	defb 003h	; 7539
	defb 008h	; 753a
	defb 043h	; 753b
	defb 081h	; 753c
	defb 040h	; 753d
	defb 005h	; 753e
	defb 043h	; 753f
	defb 002h	; 7540
	defb 040h	; 7541
	defb 008h	; 7542
	defb 030h	; 7543
	defb 002h	; 7544
	defb 000h	; 7545
	defb 005h	; 7546
	defb 004h	; 7547
	defb 002h	; 7548
	defb 000h	; 7549
	defb 002h	; 754a
	defb 004h	; 754b
	defb 003h	; 754c
	defb 034h	; 754d
	defb 004h	; 754e
	defb 003h	; 754f
	defb 003h	; 7550
	defb 004h	; 7551
	defb 003h	; 7552
	defb 000h	; 7553
	defb 081h	; 7554
	defb 004h	; 7555
	defb 008h	; 7556
	defb 034h	; 7557
	defb 005h	; 7558
	defb 003h	; 7559
	defb 002h	; 755a
	defb 004h	; 755b
	defb 000h	; 755c

; ======================================================================
; CODIGO 0x755d..0x7566  (9 bytes)
; ======================================================================


L_755D:
	ld hl,00200h		;755d
	ld de,07566h		;7560
	jp descomprime_en_los_tres_tercios		;7563

; ----------------------------------------------------------------------
; DATOS color_7566: 213 bytes comprimidos que dan 400 de VRAM en 0x0200; lo
;   carga 0x7563. Va a los TRES tercios de SCREEN 2
;   0x7566..0x763b  (213 bytes)
DATA_color_7566:
	defb 008h	; 7566
	defb 0bch	; 7567
	defb 002h	; 7568
	defb 0c1h	; 7569
	defb 005h	; 756a
	defb 0b1h	; 756b
	defb 005h	; 756c
	defb 0cbh	; 756d
	defb 085h	; 756e
	defb 0c6h	; 756f
	defb 0cbh	; 7570
	defb 0c6h	; 7571
	defb 0cbh	; 7572
	defb 0c6h	; 7573
	defb 006h	; 7574
	defb 0b6h	; 7575
	defb 081h	; 7576
	defb 0c6h	; 7577
	defb 004h	; 7578
	defb 0cbh	; 7579
	defb 004h	; 757a
	defb 0c6h	; 757b
	defb 006h	; 757c
	defb 0cbh	; 757d
	defb 002h	; 757e
	defb 0c6h	; 757f
	defb 008h	; 7580
	defb 06ch	; 7581
	defb 002h	; 7582
	defb 0cah	; 7583
	defb 005h	; 7584
	defb 06ah	; 7585
	defb 005h	; 7586
	defb 0c6h	; 7587
	defb 085h	; 7588
	defb 0cfh	; 7589
	defb 0c6h	; 758a
	defb 0cfh	; 758b
	defb 0c6h	; 758c
	defb 0cfh	; 758d
	defb 006h	; 758e
	defb 06fh	; 758f
	defb 081h	; 7590
	defb 0cfh	; 7591
	defb 004h	; 7592
	defb 0c6h	; 7593
	defb 004h	; 7594
	defb 0cfh	; 7595
	defb 006h	; 7596
	defb 0c6h	; 7597
	defb 002h	; 7598
	defb 0cfh	; 7599
	defb 008h	; 759a
	defb 0bch	; 759b
	defb 002h	; 759c
	defb 0c6h	; 759d
	defb 005h	; 759e
	defb 0b6h	; 759f
	defb 005h	; 75a0
	defb 0cbh	; 75a1
	defb 085h	; 75a2
	defb 0c1h	; 75a3
	defb 0cbh	; 75a4
	defb 0c1h	; 75a5
	defb 0cbh	; 75a6
	defb 0c1h	; 75a7
	defb 006h	; 75a8
	defb 0b1h	; 75a9
	defb 081h	; 75aa
	defb 0c1h	; 75ab
	defb 004h	; 75ac
	defb 0cbh	; 75ad
	defb 004h	; 75ae
	defb 0c1h	; 75af
	defb 006h	; 75b0
	defb 0cbh	; 75b1
	defb 002h	; 75b2
	defb 0c1h	; 75b3
	defb 008h	; 75b4
	defb 0bch	; 75b5
	defb 002h	; 75b6
	defb 0c6h	; 75b7
	defb 005h	; 75b8
	defb 0b6h	; 75b9
	defb 005h	; 75ba
	defb 0cbh	; 75bb
	defb 085h	; 75bc
	defb 0c4h	; 75bd
	defb 0cbh	; 75be
	defb 0c4h	; 75bf
	defb 0cbh	; 75c0
	defb 0c4h	; 75c1
	defb 006h	; 75c2
	defb 0b4h	; 75c3
	defb 081h	; 75c4
	defb 0c4h	; 75c5
	defb 004h	; 75c6
	defb 0cbh	; 75c7
	defb 004h	; 75c8
	defb 0c4h	; 75c9
	defb 006h	; 75ca
	defb 0cbh	; 75cb
	defb 002h	; 75cc
	defb 0c4h	; 75cd
	defb 008h	; 75ce
	defb 06ch	; 75cf
	defb 002h	; 75d0
	defb 0c1h	; 75d1
	defb 005h	; 75d2
	defb 061h	; 75d3
	defb 005h	; 75d4
	defb 0c6h	; 75d5
	defb 085h	; 75d6
	defb 0cfh	; 75d7
	defb 0c6h	; 75d8
	defb 0cfh	; 75d9
	defb 0c6h	; 75da
	defb 0cfh	; 75db
	defb 006h	; 75dc
	defb 06fh	; 75dd
	defb 081h	; 75de
	defb 0cfh	; 75df
	defb 004h	; 75e0
	defb 0c6h	; 75e1
	defb 004h	; 75e2
	defb 0cfh	; 75e3
	defb 006h	; 75e4
	defb 0c6h	; 75e5
	defb 002h	; 75e6
	defb 0cfh	; 75e7
	defb 008h	; 75e8
	defb 06ch	; 75e9
	defb 002h	; 75ea
	defb 0cbh	; 75eb
	defb 005h	; 75ec
	defb 06bh	; 75ed
	defb 005h	; 75ee
	defb 0c6h	; 75ef
	defb 085h	; 75f0
	defb 0c1h	; 75f1
	defb 0c6h	; 75f2
	defb 0c1h	; 75f3
	defb 0c6h	; 75f4
	defb 0c1h	; 75f5
	defb 006h	; 75f6
	defb 061h	; 75f7
	defb 081h	; 75f8
	defb 0c1h	; 75f9
	defb 004h	; 75fa
	defb 0c6h	; 75fb
	defb 004h	; 75fc
	defb 0c1h	; 75fd
	defb 006h	; 75fe
	defb 0c6h	; 75ff
	defb 002h	; 7600
	defb 0c1h	; 7601
	defb 008h	; 7602
	defb 0bch	; 7603
	defb 002h	; 7604
	defb 0c6h	; 7605
	defb 005h	; 7606
	defb 0b6h	; 7607
	defb 005h	; 7608
	defb 0cbh	; 7609
	defb 085h	; 760a
	defb 0cdh	; 760b
	defb 0cbh	; 760c
	defb 0cdh	; 760d
	defb 0cbh	; 760e
	defb 0cdh	; 760f
	defb 006h	; 7610
	defb 0bdh	; 7611
	defb 081h	; 7612
	defb 0cdh	; 7613
	defb 004h	; 7614
	defb 0cbh	; 7615
	defb 004h	; 7616
	defb 0cdh	; 7617
	defb 006h	; 7618
	defb 0cbh	; 7619
	defb 002h	; 761a
	defb 0cdh	; 761b
	defb 008h	; 761c
	defb 0bch	; 761d
	defb 002h	; 761e
	defb 0c4h	; 761f
	defb 005h	; 7620
	defb 0b4h	; 7621
	defb 005h	; 7622
	defb 0cbh	; 7623
	defb 085h	; 7624
	defb 0c1h	; 7625
	defb 0cbh	; 7626
	defb 0c1h	; 7627
	defb 0cbh	; 7628
	defb 0c1h	; 7629
	defb 006h	; 762a
	defb 0b1h	; 762b
	defb 081h	; 762c
	defb 0c1h	; 762d
	defb 004h	; 762e
	defb 0cbh	; 762f
	defb 004h	; 7630
	defb 0c1h	; 7631
	defb 006h	; 7632
	defb 0cbh	; 7633
	defb 002h	; 7634
	defb 0c1h	; 7635
	defb 008h	; 7636
	defb 030h	; 7637
	defb 008h	; 7638
	defb 0c0h	; 7639
	defb 000h	; 763a

; ======================================================================
; CODIGO 0x763b..0x7659  (30 bytes)
; ======================================================================


L_763B:
	ld hl,0e051h		;763b   ; el color de la celebracion del gol, un volcado por camiseta
	ld (0e52ah),hl		;763e
	ld de,07659h		;7641
	ld hl,00370h		;7644
	call L_46B8		;7647
	ld hl,0e056h		;764a
	ld (0e52ah),hl		;764d
	ld de,07659h		;7650
	ld hl,005e0h		;7653
	jp L_46B8		;7656

; ----------------------------------------------------------------------
; DATOS color_recoloreado_7659: 62 bytes que dan 160 de VRAM, a 0x0370 y
;   0x05E0: el color de los patrones de 0x720F
;   0x7659..0x7697  (62 bytes)
DATA_color_recoloreado_7659:
	defb 005h	; 7659
	defb 002h	; 765a
	defb 002h	; 765b
	defb 003h	; 765c
	defb 004h	; 765d
	defb 002h	; 765e
	defb 005h	; 765f
	defb 023h	; 7660
	defb 008h	; 7661
	defb 003h	; 7662
	defb 006h	; 7663
	defb 004h	; 7664
	defb 007h	; 7665
	defb 034h	; 7666
	defb 003h	; 7667
	defb 003h	; 7668
	defb 00ah	; 7669
	defb 004h	; 766a
	defb 003h	; 766b
	defb 003h	; 766c
	defb 003h	; 766d
	defb 034h	; 766e
	defb 003h	; 766f
	defb 002h	; 7670
	defb 005h	; 7671
	defb 003h	; 7672
	defb 002h	; 7673
	defb 002h	; 7674
	defb 005h	; 7675
	defb 023h	; 7676
	defb 009h	; 7677
	defb 003h	; 7678
	defb 005h	; 7679
	defb 034h	; 767a
	defb 013h	; 767b
	defb 003h	; 767c
	defb 007h	; 767d
	defb 002h	; 767e
	defb 082h	; 767f
	defb 042h	; 7680
	defb 004h	; 7681
	defb 007h	; 7682
	defb 003h	; 7683
	defb 081h	; 7684
	defb 004h	; 7685
	defb 007h	; 7686
	defb 003h	; 7687
	defb 009h	; 7688
	defb 034h	; 7689
	defb 005h	; 768a
	defb 003h	; 768b
	defb 002h	; 768c
	defb 004h	; 768d
	defb 007h	; 768e
	defb 003h	; 768f
	defb 081h	; 7690
	defb 004h	; 7691
	defb 007h	; 7692
	defb 003h	; 7693
	defb 081h	; 7694
	defb 004h	; 7695
	defb 000h	; 7696

; ======================================================================
; CODIGO 0x7697..0x76a9  (18 bytes)
; ======================================================================


L_7697:
	ld de,076a9h		;7697   ; el color del penalti, en 0x0200 y 0x0290
	ld hl,00200h		;769a
	call descomprime_en_los_tres_tercios		;769d
	ld de,076b0h		;76a0
	ld hl,00290h		;76a3
	jp descomprime_en_los_tres_tercios		;76a6

; ----------------------------------------------------------------------
; DATOS color_76a9: 19 bytes comprimidos que dan 144 de VRAM en 0x0200; lo
;   carga 0x769D. Va a los TRES tercios de SCREEN 2
;   0x76a9..0x76bc  (19 bytes)
DATA_color_76a9:
	defb 084h	; 76a9
	defb 060h	; 76aa
	defb 090h	; 76ab
	defb 080h	; 76ac
	defb 060h	; 76ad
	defb 024h	; 76ae
	defb 0cfh	; 76af
	defb 008h	; 76b0
	defb 0cfh	; 76b1
	defb 008h	; 76b2
	defb 0c6h	; 76b3
	defb 084h	; 76b4
	defb 060h	; 76b5
	defb 090h	; 76b6
	defb 080h	; 76b7
	defb 060h	; 76b8
	defb 054h	; 76b9
	defb 0cfh	; 76ba
	defb 000h	; 76bb

; ======================================================================
; CODIGO 0x76bc..0x76f0  (52 bytes)
; ======================================================================


L_76BC:
	ld de,076f0h		;76bc   ; LOS SPRITES DEL PARTIDO, que no van derechos a la VRAM
	call descomprime_en_la_ram		;76bf   ; primero se descomprimen en la RAM, en 0xE600
	ld de,0e600h		;76c2   ; y de ahi se copian de golpe: 0x2E0 bytes, o sea 23 sprites de 16x16
	ld hl,01800h		;76c5
	ld bc,002e0h		;76c8
	call copia_a_la_vram		;76cb
	ld de,0e600h		;76ce   ; luego los mismos 23, leidos otra vez de la RAM y escritos ESPEJADOS: son los jugadores mirando al otro lado
	ld hl,01af0h		;76d1
	ld c,017h		;76d4
	call espeja_sprites_desde_la_ram		;76d6
	ld de,078f6h		;76d9   ; y detras, un bloque mas que ya lleva su destino dentro
	jp descomprime_con_destino_dentro		;76dc
L_76DF:
	ld de,079fdh		;76df   ; los sprites de la celebracion del gol
	call descomprime_con_destino_dentro		;76e2
	ld hl,018e0h		;76e5   ; y doce de ellos, espejados de la VRAM a la VRAM
	ld de,01bd0h		;76e8
	ld c,00ch		;76eb
	jp espeja_sprites_en_la_vram		;76ed

; ----------------------------------------------------------------------
; DATOS sprites_por_la_ram: no van directos a la VRAM: 0x76BC los descomprime
;   a la RAM en 0xE600 y 0x76C8 copia 0x2E0 bytes con LDIRVM a 0x1800, o sea
;   23 sprites de 16x16; luego 0x76D6 escribe otros 23 ESPEJADOS en 0x1AE0
;   0x76f0..0x78f6  (518 bytes)
DATA_sprites_por_la_ram:
	defb 018h	; 76f0
	defb 000h	; 76f1
	defb 087h	; 76f2
	defb 07ch	; 76f3
	defb 0feh	; 76f4
	defb 02fh	; 76f5
	defb 02fh	; 76f6
	defb 00bh	; 76f7
	defb 043h	; 76f8
	defb 0e6h	; 76f9
	defb 00dh	; 76fa
	defb 000h	; 76fb
	defb 002h	; 76fc
	defb 001h	; 76fd
	defb 00ch	; 76fe
	defb 000h	; 76ff
	defb 081h	; 7700
	defb 07fh	; 7701
	defb 004h	; 7702
	defb 0feh	; 7703
	defb 08fh	; 7704
	defb 07eh	; 7705
	defb 000h	; 7706
	defb 002h	; 7707
	defb 006h	; 7708
	defb 004h	; 7709
	defb 000h	; 770a
	defb 003h	; 770b
	defb 004h	; 770c
	defb 004h	; 770d
	defb 002h	; 770e
	defb 007h	; 770f
	defb 007h	; 7710
	defb 00fh	; 7711
	defb 00eh	; 7712
	defb 00eh	; 7713
	defb 003h	; 7714
	defb 000h	; 7715
	defb 002h	; 7716
	defb 00eh	; 7717
	defb 08bh	; 7718
	defb 007h	; 7719
	defb 003h	; 771a
	defb 0fbh	; 771b
	defb 006h	; 771c
	defb 006h	; 771d
	defb 038h	; 771e
	defb 0b8h	; 771f
	defb 038h	; 7720
	defb 03ch	; 7721
	defb 01ch	; 7722
	defb 01eh	; 7723
	defb 003h	; 7724
	defb 000h	; 7725
	defb 002h	; 7726
	defb 001h	; 7727
	defb 002h	; 7728
	defb 003h	; 7729
	defb 084h	; 772a
	defb 000h	; 772b
	defb 003h	; 772c
	defb 003h	; 772d
	defb 001h	; 772e
	defb 005h	; 772f
	defb 000h	; 7730
	defb 08bh	; 7731
	defb 00fh	; 7732
	defb 01fh	; 7733
	defb 0fch	; 7734
	defb 0f0h	; 7735
	defb 0f0h	; 7736
	defb 0f8h	; 7737
	defb 0fch	; 7738
	defb 004h	; 7739
	defb 0f8h	; 773a
	defb 0f8h	; 773b
	defb 0c4h	; 773c
	defb 005h	; 773d
	defb 000h	; 773e
	defb 082h	; 773f
	defb 00fh	; 7740
	defb 01fh	; 7741
	defb 00ah	; 7742
	defb 000h	; 7743
	defb 002h	; 7744
	defb 001h	; 7745
	defb 00ch	; 7746
	defb 000h	; 7747
	defb 088h	; 7748
	defb 07ch	; 7749
	defb 0feh	; 774a
	defb 0f7h	; 774b
	defb 057h	; 774c
	defb 055h	; 774d
	defb 001h	; 774e
	defb 023h	; 774f
	defb 0e0h	; 7750
	defb 00ah	; 7751
	defb 000h	; 7752
	defb 002h	; 7753
	defb 001h	; 7754
	defb 00ch	; 7755
	defb 000h	; 7756
	defb 082h	; 7757
	defb 07ch	; 7758
	defb 0feh	; 7759
	defb 005h	; 775a
	defb 0ffh	; 775b
	defb 081h	; 775c
	defb 07eh	; 775d
	defb 00dh	; 775e
	defb 000h	; 775f
	defb 002h	; 7760
	defb 001h	; 7761
	defb 00bh	; 7762
	defb 000h	; 7763
	defb 005h	; 7764
	defb 0ffh	; 7765
	defb 08fh	; 7766
	defb 0feh	; 7767
	defb 000h	; 7768
	defb 060h	; 7769
	defb 0e0h	; 776a
	defb 0c0h	; 776b
	defb 0e0h	; 776c
	defb 06fh	; 776d
	defb 000h	; 776e
	defb 000h	; 776f
	defb 003h	; 7770
	defb 03bh	; 7771
	defb 039h	; 7772
	defb 019h	; 7773
	defb 003h	; 7774
	defb 003h	; 7775
	defb 004h	; 7776
	defb 000h	; 7777
	defb 003h	; 7778
	defb 020h	; 7779
	defb 085h	; 777a
	defb 0a0h	; 777b
	defb 060h	; 777c
	defb 000h	; 777d
	defb 080h	; 777e
	defb 080h	; 777f
	defb 003h	; 7780
	defb 0c0h	; 7781
	defb 083h	; 7782
	defb 080h	; 7783
	defb 000h	; 7784
	defb 000h	; 7785
	defb 005h	; 7786
	defb 0ffh	; 7787
	defb 085h	; 7788
	defb 0c1h	; 7789
	defb 0ffh	; 778a
	defb 0ffh	; 778b
	defb 0fch	; 778c
	defb 000h	; 778d
	defb 003h	; 778e
	defb 030h	; 778f
	defb 085h	; 7790
	defb 000h	; 7791
	defb 00eh	; 7792
	defb 00fh	; 7793
	defb 000h	; 7794
	defb 080h	; 7795
	defb 01fh	; 7796
	defb 000h	; 7797
	defb 08dh	; 7798
	defb 030h	; 7799
	defb 038h	; 779a
	defb 01ch	; 779b
	defb 01ch	; 779c
	defb 07fh	; 779d
	defb 038h	; 779e
	defb 040h	; 779f
	defb 0f0h	; 77a0
	defb 0ech	; 77a1
	defb 0f0h	; 77a2
	defb 078h	; 77a3
	defb 070h	; 77a4
	defb 020h	; 77a5
	defb 010h	; 77a6
	defb 000h	; 77a7
	defb 092h	; 77a8
	defb 001h	; 77a9
	defb 000h	; 77aa
	defb 03eh	; 77ab
	defb 04fh	; 77ac
	defb 0c7h	; 77ad
	defb 0e3h	; 77ae
	defb 0e3h	; 77af
	defb 000h	; 77b0
	defb 0c7h	; 77b1
	defb 0beh	; 77b2
	defb 00ch	; 77b3
	defb 000h	; 77b4
	defb 000h	; 77b5
	defb 004h	; 77b6
	defb 00ch	; 77b7
	defb 05ch	; 77b8
	defb 0f8h	; 77b9
	defb 0e0h	; 77ba
	defb 003h	; 77bb
	defb 01fh	; 77bc
	defb 004h	; 77bd
	defb 00fh	; 77be
	defb 083h	; 77bf
	defb 01fh	; 77c0
	defb 03fh	; 77c1
	defb 078h	; 77c2
	defb 003h	; 77c3
	defb 070h	; 77c4
	defb 004h	; 77c5
	defb 000h	; 77c6
	defb 002h	; 77c7
	defb 0f0h	; 77c8
	defb 003h	; 77c9
	defb 0f8h	; 77ca
	defb 086h	; 77cb
	defb 0f0h	; 77cc
	defb 0e0h	; 77cd
	defb 0e0h	; 77ce
	defb 0f8h	; 77cf
	defb 07ch	; 77d0
	defb 01ch	; 77d1
	defb 004h	; 77d2
	defb 000h	; 77d3
	defb 089h	; 77d4
	defb 007h	; 77d5
	defb 002h	; 77d6
	defb 000h	; 77d7
	defb 000h	; 77d8
	defb 008h	; 77d9
	defb 000h	; 77da
	defb 00fh	; 77db
	defb 007h	; 77dc
	defb 002h	; 77dd
	defb 003h	; 77de
	defb 000h	; 77df
	defb 092h	; 77e0
	defb 050h	; 77e1
	defb 0f0h	; 77e2
	defb 0e0h	; 77e3
	defb 000h	; 77e4
	defb 0e0h	; 77e5
	defb 070h	; 77e6
	defb 030h	; 77e7
	defb 070h	; 77e8
	defb 0f0h	; 77e9
	defb 020h	; 77ea
	defb 0e0h	; 77eb
	defb 0a0h	; 77ec
	defb 000h	; 77ed
	defb 006h	; 77ee
	defb 003h	; 77ef
	defb 003h	; 77f0
	defb 007h	; 77f1
	defb 003h	; 77f2
	defb 005h	; 77f3
	defb 000h	; 77f4
	defb 085h	; 77f5
	defb 077h	; 77f6
	defb 0ffh	; 77f7
	defb 0ffh	; 77f8
	defb 00fh	; 77f9
	defb 007h	; 77fa
	defb 009h	; 77fb
	defb 000h	; 77fc
	defb 003h	; 77fd
	defb 0f0h	; 77fe
	defb 003h	; 77ff
	defb 0ffh	; 7800
	defb 086h	; 7801
	defb 0feh	; 7802
	defb 0f0h	; 7803
	defb 078h	; 7804
	defb 07ch	; 7805
	defb 038h	; 7806
	defb 010h	; 7807
	defb 005h	; 7808
	defb 000h	; 7809
	defb 081h	; 780a
	defb 080h	; 780b
	defb 003h	; 780c
	defb 0c0h	; 780d
	defb 00ah	; 780e
	defb 000h	; 780f
	defb 088h	; 7810
	defb 07eh	; 7811
	defb 0cfh	; 7812
	defb 087h	; 7813
	defb 00fh	; 7814
	defb 01fh	; 7815
	defb 002h	; 7816
	defb 0fch	; 7817
	defb 08ch	; 7818
	defb 003h	; 7819
	defb 000h	; 781a
	defb 087h	; 781b
	defb 003h	; 781c
	defb 007h	; 781d
	defb 00eh	; 781e
	defb 01ch	; 781f
	defb 008h	; 7820
	defb 07fh	; 7821
	defb 0ffh	; 7822
	defb 004h	; 7823
	defb 03fh	; 7824
	defb 085h	; 7825
	defb 01fh	; 7826
	defb 00fh	; 7827
	defb 003h	; 7828
	defb 001h	; 7829
	defb 001h	; 782a
	defb 005h	; 782b
	defb 000h	; 782c
	defb 086h	; 782d
	defb 0c0h	; 782e
	defb 0f0h	; 782f
	defb 0f8h	; 7830
	defb 0fch	; 7831
	defb 0cch	; 7832
	defb 0cch	; 7833
	defb 004h	; 7834
	defb 0c0h	; 7835
	defb 003h	; 7836
	defb 0e0h	; 7837
	defb 083h	; 7838
	defb 080h	; 7839
	defb 000h	; 783a
	defb 000h	; 783b
	defb 003h	; 783c
	defb 00fh	; 783d
	defb 086h	; 783e
	defb 0cfh	; 783f
	defb 09fh	; 7840
	defb 098h	; 7841
	defb 0dfh	; 7842
	defb 00fh	; 7843
	defb 007h	; 7844
	defb 005h	; 7845
	defb 000h	; 7846
	defb 083h	; 7847
	defb 001h	; 7848
	defb 003h	; 7849
	defb 0c0h	; 784a
	defb 004h	; 784b
	defb 0e0h	; 784c
	defb 083h	; 784d
	defb 060h	; 784e
	defb 0c0h	; 784f
	defb 0c0h	; 7850
	defb 005h	; 7851
	defb 000h	; 7852
	defb 002h	; 7853
	defb 0e0h	; 7854
	defb 088h	; 7855
	defb 0c0h	; 7856
	defb 01fh	; 7857
	defb 03fh	; 7858
	defb 07fh	; 7859
	defb 07fh	; 785a
	defb 0ffh	; 785b
	defb 0ffh	; 785c
	defb 07fh	; 785d
	defb 004h	; 785e
	defb 03fh	; 785f
	defb 08dh	; 7860
	defb 01fh	; 7861
	defb 00fh	; 7862
	defb 007h	; 7863
	defb 000h	; 7864
	defb 000h	; 7865
	defb 080h	; 7866
	defb 0e0h	; 7867
	defb 0f0h	; 7868
	defb 0f8h	; 7869
	defb 0d8h	; 786a
	defb 0d8h	; 786b
	defb 0c0h	; 786c
	defb 0c0h	; 786d
	defb 003h	; 786e
	defb 080h	; 786f
	defb 003h	; 7870
	defb 0c0h	; 7871
	defb 002h	; 7872
	defb 000h	; 7873
	defb 002h	; 7874
	defb 01fh	; 7875
	defb 003h	; 7876
	defb 00fh	; 7877
	defb 084h	; 7878
	defb 008h	; 7879
	defb 01fh	; 787a
	defb 03fh	; 787b
	defb 007h	; 787c
	defb 004h	; 787d
	defb 000h	; 787e
	defb 083h	; 787f
	defb 038h	; 7880
	defb 078h	; 7881
	defb 0f0h	; 7882
	defb 003h	; 7883
	defb 0c0h	; 7884
	defb 002h	; 7885
	defb 0e0h	; 7886
	defb 08ch	; 7887
	defb 060h	; 7888
	defb 0c0h	; 7889
	defb 0c0h	; 788a
	defb 000h	; 788b
	defb 000h	; 788c
	defb 060h	; 788d
	defb 070h	; 788e
	defb 070h	; 788f
	defb 060h	; 7890
	defb 000h	; 7891
	defb 000h	; 7892
	defb 013h	; 7893
	defb 003h	; 7894
	defb 03fh	; 7895
	defb 085h	; 7896
	defb 01fh	; 7897
	defb 000h	; 7898
	defb 01fh	; 7899
	defb 02fh	; 789a
	defb 006h	; 789b
	defb 004h	; 789c
	defb 000h	; 789d
	defb 094h	; 789e
	defb 050h	; 789f
	defb 0f0h	; 78a0
	defb 0e0h	; 78a1
	defb 0c0h	; 78a2
	defb 080h	; 78a3
	defb 000h	; 78a4
	defb 080h	; 78a5
	defb 080h	; 78a6
	defb 000h	; 78a7
	defb 000h	; 78a8
	defb 0c0h	; 78a9
	defb 000h	; 78aa
	defb 000h	; 78ab
	defb 010h	; 78ac
	defb 030h	; 78ad
	defb 070h	; 78ae
	defb 060h	; 78af
	defb 000h	; 78b0
	defb 000h	; 78b1
	defb 03fh	; 78b2
	defb 004h	; 78b3
	defb 07fh	; 78b4
	defb 002h	; 78b5
	defb 0ffh	; 78b6
	defb 002h	; 78b7
	defb 07fh	; 78b8
	defb 08dh	; 78b9
	defb 077h	; 78ba
	defb 0f7h	; 78bb
	defb 0e3h	; 78bc
	defb 0e0h	; 78bd
	defb 0e0h	; 78be
	defb 000h	; 78bf
	defb 000h	; 78c0
	defb 080h	; 78c1
	defb 0c0h	; 78c2
	defb 0c0h	; 78c3
	defb 0e0h	; 78c4
	defb 0e0h	; 78c5
	defb 0c0h	; 78c6
	defb 003h	; 78c7
	defb 080h	; 78c8
	defb 002h	; 78c9
	defb 0c0h	; 78ca
	defb 081h	; 78cb
	defb 080h	; 78cc
	defb 004h	; 78cd
	defb 000h	; 78ce
	defb 090h	; 78cf
	defb 04fh	; 78d0
	defb 0feh	; 78d1
	defb 0fch	; 78d2
	defb 0feh	; 78d3
	defb 0ffh	; 78d4
	defb 083h	; 78d5
	defb 0ffh	; 78d6
	defb 09fh	; 78d7
	defb 006h	; 78d8
	defb 000h	; 78d9
	defb 000h	; 78da
	defb 008h	; 78db
	defb 038h	; 78dc
	defb 039h	; 78dd
	defb 00fh	; 78de
	defb 00eh	; 78df
	defb 010h	; 78e0
	defb 000h	; 78e1
	defb 082h	; 78e2
	defb 07eh	; 78e3
	defb 0ffh	; 78e4
	defb 003h	; 78e5
	defb 07fh	; 78e6
	defb 08bh	; 78e7
	defb 041h	; 78e8
	defb 0ffh	; 78e9
	defb 0ffh	; 78ea
	defb 08eh	; 78eb
	defb 000h	; 78ec
	defb 000h	; 78ed
	defb 01ch	; 78ee
	defb 01ch	; 78ef
	defb 018h	; 78f0
	defb 007h	; 78f1
	defb 00fh	; 78f2
	defb 010h	; 78f3
	defb 000h	; 78f4
	defb 000h	; 78f5

; ----------------------------------------------------------------------
; DATOS patrones_de_sprite_78f6: 263 bytes comprimidos que dan 576 de VRAM en
;   0x1DC0; lo carga 0x76DC
;   0x78f6..0x79fd  (263 bytes)
DATA_patrones_de_sprite_78f6:
	defb 0c0h	; 78f6
	defb 01dh	; 78f7
	defb 089h	; 78f8
	defb 006h	; 78f9
	defb 00fh	; 78fa
	defb 06fh	; 78fb
	defb 0f3h	; 78fc
	defb 0f1h	; 78fd
	defb 0f0h	; 78fe
	defb 060h	; 78ff
	defb 000h	; 7900
	defb 001h	; 7901
	defb 007h	; 7902
	defb 000h	; 7903
	defb 089h	; 7904
	defb 070h	; 7905
	defb 0f8h	; 7906
	defb 0f0h	; 7907
	defb 0f0h	; 7908
	defb 0f8h	; 7909
	defb 018h	; 790a
	defb 078h	; 790b
	defb 0f0h	; 790c
	defb 0c0h	; 790d
	defb 004h	; 790e
	defb 000h	; 790f
	defb 08ch	; 7910
	defb 058h	; 7911
	defb 078h	; 7912
	defb 0f0h	; 7913
	defb 00eh	; 7914
	defb 01fh	; 7915
	defb 00fh	; 7916
	defb 00fh	; 7917
	defb 01fh	; 7918
	defb 018h	; 7919
	defb 01eh	; 791a
	defb 00fh	; 791b
	defb 003h	; 791c
	defb 004h	; 791d
	defb 000h	; 791e
	defb 08ch	; 791f
	defb 01ah	; 7920
	defb 01eh	; 7921
	defb 00fh	; 7922
	defb 060h	; 7923
	defb 0f0h	; 7924
	defb 0f6h	; 7925
	defb 0cfh	; 7926
	defb 08fh	; 7927
	defb 00fh	; 7928
	defb 006h	; 7929
	defb 000h	; 792a
	defb 080h	; 792b
	defb 007h	; 792c
	defb 000h	; 792d
	defb 088h	; 792e
	defb 00ch	; 792f
	defb 07eh	; 7930
	defb 072h	; 7931
	defb 033h	; 7932
	defb 037h	; 7933
	defb 0fch	; 7934
	defb 04ch	; 7935
	defb 004h	; 7936
	defb 018h	; 7937
	defb 000h	; 7938
	defb 088h	; 7939
	defb 030h	; 793a
	defb 000h	; 793b
	defb 08dh	; 793c
	defb 0cch	; 793d
	defb 0c8h	; 793e
	defb 003h	; 793f
	defb 032h	; 7940
	defb 038h	; 7941
	defb 018h	; 7942
	defb 000h	; 7943
	defb 089h	; 7944
	defb 033h	; 7945
	defb 03fh	; 7946
	defb 03fh	; 7947
	defb 00fh	; 7948
	defb 077h	; 7949
	defb 0fbh	; 794a
	defb 0fbh	; 794b
	defb 077h	; 794c
	defb 00eh	; 794d
	defb 003h	; 794e
	defb 000h	; 794f
	defb 081h	; 7950
	defb 002h	; 7951
	defb 003h	; 7952
	defb 003h	; 7953
	defb 084h	; 7954
	defb 080h	; 7955
	defb 0c0h	; 7956
	defb 080h	; 7957
	defb 080h	; 7958
	defb 003h	; 7959
	defb 0c0h	; 795a
	defb 005h	; 795b
	defb 000h	; 795c
	defb 08dh	; 795d
	defb 040h	; 795e
	defb 0c0h	; 795f
	defb 0c0h	; 7960
	defb 080h	; 7961
	defb 0ffh	; 7962
	defb 07fh	; 7963
	defb 07fh	; 7964
	defb 0ffh	; 7965
	defb 0ffh	; 7966
	defb 041h	; 7967
	defb 0ffh	; 7968
	defb 0ffh	; 7969
	defb 0f0h	; 796a
	defb 003h	; 796b
	defb 000h	; 796c
	defb 086h	; 796d
	defb 060h	; 796e
	defb 0e0h	; 796f
	defb 0eeh	; 7970
	defb 00fh	; 7971
	defb 000h	; 7972
	defb 080h	; 7973
	defb 026h	; 7974
	defb 000h	; 7975
	defb 087h	; 7976
	defb 03ch	; 7977
	defb 07eh	; 7978
	defb 0fbh	; 7979
	defb 0b5h	; 797a
	defb 0a5h	; 797b
	defb 000h	; 797c
	defb 099h	; 797d
	defb 008h	; 797e
	defb 000h	; 797f
	defb 089h	; 7980
	defb 037h	; 7981
	defb 03fh	; 7982
	defb 01fh	; 7983
	defb 01fh	; 7984
	defb 03fh	; 7985
	defb 03bh	; 7986
	defb 038h	; 7987
	defb 01ch	; 7988
	defb 00ch	; 7989
	defb 007h	; 798a
	defb 000h	; 798b
	defb 092h	; 798c
	defb 0fbh	; 798d
	defb 0ffh	; 798e
	defb 0feh	; 798f
	defb 0feh	; 7990
	defb 0ffh	; 7991
	defb 0f7h	; 7992
	defb 007h	; 7993
	defb 00eh	; 7994
	defb 00ch	; 7995
	defb 03eh	; 7996
	defb 000h	; 7997
	defb 000h	; 7998
	defb 00eh	; 7999
	defb 0eeh	; 799a
	defb 0e7h	; 799b
	defb 067h	; 799c
	defb 00fh	; 799d
	defb 00eh	; 799e
	defb 031h	; 799f
	defb 000h	; 79a0
	defb 005h	; 79a1
	defb 0ffh	; 79a2
	defb 081h	; 79a3
	defb 07eh	; 79a4
	defb 018h	; 79a5
	defb 000h	; 79a6
	defb 082h	; 79a7
	defb 03ch	; 79a8
	defb 07eh	; 79a9
	defb 003h	; 79aa
	defb 0ffh	; 79ab
	defb 003h	; 79ac
	defb 07eh	; 79ad
	defb 088h	; 79ae
	defb 024h	; 79af
	defb 07eh	; 79b0
	defb 03eh	; 79b1
	defb 036h	; 79b2
	defb 0e3h	; 79b3
	defb 0f3h	; 79b4
	defb 01eh	; 79b5
	defb 018h	; 79b6
	defb 018h	; 79b7
	defb 000h	; 79b8
	defb 088h	; 79b9
	defb 01ch	; 79ba
	defb 07ch	; 79bb
	defb 0cch	; 79bc
	defb 0cfh	; 79bd
	defb 0ffh	; 79be
	defb 039h	; 79bf
	defb 030h	; 79c0
	defb 038h	; 79c1
	defb 018h	; 79c2
	defb 000h	; 79c3
	defb 088h	; 79c4
	defb 018h	; 79c5
	defb 000h	; 79c6
	defb 0c1h	; 79c7
	defb 0c9h	; 79c8
	defb 01ch	; 79c9
	defb 00ch	; 79ca
	defb 060h	; 79cb
	defb 024h	; 79cc
	defb 018h	; 79cd
	defb 000h	; 79ce
	defb 088h	; 79cf
	defb 020h	; 79d0
	defb 002h	; 79d1
	defb 033h	; 79d2
	defb 030h	; 79d3
	defb 000h	; 79d4
	defb 0c6h	; 79d5
	defb 04eh	; 79d6
	defb 004h	; 79d7
	defb 01dh	; 79d8
	defb 000h	; 79d9
	defb 083h	; 79da
	defb 03ch	; 79db
	defb 07eh	; 79dc
	defb 03ch	; 79dd
	defb 01eh	; 79de
	defb 000h	; 79df
	defb 005h	; 79e0
	defb 01ch	; 79e1
	defb 085h	; 79e2
	defb 0ffh	; 79e3
	defb 07fh	; 79e4
	defb 03eh	; 79e5
	defb 01ch	; 79e6
	defb 008h	; 79e7
	defb 00bh	; 79e8
	defb 000h	; 79e9
	defb 081h	; 79ea
	defb 080h	; 79eb
	defb 004h	; 79ec
	defb 000h	; 79ed
	defb 085h	; 79ee
	defb 008h	; 79ef
	defb 01ch	; 79f0
	defb 03eh	; 79f1
	defb 07fh	; 79f2
	defb 0ffh	; 79f3
	defb 005h	; 79f4
	defb 01ch	; 79f5
	defb 00ah	; 79f6
	defb 000h	; 79f7
	defb 081h	; 79f8
	defb 080h	; 79f9
	defb 00bh	; 79fa
	defb 000h	; 79fb
	defb 000h	; 79fc

; ----------------------------------------------------------------------
; DATOS patrones_de_sprite_79fd: 244 bytes comprimidos que dan 384 de VRAM en
;   0x18E0; lo carga 0x76E2
;   0x79fd..0x7af1  (244 bytes)
DATA_patrones_de_sprite_79fd:
	defb 0e0h	; 79fd
	defb 018h	; 79fe
	defb 019h	; 79ff
	defb 000h	; 7a00
	defb 090h	; 7a01
	defb 07ch	; 7a02
	defb 0feh	; 7a03
	defb 057h	; 7a04
	defb 057h	; 7a05
	defb 005h	; 7a06
	defb 021h	; 7a07
	defb 0e7h	; 7a08
	defb 000h	; 7a09
	defb 070h	; 7a0a
	defb 070h	; 7a0b
	defb 0f2h	; 7a0c
	defb 0eah	; 7a0d
	defb 0ffh	; 7a0e
	defb 07dh	; 7a0f
	defb 071h	; 7a10
	defb 067h	; 7a11
	defb 004h	; 7a12
	defb 000h	; 7a13
	defb 082h	; 7a14
	defb 00ch	; 7a15
	defb 003h	; 7a16
	defb 004h	; 7a17
	defb 000h	; 7a18
	defb 002h	; 7a19
	defb 080h	; 7a1a
	defb 094h	; 7a1b
	defb 0a0h	; 7a1c
	defb 0e6h	; 7a1d
	defb 08eh	; 7a1e
	defb 0efh	; 7a1f
	defb 007h	; 7a20
	defb 01fh	; 7a21
	defb 03eh	; 7a22
	defb 03ch	; 7a23
	defb 018h	; 7a24
	defb 000h	; 7a25
	defb 080h	; 7a26
	defb 008h	; 7a27
	defb 01ch	; 7a28
	defb 01fh	; 7a29
	defb 01dh	; 7a2a
	defb 01fh	; 7a2b
	defb 00fh	; 7a2c
	defb 00dh	; 7a2d
	defb 001h	; 7a2e
	defb 001h	; 7a2f
	defb 008h	; 7a30
	defb 000h	; 7a31
	defb 003h	; 7a32
	defb 0e0h	; 7a33
	defb 004h	; 7a34
	defb 0c0h	; 7a35
	defb 081h	; 7a36
	defb 080h	; 7a37
	defb 007h	; 7a38
	defb 000h	; 7a39
	defb 081h	; 7a3a
	defb 001h	; 7a3b
	defb 003h	; 7a3c
	defb 003h	; 7a3d
	defb 003h	; 7a3e
	defb 001h	; 7a3f
	defb 009h	; 7a40
	defb 000h	; 7a41
	defb 08bh	; 7a42
	defb 080h	; 7a43
	defb 0ffh	; 7a44
	defb 0feh	; 7a45
	defb 0fch	; 7a46
	defb 0fch	; 7a47
	defb 03eh	; 7a48
	defb 0cfh	; 7a49
	defb 0f7h	; 7a4a
	defb 0ffh	; 7a4b
	defb 07eh	; 7a4c
	defb 030h	; 7a4d
	defb 015h	; 7a4e
	defb 000h	; 7a4f
	defb 084h	; 7a50
	defb 060h	; 7a51
	defb 064h	; 7a52
	defb 03ch	; 7a53
	defb 038h	; 7a54
	defb 00ch	; 7a55
	defb 000h	; 7a56
	defb 085h	; 7a57
	defb 010h	; 7a58
	defb 030h	; 7a59
	defb 079h	; 7a5a
	defb 07bh	; 7a5b
	defb 0f1h	; 7a5c
	defb 004h	; 7a5d
	defb 0e0h	; 7a5e
	defb 081h	; 7a5f
	defb 0c0h	; 7a60
	defb 008h	; 7a61
	defb 000h	; 7a62
	defb 002h	; 7a63
	defb 0c0h	; 7a64
	defb 084h	; 7a65
	defb 0e0h	; 7a66
	defb 0f8h	; 7a67
	defb 0fch	; 7a68
	defb 078h	; 7a69
	defb 008h	; 7a6a
	defb 000h	; 7a6b
	defb 082h	; 7a6c
	defb 00ch	; 7a6d
	defb 03fh	; 7a6e
	defb 003h	; 7a6f
	defb 01fh	; 7a70
	defb 086h	; 7a71
	defb 009h	; 7a72
	defb 01eh	; 7a73
	defb 01fh	; 7a74
	defb 00fh	; 7a75
	defb 00fh	; 7a76
	defb 006h	; 7a77
	defb 006h	; 7a78
	defb 000h	; 7a79
	defb 089h	; 7a7a
	defb 0f8h	; 7a7b
	defb 0f0h	; 7a7c
	defb 0e0h	; 7a7d
	defb 0e0h	; 7a7e
	defb 0f0h	; 7a7f
	defb 070h	; 7a80
	defb 0b0h	; 7a81
	defb 0e0h	; 7a82
	defb 0c0h	; 7a83
	defb 003h	; 7a84
	defb 000h	; 7a85
	defb 088h	; 7a86
	defb 004h	; 7a87
	defb 002h	; 7a88
	defb 006h	; 7a89
	defb 000h	; 7a8a
	defb 010h	; 7a8b
	defb 070h	; 7a8c
	defb 0f0h	; 7a8d
	defb 0e0h	; 7a8e
	defb 00bh	; 7a8f
	defb 000h	; 7a90
	defb 082h	; 7a91
	defb 007h	; 7a92
	defb 006h	; 7a93
	defb 010h	; 7a94
	defb 000h	; 7a95
	defb 08eh	; 7a96
	defb 0c0h	; 7a97
	defb 0e0h	; 7a98
	defb 0e0h	; 7a99
	defb 072h	; 7a9a
	defb 07ah	; 7a9b
	defb 03fh	; 7a9c
	defb 03dh	; 7a9d
	defb 031h	; 7a9e
	defb 01fh	; 7a9f
	defb 018h	; 7aa0
	defb 000h	; 7aa1
	defb 000h	; 7aa2
	defb 00eh	; 7aa3
	defb 001h	; 7aa4
	defb 003h	; 7aa5
	defb 000h	; 7aa6
	defb 085h	; 7aa7
	defb 00eh	; 7aa8
	defb 01eh	; 7aa9
	defb 09ch	; 7aaa
	defb 09ch	; 7aab
	defb 0b8h	; 7aac
	defb 003h	; 7aad
	defb 0f8h	; 7aae
	defb 002h	; 7aaf
	defb 078h	; 7ab0
	defb 081h	; 7ab1
	defb 030h	; 7ab2
	defb 003h	; 7ab3
	defb 000h	; 7ab4
	defb 085h	; 7ab5
	defb 001h	; 7ab6
	defb 003h	; 7ab7
	defb 003h	; 7ab8
	defb 007h	; 7ab9
	defb 001h	; 7aba
	defb 003h	; 7abb
	defb 000h	; 7abc
	defb 084h	; 7abd
	defb 002h	; 7abe
	defb 001h	; 7abf
	defb 00eh	; 7ac0
	defb 01ch	; 7ac1
	defb 003h	; 7ac2
	defb 000h	; 7ac3
	defb 002h	; 7ac4
	defb 0f0h	; 7ac5
	defb 089h	; 7ac6
	defb 0f9h	; 7ac7
	defb 0feh	; 7ac8
	defb 0fch	; 7ac9
	defb 0fch	; 7aca
	defb 078h	; 7acb
	defb 038h	; 7acc
	defb 030h	; 7acd
	defb 070h	; 7ace
	defb 0e0h	; 7acf
	defb 015h	; 7ad0
	defb 000h	; 7ad1
	defb 084h	; 7ad2
	defb 004h	; 7ad3
	defb 01ch	; 7ad4
	defb 01ch	; 7ad5
	defb 038h	; 7ad6
	defb 00ch	; 7ad7
	defb 000h	; 7ad8
	defb 086h	; 7ad9
	defb 007h	; 7ada
	defb 00fh	; 7adb
	defb 01fh	; 7adc
	defb 01fh	; 7add
	defb 01eh	; 7ade
	defb 00fh	; 7adf
	defb 00bh	; 7ae0
	defb 000h	; 7ae1
	defb 08bh	; 7ae2
	defb 0c0h	; 7ae3
	defb 0e0h	; 7ae4
	defb 0e0h	; 7ae5
	defb 0c0h	; 7ae6
	defb 000h	; 7ae7
	defb 0f0h	; 7ae8
	defb 070h	; 7ae9
	defb 078h	; 7aea
	defb 038h	; 7aeb
	defb 03ch	; 7aec
	defb 018h	; 7aed
	defb 004h	; 7aee
	defb 000h	; 7aef
	defb 000h	; 7af0

; ======================================================================
; CODIGO 0x7af1..0x7b02  (17 bytes)
; ======================================================================


L_7AF1:
	ld de,07b02h		;7af1   ; los sprites del penalti, con diez espejados
	call descomprime_con_destino_dentro		;7af4
	ld hl,019c0h		;7af7
	ld de,01b10h		;7afa
	ld c,00ah		;7afd
	jp espeja_sprites_en_la_vram		;7aff

; ----------------------------------------------------------------------
; DATOS patrones_de_sprite_7b02: 388 bytes comprimidos que dan 768 de VRAM en
;   0x1800; lo carga 0x7AF4
;   0x7b02..0x7c86  (388 bytes)
DATA_patrones_de_sprite_7b02:
	defb 000h	; 7b02
	defb 018h	; 7b03
	defb 018h	; 7b04
	defb 000h	; 7b05
	defb 08dh	; 7b06
	defb 07eh	; 7b07
	defb 0ffh	; 7b08
	defb 0ffh	; 7b09
	defb 0b5h	; 7b0a
	defb 0a5h	; 7b0b
	defb 000h	; 7b0c
	defb 024h	; 7b0d
	defb 03ch	; 7b0e
	defb 009h	; 7b0f
	defb 02bh	; 7b10
	defb 03fh	; 7b11
	defb 01bh	; 7b12
	defb 048h	; 7b13
	defb 003h	; 7b14
	defb 0c0h	; 7b15
	defb 08dh	; 7b16
	defb 0e0h	; 7b17
	defb 0f7h	; 7b18
	defb 060h	; 7b19
	defb 000h	; 7b1a
	defb 01ch	; 7b1b
	defb 03ch	; 7b1c
	defb 038h	; 7b1d
	defb 038h	; 7b1e
	defb 040h	; 7b1f
	defb 050h	; 7b20
	defb 0f0h	; 7b21
	defb 060h	; 7b22
	defb 048h	; 7b23
	defb 003h	; 7b24
	defb 00ch	; 7b25
	defb 08ah	; 7b26
	defb 01ch	; 7b27
	defb 0bch	; 7b28
	defb 018h	; 7b29
	defb 000h	; 7b2a
	defb 0e0h	; 7b2b
	defb 0f0h	; 7b2c
	defb 070h	; 7b2d
	defb 070h	; 7b2e
	defb 038h	; 7b2f
	defb 018h	; 7b30
	defb 00eh	; 7b31
	defb 000h	; 7b32
	defb 082h	; 7b33
	defb 070h	; 7b34
	defb 060h	; 7b35
	defb 00eh	; 7b36
	defb 000h	; 7b37
	defb 082h	; 7b38
	defb 060h	; 7b39
	defb 030h	; 7b3a
	defb 003h	; 7b3b
	defb 03fh	; 7b3c
	defb 085h	; 7b3d
	defb 01fh	; 7b3e
	defb 008h	; 7b3f
	defb 01fh	; 7b40
	defb 01fh	; 7b41
	defb 003h	; 7b42
	defb 004h	; 7b43
	defb 000h	; 7b44
	defb 084h	; 7b45
	defb 020h	; 7b46
	defb 078h	; 7b47
	defb 018h	; 7b48
	defb 030h	; 7b49
	defb 003h	; 7b4a
	defb 0f0h	; 7b4b
	defb 084h	; 7b4c
	defb 0e0h	; 7b4d
	defb 040h	; 7b4e
	defb 0e0h	; 7b4f
	defb 0e0h	; 7b50
	defb 005h	; 7b51
	defb 000h	; 7b52
	defb 083h	; 7b53
	defb 010h	; 7b54
	defb 078h	; 7b55
	defb 078h	; 7b56
	defb 00fh	; 7b57
	defb 000h	; 7b58
	defb 081h	; 7b59
	defb 078h	; 7b5a
	defb 01ch	; 7b5b
	defb 000h	; 7b5c
	defb 002h	; 7b5d
	defb 001h	; 7b5e
	defb 00bh	; 7b5f
	defb 000h	; 7b60
	defb 005h	; 7b61
	defb 0ffh	; 7b62
	defb 081h	; 7b63
	defb 0feh	; 7b64
	defb 003h	; 7b65
	defb 00fh	; 7b66
	defb 086h	; 7b67
	defb 0cfh	; 7b68
	defb 09fh	; 7b69
	defb 098h	; 7b6a
	defb 0dfh	; 7b6b
	defb 00fh	; 7b6c
	defb 007h	; 7b6d
	defb 005h	; 7b6e
	defb 000h	; 7b6f
	defb 083h	; 7b70
	defb 001h	; 7b71
	defb 003h	; 7b72
	defb 0c0h	; 7b73
	defb 004h	; 7b74
	defb 0e0h	; 7b75
	defb 083h	; 7b76
	defb 060h	; 7b77
	defb 0c0h	; 7b78
	defb 0c0h	; 7b79
	defb 005h	; 7b7a
	defb 000h	; 7b7b
	defb 002h	; 7b7c
	defb 0e0h	; 7b7d
	defb 08ch	; 7b7e
	defb 0c0h	; 7b7f
	defb 07fh	; 7b80
	defb 0ffh	; 7b81
	defb 03fh	; 7b82
	defb 01fh	; 7b83
	defb 03fh	; 7b84
	defb 03fh	; 7b85
	defb 01fh	; 7b86
	defb 00fh	; 7b87
	defb 003h	; 7b88
	defb 001h	; 7b89
	defb 001h	; 7b8a
	defb 005h	; 7b8b
	defb 000h	; 7b8c
	defb 086h	; 7b8d
	defb 0c0h	; 7b8e
	defb 0f0h	; 7b8f
	defb 0f8h	; 7b90
	defb 0fch	; 7b91
	defb 0cch	; 7b92
	defb 0cch	; 7b93
	defb 004h	; 7b94
	defb 0c0h	; 7b95
	defb 003h	; 7b96
	defb 0e0h	; 7b97
	defb 081h	; 7b98
	defb 080h	; 7b99
	defb 00ah	; 7b9a
	defb 000h	; 7b9b
	defb 088h	; 7b9c
	defb 01ch	; 7b9d
	defb 07ch	; 7b9e
	defb 0cch	; 7b9f
	defb 0cfh	; 7ba0
	defb 0ffh	; 7ba1
	defb 039h	; 7ba2
	defb 030h	; 7ba3
	defb 038h	; 7ba4
	defb 018h	; 7ba5
	defb 000h	; 7ba6
	defb 088h	; 7ba7
	defb 020h	; 7ba8
	defb 032h	; 7ba9
	defb 03fh	; 7baa
	defb 0ech	; 7bab
	defb 0cch	; 7bac
	defb 04eh	; 7bad
	defb 07eh	; 7bae
	defb 030h	; 7baf
	defb 018h	; 7bb0
	defb 000h	; 7bb1
	defb 088h	; 7bb2
	defb 024h	; 7bb3
	defb 07eh	; 7bb4
	defb 03eh	; 7bb5
	defb 036h	; 7bb6
	defb 0e3h	; 7bb7
	defb 0f3h	; 7bb8
	defb 01eh	; 7bb9
	defb 018h	; 7bba
	defb 018h	; 7bbb
	defb 000h	; 7bbc
	defb 088h	; 7bbd
	defb 020h	; 7bbe
	defb 002h	; 7bbf
	defb 033h	; 7bc0
	defb 030h	; 7bc1
	defb 000h	; 7bc2
	defb 0c6h	; 7bc3
	defb 04eh	; 7bc4
	defb 004h	; 7bc5
	defb 018h	; 7bc6
	defb 000h	; 7bc7
	defb 088h	; 7bc8
	defb 01ch	; 7bc9
	defb 04ch	; 7bca
	defb 0c0h	; 7bcb
	defb 013h	; 7bcc
	defb 033h	; 7bcd
	defb 0b1h	; 7bce
	defb 000h	; 7bcf
	defb 00ch	; 7bd0
	defb 018h	; 7bd1
	defb 000h	; 7bd2
	defb 088h	; 7bd3
	defb 018h	; 7bd4
	defb 000h	; 7bd5
	defb 0c1h	; 7bd6
	defb 0c9h	; 7bd7
	defb 01ch	; 7bd8
	defb 00ch	; 7bd9
	defb 060h	; 7bda
	defb 024h	; 7bdb
	defb 011h	; 7bdc
	defb 000h	; 7bdd
	defb 08dh	; 7bde
	defb 060h	; 7bdf
	defb 0e0h	; 7be0
	defb 0c0h	; 7be1
	defb 0e0h	; 7be2
	defb 06fh	; 7be3
	defb 000h	; 7be4
	defb 000h	; 7be5
	defb 003h	; 7be6
	defb 03bh	; 7be7
	defb 039h	; 7be8
	defb 019h	; 7be9
	defb 003h	; 7bea
	defb 003h	; 7beb
	defb 004h	; 7bec
	defb 000h	; 7bed
	defb 003h	; 7bee
	defb 020h	; 7bef
	defb 085h	; 7bf0
	defb 0a0h	; 7bf1
	defb 060h	; 7bf2
	defb 000h	; 7bf3
	defb 080h	; 7bf4
	defb 080h	; 7bf5
	defb 003h	; 7bf6
	defb 0c0h	; 7bf7
	defb 083h	; 7bf8
	defb 080h	; 7bf9
	defb 000h	; 7bfa
	defb 000h	; 7bfb
	defb 005h	; 7bfc
	defb 0ffh	; 7bfd
	defb 085h	; 7bfe
	defb 0c1h	; 7bff
	defb 0ffh	; 7c00
	defb 0ffh	; 7c01
	defb 0fch	; 7c02
	defb 000h	; 7c03
	defb 003h	; 7c04
	defb 030h	; 7c05
	defb 085h	; 7c06
	defb 000h	; 7c07
	defb 00eh	; 7c08
	defb 00fh	; 7c09
	defb 000h	; 7c0a
	defb 080h	; 7c0b
	defb 00eh	; 7c0c
	defb 000h	; 7c0d
	defb 089h	; 7c0e
	defb 003h	; 7c0f
	defb 007h	; 7c10
	defb 07fh	; 7c11
	defb 07fh	; 7c12
	defb 0ffh	; 7c13
	defb 07fh	; 7c14
	defb 03eh	; 7c15
	defb 011h	; 7c16
	defb 00fh	; 7c17
	defb 008h	; 7c18
	defb 000h	; 7c19
	defb 08fh	; 7c1a
	defb 080h	; 7c1b
	defb 0c0h	; 7c1c
	defb 0c0h	; 7c1d
	defb 0e0h	; 7c1e
	defb 060h	; 7c1f
	defb 0e0h	; 7c20
	defb 0c0h	; 7c21
	defb 080h	; 7c22
	defb 003h	; 7c23
	defb 001h	; 7c24
	defb 023h	; 7c25
	defb 071h	; 7c26
	defb 030h	; 7c27
	defb 000h	; 7c28
	defb 000h	; 7c29
	defb 004h	; 7c2a
	defb 080h	; 7c2b
	defb 01eh	; 7c2c
	defb 000h	; 7c2d
	defb 087h	; 7c2e
	defb 046h	; 7c2f
	defb 0efh	; 7c30
	defb 0feh	; 7c31
	defb 078h	; 7c32
	defb 03fh	; 7c33
	defb 01ch	; 7c34
	defb 008h	; 7c35
	defb 007h	; 7c36
	defb 000h	; 7c37
	defb 08dh	; 7c38
	defb 030h	; 7c39
	defb 0b8h	; 7c3a
	defb 09ch	; 7c3b
	defb 0bch	; 7c3c
	defb 0eeh	; 7c3d
	defb 0ceh	; 7c3e
	defb 0c6h	; 7c3f
	defb 000h	; 7c40
	defb 000h	; 7c41
	defb 004h	; 7c42
	defb 00ch	; 7c43
	defb 078h	; 7c44
	defb 071h	; 7c45
	defb 003h	; 7c46
	defb 000h	; 7c47
	defb 002h	; 7c48
	defb 001h	; 7c49
	defb 084h	; 7c4a
	defb 007h	; 7c4b
	defb 0ffh	; 7c4c
	defb 07fh	; 7c4d
	defb 01dh	; 7c4e
	defb 00ch	; 7c4f
	defb 000h	; 7c50
	defb 084h	; 7c51
	defb 080h	; 7c52
	defb 0c0h	; 7c53
	defb 0e0h	; 7c54
	defb 0c0h	; 7c55
	defb 00ah	; 7c56
	defb 000h	; 7c57
	defb 088h	; 7c58
	defb 002h	; 7c59
	defb 003h	; 7c5a
	defb 07fh	; 7c5b
	defb 0ffh	; 7c5c
	defb 0ffh	; 7c5d
	defb 07eh	; 7c5e
	defb 011h	; 7c5f
	defb 00fh	; 7c60
	defb 008h	; 7c61
	defb 000h	; 7c62
	defb 088h	; 7c63
	defb 020h	; 7c64
	defb 022h	; 7c65
	defb 0f3h	; 7c66
	defb 0f0h	; 7c67
	defb 070h	; 7c68
	defb 0f0h	; 7c69
	defb 0e0h	; 7c6a
	defb 0c0h	; 7c6b
	defb 015h	; 7c6c
	defb 000h	; 7c6d
	defb 083h	; 7c6e
	defb 0e0h	; 7c6f
	defb 070h	; 7c70
	defb 070h	; 7c71
	defb 029h	; 7c72
	defb 000h	; 7c73
	defb 08eh	; 7c74
	defb 03eh	; 7c75
	defb 07ch	; 7c76
	defb 0f4h	; 7c77
	defb 016h	; 7c78
	defb 004h	; 7c79
	defb 011h	; 7c7a
	defb 072h	; 7c7b
	defb 0c0h	; 7c7c
	defb 066h	; 7c7d
	defb 07fh	; 7c7e
	defb 07fh	; 7c7f
	defb 0feh	; 7c80
	defb 0f8h	; 7c81
	defb 0e0h	; 7c82
	defb 019h	; 7c83
	defb 000h	; 7c84
	defb 000h	; 7c85

; ======================================================================
; CODIGO 0x7c86..0x7c8c  (6 bytes)
; ======================================================================


L_7C86:
	ld de,07c8ch		;7c86
	jp descomprime_con_destino_dentro		;7c89

; ----------------------------------------------------------------------
; DATOS patrones_de_sprite_7c8c: 136 bytes comprimidos que dan 288 de VRAM en
;   0x1800; lo carga 0x7C89
;   0x7c8c..0x7d14  (136 bytes)
DATA_patrones_de_sprite_7c8c:
	defb 000h	; 7c8c
	defb 018h	; 7c8d
	defb 088h	; 7c8e
	defb 024h	; 7c8f
	defb 07eh	; 7c90
	defb 03eh	; 7c91
	defb 036h	; 7c92
	defb 0e3h	; 7c93
	defb 0f3h	; 7c94
	defb 01eh	; 7c95
	defb 018h	; 7c96
	defb 018h	; 7c97
	defb 000h	; 7c98
	defb 088h	; 7c99
	defb 018h	; 7c9a
	defb 000h	; 7c9b
	defb 0c1h	; 7c9c
	defb 0c9h	; 7c9d
	defb 01ch	; 7c9e
	defb 00ch	; 7c9f
	defb 060h	; 7ca0
	defb 024h	; 7ca1
	defb 019h	; 7ca2
	defb 000h	; 7ca3
	defb 082h	; 7ca4
	defb 018h	; 7ca5
	defb 038h	; 7ca6
	defb 004h	; 7ca7
	defb 018h	; 7ca8
	defb 081h	; 7ca9
	defb 07eh	; 7caa
	defb 009h	; 7cab
	defb 000h	; 7cac
	defb 081h	; 7cad
	defb 07eh	; 7cae
	defb 003h	; 7caf
	defb 063h	; 7cb0
	defb 083h	; 7cb1
	defb 07ch	; 7cb2
	defb 060h	; 7cb3
	defb 060h	; 7cb4
	defb 009h	; 7cb5
	defb 000h	; 7cb6
	defb 087h	; 7cb7
	defb 03eh	; 7cb8
	defb 063h	; 7cb9
	defb 003h	; 7cba
	defb 00eh	; 7cbb
	defb 03ch	; 7cbc
	defb 070h	; 7cbd
	defb 07fh	; 7cbe
	defb 009h	; 7cbf
	defb 000h	; 7cc0
	defb 081h	; 7cc1
	defb 07eh	; 7cc2
	defb 003h	; 7cc3
	defb 063h	; 7cc4
	defb 083h	; 7cc5
	defb 07ch	; 7cc6
	defb 060h	; 7cc7
	defb 060h	; 7cc8
	defb 008h	; 7cc9
	defb 000h	; 7cca
	defb 081h	; 7ccb
	defb 0ffh	; 7ccc
	defb 009h	; 7ccd
	defb 080h	; 7cce
	defb 081h	; 7ccf
	defb 0ffh	; 7cd0
	defb 005h	; 7cd1
	defb 000h	; 7cd2
	defb 081h	; 7cd3
	defb 0e0h	; 7cd4
	defb 009h	; 7cd5
	defb 020h	; 7cd6
	defb 081h	; 7cd7
	defb 0e0h	; 7cd8
	defb 005h	; 7cd9
	defb 000h	; 7cda
	defb 081h	; 7cdb
	defb 0ffh	; 7cdc
	defb 009h	; 7cdd
	defb 080h	; 7cde
	defb 081h	; 7cdf
	defb 0ffh	; 7ce0
	defb 005h	; 7ce1
	defb 000h	; 7ce2
	defb 081h	; 7ce3
	defb 0ffh	; 7ce4
	defb 009h	; 7ce5
	defb 000h	; 7ce6
	defb 081h	; 7ce7
	defb 0ffh	; 7ce8
	defb 005h	; 7ce9
	defb 000h	; 7cea
	defb 081h	; 7ceb
	defb 0e0h	; 7cec
	defb 009h	; 7ced
	defb 020h	; 7cee
	defb 081h	; 7cef
	defb 0e0h	; 7cf0
	defb 015h	; 7cf1
	defb 000h	; 7cf2
	defb 081h	; 7cf3
	defb 0ffh	; 7cf4
	defb 007h	; 7cf5
	defb 080h	; 7cf6
	defb 081h	; 7cf7
	defb 0ffh	; 7cf8
	defb 007h	; 7cf9
	defb 000h	; 7cfa
	defb 009h	; 7cfb
	defb 080h	; 7cfc
	defb 008h	; 7cfd
	defb 000h	; 7cfe
	defb 087h	; 7cff
	defb 073h	; 7d00
	defb 0dah	; 7d01
	defb 082h	; 7d02
	defb 082h	; 7d03
	defb 08bh	; 7d04
	defb 0dah	; 7d05
	defb 072h	; 7d06
	defb 009h	; 7d07
	defb 000h	; 7d08
	defb 087h	; 7d09
	defb 092h	; 7d0a
	defb 0d2h	; 7d0b
	defb 052h	; 7d0c
	defb 0d2h	; 7d0d
	defb 092h	; 7d0e
	defb 01eh	; 7d0f
	defb 00ch	; 7d10
	defb 008h	; 7d11
	defb 000h	; 7d12
	defb 000h	; 7d13

; ----------------------------------------------------------------------
; DATOS parches_del_jugador_a: arbol de dos niveles: 9 punteros a 8 subtablas
;   y 26 hojas de once bytes (una palabra de desplazamiento y 3x3 tiles). Es
;   el juego que se usa cuando (0xE527) no es cero; lo eligen 0x8824 y 0x8A0A
;   0x7d14..0x801e  (778 bytes)
DATA_parches_del_jugador_a:
	defw 07d26h,07d26h,07d69h,07da1h,07db8h,07df0h,07e1dh,07e55h	; 7d14
	defw 07e6ch,07d32h,07d3dh,07d48h,07d32h,07d53h,07d5eh,0ffffh	; 7d24
	defw 0aa01h,08c8bh,001b0h,0ab8fh,0ff92h,001ffh,08baah,0a501h	; 7d34
	defw 09e9ah,09998h,0ffffh,0aa01h,0018bh,001a6h,09b01h,00001h	; 7d44
	defw 00100h,00101h,00101h,00101h,00101h,00000h,07b79h,07c7ah	; 7d54
	defw 07d7eh,07f80h,07581h,0807dh,08b7dh,0757dh,0967dh,05e7dh	; 7d64
	defw 0ff7dh,001ffh,0adach,0b08ch,08f01h,092abh,0ffffh,0ac01h	; 7d74
	defw 090adh,08e94h,0afaeh,0ff91h,001ffh,0adach,0a296h,00195h	; 7d84
	defw 001a7h,0ffffh,0ac01h,097adh,09fa4h,00101h,0ada0h,0807dh	; 7d94
	defw 08b7dh,0ad7dh,0537dh,05e7dh,0ff7dh,001ffh,0adach,08901h	; 7da4
	defw 06b65h,06884h,07dc4h,07dcfh,07ddah,07dc4h,07de5h,07d5eh	; 7db4
	defw 0ffffh,08586h,00101h,06589h,0846bh,0ff68h,086ffh,00185h	; 7dc4
	defw 06d67h,06a69h,08788h,0ffffh,08586h,06e01h,06f7bh,08001h	; 7dd4
	defw 00001h,08600h,00185h,07d78h,07970h,00101h,07dfch,07e07h	; 7de4
	defw 07e12h,07dfch,07d53h,07d5eh,0ffffh,08364h,00101h,06589h	; 7df4
	defw 0846bh,0ff68h,064ffh,00183h,07e73h,07201h,07771h,0ffffh	; 7e04
	defw 08364h,00101h,0017fh,07401h,02901h,0347eh,03f7eh,0297eh	; 7e14
	defw 04a7eh,05e7eh,0ff7dh,001ffh,0018ah,08901h,06a65h,06884h	; 7e24
	defw 0ffffh,08a01h,06601h,0016ch,0886ah,0ff87h,001ffh,0018ah	; 7e34
	defw 07c6eh,0016fh,00180h,0ffffh,00101h,07601h,08a7ah,08175h	; 7e44
	defw 06182h,0347eh,03f7eh,0617eh,0537eh,05e7dh,0ff7dh,001ffh	; 7e54
	defw 0018ah,06c66h,06a01h,08788h,07e78h,07e83h,07e8eh,07e78h	; 7e64
	defw 07e99h,07d5eh,0ffffh,0b101h,08c01h,001b0h,0ab8fh,0ff92h	; 7e74
	defw 001ffh,001b1h,06c01h,0ae8dh,091afh,0ffffh,0b101h,09601h	; 7e84
	defw 095a3h,0a701h,0ff01h,001ffh,00101h,0a1b1h,0a99dh,09ca8h	; 7e94
	defw 07eb6h,07eb6h,07eeeh,07f26h,07f3dh,07f75h,07fa2h,07fdah	; 7ea4
	defw 07fe6h,07ec2h,07ecdh,07ed8h,07ec2h,07d53h,07ee3h,0ffffh	; 7eb4
	defw 0f801h,0dad9h,001feh,0f9ddh,0ffe0h,001ffh,0d9f8h,0f301h	; 7ec4
	defw 0ece8h,0e7e6h,0ffffh,0f801h,001d9h,001f4h,0e901h,0ff01h	; 7ed4
	defw 0c8ffh,0c7c9h,0cccbh,0cfcah,0cecdh,07efah,07f05h,07f10h	; 7ee4
	defw 07efah,07f1bh,07ee3h,0ffffh,0fa01h,0dafbh,001feh,0f9ddh	; 7ef4
	defw 0ffe0h,001ffh,0fbfah,0e2deh,0fcdch,0dffdh,0ffffh,0fa01h	; 7f04
	defw 0e4fbh,0e3f0h,0f501h,0ff01h,001ffh,0fbfah,0f2e5h,001edh	; 7f14
	defw 0ee01h,07f32h,07f05h,07f10h,07f32h,07d53h,07ee3h,0ffffh	; 7f24
	defw 0fa01h,0defbh,0dce2h,0fdfch,049dfh,0547fh,05f7fh,0497fh	; 7f34
	defw 06a7fh,0e37fh,0ff7eh,0d4ffh,001d3h,0d701h,0b9b3h,0b6d2h	; 7f44
	defw 0ffffh,0d3d4h,0b501h,0b7bbh,0d6b8h,0ffd5h,0d4ffh,001d3h	; 7f54
	defw 0c9bch,001bdh,001ceh,00000h,0d3d4h,0c601h,0becbh,001c7h	; 7f64
	defw 08101h,08c7fh,0977fh,0817fh,0537fh,0e37dh,0ff7eh,0b2ffh	; 7f74
	defw 001d1h,0d701h,0b9b3h,0b6d2h,0ffffh,0d1b2h,0c101h,001cch	; 7f84
	defw 0bfc0h,0ffc5h,0b2ffh,001d1h,0cd01h,00101h,001c2h,07faeh	; 7f94
	defw 07fb9h,07fc4h,07faeh,07fcfh,07ee3h,0ffffh,0d801h,00101h	; 7fa4
	defw 0b3d7h,0d2b9h,0ffb6h,001ffh,001d8h,0bab4h,0b801h,0d5d6h	; 7fb4
	defw 0ffffh,0d801h,0bc01h,0bdcah,0ce01h,0ff01h,001ffh,00101h	; 7fc4
	defw 0c8c4h,0c3d8h,0d0cfh,07fb9h,07fb9h,07fc4h,07fb9h,07d53h	; 7fd4
	defw 07ee3h,07ff2h,07ffdh,08008h,07ff2h,08013h,07ee3h,0ffffh	; 7fe4
	defw 0ff01h,0da01h,001feh,0f9ddh,0ffe0h,001ffh,001ffh,0e101h	; 7ff4
	defw 0fcdbh,0dffdh,0ffffh,0ff01h,0e401h,0e3f1h,0f501h,0ff01h	; 8004
	defw 001ffh,00101h,0efffh,0f7ebh,0eaf6h	; 8014

; ----------------------------------------------------------------------
; DATOS parches_del_balon: la misma forma: 9 punteros, 8 subtablas y 37 hojas.
;   Lo cargan 0x8941 y 0x8B1C
;   0x801e..0x8368  (842 bytes)
DATA_parches_del_balon:
	defw 08030h,08030h,080e0h,08134h,08188h,08218h,0826ch,082c0h	; 801e
	defw 08314h,08044h,08054h,08064h,08074h,08044h,08084h,08094h	; 802e
	defw 080a4h,080b8h,080cch,0fe08h,00468h,000f8h,0025ch,000f8h	; 803e
	defw 00360h,0fe08h,00364h,00008h,00484h,000f8h,0025ch,000f8h	; 804e
	defw 00360h,00008h,00380h,0fc08h,0048ch,000f8h,0025ch,000f8h	; 805e
	defw 00360h,0fc08h,00388h,00008h,00494h,000f8h,0025ch,000f8h	; 806e
	defw 00360h,0ff08h,00390h,0f8f8h,002d0h,0fbfbh,003d4h,00008h	; 807e
	defw 004cch,0000dh,003d8h,0f8f8h,002e0h,0fbfbh,003d4h,00008h	; 808e
	defw 004cch,0000dh,003d8h,000f7h,00278h,0fcffh,0037ch,00007h	; 809e
	defw 00484h,0fc10h,00380h,00017h,00488h,000f7h,00278h,0fcffh	; 80ae
	defw 0037ch,0fd07h,00490h,0fd0fh,0038ch,0fe17h,00494h,0fcfdh	; 80be
	defw 00398h,000f7h,00278h,0ff08h,0049ch,0000dh,003a4h,00018h	; 80ce
	defw 004a0h,080f4h,08104h,08114h,08124h,080f4h,08084h,08094h	; 80de
	defw 080a4h,080b8h,080cch,0fe08h,00468h,000f8h,0026ch,000f8h	; 80ee
	defw 00374h,0fe08h,00364h,0fb08h,004a8h,000f8h,0026ch,000f8h	; 80fe
	defw 00374h,0fa08h,003ach,0f908h,004b0h,000f8h,0026ch,000f8h	; 810e
	defw 00374h,0fb08h,003a0h,0fc08h,004bch,000f8h,0026ch,000f8h	; 811e
	defw 00374h,0fa08h,00398h,08148h,08158h,08168h,08178h,08148h	; 812e
	defw 08084h,08094h,080a4h,080b8h,080cch,0fe08h,00468h,0f8f8h	; 813e
	defw 002d0h,0f8f8h,003dch,0fe08h,00364h,0f8f8h,002d0h,0fe08h	; 814e
	defw 0031ch,00008h,00420h,0f8f8h,003dch,0f8f8h,002d0h,0fa08h	; 815e
	defw 00378h,0f808h,0047ch,0f8f8h,003dch,0fe08h,004c8h,0f8f8h	; 816e
	defw 002d0h,0f8f8h,003dch,0fd08h,0033ch,0819ch,081ach,081bch	; 817e
	defw 081cch,0819ch,08084h,08094h,081dch,081f0h,08204h,0fa08h	; 818e
	defw 0040ch,0f8f8h,00210h,0f8f8h,00318h,0fa08h,00308h,0fd08h	; 819e
	defw 0044ch,0f8f8h,00210h,0f8f8h,00318h,0fe08h,00350h,0ff08h	; 81ae
	defw 00454h,0f8f8h,00210h,0f8f8h,00318h,0fd08h,00344h,0fc08h	; 81be
	defw 004b8h,0f8f8h,00210h,0f8f8h,00318h,0fe08h,0033ch,0f8f7h	; 81ce
	defw 0021ch,0fcffh,00320h,0f807h,00428h,0fc10h,00324h,0f817h	; 81de
	defw 0042ch,0f8f7h,0021ch,0fcffh,00320h,0fb07h,00434h,0fb0fh	; 81ee
	defw 00330h,0fa17h,00438h,0fcfdh,0033ch,0f8f7h,0021ch,0f908h	; 81fe
	defw 00440h,0f80dh,00348h,0f818h,00444h,0822ch,0823ch,0824ch	; 820e
	defw 0825ch,0822ch,08084h,08094h,081dch,081f0h,08204h,0fa08h	; 821e
	defw 0040ch,0f8f8h,00200h,0f8f8h,00304h,0fa08h,00308h,0f808h	; 822e
	defw 00428h,0f8f8h,00200h,0f8f8h,00304h,0f808h,00324h,0fc08h	; 823e
	defw 00430h,0f8f8h,00200h,0f8f8h,00304h,0fc08h,0032ch,0f808h	; 824e
	defw 00438h,0f8f8h,00200h,0f8f8h,00304h,0f908h,00334h,08280h	; 825e
	defw 08290h,082a0h,082b0h,08280h,08084h,08094h,081dch,081f0h	; 826e
	defw 08204h,0fa08h,0040ch,0f8f8h,00214h,0f8f8h,00318h,0fa08h	; 827e
	defw 00308h,0fd08h,00448h,0f8f8h,00214h,0f8f8h,00318h,0fe08h	; 828e
	defw 00350h,00008h,00458h,0f8f8h,00214h,0f8f8h,00318h,0fd08h	; 829e
	defw 00344h,0fd08h,00440h,0f8f8h,00214h,0f8f8h,00318h,0fc08h	; 82ae
	defw 0033ch,082d4h,082e4h,082f4h,08304h,082d4h,08084h,08094h	; 82be
	defw 080a4h,080b8h,080cch,0fa08h,0040ch,0f8f8h,002e0h,0f8f8h	; 82ce
	defw 003dch,0fa08h,00308h,00008h,00420h,0f8f8h,002e0h,0fe08h	; 82de
	defw 0031ch,0f8f8h,003dch,0f808h,0047ch,0f8f8h,002e0h,0fa08h	; 82ee
	defw 00378h,0f8f8h,003dch,0fd08h,00440h,0f8f8h,002e0h,0f8f8h	; 82fe
	defw 00318h,0fc08h,0033ch,08328h,08338h,08348h,08358h,08328h	; 830e
	defw 08084h,08094h,080a4h,080b8h,080cch,0fe08h,00468h,000f8h	; 831e
	defw 00270h,000f8h,00374h,0fe08h,00364h,0fb08h,004a4h,000f8h	; 832e
	defw 00270h,000f8h,00374h,0fa08h,003ach,0f808h,004b4h,000f8h	; 833e
	defw 00270h,000f8h,00374h,0fb08h,003a0h,0fb08h,0049ch,000f8h	; 834e
	defw 00270h,000f8h,00374h,0fc08h,00398h	; 835e

; ----------------------------------------------------------------------
; DATOS parches_del_portero: dos arboles de 2 punteros a 12 subtablas de 11
;   hojas, uno desde 0x8368 y otro desde 0x83FD; los eligen 0x8860 y 0x8870
;   0x8368..0x8492  (298 bytes)
DATA_parches_del_portero:
	defw 0836ch,0836ch,08384h,0838fh,0839ah,083a5h,083b0h,083bbh	; 8368
	defw 083c6h,083d1h,083dch,083dch,083e7h,083f2h,0ffffh,03964h	; 8378
	defw 03301h,03a44h,03801h,0ff3ch,064ffh,00183h,04433h,0013ah	; 8388
	defw 03c38h,0ffffh,04264h,03301h,03a44h,03801h,0ff3ch,064ffh	; 8398
	defw 00139h,03f34h,00101h,0013bh,0ffffh,08364h,03401h,0013fh	; 83a8
	defw 03b01h,0ff01h,064ffh,00142h,03f34h,00101h,0013bh,0ffafh	; 83b8
	defw 08345h,03501h,00143h,03d01h,09f01h,00100h,0013eh,04001h	; 83c8
	defw 03601h,00141h,0ffffh,08364h,04701h,00149h,03701h,0ff46h	; 83d8
	defw 001ffh,00101h,0716fh,07073h,07472h,0ffffh,00101h,07601h	; 83e8
	defw 07371h,07877h,00174h,00184h,01984h,02484h,02f84h,03a84h	; 83f8
	defw 04584h,05084h,05b84h,06684h,07184h,07184h,07c84h,08784h	; 8408
	defw 0ff84h,001ffh,0d951h,05c52h,0544bh,00150h,0ffffh,0f801h	; 8418
	defw 052d9h,04b5ch,05054h,0ff01h,001ffh,0d95ah,05c52h,0544bh	; 8428
	defw 00150h,0ffffh,05101h,001d9h,04c57h,05301h,0ff01h,001ffh	; 8438
	defw 0d9f8h,05701h,0014ch,00153h,0ffffh,05a01h,001d9h,04c57h	; 8448
	defw 05301h,0af01h,001ffh,05df8h,05b01h,0014dh,00155h,0009fh	; 8458
	defw 05601h,00101h,00158h,05901h,0ff4eh,001ffh,0d9f8h,06101h	; 8468
	defw 05e5fh,0014fh,0ffffh,00101h,0c101h,0bdbfh,0c0c2h,0ffbeh	; 8478
	defw 001ffh,00101h,0bfc1h,0c2c4h,0c5c6h	; 8488

; ----------------------------------------------------------------------
; DATOS listas_de_sprites_sueltos: 0x8492 son 4 punteros y 0x84CA son 5, a
;   listas de atributos de sprite de cuatro bytes; la ultima acaba clavada en
;   0x8538. Los leen 0x6AE0 y 0x6A1E
;   0x8492..0x8538  (166 bytes)
DATA_listas_de_sprites_sueltos:
	defw 0849ah,0849ah,084aah,084bah,00008h,0043ch,0f8f8h,002e0h	; 8492
	defw 0fe08h,00338h,0f8f8h,003dch,0f808h,00464h,0f8f8h,002e0h	; 84a2
	defw 0fa08h,00360h,0f8f8h,003dch,0fd08h,00418h,0f8f8h,002e0h	; 84b2
	defw 0f8f8h,00314h,0fc08h,0031ch,084d4h,084e8h,084fch,08510h	; 84c2
	defw 08524h,0f8f8h,00200h,0fd03h,00304h,0fd06h,0040ch,0fd13h	; 84d2
	defw 00308h,0fd16h,00410h,0f8f7h,00258h,00106h,00440h,0fc01h	; 84e2
	defw 00348h,0050ch,0034ch,01110h,00444h,0f8f7h,00258h,00106h	; 84f2
	defw 00450h,0fc01h,00348h,00c07h,0035ch,013fbh,00454h,0f9f7h	; 8502
	defw 00280h,0f006h,00468h,0f501h,00370h,0ec0ch,00374h,0e010h	; 8512
	defw 0046ch,0f9f7h,00280h,0f006h,00478h,0f501h,00370h,0e507h	; 8522
	defw 00384h,0defbh,0047ch	; 8532

; ======================================================================
; CODIGO 0x8538..0x853e  (6 bytes)
; ======================================================================


L_8538:
	ld de,0853eh		;8538
	jp descomprime_en_la_ram		;853b

; ----------------------------------------------------------------------
; DATOS mapa_del_campo: 1840 bytes descomprimidos a la RAM en 0xE600: 80
;   columnas por 23 filas, de las que la pantalla solo ensena 32 de ancho. Lo
;   carga 0x8538 y lo asoma 0x5DD6
;   0x853e..0x8787  (585 bytes)
DATA_mapa_del_campo:
	defb 0d0h	; 853e
	defb 040h	; 853f
	defb 044h	; 8540
	defb 040h	; 8541
	defb 044h	; 8542
	defb 040h	; 8543
	defb 044h	; 8544
	defb 040h	; 8545
	defb 044h	; 8546
	defb 040h	; 8547
	defb 044h	; 8548
	defb 040h	; 8549
	defb 044h	; 854a
	defb 040h	; 854b
	defb 044h	; 854c
	defb 040h	; 854d
	defb 044h	; 854e
	defb 040h	; 854f
	defb 044h	; 8550
	defb 040h	; 8551
	defb 044h	; 8552
	defb 040h	; 8553
	defb 044h	; 8554
	defb 040h	; 8555
	defb 044h	; 8556
	defb 040h	; 8557
	defb 044h	; 8558
	defb 040h	; 8559
	defb 044h	; 855a
	defb 040h	; 855b
	defb 044h	; 855c
	defb 040h	; 855d
	defb 044h	; 855e
	defb 040h	; 855f
	defb 044h	; 8560
	defb 040h	; 8561
	defb 044h	; 8562
	defb 040h	; 8563
	defb 044h	; 8564
	defb 040h	; 8565
	defb 044h	; 8566
	defb 040h	; 8567
	defb 044h	; 8568
	defb 040h	; 8569
	defb 044h	; 856a
	defb 040h	; 856b
	defb 044h	; 856c
	defb 040h	; 856d
	defb 044h	; 856e
	defb 040h	; 856f
	defb 044h	; 8570
	defb 040h	; 8571
	defb 044h	; 8572
	defb 040h	; 8573
	defb 044h	; 8574
	defb 040h	; 8575
	defb 044h	; 8576
	defb 040h	; 8577
	defb 044h	; 8578
	defb 040h	; 8579
	defb 044h	; 857a
	defb 040h	; 857b
	defb 044h	; 857c
	defb 040h	; 857d
	defb 044h	; 857e
	defb 040h	; 857f
	defb 044h	; 8580
	defb 040h	; 8581
	defb 044h	; 8582
	defb 040h	; 8583
	defb 044h	; 8584
	defb 040h	; 8585
	defb 044h	; 8586
	defb 040h	; 8587
	defb 044h	; 8588
	defb 040h	; 8589
	defb 044h	; 858a
	defb 040h	; 858b
	defb 044h	; 858c
	defb 040h	; 858d
	defb 044h	; 858e
	defb 010h	; 858f
	defb 002h	; 8590
	defb 085h	; 8591
	defb 054h	; 8592
	defb 055h	; 8593
	defb 056h	; 8594
	defb 057h	; 8595
	defb 058h	; 8596
	defb 00ch	; 8597
	defb 002h	; 8598
	defb 08eh	; 8599
	defb 003h	; 859a
	defb 004h	; 859b
	defb 005h	; 859c
	defb 006h	; 859d
	defb 007h	; 859e
	defb 008h	; 859f
	defb 009h	; 85a0
	defb 002h	; 85a1
	defb 009h	; 85a2
	defb 004h	; 85a3
	defb 00ah	; 85a4
	defb 00ah	; 85a5
	defb 00bh	; 85a6
	defb 00ch	; 85a7
	defb 00bh	; 85a8
	defb 002h	; 85a9
	defb 085h	; 85aa
	defb 054h	; 85ab
	defb 055h	; 85ac
	defb 056h	; 85ad
	defb 057h	; 85ae
	defb 058h	; 85af
	defb 011h	; 85b0
	defb 002h	; 85b1
	defb 054h	; 85b2
	defb 001h	; 85b3
	defb 081h	; 85b4
	defb 046h	; 85b5
	defb 046h	; 85b6
	defb 043h	; 85b7
	defb 081h	; 85b8
	defb 04ah	; 85b9
	defb 008h	; 85ba
	defb 001h	; 85bb
	defb 082h	; 85bc
	defb 049h	; 85bd
	defb 048h	; 85be
	defb 021h	; 85bf
	defb 001h	; 85c0
	defb 082h	; 85c1
	defb 047h	; 85c2
	defb 04bh	; 85c3
	defb 021h	; 85c4
	defb 001h	; 85c5
	defb 082h	; 85c6
	defb 04ch	; 85c7
	defb 04dh	; 85c8
	defb 008h	; 85c9
	defb 001h	; 85ca
	defb 081h	; 85cb
	defb 049h	; 85cc
	defb 022h	; 85cd
	defb 001h	; 85ce
	defb 082h	; 85cf
	defb 047h	; 85d0
	defb 04bh	; 85d1
	defb 022h	; 85d2
	defb 001h	; 85d3
	defb 081h	; 85d4
	defb 04dh	; 85d5
	defb 006h	; 85d6
	defb 001h	; 85d7
	defb 083h	; 85d8
	defb 04eh	; 85d9
	defb 04fh	; 85da
	defb 050h	; 85db
	defb 022h	; 85dc
	defb 001h	; 85dd
	defb 082h	; 85de
	defb 047h	; 85df
	defb 04bh	; 85e0
	defb 022h	; 85e1
	defb 001h	; 85e2
	defb 083h	; 85e3
	defb 053h	; 85e4
	defb 052h	; 85e5
	defb 051h	; 85e6
	defb 004h	; 85e7
	defb 001h	; 85e8
	defb 083h	; 85e9
	defb 008h	; 85ea
	defb 009h	; 85eb
	defb 00ah	; 85ec
	defb 006h	; 85ed
	defb 002h	; 85ee
	defb 081h	; 85ef
	defb 015h	; 85f0
	defb 01bh	; 85f1
	defb 001h	; 85f2
	defb 082h	; 85f3
	defb 014h	; 85f4
	defb 02bh	; 85f5
	defb 01bh	; 85f6
	defb 001h	; 85f7
	defb 081h	; 85f8
	defb 02ch	; 85f9
	defb 006h	; 85fa
	defb 002h	; 85fb
	defb 083h	; 85fc
	defb 021h	; 85fd
	defb 020h	; 85fe
	defb 01fh	; 85ff
	defb 004h	; 8600
	defb 001h	; 8601
	defb 083h	; 8602
	defb 008h	; 8603
	defb 009h	; 8604
	defb 00bh	; 8605
	defb 006h	; 8606
	defb 001h	; 8607
	defb 081h	; 8608
	defb 015h	; 8609
	defb 01bh	; 860a
	defb 001h	; 860b
	defb 082h	; 860c
	defb 014h	; 860d
	defb 02bh	; 860e
	defb 01bh	; 860f
	defb 001h	; 8610
	defb 081h	; 8611
	defb 02ch	; 8612
	defb 006h	; 8613
	defb 001h	; 8614
	defb 083h	; 8615
	defb 022h	; 8616
	defb 020h	; 8617
	defb 01fh	; 8618
	defb 004h	; 8619
	defb 001h	; 861a
	defb 083h	; 861b
	defb 00ch	; 861c
	defb 00dh	; 861d
	defb 00eh	; 861e
	defb 003h	; 861f
	defb 002h	; 8620
	defb 084h	; 8621
	defb 015h	; 8622
	defb 001h	; 8623
	defb 001h	; 8624
	defb 015h	; 8625
	defb 01bh	; 8626
	defb 001h	; 8627
	defb 082h	; 8628
	defb 014h	; 8629
	defb 02bh	; 862a
	defb 01bh	; 862b
	defb 001h	; 862c
	defb 084h	; 862d
	defb 02ch	; 862e
	defb 001h	; 862f
	defb 001h	; 8630
	defb 02ch	; 8631
	defb 003h	; 8632
	defb 002h	; 8633
	defb 083h	; 8634
	defb 025h	; 8635
	defb 024h	; 8636
	defb 023h	; 8637
	defb 004h	; 8638
	defb 001h	; 8639
	defb 083h	; 863a
	defb 008h	; 863b
	defb 009h	; 863c
	defb 019h	; 863d
	defb 003h	; 863e
	defb 001h	; 863f
	defb 084h	; 8640
	defb 015h	; 8641
	defb 001h	; 8642
	defb 001h	; 8643
	defb 015h	; 8644
	defb 01bh	; 8645
	defb 001h	; 8646
	defb 082h	; 8647
	defb 014h	; 8648
	defb 02bh	; 8649
	defb 01bh	; 864a
	defb 001h	; 864b
	defb 084h	; 864c
	defb 02ch	; 864d
	defb 001h	; 864e
	defb 001h	; 864f
	defb 02ch	; 8650
	defb 003h	; 8651
	defb 001h	; 8652
	defb 083h	; 8653
	defb 030h	; 8654
	defb 020h	; 8655
	defb 01fh	; 8656
	defb 004h	; 8657
	defb 001h	; 8658
	defb 083h	; 8659
	defb 008h	; 865a
	defb 009h	; 865b
	defb 019h	; 865c
	defb 003h	; 865d
	defb 001h	; 865e
	defb 085h	; 865f
	defb 015h	; 8660
	defb 001h	; 8661
	defb 001h	; 8662
	defb 007h	; 8663
	defb 028h	; 8664
	defb 018h	; 8665
	defb 001h	; 8666
	defb 086h	; 8667
	defb 011h	; 8668
	defb 010h	; 8669
	defb 00fh	; 866a
	defb 026h	; 866b
	defb 027h	; 866c
	defb 028h	; 866d
	defb 018h	; 866e
	defb 001h	; 866f
	defb 085h	; 8670
	defb 011h	; 8671
	defb 01eh	; 8672
	defb 001h	; 8673
	defb 001h	; 8674
	defb 02ch	; 8675
	defb 003h	; 8676
	defb 001h	; 8677
	defb 083h	; 8678
	defb 030h	; 8679
	defb 020h	; 867a
	defb 01fh	; 867b
	defb 004h	; 867c
	defb 001h	; 867d
	defb 083h	; 867e
	defb 008h	; 867f
	defb 009h	; 8680
	defb 019h	; 8681
	defb 003h	; 8682
	defb 001h	; 8683
	defb 085h	; 8684
	defb 015h	; 8685
	defb 001h	; 8686
	defb 001h	; 8687
	defb 015h	; 8688
	defb 029h	; 8689
	defb 018h	; 868a
	defb 001h	; 868b
	defb 086h	; 868c
	defb 012h	; 868d
	defb 001h	; 868e
	defb 014h	; 868f
	defb 02bh	; 8690
	defb 001h	; 8691
	defb 029h	; 8692
	defb 018h	; 8693
	defb 001h	; 8694
	defb 085h	; 8695
	defb 012h	; 8696
	defb 02ch	; 8697
	defb 001h	; 8698
	defb 001h	; 8699
	defb 02ch	; 869a
	defb 003h	; 869b
	defb 001h	; 869c
	defb 083h	; 869d
	defb 030h	; 869e
	defb 020h	; 869f
	defb 01fh	; 86a0
	defb 004h	; 86a1
	defb 001h	; 86a2
	defb 083h	; 86a3
	defb 01bh	; 86a4
	defb 006h	; 86a5
	defb 019h	; 86a6
	defb 003h	; 86a7
	defb 001h	; 86a8
	defb 085h	; 86a9
	defb 015h	; 86aa
	defb 001h	; 86ab
	defb 001h	; 86ac
	defb 015h	; 86ad
	defb 02ah	; 86ae
	defb 018h	; 86af
	defb 001h	; 86b0
	defb 086h	; 86b1
	defb 013h	; 86b2
	defb 001h	; 86b3
	defb 014h	; 86b4
	defb 02bh	; 86b5
	defb 001h	; 86b6
	defb 02ah	; 86b7
	defb 018h	; 86b8
	defb 001h	; 86b9
	defb 085h	; 86ba
	defb 013h	; 86bb
	defb 02ch	; 86bc
	defb 001h	; 86bd
	defb 001h	; 86be
	defb 02ch	; 86bf
	defb 003h	; 86c0
	defb 001h	; 86c1
	defb 083h	; 86c2
	defb 030h	; 86c3
	defb 01dh	; 86c4
	defb 032h	; 86c5
	defb 004h	; 86c6
	defb 001h	; 86c7
	defb 083h	; 86c8
	defb 008h	; 86c9
	defb 009h	; 86ca
	defb 005h	; 86cb
	defb 003h	; 86cc
	defb 001h	; 86cd
	defb 085h	; 86ce
	defb 015h	; 86cf
	defb 001h	; 86d0
	defb 001h	; 86d1
	defb 01ah	; 86d2
	defb 02dh	; 86d3
	defb 018h	; 86d4
	defb 001h	; 86d5
	defb 086h	; 86d6
	defb 016h	; 86d7
	defb 017h	; 86d8
	defb 018h	; 86d9
	defb 02fh	; 86da
	defb 02eh	; 86db
	defb 02dh	; 86dc
	defb 018h	; 86dd
	defb 001h	; 86de
	defb 085h	; 86df
	defb 016h	; 86e0
	defb 031h	; 86e1
	defb 001h	; 86e2
	defb 001h	; 86e3
	defb 02ch	; 86e4
	defb 003h	; 86e5
	defb 001h	; 86e6
	defb 083h	; 86e7
	defb 01ch	; 86e8
	defb 020h	; 86e9
	defb 01fh	; 86ea
	defb 004h	; 86eb
	defb 001h	; 86ec
	defb 083h	; 86ed
	defb 00fh	; 86ee
	defb 014h	; 86ef
	defb 00bh	; 86f0
	defb 003h	; 86f1
	defb 001h	; 86f2
	defb 084h	; 86f3
	defb 01eh	; 86f4
	defb 001h	; 86f5
	defb 001h	; 86f6
	defb 01eh	; 86f7
	defb 01bh	; 86f8
	defb 001h	; 86f9
	defb 082h	; 86fa
	defb 011h	; 86fb
	defb 01ch	; 86fc
	defb 01bh	; 86fd
	defb 001h	; 86fe
	defb 084h	; 86ff
	defb 013h	; 8700
	defb 001h	; 8701
	defb 001h	; 8702
	defb 013h	; 8703
	defb 003h	; 8704
	defb 001h	; 8705
	defb 083h	; 8706
	defb 016h	; 8707
	defb 01fh	; 8708
	defb 01ah	; 8709
	defb 004h	; 870a
	defb 001h	; 870b
	defb 083h	; 870c
	defb 00ch	; 870d
	defb 00dh	; 870e
	defb 00eh	; 870f
	defb 003h	; 8710
	defb 009h	; 8711
	defb 084h	; 8712
	defb 01eh	; 8713
	defb 001h	; 8714
	defb 001h	; 8715
	defb 01eh	; 8716
	defb 01bh	; 8717
	defb 001h	; 8718
	defb 082h	; 8719
	defb 011h	; 871a
	defb 01ch	; 871b
	defb 01bh	; 871c
	defb 001h	; 871d
	defb 084h	; 871e
	defb 013h	; 871f
	defb 001h	; 8720
	defb 001h	; 8721
	defb 013h	; 8722
	defb 003h	; 8723
	defb 009h	; 8724
	defb 083h	; 8725
	defb 019h	; 8726
	defb 018h	; 8727
	defb 017h	; 8728
	defb 006h	; 8729
	defb 001h	; 872a
	defb 081h	; 872b
	defb 013h	; 872c
	defb 006h	; 872d
	defb 001h	; 872e
	defb 081h	; 872f
	defb 01eh	; 8730
	defb 01bh	; 8731
	defb 001h	; 8732
	defb 082h	; 8733
	defb 011h	; 8734
	defb 01ch	; 8735
	defb 01bh	; 8736
	defb 001h	; 8737
	defb 081h	; 8738
	defb 013h	; 8739
	defb 006h	; 873a
	defb 001h	; 873b
	defb 081h	; 873c
	defb 01eh	; 873d
	defb 008h	; 873e
	defb 001h	; 873f
	defb 081h	; 8740
	defb 013h	; 8741
	defb 006h	; 8742
	defb 009h	; 8743
	defb 081h	; 8744
	defb 01eh	; 8745
	defb 01bh	; 8746
	defb 001h	; 8747
	defb 082h	; 8748
	defb 011h	; 8749
	defb 01ch	; 874a
	defb 01bh	; 874b
	defb 001h	; 874c
	defb 081h	; 874d
	defb 013h	; 874e
	defb 006h	; 874f
	defb 009h	; 8750
	defb 081h	; 8751
	defb 01eh	; 8752
	defb 008h	; 8753
	defb 001h	; 8754
	defb 081h	; 8755
	defb 013h	; 8756
	defb 022h	; 8757
	defb 001h	; 8758
	defb 082h	; 8759
	defb 011h	; 875a
	defb 01ch	; 875b
	defb 022h	; 875c
	defb 001h	; 875d
	defb 081h	; 875e
	defb 01eh	; 875f
	defb 008h	; 8760
	defb 001h	; 8761
	defb 081h	; 8762
	defb 013h	; 8763
	defb 022h	; 8764
	defb 001h	; 8765
	defb 082h	; 8766
	defb 011h	; 8767
	defb 01ch	; 8768
	defb 022h	; 8769
	defb 001h	; 876a
	defb 081h	; 876b
	defb 01eh	; 876c
	defb 008h	; 876d
	defb 001h	; 876e
	defb 082h	; 876f
	defb 013h	; 8770
	defb 010h	; 8771
	defb 021h	; 8772
	defb 001h	; 8773
	defb 082h	; 8774
	defb 011h	; 8775
	defb 01ch	; 8776
	defb 021h	; 8777
	defb 001h	; 8778
	defb 082h	; 8779
	defb 01bh	; 877a
	defb 01eh	; 877b
	defb 008h	; 877c
	defb 001h	; 877d
	defb 081h	; 877e
	defb 012h	; 877f
	defb 046h	; 8780
	defb 002h	; 8781
	defb 081h	; 8782
	defb 01dh	; 8783
	defb 004h	; 8784
	defb 001h	; 8785
	defb 000h	; 8786

; ======================================================================
; CODIGO 0x8787..0x878d  (6 bytes)
; ======================================================================


L_8787:
	ld de,0878dh		;8787
	jp descomprime_con_destino_dentro		;878a

; ----------------------------------------------------------------------
; DATOS nombres_878d: 144 bytes comprimidos que dan 736 de VRAM en 0x3820; lo
;   carga 0x878A
;   0x878d..0x881d  (144 bytes)
DATA_nombres_878d:
	defb 020h	; 878d
	defb 038h	; 878e
	defb 028h	; 878f
	defb 044h	; 8790
	defb 082h	; 8791
	defb 046h	; 8792
	defb 047h	; 8793
	defb 00ch	; 8794
	defb 040h	; 8795
	defb 082h	; 8796
	defb 054h	; 8797
	defb 053h	; 8798
	defb 010h	; 8799
	defb 044h	; 879a
	defb 082h	; 879b
	defb 046h	; 879c
	defb 048h	; 879d
	defb 00ch	; 879e
	defb 041h	; 879f
	defb 082h	; 87a0
	defb 055h	; 87a1
	defb 053h	; 87a2
	defb 010h	; 87a3
	defb 044h	; 87a4
	defb 082h	; 87a5
	defb 046h	; 87a6
	defb 048h	; 87a7
	defb 00ch	; 87a8
	defb 042h	; 87a9
	defb 082h	; 87aa
	defb 055h	; 87ab
	defb 053h	; 87ac
	defb 010h	; 87ad
	defb 044h	; 87ae
	defb 082h	; 87af
	defb 046h	; 87b0
	defb 048h	; 87b1
	defb 00ch	; 87b2
	defb 042h	; 87b3
	defb 082h	; 87b4
	defb 055h	; 87b5
	defb 053h	; 87b6
	defb 010h	; 87b7
	defb 044h	; 87b8
	defb 082h	; 87b9
	defb 046h	; 87ba
	defb 049h	; 87bb
	defb 00ch	; 87bc
	defb 043h	; 87bd
	defb 082h	; 87be
	defb 056h	; 87bf
	defb 053h	; 87c0
	defb 010h	; 87c1
	defb 044h	; 87c2
	defb 082h	; 87c3
	defb 046h	; 87c4
	defb 04ah	; 87c5
	defb 00ch	; 87c6
	defb 044h	; 87c7
	defb 082h	; 87c8
	defb 057h	; 87c9
	defb 053h	; 87ca
	defb 008h	; 87cb
	defb 044h	; 87cc
	defb 007h	; 87cd
	defb 043h	; 87ce
	defb 081h	; 87cf
	defb 058h	; 87d0
	defb 010h	; 87d1
	defb 043h	; 87d2
	defb 081h	; 87d3
	defb 04bh	; 87d4
	defb 007h	; 87d5
	defb 043h	; 87d6
	defb 006h	; 87d7
	defb 044h	; 87d8
	defb 081h	; 87d9
	defb 059h	; 87da
	defb 012h	; 87db
	defb 044h	; 87dc
	defb 081h	; 87dd
	defb 04ch	; 87de
	defb 00ch	; 87df
	defb 044h	; 87e0
	defb 081h	; 87e1
	defb 05ah	; 87e2
	defb 012h	; 87e3
	defb 044h	; 87e4
	defb 081h	; 87e5
	defb 04dh	; 87e6
	defb 00bh	; 87e7
	defb 044h	; 87e8
	defb 081h	; 87e9
	defb 059h	; 87ea
	defb 014h	; 87eb
	defb 044h	; 87ec
	defb 081h	; 87ed
	defb 04ch	; 87ee
	defb 00ah	; 87ef
	defb 044h	; 87f0
	defb 081h	; 87f1
	defb 05ah	; 87f2
	defb 014h	; 87f3
	defb 044h	; 87f4
	defb 081h	; 87f5
	defb 04dh	; 87f6
	defb 00ah	; 87f7
	defb 044h	; 87f8
	defb 016h	; 87f9
	defb 043h	; 87fa
	defb 07fh	; 87fb
	defb 044h	; 87fc
	defb 015h	; 87fd
	defb 044h	; 87fe
	defb 082h	; 87ff
	defb 045h	; 8800
	defb 052h	; 8801
	defb 06fh	; 8802
	defb 044h	; 8803
	defb 008h	; 8804
	defb 043h	; 8805
	defb 081h	; 8806
	defb 04eh	; 8807
	defb 00eh	; 8808
	defb 043h	; 8809
	defb 081h	; 880a
	defb 05bh	; 880b
	defb 008h	; 880c
	defb 043h	; 880d
	defb 008h	; 880e
	defb 044h	; 880f
	defb 083h	; 8810
	defb 04fh	; 8811
	defb 050h	; 8812
	defb 051h	; 8813
	defb 00ah	; 8814
	defb 044h	; 8815
	defb 083h	; 8816
	defb 05eh	; 8817
	defb 05dh	; 8818
	defb 05ch	; 8819
	defb 008h	; 881a
	defb 044h	; 881b
	defb 000h	; 881c

; ======================================================================
; CODIGO 0x881d..0x8c63  (1094 bytes)
; ======================================================================


estampa_el_bando_en_el_mapa:		; ordena su bando por altura y estampa los seis parches de 3x3 sobre el mapa
	call ordena_el_bando_por_altura		;881d   ; antes de nada ordena el bando de atras a delante: el que va mas abajo se estampa el ultimo y tapa
	ld a,(0e527h)		;8820   ; (0xE527) reparte los dos bandos: uno se estampa en el mapa y el otro sale por sprites
	and a			;8823
	ld hl,07d14h		;8824   ; tabla de dos niveles de parches del primer bando
	jr nz,L_882C		;8827
	ld hl,07ea4h		;8829   ; y la del segundo, 0x190 bytes mas alla
L_882C:
	ld (0e521h),hl		;882c   ; (0xE521) es el apoyo donde estas rutinas dejan la tabla de parches con la que trabajan
	ld hl,0e2d1h		;882f   ; la lista ordenada de 0x88D8 empieza en 0xE2D0; aqui se lee solo el segundo byte de cada pareja, el numero del jugador
	exx			;8832   ; el puntero de la lista se aparca en el juego alterno mientras HL hace las cuentas
	ld b,006h		;8833   ; seis, que es lo que tiene un bando
L_8835:
	exx			;8835
	ld a,(hl)			;8836   ; A = el numero del jugador (0..11)
	ld c,a			;8837
	inc l			;8838   ; dos incrementos de L: a la pareja siguiente de la lista
	inc l			;8839
	push hl			;883a   ; y esa pareja siguiente se guarda, que HL va a hacer falta
	add a,a			;883b   ; cuatro `add a,a` y un `add hl,hl`: numero por 32, que es lo que ocupa cada ficha
	add a,a			;883c
	add a,a			;883d
	add a,a			;883e
	ld l,a			;883f
	ld h,000h		;8840
	add hl,hl			;8842
	ex de,hl			;8843
	ld ix,0e100h		;8844   ; base de las fichas
	add ix,de		;8848   ; IX ya apunta a la ficha de este jugador
	ld a,c			;884a   ; el mismo numero por 11: cada jugador tiene once bytes de fondo guardado
	add a,a			;884b
	ld b,a			;884c
	add a,a			;884d
	add a,a			;884e
	add a,b			;884f
	add a,c			;8850
	ld e,a			;8851
	ld d,000h		;8852
	ld hl,0e480h		;8854   ; 0xE480 es el almacen del fondo del primer bando (0xE4C2 el del segundo)
	add hl,de			;8857
	ex de,hl			;8858
	call estampa_un_parche		;8859   ; con IX en la ficha y DE en su hueco, a estampar
	pop hl			;885c   ; la lista vuelve a HL
	exx			;885d   ; el `exx` devuelve el contador de los seis
	djnz L_8835		;885e
	ld hl,08368h		;8860   ; detras de los seis van dos parches mas, con su propia tabla y su propio hueco de fondo
	ld (0e521h),hl		;8863
	ld de,0e5e0h		;8866   ; su hueco de fondo va suelto, fuera de los dos bloques de seis
	ld ix,0e330h		;8869   ; la ficha de 0xE330, que no es de jugador
	call estampa_un_parche		;886d
	ld hl,083fdh		;8870
	ld (0e521h),hl		;8873
	ld de,0e5ebh		;8876
	ld ix,0e350h		;8879   ; y la de 0xE350; se cae dentro de 0x887D, que hace de `jp`
estampa_un_parche:		; estampa las 3x3 casillas de un parche en el mapa, en la direccion que dejo 0x8A58
	ld a,(ix+00ah)		;887d   ; +0x0A guarda la Y de ventana, y 0xE0 significa "este no se ve"
	cp 0e0h		;8880
	ret z			;8882
	ld a,(ix+00ch)		;8883   ; +0x0C es el primer indice: elige el grupo dentro de la tabla de (0xE521)
	ld hl,(0e521h)		;8886   ; la tabla del bando, que dejo puesta 0x8824 o 0x8829
	add a,a			;8889   ; palabras, asi que el indice va por dos
	ld c,a			;888a
	ld b,000h		;888b
	add hl,bc			;888d
	ld a,(ix+00dh)		;888e   ; +0x0D es el segundo indice, el dibujo dentro del grupo
	ld c,(hl)			;8891   ; la palabra de la tabla apunta al grupo
	inc hl			;8892
	ld b,(hl)			;8893
	add a,a			;8894   ; y dentro del grupo se vuelve a ir de palabra en palabra
	ld l,a			;8895
	ld h,000h		;8896
	add hl,bc			;8898
	ld c,(hl)			;8899
	inc hl			;889a
	ld h,(hl)			;889b
	ld l,c			;889c
	inc hl			;889d   ; el parche empieza con dos bytes de correccion que aqui ya no hacen falta: se saltan
	inc hl			;889e
	ld a,(de)			;889f   ; los dos primeros bytes del hueco de fondo son la direccion del mapa donde toca estampar
	ld c,a			;88a0
	inc de			;88a1
	ld a,(de)			;88a2
	and a			;88a3   ; si el byte alto es cero es que 0x8A58 no lo relleno, o sea que este no se dibuja
	ret z			;88a4
	ld d,a			;88a5   ; DE queda con la casilla del mapa, que es a donde se copia
	ld e,c			;88a6
	push hl			;88a7
	ld hl,0e69fh		;88a8   ; 0xE69F es el final de las dos primeras filas del mapa
	and a			;88ab
	sbc hl,de		;88ac
	pop hl			;88ae
	jr c,copia_las_tres_filas		;88af   ; por debajo de ahi se estampan las tres casillas enteras
	inc hl			;88b1   ; y si cae en esas dos filas de arriba solo se pone la casilla del centro, saltando las de los lados
	inc de			;88b2
	ldi		;88b3
	inc hl			;88b5
	inc de			;88b6
	jr L_88BF		;88b7
copia_las_tres_filas:		; copia las 3x3 casillas de HL a DE saltando de fila en fila del mapa
	ldi		;88b9   ; la fila de arriba del parche
	ldi		;88bb
	ldi		;88bd
L_88BF:
	ld bc,0004dh		;88bf   ; 0x4D + las 3 que se acaban de escribir son 0x50, las 80 columnas que mide el mapa
	ex de,hl			;88c2
	add hl,bc			;88c3
	ex de,hl			;88c4
	ldi		;88c5   ; la fila de en medio
	ldi		;88c7
	ldi		;88c9
	ld bc,0004dh		;88cb
	ex de,hl			;88ce
	add hl,bc			;88cf
	ex de,hl			;88d0
	ldi		;88d1   ; y la de abajo
	ldi		;88d3
	ldi		;88d5
	ret			;88d7
ordena_el_bando_por_altura:		; deja en 0xE2D0 las seis parejas (altura, numero) del bando estampado, de arriba a abajo
	ld a,(0e527h)		;88d8   ; el bando que se estampa es el contrario al que sale por sprites
	ld ix,0e100h		;88db   ; la primera ficha de las doce
	and a			;88df
	jr nz,L_88E6		;88e0
	ld ix,0e1c0h		;88e2   ; la segunda mitad de las fichas: 0xE1C0 es 0xE100 + 6 fichas de 32
L_88E6:
	ld hl,0e2d0h		;88e6
	ld de,00020h		;88e9   ; el paso entre fichas, 32 bytes
	ld b,006h		;88ec
L_88EE:
	ld a,(ix+004h)		;88ee   ; +4 es la altura, y es por lo que se ordena
	ld (hl),a			;88f1
	inc l			;88f2
	ld a,(ix+015h)		;88f3   ; +0x15 es el numero del jugador, que viaja pegado a su altura
	ld (hl),a			;88f6
	inc l			;88f7
	add ix,de		;88f8   ; a la ficha siguiente
	djnz L_88EE		;88fa

; ----------------------------------------------------------------------
; ----- ordenacion por seleccion de las seis parejas -----
; ----------------------------------------------------------------------
	ld de,0e2d0h		;88fc   ; a partir de aqui, una ordenacion por seleccion sobre las seis parejas
	ld hl,0e2d2h		;88ff   ; la comparacion siempre empieza en la pareja siguiente a la de DE
	ld b,005h		;8902   ; cinco vueltas: la ultima pareja ya no tiene con quien compararse
L_8904:
	ld a,(de)			;8904   ; la altura de la pareja fija de esta vuelta
	ld c,a			;8905
	ld a,b			;8906   ; la cuenta que queda es la de comparaciones de esta vuelta
	push hl			;8907
	exx			;8908
	ld b,a			;8909
L_890A:
	exx			;890a
	ld a,(hl)			;890b   ; la altura de la pareja con la que se compara
	cp c			;890c   ; si la altura de HL no es menor, no hay nada que cambiar
	jr nc,L_891C		;890d
	ld (hl),c			;890f   ; intercambia las dos alturas
	ld (de),a			;8910
	inc e			;8911
	ld c,a			;8912   ; y C se queda con la nueva altura de la pareja fija
	inc l			;8913
	ld a,(hl)			;8914   ; y detras van los dos numeros de jugador, para que no se despeguen de su altura
	ex af,af'			;8915
	ld a,(de)			;8916
	ld (hl),a			;8917
	ex af,af'			;8918
	ld (de),a			;8919
	dec e			;891a
	dec l			;891b
L_891C:
	inc l			;891c   ; la pareja siguiente
	inc l			;891d
	exx			;891e
	djnz L_890A		;891f
	exx			;8921
	inc de			;8922   ; acabada la vuelta, la pareja fija tambien avanza dos
	inc de			;8923
	pop hl			;8924
	inc l			;8925   ; y con ella el punto por donde empieza a comparar
	inc l			;8926
	djnz L_8904		;8927
	ret			;8929
pon_el_bando_en_sprites:		; monta los cuatro sprites de cada uno de los seis del bando que no se estampa
	ld a,(0e527h)		;892a   ; el bando de los sprites es el contrario al de 0x88D8
	and a			;892d
	jr nz,L_8939		;892e
	ld ix,0e100h		;8930   ; el primer bando, con su paleta
	ld de,0e051h		;8934   ; 0xE051 y 0xE056 son las dos paletas de cinco entradas, una camiseta cada una
	jr L_8940		;8937
L_8939:
	ld ix,0e1c0h		;8939   ; y el segundo bando con la suya
	ld de,0e056h		;893d
L_8940:
	exx			;8940
	ld hl,0801eh		;8941   ; la tabla de dibujos de sprite, comun a los dos bandos: el color lo pone la paleta
	ld (0e521h),hl		;8944   ; la misma casilla de apoyo que usan los parches
	ld hl,0e3a0h		;8947   ; 0xE3A0 es el sprite 4 de la copia: los cuatro primeros son la pelota y su sombra
	ld (0e523h),hl		;894a   ; (0xE523) es el sprite por el que se va escribiendo, y va subiendo solo
	exx			;894d
	ld b,006h		;894e   ; los seis del bando
L_8950:
	exx			;8950   ; la paleta viaja en DE' todo el rato
	call monta_los_sprites_de_uno		;8951
	ld bc,00020h		;8954   ; a la ficha siguiente
	add ix,bc		;8957
	exx			;8959
	djnz L_8950		;895a
	ret			;895c
monta_los_sprites_de_uno:		; saca los cuatro sprites de un jugador, o los aparca si no se ve
	ld a,(ix+00ah)		;895d   ; +0x0A con 0xE0 es el jugador que 0x8AE6 dejo fuera de la ventana
	cp 0e0h		;8960
	jr nz,L_8976		;8962
	ld hl,(0e523h)		;8964   ; aparcarlo es poner esa misma Y de 0xE0 en sus cuatro sprites
	ld de,00004h		;8967   ; cuatro bytes por sprite: Y, X, dibujo y color
	ld (hl),a			;896a
	add hl,de			;896b
	ld (hl),a			;896c
	add hl,de			;896d
	ld (hl),a			;896e
	add hl,de			;896f
	ld (hl),a			;8970
	add hl,de			;8971
	ld (0e523h),hl		;8972   ; y aun aparcado (0xE523) tiene que saltarse sus cuatro sitios
	ret			;8975
L_8976:
	ld a,(ix+00ch)		;8976   ; +0x0C, el grupo dentro de la tabla
	ld hl,(0e521h)		;8979
	ld b,002h		;897c   ; dos niveles de tabla, igual que en los parches
L_897E:
	add a,a			;897e
	call suma_a_hl		;897f
	ld e,(hl)			;8982
	inc hl			;8983
	ld d,(hl)			;8984
	ld a,(ix+00dh)		;8985   ; el segundo indice se carga aqui para que la vuelta de abajo lo use
	ex de,hl			;8988
	djnz L_897E		;8989
	ex de,hl			;898b
	ld hl,(0e523h)		;898c   ; (0xE523), el primer sprite libre
	ld c,(ix+00ah)		;898f   ; +0x0A y +0x0B son la Y y la X de ventana que 0x8AE6 dejo puestas
	ld b,(ix+00bh)		;8992
	call monta_un_sprite		;8995   ; tres sprites aqui y el cuarto al caer, que 0x6B04 acaba en `ret`
	call monta_un_sprite		;8998
	call monta_un_sprite		;899b
	ld a,(de)			;899e   ; el cuarto sprite va copiado a pelo porque lleva una comprobacion de mas
	inc de			;899f
	cp 0e0h		;89a0   ; esa comprobacion: con 0xE0 en la Y, el cuarto sprite se deja donde diga la tabla y no se le suma la del jugador
	jr z,L_89A5		;89a2
	add a,c			;89a4   ; y si no, la Y de la tabla es un desplazamiento sobre la del jugador
L_89A5:
	ld (hl),a			;89a5
	inc hl			;89a6
	ld a,(de)			;89a7
	inc de			;89a8
	add a,b			;89a9   ; igual con la X
	ld (hl),a			;89aa
	inc hl			;89ab
	ld a,(de)			;89ac
	ld (hl),a			;89ad   ; el dibujo pasa tal cual
	inc de			;89ae
	inc hl			;89af
	ld a,(de)			;89b0
	exx			;89b1
	ld l,e			;89b2   ; el color no: es un indice a la paleta de cinco entradas de la camiseta
	add a,l			;89b3
	ld l,a			;89b4
	ld a,(hl)			;89b5
	exx			;89b6
	ld (hl),a			;89b7
	inc hl			;89b8
	ld (0e523h),hl		;89b9   ; y (0xE523) queda listo para el jugador siguiente

; ----------------------------------------------------------------------
; ----- y si este es el jugador que llevas, parpadea -----
; ----------------------------------------------------------------------
	ld a,(0e002h)		;89bc   ; a partir de aqui, el parpadeo del jugador que llevas
	bit 5,a		;89bf   ; sin este bit solo parpadea el destacado del primer bando
	jr nz,L_89CD		;89c1
	ld de,0e1c0h		;89c3   ; 0xE1C0 parte las fichas en dos bandos
	ld hl,(0e28dh)		;89c6
	and a			;89c9
	sbc hl,de		;89ca
	ret nc			;89cc
L_89CD:
	ld a,(0e280h)		;89cd   ; fuera del partido no parpadea nadie
	and a			;89d0
	ret z			;89d1
	push ix		;89d2   ; (0xE28D) apunta a la ficha del jugador destacado
	pop de			;89d4
	ld hl,(0e28dh)		;89d5
	and a			;89d8
	sbc hl,de		;89d9
	ret nz			;89db   ; si esta ficha no es la suya, se queda con su color
	ld a,(0e003h)		;89dc
	bit 1,a		;89df   ; el bit 1 del contador de cuadros: dos cuadros encendido y dos apagado
	ret nz			;89e1
	exx			;89e2
	ld l,e			;89e3   ; la quinta entrada de la paleta de la camiseta
	ld h,d			;89e4
	inc hl			;89e5
	inc hl			;89e6
	inc hl			;89e7
	inc hl			;89e8
	ld a,(hl)			;89e9
	exx			;89ea
	cp 00fh		;89eb   ; si esa entrada ya es blanca se parpadea en cian, y si no en blanco
	ld a,007h		;89ed
	jr z,L_89F3		;89ef
	ld a,00fh		;89f1
L_89F3:
	ld iy,(0e523h)		;89f3   ; (0xE523) ya apunta detras de los cuatro sprites recien escritos
	ld (iy-001h),a		;89f7   ; -1, -5, -9 y -0x0D son los cuatro bytes de color, uno por sprite
	ld (iy-005h),a		;89fa
	ld (iy-009h),a		;89fd
	ld (iy-00dh),a		;8a00
	ret			;8a03
guarda_el_fondo_del_bando:		; aparta las 3x3 casillas del mapa que va a tapar cada parche
	ld a,(0e527h)		;8a04   ; el mismo reparto de bandos que 0x881D, para que los parches y sus fondos casen
	and a			;8a07
	jr z,L_8A19		;8a08
	ld hl,07d14h		;8a0a
	ld (0e521h),hl		;8a0d
	ld de,0e480h		;8a10   ; 0xE480: seis huecos de once bytes, uno por jugador
	ld ix,0e100h		;8a13
	jr L_8A26		;8a17
L_8A19:
	ld hl,07ea4h		;8a19
	ld (0e521h),hl		;8a1c
	ld de,0e4c2h		;8a1f   ; y 0xE4C2 para el otro bando, 0x42 mas alla, que son esos mismos 6 por 11
	ld ix,0e1c0h		;8a22
L_8A26:
	ld b,006h		;8a26   ; los seis, y aqui en el orden de la plantilla: para guardar el fondo da igual quien tapa a quien
L_8A28:
	push bc			;8a28
	push de			;8a29
	call guarda_el_fondo_de_uno		;8a2a
	ld bc,00020h		;8a2d   ; a la ficha siguiente
	add ix,bc		;8a30
	pop de			;8a32
	ld hl,0000bh		;8a33   ; al hueco siguiente, once bytes mas alla
	add hl,de			;8a36
	ex de,hl			;8a37
	pop bc			;8a38
	djnz L_8A28		;8a39
	ld hl,08368h		;8a3b   ; los dos parches de fuera de plantilla, con sus huecos sueltos en 0xE5E0 y 0xE5EB
	ld (0e521h),hl		;8a3e
	ld de,0e5e0h		;8a41
	ld ix,0e330h		;8a44
	call guarda_el_fondo_de_uno		;8a48
	ld hl,083fdh		;8a4b
	ld (0e521h),hl		;8a4e
	ld de,0e5ebh		;8a51
	ld ix,0e350h		;8a54
guarda_el_fondo_de_uno:		; calcula la casilla del mapa que le toca y se guarda las 3x3 de debajo
	ld a,(ix+00ah)		;8a58   ; el que no se ve no tapa nada, asi que no hay fondo que guardar
	cp 0e0h		;8a5b
	ret z			;8a5d
	push de			;8a5e   ; el hueco se aparca hasta que la casilla este calculada
	ld a,(ix+004h)		;8a5f   ; la altura
	ld e,(ix+006h)		;8a62   ; y el ancho, 16 bits porque el campo mide 640 pixeles
	ld d,(ix+007h)		;8a65
	add a,004h		;8a68   ; +4 y dos veces `and 0F8h` con un -8 en medio: redondea la altura a casilla y sube una fila
	and 0f8h		;8a6a
	sub 008h		;8a6c
	and 0f8h		;8a6e
	ld h,000h		;8a70
	ld l,a			;8a72
	add hl,hl			;8a73   ; la fila por 10 y por 8 mas adelante: 80 columnas por fila
	ld c,l			;8a74
	ld b,h			;8a75
	add hl,hl			;8a76
	add hl,hl			;8a77
	add hl,bc			;8a78
	ld a,e			;8a79
	and 0f8h		;8a7a   ; la columna es el ancho entre ocho, con el bit alto arrastrado tres veces
	rr d		;8a7c
	rra			;8a7e
	rr d		;8a7f
	rra			;8a81
	rr d		;8a82
	rra			;8a84
	ld e,a			;8a85
	add hl,de			;8a86   ; fila mas columna, que es el desplazamiento dentro del mapa
	ld de,0e600h		;8a87   ; el mapa del campo vive en 0xE600
	add hl,de			;8a8a
	ex de,hl			;8a8b
	ld a,(ix+00ch)		;8a8c   ; los mismos dos indices, +0x0C y +0x0D, que usa 0x887D
	ld c,(ix+00dh)		;8a8f
	ld hl,(0e521h)		;8a92
	ld b,002h		;8a95   ; y los mismos dos niveles de tabla
L_8A97:
	add a,a			;8a97
	call suma_a_hl		;8a98
	ld a,c			;8a9b
	ld c,(hl)			;8a9c
	inc hl			;8a9d
	ld h,(hl)			;8a9e
	ld l,c			;8a9f
	djnz L_8A97		;8aa0
	ld c,(hl)			;8aa2   ; la palabra de cabecera del parche: la correccion que lo centra sobre la casilla
	inc hl			;8aa3
	ld b,(hl)			;8aa4
	ex de,hl			;8aa5
	pop de			;8aa6   ; el hueco de fondo vuelve de la pila
	add hl,bc			;8aa7   ; la correccion sube el parche a su esquina de arriba a la izquierda
	ld a,l			;8aa8   ; esa direccion ya corregida es lo primero que se guarda en el hueco
	ld (de),a			;8aa9
	inc de			;8aaa
	ld a,h			;8aab
	ld (de),a			;8aac
	inc de			;8aad
	ldi		;8aae   ; y detras las nueve casillas, saltando 0x4D + 3 = las 80 del mapa
	ldi		;8ab0
	ldi		;8ab2
	ld bc,0004dh		;8ab4
	add hl,bc			;8ab7
	ldi		;8ab8
	ldi		;8aba
	ldi		;8abc
	ld bc,0004dh		;8abe
	add hl,bc			;8ac1
	ldi		;8ac2
	ldi		;8ac4
	ldi		;8ac6
	ret			;8ac8
pasa_los_doce_a_la_ventana:		; da a cada ficha su Y y su X de ventana, o el 0xE0 de "no se ve"
	ld b,00ch		;8ac9   ; los doce: seis por bando
	ld ix,0e100h		;8acb   ; aqui van todos seguidos, sin separar bandos
L_8ACF:
	exx			;8acf
	call mira_si_cabe_en_la_ventana		;8ad0
	ld bc,00020h		;8ad3
	add ix,bc		;8ad6
	exx			;8ad8
	djnz L_8ACF		;8ad9
	ld ix,0e330h		;8adb   ; los dos de siempre que no son jugadores
	call mira_si_cabe_en_la_ventana		;8adf
	ld ix,0e350h		;8ae2   ; y se cae dentro de 0x8AE6
mira_si_cabe_en_la_ventana:		; pone +0x0A y +0x0B con la altura y el ancho relativo, o 0xE0 si se sale
	ld e,(ix+006h)		;8ae6   ; el ancho de campo, 16 bits
	ld d,(ix+007h)		;8ae9
	ld bc,000e0h		;8aec   ; el valor de "no se ve": Y 0xE0 y X 0
	ld hl,(0e2c6h)		;8aef   ; (0xE2C6) es el borde derecho de la ventana, que 0x8D7E deja en izquierdo + 255
	and a			;8af2
	sbc hl,de		;8af3
	jr c,L_8B08		;8af5   ; pasado el borde derecho, fuera
	ld hl,(0e2c3h)		;8af7   ; (0xE2C3) es el borde izquierdo
	ex de,hl			;8afa
	sbc hl,de		;8afb   ; ancho menos borde izquierdo: lo que hay que restar para pasar a la ventana
	jr c,L_8B08		;8afd   ; y por delante del borde izquierdo, tambien fuera
	ld a,l			;8aff   ; pegado al borde izquierdo tampoco vale: hacen falta ocho pixeles
	cp 008h		;8b00
	jr c,L_8B08		;8b02
	ld b,l			;8b04   ; la X de ventana cabe en un byte porque la ventana mide 256
	ld c,(ix+004h)		;8b05   ; la altura pasa tal cual: el campo no se desplaza en vertical
L_8B08:
	ld (ix+00ah),c		;8b08   ; +0x0A altura y +0x0B ancho, y es lo que leen 0x887D, 0x895D, 0x8A58 y 0x8B4F
	ld (ix+00bh),b		;8b0b
	ret			;8b0e
pon_el_bando_en_treinta_sprites:		; variante de 0x892A con cinco sprites por jugador, la que usa 0x64C7
	ld hl,0e390h		;8b0f   ; 0xE390 es el sprite 0 de la copia: aqui los jugadores empiezan desde el primero
	ld b,01eh		;8b12   ; treinta sprites de los treinta y dos, que son los seis por cinco
L_8B14:
	ld (hl),0e0h		;8b14   ; aparcarlos es dejar su Y en 0xE0
	inc hl			;8b16   ; cuatro incrementos: al sprite siguiente
	inc hl			;8b17
	inc hl			;8b18
	inc hl			;8b19
	djnz L_8B14		;8b1a
	ld hl,0801eh		;8b1c   ; la misma tabla de dibujos que 0x892A
	ld (0e521h),hl		;8b1f
	ld hl,0e390h		;8b22   ; y aqui (0xE523) arranca en el sprite 0, no en el 4
	ld (0e523h),hl		;8b25
	ld a,(0e527h)		;8b28   ; el mismo bando que 0x892A, con su misma paleta
	and a			;8b2b
	jr nz,L_8B38		;8b2c
	ld ix,0e100h		;8b2e
	exx			;8b32
	ld de,0e051h		;8b33
	jr L_8B40		;8b36
L_8B38:
	ld ix,0e1c0h		;8b38
	exx			;8b3c
	ld de,0e056h		;8b3d
L_8B40:
	ld b,006h		;8b40   ; los seis
L_8B42:
	exx			;8b42   ; los doce, de 32 en 32 bytes
	call monta_los_cinco_sprites_de_uno		;8b43
	ld bc,00020h		;8b46
	add ix,bc		;8b49
	exx			;8b4b
	djnz L_8B42		;8b4c
	ret			;8b4e
monta_los_cinco_sprites_de_uno:		; igual que 0x895D pero con cinco sprites y sin parpadeo
	ld a,(ix+00ah)		;8b4f   ; el que no se ve se queda con la Y de 0xE0 que le puso 0x8B0F al limpiar
	cp 0e0h		;8b52
	ret z			;8b54
	ld a,(ix+00ch)		;8b55   ; los dos indices y los dos niveles de tabla, igual que en 0x8976
	ld hl,(0e521h)		;8b58
	ld b,002h		;8b5b
L_8B5D:
	add a,a			;8b5d
	call suma_a_hl		;8b5e
	ld e,(hl)			;8b61
	inc hl			;8b62
	ld d,(hl)			;8b63
	ld a,(ix+00dh)		;8b64
	ex de,hl			;8b67
	djnz L_8B5D		;8b68
	ex de,hl			;8b6a
	ld hl,(0e523h)		;8b6b   ; el primer sprite libre
	ld c,(ix+00ah)		;8b6e   ; la Y y la X de ventana, que 0x6B04 le suma a cada sprite
	ld b,(ix+00bh)		;8b71
	call monta_un_sprite		;8b74   ; cinco llamadas seguidas, una por sprite
	call monta_un_sprite		;8b77
	call monta_un_sprite		;8b7a
	call monta_un_sprite		;8b7d
	call monta_un_sprite		;8b80
	ld (0e523h),hl		;8b83   ; (0xE523) queda apuntando al hueco del jugador siguiente
	ret			;8b86
devuelve_el_fondo_al_mapa:		; vuelve a poner las 3x3 casillas que taparon los parches y vacia los huecos
	ld a,(0e527h)		;8b87   ; el mismo bando que estampo 0x881D
	and a			;8b8a
	jr z,L_8B95		;8b8b
	ld hl,0e480h		;8b8d
	call devuelve_seis_fondos		;8b90
	jr L_8B9B		;8b93
L_8B95:
	ld hl,0e4c2h		;8b95
	call devuelve_seis_fondos		;8b98
L_8B9B:
	ld hl,0e5e0h		;8b9b   ; y detras los dos huecos sueltos, de uno en uno
	exx			;8b9e
	ld b,001h		;8b9f   ; uno solo, que es lo unico que hay en ese hueco
	call devuelve_un_fondo		;8ba1
	ld hl,0e5ebh		;8ba4
	exx			;8ba7
	ld b,001h		;8ba8
	jr devuelve_un_fondo		;8baa
devuelve_seis_fondos:
	exx			;8bac
	ld b,006h		;8bad   ; los seis del bando
devuelve_un_fondo:
	exx			;8baf
	ld e,(hl)			;8bb0   ; los dos primeros bytes del hueco, la direccion del mapa que se tapo
	inc hl			;8bb1
	ld d,(hl)			;8bb2
	ld a,(hl)			;8bb3
	ld (hl),000h		;8bb4   ; el byte alto a cero deja el hueco marcado como gastado
	inc hl			;8bb6
	and a			;8bb7   ; y si ya venia a cero no habia nada guardado
	jr nz,L_8BC3		;8bb8
	ld a,009h		;8bba   ; se salta los nueve bytes de fondo y a por el hueco siguiente
	add a,l			;8bbc
	ld l,a			;8bbd
	jr nc,L_8BC1		;8bbe
	inc h			;8bc0
L_8BC1:
	jr L_8BCC		;8bc1
L_8BC3:
	call copia_las_tres_filas		;8bc3   ; volcar las nueve casillas es exactamente lo mismo que estampar un parche
	ld bc,0004dh		;8bc6   ; el mismo salto de fila del mapa, porque 0x88B9 lo deja a medias
	ex de,hl			;8bc9
	add hl,bc			;8bca
	ex de,hl			;8bcb
L_8BCC:
	exx			;8bcc
	djnz devuelve_un_fondo		;8bcd
	ret			;8bcf
mueve_la_pelota_con_el_que_la_lleva:		; traduce el mando a direccion, avanza la animacion del que corre y le pega la pelota al pie
	ld a,(0e527h)		;8bd0   ; (0xE527) elige de que mando se lee: (0xE007) o (0xE009)
	and a			;8bd3
	ld de,0e007h		;8bd4
	jr z,L_8BDB		;8bd7
	inc de			;8bd9   ; dos bytes mas alla esta el mando del segundo
	inc de			;8bda
L_8BDB:
	ld a,(de)			;8bdb   ; el mando trae los cuatro bits de direccion: 1 arriba, 2 abajo, 4 izquierda y 8 derecha
	and 00fh		;8bdc
	ld hl,0bc97h		;8bde   ; 0xBC97 son dieciseis bytes que convierten esa mascara en una direccion 1..8, en el sentido de las agujas del reloj desde la derecha
	call suma_a_hl		;8be1
	ld a,(hl)			;8be4   ; las combinaciones imposibles, como arriba con abajo, dan 0
	ld (0e53bh),a		;8be5   ; (0xE53B) es la direccion que se acaba de pedir
	ld a,(0e528h)		;8be8   ; (0xE528) a 0xFF es que nadie lleva la pelota, y entonces aqui no hay nada mas que hacer
	inc a			;8beb
	ret z			;8bec
	ld a,(ix+014h)		;8bed   ; +0x14 es la cuenta atras del paso que esta dando; hasta que no se acabe no se cambia de direccion
	and a			;8bf0
	jr z,L_8BF8		;8bf1   ; con la cuenta ya a cero se pasa directo a elegir paso nuevo
	dec a			;8bf3
	ld (ix+014h),a		;8bf4
	ret nz			;8bf7   ; y si aun le queda, se queda con el paso de antes
L_8BF8:
	ld a,(0e53bh)		;8bf8   ; sin direccion pedida el jugador se para
	and a			;8bfb
	jr z,L_8C08		;8bfc   ; sin direccion pedida el jugador se para
	ld (0e53ah),a		;8bfe   ; (0xE53A) es la direccion en la que va de verdad
	ld c,a			;8c01
	ld a,013h		;8c02   ; el 0x13 es el sonido de la carrera
	call pide_un_sonido		;8c04
	ld a,c			;8c07
L_8C08:
	ld (ix+003h),a		;8c08   ; +3 es la direccion en la que se dibuja
	ld c,a			;8c0b
	ld hl,0bca7h		;8c0c   ; 0xBCA7 da lo que dura cada paso: 0x0F para el 1 y el 5, que van de lado, y 0x0A para los otros siete
	call suma_a_hl		;8c0f
	ld b,(hl)			;8c12
	ld (ix+014h),b		;8c13   ; y esa duracion arranca la cuenta atras del paso
	ld a,c			;8c16
	cp 005h		;8c17   ; el 5 y el 1 son la izquierda y la derecha, las dos direcciones con paso largo
	jr z,L_8C23		;8c19
	cp 001h		;8c1b
	jr z,L_8C23		;8c1d
	ld a,b			;8c1f
	ld (ix+001h),a		;8c20   ; a las otras se les copia la duracion tambien en +1

; ----------------------------------------------------------------------
; ----- y la pelota, al pie -----
; ----------------------------------------------------------------------
L_8C23:
	ld a,(0e53ah)		;8c23   ; 0xBCB0 son nueve parejas (dy, dx) con signo, una por direccion
	add a,a			;8c26   ; parejas, asi que la direccion va por dos
	ld hl,0bcb0h		;8c27
	call suma_a_hl		;8c2a
	ld a,(ix+004h)		;8c2d   ; la altura del jugador
	add a,(hl)			;8c30   ; la pelota siempre cae por debajo del jugador: de 0x0A yendo hacia arriba a 0x14 yendo hacia abajo
	ld (0e2a1h),a		;8c31   ; (0xE2A1) es la altura entera de la pelota
	inc hl			;8c34
	ld l,(hl)			;8c35   ; el desplazamiento de ancho, que aqui si lleva signo
	bit 7,l		;8c36   ; y hay que extenderlo a 16 bits a mano
	ld h,000h		;8c38
	jr z,L_8C3D		;8c3a
	dec h			;8c3c
L_8C3D:
	ld e,(ix+006h)		;8c3d   ; el ancho del jugador
	ld d,(ix+007h)		;8c40
	add hl,de			;8c43   ; y se suma al ancho de 16 bits del jugador
	ld (0e2a5h),hl		;8c44   ; (0xE2A5) es el ancho entero de la pelota
	ret			;8c47
arranca_el_cuadro_de_la_pelota:		; pone a cero el dibujo pedido y descuenta (0xE53D) si el estado lo permite
	xor a			;8c48
	ld (0e293h),a		;8c49   ; (0xE293) lo vuelve a poner 0x8F9F con la direccion del que lleva la pelota
	ld a,(0e280h)		;8c4c
	cp 002h		;8c4f   ; en los estados 2 y 3 no se descuenta nada
	jr z,$+23		;8c51   ; los cuatro caminos de aqui saltan al 0x8C68, pasando por encima de los cinco bytes muertos de 0x8C63
	cp 003h		;8c53
	jr z,$+19		;8c55
	ld a,(0e53dh)		;8c57   ; (0xE53D) es una cuenta atras que solo corre fuera de esos dos estados
	and a			;8c5a
	jr z,$+13		;8c5b   ; llegada a cero se queda ahi
	dec a			;8c5d
	ld (0e53dh),a		;8c5e
	jr $+7		;8c61

; ----------------------------------------------------------------------
; DATOS codigo_que_no_se_ejecuta: cinco bytes que ponen 0xFF en (0xE537); los
;   cuatro caminos de L_8C48 pasan por encima
;   0x8c63..0x8c68  (5 bytes)
DATA_codigo_que_no_se_ejecuta:
	defb 03eh	; 8c63
	defb 0ffh	; 8c64
	defb 032h	; 8c65
	defb 037h	; 8c66
	defb 0e5h	; 8c67

; ======================================================================
; CODIGO 0x8c68..0x8c70  (8 bytes)
; ======================================================================


despacha_el_estado_de_la_pelota:		; entra por (0xE280) con (0xE281) en B, para el segundo nivel
	ld bc,(0e280h)		;8c68   ; de una tacada: C = (0xE280) y B = (0xE281), el subestado, que las entradas de la tabla reciben en B
	ld a,c			;8c6c
	call despacha		;8c6d   ; los ocho punteros van pegados detras del `call`

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_8c70: 8 entradas; detras sigue `ld a,(0e280h) / cp
;   005h`
;   0x8c70..0x8c80  (16 bytes)
DATA_tabla_de_subescenas_8c70:
	defw 08ea8h,08f69h,08ffeh,091ach,09f61h,09f15h,09cc0h,09cc0h	; 8c70

; ======================================================================
; CODIGO 0x8c80..0x8eac  (556 bytes)
; ======================================================================


un_cuadro_de_la_pelota:		; la fisica entera: gravedad, avance, camara, coordenadas de pantalla y sprites
	ld a,(0e280h)		;8c80
	cp 005h		;8c83   ; en el estado 5 la pelota no se mueve, solo se redibuja
	jr z,L_8C8D		;8c85
	call tira_de_la_pelota_hacia_abajo		;8c87   ; primero la gravedad...
	call suma_las_velocidades_de_la_pelota		;8c8a   ; ...luego el avance con las velocidades ya corregidas
L_8C8D:
	call arrima_la_camara_a_la_pelota		;8c8d   ; la camara persigue el ancho nuevo de la pelota
	call pasa_la_pelota_a_pantalla		;8c90   ; y con la camara puesta ya se puede pasar a pantalla
	call el_arbitro		;8c93
	ld a,(0e52fh)		;8c96   ; (0xE52E), (0xE52F) y (0xE530) juntos en (0xE54A)
	ld hl,0e530h		;8c99
	or (hl)			;8c9c
	ld hl,0e52eh		;8c9d
	or (hl)			;8ca0
	ld (0e54ah),a		;8ca1
	ld a,(0e532h)		;8ca4
	and a			;8ca7
	jr nz,L_8CAD		;8ca8
	call anima_la_pelota_si_rueda		;8caa   ; con (0xE532) puesto no se cambia de dibujo: la pelota se queda en el que este
L_8CAD:
	jp pon_la_pelota_en_sus_sprites		;8cad   ; y el ultimo paso siempre es dejarla en sus dos sprites
tira_de_la_pelota_hacia_abajo:		; la gravedad, que se suma a la velocidad vertical
	ld hl,(0e2abh)		;8cb0   ; (0xE2AB) velocidad vertical mas (0xE2AD) gravedad
	ld de,(0e2adh)		;8cb3
	add hl,de			;8cb7
	ld (0e2abh),hl		;8cb8
	ret			;8cbb
suma_las_velocidades_de_la_pelota:		; mueve los tres ejes y avisa si ya no le queda vuelo
	ld hl,(0e2a0h)		;8cbc   ; la altura, 8.8: (0xE2A0) mas (0xE2A2)
	ld de,(0e2a2h)		;8cbf
	add hl,de			;8cc3
	ld (0e2a0h),hl		;8cc4
	ld hl,(0e2a4h)		;8cc7   ; el ancho es de 24 bits, asi que la velocidad hay que extenderla con su signo
	ld de,(0e2a7h)		;8cca
	ld a,d			;8cce   ; el bit alto de la velocidad de ancho...
	rla			;8ccf   ; C queda a 0xFF si la velocidad era negativa, para que el acarreo del byte alto salga bien
	ld c,000h		;8cd0   ; ...decide si al byte de arriba hay que restarle uno
	jr nc,L_8CD5		;8cd2
	dec c			;8cd4
L_8CD5:
	add hl,de			;8cd5
	ld (0e2a4h),hl		;8cd6   ; los dos bytes de abajo del ancho
	ld a,(0e2a6h)		;8cd9
	adc a,c			;8cdc   ; y el de arriba con el acarreo que salga
	ld (0e2a6h),a		;8cdd
	ld hl,(0e2a9h)		;8ce0   ; y la altura sobre el suelo, (0xE2A9) mas (0xE2AB)
	ld de,(0e2abh)		;8ce3
	add hl,de			;8ce7
	ld (0e2a9h),hl		;8ce8
	xor a			;8ceb   ; (0xE543) se supone que no
	ld (0e543h),a		;8cec   ; (0xE543) se supone que no
	ld hl,(0e2a9h)		;8cef
	ld a,h			;8cf2   ; si la altura sobre el suelo es negativa la pelota ya paso el suelo
	rla			;8cf3
	ret c			;8cf4
	ld hl,(0e2abh)		;8cf5   ; y si le queda velocidad vertical, tampoco esta quieta
	ld a,h			;8cf8
	or l			;8cf9
	ret nz			;8cfa
	ld a,001h		;8cfb
	ld (0e543h),a		;8cfd   ; solo entonces (0xE543) dice que la pelota va rasa
	ret			;8d00
arrima_la_camara_a_la_pelota:		; mueve la ventana un pixel por cuadro hacia la parada que le toca al ancho de la pelota
	ld a,(0e5c7h)		;8d01   ; con (0xE5C7) puesto la camara no se mueve
	and a			;8d04
	ret nz			;8d05
	ld ix,0bd36h		;8d06   ; 0xBD36 son los umbrales de ancho: 0x00D0, 0x0100, 0x0180, 0x01B0 y 0x0280
	ld de,(0e2a5h)		;8d0a   ; el ancho entero de la pelota es lo que decide
	ld b,007h		;8d0e   ; siete vueltas para cinco umbrales limpios: las dos ultimas ya caen sobre la tabla de detras
	ld c,000h		;8d10
L_8D12:
	ld l,(ix+000h)		;8d12   ; el umbral de esta vuelta
	ld h,(ix+001h)		;8d15
	and a			;8d18
	sbc hl,de		;8d19
	jr nc,L_8D24		;8d1b   ; pasado el umbral, este es el tramo
	inc c			;8d1d   ; C cuenta los umbrales que la pelota ya ha dejado atras: es el tramo en que esta
	inc ix		;8d1e
	inc ix		;8d20
	djnz L_8D12		;8d22
L_8D24:
	ld hl,0bd40h		;8d24   ; 0xBD40 son cinco entradas de tres bytes: 0x0000/0x00, 0x0080/0x10, 0x00C0/0x18, 0x0100/0x20 y 0x0180/0x30
	ld a,c			;8d27
	add a,a			;8d28   ; A por tres, que es lo que ocupa cada entrada
	add a,c			;8d29
	call suma_a_hl		;8d2a
	ld e,(hl)			;8d2d
	inc hl			;8d2e
	ld d,(hl)			;8d2f
	inc hl			;8d30
	ld c,(hl)			;8d31
	ex de,hl			;8d32
	ld (0e2c9h),hl		;8d33   ; (0xE2C9) es a donde tiene que llegar la ventana
	ld a,c			;8d36
	ld (0e2cbh),a		;8d37   ; y (0xE2CB) esa misma parada contada en columnas: la palabra entre ocho
	ld hl,(0e2c3h)		;8d3a   ; el borde izquierdo de ahora
	ld de,(0e2c9h)		;8d3d
	and a			;8d41
	sbc hl,de		;8d42
	jr z,recalcula_los_bordes_de_la_ventana		;8d44   ; ya esta puesta, no hay nada que mover
	jr c,L_8D5E		;8d46   ; pasada de largo: hay que retroceder

; ----------------------------------------------------------------------
; ----- la ventana retrocede un pixel -----
; ----------------------------------------------------------------------
	ld hl,0e2c2h		;8d48
	ld a,(hl)			;8d4b   ; un `ld a,(hl)` seguido de `ld (hl),a` no hace nada: aqui iria el paso fraccionario, que se quedo sin escribir
	ld (hl),a			;8d4c
	inc hl			;8d4d
	ld a,(hl)			;8d4e
	sub 001h		;8d4f   ; de uno en uno, que es lo que hace que el campo se deslice en vez de saltar
	ld (hl),a			;8d51
	inc hl			;8d52
	ld a,(hl)			;8d53
	sbc a,000h		;8d54   ; el byte de arriba solo recoge el prestamo
	ld (hl),a			;8d56
	rla			;8d57   ; si el byte alto se ha puesto negativo es que se paso de cero
	jr nc,recalcula_los_bordes_de_la_ventana		;8d58
	ld c,000h		;8d5a   ; y entonces la ventana se planta en la columna 0
	jr L_8D73		;8d5c

; ----------------------------------------------------------------------
; ----- o avanza un pixel -----
; ----------------------------------------------------------------------
L_8D5E:
	ld hl,0e2c2h		;8d5e
	ld a,(hl)			;8d61
	ld (hl),a			;8d62
	inc hl			;8d63
	ld a,(hl)			;8d64
	add a,001h		;8d65   ; tambien de uno en uno
	ld (hl),a			;8d67
	inc hl			;8d68
	ld a,(hl)			;8d69
	adc a,000h		;8d6a
	ld (hl),a			;8d6c
	cp 003h		;8d6d   ; el tope de arriba: 0x0300, que ya se sale del campo de 640 pixeles
	jr nz,recalcula_los_bordes_de_la_ventana		;8d6f
	ld c,003h		;8d71
L_8D73:
	xor a			;8d73   ; la parte fraccionaria del desplazamiento se pierde al topar
	ld (0e2c2h),a		;8d74
	ld (0e2c3h),a		;8d77
	ld a,c			;8d7a
	ld (0e2c4h),a		;8d7b   ; y el byte alto queda en 0 o en 3 segun por que lado se haya topado
recalcula_los_bordes_de_la_ventana:		; copia el borde izquierdo al derecho sumandole 255 y saca la columna
	ld hl,0e2c2h		;8d7e   ; 0xE2C2 es el desplazamiento con su fraccion, y 0xE2C5 la copia del borde derecho
	ld de,0e2c5h		;8d81
	ld a,(hl)			;8d84   ; la fraccion pasa igual
	ld (de),a			;8d85
	inc de			;8d86
	inc hl			;8d87
	ld a,(hl)			;8d88
	add a,0ffh		;8d89   ; sumarle 0x00FF a los dos bytes altos deja el borde derecho 255 pixeles a la derecha del izquierdo
	ld (de),a			;8d8b
	inc de			;8d8c
	inc hl			;8d8d
	ld a,(hl)			;8d8e
	adc a,000h		;8d8f
	ld (de),a			;8d91
	ld hl,(0e2c3h)		;8d92   ; y (0xE2C1) es esa misma posicion contada en columnas
	ld a,l			;8d95
	and 0f8h		;8d96   ; el `and 0F8h` sobra, porque los tres giros de detras ya tiran esos bits
	srl h		;8d98   ; tres giros con el bit alto arrastrado: entre ocho
	rra			;8d9a
	srl h		;8d9b
	rra			;8d9d
	srl h		;8d9e
	rra			;8da0
	ld (0e2c1h),a		;8da1
	ret			;8da4
pasa_la_pelota_a_pantalla:		; resta la altura sobre el suelo y el desplazamiento de la ventana
	ld hl,(0e2a0h)		;8da5   ; la altura de la pelota
	ld de,(0e2a9h)		;8da8   ; menos lo que se ha elevado del suelo: por eso al botar sube por la pantalla
	and a			;8dac
	sbc hl,de		;8dad
	ld a,h			;8daf   ; de la resta en 8.8 solo interesa la parte entera
	ld (0e2afh),a		;8db0   ; (0xE2AF) es la fila en que se dibuja la pelota
	ld de,0e2a4h		;8db3   ; y el ancho, menos el borde izquierdo de la ventana
	ld hl,0e2c2h		;8db6
	ld a,(de)			;8db9
	sub (hl)			;8dba   ; la resta empieza por las dos fracciones, para que el prestamo salga bien
	inc hl			;8dbb
	inc de			;8dbc
	ld a,(de)			;8dbd
	sbc a,(hl)			;8dbe
	ld (0e2b0h),a		;8dbf   ; (0xE2B0) es su columna en pantalla, que cabe en un byte porque la ventana mide 256
	ret			;8dc2
anima_la_pelota_si_rueda:		; con las tres velocidades a cero la pelota se queda en el dibujo que tenga
	ld hl,(0e2a7h)		;8dc3   ; velocidad de ancho
	ld a,h			;8dc6
	or l			;8dc7
	ld hl,(0e2a2h)		;8dc8   ; de altura
	or h			;8dcb
	or l			;8dcc
	ld hl,(0e2abh)		;8dcd   ; y vertical: si las tres son cero, la pelota esta parada
	or h			;8dd0
	or l			;8dd1
	ret z			;8dd2
cambia_el_dibujo_de_la_pelota:		; tres dibujos que giran, uno cada cuatro cuadros
	ld hl,0e29ah		;8dd3
	inc (hl)			;8dd6   ; (0xE29A) es el contador de la animacion
	ld a,(hl)			;8dd7
	and 00ch		;8dd8   ; los bits 2 y 3: cambia de dibujo cada cuatro cuadros
	rra			;8dda
	rra			;8ddb
	cp 003h		;8ddc   ; son tres dibujos, asi que el cuarto no llega a salir
	jr nz,L_8DE2		;8dde
	xor a			;8de0   ; al llegar al cuarto el contador vuelve a cero
	ld (hl),a			;8de1
L_8DE2:
	and a			;8de2
	ld hl,0c4c0h		;8de3   ; cada palabra son los dos dibujos de la pareja de sprites que forma la pelota
	jr z,L_8DF1		;8de6
	dec a			;8de8
	ld hl,0f0e8h		;8de9
	jr z,L_8DF1		;8dec
	ld hl,0ece4h		;8dee
L_8DF1:
	ld a,l			;8df1
	ld (0e2b3h),a		;8df2   ; (0xE2B3) el dibujo del primero, con su color en (0xE2B4)
	ld a,h			;8df5
	ld (0e2b5h),a		;8df6   ; y (0xE2B5) el del segundo
	ret			;8df9
pon_la_pelota_en_sus_sprites:		; la pelota va delante de los jugadores, salvo si el que la lleva corre de espaldas
	ld hl,(0e2afh)		;8dfa   ; (0xE2AF) y (0xE2B0) de una vez: la fila y la columna en pantalla
	ld a,(0e293h)		;8dfd   ; 7 es la direccion "arriba", o sea que el jugador se aleja
	cp 007h		;8e00
	ld a,0e0h		;8e02   ; el 0xE0 con el que se aparca el sprite que sobre
	jr nz,L_8E1C		;8e04
	ld (0e404h),hl		;8e06   ; entonces la pelota se va a los sprites 28 y 29, detras de todos los jugadores
	ld (0e400h),hl		;8e09
	ld (0e390h),a		;8e0c   ; y el sprite 0 se aparca
	ld hl,(0e2b3h)		;8e0f   ; el dibujo y el color van pegados a la posicion, en los dos bytes de detras
	ld (0e402h),hl		;8e12
	ld hl,(0e2b5h)		;8e15
	ld (0e406h),hl		;8e18
	ret			;8e1b
L_8E1C:
	ld (0e390h),hl		;8e1c   ; y si no, la pelota es el sprite 0, delante de todo
	ld (0e404h),hl		;8e1f
	ld (0e400h),a		;8e22   ; y el 28 el que se aparca
	ld hl,(0e2b3h)		;8e25
	ld (0e392h),hl		;8e28
	ld hl,(0e2b5h)		;8e2b
	ld (0e406h),hl		;8e2e
	ret			;8e31
planta_la_camara_en_la_pelota:		; la misma cuenta de tramos de 0x8D01, pero saltando la ventana de golpe
	ld ix,0bd36h		;8e32   ; tramos y paradas, igual que en 0x8D01
	ld de,(0e2a5h)		;8e36
	ld b,007h		;8e3a
	ld c,000h		;8e3c
L_8E3E:
	ld l,(ix+000h)		;8e3e   ; se recorre la tabla hasta pasarse del valor buscado
	ld h,(ix+001h)		;8e41
	and a			;8e44
	sbc hl,de		;8e45
	jr nc,L_8E50		;8e47
	inc c			;8e49
	inc ix		;8e4a
	inc ix		;8e4c
	djnz L_8E3E		;8e4e
L_8E50:
	ld hl,0bd40h		;8e50   ; y el indice que salga, por tres: las entradas de 0xBD40 son de tres bytes
	ld a,c			;8e53
	add a,a			;8e54
	add a,c			;8e55
	call suma_a_hl		;8e56
	ld e,(hl)			;8e59
	inc hl			;8e5a
	ld d,(hl)			;8e5b
	inc hl			;8e5c
	ld c,(hl)			;8e5d
	ex de,hl			;8e5e
	ld (0e2c9h),hl		;8e5f
	ld a,c			;8e62
	ld (0e2cbh),a		;8e63
	ld a,(0e2a4h)		;8e66   ; la fraccion se copia de la pelota, para que no quede un pixel colgando
	ld (0e2c2h),a		;8e69
	ld (0e2c3h),hl		;8e6c   ; y el borde izquierdo se pone donde diga la parada, sin ir andando
	jp recalcula_los_bordes_de_la_ventana		;8e6f   ; queda recalcular el borde derecho y la columna
pon_la_sombra_de_la_pelota:		; la sombra usa la altura de la pelota SIN restarle el vuelo, asi que se queda en el suelo
	ld a,(0e2a1h)		;8e72   ; (0xE2A1) es la altura entera, sin descontar lo que la pelota se ha elevado
	ld l,a			;8e75
	ld a,(0e2b0h)		;8e76   ; la columna si es la misma que la de la pelota
	ld h,a			;8e79
	ld (0e2b1h),hl		;8e7a   ; (0xE2B1) y (0xE2B2) son la sombra en pantalla
	ld a,(0e280h)		;8e7d
	and a			;8e80
	jr nz,L_8E99		;8e81
	ld a,(0e281h)		;8e83
	cp 001h		;8e86
	jr nz,L_8E99		;8e88
	ld (0e394h),hl		;8e8a   ; en el subestado 1 del estado 0 la sombra es el sprite 1, justo detras de la pelota
	ld hl,(0e2b7h)		;8e8d   ; (0xE2B7) es el dibujo y el color de la sombra
	ld (0e396h),hl		;8e90
	ld a,0e0h		;8e93   ; y el 30 se aparca
	ld (0e408h),a		;8e95
	ret			;8e98
L_8E99:
	ld (0e408h),hl		;8e99   ; el resto del tiempo va al sprite 30, con los jugadores por delante
	ld hl,(0e2b7h)		;8e9c
	ld (0e40ah),hl		;8e9f
	ld a,0e0h		;8ea2
	ld (0e394h),a		;8ea4
	ret			;8ea7
despacha_el_bote:		; entra por (0xE281), que 0x8C68 traia en B
	ld a,b			;8ea8   ; los cuatro punteros van pegados detras
	call despacha		;8ea9

; ----------------------------------------------------------------------
; DATOS pasos_del_bote_de_la_pelota: 4 entradas, repartidas por (0xE281) desde
;   0x8EA9. Es la entrada 0 de la tabla de 0x8C70, o sea el subestado 0: la
;   pelota suelta, botando
;   0x8eac..0x8eb4  (8 bytes)
DATA_pasos_del_bote_de_la_pelota:
	defw 08eb4h,08eb5h,08edah,08f30h	; 8eac  -> no_hay_bote_que_hacer espera_a_que_la_pelota_caiga bota_la_pelota espera_a_que_la_pelota_se_pare

; ======================================================================
; CODIGO 0x8eb4..0x8fee  (314 bytes)
; ======================================================================


no_hay_bote_que_hacer:
	ret			;8eb4
espera_a_que_la_pelota_caiga:		; apunta el punto mas alto del vuelo y pasa al bote cuando la pelota cruza el suelo
	ld a,(0e2ach)		;8eb5   ; el byte alto de la velocidad vertical
	rla			;8eb8   ; con el bit de signo puesto, la pelota ya esta bajando
	jr nc,L_8EC7		;8eb9
	ld a,(0e54bh)		;8ebb   ; y solo la primera vez que baja
	and a			;8ebe
	jr nz,L_8EC7		;8ebf
	ld a,(0e2aah)		;8ec1   ; (0xE54B) se queda con lo alto que llego, que es lo que decidira la fuerza del bote
	ld (0e54bh),a		;8ec4
L_8EC7:
	ld hl,(0e2a9h)		;8ec7   ; la altura sobre el suelo
	ld a,h			;8eca
	rla			;8ecb
	ret nc			;8ecc   ; mientras no se vuelva negativa la pelota sigue en el aire
	ld hl,0e281h		;8ecd   ; al tocar suelo, al subestado siguiente
	inc (hl)			;8ed0
	xor a			;8ed1
	ld (0e282h),a		;8ed2   ; y el contador del bote arranca de cero
	ld h,a			;8ed5
	ld l,a			;8ed6
	jp baja_la_pelota_al_suelo		;8ed7   ; y de paso se le quita todo el vuelo
bota_la_pelota:		; dos botes de ocho cuadros con una curva de velocidad de tabla, y en cada uno la pelota pierde la mitad de carrera
	ld hl,0e282h		;8eda   ; (0xE282) cuenta los cuadros de los dos botes
	inc (hl)			;8edd
	ld a,(hl)			;8ede
	cp 010h		;8edf   ; dieciseis cuadros: dos botes de ocho
	jr z,cierra_los_botes		;8ee1
	and 007h		;8ee3   ; dentro de cada bote se cuenta de 0 a 7
	ld c,a			;8ee5
	dec a			;8ee6   ; el cuadro 1 de cada bote es el golpe contra el cesped
	jr nz,L_8F00		;8ee7
	ld hl,(0e2a2h)		;8ee9   ; y ahi la carrera se parte por la mitad
	call parte_la_velocidad_por_dos		;8eec
	ld (0e2a2h),hl		;8eef
	ld hl,(0e2a7h)		;8ef2   ; tanto la de altura como la de ancho
	call parte_la_velocidad_por_dos		;8ef5
	ld (0e2a7h),hl		;8ef8
	ld a,011h		;8efb   ; el 0x11 es el sonido del bote
	call pide_un_sonido		;8efd
L_8F00:
	ld a,(0e54bh)		;8f00   ; si el vuelo del que venia no paso de 0x10, el bote es el flojo
	cp 010h		;8f03
	ld hl,0bd5fh		;8f05   ; 0xBD5F: 0, +0x10, +0x0C, +0x08, 0, -0x08, -0x0C, -0x10
	jr c,L_8F0D		;8f08
	ld hl,0bd4fh		;8f0a   ; y 0xBD4F el fuerte: 0, +0x20, +0x18, +0x10, 0, -0x10, -0x18, -0x20
L_8F0D:
	ld b,000h		;8f0d
	add hl,bc			;8f0f
	ld l,(hl)			;8f10   ; el byte de la curva, que va con signo
	ld h,b			;8f11
	bit 7,l		;8f12   ; y se extiende a 16 bits a mano
	jr z,L_8F17		;8f14
	dec h			;8f16
L_8F17:
	add hl,hl			;8f17   ; cuatro `add hl,hl`: el byte por dieciseis es la velocidad vertical de este cuadro
	add hl,hl			;8f18
	add hl,hl			;8f19
	add hl,hl			;8f1a
	ld (0e2abh),hl		;8f1b   ; y con ella el bote sube y baja solo
	ret			;8f1e
cierra_los_botes:
	xor a			;8f1f
	ld (0e54fh),a		;8f20
	ld l,a			;8f23
	ld h,a			;8f24
	ld (0e2abh),hl		;8f25   ; sin velocidad vertical, la pelota se queda donde caiga
	ld (0e54bh),a		;8f28   ; y la marca del punto mas alto se borra para el bote siguiente
	ld hl,0e281h		;8f2b   ; y al subestado siguiente, que es la espera de 0x8F30
	inc (hl)			;8f2e
	ret			;8f2f
espera_a_que_la_pelota_se_pare:		; 0x18 cuadros de margen y a la pelota se le borra todo
	ld hl,0e282h		;8f30
	inc (hl)			;8f33
	ld a,(hl)			;8f34
	cp 018h		;8f35   ; veinticuatro cuadros
	ret c			;8f37
	xor a			;8f38
	ld (0e281h),a		;8f39   ; (0xE281) vuelve al subestado 0
	jr borra_las_marcas_de_la_pelota		;8f3c
para_la_pelota_y_al_jugador:
	xor a			;8f3e
	ld (ix+014h),a		;8f3f   ; y de paso le corta el paso que estuviera dando al jugador de IX
	ld (0e282h),a		;8f42
borra_las_marcas_de_la_pelota:
	xor a			;8f45
	ld (0e540h),a		;8f46
	ld (0e299h),a		;8f49
	ld (0e547h),a		;8f4c
para_la_pelota:		; deja las velocidades de altura y ancho a cero
	ld hl,00000h		;8f4f   ; cae en 0x8F58, que borra tambien el vuelo
	ld (0e2a2h),hl		;8f52
	ld (0e2a7h),hl		;8f55
baja_la_pelota_al_suelo:		; velocidad vertical, altura sobre el suelo y gravedad a cero, y calla el sonido
	ld (0e2abh),hl		;8f58
	ld (0e2a9h),hl		;8f5b   ; la pelota vuelve al cesped
	ld (0e2adh),hl		;8f5e   ; sin gravedad tampoco volvera a caer sola
	jp apaga_el_sonido_de_la_pelota		;8f61   ; y el silbido de la pelota en el aire se apaga
parte_la_velocidad_por_dos:		; HL entre dos, arrastrando el signo
	sra h		;8f64   ; `sra` en el byte alto conserva el signo
	rr l		;8f66
	ret			;8f68
empuja_la_pelota_al_regatear:		; le da a la pelota la velocidad que le toca por la direccion y el momento del paso del que la lleva
	ld a,(0e547h)		;8f69   ; con (0xE547) puesto la pelota no corre: se le cuentan ocho cuadros y se la deja quieta
	and a			;8f6c
	jr z,L_8F82		;8f6d
	ld hl,00000h		;8f6f   ; las dos velocidades a cero
	ld (0e2a2h),hl		;8f72
	ld (0e2a7h),hl		;8f75
	ld hl,0e548h		;8f78   ; (0xE548) es esa cuenta de ocho
	inc (hl)			;8f7b
	ld a,(hl)			;8f7c
	cp 008h		;8f7d   ; ocho cuadros, y (0xE548) vuelve a empezar
	ret nz			;8f7f
	ld (hl),000h		;8f80
L_8F82:
	ld a,(0e528h)		;8f82   ; el 0xFF de "nadie la lleva" tiene el bit alto puesto
	and a			;8f85
	ret m			;8f86
	call L_A201		;8f87   ; IX a la ficha del que la lleva
	push ix		;8f8a
	call pase_o_tiro		;8f8c   ; IX no sobrevive a esta llamada, asi que se aparca
	pop ix		;8f8f
	ld a,(0e280h)		;8f91
	and a			;8f94   ; fuera del partido la pelota no se empuja
	ret z			;8f95
	ld a,(ix+003h)		;8f96   ; +3 es la direccion en la que se dibuja...
	and a			;8f99
	jr nz,L_8F9F		;8f9a
	ld a,(0e53ah)		;8f9c   ; ...y si esta a cero se coge la que lleva de verdad, (0xE53A)
L_8F9F:
	ld (0e293h),a		;8f9f   ; (0xE293) es la direccion que luego mira 0x8DFD para decidir si la pelota va delante o detras
	ld hl,l8fech		;8fa2   ; OJO: la base es 0x8FEC, dos bytes antes de la tabla, porque la direccion 0 ya se ha desviado
	add a,a			;8fa5   ; palabras, asi que la direccion va por dos
	jr z,deja_la_pelota_quieta		;8fa6   ; sin direccion la pelota se para
	call suma_a_hl		;8fa8   ; la tabla lleva a uno de los ocho grupos de 0xBCC2..0xBD35
	ld e,(hl)			;8fab
	inc hl			;8fac
	ld d,(hl)			;8fad
	ex de,hl			;8fae
	ld a,(ix+014h)		;8faf   ; +0x14 es lo que le queda al paso que esta dando
	sub 005h		;8fb2   ; por debajo de 5 el jugador ya no empuja
	jr c,deja_la_pelota_quieta		;8fb4
	add a,a			;8fb6   ; parejas, asi que por dos; a los grupos de 1 y 5 les hacen falta once y a los otros seis
	call suma_a_hl		;8fb7
	ld e,(hl)			;8fba   ; el primer byte de la pareja es la velocidad de altura
	ld d,000h		;8fbb
	ld b,d			;8fbd
	bit 7,e		;8fbe   ; con su signo extendido a mano
	jr z,L_8FC3		;8fc0
	dec d			;8fc2
L_8FC3:
	inc hl			;8fc3
	ld c,(hl)			;8fc4   ; y el segundo la de ancho, tambien con signo
	bit 7,c		;8fc5
	jr z,L_8FCA		;8fc7
	dec b			;8fc9
L_8FCA:
	ex de,hl			;8fca
	add hl,hl			;8fcb   ; cuatro `add hl,hl`: la velocidad de altura por dieciseis
	add hl,hl			;8fcc
	add hl,hl			;8fcd
	add hl,hl			;8fce
	ex de,hl			;8fcf
	ld a,c			;8fd0
	add a,a			;8fd1   ; y lo mismo para la de ancho, a mano porque va en BC
	rl b		;8fd2
	add a,a			;8fd4
	rl b		;8fd5
	add a,a			;8fd7
	rl b		;8fd8
	add a,a			;8fda
	rl b		;8fdb
	ld c,a			;8fdd
guarda_las_dos_velocidades:
	ld (0e2a2h),de		;8fde   ; (0xE2A2) mueve la altura...
	ld (0e2a7h),bc		;8fe2   ; ...y (0xE2A7) el ancho
	ret			;8fe6
deja_la_pelota_quieta:
	ld de,00000h		;8fe7   ; las dos velocidades a cero, y por el mismo sitio
	ld c,e			;8fea
	ld b,d			;8feb
L_8FEC:
	jr guarda_las_dos_velocidades		;8fec

; ----------------------------------------------------------------------
; DATOS vectores_de_empuje_por_direccion: ocho palabras a los grupos de
;   vectores de 0xBCC2..0xBD35, indexadas por la direccion del jugador; la
;   carga 0x8FA2 con la base en 0x8FEC, una entrada mas abajo
;   0x8fee..0x8ffe  (16 bytes)
DATA_vectores_de_empuje_por_direccion:
	defw 0bcc2h,0bcd8h,0bce4h,0bcf0h,0bcfch,0bd12h,0bd1eh,0bd2ah	; 8fee

; ======================================================================
; CODIGO 0x8ffe..0x9002  (4 bytes)
; ======================================================================


L_8FFE:
	ld a,b			;8ffe
	call despacha		;8fff

; ----------------------------------------------------------------------
; DATOS pasos_del_saque_de_banda: 9 entradas, repartidas por (0xE281) desde
;   0x8FFF. Es la entrada 2 de la tabla de 0x8C70, el subestado del saque de
;   banda, en el que la pelota va rasa
;   0x9002..0x9014  (18 bytes)
DATA_pasos_del_saque_de_banda:
	defw 09014h,09045h,0907dh,090b4h,090deh,09107h,09129h,09130h	; 9002
	defw 09171h	; 9012  -> golpea_la_pelota

; ======================================================================
; CODIGO 0x9014..0x91b0  (412 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL JUGADOR QUE VA A POR LA PELOTA =====
; ----------------------------------------------------------------------
elige_por_donde_ir_a_la_pelota:
	ld a,(0e537h)		;9014   ; (0xE537) es el jugador que lleva la jugada
	and a			;9017
	ret m			;9018   ; con el bit 7 puesto no hay ninguno, y no hay nada que mover
	call L_A201		;9019   ; IX a su ficha
	ld (0e538h),hl		;901c   ; y el puntero queda a mano en (0xE538), que es de donde lo cogen las demas
	ld a,(0e2a1h)		;901f   ; la altura de la pelota
	sub 010h		;9022   ; menos 0x10, que es lo que el jugador levanta el pie
	ld ix,(0e538h)		;9024
	cp (ix+004h)		;9028   ; contra la altura del jugador
	jr z,L_9034		;902b   ; a la misma altura, ya solo falta acercarse a lo ancho
	ld c,001h		;902d   ; la pelota esta mas alta: subestado 1
	jr nc,L_9043		;902f
	inc c			;9031   ; y mas baja: subestado 2
	jr L_9043		;9032
L_9034:
	ld de,00000h		;9034   ; sin desvio
	call distancia_a_la_pelota		;9037   ; la distancia a lo ancho
	ld c,005h		;903a   ; justo encima: subestado 5, el de controlarla
	jr z,L_9043		;903c
	ld c,004h		;903e   ; a un lado: subestado 4
	jr nc,L_9043		;9040
	dec c			;9042   ; y al otro: el 3
L_9043:
	jr L_907A		;9043
sube_hacia_la_pelota:
	ld a,(0e2a1h)		;9045
	sub 010h		;9048   ; la altura de la pelota, con la misma correccion
	ld ix,(0e538h)		;904a
	cp (ix+004h)		;904e   ; contra la del jugador
	jr nc,L_9058		;9051   ; si ya la ha alcanzado
	ld (ix+004h),a		;9053   ; se ajusta a ella de golpe y se pasa a acercarse de lado
	jr L_906B		;9056
L_9058:
	ld a,(ix+004h)		;9058
	add a,002h		;905b   ; dos pixeles por cuadro
	ld (ix+004h),a		;905d
	call dibujo_de_correr		;9060   ; con el dibujo de correr
	ld a,003h		;9063   ; y el modo 3, que es el de subir
	ld (ix+00ch),a		;9065
	jp suena_el_paso		;9068   ; y los pasos, que suenan cada ocho cuadros

; ----------------------------------------------------------------------
; ===== ACERCARSE A LA PELOTA: las cuatro puertas =====
; ----------------------------------------------------------------------
L_906B:
	ld de,00000h		;906b   ; puesto a la altura, se mide el ancho y se salta al paso que toque
	call distancia_a_la_pelota		;906e
	ld c,004h		;9071
	jr z,L_907A		;9073
	ld c,003h		;9075
	jr nc,L_907A		;9077
	dec c			;9079
L_907A:
	jp L_9D26		;907a
baja_hacia_la_pelota:
	ld a,(0e2a1h)		;907d   ; bajar hacia la pelota: la altura de la pelota menos 0x10 es el sitio
	sub 010h		;9080
	ld ix,(0e538h)		;9082
	cp (ix+004h)		;9086   ; pasandose, se clava en ella
	jr c,L_9090		;9089
	ld (ix+004h),a		;908b
	jr L_90A3		;908e
L_9090:
	ld a,(ix+004h)		;9090
	sub 002h		;9093   ; dos pixeles, aqui hacia abajo
	ld (ix+004h),a		;9095
	call dibujo_de_correr		;9098
	ld a,007h		;909b   ; y el modo 7, el contrario del 3
	ld (ix+00ch),a		;909d
	jp suena_el_paso		;90a0
L_90A3:
	ld de,00000h		;90a3   ; y ya a la altura, otra vez el ancho
	call distancia_a_la_pelota		;90a6
	ld c,003h		;90a9
	jr z,L_90B2		;90ab
	ld c,002h		;90ad
	jr nc,L_90B2		;90af
	dec c			;90b1
L_90B2:
	jr L_907A		;90b2
acercate_por_un_lado:
	ld de,00000h		;90b4
	call distancia_a_la_pelota		;90b7   ; la distancia a lo ancho
	jr c,L_90C7		;90ba   ; con la pelota ya pasada...
	ld hl,(0e2a5h)		;90bc   ; ...el jugador se planta justo en su vertical
	ld (ix+006h),l		;90bf
	ld (ix+007h),h		;90c2
	jr L_90D8		;90c5
L_90C7:
	call un_pixel_atras		;90c7   ; y si no, dos pixeles hacia ella: dos llamadas de un pixel
	call un_pixel_atras		;90ca
	call dibujo_de_correr		;90cd
	ld a,005h		;90d0   ; el modo 5
	ld (ix+00ch),a		;90d2
	jp suena_el_paso		;90d5
L_90D8:
	ld hl,0e281h		;90d8
	inc (hl)			;90db   ; y el subestado sube DOS: se salta el de acercarse por el otro lado
	inc (hl)			;90dc
	ret			;90dd
acercate_por_el_otro_lado:
	ld de,00000h		;90de   ; acercarse por el otro lado: aqui la comparacion va al reves
	call distancia_a_la_pelota		;90e1
	jr nc,L_90F1		;90e4
	ld hl,(0e2a5h)		;90e6   ; con la pelota ya pasada, el jugador se planta en su vertical
	ld (ix+006h),l		;90e9
	ld (ix+007h),h		;90ec
	jr L_9102		;90ef
L_90F1:
	call un_pixel_adelante		;90f1   ; aqui los dos pixeles van al reves
	call un_pixel_adelante		;90f4
	call dibujo_de_correr		;90f7
	ld a,001h		;90fa   ; y el modo 1, el contrario del 5
	ld (ix+00ch),a		;90fc
	jp suena_el_paso		;90ff
L_9102:
	ld hl,0e281h		;9102
	inc (hl)			;9105   ; este sube solo uno
	ret			;9106
la_tiene_controlada:
	ld ix,(0e538h)		;9107
	ld a,(0e533h)		;910b   ; (0xE533) elige entre los dos dibujos de tener la pelota
	dec a			;910e
	ld a,005h		;910f
	jr z,L_9114		;9111
	inc a			;9113
L_9114:
	ld (ix+00dh),a		;9114   ; el dibujo, a la ficha
	ld hl,01800h		;9117   ; la pelota se pega a 0x18 de altura: en el pie
	ld (0e2a9h),hl		;911a
	ld hl,0e281h		;911d
	ld a,(0e527h)		;9120   ; (0xE527) es el bando; el otro se salta un subestado
	and a			;9123
	jr z,L_9127		;9124
	inc (hl)			;9126
L_9127:
	inc (hl)			;9127   ; y el que toca, uno
	ret			;9128
suelta_con_el_mando_1:
	ld de,0e006h		;9129   ; el mando 1
	ld b,000h		;912c   ; y su numero de bando, el 0
	jr L_9135		;912e
suelta_con_el_mando_2:
	ld de,0e008h		;9130   ; el mando 2
	ld b,001h		;9133   ; y el bando 1
L_9135:
	ld ix,(0e538h)		;9135
	ld a,(0e533h)		;9139   ; el mismo par de dibujos de tener la pelota
	dec a			;913c
	ld a,005h		;913d
	jr z,L_9142		;913f
	inc a			;9141
L_9142:
	ld (ix+00dh),a		;9142
	ld hl,0e2f0h		;9145   ; (0xE2F0) cuenta los cuadros que lleva sujetandola
	inc (hl)			;9148
	jr z,L_915F		;9149   ; al desbordar, se suelta sola: no se puede tener eternamente
	bit 0,b		;914b
	jr z,L_915B		;914d   ; solo al segundo mando se le aplica el limite corto
	ld a,(0e002h)		;914f
	bit 5,a		;9152   ; y solo si no hay un humano detras
	jr nz,L_915B		;9154
	ld a,(hl)			;9156
	cp 030h		;9157   ; 0x30 cuadros: la maquina no se entretiene
	jr z,L_915F		;9159
L_915B:
	ld a,(de)			;915b
	and 010h		;915c   ; el bit 4 del mando es el disparo
	ret z			;915e   ; sin pulsar, sigue con ella
L_915F:
	xor a			;915f
	ld (0e2f0h),a		;9160   ; la cuenta se rearma
	ld a,008h		;9163   ; subestado 8: el golpeo
	ld (0e281h),a		;9165
	ld a,b			;9168
	ld (0e283h),a		;9169   ; con el bando que ha golpeado apuntado
	ld a,04fh		;916c   ; y el 0x4F, que es el chut
	jp pide_un_sonido		;916e
golpea_la_pelota:
	ld ix,(0e538h)		;9171
	ld iy,(0e28dh)		;9175   ; (0xE28D) trae la segunda ficha que interviene
	call mide_y_convierte		;9179
	xor a			;917c
	ld (0e284h),a		;917d   ; (0xE284) a cero
	ld a,003h		;9180   ; el 3 es el impacto
	call pide_un_sonido		;9182
	ld hl,00100h		;9185   ; (0xE280) vuelve a 1 y (0xE281) a 0: se reinicia la maquina de estados
	ld (0e280h),hl		;9188
	ld a,020h		;918b   ; y 0x20 cuadros de gracia antes de que nadie pueda volver a tocarla
	ld (0e544h),a		;918d
pon_el_modo_del_golpeo:
	ld ix,(0e538h)		;9190
	ld a,(0e533h)		;9194   ; (0xE533) separa los dos tipos de golpeo
	dec a			;9197
	ld a,003h		;9198
	jr z,L_919E		;919a
	ld a,007h		;919c
L_919E:
	ld (ix+00ch),a		;919e
	ld (ix+00dh),001h		;91a1   ; el dibujo 1
	ld (ix+002h),008h		;91a5   ; y el +2 a 8
	jp L_9E27		;91a9
L_91AC:
	ld a,b			;91ac
	call despacha		;91ad

; ----------------------------------------------------------------------
; DATOS los_once_pasos_del_saque_del_primer_bando: 11 entradas, repartidas por
;   (0xE281) desde 0x91AD. Es la entrada 3 de la tabla de 0x8C70. Comparte
;   cuerpo con la de 0x9F65: colocarse, andar, esperar el boton, la carrerilla
;   y el golpeo
;   0x91b0..0x91c6  (22 bytes)
DATA_los_once_pasos_del_saque_del_primer_bando:
	defw 091c6h,091cbh,091d0h,091d5h,091dah,091dfh,091e2h,091f1h	; 91b0
	defw 09216h,09225h,09249h	; 91c0  -> prepara_la_carrerilla_atras carrerilla_hacia_atras L_9249

; ======================================================================
; CODIGO 0x91c6..0x93ed  (551 bytes)
; ======================================================================


L_91C6:
	ld e,005h		;91c6
	jp L_9CC1		;91c8
L_91CB:
	ld e,005h		;91cb
	jp L_9CF2		;91cd
L_91D0:
	ld e,005h		;91d0
	jp L_9D2D		;91d2
L_91D5:
	ld e,005h		;91d5
	jp L_9D63		;91d7
L_91DA:
	ld e,005h		;91da
	jp L_9D81		;91dc
L_91DF:
	jp L_9D9E		;91df
L_91E2:
	ld ix,(0e538h)		;91e2
	ld (ix+00ch),001h		;91e6
	ld (ix+00dh),000h		;91ea
	jp L_9DAF		;91ee
carrerilla_hacia_adelante:		; dieciseis cuadros corriendo, y al final el golpe
	ld ix,(0e538h)		;91f1
	ld hl,0e54eh		;91f5   ; (0xE54E) cuenta los cuadros de la carrerilla
	inc (hl)			;91f8
	ld a,(hl)			;91f9
	cp 010h		;91fa   ; dieciseis cuadros dura
	jr z,L_9209		;91fc
	call un_pixel_adelante		;91fe   ; mientras, un pixel por cuadro
	call dibujo_de_correr		;9201   ; con las piernas moviendose
	ld (ix+00ch),001h		;9204   ; y el modo 1
	ret			;9208
L_9209:
	ld (hl),000h		;9209   ; cumplidos los dieciseis, la cuenta se rearma
	ld a,057h		;920b   ; el 0x57 es el golpe
	call pide_un_sonido		;920d
	ld a,00ah		;9210
	ld (0e281h),a		;9212   ; y el subestado 10, que es el que lo resuelve
	ret			;9215
prepara_la_carrerilla_atras:
	ld ix,(0e538h)		;9216
	ld (ix+00ch),005h		;921a   ; el modo 5, el contrario del 1
	ld (ix+00dh),000h		;921e
	jp L_9DB6		;9222
carrerilla_hacia_atras:
	ld ix,(0e538h)		;9225
	ld hl,0e54eh		;9229
	inc (hl)			;922c
	ld a,(hl)			;922d
	cp 010h		;922e
	jr z,L_923D		;9230
	call un_pixel_atras		;9232   ; aqui el pixel va al otro lado
	call dibujo_de_correr		;9235
	ld (ix+00ch),005h		;9238
	ret			;923c
L_923D:
	ld (hl),000h		;923d
	ld a,057h		;923f
	call pide_un_sonido		;9241
	ld hl,0e281h		;9244
	inc (hl)			;9247   ; y el subestado sube de uno en uno
	ret			;9248
L_9249:
	jp L_9DEB		;9249

; ----------------------------------------------------------------------
; ===== LA PUNTERIA DE LA MAQUINA =====
; ----------------------------------------------------------------------
mide_hasta_el_objetivo:		; saca las dos distancias entre IX y IY, con anticipacion si el nivel es alto
	xor a			;924c   ; (0xE284) es donde se apuntan los dos signos
	ld (0e284h),a		;924d
	ld e,(iy+004h)		;9250   ; la altura del objetivo
	ld a,(0e540h)		;9253   ; (0xE540) distinto de cero: no se anticipa
	and a			;9256
	jr nz,L_9273		;9257
	ld a,(0e002h)		;9259   ; el bit 5 de (0xE002): con dos jugadores humanos tampoco
	and 020h		;925c
	jr nz,L_9273		;925e
	ld a,(0e069h)		;9260   ; y el nivel de juego...
	cp 004h		;9263   ; ...que ha de ser 4 o mas: por debajo, la maquina apunta a donde ESTA el objetivo
	jr c,L_9273		;9265
	ld a,(iy+003h)		;9267   ; el modo en que se mueve el objetivo
	ld hl,093edh		;926a   ; y la tabla dice cuanto se adelanta en altura
	call suma_a_hl		;926d
	ld a,(hl)			;9270
	add a,e			;9271   ; que se suma a donde estara
	ld e,a			;9272
L_9273:
	ld a,(ix+004h)		;9273   ; la altura del jugador
	sub e			;9276   ; menos la del objetivo
	ld (0e285h),a		;9277   ; la diferencia con signo, a (0xE285)
	jr nc,L_9283		;927a
	ld hl,0e284h		;927c
	set 0,(hl)		;927f   ; el bit 0 apunta que el objetivo queda por encima
	neg		;9281   ; y la distancia se queda en valor absoluto
L_9283:
	ld (0e286h),a		;9283
	ld e,(iy+006h)		;9286   ; ahora lo ancho, que va en 16 bits
	ld d,(iy+007h)		;9289
	ld a,(0e540h)		;928c   ; las mismas tres condiciones que arriba
	and a			;928f
	jr nz,L_92B8		;9290
	ld a,(0e002h)		;9292
	and 020h		;9295
	jr nz,L_92B8		;9297
	ld a,(0e069h)		;9299
	cp 004h		;929c
	jr c,L_92B8		;929e
	ld a,(iy+003h)		;92a0   ; aqui la tabla es de palabras, que el ancho lo pide
	add a,a			;92a3
	ld hl,093f6h		;92a4
	call suma_a_hl		;92a7
	ld a,(hl)			;92aa
	inc hl			;92ab
	ld h,(hl)			;92ac
	ld l,a			;92ad
	add hl,de			;92ae   ; sumado a donde esta el objetivo
	ld a,h			;92af   ; y si el adelanto lo saca por el borde
	and a			;92b0
	jp p,L_92B7		;92b1
	ld hl,00000h		;92b4   ; se recorta a cero: no se persigue fuera del campo
L_92B7:
	ex de,hl			;92b7
L_92B8:
	ld l,(ix+006h)		;92b8   ; el ancho del jugador
	ld h,(ix+007h)		;92bb
	and a			;92be
	sbc hl,de		;92bf   ; menos el del objetivo
	ld (0e288h),hl		;92c1
	jr nc,L_92D1		;92c4
	ld a,(0e284h)		;92c6
	set 1,a		;92c9   ; el bit 1 apunta a que lado le queda
	ld (0e284h),a		;92cb
	call L_A211		;92ce   ; y se niega, que la distancia se quiere positiva
L_92D1:
	ld a,(0e280h)		;92d1
	sub 004h		;92d4   ; en los subestados 4 y 5 del partido...
	cp 002h		;92d6
	jr nc,L_92DE		;92d8
	ld de,00020h		;92da   ; ...se le anaden 32 pixeles: es el margen con el que se persigue en esos dos
	add hl,de			;92dd
L_92DE:
	ld (0e28ah),hl		;92de   ; y la distancia definitiva
	ret			;92e1
mide_y_convierte:
	call mide_hasta_el_objetivo		;92e2

; ----------------------------------------------------------------------
; ===== LA PUNTERIA: dos distancias, dos tablas =====
; ----------------------------------------------------------------------
L_92E5:
	xor a			;92e5   ; la distancia recien medida
	ld (0e54fh),a		;92e6
	ld a,(0e286h)		;92e9   ; la vertical
	cp 0c0h		;92ec   ; por encima de 0xC0 no se afina mas
	jr c,L_92F4		;92ee
	ld a,00bh		;92f0   ; y se da por el maximo, 11
	jr L_92FA		;92f2
L_92F4:
	and 0f0h		;92f4   ; y si no, el nibble alto: la distancia se reparte en dieciseis escalones
	rrca			;92f6
	rrca			;92f7
	rrca			;92f8
	rrca			;92f9
L_92FA:
	ld (0e287h),a		;92fa   ; a (0xE287)
	ld hl,(0e28ah)		;92fd   ; y la horizontal
	ld a,h			;9300
	and a			;9301   ; si tiene byte alto es que esta muy lejos
	jr z,L_9308		;9302
	ld a,00fh		;9304   ; y se da el maximo, 15
	jr L_930F		;9306
L_9308:
	ld a,l			;9308   ; y si no, otra vez el nibble alto
	and 0f0h		;9309
	rrca			;930b
	rrca			;930c
	rrca			;930d
	rrca			;930e
L_930F:
	ld (0e28ch),a		;930f   ; el escalon de ancho, de 0 a 15
	ld hl,0bf0fh		;9312   ; primer nivel: 0xBF0F, una palabra por escalon de ancho
	ld a,(0e28ch)		;9315
	add a,a			;9318
	call suma_a_hl		;9319
	ld e,(hl)			;931c
	inc hl			;931d
	ld d,(hl)			;931e
	ex de,hl			;931f
	ld a,(0e287h)		;9320   ; segundo nivel: y dentro, un byte por escalon de alto
	call suma_a_hl		;9323
	ld a,(0e540h)		;9326   ; (0xE540) bit 0: el golpe va tabulado o fijo
	rra			;9329
	jr c,L_933F		;932a
	ld e,(hl)			;932c   ; el byte de la tabla, doblado, es el empuje vertical...
	ld d,000h		;932d
	sla e		;932f
	rl d		;9331
	ld (0e2abh),de		;9333
	ld hl,0fffdh		;9337   ; ...y la gravedad, 0xFFFD, o sea tres por cuadro hacia abajo
	ld (0e2adh),hl		;933a
	jr L_934A		;933d
L_933F:
	ld hl,0bfefh		;933f   ; y el golpe fijo son cuatro bytes copiados tal cual de 0xBFEF
	ld de,0e2abh		;9342
	ld bc,00004h		;9345
	ldir		;9348
L_934A:
	ld hl,0bd6fh		;934a   ; y ahora el suelo, con la otra tabla de dos niveles
	ld a,(0e28ch)		;934d
	add a,a			;9350
	call suma_a_hl		;9351
	ld e,(hl)			;9354
	inc hl			;9355
	ld d,(hl)			;9356
	ex de,hl			;9357
	ld a,(0e287h)		;9358
	add a,a			;935b
	call suma_a_hl		;935c
	ld e,(hl)			;935f   ; de esta salen DOS bytes: la componente a lo largo en E y la de traves en C
	inc hl			;9360
	ld c,(hl)			;9361
	ld d,000h		;9362
	ld b,d			;9364
	sla e		;9365   ; los dos doblados, igual que el vertical
	rl d		;9367
	sla c		;9369
	rl b		;936b
	ld a,(0e280h)		;936d   ; en el subestado 2 -el saque de banda, la pelota rasa- el golpe se ablanda
	cp 002h		;9370
	jr nz,L_93B0		;9372
	srl d		;9374   ; la mitad...
	rr e		;9376
	ld h,d			;9378
	ld l,e			;9379
	push hl			;937a
	srl d		;937b
	rr e		;937d
	add hl,de			;937f   ; ...mas otro cuarto: tres cuartos del empuje normal
	ex de,hl			;9380
	pop hl			;9381
	ld a,(0e287h)		;9382   ; y si ademas el objetivo esta a menos de tres escalones en las dos direcciones...
	cp 003h		;9385
	jr nc,L_9391		;9387
	ld a,(0e28ch)		;9389
	cp 003h		;938c
	jr nc,L_9391		;938e
	ex de,hl			;9390   ; ...se cambia por la mitad limpia: de cerca, un toque
L_9391:
	srl b		;9391   ; y lo mismo con la componente de traves
	rr c		;9393
	ld h,b			;9395
	ld l,c			;9396
	push hl			;9397
	srl b		;9398
	rr c		;939a
	add hl,bc			;939c
	ld b,h			;939d
	ld c,l			;939e
	pop hl			;939f
	ld a,(0e287h)		;93a0   ; con el mismo corte de tres escalones
	cp 003h		;93a3
	jr nc,L_93B0		;93a5
	ld a,(0e28ch)		;93a7
	cp 003h		;93aa
	jr nc,L_93B0		;93ac
	ld c,l			;93ae
	ld b,h			;93af
L_93B0:
	ld a,(0e284h)		;93b0   ; los dos signos que dejo 0x9273 en (0xE284): el bit 0 es el alto...
	rra			;93b3
	jr c,L_93BD		;93b4
	ld hl,00000h		;93b6   ; ...y donde no toca, la componente se niega
	and a			;93b9
	sbc hl,de		;93ba
	ex de,hl			;93bc
L_93BD:
	ld (0e2a2h),de		;93bd   ; la velocidad a lo largo
	rra			;93c1   ; y el bit 1, el ancho
	jr c,L_93CC		;93c2
	ld hl,00000h		;93c4
	and a			;93c7
	sbc hl,bc		;93c8
	ld c,l			;93ca
	ld b,h			;93cb
L_93CC:
	ld (0e2a7h),bc		;93cc   ; la velocidad de traves
	ld a,(0e280h)		;93d0   ; en el subestado 5 -el saque de centro- el empuje vertical y la gravedad se DOBLAN: la pelota sale mas tensa y cae mas rapido
	cp 005h		;93d3
	jr nz,L_93E5		;93d5
	ld hl,(0e2abh)		;93d7
	add hl,hl			;93da
	ld (0e2abh),hl		;93db
	ld hl,(0e2adh)		;93de
	add hl,hl			;93e1
	ld (0e2adh),hl		;93e2
L_93E5:
	ld a,(0e540h)		;93e5   ; y salvo con el golpe fijo, se reparte destacado
	rra			;93e8
	ret c			;93e9
	jp reparte_el_destacado		;93ea

; ----------------------------------------------------------------------
; DATOS incrementos_con_signo: dos tablas que 0x926A y 0x92A4 recorren; el
;   0x20 vale +32 y el 0xE0 vale -32
;   0x93ed..0x9408  (27 bytes)
DATA_incrementos_con_signo:
	defb 000h	; 93ed
	defb 000h	; 93ee
	defb 020h	; 93ef
	defb 020h	; 93f0
	defb 020h	; 93f1
	defb 000h	; 93f2
	defb 0e0h	; 93f3
	defb 0e0h	; 93f4
	defb 0e0h	; 93f5
	defb 000h	; 93f6
	defb 000h	; 93f7
	defb 020h	; 93f8
	defb 000h	; 93f9
	defb 020h	; 93fa
	defb 000h	; 93fb
	defb 000h	; 93fc
	defb 000h	; 93fd
	defb 0e0h	; 93fe
	defb 0ffh	; 93ff
	defb 0e0h	; 9400
	defb 0ffh	; 9401
	defb 0e0h	; 9402
	defb 0ffh	; 9403
	defb 000h	; 9404
	defb 000h	; 9405
	defb 020h	; 9406
	defb 000h	; 9407

; ======================================================================
; CODIGO 0x9408..0x9f65  (2909 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL PASE Y EL TIRO =====
; ----------------------------------------------------------------------
apunta_al_companero:		; deja en (0xE28D) el puntero a la ficha del companero al que se pasaria
	ld a,(0e547h)		;9408   ; (0xE547) o (0xE299): con cualquiera de los dos en marcha, el objetivo ya esta decidido
	ld hl,0e299h		;940b
	or (hl)			;940e
	ret nz			;940f
	ld a,(0e534h)		;9410   ; (0xE534) es el numero del companero elegido
	ld b,a			;9413
	inc a			;9414   ; el 0xFF significa que no hay ninguno...
	ld hl,00000h		;9415   ; ...y entonces el objetivo queda a cero
	jr z,L_941E		;9418
	ld a,b			;941a
	call L_A201		;941b   ; y si lo hay, IX y HL a su ficha
L_941E:
	ld (0e28dh),hl		;941e   ; que queda apuntado en (0xE28D)
	ret			;9421
pase_o_tiro:
	ld a,(0e547h)		;9422   ; (0xE547) lleva la fase en la que va el golpeo
	rra			;9425
	jr c,resuelve_el_golpe		;9426   ; el bit 0: el golpe ya esta lanzado y solo falta resolverlo
	rra			;9428
	jp c,resuelve_el_tiro		;9429   ; y el bit 1, lo mismo para el tiro
	ld a,(0e527h)		;942c   ; el bando al que sigue la camara
	and a			;942f
	ld de,0e006h		;9430   ; con eso se elige el mando que manda la jugada
	ld hl,0e007h		;9433
	ld c,000h		;9436
	jr z,L_9458		;9438
	ld c,001h		;943a
	ld a,(0e002h)		;943c
	bit 5,a		;943f   ; el bit 5 de (0xE002): si hay un segundo humano...
	jr nz,L_9452		;9441   ; ...el otro bando lo lleva el mando 2
	ld c,002h		;9443   ; y si no, lo lleva la maquina
	ld a,(0e53fh)		;9445   ; (0xE53F) es lo que la maquina ha decidido hacer
	and a			;9448
	ret z			;9449   ; a cero, nada
	dec a			;944a
	jr z,L_9472		;944b   ; uno, pase
	dec a			;944d
	jp z,apunta_a_la_porteria		;944e   ; y dos, tiro: la maquina entra por las mismas puertas que el humano
	ret			;9451
L_9452:
	ld de,0e008h		;9452
	ld hl,0e009h		;9455
L_9458:
	ld a,(0e299h)		;9458   ; (0xE299) cuenta lo que se lleva pulsado
	and a			;945b
	jr nz,L_9462		;945c   ; mientras cuenta, ya no hace falta el flanco
	ld a,(de)			;945e   ; y si no, se espera al flanco: el boton recien pulsado
	and 010h		;945f
	ret z			;9461
L_9462:
	ld a,(hl)			;9462
	and 010h		;9463   ; aqui se mira lo MANTENIDO
	jr z,L_9472		;9465   ; en cuanto se suelta, sale el pase
	ld hl,0e299h		;9467
	inc (hl)			;946a   ; un cuadro mas pulsado
	ld a,(hl)			;946b
	cp 00eh		;946c   ; y a los catorce
	ret nz			;946e
	jp apunta_a_la_porteria		;946f   ; el pase se convierte en tiro a puerta
L_9472:
	xor a			;9472
	ld (0e299h),a		;9473   ; la cuenta se rearma
	ld iy,(0e28dh)		;9476   ; el companero al que se pasa
	push iy		;947a
	pop hl			;947c
	ld a,h			;947d
	or l			;947e
	jr z,sin_companero_apunta_al_frente		;947f   ; sin companero no hay pase
	call mide_hasta_el_objetivo		;9481   ; la distancia hasta el
	ld c,001h		;9484   ; el modo 1, el del pase
	call gira_hacia_el_objetivo		;9486
	ld a,(0e547h)		;9489
	rra			;948c   ; y si el golpe ya esta lanzado, aqui se acaba
	ret c			;948d
resuelve_el_golpe:		; la fuerza sale de la distancia: cerca suena flojo, lejos suena el trallazo
	call L_92E5		;948e   ; las distancias, ya convertidas a escalones
	push ix		;9491
	call L_B667		;9493   ; la velocidad que se le imprime
	pop ix		;9496
	ld a,(0e28ch)		;9498   ; los dos escalones de distancia...
	cp 002h		;949b
	jr nc,L_94AD		;949d
	ld a,(0e287h)		;949f
	cp 002h		;94a2   ; ...y si los dos son menores que 2, el objetivo esta al lado
	jr nc,L_94AD		;94a4
	ld a,015h		;94a6   ; y suena el 0x15, que es el toque corto
	call pide_un_sonido		;94a8
	jr L_94B7		;94ab
L_94AD:
	ld a,057h		;94ad   ; y de lejos, el 0x57...
	call pide_un_sonido		;94af
	ld a,003h		;94b2   ; ...y ademas el 3: dos sonidos a la vez para el pase largo
	call pide_un_sonido		;94b4
L_94B7:
	ld a,(0e284h)		;94b7   ; (0xE284) trae los dos bits de signo de la medida
	and a			;94ba
	ld c,006h		;94bb   ; sin ninguno, la direccion 6
	jr z,L_94CB		;94bd
	dec a			;94bf
	ld c,004h		;94c0   ; con el de altura, la 4
	jr z,L_94CB		;94c2
	dec a			;94c4
	ld c,008h		;94c5   ; con el de ancho, la 8
	jr z,L_94CB		;94c7
	ld c,002h		;94c9   ; y con los dos, la 2: las cuatro diagonales
L_94CB:
	ld (ix+00ch),c		;94cb   ; a la ficha
	ld (ix+00dh),003h		;94ce   ; con el dibujo 3, el del golpeo
	ld (ix+002h),010h		;94d2   ; y el +2 a 0x10
	xor a			;94d6
	ld (0e284h),a		;94d7   ; los signos se limpian, que ya se han gastado
	ld (0e547h),a		;94da
	ld (ix+003h),a		;94dd
	ld (ix+001h),a		;94e0
	dec a			;94e3
	ld hl,0e528h		;94e4   ; y la pelota deja de tener dueno: (0xE528) a 0xFF
	ld c,(hl)			;94e7
	ld (hl),a			;94e8
	ld a,c			;94e9
	ld (0e542h),a		;94ea   ; el que la llevaba queda apuntado en (0xE542), para no poder recogerla el mismo
	ld hl,00100h		;94ed   ; (0xE280) a 1 y (0xE281) a 0: la jugada vuelve a empezar
	ld (0e280h),hl		;94f0
	xor a			;94f3
	ld (0e53fh),a		;94f4   ; y lo que la maquina habia decidido, borrado
	ld a,020h		;94f7
	ld (0e544h),a		;94f9   ; 0x20 cuadros antes de que nadie pueda tocarla
	ret			;94fc
sin_companero_apunta_al_frente:
	ld a,(0e292h)		;94fd
	ld (0e551h),a		;9500   ; se tira hacia (0xE292), que es la porteria de enfrente

; ----------------------------------------------------------------------
; ----- el tiro: el objetivo es la porteria, no un jugador -----
; ----------------------------------------------------------------------
apunta_a_la_porteria:
	xor a			;9503
	ld (0e299h),a		;9504   ; la cuenta del boton se rearma
	ld e,c			;9507
	ld a,e			;9508   ; con el modo 0...
	and a			;9509
	ld a,(0e291h)		;950a   ; ...se apunta a (0xE291) y al pixel 15, o sea el fondo de un campo
	ld bc,0000fh		;950d
	jr z,L_9523		;9510
	ld a,e			;9512
	cp 001h		;9513   ; con el modo 1...
	ld a,(0e292h)		;9515   ; ...a (0xE292) y al pixel 0x270: 624 de los 640 que mide el campo, o sea el otro fondo
	ld bc,00270h		;9518
	jr z,L_9523		;951b
	ld a,(0e551h)		;951d   ; y si no, a (0xE551), con el mismo fondo lejano
	ld bc,00270h		;9520
L_9523:
	ld iy,0e2d0h		;9523   ; la porteria se monta como si fuera una ficha mas, en 0xE2D0
	ld (iy+004h),a		;9527   ; con su altura...
	ld (iy+006h),c		;952a   ; ...y su posicion a lo ancho, que es lo unico que hace falta para apuntar
	ld (iy+007h),b		;952d
	ld a,001h		;9530
	ld (0e540h),a		;9532   ; (0xE540) a uno: mientras dura el tiro no se anticipa nada
	ld a,(0e527h)		;9535
	and a			;9538
	jr nz,L_9540		;9539   ; y a un bando...
	ld a,002h		;953b   ; ...se le enciende ademas (0xE566)
	ld (0e566h),a		;953d
L_9540:
	ld a,(ix+004h)		;9540   ; la altura del que tira
	add a,014h		;9543   ; mas 0x14: se apunta un poco por debajo de si mismo, que es como se levanta la pelota
	call mide_hasta_el_objetivo		;9545
	ld c,002h		;9548   ; el modo 2, el del tiro
	call gira_hacia_el_objetivo		;954a
	ld a,(0e547h)		;954d
	rra			;9550
	rra			;9551
	ret c			;9552
resuelve_el_tiro:
	call L_92E5		;9553
	ld a,057h		;9556   ; el 0x57 y el 4: el tiro suena distinto del pase
	call pide_un_sonido		;9558
	ld a,004h		;955b
	call pide_un_sonido		;955d
	ld a,(ix+015h)		;9560
	ld (0e557h),a		;9563
	jp L_94B7		;9566
gira_hacia_el_objetivo:		; cambia la direccion del jugador solo si la que lleva no sirve
	ld a,(0e284h)		;9569   ; los dos bits de signo que dejo la medida
	and a			;956c
	jr z,L_9577		;956d   ; sin ninguno, el objetivo queda hacia un cuadrante...
	dec a			;956f
	jr z,L_9587		;9570   ; ...y asi con los cuatro
	dec a			;9572
	jr z,L_9597		;9573
	jr L_95A7		;9575
L_9577:
	ld a,(ix+00ch)		;9577   ; la direccion que el jugador lleva ahora
	cp 005h		;957a   ; las tres que ya valen para ese cuadrante: la 5...
	ret z			;957c
	cp 006h		;957d
	ret z			;957f   ; ...la 6...
	cp 007h		;9580
	ret z			;9582   ; ...y la 7; con cualquiera de ellas no se toca nada
	ld a,006h		;9583   ; y si no, la 6, que es la del medio
	jr L_95B5		;9585
L_9587:
	ld a,(ix+00ch)		;9587   ; aqui las buenas son la 3, la 4 y la 5
	cp 003h		;958a
	ret z			;958c
	cp 004h		;958d
	ret z			;958f
	cp 005h		;9590
	ret z			;9592
	ld a,004h		;9593   ; con la 4 de por medio
	jr L_95B5		;9595
L_9597:
	ld a,(ix+00ch)		;9597   ; la 1, la 7 y la 8, que son las que cruzan por el cero
	cp 001h		;959a
	ret z			;959c
	cp 007h		;959d
	ret z			;959f
	cp 008h		;95a0
	ret z			;95a2
	ld a,008h		;95a3   ; con la 8 en medio
	jr L_95B5		;95a5
L_95A7:
	ld a,(ix+00ch)		;95a7   ; y la 1, la 2 y la 3
	cp 001h		;95aa
	ret z			;95ac
	cp 002h		;95ad
	ret z			;95af
	cp 003h		;95b0
	ret z			;95b2
	ld a,002h		;95b3   ; con la 2
L_95B5:
	ld (ix+00ch),a		;95b5   ; la direccion elegida, a la ficha
	ld a,001h		;95b8
	ld (ix+00dh),a		;95ba   ; y el dibujo 1
	ld a,c			;95bd   ; el modo que pidio quien llama queda en (0xE547), que es lo que resuelve el golpe
	ld (0e547h),a		;95be
	ret			;95c1

; ----------------------------------------------------------------------
; ===== LOS DOS PORTEROS =====
; ----------------------------------------------------------------------
mueve_a_los_porteros:		; suben y bajan solos entre 0x34 y 0x88, cuatro pixeles por cuadro
	ld a,(0e547h)		;95c2   ; con un golpe en marcha, los porteros se quedan como estan
	ld hl,0e299h		;95c5
	or (hl)			;95c8
	ret nz			;95c9
	ld a,(0e551h)		;95ca   ; (0xE551) distinto de cero: hay tiro apuntado a ellos
	and a			;95cd
	ret nz			;95ce
	ld a,(0e540h)		;95cf   ; (0xE540) es el cerrojo del tiro
	and a			;95d2
	ret nz			;95d3
	ld a,(0e280h)		;95d4   ; y solo se mueven en los dos primeros subestados del partido
	cp 002h		;95d7
	ret nc			;95d9
	ld a,(0e52eh)		;95da   ; (0xE52E) distinto de cero: hay una jugada parada
	and a			;95dd
	ret nz			;95de
	ld a,(0e298h)		;95df   ; (0xE298) es el sentido del vaiven
	rra			;95e2
	ld a,(0e291h)		;95e3   ; la altura de ahora, que es la MISMA a la que apunta el tiro a puerta
	jr c,L_95F8		;95e6
	add a,004h		;95e8   ; bajando, cuatro pixeles
	ld (0e291h),a		;95ea   ; y la misma altura a los dos: los dos porteros van sincronizados
	ld (0e292h),a		;95ed
	sub 088h		;95f0   ; en 0x88 se llega al palo de abajo
	ret nz			;95f2
	inc a			;95f3
	ld (0e298h),a		;95f4   ; y el sentido se da la vuelta
	ret			;95f7
L_95F8:
	sub 004h		;95f8   ; subiendo, cuatro
	ld (0e291h),a		;95fa
	ld (0e292h),a		;95fd
	sub 034h		;9600   ; y en 0x34, el palo de arriba
	ret nz			;9602
	ld (0e298h),a		;9603
	ret			;9606
estampa_a_los_porteros:		; los borra de donde estaban y los pone donde van, en el mapa
	ld a,(0e291h)		;9607   ; la altura del primer portero
	add a,010h		;960a   ; mas 0x10, que es donde cae su casilla
	ld de,0000fh		;960c   ; y el pixel 15 a lo ancho: el fondo de un campo
	call casilla_del_mapa		;960f
	ld hl,(0e294h)		;9612   ; donde estaba, se borra
	ld (hl),001h		;9615   ; con el tile 1, que es el cesped
	ld (0e294h),de		;9617   ; y la casilla nueva queda apuntada
	ld bc,00301h		;961b
	ex de,hl			;961e
	ld (hl),b			;961f   ; con el tile 3, el del portero
	ld a,(0e002h)		;9620
	bit 5,a		;9623   ; el bit 5 de (0xE002): con dos jugadores, se hace tambien el segundo
	jr nz,L_962D		;9625
	ld a,(0e069h)		;9627   ; y con uno solo, el nivel decide: del 3 en adelante se sale y el segundo portero NO se estampa
	cp 003h		;962a
	ret nc			;962c
L_962D:
	ld a,(0e292h)		;962d   ; la altura del segundo
	add a,010h		;9630
	ld de,00270h		;9632   ; en el pixel 0x270, el otro fondo
	call casilla_del_mapa		;9635
	ld hl,(0e296h)		;9638
	ld (hl),001h		;963b
	ld (0e296h),de		;963d
	ld bc,00401h		;9641   ; y su tile es el 4, no el 3: los dos porteros se dibujan distinto
	ex de,hl			;9644
	ld (hl),b			;9645
	ret			;9646
casilla_del_mapa:		; convierte altura y ancho en una direccion dentro del mapa de 0xE600
	sub 008h		;9647   ; la altura, menos la fila que se come el marcador
	and 0f8h		;9649   ; alineada a la casilla de ocho pixeles
	ld h,000h		;964b
	ld l,a			;964d
	add hl,hl			;964e   ; por dos...
	ld c,l			;964f   ; ...que se guarda...
	ld b,h			;9650
	add hl,hl			;9651   ; ...y por ocho
	add hl,hl			;9652
	add hl,bc			;9653   ; dos mas ocho son diez, y como la altura venia ya dividida entre ocho, esto es fila por 80
	ld a,e			;9654
	and 0f8h		;9655   ; el ancho, tambien alineado
	rr d		;9657   ; y entre ocho, con los tres giros arrastrando el bit alto
	rra			;9659
	rr d		;965a
	rra			;965c
	rr d		;965d
	rra			;965f
	ld e,a			;9660
	add hl,de			;9661   ; fila mas columna
	ld de,0e600h		;9662   ; sobre el mapa, que vive en la RAM
	add hl,de			;9665
	ex de,hl			;9666
	ret			;9667

; ----------------------------------------------------------------------
; ===== EL ARBITRO =====
; ----------------------------------------------------------------------
el_arbitro:		; mira si la pelota se ha salido, y por donde
	ld a,(0e533h)		;9668   ; (0xE533) distinto de cero: ya hay un saque en marcha
	and a			;966b
	ret nz			;966c
	ld a,(0e530h)		;966d   ; (0xE530) recuerda por que banda salio
	rra			;9670   ; su bit 0: por la de arriba...
	jr c,para_la_pelota_en_la_banda_de_arriba		;9671
	rra			;9673   ; ...y el bit 1, por la de abajo
	jp c,para_la_pelota_en_la_banda_de_abajo		;9674
	ld a,(0e52fh)		;9677   ; (0xE52F) hace lo mismo con los dos fondos
	rra			;967a
	jp c,saque_de_puerta		;967b
	rra			;967e
	jp c,L_9A7A		;967f
	ld a,(0e52eh)		;9682   ; y (0xE52E) con los otros dos casos
	rra			;9685
	jp c,L_9830		;9686
	rra			;9689
	jp c,L_9A05		;968a
	ld a,(0e2a1h)		;968d   ; la altura de la pelota
	cp 01dh		;9690   ; por encima de 0x1D esta la banda de arriba
	jr c,sale_por_la_banda_de_arriba		;9692
	cp 0b3h		;9694   ; y por debajo de 0xB3 la de abajo: 150 pixeles de campo entre las dos
	jp nc,sale_por_la_banda_de_abajo		;9696
	ld hl,(0e2a5h)		;9699   ; y ahora lo ancho
	ld de,0001eh		;969c   ; el pixel 30 es la linea de fondo de un lado
	and a			;969f
	sbc hl,de		;96a0
	jp c,sale_por_el_fondo_de_un_lado		;96a2
	ld hl,(0e2a5h)		;96a5   ; y la de enfrente...
	ld de,00259h		;96a8   ; ...en el 601: el campo mide 640 y quedan 39 de margen a cada lado
	and a			;96ab
	sbc hl,de		;96ac
	jp nc,L_99B5		;96ae
	ret			;96b1   ; dentro de las cuatro lineas, no hay nada que pitar
sale_por_la_banda_de_arriba:
	ld a,001h		;96b2
	ld (0e530h),a		;96b4   ; (0xE530) a 1: por arriba
	call guarda_el_estado_de_la_pelota		;96b7
para_la_pelota_en_la_banda_de_arriba:
	ld a,(0e280h)		;96ba
	dec a			;96bd   ; en el subestado 1 se pasa directo a colocar el saque
	jr z,L_96FD		;96be
	ld a,(0e2a1h)		;96c0   ; la altura
	cp 010h		;96c3   ; por debajo de 0x10 ya no rueda mas
	jr c,L_96E3		;96c5
	ld hl,(0e2a5h)		;96c7
	ld de,00002h		;96ca
	and a			;96cd   ; y a lo ancho, entre el pixel 2...
	sbc hl,de		;96ce
	jr c,L_96E3		;96d0
	ld hl,(0e2a5h)		;96d2
	ld de,0027eh		;96d5   ; ...y el 0x27E: si sigue dentro, se le deja rodar
	and a			;96d8
	sbc hl,de		;96d9
	jr nc,L_96E3		;96db
	ld hl,(0e2a2h)		;96dd   ; y mientras le quede velocidad
	ld a,h			;96e0
	or l			;96e1
	ret nz			;96e2   ; tampoco se para
L_96E3:
	call apaga_el_sonido_de_la_pelota		;96e3   ; el sonido de la pelota rodando se corta
	ld hl,00000h		;96e6
	ld (0e2abh),hl		;96e9   ; el empuje a cero
	ld a,(0e2aah)		;96ec   ; (0xE2AA) baja de dos en dos
	dec a			;96ef
	dec a			;96f0
	ld (0e2aah),a		;96f1
	ld hl,00000h		;96f4
	ld (0e280h),hl		;96f7   ; (0xE280) y (0xE281) a cero
	bit 7,a		;96fa   ; y hasta que (0xE2AA) no se hace negativo, se sigue frenando
	ret z			;96fc
L_96FD:
	call borra_las_marcas_de_la_pelota		;96fd   ; las marcas que la pelota dejo en el mapa
	ld a,01dh		;9700   ; y la pelota se planta justo en la linea
	ld (0e2a1h),a		;9702
	ld a,0ffh		;9705   ; con (0xE2A0) a 0xFF
	ld (0e2a0h),a		;9707
	inc a			;970a
	ld (0e530h),a		;970b   ; y la banda ya apuntada se limpia
	ld hl,0e29bh		;970e   ; los tres bytes de reposo de 0x9E9B
	ld de,0e2a4h		;9711
	ld bc,00003h		;9714
	ldir		;9717
	ld hl,00002h		;9719   ; (0xE280) a 2: el subestado del saque
	ld (0e280h),hl		;971c
	ld a,001h		;971f
	ld (0e533h),a		;9721   ; (0xE533) a 1, que es el saque de banda de arriba
	call deja_a_los_doce_quietos		;9724
	ld a,(0e283h)		;9727   ; (0xE283) dice a que equipo le toca sacar
	rra			;972a
	ld bc,00000h		;972b
	ld de,00009h		;972e   ; con estos parametros...
	ld hl,0e410h		;9731
	jr c,L_973F		;9734
	ld bc,00601h		;9736   ; ...o con estos: cada equipo saca desde su propia lista de seis
	ld de,00606h		;9739
	ld hl,0e416h		;973c
L_973F:
	jp elige_al_que_saca		;973f
sale_por_la_banda_de_abajo:
	ld a,002h		;9742
	ld (0e530h),a		;9744   ; (0xE530) a 2: por abajo
	call guarda_el_estado_de_la_pelota		;9747
para_la_pelota_en_la_banda_de_abajo:
	ld a,(0e280h)		;974a   ; la banda de abajo
	dec a			;974d
	jr z,L_9773		;974e
	ld a,(0e2a1h)		;9750
	cp 0c8h		;9753   ; aqui el limite es 0xC8, no 0x10: por abajo la pelota se ve mas rato
	jr nc,L_9773		;9755
	ld hl,(0e2a5h)		;9757
	ld de,00002h		;975a
	and a			;975d
	sbc hl,de		;975e
	jr c,L_9773		;9760
	ld hl,(0e2a5h)		;9762
	ld de,0027eh		;9765
	and a			;9768
	sbc hl,de		;9769
	jr nc,L_9773		;976b
	ld hl,(0e2a2h)		;976d
	ld a,h			;9770
	or l			;9771
	ret nz			;9772
L_9773:
	call borra_las_marcas_de_la_pelota		;9773   ; aqui se para y se saca de banda
	ld a,0b3h		;9776   ; y la pelota se planta en 0xB3, la linea de abajo
	ld (0e2a1h),a		;9778
	xor a			;977b
	ld (0e2a0h),a		;977c
	ld (0e530h),a		;977f
	ld hl,0e29bh		;9782   ; los tres bytes de 0xE29B se copian sobre 0xE2A4: la pelota se queda donde estaba a lo ancho
	ld de,0e2a4h		;9785
	ld bc,00003h		;9788
	ldir		;978b
	ld hl,00002h		;978d   ; (0xE280) al subestado 2, el del saque de banda, y (0xE281) a cero
	ld (0e280h),hl		;9790
	ld a,002h		;9793
	ld (0e533h),a		;9795   ; (0xE533) a 2, el saque de la otra banda
	call deja_a_los_doce_quietos		;9798   ; nadie se mueve mientras se coloca el saque
	ld a,(0e283h)		;979b   ; y cada bando tiene su lista y sus umbrales
	rra			;979e
	ld bc,00000h		;979f
	ld de,00209h		;97a2
	ld hl,0e410h		;97a5
	jr c,elige_al_que_saca		;97a8
	ld bc,00601h		;97aa
	ld de,00806h		;97ad
	ld hl,0e416h		;97b0
elige_al_que_saca:		; busca en la lista del equipo el jugador mas a mano y le da la pelota
	ld a,c			;97b3   ; el bando que saca queda apuntado
	ld (0e527h),a		;97b4
	ld a,(0e52bh)		;97b7   ; (0xE52B) contra el umbral que traiga E
	cp e			;97ba
	ld a,d			;97bb
	jr nc,L_97C0		;97bc
	add a,003h		;97be   ; pasado el umbral, se busca tres puestos mas alla en la lista
L_97C0:
	push bc			;97c0
	call busca_en_la_lista		;97c1   ; y ahi se elige al jugador
	ld a,c			;97c4
	pop bc			;97c5
	add a,b			;97c6   ; mas la base del equipo: 0 el primero, 6 el segundo
	ld (0e537h),a		;97c7   ; y ese es el que lleva la jugada
	ld a,00eh		;97ca
	ld (0e2b4h),a		;97cc   ; (0xE2B4) = 0x0E
	xor a			;97cf
	ld (0e54fh),a		;97d0
	ld a,(0e528h)		;97d3   ; si habia alguien con la pelota
	and a			;97d6
	call p,quitale_la_pelota		;97d7   ; se le quita
	ld a,028h		;97da   ; el 0x28 es el pitido del arbitro
	call pide_un_sonido		;97dc
	jp apaga_el_sonido_de_la_pelota		;97df   ; y el rodar de la pelota se calla
sale_por_el_fondo_de_un_lado:		; aqui se decide si es gol, saque de puerta o de esquina
	ld a,(0e2a1h)		;97e2   ; la altura a la que cruzo la linea
	cp 04bh		;97e5   ; por encima del palo de arriba, en 0x4B...
	jr c,comprueba_los_palos		;97e7
	cp 081h		;97e9   ; ...y por debajo del de abajo, en 0x81: entre los dos hay 54 pixeles de porteria
	jr nc,comprueba_los_palos		;97eb
	ld a,(0e2aah)		;97ed   ; (0xE2AA) es lo que la pelota lleva de vuelo
	cp 010h		;97f0
	jr c,comprueba_si_es_gol		;97f2   ; por debajo de 0x10 va rasa
	rla			;97f4   ; y con el bit alto puesto, va cayendo
	jr c,comprueba_si_es_gol		;97f5
	ld a,001h		;97f7   ; en cualquier otro caso ha entrado alta: (0xE565) lo apunta
	ld (0e565h),a		;97f9
	jr comprueba_los_palos		;97fc

; ----------------------------------------------------------------------
; ===== EL GOL =====
; ----------------------------------------------------------------------
comprueba_si_es_gol:
	ld a,(0e54fh)		;97fe   ; (0xE54F) distinto de cero: la jugada trae algo pendiente
	and a			;9801
	jr z,L_9813		;9802
	ld hl,(0e2a9h)		;9804   ; la altura de vuelo
	adc hl,hl		;9807   ; doblada, y el acarreo dice si se ha pasado
	jr c,L_9813		;9809
	jr z,L_9813		;980b
	ld a,(0e2abh)		;980d   ; y el empuje
	rla			;9810
	jr nc,comprueba_los_palos		;9811   ; sin bit alto puesto, la pelota no entra: se va a mirar si toca palo
L_9813:
	ld a,001h		;9813   ; (0xE52E) a 1: gol apuntado
	ld (0e52eh),a		;9815
	ld a,006h		;9818   ; (0xE2B4) = 6
	ld (0e2b4h),a		;981a
	ld a,(0e528h)		;981d   ; quien llevaba la pelota
	ld c,a			;9820
	inc a			;9821   ; el 0xFF significa que no la llevaba nadie...
	jr z,L_982A		;9822
	ld a,c			;9824
	ld (0e554h),a		;9825   ; ...y si la llevaba alguien, ese es el goleador
	jr L_9830		;9828
L_982A:
	ld a,(0e557h)		;982a   ; y si no, se apunta al ultimo que la toco, que es lo que guarda (0xE557)
	ld (0e554h),a		;982d
L_9830:
	ld a,(0e280h)		;9830
	dec a			;9833   ; en el subestado 1 el gol ya esta contado
	jr z,L_984D		;9834
	ld hl,(0e2a7h)		;9836   ; sin desvio lateral...
	ld a,h			;9839
	or l			;983a
	jr z,L_984D		;983b   ; ...el gol es directo
	ld hl,(0e2a5h)		;983d   ; y si lo hay, se mira si la pelota ya paso del pixel 0x13
	ld de,00013h		;9840
	and a			;9843
	sbc hl,de		;9844
	jp nc,L_9A2A		;9846
	dec de			;9849
	jp L_9A1E		;984a
L_984D:
	ld a,001h		;984d
	ld (0e0f0h),a		;984f   ; y aqui esta el gol: el bit 0 de (0xE0F0), que es lo que lee el marcador
	ret			;9852

; ----------------------------------------------------------------------
; ----- los dos palos -----
; ----------------------------------------------------------------------
comprueba_los_palos:
	ld a,(0e280h)		;9853
	and a			;9856   ; solo en el subestado 0...
	jr nz,L_987D		;9857
	ld a,(0e281h)		;9859
	dec a			;985c   ; ...y con (0xE281) valiendo 1
	jr nz,L_987D		;985d
	ld a,(0e2aah)		;985f   ; (0xE2AA) por debajo de 0x10: la pelota va rasa
	cp 010h		;9862
	jr nc,L_987D		;9864
	ld a,(0e2a1h)		;9866   ; y su altura
	cp 04ah		;9869   ; el palo de arriba ocupa 0x4A...
	jp z,rebota_en_el_palo		;986b
	cp 049h		;986e   ; ...y 0x49: dos pixeles de grosor
	jp z,rebota_en_el_palo		;9870
	cp 081h		;9873   ; y el de abajo, 0x81...
	jp z,rebota_en_el_palo		;9875
	cp 082h		;9878   ; ...y 0x82
	jp z,rebota_en_el_palo		;987a
L_987D:
	ld a,001h		;987d
	ld (0e52fh),a		;987f   ; (0xE52F) a 1: la pelota se ha ido por el fondo
	ld a,004h		;9882
	ld (0e2b4h),a		;9884   ; (0xE2B4) = 4

; ----------------------------------------------------------------------
; ----- el larguero -----
; ----------------------------------------------------------------------
saque_de_puerta:
	ld a,(0e280h)		;9887
	dec a			;988a   ; en el subestado 1 se va derecho a colocar el saque
	jr z,L_98D8		;988b
	ld a,(0e565h)		;988d   ; (0xE565): la pelota entro por encima de la altura de porteria
	and a			;9890
	jr z,L_98B5		;9891
	ld a,(0e2ach)		;9893   ; (0xE2AC), y con su bit alto puesto viene bajando
	rla			;9896
	jr nc,L_98B5		;9897
	ld a,(0e2aah)		;9899   ; y a 0x10 o 0x11 de vuelo
	cp 010h		;989c
	jr z,L_98A4		;989e
	cp 011h		;98a0
	jr nz,L_98B5		;98a2   ; fuera de esa franja no hay larguero que valga
L_98A4:
	ld hl,(0e2abh)		;98a4   ; el empuje
	call L_A211		;98a7   ; cambiado de signo: la pelota sale rebotada
	srl h		;98aa   ; y entre dos: el larguero se come la mitad de la velocidad
	rr l		;98ac
	ld (0e2abh),hl		;98ae
	xor a			;98b1
	ld (0e565h),a		;98b2   ; y la marca se gasta, que solo se rebota una vez
L_98B5:
	ld hl,(0e2a5h)		;98b5   ; mientras la pelota siga por delante del pixel 2...
	ld de,00002h		;98b8
	and a			;98bb
	sbc hl,de		;98bc
	jr c,L_98D8		;98be
	ld a,(0e2a1h)		;98c0   ; ...y entre 0x10 y 0xC8 de alto: fuera de eso ya no hay nada que mirar
	cp 010h		;98c3   ; ...y entre 0x10 y 0xC8 de alto
	jr c,L_98D8		;98c5
	cp 0c8h		;98c7
	jr nc,L_98D8		;98c9
	ld hl,(0e2a7h)		;98cb
	ld a,h			;98ce
	or l			;98cf
	jp nz,encaja_la_pelota_en_el_palo		;98d0   ; y le quede desvio, sigue rodando
	ld a,(0e281h)		;98d3
	and a			;98d6
	ret nz			;98d7   ; y con (0xE281) en marcha, tampoco se corta
L_98D8:
	call pita_y_para_la_jugada		;98d8   ; SE PITA Y SE PARA LA JUGADA
	ld a,(0e283h)		;98db   ; el bando que la toco por ultima vez decide que saque es
	rra			;98de
	jr c,L_9940		;98df   ; la toco el primer bando, que ataca hacia aca: esquina para ellos
	ld hl,00004h		;98e1   ; la toco el segundo, o sea el que defiende este fondo: SAQUE DE PUERTA suyo. (0xE280) al estado 4 y (0xE281) a cero, de una tacada
	ld (0e280h),hl		;98e4
	ld a,007h		;98e7   ; el puesto 7 -el del medio- es el que saca de puerta...
	ld hl,0e416h		;98e9
	call busca_en_la_lista		;98ec
	ld a,c			;98ef   ; ...y sumandole 6 se pasa del numero dentro del bando al numero entre los doce
	add a,006h		;98f0
	ld (0e537h),a		;98f2
	ld a,001h		;98f5   ; la camara se va con ellos
	ld (0e527h),a		;98f7
	ld a,(0e528h)		;98fa   ; y al que llevara la pelota se le quita
	and a			;98fd
	call p,quitale_la_pelota		;98fe
	ld a,(0e2a1h)		;9901   ; 0x70 parte el campo en dos a lo alto: la pelota salio por la mitad de abajo...
	cp 070h		;9904
	jr c,L_9924		;9906
	ld a,008h		;9908   ; ...saque de puerta de abajo
	ld (0e533h),a		;990a
	xor a			;990d
	ld (0e2a4h),a		;990e   ; la pelota, a 60 pixeles del borde y a 0x86 de alto, o sea justo al lado del palo de abajo
	ld hl,0003ch		;9911
	ld (0e2a5h),hl		;9914
	ld hl,08600h		;9917
	ld (0e2a0h),hl		;991a
	ld hl,00000h		;991d   ; y quieta, sin desvio
	ld (0e2a9h),hl		;9920
	ret			;9923
L_9924:
	ld a,007h		;9924   ; y por la mitad de arriba, el de arriba
	ld (0e533h),a		;9926
	xor a			;9929
	ld (0e2a4h),a		;992a
	ld hl,0003ch		;992d   ; misma X, y 0x4A de alto: al lado del otro palo
	ld (0e2a5h),hl		;9930
	ld hl,04a00h		;9933
	ld (0e2a0h),hl		;9936
	ld hl,00000h		;9939
	ld (0e2a9h),hl		;993c
	ret			;993f
L_9940:
	ld hl,00003h		;9940   ; LA ESQUINA de este lado. Estado 3, y esta la saca el primer bando
	ld (0e280h),hl		;9943
	ld a,003h		;9946
	ld (0e537h),a		;9948   ; el puesto 3, que es el de arriba
	xor a			;994b
	ld (0e527h),a		;994c
	inc a			;994f
	ld (0e567h),a		;9950   ; (0xE567) avisa de que hay saque de esquina en marcha
	ld a,(0e528h)		;9953
	and a			;9956
	call p,quitale_la_pelota		;9957
	ld a,(0e2a1h)		;995a
	cp 070h		;995d
	jr c,L_998C		;995f
	ld a,004h		;9961   ; salio por abajo: esquina de abajo, puesto 5 -el 3 mas dos-
	ld (0e533h),a		;9963
	ld a,(0e537h)		;9966
	inc a			;9969
	inc a			;996a
	ld hl,0e410h		;996b   ; y se busca en la lista quien lleva ese puesto
	call busca_en_la_lista		;996e
	ld a,c			;9971
	ld (0e537h),a		;9972
	xor a			;9975
	ld (0e2a4h),a		;9976
	ld hl,00026h		;9979   ; la pelota, a 38 pixeles del borde y a 0xB0 de alto: la banda de abajo esta en 0xB3
	ld (0e2a5h),hl		;997c
	ld hl,0b000h		;997f
	ld (0e2a0h),hl		;9982
	ld hl,00000h		;9985
	ld (0e2a9h),hl		;9988
	ret			;998b
L_998C:
	ld a,003h		;998c   ; y por arriba, la esquina de arriba con el puesto 3
	ld (0e533h),a		;998e
	ld a,(0e537h)		;9991
	ld hl,0e410h		;9994
	call busca_en_la_lista		;9997
	ld a,c			;999a
	ld (0e537h),a		;999b
	xor a			;999e
	ld (0e2a4h),a		;999f
	ld hl,00026h		;99a2   ; misma X y 0x22 de alto, pegada a la banda de arriba, que esta en 0x1D
	ld (0e2a5h),hl		;99a5
	ld hl,02200h		;99a8
	ld (0e2a0h),hl		;99ab
	ld hl,00000h		;99ae
	ld (0e2a9h),hl		;99b1
	ret			;99b4

; ----------------------------------------------------------------------
; ===== EL FONDO DERECHO: lo mismo, del reves =====
; ----------------------------------------------------------------------
L_99B5:
	ld a,(0e2a1h)		;99b5   ; la porteria de este lado, entre 0x4B y 0x81 de alto
	cp 04bh		;99b8
	jp c,L_9A46		;99ba
	cp 081h		;99bd
	jp nc,L_9A46		;99bf
	ld a,(0e2aah)		;99c2   ; (0xE2AA) es lo que la pelota lleva de vuelo: por encima de 0x10 va alta
	cp 010h		;99c5
	jr c,L_99D3		;99c7
	rla			;99c9   ; y con el bit alto puesto, mas todavia
	jr c,L_99D3		;99ca
	ld a,001h		;99cc   ; (0xE565): entro por encima del larguero, y 0x9A97 se encargara de devolverla
	ld (0e565h),a		;99ce
	jr L_9A46		;99d1
L_99D3:
	ld a,(0e54fh)		;99d3   ; (0xE54F) marca que el portero esta estirado
	and a			;99d6
	jr z,L_99E8		;99d7
	ld hl,(0e2a9h)		;99d9   ; con velocidad a lo ancho aun distinta de cero...
	adc hl,hl		;99dc
	jr c,L_99E8		;99de
	jr z,L_99E8		;99e0
	ld a,(0e2abh)		;99e2   ; ...y bajando, la parada aun puede salir: no hay gol
	rla			;99e5
	jr nc,L_9A46		;99e6
L_99E8:
	ld a,002h		;99e8   ; GOL en este fondo: (0xE52E) a 2
	ld (0e52eh),a		;99ea
	ld a,006h		;99ed
	ld (0e2b4h),a		;99ef
	ld a,(0e528h)		;99f2   ; el ultimo que la toco, si lo hay...
	ld c,a			;99f5
	inc a			;99f6
	jr z,L_99FF		;99f7
	ld a,c			;99f9
	ld (0e554h),a		;99fa
	jr L_9A05		;99fd
L_99FF:
	ld a,(0e557h)		;99ff   ; ...y si no, el que la toco antes de todo
	ld (0e554h),a		;9a02
L_9A05:
	ld a,(0e280h)		;9a05   ; el gol, ya contado en el subestado 1
	dec a			;9a08
	jr z,L_9A40		;9a09
	ld hl,(0e2a7h)		;9a0b   ; sin desvio lateral el gol es directo, sin mas cuentas
	ld a,h			;9a0e
	or l			;9a0f
	jr z,L_9A40		;9a10
	ld hl,(0e2a5h)		;9a12   ; y con desvio, se mira si la pelota ya paso del pixel 0x266
	ld de,00266h		;9a15
	and a			;9a18
	sbc hl,de		;9a19
	jr c,L_9A2A		;9a1b
	inc de			;9a1d
L_9A1E:
	ld (0e2a5h),de		;9a1e   ; LA RED: la pelota se clava en el pixel 0x267 -o en el 0x12 del otro fondo- y suena el 0x47
	call borra_las_marcas_de_la_pelota		;9a22
	ld a,047h		;9a25
	jp pide_un_sonido		;9a27
L_9A2A:
	ld a,(0e2a1h)		;9a2a   ; y de paso se le recorta la altura para que no salga por encima del palo de arriba...
	cp 04bh		;9a2d
	jr nc,L_9A37		;9a2f
	ld a,04bh		;9a31
	ld (0e2a1h),a		;9a33
	ret			;9a36
L_9A37:
	cp 081h		;9a37   ; ...ni por debajo del de abajo: la pelota se queda dentro de la porteria
	ret c			;9a39
	ld a,080h		;9a3a
	ld (0e2a1h),a		;9a3c
	ret			;9a3f
L_9A40:
	ld a,002h		;9a40   ; el 2 en (0xE0F0) es el gol de este lado; el otro fondo pone un 1
	ld (0e0f0h),a		;9a42
	ret			;9a45
L_9A46:
	ld a,(0e280h)		;9a46   ; los palos de este fondo, con las mismas cuatro alturas
	and a			;9a49
	jr nz,L_9A70		;9a4a
	ld a,(0e281h)		;9a4c   ; y con (0xE281) valiendo 1
	dec a			;9a4f
	jr nz,L_9A70		;9a50
	ld a,(0e2aah)		;9a52   ; la pelota, rasa
	cp 010h		;9a55
	jr nc,L_9A70		;9a57
	ld a,(0e2a1h)		;9a59   ; y a la altura justa de uno de los cuatro pixeles de palo
	cp 04ah		;9a5c
	jp z,rebota_en_el_palo		;9a5e
	cp 049h		;9a61
	jp z,rebota_en_el_palo		;9a63
	cp 081h		;9a66
	jp z,rebota_en_el_palo		;9a68
	cp 082h		;9a6b
	jp z,rebota_en_el_palo		;9a6d
L_9A70:
	ld a,002h		;9a70   ; (0xE52F) a 2: por el fondo derecho
	ld (0e52fh),a		;9a72
	ld a,004h		;9a75
	ld (0e2b4h),a		;9a77
L_9A7A:
	ld a,(0e280h)		;9a7a   ; y el larguero de este lado
	dec a			;9a7d
	jr z,L_9ACB		;9a7e
	ld a,(0e565h)		;9a80   ; (0xE565): la pelota entro por encima del larguero
	and a			;9a83
	jr z,L_9AA8		;9a84
	ld a,(0e2ach)		;9a86   ; y ha de venir bajando...
	rla			;9a89
	jr nc,L_9AA8		;9a8a
	ld a,(0e2aah)		;9a8c   ; ...con 0x10 u 0x11 de vuelo: fuera de esa franja no hay larguero que valga
	cp 010h		;9a8f
	jr z,L_9A97		;9a91
	cp 011h		;9a93
	jr nz,L_9AA8		;9a95
L_9A97:
	ld hl,(0e2abh)		;9a97   ; negada y partida por dos: el larguero se come la mitad del empuje
	call L_A211		;9a9a
	srl h		;9a9d
	rr l		;9a9f
	ld (0e2abh),hl		;9aa1
	xor a			;9aa4
	ld (0e565h),a		;9aa5
L_9AA8:
	ld hl,(0e2a5h)		;9aa8   ; aqui el borde es el 0x27E, o sea 638
	ld de,0027eh		;9aab
	and a			;9aae
	sbc hl,de		;9aaf
	jr nc,L_9ACB		;9ab1
	ld a,(0e2a1h)		;9ab3   ; la pelota, entre 0x10 y 0xC8 de alto
	cp 010h		;9ab6
	jr c,L_9ACB		;9ab8
	cp 0c8h		;9aba
	jr nc,L_9ACB		;9abc
	ld hl,(0e2a7h)		;9abe   ; y con desvio lateral aun rueda: se encaja contra el palo
	ld a,h			;9ac1
	or l			;9ac2
	jp nz,encaja_la_pelota_en_el_palo		;9ac3
	ld a,(0e281h)		;9ac6   ; con (0xE281) en marcha, tampoco se corta
	and a			;9ac9
	ret nz			;9aca
L_9ACB:
	call pita_y_para_la_jugada		;9acb   ; SE PITA Y SE PARA
	ld a,(0e283h)		;9ace   ; la toco el segundo bando, que ataca hacia aca: esquina suya
	rra			;9ad1
	jp c,L_9B4B		;9ad2
	ld hl,00003h		;9ad5   ; y si la toco el primero, saque de puerta del segundo, que es quien defiende este fondo
	ld (0e280h),hl		;9ad8
	ld a,001h		;9adb
	ld (0e527h),a		;9add
	ld a,006h		;9ae0   ; el puesto 6, el de arriba de ese bando
	ld (0e537h),a		;9ae2
	ld a,(0e528h)		;9ae5
	and a			;9ae8
	call p,quitale_la_pelota		;9ae9
	ld a,(0e2a1h)		;9aec
	cp 070h		;9aef
	jr c,L_9B20		;9af1
	ld a,006h		;9af3   ; esquina de abajo: el puesto 8
	ld (0e533h),a		;9af5
	ld a,(0e537h)		;9af8
	inc a			;9afb
	inc a			;9afc
	ld hl,0e416h		;9afd
	call busca_en_la_lista		;9b00
	ld a,c			;9b03
	add a,006h		;9b04
	ld (0e537h),a		;9b06
	xor a			;9b09
	ld (0e2a4h),a		;9b0a
	ld hl,00252h		;9b0d   ; la pelota, en el pixel 0x252 -594- y en la banda de abajo
	ld (0e2a5h),hl		;9b10
	ld hl,0b000h		;9b13
	ld (0e2a0h),hl		;9b16
	ld hl,00000h		;9b19
	ld (0e2a9h),hl		;9b1c
	ret			;9b1f
L_9B20:
	ld a,005h		;9b20   ; y esquina de arriba con el puesto 6
	ld (0e533h),a		;9b22
	ld a,(0e537h)		;9b25   ; el puesto 6, el de arriba de este bando
	ld hl,0e416h		;9b28
	call busca_en_la_lista		;9b2b
	ld a,c			;9b2e
	add a,006h		;9b2f
	ld (0e537h),a		;9b31
	xor a			;9b34   ; la pelota queda quieta...
	ld (0e2a4h),a		;9b35
	ld hl,00252h		;9b38   ; ...en el pixel 0x252, junto a la esquina de arriba
	ld (0e2a5h),hl		;9b3b
	ld hl,02200h		;9b3e   ; y a 0x22 de alto, pegada a la banda
	ld (0e2a0h),hl		;9b41
	ld hl,00000h		;9b44
	ld (0e2a9h),hl		;9b47
	ret			;9b4a
L_9B4B:
	ld hl,00004h		;9b4b   ; saque de puerta del primer bando
	ld (0e280h),hl		;9b4e
	ld a,004h		;9b51
	ld hl,0e410h		;9b53   ; el puesto 4, el del medio
	call busca_en_la_lista		;9b56
	ld a,c			;9b59
	ld (0e537h),a		;9b5a
	xor a			;9b5d
	ld (0e527h),a		;9b5e
	ld a,(0e528h)		;9b61
	and a			;9b64
	call quitale_la_pelota		;9b65
	ld a,(0e2a1h)		;9b68
	cp 070h		;9b6b
	jr c,L_9B8B		;9b6d
	ld a,00ah		;9b6f   ; el de abajo...
	ld (0e533h),a		;9b71
	xor a			;9b74
	ld (0e2a4h),a		;9b75
	ld hl,0023ch		;9b78   ; ...con la pelota en el 0x23C -572- al lado del palo
	ld (0e2a5h),hl		;9b7b
	ld hl,08600h		;9b7e
	ld (0e2a0h),hl		;9b81
	ld hl,00000h		;9b84
	ld (0e2a9h),hl		;9b87
	ret			;9b8a
L_9B8B:
	ld a,009h		;9b8b   ; y el de arriba
	ld (0e533h),a		;9b8d
	xor a			;9b90   ; la pelota, sin nada de vuelo
	ld (0e2a4h),a		;9b91
	ld hl,0023ch		;9b94   ; en el 0x23C, al lado del palo...
	ld (0e2a5h),hl		;9b97
	ld hl,04a00h		;9b9a   ; ...y a 0x4A, que es la altura del palo de arriba
	ld (0e2a0h),hl		;9b9d
	ld hl,00000h		;9ba0
	ld (0e2a9h),hl		;9ba3
	ret			;9ba6
encaja_la_pelota_en_el_palo:		; la pega al palo mas cercano al cruzar la linea
	ld a,(0e54fh)		;9ba7   ; (0xE54F) distinto de cero: hay algo pendiente y no se toca
	and a			;9baa
	ret nz			;9bab
	ld a,(0e2a1h)		;9bac   ; la altura
	cp 04bh		;9baf   ; por encima del palo de arriba, nada que encajar
	ret c			;9bb1
	cp 081h		;9bb2   ; y por debajo del de abajo, tampoco
	ret nc			;9bb4
	cp 070h		;9bb5   ; 0x70 parte la porteria en dos mitades
	jr nc,L_9BBF		;9bb7
	ld a,04ah		;9bb9   ; en la de arriba se pega al palo de 0x4A
	ld (0e2a1h),a		;9bbb
	ret			;9bbe
L_9BBF:
	ld a,081h		;9bbf   ; y en la de abajo, al de 0x81
	ld (0e2a1h),a		;9bc1
	ret			;9bc4
quitale_la_pelota:
	call L_A201		;9bc5   ; IX a su ficha
	xor a			;9bc8
	ld (ix+014h),a		;9bc9   ; el paso que estaba dando, a cero
	ld (ix+001h),a		;9bcc
	dec a			;9bcf
	ld (0e528h),a		;9bd0   ; y (0xE528) a 0xFF: la pelota se queda sin dueno
	ret			;9bd3
pita_y_para_la_jugada:
	xor a			;9bd4
	ld (0e52fh),a		;9bd5   ; el fondo apuntado se limpia
	ld a,028h		;9bd8   ; el 0x28, el silbato
	call pide_un_sonido		;9bda
	call apaga_el_sonido_de_la_pelota		;9bdd   ; el rodar de la pelota se calla
	call borra_las_marcas_de_la_pelota		;9be0   ; y las marcas que dejo por el mapa
	ld a,00eh		;9be3
	ld (0e2b4h),a		;9be5
	xor a			;9be8
	ld (0e54fh),a		;9be9
deja_a_los_doce_quietos:
	ld ix,0e100h		;9bec   ; la primera ficha
	ld b,00ch		;9bf0   ; las doce
L_9BF2:
	ld a,(ix+00dh)		;9bf2   ; el dibujo de ahora
	cp 004h		;9bf5   ; el 4 es el de correr con la pelota...
	jr nz,L_9BFD		;9bf7
	ld (ix+00dh),000h		;9bf9   ; ...y ese se cambia por el 0, el de quieto
L_9BFD:
	ld (ix+014h),000h		;9bfd   ; y el paso a medias, cortado
	ld de,00020h		;9c01   ; 32 bytes de una ficha a la siguiente
	add ix,de		;9c04
	djnz L_9BF2		;9c06
	ret			;9c08

; ----------------------------------------------------------------------
; ----- el poste -----
; ----------------------------------------------------------------------
rebota_en_el_palo:
	call apaga_el_sonido_de_la_pelota		;9c09   ; el rodar se corta
	ld a,00bh		;9c0c   ; el 0x0B es el golpe seco contra el palo, distinto del silbato y del chut
	call pide_un_sonido		;9c0e
	ld hl,(0e2a7h)		;9c11   ; el desvio lateral
	call L_A211		;9c14   ; cambiado de signo: la pelota sale rebotada por donde vino
	ld (0e2a7h),hl		;9c17
	ret			;9c1a
guarda_el_estado_de_la_pelota:
	ld a,004h		;9c1b
	ld (0e2b4h),a		;9c1d   ; (0xE2B4) = 4
	ld hl,0e2a4h		;9c20   ; los tres bytes de la pelota se copian a 0x9E9B, para poder devolverlos luego
	ld de,0e29bh		;9c23
	ld bc,00003h		;9c26
	ldir		;9c29
	ret			;9c2b
busca_en_la_lista:		; devuelve en C el puesto que ocupa A dentro de los seis
	ld b,006h		;9c2c   ; seis, que es lo que tiene un equipo
	ld c,000h		;9c2e   ; el puesto empieza en cero
L_9C30:
	cp (hl)			;9c30
	ret z			;9c31   ; encontrado, C trae el puesto
	inc c			;9c32
	inc hl			;9c33
	djnz L_9C30		;9c34
	ret			;9c36   ; y si no esta, se vuelve con C valiendo seis

; ----------------------------------------------------------------------
; ===== A QUIEN SE LE PASA =====
; ----------------------------------------------------------------------
elige_al_companero:		; recorre los seis en circulo hasta dar con uno que se vea
	ld a,(0e280h)		;9c37
	cp 002h		;9c3a   ; solo del subestado 2 en adelante
	ret c			;9c3c
	ld a,(0e537h)		;9c3d   ; el que lleva la jugada
	ld hl,0e534h		;9c40
	cp (hl)			;9c43
	jr z,L_9C89		;9c44   ; si ya es el elegido, se pasa a buscar otro
	ld a,(0e527h)		;9c46   ; el bando
	and a			;9c49
	ld a,(0e534h)		;9c4a
	jr z,L_9C55		;9c4d
	cp 006h		;9c4f   ; de un bando valen los seis primeros...
	jr c,L_9C89		;9c51
	jr L_9C59		;9c53
L_9C55:
	cp 006h		;9c55   ; ...y del otro, los seis de arriba
	jr nc,L_9C89		;9c57
L_9C59:
	and a			;9c59
	jp m,L_9C89		;9c5a   ; con el bit alto puesto no hay elegido
	call L_A201		;9c5d
	ld a,(ix+00ah)		;9c60   ; su Y de ventana
	cp 0e0h		;9c63   ; y con 0xE0 no esta en pantalla: no se le puede pasar
	jr z,L_9C89		;9c65
	ld a,(0e527h)		;9c67
	and a			;9c6a
	ld de,0e006h		;9c6b   ; el mando de un bando...
	jr z,L_9C85		;9c6e
	ld e,008h		;9c70   ; ...o el del otro
	ld a,(0e002h)		;9c72
	and 020h		;9c75
	jr nz,L_9C85		;9c77   ; con dos humanos, cada uno elige el suyo
	ld a,(0e537h)		;9c79
	and a			;9c7c
	jp p,L_A27F		;9c7d   ; y si no, elige la maquina
	ld a,007h		;9c80
	jp L_A27F		;9c82
L_9C85:
	ld a,(de)			;9c85   ; los cuatro bits de direccion del mando
	and 00fh		;9c86
	ret z			;9c88   ; sin ninguno pulsado, el elegido se queda como esta
L_9C89:
	ld a,(0e527h)		;9c89
	and a			;9c8c
	ld de,00006h		;9c8d   ; de un bando, los puestos 0 a 5...
	jr z,L_9C95		;9c90
	ld de,0060ch		;9c92   ; ...y del otro, del 6 al 11
L_9C95:
	ld hl,0e534h		;9c95
	ld b,006h		;9c98   ; seis intentos: si ninguno vale, se deja como estaba
L_9C9A:
	inc (hl)			;9c9a   ; el siguiente de la lista
	ld a,(hl)			;9c9b
	cp d			;9c9c
	jr nc,L_9CA0		;9c9d   ; por debajo del primero...
	ld a,d			;9c9f
L_9CA0:
	cp e			;9ca0
	jr c,L_9CA4		;9ca1   ; ...o pasado el ultimo
	ld a,d			;9ca3   ; vuelve al principio del grupo: la lista es circular
L_9CA4:
	ld (hl),a			;9ca4
	exx			;9ca5
	call L_A201		;9ca6   ; IX a esa ficha
	ld a,0e0h		;9ca9
	cp (ix+00ah)		;9cab   ; si no se ve, no sirve
	jr z,L_9CB9		;9cae
	ld hl,0e537h		;9cb0
	ld a,(ix+015h)		;9cb3
	cp (hl)			;9cb6   ; y si es el que ya lleva la jugada, tampoco
	jr nz,L_9CBD		;9cb7
L_9CB9:
	exx			;9cb9
	djnz L_9C9A		;9cba
	ret			;9cbc
L_9CBD:
	ld (0e534h),a		;9cbd   ; y el primero que pasa las dos pruebas, elegido
L_9CC0:
	ret			;9cc0

; ----------------------------------------------------------------------
; ===== LOS ONCE PASOS DE UN SAQUE =====
; ----------------------------------------------------------------------
L_9CC1:
	ld a,(0e537h)		;9cc1   ; paso 0: colocarse. Aqui no se anda: se MIRA donde esta el que saca y se salta al paso que toque
	and a			;9cc4   ; sin nadie apuntado, nada que hacer
	ret m			;9cc5
	call L_A201		;9cc6   ; el que saca, a IX, y guardado en (0xE538) para los pasos siguientes
	ld (0e538h),hl		;9cc9
	ld a,(0e2a1h)		;9ccc   ; la altura de la pelota menos 0x10 es donde tiene que ponerse
	sub 010h		;9ccf
	ld ix,(0e538h)		;9cd1
	cp (ix+004h)		;9cd5   ; justo a esa altura: ya solo falta el ancho
	jr z,L_9CE1		;9cd8
	ld c,001h		;9cda   ; mas abajo, hay que subir: paso 1
	jr nc,L_9D26		;9cdc
	inc c			;9cde   ; y mas arriba, bajar: paso 2
	jr L_9D26		;9cdf
L_9CE1:
	call L_9E3B		;9ce1   ; puesto a la altura: se mide el ancho
	call distancia_a_la_pelota		;9ce4
	ld c,005h		;9ce7   ; clavado: paso 5, que es el de esperar el boton
	jr z,L_9D26		;9ce9
	ld c,004h		;9ceb   ; corto: paso 4, andar hacia adelante
	jr nc,L_9D26		;9ced
	dec c			;9cef   ; y pasado: paso 3, andar hacia atras
	jr L_9D26		;9cf0
L_9CF2:
	ld a,(0e2a1h)		;9cf2   ; paso 1: bajar hasta la altura de la pelota
	sub 010h		;9cf5
	ld ix,(0e538h)		;9cf7
	cp (ix+004h)		;9cfb   ; pasandose de la altura, se clava en ella y se pasa a medir el ancho
	jr nc,L_9D05		;9cfe
	ld (ix+004h),a		;9d00
	jr L_9D17		;9d03
L_9D05:
	ld a,(ix+004h)		;9d05   ; y si no, dos pixeles hacia abajo...
	add a,002h		;9d08
	ld (ix+004h),a		;9d0a
	call dibujo_de_correr		;9d0d   ; ...con las piernas moviendose...
	ld (ix+00ch),003h		;9d10   ; ...mirando hacia abajo -el rumbo 3-...
	jp suena_el_paso		;9d14   ; ...y con su pisada
L_9D17:
	call L_9E3B		;9d17   ; llegado a la altura, se mide el ancho igual que antes
	call distancia_a_la_pelota		;9d1a
	ld c,004h		;9d1d
	jr z,L_9D26		;9d1f
	ld c,003h		;9d21
	jr nc,L_9D26		;9d23
	dec c			;9d25
L_9D26:
	ld hl,0e281h		;9d26   ; y el paso se avanza sumando: la cuenta de 1 a 5 elegida arriba
	ld a,c			;9d29
	add a,(hl)			;9d2a
	ld (hl),a			;9d2b
	ret			;9d2c
L_9D2D:
	ld a,(0e2a1h)		;9d2d   ; paso 2: subir, que es lo mismo cambiando el signo
	sub 010h		;9d30
	ld ix,(0e538h)		;9d32
	cp (ix+004h)		;9d36
	jr c,L_9D40		;9d39
	ld (ix+004h),a		;9d3b
	jr L_9D52		;9d3e
L_9D40:
	ld a,(ix+004h)		;9d40   ; dos pixeles hacia arriba, rumbo 7
	sub 002h		;9d43
	ld (ix+004h),a		;9d45
	call dibujo_de_correr		;9d48
	ld (ix+00ch),007h		;9d4b
	jp suena_el_paso		;9d4f
L_9D52:
	call L_9E3B		;9d52   ; llegado a la altura, se mide el ancho
	call distancia_a_la_pelota		;9d55
	ld c,003h		;9d58
	jr z,L_9D61		;9d5a
	ld c,002h		;9d5c
	jr nc,L_9D61		;9d5e
	dec c			;9d60
L_9D61:
	jr L_9D26		;9d61
L_9D63:
	call L_9E3B		;9d63   ; paso 3: andar hacia atras hasta pasarse de la pelota
	call distancia_a_la_pelota		;9d66
	jr nc,L_9D7B		;9d69
	call un_pixel_atras		;9d6b   ; dos pixeles por cuadro, rumbo 5
	call un_pixel_atras		;9d6e
	call dibujo_de_correr		;9d71
	ld (ix+00ch),005h		;9d74
	jp suena_el_paso		;9d78
L_9D7B:
	ld hl,0e281h		;9d7b   ; y al llegar, dos pasos de golpe: se salta el paso 4
	inc (hl)			;9d7e
	inc (hl)			;9d7f
	ret			;9d80
L_9D81:
	call L_9E3B		;9d81   ; paso 4: andar hacia adelante
	call distancia_a_la_pelota		;9d84
	jr c,L_9D99		;9d87
	call un_pixel_adelante		;9d89   ; dos pixeles, rumbo 1
	call un_pixel_adelante		;9d8c
	call dibujo_de_correr		;9d8f
	ld (ix+00ch),001h		;9d92
	jp suena_el_paso		;9d96
L_9D99:
	ld hl,0e281h		;9d99   ; y aqui basta con uno
	inc (hl)			;9d9c
	ret			;9d9d
L_9D9E:
	ld ix,(0e538h)		;9d9e   ; paso 5: el reparto de mandos. El primer bando pasa al 6 y el segundo se salta dos y va al 8, que es la carrerilla del otro lado
	ld hl,0e281h		;9da2
	ld a,(0e527h)		;9da5
	and a			;9da8
	jr z,L_9DAD		;9da9
	inc (hl)			;9dab
	inc (hl)			;9dac
L_9DAD:
	inc (hl)			;9dad
	ret			;9dae
L_9DAF:
	ld de,0e006h		;9daf   ; paso 6 del primer bando: se espera el boton del mando 1
	ld b,000h		;9db2
	jr L_9DBB		;9db4
L_9DB6:
	ld de,0e008h		;9db6   ; y el del segundo, con el mando 2
	ld b,001h		;9db9
L_9DBB:
	ld hl,0e300h		;9dbb   ; (0xE300) cuenta lo que se lleva esperando, y al dar la vuelta se saca solo
	inc (hl)			;9dbe
	jr z,L_9DD5		;9dbf
	bit 0,b		;9dc1   ; el segundo mando ademas tiene prisa...
	jr z,L_9DD1		;9dc3
	ld a,(0e002h)		;9dc5   ; ...pero solo si no hay un segundo jugador de verdad...
	bit 5,a		;9dc8
	jr nz,L_9DD1		;9dca
	ld a,(hl)			;9dcc   ; ...y entonces a los 0x30 cuadros la maquina saca sola, sin esperar mas
	cp 030h		;9dcd
	jr z,L_9DD5		;9dcf
L_9DD1:
	ld a,(de)			;9dd1   ; el bit 4 es el boton de disparo
	and 010h		;9dd2
	ret z			;9dd4
L_9DD5:
	xor a			;9dd5   ; pulsado: se rearma la cuenta y se pasa de paso
	ld (0e300h),a		;9dd6
	ld hl,0e281h		;9dd9
	inc (hl)			;9ddc
	ld a,b			;9ddd   ; con el bando que ha sacado apuntado
	ld (0e283h),a		;9dde
	ret			;9de1
L_9DE2:
	ld (0e538h),ix		;9de2   ; paso 10: EL GOLPEO, con su 0x57
	ld a,057h		;9de6
	call pide_un_sonido		;9de8
L_9DEB:
	ld ix,(0e538h)		;9deb   ; el que saca y el objetivo, y de ahi salen las dos velocidades
	ld iy,(0e28dh)		;9def
	call mide_y_convierte		;9df3
	ld a,003h		;9df6   ; el 3 es el impacto
	call pide_un_sonido		;9df8
	ld ix,(0e538h)		;9dfb
	ld a,020h		;9dff   ; 0x20 cuadros de gracia: nadie puede tocarla en ese rato
	ld (0e544h),a		;9e01
	ld (ix+00dh),003h		;9e04   ; el dibujo 3 -el del golpeo- y el +2 a 0x10
	ld (ix+002h),010h		;9e08
	ld a,(0e284h)		;9e0c   ; el bit 1 de (0xE284) es el signo del ancho: la ficha se queda mirando hacia donde mando la pelota
	bit 1,a		;9e0f
	ld a,001h		;9e11
	jr nz,L_9E17		;9e13
	ld a,005h		;9e15
L_9E17:
	ld (ix+00ch),a		;9e17
	ld hl,00100h		;9e1a   ; y la maquina de estados se reinicia: (0xE280) a 1 y (0xE281) a 0
	ld (0e280h),hl		;9e1d
	xor a			;9e20
	ld (0e284h),a		;9e21
	ld (0e53fh),a		;9e24
L_9E27:
	xor a			;9e27   ; y esto cierra el saque: (0xE533) a cero -ya no hay saque-, (0xE537) y (0xE534) a 0xFF -ni destacado ni companero- y el que saco apuntado en (0xE542) para que no se la robe el mismo
	ld (0e533h),a		;9e28
	dec a			;9e2b
	ld hl,0e537h		;9e2c
	ld c,(hl)			;9e2f
	ld (hl),a			;9e30
	ld (0e534h),a		;9e31
	ld a,c			;9e34
	ld (0e542h),a		;9e35
	jp L_A36C		;9e38
L_9E3B:
	ld a,(0e533h)		;9e3b   ; EL LADO POR EL QUE SE SACA: con (0xE533) por debajo del corte -el 5 para un bando y el 9 para el otro- el que saca se pone 22 pixeles a la IZQUIERDA de la pelota, y si no, 22 a la derecha. Asi el golpe siempre entra hacia el campo
	cp e			;9e3e
	ld de,0ffeah		;9e3f
	ret c			;9e42
	ld de,00016h		;9e43
	ret			;9e46
distancia_a_la_pelota:		; devuelve la distancia a lo ancho entre la pelota mas DE y el jugador
	ld hl,(0e2a5h)		;9e47   ; donde esta la pelota
	add hl,de			;9e4a   ; mas el desvio que pida quien llama
	ld ix,(0e538h)		;9e4b
	ld e,(ix+006h)		;9e4f   ; menos donde esta el jugador
	ld d,(ix+007h)		;9e52
	and a			;9e55
	sbc hl,de		;9e56   ; y la bandera de acarreo dice a que lado le queda
	ret			;9e58
dibujo_de_correr:
	ld a,(0e003h)		;9e59   ; el contador de cuadros
	ld c,a			;9e5c
	and 004h		;9e5d   ; su bit 2: cuatro cuadros por zancada
	ld a,001h		;9e5f
	jr z,L_9E64		;9e61
	inc a			;9e63
L_9E64:
	ld (ix+00dh),a		;9e64   ; y el dibujo, a la ficha
	ret			;9e67
un_pixel_adelante:
	ld l,(ix+006h)		;9e68
	ld h,(ix+007h)		;9e6b
	inc hl			;9e6e   ; un pixel a lo ancho, sobre los 16 bits de la ficha
	jr L_9E78		;9e6f
un_pixel_atras:
	ld l,(ix+006h)		;9e71
	ld h,(ix+007h)		;9e74
	dec hl			;9e77   ; y aqui, uno hacia el otro lado
L_9E78:
	ld (ix+006h),l		;9e78
	ld (ix+007h),h		;9e7b
	ret			;9e7e
suena_el_paso:
	ld a,c			;9e7f
	and 007h		;9e80   ; un sonido cada ocho cuadros
	ret nz			;9e82
	ld a,049h		;9e83   ; el 0x49, la pisada
	jp pide_un_sonido		;9e85

; ----------------------------------------------------------------------
; ===== LAS DOS FLECHAS QUE SENALAN AL DESTACADO =====
; ----------------------------------------------------------------------
L_9E88:
	ld a,(0e280h)		;9e88   ; por debajo del subestado 2 -y en el 6, el del choque- las flechas se dibujan; en los demas se aparcan
	cp 002h		;9e8b
	jr c,L_9E9B		;9e8d
	cp 006h		;9e8f
	jr z,L_9E9B		;9e91
	ld hl,000e0h		;9e93   ; 0xE0 en la altura es como se aparca un sprite fuera de la pantalla
	ld (0e398h),hl		;9e96
	jr L_9EFA		;9e99
L_9E9B:
	ld a,(0e002h)		;9e9b   ; y el bit 6 de (0xE002) dice si esto es un partido o la presentacion
	bit 6,a		;9e9e
	ret z			;9ea0
	ld a,(0e52ch)		;9ea1   ; el destacado del primer mando
	call L_A201		;9ea4
	ld a,(ix+00ah)		;9ea7   ; el +0x0A es su altura en pantalla, y 0xE0 quiere decir que no se ve
	cp 0e0h		;9eaa
	jr z,L_9EC7		;9eac
	ld a,(ix+00ah)		;9eae   ; la flecha va 0x18 por ENCIMA de el
	sub 018h		;9eb1
	ld l,a			;9eb3
	ld a,(0e527h)		;9eb4   ; y a lo ancho se redondea a la casilla de 8 salvo para el bando de la camara
	rra			;9eb7
	ld a,(ix+00bh)		;9eb8
	jr nc,L_9EBF		;9ebb
	and 0f8h		;9ebd
L_9EBF:
	ld h,a			;9ebf
	ld a,0f8h		;9ec0   ; el patron 0xF8, que es el penultimo de los sprites de 16x16
	ld (0e39ah),a		;9ec2
	jr L_9ECA		;9ec5
L_9EC7:
	ld hl,000e0h		;9ec7
L_9ECA:
	ld (0e398h),hl		;9eca
	ld a,(0e002h)		;9ecd   ; y la segunda flecha solo con dos jugadores
	bit 5,a		;9ed0
	jr z,L_9EFA		;9ed2
	ld a,(0e52dh)		;9ed4
	call L_A201		;9ed7
	ld a,(ix+00ah)		;9eda
	cp 0e0h		;9edd
	jr z,L_9EFA		;9edf
	ld a,(ix+00ah)		;9ee1   ; esta va 0x18 por DEBAJO, para no confundirlas
	add a,018h		;9ee4
	ld l,a			;9ee6
	ld a,(0e527h)		;9ee7
	rra			;9eea
	ld a,(ix+00bh)		;9eeb
	jr c,L_9EF2		;9eee
	and 0f8h		;9ef0
L_9EF2:
	ld h,a			;9ef2
	ld a,0fch		;9ef3   ; con el patron 0xFC, el ultimo
	ld (0e39eh),a		;9ef5
	jr L_9EFD		;9ef8
L_9EFA:
	ld hl,000e0h		;9efa   ; sin nada que senalar, aparcada
L_9EFD:
	ld (0e39ch),hl		;9efd
	ret			;9f00
L_9F01:
	ld a,(0e527h)		;9f01   ; los dos porteros: el de un lado en 0xE330 y el del otro en 0xE350
	rra			;9f04
	ld hl,0e330h		;9f05
	jr nc,L_9F0D		;9f08
	ld hl,0e350h		;9f0a
L_9F0D:
	ld (0e538h),hl		;9f0d
	ld ix,(0e538h)		;9f10
	ret			;9f14
L_9F15:
	ld a,(0e527h)		;9f15   ; subestado 5: el saque de centro despues de un gol
	rra			;9f18
	ld c,001h		;9f19
	jr c,L_9F1F		;9f1b
	ld c,000h		;9f1d
L_9F1F:
	ld ix,(0e538h)		;9f1f
	ld hl,0e53fh		;9f23   ; (0xE53F) cuenta hacia atras y solo al llegar a 3 se saca
	ld a,(hl)			;9f26
	sub 003h		;9f27
	ret nz			;9f29
	ld (hl),a			;9f2a
	ld a,c			;9f2b
	ld (0e283h),a		;9f2c
	ld a,057h		;9f2f   ; el 0x57 del golpe
	call pide_un_sonido		;9f31
	call borra_las_marcas_de_la_pelota		;9f34
	ld ix,(0e538h)		;9f37
	ld iy,(0e28dh)		;9f3b
	call mide_y_convierte		;9f3f
	xor a			;9f42
	ld (0e284h),a		;9f43
	ld a,005h		;9f46
	call pide_un_sonido		;9f48
	ld hl,00100h		;9f4b   ; y otra vez a 1 y 0, con sus 0x20 cuadros de gracia
	ld (0e280h),hl		;9f4e
	ld a,020h		;9f51
	ld (0e544h),a		;9f53
	ld a,080h		;9f56   ; 0x80 en (0xE542) es "la toco algo que no es una ficha": asi nadie carga con el saque
	ld (0e542h),a		;9f58
	ld a,0ffh		;9f5b
	ld (0e534h),a		;9f5d
	ret			;9f60
L_9F61:
	ld a,b			;9f61
	call despacha		;9f62

; ----------------------------------------------------------------------
; DATOS los_once_pasos_del_saque_del_segundo_bando: 11 entradas, la entrada 4
;   de la tabla de 0x8C70 y gemela de la de 0x91B0: las mismas rutinas, con el
;   9 en vez del 5 como corte de 0x9E3B y la carrerilla al otro lado
;   0x9f65..0x9f7b  (22 bytes)
DATA_los_once_pasos_del_saque_del_segundo_bando:
	defw 09f7bh,09f80h,09f85h,09f8ah,09f8fh,09f94h,09f97h,09fabh	; 9f65
	defw 09fd0h,09fe4h,0a008h	; 9f75  -> L_9FD0 L_9FE4 L_A008

; ======================================================================
; CODIGO 0x9f7b..0xa2b9  (830 bytes)
; ======================================================================


L_9F7B:
	ld e,009h		;9f7b
	jp L_9CC1		;9f7d
L_9F80:
	ld e,009h		;9f80
	jp L_9CF2		;9f82
L_9F85:
	ld e,009h		;9f85
	jp L_9D2D		;9f87
L_9F8A:
	ld e,009h		;9f8a
	jp L_9D63		;9f8c
L_9F8F:
	ld e,009h		;9f8f
	jp L_9D81		;9f91
L_9F94:
	jp L_9D9E		;9f94
L_9F97:
	ld ix,(0e538h)		;9f97   ; paso 6 del segundo bando, el que saca del otro lado
	ld (ix+00ch),005h		;9f9b
	ld (ix+00dh),000h		;9f9f
	ld a,(0e549h)		;9fa3   ; (0xE549) lo pone 0xB427: el portero ya esta colocado. Hasta entonces el saque no arranca
	rra			;9fa6
	ret nc			;9fa7
	jp L_9DAF		;9fa8
L_9FAB:
	ld ix,(0e538h)		;9fab   ; paso 7: la carrerilla, dieciseis cuadros hacia atras
	ld hl,0e54eh		;9faf
	inc (hl)			;9fb2
	ld a,(hl)			;9fb3
	cp 010h		;9fb4
	jr z,L_9FC3		;9fb6
	call un_pixel_atras		;9fb8
	call dibujo_de_correr		;9fbb
	ld (ix+00ch),005h		;9fbe
	ret			;9fc2
L_9FC3:
	ld (hl),000h		;9fc3   ; cumplidos, el 0x57 y salto derecho al paso 10
	ld a,057h		;9fc5
	call pide_un_sonido		;9fc7
	ld a,00ah		;9fca
	ld (0e281h),a		;9fcc
	ret			;9fcf
L_9FD0:
	ld ix,(0e538h)		;9fd0   ; paso 8: prepararse para la carrerilla del otro lado
	ld (ix+00ch),001h		;9fd4
	ld (ix+00dh),000h		;9fd8
	ld a,(0e549h)		;9fdc
	rra			;9fdf
	ret nc			;9fe0
	jp L_9DB6		;9fe1
L_9FE4:
	ld ix,(0e538h)		;9fe4   ; paso 9: y esa carrerilla, hacia adelante
	ld hl,0e54eh		;9fe8
	inc (hl)			;9feb
	ld a,(hl)			;9fec
	cp 010h		;9fed
	jr z,L_9FFC		;9fef
	call un_pixel_adelante		;9ff1
	call dibujo_de_correr		;9ff4
	ld (ix+00ch),001h		;9ff7
	ret			;9ffb
L_9FFC:
	ld (hl),000h		;9ffc   ; cumplidos los dieciseis cuadros de carrerilla
	ld a,057h		;9ffe
	call pide_un_sonido		;a000
	ld hl,0e281h		;a003
	inc (hl)			;a006
	ret			;a007
L_A008:
	call L_9DEB		;a008   ; paso 10: el golpeo, y de paso se suelta al portero
	xor a			;a00b
	ld (0e549h),a		;a00c
	ret			;a00f

; ----------------------------------------------------------------------
; ===== LA FORMACION =====
; ----------------------------------------------------------------------
un_cuadro_de_la_tactica:
	ld hl,0e556h		;a010   ; (0xE556) reparte el trabajo entre cuadros
	inc (hl)			;a013
	ld a,(hl)			;a014
	sub 006h		;a015   ; seis puestos, y vuelta a empezar
	jr c,L_A01A		;a017
	ld (hl),a			;a019
L_A01A:
	ld a,(0e280h)		;a01a
	cp 007h		;a01d   ; en el subestado 7 no hay tactica que valga
	ret z			;a01f
	ld hl,(0e531h)		;a020   ; (0xE531) es el cerrojo de la jugada
	ld a,h			;a023
	dec a			;a024
	ret z			;a025
	ld a,l			;a026
	cp 00ah		;a027   ; y por encima de 10 tampoco se recoloca a nadie
	ret nc			;a029
	call L_A3CE		;a02a
	call recalcula_un_puesto		;a02d
	call coloca_a_un_defensa		;a030
	call separa_a_los_companeros_del_destacado		;a033
	call mueve_a_los_doce_a_su_sitio		;a036
	ld a,(0e532h)		;a039   ; (0xE532) distingue el juego en marcha de las pausas
	dec a			;a03c
	jp z,da_un_paso_cada_jugador		;a03d   ; y en pausa se salta las dos de mover
	call L_A18A		;a040
	call L_A1BF		;a043
	jp da_un_paso_cada_jugador		;a046
recalcula_un_puesto:
	ld a,(0e280h)		;a049   ; del subestado 2 en adelante la formacion la lleva otra rutina
	cp 002h		;a04c
	jp nc,recoloca_segun_el_subestado		;a04e
L_A051:
	ld a,(0e527h)		;a051
	and a			;a054   ; el bando
	jr nz,L_A063		;a055
	ld de,0e116h		;a057   ; el +0x16 de la primera ficha de un bando, que es donde vive el destino
	ld ix,0e410h		;a05a   ; su lista de seis
	ld hl,0a880h		;a05e   ; y su tabla de formaciones
	jr L_A06D		;a061
L_A063:
	ld ix,0e416h		;a063   ; y lo mismo para el otro bando, con su propia tabla
	ld de,0e1d6h		;a067
	ld hl,0a934h		;a06a
L_A06D:
	ld a,(0e556h)		;a06d   ; el puesto que toca en este cuadro
	ld c,a			;a070
	ld b,000h		;a071
	add ix,bc		;a073   ; se avanza en la lista
	ld a,(0e556h)		;a075
	add a,a			;a078   ; por 32: de una ficha a la siguiente
	add a,a			;a079
	add a,a			;a07a
	add a,a			;a07b
	add a,a			;a07c
	call suma_a_de		;a07d
	ld a,(0e52bh)		;a080   ; (0xE52B) es la situacion del partido
	add a,a			;a083   ; por doce, que es lo que ocupa una formacion: seis parejas
	add a,a			;a084
	ld c,a			;a085
	add a,a			;a086
	add a,c			;a087
	ld c,a			;a088
	ld b,000h		;a089
	add hl,bc			;a08b
L_A08C:
	ld a,(ix+000h)		;a08c   ; el puesto del jugador dentro de la formacion
	add a,a			;a08f   ; por dos, que es lo que ocupa una entrada
	cp 00ch		;a090   ; doce entradas...
	jr c,L_A096		;a092
	sub 00ch		;a094   ; ...y se da la vuelta: la formacion es circular
L_A096:
	inc ix		;a096
	call suma_a_hl		;a098
	ld a,(hl)			;a09b   ; el primer byte es la altura de destino
	ld c,a			;a09c
	inc hl			;a09d
	ld (de),a			;a09e   ; que va al +0x16 de la ficha
	inc de			;a09f
	ld l,(hl)			;a0a0   ; y el segundo byte...
	ld h,000h		;a0a1
	add hl,hl			;a0a3   ; ...por dieciseis: el ancho se guarda con mas resolucion
	add hl,hl			;a0a4
	add hl,hl			;a0a5
	add hl,hl			;a0a6
	ex de,hl			;a0a7
	ld (hl),e			;a0a8   ; al +0x17 y +0x18
	inc l			;a0a9
	ld (hl),d			;a0aa
	ex de,hl			;a0ab
	ld a,(0e280h)		;a0ac
	cp 002h		;a0af   ; solo en el subestado 2
	ret nz			;a0b1
	ld a,c			;a0b2
	ld c,038h		;a0b3   ; 0x38 es el borde de arriba
	cp c			;a0b5
	jr c,L_A0BC		;a0b6
	ld c,080h		;a0b8   ; y 0x80 el de abajo
	cp c			;a0ba
	ret c			;a0bb   ; dentro de esa franja, el destino vale tal cual
L_A0BC:
	ld a,c			;a0bc
	dec e			;a0bd   ; y si no, se recorta al borde: nadie se planta fuera del campo
	dec e			;a0be
	ld (de),a			;a0bf
	inc e			;a0c0
	inc e			;a0c1
	ret			;a0c2
coloca_a_los_seis:		; recalcula la formacion entera de un bando de golpe
	ld de,0e116h		;a0c3   ; el destino de la primera ficha
	ld ix,0e410h		;a0c6   ; su lista
	ld hl,0a880h		;a0ca   ; y su tabla
	ld a,(0e527h)		;a0cd
	and a			;a0d0
	jr z,L_A0DC		;a0d1   ; o las del otro bando
	ld ix,0e416h		;a0d3
	ld e,0d6h		;a0d7
	ld hl,0a934h		;a0d9
L_A0DC:
	ld a,(0e52bh)		;a0dc   ; la situacion, por doce
	add a,a			;a0df
	add a,a			;a0e0
	ld c,a			;a0e1
	add a,a			;a0e2
	add a,c			;a0e3
	call suma_a_hl		;a0e4
L_A0E7:
	exx			;a0e7
	ld b,006h		;a0e8   ; los seis puestos
L_A0EA:
	exx			;a0ea
	push hl			;a0eb
	call L_A08C		;a0ec
	pop hl			;a0ef
	ld a,01eh		;a0f0   ; y 0x1E mas los dos que ya avanzo dan los 32 de una ficha
	call suma_a_de		;a0f2
	exx			;a0f5
	djnz L_A0EA		;a0f6
	ret			;a0f8
mueve_a_los_doce_a_su_sitio:
	ld ix,0e100h		;a0f9   ; la primera ficha
	exx			;a0fd
	ld b,00ch		;a0fe   ; las doce, incluidos los dos bandos
L_A100:
	exx			;a100
	call acerca_uno_a_su_destino		;a101
	ld de,00020h		;a104   ; 32 bytes por ficha
	add ix,de		;a107
	exx			;a109
	djnz L_A100		;a10a
	ret			;a10c
acerca_uno_a_su_destino:
	bit 7,(ix+000h)		;a10d   ; con el bit 7 del +0 puesto, esta ficha no se mueve sola
	ret nz			;a111
	ld a,(ix+001h)		;a112   ; y con el +1 distinto de cero, tampoco
	and a			;a115
	ret nz			;a116
	ld a,(0e280h)		;a117
	cp 002h		;a11a   ; del subestado 2 en adelante se mueven todos
	jr nc,L_A129		;a11c
	ld a,(ix+015h)		;a11e   ; y por debajo, se mira el numero del jugador
	ld hl,0e52ch		;a121   ; contra los dos destacados
	cp (hl)			;a124
	ret z			;a125   ; y al que lleva un mando NO se le mueve solo: ese lo llevas tu
	inc l			;a126
	cp (hl)			;a127
	ret z			;a128
L_A129:
	ld a,(ix+01ah)		;a129   ; el +0x1A es una espera
	and a			;a12c
	jr z,L_A137		;a12d
	dec (ix+01ah)		;a12f   ; mientras quede, se gasta
	ld (ix+003h),000h		;a132   ; y el jugador se queda sin direccion, o sea parado
	ret			;a136
L_A137:
	ld hl,0a5dch		;a137   ; la vuelta se apila: se sale por 0xA5DC
	push hl			;a13a
L_A13B:
	ld l,(ix+006h)		;a13b   ; el ancho de ahora
	ld h,(ix+007h)		;a13e
	ld e,(ix+017h)		;a141   ; y el ancho de destino
	ld d,(ix+018h)		;a144
	and a			;a147
	sbc hl,de		;a148   ; la diferencia
	ld e,002h		;a14a   ; E lleva el sentido: 2 hacia un lado...
	jr nc,L_A152		;a14c
	call L_A211		;a14e   ; ...y si es negativo se niega
	dec e			;a151   ; y 1 hacia el otro
L_A152:
	ld a,h			;a152
	and a			;a153
	jr nz,L_A15D		;a154   ; con byte alto, la distancia es grande
	ld a,l			;a156
	cp 008h		;a157   ; y por debajo de ocho pixeles
	jr nc,L_A15D		;a159
	ld e,000h		;a15b   ; se da por llegado: E a cero
L_A15D:
	ld a,(ix+004h)		;a15d   ; ahora la altura
	sub (ix+016h)		;a160   ; menos la de destino
	ld d,004h		;a163
	jr nc,L_A16B		;a165
	ld d,008h		;a167
	neg		;a169
L_A16B:
	cp 010h		;a16b
	jr nc,L_A171		;a16d
	ld d,000h		;a16f

; ----------------------------------------------------------------------
; ===== EL PASO DEL JUGADOR: lo que queda =====
; ----------------------------------------------------------------------
L_A171:
	ld a,d			;a171   ; los dos bits de mando juntos indexan la tabla de 0xA47B, que traduce mando a rumbo
	or e			;a172
	ld hl,0a47bh		;a173
	call suma_a_hl		;a176
	ld a,(hl)			;a179
	ld c,a			;a17a
	and 00fh		;a17b   ; el nibble bajo es el rumbo, y va al +3
	ld (ix+003h),a		;a17d
	ret nz			;a180
	ld (ix+00dh),000h		;a181   ; sin rumbo -parado- se le pone el dibujo 0 y el +2 a 8
	ld (ix+002h),008h		;a185
	ret			;a189
L_A18A:
	ld a,(0e280h)		;a18a   ; solo en el subestado 1, o sea con la pelota en poder de alguien
	dec a			;a18d
	ret nz			;a18e
	ld a,(0e528h)		;a18f   ; el que la lleva
	call L_A201		;a192
	ld a,(0e002h)		;a195   ; y con dos jugadores nadie decide por el
	and 020h		;a198
	jr nz,L_A1A7		;a19a
	push ix		;a19c
	ld a,(0e527h)		;a19e   ; y con uno, el bando 1 lo lleva la maquina
	and a			;a1a1
	call nz,la_maquina_lleva_la_pelota		;a1a2
	pop ix		;a1a5
L_A1A7:
	call mueve_la_pelota_con_el_que_la_lleva		;a1a7   ; la pelota va pegada al que la lleva
	ld a,(0e53ah)		;a1aa   ; (0xE53A) es el rumbo que se le supone a la pelota: el 0 -parado-, el 1 y el 5 no dan lado
	and a			;a1ad
	ret z			;a1ae
	cp 001h		;a1af
	ret z			;a1b1
	cp 005h		;a1b2
	ret z			;a1b4
	ld c,000h		;a1b5   ; y los demas si: (0xE53E) queda a 0 o a 1 segun a que lado la lleva
	jr nc,L_A1BA		;a1b7
	inc c			;a1b9
L_A1BA:
	ld a,c			;a1ba
	ld (0e53eh),a		;a1bb
	ret			;a1be
L_A1BF:
	ld a,(0e280h)		;a1bf   ; por debajo del subestado 2, o sea con el juego en marcha
	cp 002h		;a1c2
	ret nc			;a1c4
	ld a,(0e528h)		;a1c5   ; el que lleva la pelota...
	ld c,a			;a1c8
	ld a,(0e52ch)		;a1c9   ; ...y si ya es el destacado del primer mando, ese mando no manda dos veces
	cp c			;a1cc
	jr z,L_A1EA		;a1cd
	ld a,(0e53ch)		;a1cf   ; (0xE53C) por encima de 0xC0 es que acaba de haber cambio de jugador
	cp 0c0h		;a1d2
	jr c,L_A1DC		;a1d4
	ld a,(0e527h)		;a1d6
	and a			;a1d9
	jr nz,L_A1EA		;a1da
L_A1DC:
	ld a,(0e52ch)		;a1dc   ; y entonces el mando se le lee igual, salvo que sea el mismo
	cp c			;a1df
	jr z,L_A1EA		;a1e0
	push bc			;a1e2
	call L_A201		;a1e3
	call lee_el_mando_del_jugador		;a1e6
	pop bc			;a1e9
L_A1EA:
	ld a,(0e53ch)		;a1ea   ; lo mismo para el segundo mando
	cp 0c0h		;a1ed
	jr c,L_A1F6		;a1ef
	ld a,(0e527h)		;a1f1
	and a			;a1f4
	ret z			;a1f5
L_A1F6:
	ld a,(0e52dh)		;a1f6
	cp c			;a1f9
	ret z			;a1fa
	call L_A201		;a1fb
	jp lee_el_mando_del_jugador		;a1fe
L_A201:
	add a,a			;a201   ; DE UN NUMERO DE FICHA A SU BLOQUE: por 32 en cinco dobleces, cuatro en A y el quinto ya en HL, sobre 0xE100
	add a,a			;a202
	add a,a			;a203
	add a,a			;a204
	ld l,a			;a205   ; el quinto doblez ya en HL, que en A no cabria
	ld h,000h		;a206
	add hl,hl			;a208
	ld de,0e100h		;a209   ; y sobre 0xE100, donde empieza la primera ficha
	add hl,de			;a20c
	push hl			;a20d
	pop ix		;a20e
	ret			;a210
L_A211:
	ld a,l			;a211   ; y esta niega HL: complemento a uno mas uno, que el Z80 no tiene `neg hl`
	cpl			;a212
	ld l,a			;a213
	ld a,h			;a214
	cpl			;a215
	ld h,a			;a216
	inc hl			;a217
	ret			;a218

; ----------------------------------------------------------------------
; ===== LAS QUINCE ZONAS DEL CAMPO =====
; ----------------------------------------------------------------------
en_que_zona_esta_la_pelota:
	ld c,000h		;a219
	ld hl,(0e2a5h)		;a21b   ; la posicion de la pelota a lo ancho
	ld de,000d0h		;a21e   ; la primera raya, en 0xD0
	and a			;a221
	sbc hl,de		;a222
	jr c,L_A240		;a224   ; por delante de ella, zona 0
	ld c,003h		;a226   ; la segunda franja
	ld e,030h		;a228   ; y la raya siguiente, 0x30 mas alla
	sbc hl,de		;a22a
	jr c,L_A240		;a22c
	ld c,006h		;a22e   ; la tercera
	ld e,080h		;a230   ; con 0x80 de ancho: la del medio del campo es la mas larga
	sbc hl,de		;a232
	jr c,L_A240		;a234
	ld c,009h		;a236   ; la cuarta
	ld e,030h		;a238
	sbc hl,de		;a23a
	jr c,L_A240		;a23c
	ld c,00ch		;a23e   ; y la quinta, la del otro fondo
L_A240:
	ld a,(0e2a1h)		;a240   ; y ahora lo alto
	cp 049h		;a243   ; 0x49 es la raya de arriba...
	jr c,L_A24D		;a245
	inc c			;a247   ; ...y suma uno a la zona
	cp 078h		;a248   ; 0x78 la de abajo
	jr c,L_A24D		;a24a
	inc c			;a24c   ; y otro uno: tres franjas a lo alto por las cinco de ancho, quince en total
L_A24D:
	ld hl,0e52bh		;a24d
	ld (hl),c			;a250   ; y en (0xE52B) queda la zona, que es lo que elige la formacion
	ret			;a251
reparte_el_destacado:
	ld a,(0e534h)		;a252   ; el companero elegido
	ld hl,0e52ch		;a255
	cp 006h		;a258   ; los seis primeros son de un bando...
	jr c,L_A25D		;a25a
	inc l			;a25c   ; ...y del sexto en adelante, del otro
L_A25D:
	ld (hl),a			;a25d
	cp 006h		;a25e
	ret nc			;a260
	add a,006h		;a261   ; mas seis: el mismo puesto en el bando contrario
	ld c,a			;a263
	ld a,(0e002h)		;a264
	and 020h		;a267   ; el bit 5 de (0xE002): con dos humanos, cada uno se lleva el suyo
	ret nz			;a269
	inc l			;a26a
	ld (hl),c			;a26b   ; y con uno solo, el otro bando toma el mismo puesto
	ret			;a26c
la_maquina_elige_companero:
	ld a,(0e299h)		;a26d   ; con el boton mantenido no se cambia de companero
	and a			;a270
	ret nz			;a271
	ld a,(0e547h)		;a272   ; ni con un golpe en marcha
	dec a			;a275
	ret z			;a276
L_A277:
	ld a,(0e280h)		;a277
	dec a			;a27a   ; solo en el subestado 1
	ret nz			;a27b
	ld a,(0e528h)		;a27c   ; y se parte de quien lleva la pelota
L_A27F:
	ld hl,0e410h		;a27f   ; su puesto dentro de la lista
	call suma_a_hl		;a282
	ld a,(hl)			;a285
	ld hl,0a2b9h		;a286   ; la tabla de 0xA2B9
	call suma_a_hl		;a289
	ld a,(0e53eh)		;a28c   ; (0xE53E) elige que nibble se mira
	and a			;a28f
	ld a,(hl)			;a290
	jr nz,L_A297		;a291
	rra			;a293   ; cuatro giros: el nibble alto
	rra			;a294
	rra			;a295
	rra			;a296
L_A297:
	and 00fh		;a297   ; y se queda con cuatro bits: hasta dieciseis opciones
	ld c,a			;a299
	add a,a			;a29a   ; por cinco, que es lo que ocupa cada lista de candidatos
	add a,a			;a29b
	add a,c			;a29c
	ld hl,0a2c5h		;a29d   ; la tabla de listas
	call suma_a_hl		;a2a0
	ld b,005h		;a2a3   ; cinco candidatos por lista
L_A2A5:
	ld a,(hl)			;a2a5
	ld de,0e430h		;a2a6   ; la lista de 0xE430
	call suma_a_de		;a2a9
	ld a,(de)			;a2ac
	bit 7,a		;a2ad   ; con el bit alto puesto ese candidato no vale
	jr z,L_A2B5		;a2af
	inc l			;a2b1
	djnz L_A2A5		;a2b2   ; y se prueba el siguiente
	ret			;a2b4
L_A2B5:
	ld (0e534h),a		;a2b5   ; el primero que vale, elegido
	ret			;a2b8

; ----------------------------------------------------------------------
; DATOS listas_de_pase: doce bytes con dos nibbles cada uno, uno por dorsal, y
;   detras dieciseis grupos de cinco candidatos: a quien se le pasa el balon
;   0xa2b9..0xa315  (92 bytes)
DATA_listas_de_pase:
	defb 000h	; a2b9
	defb 012h	; a2ba
	defb 033h	; a2bb
	defb 044h	; a2bc
	defb 056h	; a2bd
	defb 077h	; a2be
	defb 088h	; a2bf
	defb 09ah	; a2c0
	defb 0bbh	; a2c1
	defb 0cch	; a2c2
	defb 0deh	; a2c3
	defb 0ffh	; a2c4
	defb 001h	; a2c5
	defb 002h	; a2c6
	defb 004h	; a2c7
	defb 005h	; a2c8
	defb 003h	; a2c9
	defb 000h	; a2ca
	defb 002h	; a2cb
	defb 003h	; a2cc
	defb 005h	; a2cd
	defb 004h	; a2ce
	defb 002h	; a2cf
	defb 000h	; a2d0
	defb 005h	; a2d1
	defb 003h	; a2d2
	defb 004h	; a2d3
	defb 001h	; a2d4
	defb 000h	; a2d5
	defb 004h	; a2d6
	defb 003h	; a2d7
	defb 005h	; a2d8
	defb 001h	; a2d9
	defb 002h	; a2da
	defb 000h	; a2db
	defb 004h	; a2dc
	defb 005h	; a2dd
	defb 000h	; a2de
	defb 002h	; a2df
	defb 001h	; a2e0
	defb 003h	; a2e1
	defb 005h	; a2e2
	defb 002h	; a2e3
	defb 000h	; a2e4
	defb 001h	; a2e5
	defb 005h	; a2e6
	defb 003h	; a2e7
	defb 001h	; a2e8
	defb 000h	; a2e9
	defb 002h	; a2ea
	defb 004h	; a2eb
	defb 003h	; a2ec
	defb 00ah	; a2ed
	defb 00bh	; a2ee
	defb 009h	; a2ef
	defb 007h	; a2f0
	defb 008h	; a2f1
	defb 009h	; a2f2
	defb 00bh	; a2f3
	defb 00ah	; a2f4
	defb 006h	; a2f5
	defb 008h	; a2f6
	defb 00bh	; a2f7
	defb 009h	; a2f8
	defb 00ah	; a2f9
	defb 008h	; a2fa
	defb 006h	; a2fb
	defb 00ah	; a2fc
	defb 009h	; a2fd
	defb 00bh	; a2fe
	defb 007h	; a2ff
	defb 006h	; a300
	defb 00ah	; a301
	defb 00bh	; a302
	defb 007h	; a303
	defb 008h	; a304
	defb 006h	; a305
	defb 009h	; a306
	defb 00bh	; a307
	defb 006h	; a308
	defb 008h	; a309
	defb 007h	; a30a
	defb 00bh	; a30b
	defb 009h	; a30c
	defb 008h	; a30d
	defb 006h	; a30e
	defb 007h	; a30f
	defb 00ah	; a310
	defb 009h	; a311
	defb 007h	; a312
	defb 006h	; a313
	defb 008h	; a314

; ======================================================================
; CODIGO 0xa315..0xa45d  (328 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL CAMBIO DE JUGADOR =====
; ----------------------------------------------------------------------
cambia_de_jugador_con_el_boton:
	ld a,(0e532h)		;a315
	and a			;a318   ; (0xE532) distinto de cero: el juego esta parado
	ret nz			;a319
	ld a,(0e280h)		;a31a
	cp 002h		;a31d   ; y del subestado 2 en adelante tampoco se cambia
	ret nc			;a31f
	ld a,(0e006h)		;a320   ; los bits 4 y 5 del mando 1: cualquiera de los dos botones
	and 030h		;a323
	jr z,L_A33C		;a325   ; sin pulsar, no hay cambio
	ld ix,0e100h		;a327   ; las fichas del primer bando
	ld bc,00000h		;a32b
	call busca_al_mas_cercano_a_la_pelota		;a32e   ; se busca al mas cercano a la pelota
	jr c,L_A33C		;a331
	ld a,(0e2d2h)		;a333   ; y ese pasa a ser el destacado
	ld hl,0e52ch		;a336
	call L_A366		;a339
L_A33C:
	ld a,(0e002h)		;a33c
	and 020h		;a33f   ; el bit 5 de (0xE002): si hay segundo humano...
	jr nz,L_A34F		;a341
	ld a,(0e280h)		;a343
	dec a			;a346
	ret z			;a347   ; ...y si no, en el subestado 1 no se hace
	ld a,(0e2aah)		;a348   ; ni con la pelota en el aire
	and a			;a34b
	ret nz			;a34c
	jr L_A355		;a34d
L_A34F:
	ld a,(0e008h)		;a34f   ; el mando 2, con sus dos botones
	and 030h		;a352
	ret z			;a354
L_A355:
	ld bc,00106h		;a355   ; el segundo bando empieza en el puesto 6
	ld ix,0e1c0h		;a358   ; y en la ficha 0xE1C0
	call busca_al_mas_cercano_a_la_pelota		;a35c
	ret c			;a35f
	ld a,(0e2d2h)		;a360
	ld hl,0e52dh		;a363
L_A366:
	cp (hl)			;a366   ; si ya era el destacado, no hay nada que hacer
	ret z			;a367
	ld (hl),a			;a368
	call L_A201		;a369   ; y al nuevo se le limpia el paso a medias
L_A36C:
	xor a			;a36c
	ld (ix+001h),a		;a36d   ; el +1 a cero...
	ld (ix+003h),a		;a370   ; ...y la direccion tambien: entra parado
	ret			;a373
busca_al_mas_cercano_a_la_pelota:
	ld a,(0e280h)		;a374
	dec a			;a377   ; en el subestado 1...
	jr nz,L_A380		;a378
	ld a,(0e527h)		;a37a
	cp b			;a37d   ; ...el bando al que sigue la camara no cambia de jugador
	scf			;a37e
	ret z			;a37f
L_A380:
	ld hl,0ffffh		;a380   ; (0xE2D0) arranca en 0xFFFF: la distancia mas grande posible
	ld (0e2d0h),hl		;a383
	ld b,006h		;a386   ; los seis del bando
L_A388:
	ld a,(ix+00ah)		;a388   ; su Y de ventana
	cp 0e0h		;a38b   ; con 0xE0 no esta en pantalla y no se le puede elegir
	jr z,L_A3C1		;a38d
	ld hl,(0e2a5h)		;a38f   ; la pelota, a lo ancho
	ld e,(ix+006h)		;a392
	ld d,(ix+007h)		;a395
	and a			;a398
	sbc hl,de		;a399   ; menos el jugador
	call c,L_A211		;a39b   ; en valor absoluto
	ld a,(0e2a1h)		;a39e
	sub 00eh		;a3a1   ; la altura de la pelota, menos 0x0E
	sub (ix+004h)		;a3a3   ; menos la del jugador
	jr nc,L_A3AA		;a3a6
	neg		;a3a8   ; tambien en valor absoluto
L_A3AA:
	add a,l			;a3aa   ; y las dos se SUMAN: la distancia se mide en cruz, que es mas barato que un cuadrado
	ld l,a			;a3ab
	jr nc,L_A3AF		;a3ac
	inc h			;a3ae
L_A3AF:
	ld de,(0e2d0h)		;a3af
	and a			;a3b3
	push hl			;a3b4
	sbc hl,de		;a3b5   ; contra la mejor de hasta ahora
	pop hl			;a3b7
	jr nc,L_A3C1		;a3b8   ; si no mejora, se pasa al siguiente
	ld (0e2d0h),hl		;a3ba   ; y si mejora, se apunta la distancia...
	ld a,c			;a3bd
	ld (0e2d2h),a		;a3be   ; ...y el puesto del jugador
L_A3C1:
	inc c			;a3c1
	ld de,00020h		;a3c2   ; la ficha siguiente
	add ix,de		;a3c5
	djnz L_A388		;a3c7
	inc h			;a3c9
	scf			;a3ca
	ret z			;a3cb
	xor a			;a3cc
	ret			;a3cd

; ----------------------------------------------------------------------
; ===== QUIEN OCUPA CADA PUESTO =====
; ----------------------------------------------------------------------
L_A3CE:
	ld a,(0e280h)		;a3ce   ; solo con la pelota en juego
	dec a			;a3d1
	ret nz			;a3d2
	ld a,(0e527h)		;a3d3   ; cada bando tiene su lista de seis y su tabla de zonas
	ld hl,0e410h		;a3d6
	ld de,0a45dh		;a3d9
	and a			;a3dc
	jr z,L_A3E4		;a3dd
	ld l,016h		;a3df
	ld de,0a46ch		;a3e1
L_A3E4:
	ld a,(0e52bh)		;a3e4   ; la zona en que esta la pelota dice que puesto tiene que llevarla
	call suma_a_de		;a3e7
	ld a,(de)			;a3ea
	ld c,a			;a3eb
	ld a,(0e528h)		;a3ec   ; el que la lleva, pasado a numero dentro de su bando
	cp 006h		;a3ef
	jr c,L_A3F5		;a3f1
	sub 006h		;a3f3
L_A3F5:
	push hl			;a3f5   ; el puesto que lleva ahora
	add a,l			;a3f6
	ld l,a			;a3f7
	ld a,(hl)			;a3f8
	pop hl			;a3f9
	cp c			;a3fa   ; si ya es el que la zona pide, no hay nada que cambiar
	ret z			;a3fb
	ld e,a			;a3fc
	ld b,006h		;a3fd
L_A3FF:
	ld a,(hl)			;a3ff
	cp c			;a400   ; C es el puesto que la zona pide; se recorre la lista de seis buscandolo
	call z,pon_el_puesto_del_que_la_lleva		;a401   ; al que lo tenia se le da el del que lleva la pelota...
	cp e			;a404   ; ...y al que tenia el del que la lleva...
	call z,pon_el_puesto_de_la_zona		;a405   ; ...el de la zona: un intercambio limpio, sin tocar a los otros cuatro
	inc l			;a408
	djnz L_A3FF		;a409   ; los seis del bando

; ----------------------------------------------------------------------
; ----- y el bando de enfrente copia la misma lista, corrida seis -----
; ----------------------------------------------------------------------
	ld hl,0e410h		;a40b   ; la lista de puestos del primer bando...
	ld de,0e416h		;a40e   ; ...y la del segundo
	ld c,006h		;a411   ; los puestos del segundo bando son los del primero mas seis
	ld a,(0e527h)		;a413   ; el bando que lleva la camara, que es el que tiene la pelota
	and a			;a416
	jr z,L_A41C		;a417
	ex de,hl			;a419   ; si la tiene el segundo, se copia al reves...
	ld c,0fah		;a41a   ; ...y entonces lo que se suma es -6
L_A41C:
	ld b,006h		;a41c   ; seis puestos
L_A41E:
	ld a,(hl)			;a41e
	add a,c			;a41f   ; el mismo papel, corrido al otro bando
	ld (de),a			;a420   ; asi los dos equipos juegan SIEMPRE la misma distribucion, espejada
	inc l			;a421
	inc e			;a422
	djnz L_A41E		;a423
	ret			;a425
pon_el_puesto_del_que_la_lleva:		; dos bytes: la mitad del intercambio
	ld (hl),e			;a426   ; se llama con `call z` para ahorrarse el salto: dos bytes de rutina
	ret			;a427
pon_el_puesto_de_la_zona:		; la otra mitad
	ld (hl),c			;a428   ; y aqui la vuelta del cambio
	ret			;a429
apunta_quien_ocupa_cada_puesto:		; llena 0xE430 con el jugador de cada puesto, y marca a los que no se ven
	ld a,(0e527h)		;a42a   ; solo se hace del bando que lleva la camara: es el unico al que se le pasa la pelota
	and a			;a42d
	ld ix,0e100h		;a42e   ; la primera ficha de ese bando...
	ld hl,0e410h		;a432   ; ...y su lista de seis puestos
	jr z,L_A43D		;a435
	ld ix,0e1c0h		;a437   ; y lo mismo del otro
	ld l,016h		;a43b   ; (0xE416), la lista del segundo bando
L_A43D:
	ld b,006h		;a43d   ; seis
L_A43F:
	ld a,(hl)			;a43f   ; el puesto que juega esta ficha
	inc l			;a440
	ld de,0e430h		;a441   ; 0xE430 se indexa por el puesto, no por el jugador: es la tabla al reves
	call suma_a_de		;a444
	ld c,(ix+015h)		;a447   ; y lo que se guarda es su numero de jugador
	ld a,(ix+00ah)		;a44a   ; su Y de ventana
	cp 0e0h		;a44d   ; 0xE0 es el "no se ve"
	jr nz,L_A453		;a44f
	set 7,c		;a451   ; y entonces se le pone el bit 7: 0xA2AD lo mira para descartar candidatos fuera de pantalla
L_A453:
	ld a,c			;a453
	ld (de),a			;a454   ; el puesto queda apuntado
	ld de,00020h		;a455   ; 32 bytes, la ficha siguiente
	add ix,de		;a458
	djnz L_A43F		;a45a
	ret			;a45c

; ----------------------------------------------------------------------
; DATOS tablas_de_zona: dos de quince bytes indexadas por (0xE52B) -las cinco
;   franjas por las tres columnas del campo- y una de once para la direccion
;   0xa45d..0xa486  (41 bytes)
DATA_tablas_de_zona:
	defb 000h	; a45d
	defb 001h	; a45e
	defb 002h	; a45f
	defb 000h	; a460
	defb 001h	; a461
	defb 002h	; a462
	defb 000h	; a463
	defb 001h	; a464
	defb 002h	; a465
	defb 003h	; a466
	defb 004h	; a467
	defb 005h	; a468
	defb 003h	; a469
	defb 004h	; a46a
	defb 005h	; a46b
	defb 006h	; a46c
	defb 007h	; a46d
	defb 008h	; a46e
	defb 006h	; a46f
	defb 007h	; a470
	defb 008h	; a471
	defb 009h	; a472
	defb 00ah	; a473
	defb 00bh	; a474
	defb 009h	; a475
	defb 00ah	; a476
	defb 00bh	; a477
	defb 009h	; a478
	defb 00ah	; a479
	defb 00bh	; a47a
	defb 000h	; a47b
	defb 001h	; a47c
	defb 005h	; a47d
	defb 000h	; a47e
	defb 087h	; a47f
	defb 088h	; a480
	defb 086h	; a481
	defb 000h	; a482
	defb 083h	; a483
	defb 082h	; a484
	defb 084h	; a485

; ======================================================================
; CODIGO 0xa486..0xa4e7  (97 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL PASO DE LOS DOCE =====
; ----------------------------------------------------------------------
da_un_paso_cada_jugador:		; recorre las doce fichas y mueve a cada una segun su direccion
	ld b,00ch		;a486   ; doce, que es lo que hay: seis por bando
	ld ix,0e100h		;a488   ; la primera ficha
L_A48C:
	push bc			;a48c
	call un_paso_de_este_jugador		;a48d   ; B se aparca en la pila porque la rutina de dentro lo usa para saber de que bando es
	ld de,00020h		;a490   ; 32 bytes por ficha
	add ix,de		;a493
	pop bc			;a495   ; y vuelve para el `djnz`
	djnz L_A48C		;a496
	ret			;a498
un_paso_de_este_jugador:
	ld a,(0e537h)		;a499   ; (0xE537) es el que lleva la jugada, y a ese lo mueve otro sitio
	cp (ix+015h)		;a49c
	ret z			;a49f
	ld a,(ix+00dh)		;a4a0   ; el dibujo 4 es el que no se mueve -en el suelo-, y tampoco anda
	cp 004h		;a4a3
	ret z			;a4a5
	ld a,(ix+002h)		;a4a6   ; +2 son los cuadros que le quedan castigado
	and a			;a4a9
	jr z,monta_el_apoyo_y_despacha		;a4aa
	dec (ix+002h)		;a4ac   ; se descuenta uno y este cuadro no da paso: es la penalizacion del que pierde la pelota
	ret			;a4af
monta_el_apoyo_y_despacha:
	ld a,(ix+005h)		;a4b0   ; la parte fina de la X...
	ld l,(ix+006h)		;a4b3   ; ...y los dos bytes de pixeles
	ld h,(ix+007h)		;a4b6
	ld (0e2d0h),a		;a4b9   ; al apoyo de 0xE2D0, que es donde las ocho rutinas de direccion lo esperan
	ld (0e2d1h),hl		;a4bc   ; y los pixeles a 0xE2D1/0xE2D2: los tres bytes seguidos son la X de 24 bits
	ld hl,0e06ch		;a4bf   ; (0xE06C) = 0x0150, el paso del primer bando suelto: un pixel y 0x50/256 por cuadro
	ld a,b			;a4c2   ; B va de 12 a 1, asi que por encima de 7 son los jugadores 0 a 5
	cp 007h		;a4c3
	jr nc,L_A4CA		;a4c5
	ld hl,0e070h		;a4c7   ; (0xE070) es el paso del segundo bando, y ese lo fija el NIVEL en 0x5746
L_A4CA:
	ld a,(0e528h)		;a4ca   ; quien lleva la pelota
	cp (ix+015h)		;a4cd
	jr nz,L_A4D4		;a4d0
	dec l			;a4d2   ; dos bytes antes: (0xE06A) y (0xE06E), el paso del que la lleva, mas corto que el del que corre suelto
	dec l			;a4d3
L_A4D4:
	ld e,(hl)			;a4d4
	inc hl			;a4d5
	ld d,(hl)			;a4d6
	ld (0e2d3h),de		;a4d7   ; el paso elegido queda en (0xE2D3), el cuarto byte del apoyo
	ld a,(ix+003h)		;a4db   ; la direccion, de 1 a 8
	and a			;a4de
	jr z,L_A4E4		;a4df
	ld (ix+00ch),a		;a4e1   ; con direccion no nula, el modo se refresca: +0x0C recuerda la ultima direccion buena
L_A4E4:
	call despacha		;a4e4   ; y se despacha por la DIRECCION, no por el modo: con cero se cae en la entrada 0, un `ret` pelado

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_a4e7: 9 entradas; su entrada [1] vale 0xA4F9, que
;   es el final de la tabla, y eso es lo que fija la cuenta en nueve y no en
;   veinticuatro
;   0xa4e7..0xa4f9  (18 bytes)
DATA_tabla_de_subescenas_a4e7:
	defw 0a517h,0a4f9h,0a506h,0a518h,0a529h,0a53bh,0a54ah,0a550h	; a4e7
	defw 0a561h	; a4f7  -> paso_arriba_y_derecha

; ======================================================================
; CODIGO 0xa4f9..0xa5cc  (211 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----- LAS OCHO DIRECCIONES, una rutina por cada una -----
; ----------------------------------------------------------------------
paso_a_la_derecha:
	ld (ix+001h),000h		;a4f9   ; la 1, derecha: es horizontal pura y no gasta cuadros de compromiso
	call alterna_el_dibujo_de_correr		;a4fd   ; el dibujo de correr
	call recoge_la_x_y_el_paso		;a500   ; recoge X y paso del apoyo
	jp suma_el_paso_a_la_x		;a503   ; y suma: por la derecha el paso se suma tal cual
paso_abajo_y_derecha:
	call paso_hacia_abajo		;a506   ; la 2: primero el escalon de abajo...
	ret nz			;a509   ; ...y si todavia no toca, se acabo: en diagonal no se mueve nada hasta el octavo cuadro
ocho_pixeles_a_la_derecha:
	ld hl,(0e2d1h)		;a50a   ; las diagonales NO usan el paso fino: mueven ocho pixeles clavados
	ld de,00008h		;a50d   ; ocho, igual que lo que sube o baja: la diagonal es exactamente a 45 grados
	add hl,de			;a510
	ld (ix+006h),l		;a511
	ld (ix+007h),h		;a514
no_da_ningun_paso:		; la entrada 0 de la tabla, para la direccion nula
	ret			;a517   ; un `ret` que hace de entrada 0 del despachador, y ademas cierra la rutina de arriba
paso_hacia_abajo:
	call alterna_el_dibujo_de_correr		;a518   ; la 3, abajo
	dec (ix+001h)		;a51b   ; la altura solo se mueve cuando el contador de +1 llega a cero: uno de cada ocho cuadros
	ret nz			;a51e
	ld a,(ix+004h)		;a51f   ; la altura
	add a,008h		;a522   ; ocho, que es la fila de caracteres: el jugador estampado no cabe entre dos
	ld (ix+004h),a		;a524
	xor a			;a527   ; sale con Z para que las diagonales sepan que ESTE es el cuadro bueno
	ret			;a528
paso_abajo_e_izquierda:
	call paso_hacia_abajo		;a529   ; la 4
	ret nz			;a52c
ocho_pixeles_a_la_izquierda:
	ld hl,(0e2d1h)		;a52d
	ld de,0fff8h		;a530   ; -8, en complemento a dos
	add hl,de			;a533
	ld (ix+006h),l		;a534
	ld (ix+007h),h		;a537
	ret			;a53a
paso_a_la_izquierda:
	ld (ix+001h),000h		;a53b   ; la 5, izquierda
	call alterna_el_dibujo_de_correr		;a53f
	call recoge_la_x_y_el_paso		;a542   ; el mismo apoyo...
	call cambia_el_paso_de_signo		;a545   ; ...con el paso cambiado de signo
	jr suma_el_paso_a_la_x		;a548   ; y a sumar, igual que por la derecha
paso_arriba_e_izquierda:
	call paso_hacia_arriba		;a54a   ; la 6
	ret nz			;a54d
	jr ocho_pixeles_a_la_izquierda		;a54e
paso_hacia_arriba:
	call alterna_el_dibujo_de_correr		;a550   ; la 7, arriba: identica a la de abajo salvo el signo
	dec (ix+001h)		;a553   ; tambien uno de cada ocho cuadros
	ret nz			;a556
	ld a,(ix+004h)		;a557
	sub 008h		;a55a   ; ocho hacia arriba
	ld (ix+004h),a		;a55c
	xor a			;a55f
	ret			;a560
paso_arriba_y_derecha:
	call paso_hacia_arriba		;a561   ; la 8, y con ella se cierran las ocho
	ret nz			;a564
	jr ocho_pixeles_a_la_derecha		;a565
alterna_el_dibujo_de_correr:
	ld c,001h		;a567   ; los dibujos 1 y 2 son las dos zancadas
	ld a,(0e003h)		;a569   ; el contador de cuadros
	and 004h		;a56c   ; el bit 2: cambia de pierna cada cuatro cuadros
	jr z,L_A571		;a56e
	inc c			;a570
L_A571:
	ld (ix+00dh),c		;a571   ; +0x0D es el dibujo
	ret			;a574
cambia_el_paso_de_signo:
	call L_A211		;a575   ; niega HL, que es el paso de 16 bits
	ld a,h			;a578   ; y si ha quedado negativo...
	add a,a			;a579
	ret nc			;a57a
	dec b			;a57b   ; ...B, que es la extension del paso a 24 bits, se pone a 0xFF
	ret			;a57c
suma_el_paso_a_la_x:
	add hl,de			;a57d   ; la suma de 24 bits: primero los dos bytes bajos...
	ld a,b			;a57e
	adc a,c			;a57f   ; ...y luego el alto con el acarreo
	ld (ix+007h),a		;a580   ; y los tres vuelven a la ficha: +7 pixeles altos, +6 bajos, +5 la parte fina
	ld (ix+006h),h		;a583
	ld (ix+005h),l		;a586
	ret			;a589
recoge_la_x_y_el_paso:
	ld de,(0e2d0h)		;a58a   ; DE = la parte fina y el byte bajo de la X, leidos de golpe
	ld a,(0e2d2h)		;a58e   ; C = el byte alto
	ld c,a			;a591
	ld hl,(0e2d3h)		;a592   ; HL = el paso
	ld b,000h		;a595   ; B a cero: la extension del paso, que 0xA575 pone a 0xFF si va hacia atras
	ret			;a597

; ----------------------------------------------------------------------
; ----- DE DONDE SALE LA DIRECCION: el mando, o la maquina -----
; ----------------------------------------------------------------------
lee_el_mando_del_jugador:
	ld a,(ix+015h)		;a598   ; el numero del jugador
	cp 006h		;a59b   ; los seis primeros son siempre de mando
	jr c,traduce_el_mando_a_direccion		;a59d
	ld a,(0e002h)		;a59f   ; el bit 5 de (0xE002): puesto, hay dos humanos
	and 020h		;a5a2
	jp z,decide_la_direccion_de_la_maquina		;a5a4   ; y si no lo hay, los jugadores 6 a 11 los piensa la maquina
traduce_el_mando_a_direccion:
	ld a,(ix+001h)		;a5a7   ; con un paso empezado NO se lee el mando: el jugador esta comprometido esos ocho cuadros
	and a			;a5aa
	ret nz			;a5ab
	ld hl,0a5dch		;a5ac   ; se apila 0xA5DC como retorno: al salir de aqui se cae en el recorte del campo
	push hl			;a5af
	ld a,(ix+015h)		;a5b0   ; su numero otra vez, ahora para saber que mando le toca
	ld de,0e007h		;a5b3   ; (0xE007), el mantenido del mando 1
	cp 006h		;a5b6
	jr c,L_A5BC		;a5b8
	ld e,009h		;a5ba   ; y (0xE009) el del mando 2
L_A5BC:
	ld a,(de)			;a5bc
	and 00fh		;a5bd   ; los cuatro bits bajos son las direcciones; los botones van mas arriba
	ld hl,0a5cch		;a5bf   ; la tabla de 0xA5CC, indexada por la propia mascara de bits
	call suma_a_hl		;a5c2
	ld a,(hl)			;a5c5
	and 00fh		;a5c6   ; solo el nibble bajo: el bit 7 de la tabla marca las direcciones con componente vertical, y aqui se tira
	ld (ix+003h),a		;a5c8   ; y en +3 queda la direccion
	ret			;a5cb

; ----------------------------------------------------------------------
; DATOS mando_a_direccion: las dieciseis combinaciones del joystick traducidas
;   a direccion; las imposibles -las que piden dos sentidos a la vez- dan cero
;   0xa5cc..0xa5dc  (16 bytes)
DATA_mando_a_direccion:
	defb 000h	; a5cc
	defb 087h	; a5cd
	defb 083h	; a5ce
	defb 000h	; a5cf
	defb 005h	; a5d0
	defb 086h	; a5d1
	defb 084h	; a5d2
	defb 000h	; a5d3
	defb 001h	; a5d4
	defb 088h	; a5d5
	defb 082h	; a5d6
	defb 000h	; a5d7
	defb 000h	; a5d8
	defb 000h	; a5d9
	defb 000h	; a5da
	defb 000h	; a5db

; ======================================================================
; CODIGO 0xa5dc..0xa64e  (114 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----- NO TE SALGAS DEL CAMPO -----
; ----------------------------------------------------------------------
no_te_salgas_del_campo:		; recorta la direccion contra los cuatro bordes y fija los cuadros de compromiso
	ld a,(ix+003h)		;a5dc   ; parado no hay nada que recortar
	and a			;a5df
	ret z			;a5e0
	ld b,a			;a5e1
	ld hl,0a65dh		;a5e2   ; la tabla de 0xA65D, con la base una entrada mas abajo porque el indice va de 1 a 8
	call suma_a_hl		;a5e5
	ld c,(hl)			;a5e8   ; la mascara de la direccion: bit 0 derecha, bit 1 izquierda, bit 4 abajo, bit 5 arriba
	bit 0,c		;a5e9   ; va hacia la derecha
	call nz,tope_por_la_derecha		;a5eb
	bit 1,c		;a5ee   ; va hacia la izquierda
	call nz,tope_por_la_izquierda		;a5f0
	bit 4,c		;a5f3   ; va hacia abajo
	call nz,tope_por_abajo		;a5f5
	bit 5,c		;a5f8   ; va hacia arriba
	call nz,tope_por_arriba		;a5fa
	ld (ix+003h),b		;a5fd   ; la direccion ya recortada vuelve a la ficha
	ld a,b			;a600
	and a			;a601
	jr z,L_A60B		;a602
	and 003h		;a604   ; direccion 1 o 5: horizontal pura...
	dec a			;a606   ; ...y esas no cuestan compromiso ninguno, se pueden cambiar en cualquier cuadro
	jr z,L_A60B		;a607
	ld a,008h		;a609   ; todas las demas mueven la altura, y esa va a saltos de ocho: ocho cuadros comprometido
L_A60B:
	ld (ix+001h),a		;a60b   ; +1 es el contador que 0xA518 y 0xA550 descuentan
	ret			;a60e
tope_por_la_derecha:
	ld l,(ix+006h)		;a60f
	ld h,(ix+007h)		;a612
	ld de,00259h		;a615   ; 0x259, o sea 601: el fondo derecho del campo
	and a			;a618
	sbc hl,de		;a619
	ret c			;a61b   ; por delante de ese pixel se puede seguir
	ld hl,0a64dh		;a61c   ; y si no, la tabla de 0xA64D quita la componente horizontal y deja la vertical
	jr quita_la_componente		;a61f
tope_por_la_izquierda:
	ld l,(ix+006h)		;a621
	ld h,(ix+007h)		;a624
	ld de,00020h		;a627   ; 0x20, el fondo izquierdo
	and a			;a62a
	sbc hl,de		;a62b
	ret nc			;a62d
	ld a,b			;a62e
	ld hl,0a64dh		;a62f   ; misma tabla: derecha o izquierda se quitan igual
	jr quita_la_componente		;a632
tope_por_arriba:
	ld a,(ix+004h)		;a634   ; la altura
	cp 011h		;a637   ; 0x11 es la banda de arriba
	ret nc			;a639
	ld hl,0a655h		;a63a   ; la otra tabla, la de 0xA655, quita la componente vertical
quita_la_componente:
	ld a,b			;a63d   ; las dos tablas van indexadas por la direccion, de 1 a 8, con la base una entrada antes
	call suma_a_hl		;a63e
	ld b,(hl)			;a641
	ret			;a642
tope_por_abajo:
	ld a,(ix+004h)		;a643
	cp 0a0h		;a646   ; 0xA0 es la banda de abajo; entre 0x11 y 0xA0 caben las 143 filas de cesped
	ret c			;a648
	ld hl,0a655h		;a649
	jr quita_la_componente		;a64c

; ----------------------------------------------------------------------
; DATOS tres_tablas_de_ocho_direcciones: las tres con la base una entrada mas
;   abajo, porque el indice va de 1 a 8; la ultima acaba justo donde empieza
;   L_A666
;   0xa64e..0xa666  (24 bytes)
DATA_tres_tablas_de_ocho_direcciones:
	defb 000h	; a64e
	defb 003h	; a64f
	defb 000h	; a650
	defb 003h	; a651
	defb 000h	; a652
	defb 007h	; a653
	defb 000h	; a654
	defb 007h	; a655
	defb 000h	; a656
	defb 001h	; a657
	defb 000h	; a658
	defb 005h	; a659
	defb 000h	; a65a
	defb 005h	; a65b
	defb 000h	; a65c
	defb 001h	; a65d
	defb 001h	; a65e
	defb 011h	; a65f
	defb 010h	; a660
	defb 012h	; a661
	defb 002h	; a662
	defb 022h	; a663
	defb 020h	; a664
	defb 021h	; a665

; ======================================================================
; CODIGO 0xa666..0xa85e  (504 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== SEPARARSE DEL QUE LLEVA EL HUMANO =====
; ----------------------------------------------------------------------
separa_a_los_companeros_del_destacado:
	ld a,(0e280h)		;a666   ; solo con el juego vivo: del subestado 2 en adelante manda el saque
	cp 002h		;a669
	ret nc			;a66b
	ld iy,0e100h		;a66c   ; el primer bando...
	ld a,(0e52ch)		;a670   ; ...con el destacado del mando 1
	call separa_a_este_companero		;a673
	ld iy,0e1c0h		;a676   ; y el segundo con el del mando 2
	ld a,(0e52dh)		;a67a
separa_a_este_companero:
	ld c,a			;a67d
	ld a,(0e556h)		;a67e   ; (0xE556) cicla de 0 a 5: en cada cuadro se mira a un companero, no a los seis
	add a,a			;a681   ; por 32, que es lo que ocupa una ficha
	add a,a			;a682
	add a,a			;a683
	add a,a			;a684
	add a,a			;a685
	ld e,a			;a686
	ld d,000h		;a687
	add iy,de		;a689
	ld a,c			;a68b
	call L_A201		;a68c   ; IX apunta a la ficha del destacado
	ld l,(ix+004h)		;a68f   ; su altura...
	ld h,(ix+015h)		;a692   ; ...y su numero
	ld a,(iy+00ah)		;a695   ; el companero, si no se ve...
	cp 0e0h		;a698   ; ...0xE0 otra vez, y entonces nada
	ret z			;a69a
	ld a,(iy+015h)		;a69b   ; y si el companero ES el destacado tampoco
	cp h			;a69e
	ret z			;a69f
	ld a,(iy+016h)		;a6a0   ; la altura de DESTINO del companero
	ld c,a			;a6a3
	sub l			;a6a4   ; menos la del destacado
	add a,018h		;a6a5   ; el truco de siempre para el valor absoluto
	cp 030h		;a6a7   ; con mas de 0x18 -24 pixeles- de diferencia ya estan separados y se deja
	ret nc			;a6a9
	ld a,c			;a6aa
	cp 058h		;a6ab   ; 0x58 es la mitad justa de lo alto del campo, entre 0x11 y 0xA0
	ld a,020h		;a6ad   ; si el companero iba por la mitad de arriba se le manda 0x20 por debajo...
	jr c,L_A6B3		;a6af
	ld a,0e0h		;a6b1   ; ...y si iba por la de abajo, 0x20 por encima
L_A6B3:
	add a,l			;a6b3   ; siempre contado desde el destacado, que es de quien hay que apartarse
	ld (iy+016h),a		;a6b4   ; y el destino corregido vuelve a +0x16
	ret			;a6b7

; ----------------------------------------------------------------------
; ===== DONDE SE PONE EL QUE DEFIENDE =====
; ----------------------------------------------------------------------
coloca_a_un_defensa:		; uno por cuadro, el que toque
	ld a,(0e527h)		;a6b8   ; el bando que NO lleva la camara: el que defiende
	and a			;a6bb
	ld ix,0e100h		;a6bc
	jr nz,L_A6C6		;a6c0
	ld ix,0e1c0h		;a6c2   ; y ese es el segundo cuando la camara va con el primero
L_A6C6:
	ld a,(0e556h)		;a6c6   ; y de el, solo el puesto que toca en este cuadro
	add a,a			;a6c9   ; por 32
	add a,a			;a6ca
	add a,a			;a6cb
	add a,a			;a6cc
	add a,a			;a6cd
	ld e,a			;a6ce
	ld d,000h		;a6cf
	add ix,de		;a6d1
	jr donde_debe_ponerse_este_defensa		;a6d3
coloca_a_los_seis_defensas:		; de golpe, para arrancar la jugada
	ld a,(0e527h)		;a6d5   ; lo llaman 0x5755 al empezar el partido y 0xB848: ahi si hacen falta los seis a la vez
	and a			;a6d8
	ld ix,0e100h		;a6d9
	jr nz,L_A6E3		;a6dd
	ld ix,0e1c0h		;a6df
L_A6E3:
	exx			;a6e3
	ld b,006h		;a6e4   ; los seis
L_A6E6:
	exx			;a6e6
	call donde_debe_ponerse_este_defensa		;a6e7   ; B se aparca en el juego alterno, que la rutina de dentro lo usa
	ld de,00020h		;a6ea
	add ix,de		;a6ed
	exx			;a6ef
	djnz L_A6E6		;a6f0
	ret			;a6f2
donde_debe_ponerse_este_defensa:
	ld a,(0e532h)		;a6f3   ; (0xE532) distingue el juego en marcha de las pausas
	and a			;a6f6
	jr z,L_A70C		;a6f7
	ld a,(ix+004h)		;a6f9   ; en pausa el destino es la posicion actual: quietos donde esten
	ld (ix+016h),a		;a6fc
	ld a,(ix+006h)		;a6ff   ; y su X entera, los dos bytes
	ld (ix+017h),a		;a702
	ld a,(ix+007h)		;a705
	ld (ix+018h),a		;a708
	ret			;a70b
L_A70C:
	ld a,(0e280h)		;a70c   ; con el juego vivo...
	cp 002h		;a70f   ; ...y del subestado 2 en adelante hasta los destacados se colocan solos, que ahi manda el saque
	jr nc,L_A71E		;a711
	ld hl,0e52ch		;a713   ; con el juego en marcha, en cambio, los dos destacados se los llevan los mandos
	ld a,(ix+015h)		;a716
	cp (hl)			;a719
	ret z			;a71a
	inc l			;a71b   ; y el del mando 2 igual
	cp (hl)			;a71c
	ret z			;a71d
L_A71E:
	ld a,(ix+015h)		;a71e   ; el numero del jugador
	add a,a			;a721   ; dos bytes por entrada
	ld e,a			;a722
	ld d,000h		;a723
	ld hl,0a868h		;a725   ; la tabla que empareja a cada uno con su par del otro bando, apuntando a su +3
	add hl,de			;a728
	ld e,(hl)			;a729
	inc hl			;a72a
	ld d,(hl)			;a72b   ; DE queda con ese puntero
	ex de,hl			;a72c
	ld a,(hl)			;a72d   ; la direccion que lleva su par
	cp (ix+019h)		;a72e   ; si es la misma de la ultima vez, no ha pasado nada: se sigue directo
	jr z,la_posicion_de_su_par		;a731
	ld (ix+019h),a		;a733   ; y si ha cambiado, se apunta
	and a			;a736   ; el par se ha parado; eso tampoco cuesta reaccion
	jr z,la_posicion_de_su_par		;a737
	ld a,(0e069h)		;a739   ; el nivel
	cp 003h		;a73c   ; REGLA DE DIFICULTAD: por debajo del 3 CUALQUIER cambio de direccion del par cuesta reaccion...
	jr c,pon_la_demora_de_reaccion		;a73e
	push hl			;a740   ; ...y del 3 para arriba solo la cuesta si el par esta cerca; si va lejos, se le sigue sin demora
	inc l			;a741   ; OJO: dos `inc l` sobre el +3 del par dejan el puntero en +5, la parte FINA de su X, no en +4, que es su altura
	inc l			;a742
	ld a,(hl)			;a743   ; y eso es lo que se guarda para el corte de altura de 0xA75D: parece un `inc l` de mas
	inc l			;a744
	ld e,(hl)			;a745   ; con dos incrementos mas si sale bien su X entera, +6 y +7
	inc l			;a746
	ld d,(hl)			;a747
	ld l,(ix+006h)		;a748   ; mi X
	ld h,(ix+007h)		;a74b
	and a			;a74e
	sbc hl,de		;a74f   ; menos la suya
	ld de,00040h		;a751   ; mas 0x40 y menos 0x80: la ventana es de +-0x40 pixeles a lo ancho
	add hl,de			;a754
	ld e,080h		;a755
	and a			;a757
	sbc hl,de		;a758
	pop hl			;a75a
	jr nc,la_posicion_de_su_par		;a75b   ; fuera de esa ventana, sin demora: se le sigue al momento
	sub (ix+004h)		;a75d   ; y ahora el corte de altura, que es el que tiene la pinta de estar mal
	add a,020h		;a760   ; el truco del valor absoluto otra vez...
	cp 040h		;a762   ; ...con una ventana de +-0x20
	jr nc,la_posicion_de_su_par		;a764
pon_la_demora_de_reaccion:
	ld a,(0e280h)		;a766   ; en el subestado 7 no hay demora que valga
	cp 007h		;a769
	jr z,la_posicion_de_su_par		;a76b
	ld a,(ix+015h)		;a76d   ; el numero del jugador
	cp 006h		;a770
	ld c,008h		;a772   ; REGLA DE DIFICULTAD: los jugadores 0 a 5 reaccionan SIEMPRE en 8 cuadros, sea cual sea el nivel
	jr c,L_A78A		;a774
	ld a,(0e002h)		;a776   ; el bit 5 de (0xE002): dos humanos
	and 020h		;a779
	ld hl,0a85dh		;a77b   ; con un solo humano, la tabla de 0xA85D+1: 16, 14, 12, 10 y 8 cuadros por nivel. La maquina siempre reacciona peor o igual que el bando del humano, y solo lo iguala en el nivel 5
	jr z,L_A783		;a77e
	ld hl,0a862h		;a780   ; con dos humanos, la otra: 11, 10, 8, 6 y 4
L_A783:
	ld a,(0e069h)		;a783   ; el nivel, de 1 a 5, indexa directamente porque la base va una entrada antes
	call suma_a_hl		;a786
	ld c,(hl)			;a789
L_A78A:
	ld (ix+01ah),c		;a78a   ; y la demora queda en +0x1A
	ret			;a78d
el_destino_de_su_par:
	ld de,00013h		;a78e   ; 0x13 sobre el +3 del par son sus +0x16, +0x17 y +0x18: su DESTINO
	add hl,de			;a791
	ld c,(hl)			;a792   ; en los saques se marca el sitio al que el par va, no donde esta
	inc l			;a793
	ld e,(hl)			;a794
	inc l			;a795
	ld d,(hl)			;a796
	jr elige_la_altura_del_marcaje		;a797
la_posicion_de_su_par:
	ld a,(0e280h)		;a799   ; del subestado 2 en adelante se marca el destino...
	cp 002h		;a79c
	jr nc,el_destino_de_su_par		;a79e
	inc l			;a7a0   ; ...y con el juego vivo, la posicion de verdad: +4 la altura
	ld c,(hl)			;a7a1
	inc l			;a7a2
	inc l			;a7a3
	ld e,(hl)			;a7a4   ; y +6/+7 su X
	inc l			;a7a5
	ld d,(hl)			;a7a6
elige_la_altura_del_marcaje:
	ex de,hl			;a7a7   ; HL se queda con el ancho al que hay que ir y DE guarda el puntero para 0xA7E7
	ld a,(0e53ch)		;a7a8   ; (0xE53C) es la cuenta atras que 0x5808 descuenta cada cuadro
	and a			;a7ab
	jr z,L_A7B3		;a7ac
	ld (ix+016h),c		;a7ae   ; mientras corre, el defensa se pone justo a la altura del par, sin correcciones
	jr elige_el_ancho_del_marcaje		;a7b1
L_A7B3:
	ld a,c			;a7b3
	cp 040h		;a7b4   ; 0x40: el par esta arriba del todo
	jr c,el_par_esta_arriba_del_todo		;a7b6
	cp 070h		;a7b8   ; entre 0x40 y 0x70, en la franja de en medio
	jp c,el_par_esta_en_la_franja_de_en_medio		;a7ba
	ld a,(0e280h)		;a7bd   ; de 0x70 para abajo, el par esta en la parte baja
	dec a			;a7c0
	jr nz,L_A7CC		;a7c1
	ld a,(0e2a1h)		;a7c3   ; la altura de la pelota...
	sub 00eh		;a7c6   ; ...menos 0x0E, que es lo que la pelota lleva de alto sobre su sombra
	cp 058h		;a7c8   ; con la pelota tambien por abajo, se corrige
	jr nc,L_A7D4		;a7ca
L_A7CC:
	ld a,c			;a7cc
	sub 010h		;a7cd   ; si no, se planta 0x10 por ENCIMA del par: se le cierra el camino hacia el centro
	ld (ix+016h),a		;a7cf
	jr elige_el_ancho_del_marcaje		;a7d2
L_A7D4:
	cp 070h		;a7d4   ; con la pelota mas abajo que 0x70...
	jr c,L_A7DD		;a7d6
	ld (ix+016h),a		;a7d8   ; ...el defensa se va a la altura de la pelota
	jr elige_el_ancho_del_marcaje		;a7db
L_A7DD:
	sub 058h		;a7dd   ; y si no, a medio camino
L_A7DF:
	neg		;a7df   ; -(altura - referencia) partido por dos, sumado a la altura del par: se queda a mitad de camino entre su par y la pelota
	sra a		;a7e1   ; partir por dos con signo
	add a,c			;a7e3
	ld (ix+016h),a		;a7e4
elige_el_ancho_del_marcaje:
	ex de,hl			;a7e7
	ld a,(0e280h)		;a7e8
	ld hl,00028h		;a7eb   ; 0x28, 40 pixeles: lo que el defensa se pone por delante de su par
	sub 003h		;a7ee   ; en el subestado 3...
	jr nz,L_A7F4		;a7f0
	ld l,020h		;a7f2   ; ...solo 0x20
L_A7F4:
	dec a			;a7f4
	cp 002h		;a7f5   ; y en los subestados 4 y 5...
	jr nc,L_A7FB		;a7f7
	ld l,038h		;a7f9   ; ...0x38: en los saques la barrera se separa mas
L_A7FB:
	ld a,(0e527h)		;a7fb   ; el bando que ataca decide de que lado se pone el defensa...
	and a			;a7fe
	call z,L_A211		;a7ff   ; ...cambiando la separacion de signo: el defensa se planta por delante de su par, del lado por el que viene el ataque (deducido)
	add hl,de			;a802   ; sobre la X del par
	ld (ix+017h),l		;a803   ; y ahi va el destino, +0x17 y +0x18
	ld (ix+018h),h		;a806
	ld a,h			;a809
	dec a			;a80a   ; con el byte alto a 1 la X cae entre 0x100 y 0x1FF, o sea en el centro: no hay nada que recortar
	ret z			;a80b
	ld a,l			;a80c   ; OJO: `ld a,l` no toca las banderas, asi que el `jp p` de abajo mira todavia el signo del `dec a`
	jp p,L_A818		;a80d   ; byte alto 2: la mitad derecha
	cp 020h		;a810   ; byte alto 0: la izquierda
	ret nc			;a812
	ld (ix+017h),020h		;a813   ; y ahi el tope es 0x20, el mismo fondo que usa 0xA621
	ret			;a817
L_A818:
	cp 061h		;a818   ; 0x61 arriba...
	ret c			;a81a
	ld (ix+017h),060h		;a81b   ; ...y se recorta a 0x260, o sea 608
	ret			;a81f
el_par_esta_arriba_del_todo:
	ld a,(0e280h)		;a820   ; el par esta arriba del todo: se le marca por debajo
	dec a			;a823
	jr nz,L_A82F		;a824
	ld a,(0e2a1h)		;a826
	sub 00eh		;a829
	cp 058h		;a82b
	jr c,L_A837		;a82d
L_A82F:
	ld a,c			;a82f
	add a,010h		;a830   ; aqui al reves: 0x10 por DEBAJO del par
	ld (ix+016h),a		;a832
	jr elige_el_ancho_del_marcaje		;a835
L_A837:
	cp 040h		;a837   ; la pelota tambien arriba...
	jr nc,L_A840		;a839
	ld (ix+016h),a		;a83b   ; ...y el defensa se va a su altura
	jr elige_el_ancho_del_marcaje		;a83e
L_A840:
	sub 058h		;a840   ; si no, a mitad de camino contra 0x58, la mitad del campo
	jr L_A7DF		;a842
el_par_esta_en_la_franja_de_en_medio:
	ld a,(0e2a1h)		;a844   ; aqui la referencia es solo la pelota: en el centro se juega a la pelota, no al hombre
	sub 00eh		;a847
	cp 040h		;a849
	jr c,L_A856		;a84b
	cp 070h		;a84d
	jr nc,L_A85A		;a84f
	ld (ix+016h),a		;a851   ; con la pelota tambien en la franja media, el defensa se planta a su altura
	jr elige_el_ancho_del_marcaje		;a854
L_A856:
	sub 010h		;a856   ; con la pelota arriba, a mitad de camino contra 0x10...
	jr L_A7DF		;a858
L_A85A:
	sub 0a0h		;a85a   ; ...y con la pelota abajo, contra 0xA0: las dos bandas
	jr L_A7DF		;a85c

; ----------------------------------------------------------------------
; DATOS dos_tablas_por_nivel: cinco bytes cada una, indexadas por el nivel de
;   (0xE069): [10 0E 0C 0A 08] y [0B 0A 08 06 04]. Las leen 0xA77B y 0xA780, y
;   el resultado va a (ix+0x1A)
;   0xa85e..0xa868  (10 bytes)
DATA_dos_tablas_por_nivel:
	defb 010h	; a85e
	defb 00eh	; a85f
	defb 00ch	; a860
	defb 00ah	; a861
	defb 008h	; a862
	defb 00bh	; a863
	defb 00ah	; a864
	defb 008h	; a865
	defb 006h	; a866
	defb 004h	; a867

; ----------------------------------------------------------------------
; DATOS punteros_a_los_doce_jugadores: doce palabras a las estructuras de
;   0xE1C3, 0xE1E3 y siguientes, de 0x20 en 0x20; 0xA725 las indexa por
;   (ix+0x15) y cuadran con el `ld b,00ch / ld ix,0e100h` de 0x8AC9
;   0xa868..0xa880  (24 bytes)
DATA_punteros_a_los_doce_jugadores:
	defw 0e1c3h,0e1e3h,0e203h,0e223h,0e243h,0e263h,0e103h,0e123h	; a868
	defw 0e143h,0e163h,0e183h,0e1a3h	; a878

; ----------------------------------------------------------------------
; DATOS colocaciones_de_los_equipos: quince formaciones de seis jugadores, con
;   sus dos coordenadas cada uno; de 0xA880 las de un equipo y de 0xA934 las
;   del otro. Las leen 0xA05E y 0xA06A, con el indice a doce por (0xE52B). Las
;   quince son las quince zonas en que 0xA219 parte el campo segun donde este
;   la pelota: CINCO franjas a lo ancho -0xD0, 0x100, 0x180, 0x1B0 y el resto-
;   por TRES a lo alto -0x49 y 0x78-, y 5 por 3 por 12 bytes por 2 equipos son
;   los 360 justos
;   0xa880..0xa9e8  (360 bytes)
DATA_colocaciones_de_los_equipos:
	defb 020h	; a880
	defb 00ah	; a881
	defb 050h	; a882
	defb 008h	; a883
	defb 098h	; a884
	defb 008h	; a885
	defb 018h	; a886
	defb 014h	; a887
	defb 058h	; a888
	defb 013h	; a889
	defb 098h	; a88a
	defb 012h	; a88b
	defb 018h	; a88c
	defb 008h	; a88d
	defb 060h	; a88e
	defb 00ah	; a88f
	defb 098h	; a890
	defb 008h	; a891
	defb 018h	; a892
	defb 014h	; a893
	defb 058h	; a894
	defb 013h	; a895
	defb 098h	; a896
	defb 014h	; a897
	defb 018h	; a898
	defb 008h	; a899
	defb 058h	; a89a
	defb 008h	; a89b
	defb 098h	; a89c
	defb 00ah	; a89d
	defb 018h	; a89e
	defb 014h	; a89f
	defb 058h	; a8a0
	defb 013h	; a8a1
	defb 098h	; a8a2
	defb 014h	; a8a3
	defb 020h	; a8a4
	defb 010h	; a8a5
	defb 048h	; a8a6
	defb 009h	; a8a7
	defb 098h	; a8a8
	defb 00fh	; a8a9
	defb 030h	; a8aa
	defb 01ch	; a8ab
	defb 060h	; a8ac
	defb 01eh	; a8ad
	defb 078h	; a8ae
	defb 016h	; a8af
	defb 018h	; a8b0
	defb 009h	; a8b1
	defb 060h	; a8b2
	defb 010h	; a8b3
	defb 098h	; a8b4
	defb 009h	; a8b5
	defb 018h	; a8b6
	defb 016h	; a8b7
	defb 060h	; a8b8
	defb 01ch	; a8b9
	defb 098h	; a8ba
	defb 016h	; a8bb
	defb 018h	; a8bc
	defb 00ch	; a8bd
	defb 068h	; a8be
	defb 009h	; a8bf
	defb 090h	; a8c0
	defb 010h	; a8c1
	defb 038h	; a8c2
	defb 016h	; a8c3
	defb 048h	; a8c4
	defb 01ah	; a8c5
	defb 098h	; a8c6
	defb 01ch	; a8c7
	defb 020h	; a8c8
	defb 014h	; a8c9
	defb 048h	; a8ca
	defb 00eh	; a8cb
	defb 098h	; a8cc
	defb 014h	; a8cd
	defb 018h	; a8ce
	defb 020h	; a8cf
	defb 068h	; a8d0
	defb 01ah	; a8d1
	defb 078h	; a8d2
	defb 020h	; a8d3
	defb 018h	; a8d4
	defb 00eh	; a8d5
	defb 068h	; a8d6
	defb 014h	; a8d7
	defb 098h	; a8d8
	defb 00eh	; a8d9
	defb 018h	; a8da
	defb 01ah	; a8db
	defb 048h	; a8dc
	defb 020h	; a8dd
	defb 098h	; a8de
	defb 01ah	; a8df
	defb 018h	; a8e0
	defb 014h	; a8e1
	defb 058h	; a8e2
	defb 00eh	; a8e3
	defb 090h	; a8e4
	defb 014h	; a8e5
	defb 030h	; a8e6
	defb 020h	; a8e7
	defb 058h	; a8e8
	defb 01ah	; a8e9
	defb 090h	; a8ea
	defb 020h	; a8eb
	defb 020h	; a8ec
	defb 00eh	; a8ed
	defb 048h	; a8ee
	defb 012h	; a8ef
	defb 090h	; a8f0
	defb 00eh	; a8f1
	defb 018h	; a8f2
	defb 018h	; a8f3
	defb 068h	; a8f4
	defb 01eh	; a8f5
	defb 098h	; a8f6
	defb 018h	; a8f7
	defb 018h	; a8f8
	defb 012h	; a8f9
	defb 060h	; a8fa
	defb 00ch	; a8fb
	defb 098h	; a8fc
	defb 012h	; a8fd
	defb 018h	; a8fe
	defb 01eh	; a8ff
	defb 058h	; a900
	defb 018h	; a901
	defb 098h	; a902
	defb 01eh	; a903
	defb 020h	; a904
	defb 00ch	; a905
	defb 068h	; a906
	defb 012h	; a907
	defb 098h	; a908
	defb 00ch	; a909
	defb 018h	; a90a
	defb 018h	; a90b
	defb 048h	; a90c
	defb 01eh	; a90d
	defb 098h	; a90e
	defb 018h	; a90f
	defb 018h	; a910
	defb 017h	; a911
	defb 058h	; a912
	defb 019h	; a913
	defb 098h	; a914
	defb 017h	; a915
	defb 018h	; a916
	defb 01dh	; a917
	defb 058h	; a918
	defb 01fh	; a919
	defb 098h	; a91a
	defb 01dh	; a91b
	defb 018h	; a91c
	defb 019h	; a91d
	defb 058h	; a91e
	defb 017h	; a91f
	defb 098h	; a920
	defb 019h	; a921
	defb 018h	; a922
	defb 01fh	; a923
	defb 058h	; a924
	defb 01dh	; a925
	defb 098h	; a926
	defb 01fh	; a927
	defb 018h	; a928
	defb 017h	; a929
	defb 058h	; a92a
	defb 019h	; a92b
	defb 098h	; a92c
	defb 017h	; a92d
	defb 018h	; a92e
	defb 01dh	; a92f
	defb 058h	; a930
	defb 01fh	; a931
	defb 098h	; a932
	defb 01dh	; a933
	defb 018h	; a934
	defb 00bh	; a935
	defb 058h	; a936
	defb 009h	; a937
	defb 098h	; a938
	defb 00bh	; a939
	defb 018h	; a93a
	defb 011h	; a93b
	defb 058h	; a93c
	defb 00fh	; a93d
	defb 098h	; a93e
	defb 011h	; a93f
	defb 018h	; a940
	defb 009h	; a941
	defb 058h	; a942
	defb 009h	; a943
	defb 098h	; a944
	defb 009h	; a945
	defb 018h	; a946
	defb 00fh	; a947
	defb 058h	; a948
	defb 011h	; a949
	defb 098h	; a94a
	defb 00fh	; a94b
	defb 018h	; a94c
	defb 00bh	; a94d
	defb 058h	; a94e
	defb 009h	; a94f
	defb 098h	; a950
	defb 00bh	; a951
	defb 018h	; a952
	defb 011h	; a953
	defb 060h	; a954
	defb 00fh	; a955
	defb 098h	; a956
	defb 011h	; a957
	defb 018h	; a958
	defb 010h	; a959
	defb 068h	; a95a
	defb 00ah	; a95b
	defb 098h	; a95c
	defb 010h	; a95d
	defb 018h	; a95e
	defb 01ch	; a95f
	defb 048h	; a960
	defb 016h	; a961
	defb 098h	; a962
	defb 01ch	; a963
	defb 018h	; a964
	defb 00ah	; a965
	defb 058h	; a966
	defb 010h	; a967
	defb 098h	; a968
	defb 00ah	; a969
	defb 018h	; a96a
	defb 016h	; a96b
	defb 060h	; a96c
	defb 01ch	; a96d
	defb 098h	; a96e
	defb 016h	; a96f
	defb 018h	; a970
	defb 010h	; a971
	defb 068h	; a972
	defb 00ah	; a973
	defb 098h	; a974
	defb 010h	; a975
	defb 018h	; a976
	defb 01ah	; a977
	defb 048h	; a978
	defb 016h	; a979
	defb 098h	; a97a
	defb 01ah	; a97b
	defb 030h	; a97c
	defb 008h	; a97d
	defb 068h	; a97e
	defb 00eh	; a97f
	defb 090h	; a980
	defb 008h	; a981
	defb 018h	; a982
	defb 014h	; a983
	defb 048h	; a984
	defb 01ah	; a985
	defb 090h	; a986
	defb 014h	; a987
	defb 018h	; a988
	defb 00eh	; a989
	defb 060h	; a98a
	defb 008h	; a98b
	defb 098h	; a98c
	defb 00eh	; a98d
	defb 018h	; a98e
	defb 01ah	; a98f
	defb 070h	; a990
	defb 014h	; a991
	defb 098h	; a992
	defb 01ah	; a993
	defb 018h	; a994
	defb 008h	; a995
	defb 048h	; a996
	defb 00eh	; a997
	defb 078h	; a998
	defb 008h	; a999
	defb 020h	; a99a
	defb 014h	; a99b
	defb 068h	; a99c
	defb 01ah	; a99d
	defb 098h	; a99e
	defb 014h	; a99f
	defb 038h	; a9a0
	defb 012h	; a9a1
	defb 068h	; a9a2
	defb 00eh	; a9a3
	defb 098h	; a9a4
	defb 00ch	; a9a5
	defb 018h	; a9a6
	defb 01ch	; a9a7
	defb 048h	; a9a8
	defb 01fh	; a9a9
	defb 090h	; a9aa
	defb 018h	; a9ab
	defb 018h	; a9ac
	defb 012h	; a9ad
	defb 060h	; a9ae
	defb 00ch	; a9af
	defb 098h	; a9b0
	defb 012h	; a9b1
	defb 018h	; a9b2
	defb 01fh	; a9b3
	defb 060h	; a9b4
	defb 018h	; a9b5
	defb 098h	; a9b6
	defb 01fh	; a9b7
	defb 030h	; a9b8
	defb 00ch	; a9b9
	defb 048h	; a9ba
	defb 00ah	; a9bb
	defb 078h	; a9bc
	defb 012h	; a9bd
	defb 020h	; a9be
	defb 018h	; a9bf
	defb 068h	; a9c0
	defb 01fh	; a9c1
	defb 098h	; a9c2
	defb 019h	; a9c3
	defb 018h	; a9c4
	defb 014h	; a9c5
	defb 058h	; a9c6
	defb 015h	; a9c7
	defb 098h	; a9c8
	defb 014h	; a9c9
	defb 018h	; a9ca
	defb 01eh	; a9cb
	defb 060h	; a9cc
	defb 020h	; a9cd
	defb 080h	; a9ce
	defb 020h	; a9cf
	defb 018h	; a9d0
	defb 014h	; a9d1
	defb 058h	; a9d2
	defb 015h	; a9d3
	defb 098h	; a9d4
	defb 014h	; a9d5
	defb 018h	; a9d6
	defb 020h	; a9d7
	defb 060h	; a9d8
	defb 01eh	; a9d9
	defb 098h	; a9da
	defb 020h	; a9db
	defb 018h	; a9dc
	defb 014h	; a9dd
	defb 058h	; a9de
	defb 015h	; a9df
	defb 098h	; a9e0
	defb 014h	; a9e1
	defb 020h	; a9e2
	defb 020h	; a9e3
	defb 050h	; a9e4
	defb 020h	; a9e5
	defb 098h	; a9e6
	defb 01eh	; a9e7

; ======================================================================
; CODIGO 0xa9e8..0xaf35  (1357 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== QUIEN TOCA LA PELOTA =====
; ----------------------------------------------------------------------
mira_si_alguien_toca_la_pelota:
	ld a,(0e54ah)		;a9e8   ; (0xE54A) distinto de cero: hay una jugada parada y no se toca nada
	and a			;a9eb
	ret nz			;a9ec
	ld a,(0e280h)		;a9ed   ; el subestado 0 es la pelota suelta...
	and a			;a9f0
	jr z,L_A9F8		;a9f1
	dec a			;a9f3
	jp z,intenta_robar_la_pelota		;a9f4   ; ...y el 1, con dueno, va a la entrada
	ret			;a9f7
L_A9F8:
	ld a,(0e2ach)		;a9f8   ; el byte alto de la velocidad vertical de la pelota
	bit 7,a		;a9fb   ; con el bit 7 puesto la pelota viene BAJANDO...
	jr z,L_AA02		;a9fd
	ld (0e542h),a		;a9ff   ; ...y entonces (0xE542) se pone a ese valor: lo que marca es que el que la solto ya no la tiene reservada
L_AA02:
	ld a,(0e003h)		;aa02   ; el contador de cuadros
	rra			;aa05   ; su bit 0 alterna que bando se mira primero: si no, el primer bando ganaria siempre los balones divididos
	jr c,prueba_al_reves		;aa06
	call prueba_con_el_primer_bando		;aa08   ; primero el suyo...
	jr c,la_pelota_choca_con_el_jugador		;aa0b   ; ...y en cuanto uno la toca se corta
	call prueba_con_el_segundo_bando		;aa0d   ; y si no, el otro
	jr c,la_pelota_choca_con_el_jugador		;aa10   ; con el mismo corte
	ret			;aa12
prueba_con_el_primer_bando:
	ld a,(0e527h)		;aa13
	ld (0e2d0h),a		;aa16   ; (0xE2D0) marca si este bando es el estampado en el mapa; sale 1 justo para el bando que NO lleva la camara
	ld ix,0e100h		;aa19   ; la primera ficha
	ld b,006h		;aa1d   ; los seis
	jp busca_a_quien_toca_la_pelota		;aa1f
prueba_con_el_segundo_bando:
	ld a,(0e527h)		;aa22
	xor 001h		;aa25   ; para el segundo bando el aviso va invertido: los dos juntos dicen "este es el que va pegado a la rejilla de caracteres"
	ld (0e2d0h),a		;aa27
	ld ix,0e1c0h		;aa2a
	ld b,006h		;aa2e
	jp busca_a_quien_toca_la_pelota		;aa30
prueba_al_reves:		; los cuadros impares miran antes al segundo bando
	call prueba_con_el_segundo_bando		;aa33
	jr c,la_pelota_choca_con_el_jugador		;aa36
	call prueba_con_el_primer_bando		;aa38
	ret nc			;aa3b
la_pelota_choca_con_el_jugador:
	xor a			;aa3c   ; alguien la ha tocado
	ld (0e55fh),a		;aa3d   ; se limpian los cerrojos de rebote...
	ld (0e567h),a		;aa40
	ld (0e532h),a		;aa43   ; ...y (0xE532) a cero reanuda el juego
	ld a,(0e281h)		;aa46   ; (0xE281) es el subestado de la pelota...
	cp 002h		;aa49
	jr z,L_AAA4		;aa4b   ; ...y con el a 2 va rasa: esa se controla sin rebotar
	ld hl,(0e2abh)		;aa4d   ; la velocidad vertical de la pelota
	bit 7,h		;aa50   ; si viene bajando, tampoco rebota: se controla
	jr nz,L_AAA4		;aa52
	ld a,h			;aa54   ; ni si esta parada en vertical
	or l			;aa55
	jr z,L_AAA4		;aa56
	ld a,(0e2aah)		;aa58   ; (0xE2AA) es lo que la pelota lleva de vuelo; a 2 o mas ya no rebota
	cp 002h		;aa5b
	ret nc			;aa5d
	xor a			;aa5e
	ld (0e566h),a		;aa5f
	inc a			;aa62
	ld (0e546h),a		;aa63
	ld a,(ix+015h)		;aa66   ; el que la ha tocado...
	ld (0e542h),a		;aa69   ; ...queda apuntado en (0xE542) para no volver a contarlo enseguida
	cp 006h		;aa6c   ; 0 o 1 segun el bando
	ld a,000h		;aa6e
	jr c,L_AA73		;aa70
	inc a			;aa72
L_AA73:
	ld (0e283h),a		;aa73
	call parte_el_rebote_por_dos		;aa76   ; la velocidad vertical se parte por dos, pero NO cambia de signo: la pelota sigue subiendo o bajando igual
	ld (0e2abh),hl		;aa79
	ld hl,(0e2a2h)		;aa7c   ; las dos componentes del suelo, esas si...
	call media_vuelta_y_a_la_mitad		;aa7f   ; ...media vuelta y a la mitad: rebota hacia atras con la mitad de fuerza
	ex de,hl			;aa82
	ld hl,(0e2a7h)		;aa83
	call media_vuelta_y_a_la_mitad		;aa86
	ld (0e2a2h),hl		;aa89
	ld (0e2a7h),de		;aa8c
	ld a,046h		;aa90   ; y suena el 0x46, el golpe
	jp pide_un_sonido		;aa92
media_vuelta_y_a_la_mitad:
	call L_A211		;aa95
parte_el_rebote_por_dos:
	sra h		;aa98   ; estos tres bytes son copia literal de parte_la_velocidad_por_dos (0x8F64): el `sra h / rr l` conserva el signo
	rr l		;aa9a
	ret			;aa9c
roba_la_pelota_con_pitido:
	ld a,015h		;aa9d   ; el 0x15 es el sonido de la entrada, el que no suena cuando la pelota se controla sola
	call pide_un_sonido		;aa9f
	jr el_jugador_se_queda_la_pelota		;aaa2
L_AAA4:
	ld hl,0e566h		;aaa4
	ld a,(hl)			;aaa7
	and a			;aaa8
	jr z,el_jugador_se_queda_la_pelota		;aaa9
	dec (hl)			;aaab
el_jugador_se_queda_la_pelota:
	xor a			;aaac
	ld h,a			;aaad
	ld l,a			;aaae
	ld (0e370h),hl		;aaaf   ; (0xE370) es el sprite de la pelota, que se apaga mientras la lleva un jugador
	ld (0e53ch),a		;aab2
	ld (0e551h),a		;aab5
	ld (0e546h),a		;aab8
	inc a			;aabb
	ld (0e280h),a		;aabc   ; y el subestado pasa a 1: la pelota ya tiene dueno
	call apunta_al_nuevo_dueno_de_la_pelota		;aabf
	ld a,(ix+00ch)		;aac2   ; el modo del que la coge, o sea la ultima direccion que llevaba
	and a			;aac5
	jr z,L_AACA		;aac6
	ld a,003h		;aac8   ; si venia andando, a (0xE53A) -la direccion que se le supone a la pelota- le toca un 3; parado, se queda a cero
L_AACA:
	ld (0e53ah),a		;aaca
	call L_A36C		;aacd
	call L_A277		;aad0   ; y la maquina se busca ya a quien pasarsela
	jp para_la_pelota_y_al_jugador		;aad3
apunta_al_nuevo_dueno_de_la_pelota:
	ld a,(0e545h)		;aad6   ; (0xE545) no lo escribe NADIE en los 32 KB, y 0x5648 borra 0xE100..0xE5FF al montar cada jugada: vale cero siempre
	ld c,a			;aad9
	ld a,(ix+015h)		;aada
	ld (0e528h),a		;aadd   ; (0xE528) es quien lleva la pelota
	ld (0e542h),a		;aae0
	ld hl,0e52ch		;aae3
	cp 006h		;aae6   ; de que bando es
	jr c,L_AAF7		;aae8
	ld b,001h		;aaea   ; el segundo bando...
	inc l			;aaec
	ld (hl),a			;aaed   ; ...y su destacado pasa a ser el que la tiene
	dec c			;aaee   ; y solo con (0xE545) valiendo 1 exacto seguiria...
	jr nz,L_AB01		;aaef
	dec l			;aaf1
	sub 006h		;aaf2   ; ...poniendo tambien el destacado del otro mando en el puesto homologo; como (0xE545) es cero, este trozo esta MUERTO
	ld (hl),a			;aaf4
	jr L_AB01		;aaf5
L_AAF7:
	ld b,000h		;aaf7   ; el primer bando, con el mismo reparto al reves y el mismo trozo muerto detras
	ld (hl),a			;aaf9
	dec c			;aafa
	jr nz,L_AB01		;aafb
	inc l			;aafd
	add a,006h		;aafe
	ld (hl),a			;ab00
L_AB01:
	ld a,b			;ab01
	ld (0e527h),a		;ab02   ; y la camara se muda al bando que tiene la pelota
	ld (0e283h),a		;ab05
	ret			;ab08
busca_a_quien_toca_la_pelota:		; devuelve carry si alguna de las seis fichas la tiene al lado
	ld a,(0e2aah)		;ab09   ; con mas de tres de vuelo la pelota pasa por encima de todos
	cp 004h		;ab0c
	ret nc			;ab0e
	ld de,(0e2a5h)		;ab0f   ; la X de la pelota
	ld a,(0e2a1h)		;ab13   ; su altura...
	sub 00eh		;ab16   ; ...menos el 0x0E que la separa de su sombra: asi se compara contra los pies del jugador
	ld c,a			;ab18
L_AB19:
	ld a,(ix+00dh)		;ab19   ; el dibujo 3 es el que no puede tocarla
	cp 003h		;ab1c
	jr z,L_AB55		;ab1e
	ld a,(0e542h)		;ab20   ; (0xE542) es el ultimo que la toco, y ese no la vuelve a tocar
	cp (ix+015h)		;ab23
	jr z,L_AB55		;ab26
	ld a,(0e280h)		;ab28   ; con la pelota en poder de alguien la ventana es mas estrecha
	dec a			;ab2b
	jr z,ventana_estrecha_de_altura		;ab2c
	ld a,(ix+004h)		;ab2e   ; su altura menos la de la pelota
	sub c			;ab31
	add a,009h		;ab32   ; mas 9 y contra 18: la ventana es de +-8 pixeles a lo alto
	cp 012h		;ab34
	jr nc,L_AB55		;ab36
L_AB38:
	ld l,(ix+006h)		;ab38   ; su X
	ld h,(ix+007h)		;ab3b
	ld a,(0e2d0h)		;ab3e   ; y si este bando es el que va estampado...
	and a			;ab41
	jr z,L_AB48		;ab42
	ld a,l			;ab44
	and 0f8h		;ab45   ; ...su X se redondea a multiplos de 8, que es donde de verdad esta dibujado: sin esto el bando de sprites tendria ventaja
	ld l,a			;ab47
L_AB48:
	sbc hl,de		;ab48   ; la resta contra la pelota
	push de			;ab4a
	ld de,00008h		;ab4b   ; mas 8...
	add hl,de			;ab4e
	sla e		;ab4f   ; ...y menos 16: la ventana a lo ancho tambien es de +-8
	sbc hl,de		;ab51
	pop de			;ab53
	ret c			;ab54   ; con carry, la tiene al lado
L_AB55:
	exx			;ab55
	ld de,00020h		;ab56   ; 32 bytes
	add ix,de		;ab59
	exx			;ab5b
	djnz L_AB19		;ab5c
	xor a			;ab5e   ; ninguno de los seis: sin carry
	ret			;ab5f
ventana_estrecha_de_altura:
	ld a,(ix+004h)		;ab60
	sub c			;ab63
	add a,006h		;ab64   ; mas 6 contra 12: en el subestado 1 la ventana baja a +-5 pixeles
	cp 00ch		;ab66
	jr c,L_AB38		;ab68
	jr L_AB55		;ab6a

; ----------------------------------------------------------------------
; ===== LA ENTRADA: robarle la pelota al que la lleva =====
; ----------------------------------------------------------------------
intenta_robar_la_pelota:
	ld hl,0e55fh		;ab6c   ; (0xE55F) son los cuadros de gracia tras el ultimo robo
	ld a,(hl)			;ab6f
	and a			;ab70
	jr z,L_AB75		;ab71
	dec (hl)			;ab73
	ret			;ab74
L_AB75:
	ld a,001h		;ab75   ; aqui (0xE2D0) va a 1 fijo, porque el bando que defiende es siempre el que no lleva la camara
	ld (0e2d0h),a		;ab77
	ld a,(0e527h)		;ab7a   ; la camara sigue al que tiene la pelota...
	and a			;ab7d
	ld ix,0e1c0h		;ab7e   ; ...asi que quien entra es el otro
	jr z,L_AB88		;ab82
	ld ix,0e100h		;ab84
L_AB88:
	ld b,006h		;ab88   ; los seis
	call busca_a_quien_toca_la_pelota		;ab8a
	ret nc			;ab8d   ; ninguno llega
	xor a			;ab8e
	ld (0e566h),a		;ab8f   ; (0xE566) y (0xE567), los cerrojos del rebote, a cero
	ld (0e567h),a		;ab92
	ld a,018h		;ab95   ; 0x18: 24 cuadros hasta que se pueda volver a robar
	ld (0e55fh),a		;ab97
	ld a,(0e528h)		;ab9a   ; el que la lleva
	add a,a			;ab9d   ; por 32, en dos pasos, para meterlo en HL...
	add a,a			;ab9e
	add a,a			;ab9f
	add a,a			;aba0
	ld l,a			;aba1   ; ...cuatro dobleces en A y el quinto ya en HL
	ld h,000h		;aba2
	add hl,hl			;aba4
	ld de,0e102h		;aba5   ; ...sobre 0xE102, o sea su +2
	add hl,de			;aba8
	ld a,(ix+00fh)		;aba9   ; este `cp 006h` no lo mira nadie: el `ld a` de la linea siguiente y el `inc l` de mas abajo se comen las banderas
	cp 006h		;abac
	ld a,010h		;abae
	ld (hl),a			;abb0   ; al que pierde la pelota se le ponen 16 cuadros de castigo sin poder moverse
	inc l			;abb1
	ld c,(hl)			;abb2   ; y de paso se recoge su direccion, que es lo que decide si la entrada sale
	ld a,(ix+004h)		;abb3   ; la altura del que entra
	sub 028h		;abb6   ; fuera de la franja 0x28..0x8E -las dos bandas- el robo sale siempre
	cp 067h		;abb8
	jp nc,roba_la_pelota_con_pitido		;abba
	ld a,(ix+003h)		;abbd   ; y si el que entra esta parado, tambien: plantarse delante basta
	and a			;abc0
	jp z,roba_la_pelota_con_pitido		;abc1
	cp 005h		;abc4   ; la direccion del que entra, doblada contra la del que la lleva
	jr c,L_ABCA		;abc6
	sub 005h		;abc8
L_ABCA:
	cp c			;abca   ; coincidiendo, la entrada sale
	jp z,roba_la_pelota_con_pitido		;abcb
	add a,005h		;abce   ; y a cinco de distancia tambien; con las direcciones de 1 a 8 lo natural seria cuatro, asi que esto empareja 1 con 6, 2 con 7 y 3 con 8
	cp c			;abd0
	jp z,roba_la_pelota_con_pitido		;abd1
	ld a,(ix+003h)		;abd4   ; y si no sale, choque: al que entra se le redondea la direccion...
	inc a			;abd7
	and 00eh		;abd8   ; ...a la diagonal siguiente, con el `and 0x0E` que fuerza par
	ld (0e552h),a		;abda
	ld (ix+00ch),a		;abdd
	jp L_B57E		;abe0

; ----------------------------------------------------------------------
; ===== Y AHORA EL PORTERO =====
; ----------------------------------------------------------------------
el_portero_va_a_por_la_pelota:
	ld hl,(0e280h)		;abe3   ; los dos subestados de golpe: (0xE280) en L y (0xE281) en H
	ld a,l			;abe6   ; los dos a cero es la pelota suelta y rasa
	or h			;abe7
	jr z,L_ABEF		;abe8
	ld a,(0e54fh)		;abea   ; y si no, con (0xE54F) puesto ya hay un portero estirado y no se le manda otra cosa
	and a			;abed
	ret nz			;abee
L_ABEF:
	ld a,(0e54ah)		;abef   ; con la jugada parada, el portero tampoco
	and a			;abf2
	ret nz			;abf3
	ld a,l			;abf4
	cp 002h		;abf5   ; del subestado 2 en adelante -los saques- el portero no sale
	ret nc			;abf7
	ld a,(0e542h)		;abf8   ; (0xE542) a 0x80 es el "la ha tocado el portero": ni bando ni jugador de los doce
	cp 080h		;abfb
	ret z			;abfd
	ld a,(0e541h)		;abfe   ; y (0xE541) distinto de cero es que ya la tiene uno de los dos
	and a			;ac01
	ret nz			;ac02
	ld hl,(0e2a5h)		;ac03   ; el ancho de la pelota, 16 bits: el campo mide 640 pixeles y no cabe en uno
	ld a,h			;ac06
	and a			;ac07
	jr z,L_AC37		;ac08   ; con el byte alto a cero la pelota anda por la mitad izquierda: portero de la izquierda
	cp 002h		;ac0a   ; por debajo de 0x200 esta en el centro del campo y no hay portero que valga
	ret c			;ac0c
	ld c,00ah		;ac0d   ; diez pixeles de boca de porteria mientras la jugada esta en marcha...
	ld a,(0e280h)		;ac0f   ; ...pero con el partido y el jugador en su subestado 0 (nadie hace nada raro)...
	and a			;ac12
	jr nz,L_AC1D		;ac13
	ld a,(0e281h)		;ac15
	and a			;ac18
	jr nz,L_AC1D		;ac19
	ld c,03eh		;ac1b   ; ...la boca se abre a 62 pixeles: el portero barre mucho mas
L_AC1D:
	ld a,l			;ac1d   ; ancho de la pelota menos 0x242 (=578): la franja de la porteria derecha
	sub 042h		;ac1e
	cp c			;ac20
	ret nc			;ac21
	ld a,(0e33dh)		;ac22   ; +0x0D de la ficha del portero derecho: el dibujo, que dice si esta estirado
	ld c,a			;ac25
	ld a,(0e334h)		;ac26   ; +4, su altura
	call la_pelota_le_pasa_al_alcance		;ac29   ; y esta decide si la pelota le pasa por donde alcanza
	ret nc			;ac2c
	ld a,(0e54fh)		;ac2d   ; (0xE54F) lo ha puesto 0xAD02: distinto de cero es que la para ESTIRADO
	and a			;ac30
	jp nz,el_portero_rechaza		;ac31   ; estirado no la atrapa, la rechaza
	xor a			;ac34   ; de pie, la atrapa: bando 0
	jr el_portero_atrapa_la_pelota		;ac35
L_AC37:
	ld bc,01023h		;ac37   ; misma cuenta para la porteria izquierda; 0x23 de boca con la jugada viva...
	ld a,(0e280h)		;ac3a
	and a			;ac3d
	jr nz,L_AC49		;ac3e
	ld a,(0e281h)		;ac40
	and a			;ac43
	jr nz,L_AC49		;ac44
	ld bc,02710h		;ac46   ; ...y 0x10 de ancho desde el pixel 0x27 con todo parado
L_AC49:
	ld a,l			;ac49
	sub c			;ac4a
	cp b			;ac4b
	ret nc			;ac4c
	ld a,(0e35dh)		;ac4d   ; +0x0D del portero izquierdo
	ld c,a			;ac50
	ld a,(0e354h)		;ac51   ; y su altura
	call la_pelota_le_pasa_al_alcance		;ac54
	ret nc			;ac57
	ld a,(0e54fh)		;ac58
	and a			;ac5b
	jr nz,L_ACCC		;ac5c
	ld a,001h		;ac5e
el_portero_atrapa_la_pelota:		; la coge, se la queda y el saque pasa a ser suyo
	ld (0e527h),a		;ac60   ; la camara se pasa al bando del portero que la ha cogido
	ld (0e283h),a		;ac63   ; (0xE283) es el lado al que mira la jugada, y queda igual que la camara
	ld hl,09f01h		;ac66   ; la vuelta de esta rutina no es a quien llamo: se fuerza a 0x9F01, que pone (0xE538) apuntando a la ficha del portero
	push hl			;ac69
	inc a			;ac6a   ; el bando 0 da el portero 1 y el bando 1 el portero 2
	ld (0e541h),a		;ac6b   ; (0xE541) = 1 o 2 segun que portero la tiene; a cero, ninguno
	ld hl,00037h		;ac6e   ; la pelota se planta en la boca de la porteria derecha, x = 0x37...
	dec a			;ac71   ; se deshace el `inc a` para volver a saber de que bando se venia
	jr nz,L_AC77		;ac72
	ld hl,00240h		;ac74   ; ...o en la izquierda, x = 0x240 (576)
L_AC77:
	ld (0e2a5h),hl		;ac77
	ld a,005h		;ac7a
	ld (0e280h),a		;ac7c   ; subestado 5 del partido: el portero con la pelota en las manos
	ld a,0ffh		;ac7f   ; nadie del campo la lleva
	ld (0e528h),a		;ac81
	push de			;ac84   ; DE trae la altura del portero y BC su dibujo, y los dos hacen falta luego
	push bc			;ac85
	ld a,(0e528h)		;ac86   ; con 0xFF, 0xA201 apunta IX fuera de las doce fichas; se hace igual porque el que sigue lo espera asi
	call L_A201		;ac89   ; con 0xFF, 0xA201 deja IX en 0xE2E0, fuera de las doce fichas; no importa porque lo que sigue no la lee
	call borra_las_marcas_de_la_pelota		;ac8c   ; le borra a la pelota el rastro de por donde venia
	ld a,01fh		;ac8f
	call pide_un_sonido		;ac91   ; el sonido de atraparla
	pop bc			;ac94
	pop de			;ac95
	ld a,c			;ac96   ; C es el dibujo del portero, que llega desde 0xABE3
	cp 006h		;ac97   ; el dibujo 6 y el 7 son las dos estiradas, y cada una deja la pelota a distinta altura
	jr z,L_ACAB		;ac99
	cp 007h		;ac9b
	jr z,L_ACB6		;ac9d
	ld a,008h		;ac9f   ; de pie: la pelota se queda 14 pixeles por delante de el
	ld (0e2aah),a		;aca1
	ld a,e			;aca4   ; E es la altura del portero, que dejo puesta 0xAD02
	add a,00eh		;aca5
	ld (0e2a1h),a		;aca7
	ret			;acaa
L_ACAB:
	xor a			;acab   ; estirado hacia un lado: dos pixeles por detras
	ld (0e2aah),a		;acac
	ld a,e			;acaf
	sub 002h		;acb0
	ld (0e2a1h),a		;acb2
	ret			;acb5
L_ACB6:
	xor a			;acb6   ; y hacia el otro, treinta por delante
	ld (0e2aah),a		;acb7
	ld a,e			;acba
	add a,01eh		;acbb
	ld (0e2a1h),a		;acbd
	ret			;acc0
el_portero_rechaza:		; rebota la pelota en vez de quedarsela, cuando la para estirado
	ld a,(0e2a8h)		;acc1   ; el byte alto de la velocidad a lo ancho; con el bit 7 puesto ya va hacia el otro lado y no hay nada que desviar
	add a,a			;acc4
	ret c			;acc5
	xor a			;acc6
	ld de,0ff40h		;acc7   ; -0xC0 a la velocidad: la manda de vuelta hacia el centro
	jr L_ACD6		;acca
L_ACCC:
	ld a,(0e2a8h)		;accc   ; el portero de la izquierda mira el signo contrario...
	add a,a			;accf
	ret nc			;acd0
	ld a,001h		;acd1
	ld de,000c0h		;acd3   ; ...y la empuja +0xC0
L_ACD6:
	ld (0e283h),a		;acd6   ; (0xE283) apunta hacia donde sale rechazada
	ld hl,(0e2a7h)		;acd9   ; la velocidad a lo ancho, que es de 16 bits
	add hl,de			;acdc
	ld (0e2a7h),hl		;acdd
	ld hl,(0e2abh)		;ace0   ; (0xE2AB) es la velocidad de subida: +0x80 la levanta del suelo, el rechace sale alto
	ld de,00080h		;ace3
	add hl,de			;ace6
	ld (0e2abh),hl		;ace7
	ld hl,(0e2a2h)		;acea   ; y (0xE2A2), la velocidad en profundidad, se desvia hacia el lado de la estirada
	ld a,(0e54fh)		;aced
	ld de,0ffech		;acf0   ; -0x14 en profundidad con una estirada...
	dec a			;acf3
	jr z,L_ACF9		;acf4
	ld de,00020h		;acf6   ; ...y +0x20 con la otra: el rechace sale hacia el lado por el que se tiro
L_ACF9:
	add hl,de			;acf9
	ld (0e2a2h),hl		;acfa
	ld a,04dh		;acfd   ; el sonido del rechace
	jp pide_un_sonido		;acff
la_pelota_le_pasa_al_alcance:		; devuelve carry si el portero llega, y apunta en (0xE54F) con que estirada
	ld e,a			;ad02   ; E = la altura del portero
	xor a			;ad03
	ld (0e566h),a		;ad04   ; (0xE566) a cero: por defecto no hay parada
	ld a,(0e2a1h)		;ad07   ; la altura de la pelota, menos los 14 pixeles con que se dibuja
	sub 00eh		;ad0a
	ld d,a			;ad0c   ; D es la altura util de la pelota, la que tendria posada
	ld a,c			;ad0d
	cp 006h		;ad0e   ; el dibujo 6 y el 7 son las estiradas; cualquier otro es de pie
	jr z,L_AD1D		;ad10
	cp 007h		;ad12
	jr z,L_AD2F		;ad14
	ld a,d			;ad16   ; de pie alcanza una franja de 13 pixeles centrada en el
	sub e			;ad17
	add a,006h		;ad18   ; el +6 centra la franja: seis pixeles por encima y seis por debajo
	cp 00dh		;ad1a   ; trece pixeles de alcance con el portero de pie
	ret			;ad1c
L_AD1D:
	ld a,d			;ad1d   ; estirado hacia un lado alcanza 24 pixeles, pero desplazados
	sub e			;ad1e
	add a,008h		;ad1f
	add a,010h		;ad21   ; el 0x10 de mas es el tope por el otro extremo de la estirada
	ret nc			;ad23
	sub 008h		;ad24
	ccf			;ad26   ; el `ccf` da la vuelta al carry, que hasta aqui queria decir lo contrario
	ret c			;ad27
	ld a,001h		;ad28   ; (0xE54F) = 1: la ha parado con la estirada de un lado
L_AD2A:
	ld (0e54fh),a		;ad2a
	scf			;ad2d   ; carry a la salida: es la senal de que la ha alcanzado
	ret			;ad2e
L_AD2F:
	ld a,d			;ad2f   ; la otra estirada, la simetrica
	sub e			;ad30
	sub 008h		;ad31
	sub 010h		;ad33
	ret nc			;ad35
	add a,008h		;ad36
	ccf			;ad38
	ret c			;ad39
	ld a,002h		;ad3a   ; (0xE54F) = 2, la del otro lado
	jr L_AD2A		;ad3c
cuenta_atras_del_saque:		; mientras (0xE532) vale 1 o 2, hace el gesto de sacar y suelta la pelota
	ld de,0e18dh		;ad3e   ; la ficha del que saca: 0xE18D es el jugador 4 del primer bando...
	ld a,(0e0f7h)		;ad41
	and a			;ad44
	jr z,L_AD4A		;ad45
	ld de,0e1edh		;ad47   ; ...y 0xE1ED el 4 del segundo; (0xE0F7) dice quien saca
L_AD4A:
	ld hl,0e532h		;ad4a   ; (0xE532) distingue el juego en marcha de las pausas
	ld a,(hl)			;ad4d
	dec a			;ad4e
	ret m			;ad4f   ; a cero -juego normal- no hay nada que hacer
	jr nz,L_AD89		;ad50   ; en el 2 el gesto ya esta en marcha y lo lleva 0xAD89
	ld a,(0e527h)		;ad52   ; con la camara en el bando de la maquina se lee el mando 2, y si no el 1
	and a			;ad55
	jr z,L_AD64		;ad56
	ld a,(0e002h)		;ad58   ; el bit 5 de (0xE002): con dos humanos, el saque lo pide el mando 2
	and 020h		;ad5b
	jr z,L_AD71		;ad5d
	ld a,(0e008h)		;ad5f
	jr L_AD67		;ad62
L_AD64:
	ld a,(0e006h)		;ad64
L_AD67:
	and 030h		;ad67   ; los dos botones de disparo: pulsando cualquiera se saca antes
	jr nz,L_AD71		;ad69
	ld a,(0e53ch)		;ad6b   ; (0xE53C) es la cuenta que hay que dejar correr si nadie pulsa
	cp 080h		;ad6e
	ret nc			;ad70
L_AD71:
	inc (hl)			;ad71   ; (0xE532) sube a 2: empieza el gesto
	dec l			;ad72   ; (0xE531) esta justo debajo de (0xE532)
	ld (hl),01ch		;ad73   ; (0xE531) = 28 cuadros de gesto
	ld a,003h		;ad75
	ld (de),a			;ad77   ; +3 de la ficha: mira hacia abajo
	dec e			;ad78   ; y de +0x0D se baja a +0x0C
	ld a,(0e0f7h)		;ad79
	and a			;ad7c
	ld a,006h		;ad7d
	jr z,L_AD83		;ad7f
	ld a,008h		;ad81
L_AD83:
	ld (de),a			;ad83   ; y +2, el dibujo, distinto para cada bando
	ld a,057h		;ad84
	jp pide_un_sonido		;ad86   ; el sonido del saque
L_AD89:
	dec l			;ad89
	dec (hl)			;ad8a   ; se descuenta el cuadro; al llegar a cero, 0xADB6 devuelve (0xE532) a cero
	jr z,L_ADB6		;ad8b
	ld a,(hl)			;ad8d
	sub 00ch		;ad8e   ; a los 12 cuadros que faltan se borra el dibujo del gesto
	jr nz,L_AD98		;ad90
	ld (de),a			;ad92
	ld hl,0fff3h		;ad93   ; 0xFFF3 es -13: de +0x0D al +0 de la ficha, que tambien se borra
	add hl,de			;ad96
	ld (hl),a			;ad97
L_AD98:
	ld hl,0e2a1h		;ad98   ; la pelota baja un pixel de altura por cuadro mientras dura
	dec (hl)			;ad9b
	ld a,(0e003h)		;ad9c   ; del contador de cuadros sale el azar: solo en la mitad de ellos se mueve tambien a lo ancho
	ld b,a			;ad9f
	rra			;ada0   ; el bit 0 del contador de cuadros: un cuadro si y otro no
	jp c,cambia_el_dibujo_de_la_pelota		;ada1
	ld a,(0e0f7h)		;ada4
	and a			;ada7
	ld c,0ffh		;ada8   ; y hacia un lado o hacia el otro segun quien saque
	jr z,L_ADAE		;adaa
	ld c,001h		;adac   ; +1 o -1 segun el bando, que cada uno saca hacia su lado
L_ADAE:
	ld l,0a5h		;adae
	ld a,(hl)			;adb0   ; HL ya trae 0xE2 arriba, asi que basta con poner la L
	add a,c			;adb1
	ld (hl),a			;adb2
	jp cambia_el_dibujo_de_la_pelota		;adb3
L_ADB6:
	inc hl			;adb6   ; se acabo el gesto: (0xE532) vuelve a cero y la pelota queda en juego
	ld (hl),000h		;adb7
	ret			;adb9
elige_el_destacado_de_la_izquierda:		; con la pelota a la izquierda del suyo, pasa el mando 2 al jugador mas adelantado
	ld a,(0e280h)		;adba   ; solo con el partido en el subestado 1, el de jugada viva
	dec a			;adbd
	ret nz			;adbe
	ld a,(0e002h)		;adbf   ; el bit 5 de (0xE002): con dos humanos esto no se hace
	and 020h		;adc2
	ret nz			;adc4
	ld a,(0e527h)		;adc5   ; ni cuando la camara sigue al otro bando
	and a			;adc8
	ret nz			;adc9
	ld a,(0e52dh)		;adca   ; (0xE52D) es el jugador que el mando 2 lleva ahora mismo
	call L_A201		;adcd
	ld de,(0e2a5h)		;add0   ; el ancho de la pelota; si pasa de 255 no se cambia de jugador
	ld a,d			;add4
	and a			;add5
	ret nz			;add6
	ld l,(ix+006h)		;add7   ; su ancho contra el de la pelota
	ld h,(ix+007h)		;adda
	sbc hl,de		;addd
	ret c			;addf   ; con el jugador ya por detras de la pelota, no hay nada que corregir
	ld a,h			;ade0
	and a			;ade1
	jr nz,L_ADE8		;ade2
	ld a,l			;ade4
	cp 020h		;ade5   ; ni tampoco si le saca menos de 32 pixeles
	ret c			;ade7
L_ADE8:
	ld b,006h		;ade8   ; se recorren los seis del segundo bando, 0xE1C0 en adelante
	ld ix,0e1c0h		;adea   ; 0xE1C0 es la primera ficha del segundo bando
L_ADEE:
	ld l,(ix+006h)		;adee
	ld h,(ix+007h)		;adf1
	and a			;adf4
	sbc hl,de		;adf5   ; el que este por delante de la pelota
	jr nc,L_AE06		;adf7
	ld a,(ix+00ah)		;adf9
	cp 0e0h		;adfc   ; +0x0A a 0xE0 significa que ese jugador no esta en pantalla: no vale
	jr z,L_AE06		;adfe
	ld a,(ix+015h)		;ae00   ; +0x15 es su numero; se queda con el ultimo que cumpla
	ld (0e52dh),a		;ae03
L_AE06:
	exx			;ae06
	ld de,00020h		;ae07   ; de una ficha a la siguiente van 32 bytes
	add ix,de		;ae0a
	exx			;ae0c
	djnz L_ADEE		;ae0d   ; se recorren los seis y gana el ultimo que cumpla, o sea el mas adelantado
	ret			;ae0f
decide_la_direccion_de_la_maquina:		; el cerebro del jugador que no lleva mando
	ld a,(0e527h)		;ae10
	and a			;ae13
	jr nz,L_AE16		;ae14   ; este salto va a la instruccion de al lado: la comprobacion de (0xE527) no llega a hacer nada
L_AE16:
	ld a,(ix+001h)		;ae16   ; +1 son los cuadros que le quedan parado; hasta que se agoten no piensa
	and a			;ae19
	ret nz			;ae1a
	call descuenta_la_reaccion		;ae1b   ; y +0x1A es la cuenta de reaccion, la que reparte el nivel
	ret c			;ae1e   ; con carry aun le quedan cuadros de reaccion y no piensa nada
	ld a,(0e280h)		;ae1f   ; con el partido fuera del subestado 0 se va a por la pelota; en el 0 -saque- manda 0xAF44
	and a			;ae22
	jp z,la_maquina_en_el_saque		;ae23
	ld hl,0a5dch		;ae26   ; la vuelta se fuerza a 0xA5DC, que es quien convierte la direccion elegida en movimiento
	push hl			;ae29
	ld hl,(0e2a5h)		;ae2a   ; LA FOTO: se apunta en la ficha donde esta la pelota AHORA...
	ld a,(0e2a1h)		;ae2d   ; la altura de la pelota AHORA, que es lo que se congela en la ficha
	ld (ix+016h),a		;ae30   ; ...su altura en +0x16...
	ld (ix+017h),l		;ae33   ; ...y su ancho de 16 bits en +0x17/+0x18
	ld (ix+018h),h		;ae36
	ld a,(ix+016h)		;ae39   ; diferencia de alturas entre la pelota y el jugador, descontando los 14 del dibujo
	sub (ix+004h)		;ae3c
	sub 00eh		;ae3f   ; los 14 pixeles con que la pelota se dibuja por delante del jugador
	ld c,a			;ae41
	add a,030h		;ae42   ; mas de 48 pixeles arriba o abajo: demasiado lejos, se va por la ruta larga de 0xA13B
	cp 060h		;ae44
	jp nc,L_A13B		;ae46
	ld e,(ix+006h)		;ae49   ; lo mismo a lo ancho: el jugador se mide 4 pixeles por delante
	ld d,(ix+007h)		;ae4c
	dec de			;ae4f   ; cuatro pixeles menos: el jugador alcanza un poco por delante de su punto
	dec de			;ae50
	dec de			;ae51
	dec de			;ae52
	and a			;ae53
	sbc hl,de		;ae54
	ld b,l			;ae56   ; B se queda con la diferencia a lo ancho, ya en un solo byte
	ld de,00030h		;ae57   ; la ventana util es de 0x60 pixeles empezando 0x30 por detras
	add hl,de			;ae5a
	ld e,060h		;ae5b
	and a			;ae5d
	sbc hl,de		;ae5e
	jp nc,L_A13B		;ae60   ; fuera de la ventana se va a 0xA13B, que persigue la FOTO vieja en vez de la pelota
	ld a,(0e53ah)		;ae63   ; (0xE53A) es la direccion en la que va la pelota de verdad
	cp (ix+019h)		;ae66   ; +0x19 es la que tenia apuntada; si la pelota ha CAMBIADO de rumbo...
	jr z,va_hacia_la_pelota_o_se_espera		;ae69
	ld de,laf34h		;ae6b   ; ...hay que volver a pensarlo, y eso cuesta los cuadros de la tabla de 0xAF35
para_y_cuenta_la_reaccion:		; apunta el rumbo nuevo y deja al jugador quieto los cuadros que diga el nivel
	ld (ix+019h),a		;ae6e
	ld a,(0e069h)		;ae71   ; el nivel de juego, 1 a 5, indexa la tabla; DE entra apuntando una entrada por debajo
	call suma_a_de		;ae74
	ld a,(de)			;ae77   ; el byte de la tabla son los cuadros que se queda parado
	ld (ix+01ah),a		;ae78   ; +0x1A recibe la espera: 8 cuadros en el nivel 1, uno solo en el 5
	xor a			;ae7b
	ld (ix+003h),a		;ae7c   ; mientras tanto, sin direccion y sin cuadros de gracia
	ld (ix+001h),a		;ae7f   ; y sin cuadros de gracia: al acabar la espera se vuelve a pensar entero
	ret			;ae82
va_hacia_la_pelota_o_se_espera:		; con la pelota en el mismo rumbo, decide si perseguirla ya
	ld a,(ix+015h)		;ae83   ; 0xE410 + numero de jugador: la casilla de ese jugador en el reparto del campo
	ld de,0e410h		;ae86
	call suma_a_de		;ae89
	ld a,(de)			;ae8c
	cp 009h		;ae8d   ; por debajo de 9 son los del fondo, y esos se lo piensan de otra forma
	ld a,(0e069h)		;ae8f   ; el nivel se deja cargado, que lo miran los dos caminos
	jr c,L_AEA8		;ae92
	cp 005h		;ae94   ; en el nivel 5 los adelantados salen SIEMPRE, sin sorteo
	jr z,L_AEBD		;ae96
	ld l,080h		;ae98   ; por debajo del 5, el contador de cuadros hace de dado: umbral 0x80...
	dec a			;ae9a
	jr nz,L_AE9F		;ae9b
	ld l,040h		;ae9d   ; ...y solo 0x40 en el nivel 1, con lo que casi siempre sale el caso perezoso
L_AE9F:
	ld a,(0e003h)		;ae9f
	cp l			;aea2   ; el contador de cuadros contra el umbral: ese es todo el azar del cartucho
	jp nc,apunta_por_detras_de_la_pelota		;aea3   ; el perezoso: apunta 32 pixeles POR DETRAS de la pelota en vez de a ella
	jr L_AEBD		;aea6
L_AEA8:
	cp 003h		;aea8   ; los del fondo con nivel 3 o mas van directos
	jr nc,L_AEBD		;aeaa
	ld l,080h		;aeac   ; en los niveles 1 y 2 vuelve a haber dado, con umbral 0xC0 en el 1
	dec a			;aeae
	jr z,$+3		;aeaf   ; ...y este salto de un solo byte cae sobre el 0xC0 del `ld l,0c0h`, que se ejecuta como un `ret nz` inofensivo: asi el nivel 2 sube el umbral a 0xC0 y solo se descuelga una de cada cuatro veces
	ld l,0c0h		;aeb1   ; y ese 0xC0, ejecutado suelto, es un `ret nz` que jamas retorna: a el solo se llega con Z puesto
	ld a,(0e003h)		;aeb3
	cp l			;aeb6   ; el mismo dado, con el umbral que haya quedado
	ld de,0fff0h		;aeb7   ; y su desvio es de 16 pixeles
	jp nc,L_AF3D		;aeba

; ----------------------------------------------------------------------
; ----- del vector al codigo de direccion -----
; ----------------------------------------------------------------------
L_AEBD:
	ld hl,00000h		;aebd
	ld a,(0e53ah)		;aec0   ; la direccion de la pelota: las impares 1,3,5,7 son las rectas...
	and 001h		;aec3
	jr z,direccion_hacia_la_pelota_en_diagonal		;aec5   ; ...y las pares, las diagonales, se resuelven en 0xAEFD
	ld a,c			;aec7   ; con la pelota recta se compara cual de los dos desvios es mayor
	and a			;aec8   ; C es la diferencia en altura...
	jp p,L_AED0		;aec9   ; L se pone a 1 si la pelota queda por encima
	neg		;aecc   ; ...que se pone en positivo si la pelota queda por encima...
	inc l			;aece   ; ...y L se acuerda de que era negativa
	ld c,a			;aecf
L_AED0:
	ld a,b			;aed0   ; B es la diferencia a lo ancho, y H hace el mismo papel que L
	and a			;aed1   ; y H a 1 si queda a la izquierda
	jp p,L_AED8		;aed2
	neg		;aed5
	inc h			;aed7
L_AED8:
	cp c			;aed8   ; mandando el desvio a lo ancho, se va en horizontal
	jr c,L_AEE7		;aed9
L_AEDB:
	ld a,h			;aedb
	and a			;aedc
	ld a,001h		;aedd   ; 1 es derecha y 5 izquierda
	jr z,L_AEE3		;aedf
	ld a,005h		;aee1
L_AEE3:
	ld (ix+003h),a		;aee3
	ret			;aee6
L_AEE7:
	ld a,c			;aee7
	cp 005h		;aee8   ; aunque mande la altura, si son menos de 5 pixeles y el ancho pasa de 2 se sigue yendo en horizontal
	jr nc,L_AEF1		;aeea   ; ...pero si esa altura no llega a cinco pixeles...
	ld a,b			;aeec
	cp 002h		;aeed   ; ...y a lo ancho hay mas de dos, se sigue yendo en horizontal: asi no se queda haciendo eses en vertical
	jr nc,L_AEDB		;aeef
L_AEF1:
	ld a,l			;aef1
	and a			;aef2
	ld a,003h		;aef3   ; 3 es abajo y 7 arriba
	jr z,L_AEF9		;aef5
	ld a,007h		;aef7
L_AEF9:
	ld (ix+003h),a		;aef9
	ret			;aefc
direccion_hacia_la_pelota_en_diagonal:		; monta el indice de la tabla de 0xA47B con los dos signos
	ld e,001h		;aefd   ; E = 1 a la derecha, 2 a la izquierda...
	ld a,b			;aeff
	and a			;af00
	jp p,L_AF07		;af01
	inc e			;af04   ; E = 2 es hacia la izquierda
	neg		;af05
L_AF07:
	cp 003h		;af07   ; ...y 0 si el desvio a lo ancho no llega a 3 pixeles
	jr nc,L_AF0D		;af09
	ld e,000h		;af0b
L_AF0D:
	ld a,c			;af0d
	and a			;af0e
	ld d,008h		;af0f   ; D = 8 hacia abajo, 4 hacia arriba...
	jp p,L_AF18		;af11
	ld d,004h		;af14   ; D = 4 es hacia arriba
	neg		;af16
L_AF18:
	cp 004h		;af18   ; ...y 0 si el desvio en altura no llega a 4
	jr nc,L_AF20		;af1a
	jr z,L_AF20		;af1c   ; este `jr z` no hace nada: el `jr nc` de arriba ya se ha llevado el caso de la igualdad
	ld d,000h		;af1e
L_AF20:
	ld a,d			;af20   ; el indice es la suma de los dos signos: nueve combinaciones
	or e			;af21
	ld hl,0a47bh		;af22   ; la tabla de 0xA47B: nueve direcciones, una por cada combinacion de los dos signos
	call suma_a_hl		;af25
	ld a,(hl)			;af28
	and 00fh		;af29   ; el nibble bajo es la direccion
	ld (ix+003h),a		;af2b
	cp (hl)			;af2e   ; el bit 7 marca las cuatro DIAGONALES...
	ret z			;af2f   ; sin el bit 7 la direccion es recta y se toma sin esperar
	ld (ix+001h),008h		;af30   ; ...y meterse en una cuesta 8 cuadros parado
L_AF34:
	ret			;af34

; ----------------------------------------------------------------------
; DATOS tiempos_de_reaccion_por_nivel: cinco bytes -08, 04, 04, 02, 01-
;   indexados por el nivel; van a (ix+0x1A), que se decrementa: cuanto mas
;   alto el nivel, antes reacciona
;   0xaf35..0xaf3a  (5 bytes)
DATA_tiempos_de_reaccion_por_nivel:
	defb 008h	; af35
	defb 004h	; af36
	defb 004h	; af37
	defb 002h	; af38
	defb 001h	; af39

; ======================================================================
; CODIGO 0xaf3a..0xafbb  (129 bytes)
; ======================================================================


apunta_por_detras_de_la_pelota:		; el objetivo se retrasa 32 pixeles: asi la maquina no se pega a la pelota
	ld de,0ffe0h		;af3a   ; los 32 pixeles del caso perezoso de 0xAEA3
L_AF3D:
	ld hl,(0e2a5h)		;af3d   ; el desvio ya viene en DE desde 0xAEB7 en el otro caso
	add hl,de			;af40
	ex de,hl			;af41
	jr encara_el_objetivo		;af42
la_maquina_en_el_saque:		; mientras el partido esta en el subestado 0, el jugador espera a que la pelota caiga
	ld a,(0e540h)		;af44   ; (0xE540) puesto: no hay espera que valga
	and a			;af47
	jr nz,L_AF68		;af48
	ld a,(0e069h)		;af4a   ; el nivel mas uno hace de umbral: cuanto mas alto el nivel, antes se mueve
	inc a			;af4d
	ld c,a			;af4e   ; C es el umbral, que sube con el nivel
	ld hl,(0e2aah)		;af4f   ; (0xE2AA) es lo que la pelota lleva levantada del suelo
	ld a,l			;af52
	or h			;af53   ; con (0xE2AA) a cero la pelota esta posada y se va a por ella
	jr z,L_AF68		;af54   ; con la pelota en el suelo se va a por ella
	ld a,(0e567h)		;af56   ; (0xE567) puesto salta el umbral
	and a			;af59
	jr nz,L_AF60		;af5a
	ld a,l			;af5c
	cp c			;af5d   ; con la pelota mas alta que el umbral, quieto y sin direccion
	jr c,L_AF68		;af5e
L_AF60:
	xor a			;af60
	ld (ix+003h),a		;af61
	ld (ix+001h),a		;af64
	ret			;af67
L_AF68:
	ld de,(0e2a5h)		;af68   ; sin caso especial, el objetivo es la pelota misma
encara_el_objetivo:		; traduce la distancia al objetivo en una de las ocho direcciones
	ld l,(ix+006h)		;af6c   ; el ancho del jugador contra el del objetivo
	ld h,(ix+007h)		;af6f
	ld c,001h		;af72   ; C = 1 si el objetivo queda a la izquierda...
	sbc hl,de		;af74
	jr nc,L_AF7C		;af76
	inc c			;af78   ; negando la resta se queda con la distancia siempre en positivo
	call L_A211		;af79   ; ...y 2 si queda a la derecha, negando la resta
L_AF7C:
	ld de,00002h		;af7c
	and a			;af7f
	sbc hl,de		;af80
	jr nc,L_AF86		;af82
	ld c,000h		;af84   ; con menos de 2 pixeles de diferencia, C = 0: ya esta encarado
L_AF86:
	ld a,(0e2a1h)		;af86   ; misma cuenta en altura, con los 14 pixeles del dibujo descontados
	sub 00eh		;af89
	sub (ix+004h)		;af8b   ; y la altura del jugador
	ld b,004h		;af8e   ; B = 4 si el objetivo esta mas abajo, 8 si esta mas arriba...
	jr nc,L_AF94		;af90
	ld b,008h		;af92
L_AF94:
	add a,005h		;af94   ; ...y 0 si estan a menos de 5 pixeles
	cp 00ah		;af96
	jr nc,L_AF9C		;af98
	ld b,000h		;af9a
L_AF9C:
	ld a,b			;af9c
	or c			;af9d
	ld hl,0afc0h		;af9e   ; la tabla gemela de la de 0xA47B, aqui en 0xAFC0
	call suma_a_hl		;afa1
	ld a,(hl)			;afa4
	and 00fh		;afa5   ; el nibble bajo; el bit 7 marca las diagonales igual que en la otra tabla
	ld c,a			;afa7
	ld a,(ix+003h)		;afa8   ; sin direccion previa se toma la nueva sin pensarlo
	and a			;afab
	jr z,L_AFB5		;afac
	cp c			;afae   ; pero CAMBIAR de direccion cuesta la espera de la tabla de 0xAFBB...
	ld de,0afbah		;afaf   ; ...que en el nivel 5 es de CERO cuadros: la maquina gira al instante
	jp nz,para_y_cuenta_la_reaccion		;afb2   ; cambiar de direccion se paga por la misma puerta que cambiar de objetivo
L_AFB5:
	ld (ix+003h),c		;afb5
	jp no_te_salgas_del_campo		;afb8   ; y con la direccion puesta se sale por el que la convierte en movimiento

; ----------------------------------------------------------------------
; DATOS dos_tablas_afbb: cinco bytes por nivel -08, 06, 04, 02, 00- con la
;   base en 0xAFBA, que cae sobre el ultimo byte de un `jp`; y once mas,
;   gemelas de las de 0xA47B
;   0xafbb..0xafcb  (16 bytes)
DATA_dos_tablas_afbb:
	defb 008h	; afbb
	defb 006h	; afbc
	defb 004h	; afbd
	defb 002h	; afbe
	defb 000h	; afbf
	defb 000h	; afc0
	defb 005h	; afc1
	defb 001h	; afc2
	defb 000h	; afc3
	defb 083h	; afc4
	defb 084h	; afc5
	defb 082h	; afc6
	defb 000h	; afc7
	defb 087h	; afc8
	defb 086h	; afc9
	defb 088h	; afca

; ======================================================================
; CODIGO 0xafcb..0xafe9  (30 bytes)
; ======================================================================


descuenta_la_reaccion:		; devuelve carry mientras al jugador le queden cuadros de reaccion
	ld a,(ix+01ah)		;afcb   ; +0x1A a cero: ya ha reaccionado, se sigue pensando
	and a			;afce
	ret z			;afcf
	dec (ix+01ah)		;afd0   ; un cuadro menos, y mientras tanto quieto
	ld (ix+003h),000h		;afd3
	scf			;afd7
	ret			;afd8
la_maquina_lleva_la_pelota:		; escribe el mando 2 en (0xE009) segun la subescena de (0xE370)
	ld a,008h		;afd9   ; 8 = derecha: por defecto tira hacia adelante
	ld (0e009h),a		;afdb
	ld a,(0e280h)		;afde   ; solo con el partido en el subestado 1
	dec a			;afe1
	ret nz			;afe2
	ld a,(0e370h)		;afe3   ; (0xE370) es la subescena; detras del call va la tabla de seis punteros
	call despacha		;afe6

; ----------------------------------------------------------------------
; DATOS pasos_de_la_maquina_con_la_pelota: 6 entradas, repartidas por (0xE370)
;   desde 0xAFE6. La maquina no mueve nada a mano: cada paso escribe en
;   (0xE009), que es el mando 2 que leeria un humano
;   0xafe9..0xaff5  (12 bytes)
DATA_pasos_de_la_maquina_con_la_pelota:
	defw 0aff5h,0b046h,0b084h,0b1f6h,0b213h,0b255h	; afe9

; ======================================================================
; CODIGO 0xaff5..0xb094  (159 bytes)
; ======================================================================


mira_en_que_zona_esta:		; reparte la subescena y el tiempo segun donde este la pelota
	call despeja_tras_el_tiro		;aff5   ; antes de nada, la salida rapida del despeje
	ld hl,0e370h		;aff8
	ld a,(0e52bh)		;affb   ; (0xE52B) es la zona: 0xA24D la monta con cinco franjas de ancho por tres de alto, de 0 a 14
	cp 006h		;affe   ; zonas 0 a 5: propia mitad
	jr c,L_B01A		;b000
	cp 00ah		;b002   ; zonas 6 a 9: el centro del campo
	jr c,L_B03F		;b004
	ld a,r		;b006   ; en la zona de ataque, el registro R hace de moneda...
	rra			;b008
	jr c,L_B021		;b009
	ld (hl),002h		;b00b   ; ...cara, la subescena 2, la de correr esquivando
	inc l			;b00d
	ld c,060h		;b00e   ; y 0x60 cuadros de plazo
L_B010:
	ld a,(0e069h)		;b010   ; al plazo se le restan cuatro cuadros por nivel: en el 5 se le da un 20 % menos de tiempo antes de replantearse
	add a,a			;b013   ; el nivel por cuatro
	add a,a			;b014
	sub c			;b015
	neg		;b016
	ld (hl),a			;b018   ; y el resultado va a (0xE371), la cuenta atras de la subescena
	ret			;b019
L_B01A:
	ld (hl),001h		;b01a   ; en su propia mitad, subescena 1 y solo 0x30 cuadros: no se entretiene atras
	inc l			;b01c
	ld c,030h		;b01d
	jr L_B010		;b01f
L_B021:
	ld a,(0e2a6h)		;b021   ; cruz: se mira si toca tirar ya; el byte alto del ancho de la pelota...
	cp 002h		;b024   ; ...ha de pasar de 0x200, o sea el ultimo tercio
	jr c,L_B03F		;b026
	ld a,r		;b028   ; y otro sorteo con R, ahora de dos bits: solo una de cada cuatro veces
	and 006h		;b02a
	jp nz,L_B03F		;b02c
	ld a,(0e2a1h)		;b02f   ; con la pelota entre 0x38 y 0xC0 de altura, o por encima de 0x30, se salta a 0xB0A1: subescena 4, a por el tiro
	sub 038h		;b032
	cp 088h		;b034
	jr c,$+107		;b036
	ld a,(0e2a1h)		;b038
	cp 030h		;b03b
	jr c,$+100		;b03d
L_B03F:
	ld (hl),001h		;b03f   ; el centro del campo acaba tambien en la subescena 1, pero con el plazo largo
	inc l			;b041
	ld c,060h		;b042
	jr L_B010		;b044
corre_o_la_pasa:		; la subescena 1: hace lo mismo que la 2, y si no ha salido nada, pasa
	call corre_esquivando_al_rival		;b046   ; primero, todo lo de la subescena 2
	ld hl,0e370h		;b049
	ld a,(hl)			;b04c   ; si aquello ya ha cambiado de subescena, no se toca nada mas
	and a			;b04d
	ret nz			;b04e
	ld a,(0e54ch)		;b04f   ; (0xE54C) lo pone 0xB115 cuando tiene un rival encima
	and a			;b052
	jr nz,L_B05C		;b053
	ld a,(0e52bh)		;b055   ; y la zona 13 es la de delante de la porteria contraria
	cp 00dh		;b058   ; la zona 13 es la franja central de la ultima columna, la de delante del marco
	jr z,L_B062		;b05a
L_B05C:
	ld a,001h		;b05c   ; sin rival cerca y fuera de esa zona, (0xE53F) = 1: pase
	ld (0e53fh),a		;b05e
	ret			;b061
L_B062:
	ld (hl),001h		;b062   ; en la zona buena se rearma la subescena 1 con un solo cuadro de plazo
	inc l			;b064   ; y (0xE371) a 1: la subescena 1 se revisa al cuadro siguiente
	ld (hl),001h		;b065
	ld l,(ix+004h)		;b067   ; L = la altura del jugador y H = el byte alto de su ancho: los dos juntos han de pasar de 0x250
	ld h,(ix+007h)		;b06a
	ld de,00250h		;b06d
	sbc hl,de		;b070
	ret c			;b072
	jr $+64		;b073   ; y si pasan, a 0xB0B3: apuntar el tiro
le_pilla_el_rival_de_cara:		; carry si tiene un rival encima y ademas va hacia la porteria
	ld a,(0e54ch)		;b075   ; sin (0xE54C) puesto no hay rival encima
	and a			;b078
	ret z			;b079
	ld a,(0e53ah)		;b07a   ; (0xE53A) es la direccion en la que va de verdad
	and a			;b07d
	ret z			;b07e
	and 007h		;b07f   ; las direcciones 8, 1 y 2 -arriba-derecha, derecha y abajo-derecha- son las que van hacia la porteria
	cp 003h		;b081
	ret			;b083
corre_esquivando_al_rival:		; la subescena 2: el nucleo, con la decision de tirar y la finta
	call descuenta_la_reaccion		;b084   ; mientras le duren cuadros de reaccion no hace nada...
	jr c,$+21		;b087   ; ...mas que soltar el mando
	xor a			;b089
	ld (0e54ch),a		;b08a   ; el rival encima se da por olvidado en cada pasada; 0xB115 lo vuelve a poner
	call que_hacer_con_la_pelota		;b08d   ; 0xB1BD devuelve en C que hacer: 0 seguir, 1 tirar ya, 2 pasar, 3 apuntar
	ld a,c			;b090
	call despacha		;b091   ; y detras van los cuatro punteros

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_b094: 4 entradas; detras sigue `xor a / ld
;   (0e009h),a / ret`
;   0xb094..0xb09c  (8 bytes)
DATA_tabla_de_subescenas_b094:
	defw 0b0ceh,0b0a1h,0b0adh,0b0b3h	; b094  -> corre_con_la_pelota tira_ya pide_el_pase apunta_el_tiro

; ======================================================================
; CODIGO 0xb09c..0xb246  (426 bytes)
; ======================================================================


suelta_el_mando_de_la_maquina:		; (0xE009) a cero: ni direccion ni boton
	xor a			;b09c
	ld (0e009h),a		;b09d
	ret			;b0a0
tira_ya:		; subescena 4, apuntando a la altura del portero de enfrente
	ld hl,0e370h		;b0a1
	ld (hl),004h		;b0a4
	ld a,(0e292h)		;b0a6   ; (0xE292) es la altura por la que va el portero de enfrente ahora mismo
	ld (0e551h),a		;b0a9
	ret			;b0ac
pide_el_pase:		; (0xE53F) = 1, que 0x944B convierte en pase
	ld a,001h		;b0ad
	ld (0e53fh),a		;b0af
	ret			;b0b2
apunta_el_tiro:		; subescena 5, con la espera de apuntado que marca el nivel
	ld hl,0e370h		;b0b3
	ld (hl),005h		;b0b6
	inc l			;b0b8
	ld a,(0e069h)		;b0b9   ; 0x18 cuadros menos cuatro por nivel: 0x14 en el nivel 1 y solo 4 en el 5
	add a,a			;b0bc
	add a,a			;b0bd
	neg		;b0be
	add a,018h		;b0c0
	ld (hl),a			;b0c2
	ld a,(0e292h)		;b0c3   ; y de momento se apunta donde este el portero
	ld (0e551h),a		;b0c6
	ret			;b0c9
vuelve_a_la_subescena_cero:		; se acabo el plazo de correr
	dec l			;b0ca
	ld (hl),000h		;b0cb
	ret			;b0cd
corre_con_la_pelota:		; subescena 0 del nucleo: esquiva al rival marcado por el mando 1
	ld hl,0e371h		;b0ce   ; el plazo que reparte 0xB010
	dec (hl)			;b0d1
	jr z,vuelve_a_la_subescena_cero		;b0d2
	ld a,(0e069h)		;b0d4   ; EN EL NIVEL 1 y solo en el...
	dec a			;b0d7
	jr nz,L_B0E2		;b0d8
	ld a,(0e003h)		;b0da
	and 040h		;b0dd   ; ...el bit 6 del contador de cuadros manda a la mitad de las pasadas al camino tonto: la maquina no esquiva
	jp z,sigue_de_frente_o_rodea		;b0df
L_B0E2:
	ld a,(ix+001h)		;b0e2   ; con cuadros de espera encima, quieto
	and a			;b0e5
	ret nz			;b0e6
	push ix		;b0e7   ; IY = el que lleva la pelota...
	pop iy		;b0e9
	ld a,(0e52ch)		;b0eb   ; ...y IX el jugador destacado del mando 1, o sea el rival al que hay que quitarse de encima
	call L_A201		;b0ee
	ld l,(ix+006h)		;b0f1   ; el ancho del rival...
	ld h,(ix+007h)		;b0f4
	ld a,008h		;b0f7   ; se le miden 8 pixeles de mas al rival, que es el ancho de su cuerpo
	call suma_a_hl		;b0f9
	ld e,(iy+006h)		;b0fc   ; ...contra el del que lleva la pelota
	ld d,(iy+007h)		;b0ff
	and a			;b102
	sbc hl,de		;b103
	jr c,sigue_de_frente_o_rodea		;b105   ; con el rival ya por detras no hay que esquivar nada
	ld a,h			;b107
	and a			;b108
	jr nz,sigue_de_frente_o_rodea		;b109
	ld a,l			;b10b
	cp 030h		;b10c   ; ni tampoco si le saca mas de 0x30 pixeles
	jr nc,sigue_de_frente_o_rodea		;b10e
	ld (0e2d0h),a		;b110   ; (0xE2D0) se queda con la distancia al rival
	ld a,001h		;b113
	ld (0e54ch),a		;b115   ; (0xE54C) = 1: tengo un rival encima, y eso es lo que lee 0xB075 para decidir el tiro
	ld a,(ix+004h)		;b118   ; diferencia de alturas entre el rival y el que lleva la pelota
	sub (iy+004h)		;b11b
	ld hl,0b27eh		;b11e   ; a la misma altura, la tabla de 0xB27E, que ofrece las dos salidas
	jr z,L_B134		;b121
	ld hl,0b290h		;b123   ; con el rival por debajo, la de 0xB290, que sube
	jr nc,L_B12B		;b126
	ld hl,0b287h		;b128   ; y con el rival por encima, la de 0xB287, que baja
L_B12B:
	ex af,af'			;b12b
	ld a,(0e069h)		;b12c   ; LA FINTA EN DIAGONAL SOLO EXISTE DEL NIVEL 3 EN ADELANTE: en el 1 y el 2 la maquina solo se aparta cuando el rival esta a su MISMA altura
	cp 003h		;b12f
	jr c,sigue_de_frente_o_rodea		;b131
	ex af,af'			;b133
L_B134:
	add a,010h		;b134   ; y aun asi solo si estan a menos de 16 pixeles
	cp 021h		;b136
	jr nc,sigue_de_frente_o_rodea		;b138
	ld a,(ix+003h)		;b13a   ; la tabla se indexa por la direccion que ya lleva, 0 a 8
	call suma_a_hl		;b13d
	ld a,(hl)			;b140
	and 00fh		;b141   ; el nibble bajo es la salida
	ld c,a			;b143
	cp (hl)			;b144   ; si los dos nibbles son distintos hay dos salidas posibles...
	jr z,L_B155		;b145
	ld a,(0e003h)		;b147   ; ...y el contador de cuadros echa a suertes cual de las dos
	add a,a			;b14a
	ld a,(hl)			;b14b   ; el byte entero, con sus dos nibbles
	jr c,L_B152		;b14c
	rra			;b14e
	rra			;b14f
	rra			;b150
	rra			;b151
L_B152:
	and 00fh		;b152   ; y se queda el nibble que haya salido en el sorteo
	ld c,a			;b154
L_B155:
	ld a,(iy+004h)		;b155   ; con el que lleva la pelota entre 0x19 y 0x98 de altura, la finta vale
	cp 019h		;b158
	jr c,L_B165		;b15a
	cp 098h		;b15c
	jr nc,L_B165		;b15e
L_B160:
	ld a,c			;b160   ; y aqui es donde la maquina se escribe el mando
	ld (0e009h),a		;b161
	ret			;b164
L_B165:
	ld a,(0e069h)		;b165   ; pegado a un palo, DEL NIVEL 4 EN ADELANTE...
	cp 004h		;b168
	jp c,sigue_de_frente_o_rodea		;b16a
	ld a,(0e2d0h)		;b16d   ; ...y con el rival a mas de 0x18 pixeles, se pasa a la subescena 3, la de abrirse
	sub 018h		;b170
	jp c,sigue_de_frente_o_rodea		;b172
	ld hl,0e370h		;b175
	ld (hl),003h		;b178
	inc hl			;b17a
	ld (hl),020h		;b17b   ; con 0x20 cuadros de plazo
	ret			;b17d
sigue_de_frente_o_rodea:		; recorre los seis rivales buscando uno a su misma altura
	ld hl,0e104h		;b17e   ; 0xE104 es el +4 -la altura- del jugador 0; se van saltando de 32 en 32
	ld b,006h		;b181
	ld de,00020h		;b183
L_B186:
	ld a,(hl)			;b186
	cp (iy+004h)		;b187
	jr z,L_B193		;b18a
	add hl,de			;b18c
	djnz L_B186		;b18d
	ld c,008h		;b18f   ; sin nadie a su altura, 8: recto hacia la porteria
	jr L_B160		;b191
L_B193:
	cp 058h		;b193   ; y con alguien delante se desvia hacia el centro del campo: 9 si el otro esta por debajo de la mitad...
	ld c,009h		;b195
	jr nc,L_B19B		;b197
	ld c,00ah		;b199   ; ...y 0x0A si esta por encima
L_B19B:
	jr L_B160		;b19b
despeja_tras_el_tiro:		; del nivel 4 arriba, con la pelota en su area y un tiro reciente, la revienta al otro campo
	ld a,(0e069h)		;b19d   ; DEL NIVEL 4 EN ADELANTE: por debajo, la maquina no despeja
	cp 004h		;b1a0
	ret c			;b1a2
	ld a,(0e2a6h)		;b1a3   ; el byte alto del ancho de la pelota a cero: esta en los primeros 256 pixeles, su propia area
	and a			;b1a6
	ret nz			;b1a7
	ld hl,0e566h		;b1a8   ; (0xE566) lo enciende 0x953D cuando el bando de enfrente acaba de tirar a puerta
	ld a,(hl)			;b1ab
	and a			;b1ac
	ret z			;b1ad
	ld (hl),000h		;b1ae
	ld a,002h		;b1b0
	ld (0e53fh),a		;b1b2   ; (0xE53F) = 2, que 0x944E convierte en tiro
	ld a,(0e292h)		;b1b5   ; apuntando al fondo contrario
	ld (0e551h),a		;b1b8
	pop de			;b1bb   ; y se saca la direccion de vuelta de la pila: esta rutina hace volver a QUIEN LLAMO a su llamador
	ret			;b1bc
que_hacer_con_la_pelota:		; devuelve en C la decision: 0 seguir, 1 tirar ya, 2 pasar, 3 apuntar
	ld hl,(0e2a5h)		;b1bd
	ld a,(0e52bh)		;b1c0   ; fuera de la ultima franja del campo no se tira nunca
	cp 00ch		;b1c3
	ld c,000h		;b1c5
	ret c			;b1c7
	ld a,(0e2a1h)		;b1c8   ; la altura de la pelota, entre 0x38 y 0x80: la franja que da a la porteria
	sub 038h		;b1cb
	cp 048h		;b1cd
	jr c,L_B1E3		;b1cf
	ld de,00240h		;b1d1   ; fuera de la franja pero pasado el pixel 576, ya no hay angulo: pase
	sbc hl,de		;b1d4
	jr c,L_B1DB		;b1d6
	ld c,002h		;b1d8
	ret			;b1da
L_B1DB:
	call le_pilla_el_rival_de_cara		;b1db   ; y si no, se tira solo cuando el rival aprieta
	ld c,001h		;b1de
	ret c			;b1e0
	dec c			;b1e1
	ret			;b1e2
L_B1E3:
	call le_pilla_el_rival_de_cara		;b1e3
	ld c,001h		;b1e6
	ret c			;b1e8
	dec c			;b1e9
	ld a,h			;b1ea   ; dentro de la franja: entre 0x200 y 0x210 de ancho se dispara...
	cp 002h		;b1eb
	ret nz			;b1ed
	ld a,l			;b1ee
	cp 010h		;b1ef
	inc c			;b1f1
	ret c			;b1f2
	ld c,003h		;b1f3   ; ...y mas alla se pasa a la subescena 3
	ret			;b1f5
se_abre_buscando_hueco:		; subescena 3: retrocede y luego se descuelga arriba o abajo
	ld hl,0e371h		;b1f6
	dec (hl)			;b1f9
	jp z,pide_el_pase		;b1fa   ; agotado el plazo sin conseguirlo, la pasa
	ld a,(hl)			;b1fd
	cp 010h		;b1fe   ; los primeros 0x10 cuadros del plazo, 4 = izquierda: da un paso atras
	ld c,004h		;b200
	jp nc,L_B160		;b202
	ld a,(0e2a1h)		;b205   ; y despues se descuelga hacia el lado largo: 1 arriba si la pelota va baja, 2 abajo si va alta
	cp 058h		;b208
	ld c,001h		;b20a
	jr nc,L_B210		;b20c
	ld c,002h		;b20e
L_B210:
	jp L_B160		;b210
espera_el_hueco_del_portero:		; subescena 4: no dispara hasta que el portero se aparta
	ld a,002h		;b213
	ld (0e371h),a		;b215   ; el plazo se rearma en 2 cuadros cada pasada: mientras dure esto, la subescena 0 no vuelve
	call corre_esquivando_al_rival		;b218
	ld a,(0e069h)		;b21b   ; dos bytes por nivel en la tabla de 0xB246, con la base una entrada por debajo
	add a,a			;b21e
	ld hl,lb244h		;b21f
	call suma_a_hl		;b222
	ld c,(hl)			;b225
	inc l			;b226
	ld b,(hl)			;b227
	ld a,(0e292h)		;b228   ; la altura por la que va el portero
	ld e,a			;b22b
	sub c			;b22c
	cp b			;b22d   ; con el portero dentro de la franja C..C+B no se dispara; esa franja crece con el nivel: un solo pixel en el 1 y 24 pixeles en el 5
	ret c			;b22e
	ld a,e			;b22f
	ld (0e551h),a		;b230   ; fuera de ella se apunta a donde el portero esta AHORA...
	ld a,005h		;b233
	ld hl,0e370h		;b235
	ld (hl),a			;b238   ; ...y se pasa a la subescena 5, que aun tarda unos cuadros: para cuando sale el balon, el portero -que se mueve 4 pixeles por cuadro- ya no esta ahi
	inc l			;b239
	ld a,(0e069h)		;b23a   ; la segunda tabla, tambien con la base una entrada por debajo: 0x20 cuadros de apuntado en el nivel 1 y 0x0C en el 5
	ld de,0b24fh		;b23d
	call suma_a_de		;b240
	ld a,(de)			;b243
L_B244:
	ld (hl),a			;b244
	ret			;b245

; ----------------------------------------------------------------------
; DATOS dos_tablas_por_nivel_b246: cinco parejas leidas con `ld c,(hl) / inc l
;   / ld b,(hl)`, y detras cinco bytes sueltos -20, 18, 14, 10, 0C-. La
;   segunda empieza donde acaba la primera
;   0xb246..0xb255  (15 bytes)
DATA_dos_tablas_por_nivel_b246:
	defb 067h	; b246
	defb 001h	; b247
	defb 064h	; b248
	defb 008h	; b249
	defb 060h	; b24a
	defb 010h	; b24b
	defb 05ch	; b24c
	defb 018h	; b24d
	defb 058h	; b24e
	defb 018h	; b24f
	defb 020h	; b250
	defb 018h	; b251
	defb 014h	; b252
	defb 010h	; b253
	defb 00ch	; b254

; ======================================================================
; CODIGO 0xb255..0xb27e  (41 bytes)
; ======================================================================


suelta_el_disparo:		; subescena 5: quieto apuntando, y al acabar la cuenta tira
	xor a			;b255   ; mientras apunta no toca el mando
	ld (0e009h),a		;b256
	ld hl,0e371h		;b259
	dec (hl)			;b25c
	ret nz			;b25d
	ld a,002h		;b25e
	ld (0e53fh),a		;b260   ; (0xE53F) = 2: tiro
	ld a,(0e069h)		;b263
	cp 004h		;b266   ; DEL NIVEL 4 EN ADELANTE se corrige la punteria; por debajo se dispara a donde estaba el portero
	ret c			;b268
	ld de,04868h		;b269   ; nivel 4: los dos palos a 0x48 y 0x68...
	jr z,L_B271		;b26c
	ld de,04070h		;b26e   ; ...y del 5 en adelante, mas ajustado: 0x40 y 0x70
L_B271:
	ld a,(0e334h)		;b271   ; la altura del portero de la porteria a la que se ataca
	cp 058h		;b274   ; por debajo de la mitad del marco, se tira arriba; por encima, abajo
	ld a,d			;b276
	jr nc,L_B27A		;b277
	ld a,e			;b279
L_B27A:
	ld (0e551h),a		;b27a
	ret			;b27d

; ----------------------------------------------------------------------
; DATOS tablas_de_persecucion: tres tablas de nueve direcciones, elegidas por
;   el signo de la diferencia entre perseguidor y perseguido; cada byte lleva
;   DOS direcciones, una en cada nibble
;   0xb27e..0xb299  (27 bytes)
DATA_tablas_de_persecucion:
	defb 09ah	; b27e
	defb 09ah	; b27f
	defb 009h	; b280
	defb 009h	; b281
	defb 009h	; b282
	defb 012h	; b283
	defb 00ah	; b284
	defb 00ah	; b285
	defb 00ah	; b286
	defb 00ah	; b287
	defb 00ah	; b288
	defb 002h	; b289
	defb 002h	; b28a
	defb 00ah	; b28b
	defb 00ah	; b28c
	defb 008h	; b28d
	defb 008h	; b28e
	defb 008h	; b28f
	defb 009h	; b290
	defb 009h	; b291
	defb 008h	; b292
	defb 008h	; b293
	defb 008h	; b294
	defb 009h	; b295
	defb 009h	; b296
	defb 001h	; b297
	defb 001h	; b298

; ======================================================================
; CODIGO 0xb299..0xb2dc  (67 bytes)
; ======================================================================


la_logica_de_los_dos_porteros:		; pasa uno detras de otro con su mando delante
	ld hl,(0e006h)		;b299   ; (0xE2D0) recoge lo recien pulsado y lo mantenido del mando 1...
	ld (0e2d0h),hl		;b29c
	ld hl,0e330h		;b29f   ; ...que es el del portero de la porteria derecha
	ld c,000h		;b2a2
	call un_portero		;b2a4
	ld a,(0e002h)		;b2a7
	and 020h		;b2aa
	call z,la_maquina_lleva_al_portero		;b2ac   ; con un solo humano, el portero de la izquierda lo mueve la maquina en 0xB434
	ld hl,(0e008h)		;b2af   ; y el mando 2 -de verdad o inventado- para el portero izquierdo
	ld (0e2d0h),hl		;b2b2
	ld hl,0e350h		;b2b5
	ld c,001h		;b2b8   ; C dice de que bando es el portero que toca
un_portero:		; despacha el estado de +0 con la ficha en HL
	ld a,(0e527h)		;b2ba   ; con la camara en el bando de este portero, su estado en reposo...
	cp c			;b2bd
	jr nz,L_B2CC		;b2be
	ld a,(hl)			;b2c0   ; el estado del portero, en +0
	and a			;b2c1
	jr nz,L_B2CC		;b2c2
	ld a,(0e280h)		;b2c4
	cp 004h		;b2c7   ; ...y el partido en el subestado 4, se va al saque de puerta de 0xB401
	jp z,recoloca_al_portero		;b2c9
L_B2CC:
	ld a,(hl)			;b2cc   ; se lee el estado y se avanza a +1: los cinco tramos reciben HL apuntando ahi
	inc l			;b2cd
	add a,a			;b2ce   ; por dos, que la tabla es de palabras
	ld de,0b2dch		;b2cf   ; la tabla de 0xB2DC no la salta un call sino el `push bc / ret` de abajo
	call suma_a_de		;b2d2
	ld a,(de)			;b2d5
	ld c,a			;b2d6
	inc de			;b2d7
	ld a,(de)			;b2d8
	ld b,a			;b2d9
	push bc			;b2da   ; `push bc` mas `ret` es el `jp (bc)` que el Z80 no tiene
	ret			;b2db

; ----------------------------------------------------------------------
; DATOS tabla_del_despachador_disfrazado: cinco entradas; no las salta un `jp`
;   sino el `push bc / ret` de 0xB2DA, que es un `jp (bc)` escrito a mano. La
;   sexta palabra ya cae fuera del cartucho
;   0xb2dc..0xb2e6  (10 bytes)
DATA_tabla_del_despachador_disfrazado:
	defw 0b2e6h,0b387h,0b396h,0b3b2h,0b3f8h	; b2dc

; ======================================================================
; CODIGO 0xb2e6..0xb4c3  (477 bytes)
; ======================================================================


el_portero_en_su_sitio:		; estado 0: se balancea, y atiende al boton para estirarse
	inc l			;b2e6
	inc l			;b2e7
	ld a,(0e541h)		;b2e8   ; (0xE541) contra el +3 de la ficha: si coincide, este portero tiene la pelota
	cp (hl)			;b2eb
	dec hl			;b2ec
	dec hl			;b2ed
	jr z,el_portero_coge_la_pelota		;b2ee
	push hl			;b2f0
	ld de,0000dh		;b2f1
	add hl,de			;b2f4   ; +0x0E, que es donde vive el contador de la animacion
	ld a,(0e003h)		;b2f5   ; la animacion de estar de pie avanza un dibujo cada 32 cuadros
	and 01fh		;b2f8
	jr nz,L_B2FD		;b2fa
	inc (hl)			;b2fc
L_B2FD:
	ld a,(hl)			;b2fd
	cp 003h		;b2fe   ; y da la vuelta a los tres
	jr c,L_B304		;b300
	xor a			;b302
	ld (hl),a			;b303
L_B304:
	dec l			;b304
	add a,000h		;b305   ; este `add a,0` no suma nada; los dos porteros comparten los mismos tres dibujos
	ld (hl),a			;b307   ; y el mismo numero pasa al dibujo de +0x0D
	pop hl			;b308
	ld de,(0e2d0h)		;b309   ; E es lo recien pulsado y D lo que sigue pulsado
	ld a,(0e540h)		;b30d   ; (0xE540) es el cerrojo del tiro: solo con un tiro en el aire vale la pena estirarse...
	and a			;b310
	jr z,L_B318		;b311
	ld a,e			;b313
	and 030h		;b314   ; ...y hace falta que el boton se ACABE de pulsar
	jr nz,empieza_la_estirada		;b316
L_B318:
	ld a,(hl)			;b318   ; con +1 distinto de cero ya hay una estirada en marcha
	and a			;b319
	jr nz,el_portero_se_desplaza		;b31a
	ld a,d			;b31c   ; sin tiro, lo mantenido del mando: los bits de arriba y abajo
	and 003h		;b31d   ; los bits 0 y 1 del mando son arriba y abajo
	ret z			;b31f
	ret pe			;b320   ; pidiendo los dos a la vez -paridad par- no se hace nada
	and 001h		;b321
	ld a,000h		;b323   ; 0 es hacia arriba y 1 hacia abajo
	jr nz,L_B328		;b325
	inc a			;b327
L_B328:
	ld (hl),008h		;b328   ; +1 = 8 cuadros de desplazamiento
	inc l			;b32a
	ld (hl),a			;b32b   ; +2 se queda con el sentido de la estirada
	inc l			;b32c
	inc l			;b32d
	and a			;b32e   ; y la altura a la que esta decide si le dejan
	ld a,(hl)			;b32f   ; la altura a la que esta el portero ahora mismo
	jr z,L_B33C		;b330
	cp 069h		;b332   ; hacia abajo no se pasa de 0x69...
	ret c			;b334
L_B335:
	dec l			;b335   ; fuera de eso, la orden se anula
	dec l			;b336
	xor a			;b337
	ld (hl),a			;b338
	dec l			;b339
	ld (hl),a			;b33a   ; y +1, la cuenta, tambien a cero
	ret			;b33b
L_B33C:
	cp 041h		;b33c   ; ...y hacia arriba no se sube de 0x41: son los dos palos
	ret nc			;b33e
	jr L_B335		;b33f
el_portero_coge_la_pelota:		; estado 3 con la cuenta que le toque tenerla
	ld c,0ffh		;b341
	ld a,(0e002h)		;b343   ; con dos humanos, 0xFF: la suelta cuando le de la gana al que juega
	and 020h		;b346   ; el bit 5 de (0xE002) es el de los dos humanos
	jr nz,L_B352		;b348
	ld a,(0e541h)		;b34a   ; y con uno solo, el portero 1 -el del humano- tambien...
	dec a			;b34d
	jr z,L_B352		;b34e
	ld c,030h		;b350   ; ...pero el de la maquina se la quita de encima en 0x30 cuadros
L_B352:
	ld (hl),c			;b352
	dec l			;b353
	ld (hl),003h		;b354   ; estado 3, el de tenerla en las manos
	ret			;b356
empieza_la_estirada:		; estado 1, con el dibujo 6 o el 7
	dec l			;b357
	inc (hl)			;b358   ; el estado sube a 1
	ld a,(0e2d1h)		;b359   ; lo mantenido del mando dice hacia donde
	and 003h		;b35c   ; lo mantenido en el mando, otra vez arriba y abajo
	jr z,L_B374		;b35e
	jp pe,L_B374		;b360
	and 001h		;b363
	ld a,006h		;b365   ; el dibujo 6 es la estirada de un lado y el 7 la del otro
	jr nz,L_B36B		;b367
	ld a,007h		;b369
L_B36B:
	inc l			;b36b
	ld (hl),00ch		;b36c   ; doce cuadros dura
	ld de,0000ch		;b36e   ; de +1 a +0x0D van doce bytes
	add hl,de			;b371
	ld (hl),a			;b372
	ret			;b373
L_B374:
	ld (hl),000h		;b374   ; sin direccion, la estirada se cae y se vuelve al estado 0
	ret			;b376
el_portero_se_desplaza:		; los ocho cuadros de moverse por la linea de gol
	dec (hl)			;b377
	ret nz			;b378
	inc l			;b379
	bit 0,(hl)		;b37a   ; +2 dice el sentido...
	ld a,008h		;b37c   ; ...ocho pixeles hacia abajo...
	jr nz,L_B382		;b37e
	ld a,0f8h		;b380   ; ...u ocho hacia arriba
L_B382:
	inc l			;b382   ; de +2 se sube a +4, que es la altura
	inc l			;b383
	add a,(hl)			;b384   ; y se aplican de golpe a la altura al terminar la cuenta
	ld (hl),a			;b385
	ret			;b386
se_levanta_de_la_estirada:		; estado 1: al acabar los doce cuadros pasa al 2
	dec (hl)			;b387
	ret nz			;b388
	ld (hl),001h		;b389   ; un cuadro de estado 2 si no ha cogido nada...
	ld a,(0e541h)		;b38b
	and a			;b38e
	jr z,L_B393		;b38f
	ld (hl),018h		;b391   ; ...y 0x18 si algun portero tiene la pelota
L_B393:
	dec l			;b393
	inc (hl)			;b394   ; estado 2
	ret			;b395
comprueba_si_la_atrapo:		; estado 2: mira si la pelota es suya y si no, se levanta
	dec (hl)			;b396
	ret nz			;b397
	ld a,(0e541h)		;b398   ; (0xE541) contra su +3
	inc l			;b39b
	inc l			;b39c
	cp (hl)			;b39d   ; el +3, su numero de portero
	jr nz,L_B3AC		;b39e
	dec l			;b3a0
	dec l			;b3a1
	call el_portero_coge_la_pelota		;b3a2   ; si es suya, al estado 3 con su cuenta
	ld de,0000dh		;b3a5
	add hl,de			;b3a8   ; y +0x0E, el contador de la animacion
	ld (hl),003h		;b3a9   ; y el contador de animacion a 3, que es donde empiezan los dibujos de tenerla
	ret			;b3ab
L_B3AC:
	dec l			;b3ac   ; y si no era suya, al estado 0
	dec l			;b3ad
	dec l			;b3ae
	ld (hl),000h		;b3af
	ret			;b3b1
el_portero_con_la_pelota:		; estado 3: la pelota le sigue, y la suelta por boton o por plazo
	push hl			;b3b2
	inc l			;b3b3   ; de +1 hasta +4, la altura
	inc l			;b3b4
	inc l			;b3b5
	ld a,(hl)			;b3b6   ; +4 es su altura; la pelota se le pega 14 pixeles por delante
	add a,00eh		;b3b7
	ld (0e2a1h),a		;b3b9
	ld a,008h		;b3bc   ; y 8 de levantada del suelo: la lleva en las manos
	ld (0e2aah),a		;b3be
	pop hl			;b3c1
	dec (hl)			;b3c2   ; la cuenta de tenerla
	jr z,L_B3D0		;b3c3
	ld a,(hl)			;b3c5
	cp 0f7h		;b3c6   ; los ocho primeros cuadros el boton no vale: si no, el mismo pulsado que la atrapo la soltaria
	ret nc			;b3c8
	ld a,(0e2d0h)		;b3c9   ; y a partir de ahi, cualquiera de los dos botones
	and 030h		;b3cc
	jr z,L_B3E0		;b3ce
L_B3D0:
	ld (hl),018h		;b3d0   ; al soltarla, 0x18 cuadros de estado 4...
	dec l			;b3d2
	inc (hl)			;b3d3   ; el estado sube a 4
	ld de,0000dh		;b3d4
	add hl,de			;b3d7
	ld (hl),009h		;b3d8   ; ...con el dibujo 9, el de sacar
	ld a,003h		;b3da
	ld (0e53fh),a		;b3dc   ; (0xE53F) = 3, que 0x9F27 recoge para lanzar la pelota
	ret			;b3df
L_B3E0:
	ld de,0000dh		;b3e0   ; mientras la tiene, los dibujos 3, 4 y 5 se turnan cada 32 cuadros
	add hl,de			;b3e3   ; +0x0E, el contador de la animacion
	ld a,(0e003h)		;b3e4
	and 01fh		;b3e7
	jr nz,L_B3EC		;b3e9
	inc (hl)			;b3eb
L_B3EC:
	ld a,(hl)			;b3ec
	cp 003h		;b3ed
	jr c,L_B3F3		;b3ef
	xor a			;b3f1
	ld (hl),a			;b3f2
L_B3F3:
	dec l			;b3f3   ; y +0x0D, el dibujo
	add a,003h		;b3f4   ; el +3 es lo que separa esta terna de la de estar de pie
	ld (hl),a			;b3f6
	ret			;b3f7
el_portero_termina_el_saque:		; estado 4: al acabar, vuelve al 0 y suelta la pelota
	dec (hl)			;b3f8
	ret nz			;b3f9
	dec l			;b3fa   ; el estado, en +0
	xor a			;b3fb
	ld (hl),a			;b3fc
	ld (0e541h),a		;b3fd   ; (0xE541) a cero: ya no la tiene ningun portero
	ret			;b400

; ----------------------------------------------------------------------
; ===== EL PORTERO DE LA MAQUINA =====
; ----------------------------------------------------------------------
recoloca_al_portero:
	ld a,(0e549h)		;b401   ; (0xE549) distinto de cero: ya esta colocado
	and a			;b404
	ret nz			;b405
	ld a,(0e003h)		;b406   ; un paso cada cuatro cuadros
	and 003h		;b409
	ret nz			;b40b
	ld de,0000dh		;b40c   ; el +0x0D de la ficha, o sea su dibujo
	add hl,de			;b40f
	ld (hl),000h		;b410   ; a cero: de pie
	ld de,0fff7h		;b412   ; y HL vuelve al +4, la altura
	add hl,de			;b415
	ld a,(0e533h)		;b416   ; (0xE533) dice hacia donde tiene que ir
	rra			;b419
	jr c,L_B42B		;b41a
	ld a,(hl)			;b41c
	cp 049h		;b41d   ; 0x49 es el palo de arriba
	jr c,L_B425		;b41f
	sub 008h		;b421   ; ocho pixeles por paso hacia arriba
	ld (hl),a			;b423
	ret			;b424
L_B425:
	ld a,001h		;b425   ; llegado al palo, (0xE549) marca que ya esta
	ld (0e549h),a		;b427
	ret			;b42a
L_B42B:
	ld a,(hl)			;b42b
	cp 060h		;b42c   ; 0x60 es el tope por abajo
	jr nc,L_B425		;b42e
	add a,008h		;b430   ; y ocho pixeles hacia abajo
	ld (hl),a			;b432
	ret			;b433
la_maquina_lleva_al_portero:
	call despeja_el_portero		;b434   ; primero se mira si toca despejar
	call hacia_donde_va_el_portero		;b437   ; y luego hacia donde caeria la pelota
	ld a,(0e008h)		;b43a   ; con algo ya pulsado, no se toca
	and a			;b43d
	jr nz,L_B46D		;b43e
	ld a,(0e2a5h)		;b440   ; la pelota a lo ancho
	cp 048h		;b443   ; por delante del pixel 0x48 no es cosa suya
	jr nc,L_B458		;b445
	ld hl,(0e280h)		;b447
	ld a,(0e567h)		;b44a   ; (0xE567) manda sobre todo lo demas
	and a			;b44d
	jr nz,L_B472		;b44e
	ld a,l			;b450
	cp 001h		;b451   ; en el subestado 1...
	jr z,L_B46D		;b453
	or h			;b455   ; ...o con los dos bytes a cero, se deja el mando como esta
	jr z,L_B46D		;b456

; ----------------------------------------------------------------------
; ----- la banda muerta, que es lo que separa los cinco niveles -----
; ----------------------------------------------------------------------
L_B458:
	ld a,(0e069h)		;b458   ; el nivel de juego
	ld hl,lb4c2h		;b45b   ; la tabla, con la base en 0xB4C2: una entrada mas abajo, que el nivel empieza en 1
	call suma_a_hl		;b45e
	ld a,(hl)			;b461   ; la banda muerta de este nivel
	ld e,a			;b462
	add a,a			;b463   ; el doble mas uno: la ventana entera, arriba y abajo
	inc a			;b464
	ld d,a			;b465
	ld a,c			;b466   ; la diferencia de altura que dejo 0xB47F
	add a,e			;b467   ; centrada sumandole la banda
	cp d			;b468   ; y comparada con la ventana: es el truco de mirar un valor con signo sin usar signo
	jr nc,L_B46D		;b469   ; fuera de la ventana, el portero se mueve
	ld b,000h		;b46b   ; y dentro, B a cero: se queda quieto. Cuanto mayor la banda, mas pasivo el portero
L_B46D:
	ld a,b			;b46d
	ld (0e009h),a		;b46e   ; y la direccion se escribe en el mando 2, como si la pulsara alguien
	ret			;b471
L_B472:
	ld a,(0e2a1h)		;b472   ; con (0xE567) puesto, el portero va a la altura de la pelota
	cp 048h		;b475   ; 0x48 parte la porteria en dos
	ld b,002h		;b477   ; abajo...
	jr c,L_B47D		;b479
	ld b,001h		;b47b   ; ...y arriba
L_B47D:
	jr L_B46D		;b47d
hacia_donde_va_el_portero:
	ld a,(0e2a1h)		;b47f   ; la altura de la pelota
	sub 00eh		;b482   ; menos 0x0E, que es lo que el portero levanta las manos
	ld c,a			;b484
	ld a,(0e354h)		;b485   ; (0xE354) es donde esta el portero
	sub c			;b488   ; y la diferencia queda en C, con signo
	ld c,a			;b489
	ld b,002h		;b48a   ; hacia abajo...
	ret c			;b48c
	ld b,001h		;b48d   ; ...o hacia arriba
	ret			;b48f
despeja_el_portero:
	ld a,(0e540h)		;b490   ; (0xE540) es el cerrojo del tiro
	and a			;b493
	jr z,L_B4BE		;b494   ; sin tiro no hay nada que despejar
	ld a,(0e544h)		;b496   ; y con mas de 0x10 cuadros de gracia, tampoco
	cp 010h		;b499
	jr nc,L_B4BE		;b49b
	ld hl,(0e2a5h)		;b49d   ; la pelota a lo ancho
	ld de,00040h		;b4a0   ; a mas de 0x40 pixeles no la alcanza
	xor a			;b4a3
	sbc hl,de		;b4a4
	jr nc,L_B4BE		;b4a6
	ld a,(0e2a1h)		;b4a8
	sub 00eh		;b4ab   ; su altura, con la misma correccion
	ld c,a			;b4ad
	ld a,(0e354h)		;b4ae   ; contra la del portero
	sub c			;b4b1
	add a,006h		;b4b2   ; mas seis...
	cp 00ch		;b4b4   ; ...y comparado con doce: la ventana de doce pixeles en que llega a tocarla
	jr c,L_B4BE		;b4b6
	ld a,010h		;b4b8   ; y ahi la maquina PULSA el boton: 0x10 en el mando
	ld (0e008h),a		;b4ba
	ret			;b4bd
L_B4BE:
	xor a			;b4be
	ld (0e008h),a		;b4bf   ; fuera de la ventana, el mando se limpia
L_B4C2:
	ret			;b4c2

; ----------------------------------------------------------------------
; DATOS alcance_del_portero_por_nivel: cinco bytes -20, 2C, 18, 14, 10-
;   indexados por el nivel, con la base en 0xB4C2. El 0x2C rompe la progresion
;   de los otros cuatro
;   0xb4c3..0xb4c8  (5 bytes)
DATA_alcance_del_portero_por_nivel:
	defb 020h	; b4c3
	defb 02ch	; b4c4
	defb 018h	; b4c5
	defb 014h	; b4c6
	defb 010h	; b4c7

; ======================================================================
; CODIGO 0xb4c8..0xb4f4  (44 bytes)
; ======================================================================


recoloca_segun_el_subestado:
	ld a,(0e280h)		;b4c8
	sub 002h		;b4cb   ; en el subestado 2 se recalcula la formacion normal
	jp z,L_A051		;b4cd
	dec a			;b4d0
	jp nz,L_A051		;b4d1   ; y en cualquiera menos el 3, tambien
	ld a,(0e527h)		;b4d4   ; en el 3, cada bando tiene su propia tabla de colocacion
	ld hl,0b4f4h		;b4d7
	and a			;b4da
	jr z,L_B4E0		;b4db
	ld hl,0b500h		;b4dd
L_B4E0:
	ld de,0e116h		;b4e0   ; el destino de la primera ficha de un bando...
	ld ix,0e410h		;b4e3
	and a			;b4e7
	jr z,L_B4F1		;b4e8
	ld de,0e1d6h		;b4ea   ; ...o del otro
	ld ix,0e416h		;b4ed
L_B4F1:
	jp L_A0E7		;b4f1

; ----------------------------------------------------------------------
; DATOS las_dos_formaciones: seis jugadores por dos bytes, dos veces: la X tal
;   cual y la Y multiplicada por dieciseis. Elige (0xE527), o sea el equipo
;   0xb4f4..0xb50c  (24 bytes)
DATA_las_dos_formaciones:
	defb 028h	; b4f4
	defb 008h	; b4f5
	defb 058h	; b4f6
	defb 00ah	; b4f7
	defb 088h	; b4f8
	defb 008h	; b4f9
	defb 020h	; b4fa
	defb 012h	; b4fb
	defb 058h	; b4fc
	defb 014h	; b4fd
	defb 080h	; b4fe
	defb 012h	; b4ff
	defb 020h	; b500
	defb 016h	; b501
	defb 058h	; b502
	defb 014h	; b503
	defb 080h	; b504
	defb 016h	; b505
	defb 028h	; b506
	defb 020h	; b507
	defb 058h	; b508
	defb 01dh	; b509
	defb 088h	; b50a
	defb 020h	; b50b

; ======================================================================
; CODIGO 0xb50c..0xb578  (108 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== TODOS MIRAN A LA PELOTA =====
; ----------------------------------------------------------------------
L_B50C:
	ld hl,0ffffh		;b50c   ; 0xFFFF como pareja de exentos: ningun numero de ficha vale 0xFF, asi que en el saque se recolocan las doce
	jr L_B519		;b50f
L_B511:
	ld a,(0e532h)		;b511   ; y con el partido en marcha, los exentos son los dos destacados: de esos se encarga el mando
	and a			;b514   ; con el juego parado no se le manda nada a nadie
	ret nz			;b515
	ld hl,(0e52ch)		;b516   ; (0xE52C) y (0xE52D) de una sola vez: el destacado de un bando en L y el del otro en H
L_B519:
	ld ix,0e100h		;b519   ; la primera ficha...
	ld b,00ch		;b51d   ; ...y las doce
L_B51F:
	call L_B52A		;b51f
	ld de,00020h		;b522   ; 32 bytes mide una ficha
	add ix,de		;b525
	djnz L_B51F		;b527
	ret			;b529
L_B52A:
	ld a,(ix+00dh)		;b52a   ; esta es la que decide hacia donde mira UNA
	and a			;b52d   ; con un dibujo distinto de cero la ficha esta ocupada -por el suelo, golpeando- y no atiende
	ret nz			;b52e
	ld a,(ix+015h)		;b52f   ; y si es uno de los dos exentos, tampoco
	cp l			;b532
	ret z			;b533
	cp h			;b534
	ret z			;b535
	exx			;b536   ; el juego alterno guarda IX y el contador de las doce
	ld e,(ix+006h)		;b537   ; su X, que va en dos bytes
	ld d,(ix+007h)		;b53a
	ld hl,(0e2a5h)		;b53d   ; contra la X de la pelota
	and a			;b540
	sbc hl,de		;b541
	ld c,000h		;b543   ; C queda a 0 si la pelota cae a la derecha de la ficha, y a 1 si a la izquierda
	jr nc,L_B548		;b545
	inc c			;b547
L_B548:
	ld a,(0e2a1h)		;b548   ; y ahora la altura, que es un solo byte
	sub (ix+004h)		;b54b
	ld a,002h		;b54e   ; 2 si la pelota esta mas abajo...
	jr nc,L_B554		;b550
	ld a,004h		;b552   ; ...y 4 si mas arriba
L_B554:
	or c			;b554   ; juntando los dos bits salen los indices 2, 3, 4 y 5
	ld hl,0b578h		;b555   ; y esos cuatro sacan de 0xB578 las CUATRO DIAGONALES -2, 4, 8 y 6-: nadie corre en linea recta hacia la pelota, siempre en diagonal
	call suma_a_hl		;b558
	ld c,(hl)			;b55b
	dec (ix+01bh)		;b55c   ; el +0x1B es un contador propio de cada ficha, y estas dos instrucciones son las UNICAS de los 32 KB que lo tocan: arranca a cero con el borrado de la RAM y se separa del de los demas porque solo baja cuando a la ficha le toca turno
	ld a,(ix+01bh)		;b55f
	and 03fh		;b562   ; de cada 64 cuentas, las NUEVE que caen entre 0x37 y 0x3F...
	cp 037h		;b564
	jr c,L_B573		;b566
	ld a,(ix+015h)		;b568   ; ...la ficha se olvida de la pelota y mira a la porteria contraria: rumbo 5 -izquierda- el primer bando y rumbo 1 -derecha- el segundo
	cp 006h		;b56b
	ld c,005h		;b56d
	jr c,L_B573		;b56f
	ld c,001h		;b571
L_B573:
	ld (ix+00ch),c		;b573   ; el rumbo pedido, que la tactica leera despues
	exx			;b576   ; y se devuelven IX y el contador
	ret			;b577

; ----------------------------------------------------------------------
; DATOS los_cuatro_rumbos_hacia_la_pelota: seis bytes; el unico consumidor,
;   0xB555, solo alcanza los indices 2 a 5, o sea las CUATRO DIAGONALES -2, 4,
;   8 y 6-, asi que las dos primeras entradas -el 1 y el 5, derecha e
;   izquierda- no las lee nadie
;   0xb578..0xb57e  (6 bytes)
DATA_los_cuatro_rumbos_hacia_la_pelota:
	defb 001h	; b578
	defb 005h	; b579
	defb 002h	; b57a
	defb 004h	; b57b
	defb 008h	; b57c
	defb 006h	; b57d

; ======================================================================
; CODIGO 0xb57e..0xb657  (217 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL CHOQUE: la entrada que no sale =====
; ----------------------------------------------------------------------
L_B57E:
	ld a,006h		;b57e   ; aqui se entra desde 0xABE0, cuando el que va a robar y el que lleva la pelota no van encarados: en vez del robo limpio, un encontronazo
	ld (0e280h),a		;b580   ; subestado 6, el del choque; IX es EL QUE ENTRA
	ld a,(ix+015h)		;b583   ; y aun asi la pelota se la queda el: se apunta como dueno...
	ld (0e528h),a		;b586
	cp 006h		;b589   ; ...y se le hace destacado de su bando, en (0xE52C) o (0xE52D) segun sea de los seis primeros o de los seis ultimos
	ld hl,0e52ch		;b58b
	ld c,000h		;b58e
	jr c,L_B594		;b590
	inc l			;b592
	inc c			;b593
L_B594:
	ld (hl),a			;b594
	ld (0e542h),a		;b595   ; el ultimo que la toco
	ld a,c			;b598
	ld (0e283h),a		;b599   ; y el bando que la lleva
	ld a,008h		;b59c   ; 8 cuadros hasta el primer resbalon
	ld (0e553h),a		;b59e
	xor a			;b5a1
	ld l,a			;b5a2
	ld h,a			;b5a3
	ld (ix+001h),0ffh		;b5a4   ; el +1 a 0xFF y el +2 y el +3 a cero: se le para el paso y se le borra el rumbo
	ld (ix+002h),a		;b5a8
	ld (ix+003h),a		;b5ab
	ld (ix+00dh),004h		;b5ae   ; dibujo 4: por el suelo. Al de enfrente ya le dejo 0xABB0 sus 16 cuadros de castigo, asi que caen los dos
	ld (0e370h),hl		;b5b2   ; se apaga el sprite de la pelota, que ahora la lleva una ficha
	ld (0e555h),a		;b5b5
	ld (0e551h),a		;b5b8
	ld (0e546h),a		;b5bb
	call L_B60B		;b5be   ; la pelota, a sus pies
	call para_la_pelota_y_al_jugador		;b5c1   ; y todo quieto
	ld a,059h		;b5c4   ; el 0x59 es el golpe del choque
	jp pide_un_sonido		;b5c6
L_B5C9:
	ld a,(0e280h)		;b5c9   ; y esta corre cada cuadro, desde 0x583D
	cp 006h		;b5cc   ; solo en el subestado 6
	ret nz			;b5ce
	ld a,(0e528h)		;b5cf   ; el que choco, otra vez en IX
	call L_A201		;b5d2
	ld a,(0e555h)		;b5d5   ; (0xE555) cuenta los resbalones dados: con uno ya hecho, se acaba por 0xB633
	and a			;b5d8
	jr nz,L_B633		;b5d9
	ld hl,0e553h		;b5db   ; ocho cuadros por resbalon
	dec (hl)			;b5de
	ret nz			;b5df
	ld (hl),008h		;b5e0   ; y al llegar a cero, otros ocho y un resbalon mas apuntado
	inc l			;b5e2
	inc l			;b5e3
	inc (hl)			;b5e4
L_B5E5:
	ld a,(0e552h)		;b5e5   ; el resbalon: 8 pixeles en la diagonal que 0xABD8 dejo en (0xE552)
	ld hl,0b655h		;b5e8   ; el primer byte de la pareja es la altura...
	call suma_a_hl		;b5eb
	ld a,(hl)			;b5ee
	inc hl			;b5ef
	add a,(ix+004h)		;b5f0
	ld (ix+004h),a		;b5f3
	ld e,(ix+006h)		;b5f6   ; ...y el segundo el ancho, que va con signo en 16 bits
	ld d,(ix+007h)		;b5f9
	ld l,(hl)			;b5fc
	ld h,000h		;b5fd
	bit 7,l		;b5ff   ; los negativos -0xF8- se extienden a mano poniendo H a 0xFF
	jr z,L_B604		;b601
	dec h			;b603
L_B604:
	add hl,de			;b604
	ld (ix+006h),l		;b605
	ld (ix+007h),h		;b608
L_B60B:
	ld a,(0e552h)		;b60b   ; y esta pone la pelota a los pies del que la lleva, con la segunda tabla
	ld hl,0b65dh		;b60e
	call suma_a_hl		;b611
	ld a,(ix+004h)		;b614   ; la altura, redondeada a la casilla de 8
	and 0f8h		;b617
	add a,(hl)			;b619
	inc hl			;b61a
	ld (0e2a1h),a		;b61b   ; la pelota queda a la altura de la ficha mas el desvio de la tabla
	ld a,(hl)			;b61e   ; y a lo ancho lo mismo, tambien redondeado y con su signo
	ld h,000h		;b61f
	and 0f8h		;b621
	jp p,L_B627		;b623
	dec h			;b626
L_B627:
	ld l,a			;b627
	ld e,(ix+006h)		;b628
	ld d,(ix+007h)		;b62b
	add hl,de			;b62e
	ld (0e2a5h),hl		;b62f   ; la X de la pelota, en 16 bits
	ret			;b632
L_B633:
	ld hl,0e553h		;b633   ; el segundo resbalon, y ya el ultimo
	dec (hl)			;b636
	ret nz			;b637
	call L_B5E5		;b638   ; se da igual que el primero...
	xor a			;b63b   ; ...y de paso se le quita el paso y el dibujo del suelo: la ficha se levanta
	ld (ix+000h),a		;b63c
	ld (ix+00dh),a		;b63f
	ld a,(ix+015h)		;b642   ; el bando del que se queda la pelota
	cp 006h		;b645
	ld a,000h		;b647
	jr c,L_B64C		;b649
	inc a			;b64b
L_B64C:
	ld (0e527h),a		;b64c   ; pasa a ser el bando con la camara...
	ld a,001h		;b64f   ; ...y el subestado vuelve al 1, que es el de la pelota con dueno
	ld (0e280h),a		;b651
	jp para_la_pelota_y_al_jugador		;b654

; ----------------------------------------------------------------------
; DATOS el_resbalon_y_la_pelota_del_choque: dos tablas de cuatro parejas, las
;   dos con la base dos bytes mas abajo -la primera cae dentro de un `jp`- y
;   el indice tomando solo 2, 4, 6 y 8, que son las cuatro DIAGONALES. La de
;   0xB655 es el resbalon del que choca, +-8 en alto y en ancho; la de 0xB65D,
;   donde se le pone la pelota a los pies
;   0xb657..0xb667  (16 bytes)
DATA_el_resbalon_y_la_pelota_del_choque:
	defb 008h	; b657
	defb 008h	; b658
	defb 008h	; b659
	defb 0f8h	; b65a
	defb 0f8h	; b65b
	defb 0f8h	; b65c
	defb 0f8h	; b65d
	defb 008h	; b65e
	defb 010h	; b65f
	defb 00ch	; b660
	defb 00ah	; b661
	defb 0f8h	; b662
	defb 004h	; b663
	defb 0f8h	; b664
	defb 004h	; b665
	defb 008h	; b666

; ======================================================================
; CODIGO 0xb667..0xb736  (207 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL FUERA DE JUEGO =====
; ----------------------------------------------------------------------
L_B667:
	ld a,(0e002h)		;b667   ; la llama 0x9493, justo cuando se lanza el pase: aqui se decide si esto va a acabar en falta
	and 020h		;b66a   ; con DOS jugadores el fuera de juego se pita siempre...
	jr nz,L_B674		;b66c
	ld a,(0e069h)		;b66e   ; ...y con uno solo, solo del NIVEL 3 en adelante: en el 1 y el 2 la regla no existe
	cp 003h		;b671
	ret c			;b673
L_B674:
	ld a,(0e534h)		;b674   ; (0xE534) es el companero al que va el pase
	call L_A201		;b677
	ld e,(ix+006h)		;b67a   ; su X
	ld d,(ix+007h)		;b67d
	ld bc,00020h		;b680   ; 32 bytes por ficha, para recorrer al bando contrario
	ld a,(0e527h)		;b683   ; el bando que ataca
	and a			;b686
	jr z,L_B6C8		;b687
	ld a,(0e2a8h)		;b689   ; el byte alto de la velocidad a lo ancho de la pelota: el segundo bando ataca a la derecha, asi que el pase tiene que ir hacia alla
	and a			;b68c
	ret m			;b68d
	ld hl,00140h		;b68e   ; y el que la recibe, en la mitad contraria del campo: 0x140 de los 0x280 que mide a lo ancho
	and a			;b691
	sbc hl,de		;b692
	ret nc			;b694
	ld hl,0fff8h		;b695   ; se le restan 8 pixeles de margen...
	add hl,de			;b698
	ex de,hl			;b699
	ld iy,0e100h		;b69a   ; ...y se recorre el bando contrario entero, que para este es el que empieza en 0xE100
	exx			;b69e
	ld b,006h		;b69f   ; los seis
L_B6A1:
	exx			;b6a1
	ld l,(iy+006h)		;b6a2   ; la X de cada rival
	ld h,(iy+007h)		;b6a5
	and a			;b6a8
	sbc hl,de		;b6a9   ; con que UNO solo este por delante del que recibe, no hay falta
	ret nc			;b6ab
	add iy,bc		;b6ac
	exx			;b6ae
	djnz L_B6A1		;b6af
L_B6B1:
	exx			;b6b1   ; solo se llega aqui si los SEIS quedaron detras: fuera de juego apuntado
	ld a,001h		;b6b2
	ld (0e5c0h),a		;b6b4   ; (0xE5C0) avisa al arbitro
	ld (0e5c5h),de		;b6b7   ; y se guarda donde: el ancho...
	ld a,(ix+004h)		;b6bb   ; ...la altura...
	ld (0e5c4h),a		;b6be
	ld a,(0e527h)		;b6c1   ; ...y el bando que lo cometio
	ld (0e5c3h),a		;b6c4
	ret			;b6c7
L_B6C8:
	ld a,(0e2a8h)		;b6c8   ; y lo mismo para el primer bando, que ataca a la izquierda: aqui todo va al reves
	and a			;b6cb
	ret p			;b6cc
	ld hl,00140h		;b6cd   ; hacia la izquierda, o sea la pelota con velocidad negativa y el que recibe por debajo de 0x140
	and a			;b6d0
	sbc hl,de		;b6d1
	ret c			;b6d3
	ld iy,0e1c0h		;b6d4   ; y los rivales son los seis que empiezan en 0xE1C0
	ld hl,00008h		;b6d8
	add hl,de			;b6db
	ex de,hl			;b6dc
	exx			;b6dd
	ld b,006h		;b6de
L_B6E0:
	exx			;b6e0   ; los seis del bando contrario, uno a uno
	ld l,(iy+006h)		;b6e1
	ld h,(iy+007h)		;b6e4
	and a			;b6e7
	sbc hl,de		;b6e8
	ret c			;b6ea
	add iy,bc		;b6eb
	exx			;b6ed
	djnz L_B6E0		;b6ee
	jr L_B6B1		;b6f0
L_B6F2:
	ld a,(0e5c0h)		;b6f2   ; EL ARBITRO, que corre cada cuadro desde 0x5818
	and a			;b6f5   ; sin fuera de juego apuntado no hay nada que pitar
	ret z			;b6f6
	ld hl,(0e2abh)		;b6f7   ; y se espera a que la pelota caiga: (0xE2AB) es su velocidad vertical
	ld a,l			;b6fa
	or h			;b6fb
	ret nz			;b6fc
	ld a,(0e546h)		;b6fd   ; (0xE546) puesto es que la pelota reboto en alguien en vez de dejarse controlar: entonces el pase no llego y la falta se anula
	and a			;b700
	jr z,L_B708		;b701
	xor a			;b703   ; el aviso se borra y aqui no ha pasado nada
	ld (0e5c0h),a		;b704
	ret			;b707
L_B708:
	ld (0e5c0h),a		;b708   ; y si llego, se pita: se borra el aviso y la subescena arranca de cero
	ld (0e5c1h),a		;b70b
	inc a			;b70e
	ld (0e5c7h),a		;b70f   ; (0xE5C7) congela la camara y el volcado del campo mientras dura el rotulo
	ld a,007h		;b712   ; subestado 7, el de la falta
	ld (0e280h),a		;b714
	ld a,060h		;b717   ; 0x60 cuadros, casi dos segundos de rotulo
	ld (0e5c2h),a		;b719
	call borra_las_marcas_de_la_pelota		;b71c   ; la pelota deja de dibujarse
	ld a,025h		;b71f   ; el 0x25 es el pitido del arbitro
	call pide_un_sonido		;b721
	ld de,0b898h		;b724   ; y el rotulo "OFFSIDE", que va a la fila 3 de la pantalla
	jp escribe_un_rotulo		;b727
L_B72A:
	ld a,(0e280h)		;b72a   ; el reparto de las tres subescenas de la falta, tambien cada cuadro
	cp 007h		;b72d   ; solo en el subestado 7
	ret nz			;b72f
	ld a,(0e5c1h)		;b730
	call despacha		;b733

; ----------------------------------------------------------------------
; DATOS las_tres_subescenas_de_la_falta: 3 entradas, repartidas por (0xE5C1)
;   desde 0xB733: agotar el rotulo de OFFSIDE y colocar a los doce, esperar el
;   boton -o la cuenta-, y los veinte pasos del que saca
;   0xb736..0xb73c  (6 bytes)
DATA_las_tres_subescenas_de_la_falta:
	defw 0b73ch,0b791h,0b7b0h	; b736  -> L_B73C L_B791 L_B7B0

; ======================================================================
; CODIGO 0xb73c..0xb898  (348 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL SAQUE DE LA FALTA, en tres subescenas =====
; ----------------------------------------------------------------------
L_B73C:
	ld hl,0e5c2h		;b73c   ; subescena 0: se agota el rotulo y se coloca todo el mundo
	dec (hl)			;b73f
	ret nz			;b740
	call L_B7EE		;b741   ; se elige al que saca
	call L_A201		;b744   ; y se le mete en IX
	ld a,(0e5c3h)		;b747   ; mira a la porteria contraria: rumbo 1 si el que se paso de listo fue el primer bando, y 5 si fue el segundo
	and a			;b74a
	ld c,001h		;b74b
	jr z,L_B751		;b74d
	ld c,005h		;b74f
L_B751:
	ld (ix+00ch),c		;b751
	ld (ix+000h),0ffh		;b754   ; el +1 a 0xFF le para el paso
	ld hl,(0e5c5h)		;b758   ; la pelota, en el punto de la falta
	ld (0e2a5h),hl		;b75b
	ld a,(0e5c4h)		;b75e   ; 0x0E mas abajo, que es donde la pisa el que saca
	add a,00eh		;b761
	ld (0e2a1h),a		;b763
	call L_B820		;b766   ; y las doce fichas, a sus puestos de golpe
	ld c,080h		;b769   ; 0x80 cuadros de espera...
	ld a,(0e5c3h)		;b76b   ; ...y solo 0x40 en un caso: falta del primer bando y un solo jugador, o sea que quien saca es la MAQUINA. Como la maquina no va a pulsar nada, la espera se acorta a la mitad
	and a			;b76e
	jr nz,L_B77A		;b76f
	ld a,(0e002h)		;b771
	and 020h		;b774
	jr nz,L_B77A		;b776
	ld c,040h		;b778
L_B77A:
	ld a,c			;b77a
	ld (0e5c2h),a		;b77b
	ld hl,03820h		;b77e   ; se borra el rotulo: 0x2E0 casillas desde 0x3820, que son las catorce primeras filas
	ld bc,002e0h		;b781
	xor a			;b784
	call rellena_la_vram		;b785
	call planta_la_camara_en_la_pelota		;b788   ; la camara, otra vez sobre la pelota
	xor a			;b78b
	ld (0e5c7h),a		;b78c   ; y se le devuelve el mando al volcado del campo
	jr L_B7AB		;b78f
L_B791:
	ld hl,0e5c2h		;b791   ; subescena 1: esperar
	dec (hl)			;b794   ; agotada la cuenta, se sigue sin mas
	jr z,L_B7A6		;b795
	ld a,(0e5c3h)		;b797   ; y si no, se mira el mando del bando que saca: el 1 en 0xE006 y el 2 en 0xE008
	ld hl,0e006h		;b79a
	and a			;b79d
	jr nz,L_B7A2		;b79e
	ld l,008h		;b7a0
L_B7A2:
	ld a,(hl)			;b7a2
	and 030h		;b7a3   ; los dos botones; y como (0xE006) es el FLANCO y no lo mantenido, hay que pulsar de nuevo
	ret z			;b7a5
L_B7A6:
	ld a,014h		;b7a6   ; 0x14 cuadros para la ultima subescena
	ld (0e5c2h),a		;b7a8
L_B7AB:
	ld hl,0e5c1h		;b7ab   ; y a la siguiente
	inc (hl)			;b7ae
	ret			;b7af
L_B7B0:
	ld a,(0e537h)		;b7b0   ; subescena 2: el que saca da veinte pasos y se reanuda
	call L_A201		;b7b3
	ld hl,0e5c2h		;b7b6   ; agotados los veinte...
	dec (hl)			;b7b9
	jr nz,L_B7C7		;b7ba
	ld (ix+000h),000h		;b7bc   ; ...se le suelta el paso, el subestado vuelve a 0 y el partido sigue
	xor a			;b7c0
	ld (0e280h),a		;b7c1
	jp L_9DE2		;b7c4
L_B7C7:
	ld a,(0e003h)		;b7c7   ; mientras tanto, el dibujo alterna entre 1 y 2 cada cuatro cuadros: son los dos pasos del andar
	and 004h		;b7ca
	ld c,001h		;b7cc
	jr z,L_B7D1		;b7ce
	inc c			;b7d0
L_B7D1:
	ld (ix+00dh),c		;b7d1
	ld l,(ix+006h)		;b7d4   ; y su X...
	ld h,(ix+007h)		;b7d7
	ld a,(0e527h)		;b7da   ; ...avanza un pixel por cuadro hacia la porteria que ataca: a la izquierda el primer bando, a la derecha el segundo
	and a			;b7dd
	ld de,0ffffh		;b7de
	jr z,L_B7E6		;b7e1
	ld de,00001h		;b7e3
L_B7E6:
	add hl,de			;b7e6
	ld (ix+006h),l		;b7e7
	ld (ix+007h),h		;b7ea
	ret			;b7ed
L_B7EE:
	ld a,(0e5c4h)		;b7ee   ; QUIEN SACA la falta, por la altura a la que se pito
	ld c,003h		;b7f1   ; tres franjas a lo alto del campo: hasta 0x40, hasta 0x78 y el resto
	cp 040h		;b7f3
	jr c,L_B7FD		;b7f5
	inc c			;b7f7
	cp 078h		;b7f8
	jr c,L_B7FD		;b7fa
	inc c			;b7fc
L_B7FD:
	ld a,(0e5c3h)		;b7fd   ; el que saca es el bando contrario al que la cometio
	xor 001h		;b800
	ld (0e527h),a		;b802
	ld a,c			;b805   ; los codigos de puesto van del 3 al 5 en un bando y del 6 al 8 en el otro
	jr z,L_B80A		;b806
	add a,003h		;b808
L_B80A:
	ld c,a			;b80a
	ld b,00ch		;b80b   ; la lista de 0xE410 dice que puesto lleva cada una de las doce fichas...
	ld e,000h		;b80d
	ld hl,0e410h		;b80f
L_B812:
	ld a,(hl)			;b812   ; ...y aqui se recorre al reves: se busca el puesto y sale el numero de la ficha
	cp c			;b813
	jr z,L_B81B		;b814
	inc l			;b816
	inc e			;b817
	djnz L_B812		;b818
	ld e,c			;b81a   ; sin encontrarlo, el propio codigo hace de numero
L_B81B:
	ld a,e			;b81b
	ld (0e537h),a		;b81c   ; el que saca
	ret			;b81f
L_B820:
	call en_que_zona_esta_la_pelota		;b820   ; y esta coloca a todo el mundo para el saque, empezando por mirar en que zona ha quedado la pelota
	call coloca_a_los_seis		;b823   ; la formacion del bando que saca
	ld a,(0e537h)		;b826   ; y el destino del que saca, que es la propia pelota...
	call L_A201		;b829
	ld a,(0e5c4h)		;b82c
	ld (ix+016h),a		;b82f
	ld hl,(0e5c5h)		;b832   ; ...corrida 0x18 pixeles hacia atras, para que salga por detras de ella
	ld a,(0e5c3h)		;b835
	ld de,00018h		;b838
	and a			;b83b
	jr nz,L_B841		;b83c
	ld de,0ffe8h		;b83e
L_B841:
	add hl,de			;b841
	ld (ix+017h),l		;b842
	ld (ix+018h),h		;b845
	call coloca_a_los_seis_defensas		;b848   ; y los seis del otro bando, a defender
	ld ix,0e100h		;b84b   ; ahora las doce, una por una
	ld b,00ch		;b84f
	ld de,00020h		;b851
L_B854:
	ld (ix+00dh),000h		;b854   ; sin dibujo especial: todas de pie
	call L_A36C		;b858
	ld a,(ix+016h)		;b85b   ; y se les copia el destino encima de la posicion: nadie camina hasta su sitio, aparecen puestos
	ld (ix+004h),a		;b85e
	ld a,(ix+017h)		;b861
	ld (ix+006h),a		;b864
	ld a,(ix+018h)		;b867
	ld (ix+007h),a		;b86a
	add ix,de		;b86d
	djnz L_B854		;b86f
	ld a,(0e5c3h)		;b871   ; y una ultima cosa: al rival del mismo puesto que el que saca...
	and a			;b874
	ld c,0fah		;b875
	ld de,00020h		;b877
	jr z,L_B881		;b87a
	ld c,006h		;b87c
	ld de,0ffe0h		;b87e
L_B881:
	ld a,(0e537h)		;b881   ; ...se le busca sumandole 6 o restandole 6...
	add a,c			;b884
	push de			;b885
	call L_A201		;b886
	pop de			;b889
	ld l,(ix+006h)		;b88a   ; ...y se le aparta 32 pixeles, para que no se plante encima de la falta
	ld h,(ix+007h)		;b88d
	add hl,de			;b890
	ld (ix+006h),l		;b891
	ld (ix+007h),h		;b894
	ret			;b897

; ----------------------------------------------------------------------
; DATOS rotulo_offside: el guion de "OFFSIDE" en 0x386C, que lanza 0xB724
;   0xb898..0xb8a2  (10 bytes)
DATA_rotulo_offside:
	defb 06ch	; b898
	defb 038h	; b899
	defb 02fh	; b89a
	defb 026h	; b89b
	defb 026h	; b89c
	defb 033h	; b89d
	defb 029h	; b89e
	defb 024h	; b89f
	defb 025h	; b8a0
	defb 0ffh	; b8a1

; ======================================================================
; CODIGO 0xb8a2..0xb9f9  (343 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LA PANTALLA FINAL: marcador, penaltis y ganador =====
; ----------------------------------------------------------------------
L_B8A2:
	ld hl,0e561h		;b8a2   ; (0xE561) distingue el primer cuadro del resto: la pantalla se monta una vez y luego solo se anima
	ld a,(hl)			;b8a5
	and a			;b8a6
	jr z,L_B8B6		;b8a7
	call L_B977		;b8a9   ; ya montada: solo el ganador dando saltos
	ld a,(0e012h)		;b8ac   ; y se espera a que se acabe la musica del final...
	and a			;b8af
	ret nz			;b8b0
	ld hl,0e562h		;b8b1   ; ...para avisar por (0xE562) de que ya se puede volver a la presentacion
	inc (hl)			;b8b4
	ret			;b8b5
L_B8B6:
	inc (hl)			;b8b6   ; primera vez: se marca y se pone (0xE562) a cero
	inc l			;b8b7
	ld (hl),000h		;b8b8
	ld de,0bacdh		;b8ba   ; los sprites del ganador, 458 bytes comprimidos que dan 928 en 0x1800
	call descomprime_con_destino_dentro		;b8bd
	ld hl,0e563h		;b8c0   ; (0xE563) es la cuenta de la animacion y (0xE564) el fotograma
	ld (hl),001h		;b8c3
	inc l			;b8c5
	ld (hl),000h		;b8c6
	ld a,0aeh		;b8c8   ; el 0xAE es la musica del final, y esta entra sin mirar la bandera de sonido
	call pide_un_sonido_siempre		;b8ca
	ld hl,03843h		;b8cd   ; el marco del cuadro, hecho a mano con la casilla 0x3B: 27 casillas de ancho arriba...
	call L_B961		;b8d0
	ld hl,039c3h		;b8d3   ; ...otras 27 abajo, doce filas mas alla...
	call L_B961		;b8d6
	ld hl,03843h		;b8d9   ; ...y las dos columnas de los lados, de trece casillas
	call L_B969		;b8dc
	ld hl,0385dh		;b8df
	call L_B969		;b8e2
	ld de,0ba99h		;b8e5   ; "SCORE RECORD" arriba y "WINNER" abajo
	call escribe_un_rotulo		;b8e8
	ld hl,038c7h		;b8eb   ; el nombre de un equipo, seis letras, a la izquierda del marcador
	ld de,0e062h		;b8ee
	ld bc,00006h		;b8f1
	call copia_a_la_vram		;b8f4
	ld hl,038d4h		;b8f7   ; y el del otro a la derecha
	ld de,0e05bh		;b8fa
	ld bc,00006h		;b8fd
	call copia_a_la_vram		;b900
	ld hl,(0e0f5h)		;b903   ; y ahora la comparacion de los dos marcadores, que son dos bytes cada uno: la cifra baja en 0xE0F5 y 0xE0F6 y el acarreo en 0xE0E0 y 0xE0E1
	ld c,h			;b906   ; el truco: se arman dos parejas cruzadas -una cifra baja de cada equipo con un acarreo de cada equipo- para que un solo `sbc hl,bc` de 16 bits compare LAS DOS a la vez
	ld de,(0e0e0h)		;b907
	ld h,e			;b90b
	ld b,d			;b90c
	and a			;b90d
	sbc hl,bc		;b90e
	jr nz,L_B92E		;b910   ; distintos, o sea que hubo ganador en el tiempo: no hay penaltis que escribir
	ld de,0bab5h		;b912   ; iguales: se escribe "PENALTY SHOOT OUT"...
	call escribe_un_rotulo		;b915
	ld hl,03937h		;b918   ; ...y las dos cuentas de penaltis
	ld de,0e0fah		;b91b
	ld b,001h		;b91e
	call escribe_dos_cifras		;b920
	ld hl,0393ah		;b923
	ld de,0e0f9h		;b926
	ld b,001h		;b929
	call escribe_dos_cifras		;b92b
L_B92E:
	ld hl,038ceh		;b92e   ; los dos goles del partido, uno a cada lado del guion de la casilla 0x20
	ld de,0e0f6h		;b931
	ld b,001h		;b934
	call escribe_dos_cifras		;b936
	ld hl,038d1h		;b939
	ld de,0e0f5h		;b93c
	ld b,001h		;b93f
	call escribe_dos_cifras		;b941
	ld hl,0388ch		;b944   ; el nivel, que solo se escribe en la partida de un jugador
	call L_5FC1		;b947
	ld a,(0e520h)		;b94a   ; el ganador: 1 es uno de los dos equipos...
	dec a			;b94d
	jr z,L_B95C		;b94e
	ld de,0e062h		;b950   ; ...y cualquier otra cosa, el otro
L_B953:
	ld hl,03991h		;b953   ; y su nombre, debajo de "WINNER"
	ld bc,00006h		;b956
	jp copia_a_la_vram		;b959
L_B95C:
	ld de,0e05bh		;b95c
	jr L_B953		;b95f
L_B961:
	ld bc,0001bh		;b961   ; las dos filas del marco: 27 casillas 0x3B seguidas
	ld a,03bh		;b964
	jp rellena_la_vram		;b966
L_B969:
	ld b,00dh		;b969   ; y las dos columnas: trece casillas 0x3B, bajando de 32 en 32
	ld a,03bh		;b96b
L_B96D:
	call 0004dh		;b96d   ; BIOS WRTVRM - Writes data in VRAM
	ld de,00020h		;b970
	add hl,de			;b973
	djnz L_B96D		;b974
	ret			;b976
L_B977:
	ld hl,03b00h		;b977   ; LA ANIMACION DEL GANADOR, cada cuadro: se abre la tabla de atributos de sprite, que empieza en 0x3B00
	call abre_la_vram		;b97a
	ld a,(0e003h)		;b97d   ; esta lectura no la usa nadie: 0xB9AE machaca A en sus tres caminos antes de mirarlo
	ld hl,0e563h		;b980   ; la cuenta de la animacion...
	dec (hl)			;b983
	inc hl			;b984
	jr nz,L_B98C		;b985   ; ...y al llegar a cero, fotograma siguiente y otros quince cuadros
	inc (hl)			;b987
	dec hl			;b988
	ld (hl),00fh		;b989
	inc l			;b98b
L_B98C:
	call L_B9AE		;b98c   ; la plantilla de sprites del fotograma de ahora
L_B98F:
	ld a,(de)			;b98f   ; y se sacan por el puerto los cuatro bytes de cada sprite: altura y ancho sumados a la posicion de la figura, y el patron y el color tal cual
	add a,l			;b990
	exx			;b991
	out (c),a		;b992
	exx			;b994
	inc de			;b995
	ld a,(de)			;b996
	add a,h			;b997
	exx			;b998
	out (c),a		;b999
	exx			;b99b
	inc de			;b99c
	ld a,(de)			;b99d
	exx			;b99e
	out (c),a		;b99f
	exx			;b9a1
	inc de			;b9a2
	ld a,(de)			;b9a3
	inc de			;b9a4
	jr L_B9A7		;b9a5   ; este `jr` a la instruccion siguiente no hace nada: cae donde habria caido igual
L_B9A7:
	exx			;b9a7
	out (c),a		;b9a8
	exx			;b9aa
	djnz L_B98F		;b9ab   ; de seis en seis u ocho en ocho, segun la figura
	ret			;b9ad
L_B9AE:
	ld a,(0e002h)		;b9ae   ; ELEGIR LA PLANTILLA: la figura depende de quien gano y de si son dos jugadores
	and 020h		;b9b1   ; con dos jugadores manda 0xB9E4
	ld a,(0e520h)		;b9b3
	jr nz,L_B9E4		;b9b6
	dec a			;b9b8   ; con uno solo: si gano el jugador...
	jr nz,L_B9D4		;b9b9
	ld a,(hl)			;b9bb   ; ...la fiesta tiene CUATRO fotogramas en vez de dos, y el cuarto cambia de plantilla
	and 003h		;b9bc
	cp 003h		;b9be
	ld de,0b9f9h		;b9c0
	jr nz,L_B9C8		;b9c3
	ld de,0ba19h		;b9c5
L_B9C8:
	bit 0,(hl)		;b9c8   ; y de sitio: dos posiciones que se alternan, para que la figura se balancee
	ld hl,0d054h		;b9ca
	jr z,L_B9D1		;b9cd
	ld l,052h		;b9cf
L_B9D1:
	ld b,008h		;b9d1   ; ocho sprites
	ret			;b9d3
L_B9D4:
	bit 0,(hl)		;b9d4   ; si gano la maquina, dos fotogramas y seis sprites
	ld de,0ba39h		;b9d6
	jr z,L_B9DE		;b9d9
	ld de,0ba51h		;b9db
L_B9DE:
	ld hl,0d054h		;b9de
	ld b,006h		;b9e1
	ret			;b9e3
L_B9E4:
	bit 1,(hl)		;b9e4   ; y con dos jugadores, la figura se planta a la derecha o a la izquierda de la pantalla segun quien ganara
	ld de,0ba69h		;b9e6
	jr z,L_B9EE		;b9e9
	ld de,0ba81h		;b9eb
L_B9EE:
	ld hl,0d054h		;b9ee
	dec a			;b9f1
	jr z,L_B9F6		;b9f2
	ld h,028h		;b9f4
L_B9F6:
	ld b,006h		;b9f6
	ret			;b9f8

; ----------------------------------------------------------------------
; DATOS plantillas_de_atributos_de_sprite: cuatro bytes por sprite -dy, dx,
;   patron y color- en grupos de 8, 8, 6, 6, 6 y 6; L_B9AE elige la base y
;   L_B98F los saca por el puerto despues de fijar 0x3B00
;   0xb9f9..0xba99  (160 bytes)
DATA_plantillas_de_atributos_de_sprite:
	defb 0f7h	; b9f9
	defb 0f9h	; b9fa
	defb 000h	; b9fb
	defb 009h	; b9fc
	defb 0f9h	; b9fd
	defb 0f9h	; b9fe
	defb 004h	; b9ff
	defb 006h	; ba00
	defb 000h	; ba01
	defb 0fah	; ba02
	defb 008h	; ba03
	defb 00ah	; ba04
	defb 003h	; ba05
	defb 000h	; ba06
	defb 014h	; ba07
	defb 004h	; ba08
	defb 00dh	; ba09
	defb 0ffh	; ba0a
	defb 018h	; ba0b
	defb 00dh	; ba0c
	defb 010h	; ba0d
	defb 001h	; ba0e
	defb 00ch	; ba0f
	defb 00ah	; ba10
	defb 017h	; ba11
	defb 001h	; ba12
	defb 010h	; ba13
	defb 004h	; ba14
	defb 000h	; ba15
	defb 000h	; ba16
	defb 000h	; ba17
	defb 000h	; ba18
	defb 0f7h	; ba19
	defb 0f9h	; ba1a
	defb 01ch	; ba1b
	defb 009h	; ba1c
	defb 0f9h	; ba1d
	defb 0f9h	; ba1e
	defb 020h	; ba1f
	defb 006h	; ba20
	defb 002h	; ba21
	defb 0fch	; ba22
	defb 024h	; ba23
	defb 00ah	; ba24
	defb 003h	; ba25
	defb 0fbh	; ba26
	defb 02ch	; ba27
	defb 004h	; ba28
	defb 00dh	; ba29
	defb 0ffh	; ba2a
	defb 034h	; ba2b
	defb 00dh	; ba2c
	defb 00fh	; ba2d
	defb 001h	; ba2e
	defb 038h	; ba2f
	defb 00fh	; ba30
	defb 012h	; ba31
	defb 003h	; ba32
	defb 028h	; ba33
	defb 00ah	; ba34
	defb 018h	; ba35
	defb 004h	; ba36
	defb 030h	; ba37
	defb 004h	; ba38
	defb 0f9h	; ba39
	defb 0f9h	; ba3a
	defb 044h	; ba3b
	defb 006h	; ba3c
	defb 0f5h	; ba3d
	defb 0f9h	; ba3e
	defb 048h	; ba3f
	defb 009h	; ba40
	defb 0f6h	; ba41
	defb 0f6h	; ba42
	defb 04ch	; ba43
	defb 004h	; ba44
	defb 009h	; ba45
	defb 002h	; ba46
	defb 054h	; ba47
	defb 00ch	; ba48
	defb 009h	; ba49
	defb 0f8h	; ba4a
	defb 03ch	; ba4b
	defb 00dh	; ba4c
	defb 003h	; ba4d
	defb 0feh	; ba4e
	defb 058h	; ba4f
	defb 00ah	; ba50
	defb 0f9h	; ba51
	defb 0f9h	; ba52
	defb 044h	; ba53
	defb 006h	; ba54
	defb 0f5h	; ba55
	defb 0f9h	; ba56
	defb 048h	; ba57
	defb 009h	; ba58
	defb 009h	; ba59
	defb 002h	; ba5a
	defb 054h	; ba5b
	defb 00ch	; ba5c
	defb 003h	; ba5d
	defb 0f8h	; ba5e
	defb 040h	; ba5f
	defb 00dh	; ba60
	defb 003h	; ba61
	defb 0fdh	; ba62
	defb 050h	; ba63
	defb 00ah	; ba64
	defb 000h	; ba65
	defb 000h	; ba66
	defb 000h	; ba67
	defb 000h	; ba68
	defb 0f9h	; ba69
	defb 0f9h	; ba6a
	defb 044h	; ba6b
	defb 006h	; ba6c
	defb 0f5h	; ba6d
	defb 0f9h	; ba6e
	defb 048h	; ba6f
	defb 009h	; ba70
	defb 0f6h	; ba71
	defb 0f6h	; ba72
	defb 04ch	; ba73
	defb 004h	; ba74
	defb 009h	; ba75
	defb 001h	; ba76
	defb 060h	; ba77
	defb 00ch	; ba78
	defb 013h	; ba79
	defb 0ffh	; ba7a
	defb 064h	; ba7b
	defb 00dh	; ba7c
	defb 003h	; ba7d
	defb 0fch	; ba7e
	defb 05ch	; ba7f
	defb 00ah	; ba80
	defb 0f9h	; ba81
	defb 0f9h	; ba82
	defb 044h	; ba83
	defb 006h	; ba84
	defb 0f5h	; ba85
	defb 0f9h	; ba86
	defb 048h	; ba87
	defb 009h	; ba88
	defb 0f6h	; ba89
	defb 0f6h	; ba8a
	defb 04ch	; ba8b
	defb 004h	; ba8c
	defb 009h	; ba8d
	defb 0f8h	; ba8e
	defb 06ch	; ba8f
	defb 00ch	; ba90
	defb 013h	; ba91
	defb 0fah	; ba92
	defb 070h	; ba93
	defb 00dh	; ba94
	defb 003h	; ba95
	defb 0fdh	; ba96
	defb 068h	; ba97
	defb 00ah	; ba98

; ----------------------------------------------------------------------
; DATOS guion_de_score_record: el rotulo "SCORE RECORD" y "WINNER", por el
;   interprete de nombres; lo lanza 0xB8E5
;   0xba99..0xbab5  (28 bytes)
DATA_guion_de_score_record:
	defb 04bh	; ba99
	defb 038h	; ba9a
	defb 033h	; ba9b
	defb 023h	; ba9c
	defb 02fh	; ba9d
	defb 032h	; ba9e
	defb 025h	; ba9f
	defb 000h	; baa0
	defb 032h	; baa1
	defb 025h	; baa2
	defb 023h	; baa3
	defb 02fh	; baa4
	defb 032h	; baa5
	defb 024h	; baa6
	defb 0feh	; baa7
	defb 08ah	; baa8
	defb 039h	; baa9
	defb 037h	; baaa
	defb 029h	; baab
	defb 02eh	; baac
	defb 02eh	; baad
	defb 025h	; baae
	defb 032h	; baaf
	defb 0feh	; bab0
	defb 0d0h	; bab1
	defb 038h	; bab2
	defb 020h	; bab3
	defb 0ffh	; bab4

; ----------------------------------------------------------------------
; DATOS guion_de_penalty_shoot_out: el rotulo "PENALTY SHOOT OUT"; lo lanza
;   0xB912
;   0xbab5..0xbacd  (24 bytes)
DATA_guion_de_penalty_shoot_out:
	defb 025h	; bab5
	defb 039h	; bab6
	defb 030h	; bab7
	defb 025h	; bab8
	defb 02eh	; bab9
	defb 021h	; baba
	defb 02ch	; babb
	defb 034h	; babc
	defb 039h	; babd
	defb 000h	; babe
	defb 033h	; babf
	defb 028h	; bac0
	defb 02fh	; bac1
	defb 02fh	; bac2
	defb 034h	; bac3
	defb 000h	; bac4
	defb 02fh	; bac5
	defb 035h	; bac6
	defb 034h	; bac7
	defb 000h	; bac8
	defb 000h	; bac9
	defb 000h	; baca
	defb 020h	; bacb
	defb 0ffh	; bacc

; ----------------------------------------------------------------------
; DATOS patrones_de_sprite_bacd: 458 bytes comprimidos que dan 928 de VRAM en
;   0x1800; lo carga 0xB8BD
;   0xbacd..0xbc97  (458 bytes)
DATA_patrones_de_sprite_bacd:
	defb 000h	; bacd
	defb 018h	; bace
	defb 007h	; bacf
	defb 000h	; bad0
	defb 087h	; bad1
	defb 010h	; bad2
	defb 000h	; bad3
	defb 050h	; bad4
	defb 0a4h	; bad5
	defb 028h	; bad6
	defb 014h	; bad7
	defb 009h	; bad8
	defb 00bh	; bad9
	defb 000h	; bada
	defb 087h	; badb
	defb 00ch	; badc
	defb 006h	; badd
	defb 011h	; bade
	defb 001h	; badf
	defb 002h	; bae0
	defb 000h	; bae1
	defb 001h	; bae2
	defb 006h	; bae3
	defb 000h	; bae4
	defb 088h	; bae5
	defb 038h	; bae6
	defb 02ch	; bae7
	defb 058h	; bae8
	defb 0d5h	; bae9
	defb 069h	; baea
	defb 034h	; baeb
	defb 009h	; baec
	defb 001h	; baed
	defb 009h	; baee
	defb 000h	; baef
	defb 089h	; baf0
	defb 070h	; baf1
	defb 0f8h	; baf2
	defb 0aeh	; baf3
	defb 006h	; baf4
	defb 005h	; baf5
	defb 007h	; baf6
	defb 06eh	; baf7
	defb 087h	; baf8
	defb 002h	; baf9
	defb 003h	; bafa
	defb 000h	; bafb
	defb 003h	; bafc
	defb 001h	; bafd
	defb 085h	; bafe
	defb 019h	; baff
	defb 038h	; bb00
	defb 030h	; bb01
	defb 03ch	; bb02
	defb 01ch	; bb03
	defb 007h	; bb04
	defb 000h	; bb05
	defb 08eh	; bb06
	defb 080h	; bb07
	defb 050h	; bb08
	defb 050h	; bb09
	defb 0f0h	; bb0a
	defb 060h	; bb0b
	defb 0f0h	; bb0c
	defb 000h	; bb0d
	defb 00ch	; bb0e
	defb 00eh	; bb0f
	defb 007h	; bb10
	defb 003h	; bb11
	defb 007h	; bb12
	defb 006h	; bb13
	defb 003h	; bb14
	defb 004h	; bb15
	defb 0d8h	; bb16
	defb 083h	; bb17
	defb 07ch	; bb18
	defb 06ch	; bb19
	defb 06ch	; bb1a
	defb 019h	; bb1b
	defb 000h	; bb1c
	defb 082h	; bb1d
	defb 06ch	; bb1e
	defb 0d8h	; bb1f
	defb 01eh	; bb20
	defb 000h	; bb21
	defb 002h	; bb22
	defb 028h	; bb23
	defb 003h	; bb24
	defb 000h	; bb25
	defb 085h	; bb26
	defb 07eh	; bb27
	defb 0fch	; bb28
	defb 0fch	; bb29
	defb 0feh	; bb2a
	defb 07eh	; bb2b
	defb 016h	; bb2c
	defb 000h	; bb2d
	defb 084h	; bb2e
	defb 03eh	; bb2f
	defb 07fh	; bb30
	defb 0ffh	; bb31
	defb 0c9h	; bb32
	defb 00eh	; bb33
	defb 000h	; bb34
	defb 002h	; bb35
	defb 080h	; bb36
	defb 011h	; bb37
	defb 000h	; bb38
	defb 089h	; bb39
	defb 050h	; bb3a
	defb 034h	; bb3b
	defb 098h	; bb3c
	defb 04ch	; bb3d
	defb 090h	; bb3e
	defb 020h	; bb3f
	defb 010h	; bb40
	defb 000h	; bb41
	defb 001h	; bb42
	defb 00bh	; bb43
	defb 000h	; bb44
	defb 087h	; bb45
	defb 00ch	; bb46
	defb 006h	; bb47
	defb 011h	; bb48
	defb 001h	; bb49
	defb 002h	; bb4a
	defb 000h	; bb4b
	defb 001h	; bb4c
	defb 003h	; bb4d
	defb 000h	; bb4e
	defb 08bh	; bb4f
	defb 020h	; bb50
	defb 0c8h	; bb51
	defb 064h	; bb52
	defb 0b0h	; bb53
	defb 06ch	; bb54
	defb 058h	; bb55
	defb 001h	; bb56
	defb 001h	; bb57
	defb 000h	; bb58
	defb 001h	; bb59
	defb 001h	; bb5a
	defb 009h	; bb5b
	defb 000h	; bb5c
	defb 09ch	; bb5d
	defb 070h	; bb5e
	defb 0f8h	; bb5f
	defb 0aeh	; bb60
	defb 006h	; bb61
	defb 005h	; bb62
	defb 007h	; bb63
	defb 06eh	; bb64
	defb 087h	; bb65
	defb 002h	; bb66
	defb 003h	; bb67
	defb 0c5h	; bb68
	defb 0c5h	; bb69
	defb 067h	; bb6a
	defb 065h	; bb6b
	defb 073h	; bb6c
	defb 038h	; bb6d
	defb 010h	; bb6e
	defb 000h	; bb6f
	defb 000h	; bb70
	defb 060h	; bb71
	defb 070h	; bb72
	defb 038h	; bb73
	defb 018h	; bb74
	defb 00ch	; bb75
	defb 005h	; bb76
	defb 0c0h	; bb77
	defb 040h	; bb78
	defb 040h	; bb79
	defb 003h	; bb7a
	defb 0c0h	; bb7b
	defb 090h	; bb7c
	defb 000h	; bb7d
	defb 030h	; bb7e
	defb 038h	; bb7f
	defb 01ch	; bb80
	defb 00ch	; bb81
	defb 01ch	; bb82
	defb 018h	; bb83
	defb 00ch	; bb84
	defb 000h	; bb85
	defb 0c0h	; bb86
	defb 0e0h	; bb87
	defb 0c0h	; bb88
	defb 0c0h	; bb89
	defb 0e0h	; bb8a
	defb 070h	; bb8b
	defb 030h	; bb8c
	defb 01ah	; bb8d
	defb 000h	; bb8e
	defb 002h	; bb8f
	defb 001h	; bb90
	defb 003h	; bb91
	defb 000h	; bb92
	defb 086h	; bb93
	defb 003h	; bb94
	defb 007h	; bb95
	defb 087h	; bb96
	defb 0c7h	; bb97
	defb 0c3h	; bb98
	defb 040h	; bb99
	defb 005h	; bb9a
	defb 000h	; bb9b
	defb 002h	; bb9c
	defb 040h	; bb9d
	defb 003h	; bb9e
	defb 000h	; bb9f
	defb 086h	; bba0
	defb 0f0h	; bba1
	defb 0e0h	; bba2
	defb 0e0h	; bba3
	defb 0f0h	; bba4
	defb 0e0h	; bba5
	defb 020h	; bba6
	defb 005h	; bba7
	defb 000h	; bba8
	defb 082h	; bba9
	defb 060h	; bbaa
	defb 0e0h	; bbab
	defb 01eh	; bbac
	defb 000h	; bbad
	defb 086h	; bbae
	defb 07ch	; bbaf
	defb 03fh	; bbb0
	defb 003h	; bbb1
	defb 081h	; bbb2
	defb 041h	; bbb3
	defb 030h	; bbb4
	defb 00ch	; bbb5
	defb 000h	; bbb6
	defb 002h	; bbb7
	defb 080h	; bbb8
	defb 00ch	; bbb9
	defb 000h	; bbba
	defb 083h	; bbbb
	defb 0f0h	; bbbc
	defb 078h	; bbbd
	defb 040h	; bbbe
	defb 01dh	; bbbf
	defb 000h	; bbc0
	defb 087h	; bbc1
	defb 0c0h	; bbc2
	defb 0f8h	; bbc3
	defb 074h	; bbc4
	defb 00eh	; bbc5
	defb 01ch	; bbc6
	defb 078h	; bbc7
	defb 030h	; bbc8
	defb 019h	; bbc9
	defb 000h	; bbca
	defb 086h	; bbcb
	defb 008h	; bbcc
	defb 018h	; bbcd
	defb 018h	; bbce
	defb 01ch	; bbcf
	defb 00eh	; bbd0
	defb 007h	; bbd1
	defb 005h	; bbd2
	defb 000h	; bbd3
	defb 083h	; bbd4
	defb 018h	; bbd5
	defb 0fch	; bbd6
	defb 070h	; bbd7
	defb 003h	; bbd8
	defb 000h	; bbd9
	defb 002h	; bbda
	defb 014h	; bbdb
	defb 016h	; bbdc
	defb 000h	; bbdd
	defb 084h	; bbde
	defb 001h	; bbdf
	defb 000h	; bbe0
	defb 000h	; bbe1
	defb 001h	; bbe2
	defb 00ah	; bbe3
	defb 000h	; bbe4
	defb 084h	; bbe5
	defb 020h	; bbe6
	defb 088h	; bbe7
	defb 072h	; bbe8
	defb 0deh	; bbe9
	defb 003h	; bbea
	defb 083h	; bbeb
	defb 082h	; bbec
	defb 0b3h	; bbed
	defb 046h	; bbee
	defb 00eh	; bbef
	defb 000h	; bbf0
	defb 002h	; bbf1
	defb 001h	; bbf2
	defb 00bh	; bbf3
	defb 000h	; bbf4
	defb 084h	; bbf5
	defb 058h	; bbf6
	defb 076h	; bbf7
	defb 08dh	; bbf8
	defb 001h	; bbf9
	defb 01fh	; bbfa
	defb 000h	; bbfb
	defb 002h	; bbfc
	defb 005h	; bbfd
	defb 006h	; bbfe
	defb 007h	; bbff
	defb 087h	; bc00
	defb 073h	; bc01
	defb 03fh	; bc02
	defb 01fh	; bc03
	defb 01fh	; bc04
	defb 02fh	; bc05
	defb 0efh	; bc06
	defb 071h	; bc07
	defb 003h	; bc08
	defb 000h	; bc09
	defb 007h	; bc0a
	defb 0c0h	; bc0b
	defb 004h	; bc0c
	defb 0e0h	; bc0d
	defb 082h	; bc0e
	defb 0c0h	; bc0f
	defb 080h	; bc10
	defb 003h	; bc11
	defb 000h	; bc12
	defb 087h	; bc13
	defb 024h	; bc14
	defb 0a0h	; bc15
	defb 0f0h	; bc16
	defb 0f0h	; bc17
	defb 060h	; bc18
	defb 044h	; bc19
	defb 0c0h	; bc1a
	defb 019h	; bc1b
	defb 000h	; bc1c
	defb 006h	; bc1d
	defb 00fh	; bc1e
	defb 087h	; bc1f
	defb 007h	; bc20
	defb 087h	; bc21
	defb 0e7h	; bc22
	defb 0f7h	; bc23
	defb 07fh	; bc24
	defb 0bfh	; bc25
	defb 05fh	; bc26
	defb 003h	; bc27
	defb 000h	; bc28
	defb 00ch	; bc29
	defb 0c0h	; bc2a
	defb 004h	; bc2b
	defb 000h	; bc2c
	defb 004h	; bc2d
	defb 003h	; bc2e
	defb 084h	; bc2f
	defb 0c3h	; bc30
	defb 0e3h	; bc31
	defb 07fh	; bc32
	defb 03fh	; bc33
	defb 005h	; bc34
	defb 003h	; bc35
	defb 083h	; bc36
	defb 007h	; bc37
	defb 006h	; bc38
	defb 00eh	; bc39
	defb 006h	; bc3a
	defb 0e0h	; bc3b
	defb 084h	; bc3c
	defb 0f8h	; bc3d
	defb 0fch	; bc3e
	defb 0fch	; bc3f
	defb 0f8h	; bc40
	defb 003h	; bc41
	defb 0e0h	; bc42
	defb 08ah	; bc43
	defb 060h	; bc44
	defb 070h	; bc45
	defb 030h	; bc46
	defb 044h	; bc47
	defb 0eeh	; bc48
	defb 0f8h	; bc49
	defb 070h	; bc4a
	defb 072h	; bc4b
	defb 07ch	; bc4c
	defb 030h	; bc4d
	defb 019h	; bc4e
	defb 000h	; bc4f
	defb 002h	; bc50
	defb 061h	; bc51
	defb 002h	; bc52
	defb 060h	; bc53
	defb 081h	; bc54
	defb 0e0h	; bc55
	defb 00bh	; bc56
	defb 000h	; bc57
	defb 085h	; bc58
	defb 080h	; bc59
	defb 0c0h	; bc5a
	defb 0c0h	; bc5b
	defb 0e0h	; bc5c
	defb 060h	; bc5d
	defb 00bh	; bc5e
	defb 000h	; bc5f
	defb 006h	; bc60
	defb 007h	; bc61
	defb 084h	; bc62
	defb 01fh	; bc63
	defb 03fh	; bc64
	defb 03fh	; bc65
	defb 01fh	; bc66
	defb 003h	; bc67
	defb 007h	; bc68
	defb 083h	; bc69
	defb 006h	; bc6a
	defb 00eh	; bc6b
	defb 00ch	; bc6c
	defb 004h	; bc6d
	defb 0c0h	; bc6e
	defb 084h	; bc6f
	defb 0c3h	; bc70
	defb 0c7h	; bc71
	defb 0feh	; bc72
	defb 0fch	; bc73
	defb 005h	; bc74
	defb 0c0h	; bc75
	defb 083h	; bc76
	defb 0e0h	; bc77
	defb 060h	; bc78
	defb 070h	; bc79
	defb 010h	; bc7a
	defb 000h	; bc7b
	defb 087h	; bc7c
	defb 022h	; bc7d
	defb 077h	; bc7e
	defb 01fh	; bc7f
	defb 00eh	; bc80
	defb 04eh	; bc81
	defb 03eh	; bc82
	defb 00ch	; bc83
	defb 009h	; bc84
	defb 000h	; bc85
	defb 085h	; bc86
	defb 001h	; bc87
	defb 003h	; bc88
	defb 003h	; bc89
	defb 007h	; bc8a
	defb 006h	; bc8b
	defb 00bh	; bc8c
	defb 000h	; bc8d
	defb 002h	; bc8e
	defb 086h	; bc8f
	defb 002h	; bc90
	defb 006h	; bc91
	defb 081h	; bc92
	defb 007h	; bc93
	defb 00bh	; bc94
	defb 000h	; bc95
	defb 000h	; bc96

; ----------------------------------------------------------------------
; DATOS tres_tablas_por_el_reloj: tres tablas de bytes que 0x8BDE, 0x8C0C y
;   0x8C27 indexan con el nibble bajo de (0xE007)
;   0xbc97..0xbcc2  (43 bytes)
DATA_tres_tablas_por_el_reloj:
	defb 000h	; bc97
	defb 007h	; bc98
	defb 003h	; bc99
	defb 000h	; bc9a
	defb 005h	; bc9b
	defb 006h	; bc9c
	defb 004h	; bc9d
	defb 000h	; bc9e
	defb 001h	; bc9f
	defb 008h	; bca0
	defb 002h	; bca1
	defb 000h	; bca2
	defb 000h	; bca3
	defb 000h	; bca4
	defb 000h	; bca5
	defb 000h	; bca6
	defb 000h	; bca7
	defb 00fh	; bca8
	defb 00ah	; bca9
	defb 00ah	; bcaa
	defb 00ah	; bcab
	defb 00fh	; bcac
	defb 00ah	; bcad
	defb 00ah	; bcae
	defb 00ah	; bcaf
	defb 000h	; bcb0
	defb 000h	; bcb1
	defb 00eh	; bcb2
	defb 008h	; bcb3
	defb 014h	; bcb4
	defb 006h	; bcb5
	defb 014h	; bcb6
	defb 000h	; bcb7
	defb 014h	; bcb8
	defb 0fah	; bcb9
	defb 00eh	; bcba
	defb 0f8h	; bcbb
	defb 00ch	; bcbc
	defb 0fah	; bcbd
	defb 00ah	; bcbe
	defb 000h	; bcbf
	defb 00ch	; bcc0
	defb 006h	; bcc1

; ----------------------------------------------------------------------
; DATOS vectores_de_direccion: ocho grupos de pares (dx, dy) con signo, uno
;   por direccion y magnitud; el ultimo grupo acaba justo donde empieza la
;   tabla de 0xBD36
;   0xbcc2..0xbd36  (116 bytes)
DATA_vectores_de_direccion:
	defb 000h	; bcc2
	defb 000h	; bcc3
	defb 000h	; bcc4
	defb 000h	; bcc5
	defb 000h	; bcc6
	defb 000h	; bcc7
	defb 000h	; bcc8
	defb 001h	; bcc9
	defb 000h	; bcca
	defb 002h	; bccb
	defb 000h	; bccc
	defb 004h	; bccd
	defb 000h	; bcce
	defb 008h	; bccf
	defb 000h	; bcd0
	defb 00ah	; bcd1
	defb 000h	; bcd2
	defb 00eh	; bcd3
	defb 000h	; bcd4
	defb 00fh	; bcd5
	defb 000h	; bcd6
	defb 010h	; bcd7
	defb 002h	; bcd8
	defb 002h	; bcd9
	defb 004h	; bcda
	defb 004h	; bcdb
	defb 008h	; bcdc
	defb 008h	; bcdd
	defb 00ch	; bcde
	defb 00ch	; bcdf
	defb 00eh	; bce0
	defb 00eh	; bce1
	defb 010h	; bce2
	defb 010h	; bce3
	defb 002h	; bce4
	defb 000h	; bce5
	defb 004h	; bce6
	defb 000h	; bce7
	defb 008h	; bce8
	defb 000h	; bce9
	defb 00ch	; bcea
	defb 000h	; bceb
	defb 00eh	; bcec
	defb 000h	; bced
	defb 010h	; bcee
	defb 000h	; bcef
	defb 002h	; bcf0
	defb 0feh	; bcf1
	defb 004h	; bcf2
	defb 0fch	; bcf3
	defb 008h	; bcf4
	defb 0f8h	; bcf5
	defb 00ch	; bcf6
	defb 0f4h	; bcf7
	defb 00eh	; bcf8
	defb 0f2h	; bcf9
	defb 010h	; bcfa
	defb 0f0h	; bcfb
	defb 000h	; bcfc
	defb 000h	; bcfd
	defb 000h	; bcfe
	defb 000h	; bcff
	defb 000h	; bd00
	defb 000h	; bd01
	defb 000h	; bd02
	defb 0ffh	; bd03
	defb 000h	; bd04
	defb 0feh	; bd05
	defb 000h	; bd06
	defb 0fch	; bd07
	defb 000h	; bd08
	defb 0f8h	; bd09
	defb 000h	; bd0a
	defb 0f6h	; bd0b
	defb 000h	; bd0c
	defb 0f2h	; bd0d
	defb 000h	; bd0e
	defb 0f1h	; bd0f
	defb 000h	; bd10
	defb 0f0h	; bd11
	defb 0feh	; bd12
	defb 0feh	; bd13
	defb 0fch	; bd14
	defb 0fch	; bd15
	defb 0f8h	; bd16
	defb 0f8h	; bd17
	defb 0f4h	; bd18
	defb 0f4h	; bd19
	defb 0f2h	; bd1a
	defb 0f2h	; bd1b
	defb 0f0h	; bd1c
	defb 0f0h	; bd1d
	defb 0feh	; bd1e
	defb 000h	; bd1f
	defb 0fch	; bd20
	defb 000h	; bd21
	defb 0f8h	; bd22
	defb 000h	; bd23
	defb 0f4h	; bd24
	defb 000h	; bd25
	defb 0f2h	; bd26
	defb 000h	; bd27
	defb 0f0h	; bd28
	defb 000h	; bd29
	defb 0feh	; bd2a
	defb 002h	; bd2b
	defb 0fch	; bd2c
	defb 004h	; bd2d
	defb 0f8h	; bd2e
	defb 008h	; bd2f
	defb 0f4h	; bd30
	defb 00ch	; bd31
	defb 0f2h	; bd32
	defb 00eh	; bd33
	defb 0f0h	; bd34
	defb 010h	; bd35

; ----------------------------------------------------------------------
; DATOS umbrales_y_tramos: 0xBD36 son palabras de umbral (0x00D0, 0x0100,
;   0x0180, 0x01B0, 0x0280) que barre 0xBD06; 0xBD40 son entradas de tres
;   bytes con paso 3 que lee 0x8D24, y 0xBD4F y 0xBD5F dos tablas de dieciseis
;   bytes con signo. El barrido pide siete palabras y solo hay cinco limpias,
;   asi que las dos ultimas caen ya sobre la tabla de tres bytes
;   0xbd36..0xbd6f  (57 bytes)
DATA_umbrales_y_tramos:
	defb 0d0h	; bd36
	defb 000h	; bd37
	defb 000h	; bd38
	defb 001h	; bd39
	defb 080h	; bd3a
	defb 001h	; bd3b
	defb 0b0h	; bd3c
	defb 001h	; bd3d
	defb 080h	; bd3e
	defb 002h	; bd3f
	defb 000h	; bd40
	defb 000h	; bd41
	defb 000h	; bd42
	defb 080h	; bd43
	defb 000h	; bd44
	defb 010h	; bd45
	defb 0c0h	; bd46
	defb 000h	; bd47
	defb 018h	; bd48
	defb 000h	; bd49
	defb 001h	; bd4a
	defb 020h	; bd4b
	defb 080h	; bd4c
	defb 001h	; bd4d
	defb 030h	; bd4e
	defb 000h	; bd4f
	defb 020h	; bd50
	defb 018h	; bd51
	defb 010h	; bd52
	defb 000h	; bd53
	defb 0f0h	; bd54
	defb 0e8h	; bd55
	defb 0e0h	; bd56
	defb 000h	; bd57
	defb 018h	; bd58
	defb 010h	; bd59
	defb 008h	; bd5a
	defb 000h	; bd5b
	defb 0f8h	; bd5c
	defb 0f0h	; bd5d
	defb 0e8h	; bd5e
	defb 000h	; bd5f
	defb 010h	; bd60
	defb 00ch	; bd61
	defb 008h	; bd62
	defb 000h	; bd63
	defb 0f8h	; bd64
	defb 0f4h	; bd65
	defb 0f0h	; bd66
	defb 000h	; bd67
	defb 00ch	; bd68
	defb 008h	; bd69
	defb 004h	; bd6a
	defb 000h	; bd6b
	defb 0fch	; bd6c
	defb 0f8h	; bd6d
	defb 0f4h	; bd6e

; ----------------------------------------------------------------------
; DATOS punteros_a_las_fichas_largas: dieciseis palabras a las entradas de 24
;   bytes de 0xBD8F; 16 por 24 son 384, que acaba clavado donde empieza la
;   tabla siguiente. Lo indexa 0x934A por (0xE28C)
;   0xbd6f..0xbd8f  (32 bytes)
DATA_punteros_a_las_fichas_largas:
	defw 0bd8fh,0bda7h,0bdbfh,0bdd7h,0bdefh,0be07h,0be1fh,0be37h	; bd6f
	defw 0be4fh,0be67h,0be7fh,0be97h,0beafh,0bec7h,0bedfh,0bef7h	; bd7f

; ----------------------------------------------------------------------
; DATOS fichas_largas: dieciseis entradas de 24 bytes, destinos de la tabla de
;   arriba
;   0xbd8f..0xbf0f  (384 bytes)
DATA_fichas_largas:
	defb 067h	; bd8f
	defb 067h	; bd90
	defb 08ah	; bd91
	defb 02dh	; bd92
	defb 08fh	; bd93
	defb 01ch	; bd94
	defb 090h	; bd95
	defb 014h	; bd96
	defb 091h	; bd97
	defb 010h	; bd98
	defb 091h	; bd99
	defb 00dh	; bd9a
	defb 091h	; bd9b
	defb 00ah	; bd9c
	defb 091h	; bd9d
	defb 009h	; bd9e
	defb 091h	; bd9f
	defb 008h	; bda0
	defb 091h	; bda1
	defb 007h	; bda2
	defb 091h	; bda3
	defb 006h	; bda4
	defb 091h	; bda5
	defb 006h	; bda6
	defb 02dh	; bda7
	defb 08ah	; bda8
	defb 067h	; bda9
	defb 067h	; bdaa
	defb 07dh	; bdab
	defb 04ah	; bdac
	defb 086h	; bdad
	defb 039h	; bdae
	defb 08ah	; bdaf
	defb 02dh	; bdb0
	defb 08ch	; bdb1
	defb 026h	; bdb2
	defb 08eh	; bdb3
	defb 020h	; bdb4
	defb 08fh	; bdb5
	defb 01ch	; bdb6
	defb 090h	; bdb7
	defb 019h	; bdb8
	defb 090h	; bdb9
	defb 016h	; bdba
	defb 090h	; bdbb
	defb 014h	; bdbc
	defb 090h	; bdbd
	defb 012h	; bdbe
	defb 01ch	; bdbf
	defb 08fh	; bdc0
	defb 04ah	; bdc1
	defb 07dh	; bdc2
	defb 067h	; bdc3
	defb 067h	; bdc4
	defb 076h	; bdc5
	defb 054h	; bdc6
	defb 07fh	; bdc7
	defb 046h	; bdc8
	defb 085h	; bdc9
	defb 03ch	; bdca
	defb 088h	; bdcb
	defb 034h	; bdcc
	defb 08ah	; bdcd
	defb 02dh	; bdce
	defb 08ch	; bdcf
	defb 029h	; bdd0
	defb 08dh	; bdd1
	defb 025h	; bdd2
	defb 08eh	; bdd3
	defb 021h	; bdd4
	defb 08eh	; bdd5
	defb 01eh	; bdd6
	defb 014h	; bdd7
	defb 090h	; bdd8
	defb 039h	; bdd9
	defb 086h	; bdda
	defb 054h	; bddb
	defb 076h	; bddc
	defb 067h	; bddd
	defb 067h	; bdde
	defb 073h	; bddf
	defb 059h	; bde0
	defb 07ah	; bde1
	defb 04eh	; bde2
	defb 080h	; bde3
	defb 045h	; bde4
	defb 084h	; bde5
	defb 03dh	; bde6
	defb 086h	; bde7
	defb 037h	; bde8
	defb 089h	; bde9
	defb 032h	; bdea
	defb 08ah	; bdeb
	defb 02dh	; bdec
	defb 08bh	; bded
	defb 02ah	; bdee
	defb 010h	; bdef
	defb 091h	; bdf0
	defb 02dh	; bdf1
	defb 08ah	; bdf2
	defb 046h	; bdf3
	defb 07fh	; bdf4
	defb 059h	; bdf5
	defb 073h	; bdf6
	defb 067h	; bdf7
	defb 067h	; bdf8
	defb 071h	; bdf9
	defb 05ch	; bdfa
	defb 078h	; bdfb
	defb 052h	; bdfc
	defb 07dh	; bdfd
	defb 04ah	; bdfe
	defb 081h	; bdff
	defb 044h	; be00
	defb 084h	; be01
	defb 03eh	; be02
	defb 086h	; be03
	defb 039h	; be04
	defb 088h	; be05
	defb 035h	; be06
	defb 00dh	; be07
	defb 091h	; be08
	defb 026h	; be09
	defb 08ch	; be0a
	defb 03ch	; be0b
	defb 085h	; be0c
	defb 04eh	; be0d
	defb 07ah	; be0e
	defb 05ch	; be0f
	defb 071h	; be10
	defb 067h	; be11
	defb 067h	; be12
	defb 06fh	; be13
	defb 05eh	; be14
	defb 075h	; be15
	defb 056h	; be16
	defb 07ah	; be17
	defb 04fh	; be18
	defb 07eh	; be19
	defb 049h	; be1a
	defb 081h	; be1b
	defb 043h	; be1c
	defb 083h	; be1d
	defb 03eh	; be1e
	defb 00ah	; be1f
	defb 091h	; be20
	defb 020h	; be21
	defb 08eh	; be22
	defb 034h	; be23
	defb 088h	; be24
	defb 045h	; be25
	defb 080h	; be26
	defb 052h	; be27
	defb 078h	; be28
	defb 05eh	; be29
	defb 06fh	; be2a
	defb 067h	; be2b
	defb 067h	; be2c
	defb 06eh	; be2d
	defb 05fh	; be2e
	defb 074h	; be2f
	defb 058h	; be30
	defb 078h	; be31
	defb 052h	; be32
	defb 07ch	; be33
	defb 04ch	; be34
	defb 07eh	; be35
	defb 047h	; be36
	defb 009h	; be37
	defb 091h	; be38
	defb 01ch	; be39
	defb 08fh	; be3a
	defb 02dh	; be3b
	defb 08ah	; be3c
	defb 03dh	; be3d
	defb 084h	; be3e
	defb 04ah	; be3f
	defb 07dh	; be40
	defb 056h	; be41
	defb 075h	; be42
	defb 05fh	; be43
	defb 06eh	; be44
	defb 067h	; be45
	defb 067h	; be46
	defb 06dh	; be47
	defb 060h	; be48
	defb 072h	; be49
	defb 05ah	; be4a
	defb 076h	; be4b
	defb 054h	; be4c
	defb 07ah	; be4d
	defb 04fh	; be4e
	defb 008h	; be4f
	defb 091h	; be50
	defb 019h	; be51
	defb 090h	; be52
	defb 029h	; be53
	defb 08ch	; be54
	defb 037h	; be55
	defb 086h	; be56
	defb 044h	; be57
	defb 081h	; be58
	defb 04fh	; be59
	defb 07ah	; be5a
	defb 058h	; be5b
	defb 074h	; be5c
	defb 060h	; be5d
	defb 06dh	; be5e
	defb 067h	; be5f
	defb 067h	; be60
	defb 06ch	; be61
	defb 061h	; be62
	defb 071h	; be63
	defb 05ch	; be64
	defb 075h	; be65
	defb 056h	; be66
	defb 007h	; be67
	defb 091h	; be68
	defb 016h	; be69
	defb 090h	; be6a
	defb 025h	; be6b
	defb 08dh	; be6c
	defb 032h	; be6d
	defb 089h	; be6e
	defb 03eh	; be6f
	defb 084h	; be70
	defb 049h	; be71
	defb 07eh	; be72
	defb 052h	; be73
	defb 078h	; be74
	defb 05ah	; be75
	defb 072h	; be76
	defb 061h	; be77
	defb 06ch	; be78
	defb 067h	; be79
	defb 067h	; be7a
	defb 06ch	; be7b
	defb 061h	; be7c
	defb 070h	; be7d
	defb 05dh	; be7e
	defb 006h	; be7f
	defb 091h	; be80
	defb 014h	; be81
	defb 090h	; be82
	defb 021h	; be83
	defb 08eh	; be84
	defb 02dh	; be85
	defb 08ah	; be86
	defb 039h	; be87
	defb 086h	; be88
	defb 043h	; be89
	defb 081h	; be8a
	defb 04ch	; be8b
	defb 07ch	; be8c
	defb 054h	; be8d
	defb 076h	; be8e
	defb 05ch	; be8f
	defb 071h	; be90
	defb 061h	; be91
	defb 06ch	; be92
	defb 067h	; be93
	defb 067h	; be94
	defb 06ch	; be95
	defb 062h	; be96
	defb 006h	; be97
	defb 091h	; be98
	defb 012h	; be99
	defb 090h	; be9a
	defb 01eh	; be9b
	defb 08eh	; be9c
	defb 02ah	; be9d
	defb 08bh	; be9e
	defb 035h	; be9f
	defb 088h	; bea0
	defb 03eh	; bea1
	defb 083h	; bea2
	defb 047h	; bea3
	defb 07eh	; bea4
	defb 04fh	; bea5
	defb 07ah	; bea6
	defb 056h	; bea7
	defb 075h	; bea8
	defb 05dh	; bea9
	defb 070h	; beaa
	defb 062h	; beab
	defb 06ch	; beac
	defb 067h	; bead
	defb 067h	; beae
	defb 005h	; beaf
	defb 091h	; beb0
	defb 011h	; beb1
	defb 091h	; beb2
	defb 01ch	; beb3
	defb 08fh	; beb4
	defb 027h	; beb5
	defb 08ch	; beb6
	defb 031h	; beb7
	defb 089h	; beb8
	defb 03ah	; beb9
	defb 085h	; beba
	defb 043h	; bebb
	defb 081h	; bebc
	defb 04ah	; bebd
	defb 07dh	; bebe
	defb 051h	; bebf
	defb 078h	; bec0
	defb 058h	; bec1
	defb 074h	; bec2
	defb 05dh	; bec3
	defb 070h	; bec4
	defb 062h	; bec5
	defb 06bh	; bec6
	defb 005h	; bec7
	defb 091h	; bec8
	defb 010h	; bec9
	defb 091h	; beca
	defb 01ah	; becb
	defb 08fh	; becc
	defb 024h	; becd
	defb 08dh	; bece
	defb 02dh	; becf
	defb 08ah	; bed0
	defb 036h	; bed1
	defb 087h	; bed2
	defb 03fh	; bed3
	defb 083h	; bed4
	defb 046h	; bed5
	defb 07fh	; bed6
	defb 04dh	; bed7
	defb 07bh	; bed8
	defb 054h	; bed9
	defb 077h	; beda
	defb 059h	; bedb
	defb 073h	; bedc
	defb 05eh	; bedd
	defb 06eh	; bede
	defb 004h	; bedf
	defb 091h	; bee0
	defb 00eh	; bee1
	defb 091h	; bee2
	defb 018h	; bee3
	defb 090h	; bee4
	defb 022h	; bee5
	defb 08dh	; bee6
	defb 02ah	; bee7
	defb 08bh	; bee8
	defb 033h	; bee9
	defb 088h	; beea
	defb 03bh	; beeb
	defb 085h	; beec
	defb 042h	; beed
	defb 081h	; beee
	defb 049h	; beef
	defb 07dh	; bef0
	defb 050h	; bef1
	defb 07ah	; bef2
	defb 055h	; bef3
	defb 076h	; bef4
	defb 05ah	; bef5
	defb 072h	; bef6
	defb 004h	; bef7
	defb 091h	; bef8
	defb 00dh	; bef9
	defb 091h	; befa
	defb 016h	; befb
	defb 090h	; befc
	defb 020h	; befd
	defb 08eh	; befe
	defb 028h	; beff
	defb 08ch	; bf00
	defb 030h	; bf01
	defb 089h	; bf02
	defb 038h	; bf03
	defb 086h	; bf04
	defb 03fh	; bf05
	defb 083h	; bf06
	defb 046h	; bf07
	defb 080h	; bf08
	defb 04ch	; bf09
	defb 07ch	; bf0a
	defb 051h	; bf0b
	defb 078h	; bf0c
	defb 056h	; bf0d
	defb 075h	; bf0e

; ----------------------------------------------------------------------
; DATOS punteros_a_las_fichas_cortas: dieciseis palabras a las entradas de 12
;   bytes de 0xBF2F; 16 por 12 son 192, que acaba clavado en 0xBFEF. Lo indexa
;   0x9312, tambien por (0xE28C)
;   0xbf0f..0xbf2f  (32 bytes)
DATA_punteros_a_las_fichas_cortas:
	defw 0bf2fh,0bf3bh,0bf47h,0bf53h,0bf5fh,0bf6bh,0bf77h,0bf83h	; bf0f
	defw 0bf8fh,0bf9bh,0bfa7h,0bfb3h,0bfbfh,0bfcbh,0bfd7h,0bfe3h	; bf1f

; ----------------------------------------------------------------------
; DATOS fichas_cortas: dieciseis entradas de 12 bytes, destinos de la tabla de
;   arriba
;   0xbf2f..0xbfef  (192 bytes)
DATA_fichas_cortas:
	defb 005h	; bf2f
	defb 00ch	; bf30
	defb 014h	; bf31
	defb 01ch	; bf32
	defb 024h	; bf33
	defb 02ch	; bf34
	defb 034h	; bf35
	defb 03ch	; bf36
	defb 044h	; bf37
	defb 04ch	; bf38
	defb 054h	; bf39
	defb 05ch	; bf3a
	defb 00ch	; bf3b
	defb 010h	; bf3c
	defb 017h	; bf3d
	defb 01eh	; bf3e
	defb 025h	; bf3f
	defb 02dh	; bf40
	defb 035h	; bf41
	defb 03dh	; bf42
	defb 045h	; bf43
	defb 04ah	; bf44
	defb 054h	; bf45
	defb 05ch	; bf46
	defb 014h	; bf47
	defb 017h	; bf48
	defb 01ch	; bf49
	defb 022h	; bf4a
	defb 029h	; bf4b
	defb 030h	; bf4c
	defb 037h	; bf4d
	defb 03fh	; bf4e
	defb 046h	; bf4f
	defb 04eh	; bf50
	defb 056h	; bf51
	defb 05eh	; bf52
	defb 01ch	; bf53
	defb 01eh	; bf54
	defb 022h	; bf55
	defb 027h	; bf56
	defb 02dh	; bf57
	defb 034h	; bf58
	defb 03bh	; bf59
	defb 042h	; bf5a
	defb 049h	; bf5b
	defb 050h	; bf5c
	defb 058h	; bf5d
	defb 060h	; bf5e
	defb 024h	; bf5f
	defb 025h	; bf60
	defb 029h	; bf61
	defb 02dh	; bf62
	defb 032h	; bf63
	defb 038h	; bf64
	defb 03fh	; bf65
	defb 045h	; bf66
	defb 04ch	; bf67
	defb 054h	; bf68
	defb 05bh	; bf69
	defb 062h	; bf6a
	defb 02ch	; bf6b
	defb 02dh	; bf6c
	defb 030h	; bf6d
	defb 034h	; bf6e
	defb 038h	; bf6f
	defb 03eh	; bf70
	defb 044h	; bf71
	defb 04ah	; bf72
	defb 050h	; bf73
	defb 057h	; bf74
	defb 05eh	; bf75
	defb 065h	; bf76
	defb 034h	; bf77
	defb 035h	; bf78
	defb 037h	; bf79
	defb 03bh	; bf7a
	defb 03fh	; bf7b
	defb 044h	; bf7c
	defb 049h	; bf7d
	defb 04fh	; bf7e
	defb 055h	; bf7f
	defb 05ch	; bf80
	defb 062h	; bf81
	defb 069h	; bf82
	defb 03ch	; bf83
	defb 03dh	; bf84
	defb 03fh	; bf85
	defb 042h	; bf86
	defb 045h	; bf87
	defb 04ah	; bf88
	defb 04fh	; bf89
	defb 054h	; bf8a
	defb 05ah	; bf8b
	defb 060h	; bf8c
	defb 067h	; bf8d
	defb 06dh	; bf8e
	defb 044h	; bf8f
	defb 045h	; bf90
	defb 046h	; bf91
	defb 049h	; bf92
	defb 04ch	; bf93
	defb 050h	; bf94
	defb 055h	; bf95
	defb 05ah	; bf96
	defb 060h	; bf97
	defb 065h	; bf98
	defb 06ch	; bf99
	defb 072h	; bf9a
	defb 04ch	; bf9b
	defb 04ch	; bf9c
	defb 04eh	; bf9d
	defb 050h	; bf9e
	defb 054h	; bf9f
	defb 057h	; bfa0
	defb 05ch	; bfa1
	defb 060h	; bfa2
	defb 065h	; bfa3
	defb 06bh	; bfa4
	defb 071h	; bfa5
	defb 077h	; bfa6
	defb 054h	; bfa7
	defb 054h	; bfa8
	defb 056h	; bfa9
	defb 058h	; bfaa
	defb 05bh	; bfab
	defb 05eh	; bfac
	defb 062h	; bfad
	defb 067h	; bfae
	defb 06ch	; bfaf
	defb 071h	; bfb0
	defb 076h	; bfb1
	defb 07ch	; bfb2
	defb 05ch	; bfb3
	defb 05ch	; bfb4
	defb 05eh	; bfb5
	defb 060h	; bfb6
	defb 062h	; bfb7
	defb 065h	; bfb8
	defb 069h	; bfb9
	defb 06dh	; bfba
	defb 072h	; bfbb
	defb 077h	; bfbc
	defb 07ch	; bfbd
	defb 082h	; bfbe
	defb 064h	; bfbf
	defb 064h	; bfc0
	defb 065h	; bfc1
	defb 067h	; bfc2
	defb 06ah	; bfc3
	defb 06dh	; bfc4
	defb 070h	; bfc5
	defb 074h	; bfc6
	defb 078h	; bfc7
	defb 07dh	; bfc8
	defb 082h	; bfc9
	defb 087h	; bfca
	defb 06ch	; bfcb
	defb 06ch	; bfcc
	defb 06dh	; bfcd
	defb 06fh	; bfce
	defb 071h	; bfcf
	defb 074h	; bfd0
	defb 077h	; bfd1
	defb 07bh	; bfd2
	defb 07fh	; bfd3
	defb 084h	; bfd4
	defb 088h	; bfd5
	defb 08dh	; bfd6
	defb 074h	; bfd7
	defb 074h	; bfd8
	defb 075h	; bfd9
	defb 077h	; bfda
	defb 079h	; bfdb
	defb 07ch	; bfdc
	defb 07fh	; bfdd
	defb 082h	; bfde
	defb 086h	; bfdf
	defb 08ah	; bfe0
	defb 08fh	; bfe1
	defb 094h	; bfe2
	defb 07ch	; bfe3
	defb 07ch	; bfe4
	defb 07dh	; bfe5
	defb 07fh	; bfe6
	defb 081h	; bfe7
	defb 083h	; bfe8
	defb 086h	; bfe9
	defb 089h	; bfea
	defb 08dh	; bfeb
	defb 091h	; bfec
	defb 095h	; bfed
	defb 09ah	; bfee

; ----------------------------------------------------------------------
; DATOS dos_palabras_a_la_ram: los cuatro bytes que 0x933F copia a (0xE2AB)
;   con `ld bc,00004h / ldir`: las palabras 0x0030 y 0xFFFF. La rama de 0x9337
;   pone 0xFFFD en (0xE2AD) en vez de esta, o sea que son un par de limites
;   0xbfef..0xbff3  (4 bytes)
DATA_dos_palabras_a_la_ram:
	defw 00030h,0ffffh	; bfef

; ----------------------------------------------------------------------
; DATOS marca_de_konami: el titulo en katakana al reves (10 bytes), su
;   longitud 0x0A, el 0x32 de RC-732 y el 0xAA de cierre
;   0xbff3..0xc000  (13 bytes)
DATA_marca_de_konami:
	defb 0bah	; bff3
	defb 085h	; bff4
	defb 0b5h	; bff5
	defb 08ah	; bff6
	defb 000h	; bff7
	defb 098h	; bff8
	defb 000h	; bff9
	defb 09fh	; bffa
	defb 094h	; bffb
	defb 089h	; bffc
	defb 00ah	; bffd
	defb 032h	; bffe
	defb 0aah	; bfff
