
; =============================================================================
; 	RAM
; =============================================================================

IFDEF CFG_INIT_16KB_RAM
	org	$c000, $f380
ELSE
	org	$e000, $f380
ENDIF
ram_start:

; =============================================================================
; 	MSX cartridge (ROM) header, entry point and initialization
; -----------------------------------------------------------------------------
; Refresh rate in Hertzs (50Hz/60Hz) and related convenience vars
frame_rate:
	rb	1
frames_per_tenth:
	rb	1
; =============================================================================


; =============================================================================
;	Input routines (BIOS-based)
; -----------------------------------------------------------------------------
; Stores GET_TRIGGER result
trigger:
	rb	1

; Stores GET_STICK_TRIGGER_BITS result
stick:
	rb	1
stick_edge:
	rb	1
; =============================================================================


; =============================================================================
;	VRAM buffers (NAMTBL and SPRATR)
; -----------------------------------------------------------------------------
; NAMTBL buffer in RAM
namtbl_buffer:
	rb	NAMTBL_SIZE
	
; SPRATR buffer in RAM
spratr_buffer:
	rb	SPRATR_SIZE
spratr_buffer_end:
	rb	1	; to store one SPAT_END when the buffer is full
; (direct pointers inside SPRATR buffer)
	spratr_player:	equ spratr_buffer + 4* CFG_SPRITES_RESERVED_BEFORE
	dynamic_sprites:	equ spratr_buffer + 4* (CFG_SPRITES_RESERVED_BEFORE + CFG_PLAYER_SPRITES + CFG_SPRITES_RESERVED_AFTER)

; Deferred WRTVRM vars (aka VPOKE-like vars)
IF (CFG_VRAM_VPOKES > 0)
vpoke_count:
	rb	1
vpoke_array:
	rb	CFG_VRAM_VPOKES * VPOKE_SIZE
ENDIF ; (CFG_VRAM_VPOKES > 0)
; =============================================================================


; -----------------------------------------------------------------------------
; Player vars
player_vars:

; Logical coordinates (in pixels)
player_xy:
player_y:
	rb	1
player_x:
	rb	1
; Current animation delay (e.g.: when walking) (in frames)
player_animation_delay:
	rb	1
; Current player state
player_state:
	rb	1
; dY table index (when jumping and falling)
player_dy_index:
	rb	1

	PLAYER_VARS_SIZE:	equ $ - player_vars
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Enemies array
enemies_array:
; Logical coordinates (in pixels)
	_ENEMY_Y:		equ $ - enemies_array
	rb	1
	_ENEMY_X:		equ $ - enemies_array
	rb	1
; Dynamic sprite attributes
	_ENEMY_PATTERN:	equ $ - enemies_array
	rb	1
	_ENEMY_COLOR:		equ $ - enemies_array
	rb	1
; Pointer to the current state
	_ENEMY_STATE_L:		equ $ - enemies_array
	rb	1
	_ENEMY_STATE_H:		equ $ - enemies_array
	rb	1
; Current animation delay
	_ENEMY_ANIMATION_DELAY:	equ $ - enemies_array
	rb	1
; Current frame counter
	_ENEMY_FRAME_COUNTER:	equ $ - enemies_array
	rb	1
	ENEMY_SIZE:		equ $ - enemies_array

; (rest of the array)
IF (CFG_ENEMY_COUNT > 1)
	rb	(CFG_ENEMY_COUNT -1) * ENEMY_SIZE
ENDIF
	ENEMIES_SIZE:	equ $ - enemies_array
; -----------------------------------------------------------------------------


; =============================================================================
;	Spriteable tiles routines
; -----------------------------------------------------------------------------
IFDEF CFG_MAX_SPRITEABLES
spriteables_data:
spriteables_count:
	rb	1
spriteables_array:
; estado (0 = reposo, [MASK_TILE_SPRITE_DIRECTION | MASK_TILE_SPRITE_PENDING] = movimiento pendiente)
	_SPRITEABLE_STATUS:	equ $ - spriteables_array
	rb	1
; offset del caracter superior izquierdo
	_SPRITEABLE_OFFSET:	equ $ - spriteables_array
	rw	1
; caracteres que definen el tile convertible
	_SPRITEABLE_FOREGROUND:	equ $ - spriteables_array
	rb	4
; caracteres de fondo cubiertos por el tile convertible
	_SPRITEABLE_BACKGROUND:	equ $ - spriteables_array
	rb	4
; atributos del sprite equivalente (patrón, color)
	_SPRITEABLE_SPRATR:	equ $ - spriteables_array
	rb	1	; patrón
	rb	1	; color
	SPRITEABLE_SIZE:		equ $ - spriteables_array
; (resto del array)
	rb	(CFG_MAX_SPRITEABLES -1) * ($ - spriteables_array)
	SPRITEABLES_SIZE:	equ $ - spriteables_array
ENDIF ; CFG_MAX_SPRITEABLES
; =============================================================================

; ;
; ; =============================================================================
; ; 	RAM: optional MSXlib variables
; ; =============================================================================
; ;

; ; -----------------------------------------------------------------------------
; IF (CFG_OPTIONAL_MSX2_OPTIONS > 0)
	; .include	"lib/optional/msx2options.ram.asm"
; ENDIF ; (CFG_OPTIONAL_MSX2_OPTIONS > 0)
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; IF (CFG_OPTIONAL_PT3HOOK > 0)
	; .include	"lib/optional/pt3hook.ram.asm"
; ENDIF ; (CFG_OPTIONAL_PT3HOOK > 0)
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; IF (CFG_VRAM_DELAYED_WRTVRM > 0)
	; .include	"lib/optional/spriteables.ram.asm"
; ENDIF ; (CFG_VRAM_DELAYED_WRTVRM > 0)
; ; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
	; .printtext	" ... msxlib vars"
	; .printhex	$
; -----------------------------------------------------------------------------

; EOF
