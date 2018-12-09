;
; =============================================================================
;	Enemies related routines (generic)
;	Convenience enemy state handlers (generic)
;	Enemy-tile helper routines
; =============================================================================
;

	CFG_RAM_ENEMY:	equ 1

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
; ret ix: pointer to the new initialized enemy
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
; Prepares ret ix: pointer to the new enemy
	push	hl
	pop	ix
	
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

IFEXIST CFG_ENEMY_DYING_PATTERN
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
	call	KILL_ENEMY
	
.NOT_KILLED:
ENDIF ; IFEXIST BIT_WORLD_SOLID
ENDIF ; IFEXIST CFG_ENEMY_DYING_PATTERN

; Dereferences the state pointer of the current enemy
	ld	l, [ix + enemy.state_l]
	ld	h, [ix + enemy.state_h]
; Invokes the current state handler
	call	JP_HL

; Continues with the next enemy
.NEXT:
	ld	bc, enemy.SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------


;
; =============================================================================
;	Convenience enemy state handlers (generic)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Sets the next state as the new state
; param ix: pointer to the current enemy
; param [sp]: address of the next state (word)
; (invoke with call SET_ENEMY_STATE.NEXT)
SET_ENEMY_STATE.NEXT:
	pop	hl
	; jr	.HL_OK ; falls through
	
; Sets an specific address of the next state as the new state
; param ix: pointer to the current enemy
; param hl: address of the next state (word)
SET_ENEMY_STATE:
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
	; ld	[ix + enemy.trigger_frame_counter], a
	ld	[ix + enemy.dy_index], a
	ret
	
; Sets the new state as the new state (and the respawning state)
; param ix: pointer to the current enemy
; param hl: address of the next state (word)
.AND_SAVE_RESPAWN:
; Sets the new state
	call	SET_ENEMY_STATE
	; jr	.SAVE_RESPAWN ; falls through

; Saves the current data as the respawning data
; param ix: pointer to the current enemy
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
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates animation counter and toggles the animation flag,
; then puts the enemy sprite
; param ix: pointer to the current enemy
PUT_ENEMY_SPRITE_ANIMATE:
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
PUT_ENEMY_SPRITE:
	ld	c, [ix + enemy.pattern]
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Puts the enemy sprite using an specific pattern
; param ix: pointer to the current enemy
; param c: the specific pattern
PUT_ENEMY_SPRITE_PATTERN:
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	ld	b, [ix + enemy.color]
	jp	PUT_SPRITE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Puts the enemy sprite with the animation flag on
; param ix: pointer to the current enemy
PUT_ENEMY_SPRITE_ANIM:
	ld	a, [ix + enemy.pattern]
.A_OK:
	or	FLAG_ENEMY_PATTERN_ANIM
	ld	c, a
	jr	PUT_ENEMY_SPRITE_PATTERN
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Toggles the left flag of the enemy
; param ix: pointer to the current enemy
TURN_ENEMY:
; Toggles the left flag
	ld	a, FLAG_ENEMY_PATTERN_LEFT
	xor	[ix + enemy.pattern]
	ld	[ix + enemy.pattern], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Toggles the left flag of both the current enemy and the respawning data
; (usually used to allow enemies that start looking in the opposite direction)
; param ix: pointer to the current enemy
.RESPAWN_AWARE:
; Toggles the left flag
	call	TURN_ENEMY
; Toggles the left flag in the respawning data
	ld	[ix + enemy.respawn_data + enemy.pattern], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Turns the enemy towards the player
; This function can be used as an enemy state handler
; param ix: pointer to the current enemy
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
.LEFT:
	set	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Turns the enemy right
; This function can be used as an enemy state handler
; param ix: pointer to the current enemy
.RIGHT:
	res	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: wait a number of frames
; param ix: pointer to the current enemy
; param b: number of frames
; ret z/nz: z if the wait has finished, nz otherwise
WAIT_ENEMY_HANDLER:
; increases frame counter and compares with argument
	ld	a, [ix + enemy.frame_counter]
	inc	[ix + enemy.frame_counter]
; ret z/nz
	cp	b
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: wait a number of frames, turning around
; param ix: pointer to the current enemy
; param b: ttffffff:
; - f the frames to wait before each turn
; - t the times to turn minus 1 (0 = 1 time, 1 = 2 times, etc.)
; ret z/nz: z if the wait has finished, nz otherwise
.TURNING:
; compares frame counter with frames
	ld	a, [ix + enemy.frame_counter]
	ld	c, a ; preserves frame counter in c
	xor	b
	and	$3f ; masks the ffffff part
	jr	z, .DO_TURN
; increases frame counter
	inc	[ix + enemy.frame_counter]
	ret	; nz
	
.DO_TURN:
	call	TURN_ENEMY
; compares frame counter with times
	ld	a, c ; restores frame counter in a
	cp	b
	ret	z
; resets frame part of frame counter and increases times counter
	and	$c0
	add	$40
	ld	[ix + enemy.frame_counter], a
	ret	; nz
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is ahead of the enemy
; param ix: pointer to the current enemy
; ret z/nz: z if the wait has finished (the player is ahead), nz otherwise
.PLAYER_AHEAD:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
	jr	z, .PLAYER_RIGHT
	; jr	.PLAYER_LEFT ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is left of the enemy
; param ix: pointer to the current enemy
; ret z/nz: z if the wait has finished (the player is left), nz otherwise
.PLAYER_LEFT:
; Is the player to the left?
	ld	a, [player.x]
	cp	[ix + enemy.x]
	jp	nc, RET_NOT_ZERO ; no (ret nz)
	jr	.PLAYER_AT_Y
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is right of the enemy
; param ix: pointer to the current enemy
; ret z/nz: z if the wait has finished (the player is right), nz otherwise
.PLAYER_RIGHT:
; Is the player to the right?
	ld	a, [player.x]
	cp	[ix + enemy.x]
	ret	c ; no (ret nz)
	; jr	.PLAYER_AT_Y ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is overlapping y coordinates
; param ix: pointer to the current enemy
; param h: vertical maximum distance
; ret z/nz: z if the wait has finished (the player is overlapping), nz otherwise
.PLAYER_AT_Y:
; Is the player overlapping y coordinates?
	ld	c, PLAYER_ENEMY_Y_OFFSET
	call	CHECK_PLAYER_COLLISION.Y
	jp	nc, RET_NOT_ZERO ; no
; ret z
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is above the enemy
; param ix: pointer to the current enemy
; ret z/nz: z if the wait has finished (the player is above), nz otherwise
.PLAYER_ABOVE_DEFAULT:
; Default horizontal maximum distance
	ld	l, PLAYER_ENEMY_X_SIZE + CFG_ENEMY_ADVANCE_COLLISION * 2
	; jr	.PLAYER_ABOVE ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is above the enemy
; param ix: pointer to the current enemy
; param l: horizontal maximum distance
; ret z/nz: z if the wait has finished (the player is above), nz otherwise
.PLAYER_ABOVE:
; Is the player above?
	ld	a, [player.y]
	cp	[ix + enemy.y]
	jp	nc, RET_NOT_ZERO ; no (ret nz)
	jr	.PLAYER_AT_X
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is below the enemy
; param ix: pointer to the current enemy
; ret z/nz: z if the wait has finished (the player is below), nz otherwise
.PLAYER_BELOW_DEFAULT:
; Default horizontal maximum distance
	ld	l, PLAYER_ENEMY_X_SIZE + CFG_ENEMY_ADVANCE_COLLISION * 2
	; jr	.PLAYER_BELOW : falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is below the enemy
; param ix: pointer to the current enemy
; param l: horizontal maximum distance
; ret z/nz: z if the wait has finished (the player is below), nz otherwise
.PLAYER_BELOW:
; Is the player below?
	ld	a, [player.y]
	dec	a ; (avoids false positive due player.y == enemy.y)
	cp	[ix + enemy.y]
	ret	c ; no (ret nz)
	; jr	.PLAYER_X : falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is overlapping x coordinates
; param ix: pointer to the current enemy
; param l: horizontal maximum distance
; ret z/nz: z if the wait has finished (the player is overlapping), nz otherwise
.PLAYER_AT_X:
; Is the player overlapping x coordinates?
	call	CHECK_PLAYER_COLLISION.X
	jp	nc, RET_NOT_ZERO ; no
; ret z
	xor	a
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Trigger state handler: pauses until the enemy can shoot again
; param ix: pointer to the current enemy
; ret z/nz: z if the wait has finished (the enemy can shoot again), nz otherwise
; ret a: continue (2) if the wait has finished, halt (0) otherwise
TRIGGER_ENEMY_HANDLER:
; Has the pause finished?
	ld	a, [ix + enemy.trigger_frame_counter]
	or	a
	ret	z ; yes
; no
	dec	[ix + enemy.trigger_frame_counter]
	ret	; (ret nz)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Trigger state handler reset: restarts the trigger frame counter
; param ix: pointer to the current enemy
; param a: number of frames to wait between shoots
.RESET:
; resets trigger frame counter
	ld	[ix + enemy.trigger_frame_counter], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
REMOVE_ENEMY:
	xor	a ; (marker value: y = 0)
	ld	[ix + enemy.y], a
	ret
; -----------------------------------------------------------------------------

IFEXIST CFG_ENEMY_DYING_PATTERN
; -----------------------------------------------------------------------------
; Kills the enemy
; param ix: pointer to the current enemy
KILL_ENEMY:
IFEXIST CFG_SOUND_ENEMY_KILLED
	ld	a, CFG_SOUND_ENEMY_KILLED
	ld	c, 8
	call	ayFX_INIT
ENDIF
; Makes the enemy non-lethal and non-solid
	ld	a, $ff AND NOT (FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH)
	and	[ix + enemy.flags]
	ld	[ix + enemy.flags], a
; Sets the enemy the behaviour when killed
	ld	hl, ENEMY_TYPE_KILLED
	jp	SET_ENEMY_STATE
; -----------------------------------------------------------------------------
ENDIF ; IFEXIST CFG_ENEMY_DYING_PATTERN

	
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
; Reads the tile flags
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


;
; =============================================================================
;	Default enemy types (generic)
; =============================================================================
;

IFEXIST CFG_ENEMY_DYING_PATTERN
; -----------------------------------------------------------------------------
; Killed: the enemy has been killed. Shows the dying animation
; and respawns the enemy after a pause
ENEMY_TYPE_KILLED:
; Shows the dying pattern
	ld	c, CFG_ENEMY_DYING_PATTERN
	call	PUT_ENEMY_SPRITE_PATTERN
	ld	b, CFG_ENEMY_PAUSE_S ; short pause
	call	WAIT_ENEMY_HANDLER
	ret	nz ; (end)
; Then
	call	SET_ENEMY_STATE.NEXT
; Pause
	ld	b, CFG_ENEMY_PAUSE_L ; long wait
	call	WAIT_ENEMY_HANDLER
	ret	nz ; (end)
; (restores the coordinates from the respawning data)
	ld	c, [ix + enemy.respawn_data + enemy.y]
	ld	b, [ix + enemy.respawn_data + enemy.x]
	ld	a, CFG_ENEMY_RESPAWN_PATTERN
	ld	[ix + enemy.y], c
	ld	[ix + enemy.x], b
	ld	[ix + enemy.pattern], a
; Then
	call	SET_ENEMY_STATE.NEXT
; Shows the respawning animation
	call	PUT_ENEMY_SPRITE_ANIMATE
	ld	b, CFG_ENEMY_PAUSE_L ; long wait
	call	WAIT_ENEMY_HANDLER
	ret	nz ; (end)
; Then respawns the enemy
; (restores the respawning data as the current data)
	push	ix ; hl = ix
	pop	hl
	ld	d, h ; de = hl
	ld	e, l
	ld	a, enemy.respawn_data ; hl += .respawn_data
	call	ADD_HL_A
	ld	bc, enemy.RESPAWN_SIZE 
	ldir
; Resets the animation delay and the frame counter for the next frame
	jp	SET_ENEMY_STATE.RESET_FRAME_COUNTERS
; -----------------------------------------------------------------------------
ENDIF ; IFEXIST CFG_ENEMY_DYING_PATTERN

; EOF
