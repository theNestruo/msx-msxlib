
; =============================================================================
;	Sprite-tile helper routines
; =============================================================================

; -----------------------------------------------------------------------------
; Bit index for the default tile properties
	BIT_WORLD_SOLID:	equ 0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Translate pixel coordinates to NAMTBL offsets
; param de: pixel coordinates (x, y)
; ret hl: NAMTBL offset
; touches: a
COORDS_TO_OFFSET:
; y part: hl = y / 8 * 32
	ld	a, e
	and	$f8 ; equivalent to /8 *8
	ld	h, 0
	ld	l, a
	add	hl, hl
	add	hl, hl
; x part: a = x / 8
	ld	a, d
	srl	a
	srl	a
	srl	a
; hl += a
	add	l
	ld	l, a
	adc	h
	sub	l
	ld	h, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Translates NAMTBL buffer pointers to pixel coordinates
; param hl: NAMTBL buffer pointer
; ret hl: NAMTBL offset
; ret de: pixel coordinates (y, x) (CAUTION: order is reversed)
; touches: a, hl
NAMTBL_POINTER_TO_COORDS:
	ld	de, -namtbl_buffer + $10000 ; de = hl -namtbl_buffer +SCR_WIDTH
	add	hl, de
	ex	de, hl
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Translates NAMTBL offsets to pixel coordinates
; param de: NAMTBL offset
; ret de: pixel coordinates (y, x) (CAUTION: order is reversed)
; touches: a
OFFSET_TO_COORDS:
; y = (de / 32) *8 = (de / 4) mod 8
	ld	a, e ; a instead of e to preserve e
	srl	d
	rr	a
	srl	d
	rr	a
	and	$f8
	ld	d, a
; x = (de mod 32) *8 = (e * 8)
	sla	e
	sla	e
	sla	e
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Translates NAMTBL offsets to logical coordinates
; (i.e: below the center of the character pointed by NAMTBL offset)
; param de: NAMTBL offset
; ret de: pixel coordinates (x, y)
; touches: a
NAMTBL_POINTER_TO_LOGICAL_COORDS:
	call	NAMTBL_POINTER_TO_COORDS
; Translates into logical coordinates (also reverses (y,x) order)
	ex	de, hl ; coordinates in hl
	ld	a, l ; (x += 4px, half tile right)
	add	4
	ld	d, a
	ld	a, h ; (y += 8px, one tile down)
	add	8
	ld	e, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the tile index (value) at some pixel coordinates
; param de: pixel coordinates (x, y)
; ret hl: NAMTBL buffer pointer
; ret a: tile index (value)
; touches: de
GET_TILE_VALUE:
; Checks off-screen
	ld	a, e
	sub	192 -1
	jr	nc, .OFF_SCREEN ; yes (y >= 192)
; no: visible screen. Checks border
	ld	a, d
	add	8
	cp	16
	jr	c, .BORDER
; no
	call	COORDS_TO_OFFSET ; NAMTBL offset in hl
	ld	de, namtbl_buffer
	add	hl, de ; NAMTBL buffer pointer in hl
; reads the tile index (value)
	ld	a, [hl]
	ret
	
.OFF_SCREEN:
; Is over or under visible screen?
	cp	32 +1
	ld	a, CFG_TILES_VALUE_UNDER
	ret	c ; under visible screen (y - 192 < 32)
; over visible screen (y - 192 > 32  =>  y > -32)
	ld	a, CFG_TILES_VALUE_OVER
	ret
	
.BORDER:
	ld	a, CFG_TILES_VALUE_BORDER
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the flags of a tile index (value)
; param a: tile index (value)
; ret a: tile flags
; touches: hl
GET_TILE_FLAGS:
	ld	hl, TILE_FLAGS_TABLE
.LOOP:
; Is tile index "up to index"?
	cp	[hl]
	inc	hl ; hl = flags
	jr	c, .OK ; yes (lower)
	jr	z, .OK ; yes (equal)
; no
	inc	hl ; hl = up to index (next group)
	jr	.LOOP

.OK:
	ld	a, [hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of a vertical serie of tiles
; param de: upper pixel coordinates (x, y)
; param b: height in pixels
; ret a: OR-ed tile flags
; touches: hl, bc, de
GET_V_TILE_FLAGS:
; Calculates how many tiles to check
	ld	a, e ; from top
	call	HOW_MANY_TILES
; First tile
	call	GET_TILE_VALUE ; also: NAMTBL buffer pointer in hl
; Only one tile?
	dec	b
	jp	z, GET_TILE_FLAGS ; yes
	
; no: reads first tile flags
	ex	de, hl ; NAMTBL buffer pointer in de
	call	GET_TILE_FLAGS
; For each other tile
.LOOP:
	ld	c, a ; current flags in c
	push	bc ; preserves counter and current flags
; Reads the next tile
	call	.GET_NEXT_TILE_FLAGS
; ; Moves pointer one tile down
	; ld	a, SCR_WIDTH
	; add	e ; de += a => de += 32
	; ld	e, a
	; adc	d
	; sub	e
	; ld	d, a
; ; Reads other tile
	; ld	a, [de]
	; call	GET_TILE_FLAGS
	pop	bc ; restores counter and previous flags
; OR tile flags
	or	c
; Next tile
	djnz	.LOOP
	ret
	
.GET_NEXT_TILE_FLAGS:
; Moves pointer one tile down
	ld	a, SCR_WIDTH
	add	e ; de += a => de += 32
	ld	e, a
	adc	d
	sub	e
	ld	d, a
; Reads other tile
	ld	a, [de]
	jp	GET_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of an horizontal serie of tiles
; param de: left pixel coordinates (x, y)
; param b: width in pixels
; ret a: OR-ed tile flags
; touches: hl, bc, de
GET_H_TILE_FLAGS:
.OR:
; Calculates how many tiles to check and reads the first tile
	call	.FIRST
; Only one tile?
	dec	b
	jp	z, GET_TILE_FLAGS ; yes
; no: reads first tile flags
	ex	de, hl ; NAMTBL buffer pointer in de
	call	GET_TILE_FLAGS
; Reads each other tile and ORs the tile flags
.OR_LOOP:
	ld	c, a ; current flags in c
	call	.NEXT
	or	c
	djnz	.OR_LOOP
	ret

; Returns the AND-ed flags of an horizontal serie of tiles
; param de: left pixel coordinates (x, y)
; param b: width in pixels
; ret a: AND-ed tile flags
; touches: hl, bc, de
.AND:
; Calculates how many tiles to check and reads the first tile
	call	.FIRST
; Only one tile?
	dec	b
	jp	z, GET_TILE_FLAGS ; yes
; no: reads first tile flags
	ex	de, hl ; NAMTBL buffer pointer in de
	call	GET_TILE_FLAGS
; Reads each other tile and ORs the tile flags
.AND_LOOP:
	ld	c, a ; current flags in c
	call	.NEXT
	and	c
	djnz	.AND_LOOP
	ret

; ret a: first tile value
; ret b: number of tiles to check
; ret hl: NAMTBL buffer pointer
.FIRST:
; Calculates how many tiles to check
	ld	a, d ; forom left
	call	HOW_MANY_TILES
; First tile
	jp	GET_TILE_VALUE ; also: NAMTBL buffer pointer in hl

; ret a: next tile flags
.NEXT:
	push	bc ; preserves counter and current flags
; Moves pointer one tile right
	inc	de
; Reads other tile
	ld	a, [de]
	call	GET_TILE_FLAGS
	pop	bc ; restores counter and previous flags
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Calculates how many pixels to check
; param a: left/top pixel coordinate
; param b: width/height in pixels
; ret b: number of tiles to check
HOW_MANY_TILES:
; Calculates how many pixels to check
	and	$07	; pixels = x mod 8 (sub tile)
	add	b	;     ... +height
	dec	a	;     ... -1
; Calculates how many tiles to check
	srl	a ; tiles = pixels / 8
	srl	a
	srl	a
	inc	a ;	... +1
	ld	b, a ; number of tiles in b
	ret
; -----------------------------------------------------------------------------


; EOF
