
; =============================================================================
;	"vpoke" routines (deferred WRTVRMs routines)
;	Spriteables routines (2x2 chars that eventually become a sprite)
; =============================================================================


; =============================================================================
;	"vpoke" routines (deferred WRTVRMs routines)
; =============================================================================

IFDEF CFG_VPOKES

; -----------------------------------------------------------------------------
; Symbolic constants for "vpokes"
	_VPOKE_ADDRESS_L:	equ 0
	_VPOKE_ADDRESS_H:	equ 1
	_VPOKE_VALUE:		equ 2
	VPOKE_SIZE:		equ 3
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the NAMTBL buffer and adds the "vpoke" to the array
; param hl: NAMTBL buffer pointer
; param a: value to set and write
; ret hl: NAMTBL address
UPDATE_NAMTBL_BUFFER_AND_VPOKE:
; Updates the NAMTBL buffer
	ld	[hl], a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Adds a "vpoke" to the array, using NAMTBL buffer pointer
; param hl: NAMTBL buffer pointer
; param a: value to write
; ret hl: NAMTBL address
; touches: ix, bc, de
VPOKE_NAMTBL_BUFFER:
; Translates NAMTBL buffer pointer into NAMTBL address and adds the "vpoke"
	ld	de, -namtbl_buffer +NAMTBL +$10000
	add	hl, de
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Adds a "vpoke" to the array, using NAMTBL address
; param hl: NAMTBL address
; param a: value to write
; touches: ix, bc
VPOKE_NAMTBL_ADDRESS:
	push	af ; preserves value to write
; Adds an element to the array
	ld	ix, vpokes.count
	ld	bc, VPOKE_SIZE
	call	ADD_ARRAY_IX
; Sets the values of the new element
	pop	af ; restores the value to write
	ld	[ix + _VPOKE_ADDRESS_L], l
	ld	[ix + _VPOKE_ADDRESS_H], h
	ld	[ix + _VPOKE_VALUE], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Executes the "vpokes" and resets the array
EXECUTE_VPOKES:
; Checks array size
	ld	ix, vpokes.count
	ld	a, [ix]
	or	a
	ret	z ; no elements
; Executes the "vpokes"
	ld	b, a ; counter in b
	inc	ix ; ix = vpokes.array
.LOOP:
	push	bc ; preserves the counter
; Executes the "vpoke"
	ld	l, [ix + _VPOKE_ADDRESS_L]
	ld	h, [ix + _VPOKE_ADDRESS_H]
	ld	a, [ix + _VPOKE_VALUE]
	call	WRTVRM
; Next element
	ld	bc, VPOKE_SIZE
	add	ix, bc
	pop	bc ; restores the counter
	djnz	.LOOP
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Resets the "vpoke" array
RESET_VPOKES:
	xor	a
	ld	[vpokes.count], a
	ret
; -----------------------------------------------------------------------------

ENDIF ; CFG_VPOKES


; =============================================================================
;	Spriteables routines (2x2 chars that eventually become a sprite)
; =============================================================================

IFDEF CFG_SPRITEABLES

; -----------------------------------------------------------------------------
; Symbolic constants for spriteables
	MASK_SPRITEABLE_PENDING:	equ $0f ; pending movement (in pixels)
	MASK_SPRITEABLE_DIRECTION:	equ $70 ; movement direction

	SPRITEABLE_PENDING_0:		equ 7 ; 8 pixels (= 1 tile)

	SPRITEABLE_IDLE:		equ $00 ; no movement (can be moved)
	SPRITEABLE_DIR_UP:		equ $10
	SPRITEABLE_DIR_DOWN:		equ $20
	SPRITEABLE_DIR_RIGHT:		equ $30
	SPRITEABLE_DIR_LEFT:		equ $40
	SPRITEABLE_STOPPED:		equ $80 ; no movement (locked)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Zeroes the spriteable array entirely (count and array)
RESET_SPRITEABLES:
	ld	hl, spriteables
	ld	de, spriteables +1
	ld	bc, SPRITEABLES_SIZE -1
	ld	[hl], 0
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a spriteable
; param hl: NAMTBL buffer pointer to the upper left character
; ret ix: address of the spriteable (to set sprite pattern and color)
INIT_SPRITEABLE:
	ex	de, hl ; NAMTBL buffer pointer in de
; Translates NAMTBL buffer pointer into NAMTBL offset
	ld	hl, -namtbl_buffer +$10000
	add	hl, de ; NAMTBL offset in hl
; Adds an element to the array
	ld	ix, spriteables.count
	ld	bc, SPRITEABLE_SIZE
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
; Updates the spriteables
UPDATE_SPRITEABLES:
; Checks array size
	ld	ix, spriteables.count
	ld	a, [ix]
	or	a
	ret	z ; no elements
; Updates the spriteables
	ld	b, a ; counter in b
	inc	ix ; ix = spriteables.array
.LOOP:
	push	bc ; preserves the counter
; Checks movement direction
	ld	a, [ix + _SPRITEABLE_STATUS]
	ld	b, a ; preserves status
	and	MASK_SPRITEABLE_DIRECTION
	jr	z, .NEXT ; no direction
; Checks pending movement
	ld	a, MASK_SPRITEABLE_PENDING
	and	b
	jr	z, .STOP ; no pending movement
; Decreases the pending movement and shows the sprite
	dec	[ix + _SPRITEABLE_STATUS]
	call	PUT_SPRITEABLE_SPRITE
	jr	.NEXT

; Stops the spriteable (for the next frame)
.STOP:
	; xor	a ; 0 = SPRITEABLE_IDLE ; (unecessary)
	ld	[ix + _SPRITEABLE_STATUS], a
; "vpokes" the spriteable foreground
	call	VPOKE_SPRITEABLE_FOREGROUND

; Next element
.NEXT:
	ld	bc, SPRITEABLE_SIZE
	add	ix, bc
	pop	bc ; restores the counter
	djnz	.LOOP
	ret
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
	cp	SPRITEABLE_DIR_RIGHT
	jr	c, .UP_OR_DOWN ; direction < RIGHT, ergo UP or DOWN
; direction >= RIGHT, ergo RIGHT or LEFT
	cp	SPRITEABLE_DIR_LEFT
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
	cp	SPRITEABLE_DIR_DOWN
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
; (convenience routine to optimize size)
; Sets new status, removes the spriteable from the NAMTBL (both VRAM and buffer),
; and reads the NAMTBL offset
; param ix: pointer to the current spriteable
; param a: new status
; ret hl: NAMTBL offset
MOVE_SPRITEABLE_1:
; Sets new status
	ld	[ix +_SPRITEABLE_STATUS], a
; Removes the spriteable from the NAMTBL (both VRAM and buffer)
	call	VPOKE_SPRITEABLE_BACKGROUND
	call	NAMTBL_BUFFER_SPRITEABLE_BACKGROUND
; Updates NAMTBL offset
	ld	l, [ix +_SPRITEABLE_OFFSET_L]
	ld	h, [ix +_SPRITEABLE_OFFSET_H]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts moving a spriteable down
; param ix: pointer to the current spriteable
MOVE_SPRITEABLE_DOWN:
; Sets new status, removes the spriteable from NAMTBL VRAM and buffer
	ld	a, SPRITEABLE_DIR_DOWN OR SPRITEABLE_PENDING_0
	call	MOVE_SPRITEABLE_1
; Updates NAMTBL offset
	ld	bc, SCR_WIDTH
	add	hl, bc
; Shows the spriteable sprite and puts the spriteable in the NAMTBL buffer
	jr	MOVE_SPRITEABLE_2
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts moving a spriteable to the right
; param ix: pointer to the current spriteable
MOVE_SPRITEABLE_RIGHT:
; Sets new status, removes the spriteable from NAMTBL VRAM and buffer
	ld	a, SPRITEABLE_DIR_RIGHT OR SPRITEABLE_PENDING_0
	call	MOVE_SPRITEABLE_1
; Updates NAMTBL offset
	inc	hl
; Shows the spriteable sprite and puts the spriteable in the NAMTBL buffer
	jr	MOVE_SPRITEABLE_2
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts moving a spriteable to the left
; param ix: pointer to the current spriteable
MOVE_SPRITEABLE_LEFT:
; Sets new status, removes the spriteable from NAMTBL VRAM and buffer
	ld	a, SPRITEABLE_DIR_LEFT OR SPRITEABLE_PENDING_0
	call	MOVE_SPRITEABLE_1
; Updates NAMTBL offset
	dec	hl
; Shows the spriteable sprite and puts the spriteable in the NAMTBL buffer
	; jr	MOVE_SPRITEABLE_2 ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; (convenience routine to optimize size)
; Saves NAMTBL offset, shows the spriteable sprite,
; and puts the spriteable back in the NAMTBL buffer (only)
; param ix: pointer to the current spriteable
; param hl: NAMTBL offset
MOVE_SPRITEABLE_2:
; Saves NAMTBL offset
	ld	[ix +_SPRITEABLE_OFFSET_L], l
	ld	[ix +_SPRITEABLE_OFFSET_H], h
; Shows the spriteable sprite
	call	PUT_SPRITEABLE_SPRITE
; Puts the spriteable back in the NAMTBL buffer (only)
	jp	NAMTBL_BUFFER_SPRITEABLE_FOREGROUND
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
	inc	a
	call	VPOKE_SPRITEABLE_NEXT
; Lower left character
	ld	de, SCR_WIDTH -1
	add	hl, de
	inc	a
	call	VPOKE_SPRITEABLE_NEXT
; Lower right character
	inc	hl
	inc	a
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

ENDIF ; CFG_SPRITEABLES

; EOF
