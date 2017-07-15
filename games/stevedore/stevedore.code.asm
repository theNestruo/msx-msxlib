
;
; =============================================================================
; 	Game code
; =============================================================================
;

; -----------------------------------------------------------------------------
; Number of frames required to actually push an object
	FRAMES_TO_PUSH:		equ 12

; Playground size
	PLAYGROUND_FIRST_ROW:	equ 0
	PLAYGROUND_LAST_ROW:	equ 23
	
; The flags the define the state of the stage
	BIT_STAGE_KEY:		equ 0 ; Key picked up
	BIT_STAGE_STAR:		equ 1 ; Star picked up
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
MAIN_INIT:
; Charset (1/2: CHRTBL)
	ld	hl, CHARSET_PACKED.CHR
	call	UNPACK_LDIRVM_CHRTBL
; Charset (2/2: CLRTBL)
	ld	hl, CHARSET_PACKED.CLR
	call	UNPACK_LDIRVM_CLRTBL
	
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
	
; Initializes the replayer and installs it in the interruption
	call	REPLAYER.RESET
	call	REPLAYER.INSTALL
; ------VVVV----falls through--------------------------------------------------
	
IFEXIST NAMTBL_PACKED_TABLE.TEST_SCREEN
	ld	hl, NAMTBL_PACKED_TABLE.TEST_SCREEN
	ld	de, namtbl_buffer
	call	UNPACK
	call	INIT_STAGE
	call	ENASCR_NO_FADE
	
; Loads song #0
	xor	a
	call	REPLAYER.PLAY

	jp	GAME_LOOP
ENDIF

; -----------------------------------------------------------------------------
; Intro sequence
INTRO:
; Is ESC key pressed?
	halt
	ld	hl, NEWKEY + 7 ; CR SEL BS STOP TAB ESC F5 F4
	bit	2, [hl]
	call	z, MAIN_MENU ; yes: skip intro / tutorial

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

; Loads song #0
	xor	a
	call	REPLAYER.PLAY

; Intro sequence #1: "Push space key"

; Courtesy pause
	call	TRIGGER_PAUSE_FOUR_SECONDS
	jr	nz, .SKIP_WAIT

; Prints "push space key" text
	ld	hl, TXT_PUSH_SPACE_KEY
	ld	de, namtbl_buffer + 16 * SCR_WIDTH + TXT_PUSH_SPACE_KEY.CENTER
	call	PRINT_TXT
	halt
	call	LDIRVM_NAMTBL

; Pauses until trigger
.TRIGGER_LOOP_1:
	halt
	call	READ_INPUT
	and	1 << BIT_TRIGGER_A
	jr	z, .TRIGGER_LOOP_1

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
	ld	de, namtbl_buffer + 16 *SCR_WIDTH + TXT_PUSH_SPACE_KEY.CENTER
	call	PRINT_TXT
; Blit and pause
	call	LDIRVM_NAMTBL
	halt
	halt
	halt
	pop	bc ; restores counter
	djnz	.BLINK_LOOP
; Removes the "push space key" text
	ld	hl, namtbl_buffer + 16 *SCR_WIDTH
	call	CLEAR_LINE
	
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

; Loads first tutorial stage screen into NAMTBL buffer
	ld	hl, NAMTBL_PACKED_TABLE.INTRO_STAGE
	ld	de, namtbl_buffer
	call	UNPACK
; Mimics in-game loop preamble and initialization	
	call	INIT_STAGE
	
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
	jr	GAME_LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Main menu
MAIN_MENU:
; Main menu entry point and initialization
	;	...TBD...
	
; Main menu draw
	; call	CLS_NAMTBL
	;	...TBD...
	
; Fade in
	; call	ENASCR_FADE_IN

; Main menu loop
.LOOP:
	halt
	;	...TBD...
	; jr	.LOOP
	
; Fade out
	; call	DISSCR_FADE_OUT
; ------VVVV----falls through--------------------------------------------------
	
; -----------------------------------------------------------------------------
; New game entry point
NEW_GAME:
; Initializes game vars
	ld	hl, GAME_0
	ld	de, game
	ld	bc, GAME_0.SIZE
	ldir
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; New stage / new life entry point
NEW_STAGE:
; Skip this section in tutorial stages
	; ld	a, [game.current_stage]
	; cp	TUTORIAL_STAGES
	; jr	nc, .NORMAL
	
; Tutorial stage (quick init)

; Loads and initializes the current stage
	call	LOAD_AND_INIT_CURRENT_STAGE
; Fade in
	call	ENASCR_FADE_IN
	jp	GAME_LOOP
	
.NORMAL:
; Prepares the "new stage" screen
	call	CLS_NAMTBL
	
; "STAGE 0"
	ld	hl, TXT_STAGE
	ld	de, namtbl_buffer + 8 * SCR_WIDTH + TXT_STAGE.CENTER
	call	PRINT_TXT
; "stage N"
	dec	de
	ld	a, [game.current_stage]
	add	$31 ;  - TUTORIAL_STAGES ; "1"
	ld	[de], a
	
; "LIVES 0"
	ld	hl, TXT_LIVES
	ld	de, namtbl_buffer + 10 * SCR_WIDTH + TXT_LIVES.CENTER
	push	de
	call	PRINT_TXT
; "lives N"
	pop	de
	ld	a, [game.lives]
	add	$30 ; "0"
	ld	[de], a

; Fade in
	call	ENASCR_FADE_IN
	call	TRIGGER_PAUSE_ONE_SECOND
	
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
	ld	b, 12
	call	SET_BDRCLR ; green: free frame time
ENDIF
	
; Synchronization (halt)
	halt
	
IFDEF CFG_DEBUG_BDRCLR
	ld	b, 5
	call	SET_BDRCLR ; blue: VDP busy
ENDIF

; Blit buffers to VRAM
	call	EXECUTE_VPOKES
	call	LDIRVM_SPRATR
	
IFDEF CFG_DEBUG_BDRCLR
	ld	b, 1 ; black: game logic
	call	SET_BDRCLR
ENDIF

; Prepares next frame (2/2)
	call	RESET_SPRITES

; Read input devices
	call	READ_INPUT

; Game logic (1/2: updates)
	call	UPDATE_SPRITEABLES
	call	UPDATE_DYNAMIC_CHARSET	; (custom)
	call	UPDATE_BOXES_AND_ROCKS	; (custom)
	call	UPDATE_PLAYER
	call	UPDATE_FRAMES_PUSHING	; (custom)
	call	UPDATE_ENEMIES
	call	UPDATE_BULLETS

; Game logic (2/2: interactions)
	call	CHECK_PLAYER_ENEMIES_COLLISIONS
	call	CHECK_PLAYER_BULLETS_COLLISIONS
	
; Additional game logic: crushed (by a pushable)
	call	GET_PLAYER_TILE_FLAGS
	bit	BIT_WORLD_SOLID, a
	call	nz, SET_PLAYER_DYING
	
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
	jr	PLAYER_OVER ; player is dead
	; cp	PLAYER_STATE_DEAD
	; jr	z, PLAYER_OVER ; player is dead

IFDEF CFG_DEBUG_BDRCLR
	ld	b, 6
	call	SET_BDRCLR ; red: this is bad
ENDIF

.THIS_IS_BAD:
	halt
	call	BEEP
	jr	.THIS_IS_BAD
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
.CTRL_STOP_CHECK:
	ld	hl, NEWKEY + 7 ; CR SEL BS STOP TAB ESC F5 F4
	bit	4, [hl]
	ret	nz ; no STOP
	
	dec	hl ; hl = NEWKEY + 6 ; F3 F2 F1 CODE CAP GRAPH CTRL SHIFT
	bit	1, [hl]
	ret	nz ; no CTRL
	
; Has the player already finished?
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	ret	nz ; yes: do nothing

; ; no: It is a tutorial stage?
	; ld	a, [game.current_stage]
	; cp	TUTORIAL_STAGES
	; jr	c, TUTORIAL_OVER ; yes: skip tutorial
	
; no: Is the player already dying?
	ld	a, [player.state]
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_DYING
	ret	z ; yes: do nothing
	
; no: kills the player
	jp	SET_PLAYER_DYING
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due stage over
STAGE_OVER:
; Fade out
	call	DISSCR_FADE_OUT

; Next stage logic
	ld	hl, game.current_stage
	inc	[hl]
	
; Is it a tutorial stage?
	; ld	a, [game.current_stage]
	; cp	TUTORIAL_STAGES
	; jp	c, NEW_STAGE ; yes: next stage directly
	; jp	z, TUTORIAL_OVER ; no: tutorial finished
	
; Stage over screen
	;	...
	
; Go to the next stage
	jp	NEW_STAGE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
TUTORIAL_OVER:
; Fade out and go to main menu
	call	DISSCR_FADE_OUT
	jp	MAIN_MENU
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due death of the player
PLAYER_OVER:
; Fade out
	call	DISSCR_FADE_OUT
	
; ; Is it a tutorial stage?
	; ld	a, [game.current_stage]
	; cp	TUTORIAL_STAGES
	; jp	c, NEW_STAGE ; yes: re-enter current stage, no life lost
	
; ; Life loss logic
	; ld	hl, game.lives
	; xor	a
	; cp	[hl]
	; jr	z, GAME_OVER ; no lives left
	; dec	[hl]

.SKIP:	
; Re-enter current stage
	jp	NEW_STAGE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game over
GAME_OVER:
; Prepares game over screen
	call	CLS_NAMTBL
; "GAME OVER"
	ld	hl, TXT_GAME_OVER
	ld	de, namtbl_buffer + 8 * SCR_WIDTH + TXT_GAME_OVER.CENTER
	call	PRINT_TXT
	
; Fade in
	call	LDIRVM_NAMTBL_FADE_INOUT
	call	TRIGGER_PAUSE_FOUR_SECONDS
	call	DISSCR_FADE_OUT
	
	jp	MAIN_MENU
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Custom game routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Loads and initializes the current stage
LOAD_AND_INIT_CURRENT_STAGE:
; Loads current stage into NAMTBL buffer
	ld	hl, NAMTBL_PACKED_TABLE
	ld	a, [game.current_stage]
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
	jr	z, .NEW_BOX
; Is it a rock?
	cp	ROCK_FIRST_CHAR
	jr	z, .NEW_ROCK
; Is it a skeleton?
	cp	SKELETON_FIRST_CHAR +1
	jr	z, .NEW_SKELETON
; Is it a trap?
	cp	TRAP_LOWER_LEFT_CHAR
	jp	z, .NEW_LEFT_TRAP
	cp	TRAP_LOWER_RIGHT_CHAR
	jr	z, .NEW_RIGHT_TRAP
; Is it '0', '1', '2', ...
	sub	'0'
	jr	z, .SET_START_POINT ; '0'
	dec	a
	jr	z, .NEW_BAT ; '1'
	dec	a
	jr	z, .NEW_SPIDER ; '2'
	dec	a
	jr	z, .NEW_SNAKE ; '3'
	dec	a
	jr	z, .NEW_SAVAGE ; '4'
	ret
	
.SET_START_POINT:
; Initializes player coordinates
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, player.y
	ld	[hl], e
	inc	hl ; hl = player.x
	ld	[hl], d
	ret

.NEW_BOX:
; Initializes a box spriteable
	call	INIT_SPRITEABLE
	ld	[ix + _SPRITEABLE_PATTERN], BOX_SPRITE_PATTERN
	ld	[ix + _SPRITEABLE_COLOR], BOX_SPRITE_COLOR
	ret

.NEW_ROCK:
; Initializes a rock spriteable
	call	INIT_SPRITEABLE
	ld	[ix + _SPRITEABLE_PATTERN], ROCK_SPRITE_PATTERN
	ld	[ix + _SPRITEABLE_COLOR], ROCK_SPRITE_COLOR
	ret
	
.NEW_SKELETON:
; Initializes a new skeleton
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, ENEMY_0.SKELETON
	jp	INIT_ENEMY

.NEW_BAT:
; Initializes a new bat
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, ENEMY_0.BAT
	jp	INIT_ENEMY

.NEW_SPIDER:
; Initializes a new spider
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, ENEMY_0.SPIDER
	jp	INIT_ENEMY

.NEW_OCTOPUS:

.NEW_SNAKE:
; Initializes a new snake
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, ENEMY_0.SNAKE
	jp	INIT_ENEMY

.NEW_SAVAGE:
; Initializes a new savage
	ld	[hl], 0
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, ENEMY_0.SAVAGE
	jp	INIT_ENEMY
	
.NEW_LEFT_TRAP:
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
; (ensures the bullets start outside the tile)
	ld	a, d
	sub	5
	ld	d, a
	ld	hl, ENEMY_0.TRAP_LEFT
	jp	INIT_ENEMY
	
.NEW_RIGHT_TRAP:
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
; (ensures the bullets start outside the tile)
	ld	a, d
	add	4
	ld	d, a
	ld	hl, ENEMY_0.TRAP_RIGHT
	jp	INIT_ENEMY
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
; no: Reads the character under the right part of the spriteable
	inc	hl ; (+1,+0)
	ld	a, [hl]
	call	GET_TILE_FLAGS
; Is it solid?
	bit	BIT_WORLD_SOLID, a
	ret	nz ; yes
	
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
	or	$b8
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
	or	$b0
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
	add	$ac
; Sets the new lower characters
	ld	[ix + _SPRITEABLE_FOREGROUND +2], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +3], a
; Is the upper half of the box in water?
	bit	1, b
	ret	z ; no
; Yes: sets the new upper characters
	ld	[ix + _SPRITEABLE_FOREGROUND], $aa
	ld	[ix + _SPRITEABLE_FOREGROUND +1], $aa +1
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

; -----------------------------------------------------------------------------
; Skeleton: the skeleton is slept until the star is picked up,
; then, it becomes of type walker (follower with pause)
ENEMY_SKELETON.HANDLER:
; Has the star been picked up?
	ld	hl, stage.flags
	bit	BIT_STAGE_STAR, [hl]
	jp	z, RET_NOT_ZERO ; no

; yes: locates the skeleton characters
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	call	COORDS_TO_OFFSET ; hl = NAMTBL offset
	ld	de, namtbl_buffer -SCR_WIDTH -1 ; (-1,-1)
	add	hl, de ; hl = NAMTBL buffer pointer
; Removes the characters in the next frame
	push	ix ; preserves ix
	xor	a
	ld	[hl], a ; left char (NAMTBL buffer only)
	inc	hl
	call	UPDATE_NAMTBL_BUFFER_AND_VPOKE ; right char
	dec	hl
	call	VPOKE_NAMTBL_ADDRESS ; left char (NATMBL)
	pop	ix ; restores ix
; Shows the sprite in the next frame
	call	PUT_ENEMY_SPRITE ; (side effect: a = 0)
; Makes the enemy lethal
	set	BIT_ENEMY_LETHAL, [ix + enemy.flags]
; Makes the enemy a walker (follower with pause)
	ld	hl, ENEMY_TYPE_WALKER.FOLLOWER_WITH_PAUSE
	ld	[ix + enemy.state_h], h
	ld	[ix + enemy.state_l], l
; ret nz (halt)
	dec	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ENEMY_TRAP:

.TRIGGER_RIGHT_HANDLER:
	ld	h, PLAYER_ENEMY_Y_SIZE
	call	CHECK_PLAYER_COLLISION.Y
	jp	nc, RET_NOT_ZERO
; right?
	ld	a, [player.x]
	cp	[ix + enemy.x]
	jp	c, RET_NOT_ZERO
; Sets the next state as the enemy state
	ld	bc, ENEMY_STATE.NEXT
	jp	SET_NEW_STATE_HANDLER.BC_OK
	
.TRIGGER_LEFT_HANDLER:
	ld	h, PLAYER_ENEMY_Y_SIZE
	call	CHECK_PLAYER_COLLISION.Y
	jp	nc, RET_NOT_ZERO
; left?
	ld	a, [player.x]
	cp	[ix + enemy.x]
	jp	nc, RET_NOT_ZERO
; Sets the next state as the enemy state
	ld	bc, ENEMY_STATE.NEXT
	jp	SET_NEW_STATE_HANDLER.BC_OK
	
.SHOOT_RIGHT_HANDLER:
	ld	hl, BULLET_0.ARROW_RIGHT
	call	INIT_BULLET_FROM_ENEMY
; ret z (continue)
	xor	a
	ret

.SHOOT_LEFT_HANDLER:
	ld	hl, BULLET_0.ARROW_LEFT
	call	INIT_BULLET_FROM_ENEMY
; ret z (continue)
	xor	a
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
	dw	.BONUS	; octopus

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

; coins, fruits, octopus
.BONUS:
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wide tile collision (player width)
ON_PLAYER_WIDE_ON:
; Cursor down?
	ld	hl, input.edge
	bit	BIT_STICK_DOWN, [hl]
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
; UX empujando tiles
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
