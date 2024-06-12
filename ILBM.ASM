; $Header$

;{----------------------------------------------------------------------}
;{	MSDOS ILBM library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	Written by Kenneth L. Hurley					}
;{	Started	2-28-1989						}
;{	Written with Turbo Assembler ver 1.0				}
;{----------------------------------------------------------------------}

; $Log$
		locals

		include	ilbm.inc

dilbm		Segment Public 'FAR_DATA'

tempdpentry	dw	"MB","DH"
		dd	0
tempbmhd	BMHead	<>

dpentrys	db	"FORM"
		dw	readform,writeform
		db	"ILBM"
		dw	readilbm,writeilbm
		db	"BMHD"
		dw	readbmhd,writebmhd
		db	"CMAP"
		dw	readcmap,writecmap
		db	"BODY"
		dw	readbody,writebody
		db	"PBM "
		dw	readpbm,writeilbm

ndpentrys	equ	($-dpentrys)/8

tendfile	dw	0,0
tpicwidth	dw	0
tpicheight	dw	0
tpicnplns	dw	0
tpicseg		dw	0
palsize		dw	0
paloff		dw	0
planarmode	dw	?

dilbm		Ends

ilbm		Segment Public 'CODE'

		assume	cs:ilbm,ds:dilbm,ss:nothing,es:nothing

;{----------------------------------------------------------------------}
;{	saveiff:							}
;{	  ax:bx = pointer to raw picture stuff				}
;{	  cx:dx = filename to save to					}
;{	  bp = 1 to compress file					}
;{----------------------------------------------------------------------}
saveiff		Proc	Far

		pushall

		push	ax
		push	bx
		mov	ds,cx			; set up filename pointer
		xor	cx,cx			; set up as normal
		mov	ah,CreateFile		; create the file
		Int	MsDos			; through MsDos
		mov	cx,ax			; if no errors
		pop	bx
		pop	ax
		jc	saifexit
		push	ax
		mov	ax,cx
		call	far ptr setsrcasmemory	; get stuff from memory
		call	far ptr setdestasdisk	; and put to disk
		pop	ax
		call	far ptr rawtoiff	; save off file
saifexit:
		mov	ax,seg dilbm
		mov	ds,ax
		lea	si,outpflushrtn
		call	dword ptr [si]		; if any flushing to do
		mov	bx,outpfhand
		mov	ah,CloseFile
		Int	MsDos
@@1:
		popall
		ret
saveiff		Endp

;{----------------------------------------------------------------------}
;{	rawtoiff:							}
;{	  save off a raw picture as an ilbm one				}
;{	  ax:bx = raw picture buffer					}
;{	  cs:fhand = file handle					}
;{	  bp = 1 to compress or not					}
;{----------------------------------------------------------------------}
rawtoiff	Proc	Far

;		pushall
;		mov	cx,seg dilbm
;		mov	ds,cx
;		mov	es,ax
;		mov	si,bx			; save for later
;		mov	ax,es:[picwidth]
;		mov	bx,es:[picnplns]
;		shr	ax,1
;		shr	ax,1
;		shr	ax,1			; make pixels to byte size
;		mul	bl
;		mov	bx,es:[picheight]
;		mul	bx			; get size of picture
;		mov	tendfile,ax
;		mov	tendfile+2,dx		; save size of picture
;		cmp	bp,0
;		je	@@1
;		call	near ptr ilbmcompanalyze ; see if compression can be
;@@1:						; used or not
;		lea	di,dpentrys
;		mov	cx,ndpentrys		; number of entries to write
;@@2:
;		mov	ax,[di+6]		; get routine to call
;		call	ax
;		jc	ratoifexit
;		add	di,8
;		loop	@@2			; and write all data out
;ratoifexit:
;		popall
;		ret

rawtoiff	Endp		

spicseg		dw	?

;{----------------------------------------------------------------------}
;{	loadiff:							}
;{	  load in iff file into memory					}
;{	  ax:bx = filename to load					}
;{	  cx = bit settings for information bypass			}
;{	    0 = palette bypass						}
;{	    1 = binary bypass						}
;{	    2 = raw pix structure bypass				}
;{	  dx = buffer pointer or zero for allocate one			}
;{	returns:							}
;{	  carry set on error						}
;{	  ax: segment of binary part of picture				}
;{	  es: segment of rawpix structure if exists			}
;{----------------------------------------------------------------------}
loadiff		Proc	Far

		push	bx
		push	dx
		push	di
		push	ds
		and	cx,7
		cmp	cx,7			; nothing wanted?
		je	@@1
		push	cx
		mov	cs:spicseg,dx		; save picture segment if exist
		mov	dx,bx
		mov	ds,ax
		mov	ah,OpenFile
		xor	al,al
		Int	MsDos			; start by opening file
		pop	cx
		jc	@@1
		mov	bx,seg dilbm
		mov	ds,bx
		mov	inpfhand,ax		; save the file handle
		call	far ptr setsrcasdisk	; from disk
		call	far ptr setdestasmemory	; to memory
		call	far ptr ifftoraw
		pushf
		push	ax
		mov	bx,seg dilbm
		mov	ds,bx
		mov	bx,inpfhand
		mov	ah,CloseFile
		Int	MsDos
		pop	ax
		popf
		jc	@@1
		mov	ax,es
		test	cx,4
		jne	@@1
		mov	ax,es:[picseg]
@@1:
		pop	ds
		pop	di
		pop	dx
		pop	bx
		ret

loadiff		endp

;{----------------------------------------------------------------------}
;{	ifftoraw:							}
;{	  translate iff file to raw format				}
;{	  infhand = iff buffer						}
;{	  cx = bit 0 = 1,palette information bypass			}
;{	  cx = bit 1 = 1,binary information bypass			}
;{	  returns							}
;{	  ax = 0 on successful or error code				}
;{	  es: ptr to raw pix structure					}
;{----------------------------------------------------------------------}

ifftoraw	Proc	Far

		push	bx
		push	cx
		push	dx
		push	bp
		push	si
		push	ds

		mov	bx,cx
		xor	bx,0ffffh		; change bits
		mov	ax,seg dilbm
		mov	ds,ax
;		test	displayScr.scrflags,4	; see if screen is sequential
;		je	@@1
		and	bx,0dfffh		; say make sequential
@@1:
		push	es
		mov	ax,seg dilbm
		mov	es,ax
		lea	di,tempdpentry
		lea	si,inpdatartn
		mov	cx,8
@@2:
		call	dword ptr [si]
		jc	@@4
		stosb
		loop	@@2
		pop	es
		call	near ptr decodeiffhead ; decode long word text ds:dx
		jc	@@4		; some kind of error
		call	ax		; call routine to do something
		jc	@@4		; if error then exit
		test	bx,7		; see if got to body
		jne	@@1		; nope keep going
@@3:
		mov	ax,seg dilbm
		mov	ds,ax
		mov	es,tpicseg
		xor	ax,ax		; no errors
		clc
@@4:
		pop	ds
		pop	si
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		ret

ifftoraw	Endp
 

;{----------------------------------------------------------------------}
;{	decodeiffhead:							}
;{	  get header info and loads calls appropriate routine		}
;{	  ds:si = pointer into ilbm file				}
;{	returns:							}
;{	  ax = error number						}
;{----------------------------------------------------------------------}
decodeiffhead	Proc	Near

		pushall

		mov	ax,seg dilbm
		mov	ds,ax
		mov	ax,tempdpentry		; get first word of text
		mov	bx,tempdpentry+2	; and second

		mov	cx,seg dilbm
		mov	ds,cx
		lea	di,dpentrys	; get to table list

		mov	cx,ndpentrys	; number of entries in dpaint
@@1:					; headers we care about
		cmp	ax,[di]		; see if first matches
		jne	@@2
		cmp	bx,[di+2]	; and second also
		jne	@@2
		mov	ax,[di+4]	; get address of routine
		jmp	@@3		; and return to sender
@@2:
		add	di,8		; next item in list
		loop	@@1		; try all of them
		mov	ax,offset unkdphead ; bypass header
@@3:
		clc
		popall
		ret

decodeiffhead	Endp

;{----------------------------------------------------------------------}
;{	unkdphead:							}
;{	  bypass unknown deluxe paint header or one we don't care	}
;{	  about.							}
;{	returns:							}
;{	  no errors							}
;{----------------------------------------------------------------------}
unkdphead	Proc	Near

		push	bx
		push	cx
		push	dx
		push	si
		push	ds

		mov	ax,seg dilbm
		mov	ds,ax
		GetRWord bx,tempdpentry+4 	; get 68000 long word
		GetRWord ax,tempdpentry+6
		add	ax,1
		adc	bx,0
		and	ax,0fffeh		; align word like
	
		mov	cx,seg dilbm
		mov	ds,cx
		mov	cx,bx
		mov	dx,ax
		lea	si,inpseekrtn		; seek to offset
		call	dword ptr [si]

		pop	ds
		pop	si
		pop	dx
		pop	cx
		pop	bx
		ret

unkdphead	Endp

;{----------------------------------------------------------------------}
;{	readform:							}
;{	  get form information from memory				}
;{	returns:							}
;{	  bx bit 3 cleared indicating 'FORM' found			}
;{----------------------------------------------------------------------}
readform	Proc	Near

		push	bx
		push	cx
		push	dx

		mov	ax,seg dilbm
		mov	ds,ax

		GetRWord ax,tempdpentry+4
		GetRWord bx,tempdpentry+6	; get length of form
		add	bx,9
		adc	ax,0
		and	bx,0fffeh

		mov	cx,seg dilbm
		mov	ds,cx

		mov	cl,4
		ror	ax,cl		; get high nibble into high
		mov	inpdatasize,bx
		mov	inpdatasize+2,ax

		pop	dx
		pop	cx
		pop	bx
		and	bx,0fff7h	; say 'FORM' found
		xor	ax,ax
		clc
		ret

		ret

readform	Endp

;{----------------------------------------------------------------------}
;{	writeform:							}
;{	  write form information from memory				}
;{	  es:si = pointer to raw picture				}
;{	  sets tendfile = 0						}
;{----------------------------------------------------------------------}
writeform	Proc	Near

		pushall

		mov	tempdpentry,'OF'
		mov	tempdpentry+2,'MR'

		mov	ax,tendfile
		mov	dx,tendfile+2
		mov	bx,size BMHead+20	; size of ILBM+BMHD+BODY
		test	es:[picflags],2		; headers and BMHD structure
		je	@@1			; no palette info avialable
		mov	bx,1
		mov	cx,es:[picnplns]	; get number of planes
		shl	bx,cl			; number of RGB colors
		mov	cx,bx			; save for later * 1
		shl	bx,1			; * 2
		add	bx,cx			; * 3 bytes RGB values
		add	bx,size BMHead+28
@@1:
		add	ax,bx
		adc	dx,0			; add to size of body

		StorRWord tempdpentry+4,dx
		StorRWord tempdpentry+6,ax	; save size of picture
		
		lea	dx,tempdpentry
		mov	cx,8
		push	ds
		mov	bx,seg dilbm
		mov	ds,bx 
		mov	bx,outpfhand
		pop	ds
		mov	ah,WriteFile
		Int	MsDos			; write out form

		popall
wrfoexit:
		ret

writeform	Endp

;{----------------------------------------------------------------------}
;{	readilbm:							}
;{	  just adds 4 bytes to pointer					}
;{	returns:							}
;{	  bx bit 4 cleared to indicated 'ILBM' was found		}
;{----------------------------------------------------------------------}
readilbm	Proc	Near

		and	bx,0ffefh	; set bit that 'ILBM was found
		push	bx
		push	cx
		push	dx
		push	si
		push	ds

		mov	cx,seg dilbm
		mov	ds,cx
		mov	planarmode,offset pltoseq1 ; not planar then
		mov	cx,-1
		mov	dx,-4
		mov	si,seg dilbm
		mov	ds,si
		lea	si,inpseekrtn
		call	dword ptr [si]

		pop	ds
		pop	si
		pop	dx
		pop	cx
		pop	bx
		ret

readilbm	Endp


;{----------------------------------------------------------------------}
;{	readpbm:							}
;{	  just adds 4 bytes to pointer					}
;{	returns:							}
;{	  bx bit 4 cleared to indicated 'PBM' was found			}
;{----------------------------------------------------------------------}
readpbm		Proc	Near

		and	bx,0ffefh	; set bit that 'ILBM was found
		push	bx
		push	cx
		push	dx
		push	si
		push	ds

		mov	cx,seg dilbm
		mov	ds,cx
		mov	planarmode,offset seqtopl1	; planar then
		mov	cx,-1
		mov	dx,-4
		mov	si,seg dilbm
		mov	ds,si
		lea	si,inpseekrtn
		call	dword ptr [si]

		pop	ds
		pop	si
		pop	dx
		pop	cx
		pop	bx
		ret

readpbm		Endp

;{----------------------------------------------------------------------}
;{	writeilbm:							}
;{	  just adds 'ILBM' to file					}
;{----------------------------------------------------------------------}
writeilbm	Proc	Near

		pushall

		mov	tempdpentry,'LI'
		mov	tempdpentry+2,'MB'

		Mov	ah,WriteFile
		push	ds
		mov	bx,seg dilbm
		mov	ds,bx
		mov	bx,outpfhand
		pop	ds
		mov	cx,4
		lea	dx,tempdpentry
		Int	MsDos			; write it out

		popall
		ret

writeilbm	Endp

;{----------------------------------------------------------------------}
;{	readbmhd:							}
;{	  get information from bit map head for raw format		}
;{	  allocates memory for raw file to place into			}
;{	  bx = bits set from other routines				}
;{	returns:							}
;{	  ax = error number						}
;{	  es:di pointer to new picture structure			}
;{----------------------------------------------------------------------}
readbmhd	Proc	Near

		push	cx
		push	dx
		push	bp
		push	ds

		mov	bp,bx		; save for later

		mov	ax,seg dilbm
		mov	es,ax
		mov	ax,seg dilbm
		mov	ds,ax
		mov	cx,size BMHead
		lea	di,tempbmhd
		lea	si,inpdatartn
@@0:
		call	dword ptr [si]
		jnc	@@0a
		jmp	readbmhdexit
@@0a:
		stosb
		loop	@@0

		push	es
		pop	ds
		GetRword ax,tempbmhd.BMHeadW ; get width in pixels
		mov	cl,3
		shr	ax,cl		; divide by 8 for bytes
		mov	tpicwidth,ax
		xor	bh,bh
		mov	bl,tempbmhd.BMHeadNplns ; get number of planes
		mov	tpicnplns,bx
		mul	bx		; and multiply * planes	
		cmp	planarmode,offset pltoseq1
		je	@@0a1
		mov	tpicnplns,1
		mov	tpicwidth,ax
@@0a1:
		GetRword dx,tempbmhd.BMHeadH ; and height of raster area
		mov	tpicheight,dx
		mul	dx		; and mulitply that
		test	bp,2		; want binary part of picture
		jne	@@0b		; yep so bypass zeroing ax
		xor	ax,ax
@@0b:
		mov	cx,bx
		xor	bx,bx		; assume no palette wanted
		test	bp,1		; see if true
		je	@@1		; yes so don't get size
		mov	bx,1		; and to get number of colors
		shl	bx,cl		; shift it left
		mov	cx,bx		; save * 1 value
		shl	bx,1		; get * 2 value
		add	bx,cx		; add together get * 3 value
@@1:
		mov	palsize,bx	; save palette size
		mov	paloff,0
		test	bp,4		; no raw pix structure?
		je	@@1a0		; nope don't want it
		mov	paloff,size rawpix
		add	bx,size rawpix	; and add in header size &
@@1a0:
		add	bx,15 		; get to next paragraph
		and	bx,0fff0h	; and mask to that value
		add	ax,bx		; get number of bytes
		adc	dx,0		; and add into high word

		mov	cl,4		; make palette size in paragraphs
		shr	bx,cl		; if wanted

		mov	di,seg dilbm
		mov	ds,di
		mov	es,di
		lea	di,dbytebuff

		longtopara	dx,ax

		cmp	word ptr outpdatartn,offset memstorebyte
		jne	@@2			; no need for buffer then
		cmp	cs:spicseg,0
		je	@@1a
		mov	ax,cs:spicseg
		jmp	@@1b
@@1a:
		call	far ptr malloc		; and allocate memory
@@1b:
		mov	es,ax			; save for later
		add	bx,ax
		mov	di,0
		jnc	@@2
		jmp	readbmhdexit		; exit with error
@@2:
		mov	outpdataptr+2,es
		mov	outpdataptr,di
		mov	ax,seg dilbm
		mov	ds,ax
		mov	tpicseg,es
		cmp	tempbmhd.BMHeadMask,1 ; see if masking enabled
		jne	@@3
		and	bp,7fffh	; say mask is there
@@3:
		cmp	tempbmhd.BMHeadComp,1 ; see if compressed
		jne	@@4
		and	bp,0bfffh	; set bit for compression
@@4:
		test	bp,4		; see if raw pix structure wanted
		jne	@@4a		; yes so make it
		jmp	@@6a		; else bypass it
@@4a:
		GetRWord ax,tempbmhd.BMHeadW ; get width
		GetRWord cx,tempbmhd.BMHeadH ; height
		xor	dh,dh
		mov	dl,tempbmhd.BMHeadNplns ; number of planes
		mov	si,seg dilbm
		mov	ds,si
		lea	si,outpdatartn
		call	dword ptr [si]
		mov	al,ah
		call	dword ptr [si]
		mov	al,cl
		call	dword ptr [si]
		mov	al,ch
		call	dword ptr [si]
		mov	al,bl
		call	dword ptr [si]
		mov	al,bh
		call	dword ptr [si]
		mov	al,dl
		call	dword ptr [si]
		mov	al,dh
		call	dword ptr [si]
		xor	ax,ax		; assume no palette info
		test	bp,1		; and check to see
		je	@@5
		mov	ax,2		; else palette available
@@5:
		test	bp,2000h	; see if to sequential
		jne	@@6
		or	ax,1		; set to save it
@@6:
		call	dword ptr [si]
		mov	al,ah
		call	dword ptr [si]
@@6a:
		and	bp,0ffdbh	; say memory allocated and 'BMHD' fnd.
		clc
readbmhdexit:
		mov	bx,bp
		pop	ds
		pop	bp
		pop	dx
		pop	cx
		ret

readbmhd	Endp

;{----------------------------------------------------------------------}
;{	writebmhd:							}
;{	  writes information from bit map head to file			}
;{----------------------------------------------------------------------}
writebmhd	Proc	Near

;		pushall
;
;		lea	bx,tempbmhd		; get to temporary BMHD
;		mov	ax,es:[picwidth]	; get width of picture
;		StorRWord [bx].BMHeadW,ax		; save it
;		mov	ax,es:[picheight]	; and get height
;		StorRWord [bx].BMHeadH,ax		; and height
;		mov	[bx].BMHeadX,0
;		mov	[bx].BMHeadY,0		; zero x offset and y offset
;		mov	ax,es:[picnplns]	; get number of planes
;		mov	[bx].BMHeadNplns,al	; save number of planes
;		mov	[bx].BMHeadMask,0	; no mask avialable
;		mov	ax,bp			; get if compressed or not
;		mov	[bx].BMHeadComp,al	; save it
;		mov	[bx].BMHeadpad1,0	; zero out pad byte
;		mov	[bx].BMHeadXparent,0	; transparent is color 0
;		mov	[bx].BMHeadXaspect,1	; who cares????
;		mov	[bx].BMHeadYaspect,1	; who cares????
;		push	ds
;		mov	ax,seg dilbm
;		mov	ds,ax
;		mov	cx,displayScr.scrhrez	; get screens resolution
;		mov	dx,displayScr.scrvrez
;		pop	ds
;		StorRWord [bx].BMHeadPageW,cx
;		StorRWord [bx].BMHeadPageH,dx	; save page width and height
;
;		mov	tempdpentry,'MB'
;		mov	tempdpentry+2,'DH'
;
;		mov	ax,size BMHead
;		StorRWord tempdpentry+6,ax
;		mov	tempdpentry+4,0
;
;		mov	ah,WriteFile
;		push	ds
;		mov	bx,seg dilbm
;		mov	ds,bx
;		mov	bx,outpfhand
;		pop	ds
;		mov	cx,size BMHead+8
;		lea	dx,tempdpentry
;		Int	MsDos

;		popall
;		ret

writebmhd	Endp

;{----------------------------------------------------------------------}
;{	readcmap:							}
;{	  transfer color map information if wanted			}
;{	  bx = bit settings						}
;{----------------------------------------------------------------------}
readcmap	Proc	Near

		test	bx,1		; see if color map wanted
		je	@@5
		mov	ax,EDATAINV	; set error in case one
		test	bx,30h		; see if 'ILBM' & 'BMHD' fnd.
		je	@@1
		stc			; return with error
		ret
@@1:	
		push	bx
		push	cx
		push	si
		push	di
		push	ds
		push	es
		mov	cx,seg dilbm
		mov	ds,cx
		mov	cx,palsize		; maximum palette size alloced
;		mov	palsize,0		; say transferred bytes
		mov	si,seg dilbm
		mov	ds,si
		lea	si,inpdatartn
		lea	di,outpdatartn
@@2:
		call	dword ptr [si]
		jc	@@3
		shr	al,1
		shr	al,1
		call	dword ptr [di]
		loop	@@2
		clc
@@3:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	cx
		pop	bx
		jc	@@4
		and	bx,0fffeh	; say already got color map
@@4:
		ret
@@5:
		jmp	near ptr unkdphead ; and bypass information

readcmap	Endp

;{----------------------------------------------------------------------}
;{	writecmap:							}
;{	  transfer color map information if wanted to file		}
;{----------------------------------------------------------------------}
writecmap	Proc	Near

;		pushall
;		test	es:[picflags],2
;		je	wrcmexit 
;		mov	tempdpentry,'MC'
;		mov	tempdpentry+2,'PA'
;		mov	cx,es:[picnplns]	; get number of planes
;		mov	dx,1
;		shl	dx,cl			; get number of colors
;		mov	cx,dx			; save
;		shl	dx,1
;		add	dx,cx			; save number of RGB values
;		mov	bp,dx			; for loop counter
;		StorRWord tempdpentry+6,dx
;		mov	tempdpentry+4,0		; number of RGB values
;
;		mov	cx,8
;		lea	dx,tempdpentry
;		push	ds
;		mov	bx,seg dilbm
;		mov	ds,bx
;		mov	bx,outpfhand
;		pop	ds
;		Mov	ah,WriteFile
;		Int	MsDos
;		jc	wrcmexit		; exit on error
;
;		mov	cx,bp			; number of RGB values
;		
;		mov	ax,es
;		mov	ds,ax			; swap es: ds:
;		mov	si,size rawpix		; bypass header info
;@@1:
;		shl	byte ptr[si],1
;		shl	byte ptr[si],1			; upgrade
;		inc	si
;		loop	@@1			; do all dah' color
;
;		mov	dx,size rawpix
;		mov	cx,bp			; size to write
;		Mov	Ah,WriteFile		; write RGB Values
;		Int	MsDos
;wrcmexit:
;		popall
;		ret

writecmap	Endp


;{----------------------------------------------------------------------}
;{	ilbmunpakline:							}
;{	  unpack line from ilbm file					}
;{	  ds:si = ptr to data						}
;{	  es:di = destination ptr					}
;{	returns:							}
;{	 if error							}
;{----------------------------------------------------------------------}
ilbmunpakline	Proc	Near

		push	ax
		push	bx
		push	cx
		push	dx
		push	bp

		xor	ch,ch
@@1:
		push	bx
		lea	bx,inpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	iuplexit
		cmp	al,80h		; see if no operation
		je	@@5
		mov	cl,al		; save in case literal copy
		inc	cl
		mov	ah,al		; save for next test
		cmp	al,127		; see if literal copy
		jb	@@2		; do literal copy then
		neg	al
		inc	al		; get a byte
		mov	cl,al		; save number to replicate
		push	bx
		lea	bx,inpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	iuplexit	; and exit if error
@@2:
		cmp	ah,127		; check for literal copy
		jnb	@@3		; nope so replicate byte
		push	bx
		lea	bx,inpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	iuplexit	; and exit if error
@@3:
		push	bx
		lea	bx,outpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	iuplexit	; exit if error
		cmp	outpdatasize,dx
		jbe	@@4
		stc
		mov	ax,EDATAINV
		jmp	iuplexit
@@4:
		loop	@@2		; and do for number of bytes
@@5:
		cmp	outpdatasize,dx
		jne	@@1
		clc
		mov	outpdatasize,0
iuplexit:
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		pop	ax

		ret

ilbmunpakline	Endp


;{----------------------------------------------------------------------}
;{	rawpakline:							}
;{	  pack line from raw buffer to ilbm file buffer			}
;{	  ds:si = ptr to data						}
;{	  es:di = destination ptr					}
;{	returns:							}
;{	 if error							}
;{----------------------------------------------------------------------}
rawpakline	Proc	Near

		ret
rawpakline	Endp

;{----------------------------------------------------------------------}
;{	ilbmeatpakline:							}
;{	  unpack line from ilbm file and just eat it			}
;{	  ds:si = ptr to data						}
;{	returns:							}
;{	 if error							}
;{----------------------------------------------------------------------}
ilbmeatpakline	Proc	Near

		push	ax
		push	bx
		push	cx
		push	dx
		push	bp 

		xor	ch,ch
@@1:
		push	bx
		lea	bx,inpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	ieplexit
		cmp	al,80h		; see if no operation
		je	@@4
		mov	cl,al		; save in case literal copy
		inc	cl
		mov	ah,al		; save for next test
		cmp	al,127		; see if literal copy
		jb	@@2		; do literal copy then
		neg	al
		inc	al		; get a byte
		mov	cl,al
		push	bx
		lea	bx,inpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	ieplexit	; and exit if error
		mov	ax,EDATAINV	; assume invalid data
		sub	dx,cx
		jc	ieplexit	; error if went over
		jnc	@@4
@@2:
		push	bx
		lea	bx,inpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	ieplexit	; and exit if error
		dec	dx
		cmp	dx,-1
		jne	@@3
		mov	ax,EDATAINV
		stc
		jc	ieplexit
@@3:
		loop	@@2		; and do for number of bytes
@@4:
		cmp	dx,0
		jne	@@1
		clc
ieplexit:
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

ilbmeatpakline	Endp

;{----------------------------------------------------------------------}
;{	rawmovline:							}
;{	  move bytes from ds:si to es:di				}
;{	  dx times							}
;{----------------------------------------------------------------------}
rawmovline	Proc	Near

		push	cx
		mov	cx,dx		; get number of bytes to move
@@1:
		shr	cx,1
		jnc	@@2
		movsb
@@2:
		repne	movsw
@@3:
		pop	cx		
		ret
		
rawmovline	Endp
;
;
;
ilbmmovline	Proc	Near

		push	ax
		push	bx
		push	cx
		push	dx
@@1:
		push	bx
		lea	bx,inpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	imlexit		; exit if error

		push	bx
		lea	bx,outpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	imlexit
		cmp	outpdatasize,dx
		jne	@@1
		mov	outpdatasize,0
		clc
imlexit:
		pop	dx
		pop	cx
		pop	bx
		pop	ax

		ret

ilbmmovline	Endp


;
;
;
ilbmeatline	Proc	Near

		push	ax
		push	bx
		push	cx
		push	dx

@@1:
		push	bx
		lea	bx,inpdatartn
		call	dword ptr [bx]
		pop	bx
		jc	ielexit		; exit if error
		dec	dx
		jne	@@1
ielexit:
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

ilbmeatline	Endp

tendbody	dw	?,?
tptr		label	dword
tptrOff		dw	?
tptrSeg		dw	?

;{----------------------------------------------------------------------}
;{	readbody:							}
;{	  unpack body into buffer					}
;{	  bx = bit setting for this ilbm file				}
;{	  es:di = ptr to raw picture structure				}
;{----------------------------------------------------------------------}
readbody	Proc	Near

		mov	ax,EDATAINV	; assume invalid data
		test	bx,30h		; see if stuff found
		je	@@1
		stc
		jmp	readbodyexit	; exit with error
@@1:
		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es
		test	bx,2
		jne	@@1a
		jmp	readbodyexit
@@1a:
		mov	cx,seg dilbm
		mov	ds,cx
		mov	cx,palsize
		add	cx,paloff
		and	cx,15			; get number 0-15
		sub	cx,16			; get number of bytes left
		neg	cx
		and	cx,15
		mov	al,0			; dummy value 
		mov	dx,seg dilbm
		mov	ds,dx
		lea	si,outpdatartn
		jcxz	@@2a			; already byte aligned?
@@2:
		call	dword ptr [si]		; align picture to paragraph
		loop	@@2
@@2a:
		mov	dx,seg dilbm
		mov	ds,dx
		mov	dx,tpicwidth		; get picture width
		mov	cx,tpicnplns 		; get number of planes
		mov	bp,tpicheight
@@3:
		mov	si,seg dilbm
		mov	ds,si
		lea	si,outpflushrtn
		call	dword ptr [si]		; make buffer empty
		mov	es,outpdataptr+2	; get current buffer storage
		mov	di,outpdataptr
		mov	outpdatasize,0
		mov	outpdatasize+2,0
		push	cx			; save number of planes & width
		mov	ax,offset ilbmunpakline
		test	bx,4000h		; see if compression on
		je	@@4
		mov	ax,offset ilbmmovline
@@4:
		call	ax			; and call appropriate routine

		jnc	@@5
		mov	ax,EDATAINV
		pop	cx
		jmp	readbodyexit	; and exit if error
@@5:
		loop	@@4		; and do number of planes

		pop	cx
		mov	ax,seg dilbm
		mov	ds,ax
		mov	ax,offset pltoseq1
		test	bx,2000h	; see if planar wanted
		je	@@5a
		mov	ax,offset seqtopl1
@@5a:
		cmp	planarmode,ax
		jne	@@6
		mov	tptrOff,ax
		mov	ax,seg dilbm
		mov	tptrSeg,ax
		push	bx
		push	ds
		mov	bx,seg dilbm
		mov	ds,bx
		mov	bx,di
		mov	ax,es
		call	dword ptr inconvert
		pop	ds
		pop	bx
@@6:
		test	bx,8000h	; see if mask in middle
		jne	@@8
		mov	ax,offset ilbmeatpakline
		test	bx,4000h
		je	@@7
		mov	ax,offset ilbmeatline
@@7:
		call	ax
		jnc	@@8
		jmp	readbodyexit	; exit if error
@@8:
		dec	bp		; and do height
		je	@@9
		jmp	@@3
@@9:
		xor	ax,ax		; no errors
		clc
		and	bx,0fffdh	; say got body
readbodyexit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret
		
readbody	Endp

;{----------------------------------------------------------------------}
;{	writebody:							}
;{	  pack body into buffer						}
;{	  es:si = ptr to raw picture structure				}
;{	  bp = 1 to compress
;{----------------------------------------------------------------------}
writebody	Proc	Near

;		pushall
;
;		mov	tempdpentry,'OB'
;		mov	tempdpentry+2,'YD'
;		mov	ax,tendfile+2
;		StorRWord tempdpentry+4,ax
;		mov	ax,tendfile
;		StorRWord tempdpentry+6,ax
;
;		push	ds
;		mov	bx,seg dilbm
;		mov	ds,bx
;		mov	bx,outpfhand
;		pop	ds
;		lea	dx,tempdpentry
;		mov	cx,8
;		mov	ah,WriteFile		; write 8 bytes to file
;		Int	MsDos
;		jc	wrboexit
;		mov	ax,es
;		mov	ds,ax
;		mov	bx,si			; get pointers
;		lea	di,dbytebuff
;		mov	cx,seg dilbm
;		mov	es,cx			; set up temporary buffer
;		mov	ax,ds:[picwidth]	; get width of picture
;		shr	ax,1
;		shr	ax,1
;		shr	ax,1			; make byte size
;		mov	cx,ds:[picnplns]	; times number of planes
;		mul	cl			; and get number of bytes
;		mov	dx,ax			; save for later
;		mov	bx,ds:[picheight]
;		and	bp,7fffh
;		test	ds:[picflags],1		; see if planar data
;		mov	ds,ds:[picseg]		; get to segment of picture
;		je	@@1
;		or	bp,8000h
;@@1:
;		push	bx
;		push	dx			; save line size for later
;		test	bp,8000h
;		je	@@2			; no need to convert line
;		call	far ptr seqtopl1	; convert to planar data
;@@2:
;		lea	ax,rawpakline		; assume packing wanted
;		test	bp,1
;		jne	@@3
;		lea	ax,rawmovline		; else just move dah' line
;@@3:
;		call	ax
;		push	ds
;		mov	ax,seg dilbm
;		mov	ds,ax
;		mov	cx,dx			; number of bytes to write
;		lea	dx,dbytebuff		; get buffer to write
;		mov	di,dx
;		push	ds
;		mov	bx,seg dilbm
;		mov	ds,bx
;		mov	bx,outpfhand
;		pop	ds
;		mov	ah,WriteFile
;		Int	MsDos
;		pop	ds
;		pop	dx
;		pop	bx
;		jc	wrboexit
;		dec	bx
;		jne	@@1
;wrboexit:
;		popall
;		ret

writebody	Endp

;
;
;
ilbmcompanalyze	Proc	Near

		ret

ilbmcompanalyze	Endp

ilbm		Ends

		end


