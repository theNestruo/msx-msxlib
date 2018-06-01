
;
; =============================================================================
; 	Game code
; =============================================================================
;

; -----------------------------------------------------------------------------
; Number of frames required to actually push an object
	FRAMES_TO_PUSH:		equ 12

; Number of stages per chapter
	STAGES_PER_CHAPTER:	equ 5
	
; Tutorial stages
	FIRST_TUTORIAL_STAGE:	equ 25
	LAST_TUTORIAL_STAGE:	equ 31
	
; The flags the define the state of the stage
	BIT_STAGE_KEY:		equ 0 ; Key picked up
	BIT_STAGE_STAR:		equ 1 ; Star picked up

; Debug
	DEBUG_STAGE:		equ 14 -1 ; DEBUG LINE
	
; Demo mode
	; DEMO_MODE:
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
MAIN_INIT:
; Charset
	call	SET_DEFAULT_CHARSET
	
; Sprite pattern table (SPRTBL)
	ld	hl, SPRTBL_PACKED
	ld	de, SPRTBL
	ld	bc, SPRTBL_SIZE
	call	UNPACK_LDIRVM
	
; Initializes global vars
	ld	hl, GLOBALS_0
	ld	de, globals
	ld	bc, GLOBALS_0.SIZE
	ldir

IFEXIST DEBUG_STAGE
; Is ESC key pressed?
	halt
	ld	hl, NEWKEY + 7 ; CR SEL BS STOP TAB ESC F5 F4
	bit	2, [hl]
	jr	z, .DONT_USE_DEBUG_STAGE ; yes: do not go to debug stage
; Loads debug stage
	ld	a, DEBUG_STAGE
	ld	[game.stage], a
	call	LOAD_AND_INIT_CURRENT_STAGE
	call	ENASCR_NO_FADE
; Directly to game loop
	jp	GAME_LOOP
.DONT_USE_DEBUG_STAGE:
ENDIF
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Copyright notice and "skip intro" secret option
COPYRIGHT:
IFEXIST TXT_COPYRIGHT
; Prints copyright notice
	call	CLS_NAMTBL
	call	CLS_SPRATR
	ld	hl, TXT_COPYRIGHT
	ld	de, namtbl_buffer + 16 *SCR_WIDTH
.LOOP:
	push	de ; preserves destination
	call	PRINT_CENTERED_TEXT
	pop	de ; restores destination
	ld	bc, 2 *SCR_WIDTH
	ex	de, hl ; de += bc
	add	hl, bc
	ex	de, hl
	inc	hl
	xor	a
	cp	[hl]
	jr	nz, .LOOP
	
; Fade in, pause, fade out
	call	ENASCR_FADE_IN
	call	WAIT_TRIGGER_FOUR_SECONDS
	call	DISSCR_FADE_OUT
ENDIF ; IFDEF TXT_COPYRIGHT
	
; Is SEL key pressed?
	halt
	ld	hl, NEWKEY + 7 ; CR SEL BS STOP TAB ESC F5 F4
	bit	6, [hl]
	jp	z, MAIN_MENU ; yes: skip intro / tutorial
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Intro sequence
INTRO:
; Loads intro screen into NAMTBL buffer
	ld	hl, INTRO_DATA.NAMTBL_PACKED
	ld	de, namtbl_buffer
	call	UNPACK
; Mimics in-game loop preamble and initialization	
	call	INIT_STAGE
	call	PUT_PLAYER_SPRITE
; Fade in
	call	ENASCR_FADE_IN
	call	LDIRVM_SPRATR

; Intro sequence #1: "Push space key"
	call	WAIT_TRIGGER_FOUR_SECONDS ; (courtesy pause)
	call	z, PUSH_SPACE_KEY_ROUTINE
	
; Intro sequence #2: the fall

.SKIP_WAIT:
; Updates screen 1/2: broken bridge
	ld	hl, INTRO_DATA.BROKEN_BRIDGE_CHARS
	ld	de, namtbl_buffer + 3 *SCR_WIDTH + 15
	ldi	; 3 bytes
	ldi
	ldi
; Updates screen 2/2: floor
	ld	hl, INTRO_DATA.FLOOR_CHARS
	ld	de, namtbl_buffer + 22 *SCR_WIDTH + 12
	ld	bc, 9 ; 9 bytes
	ldir
; Sets the player falling
	call	SET_PLAYER_FALLING
	call	PUT_PLAYER_SPRITE
; Synchronization (halt) and blit buffers to VRAM
	halt
	call	LDIRVM_NAMTBL
	call	LDIRVM_SPRATR

.FALL_LOOP:
; Mimics game logic, synchronization (halt) and blit buffer to VRAM
	call	UPDATE_PLAYER
	call	PUT_PLAYER_SPRITE
	halt
	call	LDIRVM_SPRATR
; Checks exit condition
	ld	a, [player.state]
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_AIR
	jr	z, .FALL_LOOP ; no

; Intro sequence #3: the darkness

; Sets the player crashed (sprite only)
	ld	a, PLAYER_SPRITE_INTRO_PATTERN
	ld	[player_spratr.pattern], a
	add	4
	ld	[player_spratr.pattern +4], a
	call	LDIRVM_SPRATR

; Loads song #0 (warehouse), looped
	xor	a
	call	REPLAYER.PLAY

; Slow fade out
	ld	hl, NAMTBL
	ld	b, 16 ; 16 lines
.LOOP_2:
	push	bc ; preserves counter
	push	hl ; preserves line
; Synchronization (halt)
	halt	; (slowly: 3 frames)
	halt
	halt
	pop	hl ; restores line
; Erases one line in VRAM
	ld	bc, SCR_WIDTH
	push	bc ; preserves SCR_WIDTH
	push	hl ; preserves line (again)
	xor	a
	call	FILVRM
	pop	hl ; restores line (again)
	pop	bc ; restores SCR_WIDTH
; Moves one line down
	add	hl, bc
	pop	bc ; resotres counter
	djnz	.LOOP_2

; Intro sequence #4: the awakening

; Loads first tutorial stage screen
	ld	a, FIRST_TUTORIAL_STAGE
	ld	[game.stage], a
	call	LOAD_AND_INIT_CURRENT_STAGE
	
; Pauses until trigger
.TRIGGER_LOOP_2:
	halt
	call	READ_INPUT
	and	1 << BIT_TRIGGER_A
	jr	z, .TRIGGER_LOOP_2

; Awakens the player, synchronization (halt) and blit buffer to VRAM
	call	PUT_PLAYER_SPRITE
	halt
	call	LDIRVM_SPRATR
; Fade in-out with the playable intro screen and enter the game
	call	LDIRVM_NAMTBL_FADE_INOUT.KEEP_SPRITES
	jp	GAME_LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Main menu entry point and initialization
MAIN_MENU:
; Title charset
	call	SET_TITLE_CHARSET
	
; Draws the main menu
	call	CLS_NAMTBL
	call	CLS_SPRATR
	
; Prints the title
	ld	hl, namtbl_buffer + 1 *SCR_WIDTH + TITLE_CENTER
	ld	a, TITLE_CHAR_FIRST
.TITLE_ROW_LOOP:
	ld	b, TITLE_WIDTH
; Prints a row
.TITLE_CHAR_LOOP:
	ld	[hl], a
	inc	hl
	inc	a
	djnz	.TITLE_CHAR_LOOP
; Moves target pointer
	ld	bc, SCR_WIDTH - TITLE_WIDTH
	add	hl, bc
; Checks if the last character has been reached
	cp	TITLE_CHAR_FIRST + TITLE_HEIGHT * TITLE_WIDTH
	jr	c, .TITLE_ROW_LOOP ; no
	
; Prints "STAGE SELECT"
	ld	hl, TXT_STAGE_SELECT
	ld	de, namtbl_buffer + 6 *SCR_WIDTH
	call	PRINT_CENTERED_TEXT
; "LIGHTHOUSE" and similar texts
	inc	hl ; (points to the first text)
	ld	a, [globals.chapters]
	call	PRINT_SELECTED_CHAPTER_NAME.HL_A_OK
	
; Initializes the selection with the latest chapter
	ld	a, [globals.chapters]
	ld	[menu.selected_chapter], a
; Initializes the menu values from the look-up-table
	ld	hl, STAGE_SELECT.MENU_0_TABLE
	ld	bc, STAGE_SELECT.MENU_0_SIZE
.TABLE_LOOP:
; Is the right table entry?
	dec	a
	jr	z, .HL_OK ; yes
; no: skips to the next table entry
	add	hl, bc
	jr	.TABLE_LOOP
.HL_OK:
	ld	de, menu
	ldir
	
; Prints the blocks depending on globals.chapters
	ld	hl, STAGE_SELECT.NAMTBL
	ld	de, [menu.namtbl_buffer_origin]
	ld	a, [globals.chapters]
	ld	b, a
.PRINT_BLOCK_LOOP:
	push	bc ; preserves counter
	push	de ; preserves coordinates
; Prints the block
	ld	bc, STAGE_SELECT.HEIGHT << 8 + STAGE_SELECT.WIDTH
	call	PRINT_BLOCK
; Advances to the next block
	pop	de ; restores coordinates
	ex	de, hl ; coordinates += (6,0)
	ld	bc, 6
	add	hl, bc
	ex	de, hl
	pop	bc ; restores counter
	djnz	.PRINT_BLOCK_LOOP
; Prints the tutorial option
	ld	hl, STAGE_SELECT.FLOOR_CHARS
	ld	de, namtbl_buffer + 22 *SCR_WIDTH + 13
	ld	bc, 6 ; 6 bytes
	ldir
; Initializes the sprite attribute table (SPRATR) and the player
	ld	hl, SPRATR_0
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir
	ld	hl, PLAYER_0
	ld	de, player
	ld	bc, PLAYER_0.SIZE
	ldir
	call	UPDATE_MENU_PLAYER
; Other initialization
	xor	a
	ld	[stage.framecounter], a
	ld	hl, CHARSET_DYNAMIC.CHR + CHAR_FIRST_SURFACES * 8
	call	SET_DYNAMIC_CHARSET
; Fade in and player appearing
	call	ENASCR_FADE_IN
	call	PLAYER_APPEARING_ANIMATION
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Main menu loop
MAIN_MENU_LOOP:
; Synchronization (halt), read input devices, etc.
	halt
	call	LDIRVM_SPRATR
	call	READ_INPUT
	call	UPDATE_DYNAMIC_CHARSET
; Player animation
	call	UPDATE_PLAYER_ANIMATION
	call	PUT_PLAYER_SPRITE
; If triggered, accepts selection
	ld	a, [input.edge]
	bit	BIT_TRIGGER_A, a
	jr	nz, .OK
; Else, updates selection
	call	MAIN_MENU_INPUT
	jr	MAIN_MENU_LOOP

.OK:
; Player disappearing and fade out
	call	PLAYER_DISAPPEARING_ANIMATION
	call	DISSCR_FADE_OUT

; Restores default charset
	call	RESET_TITLE_CHARSET
; ------VVVV----falls through--------------------------------------------------
	
; -----------------------------------------------------------------------------
; New game entry point
NEW_GAME:
; Initializes game vars
	ld	hl, GAME_0
	ld	de, game
	ld	bc, GAME_0.SIZE
	ldir
; Initializes stage and stage_bcd
	ld	a, [menu.selected_chapter] ; a = 0..5
	add	a ; a = 0,2,..10
	ld	hl, STAGE_SELECT.GAME_0_TABLE
	call	ADD_HL_A
	ldi	; .stage
	ldi	; .stage_bcd
; Loads chapter song, looped
	ld	a, [menu.selected_chapter] ; a = 0..5
	call	REPLAYER.PLAY
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; New stage / new life entry point
NEW_STAGE:
; Skip this section in tutorial stages
	ld	a, [game.stage]
	cp	FIRST_TUTORIAL_STAGE
	jr	c, .NORMAL
	
; Tutorial stage (quick init)

; Loads and initializes the current stage
	call	LOAD_AND_INIT_CURRENT_STAGE
; Fade in
	call	ENASCR_FADE_IN
	jp	GAME_LOOP
	
.NORMAL:
; Prepares the "new stage" screen
	call	CLS_NAMTBL
	
; "STAGE"
	ld	hl, TXT_STAGE
	ld	de, namtbl_buffer + 8 * SCR_WIDTH + TXT_STAGE.CENTER
	call	PRINT_TEXT
; " NN"
	inc	de ; " "
	ld	hl, game.stage_bcd
	call	PRINT_BCD
	
; "N"
	ld	de, namtbl_buffer + 10 * SCR_WIDTH + TXT_LIVES.CENTER
	ld	a, [game.lives]
	add	$30 ; "0"
	ld	[de], a
	inc	de
	inc	de ; " "
; "LIVES LEFT" / "LIFE LEFT"
	cp	$31 ; "1"
	jr	z, .LIFE
	ld	hl, TXT_LIVES
	jr	.HL_OK
.LIFE:
	ld	hl, TXT_LIFE
.HL_OK:
	call	PRINT_TEXT

; Fade in
	call	ENASCR_FADE_IN
	call	WAIT_TRIGGER_ONE_SECOND
	
; Loads and initializes the current stage
	call	LOAD_AND_INIT_CURRENT_STAGE
	
; Fade in-out
	call	LDIRVM_NAMTBL_FADE_INOUT
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop
GAME_LOOP:
; Prepares next frame (1/2)
	call	PUT_PLAYER_SPRITE

IFDEF CFG_DEBUG_BDRCLR
	ld	b, 1
	call	SET_BDRCLR ; black: free frame time
ENDIF
	
; Synchronization (halt)
	halt
	
IFDEF CFG_DEBUG_BDRCLR
	ld	b, 4
	call	SET_BDRCLR ; blue: VDP busy
ENDIF

; Blit buffers to VRAM
	call	EXECUTE_VPOKES
	call	LDIRVM_SPRATR

; Prepares next frame (2/2)
	call	RESET_SPRITES
	call	UPDATE_DYNAMIC_CHARSET	; (custom)
	
IFDEF CFG_DEBUG_BDRCLR
	ld	b, 6 ; red: game logic
	call	SET_BDRCLR
ENDIF
	
; Read input devices
	call	READ_INPUT

; Game logic (1/2: updates)
	call	UPDATE_SPRITEABLES
	call	UPDATE_BOXES_AND_ROCKS	; (custom)
	call	UPDATE_PLAYER
	call	UPDATE_FRAMES_PUSHING	; (custom)
	call	UPDATE_ENEMIES
	call	UPDATE_BULLETS

; Game logic (2/2: interactions)
	call	CHECK_PLAYER_ENEMIES_COLLISIONS
	call	CHECK_PLAYER_BULLETS_COLLISIONS
	
; Extra input
	call	.CTRL_STOP_CHECK
	
; Check exit condition
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	jr	z, GAME_LOOP ; no
; yes: conditionally jump according the exit status
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_FINISH
	jr	z, STAGE_OVER ; stage over
	jp	PLAYER_OVER ; player is dead
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
.CTRL_STOP_CHECK:
; Check CTRL+STOP
	call	BREAKX
	ret	nc ; no CTRL+STOP
	
; Has the player already finished?
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	ret	nz ; yes: do nothing

; no: Is the player already dying?
	ld	a, [player.state]
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_DYING
	ret	z ; yes: do nothing
	
; no: kills the player
	jp	SET_PLAYER_DYING
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due death of the player
PLAYER_OVER:
; Fade out
	call	DISSCR_FADE_OUT

; Is SEL key pressed?
	halt
	ld	hl, NEWKEY + 7 ; CR SEL BS STOP TAB ESC F5 F4
	bit	6, [hl]
	jp	z, MAIN_MENU ; yes: go to main menu
	
; Is it a tutorial stage?
	ld	a, [game.stage]
	cp	FIRST_TUTORIAL_STAGE
	jp	nc, NEW_STAGE ; yes: re-enter current stage, no life lost
	
; Life loss logic
	ld	hl, game.lives
	xor	a
	cp	[hl]
	jr	z, GAME_OVER ; no lives left
	dec	[hl]

; Re-enter current stage
	jp	NEW_STAGE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game over
GAME_OVER:
	
; Stops the replayer
	call	REPLAYER.STOP
	
; Prepares game over screen
	call	CLS_NAMTBL
; "GAME OVER"
	ld	hl, TXT_GAME_OVER
	ld	de, namtbl_buffer + 8 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT
	
; Fade in
	call	LDIRVM_NAMTBL_FADE_INOUT
	call	WAIT_TRIGGER_FOUR_SECONDS
	call	DISSCR_FADE_OUT
	
	jp	MAIN_MENU
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due stage over
STAGE_OVER:
; Prepares the player disappearing animation
	call	SET_PLAYER_FLOOR
	call	PREPARE_MASK.DISAPPEARING
; Player disappearing and fade out
	call	PLAYER_DISAPPEARING_ANIMATION
	call	DISSCR_FADE_OUT

; Next stage logic
	ld	hl, game.stage_bcd
	ld	a, [hl]
	add	1
	daa
	ld	[hl], a
	dec	hl ; game.stage
	inc	[hl]
	
; Is a tutorial stage?
	ld	a, [hl] ; game.stage
	cp	LAST_TUTORIAL_STAGE
	jp	z, TUTORIAL_OVER ; tutorial finished
	cp	FIRST_TUTORIAL_STAGE
	jp	nc, NEW_STAGE ; yes: go to next stage
	
; Is the end of a chapter?
	ld	d, 1 ; (initializes chapter counter)
.LOOP:
	sub	STAGES_PER_CHAPTER
	jr	z, CHAPTER_OVER ; yes: go to "chapter over" screen
	jp	c, NEW_STAGE ; no: go to next stage
	inc	d ; (increases chapter counter)
	jr	.LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Special chapter over for the tutorial stages
TUTORIAL_OVER:
; Initializes the screen
	ld	d, 0 ; (tutorial chapter)
	call	CHAPTER_OVER.INIT
	
; Animation loop
.LOOP:
	halt
	call	LDIRVM_SPRATR
; Moves the player right
	call	MOVE_PLAYER_RIGHT
	call	UPDATE_PLAYER_ANIMATION
	call	PUT_PLAYER_SPRITE
; Has the player reached the right side of the screen?
	ld	a, [player.x]
	cp	256 -8
	jr	nz, .LOOP ; no
	
; yes: Go to main menu
	call	DISSCR_FADE_OUT
	jp	MAIN_MENU
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Chapter over (after a group of stages) "congratulations" screen
; param d: finished chapter index (1..5)
CHAPTER_OVER:
; Is the last chapter?
	ld	a, d
	cp	5
	jp	z, ENDING ; yes: goto ending
; no: Unlocks the next chapter in the main menu
	push	de ; (preserves chapter counter)
IFEXIST DEMO_MODE
ELSE
	inc	a ; 2..5
	ld	[globals.chapters], a
ENDIF
.CHAPTERS_OK:
; Initializes the screen
	call	.INIT
	
; Animation loop
.LEFT_LOOP:
	halt
	call	LDIRVM_SPRATR
; Moves the player right
	call	MOVE_PLAYER_RIGHT
	call	UPDATE_PLAYER_ANIMATION
	call	PUT_PLAYER_SPRITE
; Has the player reached the half of the screen?
	ld	a, [player.x]
	cp	128
	jr	nz, .LEFT_LOOP ; no

IFEXIST DEMO_MODE
	; TODO check fruits, etc.
	
; yes: Sets the player crashed (sprite only)
	ld	a, PLAYER_SPRITE_INTRO_PATTERN
	ld	[player_spratr.pattern], a
	add	4
	ld	[player_spratr.pattern +4], a
	call	LDIRVM_SPRATR

; Dramatic pause	
	call	WAIT_FOUR_SECONDS
	
; "DEMO OVER"
	ld	hl, TXT_DEMO_OVER
	ld	de, namtbl_buffer + 17 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT
	
	halt
	call	LDIRVM_NAMTBL
	call	WAIT_TRIGGER_FOUR_SECONDS
	call	DISSCR_FADE_OUT
	
	jp	MAIN_MENU
	
ELSE ; IFEXIST DEMO_MODE
	; TODO walk right half
	
; Go to next stage
	call	DISSCR_FADE_OUT
; Loads chapter song, looped
	pop	af ; (restores chapter counter in a)
	inc	a
	call	REPLAYER.PLAY
; Go to next stage
	jp	NEW_STAGE
ENDIF ; IFEXIST DEMO_MODE ELSE
	
; Chapter over screen initilization
; param d: chapter index (1..5, 0 meaning "tutorial")
.INIT:
	push	de ; (preserves chapter counter)
	
; Stops the replayer
	call	REPLAYER.STOP
	
; Prepares the "chapter over" screen
	call	CLS_NAMTBL
	call	RESET_SPRITES
	
; "SORRY, STEVEDORE"
	ld	hl, TXT_CHAPTER_OVER
	ld	de, namtbl_buffer + 6 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT

; "BUT THE LIGHTHOUSE KEEPER"
	inc	hl ; (next text)
	ld	de, namtbl_buffer + 8 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT

; Searchs for the correct text
	inc	hl ; (points to the first text)
	pop	de ; (restores chapter counter)
	call	GET_TEXT.USING_D
; "IS IN ANOTHER BUILDING!" and similar texts
	ld	de, namtbl_buffer + 10 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT

; Fade in
	call	ENASCR_FADE_IN

; Initialize sprites
	ld	hl, .PLAYER_0
	ld	de, player
	ld	bc, PLAYER_0.SIZE
	ldir
	jp	PUT_PLAYER_SPRITE
	
; Initial player vars
.PLAYER_0:
	db	128, 8			; .y, .x
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ENDING:
	jr	$
; -----------------------------------------------------------------------------


;
; =============================================================================
;	Custom game routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Sets the default charset in all banks
SET_DEFAULT_CHARSET:
RESET_TITLE_CHARSET:
; Charset (1/2: CHRTBL)
	ld	hl, CHARSET_PACKED.CHR
	call	UNPACK_LDIRVM_CHRTBL
; Charset (2/2: CLRTBL)
	ld	hl, CHARSET_PACKED.CLR
	jp	UNPACK_LDIRVM_CLRTBL
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Overwrites the charset with the title charset at bank #0
SET_TITLE_CHARSET:
; Title charset (1/2: CHRTBL)
	ld	hl, CHARSET_TITLE_PACKED.CHR
	ld	de, CHRTBL + TITLE_CHAR_FIRST *8
	call	.UNPACK_LDIRVM
; Title charset (2/2: CLRTBL)
	ld	hl, CHARSET_TITLE_PACKED.CLR
	ld	de, CLRTBL + TITLE_CHAR_FIRST *8
.UNPACK_LDIRVM:
	ld	bc, CHARSET_TITLE_PACKED.SIZE
	jp	UNPACK_LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Handles selection change in the main menu
MAIN_MENU_INPUT:
; Is the cursor at the tutorial?
	ld	a, [menu.selected_chapter]
	or	a ; (for the jr z)
	ld	a, [input.edge]
	jr	z, .CHECK_UP ; yes: check up only
; Checks stick left or right
	bit	BIT_STICK_LEFT, a
	jr	nz, .LEFT
	bit	BIT_STICK_RIGHT, a
	jr	nz, .RIGHT
; Checks stick down
	bit	BIT_STICK_DOWN, a
	ret	z ; no: no input
; yes: sets the cursor at the tutorial
	xor	a
	jr	.MOVE_TO_A

; Checks stick up only
.CHECK_UP:
	bit	BIT_STICK_UP, a
	ret	z ; no cursor
; yes: sets the cursor at the leftmost position
	ld	a, 1
; Sets the cursor at the position a with out/in animation
.MOVE_TO_A:
	ld	[menu.selected_chapter], a
.MOVE:
; Removes the name of the selected chapter
	ld	hl, namtbl_buffer + 8 *SCR_WIDTH
	call	CLEAR_LINE
	halt
	call	LDIRVM_NAMTBL
; Out animation
	call	PLAYER_DISAPPEARING_ANIMATION
	call	UPDATE_MENU_PLAYER
; In animation
	call	PLAYER_APPEARING_ANIMATION
	call	PRINT_SELECTED_CHAPTER_NAME
	halt
	jp	LDIRVM_NAMTBL

; Moves the selection to the left
.LEFT:
; Checks leftmost position
	ld	a, [menu.selected_chapter]
	dec	a
	jr	nz, .MOVE_TO_A ; no: move cursor
; yes: do nothing
	ret

; Moves the selection to the right
.RIGHT:
; Checks rightmost position
	ld	a, [menu.selected_chapter]
	ld	hl, globals.chapters
	cp	[hl]
	ret	z ; yes: do nothing
; no: move cursor
	inc	a
	jr	.MOVE_TO_A
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the cursor (the player) in the stage select screen
UPDATE_MENU_PLAYER:
; Uses the table to convert index into coordinates
	ld	hl, menu.player_0_table
	ld	a, [menu.selected_chapter] ; a = 0..5
	add	a ; a = 0,2,..10
	call	ADD_HL_A
; Sets the player coordinates
	ld	de, player
	ldi
	ldi
; Updates the player sprite
	call	PUT_PLAYER_SPRITE
; Prepares the mask for appearing animation
	; jp	PREPARE_MASK.APPEARING ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Prepares the SPRATR buffer for the player appearing/disappearing animations
PREPARE_MASK:
.APPEARING:
	ld	b, SPRITE_HEIGHT / 2
	jr	.B_OK
.DISAPPEARING:
	ld	b, SPRITE_HEIGHT
.B_OK:
	ld	a, [player.y]
	add	CFG_SPRITES_Y_OFFSET
	sub	b
	ld	[spratr_buffer], a
	ld	[spratr_buffer +4], a
	add	b
	ld	[spratr_buffer +8], a
	ld	[spratr_buffer +12], a
	add	b
	ld	[spratr_buffer +16], a
	ld	[spratr_buffer +20], a
; Resets the volatile sprites
	ld	hl, volatile_sprites
	ld	[hl], SPAT_END
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints the name of the selected chapter
PRINT_SELECTED_CHAPTER_NAME:
	ld	hl, TXT_STAGE_SELECT._0
	ld	a, [menu.selected_chapter]
.HL_A_OK:
; "LIGHTHOUSE" and similar texts
	call	GET_TEXT
	ld	de, namtbl_buffer + 8 * SCR_WIDTH
	jp	PRINT_CENTERED_TEXT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Animation of player appearing
PLAYER_APPEARING_ANIMATION:
	ld	b, SPRITE_HEIGHT / 2
.LOOP:
	push	bc ; (preserves counter)
	halt
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET
; Player appears
	ld	hl, spratr_buffer
	dec	[hl]
	ld	hl, spratr_buffer +4
	dec	[hl]
	ld	hl, spratr_buffer +16
	inc	[hl]
	ld	hl, spratr_buffer +20
	inc	[hl]
	call	UPDATE_PLAYER_ANIMATION
	call	PUT_PLAYER_SPRITE
; Loop condition
	pop	bc ; (restores counter)
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Animation of player disappearing
PLAYER_DISAPPEARING_ANIMATION:
	ld	b, SPRITE_HEIGHT / 2
.LOOP:
	push	bc ; (preserves counter)
	halt
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET
; Player disappears
	ld	hl, spratr_buffer
	inc	[hl]
	ld	hl, spratr_buffer +4
	inc	[hl]
	ld	hl, spratr_buffer +16
	dec	[hl]
	ld	hl, spratr_buffer +20
	dec	[hl]
	call	UPDATE_PLAYER_ANIMATION
	call	PUT_PLAYER_SPRITE
; Loop condition
	pop	bc ; (restores counter)
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints "push space key" text, waits for trigger, the makes the text blink
PUSH_SPACE_KEY_ROUTINE:
; Prints "push space key" text
	ld	hl, TXT_PUSH_SPACE_KEY
	ld	de, namtbl_buffer + 16 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT
	halt
	call	LDIRVM_NAMTBL

; Pauses until trigger
.TRIGGER_LOOP_1:
	halt
	call	READ_INPUT
	and	1 << BIT_TRIGGER_A
	jr	z, .TRIGGER_LOOP_1

.BLINK:
; Makes "push space key" text blink
	ld	b, 10 ; times to blink
.BLINK_LOOP:
	push	bc ; preserves counter
; Removes the "push space key" text
	ld	hl, namtbl_buffer + 16 *SCR_WIDTH
	call	CLEAR_LINE
; Blit and pause
	call	LDIRVM_NAMTBL
	halt
	halt
	halt
; Prints "push space key" text
	ld	hl, TXT_PUSH_SPACE_KEY
	ld	de, namtbl_buffer + 16 *SCR_WIDTH
	call	PRINT_CENTERED_TEXT
; Blit and pause
	call	LDIRVM_NAMTBL
	halt
	halt
	halt
	pop	bc ; restores counter
	djnz	.BLINK_LOOP
; Removes the "push space key" text
	ld	hl, namtbl_buffer + 16 *SCR_WIDTH
	xor	a ; (because " " is actually a solid tile)
	jp	CLEAR_LINE.USING_A
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Loads and initializes the current stage
LOAD_AND_INIT_CURRENT_STAGE:
; Loads current stage into NAMTBL buffer
	ld	hl, NAMTBL_PACKED_TABLE
	ld	a, [game.stage]
	add	a ; a *= 2
	call	GET_HL_A_WORD
	ld	de, namtbl_buffer
	call	UNPACK
; In-game loop preamble and initialization	
	; jp	INIT_STAGE ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop preamble and initialization:
; Initializes stage vars, player vars and SPRATR,
; sprites, enemies, vpokes, spriteables,
; and post-processes the stage loaded in NATMBL buffer
INIT_STAGE:
; Initializes stage vars
	ld	hl, STAGE_0
	ld	de, stage
	ld	bc, STAGE_0.SIZE
	ldir

; Initializes player vars
	ld	hl, PLAYER_0
	ld	de, player
	ld	bc, PLAYER_0.SIZE
	ldir
	
; Initializes sprite attribute table (SPRATR)
	ld	hl, SPRATR_0
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir
	
; Other initialization
	call	RESET_SPRITES
	call	RESET_ENEMIES
	call	RESET_BULLETS
	call	RESET_VPOKES
	call	RESET_SPRITEABLES
	call	SET_DOORS_CHARSET.CLOSED
	ld	hl, CHARSET_DYNAMIC.CHR + CHAR_FIRST_SURFACES * 8
	call	SET_DYNAMIC_CHARSET
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Post-processes the stage loaded in NATMBL buffer
POST_PROCESS_STAGE_ELEMENTS:
	ld	hl, namtbl_buffer
	ld	bc, NAMTBL_SIZE
.LOOP:
	push	bc ; preserves counter
	push	hl ; preserves pointer
	call	POST_PROCESS_STAGE_ELEMENT
	pop	hl ; restores pointer
	pop	bc ; restores counter
	cpi	; inc hl, dec bc
	jp	pe, .LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Post-processes one char of the loaded stage
; param hl: NAMTBL buffer pointer
POST_PROCESS_STAGE_ELEMENT:
	ld	a, [hl]
	
; Is it a box?
	cp	BOX_FIRST_CHAR
	jr	z, NEW_BOX
; Is it a rock?
	cp	ROCK_FIRST_CHAR
	jr	z, NEW_ROCK
; Is it a skeleton?
	cp	SKELETON_FIRST_CHAR +1
	jr	z, NEW_SKELETON
; Is it a left trap?
	cp	TRAP_LOWER_LEFT_CHAR
	jp	z, NEW_LEFT_TRAP
; Is it a right trap?
	cp	TRAP_LOWER_RIGHT_CHAR
	jp	z, NEW_RIGHT_TRAP
; Is it the start point?
	sub	'0'
	jp	z, SET_START_POINT ; '0'
; Is it an enemy?
	dec	a
	jp	z, NEW_BAT_1 ; '1'
	dec	a
	jp	z, NEW_BAT_2 ; '2'
	dec	a
	jp	z, NEW_SNAKE_1 ; '3'
	dec	a
	jp	z, NEW_SNAKE_2 ; '4'
	dec	a
	jp	z, NEW_SNAKE_3 ; '5'
	dec	a
	jp	z, NEW_PIRATE ; '6'
	dec	a
	jp	z, NEW_SAVAGE ; '7'
	dec	a
	jp	z, NEW_SPIDER ; '8'
	dec	a
	jp	z, NEW_JELLYFISH ; '9'
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a box spriteable
NEW_BOX:
	call	INIT_SPRITEABLE
	ld	[ix + _SPRITEABLE_PATTERN], BOX_SPRITE_PATTERN
	ld	[ix + _SPRITEABLE_COLOR], BOX_SPRITE_COLOR
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a rock spriteable
NEW_ROCK:
	call	INIT_SPRITEABLE
	ld	[ix + _SPRITEABLE_PATTERN], ROCK_SPRITE_PATTERN
	ld	[ix + _SPRITEABLE_COLOR], ROCK_SPRITE_COLOR
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new skeleton
NEW_SKELETON:
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .SKELETON_DATA
	jp	INIT_ENEMY

; Skeleton: the skeleton is slept until the star is picked up,
; then, it becomes of type walker (follower with pause)
.SKELETON_DATA:
	db	SKELETON_SPRITE_PATTERN OR FLAG_ENEMY_PATTERN_LEFT
	db	SKELETON_SPRITE_COLOR
	db	$00 ; (not lethal nor solid in the initial state)
	dw	.SKELETON_BEHAVIOUR_IDLE
	
.SKELETON_BEHAVIOUR_IDLE:
; Slept until the star is picked up
	dw	.WAIT_KEY_HANDLER
	dw	.WAKE_UP_HANDLER
; then becomes of type walker (follower with pause)
	dw	SET_NEW_STATE_HANDLER.AND_SAVE_RESPAWN
	dw	ENEMY_TYPE_PACER.FOLLOWER
; ; Follower (with pauses):
; ; the enemy walks a medium distance along the ground,
; ; towards the player, then pauses, turning around, and continues
; .SKELETON_BEHAVIOUR:
; ; The enemy pauses, turning around
	; dw	PUT_ENEMY_SPRITE
	; dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	; db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	; dw	WAIT_ENEMY_HANDLER.TURNING
	; db	(2 << 6) OR CFG_ENEMY_PAUSE_M ; 3 (even) times, medium pause
; ; then turns towards the player
	; dw	TURN_ENEMY.TOWARDS_PLAYER
	; dw	SET_NEW_STATE_HANDLER.NEXT
; ; walks ahead along the ground
	; dw	PUT_ENEMY_SPRITE_ANIM
	; dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	; db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	; dw	WALKER_ENEMY_HANDLER.RANGED
	; db	CFG_ENEMY_PAUSE_M ; medium distance
; ; and continues
	; dw	SET_NEW_STATE_HANDLER
	; dw	.SKELETON_BEHAVIOUR ; (restart)

.WAIT_KEY_HANDLER:
; Has the key been picked up?
	ld	hl, stage.flags
	bit	BIT_STAGE_KEY, [hl]
	jp	nz, CONTINUE_ENEMY_HANDLER.NO_ARGS
; no: ret halt (0)
	xor	a
	ret

.WAKE_UP_HANDLER:
; Reads the characters from the NAMTBL buffer
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	call	COORDS_TO_OFFSET ; hl = NAMTBL offset
	ld	de, namtbl_buffer -SCR_WIDTH -1 ; (-1,-1)
	add	hl, de ; hl = NAMTBL buffer pointer
; Checks the skeleton characters
	ld	a, SKELETON_FIRST_CHAR ; left char
	cp	[hl]
	jp	nz, END_ENEMY_HANDLER ; no
	inc	a ; right char
	inc	hl
	cp	[hl]
	jp	nz, END_ENEMY_HANDLER ; no
; yes: Removes the characters in the next frame
	push	ix ; preserves ix
	xor	a
	ld	[hl], a ; right char (buffer only)
	dec	hl
	call	UPDATE_NAMTBL_BUFFER_AND_VPOKE ; left char (buffer and VRAM)
	inc	hl
	call	VPOKE_NAMTBL_ADDRESS ; right char (VRAM only)
	pop	ix ; restores ix
; Wakes up the enemy
	set	BIT_ENEMY_LETHAL, [ix + enemy.flags]
	set	BIT_ENEMY_SOLID, [ix + enemy.flags]
; Shows the sprite and ret 2 (continue with next state handler)
	jp	PUT_ENEMY_SPRITE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new left trap
NEW_LEFT_TRAP:
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
; (ensures the bullets start outside the tile)
	ld	a, d
	sub	5
	ld	d, a
	ld	hl, .LEFT_TRAP_DATA
	jp	INIT_ENEMY
	
; Trap (pointing left): shoots when the player is in front of it
.LEFT_TRAP_DATA:
	db	ARROW_LEFT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	$00 ; (not lethal)
	dw	.LEFT_TRAP_BEHAVIOUR
	
.LEFT_TRAP_BEHAVIOUR:
; Is the player in overlapping y coordinates...
	dw	TRIGGER_ENEMY_HANDLER
	dw	WAIT_ENEMY_HANDLER.Y_COLLISION
	db	PLAYER_BULLET_Y_SIZE
; ... and to the left?
	dw	WAIT_ENEMY_HANDLER.PLAYER_LEFT
; Shoot left
	dw	TRIGGER_ENEMY_HANDLER.RESET
	db	CFG_ENEMY_PAUSE_M ; medium pause until next shoot
	dw	.SHOOT_LEFT_HANDLER

; Enemy handler that shoots a bullet to the left
.SHOOT_LEFT_HANDLER:
	ld	hl, .ARROW_LEFT_DATA
	call	INIT_BULLET_FROM_ENEMY
; ret 0 (halt)
	xor	a
	ret
	
.ARROW_LEFT_DATA:
	db	ARROW_LEFT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	BULLET_DIR_LEFT OR 4 ; (4 pixels / frame)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new right trap
NEW_RIGHT_TRAP:
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
; (ensures the bullets start outside the tile)
	ld	a, d
	add	4
	ld	d, a
	ld	hl, .RIGHT_TRAP_DATA
	jp	INIT_ENEMY

; Trap (pointing right): shoots when the player is in front of it
.RIGHT_TRAP_DATA:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	$00 ; (not lethal)
	dw	.RIGHT_TRAP_BEHAVIOUR
	
.RIGHT_TRAP_BEHAVIOUR:
; Is the player in overlapping y coordinates...
	dw	TRIGGER_ENEMY_HANDLER
	dw	WAIT_ENEMY_HANDLER.Y_COLLISION
	db	PLAYER_BULLET_Y_SIZE
; ... and to the right?
	dw	WAIT_ENEMY_HANDLER.PLAYER_RIGHT
; Shoot right
	dw	TRIGGER_ENEMY_HANDLER.RESET
	db	CFG_ENEMY_PAUSE_M ; medium pause until next shoot
	dw	.SHOOT_RIGHT_HANDLER

; Enemy handler that shoots a bullet to the right
.SHOOT_RIGHT_HANDLER:
	ld	hl, .ARROW_RIGHT_DATA
	call	INIT_BULLET_FROM_ENEMY
; ret 0 (halt)
	xor	a
	ret
	
.ARROW_RIGHT_DATA:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	BULLET_DIR_RIGHT OR 4 ; (4 pixels / frame)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes player coordinates
SET_START_POINT:
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, player.y
	ld	[hl], e
	inc	hl ; hl = player.x
	ld	[hl], d
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new bat (1)
NEW_BAT_1:
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .BAT_1_DATA
	jp	INIT_ENEMY
	
; The bat (1) flies, then turns around and continues
.BAT_1_DATA:
	db	BAT_SPRITE_PATTERN
	db	BAT_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID
	dw	ENEMY_TYPE_FLYER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new bat
NEW_BAT_2:
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .BAT_2_DATA
	jp	INIT_ENEMY
	
; Bat: the bat flies, the turns around and continues
.BAT_2_DATA:
	db	BAT_SPRITE_PATTERN
	db	BAT_SPRITE_COLOR_2
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID
	dw	.BAT_2_BEHAVIOUR
	
.BAT_2_BEHAVIOUR:
; The enemy flies
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FLYER_ENEMY_HANDLER
; Is the player in overlapping x coordinates...
	dw	WAIT_ENEMY_HANDLER.X_COLLISION
	db	PLAYER_ENEMY_X_SIZE + 6 ; 3 pixels before the actual collision
; ...and below?
	dw	WAIT_ENEMY_HANDLER.PLAYER_BELOW
	dw	SET_NEW_STATE_HANDLER.NEXT
; then the enemy flies, falling onto the ground
	dw	PUT_ENEMY_SPRITE
	dw	FLYER_ENEMY_HANDLER
	dw	FALLER_ENEMY_HANDLER
	db	(1 << BIT_WORLD_SOLID)
	dw	SET_NEW_STATE_HANDLER.NEXT
; then flies, rising back up
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FLYER_ENEMY_HANDLER
	dw	RISER_ENEMY_HANDLER
	db	(1 << BIT_WORLD_SOLID)
	dw	SET_NEW_STATE_HANDLER
	dw	.BAT_2_BEHAVIOUR ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new snake (1)
NEW_SNAKE_1:
NEW_SNAKE_2:
NEW_SNAKE_3:
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .SNAKE_DATA
	jp	INIT_ENEMY

; Snake (1): the snake walks, the pauses, turning around, and continues
.SNAKE_DATA:
	db	SNAKE_SPRITE_PATTERN
	db	SNAKE_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID
	dw	ENEMY_TYPE_PACER.PAUSED
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new pirate
NEW_PIRATE:
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .PIRATE_DATA
	jp	INIT_ENEMY

; Pirate: TODO
.PIRATE_DATA:
	db	PIRATE_SPRITE_PATTERN
	db	PIRATE_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID
	dw	ENEMY_TYPE_PACER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new savage
NEW_SAVAGE:
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .SAVAGE_DATA
	jp	INIT_ENEMY
	
; Savage: the savage walks towards the player, pausing briefly
.SAVAGE_DATA:
	db	SAVAGE_SPRITE_PATTERN
	db	SAVAGE_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID
	dw	ENEMY_TYPE_PACER.FOLLOWER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new spider
NEW_SPIDER:
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .SPIDER_DATA
	jp	INIT_ENEMY

; Spider: the spider falls onto the ground the the player is near
.SPIDER_DATA:
	db	SPIDER_SPRITE_PATTERN
	db	SPIDER_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID
	dw	ENEMY_TYPE_FALLER.TRIGGERED
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new jellyfish
NEW_JELLYFISH:
	ld	[hl], $f3 ; (water)
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .JELLYFISH_DATA
	jp	INIT_ENEMY

; Jellyfish: the jellyfish floats in a sine wave pattern, shooting up
.JELLYFISH_DATA:
	db	JELLYFISH_SPRITE_PATTERN
	db	JELLYFISH_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID
	dw	.JELLYFISH_BEHAVIOUR
	
.JELLYFISH_BEHAVIOUR:
; The enemy floats in a sine wave pattern
	dw	.WAVER_HANDLER ; PUT_ENEMY_SPRITE + WAVER_ENEMY_HANDLER
	dw	FLYER_ENEMY_HANDLER
; Is the player in overlapping x coordinates?
	dw	TRIGGER_ENEMY_HANDLER
	dw	WAIT_ENEMY_HANDLER.X_COLLISION
	db	PLAYER_BULLET_X_SIZE
; Shoot
	dw	TRIGGER_ENEMY_HANDLER.RESET
	db	CFG_ENEMY_PAUSE_M ; medium pause until next shoot
	dw	.SHOOT_UP_HANDLER

; JELLYFISH: the JELLYFISH floats in a sine wave pattern
.WAVER_HANDLER:
; Is the wave pattern ascending?
	inc	[ix + enemy.frame_counter]
	ld	a, [ix + enemy.frame_counter]
	bit	5, a
	jr	z, .ASCENDING ; yes
; no: descending
	ld	c, JELLYFISH_SPRITE_PATTERN
	jr	.PATTERN_OK
.ASCENDING:
	ld	c, JELLYFISH_SPRITE_PATTERN OR FLAG_ENEMY_PATTERN_ANIM
.PATTERN_OK:
; Puts the sprite
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	ld	b, [ix + enemy.color]
	call	PUT_SPRITE
; Reads and applies the dy
	call	READ_WAVER_ENEMY_DY_VALUE
	add	[ix + enemy.y]
	ld	[ix + enemy.y], a
; ret 2 (continue with next state handler)
	ld	a, 2
	ret

; JELLYFISH: the JELLYFISH shoots oil up
.SHOOT_UP_HANDLER:
	ld	hl, .SPARK_UP_DATA
	call	INIT_BULLET_FROM_ENEMY
; ret 0 (halt)
	xor	a
	ret
	
.SPARK_UP_DATA:
	db	SPARK_SPRITE_PATTERN
	db	SPARK_SPRITE_COLOR
	db	BULLET_DIR_UP OR 4 ; (4 pixels / frame)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sets the doors charset to either the closed or the open doors
SET_DOORS_CHARSET:

.CLOSED:
; Chooses the closed doors from the dynamic charset
	ld	hl, CHARSET_DYNAMIC.CHR + CHAR_FIRST_CLOSED_DOOR * 8
	jr	.HL_OK

.OPEN:
; Chooses the open doors from the dynamic charset
	ld	hl, CHARSET_DYNAMIC.CHR + CHAR_FIRST_OPEN_DOOR * 8
	; jr	.HL_OK ; falls through
	
.HL_OK:
; (1/2: CHRTBL)
	ld	de, CHRTBL + CHAR_FIRST_DOOR * 8
	call	UPDATE_CXRTBL
; (2/2: CLRTBL)
	ld	bc, CHARSET_DYNAMIC.SIZE
	add	hl, bc
	ld	de, CLRTBL + CHAR_FIRST_DOOR * 8
	jr	UPDATE_CXRTBL
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Updates the water and lava surfaces
UPDATE_DYNAMIC_CHARSET:
; Updates the framecounter
	ld	a, $40 / 8 ; each 8 frames
	ld	hl, stage.framecounter
	add	a, [hl]
	ld	[hl], a
	ld	b, a ; preserves framecounter
; Should the charset be updated in this frame?
	and	$3f
	ret	nz ; no
; yes: locates proper source
	ld	hl, CHARSET_DYNAMIC.CHR + CHAR_FIRST_SURFACES * 8
	ld	a, b ; restores framecounter
	; and	$c0 ; unnecessary (due ret nz)
	call	ADD_HL_A
; ------VVVV----falls through--------------------------------------------------
	
; -----------------------------------------------------------------------------
; Initializes the water and lava surfaces
; param hl: source address (i.e.: CHARSET_DYNAMIC.CHR + CHAR_FIRST_SURFACES * 8)
SET_DYNAMIC_CHARSET:
; (1/2: CHRTBL)
	ld	de, CHRTBL + CHAR_WATER_SURFACE * 8
	call	UPDATE_CXRTBL
; (2/2: CLRTBL)
	ld	bc, CHARSET_DYNAMIC.SIZE
	add	hl, bc
	ld	de, CLRTBL + CHAR_WATER_SURFACE * 8
	jr	UPDATE_CXRTBL
; ------VVVV----falls through--------------------------------------------------
	
; -----------------------------------------------------------------------------
; Updates a row of chars from the dynamic charset (ie.: 8 characters)
; param hl: source address inside the dynamic charset
; param de: destination in VRAM
UPDATE_CXRTBL:
; Replaces 64 bytes in three banks
	call	.ONE_BANK
	call	.ONE_BANK
	; jr	.ONE_BANK ; falls through

; Replaces 64 bytes in one bank
.ONE_BANK:
	push	de ; preserves destination
	push	hl ; preserves source
	ld	bc, CHARSET_DYNAMIC.ROW_SIZE
	call	LDIRVM
	pop	de ; restores source in de
	pop	hl ; restores destination in hl
	ld	bc, CHRTBL_SIZE
	add	hl, bc ; moves destination to next bank
	ex	de, hl ; source and destination in proper registers
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Automatic update of the spriteables/pushables movement
; (i.e.: start falling, stop at water, etc.)
UPDATE_BOXES_AND_ROCKS:
; For each spriteable/pushable in the array
	ld	a, [spriteables.count]
	or	a
	ret	z ; no pushables
	ld	b, a ; b = spriteables.count
	ld	ix, spriteables.array
.LOOP:
	push	bc ; preserves counter
; Is the spriteable already moving?
	ld	a, [ix +_SPRITEABLE_STATUS]
	or	a
	call	z, .CHECK_FALLING ; no; checks if it is going to fall
; Skips to the next element of the array
	ld	bc, SPRITEABLE_SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.LOOP
	ret

.CHECK_FALLING:
; Reads the character under the left part of the spriteable
	ld	hl, namtbl_buffer +SCR_WIDTH *2 ; (+2,+0)
	ld	e, [ix +_SPRITEABLE_OFFSET_L]
	ld	d, [ix +_SPRITEABLE_OFFSET_H]
	add	hl, de
	push	hl ; preserves buffer namtbl pointer
	ld	a, [hl]
	call	GET_TILE_FLAGS
	pop	hl ; restores buffer namtbl pointer
; Is it solid?
	bit	BIT_WORLD_SOLID, a
	ret	nz ; yes
	cp	1 << BIT_WORLD_FLOOR OR 1 << BIT_WORLD_STAIRS ; (top of stairs)
	ret	z ; yes (top of stairs considered solid)

; no: Reads the character under the right part of the spriteable
	inc	hl ; (+1,+0)
	ld	a, [hl]
	call	GET_TILE_FLAGS
; Is it solid?
	bit	BIT_WORLD_SOLID, a
	ret	nz ; yes
	cp	1 << BIT_WORLD_FLOOR OR 1 << BIT_WORLD_STAIRS ; (top of stairs)
	ret	z ; yes (top of stairs considered solid)
	
; Starts moving the spriteable down
	call	MOVE_SPRITEABLE_DOWN
	
; Is the lower half of the spriteable in water or lava?
	ld	a, [ix +_SPRITEABLE_BACKGROUND +2] ; (+0,+1)
	ld	b, a ; preserves value in b
	and	$f8 ; (discards lower bits)
	cp	CHAR_WATER_SURFACE
	ret	nz ; no
	
; Yes: is the spriteable a box?
	ld	a, [ix +_SPRITEABLE_PATTERN]
	cp	BOX_SPRITE_PATTERN
	jr	z, .BOX ; yes
; no: it is a rock

.ROCK:
; Calculate new lower characters
	ld	a, b ; restores background value
	and	$06 ; (discards lower bit)
	or	$a8
; Sets the new lower characters
	ld	[ix + _SPRITEABLE_FOREGROUND +2], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +3], a
; Is the upper half of the rock in water or lava?
	ld	a, [ix +_SPRITEABLE_BACKGROUND]
	ld	b, a ; preserves value in b
	and	$f8 ; (discards lower bits)
	cp	CHAR_WATER_SURFACE
	ret	nz ; no
; Yes: calculate new upper characters
	ld	a, b ; restores background value
	and	$06 ; (discards lower bit)
	or	$a0
; Sets the new upper character
	ld	[ix + _SPRITEABLE_FOREGROUND], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +1], a
; Is the upper half of the rock in deep water or lava?
	bit	1, b
	ret	z ; no
; yes: change the sprite color
	bit	2, b
	ld	a, ROCK_SPRITE_COLOR_WATER
	jr	z, .A_OK
	ld	a, ROCK_SPRITE_COLOR_LAVA
.A_OK:
	ld	[ix + _SPRITEABLE_COLOR], a
	ret
	
.BOX:
; Checks if it is water or lava
	ld	a, b ; restores background value
	bit	2, b
	jr	nz, .BOX_IN_LAVA ; lava

; Water: calculate new lower characters
	and	$06 ; (discards lower bit)
	add	$9c
; Sets the new lower characters
	ld	[ix + _SPRITEABLE_FOREGROUND +2], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +3], a
; Is the upper half of the box in water?
	bit	1, b
	ret	z ; no
; Yes: sets the new upper characters
	ld	[ix + _SPRITEABLE_FOREGROUND], $9a
	ld	[ix + _SPRITEABLE_FOREGROUND +1], $9a +1
; Stops the spriteable (after this movement)
	set	7, [ix + _SPRITEABLE_STATUS]
	ret
	
.BOX_IN_LAVA:
; Recovers the background immediately
	call	NAMTBL_BUFFER_SPRITEABLE_BACKGROUND
; Prevents printing the foreground again after this movement
	ld	a, [ix + _SPRITEABLE_BACKGROUND]
	ld	[ix + _SPRITEABLE_FOREGROUND], a
	ld	a, [ix + _SPRITEABLE_BACKGROUND +1]
	ld	[ix + _SPRITEABLE_FOREGROUND +1], a
	ld	a, [ix + _SPRITEABLE_BACKGROUND +2]
	ld	[ix + _SPRITEABLE_FOREGROUND +2], a
	ld	a, [ix + _SPRITEABLE_BACKGROUND +3]
	ld	[ix + _SPRITEABLE_FOREGROUND +3], a
; Changes the sprite color
	ld	[ix + _SPRITEABLE_COLOR], ROCK_SPRITE_COLOR_LAVA
; Stops the spriteable (after this movement)
	set	7, [ix + _SPRITEABLE_STATUS]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Resetea el contador de frames que lleva empujando el jugador
; si no está empujando
UPDATE_FRAMES_PUSHING:
; ¿Está empujando?
	ld	a, [player.state]
	and	$ff - FLAGS_STATE
	cp	PLAYER_STATE_PUSH
	ret	z ; sí
 ; no: resetea el contador
	xor	a
	ld	[player.pushing], a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	MSXlib user extensions (UX)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Tile collision (single char): Items
ON_PLAYER_WALK_ON:
; Reads the tile index and NAMTBL offset and buffer pointer
	call	GET_PLAYER_TILE_VALUE
	push	hl ; preserves NAMTBL buffer pointer
; Executes item action
	sub	CHAR_FIRST_ITEM
	ld	hl, .ITEM_JUMP_TABLE
	call	JP_TABLE
; Removes the item in the NAMTBL buffer and VRAM
	xor	a
	pop	hl ; restores NAMTBL buffer pointer
	jp	UPDATE_NAMTBL_BUFFER_AND_VPOKE

.ITEM_JUMP_TABLE:
	dw	.KEY	; key
	dw	.STAR	; star
	dw	.BONUS	; coin
	dw	.BONUS	; fruit: cherry
	dw	.BONUS	; fruit: strawberry
	dw	.BONUS	; fruit: apple
	dw	.BONUS	; JELLYFISH

; key
.KEY:
	ld	hl, stage.flags
	set	BIT_STAGE_KEY, [hl]
	jp	SET_DOORS_CHARSET.OPEN

; star
.STAR:
	ld	hl, stage.flags
	set	BIT_STAGE_STAR, [hl]
	ret

; coins, fruits, JELLYFISH
.BONUS:
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wide tile collision (player width): Doors
ON_PLAYER_WIDE_ON:
; Cursor up or down?
	ld	a, [input.edge]
	and	(1 << BIT_STICK_UP) OR (1 << BIT_STICK_DOWN)
	ret	z ; no
; Key picked up?
	ld	hl, stage.flags
	bit	BIT_STAGE_KEY, [hl]
	ret	z ; no
; yes: set "stage finish" state
	ld	a, PLAYER_STATE_FINISH
	jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walking over tiles (player width): Fragile floor
ON_PLAYER_WALK_OVER:
; Reads the tile index and NAMTBL offset and buffer pointer
	ld	de, [player.xy]
	call	GET_TILE_VALUE
	push	hl ; preserves NAMTBL buffer pointer
	push	af ; preserves actual character
; Checks if the tile is fragile
; (avoids touching the wrong character because of player width)
	call	GET_TILE_FLAGS
	bit	BIT_WORLD_WALK_OVER, a
	pop	bc ; restores actual character in b
	pop	hl ; restores NAMTBL buffer pointer
	ret	z ; no
; yes: Is the most fragile character?
	ld	a, b
	cp	CHAR_FIRST_FRAGILE
	jr	z, .REMOVE ; yes
; no: Increases the fragility of the character in the NAMTBL buffer and VRAM
	dec	a
	jp	UPDATE_NAMTBL_BUFFER_AND_VPOKE
.REMOVE:
; Removes the fragile character in the NAMTBL buffer and VRAM
	xor	a
	jp	UPDATE_NAMTBL_BUFFER_AND_VPOKE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pushable tiles (player height)
ON_PLAYER_PUSH:

.RIGHT:
; lee el tile bajo que se está empujando
	ld	a, PLAYER_BOX_X_OFFSET +CFG_PLAYER_WIDTH ; x += offset + width
	call	.GET_PUSHED_TILE
; ¿es la parte baja izquierda?
	and	3 ; (porque están alienados a $?0 y $?4)
	cp	2
	ret	nz ; no
; sí: cambia el estado
	ld	a, PLAYER_STATE_PUSH
	ld	[player.state], a
; ¿hay hueco para empujar?
	ld	a, PLAYER_BOX_X_OFFSET +CFG_PLAYER_WIDTH +16
	call	GET_PLAYER_V_TILE_FLAGS
	bit	BIT_WORLD_SOLID, a
	ret	nz ; no
; sí: ¿ha empujado suficiente?
	call	.CHECK_FRAMES_PUSHING
	ret	nz ; no
; sí: localiza el elemento empujable e inicia su movimiento
	ld	a, PLAYER_BOX_X_OFFSET +CFG_PLAYER_WIDTH +8
	call	.LOCATE_PUSHABLE
	jp	MOVE_SPRITEABLE_RIGHT
	
.LEFT:
; lee el tile bajo que se está empujando
	ld	a, PLAYER_BOX_X_OFFSET -1 ; x += offset -1
	call	.GET_PUSHED_TILE
; ¿es la parte baja derecha?
	and	3 ; (porque están alienados a $?0 y $?4)
	cp	3
	ret	nz ; no
; sí: cambia el estado
	ld	a, PLAYER_STATE_PUSH OR FLAG_STATE_LEFT
	ld	[player.state], a
; ¿hay hueco para empujar?
	ld	a, PLAYER_BOX_X_OFFSET -1 -16
	call	GET_PLAYER_V_TILE_FLAGS
	bit	BIT_WORLD_SOLID, a
	ret	nz ; no
; sí: ¿ha empujado suficiente?
	call	.CHECK_FRAMES_PUSHING
	ret	nz ; no
; sí: localiza el elemento empujable e inicia su movimiento
	ld	a, PLAYER_BOX_X_OFFSET -8
	call	.LOCATE_PUSHABLE
	jp	MOVE_SPRITEABLE_LEFT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee el tile (parte baja) que se está empujando
; param a: dx
.GET_PUSHED_TILE:
	ld	de, [player.xy]
	add	d ; x += dx
	ld	d, a
	dec	e ; y -= 1
	jp	GET_TILE_VALUE
	
; Actualiza y comprueba el contador de frames que lleva empujando el jugador
; ret nz: insuficientes
; ret z: suficientes
.CHECK_FRAMES_PUSHING:
	ld	hl, player.pushing
	inc	[hl]
	ld	a, [hl]
	cp	FRAMES_TO_PUSH
	ret
	
; Localiza el elemento que se está empujando y lo activa
; param a: dx
; return ix: puntero al tile convertible
.LOCATE_PUSHABLE:
; Calcula las coordenadas que tiene que buscar
	ld	de, [player.xy]
	add	d ; x += dx
	ld	d, a
	jp	GET_SPRITEABLE_COORDS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ON_PLAYER_ENEMY_COLLISION:
	bit	BIT_ENEMY_LETHAL, [ix + enemy.flags]
	jp	nz, SET_PLAYER_DYING
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ON_PLAYER_BULLET_COLLISION:	equ SET_PLAYER_DYING
; -----------------------------------------------------------------------------

; EOF
