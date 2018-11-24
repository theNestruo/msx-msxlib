
; =============================================================================
;	Attract-mode text-printing routines
; =============================================================================

	CFG_RAM_ATTRACT_PRINT:	equ 1

; -----------------------------------------------------------------------------
; Initializes the attract-mode print
; param hl: pointer to the source data
; param de: pointer to the NAMTBL buffer
INIT_ATTRACT_PRINT:
	ld	[attract_print.target_line], de
.TARGET_OK:
	ld	[attract_print.source], hl
.NEXT_LINE:
	xor	a
	ld	[attract_print.framecounter], a
; Locates the actual destination	
	ld	hl, [attract_print.source]
	ld	de, [attract_print.target_line]
	call	LOCATE_CENTER
	ld	[attract_print.target_char], de
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints one character in attract-mode print
; ret z: the end of the string has been reached
; ret nz: otherwise
ATTRACT_PRINT_CHAR:
; Checks delay
	ld	hl, attract_print.framecounter
	inc	[hl]
	ld	a, [hl]
	sub	CFG_ATTRACT_PRINT_DELAY
	ret	nz
	; xor	a ; unnecessary
	ld	[hl], a
; Prints one character
	ld	hl, [attract_print.source]
	ld	de, [attract_print.target_char]
	ldi
; (preserves updated pointers)
	ld	[attract_print.source], hl
	ld	[attract_print.target_char], de
; Is the end of the string?
	xor	a
	cp	[hl]
	ret	; z = yes, nz = no
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the attract print pointer one line down
ATTRACT_PRINT_MOVE_LF:
	ld	bc, SCR_WIDTH
	; jr	ATTRACT_PRINT_MOVE ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the attract print pointer a number of lines down
; param bc: the target pointer displacement (a multiple of SCR_WIDTH)
ATTRACT_PRINT_MOVE:
	ld	hl, [attract_print.target_line]
	add	hl, bc
	ld	[attract_print.target_line], hl
	ret
; -----------------------------------------------------------------------------

; EOF
