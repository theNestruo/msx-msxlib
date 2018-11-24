
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

; -----------------------------------------------------------------------------
; Default palettes used during initialization
DEFAULT_PALETTE:

; TMS approximate (Wolf's Polka)
.TMS_APPROXIMATE:
	dw	$0000, $0000, $0522, $0623, $0326, $0337, $0261, $0637
	dw	$0272, $0373, $0561, $0674, $0520, $0355, $0666, $0777
	
; Default MSX2 palette
.MSX2:
	dw	$0000, $0000, $0611, $0733, $0117, $0327, $0151, $0627
	dw	$0171, $0373, $0661, $0664, $0411, $0265, $0555, $0777
	
IFEXIST CFG_CUSTOM_PALETTE
ELSE
; CoolColors (c) Fabio R. Schmidlin, 1997
.COOL_COLORS:
	dw	$0000, $0000, $0523, $0634, $0215, $0326, $0251, $0537
	dw	$0362, $0472, $0672, $0774, $0412, $0254, $0555, $0777
ENDIF ; CFG_CUSTOM_PALETTE
; -----------------------------------------------------------------------------

; EOF
