
;
; =============================================================================
;	Rutinas para el uso del replayer PT3 instalado en la interrupción
; =============================================================================
;

; Variables de las bibliotecas incluidas
	.include	"libext/pt3-ram.asm"

; Rutina de interrupción previamente existente en el hook H.TIMI
old_htimi_hook:
	.ds	HOOK_SIZE
	
; Sincronización de la música en equipos a 60Hz
replayer_frameskip:
	.byte

; EOF
