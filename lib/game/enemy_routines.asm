
; -----------------------------------------------------------------------------
ENEMY_ROUTINE_CRAWLER:
	dw	EH_PUT_SPRITE_ANIM
	db	0 ; (unused)
	dw	EH_WALK
	db	0 ; forever
	dw	EH_SET_STATE
	db	STATE_SIZE ; next
	
	dw	EH_PUT_SPRITE
	db	0 ; (unused)
	dw	EH_IDLE_TURNING ; EH_IDLE
	db	(2 << 6) OR 30 ; 3 repetitions, 30 frames
	dw	EH_SET_STATE
	db	-5 * STATE_SIZE ; restart
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ENEMY_ROUTINE_FOLLOWER:
	dw	EH_PUT_SPRITE_ANIM
	db	0 ; (unused)
	dw	EH_WALK
	db	32 ; 16 pixels
	dw	EH_SET_STATE
	db	STATE_SIZE ; next
	
	dw	EH_PUT_SPRITE
	db	0 ; (unused)
	dw	EH_IDLE_TURNING
	db	(2 << 6) OR 30 ; 3 repetitions, 30 frames
	dw	EH_TURN_WALKING_ENEMY_TOWARDS_PLAYER
	db	0 ; (unused)
	dw	EH_SET_STATE
	db	-6 * STATE_SIZE ; restart
; -----------------------------------------------------------------------------
