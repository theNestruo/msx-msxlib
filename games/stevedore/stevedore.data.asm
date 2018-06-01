
;
; =============================================================================
;	Game data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Literals
; TXT_COPYRIGHT:
	; db	"STEVEDORE", $00
	; db	"@ 2018 THENESTRUO = WONDER", $00
	; db	"PRIVATE BETA: DO NOT PUBLISH", $00
	; db	$00
	
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
	db	1			; .chapters
	db	$00			; .star_counter
	.SIZE:	equ $ - GLOBALS_0
	
; Initial value of the game-scope vars
GAME_0:
	db	4			; .lives
	db	0			; .fruit_counter
	.SIZE:	equ $ - GAME_0

; Initial value of the stage-scoped vars
STAGE_0:
	db	0			; player.pushing
	db	0			; .flags
	db	0			; .frame_counter
	.SIZE:	equ $ - STAGE_0
	
; Initial (per stage) player vars
PLAYER_0:
	; db	48, 128			; .y, .x ; (intro screen coords)
	db	SPAT_OB, 0		; .y, .x
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index
	.SIZE:	equ $ - PLAYER_0

; Initial (per stage) sprite attributes table
SPRATR_0:
; Reserved sprites before player sprites (see CFG_PLAYER_SPRITES_INDEX)
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
; Player sprites
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_1
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_2
; SPAT end marker (No "volatile" sprites)
	db	SPAT_END
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Intro screen data
INTRO_DATA:

.NAMTBL_PACKED:
	incbin	"games/stevedore/maps/intro_screen.tmx.bin.zx7"
	
.BROKEN_BRIDGE_CHARS:
	db	$ca, $00, $c8 ; 3 bytes
	
.FLOOR_CHARS:
	db	$25, $24, $25, $5c, $84, $85, $05, $24, $25 ; 9 bytes
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
	db	176, 128 ; Warehouse (tutorial)
	db	128, 128 ; Lighthouse
	db	0, 0
	db	0, 0
	db	0, 0
	db	0, 0
	.MENU_0_SIZE:	equ $ - .MENU_0_TABLE
; 2nd chapter open
	dw	namtbl_buffer + 11 * SCR_WIDTH + 11
	db	176, 128 ; Warehouse (tutorial)
	db	128, 104 ; Lighthouse
	db	128, 152 ; Ship
	db	0, 0
	db	0, 0
	db	0, 0
; 3rd chapter open
	dw	namtbl_buffer + 11 * SCR_WIDTH + 8
	db	176, 128 ; Warehouse (tutorial)
	db	128,  80 ; Lighthouse
	db	128, 128 ; Ship
	db	128, 176 ; Jungle
	db	0, 0
	db	0, 0
; 4th chapter open
	dw	namtbl_buffer + 11 * SCR_WIDTH + 5
	db	176, 128 ; Warehouse (tutorial)
	db	128,  56 ; Lighthouse
	db	128, 104 ; Ship
	db	128, 152 ; Jungle
	db	128, 200 ; Volcano
	db	0, 0
; All chapters open
	dw	namtbl_buffer + 11 * SCR_WIDTH + 2
	db	176, 128 ; Warehouse (tutorial)
	db	128,  32 ; Lighthouse
	db	128,  80 ; Ship
	db	128, 128 ; Jungle
	db	128, 176 ; Volcano
	db	128, 224 ; Temple

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
	dw	.STAGE_01, .STAGE_03, .STAGE_06, .STAGE_11, .STAGE_14
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
.STAGE_13:	incbin	"games/stevedore/maps/stage_13.tmx.bin.zx7"
.STAGE_14:	incbin	"games/stevedore/maps/stage_14.tmx.bin.zx7"
.STAGE_15:	incbin	"games/stevedore/maps/stage_15.tmx.bin.zx7"

; Volcano
.STAGE_16:	incbin	"games/stevedore/maps/stage_16.tmx.bin.zx7"
.STAGE_17:	incbin	"games/stevedore/maps/stage_17.tmx.bin.zx7"
.STAGE_18:	incbin	"games/stevedore/maps/stage_18.tmx.bin.zx7"
.STAGE_19:	incbin	"games/stevedore/maps/stage_19.tmx.bin.zx7"
.STAGE_20:	incbin	"games/stevedore/maps/stage_20.tmx.bin.zx7"

; Temple
.STAGE_21:	incbin	"games/stevedore/maps/stage_21.tmx.bin.zx7"
.STAGE_22:	incbin	"games/stevedore/maps/stage_22.tmx.bin.zx7"
.STAGE_23:	incbin	"games/stevedore/maps/stage_23.tmx.bin.zx7"
.STAGE_24:	incbin	"games/stevedore/maps/stage_24.tmx.bin.zx7"
.STAGE_25:	incbin	"games/stevedore/maps/stage_25.tmx.bin.zx7"
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
	BAT_SPRITE_COLOR_1:		equ 4
	BAT_SPRITE_COLOR_2:		equ 6

	SNAKE_SPRITE_PATTERN:		equ $70
	SNAKE_SPRITE_COLOR_1:		equ 2
	SNAKE_SPRITE_COLOR_2:		equ 11
	SNAKE_SPRITE_COLOR_3:		equ 8
	
	PIRATE_SPRITE_PATTERN:		equ $80
	PIRATE_SPRITE_COLOR:		equ 14
	
	SAVAGE_SPRITE_PATTERN:		equ $90
	SAVAGE_SPRITE_COLOR:		equ 8
	
	SKELETON_SPRITE_PATTERN:	equ $a0
	SKELETON_SPRITE_COLOR:		equ 15
	
	SPIDER_SPRITE_PATTERN:		equ $b0
	SPIDER_SPRITE_COLOR:		equ 13
	
	JELLYFISH_SPRITE_PATTERN:	equ $b8
	JELLYFISH_SPRITE_COLOR:		equ 15
	
	BOX_SPRITE_PATTERN:		equ $e8
	BOX_SPRITE_COLOR:		equ 9
	
	ROCK_SPRITE_PATTERN:		equ $ec
	ROCK_SPRITE_COLOR:		equ 14
	ROCK_SPRITE_COLOR_WATER:	equ 5
	ROCK_SPRITE_COLOR_LAVA:		equ 9

	ARROW_RIGHT_SPRITE_PATTERN:	equ $c8
	ARROW_LEFT_SPRITE_PATTERN:	equ $cc
	ARROW_SPRITE_COLOR:		equ 14

	KNIFE_RIGHT_SPRITE_PATTERN:	equ $d0
	KNIFE_LEFT_SPRITE_PATTERN:	equ $d4
	KNIFE_SPRITE_COLOR:		equ 14
	
	SPARK_SPRITE_PATTERN:		equ $d8
	SPARK_SPRITE_COLOR:		equ 10
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PT3Player data
SONG_PACKED_TABLE:
IFEXIST DEMO_MODE
	dw	.SONG_0, .SONG_2, .SONG_1, .SONG_3, .SONG_4, .SONG_5
ELSE
	dw	.SONG_0, .SONG_1, .SONG_2, .SONG_3, .SONG_4, .SONG_5
ENDIF
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
	
; ayFX sound bank
SOUND_BANK:
	incbin	"games/stevedore/sfx/test.afb"
	
	CFG_SOUND_PLAYER_JUMP:		equ 5 -1 ; 8 -1
	CFG_SOUND_PLAYER_LAND:		equ 0
	CFG_SOUND_PLAYER_KILLED:	equ 0
	CFG_SOUND_PLAYER_FINISH:	equ 0
	CFG_SOUND_ENEMY_KILLED:		equ 0
	CFG_SOUND_ENEMY_RESPAWN:	equ 0
; -----------------------------------------------------------------------------

; EOF
