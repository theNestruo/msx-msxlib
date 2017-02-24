
		ld	a,($2d)		; read MSX version
		or	a		; is it MSX1?
		ret	z		; then there's no need to use it anyway
		ld	a,(7)		; get first VDP write port
		ld	c,a
		inc	c		; prepare to write register data
		di			; interrupts could screw things up
		xor	a		; from color 0
		out	(c),a
		ld	a,128+16	; write R#16
		out	(c),a
		ei
		inc	c		; prepare to write palette data
		ld	b,32		; 16 color * 2 bytes for palette data
		ld	hl,palette
		otir
		ret
;
; the format of the palette is like $GRB
; and R, G and B must be between 0-7
; currently it's the default MSX2 palette
; but you set up your own in these dw's
;
palette:
	dw	$000, $000, $611, $733, $117, $327, $151, $627
	dw	$171, $373, $661, $664, $411, $265, $555, $777
		
		
; enhanced color palette
; CoolColors (c) Fabio R. Schmidlin, 1997

	dw	$000, $000, $523, $634, $215, $326, $251, $537
	dw	$362, $472, $672, $774, $412, $254, $555, $777
