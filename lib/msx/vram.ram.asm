
; -----------------------------------------------------------------------------
IFDEF LDIRVM_NAMTBL

; NAMTBL buffer in RAM
namtbl_buffer:
	rb	NAMTBL_SIZE

ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
IFDEF LDIRVM_SPRATR

; SPRATR buffer in RAM
spratr_buffer:
	rb	SPRATR_SIZE
.end:
	rb	1 ; to store one SPAT_END when the buffer is full
	
IFDEF CFG_SPRITES_FLICKER
; (extra space for the flickering routine)
	rb	SPRATR_SIZE -CFG_SPRITES_NO_FLICKER *4 -16
; Offset used by the flickering routine
.flicker_offset:
	rb	1
ENDIF

ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
IFDEF CFG_VPOKES

; Vars for "vpoke" routines (deferred WRTVRMs routines)
vpokes:
.count:
	rb	1
.array:
	rb	CFG_VPOKES * VPOKE.SIZE

ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
IFDEF CFG_SPRITEABLES

; Vars for spriteables routines (2x2 chars that eventually become a sprite)
spriteables:
.count:
	rb	1
.array:
; estado (0 = reposo, [MASK_TILE_SPRITE_DIRECTION | MASK_TILE_SPRITE_PENDING] = movimiento pendiente)
	_SPRITEABLE_STATUS:	equ $ - spriteables.array
	rb	1
; offset del caracter superior izquierdo
	_SPRITEABLE_OFFSET_L:	equ $ - spriteables.array
	rb	1
	_SPRITEABLE_OFFSET_H:	equ $ - spriteables.array
	rb	1
; caracteres que definen el tile convertible
	_SPRITEABLE_FOREGROUND:	equ $ - spriteables.array
	rb	4
; caracteres de fondo cubiertos por el tile convertible
	_SPRITEABLE_BACKGROUND:	equ $ - spriteables.array
	rb	4
; atributos del sprite equivalente (patrón, color)
	_SPRITEABLE_PATTERN:	equ $ - spriteables.array
	rb	1	; patrón
	_SPRITEABLE_COLOR:	equ $ - spriteables.array
	rb	1	; color
	SPRITEABLE_SIZE:	equ $ - spriteables.array

; (resto del array)
	rb	(CFG_SPRITEABLES -1) * ($ - spriteables.array)
	spriteables.SIZE:	equ $ - spriteables.array
	
ENDIF
; -----------------------------------------------------------------------------

; EOF
