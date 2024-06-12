; $Header$

;{----------------------------------------------------------------------}
;{	MSDOS refresh library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	Written by Kenneth L. Hurley					}
;{	Started	9-14-1993						}
;{	Written with Turbo Assembler ver 1.0				}
;{----------------------------------------------------------------------}

; $Log$
		locals

		include	refresh.inc

DGROUP		GROUP	_DATA
_DATA		Segment Public 'DATA'

workRect	Rect	<>
workRect2	Rect	<>
tRefreshRect	Rect	<>
curHandle	dw	?

tempRect	Rect	<>
tempLastWin	dw	?

_DATA		Ends


EVENTHANDLER	Segment	Public 'FAR_DATA'

		Executehead	<"EVHA", 32767, refreshEvent, REFRESHDEVICE>

EVENTHANDLER	Ends



crefresh	Segment Public 'CODE'

		assume	cs:crefresh,ds:DGROUP,ss:nothing


;{----------------------------------------------------------------------}
;{ Function:	void _RefreshRect(rect *srcRect, int lastWindow);	}
;{ Description:	'C' callable function to refresh background and windows	}
;{ Parameters:	srcRect = pointer to rectangle structure to refresh	}
;{		lastWindow = to include last window or not		}
;{			     useful for window moves			}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
_RefreshRect	Proc C far

		arg	srcRect:dword, lastWindow:word
		uses	cx,dx,si,di,ds,es

		mov	ax,seg curHandle
		mov	ds,ax
		mov	curHandle,0		; start with background

@@WindowLoop:
		lds	si,srcRect		; get source rectangle
		mov	ax,seg DGROUP
		mov	es,ax
		mov	di,offset tRefreshRect	; and set up work Rectangle
		rept	(size Rect)/2
		movsw
		endm
		rept	(size Rect) MOD 2
		movsb
		endm

		mov	ax,seg DGROUP
		mov	ds,ax
		mov	ax,curHandle
		mov	bx,offset WinX		; window's rectangle list
		or	ax,ax
		jne	@@NotBackG1
		mov	ax,xMin
		mov	workRect.RectX,ax
		mov	ax,yMin
		mov	workRect.RectY,ax
		mov	ax,xMax			; else get background x,y,w,h
		sub	ax,xMin
		inc	ax
		mov	workRect.RectW,ax
		mov	ax,yMax
		sub	ax,yMin
		inc	ax
		mov	workRect.RectH,ax
		mov	ax,ds
		mov	bx,offset workRect
@@NotBackG1:
		mov	es,ax
		mov	di,bx
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	si,offset tRefreshRect
		call	far ptr rectangleUnion	; find rectangles union

		cmp	tRefreshRect.rectW,0
		je	@@NoUnion
		cmp	tRefreshRect.rectH,0	; any union in this puppy?
		je	@@NoUnion
		mov	ax,curHandle
		call	far ptr Refresh1Object	; refresh 1 window or background

@@NoUnion:
		mov	ax,curHandle
		or	ax,ax
		jne	@@NotBackG2		; isn't background

		mov	ax,seg _startWinHandle
		mov	es,ax
		mov	ax,es:_startWinHandle	; get starting handle
		cmp	ax,-1
		je	@@AllDone		; no windows yet
		mov	es,ax
		xor	di,di
		jmp	short @@NextWindow
@@NotBackG2:
		mov	es,ax
		xor	di,di
		mov	ax,es:[di].winNext
@@NextWindow:
		mov	curHandle,ax
		mov	es,ax
		xor	di,di
		cmp	ax,-1
		je	@@AllDone
		cmp	es:[di].winNext,-1	; is last window in list
		jne	@@WindowLoop		; loop back to next window 
		cmp	lastWindow,FALSE	; else check if want to update
		mov	lastWindow,FALSE	; next time thru drop out
		jne	@@WindowLoop		; last window
@@AllDone:
		ret

_RefreshRect	Endp


;{----------------------------------------------------------------------}
;{ Function:	refreshEvent						}
;{ Description:	come here when a refresh event happens to take care	}
;{		of it.							}
;{ Paramters:	ah = REFRESHDEVICE					}
;{		al = bits for device information			}
;{ Returns:	ax = !0 for taken care of				}
;{----------------------------------------------------------------------}
refreshEvent	Proc	Far

		pushall
		cmp	al,REDRAW_SYSRECT	; invalidated rectangle redraw?
		jne	@@NotRedrawSYS
		mov	ax,seg tempRect
		mov	bx,offset tempRect
		mov	cx,5			; eight message for this parm
		call	far ptr getMsgBuff	; get 6 messages
		cmp	ax,5
		je	@@AllOk
		mov	ax,INVALID_NUM_PARMS
		call	far ptr WinDebugger	; call grace debugger
@@AllOk:
		push	tempLastWin
		mov	ax,seg tempRect
		push	ax
		mov	ax,offset tempRect
		push	ax
		call	far ptr _RefreshRect
		add	sp,6			; clean up stack
		jmp	@@AllDone
@@NotRedrawSYS:
		cmp	al,BACK_SYSREDRAW
		jne	@@AllDone		; nothing to do

		mov	ax,seg tempRect
		mov	ds,ax
		mov	bx,offset tempRect
		mov	cx,4			; get 4 message parameters
		call	far ptr getMsgBuff
		cmp	ax,4
		je	@@AllOk2
		mov	ax,INVALID_NUM_PARMS
		call	far ptr WinDebugger
@@AllOk2:
		mov	ax,seg tempRect
		mov	bx,offset tempRect
		call	far ptr redrawBackGround
@@AllDone:
		popall
		mov	ax,1
		ret

refreshEvent	Endp

;{----------------------------------------------------------------------}
;{ Function:	void _RectangleUnion(rect *Rect1, rect *Rect2);		}
;{ Description:	'C' callable function to calculate the union of 	}
;{		two rectangles and return rectangle			}
;{ Parameters:	Rect1 = first rectangle *** this also gets result	}
;{		Rect2 = second rectangle				}
;{ Returns:	Rect1 = union rectangle structure			}
;{----------------------------------------------------------------------}
_RectangleUnion	Proc	C Far


		arg	Rect1:dword, Rect2:dword
		uses	cx,dx,si,di,ds,es


		lds	si,Rect1
		les	di,Rect2		; get rectangles

		call	far ptr RectangleUnion

		ret

_RectangleUnion	Endp


;{----------------------------------------------------------------------}
;{ Function:	RectangleUnion						}
;{ Description:	calculate the union of two rectangles and return 	}
;{		rectangle						}
;{ Parameters:	ds:si = first rectangle *** this also gets result	}
;{		es:di = second rectangle				}
;{ Returns:	ds:si = union rectangle structure			}							
;{----------------------------------------------------------------------}
RectangleUnion	Proc	far

		mov	ax,[si].rectX		; get first X
		mov	cx,[si].rectW		; get first W
		add	cx,ax			; get first x+w
		mov	bx,es:[di].rectX
		mov	dx,es:[di].rectW
		add	dx,bx
		cmp	ax,bx
		jge	@@FirstXBigger
	       	mov	ax,bx
@@FirstXBigger:
		cmp	cx,dx			; now check x+w
		jl	@@SecondXWBigger	; second is bigger
		mov	cx,dx			; else get first's x+w
@@SecondXWBigger:
		mov	[si].rectX,ax
		sub	cx,ax
		jge	@@SomeWidth
		xor	cx,cx
@@SomeWidth:
		mov	[si].rectW,cx

		mov	ax,[si].rectY		; get first Y
		mov	cx,[si].rectH		; get first H
		add	cx,ax			; get first y+h
		mov	bx,es:[di].rectY
		mov	dx,es:[di].rectH
		add	dx,bx
		cmp	ax,bx
		jge	@@FirstYBigger
	       	mov	ax,bx
@@FirstYBigger:
		cmp	cx,dx			; now check y+h
		jl	@@SecondYHBigger
		mov	cx,dx
@@SecondYHBigger:
		mov	[si].rectY,ax
		sub	cx,ax
		jge	@@SomeHeight
		xor	cx,cx
@@SomeHeight:
		mov	[si].rectH,cx
		ret

RectangleUnion	Endp

;{----------------------------------------------------------------------}
;{ Function:	void _Refresh1Object(int handle, rect *srcRect);	}
;{ Description:	'C' callable function to refresh 1 window or background	}
;{ Parameters:	handle = 0 for background !=0 is window handle		}
;{		srcRect pointer to rectangle to refresh			}
;{		*** destroys srcRectangle				}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
_Refresh1Object	Proc	C far

		uses	si,ds
		arg	handle:word
		arg	srcRect:dword

		mov	ax,handle
		lds	si,srcRect

		call	far ptr Refresh1Object	; call assembler routine

		ret

_Refresh1Object	Endp

;{----------------------------------------------------------------------}
;{ Function:	Refresh1Object						}
;{ Description:	refresh 1 object either background or window		}
;{ Parameters:	ax = handle 0 = background				}
;{ 		ds:si pointer to source rectangle			}
;{		*** destroys srcRectangle				}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
Refresh1Object	Proc	Far


		push	cx
		push	dx
		push	si
		push	di
		push	bp
		push	ds
		push	es

		mov	di,seg DGROUP
		mov	es,di
		mov	di,offset workRect2

		mov	es:curHandle,ax

		rept	(size Rect)/2
		movsw
		endm
		rept	(size Rect) MOD 2
		movsb
		endm

		sub	si,size Rect
		sub	di,size Rect

@@RectLoop:
		push	si
		push	ds

		mov	ax,seg DGROUP
		mov	ds,ax
		mov	ax,curHandle
		cmp	ax,0			; is background?
		jne	@@NotBack		; nope try window

		mov	ax,seg _startWinHandle
		mov	ds,ax
		mov	ax,_startWinHandle	; get starting handle
		jmp	short @@WindowLoop
@@NotBack:
		mov	ds,ax
		xor	si,si
		mov	ax,[si].winNext		; get next upper window
@@WindowLoop:
		cmp	ax,-1			; end all done
		je	@@SendComminque		; send communique

		mov	ds,ax
		mov	si,offset winX		; rectangle offset

		mov	di,seg workRect		; will get overwritten so..
		mov	es,di
		mov	di,offset workRect	; save in temporary rectangle

		rept	(size Rect)/2
		movsw
		endm
		rept	(size Rect) MOD 2
		movsb
		endm

		push	ds
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	es,ax
		mov	si,offset workRect
		mov	di,offset workRect2
		call	far ptr RectangleExclusion
		pop	ax			; recover window segment

		cmp	[si].rectW,0
		je	@@NoRefresh
		cmp	[si].rectH,0
		je	@@NoRefresh		; all clipped out

		rept	(size Rect)/2		; make workRect2 = workRect
		movsw
		endm
		rept	(size Rect) MOD 2
		movsb
		endm

		jmp	short @@NotBack		; and loop until end of windows
@@SendComminque:
		mov	di,seg tMsgQueue
		mov	es,di
		mov	di,offset tMsgQueue
		mov	ax,seg curHandle
		mov	ds,ax
		cmp	curHandle,0
		jne	@@WindUpdate
		mov	ah,REFRESHDEVICE
		mov	al,BACK_SYSREDRAW	; send refresh message
		stosw
		mov	ax,1
		jmp	short @@SendRect
@@WindUpdate:
		mov	ah,WINDOWDEVICE
		mov	al,WINDOW_SYSREDRAW
		stosw
		mov	ax,curHandle
		stosw
		mov	ax,2			; number of words to send
@@SendRect:
		mov	bx,ax
		mov	ax,workRect2.rectX
		stosw
		mov	ax,workRect2.rectY	; send rectangle to update
		stosw
		mov	ax,workRect2.rectW
		stosw
		mov	ax,workRect2.rectH
		stosw
		mov	ax,4
		add	ax,bx
		push	si
		push	ds
		push	es
		pop	ds
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	ds
		pop	si
		mov	workRect.rectW,0
@@NoRefresh:
		pop	ds
		pop	si

		mov	ax,seg DGROUP
		mov	es,ax
		mov	di,offset workRect
		mov	bp,offset workRect2

		mov	ax,es:[di].rectY	; get rectangle Y position
		add	ax,es:[di].rectH	; add in height taken care of
		mov	cx,es:[di].rectX	; and x position
		add	cx,es:[di].rectW	; and width taken care of

		mov	es:[di].rectY,ax
		mov	bx,[si].rectY
		add	bx,[si].rectH		; get src h&w
		cmp	ax,bx
		jl	@@NotResetY
		mov	ax,es:[bp].rectW	; last rect width not zero'ed
		add	[si].rectX,ax
		mov	cx,[si].rectX		; new x position
		neg	ax
		add	ax,[si].rectW		; taken care of width
		mov	[si].rectW,ax
		mov	es:[di].rectW,ax
		mov	ax,[si].rectY
		mov	es:[di].rectY,ax
		mov	ax,[si].rectH
		mov	es:[di].rectH,ax
@@NotResetY:
		mov	ax,cx
		mov	es:[di].rectX,ax
		mov	bx,[si].rectX
		add	bx,[si].rectW
		cmp	ax,bx
		jl	@@NotResetX
		mov	ax,es:[bp].rectH	; last rect Height not zero'ed
		add	[si].rectY,ax
		neg	ax
		add	ax,[si].rectH
		mov	[si].rectH,ax
		mov	es:[di].rectH,ax
		mov	ax,[si].rectX
		mov	es:[di].rectX,ax
		mov	ax,[si].rectW
		mov	es:[di].rectW,ax
@@NotResetX:
		cmp	[si].rectH,0
		je	@@AllDone
		cmp	[si].rectW,0
		je	@@AllDone
		mov	ax,es:[di].rectX
		mov	es:[bp].rectX,ax
		mov	ax,es:[di].rectY
		mov	es:[bp].rectY,ax
		mov	ax,es:[di].rectW
		mov	es:[bp].rectW,ax
		mov	ax,es:[di].rectH
		mov	es:[bp].rectH,ax
@@NextRect:
		jmp	@@RectLoop		; next rectangle

@@AllDone:
		pop	es
		pop	ds
		pop	bp
		pop	di
		pop	si
		pop	dx
		pop	cx
		ret

Refresh1Object	Endp

;{----------------------------------------------------------------------}
;{ Function:	void _RectangleExclusion(rect *firstrect, 		}
;{				rect *secondRect);			}
;{ Description:	'C' callable function to return rectangle exclusions	}
;{ Parameters:	firstRect = full rectangle that is trying to be 	}
;{				refreshed				}
;{		secondRect = working rectangle that gets passed back for}
;{				current exclusion rectangle		}
;{ Returns:	secondRect = exclusion rectangle			}
;{				width and/or height = 0 for finished	}
;{----------------------------------------------------------------------}
_RectangleExclusion Proc	C far

		uses	cx,dx,si,di,ds,es
		arg	firstRect:dword,secondRect:dword

		lds	si,secondRect		; get both rectangles
		les	di,firstRect

		call	far ptr RectangleExclusion
		ret

_RectangleExclusion Endp

;{----------------------------------------------------------------------}
;{ Function:	RectangleExclusion					}
;{ Description:	find the lowest possible exclusion rectangle 		}
;{			(unobstructed rectangle y has priority)		}
;{ Parameters:  ds:si = second rectangle				}
;{		es:di = first rectangle					}
;{ Returns:	ds:si = updates rectangle exclusion area.		}
;{----------------------------------------------------------------------}
RectangleExclusion Proc	far

		call	far ptr RectangleUnion	; see if any unions
		cmp	[si].rectW,0
		je	@@NoUnion
		cmp	[si].rectH,0
		jne	@@HasUnion		; no unions
@@NoUnion:
		mov	ax,es:[di].rectX
		mov	[si].rectX,ax
		mov	ax,es:[di].rectY	; send back entire area
		mov	[si].rectY,ax		; is unobstructed
		mov	ax,es:[di].rectW
		mov	[si].rectW,ax
		mov	ax,es:[di].rectH
		mov	[si].rectH,ax
		jmp	short @@AllDone
@@HasUnion:
		mov	ax,es:[di].rectX	; start of rectangle
		cmp	ax,[si].rectX
		je	@@LeftIntersect
		xchg	[si].rectX,ax		; and set unobstructed X
		sub	ax,es:[di].rectX	; make width
		mov	[si].rectW,ax
		mov	ax,es:[di].rectH
		mov	[si].rectH,ax		; save new rectangle height
		jmp	short @@AllDone
@@LeftInterSect:
		mov	ax,[si].rectY		; get rectangle Y
		cmp	ax,es:[di].rectY
		je	@@BothIntersect		; height has to be reduced
		sub	ax,es:[di].rectY
		mov	[si].rectH,ax
		mov	ax,es:[di].rectY
		mov	[si].rectY,ax		; new rectangle Y position
		mov	ax,es:[di].rectX
		mov	[si].rectX,ax		; no height intersection anymore
		mov	ax,es:[di].rectW
		mov	[si].rectW,ax
		jmp	short @@AllDone
@@BothIntersect:
		mov	ax,[si].rectH
		add	[si].rectY,ax
		neg	ax
		add	ax,es:[di].rectH
		mov	[si].rectH,ax
		jg	@@AllDone
		mov	ax,es:[di].rectH
		mov	[si].rectH,ax
		sub	[si].rectY,ax		; back to regular y position
		mov	ax,[si].rectW		; get intersection width
		add	[si].rectX,ax		; now get new x position
		neg	ax
		add	ax,es:[di].rectW	; amount left on right side
		mov	[si].rectW,ax
@@AllDone:
		ret

RectangleExclusion Endp

crefresh	Ends

 		end
