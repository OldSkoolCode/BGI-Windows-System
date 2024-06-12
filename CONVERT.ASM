

		include dos.inc
		include	window.inc
		include mouse.inc
		include	menu.inc
		include keyboard.inc
		include dialog.inc
		include	ilbm.inc

		dosseg

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

DGROUP		GROUP	_DATA

_DATA	segment public 'DATA'

ComLinePtr	dd	?
ComLineSize	dw	-1

OpenError	db	"Unable to open file ->$"
NoArgError	db	"No file specified!$"
InternalError	db	"Internal Error!$"
EOL		db	CR,LF,"$"

_DATA	ends
				   
cseg		segment	'CODE'

		assume	cs:cseg,ds:DGROUP,es:DGROUP
start:

		call	far ptr init

		xor	ax,ax
		call	far ptr setKeySwitch

		call	near ptr ParseComLine	; get an argument
		jnc	DoLoadFile

		mov	ax,seg DGROUP
		mov	ds,ax
		mov	dx,offset NoArgError
		mov	bx,RETURN_NOARG
		jmp	ErrorExit
DoLoadFile:
		push	ax
		push	bx
		mov	cx,101b
		xor	dx,dx
		call	far ptr loadiff

		mov	ax,(PTerm SHL 8) OR RETURN_AOK
		int	MsDos
ErrorExit:
		mov	ah,PrintStr
		int	MsDos
		mov	al,bl
		mov	ah,PTerm
		int	MsDos

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


