; $Header: e:/graphic\RCS\dos.asm_v 1.2 1993/05/18 16:44:15 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	MSDOS DOS library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log: dos.asm_v $
; Revision 1.2  1993/05/18  16:44:15  KENH
; *** empty log message ***
;
; Revision 1.1  1993/04/23  21:07:33  KENH
; Initial revision
;
		locals

		include	dos.inc

DGROUP		GROUP	_DATA

_DATA		Segment Public 'DATA'

;
;
;
;sbytebuff	db	1024 dup (?)		;\ don't seperate these
;sbytebnum	dw	sbytebuff+1024		;/
;sendbytebuff	dw	sbytebuff+1024
;dbytebuff	db	1024 dup (?)
;dbytebnum	dw	dbytebuff
sbytebuff	db	10			;\ don't seperate these
sbytebnum	dw	sbytebuff+1024		;/
sendbytebuff	dw	sbytebuff+1024
dbytebuff	db	10
dbytebnum	dw	dbytebuff
inpfhand	dw	?
outpfhand	dw	?
inpdatartn	dd	buffgetbyte
outpdatartn	dd	memstorebyte
outpflushrtn	dd	nobufflush
inpseekrtn	dd	ibuffseek
outpseekrtn	dd	omemseek
inpdataptr	dw	?,?
inpdatasize	dw	?,?
outpdataptr	dw	?,?
outpdatasize	dw	?,?
destmemory	db	FALSE

hiandval	db	0ffh
loworval	db	0
decvals		dw	10000,1000,100,10,1

hexascii	db	"0123456789abcdef"
notherterms	dw	0
otherterms	dd	?
curdtaptr	dd	0		
;
;
;
_DATA		Ends

INITSTART	Segment Public 'FAR_DATA'

		Executehead	<"GRIN",32767,initdos>

INITSTART	Ends

dos		Segment Public 'CODE'

		assume	cs:dos,ds:DGROUP,ss:nothing,es:DGROUP

;{----------------------------------------------------------------------}
;{	initdos:							}
;{	  initialize vectors for exit					}
;{----------------------------------------------------------------------}
initdos		Proc	Far

		pushall

		mov	ah,GETDTA
		int	MSDOS
		
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	word ptr curdtaptr,bx
		mov	word ptr curdtaptr+2,es

		popall
		xor	ax,ax
		ret

initdos		Endp

;{----------------------------------------------------------------------}
;{	getfirstfilename:						}
;{	  get file names with filespec					}
;{	  ax:bx = filespec pointer					}
;{	  cx = attribute spec						}
;{	  returns:							}
;{	   ax:bx = first filename pointer				}
;{	   or c = 1 ax = error #					}
;{----------------------------------------------------------------------}
getfirstfilename Proc	Far

		push	cx
		push	dx
		push	ds
		push	es
		
		mov	ds,ax
		mov	dx,bx
		mov	ah,GETDTA		; get current pointer to DTA
		int	MSDOS
		
		Int	MSDOS
		mov	ah,FSFIRST		; get a file name
		int	MSDOS
		jnc	@@1
		neg	ax
		jmp	short @@2
@@1:
		lea	bx,[bx].FDTAFileName
		mov	ax,es
@@2:
		pop	es
		pop	ds
		pop	dx
		pop	cx
		ret
		
getfirstfilename Endp

;{----------------------------------------------------------------------}
;{	getnextfilename:						}
;{	  get the next file name after calling get first file name	}
;{	returns:							}
;{	  ax:bx = pointer to filename					}
;{	  or c = 1 then ax = error #					}
;{----------------------------------------------------------------------}
getnextfilename	Proc	Far

		push	es

		mov	ah,GETDTA
		int	MSDOS

		mov	ah,FSNEXT
		int	MSDOS
		jnc	@@1
		neg	ax
		jmp	short @@2
@@1:
		mov	ax,es
		lea	bx,[bx].FDTAFileName
@@2:
		pop	es
		ret

getnextfilename	Endp

;{----------------------------------------------------------------------}
;{	setsrcasmemory:							}
;{	  set memory as the source stuff				}
;{	  ax:bx = source memory pointer					}
;{----------------------------------------------------------------------}
setsrcasmemory	Proc	Far

		pushall

		mov	cx,DGROUP
		mov	ds,cx
		mov	word ptr inpdataptr,bx
		mov	word ptr inpdataptr+2,ax
		mov	cx,seg DGROUP
		mov	word ptr inpdatartn+2,cx
		lea	bx,memgetbyte
		mov	word ptr inpdatartn,bx
		mov	word ptr inpseekrtn+2,cx
		lea	bx,imemseek
		mov	word ptr inpseekrtn,bx

		popall

		ret

setsrcasmemory	Endp

;{----------------------------------------------------------------------}
;{	getfilesize:							}
;{	  get a filesize handle in ax					}
;{----------------------------------------------------------------------}
getfilesize	Proc	Far

		push	cx
		push	dx
		push	bp
		push	si

		mov	bx,ax
		mov	ah,MOVEFILEPTR
		mov	al,1
		xor	cx,cx
		xor	dx,dx			; go nowhere
		Int	MSDOS			; just return current offset
		jc	@@1
		push	ax
		push	dx			; save offsets
		mov	ah,MOVEFILEPTR
		mov	al,2			; from end of file
		xor	cx,cx
		xor	dx,dx
		Int	MSDOS			; to get file length
		mov	bp,dx			; save significant digit
		mov	si,ax			; and least also
		pop	cx
		pop	dx
		jc	@@1
		mov	ah,MOVEFILEPTR		; move file ptr to place
		xor	al,al
		Int	MSDOS			; back to where we were
		jc	@@1
		mov	ax,bp
		mov	bx,si			; back to passing parms
@@1:
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

getfilesize	Endp

;{----------------------------------------------------------------------}
;{	setsrcasdisk:							}
;{	  set disk as the source stuff					}
;{	  ax = file handle to use					}
;{----------------------------------------------------------------------}
setsrcasdisk	Proc	Far

		pushall

		mov	cx,DGROUP
		mov	ds,cx
		mov	inpfhand,ax		; save file handle
		mov	cx,seg DGROUP
		mov	word ptr inpdatartn+2,cx
		lea	bx,buffgetbyte
		mov	word ptr inpdatartn,bx
		mov	word ptr inpseekrtn+2,cx
		lea	bx,ibuffseek
		mov	word ptr inpseekrtn,bx
		lea	bx,sbytebuff+1024
		mov	sbytebnum,bx
		mov	sendbytebuff,bx

		popall

		ret

setsrcasdisk	Endp

;{----------------------------------------------------------------------}
;{	setdestasmemory:						}
;{	  set memory as the source stuff				}
;{	  ax:bx = source memory pointer					}
;{----------------------------------------------------------------------}
setdestasmemory	Proc	Far

		pushall

		mov	cx,DGROUP
		mov	ds,cx
		mov	word ptr outpdataptr,bx
		mov	word ptr outpdataptr+2,ax
		mov	cx,seg DGROUP
		mov	word ptr outpdatartn+2,cx
		lea	bx,memstorebyte
		mov	word ptr outpdatartn,bx
		mov	word ptr outpseekrtn+2,cx
		lea	bx,omemseek
		mov	word ptr outpseekrtn,bx
		mov	word ptr outpflushrtn+2,cx
		lea	bx,nobufflush
		mov	word ptr outpflushrtn,bx
		mov	destmemory,TRUE

		popall

		ret

setdestasmemory	Endp

;{----------------------------------------------------------------------}
;{	setdestasdisk:							}
;{	  set disk as the destination stuff				}
;{	  ax = file handle to use					}
;{----------------------------------------------------------------------}
setdestasdisk	Proc	Far

		pushall

		mov	cx,DGROUP
		mov	ds,cx
		mov	outpfhand,ax		; save file handle
		mov	cx,seg DGROUP
		mov	word ptr outpdatartn+2,cx
		lea	bx,buffstorebyte
		mov	word ptr outpdatartn,bx
		mov	word ptr outpseekrtn+2,cx
		lea	bx,obuffseek
		mov	word ptr outpseekrtn,bx
		mov	word ptr outpflushrtn+2,cx
		lea	bx,obufflush
		mov	word ptr outpflushrtn,bx
		lea	bx,dbytebuff
		mov	dbytebnum,bx
		mov	destmemory,FALSE

		popall

		ret

setdestasdisk	Endp

;{----------------------------------------------------------------------}
;{	imemseek:							}
;{	  seek to new memory location					}
;{	  cx:dx = signed offset to seek to				}
;{----------------------------------------------------------------------}
imemseek	Proc	Far

		pushall

		mov	ax,DGROUP
		mov	ds,ax
		mov	ax,cx
		add	word ptr inpdataptr,dx
		adc	ax,0
		mov	cl,4
		ror	ax,cl
		and	ax,0f000h
		add	word ptr inpdataptr+2,ax

		popall
		ret

imemseek	Endp

;{----------------------------------------------------------------------}
;{	omemseek:							}
;{	  seek to new memory location					}
;{	  cx:dx = signed offset to seek to				}
;{----------------------------------------------------------------------}
omemseek	Proc	Far

		pushall

		mov	ax,DGROUP
		mov	ds,ax
		mov	ax,cx
		add	word ptr outpdataptr,dx
		adc	ax,0
		mov	cl,4
		ror	ax,cl
		and	ax,0f000h
		add	word ptr outpdataptr+2,ax

		popall
		ret

omemseek	Endp

;{----------------------------------------------------------------------}
;{	ibuffseek:							}
;{	  seek for source buffer					}
;{----------------------------------------------------------------------}
ibuffseek	Proc	Far

		pushall
		
		mov	ax,DGROUP
		mov	ds,ax
		lea	bp,sbytebuff
		xor	ax,ax
		mov	bx,sbytebnum
		sub	bx,bp
		sbb	ax,0
		add	bx,dx
		adc	ax,cx
		add	bx,bp
		cmp	bx,offset DGROUP:sbytebuff
		jb	@@1
		cmp	bx,sendbytebuff
		jae	@@1
		mov	sbytebnum,bx
		clc
		jmp	@@2
@@1:
		xor	ax,ax
		mov	bx,sbytebnum
		sub	bx,sendbytebuff
		sbb	ax,0
		add	dx,bx
		adc	cx,ax
		mov	bx,sendbytebuff
		mov	sbytebnum,bx		; force reload of buffer
		mov	bx,inpfhand
		mov	ah,MOVEFILEPTR
		mov	al,1			; from current position
		Int	MSDOS			; return with error
@@2:
		popall
		ret

ibuffseek	Endp

;{----------------------------------------------------------------------}
;{	obuffseek:							}
;{	  seek for destination buffer					}
;{----------------------------------------------------------------------}
obuffseek	Proc	Far

		pushall
		
		call	far ptr obufflush	; flush current buffer
		mov	ax,DGROUP
		mov	ds,ax
		mov	bx,outpfhand
		mov	ah,MOVEFILEPTR
		mov	al,1			; from current position
		Int	MSDOS			; return with error

		popall
		ret

obuffseek	Endp

;{----------------------------------------------------------------------}
;{	getchar:							}
;{	  get a character from dos in ax				}
;{----------------------------------------------------------------------}
getchar		Proc	Far

		jmp	far ptr getdoschar
getcharrtn	equ	$-2

getdoschar	Proc	Far

		push	bx
		mov	ah,UNFCHRIN
		Int	MSDOS
		xor	ah,ah
		cmp	al,0
		jne	@@1
		mov	bl,al
		Mov	ah,UNFCHRIN
		Int	MSDOS
		mov	ah,al
		mov	al,bl
		mov	bx,seg DGROUP
		mov	ds,bx
		and	al,hiandval
		or	al,loworval
@@1:
		pop	bx
		ret

getdoschar	Endp

getchar		Endp

;{----------------------------------------------------------------------}
;{	stripext:							}
;{	  strip off an extension of a filename				}
;{	  ax:bx = pointer to string					}
;{	  returns carry set on error					}
;{----------------------------------------------------------------------}
stripext	Proc	Far
		pushall

		call	far ptr strlen	; get string length
		mov	cx,ax		; maximum string length
		inc	cx		; make sure check first byte
		std
@@1:
		mov	al,'.'
		repne	scasb		; find a '.'
		stc
		jne	@@2
		inc	di		; back to .
		mov	al,0		; and kill rest of line
		stosb
		clc
@@2:
		cld

		popall
		ret

stripext	Endp

;{----------------------------------------------------------------------}
;{	stripfname:							}
;{	  strip off a filename from path				}
;{	  ax:bx = pointer to string					}
;{----------------------------------------------------------------------}
stripfname	Proc	Far

		pushall

		call	far ptr strlen	; get string length
		mov	cx,ax		; maximum string length
		inc	cx		; make sure check first byte
		std
@@1:
		mov	al,'\'
		mov	ah,':'
		cmp	ah,es:[di]	; see if a ':'
		je	@@3
		scasb			; find a '\'
		je	@@3
		loop	@@1
		stc
		jmp	@@4		; not found
@@2:
		inc	di
@@3:
		mov	al,0		; and kill rest of line
		stosb
		clc
@@4:
		cld

		popall
		ret

stripfname	Endp

;{----------------------------------------------------------------------}
;{	buffgetbyte:							}
;{	  get a byte from a disk buffer					}
;{	  al = returned value						}
;{----------------------------------------------------------------------}
buffgetbyte	Proc	Far

		pushall

		push	ax		; save high byte for return
		mov	bx,seg DGROUP
		mov	ds,bx
		mov	si,sbytebnum
		mov	ax,sendbytebuff
		cmp	si,ax
		jne	@@2
		push	ds
		mov	cx,1024		; max read
		mov	bx,seg DGROUP
		mov	ds,bx
		mov	bx,inpfhand
		lea	dx,sbytebuff
		mov	si,dx
		pop	ds
		mov	ah,READFILE
		Int	MSDOS
		jc	@@1
		add	ax,si
		cmp	ax,si
		jne	@@2
		mov	ax,sendbytebuff
		mov	sbytebnum,ax
		mov	ax,EEOF		; say end of file data
@@1:
		pop	bx		; dummy value
		stc
		jmp	@@3
@@2:
		mov	sendbytebuff,ax
		lodsb
		mov	sbytebnum,si
		pop	bx
		mov	ah,bh		; recover high byte
		clc
@@3:
		popall
		ret

buffgetbyte	Endp

;{----------------------------------------------------------------------}
;{	memstorebyte:							}
;{	  store byte in al into es:di					}
;{	  returns:							}
;{	   error if went past line					}
;{----------------------------------------------------------------------}
memstorebyte	Proc	Far

		push	di
		push	ds
		push	es
		mov	di,seg DGROUP
		mov	ds,di
		les	di,dword ptr outpdataptr

		inc	outpdatasize
		jne	@@1
		inc	outpdatasize+2
@@1:
		stosb
		cmp	di,0
		jne	@@2
		mov	di,es		; get segment
		add	di,1000h
		mov	es,di		; next 64k
		xor	di,di
@@2:
		clc
		mov	outpdataptr,di
		mov	outpdataptr+2,es
		pop	es
		pop	ds
		pop	di
		ret
		
memstorebyte	Endp

;{----------------------------------------------------------------------}
;{	buffstorebyte:							}
;{	  put a byte to the disk buffer					}
;{	  al = value to store						}
;{----------------------------------------------------------------------}
buffstorebyte	Proc	Far

		pushall

		mov	bx,seg DGROUP
		mov	ds,bx
		mov	es,bx
		mov	di,dbytebnum
		cmp	di,offset DGROUP:dbytebuff+1024
		jne	@@2
		push	ax
		push	ds
		mov	cx,1024		; max read
		mov	bx,seg DGROUP
		mov	ds,bx
		mov	bx,outpfhand
		lea	dx,dbytebuff
		mov	di,dx
		pop	ds
		mov	ah,WRITEFILE
		Int	MSDOS
		pop	ax
		jc	@@4
@@2:
		stosb
		mov	dbytebnum,di
		inc	outpdatasize
		jne	@@3
		inc	outpdatasize+2
@@3:
		clc
@@4:
		popall
		ret

buffstorebyte	Endp

;{----------------------------------------------------------------------}
;{	obufflush:							}
;{	  flush the output buffer					}
;{----------------------------------------------------------------------}
obufflush	Proc	Far

		pushall
		mov	cx,seg DGROUP
		mov	ds,cx			; set up segment
		mov	cx,dbytebnum		; get byte offset in buffer
		sub	cx,offset DGROUP:dbytebuff
		je	obfexit			; nothing to write
		lea	dx,dbytebuff
		mov	dbytebnum,dx
		mov	bx,outpfhand		; get file handle to write
		mov	ah,WRITEFILE		; write dah' file out
		Int	MSDOS
obfexit:
		popall
;
;
;
nobufflush	Proc	Far
		ret
nobufflush	Endp

obufflush	Endp

;{----------------------------------------------------------------------}
;{	memgetbyte:							}
;{	  get byte in al from inpdataptr				}
;{	  returns:							}
;{	   error if went past line					}
;{----------------------------------------------------------------------}
memgetbyte	Proc	Far

		push	si
		push	ds
		push	es
		mov	si,seg DGROUP
		mov	es,si
		mov	si,es:inpdataptr
		mov	ds,es:inpdataptr+2

		cmp	es:inpdatasize,0
		jne	@@1
		cmp	es:inpdatasize+2,0
		jne	@@1
		mov	ax,EEOF
		stc
		jmp	@@4
@@1:
		lodsb
		cmp	si,0
		jne	@@2
		mov	si,ds		; get segment
		add	si,1000h
		mov	ds,si		; next 64k
		xor	si,si
@@2:
		mov	es:inpdataptr,si
		mov	es:inpdataptr+2,ds
		dec	es:inpdatasize
		jne	@@3
		cmp	es:inpdatasize+2,0
		je	@@3
		dec	es:inpdatasize+2
@@3:
		clc
@@4:
		pop	es
		pop	ds
		pop	si		
		ret
		
memgetbyte	Endp

;{----------------------------------------------------------------------}
;{	hextobcd:							}
;{	  convert hexidecimal # to bcd					}
;{	  ax = number to convert					}
;{	  returns:							}
;{	   ax = converted #						}
;{----------------------------------------------------------------------}
hextobcd	Proc	Far

		push	bx
		push	cx
		push	dx
		push	bp
		push	di
		push	ds

		mov	dx,ax			; save # to be converted
		xor	bx,bx			; start off with zeroed value
		mov	ax,seg DGROUP
		mov	ds,ax
		lea	di,decvals-2		; load in divide #'s

		mov	cx,5			; # possibles
@@1:
		add	di,2			; next pointer
		cmp	dx,[di]			; see if time
		jae	@@2			; yep found starting divide #
		loop	@@1			; else keep trying
		jmp	@@5			; none found must be zero then
@@2:
		mov	bp,[di]			; get divide #
		add	di,2			; increment pointer
@@3:
		mov	ax,dx			; get # to divide by
		xor	dx,dx			; zero out remainder
		div	bp			; and divide by divisor
		shl	bx,1
		shl	bx,1
		shl	bx,1			; move last bcd # up
		shl	bx,1
		or	bl,al			; and put this one in low spot
@@4:
		loop	@@2			; and finish out bcd digits

@@5:
		mov	ax,bx			; put in return register
		pop	ds
		pop	di
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		ret

hextobcd	Endp

;{----------------------------------------------------------------------}
;{	bcdtodec:							}
;{	  convert bcd number to decimal ascii				}
;{	  ax:bx pointer to string storage				}
;{	  cx: number							}
;{----------------------------------------------------------------------}
bcdtodec	Proc	Far

		push	bx
		push	cx
		push	bp
		push	di
		push	es

		xor	bp,bp			; start flag
		mov	es,ax
		mov	di,bx
		mov	byte ptr es:[di],'0'
		mov	byte ptr es:[di+1],0
		jcxz	@@4
		mov	bx,cx
		mov	cx,4
@@1:
		rol	bx,1
		rol	bx,1
		rol	bx,1
		rol	bx,1
		mov	al,bl
		and	al,0fh
		cmp	bp,0
		jne	@@2
		cmp	al,0
		je	@@3
@@2:
		mov	bp,1
		add	al,'0'
		stosb
@@3:
		loop	@@1
		mov	al,0
		stosb
@@4:
		pop	es
		pop	di
		pop	bp
		pop	cx
		pop	bx
		ret
		
bcdtodec	Endp

;{----------------------------------------------------------------------}
;{	hextodec:							}
;{	  convert hex number to decimal ascii				}
;{	  ax:bx pointer to string storage				}
;{	  cx: number							}
;{----------------------------------------------------------------------}
hextodec	Proc	Far

		pushall

		mov	es,ax
		mov	di,bx
		mov	ax,seg DGROUP
		mov	ds,ax
		lea	bx,decvals-2
		mov	byte ptr es:[di],'0'	; start off with zero
		mov	byte ptr es:[di+1],0
		mov	dx,cx
		mov	cx,5
@@1:
		add	bx,2
		cmp	dx,[bx]
		jae	@@2
		loop	@@1
		jmp	@@5
@@2:
		mov	bp,[bx]
		add	bx,2
@@3:
		mov	ax,dx		; 2 clocks
		xor	dx,dx		; fucking ibm
		div	bp
		add	al,'0'
		stosb
@@4:
		loop	@@2
		xor	al,al
		stosb			; null terminated
@@5:
		popall
		ret

hextodec	Endp


;{----------------------------------------------------------------------}
;{	hextoasc:							}
;{	  convert hex number to hexidecimal ascii			}
;{	  ax:bx pointer to string storage				}
;{	  cx: number							}
;{----------------------------------------------------------------------}
hextoasc	Proc	Far

		pushall

		mov	si,seg DGROUP
		mov	ds,si
		mov	es,ax
		mov	di,bx
		mov	dx,cx
		mov	bp,4		; number of rotates
		mov	cx,4
		lea	bx,hexascii
		xor	si,si		; no first number yet
@@1:
		rol	dx,cl
		mov	ax,dx
		and	ax,0fh
		jne	@@2
		cmp	si,0
		je	@@3
@@2:
		mov	si,1
		xlat
		stosb
@@3:
		dec	bp
		jne	@@1
		cmp	si,0
		jne	@@4
		mov	al,'0'
		stosb
@@4:
		xor	al,al
		stosb			; null terminated

		popall
		ret

hextoasc	Endp


;{----------------------------------------------------------------------}
;{	settolower:							}
;{	  set switch data to lower case always				}
;{----------------------------------------------------------------------}
settolower	Proc	Far

		push	ax
		push	ds
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	hiandval,0ffh
		mov	loworval,20h
		pop	ds
		pop	ax
		ret

settolower	Endp


;{----------------------------------------------------------------------}
;{	settoupper:							}
;{	  set switch data to upper case always				}
;{----------------------------------------------------------------------}
settoupper	Proc	Far

		push	ax
		push	ds
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	hiandval,0dfh
		mov	loworval,0
		pop	ds
		pop	ax
		ret

settoupper	Endp

;{----------------------------------------------------------------------}
;{	checkswitches:							}
;{	  check if any or valid switches in command line		}
;{	  ax:bx = string in command line				}
;{	  cx:dx = valid switch pointers					}
;{	  bp = number of switches					} 
;{	  returns:							}
;{	    cf = 1 if error						}
;{	    zf = 0 if no switch flag					}
;{----------------------------------------------------------------------}
checkswitches	Proc	Far

		push	ax
		pushall

		mov	si,dx		; save dx for later
		mov	dx,seg DGROUP
		mov	ds,dx
		mov	dl,loworval
		mov	dh,hiandval

		mov	ds,ax		; set up segment
		mov	es,cx

		mov	al,[bx]		; get a character
		cmp	al,'-'		; a switch character
		je	@@1
		cmp	al,'/'		; how about this one
		stc			; say not switch /parsable/?
		jne	chswexit	; exit with ax != 0 flag set
@@1:
		cmp	byte ptr [bx+1],0	; now end of line
		jne	@@2
		stc			; switch flag is available
		jc	chswexit	; exit with error
@@2:
		inc	bx
		mov	al,[bx]		; get next character
		cmp	al,0		; see if end of line
		clc
		je	chswexit	; all finished
		
		or	al,dl
		and	al,dh
		mov	ah,1		; flag = true

		mov	cx,bp		; get number of switches to check
		mov	di,si		; and address in scasb index
		repne	scasb
		je	@@3
		mov	ah,al
		mov	al,'#'		; any numbers allowed
		mov	cx,bp
		mov	di,si
@@2a:
		repne	scasb
		jne	@@2b
		dec	di
		cmp	byte ptr es:[di+bp],0
		pushf
		inc	di
		popf
		jne	@@2a
		cmp	ah,'0'
		jb	@@2b
		cmp	ah,'9'
		jbe	@@3
@@2b:
		mov	al,'&'		; any other letters allowed
		mov	cx,bp
		mov	di,si
@@2c:
		repne	scasb
		jne	@@2d
		dec	di
		cmp	byte ptr es:[di+bp],0
		pushf
		inc	di
		popf
		jne	@@2c
		jmp	short @@3
@@2d:
		xor	ax,ax		; set zf = 1 switch avialable
		stc			; not valid switch
		jc	chswexit	; whoops not valid switch
@@3:
		dec	di
		mov	es:[di+bp],ah	; set switch as on
		jmp	@@2
chswexit:
		popall
		pop	ax
		ret

checkswitches	Endp

		assume	ds:nothing		
;{----------------------------------------------------------------------}
;{	parsecl:							}
;{	  parse the command line for next variable			}
;{	  returns:							}
;{	  ax:bx = command line string					}
;{	  cx = old terminating character				}
;{----------------------------------------------------------------------}
parsecl		Proc	Far
		
		push	dx
		push	bp
		push	si
		push	ds
		
		mov	ax,seg pspseg
		mov	ds,ax
		mov	bx,pspcurptr	; get current pointer
		mov	ax,pspseg	; get segment of psp
		mov	ds,ax
		mov	si,80h		; length of string
		xor	ch,ch
		mov	cl,[si]		; and get length
		add	cx,81h		; get to start of command line
		sub	cx,bx
		je	@@1
		jnc	@@2
@@1:
		mov	ax,EGENFAIL	; no more room
		stc
		jmp	pclexit
@@2:
		call	far ptr parseline ; parse a command out of line
		jc	pclexit
		mov	si,seg pspcurptr
		mov	ds,si
		mov	pspcurptr,dx	; save new pointer
		mov	cx,bp		; save old terminate character
		clc
pclexit:
		pop	ds
		pop	si
		pop	bp
		pop	dx
		ret
		
parsecl		Endp

		assume	ds:DGROUP
;{----------------------------------------------------------------------}
;{	SetOtherTerms:							}
;{	  Set Other Terminate Character SET				}
;{	  ax = number of characters					}
;{	  bx:cx = pointer to character set				}
;{----------------------------------------------------------------------}
SetOtherTerms	Proc	Far

		pushall

		mov	dx,seg DGROUP
		mov	ds,dx
		mov	notherterms,ax
		mov	word ptr otherterms,cx
		mov	word ptr otherterms+2,bx

		popall
		ret

SetOtherTerms	Endp

;{----------------------------------------------------------------------}
;{	parseline:							}
;{	  parse a command from a line					}
;{	  ax:bx = command line						}
;{	  cx = max characters to check					}
;{	  returns:							}
;{	  ax:bx line pointer						}
;{	  cx = new length value						}
;{	  dx = end of line pointer					}
;{	  bp = old terminate character					}
;{----------------------------------------------------------------------}
parseline	Proc	Far

		push	si
		push	di
		push	ds
		push	es
		mov	ds,ax
		mov	si,bx
		mov	bx,-1		; haven't found ptr yet
		xor	ax,ax
		xor	bp,bp
		jcxz	palifail
@@1:
		lodsb			; next byte ptr
		cmp	al,' '		; see if space
		je	endparm		; found end of parameter
		cmp	al,0dh		; see if carriage return
		je	endparm2
		cmp	al,0ah
		je	endparm		; or linefeed
		cmp	al,9		; tab is end of parameter
		je	endparm
		mov	di,seg DGROUP
		mov	es,di
		mov	di,es:notherterms ; get number of other terminators
		cmp	di,0
		je	@@1a		; no others to check
		les	di,es:otherterms ; get pointer
		repne	scasb
		je	endparm		; must have found one
@@1a:
		cmp	bx,-1		; see if start found
		jne	@@2		; yes so don't reload
		mov	bx,si		; get address
		dec	bx		; minus 1 for lodsb action
@@2:
		loop	@@1		; keep checkin
		inc	si		; next byte bypass
		cmp	bx,-1
		jne	endparm		; at end of rope
palifail:
		mov	ax,EGENFAIL	; no more room
		stc
		jmp	paliexit
endparm2:
		cmp	bx,-1
		jne	@@3		; if we got any characters yet
		or	bp,8000h	; say got end of line before parm.
endparm:
		cmp	bx,-1		; no pointer found yet
		je	@@2		; then try to find one
@@3:
		dec	cx		; for terminate character
		or	bp,ax		; save old terminate character
		mov	ax,ds		; and set data segment
		dec	si
		mov	byte ptr[si],0	; set end of string
		inc	si
		mov	dx,si		; and save for later
		clc
paliexit:
		pop	es
		pop	ds
		pop	di
		pop	si
		ret

parseline	Endp

;{----------------------------------------------------------------------}
;{	strcpy:								}
;{	  do a string copy from cx:dx to ax:bx				}
;{----------------------------------------------------------------------}
strcpy		Proc	Far

		pushall
		mov	es,ax
		mov	di,bx
		mov	ds,cx
		mov	si,dx
		jmp	near ptr strcat2
		
;{----------------------------------------------------------------------}
;{	strcat:								}
;{	  concats strings from cx:dx to ax:bx				}
;{----------------------------------------------------------------------}
strcat		Proc	Far

		pushall

		mov	ds,cx
		mov	si,dx

		call	far ptr strlen	; go get string length
strcat2:
		mov	cx,256		; max size string to move
@@1:
		lodsb
		stosb
		cmp	al,0
		je	@@2
		loop	@@1		
@@2:
		popall

		ret

strcat		Endp
strcpy		Endp

;{----------------------------------------------------------------------}
;{	strcmp:								}
;{	  compare 2 strings						}
;{	  ax:bx = string 1						}
;{	  cx:dx = string 2						}
;{	  returns:							}
;{	    ax = 0 then equal						}
;{	    ax = 1 source is greater than				}
;{	    ax = 2 source is less than					}
;{----------------------------------------------------------------------}
strcmp		Proc	Far

		push	cx
		push	si
		push	di
		push	ds
		push	es

		mov	ds,ax
		mov	si,bx

		call	far ptr strlen
		mov	es,cx
		mov	di,dx
		mov	cx,ax
		inc	cx
@@1:
		xor	ax,ax			; assume equal
		repe	cmpsb			; compare the pointers
		je	@@2
		mov	ax,1
		mov	cl,[si-1]		; get destination string
		cmp	cl,es:[di-1]
		ja	@@2
		mov	ax,2		
@@2:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	cx
		ret
		
strcmp		Endp

;{----------------------------------------------------------------------}
;{	strlen:								}
;{	  ax:bx = string to get length of				}
;{	  returns:							}
;{	    ax = strlen							}
;{	    es:di = end of string					}
;{----------------------------------------------------------------------}
strlen		Proc	Far
		push	cx

		mov	es,ax
		mov	di,bx
		mov	cx,256+1	; maximum string length + 1
		xor	al,al
		repne	scasb		; scan to end of string
		neg	cx
		mov	ax,256
		add	ax,cx

		dec	di
		pop	cx
		ret

strlen		Endp

;{----------------------------------------------------------------------}
;{	loadmem:							}
;{	  allocate memory and load in file				}
;{	    ax:bx = filename to load					}
;{	  returns:							}
;{	   ax = error number						}
;{	   bx = number of bytes read high				}
;{	   cx = number of bytes read low				}
;{	   es:di = segment/offset loaded to				}
;{----------------------------------------------------------------------}
loadmem		Proc	Far

		push	ds

		mov	ds,ax
		mov	dx,bx			; get to doses registers
		mov	ah,FSFIRST		; file search first
		mov	cx,ALLFILES		; all file attributes
		Int	MSDOS			; go through dos to find it

		jnc	@@2
		cmp	ax,12h			; see if file not found
		jne	@@1
		mov	ax,1
@@1:
		inc	ax
		neg	ax
		jmp	loadmemexit
@@2:
		mov	ah,GETDTA		; get disk xfer area
		Int	MSDOS			; through msdos

		mov	ax,es:[bx+26]		; DTA information on file
		mov	bx,es:[bx+28]		; and second size

		add	ax,15			; next 16 byte boundary

		longtopara ax,bx
		call	far ptr malloc		; go allocate memory for it

		xor	bx,bx
		mov	cx,ds
		pop	ds
		cmp	ax,0ff00h		; error if above this
		jb	loadfile		; bypass rest of routine

loadmemexit:
		pop	ds
		cmp	ax,0ff00h		; check for error
		cmc				; set carry for error
		ret

;{----------------------------------------------------------------------}
;{	loadfile:							}
;{	  loads in a file from current disk drive			}
;{	    ax:bx = segment to load to					}
;{	    cx:dx = filename to load					}
;{	  returns:							}
;{	    ax = error number						}
;{	    bx = number of bytes read high				}
;{	    cx = number of bytes read low				}
;{----------------------------------------------------------------------}

loadfile	Proc	Far

		mov	es,ax
		mov	di,bx

		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	ds,cx

		Mov	ah,OPENFILE
		xor	al,al		; just read acess
		Int	MSDOS		; open a file
		jnc	@@1
		neg	ax		; must have not found the file
		jmp	loadfileexit
@@1:
		pop	bx
		push	bx		; get and save where to write to
		cmp	di,0fff0h	; see if too far up segment
		jb	@@2
		mov	cx,4		; for paragraph shift
		mov	dx,di		; into temp register
		shr	dx,cl		; get paragraphs to add to bx
		add	bx,dx		; and add to segment
		and	di,0fh		; make di low enough now
@@2:
		mov	ds,bx		; set up data segment
		mov	dx,di		; get buffer to read to
		mov	cx,0fff0h	; max bytes to read
		sub	cx,di
		
		xor	bp,bp		; high number of bytes read
		xor	si,si		; low number of bytes read
		mov	bx,ax		; put file handle in right register
@@3:
		mov	ah,READFILE	; code for read file
		Int	MSDOS
		jnc	@@4
		neg	ax		; say nothing read
		jmp	@@7
@@4:
		add	si,ax		; add in bytes read
		jnb	@@5		; if next 64k
		inc	bp		; then increment
@@5:
		cmp	ax,cx		; see if number of bytes read
		jb	@@6		; is less than requested were done
		add	ax,dx		; add in offset in segment
		mov	dx,ds		; get data segment
		mov	cl,4		; and shift for bytes read
		shr	ax,cl		; get number of paragraphs read
		add	dx,ax		; add in to temp register
		mov	ds,dx		; and back to data segment
		xor	dx,dx		; start at zeroth byte
		mov	cx,0fff0h	; read 65520 max
		jmp	@@3		; keep going till finished
@@6:
		xor	ax,ax
@@7:
		push	ax
		mov	ah,CLOSEFILE	; close dah' file
		Int	MSDOS
		pop	ax
		mov	bx,bp
		mov	cx,si		; put in register return with
loadfileexit:
		cmp	ax,0ff00h	; check for error
		cmc			; reverse carry
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		ret

loadfile	EndP

loadmem		Endp

;{----------------------------------------------------------------------}
;{	savefile:							}
;{	  saves a file to current disk drive				}
;{	    ax:bx = segment to save from				}
;{	    cx:dx = filename to save to					}
;{	    bp = number of bytes to write high				}
;{	    si = number of bytes to write low				}
;{	  returns:							}
;{	    ax = error number						}
;{----------------------------------------------------------------------}

savefile	Proc	Far

		mov	es,ax
		mov	di,bx
		mov	ds,cx

		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	cx,NORMAL	; open file with normal attributes
		Mov	ah,CREATEFILE
		xor	al,al		; no bits set
		Int	MSDOS		; create the file
		jnc	@@1
		neg	ax		; error code
		jmp	savefileexit
@@1:
		pop	bx
		push	bx		; get and put where to write from
		cmp	di,0fff0h	; see if too high in segment
		jb	@@2
		mov	cx,4		; for paragraph shift
		mov	dx,di		; into temp register
		shr	dx,cl		; get paragraphs to add to bx
		add	bx,dx		; and add to segment
		and	di,0fh		; make di low enough now
@@2:
		mov	ds,bx
		mov	dx,di		; get buffer to write from
		mov	cx,0fff0h	; into cx of course
		sub	cx,di		; number of bytes to write at first
		mov	bx,ax		; put file handle in right register
		jmp	@@7
@@3:
		mov	ah,WRITEFILE	; code for write file
		Int	MSDOS		; through MsDos
		jnc	@@4
		neg	ax		; some write error
		jmp	@@8
@@4:
		cmp	ax,cx
		je	@@5
		mov	ax,EDISKFULL	; return with disk is full
		stc
		jmp	@@8
@@5:
		sub	si,ax		; number of bytes written
		jnb	@@6
		dec	bp		; next 64k block or so
@@6:
		add	ax,dx
		mov	dx,ds		; get current paragraphs
		mov	cl,4
		shr	ax,cl		; get number of paragraphs written
		add	dx,ax
		mov	ds,dx
		xor	dx,dx
		mov	cx,0fff0h	; write 65520 max
@@7:
		cmp	bp,0		; is this zero
		jne	@@3
		cmp	cx,si		; is cx less than last bytes to write
		jb	@@3
		mov	cx,si		; get number of bytes to write
		cmp	cx,0
		jne	@@3		; end of write
		xor	ax,ax
@@8:
		push	ax
		mov	ah,CLOSEFILE	; close dah' file
		Int	MSDOS
		pop	ax
savefileexit:
		cmp	ax,0ff00h	; check for error
		cmc
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		ret

savefile	EndP

;{----------------------------------------------------------------------}
;{	WriteFileL:							}
;{	  write number of bytes to open file				}
;{	  bx = file handle						}
;{	  cx:dx = buffer area						}
;{	  bp:si = size to write						}
;{----------------------------------------------------------------------}
writefilel	Proc	Far

		pushall
		
		mov	ax,cx		; set up segment to write from

		cmp	dx,0fff0h	; see if too high in segment
		jb	@@1
		mov	cx,4		; for paragraph shift
		mov	di,dx		; into temp register
		shr	di,cl		; get paragraphs to add to ax
		add	ax,di		; and add to segment
		and	dx,0fh		; make dx low enough now
@@1:
		mov	ds,cx
		mov	cx,0fff0h	; into cx of course
		sub	cx,dx		; number of bytes to write at first
		jmp	@@6
@@2:
		mov	ah,WRITEFILE	; code for write file
		Int	MSDOS		; through MsDos
		jnc	@@3
		neg	ax		; some write error
		jmp	@@7
@@3:
		cmp	ax,cx
		je	@@4
		mov	ax,EDISKFULL	; return with disk is full
		stc
		jmp	@@7
@@4:
		sub	si,ax		; number of bytes written
		jnb	@@5
		dec	bp		; next 64k block or so
@@5:
		add	ax,dx
		mov	dx,ds		; get current paragraphs
		mov	cl,4
		shr	ax,cl		; get number of paragraphs written
		add	dx,ax
		mov	ds,dx
		xor	dx,dx
		mov	cx,0fff0h	; write 65520 max
@@6:
		cmp	bp,0		; is this zero
		jne	@@2
		cmp	cx,si		; is cx less than last bytes to write
		jb	@@2
		mov	cx,si		; get number of bytes to write
		cmp	cx,0
		jne	@@2		; end of write
		xor	ax,ax
@@7:
		popall
		ret
writefilel	endp

;{----------------------------------------------------------------------}
;{	ReadFileL:							}
;{	  read number of bytes from open file				}
;{	  bx = file handle						}
;{	  cx:dx = buffer area						}
;{	  bp:si = size to read						}
;{----------------------------------------------------------------------}
readfilel	Proc	Far

		pushall
		
		mov	ax,cx		; set up segment to write from

		cmp	dx,0fff0h	; see if too high in segment
		jb	@@1
		mov	cx,4		; for paragraph shift
		mov	di,dx		; into temp register
		shr	di,cl		; get paragraphs to add to ax
		add	ax,di		; and add to segment
		and	dx,0fh		; make dx low enough now
@@1:
		mov	ds,cx
		mov	cx,0fff0h	; into cx of course
		sub	cx,dx		; number of bytes to write at first
		jmp	@@6
@@2:
		mov	ah,READFILE	; code for read file
		Int	MSDOS		; through MsDos
		jnc	@@3
		neg	ax		; some write error
		jmp	@@7
@@3:
		cmp	ax,cx
		je	@@4		; not end of file
		mov	ax,EEOF		; end of file error
		stc
		jmp	@@7
@@4:
		sub	si,ax		; number of bytes read
		jnb	@@5
		dec	bp		; next 64k block or so
@@5:
		add	ax,dx
		mov	dx,ds		; get current paragraphs
		mov	cl,4
		shr	ax,cl		; get number of paragraphs written
		add	dx,ax
		mov	ds,dx
		xor	dx,dx
		mov	cx,0fff0h	; write 65520 max
@@6:
		cmp	bp,0		; is this zero
		jne	@@2
		cmp	cx,si		; is cx less than last bytes to write
		jb	@@2
		mov	cx,si		; get number of bytes to write
		cmp	cx,0
		jne	@@2		; end of write
		xor	ax,ax
@@7:
		popall
		ret

readfilel	endp

;{----------------------------------------------------------------------}
;{ Function:	atoi							}
;{ Description:	convert a decimal ascii number.				}
;{ Parameters:	ax:bx = pointer to decimal ascii			}
;{ returns:	cf = invalid number					}
;{		dx:ax = converted number				}
;{----------------------------------------------------------------------}
atoi		proc	far

		push	bx
		push	cx
		push	bp
		push	si
		push	di
		push	ds

		mov	ds,ax
		mov	si,bx

		xor	bx,bx
		xor	dx,dx
		xor	ah,ah
		mov	cx,255
@@ConvertLoop:
		lodsb
		or	al,al
		je	@@AllDone
		cmp	al,'0'
		jb	@@Error
		cmp	al,'9'
		ja	@@Error
		sub	al,'0'
		add	bx,bx
		adc	dx,dx		; * 2
		mov	bp,bx
		mov	di,dx
		add	bx,bx		; * 4
		adc	dx,dx
		add	bx,bx		; * 8
		adc	dx,dx
		add	bx,bp
		adc	dx,di
		add	bx,ax
		adc	dx,0
		loop	@@ConvertLoop

@@AllDone:
		mov	ax,bx

		clc
		jmp	@@Exit

@@Error:
		stc
@@Exit:

		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	cx
		pop	bx
		
		ret


atoi		Endp


dos		Ends

		end

