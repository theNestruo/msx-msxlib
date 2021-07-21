
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

IFDEF CFG_RAM_MENU
; -----------------------------------------------------------------------------
; Variables for: Menu control routines

options_menu:
.size:
	rb	1 ; Number of options
.cursor_definition:
	rw	1 ; Cursor definition address
.offset:
	rw	1 ; Cursor-to-option text coordinates offset
.coordinates:
	rw	1 ; Address of the cursor coordinates table
.options:
	rw	1 ; Address of the option texts table
.current_position:
	rb	1
; -----------------------------------------------------------------------------
ENDIF

; EOF
