;
; =============================================================================
;	Default player control routines (platformer game)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bit index for the default tile properties
	BIT_WORLD_SOLID:	equ 0
	BIT_WORLD_FLOOR:	equ 1
	BIT_WORLD_STAIRS:	equ 2
	BIT_WORLD_DEATH:	equ 3
	BIT_WORLD_WALK_ON:	equ 4 ; Tile collision (single char)
	BIT_WORLD_WIDE_ON:	equ 5 ; Wide tile collision (player width)
	BIT_WORLD_WALK_OVER:	equ 6 ; Walking over tiles (player width)
	BIT_WORLD_PUSHABLE:	equ 7 ; Pushable tiles (player height)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Default player states
	PLAYER_STATE_FLOOR:	equ (0 << 2) ; $00
	PLAYER_STATE_STAIRS:	equ (1 << 2) ; $04
	PLAYER_STATE_AIR:	equ (2 << 2) ; $08
	PLAYER_STATE_DYING:	equ (3 << 2) ; $0c
	PLAYER_STATE_DEAD:	equ (0 << 2) + (1 << BIT_STATE_FINISH) ; $80
	PLAYER_STATE_FINISH:	equ (1 << 2) + (1 << BIT_STATE_FINISH) ; $84
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Main player control routine
UPDATE_PLAYER:
; Invokes PLAYER_UPDATE_TABLE[player.state] routine
	ld	a, [player.state] ; a = player.state without flags
	srl	a
	srl	a
	ld	hl, UPDATE_PLAYER_TABLE
	call	JP_TABLE
	
; Finished?
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	ret	nz ; yes

; Reads the tile flags at the player coordinates
	call	GET_PLAYER_TILE_FLAGS
; Has death bit?
	bit	BIT_WORLD_DEATH, a
	jp	nz, SET_PLAYER_DYING ; yes
; Has tile collision (single char) bit?
IFEXIST ON_PLAYER_WALK_ON
	bit	BIT_WORLD_WALK_ON, a
	call	nz, ON_PLAYER_WALK_ON ; yes
ENDIF
	
IFEXIST ON_PLAYER_WIDE_ON
; Returns the OR-ed flags of the tiles at the player coordinates
	call	GET_PLAYER_TILE_FLAGS_WIDE
; Has wide tile collision (player width) bit?
	bit	BIT_WORLD_WIDE_ON, a
	call	nz, ON_PLAYER_WIDE_ON ; yes
ENDIF
	
IFEXIST ON_PLAYER_WALK_OVER
; Returns the OR-ed flags of the tiles under the player
	call	GET_PLAYER_TILE_FLAGS_UNDER_FAST
; Has walking over tiles (player width) bit?
	bit	BIT_WORLD_WALK_OVER, a
	call	nz, ON_PLAYER_WALK_OVER ; yes
ENDIF

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Set the player on the floor
SET_PLAYER_FLOOR:
; Y adjust
	ld	a, [player.y]
	add	CFG_PLAYER_GRAVITY - 1
	and	$f8 ; (aligned to char)
	ld	[player.y], a
; Sets the player state
	ld	a, PLAYER_STATE_FLOOR
	jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Control routine when the player is on the floor
UPDATE_PLAYER_FLOOR:
; Trying to get on stairs?
	ld	hl, stick
	bit	BIT_STICK_UP, [hl]
	jr	z, .NO_UPSTAIRS ; no
; yes (upstairs)
	call	GET_PLAYER_TILE_FLAGS
	jr	.CHECK_STAIRS
	
.NO_UPSTAIRS:
	ld	hl, stick
	bit	BIT_STICK_DOWN, [hl]
	jr	z, .NO_STAIRS ; no
; yes (downstairs)
	call	GET_PLAYER_TILE_FLAGS_UNDER_FAST
	; jr	.CHECK_STAIRS ; falls through
	
.CHECK_STAIRS:
; Are there stairs? (i.e.:Stairs flags, but not solid flag)
	and	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_STAIRS)
	cp	(1 << BIT_WORLD_STAIRS)
	jr	z, SET_PLAYER_STAIRS ; yes

.NO_STAIRS:
; No: Jumping?
	ld	hl, stick_edge
	bit	BIT_STICK_UP, [hl]
	jp	nz, SET_PLAYER_JUMPING ; yes
	
; no: Moves horizontally with animation
	call	MOVE_PLAYER_LR_ANIMATE
	
; Floor under the player?
	call	GET_PLAYER_TILE_FLAGS_UNDER_FAST
	bit	BIT_WORLD_FLOOR, a
	ret	nz ; yes
; no
	jp	SET_PLAYER_FALLING
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Set the player on stairs
SET_PLAYER_STAIRS:
; Sets the player state
	ld	a, PLAYER_STATE_STAIRS
	call	SET_PLAYER_STATE
	
; Moves horizontally and vertically
	call	MOVE_PLAYER_LR
	jr	UPDATE_PLAYER_STAIRS_0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Rutina de control de jugador cuando el jugador está en unas escaleras
UPDATE_PLAYER_STAIRS:
; Gestiona el desplazamiento lateral
	call	MOVE_PLAYER_LR
; ¿Ha salido de la escalera?
	call	GET_PLAYER_TILE_FLAGS
	bit	BIT_WORLD_STAIRS, a
	jp	z, SET_PLAYER_OFF_STAIRS ; sí
	
UPDATE_PLAYER_STAIRS_0:
; no: ¿desplazamiento vertical?
	ld	hl, stick
	bit	BIT_STICK_UP, [hl]
	jr	z, .NO_UP
; sí (arriba): ¿Hay sólido?
	call	GET_PLAYER_TILE_FLAGS_OVER_FAST
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
	call	GET_PLAYER_TILE_FLAGS_UNDER_FAST
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
	call	GET_PLAYER_TILE_FLAGS_UNDER_FAST
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
	call	GET_PLAYER_TILE_FLAGS_UNDER_FAST
	bit	BIT_WORLD_FLOOR, a
	pop	bc ; restaura dy (en b para no pisar f)
	jp	nz, SET_PLAYER_FLOOR ; sí
; no
	ld	a, b ; restaura dy (en a)
	jp	MOVE_PLAYER_DY
	
.UP:
; (dy < 0): ¿Hay sólido encima del jugador?
	push	af ; preserva dy
	call	GET_PLAYER_TILE_FLAGS_OVER_FAST
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
	jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Gestiona el desplazamiento lateral en función de los cursores, sin animación
MOVE_PLAYER_LR:
; ¿Desplazamiento lateral?
	ld	hl, stick
	bit	BIT_STICK_RIGHT, [hl]
	jr	z, .NO_RIGHT
	
; sí: derecha
	call	GET_PLAYER_TILE_FLAGS_RIGHT_FAST
	bit	BIT_WORLD_SOLID, a
	ret	nz
	jp	MOVE_PLAYER_RIGHT
	
.NO_RIGHT:
	bit	BIT_STICK_LEFT, [hl]
	ret	z ; no
	
; sí: izquierda
	call	GET_PLAYER_TILE_FLAGS_LEFT_FAST
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
	jp	SET_PLAYER_STATE.MASK
; ENDIF ; (BIT_WORLD_PUSHABLE == 0)

.RIGHT:
	call	GET_PLAYER_TILE_FLAGS_RIGHT_FAST
	
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
	call	GET_PLAYER_TILE_FLAGS_LEFT_FAST

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

; EOF
