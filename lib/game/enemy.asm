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
	BIT_ENEMY_LETHAL:	equ 0 ; Kills the player on collision
	
; Enemy flags (as flags)
	FLAG_ENEMY_LETHAL:	equ (1 << BIT_ENEMY_LETHAL) ; $01
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Symbolic constants for enemy states.

; Any enemy state handler routine:
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret z: the enemy update process has finished for the current frame.
; ret nz: the enemy update process for the current frame
;	continues with the next state handler;
;	the handler for the next state handler is returned by the state handler.
	ENEMY_STATE.HANDLER_L:	equ 0 ; State handler address (low)
	ENEMY_STATE.HANDLER_H:	equ 1 ; State handler address (high)
	ENEMY_STATE.ARG_0:	equ 2 ; State handler arguments
	ENEMY_STATE.ARG_1:	equ 3 ; State handler arguments
	ENEMY_STATE.ARG_2:	equ 4 ; State handler arguments
	ENEMY_STATE.ARG_3:	equ 5 ; State handler arguments
	ENEMY_STATE.ARG_4:	equ 6 ; State handler arguments
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
	push	hl ; preserves source data
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
	ld	b, h ; preserves target start in bc
	ld	c, l
; Stores the logical coordinates
	ld	[hl], e ; .y
	inc	hl
	ld	[hl], d ; .x
	inc	hl
; Stores the pattern, color and initial handler
	ex	de, hl ; current target in de
	pop	hl ; restores source data in hl
	push	bc ; preserves target start
	ld	bc, 5
	ldir	; .pattern, .color, .flags, .state
; Resets the animation delay and the frame counter
	xor	a
	ld	[de], a ; .animation_delay
	inc	de
	ld	[de], a ; .frame_counter
	inc	de
	ld	[de], a ; .trigger_frame_counter
	inc	de
	ld	[de], a ; .dy_index
; Saves the data for respawning
	pop	hl ; restores target start in hl
	inc	de ; .respawn_data
	ld	bc, enemy.RESPAWN_SIZE
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the enemies
UPDATE_ENEMIES:
; For each enemy in the array
	ld	ix, enemies
	ld	b, CFG_ENEMY_COUNT
.LOOP:
	push	bc ; preserves counter in b
; Is the enemy slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + enemy.y]
	jp	z, .NEXT ; yes
; no: update enemy

IFEXIST BIT_ENEMY_SOLID
; Reads the tile flags at the enemy coordinates
	call	GET_ENEMY_TILE_FLAGS

; Is the tile solid?
	bit	BIT_WORLD_SOLID, a
	jr	z, .NOT_SOLID ; no
; yes: Is the enemy solid? (the enemy has been crushed)
	bit	BIT_ENEMY_SOLID, [ix + enemy.flags]
	jr	nz, .KILL_ENEMY ; yes
; no
.NOT_SOLID:

; Has the tile the death bit?
	bit	BIT_WORLD_DEATH, a
	jr	z, .NOT_KILLED ; no
; Can the enemy be killed by death tiles?
	bit	BIT_ENEMY_DEATH, [ix + enemy.flags]
	jr	z, .NOT_KILLED ; no
; yes
	
.KILL_ENEMY:
; Makes the enemy non-lethal and non-solid
	ld	a, $ff AND NOT (FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH)
	and	[ix + enemy.flags]
	ld	[ix + enemy.flags], a
; Sets the enemy the behaviour when killed
	ld	hl, ENEMY_TYPE_KILLED
	call	SET_NEW_STATE_HANDLER.HL_OK
	
.NOT_KILLED:
ENDIF ; IFEXIST BIT_WORLD_SOLID

; Processes the state handlers of the current enemy
	call	PROCESS_ENEMY_HANDLERS

; Continues with the next enemy
.NEXT:
	ld	bc, enemy.SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Processes the state handlers of the current enemy
; param ix: pointer to the current enemy
PROCESS_ENEMY_HANDLERS:
; Dereferences the state pointer
	ld	l, [ix + enemy.state_l]
	ld	h, [ix + enemy.state_h]
	push	hl ; iy = hl
	pop	iy
.LOOP:
; Invokes the current state handler
	ld	l, [iy + ENEMY_STATE.HANDLER_L]
	ld	h, [iy + ENEMY_STATE.HANDLER_H]
	call	JP_HL ; emulates "call [hl]"
; Has the handler finished?
	or	a
	ret	z ; yes: the enemy update process has finished
; no: Continues with the next state handler
	ld	c, a ; ld bc, a
	rla
	sbc	a, a
	ld	b, a
	add	iy, bc ; iy += bc
	jr	.LOOP
; -----------------------------------------------------------------------------


;
; =============================================================================
;	Convenience enemy state handlers (generic)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Finish state handler (to be used in comparisons only; inline otherwise)
; param ix: pointer to the current enemy (ignored)
; param iy: pointer to the current enemy state (ignored)
; ret a: always halt (0)
END_ENEMY_HANDLER:	equ	RET_ZERO
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Continue state handler (to be used in comparisons only; inline otherwise)
; param ix: pointer to the current enemy (ignored)
; param iy: pointer to the current enemy state (ignored)
; ret a: always continue (2, 3, etc.)
CONTINUE_ENEMY_HANDLER:
.NO_ARGS:
	ld	a, 2
	ret
.ONE_ARG:
	ld	a, 3
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
GOSUB_ENEMY_HANDLER:
	ld	b, b
	jr	$ + 2
	
	push	iy ; preserves the current enemy state
; no: Continues with the next state handler
	ld	c, [iy + ENEMY_STATE.ARG_0]
	ld	b, [iy + ENEMY_STATE.ARG_1]
	push	bc
	pop	iy
	; add	iy, bc ; iy += bc
	call	PROCESS_ENEMY_HANDLERS.LOOP
	pop	iy ; restores the current enemy state
; ret continue (3)
	ld	a, 4
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sets a new current state for the current enemy
; (this state handler is usually the last handler of a state)
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARG_0]: address of the next state (word)
; ret z (halt)
SET_NEW_STATE_HANDLER:
; Reads the address of the next state in hl
	ld	l, [iy + ENEMY_STATE.ARG_0]
	ld	h, [iy + ENEMY_STATE.ARG_1]
	jr	.HL_OK
	
; Sets the next state as the new state
.NEXT:
	push	iy
	pop	hl
	inc	hl
	inc	hl
	; jr	.HL_OK ; falls through
	
; Sets an specific address of the next state
.HL_OK:
; Sets the new state as the enemy state
	ld	[ix + enemy.state_l], l
	ld	[ix + enemy.state_h], h
; Resets the animation flag
	res	BIT_ENEMY_PATTERN_ANIM, [ix + enemy.pattern]
.RESET_FRAME_COUNTERS:
; Resets the animation delay and the frame counter
	xor	a
	ld	[ix + enemy.animation_delay], a
	ld	[ix + enemy.frame_counter], a
	ld	[ix + enemy.trigger_frame_counter], a
	ld	[ix + enemy.dy_index], a
; ret z (halt)
	ret
	
; Sets the new state as the new state (and the respawning state)
.AND_SAVE_RESPAWN:
; Sets the new state
	call	SET_NEW_STATE_HANDLER
	; jr	.SAVE_RESPAWN ; falls through

; Saves the current data as the respawning data
.SAVE_RESPAWN:
	push	ix ; hl = ix
	pop	hl
	ld	d, h ; de = hl
	ld	e, l
	ld	a, enemy.respawn_data ; hl += .respawn_data
	call	ADD_HL_A
	ex	de, hl
	ld	bc, enemy.RESPAWN_SIZE 
	ldir
; ret z (halt)
	xor	a
	ret

; Sets the next state as the new state (and the respawning state)
.NEXT_AND_SAVE_RESPAWN:
	call	.NEXT
	jr	.SAVE_RESPAWN
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Kill state handler: kills the enemy
KILL_ENEMY_HANDLER:
; Makes the enemy non-lethal
	res	BIT_ENEMY_LETHAL, [ix + enemy.flags]
; ret 2 (continue with next state handler)
	ld	a, 2
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Respawning initialization state handler: prepares for the respawning animation
INIT_RESPAWN_ENEMY_HANDLER:
; Restores the coordinates from the respawning data
	ld	c, [ix + enemy.respawn_data + enemy.y]
	ld	b, [ix + enemy.respawn_data + enemy.x]
	ld	a, CFG_ENEMY_RESPAWN_PATTERN
	ld	[ix + enemy.y], c
	ld	[ix + enemy.x], b
	ld	[ix + enemy.pattern], a
; ret 2 (continue with next state handler)
	ld	a, 2
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Respawn state handler: restores the respawning data as the current data
RESPAWN_ENEMY_HANDLER:
; Restores the respawning data as the current data
	push	ix ; hl = ix
	pop	hl
	ld	d, h ; de = hl
	ld	e, l
	ld	a, enemy.respawn_data ; hl += .respawn_data
	call	ADD_HL_A
	ld	bc, enemy.RESPAWN_SIZE 
	ldir
; Resets the animation delay and the frame counter and ret halt (0)
	jr	SET_NEW_STATE_HANDLER.RESET_FRAME_COUNTERS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates animation counter and toggles the animation flag,
; then puts the enemy sprite
; This function can be used as an enemy state handler
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret nz (continue)
; ret a: 2 (continue with next state handler)
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
; This function can be used as an enemy state handler
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret nz (continue)
; ret a: 2 (continue with next state handler)
PUT_ENEMY_SPRITE:
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	ld	c, [ix + enemy.pattern]
	ld	b, [ix + enemy.color]
	call	PUT_SPRITE
; ret 2 (continue with next state handler)
	ld	a, 2
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Puts the enemy sprite using an specific pattern
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARG_0]: the specific pattern
; ret a: 3 (continue with next state handler)
PUT_ENEMY_SPRITE_PATTERN:
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	ld	c, [iy + ENEMY_STATE.ARG_0]
	ld	b, [ix + enemy.color]
	call	PUT_SPRITE
; ret 3 (continue with next state handler)
	ld	a, 3
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Toggles the left flag of the enemy
; This function can be used as an enemy state handler
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret a: 2 (continue with next state handler)
TURN_ENEMY:
; Toggles the left flag
	ld	a, FLAG_ENEMY_PATTERN_LEFT
	xor	[ix + enemy.pattern]
	ld	[ix + enemy.pattern], a
; ret 2 (continue with next state handler)
	ld	a, 2
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Turns the enemy towards the player
; This function can be used as an enemy state handler
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
; This function can be used as an enemy state handler
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret z (continue)
.LEFT:
	set	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
; ret 2 (continue with next state handler)
	ld	a, 2
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Turns the enemy right
; This function can be used as an enemy state handler
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret z (continue)
.RIGHT:
	res	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
; ret 2 (continue with next state handler)
	ld	a, 2
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: wait a number of frames
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARG_0]: number of frames
; ret a: continue (3) if the wait has finished, halt (0) otherwise
WAIT_ENEMY_HANDLER:
; increases frame counter and compares with argument
	ld	a, [ix + enemy.frame_counter]
	inc	[ix + enemy.frame_counter]
	cp	[iy + ENEMY_STATE.ARG_0]
; ret 3/0
	jp	z, CONTINUE_ENEMY_HANDLER.ONE_ARG
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: wait a number of frames, turning around
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy+ENEMY_STATE.ARG_0]: ttffffff:
; - f the frames to wait before each turn
; - t the times to turn minus 1 (0 = 1 time, 1 = 2 times, etc.)
; ret a: continue (3) if the wait has finished, halt (0) otherwise
.TURNING:
; compares frame counter with frames
	ld	a, [ix + enemy.frame_counter]
	ld	b, a ; preserves frame counter in b
	xor	[iy + ENEMY_STATE.ARG_0]
	and	$3f ; masks the ffffff part
	jr	z, .DO_TURN
; increases frame counter
	inc	[ix + enemy.frame_counter]
; ret 0 (halt)
	xor	a
	ret
	
.DO_TURN:
	call	TURN_ENEMY
; compares frame counter with times
	ld	a, b ; restores frame counter in b
	cp	[iy + ENEMY_STATE.ARG_0]
	jp	z, CONTINUE_ENEMY_HANDLER.ONE_ARG
; resets frame part of frame counter and increases times counter
	and	$c0
	add	$40
	ld	[ix + enemy.frame_counter], a
; ret 0 (halt)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is ahead of the enemy
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret a: continue (2) if the player is ahead of the enemy, halt (0) otherwise
.PLAYER_AHEAD:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
	jr	z, .PLAYER_RIGHT
	; jr	.PLAYER_LEFT ; falls through
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is left of the enemy
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret a: continue (2) if the player is left of the enemy, halt (0) otherwise
.PLAYER_LEFT:
; Is the player to the left?
	ld	a, [player.x]
	cp	[ix + enemy.x]
	jp	c, CONTINUE_ENEMY_HANDLER.NO_ARGS ; yes: continue (ret 2)
; no: halt (ret 0)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is right of the enemy
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret a: continue (2) if the player is right of the enemy, halt (0) otherwise
.PLAYER_RIGHT:
; Is the player to the right?
	ld	a, [player.x]
	cp	[ix + enemy.x]
	jp	nc, CONTINUE_ENEMY_HANDLER.NO_ARGS ; yes: continue (ret 2)
; no: halt (ret 0)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is above the enemy
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret a: continue (2) if the player is above the enemy, halt (0) otherwise
.PLAYER_ABOVE:
; Is the player above?
	ld	a, [player.y]
	cp	[ix + enemy.y]
	jp	c, CONTINUE_ENEMY_HANDLER.NO_ARGS ; yes: continue (ret 2)
; no: halt (ret 0)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is below the enemy
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret a: continue (2) if the player is below the enemy, halt (0) otherwise
.PLAYER_BELOW:
; Is the player below?
	ld	a, [player.y]
	cp	[ix + enemy.y]
	jp	nc, CONTINUE_ENEMY_HANDLER.NO_ARGS ; yes: continue (ret 2)
; no: halt (ret 0)
	xor	a
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Wait X collision state handler:
; waits until the player and the enemy are in overlapping x coordinates
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy+ENEMY_STATE.ARG_0]: horizontal maximum distance (usually, PLAYER_ENEMY_X_SIZE)
; ret a: continue (3) if the x coordinates are overlapping, halt (0) otherwise
.X_COLLISION:
	ld	l, [iy + ENEMY_STATE.ARG_0]
	call	CHECK_PLAYER_COLLISION.X
	jp	c, CONTINUE_ENEMY_HANDLER.ONE_ARG ; ret 3 (continue)
; ret 0 (halt)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait Y collision state handler:
; waits until the player and the enemy are in overlapping y coordinates
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy+ENEMY_STATE.ARG_0]: vertical maximum distance (usually, PLAYER_ENEMY_Y_SIZE)
; ret a: continue (3) if the y coordinates are overlapping, halt (0) otherwise
.Y_COLLISION:
	ld	h, [iy + ENEMY_STATE.ARG_0]
	call	CHECK_PLAYER_COLLISION.Y
	jp	c, CONTINUE_ENEMY_HANDLER.ONE_ARG ; ret 3 (continue)
; ret 0 (halt)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Trigger state handler: pauses until the enemy can shoot again
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret a: continue (2) if the wait has finished, halt (0) otherwise
TRIGGER_ENEMY_HANDLER:
; Has the pause finished?
	ld	a, [ix + enemy.trigger_frame_counter]
	or	a
	jp	z, CONTINUE_ENEMY_HANDLER.NO_ARGS ; yes
; no
	dec	[ix + enemy.trigger_frame_counter]
; ret 0 (halt)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Trigger state handler reset: restarts the trigger frame counter
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; param [iy + ENEMY_STATE.ARG_0]: number of frames to wait between shoots
; ret a: continue (3)
.RESET:
; resets trigger frame counter
	ld	a, [iy + ENEMY_STATE.ARG_0]
	ld	[ix + enemy.trigger_frame_counter], a
; ret 3 (continue with next state handler)
	ld	a, 3
	ret
; -----------------------------------------------------------------------------
	
;
; =============================================================================
;	Enemy-tile helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Reads the tile flags at the enemy coordinates
; (one pixel above the enemy logical coordinates)
; param ix: pointer to the current enemy
; ret a: tile flags
GET_ENEMY_TILE_FLAGS:
; Enemy coordinates
	ld	a, [ix + enemy.y]
	dec	a
	ld	e, a
	ld	d, [ix + enemy.x]
; Reads the tile index and then the tile flags
	call	GET_TILE_VALUE
	jp	GET_TILE_FLAGS
; -----------------------------------------------------------------------------

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

; EOF
