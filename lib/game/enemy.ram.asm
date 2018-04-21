
; -----------------------------------------------------------------------------
IFDEF RESET_ENEMIES

; Enemies array
enemies:

enemy:
; Logical coordinates (in pixels)
	.xy:		equ $ - enemy
	.y:		equ $ - enemy
	rb	1
	.x:		equ $ - enemy
	rb	1
; Enemy sprite attributes
	.pattern:	equ $ - enemy
	rb	1
	.color:		equ $ - enemy
	rb	1
	.flags:		equ $ - enemy
	rb	1
; State pointer
	.state:		equ $ - enemy
	.state_l:	equ $ - enemy
	rb	1
	.state_h:	equ $ - enemy
	rb	1
; Current animation delay (e.g.: when walking) (in frames)
	.animation_delay:	equ $ - enemy
	rb	1
; Current frame counter
	.frame_counter:	equ $ - enemy
	rb	1
	.bullet_frame_counter: equ $ - enemy
	rb	1
	.SIZE:		equ $ - enemy

; (rest of the array)
	rb	(CFG_ENEMY_COUNT -1) * .SIZE
	enemies.SIZE:	equ $ - enemies

ENDIF
; -----------------------------------------------------------------------------

; EOF
