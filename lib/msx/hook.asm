
; =============================================================================
; 	Interrupt routine (H.TIMI hook)
; =============================================================================

	CFG_RAM_HOOK:	equ 1

; -----------------------------------------------------------------------------
; H.TIMI hook
; 1. Invokes the replayer
; 2. Reads the inputs
; 3. Tricks BIOS' KEYINT to skip keyboard scan, TRGFLG, OLDKEY/NEWKEY, ON STRIG...
; 5. Invokes the previously existing hook
HOOK:
	push	af ; Preserves VDP status register S#0 (a)

; Invokes the replayer
	IFEXIST REPLAYER.FRAME
	; Invokes the replayer (with frameskip in 60Hz machines)
		ld	a, [frames_per_tenth]
		cp	5
		jr	z, .NO_FRAMESKIP ; No frameskip (50Hz machine)
	; Checks frameskip (60Hz machine)
		; ld	a, 6 ; (unnecessary)
		ld	hl, replayer.frameskip
		inc	[hl]
		sub	[hl]
		jr	nz, .NO_FRAMESKIP ; No framewksip
	; Resets frameskip counter
		; xor	a ; (unnecessary)
		ld	[hl], a
		jr	.FRAMESKIP

	.NO_FRAMESKIP:
	; Executes a frame of the replayer
		call	REPLAYER.FRAME
	.FRAMESKIP:
	ENDIF ; REPLAYER.FRAME

; Reads the inputs
	IFDEF CFG_HOOK_ENABLE_AUTO_KEYBOARD
		call	READ_KEYBOARD
	ENDIF ; CFG_HOOK_ENABLE_AUTO_KEYBOARD

	IFEXIST CFG_HOOK_DISABLE_AUTO_INPUT
	ELSE
		call	READ_INPUT
	ENDIF ; CFG_HOOK_DISABLE_AUTO_INPUT

; Tricks BIOS' KEYINT to skip keyboard scan, TRGFLG, OLDKEY/NEWKEY, ON STRIG...
	xor	a
	ld	[SCNCNT], a
	ld	[INTCNT], a

	pop	af ; Restores VDP status register S#0 (a)

; Tricks BIOS' KEYINT to skip ON SPRITE...
	IFDEF CFG_HOOK_PRESERVE_SPRITE_COLLISION_FLAG
	ELSE
		and	$df ; Turns off sprite collision flag
	ENDIF ; IFDEF CFG_HOOK_PRESERVE_SPRITE_COLLISION_FLAG

; Invokes the previously existing hook
	IFDEF CFG_INIT_USE_HIMEM_KEEP_HOOKS
		jp	old_htimi_hook
	ELSE
		ret
	ENDIF ; IFDEF CFG_INIT_USE_HIMEM_KEEP_HOOKS
; -----------------------------------------------------------------------------

; EOF
