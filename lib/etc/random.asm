
; =============================================================================
;	Random routines
; =============================================================================

	CFG_RAM_RANDOM:	equ	1

; -----------------------------------------------------------------------------
; Uniform generator for 7 bit numbers
; ret a: a pseudo-random 7 bit number
; touches: b
GET_RANDOM:
	ld      a, r
	ld      b, a
	ld      a, [current_random]
	xor     b
	ld      [current_random], a
	ret
; -----------------------------------------------------------------------------

; EOF
