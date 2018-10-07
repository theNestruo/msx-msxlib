
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
GET_TILE_VALUE:

; Checks screen borders
IFDEF CFG_TILES_VALUE_BORDER
	ld	a, d	; (0..7,   8..247, 248..255)
	add	8	; (8..15, 16..255,   0..7)
	cp	16	; (  c,     nc,       c)
	ld	a, CFG_TILES_VALUE_BORDER
	ret	c ; yes
ENDIF ; IFDEF CFG_TILES_VALUE_BORDER

; no: Checks off-screen
	ld	a, e	; (0..192, 193..255)
	cp	192 +1	; (  c,       nc)
	jr	nc, .OFF_SCREEN ; yes (y >= 192)
	
; no: visible screen
	call	COORDS_TO_OFFSET ; NAMTBL offset in hl
	push	bc
	ld	bc, namtbl_buffer
	add	hl, bc ; NAMTBL buffer pointer in hl
	pop	bc
; reads the tile index (value)
	ld	a, [hl]
	ret
	
.OFF_SCREEN:
; Is over or under visible screen?
				; (225..255, 0..192, 193..224)
	cp	256 -32 +1	; (   nc,      c,         c)
	ld	a, CFG_TILES_VALUE_UNDER
	ret	c ; under visible screen (y - 192 < 32)
; over visible screen (y - 192 > 32  =>  y > -32)
	ld	a, CFG_TILES_VALUE_OVER
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Given some pixel coordinates,
; calculates how many pixels to check and reads the flags of the first tile
; param a: d or e (left/top pixel coordinate)
; param b: width/height in pixels to check
; param de: pixel coordinates (x, y)
; ret hl: NAMTBL buffer pointer
; ret a: tile flags
; ret b: number of tiles to check
GET_FIRST_TILE_FLAGS:
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
	
; Reads the flags of the first tile
	; jp	GET_TILE_FLAGS ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the flags of a tile at some pixel coordinates
; param de: pixel coordinates (x, y)
; ret hl: NAMTBL buffer pointer
; ret a: tile flags
GET_TILE_FLAGS:
	call	GET_TILE_VALUE
	; jp	GET_FLAGS_OF_TILE ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the flags of a tile index (value)
; param a: tile index (value)
; ret a: tile flags
; touches: hl
GET_FLAGS_OF_TILE:
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
.OR:
; Calculates how many tiles to check and reads the first tile flag
	ld	a, e ; from top
	call	GET_FIRST_TILE_FLAGS
; Only one tile?
	dec	b
	ret	z ; yes
	
; no: For each other tile
.LOOP:
	ld	c, a ; current flags in c
; Moves coordinates one tile down
	ld	a, 8
	add	e
	ld	e, a
; Reads the next tile flags
	call	GET_TILE_FLAGS
; OR current tile flags
	or	c
; Next tile
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed (or AND-ed) flags of an horizontal serie of tiles
; param de: left pixel coordinates (x, y)
; param b: width in pixels
; ret a: OR-ed (or AND-ed) tile flags
; touches: hl, bc, de
GET_H_TILE_FLAGS:
.OR:
; Calculates how many tiles to check and reads the first tile flags
	ld	a, d ; from left
	call	GET_FIRST_TILE_FLAGS
; Only one tile?
	dec	b
	ret	z ; yes
	
; no: For each other tile
.OR_LOOP:
	ld	c, a ; current flags in c
; Moves coordinates one tile down
	ld	a, 8
	add	d
	ld	d, a
; Reads the next tile flags
	call	GET_TILE_FLAGS
; OR current tile flags
	or	c
; Next tile
	djnz	.OR_LOOP
	ret

.AND:
; Calculates how many tiles to check and reads the first tile flags
	ld	a, d ; from left
	call	GET_FIRST_TILE_FLAGS
; Only one tile?
	dec	b
	ret	z ; yes
	
; no: For each other tile
.AND_LOOP:
	ld	c, a ; current flags in c
; Moves coordinates one tile down
	ld	a, 8
	add	d
	ld	d, a
; Reads the next tile flags
	call	GET_TILE_FLAGS
; AND current tile flags
	and	c
; Next tile
	djnz	.AND_LOOP
	ret
; -----------------------------------------------------------------------------


; EOF
