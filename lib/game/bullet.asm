;
; =============================================================================
;	Bullet related routines (generic)
;	Bullet-tile helper routines
; =============================================================================
;

	CFG_RAM_BULLET:	equ 1

; -----------------------------------------------------------------------------
; Bounding box coordinates offset from the logical coordinates
	BULLET_BOX_X_OFFSET:	equ -(CFG_BULLET_WIDTH / 2)
	BULLET_BOX_Y_OFFSET:	equ -CFG_BULLET_HEIGHT

	BIT_BULLET_DYING:	equ 0 ; bit set for dying bullet

	MASK_BULLET_SPEED:	equ $fc ; speed (in signed pixels / frame)
	MASK_BULLET_DIRECTION:	equ $82 ; movement direction (sign + direction)
	MASK_BULLET_DYING:	equ ($01 << BIT_BULLET_DYING) ; flag for dying bullet

	BULLET_DIR_UD:		equ $00
	BULLET_DIR_LR:		equ $02
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Empties the bullets array
RESET_BULLETS:
; Fills the array with zeroes
	ld	hl, bullets
	ld	de, bullets +1
	ld	bc, bullets.SIZE -1
	ld	[hl], b ; b = $00
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
	ld	de, bullet.SIZE
.LOOP:
; Is the bullet slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + bullet.y]
	jp	z, .FAST_SKIP ; yes
; no: Updates the bullet
	push	bc ; preserves counter in b

; Checks for dying bullet animation
IFDEF CFG_BULLET_DYING_PATTERN
; Is the dying bullet animation?
	ld	a, [ix + bullet.type] ; (loaded to be reused in MOVE_BULLET.A_OK)
	bit	BIT_BULLET_DYING, a
	sra	a ; flag for dying bullet in carry flag
	jp	nc, .NOT_DYING ; no
; yes: Decreases the frame counter
	dec	a
	jp	z, .REMOVE ; zero: removes the bullet
; not zero: saves frame counter
	scf	; (restores dying bullet flag)
	rla
	ld	[ix + bullet.type], a
	jp	.PUT_SPRITE

; Removes the bullet
.REMOVE:
	; xor	a ; (unnecessary)
	ld	[ix + bullet.y], a
	jp	.SKIP

; Moves the bullet and checks for collision
.NOT_DYING:
	call	MOVE_BULLET.A_OK

ELSE
; Moves the bullet and checks for collision
	call	MOVE_BULLET
ENDIF ; IFDEF CFG_BULLET_DYING_PATTERN

; Has the bullet hit a wall?
	bit	BIT_WORLD_SOLID, a
	jp	z, .PUT_SPRITE ; no
IFDEF CFG_BULLET_DYING_PATTERN
; yes: Prepares the dying bullet animation
	ld	a, CFG_BULLET_DYING_PAUSE << 1 OR MASK_BULLET_DYING
	ld	[ix + bullet.type], a
; Prepares the sprite
IF CFG_ENEMY_HEIGHT != CFG_BULLET_HEIGHT
	ld	a, [ix + bullet.y]
	add	(CFG_ENEMY_HEIGHT - CFG_BULLET_HEIGHT) / 2
	ld	[ix + bullet.y], a
ENDIF ; IF CFG_ENEMY_HEIGHT = CFG_BULLET_HEIGHT
	ld	[ix + bullet.pattern], CFG_BULLET_DYING_PATTERN

ELSE
; yes: Removes the bullet (for the next frame)
	xor	a ; (marker value: y = 0)
	ld	[ix + bullet.y], a
	jp	.SKIP
ENDIF ; IFDEF CFG_BULLET_DYING_PATTERN

; Puts the bullet sprite
.PUT_SPRITE:
	ld	e, [ix + bullet.y]
	ld	c, [ix + bullet.pattern]
	ld	d, [ix + bullet.x]
	ld	b, [ix + bullet.color]
	call	PUT_SPRITE

.SKIP:
; Skips to the next bullet
	pop	bc ; restores counter
	ld	de, bullet.SIZE ; restores bullet size
.FAST_SKIP:
	add	ix, de
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates a bullet: moves the bullet
; param ix: pointer to the current bullet
; ret a: OR-ed tile flags
MOVE_BULLET:
; Determines bullet direction
	ld	a, [ix + bullet.type]
	sra	a
.A_OK:
	sra	a ; UD/LR in carry flag, bullet speed in a
	jr	nc, .UP_OR_DOWN ; 0 => BULLET_DIR_UD
; 1 => BULLET_DIR_LR
	bit	7, a
	jp	p, .RIGHT
	; jp	.LEFT ; falls through

.LEFT:
; Moves the bullet left
	add	[ix + bullet.x]
	ld	[ix + bullet.x], a
; Has the bullet hit a wall?
	ld	a, BULLET_BOX_X_OFFSET
	jp	GET_BULLET_V_TILE_FLAGS

.RIGHT:
; Moves the bullet right
	add	[ix + bullet.x]
	ld	[ix + bullet.x], a
; Has the bullet hit a wall?
	ld	a, BULLET_BOX_X_OFFSET + CFG_BULLET_WIDTH - 1
	jp	GET_BULLET_V_TILE_FLAGS

.UP_OR_DOWN:
	bit	7, a
	jp	p, .DOWN
	; jp	.UP ; falls through

.UP:
; Moves the bullet up
	add	[ix + bullet.y]
	ld	[ix + bullet.y], a
; Checks off-screen
	sub	192 -1
	ld	a, 1 << BIT_WORLD_SOLID ; (fake tile flags)
	ret	nc ; yes
; Has the bullet hit a wall?
	ld	a, BULLET_BOX_Y_OFFSET
	jp	GET_BULLET_H_TILE_FLAGS

.DOWN:
; Moves the bullet down
	add	[ix + bullet.y]
	ld	[ix + bullet.y], a
; Has the bullet hit a wall?
	xor	a
	jp	GET_BULLET_H_TILE_FLAGS
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Bullet-tile helper routines
; =============================================================================
;

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
	ld	a, e
	add	BULLET_BOX_Y_OFFSET
	ld	e, a
; Bullet height
	ld	b, CFG_BULLET_HEIGHT
	jp	GET_V_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of a vertical serie of tiles
; relative to the bullet position
; param ix: pointer to the current bullet
; param a: x-offset from the bullet logical coordinates
; ret a: OR-ed tile flags
; touches: hl, bc, de
GET_BULLET_H_TILE_FLAGS:
; Bullet coordinates
	ld	e, [ix + bullet.y]
	ld	d, [ix + bullet.x]
; y += dy
	add	e
	ld	e, a
; x += BULLET_BOX_X_OFFSET
	ld	a, d
	add	BULLET_BOX_X_OFFSET
	ld	d, a
; Bullet width
	ld	b, CFG_BULLET_WIDTH
	jp	GET_H_TILE_FLAGS
; -----------------------------------------------------------------------------


; EOF
