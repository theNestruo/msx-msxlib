		; --- ayFX REPLAYER v1.31 ---

		; --- THIS FILE MUST BE COMPILED IN RAM ---

ayFX_MODE:	rb	1			; ayFX mode
ayFX_BANK:	rw	1			; Current ayFX Bank
ayFX_PRIORITY:	rb	1			; Current ayFX stream priotity
ayFX_POINTER:	rw	1			; Pointer to the current ayFX stream
ayFX_TONE:	rw	1			; Current tone of the ayFX stream
ayFX_NOISE:	rb	1			; Current noise of the ayFX stream
ayFX_VOLUME:	rb	1			; Current volume of the ayFX stream
ayFX_CHANNEL:	rb	1			; PSG channel to play the ayFX stream
IFDEF CFG_AYFX_RELATIVE
	ayFX_VT:	rw	1			; ayFX relative volume table pointer
ENDIF ; IFDEF CFG_AYFX_RELATIVE

		; --- UNCOMMENT THIS IF YOU DON'T USE THIS REPLAYER WITH PT3 REPLAYER ---
;AYREGS:		.ds	14			; Ram copy of PSG registers
		; --- UNCOMMENT THIS IF YOU DON'T USE THIS REPLAYER WITH PT3 REPLAYER ---
