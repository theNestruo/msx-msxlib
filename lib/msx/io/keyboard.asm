
; =============================================================================
;	Keyboard input routines
;	(note: these routines change OLDKEY/NEWKEY semantics!)
; =============================================================================

; -----------------------------------------------------------------------------
; Initializes the level values before the first READ_KEYBOARD invocation
; ret [OLDKEY + i]: $00
; touches: a, bc, de, hl
RESET_KEYBOARD:
	ld	hl, OLDKEY
	ld	de, OLDKEY + 1
	ld	bc, (NEWKEY - OLDKEY - 1) ; (resets all rows)
	ld	[hl], b ; b = $00
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the keyboard level and edge values
; param b: number of keyboard rows to read
; param c: first keyboard row to be read
; ret [OLDKEY + i]: current bit map (level)
; ret [NEWKEY + i]: bits that went from off to on (edge)
READ_KEYBOARD:
; Defaults to all rows
	ld	bc, $0b00 ; ((NEWKEY - OLDKEY) << 8 + $00)
.BC_OK:
; Initializes pointers
	ld	hl, OLDKEY
	ld	de, NEWKEY

IFDEF CFG_HOOK_ENABLE_AUTO_KEYBOARD
ELSE
	di
ENDIF ; IFDEF CFG_HOOK_ENABLE_AUTO_KEYBOARD

.LOOP:
	push	bc ; preserves counter
; Reads the requested row
	call	SNSMAT_NO_DI_EI.C_OK
	cpl	; (as a bitmap: 1/0 = on/off)
; Computes level and edge
	ld	c, a ; c = current
	xor	[hl] ; a = changed bits
	and	c ; a = edge (bits that went from off to on)
	ld	[hl], c ; [OLDKEY + i] = level (current)
	ld	[de], a ; [NEWKEY + i] = edge
; Moves to the next row
	inc	hl
	inc	de
	pop	bc ; restores counter
	inc	c
	djnz	.LOOP

IFDEF CFG_HOOK_ENABLE_AUTO_KEYBOARD
ELSE
	ei
ENDIF ; IFDEF CFG_HOOK_ENABLE_AUTO_KEYBOARD

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Alternative implementation of BIOS' SNSMAT without DI and EI
; param a/c: the keyboard matrix row to be read
; ret a: the keyboard matrix row read
SNSMAT_NO_DI_EI:
	ld	c, a
.C_OK:
; Initializes PPI.C value
	in	a, (PPI.C)
	and	$f0 ; (keep bits 4-7)
	or	c
; Reads the keyboard matrix row
	out	(PPI.C), a
	in	a, (PPI.B)
	ret
; -----------------------------------------------------------------------------

; EOF
