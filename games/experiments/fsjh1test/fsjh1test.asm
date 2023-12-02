
;
; =============================================================================
;	Panasonic FS-JH1 Joy Handle experiment using MSXlib
; =============================================================================
;


; -----------------------------------------------------------------------------
; MSXlib helper: default configuration
	include	"lib/rom-default.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
INIT:
; screen 1
	call	INIT32

; Charset and sprite patterns
	ld	hl, DATA_CHRTBL_PACKED
	call	UNPACK_LDIRVM_CHRTBL
	ld	hl, DATA_SPRTBL_PACKED
	ld	de, SPRTBL
	ld	bc, SPRTBL_SIZE
	call	UNPACK_LDIRVM
	ld	hl, DATA_SPRATR
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir

; Initialization
	ld	a, [frame_rate]
	sra	a
	add	1
	ld	[input_buffer.size], a
	cp	31
	ld	a, $31
	jr	z, .A_OK
	ld	a, $26
.A_OK:
	ld	[input_buffer.size_bcd], a
	call	RESET_INPUT_BUFFER_AND_VISUAL_FEEDBACK

; Initializes the NAMTBL buffer
	ld	hl, DATA_LITERALS
	ld	de, namtbl_buffer + SCR_WIDTH *  1
	call	PRINT_CENTERED_TEXT
	inc	hl
	ld	de, namtbl_buffer + SCR_WIDTH *  4
	call	PRINT_CENTERED_TEXT
	inc	hl
	ld	de, namtbl_buffer + SCR_WIDTH * 10
	call	PRINT_CENTERED_TEXT
	; inc	hl
	; ld	de, namtbl_buffer + SCR_WIDTH * 22
	; call	PRINT_CENTERED_TEXT
	; call	UPDATE_INPUT_BUFFER_SIZE.PRINT
; Enables the screen
	call	ENASCR_NO_FADE

; (infinite loop)
.LOOP:
	halt			; (sync)
	call	LDIRVM_NAMTBL	; Blits the NAMTBL buffer
	call	LDIRVM_SPRATR	; Blits the SPRATR buffer

; Emulates pulse
	call	UPDATE_INPUT_LEVEL
	call	VISUAL_FEEDBACK_INPUT

; 	call	UPDATE_INPUT_BUFFER_SIZE
; 	call	nz, RESET_INPUT_BUFFER_AND_VISUAL_FEEDBACK

; Accumulator algorithm
	call	UPDATE_INPUT_BUFFER
	call	UPDATE_ACCUMULATOR_FROM_INPUT_BUFFER
	call	UPDATE_NORMALIZED_FROM_ACCUMULATOR
; (visual)
	ld	a, [normalized]
	add	128 -4
	ld	[spratr_buffer + $14 + 1], a
	ld	a, [accumulator]
	add	128 -4
	ld	[spratr_buffer + $18 + 1], a

; FSM algorithm
	call	UPDATE_FSJH1
	call	UPDATE_NORMALIZED_FROM_FSJH1
; (visual)
	ld	a, [fsjh1.normalized]
	add	128 -4
	ld	[spratr_buffer + $28 + 1], a
	ld	a, [fsjh1.accumulator]
	add	128 -4
	ld	[spratr_buffer + $2c + 1], a

	jr	.LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param [input.level]
; ret updated [input.level]
; ret updated [input.edge]
UPDATE_INPUT_LEVEL:
; Checks JIFFY
	ld	hl, JIFFY
	ld	a, [hl]
	cp	60
	jr	c, .JIFFY_OK
	xor	a
	ld	[hl], a
.JIFFY_OK:
; Emulate pulse?
	cp	30
	ret	c ; no
; Emulate pulse?
	ld	a, [input.level]
	bit	BIT_TRIGGER_B, a
	ret	z ; no
; yes: emulates pulse (resets input)
	ld	hl, input.level
	res	BIT_STICK_LEFT, [hl]
	res	BIT_STICK_RIGHT, [hl]
	ld	hl, input.edge
	res	BIT_STICK_LEFT, [hl]
	res	BIT_STICK_RIGHT, [hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
VISUAL_FEEDBACK_INPUT:
	ld	a, [input.level]
	ld	b, a
	ld	a, [input.edge]
	ld	c, a

; Visual feedback (left)
	ld	a, 4
	bit	BIT_STICK_LEFT, b
	jr	z, .A_LEFT_OK
	ld	a, 10
	bit	BIT_STICK_LEFT, c
	jr	z, .A_LEFT_OK
	ld	a, 15
.A_LEFT_OK:
	ld	[spratr_buffer + $00 + 3], a
; Visual feedback (right)
	ld	a, 4
	bit	BIT_STICK_RIGHT, b
	jr	z, .A_RIGHT_OK
	ld	a, 10
	bit	BIT_STICK_RIGHT, c
	jr	z, .A_RIGHT_OK
	ld	a, 15
.A_RIGHT_OK:
	ld	[spratr_buffer + $04 + 3], a

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
UPDATE_INPUT_BUFFER_SIZE:
	ld	a, [input.edge]
	bit	BIT_STICK_UP, a
	jr	nz, .DO_INC
	bit	BIT_STICK_DOWN, a
	jr	nz, .DO_DEC
	ret

.DO_INC:
; Increases input buffer size
	ld	hl, [input_buffer.write_pointer]
	inc	l
	ld	[input_buffer.write_pointer], hl
; Increases input buffer size
	ld	hl, input_buffer.size
	inc	[hl]
	inc	hl ; input_buffer.size.bcd
	ld	a, [hl]
	add	1
	daa
	ld	[hl], a
	jr	.PRINT

.DO_DEC:
; Decreases input buffer size
	ld	hl, [input_buffer.write_pointer]
	dec	l
	ld	[input_buffer.write_pointer], hl
; Decreases input buffer size
	ld	hl, input_buffer.size
	dec	[hl]
	inc	hl ; input_buffer.size.bcd
	ld	a, [hl]
	sub	1
	daa
	ld	[hl], a
	jr	.PRINT

.PRINT:
	ld	hl, input_buffer.size_bcd
	ld	de, namtbl_buffer + SCR_WIDTH * 22 + 21
	call	PRINT_BCD
; ret nz
	or	-1
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
RESET_INPUT_BUFFER_AND_VISUAL_FEEDBACK:
	ld	hl, input_buffer
	ld	de, input_buffer + 1
	ld	bc, 256 - 1
	ld	[hl], 0
	ldir

	ld	a, [input_buffer.size]
	ld	b, a

	ld	hl, input_buffer
	ld	[input_buffer.read_pointer], hl
	ld	a, [input_buffer.size]
	call	ADD_HL_A
	ld	[input_buffer.write_pointer], hl

	; ld	a, [spratr_buffer + $04 + 1]
	; ld	[spratr_buffer + $00 + 1], a ; Algorithm 1
	; ld	[spratr_buffer + $18 + 1], a ; Algorithm 2

; Half left marker
	ld	c, b
	sra	c
	sub	c
	sub	4
	; ld	[spratr_buffer + $08 + 1], a ; Algorithm 1
	; ld	[spratr_buffer + $20 + 1], a ; Algorithm 2
	add	c
	add	c
	add	8
	; ld	[spratr_buffer + $0c + 1], a ; Algorithm 1
	; ld	[spratr_buffer + $24 + 1], a ; Algorithm 2

; Left/right visual feedback
	ld	a, [spratr_buffer + $04 + 1]
	sub	b
	sub	8
	; ld	[spratr_buffer + $10 + 1], a ; Algorithm 1
	; ld	[spratr_buffer + $28 + 1], a ; Algorithm 2
	add	b
	add	b
	add	16
	; ld	[spratr_buffer + $14 + 1], a ; Algorithm 1
	; ld	[spratr_buffer + $2c + 1], a ; Algorithm 2
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param [input.level]: current input.level
; ret a: current input.level
; ret b: previously buffered input.level
UPDATE_INPUT_BUFFER:
; Current valye
	ld	a, [input.level]
	and	$0c ; BIT_STICK_LEFT and BIT_STICK_RIGHT
; Saves
	ld	hl, [input_buffer.write_pointer]
	ld	[hl], a
	inc	l
	ld	[input_buffer.write_pointer], hl
; Previous value
	ld	hl, [input_buffer.read_pointer]
	ld	b, [hl]
	inc	l
	ld	[input_buffer.read_pointer], hl
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param [input.level]: current input.level
; param b: previously buffered input.level
UPDATE_ACCUMULATOR_FROM_INPUT_BUFFER:
	ld	hl, accumulator
; Based on the current input.level
	ld	a, [input.level]
	bit	BIT_STICK_LEFT, a
	jr	nz, .CURRENT_LEFT
	bit	BIT_STICK_RIGHT, a
	jr	nz, .CURRENT_RIGHT

.CURRENT_NONE:
; Based on the previously buffered input.level
	bit	BIT_STICK_LEFT, b
	jr	nz, .DO_INC
	bit	BIT_STICK_RIGHT, b
	jr	nz, .DO_DEC
	ret

.CURRENT_LEFT:
; Based on the previously buffered input.level
	bit	BIT_STICK_LEFT, b
	ret	nz
	bit	BIT_STICK_RIGHT, b
	jr	nz, .DO_DEC_x2
	jr	.DO_DEC

.CURRENT_RIGHT:
; Based on the previously buffered input.level
	bit	BIT_STICK_LEFT, b
	jr	nz, .DO_INC_x2
	bit	BIT_STICK_RIGHT, b
	ret	nz
	jr	.DO_INC

.DO_DEC_x2:
	dec	[hl]
.DO_DEC:
	dec	[hl]
	ret

.DO_INC_x2:
	inc	[hl]
.DO_INC:
	inc	[hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
UPDATE_NORMALIZED_FROM_ACCUMULATOR:
	ld	a, [hl]
	or	a
	jp	z, .A_OK ; (center)
	jp	m, .LEFT
; Right
	cp	31
	ld	a, 30
	jr	z, .A_OK
	ld	a, 15
	jr	.A_OK

.LEFT:
; Left
	cp	-31
	ld	a, -30
	jr	z, .A_OK
	ld	a, -15
	jr	.A_OK

.A_OK:
	inc	hl
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
UPDATE_FSJH1:
	ld	hl, .TABLE
	ld	a, [fsjh1.state]
	jp	JP_TABLE
.TABLE:
	dw	.CENTER		;  0
	dw	.LEFT_0s_START	;  1
	dw	.LEFT_1s_START	;  2
	dw	.LEFT_0s	;  3
	dw	.LEFT_1s	;  4
	dw	.LEFTMOST	;  5
	dw	.RIGHT_0s_START	;  6
	dw	.RIGHT_1s_START	;  7
	dw	.RIGHT_0s	;  8
	dw	.RIGHT_1s	;  9
	dw	.RIGHTMOST	; 10

; Center ----------------------------------------------------------------------

.SET_CENTER:
	xor	a
	ld	[fsjh1.state], a
	ret
.CENTER:
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_LEFT
	ret	nz
	call	.HANDLE_CHANGE_DIRECTION_RIGHT
	ret

; Left ------------------------------------------------------------------------

.SET_LEFT_0s_START:
	ld	a, 1
	ld	[fsjh1.state], a
	; ld	a, 1 ; (unnecessary)
	ld	[fsjh1.accumulator], a
	ret
.LEFT_0s_START:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_RIGHT
	ret	nz ; yes
; 1?
	bit	BIT_STICK_LEFT, a
	jp	nz, .SET_LEFT_1s_ON_1 ; yes: switch to expect 1s
; 0: Expected?
	ld	hl, fsjh1.accumulator
	ld	a, [hl]
	cp	30
	jp	z, .SET_CENTER ; no; too many 0s
; yes
	inc	[hl]
	ret

.SET_LEFT_1s_START:
	ld	a, 2
	ld	[fsjh1.state], a
	ld	a, 1
	ld	[fsjh1.accumulator], a
	ret
.LEFT_1s_START:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_RIGHT
	ret	nz ; yes
; 0?
	bit	BIT_STICK_LEFT, a
	jp	z, .SET_LEFT_0s_ON_0 ; yes: Switch to expect 0s
; 1: Expected?
	ld	hl, fsjh1.accumulator
	ld	a, [hl]
	cp	30
	jp	z, .SET_LEFTMOST ; no; too many 1s
; yes
	inc	[hl]
	ret

.SET_LEFT_0s:
	xor	a
	jr	.SET_LEFT_0s_A_OK
.SET_LEFT_0s_ON_0:
	ld	a, 1
.SET_LEFT_0s_A_OK:
	ld	[fsjh1.accumulator], a
	ld	a, 3
	ld	[fsjh1.state], a
	ret
.LEFT_0s:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_RIGHT
	ret	nz ; yes
; 1?
	bit	BIT_STICK_LEFT, a
	jp	nz, .SET_LEFTMOST ; yes
; 0: Last expected?
	ld	hl, fsjh1.accumulator
	ld	a, [hl]
	cp	29
	jp	z, .SET_LEFT_1s ; yes: change to expect 1s
; yes
	inc	[hl]
	ret

.SET_LEFT_1s:
	xor	a
	jr	.SET_LEFT_1s_A_OK
.SET_LEFT_1s_ON_1:
	ld	a, 1
.SET_LEFT_1s_A_OK:
	ld	[fsjh1.accumulator], a
	ld	a, 4
	ld	[fsjh1.state], a
	ret
.LEFT_1s:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_RIGHT
	ret	nz ; yes
; 0?
	bit	BIT_STICK_LEFT, a
	jp	z, .SET_CENTER ; yes
; 1: Last expected?
	ld	hl, fsjh1.accumulator
	ld	a, [hl]
	cp	29
	jp	z, .SET_LEFT_0s ; yes: change to expect 0s
; yes
	inc	[hl]
	ret

.SET_LEFTMOST:
	ld	a, 5
	ld	[fsjh1.state], a
	ret
.LEFTMOST:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_RIGHT
	ret	nz ; yes
; 0?
	bit	BIT_STICK_LEFT, a
	ret	nz ; no
; yes
	jp	.SET_LEFT_0s_START

; Right -----------------------------------------------------------------------

.SET_RIGHT_0s_START:
	ld	a, 6
	ld	[fsjh1.state], a
	ld	a, 1
	ld	[fsjh1.accumulator], a
	ret
.RIGHT_0s_START:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_LEFT
	ret	nz ; yes
; 1?
	bit	BIT_STICK_RIGHT, a
	jp	nz, .SET_RIGHT_1s_ON_1 ; yes: switch to expect 1s
; 0: Expected?
	ld	hl, fsjh1.accumulator
	ld	a, [hl]
	cp	30
	jp	z, .SET_CENTER ; no; too many 0s
; yes
	inc	[hl]
	ret

.SET_RIGHT_1s_START:
	ld	a, 7
	ld	[fsjh1.state], a
	ld	a, 1
	ld	[fsjh1.accumulator], a
	ret
.RIGHT_1s_START:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_LEFT
	ret	nz ; yes
; 0?
	bit	BIT_STICK_RIGHT, a
	jp	z, .SET_RIGHT_0s_ON_0 ; yes: Switch to expect 0s
; 1: Expected?
	ld	hl, fsjh1.accumulator
	ld	a, [hl]
	cp	30
	jp	z, .SET_RIGHTMOST ; no; too many 1s
; yes
	inc	[hl]
	ret

.SET_RIGHT_0s:
	xor	a
	jr	.SET_RIGHT_0s_A_OK
.SET_RIGHT_0s_ON_0:
	ld	a, 1
.SET_RIGHT_0s_A_OK:
	ld	[fsjh1.accumulator], a
	ld	a, 8
	ld	[fsjh1.state], a
	ret
.RIGHT_0s:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_LEFT
	ret	nz ; yes
; 1?
	bit	BIT_STICK_RIGHT, a
	jp	nz, .SET_RIGHTMOST ; yes
; 0: Last expected?
	ld	hl, fsjh1.accumulator
	ld	a, [hl]
	cp	29
	jp	z, .SET_RIGHT_1s ; yes: change to expect 1s
; yes
	inc	[hl]
	ret

.SET_RIGHT_1s:
	xor	a
	jr	.SET_RIGHT_1s_A_OK
.SET_RIGHT_1s_ON_1:
	ld	a, 1
.SET_RIGHT_1s_A_OK:
	ld	[fsjh1.accumulator], a
	ld	a, 9
	ld	[fsjh1.state], a
	ret
.RIGHT_1s:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_LEFT
	ret	nz ; yes
; 0?
	bit	BIT_STICK_RIGHT, a
	jp	z, .SET_CENTER ; yes
; 1: Last expected?
	ld	hl, fsjh1.accumulator
	ld	a, [hl]
	cp	29
	jp	z, .SET_RIGHT_0s ; yes: change to expect 0s
; yes
	inc	[hl]
	ret

.SET_RIGHTMOST:
	ld	a, 10
	ld	[fsjh1.state], a
	ret
.RIGHTMOST:
; Direction change?
	ld	a, [input.level]
	call	.HANDLE_CHANGE_DIRECTION_LEFT
	ret	nz ; yes
; 0?
	bit	BIT_STICK_RIGHT, a
	ret	nz ; no
; yes
	jp	.SET_RIGHT_0s_START

; Auxiliary functions ---------------------------------------------------------

.HANDLE_CHANGE_DIRECTION_LEFT:
	bit	BIT_STICK_LEFT, a
	ret	z
; Enters turning left
	ld	a, 2 ; .LEFT_1s_START
	ld	[fsjh1.state], a
	ld	a, 1
	ld	[fsjh1.accumulator], a
	or	a ; (ret nz)
	ret

.HANDLE_CHANGE_DIRECTION_RIGHT:
	bit	BIT_STICK_RIGHT, a
	ret	z
; Enters turning left
	ld	a, 7 ; .RIGHT_1s_START
	ld	[fsjh1.state], a
	ld	a, 1
	ld	[fsjh1.accumulator], a
	or	a ; (ret nz)
	ret

; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
UPDATE_NORMALIZED_FROM_FSJH1:
	ld	hl, .TABLE
	ld	a, [fsjh1.state]
	call	GET_HL_A_BYTE
	ld	[fsjh1.normalized], a
	ret

.TABLE:
	db	  0 ;  0 ; .CENTER
	db	-15 ;  1 ; .LEFT_0s_START
	db	-15 ;  2 ; .LEFT_1s_START
	db	-15 ;  3 ; .LEFT_0s
	db	-15 ;  4 ; .LEFT_1s
	db	-30 ;  5 ; .LEFTMOST
	db	 15 ;  6 ; .RIGHT_0s_START
	db	 15 ;  7 ; .RIGHT_1s_START
	db	 15 ;  8 ; .RIGHT_0s
	db	 15 ;  9 ; .RIGHT_1s
	db	 30 ; 10 ; .RIGHTMOST
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
DATA_CHRTBL_PACKED:
	incbin	"games/examples/shared/charset.png.chr.zx0"
DATA_CLRTBL_PACKED:
	incbin	"games/examples/shared/charset.png.clr.zx0"
DATA_SPRTBL_PACKED:
	incbin	"games/experiments/shared/sprites.png.spr.zx0"

DATA_SPRATR:
; Input feedback
	db	176 -1,  48 -4, $08,  4
	db	176 -1, 208 -4, $0c,  4
; Accumulator algorithm
	db	 40 -1, 128 -30 -4, $04,  4 ; markers
	db	 40 -1, 128     -4, $04,  4 ; markers
	db	 40 -1, 128 +30 -4, $04,  4 ; markers
	db	 56 -1, 128     -4, $00, 15 ; accumulator value
	db	 56 -1, 128     -4, $00, 13 ; normalized value
; Algorithm 2
	db	 88 -1, 128 -30 -4, $04,  4 ; markers
	db	 88 -1, 128     -4, $04,  4 ; markers
	db	 88 -1, 128 +30 -4, $04,  4 ; markers
	db	104 -1, 128     -4, $00, 15 ; normalized value
	db	112 -1, 128     -4, $00, 13 ; countdown value

	db	SPAT_END

DATA_LITERALS:
	db	"Panasonic FS-JH1 test", $00
	db	"Accumulator algorithm:", $00
	db	"FSM algorithm:", $00
	; db	"Buffer size: 00", $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
	include	"lib/rom_end.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"

; Accumulator algorithm: accumulator
accumulator:	rb 1
normalized:	rb 1

; FSM algorithm
fsjh1:
	.state:		rb 1
	.accumulator:	rb 1
	.normalized:	rb 1

	rb	($ OR $00ff) -$ +1 ; (align to 256 bytes boundary)
; Accumulator algorithm: Input circular buffer
input_buffer:
	rb	256
	.read_pointer:	rw 1
	.write_pointer:	rw 1
	.size:		rb 1 ; Requested size, in bytes
	.size_bcd:	rb 1 ; Requested size, in bytes (BCD)
; -----------------------------------------------------------------------------

	include	"lib/ram_end.asm"

; EOF
