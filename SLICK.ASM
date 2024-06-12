; $Header$

;{----------------------------------------------------------------------}
;{	SLICK								}
;{		Super Light Ingenious Character Kit			}
;{									}
;{	A compact character and sprite editor for games			}
;{									}
;{	Copyright (c) 1992 Futurescape Productions			}
;{									}
;{	Author: Kenneth L. Hurley					}
;{									}
;{	Uses GRACE windows kit						}
;{----------------------------------------------------------------------}

; $Log$

		include dos.inc
		include	window.inc
		include mouse.inc
		include	menu.inc
		include keyboard.inc
		include dialog.inc

		dosseg

MY_WIN_DEFAULTS	equ	WIN_DRAW OR WIN_TITLE_BAR OR WIN_CLOSE_BM OR \
		WIN_VSCROLL OR WIN_HSCROLL OR WIN_SIZE_BM

;
READMODE	equ	0
;
RETURN_AOK	equ	0
RETURN_NOARG	equ	1
RETURN_NOPEN	equ	2
RETURN_INTERNAL	equ	3
RETURN_MALLOC	equ	4
RETURN_WINOPEN	equ	5
RETURN_NOMOUSE	equ	6
;
;
;
BGI_HEADER_SIZE	equ	160
;
;
;
sseg		segment STACK 'STACK'

thestack	label	byte
		dw	1024 dup (0)
endprog		equ	$-thestack

sseg		ends

EVENTHANDLER	Segment	Public 'FAR_DATA'

		Executehead	<"EVHA", 32000, myMenuEventHandler, MENUDEVICE>
		Executehead	<"EVHA", 32000, myWinEventHandler, WINDOWDEVICE>
		Executehead	<"EVHA", 32000, myWinEventHandler, MOUSEDEVICE>
		Executehead	<"EVHA", 32000, myWinEventHandler, KEYBOARDDEVICE>

EVENTHANDLER	Ends

DGROUP		GROUP	_DATA
_DATA	segment public 'DATA'

		include	slick.inc

ComLinePtr	dd	?
ComLineSize	dw	-1

OpenError	db	"Unable to open file ->$"
NoArgError	db	"No file specified!$"
InternalError	db	"Internal Error!$"
MallocError	db	"Unable to allocate memory!$"
WinOpenError	db	"Unable to open window!$"
NoMouseError	db	"Unable to find mouse!$"
EOL		db	CR,LF,"$"
VideoMode	db	0

quitStr		db	"Are you sure you",CR,LF
		db	"want to quit?",0

UnfStr		db	"That menu item is not",CR,LF
		db	"functioning yet!!!!",0

defFile		db	"MCGA.BGI",0

bgiLoad		dw	?

win1hand	dw	?

mymsgQueue	dw	16 dup (?)

backfName	db	'*.LBM',0
backPath	db	'E:\GRAPHICS\',0
LoadBackStr	db	'Load Background File',0

DITable		$DIT	<>

__BGI_add	dd	?

_DATA	ends

cseg		segment	'CODE'

		assume	cs:cseg,ds:DGROUP,es:DGROUP
start:

		call	far ptr init

		xor	ax,ax
		call	far ptr setKeySwitch

		call	far ptr FindMouseDriver
		or	ax,ax
		jne	FoundMouse
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	dx,offset NoMouseError
		mov	bx,RETURN_NOMOUSE
		jmp	ErrorExit
FoundMouse:
		call	near ptr ParseComLine	; get an argument
		jnc	DoLoadFile

		mov	ax,seg DGROUP
		mov	bx,offset defFile
;		mov	ax,seg DGROUP
;		mov	ds,ax
;		mov	dx,offset NoArgError
;		mov	bx,RETURN_NOARG
;		jmp	ErrorExit
DoLoadFile:
		push	ax
		push	bx
		mov	cx,ss
		mov	bx,(endprog+15) AND 0fff0h
		shr	bx,1
		shr	bx,1
		shr	bx,1
		shr	bx,1
		add	bx,cx
		sub	bx,word ptr ComLinePtr+2
		mov	es,word ptr ComLinePtr+2
		mov	ah,ShrinkMem
		int	MsDos

		pop	bx
		pop	ax
		
		push	ax
		push	bx
		call	far ptr FileSize

		call	far ptr farMalloc
		mov	dx,bx
		or	dx,ax
		jne	@@FileMallocOK
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	dx,offset MallocError
		mov	bx,RETURN_MALLOC
		jmp	ErrorExit
@@FileMallocOK:
		mov	cx,ax
		mov	dx,bx
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	bgiLoad,cx		; save address of load
		pop	bx
		pop	ax

		push	cx
		push	dx
		call	near ptr ELoadFile	; read in file if possible
		pop	dx
		pop	cx

		add	dx,BGI_HEADER_SIZE
		shr	dx,1
		shr	dx,1
		shr	dx,1
		shr	dx,1
		mov	ax,cx
		add	ax,dx
		xor	dx,dx
		mov	cx,seg DGROUP
		mov	ds,cx

		mov	word ptr __BGI_add,dx
		mov	word ptr __BGI_add+2,ax

		xor	ax,ax			; get DST
		callBGI install

		mov	ax,seg DGROUP
		mov	es,ax
		mov	bx,offset DITable
		mov	al,backcolor
		mov	es:[bx].$backcolor,al
		callBGI	init			; into video mode

		call	far ptr BGIDefaults

		callBGI	clear

		xor	ax,ax
		xor	bx,bx
		mov	cx,seg DGROUP
		mov	dx,offset menuobject
		call	far ptr drawMenuBar

		mov	ax,50
		mov	bx,50
		mov	cx,200
		mov	dx,100
		mov	si,MY_WIN_DEFAULTS

		call	far ptr makewindow

		or	ax,ax
		jne	@@WinOpened
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	dx,offset WinOpenError
		mov	bx,RETURN_WINOPEN
		jmp	ErrorExit
@@WinOpened:
		mov	win1hand,ax

;		mov	ax,OBJ_INVISIBLE
;		mov	cx,seg DGROUP
;		mov	dx,offset menuobject
;		mov	si,3
;		call	far ptr clearObjectFlags
;
;		mov	ax,OBJ_SELECTED
;		mov	cx,seg DGROUP
;		mov	dx,offset menuobject
;		mov	si,2
;		call	far ptr setObjectFlags
;
;		xor	ax,ax
;		xor	bx,bx
;		mov	cx,seg DGROUP
;		mov	dx,offset menuobject
;		mov	si,2
;		call	far ptr redrawObject
;
;		xor	ax,ax
;		xor	bx,bx
;		mov	cx,seg DGROUP
;		mov	dx,offset menuobject
;		mov	si,3
;		call	far ptr redrawObject
;
;		mov	ax,OBJ_SELECTED
;		mov	cx,seg DGROUP
;		mov	dx,offset menu1
;		mov	si,4
;		call	far ptr setObjectFlags
;
;		mov	ax,8
;		mov	bx,12
;		mov	cx,seg DGROUP
;		mov	dx,offset menu1
;		mov	si,4
;		call	far ptr redrawObject

		mov	ax,CHGMODE
		call	far ptr InitMouse
		call	far ptr ShowMouse

		call	far ptr eventManager	; wait for events to happen
myExit:
		mov	ax,seg DGROUP
		mov	ds,ax

		callBGI	post

		mov	es,win1hand
		mov	ah,FreeMem
		int	MsDos

		mov	es,bgiLoad
		mov	ah,FreeMem
		int	MsDos
NoReset1:
		mov	ax,(PTerm SHL 8) OR RETURN_AOK
		int	MsDos
ErrorExit:
		mov	ah,PrintStr
		int	MsDos
		mov	al,bl
		mov	ah,PTerm
		int	MsDos

;{----------------------------------------------------------------------}
;{	myWinEventHandler:						}
;{	  receive window events and take care of them			}
;{									}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bits of device						}
;{----------------------------------------------------------------------}
myWinEventHandler Proc	far

		pushall

		cmp	ah,MOUSEDEVICE
		jne	@@NotMouseEvent

		cmp	al,MButton2Press
		jne	@@NotMouseEvent

		jmp	myExit
@@NotMouseEvent:
		cmp	ah,KEYBOARDDEVICE
		jne	@@NotKeyBoard
		cmp	al,KEYBOARDPRESS
		jne	@@NotKeyBoard
		mov	ah,UnfChrIn
		int	MsDos
		cmp	al,1bh
		jne	@@NotKeyBoard
		jmp	myExit
@@NotKeyBoard:
		xor	ax,ax
		popall
		ret

myWinEventHandler Endp

;{----------------------------------------------------------------------}
;{	myMenuEventHandler:						}
;{	  receive menu events and take care of them			}
;{									}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bits of device						}
;{----------------------------------------------------------------------}
myMenuEventHandler Proc	far

		pushall

		cmp	al,MENUITEMRELEASE
		jne	@@NotMenuSelection

		mov	ax,seg DGROUP
		mov	ds,ax
		mov	bx,offset mymsgQueue
		mov	cx,3
		call	far ptr getMsgBuff

		cmp	ax,3
		jl	@@NotMenuSelection

		cmp	word ptr [bx],FILE_QUIT
		jne	@@NotMenuSelQuit
		mov	ax,75
		mov	bx,75
		mov	cx,seg DGROUP
		mov	dx,offset quitStr
		mov	si,(DIALOG_OK_BIT OR DIALOG_CANCEL_BIT \
				OR DIALOG_ICON_BIT)
		mov	di,OBJSTOPICON
		call	far ptr alert
		cmp	ax,CANCEL_BUTTON
		je	@@NotMenuSelection
		jmp	myexit
@@NotMenuSelQuit:
		cmp	word ptr [bx],FILE_LOAD_B
		jne	@@NotMenuLoadBack
		mov	ax,seg DGROUP
		mov	bx,offset backfName
		mov	cx,seg DGROUP
		mov	dx,offset backPath
		mov	si,seg DGROUP
		mov	di,offset LoadBackStr
		call	far ptr fileDialog
		jmp	@@NotMenuSelection
@@NotMenuLoadBack:
		mov	ax,75
		mov	bx,75
		mov	cx,seg DGROUP
		mov	dx,offset UnfStr
		mov	si,DIALOG_OK_BIT
		call	far ptr alert
@@NotMenuSelection:
		xor	ax,ax
		popall
		ret

myMenuEventHandler Endp

;{----------------------------------------------------------------------}
;{	FileSize:							}
;{	  return file size from name					}
;{									}
;{	parameters:							}
;{	  ax:bx = filename						}
;{									}
;{	returns:							}
;{	  ax:bx = size of file						}
;{----------------------------------------------------------------------}
FileSize	Proc	far

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	ds,ax
		mov	es,ax
		mov	dx,bx
		mov	di,bx

		mov	ax,(OpenFile SHL 8) OR READMODE
		int	MsDos
		jnc	@@OpenOK
		jmp	FNFError
@@OpenOK:
		mov	bx,ax
		mov	ax,(MOVEFILEPTR SHL 8) OR 2
		xor	cx,cx
		xor	dx,dx
		int	MsDos

		mov	cx,ax
		mov	ah,CLOSEFILE
		int	MsDos

		mov	ax,dx
		mov	bx,cx

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

FileSize	Endp

;{----------------------------------------------------------------------}
;{	void far *_farMalloc(long size)					}
;{	  allocate memory of size bytes					}
;{									}
;{	parameters:							}
;{	  size = number of bytes to allocate				}
;{									}
;{	returns:							}
;{	  far pointer to allocated memory				}
;{----------------------------------------------------------------------}
_farmalloc	Proc	far

		arg	insize:dword

		push	bp
		mov	bp,sp


		mov	ax,word ptr insize+2
		mov	bx,word ptr insize
		call	far ptr farmalloc
		jnc	@@NoError
		xor	ax,ax
		xor	bx,bx
@@NoError:
		mov	dx,ax
		mov	ax,bx
		pop	bp
		ret
		
_farmalloc	Endp

;{----------------------------------------------------------------------}
;{	farmalloc:							}
;{	  allocate memory of size bytes					}
;{									}
;{	parameters:							}
;{	  ax:bx = number of bytes to allocate				}
;{									}
;{	returns:							}
;{	  ax:bx far pointer to allocated memory				}
;{----------------------------------------------------------------------}
farmalloc	Proc	far

		add	bx,15
		adc	ax,0
		longtopara ax,bx

		mov	ah,AllocMem
		int	MsDos
		jc	@@Error
		xor	bx,bx
@@Error:
		ret

farmalloc	Endp

;{----------------------------------------------------------------------}
;{	void _farfree(void far *memPtr)					}
;{	  free memory alloced previously				}
;{									}
;{	parameters:							}
;{	  memPtr = void far pointer to allocated memory			}
;{									}
;{----------------------------------------------------------------------}
_farfree	Proc	far

		arg	memPtr:dword

		push	bp
		mov	bp,sp

		mov	ax,word ptr memPtr+2
		mov	bx,word ptr memPtr
		call	far ptr farfree
		pop	bp
		ret
		
_farfree	Endp

;{----------------------------------------------------------------------}
;{	farfree:							}
;{	  free memory alloced previously				}
;{									}
;{	parameters:							}
;{	  ax:bx far pointer to allocated memory				}
;{----------------------------------------------------------------------}
farfree		Proc	far

		mov	es,ax
		mov	ah,FreeMem
		int	MsDos
		ret

farfree		Endp

;{----------------------------------------------------------------------}
;{	ELoadFile:							}
;{	  Try reading in a file and report unable to open file		}
;{	  if error occurs.						}
;{----------------------------------------------------------------------}
ELoadFile	Proc	Near

		mov	es,ax
		mov	di,bx
		call	near ptr MyLoadFile
		jnc	ERFExit

FNFError:
		mov	bp,di			; save of beginning
		mov	al,0
		mov	cx,-1
		repne	scasb			; scan for end of string
		je	NoIntern
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	dx,offset InternalError
		mov	bx,RETURN_INTERNAL
		jmp	ErrorExit
NoIntern:
		mov	byte ptr es:[di-1],'$'	; terminate with $
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	dx,offset OpenError
		mov	ah,PrintStr
		int	MsDos
		mov	dx,bp
		push	ds
		mov	ax,es
		mov	ds,ax
		mov	ah,PrintStr
		int	MsDos
		pop	ds
		mov	dx,offset EOL
		int	MsDos
		jmp	ErrorExit
ERFExit:
		ret

ELoadFile	Endp

;{----------------------------------------------------------------------}
;{ 	MyLoadFile:							}
;{	  read in filename specified by ax:bx into buffer at cx:dx	}
;{	  max filesize = 64k						}
;{	  returns carry set on error					}
;{	  and ax = error number from dos				}
;{----------------------------------------------------------------------}
MyLoadFile	Proc	Near

		
		mov	ds,ax
		xchg	dx,bx
		xor	bp,bp

		mov	ax,(OpenFile SHL 8) OR READMODE
		int	MsDos
		jc	RFExit

		mov	bp,ax
		mov	dx,bx
		mov	bx,ax		; save off handle
		mov	ds,cx

		mov	cx,dx
		neg	cx		; max read in this segment
		or	cx,cx
		jne	@@maxReadOK
		dec	cx
@@maxReadOK:
		mov	ah,ReadFile
		int	MsDos		; now read in file
RFExit:
		pushf
		or	bp,bp
		je	RFEl2
		mov	bx,bp
		mov	ah,CloseFile
		int	MsDos
RFEl2:
		popf
		ret
		
MyLoadFile	Endp

;{----------------------------------------------------------------------}
;{	ParseComLine:							}
;{	Parse a argument from the command line				}
;{	return ax:bx pointer to name					}
;{----------------------------------------------------------------------}
ParseComLine	Proc	Near


		mov	si,seg DGROUP
		mov	ds,si

		cmp	ComLineSize,-1
		jne	NoCLSetup

		mov	ah,GetPsp
		int	MsDos			; get out psp segment

		mov	word ptr ComLinePtr+2,bx
		mov	word ptr ComLinePtr,81h
		mov	es,bx
		mov	al,es:[80h]		; get size of command line
		xor	ah,ah
		mov	ComLineSize,ax		; save command line size
NoCLSetup:
		xor	dx,dx
		xor	bp,bp			; no commands left

		mov	cx,ComLineSize
		lds	si,ComLinePtr		; load point to command line
		jcxz	NoneLeft
StripPreWS:
		mov	al,[si]
		cmp	al,' '
		je	StillWS
		cmp	al,TAB
		je	StillWS
		cmp	al,CR
		je	StillWS
		cmp	al,LF
		jne	ToNextArg
StillWS:
		inc	si
		loop	StripPreWS		; keep checking
ToNextArg:
		mov	dx,ds
		mov	bp,si			; save pointer to line
LoopNextArg:
		mov	al,[si]
		cmp	al,' '
		je	FoundNextArg
		cmp	al,TAB			; scan to next WS character
		je	FoundNextArg
		cmp	al,CR
		je	FoundNextArg
		cmp	al,LF
		je	FoundNextArg
		inc	si
		loop	LoopNextArg		; keep checking
FoundNextArg:
		mov	byte ptr [si],0		; zero terminate it
NoneLeft:
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	ComLineSize,cx
		mov	word ptr ComLinePtr,si
		mov	ax,dx
		mov	bx,bp			; return start of argument
		clc
		cmp	ax,0
		jne	PCLExit
		cmp	bx,0
		jne	PCLExit
		stc				; if zero exit
PCLExit:
		ret
		
ParseComLine	Endp

cseg		ends

		end	start


