;{----------------------------------------------------------------------}
;{	joystick.inc device interface definitions			}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

		ifndef	equatesinc
		include	equates.inc
		endif

JoyDevInc	equ	1

		ifndef	dosinc
		include	dos.inc
		endif

;
; -----	device equates
;

JoyPort		equ	201h
JoyTimeout	equ	2000h

JOYUP		equ	1
JOYDOWN		equ	2
JOYLEFT		equ	4
JOYRIGHT	equ	8
JOYBUTTON1	equ	40h
JOYBUTTON2	equ	20h


		global	readjoys:far,joysactive:byte
		global	_joysactive:byte
