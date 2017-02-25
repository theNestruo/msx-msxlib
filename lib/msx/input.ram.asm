
; -----------------------------------------------------------------------------
;	Input routines (BIOS-based)

IFDEF GET_STICK_BITS
; Stores GET_STICK_BITS result
stick:
	rb	1
stick_edge:
	rb	1
ENDIF

IFDEF GET_TRIGGER
; Stores GET_TRIGGER result
trigger:
	rb	1
ENDIF
; -----------------------------------------------------------------------------

; EOF
