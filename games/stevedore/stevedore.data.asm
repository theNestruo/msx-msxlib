
;
; =============================================================================
;	Game data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Literals
TXT_PUSH_SPACE_KEY:
	db	"PUSH SPACE KEY"
	.SIZE:		equ $ - TXT_PUSH_SPACE_KEY
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
	db	$00
	
TXT_STAGE:
	db	"STAGE 00"
	.SIZE:		equ $ - TXT_STAGE
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
	db	$00
	
TXT_LIVES:
	db	"0 LIVES LEFT"
	.SIZE: 		equ $ - TXT_LIVES
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
	db	$00
	
TXT_GAME_OVER:
	db	"GAME OVER"
	.SIZE: 		equ $ - TXT_GAME_OVER
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
	db	$00
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
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_FLYER
	
.SPIDER:
	db	SPIDER_SPRITE_PATTERN
	db	SPIDER_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_FALLER
	
.OCTOPUS:

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

.SAVAGE:
	db	SAVAGE_SPRITE_PATTERN
	db	SAVAGE_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_WALKER.FOLLOWER

.TRAP_RIGHT:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	$00 ; (not lethal)
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
	db	$00 ; (not lethal)
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
INTRO_DATA:

.NAMTBL_PACKED:
	incbin	"games/stevedore/intro.tmx.bin.zx7"
	
.BROKEN_BRIDGE_CHARS:
	db	$b4, $00, $b1 ; 3 bytes
	
.FLOOR_CHARS:
	db	$a5, $85, $a4, $e5, $e4, $e5, $85, $a4, $a5 ; 9 bytes
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
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

; .TEST:
	incbin	"games/stevedore/screen.tmx.bin.zx7"
	
	TUTORIAL_STAGES:	equ 5
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

; EOF
