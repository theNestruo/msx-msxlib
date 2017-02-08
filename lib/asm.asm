
; =============================================================================
; 	Generic Z80 assembly convenience routines
; =============================================================================

; -----------------------------------------------------------------------------
; Emulates the instruction "add hl, a" (or "hl += a" in C syntax)
; param hl: operand
; param a: usigned operand
ADD_HL_A:
	add	l
	ld	l, a
	adc	h
	sub	l
	ld	h, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads a byte from a byte array (i.e.: "a = hl[a]" in C syntax)
; param hl: byte array address
; param a: usigned 0-based index
; ret hl: pointer to the byte (i.e.: hl + a)
; ret a: read byte
GET_HL_A_BYTE:
	call	ADD_HL_A
	ld	a, [hl] ; a = [hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads a word from a word array (i.e.: "h,l = hl[a+1], hl[a]" in C syntax)
; param hl: word array address
; param a: unsigned 0-based index (0, 2, 4...)
; ret hl: read word
GET_HL_A_WORD:
	call	ADD_HL_A
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
	call	ADD_HL_A
	; jr	JP_HL_INDIRECT ; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Emulates the instruction "jp [[hl]]" or "call [[hl]]"
; param hl: pointer to the address
; touches a
JP_HL_INDIRECT:
	call	LD_HL_HL
	; jr	JP_HL ; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Simply "jp [hl]", but can be used to emulate the instruction "call [hl]"
; param hl: address
JP_HL:
	jp	[hl]
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Emulates the instruction "ld bc, a"
; param a: signed 8-bit value
; ret bc: signed 16-bit value
LD_BC_A:
	ld	c, a
	rlca ; or rla
	sbc	a, a
	ld	b, a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Loads a in [hl], masked with b (keeps the other bits of [hl])
; param hl: address
; param a: value
; param b: mask
; ret a: loaded value
LD_HL_A_MASK:
	xor	[hl]	; a    = status0 ^ status1 | flag
	and	b	; a    = status0 ^ status1
	xor	[hl]	; a    =           status1 | flag
	ld	[hl], a	; [hl] =           status1 | flag
	ret
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
.LOOP:
; Skips one element
	add	ix, bc
	dec	a
	jr	nz, .LOOP
	ret
; -----------------------------------------------------------------------------

; EOF
