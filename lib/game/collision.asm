;
; =============================================================================
;	Enemy-player helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
	PLAYER_ENEMY_X_SIZE:	equ (CFG_PLAYER_WIDTH + CFG_ENEMY_WIDTH) /2
	PLAYER_ENEMY_Y_SIZE:	equ (CFG_PLAYER_HEIGHT + CFG_ENEMY_HEIGHT) /2
; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; CHECK_COLLISIONS_ENEMIES:
; ; Recorre el array de enemigos
	; ld	ix, enemies_array
	; ld	b, MAX_ENEMY_COUNT
; .LOOP:
	; push	bc ; preserva el contador en b
	; call	CHECK_COLLISION_ENEMY
; ; AVanza al siguiente enemigo
	; ld	bc, ENEMY_SIZE
	; add	ix, bc
	; pop	bc ; restaura el contador
	; djnz	.LOOP
; ; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ret c: collision
; ret nc: no collision
CHECK_PLAYER_ENEMY_COLLISION:

.X:
	ld	a, [player.x]
	sub	[ix + enemy.x]
	jp	p, .X_POSITIVE ; (absolute value)
	neg
.X_POSITIVE:
; Overlapping?
	cp	PLAYER_ENEMY_X_SIZE
	ret	; c= sí, nc= no
; -----------------------------------------------------------------------------

; EOF
