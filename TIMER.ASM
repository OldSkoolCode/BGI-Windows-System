; $Header$

;{----------------------------------------------------------------------}
;{	timer device library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log$

		locals

		include	timer.inc

zseg		segment at 0

		org	20h
timervec	dd	?

zseg		Ends

INITSTART	Segment	Public 'FAR_DATA'

		Executehead	<"GRIN",32767,installtimer>

INITSTART	Ends

INITEND		Segment Public 'FAR_DATA'

		Executehead	<"GREN",32767,uninstalltimer>

INITEND		Ends
		
EVENTHANDLER	Segment	Public 'FAR_DATA'

		Executehead	<"EVHA", 65000, HWTimerTickEvent, HWTIMERDEVICE>
		Executehead	<"EVHA", 32767, TimerTickEvent, TIMERDEVICE>

EVENTHANDLER	Ends

TimerDevData	Segment	Public 'FAR_DATA'

ttickval	dw	0
nSlices		dw	1
startSlice	timeSlice	<0, 0, 0, 0>


TimerDevData	Ends

TimerDevCode	Segment Public 'CODE'

	    	assume	cs:TimerDevCode, ds:TimerDevData

installed8	dw	0
saveint8	dd	?

;{----------------------------------------------------------------------}
;{	installtimer:							}
;{----------------------------------------------------------------------}
installtimer	Proc	Far

		pushall

		cmp	cs:installed8,0
		jne	intiexit
		mov	ah,GetIntVec
		mov	al,8		; interrupt vector for user timer
		Int	MsDos		; call through MsDos
		mov	word ptr cs:saveint8,bx
		mov	word ptr cs:saveint8+2,es ; save old routine address
		mov	word ptr cs:installed8,1
		mov	ax,seg mytimerrtn
		lea	bx,mytimerrtn
		xor	cx,cx
		mov	ds,cx
		assume	ds:zseg
		cli
		mov	word ptr timervec,bx
		mov	word ptr timervec+2,ax
		assume	ds:TimerDevData
		mov	al,36h
		out	TIMERCONTROL,al
		nop
		nop
		nop
		mov	al,0h
		out	TIMER0,al
		nop
		nop
		nop
		nop
		nop
		mov	al,40h
		out	TIMER0,AL
		sti
intiexit:
		xor	ax,ax
		popall
		ret

installtimer	Endp

;{----------------------------------------------------------------------}
;{	uninstalltimer:							}
;{	  uninstall the timer driver vector				}
;{----------------------------------------------------------------------}
uninstalltimer	Proc	Far

		pushall
		cmp	word ptr cs:installed8,0
		je	unintiexit
		mov	word ptr cs:installed8,0
		les	dx,cs:saveint8
		assume	ds:zseg
		xor	ax,ax
		mov	ds,ax
		cli
		mov	word ptr timervec,dx
		mov	word ptr timervec+2,es
		assume	ds:TimerDevData
		mov	al,36h
		out	TIMERCONTROL,al
		xor	al,al
		out	TIMER0,al
		nop
		nop
		nop				; delay a little
		nop
		nop
		out	TIMER0,al
		sti
unintiexit:
		xor	ax,ax
		popall
		ret

uninstalltimer	Endp

fasttickval	dw	4
inTimer		dw	0

;{----------------------------------------------------------------------}
;{	HWTimerTickEvent:						}
;{	  come here when timer event happens				}
;{----------------------------------------------------------------------}
HWTimerTickEvent Proc	Far

		cmp	ah,HWTIMERDEVICE
		jne	@@notMyEvent

		cmp	cs:inTimer,0
		jne	@@NoMessage		; will lose message if queue
		mov	cs:inTimer,1		; is full
		push	ax
		mov	ah,TIMERDEVICE		; and set device got from
		call	far ptr addMsgQueue
		pop	ax
		mov	cs:inTimer,0
@@NoMessage:
		mov	ax,1
		ret
@@notMyEvent:
		xor	ax,ax
		ret

HWTimerTickEvent Endp

;{----------------------------------------------------------------------}
;{	TimerTickEvent:							}
;{	  come here when timer event happens				}
;{----------------------------------------------------------------------}
TimerTickEvent Proc	Far

		cmp	ah,TIMERDEVICE
		jne	@@notMyEvent

		cmp	al,TIMERTICK
		jne	@@notMyEvent

		pushall

		mov	bx,seg startSlice
		mov	ds,bx			; set up segment
		mov	es,bx

		mov	di,offset startSlice
		mov	cx,nSlices
@@NotifyLoop:
		mov	ax,es
		or	ax,di
		je	@@TTEExit		; no routines yet
		dec	es:[di].temp
		jne	@@DontNotify
		mov	ax,es:[di].timerNotify
		mov	es:[di].temp,ax		; reset counter
		push	cx
		push	di
		push	es

		call	es:[di].notifyRoutine	; notify time-out
		pop	es
		pop	di
		pop	cx
@@DontNotify:
		les	di,es:[di].nextRoutine	; get next routine
		loop	@@NotifyLoop
@@TTEExit:
		popall
@@notMyEvent:
		xor	ax,ax
		ret

TimerTickEvent Endp

;{----------------------------------------------------------------------}
;{	mytimerrtn:							}
;{	  timer vector handler						}
;{----------------------------------------------------------------------}
mytimerrtn	Proc	Far

		push	ax
		push	bx
		push	cx 
		push	dx
		push	ds
		sti				; make sure ints. still going
		mov	ax,seg ttickval
		mov	ds,ax
		inc	ttickval

		push	ax
		mov	ah,HWTIMERDEVICE	; and set device got from
		mov	al,TIMERTICK
		call	far ptr sendMessage
		pop	ax
		mov	inTimer,0

@@NoMessage:
		pop	ds
		pop	dx
		pop	cx
		pop	bx

		dec	cs:fasttickval
		je	@@DoOldInt
		mov	al,20h
		out	20h,al		; signal end of interrupt
		pop	ax
		iret
@@DoOldInt:
		mov	cs:fasttickval,4
		pop	ax
		jmp	cs:saveint8

mytimerrtn	Endp

;{----------------------------------------------------------------------}
;{ Function:	_addTimerNotify(timerSlice huge *inptr):		}
;{ Descripiton:	come here to add timer notify structure in linked list	}
;{ Parameters:	inptr = pointer to time slice structure			}
;{ Output:	ax = 0 if ok						}
;{----------------------------------------------------------------------}
_addTimerNotify	Proc	C Far

		arg	inptr:dword

		mov	bx,word ptr inptr
		mov	ax,word ptr inptr+2	; get pointer
		call	far ptr addTimerNotify
		ret

_addTimerNotify	Endp

;{----------------------------------------------------------------------}
;{	addTimerNotify:							}
;{	  come here to add timer notify structure in linked list	}
;{	ax:bx = pointer to time slice structure				}
;{----------------------------------------------------------------------}
addTimerNotify	Proc	Far

		push	cx
		push	dx
		push	di
		push	ds
		push	es
		mov	di,seg nSlices
		mov	ds,di
		mov	es,di
		mov	cx,nSlices		; maximum routines
		mov	di,offset startSlice
@@FindLoop:
		mov	dx,word ptr es:[di].nextRoutine
		or	dx,word ptr es:[di].nextRoutine+2
		je	@@FoundEnd
		les	di,es:[di].nextRoutine
		loop	@@FindLoop
		mov	ax,1
		jmp	@@ATNExit
@@FoundEnd:
		mov	word ptr es:[di].nextRoutine,bx
		mov	word ptr es:[di].nextRoutine+2,ax
		mov	es,ax
		mov	di,bx
		mov	ax,es:[di].timerNotify
		mov	es:[di].temp,ax
		mov	word ptr es:[di].nextRoutine,0
		mov	word ptr es:[di].nextRoutine+2,0
		inc	nSlices
@@ATNExit:
		pop	es
		pop	ds
		pop	di
		pop	dx
		pop	cx
		ret

addTimerNotify	Endp

;{----------------------------------------------------------------------}
;{ Function:	_delTimerNotify(timerSlice huge *inptr):		}
;{ Descripiton:	come here to del timer notify structure in linked list	}
;{ Parameters:	inptr = pointer to time slice structure			}
;{ Output:	ax = 0 if ok						}
;{----------------------------------------------------------------------}
_delTimerNotify	Proc	C Far

		arg	inptr:dword

		mov	bx,word ptr inptr
		mov	ax,word ptr inptr+2	; get pointer
		call	far ptr delTimerNotify
		ret

_delTimerNotify	Endp

;{----------------------------------------------------------------------}
;{	delTimerNotify:							}
;{	  come here to del timer notify structure in linked list	}
;{	ax:bx = pointer to time slice structure				}
;{----------------------------------------------------------------------}
delTimerNotify	Proc	Far

		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		mov	di,seg nSlices
		mov	ds,di
		mov	es,di
		mov	cx,nSlices		; maximum routines
		mov	si,offset startSlice
@@FindLoop:
		mov	dx,word ptr [si].nextRoutine
		or	dx,word ptr [si].nextRoutine+2
		je	@@FoundEnd
		les	di,[si].nextRoutine
		mov	dx,es
		cmp	ax,dx
		jne	@@NotFound
		cmp	bx,di
		jne	@@NotFound
		mov	ax,word ptr es:[di].nextRoutine
		mov	word ptr [si].nextRoutine,ax
		mov	ax,word ptr es:[di].nextRoutine+2
		mov	word ptr [si].nextRoutine+2,ax
		mov	ax,seg nSlices
		mov	ds,ax
		dec	nSlices
		xor	ax,ax
		jmp	@@DTNExit
@@NotFound:
		mov	ds,dx
		mov	si,di
		loop	@@FindLoop
@@FoundEnd:
		mov	ax,1
@@DTNExit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		ret

delTimerNotify	Endp

TimerDevCode	Ends

		end

