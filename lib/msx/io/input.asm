
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

; Reads keyboard

; Cursors and space key
IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
	ld	a, 8 ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
	call	SNSMAT
ELSE
	ld	c, 8 ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
	call	SNSMAT_NO_DI_EI
ENDIF
	cpl
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
IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
	ld	a, 4 ; R Q P O N M L K
	call	SNSMAT
ELSE
	ld	c, 4 ; R Q P O N M L K
	call	SNSMAT_NO_DI_EI
ENDIF
	bit	2, a
	jr	nz, .NOT_TRIGGER_B
; Saves trigger B in current level
	set	BIT_TRIGGER_B, b
.NOT_TRIGGER_B:

; "Select" button (SEL key)
IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
	ld	a, 7 ; CR SEL BS STOP TAB ESC F5 F4
	call	SNSMAT
ELSE
	ld	c, 7 ; CR SEL BS STOP TAB ESC F5 F4
	call	SNSMAT_NO_DI_EI
ENDIF
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

IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
; Enables interrupts if this routine is to be called manually
	ei
ENDIF

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
IFDEF CFG_INPUT_KEYBOARD

; Initializes the level values before the first READ_KEYBOARD invocation
; ret [OLDKEY + i]: $00
; touches: a, bc, de, hl
RESET_KEYBOARD:
	ld	hl, OLDKEY
	ld	de, OLDKEY + 1
	ld	bc, (NEWKEY - OLDKEY - 1) ; (resets all rows)
	ld	[hl], b ; b = $00
	ldir
	ret

; Reads the keyboard level and edge values
; param b: number of keyboard rows to read
; param c: first keyboard row to be read
; ret [OLDKEY + i]: current bit map (level)
; ret [NEWKEY + i]: bits that went from off to on (edge)
READ_KEYBOARD:
; Defaults to all rows
	ld	bc, $0b00 ; ((NEWKEY - OLDKEY) << 8 + $00)
.BC_OK:
; Initializes pointers
	ld	hl, OLDKEY
	ld	de, NEWKEY
IFEXIST SNSMAT_NO_DI_EI
	di
ENDIF
.LOOP:
	push	bc ; preserves counter
; Reads the requested row
IFEXIST SNSMAT_NO_DI_EI
	call	SNSMAT_NO_DI_EI
ELSE
	ld	a, c
	call	SNSMAT
ENDIF
	cpl	; (as a bitmap: 1/0 = on/off)
; Computes level and edge
	ld	c, a ; c = current
	xor	[hl] ; a = changed bits
	and	c ; a = edge (bits that went from off to on)
	ld	[hl], c ; [OLDKEY + i] = level (current)
	ld	[de], a ; [NEWKEY + i] = edge
; Moves to the next row
	inc	hl
	inc	de
	pop	bc ; restores counter
	inc	c
	djnz	.LOOP

IFEXIST SNSMAT_NO_DI_EI
	ei
ENDIF
	ret

ENDIF ; IFDEF CFG_INPUT_KEYBOARD
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
ELSE

; Alternative implementation of BIOS' SNSMAT without DI and EI
; param c: the keyboard matrix row to be read
; ret a: the keyboard matrix row read
SNSMAT_NO_DI_EI:
; Initializes PPI.C value
	in	a, (PPI.C)
	and	$f0 ; (keep bits 4-7)
	or	c
; Reads the keyboard matrix row
	out	(PPI.C), a
	in	a, (PPI.B)
	ret

ENDIF
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
IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
	call	READ_INPUT
ELSE
	ld	a, [input.edge]
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
IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
	call	READ_INPUT
ELSE
	ld	a, [input.edge]
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
