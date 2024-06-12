; $Header: e:/graphic\RCS\mouse.asm_v 1.2 1993/05/17 16:33:21 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	MSDOS mouse library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log: mouse.asm_v $
; Revision 1.2  1993/05/17  16:33:21  KENH
; *** empty log message ***
;
; Revision 1.1  1993/04/23  21:10:21  KENH
; Initial revision
;
; Revision 1.1  1993/04/23  21:10:21  KENH
; Initial revision
;

		locals

		include	mouse.inc

DGROUP		GROUP	_DATA

_DATA		segment public 'DATA'

mouseavail	dw	0		; whether mouse available
mousebits	dw	0		; mouse interrupt bits
_mouseX		dw	?
_mouseY		dw	?
oldMouseX	dw	?
oldMouseY	dw	?
_mousePtr	dd	mouseArrow
_oldmousePtr	dd	mouseArrow
mouseBack	dd	mBackBuff
mouseHotX	dw	1
mouseHotY	dw	0
mouseOn		dw	0
oldMouseMask	dw	?
saveMouseInt	dd	?

mBackBuff	dw	16,16
		db	(16*16) dup (?)


_DATA   	Ends

EVENTHANDLER	Segment	Public 'FAR_DATA'

		Executehead	<"EVHA", 65000, MouseMoveEvents, HWMOUSEDEVICE>

EVENTHANDLER	Ends

GRAFCHANGE	Segment	Public 'FAR_DATA'

		Executehead	<"GRCH",32767,mousegch>
		Executehead	<"GRCH",50000,initmouse>

GRAFCHANGE	Ends

INITEND		Segment Public 'FAR_DATA'

		Executehead	<"GREN",32767,UninstallMouse>

INITEND		Ends

cmouse		Segment Public 'CODE'

		assume	cs:cmouse,ds:DGROUP,ss:nothing,es:DGROUP

;{----------------------------------------------------------------------}
;{	MouseMoveEvents:						}
;{	  come here when mouse events needs to happen			}
;{----------------------------------------------------------------------}
MouseMoveEvents	Proc	Far

		cmp	ah,HWMOUSEDEVICE
		jne	@@notMyEvent
		pushall

		mov	bx,seg DGROUP
		mov	ds,bx

		push	ax
		mov	ah,MOUSEDEVICE		; and set device got from
		call	far ptr addMsgQueue
		pop	ax

		cmp	al,MOUSEMOVEMENT
		jne	@@NoMouseMove

		cmp	mouseOn,1
		jl	@@NoMouseMove

		les	bx,mouseBack		; get address of mouse
		mov	cx,oldMouseX
		mov	dx,oldMouseY
		mov	al,REPLACE_MODE
		callBGI	restorebitmap		; restore old back ground

		mov	cx,_mouseX
		mov	dx,_mouseY
		mov	oldMouseX,cx
		mov	oldMouseY,dx		; save new mouse background
		les	bx,mouseBack
		callBGI	savebitmap

		mov	cx,_mouseX
		mov	dx,_mouseY
		les	bx,_mousePtr
		mov	al,XPARENT_MODE
		callBGI	restorebitmap
@@NoMouseMove:
		popall
		mov	ax,1
		ret
@@notMyEvent:
		xor	ax,ax
		ret

MouseMoveEvents	Endp

;{----------------------------------------------------------------------}
;{	MouseIntHand:							}
;{	  Mouse interrupt handler					}
;{----------------------------------------------------------------------}
MouseIntHand	Proc	far

		push	ax
		pushall

		mov	bx,seg DGROUP
		mov	ds,bx
		mov	mousebits,ax

		test	al,HWMOUSEMOVEMENT	; see if movement event
		je	@@NoMouseMove

		sub	cx,mouseHotX		; add in hot spot draw offset
		sub	dx,mouseHotY
		mov	_mouseX,cx
		mov	_mouseY,dx

		push	ax
		mov	ah,HWMOUSEDEVICE	; and set device got from
		mov	al,MOUSEMOVEMENT
		call	far ptr sendMessage
		pop	ax
@@NoMouseMove:
		test	al,HWMBUTTON1PRESS
		je	@@notMB1Press
		push	ax
		mov	ah,HWMOUSEDEVICE	; send mouse 1 button down
		mov	al,MBUTTON1PRESS
		call	far ptr sendMessage
		pop	ax
@@notMB1Press:
		test	al,HWMBUTTON1RELEASE
		je	@@notMB1Release
		push	ax
		mov	ah,HWMOUSEDEVICE	; send mouse 1 button up
		mov	al,MBUTTON1RELEASE
		call	far ptr sendMessage
		pop	ax
@@notMB1Release:
		test	al,HWMBUTTON2PRESS
		je	@@notMB2Press
		push	ax
		mov	ah,HWMOUSEDEVICE	; send mouse 2 button down
		mov	al,MBUTTON2PRESS
		call	far ptr sendMessage
		pop	ax
@@notMB2Press:
		test	al,HWMBUTTON2RELEASE
		je	@@notMB2Release
		push	ax
		mov	ah,HWMOUSEDEVICE	; send mouse 2 button up
		mov	al,MBUTTON2RELEASE
		call	far ptr sendMessage
		pop	ax
@@notMB2Release:
		test	al,HWMBUTTON3PRESS
		je	@@notMB3Press
		push	ax
		mov	ah,HWMOUSEDEVICE
		mov	al,MBUTTON3PRESS	; send mouse 3 button down
		call	far ptr sendMessage
		pop	ax
@@notMB3Press:
		test	al,HWMBUTTON3RELEASE
		je	@@notMB3Release
		push	ax
		mov	ah,HWMOUSEDEVICE	; send mouse 3 button up
		mov	al,MBUTTON3RELEASE
		call	far ptr sendMessage
		pop	ax
@@notMB3Release:
		popall
		pop	ax
		ret

MouseIntHand	Endp

;{----------------------------------------------------------------------}
;{	InitMouse:							}
;{	  Initialize Mouse						}
;{----------------------------------------------------------------------}
InitMouse	Proc	Far

		pushall

		cmp	ax,CHGMODE
		jne	inmoexit
		mov	ax,seg DGROUP
		mov	ds,ax

		mov	ax,MRESET
		Int	MOUSEINT
		mov	mouseavail,ax		; mouse connected

		mov	ax,MSWAPINTRTNS
		mov	cx,0ffh			; interrupt mask
		mov	dx,seg MouseIntHand
		mov	es,dx
		mov	dx,offset MouseIntHand
		Int	MOUSEINT

		mov	oldMouseMask,cx
		mov	word ptr saveMouseInt,dx
		mov	word ptr saveMouseInt+2,es

		xor	ax,ax
		callBGI	install			; get es:bx pointer to DIT
	
		push	bx
		xor	cx,cx
		mov	dx,es:[bx].$xres
		mov	ax,dx
		shr	ax,1
		sub	ax,mouseHotX
		mov	_mouseX,ax
		mov	ax,MSETMINMAXH
		int	MOUSEINT
		pop	bx
		xor	cx,cx
		mov	dx,es:[bx].$yres
		mov	ax,dx
		shr	ax,1
		sub	ax,mouseHotY
		mov	_mouseY,ax
		mov	ax,MSETMINMAXV
		int	MOUSEINT
		
		mov	cx,_mouseX
		mov	dx,_mouseY
		mov	ax,MSETCURPOS
		int	MOUSEINT

		mov	mouseOn,1		; set mouse to on
		mov	ax,mouseavail
inmoexit:
		xor	ax,ax
		popall
		ret

InitMouse	Endp

;{----------------------------------------------------------------------}
;{	FindMouseDriver:						}
;{	  Find out If Mouse available					}
;{									}
;{	returns:							}
;{	  ax != 0 if available						}
;{----------------------------------------------------------------------}
FindMouseDriver	Proc	Far

		push	bx
		push	ds
		push	es
		
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	mouseavail,0		; no mouse available

		Mov	ah,35h			; get interrupt vector
		Mov	al,MOUSEINT		; of mouse Interrup
		Int	MSDOS			; through dos

		mov	ax,es
		or	ax,bx
		je	fimoexit
		cmp	byte ptr es:[bx],0cfh	; iret number
		je	fimoexit

		mov	ax,1			; found the driver
		mov	mouseavail,ax
fimoexit:
		pop	es
		pop	ds
		pop	bx
		ret

FindMouseDriver	Endp

;{----------------------------------------------------------------------}
;{	HideMouse:							}
;{	  Turn Mouse off						}
;{----------------------------------------------------------------------}
HideMouse	Proc	Far


		push	ax
		pushall
		    
		mov	ax,seg DGROUP
		mov	ds,ax
		dec	mouseOn
		jne	@@MouseNotOn

		les	bx,mouseBack		; get address of mouse
		mov	cx,oldMouseX
		mov	dx,oldMouseY
		mov	al,REPLACE_MODE
		callBGI	restorebitmap		; restore old back ground
@@MouseNotOn:
		popall
		pop	ax
		ret

HideMouse	Endp

;{----------------------------------------------------------------------}
;{	ShowMouse:							}
;{	  Turn Mouse On							}
;{----------------------------------------------------------------------}
ShowMouse	Proc	Far

		push	ax
		pushall

		mov	ax,seg DGROUP
		mov	ds,ax
		inc	mouseOn
		cmp	mouseOn,1
		jne	@@MouseOn

		mov	cx,_mouseX
		mov	oldMouseX,cx
		mov	dx,_mouseY
		mov	oldMouseY,dx
		les	bx,mouseBack
		callBGI	savebitmap

		mov	cx,_mouseX
		mov	dx,_mouseY
		les	bx,_mousePtr
		mov	al,XPARENT_MODE
		callBGI	restorebitmap
@@MouseOn:
		popall
		pop	ax
		ret

ShowMouse	Endp

;{----------------------------------------------------------------------}
;{	mousegch:							}
;{	  come here when a graphics parameter is changed		}
;{----------------------------------------------------------------------}
mousegch	Proc	Far

		cmp	ax,CHGPAGE
		jne	@@2
		push	ax
		push	bx
		push	ds

		mov	ax,MHIDECUR
		Int	MOUSEINT

;		mov	ax,seg DGROUP
;		mov	ds,ax
;		test	displayScr.scrflags,3	; cga type pageflip has no pages
;		je	@@1
;		mov	ax,MSetCRTPageNum
;		mov	bx,[pagenum]		; tell mouse we changed pages
;		Int	MouseInt
@@1:
		mov	ax,MSHOWCUR
		Int	MOUSEINT

		pop	ds
		pop	bx
		pop	ax
@@2:
		xor	ax,ax
		ret
		
mousegch	Endp

;{----------------------------------------------------------------------}
;{	UninstallMouse:							}
;{	  Uninstall mouse interrupt subroutine				}
;{----------------------------------------------------------------------}
UninstallMouse	Proc	Far

		pushall
		mov	ax,seg DGROUP
		mov	ds,ax
		xor	ax,ax
		xor	dx,dx
		xchg	ax,word ptr saveMouseInt+2
		xchg	dx,word ptr saveMouseInt
		mov	es,ax
		or	ax,dx
		je	@@NoMouseInstalled
		mov	ax,MSETINTADDR
		mov	cx,oldMouseMask
		Int	MOUSEINT
@@NoMouseInstalled:
		popall
		xor	ax,ax
		ret

UninstallMouse	Endp

;{----------------------------------------------------------------------}
;{	CheckMouseEvent:						}
;{	  Check for a mouse event that may have happened		}
;{	  in:								}
;{	    Nothing							}
;{	  out:								}
;{	    AL = Event #						}
;{	    AH = Event Device						}
;{----------------------------------------------------------------------}
CheckMouseEvent	Proc	Far

		mov	ax,seg DGROUP
		mov	ds,ax
		xor	ax,ax			; nothing happened default
		clc
		test	mousebits,0ffh		; see if any bits got set
		je	@@1
		stc
		xchg	ax,mousebits		; get bits and zero old ones
		mov	ah,MOUSEDEVICE		; and set device got from
@@1:
		ret

CheckMouseEvent	Endp

;{----------------------------------------------------------------------}
;{	ReadMouse:							}
;{	  Read mouse coordinates					}
;{	  in:								}
;{	     Nothing							}
;{	  out:								}
;{	     ax = x position						}
;{	     bx = y position						}
;{	     cx = buttons						}
;{----------------------------------------------------------------------}
ReadMouse	Proc	Far

		push	dx

		mov	ax,MGETINFO
		Int	MOUSEINT		; Get coords and buttons

		mov	ax,cx
		mov	cx,bx			; put into correct registers
		mov	bx,dx

		pop	dx
		ret

ReadMouse	Endp

cmouse		Ends

		end

