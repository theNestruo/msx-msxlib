
; =============================================================================
;	Timing and wait routines
; =============================================================================

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

IFEXIST READ_INPUT

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
IFDEF CFG_HOOK_DISABLE_AUTO_INPUT
	push	bc ; preserves counter
	halt
	call	READ_INPUT
	pop	bc ; restores counter
ELSE
	halt
	ld	a, [input.edge]
ENDIF
	bit	BIT_TRIGGER_A, a
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

ENDIF ; IFEXIST READ_INPUT

; ; -----------------------------------------------------------------------------
; ; Waits until no key is pressed
; WAIT_NO_KEY:
; 	halt
; ; Ten lines
; 	ld	b, 11
; 	ld	d, $ff
; .LOOP:
; ; Reads keyboard matrix line
; 	ld	a, b
; 	dec	a ; check lines from 10 to 0
; 	call	SNSMAT
; ; Aggregates (AND) the result in d
; 	and	d
; 	ld	d, a
; 	djnz	.LOOP
; ; If no keys were pressed, d will be $ff
; 	; ld	a, d ; (unnecessary)
; 	inc	a ; $ff becomes $00
; 	ret	z
; 	jr	WAIT_NO_KEY
; ; -----------------------------------------------------------------------------

; EOF
