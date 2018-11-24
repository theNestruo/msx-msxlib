
IFDEF CFG_RAM_PASSWORD
; -----------------------------------------------------------------------------
; Variables for: Password encoding/decoding routines

; Password (0..9, A..Z)
password:
	rb	PASSWORD_SIZE
	
; Decoded value
password_value:
	rb	CFG_PASSWORD_DATA_SIZE
; -----------------------------------------------------------------------------
ENDIF

; EOF
