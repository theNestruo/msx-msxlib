
;
; =============================================================================
;	MSXlib core configuration, routines and initialization
; =============================================================================
;

; -----------------------------------------------------------------------------
; Define to visually debug frame timing
	CFG_DEBUG_BDRCLR:
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; MSX cartridge (ROM) header, entry point and initialization

; Define if the ROM is larger than 16kB (typically, 32kB)
; Includes search for page 2 slot/subslot at start
	; CFG_INIT_32KB_ROM:

; Define if the game needs 16kB instead of 8kB
; RAM will start at the beginning of the page 2 instead of $e000
; and availability will be checked at start
	; CFG_INIT_16KB_RAM:
	
; MSX symbolic constants
	include	"lib/msx/symbols.asm"
; MSX cartridge (ROM) header, entry point and initialization
	include "lib/msx/cartridge.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Generic Z80 assembly convenience routines
	include "lib/asm.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacker routine

; Unpack to RAM routine (optional)
; param hl: packed data source address
; param de: destination buffer address

; Pletter (v0.5c1, XL2S Entertainment)
	; include	"libext/pletter05c/pletter05c-unpackRam.tniasm.asm"

; ZX7 decoder by Einar Saukas, Antonio Villena & Metalbrain
; "Standard" version (69 bytes only)
	UNPACK: equ dzx7_standard
	include	"libext/zx7/dzx7_standard.tniasm.asm"

; Buffer size to check it actually fits before system variables
	CFG_RAM_RESERVE_BUFFER:	equ 2048
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Input, timing & pause routines (BIOS-based)
	include "lib/msx/input.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VRAM routines (BIOS-based)
; NAMBTL and SPRATR buffer routines (BIOS-based)
; NAMTBL buffer text routines
; Logical coordinates sprite routines
	
; Logical-to-physical sprite coordinates offsets (pixels)
	CFG_SPRITES_X_OFFSET:	equ -8
	CFG_SPRITES_Y_OFFSET:	equ -17
	
; Number of sprites reserved at the beginning of the SPRATR buffer
; (i.e.: first sprite number for the "volatile" sprites)
	CFG_SPRITES_RESERVED:	equ 2
	
; VRAM routines (BIOS-based)
; NAMBTL and SPRATR buffer routines (BIOS-based)
; NAMTBL buffer text routines
; Logical coordinates sprite routines
	include "lib/msx/vram.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; "vpoke" routines (deferred WRTVRMs routines)
; Spriteables routines (2x2 chars that eventually become a sprite)

; Define to enable the "vpoke" routines (deferred WRTVRMs)
; Maximum number of "vpokes" per frame
	CFG_VPOKES: 		equ 64

; Define to enable the spriteable routines
; Maximum number of simultaneous spriteables
	CFG_SPRITEABLES:	equ 16

; "vpoke" routines (deferred WRTVRMs routines)
; Spriteables routines (2x2 chars that eventually become a sprite)
	include "lib/msx/vram_x.asm"
; -----------------------------------------------------------------------------


;
; =============================================================================
;	MSXlib game-related configuration and routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Sprite-tile helper routines

; Tile indexes (values) to be returned by GET_TILE_VALUE
; when the coordinates are over and under visible screen
	CFG_TILES_VALUE_OVER:	equ $ff ; BIT_WORLD_FLOOR | BIT_WORLD_SOLID
	CFG_TILES_VALUE_UNDER:	equ $1f ; BIT_WORLD_DEATH

; Table of tile flags in pairs (up to index, tile flags)
TILE_FLAGS_TABLE:
	db	$00, $00 ; [     $00] : 0
	db	$07, $10 ; [$01..$07] : BIT_WORLD_WALK_ON (items)
	db	$0f, $20 ; [$01..$0f] : BIT_WORLD_WIDE_ON (open doors)
	db	$17, $83 ; [$10..$17] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID | BIT_WORLD_PUSH
	db	$1f, $08 ; [$18..$1f] : BIT_WORLD_DEATH
	db	$ab, $00 ; [$20..$ab] : 0 (chars and backgrounds)
	db	$af, $04 ; [$ac..$af] : BIT_WORLD_STAIRS
	db	$b7, $02 ; [$b0..$b7] : BIT_WORLD_FLOOR
	db	$bf, $06 ; [$b8..$bf] : BIT_WORLD_FLOOR | BIT_WORLD_STAIRS
	db	$ff, $03 ; [$c0..$ff] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID

; Sprite-tile helper routines
	include	"lib/game/tiles.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Player related routines (generic)
; Player-tile helper routines

; Logical sprite sizes (bounding box size) (pixels)
	CFG_PLAYER_WIDTH:		equ 8
	CFG_PLAYER_HEIGHT:		equ 16

; Number of player sprites (i.e.: number of colors)
	CFG_PLAYER_SPRITES:		equ 2

; Player animation delay (frames)
	CFG_PLAYER_ANIMATION_DELAY:	equ 6

; Custom player states (starting from 4 << 2)
	PLAYER_STATE_PUSH:	equ (4 << 2) ; $10
	;	...

; Maps player states to sprite patterns
PLAYER_SPRATR_TABLE:
	;	0	ANIM	LEFT	LEFT|ANIM
	db	$00,	$08,	$10,	$18	; PLAYER_STATE_FLOOR
	db	$20,	$28,	$20,	$28	; PLAYER_STATE_STAIRS
	db	$08,	$08,	$18,	$18	; PLAYER_STATE_AIR
	db	$30,	$38,	$30,	$38	; PLAYER_STATE_DYING
	db	$40,	$40,	$48,	$48	; PLAYER_STATE_PUSH
	;	...

; Maps player states to assembly routines
PLAYER_UPDATE_TABLE:
	dw	UPDATE_PLAYER_FLOOR	; PLAYER_STATE_FLOOR
	dw	UPDATE_PLAYER_STAIRS	; PLAYER_STATE_STAIRS
	dw	UPDATE_PLAYER_AIR	; PLAYER_STATE_AIR
	dw	UPDATE_PLAYER_DYING	; PLAYER_STATE_DYING
	dw	UPDATE_PLAYER_FLOOR	; PLAYER_STATE_PUSH
	;	...

; Delta-Y (dY) table for jumping and falling
PLAYER_DY_TABLE:
	db	-4, -4			; (2,-8)
	db	-2, -2, -2		; (5,-14)
	db	-1, -1, -1, -1, -1, -1	; (11,-20)
	.TOP_OFFSET:	equ $ - PLAYER_DY_TABLE
	db	 0,  0,  0,  0,  0,  0	; (17,-20)
	.FALL_OFFSET:	equ $ - PLAYER_DY_TABLE
	db	1, 1, 1, 1, 1, 1	; (23,-14) / (6,6)
	db	2, 2, 2			; (26,-8) / (9,12)
	.SIZE:		equ $ - PLAYER_DY_TABLE

; Terminal falling speed (pixels/frame)
	CFG_PLAYER_GRAVITY:		equ 4

; Player related routines (generic)
; Player-tile helper routines
	include	"lib/game/player.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Default player control routines (platformer game)
	include	"lib/game/player_x.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Enemies related routines (generic)
; Convenience enemy state handlers (generic)
; Enemy-tile helper routines

; Maximum simultaneous number of enemies
	CFG_ENEMY_COUNT:		equ 16

; Logical enemy sprite sizes (bounding box size) (pixels)
	CFG_ENEMY_WIDTH:		equ 8
	CFG_ENEMY_HEIGHT:		equ 16

; Enemies animation delay (frames)
	CFG_ENEMY_ANIMATION_DELAY:	equ 10

; Enemies delta-Y (dY) table for jumping and falling
	ENEMY_DY_TABLE:			equ PLAYER_DY_TABLE
	.TOP_OFFSET:			equ PLAYER_DY_TABLE.TOP_OFFSET
	.FALL_OFFSET:			equ PLAYER_DY_TABLE.FALL_OFFSET
	.SIZE:				equ PLAYER_DY_TABLE.SIZE
	
; Enemies terminal falling speed (pixels/frame)
	CFG_ENEMY_GRAVITY:		equ CFG_PLAYER_GRAVITY

; Enemies related routines (generic)
; Convenience enemy state handlers (generic)
; Enemy-tile helper routines
	include	"lib/game/enemy.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Default enemy types (platformer game)
; Convenience enemy state handlers (platformer game)
; Convenience enemy helper routines (platform games)

; Pauses (frames) for the default enemy routines
	CFG_ENEMY_PAUSE_S:	equ 16 ; short pause (~16 frames)
	CFG_ENEMY_PAUSE_M:	equ 40 ; medium pause (~32 frames, < 64 frames)
	CFG_ENEMY_PAUSE_L:	equ 96 ; long pause (~64 frames, < 256 frames)
	
; Default enemy types (platformer game)
; Convenience enemy state handlers (platformer game)
; Convenience enemy helper routines (platform games)
	include	"lib/game/enemy_x.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Bullet related routines (generic)
; Bullet-tile helper routines

; Maximum simultaneous number of bullets
	CFG_BULLET_COUNT:		equ 8

; Logical bullet sprite sizes (bounding box size) (pixels)
	CFG_BULLET_WIDTH:		equ 4
	CFG_BULLET_HEIGHT:		equ 4

; Bullet related routines (generic)
; Bullet-tile helper routines
	include	"lib/game/bullet.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Enemy-player helper routines
	include	"lib/game/collision.asm"
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	Custom parameterization and symbolic constants
; =============================================================================
;

; -----------------------------------------------------------------------------
; Number of frames required to actually push an object
	FRAMES_TO_PUSH:		equ 12

; Playground size
	PLAYGROUND_FIRST_ROW:	equ 0
	PLAYGROUND_LAST_ROW:	equ 23
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	Game main flow
; =============================================================================
;

; -----------------------------------------------------------------------------
; Game entry point
MAIN_INIT:
; Charset (1/2: CHRTBL)
	ld	hl, CHARSET_CHR_PACKED
	call	UNPACK_LDIRVM_CHRTBL
; Charset (2/2: CLRTBL)
	ld	hl, CHARSET_CLR_PACKED
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
; ------VVVV----falls through--------------------------------------------------
	
IFEXIST NAMTBL_TEST_SCREEN
; Is SELECT key pressed?
	halt
	ld	hl, NEWKEY + 7 ; CR SEL BS STOP TAB ESC F5 F4
	bit	6, [hl]
	call	z, INTRO ; yes: skip test screen
	
	ld	hl, NAMTBL_TEST_SCREEN
	ld	de, namtbl_buffer
	call	UNPACK
	call	INIT_STAGE
	call	ENASCR_NO_FADE
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
	ld	hl, NAMTBL_PACKED_INTRO
	ld	de, namtbl_buffer
	call	UNPACK
; Mimics in-game loop preamble and initialization	
	call	INIT_STAGE
; Fade in
	call	ENASCR_FADE_IN

; Intro sequence #1: the fall

; Special initialization
	ld	hl, player.state
	set	BIT_STATE_LEFT, [hl]
	call	SET_PLAYER_FALLING
.LOOP_1:
; Synchronization (halt) and blit buffers to VRAM
	call	PUT_PLAYER_SPRITE
	halt
	call	LDIRVM_SPRATR
; Mimics game logic
	call	UPDATE_PLAYER
; Check exit condition
	ld	a, [player.state]
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_AIR
	jr	z, .LOOP_1 ; no

; Intro sequence #2: the floor

; Crashed sprite
	ld	a, PLAYER_SPRITE_INTRO_PATTERN
	ld	[player_spratr.pattern], a
	add	4
	ld	[player_spratr.pattern +4], a
	call	LDIRVM_SPRATR

; Intro sequence #3: the darkness

; Loop preamble
	ld	hl, NAMTBL
	ld	b, 16 ; 16 lines
.LOOP_2:
	push	bc ; preserves counter
	push	hl ; preserves line
; Synchronization (halt)
	halt
	halt	; (slowly)
	halt
	pop	hl ; restores line
; Erases one line in VRAM
	ld	bc, SCR_WIDTH
	push	bc ; preserves SCR_WIDTH
	push	hl ; preserves line (again)
	ld	a, $20 ; " " ASCII
	call	FILVRM
	pop	hl ; restores line (again)
	pop	bc ; restores SCR_WIDTH
; Moves one line down
	add	hl, bc
	pop	bc ; resotres counter
	djnz	.LOOP_2

; Intro sequence #4: the awakening

; Loads first tutorial stage screen into NAMTBL buffer
	ld	hl, NAMTBL_PACKED_TABLE.TUTORIAL_01
	ld	de, namtbl_buffer
	call	UNPACK
; Mimics in-game loop preamble and initialization	
	call	INIT_STAGE
; Special initialization
	ld	hl, player.state
	set	BIT_STATE_LEFT, [hl]
; Pause until trigger
.LOOP_3:
	halt
	call	GET_TRIGGER
	jr	z, .LOOP_3

; Awakens player
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
	ld	a, [game.current_stage]
	cp	TUTORIAL_STAGES
	jr	nc, .NORMAL
	
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
	add	$31 - TUTORIAL_STAGES ; "1"
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
	
IFDEF CFG_DEBUG_BDRCLR
	ld	b, 12 ; green: game logic
	call	SET_BDRCLR
ENDIF

; Prepares next frame (2/2)
	call	RESET_SPRITES

; Read input devices
	call	GET_STICK_BITS
	call	GET_TRIGGER

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
	ld	a, [game.current_stage]
	cp	TUTORIAL_STAGES
	jp	c, NEW_STAGE ; yes: next stage directly
	jp	z, TUTORIAL_OVER ; no: tutorial finished
	
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
	
; Is it a tutorial stage?
	ld	a, [game.current_stage]
	cp	TUTORIAL_STAGES
	jp	c, NEW_STAGE ; yes: re-enter current stage, no life lost
	
; Life loss logic
	ld	hl, game.lives
	xor	a
	cp	[hl]
	jr	z, GAME_OVER ; no lives left
	dec	[hl]

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
; Actualiza el movimiento automático de los elementos empujables
; (esto es: inicia su movimiento de caída)
UPDATE_BOXES_AND_ROCKS:
; ¿Hay pushables?
	ld	a, [spriteables.count]
	or	a
	ret	z ; no
; sí
	ld	b, a ; b = contador
	ld	ix, spriteables.array
.LOOP:
	push	bc ; preserva el contador
; ¿Está activo?
	ld	a, [ix +_SPRITEABLE_STATUS]
	or	a
	jr	nz, .NEXT ; sí: pasa al siguiente
	
; no
	ld	a, [ix +_SPRITEABLE_BACKGROUND]
	and	$fe ; (para descartar el bit más bajo)
; ¿condiciones especiales (entrando en agua)?
	cp	CHAR_WATER_SURFACE
	jr	nz, .NO_WATER ; no
; sí: ¿es una caja?
	ld	a, [ix +_SPRITEABLE_PATTERN]
	cp	BOX_SPRITE_PATTERN
	jr	z, .BOX_ON_WATER ; sí
	jr	.ROCK_ON_WATER ; no (es una roca)
.NO_WATER:

; ¿condiciones especiales (entrando en lava)?
	cp	CHAR_LAVA_SURFACE
	jr	nz, .NO_LAVA ; no
; sí: ¿es una caja?
	ld	a, [ix +_SPRITEABLE_PATTERN]
	cp	BOX_SPRITE_PATTERN
	jr	z, .BOX_ON_LAVA ; sí
	jr	.ROCK_ON_LAVA ; no (es una roca)
.NO_LAVA:

.CHECK:
; Lee el caracter bajo la parte izquierda del spriteable
	ld	hl, namtbl_buffer +SCR_WIDTH *2 ; (+2,+0)
	ld	e, [ix +_SPRITEABLE_OFFSET_L]
	ld	d, [ix +_SPRITEABLE_OFFSET_H]
	add	hl, de
	push	hl ; preserva el puntero al buffer namtbl
	ld	a, [hl]
	call	GET_TILE_FLAGS
	ld	c, a ; preserva el valor
; Lee el caracter bajo la parte derecha del spriteable
	pop	hl ; restaura puntero al buffer namtbl
	inc	hl
	ld	a, [hl]
	call	GET_TILE_FLAGS
	or	c ; combina el valor
; ¿Es sólido?
	bit	BIT_WORLD_SOLID, a
	jr	nz, .NEXT ; sí
	cp	(1 << BIT_WORLD_FLOOR) OR (1 << BIT_WORLD_STAIRS)
	jr	z, .NEXT ; sí
; no: inicia el movimiento hacia abajo
	call	MOVE_SPRITEABLE_DOWN

.NEXT:
; Pasa al siguiente elemento
	ld	bc, SPRITEABLE_SIZE
	add	ix, bc
	pop	bc ; restaura el contador
	djnz	.LOOP
	ret
	
.BOX_ON_WATER:
; Cambia los caracteres que se volcarán y los vuelca inmediatamente
	ld	a, BOX_FIRST_CHAR_WATER
	ld	[ix + _SPRITEABLE_FOREGROUND], a
	call	VPOKE_SPRITEABLE_FOREGROUND
	jr	.STOP_BOX
.BOX_ON_LAVA:
; Elimina los caracteres de la caja y recupera el fondo inmediatamente
	call	NAMTBL_BUFFER_SPRITEABLE_BACKGROUND
	call	VPOKE_SPRITEABLE_BACKGROUND
	; jr	.STOP_BOX ; falls through
.STOP_BOX:
; Detiene el spriteable
	ld	a, SPRITEABLE_STOPPED
	ld	[ix + _SPRITEABLE_STATUS], a
; no continúa procesando la caída
	jr	.NEXT
	
.ROCK_ON_WATER:
; Cambia los caracteres que se volcarán
	ld	a, ROCK_FIRST_CHAR_WATER
	ld	[ix + _SPRITEABLE_FOREGROUND], a
; Cambia el color del sprite
	ld	a, ROCK_SPRITE_COLOR_WATER
	ld	[ix + _SPRITEABLE_COLOR], a
; continúa procesando la caída
	jr	.CHECK
	
.ROCK_ON_LAVA:
; Cambia los caracteres que se volcarán
	ld	a, ROCK_FIRST_CHAR_LAVA
	ld	[ix + _SPRITEABLE_FOREGROUND], a
; Cambia el color del sprite
	ld	a, ROCK_SPRITE_COLOR_LAVA
	ld	[ix + _SPRITEABLE_COLOR], a
; continúa procesando la caída
	jr	.CHECK
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
	ld	a, [star]
	or	a
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
	call	CHECK_PLAYER_ENEMY_COLLISION.Y
	jp	nc, RET_NOT_ZERO
; right?
	ld	a, [player.x]
	cp	[ix + enemy.x]
	jp	c, RET_NOT_ZERO
; Sets the next state as the enemy state
	ld	bc, ENEMY_STATE.NEXT
	jp	SET_NEW_STATE_HANDLER.BC_OK
	
.TRIGGER_LEFT_HANDLER:
	call	CHECK_PLAYER_ENEMY_COLLISION.Y
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
	dw	.KEY		; key
	dw	.STAR	; star
	dw	.BONUS	; coin
	dw	.BONUS	; fruit: cherry
	dw	.BONUS	; fruit: strawberry
	dw	.BONUS	; fruit: apple
	dw	.BONUS	; octopus
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
.KEY:
; Travels the NAMTBL buffer
	ld	hl, namtbl_buffer
	ld	bc, NAMTBL_SIZE
.LOOP:
; Is a closed-door char?
	ld	a, [hl]
	cp	CHAR_FIRST_CLOSED_DOOR
	jr	c, .NEXT ; no (< CHAR_FIRST_CLOSED_DOOR)
	cp	CHAR_LAST_CLOSED_DOOR + 1
	jr	nc, .NEXT ; no (> CHAR_LAST_CLOSED_DOOR)
; yes: make it an open-door char
	push	bc ; preserves counter
	push	hl ; preserves offset
	add	CHAR_FIRST_OPEN_DOOR - CHAR_FIRST_CLOSED_DOOR
	call	UPDATE_NAMTBL_BUFFER_AND_VPOKE
	pop	hl ; restaura puntero
	pop	bc ; restaura contador
.NEXT:
; Busca el siguiente elemento
	cpi	; inc hl, dec bc
	ret	po
	jr	.LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
.STAR:
	ld	a, 1
	ld	[star], a
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
.BONUS:
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wide tile collision (player width)
ON_PLAYER_WIDE_ON:
; Cursor down?
	ld	hl, stick
	bit	BIT_STICK_DOWN, [hl]
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
ON_PLAYER_ENEMY_COLLISION:	equ SET_PLAYER_DYING
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ON_PLAYER_BULLET_COLLISION:	equ SET_PLAYER_DYING
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Game data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Literals
TXT_STAGE:
	db	"STAGE 00", $00
	.SIZE:		equ $ - TXT_STAGE
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
	
TXT_LIVES:
	db	"0 LIVES LEFT", $00
	.SIZE: equ $ - TXT_LIVES
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
	
TXT_GAME_OVER:
	db	"GAME OVER", $00
	.SIZE: equ $ - TXT_GAME_OVER
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial value of the globals
GLOBALS_0:
	dw	2500			; .hi_score
	db	0			; game.current_stage (intro)
	.SIZE:	equ $ - GLOBALS_0
	
; Initial value of the game-scope vars
GAME_0:
	db	0			; .current_stage
	db	3			; .continues
	dw	0			; .score
	db	5			; .lives
	.SIZE:	equ $ - GAME_0

; Initial value of the stage-scoped vars
STAGE_0:
	db	0			; player.pushing
	db	0			; star
	.SIZE:	equ $ - STAGE_0

; Initial (per stage) sprite attributes table
SPRATR_0:
; Player sprites
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_1
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_2
; SPAT end marker
	db	SPAT_END
	
; Initial (per stage) player vars
PLAYER_0:
	db	48, 128			; .y, .x
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index
	.SIZE:	equ $ - PLAYER_0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial enemy data
ENEMY_0:

.BAT:
	db	BAT_SPRITE_PATTERN
	db	BAT_SPRITE_COLOR
	dw	ENEMY_TYPE_FLYER
	
.SPIDER:
	db	SPIDER_SPRITE_PATTERN
	db	SPIDER_SPRITE_COLOR
	dw	ENEMY_TYPE_FALLER
	
.OCTOPUS:

.SNAKE:
	db	SNAKE_SPRITE_PATTERN
	db	SNAKE_SPRITE_COLOR
	dw	ENEMY_TYPE_WALKER.WITH_PAUSE

; Skeleton: the skeleton is slept until the star is picked up,
; then, it becomes of type walker (follower with pause)
.SKELETON:
	db	SKELETON_SPRITE_PATTERN OR FLAG_ENEMY_PATTERN_LEFT
	db	SKELETON_SPRITE_COLOR
	dw	$ + 2
; Slept until the star is picked up
	dw	ENEMY_SKELETON.HANDLER
	db	0 ; (unused)

.SAVAGE:
	db	SAVAGE_SPRITE_PATTERN
	db	SAVAGE_SPRITE_COLOR
	dw	ENEMY_TYPE_WALKER.FOLLOWER

.TRAP_RIGHT:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	dw	$ + 2
; Does the player overlaps y coordinate?
	dw	ENEMY_TRAP.TRIGGER_RIGHT_HANDLER
	db	0 ; (unused)
; Shoot
	dw	ENEMY_TRAP.SHOOT_RIGHT_HANDLER
	db	0 ; (unused)
	dw	SET_NEW_STATE_HANDLER
	db	ENEMY_STATE.NEXT
; then pause and restart
	dw	STATIONARY_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M
	dw	SET_NEW_STATE_HANDLER
	db	-4 * ENEMY_STATE.SIZE; (restart)
	
.TRAP_LEFT:
	db	ARROW_LEFT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	dw	$ + 2
; Does the player overlaps y coordinate?
	dw	ENEMY_TRAP.TRIGGER_LEFT_HANDLER
	db	0 ; (unused)
; Shoot
	dw	ENEMY_TRAP.SHOOT_LEFT_HANDLER
	db	0 ; (unused)
	dw	SET_NEW_STATE_HANDLER
	db	ENEMY_STATE.NEXT
; then pause and restart
	dw	STATIONARY_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M
	dw	SET_NEW_STATE_HANDLER
	db	-4 * ENEMY_STATE.SIZE; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial bullet data
BULLET_0:

.ARROW_RIGHT:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	BULLET_DIR_RIGHT OR 4 ; (4 pixels / frame)
	
.ARROW_LEFT:
	db	ARROW_LEFT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	BULLET_DIR_LEFT OR 4 ; (4 pixels / frame)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
NAMTBL_TEST_SCREEN:
	incbin	"games/stevedore/screen.tmx.bin.zx7"
	
NAMTBL_PACKED_INTRO:
	incbin	"games/stevedore/intro.tmx.bin.zx7"

NAMTBL_PACKED_TABLE:
	dw	.TUTORIAL_01
	dw	.TUTORIAL_02
	dw	.TUTORIAL_03
	dw	.TUTORIAL_04
	dw	.TUTORIAL_05
	dw	.JUNGLE_01
	dw	.VOLCANO_01
	
.TUTORIAL_01:
	incbin	"games/stevedore/tutorial_01.tmx.bin.zx7"
.TUTORIAL_02:
	incbin	"games/stevedore/tutorial_02.tmx.bin.zx7"
.TUTORIAL_03:
	incbin	"games/stevedore/tutorial_03.tmx.bin.zx7"
.TUTORIAL_04:
	incbin	"games/stevedore/tutorial_04.tmx.bin.zx7"
.TUTORIAL_05:
	incbin	"games/stevedore/tutorial_05.tmx.bin.zx7"
	
.JUNGLE_01:
	incbin	"games/stevedore/jungle_01.tmx.bin.zx7"
	
.VOLCANO_01:
	incbin	"games/stevedore/volcano_01.tmx.bin.zx7"
	
	TUTORIAL_STAGES:	equ 4 ; 5
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Charset binary data (CHRTBL and CLRTBL)
CHARSET_CHR_PACKED:
	incbin	"games/stevedore/charset.pcx.chr.zx7"
	
CHARSET_CLR_PACKED:
	incbin	"games/stevedore/charset.pcx.clr.zx7"
	
; Charset-related symbolic constants
	CHAR_FIRST_ITEM:	equ $01
	CHAR_FIRST_OPEN_DOOR:	equ $08
	CHAR_FIRST_CLOSED_DOOR:	equ $88
	CHAR_LAST_CLOSED_DOOR:	equ $8f
	
	CHAR_WATER_SURFACE:	equ $1a
	CHAR_LAVA_SURFACE:	equ $1c
	
	BOX_FIRST_CHAR:		equ $10
	BOX_FIRST_CHAR_WATER:	equ $f4
	
	ROCK_FIRST_CHAR:	equ $14
	ROCK_FIRST_CHAR_WATER:	equ $f8
	ROCK_FIRST_CHAR_LAVA:	equ $fc
	
	SKELETON_FIRST_CHAR:	equ $98
	
	TRAP_UPPER_LEFT_CHAR:	equ $ce
	TRAP_UPPER_RIGHT_CHAR:	equ $cf
	TRAP_LOWER_LEFT_CHAR:	equ $de
	TRAP_LOWER_RIGHT_CHAR:	equ $df
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sprites binary data (SPRTBL)
SPRTBL_PACKED:
	incbin	"games/stevedore/sprites.pcx.spr.zx7"

; Sprite-related symbolic constants (SPRATR)
	PLAYER_SPRITE_COLOR_1:		equ 9
	PLAYER_SPRITE_COLOR_2:		equ 15
	
	BAT_SPRITE_PATTERN:		equ $50
	BAT_SPRITE_COLOR:		equ 4

	SPIDER_SPRITE_PATTERN:		equ $60
	SPIDER_SPRITE_COLOR:		equ 13
	
	OCTOPUS_SPRITE_PATTERN:		equ $68
	OCTOPUS_SPRITE_COLOR:		equ 13
	
	SNAKE_SPRITE_PATTERN:		equ $70
	SNAKE_SPRITE_COLOR:		equ 2
	
	SKELETON_SPRITE_PATTERN:	equ $80
	SKELETON_SPRITE_COLOR:		equ 15
	
	SAVAGE_SPRITE_PATTERN:		equ $90
	SAVAGE_SPRITE_COLOR:		equ 8

	BOX_SPRITE_PATTERN:		equ $a0
	BOX_SPRITE_COLOR:		equ 9
	
	ROCK_SPRITE_PATTERN:		equ $a4
	ROCK_SPRITE_COLOR:		equ 14
	ROCK_SPRITE_COLOR_WATER:	equ 5
	ROCK_SPRITE_COLOR_LAVA:		equ 9

	ARROW_RIGHT_SPRITE_PATTERN:	equ $a8
	ARROW_LEFT_SPRITE_PATTERN:	equ $ac
	ARROW_SPRITE_COLOR:		equ 14
	
	PLAYER_SPRITE_INTRO_PATTERN:	equ $b0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Padding to a 8kB boundary
PADDING:
	ds	($ OR $1fff) -$ +1, $ff ; $ff = rst $38
	.SIZE:	equ $ - PADDING
; -----------------------------------------------------------------------------

;
; =============================================================================
;	RAM
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
;	User vars

; Global vars (i.e.: initialized only once)
globals:

.hi_score:
	rw	1

; Game vars (i.e.: vars from start to game over)
game:

.current_stage:
	rb	1
.continues:
	rb	1
.score:
	rw	1
.lives:
	rb	1

; Stage vars (i.e.: vars inside the main game loop)
stage:

; Number of consecutive frames the player has been pushing an object
player.pushing:
	rb	1
; The player has picked up the star
star:
	rb	1
; -----------------------------------------------------------------------------

ram_end:

; -----------------------------------------------------------------------------
; Unpacker routine buffer
unpack_buffer:
IFDEF CFG_RAM_RESERVE_BUFFER
	rb	CFG_RAM_RESERVE_BUFFER
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	bytes_rom_MSXlib_code:	equ MAIN_INIT - ROM_START
	bytes_rom_game_code:	equ CHARSET_CHR_PACKED - MAIN_INIT
	bytes_rom_game_data:	equ PADDING - CHARSET_CHR_PACKED

	bytes_ram_MSXlib:	equ globals - ram_start
	bytes_ram_game:		equ ram_end - globals
	
	bytes_total_rom:	equ PADDING - ROM_START
	bytes_total_ram:	equ ram_end - ram_start

	bytes_free_rom:		equ PADDING.SIZE
	bytes_free_ram:		equ $f380 - $
; -----------------------------------------------------------------------------

; EOF
