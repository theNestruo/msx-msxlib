
; =============================================================================
; 	Unpacker routine: ZX0 decoder-based implementation
; =============================================================================

; -----------------------------------------------------------------------------
; Unpack to RAM routine
; param hl: packed data source address
; param de: destination buffer address
UNPACK:
IFDEF CFG_INIT_ROM_SIZE
IF (CFG_INIT_ROM_SIZE > 32)
; Is the source from the page 0? (hl < $4000)
	ld	a, $3f
	cp	h
	jr	c, dzx0_standard ; no
; Yes: unpacks from page 0
	di
	push	de ; (preserves destination buffer address)
	call	SET_PAGE0.CARTRIDGE
	pop	de ; (restores destination buffer address)
	call	dzx0_standard
	call	SET_PAGE0.BIOS
	ei
	ret

ELSE
	; jp	dzx0_standard ; falls through

ENDIF ; IF (CFG_INIT_ROM_SIZE > 32)
ELSE
	; jp	dzx0_standard ; falls through

ENDIF ; IFDEF CFG_INIT_ROM_SIZE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas, Antonio Villena & Metalbrain
; "Standard" routine (81 bytes only)
	include	"libext/zx0/dzx0_standard.asm"
; -----------------------------------------------------------------------------

; EOF
