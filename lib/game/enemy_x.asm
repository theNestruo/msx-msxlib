;
; =============================================================================
;	Default enemy control routines (platformer game)
;	Convenience enemy helper routines (platform games)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Stationary: the enemy does not move at all
ENEMY_TYPE_STATIONARY:
	dw	PUT_ENEMY_SPRITE
	db	0 ; (unused)
	dw	.HANDLER
	db	0 ; 0 = forever
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stationary state handler: the enemy does not move
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARGS]: number of frames (0 = forever)
; ret z/nz: if the state has finished
.HANDLER:
; Is the argument zero?
	ld	a, [iy + ENEMY_STATE.ARGS]
	or	a
	jr	z, .FOREVER
; increases frame counter
	inc	[ix + enemy.frame_counter]
; ret z/nz
	; ld	a, [iy + ENEMY_STATE.ARGS] ; unnecessary
	cp	[ix + enemy.frame_counter]
	ret
	
.FOREVER:
; ret nz (halt)
	inc	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stationary state handler: the enemy does not move, but turns around
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy+_STATE_ARGUMENT]: ttffffff:
; - f the frames to wait before each turn
; - t the times to turn minus 1 (0 = 1 time, 1 = 2 times, etc.)
; ret z/nz: if the state has finished
.HANDLER_TURNING:
; compares frame counter with frames
	ld	a, [ix + enemy.frame_counter]
	ld	b, a ; preserves frame counter in b
	xor	[iy + ENEMY_STATE.ARGS]
	and	$3f ; masks the ffffff part
	jr	z, .DO_TURN
; increases frame counter
	inc	[ix + enemy.frame_counter]
; ret nz (halt)
	ret
	
.DO_TURN:
	call	TURN_ENEMY
; compares frame counter with times
	ld	a, b ; restores frame counter in b
	cp	[iy + ENEMY_STATE.ARGS]
	ret	z ; (continue)
; resets frame part of frame counter and increases times counter
	and	$c0
	add	$40
	ld	[ix + enemy.frame_counter], a
; ret nz (halt)
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker: the enemy walks ahead along the ground,
; then turns around, and continues
ENEMY_TYPE_WALKER:
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	ENEMY_TYPE_WALKER.HANDLER
	db	0 ; 0 = forever
	dw	TURN_ENEMY
	db	0 ; (unused)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker: the enemy walks ahead along the ground,
; then pauses, turning around, and continues
.WITH_PAUSE:
; walks ahead along the ground
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	ENEMY_TYPE_WALKER.HANDLER
	db	0 ; 0 = forever
	dw	SET_ENEMY_STATE
	db	ENEMY_STATE.NEXT
; pauses, turning around, and continues
	dw	PUT_ENEMY_SPRITE
	db	0 ; (unused)
	dw	ENEMY_TYPE_STATIONARY.HANDLER_TURNING
	db	(2 << 6) OR CFG_ENEMY_PAUSE_M ; 3 times, medium pause
	dw	SET_ENEMY_STATE
	db	-5 * ENEMY_STATE.SIZE ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker: the enemy walks a short distance toward the player along the ground,
; then pauses and continues
.FOLLOWER:
; pauses and turns towards the player
	dw	PUT_ENEMY_SPRITE
	db	0 ; (unused)
	dw	ENEMY_TYPE_STATIONARY.HANDLER_TURNING
	db	(2 << 6) OR CFG_ENEMY_PAUSE_M ; 3 times, medium pause
	dw	TURN_ENEMY.TOWARDS_PLAYER
	db	0 ; (unused)
	dw	SET_ENEMY_STATE
	db	ENEMY_STATE.NEXT
; walks ahead along the ground
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	ENEMY_TYPE_WALKER.HANDLER
	db	CFG_ENEMY_PAUSE_S ; short distance
	dw	SET_ENEMY_STATE
	db	-6 * ENEMY_STATE.SIZE ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker: the enemy walks a short distance toward the player along the ground,
; then pauses briefly and continues
.FAST_FOLLOWER:
; pauses briefly and turns towards the player
	dw	PUT_ENEMY_SPRITE
	db	0 ; (unused)
	dw	ENEMY_TYPE_STATIONARY.HANDLER
	db	CFG_ENEMY_PAUSE_M ; medium pause
	dw	TURN_ENEMY.TOWARDS_PLAYER
	db	0 ; (unused)
	dw	SET_ENEMY_STATE
	db	ENEMY_STATE.NEXT
; walks ahead along the ground
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	ENEMY_TYPE_WALKER.HANDLER
	db	CFG_ENEMY_PAUSE_M ; medium distance
	dw	SET_ENEMY_STATE
	db	-6 * ENEMY_STATE.SIZE ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker state handler: the enemy walks ahead along the ground
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARGS]: distance (frames/pixels) (0 = forever)
; ret z/nz: if the state has finished (cannot walk or distance reached)
.HANDLER:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
	jr	z, .HANDLER_RIGHT
	; jr	.HANDLER_LEFT ; falls through

.HANDLER_LEFT:
	call	CAN_ENEMY_WALK.LEFT
	ret	z ; no
; moves left
	dec	[ix + enemy.x]
	jp	ENEMY_TYPE_STATIONARY.HANDLER

.HANDLER_RIGHT:
	call	CAN_ENEMY_WALK.RIGHT
	ret	z ; no
; moves right
	inc	[ix + enemy.x]
	jp	ENEMY_TYPE_STATIONARY.HANDLER
; -----------------------------------------------------------------------------


; Riser - The enemy can increase its height (often, can rise from nothing). Examples: Super Mario's Piranha Plants and Castlevania's Mud Man

; Ducker - The enemy can reduce its height (including, melting into the floor). Example: Super Mario's Piranha Plants

; Faller - The enemy falls from the ceiling onto the ground. Usually these enemies are drops of something, like acid. Some games have slimes that do this.

; Jumper - The enemy can bounce or jump. (some jump forward, some jump straight up and down). Examples: Donkey Kong's Springs, Super Mario 2's Tweeter, Super Mario 2's Ninji

; Floater - The enemy can float, fly, or levitate. Example: Castlevania's Bats

; Sticky - The enemy sticks to walls and ceilings. Example: Super Mario 2's Spark

; Waver - The enemy floats in a sine wave pattern. Example: Castlevania's Medusa Head

; Rotator - The enemy rotates around a fixed point. Sometimes, the fixed point moves, and can move according to any movement attribute in this list. Also, the rotation direction may change. Example: Super Mario 3's Rotodisc, These jetpack enemeis from Sunsoft's Batman (notice that the point which they rotate around is the player)

; Swinger - The enemy swings from a fixed point. Example: Castlevania's swinging blades

; Pacer - The enemy changes direction in response to a trigger (like reaching the edge of a platform). Example: Super Mario's Red Koopas

; Follower - The enemy follows the player (Often used in top-down games). Example: Zelda 3's Hard Hat Beetles

; Roamer - The enemy changes direction completely randomly. Example: Legend of Zelda's Octoroks

; Liner - The enemy moves directly to a spot on the screen. Forgot to record the enemies I saw doing this, but usually they move from one spot to another in straight lines, sometimes randomly, other times, trying to 'slice' through the player.

; Teleporter - The enemy can teleport from one location to another. Example: Zelda's Wizrobes

; Dasher - The enemy dashes in a direction, faster than its normal movement speed. Example: Zelda's Rope Snakes

; Ponger - The enemy ignores gravity and physics, and bounces off walls in straight lines. Example: Zelda 2's "Bubbles"

; Geobound - The enemy is physically stuck to the geometry of the level, sometimes appears as level geometry. Examples: Megaman's Spikes, Super Mario's Piranha Plants, CastleVania's White Dragon

; Tethered - The enemy is tethered to the level's geometry by a chain or a rope. Example: Super Mario's Chain Chomps

; Swooper - A floating enemy that swoops down, often returning to its original position, but not always. Example: Castlevania's Bats, Super Mario's Swoopers, Super Mario 3's Angry Sun

;
; =============================================================================
;	Convenience enemy helper routines (platform games)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Checks if the enemy can walk ahead (i.e.: floor and no wall)
; param ix: pointer to the current enemy
; ret z: no
; ret nz: yes
CAN_ENEMY_WALK:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
IFDEF CFG_OPT_SPEED
	jp	nz, CAN_ENEMY_WALK.LEFT
	jp	CAN_ENEMY_WALK.RIGHT
ELSE
	jr	nz, CAN_ENEMY_WALK.LEFT
	jr	CAN_ENEMY_WALK.RIGHT
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Checks if the enemy can fly ahead (i.e.: no wall)
; param ix: pointer to the current enemy
; ret z: no
; ret nz: yes
CAN_ENEMY_FLY:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
IFDEF CFG_OPT_SPEED
	jp	nz, CAN_ENEMY_FLY.LEFT
	jp	CAN_ENEMY_FLY.RIGHT
ELSE
	jr	nz, CAN_ENEMY_FLY.LEFT
	jr	CAN_ENEMY_FLY.RIGHT
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Checks if the enemy can walk left (i.e.: floor and no wall)
; param ix: pointer to the current enemy
; ret z: no
; ret nz: yes
CAN_ENEMY_WALK.LEFT:
; Is there floor ahead to the left?
	call	GET_ENEMY_TILE_FLAGS_UNDER.LEFT
	bit	BIT_WORLD_FLOOR, a
	ret	z ; no
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Checks if the enemy can fly left (i.e.: no wall)
; param ix: pointer to the current enemy
; ret z: no
; ret nz: yes
CAN_ENEMY_FLY.LEFT:
; Is there wall ahead to the left?
	call	GET_ENEMY_TILE_FLAGS_LEFT
	cpl	; (negative check to ret z/nz properly)
	bit	BIT_WORLD_SOLID, a
; ret z/nz
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Checks if the enemy can walk right (i.e.: floor and no wall)
; param ix: pointer to the current enemy
; ret z: no
; ret nz: yes
CAN_ENEMY_WALK.RIGHT:
; Is there floor ahead to the right?
	call	GET_ENEMY_TILE_FLAGS_UNDER.RIGHT
	bit	BIT_WORLD_FLOOR, a
	ret	z ; no
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Checks if the enemy can fly right (i.e.: no wall)
; param ix: pointer to the current enemy
; ret z: no
; ret nz: yes
CAN_ENEMY_FLY.RIGHT:
; Is there wall ahead to the right?
	call	GET_ENEMY_TILE_FLAGS_RIGHT
	cpl	; (negative check to ret z/nz properly)
	bit	BIT_WORLD_SOLID, a
; ret z/nz
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the tile flags under the enemy and to the left
; param ix: pointer to the current enemy
; ret a: tile flags
GET_ENEMY_TILE_FLAGS_UNDER.LEFT:
	ld	a, ENEMY_BOX_X_OFFSET -1
IFDEF CFG_OPT_SPEED
	jp	GET_ENEMY_TILE_FLAGS_UNDER.A_OK
ELSE
	jr	GET_ENEMY_TILE_FLAGS_UNDER.A_OK
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the tile flags under the enemy and to the right
; param ix: pointer to the current enemy
; ret a: tile flags
GET_ENEMY_TILE_FLAGS_UNDER.RIGHT:
	ld	a, ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
IFDEF CFG_OPT_SPEED
	jp	GET_ENEMY_TILE_FLAGS_UNDER.A_OK
ELSE
	jr	GET_ENEMY_TILE_FLAGS_UNDER.A_OK
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the tile flags under the enemy
; param ix: pointer to the current enemy
; ret a: tile flags
GET_ENEMY_TILE_FLAGS_UNDER:
	xor	a
	
.A_OK:
; Enemy coordinates
	ld	e, [ix + enemy.y]
; x += dx
	add	[ix + enemy.x]
	ld	d, a
; Reads the tile index and then the tile flags
	call	GET_TILE_VALUE
	jp	GET_TILE_FLAGS
; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ENEMY_ROUTINE_CRAWLER:
	; dw	EH_PUT_SPRITE_ANIM
	; db	0 ; (unused)
	; dw	EH_WALK
	; db	0 ; forever
	; dw	EH_SET_STATE
	; db	STATE_SIZE ; next
	
	; dw	EH_PUT_SPRITE
	; db	0 ; (unused)
	; dw	EH_IDLE_TURNING ; EH_IDLE
	; db	(2 << 6) OR 30 ; 3 repetitions, 30 frames
	; dw	EH_SET_STATE
	; db	-5 * STATE_SIZE ; restart
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ENEMY_ROUTINE_FOLLOWER:
	; dw	EH_PUT_SPRITE_ANIM
	; db	0 ; (unused)
	; dw	EH_WALK
	; db	32 ; 16 pixels
	; dw	EH_SET_STATE
	; db	STATE_SIZE ; next
	
	; dw	EH_PUT_SPRITE
	; db	0 ; (unused)
	; dw	EH_IDLE_TURNING
	; db	(2 << 6) OR 30 ; 3 repetitions, 30 frames
	; dw	EH_TURN_WALKING_ENEMY_TOWARDS_PLAYER
	; db	0 ; (unused)
	; dw	EH_SET_STATE
	; db	-6 * STATE_SIZE ; restart
; ; -----------------------------------------------------------------------------

; ;
; ; =============================================================================
; ;	Handler routines for enemies (platform games)
; ; =============================================================================
; ;

; ; -----------------------------------------------------------------------------
; EH_TURN_WALKING_ENEMY_TOWARDS_PLAYER:
	; call	TURN_WALKING_ENEMY_TOWARDS_PLAYER
; ; ret z (continue with next handler)
	; cp	a
	; ret
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; EH_WALK:
	; bit	BIT_ENEMY_PATTERN_LEFT, [ix + _ENEMY_PATTERN]
	; jr	z, EH_WALK_RIGHT
	; ; jr	EH_WALK_LEFT ; falls through
; ; ------VVVV----falls through--------------------------------------------------

; ; -----------------------------------------------------------------------------
; EH_WALK_LEFT:
	; call	CAN_ENEMY_WALK_LEFT
	; ret	z ; no
	; dec	[ix + _ENEMY_X]
; ; ret nz
	; ; or	1 ; unecessary? (TODO check dec[ix] flag affection)
	; ; ret
	; jp	EH_IDLE
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; EH_WALK_RIGHT:
	; call	CAN_ENEMY_WALK
	; ret	z ; no
	; inc	[ix + _ENEMY_X]
; ; ret nz
	; ; or	1 ; unecessary? (TODO check inc[ix] flag affection)
	; ; ret
	; jp	EH_IDLE
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; EH_FLY_LEFT:
; ; ; Can move left? Checks walls
	; ; call	CHECK_TILES_LEFT_ENEMY
	; ; cpl	; (for checking z instead of nz)
	; ; bit	BIT_WORLD_SOLID, a
	; ; ret	z ; no
; ; -----------------------------------------------------------------------------
	
; ; -----------------------------------------------------------------------------
; ; EH_FLOAT_LEFT:
; ; ; Unconditionally moves left
	; ; dec	[ix + _ENEMY_X]
; ; ; ret nz
	; ; or	1
	; ; ret
; ; -----------------------------------------------------------------------------

; ; ; -----------------------------------------------------------------------------
; ; ; Mueve el enemigo hacia la derecha, comprobando suelo y colisiones
; ; ; param ix: puntero al enemigo
; ; ; param _STATE_ARG: número de píxeles/frames; se decrementará (0 = infinito)
; ; EH_WALK_RIGHT:
; ; ; Can walk left? Checks floor
	; ; call	CHECK_TILE_UNDER_RIGHT_ENEMY
	; ; bit	BIT_WORLD_FLOOR, a
	; ; ret	z ; no
	
; ; EH_FLY_RIGHT:
; ; ; Can move right? Checks walls
	; ; call	CHECK_TILES_RIGHT_ENEMY
	; ; cpl	; (for checking z instead of nz)
	; ; bit	BIT_WORLD_SOLID, a
	; ; ret	z ; no
	
; ; EH_FLOAT_RIGHT:
; ; ; Unconditionally moves right
	; ; inc	[ix + _ENEMY_X]
; ; ; ret nz
	; ; or	1
	; ; ret
; ; ; -----------------------------------------------------------------------------
; 