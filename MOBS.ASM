; $Header$

;{----------------------------------------------------------------------}
;{	MSDOS mobs library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	Written by Kenneth L. Hurley					}
;{	Started	4-23-1989						}
;{	Written with Turbo Assembler ver 1.0				}
;{----------------------------------------------------------------------}

; $Log$

		locals

		include	mobs.inc

dobjects	Segment Public 'FAR_DATA'

drawrtns	dd	drawshape,rascopy,bytecopy,bsdrawshape
		dd	12 dup (?)

nshpobj		dw	0
shapobjects	object	maxshapes	dup	(<>)
lshpobjptr	dw	shapobjects
fshpobjptr	dw	shapobjects

dobjects	Ends

INITSTART	Segment	Public 'FAR_DATA'

		Executehead	<"GRIN",32767,killallobjects>

INITSTART	Ends

objects		Segment Public 'CODE'

		assume	cs:objects,ds:dobjects

;{----------------------------------------------------------------------}
;{	addobject:							}
;{	  add an object into the list					}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx = segment of animation sequence				}
;{	  dx = offset of animation sequence				}
;{	  bp = obstatus bits to write to				}
;{	  si = priority to set						}
;{	  returns:							}
;{	    ax:bx object pointer					}
;{----------------------------------------------------------------------}
addobject	Proc	Far

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	di,si			; save priority of shape
		mov	si,seg nshpobj
		mov	ds,si
		mov	si,ax			; and put x position in si
		mov	ax,EINSMEM
		cmp	nshpobj,maxshapes	; see if past maximum shapes
		cmc
		jb	addobexit		; yes so can't add
		inc	nshpobj
		push	cx
		push	si
		mov	cx,maxshapes		; maximum shapes to search
		lea	si,shapobjects		; get shape object pointers
@@1:
		cmp	[si].obnext,0		; see if object open
		je	@@2
		lea	si,[si+size object]
		loop	@@1
		pop	si
		pop	cx
		stc
		jmp	addobexit
@@2:
		mov	ax,si			; save current pointer
		xchg	si,lshpobjptr		; get old last object pointer
		mov	[si].obnext,ax		; and save new object pointer
		xchg	si,ax			; reset to our pointer
		mov	[si].obprev,ax		; save previous object
		mov	[si].obnext,-1		; say where taken
		pop	ax			; recover x position
		pop	cx			; recover animation segment
		mov	[si].obx,ax
		mov	[si].oby,bx		; save x & y
		mov	word ptr[si].obaniptr+2,cx ; seg dobjects
		mov	word ptr[si].obaniptr,dx ; ptr to animation structure
		mov	bx,dx
		mov	es,cx
		mov	es:[bx].sframeon,0	; reset in case 
		mov	[si].obstat,bp		; and save status bits
		mov	ax,ds
		mov	bx,si
		mov	cx,di			; set obpriority as requested
		push	ax
		call	far ptr setpriority
		pop	ax
addobexit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret
		
addobject	Endp

lowptr		dw	?
hiptr		dw	?
;{----------------------------------------------------------------------}
;{	setpriority:							}
;{	  set priority of moveable object (mob)				}
;{	  ax:bx = pointer to mob					}
;{	  cx = priority #						}
;{----------------------------------------------------------------------}
setpriority	Proc	Far

		pushall

		mov	ds,ax
		mov	di,bx
		mov	[di].obpriority,cx	; save priority setting
		mov	bp,cx			; save priority
		mov	si,fshpobjptr		; get shape objects addresses
		mov	cs:lowptr,-1
		mov	cs:hiptr,-1
		mov	cx,nshpobj		; get # object pointers
		cmp	cx,1			; only 1 shape or none
		ja	@@0			; then exit
		jmp	@@9
@@0:
		xor	bx,bx			; lowest priority so far
		mov	dx,-1			; highest priority so far
@@1:
		cmp	si,di			; see if same shape
		je	@@3			; yes then no priority checks
		mov	ax,[si].obpriority	; get priority of object
		cmp	ax,bp
		jbe	@@2
		cmp	ax,dx			; see if above current high then
		jnb	@@3
		mov	dx,ax
		mov	cs:hiptr,si		; set new low pointer
		jmp	short @@3
@@2:
		cmp	ax,bx
		jb	@@3
		mov	bx,ax
		mov	cs:lowptr,si		; now got high pointer also
@@3:
		mov	si,[si].obnext
		loop	@@1

		mov	si,[di].obprev		; get objects previous pointer
		mov	ax,[di].obnext		; get next pointer
		cmp	di,fshpobjptr		; first shape in list
		jne	@@4			; nope
		mov	fshpobjptr,ax		; yes, then set new first
		mov	si,ax			; pointer
		mov	[si].obprev,0		; set as first one then
		jmp	short @@6
@@4:
		mov	[si].obnext,ax
		cmp	ax,-1			; see if last in list
		jne	@@5			; nope
		mov	lshpobjptr,si		; then set new last one
		jmp	short @@6
@@5:
		mov	cx,si			; save current low pointer
		mov	si,ax			; get next pointer
		mov	[si].obprev,cx		; save previous pointer
@@6:
		mov	si,cs:lowptr		; get low pointer
		cmp	si,-1
		jne	@@7
		mov	[di].obprev,0
		mov	si,fshpobjptr
		mov	[si].obprev,di
		mov	fshpobjptr,di
		jmp	short @@9
@@7:
		mov	[di].obprev,si
		mov	[si].obnext,di
		mov	si,cs:hiptr
		cmp	si,-1
		jne	@@8
		mov	[di].obnext,-1
		mov	si,lshpobjptr
		mov	[si].obnext,di
		mov	lshpobjptr,di
		jmp	short @@9
@@8:
		mov	[di].obnext,si
		mov	[si].obprev,di
@@9:
		popall
		ret

setpriority	Endp

;{----------------------------------------------------------------------}
;{	updaobjects:							}
;{	  update objects in list					}
;{----------------------------------------------------------------------}
updaobjects	Proc	Far

		pushall			; save all da'ski registies

		mov	ax,seg fshpobjptr
		mov	ds,ax
		mov	si,fshpobjptr		; get shape objects addresses
		mov	cx,nshpobj
		cmp	cx,0
		jcxz	upobexit
@@1:
		push	cx
		mov	ax,[si].obx		; get x position for destination
		mov	bx,[si].oby		; get objects y position
		mov	cx,word ptr[si].obaniptr+2 ; get animation segment
		mov	dx,word ptr[si].obaniptr ; get animation pointer
		mov	bp,[si].obstat	; get status bits
		call	far ptr doanimseq ; go do animation sequence
		add	[si].obx,ax
		add	[si].oby,bx	; and next objects y
		mov	word ptr[si].obaniptr+2,cx
		mov	word ptr[si].obaniptr,dx
		mov	[si].obstat,bp	; and save new status
		cmp	cx,-1		; see if end of this shape
		jne	@@5
		cmp	dx,-1
		jne	@@5
		dec	nshpobj		; minus 1 in shapes in
		cmp	si,lshpobjptr	; see if last in list
		jne	@@2
		mov	ax,[si].obprev
		mov	lshpobjptr,ax	; reset last pointer
@@2:
		cmp	si,fshpobjptr	; see if first in list
		jne	@@4
		mov	ax,[si].obnext
		cmp	ax,-1		; last object also
		jne	@@3
		mov	ax,offset shapobjects
@@3:
		mov	fshpobjptr,ax
		xor	ax,ax
		xchg	[si].obnext,ax
		mov	si,ax
		jmp	@@6
@@4:
		xor	ax,ax		; zero out object pointer
		xchg	ax,[si].obnext	; get next object pointer
		mov	si,[si].obprev	; get previous object pointer
		mov	[si].obnext,ax	; bypass this object pointer
@@5:
		mov	si,[si].obnext
@@6:
		pop	cx
		loop	@@1
upobexit:
		popall
		ret

updaobjects	Endp

saveobj		dd	?

;{----------------------------------------------------------------------}
;{	doanimseq:							}
;{	  do an animation sequence					}
;{	  ax = object x to draw to					}
;{	  bx = objects y to draw to					}
;{	  cx = animseq segment address					}
;{	  dx = animseq ptr address					}
;{	  bp = objects status bits to pass				}
;{	  ds:si = object pointer					}
;{	  returns:							}
;{	   ax = add value x						}
;{	   bx = add value y						}
;{	   cx = new animseq pointer segment				}
;{	   dx = new animseq pointer					}
;{	   bp = new status bits						}
;{----------------------------------------------------------------------}
doanimseq	Proc	Far

		push	si
		push	di
		push	ds
		push	es
		cmp	cx,-1		; see if valid address
		jne	@@1
		cmp	dx,-1
		jne	@@1
		jmp	doasexit
@@1:
		mov	word ptr cs:saveobj,si	; save object pointer
		mov	word ptr cs:saveobj+2,ds
		mov	si,dx		; set up pointer to animseq
		mov	ds,cx
		mov	cx,word ptr[si].shpptr+2
		mov	dx,word ptr[si].shpptr
		push	ax		; save x position
		call	far ptr doshape ; go do a shape structure
		pop	ax		; recover x position

		test	[si].shpflags,8		; no updating frame stuff
		jne	@@1a
		mov	di,[si].snframes
		cmp	[si].sframeon,di	; see if only 1 frame
		je	@@2
		inc	[si].sframeon		; next frame
		cmp	[si].sframeon,di	; at end
		je	@@2
@@1a:
		test	[si].shpflags,4		; see if call routine every update
		jne	@@3
@@2:
		mov	cx,ds		; save in case no routine executed
		mov	dx,si		; here also
		cmp	word ptr[si].shptask,0
		jne	@@2a
		cmp	word ptr[si].shptask+2,0
		je	@@2b
@@2a:
		les	di,cs:saveobj	; get object pointer
		call	[si].shptask	; go do the task es:di = object ptr
					; ax = x, bx = y
					; cx:dx = animseq address
					; return cx:dx new animseq address
					; or -1,-1 if end it all
					; save return status bits
@@2b:
		mov	ax,cx
		mov	bx,dx
		cmp	ax,-1
		jne	@@3		; not ending
		cmp	bx,-1
		je	@@5
@@3:
		mov	cx,ds
		cmp	ax,cx		; see if moved
		jne	@@5
		cmp	bx,si		; check low word also
		jne	@@5
		test	[bx].shpflags,8		; see if to update seq at all
		jne	@@5
		mov	di,[bx].snframes
		cmp	[bx].sframeon,di	; see if all frames done
		jne	@@5			; nope not done yet
		add	bx,size animseq
		cmp	word ptr[bx].shpptr,-1	; see if reset to another sequence
		jne	@@4
		cmp	word ptr[bx].shpptr+2,-1
		jne	@@4
		mov	ax,[bx].syadd		; get next sequence address
		mov	bx,[bx].sxadd
		mov	[si].sframeon,0		 ; reset number of frames used
		jmp	@@5
@@4:
		mov	[bx].sframeon,0		 ; reset number of frames used
@@5:
		mov	cx,ax			; save new animseq pointer segment
		mov	dx,bx			; save new animseq pointer
		mov	ax,[si].sxadd		; get add values
		mov	bx,[si].syadd
		mov	di,[si].snframes
		cmp	[si].sframeon,di	; see if all finished
		je	doasexit
		test	[si].shpflags,1	; see if update x position
		je	@@6
		xor	ax,ax		; nope don't update
@@6:
		test	[si].shpflags,2	; see if update y position
		je	doasexit
		xor	bx,bx
doasexit:
		pop	es
		pop	ds
		pop	di	
		pop	si

		ret

doanimseq	Endp

tempobjstat	dw	?

;{----------------------------------------------------------------------}
;{	doshape:							}
;{	  draw a shape to the screen					}
;{	  ax = x position to draw to					}
;{	  bx = y position to draw to					}
;{	  cx:dx = pointer to shape structure				}
;{	  bp = object status						}
;{	   0 = uses draw shape routine					}
;{	   1 = uses rascopy drawing routine				}
;{	   2 = uses bytecopy drawing routine				}
;{	   bit 7 = 1: no refresh save					}
;{	  returns:							}
;{	    nothing							}
;{----------------------------------------------------------------------}
doshape		Proc	Far

		pushall
		mov	si,bp
		and	si,7fh
		mov	cs:tempobjstat,si
		mov	si,seg refron
		mov	ds,si
		push	refron		; save old value
		cmp	refron,0	; if refresh off don't set to on
		je	@@1
		mov	refron,0	; assume off
		test	bp,80h		; see if want no refresh
		jne	@@1
		mov	refron,1
@@1:
		mov	bp,ax
		mov	si,bx		; get to passing registers
		mov	ax,seg pic1seg
		mov	ds,ax
		mov	es,pic1seg	; get segment to draw to
		mov	ds,cx
		mov	bx,dx		; set up shape pointer
attachloop:
		push	bx		; in case any attachments
		push	ds
		mov	di,[bx].sdrawrtn
		and	di,0fh		; max entries is 16
		shl	di,1
		shl	di,1		; for double word pointers
		push	ds
		mov	ax,seg drawrtns
		mov	ds,ax
		lea	di,[drawrtns+di]
		mov	ax,[di]
		mov	word ptr cs:doshgortn,ax
		mov	cx,[di+2]
		mov	word ptr cs:doshgortn+2,cx
		pop	ds
		cmp	ax,0
		jne	@@1a
		cmp	cx,0
		je	@@4		; no draw routine?
@@1a:
		mov	ax,[bx].sx	; get x position of source
		mov	cx,[bx].sy	; get width of shape
		add	bp,[bx].sxoff
		add	si,[bx].syoff	; add into for crop mark
		mov	dx,[bx].sh	; and shapes height
		mov	di,[bx].shpseg	; shapes segment pointer
		mov	bx,[bx].sw	; get width
		xchg	bx,cx		; reverse this
		mov	ds,di		; source buffer
		call	far ptr drawshape
doshgortn	equ	$-4
@@4:
		pop	ds
		pop	bx
		mov	ax,word ptr [bx].nextshape+2	; get segment of next
		mov	bx,word ptr [bx].nextshape	; and shape pointer
		mov	ds,ax			; ok if gets zeroed gets reset
		cmp	ax,0
		jne	attachloop
		cmp	bx,0
		jne	attachloop		; next pointer is fine
		mov	ax,seg refron
		mov	ds,ax			; whew! if 0 could be trouble
		pop	refron
		popall
		ret
 
doshape		Endp

;{----------------------------------------------------------------------}
;{	killallobjects:							}
;{	  kill all objects in que list					}
;{----------------------------------------------------------------------}
killallobjects	Proc	Far

		pushall
		mov	ax,seg lshpobjptr
		mov	ds,ax
		mov	lshpobjptr,offset shapobjects
		mov	fshpobjptr,offset shapobjects
		mov	nshpobj,0
		mov	cx,maxshapes
		lea	si,shapobjects
@@1:
		mov	[si].obnext,0	; zero out all object pointers
		lea	si,[si+size object]
		loop	@@1
		xor	ax,ax
		popall
		ret
		
killallobjects	Endp

tx1		dw	?
ty1		dw	?

;{----------------------------------------------------------------------}
;{	InitPath:							}
;{	  initialize path for an object					}
;{	  ax = x1 start position					}
;{	  bx = y1							}
;{	  cx = x2 destination position					}
;{	  dx = y2							}
;{	  bp = shift mulitplier for movement 0 = * 1 pixel a move	}
;{					     1 = * 2 pixels a move	}
;{					     2 = * 4 pixels a move	}
;{					     3 = * 8 pixels a move etc.	}
;{	  si:di = pointer to pathvars structure				}
;{	returns:							}
;{	  pathvars structure filled in					}
;{----------------------------------------------------------------------}
InitPath	Proc	Far

		pushall

		mov	ds,si			; set pointer to pathvars
		mov	si,di

		mov	tx1,ax
		mov	ty1,bx
		xchg	cx,bp			; save tx2
		mov	ax,1			; starting postive for update
		mov	bx,1			; starting y postive for update
		shl	ax,cl
		shl	bx,cl			; make movement size
		xchg	cx,bp			; recover x2
		sub	dx,ty1			; subtract y1 from y2
		jge	storey			; skip if y2-y1 is nonnegative
		neg	bx			; negative y direction
		neg	dx			; absolute value of y2-y1
storey:
		mov	[si].pdeldy,bx		; store y for diagonal moves
		sub	cx,tx1			; subtrack x1
		jge	storex			; skip if x2-x1 is postive
		neg	ax			; make negative x direction
		neg	cx			; absolute value of cx
storex:
		mov	[si].pdeldx,ax		; save x direction
		cmp	cx,dx			; compare dels with delp
		jge	setdiag			; skip if straight move in x direction
		xor	ax,ax			; zap x update
		xchg	cx,dx			; exchange differences
		jmp	storedelsxy
setdiag:
		xor	bx,bx			; zap y update
storedelsxy:
		mov	[si].pdelsx,ax		; x update in straight direction
		mov	[si].pdelsy,bx		; y update in straight direction

		shl	dx,1			; get delp and * 2
		mov	[si].pdelse,dx		; change if straight move
		sub	dx,cx			; 2*delp-dels
		mov	di,dx			; initial value
		sub	dx,cx
		mov	[si].pdelde,dx
		inc	cx			; increment count
		xchg	bp,cx			; for division
		shr	bp,cl

		mov	[si].pinitval,di	; initial value
		mov	[si].pathmoves,bp	; save number

		popall
inpaexit:
		ret

InitPath	Endp

;{----------------------------------------------------------------------}
;{	MovePath:							}
;{	  Move one step in a path previous call to initpath a must	}
;{	  ax = x position						}
;{	  bx = y position						}
;{	  cx:dx = pathvars pointer					}
;{	returns:							}
;{	  ax = new x position						}
;{	  bx = new y position						}
;{----------------------------------------------------------------------}
MovePath	Proc	Far

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	ds,cx
		mov	si,dx			; set up pathvars pointer
		mov	di,[si].pinitval	; get initial or current value
		xor	bp,bp			; say no update
@@1:
		cmp	[si].pathmoves,0	; are were all done...
		je	mopaexit		; yes so exit
		cmp	di,0			; determine straight or diagonal
		jge	@@diagonal
@@straight:
		add	ax,[si].pdelsx		;update x
		add	bx,[si].pdelsy		;update y
		add	di,[si].pdelse		;update error term
		cmp	[si].pdelse,0
		jmp	@@2			;all finished
@@diagonal:
		add	ax,[si].pdeldx		;update x
		add	bx,[si].pdeldy		;update y
		add	di,[si].pdelde		;update error term
@@2:
		mov	[si].pinitval,di
		dec	[si].pathmoves		; go down one ball move
mopaexit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

MovePath	Endp

objects		Ends

		end




