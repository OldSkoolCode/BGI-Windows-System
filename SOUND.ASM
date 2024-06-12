; $Header: e:/graphic\RCS\sound.asm_v 1.1 1993/04/23 21:07:33 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	MSDOS sound library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	Written by Kenneth L. Hurley					}
;{	Started	4-1-1989						}
;{	Written with Turbo Assembler ver 1.0				}
;{----------------------------------------------------------------------}

; $Log: sound.asm_v $
; Revision 1.1  1993/04/23  21:07:33  KENH
; Initial revision
;

		include	sound.inc

		locals

zseg		segment at 0

		org	46ch
timerval	dd	?

zseg		Ends
dsound		Segment	Public 'FAR_DATA'

dsound		Ends

csound		Segment Public 'CODE'

		assume	cs:csound,ds:dsound,ss:nothing,es:nothing


;{----------------------------------------------------------------------}
;{ Function:	beep							}
;{ Description:	beep the speaker at the desired frequency for the 	}
;{		desired duration.					}	}
;{ Parameters:	ax = frequency						}
;{		bx = duration in 1/18ths of a second			}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
beep		Proc	Far

		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	es

		mov	di,bx
		mov	bx,ax

		xor	cx,cx
		mov	ax,34dch
		mov	dx,12h		; 1.193180 MHZ clock
		call	far ptr divU32
		mov	dx,ax
	
		mov	al,10110110b
		out	TIMERCONTROL,al
		mov	ax,dx
		out	TIMER2,al
		mov	al,ah
		out	TIMER2,al

		xor	ax,ax
		mov	es,ax
		mov	ax,word ptr es:timerval
.waitLoop1:
		cmp	ax,word ptr es:timerval
		je	.waitLoop1

		add	di,word ptr es:timerval

		in	al,PORTBOUT
		or	al,3
		out	PORTBOUT,al

.waitLoop2:
		cmp	di,word ptr es:timerval
		jg	.waitLoop2

		in	al,PORTBOUT
		and	al,0fch
		out	PORTBOUT,al

		pop	es
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		ret

beep		Endp

csound		Ends

		end
