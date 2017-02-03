
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

; -----------------------------------------------------------------------------
; Sprite-tile helper routines

; Tile properties table in pairs (up to char number, tile properties)
TILE_PROPERTIES_TABLE:
	db	$00, $00 ; [     $00] : 0
	db	$0f, $10 ; [$01..$0f] : BIT_WORLD_UX_WALK_ON (items and doors)
	db	$17, $83 ; [$10..$17] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID | BIT_WORLD_UX_PUSH
	db	$1f, $08 ; [$18..$1f] : BIT_WORLD_DEATH
	db	$ab, $00 ; [$00..$ab] : 0 (chars and backgrounds)
	db	$af, $04 ; [$ac..$af] : BIT_WORLD_STAIRS
	db	$b7, $02 ; [$b0..$b7] : BIT_WORLD_FLOOR
	db	$bf, $06 ; [$ba..$bf] : BIT_WORLD_FLOOR | BIT_WORLD_STAIRS
	db	$ff, $03 ; [$c0..$ff] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID

; Offscreen tile properties
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
	; PLAYER_STATE_FLOOR	equ (0 << 2) ; $00
	; PLAYER_STATE_STAIRS	equ (1 << 2) ; $04
	; PLAYER_STATE_AIR	equ (2 << 2) ; $08
	; PLAYER_STATE_DYING	equ (3 << 2) ; $0c
; Custom player states
	PLAYER_STATE_PUSH:	equ (4 << 2) ; $10
	;	...

; Maps player states to sprite patterns
STATUS_SPRATR_TABLE:
	;	0	LEFT	ANIM	LEFT|ANIM
	db	$00,	$10,	$08,	$18	; PLAYER_STATE_FLOOR
	db	$20,	$20,	$28,	$28	; PLAYER_STATE_STAIRS
	db	$08,	$18,	$08,	$18	; PLAYER_STATE_AIR
	db	$30,	$30,	$38,	$38	; PLAYER_STATE_DYING
	db	$40,	$48,	$40,	$48	; PLAYER_STATE_PUSH
	;	...

; Maps player states to assembly routines
UPDATE_PLAYER_TABLE:
	dw	UPDATE_PLAYER_FLOOR	; PLAYER_STATE_FLOOR
	dw	UPDATE_PLAYER_STAIRS	; PLAYER_STATE_STAIRS
	dw	UPDATE_PLAYER_AIR	; PLAYER_STATE_AIR
	dw	UPDATE_PLAYER_DYING	; PLAYER_STATE_DYING
	dw	UPDATE_PLAYER_FLOOR	; PLAYER_STATE_PUSH
	;	...

; Terminal falling speed (pixels/frame)
	CFG_PLAYER_GRAVITY:		equ 4

; Delta-Y table for jumping and falling
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
	CFG_ENEMY_COUNT:		equ 8

; Logical sprite sizes (bounding box size) (pixels)
	CFG_ENEMY_WIDTH:		equ 8
	CFG_ENEMY_HEIGHT:		equ 16

; Enemies animation delay (frames)
	CFG_ENEMY_ANIMATION_DELAY:	equ 8	
	
; Define as $0000 the unused MSXlib user extension (UX)
	; ON_ENEMY_COLLISION_UX
	; ON_BULLET_COLLISION_UX

; Enemies related routines
	include	"lib/game/enemy.asm"
; (optional) Default handlers and behavior
	include	"lib/game/enemy_handlers.asm"
	include	"lib/game/enemy_routines.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Spriteables routines (2x2 chars that eventually become a sprite)

; Maximum simultaneous number of spriteables
	CFG_MAX_SPRITEABLES:	equ 16

; (optional) Spriteables routines
	include	"lib/extra/spriteables.asm"
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
	; call	DISSCR_FADE_OUT
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
	
; Initializes stage vars
	ld	hl, STAGE_VARS_0
	ld	de, stage_vars
	ld	bc, STAGE_VARS_SIZE
	ldir

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
	
; In-game loop preamble and initialization
	call	RESET_DYNAMIC_SPRITES
	call	RESET_ENEMIES
	call	RESET_VPOKES
	call	RESET_SPRITEABLES
	
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
	call	EXECUTE_VPOKES
	call	LDIRVM_SPRATR
; Prepares next frame (2/2)
	call	RESET_DYNAMIC_SPRITES
	
; Read input devices
	call	GET_STICK_BITS
	call	GET_TRIGGER
	
; Game logic
	call	UPDATE_SPRITEABLES
	call	UPDATE_BOXES_AND_ROCKS	; (custom)
	call	UPDATE_PLAYER
	call	UPDATE_ENEMIES
	; ; call	UPDATE_BULLETS		; específica
	; ; call	CHECK_COLLISIONS_ENEMIES
	
	call	UPDATE_FRAMES_PUSHING	; (custom)
	
; Check exit condition
	ld	a, [player_state]
	bit	BIT_STATE_FINISH, a
	jr	z, GAME_LOOP ; no
; yes: conditionally jump according the exit status
	cp	PLAYER_STATE_DEAD
	jr	z, GAME_LOOP_DEAD ; player is dead
	cp	PLAYER_STATE_FINISH
	jr	z, GAME_LOOP_FINISH ; stage finished ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due stage over
GAME_LOOP_FINISH:
; Fade out
	call	DISSCR_FADE_OUT		; shared/helper/vram

; Next stage logic
	;	...
	
; Next screen
	jp	NEW_STAGE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop finish due death of the player
GAME_LOOP_DEAD:
; Fade out
	call	DISSCR_FADE_OUT		; shared/helper/vram

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
	call	ENASCR_FADE_IN		; shared/helper/vram

; Game over loop
.LOOP:
	halt
	;	...
	; jr	.LOOP
	
; Fade out
	call	DISSCR_FADE_OUT		; shared/helper/vram
	
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
	ld	hl, namtbl_buffer +PLAYGROUND_FIRST_ROW *SCR_WIDTH
	ld	bc, ((PLAYGROUND_LAST_ROW -PLAYGROUND_FIRST_ROW +1) *SCR_WIDTH)
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
	ld	[ix + _SPRITEABLE_SPRATR +0], BOX_SPRITE_PATTERN ; patrón caja
	ld	[ix + _SPRITEABLE_SPRATR +1], BOX_SPRITE_COLOR ; color caja
	ret

; Inicializa el tile sprite de una roca
.INIT_ROCK:
	call	INIT_SPRITEABLE
	ld	[ix + _SPRITEABLE_SPRATR +0], ROCK_SPRITE_PATTERN ; patrón roca
	ld	[ix + _SPRITEABLE_SPRATR +1], ROCK_SPRITE_COLOR ; color roca
	ret

; Initial player coordinates
.INIT_START_POINT:
	call	.CLEAR_CHAR_GET_LOGICAL_COORDS
	ld	hl, player_y
	ld	[hl], d
	inc	hl ; hl = player_x
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
	ld	a, [spriteables_count]
	or	a
	ret	z ; no
; sí
	ld	b, a ; b = contador
	ld	ix, spriteables_array
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
	ld	a, [ix +_SPRITEABLE_SPRATR]
	cp	BOX_SPRITE_PATTERN
	jr	z, .BOX_ON_WATER ; sí
	jr	.ROCK_ON_WATER ; no (es una roca)
.NO_WATER:

; ¿condiciones especiales (entrando en lava)?
	cp	CHAR_LAVA_SURFACE
	jr	nz, .NO_LAVA ; no
; sí: ¿es una caja?
	ld	a, [ix +_SPRITEABLE_SPRATR]
	cp	BOX_SPRITE_PATTERN
	jr	z, .BOX_ON_LAVA ; sí
	jr	.ROCK_ON_LAVA ; no (es una roca)
.NO_LAVA:

.CHECK:
; Lee el caracter bajo la parte izquierda del spriteable
	ld	hl, namtbl_buffer +SCR_WIDTH *2 ; (+2,+0)
	ld	e, [ix +_SPRITEABLE_OFFSET +0]
	ld	d, [ix +_SPRITEABLE_OFFSET +1]
	add	hl, de
	push	hl ; preserva el puntero al buffer namtbl
	ld	a, [hl]
	call	GET_TILE_PROPERTIES
	ld	c, a ; preserva el valor
; Lee el caracter bajo la parte derecha del spriteable
	pop	hl ; restaura puntero al buffer namtbl
	inc	hl
	ld	a, [hl]
	call	GET_TILE_PROPERTIES
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
	call	SET_SPRITEABLE_FOREGROUND
	call	VPOKE_SPRITEABLE_FOREGROUND
	jr	.STOP_BOX
.BOX_ON_LAVA:
; Elimina los caracteres de la caja y recupera el fondo inmediatamente
	call	NAMTBL_BUFFER_ERASE
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
	call	SET_SPRITEABLE_FOREGROUND
; Cambia el color del sprite
	ld	a, ROCK_SPRITE_COLOR_WATER
	ld	[ix + _SPRITEABLE_SPRATR +1], a
; continúa procesando la caída
	jr	.CHECK
	
.ROCK_ON_LAVA:
; Cambia los caracteres que se volcarán
	ld	a, ROCK_FIRST_CHAR_LAVA
	call	SET_SPRITEABLE_FOREGROUND
; Cambia el color del sprite
	ld	a, ROCK_SPRITE_COLOR_LAVA
	ld	[ix + _SPRITEABLE_SPRATR +1], a
; continúa procesando la caída
	jr	.CHECK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Resetea el contador de frames que lleva empujando el jugador
; si no está empujando
UPDATE_FRAMES_PUSHING:
; ¿Está empujando?
	ld	a, [player_state]
	and	$ff - FLAGS_STATE
	cp	PLAYER_STATE_PUSH
	ret	z ; sí
 ; no: resetea el contador
	xor	a
	ld	[frames_pushing], a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	MSXlib user extensions (UX)
; =============================================================================
;

; -----------------------------------------------------------------------------
; UX colisión, un tile (coordenadas concretas)
UPDATE_PLAYER_UX_WALK_ON:
; obtiene el tile, el offset y el puntero al buffer
	call	GET_TILE_AT_PLAYER
	push	de ; preserva el offset
	push	hl ; preserva el puntero
	
; ¿es un item?
	; cp	CHAR_FIRST_OPEN_DOOR
	; jr	nc, .DOOR ; no
; sí: realiza la acción que corresponda al item
	sub	CHAR_FIRST_ITEM
	ld	hl, .ITEM_JUMP_TABLE
	call	JP_TABLE
; elimina el item en el buffer y en la VRAM
	xor	a
	pop	hl ; restaura el puntero
	ld	[hl], a
	pop	hl ; restaura el offset
	jp	VPOKE

.ITEM_JUMP_TABLE:
	dw	PLAYER_GETS_KEY		; llave
	dw	PLAYER_GETS_STAR	; estrella
	dw	PLAYER_GETS_BONUS	; moneda
	dw	PLAYER_GETS_BONUS	; cereza
	dw	PLAYER_GETS_BONUS	; fresa
	dw	PLAYER_GETS_BONUS	; manzana
	dw	PLAYER_GETS_BONUS	; octopus

; .DOOR:	
	; pop	hl ; restaura el puntero
	; pop	hl ; restaura el offset
; ; sí: ¿cursor arriba?
	; ld	hl, stick
	; bit	BIT_STICK_UP, [hl]
	; ret	z ; no
; ; sí: cambia el estado para que el juego finalice
	; ld	a, PLAYER_STATE_FINISH
	; jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
PLAYER_GETS_KEY:
; Recorre todo el buffer de namtbl
	ld	hl, namtbl_buffer + PLAYGROUND_FIRST_ROW * SCR_WIDTH
	ld	bc, ((PLAYGROUND_LAST_ROW - PLAYGROUND_FIRST_ROW + 1) * SCR_WIDTH)
.LOOP:
; ¿Es un caracter de puerta cerrada?
	ld	a, [hl]
	cp	CHAR_FIRST_CLOSED_DOOR
	jr	c, .NEXT ; no
	cp	CHAR_LAST_CLOSED_DOOR + 1
	jr	nc, .NEXT ; no
; sí: lo convierte en caracter de puerta abierta
	push	bc ; preserva contador
	push	hl ; preserva puntero 
	add	CHAR_FIRST_OPEN_DOOR - CHAR_FIRST_CLOSED_DOOR
	ld	[hl], a
	ld	de, -namtbl_buffer + $10000
	add	hl, de ; hl = offset
	call	VPOKE
	pop	hl ; restaura puntero
	pop	bc ; restaura contador
.NEXT:
; Busca el siguiente elemento
	cpi	; inc hl, dec bc
	ret	po
	jr	.LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
PLAYER_GETS_STAR:
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
PLAYER_GETS_BONUS:
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; UX empujando tiles
UPDATE_PLAYER_UX_PUSH_RIGHT:
; lee el tile bajo que se está empujando
	ld	a, PLAYER_BOX_X_OFFSET + CFG_PLAYER_WIDTH ; x += offset + width
	call	PUSH_GET_PUSHED_TILE
; ¿es la parte baja izquierda?
	and	3 ; (porque están alienados a $?0 y $?4)
	cp	2
	ret	nz ; no
; sí: cambia el estado
	ld	a, PLAYER_STATE_PUSH
	ld	[player_state], a
; ¿hay hueco para empujar?
	ld	a, PLAYER_BOX_X_OFFSET + CFG_PLAYER_WIDTH +16
	call	CHECK_V_TILES_PLAYER
	bit	BIT_WORLD_SOLID, a
	ret	nz ; no
; sí: ¿ha empujado suficiente?
	call	CHECK_FRAMES_PUSHING
	ret	nz ; no
; sí: localiza el elemento empujable e inicia su movimiento
	ld	a, ((CFG_PLAYER_WIDTH +16) /2)
	call	PUSH_LOCATE_PUSHABLE
	jp	MOVE_SPRITEABLE_RIGHT
	
UPDATE_PLAYER_UX_PUSH_LEFT:
; lee el tile bajo que se está empujando
	ld	a, PLAYER_BOX_X_OFFSET -1 ; x += offset -1
	call	PUSH_GET_PUSHED_TILE
; ¿es la parte baja derecha?
	and	3 ; (porque están alienados a $?0 y $?4)
	cp	3
	ret	nz ; no
; sí: cambia el estado
	ld	a, PLAYER_STATE_PUSH OR FLAG_STATE_LEFT
	ld	[player_state], a
; ¿hay hueco para empujar?
	ld	a, PLAYER_BOX_X_OFFSET -1 -16
	call	CHECK_V_TILES_PLAYER
	bit	BIT_WORLD_SOLID, a
	ret	nz ; no
; sí: ¿ha empujado suficiente?
	call	CHECK_FRAMES_PUSHING
	ret	nz ; no
; sí: localiza el elemento empujable e inicia su movimiento
	ld	a, -(CFG_PLAYER_WIDTH/2) -8 +$100 ; +$100 evita 8-bit overflow
	call	PUSH_LOCATE_PUSHABLE
	jp	MOVE_SPRITEABLE_LEFT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Lee el tile (parte baja) que se está empujando
; param a: dx
PUSH_GET_PUSHED_TILE:
	ld	de, [player_xy]
	add	d ; x += dx
	ld	d, a
	dec	e ; y -= 1
	jp	GET_TILE_AT_XY
	
; Actualiza y comprueba el contador de frames que lleva empujando el jugador
; ret nz: insuficientes
; ret z: suficientes
CHECK_FRAMES_PUSHING:
	ld	hl, frames_pushing
	inc	[hl]
	ld	a, [hl]
	cp	FRAMES_TO_PUSH
	ret
	
; Localiza el elemento que se está empujando y lo activa
; param a: dx
; return ix: puntero al tile convertible
PUSH_LOCATE_PUSHABLE:
; Calcula las coordenadas que tiene que buscar
	ld	de, [player_xy]
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

; Sprite-related data (SPRATR)
PLAYER_SPRATR_0:
	db	SPAT_OB, 0, 0, 9	; 1st player sprite
	db	SPAT_OB, 0, 0, 15	; 2nd player sprite
	db	SPAT_END		; SPAT end marker
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
NAMTBL_PACKED:
	incbin	"games/stevedore/screen.tmx.bin.zx7"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial value of the globals, game and stage vars, and player vars
GLOBALS_0:
	dw	2500			; hi_score

GAME_VARS_0:
	db	5			; lives_left
	dw	0			; score

STAGE_VARS_0:
	db	0			; frames_pushing
	
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

hi_score:
	rw	1
	
	GLOBALS_SIZE:	equ $ - globals

; Game vars (i.e.: vars from start to game over)
game_vars:

lives_left:
	rb	1
score:
	rw	1
	
	GAME_VARS_SIZE:	equ $ - game_vars

; Stage vars (i.e.: vars inside the main game loop)
stage_vars:

; Number of consecutive frames the player has been pushing an object
frames_pushing:
	rb	1
	
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
