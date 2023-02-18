
; =============================================================================
; 	Additional Z80 assembly convenience routines
; =============================================================================

; -----------------------------------------------------------------------------
; Loads a in [hl], masked with b (only loads the bits specified by b).
; i.e.: [hl] = a = ([hl] & not(b)) | (a & b)
; param hl: the memory address
; param a: the new value
; param b: the mask (1 = new value, 0 = old value)
; ret a, [hl]: the loaded value
LD_HL_A_MASK:
			; a    = new_10
	xor	[hl]	; a    = new_10 ^ old_10
	and	b	; a    = new_1_ ^ old_1_
	xor	[hl]	; a    = new_1_ ^ old__0
	ld	[hl], a	; [hl] = new_1_ ^ old__0
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Computes a modulus b, with both unsigned operands
; (this routine can be potentially slow)
; param a: the dividend, unsigned (0..255)
; param b: the divisor, unsigned (1..255)
; ret a: the modulus, unsigned
A_MODULUS_B:
; Is a greater than b?
	cp	b
	ret	c ; no
; yes: subtract b from a and compare again
	sub	b
	jp	A_MODULUS_B
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Computes a modulus c, with both unsigned operands
; (this routine can be potentially slow)
; param a: the dividend, unsigned (0..255)
; param c: the divisor, unsigned (0..255)
; ret a: the modulus, unsigned
A_MODULUS_C:
; Is a greater than c?
	cp	c
	ret	c ; no
; yes: subtract c from a and compare again
	sub	c
	jp	A_MODULUS_C
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Mirrors the value of register A
; param a: the value to mirror
; ret a: the mirrored value
; touches c
MIRROR_A:
	ld	c, a	; a = 76543210
	rlca
	rlca		; a = 54321076
	xor	c
	and	$aa
	xor	c	; a = 56341270
	ld	c, a
	rlca
	rlca
	rlca		; a = 41270563
	rrc	c	; c = 05634127
	xor	c
	and	$66
	xor	c	; a = 01234567
  	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Mirrors the value contained in address hl
; param hl: the address containing the value to mirror
; ret a, [hl]: the mirrored value
MIRROR_HL_INDIRECT:
	ld	a, [hl]	; a = 76543210
	rlca
	rlca		; a = 54321076
	xor	[hl]
	and	$aa
	xor	[hl]	; a = 56341270
	ld	[hl], a
	rlca
	rlca
	rlca		; a = 41270563
	rrc	[hl]	; c = 05634127
	xor	[hl]
	and	$66
	xor	[hl]	; a = 01234567
	ld	[hl], a
  	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Mirrors b bytes, starting at address hl
; param hl: the address of the first byte to mirror
; param b: the number of bytes to mirror
MIRROR_B_BYTES:
	call	MIRROR_HL_INDIRECT
	inc	hl
	djnz	MIRROR_B_BYTES
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Swaps two bytes
; param hl: the address of one of the bytes to swap
; param de: the address of the other byte to swap
; touches c
SWAP_BYTE:
	ld	c, [hl]
	ld	a, [de]
	ex	de, hl
	ld	[hl], c
	ld	[de], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Swaps 32 bytes, starting at addresses hl and de
; param hl: one of the address of the bytes to swap
; param de: the other address of the byte to swap
; touches b, c
SWAP_32_BYTES:
	call	SWAP_16_BYTES
	; jr	SWAP_16_BYTES ; (falls through)
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
; Swaps 16 bytes, starting at addresses hl and de
; param hl: one of the address of the bytes to swap
; param de: the other address of the byte to swap
; touches b, c
SWAP_16_BYTES:
	call	SWAP_8_BYTES
	; jr	SWAP_8_BYTES ; (falls through)
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
; Swaps 8 bytes, starting at addresses hl and de
; param hl: one of the address of the bytes to swap
; param de: the other address of the byte to swap
; touches b, c
SWAP_8_BYTES:
	ld	b, 8
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
; Swaps b bytes, starting at addresses hl and de
; param hl: one of the address of the bytes to swap
; param de: the other address of the byte to swap
; param b: the number of bytes to swap
; touches c
SWAP_B_BYTES:
	call	SWAP_BYTE
	inc	hl
	inc	de
	djnz	SWAP_B_BYTES
	ret
; -----------------------------------------------------------------------------

; EOF
