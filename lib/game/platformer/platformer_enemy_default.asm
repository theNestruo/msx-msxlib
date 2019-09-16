;
; =============================================================================
;	Additional default enemy types (platformer game)
;	Convenience enemy state handlers (platformer game)
;	Specific enemy helper routines (platform games)
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
;  Stationary: The enemy does no move at all
ENEMY_TYPE_STATIONARY:	equ PUT_ENEMY_SPRITE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
;  Stationary: The enemy does no move at all
.ANIMATED:	equ PUT_ENEMY_SPRITE_ANIMATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker: the enemy walks along the ground (see also: Pacer)
ENEMY_TYPE_WALKER:
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM ; (puts sprite and ends)
; Walks along the ground then turns around
	; jp	ENEMY_TYPE_FLYER ; (flyer to keep walking beyond edges) ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Flyer: The enemy flies (or foats),
; then turns around and continues
ENEMY_TYPE_FLYER:
	call	PUT_ENEMY_SPRITE_ANIMATE
	; jp	.HANDLER ; falls through

.HANDLER:
; Checks wall
	call	CAN_ENEMY_FLY
	jp	nz, MOVE_ENEMY ; no: moves the enemy
IFEXIST ENEMY_TYPE_KILLED
	call	TURN_ENEMY ; yes: turns around
; Is the enemy trapped between two walls?
	call	CAN_ENEMY_FLY
	ret	nz ; no
	jp	KILL_ENEMY ; yes: kills the enemy
ELSE
	jp	TURN_ENEMY ; yes: turns around
ENDIF ; IFEXIST ENEMY_TYPE_KILLED
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walker + Follower: The enemy follows the player (see also: Pacer + Follower)
ENEMY_TYPE_WALKER.FOLLOWER:
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Pauses briefly
	call	PUT_ENEMY_SPRITE
	ld	b, CFG_ENEMY_PAUSE_M ; medium pause
	call	WAIT_ENEMY_HANDLER
	ret	nz
; Then turns towards the player
	call	TURN_ENEMY.TOWARDS_PLAYER
	call	SET_ENEMY_STATE.NEXT ; (end)
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Walks ahead along the ground a medium distance
	call	PUT_ENEMY_SPRITE_ANIMATE
	ld	b, CFG_ENEMY_PAUSE_M ; medium distance
	call	ENEMY_TYPE_WALKER.RANGED_HANDLER
	ret	nz
; Then continues
	ld	hl, ENEMY_TYPE_WALKER.FOLLOWER ; (restart)
	jp	SET_ENEMY_STATE

; The enemy walks a number of pixels along the ground
; param b: distance (frames/pixels) (0 = forever)
; ret z/nz: z if the distance has been reached, nz otherwise
ENEMY_TYPE_WALKER.RANGED_HANDLER:
; Checks if the distance has been reached
	call	WAIT_ENEMY_HANDLER
	ret	z ; yes
; Checks wall
	call	CAN_ENEMY_FLY
	ret	z; yes
	jp	MOVE_ENEMY ; no: moves the enemy
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Faller: The enemy falls from the ceiling onto the ground.
ENEMY_TYPE_FALLER:
	call	ENEMY_TYPE_FALLER.SOLID_HANDLER
	jp	nz, PUT_ENEMY_SPRITE
	jp	PUT_ENEMY_SPRITE_ANIM

; ret z/nz: z if the player is falling, nz otherwise
.SOLID_HANDLER:
	ld	b, (1 << BIT_WORLD_SOLID)
	jp	.HANDLER

; ret z/nz: z if the player is falling, nz otherwise
.FLOOR_HANDLER:
	ld	b, (1 << BIT_WORLD_FLOOR)
	; jp	.HANDLER ; falls through

; param b: mask of tile flags to check
; ret z/nz: z if the player is falling, nz otherwise
.HANDLER:
; Has fallen onto the ground?
	call	GET_ENEMY_TILE_FLAGS_UNDER
	and	b
	jp	z, .DO_FALL ; no
; yes: resets Delta-Y (dY) table index
	ld	[ix + enemy.dy_index], 0
	ret	; (ret nz)

.DO_FALL:
; Computes falling speed
	ld	a, [ix + enemy.dy_index]
	inc	[ix + enemy.dy_index]
	add	ENEMY_DY_TABLE.FALL_OFFSET
	call	READ_FALLER_ENEMY_DY_VALUE
; moves down
	add	[ix + enemy.y]
	ld	[ix + enemy.y], a
; ret z
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Riser: The enemy can increase its height.
ENEMY_TYPE_RISER:
	call	PUT_ENEMY_SPRITE_ANIMATE
; The enemy rises up to the ceiling
	; jp	.SOLID_HANDLER ; (falls through)

; ret z/nz: nz if already reached the ceiling, z otherwise
.SOLID_HANDLER:
	ld	b, (1 << BIT_WORLD_SOLID)
	; jp	.HANDLER ; falls through

; param b: mask of tile flags to check
; ret z/nz: nz if already reached the ceiling, z otherwise
.HANDLER:
; Has reached the ceiling?
	call	GET_ENEMY_TILE_FLAGS_ABOVE
	and	b
	ret	nz ; yes
; no: moves up
	dec	[ix + enemy.y]
; ret z
	xor	a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Jumper: The enemy bounces or jumps.
ENEMY_TYPE_JUMPER:
; The enemy bounces or jumps
	call	PUT_ENEMY_SPRITE_ANIM
	; jp	.DEFAULT_HANDLER ; falls through

; ret z/nz: z if the player is on the floor, nz otherwise
.DEFAULT_HANDLER:
	ld	b, (1 << BIT_WORLD_FLOOR)
	; jp	.HANDLER ; falls through

; param b: mask of tile flags to check
; ret z/nz: z if the player is on the floor, nz otherwise
.HANDLER:
	ld	a, [ix + enemy.dy_index]
	cp	ENEMY_DY_TABLE.SIZE -1
	jp	z, .DY_MAX ; yes
; increases frame counter
	inc	[ix + enemy.dy_index]
.DY_MAX:
; Reads the dy
	ld	hl, ENEMY_DY_TABLE
	call	GET_HL_A_BYTE
	ld	c, a ; preserves dy in c
; Applies the dy
	add	[ix + enemy.y]
	ld	[ix + enemy.y], a
; Is the enemy falling?
	ld	a, c ; restores dy
	dec	a
	jp	m, RET_NOT_ZERO ; no
; yes: Has fallen onto the ground?
	call	GET_ENEMY_TILE_FLAGS_UNDER_FAST
	and	b
	jp	z, RET_NOT_ZERO ; no
; yes: ret z
	xor	a
	ld	[ix + enemy.dy_index], a
	ret	; ret z
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
	call	.HANDLER
; Is the wave pattern ascending?
	ld	a, [ix + enemy.dy_index]
	bit	5, a
	jp	z, PUT_ENEMY_SPRITE_ANIM ; yes
	jp	PUT_ENEMY_SPRITE ; no

.HANDLER:
; Reads the dy
	call	READ_WAVER_ENEMY_DY_VALUE
	inc	[ix + enemy.dy_index]
; Applies the dy
	add	[ix + enemy.y]
	ld	[ix + enemy.y], a
	ret
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
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE
; Walks along the ground then turns around
	call	PUT_ENEMY_SPRITE_ANIMATE
	; jp	.DEFAULT_HANDLER ; falls through

; The enemy walks ahead along the ground,
; turning around when the wall is hit or at the end of the platform
.DEFAULT_HANDLER:
; Checks floor (or wall)
	call	CAN_ENEMY_WALK
	jp	nz, MOVE_ENEMY ; yes: moves the enemy
IFEXIST ENEMY_TYPE_KILLED
	call	TURN_ENEMY ; no: turns around
; Is the enemy trapped?
	call	CAN_ENEMY_WALK
	ret	nz ; no
	jp	KILL_ENEMY ; yes: kills the enemy
ELSE
	jp	TURN_ENEMY ; no: turns around
ENDIF ; IFEXIST ENEMY_TYPE_KILLED

; The enemy walks ahead a number of pixels along the ground
; or until a wall is hit, the end of the platform is reached
; param b: distance (frames/pixels) (0 = forever)
; ret z/nz: z if a wall has been hit or the distance has been reached, nz otherwise
.RANGED_HANDLER:
; Checks if the distance has been reached
	call	WAIT_ENEMY_HANDLER
	ret	z ; yes
	; jp	.HANDLER ; falls through

; The enemy walks ahead along the ground,
; until a wall is hit or the end of the platform is reached
; ret z/nz: z if a wall has been hit, nz otherwise
.HANDLER:
; Checks floor (or wall)
	call	CAN_ENEMY_WALK
	ret	z ; no
; yes: moves the enemy
	jp	MOVE_ENEMY
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pacer (with pauses): When reaching the edge of a platform,
; the enemy pauses, turning around, then changes direction and continues
.PAUSED:
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Walks along the ground
	call	PUT_ENEMY_SPRITE_ANIMATE
	call	.HANDLER
	ret	nz
; Then
	call	SET_ENEMY_STATE.NEXT ; (end)
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Pauses, turning around
	call	PUT_ENEMY_SPRITE
	ld	b, (2 << 6) OR CFG_ENEMY_PAUSE_M ; 3 (even) times, medium pause
	call	WAIT_ENEMY_HANDLER.TURNING
	ret	nz
; Then continues
	ld	hl, .PAUSED ; (restart)
	jp	SET_ENEMY_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pacer + Follower: The enemy follows the player (see also: Walker + Follower)
.FOLLOWER:
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Pauses briefly
	call	PUT_ENEMY_SPRITE
	ld	b, CFG_ENEMY_PAUSE_M ; medium pause
	call	WAIT_ENEMY_HANDLER
	ret	nz
; Then turns towards the player
	call	TURN_ENEMY.TOWARDS_PLAYER
	call	SET_ENEMY_STATE.NEXT ; (end)
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Walks ahead along the ground a medium distance
	call	PUT_ENEMY_SPRITE_ANIMATE
	ld	b, CFG_ENEMY_PAUSE_M ; medium distance
	call	ENEMY_TYPE_PACER.RANGED_HANDLER
	ret	nz
; Then continues
	ld	hl, .FOLLOWER ; (restart)
	jp	SET_ENEMY_STATE
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

;
; =============================================================================
;	Specific enemy helper routines (platform games)
; =============================================================================
;

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
	jp	z, .NEGATE ; no: negate the table value
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