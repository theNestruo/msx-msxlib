
; =============================================================================
;	VRAM routines (BIOS-based)
;	NAMBTL and SPRATR buffer routines (BIOS-based)
;	NAMTBL buffer text routines
;	Logical coordinates sprite routines
; =============================================================================


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

; -----------------------------------------------------------------------------
; Unpacks to VRAM using the decompression buffer
; param hl: packed data source address
; param de: VRAM destination address
; param bc: uncompressed data size
IFEXIST UNPACK
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
ENDIF ; UNPACK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacks CHRTBL to the three banks
; param hl: packed CHRTBL source address
IFEXIST UNPACK
UNPACK_LDIRVM_CHRTBL:
	ld	de, unpack_buffer
	call	UNPACK
	; jr	LDIRVM_CHRTBL ; falls through
ENDIF ; UNPACK
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
IFEXIST UNPACK
UNPACK_LDIRVM_CLRTBL:
	ld	de, unpack_buffer
	call	UNPACK
	; jr	LDIRVM_CLRTBL ; falls through
ENDIF ; UNPACK
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
; Clears NAMTBL
	call	CLS
; Disables sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	jp	WRTVRM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Fade out (horizontal sweep)
; Disables the screen, clears NAMTBL and disables sprites
DISSCR_FADE_OUT:
; Disables sprites
	halt	; (sync before disabling sprites / first column)
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Fade out
	ld	hl, NAMTBL
	ld	b, SCR_WIDTH
; For each column...
.COL:
	push	bc ; preserves column counter
	push	hl ; preserves pointer
	ld	de, SCR_WIDTH
	ld	b, SCR_HEIGHT
	ld	a, $20 ; " " ASCII
; For each char...
.CHAR:
	call	WRTVRM
	add	hl, de
	djnz	.CHAR
	halt
	pop	hl ; restores pointer
	inc	hl
	pop	bc ; restores column counter
	djnz	.COL

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
ENASCR_FADE_IN:
; Clears NAMTBL
	halt	; (sync in case screen was enabled)
	; ld	hl, NAMTBL
	; ld	bc, NAMTBL_SIZE
	; ld	a, $20 ; " " ASCII
	; call	FILVRM
	call	CLS
; Disables sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Activa la pantalla
	halt	; (sync before enabling screen)
	call	ENASCR
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Fade in/out (horizontal sweep)
; from current VRAM NAMTBL contents to NAMTBL buffer contents
LDIRVM_NAMTBL_FADE_INOUT:
; Disables sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Fade in
	ld	hl, NAMTBL
	ld	de, namtbl_buffer
	ld	c, SCR_WIDTH
; For each column...
.COL:
	push	hl ; preserves souce pointer
	push	de ; preserves destination pointer
	ld	b, SCR_HEIGHT
; For each char...
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
	push	bc ; preserves counters
	halt
; Moves right a position
	pop	bc ; restores contadores
	pop	de ; restores destination pointer
	inc	de
	pop	hl ; restores source pointer
	inc	hl
	dec	c
	jr	nz, .COL
	ret
; -----------------------------------------------------------------------------


; =============================================================================
;	NAMTBL buffer text routines
; =============================================================================

; -----------------------------------------------------------------------------
; Writes a 0-terminated string centered in the NAMTBL buffer
; param hl: source string
; param de: NAMTBL buffer pointer (beginning of the line)
; touches: a, bc, de, hl
PRINT_CENTERED_TXT:
	call	LOCATE_CENTER
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Writes a 0-terminated string in the NAMTBL buffer
; param hl: source string
; param de: NAMTBL buffer pointer
; touches: a, bc, de, hl
PRINT_TXT:
	xor	a
.LOOP:
	cp	[hl]
	ret	z ; \0 found
	ldi
	jr	.LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Writes a collection of 0-terminated strings centered
; (until the first null string is found) in the NAMTBL buffer
; param hl: source string
; param de: NAMTBL buffer pointer (beginning of the line)
; touches: a, bc, de, hl
PRINT_TXTS:
; Writes one string
	push	de ; preserves destination
	call	PRINT_TXT
	pop	de ; restores destination
; Are there more strings?
	inc	hl ; skips the \0
	ld	a, [hl]
	or	a
	ret	z ; no
; yes: line feed
	ex	de, hl ; destination in hl
	ld	bc, SCR_WIDTH; hl += 32
	add	hl, bc
	ex	de, hl ; destination in de
	jr	PRINT_TXTS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Center a 0-terminated string
; param hl: source string
; param de: NAMTBL buffer pointer (beginning of the line)
; ret de: NAMTBL buffer pointer
; touches: a, bc
LOCATE_CENTER:
	push	hl ; preservaes source
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
; touches: bc, de, hl
CLEAR_LINE:
	ld	d, h ; de = hl + 1
	ld	e, l
	inc	de
	ld	bc, SCR_WIDTH -1
	ld	[hl], $20 ; " " ASCII
	ldir
	ret
; -----------------------------------------------------------------------------


; =============================================================================
;	Logical coordinates sprite routines
; =============================================================================

; -----------------------------------------------------------------------------
; param de: logical coordinates (x, y)
; ret de: physical coordinates (x, y)
LOGICAL_TO_PHYSICAL_COORDINATES:
	ld	a, e ; y -= 16, y--
	add	CFG_SPRITES_Y_OFFSET
	ld	e, a
	ld	a, d ; x -= 8
	add	CFG_SPRITES_X_OFFSET
	ld	d, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Resets the volatile sprites
RESET_SPRITES:
; Fills with Y = SPAT_END
	ld	hl, volatile_sprites
	ld	de, 4
	ld	b, (spratr_buffer_end - volatile_sprites) / 4
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
; param cb: attributes (patter, color)
PUT_SPRITE:
	call	LOGICAL_TO_PHYSICAL_COORDINATES
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Appends a volatile sprite using physical coordinates
; param de: physical coordinates (x, y)
; param cb: attributes (pattern, color)
PUT_SPRITE_NO_OFFSET:
; Locates the SPAT_END
	ld	hl, volatile_sprites
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
	call	LOGICAL_TO_PHYSICAL_COORDINATES
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
