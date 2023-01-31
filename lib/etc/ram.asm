
IFDEF CFG_RAM_RANDOM
; -----------------------------------------------------------------------------
; Variables for: Random routines

; Current (latest generated) pseudo-random 7 bit number, also working as seed
current_random:
	rb	1
; -----------------------------------------------------------------------------
ENDIF

; EOF
