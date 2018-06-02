
; -----------------------------------------------------------------------------
IFDEF RESET_BULLETS

; Bullets array
bullets:

bullet:
; Logical coordinates (in pixels)
	.xy:		equ $ - bullet
	.y:		equ $ - bullet
	rb	1
	.x:		equ $ - bullet
	rb	1
; Bullet sprite attributes
	.pattern:	equ $ - bullet
	rb	1
	.color:		equ $ - bullet
	rb	1
; Bullet speed and direction
	.type:		equ $ - bullet
	rb	1
	
	.SIZE:		equ $ - bullet

; (rest of the array)
	rb	(CFG_BULLET_COUNT -1) * .SIZE
	
	bullets.SIZE:	equ $ - bullets

ENDIF
; -----------------------------------------------------------------------------

; EOF
