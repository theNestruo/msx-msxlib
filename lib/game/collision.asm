;
; =============================================================================
;	Player-enemy-bullet helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
	PLAYER_ENEMY_X_SIZE:	equ (CFG_PLAYER_WIDTH + CFG_ENEMY_WIDTH) /2
	PLAYER_ENEMY_Y_SIZE:	equ (CFG_PLAYER_HEIGHT + CFG_ENEMY_HEIGHT) /2
	PLAYER_ENEMY_Y_OFFSET:	equ (CFG_ENEMY_HEIGHT - CFG_PLAYER_HEIGHT) /2
	PLAYER_ENEMY_YX_SIZES:	equ (PLAYER_ENEMY_Y_SIZE << 8) + PLAYER_ENEMY_X_SIZE

IFEXIST RESET_BULLETS
	PLAYER_BULLET_X_SIZE:	equ (CFG_PLAYER_WIDTH + CFG_BULLET_WIDTH) /2
	PLAYER_BULLET_Y_SIZE:	equ (CFG_PLAYER_HEIGHT + CFG_BULLET_HEIGHT) /2
	PLAYER_BULLET_Y_OFFSET:	equ (CFG_BULLET_HEIGHT - CFG_PLAYER_HEIGHT) /2
	PLAYER_BULLET_YX_SIZES:	equ (PLAYER_BULLET_Y_SIZE << 8) + PLAYER_BULLET_X_SIZE
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Checks collision between the player and any enemy
; and executes
CHECK_PLAYER_ENEMIES_COLLISIONS:
	ld	hl, PLAYER_ENEMY_YX_SIZES
	ld	c, PLAYER_ENEMY_Y_OFFSET
; For each enemy in the array
	ld	ix, enemies
	ld	de, enemy.SIZE
	ld	b, CFG_ENEMY_COUNT
.LOOP:
; Is the enemy slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + enemy.y]
	jp	z, .NEXT ; yes
; no: checks collision between the player and one enemy
	call	CHECK_PLAYER_COLLISION
	jp	c, ON_PLAYER_ENEMY_COLLISION
.NEXT:
; Skips to the next enemy
	add	ix, de
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

IFEXIST RESET_BULLETS
; -----------------------------------------------------------------------------
; Checks collision between the player and any bullet
CHECK_PLAYER_BULLETS_COLLISIONS:
	ld	hl, PLAYER_BULLET_YX_SIZES
	ld	c, PLAYER_BULLET_Y_OFFSET
; For each bullet in the array
	ld	ix, bullets
	ld	de, bullet.SIZE
	ld	b, CFG_BULLET_COUNT
.BULLET_LOOP:
; Is the bullet slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + bullet.y]
	jp	z, .NEXT ; yes
; no: checks collision between the player and one bullet
	call	CHECK_PLAYER_COLLISION
	jp	c, ON_PLAYER_BULLET_COLLISION
.NEXT:
; Skips to the next bullet
	add	ix, de
	djnz	.BULLET_LOOP
	ret
; -----------------------------------------------------------------------------
ENDIF

; -----------------------------------------------------------------------------
; Checks collision between the player and one enemy
; param ix: pointer to the enemy
; param h: vertical maximum distance
; param l: horizontal maximum distance
; param c: vertical offset the logical vertical coordinate is not centered)
; ret c: collision
; ret nc: no collision
; touches: af
CHECK_PLAYER_COLLISION:
; Overlapping x?
	call	.X
	ret	nc ; no
; Overlapping y?
	; jr	.Y ; falls through

.Y:
	ld	a, [player.y]
	sub	[ix + enemy.y]
	add	c
	jp	p, .Y_POSITIVE ; (absolute value)
	neg
.Y_POSITIVE:
; Overlapping?
	cp	h ; (vertical maximum distance)
	ret	; c/nc (yes/no)

.X:
	ld	a, [player.x]
	sub	[ix + enemy.x]
	jp	p, .X_POSITIVE ; (absolute value)
	neg
.X_POSITIVE:
; Overlapping?
	cp	l ; (horizontal maximum distance)
	ret	; c/nc (yes/no)
; -----------------------------------------------------------------------------

; EOF
