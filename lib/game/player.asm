;
; =============================================================================
;	Player related constants and routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Offset de las coordenadas del bounding box de los sprites
	PLAYER_BOX_X_OFFSET:	equ -(CFG_PLAYER_WIDTH / 2)
	PLAYER_BOX_Y_OFFSET:	equ -CFG_PLAYER_HEIGHT
	
; Bit index for default tile properties
	BIT_WORLD_SOLID:	equ 0
	BIT_WORLD_FLOOR:	equ 1
	BIT_WORLD_STAIRS:	equ 2
	BIT_WORLD_DEATH:	equ 3
	BIT_WORLD_WALK_ON:	equ 4 ; Tile collision (single char)
	BIT_WORLD_WIDE_ON:	equ 5 ; Wide tile collision (player width)
	BIT_WORLD_WALK_OVER:	equ 6 ; Walking over tiles (player width)
	BIT_WORLD_PUSHABLE:	equ 7 ; Pushable tiles (player height)

; Modificadores de estados del jugador (en forma de bits y flags) 
	BIT_STATE_LEFT:		equ 0
	BIT_STATE_ANIM:		equ 1
	FLAG_STATE_LEFT:	equ (1 << BIT_STATE_LEFT) ; $01
	FLAG_STATE_ANIM:	equ (1 << BIT_STATE_ANIM) ; $02
	FLAGS_STATE:		equ FLAG_STATE_LEFT + FLAG_STATE_ANIM ; $03

; Estados del jugador por defecto
	PLAYER_STATE_FLOOR:	equ (0 << 2) ; $00
	PLAYER_STATE_STAIRS:	equ (1 << 2) ; $04
	PLAYER_STATE_AIR:	equ (2 << 2) ; $08
	PLAYER_STATE_DYING:	equ (3 << 2) ; $0c
; Estados del jugador definidos por el usuario
	; ...

; Condiciones de salida por defecto (estados del jugador especiales)
	BIT_STATE_FINISH:	equ 7
	PLAYER_STATE_DEAD:	equ (1 << BIT_STATE_FINISH) + (0 << 2); $80
	PLAYER_STATE_FINISH:	equ (1 << BIT_STATE_FINISH) + (1 << 2); $84
; Condiciones de salida definidas por el usuario
	; ...
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Generic player related routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Modifica las coordenadas de los sprites del jugador en el buffer de spratr
PUT_SPRITE_PLAYER:
; Obtiene el patrón del primer sprite en función del estado
	ld	a, [player.state]
	ld	hl, STATUS_SPRATR_TABLE
	call	GET_HL_A_BYTE
	ld	[spratr_player + 2], a
; Volcado de coordenadas
	ld	de, [player.xy]
	ld	hl, spratr_player
	ld	b, CFG_PLAYER_SPRITES
	jp	MOVE_SPRITES
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Player related routines (platform game)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Rutina de control de jugador (plataformas)
UPDATE_PLAYER:
; salta a la rutina correcta en función del estado
	ld	a, [player.state] ; a = estado << 2 + flags
	srl	a ; a = estado << 1
	srl	a ; a = estado
	ld	hl, UPDATE_PLAYER_TABLE
	call	JP_TABLE
	
; ¿estado finalizado?
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	ret	nz ; sí
; no: comprobaciones que se hacen en todos los estados:

; colisión, un tile
	call	CHECK_TILE_PLAYER
; ¿muerte?
	bit	BIT_WORLD_DEATH, a
	jp	nz, SET_PLAYER_DYING ; sí
; UX: ¿colisión, un tile?
IFEXIST ON_PLAYER_WALK_ON
	bit	BIT_WORLD_WALK_ON, a
	call	nz, ON_PLAYER_WALK_ON ; sí
ENDIF
	
; UX: ¿colisión, tiles (ancho del jugador)?
IFEXIST ON_PLAYER_WIDE_ON
	call	CHECK_TILES_PLAYER
	bit	BIT_WORLD_WIDE_ON, a
	call	nz, ON_PLAYER_WIDE_ON ; sí
ENDIF
	
; UX: ¿jugador sobre tiles (ancho del jugador)?
IFEXIST ON_PLAYER_WALK_OVER
	call	CHECK_TILES_UNDER_PLAYER
	bit	BIT_WORLD_WALK_OVER, a
	call	nz, ON_PLAYER_WALK_OVER ; sí
ENDIF

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Hace que el jugador esté sobre suelo
SET_PLAYER_FLOOR:
; ajusta la coordenada vertical
	ld	a, [player.y]
	add	CFG_PLAYER_GRAVITY - 1
	and	$f8 ; alinea a caracter vertical
	ld	[player.y], a
; cambia el estado
	ld	a, PLAYER_STATE_FLOOR
	jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Rutina de control de jugador cuando el jugador está sobre suelo
UPDATE_PLAYER_FLOOR:
; ¿Accede a escaleras?
	ld	hl, stick
	bit	BIT_STICK_UP, [hl]
	jr	z, .NO_UPSTAIRS
; sí (arriba)
	call	CHECK_TILE_PLAYER
	jr	.CHECK_STAIRS
	
.NO_UPSTAIRS:
	ld	hl, stick
	bit	BIT_STICK_DOWN, [hl]
	jr	z, .NO_DOWNSTAIRS ; no
; sí (abajo)
	call	CHECK_TILES_UNDER_PLAYER_FAST
	; jr	.CHECK_STAIRS ; falls through
	
.CHECK_STAIRS:
; ¿Hay escaleras pero no sólido?
	and	(1 << BIT_WORLD_SOLID) + (1 << BIT_WORLD_STAIRS)
	cp	(1 << BIT_WORLD_STAIRS)
	jr	z, SET_PLAYER_STAIRS ; sí

.NO_DOWNSTAIRS:
; no: ¿Salto?
	ld	hl, stick_edge
	bit	BIT_STICK_UP, [hl]
	jp	nz, SET_PLAYER_JUMPING ; sí
	
; no: gestiona el desplazamiento lateral
	call	MOVE_PLAYER_LR_ANIMATE
	
; ¿Hay suelo debajo del jugador?
	call	CHECK_TILES_UNDER_PLAYER_FAST
	bit	BIT_WORLD_FLOOR, a
	ret	nz ; sí
; no
	jp	SET_PLAYER_FALLING
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Hace que el jugador empiece a estar en unas escaleras
SET_PLAYER_STAIRS:
; cambia el estado
	ld	a, PLAYER_STATE_STAIRS
	call	SET_PLAYER_STATE
	
; gestiona el desplazamiento lateral
	call	MOVE_PLAYER_LR
	
; gestiona el desplazamiento vertical
	jr	UPDATE_PLAYER_STAIRS_0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Rutina de control de jugador cuando el jugador está en unas escaleras
UPDATE_PLAYER_STAIRS:
; Gestiona el desplazamiento lateral
	call	MOVE_PLAYER_LR
; ¿Ha salido de la escalera?
	call	CHECK_TILE_PLAYER
	bit	BIT_WORLD_STAIRS, a
	jp	z, SET_PLAYER_OFF_STAIRS ; sí
	
UPDATE_PLAYER_STAIRS_0:
; no: ¿desplazamiento vertical?
	ld	hl, stick
	bit	BIT_STICK_UP, [hl]
	jr	z, .NO_UP
; sí (arriba): ¿Hay sólido?
	call	CHECK_TILES_OVER_PLAYER_FAST
	bit	BIT_WORLD_SOLID, a
	ret	nz ; sí
; no
	ld	hl, player.y
	dec	[hl]
	jp	UPDATE_PLAYER_ANIMATION

.NO_UP:
	bit	BIT_STICK_DOWN, [hl]
	ret	z ; no
; sí (abajo): ¿Sigue habiendo escaleras?
	call	CHECK_TILES_UNDER_PLAYER
	bit	BIT_WORLD_STAIRS, a
	jr	z, SET_PLAYER_OFF_STAIRS ; no
; sí: ¿Hay sólido?
	bit	BIT_WORLD_SOLID, a
	ret	nz ; sí
; no
	ld	hl, player.y
	inc	[hl]
	jp	UPDATE_PLAYER_ANIMATION
	
SET_PLAYER_OFF_STAIRS:
; ¿hay suelo por abajo?
	call	CHECK_TILES_UNDER_PLAYER_FAST
	bit	BIT_WORLD_FLOOR, a
	jp	nz, SET_PLAYER_FLOOR ; sí
	jp	SET_PLAYER_FALLING ; no
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Hace que el jugador empiece a caer
SET_PLAYER_FALLING:
; cambia el estado
	ld	a, PLAYER_STATE_AIR
	call	SET_PLAYER_STATE
; inicializa el puntero a la tabla de dy
	ld	a, JUMP_DY_TABLE_FALL_OFFSET
	ld	[player.dy_index], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Hace que el jugador salte
SET_PLAYER_JUMPING:
; cambia el estado
	ld	a, PLAYER_STATE_AIR
	call	SET_PLAYER_STATE
; inicializa el puntero a la tabla de dy
	xor	a
	ld	[player.dy_index], a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Rutina de control de jugador cuando el jugador está saltando o cayendo
UPDATE_PLAYER_AIR:
; Gestiona el desplazamiento lateral
	call	MOVE_PLAYER_LR
	
; Gestiona el desplazamiento vertical
	call	UPDATE_PLAYER_DY
	or	a
	ret	z ; (dy == 0)
	jp	m, .UP ; (dy < 0)

; (dy > 0): ¿Hay suelo debajo del jugador?
	push	af ; preserva dy
	call	CHECK_TILES_UNDER_PLAYER_FAST
	bit	BIT_WORLD_FLOOR, a
	pop	bc ; restaura dy (en b para no pisar f)
	jp	nz, SET_PLAYER_FLOOR ; sí
; no
	ld	a, b ; restaura dy (en a)
	jp	MOVE_PLAYER_DY
	
.UP:
; (dy < 0): ¿Hay sólido encima del jugador?
	push	af ; preserva dy
	call	CHECK_TILES_OVER_PLAYER_FAST
	bit	BIT_WORLD_SOLID, a
	pop	bc ; restaura dy (en b para no pisar f)
	jp	nz, SET_PLAYER_FALLING ; sí
; no
	ld	a, b ; restaura dy (en a)
	jp	MOVE_PLAYER_DY
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Hace que el jugador empiece a morir
SET_PLAYER_DYING:
; ¿ya está muriendo? (evita que vuelva a empezar a morir si ya está muriendo)
	ld	a, [player.state]
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_DYING
	ret	z ; sí
; no: cambia el estado
	ld	a, PLAYER_STATE_DYING
	call	SET_PLAYER_STATE
; inicializa el puntero a la tabla de dy
	xor	a
	ld	[player.dy_index], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Rutina de control de jugador cuando está muriendo
UPDATE_PLAYER_DYING:
; Anima
	call	UPDATE_PLAYER_ANIMATION
; Gestiona el desplazamiento vertical
	call	UPDATE_PLAYER_DY
	call	MOVE_PLAYER_DY
; ¿fin de la pantalla?
	ld	a, [player.y]
	cp	192 +16 +1
	ret	c ; no
	; jr	SET_PLAYER_DEAD ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Hace que el jugador acabe de morir (condición de salida)
SET_PLAYER_DEAD:
; cambia el estado
	ld	a, PLAYER_STATE_DEAD
	; jr	SET_PLAYER_STATE ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Cambia el estado de un jugador, manteniendo el flag izquierda
; param a: nuevo estado
; touches hl, b
; ret a: nuevo estado con el flag izquierda anterior
SET_PLAYER_STATE:
	ld	b, $ff XOR FLAG_STATE_LEFT
SET_PLAYER_STATE_B_OK:
	ld	hl, player.state
	jp	LD_HL_A_MASK
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Gestiona el desplazamiento lateral en función de los cursores, sin animación
MOVE_PLAYER_LR:
; ¿Desplazamiento lateral?
	ld	hl, stick
	bit	BIT_STICK_RIGHT, [hl]
	jr	z, .NO_RIGHT
	
; sí: derecha
	call	CHECK_TILES_RIGHT_PLAYER_FAST
	bit	BIT_WORLD_SOLID, a
	ret	nz
	jp	MOVE_PLAYER_RIGHT
	
.NO_RIGHT:
	bit	BIT_STICK_LEFT, [hl]
	ret	z ; no
	
; sí: izquierda
	call	CHECK_TILES_LEFT_PLAYER_FAST
	bit	BIT_WORLD_SOLID, a
	ret	nz
	jp	MOVE_PLAYER_LEFT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Gestiona el desplazamiento lateral en función de los cursores, con animación
MOVE_PLAYER_LR_ANIMATE:
; ¿Desplazamiento lateral?
	ld	hl, stick
	bit	BIT_STICK_RIGHT, [hl]
	jr	nz, .RIGHT ; sí (derecha)
	bit	BIT_STICK_LEFT, [hl]
	jr	nz, .LEFT ; sí (izquierda)

.RESET_ANIMATION:
; resetea el contador de animación
	xor	a
	ld	[player.animation_delay], a
; apaga el bit de animación
	ld	hl, player.state
	res	BIT_STATE_ANIM, [hl]
	
; IF (BIT_WORLD_PUSHABLE = 0)
	; ret
; ELSE
.RESET_STATE:
; resetea el estado si está activa la UX de empujar
	ld	a, PLAYER_STATE_FLOOR
	ld	b, $ff XOR FLAGS_STATE
	jp	SET_PLAYER_STATE_B_OK
; ENDIF ; (BIT_WORLD_PUSHABLE == 0)

.RIGHT:
	call	CHECK_TILES_RIGHT_PLAYER_FAST
	
; UX: ¿empujando tiles (alto del jugador)?
IFEXIST ON_PLAYER_PUSH.RIGHT
	bit	BIT_WORLD_PUSHABLE, a
	jp	nz, ON_PLAYER_PUSH.RIGHT ; sí
ENDIF

; ¿Hay sólido a la derecha?
	bit	BIT_WORLD_SOLID, a
	jr	nz, .RESET_ANIMATION ; sí

; resetea el estado si está activa la UX de empujar
IFEXIST ON_PLAYER_PUSH
	call	.RESET_STATE
ENDIF

; no: mueve y anima
	call	MOVE_PLAYER_RIGHT
	jp	UPDATE_PLAYER_ANIMATION

.LEFT:
	call	CHECK_TILES_LEFT_PLAYER_FAST

; UX: ¿empujando tiles (alto del jugador)?
IFEXIST ON_PLAYER_PUSH.LEFT
	bit	BIT_WORLD_PUSHABLE, a
	jp	nz, ON_PLAYER_PUSH.LEFT ; sí
ENDIF

; ¿Hay sólido a la izquierda?
	bit	BIT_WORLD_SOLID, a
	jr	nz, .RESET_ANIMATION ; sí

; resetea el estado si está activa la UX de empujar
IFEXIST ON_PLAYER_PUSH
	call	.RESET_STATE
ENDIF

; no: mueve y anima
	call	MOVE_PLAYER_LEFT
	jp	UPDATE_PLAYER_ANIMATION
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Gestiona el puntero de desplazamiento vertical
; ret a: dy
UPDATE_PLAYER_DY:
; ¿Se ha alcanzado el final de la tabla de dy?
	ld	hl, player.dy_index
	ld	a, [hl]
	cp	JUMP_DY_TABLE_SIZE -1
	jr	z, .DY_MAX ; sí
; no: avanza el puntero
	inc	[hl]
.DY_MAX:
; Lee el valor de dy
	ld	hl, JUMP_DY_TABLE
	jp	GET_HL_A_BYTE
; -----------------------------------------------------------------------------


; =============================================================================
;	Jugador
; =============================================================================

; -----------------------------------------------------------------------------
; Actualiza el contador de animación y alterna el bit de animación si procede
UPDATE_PLAYER_ANIMATION:
; actualiza el contador de animación
	ld	a, [player.animation_delay]
	inc	a
	cp	CFG_PLAYER_ANIMATION_DELAY
	jr	nz, .DONT_ANIMATE
; alterna el bit de animación
	ld	hl, player.state
	ld	a, 1 << BIT_STATE_ANIM
	xor	[hl]
	ld	[hl], a
; resetea el contador de animación
	xor	a
.DONT_ANIMATE:
	ld	[player.animation_delay], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Mueve el jugador a la derecha
MOVE_PLAYER_RIGHT:
; desplaza a la derecha
	ld	hl, player.x
	inc	[hl]
; mira a la derecha
	inc	hl
	inc	hl ; hl = player.state
	res	BIT_STATE_LEFT, [hl]
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Mueve el jugador a la izquierda
MOVE_PLAYER_LEFT:
; desplaza a la izquierda
	ld	hl, player.x
	dec	[hl]
; mira a la izquierda
	inc	hl
	inc	hl ; hl = player.state
	set	BIT_STATE_LEFT, [hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Mueve el jugador en vertical
; parm a: dy
MOVE_PLAYER_DY:
; y += dy
	ld	hl, player.y
	add	[hl]
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Subrutinas de apoyo a la gestión de tiles
; =============================================================================
;

; -----------------------------------------------------------------------------
; Determina sobre qué tile está principalmente el jugador
; (comprueba la parte baja del jugador)
; ret hl: puntero al buffer namtbl del tile principal del jugador
; ret de: offset (en bytes) del tile principal del jugador
; ret a: tile (índice) principal del jugador
GET_TILE_AT_PLAYER:
	ld	de, [player.xy]
	dec	e
	jp	GET_TILE_AT_XY
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades del tile principal en el que está el jugador
; (comprueba la parte baja del jugador)
CHECK_TILE_PLAYER:
	call	GET_TILE_AT_PLAYER
	jp	GET_TILE_PROPERTIES
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or) de los tiles a la izquierda del jugador
; ret a: propiedades acumuladas (or) de los tiles
CHECK_TILES_LEFT_PLAYER_FAST:
; ¿hay cambio de tile hacia la izquierda?
	ld	a, [player.x]
	add	PLAYER_BOX_X_OFFSET
	and	$07
	jp	nz, CHECK_NO_TILES ; no: descarta comprobación
	
; sí: hace comprobación
CHECK_TILES_LEFT_PLAYER:
	ld	a, PLAYER_BOX_X_OFFSET -1
	jr	CHECK_V_TILES_PLAYER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or) de los tiles a la derecha del jugador
; ret a: propiedades acumuladas (or) de los tiles
CHECK_TILES_RIGHT_PLAYER_FAST:
; ¿hay cambio de tile hacia la derecha?
	ld	a, [player.x]
	add	PLAYER_BOX_X_OFFSET + CFG_PLAYER_WIDTH
	and	$07
	jp	nz, CHECK_NO_TILES ; no: descarta comprobación

; sí: hace comprobación
CHECK_TILES_RIGHT_PLAYER:
	ld	a, PLAYER_BOX_X_OFFSET + CFG_PLAYER_WIDTH
	jr	CHECK_V_TILES_PLAYER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or)
; de una serie vertical de tiles relacionada con el jugador
; param a: dy respecto a las coordenadas del jugador
; ret a: propiedades acumuladas (or) de los tiles
CHECK_V_TILES_PLAYER:
; Coordenadas del jugador
	ld	de, [player.xy]
; x += dx
	add	d
	ld	d, a
; y += PLAYER_Y_OFFSET
	ld	a, PLAYER_BOX_Y_OFFSET
	add	e
	ld	e, a
; altura del objeto
	ld	b, CFG_PLAYER_HEIGHT
	jp	CHECK_V_TILES
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or) de los tiles por encima del jugador
; ret a: propiedades acumuladas (or) de los tiles
CHECK_TILES_OVER_PLAYER_FAST:
; ¿hay cambio de tile hacia arriba?
	ld	a, [player.y]
	add	PLAYER_BOX_Y_OFFSET
	and	$07
	jp	nz, CHECK_NO_TILES ; no: descarta comprobación
	
; sí: hace comprobación
CHECK_TILES_OVER_PLAYER:
	ld	a, PLAYER_BOX_Y_OFFSET - 1
	jr	CHECK_H_TILES_PLAYER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or) de los tiles en los que está el jugador
; (comprueba la parte baja del jugador)
CHECK_TILES_PLAYER:
	ld	a, -1
	jr	CHECK_H_TILES_PLAYER
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or) de los tiles por debajo del jugador
; ret a: propiedades acumuladas (or) de los tiles
CHECK_TILES_UNDER_PLAYER_FAST:
; ¿hay cambio de tile hacia abajo?
	ld	a, [player.y]
	and	$07
	cp	4 ; 0..3 dado que la velocidad terminal es 4
	jp	nc, CHECK_NO_TILES ; no: descarta comprobación
	
; sí: hace comprobación
CHECK_TILES_UNDER_PLAYER:
	xor	a ; dy = 0 = justo debajo del jugador
	; jr	CHECK_H_TILES_PLAYER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee las propiedades acumuladas (or)
; de una serie horizontal de tiles relacionada con el jugador
; param a: dy respecto a las coordenadas del jugador
; ret a: propiedades acumuladas (or) de los tiles
CHECK_H_TILES_PLAYER:
; Coordenadas del jugador
	ld	de, [player.xy]
; y += dy
	add	e
	ld	e, a
; x += PLAYER_X_OFFSET
	ld	a, PLAYER_BOX_X_OFFSET
	add	d
	ld	d, a
; anchura del objeto
	ld	b, CFG_PLAYER_WIDTH
	jp	CHECK_H_TILES
; -----------------------------------------------------------------------------

; EOF