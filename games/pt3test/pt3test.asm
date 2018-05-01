
;
; =============================================================================
;	MSXlib core configuration, routines and initialization
; =============================================================================
;

; -----------------------------------------------------------------------------
; Define to visually debug frame timing
	; CFG_DEBUG_BDRCLR:
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; MSX cartridge (ROM) header, entry point and initialization

; Define if the ROM is larger than 16kB (typically, 32kB)
; Includes search for page 2 slot/subslot at start
	; CFG_INIT_32KB_ROM:

; Define if the game needs 16kB instead of 8kB
; RAM will start at the beginning of the page 2 instead of $e000
; and availability will be checked at start
	; CFG_INIT_16KB_RAM:
	
; MSX symbolic constants
	include	"lib/msx/symbols.asm"
; MSX cartridge (ROM) header, entry point and initialization
	include "lib/msx/cartridge.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Generic Z80 assembly convenience routines
	include "lib/asm.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Input, timing & pause routines (BIOS-based)
	include "lib/msx/input.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Replayer routines

; Define to enable packed songs when using the PT3-based implementation
	CFG_PT3_PACKED:
	
; Define to use headerless PT3 files (without first 100 bytes)
	CFG_PT3_HEADERLESS:

; PT3-based implementation
	include	"lib/msx/replayer_pt3.asm"
; WYZPlayer v0.47c-based implementation
	; include	"lib/msx/replayer_wyz.asm"

; Define to use relative volume version (the default is fixed volume)
	; CFG_AYFX_RELATIVE:

; ayFX REPLAYER v1.31
	include	"libext/ayFX-replayer/ayFX-ROM.tniasm.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacker routine

; Unpack to RAM routine (optional)
; param hl: packed data source address
; param de: destination buffer address

; Pletter (v0.5c1, XL2S Entertainment)
	; include	"libext/pletter05c/pletter05c-unpackRam.tniasm.asm"

; ZX7 decoder by Einar Saukas, Antonio Villena & Metalbrain
; "Standard" version (69 bytes only)
	UNPACK: equ dzx7_standard
	include	"libext/zx7/dzx7_standard.tniasm.asm"

; Buffer size to check it actually fits before system variables
	CFG_RAM_RESERVE_BUFFER:	equ 2048
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	Game code and data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Game entry point
MAIN_INIT:
	xor	a
	ld	[current_song], a
	call	REPLAYER.RESET
	halt
	
PLAY_SONG:
	ld	a, [current_song]
	call	REPLAYER.PLAY
	
MAIN_LOOP:
	halt
; Reads trigger value	
	call	GET_TRIGGER
	or	a
	jr	z, MAIN_LOOP
	
CHANGE_SONG:
	call	REPLAYER.STOP
	halt
	ld	a, [current_song]
	inc	a
	cp	SONG_PACKED_TABLE.SIZE
	jr	c, .A_OK
	xor	a
.A_OK:
	ld	[current_song], a
	jr	PLAY_SONG
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PT3Player data
SONG_PACKED_TABLE:
	dw	.SONG_0, .SONG_1, .SONG_2, .SONG_3
	.SIZE:	equ ($ - SONG_PACKED_TABLE) /2
.SONG_0:
	incbin	"games/pt3test/warehouse.pt3.hl.zx7"
.SONG_1:
	incbin	"games/pt3test/ship.pt3.hl.zx7"
.SONG_2:
	incbin	"games/pt3test/jungle.pt3.hl.zx7"
.SONG_3:
	incbin	"games/pt3test/cave.pt3.hl.zx7"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Padding to a 8kB boundary
PADDING:
	ds	($ OR $1fff) -$ +1, $ff ; $ff = rst $38
	.SIZE:	equ $ - PADDING
; -----------------------------------------------------------------------------


;
; =============================================================================
;	RAM
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
current_song:
	rb	1
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacker routine buffer
unpack_buffer:
IFDEF CFG_RAM_RESERVE_BUFFER
	rb	CFG_RAM_RESERVE_BUFFER
ENDIF
; -----------------------------------------------------------------------------

ram_end:

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	bytes_rom_MSXlib_code:	equ MAIN_INIT - ROM_START
	bytes_rom_game_code:	equ SONG_PACKED_TABLE - MAIN_INIT
	bytes_rom_game_data:	equ PADDING - SONG_PACKED_TABLE

	bytes_ram_MSXlib:	equ unpack_buffer - ram_start
	bytes_ram_game:		equ ram_end - unpack_buffer
	
	bytes_total_rom:	equ PADDING - ROM_START
	bytes_total_ram:	equ ram_end - ram_start

	bytes_free_rom:		equ PADDING.SIZE
	bytes_free_ram:		equ $f380 - $
; -----------------------------------------------------------------------------

; EOF
