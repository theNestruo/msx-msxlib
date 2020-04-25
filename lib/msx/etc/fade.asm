
; =============================================================================
;	Additional NAMBTL and SPRATR buffer based routines
; =============================================================================

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
; Clears just a column of the NAMTBL
; param a: the column to LDIRVM (0..31)
; touches af, b, de, hl
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
; LDIRVM just a column from the NAMTBL buffer
; param a: the column to LDIRVM (0..31)
; tocuhes af, b, de, hl
LDIRVM_NAMTBL_COLUMN:
; Calculates the origin address (NAMTBL is aligned to $xx00)
	ld	h, NAMTBL >> 8
	ld	l, a
; Calculates the destination address (namtbl_buffer is aligned to $xx00)
	ld	d, namtbl_buffer >> 8
	ld	e, a
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

; EOF
