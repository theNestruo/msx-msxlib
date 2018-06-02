
; -----------------------------------------------------------------------------
IFDEF PUT_PLAYER_SPRITE

; Player vars
player:

; Logical coordinates (in pixels)
	.xy:
	.y:
	rb	1
	.x:
	rb	1
; Current animation delay (e.g.: when walking) (in frames)
	.animation_delay:
	rb	1
; Current player state
	.state:
	rb	1
; Delta-Y (dY) table index (when jumping and falling)
	.dy_index:
	rb	1
	
ENDIF
; -----------------------------------------------------------------------------

; EOF
