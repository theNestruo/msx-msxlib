
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
; Example: Default MSX2 palette
	; dw	$0000, $0000, $0611, $0733, $0117, $0327, $0151, $0627
	; dw	$0171, $0373, $0661, $0664, $0411, $0265, $0555, $0777

; Palette routines for MSX2 VDP
	; include "lib/msx/vram_msx2.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; "vpoke" routines (deferred WRTVRMs routines)
; Spriteables routines (2x2 chars that eventually become a sprite)

; Define to enable the "vpoke" routines (deferred WRTVRMs)
; Maximum number of "vpokes" per frame
	CFG_VPOKES: 		equ 64

; Define to enable the spriteable routines
; Maximum number of simultaneous spriteables
	; CFG_SPRITEABLES:	equ 16

; "vpoke" routines (deferred WRTVRMs routines)
; Spriteables routines (2x2 chars that eventually become a sprite)
	include "lib/msx/vram_x.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Replayer routines

; Define to enable packed songs when using the PT3-based implementation
	; CFG_PT3_PACKED:
	
; Define to use headerless PT3 files (without first 100 bytes)
	; CFG_PT3_HEADERLESS:

; PT3-based implementation
	; include	"lib\msx\replayer_pt3.asm"
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
	CFG_TILES_VALUE_OVER:	equ $8f ; BIT_WORLD_FLOOR | BIT_WORLD_SOLID
	CFG_TILES_VALUE_UNDER:	equ $8f ; BIT_WORLD_FLOOR | BIT_WORLD_SOLID

; Table of tile flags in pairs (up to index, tile flags)
TILE_FLAGS_TABLE:
	db	$1f, $00 ; [$00..$1f] : 0 (background)
	db	$7f, $00 ; [$00..$7f] : 0 (font)
	db	$9f, $00 ; [$80..$9f] : 0 (more background)
	db	$bf, $03 ; [$a0..$bf] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID
	db	$c7, $02 ; [$c0..$c7] : BIT_WORLD_FLOOR
	db	$cb, $04 ; [$c8..$cb] : BIT_WORLD_STAIRS
	db	$cf, $06 ; [$cc..$cf] : BIT_WORLD_STAIRS | BIT_WORLD_FLOOR
	db	$d7, $08 ; [$d0..$d7] : BIT_WORLD_DEATH
	db	$df, $10 ; [$d8..$df] : BIT_WORLD_WALK_ON (e.g. items)
	db	$ff, $20 ; [$e0..$ff] : BIT_WORLD_WIDE_ON (e.g. doors)

; Sprite-tile helper routines
	include	"lib/game/tiles.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Player related routines (generic)
; Default player control routines (platformer game)

; Logical sprite sizes (bounding box size) (pixels)
	CFG_PLAYER_WIDTH:		equ 8
	CFG_PLAYER_HEIGHT:		equ 16

; Number of sprites reserved before the player sprites
; (i.e.: first sprite number for the player sprites)
	CFG_PLAYER_SPRITES_INDEX:	equ 0

; Number of player sprites (i.e.: number of colors)
	CFG_PLAYER_SPRITES:		equ 2

; Player animation delay (frames)
	CFG_PLAYER_ANIMATION_DELAY:	equ 6

; Custom player states (starting from 4 << 2)
	; PLAYER_STATE_UVW:	equ (4 << 2) ; $10
	; PLAYER_STATE_XYZ:	equ (5 << 2) ; $14
	; ...

; Maps player states to sprite patterns
PLAYER_SPRATR_TABLE:
	;	0	ANIM	LEFT	LEFT|ANIM
	db	$00,	$08,	$10,	$18	; PLAYER_STATE_FLOOR
	db	$20,	$28,	$20,	$28	; PLAYER_STATE_STAIRS
	db	$08,	$08,	$18,	$18	; PLAYER_STATE_AIR
	db	$30,	$38,	$30,	$38	; PLAYER_STATE_DYING
	;	...				; PLAYER_STATE_...

; Maps player states to assembly routines
PLAYER_UPDATE_TABLE:
	dw	UPDATE_PLAYER_FLOOR	; PLAYER_STATE_FLOOR
	dw	UPDATE_PLAYER_STAIRS	; PLAYER_STATE_STAIRS
	dw	UPDATE_PLAYER_AIR	; PLAYER_STATE_AIR
	dw	UPDATE_PLAYER_DYING	; PLAYER_STATE_DYING
	;	...			; PLAYER_STATE_...

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
	CFG_ENEMY_COUNT:		equ 4

; Logical sprite sizes (bounding box size) (pixels)
	CFG_ENEMY_WIDTH:		equ 8
	CFG_ENEMY_HEIGHT:		equ 16

; Enemies animation delay (frames)
	CFG_ENEMY_ANIMATION_DELAY:	equ 8	

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
	; CFG_BULLET_COUNT:		equ 8

; Logical bullet sprite sizes (bounding box size) (pixels)
	; CFG_BULLET_WIDTH:		equ 4
	; CFG_BULLET_HEIGHT:		equ 4

; Offsets to create a new bullet from an emey position (pixels)
	; CFG_ENEMY_TO_BULLET_X_OFFSET:	equ 0
	; CFG_ENEMY_TO_BULLET_Y_OFFSET:	equ -8

; Bullet related routines (generic)
; Bullet-tile helper routines
	; include	"lib/game/bullet.asm"
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
IF (GLOBALS_0.SIZE > 0)
	ld	hl, GLOBALS_0
	ld	de, globals
	ld	bc, GLOBALS_0.SIZE
	ldir
ENDIF
; ------VVVV----falls through--------------------------------------------------
	
; -----------------------------------------------------------------------------
; Main menu
MAIN_MENU:
; Main menu entry point and initialization
	;	...TBD...
	
; Main menu draw
	call	CLS_NAMTBL
	;	...TBD...
	
; Fade in
	call	ENASCR_FADE_IN

; Main menu loop
.LOOP:
	halt
	;	...TBD...
	; jr	.LOOP
	
; Fade out
	call	DISSCR_FADE_OUT
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
; Prepares the "new stage" screen
	call	CLS_NAMTBL
	
; "STAGE 0"
	ld	hl, TXT_STAGE
	ld	de, namtbl_buffer + 8 * SCR_WIDTH + TXT_STAGE.CENTER
	call	PRINT_TEXT
; "stage N"
	dec	de
	ld	a, [game.current_stage]
	add	$31 ; "1"
	ld	[de], a
	
; "LIVES 0"
	ld	hl, TXT_LIVES
	ld	de, namtbl_buffer + 10 * SCR_WIDTH + TXT_LIVES.CENTER
	push	de
	call	PRINT_TEXT
; "lives N"
	pop	de
	ld	a, [game.lives]
	add	$30 ; "0"
	ld	[de], a

; Fade in
	call	ENASCR_FADE_IN
	call	WAIT_TRIGGER_ONE_SECOND
	call	DISSCR_FADE_OUT
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; New stage / new life entry point
GAME_LOOP_INIT:
; Name table memory buffer (from the current stage)
	ld	hl, NAMTBL_PACKED_TABLE
	ld	a, [game.current_stage]
	add	a ; a *= 2
	call	GET_HL_A_WORD
	ld	de, namtbl_buffer
	call	UNPACK
	
; Initializes stage vars
IF (STAGE_0.SIZE > 0)
	ld	hl, STAGE_0
	ld	de, stage
	ld	bc, STAGE_0.SIZE
	ldir
ENDIF

; Initializes player vars
IF (PLAYER_0.SIZE > 0)
	ld	hl, PLAYER_0
	ld	de, player
	ld	bc, PLAYER_0.SIZE
	ldir
ENDIF
	
; Initializes sprite attribute table (SPRATR)
	ld	hl, SPRATR_0
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir
	
; In-game loop preamble and initialization
	call	RESET_SPRITES
	call	RESET_ENEMIES
	
	call	INIT_STAGE	; (custom)
	
; Fade in
	call	ENASCR_FADE_IN
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
	call	READ_INPUT

; Game logic (1/2: updates)
	call	UPDATE_PLAYER
	call	UPDATE_ENEMIES
	; call	UPDATE_BULLETS

; Game logic (2/2: interactions)
	call	CHECK_PLAYER_ENEMIES_COLLISIONS
	; call	CHECK_PLAYER_BULLETS_COLLISIONS
	
; Check exit condition
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	jr	z, GAME_LOOP ; no
	
; yes: conditionally jump according the exit status
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_FINISH
	jr	z, STAGE_OVER ; stage over
	cp	PLAYER_STATE_DEAD
	jr	z, PLAYER_OVER ; player is dead

; (this should never happen)
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
; In-game loop finish due stage over
STAGE_OVER:
; Next stage logic
	ld	hl, game.current_stage
	inc	[hl]
	
; Fade out
	call	DISSCR_FADE_OUT

; Stage over screen
	;	...
	
; Go to the next stage
	jp	NEW_STAGE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due death of the player
PLAYER_OVER:
; Life loss logic
	ld	hl, game.lives
	xor	a
	cp	[hl]
	jr	z, GAME_OVER ; no lives left
	dec	[hl]

.SKIP:	
; Fade out
	call	DISSCR_FADE_OUT
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
	call	PRINT_TEXT
	
; Fade in
	call	LDIRVM_NAMTBL_FADE_INOUT
	call	WAIT_TRIGGER_FOUR_SECONDS
	call	DISSCR_FADE_OUT
	
	jp	MAIN_MENU
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Custom game routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Initializes the initial player coordinates, enemies and other special elements
INIT_STAGE:
; Travels the playable area
	ld	hl, namtbl_buffer
	ld	bc, NAMTBL_SIZE
.LOOP:
; For each character
	push	bc ; preserves counter
	push	hl ; preserves pointer
	ld	a, [hl]
	call	.INIT_ELEMENT
; Next element
	pop	hl ; restores pointer
	pop	bc ; restores counter
	cpi	; inc hl, dec bc
	ret	po
	jr	.LOOP
	
.INIT_ELEMENT:
; 0 = Initial player coordinates
	cp	'0'
	jr	z, .INIT_START_POINT
	ret

; Initial player coordinates
.INIT_START_POINT:
	call	.CLEAR_CHAR_GET_LOGICAL_COORDS
	ld	hl, player.y
	ld	[hl], d
	inc	hl ; hl = player.x
	ld	[hl], e
	ret

; Rutina de conveniencia que elimina el caracter de control
; y devuelve las coordenadas lógicas para ubicar ahí un sprite
; param hl: puntero del buffer namtbl del caracter de control
; ret de: coordenadas lógicas del sprite
.CLEAR_CHAR_GET_LOGICAL_COORDS:
; elimina el caracter de control
	ld	[hl], 0
; calcula las coordenadas
	call	NAMTBL_POINTER_TO_COORDS
; convierte a coordenadas lógicas
	ld	a, 4 ; medio caracter a la derecha
	add	e
	ld	e, a
	ld	a, 8 ; un caracter hacia abajo
	add	d
	ld	d, a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	MSXlib user extensions (UX)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Tile collision (single char): e.g. Items
ON_PLAYER_WALK_ON:
; Reads the tile index and NAMTBL offset and buffer pointer
	call	GET_PLAYER_TILE_VALUE
	push	hl ; preserves NAMTBL buffer pointer
; Executes item action
	sub	CHARSET.ITEM_0
	;	...TBD...
; Removes the item in the NAMTBL buffer and VRAM
	xor	a
	pop	hl ; restores NAMTBL buffer pointer
	jp	UPDATE_NAMTBL_BUFFER_AND_VPOKE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wide tile collision (player width): e.g. Exit door
; ON_PLAYER_WIDE_ON:
	;	...TBD...
; Set "stage finish" state
	; ld	a, PLAYER_STATE_FINISH
	; jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pushing a pushable object: e.g. switches
; ON_PLAYER_PUSH:
	;	...TBD...
	; ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Collision of the player with an enemy
ON_PLAYER_ENEMY_COLLISION:	equ SET_PLAYER_DYING
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Collision of the player with an enemy bullet
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
	dw	1000			; .hi_score
	;	...			; ...
	.SIZE:	equ $ - GLOBALS_0
	
; Initial value of the game-scope vars
GAME_0:
	db	0			; .current_stage
	db	3			; .continues
	dw	0			; .score
	db	5			; .lives
	;	...			; ...
	.SIZE:	equ $ - GAME_0

; Initial value of the stage-scoped vars
STAGE_0:
	;	...			; ...
	.SIZE:	equ $ - STAGE_0

; Initial (per stage) sprite attributes table
SPRATR_0:
	db	SPAT_OB, 0, 0, 9	; Player 1st sprite
	db	SPAT_OB, 0, 0, 15	; Player 2nd sprite
	db	SPAT_END		; SPAT end marker
	
; Initial (per stage) player vars
PLAYER_0:
	db	0, 0			; .y, .x
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index
	.SIZE:	equ $ - PLAYER_0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
NAMTBL_PACKED_TABLE:
	dw	.SCREEN	; stage 0
	dw	.SCREEN	; stage 1
	dw	.SCREEN	; stage 2
	dw	.SCREEN	; stage 3
	dw	.SCREEN	; stage 5
	;	...
	
.SCREEN:
	incbin	"games/template/screen.tmx.bin.zx7"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Charset binary data (CHRTBL and CLRTBL)
CHARSET_PACKED:
.CHR:
	incbin	"games/template/charset.pcx.chr.zx7"
.CLR:
	incbin	"games/template/charset.pcx.clr.zx7"
	
; Charset-related symbolic constants
CHARSET:
	.ITEM_0:	equ $d8 ; First item
	; ...
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Sprites binary data (SPRTBL)
SPRTBL_PACKED:
	incbin	"games/stevedore/gfx/sprites.pcx.spr.zx7"

; Sprite-related symbolic constants (SPRATR)
	; ...
	
; Sprite-related data (SPRATR)
	; db	SPAT_OB, 0, 0, 9	; 1st player sprite
	; db	SPAT_OB, 0, 0, 15	; 2nd player sprite
	; db	SPAT_END		; SPAT end marker
	; ...
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
; ...
	; ...
	
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
; ...
	; ...

; Stage vars (i.e.: vars inside the main game loop)
stage:

; ...
	; ...
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
	bytes_rom_game_code:	equ TXT_STAGE - MAIN_INIT
	bytes_rom_game_data:	equ PADDING - TXT_STAGE

	bytes_ram_MSXlib:	equ globals - ram_start
	bytes_ram_game:		equ ram_end - globals
	
	bytes_total_rom:	equ PADDING - ROM_START
	bytes_total_ram:	equ ram_end - ram_start

	bytes_free_rom:		equ PADDING.SIZE
	bytes_free_ram:		equ $f380 - $
; -----------------------------------------------------------------------------

; EOF
