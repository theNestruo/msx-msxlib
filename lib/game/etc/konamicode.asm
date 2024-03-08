
; =============================================================================
;	"Konami code" routines
; =============================================================================

	CFG_RAM_KONAMI_CODE:	equ	1

; -----------------------------------------------------------------------------
; Resets the "Konami code" detection
; ret nc
RESET_KONAMI_CODE:
; Points to the first input edge to check
	IFEXIST CFG_KONAMI_CODE
		ld	hl, CFG_KONAMI_CODE
	ELSE
		ld	hl, DEFAULT_KONAMI_CODE
	ENDIF ; IFEXIST CFG_KONAMI_CODE
	ld	[konami_code.pointer], hl
; ret nc (for INPUT_KONAMI_CODE compatibility)
	or	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Uses input edge to detect the "Konami code"
; ret c/nc: if the "Konami code" was entered in this frame (c) or not (nc)
INPUT_KONAMI_CODE:
; Input edge?
	ld	a, [input.edge]
	or	a
	ret	z ; no
; yes: Checks against expected input edge
	ld	hl, [konami_code.pointer]
	xor	[hl]
	jr	nz, RESET_KONAMI_CODE ; no: ret nc
; yes: Advances to the next expected input edge
	; xor	a ; (unnecessary)
	inc	hl
	ld	[konami_code.pointer], hl
; "Konami code" completed?
	or	[hl]
	ret	nz ; no
; yes: Resets the "Konami code" detection
	call	RESET_KONAMI_CODE
; ret c
	scf
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
	IFEXIST CFG_KONAMI_CODE
	ELSE

; Default "Konami code": up up down down left right left right B A
DEFAULT_KONAMI_CODE:
	db	1 << BIT_STICK_UP
	db	1 << BIT_STICK_UP
	db	1 << BIT_STICK_DOWN
	db	1 << BIT_STICK_DOWN
	db	1 << BIT_STICK_LEFT
	db	1 << BIT_STICK_RIGHT
	db	1 << BIT_STICK_LEFT
	db	1 << BIT_STICK_RIGHT
	db	1 << BIT_TRIGGER_B
	db	1 << BIT_TRIGGER_A
	db	$00

	ENDIF ; IFEXIST CFG_KONAMI_CODE
; -----------------------------------------------------------------------------

; EOF
