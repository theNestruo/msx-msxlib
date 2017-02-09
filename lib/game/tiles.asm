
; =============================================================================
;	Sprite-tile helper routines
; =============================================================================

; -----------------------------------------------------------------------------
; Bit index for the default tile properties
	BIT_WORLD_SOLID:	equ 0
	BIT_WORLD_FLOOR:	equ 1
	BIT_WORLD_STAIRS:	equ 2
	BIT_WORLD_DEATH:	equ 3
	BIT_WORLD_WALK_ON:	equ 4 ; Tile collision (single char)
	BIT_WORLD_WIDE_ON:	equ 5 ; Wide tile collision (player width)
	BIT_WORLD_WALK_OVER:	equ 6 ; Walking over tiles (player width)
	BIT_WORLD_PUSHABLE:	equ 7 ; Pushable tiles (player height)
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
	jp	ADD_HL_A
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
; no: visible screen
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
CHECK_V_TILES:
; Calculates how many pixels to check
	ld	a, e
	and	$07	; y mod 8 (sub tile)
	add	b	;     ... +height
	dec	a	;     ... -1
; Calculates how many tiles to check
	srl	a
	srl	a
	srl	a
	inc	a
	ld	b, a ; number of tiles in b
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
; Moves pointer one tile down
	ld	a, SCR_WIDTH
	add	e ; de += a => de += 32
	ld	e, a
	adc	d
	sub	e
	ld	d, a
; Reads other tile
	ld	a, [de]
	call	GET_TILE_FLAGS
	pop	bc ; restores counter and previous flags
; OR tile flags
	or	c
; Next tile
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of an horizontal serie of tiles
; param de: left pixel coordinates (x, y)
; param b: width in pixels
; ret a: OR-ed tile flags
CHECK_H_TILES:
; Calculates how many pixels to check
	ld	a, d
	and	$07	; x mod 8 (sub tile)
	add	b	;     ... +height
	dec	a	;     ... -1
; Calculates how many tiles to check
	srl	a
	srl	a
	srl	a
	inc	a
	ld	b, a ; almacena en b
	ld	b, a ; number of tiles in b
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
; Moves pointer one tile right
	inc	hl
; Reads other tile
	ld	a, [de]
	call	GET_TILE_FLAGS
	pop	bc ; restores counter and previous flags
; OR tile flags
	or	c
; Next tile
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; EOF
