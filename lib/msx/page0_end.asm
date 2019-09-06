
;
; =============================================================================
;	Page 0 ROM end
; =============================================================================
;

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	dbg_rom_page0_bytes:	equ $ - $0000
	dbg_rom_page0_free_bytes:	equ $3fff - $
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Page 0 padding
	ds	($ OR $3fff) -$ +1, $ff ; $ff = rst $38
; -----------------------------------------------------------------------------

; EOF