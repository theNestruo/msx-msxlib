
; Stationary - The enemy does no move at all.

; Walker - The enemy walks or runs along the ground. Example: Super Mario's Goombas

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


; -----------------------------------------------------------------------------
ENEMY_ROUTINE_CRAWLER:
	dw	EH_PUT_SPRITE_ANIM
	db	0 ; (unused)
	dw	EH_WALK
	db	0 ; forever
	dw	EH_SET_STATE
	db	STATE_SIZE ; next
	
	dw	EH_PUT_SPRITE
	db	0 ; (unused)
	dw	EH_IDLE_TURNING ; EH_IDLE
	db	(2 << 6) OR 30 ; 3 repetitions, 30 frames
	dw	EH_SET_STATE
	db	-5 * STATE_SIZE ; restart
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ENEMY_ROUTINE_FOLLOWER:
	dw	EH_PUT_SPRITE_ANIM
	db	0 ; (unused)
	dw	EH_WALK
	db	32 ; 16 pixels
	dw	EH_SET_STATE
	db	STATE_SIZE ; next
	
	dw	EH_PUT_SPRITE
	db	0 ; (unused)
	dw	EH_IDLE_TURNING
	db	(2 << 6) OR 30 ; 3 repetitions, 30 frames
	dw	EH_TURN_WALKING_ENEMY_TOWARDS_PLAYER
	db	0 ; (unused)
	dw	EH_SET_STATE
	db	-6 * STATE_SIZE ; restart
; -----------------------------------------------------------------------------
