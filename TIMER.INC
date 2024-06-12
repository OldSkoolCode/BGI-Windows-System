;{----------------------------------------------------------------------}
;{	timer.inc timer device interface definitions			}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

		ifndef	equatesinc
		include	equates.inc
		endif

TIMERINC	equ	1

		ifndef	eventsinc
		include	events.inc
		endif

		ifndef	dosinc
		include	dos.inc
		endif

;
; -----	hardware port equates
;

TIMER0		equ	40h
TIMER1		equ	41h
TIMER2		equ	42h
TIMERCONTROL	equ	43h
;
; ---- timer device equates
;
TIMERTICK	equ	1

;
; ----- Timer structure
;
timeSlice	struc

timerNotify	dw	?	; ticks before notification
temp		dw	?	; current tick counter
notifyRoutine	dd	?	; notification routine
nextRoutine	dd	?	; pointer to next

timeSlice	Ends

;
; -----	global definitions
;
		global	installtimer:far,uninstalltimer:far
		global	ttickval:word,mytimerrtn:far
		global	addTimerNotify:far, delTimerNotify:far
		global	_addTimerNotify:far, _delTimerNotify:far
