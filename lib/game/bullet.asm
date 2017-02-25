;
; =============================================================================
;	Bullet related routines (generic)
;	Bullet-tile helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bounding box coordinates offset from the logical coordinates
	BULLET_BOX_X_OFFSET:	equ -(CFG_BULLET_WIDTH / 2)
	BULLET_BOX_Y_OFFSET:	equ -CFG_BULLET_HEIGHT

	MASK_BULLET_SPEED:	equ $0f ; speed (in pixels / frame)
	MASK_BULLET_DIRECTION:	equ $70 ; movement direction

	BULLET_DIR_UP:		equ $10
	BULLET_DIR_DOWN:	equ $20
	BULLET_DIR_RIGHT:	equ $30
	BULLET_DIR_LEFT:	equ $40
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Empties the bullets array
RESET_BULLETS:
; Fills the array with zeroes
	ld	hl, bullets
	ld	de, bullets +1
	ld	bc, bullets.SIZE -1
	ld	[hl], 0
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new from the enemy coordinates in the first empty bullet slot
; param hl: pointer to the new bullet data (pattern, color, speed and direction)
; touches: a, hl, de, bc
INIT_BULLET_FROM_ENEMY:
	push	hl ; preserves source
; Search for the first empty enemy slot
	ld	hl, bullets
	ld	bc, bullet.SIZE
	xor	a ; (marker value: y = 0)
.LOOP:
	cp	[hl]
	jr	z, .INIT ; empty slot found
; Skips to the next element of the array
	add	hl, bc
	jr	.LOOP
	
.INIT:
; Stores the logical coordinates
	push	ix ; hl = ix, de = empy bullet slot
	pop	de
	ex	de, hl
	ldi	; .y
	ldi	; .x
; Stores the pattern, color and type (speed and direction)
	pop	hl ; restores source in hl
	ldi	; .pattern
	ldi	; .color
	ldi	; .type
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the bullets
UPDATE_BULLETS:
; For each bullet in the array
	ld	ix, bullets
	ld	b, CFG_BULLET_COUNT
.LOOP:
	push	bc ; preserves counter in b
; Is the bullet slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + bullet.y]
	call	nz, UPDATE_BULLET ; no
; Skips to the next bullet
	ld	bc, bullet.SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates one bullet
UPDATE_BULLET:
; ; Puts the bullet sprite
	; ld	e, [ix + bullet.y]
	; ld	d, [ix + bullet.x]
	; ld	c, [ix + bullet.pattern]
	; ld	b, [ix + bullet.color]
	; call	PUT_SPRITE

	call	.A
	ld	e, [ix + bullet.y]
	ld	d, [ix + bullet.x]
	ld	c, [ix + bullet.pattern]
	ld	b, [ix + bullet.color]
	jp	PUT_SPRITE
.A:

; Determines bullet direction	
	ld	a, [ix + bullet.type]
	cp	BULLET_DIR_RIGHT
	jr	c, .UP_OR_DOWN ; direction < RIGHT, ergo UP or DOWN
; direction >= RIGHT, ergo RIGHT or LEFT
	cp	BULLET_DIR_LEFT
	jr	c, .RIGHT
	; jr	.LEFT ; falls through

.LEFT:
	and	MASK_BULLET_SPEED
	neg
	add	d
	ld	[ix + bullet.x], a
	ret
	
.RIGHT:
; Is there wall ahead to the right?
	and	MASK_BULLET_SPEED ; a = delta-X
	call	GET_BULLET_TILE_FLAGS_RIGHT_FAST
	bit	BIT_WORLD_SOLID, a
	jr	nz, .REMOVE_BULLET ; yes
; no: moves the bullet to the right
	ld	a, [ix + bullet.type]
	and	MASK_BULLET_SPEED
	add	[ix + bullet.x]
	ld	[ix + bullet.x], a
	ret

.UP_OR_DOWN:
	cp	BULLET_DIR_DOWN
	jr	c, .UP

; down
	and	MASK_BULLET_SPEED
	add	e
	ld	[ix + bullet.y], a
	ret

.UP:
; up
	and	MASK_BULLET_SPEED
	neg
	add	e
	ld	[ix + bullet.y], a
	ret
	
.REMOVE_BULLET:
	xor	a ; (marker value: y = 0)
	ld	[ix + bullet.y], a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Bullet-tile helper routines
; =============================================================================
;

; ; -----------------------------------------------------------------------------
; ; Returns the OR-ed flags of the tiles to the left of the enemy
; ; when aligned to the tile boundary
; ; param ix: pointer to the current enemy
; ; ret a: OR-ed tile flags
; GET_ENEMY_TILE_FLAGS_LEFT_FAST:
; ; Aligned to tile boundary?
	; ld	a, [ix + enemy.x]
	; add	ENEMY_BOX_X_OFFSET
	; and	$07
	; jp	nz, GET_NO_BULLET_TILE_FLAGS ; no: return no flags
; ; ------VVVV----falls through--------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Returns the OR-ed flags of the tiles to the left of the enemy
; ; param ix: pointer to the current enemy
; ; ret a: OR-ed tile flags
; GET_ENEMY_TILE_FLAGS_LEFT:
	; ld	a, ENEMY_BOX_X_OFFSET -1
	; jr	GET_ENEMY_V_TILE_FLAGS
; ; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the right of the bullet
; when moving fast enough to cross the tile boundary
; param a: positive delta-X
; param ix: pointer to the current bullet
; ret a: OR-ed tile flags
; touches: hl, bc, de
GET_BULLET_TILE_FLAGS_RIGHT_FAST:
; Moving fast enough to cross the tile boundary?
	ld	b, a ; delta-X on b
; Rightmost pixels of the bullet
	add	[ix + bullet.x]
	add	BULLET_BOX_X_OFFSET + CFG_BULLET_WIDTH - 1
	or	$f8
; Adds delta-X and checks tile boundaries
	add	b
	jp	nc, GET_NO_BULLET_TILE_FLAGS ; no: return no flags
	
	ld	a, b ; restores delta-X
	jp	GET_BULLET_V_TILE_FLAGS
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the right of the bullet
; param a: positive delta-X
; param ix: pointer to the current bullet
; ret a: OR-ed tile flags
; touches: hl, bc, de
GET_BULLET_TILE_FLAGS_RIGHT:
	add	ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH - 1
	; jr	GET_BULLET_V_TILE_FLAGS ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of a vertical serie of tiles
; relative to the bullet position
; param ix: pointer to the current bullet
; param a: x-offset from the bullet logical coordinates
; ret a: OR-ed tile flags
; touches: hl, bc, de
GET_BULLET_V_TILE_FLAGS:
; Bullet coordinates
	ld	e, [ix + bullet.y]
	ld	d, [ix + bullet.x]
; x += dx
	add	d
	ld	d, a
; y += BULLET_BOX_Y_OFFSET
	ld	a, BULLET_BOX_Y_OFFSET
	add	e
	ld	e, a
; Bullet height
	ld	b, CFG_BULLET_HEIGHT
	jp	GET_V_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience routine to read no flags
; (used in GET_BULLET_TILE_FLAGS_*_FAST)
	GET_NO_BULLET_TILE_FLAGS:	equ RET_ZERO
; -----------------------------------------------------------------------------

; EOF
