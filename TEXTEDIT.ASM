; $Header: e:/graphic\RCS\textedit.asm_v 1.1 1993/04/23 21:10:21 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	text edit library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	2-16-1993						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log: textedit.asm_v $
; Revision 1.1  1993/04/23  21:10:21  KENH
; Initial revision
;

		locals

		include	textedit.inc

INITSTART	Segment	Public 'FAR_DATA'

INITSTART	Ends

INITEND		Segment Public 'FAR_DATA'

INITEND		Ends
		
EVENTHANDLER	Segment	Public 'FAR_DATA'

		Executehead	<"EVHA", 51000, textEditKeyEvent, KEYBOARDDEVICE>
		Executehead	<"EVHA", 32000, textEditEventHandler, TEXTEDITDEVICE>
		Executehead	<"EVHA", 32000, textEditDlgClose, DIALOGDEVICE>
		Executehead	<"EVHA", 32000, textEditDlgItem, DIALOGDEVICE>
		Executehead	<"EVHA", 51000, textEditMouseMove, MOUSEDEVICE>

EVENTHANDLER	Ends

DGROUP		GROUP	_DATA

_DATA		segment public 'DATA'

_textCursorOn	db	0
_textCursorBlink db	0
_textCursorPtr	dd	InternalInsTextCursor
_textSavePtr	dd	saveTextCursor
_textCursorRate	dw	36
_textCursorX	dw	?
_textCursorY	dw	?

cursorPos	dw	?
editingText	dw	?
toupper		db	?

		even
saveTextCursor	dw	8,8
		db	8*8 dup (?)

InternalInsTextCursor dw	8,8	 
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255
		db	0,0,255,255,255,255,255,255

InternalOvrTextCursor dw	8,8	 
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0

InternalEditCursor dw	8,8
		db	0,0,255,0,0,255,255,255
		db	255,255,0,255,255,255,255,255
		db	255,255,0,255,255,255,255,255
		db	255,255,0,255,255,255,255,255
		db	255,255,0,255,255,255,255,255
		db	255,255,0,255,255,255,255,255
		db	255,255,0,255,255,255,255,255
		db	0,0,255,0,0,255,255,255

textCursorSlice	timeSlice	<0, 0, blinkCursor, 0>

TERoutines	dw	TEEscapeRtn, TEEnterRtn, TEMoveRtnLt, TEMoveRtnRt
		dw	TEMoveRtnUp, TRMoveRtnDn, TEDelRtn, TEBSRtn
		dw	TEPGUPRtn, TEPGDNRtn, TEHomeRtn, TEEndRtn
		dw	TEInsRtn, TETabRtn, TETNormRtn

TEEditKeys	dw	ESCAPEKEY, ENTERKEY, BACKSPCKEY
		dw	DELKEY, RIGHTARKEY, LEFTARKEY
		dw	INSKEY
TEMsgOffset	equ	$-TEEditKeys
		dw	TEXTEDITESCAPE, TEXTEDITENTER, TEXTEDITBS
		dw	TEXTEDITDEL, TEXTEDITMOVERT, TEXTEDITMOVELT
		dw	TEXTEDITINS

_acceptedChars:
		db	'`1234567890-=~!@#$%^&*()_+'
		db	'qwertyuiop[]QWERTYUIOP{}'
		db	"asdfghjkl;'ASDFGHJKL:",'"'
		db	'zxcvbnm,./ZXCVBNM<>?'
		db	' \|'

_acceptSize	dw	$-_acceptedChars


editingRect	Rect	<>
editingParX	dw	?
editingParY	dw	?
editingParent	dd	?
editingStrPtr	dd	?
editingMaxLen	dw	?

insOn		db	?		; flag for insert/overwrite

_DATA		Ends

TimerDevData	Segment	Public 'FAR_DATA'


TimerDevData	Ends


TextEditCode	Segment Public 'CODE'

	    	assume	cs:TextEditCode, ds:DGROUP, es:DGROUP

;{----------------------------------------------------------------------}
;{ Function:	int _EditText(int x, int y, objectParent huge *TextPar,	}
;{				int bufLen, int curPos, int tobjID);	}
;{ Description:	Edit text on screen into buffer				}
;{ Parameters:	x = x position on screen				}
;{		y = y position on screen				}
;{		TextParent = current Text Buffer Parent Structure	}
;{		bufLen = text Buffer Length				}
;{		curPos = cursor position inside of text			}
;{		objID = objects ID to edit				}
;{ Output:	key pressed to exit					}
;{		ESC or Enter key					}
;{----------------------------------------------------------------------}
_EditText	Proc	C Far

		arg	xPos:word, yPos:word, TextPar:dword, bufLen:word
		arg	curPos:word, theobjID:word

		uses	si,di,es,ds

		mov	di,seg DGROUP
		mov	es,di

		mov	ax,curPos
		mov	es:cursorPos,ax
		mov	es:insOn,TRUE
		mov	word ptr es:_textCursorPtr,offset DGROUP:InternalInsTextCursor
		mov	word ptr es:_textCursorPtr+2,seg DGROUP

		lds	si,TextPar
		mov	ax,[si].objX
		mov	es:editingParX,ax
		mov	ax,[si].objY
		mov	es:editingParY,ax
		mov	word ptr es:EditingParent,si
		mov	word ptr es:EditingParent+2,ds
		mov	cx,word ptr [si].objPtr+2
		mov	dx,word ptr [si].objPtr
		mov	ax,theobjID
		call	far ptr findObjectID	; go get object id
		cmp	cx,-1
		jne	@@FoundOk
		cmp	dx,-1
		je	@@ETExit
@@FoundOk:
		add	ax,[si].objX
		add	bx,[si].objY

		mov	ds,cx
		mov	si,dx

		push	si
		push	ds
		and	[si].objFlags,OBJ_SELECTABLE
		add	ax,xPos
		add	bx,yPos
		add	ax,[si].objX
		add	bx,[si].objY
		mov	es:_textCursorX,ax
		mov	es:_textCursorY,bx

		mov	di,offset DGROUP:editingRect

		lds	si,TextPar

		mov	ax,[si].objW
		mov	es:[di].RectW,ax
		mov	ax,[si].objH
		mov	es:[di].RectH,ax

		mov	ax,xPos
		mov	bx,yPos
		add	es:editingParX,ax
		add	es:editingParY,bx
		add	ax,[si].objX
		add	bx,[si].objY
		mov	es:[di].RectX,ax
		mov	es:[di].RectY,bx

		mov	si,dx
		mov	ds,cx
		lds	si,[si].objPtr		; get to string pointer
		mov	al,[si].strFlags
		mov	es:toUpper,al
		les	di,[si].strPtr
		fartohuge di,es			; convert to huge pointer

		mov	cx,seg DGROUP
		mov	ds,cx
		mov	word ptr editingStrPtr,di
		mov	word ptr editingStrPtr+2,es

		mov	cx,bufLen
		mov	editingMaxLen,cx

		mov	_textCursorOn,TRUE
		mov	_textCursorBlink,0
		mov	editingText,TRUE

		mov	ax,seg DGROUP
		mov	bx,offset DGROUP:textCursorSlice
		mov	cx,_textCursorRate
		mov	[bx].timerNotify,cx

		call	far ptr addTimerNotify
		mov	al,MOUSEMOVEMENT
		call	far ptr textEditMouseMove
@@doEditText:
		call	far ptr waitForEvent	; wait for event to happen

		mov	bp,ax
		mov	ax,seg EVENTHANDLER
		xor	bx,bx
		mov	cx,"VE"
		mov	dx,"AH"
		call	far ptr ExecuteRtns	; call event handler routines

		cmp	editingText,TRUE
		je	@@doEditText

		pop	ds
		pop	si
		or	[si].objFlags,OBJ_SELECTABLE

		mov	ax,seg DGROUP
		mov	ds,ax
		mov	ax,word ptr _oldmousePtr+2
		mov	bx,word ptr _oldmousePtr
		cmp	word ptr _mousePtr,bx
		jne	@@NewMouse2		; restore if changed
		cmp	word ptr _mousePtr+2,ax
		je	@@ETExit
@@NewMouse2:
		mov	word ptr _mousePtr,bx
		mov	word ptr _mousePtr+2,ax
		call	far ptr hidemouse
		call	far ptr showmouse
@@ETExit:
		ret

_EditText	Endp

;
;
;
textEditKeyEvent Proc Far

		pushall
		cmp	ah,KEYBOARDDEVICE
		jne	@@NotKeyBoard
		cmp	al,KEYBOARDPRESS
		jne	@@NotKeyBoard
		test	inkey,0ffh		; to include keyboard.obj
		mov	bx,seg DGROUP
		mov	ds,bx
		cmp	editingText,0
		je	@@NotKeyBoard
		mov	ah,INPSTAT		; see if convert to code
		int	MSDOS
		cmp	al,0ffh	
		jne	@@NotKeyBoard
		mov	ah,UNFCHRIN
		int	MsDos
		xor	ah,ah
		or	al,al
		jne	@@NotMultiKey
		mov	ah,UNFCHRIN
		int	MsDos
		mov	ah,al
		xor	al,al			; make multi-key scan code
@@NotMultiKey:
		mov	cx,TEMsgOffset/2
		mov	di,seg DGROUP
		mov	es,di
		mov	di,offset DGROUP:TEEditKeys
@@ScanLoop:
		repne	scasw			; find key if there
		je	@@foundKey
		mov	di,offset DGROUP:_acceptedChars
		mov	cx,_acceptSize	; Number of characters in array

		repne	scasb
		jne	@@beepExit
		test	toUpper,STR_TOUPPER
		je	@@DontUpperCase
		cmp	al,'a'
		jl	@@DontUpperCase
		cmp	al,'z'
		jg	@@DontUpperCase
		and	al,0dfh
@@DontUpperCase:
		test	toUpper,STR_TOLOWER
		je	@@DontLowerCase
		cmp	al,'A'
		jl	@@DontLowerCase
		cmp	al,'Z'
		jg	@@DontLowerCase
		or	al,20h
@@DontLowerCase:
	   	mov	cx,seg tMsgQueue
		mov	ds,cx
		mov	tMsgQueue+2,ax
		mov	ah,TEXTEDITDEVICE
		mov	al,TEXTEDITNORMKEY
		mov	tMsgQueue,ax
		mov	ax,2
		push	si
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	si
		mov	ax,1
		jmp	@@WasKeyBoard
@@beepExit:
		mov	ax,1000
		mov	bx,1
		call	far ptr Beep
		mov	ax,1
		jmp	short @@wasKeyBoard
@@foundKey:
		mov	ax,es:[di+TEMsgOffset-2]
		mov	ah,TEXTEDITDEVICE
		call	far ptr addMsgQueue
		mov	ax,1
		jmp	@@WasKeyBoard
@@NotKeyBoard:
		xor	ax,ax
@@WasKeyBoard:
		popall
		ret

textEditKeyEvent Endp

;
;
;
textEditDlgClose Proc	far

		pushall

		cmp	ah,DIALOGDEVICE
		jne	@@NotMyEvent
		cmp	al,DIALOGCLOSE
		jne	@@NotMyEvent

		jmp	TEEscapeRtn
@@NotMyEvent:
		xor	ax,ax
		popall
		ret


textEditDlgClose Endp
;
;
;
textEditDlgItem Proc	far

		pushall

		cmp	ah,DIALOGDEVICE
		jne	@@NotMyEvent
		cmp	al,DIALOGITEMPRESS
		jne	@@NotMyEvent

		jmp	TEEnterRtn
@@NotMyEvent:
		xor	ax,ax
		popall
		ret


textEditDlgItem Endp
;
;
;
textEditEventHandler Proc Far

		pushall

		cmp	ah,TEXTEDITDEVICE
		jne	@@NotMyEvent

		mov	bx,ax
		and	bx,0ffh
		dec	bx
		shl	bx,1
		mov	cx,seg DGROUP
		mov	ds,cx
		mov	bx,[bx+TERoutines]
		jmp	bx
TEEscapeRtn:
		mov	bx,seg DGROUP
		mov	ds,bx
		cmp	editingText,TRUE
		jne	@@NotMyEvent
		jmp	@@EditOn
TEEnterRtn:
		mov	bx,seg DGROUP
		mov	ds,bx
		cmp	editingText,TRUE
		jne	@@NotMyEvent
@@EditOn:
		mov	_textCursorOn,FALSE
		mov	editingText,FALSE
		cmp	_textCursorBlink,1
		jne	@@CursorNotOn
		xor	_textCursorBlink,1
		xor	ax,ax
		call	far ptr drawTextCursor
@@CursorNotOn:
		mov	ax,1
		jmp	@@TEEHExit
TEBSRtn:
		mov	bx,seg DGROUP
		mov	ds,bx
		cmp	editingText,TRUE
		jne	@@NotMyEvent
		cmp	cursorPos,0
		je	beepExit
		dec	cursorPos
		sub	_textCursorX,8
TEDelRtn:
		mov	bx,seg DGROUP
		mov	ds,bx
		cmp	editingText,TRUE
		jne	@@NotMyEvent
		mov	cx,word ptr editingStrPtr+2	; save for later
		mov	bx,word ptr editingStrPtr
		mov	ax,cx
		call	far ptr strlen		; see if any left
		or	ax,ax			; to delete
		je	beepExit		; nope..
		cmp	ax,cursorPos		; end of string
		je	beepExit
		mov	ax,cx
		add	bx,cursorPos
		mov	dx,bx
		
		inc	dx			; move left to right
		call	far ptr strcpy

		jmp	redrawEditParent
TEMoveRtnLt:
		mov	bx,seg DGROUP
		mov	ds,bx
		cmp	editingText,TRUE
		jne	@@NotMyEvent
		mov	cx,word ptr editingStrPtr+2	; save for later
		mov	bx,word ptr editingStrPtr
		mov	ax,cx
		call	far ptr strlen		; see if any left
		or	ax,ax			; to delete
		je	beepExit		; nope..
		cmp	cursorPos,0		; end of string
		je	beepExit
		mov	_textCursorOn,FALSE
		cmp	_textCursorBlink,1
		jne	@@CursorNotOn2
		xor	_textCursorBlink,1
		call	far ptr drawTextCursor
@@CursorNotOn2:
		dec	cursorPos
		sub	_textCursorX,8
		mov	_textCursorOn,TRUE
		jmp	diagKeyUsed		; dialog key used
TEMoveRtnRt:
		mov	bx,seg DGROUP
		mov	ds,bx
		cmp	editingText,TRUE
		jne	@@NotMyEvent
		mov	cx,word ptr editingStrPtr+2	; save for later
		mov	bx,word ptr editingStrPtr
		mov	ax,cx
		call	far ptr strlen		; see if any left
		or	ax,ax			; to delete
		je	beepExit
		cmp	cursorPos,ax		; end of string
		je	beepExit
		mov	_textCursorOn,FALSE
		cmp	_textCursorBlink,1
		jne	@@CursorNotOn3
		xor	_textCursorBlink,1
		call	far ptr drawTextCursor
@@CursorNotOn3:
		inc	cursorPos
		add	_textCursorX,8
		mov	_textCursorOn,TRUE
		jmp	diagKeyUsed
TETNormRtn:
		mov	bx,seg DGROUP
		mov	ds,bx
		cmp	editingText,TRUE
		jne	@@NotMyEvent
		mov	cx,word ptr editingStrPtr+2	; save for later
		mov	bx,word ptr editingStrPtr
		mov	ax,cx
		call	far ptr strlen		; see if any left
		cmp	cursorPos,ax		; end of string
		je	@@NotOverWrite		; at end? insert then
		cmp	insOn,0
		je	@@OverWrite
@@NotOverWrite:
		cmp	ax,editingMaxLen	; to add
		je	beepExit
		mov	si,ax			; number of bytes to move
		mov	cx,word ptr editingStrPtr+2	; save for later
		add	bx,cursorPos
		sub	si,cursorPos
		inc	si
		mov	ax,cx
		mov	dx,bx
		inc	bx
		call	far ptr memcpy
@@OverWrite:
		call	far ptr GetMsgQueue	; get character typed
		les	di,editingStrPtr
		add	di,cursorPos
		stosb
		inc	cursorPos
		add	_textCursorX,8
		jmp	redrawEditParent

TEInsRtn:
		mov	bx,seg DGROUP
		mov	ds,bx
		cmp	editingText,TRUE
		jne	@@NotMyEvent
		mov	_textCursorOn,FALSE
		cmp	_textCursorBlink,1
		jne	@@CursorNotOn4
		xor	_textCursorBlink,1
		call	far ptr drawTextCursor
@@CursorNotOn4:
		xor	insOn,TRUE
		je	@@TEInsNotOn
		mov	word ptr _textCursorPtr,offset DGROUP:InternalInsTextCursor
		mov	word ptr _textCursorPtr+2,seg DGROUP
		jmp	@@TEOvrNotOn
@@TEInsNotOn:
		mov	word ptr _textCursorPtr,offset DGROUP:InternalOvrTextCursor
		mov	word ptr _textCursorPtr+2,seg DGROUP
@@TEOvrNotOn:
		mov	_textCursorOn,TRUE
		jmp	diagKeyUsed
TEMoveRtnUp:
TRMoveRtnDn:
TEPGUPRtn:
TEPGDNRtn:
TEHomeRtn:
TEEndRtn:
TETabRtn:

@@NotMyEvent:
		xor	ax,ax
@@TEEHExit:
		popall
		ret

redrawEditParent:
		mov	_textCursorOn,FALSE
		call	far ptr hideMouse
		push	ds
		mov	ax,editingParX
		mov	bx,editingParY
		lds	si,editingParent
		mov	cx,word ptr [si].objPtr+2
		mov	dx,word ptr [si].objPtr
		xor	bp,bp
		call	far ptr objParentDraw
		call	far ptr ShowMouse
		pop	ds
		mov	_textCursorBlink,0
		mov	_textCursorOn,TRUE
diagKeyUsed:
		mov	ax,1
		popall
		ret

beepExit:
		mov	ax,1000
		mov	bx,1
		call	far ptr Beep
		mov	ax,1
		popall
		ret
		

		

textEditEventHandler Endp

;{----------------------------------------------------------------------}
;{ Function:	drawTextCursor						}
;{ Description:	Draw or remove the text cursor with the screen		}
;{ Paramters:	.							}
;{----------------------------------------------------------------------}
drawTextCursor	Proc	far

		pushall
		
		call	far ptr hideMouse
		mov	cx,seg DGROUP
		mov	ds,cx
		cmp	_textCursorBlink,1
		jne	@@RemoveCursor

		mov	cx,_textCursorX
		mov	dx,_textCursorY
		les	bx,_textSavePtr
		mov	al,REPLACE_MODE
		callBGI	savebitmap

		mov	cx,_textCursorX
		mov	dx,_textCursorY
		les	bx,_textCursorPtr
		mov	al,AND_MODE
		callBGI	restorebitmap
		call	far ptr showMouse

		popall
		ret
@@RemoveCursor:
		mov	cx,_textCursorX
		mov	dx,_textCursorY
		les	bx,_textSavePtr
		mov	al,REPLACE_MODE
		callBGI	restorebitmap
		call	far ptr showMouse
		
		popall
		ret

drawTextCursor	Endp

;{----------------------------------------------------------------------}
;{ Function:	blinkCursor						}
;{ Description:	blink cursor on screen if showing			}
;{ Paramters:	.							}
;{----------------------------------------------------------------------}
blinkCursor	Proc	far

		pushall

		mov	ax,seg DGROUP
		mov	ds,ax
		cmp	_textCursorOn,TRUE
		jne	@@NoTextCursor

		xor	_textCursorBlink,1
		call	far ptr drawTextCursor
@@NoTextCursor:

		popall
		ret

blinkCursor	Endp


;{----------------------------------------------------------------------}
;{ Function:	textEditMouseMove					}
;{ Description:	come here when mouse moves for text editing handler	}
;{ Paramters:	ax = device bits					}
;{----------------------------------------------------------------------}
textEditMouseMove Proc	far

		pushall
		cmp	al,MOUSEMOVEMENT
		jne	@@NotMyEvent

		mov	ax,seg DGROUP
		mov	ds,ax
		cmp	editingText,FALSE
		je	@@NotMyEvent
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	ax,_mouseX
		mov	bx,_mouseY		; get x and y of mouse
		mov	cx,seg DGROUP
		mov	dx,offset DGROUP:editingRect
		call	far ptr ptInRect	; see if inside
		or	ax,ax
		je	@@NotInside
		mov	ax,seg DGROUP
		mov	bx,offset DGROUP:InternalEditCursor
		cmp	ax,word ptr _mousePtr+2
		jne	@@NewMouse
		cmp	bx,word ptr _mousePtr
		jne	@@NewMouse
		jmp	@@NotMyEvent
@@NewMouse:
		xchg	ax,word ptr _mousePtr+2
		mov	word ptr _oldmousePtr+2,ax
		xchg	bx,word ptr _mousePtr
		mov	word ptr _oldmousePtr,bx
		call	far ptr hidemouse
		call	far ptr showmouse	; redraw mouse
		jmp	@@NotMyEvent
@@NotInside:
		mov	ax,word ptr _oldmousePtr+2
		mov	bx,word ptr _oldmousePtr
		cmp	word ptr _mousePtr,bx
		jne	@@NewMouse2
		cmp	word ptr _mousePtr+2,ax
		je	@@NotMyEvent
@@NewMouse2:
		mov	word ptr _mousePtr,bx
		mov	word ptr _mousePtr+2,ax
		call	far ptr hidemouse
		call	far ptr showmouse
@@NotMyEvent:
		popall
		xor	ax,ax
		ret

textEditMouseMove Endp

TextEditCode	Ends

		end

