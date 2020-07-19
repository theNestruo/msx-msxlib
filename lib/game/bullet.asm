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

	MASK_BULLET_SPEED:	equ $fe ; speed (in signed pixels / frame)
	MASK_BULLET_DIRECTION:	equ $81 ; movement direction (sign + direction)

	BULLET_DIR_UD:		equ $00
	BULLET_DIR_LR:		equ $01
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
	jp	z, .SKIP ; yes
; no: Updates the bullet
	push	bc ; preserves counter in b

; Moves the bullet and checks for collision
	call	.MOVE
; Has the bullet hit a wall?
	bit	BIT_WORLD_SOLID, a
IFDEF CFG_BULLET_DYING_PATTERN
	jr	nz, .REMOVE ; yes
ELSE
	jp	z, .PUT_SPRITE ; no
; yes: Removes the bullet (for the next frame)
	xor	a ; (marker value: y = 0)
	ld	[ix + bullet.y], a
ENDIF ; IFDEF CFG_BULLET_DYING_PATTERN
; Puts the bullet sprite
.PUT_SPRITE:
	ld	e, [ix + bullet.y]
	ld	c, [ix + bullet.pattern]
.PUT_SPRITE_Y_PATTERN_OK:
	ld	d, [ix + bullet.x]
	ld	b, [ix + bullet.color]
	call	PUT_SPRITE

; Skips to the next bullet
	pop	bc ; restores counter
	ld	de, bullet.SIZE ; restores bullet size
.SKIP:
	add	ix, de
	djnz	.LOOP
	ret


.MOVE:
; Determines bullet direction
	ld	a, [ix + bullet.type]
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


IFDEF CFG_BULLET_DYING_PATTERN
.REMOVE:
; Prepares the last sprite
IF CFG_ENEMY_HEIGHT = CFG_BULLET_HEIGHT
	ld	e, [ix + bullet.y]
ELSE
	ld	a, [ix + bullet.y]
	add	(CFG_ENEMY_HEIGHT - CFG_BULLET_HEIGHT) / 2
	ld	e, a
ENDIF ; IF CFG_ENEMY_HEIGHT = CFG_BULLET_HEIGHT
; Removes the bullet (for the next frame)
	ld	[ix + bullet.y], 0 ; (marker value: y = 0)
; Puts the bullet sprite
	ld	c, CFG_BULLET_DYING_PATTERN
	jp	.PUT_SPRITE_Y_PATTERN_OK
ENDIF ; IFDEF CFG_BULLET_DYING_PATTERN
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
