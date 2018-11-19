
; =============================================================================
;	VRAM routines (BIOS-based)
;	NAMBTL and SPRATR buffer routines (BIOS-based)
;	NAMTBL buffer text routines
;	Logical coordinates sprite routines
; =============================================================================

; -----------------------------------------------------------------------------
; TO DO list:
;	Support for CFG_SPRITES_EC_AWARE in MOVE_SPRITE[S]
;	Support for CFG_SPRITES_FLICKERING
; -----------------------------------------------------------------------------

; =============================================================================
;	VRAM routines (BIOS-based)
; =============================================================================

; -----------------------------------------------------------------------------
; LDIRVM with repetition
; (original routine: COPY_BLOCK by Eduardo A. Robsy Petrus)
; param hl: RAM source address
; param de: VRAM destination address
; param b: blocks to copy
LDIRVM_BLOCKS:
	push	bc ; preserves counter
	push	hl ; preserves source
	push	de ; preserves destination
; Blits a block
	ld	bc, 8 ; 8b
	call	LDIRVM
	pop	hl ; restores destination in hl
	ld	bc, 8 ; hl += 8
	add	hl, bc
	ex	de, hl ; updated destination in de
	pop	hl ; restores source
	pop	bc ; restores counter
	djnz	LDIRVM_BLOCKS
	ret
; -----------------------------------------------------------------------------

IFEXIST UNPACK

; -----------------------------------------------------------------------------
; Unpacks to VRAM using the decompression buffer
; param hl: packed data source address
; param de: VRAM destination address
; param bc: uncompressed data size
UNPACK_LDIRVM:
	push	de ; preserves VRAM destination
	push	bc ; preserves size
; Unpacks
	ld	de, unpack_buffer
	push	de ; preserves buffer address
	call	UNPACK
; LDIRVM
	pop	hl ; restores buffer address (in hl)
	pop	bc ; restores size
	pop	de ; restores VRAM destination
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacks CHRTBL to the three banks
; param hl: packed CHRTBL source address
UNPACK_LDIRVM_CHRTBL:
	ld	de, unpack_buffer
	call	UNPACK
	; jr	LDIRVM_CHRTBL ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM the decompresison buffer to the three CHRTBL banks
LDIRVM_CHRTBL:
	ld	de, CHRTBL
	call	LDIRVM_CHRTBL_BANK
	ld	de, CHRTBL + CHRTBL_SIZE
	call	LDIRVM_CHRTBL_BANK
	ld	de, CHRTBL + CHRTBL_SIZE + CHRTBL_SIZE
	jr	LDIRVM_CHRTBL_BANK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacks CLRTBL to the three banks
; param hl: packed CLRTBL source address
UNPACK_LDIRVM_CLRTBL:
	ld	de, unpack_buffer
	call	UNPACK
	; jr	LDIRVM_CLRTBL ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM the decompresison buffer to the three CLRTBL banks
LDIRVM_CLRTBL:
	ld	de, CLRTBL
	call	LDIRVM_CLRTBL_BANK
	ld	de, CLRTBL + CHRTBL_SIZE
	call	LDIRVM_CLRTBL_BANK
	ld	de, CLRTBL + CHRTBL_SIZE + CHRTBL_SIZE
	; jr	LDIRVM_CLRTBL_BANK
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM the decompresison buffer to one CHRTBL or CLRTBL bank
; param de: VRAM destination address
LDIRVM_CHRTBL_BANK:
LDIRVM_CLRTBL_BANK:
	ld	hl, unpack_buffer
	ld	bc, CHRTBL_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

ENDIF ; IFEXIST UNPACK


; =============================================================================
;	NAMBTL and SPRATR buffer routines (BIOS-based)
; =============================================================================

; -----------------------------------------------------------------------------
; Fills the NAMTBL buffer with the blank space character ($20, " " ASCII)
CLS_NAMTBL:
	ld	hl, namtbl_buffer
	ld	de, namtbl_buffer + 1
	ld	bc, NAMTBL_SIZE - 1
	ld	[hl], $20 ; " " ASCII
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Fills the SPRATR buffer with the SPAT_END marker value
CLS_SPRATR:
	ld	hl, spratr_buffer
	ld	de, spratr_buffer + 1
	ld	bc, SPRATR_SIZE - 1
	ld	[hl], SPAT_END
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM the NAMTBL buffer
LDIRVM_NAMTBL:
	ld	hl, namtbl_buffer
	ld	de, NAMTBL
	ld	bc, NAMTBL_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM the SPRATR buffer
LDIRVM_SPRATR:
IFDEF CFG_SPRITES_FLICKER
; Has the VDP reported a 5th sprite?
	ld	a, [STATFL]
	bit	6, a
	jr	z, .NO_FLICKER ; no: non-flickering LDIRVM
IF CFG_SPRITES_NO_FLICKER != 0
; yes: Is the 5th sprite one of the no-flicker ones?
	and	$0f
	sub	CFG_SPRITES_NO_FLICKER
	jr	c, .NO_FLICKER ; yes: non-flickering LDIRVM
ENDIF

; Counts how many actual sprites are in the buffer
	ld	hl, spratr_buffer + CFG_SPRITES_NO_FLICKER *4
	ld	a, SPAT_END
	ld	c, CFG_SPRITES_NO_FLICKER
.LOOP:
	cp	[hl]
	jr	z, .C_OK
	inc	c
; Skips to the next sprite
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	jr	.LOOP
.C_OK:
; Enough sprites in this frame to apply the flickering routine?
IF CFG_SPRITES_NO_FLICKER < 4
	ld	a, 4 ; (at least five sprites)
ELSE
	ld	a, CFG_SPRITES_NO_FLICKER + 1 ; (at least 2 flickering sprites)
ENDIF
	cp	c
	jr	nc, .NO_FLICKER ; no: non-flickering LDIRVM
; yes
	push	hl ; (preserves actual spratr buffer end)
	
; Calculates flicker size (in bytes)
IF CFG_SPRITES_NO_FLICKER != 0
	ld	a, -CFG_SPRITES_NO_FLICKER ; c (size, bytes) = (c -CFG_SPRITES_NO_FLICKER) * 4
	add	c
	add	a
	add	a
	ld	c, a
ELSE
	sla	c ; c (size, bytes) = c * 4
	sla	c
ENDIF

; Reads the 5th sprite plane
	ld	a, [STATFL]
	and	$0f
; Computes the new flickering offset
	sub	CFG_SPRITES_NO_FLICKER
	sla	a ; a (offset, bytes) = a *4
	sla	a
	ld	hl, spratr_buffer.flicker_offset
	add	[hl]
; Is the offset beyond the actual flickering size?
	cp	c ; (size, bytes)
	jr	c, .OFFSET_OK ; no
; yes: tries to loop around
	sub	c ; (size, bytes)
	jr	z, .OFFSET_ZERO ; (the offset got reset)
; Is the offset still beyond the actual flickering size?
	cp	c ; (size, bytes)
	jr	c, .OFFSET_OK ; no
; yes: The flickering size has changed between frames; resets the offset
	xor	a
.OFFSET_ZERO:
; Preserves the offset for the next frame
	ld	[hl], a
	jr	.POP_AND_NO_FLICKER ; non-flickering LDIRVM
	
.OFFSET_OK:
; Preserves the offset for the next frame
	ld	[hl], a

; Copies the sprites before the offset at the actual end of the spratr buffer
	ld	hl, spratr_buffer + CFG_SPRITES_NO_FLICKER *4
	pop	de ; de = actual spratr buffer end
	ld	b, 0 ; bc = offset
	ld	c, a
	push	bc ; (preserves offset)
	ldir
; Appends a SPAT_END (just in case)
	ld	a, SPAT_END
	ld	[de], a
	
IF CFG_SPRITES_NO_FLICKER != 0
; LDIRVM the non-flickering sprites
	ld	hl, spratr_buffer
	ld	de, SPRATR
	ld	bc, CFG_SPRITES_NO_FLICKER *4
	call	LDIRVM
ENDIF
; LDIRVM the sprites, starting from the offset
	ld	hl, spratr_buffer + CFG_SPRITES_NO_FLICKER *4
	pop	bc ; (restores offset)
	add	hl, bc
	ld	de, SPRATR + CFG_SPRITES_NO_FLICKER *4
	ld	bc, SPRATR_SIZE - CFG_SPRITES_NO_FLICKER *4
	jp	LDIRVM
	
.POP_AND_NO_FLICKER:
	pop	hl ; (restores stack status)
.NO_FLICKER:
ENDIF ; IFDEF CFG_SPRITES_FLICKER

; LDIRVM the actual SPRATR buffer
	ld	hl, spratr_buffer
	ld	de, SPRATR
	ld	bc, SPRATR_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Disables the screen, clears NAMTBL and disables sprites
DISSCR_NO_FADE:
; Disables the screen
	halt	; (sync before disabling screen)
	call	DISSCR
.CLEAR:
; Clears NAMTBL
	ld	hl, NAMTBL
	ld	bc, NAMTBL_SIZE
	ld	a, $20 ; " " ASCII
	call	FILVRM
; Disables sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	jp	WRTVRM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Fade out (horizontal sweep)
; Disables the screen, clears NAMTBL and disables sprites
DISSCR_FADE_OUT:
	halt	; (sync before disabling sprites / first column)
; Disables sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Checks if the screen is already disabled
	ld	hl, RG1SAV
	bit	6, [hl]
	ret	z ; yes: do nothing

IFDEF CFG_FADE_TYPE_DOUBLE
; Fade out (double)
	ld	b, SCR_WIDTH /2
.COL2:
	push	bc ; preserves counter
; Erases the left column
	ld	a, SCR_WIDTH /2
	sub	b
	ld	c, b ; (preserves counter in c)
	call	WRTVRM_NAMTBL_COLUMN_OUT ; (c untouched)
; Prints the right column
	ld	a, SCR_WIDTH /2 -1
	add	c
	call	WRTVRM_NAMTBL_COLUMN_OUT
; (sync)
	halt
; Moves left a position
	pop	bc ; restores contadore
	djnz	.COL2

ELSE
; Fade out (simple)
	ld	b, SCR_WIDTH
.COL:
	push	bc ; preserves counter
; Erases the column
	ld	a, SCR_WIDTH
	sub	b
	call	WRTVRM_NAMTBL_COLUMN_OUT
; (sync)
	halt
; Moves right a position
	pop	bc ; restores contadore
	djnz	.COL

ENDIF ; IFDEF CFG_FADE_TYPE_DOUBLE

; Disables the screen
	jp	DISSCR
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM the NAMTBL and SPRATR buffers and enables the screen
ENASCR_NO_FADE:
; LDIRVM the NAMTBL and SPRATR buffers
	halt	; (sync in case screen was enabled)
	call	LDIRVM_NAMTBL
	call	LDIRVM_SPRATR
; Enables the screen
	halt	; (sync before enabling screen)
	jp	ENASCR
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Fade in (horizontal sweep)
; LDIRVM the NAMTBL and SPRATR buffer and enables the screen
; If the screen is already enabled, defaults to LDIRVM_NAMTBL_FADE_INOUT
ENASCR_FADE_IN:
	halt	; (sync in case screen was enabled)
	
; Checks if the screen is already enabled
	ld	hl, RG1SAV
	bit	6, [hl]
	jr	nz, LDIRVM_NAMTBL_FADE_INOUT ; yes: uses fade in/out
	
; No: clears NAMTBL and disables sprites
	; halt	; (sync in case screen was enabled)
	call	DISSCR_NO_FADE.CLEAR
; Enables the screen
	halt	; (sync before enabling screen)
	call	ENASCR
; And starts the fade in
	; jr	LDIRVM_NAMTBL_FADE_INOUT ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Fade in/out (horizontal sweep)
; from current VRAM NAMTBL contents to NAMTBL buffer contents
LDIRVM_NAMTBL_FADE_INOUT:
; Disables sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

.KEEP_SPRITES:
IFDEF CFG_FADE_TYPE_DOUBLE
; Fade in (double)
	ld	b, SCR_WIDTH /2
.COL2:
	push	bc ; preserves counters
; Prints the left column
	ld	a, b
	dec	a
	ld	c, b ; (preserves counter in c)
	call	LDIRVM_NAMTBL_COLUMN ; (c untouched)
; Prints the right column
	ld	a, SCR_WIDTH
	sub	c
	call	LDIRVM_NAMTBL_COLUMN
; (sync)
	halt
; Moves left a position
	pop	bc ; restores contadores
	djnz	.COL2
	
ELSE
; Fade in (simple)
	ld	b, SCR_WIDTH
.COL:
	push	bc ; preserves counters
; Prints the column
	ld	a, SCR_WIDTH
	sub	b
	call	LDIRVM_NAMTBL_COLUMN
; (sync)
	halt
; Moves right a position
	pop	bc ; restores contadores
	djnz	.COL
ENDIF ; IFDEF CFG_FADE_TYPE_DOUBLE

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Clears just a column of the NAMTBL
; param a: the column to LDIRVM (0..31)
; tocuhes af, b, de, hl
WRTVRM_NAMTBL_COLUMN_OUT:
; Calculates the destination address
	ld	hl, NAMTBL
	call	ADD_HL_A
; For each char...
	ld	de, SCR_WIDTH
	ld	b, SCR_HEIGHT
	ld	a, $20 ; " " ASCII
.CHAR:
; Erases the character
	call	WRTVRM
	add	hl, de
	djnz	.CHAR
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM just a column from the NAMTBL buffer
; param a: the column to LDIRVM (0..31)
; tocuhes af, b, de, hl
LDIRVM_NAMTBL_COLUMN:
; Calculates the origin address
	ld	hl, NAMTBL
	push	af ; preserves the column
	call	ADD_HL_A
	pop	af ; restores the column
; Calculates the destination address
	ld	de, namtbl_buffer
	call	ADD_DE_A
; For each char...
	ld	b, SCR_HEIGHT
.CHAR:
	push	bc ; preserves counters
	ld	a, [de]
	call	WRTVRM
; Moves down a position
	ld	bc, SCR_WIDTH
	add	hl, bc
	ex	de, hl
	add	hl, bc
	ex	de, hl
	pop	bc ; restores counters
	djnz	.CHAR
	ret
; -----------------------------------------------------------------------------


; =============================================================================
;	NAMTBL buffer text and block routines
; =============================================================================

; -----------------------------------------------------------------------------
; Writes a 0-terminated string centered in the NAMTBL buffer
; param hl: source string
; param de: NAMTBL buffer pointer (beginning of the line)
; touches: a, bc, de, hl
PRINT_CENTERED_TEXT:
	call	LOCATE_CENTER
	; jr	PRINT_TEXT ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Writes a 0-terminated string in the NAMTBL buffer
; param hl: source string
; param de: NAMTBL buffer pointer
; touches: a, bc, de, hl
PRINT_TEXT:
	xor	a
.LOOP:
	cp	[hl]
	ret	z ; \0 found
	ldi
	jr	.LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Center a 0-terminated string
; param hl: source string
; param de: NAMTBL buffer pointer (beginning of the line)
; ret de: NAMTBL buffer pointer
; touches: a, bc
LOCATE_CENTER:
	push	hl ; preserves source
; Looks for the \0
	xor	a
	ld	bc, SCR_WIDTH +1 ; (+1 to count the last dec bc)
	cpir
; Centers the buffer pointer
	sra	b ; bc /= 2
	rr	c
	ex	de, hl ; de += bc  =>  de += (32 - length) / 2
	add	hl, bc
	ex	de, hl
	pop	hl ; restores source
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Clears a line in the NAMTBL buffer
; with the blank space character ($20, " " ASCII)
; param hl: NAMTBL buffer pointer (beginning of the line)
; touches: a, bc, de, hl
CLEAR_LINE:
	ld	a, $20 ; " " ASCII
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Fills a line in the NAMTBL buffer with the specified character
; param hl: NAMTBL buffer pointer (beginning of the line)
; param a: the character to fill the line
; touches: bc, de, hl
.USING_A:
	ld	d, h ; de = hl + 1
	ld	e, l
	inc	de
	ld	bc, SCR_WIDTH -1
	ld	[hl], a
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads a string from a 0-terminated string array
; param hl: source of the first string
; param a: string index
; ret hl: source of the a-th string
GET_TEXT:
	ld	d, a ; string index in d
	xor	a ; (looks for \0)
; Checks the border case (d == 0)
	cp	d
	ret	z ; yes: text found
; no: Looks for the proper text
.LOOP:
; Moves the pointer to the next text
	ld	bc, SCR_WIDTH ; (at most SCR_WIDTH chars)
	cpir
; Is the proper text?
	dec	d
	ret	z ; yes
; No: repeats the loop
	jr	.LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints two digits of a BCD value in the NAMTBL buffer
; param hl: source BCD value
; param de: NAMTBL buffer pointer
; ret de: updated NAMTBL buffer pointer
PRINT_BCD:
	xor	a
; Extracts first digit
	rld
; Prints first digit
	push	af
	add	$30 ; "0"
	ld	[de], a
	inc	de
	pop	af
; Extracts second digit
	rld
; Prints second digit
	push	af
	add	$30 ; "0"
	ld	[de], a
	inc	de
	pop	af
; Restores original [hl] value	
	rld
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints a block of b x c characters
; param hl: source data
; param bc: [height, width] of the block
; param de: NAMTBL buffer pointer
PRINT_BLOCK:
; For each row
	push	bc ; preserves counters
	push	de ; preserves destination
; For each byte in the row
	ld	b, 0
	ldir
; Prepares for the next row
	ex	de, hl ; preserves updated source (hl) in de
	pop	hl ; restores destination in hl
	ld	bc, SCR_WIDTH
	add	hl, bc
	ex	de, hl ; restores source and destination in hl and de
	pop	bc ; restores counters
; Checks next row
	djnz	PRINT_BLOCK
	ret
; -----------------------------------------------------------------------------


; =============================================================================
;	Logical coordinates sprite routines
; =============================================================================

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
