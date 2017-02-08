
; =============================================================================
;	Input, timing & pause routines (BIOS-based)
; =============================================================================

; -----------------------------------------------------------------------------
; Bits returned by GET_STICK_BITS
	BIT_STICK_UP:		equ 0
	BIT_STICK_RIGHT:	equ 1
	BIT_STICK_DOWN:		equ 2
	BIT_STICK_LEFT:		equ 3

; Bit map values table
STICK_BITS_TABLE:
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
; Reads both keyboard and joystick 1 as a bit map
; ret [stick]: current bit map (level)
; ret a / [stick_edge]: bits that went from off to on (edge)
GET_STICK_BITS:
; Reads the value
	call	GET_STICK
; Reads the bit map value
	ld	hl, STICK_BITS_TABLE
	call	ADD_HL_A
	ld	b, [hl] ; b = level
; Builts edge value from level value
	ld	hl, stick
	ld	a, [hl] ; previous level in a
	ld	[hl], b ; updates level
	cpl
	and	b ; a = current & !previous
	inc	hl ; hl = stick_edge
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads both keyboard and joystick 1 trigger
; ret a / [trigger]: current GTTRIG read value (level)
; ret nz: if the trigger went from off to on (edge)
GET_TRIGGER:
; Reads keyboard
	xor	a
	call	GTTRIG
; Had value?
	or	a
	jr	nz, .ON ; yes
; No: reads joystick
	inc	a ; a = 1
	call	GTTRIG
	or	a
	jr	nz, .ON
; off
	ld	[trigger], a
	ret	; ret z
.ON:
	ld	hl, trigger
	cp	[hl] ; for ret z / nz
	ld	[hl], a
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
; touches: b, hl
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
TRIGGER_PAUSE_FOUR_SECONDS:
	ld	a, [frame_rate]
	add	a
	add	a
	jr	TRIGGER_PAUSE_A
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Skippable one second pause
; ret nz: if the trigger went from off to on (edge)
; ret z: if the pause timed out
; touches: a, bc, de, hl
TRIGGER_PAUSE_ONE_SECOND:
	ld	a, [frame_rate]
	; jr	TRIGGER_PAUSE_A ; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Skippable pause
; param a: pause length (in frames)
; ret nz: if the trigger went from off to on (edge)
; ret z: if the pause timed out
; touches: a, bc, de, hl
TRIGGER_PAUSE_A:
	ld	b, a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Skippable pause
; param b: pause length (in frames)
; ret nz: if the trigger went from off to on (edge)
; ret z: if the pause timed out
; touches: a, bc, de, hl
TRIGGER_PAUSE:
	push	bc ; preserves counter
	halt
	call	GET_TRIGGER
	pop	bc ; restores counter
	ret	nz ; trigger
	djnz	TRIGGER_PAUSE
	ret	; no trigger (z)
; -----------------------------------------------------------------------------

; EOF
