;
; =============================================================================
;	Default enemy types (platformer game)
;	Convenience enemy state handlers (platformer game)
;	Convenience enemy helper routines (platform games)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Enemy flags (as bit indexes) (platformer game)
	BIT_ENEMY_SOLID:	equ 1 ; (can be killed by solid tiles)
	BIT_ENEMY_DEATH:	equ 2 ; (can be killed by death tiles)
	
; Enemy flags (as flags)
	FLAG_ENEMY_SOLID:	equ (1 << BIT_ENEMY_SOLID) ; $02
	FLAG_ENEMY_DEATH:	equ (1 << BIT_ENEMY_DEATH) ; $04
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stationary: The enemy does not move at all
ENEMY_TYPE_STATIONARY:
; The enemy does not move
	dw	PUT_ENEMY_SPRITE
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stationary (animated): The enemy does not move at all
.ANIMATED:
; The enemy does not move
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Flyer: The enemy flies (or foats),
; then turns around and continues
ENEMY_TYPE_FLYER:
; The enemy flies
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FLYER_ENEMY_HANDLER
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker: the enemy walks along the ground
; (see also: Pacer)
ENEMY_TYPE_WALKER:
; The enemy walks ahead
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	db	(1 << BIT_WORLD_FLOOR)
	dw	FLYER_ENEMY_HANDLER ; (flyer to fall when reaching edges)
; then turns around and continues
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Follower: The enemy follows the player (Often used in top-down games).
.FOLLOWER:
; The enemy pauses briefly
	dw	PUT_ENEMY_SPRITE
	dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	dw	WAIT_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M ; medium pause
; then turns towards the player
	dw	TURN_ENEMY.TOWARDS_PLAYER
	dw	SET_NEW_STATE_HANDLER.NEXT
; walks ahead along the ground a medium distance
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	dw	FLYER_ENEMY_HANDLER.RANGED
	db	CFG_ENEMY_PAUSE_M ; medium distance
; and continues
	dw	SET_NEW_STATE_HANDLER
	dw	.FOLLOWER ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Faller: The enemy falls from the ceiling onto the ground.
ENEMY_TYPE_FALLER:
; The enemy falls onto the ground
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FALLER_ENEMY_HANDLER
	db	(1 << BIT_WORLD_SOLID)
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Faller (with trigger): The enemy falls onto the ground
; when the player x coordinate overlaps with the enemy's
.TRIGGERED:
; The enemy waits until the player overlaps x coordinate
	dw	PUT_ENEMY_SPRITE
	dw	WAIT_ENEMY_HANDLER.X_COLLISION
	db	PLAYER_ENEMY_X_SIZE + CFG_ENEMY_ADVANCE_COLLISION * 2
	dw	WAIT_ENEMY_HANDLER.PLAYER_BELOW
	dw	SET_NEW_STATE_HANDLER.NEXT
; then the enemy falls onto the ground
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FALLER_ENEMY_HANDLER
	db	(1 << BIT_WORLD_SOLID)
	dw	SET_NEW_STATE_HANDLER.NEXT
; then rises back up
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	RISER_ENEMY_HANDLER
	db	(1 << BIT_WORLD_SOLID)
	dw	SET_NEW_STATE_HANDLER
	dw	.TRIGGERED ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Riser: The enemy can increase its height.
ENEMY_TYPE_RISER:
; The enemy rises up to the ceiling
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	RISER_ENEMY_HANDLER
	db	(1 << BIT_WORLD_SOLID)
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Riser (with trigger): The enemy increases its height
; when the player x coordinate overlaps with the enemy's
.TRIGGERED:
; The enemy waits until the player overlaps x coordinate
	dw	PUT_ENEMY_SPRITE
	dw	WAIT_ENEMY_HANDLER.X_COLLISION
	db	PLAYER_ENEMY_X_SIZE + CFG_ENEMY_ADVANCE_COLLISION * 2
	dw	WAIT_ENEMY_HANDLER.PLAYER_ABOVE
; then the enemy rises up to the ceiling
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	RISER_ENEMY_HANDLER
	db	(1 << BIT_WORLD_SOLID)
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Jumper: The enemy bounces or jumps.
ENEMY_TYPE_JUMPER:
; The enemy bounces or jumps
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	JUMPER_ENEMY_HANDLER
	db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Jumper (with trigger): The enemy bounces or jumps
; when the player x coordinate overlaps with the enemy's
.TRIGGERED:
; The enemy waits until the player overlaps x coordinate
	dw	PUT_ENEMY_SPRITE
	dw	WAIT_ENEMY_HANDLER.X_COLLISION
	db	PLAYER_ENEMY_X_SIZE + CFG_ENEMY_ADVANCE_COLLISION * 2
	dw	SET_NEW_STATE_HANDLER.NEXT
; then the enemy bounces or jumps
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	JUMPER_ENEMY_HANDLER
	db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	dw	SET_NEW_STATE_HANDLER
	dw	.TRIGGERED ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Ducker - The enemy can reduce its height (including, melting into the floor).
; Example: Super Mario's Piranha Plants
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sticky - The enemy sticks to walls and ceilings.
; Example: Super Mario 2's Spark
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Waver: The enemy floats in a sine wave pattern.
ENEMY_TYPE_WAVER:
; The enemy floats in a sine wave pattern
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	WAVER_ENEMY_HANDLER
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Flyer + waver: The enemy flies (or foats) in a sine wave pattern,
; then turns around and continues
ENEMY_TYPE_FLYER_WAVER:
ENEMY_TYPE_WAVER_FLYER:
; The enemy flies
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FLYER_ENEMY_HANDLER
; in a sine wave pattern
	dw	WAVER_ENEMY_HANDLER
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Rotator - The enemy rotates around a fixed point.
; Sometimes, the fixed point moves, and can move according to any movement attribute in this list.
; Also, the rotation direction may change.
; Example: Super Mario 3's Rotodisc,
; These jetpack enemeis from Sunsoft's Batman (notice that the point which they rotate around is the player)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Swinger - The enemy swings from a fixed point.
; Example: Castlevania's swinging blades
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pacer: The enemy changes direction in response to a trigger
; (like reaching the edge of a platform) (see also: Walker)
ENEMY_TYPE_PACER:
; The enemy walks ahead
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	db	(1 << BIT_WORLD_FLOOR)
	dw	WALKER_ENEMY_HANDLER
; then turns around and continues
	dw	TURN_ENEMY
	dw	END_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pacer (with pauses): When reaching the edge of a platform,
; the enemy pauses, turning around, then changes direction and continues
.PAUSED:
; The enemy walks ahead
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	dw	WALKER_ENEMY_HANDLER.NOTIFY
	dw	SET_NEW_STATE_HANDLER.NEXT
; then pauses, turning around
	dw	PUT_ENEMY_SPRITE
	dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	dw	WAIT_ENEMY_HANDLER.TURNING
	db	(2 << 6) OR CFG_ENEMY_PAUSE_M ; 3 (even) times, medium pause
; and continues
	dw	SET_NEW_STATE_HANDLER
	dw	.PAUSED ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Follower: The enemy follows the player (Often used in top-down games).
.FOLLOWER:
; The enemy pauses briefly
	dw	PUT_ENEMY_SPRITE
	dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	dw	WAIT_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M ; medium pause
; then turns towards the player
	dw	TURN_ENEMY.TOWARDS_PLAYER
	dw	SET_NEW_STATE_HANDLER.NEXT
; walks ahead along the ground a medium distance
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	FALLER_ENEMY_HANDLER ; (falls if not on the floor)
	db	(1 << BIT_WORLD_SOLID) OR (1 << BIT_WORLD_FLOOR)
	dw	WALKER_ENEMY_HANDLER.RANGED
	db	CFG_ENEMY_PAUSE_M ; medium distance
; and continues
	dw	SET_NEW_STATE_HANDLER
	dw	.FOLLOWER ; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Roamer - The enemy changes direction completely randomly.
; Example: Legend of Zelda's Octoroks
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Liner - The enemy moves directly to a spot on the screen.
; Forgot to record the enemies I saw doing this, but usually they move from one spot to another in straight lines,
; sometimes randomly, other times, trying to 'slice' through the player.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Teleporter - The enemy can teleport from one location to another.
; Example: Zelda's Wizrobes
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Dasher - The enemy dashes in a direction, faster than its normal movement speed.
; Example: Zelda's Rope Snakes
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Ponger - The enemy ignores gravity and physics, and bounces off walls in straight lines.
; Example: Zelda 2's "Bubbles"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Geobound - The enemy is physically stuck to the geometry of the level, sometimes appears as level geometry.
; Examples: Megaman's Spikes, Super Mario's Piranha Plants, CastleVania's White Dragon
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Tethered - The enemy is tethered to the level's geometry by a chain or a rope.
; Example: Super Mario's Chain Chomps
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Swooper - A floating enemy that swoops down, often returning to its original position, but not always.
; Example: Castlevania's Bats, Super Mario's Swoopers, Super Mario 3's Angry Sun
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Killed: the enemy has been killed. Shows the dying animation
; and respawns the enemy after a pause
ENEMY_TYPE_KILLED:
; Shows the dying pattern
	dw	PUT_ENEMY_SPRITE_PATTERN
	db	CFG_ENEMY_DYING_PATTERN
	dw	WAIT_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_S ; short pause
	dw	SET_NEW_STATE_HANDLER.NEXT
; Pause
	dw	WAIT_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_L ; long wait
	dw	INIT_RESPAWN_ENEMY_HANDLER
	dw	SET_NEW_STATE_HANDLER.NEXT
; Shows the respawning animation
	dw	PUT_ENEMY_SPRITE_ANIM
	dw	WAIT_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_L ; long wait
; Actually respawns the enemy
	dw	RESPAWN_ENEMY_HANDLER
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Convenience enemy state handlers (platformer game)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Flyer state handler: The enemy flies (or floats),
; turning around when the wall is hit
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret a: always continue (2)
FLYER_ENEMY_HANDLER:
; Checks wall
	call	CAN_ENEMY_FLY
	jp	z, TURN_ENEMY ; yes: turns around
; no: moves the enemy
	call	MOVE_ENEMY
; ret 2 (continue with next state handler)
	ld	a, 2
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Flyer state handler: The enemy flies (or floats), until a wall is hit
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret a: continue (2) if a wall has been hit, halt (0) otherwise
.NOTIFY:
; Checks wall
	call	CAN_ENEMY_FLY
	jp	z, END_ENEMY_HANDLER ; yes
; no: moves the enemy
	call	MOVE_ENEMY
; ret halt (0)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Flyer state handler: The enemy flies (or floats) a number of pixels or
; until a wall is hit
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; param [iy + ENEMY_STATE.ARGS]: distance (frames/pixels) (0 = forever)
; ret a: continue (3) if a wall has been hit, halt (0) otherwise
.RANGED:
; Checks wall
	call	CAN_ENEMY_FLY
	jp	z, CONTINUE_ENEMY_HANDLER.ONE_ARG ; no
; yes: moves the enemy
	call	MOVE_ENEMY
; increases frame counter, compares with argument, and ret 3/0
	jp	WAIT_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker state handler: the enemy walks ahead along the ground,
; turning around when the wall is hit or at the end of the platform
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret a: always continue (2)
WALKER_ENEMY_HANDLER:
; Checks floor (or wall)
	call	CAN_ENEMY_WALK
	jp	z, TURN_ENEMY ; no: turns around
; yes: moves the enemy
	call	MOVE_ENEMY
; ret 2 (continue with next state handler)
	ld	a, 2
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker state handler: the enemy walks ahead along the ground,
; until a wall is hit or the end of the platform is reached
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret a: continue (2) if a wall has been hit, halt (0) otherwise
.NOTIFY:
; Checks floor (or wall)
	call	CAN_ENEMY_WALK
	jp	z, CONTINUE_ENEMY_HANDLER.NO_ARGS ; no
; yes: moves the enemy
	call	MOVE_ENEMY
; ret halt (0)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker state handler: the enemy walks ahead a number of pixels along the ground
; or until a wall is hit, the end of the platform is reached
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; param [iy + ENEMY_STATE.ARGS]: distance (frames/pixels) (0 = forever)
; ret a: continue (3) if a wall has been hit, halt (0) otherwise
.RANGED:
; Checks floor (or wall)
	call	CAN_ENEMY_WALK
	jp	z, CONTINUE_ENEMY_HANDLER.ONE_ARG ; no
; yes: moves the enemy
	call	MOVE_ENEMY
; increases frame counter, compares with argument, and ret 3/0
	jp	WAIT_ENEMY_HANDLER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Faller state handler: the enemy falls onto the ground.
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARG_0]: mask of tile flags to check
; ret a: continue (3) if already on the ground, halt (0) otherwise
FALLER_ENEMY_HANDLER:
; Has fallen onto the ground?
	call	GET_ENEMY_TILE_FLAGS_UNDER
	and	[iy + ENEMY_STATE.ARG_0]
	jp	z, .FALL ; no
; yes: resets Delta-Y (dY) table index
	xor	a
	ld	[ix + enemy.dy_index], 0
; ret continue (3)
	ld	a, 3
	ret

.FALL:
; Computes falling speed	
	ld	a, [ix + enemy.dy_index]
	inc	[ix + enemy.dy_index]
	add	ENEMY_DY_TABLE.FALL_OFFSET
	call	READ_FALLER_ENEMY_DY_VALUE
; moves down
	add	[ix + enemy.y]
	ld	[ix + enemy.y], a
; ret halt (0)
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Riser: The enemy can increase its height.
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARG_0]: mask of tile flags to check
; ret a: continue (3) if already reached the ceiling, halt (0) otherwise
RISER_ENEMY_HANDLER:
; Has reached the ceiling?
	call	GET_ENEMY_TILE_FLAGS_ABOVE
	and	[iy + ENEMY_STATE.ARG_0]
	jp	nz, CONTINUE_ENEMY_HANDLER.ONE_ARG ; yes
; no: moves up
	dec	[ix + enemy.y]
; ret halt (0)
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
; Jumper: The enemy bounces or jumps.
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state
; param [iy + ENEMY_STATE.ARG_0]: (ignored)
; ret z/nz: if the state has finished
JUMPER_ENEMY_HANDLER:
	ld	a, [ix + enemy.dy_index]
	cp	ENEMY_DY_TABLE.SIZE -1
	jr	z, .DY_MAX ; yes
; increases frame counter
	inc	[ix + enemy.dy_index]
.DY_MAX:
	ld	hl, ENEMY_DY_TABLE
	call	GET_HL_A_BYTE
	ld	b, a
	
	add	[ix + enemy.y]
	ld	[ix + enemy.y], a
	
	ld	a, b
	or	a
	jp	m, END_ENEMY_HANDLER ; no

; Has fallen onto the ground?
	call	GET_ENEMY_TILE_FLAGS_UNDER
	and	[iy + ENEMY_STATE.ARG_0]
	jp	z, END_ENEMY_HANDLER ; no
	
; yes
	xor	a
	ld	[ix + enemy.dy_index], a
	
; ret 3 (continue with next state handler)
	ld	a, 3
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Waver: The enemy floats in a sine wave pattern.
; param ix: pointer to the current enemy
; param iy: pointer to the current enemy state (ignored)
; ret a: always continue (2)
WAVER_ENEMY_HANDLER:
; Reads the dy
	call	READ_WAVER_ENEMY_DY_VALUE
	inc	[ix + enemy.dy_index]
; Applies the dy
	add	[ix + enemy.y]
	ld	[ix + enemy.y], a
; ret 2 (continue with next state handler)
	ld	a, 2
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
	cp	ENEMY_DY_TABLE.SIZE
	jr	c, .FROM_TABLE
	ld	a, CFG_ENEMY_GRAVITY
	ret
	
.FROM_TABLE:
	ld	hl, ENEMY_DY_TABLE
	jp	GET_HL_A_BYTE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param ix: pointer to the current enemy
; ret a: the dy (-1, 0 or 1)
READ_WAVER_ENEMY_DY_VALUE:
	ld	a, [ix + enemy.dy_index]
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; param a: the frame counter (or index)
; ret a: the dy (-1, 0 or 1)
READ_WAVER_DY_VALUE:
	ld	hl, .WAVER_LUT_TABLE
; Is the 5th bit set? (32..63)
	bit	5, a
	jr	z, .NEGATE ; no: negate the table value
; yes: read the table value	
	and	$1f ; (0..31)
	jp	GET_HL_A_BYTE
.NEGATE:
; read the table value
	and	$1f ; (0..31)
	call	GET_HL_A_BYTE
; and return it negated
	neg
	ret
	
.WAVER_LUT_TABLE:
	db	0, 1, 0, 0,   1, 0, 1, 0,   1, 1, 1, 0,   1, 1, 1, 1
	db	0, 1, 1, 1,   0, 1, 0, 1,   0, 0, 1, 0,   0, 0, 0, 0
; -----------------------------------------------------------------------------

; EOF