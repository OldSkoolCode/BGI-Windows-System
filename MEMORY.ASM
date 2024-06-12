; $Header: e:/graphic\RCS\memory.asm_v 1.1 1993/04/23 21:07:33 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	MSDOS memory library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log: memory.asm_v $
; Revision 1.1  1993/04/23  21:07:33  KENH
; Initial revision
;
		locals

;		dosseg		; high level
				; language interface and group like names

		include	memory.inc

dpspseg		segment	at 0h

		org	0ah
pspexitptr	dw	?,?
		org	88h
int22vec	dw	?,?
dummyvec	label	dword

dpspseg		Ends

dmemory		Segment Public 'FAR_DATA'

membptrs	dw	0
savetprog	dw	0
topprog		dw	0
topused		dw	0
temptop		dw	0
topmem		dw	0
pspseg		dw	0
pspcurptr	dw	81h
startstack	dd	?

saveHeader	dw	?,?

dmemory		Ends

DGROUP		GROUP	_DATA

_DATA		Segment Public 'DATA'
uexitrtn	dd	?
oldvmode	db	?
oldvmonitor	db	?
ctrlcvector	dw	?,?
meminited	db	0
_DATA		Ends

;
; ---- for hooks into borland C compiler
;
_INIT_          SEGMENT WORD PUBLIC 'INITDATA'
		db	1			; far call
		db	1			; highest priority-1
		dd	_InstallSystem
                ENDS
_EXIT_          SEGMENT WORD PUBLIC 'EXITDATA'
		db	1			; far call
		db	1			; highest priority-1
		dd	cleanup
                ENDS

;
;
;
INITSTART	Segment	Public 'FAR_DATA'

		Executehead	<"GRIN",63000,SortGREN>
		

INITSTART	Ends

INITEND		Segment Public 'FAR_DATA'

		Executehead	<"GREN",100,resetVideoMode>
		
INITEND		Ends

memory		Segment Public 'CODE'

		assume	cs:memory,ds:dmemory,ss:nothing,es:nothing


;{----------------------------------------------------------------------}
;{	void _InstallSystem(void)					}
;{	  'C' callable initialization of system parameters		}
;{									}
;{----------------------------------------------------------------------}
_InstallSystem	Proc	C far


;{----------------------------------------------------------------------}
;{	init:								}
;{	  finds the top of program to determine memory amount		}
;{	  ax = graphics mode to load if necessary			}
;{----------------------------------------------------------------------}
init		Proc	Far

		pushall

		mov	bp,ax		; save for later
		mov	si,bx

		assume	ds:DGROUP
		mov	ax,seg DGROUP
		mov	ds,ax
		xor	bx,bx
		mov	es,bx
		mov	al,es:BiosActiveMonitor
		mov	oldvmonitor,al
		mov	ah,0fh
		Int	VideoIO
		mov	oldvmode,al
		cmp	meminited,0
		jne	@@MemDone
		mov	meminited,1
		assume	ds:dmemory

		mov	ah,51h
		Int	21h
		mov	ds,bx		; save segment of start

		mov	ax,seg topprog
		mov	bx,ss		; see if stack in our segment
		cmp	bx,ax
		jle	@@1		; nope so just got end of program
		mov	ax,bx
@@1:
		mov	bx,sp		; else get stack pointer
		add	bx,35
		mov	cl,4
		shr	bx,cl		; make paragraph size
		add	ax,bx		; and add to get to new segment
		mov	bx,2
		mov	cx,[bx]

		mov	bx,ds
		
		mov	dx,seg topprog
		mov	ds,dx
		
		mov	topprog,ax	; set top of program
		mov	savetprog,ax
		mov	topmem,cx	; and top of memory
		mov	pspseg,bx	; save start of program
		mov	word ptr startstack,sp
		mov	word ptr startstack+2,ss

		mov	ax,seg pspseg
		mov	ds,ax
		mov	ds,pspseg
		mov	ax,seg exitint
		lea	bx,exitint
		assume	ds:dpspseg
		xchg	bx,[pspexitptr]
		xchg	ax,[pspexitptr+2]
		assume	ds:dmemory
		mov	word ptr cs:exitoldvec,bx
		mov	word ptr cs:exitoldvec+2,ax

		mov	ah,SETINTVEC
		mov	al,23h			; control break command
		mov	dx,seg ctrlcint
		mov	ds,dx
		lea	dx,ctrlcint
		Int	MSDOS

		mov	ax,3301h		; set control break flag
		mov	dl,1
		Int	MSDOS

@@MemDone:
		mov	ax,seg INITSTART
		xor	bx,bx
		mov	cx,"RG"
		mov	dx,"NI"		; header checks
		call	far ptr SortRtns
		mov	ax,seg INITSTART
 		call	far ptr ExecuteRtns
		jc	initexit
initexit:
		popall

		ret
 
init		Endp

_InstallSystem	Endp

;{----------------------------------------------------------------------}
;{	SortGREN:							}
;{	  sort up the INITEND execute header structures			}
;{----------------------------------------------------------------------}
SortGREN	Proc	far

		pushall
		mov	ax,seg INITEND
		xor	bx,bx
		mov	cx,"RG"
		mov	dx,"NE"
		call	far ptr SortRtns
		xor	ax,ax
		popall
		ret
		
SortGREN	Endp

CompareRtn	dd	?
itemsize	dw	?
BasePtr		dd	?
;{----------------------------------------------------------------------}
;{	ShellSort:							}
;{	  Shell sort a list of unknown type				}
;{	  in:								}
;{	    ax = number of items in list				}
;{	    bx:cx = pointer to routine to compare items			}
;{	    dx = size of item						}
;{	    ds:si = pointer to data					}
;{	  returns:							}
;{	    nothing							}
;{----------------------------------------------------------------------}
ShellSort 	Proc	far

		pushall
		mov	word ptr cs:CompareRtn,cx
		mov	word ptr cs:CompareRtn+2,bx
		mov	word ptr cs:BasePtr,si
		mov	word ptr cs:BasePtr+2,ds
		mov	bp,ax		; number of items in list
		mov	cs:itemsize,dx	; because mul trashes dx
		
		mov	bx,bp		; starting gap size
		jmp	@@checkgapLoop
@@gaploop:
		mov	cx,bx		; i = gap
		jmp	@@checkiLoop
@@iloop:
		mov	dx,cx		; j = i
		jmp	@@NextJ
@@jloop:
		push	dx

		mov	di,dx

		mov	ax,dx		; j value
		mul	cs:itemsize	; and get item size
		lds	si,cs:BasePtr	; get to items[j]
		add	si,ax

		mov	ax,di		; j value
		add	ax,bx		; + gap
		mul	cs:itemsize	; and second item
		les	di,cs:BasePtr	; get to items[(j+gap)]
		add	di,ax

		pop	dx

		call	dword ptr cs:CompareRtn ; see if less than or what

		or	ax,ax
		jl	@@nexti		; if not don't swap

;
; swap elements
;

		push	cx
		mov	cx,cs:itemsize	; get number of bytes in element
@@2:
		mov	al,[si]		; get source
		xchg	al,es:[di]	; swap destination
		mov	[si],al		; put back source
		inc	si
		inc	di
		loop	@@2
		pop	cx

@@nextj:
		sub	dx,bx		; j = j-gap
		jge	@@jloop
@@nexti:
		inc	cx
@@checkiLoop:
		cmp	cx,bp
		jl	@@iloop

@@checkgapLoop:
		shr	bx,1
		jg	@@gaploop

		popall
		ret

ShellSort	Endp

;{----------------------------------------------------------------------}
;{	CheckPriority:							}
;{	  Check for priority of Executehead structure			}
;{	  in:								}
;{	    ds:si = execute head structure 1 pointer			}
;{	    es:di = execute head structure 2 pointer			}
;{	  returns:							}
;{	    ax < 0 if EH struct < EH struct 2				}
;{	    ax = 0 if EH struct = EH struct 2				}
;{	    ax > 0 if EH struct > EH struct 2				}
;{----------------------------------------------------------------------}
CheckPriority	Proc	Far

		mov	ax,es:[di].priority
		sub	ax,[si].priority
		rcr	ax,1
		ret

CheckPriority	Endp

;{----------------------------------------------------------------------}
;{	SortRtns:							}
;{	  Sort the Execute Head structures by priority.			}
;{	  using quick sort algorithm					}
;{	  in:								}
;{	    ax:bx = segment:offset of structures			}
;{	    cx:dx = "XXXX" id string					}
;{	  returns:							}
;{	    nothing							}
;{----------------------------------------------------------------------}
SortRtns	Proc	Far

		pushall

		mov	ds,ax
		mov	si,bx		; set up pointers to data
		xor	ax,ax		; initial counter
@@1:
		cmp	word ptr [si].identifier,cx
		jne	@@2
		cmp	word ptr [si].identifier+2,dx
		jne	@@2
		inc	ax
		add	si,size Executehead
		jmp	@@1
@@2:
		or	ax,ax
		je	@@exitSR

		mov	si,bx
		mov	bx,seg CheckPriority
		mov	cx,offset CheckPriority
		mov	dx,size Executehead
		call	far ptr ShellSort
@@exitSR:
		popall
		ret

SortRtns	Endp

parm1		dw	?
parm2		dw	?

;{----------------------------------------------------------------------}
;{	ExecuteRtns:							}
;{	  Execute a batch of routines from a structure			}
;{	  of initialization routines					}
;{	  ax:bx = ptr to structures					}
;{	  cx = Header Pointer first word				}
;{	  dx = Header Pointer second word				}
;{	  bp = parm1							}
;{	  si = parm2							}
;{----------------------------------------------------------------------}
ExecuteRtns	Proc	Far

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	es,ax		; set up initialization segment
		mov	ds,ax		; set up initialization segment
		mov	di,bx
@@1:
		cmp	word ptr [di].identifier,cx
		jne	@@2
		cmp	word ptr[di].identifier+2,dx
		jne	@@2
		mov	al,byte ptr [di].misc
		and	ax,0ffh
		je	@@NotDevice
		mov	bx,bp
		cmp	al,bh
		jne	@@NextRtn
@@NotDevice:
		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	ax,bp
		mov	bx,si
		push	bx
		push	ax
		call	es:[di].routine
		pop	bx
		pop	bx
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		or	ax,ax
		jne	exrtexit
@@NextRtn:
		add	di,size Executehead
		jmp	@@1
@@2:
		clc
exrtexit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

ExecuteRtns	Endp

;{----------------------------------------------------------------------}
;{ Function:	memcpy							}
;{ Description:	copy memory from one location to another.		}
;{ Parameters:	ax:bx = destination address				}
;{ 		cx:dx = source address					}
;{		si = size						}
;{----------------------------------------------------------------------}
memcpy		Proc	far

		pushall

		mov	es,ax
		mov	di,bx
		xchg	dx,cx
		xchg	si,cx
		mov	ds,dx
		fartohuge si,ds
		fartohuge di,es

		cld
		cmp	dx,ax
		jg	@@forwardMove
		jne	@@backwardMove
		cmp	si,di
		jg	@@forwardMove
		jne	@@backwardMove
		jmp	@@mecpExit
@@forwardMove:
		shr	cx,1
		rep	movsw
		adc	cx,cx
		rep	movsb
		jmp	@@mecpExit
@@backwardMove:
		add	si,cx
		add	di,cx
		sub	si,2
		sub	di,2
		std
		shr	cx,1
		rep	movsw
		inc	si
		inc	di
		adc	cx,cx
		rep	movsb
		cld
@@mecpExit:
		popall
		ret
memcpy		Endp

;{----------------------------------------------------------------------}
;{	splitmem:							}
;{	  split memory control block					}
;{	  bx = size of first memory block				}
;{	  ds = ptr to control block					}
;{----------------------------------------------------------------------}
splitmem	Proc	Near

		push	bx
		push	cx
		push	dx
		push	di
		push	ds

		xor	di,di			; make sure at beginning
		mov	dx,[di].MCBsize		; get size of this block
		sub	dx,bx			; get remainder for n blk size
		cmp	dx,0			; if zero then block doesnt 
		je	@@1			; split
		mov	[di].MCBsize,bx		; set up size of this block
		mov	ax,ds			; get ptr to control block
		add	ax,bx			; add in to next block
		mov	cx,[di].MCBnext		; get this ones next block ptr
		mov	[di].MCBnext,ax		; save new next block ptr
		mov	ds,ax			; now go to next MCB
		sub	ax,bx			; make ax have last MCB segment
		mov	[di].MCBkeyword,'FM'	; set up as free memory
		mov	[di].MCBnext,cx		; and save next one in here
		mov	[di].MCBprev,ax		; and save previous MCB
		mov	[di].MCBsize,dx		; and size of this block
		call	near ptr unsplitmem	; unsplit if more free above
@@1:			
		mov	ax,bx			; return size of block
		pop	ds
		pop	di
		pop	dx
		pop	cx
		pop	bx
		ret

splitmem	Endp 

;{----------------------------------------------------------------------}
;{	unsplitmem:							}
;{	  unsplit memory control block					}
;{	  ds = ptr to control block					}
;{----------------------------------------------------------------------}
unsplitmem	Proc	Near

		push	bx
		push	cx
		push	dx
		push	di
		push	ds

		xor	di,di			; make sure at zero
		mov	ax,ds
		mov	dx,[di].MCBsize		; in case no next
		mov	cx,[di].MCBnext		; get next pointer block
		mov	ds,cx			; get to it
		cmp	[di].MCBkeyword,'FM'	; see if next free memory
		jne	@@1
		mov	dx,[di].MCBsize		; get size of this block
		mov	cx,[di].MCBnext		; get this ones next block ptr
		mov	ds,ax			; now go to previous MCB
		mov	[di].MCBnext,cx		; and save next MCB
		add	[di].MCBsize,dx		; add in size of this block
		mov	dx,[di].MCBsize		; keep size in dx for previous
		mov	ds,cx
		mov	[di].MCBprev,ax
@@1:
		mov	ds,ax			; reset to current segment
		mov	ax,[di].MCBprev		; get previous block
		cmp	ax,0
		je	@@2			; at first block bypass
		mov	ds,ax			; set up data segment
		cmp	[di].MCBkeyword,'FM'	; see if we also are free
		jne	@@2			; nope so bypass
		mov	[di].MCBnext,cx		; set up to next pointer
		add	[di].MCBsize,dx		; and free up all
		mov	ds,cx
		mov	[di].MCBprev,ax
@@2:
		pop	ds
		pop	di
		pop	dx
		pop	cx
		pop	bx
		ret

unsplitmem	Endp 

;{----------------------------------------------------------------------}
;{	mshrink:							}
;{	 shrink memory block to size					}
;{	  ax = memory block						}
;{	  bx = size of memory to shrink to				}
;{	  returns:							}
;{	    ax = error or size of block					}
;{----------------------------------------------------------------------}
mshrink		Proc	Far

		push	bx
		push	di
		push	ds

		inc	bx
		dec	ax
		mov	ds,ax			; get to MCB
		xor	di,di			; and zeroth byte

		mov	ax,EMEMBLINV		; can't shrink to more size
		cmp	[di].MCBkeyword,'LM'	; see if last memory block
		jne	@@2			; not easy

		cmp	[di].MCBsize,bx		; see if less than block size
		jb	mshrinkexit
@@1:
		mov	ax,[di].MCBsize		; get old value
		mov	[di].MCBsize,bx		; set new size
		sub	ax,bx			; get amount shrunk
		mov	bx,seg topprog
		mov	ds,bx
		sub	topprog,ax		; and free up memory
		jmp	mshrinkexit
@@2:
		cmp	[di].MCBkeyword,'AM'	; is it allocated
		jne	mshrinkexit
		call	splitmem		; split the memory then
mshrinkexit:
		cmp	ax,0ff00h		; see if error
		cmc
		pop	ds
		pop	di
		pop	bx
		ret

mshrink		Endp

;{----------------------------------------------------------------------}
;{	findoldmem:							}
;{	  searches through memory control blocks for a buffer 		}
;{	  bx = size requirements					}
;{	  free >= to requested size					}
;{----------------------------------------------------------------------}
findoldmem	Proc	Near

		push	bx
		push	cx
		push	dx
		push	di
		push	ds

		mov	ax,EMEMBLINV		; assume nothing big enough

		mov	dx,membptrs		; get last of memory allocated
		cmp	dx,0			; any memory allocated?
		je	fomexit

		mov	cx,savetprog		; get to first memory block
		xor	di,di			; zeroth byte in segment
@@1:
		mov	ds,cx
		cmp	[di].MCBkeyword,'LM'	; if at top of memory exit
		je	fomexit			; routine
		cmp	[di].MCBkeyword,'FM'	; see if free memory
		jne	@@3
		cmp	[di].MCBsize,bx		; see if big enough
		jb	@@3			; nope so bypass
		je	@@2			; if equal no split available
		mov	ax,bx			; get into temp register
		add	ax,2			; see if enough for header
		cmp	[di].MCBsize,ax		; and 16 bytes
		jbe	@@2			; nope so bypass split
		call	splitmem		; split memory control block
		xor	ax,ax			; no error
@@2:
		mov	[di].MCBkeyword,'AM'	; reallocate memory
		mov	ax,ds
		inc	ax			; get to memory block
		jmp	fomexit			; exit routine
@@3:
		mov	cx,[di].MCBnext		; get to next segment
		jmp	@@1
fomexit:
		cmp	ax,0ff00h		; see if error
		cmc
		pop	ds
		pop	di
		pop	dx
		pop	cx
		pop	bx
		ret

findoldmem	Endp

;{----------------------------------------------------------------------}
;{	malloc:								}
;{	  gets a block of memory and saves pointer for later free up	}
;{	  ax = size requirements -1 to get size available		}
;{	  returns							}
;{	   ax = INSMEM if error						} 
;{	   ax = segment pointer:0 = memory address			}
;{----------------------------------------------------------------------}
malloc		Proc	Far

		push	bx
		push	cx
		push	dx
		push	ds

		mov	bx,ax
		mov	ax,seg topmem
		mov	ds,ax			; and set it

		inc	bx			; take up 16 extra bytes
		je	@@1			; just want memory free

		call	findoldmem		; see if any inbetween
		jnc	mallocexit		; must have found something
@@1:
		mov	ax,seg topmem
		mov	ds,ax			; set it
		mov	ax,topmem		; get top of memory
		sub	ax,topprog		; and get memory available
		cmp	bx,0			; just want size of buffer
		je	mallocexit		; exit routine
		cmp	ax,bx			; see if enough memory
		jnb	@@2			; yep so no error
		mov	ax,EINSMEM		; set error number
		jmp	mallocexit		; exit with error message
@@2:
		mov	dx,topprog		; get buffer pointer
		mov	ax,dx
		add	topprog,bx		; and add to get to next one
		add	dx,bx
		cmp	dx,topused		; just for testing purposes
		jb	@@2a			; if below no new high value
		mov	topused,dx		; else save new high value
@@2a:
		mov	cx,[membptrs]		; get block memory pointers
		mov	[membptrs],ax		; and set new value
		mov	dx,bx
		xor	bx,bx			; zeroth byte
		cmp	cx,0			; check if any old values
		je	@@3
		mov	ds,cx			; get to that segment
		mov	[bx].MCBkeyword,'AM'	; move in allocated memory code
		mov	[bx].MCBnext,ax		; and ptr to next block
@@3:
		mov	ds,ax			; and last allocated segment
		mov	[bx].MCBkeyword,'LM'	; set code to last memory
		mov	[bx].MCBprev,cx		; save previous block ptr
		mov	[bx].MCBsize,dx		; save size of block
		add	ax,1			; bypass our 16 bytes
mallocexit:
		cmp	ax,0ff00h		; check for errors
		cmc
		pop	ds
		pop	dx
		pop	cx
		pop	bx
		ret

malloc		Endp

;{----------------------------------------------------------------------}
;{	mfree:								}
;{	  free up buffer from memory					}
;{	  ax = buffer ptr						}
;{	  returns:							}
;{	    ax = error number						}
;{----------------------------------------------------------------------}
mfree		Proc	Far

		push	bx
		push	cx
		push	ds

		dec	ax			; get to previous MCB header
		mov	ds,ax			; put in segment reg

		xor	bx,bx			; zeroth byte
		mov	ax,EMEMCBD		; assume memory block destroyed
		xor	cx,cx			; no size yet

		cmp	[bx].MCBkeyword,'LM'	; see if last memory
		jne	@@2			; nope so try another
@@0:
		mov	ax,[bx].MCBprev		; get previous control block
		add	cx,[bx].MCBsize		; get size of block
		cmp	ax,0			; no previous block?
		je	@@1			; yep so bypass writing lm
		mov	ds,ax			; get to previous MCB
		cmp	[bx].MCBkeyword,'FM'	; if free keep going
		je	@@0
		mov	[bx].MCBkeyword,'LM'	; and set as last one
@@1:
		mov	bx,seg membptrs
		mov	ds,bx
		mov	membptrs,ax
		sub	topprog,cx		; free up memory
		xor	ax,ax			; no errors
		jmp	mfreeexit		; get outa town
@@2:
		cmp	[bx].MCBkeyword,'AM'	; see if allocated memory
		jne	@@3
		mov	[bx].MCBkeyword,'FM'	; set as free memory now
		call	near ptr unsplitmem	; if memory split unsplit it
		xor	ax,ax
		jmp	mfreeexit		; exit routine
@@3:
		cmp	[bx].MCBkeyword,'FM'	; see if already free
		jne	mfreeexit		; nope so must be destroyed
		mov	ax,EMEMBLINV		; already free so forget it
mfreeexit:
		cmp	ax,0ff00h		; check for errors
		cmc
		pop	ds
		pop	cx
		pop	bx

		ret

mfree		Endp

;{----------------------------------------------------------------------}
;{	mfreeall:							}
;{	  free all memory allocated					}
;{----------------------------------------------------------------------}
mfreeall	Proc	Far

		push	ds

		mov	ax,seg membptrs
		mov	ds,ax
		mov	membptrs,0		; set no memory block ptr
		cmp	temptop,0
		jne	@@1
		mov	ax,topprog
		mov	temptop,ax
@@1:
		mov	ax,savetprog		; get where top of program is
		mov	topprog,ax		; and save it

		clc				; no errors
		pop	ds
		ret

mfreeall	Endp

		assume	ds:DGROUP

;{----------------------------------------------------------------------}
;{	ctrlcint:							}
;{	  handle control c's						}
;{----------------------------------------------------------------------}
ctrlcint	Proc	Far

		push	ax
		pushall

		mov	ax,seg DGROUP
		mov	ds,ax
		cmp	ctrlcvector,0
		jne	@@1
		cmp	ctrlcvector+2,0
		je	@@2
@@1:
		jmp	dword ptr [ctrlcvector]
@@2:
;		mov	ax,3
;		int	VideoIO			; back to text mode
;		call	far ptr mfreeall	; free up buffers in use
;		call	far ptr cleanup		; and clean up	
		popall
		pop	ax
;		iret
@@NoAction:
		clc
		ret

ctrlcint	Endp

;{----------------------------------------------------------------------}
;{	exitint:							}
;{	  exit interrupt handler					}
;{----------------------------------------------------------------------}
exitint		Proc	Far

		push	ax
		pushall

		mov	bx,ss
		mov	bp,sp
		assume	ds:dmemory
		mov	ax,seg startstack
		mov	ds,ax
		mov	sp,word ptr startstack
		mov	ss,word ptr startstack+2
		push	bp
		push	bx

		call	far ptr mfreeall	; free up buffers in use
		call	far ptr cleanup		; and clean up
		assume	ds:DGROUP
		mov	ax,seg DGROUP
		mov	ds,ax
		cmp	word ptr uexitrtn,0
		jne	@@1
		cmp	word ptr uexitrtn+2,0
		je	@@2
@@1:
		call	dword ptr uexitrtn
@@2:
		assume	ds:dmemory
		mov	ax,seg pspseg
		mov	ds,ax
		mov	ds,pspseg
		assume	ds:dpspseg
		mov	bx,word ptr cs:exitoldvec
		mov	cx,word ptr cs:exitoldvec+2
		mov	pspexitptr,bx
		mov	pspexitptr+2,cx
		xor	ax,ax
		mov	ds,ax
		mov	int22vec,bx
		mov	int22vec+2,cx
		assume	ds:DGROUP
		pop	bx
		pop	bp
		mov	ss,bx
		mov	sp,bp
		popall
		pop	ax
		clc
		jmp	far ptr dummyvec
exitoldvec	equ	$-4

exitint		Endp

;{----------------------------------------------------------------------}
;{	_exit:								}
;{	  exit the program if possible					}
;{----------------------------------------------------------------------}
_exitProg	Proc	Far

_exittext	Proc	Far			; already in text mode

		pop	ax
		mov	ah,PTERM
		Int	MSDOS

_exittext	Endp

_exitProg	Endp

;{----------------------------------------------------------------------}
;{	setexitrtn:							}
;{	  set the exit routine address of user				}
;{----------------------------------------------------------------------}
setexitrtn	Proc	Far

		push	cx
		push	ds
		mov	cx,seg uexitrtn
		mov	ds,cx
		mov	word ptr uexitrtn,bx		; set user exit routine
		mov	word ptr uexitrtn+2,ax		; and segment also
		pop	ds
		pop	cx
		ret

setexitrtn	Endp

;{----------------------------------------------------------------------}
;{ Function:	ResetVideoMode						}
;{ Description:	resets the video mode to what it was			}
;{ Paramters:	.							}
;{ returns:	.							}
;{----------------------------------------------------------------------}
resetVideoMode	Proc	Far
		
		push	ax
		push	bx
		push	ds
		push	es

		
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	al,oldvmonitor
		xor	bx,bx
		mov	es,bx
		mov	es:BiosActiveMonitor,al
		mov	ah,0fh
		Int	VideoIO
		cmp	al,oldvmode
		je	@@AlreadySet
		xor	ah,ah
		mov	al,oldvmode
		Int	VideoIO			; make sure in textmode
@@AlreadySet:
		pop	es
		pop	ds
		pop	bx
		pop	ax
		ret


resetVideoMode	Endp

;{----------------------------------------------------------------------}
;{	cleanup:							}
;{	  call execute clean up routines				}
;{----------------------------------------------------------------------}
cleanup		Proc	Far

		assume	ds:DGROUP
		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		mov	ax,seg INITEND
		xor	bx,bx
		mov	cx,"RG"
		mov	dx,"NE"
		xor	bp,bp
		call	far ptr ExecuteRtns
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

cleanup		Endp

;{----------------------------------------------------------------------}
;{	setctrlcvector:							}
;{	  set control c vector to something				}
;{	  ax:bx = address of handler					}
;{----------------------------------------------------------------------}
setctrlcvector	Proc	Far

		push	cx
		push	ds
		mov	cx,seg DGROUP
		mov	ds,cx
		mov	ctrlcvector,bx
		mov	ctrlcvector+2,ax
		pop	ds
		pop	cx
		ret

setctrlcvector	Endp

memory		Ends

_STACK		segment	byte public STACK 'STACK' ; end of program locator
endstack	label	byte
_STACK		ends


		end


