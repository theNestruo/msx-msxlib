
; =============================================================================
;	Spriteables routines (2x2 chars that eventually become a sprite)
; =============================================================================

	CFG_RAM_SPRITEABLES:	equ 1

; -----------------------------------------------------------------------------
; Symbolic constants for spriteables
	MASK_SPRITEABLE_STATUS:		equ $f0 ; actual status
	MASK_SPRITEABLE_DIRECTION:	equ $70 ; direction (inside status)
	MASK_SPRITEABLE_PENDING:	equ $0f ; pending movement (in pixels)
	BIT_SPRITEABLE_DISABLED:	equ 7

	SPRITEABLE_PENDING_0:		equ 8 ; 8 pixels (= 1 tile)

	SPRITEABLE_IDLE:		equ $00 ; no movement, but can be moved
	SPRITEABLE_MOVING_UP:		equ $10
	SPRITEABLE_MOVING_DOWN:		equ $20
	SPRITEABLE_MOVING_RIGHT:	equ $30
	SPRITEABLE_MOVING_LEFT:		equ $40
	SPRITEABLE_STOPPING:		equ $70 ; marker direction value for "stopping in this frame"
	SPRITEABLE_DISABLED:		equ $80 ; no movement, and cannot be moved
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Zeroes the spriteable array entirely (count and array)
RESET_SPRITEABLES:
	ld	hl, spriteables
	ld	de, spriteables +1
	ld	bc, spriteables.SIZE -1
	ld	[hl], 0
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a spriteable
; param hl: NAMTBL buffer pointer to the upper left character
; param a: initial background character
; ret ix: address of the spriteable (to set sprite pattern and color)
INIT_SPRITEABLE:
	push	af ; preserves background character
	ex	de, hl ; NAMTBL buffer pointer in de
; Translates NAMTBL buffer pointer into NAMTBL offset
	ld	hl, -namtbl_buffer +$10000
	add	hl, de ; NAMTBL offset in hl
; Adds an element to the array
	ld	ix, spriteables.count
	ld	c, SPRITEABLE_SIZE
	call	ADD_ARRAY_IX
; Sets the initial status
	xor	a ; 0 = SPRITEABLE_IDLE
	ld	[ix + _SPRITEABLE_STATUS], a
; Saves the NAMTBL offset
	ld	[ix + _SPRITEABLE_OFFSET_L], l
	ld	[ix + _SPRITEABLE_OFFSET_H], h
; Saves the first foreground character
	ld	a, [de]
	ld	[ix + _SPRITEABLE_FOREGROUND], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +1], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +2], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +3], a
; Initializes background characters
	pop	af ; restores background character
	ld	[ix + _SPRITEABLE_BACKGROUND], a
	ld	[ix + _SPRITEABLE_BACKGROUND +1], a
	ld	[ix + _SPRITEABLE_BACKGROUND +2], a
	ld	[ix + _SPRITEABLE_BACKGROUND +3], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Locates a spriteable by logical coordinates
; param de: logical coordinates (x, y)
; ret ix: pointer to the spriteable
GET_SPRITEABLE_COORDS:
; Translates logical coordinates in NAMTBL offset
	call	COORDS_TO_OFFSET
; Adjusts for the upper left character
	ld	de, -SCR_WIDTH -SCR_WIDTH -1 ; (-1, -2)
	add	hl, de
	ex	de, hl ; NAMTBL offset in de
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Locates a spriteable by its NAMTBL offset (upper left character)
; param de: NAMTBL offset
; ret ix: pointer to the spriteable
GET_SPRITEABLE_OFFSET:
; Travels the spriteable array
	ld	ix, spriteables.array
.LOOP:
; Compares offsets
	ld	a, [ix +_SPRITEABLE_OFFSET_L]
	cp	e
	jr	nz, .NEXT ; no match
	ld	a, [ix +_SPRITEABLE_OFFSET_H]
	cp	d
	ret	z ; match

; no match: next element
.NEXT:
	ld	bc, SPRITEABLE_SIZE
	add	ix, bc
	jr	.LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; (convenience routine to optimize size)
; Sets new status, removes the spriteable from the NAMTBL (both VRAM and buffer),
; and reads the NAMTBL offset
; param ix: pointer to the current spriteable
; param a: new status
; ret hl: NAMTBL offset
MOVE_SPRITEABLE_1:
; Reads the old status in b
	ld	b, [ix +_SPRITEABLE_STATUS]

; Sets new status
	ld	[ix +_SPRITEABLE_STATUS], a

; If the spriteable already had a direction, it was already moving:
; the foreground is not actually in the NAMTBL, so there is no need to erase it
; Otherwise, erases the spriteable from the NAMTBL (VPOKEs)
	ld	a, b ; (restores the old status)
	or	a
	call	z, VPOKE_SPRITEABLE_BACKGROUND ; erases the spriteable from the NAMTBL

; Removes the spriteable from the NAMTBL buffer
	call	NAMTBL_BUFFER_SPRITEABLE_BACKGROUND
; Updates NAMTBL offset
	ld	l, [ix +_SPRITEABLE_OFFSET_L]
	ld	h, [ix +_SPRITEABLE_OFFSET_H]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts moving a spriteable down
; (note: does not show the spriteable sprite)
; param ix: pointer to the current spriteable
MOVE_SPRITEABLE_DOWN:
; Sets new status, removes the spriteable from NAMTBL VRAM and buffer
	ld	a, SPRITEABLE_MOVING_DOWN OR SPRITEABLE_PENDING_0
	call	MOVE_SPRITEABLE_1
; Updates NAMTBL offset
	ld	bc, SCR_WIDTH
	add	hl, bc
; Shows the spriteable sprite and puts the spriteable in the NAMTBL buffer
	jr	MOVE_SPRITEABLE_2
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts moving a spriteable to the right
; (note: does not show the spriteable sprite)
; param ix: pointer to the current spriteable
MOVE_SPRITEABLE_RIGHT:
; Sets new status, removes the spriteable from NAMTBL VRAM and buffer
	ld	a, SPRITEABLE_MOVING_RIGHT OR SPRITEABLE_PENDING_0
	call	MOVE_SPRITEABLE_1
; Updates NAMTBL offset
	inc	hl
; Shows the spriteable sprite and puts the spriteable in the NAMTBL buffer
	jr	MOVE_SPRITEABLE_2
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts moving a spriteable to the left
; (note: does not show the spriteable sprite)
; param ix: pointer to the current spriteable
MOVE_SPRITEABLE_LEFT:
; Sets new status, removes the spriteable from NAMTBL VRAM and buffer
	ld	a, SPRITEABLE_MOVING_LEFT OR SPRITEABLE_PENDING_0
	call	MOVE_SPRITEABLE_1
; Updates NAMTBL offset
	dec	hl
; Shows the spriteable sprite and puts the spriteable in the NAMTBL buffer
	; jr	MOVE_SPRITEABLE_2 ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; (convenience routine to optimize size)
; Saves NAMTBL offset and puts the spriteable back in the NAMTBL buffer (only)
; (but does not show the spriteable sprite!)
; param ix: pointer to the current spriteable
; param hl: NAMTBL offset
MOVE_SPRITEABLE_2:
; Saves NAMTBL offset
	ld	[ix +_SPRITEABLE_OFFSET_L], l
	ld	[ix +_SPRITEABLE_OFFSET_H], h
; Puts the spriteable back in the NAMTBL buffer (only)
	; jp	NAMTBL_BUFFER_SPRITEABLE_FOREGROUND ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Puts back the spriteable in the NAMTBL buffer (only),
; saving the current background characters
; param ix: pointer to the current spriteable
NAMTBL_BUFFER_SPRITEABLE_FOREGROUND:
	ld	l, [ix +_SPRITEABLE_OFFSET_L]
	ld	h, [ix +_SPRITEABLE_OFFSET_H]
	ld	de, namtbl_buffer
	add	hl, de ; NAMTBL buffer pointer in hl
; Upper left character
	ld	a, [hl]
	ld	[ix +_SPRITEABLE_BACKGROUND +0], a
	ld	b, [ix +_SPRITEABLE_FOREGROUND]
	ld	[hl], b
; Upper right character
	inc	hl
	ld	a, [hl]
	ld	[ix +_SPRITEABLE_BACKGROUND +1], a
	inc	b
	ld	[hl], b
; Lower left character
	ld	de, SCR_WIDTH -1
	add	hl, de
	ld	a, [hl]
	ld	[ix +_SPRITEABLE_BACKGROUND +2], a
	inc	b
	ld	[hl], b
; Lower right character
	inc	hl
	ld	a, [hl]
	ld	[ix +_SPRITEABLE_BACKGROUND +3], a
	inc	b
	ld	[hl], b
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sets the spriteable background in the NAMTBL buffer (only)
; (i.e.: removes the spriteable characters)
; param ix: pointer to the current spriteable
NAMTBL_BUFFER_SPRITEABLE_BACKGROUND:
	ld	l, [ix +_SPRITEABLE_OFFSET_L]
	ld	h, [ix +_SPRITEABLE_OFFSET_H]
	ld	de, namtbl_buffer
	add	hl, de ; NAMTBL buffer pointer in hl
; Upper left character
	ld	a, [ix +_SPRITEABLE_BACKGROUND +0]
	ld	[hl], a
; Upper right character
	inc	hl
	ld	a, [ix +_SPRITEABLE_BACKGROUND +1]
	ld	[hl], a
; Lower left character
	ld	de, SCR_WIDTH -1
	add	hl, de
	ld	a, [ix +_SPRITEABLE_BACKGROUND +2]
	ld	[hl], a
; Lower right character
	inc	hl
	ld	a, [ix +_SPRITEABLE_BACKGROUND +3]
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the spriteables in movement
UPDATE_SPRITEABLES:
; For each spriteable
	ld	ix, spriteables.count
	ld	c, SPRITEABLE_SIZE
	ld	hl, .ROUTINE
	jp	FOR_EACH_ARRAY_IX

; param ix: pointer to the current spriteable
.ROUTINE:
; Checks direction
	ld	a, [ix + _SPRITEABLE_STATUS]
	ld	b, a ; preserves status
	and	MASK_SPRITEABLE_DIRECTION
	ret	z ; no direction
; Checks pending movement
	ld	a, b ; restores status
	and	MASK_SPRITEABLE_PENDING
	jr	z, .STOP ; no pending movement
; Pending movement: decreases the counter
	dec	[ix + _SPRITEABLE_STATUS]
	ret

; No pending movement
.STOP:
; Sets the marker value
	ld	a, b ; restores status
	or	SPRITEABLE_STOPPING ; "stopping in this frame"
	ld	[ix + _SPRITEABLE_STATUS], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Draws the updated spriteables, either as sprites or as foreground VPOKEs
DRAW_SPRITEABLES:
; For each spriteable
	ld	ix, spriteables.count
	ld	c, SPRITEABLE_SIZE
	ld	hl, .ROUTINE
	jp	FOR_EACH_ARRAY_IX

; param ix: pointer to the current spriteable
.ROUTINE:
; Is the spriteable still moving?
	ld	a, [ix + _SPRITEABLE_STATUS]
	ld	b, a ; (preserves the status)
	and	MASK_SPRITEABLE_DIRECTION
	ret	z ; no: idle or disabled
; yes: Is the spriteable stopping in this frame?
	cp	SPRITEABLE_STOPPING ; (checks marker value)
	jp	nz, PUT_SPRITEABLE_SPRITE ; no: puts the sprite
; yes: Stops the spriteable
	ld	a, b ; (restores the status)
	and	SPRITEABLE_DISABLED ; either $00 (idle) or $80 (disabled)
	ld	[ix + _SPRITEABLE_STATUS], a
; VPOKEs the foreground
	jp	VPOKE_SPRITEABLE_FOREGROUND
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Shows the spriteable sprite
; param ix: pointer to the current spriteable
PUT_SPRITEABLE_SPRITE:
; Reads physical sprite coordinates at the end of the movement
	ld	e, [ix +_SPRITEABLE_OFFSET_L]
	ld	d, [ix +_SPRITEABLE_OFFSET_H]
	call	OFFSET_TO_COORDS
; Translates (y, x) into (x, y) (i.e.: swaps d and e)
	ld	a, e
	ld	e, d
	ld	d, a
	dec	e ; (y pixel adjust)
; Checks pending movement
	ld	a, [ix +_SPRITEABLE_STATUS]
	ld	b, a ; preserves status
	and	MASK_SPRITEABLE_PENDING
	jr	z, .DE_OK ; no

; Coordinates adjust depending on the direction
	ld	c, a ; preserves pending movement
	ld	a, b ; restores status
	and	MASK_SPRITEABLE_DIRECTION
	cp	SPRITEABLE_MOVING_RIGHT
	jr	c, .UP_OR_DOWN ; direction < RIGHT, ergo UP or DOWN
; direction >= RIGHT, ergo RIGHT or LEFT
	cp	SPRITEABLE_MOVING_LEFT
	jr	c, .RIGHT

; left: x += pending movement
	ld	a, d
	add	c
	ld	d, a
	jr	.DE_OK

.RIGHT:
; right: x -= pending movement
	ld	a, d
	sub	c
	ld	d, a
	jr	.DE_OK

.UP_OR_DOWN:
	cp	SPRITEABLE_MOVING_DOWN
	jr	c, .UP

; down: y -= pending movement
	ld	a, e
	sub	c
	ld	e, a
	jr	.DE_OK

.UP:
; up: y += pending movement
	ld	a, e
	add	c
	ld	e, a
	; jr	.DE_OK ; falls through

.DE_OK:
	ld	c, [ix + _SPRITEABLE_PATTERN]
	ld	b, [ix + _SPRITEABLE_COLOR]
	jp	PUT_SPRITE_NO_OFFSET
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sets the spriteable foreground in the NAMTBL (VRAM only)
; param ix: pointer to the current spriteable
VPOKE_SPRITEABLE_FOREGROUND:
; Upper left character
	ld	l, [ix +_SPRITEABLE_OFFSET_L]
	ld	h, [ix +_SPRITEABLE_OFFSET_H]
	ld	a, [ix +_SPRITEABLE_FOREGROUND]
	call	VPOKE_SPRITEABLE_FIRST
; Upper right character
	inc	hl
	ld	a, [ix +_SPRITEABLE_FOREGROUND +1]
	call	VPOKE_SPRITEABLE_NEXT
; Lower left character
	ld	de, SCR_WIDTH -1
	add	hl, de
	ld	a, [ix +_SPRITEABLE_FOREGROUND +2]
	call	VPOKE_SPRITEABLE_NEXT
; Lower right character
	inc	hl
	ld	a, [ix +_SPRITEABLE_FOREGROUND +3]
	jr	VPOKE_SPRITEABLE_NEXT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sets the spriteable background in the NAMTBL (VRAM only)
; param ix: pointer to the current spriteable
VPOKE_SPRITEABLE_BACKGROUND:
; Upper left character
	ld	l, [ix +_SPRITEABLE_OFFSET_L]
	ld	h, [ix +_SPRITEABLE_OFFSET_H]
	ld	a, [ix +_SPRITEABLE_BACKGROUND +0]
	call	VPOKE_SPRITEABLE_FIRST
; Upper right character
	inc	hl
	ld	a, [ix +_SPRITEABLE_BACKGROUND +1]
	call	VPOKE_SPRITEABLE_NEXT
; Lower left character
	ld	de, SCR_WIDTH -1
	add	hl, de
	ld	a, [ix +_SPRITEABLE_BACKGROUND +2]
	call	VPOKE_SPRITEABLE_NEXT
; Lower right character
	inc	hl
	ld	a, [ix +_SPRITEABLE_BACKGROUND +3]
	jr	VPOKE_SPRITEABLE_NEXT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; (convenience routine to optimize size)
; Adds a "vpoke" to the array, using NAMTBL offset, preserving IX
; param hl: NAMTBL offset
; param a: value to write
; ret hl: NAMTBL address
VPOKE_SPRITEABLE_FIRST:
; Translates NAMTBL offset into NAMTBL address
	ld	de, +NAMTBL
	add	hl, de
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; (convenience routine to optimize size)
; Adds a "vpoke" to the array, using NAMTBL address, preserving IX
; param hl: NAMTBL address
; param a: value to write
VPOKE_SPRITEABLE_NEXT:
	push	ix
	call	VPOKE_NAMTBL_ADDRESS
	pop	ix
	ret
; -----------------------------------------------------------------------------

; EOF
