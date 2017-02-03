
;
; =============================================================================
;	MSXlib core configuration, routines and initialization
; =============================================================================
;

; -----------------------------------------------------------------------------
; Enable if the ROM is larger than 16kB (typically, 32kB)
; Includes search for page 2 slot/subslot at start
	; CFG_INIT_32KB_ROM:

; Enable if the game needs 16kB instead of 8kB
; RAM will start at the beginning of the page 2 instead of $e000
; and availability will be checked at start
	; CFG_INIT_16KB_RAM:
	
; Maximum number of "vpokes" (deferred WRTVRMs) per frame
	CFG_VRAM_VPOKES:		equ 64

; MSXlib core
	include	"lib/rom.asm"
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

;
; =============================================================================
;	MSXlib game-related configuration and routines
; =============================================================================
;

;
; =============================================================================
; 	Game
; =============================================================================
;

; -----------------------------------------------------------------------------
; Sprite-tile helper routines

; Tile properties table in pairs (up to char number, tile properties)
TILE_PROPERTIES_TABLE:
	db	$7f, $00 ; [$00..$07] : 0
	db	$81, $00 ; [$80..$81] : 0
	db	$8f, $03 ; [$82..$8f] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID
	db	$91, $00 ; [$90..$91] : 0
	db	$9f, $03 ; [$92..$9f] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID
	db	$ff, $00 ; [$ac..$af] : 0

; Caracteres que se devolverán al consultar offscreen
	CFG_TILES_OFFSCREEN_TOP:	equ $01 ; BIT_WORLD_SOLID
	CFG_TILES_OFFSCREEN_BOTTOM:	equ $08 ; BIT_WORLD_DEATH
	
; Sprite-tile helper routines
	include	"lib/game/tiles.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Player related routines

; Logical sprite sizes (bounding box size) (pixels)
	CFG_PLAYER_WIDTH:		equ 8
	CFG_PLAYER_HEIGHT:		equ 16

; Number of player sprites (i.e.: number of colors)
	CFG_PLAYER_SPRITES:		equ 2

; Player animation delay (frames)
	CFG_PLAYER_ANIMATION_DELAY:	equ 6

; Default player states
	; PLAYER_STATE_FLOOR:	equ (0 << 2) ; $00
	; PLAYER_STATE_STAIRS:	equ (1 << 2) ; $04
	; PLAYER_STATE_AIR:	equ (2 << 2) ; $08
	; PLAYER_STATE_DYING:	equ (3 << 2) ; $0c
; Custom player states
	; ...

; Maps player states to sprite patterns
STATUS_SPRATR_TABLE:
	;	0	LEFT	ANIM	LEFT|ANIM
	db	$00,	$10,	$08,	$18	; PLAYER_STATE_FLOOR
	db	$20,	$20,	$28,	$28	; PLAYER_STATE_STAIRS
	db	$08,	$18,	$08,	$18	; PLAYER_STATE_AIR
	db	$30,	$30,	$38,	$38	; PLAYER_STATE_DYING
	;	...

; Maps player states to assembly routines
UPDATE_PLAYER_TABLE:
	dw	UPDATE_PLAYER_FLOOR	; PLAYER_STATE_FLOOR
	dw	UPDATE_PLAYER_STAIRS	; PLAYER_STATE_STAIRS
	dw	UPDATE_PLAYER_AIR	; PLAYER_STATE_AIR
	dw	UPDATE_PLAYER_DYING	; PLAYER_STATE_DYING
	;	...

; Terminal falling velocity (pixels/frame)
	CFG_PLAYER_GRAVITY:		equ 4

; Delta-Y (dY) table for jumping and falling
JUMP_DY_TABLE:
	db	-4, -4			; (2,-8)
	db	-2, -2, -2		; (5,-14)
	db	-1, -1, -1, -1, -1, -1	; (11,-20)
	db	 0,  0,  0,  0,  0,  0	; (17,-20)
	JUMP_DY_TABLE_FALL_OFFSET:	equ $ - JUMP_DY_TABLE
	db	1, 1, 1, 1, 1, 1	; (23,-14) / (6,6)
	db	2, 2, 2			; (26,-8) / (9,12)
	db	CFG_PLAYER_GRAVITY	; (terminal falling speed)
	JUMP_DY_TABLE_SIZE:		equ $ - JUMP_DY_TABLE
	
; Player related routines
	include	"lib/game/player.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Enemies related routines

; Maximum simultaneous number of enemies
	CFG_ENEMY_COUNT:		equ 4

; Logical sprite sizes (bounding box size) (pixels)
	CFG_ENEMY_WIDTH:		equ 8
	CFG_ENEMY_HEIGHT:		equ 16

; Player and enemies animation delay (frames)
	CFG_ENEMY_ANIMATION_DELAY:	equ 8	

; Enemies related routines
	include	"lib/game/enemy.asm"
; (optional) Default handlers and behavior
	include	"lib/game/enemy_handlers.asm"
	include	"lib/game/enemy_routines.asm"
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	Custom parameterization and symbolic constants
; =============================================================================
;

; -----------------------------------------------------------------------------
; 	SYMBOL:	equ value
;	...
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
	ld	bc, GLOBALS_SIZE
	ldir
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
	ld	hl, GAME_VARS_0
	ld	de, game_vars
	ld	bc, GAME_VARS_SIZE
	ldir
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; New stage / new life entry point
NEW_STAGE:
; Name table memory buffer
	ld	hl, NAMTBL_PACKED
	ld	de, namtbl_buffer
	call	UNPACK
	
; Initializes player vars
	ld	hl, PLAYER_VARS_0
	ld	de, player_vars
	ld	bc, PLAYER_VARS_SIZE
	ldir
	
; Initializes sprite attribute table (SPRATR)
	ld	hl, PLAYER_SPRATR_0
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir
	
; Game specific initialization
	call	RESET_DYNAMIC_SPRITES
	call	RESET_ENEMIES
	call	INIT_STAGE	; (custom)
	
; Fade in
	call	ENASCR_FADE_IN
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop
GAME_LOOP:
; Prepares next frame (1/2)
	call	PUT_SPRITE_PLAYER
; Blit buffers to VRAM
	halt
	call	LDIRVM_SPRATR
; Prepares next frame (2/2)
	call	RESET_DYNAMIC_SPRITES
	
; Read input devices
	call	GET_STICK_BITS
	call	GET_TRIGGER
	
; Game logic
	call	UPDATE_PLAYER
	call	UPDATE_ENEMIES
	
; Check exit condition
	ld	a, [player_state]
	bit	BIT_STATE_FINISH, a
	jr	z, GAME_LOOP ; no
; yes: conditionally jump according the exit status
	cp	PLAYER_STATE_DEAD
	jr	z, GAME_LOOP_DEAD ; player is dead
	cp	PLAYER_STATE_FINISH
	; jr	z, GAME_LOOP_FINISH ; stage finished (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due stage over
GAME_LOOP_FINISH:
; Fade out
	call	DISSCR_FADE_OUT

; Next stage logic
	;	...
	
; Next screen
	jp	NEW_STAGE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due death of the player
GAME_LOOP_DEAD:
; Fade out
	call	DISSCR_FADE_OUT

; Life loss logic
	;	...
	xor	a
	
; Enough lifes?
	jp	nz, NEW_STAGE ; yes
	
; no: game over
	; jr	GAME_OVER ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Game over
GAME_OVER:
; Game over screen draw
	call	CLS_NAMTBL
	;	...
	
; Fade in
	call	ENASCR_FADE_IN

; Game over loop
.LOOP:
	halt
	;	...
	; jr	.LOOP
	
; Fade out
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
; Travels the screen
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
	ld	hl, player_y
	ld	[hl], d
	inc	hl ; hl = player_x
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


;
; =============================================================================
;	Game data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Charset binary data (CHRTBL and CLRTBL)
CHARSET_CHR_PACKED:
	incbin	"games/template/charset.pcx.chr.zx7"
	
CHARSET_CLR_PACKED:
	incbin	"games/template/charset.pcx.clr.zx7"
	
; Charset-related symbolic constants
	; ...
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sprites binary data (SPRTBL)
SPRTBL_PACKED:
	incbin	"games/template/sprites.pcx.spr.zx7"
	
; Sprite-related symbolic constants (SPRATR)
	; ...
	
; Sprite-related data (SPRATR)
PLAYER_SPRATR_0:
	db	SPAT_OB, 0, 0, 9	; 1st player sprite
	db	SPAT_OB, 0, 0, 15	; 2nd player sprite
	db	SPAT_END		; SPAT end marker
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
NAMTBL_PACKED:
	incbin	"games/template/screen.tmx.bin.zx7"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial value of the globals, game and stage vars, and player vars
GLOBALS_0:
	dw	2500			; hi_score
	; db	...			; ...

GAME_VARS_0:
	db	5			; lives_left
	dw	0			; score
	; db	...			; ...

STAGE_VARS_0:
	db	0			; ...
	; db	...			; ...
	
; Initial player vars
PLAYER_VARS_0:
	db	0, 0			; player_y, player_x
	db	0			; player_animation_delay
	db	0 ; PLAYER_STATE_FLOOR	; player_state
	db	0			; player_dy_index
	
; =============================================================================

ROM_END:

;
; =============================================================================
; 	RAM
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

hi_score:
	rw	1
; ...
	;	...
	
	GLOBALS_SIZE:	equ $ - globals

; Game vars (i.e.: vars from start to game over)
game_vars:

lives_left:
	rb	1
score:
	rw	1
; ...

	;	...
	GAME_VARS_SIZE:	equ $ - game_vars

; Stage vars (i.e.: vars inside the main game loop)
stage_vars:

; ...
	rb	1
; ...
	;	...
	
	STAGE_VARS_SIZE:	equ $ - stage_vars
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacker routine buffer
unpack_buffer:
IFDEF CFG_RAM_RESERVE_BUFFER
	ds	CFG_RAM_RESERVE_BUFFER
ENDIF
; -----------------------------------------------------------------------------

ram_end:

; EOF
