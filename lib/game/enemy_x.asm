;
; =============================================================================
;	Default enemy types (platformer game)
;	Convenience enemy state handlers (platformer game)
;	Convenience enemy helper routines (platform games)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Stationary: The enemy does not move at all
ENEMY_TYPE_STATIONARY:
; The enemy does not move
	dw	PUT_ENEMY_SPRITE
	db	0 ; (unused)
	dw	RET_NOT_ZERO
	; db	0 ; (unused)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stationary (animated): The enemy does not move at all
.ANIMATED:
; The enemy does not move
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	RET_NOT_ZERO
	; db	0 ; (unused)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Flyer: The enemy flies (or foats), then turns around, and continues
ENEMY_TYPE_FLYER:
; The enemy flies
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	FLYER_ENEMY_HANDLER
	db	0 ; (unused)
	dw	RET_NOT_ZERO
	; db	0 ; (unused)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker: the enemy walks ahead along the ground,
; then turns around, and continues
ENEMY_TYPE_WALKER:
; The enemy walks ahead
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	WALKER_ENEMY_HANDLER.CONTINUOUS
	db	0 ; (unused)
	dw	RET_NOT_ZERO
	; db	0 ; (unused)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker (with pause): the enemy walks ahead along the ground,
; then pauses, turning around, and continues
.WITH_PAUSE:
; The enemy walks ahead along the ground
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	WALKER_ENEMY_HANDLER
	db	0 ; 0 = forever
; then
	dw	SET_NEW_STATE_HANDLER
	db	ENEMY_STATE.NEXT
; pauses, turning around
	dw	PUT_ENEMY_SPRITE
	db	0 ; (unused)
	dw	STATIONARY_ENEMY_HANDLER.TURNING ; then pauses, turning around
	db	(2 << 6) OR CFG_ENEMY_PAUSE_M ; 3 (even) times, medium pause
; and continues
	dw	SET_NEW_STATE_HANDLER	; and continues
	db	-5 * ENEMY_STATE.SIZE ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker (follower): the enemy walks a medium distance along the ground,
; towards the player, then pauses briefly, and continues
.FOLLOWER:
; The enemy pauses briefly
	dw	PUT_ENEMY_SPRITE
	db	0 ; (unused)
	dw	STATIONARY_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M ; medium pause
; then turns towards the player
	dw	TURN_ENEMY.TOWARDS_PLAYER
	db	0 ; (unused)
	dw	SET_NEW_STATE_HANDLER
	db	ENEMY_STATE.NEXT
; walks ahead along the ground
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	WALKER_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M ; medium distance
; and continues
	dw	SET_NEW_STATE_HANDLER
	db	-6 * ENEMY_STATE.SIZE ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker (follower with pause):
; the enemy walks a medium distance along the ground,
; towards the player, then pauses, turning around, and continues
.FOLLOWER_WITH_PAUSE:
; The enemy pauses, turning around
	dw	PUT_ENEMY_SPRITE
	db	0 ; (unused)
	dw	STATIONARY_ENEMY_HANDLER.TURNING
	db	(2 << 6) OR CFG_ENEMY_PAUSE_M ; 3 times, medium pause
; then turns towards the player
	dw	TURN_ENEMY.TOWARDS_PLAYER
	db	0 ; (unused)
	dw	SET_NEW_STATE_HANDLER
	db	ENEMY_STATE.NEXT
; walks ahead along the ground
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	WALKER_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M ; medium distance
; and continues
	dw	SET_NEW_STATE_HANDLER
	db	-6 * ENEMY_STATE.SIZE ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Faller: The enemy falls from the ceiling onto the ground.
ENEMY_TYPE_FALLER:
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Faller (with trigger): The enemy falls onto the ground
; when the player x coordinate overlaps with the enemy's
.WITH_TRIGGER:
; Does the player overlaps x coordinate?
	dw	PUT_ENEMY_SPRITE
	db	0 ; (unused)
	dw	SET_NEW_STATE_HANDLER.ON_X_COLLISION
	db	2 * ENEMY_STATE.SIZE ; (skip one)
; No: the enemy remains stationary
	dw	STATIONARY_ENEMY_HANDLER
	db	0 ; 0 = forever
	
; Yes: The enemy falls onto the ground
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	FALLER_ENEMY_HANDLER
	db	0 ; 0 = forever
	dw	SET_NEW_STATE_HANDLER
	db	ENEMY_STATE.NEXT
; then rises back up
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	RISER_ENEMY_HANDLER
	db	0 ; 0 = forever
	dw	SET_NEW_STATE_HANDLER
	db	-8 * ENEMY_STATE.SIZE; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Riser: The enemy can increase its height.
; ENEMY_TYPE_RISER:
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Jumper: The enemy bounces or jumps.
; ENEMY_TYPE_JUMPER:
; -----------------------------------------------------------------------------

; Ducker - The enemy can reduce its height (including, melting into the floor).
; Example: Super Mario's Piranha Plants

; Sticky - The enemy sticks to walls and ceilings.
; Example: Super Mario 2's Spark

; -----------------------------------------------------------------------------
; Waver: The enemy floats in a sine wave pattern.
ENEMY_TYPE_WAVER:
; The enemy floats in a sine wave pattern
	dw	PUT_ENEMY_SPRITE_ANIM
	db	0 ; (unused)
	dw	WAVER_ENEMY_HANDLER
	db	0 ; (unused)
	dw	FLYER_ENEMY_HANDLER
	db	0 ; (unused)
	dw	RET_NOT_ZERO
	; db	0 ; (unused)
; -----------------------------------------------------------------------------

; Rotator - The enemy rotates around a fixed point.
; Sometimes, the fixed point moves, and can move according to any movement attribute in this list.
; Also, the rotation direction may change.
; Example: Super Mario 3's Rotodisc,
; These jetpack enemeis from Sunsoft's Batman (notice that the point which they rotate around is the player)

; Swinger - The enemy swings from a fixed point.
; Example: Castlevania's swinging blades

; Pacer - The enemy changes direction in response to a trigger (like reaching the edge of a platform).
; Example: Super Mario's Red Koopas

; Roamer - The enemy changes direction completely randomly.
; Example: Legend of Zelda's Octoroks

; Liner - The enemy moves directly to a spot on the screen.
; Forgot to record the enemies I saw doing this, but usually they move from one spot to another in straight lines,
; sometimes randomly, other times, trying to 'slice' through the player.

; Teleporter - The enemy can teleport from one location to another.
; Example: Zelda's Wizrobes

; Dasher - The enemy dashes in a direction, faster than its normal movement speed.
; Example: Zelda's Rope Snakes

; Ponger - The enemy ignores gravity and physics, and bounces off walls in straight lines.
; Example: Zelda 2's "Bubbles"

; Geobound - The enemy is physically stuck to the geometry of the level, sometimes appears as level geometry.
; Examples: Megaman's Spikes, Super Mario's Piranha Plants, CastleVania's White Dragon

; Tethered - The enemy is tethered to the level's geometry by a chain or a rope.
; Example: Super Mario's Chain Chomps

; Swooper - A floating enemy that swoops down, often returning to its original position, but not always.
; Example: Castlevania's Bats, Super Mario's Swoopers, Super Mario 3's Angry Sun

;
; =============================================================================
;	Convenience enemy state handlers (platformer game)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Stationary state handler: the enemy does not move
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARGS]: number of frames (0 = forever)
; ret z/nz: if the state has finished
STATIONARY_ENEMY_HANDLER:
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
.TURNING:
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
; Flyer state handler: The enemy flies (or floats),
; turning around when the wall is hit
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret z: continue
FLYER_ENEMY_HANDLER:
; Checks wall
	call	CAN_ENEMY_FLY
	jp	z, TURN_ENEMY ; yes: turns around
; no: moves the enemy
	call	MOVE_ENEMY
; ret z (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker state handler: the enemy walks ahead along the ground
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARGS]: distance (frames/pixels) (0 = forever)
; ret z/nz: if the state has finished (cannot walk or distance reached)
WALKER_ENEMY_HANDLER:
	call	CAN_ENEMY_WALK
	ret	z ; no
; yes: moves the enemy
	call	MOVE_ENEMY
; Checks distance
	jp	STATIONARY_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker state handler: the enemy walks ahead along the ground,
; turning around when the wall is hit or at the end of the platform
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; ret z: continue
.CONTINUOUS:
	call	CAN_ENEMY_WALK
	jp	z, TURN_ENEMY ; yes: turns around
; yes: moves the enemy
	call	MOVE_ENEMY
; ret z (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Faller state handler: the enemy falls onto the ground.
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARGS]: (ignored)
; ret z/nz: if the state has finished
FALLER_ENEMY_HANDLER:
; Has fallen onto the ground?
	call	GET_ENEMY_TILE_FLAGS_UNDER
	cpl	; (negative check to ret z/nz properly)
	bit	BIT_WORLD_SOLID, a
	ret	z ; yes (continue)
	
; Computes falling speed	
	ld	a, [ix + enemy.frame_counter]
	inc	[ix + enemy.frame_counter]
	add	ENEMY_DY_TABLE.FALL_OFFSET
	call	READ_FALLER_ENEMY_DY_VALUE
; moves down
	add	[ix + enemy.y]
	ld	[ix + enemy.y], a
; ret nz (halt)
	; inc	a ; (unnecessary)
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Riser: The enemy can increase its height.
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARGS]: number of frames (0 = forever)
; ret z/nz: if the state has finished
RISER_ENEMY_HANDLER:
	call	.AND
	jp	STATIONARY_ENEMY_HANDLER

.AND:
; Has reached the ceiling?
	call	GET_ENEMY_TILE_FLAGS_ABOVE
	cpl	; (negative check to ret z/nz properly)
	bit	BIT_WORLD_SOLID, a
	ret	z ; yes (continue)
; moves up
	dec	[ix + enemy.y]
; ret z ; (continue)
	xor	a
	ret
; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Lower: The enemy can decrease its height.
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state
; ; param [iy + ENEMY_STATE.ARGS]: number of frames (0 = forever)
; ; ret z/nz: if the state has finished
; LOWER_ENEMY_HANDLER:
	; call	.AND
	; jp	STATIONARY_ENEMY_HANDLER

; .AND:
; ; Has reached the ground?
	; call	GET_ENEMY_TILE_FLAGS_UNDER
	; cpl	; (negative check to ret z/nz properly)
	; bit	BIT_WORLD_SOLID, a
	; ret	z ; yes (continue)
; ; moves down
	; inc	[ix + enemy.y]
; ; ret z ; (continue)
	; xor	a
	; ret
; ; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ; Jumper: The enemy bounces or jumps.
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state
; ; param [iy + ENEMY_STATE.ARGS]: (ignored)
; ; ret z/nz: if the state has finished
; JUMPER_ENEMY_HANDLER:
	; ld	a, [ix + enemy.frame_counter]
	; cp	ENEMY_DY_TABLE.SIZE -1
	; jr	z, .DY_MAX ; yes
; ; increases frame counter
	; inc	[ix + enemy.frame_counter]
; .DY_MAX:
	; ld	hl, ENEMY_DY_TABLE
	; call	GET_HL_A_BYTE
	
	; add	[ix + enemy.y]
	; ld	[ix + enemy.y], a
	
; ; ret nz (halt)
	; xor	a
	; inc	a
	; ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Waver: The enemy floats in a sine wave pattern.
; Example: Castlevania's Medusa Head
WAVER_ENEMY_HANDLER:
	inc	[ix + enemy.frame_counter]
	ld	a, [ix + enemy.frame_counter]
	call	READ_WAVER_ENEMY_DY_VALUE ; ._16
	add	[ix + enemy.y]
	ld	[ix + enemy.y], a
; ret z
	xor	a
	ret
; -----------------------------------------------------------------------------

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
	jr	nz, CAN_ENEMY_WALK.LEFT
	jr	CAN_ENEMY_WALK.RIGHT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Checks if the enemy can fly ahead (i.e.: no wall)
; param ix: pointer to the current enemy
; ret z: no
; ret nz: yes
CAN_ENEMY_FLY:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
	jr	nz, CAN_ENEMY_FLY.LEFT
	jr	CAN_ENEMY_FLY.RIGHT
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
; Moves the enemy 1 pixel forward
; param ix: pointer to the current enemy
MOVE_ENEMY:
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
	jr	z, .RIGHT
	; jr	.LEFT ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the enemy 1 pixel to the left
; param ix: pointer to the current enemy
.LEFT:
	dec	[ix + enemy.x]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Moves the enemy 1 pixel to the right
; param ix: pointer to the current enemy
.RIGHT:
	inc	[ix + enemy.x]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the tile flags above the enemy
; param ix: pointer to the current enemy
; ret a: tile flags
GET_ENEMY_TILE_FLAGS_ABOVE:
	xor	a
; Enemy coordinates
	ld	a, [ix + enemy.y]
	add	ENEMY_BOX_Y_OFFSET -1
	ld	e, a
	ld	d, [ix + enemy.x]
; Reads the tile index and then the tile flags
	call	GET_TILE_VALUE
	jp	GET_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the tile flags under the enemy and to the left
; param ix: pointer to the current enemy
; ret a: tile flags
GET_ENEMY_TILE_FLAGS_UNDER.LEFT:
	ld	a, ENEMY_BOX_X_OFFSET -1
	jr	GET_ENEMY_TILE_FLAGS_UNDER.A_OK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads the tile flags under the enemy and to the right
; param ix: pointer to the current enemy
; ret a: tile flags
GET_ENEMY_TILE_FLAGS_UNDER.RIGHT:
	ld	a, ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
	jr	GET_ENEMY_TILE_FLAGS_UNDER.A_OK
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

; -----------------------------------------------------------------------------
; param a
READ_FALLER_ENEMY_DY_VALUE:
	; ld	a, [player.dy_index]
	cp	ENEMY_DY_TABLE.SIZE
	jr	c, .FROM_TABLE
	ld	a, CFG_ENEMY_GRAVITY
	ret
	
.FROM_TABLE:
	ld	hl, ENEMY_DY_TABLE
	jp	GET_HL_A_BYTE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param a
READ_WAVER_ENEMY_DY_VALUE:
; ._16:
	ld	a, [ix + enemy.frame_counter]
; ._16_A_OK:
.A_OK:
	and	$3f
	ld	hl, .DATA ; _16
	jp	GET_HL_A_BYTE
; .DATA_16:
.DATA:
	db	0,-1, 0, 0,  -1, 0,-1, 0,  -1,-1,-1, 0,  -1,-1,-1,-1
	db	0,-1,-1,-1,   0,-1, 0,-1,   0, 0,-1, 0,   0, 0, 0, 0
	db	0, 1, 0, 0,   1, 0, 1, 0,   1, 1, 1, 0,   1, 1, 1, 1
	db	0, 1, 1, 1,   0, 1, 0, 1,   0, 0, 1, 0,   0, 0, 0, 0
	
; ._8:
	; ld	a, [ix + enemy.frame_counter]
; ._8_A_OK:
	; and	$1f
	; ld	hl, .DATA_8
	; jp	GET_HL_A_BYTE
; .DATA_8:
	; db	 0, 0,  -1,0,  -1,0,  -1,-1
	; db	-1,-1,  0,-1,   0,-1,   0, 0
	; db	 0, 0,   1,0,   1,0,   1, 1
	; db	 1, 1,  0, 1,   0, 1,   0, 0
; -----------------------------------------------------------------------------

; EOF