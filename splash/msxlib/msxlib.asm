
; -----------------------------------------------------------------------------
; MSX BIOS
	DISSCR:	equ $0041 ; Disable screen
	ENASCR:	equ $0044 ; Enable screen
	RDVRM:	equ $004a ; Read byte from VRAM
	WRTVRM:	equ $004d ; Write byte to VRAM
	LDIRVM:	equ $005c ; Copy block to VRAM, from memory
	INIT32:	equ $006f ; Initialize VDP to 32x24 Text Mode

; MSX system variables
	RG1SAV:	equ $f3e0 ; Content of VDP(1) register (R#1)
	FORCLR:	equ $f3e9 ; Foreground colour

; VRAM addresses
	CHRTBL:	equ $0000 ; Pattern table
	NAMTBL:	equ $1800 ; Name table
	CLRTBL:	equ $2000 ; Color table
	SPRATR:	equ $1B00 ; Sprite attributes table
	SPRTBL:	equ $3800 ; Sprite pattern table

; VDP symbolic constants
	SCR_WIDTH:	equ 32
	SPAT_END:	equ $d0 ; Sprite attribute table end marker
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VDP: color ,1,1
	ld	hl, FORCLR
	ld	a, 15
	ld	[hl], a
	ld	a, 4
	inc	hl ; BAKCLR
	ld	[hl], a
	inc	hl ; BDRCLR
	ld	[hl], a
; VDP: screen 2
	call	INIT32
; screen ,2
	ld	hl, RG1SAV
	set	1, [hl]
; Disable screen
	call	DISSCR

; Charset 1/2: CHRTBL
	ld	hl, .CHRTBL_0
	ld	de, CHRTBL
	ld	bc, .CHRTBL_0_SIZE
	call	LDIRVM
; Sprites 1/2: SPRTBL
	ld	hl, .SPRTBL_0
	ld	de, SPRTBL
	ld	bc, .SPRTBL_0_SIZE
	call	LDIRVM
; Sprites 2/2: SPRATR
	ld	hl, .SPRATR_0
	ld	de, SPRATR
	ld	bc, .SPRATR_0_SIZE
	call	LDIRVM
; Charset 2/2: CLRTBL
	ld	hl, CLRTBL + 1
	ld	a, $10
	call	WRTVRM
	ld	hl, CLRTBL + 3
	ld	a, $10
	call	WRTVRM
; Name table
	ld	hl, NAMTBL + 11 *SCR_WIDTH + 9
	xor	a
	call	.LDIRVM_NAMTBL
	ld	hl, NAMTBL + 12 *SCR_WIDTH + 9
	call	.LDIRVM_NAMTBL

; Enable screen
	halt
	call	ENASCR
	
; Animation
	ld	b, 16
.ANIMATION_LOOP:
	push	bc ; preserves counter
	ld	hl, SPRATR + 16 ; MSX.y
	call	.DEC_VRAM
	ld	hl, SPRATR + 20 ; MSX.y
	call	.DEC_VRAM
	ld	hl, SPRATR + 25 ; LIB.x
	call	RDVRM
	inc	a
	call	WRTVRM
	pop	bc ; restores counter
	halt
	halt
	djnz	.ANIMATION_LOOP
; (last pixel)
	ld	hl, SPRATR + 25 ; LIB.x
	call	RDVRM
	inc	a
	call	WRTVRM
	
; Pause
	ld	b, 60 ; ~1 second
.PAUSE_LOOP:
	halt
	djnz	.PAUSE_LOOP
	jp	DISSCR

.LDIRVM_NAMTBL:
	ld	b, 16
.LDIRVM_NAMTBL_LOOP:
	inc	a
	call	WRTVRM
	inc	hl
	djnz	.LDIRVM_NAMTBL_LOOP
	ret

.DEC_VRAM:
	call	RDVRM
	dec	a
	jp	WRTVRM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
.CHRTBL_0:
	incbin	"charset.pcx.chr"
	.CHRTBL_0_SIZE:	equ $ - .CHRTBL_0
.SPRTBL_0:
	incbin	"sprites.pcx.spr"
	.SPRTBL_0_SIZE:	equ $ - .SPRTBL_0
.SPRATR_0:
	db	88 +12, 0,       $00, 0
	db	88 +12, 0,       $00, 0
	db	88 +12, 0,       $00, 0
	db	88 +12, 0,       $00, 0
	db	88 +18, 128  +0, $00, 15 ; MSX
	db	88 +18, 128 +16, $04, 15 ; MSX
	db	88  +2, 128  +8, $08, 1	; LIB
	db	SPAT_END
	.SPRATR_0_SIZE:	equ $ - .SPRATR_0
; -----------------------------------------------------------------------------

; EOF
