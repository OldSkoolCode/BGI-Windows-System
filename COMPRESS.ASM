; $Header$
		.xlist
;{----------------------------------------------------------------------}
;{	msdos compression library routines				}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by kenneth l. hurley					}
;{	started	2-28-1989						}
;{	written with turbo assembler ver 1.0				}
;{----------------------------------------------------------------------}

; $Log$
		locals

		include	compress.inc

DGROUP		GROUP	_DATA

_DATA		Segment Public 'DATA'

		even

grcofnum	dw	0			; current file number
cfileattr	dw	0			; create file attribute
hashptr		dw	?,?
prefixcode	dw	?
freecode	dw	?
maxcode		dw	?
nbits		dw	?

GRCOthead	dw	?,?,?		;\ temporary header
firstfilelen	dw	?,?		;/ don't seperate these
actfileptr	dw	?,?
k		db	?
finchar		db	?
bitoffset	dw	0
lastbits	dw	0
didcompmalloc	dw	0
saveftype	dw	0
curcode		dw	?
oldcode		dw	?
incode		dw	?
stackcount	dw	0
masks		dw	1ffh,3ffh,7ffh,0fffh
compression	dw	3		; analyze first, and compression on

stackov		db	"Lemple-Ziv Compression Stack Overflow.",cr,lf,"$",0

_DATA		Ends

ccompress	Segment Public 'CODE'

		assume	cs:ccompress,ds:DGROUP,ss:nothing,es:DGROUP

;{----------------------------------------------------------------------}
;{	CreateGRCO:							}
;{	  create a grace compression file				}
;{	  ax:bx = filename to use					}
;{	  returns filehandle in ax					}
;{----------------------------------------------------------------------}
CreateGRCO	Proc	Far

		pushall

		mov	cx,DGROUP
		mov	ds,cx
		mov	cx,cfileattr		; get create file attributes
		mov	ds,ax
		mov	dx,bx			; set up for msdos
		Mov	ah,CreateFile		; create file code through dos
		Int	MsDos
		jc	crgrcoexit
		mov	bx,ax			; save file handle in bx
		mov	ax,DGROUP
		mov	es,ax
		mov	ds,ax
		lea	di,GRCOtHead		; temporary buffer
		mov	dx,di
		mov	ax,"RG"			; GR actually
		stosw
		mov	ax,"OC"			; CO acutally
		stosw
		mov	ax,1			; lemple-ziv compress
		stosw				; store it
		mov	cx,6			; number of bytes to write
		mov	ah,WriteFile
		Int	MsDos			; write it
		mov	ax,bx			; replace handle into ax
crgrcoexit:
		popall
		ret

CreateGRCO	Endp

;{----------------------------------------------------------------------}
;{	Countbytes:							}
;{	  count bytes coming through as output 				}
;{----------------------------------------------------------------------}
countbytes	Proc	Far

		pushall

		mov	bx,DGROUP
		mov	ds,bx
		inc	outpdatasize
		jne	@@1
		inc	outpdatasize+2
@@1:		
		popall
		ret

countbytes	Endp

;{----------------------------------------------------------------------}
;{	SeekGRCOFile							}
;{	  seek to a file number						}
;{	  ax = file number of file					}
;{	  bx = old file number						}
;{	  cx = file handle						}
;{----------------------------------------------------------------------}
SeekGRCOFile	Proc	Far

		pushall

		xchg	bx,cx
		mov	dx,seg DGROUP
		mov	ds,dx			; set up our segment
		cmp	ax,cx			; see where at in relation
		je	@@3			; if equal already there
		ja	@@1			; if above no need to reseek
		push	ax			; go back to beginning
		mov	ah,MoveFileptr
		xor	al,al			; from beginning
		xor	cx,cx
		mov	dx,6			; bypass head info
		Int	MsDos			; and do it
		pop	ax
		jc	@@3			; whoops have to exit
		mov	cx,0
		mov	actfileptr,6
		mov	actfileptr+2,0
@@1:
		mov	bp,ax
		sub	bp,cx			; get number of files to bypass
@@2:
		cmp	bp,0			; finished
		je	@@3			; yes then exit
		mov	ah,ReadFile		; read in
		mov	cx,4			; 4 bytes
		lea	dx,FirstFileLen		; where to read to
		Int	MsDos			; to get file length
		jc	@@2			; exit on error
		mov	cx,firstfilelen+2
		mov	dx,firstfilelen		; get length of file
		and	cx,0ffh			; mask off high byte
		add	actfileptr,dx
		adc	actfileptr+2,cx
		add	actfileptr,4
		adc	actfileptr+2,0
		mov	ah,MoveFilePtr
		mov	al,1			; from current position
		Int	MsDos			; and do it
		jc	@@3			; exit on error
		dec	bp			; keep going
		jmp	@@2
@@3:
		popall
		ret

SeekGRCOFile	Endp

;{----------------------------------------------------------------------}
;{	SaveGRCOFile:							}
;{	  save a file into GRace COmpression file			}
;{	  ax = filetype							}
;{	  bx = handle of file output					}
;{	  cx:dx = input data pointer
;{	  bp:si = length of data					}
;{----------------------------------------------------------------------}
SaveGRCOFile	Proc	Far

		pushall

		push	bp
		push	si
		mov	di,DGROUP
		mov	ds,di
		inc	grcofnum		; next file pointer
		mov	outpdatasize,0
		mov	outpdatasize+2,0
		mov	saveftype,ax		; save temporarily
		mov	outpfhand,bx
		mov	ax,cx
		mov	bx,dx
		call	far ptr setsrcasmemory
		cmp	saveftype,FtypePix
		jne	@@1
		test	displayScr.scrflags,4	; see if in planar mode
		jne	@@1
		mov	ax,seg DGROUP
		mov	word ptr inpdatartn+2,ax
		lea	ax,rawpixgetbyte
		mov	word ptr inpdatartn,ax
@@1:
		mov	inpdatasize,si
		mov	inpdatasize+2,bp	; save input data size
		mov	ax,sendbytebuff
		mov	sbytebnum,ax
		call	far ptr setdestasmemory	; ptr doesn't matter
		mov	ax,seg DGROUP
		mov	word ptr outpdatartn+2,ax
		lea	bx,countbytes
		mov	word ptr outpdatartn,bx	; set up pointer to routine
		mov	dmemory,FALSE
		mov	ax,compression
		and	ax,3			; lower 2 bits determine
		cmp	ax,3			; compression wanted and
		jne	@@2			; if to analyze first
		test	saveFtype,80h		; no compression wanted
		jne	@@3
		call	far ptr LZCompress	; see what size it is
		jnc	@@2
    		pop	si
		pop	bp
 		jmp	sagrpaexit
@@2:
		mov	ax,outpfhand
		call	far ptr setdestasdisk
		cmp	compression,0		; see if want compression
		je	@@3
		cmp	outpdatasize+2,bp
		jb	@@4
		jne	@@3			; means is above
		cmp	outpdatasize,si		; see if size < bp:si
		jb	@@4			; if below do lemple-ziv then
@@3:
		mov	outpdatasize,si
		mov	outpdatasize+2,bp	; save outpdatasize
		mov	ax,saveftype
		or	al,80h			; no compression on
		mov	byte ptr outpdatasize+3,al
		mov	bx,outpfhand		; get handle
		push	cx
		push	dx
		mov	cx,4			; number of bytes to write
		lea	dx,outpdatasize		; get address of bytes
		Mov	ah,WriteFile
		Int	MsDos			; and write to dah file
		pop	dx
		pop	cx
		pop	si
		pop	bp			; recover length
		jc	sagrpaexit		; and exit if error
		call	far ptr WritefileL	; else write out long words
		jmp	sagrpaexit		; maybe even an error?
@@4:
		mov	ax,saveftype
		mov	byte ptr outpdatasize+3,al	; set up file type
		mov	bx,outpfhand		; get filehandle
		mov	cx,4			; number of bytes to write
		lea	dx,outpdatasize		; get pointer to 4 bytes
		mov	ah,WriteFile		; and write these out
		Int	MsDos
		pop	si
		pop	bp			; recover length
		jc	sagrpaexit		; if error from write exit
		mov	di,DGROUP
		mov	ds,di			; make sure segment still set
		mov	inpdatasize,si
		mov	inpdatasize+2,bp	; save input data size
		mov	cx,bp
		mov	dx,si
		neg	dx			; negate low
		adc	cx,0			; for upper negation
		neg	cx			; and upper byte also
		lea	di,inpseekrtn
		call	dword ptr [di]
		mov	ax,sendbytebuff
		mov	sbytebnum,ax		; zero out buffer
		call	far ptr LZCompress	; go compress it to a file
sagrpaexit:
		popall
		ret

SaveGRCOFile	Endp

;{----------------------------------------------------------------------}
;{	OpenGRCOFile:							}
;{	  ax:bx = filename to open					}
;{	  open up a grace compression file for loading			}
;{	    returns:							}
;{	      ax set to error number or file handle			}
;{	      bx = status bits of file					}
;{----------------------------------------------------------------------}
OpenGRCOFile	Proc	Far

		push	cx
		push	dx
		push	bp
		push	ds

		mov	ds,ax
		mov	dx,bx
		mov	ah,OpenFile
		mov	al,02			; R/W access
		Int	MsDos			; go open the file
		jc	@@1
		mov	bp,ax			; save file handle
		mov	bx,ax			; move file handle
		mov	ax,seg DGROUP
		mov	ds,ax
		lea	dx,GRCOthead
		mov	cx,6			; # Header bytes
		mov	ah,ReadFile
		Int	MsDos
		jc	@@1
		mov	ax,EFORINV		; invalid format
		cmp	GRCOthead,"RG"		; is first word correct
		stc
		jne	@@1			; nope not GRCO file
		cmp	GRCOthead+2,"OC"	; and second
		stc
		jne	@@1			; second one not correct
		mov	bx,GRCOthead+4		; else get status bits
		mov	actfileptr,6
		mov	actfileptr+2,0		; say at 10 offset
		clc
		mov	ax,bp
		mov	grcofnum,0		; at first file
@@1:
		pop	ds
		pop	bp
		pop	dx
		pop	cx
		ret

OpenGRCOFile	EndP

;{----------------------------------------------------------------------}
;{	LoadGRCOFile:							}
;{	  load in a grace compression file				}
;{	  File must be opened first					}
;{	  ax = file handle of from OpenGRCOFile				}
;{	  bx:cx address of load buffer					}
;{	  returns:							}
;{	    ax = error number or filetype				}
;{	    updates firstfilelen with next in line			}
;{----------------------------------------------------------------------}
LoadGRCOFile	Proc	Far

		pushall

		mov	di,ax
		push	bx
		push	cx
		call	far ptr setsrcasdisk	; set up source as disk		
		mov	ax,bx
		mov	bx,cx
		call	far ptr setdestasmemory
		mov	ah,MoveFilePtr
		mov	al,1
		mov	bx,di
		xor	cx,cx			; get current file position
		xor	dx,dx
		Int	MsDos
		mov	cx,seg DGROUP
		mov	ds,cx
		mov	actfileptr,ax		; save current file pointer
		mov	actfileptr+2,dx
		lea	dx,firstfilelen		; get file length address
		mov	cx,4
		mov	bx,di
		mov	ah,ReadFile		; could be end of file
		Int	MsDos			; get file length
		pop	cx
		pop	bx
		jnc	@@1			; exit on error
		jmp	lgrfexit
@@1:
		cmp	ax,4			; see if read ok
		je	@@2
		mov	ax,EEOF
		stc	
		jmp	lgrfexit
@@2:
		mov	al,byte ptr firstfilelen+3
		mov	ah,al
		test	displayScr.scrflags,4	; see if in planar mode
		je	@@2a0			; yep
		xor	al,40h			; else reverse fast compress bit
@@2a0:
		and	ah,3fh
		cmp	ah,FtypePix		; picture type
		jne	@@2a
		test	al,40h			; fast compression
		jne	@@2a
		mov	ax,seg DGROUP
		mov	word ptr outpdatartn+2,ax
		lea	ax,rawpixstorebyte
		mov	word ptr outpdatartn,ax
		mov	dmemory,FALSE
@@2a:
		test	compression,1		; see if want to uncompress
		je	@@3
		test	byte ptr firstfilelen+3,80h	; see if compressed
		jne	@@3			; nope so no compression
		call	far ptr LZDeCompress	; decompress the file
		mov	bx,sendbytebuff
		mov	sbytebnum,bx		; reset input buffer
		mov	cx,firstfilelen+2
		mov	dx,firstfilelen
		and	cx,0ffh			; high doesn't count is filetype
		add	dx,4
		adc	cx,0			; for file length
		add	dx,actfileptr
		adc	cx,actfileptr+2
		mov	ah,MoveFilePtr		; move file pointer to there
		xor	al,al			; from beginning
		mov	bx,inpfhand		; the input file handle
		Int	MsDos
		jnc	@@2b
		cmp	ax,EEOF
		stc
		jne	lgrfexit
@@2b:
		mov	al,byte ptr firstfilelen+3
		and	ax,7fh			; grab file type
		clc
		jmp	lgrfexit
@@3:
		mov	dx,cx			; offset
		mov	cx,bx			; and segment
		mov	bx,di			; save file handle
		mov	si,firstfilelen		; get length to read
		mov	bp,firstfilelen+2
		and	bp,0ffh			; mask out filetype
		mov	bx,inpfhand		; filehandle
		call	far ptr ReadFileL	; read in long file
		jc	lgrfexit
		mov	outpdatasize,si
		mov	outpdatasize+2,bp
		mov	al,byte ptr firstfilelen+3
		and	ax,7fh			; grab file type
		clc
lgrfexit:
		popall
		ret

LoadGRCOFile	Endp

;{----------------------------------------------------------------------}
;{	LZCompress:							}
;{	  do lemple-ziv compression					}
;{	  inpfhand = file handle if need be -1 if none			}
;{----------------------------------------------------------------------}
LZCompress	Proc	Far

		pushall				; save all the registers

		mov	ax,DGROUP
		mov	ds,ax			; set up data segment
		mov	es,ax
		mov	bitoffset,0
		mov	lastbits,0
		mov	didcompmalloc,0
		cmp	hashptr+2,0		; see if empty
		jne	@@1
		cmp	hashptr,0
		jne	@@1
		mov	didcompmalloc,1
		mov	ax,500h			; size of buffer needed
		call	far ptr malloc		; call get memory
		jnc	@@0
		jmp	@@9			; exit on error
@@0:
		mov	hashptr+2,ax		; save segment of buffer
		xor	ax,ax			; and start at zeroth byte
		mov	hashptr,ax		; for offset in segment
@@1:
		call	near ptr inittable	; Initialize the table and some vars
		mov	ax,clear		; Write a clear code
		call	near ptr writecode
		lea	di,inpdatartn
		call	dword ptr [di]		; get input from some where
@@2:
		xor	ah,ah			; Turn char into code
@@3:
		mov	prefixcode,ax		; Set prefix code
		lea	di,inpdatartn
		call	dword ptr [di]		; call read a character into al
		jnc	@@3a
		cmp	ax,EEOF			; Carry means eof
		jne	@@7			; some error then
		jmp	@@5
@@3a:
		mov	k,al			; Save char in k
		mov	bx,prefixcode		; Get prefix code
		call	near ptr lookupcode	; See if this pair in table
		jnc	@@3			; nc means yes, new code in ax
		call	near ptr addcode	; Add pair to table
		push	bx			; Save new code
		mov	ax,prefixcode		; Write old prefix code
		call	near ptr writecode
		pop	bx
		mov	al,k			; Get last char
		cmp	bx,maxcode		; Exceed code size?
		jl	@@2			; less means no
		cmp	nbits,12		; Currently less than 12 bits?
		jl	@@4			; yes
		mov	ax,clear		; Write a clear code
		call	near ptr writecode
		call	near ptr inittable	; Reinit table
		mov	al,k			; get last char
		jmp	@@2			; Start over
@@4:
		inc	nbits			; Increase number of bits
		shl	maxcode,1		; Double max code size
		jmp	@@2			; Get next char
@@5:
 		mov	ax,prefixcode		; Write last code
		call	near ptr writecode
		mov	ax,eof			; Write eof code
		call	near ptr writecode
		mov	cx,bitoffset		; Make sure buffer is flushed to file
		and	cx,7
		jcxz	@@6
		mov	ax,lastbits		; get last byte to output
		lea	si,outpdatartn
		call	dword ptr [si]
@@6:
		lea	si,outpflushrtn
		call	dword ptr [si]
		clc
@@7:
		pushf
		cmp	didcompmalloc,0
		je	@@8
		push	ax
		mov	ax,hashptr+2
		call	far ptr mfree		; free up memory
		mov	hashptr,0
		mov	hashptr+2,0
		pop	ax
@@8:
		popf
@@9:
		popall				; recover registers
		ret

LZCompress	endp


;{----------------------------------------------------------------------}
;{	inittable:							}
;{	  initialize tables for compression				}
;{----------------------------------------------------------------------}
inittable	proc	near

		mov	nbits,9			; Set code size to 9
		mov	maxcode,512		; Set max code to 512
		push	es			; Save seg reg
		mov	es,hashptr+2		; Address hash table
		mov	ax,-1			; Unused flag
		mov	cx,640			; Clear first 256 entries
		mov	di,hashptr		; Point to first entry
		rep	stosw			; Clear it out
		pop	es			; Restore seg reg
		mov	freecode,firstfree	; Set next code to use
		ret				; done

inittable	endp


;{----------------------------------------------------------------------}
;{	writecode:							}
;{	  write code in ax to output buffer				}
;{----------------------------------------------------------------------}
writecode	proc	near

		lea	si,outpdatartn
		mov	cx,bitoffset		; Get bit offset
		mov	bp,nbits		; Adjust bit offset by code size
		add	bitoffset,bp
		and	cx,7			; get remainder in cx
		add	bp,cx			; get to ending bit
		mov	bx,-1
		rol	ax,cl
		shl	bx,cl
		mov	dx,ax
		and	ax,bx
		not	bx
		and	dx,bx
		and	bx,lastbits
 		or	ax,bx			; Grab previous bits
		call	dword ptr [si]
		xchg	ah,al
		cmp	bp,16			; see if over limit
		jb	@@1
		add	bitoffset,8		; we just zapped one more byte
		call	dword ptr [si]
		mov	ax,dx
@@1:		
		mov	lastbits,ax
		ret

writecode	endp

;{----------------------------------------------------------------------}
;{	lookupcode:							}
;{	   in hash table return no carry if found			}
;{----------------------------------------------------------------------}
lookupcode	proc	near

		push	ds			; Save seg reg
		mov	bp,hashptr		; get first pointer
		mov	ds,hashptr+2		; point to hash table
		mov	si,bx			; si = bx * 5 (5 byte hash entries)
		shl	si,1			; si = bx * 2 * 2 + bx
		shl	si,1
		add	si,bx
		add	si,bp			; starting offset also
		mov	di,0			; flag
		cmp	[si].first,-1		; Has this code been used?
		je	@@4			; equal means no
		inc	di			; set flag
		mov	bx,[si].first		; Get first entry
@@2:
		mov	si,bx			; si = bx * 5 (5 byte hash entries)
		shl	si,1			; si = bx * 2 * 2 + bx
		shl	si,1
		add	si,bx
		add	si,bp			; offset add in
		cmp	[si].char,al		; is char the same?
		jne	@@3			; ne means no
		clc				; success
		mov	ax,bx			; put found code in ax
		pop	ds			; restore seg reg
		ret				; done
@@3:
		cmp	[si].next,-1		; More left with this prefix?
		je	@@4			; equal means no
		mov	bx,[si].next		; get next code
		jmp	@@2			; try again
@@4:
		stc				; not found
		pop	ds			; restore seg reg
		ret				; done
lookupcode	endp

;{----------------------------------------------------------------------}
;{	addcode:							}
;{	  add in a code into the hash table				}
;{----------------------------------------------------------------------}
addcode		proc	near

		mov	bx,freecode		; Get code to use
		push	ds			; point to hash table
		mov	bp,hashptr
		mov	ds,hashptr+2
		cmp	di,0			; First use of this prefix?
		je	@@1			; equal means yes
		mov	[si].next,bx		; point last use to new entry
		jmp	@@2
@@1:	
		mov	[si].first,bx		; Point first use to new entry
@@2:	
		cmp	bx,maxmax		; Have we reached code limit?
		je	@@3			; equal means yes, just return
		mov	si,bx			; si = bx * 5 (5 byte hash entries)
		shl	si,1			; si = bx * 2 * 2 + bx
		shl	si,1
		add	si,bx
		add	si,bp			; next pointer
		mov	[si].first,-1		; initialize pointers
		mov	[si].next,-1
		mov	[si].char,al		; save suffix char
		inc	es:freecode		; adjust next code
@@3:	
		pop	ds			; restore seg reg
		ret
addcode		endp

;{----------------------------------------------------------------------}
;{	LZDeCompress:							}
;{	  decompress a block						}
;{----------------------------------------------------------------------}
LZDeCompress	Proc	Far

		pushall
		mov	ax,DGROUP
		mov	ds,ax

		mov	nbits,9
		mov	maxcode,512
		mov	freecode,firstfree
		mov	bitoffset,0
		mov	lastbits,0
		mov	stackcount,0		; nothing on stack yet
		mov	didcompmalloc,0
		cmp	hashptr+2,0		; see if empty
		jne	@@1
		cmp	hashptr,0
		jne	@@1
		mov	didcompmalloc,1
		mov	ax,300h			; size of buffer needed
		call	far ptr malloc		; call get memory
		jnc	@@0
		jmp	lzdcexit		; exit on error
@@0:
		mov	hashptr+2,ax		; save segment of buffer
		xor	ax,ax			; and start at zeroth byte
		mov	hashptr,ax		; for offset in segment
@@1:
		call	near ptr readcode	; Get a code
		cmp	ax,eof			; End of file?
		jne	@@2			; no
		lea	si,outpflushrtn
		call	dword ptr [si]
		clc
		jmp	lzdcexit
@@2:
		cmp	ax,clear		; Clear code?
		jne	@@3			; no
		mov	nbits,9			; Initialize variables
		mov	maxcode,512
		mov	freecode,firstfree
		call	near ptr readcode	; Read next code
		mov	curcode,ax		; Initialize variables
		mov	oldcode,ax
		mov	k,al
		mov	finchar,al
		mov	al,k
		lea	si,outpdatartn
		call	dword ptr [si]
		jmp	@@1			; Get next code
@@3:
		mov	curcode,ax		; Save new code
		mov	incode,ax
		mov	es,hashptr+2		; Point to hash table
		cmp	ax,freecode		; Code in table? (k<w>k<w>k)
		jl	@@4			; yes
		mov	ax,oldcode		; get previous code
		mov	curcode,ax		; make current
		mov	al,finchar		; get old last char
		push	ax			; push it
		inc	stackcount
		mov	ax,sp
		cmp	ax,0
		jge	@@4
		mov	ax,3
		int	10h
		lea	dx,stackov
		mov	ds,dx
		mov	ah,9
		Int	21h
		jmp	far ptr _exittext
@@4:
		cmp	curcode,255		; Code or character?
		jle	@@5			; Char
		mov	bx,curcode		; Convert code to address
		mov	bp,bx			;bx = bx * 3 (3 byte entries)
		shl	bx,1			;bp = bx
		add	bx,bp			;bx = bx * 2 + bp
		add	bx,hashptr
		mov	al,es:2[bx]		; Get suffix char
		push	ax			; push it
		inc	stackcount
		mov	ax,es:[bx]		; Get prefix code
		mov	curcode,ax		; Save it
		jmp	@@4			; Translate again
@@5:
		push	ds			; Restore seg reg
		pop	es
		mov	ax,curcode		; Get code
		mov	finchar,al		; Save as final, k
		mov	k,al
		push	ax			; Push it
		inc	stackcount
		mov	cx,stackcount		; Pop stack
		jcxz	@@7			; If anything there
		lea	si,outpdatartn
@@6:
		pop	ax
		call	dword ptr [si]
		loop	@@6
@@7:
		mov	stackcount,cx		; Clear count on stack
		call	near ptr daddcode	; Add new code to table
		mov	ax,incode		; Save input code
		mov	oldcode,ax
		mov	bx,freecode		; Hit table limit?
		cmp	bx,maxcode
		jl	@@8			; Less means no
		cmp	nbits,12		; Still within twelve bits?
		je	@@8			; no (next code should be clear)
		inc	nbits			; Increase code size
		shl	maxcode,1		; Double max code
@@8:
		jmp	@@1			; Get next code
lzdcexit:
		pushf
		cmp	didcompmalloc,0
		je	@@9
		push	ax
		mov	ax,hashptr+2
		call	far ptr mfree		; free up memory
		mov	hashptr,0
		mov	hashptr+2,0
		pop	ax
@@9:
		popf
		popall
		ret

LZDeCompress	endp	

;{----------------------------------------------------------------------}
;{	readcode:							}
;{	  read in code from buffer and return in ax			}
;{----------------------------------------------------------------------}
readcode	proc	near

		mov	cx,bitoffset		; Get bit offset
		mov	bp,nbits		; Adjust by code size
		add	bitoffset,bp		; adjust bit size
		and	cx,7
		add	bp,cx
		lea	si,inpdatartn		; get input data routine
		call	dword ptr [si]		; get a byte in al
		xor	ah,ah
		cmp	cx,0
		jne	@@1
		mov	lastbits,ax
		call	dword ptr [si]
@@1:
		mov	bx,0ffh			; mask value
		mov	dx,ax
		cmp	bp,16
		jbe	@@2
		add	bitoffset,8
		mov	ah,al
		call	dword ptr [si]		; next byte also
		mov	dx,ax
		xchg	ah,al
@@2:
		xchg	ah,al
		shr	bx,cl
		mov	bp,lastbits
		ror	bp,cl
		ror	ax,cl
		and	bp,bx
		not	bx
		and	ax,bx
		or	ax,bp
		mov	bx,nbits		; mask off unwanted bits
		sub	bx,9
		shl	bx,1
		and	ax,[bx].masks
		mov	lastbits,dx
		ret

readcode	endp

;{----------------------------------------------------------------------}
;{	daddcode:							}
;{	  decompression add in code to hash segment			}
;{----------------------------------------------------------------------}
daddcode	proc	near

		mov	bx,freecode		; Get new code
		mov	bp,bx			; bx = bx * 3 (3 byte entries)
		shl	bx,1			; bp = bx
		add	bx,bp			; bx = bx * 2 + bp
		push	es			; point to hash table
		mov	es,hashptr+2
		add	bx,hashptr		; go hash pointer
		mov	al,k			; get suffix char
		mov	es:[bx].dchar,al	; save it
		mov	ax,oldcode		; get prefix code
		mov	es:[bx].dnext,ax	; save it
		pop	es
		inc	freecode		; set next code
		ret

daddcode	endp

ccompress	Ends

		end




