;
; =============================================================================
;	Player related routines (generic)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bounding box offset (based on the logical sprite sizes)
	PLAYER_BOX_X_OFFSET:	equ -(CFG_PLAYER_WIDTH / 2)
	PLAYER_BOX_Y_OFFSET:	equ -(CFG_PLAYER_HEIGHT)

; Player state modifiers (as bit indexes)
	BIT_STATE_ANIM:		equ 0
	BIT_STATE_LEFT:		equ 1
	BIT_STATE_FINISH:	equ 7 ; (special state marker: exit state)
	
; Player state modifiers (as flags)
	FLAG_STATE_ANIM:	equ (1 << BIT_STATE_ANIM) ; $01
	FLAG_STATE_LEFT:	equ (1 << BIT_STATE_LEFT) ; $02
	FLAGS_STATE:		equ FLAG_STATE_LEFT OR FLAG_STATE_ANIM ; $03
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; (direct pointers inside SPRATR buffer)
	player_spratr:		equ spratr_buffer
		.pattern:	equ player_spratr +2
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the player sprites in the SPRATR buffer,
; and sets their patterns according PLAYER_SPRATR_TABLE[player.state]
PUT_PLAYER_SPRITE:
; First pattern according player state
	ld	a, [player.state]
	ld	hl, PLAYER_SPRATR_TABLE
	call	GET_HL_A_BYTE
	ld	[player_spratr.pattern], a
; Moves the player sprites
	ld	hl, player_spratr
	ld	de, [player.xy]
	ld	b, CFG_PLAYER_SPRITES
	jp	MOVE_SPRITES
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates animation counter and toggles the animation flag
UPDATE_PLAYER_ANIMATION:
; Updates animation counter
	ld	a, [player.animation_delay]
	inc	a
	cp	CFG_PLAYER_ANIMATION_DELAY
	jr	nz, .DONT_ANIMATE
; Toggles the animation flag
	ld	hl, player.state
	ld	a, FLAG_STATE_ANIM
	xor	[hl]
	ld	[hl], a
; Resets animation counter
	xor	a
.DONT_ANIMATE:
	ld	[player.animation_delay], a
	ret
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

; -----------------------------------------------------------------------------
; Sets the player state, but keeping the "left" flag
; param a: new player state
; ret a: new player state with previous left flag
; touches: hl, b
SET_PLAYER_STATE:
	ld	b, $ff XOR FLAG_STATE_LEFT
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Sets the player state, applying a mask
; param a: new player state
; param b: mask
; ret a: new player state with previous unmasked flag
; touches: hl
.MASK:
	ld	hl, player.state
	; jr	LD_HL_A_MASK ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Loads a in [hl], masked with b
; param hl: memory address
; param a: new value
; param b: mask (1 = new value, 0 = old value)
; ret a: loaded value
LD_HL_A_MASK:
			; a    = new_10
	xor	[hl]	; a    = new_10 ^ old_10
	and	b	; a    = new_1_ ^ old_1_
	xor	[hl]	; a    = new_1_ ^ old__0
	ld	[hl], a	; [hl] = new_1_ ^ old__0
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Player-tile helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Reads the tile index (value) at the player coordinates
; (one pixel over the player logical coordinates)
; ret hl: NAMTBL buffer pointer
; ret a: tile index (value)
; touches: de
GET_PLAYER_TILE_VALUE:
	ld	de, [player.xy]
	dec	e
	jp	GET_TILE_VALUE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the tile flags at the player coordinates
; (one pixel over the player logical coordinates)
; ret hl: NAMTBL buffer pointer
; ret a: tile flags
; touches: de
GET_PLAYER_TILE_FLAGS:
	call	GET_PLAYER_TILE_VALUE
	jp	GET_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the left of the player
; when aligned to the tile boundary
; ret a: OR-ed tile flags
GET_PLAYER_TILE_FLAGS_LEFT_FAST:
; Aligned to tile boundary?
	ld	a, [player.x]
	add	PLAYER_BOX_X_OFFSET
	and	$07
	jr	nz, CHECK_NO_TILES ; no: return no flags
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the left of the player
; ret a: OR-ed tile flags
GET_PLAYER_TILE_FLAGS_LEFT:
	ld	a, PLAYER_BOX_X_OFFSET -1
	jr	GET_PLAYER_V_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the right of the player
; when aligned to the tile boundary
; ret a: OR-ed tile flags
GET_PLAYER_TILE_FLAGS_RIGHT_FAST:
; Aligned to tile boundary?
	ld	a, [player.x]
	add	PLAYER_BOX_X_OFFSET + CFG_PLAYER_WIDTH
	and	$07
	jr	nz, CHECK_NO_TILES ; no: return no flags
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the right of the player
; ret a: OR-ed tile flags
GET_PLAYER_TILE_FLAGS_RIGHT:
	ld	a, PLAYER_BOX_X_OFFSET + CFG_PLAYER_WIDTH
	; jr	GET_PLAYER_V_TILE_FLAGS ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of a vertical serie of tiles
; relative to the player position
; param a: x-offset from the player logical coordinates
; ret a: OR-ed tile flags
GET_PLAYER_V_TILE_FLAGS:
; Player coordinates
	ld	de, [player.xy]
; x += dx
	add	d
	ld	d, a
; y += PLAYER_BOX_Y_OFFSET
	ld	a, PLAYER_BOX_Y_OFFSET
	add	e
	ld	e, a
; Player height
	ld	b, CFG_PLAYER_HEIGHT
	jp	GET_V_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles over the player
; when aligned to the tile boundary
; ret a: OR-ed tile flags
GET_PLAYER_TILE_FLAGS_OVER_FAST:
; Aligned to tile boundary?
	ld	a, [player.y]
	add	PLAYER_BOX_Y_OFFSET
	and	$07
	jr	nz, CHECK_NO_TILES ; no: return no flags
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles over the player
; ret a: OR-ed tile flags
GET_PLAYER_TILE_FLAGS_OVER:
	ld	a, PLAYER_BOX_Y_OFFSET - 1
	jr	GET_PLAYER_H_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles at the player coordinates
; (one pixel over the player logical coordinates, full width)
GET_PLAYER_TILE_FLAGS_WIDE:
	ld	a, -1
	jr	GET_PLAYER_H_TILE_FLAGS
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles under the player
; when aligned to a tile boundary
; ret a: OR-ed tile flags
GET_PLAYER_TILE_FLAGS_UNDER_FAST:
; Aligned to tile boundary?
; (or falling fast enough to cross the tile boundary?)
	ld	a, [player.y]
IFDEF CFG_PLAYER_GRAVITY
	and	$07
	cp	CFG_PLAYER_GRAVITY ; (any value lower than the maximum dy)
	jr	nc, CHECK_NO_TILES ; no: return no flags
ELSE
	and	$07
	jr	nz, CHECK_NO_TILES ; no: return no flags
ENDIF
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles under the player
; ret a: OR-ed tile flags
GET_PLAYER_TILE_FLAGS_UNDER:
	xor	a ; dy = 0
	; jr	GET_PLAYER_H_TILE_FLAGS ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of an horizontal serie of tiles
; relative to the player position
; param a: y-offset from the player logical coordinates
; ret a: OR-ed tile flags
GET_PLAYER_H_TILE_FLAGS:
; Player coordinates
	ld	de, [player.xy]
; y += dy
	add	e
	ld	e, a
; x += PLAYER_X_OFFSET
	ld	a, PLAYER_BOX_X_OFFSET
	add	d
	ld	d, a
; Player width
	ld	b, CFG_PLAYER_WIDTH
	jp	GET_H_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience routine to read no flags
; (used in _FAST version of the checks)
; ret a: 0
; ret z
CHECK_NO_TILES:
	xor	a
	ret
; -----------------------------------------------------------------------------

; EOF