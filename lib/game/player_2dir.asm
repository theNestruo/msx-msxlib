;
; =============================================================================
;	Side-view player related routines (two directions: left, right)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Player state modifiers (as bit indexes)
	BIT_STATE_LEFT:		equ 1
	PLAYER_STATE_MOD_BITS:	equ 2

; Player state modifiers (as flags)
	FLAG_STATE_LEFT:	equ (1 << BIT_STATE_LEFT) ; $02
	FLAGS_STATE:		equ FLAG_STATE_LEFT OR FLAG_STATE_ANIM ; $03
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the player one pixel to the right
MOVE_PLAYER_RIGHT:
; Moves right
	ld	hl, player.x
	inc	[hl]
; Resets "left" flag
	inc	hl
	inc	hl ; hl = player.state
	res	BIT_STATE_LEFT, [hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the player one pixel to the right
MOVE_PLAYER_LEFT:
; Moves left
	ld	hl, player.x
	dec	[hl]
; Sets "left" flag
	inc	hl
	inc	hl ; hl = player.state
	set	BIT_STATE_LEFT, [hl]
	ret
; -----------------------------------------------------------------------------
