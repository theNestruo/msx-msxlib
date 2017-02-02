
	; .printtext	" ... user vars"
	; .printhex	$
	
; Buffer general para descompresión
unpack_buffer:
IF CFG_RAM_RESERVE_BUFFER > 0
	ds	CFG_RAM_RESERVE_BUFFER
	; .printtext	" ... (unpack buffer)"
	; .printhex	$
ENDIF

ram_end:
	; .printtext	"-----Core DiskRom System------$f1c9-RAM-"
	; .printtext	"-----DiskROM System vars------$f341-RAM-"
	; .printtext	"-----MSX System vars----------$f380-RAM-"
	; .printtext	" "

	; .printtext	"ROM bytes free:"
	; .printdec	$bfff - rom_end
	; .printtext	" "
	
; EOF
