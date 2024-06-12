; $Header: e:/graphic\RCS\filedlg.asm_v 1.1 1993/04/23 21:07:33 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	msdos dialog library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log: filedlg.asm_v $
; Revision 1.1  1993/04/23  21:07:33  KENH
; Initial revision
;
		locals

		include	filedlg.inc

FDPATHSTRID	equ	2002
FDFNAMESTRID	equ	2004




EVENTHANDLER	Segment	Public 'FAR_DATA'

;
; ----- for system dialog boxes.  You can still receive systems
;	messages first if your priority is greater than 50000
;
		Executehead	<"EVHA", 51000, fileDlgItemEvent, DIALOGDEVICE>

EVENTHANDLER	Ends

filedlgdseg	Segment Public 'FAR_DATA'


rect1		objRect	<0, 0, REPLACE_MODE>
line1		objLine	<0, 0fh, REPLACE_MODE, 0, 0>
line2		objLine	<0, 8, REPLACE_MODE, 0, 0>
line3		objLine	<0, 0, REPLACE_MODE, 0, 0>
;
; -----	System file selector dialog resource data
;
objfileDialog	dw	2
		object	<0, 0, 280, 13, OBJ_PARENT, 0, 0, FDTopBar>
FDMAINRECTNUM	equ	($-(objfileDialog+2))/size object
		object	<0, 12, 280, 152, OBJ_PARENT, 0, 0, FDMainRect>

;
; ----- Top info bar for file selector
;
FDTopBar	dw	7
		object	<0, 0, 280, 13, OBJ_RECT, 0, 0, rect1>
		object	<1, 1, 278, 11, OBJ_BAR, 0, 0, sysDialogBar>
		object	<1, 1, 278, 1, OBJ_LINE, 0, 0, line1>
		object	<1, 2, 1, 11, OBJ_LINE, 0, 0, line1>
		object	<278, 1, 278, 11, OBJ_LINE, 0, 0, line2>
		object	<2, 11, 278, 11, OBJ_LINE, 0, 0, line2>
FDTBObject7	object	<4, 2, 278, 11, OBJ_PARENT, 0, 0, FDTStrParent>

FDTStrParent	dw	1
FDTStrObject1	object	<0, 0, 0, 0, OBJ_STR, 0, 0, FDTObjStr>

;
; ----- Main Dialog bar for file selector
;
FDMainRect	dw	14
		object	<0, 0, 280, 152, OBJ_RECT, 0, 0, rect1>
		object	<1, 1, 278, 150, OBJ_BAR, 0, 0, sysDialogBar>
		object	<1, 1, 278, 1, OBJ_LINE, 0, 0, line1>
		object	<1, 2, 1, 150, OBJ_LINE, 0, 0, line1>
		object	<278, 1, 278, 150, OBJ_LINE, 0, 0, line2>
		object	<2, 150, 278, 150, OBJ_LINE, 0, 0, line2>
		object	<11, 13, 0, 8, OBJ_STR, 0, 0, pathObjStr>
PATHRECTNUM	equ	($-(FDMainRect+2))/size object
		object	<46, 10, 222, 12, OBJ_PARENT, 0, 0, pathRect>
		object	<11, 26, 0, 8, OBJ_STR, 0, 0, fNameObjStr>
FILERECTNUM	equ	($-(FDMainRect+2))/size object
		object	<78, 24, 190, 12, OBJ_PARENT, 0, 0, fNameRect>
		object	<14, 41, 115, 96, OBJ_PARENT, 0, 0, filesRect>
		object	<138, 41, 130, 67, OBJ_PARENT, 0, 0, DirsRect>
		object	<150, 117, 0, 0, OBJ_BITMAP, OBJ_SELECTABLE, \
				OK_BUTTON, InternalBitmaps+OBJOKBUTTON>
		object	<212, 117, 0, 0, OBJ_BITMAP, OBJ_SELECTABLE, \
				CANCEL_BUTTON, InternalBitmaps+OBJCANCELBUTTON>

pathRect	dw	6
		object	<1, 1, 220, 10, OBJ_BAR, 0, 0, sysDialogBar>
		object	<0, 0, 221, 0, OBJ_LINE, 0, 0, line2>
		object	<0, 1, 0, 11, OBJ_LINE, 0, 0, line2>
		object	<221, 1, 221, 11, OBJ_LINE, 0, 0, line1>
		object	<1, 11, 221, 11, OBJ_LINE, 0, 0, line1>
		object	<0, 0, 212, 8, OBJ_PARENT, 0, 0, pathStrParent>
		
fNameRect	dw	6
		object	<1, 1, 188, 10, OBJ_BAR, 0, 0, sysDialogBar>
		object	<0, 0, 189, 0, OBJ_LINE, 0, 0, line2>
		object	<0, 1, 0, 11, OBJ_LINE, 0, 0, line2>
		object	<189, 1, 189, 11, OBJ_LINE, 0, 0, line1>
		object	<1, 11, 189, 11, OBJ_LINE, 0, 0, line1>
		object	<0, 0, 180, 8, OBJ_PARENT,  0, 0, fNameStrParent>

;
; ----- files rectangle parent for file selector
;
filesRect	dw	3
		object	<0, 0, 113, 13, OBJ_PARENT, 0, 0, filesHeader>
		object	<0, 12, 101, 84, OBJ_PARENT, 0, 0, filesList>
		object	<101, 13, 12, 83, OBJ_PARENT, 0, 0, filesVScroll>

filesHeader	dw	6
		object	<0, 0, 113, 12, OBJ_BAR, 0, 0, sysDialogBar>
		object	<0, 0, 112, 0, OBJ_LINE, 0, 0, line1>
		object	<0, 1, 0, 12, OBJ_LINE, 0, 0, line1>
		object	<112, 1, 112, 12, OBJ_LINE, 0, 0, line2>
		object	<1, 12, 112, 12, OBJ_LINE, 0, 0, line2>
		object	<4, 2, 0, 0, OBJ_STR, 0, 0, FileObjStr>

filesList	dw	13
		object	<0, 0, 101, 12, OBJ_BAR, 0, 0, sysDialogBar>
		object	<0, 0, 100, 0, OBJ_LINE, 0, 0, line2>
		object	<0, 1, 0, 83, OBJ_LINE, 0, 0, line2>
		object	<100, 1, 100, 83, OBJ_LINE, 0, 0, line1>
		object	<1, 83, 100, 83, OBJ_LINE, 0, 0, line1>
FLFilesObjects	object	<4, 2, 0, 0, OBJ_STR, 0, 0, Files1ObjStr>
		object	<4, 12, 0, 0, OBJ_STR, 0, 0, Files2ObjStr>
		object	<4, 22, 0, 0, OBJ_STR, 0, 0, Files3ObjStr>
		object	<4, 32, 0, 0, OBJ_STR, 0, 0, Files4ObjStr>
		object	<4, 42, 0, 0, OBJ_STR, 0, 0, Files5ObjStr>
		object	<4, 52, 0, 0, OBJ_STR, 0, 0, Files6ObjStr>
		object	<4, 62, 0, 0, OBJ_STR, 0, 0, Files7ObjStr>
		object	<4, 72, 0, 0, OBJ_STR, 0, 0, Files8ObjStr>

filesVScroll	dw	5
		object	<0, 0, 12, 83, OBJ_RECT, 0, 0, ScrollRect>
		object	<1, 1, 10, 81, OBJ_BAR, 0, 0, ScrollBar>
		object	<0, 0, 0, 0, OBJ_BITMAP, OBJ_SELECTABLE, 0,\
				InternalBitmaps+OBJUPARROW>
		object	<0, 12, 0, 0, OBJ_BITMAP, 0, 0,\
				InternalBitmaps+OBJBLOCK>
		object	<0, 71, 0, 0, OBJ_BITMAP, OBJ_SELECTABLE, 0,\
				InternalBitmaps+OBJDNARROW>

;
; ----- directories rectangle parent for file selector
;
DirsRect	dw	3
		object	<0, 0, 128, 13, OBJ_PARENT, 0, 0, DirsHeader>
		object	<0, 12, 116, 55, OBJ_PARENT, 0, 0, DirsList>
		object	<116, 13, 12, 54, OBJ_PARENT, 0, 0, DirsVScroll>

DirsHeader	dw	6
		object	<0, 0, 128, 12, OBJ_BAR, 0, 0, sysDialogBar>
		object	<0, 0, 127, 0, OBJ_LINE, 0, 0, line1>
		object	<0, 1, 0, 12, OBJ_LINE, 0, 0, line1>
		object	<127, 1, 127, 12, OBJ_LINE, 0, 0, line2>
		object	<1, 12, 127, 12, OBJ_LINE, 0, 0, line2>
		object	<4, 2, 0, 0, OBJ_STR, 0, 0, DirsObjStr>

DirsList	dw	6
		object	<0, 0, 116, 12, OBJ_BAR, 0, 0, sysDialogBar>
		object	<0, 0, 115, 0, OBJ_LINE, 0, 0, line2>
		object	<0, 1, 0, 54, OBJ_LINE, 0, 0, line2>
		object	<115, 1, 115, 54, OBJ_LINE, 0, 0, line1>
		object	<1, 54, 115, 54, OBJ_LINE, 0, 0, line1>
		object	<4, 2, 0, 0, OBJ_STR, 0, 0, Files1ObjStr>

DirsVScroll	dw	5
		object	<0, 0, 12, 54, OBJ_RECT, 0, 0, ScrollRect>
		object	<1, 1, 10, 52, OBJ_BAR, 0, 0, ScrollBar>
		object	<0, 0, 0, 0, OBJ_BITMAP, OBJ_SELECTABLE, 0,\
				InternalBitmaps+OBJUPARROW>
		object	<0, 12, 0, 0, OBJ_BITMAP, 0, 0,\
				InternalBitmaps+OBJBLOCK>
		object	<0, 42, 0, 0, OBJ_BITMAP, OBJ_SELECTABLE, 0,\
				InternalBitmaps+OBJDNARROW>

pathStrParent	dw	1
		object	<4, 2, 0, 0, OBJ_STR, OBJ_SELECTABLE OR OBJ_EDITABLE, \
				FDPATHSTRID, pathEditStr>

fNameStrParent	dw	1
		object	<4, 2, 0, 0, OBJ_STR, OBJ_SELECTABLE OR OBJ_EDITABLE, \
				FDFNAMESTRID, fNameEditStr>

FDTObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, 0>
pathObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, pathStr>
pathEditStr	objStr	<0, 0, STR_TOUPPER, 0, 8, 7, XPARENT_MODE, 0>
fNameObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, fNameStr>
fNameEditStr	objStr	<0, 0, STR_TOUPPER, 0, 8, 7, XPARENT_MODE, 0>
FileObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, FileStr>
DirsObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, DirsStr>

Files1ObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, gNullStr>
Files2ObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, gNullStr>
Files3ObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, gNullStr>
Files4ObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, gNullStr>
Files5ObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, gNullStr>
Files6ObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, gNullStr>
Files7ObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, gNullStr>
Files8ObjStr	objStr	<0, 0, 0, 0, 8, 7, XPARENT_MODE, gNullStr>

ScrollRect	objRect	<0, 0, REPLACE_MODE>
ScrollBar	objBar	<0, 0fh, REPLACE_MODE, 9, 0>

pathStr		db	'~Path',0
fNameStr	db	'File~name',0
FileStr		db	'~File',0
DirsStr		db	'~Directories',0

fileDialogX	dw	?
fileDialogY	dw	?

currSelect	dd	?

editRect	Rect	<?>

filedlgdseg	Ends

DGROUP		GROUP 	_DATA

_DATA		segment public 'DATA'
_DATA		ends


filedlgcseg	Segment Public 'CODE'

		assume	cs:filedlgcseg,ds:filedlgdseg

;{----------------------------------------------------------------------}
;{ Function:	int _fileDialog(char far *filename, char far *pathname, }
;{			char far *titleStr:				}
;{ Description:	default file dialog routine				}
;{ Parameters:	filename = current file name buffer			}
;{		pathname = current path name buffer			}
;{		titlestr = title string for dialog			}
;{----------------------------------------------------------------------}
_fileDialog	Proc	C far

		arg	filename:dword, pathname:dword, titlestr:dword

		uses	si,di,ds,es

		mov	ax,word ptr filename+2
		mov	bx,word ptr filename
		mov	cx,word ptr pathname+2
		mov	dx,word ptr pathname
		mov	si,word ptr titlestr+2
		mov	di,word ptr titlestr
		call	far ptr fileDialog

		ret

_fileDialog	Endp
;{----------------------------------------------------------------------}
;{	fileDialog:							}
;{	  default file dialog routine					}
;{	  ax:bx = current file name					}
;{	  cx:dx = current pathname					}
;{	  si:di = title string pointer					}
;{----------------------------------------------------------------------}
fileDialog	Proc	far

		
		pushall

		mov	bp,seg pathEditStr
		mov	ds,bp

;
; -----	setup initial path
;
		mov	word ptr pathEditStr.strptr,dx
		mov	word ptr pathEditStr.strptr+2,cx

		mov	word ptr fNameEditStr.strptr,bx
		mov	word ptr fNameEditStr.strptr+2,ax

		mov	word ptr FDTObjStr.strptr,di
		mov	word ptr FDTObjStr.strptr+2,si

		mov	es,si
		xor	al,al
		mov	cx,-1
		xor	al,al
		mov	bx,di
		repne	scasb			; wait till zero byte found
		mov	di,bx
		neg	cx
		sub	cx,2
		jne	@@objHasText
		xor	bx,bx
		xor	cx,cx
		jmp	@@objHasNoText
@@objHasText:
		push	si
		push	ds
		mov	ax,seg DGROUP
		mov	ds,ax
	 	callBGI	textsize		; get text size
		pop	ds
		pop	si
		add	bx,4			; 4 pixels on right side
@@objHasNoText:
		neg	bx
		neg	cx

		add	bx,FDTBObject7.objW	; get pixels left and right
		jge	@@XTextFits		; does it fit
		xor	bx,bx			; then let parent clip it out
@@XTextFits:
		add	cx,FDTBObject7.objH	; how about height
		jge	@@YTextFits		; yep
		xor	cx,cx			; let parent clip again
@@YTextFits:
		shr	bx,1
		shr	cx,1			; center text
		mov	FDTStrObject1.objX,bx
		mov	FDTStrObject1.objY,cx	; save x & y offsets

		mov	cx,seg objfileDialog
		mov	dx,offset objfileDialog
		call	far ptr sizeObjects	; get width & height of dialog

		assume	ds:DGROUP
		mov	cx,seg DGROUP 
		mov	ds,cx 
		mov	cx,xMax
		sub	cx,xMin			; get width of window
		mov	dx,yMax
		sub	dx,yMin

		assume	ds:filedlgdseg

		sub	cx,ax			; center in
		jl	@@NoRoomInWindow	; no room in clip window
		sub	dx,bx
		jge	@@RoomInWindow		; room in clip window!
@@NoRoomInWindow:
		jmp	@@FDExit
@@RoomInWindow:
		mov	ax,cx
		mov	bx,dx
		call	far ptr hideMouse
		shr	ax,1
		shr	bx,1			; make in middle
		mov	cx,seg objfileDialog
		mov	ds,cx
		mov	dx,offset objfileDialog
		mov	fileDialogX,ax
		mov	fileDialogY,bx
		mov	si,seg dialogX
		mov	ds,si
		mov	dialogX,ax
		mov	dialogY,bx		; save x & y
		call	far ptr drawObjects	; draw the dialog

		call	far ptr showMouse

		mov	ax,FALSE		; yes system dialog
		mov	bx,FALSE		; yes need to draw
		mov	cx,seg objfileDialog
		mov	dx,offset objfileDialog
		call	far ptr doDialog

@@FDExit:
		popall
		ret

fileDialog	Endp


;
;
;
fileDlgItemEvent Proc	far

		pushall
		cmp	al,DIALOGITEMRELEASE
		jne	@@NotMyEvent


		call	far ptr getTempMsgWord

		cmp	ax,FDPATHSTRID
		jne	@@NotPathStr

		mov	ax,seg fileDialogX
		mov	ds,ax
		mov	es,ax
		mov	ax,fileDialogX
		mov	bx,fileDialogY
		mov	di,offset editRect

		mov	si,offset objfileDialog+(FDMAINRECTNUM*size object)+2
		add	ax,[si].objX
		add	bx,[si].objY
		lds	si,[si].objptr
		add	si,(PATHRECTNUM*size object)+2
		mov	cx,FDPATHSTRID
		push	cx
		xor	cx,cx
		push	cx
		mov	cx,65
		push	cx
		push	ds
		push	si
		push	bx
		push	ax
		call	far ptr _EditText
		add	sp,14
		jmp	@@NotMyEvent
@@NotPathStr:
		cmp	ax,FDFNAMESTRID
		jne	@@NotMyEvent
		mov	ax,seg fileDialogX
		mov	ds,ax
		mov	es,ax
		mov	ax,fileDialogX
		mov	bx,fileDialogY
		mov	di,offset editRect

		mov	si,offset objfileDialog+(FDMAINRECTNUM*size object)+2
		add	ax,[si].objX
		add	bx,[si].objY
		lds	si,[si].objptr
		add	si,(FILERECTNUM*size object)+2
		mov	cx,FDFNAMESTRID
		push	cx
		xor	cx,cx
		push	cx
		mov	cx,13
		push	cx
		push	ds
		push	si
		push	bx
		push	ax
		call	far ptr _EditText
		add	sp,14
@@NotMyEvent:
		popall
		xor	ax,ax
		ret



fileDlgItemEvent Endp

filedlgcseg	Ends

		end
