
; =============================================================================
; 	Interrupt routine (H.TIMI hook)
; =============================================================================

; -----------------------------------------------------------------------------
; Installs the H.TIMI hook in the interruption
HOOK.INSTALL:
; Preserves the existing hook
	ld	hl, HTIMI
	ld	de, old_htimi_hook
	ld	bc, HOOK_SIZE
	ldir
; Install the replayer hook
	di
	ld	hl, HOOK
	ld	de, HTIMI
	ld	bc, HOOK_SIZE
	ldir
	ei
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; H.TIMI hook
; 1. Invokes the replayer
; 2. Reads the inputs
; 3. Tricks BIOS' KEYINT to skip keyboard scan, TRGFLG, OLDKEY/NEWKEY, ON STRIG...
; 4. Invokes the previously existing hook
HOOK:
	jp	.ACTUAL_HOOK
	; ret	; (padding, unnecesary)
	; ret	; (padding, unnecesary)

; Actual interrupt routine (H.TIMI hook):
.ACTUAL_HOOK:
	push	af ; Preserves VDP status register S#0 (a)
	
IFDEF CFG_DEBUG_BDRCLR
	ld	b, 15
	call	SET_BDRCLR ; grey: custom hook frame time
ENDIF

; Invokes the replayer
IFEXIST REPLAYER.FRAME
; Invokes the replayer (with frameskip in 60Hz machines)
	ld	a, [frames_per_tenth]
	cp	5
	jr	z, .NO_FRAMESKIP ; No frameskip (50Hz machine)
; Checks frameskip (60Hz machine)
	; ld	a, 6 ; (unnecesary)
	ld	hl, replayer.frameskip
	inc	[hl]
	cp	[hl]
	jr	nz, .NO_FRAMESKIP ; No framewksip 
; Resets frameskip counter
	xor	a
	ld	[hl], a
	jr	.FRAMESKIP

.NO_FRAMESKIP:
; Executes a frame of the replayer
	call	REPLAYER.FRAME
.FRAMESKIP:
ENDIF ; REPLAYER.FRAME

; Reads the inputs
IFEXIST CFG_HOOK_READ_INPUT
	call	READ_INPUT
; Tricks BIOS' KEYINT to skip keyboard scan, TRGFLG, OLDKEY/NEWKEY, ON STRIG...
IFEXIST CFG_HOOK_KEEP_BIOS_INPUT
ELSE
	xor	a
	ld	[SCNCNT], a
ENDIF ; IFEXIST CFG_HOOK_KEEP_BIOS_INPUT
ENDIF ; IFEXIST CFG_HOOK_READ_INPUT

IFDEF CFG_DEBUG_BDRCLR
	ld	b, 13
	call	SET_BDRCLR ; magenta: BIOS interrupt frame time
ENDIF

; Invokes the previously existing hook
	pop	af ; Restores VDP status register S#0 (a)
	jp	old_htimi_hook
; -----------------------------------------------------------------------------

; EOF
