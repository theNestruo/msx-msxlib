
; =============================================================================
; 	Generic Z80 assembly convenience routines
; =============================================================================

; -----------------------------------------------------------------------------
; Emulates the instruction "hl += 2*a" (in C syntax)
; param hl: operand
; param a: unsigned operand (0..127)
ADD_HL_2A:
	add	a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Emulates the instruction "add hl, a" (or "hl += a" in C syntax)
; param hl: operand
; param a: unsigned operand (0..255)
ADD_HL_A:
	add	l
	ld	l, a
	ret	nc
	inc	h
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Emulates the instruction "add de, a" (or "de += a" in C syntax)
; param de: operand
; param a: unsigned operand
ADD_DE_A:
	add	e
	ld	e, a
	ret	nc
	inc	d
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Emulates the instruction "add bc, a" (or "bc += a" in C syntax)
; param bc: operand
; param a: unsigned operand
ADD_BC_A:
	add	c
	ld	c, a
	ret	nc
	inc	b
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads a byte from a byte array (i.e.: "a = hl[a]" in C syntax)
; param hl: byte array address
; param a: unsigned 0-based index
; ret hl: pointer to the byte (i.e.: hl + a)
; ret a: read byte
GET_HL_A_BYTE:
	add	l ; hl += a (inlined)
	ld	l, a
	jr	nc, .HL_OK
	inc	h
.HL_OK:
	ld	a, [hl] ; a = [hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads a word from a word array (i.e.: "h,l = hl[2*a+1], hl[2*a]" in C syntax)
; param hl: word array address
; param a: unsigned 0-based index (0, 1, 2...)
; ret hl: read word
GET_HL_2A_WORD:
	add	a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Reads a word from a word array (i.e.: "h,l = hl[a+1], hl[a]" in C syntax)
; param hl: word array address
; param a: unsigned 0-based index (0, 2, 4...)
; ret hl: read word
GET_HL_A_WORD:
	add	l ; hl += a (inlined)
	ld	l, a
	jr	nc, .HL_OK
	inc	h
.HL_OK:
	; jr	LD_HL_HL ; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Emulates the instruction "ld hl, [hl]"
; param hl: address
; ret hl: read word
LD_HL_HL:
	ld	a, [hl] ; hl = [hl]
	inc	hl
	ld	h, [hl]
	ld	l, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Uses a jump table. Usage: both call JP_TABLE and jp JP_TABLE are valid
; param hl: jump table address
; param a: unsigned 0-based index (0, 1, 2...)
JP_TABLE:
	add	a ; a *= 2
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Uses a jump table. Usage: both call JP_TABLE_2 and jp JP_TABLE_2 are valid
; param hl: jump table address
; param a: unsigned 0-based index (0, 2, 4...)
JP_TABLE_2:
	add	l ; hl += a (inlined)
	ld	l, a
	jr	nc, .HL_OK
	inc	h
.HL_OK:
	; jr	JP_HL_INDIRECT ; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Emulates the instruction "jp [[hl]]" or "call [[hl]]"
; param hl: pointer to the address
; touches a
JP_HL_INDIRECT:
	ld	a, [hl] ; hl = [hl] (inlined)
	inc	hl
	ld	h, [hl]
	ld	l, a
	; jr	JP_HL ; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Simply "jp [hl]", but can be used to emulate the instruction "call [hl]"
; param hl: address
JP_HL:
	jp	[hl]
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Simply "jp [ix]", but can be used to emulate the instruction "call [ix]"
; param ix: address
JP_IX:
	jp	[ix]
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Simply "jp [iy]", but can be used to emulate the instruction "call [iy]"
; param iy: address
JP_IY:
	jp	[iy]
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Adds an element to an array and returns the address of the added element
; param ix: array.count address (byte size)
; param bc: size of each array element
; ret ix: address of the new element
ADD_ARRAY_IX:
; Reads the size
	ld	a, [ix]
	inc	[ix]
; Skips the size byte
	inc	ix ; *.array
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Locates an element into an array
; param ix: array address (skipped the size byte)
; param bc: size of each array element
; param a: 0-based index (0, 1, 2...)
; ret ix: address of the element
GET_ARRAY_IX:
	or	a
	ret	z ; element reached
	ld	b, 0
.LOOP:
; Skips one element
	add	ix, bc
	dec	a
	jp	nz, .LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Executes a routine for every element of an array
; param ix: array.count address (byte size)
; param bc: size of each array element
; param hl: routine to execute on every element,
;	that will receive the address of the element in ix
FOR_EACH_ARRAY_IX:
; Checks array size
	ld	a, [ix]
	or	a
	ret	z ; no elements
; For every item in the array
	inc	ix ; ix = actual array
	ld	b, 0
.LOOP:
	push	af ; preserves the counter
	push	bc ; preserves the size of the array element
	push	hl ; preserves the routine address
	call	JP_HL
	pop	hl ; restores the routine address
; Next element
.NEXT:
	pop	bc ; restores the size of the array element
	add	ix, bc
	pop	af ; restores the counter
	dec	a
	jp	nz, .LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience routine to return 0 and the z flag;
; (to be used in comparisons only; inline otherwise)
; ret a: 0
; ret z, nc
RET_ZERO:
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience routine to return -1 ($ff) and the nz flag;
; (to be used in comparisons only; inline otherwise)
; ret a: -1 ($ff)
; ret nz, nc
RET_NOT_ZERO:
	or	-1
	; ret	; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience routine that just rets
; (mainly to be used in no-op entries of jump tables; unnecessary otherwise)
RET_NO_OP:
	ret
; -----------------------------------------------------------------------------

; EOF
