
; =============================================================================
; 	MSX cartridge (ROM) header, entry point and initialization
; -----------------------------------------------------------------------------
; Enable if the ROM is larger than 16kB (typically, 32kB)
; Includes search for page 2 slot/subslot at start
	CFG_INIT_32KB_ROM	equ 0

; Enable if the game needs 16kB instead of 8kB
; RAM will start at the beginning of the page 2 instead of $e000
; and availability will be checked at start
	CFG_INIT_16KB_RAM	equ 0

; MSX cartridge (ROM) header, entry point and initialization
	.include	"lib/msx_cartridge.asm"
; =============================================================================


; =============================================================================
;	Input routines (BIOS-based)
; -----------------------------------------------------------------------------
; Tabla de valores de cursores o joystick en forma de mapa de bits
STICK_BITS_TABLE:
	.db	0						 ; 0
	.db	(1 << BIT_STICK_UP)				 ; 1
	.db	(1 << BIT_STICK_UP)	| (1 << BIT_STICK_RIGHT) ; 2
	.db				  (1 << BIT_STICK_RIGHT) ; 3
	.db	(1 << BIT_STICK_DOWN)	| (1 << BIT_STICK_RIGHT) ; 4
	.db	(1 << BIT_STICK_DOWN)				 ; 5
	.db	(1 << BIT_STICK_DOWN)	| (1 << BIT_STICK_LEFT)	 ; 6
	.db				  (1 << BIT_STICK_LEFT)	 ; 7
	.db	(1 << BIT_STICK_UP)	| (1 << BIT_STICK_LEFT)	 ; 8

; Input routines (BIOS-based)
	.include	"lib/msx_input.asm"
; =============================================================================


; =============================================================================
;	Generic sprite routines
; -----------------------------------------------------------------------------
; Offset de las coordenadas físicas del sprite respecto a las coordenadas lógicas
	CFG_SPRITES_X_OFFSET	equ -8
	CFG_SPRITES_Y_OFFSET	equ -16 -1
	
; Number of fixed sprites reserved at the beginning of the table
	CFG_SPRITES_RESERVED_BEFORE	equ 0

; Number of fixed sprites reserved after the player sprites
	CFG_SPRITES_RESERVED_AFTER	equ 0

; Generic sprite routines
	.include	"lib/msx_sprites.asm"
; =============================================================================


; =============================================================================
;	VRAM buffers routines (NAMTBL and SPRATR)
; -----------------------------------------------------------------------------
	.include	"lib/msx_vram.asm"
; =============================================================================

	
; =============================================================================
; 	Generic Z80 assembly convenience routines
; -----------------------------------------------------------------------------
	.include	"lib/asm.asm"
; =============================================================================

;
; =============================================================================
; 	Game
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bits de las diferentes propiedades de los tiles
	BIT_WORLD_SOLID		equ 0
	BIT_WORLD_FLOOR		equ 1
	BIT_WORLD_STAIRS	equ 2
	BIT_WORLD_DEATH		equ 3
; Bits de extensiones del usuario (UX), detectados en...
	BIT_WORLD_UX_WALK_ON	equ 0 ; 4 ; ...colisión, un tile (coordenadas concretas)
	BIT_WORLD_UX_WIDE_ON	equ 0 ; 5 ; ...colisión, tiles (ancho del jugador)
	BIT_WORLD_UX_WALK_OVER	equ 0 ; 6 ; ...jugador sobre tiles (ancho del jugador)
	BIT_WORLD_UX_PUSH	equ 0 ; 7 ; ...empujando tiles (alto del jugador)

TILE_PROPERTIES_TABLE:
	.db	$7f, $00 ; [$00..$07] : 0
	.db	$81, $00 ; [$80..$81] : 0
	.db	$8f, $03 ; [$82..$8f] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID
	.db	$91, $00 ; [$90..$91] : 0
	.db	$9f, $03 ; [$92..$9f] : BIT_WORLD_FLOOR | BIT_WORLD_SOLID
	.db	$ff, $00 ; [$ac..$af] : 0

; Caracteres que se devolverán al consultar offscreen
	CFG_TILES_OFFSCREEN_TOP		equ $01 ; BIT_WORLD_SOLID
	CFG_TILES_OFFSCREEN_BOTTOM	equ $08 ; BIT_WORLD_DEATH
	
	.include	"lib/game/tiles.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Logical sprite sizes (bounding box size) (pixels)
	CFG_PLAYER_WIDTH	equ 8
	CFG_PLAYER_HEIGHT	equ 16

; Number of player sprites (i.e.: number of colors)
	CFG_PLAYER_SPRITES	equ 2

; Player and enemies animation delay (frames)
	CFG_PLAYER_ANIMATION_DELAY	equ 6

; Estados del jugador por defecto
	; PLAYER_STATE_FLOOR	equ (0 << 2) ; $00
	; PLAYER_STATE_STAIRS	equ (1 << 2) ; $04
	; PLAYER_STATE_AIR	equ (2 << 2) ; $08
	; PLAYER_STATE_DYING	equ (3 << 2) ; $0c
; Estados del jugador definidos por el usuario
	;	...

; Tabla de mapeo de estado a patrones de sprites
STATUS_SPRATR_TABLE:
	;	0	LEFT	ANIM	LEFT|ANIM
; Estados del jugador por defecto
	.db	$00,	$10,	$08,	$18	; PLAYER_STATE_FLOOR
	.db	$20,	$20,	$28,	$28	; PLAYER_STATE_STAIRS
	.db	$08,	$18,	$08,	$18	; PLAYER_STATE_AIR
	.db	$30,	$30,	$38,	$38	; PLAYER_STATE_DYING
; Estados del jugador definidos por el usuario
	;	...

; Tabla de mapeo de estado del jugador a rutinas (0-based)
UPDATE_PLAYER_TABLE:
; Estados del jugador por defecto
	.dw	UPDATE_PLAYER_FLOOR	; PLAYER_STATE_FLOOR
	.dw	UPDATE_PLAYER_STAIRS	; PLAYER_STATE_STAIRS
	.dw	UPDATE_PLAYER_AIR	; PLAYER_STATE_AIR
	.dw	UPDATE_PLAYER_DYING	; PLAYER_STATE_DYING
; Estados del jugador definidos por el usuario
	;	...

; Declaraciones nulas de extensiones del usuario (UX) no utilizadas
	UPDATE_PLAYER_UX_WALK_ON	equ $0000
	UPDATE_PLAYER_UX_WIDE_ON	equ $0000
	UPDATE_PLAYER_UX_WALK_OVER	equ $0000
	UPDATE_PLAYER_UX_PUSH_RIGHT	equ $0000
	UPDATE_PLAYER_UX_PUSH_LEFT	equ $0000

; Terminal falling velocity (pixels/frame)
	CFG_PLAYER_GRAVITY		equ 4

; Tabla de dY para los saltos y la caída
JUMP_DY_TABLE:
	.db	-4, -4			; (2,-8)
	.db	-2, -2, -2		; (5,-14)
	.db	-1, -1, -1, -1, -1, -1	; (11,-20)
	.db	 0,  0,  0,  0,  0,  0	; (17,-20)
	JUMP_DY_TABLE_FALL_OFFSET	equ $ - JUMP_DY_TABLE
	.db	1, 1, 1, 1, 1, 1	; (23,-14) / (6,6)
	.db	2, 2, 2			; (26,-8) / (9,12)
	.db	CFG_PLAYER_GRAVITY	; velocidad terminal
	JUMP_DY_TABLE_SIZE		equ $ - JUMP_DY_TABLE
	
	.include	"lib/game/player.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Maximum simultaneous number of enemies
	CFG_ENEMY_COUNT		equ 4

; Logical sprite sizes (bounding box size) (pixels)
	CFG_ENEMY_WIDTH		equ 8
	CFG_ENEMY_HEIGHT	equ 16

; Player and enemies animation delay (frames)
	CFG_ENEMY_ANIMATION_DELAY	equ 8	
	
; Declaraciones nulas de extensiones del usuario (UX) no utilizadas
	ON_ENEMY_COLLISION_UX	equ $0000
	ON_BULLET_COLLISION_UX	equ $0000

	.include	"lib/game/enemy.asm"
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	ROM: optional MSXlib configuration and includes
; =============================================================================
;
	
; -----------------------------------------------------------------------------
	.include	"lib/game/enemy/default_routines.asm"
	.include	"lib/game/enemy/default_handlers.asm"
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Hook-installed PT3 replayer
	; CFG_OPTIONAL_PT3HOOK equ 0
	; .include	"lib/optional/pt3hook.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
	; .include	"lib/optional/spriteables.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
msxlib_end:
	.printtext	" ... msxlib code"
	.printhex	$
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	ROM: custom routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Custom symbolic constants

; Configuración específica el juego
	PLAYGROUND_FIRST_ROW	equ 0  ; Define el tamaño del área de juego a procesar
	PLAYGROUND_LAST_ROW	equ 23
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
MAIN:
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
@@LOOP:
	halt
	;	...TBD...
	; jr	@@LOOP
	
; Fade out
	call	DISSCR_FADE_OUT
; ------VVVV----falls through--------------------------------------------------
	
; -----------------------------------------------------------------------------
; New game entry point
NEW_GAME:
; Game vars initialization
	;	...TBD...
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; New stage / new life entry point
NEW_STAGE:
; Name table memory buffer
	ld	hl, NAMTBL_PACKED
	ld	de, namtbl_buffer
	call	UNPACK
	
; Sprite attribute table (SPRATR)
	ld	hl, SPRATR_0
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir
	
; ; Game vars
	; ld	hl, PLAYER_VARS_0
	; ld	de, player_vars
	; ld	bc, PLAYER_VARS_SIZE
	; ldir
	
; Game specific initialization
	call	RESET_DYNAMIC_SPRITES
	call	RESET_ENEMIES
	
	call	INIT_STAGE		; específica
	
; Fade in
	call	ENASCR_FADE_IN
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop
GAME_LOOP:
; Blit buffers to VRAM
	call	PUT_SPRITE_PLAYER
	halt
	call	LDIRVM_SPRATR
; Prepare buffers for the next frames
	call	RESET_DYNAMIC_SPRITES
	
; Read input devices
	call	GET_STICK_BITS
	call	GET_TRIGGER
	
; Game logic
	call	UPDATE_PLAYER
	call	UPDATE_ENEMIES
	; call	CHECK_COLLISIONS_ENEMIES
	
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
@@LOOP:
	halt
	;	...
	; jr	@@LOOP
	
; Fade out
	call	DISSCR_FADE_OUT
	
	jp	MAIN_MENU
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	Rutinas específicas
; =============================================================================
;

; -----------------------------------------------------------------------------
; Initializes the initial player coordinates, enemies and other special elements
INIT_STAGE:
; Travels the playable area
	ld	hl, namtbl_buffer +PLAYGROUND_FIRST_ROW *SCR_WIDTH
	ld	bc, (PLAYGROUND_LAST_ROW -PLAYGROUND_FIRST_ROW +1) *SCR_WIDTH
@@LOOP:
; For each character
	push	bc ; preserves counter
	push	hl ; preserves pointer
	ld	a, [hl]
	call	@@INIT_ELEMENT
; Next element
	pop	hl ; restores pointer
	pop	bc ; restores counter
	cpi	; inc hl, dec bc
	ret	po
	jr	@@LOOP
	
@@INIT_ELEMENT:
; 0 = Initial player coordinates
	cp	'0'
	jr	z, @@INIT_START_POINT
	ret

; Initial player coordinates
@@INIT_START_POINT:
	call	CLEAR_CHAR_GET_LOGICAL_COORDS
	ld	hl, player_y
	ld	[hl], d
	inc	hl ; hl = player_x
	ld	[hl], e
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Rutina de conveniencia que elimina el caracter de control
; y devuelve las coordenadas lógicas para ubicar ahí un sprite
; param hl: puntero del buffer namtbl del caracter de control
; ret de: coordenadas lógicas del sprite
CLEAR_CHAR_GET_LOGICAL_COORDS:
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
; 	ROM: main MSXlib data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Binary data
CHARSET_CHR_PACKED:
	.incbin		"games/example/charset.pcx.chr.plet5"
CHARSET_CLR_PACKED:
	.incbin		"games/example/charset.pcx.clr.plet5"
SPRTBL_PACKED:
	.incbin		"games/example/sprites.pcx.spr.plet5"
NAMTBL_PACKED:
	.incbin		"games/example/screen.tmx.bin.plet5"
; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; PLAYER_VARS_0:
	; .db	0, 0, 0, PLAYER_STATE_FLOOR, 0
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; STAGE_VARS_0:
	; .db	0 ; stage_state
	; .db	0 ; frames_pushing
; ; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
SPRATR_0:
; jugador
	.db	SPAT_OB, 0, 0, 9
	.db	SPAT_OB, 0, 0, 15
; spat end
	.db	SPAT_END
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	RAM
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSXlib vars
	.include	"lib/ram_begin.asm"
; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Variables durante el bucle principal del juego
; stage_vars:
	; STAGE_VARS_SIZE	equ $ - stage_vars
; ; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpack buffer will be at RAM end
; (declare this value to check it actually fits before system variables)
	CFG_RAM_RESERVE_BUFFER	equ 2048
	
; MSXlib end marker
	.include	"lib/ram_end.asm"
; -----------------------------------------------------------------------------

; EOF
