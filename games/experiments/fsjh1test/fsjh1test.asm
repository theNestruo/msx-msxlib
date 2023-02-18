
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
	ld	[input_buffer.size], a
	cp	30
	ld	a, $30
	jr	z, .A_OK
	ld	a, $25
.A_OK:
	ld	[input_buffer.size_bcd], a
	call	RESET_INPUT_BUFFER_AND_VISUAL_FEEDBACK

; Initializes the NAMTBL buffer
	ld	hl, DATA_LITERALS
	ld	de, namtbl_buffer + SCR_WIDTH
	call	PRINT_CENTERED_TEXT
	inc	hl
	ld	de, namtbl_buffer + SCR_WIDTH * 22
	call	PRINT_CENTERED_TEXT
	call	UPDATE_INPUT_BUFFER_SIZE.PRINT
; Enables the screen
	call	ENASCR_NO_FADE

; (infinite loop)
.LOOP:
	halt			; (sync)
	call	LDIRVM_NAMTBL	; Blits the NAMTBL buffer
	call	LDIRVM_SPRATR	; Blits the SPRATR buffer

	call	UPDATE_INPUT_BUFFER_SIZE
	call	nz, RESET_INPUT_BUFFER_AND_VISUAL_FEEDBACK

	call	VISUAL_FEEDBACK

	call	READ_INPUT_BUFFER
	ld	hl, spratr_buffer + 1
	call	APPLY_BUFFERED_INPUT_TO_HL

	jr	.LOOP
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

	ld	a, [spratr_buffer + $04 + 1]
	ld	[spratr_buffer + $00 + 1], a

; Half left marker
	ld	c, b
	sra	c
	sub	c
	sub	4
	ld	[spratr_buffer + $08 + 1], a
	add	c
	add	c
	add	8
	ld	[spratr_buffer + $0c + 1], a

; Left/right visual feedback
	ld	a, [spratr_buffer + $04 + 1]
	sub	b
	sub	8
	ld	[spratr_buffer + $10 + 1], a
	add	b
	add	b
	add	16
	ld	[spratr_buffer + $14 + 1], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
VISUAL_FEEDBACK:
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
	ld	[spratr_buffer + $10 + 3], a

; Visual feedback (right)
	ld	a, 4
	bit	BIT_STICK_RIGHT, b
	jr	z, .A_RIGHT_OK
	ld	a, 10
	bit	BIT_STICK_RIGHT, c
	jr	z, .A_RIGHT_OK
	ld	a, 15
.A_RIGHT_OK:
	ld	[spratr_buffer + $14 + 3], a

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ret a: current input.level
; ret b: previously buffered input.level
READ_INPUT_BUFFER:
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
; param a: current input.level
; param b: previously buffered input.level
; param hl: the address of the value to update
APPLY_BUFFERED_INPUT_TO_HL:

; Based on the current input.level
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
DATA_CHRTBL_PACKED:
	incbin	"games/examples/shared/charset.png.chr.zx0"
DATA_CLRTBL_PACKED:
	incbin	"games/examples/shared/charset.png.clr.zx0"
DATA_SPRTBL_PACKED:
	incbin	"games/experiments/shared/sprites.png.spr.zx0"

DATA_SPRATR:
	db	96 -1, 128 -4, $00, 7
	db	80 -1, 128 -4, $04, 6
	db	80 -1, 128 -4, $04, 6
	db	80 -1, 128 -4, $04, 6
	db	96 -1, 128 -4, $08, 4
	db	96 -1, 128 -4, $0c, 4
	db	SPAT_END

DATA_LITERALS:
	db	"Panasonic FS-JH1 test", $00
	db	"Buffer size: 00", $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
	include	"lib/rom_end.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"

	rb	($ OR $00ff) -$ +1 ; (align to 256 bytes boundary)

; Input circular buffer
input_buffer:
	rb	256
	.read_pointer:	rw 1
	.write_pointer:	rw 1
	.size:		rb 1 ; Requested size, in bytes
	.size_bcd:	rb 1 ; Requested size, in bytes (BCD)

; -----------------------------------------------------------------------------

	include	"lib/ram_end.asm"

; EOF
