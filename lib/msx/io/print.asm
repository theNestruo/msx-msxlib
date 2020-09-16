
; =============================================================================
;	NAMTBL buffer text and block routines
; =============================================================================

; -----------------------------------------------------------------------------
; Writes a 0-terminated string centered in the NAMTBL buffer
; param hl: source string
; param de: NAMTBL buffer pointer (beginning of the line)
; ret hl: pointer to the "\0" of the printed string
; ret de: updated NAMTBL buffer pointer
; ret a: 0
; touches: bc
PRINT_CENTERED_TEXT:
	call	LOCATE_CENTER
	; jr	PRINT_TEXT ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Writes a 0-terminated string in the NAMTBL buffer
; param hl: source string
; param de: NAMTBL buffer pointer
; ret hl: pointer to the "\0" of the printed string
; ret de: updated NAMTBL buffer pointer
; ret a: 0
; touches: bc
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
; ret a: 0
; touches: bc
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
; Checks the border case (a == 0)
	or	a
	ret	z ; yes: text found
; no: Looks for the proper text
	ld	d, a ; string index in d
	xor	a ; (looks for \0)
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

; EOF
