;
; =============================================================================
;	Enemies related routines (generic)
;	Generic enemy state handlers (generic)
;	Enemy-tile helper routines
; =============================================================================
;

	CFG_RAM_ENEMY:	equ 1

; -----------------------------------------------------------------------------
; Bounding box coordinates offset from the logical coordinates
	ENEMY_BOX_X_OFFSET:	equ -(CFG_ENEMY_WIDTH / 2)
	ENEMY_BOX_Y_OFFSET:	equ -CFG_ENEMY_HEIGHT

; Enemy pattern modifiers (as bit indexes)
	BIT_ENEMY_PATTERN_ANIM:	equ 2
	BIT_ENEMY_PATTERN_LEFT:	equ 3

; Enemy pattern modifiers (as flags)
	FLAG_ENEMY_PATTERN_ANIM:	equ (1 << BIT_ENEMY_PATTERN_ANIM) ; $04
	FLAG_ENEMY_PATTERN_LEFT:	equ (1 << BIT_ENEMY_PATTERN_LEFT) ; $08

; Enemy flags (as bit indexes)
	BIT_ENEMY_LETHAL:	equ 0 ; Kills the player on collision

; Enemy flags (as flags)
	FLAG_ENEMY_LETHAL:	equ (1 << BIT_ENEMY_LETHAL) ; $01
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Empties the enemies array
RESET_ENEMIES:
; Fills the array with zeroes
	ld	hl, enemies
	ld	de, enemies +1
	ld	bc, enemies.SIZE -1
	ld	[hl], 0
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a enemy in the first empty enemy slot
; param hl: pointer to the new enemy data (pattern, color, state pointer)
; param de: logical coordinates (x, y)
; ret ix: pointer to the new initialized enemy
; touches: a, hl, de, bc
INIT_ENEMY:
	push	hl ; preserves source data
; Search for the first empty enemy slot
	ld	hl, enemies
	ld	bc, enemy.SIZE
	xor	a ; (marker value: y = 0)
.LOOP:
	cp	[hl]
	jr	z, .INIT ; empty slot found
; Skips to the next element of the array
	add	hl, bc
	jr	.LOOP

.INIT:
; Prepares ret ix: pointer to the new enemy
	push	hl
	pop	ix

	ld	b, h ; preserves target start in bc
	ld	c, l
; Stores the logical coordinates
	ld	[hl], e ; .y
	inc	hl
	ld	[hl], d ; .x
	inc	hl
; Stores the pattern, color and initial handler
	ex	de, hl ; current target in de
	pop	hl ; restores source data in hl
	push	bc ; preserves target start
	ld	bc, 5
	ldir	; .pattern, .color, .flags, .state
; Resets the animation delay and the frame counter
	xor	a
	ld	[de], a ; .animation_delay
	inc	de
	ld	[de], a ; .frame_counter
	inc	de
	ld	[de], a ; .trigger_frame_counter
	inc	de
	ld	[de], a ; .dy_index
; Saves the data for respawning
	pop	hl ; restores target start in hl
	inc	de ; .respawn_data
	ld	bc, enemy.RESPAWN_SIZE
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the enemies
UPDATE_ENEMIES:
; For each enemy in the array
	ld	ix, enemies
	ld	b, CFG_ENEMY_COUNT
.LOOP:
	push	bc ; preserves counter in b
; Is the enemy slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + enemy.y]
	jp	z, .NEXT ; yes
; no: update enemy

IFEXIST KILL_ENEMY
; Reads the tile flags at the enemy coordinates
	call	GET_ENEMY_TILE_FLAGS

IFEXIST BIT_ENEMY_SOLID
; Is the tile solid?
	bit	BIT_WORLD_SOLID, a
	jp	z, .NOT_SOLID ; no
; yes: Is the enemy solid? (the enemy has been crushed)
	bit	BIT_ENEMY_SOLID, [ix + enemy.flags]
	jr	nz, .KILL_ENEMY ; yes
; no
.NOT_SOLID:
ENDIF ; IFEXIST BIT_WORLD_SOLID

; Has the tile the death bit?
	bit	BIT_WORLD_DEATH, a
	jp	z, .NOT_KILLED ; no
; Can the enemy be killed by death tiles?
	bit	BIT_ENEMY_DEATH, [ix + enemy.flags]
	jr	z, .NOT_KILLED ; no
; yes

.KILL_ENEMY:
	call	KILL_ENEMY

.NOT_KILLED:
ENDIF ; IFEXIST KILL_ENEMY

; Dereferences the state pointer of the current enemy
	ld	l, [ix + enemy.state_l]
	ld	h, [ix + enemy.state_h]
; Invokes the current state handler
	call	JP_HL

; Continues with the next enemy
.NEXT:
	ld	bc, enemy.SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------


;
; =============================================================================
;	Generic enemy state handlers (generic)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Sets the next state as the new state
; param ix: pointer to the current enemy
; param [sp]: address of the next state (word)
; (invoke with call SET_ENEMY_STATE.NEXT)
SET_ENEMY_STATE.NEXT:
	pop	hl
	; jr	.HL_OK ; falls through

; Sets an specific address of the next state as the new state
; param ix: pointer to the current enemy
; param hl: address of the next state (word)
SET_ENEMY_STATE:
; Sets the new state as the enemy state
	ld	[ix + enemy.state_l], l
	ld	[ix + enemy.state_h], h
; Resets the animation flag
	res	BIT_ENEMY_PATTERN_ANIM, [ix + enemy.pattern]
.RESET_FRAME_COUNTERS:
; Resets the animation delay and the frame counter
	xor	a
	ld	[ix + enemy.animation_delay], a
	ld	[ix + enemy.frame_counter], a
	; ld	[ix + enemy.trigger_frame_counter], a
	ld	[ix + enemy.dy_index], a
	ret

; Sets the new state as the new state (and the respawning state)
; param ix: pointer to the current enemy
; param hl: address of the next state (word)
.AND_SAVE_RESPAWN:
; Sets the new state
	call	SET_ENEMY_STATE
	; jr	.SAVE_RESPAWN ; falls through

; Saves the current data as the respawning data
; param ix: pointer to the current enemy
.SAVE_RESPAWN:
	push	ix ; hl = ix
	pop	hl
	ld	d, h ; de = hl
	ld	e, l
	ld	a, enemy.respawn_data ; hl += .respawn_data
	call	ADD_HL_A
	ex	de, hl
	ld	bc, enemy.RESPAWN_SIZE
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates animation counter and toggles the animation flag,
; then puts the enemy sprite
; param ix: pointer to the current enemy
PUT_ENEMY_SPRITE_ANIMATE:
; Updates animation counter
	ld	a, [ix + enemy.animation_delay]
	inc	a
	cp	CFG_ENEMY_ANIMATION_DELAY
	jp	nz, .DONT_ANIMATE
; Toggles the animation flag
	ld	a, [ix + enemy.pattern]
	xor	FLAG_ENEMY_PATTERN_ANIM
	ld	[ix + enemy.pattern], a
; Resets animation counter
	xor	a
.DONT_ANIMATE:
	ld	[ix + enemy.animation_delay], a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Puts the enemy sprite
; param ix: pointer to the current enemy
PUT_ENEMY_SPRITE:
	ld	c, [ix + enemy.pattern]
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Puts the enemy sprite using an specific pattern
; param ix: pointer to the current enemy
; param c: the specific pattern
PUT_ENEMY_SPRITE_PATTERN:
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	ld	b, [ix + enemy.color]
	jp	PUT_SPRITE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Puts the enemy sprite with the animation flag on
; param ix: pointer to the current enemy
PUT_ENEMY_SPRITE_ANIM:
	ld	a, [ix + enemy.pattern]
.A_OK:
	or	FLAG_ENEMY_PATTERN_ANIM
	ld	c, a
	jp	PUT_ENEMY_SPRITE_PATTERN
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Removes the current enemy, using the marker value to free the slot
; param ix: pointer to the current enemy
REMOVE_ENEMY:
	xor	a ; (marker value: y = 0)
	ld	[ix + enemy.y], a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Enemy-tile helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Reads the tile flags at the enemy coordinates
; (one pixel above the enemy logical coordinates)
; param ix: pointer to the current enemy
; ret hl: NAMTBL buffer pointer
; ret a: tile flags
; touches de
GET_ENEMY_TILE_FLAGS:
; Enemy coordinates
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	dec	e ; (one pixel above)
; Reads the tile flags
	jp	GET_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the left of the enemy
; param ix: pointer to the current enemy
; ret a: OR-ed tile flags
GET_ENEMY_TILE_FLAGS_LEFT:
	ld	a, ENEMY_BOX_X_OFFSET -1
	jp	GET_ENEMY_V_TILE_FLAGS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of the tiles to the right of the enemy
; param ix: pointer to the current enemy
; ret a: OR-ed tile flags
GET_ENEMY_TILE_FLAGS_RIGHT:
	ld	a, ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
	; jp	GET_ENEMY_V_TILE_FLAGS ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the OR-ed flags of a vertical serie of tiles
; relative to the enemy position
; param ix: pointer to the current enemy
; param a: x-offset from the enemy logical coordinates
; ret a: OR-ed tile flags
; touches: hl, bc, de
GET_ENEMY_V_TILE_FLAGS:
; Enemy coordinates
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
; x += dx
	add	d
	ld	d, a
; y += ENEMY_BOX_Y_OFFSET
	ld	a, e
	add	ENEMY_BOX_Y_OFFSET
	ld	e, a
; Enemy height
	ld	b, CFG_ENEMY_HEIGHT
	jp	GET_V_TILE_FLAGS
; -----------------------------------------------------------------------------

; EOF
