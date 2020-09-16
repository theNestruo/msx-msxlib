
; =============================================================================
;	VRAM routines (BIOS-based)
;	NAMBTL and SPRATR buffer routines (BIOS-based)
; =============================================================================

	CFG_RAM_VRAM:	equ 1

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
	; jr	LDIRVM_UNPACKED_CHRTBL ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM the decompresison buffer to the three CHRTBL banks
LDIRVM_UNPACKED_CHRTBL:
	ld	de, CHRTBL
	call	LDIRVM_UNPACKED_CHRTBL_BANK
	ld	de, CHRTBL + CHRTBL_SIZE
	call	LDIRVM_UNPACKED_CHRTBL_BANK
	ld	de, CHRTBL + CHRTBL_SIZE + CHRTBL_SIZE
	jr	LDIRVM_UNPACKED_CHRTBL_BANK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacks CLRTBL to the three banks
; param hl: packed CLRTBL source address
UNPACK_LDIRVM_CLRTBL:
	ld	de, unpack_buffer
	call	UNPACK
	; jr	LDIRVM_UNPACKED_CLRTBL ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM the decompresison buffer to the three CLRTBL banks
LDIRVM_UNPACKED_CLRTBL:
	ld	de, CLRTBL
	call	LDIRVM_UNPACKED_CLRTBL_BANK
	ld	de, CLRTBL + CHRTBL_SIZE
	call	LDIRVM_UNPACKED_CLRTBL_BANK
	ld	de, CLRTBL + CHRTBL_SIZE + CHRTBL_SIZE
	; jr	LDIRVM_UNPACKED_CLRTBL_BANK
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVM the decompresison buffer to one CHRTBL or CLRTBL bank
; param de: VRAM destination address
LDIRVM_UNPACKED_CHRTBL_BANK:
LDIRVM_UNPACKED_CLRTBL_BANK:
	ld	hl, unpack_buffer
	ld	bc, CHRTBL_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

ELSE ; IFEXIST UNPACK

; -----------------------------------------------------------------------------
; LDIRVMs CHRTBL to the three banks
; param hl: data source address
LDIRVM_CHRTBL:
	ld	de, CHRTBL
	call	LDIRVM_CXRTBL.KEEP_HL
	ld	de, CHRTBL + CHRTBL_SIZE
	call	LDIRVM_CXRTBL.KEEP_HL
	ld	de, CHRTBL + CHRTBL_SIZE + CHRTBL_SIZE
	jr	LDIRVM_CXRTBL
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVMs CLRTBL to the three banks
; param hl: data source address
LDIRVM_CLRTBL:
	ld	de, CLRTBL
	call	LDIRVM_CXRTBL.KEEP_HL
	ld	de, CLRTBL + CLRTBL_SIZE
	call	LDIRVM_CXRTBL.KEEP_HL
	ld	de, CLRTBL + CLRTBL_SIZE + CLRTBL_SIZE
	; jp	LDIRVM_CXRTBL ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; LDIRVMs CHRTBL or CLRTBL to one of the banks
; param hl: data source address
; param de: VRAM destination address
LDIRVM_CXRTBL:
	ld	bc, CLRTBL_SIZE
	jp	LDIRVM
.KEEP_HL:
	push	hl ; (preserves data source address)
	call	LDIRVM_CXRTBL
	pop	hl ; (restores data source address)
	ret
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
; yes
IF CFG_SPRITES_NO_FLICKER > 4
; Was the 5th sprite one of the no-flicker ones?
	and	$0f
	sub	CFG_SPRITES_NO_FLICKER
	jr	c, .NO_FLICKER ; yes: non-flickering LDIRVM
ENDIF ; IF CFG_SPRITES_NO_FLICKER > 4

; Counts how many actual sprites are in the buffer
	ld	hl, spratr_buffer + CFG_SPRITES_NO_FLICKER *4
	ld	a, SPAT_END
; Is there dynamic sprites? (edge case)
	cp	[hl]
	jr	z, .NO_FLICKER ; no: non-flickering LDIRVM
; Count the sprites (in e)
	ld	bc, 4
	ld	e, CFG_SPRITES_NO_FLICKER
.LOOP:
	add	hl, bc
	inc	e
	cp	[hl]
	jp	nz, .LOOP

; Enough sprites in this frame to apply the flickering routine?
IF CFG_SPRITES_NO_FLICKER < 4
	ld	a, 4 ; (at least five sprites)
ELSE
	ld	a, CFG_SPRITES_NO_FLICKER + 1 ; (at least 2 flickering sprites)
ENDIF ; IF CFG_SPRITES_NO_FLICKER < 4
	cp	e
	jr	nc, .NO_FLICKER ; no: non-flickering LDIRVM
; yes
	push	hl ; (preserves actual spratr buffer end)

; Calculates flicker size (in bytes)
IF CFG_SPRITES_NO_FLICKER != 0
	ld	a, -CFG_SPRITES_NO_FLICKER ; e (size, bytes) = (e -CFG_SPRITES_NO_FLICKER) * 4
	add	e
	add	a
	add	a
	ld	e, a
ELSE
	sla	e ; e (size, bytes) = e * 4
	sla	e
ENDIF ; IF CFG_SPRITES_NO_FLICKER != 0

; Reads the 5th sprite plane
	ld	a, [STATFL]
	and	$0f
; Computes the new flickering offset
	sub	CFG_SPRITES_NO_FLICKER
	add	a ; a (offset, bytes) = a *4
	add	a
	ld	hl, spratr_buffer.flicker_offset
	add	[hl]
; Is the offset beyond the actual flickering size?
	cp	e ; (size, bytes)
	jr	c, .OFFSET_OK ; no
; yes: Did the offset got reset?
	sub	e ; (size, bytes)
	jr	z, .RESET_OFFSET ; yes
; no: Is the offset still beyond the actual flickering size?
	cp	e ; (size, bytes)
	jr	nc, .RESET_OFFSET ; yes: resets the offset
; no

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
ENDIF ; IF CFG_SPRITES_NO_FLICKER != 0

; LDIRVM the sprites, starting from the offset
	ld	hl, spratr_buffer + CFG_SPRITES_NO_FLICKER *4
	pop	bc ; (restores offset)
	add	hl, bc
	ld	de, SPRATR + CFG_SPRITES_NO_FLICKER *4
	ld	bc, SPRATR_SIZE - CFG_SPRITES_NO_FLICKER *4
	jp	LDIRVM

.RESET_OFFSET:
; The flickering size has changed between frames; resets the offset for the next frame
	ld	[hl], 0
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

; EOF
