;
; =============================================================================
;	Top-down player related routines (four directions)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Player state modifiers (as bit indexes)
	BIT_STATE_LEFT:		equ 1 ; 0 = left, 1 = right
	BIT_STATE_UP:		equ 1 ; 0 = up, 1 = down
	BIT_STATE_UD_OR_LR:	equ 2 ; 0 = up/down, 1 = left/right
	PLAYER_STATE_MOD_BITS:	equ 3

; Player state modifiers (as flags)
	FLAGS_STATE_DIRECTION:	equ ($03 << 1)
	FLAGS_STATE:		equ FLAGS_STATE_DIRECTION OR FLAG_STATE_ANIM ; $07

; Player directions
	PLAYER_DIRECTION_UP:	equ (0 << 1)
	PLAYER_DIRECTION_DOWN:	equ (1 << 1)
	PLAYER_DIRECTION_LEFT:	equ (2 << 1)
	PLAYER_DIRECTION_RIGHT:	equ (3 << 1)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the player one pixel up
MOVE_PLAYER_UP:
; Moves up
	ld	hl, player.y
	dec	[hl]
; Sets "direction" flags
	ld	a, PLAYER_DIRECTION_UP
	ld	b, FLAGS_STATE_DIRECTION
	jp	SET_PLAYER_STATE.MASK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the player one pixel down
MOVE_PLAYER_DOWN:
; Moves left
	ld	hl, player.y
	inc	[hl]
; Sets "direction" flags
	ld	a, PLAYER_DIRECTION_DOWN
	ld	b, FLAGS_STATE_DIRECTION
	jp	SET_PLAYER_STATE.MASK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the player one pixel to the right
MOVE_PLAYER_RIGHT:
; Moves right
	ld	hl, player.x
	inc	[hl]
; Sets "direction" flags
	ld	a, PLAYER_DIRECTION_RIGHT
	ld	b, FLAGS_STATE_DIRECTION
	jp	SET_PLAYER_STATE.MASK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the player one pixel to the right
MOVE_PLAYER_LEFT:
; Moves left
	ld	hl, player.x
	dec	[hl]
; Sets "direction" flags
	ld	a, PLAYER_DIRECTION_LEFT
	ld	b, FLAGS_STATE_DIRECTION
	jp	SET_PLAYER_STATE.MASK
; -----------------------------------------------------------------------------
