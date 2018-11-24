
; =============================================================================
; 	RAM
; =============================================================================

IFDEF CFG_INIT_16KB_RAM
	org	$c000, $f380
ELSE
	org	$e000, $f380
ENDIF
ram_start:

	include "lib\msx\ram.asm"
	; include "lib\game\game.ram.asm"

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	dbg_ram_size:		equ ram_end - ram_start
	dbg_ram_size_msxlib:	equ $ - ram_start
	dbg_ram_size_game:	equ dbg_ram_size - dbg_ram_size_msxlib
	dbg_ram_free:		equ $f380 - $
; -----------------------------------------------------------------------------

; EOF
