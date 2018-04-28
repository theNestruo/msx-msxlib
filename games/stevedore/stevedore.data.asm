
;
; =============================================================================
;	Game data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Literals
TXT_COPYRIGHT:
	db	"@ 2018 THENESTRUO = WONDER", $00
	
TXT_PUSH_SPACE_KEY:
	db	"PUSH SPACE KEY", $00

TXT_STAGE:
	db	"STAGE"
	.SIZE:		equ ($ + 3) - TXT_STAGE ; "... 00"
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
	db	$00
	
TXT_LIVES:
	db	"LIVES LEFT"
	.SIZE: 		equ $ - TXT_LIVES
	.CENTER:	equ (SCR_WIDTH - .SIZE - 2) /2 ; "0 ..."
	db	$00

TXT_LIFE:
	db	"LIFE LEFT"
	db	$00
	
TXT_GAME_OVER:
	db	"GAME OVER", $00

TXT_STAGE_SELECT:
	db	"STAGE SELECT", $00
	
._0:	db	"WAREHOUSE <TUTORIAL>",		$00
._1:	db	"LIGHTHOUSE",			$00
._2:	db	"ABANDONED SHIP",		$00
._3:	db	"SHIPWRECK ISLAND",		$00 ; (jungle)
._4:	db	"UNCANNY CAVE",			$00 ; (volcano)
._5:	db	"ANCIENT TEMPLE RUINS",		$00 ; (temple)
	
TXT_CHAPTER_OVER:
	db	"SORRY; STEVEDORE",		$00
	db	"BUT THE LIGHTHOUSE KEEPER",	$00
	db	"IS IN ANOTHER BUILDING?",	$00
	db	"WAS KIDNAPPED BY PIRATES?",	$00
	db	"SHIPWRECKED?",			$00
	db	"FELL INTO A CAVE?",		$00
	db	"WAS CAPTURED BY PANTOJOS?",	$00
	
IFEXIST DEMO_MODE
TXT_DEMO_OVER:
	db	"DEMO OVER", $00
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial value of the globals
GLOBALS_0:
	db	1 ; 1			; .chapters ; DEBUG LINE
	db	$00, $00, $00		; .hi_score
	.SIZE:	equ $ - GLOBALS_0
	
; Initial value of the game-scope vars
GAME_0:
	db	$00, $00, $00		; .score
	db	3			; .lives
	.SIZE:	equ $ - GAME_0

; Initial value of the stage-scoped vars
STAGE_0:
	db	0			; player.pushing
	db	0			; .flags
	db	0			; .frame_counter
	.SIZE:	equ $ - STAGE_0

; Initial (per stage) sprite attributes table
SPRATR_0:
; Reserved sprites before player sprites (see CFG_PLAYER_SPRITES_BEFORE)
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
; Player sprites
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_1
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_2
; SPAT end marker (No "volatile" sprites)
	db	SPAT_END
	
; Initial (per stage) player vars
PLAYER_0:
	db	48, 128			; .y, .x ; (intro screen coords)
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index
	.SIZE:	equ $ - PLAYER_0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial enemy data
ENEMY_0:

; Bat: the bat flies, the turns around and continues
.BAT:
	db	BAT_SPRITE_PATTERN
	db	BAT_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_FLYER

; Spider: the spider falls onto the ground the the player is near
.SPIDER:
	db	SPIDER_SPRITE_PATTERN
	db	SPIDER_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_FALLER.WITH_TRIGGER

; Octopus: not implemented yet	
.OCTOPUS:
	db	OCTOPUS_SPRITE_PATTERN
	db	OCTOPUS_SPRITE_COLOR
	db	$00 ; (not lethal)
	dw	ENEMY_TYPE_WAVER ; $ + 2
; ; The enemy floats up
	; dw	PUT_ENEMY_SPRITE_PATTERN
	; db	OCTOPUS_SPRITE_PATTERN or FLAG_ENEMY_PATTERN_ANIM
	; dw	ENEMY_OCTOPUS.FLOAT_UP_HANDLER
	; db	16 ; 16 pixels
	; dw	SET_NEW_STATE_HANDLER
	; db	ENEMY_STATE.NEXT
; ; The enemy floats down
	; dw	PUT_ENEMY_SPRITE_PATTERN
	; db	OCTOPUS_SPRITE_PATTERN
	; dw	ENEMY_OCTOPUS.FLOAT_DOWN_HANDLER
	; db	16 ; 16 pixels
	; dw	SET_NEW_STATE_HANDLER
	; db	-5 * ENEMY_STATE.SIZE ; (restart)

; Snake: the snake walks, the pauses, turning around, and continues
.SNAKE:
	db	SNAKE_SPRITE_PATTERN
	db	SNAKE_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_WALKER.WITH_PAUSE

; Skeleton: the skeleton is slept until the star is picked up,
; then, it becomes of type walker (follower with pause)
.SKELETON:
	db	SKELETON_SPRITE_PATTERN OR FLAG_ENEMY_PATTERN_LEFT
	db	SKELETON_SPRITE_COLOR
	db	$00 ; (not lethal in the initial state)
	dw	$ + 2
; Slept until the star is picked up
	dw	ENEMY_SKELETON.HANDLER
	db	0 ; (unused)

; Savage: the savage walks towards the player, pausing briefly
.SAVAGE:
	db	SAVAGE_SPRITE_PATTERN
	db	SAVAGE_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_WALKER.FOLLOWER

; Trap (pointing right): shoots when the player is in front of it
.TRAP_RIGHT:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	$00 ; (not lethal)
	dw	$ + 2
; Does the player overlaps y coordinate?
	dw	TRIGGER_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M
	dw	ENEMY_TRAP.TRIGGER_RIGHT_HANDLER
	db	0 ; (unused)
; Shoot
	dw	ENEMY_TRAP.SHOOT_RIGHT_HANDLER
	db	0 ; (unused)
	dw	RET_NOT_ZERO
	; db	0 ; (unused)
	
; Trap (pointing left): shoots when the player is in front of it
.TRAP_LEFT:
	db	ARROW_LEFT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	$00 ; (not lethal)
	dw	$ + 2
; Does the player overlaps y coordinate?
	dw	TRIGGER_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M
	dw	ENEMY_TRAP.TRIGGER_LEFT_HANDLER
	db	0 ; (unused)
; Shoot
	dw	ENEMY_TRAP.SHOOT_LEFT_HANDLER
	db	0 ; (unused)
	dw	RET_NOT_ZERO
	; db	0 ; (unused)
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
	
.OIL_UP:
	db	OIL_SPRITE_PATTERN
	db	OIL_SPRITE_COLOR
	db	BULLET_DIR_UP OR 4 ; (4 pixels / frame)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Intro screen data
INTRO_DATA:

.NAMTBL_PACKED:
	incbin	"games/stevedore/maps/intro_screen.tmx.bin.zx7"
	
.BROKEN_BRIDGE_CHARS:
	db	$ca, $00, $c8 ; 3 bytes
	
.FLOOR_CHARS:
	db	$25, $24, $25, $64, $84, $85, $14, $24, $25 ; 9 bytes
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; "Stage select" screen data
STAGE_SELECT:

.NAMTBL:
	incbin	"games/stevedore/maps/stage_select.tmx.bin"
	.WIDTH:		equ 4
	.HEIGHT:	equ 8	

.FLOOR_CHARS:
	db	$24, $25, $84, $85, $14, $24 ; 6 bytes

.MENU_0_TABLE:
; 1st chapter open
; .namtbl_buffer_origin
	dw	namtbl_buffer + 11 * SCR_WIDTH + 14
; .player_0_table
	db	176 +SPRITE_HEIGHT, 128 ; Warehouse (tutorial)
	db	128 +SPRITE_HEIGHT, 128 ; Lighthouse
	db	0, 0
	db	0, 0
	db	0, 0
	db	0, 0
	.MENU_0_SIZE:	equ $ - .MENU_0_TABLE
; 2nd chapter open
	dw	namtbl_buffer + 11 * SCR_WIDTH + 11
	db	176 +SPRITE_HEIGHT, 128 ; Warehouse (tutorial)
	db	128 +SPRITE_HEIGHT, 104 ; Lighthouse
	db	128 +SPRITE_HEIGHT, 152 ; Ship
	db	0, 0
	db	0, 0
	db	0, 0
; 3rd chapter open
	dw	namtbl_buffer + 11 * SCR_WIDTH + 8
	db	176 +SPRITE_HEIGHT, 128 ; Warehouse (tutorial)
	db	128 +SPRITE_HEIGHT,  80 ; Lighthouse
	db	128 +SPRITE_HEIGHT, 128 ; Ship
	db	128 +SPRITE_HEIGHT, 176 ; Jungle
	db	0, 0
	db	0, 0
; 4th chapter open
	dw	namtbl_buffer + 11 * SCR_WIDTH + 5
	db	176 +SPRITE_HEIGHT, 128 ; Warehouse (tutorial)
	db	128 +SPRITE_HEIGHT,  56 ; Lighthouse
	db	128 +SPRITE_HEIGHT, 104 ; Ship
	db	128 +SPRITE_HEIGHT, 152 ; Jungle
	db	128 +SPRITE_HEIGHT, 200 ; Volcano
	db	0, 0
; All chapters open
	dw	namtbl_buffer + 11 * SCR_WIDTH + 2
	db	176 +SPRITE_HEIGHT, 128 ; Warehouse (tutorial)
	db	128 +SPRITE_HEIGHT,  32 ; Lighthouse
	db	128 +SPRITE_HEIGHT,  80 ; Ship
	db	128 +SPRITE_HEIGHT, 128 ; Jungle
	db	128 +SPRITE_HEIGHT, 176 ; Volcano
	db	128 +SPRITE_HEIGHT, 224 ; Temple

.GAME_0_TABLE:
	;	.stage,	.stage_bcd
	db	FIRST_TUTORIAL_STAGE, $00 ; Warehouse (tutorial)
	db	 0, $01 ; Lighthouse
	db	 5, $06 ; Ship
	db	10, $11 ; Jungle
	db	15, $16 ; Volcano
	db	20, $21 ; Temple
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
NAMTBL_PACKED_TABLE:
IFEXIST DEMO_MODE
	dw	.STAGE_01, .STAGE_02, .STAGE_11, .STAGE_14, .STAGE_14
ELSE
	dw	.STAGE_01, .STAGE_02, .STAGE_03, .STAGE_04, .STAGE_05
ENDIF ; IFEXIST DEMO_MODE
	dw	.STAGE_06, .STAGE_07, .STAGE_08, .STAGE_09, .STAGE_10
	dw	.STAGE_11, .STAGE_12, .STAGE_13, .STAGE_14, .STAGE_15
	dw	.STAGE_16, .STAGE_17, .STAGE_18, .STAGE_19, .STAGE_20
	dw	.STAGE_21, .STAGE_22, .STAGE_23, .STAGE_24, .STAGE_25
; Intro
	dw	.INTRO_STAGE
; Warehouse (tutorial)
	dw	.TUTORIAL_01, .TUTORIAL_02, .TUTORIAL_03, .TUTORIAL_04, .TUTORIAL_05

; Intro	
.INTRO_STAGE:	incbin	"games/stevedore/maps/intro_stage.tmx.bin.zx7"

; Warehouse (tutorial)
.TUTORIAL_01:	incbin	"games/stevedore/maps/tutorial_01.tmx.bin.zx7"
.TUTORIAL_02:	incbin	"games/stevedore/maps/tutorial_02.tmx.bin.zx7"
.TUTORIAL_03:	incbin	"games/stevedore/maps/tutorial_03.tmx.bin.zx7"
.TUTORIAL_04:	incbin	"games/stevedore/maps/tutorial_04.tmx.bin.zx7"
.TUTORIAL_05:	incbin	"games/stevedore/maps/tutorial_05.tmx.bin.zx7"

; Lighthouse
.STAGE_01:	incbin	"games/stevedore/maps/stage_01.tmx.bin.zx7"
.STAGE_02:	incbin	"games/stevedore/maps/stage_02.tmx.bin.zx7"
.STAGE_03:	incbin	"games/stevedore/maps/stage_03.tmx.bin.zx7"
.STAGE_04:	incbin	"games/stevedore/maps/stage_04.tmx.bin.zx7"
.STAGE_05:	incbin	"games/stevedore/maps/stage_05.tmx.bin.zx7"

; Ship
.STAGE_06:	incbin	"games/stevedore/maps/stage_06.tmx.bin.zx7"
.STAGE_07:	incbin	"games/stevedore/maps/stage_07.tmx.bin.zx7"
.STAGE_08:	incbin	"games/stevedore/maps/stage_08.tmx.bin.zx7"
.STAGE_09:	incbin	"games/stevedore/maps/stage_09.tmx.bin.zx7"
.STAGE_10:	incbin	"games/stevedore/maps/stage_10.tmx.bin.zx7"

; Jungle
.STAGE_11:	incbin	"games/stevedore/maps/stage_11.tmx.bin.zx7"
.STAGE_12:	incbin	"games/stevedore/maps/stage_12.tmx.bin.zx7"
.STAGE_13:	incbin	"games/stevedore/maps/stage_12.tmx.bin.zx7"
.STAGE_14:	incbin	"games/stevedore/maps/stage_14.tmx.bin.zx7"
.STAGE_15:	incbin	"games/stevedore/maps/stage_14.tmx.bin.zx7"

; Volcano
.STAGE_16:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
.STAGE_17:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
.STAGE_18:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
.STAGE_19:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
.STAGE_20:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"

; Temple
.STAGE_21:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
.STAGE_22:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
.STAGE_23:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
.STAGE_24:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
.STAGE_25:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Charset binary data (CHRTBL and CLRTBL)
CHARSET_PACKED:
.CHR:
	incbin	"games/stevedore/gfx/charset.pcx.chr.zx7"
.CLR:
	incbin	"games/stevedore/gfx/charset.pcx.clr.zx7"
	
; Charset-related symbolic constants
	SKELETON_FIRST_CHAR:	equ $2e
	TRAP_UPPER_RIGHT_CHAR:	equ $6e
	TRAP_UPPER_LEFT_CHAR:	equ $6f
	TRAP_LOWER_RIGHT_CHAR:	equ $7e
	TRAP_LOWER_LEFT_CHAR:	equ $7f
	CHAR_FIRST_FRAGILE:	equ $d0
	BOX_FIRST_CHAR:		equ $d8
	ROCK_FIRST_CHAR:	equ $dc
	CHAR_FIRST_ITEM:	equ $e0
	CHAR_WATER_SURFACE:	equ $f0
	CHAR_LAVA_SURFACE:	equ $f4
	CHAR_FIRST_DOOR:	equ $f8

CHARSET_TITLE_PACKED:
.CHR:
	incbin	"games/stevedore/gfx/charset_title.pcx.chr.zx7"
.CLR:
	incbin	"games/stevedore/gfx/charset_title.pcx.clr.zx7"
	.SIZE:			equ TITLE_HEIGHT *TITLE_WIDTH *8
	
	TITLE_CHAR_FIRST:	equ 96
	TITLE_WIDTH:		equ 16
	TITLE_HEIGHT:		equ 3
	TITLE_CENTER:		equ (SCR_WIDTH - TITLE_WIDTH) /2
	
CHARSET_DYNAMIC:
.CHR:
	incbin	"games/stevedore/gfx/charset_dynamic.pcx.chr"
	.SIZE:			equ $ - CHARSET_DYNAMIC
.CLR:
	incbin	"games/stevedore/gfx/charset_dynamic.pcx.clr"

	.ROW_SIZE:		equ 2 *4 *8; 2 doors/surfaces, 4 characters

	CHAR_FIRST_CLOSED_DOOR:	equ $00
	CHAR_FIRST_OPEN_DOOR:	equ $08
	CHAR_FIRST_SURFACES:	equ $10
	
; Dynamic charset-related symbolic constants
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sprites binary data (SPRTBL)
SPRTBL_PACKED:
	incbin	"games/stevedore/gfx/sprites.pcx.spr.zx7"

; Sprite-related symbolic constants (SPRATR)
	PLAYER_SPRITE_COLOR_1:		equ 15
	PLAYER_SPRITE_COLOR_2:		equ 9
	
	PLAYER_SPRITE_INTRO_PATTERN:	equ $50

	BAT_SPRITE_PATTERN:		equ $60
	BAT_SPRITE_COLOR:		equ 4
	
	SKELETON_SPRITE_PATTERN:	equ $70
	SKELETON_SPRITE_COLOR:		equ 15
	
	SNAKE_SPRITE_PATTERN:		equ $80
	SNAKE_SPRITE_COLOR:		equ 2
	
	SAVAGE_SPRITE_PATTERN:		equ $90
	SAVAGE_SPRITE_COLOR:		equ 8

	SPIDER_SPRITE_PATTERN:		equ $a0
	SPIDER_SPRITE_COLOR:		equ 13
	
	OCTOPUS_SPRITE_PATTERN:		equ $a8
	OCTOPUS_SPRITE_COLOR:		equ 1
	
	BOX_SPRITE_PATTERN:		equ $b0
	BOX_SPRITE_COLOR:		equ 9
	
	ROCK_SPRITE_PATTERN:		equ $b4
	ROCK_SPRITE_COLOR:		equ 14
	ROCK_SPRITE_COLOR_WATER:	equ 5
	ROCK_SPRITE_COLOR_LAVA:		equ 9

	ARROW_RIGHT_SPRITE_PATTERN:	equ $b8
	ARROW_LEFT_SPRITE_PATTERN:	equ $bc
	ARROW_SPRITE_COLOR:		equ 14
	
	OIL_SPRITE_PATTERN:		equ $d8
	OIL_SPRITE_COLOR:		equ 7
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PT3Player data
SONG_PACKED_TABLE:
	dw	.SONG_0, .SONG_1, .SONG_2, .SONG_3, .SONG_4, .SONG_5
.SONG_0:
	incbin	"games/stevedore/sfx/warehouse.pt3.hl.zx7"
.SONG_1:
	incbin	"games/stevedore/sfx/warehouse.pt3.hl.zx7" ; TODO
.SONG_2:
	incbin	"games/stevedore/sfx/ship.pt3.hl.zx7"
.SONG_3:
	incbin	"games/stevedore/sfx/jungle.pt3.hl.zx7"
.SONG_4:
	incbin	"games/stevedore/sfx/cave.pt3.hl.zx7"
.SONG_5:
	incbin	"games/stevedore/sfx/ship.pt3.hl.zx7" ; TODO
; -----------------------------------------------------------------------------

; EOF
