
;
; =============================================================================
;	Game data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Literals
IFDEF CFG_DEMO_MODE
TXT_COPYRIGHT:
	db	"STEVEDORE", $00
	db	"RETROEUSKAL 2018 PROMO VERSION", $00
	db	"DO NOT PUBLISH ??", $00
	db	" ", $00
	db	"@2018 THENESTRUO = WONDER", $00
	db	$00
ENDIF

TXT_PUSH_SPACE_KEY:
	db	"PUSH SPACE KEY", $00

TXT_STAGE_SELECT:
	db	"STAGE SELECT", $00
	
._0:	db	"WAREHOUSE <TUTORIAL>",		$00
._1:	db	"LIGHTHOUSE",			$00
._2:	db	"ABANDONED SHIP",		$00
._3:	db	"SHIPWRECK ISLAND",		$00 ; (jungle)
._4:	db	"UNCANNY CAVE",			$00 ; (volcano)
._5:	db	"ANCIENT TEMPLE RUINS",		$00 ; (temple)
	
TXT_INPUT_PASSWORD:
	db	"INPUT "
	
TXT_PASSWORD:
	db	"PASSWORD:" ;  + " " + PASSWORD_SIZE
	.SIZE:		equ ($ + 1 + PASSWORD_SIZE) - TXT_PASSWORD ; "... password"
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
	db	$00

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

TXT_CHAPTER_OVER:
	db	"SORRY; STEVEDORE",		$00
	db	"BUT THE LIGHTHOUSE KEEPER",	$00
	db	"IS IN ANOTHER BUILDING?",	$00
	db	"WAS KIDNAPPED BY PIRATES?",	$00
	db	"SHIPWRECKED?",			$00
	db	"FELL INTO A CAVE?",		$00
	db	"WAS CAPTURED BY PANTOJOS?",	$00

TXT_ENDING:
	db	"YOU ARE GREAT?", $00
	
TXT_GAME_OVER:
	db	"GAME OVER", $00

IFDEF CFG_DEMO_MODE
TXT_DEMO_OVER:
	db	"DEMO OVER", $00
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial value of the globals
GLOBALS_0:
	db	1			; .chapters
	db	$00			; .flags
	.SIZE:	equ $ - GLOBALS_0
	
; Initial value of the game-scope vars
GAME_0:
	db	5			; .lives
	db	0			; .item_counter
	db	0			; .chapter
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
	db	$25, $24, $25, $5c, $84, $85, $11, $24, $25 ; 9 bytes
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; "Stage select" screen data
STAGE_SELECT:

.NAMTBL:
	incbin	"games/stevedore/maps/stage_select.tmx.bin"
	.WIDTH:		equ 4
	.HEIGHT:	equ 8	

.FLOOR_CHARS:
	db	$25, $24, $25, $84, $85, $11, $24, $25 ; 8 bytes

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
	db	 6, $07 ; Ship
	db	12, $13 ; Jungle
	db	18, $19 ; Volcano
	db	24, $25 ; Temple
	db	30, $31 ; Secret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
NAMTBL_PACKED_TABLE:
; Stages
	dw	.LIGHTHOUSE_1,	.LIGHTHOUSE_2,	.LIGHTHOUSE_3,	.LIGHTHOUSE_4,	.LIGHTHOUSE_5,	.LIGHTHOUSE_6
	dw	.SHIP_1,	.SHIP_2, 	.SHIP_3,	.SHIP_4,	.SHIP_5,	.SHIP_6
	dw	.JUNGLE_1,	.JUNGLE_2,	.JUNGLE_3,	.JUNGLE_4,	.JUNGLE_5,	.JUNGLE_6
	dw	.VOLCANO_1,	.VOLCANO_2, 	.VOLCANO_3,	.VOLCANO_4,	.VOLCANO_5,	.VOLCANO_6
	dw	.TEMPLE_1,	.TEMPLE_2,	.TEMPLE_3,	.TEMPLE_4,	.TEMPLE_5,	.TEMPLE_6
	dw	.SECRET_1,	.SECRET_2, 	.SECRET_3,	.SECRET_4,	.SECRET_5,	.SECRET_6
; Intro screen
	dw	.INTRO_STAGE
; Warehouse (tutorial)
	dw	.WAREHOUSE_1,	.WAREHOUSE_2,	.WAREHOUSE_3,	.WAREHOUSE_4,	.WAREHOUSE_5

.EMPTY:		incbin	"games/stevedore/maps/empty.tmx.bin.zx7"

; Intro	
.INTRO_STAGE:	incbin	"games/stevedore/maps/intro_stage.tmx.bin.zx7"

; Warehouse (tutorial)
.WAREHOUSE_1:	incbin	"games/stevedore/maps/0-1-warehouse.tmx.bin.zx7"
.WAREHOUSE_2:	incbin	"games/stevedore/maps/0-2-warehouse.tmx.bin.zx7"
.WAREHOUSE_3:	incbin	"games/stevedore/maps/0-3-warehouse.tmx.bin.zx7"
.WAREHOUSE_4:	incbin	"games/stevedore/maps/0-4-warehouse.tmx.bin.zx7"
.WAREHOUSE_5:	incbin	"games/stevedore/maps/0-5-warehouse.tmx.bin.zx7"

; Lighthouse
.LIGHTHOUSE_1:	incbin	"games/stevedore/maps/1-1-lighthouse.tmx.bin.zx7"
.LIGHTHOUSE_2:	incbin	"games/stevedore/maps/1-2-lighthouse.tmx.bin.zx7"
.LIGHTHOUSE_3:	incbin	"games/stevedore/maps/1-3-lighthouse.tmx.bin.zx7"
.LIGHTHOUSE_4:	incbin	"games/stevedore/maps/1-4-lighthouse.tmx.bin.zx7"
.LIGHTHOUSE_5:	incbin	"games/stevedore/maps/1-5-lighthouse.tmx.bin.zx7"
.LIGHTHOUSE_6:	incbin	"games/stevedore/maps/1-6-lighthouse.tmx.bin.zx7"

; Ship
.SHIP_1:	incbin	"games/stevedore/maps/2-1-ship.tmx.bin.zx7"
.SHIP_2:	incbin	"games/stevedore/maps/2-2-ship.tmx.bin.zx7"
.SHIP_3:	incbin	"games/stevedore/maps/2-3-ship.tmx.bin.zx7"
.SHIP_4:	incbin	"games/stevedore/maps/2-4-ship.tmx.bin.zx7"
.SHIP_5:	incbin	"games/stevedore/maps/2-5-ship.tmx.bin.zx7"
.SHIP_6:	incbin	"games/stevedore/maps/2-6-ship.tmx.bin.zx7"

; Jungle
.JUNGLE_1:	incbin	"games/stevedore/maps/3-1-jungle.tmx.bin.zx7"
.JUNGLE_2:	incbin	"games/stevedore/maps/3-2-jungle.tmx.bin.zx7"
.JUNGLE_3:	incbin	"games/stevedore/maps/3-3-jungle.tmx.bin.zx7"
.JUNGLE_4:	incbin	"games/stevedore/maps/3-4-jungle.tmx.bin.zx7"
.JUNGLE_5:	incbin	"games/stevedore/maps/3-5-jungle.tmx.bin.zx7"
.JUNGLE_6:	incbin	"games/stevedore/maps/3-6-jungle.tmx.bin.zx7"

; Volcano
.VOLCANO_1:	incbin	"games/stevedore/maps/4-1-volcano.tmx.bin.zx7"
.VOLCANO_2:	incbin	"games/stevedore/maps/4-2-volcano.tmx.bin.zx7"
.VOLCANO_3:	incbin	"games/stevedore/maps/4-3-volcano.tmx.bin.zx7"
.VOLCANO_4:	incbin	"games/stevedore/maps/4-4-volcano.tmx.bin.zx7"
.VOLCANO_5:	incbin	"games/stevedore/maps/4-5-volcano.tmx.bin.zx7"
.VOLCANO_6:	incbin	"games/stevedore/maps/4-6-volcano.tmx.bin.zx7"

; Temple
.TEMPLE_1:	incbin	"games/stevedore/maps/5-1-temple.tmx.bin.zx7"
.TEMPLE_2:	incbin	"games/stevedore/maps/5-2-temple.tmx.bin.zx7"
.TEMPLE_3:	incbin	"games/stevedore/maps/5-3-temple.tmx.bin.zx7"
.TEMPLE_4:	incbin	"games/stevedore/maps/5-4-temple.tmx.bin.zx7"
.TEMPLE_5:	incbin	"games/stevedore/maps/5-5-temple.tmx.bin.zx7"
.TEMPLE_6:	incbin	"games/stevedore/maps/5-6-temple.tmx.bin.zx7"

; Secret
.SECRET_1:	incbin	"games/stevedore/maps/6-1-secret.tmx.bin.zx7"
.SECRET_2:	incbin	"games/stevedore/maps/6-2-secret.tmx.bin.zx7"
.SECRET_3:	incbin	"games/stevedore/maps/6-3-secret.tmx.bin.zx7"
.SECRET_4:	incbin	"games/stevedore/maps/6-4-secret.tmx.bin.zx7"
.SECRET_5:	incbin	"games/stevedore/maps/6-5-secret.tmx.bin.zx7"
.SECRET_6:	incbin	"games/stevedore/maps/6-6-secret.tmx.bin.zx7"
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

; Title charset binary data (CHRTBL and CLRTBL)
CHARSET_TITLE_PACKED:
.CHR:
	incbin	"games/stevedore/gfx/charset_title.pcx.chr.zx7"
.CLR:
	incbin	"games/stevedore/gfx/charset_title.pcx.clr.zx7"
	.SIZE:			equ TITLE_HEIGHT *TITLE_WIDTH *8
	
; Title charset-related symbolic constants
	TITLE_CHAR_FIRST:	equ 96
	TITLE_WIDTH:		equ 16
	TITLE_HEIGHT:		equ 3
	TITLE_CENTER:		equ (SCR_WIDTH - TITLE_WIDTH) /2
	
; Dynamic charset binary data (CHRTBL and CLRTBL)
CHARSET_DYNAMIC:
.CHR:
	incbin	"games/stevedore/gfx/charset_dynamic.pcx.chr"
	.SIZE:			equ $ - CHARSET_DYNAMIC
.CLR:
	incbin	"games/stevedore/gfx/charset_dynamic.pcx.clr"

	.ROW_SIZE:		equ 2 *4 *8; 2 doors/surfaces, 4 characters

; Dynamic charset-related symbolic constants
	CHAR_FIRST_CLOSED_DOOR:	equ $00
	CHAR_FIRST_OPEN_DOOR:	equ $08
	CHAR_FIRST_SURFACES:	equ $10
	
; Bad ending charset binary data (CHRTBL and CLRTBL)
; CHARSET_BAD_ENDING_PACKED:
	incbin	"games/stevedore/gfx/charset_title.pcx.chr.zx7" ; TODO
	incbin	"games/stevedore/gfx/charset_title.pcx.clr.zx7" ; TODO
	
; Good ending charset binary data (CHRTBL and CLRTBL)
; CHARSET_GOOD_ENDING_PACKED:
	incbin	"games/stevedore/gfx/charset_title.pcx.chr.zx7" ; TODO
	incbin	"games/stevedore/gfx/charset_title.pcx.clr.zx7" ; TODO
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sprites binary data (SPRTBL)
SPRTBL_PACKED:
	incbin	"games/stevedore/gfx/sprites.pcx.spr.zx7"

; Sprite-related symbolic constants (SPRATR)
	PLAYER_SPRITE_COLOR_1:		equ 15
	PLAYER_SPRITE_COLOR_2:		equ 9
	
	PLAYER_SPRITE_KO_PATTERN:	equ $50
	PLAYER_SPRITE_HAPPY_PATTERN:	equ $58

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
	
	URCHIN_SPRITE_PATTERN:		equ $c0
	URCHIN_SPRITE_COLOR_1:		equ 14
	URCHIN_SPRITE_COLOR_2:		equ 15
	
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
	dw	.SONG_0, .SONG_1, .SONG_2, .SONG_3, .SONG_4, .SONG_5

.SONG_0:
	incbin	"games/stevedore/sfx/warehouse.pt3.hl.zx7"
.SONG_1:
	incbin	"games/stevedore/sfx/warehouse.pt3.hl.zx7" ; TODO lighthous
.SONG_2:
	incbin	"games/stevedore/sfx/ship.pt3.hl.zx7"
.SONG_3:
	incbin	"games/stevedore/sfx/jungle.pt3.hl.zx7"
.SONG_4:
	incbin	"games/stevedore/sfx/cave.pt3.hl.zx7"
.SONG_5:
	incbin	"games/stevedore/sfx/ship.pt3.hl.zx7" ; TODO temple
	
	incbin	"games/stevedore/sfx/cave.pt3.hl.zx7"; TODO chapter over (jingle)
	incbin	"games/stevedore/sfx/warehouse.pt3.hl.zx7" ; TODO bad ending
	incbin	"games/stevedore/sfx/warehouse.pt3.hl.zx7" ; TODO good ending
	incbin	"games/stevedore/sfx/cave.pt3.hl.zx7"; TODO game over (jingle)
	
; ayFX sound bank
SOUND_BANK:
	incbin	"games/stevedore/sfx/test.afb"
	
	; CFG_SOUND_PLAYER_JUMP:	equ 5 -1 ; 8 -1
	; CFG_SOUND_PLAYER_LAND:	equ 0
	; CFG_SOUND_PLAYER_KILLED:	equ 0
	; CFG_SOUND_PLAYER_FINISH:	equ 0
	; CFG_SOUND_ENEMY_KILLED:	equ 0
	; CFG_SOUND_ENEMY_RESPAWN:	equ 0
; -----------------------------------------------------------------------------

; IFDEF CFG_DEMO_MODE
; IF CFG_DEMO_MODE = 1 ; 1 = RETROEUSKAL 2018 promo version
	; db	"RetroEuskal 2018 promo version"
; ENDIF ; IF CFG_DEMO_MODE = 1
; ENDIF ; IFDEF CFG_DEMO_MODE

; EOF
