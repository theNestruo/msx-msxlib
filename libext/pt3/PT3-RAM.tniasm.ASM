		; --- THIS FILE MUST BE COMPILED IN RAM ---

		; --- PT3 WORKAREA [self-modifying code patched] ---

PT3_SETUP:		rb	1	;set bit0 to 1, if you want to play without looping
					;bit7 is set each time, when loop point is passed
PT3_MODADDR:		rb	2
PT3_CrPsPtr:		rb	2
PT3_SAMPTRS:		rb	2
PT3_OrnPtrs:		rb	2
PT3_PDSP:		rb	2
PT3_CSP:		rb	2
PT3_PSP:		rb	2
PT3_PrNote:		rb	1
PT3_PrSlide:		rb	2
PT3_AdInPtA:		rb	2
PT3_AdInPtB:		rb	2
PT3_AdInPtC:		rb	2
PT3_LPosPtr:		rb	2
PT3_PatsPtr:		rb	2
PT3_Delay:		rb	1
PT3_AddToEn:		rb	1
PT3_Env_Del:		rb	1
PT3_ESldAdd:		rb	2

VARS:

ChanA:			rb	29			;CHNPRM_Size
ChanB:			rb	29			;CHNPRM_Size
ChanC:			rb	29			;CHNPRM_Size

;GlobalVars
DelyCnt:		rb	1
CurESld:		rb	2
CurEDel:		rb	1
Ns_Base_AddToNs:
Ns_Base:		rb	1
AddToNs:		rb	1

AYREGS:
VT_:			rb	14
EnvBase:		rb	2
VAR0END:		rb	240
