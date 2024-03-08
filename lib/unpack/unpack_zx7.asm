
; =============================================================================
; 	Unpacker routine: ZX7 decoder-based implementation
; =============================================================================

	CFG_UNPACK_ZX7:	equ 1

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
	jr	c, dzx7_standard ; no
; Yes: unpacks from page 0
	push	de ; (preserves destination buffer address)
	IFDEF CFG_UNPACK_PAGE0_SYNC
		halt
	ENDIF ; IFDEF CFG_UNPACK_PAGE0_SYNC
	di
	call	SET_PAGE0.CARTRIDGE
	pop	de ; (restores destination buffer address)
	call	dzx7_standard
	call	SET_PAGE0.BIOS
	ei
	ret

ELSE
	; jp	dzx7_standard ; falls through

ENDIF ; IF (CFG_INIT_ROM_SIZE > 32)
ELSE
	; jp	dzx7_standard ; falls through

ENDIF ; IFDEF CFG_INIT_ROM_SIZE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ZX7 decoder by Einar Saukas, Antonio Villena & Metalbrain
; "Standard" version (69 bytes only)
	include	"libext/zx7/dzx7_standard.tniasm.asm"
; -----------------------------------------------------------------------------

; EOF
