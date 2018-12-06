
;
; =============================================================================
;	MSXlib basic example: snake game
; =============================================================================
;

	SNAKE_CHAR:	equ $02
	FRUIT_CHAR:	equ $03
	EMPTY_CHAR:	equ $20

; -----------------------------------------------------------------------------
; MSXlib helper: default configuration
	include	"lib/rom-default.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
INIT:

; Besides the minimal initialization, the MSXlib hook has been installed
; And VRAM buffer, text, and logical coordinates sprites routines are available
; as well as input, timing & pause routines

;
; YOUR CODE (ROM) START HERE
;

; Initialization
	call	INIT_CHARSET	; Initializes the charset	
.LOOP:
	call	INIT_SCREEN	; Initializes the screen
	call	INIT_VARIABLES	; Pre-initializes the game
	call	PRINT_SNAKE	; (initial print of the snake)
; Re-enables the screen, but using a fade-in to blit the NAMTBL buffer
	call	ENASCR_FADE_IN
	
; Waits for the space key
	call	WAIT_SPACE_KEY
	
; In-game loop
	call	GAME_LOOP
	
; Game over
	call	GAME_OVER
	
; Waits for the space key
	call	WAIT_SPACE_KEY

; Disables the screen, using a fade-out
	call	DISSCR_FADE_OUT
	
	jr	.LOOP
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Prepares the VRAM buffer of the NAMTBL
INIT_CHARSET:
; Uses MSXlib convenience routines
; to unpack and LDIRVM the charset to the three banks
	ld	hl, .MY_CHRTBL_PACKED
	call	UNPACK_LDIRVM_CHRTBL
	ld	hl, .MY_CLRTBL_PACKED
	jp	UNPACK_LDIRVM_CLRTBL

; The shared data of the examples
.MY_CHRTBL_PACKED:
	incbin	"examples/shared/charset.pcx.chr.zx7"
.MY_CLRTBL_PACKED:
	incbin	"examples/shared/charset.pcx.clr.zx7"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prepares the VRAM buffer of the NAMTBL
INIT_SCREEN:
	call	CLS_NAMTBL
	
; Top text
	ld	hl, .TXT_TITLE
	ld	de, namtbl_buffer ; de = (0, 0)
	call	PRINT_CENTERED_TEXT

; Prints the top border
	ld	hl, namtbl_buffer + 2 *SCR_WIDTH ; hl = (0, 2)
	ld	b, SCR_WIDTH
	ld	a, $80 ; top red bricks
.TOP_LOOP:
	ld	[hl], a ; prints the brick
	inc	hl ; moves the cursor right
	djnz	.TOP_LOOP

; Prints the bottom border	
	ld	b, SCR_WIDTH
	ld	hl, namtbl_buffer + 21 *SCR_WIDTH ; hl = (0, 21)
	ld	a, $80 ; top red bricks
.BOTTOM_LOOP:
	ld	[hl], a ; prints the brick
	inc	hl ; moves the cursor right
	djnz	.BOTTOM_LOOP

; Prints the borders of the sides
	ld	b, SCR_HEIGHT - 5
	ld	hl, namtbl_buffer + 3 *SCR_WIDTH ; hl = (0, 3)
	ld	a, $90 ; red bricks
.SIDES_LOOP:
	push	bc ; (preserves the b counter)
	ld	[hl], a ; prints the left brick
	ld	bc, SCR_WIDTH -1 ; moves the cursor to the rightmost column
	add	hl, bc
	ld	[hl], a ; prints the right brick
	inc	hl ; the cursor points to the left of the next line
	pop	bc ; (restores the b counter)
	djnz	.SIDES_LOOP
	
	ret
	
.TXT_TITLE:
	db	"MSXLIB EXAMPLE: SNAKE", $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_VARIABLES:
; Tail of the snake at 15,11
	xor	a ; a = 0
	ld	[tail_index], a ; tail_index = 0
	ld	hl, namtbl_buffer + 11 *SCR_WIDTH + 15; hl = (15, 11)
	ld	[snake_buffer], hl
	
; Head of the snake at 16,11
	inc	a ; a = 1
	ld	[head_index], a ; head_index = 1
	inc	hl ; hl = (16, 11)
	ld	[snake_buffer + 2], hl
	
; Initial direction: right
	ld	a, 3
	ld	[direction], a ; direction = 3
	
; Initial score: 0
	ld	hl, $0000
	ld	[score], hl
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
WAIT_SPACE_KEY:

; Prints the "PUSH SPACE KEY" text
	ld	hl, .TXT_PUSH_SPACE_KEY
	ld	de, namtbl_buffer + 23 *SCR_WIDTH ; hl = (0, 23)
	push	de ; (preserves the NAMTBL buffer pointer)
	call	PRINT_CENTERED_TEXT

; Blits the NAMTBL buffer
	call	LDIRVM_NAMTBL
	
; Waits for the trigger
	call	WAIT_TRIGGER
	
; Clears the text
	pop	hl ; (restores the NAMTBL buffer pointer)
	call	CLEAR_LINE

; Blits the NAMTBL buffer and ends
	jp	LDIRVM_NAMTBL
	
.TXT_PUSH_SPACE_KEY:
	db	"PUSH SPACE KEY", $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop
GAME_LOOP:
; Prints the initial fruit
	call	PRINT_FRUIT
	
.LOOP:
; Blits the NAMTBL buffer
	halt ; (sync)
	call	PRINT_SNAKE
	call	LDIRVM_NAMTBL
; (reduces the FPS; otherwise the game is unplayable)
	halt
	halt
	
; Handles the input and computes the new position of the head
	call	UPDATE_DIRECTION
	call	APPLY_DIRECTION
	
; Checks collisions
	ld	a, [hl] ; Reads the character under the new position of the head
	ex	de, hl ; (preserves new NAMTBL pointer of the head in de)
	
; Is it empty space?
	cp	EMPTY_CHAR
	jr	nz, .NOT_EMPTY
; yes: moves head and tail of the snake
	call	INC_SNAKE_HEAD
	call	INC_SNAKE_TAIL
	call	SAVE_SNAKE_HEAD
	jr	.LOOP
.NOT_EMPTY:
	
; Is a fruit?
	cp	FRUIT_CHAR
	jr	nz, .NO_FRUIT
; yes: moves head and puts a new fruit
	call	INC_SNAKE_HEAD
	call	SAVE_SNAKE_HEAD
	call	PRINT_FRUIT
	jr	.LOOP
.NO_FRUIT:

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
PRINT_FRUIT:
	
; Looks for a random value in the range 0..1023
	ld	a, r ; h = 0..3
	and	$03 ; (for faster checks)
	ld	h, a
	ld	a, r ; l = 0..255
	ld	l, a 
	push	hl ; (preserves the value)
; Is inside the game area?
	ld	de, NAMTBL_SIZE - (6*SCR_WIDTH)
	call	DCOMPR
	pop	bc ; (restores the value in bc)
	jr	nc, PRINT_FRUIT ; no: retry
	
; yes: Compues the actual NAMTBL buffer pointer
	ld	hl, namtbl_buffer + 3 *SCR_WIDTH
	add	hl, bc
	
; Is it an empty space?
	ld	a, [hl]
	cp	EMPTY_CHAR
	jr	nz, PRINT_FRUIT ; no: retry
	
; Yes: saves the fruit
	ld	a, FRUIT_CHAR
	ld	[hl], a
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Handles the input
UPDATE_DIRECTION:
	ld	a, [input.level]
	
; Checks left
	bit	BIT_STICK_LEFT, a
	jr	z, .NOT_LEFT ; no
.LEFT:
; yes: saves the "LEFT" direction
	ld	a, 7
	ld	[direction], a
	ret
.NOT_LEFT:
	
; Checks right
	bit	BIT_STICK_RIGHT, a
	jr	z, .NOT_RIGHT ; no
; yes: saves the "RIGHT" direction
.RIGHT:
	ld	a, 3
	ld	[direction], a
	ret
.NOT_RIGHT:
	
; Checks up
	bit	BIT_STICK_UP, a
	jr	z, .NOT_UP ; no
; yes: saves the "UP" direction
.UP:
	ld	a, 1
	ld	[direction], a
	ret
.NOT_UP:
	
; Checks down
	bit	BIT_STICK_DOWN, a
	jr	z, .NOT_DOWN ; no
; no: saves the "DOWN" direction
.DOWN:
	ld	a, 5
	ld	[direction], a
	ret
.NOT_DOWN:
	
; No valid input: will keep the existing direction
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Computes the new position of the head
; ret hl: NAMTBL pointer of the new position of the head
APPLY_DIRECTION:
; Uses a jump table to react to the direction
	ld	a, [direction] ; a = 1, 3, 5, 7
	dec	a ; a = 0, 2, 4, 6
	ld	hl, .JUMP_TABLE
	jp	JP_TABLE_2
	
.JUMP_TABLE:
	dw	.MOVE_UP	; 1 -> 0
	dw	.MOVE_RIGHT	; 3 -> 2
	dw	.MOVE_DOWN	; 5 -> 4
	dw	.MOVE_LEFT	; 7 -> 6
	
; Up: will move the head (0, -1)
.MOVE_UP:
	ld	bc, -SCR_WIDTH
	jr	.DO_MOVE
	
; Right: will move the head (+1, 0)
.MOVE_RIGHT:
	ld	bc, 1
	jr	.DO_MOVE

; Down: will move the head (0, +1)
.MOVE_DOWN:
	ld	bc, SCR_WIDTH
	jr	.DO_MOVE
	
; Left: will move the head (-1, 0)
.MOVE_LEFT:
	ld	bc, -1
	jr	.DO_MOVE
	
.DO_MOVE:
; Gets the NAMTBL pointer of the head of the snake
	ld	hl, snake_buffer
	ld	a, [head_index] ; a = 0, 1, 2...
	add	a, a ; a *= 2 = 0, 2, 4...
	call	GET_HL_A_WORD
	
; Applies the delta (bc) to the current NAMTBL pointer of the head
	add	hl, bc
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the head index one position ahead
INC_SNAKE_HEAD:
	ld	hl, head_index
	inc	[hl]
	ret
	
; Moves the tail index one position ahead
INC_SNAKE_TAIL:
	ld	hl, tail_index
	inc	[hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param de: NAMTBL pointer of the new position of the head
SAVE_SNAKE_HEAD:
; Saves the new NAMTBL pointer of the head
	ld	a, [head_index] ; a = 0, 1, 2...
	add	a, a ; a *= 2 = 0, 2, 4...
; hl = snake_buffer[head_index]
	ld	hl, snake_buffer
	call	ADD_HL_A
; [hl] = de
	ld	[hl], e
	inc	hl
	ld	[hl], d
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
PRINT_SNAKE:
; Gets the NAMTBL pointer of the head of the snake
	ld	hl, snake_buffer
	ld	a, [head_index] ; a = 0, 1, 2...
	add	a, a ; a *= 2 = 0, 2, 4...
	call	GET_HL_A_WORD
	
; Prints the head of the snake
	ld	a, SNAKE_CHAR
	ld	[hl], a

; Gets the NAMTBL pointer of the tail of the snake
	ld	hl, snake_buffer
	ld	a, [tail_index] ; a = 0, 1, 2...
	add	a, a ; a *= 2 = 0, 2, 4...
	call	GET_HL_A_WORD
	
; Clears the tail of the snake
	ld	a, EMPTY_CHAR ; ' '
	ld	[hl], a
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
GAME_OVER:

; Prints the "GAME_OVER" text
	ld	hl, .TXT_GAME_OVER
	ld	de, namtbl_buffer + 11 *SCR_WIDTH ; hl = (0, 11)
	jp	PRINT_CENTERED_TEXT

.TXT_GAME_OVER:
	db	"GAME OVER!", $00
; -----------------------------------------------------------------------------

	include	"lib/msx/rom_end.asm"

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"

; lib/ram.asm automatically starts the RAM section at the proper address
; (either $C000 (16KB) or $E000 (8KB)) and includes everything MSXlib requires.

;
; YOUR VARIABLES (RAM) START HERE
;
head_index:
	rb	1 ; index of the snake_buffer with the head
tail_index:
	rb	1 ; index of the snake_buffer with the tail
snake_buffer:
	rb	256 * 2	; up to 256 snake segments (pointers to namtbl_buffer)
	.SIZE:	equ $ - snake_buffer
	
direction:
	rb	1
	
score:
	rw	1

; -----------------------------------------------------------------------------

	include	"lib/msx/ram_end.asm"

; EOF
