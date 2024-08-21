; MSX PSG proPLAYER v0.47d - WYZ 09.03.2016

; CARACTERISTICAS
; 5 OCTAVAS:            O[2-6]=60 NOTAS
; 4 LONGITUDES DE NOTA: L[0-3]+PUNTILLO

; LOS DATOS QUE HAY QUE VARIAR :
; * No. DE CANCION.
; * TABLA DE CANCIONES

; ENSAMBLAR CON tniASM

;
; PUNTOS DE ENTRADA PRINCIPALES:
;
; - WYZ_PLAYER_INIT
;       Inicializa el reproductor de música y sonidos
;
; - WYZ_PLAYER_OFF
;       Detiene el reproductor de música y sonidos
;
; - WYZ_CARGA_CANCION
;       Carga una canción, utilizando la tabla de canciones (TABLA_SONG)
;       IN:[A] = No. de canción
;
; - WYZ_CARGA_CANCION_HL
;       Carga una canción
;       IN:[HL] = Dirección de memoria con los datos de la canción
;
; - WYZ_INICIA_EFECTO
;       Inicia un efecto de sonido
;       IN:[A] = No. de sonido
;
; - WYZ_INICIA_FADE_OUT
;       Inicia un fade-out
;       IN:[A] = Cadencia
;
; - WYZ_REPRODUCE_FRAME
;       Reproduce un frame de sonido: a invocar en cada interrupción.
;       Vuelca el frame al PSG y prepara el siguiente frame

;
; PUNTOS DE ENTRADA SECUNDARIOS:
; (sólo si no se utiliza WYZ_REPRODUCE_FRAME)
;
; - WYZ_VOLCADO_PSG
;       Vuelca el frame al PSG
; - WYZ_REPRODUCE_CANCION
;       Prepara el siguiente frame (música)
; - WYZ_REPRODUCE_EFECTOS_MUSICA
;       Prepara el siguiente frame (efectos de la música)
; - WYZ_REPRODUCE_FADE_OUT
;       Post-procesa el siguiente frame para aplicar fade out
; - WYZ_REPRODUCE_EFECTOS
;       Prepara el siguiente frame (efectos externos)

;______________________________________________________

WYZ_BIT_PLAYER:         equ 1
WYZ_BIT_EFECTOS:        equ 2
WYZ_BIT_SFX:            equ 3
WYZ_BIT_LOOP:           equ 4

;______________________________________________________

; Inicializa el reproductor de música y sonidos

WYZ_PLAYER_INIT:

; MUSICA DATOS INICIALES
        LD      HL, BUFFER_CANAL_A
        LD      [CANAL_A], HL

        LD      HL, BUFFER_CANAL_B
        LD      [CANAL_B], HL

        LD      HL, BUFFER_CANAL_C
        LD      [CANAL_C], HL

        LD      HL, BUFFER_CANAL_P
        LD      [CANAL_P], HL

; (comentado porque el método está a continuación)
        ; jp      WYZ_PLAYER_OFF

;______________________________________________________


;______________________________________________________

; Detiene el reproductor de música y sonidos

WYZ_PLAYER_OFF:

;PLAYER OFF
        XOR	A			;***** IMPORTANTE SI NO HAY MUSICA ****
        LD	[WYZ_FLAGS], A
        IFDEF CFG_WYZ_FADE
                LD	[FADE], A	;solo si hay fade out
        ENDIF ; IFDEF CFG_WYZ_FADE

; CLEAR_PSG_BUFFER:
        LD	HL, PSG_REG
        LD	DE, PSG_REG+1
        LD	BC, 14
        LD	[HL], A
        LDIR

        LD      A, 10111000B		; **** POR SI ACASO ****
        LD      [PSG_REG+7], A

        LD	HL, PSG_REG
        LD	DE, PSG_REG_SEC
        LD	C, 14                   ; (optimizado desde: LD BC, 14)
        LDIR

        jp	WYZ_VOLCADO_PSG
;______________________________________________________


;______________________________________________________

;CARGA UNA CANCION
;IN:TABLA_SONG=INDICE DE CANCIONES
;IN:[A]=No. DE CANCION

WYZ_CARGA_CANCION:

                ; LD      [SONG], A          ;No. A

                LD      HL, TABLA_SONG
                CALL    EXT_WORD

;CARGA UNA CANCION
;IN:[HL]=DIRECCION DE MEMORIA CON LOS DATOS DE LA CANCION

WYZ_CARGA_CANCION_HL:

; Previene interrupciones con la canción a medias de cargar
                XOR     A
                LD	[WYZ_FLAGS], A
        IFDEF CFG_WYZ_FADE
                LD	[FADE], A
        ENDIF ; IFDEF CFG_WYZ_FADE

;DECODIFICAR

;LEE CABECERA DE LA CANCION
;BYTE 0=TEMPO

                LD      A, [HL]
                AND	01111111B
                LD      [TEMPO], A
		DEC	A
		LD	[TTEMPO], A
	IFDEF CFG_WYZ_HYBRID
		LD	A, [HL]
		AND	10000000B
		LD	[HYBRID], A
	ENDIF ; IFDEF CFG_WYZ_HYBRID


;HEADER BYTE 1
;[-|-|-|-|  3-1 | 0  ]
;[-|-|-|-|FX CHN|LOOP]

                INC	HL		;LOOP 1=ON/0=OFF?
                LD	A, [HL]
                BIT	0, A
                JR	Z, NPTJP0

                PUSH	HL
                LD	HL, WYZ_FLAGS
                SET	WYZ_BIT_LOOP, [HL]
                POP	HL

;SELECCION DEL CANAL DE EFECTOS DE RITMO

NPTJP0:         AND	00000110B
		RRA
		;LD	[SELECT_CANAL_P], A

		PUSH	HL
		LD	HL, TABLA_DATOS_CANAL_SFX
		CALL    EXT_WORD
		PUSH	HL
		POP	IX
		LD	E, [IX+0]
		LD	D, [IX+1]
		LD	[SFX_L], DE

		LD	E, [IX+2]
		LD	D, [IX+3]
		LD	[SFX_H], DE

		LD	E, [IX+4]
		LD	D, [IX+5]
		LD	[SFX_V], DE

		LD	A, [IX+6]
		LD	[SFX_MIX], A
		POP	HL

		INC	HL		;2 BYTES RESERVADOS
                INC	HL
                INC	HL

;BUSCA Y GUARDA INICIO DE LOS CANALES EN EL MODULO MUS (OPTIMIZAR****************)
;ANNADE OFFSET DEL LOOP

		PUSH	HL			;IX INICIO OFFSETS LOOP POR CANAL
		POP	IX

		LD	DE, $0008		;HASTA INICIO DEL CANAL A
		ADD	HL, DE


		LD	[PUNTERO_P_DECA], HL	;GUARDA PUNTERO INICIO CANAL
		LD	E, [IX+0]
		LD	D, [IX+1]
		ADD	HL, DE
		LD	[PUNTERO_L_DECA], HL	;GUARDA PUNTERO INICIO LOOP

		CALL	BGICMODBC1
		LD	[PUNTERO_P_DECB], HL
		LD	E, [IX+2]
		LD	D, [IX+3]
		ADD	HL, DE
		LD	[PUNTERO_L_DECB], HL

		CALL	BGICMODBC1
		LD	[PUNTERO_P_DECC], HL
		LD	E, [IX+4]
		LD	D, [IX+5]
		ADD	HL, DE
		LD	[PUNTERO_L_DECC], HL

		CALL	BGICMODBC1
		LD	[PUNTERO_P_DECP], HL
		LD	E, [IX+6]
		LD	D, [IX+7]
		ADD	HL, DE
		LD	[PUNTERO_L_DECP], HL


;LEE DATOS DE LAS NOTAS
;[|][|||||] LONGITUD\NOTA

INIT_DECODER:   LD      DE, [CANAL_A]
                LD      [PUNTERO_A], DE
                LD	HL, [PUNTERO_P_DECA]
                CALL    DECODE_CANAL    	;CANAL A
                LD	[PUNTERO_DECA], HL

                LD      DE, [CANAL_B]
                LD      [PUNTERO_B], DE
                LD	HL, [PUNTERO_P_DECB]
                CALL    DECODE_CANAL    	;CANAL B
                LD	[PUNTERO_DECB], HL

                LD      DE, [CANAL_C]
                LD      [PUNTERO_C], DE
                LD	HL, [PUNTERO_P_DECC]
                CALL    DECODE_CANAL    	;CANAL C
                LD	[PUNTERO_DECC], HL

                LD      DE, [CANAL_P]
                LD      [PUNTERO_P], DE
                LD	HL, [PUNTERO_P_DECP]
                CALL    DECODE_CANAL    	;CANAL P
                LD	[PUNTERO_DECP], HL

; Reactiva la reproducción de música
                LD      HL, WYZ_FLAGS
                SET     WYZ_BIT_PLAYER, [HL]

                RET


;BUSCA INICIO DEL CANAL

BGICMODBC1:	XOR	A			;BUSCA EL BYTE 0
		LD	E, $3F			;CODIGO INSTRUMENTO 0
		LD	B, $FF			;EL MODULO DEBE TENER UNA LONGITUD MENOR DE $FF00 ... o_O!
		CPIR

		DEC	HL
		DEC	HL
		LD	A, E			;ES EL INSTRUMENTO 0??
		CP	[HL]
		INC	HL
		INC	HL
		JR	Z, BGICMODBC1

		DEC	HL
		DEC	HL
		DEC	HL
		LD	A, E			;ES VOLUMEN 0??
		CP	[HL]
		INC	HL
		INC	HL
		INC	HL
		JR	Z, BGICMODBC1
		RET


;DECODIFICA NOTAS DE UN CANAL
;IN [DE]=DIRECCION DESTINO
;NOTA=0 FIN CANAL
;NOTA=1 SILENCIO
;NOTA=2 PUNTILLO
;NOTA=3 COMANDO I

DECODE_CANAL:   LD      A, [HL]
                AND     A               ;FIN DEL CANAL?
                JR      Z, FIN_DEC_CANAL
                CALL    GETLEN

                CP      00000001B       ;ES SILENCIO?
                JR      NZ, NO_SILENCIO
                SET     6, A
                JR      NO_MODIFICA

NO_SILENCIO:    CP      00111110B       ;ES PUNTILLO?
                JR      NZ, NO_PUNTILLO
                RRC     B
                XOR     A
                JR      NO_MODIFICA

NO_PUNTILLO:    CP      00111111B       ;ES COMANDO?
                JR      NZ, NO_MODIFICA
                BIT     0, B             ;COMADO=INSTRUMENTO?
                JR      Z, NO_INSTRUMENTO
                LD      A, 11000001B     ;CODIGO DE INSTRUMENTO
                LD      [DE], A
                INC     HL
                INC     DE
                LDI                     ;No. DE INSTRUMENTO
                LDI                     ;VOLUMEN RELATIVO DEL INSTRUMENTO
                JR      DECODE_CANAL

NO_INSTRUMENTO: BIT     2, B
                JR      Z, NO_ENVOLVENTE
                LD      A, 11000100B     ;CODIGO ENVOLVENTE
                LD      [DE], A
                INC     DE
                INC	HL
                LDI
                JR      DECODE_CANAL

NO_ENVOLVENTE:  BIT     1, B
                JR      Z, NO_MODIFICA
                LD      A, 11000010B     ;CODIGO EFECTO
                LD      [DE], A
                INC     HL
                INC     DE
                LD      A, [HL]
                CALL    GETLEN

NO_MODIFICA:    LD      [DE], A
                INC     DE
                XOR     A
                DJNZ    NO_MODIFICA
		SET     7, A
		SET 	0, A
                LD      [DE], A
                INC     DE
                INC	HL
                RET			;** JR      DECODE_CANAL

FIN_DEC_CANAL:  SET     7, A
                LD      [DE], A
                INC     DE
                RET

GETLEN:         LD      B, A
                AND     00111111B
                PUSH    AF
                LD      A, B
                AND     11000000B
                RLCA
                RLCA
                INC     A
                LD      B, A
                LD      A, 10000000B
DCBC0:          RLCA
                DJNZ    DCBC0
                LD      B, A
                POP     AF
                RET
;______________________________________________________


;______________________________________________________

;INICIA EL SONIDO No. [A]

INICIA_EFECTO_MUSICA:
                ;CP	19		;SFX SPEECH
		;JP	NC, SET_SAMPLE_P

		LD      HL, TABLA_SONIDOS
                CALL    EXT_WORD

                LD      [PUNTERO_SONIDO], HL
                LD      HL, WYZ_FLAGS
                SET     WYZ_BIT_EFECTOS, [HL]
                RET
;______________________________________________________


;______________________________________________________
	IFDEF CFG_WYZ_SFX

;REPRODUCE EFECTOS DE SONIDO

;INICIA EL SONIDO No. [A]

WYZ_INICIA_EFECTO:
                LD      HL,TABLA_SONIDOS
                CALL    EXT_WORD

                LD      [PUNTERO_FX_SONIDO],HL
                LD      HL,WYZ_FLAGS
                SET     WYZ_BIT_SFX,[HL]
                RET

        ENDIF ; IFDEF CFG_WYZ_SFX
;______________________________________________________


;____________________________________________________________
        IFDEF CFG_WYZ_FADE

;FADE_OUT 100% A 0% *
;IN [A]:CADENCIA

WYZ_INICIA_FADE_OUT:
                LD	[DECAY],A
		LD	[DECAY_TEMP],A
		XOR	A
		LD	[FADE_METER],A
		LD	HL,FADE
		SET	0,[HL]
		RET

	ENDIF ; IFDEF CFG_WYZ_FADE
;____________________________________________________________


;____________________________________________________________
WYZ_REPRODUCE_FRAME:
        CALL	WYZ_VOLCADO_PSG

; Invoca REPRODUCE_CANCION condicionalmente
        ld      a, [WYZ_FLAGS]
        and     1 << WYZ_BIT_PLAYER       ; PLAY BIT 1 ON?
        call    nz, REPRODUCE_CANCION

;
        LD	HL,PSG_REG
        LD	DE,PSG_REG_SEC
        LD	BC,14
        LDIR

; Invoca REPRODUCE_EFECTO_MUSICA condicionalmente
        ld      a, [WYZ_FLAGS]
        and     1 << WYZ_BIT_EFECTOS       ; ESTA ACTIVADO EL EFECTO?
        call    nz, REPRODUCE_EFECTO_MUSICA

; Invoca REPRODUCE_FADE_OUT condicionalmente
        IFDEF CFG_WYZ_FADE
                ld      a, [FADE]
                rrca                    ; ESTA ACTIVADO EL FADE?
                call    c, REPRODUCE_FADE_OUT
	ENDIF ; IFDEF CFG_WYZ_FADE

; Invoca REPRODUCE_EFECTO condicionalmente
	IFDEF CFG_WYZ_SFX
                ld      a, [WYZ_FLAGS]
                and     1 << WYZ_BIT_SFX       ; ESTA ACTIVADO EL EFECTO?
                call    nz, REPRODUCE_EFECTO
	ENDIF ; IFDEF CFG_WYZ_SFX

        RET
;____________________________________________________________


;______________________________________________________
        IFDEF CFG_WYZ_FADE

WYZ_REPRODUCE_FADE_OUT:
                LD      HL, FADE
                BIT	0,[HL]
                RET     Z

REPRODUCE_FADE_OUT:
                LD	HL,DECAY_TEMP
		DEC	[HL]
		JR	NZ,FADEOJP0
		LD	A,[DECAY]
		LD	[HL],A
		LD	A,[FADE_METER]
		CP	$10			;FADE OUT COMPLETO
		JP	Z,WYZ_PLAYER_OFF
		INC	A
		LD	[FADE_METER],A
FADEOJP0:	LD	A,[FADE_METER]
		LD	C,A
		LD	HL,PSG_REG_SEC+8
		LD	B,3
FADEOBC0:	LD	A,[HL]
		SUB	C
		JR	NC,NO_RESET_VOL
		XOR	A
NO_RESET_VOL:	LD	[HL],A
		INC	HL
		DJNZ	FADEOBC0
                RET

	ENDIF ; IFDEF CFG_WYZ_FADE
;______________________________________________________

;______________________________________________________

;VUELCA BUFFER DE SONIDO AL PSG

WYZ_VOLCADO_PSG:
		LD	A, [PSG_REG+13]
                AND	A			;ES CERO?
                JR	Z, NO_BACKUP_ENVOLVENTE
                LD	[ENVOLVENTE_BACK], A	;08.13 / GUARDA LA ENVOLVENTE EN EL BACKUP


NO_BACKUP_ENVOLVENTE:



		XOR     A



		LD      C, $A0
                LD      HL, PSG_REG_SEC
LOUT:		OUT     [C], A
                INC     C
                OUTI
                DEC     C
                INC     A
                CP      13
                JR      NZ, LOUT
                OUT     [C], A
                LD      A, [HL]
                AND     A
                RET     Z
                INC     C
                OUT     [C], A
		XOR     A
		LD      [PSG_REG_SEC+13], A
                LD	[PSG_REG+13], A
                RET
;______________________________________________________


;PLAY __________________________________________________


WYZ_REPRODUCE_CANCION:
                ld      a, [WYZ_FLAGS]
                and     1 << WYZ_BIT_PLAYER       ; PLAY BIT 1 ON?
                RET     Z

REPRODUCE_CANCION:

	IFDEF CFG_WYZ_HYBRID

		ld	a, [HYBRID]
                rlca    ; HYBRID BIT 7 ON?
		jr	nc, TEMPO_ENTERO
                rlca    ; HYBRID BIT 6 ON?
		jr	nc, TEMPO_ENTERO

TEMPO_SEMI:
                LD      HL, TTEMPO       ;CONTADOR TEMPO
                INC     [HL]
                LD      A, [TEMPO]
                DEC	A
                CP      [HL]
                JR      NZ, PAUTAS
                LD      [HL], 0
                LD	HL, HYBRID
		RES	6, [HL]
		JR	INTERPRETA

	ENDIF ; IFDEF CFG_WYZ_HYBRID

TEMPO_ENTERO:
                LD      HL, TTEMPO       ;CONTADOR TEMPO
                INC     [HL]
                LD      A, [TEMPO]
                CP      [HL]
                JR      NZ, PAUTAS
                LD      [HL], 0
	IFDEF CFG_WYZ_HYBRID
                LD	HL, HYBRID
		SET	6, [HL]
	ENDIF ; IFDEF CFG_WYZ_HYBRID

INTERPRETA:
                LD      IY, PSG_REG
                LD      IX, PUNTERO_A
                LD      BC, PSG_REG+8
                CALL    LOCALIZA_NOTA
                LD      IY, PSG_REG+2
                LD      IX, PUNTERO_B
                LD      BC, PSG_REG+9
                CALL    LOCALIZA_NOTA
                LD      IY, PSG_REG+4
                LD      IX, PUNTERO_C
                LD      BC, PSG_REG+10
                CALL    LOCALIZA_NOTA
                LD      IX, PUNTERO_P    ;EL CANAL DE EFECTOS ENMASCARA OTRO CANAL
                CALL    LOCALIZA_EFECTO

;PAUTAS

PAUTAS:         LD      IY, PSG_REG+0
                LD      IX, PUNTERO_P_A
                LD      HL, PSG_REG+8
                CALL    PAUTA           ;PAUTA CANAL A
                LD      IY, PSG_REG+2
                LD      IX, PUNTERO_P_B
                LD      HL, PSG_REG+9
                CALL    PAUTA           ;PAUTA CANAL B
                LD      IY, PSG_REG+4
                LD      IX, PUNTERO_P_C
                LD      HL, PSG_REG+10
                JP      PAUTA           ;PAUTA CANAL C





;LOCALIZA NOTA CANAL A
;IN [PUNTERO_A]

;LOCALIZA NOTA CANAL A
;IN [PUNTERO_A]

LOCALIZA_NOTA:  LD      L, [IX+PUNTERO_A-PUNTERO_A]	;HL=[PUNTERO_A_C_B]
                LD      H, [IX+PUNTERO_A-PUNTERO_A+1]
                LD      A, [HL]
                AND     11000000B      			;COMANDO?
                CP      11000000B
                JR      NZ, LNJP0

;BIT[0]=INSTRUMENTO

COMANDOS:       LD      A, [HL]
                BIT     0, A             		;INSTRUMENTO
                JR      Z, COM_EFECTO

                INC     HL
                LD      A, [HL]          		;No. DE PAUTA
                INC     HL
                LD	E, [HL]

                PUSH	HL				;;TEMPO ******************
                LD	HL, TEMPO
                BIT	5, E
                JR	Z, NO_DEC_TEMPO
                DEC	[HL]
NO_DEC_TEMPO:	BIT	6, E
		JR	Z, NO_INC_TEMPO
		INC	[HL]
NO_INC_TEMPO:	RES	5, E				;SIEMPRE RESETEA LOS BITS DE TEMPO
		RES	6, E
		POP	HL

		LD      [IX+VOL_INST_A-PUNTERO_A], E	;REGISTRO DEL VOLUMEN RELATIVO
                INC	HL
                LD      [IX+PUNTERO_A-PUNTERO_A], L
                LD      [IX+PUNTERO_A-PUNTERO_A+1], H
                LD      HL, TABLA_PAUTAS
                CALL    EXT_WORD
                LD      [IX+PUNTERO_P_A0-PUNTERO_A], L
                LD      [IX+PUNTERO_P_A0-PUNTERO_A+1], H
                LD      [IX+PUNTERO_P_A-PUNTERO_A], L
                LD      [IX+PUNTERO_P_A-PUNTERO_A+1], H
                LD      L, C
                LD      H, B
                RES     4, [HL]        			;APAGA EFECTO ENVOLVENTE
                XOR     A
                LD      [PSG_REG_SEC+13], A
                LD	[PSG_REG+13], A
                ;LD	[ENVOLVENTE_BACK], A		;08.13 / RESETEA EL BACKUP DE LA ENVOLVENTE
                JR      LOCALIZA_NOTA

COM_EFECTO:     BIT     1, A             		;EFECTO DE SONIDO
                JR      Z, COM_ENVOLVENTE

                INC     HL
                LD      A, [HL]
                INC     HL
                LD      [IX+PUNTERO_A-PUNTERO_A], L
                LD      [IX+PUNTERO_A-PUNTERO_A+1], H
                jp      INICIA_EFECTO_MUSICA

COM_ENVOLVENTE: BIT     2, A
                RET     Z               		;IGNORA - ERROR

                INC     HL
                LD	A, [HL]			;CARGA CODIGO DE ENVOLVENTE
                LD	[ENVOLVENTE], A
                INC     HL
                LD      [IX+PUNTERO_A-PUNTERO_A], L
                LD      [IX+PUNTERO_A-PUNTERO_A+1], H
                LD      L, C
                LD      H, B
                LD	[HL], 00010000B          	;ENCIENDE EFECTO ENVOLVENTE
                JR      LOCALIZA_NOTA


LNJP0:          LD      A, [HL]
                INC     HL
                BIT     7, A
                JR      Z, NO_FIN_CANAL_A	;
                RRA                             ; (optimizado desde: BIT 0, A...
                JR	NC, FIN_CANAL_A         ; ...JR Z, FIN_CANAL_A)

FIN_NOTA_A:	LD      E, [IX+CANAL_A-PUNTERO_A]
		LD	D, [IX+CANAL_A-PUNTERO_A+1]	;PUNTERO BUFFER AL INICIO
		LD	[IX+PUNTERO_A-PUNTERO_A], E
		LD	[IX+PUNTERO_A-PUNTERO_A+1], D
		LD	L, [IX+PUNTERO_DECA-PUNTERO_A]	;CARGA PUNTERO DECODER
		LD	H, [IX+PUNTERO_DECA-PUNTERO_A+1]
		PUSH	BC
                CALL    DECODE_CANAL    		;DECODIFICA CANAL
                POP	BC
                LD	[IX+PUNTERO_DECA-PUNTERO_A], L	;GUARDA PUNTERO DECODER
                LD	[IX+PUNTERO_DECA-PUNTERO_A+1], H
                JP      LOCALIZA_NOTA

FIN_CANAL_A:    ld	a, [WYZ_FLAGS]			;LOOP?
                and     1 << WYZ_BIT_LOOP       ; PLAY BIT 1 ON?
                JR      NZ, FCA_CONT
                POP	AF
                JP	WYZ_PLAYER_OFF


FCA_CONT:	LD	L, [IX+PUNTERO_L_DECA-PUNTERO_A]	;CARGA PUNTERO INICIAL DECODER
		LD	H, [IX+PUNTERO_L_DECA-PUNTERO_A+1]
		LD	[IX+PUNTERO_DECA-PUNTERO_A], L
		LD	[IX+PUNTERO_DECA-PUNTERO_A+1], H
		JR      FIN_NOTA_A

NO_FIN_CANAL_A: LD      [IX+PUNTERO_A-PUNTERO_A], L        	;[PUNTERO_A_B_C]=HL GUARDA PUNTERO
                LD      [IX+PUNTERO_A-PUNTERO_A+1], H
                AND     A               		;NO REPRODUCE NOTA SI NOTA=0
                JR      Z, FIN_RUTINA
                BIT     6, A             		;SILENCIO?
                JR      Z, NO_SILENCIO_A
                LD	A, [BC]
                AND	00010000B
                JR	NZ, SILENCIO_ENVOLVENTE

                XOR     A
                LD	[BC], A				;RESET VOLUMEN DEL CORRESPODIENTE CHIP
                LD	[IY+0], A
                LD	[IY+1], A
		RET

SILENCIO_ENVOLVENTE:
		LD	A, $FF
                LD	[PSG_REG+11], A
                LD	[PSG_REG+12], A
                XOR	A
                LD	[PSG_REG+13], A
                LD	[IY+0], A
                LD	[IY+1], A
                RET

NO_SILENCIO_A:  LD	[IX+REG_NOTA_A-PUNTERO_A], A	;REGISTRO DE LA NOTA DEL CANAL
		CALL    NOTA            		;REPRODUCE NOTA
                LD      L, [IX+PUNTERO_P_A0-PUNTERO_A]     ;HL=[PUNTERO_P_A0] RESETEA PAUTA
                LD      H, [IX+PUNTERO_P_A0-PUNTERO_A+1]
                LD      [IX+PUNTERO_P_A-PUNTERO_A], L       ;[PUNTERO_P_A]=HL
                LD      [IX+PUNTERO_P_A-PUNTERO_A+1], H
FIN_RUTINA:     RET


;LOCALIZA EFECTO
;IN HL=[PUNTERO_P]

LOCALIZA_EFECTO:
                LD      L, [IX+0]       ;HL=[PUNTERO_P]
                LD      H, [IX+1]
                LD      A, [HL]
                CP      11000010B
                JR      NZ, LEJP0

                INC     HL
                LD      A, [HL]
                INC     HL
                LD      [IX+00], L
                LD      [IX+01], H
                jp      INICIA_EFECTO_MUSICA


LEJP0:          INC     HL
                BIT     7, A
                JR      Z, NO_FIN_CANAL_P	;
                RRA                             ; (optimzado desde: BIT 0, A
                JR	NC, FIN_CANAL_P         ; ...JR Z, FIN_CANAL_A)
FIN_NOTA_P:	LD      DE, [CANAL_P]
		LD	[IX+0], E
		LD	[IX+1], D
		LD	HL, [PUNTERO_DECP]	;CARGA PUNTERO DECODER
		PUSH	BC
		CALL    DECODE_CANAL    	;DECODIFICA CANAL
		POP	BC
                LD	[PUNTERO_DECP], HL	;GUARDA PUNTERO DECODER
                JP      LOCALIZA_EFECTO

FIN_CANAL_P:	LD	HL, [PUNTERO_L_DECP]	;CARGA PUNTERO INICIAL DECODER
		LD	[PUNTERO_DECP], HL
		JR      FIN_NOTA_P

NO_FIN_CANAL_P: LD      [IX+0], L        ;[PUNTERO_A_B_C]=HL GUARDA PUNTERO
                LD      [IX+1], H
                RET

; PAUTA DE LOS 3 CANALES
; IN:[IX]:PUNTERO DE LA PAUTA
;    [HL]:REGISTRO DE VOLUMEN
;    [IY]:REGISTROS DE FRECUENCIA

; FORMATO PAUTA
;	    7    6     5     4   3-0                        3-0
; BYTE 1 [LOOP|OCT-1|OCT+1|ORNMT|VOL] - BYTE 2 [ | | | |PITCH/NOTA]

PAUTA:          BIT     4, [HL]        ;SI LA ENVOLVENTE ESTA ACTIVADA NO ACTUA PAUTA
                RET     NZ

		LD	A, [IY+0]
		LD	B, [IY+1]
		OR	B
		RET	Z


                PUSH	HL

PCAJP4:         LD      L, [IX+0]
                LD      H, [IX+1]
		LD	A, [HL]

		BIT     7, A		;LOOP / EL RESTO DE BITS NO AFECTAN
                JR      Z, PCAJP0
                AND     00011111B       ;MAXIMO LOOP PAUTA [0, 32]X2!!!-> PARA ORNAMENTOS
                RLCA			;X2
                LD      D, 0
                LD      E, A
                SBC     HL, DE
                LD      A, [HL]

PCAJP0:		BIT	6, A		;OCTAVA -1
		JR	Z, PCAJP1
		LD	E, [IY+0]
		LD	D, [IY+1]

		RRC	D
		RR	E
		LD	[IY+0], E
		LD	[IY+1], D
		JR	PCAJP2

PCAJP1:		BIT	5, A		;OCTAVA +1
		JR	Z, PCAJP2
		LD	E, [IY+0]
		LD	D, [IY+1]

		RLC	E
		RL	D
		LD	[IY+0], E
		LD	[IY+1], D




PCAJP2:		LD	A, [HL]
		BIT	4, A
		JR	NZ, PCAJP6	;ORNAMENTOS SELECCIONADOS

		INC     HL		;______________________ FUNCION PITCH DE FRECUENCIA__________________
		PUSH	HL
		LD	E, A
		LD	A, [HL]		;PITCH DE FRECUENCIA
		LD	L, A
		AND	A
		LD	A, E
		JR	Z, ORNMJP1

                LD	A, [IY+0]	;SI LA FRECUENCIA ES 0 NO HAY PITCH
                ADD	A, [IY+1]
                AND	A
                LD	A, E
                JR	Z, ORNMJP1


		BIT	7, L
		JR	Z, ORNNEG
		LD	H, $FF
		JR	PCAJP3
ORNNEG:		LD	H, 0

PCAJP3:		LD	E, [IY+0]
		LD	D, [IY+1]
		ADC	HL, DE
		LD	[IY+0], L
		LD	[IY+1], H
		JR	ORNMJP1


PCAJP6:		INC	HL		;______________________ FUNCION ORNAMENTOS__________________

		PUSH	HL
		PUSH	AF
		LD	A, [IX+REG_NOTA_A-PUNTERO_P_A]	;RECUPERA REGISTRO DE NOTA EN EL CANAL
		LD	E, [HL]		;
		ADC	E		;+- NOTA
		CALL	TABLA_NOTAS
		POP	AF


ORNMJP1:	POP	HL

		INC	HL
                LD      [IX+0], L
                LD      [IX+1], H
PCAJP5: 	POP HL
       		AND 15
	       LD  C,  A
	       LD  A, [IX+VOL_INST_A-PUNTERO_P_A]   ;VOLUMEN RELATIVO
	       BIT 4,  A
	       JR  Z,  PCAJP9
	       OR  $F0
PCAJP9: 	ADD A,  C
	       JP  P, PCAJP7
	       LD  A,  1        ;NO SE EXTINGUE EL VOLUMEN
PCAJP7:		CP 15
	       JP M,  PCAJP8
	       LD A,  15
PCAJP8: 	LD      [HL], A
       		RET



;NOTA : REPRODUCE UNA NOTA
;IN [A]=CODIGO DE LA NOTA
;   [IY]=REGISTROS DE FRECUENCIA


NOTA:		LD      L, C
                LD      H, B
                BIT     4, [HL]
     		LD      B, A
                JR	NZ, EVOLVENTES
      		LD	A, B
TABLA_NOTAS:    LD      HL, DATOS_NOTAS		;BUSCA FRECUENCIA
		CALL	EXT_WORD
		LD      [IY+0], L
                LD      [IY+1], H
                RET




;IN [A]=CODIGO DE LA ENVOLVENTE
;   [IY]=REGISTRO DE FRECUENCIA

EVOLVENTES:     LD      HL, DATOS_NOTAS
		;SUB	12
		RLCA                    ;X2
                LD      D, 0
                LD      E, A
                ADD     HL, DE
                LD	E, [HL]
		INC	HL
		LD	D, [HL]

		PUSH	DE
		LD	A, [ENVOLVENTE]		;FRECUENCIA DEL CANAL ON/OFF
		RRA
		JR	NC, FRECUENCIA_OFF
		LD      [IY+0], E
                LD      [IY+1], D
		JR	CONT_ENV

FRECUENCIA_OFF:	LD 	DE, $0000
		LD      [IY+0], E
                LD      [IY+1], D
					;CALCULO DEL RATIO (OCTAVA ARRIBA)
CONT_ENV:	POP	DE
		PUSH	AF
		PUSH	BC
		AND	00000011B
		LD	B, A
		;INC	B

		;AND	A			;1/2
		RR	D
		RR	E
CRTBC0:		;AND	A			;1/4 - 1/8 - 1/16
		RR	D
		RR	E
		DJNZ	CRTBC0
		LD	A, E
                LD      [PSG_REG+11], A
                LD	A, D
                AND	00000011B
                LD      [PSG_REG+12], A
		POP	BC
                POP	AF			;SELECCION FORMA DE ENVOLVENTE

                RRA
                AND	00000110B		;$08, $0A, $0C, $0E
                ADD	8
                LD      [PSG_REG+13], A
           	LD	[ENVOLVENTE_BACK], A
                RET
;______________________________________________________




;______________________________________________________

;REPRODUCE EFECTOS DE SONIDO

WYZ_REPRODUCE_EFECTOS_MUSICA:

                ld      a, [WYZ_FLAGS]
                and     1 << WYZ_BIT_EFECTOS       ; ESTA ACTIVADO EL EFECTO?
                RET     Z

REPRODUCE_EFECTO_MUSICA:

                LD      HL, [PUNTERO_SONIDO]
                LD      A, [HL]
                CP      $FF
                JR      Z, FIN_SONIDO
                LD	DE, [SFX_L]
                LD      [DE], A
                INC     HL
                LD      A, [HL]
                RRCA
                RRCA
                RRCA
                RRCA
                AND     00001111B
                LD	DE, [SFX_H]
                LD      [DE], A
                LD      A, [HL]
                AND     00001111B
                LD	DE, [SFX_V]
                LD      [DE], A

                INC     HL
                LD      A, [HL]
                LD	B, A
                RLA	; (optimizado desde: BIT 7, A...) ;09.08.13 BIT MAS SIGINIFICATIVO ACTIVA ENVOLVENTES
                JR	NC, NO_ENVOLVENTES_SONIDO ; (...JR Z, NO_ENVOLVENTES_SONIDO)
                LD	A, $12
                LD	[DE], A
                INC	HL
                LD      A, [HL]
                LD	[PSG_REG_SEC+11], A
                INC	HL
                LD      A, [HL]
                LD	[PSG_REG_SEC+12], A
                INC	HL
                LD      A, [HL]
                CP	1
                JR	Z, NO_ENVOLVENTES_SONIDO		;NO ESCRIBE LA ENVOLVENTE SI SU VALOR ES 1
                LD	[PSG_REG_SEC+13], A


NO_ENVOLVENTES_SONIDO:

		LD	A, B
		RES	7, A
		AND     A
                JR      Z, NO_RUIDO
                LD      [PSG_REG_SEC+6], A
                LD      A, [SFX_MIX]
                JR      SI_RUIDO
NO_RUIDO: 	XOR	A
		LD      [PSG_REG_SEC+6], A
		LD      A, 10111000B
SI_RUIDO:       LD      [PSG_REG_SEC+7], A

                INC     HL
                LD      [PUNTERO_SONIDO], HL
                RET
FIN_SONIDO:     LD      HL, WYZ_FLAGS
                RES     2, [HL]
       		LD	A, [ENVOLVENTE_BACK]		;NO RESTAURA LA ENVOLVENTE SI ES 0
       		AND	A
       		JR	Z, FIN_NOPLAYER
       		;xor	a ; ***
       		LD	[PSG_REG_SEC+13], A			;08.13 RESTAURA LA ENVOLVENTE TRAS EL SFX

FIN_NOPLAYER:	LD      A, 10111000B
       		LD      [PSG_REG_SEC+7], A

                RET
;______________________________________________________


;______________________________________________________
	IFDEF CFG_WYZ_SFX

WYZ_REPRODUCE_EFECTOS:
                ld      a, [WYZ_FLAGS]
                and     1 << WYZ_BIT_SFX       ; ESTA ACTIVADO EL EFECTO?
                RET     Z

REPRODUCE_EFECTO:

                LD      HL,[PUNTERO_FX_SONIDO]
                LD      A,[HL]
                CP      $FF
                JR      Z,FIN_FX_SONIDO

                LD	DE,PSG_REG_SEC+2		;**** PARA CANAL B ****
                LD      [DE],A
                INC     HL
                LD      A,[HL]
                RRCA
                RRCA
                RRCA
                RRCA
                AND     00001111B
                LD	DE,PSG_REG_SEC+3		;**** PARA CANAL B ****
                LD      [DE],A
                LD      A,[HL]
                AND     00001111B
                LD	DE,PSG_REG_SEC+9		;**** PARA CANAL B ****
                INC	A
                LD      [DE],A

                INC     HL
                LD      A,[HL]
                LD	B,A
                BIT	7,A				;09.08.13 BIT MAS SIGINIFICATIVO ACTIVA ENVOLVENTES
                JR	Z,NO_ENVOLVENTES_FX_SONIDO
                LD	A,$12
                LD	[DE],A
                INC	HL
                LD      A,[HL]
                LD	[PSG_REG_SEC+11],A
                INC	HL
                LD      A,[HL]
                LD	[PSG_REG_SEC+12],A
                INC	HL
                LD      A,[HL]
                CP	1
                JR	Z,NO_ENVOLVENTES_FX_SONIDO		;NO ESCRIBE LA ENVOLVENTE SI SU VALOR ES 1
                LD	[PSG_REG_SEC+13],A


NO_ENVOLVENTES_FX_SONIDO:

		LD	A,B
		RES	7,A
		AND     A
                JR      Z,NO_FX_RUIDO
                LD      [PSG_REG_SEC+6],A
                LD      A,[PSG_REG+7]
                RES	4,A				;**** PARA CANAL B ****
                JR      SI_FX_RUIDO
NO_FX_RUIDO: 	XOR	A
		LD      [PSG_REG_SEC+6],A
		LD      A,10111000B
SI_FX_RUIDO:    LD      [PSG_REG_SEC+7],A
                INC     HL
                LD      [PUNTERO_FX_SONIDO],HL
                RET
FIN_FX_SONIDO:  LD      HL,WYZ_FLAGS
                RES     3,[HL]
       		LD	A,[ENVOLVENTE_BACK]		;NO RESTAURA LA ENVOLVENTE SI ES 0
       		AND	A
       		JR	Z,FIN_FX_NOPLAYER
       		;xor	a ; ***
       		LD	[PSG_REG_SEC+13],A		;08.13 RESTAURA LA ENVOLVENTE TRAS EL SFX

FIN_FX_NOPLAYER:LD      A,10111000B
       		LD      [PSG_REG_SEC+7],A

                RET

	ENDIF ; IFDEF CFG_WYZ_SFX
;______________________________________________________





;______________________________________________________

;EXTRAE UN WORD DE UNA TABLA
;IN:[HL]=DIRECCION TABLA
;   [A]= POSICION
;OUT[HL]=WORD

EXT_WORD:       LD      D, 0
                RLCA
                LD      E, A
                ADD     HL, DE
                LD      E, [HL]
                INC     HL
                LD      D, [HL]
                EX      DE, HL
                RET

;TABLA DE DATOS DEL SELECTOR DEL CANAL DE EFECTOS DE RITMO

TABLA_DATOS_CANAL_SFX:

		DW	SELECT_CANAL_A, SELECT_CANAL_B, SELECT_CANAL_C


;BYTE 0:SFX_L
;BYTE 1:SFX_H
;BYTE 2:SFX_V
;BYTE 3:SFX_MIX

SELECT_CANAL_A:	DW	PSG_REG_SEC+0, PSG_REG_SEC+1, PSG_REG_SEC+8
		DB	10110001B

SELECT_CANAL_B:	DW	PSG_REG_SEC+2, PSG_REG_SEC+3, PSG_REG_SEC+9
		DB	10101010B

SELECT_CANAL_C:	DW	PSG_REG_SEC+4, PSG_REG_SEC+5, PSG_REG_SEC+10
		DB	10011100B
;______________________________________________________
