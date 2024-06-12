;{----------------------------------------------------------------------}
;{	SOUND.inc sound definitions					}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

		ifndef	equatesinc
		include	equates.inc
		endif

soundinc	equ	1

		ifndef	dosinc
		include	dos.inc
		endif

		ifndef	timerinc
		include	timer.inc
		endif

		ifndef	mathinc
		include	math.inc
		endif
;
; -----	global definitions
;

		global	beep:far
