
;
; =============================================================================
;	MSXlib core configuration, routines and initialization
; =============================================================================
;

; -----------------------------------------------------------------------------
; Define to visually debug frame timing
	; CFG_DEBUG_BDRCLR:
	
; Define to prefer speed over size wherever speed does matter
; (e.g.: jp instead of jr, inline routines, etc.)
	; CFG_OPT_SPEED:
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
; Default player control routines (platformer game)

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

; Terminal falling speed (pixels/frame)
	CFG_PLAYER_GRAVITY:		equ 4

; Delta-Y (dY) table for jumping and falling
PLAYER_DY_TABLE:
	db	-4, -4			; (2,-8)
	db	-2, -2, -2		; (5,-14)
	db	-1, -1, -1, -1, -1, -1	; (11,-20)
	db	 0,  0,  0,  0,  0,  0	; (17,-20)
	.FALL_OFFSET:	equ $ - PLAYER_DY_TABLE
	db	1, 1, 1, 1, 1, 1	; (23,-14) / (6,6)
	db	2, 2, 2			; (26,-8) / (9,12)
	db	CFG_PLAYER_GRAVITY	; (terminal falling speed)
	.SIZE:		equ $ - PLAYER_DY_TABLE

; Player related routines (generic)
	include	"lib/game/player.asm"

; Default player control routines (platformer game)
	include	"lib/game/player_x.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Enemies related routines
; Default enemy behavior routines (platformer game)

; Maximum simultaneous number of enemies
	CFG_ENEMY_COUNT:		equ 8

; Logical sprite sizes (bounding box size) (pixels)
	CFG_ENEMY_WIDTH:		equ 8
	CFG_ENEMY_HEIGHT:		equ 16

; Enemies animation delay (frames)
	CFG_ENEMY_ANIMATION_DELAY:	equ 8	
	
; Enemies related routines (generic)
	include	"lib/game/enemy.asm"
	
; Default enemy behavior routines (platformer game)
	include	"lib/game/enemy_handlers.asm"
	include	"lib/game/enemy_routines.asm"
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
	
; -----------------------------------------------------------------------------
; Skips the main menu and goes into tutorial stages the first time
TUTORIAL_FIRST:
; Is SELECT key pressed?
	halt
	ld	hl, NEWKEY + 7
	bit	6, [hl]
	call	z, MAIN_MENU ; yes: skip tutorial

; no: skip MAIN_MENU and enter tutorial stages
	xor	a
	ld	[game.current_stage], a
	call	ENASCR_NO_FADE
	jp	NEW_STAGE
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
	jr	c, GAME_LOOP_INIT
	
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
	call	LDIRVM_NAMTBL_FADE_INOUT
	call	TRIGGER_PAUSE_ONE_SECOND
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
	
; In-game loop preamble and initialization
	call	RESET_SPRITES
	call	RESET_ENEMIES
	call	RESET_VPOKES
	call	RESET_SPRITEABLES
	
	call	INIT_STAGE	; (custom)
	
; Fade in
	call	LDIRVM_NAMTBL_FADE_INOUT
	; call	LDIRVM_NAMTBL_FADE_INOUT
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop
GAME_LOOP:
; Prepares next frame (1/2)
	call	PUT_PLAYER_SPRITE
	
; Synchronization (halt)
IFDEF CFG_DEBUG_BDRCLR
	ld	b, 1
	call	SET_BDRCLR ; black: free frame time
	halt
	ld	b, 4
	call	SET_BDRCLR ; blue: VDP busy
ELSE
	halt
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

; Game logic
	call	UPDATE_SPRITEABLES
	call	UPDATE_BOXES_AND_ROCKS	; (custom)
	call	UPDATE_PLAYER
	call	UPDATE_ENEMIES
	; call	UPDATE_BULLETS		; específica
	; call	CHECK_COLLISIONS_ENEMIES
	
	call	UPDATE_FRAMES_PUSHING	; (custom)
	
; Extra input
	ld	hl, NEWKEY + 7
	bit	4, [hl]
	call	z, ON_GAME_LOOP_STOP_KEY
	
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
ON_GAME_LOOP_STOP_KEY:
; Has the player already finished?
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	ret	nz ; yes: do nothing

; no: It is a tutorial stage?
	ld	a, [game.current_stage]
	cp	TUTORIAL_STAGES
	jr	c, TUTORIAL_OVER ; yes: skip tutorial
	
; no: Is the player already dying?
	ld	a, [player.state]
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_DYING
	ret	z ; yes: do nothing
	
; no: kills the player
	ld	a, PLAYER_STATE_DYING
	jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due stage over
STAGE_OVER:
; Next stage logic
	ld	hl, game.current_stage
	inc	[hl]
	
; Is it a tutorial stage?
	ld	a, [game.current_stage]
	cp	TUTORIAL_STAGES
	jp	c, NEW_STAGE ; yes: next stage directly
	jp	z, TUTORIAL_OVER ; no: tutorial finished
	
; Fade out
	call	DISSCR_FADE_OUT

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
; Is it a tutorial stage?
	ld	a, [game.current_stage]
	cp	TUTORIAL_STAGES
	jp	c, NEW_STAGE ; .SKIP ; yes: no lives lost
	
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
; Box
	cp	BOX_FIRST_CHAR
	jr	z, .INIT_BOX
; Rock
	cp	ROCK_FIRST_CHAR
	jr	z, .INIT_ROCK
; 0 = Initial player coordinates
	cp	'0'
	jr	z, .INIT_START_POINT
; ; 1, 2... = Enemies
	; cp	'1'
	; jr	z, .INIT_SNAKE
	; cp	'2'
	; jr	z, .INIT_SKELETON
	ret

; Inicializa un tile sprite de una caja
.INIT_BOX:
	call	INIT_SPRITEABLE
	ld	[ix + _SPRITEABLE_PATTERN], BOX_SPRITE_PATTERN
	ld	[ix + _SPRITEABLE_COLOR], BOX_SPRITE_COLOR
	ret

; Inicializa el tile sprite de una roca
.INIT_ROCK:
	call	INIT_SPRITEABLE
	ld	[ix + _SPRITEABLE_PATTERN], ROCK_SPRITE_PATTERN
	ld	[ix + _SPRITEABLE_COLOR], ROCK_SPRITE_COLOR
	ret

; Initial player coordinates
.INIT_START_POINT:
	call	.CLEAR_CHAR_GET_LOGICAL_COORDS
	ld	hl, player.y
	ld	[hl], d
	inc	hl ; hl = player.x
	ld	[hl], e
	ret

; ; Enemies
; .INIT_SNAKE:
	; call	CLEAR_CHAR_GET_LOGICAL_COORDS
; ; Initializes the enemy in the array
	; call	INIT_ENEMY
	; .db	ENEMY_PATTERN_SNAKE
	; .db	ENEMY_COLOR_SNAKE
	; .dw	ENEMY_ROUTINE_CRAWLER

; .INIT_SKELETON:
	; call	CLEAR_CHAR_GET_LOGICAL_COORDS
; ; Initializes the enemy in the array
	; call	INIT_ENEMY
	; .db	ENEMY_PATTERN_SKELETON
	; .db	ENEMY_COLOR_SKELETON
	; .dw	ENEMY_ROUTINE_FOLLOWER

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
; ON_ENEMY_COLLISION_UX:
	; ld	a, [ix + _ENEMY_STATE]
	; cp	ENEMY_TRIGGER
	; jr	nz, ON_BULLET_COLLISION_UX
	
	; push	ix
	; ld	d, [ix + _ENEMY_Y]
	; ld	e, [ix + _ENEMY_X]
	; call	INIT_BULLET
	; ld	[ix + _BULLET_PATTERN], BULLET_PATTERN_RIGHT
	; ld	[ix + _BULLET_COLOR], BULLET_COLOR
	; ld	[ix + _BULLET_STATE], BULLET_STATE_FLY_RIGHT
	; pop	ix
	; ret

; ON_BULLET_COLLISION_UX:
	; ld	a, PLAYER_STATE_DYING
	; jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Game data
; =============================================================================
;

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
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sprites binary data (SPRTBL)
SPRTBL_PACKED:
	incbin	"games/stevedore/sprites.pcx.spr.zx7"

; Sprite-related symbolic constants (SPRATR)
	BOX_SPRITE_PATTERN:		equ $b0
	BOX_SPRITE_COLOR:		equ 9
	
	ROCK_SPRITE_PATTERN:		equ $b4
	ROCK_SPRITE_COLOR:		equ 14
	ROCK_SPRITE_COLOR_WATER:	equ 5
	ROCK_SPRITE_COLOR_LAVA:		equ 9

	; ENEMY_PATTERN_SNAKE	equ $50
	; ENEMY_PATTERN_SKELETON	equ $60
	; ENEMY_COLOR_SNAKE	equ 2
	; ENEMY_COLOR_SKELETON	equ 15
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
NAMTBL_PACKED_TABLE:
	; dw	.TEST
	
	dw	.TUTORIAL_01
	dw	.TUTORIAL_02
	dw	.TUTORIAL_03
	dw	.TUTORIAL_04
	dw	.TUTORIAL_05
	dw	.JUNGLE_01
	dw	.VOLCANO_01
	
.TEST:
	incbin	"games/stevedore/screen.tmx.bin.zx7"
	
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
; Initial value of the globals
GLOBALS_0:
	dw	2500			; .hi_score
	db	0			; game.current_stage (tutorial)
	.SIZE:	equ $ - GLOBALS_0
	
; Initial value of the game-scope vars
GAME_0:
	db	TUTORIAL_STAGES		; .current_stage
	db	3			; .continues
	dw	0			; .score
	db	5			; .lives
	.SIZE:	equ $ - GAME_0

; Initial value of the stage-scoped vars
STAGE_0:
	db	0			; player.pushing
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

ROM_END:

; -----------------------------------------------------------------------------
; Padding to a 8kB boundary
	ds	($ OR $1fff) -$ +1, $ff ; $ff = rst $38
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
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacker routine buffer
unpack_buffer:
IFDEF CFG_RAM_RESERVE_BUFFER
	rb	CFG_RAM_RESERVE_BUFFER
ENDIF
; -----------------------------------------------------------------------------

ram_end:

; EOF
