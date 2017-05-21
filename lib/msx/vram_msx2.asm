
; =============================================================================
;	Palette routines for MSX2 VDP
; =============================================================================

; -----------------------------------------------------------------------------
; Sets the color palette
; param hl: palette as sixteen $0RGB values (with R, G, B in 0..7)
SET_PALETTE:
; Reads the first VDP write port
	ld	a, [VDP_DW]
	ld	c, a
; Prepare to write register data from color 0
	inc	c
	xor     a
	di
	out     [c], a
; Write register #16
	ld      a, $80 or 16
	ei	; (interruptions enabled after the next instruction)
	out     [c], a
; Writes palette data (16 color * 2 bytes)
	ld	b, 16 * 2
	inc	c
	otir
	ret
; -----------------------------------------------------------------------------

; EOF
