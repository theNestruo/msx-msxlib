;
; =============================================================================
;	Enemies related routines (generic)
;	Convenience enemy state handlers (generic)
;	Enemy-tile helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bounding box coordinates offset from the logical coordinates
	ENEMY_BOX_X_OFFSET:	equ -(CFG_ENEMY_WIDTH / 2)
	ENEMY_BOX_Y_OFFSET:	equ -CFG_ENEMY_HEIGHT
	
; Enemy pattern modifiers (as bit indexes)
	BIT_ENEMY_PATTERN_ANIM:	equ 2
	BIT_ENEMY_PATTERN_LEFT:	equ 3

; Enemy pattern modifiers (as flags)
	FLAG_ENEMY_PATTERN_ANIM:	equ (1 << BIT_ENEMY_PATTERN_ANIM) ; $04
	FLAG_ENEMY_PATTERN_LEFT:	equ (1 << BIT_ENEMY_PATTERN_LEFT) ; $08

; Enemy flags (as bit indexes)
	BIT_ENEMY_LETHAL:	equ 0
	
; Enemy flags (as flags)
	FLAG_ENEMY_LETHAL:	equ (1 << BIT_ENEMY_LETHAL) ; $01
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Symbolic constants for enemy states.

; Any enemy state handler routine:
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret nz: if the state handler has not finished yet.
;	The enemy update process will halt until the next frame.
; ret z: if the state handler has finished.
;	The enemy update process continues immediately with the next state.
	ENEMY_STATE.HANDLER_L:	equ 0 ; State handler address (low)
	ENEMY_STATE.HANDLER_H:	equ 1 ; State handler address (high)
	ENEMY_STATE.ARGS:	equ 2 ; State handler arguments
	ENEMY_STATE.SIZE:	equ 3
	ENEMY_STATE.NEXT:	equ ENEMY_STATE.SIZE ; (for legiblity)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Empties the enemies array
RESET_ENEMIES:
; Fills the array with zeroes
	ld	hl, enemies
	ld	de, enemies +1
	ld	bc, enemies.SIZE -1
	ld	[hl], 0
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a enemy in the first empty enemy slot
; param hl: pointer to the new enemy data (pattern, color, state pointer)
; param de: logical coordinates (x, y)
; touches: a, hl, de, bc
INIT_ENEMY:
	push	hl ; preserves source
; Search for the first empty enemy slot
	ld	hl, enemies
	ld	bc, enemy.SIZE
	xor	a ; (marker value: y = 0)
.LOOP:
	cp	[hl]
	jr	z, .INIT ; empty slot found
; Skips to the next element of the array
	add	hl, bc
	jr	.LOOP
	
.INIT:
; Stores the logical coordinates
	ld	[hl], e ; .y
	inc	hl
	ld	[hl], d ; .x
	inc	hl
; Stores the pattern, color and initial handler
	ex	de, hl ; target in de
	pop	hl ; restores source in hl
	ldi	; .pattern
	ldi	; .color
	ldi	; .flags
	ldi	; .state_l
	ldi	; .state_h
; Resets the animation delay and the frame counter
	xor	a
	ld	[de], a ; .animation_delay
	inc	de
	ld	[de], a ; .frame_counter
	inc	de
	ld	[de], a ; .trigger_frame_counter
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the enemies
UPDATE_ENEMIES:
; For each enemy in the array
	ld	ix, enemies
	ld	b, CFG_ENEMY_COUNT
.ENEMY_LOOP:
	push	bc ; preserves counter in b
; Is the enemy slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + enemy.y]
	jp	z, .SKIP_ENEMY ; yes
; no: update enemy

; Dereferences the state pointer
	ld	l, [ix + enemy.state_l]
	ld	h, [ix + enemy.state_h]
	push	hl ; iy = hl
	pop	iy
.HANDLER_LOOP:
; Invokes the current state handler
	ld	l, [iy + ENEMY_STATE.HANDLER_L]
	ld	h, [iy + ENEMY_STATE.HANDLER_H]
	call	JP_HL ; emulates "call [hl]"
; Has the handler finished?
	jp	nz, .SKIP_ENEMY ; no: pending frames
; Skips to the next state handler
	ld	bc, ENEMY_STATE.SIZE
	add	iy, bc
	jp	.HANDLER_LOOP
	
.SKIP_ENEMY:
; Skips to the next enemy
	ld	bc, enemy.SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.ENEMY_LOOP
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Convenience enemy state handlers (generic)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Sets a new current state for the current enemy, relative to the current state
; (this state handler is usually the last handler of a state)
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARGS]: offset to the next state (in bytes)
; ret nz (halt)
SET_NEW_STATE_HANDLER:
; Reads the offset to the next state in bc (16-bit signed)
	ld	a, [iy + ENEMY_STATE.ARGS]
	ld	c, a ; ld bc, a
	rla
	sbc	a, a
	ld	b, a
	
.BC_OK:
; Sets the new state as the enemy state
	push	iy ; hl = iy + bc
	pop	hl
	add	hl, bc
	ld	[ix + enemy.state_h], h
	ld	[ix + enemy.state_l], l
; Resets the animation flag
	res	BIT_ENEMY_PATTERN_ANIM, [ix + enemy.pattern]
; Resets the animation delay and the frame counter
	xor	a
	ld	[ix + enemy.animation_delay], a
	ld	[ix + enemy.frame_counter], a
; ret nz (halt)
	dec	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sets a new current state for the current enemy,
; relative to the current state,
; when the player and the enemy are in overlapping x coordinates
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARGS]: offset to the next state (in bytes)
; ret z (continue) if the state does not change (no overlapping coordinates)
; ret nz (halt) if the state changes
.ON_X_COLLISION:
	ld	l, PLAYER_ENEMY_X_SIZE
	call	CHECK_PLAYER_COLLISION.X
	jp	c, SET_NEW_STATE_HANDLER
; ret z (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sets a new current state for the current enemy,
; relative to the current state,
; when the player and the enemy are in overlapping y coordinates
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARGS]: offset to the next state (in bytes)
; ret z (continue) if the state does not change (no overlapping coordinates)
; ret nz (halt) if the state changes
.ON_Y_COLLISION:
	ld	h, PLAYER_ENEMY_Y_SIZE
	call	CHECK_PLAYER_COLLISION.Y
	jp	c, SET_NEW_STATE_HANDLER
; ret z (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates animation counter and toggles the animation flag,
; then puts the enemy sprite
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret z (continue)
PUT_ENEMY_SPRITE_ANIM:
; Updates animation counter
	ld	a, [ix + enemy.animation_delay]
	inc	a
	cp	CFG_ENEMY_ANIMATION_DELAY
	jr	nz, .DONT_ANIMATE
; Toggles the animation flag
	ld	a, FLAG_ENEMY_PATTERN_ANIM
	xor	[ix + enemy.pattern]
	ld	[ix + enemy.pattern], a
; Resets animation counter
	xor	a
.DONT_ANIMATE:
	ld	[ix + enemy.animation_delay], a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Puts the enemy sprite
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret z (continue)
PUT_ENEMY_SPRITE:
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	ld	c, [ix + enemy.pattern]
	ld	b, [ix + enemy.color]
	call	PUT_SPRITE
; ret z (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Puts the enemy sprite using an specific pattern
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret z (continue)
PUT_ENEMY_SPRITE_PATTERN:
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	ld	c, [iy + ENEMY_STATE.ARGS]
	ld	b, [ix + enemy.color]
	call	PUT_SPRITE
; ret z (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Toggles the left flag of the enemy
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret z (continue)
TURN_ENEMY:
; Toggles the left flag
	ld	a, FLAG_ENEMY_PATTERN_LEFT
	xor	[ix + enemy.pattern]
	ld	[ix + enemy.pattern], a
; ret z (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Turns the enemy towards the player
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret z (continue)
.TOWARDS_PLAYER:
	ld	a, [player.x]
	cp	[ix + enemy.x]
	jr	nc, .RIGHT
	; jp	.LEFT ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Turns the enemy left
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret z (continue)
.LEFT:
	set	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
; ret z (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Turns the enemy right
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret z (continue)
.RIGHT:
	res	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
; ret z (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Enemy-tile helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the left of the enemy
; when aligned to the tile boundary
; param ix: pointer to the current enemy
; ret a: OR-ed tile flags
GET_ENEMY_TILE_FLAGS_LEFT_FAST:
; Aligned to tile boundary?
	ld	a, [ix + enemy.x]
	add	ENEMY_BOX_X_OFFSET
	and	$07
	jp	nz, GET_NO_ENEMY_TILE_FLAGS ; no: return no flags
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the left of the enemy
; param ix: pointer to the current enemy
; ret a: OR-ed tile flags
GET_ENEMY_TILE_FLAGS_LEFT:
	ld	a, ENEMY_BOX_X_OFFSET -1
	jr	GET_ENEMY_V_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the right of the enemy
; when aligned to the tile boundary
; param ix: pointer to the current enemy
; ret a: OR-ed tile flags
GET_ENEMY_TILE_FLAGS_RIGHT_FAST:
; Aligned to tile boundary?
	ld	a, [ix + enemy.x]
	add	ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
	and	$07
	jp	nz, GET_NO_ENEMY_TILE_FLAGS ; no: return no flags
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the right of the enemy
; param ix: pointer to the current enemy
; ret a: OR-ed tile flags
GET_ENEMY_TILE_FLAGS_RIGHT:
	ld	a, ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
	; jr	GET_ENEMY_V_TILE_FLAGS ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of a vertical serie of tiles
; relative to the enemy position
; param ix: pointer to the current enemy
; param a: x-offset from the enemy logical coordinates
; ret a: OR-ed tile flags
; touches: hl, bc, de
GET_ENEMY_V_TILE_FLAGS:
; Enemy coordinates
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
; x += dx
	add	d
	ld	d, a
; y += ENEMY_BOX_Y_OFFSET
	ld	a, ENEMY_BOX_Y_OFFSET
	add	e
	ld	e, a
; Enemy height
	ld	b, CFG_ENEMY_HEIGHT
	jp	GET_V_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience routine to read no flags
; (used in GET_ENEMY_TILE_FLAGS_*_FAST)
	GET_NO_ENEMY_TILE_FLAGS:	equ RET_ZERO
; -----------------------------------------------------------------------------

; EOF
