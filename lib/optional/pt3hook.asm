
	CFG_OPTIONAL_PT3HOOK equ 1

; -----------------------------------------------------------------------------
; PT3 Player (Dioniso, versión ROM por MSX-KUN, adaptación asMSX por SapphiRe)
	.include	"libext/pt3-rom.asm"
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Rutinas para el uso del replayer PT3 instalado en la interrupción
; =============================================================================
;

; -----------------------------------------------------------------------------
; Descomprime una canción, inicializa el reproductor
; y lo instala en la interrupción.
; param hl: puntero a la canción comprimida
INIT_REPLAYER:
; Descomprime la música
	ld	de, unpack_buffer
	call	UNPACK
; Prepara los valores iniciales del las variables el replayer
	ld	a, 6
	ld	[replayer_frameskip], a
; Con las interrupciones deshabilitadas...
	halt	; sincronización
	di
; ...instala el reproductor de PT3 en la interrupción
	ld	hl, @@HOOK
	ld	de, HTIMI
	ld	bc, HOOK_SIZE
	ldir
; ...inicializa la reproducción
	ld	hl, unpack_buffer -100
	call	PT3_INIT
	ld	hl, PT3_SETUP
	set	0, [hl] ; desactiva loop
; Habilita las interrupciones y finaliza
	ei
	halt	; asegura que se limpie el bit de interrupción del VDP
	halt	; TODO duda: ¿innecesarios? ¿innecesario uno?
	ret

; Hook a instalar en H.TIMI
@@HOOK:
	jp	@@INTERRUPT
	ret	; padding a 5 bytes (tamaño de un hook)
	ret

; Subrutina que se invocará en cada interrupción
@@INTERRUPT:
; Ejecuta un frame del reproductor musical
	call	REPLAYER_INTERRUPT
; Se ejecuta el hook previo
	jp	old_htimi_hook
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Detiene manualmente el reproductor y lo desinstala de la interrupción.
REPLAYER_DONE:
; Silencia el reproductor
	halt	; sincronización
	call	PT3_MUTE
; Con las interrupciones deshabilitadas, recupera el hook previo
	di
	call	RESTORE_OLD_HTIMI_HOOK
	ei
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Subrutina del reproductor musical.
REPLAYER_INTERRUPT:
; En función de los 50Hz/60Hz...
	ld	a, [frame_rate]
	cp	60
	jr	nz, @@NO_FRAMESKIP ; 50Hz
; 60Hz: comprueba si toca frameskip
	ld	hl, replayer_frameskip
	dec	[hl]
	jr	nz, @@NO_FRAMESKIP ; no
; sí: no reproduce música y restaura el valor de frameskip
	ld	a, 6
	ld	[hl], a
	ret

@@NO_FRAMESKIP:
; frame normal: reproduce música
	; di	; innecesario (estamos en la interrupción)
	call	PT3_ROUT
	call	PT3_PLAY
	; ei	; innecesario (estamos en la interrupción)
; comprueba si se ha llegado al final de la canción
	ld	hl, PT3_SETUP
	bit	0, [hl]
	ret	z ; no (está en modo bucle)
	bit	7, [hl]
	ret	z ; no (no ha terminado)
; sí: detiene automáticamente el reproductor
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Desinstala el reproductor recuperando el hook previo.
; Invocar siempre con las interrupciones deshabilitadas
RESTORE_OLD_HTIMI_HOOK:
	ld	hl, old_htimi_hook
	ld	de, HTIMI
	ld	bc, HOOK_SIZE
	ldir
	ret
; -----------------------------------------------------------------------------

; EOF
