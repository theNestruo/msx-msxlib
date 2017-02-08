
;
; =============================================================================
;	Generic handler routines for enemies
; =============================================================================
;

; -----------------------------------------------------------------------------
; Updates animation delay and switches the animation flag if necessary,
; then puts the enemy sprite
; param ix: pointer to the enemy
; ret z: this handler always continues with the next handler
EH_PUT_SPRITE_ANIM:
; checks animation delay
	ld	a, [ix + _ENEMY_ANIMATION_DELAY]
	inc	a
	cp	CFG_ENEMY_ANIMATION_DELAY
	jr	nz, .DONT_ANIMATE ; not yet
; switches the animation flag
	ld	a, FLAG_ENEMY_PATTERN_ANIM
	xor	[ix + _ENEMY_PATTERN]
	ld	[ix + _ENEMY_PATTERN], a
; resets the animation delay
	xor	a
.DONT_ANIMATE:
	ld	[ix + _ENEMY_ANIMATION_DELAY], a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Puts the enemy sprite
; param ix: pointer to the enemy
; ret z: this handler always continues with the next handler
EH_PUT_SPRITE:
	ld	e, [ix + _ENEMY_X]
	ld	d, [ix + _ENEMY_Y]
	ld	c, [ix + _ENEMY_PATTERN]
	ld	b, [ix + _ENEMY_COLOR]
	call	PUT_SPRITE
; ret z (continue with next handler)
	cp	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; The enemy waits idle.
; param [iy+_STATE_ARGUMENT]: The number of frames to wait (0 = forever)
; param ix: pointer to the enemy
; param iy: pointer to this state
; ret z/nz: if the state has finished
EH_IDLE:
; Is the argument zero?
	ld	a, [iy + _STATE_ARGUMENT]
	or	a
	jr	nz, .DO_WAIT ; no: do the wait
; yes: ret nz (this handler never finishes)
	or	1
	ret
	
.DO_WAIT:
; increases frame counter and checks against the argument
	inc	[ix + _ENEMY_FRAME_COUNTER]
	; ld	a, [iy + _STATE_ARGUMENT] ; unnecessary
	cp	[ix + _ENEMY_FRAME_COUNTER]
	ret	; z/nz
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; The enemy waits idle, but turning (chaging direction)
; param [iy+_STATE_ARGUMENT]: ttffffff:
; - f the number of frames to wait before each turn
; - t the number of times to turn minus 1 (0 = 1 time, 1 = 2 times, etc.)
; param ix: pointer to the enemy
; param iy: pointer to this state
; ret z/nz: if the state has finished
EH_IDLE_TURNING:
; increases frame counter and checks against the argument
	ld	a, [ix + _ENEMY_FRAME_COUNTER]
	xor	[iy + _STATE_ARGUMENT]
	ld	b, a ; preserves comparison without mask
	and	$3f ; masks the ffffff part
	jr	z, .DO_TURN ; must turn
; no turn yet
	inc	[ix + _ENEMY_FRAME_COUNTER]
	ret	; nz
	
.DO_TURN:
	call	TURN_ENEMY
; checks iteration counter against the argument
	ld	a, b ; restores comparison (ffffff is zero)
	or	a
	ret	z ; iterations match
; increases the iteration counter
	add	$40
	ld	[ix + _ENEMY_FRAME_COUNTER], a
	ret	; nz
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
EH_TURN:
	call	TURN_ENEMY
; ret z (continue with next handler)
	cp	a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Handler routines for enemies (platform games)
; =============================================================================
;

; -----------------------------------------------------------------------------
EH_TURN_WALKING_ENEMY_TOWARDS_PLAYER:
	call	TURN_WALKING_ENEMY_TOWARDS_PLAYER
; ret z (continue with next handler)
	cp	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
EH_WALK:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + _ENEMY_PATTERN]
	jr	z, EH_WALK_RIGHT
	; jr	EH_WALK_LEFT ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
EH_WALK_LEFT:
	call	CAN_ENEMY_WALK_LEFT
	ret	z ; no
	dec	[ix + _ENEMY_X]
; ret nz
	; or	1 ; unecessary? (TODO check dec[ix] flag affection)
	; ret
	jp	EH_IDLE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
EH_WALK_RIGHT:
	call	CAN_ENEMY_WALK
	ret	z ; no
	inc	[ix + _ENEMY_X]
; ret nz
	; or	1 ; unecessary? (TODO check inc[ix] flag affection)
	; ret
	jp	EH_IDLE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; EH_FLY_LEFT:
; ; Can move left? Checks walls
	; call	CHECK_TILES_LEFT_ENEMY
	; cpl	; (for checking z instead of nz)
	; bit	BIT_WORLD_SOLID, a
	; ret	z ; no
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; EH_FLOAT_LEFT:
; ; Unconditionally moves left
	; dec	[ix + _ENEMY_X]
; ; ret nz
	; or	1
	; ret
; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Mueve el enemigo hacia la derecha, comprobando suelo y colisiones
; ; param ix: puntero al enemigo
; ; param _STATE_ARG: número de píxeles/frames; se decrementará (0 = infinito)
; EH_WALK_RIGHT:
; ; Can walk left? Checks floor
	; call	CHECK_TILE_UNDER_RIGHT_ENEMY
	; bit	BIT_WORLD_FLOOR, a
	; ret	z ; no
	
; EH_FLY_RIGHT:
; ; Can move right? Checks walls
	; call	CHECK_TILES_RIGHT_ENEMY
	; cpl	; (for checking z instead of nz)
	; bit	BIT_WORLD_SOLID, a
	; ret	z ; no
	
; EH_FLOAT_RIGHT:
; ; Unconditionally moves right
	; inc	[ix + _ENEMY_X]
; ; ret nz
	; or	1
	; ret
; ; -----------------------------------------------------------------------------
