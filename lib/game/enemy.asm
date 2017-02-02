;
; =============================================================================
;	Enemies related constants and routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bounding box coordinates offset from the logical coordinates
	ENEMY_BOX_X_OFFSET:	equ -(CFG_ENEMY_WIDTH / 2)
	ENEMY_BOX_Y_OFFSET:	equ -CFG_ENEMY_HEIGHT

; Bits and flags of the enemy pattern modifiers
	BIT_ENEMY_PATTERN_LEFT:	equ 3
	BIT_ENEMY_PATTERN_ANIM:	equ 2
	FLAG_ENEMY_PATTERN_LEFT:	equ (1 << BIT_ENEMY_PATTERN_LEFT) ; $08
	FLAG_ENEMY_PATTERN_ANIM:	equ (1 << BIT_ENEMY_PATTERN_ANIM) ; $04
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; State definition related values
	_STATE_HANDLER_L:	equ 0
	_STATE_HANDLER_H:	equ 1
	_STATE_ARGUMENT:	equ 2
	STATE_SIZE:		equ 3
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Generic enemies related routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Empties the enemies array
RESET_ENEMIES:
; Fills the array with zeroes
	ld	hl, enemies_array
	ld	de, enemies_array +1
	ld	bc, ENEMIES_SIZE -1
	ld	[hl], 0
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new enemy (use call to invoke this routine).
; param [sp]: enemy data: pattern, color, state
; param de: logical coordinates of the enemy sprite
; touches hl, de, bc
INIT_ENEMY:
; Loops the enemies array
	ld	hl, enemies_array
	ld	bc, ENEMY_SIZE
	xor	a ; a = 0 (marker value)
.LOOP:
	cp	[hl]
	jr	z, .SET_VALUES ; empty slot (y = 0 means offscreen)
; Skips to the next element of the array
	add	hl, bc
	jr	.LOOP
	
.SET_VALUES:
; Stores the logical coordinates
	ld	[hl], d ; _ENEMY_Y
	inc	hl
	ld	[hl], e ; _ENEMY_X
	inc	hl
; Stores the pattern, color and initial handler
	ex	de, hl ; destination in de
	pop	hl ; source data: next to the call instruction
	ldi	; _ENEMY_PATTERN
	ldi	; _ENEMY_COLOR
	ldi	; _ENEMY_STATE
	ldi
; Resets the animation delay and frame counter
	xor	a
	ld	[hl], a ; _ENEMY_ANIMATION_DELAY
	inc	hl
	ld	[hl], a ; _ENEMY_FRAME_COUNTER
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Processes the current frame of all the enemies
UPDATE_ENEMIES:
; For each enemy in the array
	ld	ix, enemies_array
	ld	b, CFG_ENEMY_COUNT
.ENEMY_LOOP:
	push	bc ; preserves counter in b
; Is this enemy slot empty?
	xor	a ; 0 = marker value
	cp	[ix +_ENEMY_Y]
	jr	z, .NEXT_ENEMY ; yes: skip to the next enemy
; no: dereferences the state pointer
	ld	h, [ix +_ENEMY_STATE_H]
	ld	l, [ix +_ENEMY_STATE_L]
	push	hl ; iy = hl
	pop	iy
.HANDLER_LOOP:
; Invokes the current state handler
	ld	h, [iy +_STATE_HANDLER_H]
	ld	l, [iy +_STATE_HANDLER_L]
	call	JP_HL ; emulates "call [hl]"
; Has the handler finished?
	jr	nz, .NEXT_ENEMY ; no: pending frames
; Yes: skips to the next state handler
	ld	bc, STATE_SIZE
	add	iy, bc
	jr	.HANDLER_LOOP
.NEXT_ENEMY:
; Skip to the next enemy
	ld	bc, ENEMY_SIZE
	add	ix, bc
	pop	bc ; restores the counter
	djnz	.ENEMY_LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Special handler that sets a new current state for the current enemy
; (i.e.: this handler is usually the last handler of a complete state)
; param ix: pointer to the enemy
; param iy: pointer to this state
; param [iy + _STATE_ARGUMENT]: offset to the next state (in bytes)
; ret nz: this handler always finishes the current state
EH_SET_STATE:
; Reads the offset as 16-bit signed
	ld	a, [iy + _STATE_ARGUMENT]
	call	LD_BC_A
; Points the enemy to the new state
	push	iy ; hl = iy + bc
	pop	hl
	add	hl, bc
	ld	[ix +_ENEMY_STATE_H], h
	ld	[ix +_ENEMY_STATE_L], l
; Resets the animation flag, the animation delay and the frame counter
	res	BIT_ENEMY_PATTERN_ANIM, [ix + _ENEMY_PATTERN]
	xor	a
	ld	[ix + _ENEMY_ANIMATION_DELAY], a
	ld	[ix + _ENEMY_FRAME_COUNTER], a
; ret nz (halt current frame execution)
	inc	a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Generic convenience routines for enemies
; =============================================================================
;

; -----------------------------------------------------------------------------
; Alterna el bit de dirección de un enemigo
; param ix: puntero al enemigo
TURN_ENEMY:
	ld	a, FLAG_ENEMY_PATTERN_LEFT
	xor	[ix + _ENEMY_PATTERN]
	ld	[ix + _ENEMY_PATTERN], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param ix: puntero al enemigo
; ret c/nc: c = derecha, nc = izquierda
TURN_ENEMY_TOWARDS_PLAYER:
	ld	a, [player_x]
	cp	[ix +_ENEMY_X]
	jr	c, .AIM_LEFT
	
.AIM_RIGHT:
	res	BIT_ENEMY_PATTERN_LEFT, [ix + _ENEMY_PATTERN]
	ret
	
.AIM_LEFT:
	set	BIT_ENEMY_PATTERN_LEFT, [ix + _ENEMY_PATTERN]
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Convenience routines for enemies (platform games)
; =============================================================================
;

; -----------------------------------------------------------------------------
TURN_WALKING_ENEMY_TOWARDS_PLAYER:
	call	TURN_ENEMY_TOWARDS_PLAYER
	call	CAN_ENEMY_WALK
	ret	nz
	jp	TURN_ENEMY
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param ix: puntero al enemigo
CAN_ENEMY_WALK:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + _ENEMY_PATTERN]
	jr	z, CAN_ENEMY_WALK_RIGHT
	jr	CAN_ENEMY_WALK_LEFT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param ix: puntero al enemigo
CAN_ENEMY_FLY:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + _ENEMY_PATTERN]
	jr	z, CAN_ENEMY_FLY_RIGHT
	jr	CAN_ENEMY_FLY_LEFT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param ix: puntero al enemigo
CAN_ENEMY_WALK_LEFT:
; ¿Puede seguir avanzando (comprueba suelos)?
	call	CHECK_TILE_UNDER_LEFT_ENEMY
	bit	BIT_WORLD_FLOOR, a
	ret	z
	
CAN_ENEMY_FLY_LEFT:
; ¿Puede seguir avanzando (comprueba colisiones)?
	call	CHECK_TILES_LEFT_ENEMY
	cpl	; Comprueba en negativo para devolver z/nz correctamente
	bit	BIT_WORLD_SOLID, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param ix: puntero al enemigo
CAN_ENEMY_WALK_RIGHT:
; ¿Puede seguir avanzando (comprueba suelos)?
	call	CHECK_TILE_UNDER_RIGHT_ENEMY
	bit	BIT_WORLD_FLOOR, a
	ret	z
	
CAN_ENEMY_FLY_RIGHT:
; ¿Puede seguir avanzando (comprueba colisiones)?
	call	CHECK_TILES_RIGHT_ENEMY
	cpl	; Comprueba en negativo para devolver z/nz correctamente
	bit	BIT_WORLD_SOLID, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or) de los tiles a la izquierda del jugador
; ret a: propiedades acumuladas (or) de los tiles
CHECK_TILES_LEFT_ENEMY:
; ¿hay cambio de tile hacia la izquierda?
	ld	a, [ix + _ENEMY_X]
	add	ENEMY_BOX_X_OFFSET
	and	$07
	jp	nz, CHECK_NO_TILES ; no: descarta comprobación
	
; sí: hace comprobación
	ld	a, ENEMY_BOX_X_OFFSET -1
	jr	CHECK_V_TILES_ENEMY
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or) de los tiles a la izquierda del jugador
; ret a: propiedades acumuladas (or) de los tiles
CHECK_TILES_RIGHT_ENEMY:
; ¿hay cambio de tile hacia la derecha?
	ld	a, [ix + _ENEMY_X]
	add	ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
	and	$07
	jp	nz, CHECK_NO_TILES ; no: descarta comprobación
	
; sí: hace comprobación
	ld	a, ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
	jr	CHECK_V_TILES_ENEMY
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or)
; de una serie vertical de tiles relacionada con el jugador
; param a: dy respecto a las coordenadas del jugador
; ret a: propiedades acumuladas (or) de los tiles
CHECK_V_TILES_ENEMY:
; Coordenadas del enemigo
	ld	e, [ix + _ENEMY_Y]
	ld	d, [ix + _ENEMY_X]
; x += dx
	add	d
	ld	d, a
; y += PLAYER_Y_OFFSET
	ld	a, ENEMY_BOX_Y_OFFSET
	add	e
	ld	e, a
; altura del objeto
	ld	b, CFG_ENEMY_HEIGHT
	jp	CHECK_V_TILES
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades de un tile por debajo del enemigo
; param ix: puntero al enemigo
CHECK_TILE_UNDER_LEFT_ENEMY:
	ld	a, ENEMY_BOX_X_OFFSET -1
	jr	CHECK_TILE_UNDER_ENEMY_A_OK
	
CHECK_TILE_UNDER_RIGHT_ENEMY:
	ld	a, ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
	jr	CHECK_TILE_UNDER_ENEMY_A_OK
	
CHECK_TILE_UNDER_ENEMY:
	xor	a
	; jr	CHECK_TILES_UNDER_ENEMY_A_OK ; falls through
	
CHECK_TILE_UNDER_ENEMY_A_OK:
; Coordenadas del enemigo
	ld	e, [ix + _ENEMY_Y]
; x += dx
	add	[ix + _ENEMY_X]
	ld	d, a
; Lee el tile
	call	GET_TILE_AT_XY
	jp	GET_TILE_PROPERTIES
; -----------------------------------------------------------------------------

; ;
; ; =============================================================================
; ;	Subrutinas especÃ­ficas de juegos
; ; =============================================================================
; ;

; ; -----------------------------------------------------------------------------
; CHECK_COLLISIONS_ENEMIES:
; ; Recorre el array de enemigos
	; ld	ix, enemies_array
	; ld	b, MAX_ENEMY_COUNT
; .LOOP:
	; push	bc ; preserva el contador en b
	; call	CHECK_COLLISION_ENEMY
; ; AVanza al siguiente enemigo
	; ld	bc, ENEMY_SIZE
	; add	ix, bc
	; pop	bc ; restaura el contador
	; djnz	.LOOP
; ; -----------------------------------------------------------------------------


; ; -----------------------------------------------------------------------------
; ; param ix
; CHECK_COLLISION_ENEMY:
; ; sÃ­: compara la diferencia horizontal
	; ld	a, [player_x]
	; sub	[ix + _ENEMY_X]
; ; (valor absoluto)
	; jp	p, .ELSE_X
	; neg
; .ELSE_X:
; ; Â¿Hay solapamiento?
	; cp	(PLAYER_WIDTH + ENEMY_WIDTH) /2
	; ret	nc ; no
	
; ; Compara la diferencia vertical
	; ld	a, [player_y]
	; sub	[ix + _ENEMY_Y]
; ; (valor absoluto)
	; jp	p, .ELSE_Y
	; neg
; .ELSE_Y:
; ; Â¿Hay solapamiento?
	; cp	(PLAYER_HEIGHT + ENEMY_HEIGHT) /2
	; ret	nc ; no
	
; ; sÃ­
	; jp	ON_ENEMY_COLLISION_UX
; ; -----------------------------------------------------------------------------

; EOF