
; =============================================================================
; 	Unpacker routine: ZX1 decoder-based implementation
; =============================================================================

	CFG_UNPACK_ZX1:	equ 1

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
	push	de ; (preserves destination buffer address)
	IFDEF CFG_UNPACK_PAGE0_SYNC
		halt
	ENDIF ; IFDEF CFG_UNPACK_PAGE0_SYNC
	di
	call	SET_PAGE0.CARTRIDGE
	pop	de ; (restores destination buffer address)
	call	dzx0_standard
	call	SET_PAGE0.BIOS
	ei
	ret

ELSE
	; jp	dzx1_standard ; falls through

ENDIF ; IF (CFG_INIT_ROM_SIZE > 32)
ELSE
	; jp	dzx1_standard ; falls through

ENDIF ; IFDEF CFG_INIT_ROM_SIZE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ZX1 decoder by Einar Saukas
; "Standard" version (68 bytes only)
	include	"libext/ZX1/z80/dzx1_standard.asm"
; -----------------------------------------------------------------------------

; EOF
