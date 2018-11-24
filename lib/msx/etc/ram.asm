
IFDEF CFG_RAM_ATTRACT_PRINT
; -----------------------------------------------------------------------------
; Variables for: Attract-mode text-printing routines
attract_print:

.source:
	rw	1 ; source pointer
.target_line:
	rw	1 ; destination pointer (current line)
.target_char:
	rw	1 ; destination pointer (current character)
.framecounter:
	rb	1 ; frame counter for slow printing
; -----------------------------------------------------------------------------
ENDIF


IFDEF CFG_RAM_VPOKES
; -----------------------------------------------------------------------------
; Variables for: "vpoke" routines (deferred WRTVRMs routines)
vpokes:
.count:
	rb	1
.array:
	rb	CFG_VPOKES * VPOKE.SIZE
; -----------------------------------------------------------------------------
ENDIF


IFDEF CFG_RAM_SPRITEABLES
; -----------------------------------------------------------------------------
; Variables for: Spriteables routines (2x2 chars that eventually become a sprite)
spriteables:
.count:
	rb	1
.array:
; status:
; 0 = idle
; [MASK_TILE_SPRITE_DIRECTION | MASK_TILE_SPRITE_PENDING] = movement still pending)
	_SPRITEABLE_STATUS:	equ $ - spriteables.array
	rb	1
; offset of the upper left character
	_SPRITEABLE_OFFSET_L:	equ $ - spriteables.array
	rb	1
	_SPRITEABLE_OFFSET_H:	equ $ - spriteables.array
	rb	1
; characters that define the spriteable
	_SPRITEABLE_FOREGROUND:	equ $ - spriteables.array
	rb	4
; background characters covered by the spriteable
	_SPRITEABLE_BACKGROUND:	equ $ - spriteables.array
	rb	4
; equivalent sprite attributes
	_SPRITEABLE_PATTERN:	equ $ - spriteables.array
	rb	1	; pattern
	_SPRITEABLE_COLOR:	equ $ - spriteables.array
	rb	1	; color
	SPRITEABLE_SIZE:	equ $ - spriteables.array

; (array)
	rb	(CFG_SPRITEABLES -1) * ($ - spriteables.array)
	spriteables.SIZE:	equ $ - spriteables.array
; -----------------------------------------------------------------------------
ENDIF

; EOF
