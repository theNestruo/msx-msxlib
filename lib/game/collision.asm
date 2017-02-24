;
; =============================================================================
;	Enemy-player helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
	PLAYER_ENEMY_X_SIZE:	equ (CFG_PLAYER_WIDTH + CFG_ENEMY_WIDTH) /2
	PLAYER_ENEMY_Y_SIZE:	equ (CFG_PLAYER_HEIGHT + CFG_ENEMY_HEIGHT) /2
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Checks collision between the player and any enemy
CHECK_PLAYER_ENEMIES_COLLISIONS:
; For each enemy in the array
	ld	ix, enemies
	ld	b, CFG_ENEMY_COUNT
.ENEMY_LOOP:
	push	bc ; preserves counter in b
; Is the enemy slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + enemy.y]
	jp	z, .SKIP_ENEMY ; yes
; no: checks collision between the player and one enemy

	call	CHECK_PLAYER_ENEMY_COLLISION
	call	c, ON_PLAYER_ENEMY_COLLISION
	
.SKIP_ENEMY:
; Skips to the next enemy
	ld	bc, enemy.SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.ENEMY_LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Checks collision between the player and one enemy
; param ix: pointer to the enemy
; ret c: collision
; ret nc: no collision
CHECK_PLAYER_ENEMY_COLLISION:
; Overlapping x?
	call	.X
	ret	nc ; no
; Overlapping y?
	; jr	.Y ; falls through

.Y:
	ld	a, [player.y]
	sub	[ix + enemy.y]
	jp	p, .Y_POSITIVE ; (absolute value)
	neg
.Y_POSITIVE:
; Overlapping?
	cp	PLAYER_ENEMY_Y_SIZE
	ret	; c/nc (yes/no)

.X:
	ld	a, [player.x]
	sub	[ix + enemy.x]
	jp	p, .X_POSITIVE ; (absolute value)
	neg
.X_POSITIVE:
; Overlapping?
	cp	PLAYER_ENEMY_X_SIZE
	ret	; c/nc (yes/no)
; -----------------------------------------------------------------------------

; EOF
