
;
; =============================================================================
;	MSXlib core configuration, routines and initialization
; =============================================================================
;

; -----------------------------------------------------------------------------
; Define to visually debug frame timing
	; CFG_DEBUG_BDRCLR:
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; MSX cartridge (ROM) header, entry point and initialization

; Define if the ROM is larger than 16kB (typically, 32kB)
; Includes search for page 2 slot/subslot at start
	CFG_INIT_32KB_ROM:

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
; Palette routines for MSX2 VDP

; Custom initial palette in $0GRB format (with R, G, B in 0..7).
CFG_CUSTOM_PALETTE:
	dw	$0000, $0000, $0523, $0634, $0104, $0326, $0140, $0537
	dw	$0362, $0472, $0672, $0774, $0301, $0333, $0555, $0777
; Example: Default MSX2 palette
	; dw	$0000, $0000, $0611, $0733, $0117, $0327, $0151, $0627
	; dw	$0171, $0373, $0661, $0664, $0411, $0265, $0555, $0777

; Palette routines for MSX2 VDP
	include "lib/msx/vram_msx2.asm"
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

; -----------------------------------------------------------------------------
; Replayer routines

; PT3-based implementation
	include	"lib\msx\replayer_pt3.asm"
; WYZPlayer v0.47c-based implementation
	; include	"lib\msx\replayer_wyz.asm"
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
	db	$5f, $00 ; [$00..$5f] : 0
	db	$bf, $03 ; [$60..$bf] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID
	db	$c7, $06 ; [$c0..$c7] : BIT_WORLD_FLOOR | BIT_WORLD_STAIRS
	db	$cf, $04 ; [$c8..$cf] : BIT_WORLD_STAIRS
	db	$d7, $02 ; [$d0..$d7] : BIT_WORLD_FLOOR
	db	$df, $83 ; [$d8..$df] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID | BIT_WORLD_PUSH
	db	$e5, $10 ; [$e0..$e5] : BIT_WORLD_WALK_ON (items)
	db	$ed, $00 ; [$e6..$ed] : 0 (empty)
	db	$f7, $08 ; [$ee..$f7] : BIT_WORLD_DEATH
	db	$ff, $20 ; [$f8..$ff] : BIT_WORLD_WIDE_ON (doors)

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

; Controls if the player jumps with BIT_STRICK_UP or with BIT_TRIGGER_A/B
	CFG_PLAYER_JUMP_INPUT:	equ BIT_TRIGGER_A
	
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

; Offsets to create a new bullet from an emey position (pixels)
	CFG_ENEMY_TO_BULLET_X_OFFSET:	equ 0
	CFG_ENEMY_TO_BULLET_Y_OFFSET:	equ -8

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
;	MSXlib external routines
; =============================================================================
;

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


;
; =============================================================================
; 	Game code and data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Game code
	include "games/stevedore/stevedore.code.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game data
	include "games/stevedore/stevedore.data.asm"
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
; Game vars
	include "games/stevedore/stevedore.ram.asm"
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
	bytes_rom_game_code:	equ TXT_PUSH_SPACE_KEY - MAIN_INIT
	bytes_rom_game_data:	equ PADDING - TXT_PUSH_SPACE_KEY

	bytes_ram_MSXlib:	equ globals - ram_start
	bytes_ram_game:		equ ram_end - globals

	bytes_total_rom:	equ PADDING - ROM_START
	bytes_total_ram:	equ ram_end - ram_start

	bytes_free_rom:		equ PADDING.SIZE
	bytes_free_ram:		equ $f380 - $
; -----------------------------------------------------------------------------

; EOF
