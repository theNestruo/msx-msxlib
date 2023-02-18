
; =============================================================================
;	Input routines (BIOS-based)
; =============================================================================

	CFG_RAM_INPUT:	equ 1

; -----------------------------------------------------------------------------
; Bits read by READ_INPUT and stored in input.edge and input.level
	BIT_STICK_UP:		equ 0
	BIT_STICK_DOWN:		equ 1
	BIT_STICK_LEFT:		equ 2
	BIT_STICK_RIGHT:	equ 3
	BIT_TRIGGER_A:		equ 4
	BIT_TRIGGER_B:		equ 5
	BIT_BUTTON_SELECT:	equ 6
	BIT_BUTTON_START:	equ 7
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads joystick and keyboard as a bit map
; Important: if CFG_HOOK_DISABLE_AUTO_INPUT is not defined,
; this routine is automatically invoked during the H.TIMI hook;
; and there is no need to invoke this routine manually
; ret a / [input.edge]: bits that went from off to on (edge)
; ret b / [input.level]: current bit map (level)
READ_INPUT:
; Reads joystick #1

IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
; Disables interrupts if this routine is to be called manually
	di
ENDIF
; Reads PSG register #15
	ld	a, 15
	call	RDPSG
; Sets flags for reading joystick #1
	and	$bf ; resets b6 = b0-b5 of port A to be connected to univ. I/O interface 1
	ld	e, a
	ld	a, 15
	call	WRTPSG
; Reads PSG register #14
	ld	a, 14
	call	RDPSG
	cpl
	and	$3f ; a = 00BARLDU
; Preserves input value in b
	ld	b, a

; Reads keyboard

; Cursors and space key
IFEXIST SNSMAT_NO_DI_EI
IFDEF CFG_HOOK_ENABLE_AUTO_KEYBOARD
	ld	a, [OLDKEY + 8] ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
ELSE
	ld	c, 8 ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
	call	SNSMAT_NO_DI_EI.C_OK
	cpl
ENDIF
ELSE
	ld	a, 8 ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
	call	SNSMAT
	cpl
ENDIF
; Saves LEFT in input value
	rrca	; SPACE RIGHT DOWN UP LEFT DEL INS HOME
	rrca	; HOME SPACE RIGHT DOWN UP LEFT DEL INS
	ld	c, a ; (preserves rotated row)
	and	$04 ; b |= 00000L00
	or	b
	ld	b, a
; Saves SPACE and RIGHT in input value
	ld	a, c ; (restores rotated row)
	rrca	; INS HOME SPACE RIGHT DOWN UP LEFT DEL
	rrca	; DEL INS HOME SPACE RIGHT DOWN UP LEFT
	ld	c, a ; (preserves rotated row)
	and	$18 ; b |= 000AR000
	or	b
	ld	b, a
; Saves DOWN and UP in input value
	ld	a, c ; (restores rotated row)
	rrca	; LEFT DEL INS HOME SPACE RIGHT DOWN UP
	and	$03 ; b |= 000000DU
	or	b
	ld	b, a

; Trigger B (M key)
IFEXIST SNSMAT_NO_DI_EI
IFDEF CFG_HOOK_ENABLE_AUTO_KEYBOARD
	ld	a, [OLDKEY + 4] ; R Q P O N M L K
ELSE
	ld	c, 4 ; R Q P O N M L K
	call	SNSMAT_NO_DI_EI.C_OK
	cpl
ENDIF
ELSE
	ld	a, 4 ; R Q P O N M L K
	call	SNSMAT
	cpl
ENDIF
	and	$0c ; N or M
	jr	z, .NOT_TRIGGER_B
; Saves trigger B in current level
	set	BIT_TRIGGER_B, b
.NOT_TRIGGER_B:

; "Select" button (SEL key)
IFEXIST SNSMAT_NO_DI_EI
IFDEF CFG_HOOK_ENABLE_AUTO_KEYBOARD
	ld	a, [OLDKEY + 7] ; CR SEL BS STOP TAB ESC F5 F4
ELSE
	ld	c, 7 ; CR SEL BS STOP TAB ESC F5 F4
	call	SNSMAT_NO_DI_EI.C_OK
	cpl
ENDIF
ELSE
	ld	a, 7 ; CR SEL BS STOP TAB ESC F5 F4
	call	SNSMAT
	cpl
ENDIF
	ld	c, a ; (preserves a in c)
	and	$68 ; SEL BS or TAB
	jr	z, .NOT_SELECT
; Saves "select" button in current level
	set	BIT_BUTTON_SELECT, b
.NOT_SELECT:

; "Start" button (STOP key)
	ld	a, c ; (restores a)
	and	$94 ; CR STOP or ESC
	jr	z, .NOT_START
; Saves "start" button in current level
	set	BIT_BUTTON_START, b
.NOT_START:

; Computes edge value from level value
	ld	hl, input.level
	ld	a, [hl] ; previous in a
	cpl	; a = !previous
	and	b ; a = !previous & current = edge
	ld	[hl], b ; saves current
	inc	hl ; hl = input.edge
	ld	[hl], a ; saves edge

IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
; Enables interrupts if this routine is to be called manually
	ei
ENDIF

	ret
; -----------------------------------------------------------------------------

; EOF
