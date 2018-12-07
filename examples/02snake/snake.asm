
;
; =============================================================================
;	MSXlib basic example: snake game
; =============================================================================
;

; Symbolic constants to easily change the characters used in the game
	SNAKE_CHAR:		equ $01
	FRUIT_CHAR:		equ $03
	EMPTY_CHAR:		equ $20
	BORDER_TOP_CHAR:	equ $84
	BORDER_BOTTOM_CHAR:	equ $84
	BORDER_SIDES_CHAR:	equ $94

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
	ld	hl, $1000	; Initial high score: 1000 points (l=$00 h=$10 '00')
	ld	[high_score], hl
.LOOP:
	call	INIT_SCREEN	; Initializes the screen
	call	INIT_VARIABLES	; Pre-initializes the game
	call	PRINT_SNAKE	; Initial print of the snake to be visible on "title" screen
	call	NEW_FRUIT	; Prints the initial fruit to be visible on "title" screen
	call	ENASCR_FADE_IN	; Re-enables the screen, but using a fade-in to blit the NAMTBL buffer
	call	WAIT_SPACE_KEY	; Waits for the space key
	call	GAME_LOOP	; Executes the in-game loop
	call	GAME_OVER	; Game over
	call	WAIT_SPACE_KEY	; Waits for the space key
	call	DISSCR_FADE_OUT	; Disables the screen, using a fade-out
	jr	.LOOP		; Re-start
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Initializes the charset
; This routine uses MSXlib convenience routines
; to unpack and LDIRVM the charset to the three banks
INIT_CHARSET:

; Invokes UNPACK_LDIRVM_CHRTBL with hl pointing to the packed CHRTBL definition
	ld	hl, .CHRTBL_PACKED
	call	UNPACK_LDIRVM_CHRTBL

; Invokes UNPACK_LDIRVM_CLRTBL with hl pointing to the packed CLRTBL definition
	ld	hl, .CLRTBL_PACKED
	jp	UNPACK_LDIRVM_CLRTBL

; The data is the shared data of the examples
.CHRTBL_PACKED:
	incbin	"examples/shared/charset.pcx.chr.zx7"
	
.CLRTBL_PACKED:
	incbin	"examples/shared/charset.pcx.clr.zx7"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes the screen in the NAMTBL buffer
INIT_SCREEN:

; Clears the NAMTBL buffer
	call	CLS_NAMTBL
	
; Prints the title, centered
	ld	hl, .TXT_TITLE ; hl = source text
	ld	de, namtbl_buffer + 2 *SCR_WIDTH ; de = destination row: (0, 2)
	call	PRINT_CENTERED_TEXT
	
; Prints the hud
	ld	hl, .TXT_SCORE ; hl = source text
	ld	de, namtbl_buffer + 1 ; de = destination: (1, 0)
	call	PRINT_TEXT
	ld	hl, .TXT_HIGH_SCORE ; hl = source text
	ld	de, namtbl_buffer + 16 ; de = destination: (16, 0)
	call	PRINT_TEXT
	
; Prints the actual value of the high score
	call	PRINT_HI_SCORE

; This loop prints the top border
	ld	hl, namtbl_buffer + 3 *SCR_WIDTH ; hl = (0, 3)
	ld	b, SCR_WIDTH ; 32 iterations / characters
	ld	a, BORDER_TOP_CHAR
.TOP_LOOP:
	ld	[hl], a ; prints the brick
	inc	hl ; moves the cursor right
	djnz	.TOP_LOOP

; This loop prints the bottom border	
	ld	b, SCR_WIDTH ; Again, 32 iterations / characters
	ld	hl, namtbl_buffer + 20 *SCR_WIDTH ; hl = (0, 20)
	ld	a, BORDER_BOTTOM_CHAR
.BOTTOM_LOOP:
	ld	[hl], a ; prints the brick
	inc	hl ; moves the cursor right
	djnz	.BOTTOM_LOOP

; This loop prints both sides border
	ld	b, SCR_HEIGHT -4 -4 ; 24 lines - 4 top - 4 bottom 
	ld	hl, namtbl_buffer + 4 *SCR_WIDTH ; hl = (0, 4)
	ld	a, BORDER_SIDES_CHAR
.SIDES_LOOP:
	push	bc ; (preserves the b counter)
	ld	[hl], a ; prints the left brick
	ld	bc, SCR_WIDTH -1 ; moves the cursor (+31,0) to the rightmost column
	add	hl, bc
	ld	[hl], a ; prints the right brick
	inc	hl ; the cursor will point to the leftmost column of the next line
	pop	bc ; (restores the b counter)
	djnz	.SIDES_LOOP
	
	ret
	
; null-terminated strings
.TXT_TITLE:
	db	$eb, $ec, $ed, $ee, $ef, "SNAKE", ASCII_NUL ; NUL (null) = $00
.TXT_SCORE:
	db	"SCORE 000000", ASCII_NUL ; NUL (null) = $00
.TXT_HIGH_SCORE:
	db	"HI-SCORE 000000", ASCII_NUL ; NUL (null) = $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pre-initializes the game
INIT_VARIABLES:

; Position the tail of the snake at (30,19)
	xor	a ; a = 0
	ld	[tail_index], a ; tail_index = 0
	ld	hl, namtbl_buffer + 19 *SCR_WIDTH + 30; hl = (30, 19)
	ld	[snake_buffer], hl
	
; Position the head of the snake at (29,19)
	inc	a ; a = 1
	ld	[head_index], a ; head_index = 1
	dec	hl ; hl = (29, 19)
	ld	[snake_buffer + 2], hl
	
; Initial direction: "UP"
	ld	a, 1
	ld	[direction], a ; direction = 1 = "UP"
	
; Initial score: 0
	ld	hl, $0000
	ld	[score], hl
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Waits for the space key
WAIT_SPACE_KEY:

; Prints the "PUSH SPACE KEY" text (in the NAMTBL buffer)
	ld	hl, .TXT_PUSH_SPACE_KEY
	ld	de, namtbl_buffer + 22 *SCR_WIDTH ; hl = (0, 22)
	call	PRINT_CENTERED_TEXT

; Blits the NAMTBL buffer so the text is visible
	call	LDIRVM_NAMTBL
	
; Waits for the trigger
	call	WAIT_TRIGGER
	
; Clears the text (in the NAMTBL buffer)
	ld	hl, namtbl_buffer + 22 *SCR_WIDTH ; hl = (0, 22)
	call	CLEAR_LINE

; Blits the NAMTBL buffer again (so the text is hidden) and ends
	jp	LDIRVM_NAMTBL
	
; null-terminated string
.TXT_PUSH_SPACE_KEY:
	db	"PUSH SPACE KEY",  ASCII_NUL ; NUL (null) = $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop
GAME_LOOP:

; Resets the frame counter to sync the first loop
	xor	a
	ld	[JIFFY], a

.LOOP:
; Every frame
	call	PRINT_SNAKE		; Prepares the snake in the NAMTBL buffer
	halt	; (sync)
	call	LDIRVM_NAMTBL		; Blits the NAMTBL buffer
	call	UPDATE_DIRECTION	; Handles the input
	
; Updates the game status every 4 frames (otherwise the game would be too fast to be playable)
	ld	a, [JIFFY]
	and	$03
	jr	nz, .LOOP

; Computes the new position of the head
	call	APPLY_DIRECTION		
	ld	d, h	; (preserves new NAMTBL pointer of the head in de,
	ld	e, l	; because SAVE_SNAKE_HEAD expects it as a parameter)
	
; Checks collisions
	ld	a, [hl] ; Reads the character under the new position of the head
; Is it empty space?
	cp	EMPTY_CHAR
	jr	z, .MOVE_SNAKE ; yes: moves the snake to an empty space
; no: is it a fruit?
	cp	FRUIT_CHAR
	jr	z, .EAT_FRUIT	; yes: moves the snake and eats the fruit
; no: not an empty space nor a fruit,
; so the snake has collided with the walls or with itself
; The game loop ends here
	ret
	
; Moves the snake to an empty space
.MOVE_SNAKE:
	call	INC_SNAKE_HEAD	; Moves the head index
	call	INC_SNAKE_TAIL	; Moves the tail index (the snake does not grow)
	call	SAVE_SNAKE_HEAD	; Preserves the new position of the head
	jr	.LOOP		; Go to next frame

; Moves the snake and eats the fruit
.EAT_FRUIT:
	call	INC_SNAKE_HEAD	; Moves the head index but does not move the tail index, so the snake grows
	call	SAVE_SNAKE_HEAD	; Preserves the new position of the head
	call	NEW_FRUIT	; Prints a new fruit in the game area
	call	INC_SCORE	; Increases the score
	call	UPDATE_HI_SCORE ; Updates the high score
	jr	.LOOP		; Go to next frame
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Handles the input
; param [input.level]: the current status of the input, read by MSXlib
; ret [direction]: the direction the snake is moving to
UPDATE_DIRECTION:
; Reads the current status of the input
	ld	a, [input.level]
	
; For convenience, points hl to direction
	ld	hl, direction
	
; Checks left
	bit	BIT_STICK_LEFT, a
	jr	z, .NOT_LEFT ; no
; yes:
.LEFT:
; Is the current direction "RIGHT"?
	ld	a, [hl]
	cp	3 ; [direction] == 3 ?
	ret	z ; yes: do nothing
; no: saves the "LEFT" direction
	ld	a, 7
	ld	[hl], a
	ret
.NOT_LEFT:
	
; Checks right
	bit	BIT_STICK_RIGHT, a
	jr	z, .NOT_RIGHT ; no
; yes:
.RIGHT:
; Is the current direction "LEFT"?
	ld	a, [hl]
	cp	7 ; [direction] == 7 ?
	ret	z ; yes: do nothing
; no: saves the "RIGHT" direction
	ld	a, 3
	ld	[hl], a
	ret
.NOT_RIGHT:
	
; Checks up
	bit	BIT_STICK_UP, a
	jr	z, .NOT_UP ; no
; yes:
.UP:
; Is the current direction "DOWN"?
	ld	a, [hl]
	cp	5 ; [direction] == 5 ?
	ret	z ; yes: do nothing
; no: saves the "UP" direction
	ld	a, 1
	ld	[hl], a
	ret
.NOT_UP:
	
; Checks down
	bit	BIT_STICK_DOWN, a
	jr	z, .NOT_DOWN ; no
; yes:
.DOWN:
; Is the current direction "UP"?
	ld	a, [hl]
	cp	1 ; [direction] == 1 ?
	ret	z ; yes: do nothing
; no: saves the "DOWN" direction
	ld	a, 5
	ld	[hl], a
	ret
.NOT_DOWN:
	
; No valid input: will keep the existing direction
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Computes the new position of the head
; param [direction]: the direction the snake is moving to
; ret hl: NAMTBL pointer of the new position of the head
APPLY_DIRECTION:

; Uses a jump table to react to the direction
	ld	a, [direction] ; a = 1, 3, 5, 7
	dec	a ; a = 0, 2, 4, 6
	ld	hl, .JUMP_TABLE
	jp	JP_TABLE_2 ; Similar to MSX-BASIC's ON a GOTO ...
	
.JUMP_TABLE:
	dw	.MOVE_UP	; When a = 0
	dw	.MOVE_RIGHT	; When a = 2
	dw	.MOVE_DOWN	; When a = 4
	dw	.MOVE_LEFT	; When a = 6
	
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
	
; param bc: the displacement of the NAMTBL pointer
.DO_MOVE:
; Gets the NAMTBL pointer of the head of the snake
	ld	hl, snake_buffer
	ld	a, [head_index]	; a = 0, 1, 2...
	add	a, a		; a *= 2 = 0, 2, 4...
	call	GET_HL_A_WORD	; hl = snake_buffer[head_index]
	
; Applies the delta (bc) to the current NAMTBL pointer of the head
	add	hl, bc
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the head index one position ahead in the buffer
INC_SNAKE_HEAD:
	ld	hl, head_index
	inc	[hl] ; automatically loops: ..., 254, 255, 0, 1, ...
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the tail index one position ahead in the buffer
INC_SNAKE_TAIL:
	ld	hl, tail_index
	inc	[hl] ; automatically loops: ..., 254, 255, 0, 1, ...
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Preserves the new position of the head
; param de: NAMTBL pointer of the new position of the head
SAVE_SNAKE_HEAD:

; Saves the new NAMTBL pointer of the head
	ld	hl, snake_buffer
	ld	a, [head_index]	; a = 0, 1, 2...
	add	a, a		; a *= 2 = 0, 2, 4...
	call	ADD_HL_A	; hl = snake_buffer[head_index]

; Saves de in snake_buffer[head_index] (i.e.: this code is equivalent to [hl] = de)
	ld	[hl], e
	inc	hl
	ld	[hl], d
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prepares the snake in the NAMTBL buffer
; This routine actually only prints the head of the snake
; and removes the tail of the snake
PRINT_SNAKE:

; Gets the NAMTBL pointer of the head of the snake
	ld	hl, snake_buffer
	ld	a, [head_index] ; a = 0, 1, 2...
	add	a, a		; a *= 2 = 0, 2, 4...
	call	GET_HL_A_WORD	; hl = snake_buffer[head_index]
	
; Prints the head of the snake
	ld	a, SNAKE_CHAR
	ld	[hl], a

; Gets the NAMTBL pointer of the tail of the snake
	ld	hl, snake_buffer
	ld	a, [tail_index]	; a = 0, 1, 2...
	add	a, a		; a *= 2 = 0, 2, 4...
	call	GET_HL_A_WORD	; hl = snake_buffer[tail_index]
	
; Clears the tail of the snake
	ld	a, EMPTY_CHAR
	ld	[hl], a
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints a new fruit in the game area
NEW_FRUIT:

; The game area actually has:
; 24 (screen height) -4 (top) -4 (bottom) = 16 characters height
; So there are 16 * 32 (screen width) = 512 posible positions to place the fruit

; Starts at the first playable character: (0,4)
	ld	hl, namtbl_buffer + 4 *SCR_WIDTH
	
; Looks for a random value in the range 0..512 in bc
; (the randomness of this routine is very poor, but good enough for this example)
	ld	a, r
	and	$01
	ld	b, a ; b = 0..1
	ld	a, r
	ld	c, a ; c = 0..255
	
; Computes the actual NAMTBL buffer pointer
	add	hl, bc
	
; Is it an empty space?
	ld	a, [hl]
	cp	EMPTY_CHAR
	jr	nz, NEW_FRUIT ; no: retry in a different position
	
; Yes: saves the fruit in the NAMTBL buffer
	ld	a, FRUIT_CHAR
	ld	[hl], a
	
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Increases and prints the score
INC_SCORE:

; Reads the lower byte of the score
	ld	hl, score + 1
	ld	a, [hl]
; Increases 1 in BCD
	add	$01
	daa
; Saves the lower byte of the score
	ld	[hl], a
; Checks carry
	jr	nc, .NC ; no carry
; carry: reads the higher byte of the score
	dec	hl ; hl = score
	ld	a, [hl]
; Increases 1 in BCD
	add	$01
	daa
; Saves the higher byte of the score
	ld	[hl], a
.NC:
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
; Prints the BCD score on the NAMTBL buffer
PRINT_SCORE:

; Uses MSXlib convenience routines to print the BCD score on the NAMTBL buffer
; Higher byte
	ld	hl, score ; source BCD data
	ld	de, namtbl_buffer + 7 ; de = destination: (7, 0)
	call	PRINT_BCD ; 1 byte -> 2 characters
; Lower byte
	inc	hl ; hl = score + 1
	call	PRINT_BCD
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
UPDATE_HI_SCORE:

; Checks high score
	ld	hl, [score]
	ld	de, [high_score]
	call	DCOMPR ; compares HL and DE
	ret	c ; carry: high_score is higher than score
; No carry: score is higher than high_score
	ld	a, l
	ld	[high_score], a
	ld	a, h
	ld	[high_score + 1], a
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
; Prints the BCD high_score on the NAMTBL buffer
PRINT_HI_SCORE:

; Higher byte
	ld	hl, high_score ; source BCD data
	ld	de, namtbl_buffer + 25 ; de = destination: (25, 0)
	call	PRINT_BCD ; 1 byte -> 2 characters
; Lower byte
	inc	hl ; hl = high_score + 1
	jp	PRINT_BCD
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
GAME_OVER:

; Prints the "GAME_OVER" text
	ld	hl, .TXT_GAME_OVER
	ld	de, namtbl_buffer + 11 *SCR_WIDTH ; hl = (0, 11)
	jp	PRINT_CENTERED_TEXT

; null-terminated string
.TXT_GAME_OVER:
	db	"GAME OVER!", ASCII_NUL ; NUL (null) = $00
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

; The snake buffer is a circular buffer of pointers to the NAMTBL buffer
snake_buffer:
	rw	256
	.SIZE:	equ $ - snake_buffer

; Index of the snake buffer that contains the position of the snake head
head_index:
	rb	1
	
; Index of the snake buffer that contains the position of the snake tail
tail_index:
	rb	1
	
; Direction the snake is moving
; Uses MSX-BASIC's direction values for convenience (1 = up, 3 = right, ...)
direction:
	rb	1
	
; The score in BCD (e.g.: $0312 = 31200 points)
score:
	rw	1
	
; The high score in BCD
high_score:
	rw	1
; -----------------------------------------------------------------------------

	include	"lib/msx/ram_end.asm"

; EOF
