
; =============================================================================
; 	MSX cartridge (ROM) header
; =============================================================================

; -----------------------------------------------------------------------------
; Cartridge header
IFDEF CFG_INIT_ROM_SIZE
IF (CFG_INIT_ROM_SIZE < 32)
	org	$4000, $4000 + (CFG_INIT_ROM_SIZE * $0400) - 1
ELSE
	org	$4000, $bfff
ENDIF ; IF (CFG_INIT_ROM_SIZE < 32)
ELSE
	org	$4000, $7fff
ENDIF ; IFDEF CFG_INIT_ROM_SIZE

CARTRIDGE_HEADER:
	db	"AB"		; ROM Catridge ID ("AB")
	dw	CARTRIDGE_INIT	; INIT
	dw	$0000		; STATEMENT
	dw	$0000		; DEVICE
	dw	$0000		; TEXT
	ds	$4010 - $, $00	; Reserved
; -----------------------------------------------------------------------------

; EOF
