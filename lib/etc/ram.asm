
IFDEF CFG_RAM_RANDOM
; -----------------------------------------------------------------------------
; Variables for: Random routines

; Current (latest generated) pseudo-random 7 bit number, also working as seed
current_random:
	rw	2
; -----------------------------------------------------------------------------
ENDIF

; EOF
