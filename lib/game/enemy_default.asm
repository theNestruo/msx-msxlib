;
; =============================================================================
;	Convenience enemy state handlers (generic)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Toggles the left flag of the enemy
; param ix: pointer to the current enemy
TURN_ENEMY:
; Toggles the left flag
	ld	a, [ix + enemy.pattern]
	xor	FLAG_ENEMY_PATTERN_LEFT
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
; Translates c/nc to z/nz
; (note: a = 0 implies c because of CHECK_PLAYER_COLLISION.Y internals)
	ccf
	sbc	a, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is above the enemy
; param ix: pointer to the current enemy
; ret z/nz: z if the wait has finished (the player is above), nz otherwise
.PLAYER_ABOVE_DEFAULT:
; Default horizontal maximum distance
IFEXIST CFG_ENEMY_ADVANCE_COLLISION
	ld	l, PLAYER_ENEMY_X_SIZE + CFG_ENEMY_ADVANCE_COLLISION * 2
ELSE
	ld	l, PLAYER_ENEMY_X_SIZE
ENDIF
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
IFEXIST CFG_ENEMY_ADVANCE_COLLISION
	ld	l, PLAYER_ENEMY_X_SIZE + CFG_ENEMY_ADVANCE_COLLISION * 2
ELSE
	ld	l, PLAYER_ENEMY_X_SIZE
ENDIF
	; jr	.PLAYER_BELOW : falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Wait state handler: waits until the player is below the enemy
; param ix: pointer to the current enemy
; param l: horizontal maximum distance
; ret z/nz: z if the wait has finished (the player is below), nz otherwise
.PLAYER_BELOW:
; Is the player on-screen (avoid false positives)?
	ld	a, [player.y]
	dec	a ; (avoids false positive due player.y == enemy.y)
	cp	192
	ret	nc ; no (ret nz)
; Is the player below?
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
; Translates c/nc to z/nz
; (note: a = 0 implies c because of CHECK_PLAYER_COLLISION.X internals)
	ccf
	sbc	a, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Trigger state handler: pauses until the enemy can shoot again
; param ix: pointer to the current enemy
; ret z/nz: z if the wait has finished (the enemy can shoot again), nz otherwise
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

; EOF
