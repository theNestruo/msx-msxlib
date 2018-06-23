
; =============================================================================
;	Input, timing & pause routines (BIOS-based)
; =============================================================================

; -----------------------------------------------------------------------------
; Bits returned by GET_INPUT_BITS
	BIT_STICK_UP:		equ 0
	BIT_STICK_RIGHT:	equ 1
	BIT_STICK_DOWN:		equ 2
	BIT_STICK_LEFT:		equ 3
	BIT_TRIGGER_A:		equ 4
	BIT_TRIGGER_B:		equ 5

; Bit map values table
INPUT_BITMAP_STICK_TABLE:
	db	0						 ; 0
	db	(1 << BIT_STICK_UP)				 ; 1
	db	(1 << BIT_STICK_UP)	+ (1 << BIT_STICK_RIGHT) ; 2
	db				  (1 << BIT_STICK_RIGHT) ; 3
	db	(1 << BIT_STICK_DOWN)	+ (1 << BIT_STICK_RIGHT) ; 4
	db	(1 << BIT_STICK_DOWN)				 ; 5
	db	(1 << BIT_STICK_DOWN)	+ (1 << BIT_STICK_LEFT)	 ; 6
	db				  (1 << BIT_STICK_LEFT)	 ; 7
	db	(1 << BIT_STICK_UP)	+ (1 << BIT_STICK_LEFT)	 ; 8
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads both keyboard and joystick 1 as a bit map
; ret [input.level]: current bit map (level)
; ret a / [input.edge]: bits that went from off to on (edge)
READ_INPUT:
	ld	hl, input.level
	ld	a, [hl]
	push	af ; (preserves previous level)
	
; Reads the cursors/stick value
	call	GET_STICK
; Translates as bit map value
	ld	hl, INPUT_BITMAP_STICK_TABLE
	call	ADD_HL_A
	ld	a, [hl]
	ld	hl, input.level
	ld	[hl], a
; Reads trigger A value	
	call	GET_TRIGGER
	or	a
	jr	z, .ELSE_A ; not pressed
; Pressed: sets the bit value
	; ld	hl, input.level ; unnecessary
	set	BIT_TRIGGER_A, [hl]
.ELSE_A:
; Reads trigger B value
	call	GET_TRIGGER.B
	or	a
	jr	z, .ELSE_B ; not pressed
; Pressed: sets the bit value
	; ld	hl, input.level ; unnecessary
	set	BIT_TRIGGER_B, [hl]
.ELSE_B:
	
; Computes edge value from level value
	pop	af ; (restores previous level)
	cpl	; a = !previous
	; ld	hl, input.level ; unnecessary
	ld	b, [hl] ; b = current
	and	b ; a = !previous & current
	inc	hl ; hl = input.edge
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads both keyboard and joystick 1
; ret a: GTSTCK read value
GET_STICK:
; Reads keyboard
	xor	a
	call	GTSTCK
; Had value?
	or	a
	ret	nz ; yes
; No: reads joystick
	inc	a ; a = 1
	jp	GTSTCK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads both keyboard and joystick 1 trigger
; ret a: GTTRIG read value
GET_TRIGGER:
.A:
; Reads keyboard
	xor	a ; 0 -> SPACE KEY
	call	GTTRIG
; Had value?
	or	a
	ret	nz ; yes
; No: reads joystick
	inc	a ; a = 1 -> JOY 1, TRIGGER A
	jp	GTTRIG
.B:
IFDEF CFG_INPUT_TRIGGER_B_ROW
; Reads keyboard
	ld	a, [NEWKEY + CFG_INPUT_TRIGGER_B_ROW]
	and	(1 << CFG_INPUT_TRIGGER_B_BIT)
	jp	z, RET_NOT_ZERO
ENDIF ; IFDEF CFG_INPUT_TRIGGER_B_ROW
; Reads joystick
	ld	a, 3 ; 3 -> JOY 1, TRIGGER B
	jp	GTTRIG
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
	call	READ_INPUT
	and	1 << BIT_TRIGGER_A
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
	call	READ_INPUT
	and	1 << BIT_TRIGGER_A
	jr	z, WAIT_TRIGGER
	ret	; trigger (nz)
; -----------------------------------------------------------------------------

; EOF
