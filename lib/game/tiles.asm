
; =============================================================================
;	Sprite-tile helper routines
; =============================================================================

; -----------------------------------------------------------------------------
; Translate pixel coordinates to NAMTBL offsets
; param de: pixe coordinates (yx pair, two bytes)
; ret hl: NAMTBL offset (in bytes)
; touches a
COORDS_TO_OFFSET:
; y part: hl = y / 8 * 32
	ld	a, e
	and	$f8 ; equivalent to /8 *8
	ld	h, 0
	ld	l, a
	add	hl, hl
	add	hl, hl
; x part: a = x / 8
	ld	a, d
	srl	a
	srl	a
	srl	a
; hl += a
	jp	ADD_HL_A
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Translates NAMTBL buffer pointers to pixel coordinates
; param hl: NAMTBL buffer pointer
; ret hl: NAMTBL offset (in bytes)
; ret de: pixel coordinates (yx pair, two bytes)
; touches a
NAMTBL_POINTER_TO_COORDS:
	ld	de, -namtbl_buffer + $10000 ; de = hl -namtbl_buffer +SCR_WIDTH
	add	hl, de
	ex	de, hl
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Translates NAMTBL offsets to pixel coordinates
; Convierte coordenadas en bytes en coordenadas en píxeles
; param de: NAMTBL offset (in bytes)
; ret de: pixel coordinates (y, x)
; touches a
OFFSET_TO_COORDS:
; y = (de / 32) *8 = (de / 4) mod 8
	ld	a, e ; a instead of e to preserve e
	srl	d
	rr	a
	srl	d
	rr	a
	and	$f8
	ld	d, a
; x = (de mod 32) *8 = (e * 8)
	sla	e
	sla	e
	sla	e
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the tile index (value) at some pixel coordinates
; param de: pixe coordinates (yx pair, two bytes)
; ret hl: NAMTBL buffer pointer
; ret de: NAMTBL offset (in bytes)
; ret a: tile index (value)
; touches de
GET_TILE_AT_XY:
; Is on screen?
	ld	a, e
	sub	192 -1
	jr	nc, .OFF_SCREEN ; no (e >= 192)
; yes: pixel coordinates to offset
	call	COORDS_TO_OFFSET
	ex	de, hl ; offset now in de
; hl = namtbl buffer + offset
	ld	hl, namtbl_buffer
	add	hl, de
; reads the tile value
	ld	a, [hl]
	ret
	
.OFF_SCREEN:
; Is below screen?
	cp	32 +1
	ld	a, CFG_TILES_OFFSCREEN_BOTTOM
	ret	c ; yes (e - 192 < 32)
; no: Over screen (e - 192 > 32  ->  e > -32)
	ld	a, CFG_TILES_OFFSCREEN_TOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the properties of a tile index (value)
; ret a: tile index (value)
; ret a: tile properties
; touches hl
GET_TILE_PROPERTIES:
	ld	hl, TILE_PROPERTIES_TABLE
.LOOP:
; Is the current tile group max index less than or equals the tile index?
	cp	[hl]
	inc	hl ; hl now points to the properties
	jr	c, .OK ; yes (lower)
	jr	z, .OK ; yes (equal)
; no: skip to the next tile group
	inc	hl ; hl now points to the next tile group
	jr	.LOOP
.OK:
	ld	a, [hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience routine to read no properties
; (usually used in _FAST version of the checks)
; ret a: 0
; ret z
CHECK_NO_TILES:
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or) de una serie vertical de tiles
; param de: coordenadas x,y del objeto
; param b: altura del objeto
; ret a: propiedades acumuladas (or) de los tiles
CHECK_V_TILES:
; Determina el número de tiles a comprobar
	ld	a, e
	and	$07	; coordenada y (mod 8: posición sub tile)
	add	b	; ...+altura
	dec	a	; ...-1
; Convierte en número de tiles
	srl	a
	srl	a
	srl	a
	inc	a
	ld	b, a ; almacena en b
; Lee el primer tile
	call	GET_TILE_AT_XY ; adicionalmente: hl = puntero a buffer namtbl
; ¿Es el único tile a comprobar?
	dec	b
	jp	z, GET_TILE_PROPERTIES ; sí: Devuelve sus propiedades
; no: Lee las propiedades del primer tile
	push	hl ; preserva puntero a buffer namtbl
	call	GET_TILE_PROPERTIES
	pop	hl ; restaura puntero a buffer namtbl
; Para cada tile restante
.LOOP:
	push	bc ; preserva contador
; Avanza el puntero en buffer namtbl
	ld	bc, SCR_WIDTH
	add	hl, bc
	push	hl ; preserva puntero
; Lee el tile, lee sus propiedades
	push	af ; preserva propiedades previas
	ld	a, [hl]
	call	GET_TILE_PROPERTIES
	pop	hl ; restaura propiedades previas en h
; Acumula propiedades
	or	h
; Pasa al siguiente tile
	pop	hl ; restaura el puntero
	pop	bc ; restaura contador
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or) de una serie horizontal de tiles
; param de: coordenadas originales (en píxeles)
; param b: anchura a comprobar (en píxeles)
; ret a: propiedades acumuladas (or) de los tiles
CHECK_H_TILES:
; Determina el número de tiles a comprobar
	ld	a, d
	and	$07	; coordenada x (mod 8: posición sub tile)
	add	b	; ...+anchura
	dec	a	; ...-1
; Convierte en número de tiles
	srl	a
	srl	a
	srl	a
	inc	a
	ld	b, a ; almacena en b
; Lee el primer tile
	call	GET_TILE_AT_XY ; adicionalmente: hl = puntero a buffer namtbl
; ¿Es el único tile a comprobar?
	dec	b
	jp	z, GET_TILE_PROPERTIES ; sí: Devuelve sus propiedades
; no: Lee las propiedades del primer tile
	push	hl ; preserva puntero a buffer namtbl
	call	GET_TILE_PROPERTIES
	pop	hl ; restaura puntero a buffer namtbl
; Para cada tile restante
.LOOP:
	push	bc ; preserva contador
; Avanza el puntero en buffer namtbl
	inc	hl
	push	hl ; preserva puntero
; Lee el tile, lee sus propiedades
	push	af ; preserva propiedades previas
	ld	a, [hl]
	call	GET_TILE_PROPERTIES
	pop	hl ; restaura propiedades previas en h
; Acumula propiedades
	or	h
; Pasa al siguiente tile
	pop	hl ; restaura el puntero
	pop	bc ; restaura contador
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; EOF