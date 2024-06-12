;{----------------------------------------------------------------------}
;{	BUFF.inc double buffering include file				}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

		ifndef	equatesinc
		include	equates.inc
		endif

buffinc		equ	1

		ifndef	grafinc
		include	graf.inc
		endif

;
; -----	global definitions
;

		global	initbuffering:far,pageflip:far
		global	enablebuffering:far,disablebuffering:far
		global	pic2seg:word


