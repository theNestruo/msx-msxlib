
; =============================================================================
;	Palette routines for MSX2 VDP
; =============================================================================

; -----------------------------------------------------------------------------
; Makes color 0 transparent or solid
; Does nothing if the MSX does not have MSX2 VDP or greater
SET_COLOR_0:

; Makes color 0 transparent (normal)
; touches a, bc, hl
.NORMAL:
; MSX2 VDP?
	call	CHECK_MSX2_VDP
	ret	z ; not MSX2
.NORMAL_NO_CHECK:
; Resets TP bit for transparent
	ld	hl, RG08SAV
	res	5, [hl] ; TP: Transparent from palette (0=Normal, 1=Color 0 is solid)
	jr	.WRTVDP_8

; Makes color 0 solid (black by default)
; touches a, bc, hl
.SOLID:
; MSX2 VDP?
	call	CHECK_MSX2_VDP
	ret	z ; not MSX2
.SOLID_NO_CHECK:
; Sets TP bit for black
	ld	hl, RG08SAV
	set	5, [hl] ; TP: Transparent from palette (0=Normal, 1=Color 0 is solid)
.WRTVDP_8:
	ld	b, [hl]
	ld	c, 8
	jp	WRTVDP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sets the color palette
; Does nothing if the MSX does not have MSX2 VDP or greater
; param hl: palette as sixteen $0GRB values (with R, G, B in 0..7)
; touches a, bc, hl
SET_PALETTE:
; MSX2 VDP?
	call	CHECK_MSX2_VDP
	ret	z ; not MSX2
.NO_CHECK:
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
; Checks if the MSX does have MSX2 VDP or greater
; ret z/nz: does not/does have MSX2 VDP or greater
; touches a
CHECK_MSX2_VDP:
; MSX2 VDP?
	ld	a, [MSXID3]
	or	a
	ret	; ret z/nz
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
IFDEF CFG_INIT_DISABLE_PALETTE
ELSE
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
ENDIF ; IFEXIST CFG_CUSTOM_PALETTE
ENDIF ; IFDEF CFG_INIT_DISABLE_PALETTE
; -----------------------------------------------------------------------------

; EOF
