; $Header: e:/graphic\RCS\events.asm_v 1.1 1993/04/23 21:10:21 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	MSDOS event library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log: events.asm_v $
; Revision 1.1  1993/04/23  21:10:21  KENH
; Initial revision
;
		locals

		include	events.inc

INITSTART	Segment Public 'FAR_DATA'

		Executehead	<"GRIN",40000,SortEVHA>

		if DEBUG
		Executehead	<"GRIN",32767,openRecord>
		endif

INITSTART	Ends

EVENTHANDLER	Segment	Public 'FAR_DATA'

		if DEBUG
;		Executehead	<"EVHA", 65000, RecordMessageParms, KEYBOARDDEVICE>
;		Executehead	<"EVHA", 65000, RecordMessageParms, JOYSTICKDEVICE>
;		Executehead	<"EVHA", 65000, RecordMessageParms, TIMERDEVICE>
;		Executehead	<"EVHA", 65000, RecordMessageParms, HWMOUSEDEVICE>
;		Executehead	<"EVHA", 65000, RecordMessageParms, MOUSEDEVICE>
;		Executehead	<"EVHA", 65000, RecordMessageParms, MENUDEVICE>
		Executehead	<"EVHA", 65000, RecordMessageParms, WINDOWDEVICE>
;		Executehead	<"EVHA", 65000, RecordMessageParms, DIALOGDEVICE>
;		Executehead	<"EVHA", 65000, RecordMessageParms, OBJECTDEVICE>
;		Executehead	<"EVHA", 65000, RecordMessageParms, TEXTEDITDEVICE>
		Executehead	<"EVHA", 65000, RecordMessageParms, REFRESHDEVICE>

		endif

		Executehead	<"EVHA", 0, ClearMessageParms, KEYBOARDDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, JOYSTICKDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, TIMERDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, HWMOUSEDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, MOUSEDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, MENUDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, WINDOWDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, DIALOGDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, OBJECTDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, TEXTEDITDEVICE>
		Executehead	<"EVHA", 0, ClearMessageParms, REFRESHDEVICE>

EVENTHANDLER	Ends

INITEND		Segment Public 'FAR_DATA'

		if DEBUG
		Executehead	<"GREN",50,closeRecord>
		endif

;
; ----- very low so everything else gets flushed first
;	reset video mode is 100 which is only thing with lower priority
;
		Executehead	<"GREN",200,flushEvents>


INITEND		Ends

eventdseg	Segment	Public 'FAR_DATA'

msgQueue	dw	128 dup (?)
endMsgQueue	label	word
msgSizeOff	equ	$-msgQueue
msgSize		dw	128 dup (?)
msgHead		dw	msgQueue
msgTail		dw	msgQueue
msgQueueFull	dw	0

tNumStr		db	6 dup (0)
tMsgQueue	dw	16 dup (?)
msgSizeLeft	dw	0

recordMsgBuff	dw	16 dup (?)
		if	DEBUG
recordHand	dw	-1
recordOn	dw	TRUE
recordName	db	'MESSAGES.SAV',0

titleStr	db	'DEVICE		BITS		       	PARM1	PARM2	PARM3	PARM4	PARM5',CR,LF
		db	'--------------	---------------------	-------	-------	-------	-------	-------'
EolStr		db	CR,LF
titleStrLen	equ	$-titleStr
tabStr		db	TAB

deviceStrs	db	'NULL    '	
		db	'KEYBOARD'	
		db	'JOYSTICK'	
		db	'HW-TIMER'	
		db	'TIMER   '	
		db	'HW-MOUSE'	
		db	'MOUSE   '	
		db	'MENU    '	
		db	'WINDOW  '	
		db	'DIALOG  '	
		db	'OBJECT  '	
		db	'TEXTEDIT'	
		db	'REFRESH '	
					
subDevicePtrs	label	word
		dw	nullSubs
		dw	keySubs
		dw	joySubs
		dw	timerSubs
		dw	timerSubs
		dw	hwMouseSubs
		dw	mouseSubs
		dw	menuSubs
		dw	winSubs
		dw	dlgSubs
		dw	objSubs
		dw	teSubs
		dw	refreshSubs

nullSubs	db	'NULL            '
		db	0

keySubs		db	'NULL            '
		db	'KEYBOARDPRESS   '
		db	'KEYBOARDRELEASE '

joySubs		db	'NULL            '
		db	0

timerSubs	db	'NULL            '
		db	'TIMERTICK       '

hwMouseSubs	db	'NULL            '
		db	'HWMOUSEMOVEMENT '
		db	'HWMBUTTON1PRESS '
		db	'HWMBUTTON1RELEA '
		db	'HWMBUTTON2PRESS '
		db	'HWMBUTTON2RELEA '
		db	'HWMBUTTON3PRESS '
		db	'HWMBUTTON3RELEA '

mouseSubs	db	'NULL            '
		db	'MOUSEMOVEMENT   '
		db	'MBUTTON1PRESS   '
		db	'MBUTTON1RELEASE '
		db	'MBUTTON2PRESS   '
		db	'MBUTTON2RELEASE '
		db	'MBUTTON3PRESS   '
		db	'MBUTTON3RELEASE '

menuSubs	db	'NULL            '
		db	'MENUSELECT      '
		db	'MENUDESELECT    '
		db	'MENUMOUSEMOVE   '
		db	'MENUITEMSELECT  '
		db	'MENUITEMDESELECT'
		db	'MENUITEMRELEASE '
	
winSubs		db	'NULL            '
		db	'WINDOW_REDRAW_WS'
		db	'WINDOW_CLOSE    '
		db	'WINDOW_RESIZE   '
		db	'WINDOW_MOVE     '
		db	'WINDOW_VS_UP    '
		db	'WINDOW_VS_DOWN  '
		db	'WINDOW_VS_BAR   '
		db	'WINDOW_HS_LEFT  '
		db	'WINDOW_HS_RIGHT '
		db	'WINDOW_HS_BAR   '
		db	'WINDOW_TO_TOP   '
		db	'WINDOW_TO_BACK  '
		db	'WINDOW_MOUSE_MOV'
		db	'WINDOW_MOUSE_CLI'
		db	'WINDOW_KEY_PRESS'
		db	'WINDOW_KEY_RELEA'
		db	'WINDOW_COOKED_KE'
		db	'WINDOWITEMPRESS '
		db	'WINDOWITEMRELEAS'
		db	'WINDOW_SYSREDRAW'


dlgSubs		db	'NULL            '
		db	'DIALOGSELECT    '
		db	'DIALOGDESELECT  '
		db	'DIALOGMOUSEMOVE '
		db	'DIALOGITEMSELECT'
		db	'DIALOGITEMDESEL '
		db	'DIALOGITEMREL   '
		db	'DIALOGITEMPRESS '
		db	'DIALOGCLOSE     '

objSubs		db	'NULL            '
		db	'OBJSELECT       '
		db	'OBJDESELECT     '
		db	'OBJMOUSEMOVE    '
		db	'OBJRELEASE      '


TESubs		db	'NULL            '
		db	'TEXTEDITESCAPE	 '
		db	'TEXTEDITENTER	 '
		db	'TEXTEDITMOVELT	 '
		db	'TEXTEDITMOVERT	 '
		db	'TEXTEDITMOVEUP	 '
		db	'TEXTEDITMOVEDN	 '
		db	'TEXTEDITDEL	 '
		db	'TEXTEDITBS	 '
		db	'TEXTEDITPGUP	 '
		db	'TEXTEDITPGDN	 '
		db	'TEXTEDITHOME	 '
		db	'TEXTEDITEND	 '
		db	'TEXTEDITINS	 '
		db	'TEXTEDITTAB	 '
		db	'TEXTEDITNORMKEY '


refreshSubs	db	'NULL            '
		db	'REDRAW_SYSRECT	 '
		db	'BACK_SYSREDRAW	 '


		endif

eventdseg	Ends

eventcseg	Segment 'CODE'

		assume	cs:eventcseg, ds:eventdseg

;{----------------------------------------------------------------------}
;{	SortEVHA:							}
;{	  sort up the EVENTHANDLER execute header structures		}
;{----------------------------------------------------------------------}
SortEVHA	Proc	far

		pushall
		mov	ax,seg EVENTHANDLER
		xor	bx,bx
		mov	cx,"VE"
		mov	dx,"AH"
		call	far ptr SortRtns
		xor	ax,ax
		popall
		ret
		
SortEVHA	Endp

;{----------------------------------------------------------------------}
;{ Function:	void addMsgQueue(int msg);				}
;{ Description:	'C' callable add 1 message to the rotating queue	}
;{ Parameters:	msg = high byte = device low byte = bits for device	}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
_addMsgQueue	Proc C Far

		arg	msg:word

		mov	ax,msg
		call	far ptr addMsgQueue
		ret


_addMsgQueue	Endp

;{----------------------------------------------------------------------}
;{	addMsgQueue:							}
;{	  add a message to the rotating queue				}
;{									}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bits for device						}
;{----------------------------------------------------------------------}
addMsgQueue	Proc	far

		push	bx
		push	cx
		push	ds

		mov	bx,seg msgHead
		mov	ds,bx

@@WaitEmpty:
		cmp	msgQueueFull,0
		je	@@NotFull
	     	call	far ptr Exec1Event
		jmp	@@WaitEmpty
@@NotFull:
		cli
		mov	cx,msgHead
		mov	bx,msgTail		; get current pointer
		mov	[bx],ax			; save message
		mov	word ptr [bx+msgSizeOff],1
		add	bx,2			; next pointer
		cmp	bx,offset endMsgQueue
		jb	@@TailOK
		mov	bx,offset msgQueue
@@TailOK:
		cmp	bx,cx			; still != than msgTail
		jne	@@HeadOK
		mov	msgQueueFull,1		; msg queue is Full
@@HeadOK:
		mov	msgHead,cx
		mov	msgTail,bx
		sti
		pop	ds
		pop	cx
		pop	bx
		ret

addMsgQueue	Endp

;{----------------------------------------------------------------------}
;{ Function:	void addMsgBuff(int nMessages, int *msgs);		}
;{ Description:	add messages to the rotating queue			}
;{ Parameters:	nMessages = Number of messages to send			}
;{		msgs = pointer to integer values for messages		}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
_addMsgBuff	Proc C Far

		uses	ds,si
		arg	nMessages:word
		arg	msgs:dword

		mov	ax,nMessages
		lds	si,msgs
		call	far ptr addMsgBuff
		ret

_addMsgBuff	Endp

;{----------------------------------------------------------------------}
;{	addMsgBuff:							}
;{	  add message(s) to the rotating queue				}
;{									}
;{	parameters:							}
;{	  ax = # messages						}
;{----------------------------------------------------------------------}
addMsgBuff	Proc	far

		pushall

		mov	dx,ax
		push	si
		push	ds
@@AddLoop:
		mov	bx,seg msgHead
		mov	es,bx
		mov	ds,bx

		cmp	msgQueueFull,0
		jne	@@DoWait
		cli				; make sure no one interrupts
		mov	cx,msgHead
		mov	bx,msgTail		; get current pointer

		mov	bp,cx
		sub	bp,bx
		cmp	bx,cx
		jb	@@FoundSizeLeft		; found size of buffer left
		mov	bp,cx
		sub	bp,offset msgQueue
		mov	ax,offset endMsgQueue
		sub	ax,bx
		add	bp,ax
@@FoundSizeLeft:
		shr	bp,1
		cmp	bp,dx
		jae	@@RoomInBuff
@@DoWait:
		sti
		push	dx
	     	call	far ptr Exec1Event
		pop	dx			; events to free up room
		jmp	@@AddLoop
@@RoomInBuff:
		mov	di,bx
		shl	dx,1			; number of messages
		add	bx,dx
		cmp	bx,offset endMsgQueue
		jl	@@TailOK
		sub	bx,offset endMsgQueue
		add	bx,offset msgQueue
@@TailOK:
		cmp	bx,cx			; still != than msgTail
		jne	@@HeadOK		; out of messages
		mov	msgQueueFull,1		; message queue is full
@@HeadOK:
		mov	msgHead,cx
		mov	msgTail,bx
		sti

		pop	ds
		pop	si
		shr	dx,1
		mov	cx,dx
@@msgCopyLoop:
		movsw
		mov	es:[di+msgSizeOff-2],dx
		dec	dx
		cmp	di,offset endMsgQueue
		jl	@@Tail2OK
		mov	di,offset msgQueue
@@Tail2OK:
		loop	@@msgCopyLoop

		popall
		ret

addMsgBuff	Endp

;{----------------------------------------------------------------------}
;{	getMsgQueue:							}
;{	  get a message from the rotating queue				}
;{									}
;{	returns:							}
;{	  ah = device #							}
;{	  al = bits for device						}
;{	  or ax = parameters						}
;{----------------------------------------------------------------------}
getMsgQueue	Proc	far

		push	bx
		push	cx
		push	ds

		mov	bx,seg msgHead
		mov	ds,bx

		xor	ax,ax
		mov	bx,msgHead		; if == queue is empty
		cmp	msgQueueFull,0
		jne	@@FoundMsg
		cmp	bx,msgTail
		je	@@NoMessages
@@FoundMsg:
		mov	ax,[bx]			; get message
		mov	cx,[bx+msgSizeOff]
		add	bx,2			; previous message
		cmp	bx,offset endMsgQueue
		jl	@@HeadOK
		mov	bx,offset msgQueue
@@HeadOK:
		mov	msgHead,bx
		mov	msgSizeLeft,cx
@@NoMessages:
		mov	msgQueueFull,0		; message queue is not full
		pop	ds
		pop	cx
		pop	bx
		ret

getMsgQueue	Endp

;{----------------------------------------------------------------------}
;{ Function:	_getTempMsgWord(void);					}
;{ Description:	'C' callable routine to get a temporary message word	}
;{ Parameters:	.							}
;{ returns:	ax = message or 0					}
;{----------------------------------------------------------------------}
_getTempMsgWord	Proc	C Far

;{----------------------------------------------------------------------}
;{	getTempMsgWord:							}
;{	  get a message from the rotating queue without updating queue	}
;{									}
;{	returns:							}
;{	  ah = device #							}
;{	  al = bits for device						}
;{	  or ax = parameters						}
;{----------------------------------------------------------------------}
getTempMsgWord	Proc	far

		push	bx
		push	cx
		push	ds

		mov	bx,seg msgHead
		mov	ds,bx

		xor	ax,ax
		mov	bx,msgHead		; if == queue is empty
		cmp	msgQueueFull,0
		jne	@@FoundMsg
		cmp	bx,msgTail
		je	@@NoMessages
@@FoundMsg:
		mov	ax,[bx]			; get message
@@NoMessages:
		pop	ds
		pop	cx
		pop	bx
		ret

getTempMsgWord	Endp

_getTempMsgWord	Endp

;{----------------------------------------------------------------------}
;{	int _getTempMsgBuff(int huge *bufPtr, int nMsgs);		}
;{	  put messages in temporary buffer				}
;{									}
;{	parameters:							}
;{	  bufPtr = pointer to word buffer				}
;{	  nMsgs = number of messages					}
;{									}
;{	returns:							}
;{	  ax = number of message copied					}
;{									}
;{----------------------------------------------------------------------}
_getTempMsgBuff	Proc	C far

		arg	bufPtr:dword, nMsgs:word

		mov	ax,word ptr bufPtr+2
		mov	bx,word ptr bufPtr
		mov	cx,word ptr nMsgs
		call	far ptr getTempMsgBuff
		ret

_getTempMsgBuff	Endp

;{----------------------------------------------------------------------}
;{	getTempMsgBuff:							}
;{	  put messages in temporary buffer				}
;{									}
;{	parameters:							}
;{	  ax:bx = pointer to temporary buffer				}
;{	  cx = number of messages					}
;{									}
;{	returns:							}
;{	  ax = number of message copied					}
;{									}
;{----------------------------------------------------------------------}
getTempMsgBuff	Proc	far

		pushall

		mov	es,ax
		mov	di,bx

		xor	ax,ax
		mov	dx,seg msgHead
		mov	ds,dx

		mov	si,msgHead		; if == queue is empty
		cmp	msgQueueFull,0
		jne	@@FoundMsg
@@getTMsgs:
		cmp	si,msgTail
		je	@@NoMessages
@@FoundMsg:
		movsw
		inc	ax
		cmp	si,offset endMsgQueue
		jl	@@HeadOK
		mov	si,offset msgQueue
@@HeadOK:
		loop	@@getTMsgs
@@NoMessages:
		popall
		ret

getTempMsgBuff	Endp

;{----------------------------------------------------------------------}
;{	getMsgBuff:							}
;{	  put messages in buffer					}
;{									}
;{	parameters:							}
;{	  ax:bx = pointer to tempoary buffer				}
;{	  cx = number of messages					}
;{									}
;{	returns:							}
;{	  ax = number of message copied					}
;{									}
;{----------------------------------------------------------------------}
getMsgBuff	Proc	far

		jcxz	@@NoneWanted
		pushall

		mov	es,ax
		mov	di,bx

		xor	ax,ax
		mov	dx,seg msgHead
		mov	ds,dx
		mov	si,msgHead		; if == queue is empty
		cmp	msgQueueFull,0
		jne	@@FoundMsg
@@getTMsgs:
		cmp	si,msgTail
		je	@@NoMessages
@@FoundMsg:
		movsw
		mov	bp,[si+msgSizeOff-2]	; get size of messages left
		inc	ax
		cmp	si,offset endMsgQueue
		jl	@@HeadOK
		mov	si,offset msgQueue
@@HeadOK:
		loop	@@getTMsgs
@@NoMessages:
		mov	msgQueueFull,0		; message queue is not full
		mov	msgHead,si
		mov	msgSizeLeft,bp
		popall
@@NoneWanted:
		ret

getMsgBuff	Endp

;{----------------------------------------------------------------------}
;{	waitForEvent:							}
;{	  check for event that happened					}
;{									}
;{	returns:							}
;{	  ah = event device						}
;{	  al = bits of event device					}
;{----------------------------------------------------------------------}
waitForEvent	Proc	far

		push	bx
		push	ds
		mov	bx,seg msgHead
		mov	ds,bx
		mov	bx,msgHead
		cmp	msgQueueFull,0
		jne	@@FoundMsg
@@WFEl1:
		cmp	bx,msgTail
		je	@@WFEl1
@@FoundMsg:
		call	far ptr getMsgQueue
		pop	ds
		pop	bx
		ret

waitForEvent	Endp

;{----------------------------------------------------------------------}
;{	_eventManager:							}
;{	  wait for events to happen and call event routines		}
;{----------------------------------------------------------------------}
_eventManager	Proc	C far

;{----------------------------------------------------------------------}
;{	eventManager:							}
;{	  wait for events to happen and call event routines		}
;{----------------------------------------------------------------------}
eventManager	Proc	far

		call	far ptr waitForEvent

		mov	bp,ax
		mov	ax,seg EVENTHANDLER
		xor	bx,bx
		mov	cx,"VE"
		mov	dx,"AH"
		call	far ptr ExecuteRtns

		jmp	eventManager


eventManager	Endp

_eventManager	Endp

;{----------------------------------------------------------------------}
;{ Function:	Exec1Event						}
;{ Description:	execute 1 event and return				}
;{ Parameters:	.							}
;{ returns:	.							}
;{----------------------------------------------------------------------}
Exec1Event	Proc	far

		call	far ptr waitForEvent

		mov	bp,ax
		mov	ax,seg EVENTHANDLER
		xor	bx,bx
		mov	cx,"VE"
		mov	dx,"AH"
		call	far ptr ExecuteRtns

		ret

Exec1Event	Endp

;{----------------------------------------------------------------------}
;{	sendMessage:							}
;{	  send message to event handlers				}
;{									}
;{	parameters:							}
;{	  ah = device type						}
;{	  al = bits for device						}
;{	  bx = miscelleneous pass pointer				}
;{----------------------------------------------------------------------}
sendMessage	Proc	far


		pushall		
		mov	bp,ax
		mov	si,bx
		mov	ax,seg EVENTHANDLER
		xor	bx,bx
		mov	cx,"VE"
		mov	dx,"AH"
		call	far ptr ExecuteRtns

		popall
		ret

sendMessage	Endp

;{----------------------------------------------------------------------}
;{	ClearMessageParms:						}
;{	  clear the unused message parameters from queue if they	}
;{	  weren't taken care of.					}
;{----------------------------------------------------------------------}
ClearMessageParms Proc	far

		pushall

		mov	ax,seg msgSizeLeft
		mov	ds,ax
		mov	bp,msgSizeLeft
		dec	bp
		je	@@AllDone
		mov	bx,offset tMsgQueue
@@ClearLoop:
		mov	cx,bp
		cmp	bp,16
		jle	@@lengthOK
		mov	cx,16
@@lengthOK:
		mov	ax,ds
		call	far ptr getMsgBuff
		sub	bp,cx
		jne	@@ClearLoop
@@AllDone:
		mov	ax,1
		popall
		ret

ClearMessageParms Endp

;{----------------------------------------------------------------------}
;{ Function:	flushEvents						}
;{ Description:	flush all events from the queue				}
;{ Parameters:	.							}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
flushEvents	Proc	far

@@waitLoop:
		call	far ptr getTempMsgWord
		or	ax,ax
		je	@@AllDone
		call	far ptr Exec1Event
		jmp	short @@waitLoop
@@AllDone:
		xor	ax,ax
		ret

flushEvents	Endp


		if	DEBUG
;{----------------------------------------------------------------------}
;{	openRecord:							}
;{	  open up recording file if any					}
;{----------------------------------------------------------------------}
openRecord	Proc	far

		push	bx
		push	cx
		push	dx
		push	ds

		mov	cx,seg recordOn
		mov	ds,cx
		cmp	recordOn,TRUE
		jne	@@DontRecord

		mov	dx,offset recordName
		mov	ah,CREATEFILE
		xor	cx,cx
		int	MsDos

		mov	recordHand,ax
		mov	bx,ax

		mov	dx,offset titleStr
		mov	ah,WRITEFILE
		mov	cx,titleStrLen
		int	MSDOS
@@DontRecord:
		pop	ds
		pop	dx
		pop	cx
		pop	bx

		xor	ax,ax
		ret

openRecord	Endp

;{----------------------------------------------------------------------}
;{	closeRecord:							}
;{	  close recording file if any					}
;{----------------------------------------------------------------------}
closeRecord	Proc	far


		push	bx
		push	cx
		push	dx
		push	ds

		mov	cx,seg recordOn
		mov	ds,cx
		cmp	recordOn,TRUE
		jne	@@DontRecord

		mov	bx,recordHand
		mov	ah,CLOSEFILE
		int	MSDOS
@@DontRecord:
		pop	ds
		pop	dx
		pop	cx
		pop	bx

		xor	ax,ax
		ret

closeRecord	Endp

;{----------------------------------------------------------------------}
;{	RecordMessageParms:						}
;{	  record the message parameters from queue if they		}
;{	  weren't taken care of.					}
;{----------------------------------------------------------------------}
RecordMessageParms Proc	far

		pushall


		mov	cx,seg recordOn
		mov	ds,cx
		cmp	recordOn,TRUE
		jne	@@DontRecord
		push	ax

		mov	bx,recordHand
		mov	dl,ah
		and	dx,0ffh
		shl	dx,1
		shl	dx,1
		shl	dx,1
		add	dx,offset deviceStrs

		mov	cx,8
		mov	ah,WRITEFILE
		int	MSDOS

		mov	ah,WRITEFILE
		mov	cx,1
		mov	dx,offset tabStr
		int	MSDOS

		pop	ax
		mov	bl,ah
		and	bx,0ffh

		shl	bx,1
		mov	dx,[bx+subDevicePtrs]	; grab pointer to bits set
		and	ax,0ffh
		shl	ax,1
		shl	ax,1
		shl	ax,1
		shl	ax,1
		add	dx,ax
		mov	cx,16
		mov	bx,recordHand
		mov	ah,WRITEFILE
		int	MSDOS

		mov	ah,WRITEFILE
		mov	cx,1
		mov	dx,offset tabStr
		int	MSDOS

		mov	bp,msgSizeLeft
		dec	bp
		mov	cx,bp
		jle	@@AllDone
		mov	ax,seg recordMsgBuff
		mov	ds,ax
		mov	bx,offset recordMsgBuff
		mov	si,bx
		call	far ptr getTempMsgBuff
;		lodsw
@@ParmLoop:
		lodsw
		mov	cx,ax
;		and	cx,0ffh
		mov	ax,seg tMsgQueue
		mov	bx,offset tMsgQueue

		call	far ptr hextodec	; convert hex to decimal

		mov	ax,seg tMsgQueue
		call	far ptr strlen
		mov	cx,ax

		mov	bx,recordHand
		mov	dx,offset tMsgQueue
		mov	ah,WRITEFILE
		int	MSDOS

		mov	dx,offset tabStr
		mov	cx,1
		mov	ah,WRITEFILE
		int	MSDOS

		dec	bp
		jg	@@ParmLoop

@@AllDone:
		mov	dx,offset EOLstr
		mov	cx,2
		mov	ah,WRITEFILE
		int	MSDOS

@@DontRecord:
		xor	ax,ax
		popall
		ret

RecordMessageParms Endp

		endif

eventcseg	Ends

		end
