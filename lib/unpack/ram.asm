
IFDEF UNPACK

; -----------------------------------------------------------------------------
; Unpacker routine buffer
unpack_buffer:
IFDEF CFG_RAM_RESERVE_BUFFER
	rb	CFG_RAM_RESERVE_BUFFER
ENDIF ; IFDEF CFG_RAM_RESERVE_BUFFER
; -----------------------------------------------------------------------------

ENDIF ; IFDEF UNPACK

; EOF
