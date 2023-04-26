
;
; =============================================================================
;	RUN'23 minigame
; =============================================================================
;

; -----------------------------------------------------------------------------
; 16KB ROM
	CFG_INIT_ROM_SIZE:	equ 8

; Automatically reads the keyboard
	CFG_HOOK_ENABLE_AUTO_KEYBOARD:

; Faster LDIRVM_NAMTBL routine
	CFG_LDIRVM_NAMTBL_FAST:

; MSXlib helper: default configuration
	include	"lib/rom-default.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Palette routines for MSX2 VDP
	include "lib/msx/etc/msx2_palette.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Replayer routines

; Define to enable packed songs when using the PT3-based implementation
	CFG_PT3_PACKED:

; Define to use headerless PT3 files (without first 100 bytes)
	CFG_PT3_HEADERLESS:

; PT3-based implementation
	include	"lib/msx/io/replayer_pt3.asm"

; ayFX REPLAYER v1.31
	include	"libext/ayFX-replayer/ayFX-ROM.tniasm.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Random routines
	include "lib/etc/random.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
	NO_LIVES:		equ $80

	CFG_TIMER_WAIT:		equ 9
	CFG_TIMER_PUSH:		equ 5

	BIT_INPUT:		equ 0
	BIT_FORWARD:		equ 1
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
INIT:

; Besides the minimal initialization, the MSXlib hook has been installed
; And VRAM buffer, text, and logical coordinates sprites routines are available
; as well as input, timing & pause routines

	call	INIT_CHARSET_SPRITES_SCREEN

.MAIN_LOOP:

	call	INIT_NEW_GAME

; Wait for players to join
	call	INIT_WAIT_FOR_PLAYERS
	call	WAIT_FOR_PLAYERS_LOOP

; Resets the timer
	call	RESET_TIMER
; Clears messages
	ld	hl, REMOVE_CURRENT_PLAYER_MESSAGE
	call	FOR_EVERY_PLAYER_DO

; Checks the number of players
	ld	a, [number_of_players]
	cp	1
	jr	z, .RESTART ; (only one player)

; Initialization of the first round
	call	INIT_FIRST_ROUND

.INGAME_LOOP:

; (ensures the weight is over a live player)
	call	MOVE_WEIGHT_LOOP

; "READY?" messages
	call	INIT_ROUND
	call	TWO_SECONDS_IDLE_LOOP

; Wait for player inputs
	call	INIT_WAIT_FOR_PLAYERS_INPUT
	call	WAIT_FOR_PLAYERS_INPUT_LOOP

; Resets the timer
	call	RESET_TIMER
; Clears messages
	ld	hl, REMOVE_CURRENT_PLAYER_MESSAGE
	call	FOR_EVERY_PLAYER_DO

; Reveals the player inputs
	call	INIT_REVEAL_PLAYERS_INPUT
	call	REVEAL_PLAYERS_INPUT_LOOP
	call	INIT_WEIGHT_MOVEMENT
	call	ONE_SECOND_IDLE_LOOP
	call	HIDE_PLAYERS_INPUT_LOOP
; Applies the player inputs
	call	WEIGHT_MOVEMENT_LOOP

; Resets the timer
	call	RESET_TIMER

; Drops the weight
	call	INIT_WEIGHT_DROP
	call	WEIGHT_DROP_LOOP
	call	INIT_WEIGHT_RAISE
	call	WEIGHT_RAISE_LOOP
	call	DONE_WEIGHT_RAISE

; Checks the number of players
	ld	a, [number_of_players]
	cp	1
	jr	nz, .INGAME_LOOP

; Victory
	call	INIT_VICTORY_SEQUENCE
	call	VICTORY_SEQUENCE_LOOP
	call	DONE_VICTORY_SEQUENCE

.RESTART:

; Restarts
 	call	DISSCR_FADE_OUT
 	jp	.MAIN_LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_CHARSET_SPRITES_SCREEN:

; Initializes charset
	ld	hl, CHRTBL_PACKED
	call	UNPACK_LDIRVM_CHRTBL
	ld	hl, CLRTBL_PACKED
	call	UNPACK_LDIRVM_CLRTBL

; Initializes sprite patterns
	ld	hl, SPRTBL_PACKED
	ld	de, SPRTBL
	ld	bc, SPRTBL_SIZE
	call	UNPACK_LDIRVM

; Initializes screen
	ld	hl, NAMTBL_PACKED
	ld	de, namtbl_buffer
	jp	UNPACK

CHRTBL_PACKED:
	incbin	"games/minigames/run23/charset.png.chr.zx0"
CLRTBL_PACKED:
	incbin	"games/minigames/run23/charset.png.clr.zx0"
SPRTBL_PACKED:
	incbin	"games/minigames/run23/sprites.png.spr.zx0"
NAMTBL_PACKED:
	incbin	"games/minigames/run23/screen.tmx.bin.zx0"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_NEW_GAME:

; No music
	ld	a, 2
	call	REPLAYER.PLAY

; Initializes players
	ld	a, NO_LIVES
	ld	[lives.player1], a
	ld	[lives.player2], a
	ld	[lives.player3], a
	ld	[lives.player4], a
	ld	hl, PRINT_CURRENT_PLAYER_LIVES
	call	FOR_EVERY_PLAYER_DO
; Resets the timer
	call	RESET_TIMER
; Shows the screen (without sprites)
	ld	hl, SPRATR
	ld	a, SPAT_END
	halt
	call	WRTVRM
	call	ENASCR_FADE_IN
; Initializes the sprite attributes
	ld	hl, SPRATR_DATA
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir
; Shows sprites
	halt
	jp	LDIRVM_SPRATR

SPRATR_DATA:
	db	  40 -1,   0,    $00,  0 ; upper mask
	db	  40 -1,   0,    $00,  0
	db	  40 -1,   0,    $00,  0
	db	  40 -1,   0,    $00,  0
	; +$10
	db	 112 -1,   0,    $00,  0 ; lower mask
	db	 112 -1,   0,    $00,  0
	db	 112 -1,   0,    $00,  0
	db	 112 -1,   0,    $00,  0
	; +$20
	db	SPAT_OB,   0,    $80, 14 ; weight
	db	SPAT_OB,   0,    $a8,  4 ; chain
	db	SPAT_OB,   0,    $a8,  4
	db	SPAT_OB,   0,    $a8,  4
	; +$30
	db	 112 -1,  32 -8, $00,  9 ; players and option indicators
	db	SPAT_OB,   0,    $ac, 15
	db	 112 -1,  96 -8, $04, 11
	db	SPAT_OB,   0,    $ac, 15
	db	 112 -1, 160 -8, $08,  3
	db	SPAT_OB,   0,    $ac, 15
	db	 112 -1, 224 -8, $0c,  7
	db	SPAT_OB,   0,    $ac, 15
	; +$50
	db	SPAT_OB,   0,    $a0, 11 ; stunned indicator
	db	SPAT_OB,   0,    $90, 10 ; victory indicator
	db	SPAT_END
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_WAIT_FOR_PLAYERS:

; Initializes players
	xor	a
	ld	[number_of_players], a
; Resets the timer
	call	RESET_TIMER
; "JOIN" messages
	ld	hl, .PRINT_JOIN
	jp	FOR_EVERY_PLAYER_DO

.PRINT_JOIN:
	ld	hl, .LITERAL_JOIN
	jp	PRINT_CURRENT_PLAYER_MESSAGE
.LITERAL_JOIN:
	db	" JOIN "
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
WAIT_FOR_PLAYERS_LOOP:
	halt
	call	LDIRVM_SPRATR
	call	LDIRVM_NAMTBL

; Updates the timer
	call	UPDATE_TIMER
; Updates the player sprites
	ld	hl, .UPDATE_PLAYER_SPRITE_WAIT
	call	FOR_EVERY_PLAYER_DO

; Checks for players joining
	call	SET_FIRST_PLAYER
	ld	hl, NEWKEY + 6 ; F3 F2 F1 CODE CAP GRAPH CTRL SHIFT
	ld	c, $60 ; (F2 F1)
	call	.CHECK_JOIN_PLAYER

	call	SET_NEXT_PLAYER
	ld	hl, NEWKEY + 5 ; Z Y X W V U T S
	ld	c, $a0 ; (Z X)
	call	.CHECK_JOIN_PLAYER

	call	SET_NEXT_PLAYER
	ld	hl, NEWKEY + 4 ; R Q P O N M L K
	ld	c, $0c ; (N M)
	call	.CHECK_JOIN_PLAYER

	call	SET_NEXT_PLAYER
	ld	hl, NEWKEY + 8 ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
	ld	c, $0c ; (DEL INS)
	call	.CHECK_JOIN_PLAYER

; Checks for exit conditions
	ld	a, [number_of_players]
	cp	4
	ret	z ; (4 players)
	call	CHECK_TIMER
	ret	z ; (timer exhausted)

	jr	WAIT_FOR_PLAYERS_LOOP

.UPDATE_PLAYER_SPRITE_WAIT:
; Shows the player sprite
	call	MOVE_PLAYER_UP
; Checks if the player has already joined
	call	GET_CURRENT_PLAYER_LIVES
	cp	NO_LIVES
	jp	nz, ANIMATE_PLAYER ; yes
; no: Randomizes the sprite
	ld	a, [JIFFY]
	and	$07
	ret	nz ; no
	call	GET_RANDOM
	and	$3c
	call	GET_CURRENT_PLAYER_SPRATR
	inc	de
	inc	de
	ld	[de], a
	ret

.CHECK_JOIN_PLAYER:
; Checks any of the keys
	ld	a, [hl]
	and	c
	ret	z ; no
; yes: Checks if the player has already joined
	call	IS_CURRENT_PLAYER_ALIVE
	ret	nz ; yes
; no: Joins the player
	call	GET_CURRENT_PLAYER_LIVES
	ld	[hl], 2 ; (2 lives)
	ld	hl, number_of_players
	inc	[hl]
; Starts the music (with the first player)
	ld	a, [hl]
	dec	a ; cp 1 / ld a, 0
	call	z, REPLAYER.PLAY
; Starts the timer
	ld	b, CFG_TIMER_WAIT
	call	INIT_TIMER
; Print lives
	call	PRINT_CURRENT_PLAYER_LIVES
; "WAIT" Message
	ld	hl, .LITERAL_WAIT
	call	PRINT_CURRENT_PLAYER_MESSAGE
; Joined sound
	ld	a, CFG_SOUND_JOIN
	ld	c, 0
	jp	ayFX_INIT
.LITERAL_WAIT:
	db	" WAIT "
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_FIRST_ROUND:
; No music
	ld	a, 2
	call	REPLAYER.PLAY
; Randomizes weight sprite
	call	GET_RANDOM
	and	$06
	ld	hl, .WEIGHT_SPRITES_TABLE
	call	ADD_HL_A
	ld	de, spratr_buffer +$20 +2
	ldi
	ldi
; Randomizes weight position
	xor	a
	ld	[weight.current_x], a
	jp	SET_WEIGHT_POSITION_RANDOM

.WEIGHT_SPRITES_TABLE:
	db	$80, 14
	db	$84,  4
	db	$88, 14
	db	$8c,  6
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
MOVE_WEIGHT_LOOP:
	halt
	call	LDIRVM_SPRATR
	call	LDIRVM_NAMTBL

; Updates the weight sprite
	call	RESET_WEIGHT_Y
	call	UPDATE_WEIGHT_X
; Updates the player sprites
	ld	hl, ANIMATE_PLAYER
	call	FOR_EVERY_PLAYER_DO

; Checks for exit conditions
	ld	hl, weight.target_x
	ld	a, [hl]
	inc	hl ; weight.current_x
	cp	[hl]
	ret	z

	jr	MOVE_WEIGHT_LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_ROUND:
; "READY?" messages
	ld	hl, .PRINT_READY
	jp	FOR_EVERY_PLAYER_DO

.PRINT_READY:
	call	IS_CURRENT_PLAYER_ALIVE
	ret	z
	ld	hl, .LITERAL_READY
	jp	PRINT_CURRENT_PLAYER_MESSAGE
.LITERAL_READY:
	db	"READY?"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
TWO_SECONDS_IDLE_LOOP:
	call	ONE_SECOND_IDLE_LOOP
	; jp	ONE_SECOND_IDLE_LOOP ; (falls through)
ONE_SECOND_IDLE_LOOP:
	ld	a, [frame_rate]
	ld	b, a
IDLE_LOOP:
	push	bc ; (preserves counter)

	halt
	call	LDIRVM_SPRATR
	call	LDIRVM_NAMTBL

; Updates the player sprites
	ld	hl, ANIMATE_PLAYER
	call	FOR_EVERY_PLAYER_DO

	pop	bc ; (restores counter)
	djnz	IDLE_LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_WAIT_FOR_PLAYERS_INPUT:
; Starts the music
	xor	a
	call	REPLAYER.PLAY
; Resets player inputs
	xor	a
	ld	[inputs.player1], a
	ld	[inputs.player2], a
	ld	[inputs.player3], a
	ld	[inputs.player4], a
; Resets the timer
	ld	b, CFG_TIMER_PUSH
	call	INIT_TIMER.FORCE
; "PUSH" messages
	ld	hl, .PRINT_PUSH
	jp	FOR_EVERY_PLAYER_DO

.PRINT_PUSH:
	call	IS_CURRENT_PLAYER_ALIVE
	ret	z
	ld	hl, .LITERAL_PUSH
	jp	PRINT_CURRENT_PLAYER_MESSAGE
.LITERAL_PUSH:
	db	" PUSH "
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
WAIT_FOR_PLAYERS_INPUT_LOOP:
	halt
	call	LDIRVM_SPRATR
	call	LDIRVM_NAMTBL

; Updates the timer
	call	UPDATE_TIMER
; Updates the player sprites
	ld	hl, ANIMATE_PLAYER
	call	FOR_EVERY_PLAYER_DO

; Checks for players input
	call	SET_FIRST_PLAYER
	call	IS_CURRENT_PLAYER_ALIVE
	jr	z, .SKIP_PLAYER_1
	ld	hl, NEWKEY + 6 ; F3 F2 F1 CODE CAP GRAPH CTRL SHIFT
	ld	bc, $4060 ; (F2 -, F2 F1)
	call	.CHECK_PUSH_PLAYER
.SKIP_PLAYER_1:

	call	SET_NEXT_PLAYER
	call	IS_CURRENT_PLAYER_ALIVE
	jr	z, .SKIP_PLAYER_2
	ld	hl, NEWKEY + 5 ; Z Y X W V U T S
	ld	bc, $20a0 ; (- X, Z X)
	call	.CHECK_PUSH_PLAYER
.SKIP_PLAYER_2:

	call	SET_NEXT_PLAYER
	call	IS_CURRENT_PLAYER_ALIVE
	jr	z, .SKIP_PLAYER_3
	ld	hl, NEWKEY + 4 ; R Q P O N M L K
	ld	bc, $040c ; (- M, N M)
	call	.CHECK_PUSH_PLAYER
.SKIP_PLAYER_3:

	call	SET_NEXT_PLAYER
	call	IS_CURRENT_PLAYER_ALIVE
	jr	z, .SKIP_PLAYER_4
	ld	hl, NEWKEY + 8 ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
	ld	bc, $080c ; (- DEL, DEL INS)
	call	.CHECK_PUSH_PLAYER
.SKIP_PLAYER_4:

; Checks for exit conditions
	call	CHECK_TIMER
	ret	z ; (timer exhausted)

	jr	WAIT_FOR_PLAYERS_INPUT_LOOP

.CHECK_PUSH_PLAYER:
; Checks any key
	ld	a, [hl]
	and	c
	ret	z ; no
; yes: Checks forward key
	and	b
	jr	nz, .FORWARD ; yes
; no

.STAY:
	call	GET_CURRENT_PLAYER_INPUTS
	bit	0, a
	ret	nz ; (already pushed)
	ld	[hl], 1 << BIT_INPUT
	jr	.PRINT_OK

.FORWARD:
	call	GET_CURRENT_PLAYER_INPUTS
	bit	0, a
	ret	nz ; (already pushed)
	ld	[hl], 1 << BIT_INPUT + 1 << BIT_FORWARD
	; jr	.PRINT_OK ; (falls through)

.PRINT_OK:
; "OK" message
	ld	hl, .LITERAL_OK
	call	PRINT_CURRENT_PLAYER_MESSAGE
; Pushed sound
	ld	a, CFG_SOUND_PUSH
	ld	c, 0
	jp	ayFX_INIT

.LITERAL_OK:
	db	"  OK  "
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_REVEAL_PLAYERS_INPUT:
; No music
	ld	a, 2
	call	REPLAYER.PLAY
; Timeout sound
	ld	a, CFG_SOUND_TIMEOUT
	ld	c, 0
	call	ayFX_INIT
; Initializes the input indicators (Y)
	ld	a, 192 -1
	ld	[spratr_buffer +$34 +0], a
	ld	[spratr_buffer +$3c +0], a
	ld	[spratr_buffer +$44 +0], a
	ld	[spratr_buffer +$4c +0], a
; Initializes the input indicators (X)
	ld	hl, .INIT_PLAYER_INPUT
	jp	FOR_EVERY_PLAYER_DO

.INIT_PLAYER_INPUT:
	call	IS_CURRENT_PLAYER_ALIVE
	ret	z

	call	GET_CURRENT_PLAYER_SPRATR
	ld	a, $04 +1
	call	ADD_DE_A
	call	GET_CURRENT_PLAYER_INPUTS
	ld	b, [hl]
	ld	hl, .X_TABLE
	ld	a, [current_player]
	call	ADD_HL_2A
	bit	1, b
	jr	z, .HL_OK
	inc	hl
.HL_OK:
	ldi
	ret

.X_TABLE:
	db	 32 -20,  32 +12
	db	 96 -16,  96  +8
	db	160 -16, 160  +8
	db	224 -20, 224 +12
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
REVEAL_PLAYERS_INPUT_LOOP:
	ld	b, 16
.LOOP:
	push	bc ; (preserves counter)

	halt
	call	LDIRVM_SPRATR
	; call	LDIRVM_NAMTBL ; (unnecessary)

; Updates the player sprites
	ld	hl, ANIMATE_PLAYER
	call	FOR_EVERY_PLAYER_DO
; Updates the input indicators
	ld	hl, .REVEAL
	call	FOR_EVERY_PLAYER_DO

	pop	bc ; (restores counter)
	djnz	.LOOP
	ret

.REVEAL:
	call	IS_CURRENT_PLAYER_ALIVE
	ret	z

	call	GET_CURRENT_PLAYER_SPRATR
	inc	de
	inc	de
	inc	de
	inc	de
	ex	de, hl
	dec	[hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_WEIGHT_MOVEMENT:

; Counts player inputs forward
	ld	b, 0
	ld	hl, inputs.player1
	call	.COUNT_FORWARD
	inc	hl ; inputs.player2
	call	.COUNT_FORWARD
	inc	hl ; inputs.player3
	call	.COUNT_FORWARD
	inc	hl ; inputs.player4
	call	.COUNT_FORWARD
; Saves movement count
	ld	a, b
	ld	[weight.movements], a
; Prints movement count
	jp	PRINT_TIMER.A_OK

.COUNT_FORWARD:
	bit	BIT_FORWARD, [hl]
	ret	z
	inc	b
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
HIDE_PLAYERS_INPUT_LOOP:
	ld	b, 16
.LOOP:
	push	bc ; (preserves counter)

	halt
	call	LDIRVM_SPRATR
	; call	LDIRVM_NAMTBL ; (unnecessary)

; Updates the player sprites
	ld	hl, ANIMATE_PLAYER
	call	FOR_EVERY_PLAYER_DO
; Updates the input indicators
	ld	hl, .HIDE
	call	FOR_EVERY_PLAYER_DO

	pop	bc ; (restores counter)
	djnz	.LOOP
	ret

.HIDE:
	call	IS_CURRENT_PLAYER_ALIVE
	ret	z

	call	GET_CURRENT_PLAYER_SPRATR
	inc	de
	inc	de
	inc	de
	inc	de
	ex	de, hl
	inc	[hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
WEIGHT_MOVEMENT_LOOP:
; Checks pending movements
	ld	a, [weight.movements]
	or	a
	ret	z ; no

; yes: Moves the weight
	ld	a, CFG_SOUND_WEIGHT_MOVE
	ld	c, 0
	call	ayFX_INIT
	call	SET_WEIGHT_POSITION_NEXT
	call	MOVE_WEIGHT_LOOP

; Consumes pending movement
	ld	hl, weight.movements
	dec	[hl]
; Prints movement count
	ld	a, [hl]
	call	PRINT_TIMER.A_OK

; Small pause
	ld	b, 10
	call	IDLE_LOOP

	jr	WEIGHT_MOVEMENT_LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_WEIGHT_DROP:
	ld	a, 1
	ld	[weight.speed], a
	jp	RESET_WEIGHT_Y
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
WEIGHT_DROP_LOOP:
	halt
	call	LDIRVM_SPRATR
	; call	LDIRVM_NAMTBL ; (unnecessary)

; Drops the weight
	ld	hl, weight.speed
	ld	a, [hl]
	cp	$10
	jr	z, .SPEED_OK
	inc	[hl]
.SPEED_OK:
	ld	hl, spratr_buffer +$20 +0
	add	[hl]
	call	SET_WEIGHT_Y

; Updates the player sprites
	ld	hl, ANIMATE_PLAYER
	call	FOR_EVERY_PLAYER_DO

; Checks for exit conditions
	ld	a, [spratr_buffer +$20 +0]
	cp	96 -1
	jr	c, WEIGHT_DROP_LOOP ; no
; yes
	ld	a, 96 -1
	call	SET_WEIGHT_Y
; Weight sound
	ld	a, CFG_SOUND_WEIGHT_FALL
	ld	c, 0
	jp	ayFX_INIT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_WEIGHT_RAISE:
	ld	a, [weight.target]
	ld	[current_player], a
; Hides the player sprite
	call	GET_CURRENT_PLAYER_SPRATR
	ld	a, 112 -1
	ld	[de], a
; Decreases player lives
	call	GET_CURRENT_PLAYER_LIVES
	dec	[hl]
	call	PRINT_CURRENT_PLAYER_LIVES
; Stunned?
	call	GET_CURRENT_PLAYER_LIVES
	or	a
	jr	z, .KILLED ; no
; yes: shows the stunned indicator
	ld	a, 76 -1
	ld	[spratr_buffer +$50 +0], a
	ld	a, [weight.target_x]
	sub	8
	ld	[spratr_buffer +$50 +1], a
	ret

.KILLED:
; The player is killed
	ld	hl, number_of_players
	dec	[hl]
; Re-adjusts the weight position
	jp	SET_WEIGHT_POSITION_NEXT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
WEIGHT_RAISE_LOOP:
	halt
	call	LDIRVM_SPRATR
	; call	LDIRVM_NAMTBL ; (unnecessary)

; Raises the weight
	ld	a, [spratr_buffer +$20 +0]
	dec	a
	call	SET_WEIGHT_Y

; Updates the player sprites
	ld	hl, ANIMATE_PLAYER
	call	FOR_EVERY_PLAYER_DO

; Updates the stunned indicator
	ld	a, [JIFFY]
	and	$07
	jr	nz, .SKIP_STUNNED
	ld	hl, spratr_buffer +$50 +2
	ld	a, [hl]
	xor	$04
	ld	[hl], a
.SKIP_STUNNED:

; Checks for exit conditions
	ld	a, [spratr_buffer +$20 +0]
	cp	56 -1
	ret	z

	jp	WEIGHT_RAISE_LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
DONE_WEIGHT_RAISE:
; Hides the stunned indicator
	ld	a, SPAT_OB
	ld	[spratr_buffer +$50 +0], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_VICTORY_SEQUENCE:
; Starts the music
	ld	a, $80 + 1
	call	REPLAYER.PLAY
; Shows the victory indicator
	ld	a, 72 -1
	ld	hl, spratr_buffer +$54 +0
	ld	[hl], a
	ld	a, [weight.target_x]
	sub	8
	inc	hl ; spratr_buffer +$54 +1
	ld	[hl], a
; Randomizes victory indicator sprite
	inc	hl ; spratr_buffer +$54 +2
	push	hl
	call	GET_RANDOM
	and	$06
	ld	hl, .VICTORY_SPRITES_TABLE
	call	ADD_HL_A
	pop	de
	ldi	; spratr_buffer +$54 +2
	ldi	; spratr_buffer +$54 +3
; "WINNER" message
	ld	hl, .LITERAL_WINNER
	ld	a, [weight.target]
	jp	PRINT_CURRENT_PLAYER_MESSAGE.A_OK

.VICTORY_SPRITES_TABLE:
	db	$90, 10
	db	$94, 15
	db	$98, 10
	db	$9c,  6

.LITERAL_WINNER:
	db	"WINNER"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
VICTORY_SEQUENCE_LOOP:
	halt
	call	LDIRVM_SPRATR
	call	LDIRVM_NAMTBL

; Raises (hides) the weight
	ld	a, [spratr_buffer +$20 +0]
	dec	a
	cp	40 -1
	call	nc, SET_WEIGHT_Y

; Updates the player sprites
	ld	hl, ANIMATE_PLAYER
	call	FOR_EVERY_PLAYER_DO

; Checks for exit conditions
	ld	a, [PT3_SETUP]
	rlca
	jr	nc, VICTORY_SEQUENCE_LOOP

	jp	TWO_SECONDS_IDLE_LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
DONE_VICTORY_SEQUENCE:
; Stops the music
	jp	REPLAYER.STOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ret a/[current_player]:
SET_FIRST_PLAYER:
	xor	a
	ld	[current_player], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param [current_player]:
; ret a/[current_player]:
SET_NEXT_PLAYER:
	ld	a, [current_player]
	inc	a
	and	$03
	ld	[current_player], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param [current_player]:
; ret a: current player lives
; ret hl: current player lives address
GET_CURRENT_PLAYER_LIVES:
	ld	a, [current_player]
GET_PLAYER_LIVES:
	ld	hl, lives
	jp	GET_HL_A_BYTE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ret z/nz: dead/alive
; touches: a
IS_CURRENT_PLAYER_ALIVE:
	ld	a, [current_player]
IS_PLAYER_ALIVE:
	push	hl
	ld	hl, lives
	call	ADD_HL_A
	ld	a, [hl]
	and	$7f
	pop	hl
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param [current_player]:
; ret a: current player inputs
; ret hl: current player inputs address
GET_CURRENT_PLAYER_INPUTS:
	ld	a, [current_player]
GET_PLAYER_INPUTS:
	ld	hl, inputs
	jp	GET_HL_A_BYTE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param [current_player]:
; ret de: current player SPRATR buffer address
GET_CURRENT_PLAYER_SPRATR:
	push	af
	ld	a, [current_player]
	add	a
	add	a
	add	a
	ld	de, spratr_buffer + $30
	call	ADD_DE_A
	pop	af
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param hl: routine address
FOR_EVERY_PLAYER_DO:
	call	SET_FIRST_PLAYER
.LOOP:
	push	hl ; (preserves routine)
	call	JP_HL
	pop	hl ; (restores routine)
	call	SET_NEXT_PLAYER
	jr	nz, .LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
REMOVE_CURRENT_PLAYER_MESSAGE:
	ld	hl, LITERAL_BLANKS
	; jp	PRINT_CURRENT_PLAYER_MESSAGE ; (falls through)
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
; param hl: literal address
PRINT_CURRENT_PLAYER_MESSAGE:
	push	af
	ld	a, [current_player]
	call	.A_OK
	pop	af
	ret

; param a: player index
; param hl: literal address
; touches a, bc, de
.A_OK:
	; push	bc
	; push	de
	push	hl
	add	a
	add	a
	add	a
	ld	de, namtbl_buffer + 1 + 17 * SCR_WIDTH
	call	ADD_DE_A
	ld	bc, 6
	ldir
	pop	hl
	; pop	de
	; pop	bc
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
PRINT_CURRENT_PLAYER_LIVES:
	ld	a, [current_player]
; param a: player index
.A_OK:
	add	a
	add	a
	add	a
	ld	de, namtbl_buffer + 3 + 2 * SCR_WIDTH
	call	ADD_DE_A
	call	GET_CURRENT_PLAYER_LIVES
	cp	NO_LIVES
	ld	hl, LITERAL_BLANKS
	jr	z, .PRINT
	ld	hl, .LITERAL_LIVES
	call	ADD_HL_A
.PRINT:
	ldi
	ldi
	ret
.LITERAL_LIVES:
	db	$84, $84, $81, $81
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
RESET_TIMER:
	ld	a, -1
	ld	[timer.value], a
	ld 	a, ' '
	ld	[namtbl_buffer + 16 + 4 * SCR_WIDTH], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param b
INIT_TIMER:
; Checks if started
	ld	a, [timer.value]
	or	a
	ret	p ; yes
.FORCE:
	ld	hl, timer.value
; no: Sets value
	ld	[hl], b
	ld	a, [frame_rate]
	ld	[timer.framecounter], a
; Prints the initial value
	ld	a, [hl]
	add	'0'
	ld	[namtbl_buffer + 16 + 4 * SCR_WIDTH], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
UPDATE_TIMER:
; Checks if started
	ld	hl, timer.value
	ld	a, [hl]
	or	a
	ret	m ; no
; yes: Checks framecounter
	inc	hl ; timer.framecounter
	ld	a, [hl]
	dec	a
	ld	[hl], a
	ret	nz ; no
; yes: Updates value
	dec	hl ; timer.value
	ld	a, [hl]
	or	a
	ret	z ; (already 0)
	dec	a
	ld	[hl], a
; Restores framecounter
	ld	a, [frame_rate]
	ld	[timer.framecounter], a
; Prints the updated value
	; jp	PRINT_TIMER ; (falls through)
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
PRINT_TIMER:
	ld	a, [timer.value]
.A_OK:
	add	'0'
	ld	[namtbl_buffer + 16 + 4 * SCR_WIDTH], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ret z: timer is exhausted
CHECK_TIMER:
	ld	hl, [timer]
	ld	a, h
	or	l
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
JUST_ANIMATE_PLAYER:
; Every few frames
	ld	a, [JIFFY]
	and	$3f
	ret	nz
; Alternates the player animation
	call	GET_CURRENT_PLAYER_SPRATR
	inc	de
	inc	de
	ld	a, [de]
	xor	$40
	ld	[de], a
	ret

ANIMATE_PLAYER:
	call	JUST_ANIMATE_PLAYER
; Moves the player up or down
	call	IS_CURRENT_PLAYER_ALIVE
	jr	z, MOVE_PLAYER_DOWN

MOVE_PLAYER_UP:
	call	GET_CURRENT_PLAYER_SPRATR
	ld	a, [de]
	cp	96 -1
	ret	c
	dec	a
	ld	[de], a
	ret

MOVE_PLAYER_DOWN:
	call	GET_CURRENT_PLAYER_SPRATR
	ld	a, [de]
	cp	112 -1
	ret	nc
	inc	a
	ld	[de], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
SET_WEIGHT_POSITION_RANDOM:
; Gets a random position
	call	GET_RANDOM
	and	$03
	ld	[weight.target], a
; Checks if it is a valid position
	call	IS_PLAYER_ALIVE
	jr	z, SET_WEIGHT_POSITION_RANDOM ; no
; yes
	jp	SET_WEIGHT_POSITION
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
SET_WEIGHT_POSITION_NEXT:
; Increases the position
	ld	hl, weight.target
	ld	a, [hl]
	inc	a
	and	$03
	ld	[hl], a
; Checks if it is a valid position
	call	IS_PLAYER_ALIVE
	jr	z, SET_WEIGHT_POSITION_NEXT ; no
; yes
	; jp	SET_WEIGHT_POSITION ; (falls through)
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
; param a:
SET_WEIGHT_POSITION:
	ld	a, [weight.target]
.A_OK:
	rrca
	rrca
	add	32
	ld	[weight.target_x], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
UPDATE_WEIGHT_X:
; Checks target X
	ld	hl, weight.target_x
	ld	b, [hl]
	inc	hl ; weight.current_x
	ld	a, [hl]
	cp	b
	call	nz, .INC_HL_TWICE
; Updates weight and chain sprites
	ld	a, [hl]
	ld	hl, spratr_buffer +$20
	cp	8
	jr	c, .SET_SPRITE_X_WITH_EC_x4
	jr	.SET_SPRITE_X_WITHOUT_EC_x4

.INC_HL_TWICE:
	inc	[hl]
	inc	[hl]
	ret

.SET_SPRITE_X_WITHOUT_EC_x4:
	sub	8
	call	.SET_SPRITE_X_WITHOUT_EC_x2
.SET_SPRITE_X_WITHOUT_EC_x2:
	call	.SET_SPRITE_X_WITHOUT_EC
.SET_SPRITE_X_WITHOUT_EC:
	inc	hl ; x
	ld	[hl], a
	inc	hl ; pattern
	inc	hl ; color
	res	7, [hl]
	inc	hl
	ret

.SET_SPRITE_X_WITH_EC_x4:
	add	32 -8
	call	.SET_SPRITE_X_WITH_EC_x2
.SET_SPRITE_X_WITH_EC_x2:
	call	.SET_SPRITE_X_WITH_EC
.SET_SPRITE_X_WITH_EC:
	inc	hl ; x
	ld	[hl], a
	inc	hl ; pattern
	inc	hl ; color
	set	7, [hl]
	inc	hl
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
RESET_WEIGHT_Y:
	ld	a, 56 -1
	; jp	SET_WEIGHT_Y ; (falls through)
; ------VVVV----(falls through)------------------------------------------------

; -----------------------------------------------------------------------------
SET_WEIGHT_Y:
	ld	[spratr_buffer +$20 +0], a
	call	.NEXT
	ld	[spratr_buffer +$24 +0], a
	call	.NEXT
	ld	[spratr_buffer +$28 +0], a
	call	.NEXT
	ld	[spratr_buffer +$2c +0], a
	ret
.NEXT:
	sub	16
	cp	40 -1
	ret	nc
	ld	a, 40 -1
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------

LITERAL_BLANKS:
	db	"      "

SONG_TABLE:
	dw	.ShuffleOne
	dw	.YouWin1
	dw	.empty
.ShuffleOne:
	incbin	"games/minigames/run23/music/RUN23_ShuffleOne.pt3.hl.zx0"
.YouWin1:
	incbin	"games/minigames/run23/music/RUN23_YouWin1.pt3.hl.zx0"
.empty:
	incbin	"games/minigames/run23/music/empty.pt3.hl.zx0"

SOUND_BANK:
	incbin	"games/minigames/run23/music/run23.afb"

	CFG_SOUND_JOIN:			equ 1 -1
	CFG_SOUND_PUSH:			equ 2 -1
	CFG_SOUND_TIMEOUT:		equ 3 -1
	CFG_SOUND_WEIGHT_MOVE:		equ 5 -1
	CFG_SOUND_WEIGHT_FALL:		equ 4 -1
; -----------------------------------------------------------------------------

	include	"lib/rom_end.asm"

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"

; lib/ram.asm automatically starts the RAM section at the proper address
; (either $C000 (16KB) or $E000 (8KB)) and includes everything MSXlib requires.

;
; YOUR VARIABLES (RAM) START HERE
;

number_of_players:	rb	1

lives:
	.player1:	rb	1
	.player2:	rb	1
	.player3:	rb	1
	.player4:	rb	1

inputs:
	.player1:	rb	1
	.player2:	rb	1
	.player3:	rb	1
	.player4:	rb	1

weight:
	.movements:	rb	1
	.target:	rb	1
	.target_x:	rb	1
	.current_x:	rb	1
	.speed:		rb	1

timer:
	.value:		rb	1
	.framecounter:	rb	1

; (auxiliary variable)
current_player:		rb	1

; -----------------------------------------------------------------------------

	include	"lib/ram_end.asm"

; EOF
