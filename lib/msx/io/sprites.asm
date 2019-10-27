
; =============================================================================
;	Logical coordinates sprite routines
; =============================================================================

; TODO: Support for CFG_SPRITES_EC_AWARE in MOVE_SPRITE[S]

; -----------------------------------------------------------------------------
; (direct pointers inside SPRATR buffer)
IFDEF CFG_SPRITES_RESERVED
	volatile_sprites:	equ spratr_buffer + CFG_SPRITES_RESERVED *4
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Resets the volatile sprites
RESET_SPRITES:
; Fills with Y = SPAT_END
IFDEF CFG_SPRITES_RESERVED
	ld	hl, volatile_sprites
	ld	de, 4
	ld	b, (spratr_buffer.end - volatile_sprites) /4
ELSE
	ld	hl, spratr_buffer
	ld	de, 4
	ld	b, (spratr_buffer.end - spratr_buffer) /4
ENDIF
.LOOP:
	ld	[hl], SPAT_END
; Skip to the next sprite
	add	hl, de
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Appends a volatile sprite using logical coordinates
; param de: logical coordinates (x, y)
; param bc: attributes (pattern, color)
; touches: a, hl
PUT_SPRITE:
IFDEF CFG_SPRITES_RESERVED
	ld	hl, volatile_sprites
ELSE
	ld	hl, spratr_buffer
ENDIF
	ld	a, SPAT_END
.LOOP:
	cp	[hl]
	jr	z, .HL_OK
; Skip to the next sprite
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	jr	.LOOP
.HL_OK:

; Saves the values in the SPRATR buffer
; y
	ld	a, e
	add	CFG_SPRITES_Y_OFFSET
	ld	[hl], a
; x: Early clock bit required?
	inc	hl
	ld	a, d
	sub	-CFG_SPRITES_X_OFFSET
	jr	nc, .NO_EC ; no
; yes
	add	32 ; (32 pixels because SPAT_EC)
	ld	[hl], a
; set SPAT_EC in color byte
	ld	a, b
	or	SPAT_EC
	ld	b, a
	jr	.PATTERN_COLOR
.NO_EC:
	ld	[hl], a

.PATTERN_COLOR:
; pattern
	inc	hl
	ld	[hl], c
; color
	inc	hl
	ld	[hl], b
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Appends a volatile sprite using physical coordinates
; param de: physical coordinates (x, y)
; param bc: attributes (pattern, color)
; touches: a, hl
PUT_SPRITE_NO_OFFSET:
; Locates the SPAT_END
IFDEF CFG_SPRITES_RESERVED
	ld	hl, volatile_sprites
ELSE
	ld	hl, spratr_buffer
ENDIF
	ld	a, SPAT_END
.LOOP:
	cp	[hl]
	jr	z, .HL_OK
; Skip to the next sprite
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	jr	.LOOP
.HL_OK:

; Saves the values in the SPRATR buffer
	ld	[hl], e
	inc	hl
	ld	[hl], d
	inc	hl
	ld	[hl], c
	inc	hl
	ld	[hl], b
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves a set of sprites in the SPRATR buffer,
; and sets their patterns consecutive (after reading the first one)
; param hl: SPRATR buffer pointer
; param de: logical coordinates (x, y)
; param b: number of consecutive sprites to move and set the pattern
MOVE_SPRITES:
	djnz	.MULTI
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Moves one sprites in the SPRATR buffer
; param hl: SPRATR buffer pointer
; param de: logical coordinates (x, y)
MOVE_SPRITE:
	ld	a, e ; y -= 16, y--
	add	CFG_SPRITES_Y_OFFSET
	ld	e, a
	ld	a, d ; x -= 8
	add	CFG_SPRITES_X_OFFSET
	ld	d, a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Moves one sprites in the SPRATR buffer
; param hl: SPRATR buffer pointer
; param de: physical coordinates (x, y)
MOVE_SPRITE_NO_OFFSET:
	ld	[hl], e
	inc	hl
	ld	[hl], d
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; (continued from MOVE_SPRITES)
MOVE_SPRITES.MULTI:
; moves the first sprite
	call	MOVE_SPRITE
; reads first sprite pattern
	inc	hl
	ld	a, [hl]
.LOOP:
; next sprite
	inc	hl
	inc	hl
	call	MOVE_SPRITE_NO_OFFSET
; sets next sprite pattern
	inc	hl
	add	a, 4
	ld	[hl], a
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; EOF
