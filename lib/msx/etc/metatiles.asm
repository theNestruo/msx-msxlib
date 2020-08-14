
; =============================================================================
;	Metatiles routines for NAMBTL buffer
; =============================================================================

IFEXIST UNPACK

; -----------------------------------------------------------------------------
; Prints a meta-tiles based screen using the decompression buffer
; param hl: packed meta-tiles based screen definition
; param de: NAMTBL buffer destination pointer
; param bc: [width, height] of the block (in meta-tiles)
UNPACK_PRINT_METATILE_BLOCK:
	push	de ; preserves NAMTBL buffer destination
	push	bc ; preserves size
; Unpacks
	ld	de, unpack_buffer
	push	de ; preserves buffer address
	call	UNPACK
; Prints the meta-tiles based screen
	pop	hl ; restores buffer address (in hl)
	pop	bc ; restores size
	pop	de ; restores NAMTBL buffer destination
	; jp	LDIRVM ; falls through
; ------VVVV----falls through--------------------------------------------------

ENDIF ; IFEXIST UNPACK

; -----------------------------------------------------------------------------
; Prints a meta-tiles based screen
; param hl: meta-tiles based screen definition
; param de: NAMTBL buffer destination pointer
; param bc: [width, height] of the block (in meta-tiles)
PRINT_METATILE_BLOCK:
	push	bc ; (preserves width and counter)
	call	PRINT_METATILE_ROW
	pop	bc ; (restores width and counter)
	dec	c
	jr	nz, PRINT_METATILE_BLOCK
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints a row of meta-tiles
; param hl: meta-tiles based screen definition pointer
; param de: NAMTBL buffer destination pointer
; param b: width of the block (in meta-tiles)
; ret hl: updated meta-tiles based screen definition pointer
; ret de: updated NAMTBL buffer destination pointer (next row)
PRINT_METATILE_ROW:
	push	de ; (preservs NAMTBL buffer destination pointer)
.LOOP:
	push	bc ; (preserves counter)
	push	hl ; (preserves screen definition pointer)
	ld	a, [hl]
	call	PRINT_METATILE
	pop	hl ; (restores screen definition pointer)
	inc	hl
	pop	bc ; (restores counter)
	djnz	.LOOP
; Moves the destination pointer to the next row
	pop	de ; (restore NAMTBL buffer destination pointer)
	ld	a, SCR_WIDTH * 2
	jp	ADD_DE_A
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints a 16x16 pixeles (2x2 chars) meta-tile
; param a: meta-tile index (0..255)
; param de: NAMTBL buffer destination pointer
; ret de: updated NAMTBL buffer destination pointer
PRINT_METATILE:
; Locates the meta-tile definition
	ld	hl, TILESET
	ld	c, a ; hl += 4*a
	ld	b, 0
	add	hl, bc
	add	hl, bc
	add	hl, bc
	add	hl, bc

; Copies two upper bytes/chars of the meta-tile to the destination
	ldi
	ldi

	push	de ; (preserves updated NAMTBL buffer destination pointer)
; Moves the destination pointer to the lower left byte/char
	ld	a, SCR_WIDTH -2 ; (one line except for the two chars already copied)
	call	ADD_DE_A
; Copies the two lower bytes/chars of the meta-tile to the destination
	ldi
	ldi

	pop	de ; (restores updated NAMTBL buffer destination pointer)
	ret
; -----------------------------------------------------------------------------

; EOF
