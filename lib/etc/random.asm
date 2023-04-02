
; =============================================================================
;	Random routines
; =============================================================================

	CFG_RAM_RANDOM:	equ	1

; -----------------------------------------------------------------------------
; Uniform generator for 8 bit numbers
; ret a, l: a pseudo-random 8 bit number (bit 8 is undefined)
; touches: hl, de
; https://worldofspectrum.org/forums/discussion/comment/583693#Comment_583693
GET_RANDOM:
	ld	hl, [current_random +0]   ; xz -> yw
        ld	de, [current_random +2]   ; yw -> zt
        ld	[current_random +0], de  ; x = y, z = w
        ld	a, e         ; w = w ^ ( w << 3 )
        add	a
        add	a
        add	a
        xor	e
        ld	e, a
        ld	a, h         ; t = x ^ (x << 1)
        add	a
        xor	h
        ld	d, a
        rra	; t = t ^ (t >> 1) ^ w
        xor	d
        xor	e
        ld	h, l         ; y = z
        ld	l, a         ; w = t
        ld	[current_random +2], hl
	ret
; -----------------------------------------------------------------------------

IFEXIST A_MODULUS_C

; -----------------------------------------------------------------------------
; Uniform generator for 8 bit numbers between two values
; param c: maximum value (inclusive)
; param b: minimum value (inclusive)
; ret a: a pseudo-random 8 bit number between two values
; touches hl, de, c
RANDOM_BETWEEN_B_C:
; Compues range
	ld	a, c
	sub	b
; Random value within range
	call	RANDOM_BETWEEN_0_A
	add	b
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Uniform generator for 8 bit numbers between 0 (inclusive) and another value
; param a: maximum value (inclusive)
; ret a: a pseudo-random 8 bit number between 0 (inclusive) and another value
; touches hl, de
RANDOM_BETWEEN_0_A:
	ld	c, a
	; jr	RANDOM_BETWEEN_0_C ; (falls through)
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
; Uniform generator for 8 bit numbers between 0 (inclusive) and another value
; param c: maximum value (inclusive)
; ret a: a pseudo-random 8 bit number between 0 (inclusive) and another value
; touches hl, de
RANDOM_BETWEEN_0_C:
	call	GET_RANDOM
	jp	A_MODULUS_C
; -----------------------------------------------------------------------------

ENDIF ; IFEXIST A_MODULUS_C

; EOF
