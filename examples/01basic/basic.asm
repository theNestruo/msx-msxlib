
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

; Uses MSXlib convenience routines
; to unpack and LDIRVM the charset to the three banks
	ld	hl, .MY_CHRTBL_PACKED
	call	UNPACK_LDIRVM_CHRTBL
	ld	hl, .MY_CLRTBL_PACKED
	call	UNPACK_LDIRVM_CLRTBL
	
; Uses BIOS to LDIRVM the sprite patterns
	ld	hl, .MY_SPRTBL_PACKED
	ld	de, SPRTBL
	ld	bc, SPRTBL_SIZE
	call	UNPACK_LDIRVM
	
; Prepares the VRAM buffer of the NAMTBL
	ld	hl, .MY_NAMTBL
	ld	de, namtbl_buffer
	ld	bc, NAMTBL_SIZE
	ldir

; Initializes the sprites of the scene in the NAMTBL buffer
	call	RESET_SPRITES
	
	ld	e, 96	; y
	ld	d, 112	; x
	ld	c, $00	; pattern
	ld	b, 9	; color
	call	PUT_SPRITE
	
	ld	d, 144	; x
	ld	c, $28	; pattern
	ld	b, 11	; color
	call	PUT_SPRITE

; Re-enables the screen, but using a fade-in to blit the NAMTBL buffer
	call	ENASCR_FADE_IN

; (infinite loop)
.LOOP:
; Blits the SPRATR buffer
	call	LDIRVM_SPRATR
	
; After some frames...
	ld	b, 10
	call	WAIT_FRAMES
	
; ...animates the sprites in the NAMTBL buffer
; (1/2)
	ld	hl, spratr_buffer +0 +2 ; pattern of sprite #0
	ld	a, [hl]
	xor	$04 ; (swaps with the next/previous pattern)
	ld	[hl], a
; (2/2)	
	ld	bc, 4 ; Moves to the pattern of sprite #1
	add	hl, bc
	ld	a, [hl]
	xor	$04 ; (swaps with the next/previous pattern)
	ld	[hl], a
	
; (infinite loop)
	jr	.LOOP

; The shared data of the examples
.MY_CHRTBL_PACKED:
	incbin	"examples/shared/charset.pcx.chr.zx7"
.MY_CLRTBL_PACKED:
	incbin	"examples/shared/charset.pcx.clr.zx7"
.MY_SPRTBL_PACKED:
	incbin	"examples/shared/sprites.pcx.spr.zx7"

.MY_NAMTBL:
	incbin	"examples/shared/screen.tmx.bin"
; -----------------------------------------------------------------------------

	include	"lib/msx/rom_end.asm"

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"

; lib/ram.asm automatically starts the RAM section at the proper address
; (either $C000 (16KB) or $E000 (8KB)) and includes everything MSXlib requires.

;
; YOUR VARIABLES (RAM) START HERE
;

; -----------------------------------------------------------------------------

	include	"lib/msx/ram_end.asm"

; EOF
