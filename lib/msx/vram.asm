
; =============================================================================
;	VRAM buffers routines (NAMTBL and SPRATR, BIOS-based)
; =============================================================================

; -----------------------------------------------------------------------------
; Vaciado del buffer de pantalla con el carácter espacio
CLS_NAMTBL:
	ld      hl, namtbl_buffer
	ld      de, namtbl_buffer + 1
	ld      bc, NAMTBL_SIZE - 1
	ld      [hl], $20 ; " " ASCII
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vaciado del buffer de SPRATR
CLS_SPRATR:
	ld      hl, spratr_buffer
	ld      de, spratr_buffer + 1
	ld      bc, SPRATR_SIZE - 1
	ld      [hl], SPAT_END
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca el buffer de NAMTBL utilizando la BIOS
LDIRVM_NAMTBL:
	ld	hl, namtbl_buffer
	ld	de, NAMTBL
	ld	bc, NAMTBL_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vuleca el buffer de SPRATR utilizando la BIOS
LDIRVM_SPRATR:
	ld	hl, spratr_buffer
	ld	de, SPRATR
	ld	bc, SPRATR_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vacía NAMTBL, deshabilita sprites y desactiva la pantalla
DISSCR_NO_FADE:
	halt	; (sincronización antes de desactivar la pantalla)
	call	DISSCR
; Vacía NAMTBL
	call	CLS
; Deshabilita sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	jp	WRTVRM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Fundido de salida (cortinilla horizontal)
; Vacía NAMTBL, deshabilita sprites y desactiva la pantalla
DISSCR_FADE_OUT:
; Deshabilita sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Fundido
	ld	hl, NAMTBL
	ld	b, SCR_WIDTH
@@COL:
	push	bc ; preserva contador de columnas
	push	hl ; preserva puntero
	ld	de, SCR_WIDTH
	ld	b, SCR_HEIGHT
	ld	a, $20 ; " " ASCII
@@H_CHAR:
	call	WRTVRM
	add	hl, de
	djnz	@@H_CHAR
	halt
	pop	hl ; restaura puntero
	inc	hl
	pop	bc ; restaura contador de columnas
	djnz	@@COL

; Desactiva la pantalla
	jp	DISSCR
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca los buffer de NAMTBL y SPRATR y activa la pantalla
ENASCR_NO_FADE:
	halt	; (sincronización antes del volcado por si la pantalla estaba activada)
	call	LDIRVM_NAMTBL
	call	LDIRVM_SPRATR
	halt	; (sincronización antes de activar la pantalla)
	jp	ENASCR
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Fundido de entrada (cortinilla horizontal)
; Vuelca los buffer de NAMTBL y SPRATR y activa la pantalla
ENASCR_FADE_IN:
; Inicialmente vacía, tanto NAMTBL como sprites
	ld	hl, NAMTBL
	ld	bc, NAMTBL_SIZE
	ld	a, $20 ; " " ASCII
	call	FILVRM
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Activa la pantalla
	halt	; (sincronización antes de activar la pantalla)
	call	ENASCR
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Fundido de entrada/salida (cortinilla horizontal),
; de la imagen actual al contenido de NAMTBL
LDIRVM_NAMTBL_FADE_INOUT:
; Deshabilita sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Fundido
	ld	hl, NAMTBL
	ld	de, namtbl_buffer
	ld	c, SCR_WIDTH
@@COL:
	push	hl ; preserva puntero hl
	push	de ; preserva puntero de
	ld	b, SCR_HEIGHT
@@CHAR:
	push	bc ; preserva contadores
; escribe un caracter
	ld	a, [de]
	call	WRTVRM
; baja una posición
	ld	bc, SCR_WIDTH
	add	hl, bc
	ex	de, hl
	add	hl, bc
	ex	de, hl
	pop	bc ; restaura contadores
	djnz	@@CHAR
	push	bc ; preserva contadores
	halt
; se mueve a la derecha una posición
	pop	bc ; restaura contadores
	pop	de ; restaura puntero de
	inc	de
	pop	hl ; restaura puntero hl
	inc	hl
	dec	c
	jr	nz, @@COL
	ret
; -----------------------------------------------------------------------------


; =============================================================================
;	VRAM routines (BIOS-based)
; =============================================================================

; -----------------------------------------------------------------------------
; Volcado con repetición de un mismo bloque a VRAM
; (rutina original: COPY_BLOCK de Eduardo A. Robsy Petrus)
; param hl: dirección RAM del bloque (normalmente CLRTBL)
; param de: dirección VRAM destino
; param b: número de bloques a copiar
LDIRVM_BLOCKS:
	push	bc ; preserva el contador
	push	hl ; preserva el origen
	push	de ; preserva el destino
; Vuelca un bloque
	ld	bc, 8
	call	LDIRVM
	pop	hl ; restaura el destino (en hl)
	ld	bc, 8 ; hl += 8
	add	hl, bc
	ex	de, hl ; destino actualizado en de
	pop	hl ; restaura el origen
	pop	bc ; restaura el contador
	djnz	LDIRVM_BLOCKS
	ret
; -----------------------------------------------------------------------------


; =============================================================================
;	Unpacking to VRAM routines
; =============================================================================

; -----------------------------------------------------------------------------
; Descomprime y vuelca a VRAM utilizando el buffer de descompresión y la BIOS
; param hl: origen de datos (comprimidos)
; param de: destino en VRAM
; param bc: tamaño a volcar en VRAM
UNPACK_LDIRVM:
	push	de ; preserva la dirección VRAM
	push	bc ; preserva el tamaño
; Descomprime
	ld	de, unpack_buffer
	push	de ; preserva la dirección del buffer de descompresión
	call	UNPACK
; Vuelca a VRAM
	pop	hl ; restaura la dirección del buffer de descompresión
	pop	bc ; restaura el tamaño
	pop	de ; restaura la dirección VRAM
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Descomprime y vuelca a los tres bancos de patrones utilizando la BIOS
; param hl: origen de datos (comprimidos)
UNPACK_LDIRVM_CHRTBL:
	ld	de, unpack_buffer
	call	UNPACK
	; jr	LDIRVM_CHRTBL ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca el buffer de descompresión a los tres bancos de patrones
; utiliznado la BIOS
LDIRVM_CHRTBL:
	ld	de, CHRTBL
	call	LDIRVM_CXRTBL_BANK
	ld	de, CHRTBL + CHRTBL_SIZE
	call	LDIRVM_CXRTBL_BANK
	ld	de, CHRTBL + CHRTBL_SIZE + CHRTBL_SIZE
	jr	LDIRVM_CXRTBL_BANK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Descomprime y vuelca a los tres bancos de colores utilizando la BIOS
; param hl: origen de datos (comprimidos)
UNPACK_LDIRVM_CLRTBL:
	ld	de, unpack_buffer
	call	UNPACK
	; jr	LDIRVM_CLRTBL ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca el buffer de descompresión a los tres bancos de colores
; utiliznado la BIOS
LDIRVM_CLRTBL:
	ld	de, CLRTBL
	call	LDIRVM_CXRTBL_BANK
	ld	de, CLRTBL + CHRTBL_SIZE
	call	LDIRVM_CXRTBL_BANK
	ld	de, CLRTBL + CHRTBL_SIZE + CHRTBL_SIZE
	; jr	LDIRVM_CXRTBL_BANK
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca el buffer de descompresión a un banco completo de patrones o colores
; utilizando la BIOS
; param de: dirección VRAM destino
LDIRVM_CXRTBL_BANK:
	ld	hl, unpack_buffer
	ld	bc, CHRTBL_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Descomprime
; param hl: origen de datos (comprimidos)
; param de: destino en RAM
UNPACK:
	; Pletter (v0.5c1, XL2S Entertainment, asMSX syntax by José Vila Cuadrillero)
	.include	"libext/pletter05c-unpackRam-asmsx.asm"
; -----------------------------------------------------------------------------


; =============================================================================
;	NAMTBL buffer text routines
; =============================================================================

; -----------------------------------------------------------------------------
; Escribe un literal centrado horizontalmente
; param hl: origen
; param de: primer caracter de la línea destino
; touches a, bc, de, hl
PRINT_TXT:
	call	LOCATE_CENTER
PRINT_TXT_DE_OK:
	xor	a
@@LOOP:
	cp	[hl]
	ret	z
	ldi
	jr	@@LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Escribe múltiples literales centrados horizontalmente
; param hl: origen
; param de: primer caracter de la línea destino
; touches a, bc, de, hl
PRINT_FULL_TXT:
	push	de ; preserva el destino
	call	PRINT_TXT
	pop	de ; restaura el destino
; ¿hay más texto pendiente?
	inc	hl ; salta el \0
	ld	a, [hl]
	or	a
	ret	z ; no
; sí: salto de línea
	ex	de, hl ; destino en hl
	ld	bc, SCR_WIDTH
	add	hl, bc
	ex	de, hl ; destino en de
	jr	PRINT_FULL_TXT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Centra horizontalmente un literal
; param hl: origen
; param de: primer caracter de la línea destino
; ret de: destino
; touches: a, bc
LOCATE_CENTER:
	push	hl ; preserva origen
; busca el siguiente \0
	xor	a
	ld	bc, SCR_WIDTH +1 ; (+1 para contar el último dec bc)
	cpir
; centra el puntero de escritura
	sra	b ; bc /= 2
	rr	c
	ex	de, hl ; de += bc (=(32 - longitud) / 2)
	add	hl, bc
	ex	de, hl
	pop	hl ; restaura origen
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Limpia una línea
; param hl: primer caracter de la línea destino
; touches: bc, de, hl
CLEAR_LINE:
	ld	d, h ; de = hl + 1
	ld	e, l
	inc	de
	ld	bc, SCR_WIDTH -1
	ld	[hl], $20 ; " " ASCII
	ldir
	ret
; -----------------------------------------------------------------------------


; =============================================================================
;	Logical coordinates sprite routines
; =============================================================================

; -----------------------------------------------------------------------------
; Número de sprites gestionados dinámicamente (por ejemplo: enemigos, balas)
	CFG_SPRITES_DYNAMIC	equ 32 -CFG_SPRITES_RESERVED_BEFORE -CFG_PLAYER_SPRITES -CFG_SPRITES_RESERVED_AFTER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Modifica las coordenadas de un sprite en el buffer de spratr
; param hl: puntero al sprite a modificar en el buffer de la spratr
; param d: coordenada x
; param e: coordenada y
; param b: número de sprites
MOVE_SPRITE_XY:
	djnz	@@MULTI

@@DO_PUT_SPRITE_XY:
; spratr y = coordenada y -16 -1
	ld	a, e
	add	CFG_SPRITES_Y_OFFSET
	ld	[hl], a
	inc	hl
; spratr x = coordenada x -8
	ld	a, d
	add	CFG_SPRITES_X_OFFSET
	ld	[hl], a
	ret
	
@@MULTI:
; primer sprite
	push	de ; preserva las coordenadas del objeto
	call	@@DO_PUT_SPRITE_XY
	pop	de ; restaura las coordenadas del objeto
; lee el patrón del sprite
	inc	hl
	ld	a, [hl]
@@LOOP:
; guarda el patrón del sprite en c
	ld	c, a
; siguiente sprite
	push	de ; preserva las coordenadas del objeto
	inc	hl ; avanza hasta el buffer de la spratr del siguiente sprite
	inc	hl
	call	@@DO_PUT_SPRITE_XY
	pop	de ; restaura las coordenadas del objeto
; escribe el siguiente patrón (c + 4)
	inc	hl
	ld	a, 4
	add	c
	ld	[hl], a
	djnz	@@LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Resetea toda la información de los sprites dinámicos
RESET_DYNAMIC_SPRITES:
; Rellena todas las coordenadas Y con SPAT_END
	ld	hl, dynamic_sprites
	ld	b, (spratr_buffer_end - dynamic_sprites) / 4
	ld	a, SPAT_END
@@LOOP:
	ld	[hl], a
; Avanza al siguiente sprite
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	djnz	@@LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Añade un sprite dinámico
; param de: coordenadas (y, x) lógicas o físicas
; param cb: atributos (patrón, color)
PUT_DYNAMIC_SPRITE_LOGICAL:
; Convierte las coordenadas lógicas en físicas (-8, -16)
	ld	a, d ; y -= 16, y--
	add	CFG_SPRITES_Y_OFFSET
	ld	d, a
	ld	a, e ; x -= 8
	add	CFG_SPRITES_X_OFFSET
	ld	e, a
	
PUT_DYNAMIC_SPRITE:
; Localiza el SPAT_END
	ld	hl, dynamic_sprites
	ld	a, SPAT_END
@@LOOP:
	cp	[hl]
	jr	z, @@HL_OK
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	jr	@@LOOP
@@HL_OK:

; Vuelca los valores en el buffer de SPRATR
	ld	[hl], d
	inc	hl
	ld	[hl], e
	inc	hl
	ld	[hl], c
	inc	hl
	ld	[hl], b
	ret
; -----------------------------------------------------------------------------


; =============================================================================
;	Deferred WRTVRM routines (aka VPOKE-like routines)
; =============================================================================

	VPOKE_SIZE	equ 3

IF (CFG_VRAM_VPOKES > 0)

; -----------------------------------------------------------------------------
; Inicializa la cola de volcados de NAMTBL
INIT_VPOKES:
	xor	a
	ld	[vpoke_count], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Añade un elemento a la cola de volcados de NAMTBL
; param hl: offset de NAMTBL
; param a: valor a escribir
; ret hl: offset de NAMTBL
; ret a: valor escrito
; touches bc
VPOKE:
	push	ix ; preserva el valor anterior de IX
	push	af ; preserva el valor a escribir
; Añade un elemento al array
	ld	ix, vpoke_count
	ld	bc, VPOKE_SIZE
	call	ADD_ARRAY_IX
; Informa el elemento añadido
	pop	af ; restaura el valor a escribir
	ld	[ix +0], l
	ld	[ix +1], h
	ld	[ix +2], a
	pop	ix ; restaura el valor anterior de IX
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Ejecuta los volcados de NAMTBL encolados y vacía la cola
EXECUTE_VPOKES:
; Comprueba si hay elementos encolados
	ld	ix, vpoke_count
	ld	a, [ix]
	or	a
	ret	z ; no hay elementos
; hay elementos
	ld	b, a
	xor	a ; resetea el contador para la próxima ejecución
	ld	[ix], a
	inc	ix ; ix = delayed_wrtvrm_array
	ld	de, NAMTBL ; para convertir offsets en NAMTBL

; Para cada elemento
@@LOOP:
	push	bc ; preserva el contador
	
; Lee el offset en bc
	ld	l, [ix +0]
	ld	h, [ix +1]
	ld	a, [ix +2]
; Vuelca el byte en VRAM
	add	hl, de
	call	WRTVRM
; Avanza al siguiente elemento
	ld	bc, VPOKE_SIZE
	add	ix, bc
	
	pop	bc ; restaura el contador
	djnz	@@LOOP
	ret
; -----------------------------------------------------------------------------

ENDIF ; (CFG_VRAM_VPOKES > 0)

; EOF