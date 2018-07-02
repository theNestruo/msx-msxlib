
; -----------------------------------------------------------------------------
; MSX BIOS
	DISSCR:	equ $0041 ; Disable screen
	ENASCR:	equ $0044 ; Enable screen
	WRTVRM:	equ $004d ; Write byte to VRAM
	FILVRM:	equ $0056 ; Fill block of VRAM with data byte
	LDIRVM:	equ $005c ; Copy block to VRAM, from memory
	INIT32:	equ $006f ; Initialize VDP to 32x24 Text Mode
	CLS:	equ $00c3 ; Clear screen

; MSX system variables
	CLIKSW:	equ $f3db ; Keyboard click sound
	RG1SAV:	equ $f3e0 ; Content of VDP(1) register (R#1)
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
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VDP: color ,1,1
	ld	a, 1
	ld	[BAKCLR], a
	ld	[BDRCLR], a
; VDP: screen 2
	call	INIT32
	call	DISSCR
; screen ,2
	ld	hl, RG1SAV
	set	1, [hl]
; screen ,,0
	xor	a
	ld	[CLIKSW], a

; Disable screen
	call	DISSCR

; Charset
	ld	hl, .CHRTBL_0
	ld	de, CHRTBL
	ld	bc, .CHRTBL_0_SIZE
	call	LDIRVM
	ld	hl, CLRTBL + 4	; "E", "K"
	ld	a, $80		; red
	call	WRTVRM
	ld	hl, CLRTBL + 6	; "S", "L"
	ld	a, $20		; green
	call	WRTVRM
	
; Name table
	ld	hl, NAMTBL
	ld	bc, NAMTBL_SIZE
	xor	a
	call	FILVRM
	ld	hl, .NAMTBL_0 + 0 *.NAMTBL_0_ROW_SIZE
	ld	de, NAMTBL + 10 *SCR_WIDTH + .NAMTBL_0_CENTER
	ld	bc, .NAMTBL_0_ROW_SIZE
	call	LDIRVM
	ld	hl, .NAMTBL_0 + 1 *.NAMTBL_0_ROW_SIZE
	ld	de, NAMTBL + 11 *SCR_WIDTH + .NAMTBL_0_CENTER
	ld	bc, .NAMTBL_0_ROW_SIZE
	call	LDIRVM
	ld	hl, .NAMTBL_0 + 2 *.NAMTBL_0_ROW_SIZE
	ld	de, NAMTBL + 12 *SCR_WIDTH + .NAMTBL_0_CENTER
	ld	bc, .NAMTBL_0_ROW_SIZE
	call	LDIRVM
	ld	hl, .NAMTBL_0 + 3 *.NAMTBL_0_ROW_SIZE
	ld	de, NAMTBL + 13 *SCR_WIDTH + .NAMTBL_0_CENTER
	ld	bc, .NAMTBL_0_ROW_SIZE
	call	LDIRVM
	
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
	
; Pause
	ld	b, 0 ; 256 frames
.LOOP:
	halt
	djnz	.LOOP
	jp	DISSCR
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
.CHRTBL_0:
	incbin	"charset.pcx.chr"
	.CHRTBL_0_SIZE:	equ $ - .CHRTBL_0
.NAMTBL_0:
	incbin	"screen.tmx.bin"
	.NAMTBL_0_SIZE:		equ $ - .NAMTBL_0
	.NAMTBL_0_ROW_SIZE:	equ .NAMTBL_0_SIZE /4
	.NAMTBL_0_CENTER:	equ (SCR_WIDTH - .NAMTBL_0_ROW_SIZE) / 2
.SPRTBL_0:
	incbin	"sprites.pcx.spr"
	.SPRTBL_0_SIZE:	equ $ - .SPRTBL_0
.SPRATR_0:
	db	96 -1, 72, $00, 8
	db	SPAT_END
	.SPRATR_0_SIZE:	equ $ - .SPRATR_0
; -----------------------------------------------------------------------------

; EOF
