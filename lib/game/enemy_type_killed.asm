;
; =============================================================================
;	Enemy type: killed (generic)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Kills the enemy
; param ix: pointer to the current enemy
KILL_ENEMY:
IFEXIST CFG_SOUND_ENEMY_KILLED
	ld	a, CFG_SOUND_ENEMY_KILLED
	ld	c, 7 ; default-high priority
	call	ayFX_INIT
ENDIF
.NO_SOUND:
; Makes the enemy non-lethal and non-solid
	ld	a, [ix + enemy.flags]
	and	($ff XOR (FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH))
	ld	[ix + enemy.flags], a
; Sets the enemy the behaviour when killed
	ld	hl, ENEMY_TYPE_KILLED
	jp	SET_ENEMY_STATE
; -----------------------------------------------------------------------------

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

; EOF
