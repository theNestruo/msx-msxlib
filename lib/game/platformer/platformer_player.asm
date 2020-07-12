;
; =============================================================================
;	Default player control routines (platformer game)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bit index for the tile properties (platformer game)
	BIT_WORLD_FLOOR:	equ 1
	BIT_WORLD_STAIRS:	equ 2
	BIT_WORLD_DEATH:	equ 3
	BIT_WORLD_WALK_ON:	equ 4 ; Tile collision (single char)
	BIT_WORLD_WIDE_ON:	equ 5 ; Wide tile collision (player width)
	BIT_WORLD_WALK_OVER:	equ 6 ; Walking over tiles (player width)
	BIT_WORLD_PUSHABLE:	equ 7 ; Pushable tiles (player height)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Default player states
	PLAYER_STATE_FLOOR:	equ (0 << 2) ; $00
	PLAYER_STATE_STAIRS:	equ (1 << 2) ; $04
	PLAYER_STATE_AIR:	equ (2 << 2) ; $08
	PLAYER_STATE_DYING:	equ (3 << 2) + (1 << BIT_STATE_FINISH) ; $8c
	PLAYER_STATE_FINISH:	equ PLAYER_STATE_FLOOR + (1 << BIT_STATE_FINISH) ; $80
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Main player control routine
UPDATE_PLAYER:
; Invokes PLAYER_UPDATE_TABLE[player.state] routine
	ld	a, [player.state] ; a = player.state without flags
	and	$ff - (1 << BIT_STATE_FINISH) ; (removes finish bit)
	srl	a
	srl	a
	ld	hl, PLAYER_UPDATE_TABLE
	call	JP_TABLE

; Finished?
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	ret	nz ; yes

; Reads the tile flags at the player coordinates
	call	GET_PLAYER_TILE_FLAGS
; Has death bit?
	bit	BIT_WORLD_DEATH, a
	jp	nz, SET_PLAYER_DYING ; yes
; Is solid? (the player has been crushed)
	bit	BIT_WORLD_SOLID, a
	jp	nz, SET_PLAYER_DYING ; yes
; Has tile collision (single char) bit?
IFEXIST ON_PLAYER_WALK_ON
	bit	BIT_WORLD_WALK_ON, a
	call	nz, ON_PLAYER_WALK_ON ; yes
ENDIF

IFEXIST ON_PLAYER_WIDE_ON
; Reads the AND-ed flags of the tiles at the player coordinates
	call	GET_PLAYER_TILE_FLAGS_WIDE
; Has wide tile collision (player width) bit?
	bit	BIT_WORLD_WIDE_ON, a
	call	nz, ON_PLAYER_WIDE_ON ; yes
ENDIF

IFEXIST ON_PLAYER_WALK_OVER
; Reads the OR-ed flags of the tiles under the player
	call	GET_PLAYER_TILE_FLAGS_UNDER
; Has walking over tiles (player width) bit?
	bit	BIT_WORLD_WALK_OVER, a
	call	nz, ON_PLAYER_WALK_OVER ; yes
ENDIF

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Set the player to be on the floor in the next frame
SET_PLAYER_FLOOR.LANDING:
IFEXIST CFG_SOUND_PLAYER_LAND
	ld	a, CFG_SOUND_PLAYER_LAND
	ld	c, 15 ; lowest priority
	call	ayFX_INIT
ENDIF

SET_PLAYER_FLOOR:
; Y adjust
	ld	hl, player.y
	ld	a, [hl]
	add	CFG_PLAYER_GRAVITY - 1
	and	$f8 ; (aligned to char)
	ld	[hl], a
; Sets the player state
	ld	a, PLAYER_STATE_FLOOR
	jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Control routine when the player is on the floor
UPDATE_PLAYER_FLOOR:
; Trying to get on stairs?
	ld	hl, input.level
	bit	BIT_STICK_UP, [hl]
	jp	nz, .CHECK_UPSTAIRS ; yes (upstairs)
	bit	BIT_STICK_DOWN, [hl]
	jp	nz, .CHECK_DOWNSTAIRS ; yes (downstairs)

.NO_STAIRS:
; Jumping?
	ld	hl, input.edge
	bit	CFG_PLAYER_JUMP_INPUT, [hl]
	jp	nz, SET_PLAYER_JUMPING ; yes

; Moves horizontally with animation
	call	MOVE_PLAYER_LR_ANIMATE

; Is there floor under the player?
	call	GET_PLAYER_TILE_FLAGS_UNDER
	bit	BIT_WORLD_FLOOR, a
	jp	z, SET_PLAYER_FALLING ; no
; yes
	ret

.CHECK_UPSTAIRS:
; Trying to get on stairs upstairs
	call	GET_PLAYER_TILE_FLAGS_WIDE
	jp	.CHECK_STAIRS

.CHECK_DOWNSTAIRS:
; Trying to get on stairs downstairs
	call	GET_PLAYER_TILE_FLAGS_WIDE_UNDER
	; jp	.CHECK_STAIRS ; falls through

.CHECK_STAIRS:
; Are there stairs? (i.e.: stairs flags, but not solid flag)
	and	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_STAIRS)
	cp	(1 << BIT_WORLD_STAIRS)
	jp	nz, .NO_STAIRS ; no
; yes
	; jp	SET_PLAYER_STAIRS ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Set the player on stairs in the next frame
SET_PLAYER_STAIRS:
; Sets the player state
	ld	a, PLAYER_STATE_STAIRS
	call	SET_PLAYER_STATE

; Moves horizontally and vertically
	call	MOVE_PLAYER_LR
	jp	UPDATE_PLAYER_STAIRS.ON
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Control routine when the player is on stairs
UPDATE_PLAYER_STAIRS:
; Moves horizontally (no animation)
	call	MOVE_PLAYER_LR
; Moved out of the stairs? (sides)
	call	GET_PLAYER_TILE_FLAGS_WIDE
	bit	BIT_WORLD_STAIRS, a
	jr	z, .OFF ; yes

.ON:
; Manages vertical movement
	ld	hl, input.level
	bit	BIT_STICK_DOWN, [hl]
	jp	nz, .DOWN
	bit	BIT_STICK_UP, [hl]
	ret	z

.UP:
; Is there solid above the player?
	call	GET_PLAYER_TILE_FLAGS_ABOVE
	bit	BIT_WORLD_SOLID, a
	ret	nz ; yes
; no: keep moving
	ld	hl, player.y
	dec	[hl]
	jp	UPDATE_PLAYER_ANIMATION

.DOWN:
; Moved out of the stairs? (down)
	call	GET_PLAYER_TILE_FLAGS_UNDER
	bit	BIT_WORLD_STAIRS, a
	jp	z, .OFF ; yes
; no: Is there solid under the player?
	bit	BIT_WORLD_SOLID, a
	ret	nz ; yes
; no: keep moving
	ld	hl, player.y
	inc	[hl]
	jp	UPDATE_PLAYER_ANIMATION

.OFF:
; Is there floor under the player?
	call	GET_PLAYER_TILE_FLAGS_UNDER
	bit	BIT_WORLD_FLOOR, a
	jp	nz, SET_PLAYER_FLOOR ; yes
	; jp	SET_PLAYER_FALLING ; no ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Set the player to be falling in the next frame
SET_PLAYER_FALLING:
; Sets the player state
	ld	a, PLAYER_STATE_AIR
	call	SET_PLAYER_STATE
; Initializes Delta-Y (dY) table index
	ld	a, PLAYER_DY_TABLE.FALL_OFFSET
	ld	[player.dy_index], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Set the player to be jumping in the next frame
SET_PLAYER_JUMPING:
IFEXIST CFG_SOUND_PLAYER_JUMP
	ld	a, CFG_SOUND_PLAYER_JUMP
	ld	c, 14 ; almost lowest priority
	call	ayFX_INIT
ENDIF
; Sets the player state
	ld	a, PLAYER_STATE_AIR
	call	SET_PLAYER_STATE
; Initializes Delta-Y (dY) table index
	xor	a
	ld	[player.dy_index], a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Control routine when the player is on air (either jumping or falling)
UPDATE_PLAYER_AIR:
; Moves horizontally (no animation)
	call	MOVE_PLAYER_LR

; Updates Delta-Y (dY) table index
	; call	UPDATE_PLAYER_DY_INDEX
	call	READ_PLAYER_DY_VALUE
	ld	hl, player.dy_index
	inc	[hl]

	or	a
	ret	z ; (dy == 0)
	jp	m, .UP ; (dy < 0)

; (dy > 0): Is there floor under the player?
	push	af ; preserves dy
	call	GET_PLAYER_TILE_FLAGS_UNDER_FAST
	bit	BIT_WORLD_FLOOR, a
	pop	bc ; restores dy in b (to keep f)
	jp	nz, SET_PLAYER_FLOOR.LANDING ; yes
; no
	ld	a, b ; restores dy in a
	jp	MOVE_PLAYER_V

.UP:
; (dy < 0): Is there solid above the player?
	push	af ; preserves dy
	call	GET_PLAYER_TILE_FLAGS_ABOVE
	bit	BIT_WORLD_SOLID, a
	pop	bc ; restores dy in b (to keep f)
	jp	nz, SET_PLAYER_FALLING ; yes
; no
	ld	a, b ; restores dy in a
	jp	MOVE_PLAYER_V
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Control routine when the player is on stairs
SET_PLAYER_DYING:
; Is the player already dying?
	ld	a, [player.state]
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_DYING
	ret	z ; yes (do nothing)
; no: Sets the player state
	ld	a, PLAYER_STATE_DYING
IFEXIST CFG_SOUND_PLAYER_KILLED
	call	SET_PLAYER_STATE
	ld	a, CFG_SOUND_PLAYER_KILLED
	ld	c, 0 ; highest priority
	jp	ayFX_INIT
ELSE
	jp	SET_PLAYER_STATE
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Control routine when the player is dying
UPDATE_PLAYER_DYING:
; Animation
	call	UPDATE_PLAYER_ANIMATION

; Each two frames
	ld	a, [JIFFY]
	and	1
	ret	z ; no
; yes: checks solid
	; ld	a, 1 ; unnecessary
	call	GET_PLAYER_TILE_FLAGS_UNDER_FAST
	bit	BIT_WORLD_SOLID, a
	ret	nz ; yes
; no: moves 1 pixel down
	ld	a, 1
	jp	MOVE_PLAYER_V
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the player left or right, according input
MOVE_PLAYER_LR:
; Manages horizontal movement
	ld	hl, input.level
	bit	BIT_STICK_RIGHT, [hl]
	jp	nz, .RIGHT
	bit	BIT_STICK_LEFT, [hl]
	ret	z

.LEFT:
; Is there solid left to the player?
	call	GET_PLAYER_TILE_FLAGS_LEFT
	bit	BIT_WORLD_SOLID, a
	ret	nz ; yes
; no
	jp	MOVE_PLAYER_LEFT

.RIGHT:
; Is there solid right to the player?
	call	GET_PLAYER_TILE_FLAGS_RIGHT
	bit	BIT_WORLD_SOLID, a
	ret	nz ; yes
; no
	jp	MOVE_PLAYER_RIGHT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the player left or right, according input, with animation
MOVE_PLAYER_LR_ANIMATE:
; Manages horizontal movement
	ld	hl, input.level
	bit	BIT_STICK_LEFT, [hl]
	jp	nz, .LEFT
	bit	BIT_STICK_RIGHT, [hl]
	jp	nz, .RIGHT

.RESET_ANIMATION:
; Resets the animation counter
	xor	a
	ld	[player.animation_delay], a
; Turns off the animation flag
	ld	hl, player.state
	res	BIT_STATE_ANIM, [hl]

IFEXIST ON_PLAYER_PUSH
.RESET_FLOOR:
; Resets floor state (in case ON_PLAYER_PUSH is defined)
	ld	a, PLAYER_STATE_FLOOR
	ld	b, $ff XOR FLAGS_STATE
	jp	SET_PLAYER_STATE.MASK
ELSE
	ret
ENDIF

.LEFT:
; Is there solid left to the player?
	call	GET_PLAYER_TILE_FLAGS_LEFT

IFEXIST ON_PLAYER_PUSH.LEFT
; Are there pushable tiles left to the player?
	bit	BIT_WORLD_PUSHABLE, a
	jp	nz, ON_PLAYER_PUSH.LEFT
ENDIF

; Is there solid left to the player?
	bit	BIT_WORLD_SOLID, a
	jp	nz, .RESET_ANIMATION ; yes

; no
IFEXIST ON_PLAYER_PUSH
; Resets floor state (in case ON_PLAYER_PUSH is defined)
	call	.RESET_FLOOR
ENDIF
	call	UPDATE_PLAYER_ANIMATION
	jp	MOVE_PLAYER_LEFT

.RIGHT:
; Is there solid right to the player?
	call	GET_PLAYER_TILE_FLAGS_RIGHT

IFEXIST ON_PLAYER_PUSH.RIGHT
; Are there pushable tiles right to the player?
	bit	BIT_WORLD_PUSHABLE, a
	jp	nz, ON_PLAYER_PUSH.RIGHT
ENDIF

; Is there solid right to the player?
	bit	BIT_WORLD_SOLID, a
	jp	nz, .RESET_ANIMATION ; yes

; no
IFEXIST ON_PLAYER_PUSH
; Resets floor state (in case ON_PLAYER_PUSH is defined)
	call	.RESET_FLOOR
ENDIF
	call	UPDATE_PLAYER_ANIMATION
	jp	MOVE_PLAYER_RIGHT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
READ_PLAYER_DY_VALUE:
	ld	a, [player.dy_index]
	cp	PLAYER_DY_TABLE.SIZE
	jp	c, .FROM_TABLE
	ld	a, CFG_PLAYER_GRAVITY
	ret

.FROM_TABLE:
	ld	hl, PLAYER_DY_TABLE
	jp	GET_HL_A_BYTE
; -----------------------------------------------------------------------------

; EOF
