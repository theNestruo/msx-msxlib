
;
; =============================================================================
;	RAM end
; =============================================================================
;

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	dbg_ram_msxlib_bytes:	equ ram_msxlib_end - ram_start
	dbg_ram_game_bytes:	equ $ - ram_msxlib_end
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacker routine buffer
unpack_buffer:
IFDEF CFG_RAM_RESERVE_BUFFER
	rb	CFG_RAM_RESERVE_BUFFER
ENDIF
; -----------------------------------------------------------------------------

ram_end: ; (required by MSXlib)

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	dbg_ram_himem:		equ ram_end
	dbg_ram_size_bytes:	equ ram_end - ram_start
	dbg_ram_free_bytes:	equ $f380 - ram_end
; -----------------------------------------------------------------------------

; EOF
