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
; param bc: (x, y) offset of the bullet coordinates from the enemy coordinates
; touches: a, hl, de, bc
INIT_BULLET_FROM_ENEMY:
	push	hl ; preserves source
	push	bc ; preserves offset
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
	pop	bc ; restores offsets
; .y
	ld	a, [hl] ; [de++] = [hl++] + c (y offset)
	inc	hl
	add	c
	ld	[de], a
	inc	de
; .x
	ld	a, [hl] ; [de++] = [hl++] + b (x offset)
	inc	hl
	add	b
	ld	[de], a
	inc	de
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
	jr	z, .SKIP ; yes

; Moves the bullet
	call	.MOVE
; Puts the bullet sprite
	ld	e, [ix + bullet.y]
	ld	d, [ix + bullet.x]
	push	de ; preserves bullet coordinates
	ld	c, [ix + bullet.pattern]
	ld	b, [ix + bullet.color]
	call	PUT_SPRITE
	
; Has the bullet hit a wall?
	pop	de ; restores bullet coordinates
	dec	e
	call	GET_TILE_VALUE
	call	GET_TILE_FLAGS
	bit	BIT_WORLD_SOLID, a
	jr	nz, .REMOVE ; yes
; Checks off-screen
	ld	a, [ix + bullet.y]
	sub	192 -1
	jr	c, .SKIP ; yes
.REMOVE:
; Removes the bullet (for the next frame)
	xor	a ; (marker value: y = 0)
	ld	[ix + bullet.y], a
	; jr	.SKIP ; falls through
	
.SKIP:
; Skips to the next bullet
	ld	bc, bullet.SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.LOOP
	ret

; Moves the bullet	
.MOVE:
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
	add	[ix + bullet.x]
	ld	[ix + bullet.x], a
	ret
.RIGHT:
	and	MASK_BULLET_SPEED
	add	[ix + bullet.x]
	ld	[ix + bullet.x], a
	ret

.UP_OR_DOWN:
	cp	BULLET_DIR_DOWN
	jr	c, .UP
	; jr	.DOWN ; falls through
.DOWN:
	and	MASK_BULLET_SPEED
	add	[ix + bullet.y]
	ld	[ix + bullet.y], a
	ret
.UP:
	and	MASK_BULLET_SPEED
	neg
	add	[ix + bullet.y]
	ld	[ix + bullet.y], a
	ret
; -----------------------------------------------------------------------------

; EOF
