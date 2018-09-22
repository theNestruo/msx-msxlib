
; -----------------------------------------------------------------------------
; MSX BIOS
	DISSCR:	equ $0041 ; Disable screen
	ENASCR:	equ $0044 ; Enable screen
	RDVRM:	equ $004a ; Read byte from VRAM
	WRTVRM:	equ $004d ; Write byte to VRAM
	; FILVRM:	equ $0056 ; Fill block of VRAM with data byte
	LDIRVM:	equ $005c ; Copy block to VRAM, from memory
	INIT32:	equ $006f ; Initialize VDP to 32x24 Text Mode
	; CLS:	equ $00c3 ; Clear screen

; MSX system variables
	; CLIKSW:	equ $f3db ; Keyboard click sound
	RG1SAV:	equ $f3e0 ; Content of VDP(1) register (R#1)
	FORCLR:	equ $f3e9 ; Foreground colour
	BAKCLR:	equ $f3ea ; Background colour
	BDRCLR:	equ $f3eb ; Border colour

; VRAM addresses
	CHRTBL:	equ $0000 ; Pattern table
	NAMTBL:	equ $1800 ; Name table
	CLRTBL:	equ $2000 ; Color table
	SPRATR:	equ $1B00 ; Sprite attributes table
	SPRTBL:	equ $3800 ; Sprite pattern table

; VDP symbolic constants
	SCR_WIDTH:	equ 32
	NAMTBL_SIZE:	equ 32 * 24
	CHRTBL_SIZE:	equ 256 * 8
	SPAT_END:	equ $d0 ; Sprite attribute table end marker
	SPAT_EC:	equ $80 ; Early clock bit (32 pixels)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VDP: color ,1,1
	ld	a, 15
	ld	[FORCLR], a
	ld	a, 4
	ld	[BAKCLR], a
	ld	[BDRCLR], a
; VDP: screen 2
	call	INIT32
; screen ,2
	ld	hl, RG1SAV
	set	1, [hl]
; Disable screen
	call	DISSCR

; Charset
	ld	hl, .CHRTBL_0
	ld	de, CHRTBL
	ld	bc, .CHRTBL_0_SIZE
	call	LDIRVM
	ld	hl, CLRTBL + 1
	call	.WRTVRM_BLACK
	ld	hl, CLRTBL + 3
	call	.WRTVRM_BLACK
; Name table
	ld	hl, NAMTBL + 11 *SCR_WIDTH + 9
	xor	a
	call	.LDIRVM_NAMTBL
	ld	hl, NAMTBL + 12 *SCR_WIDTH + 9
	ld	a, $10
	call	.LDIRVM_NAMTBL
; Sprite
	ld	hl, .SPRTBL_0
	ld	de, SPRTBL
	ld	bc, .SPRTBL_0_SIZE
	call	LDIRVM
	ld	hl, .SPRATR_0
	ld	de, SPRATR
	ld	bc, .SPRATR_0_SIZE
	call	LDIRVM

; Enable screen
	halt
	call	ENASCR
	
; Animation #1: "MSX"
	ld	b, 10
.MSX_LOOP:
	push	bc ; preserves counter
	halt
	halt
	ld	hl, SPRATR + 16
	call	.DEC_VRAM
	ld	hl, SPRATR + 20
	call	.DEC_VRAM
	pop	bc ; restores counter
	djnz	.MSX_LOOP
	
; Animation #2: "LIB"
	ld	b, 17
.LIB_LOOP:
	push	bc ; preserves counter
	halt
	halt
	ld	hl, SPRATR + 25
	call	.INC_VRAM
	ld	hl, SPRATR + 29
	call	.INC_VRAM
	pop	bc ; restores counter
	djnz	.LIB_LOOP
	
; Pause
	ld	b, 60 ; ~1 second
.PAUSE_LOOP:
	halt
	djnz	.PAUSE_LOOP
	jp	DISSCR

.WRTVRM_BLACK:	
	ld	a, $10
	jp	WRTVRM
	
.LDIRVM_NAMTBL:
	ld	b, 10
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
	
.INC_VRAM:
	call	RDVRM
	inc	a
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
	db	88 +12, 0,       $0c, SPAT_EC OR 1
	db	88 +12, 0,       $0c, SPAT_EC OR 1
	db	88 +12, 0,       $0c, SPAT_EC OR 1
	db	88 +12, 0,       $0c, SPAT_EC OR 1
	db	88 +12, 128  +0, $00, 15
	db	88 +12, 128 +16, $04, 15
	db	88  +2, 128  +8, $08, 1
	db	SPAT_END
	.SPRATR_0_SIZE:	equ $ - .SPRATR_0
; -----------------------------------------------------------------------------

; EOF
