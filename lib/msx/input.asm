
; =============================================================================
;	Input, timing & pause routines (BIOS-based)
; =============================================================================

; -----------------------------------------------------------------------------
; Bit of the return values of GET_STICK_BITS
	BIT_STICK_UP		equ 0
	BIT_STICK_RIGHT		equ 1
	BIT_STICK_DOWN		equ 2
	BIT_STICK_LEFT		equ 3
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
	add	l ; hl += a
	ld	l, a
	adc	h
	sub	l
	ld	h, a
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
	jr	nz, @@ON ; yes
; No: reads joystick
	inc	a ; a = 1
	call	GTTRIG
	or	a
	jr	nz, @@ON
; off
	ld	[trigger], a
	ret	; ret z
@@ON:
	ld	hl, trigger
	cp	[hl] ; for ret z / nz
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pausa de uno, dos y cuatro segundos
; touches b, hl
WAIT_FOUR_SECONDS:
	call	WAIT_TWO_SECONDS
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
WAIT_TWO_SECONDS:
	call	WAIT_ONE_SECOND
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
WAIT_ONE_SECOND:
	ld	hl, frame_rate
	ld	b, [hl]
	; jr	WAIT_FRAMES ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Pausa de un número determinado de frames
; param b: número de frames de duración de la pausa
; touches b, hl
WAIT_FRAMES:
	halt
	djnz	WAIT_FRAMES
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pausa de cuatro segundos abortable pulsando el disparador
; (ver TRIGGER_PAUSE)
TRIGGER_PAUSE_FOUR_SECONDS:
	ld	a, [frame_rate]
	add	a
	add	a
	jr	TRIGGER_PAUSE_A
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pausa de un segundo abortable pulsando el disparador
; (ver TRIGGER_PAUSE)
TRIGGER_PAUSE_ONE_SECOND:
	ld	a, [frame_rate]
	; jr	TRIGGER_PAUSE_A ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Pausa abortable pulsando el disparador
; param a/b: número de frames de duración de la pausa
; touches a, bc, de, hl
; ret nz: se ha pulsado el disparador
; ret z: se ha agotado la pausa
TRIGGER_PAUSE_A:
	ld	b, a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
TRIGGER_PAUSE:
	push	bc
	halt
	call	GET_TRIGGER
	pop	bc
	ret	nz ; trigger
	djnz	TRIGGER_PAUSE
	ret	; z = no trigger
; -----------------------------------------------------------------------------

; EOF