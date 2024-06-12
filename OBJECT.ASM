; $Header: e:/graphic\RCS\object.asm_v 1.1 1993/04/23 21:10:21 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	MsDos Object library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log: object.asm_v $
; Revision 1.1  1993/04/23  21:10:21  KENH
; Initial revision
;

		locals
		include	object.inc

EVENTHANDLER	Segment	Public 'FAR_DATA'

		Executehead	<"EVHA", 52000, objectSelectEvent, OBJECTDEVICE>

EVENTHANDLER	Ends

GRAFCHANGE	Segment	Public 'FAR_DATA'
GRAFCHANGE	Ends

INITEND		Segment	Public 'FAR_DATA'

;		Executehead	<"GREN",32767,_closegraph>


INITEND		Ends

INITSTART	Segment	Public 'FAR_DATA'

;		Executehead	<"GRIN",32767,setBGIAddress>
		

INITSTART	Ends

OBJECTDRAW	segment public 'FAR_DATA'

		Executehead	<"OBDR", OBJ_PARENT, objParentDraw>
		Executehead	<"OBDR", OBJ_RECT, objRectDraw>
		Executehead	<"OBDR", OBJ_STR, objStringDraw>
		Executehead	<"OBDR", OBJ_BITMAP, objBitmapDraw>
		Executehead	<"OBDR", OBJ_BAR, objBarDraw>
		Executehead	<"OBDR", OBJ_CIRCLE, 0>
		Executehead	<"OBDR", OBJ_LINE, objLineDraw>

OBJECTDRAW	ends

OBJECTSIZE	segment public 'FAR_DATA'

		Executehead	<"OBSZ", OBJ_PARENT, objParentSize>
		Executehead	<"OBSZ", OBJ_RECT, objRectSize>
		Executehead	<"OBSZ", OBJ_STR, objStringSize>
		Executehead	<"OBSZ", OBJ_BITMAP, objBitmapSize>
		Executehead	<"OBSZ", OBJ_BAR, objBarSize>
		Executehead	<"OBSZ", OBJ_CIRCLE, 0>
		Executehead	<"OBSZ", OBJ_LINE, objLineSize>

OBJECTSIZE	ends

OBJECTBITMAPS	segment public 'FAR_DATA'

InternalBitmaps	objBitmap	<0, 4, objCircleBM, objCircleSelBM>
		objBitmap	<0, 4, objCloseWinBM, objCloseWinSelBM>
		objBitmap	<0, 4, objDiamondBM, objDiamondSelBM>
		objBitmap	<0, 4, objDNArrowBM, objDNArrowSelBM>
		objBitmap	<0, 4, objLFArrowBM, objLFArrowSelBM>
		objBitmap	<0, 4, objSizeWinBM, objSizeWinSelBM>
		objBitmap	<0, 4, objRTArrowBM, objRTArrowSelBM>
		objBitmap	<0, 4, objBlockBM, objBlockSelBM>
		objBitmap	<0, 4, objUPArrowBM, objUPArrowSelBM>
		objBitmap	<0, 4, objOKBM, objOKSelBM>
		objBitmap	<0, 4, objCancelBM, objCancelSelBM>
		objBitmap	<0, 4, objStopBM, objStopSelBM>

OBJECTBITMAPS	ends

DGROUP		GROUP	_DATA

_DATA		segment public 'DATA'

		include	bitmaps.inc
;
; -----	Default BGI variables
;
patternColor	db	0
patternNum	db	1
drawColor	db	0
drawMode	db	0
_backColor	label	byte
backColor	db	255
_BackPatternCol	label	byte
BackPatternCol	db	255
_backPattern	label	byte
backPattern	db	1			; background fill pattern
_backPatternPtr	label	dword
backPatternPtr	dd	?
patternPtr	dd	0
vectPattNum	db	0
vectPattern	dw	1111111111111111b
xMin		dw	?
yMin		dw	?
xMax		dw	?
yMax		dw	?
curTextHeight	dw	?

DITable		$DIT	<0, 0>
BGI_utiladd	dd	?

objTempQueue	dw	16 dup (?)

gNullStr	db	0
shiftvalues	db	0, 3, 2, 2, 1, 1, 1, 1

_DATA		ends



objectcseg	segment 'CODE'

		assume	cs:objectcseg,ds:DGROUP, es:DGROUP

;{----------------------------------------------------------------------}
;{	_initGRACE:							}
;{	  initialze graphics system from C				}
;{----------------------------------------------------------------------}
_initGRACE	Proc	C Far


		uses	si,bp
		
		call	far ptr BGIDefaults

		call	far ptr FindMouseDriver
		or	ax,ax
		je	@@NoMouse
		mov	ax,seg GRAFCHANGE
		xor	bx,bx
		mov	cx,"RG"
		mov	dx,"HC"		; header checks
		mov	bp,CHGMODE
 		call	far ptr ExecuteRtns

@@NoMouse:
		mov	ax,seg objTempQueue
		mov	ds,ax
		mov	bx,offset objTempQueue
		mov	cx,xMin
		mov	[bx].rectX,cx
		mov	dx,yMin
		mov	[bx].rectY,dx
		neg	cx
		add	cx,xMax
		inc	cx
		mov	[bx].rectW,cx
		neg	dx
		add	dx,yMax
		inc	dx
		mov	[bx].rectH,dx
		call	far ptr redrawBackground

		call	far ptr getCurTextHeight
		ret

_initGRACE	Endp

;{----------------------------------------------------------------------}
;{ Function:	unsigned int getCurTextHeight(void);			}
;{ Description:	get the current fonts height and return it		}
;{ Parameters:	.							}
;{ Returns:	ax = font height					}
;{----------------------------------------------------------------------}
getCurTextHeight Proc Far
_getCurTextHeight Proc C Far

 
		uses	si,ds

		mov	ax,seg DGROUP
		mov	ds,ax		
		xor	cx,cx			; dummy string length
		callBGI	textsize		; get text size
	    	mov	curTextHeight,cx
		mov	ax,cx			; return value

		ret

_getCurTextHeight Endp
getCurTextHeight Endp

;{----------------------------------------------------------------------}
;{ Function:	void redrawBackground(rect *clipRect);			}
;{ Description:	'C' callable redraws the background			}
;{ Paramters:	clipRect = clipping rectangle for redraw		}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
_redrawBackground Proc	C Far


		arg	clipRect:dword

		mov	ax,word ptr clipRect+2
		mov	bx,word ptr clipRect
		call	far ptr redrawBackground
		ret

_redrawBackground Endp

;{----------------------------------------------------------------------}
;{ Function:	redrawBackground					}
;{ Description:	redraws the backgound with clipping			}
;{ Paramters:	ax:bx = pointer to rectangle to redraw			}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
redrawBackground Proc	far

		pushall
		mov	es,ax
		mov	di,bx

		call	far ptr HideMouse

		mov	ah,BackPatternCol
		mov	PatternColor,ah
		mov	al,BackColor
		mov	drawColor,al
		callBGI	color
@@NoNewColor:
		mov	al,REPLACE_MODE
		mov	drawmode,al
		callBGIutil setwritemode
@@NoNewDrawMode:
		push	es
		mov	bx,word ptr backPatternPtr	; load in case user defined
		mov	cx,word ptr backPatternPtr+2
		mov	al,BackPattern
		mov	PatternNum,al		; save new info
		mov	word ptr PatternPtr,bx
		mov	word ptr PatternPtr+2,cx
		mov	es,cx
		callBGI	fillstyle
		pop	es

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

		popall
		ret

redrawBackground Endp

;{----------------------------------------------------------------------}
;{	_drawObjects(int x, int y, void far *ParentObject)		}
;{	  'C' routine for drawing objects in linked list		}
;{									}
;{	parameters:							}
;{	  x = x position of object					}
;{	  y = y position of object					}
;{	  ParentObject = far pointer to parent object			}
;{									}
;{----------------------------------------------------------------------}
_drawObjects	Proc	C far

		arg	x:word, y:word, ParentObject:dword

		mov	ax,x
		mov	bx,y			; get x & y
		mov	dx,word ptr ParentObject
		mov	cx,word ptr ParentObject+2
		call	far ptr drawObjects
		ret

_drawObjects	Endp



;{----------------------------------------------------------------------}
;{	drawOneObject:							}
;{	  draw one object in parent list				}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  ds:si = pointer to object					}
;{----------------------------------------------------------------------}
drawOneObject	Proc	far

		push	bp
		push	si
		push	di
		push	ds			; save registers
		push	es

		mov	cx,1			; do one object

		jmp	drawNextObject		; thru draw next object rtn

drawOneObject	Endp

;{----------------------------------------------------------------------}
;{	drawObjects:							}
;{	  draw objects in linked list					}
;{									}
;{	parameters:							}
;{	  ax = x position if not root Parent				}
;{	  bx = y position if not root Parent				}
;{	  cx:dx = pointer to Parent					}
;{----------------------------------------------------------------------}
drawObjects	Proc	far

		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	ds,cx
		mov	si,dx			; setup pointer to parent

		mov	cx,[si].numObjects	; get number of objects to draw
		add	si,offset theObjects
;{----------------------------------------------------------------------}
;{	drawNextObject:							}
;{	  draw next object in parent list				}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx = # objects to draw					}
;{	  ds:si = pointer to object					}
;{----------------------------------------------------------------------}
drawNextObject:
		push	ax
		push	bx
		add	ax,[si].objX		; get new x position
		add	bx,[si].objY		; and new y position
		mov	di,seg OBJECTDRAW
		mov	es,di
		mov	di,[si].objtype
		and	di,0ffh
		shl	di,1
		shl	di,1
		shl	di,1
		shl	di,1			; multiply by size of Executehead
		cmp	word ptr es:[di],"BO"
		jne	@@NextObject		; don't know how to draw this
		cmp	word ptr es:[di+2],"RD"
		jne	@@NextObject		; object if branches taken

		mov	bp,[si].objflags
		test	bp,OBJ_INVISIBLE
		jne	@@NextObject

		push	cx
		push	ds
		push	si
		mov	dx,word ptr [si].objptr	; load in pointer to object
		mov	cx,word ptr [si].objptr+2
		call	es:[di].routine		; call routine to draw it

		pop	si
		pop	ds
		pop	cx
@@NextObject:
		pop	bx
		pop	ax

		add	si,size object
		loop	drawNextObject

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

drawObjects	Endp

;{----------------------------------------------------------------------}
;{	objParentDraw:							}
;{	  draw a parent object 						}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx:dx = pointer to objParent structure			}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{----------------------------------------------------------------------}
objParentDraw	Proc	far


		pushall
		mov	di,seg DGROUP
		mov	es,di

		push	es:xMin
		push	es:yMin
		push	es:xMax			; save current clip region
		push	es:yMax

		push	ax
		push	bx
		push	cx
		push	dx
		push	ds

		mov	cx,[si].objW		; get parent width and height
		mov	dx,[si].objH
		add	cx,ax
		dec	cx
		add	dx,bx
		dec	dx

		mov	ds,di
		cmp	ax,xMin			; see if out of range
		jl	@@NoNewXMin
		mov	xMin,ax
@@NoNewXMin:
		cmp	bx,yMin
		jl	@@NoNewYMin
		mov	yMin,bx
@@NoNewYMin:
		cmp	cx,xMax
		jge	@@NoNewXMax
		mov	xMax,cx
@@NoNewXMax:
		cmp	dx,yMax
		jge	@@NoNewYMax
		mov	yMax,dx
@@NoNewYMax:
		mov	ax,xMin
		mov	bx,yMin
		mov	cx,xMax
		mov	dx,yMax

		cmp	ax,cx
		jge	@@FullClip
		cmp	bx,dx
		jl	@@OktoDraw
@@FullClip:
		pop	ds
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		jmp	short @@Exit
@@OktoDraw:
		callBGI	setclip			; set clipping region

		pop	ds
		pop	dx
		pop	cx
		pop	bx
		pop	ax

		call	far ptr drawObjects

@@Exit:
		mov	ax,seg DGROUP
		mov	ds,ax
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		mov	xMin,ax
		mov	yMin,bx
		mov	xMax,cx
		mov	yMax,dx
		callBGI	setclip

		popall
		ret

objParentDraw	Endp

;{----------------------------------------------------------------------}
;{	objRectDraw:							}
;{	  draw a rectangle object 					}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx:dx = pointer to objRect structure				}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{----------------------------------------------------------------------}
objRectDraw	Proc	far

		mov	es,cx
		mov	di,dx
		push	ax
		push	si
		push	ds
		mov	cx,seg DGROUP
		mov	ds,cx
		mov	al,es:[di].rectcol
		cmp	al,drawColor
		je	@@NoNewdrawColor
		mov	drawColor,al
		mov	ah,PatternColor	 	; color change for fillpattern?
		callBGI	color			; set current color to draw in
@@NoNewdrawColor:
		mov	al,byte ptr es:[di].rectdrawMode
		cmp	al,drawmode
		je	@@NoNewDrawMode
		mov	drawmode,al
		callBGIutil setwritemode
@@NoNewDrawMode:

		pop	ds
		pop	si
		pop	ax

		mov	cx,[si].objW
		mov	dx,[si].objH
		push	ds
		mov	bp,seg DGROUP
		mov	ds,bp
		push	ax
		push	bx
		push	cx
		push	dx
		add	cx,ax
		dec	cx
		mov	dx,bx
		callBGI	vect

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		push	ax
		push	bx
		push	cx
		push	dx

		mov	cx,ax
		add	dx,bx
		dec	dx
		callBGI	vect

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		push	ax
		push	bx
		push	cx
		push	dx

		add	ax,cx
		dec	ax
		mov	cx,ax
		add	dx,bx
		dec	dx
		callBGI	vect

		pop	dx
		pop	cx
		pop	bx
		pop	ax

		add	bx,dx
		dec	bx
		mov	dx,bx
		add	cx,ax
		dec	cx
		callBGI	vect

		pop	ds
		ret

objRectDraw	Endp

;{----------------------------------------------------------------------}
;{	objBarDraw:							}
;{	  draw a filled bar object 					}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx:dx = pointer to objBar structure				}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{----------------------------------------------------------------------}
objBarDraw	Proc	far


		push	ax
		push	bx
		push	ds
		push	si

		mov	es,cx
		mov	di,dx

		mov	cx,seg DGROUP
		mov	ds,cx

		mov	ah,es:[di].barcol
		cmp	ah,PatternColor	 	; color change for rectangles?
		je	@@NoNewColor		; nope
		mov	PatternColor,ah
		mov	al,drawColor
		callBGI	color
@@NoNewColor:
		mov	al,es:[di].bardrawMode
		cmp	al,drawmode
		je	@@NoNewDrawMode
		mov	drawmode,al
		callBGIutil setwritemode
@@NoNewDrawMode:
		push	es
		push	di
		mov	bx,word ptr es:[di].fillpattPtr	; load in case user defined
		mov	cx,word ptr es:[di].fillpattPtr+2
		mov	al,es:[di].fillpattNum
		cmp	al,PatternNum
		jne	@@NewPattern
		cmp	cx,word ptr PatternPtr+2
		jne	@@NewPattern
		cmp	bx,word ptr PatternPtr
		je	@@NoNewPattern
@@NewPattern:
		mov	PatternNum,al		; save new info
		mov	word ptr PatternPtr,bx
		mov	word ptr PatternPtr+2,cx
		mov	es,cx
		callBGI	fillstyle
@@NoNewPattern:
		pop	di
		pop	es

		pop	si
		pop	ds
		pop	bx
		pop	ax

		mov	cx,ax
		mov	dx,bx
		add	cx,[si].objW
		add	dx,[si].objH		; get width and height of rect
		dec	cx
		dec	dx

		push	ds
		mov	bp,seg DGROUP
		mov	ds,bp
		callBGI	patbar
		pop	ds

		ret

objBarDraw	Endp

;{----------------------------------------------------------------------}
;{	objLineDraw:							}
;{	  draw a line object 						}
;{									}
;{	parameters:							}
;{	  cx:dx = pointer to objLine structure				}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{----------------------------------------------------------------------}
objLineDraw	Proc	far

		mov	es,cx
		mov	di,dx
		push	ax
		push	si
		push	ds
		mov	cx,seg DGROUP
		mov	ds,cx
		mov	al,es:[di].linecolor
		cmp	al,drawColor
		je	@@NoNewdrawColor
		mov	drawColor,al
		mov	ah,PatternColor	 	; color change for fillpattern?
		callBGI	color			; set current color to draw in
@@NoNewdrawColor:
		mov	al,es:[di].linedrawMode
		cmp	al,drawmode
		je	@@NoNewDrawMode
		mov	drawmode,al
		callBGIutil setwritemode
@@NoNewDrawMode:
		mov	al,es:[di].linePattNum
		cmp	al,vectPattNum
		jne	@@NewLinePattern
		cmp	al,4
		jne	@@NoNewLinePattern
		mov	ax,es:[di].linePattern
		cmp	ax,vectPattern
		je	@@NoNewLinePattern
@@NewLinePattern:
		push	bx
		mov	al,vectPattNum
		mov	bx,vectPattern
		callBGI	vectstyle
		pop	bx
@@NoNewLinePattern:
		pop	ds
		pop	si
		pop	ax

		mov	cx,[si].objW		; get X2, Y2
		mov	dx,[si].objH

		add	cx,ax
		add	dx,bx			; and add in screen X1, Y1

		sub	cx,[si].objX		; because X1, Y1 relative added
		sub	dx,[si].objY		; into screen x,y

		push	ds
		mov	bp,seg DGROUP
		mov	ds,bp
		callBGI	vect
		pop	ds

		ret

objLineDraw	Endp

;{----------------------------------------------------------------------}
;{	objStringDraw:							}
;{	  draw an object string to the screen				}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx:dx = pointer to objStr structure				}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{----------------------------------------------------------------------}
objStringDraw	Proc	Far


		mov	es,cx
		mov	di,dx

		push	ax
		push	bx
		push	si
		push	ds
		add	ax,es:[di].strXOff
		add	bx,es:[di].strYOff
		mov	si,seg DGROUP
		mov	ds,si
		callBGI	move			; move to current position
		mov	al,byte ptr es:[di].strDrawMode
		cmp	al,drawmode
		je	@@NoNewDrawMode
		mov	drawmode,al
		callBGIutil setwritemode
@@NoNewDrawMode:
		pop	ds
		pop	si
		pop	bx
		pop	ax

		push	ax
		push	bx
		push	si
		push	ds
		mov	cx,seg DGROUP
		mov	ds,cx
		mov	ah,es:[di].strselcol
		mov	al,es:[di].strcol	; text color
		test	bp,OBJ_DISABLED
		je	@@objNotDisabled
		mov	al,es:[di].strdiscol	; disabled color for text
@@objNotDisabled:
		test	bp,OBJ_SELECTED
		je	@@objNotSelected
		xchg	ah,al
@@objNotSelected:
		push	ax
		les	di,es:[di].strptr	; get string pointer
		mov	cx,-1
		xor	al,al
		mov	bx,di
		repne	scasb			; wait till zero byte found
		pop	ax
		mov	di,bx
		neg	cx
		sub	cx,2
		jne	@@objHasText
		pop	ds
		pop	si
		pop	bx
		pop	ax
		ret
@@objHasText:
		mov	drawColor,al
		mov	PatternColor,ah		; save pattern color
		mov	bp,cx
		mov	al,PatternColor
		call	far ptr setBackColor	; set background color
		mov	al,drawColor
		mov	ah,PatternColor
		callBGI	color
		mov	al,1
		mov	PatternNum,al
		callBGI	fillstyle

		mov	cx,bp
		mov	bx,di
		callBGI	textsize		; get text size

		mov	dx,cx			; get into width and height
		mov	cx,bx			; registers
		pop	ds
		pop	si
		pop	bx
		pop	ax
		cmp	cx,[si].objW		; if cx >= rectangle
		jg	@@objWidthOK		; then use width of string
		mov	cx,[si].objW
@@objWidthOK:
		cmp	dx,[si].objH
		jg	@@objHeightOK
		mov	dx,[si].objH
@@objHeightOK:
		mov	si,seg DGROUP
		mov	ds,si
		add	cx,ax
		dec	cx
		add	dx,bx
		dec	dx
		callBGI	patbar
@@objNotSelected2:
		mov	cx,bp
		mov	bx,di

		callBGI	text			; draw text string

		mov	al,backcolor
		call	far ptr setBackColor

		ret

objStringDraw	Endp

;{----------------------------------------------------------------------}
;{	setBackColor:							}
;{	  set the background color.					}
;{									}
;{	parameters:							}
;{	  al = color index						}
;{----------------------------------------------------------------------}
setBackColor	Proc	far


		push	bx
		push	es
		mov	bx,seg DGROUP
		mov	es,bx
		mov	bx,offset DGROUP:DITable
		cmp	al,es:[bx].$backcolor
		je	@@sBCDone
		mov	es:[bx].$backcolor,al
		mov	es:[bx].$initflag,0a5h
		callBGI	init
@@sBCDone:
		pop	es
		pop	bx
		ret


setBackColor	Endp

;{----------------------------------------------------------------------}
;{ Function:	globalSetClip						}
;{ Description:	globally set the clipping region			}
;{ Parameters:	ax = xmin						}
;{		bx = ymin						}
;{		cx = xmax						}
;{		dx = ymax						}
;{ Returns	.							}
;{----------------------------------------------------------------------}
globalSetClip	Proc	far


		push	si
		push	ds

		mov	si,seg DGROUP
		mov	ds,si
		cmp	ax,xMin			; see if out of range
		jl	@@NoNewXMin
		mov	xMin,ax
@@NoNewXMin:
		cmp	bx,yMin
		jl	@@NoNewYMin
		mov	yMin,bx
@@NoNewYMin:
		cmp	cx,xMax
		jge	@@NoNewXMax
		mov	xMax,cx
@@NoNewXMax:
		cmp	dx,yMax
		jge	@@NoNewYMax
		mov	yMax,dx
@@NoNewYMax:
		callBGI	setclip			; set clipping region

		pop	ds
		pop	si
		ret

globalSetClip	Endp

;{----------------------------------------------------------------------}
;{	objBitmapDraw:							}
;{	  draw an object bitmap to the screen				}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx:dx = pointer to objBitmap structure			}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{----------------------------------------------------------------------}
objBitmapDraw	Proc	Far


		push	ds
		mov	si,seg DGROUP
		mov	ds,si
		mov	es,cx
		mov	di,dx

		mov	cx,ax
		mov	dx,bx

		mov	al,es:[di].bitmapdrawMode ; get drawing mode for bitmap
		mov	bx,offset bitmapNormalPtr
		test	bp,OBJ_SELECTED
		je	@@objNotSelected
		mov	bx,offset bitmapPressPtr
@@objNotSelected:
		les	bx,es:[di+bx]		; get pointer to bitmap
		callBGI	restorebitmap
		pop	ds

		ret

objBitmapDraw	Endp

;{----------------------------------------------------------------------}
;{	_redrawObject(int x, int y, object far *ParentObject,		}
;{			 int objIndex)					}
;{	  'C' callable redraw an object and draw if necessary		}
;{									}
;{----------------------------------------------------------------------}
_redrawObject	Proc	C far

		arg	x:word, y:word, PObject:dword
		arg	oIndex:word

		uses	si

		mov	ax,x
		mov	bx,y
		mov	cx,word ptr PObject+2
		mov	dx,word ptr PObject
		mov	si,oIndex
		call	far ptr redrawObject
		ret

_redrawObject	Endp

;{----------------------------------------------------------------------}
;{	redrawObject:							}
;{	  redraw an object and draw if necessary			}
;{									}
;{	parameters:							}
;{	  ax = x position of Parent					}
;{	  bx = y position of Parent					}
;{	  cx:dx pointer to parent object				}
;{	  si = object index						}
;{----------------------------------------------------------------------}
redrawObject	Proc	Far

		pushall

		push	ax
		push	bx
		mov	ds,cx
		mov	cx,si			; save object index
		mov	si,dx			; get pointer
		add	si,2			; bypass count for this
		mov	ax,cx			; object index
		mov	cx,size object		; * size of object struc
		mul	cx
		add	si,ax			; add to pointer
		pop	bx
		pop	ax
		call	far ptr drawOneObject

		popall
		ret

redrawObject	Endp

;{----------------------------------------------------------------------}
;{	_setObjectFlags(object far *ParentObject, int objIndex		}
;{				, int flags)				}
;{	  'C' callable routine to set flags of an object		}
;{									}
;{----------------------------------------------------------------------}
_setObjectFlags	Proc	C far

		arg	PObject:dword, oIndex:word, flags:word

		uses	si

		mov	ax,flags
		mov	cx,word ptr PObject+2
		mov	dx,word ptr PObject
		mov	si,oIndex
		call	far ptr setObjectFlags
		ret

_setObjectFlags	Endp

;{----------------------------------------------------------------------}
;{	setObjectFlags:							}
;{	  set object flags.						}
;{									}
;{	parameters:							}
;{	  ax = flags							}
;{	  cx:dx pointer to parent object				}
;{	  si = object index						}
;{----------------------------------------------------------------------}
setObjectFlags	Proc	Far

		push	bp
		push	si
		push	di
		push	ds			; as drawObjects
		push	es			; these have to be the same

		mov	di,ax
		mov	ds,cx
		mov	cx,si			; save object index
		mov	si,dx			; get pointer
		add	si,2			; bypass count for this
		mov	ax,cx			; object index
		mov	cx,size object		; * size of object struc
		mul	cx
		add	si,ax			; add to pointer
		or	[si].objflags,di	; set flags
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

setObjectFlags	Endp

;{----------------------------------------------------------------------}
;{	_ClearrObjectFlags(object far *ParentObject, int objIndex	}
;{				, int flags)				}
;{	  'C' callable routine to clear flags of an object		}
;{									}
;{----------------------------------------------------------------------}
_clearObjectFlags Proc	C far

		arg	PObject:dword, oIndex:word, flags:word

		uses	si

		mov	ax,flags
		mov	cx,word ptr PObject+2
		mov	dx,word ptr PObject
		mov	si,oIndex
		call	far ptr clearObjectFlags
		ret

_clearObjectFlags Endp

;{----------------------------------------------------------------------}
;{	clearObjectFlags:						}
;{	  clear object flags.						}
;{									}
;{	parameters:							}
;{	  ax = flags							}
;{	  cx:dx pointer to parent object				}
;{	  si = object index						}
;{----------------------------------------------------------------------}
clearObjectFlags Proc	Far

		push	bp
		push	si
		push	di
		push	ds			; as drawObjects
		push	es			; these have to be the same

		mov	di,ax
		mov	ds,cx
		mov	cx,si			; save object index
		mov	si,dx			; get pointer
		add	si,2			; bypass count for this
		mov	ax,cx			; object index
		mov	cx,size object		; * size of object struc
		mul	cx
		add	si,ax			; add to pointer
		not	di
		and	[si].objflags,di	; set flags
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

clearObjectFlags Endp

;{----------------------------------------------------------------------}
;{	BGIDefaults:							}
;{	  set up BGI default values for this module			}
;{									}
;{	parameters:							}
;{	  es:bx = Device Status Table					}
;{----------------------------------------------------------------------}
BGIDefaults	Proc	far

		mov	ax,seg DGROUP
		mov	ds,ax

		xor	ax,ax			; get DST
		callBGI install

		mov	cx,es:[bx].$xres
		mov	dx,es:[bx].$yres
		xor	ax,ax
		xor	bx,bx
		mov	xMin,ax
		mov	yMin,bx
		mov	xMax,cx
		mov	yMax,dx
		callBGI	setclip

		mov	al,backcolor
		call	far ptr setBackColor

		mov	al,drawColor
		mov	ah,PatternColor
		callBGI	color

		mov	al,PatternNum
		les	bx,PatternPtr
		callBGI	fillstyle

		callBGI	bitmaputil		; get pointer to table

		mov	word ptr BGI_utiladd,bx
		mov	word ptr BGI_utiladd+2,es

		mov	al,REPLACE_MODE
		mov	drawmode,al
		callBGIutil setwritemode

		ret

BGIDefaults	Endp

;{----------------------------------------------------------------------}
;{	_sizeObjects(void far *ParentObject, int *width, int *height)	}
;{	  'C' routine for getting size of objects in linked list	}
;{									}
;{	parameters:							}
;{	  ParentObject = far pointer to parent object			}
;{	  *width = pointer to return width				}
;{	  *height = pointer to return height				}
;{									}
;{----------------------------------------------------------------------}
_sizeObjects	Proc	C far

		arg	ParentObject:dword, pWidth:dword, pHeight:dword

		uses	di,ds

		mov	dx,word ptr ParentObject
		mov	cx,word ptr ParentObject+2

		call	far ptr sizeObjects

		lds	di,pWidth
		mov	[di],ax
		lds	di,pHeight
		mov	[di],bx

		ret

_sizeObjects	Endp

;{----------------------------------------------------------------------}
;{	sizeObjects:							}
;{	  size objects in linked list					}
;{									}
;{	parameters:							}
;{	  cx:dx = pointer to Parent					}
;{									}
;{	returns:							}
;{	  ax = width of object						}
;{	  bx = height of object						}
;{----------------------------------------------------------------------}
sizeObjects	Proc	far

		LOCAL	curLowX, curLowY, curHighX, curHighY = LSTACKSIZE
		
		push	bp
		mov	bp,sp
		sub	sp,LSTACKSIZE

		push	si
		push	di
		push	ds
		push	es


		mov	ds,cx
		mov	si,dx			; setup pointer to parent

		mov	cx,[si].numObjects	; get number of objects to draw
		add	si,offset theObjects
		mov	curLowX,32767
		mov	curLowY,32767
		mov	curHighX,0
		mov	curHighY,0

sizeNextObject:
		mov	ax,[si].objX		; get new x position
		mov	bx,[si].objY		; and new y position
		cmp	ax,curLowX
		jge	@@NotNewLowX
		mov	curLowX,ax
@@NotNewLowX:
		cmp	bx,curLowY
		jge	@@notNewLowY
		mov	curLowY,bx
@@notNewLowY:
		mov	di,seg OBJECTSIZE
		mov	es,di
		mov	di,[si].objtype
		and	di,0ffh
		shl	di,1
		shl	di,1
		shl	di,1
		shl	di,1			; multiply by size of Executehead
		cmp	word ptr es:[di],"BO"
		jne	@@NextObject		; don't know how to size this
		cmp	word ptr es:[di+2],"ZS"	; object if branches taken
		jne	@@NextObject		

		push	ax
		push	bx
		push	si
		push	ds
		push	cx
		push	bp
		mov	bp,[si].objflags
		mov	dx,word ptr [si].objptr	; load in pointer to object
		mov	cx,word ptr [si].objptr+2
		call	es:[di].routine		; call routine to size it
		pop	bp
		pop	cx

		mov	di,seg DGROUP
		mov	es,di

		mov	dx,ax
		mov	di,bx
		pop	ds
		pop	si
		pop	bx
		pop	ax
		add	dx,ax
		dec	dx
		add	di,bx
		dec	di
;
; ----- now clip to parent rectangle
;
		cmp	ax,es:xMin
		jge	@@xMinOk1		; make sure xMin in parent Rect
		mov	ax,es:xMin
@@xMinOk1:
		cmp	bx,es:yMin
		jge	@@yMinOk1		; make sure yMin in parent Rect
		mov	bx,es:yMin
@@yMinOk1:
		cmp	dx,es:xMax
		jle	@@xMaxOk1 		; make sure xMax in parent Rect
		mov	dx,es:xMax
@@xMaxOk1:
		cmp	di,es:yMax
		jle	@@yMaxOk1		; make sure yMax in parent Rect
		mov	di,es:yMax
@@yMaxOk1:
		cmp	ax,dx
		jg	@@NextObject		; make sure not completly clipped
		cmp	bx,di
		jg	@@NextObject

		cmp	dx,curHighX
		jle	@@NotNewHighX
		mov	curHighX,dx
@@NotNewHighX:
		cmp	di,curHighY
		jle	@@NextObject
		mov	curHighY,di
@@NextObject:
		add	si,size object
		loop	sizeNextObject

		mov	ax,curHighX
		mov	bx,curHighY
		sub	ax,curLowX
		inc	ax
		sub	bx,curLowY
		inc	bx

		pop	es
		pop	ds
		pop	di
		pop	si
		mov	sp,bp
		pop	bp
		ret

sizeObjects	Endp

;{----------------------------------------------------------------------}
;{	objParentSize:							}
;{	  size a parent object 						}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx:dx = pointer to objParent structure			}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{----------------------------------------------------------------------}
objParentSize	Proc	far

		mov	di,seg DGROUP
		mov	es,di

		push	es:xMin
		push	es:yMin
		push	es:xMax			; save current clip region
		push	es:yMax

		push	cx
		push	dx
		push	ds

		mov	cx,[si].objW		; get parent width and height
		mov	dx,[si].objH
		add	cx,ax
		dec	cx
		add	dx,bx
		dec	dx

		mov	ds,di
		mov	xMin,ax
		mov	yMin,bx
		mov	xMax,cx
		mov	yMax,dx

		pop	ds
		pop	dx
		pop	cx

		call	far ptr sizeObjects

		mov	cx,seg DGROUP
		mov	ds,cx
		pop	yMax
		pop	xMax
		pop	yMin
		pop	xMin

		ret

objParentSize	Endp

;{----------------------------------------------------------------------}
;{	objRectSize:							}
;{	  size a rectangle object 					}
;{									}
;{	parameters:							}
;{	  cx:dx = pointer to objRect structure				}
;{	  ds:si = pointer object structure pointer			}
;{									}
;{	returns:							}
;{	  ax = width of object						}
;{	  bx = height of object						}
;{----------------------------------------------------------------------}
objRectSize	Proc	far

		mov	ax,[si].objW
		mov	bx,[si].objH
		ret

objRectSize	Endp

;{----------------------------------------------------------------------}
;{	objBarSize:							}
;{	  size a filled bar object 					}
;{									}
;{	parameters:							}
;{	  cx:dx = pointer to objBar structure				}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{									}
;{	returns:							}
;{	  ax = width of object						}
;{	  bx = height of object						}
;{----------------------------------------------------------------------}
objBarSize	Proc	far


		mov	ax,[si].objW
		mov	bx,[si].objH		; get width and height of rect
		ret

objBarSize	Endp

;{----------------------------------------------------------------------}
;{	objLineSize:							}
;{	  size a line object 						}
;{									}
;{	parameters:							}
;{	  cx:dx = pointer to objLine structure				}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{									}
;{	returns:							}
;{	  ax = width of object						}
;{	  bx = height of object						}
;{----------------------------------------------------------------------}
objLineSize	Proc	far

		mov	ax,[si].objW
		mov	bx,[si].objH
		sub	ax,[si].objX
		inc	ax
		sub	bx,[si].objY
		inc	bx

		ret

objLineSize	Endp

;{----------------------------------------------------------------------}
;{	objStringSize:							}
;{	  size an object string						}
;{									}
;{	parameters:							}
;{	  cx:dx = pointer to objStr structure				}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{									}
;{	returns:							}
;{	  ax = width of object						}
;{	  bx = height of object						}
;{----------------------------------------------------------------------}
objStringSize	Proc	Far


		push	cx
		push	dx
		mov	es,cx
		mov	di,dx

		les	di,es:[di].strptr	; get string pointer
		mov	cx,-1
		xor	al,al
		mov	bx,di
		repne	scasb			; wait till zero byte found
		neg	cx
		sub	cx,2
		push	si
		push	ds
		mov	si,seg DGROUP
		mov	ds,si
		callBGI	textsize		; get text size
		pop	ds
		pop	si
		mov	ax,bx			; get into width and height
		mov	bx,cx			; registers
		test	bp,OBJ_SELECTED
		je	@@objNotSelected
		cmp	ax,[si].objW		; if cx >= rectangle
		jg	@@objWidthOK		; then use width of string
		mov	ax,[si].objW
@@objWidthOK:
		cmp	bx,[si].objH
		jg	@@objHeightOK
		mov	bx,[si].objH
@@objHeightOK:
		add	ax,4
		add	bx,4
@@objNotSelected:
		pop	dx
		pop	cx
		ret

objStringSize	Endp

;{----------------------------------------------------------------------}
;{	objBitmapSize:							}
;{	  size an object bitmap						}
;{									}
;{	parameters:							}
;{	  cx:dx = pointer to objBitmap structure			}
;{	  bp = object flags						}
;{	  ds:si = pointer object structure pointer			}
;{									}
;{	returns:							}
;{	  ax = width of object						}
;{	  bx = height of object						}
;{----------------------------------------------------------------------}
objBitmapSize	Proc	Far

		mov	es,cx
		mov	di,dx

		mov	al,es:[di].bitmapdrawMode ; get drawing mode for bitmap
		mov	bx,offset bitmapNormalPtr
		test	bp,OBJ_SELECTED
		je	@@objNotSelected
		mov	bx,offset bitmapPressPtr
@@objNotSelected:
		les	bx,es:[di+bx]		; get pointer to bitmap
		mov	ax,es:[bx]
		mov	bx,es:[bx+2]

		ret

objBitmapSize	Endp

;{----------------------------------------------------------------------}
;{	ptInRect:							}
;{	  determine if x,y is in rectangle				}
;{									}
;{	parameters:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx:dx = pointer to rectangle structure			}
;{									}
;{	returns:							}
;{	  ax = 0 if not in rectangle					}
;{----------------------------------------------------------------------}
ptInRect	Proc	far

		push	si
		push	ds

		mov	ds,cx
		mov	si,dx

		mov	cx,[si].rectX
		cmp	ax,cx
		jl	@@NotInRect
		add	cx,[si].rectW
		cmp	ax,cx
		jge	@@NotInRect

		mov	dx,[si].rectY
		cmp	bx,dx
		jl	@@NotInRect
		mov	ax,1
		add	dx,[si].rectH
		cmp	bx,dx
		jl	@@InRect
@@NotInRect:
		xor	ax,ax
@@InRect:
		pop	ds
		pop	si
		ret

ptInRect	Endp

;{----------------------------------------------------------------------}
;{	BGIutil:							}
;{	  call far routine bitmaputil vectors				}
;{									}
;{	parameters:							}
;{	  si = routine to call						}
;{----------------------------------------------------------------------}
BGIutil		Proc	far

		push	es
		mov	es,word ptr BGI_utiladd+2
		add	si,word ptr BGI_utiladd
		mov	si,es:[si]
		pop	es
		push	word ptr __BGI_add+2
		add	si,word ptr __BGI_add
		push	si
		retf

BGIutil		Endp

;{----------------------------------------------------------------------}
;{	savePopUpBack:							}
;{	  save back ground for menu pop-Up				}
;{									}
;{	parameters:							}
;{	  ax = x position of Parent					}
;{	  bx = y position of Parent					}
;{	  cx:dx pointer to parent object				}
;{	  si = object index for popup					}
;{	  es:di = pointer to save buffer				}
;{----------------------------------------------------------------------}
savePopUpBack	Proc	far

		push	si
		push	di
		push	ds
		push	es

		mov	bp,si			; save object #
		mov	ds,cx
		mov	si,dx			; get pointer to parent

		mov	cx,ax			; save x position

		mov	ax,size object
		mul	bp			; get offset to object
		add	si,ax
		add	si,2			; bypass # objects

		mov	dx,bx			; save y position

		add	cx,[si].objX		; add in x, y offset
		add	dx,[si].objY

		mov	bx,di
		mov	ax,[si].objW
		stosw
		mov	ax,[si].objH
		stosw

		mov	di,seg DGROUP
		mov	ds,di
		
		callBGI	savebitmap

		pop	es
		pop	ds
		pop	di
		pop	si
		ret

savePopUpBack	Endp

;{----------------------------------------------------------------------}
;{	restorePopUpBack:						}
;{	  restore back ground for menu pop-Up				}
;{									}
;{	parameters:							}
;{	  ax = x position of Parent					}
;{	  bx = y position of Parent					}
;{	  cx:dx pointer to parent object				}
;{	  si = object index for popup					}
;{	  es:di = pointer to restore buffer				}
;{----------------------------------------------------------------------}
restorePopUpBack Proc	far

		push	si
		push	di
		push	ds
		push	es

		mov	bp,si			; save object #
		mov	ds,cx
		mov	si,dx			; get pointer to parent

		mov	cx,ax			; save x position

		mov	ax,size object
		mul	bp			; get offset to object
		add	si,ax
		add	si,2

		mov	dx,bx			; save y position
		mov	bx,di

		add	cx,[si].objX		; add in x, y offset
		add	dx,[si].objY

		mov	al,REPLACE_MODE
		mov	di,seg DGROUP
		mov	ds,di
		
		callBGI	restorebitmap

		pop	es
		pop	ds
		pop	di
		pop	si
		ret

restorePopUpBack Endp

tRect		Rect	<?>
tPointX		dw	?
tPointY		dw	?
tTestbits	dw	?
;{----------------------------------------------------------------------}
;{	ptInObject:							}
;{	  see if point is inside object in list				}
;{									}
;{	parameters:							}
;{	  ax = object x position					}
;{	  bx = object y position					}
;{	  cx:dx = pointer to parent object				}
;{	  bp = point x							}
;{	  si = point y							}
;{	  di = bits of objects to look at				}
;{									}
;{	returns:							}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx:dx = pointer to object or -1				}
;{----------------------------------------------------------------------}
ptInObject	Proc	far

		mov	cs:tPointX,bp
		mov	cs:tPointY,si
		mov	cs:tTestBits,di
ptInObject2:
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	ds,cx
		mov	si,dx
		
		mov	cx,[si]
		add	si,2
		xor	bp,bp
@@ptIOLoop:
		push	ax
		push	bx
		push	bp
		add	ax,[si].objX
		add	bx,[si].objY
		mov	di,seg OBJECTSIZE
		mov	es,di
		mov	di,[si].objtype
		cmp	di,OBJ_PARENT
		jne	@@PIONotParent
		mov	bp,[si].objflags
		test	bp,cs:tTestBits		; see if bit settings wanted
		je	@@NotParentNotify	; if parent matches then notify

		push	ax			; check for rectangle
		push	bx
		push	cx
		push	dx
		mov	cx,[si].objW
		mov	dx,[si].objH
		mov	cs:tRect.RectX,ax
		mov	cs:tRect.RectY,bx
		mov	cs:tRect.RectW,cx
		mov	cs:tRect.RectH,dx
		mov	ax,cs:tPointX
		mov	bx,cs:tPointY
		mov	cx,cs
		mov	dx,offset tRect
		call	far ptr ptInRect
		pop	dx
		pop	cx
		pop	bx
		or	ax,ax
		pop	ax
		je	@@NotParentNotify	; nope not in it

		pop	bp
		pop	bx
		pop	ax
		mov	dx,si			; return parent object
		mov	cx,ds			; as pointer to it
		jmp	@@ptIOExit
		
@@NotParentNotify:
		push	cx
		mov	dx,word ptr [si].objptr	; load in pointer to object
		mov	cx,word ptr [si].objptr+2
		call	far ptr ptInObject2	; recurse
		mov	bp,cx
		or	bp,dx
		cmp	bp,-1
		je	@@NotFoundYet		; nope
		add	sp,8			; else get out of loop
		jmp	@@ptIOExit
@@NotFoundYet:		
		pop	cx
		jmp	@@NextObject
@@PIONotParent:
		and	di,0ffh
		shl	di,1
		shl	di,1
		shl	di,1
		shl	di,1			; multiply by size of Executehead

		cmp	word ptr es:[di],"BO"
		jne	@@NextObject		; don't know how to draw this
		cmp	word ptr es:[di+2],"ZS"
		jne	@@NextObject		; object if branches taken

		mov	bp,[si].objflags
		test	bp,OBJ_INVISIBLE
		jne	@@NextObject

		test	bp,cs:tTestBits		; see if bit settings wanted
		je	@@NextObject

		mov	cs:tRect.objX,ax
		mov	cs:tRect.objY,bx
		push	cx
		push	ds
		push	si
		mov	dx,word ptr [si].objptr	; load in pointer to object
		mov	cx,word ptr [si].objptr+2
		call	es:[di].routine		; call routine to size it
		mov	cs:tRect.objW,ax
		mov	cs:tRect.objH,bx

		mov	ax,cs:tPointX
		mov	bx,cs:tPointY
		mov	cx,cs
		mov	dx,offset tRect
		call	far ptr ptInRect
		pop	si
		pop	ds
		pop	cx

		or	ax,ax
		je	@@NextObject

		pop	bp
		pop	bx
		pop	ax
		mov	dx,si
		mov	cx,ds			; and pointer to object
		jmp	@@ptIOExit
@@NextObject:
		pop	bp
		pop	bx
		pop	ax
		inc	bp
		add	si,size object
		dec	cx
		je	@@NoneFound
		jmp	@@ptIOLoop
@@NoneFound:
		mov	cx,-1
		mov	dx,-1
@@ptIOExit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

ptInObject	Endp

;{----------------------------------------------------------------------}
;{ Function:	_SetObjectText(int objectID, 


;{----------------------------------------------------------------------}
;{	findObjectID:							}
;{	  find an object id is inside of parent structure		}
;{									}
;{	parameters:							}
;{	  ax = ID to match						}
;{	  cx:dx = pointer to parent object				}
;{									}
;{	returns:							}
;{	  ax = x offset from parent of object				}
;{	  bx = y offset from parent of object				}
;{	  cx:dx = pointer to object or -1				}
;{	  *** thrashes di						}
;{----------------------------------------------------------------------}
findObjectID	Proc	far

		mov	di,ax
		xor	ax,ax
		xor	bx,bx
findObjectID2:
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	ds,cx
		mov	si,dx
		
		mov	cx,[si]
		add	si,2
@@findIDLoop:
		push	ax
		push	bx
		push	bp
		add	ax,[si].objX
		add	bx,[si].objY
		cmp	di,[si].objID
		jne	@@NextObject
		pop	bp
		pop	bx
		pop	ax
		mov	dx,si
		mov	cx,ds			; and pointer to object
		jmp	@@findIDExit
@@NextObject:
		cmp	[si].objtype,OBJ_PARENT
		jne	@@findIDNotParent
		push	cx
		mov	dx,word ptr [si].objptr	; load in pointer to object
		mov	cx,word ptr [si].objptr+2
		call	far ptr findObjectID2	; recurse
		mov	bp,cx
		or	bp,dx
		cmp	bp,-1
		je	@@NotFoundYet		; nope
		add	sp,8			; else get out of loop
		jmp	@@findIDExit
@@NotFoundYet:		
		pop	cx
@@findIDNotParent:
		pop	bp
		pop	bx
		pop	ax
		inc	bp
		add	si,size object
		loop	@@FindIDLoop
		mov	cx,-1
		mov	dx,-1
@@findIDExit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		ret

findObjectID	Endp

;{----------------------------------------------------------------------}
;{	objectSelectEvent:						}
;{	  come here when an object is selected and nobody else		}
;{	  dealt with it.						}
;{									}
;{	parameters:							}
;{	  ax = bits of device						}
;{----------------------------------------------------------------------}
objectSelectEvent Proc	far

		cmp	ah,OBJECTDEVICE
		jne	@@NotMyEvent
		pushall
		mov	bp,ax
		cmp	al,OBJSELECT
		je	@@ObjectSelect
		cmp	al,OBJDESELECT
		jne	@@objSelExit
@@ObjectSelect:
		mov	cx,4
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	bx,offset DGROUP:objTempQueue
		call	far ptr getMsgBuff
		cmp	ax,4
		jne	@@objSelExit
		mov	di,[bx]			; get x
		les	si,[bx+4]		; and pointer to object
		mov	bx,[bx+2]		; and y

		test	es:[si].objflags,OBJ_DISABLED
		jne	@@objSelExit
		test	es:[si].objFlags,OBJ_SELECTABLE
		je	@@objSelExit

		mov	ax,bp			; recover bits of device
		cmp	al,OBJSELECT
		jne	@@NotObjectSelect
		or	es:[si].objflags,OBJ_SELECTED
@@NotObjectSelect:
		cmp	al,OBJDESELECT
		jne	@@NotObjectDeselect
		and	es:[si].objflags,NOT OBJ_SELECTED
@@NotObjectDeselect:
		call	far ptr hideMouse

		mov	ax,di
		mov	cx,es
		mov	ds,cx

		call	far ptr drawOneObject

		call	far ptr showMouse
@@objSelExit:
		popall
@@NotMyEvent:
		xor	ax,ax
		ret

objectSelectEvent Endp


objectcseg	ends

		end
