
IFDEF CFG_RAM_PLAYER
; -----------------------------------------------------------------------------
; Variables for: Player related routines (generic)
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
; -----------------------------------------------------------------------------
ENDIF

IFDEF CFG_RAM_ENEMY
; -----------------------------------------------------------------------------
; Variables for: Enemies related routines (generic)
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
; Current trigger frame counter
	.trigger_frame_counter: equ $ - enemy
	rb	1
; Delta-Y (dY) table index (when jumping and falling)
	.dy_index:	equ $ - enemy
	rb	1
; Backup data for respawning the enemy
	.RESPAWN_SIZE:	equ .animation_delay ; (from .xy to .state)
	.respawn_data:	equ $ - enemy
	rb	.RESPAWN_SIZE
	
	.SIZE:		equ $ - enemy

; (rest of the array)
	rb	(CFG_ENEMY_COUNT -1) * .SIZE
	
	enemies.SIZE:	equ $ - enemies
; -----------------------------------------------------------------------------
ENDIF
	
IFDEF CFG_RAM_BULLET
; -----------------------------------------------------------------------------
; Variables for: Bullet related routines (generic)
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
; -----------------------------------------------------------------------------
ENDIF

; EOF
