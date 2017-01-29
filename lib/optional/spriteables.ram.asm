
;
; =============================================================================
;	Subrutinas para tiles convertibles en sprites
; =============================================================================
;

; Cola de volcados a NAMTBL retrasados
delayed_wrtvrm_count:
	.byte
delayed_wrtvrm_array:
	.ds	DELAYED_WRTVRM_SIZE *3
	
; Variables de tiles convertibles en sprites
spriteables_data:
spriteables_count:
	.byte
spriteables_array:
; estado (0 = reposo, [MASK_TILE_SPRITE_DIRECTION | MASK_TILE_SPRITE_PENDING] = movimiento pendiente)
	; _SPRITEABLE_STATUS	equ $ - spriteables_array
	.byte
; offset del caracter superior izquierdo
	; _SPRITEABLE_OFFSET	equ $ - spriteables_array
	.word
; caracteres que definen el tile convertible
	; _SPRITEABLE_FOREGROUND	equ $ - spriteables_array
	.ds	4
; caracteres de fondo cubiertos por el tile convertible
	; _SPRITEABLE_BACKGROUND	equ $ - spriteables_array
	.ds	4
; atributos del sprite equivalente (patrón, color)
	; _SPRITEABLE_SPRATR	equ $ - spriteables_array
	.byte	; patrón
	.byte	; color
	; SPRITEABLE_SIZE		equ $ - spriteables_array
; (resto del array)
	.ds	(CFG_MAX_SPRITEABLES -1) * ($ - spriteables_array)
	; SPRITEABLES_SIZE	equ $ - spriteables_array

	_SPRITEABLE_STATUS	equ 0
	_SPRITEABLE_OFFSET	equ 1
	_SPRITEABLE_FOREGROUND	equ 3
	_SPRITEABLE_BACKGROUND	equ 7
	_SPRITEABLE_SPRATR	equ 11
	SPRITEABLE_SIZE		equ 13
	SPRITEABLES_SIZE	equ CFG_MAX_SPRITEABLES * SPRITEABLE_SIZE

; EOF
