
;
; =============================================================================
;	ROM end
; =============================================================================
;

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	dbg_rom_msxlib_bytes:	equ INIT - CARTRIDGE_HEADER
	dbg_rom_game_bytes:	equ $ - INIT
	dbg_rom_size_bytes:	equ $ - CARTRIDGE_HEADER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Padding to a 16kB boundary with $FF (RST $38)
PADDING:
IFDEF CFG_INIT_ROM_SIZE
IF CFG_INIT_ROM_SIZE < 32
	ds	($ OR $1fff) -$ +1, $ff ; (8kB boundary to allow 8kB or 24kB ROMs)
ELSE
	ds	($ OR $3fff) -$ +1, $ff
ENDIF
ELSE ; IF CFG_INIT_ROM_SIZE < 32
	ds	($ OR $1fff) -$ +1, $ff ; (8kB boundary to allow 8kB or 24kB ROMs)
ENDIF ; IFDEF CFG_INIT_ROM_SIZE
	.SIZE:	equ $ - PADDING
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	dbg_rom_free_bytes:	equ PADDING.SIZE
; -----------------------------------------------------------------------------

; EOF
