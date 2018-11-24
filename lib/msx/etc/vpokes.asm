
; =============================================================================
;	"vpoke" routines (deferred WRTVRMs routines)
; =============================================================================

	CFG_RAM_VPOKES:	equ 1

; -----------------------------------------------------------------------------
; Symbolic constants for "vpokes"
	VPOKE.L:	equ 0 ; NAMTBL address (low)
	VPOKE.H:	equ 1 ; NAMTBL address (high)
	VPOKE.A:	equ 2 ; value to write
	VPOKE.SIZE:	equ 3
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the NAMTBL buffer and adds the "vpoke" to the array
; param hl: NAMTBL buffer pointer
; param a: value to set and write
; ret hl: NAMTBL address
; touches: bc, de, ix
UPDATE_NAMTBL_BUFFER_AND_VPOKE:
; Updates the NAMTBL buffer
	ld	[hl], a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Adds a "vpoke" to the array, using NAMTBL buffer pointer
; param hl: NAMTBL buffer pointer
; param a: value to write
; ret hl: NAMTBL address
; touches: bc, de, ix
VPOKE_NAMTBL_BUFFER:
; Translates NAMTBL buffer pointer into NAMTBL address and adds the "vpoke"
	ld	de, -namtbl_buffer +NAMTBL +$10000
	add	hl, de
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Adds a "vpoke" to the array, using NAMTBL address
; param hl: NAMTBL address
; param a: value to write
; touches: bc, ix
VPOKE_NAMTBL_ADDRESS:
	push	af ; preserves value to write
; Adds an element to the array
	ld	ix, vpokes.count
	ld	bc, VPOKE.SIZE
	call	ADD_ARRAY_IX
; Sets the values of the new element
	pop	af ; restores the value to write
	ld	[ix + VPOKE.L], l
	ld	[ix + VPOKE.H], h
	ld	[ix + VPOKE.A], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Executes the "vpokes" and resets the array
EXECUTE_VPOKES:
; Checks array size
	ld	ix, vpokes.count
	ld	a, [ix]
	or	a
	ret	z ; no elements
; Executes the "vpokes"
	ld	b, a ; counter in b
	inc	ix ; ix = vpokes.array
.LOOP:
	push	bc ; preserves the counter
; Executes the "vpoke"
	ld	l, [ix + VPOKE.L]
	ld	h, [ix + VPOKE.H]
	ld	a, [ix + VPOKE.A]
	call	WRTVRM
; Next element
	ld	bc, VPOKE.SIZE
	add	ix, bc
	pop	bc ; restores the counter
	djnz	.LOOP
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Resets the "vpoke" array
RESET_VPOKES:
	xor	a
	ld	[vpokes.count], a
	ret
; -----------------------------------------------------------------------------

; EOF
