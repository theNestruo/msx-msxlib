
; =============================================================================
; 	Interrupt routine (H.TIMI hook)
; =============================================================================

	CFG_RAM_HOOK:	equ 1

; -----------------------------------------------------------------------------
; H.TIMI hook
; 1. Invokes the replayer
; 2. Reads the inputs
; 3. Tricks BIOS' KEYINT to skip keyboard scan, TRGFLG, OLDKEY/NEWKEY, ON STRIG...
; 4. Invokes the previously existing hook
HOOK:
	push	af ; Preserves VDP status register S#0 (a)
	
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
IFEXIST CFG_HOOK_DISABLE_AUTO_INPUT

IFEXIST CFG_HOOK_KEEP_BIOS_KEYINT
ELSE ; NOT CFG_HOOK_KEEP_BIOS_KEYINT
; Tricks BIOS' KEYINT to skip keyboard scan, TRGFLG, OLDKEY/NEWKEY, ON STRIG...
	xor	a
	ld	[SCNCNT], a
	ld	[INTCNT], a
ENDIF ; IFEXIST CFG_HOOK_KEEP_BIOS_KEYINT

ELSE ; NOT CFG_HOOK_DISABLE_AUTO_INPUT
	call	READ_INPUT
ENDIF ; CFG_HOOK_KEEP_BIOS_KEYINT

; Invokes the previously existing hook
	pop	af ; Restores VDP status register S#0 (a)
	jp	old_htimi_hook
; -----------------------------------------------------------------------------

; EOF
