
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
; Important: if CFG_HOOK_READ_INPUT is defined,
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
IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
; Enables interrupts if this routine is to be called manually
	ei
ENDIF
	
; Reads keyboard

; Cursors and space key
	ld	a, 8 ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
	call	SNSMAT
	cpl
; Introduces LEFT in input value
	rrca	; SPACE RIGHT DOWN UP LEFT DEL INS HOME
	rrca	; HOME SPACE RIGHT DOWN UP LEFT DEL INS
	ld	c, a ; (preserves rotated row)
	and	$04 ; b |= 00000L00
	or	b
	ld	b, a
; Introduces SPACE and RIGHT in input value
	ld	a, c ; (restores rotated row)
	rrca	; INS HOME SPACE RIGHT DOWN UP LEFT DEL
	rrca	; DEL INS HOME SPACE RIGHT DOWN UP LEFT
	ld	c, a ; (preserves rotated row)
	and	$18 ; b |= 000AR000
	or	b
	ld	b, a
; Introduces DOWN and UP in input value
	ld	a, c ; (restores rotated row)
	rrca	; LEFT DEL INS HOME SPACE RIGHT DOWN UP
	and	$03 ; b |= 000000DU
	or	b
	ld	b, a

; Trigger B (M key)
	ld	a, 4 ; R Q P O N M L K
	call	SNSMAT
	bit	2, a
	jr	nz, .NOT_TRIGGER_B
; Saves trigger B in current level
	set	BIT_TRIGGER_B, b
.NOT_TRIGGER_B:

; "Select" button (SEL key)
	ld	a, 7 ; CR SEL BS STOP TAB ESC F5 F4
	call	SNSMAT
	bit	6, a
	jr	nz, .NOT_SELECT
; Saves "select" button in current level
	set	BIT_BUTTON_SELECT, b
.NOT_SELECT:

; "Start" button (STOP key)
	bit	4, a
	jr	nz, .NOT_START
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

	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Four seconds pause
; touches: b, hl
WAIT_FOUR_SECONDS:
	call	WAIT_TWO_SECONDS
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Two seconds pause
; touches: b, hl
WAIT_TWO_SECONDS:
	call	WAIT_ONE_SECOND
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; One second pause
; touches: b, hl
WAIT_ONE_SECOND:
	ld	hl, frame_rate
	ld	b, [hl]
	; jr	WAIT_FRAMES ; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Pause
; param b: pause length (in frames)
; touches: b
WAIT_FRAMES:
	halt
	djnz	WAIT_FRAMES
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Skippable four seconds pause
; ret nz: if the trigger went from off to on (edge)
; ret z: if the pause timed out
; touches: a, bc, de, hl
WAIT_TRIGGER_FOUR_SECONDS:
	ld	a, [frame_rate]
	add	a
	add	a
	jr	WAIT_TRIGGER_FRAMES_A
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Skippable one second pause
; ret nz: if the trigger went from off to on (edge)
; ret z: if the pause timed out
; touches: a, bc, de, hl
WAIT_TRIGGER_ONE_SECOND:
	ld	a, [frame_rate]
	; jr	TRIGGER_PAUSE_A ; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Skippable pause
; param a: pause length (in frames)
; ret nz: if the trigger went from off to on (edge)
; ret z: if the pause timed out
; touches: a, bc, de, hl
WAIT_TRIGGER_FRAMES_A:
	ld	b, a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Skippable pause
; param b: pause length (in frames)
; ret nz: if the trigger went from off to on (edge)
; ret z: if the pause timed out
; touches: a, bc, de, hl
WAIT_TRIGGER_FRAMES:
	push	bc ; preserves counter
	halt
IFDEF CFG_HOOK_READ_INPUT
	ld	a, [input.edge]
ELSE
	call	READ_INPUT
ENDIF
	bit	BIT_TRIGGER_A, a
	pop	bc ; restores counter
	ret	nz ; trigger
	djnz	WAIT_TRIGGER_FRAMES
	ret	; no trigger (z)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Waits for the trigger
; ret nz always: the trigger went from off to on (edge)
; touches: a, bc, de, hl
WAIT_TRIGGER:
	halt
IFDEF CFG_HOOK_READ_INPUT
	ld	a, [input.edge]
ELSE
	call	READ_INPUT
ENDIF
	bit	BIT_TRIGGER_A, a
	jr	z, WAIT_TRIGGER
	ret	; trigger (nz)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Waits until no key is pressed
WAIT_NO_KEY:
	halt
; Ten lines
	ld	b, 11
	ld	d, $ff
.LOOP:
; Reads keyboard matrix line
	ld	a, b
	dec	a ; check lines from 10 to 0
	call	SNSMAT
; Aggregates (AND) the result in d
	and	d
	ld	d, a
	djnz	.LOOP
; If no keys were pressed, d will be $ff
	; ld	a, d ; (unnecessary)
	inc	a ; $ff becomes $00
	ret	z
	jr	WAIT_NO_KEY
; -----------------------------------------------------------------------------

; EOF
