
; =============================================================================
;	Secondary slot routines
; =============================================================================

; -----------------------------------------------------------------------------
; Checks the presence of a search string at address in any slot
; param hl: pointer to: nn = address, n = number of bytes, search string
; ret z/nz: search string found/not found
SEARCH_IN_ANY_SLOT:
; Checks primary slots
	ld	bc, $0400 ; Primary slots: $00,$01,$02,$03
	call	.LOOP
	ret	z ; match
; not found: Checks expanded slots
	ld	bc, $1080 ; Expanded slots: $80,$81,..,$8e,$8f
.LOOP:
; Compares with the current slot
	push	bc	; (preserves counter and slot ID)
	push	hl	; (preserves search string data)
	call	SEARCH_IN_SLOT
	pop	hl	; (restores search string data)
	pop	bc	; (restores counter and slot ID)
	ret	z ; found
; not found: next slot
	inc	c
	djnz	.LOOP
; no more slots: not found (ret nz)
	or	-1
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Checks the presence of a search string in one slot
; param hl: pointer to: nn = address, n = number of bytes, search string
; param c: slot ID
; ret z/nz: search string found/not found
; touches: a, b, de, hl
SEARCH_IN_SLOT:
; Reads address
	ld	e, [hl]
	inc	hl
	ld	d, [hl]
	inc	hl
; Reads size
	ld	b, [hl]
	inc	hl
.LOOP:
	push    bc	; (preserves byte counter and slot ID)
	push	hl	; (preserves address to search string)
; Reads the byte
	ld	a, c
	ex	de, hl
        call    RDSLT
	ex	de, hl
	pop	hl	; (restores address to search string)
	pop	bc	; (restores byte counter and slot ID)
; Is the expected byte?
	cp	[hl]
	ret	nz ; no
; yes: next byte
	inc	hl
	inc	de
	djnz	.LOOP
	ret	; (rets z)
; -----------------------------------------------------------------------------
