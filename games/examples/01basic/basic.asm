
;
; =============================================================================
;	MSXlib basic example
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSXlib helper: default configuration
	include	"lib/rom-default.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
INIT:

; Besides the minimal initialization, the MSXlib hook has been installed
; And VRAM buffer, text, and logical coordinates sprites routines are available
; as well as input, timing & pause routines

;
; YOUR CODE (ROM) START HERE
;
; Example:
;

; Charset and sprite patterns
	call	INIT_GRAPHICS

; Prepares the VRAM buffer of the NAMTBL
	ld	hl, .MY_SCREEN_PACKED
	ld	de, namtbl_buffer
	call	UNPACK

; Initializes one sprite in the NAMTBL buffer
	call	RESET_SPRITES

	ld	e, 96	; y
	ld	d, 128	; x
	ld	c, $40	; pattern
	ld	b, 15	; color
	call	PUT_SPRITE

; Re-enables the screen, but using a fade-in to blit the NAMTBL buffer
	call	ENASCR_FADE_IN

; (infinite loop)
.LOOP:
	halt			; (sync)
	call	LDIRVM_SPRATR	; Blits the SPRATR buffer
	call	MOVE_PLAYER	; Moves the player
	call	ANIMATE_SPRITE	; Animates the sprite
	jr	.LOOP

.MY_SCREEN_PACKED:
	incbin	"games/examples/shared/screen.tmx.bin.zx0"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
INIT_GRAPHICS:
; Uses MSXlib convenience routines
; to unpack and LDIRVM the charset to the three banks
	ld	hl, .MY_CHRTBL_PACKED
	call	UNPACK_LDIRVM_CHRTBL
	ld	hl, .MY_CLRTBL_PACKED
	call	UNPACK_LDIRVM_CLRTBL

; Also uses MSXlib to unpack and LDIRVM sprite patterns
	ld	hl, .MY_SPRTBL_PACKED
	ld	de, SPRTBL
	ld	bc, SPRTBL_SIZE
	jp	UNPACK_LDIRVM

; The shared data of the examples
.MY_CHRTBL_PACKED:
	incbin	"games/examples/shared/charset.pcx.chr.zx0"
.MY_CLRTBL_PACKED:
	incbin	"games/examples/shared/charset.pcx.clr.zx0"
.MY_SPRTBL_PACKED:
	incbin	"games/examples/shared/sprites.pcx.spr.zx0"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
MOVE_PLAYER:
; Uses MSXlib auto input to read the cursor or joystick

; For the trigger, uses .edge to react only on new key presses
	ld	a, [input.edge]
	bit	BIT_TRIGGER_A, a
	call	nz, ON_TRIGGER_A

; For the movement, uses .level for fluid movement
	ld	a, [input.level]

	bit	BIT_STICK_UP, a
	jr	nz, MOVE_PLAYER_UP

	bit	BIT_STICK_DOWN, a
	jr	nz, MOVE_PLAYER_DOWN

	bit	BIT_STICK_LEFT, a
	jr	nz, MOVE_PLAYER_LEFT

	bit	BIT_STICK_RIGHT, a
	jr	nz, MOVE_PLAYER_RIGHT

	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ON_TRIGGER_A:
; Alternates the color of the sprite
	ld	a, [spratr_buffer +3] ; color of sprite #0
	xor	(15 XOR 14) ; alternates between 14 and 15
	ld	[spratr_buffer +3], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
MOVE_PLAYER_UP:
; Moves the sprite up (in spratr buffer)
	ld	hl, spratr_buffer ; y of sprite #0
	dec	[hl]
; Changes the pattern (preserving the animation)
	ld	a, [spratr_buffer + 2]; pattern of sprite #0
	and	$07
	or	$58
	ld	[spratr_buffer + 2], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
MOVE_PLAYER_DOWN:
; Moves the sprite down (in spratr buffer)
	ld	hl, spratr_buffer ; y of sprite #0
	inc	[hl]
; Changes the pattern (preserving the animation)
	ld	a, [spratr_buffer + 2]; pattern of sprite #0
	and	$07
	or	$50
	ld	[spratr_buffer + 2], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
MOVE_PLAYER_LEFT:
; Moves the sprite left (in spratr buffer)
	ld	hl, spratr_buffer +1 ; x of sprite #0
	dec	[hl]
; Changes the pattern (preserving the animation)
	ld	a, [spratr_buffer + 2]; pattern of sprite #0
	and	$07
	or	$48
	ld	[spratr_buffer + 2], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
MOVE_PLAYER_RIGHT:
; Moves the sprite right (in spratr buffer)
	ld	hl, spratr_buffer +1 ; x of sprite #0
	inc	[hl]
; Changes the pattern (preserving the animation)
	ld	a, [spratr_buffer + 2]; pattern of sprite #0
	and	$07
	or	$40
	ld	[spratr_buffer + 2], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ANIMATE_SPRITE:
; Each 16 frames...
	ld	a, [JIFFY]
	and	$0f
	ret	nz
; ...animates the sprite (in spratr buffer)
	ld	hl, spratr_buffer +2 ; pattern of sprite #0
	ld	a, [hl]
	xor	$04 ; (swaps with the next/previous pattern)
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

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

; -----------------------------------------------------------------------------

	include	"lib/ram_end.asm"

; EOF
