; $Header: e:/graphic\RCS\window.asm_v 1.2 1993/05/30 00:13:10 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	MsDos window library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log: window.asm_v $
; Revision 1.2  1993/05/30  00:13:10  KENH
; made mouse clicks work with selectable button on
; window.
;
; Revision 1.1  1993/04/23  21:07:33  KENH
; Initial revision
;

		locals

		include window.inc

WINOBJECTSIZE	segment public 'FAR_DATA'

		Executehead	<"WOSZ", WIN_TITLE_BAR, WinTitleBarSize>
		Executehead	<"WOSZ", WIN_CLOSE_BM, closeWinBMSize>
		Executehead	<"WOSZ", WIN_VSCROLL, vScrollSize>
		Executehead	<"WOSZ", WIN_HSCROLL, hScrollSize>
		Executehead	<"WOSZ", WIN_SIZE_BM, sizeWinBMSize>

WINOBJECTSIZE	ends

ADDWINOBJECTS	segment public 'FAR_DATA'

		Executehead	<"AWOB", WIN_TITLE_BAR, WinTitleBarAdd>
		Executehead	<"AWOB", WIN_CLOSE_BM, closeWinBMAdd>
		Executehead	<"AWOB", WIN_VSCROLL, vScrollAdd>
		Executehead	<"AWOB", WIN_HSCROLL, hScrollAdd>
		Executehead	<"AWOB", WIN_SIZE_BM, sizeWinBMAdd>

ADDWINOBJECTS	ends

INITEND		Segment Public 'FAR_DATA'

		Executehead	<"GREN", 32767, closeAllWindows>

INITEND		Ends

EVENTHANDLER	Segment	Public 'FAR_DATA'

		Executehead	<"EVHA", 50000, WindowMouseEvent, MOUSEDEVICE>
		Executehead	<"EVHA", 40000, ChangeWindowAttr, \
						MOUSEDEVICE>
		Executehead	<"EVHA", 32767, FocusWindowMouseEvent, \
						MOUSEDEVICE>
		Executehead	<"EVHA", 32767, WindowKeyEvent, KEYBOARDDEVICE>
		Executehead	<"EVHA", 32767, callWndProc, WINDOWDEVICE>
		Executehead	<"EVHA", 32767, ChangeWindowAttr, \
						WINDOWDEVICE>


EVENTHANDLER	Ends

DGROUP		GROUP	_DATA

_DATA		Segment Public 'DATA'
_DATA		Ends

windseg		segment public 'FAR_DATA'

mouseWindowPress dw	?
lastWinObjectX	dw	?
lastWinObjectY	dw	?
lastWinObject	dd	-1
_winHandle	label	word
winHandle	dw	-1		; window with focus
_startWinHandle	label	word
startWinHandle	dw	-1		; beginning window allocated
baseObjects	dd	?
otherObjects	dd	?
tWinX		dw	?
tWinY		dw	?
tWinW		dw	?
tWinH		dw	?
winflags	dw	?
tParmsPtr	dd	?
resizeMinX	dw	?
resizeMinY	dw	?
oldWinX1	dw	?
oldWinY1	dw	?
oldWinX2	dw	?
oldWinY2	dw	?
mouseGrabXoff	dw	?
mouseGrabYoff	dw	?


titlePattern	db	0, 0ffh, 0, 0ffh, 0, 0ffh, 0, 0ffh
dummystr	db	0
resizeON	db	0
WinMoveON	db	0
_rBandColor	label	byte
rBandColor	db	8

windseg		ends


wincseg		segment 'CODE'

		assume cs:wincseg,ds:windseg, es:windseg

;{----------------------------------------------------------------------}
;{ Function:	int _makeWindow(int workX, int workY, int workW, 	}
;{			int workH, int flags, void far *wndProc,	}
;{			parmstruct *parmsPtr);				}
;{ Descripion:	'C' callable routine to make a window in memory		}
;{ Parameters:	workX = work area's x position				}
;{	  	workY = work area's y position				}
;{	  	workW = work area's width				}
;{	  	workH = work area's height				}
;{	  	flags = bit 0 = draw window flag			}
;{			bits 1-15 see window object flags		}
;{	  	wndProc = windows procedure & parameters structure	}
;{				to call for events			}
;{ Returns:	ax = window's handle					}
;{----------------------------------------------------------------------}
_makeWindow	Proc	C Far

		arg	workX:word, workY:word, workW:word, workH:word
		arg	argwinFlags:word, argWinProc:dword, parmsPtr:dword

		uses	si,di,ds,es

		mov	ax,seg tParmsPtr
		mov	ds,ax
		mov	ax,word ptr parmsPtr
		mov	word ptr tParmsPtr,ax
		mov	ax,word ptr parmsPtr+2
		mov	word ptr tParmsPtr+2,ax

		mov	ax,workX
		mov	bx,workY
		mov	cx,workW		; get parameters
		mov	dx,workH
		mov	si,argwinFlags
		les	di,argWinProc

		call	far ptr makeWindow
		ret

_makeWindow	Endp

;{----------------------------------------------------------------------}
;{ Function:	makeWindow						}
;{ Description:	make window from x,y,w,h and flags			}
;{ Parameters:	ax = x position of work area				}
;{	  	bx = y position of work area				}
;{	  	cx = width of work area					}
;{	  	dx = height of work area				}
;{	  	si = bit 0 = draw window or not				}
;{	       	bit 1-15 = flags for objects on window			}
;{	  	es:di = procedure & parameter structure for window 	}
;{		events							}
;{		tParmsPtr far ptr to parameters				}
;{ Returns:	ax = window handle					}
;{----------------------------------------------------------------------}
makeWindow	Proc	far

		push	bp
		push	si
		push	di
		push	ds
		push	es


		push	ax
		push	bx
		push	cx
		push	dx
		call	far ptr getCurTextHeight
		pop	dx
		pop	cx
		pop	bx
		pop	ax

		mov	bp,seg tWinX
		mov	ds,bp

		cmp	dx,MINWINDOWHEIGHT
		jge	@@WinSizeOk
		mov	dx,MINWINDOWHEIGHT
@@WinSizeOk:
		mov	tWinX,ax
		mov	tWinY,bx		; save x,y,w,h
		mov	tWinW,cx
		mov	tWinH,dx

		mov	winflags,si
		mov	ax,si			; bits in ax
		call	near ptr getWindowMem
		or	bx,bx
		jne	@@WinAllocedOK
		jmp	@@makeWindowExit
@@WinAllocedOK:
		mov	bp,es			; save procedure pointer
		mov	es,bx
		xor	si,si
		mov	word ptr es:[si].winProcPtr,di
		mov	word ptr es:[si].winProcPtr+2,bp
		mov	cx,word ptr tParmsPtr
		mov	word ptr es:[si].winParmsPtr,cx
		mov	cx,word ptr tParmsPtr+2
		mov	word ptr es:[si].winParmsPtr+2,cx

		xor	di,di

		cmp	winHandle,-1		; first window alloced?
		je	@@FirstWinAlloced
		mov	cx,winHandle		; this window has focus
		mov	es,cx			; get to segment
		mov	es:[si].winNext,bx	; set one lower than current
		mov	es,bx			; get current alloced
		mov	es:[si].winPrevious,cx	; set previous to last window
		jmp	@@NotFirstWinAlloced	; and bypass is first window
@@FirstWinAlloced:
		mov	es:[di].winPrevious,-1
		mov	startWinHandle,es
@@NotFirstWinAlloced:
		mov	es:[di].winNext,-1	; set next window to null
		mov	winHandle,es		; this window has focus

		mov	es:[di].winOffset,dx	; save true malloced offset

		mov	di,size winHeader	; bypass header information

		mov	es:[di],ax		; save number of object structures
		add	di,2			; bypass number

		fartohuge di,es			; make huge pointer

		mov	word ptr baseObjects,di
		mov	word ptr baseObjects+2,es

		mov	cx,size object
		mul	cx
		mov	cx,ax			; save low bits
		longtopara dx,ax		; convert to paragraph offset

		mov	dx,es
		add	dx,ax

		and	cx,0fh
		add	di,cx			; and new offset

		mov	word ptr otherObjects,di
		mov	word ptr otherObjects+2,dx

		mov	ax,tWinX
		mov	bx,tWinY
		mov	cx,tWinW
		mov	dx,tWinH

		call	far ptr winRectAdd
		mov	tWinX,ax
		mov	tWinY,bx
		mov	tWinW,cx
		mov	tWinH,dx
		mov	dx,winflags		; recover bits

		mov	si,seg ADDWINOBJECTS
		mov	es,si
		xor	si,si
		
		mov	bx,WIN_TITLE_BAR	; initial test value
@@WinObjectLoop:
		test	bx,dx			; want this object in window?
		je	@@WinNextObject
		cmp	word ptr es:[si], 'WA'	; make sure id = 'AWOB'
		jne	@@WinNextObject
		cmp	word ptr es:[si+2],'BO'
		jne	@@WinNextObject

		push	bx
		push	dx
		mov	ax,tWinX
		mov	bx,tWinY		; get x,y,w,h
		mov	cx,tWinW
		mov	dx,tWinH
		call	dword ptr es:[si].routine
		mov	tWinX,ax
		mov	tWinY,bx		; save x,y,w,h
		mov	tWinW,cx
		mov	tWinH,dx
		pop	dx
		pop	bx

@@WinNextObject:
		add	si,size Executehead
		shl	bx,1
		jnc	@@WinObjectLoop

		mov	si,dx
		mov	es,winHandle		; get segment of window memory
		xor	di,di
		mov	ax,tWinX
		mov	es:[di].winX,ax
		mov	bx,tWinY
		mov	es:[di].winY,bx
		mov	cx,tWinW
		mov	es:[di].winW,cx
		mov	dx,tWinH
		mov	es:[di].winH,dx
		mov	es:[di].winID,'W'
		mov	es:[di].winID+1,'I'
		mov	es:[di].winID+2,'N'
		mov	es:[di].winID+3,'D'
		
		test	si,1
		je	@@DontDrawWindow

		mov	ax,es
		call	far ptr drawWindow
@@DontDrawWindow:
		mov	ax,winHandle
@@makeWindowExit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		
		ret

makeWindow	Endp

;{----------------------------------------------------------------------}
;{ Function:	int _DrawWindow(int winHandle);				}
;{ Description:	'C' callable function to draw a window			}
;{ Parameters:	winHandle = window's handle to draw			}
;{ Returns:	ax = 0 (FALSE) if no errors.				}
;{		ax = error number					}
;{----------------------------------------------------------------------}
_DrawWindow	Proc C	Far

		arg	argwinH:word

		mov	ax,argWinH
		call	far ptr DrawWindow

		ret

_DrawWindow	Endp

;{----------------------------------------------------------------------}
;{ Function:	DrawWindow						}
;{ Description:	draw a window						}
;{ Parameters:	ax = window's handle to draw				}
;{ Returns:	ax = 0 (FALSE) if no errors.				}
;{		ax = error number					}
;{----------------------------------------------------------------------}
DrawWindow	Proc	Far

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	es,ax
		xor	di,di
		mov	ax,INVALID_WINDOW_HANDLE ; in case bad handle
		cmp	word ptr es:[di].winID,'IW'
		jne	@@DrawWinExit
		cmp	word ptr es:[di].winID+2,'DN'
		jne	@@DrawWinExit

		mov	ax,es:[di].winX
		mov	bx,es:[di].winY
		call	far ptr hideMouse
		mov	cx,es
		mov	dx,size winHeader
		call	far ptr drawObjects
		call	far ptr showMouse

		mov	ax,WIN_WORK_AREA_ID
		mov	cx,es
		mov	dx,size winHeader
		call	far ptr findObjectID	; get objects' ID
		cmp	cx,-1
		jne	@@FoundObject
		cmp	dx,-1
		je	@@NoWSFound
@@FoundObject:
		xor	di,di
		add	ax,es:[di].winX
		add	bx,es:[di].winY
		push	es			; save window handle
		mov	ds,cx
		mov	si,dx			; pointer to rectangle
		add	ax,[si].objX
		inc	ax			; for outline
		add	bx,[si].objY
		inc	bx			; for outline
		mov	cx,[si].objW
		sub	cx,2			; for outline
		mov	dx,[si].objH
		sub	dx,2			; for outline
		mov	si,seg DGROUP
		mov	ds,si
		mov	es,si
		mov	tempRect.rectX,ax
		mov	tempRect.rectY,bx
		mov	tempRect.rectW,cx
		mov	tempRect.rectH,dx
		mov	ax,xMin			; current clip
		mov	bx,yMin
		mov	cx,xMax
		mov	dx,YMax
		sub	cx,ax
		inc	cx
		sub	dx,bx
		inc	dx	
		mov	workRect.rectX,ax
		mov	workRect.rectY,bx
		mov	workRect.rectW,cx
		mov	workRect.rectH,dx
		mov	si,offset workRect
		mov	di,offset tempRect
		call	far ptr RectangleUnion	; union is refresh area

		pop	bx			; recover window handle
		cmp	workRect.rectW,0
		je	@@NoWSFound
		cmp	workRect.rectH,0
		je	@@NoWSFound

		mov	di,seg tMsgQueue
		mov	es,di
		mov	di,offset tMsgQueue
		mov	ax,(WINDOWDEVICE SHL 8) OR WINDOW_REDRAW_WS
		stosw
		mov	ax,bx
		stosw	     			; store window handle
		mov	ax,workRect.rectX
		stosw	     			; and x,y,w,h
		mov	ax,workRect.rectY
		stosw
		mov	ax,workRect.rectW
		stosw
		mov	ax,workRect.rectH
		stosw

		push	es			; segment to temp msg queue
		pop	ds
		mov	si,offset tMsgQueue
		mov	ax,6			; 6 parameters to add
		call	far ptr addMsgBuff	; and add refresh work space
@@NoWSFound:
		xor	ax,ax
@@DrawWinExit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

DrawWindow	Endp

;{----------------------------------------------------------------------}
;{ Function:	refreshWindow						}
;{ Description:	called to refresh window when an event like this	}
;{		happens							}
;{ Parameters:	ax = window handle					}
;{		ds:si = pointer to rectangle clip structure		}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
refreshWindow	Proc	Far


		push	cx
		push	dx
		push	si
		push	ds

		call	far ptr hideMouse

		mov	cx,seg xMin
		mov	ds,cx
		push	xMin
		push	yMin
		push	xMax
		push	yMax
		push	ax
		mov	ax,[si].rectX
		mov	bx,[si].rectY
		mov	cx,[si].rectW
		mov	dx,[si].rectH		; get rectangle clipping
		add	cx,ax
		dec	cx
		add	dx,bx
		dec	dx
		call	far ptr globalSetClip
		pop	ax
		call	far ptr DrawWindow

		mov	ax,seg xMin
		mov	ds,ax

		pop	dx
		mov	yMax,dx
		pop	cx
		mov	xMax,cx
		pop	bx
		mov	yMin,bx
		pop	ax
		mov	xMin,ax
		callBGI	setClip			; reset clip region


		call	far ptr showMouse

		pop	ds
		pop	si
		pop	dx
		pop	cx

		ret
		
refreshWindow	Endp

;{----------------------------------------------------------------------}
;{ Function:	refreshWorkSpace					}
;{ Description:	called to refresh window's work space			}
;{ Parameters:	ax = window handle					}
;{		es:di = work space to refresh				}
;{		global clipping already set				}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
refreshWorkSpace Proc	Far


		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es

		mov	ax,seg DGROUP
		mov	ds,ax
		call	far ptr HideMouse

		mov	ah,PatternColor
		mov	al,BackColor
		mov	drawColor,al
		callBGI	color
@@NoNewColor:
		mov	al,REPLACE_MODE
		mov	drawmode,al
		callBGIutil setwritemode
@@NoNewDrawMode:
		mov	al,7			; solid fill style
		mov	PatternNum,al		; save new info
		callBGI	fillstyle

		mov	ax,es:[di].rectX
		mov	bx,es:[di].rectY
		mov	cx,es:[di].rectW
		mov	dx,es:[di].rectH
		add	cx,ax
		add	dx,bx
		dec	cx
		dec	dx

		callBGI	patbar

		call	far ptr ShowMouse

		pop	es
		pop	ds
		pop	si
		pop	di
		pop	dx
		pop	cx

		ret
		
refreshWorkSpace Endp


;{----------------------------------------------------------------------}
;{ Function:	callWndProc						}
;{ Description:	call current window procedure				}
;{ Parameters:	ah = device bits					}
;{		al = message #						}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
callWndProc	Proc	Far

		push	bx
		push	di
		push	es
		mov	bx,seg winHandle	; get segment or winhandle
		mov	ds,bx
		mov	bx,winHandle
		cmp	bx,-1			; is at least 1 window open
		je	@@NoWinAvailable	; nope
		mov	es,bx
		xor	di,di			; get to window structure
		push	es:[di].winParmsPtr	; and pass parameters to proc
		push	ax
		call	es:[di].winProcPtr	; and call procedure
		add	sp,6
@@NoWinAvailable:
		pop	es
		pop	di
		pop	bx
		ret
		

callWndProc	Endp

;{----------------------------------------------------------------------}
;{ Function:	int _SetWinTitle(int winHandle, char far *strptr);	}
;{ Description:	set the windows title to string passed in		}
;{ Parameters:	strptr = char string for window title bar		}
;{ Returns:	ax = 0 (FALSE) if no errors.				}
;{		ax = error number					}
;{----------------------------------------------------------------------}
_SetWinTitle	Proc C	Far

		arg	argwinH:word, argStrptr:dword, argFlags:word

		uses	bx,cx,dx

		mov	ax,argwinH
		mov	bx,word ptr argStrptr+2
		mov	cx,word ptr argStrptr
		mov	dx,argFlags

		call	far ptr SetWinTitle

		ret

_SetWinTitle	Endp

;{----------------------------------------------------------------------}
;{ Function:	SetWinTitle						}
;{ Description:	set the windows title to string passed in		}
;{ Parameters:	ax = windows handle					}
;{		bx:cx = char string for window title bar		}
;{		dx = string flags					}
;{ Returns:	ax = 0 (FALSE) if no errors.				}
;{		ax = error number					}
;{----------------------------------------------------------------------}
SetWinTitle	Proc	Far

		push	bx
		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es
		
		push	bx
		push	cx
		push	dx

		push	ax
		xchg	bx,cx
		mov	es,cx
		mov	di,bx
		mov	cx,-1			; starting size
		xor	al,al
		repne	scasb			; wait till zero byte found
		neg	cx
		sub	cx,2			; cx = string length

		mov	si,seg DGROUP
		mov	ds,si
		callBGI	textsize		; get text size

		mov	si,bx			; save text width for now
		pop	es

		xor	di,di
		mov	ax,INVALID_WINDOW_HANDLE ; in case bad handle
		cmp	es:[di].winID,'W'
		jne	@@SetWinTExit
		cmp	es:[di].winID+1,'I'	; check id
		jne	@@SetWinTExit
		cmp	es:[di].winID+2,'N'
		jne	@@SetWinTExit
		cmp	es:[di].winID+3,'D'
		jne	@@SetWinTExit
	      
		mov	cx,es
		mov	dx,size winHeader

		mov	ax,WIN_TITLE_STR_ID
		call	far ptr findObjectID	; find title bar string
		mov	ax,NO_TITLE_BAR_FOUND	; assume not found
		cmp	cx,-1
		jne	@@FoundIt		; check for not found
		cmp	dx,-1
		je	@@SetWinTExit
@@FoundIt:
		mov	es,cx			; found it so get pointer
		mov	di,dx
		pop	dx
		pop	cx
		pop	bx
		test	dx,STR_LEFT_JUSTIFY
		jne	@@Done_justify
		test	dx,STR_CENTERED
		je	@@NotCentered
		neg	si
		add	si,es:[di].objW		; si = width difference
		shr	si,1			; /2
		add	es:[di].objX,si
		jmp	@@Done_justify
@@NotCentered:
		test	dx,STR_RIGHT_JUSTIFY
		je	@@Done_justify
		neg	si
		add	si,es:[di].objW		; si = width difference
		mov	es:[di].objX,si
@@Done_justify:
		mov	es:[di].objW,0		; now defaults to string size
		les	di,es:[di].objptr	; to string structure

		mov	word ptr es:[di].strptr,cx ; and save off new string ptr
		mov	word ptr es:[di].strptr+2,bx
		xor	ax,ax
		jmp	@@SetWinTExit2
@@SetWinTExit:
		pop	dx
		pop	cx
		pop	bx
@@SetWinTExit2:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		ret

SetWinTitle	Endp

;{----------------------------------------------------------------------}
;{ Function:	int _SummonWinToTop(int winHandle);			}
;{ Description:	'C' callable function to summon the window defined by 	}
;{		handle to top of screen					}
;{ Parameters:	winHandle = window's handle to put on top		}
;{ Returns:	ax = 0 (FALSE) if no errors.				}
;{		ax = error number					}
;{----------------------------------------------------------------------}
_SummonWinToTop	Proc C	Far

		arg	argwinH:word

		mov	ax,argWinH
		call	far ptr SummonWinToTop

		ret


_SummonWinToTop	Endp

;{----------------------------------------------------------------------}
;{ Function:	SummonWintoTop						}
;{ Description:	Summon the window defined by handle to top of screen	}
;{ Parameters:	ax = window's handle					}
;{ Returns:	ax = 0 (FALSE) if no errors.				}
;{		ax = error number					}
;{----------------------------------------------------------------------}
SummonWintoTop	Proc	Far

		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	bx,seg winHandle	; get current top window
		mov	ds,bx
		cmp	ax,winHandle
		jne	@@NotSameHandle
		xor	ax,ax			; already at top no error
		jmp	@@SumWinExit
@@NotSameHandle:
		mov	es,ax
		xor	di,di
		mov	ax,INVALID_WINDOW_HANDLE ; in case bad handle
		cmp	word ptr es:[di].winID,'IW'
		jne	@@SumWinExit
		cmp	word ptr es:[di].winID+2,'DN'
		jne	@@SumWinExit

		mov	ax,es:[di].winPrevious	; get previous handle of this
		mov	cx,es:[di].winNext

		mov	dx,es			; save new window's handle
		mov	es,cx			; get next window's structure
		mov	es:[di].winPrevious,ax	; save off new previous
		cmp	ax,-1			; new start window
		jne	@@NotNewStart1
		mov	startWinHandle,es
		jmp	short @@NoPrevious
@@NotNewStart1:
	     	mov	es,ax
		mov	es:[di].winNext,cx	; set previous's next to ours
@@NoPrevious:
;
;  ----- Now it is removed from list re-insert on top
;
		mov	cx,winHandle		; get current window's ptr
		mov	es,cx
		mov	es:[di].winNext,dx	; save new top window
		mov	es,dx			; get new top window pointer
		mov	es:[di].winPrevious,cx
		mov	es:[di].winNext,-1	; now top window

		mov	winHandle,dx
		mov	ax,dx
		call	far ptr drawWindow
@@SumWinExit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

SummonWinToTop	Endp

;{----------------------------------------------------------------------}
;{ Function:	_DefWindProc(int msgBits);				}
;{ Description:	Come here when a window receives a message and does	}
;{		nothing with it						}
;{ Parameters:	msgBits = high byte = device #				}
;{			  low byte = bits for device			}
;{----------------------------------------------------------------------}
_DefWindProc	Proc C	Far

		arg	msgBits:word

		mov	ax,msgBits
		push	cs
		call	near ptr DefWindProc
		ret

_DefWindProc	Endp


;{----------------------------------------------------------------------}
;{ Function:	DefWindProc						}
;{ Description:	Come here when a window receives a message and does	}
;{		nothing with it						}
;{ Parameters:	ah = device #						}
;{		al = bits for device					}
;{ returns:	0 if to continue or 1 if remove message			}
;{----------------------------------------------------------------------}
DefWindProc	Proc	far

		push	bp
		push	si
		push	di
		push	ds
		push	es

		cmp	ah,WINDOWDEVICE
		jne	@@NotWinDev
		cmp	al,WINDOWITEMRELEASE
		jne	@@NotItemRel
; only get temp in case we don't know how to handle it
		call	far ptr getTempMsgWord 
		cmp	ax,WIN_CLOSE_ID
		jne	@@NotCloseItem		; don't know how to handle it
		call	far ptr getMsgQueue	; remove parameter
		mov	ah,WINDOWDEVICE
		mov	al,WINDOW_CLOSE		; send close window comminque
		jmp	short @@SendChWinAttr
@@NotCloseItem:
		cmp	ax,WIN_SIZE_ID
		jne	@@NotSizeID1
		call	far ptr getMsgQueue	; remove parameter
		mov	ah,WINDOWDEVICE
		mov	al,WINDOW_END_RESIZE	; send end of window resize
		jmp	short @@SendChWinAttr
@@NotSizeID1:
		cmp	ax,WIN_TITLE_BAR_ID
		jne	@@NotWinDev
		call	far ptr getMsgQueue
		mov	ah,WINDOWDEVICE
		mov	al,WINDOW_END_MOVE	; send end of window move
@@SendChWinAttr:
		mov	bx,seg winHandle
		mov	ds,bx
		mov	bp,winHandle

		mov	di,seg tMsgQueue
		mov	es,di
		mov	di,offset tMsgQueue
		stosw
		mov	ax,bp			; save ID of object
		stosw
		mov	ax,2
		push	si
		push	ds
		push	es
		pop	ds
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	ds
		pop	si
		jmp	@@NotWinDev
@@NotItemRel:
		cmp	al,WINDOW_CLOSE
		jne	@@NotWinClose
		call	far ptr getMsgQueue	; get handle of window
		call	far ptr freeWindow	; and free up window
		jmp	@@NotWinDev
@@NotWinClose:
		cmp	al,WINDOW_SYSREDRAW	; redraw system area
		jne	@@NotSysRedraw
		call	far ptr getMsgQueue	; get word for handle
		mov	di,ax
		mov	ax,seg DGROUP
		mov	bx,offset workRect
		mov	cx,4
		call	far ptr getMsgBuff	; get messages for Rect
		cmp	cx,4
		je	@@AllOk
		mov	ax,INVALID_NUM_PARMS
		call	far ptr WinDebugger	; call grace debugger
@@AllOk:
		mov	ax,di			; recall window handle
		mov	si,seg DGROUP
		mov	ds,si
		mov	si,offset workRect
		call	far ptr refreshWindow
@@NotSysRedraw:
		cmp	al,WINDOW_REDRAW_WS
		jne	@@NotWinRedraw

		call	far ptr getMsgQueue
		mov	di,ax
		mov	ax,seg DGROUP
		mov	bx,offset workRect
		mov	cx,4
		call	far ptr getMsgBuff
		cmp	cx,4
		je	@@AllOk2
		mov	ax,INVALID_NUM_PARMS
		call	far ptr WinDebugger	; parms passed incorrectly
@@AllOk2:
		mov	ax,di
		mov	di,seg DGROUP
		mov	es,di
		mov	di,offset workRect
		call	far ptr refreshWorkSpace
@@NotWinRedraw:
		cmp	al,WINDOWITEMPRESS
		jne	@@NotWinPress
		call	far ptr getTempMsgWord 
		cmp	ax,WIN_SIZE_ID
		jne	@@NotSizeID2
		call	far ptr getMsgQueue	; remove parameter
		mov	ax,seg resizeON
		mov	ds,ax
		cmp	resizeON,TRUE		; already resizing window
		je	@@NotWinPress		; then don't start it again
		mov	ah,WINDOWDEVICE
		mov	al,WINDOW_START_RESIZE	; send start of window resize
		jmp	@@SendChWinAttr
@@NotSizeID2:
		cmp	ax,WIN_TITLE_BAR_ID
		jne	@@NotWinDev
		call	far ptr getMsgQueue	; remove parameter
		mov	ax,seg WinMoveON
		mov	ds,ax
		cmp	WinMoveON,TRUE		; already moving window?
		je	@@NotWinPress		; then don't start again
		mov	ah,WINDOWDEVICE
		mov	al,WINDOW_START_MOVE	; send start of window move
		jmp	@@SendChWinAttr
@@NotWinPress:
@@NotWinDev:
		xor	ax,ax
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

DefWindProc	Endp

;{----------------------------------------------------------------------}
;{ Function:	ChangeWindowAttr					}
;{ Description:	change window attributes when necessary			}
;{ Parameters:	ah = device #						}
;{		al = bits for device					}
;{ returns:	0 if to continue or 1 if remove message			}
;{----------------------------------------------------------------------}
ChangeWindowAttr Proc	far

		pushall
		mov	bx,seg ResizeON
		mov	ds,bx
		cmp	ah,WINDOWDEVICE
		jne	@@NotWinDev
		cmp	al,WINDOW_START_RESIZE
		jne	@@NotStartResize
		mov	ResizeON,TRUE
		jmp	short @@StartChange
@@NotStartResize:
		cmp	al,WINDOW_START_MOVE
		jne	@@NotStartMove
		mov	WinMoveOn,TRUE
@@StartChange:
		call	far ptr getMsgQueue	; remove parameter
		mov	es,ax			; get segment of window memory
		xor	di,di
		mov	ax,es:[di].WinX
		mov	bx,es:[di].WinY
		mov	cx,es:[di].WinW
		mov	dx,es:[di].WinH
		add	cx,ax
		dec	cx
		add	dx,bx
		dec	dx
		mov	oldWinX1,ax
		mov	oldWinY1,bx
		mov	oldWinX2,cx
		mov	oldWinY2,dx
		mov	resizeMinX,ax
		mov	resizeMinY,bx
		mov	bp,seg DGROUP
		mov	ds,bp
		mov	di,_mouseX
		mov	si,_mouseY
		sub	di,cx
		sub	si,dx
		mov	bp,seg mouseGrabXoff
		mov	ds,bp
		
		mov	mouseGrabXoff,di
		mov	mouseGrabYoff,si
		call	near ptr winRect
		mov	ax,1
		popall
		ret
@@NotStartMove:
		cmp	al,WINDOW_END_RESIZE
		jne	@@NotEndResize
		mov	ResizeOn,FALSE
		jmp	@@RemoveLastRect
@@NotEndResize:
		cmp	al,WINDOW_END_MOVE
		jne	@@NotWinDev
		mov	WinMoveON,FALSE
@@RemoveLastRect:
		call	far ptr getMsgQueue	; remove parameter
		mov	ax,oldWinX1
		mov	bx,oldWinY1
		mov	cx,oldWinX2		; get mouse x & y
		mov	dx,oldWinY2		; now draw initial rectangle
		call	near ptr winRect
		mov	ax,seg winHandle
		mov	ds,ax
		mov	es,winHandle		; grab handle of window
		xor	di,di
		mov	ax,oldWinX1
		mov	bx,oldWinY1
		xchg	es:[di].WinX,ax
		xchg	es:[di].WinY,bx
		mov	tWinX,ax
		mov	tWinY,bx
		mov	ax,oldWinX2
		mov	bx,oldWinY2
		sub	ax,oldWinX1
		inc	ax
		sub	bx,oldWinY1
		inc	bx
		xchg	es:[di].WinW,ax
		xchg	es:[di].WinH,bx
		mov	tWinW,ax
		mov	tWinH,bx
		mov	ax,es
		call	far ptr DrawWindow

		mov	ax,FALSE		; don't redraw last window
		push	ax
		mov	ax,seg tWinX
		push	ax
		mov	di,offset tWinX
		push	di
		call	far ptr _RefreshRect
		add	sp,6			; clean up stack
		mov	ax,1
		popall
		ret
@@NotWinDev:
		cmp	ah,MOUSEDEVICE
		jne	@@NotMDevice
		cmp	al,MOUSEMOVEMENT
		jne	@@NotMouseMove
		cmp	ResizeON,TRUE
		jne	@@NotResizeOn
		call	far ptr resizeWin
		mov	ax,1
		popall
		ret
@@NotResizeON:
		cmp	WinMoveON,TRUE
		jne	@@NotMDevice
		call	far ptr MoveWin
		mov	ax,1
		popall
		ret
@@NotMouseMove:
		cmp	al,MBUTTON1RELEASE	; button released?
		jne	@@NotMDevice
		cmp	ResizeON,TRUE
		je	@@RemoveCHRect
		cmp	WinMoveON,TRUE
		jne	@@NotMDevice
@@RemoveCHRect:
		mov	si,seg lastWinObject
		mov	ds,si
		les	si,lastWinObject	; get last object pointer
		mov	bp,es:[si].objID	; and id for object
; deselect last object if not same
		call	far ptr deselLastWinObject
		mov	MouseWindowPress,FALSE	; and reset flag
		mov	di,seg tMsgQueue
		mov	es,di
		mov	di,offset tMsgQueue
		mov	ah,WINDOWDEVICE
		mov	al,WINDOWITEMRELEASE	; send end of window resize
		stosw
		mov	ax,bp			; save ID of object
		stosw
		mov	ax,2
		push	si
		push	ds
		push	es
		pop	ds
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	ds
		pop	si
		mov	ax,1
		popall
		ret
@@NotMDevice:
		popall
		xor	ax,ax
		ret

ChangeWindowAttr Endp

;{----------------------------------------------------------------------}
;{ Function:	winRect							}
;{ Description:	local function to draw an xor'ed rectangle at the	}
;{ 		specified position					}
;{ Parameters:	ax,bx,cx,dx = x1, y1, x2, y2 or rectangle		}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
winRect		Proc	Near

		push	si
		push	ds
		push	ax

		call	far ptr hideMouse
		mov	ax,seg rBandColor
		mov	ds,ax

		mov	al,rBandColor		; rubber band color
		mov	si,seg DGROUP
		mov	ds,si
		cmp	al,drawColor
		je	@@NoNewdrawColor
		mov	drawColor,al
		mov	ah,PatternColor	 	; color change for fillpattern?
		callBGI	color			; set current color to draw in
@@NoNewdrawColor:
		mov	al,XOR_MODE
		cmp	al,drawmode
		je	@@NoNewDrawMode
		mov	drawmode,al
		callBGIutil setwritemode
@@NoNewDrawMode:
		pop	ax
		push	ax
		push	bx
		push	cx
		push	dx
		mov	dx,bx
		callBGI	vect			; do first line (top)

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		push	ax
		push	bx
		push	cx
		push	dx

		mov	cx,ax
		callBGI	vect			; second line (left)

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		push	ax
		push	bx
		push	cx
		push	dx

		mov	ax,cx
		callBGI	vect			; third line (right)

		pop	dx
		pop	cx
		pop	bx
		pop	ax

		mov	bx,dx
		callBGI	vect			; fourth line (bottom)

		call	far ptr showMouse
		pop	ds
		pop	si

		ret

winRect		endp
		
;{----------------------------------------------------------------------}
;{ Function:	MoveWin							}
;{ Description:	move the window until mouse is released			}
;{ Parameters:	.							}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
MoveWin		Proc	far

		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	ax,seg oldWinX2
		mov	ds,ax
;
; ----- first loop remove old box
;
		mov	di,2
		mov	cx,oldWinX2
		mov	dx,oldWinY2
@@DrawLoop:
		mov	ax,oldWinX1
		mov	bx,oldWinY1

		call	near ptr WinRect

		mov	cx,seg DGROUP
		mov	ds,cx
		mov	cx,_mouseX		; get mouse x & y
		mov	dx,_mouseY
		mov	ax,seg oldWinX2
		mov	ds,ax
		sub	cx,mouseGrabXoff
		sub	dx,mouseGrabYoff
		mov	ax,oldWinX1
		mov	bx,oldWinY1
		sub	ax,oldWinX2
		sub	bx,oldWinY2
		mov	oldWinX2,cx
		mov	oldWinY2,dx
		add	ax,cx
		add	bx,dx
		mov	oldWinX1,ax
		mov	oldWinY1,bx

		dec	di
		jne	@@DrawLoop
@@DontUpdate:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

MoveWin		Endp

;{----------------------------------------------------------------------}
;{ Function:	resizeWin						}
;{ Description:	resize the window until mouse is released		}
;{ Parameters:	.							}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
resizeWin	Proc	far

		push	bp
		push	si
		push	di
		push	ds
		push	es
		mov	ax,seg DGROUP
		mov	ds,ax

		mov	cx,_mouseX		; get mouse x & y
		mov	dx,_mouseY

		mov	ax,seg resizeMinX
		mov	ds,ax
		sub	cx,mouseGrabXoff
		sub	dx,mouseGrabYoff

		cmp	cx,resizeMinX
		jl	@@DontUpdate
		cmp	dx,resizeMinY
		jl	@@DontUpdate

;
; ----- first loop remove old box
;
		mov	di,2
		mov	cx,oldWinX2
		mov	dx,oldWinY2
@@DrawLoop:
		mov	ax,oldWinX1
		mov	bx,oldWinY1

		call	near ptr WinRect

		mov	cx,seg DGROUP
		mov	ds,cx
		mov	cx,_mouseX		; get mouse x & y
		mov	dx,_mouseY
		mov	ax,seg oldWinX2
		mov	ds,ax
		sub	cx,mouseGrabXoff
		sub	dx,mouseGrabYoff
		mov	oldWinX2,cx
		mov	oldWinY2,dx

		dec	di
		jne	@@DrawLoop
@@DontUpdate:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

resizeWin	Endp


;{----------------------------------------------------------------------}
;{ Function:	deselLastWinObject					}
;{ Description:	deselect the last window object selected		}
;{ Parameters:	.							}
;{ Returns:	ax = 0 for object not found OBJID, otherwise		}
;{----------------------------------------------------------------------}
deselLastWinObject Proc	far

		pushall
		mov	si,seg lastWinObject
		mov	ds,si
		les	si,lastWinObject	; get last object pointer
		mov	bp,es:[si].objID	; and id for object
		xor	ax,ax			; no last object
		cmp	word ptr lastWinObject,-1
		jne	@@LastObjectAvail
		cmp	word ptr lastWinObject+2,-1
		je	@@NoObjectFound		; nope
@@LastObjectAvail:
		assume	es:NOTHING
		mov	ax,seg tMsgQueue
		mov	es,ax
		mov	di,offset tMsgQueue	; pointer to temp msg queue
		cmp	MouseWindowPress,FALSE	; see if mouse released
		je	@@MouseRelease		; yes, then deselect last object
		xor	ax,ax
		cmp	dx,word ptr lastWinObject
		jne	@@MouseRelease		; still in last object?
		cmp	cx,word ptr lastWinObject+2
		je	@@NoObjectFound
@@MouseRelease:
		mov	ah,OBJECTDEVICE		; deselect last object selected
		mov	al,OBJDESELECT
		stosw
		mov	ax,lastWinObjectX	; send object X
		stosw
		mov	ax,lastWinObjectY	; and Y
		stosw
		mov	dx,word ptr lastWinObject
		mov	ax,dx
		stosw				; and pointer to object
		mov	cx,word ptr lastWinObject+2
		mov	ax,cx
		stosw
		assume	es:windseg
@@NoError1:

		mov	ax,5
		push	si
		push	ds
		push	es
		pop	ds
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	ds
		pop	si
		mov	word ptr lastWinObject,-1
		mov	word ptr lastWinObject+2,-1
		mov	ax,bp
@@NoObjectFound:
		popall
		ret

deselLastWinObject Endp


;{----------------------------------------------------------------------}
;{ Function:	WindowPress						}
;{ Description:	select window item and send object redraw 		}
;{ Parameters:	ax = x position						}
;{		bx = y position						}
;{		cx:dx = object pointer					}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
WindowPress	Proc	far

		push	ax
		push	bx
		push	cx
		push	dx
		call	far ptr deselLastWinObject
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		mov	lastWinObjectX,ax
		mov	lastWinObjectY,bx
		cmp	dx,word ptr lastWinObject
		jne	@@NewObject
		cmp	cx,word ptr lastWinObject+2
		je	@@NotWindowPress
@@NewObject:
		assume	es:NOTHING
		mov	word ptr lastWinObject,dx
		mov	word ptr lastWinObject+2,cx
		mov	bp,ax
		mov	ax,seg tMsgQueue
		mov	es,ax
		mov	di,offset tMsgQueue	; send message to select object
		mov	ah,OBJECTDEVICE
		mov	al,OBJSELECT
		stosw
		mov	ax,bp			; send x
		stosw
		mov	ax,bx			; and y
		stosw
		mov	ax,dx
		stosw
		mov	ax,cx
		stosw
		mov	ax,5
		push	si
		push	ds
		push	es
		pop	ds
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	ds
		pop	si
		mov	di,offset tMsgQueue
		mov	ds,cx
		mov	si,dx
		mov	bp,[si].objID
		mov	ah,WINDOWDEVICE
		mov	al,WINDOWITEMPRESS	; send object pressed/released
		stosw
		mov	ax,bp
		stosw
		mov	ax,2
		push	si
		push	ds
		push	es
		pop	ds
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	ds
		pop	si
		assume	es:windseg
@@NotWindowPress:
		ret

WindowPress	Endp

;{----------------------------------------------------------------------}
;{ Function:	WindowMouseEvent					}
;{ Description:	Come here when a mouse event occurs and send to window	}
;{		that has focus or window mouse is over			}
;{ Parameters:	ah = device #						}
;{		al = bits for device					}
;{----------------------------------------------------------------------}
WindowMouseEvent Proc	Far

		pushall
		mov	cx,seg winHandle
		mov	ds,cx
		cmp	winHandle,-1
		jne	@@WinAvailable
		jmp	@@ExitWindow
@@WinAvailable:
		cmp	ah,MOUSEDEVICE		; mouse device event?
		je	@@IsMouseEvent
		jmp	@@NotMouseEvent
@@IsMouseEvent:
		cmp	al,MBUTTON1PRESS	; button pressed?
		jne	@@ExitWindow
		mov	MouseWindowPress,TRUE	; then set flag
@@NotMouseUp:
		mov	ax,winHandle		; get current focus
		mov	es,ax
		xor	di,di
@@ScanLoop:
		mov	cx,es
		mov	dx,offset winX		; rectangle structure
		push	ds
		assume	ds:DGROUP
		mov	si,seg DGROUP
		mov	ds,si
		mov	ax,_mouseX		; get mouse x & y
		mov	bx,_mouseY
		pop	ds
		assume	ds:windseg
		call	far ptr ptInRect	; see if in window's rectangle
		or	ax,ax
		jne	@@FoundOne
		mov	ax,es:[di].winPrevious	; get previous window
		mov	es,ax
		cmp	ax,-1
		jne	@@scanLoop
		jmp	@@ExitWindow
@@FoundOne:
		mov	ax,es
		call	far ptr SummonWinToTop
@@ExitWindow:
@@NotMouseEvent:
		xor	ax,ax
		popall
		ret

WindowMouseEvent Endp

;{----------------------------------------------------------------------}
;{ Function:	FocusWindowMouseEvent					}
;{ Description:	Come here when a mouse event occurs and send to window	}
;{		that has focus or window mouse is over			}
;{ Parameters:	ah = device #						}
;{		al = bits for device					}
;{----------------------------------------------------------------------}
FocusWindowMouseEvent Proc	Far

		pushall
		mov	cx,seg winHandle
		mov	ds,cx
		cmp	winHandle,-1
		jne	@@WinAvailable
		jmp	@@ExitWindow
@@WinAvailable:
		cmp	ah,MOUSEDEVICE		; mouse device event?
		je	@@IsMouseEvent
		jmp	@@NotMouseEvent
@@IsMouseEvent:
		cmp	al,MBUTTON1PRESS	; button pressed?
		jne	@@NotMouseDown
		mov	MouseWindowPress,TRUE	; then set flag
		jmp	@@NotMouseUp
@@NotMouseDown:
		cmp	al,MBUTTON1RELEASE	; button released?
		jne	@@NotMouseUp
		mov	MouseWindowPress,FALSE	; then reset flag
@@NotMouseUp:
		push	ax
		push	ds
		mov	ax,winHandle
		mov	es,ax
		xor	di,di
		mov	ax,es:[di].WinX		; get x & y of window
		mov	bx,es:[di].WinY
		mov	cx,es			; and pointer
		mov	dx,size winHeader
		assume	ds:DGROUP
		mov	si,seg DGROUP
		mov	ds,si
		mov	bp,_mouseX		; get mouse x & y
		mov	si,_mouseY
		mov	di,(OBJ_SELECTABLE OR OBJ_NOTIFY)
		pop	ds
		assume	ds:windseg
		call	far ptr ptInObject	; see if mouse points to object
		pop	bp			; recover device bits
		and	bp,0ffh
@@ObjectFound:
		cmp	MouseWindowPress,TRUE
		jne	@@NotWindowPress	; nope
		cmp	cx,-1
		jne	@@WindowPress
		cmp	dx,-1
		je	@@NotWindowPress	; is mouse over selectable item
@@WindowPress:
		call	far ptr WindowPress
		jmp	@@ExitWindow
@@NotWindowPress:
		call	far ptr deselLastWinObject ; deselect last object if not same
		or	ax,ax
		je	@@NoObjectFound
@@MouseInObject:
		cmp	MouseWindowPress,TRUE
		je	@@ObjectPress
		cmp	cx,-1
		jne	@@ObjectRelease
		cmp	dx,-1
		je	@@NoObjectFound
@@ObjectRelease:
		mov	bp,ax			; save off last window objID
		assume	es:NOTHING
		mov	di,seg tMsgQueue
		mov	es,di
		mov	di,offset tMsgQueue
		mov	ah,WINDOWDEVICE
		mov	al,WINDOWITEMRELEASE	; send object pressed/released
		stosw
		mov	ax,bp			; save ID of object
		stosw
		mov	ax,2
		push	si
		push	ds
		push	es
		pop	ds
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	ds
		pop	si
		assume	es:windseg
		jmp	@@ExitWindow
@@ObjectPress:
		mov	di,seg tMsgQueue
		mov	es,di
		mov	di,offset tMsgQueue
		mov	ds,cx
		mov	si,dx
		mov	bp,[si].objID
		mov	ah,WINDOWDEVICE
		mov	al,WINDOWITEMPRESS	; send object pressed/released
		stosw
		mov	ax,bp
		stosw
		mov	ax,2
		push	si
		push	ds
		push	es
		pop	ds
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	ds
		pop	si
@@NoObjectFound:
@@ExitWindow:
@@NotMouseEvent:
		xor	ax,ax
		popall
		ret

FocusWindowMouseEvent Endp

nParms		dw	?
;{----------------------------------------------------------------------}
;{ Function:	WindowKeyEvent						}
;{ Description:	Come here when a Key event occurs and send to window	}
;{		that has focus						}
;{ Parameters:	ah = device #						}
;{		al = bits for device					}
;{----------------------------------------------------------------------}
WindowKeyEvent Proc	Far

		pushall
		mov	bx,seg winHandle
		mov	ds,bx
		cmp	al,KEYBOARDPRESS	; keyboard press?
		jne	@@NotKeyPress
		cmp	winHandle,-1		; first window alloced?
		je	@@NotMyEvent
		mov	es,winHandle		; get window with focus
		xor	di,di
		mov	ah,WINDOWDEVICE
		mov	al,WINDOW_KEY_PRESS
		call	far ptr addMsgQueue
		mov	cx,ax
		mov	ah,INPSTAT		; see if convert to code
		int	MSDOS
		cmp	al,0ffh	
		jne	@@NotMyEvent
		mov	ah,UNFCHRIN
		int	MsDos
		and	ax,0ffh
		jne	@@NotMultiKey
		mov	ah,UNFCHRIN
		int	MsDos
		mov	ah,al
		xor	al,al
@@NotMultiKey:
		or	cx,cx
		jne	@@winKeyExit		; kill event
		mov	bx,ax			; save for later
		mov	cx,seg tMsgQueue
		mov	es,cx
		mov	di,offset tMsgQueue
		mov	ah,WINDOWDEVICE
		mov	al,WINDOW_COOKED_KEY
		stosw
		mov	ax,bx
		stosw
		jmp	@@winKeyExit
@@NotKeyPress:
		cmp	al,KEYBOARDRELEASE
		jne	@@notMyEvent
		cmp	winHandle,-1		; first window alloced?
		je	@@NotMyEvent
		mov	es,winHandle		; get window with focus
		xor	di,di
		mov	ah,WINDOWDEVICE
		mov	al,WINDOW_KEY_RELEASE
		call	far ptr addMsgQueue
		jmp	@@winKeyExit
@@notMyEvent:
		xor	ax,ax
@@winKeyExit:
		popall
		ret

WindowKeyEvent Endp

;{----------------------------------------------------------------------}
;{	addObjectRectS:							}
;{	  add object Rectangle structure				}
;{									}
;{	parameters:							}
;{	  cx = width							}
;{	  dx = height							}
;{	  bp = rectangle color						}
;{	  es:di = uninitialize data pointer				}
;{	  es:si = offset for child object of this tree			}
;{----------------------------------------------------------------------}
addObjectRectS	Proc	Near

		mov	es:[di].objW,cx
		mov	es:[di].objH,dx
		mov	es:[di].objtype,OBJ_RECT
		mov	es:[di].objflags,0
		mov	word ptr es:[di].objptr,si
		mov	word ptr es:[di].objptr+2,es

		add	di,size object

		mov	es:[si].rectflags,0
		mov	es:[si].rectcol,0
		mov	es:[si].rectDrawMode,REPLACE_MODE
		add	si,size objRect

		ret

addObjectRectS	Endp

;{----------------------------------------------------------------------}
;{	addObjectBarS:							}
;{	  add object Bar structure					}
;{									}
;{	parameters:							}
;{	  cx = width							}
;{	  dx = height							}
;{	  bp = fillpattern/fillcolor					}
;{	  es:di = uninitialize data pointer				}
;{	  es:si = offset for child object of this tree			}
;{----------------------------------------------------------------------}
addObjectBarS	Proc	Near

		mov	es:[di].objW,cx
		mov	es:[di].objH,dx
		mov	es:[di].objType,OBJ_BAR
		mov	es:[di].objFlags,0
		mov	word ptr es:[di].objptr,si
		mov	word ptr es:[di].objptr+2,es

		add	di,size object

		push	ax
		xchg	ax,bp
		mov	es:[si].barflags,0
		mov	es:[si].barcol,al
		mov	word ptr es:[si].fillpattPtr,0
		mov	word ptr es:[si].fillpattPtr+2,0
		cmp	ah,-1
		jne	@@NotUserPattern
		mov	word ptr es:[si].fillPattPtr,bx
		mov	word ptr es:[si].fillPattPtr+2,bp
@@NotUserPattern:
		mov	es:[si].fillpattNum,ah
		mov	es:[si].bardrawMode,REPLACE_MODE
		pop	ax
		mov	es:[si].bardrawMode,0

		add	si,size objBar

		ret

addObjectBarS	Endp

;{----------------------------------------------------------------------}
;{	addObjectStringS:						}
;{	  add object string structure					}
;{									}
;{	parameters:							}
;{	  es:di = uninitialize data pointer				}
;{	  es:si = offset for child object of this tree			}
;{----------------------------------------------------------------------}
addObjectStringS Proc	Near

		mov	es:[di].objtype,OBJ_STR
		mov	es:[di].objflags,0
		mov	es:[di].objID,WIN_TITLE_STR_ID
		mov	word ptr es:[di].objptr,si
		mov	word ptr es:[di].objptr+2,es

		add	di,size object

		mov	es:[si].strXOff,0
		mov	es:[si].strYOff,1
		mov	es:[si].strflags,0
		mov	es:[si].strcol,0
		mov	es:[si].strdiscol,8
		mov	es:[si].strselcol,7
		mov	es:[si].strdrawMode,XPARENT_MODE
		mov	bp,offset dummystr
		mov	word ptr es:[si].strptr,bp
		mov	bp,seg dummystr
		mov	word ptr es:[si].strptr+2,bp

		add	si,size objStr

		ret

addObjectStringS Endp

;{----------------------------------------------------------------------}
;{	addObjectBMS:							}
;{	  add object bitmap structure					}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx = flags for bitmap						}
;{	  bp = internal bitmap offset					}
;{	  es:di = uninitialize data pointer				}
;{----------------------------------------------------------------------}
addObjectBMS	Proc	Near

		push	si
		mov	es:[di].objtype,OBJ_BITMAP
		mov	es:[di].objflags,cx
		mov	si,offset InternalBitmaps
		add	si,bp
		mov	word ptr es:[di].objptr,si
		mov	si,seg InternalBitmaps
		mov	word ptr es:[di].objptr+2,si
		pop	si
		add	di,size object

		ret

addObjectBMS	Endp

;{----------------------------------------------------------------------}
;{	addObjectLineS:							}
;{	  add object Line structure					}
;{									}
;{	parameters:							}
;{	  ax = x1 position						}
;{	  bx = y1 position						}
;{	  cx = x2 position						}
;{	  dx = y2 position						}
;{	  bp = pattern/linecolor					}
;{	  es:di = uninitialize data pointer				}
;{----------------------------------------------------------------------}
addObjectLineS	Proc	Near

		mov	es:[di].objtype,OBJ_LINE
		mov	es:[di].objW,cx
		mov	es:[di].objH,dx
		mov	es:[di].objflags,0
		mov	word ptr es:[di].objptr,si
		mov	word ptr es:[di].objptr+2,es
		add	di,size object

		push	ax
		mov	ax,bp
		mov	es:[si].linecolor,al
		mov	es:[si].linePattNum,ah
		mov	es:[si].linedrawMode,REPLACE_MODE
		pop	ax

		add	si,size objLine

		ret

addObjectLineS	Endp

;{----------------------------------------------------------------------}
;{	winRectAdd:							}
;{	  add object structures for windows work area rectangle		}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx = width of work area					}
;{	  dx = height of work area					}
;{	  baseObjects = pointer to object structures for window		}
;{	  otherObjects = pointer to other parent object structures	}
;{----------------------------------------------------------------------}
winRectAdd	Proc	far

		push	bp
		push	si
		push	di
		push	ds
		push	es

		assume	ds:DGROUP
		mov	bp,seg DGROUP
		mov	ds,bp
		mov	bp,curTextHeight
		add	bp,3

		assume	ds:windseg
		mov	si,seg baseObjects
		mov	ds,si

		les	di,baseObjects

		dec	ax
		dec	bx
		add	cx,2
		add	dx,2
		test	winflags,WIN_TITLE_BAR
		jne	@@IsTitleBar
		xor	bp,bp
@@IsTitleBar:
		mov	es:[di].objX,0
		mov	es:[di].objY,bp
		mov	es:[di].objW,cx
		mov	es:[di].objH,dx
		mov	es:[di].objtype,OBJ_PARENT
		mov	es:[di].objflags,OBJ_NOTIFY
		mov	es:[di].objID,WIN_WORK_AREA_ID
		mov	bp,word ptr otherObjects
		mov	word ptr es:[di].objptr,bp
		mov	si,word ptr otherObjects+2
		mov	word ptr es:[di].objptr+2,si

		add	di,size object

		fartohuge di,es

		mov	word ptr baseObjects,di
		mov	word ptr baseObjects+2,es

		mov	es,si
		mov	di,bp			; set pointer to other objects

		mov	word ptr es:[di],1	; 1 initial objects
		add	di,2

		mov	si,di
		add	si,(1*size object)

		mov	es:[di].objX,0
		mov	es:[di].objY,0
		xor	bp,bp
		call	near ptr addObjectRectS

		fartohuge si,es

		mov	word ptr otherObjects,si
		mov	word ptr otherObjects+2,es

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

winRectAdd	Endp


;{----------------------------------------------------------------------}
;{	WinTitleBarAdd:							}
;{	  add object structures for windows Title Bar rectangle		}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx = width of work area					}
;{	  dx = height of work area					}
;{	  baseObjects = pointer to object structures for window		}
;{	  otherObjects = pointer to other parent object structures	}
;{----------------------------------------------------------------------}
WinTitleBarAdd	Proc	Far

		push	cx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		assume	ds:DGROUP
		mov	bp,seg DGROUP
		mov	ds,bp
		mov	bp,curTextHeight
		assume	ds:windseg

		mov	si,seg baseObjects
		mov	ds,si

		add	bp,3
		les	di,baseObjects

		sub	bx,bp
		add	dx,bp			; workarea's outline
		test	winflags,WIN_VSCROLL
		jne	@@HasVScroll
		sub	cx,bp
		dec	cx
@@HasVScroll:
		inc	bp
		push	bp
		mov	es:[di].objX,0
		mov	es:[di].objY,0
		mov	es:[di].objW,cx
		mov	es:[di].objH,bp
		mov	es:[di].objtype,OBJ_PARENT
		mov	es:[di].objflags,OBJ_NOTIFY
		mov	es:[di].objID,WIN_TITLE_BAR_ID  ; system id's
		mov	bp,word ptr otherObjects
		mov	word ptr es:[di].objptr,bp
		mov	si,word ptr otherObjects+2
		mov	word ptr es:[di].objptr+2,si

		add	di,size object

		fartohuge di,es

		mov	word ptr baseObjects,di
		mov	word ptr baseObjects+2,es

		mov	es,si
		mov	di,bp			; set pointer to other objects

		pop	bp

		mov	word ptr es:[di],7	; 2 initial objects
		add	di,2

		mov	si,di
		add	si,(7*size object)

		push	cx
		push	dx
		mov	es:[di].objX,0
		mov	es:[di].objY,0
		mov	dx,bp
		call	near ptr addObjectRectS

		push	cx
		push	dx
		mov	es:[di].objX,1
		mov	es:[di].objY,1
		mov	dx,1
		sub	cx,3
		mov	bp,000fh
		call	near ptr addObjectLineS
		pop	dx
		pop	cx

		push	cx
		push	dx
		mov	es:[di].objX,1
		mov	es:[di].objY,2
		mov	cx,1
		sub	dx,2
		mov	bp,000fh
		call	near ptr addObjectLineS
		pop	dx
		pop	cx

		push	cx
		push	dx
		mov	bp,cx
		sub	bp,2
		mov	es:[di].objX,bp
		mov	es:[di].objY,1
		mov	cx,bp
		sub	dx,2
		mov	bp,0008h
		call	near ptr addObjectLineS
		pop	dx
		pop	cx

		push	cx
		push	dx
		mov	bp,dx
		sub	bp,2
		mov	es:[di].objX,2
		mov	es:[di].objY,bp
		mov	dx,bp
		sub	cx,3
		mov	bp,0008h
		call	near ptr addObjectLineS
		pop	dx
		pop	cx


		push	ax
		push	bx
		mov	es:[di].objX,2
		mov	es:[di].objY,2
		sub	dx,4
		sub	cx,4
		mov	bp,0ff07h
		mov	ax,seg titlePattern
		mov	bx,offset titlePattern
		call	near ptr addObjectBarS

		mov	es:[di].objX,4
		mov	es:[di].objY,2
		mov	es:[di].objW,cx
		mov	es:[di].objH,0
		call	near ptr addObjectStringS

		pop	bx
		pop	ax
		pop	dx
		pop	cx

		fartohuge si,es

		mov	word ptr otherObjects,si
		mov	word ptr otherObjects+2,es

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	cx
		ret

WinTitleBarAdd	Endp

;{----------------------------------------------------------------------}
;{	closeWinBMAdd:							}
;{	  add object structures for close window bitmap			}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx = width of work area					}
;{	  dx = height of work area					}
;{	  baseObjects = pointer to object structures for window		}
;{	  otherObjects = pointer to other parent object structures	}
;{----------------------------------------------------------------------}
closeWinBMAdd	Proc	Far


		push	cx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	si,seg baseObjects
		mov	ds,si

		les	di,baseObjects

		mov	bp,cx
		dec	bp
		test	winflags,WIN_VSCROLL
		jne	@@HasVScroll
		sub	bp,11
@@HasVScroll:
		mov	es:[di].objX,bp
		mov	es:[di].objY,0
		mov	es:[di].objID,WIN_CLOSE_ID
		
		mov	bp,OBJCLOSEWIN
		mov	cx,OBJ_SELECTABLE
		call	near ptr addObjectBMS

		mov	word ptr baseObjects,di
		mov	word ptr baseObjects+2,es

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	cx
		ret

closeWinBMAdd	Endp

;{----------------------------------------------------------------------}
;{	vScrollAdd:							}
;{	  add object structures for vertical scroll object		}			}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx = width of work area					}
;{	  dx = height of work area					}
;{	  baseObjects = pointer to object structures for window		}
;{	  otherObjects = pointer to other parent object structures	}
;{----------------------------------------------------------------------}
vScrollAdd	Proc	Far

		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	si,seg baseObjects
		mov	ds,si

		les	di,baseObjects

		test	winflags,WIN_TITLE_BAR
		je	@@NoTitleBar
		sub	dx,11
@@NoTitleBar:
		test	winflags,WIN_HSCROLL
		je	@@NoHScroll
		add	dx,11
@@NoHScroll:
		test	winflags,WIN_SIZE_BM
		je	@@NoSizeBM
		sub	dx,11
@@NoSizeBM:
		mov	bp,11
		test	winflags,WIN_CLOSE_BM
		jne	@@CloseBMPresent
		mov	bp,23
		sub	dx,11
@@CloseBMPresent:
		mov	es:[di].objX,cx
		dec	es:[di].objX
		mov	es:[di].objY,bp
		mov	es:[di].objW,12
		mov	es:[di].objH,dx
		mov	es:[di].objtype,OBJ_PARENT
		mov	es:[di].objflags,OBJ_NOTIFY
		mov	es:[di].objID,WIN_VSCROLL_ID ; system id's
		mov	bp,word ptr otherObjects
		mov	word ptr es:[di].objptr,bp
		mov	si,word ptr otherObjects+2
		mov	word ptr es:[di].objptr+2,si

		add	cx,11			; add width of vscroll object
		add	di,size object		; overlap of work area

		fartohuge di,es

		mov	word ptr baseObjects,di
		mov	word ptr baseObjects+2,es

		mov	es,si
		mov	di,bp			; set pointer to other objects

		mov	word ptr es:[di],5	; 5 initial objects
		add	di,2

		mov	si,di
		add	si,(5*size object)

		push	cx
		push	dx
		mov	cx,12
		mov	es:[di].objX,0
		mov	es:[di].objY,0
		xor	bp,bp
		call	near ptr addObjectRectS
	
		sub	cx,2
		sub	dx,2
		mov	es:[di].objX,1
		mov	es:[di].objY,1
		mov	bp,090fh
		call	near ptr addObjectBarS

		pop	dx
		mov	es:[di].objX,0
		mov	es:[di].objY,0
		mov	bp,OBJUPARROW
		mov	cx,OBJ_SELECTABLE
		call	near ptr addObjectBMS

		mov	es:[di].objX,0
		mov	es:[di].objY,11
		mov	es:[di].objID,WIN_VSCROLL_BAR_ID ; system id's
		mov	bp,OBJBLOCK
		mov	cx,OBJ_NOTIFY
		call	near ptr addObjectBMS

		mov	es:[di].objX,0
		mov	bp,dx
		sub	bp,12
		mov	es:[di].objY,bp
		mov	bp,OBJDNARROW
		mov	cx,OBJ_SELECTABLE
		call	near ptr addObjectBMS

		pop	cx
		fartohuge si,es

		mov	word ptr otherObjects,si
		mov	word ptr otherObjects+2,es

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		ret

vScrollAdd	Endp

;{----------------------------------------------------------------------}
;{	hScrollAdd:							}
;{	  add object structures for horizontal scroll object		}			}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx = width of work area					}
;{	  dx = height of work area					}
;{	  baseObjects = pointer to object structures for window		}
;{	  otherObjects = pointer to other parent object structures	}
;{----------------------------------------------------------------------}
hScrollAdd	Proc	Far

		push	cx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	si,seg baseObjects
		mov	ds,si

		les	di,baseObjects

		test	winflags,(WIN_VSCROLL OR WIN_SIZE_BM)
		je	@@HasVScroll
		sub	cx,11
@@HasVScroll:
		mov	bp,dx
		sub	bp,1
		mov	es:[di].objX,0
		mov	es:[di].objY,bp
		mov	es:[di].objW,cx
		mov	es:[di].objH,12
		mov	es:[di].objtype,OBJ_PARENT
		mov	es:[di].objflags,OBJ_NOTIFY
		mov	es:[di].objID,WIN_HSCROLL_ID ; system id's
		mov	bp,word ptr otherObjects
		mov	word ptr es:[di].objptr,bp
		mov	si,word ptr otherObjects+2
		mov	word ptr es:[di].objptr+2,si

		add	dx,11
		add	di,size object

		fartohuge di,es

		mov	word ptr baseObjects,di
		mov	word ptr baseObjects+2,es

		mov	es,si
		mov	di,bp			; set pointer to other objects

		mov	word ptr es:[di],5	; 5 initial objects
		add	di,2

		mov	si,di
		add	si,(5*size object)

		push	cx
		push	dx
		mov	dx,12
		mov	es:[di].objX,0
		mov	es:[di].objY,0
		xor	bp,bp
		call	near ptr addObjectRectS
	
		sub	cx,2
		sub	dx,2
		mov	es:[di].objX,1
		mov	es:[di].objY,1
		mov	bp,090fh
		call	near ptr addObjectBarS

		pop	dx
		pop	cx
		push	cx
		mov	es:[di].objX,0
		mov	es:[di].objY,0
		mov	bp,OBJLFARROW
		mov	cx,OBJ_SELECTABLE
		call	near ptr addObjectBMS

		mov	es:[di].objX,11
		mov	es:[di].objY,0
		mov	es:[di].objID,WIN_HSCROLL_BAR_ID ; system id's
		mov	bp,OBJBLOCK
		mov	cx,OBJ_NOTIFY
		call	near ptr addObjectBMS

		pop	cx
		push	cx
		mov	bp,cx
		sub	bp,12
		mov	es:[di].objX,bp
		mov	es:[di].objY,0
		mov	bp,OBJRTARROW
		mov	cx,OBJ_SELECTABLE
		call	near ptr addObjectBMS
		pop	cx

		fartohuge si,es

		mov	word ptr otherObjects,si
		mov	word ptr otherObjects+2,es

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	cx
		ret

hScrollAdd	Endp

;{----------------------------------------------------------------------}
;{	sizeWinBMAdd:							}
;{	  add object structures for size window bitmap			}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx = width of work area					}
;{	  dx = height of work area					}
;{	  baseObjects = pointer to object structures for window		}
;{	  otherObjects = pointer to other parent object structures	}
;{----------------------------------------------------------------------}
sizeWinBMAdd	Proc	Far


		push	cx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	si,seg baseObjects
		mov	ds,si

		les	di,baseObjects

		mov	bp,cx
		test	winflags,WIN_VSCROLL
		je	@@NoVScroll
		sub	bp,11
@@NoVScroll:
		dec	bp
		mov	es:[di].objX,bp
		mov	bp,dx
		test	winflags,WIN_HSCROLL
		je	@@NoHScroll
		sub	bp,11
@@NoHScroll:
		sub	bp,1
		mov	es:[di].objY,bp
		mov	es:[di].objID,WIN_SIZE_ID ; system id's
		
		mov	bp,OBJSIZEWIN
		mov	cx,OBJ_SELECTABLE
		call	near ptr addObjectBMS


		mov	word ptr baseObjects,di
		mov	word ptr baseObjects+2,es

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	cx
		ret

sizeWinBMAdd	Endp

;{----------------------------------------------------------------------}
;{	getWindowMem:							}
;{	  allocate memory for window structures				}
;{									}
;{	parameters:							}
;{	  ax = bits for objects on window				}
;{									}
;{	returns:							}
;{	  ax = number of objects					}
;{	  bx:0 = pointer to buffer					}
;{	  dx = true malloced offset					}
;{----------------------------------------------------------------------}
getWindowMem	Proc	near


		push	bp
		push	si
		push	di
		push	ds
;
; ----- work area is always outlined so get 1 object + objRect structure
;	+ 2 word for number of objects in window
;
		xor	bp,bp
		mov	di,(size winHeader)+(size object)+(size objRect)+2
		mov	cx,1			; number of objects so far

		mov	bx,WIN_TITLE_BAR	; initial test value
		mov	dx,ax			; save flags

		mov	si,seg WINOBJECTSIZE
		mov	ds,si
		xor	si,si			; starting offset
@@WinObjectLoop:
		test	bx,dx			; want this object in window?
		je	@@WinNextObject		; nope so bypass
		cmp	word ptr [si],'OW'
		jne	@@WinNextObject
		cmp	word ptr [si+2],'ZS'	; see if information available
		jne	@@WinNextObject

		inc	cx			; found another object

		call	dword ptr [si].routine
		add	di,ax			; add in size of object define
		adc	bp,0			; structures

@@WinNextObject:
		add	si,size Executehead	; next structure
		shl	bx,1
		jnc	@@WinObjectLoop		; test all bits

		mov	ax,size object
		mul	cx			; get size object*num_objects
		add	ax,di			; add in size of object define
		adc	dx,bp			; structures
		add	ax,15
		adc	dx,0

		push	cx
		push	dx
		push	ax			; push size to malloc
		call	far ptr _myfarmalloc	; allocate buffer
		pop	bx
		pop	bx
		pop	cx
		mov	bx,dx
		or	bx,ax
		jne	@@AllocedOK
		xor	ax,ax
		xor	bx,bx
		jmp	@@GWMExit
@@AllocedOK:
		mov	bx,dx
		test	ax,0fh
		je	@@NotNextSegment
		inc	bx
@@NotNextSegment:
		mov	dx,ax
		mov	ax,cx
@@GWMExit:
		pop	ds
		pop	di
		pop	si
		pop	bp

		ret

getWindowMem	Endp


;{----------------------------------------------------------------------}
;{	WinTitleBarSize:						}
;{	  return number of bytes to allocate for structure for		}
;{	  window title bar.						}
;{									}
;{	paramters:							}
;{	  none								}
;{									}
;{	returns:							}
;{	  ax = size of structures needed for Title Bar			}
;{----------------------------------------------------------------------}
WinTitleBarSize	Proc	Far

		mov	ax,(7*size object)+(size objBar)+(size objRect)\
				+(4*size objLine)
		ret

WinTitleBarSize	Endp

;{----------------------------------------------------------------------}
;{	closeWinBMSize:							}
;{	  return number of bytes to allocate for structure for		}
;{	  close window BitMap.						}
;{									}
;{	paramters:							}
;{	  none								}
;{									}
;{	returns:							}
;{	  ax = size of structures needed for close Window Bitmap	}
;{----------------------------------------------------------------------}
closeWinBMSize	Proc	Far

		mov	ax,(1*size object)
		ret

closeWinBMSize	Endp


;{----------------------------------------------------------------------}
;{	vScrollSize:							}
;{	  return number of bytes to allocate for structure for		}
;{	  vertical Scroll bar.						}
;{									}
;{	paramters:							}
;{	  none								}
;{									}
;{	returns:							}
;{	  ax = size of structures needed for vscroll Bar		}
;{----------------------------------------------------------------------}
vScrollSize	Proc	Far

		mov	ax,(5*size object)+(2*size objBar)+(size objRect)
		ret

vScrollSize	Endp

;{----------------------------------------------------------------------}
;{	hScrollSize:							}
;{	  return number of bytes to allocate for structure for		}
;{	  horizontal Scroll bar.					}
;{									}
;{	paramters:							}
;{	  none								}
;{									}
;{	returns:							}
;{	  ax = size of structures needed for hscroll Bar		}
;{----------------------------------------------------------------------}
hScrollSize	Proc	Far

		mov	ax,(5*size object)+(2*size objBar)+(size objRect)
		ret

hScrollSize	Endp

;{----------------------------------------------------------------------}
;{	sizeWinBMSize:							}
;{	  return number of bytes to allocate for structure for		}
;{	  size window BitMap.						}
;{									}
;{	paramters:							}
;{	  none								}
;{									}
;{	returns:							}
;{	  ax = size of structures needed for size Window Bitmap		}
;{----------------------------------------------------------------------}
sizeWinBMSize	Proc	Far

		mov	ax,(1*size object)
		ret

sizeWinBMSize	Endp

;{----------------------------------------------------------------------}
;{	void _freeWindow(int winHandle);				}
;{	  'C' callable free up window structure				}
;{----------------------------------------------------------------------}
_freeWindow	Proc	far
		
		arg	argwinHandle:word

		mov	ax,argwinHandle

;{----------------------------------------------------------------------}
;{ Function:	freeWindow						}
;{ Description:	free up window from memory and delete structure		}
;{ Parameters:	ax = windows handle					}
;{ returns:	ax = 0 on no errors					}
;{----------------------------------------------------------------------}
freeWindow	Proc	far

		push	ax
		push	bx
		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds

		mov	bx,seg winHandle
		mov	ds,bx

		mov	es,ax
		xor	di,di
		mov	ax,INVALID_WINDOW_HANDLE ; in case bad handle
		cmp	word ptr es:[di].winID,'IW'
		jne	@@FreeWinExit
		cmp	word ptr es:[di].winID+2,'DN'
		jne	@@FreeWinExit

		mov	bp,es			; save for later
		mov	ax,es:[di].winPrevious
		mov	cx,es:[di].winNext
		cmp	ax,-1
		je	@@NoPrevious
		mov	es,ax			; get to window struct (prev)
		mov	es:[di].winNext,cx	; now set next deleting cur
		mov	es,bp			; recover current win handle
@@NoPrevious:
		cmp	cx,-1			
		je	@@NoNext		; because next available
		mov	es,cx
		mov	es:[di].winPrevious,ax	; save new previous pointer
		mov	es,bp
@@NoNext:
		cmp	ax,-1			; new start window
		jne	@@NotNewStart1
		mov	startWinHandle,cx
@@NotNewStart1:
		cmp	bp,winHandle		; is current window?
		jne	@@NotCurrent
		mov	winHandle,ax		; set current handle
		cmp	ax,-1
		je	@@NotCurrent		; don't redraw if no windows
		call	far ptr DrawWindow	; redraw window on top
@@NotCurrent:
		mov	ax,FALSE		; don't redraw last window
		push	ax
		push	es
		mov	di,offset winX
		push	di
		call	far ptr _RefreshRect
		add	sp,6			; clean up stack

		mov	ax,es
		xor	di,di

		mov	word ptr es:[di].winID,0
		mov	word ptr es:[di].winID+2,0

		mov	bx,es:[di].winOffset	; get true malloced offset
		or	bx,bx
		je	@@NoNewSegment
		dec	ax
@@NoNewSegment:
		push	ax
		push	bx
		call	far ptr _myfarfree	; and free up memory used
		pop	ax
		pop	ax
@@NothingAlloced:
@@FreeWinExit:
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

freeWindow	Endp

_freeWindow	Endp


;{----------------------------------------------------------------------}
;{ Function:	closeAllWindows						}
;{ Description:	close all open windows					}
;{ Parameters:	.							}
;{ returns:	.							}
;{----------------------------------------------------------------------}
closeAllWindows	Proc	far


		mov	ax,seg winHandle
		mov	ds,ax

		mov	ax,winHandle		; get top handle
@@WinLoop:
		cmp	ax,-1			; all finished?
		je	@@AllDone
		call	far ptr freeWindow
		mov	es,ax
		xor	di,di
		mov	ax,es:[di].winPrevious	; get previous window
		jmp	short @@WinLoop
@@AllDone:
		xor	ax,ax
		ret


closeAllWindows	Endp
		

wincseg		ends

		end

