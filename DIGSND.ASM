; $Header$

;{----------------------------------------------------------------------}
;{	MSDOS sound library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	Written by Kenneth L. Hurley					}
;{	Started	4-1-1989						}
;{	Written with Turbo Assembler ver 1.0				}
;{----------------------------------------------------------------------}

; $Log$
		include	sound.inc

		locals

dsound		Segment	Public 'FAR_DATA'

savesseg	dw	?
sndptr		dw	?,?
soundsize	dw	?,?
maxssize	dw	?,?
psndrtn		dw	?
rsndrtn		dw	?
sounddone	dw	0
soundbrdfnd	dw	?

dsound		Ends

INITSTART	Segment Public 'FAR_DATA'

		Executehead	<"GRIN",32767,installsounds>

INITSTART	Ends

INITEND		Segment Public 'FAR_DATA'

		Executehead	<"GREN",32767,uninstallsounds>

INITEND		Ends

;
csound		Segment Public 'CODE'

		assume	cs:csound,ds:dsound,ss:nothing,es:nothing


;{----------------------------------------------------------------------}
;{	installsounds:							}
;{	  initialize sound routines					}
;{----------------------------------------------------------------------}
installsounds	Proc	Far

		pushall

		mov	ah,81h			; tandy wise any way
		Int	TIMERA
		cmp	ax,0c4h			; present?
		jne	@@1

		mov	ah,GETINTVEC
		mov	al,15h			; interrupt 15 vector
		Int	MSDOS			; get it

		mov	cs:saveint15,bx		; save it
		mov	cs:saveint15+2,es
		mov	cs:replacedint15,1

		mov	ax,seg myint15
		mov	ds,ax
		lea	dx,myint15		; setup ours
		mov	ah,SETINTVEC
		mov	al,15h			; interrupt 15 vector
		Int	MSDOS			; set it

		mov	ax,seg soundbrdfnd
		mov	ds,ax
		mov	soundbrdfnd,TANDYSOUND

		lea	ax,playtandysound
		lea	bx,recordtandysound
		mov	cx,1c8h			; playback rate
		mov	dx,32h			; record rate
		jmp	@@2
@@1:
		mov	ax,seg soundbrdfnd
		mov	ds,ax
		mov	soundbrdfnd,IBMSOUND

		lea	ax,playibmsound
		lea	bx,recordibmsound
		mov	cx,16
		mov	dx,0			; umm???
@@2:
		mov	bp,seg psndrtn
		mov	ds,bp
		mov	psndrtn,ax
		mov	rsndrtn,bx
		mov	cs:psndrate,cx
		mov	cs:rsndrate,dx

		xor	ax,ax
		popall
		ret

installsounds	Endp

;{----------------------------------------------------------------------}
;{	uninstallsounds:						}
;{	  remove interrupt vectors for sounds				}
;{----------------------------------------------------------------------}
uninstallsounds	Proc	Far

		pushall
		cmp	cs:replacedint15,1
		jne	@@1
		mov	cs:replacedint15,0
		mov	ds,cs:saveint15+2
		mov	dx,cs:saveint15
		mov	ah,SETINTVEC		; reset int 15h
		mov	al,15h
		Int	MSDOS
@@1:
		xor	ax,ax
		popall
		ret
uninstallsounds	Endp

;{----------------------------------------------------------------------}
;{	convertsound:							}
;{	  convert a sound loaded in if need be				}
;{	  ax:bx = sound pointer						}
;{	  cx:dx = size of sound						}
;{	  returns ax:bx = size of new sound alway less then original	}
;{----------------------------------------------------------------------}
convertsound	Proc	Far

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		cmp	cs:replacedint15,1
		jne	@@0
		mov	ax,cx
		mov	bx,dx
		jmp	cosoexit		; in tandy so don't convert
@@0:
		xchg	cx,dx

		mov	ds,ax
		mov	es,ax
		mov	si,bx			; set up pointer
		mov	di,bx			; to destination also

		add	cx,1
		adc	dx,0
		shr	dx,1			; divide by two
		rcr	cx,1
		mov	bx,dx
		mov	bp,cx			; number of bytes
		xor	dh,dh			; high byte should contain 0
@@1:
		lodsb
		cmp	si,0			; see if to next segment
		jne	@@2			; nope
		mov	si,ds
		add	si,1000h		; next 64k segment
		mov	ds,si
		xor	si,si			; rezero si
@@2:
		mov	dh,al			; save temporary
		and	dh,80h
		jne	@@3			; test for above zero in freq
		neg	al
		and	al,7fh			; then - voltage frequency
		mov	dh,7fh
@@3:
		shl	al,1			; double
		add	al,dh			; add in 
		jnc	@@4
		mov	al,-1			; max value
@@4:
		test	dh,80h			; see if above zero volts
		jne	@@5
		neg	al			; nope so reconvert
		and	al,7fh
@@5:
		and	al,0f0h			; mask off to high nibble
		mov	ah,al			; save for later
		lodsb				; get next byte
		cmp	si,0
		jne	@@6			; see if went over limit
		mov	si,ds
		add	si,1000h		; then next 64k boundary
		mov	ds,si
		xor	si,si
@@6:
		mov	dh,al
		and	dh,80h
		jne	@@7
		neg	al
		and	al,7fh
		mov	dh,7fh
@@7:
		shl	al,1
		add	al,dh
		jnc	@@8
		mov	al,-1
@@8:
		test	dh,80h
		jne	@@9
		neg	al
		and	al,7fh
@@9:
		shr	al,1
		shr	al,1
		shr	al,1
		shr	al,1
		or	al,ah
		stosb
		cmp	di,0
		jne	@@10
		mov	di,es
		add	di,1000h
		mov	es,di
		xor	di,di
@@10:
		dec	cx
		je	@@11
		jmp	@@1
@@11:
		cmp	dl,0
		je	@@12
		dec	dl
		jmp	@@1
@@12:
		mov	ax,bx
		mov	bx,bp
 cosoexit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

convertsound	Endp

;{----------------------------------------------------------------------}
;{	playsound:							}
;{	  call one of the player routines				}
;{----------------------------------------------------------------------}
playsound	Proc	Far

		pushall
		mov	di,seg psndrtn
		mov	ds,di
		mov	di,psndrtn
		call	di
		popall
		ret

playsound	Endp

;{----------------------------------------------------------------------}
;{	recordsound:							}
;{	  call one of the recorder routines				}
;{----------------------------------------------------------------------}
recordsound	Proc	Far

		pushall
		mov	di,seg rsndrtn
		mov	ds,di
		mov	di,rsndrtn
		call	di
		popall
		ret

recordsound	Endp

;{----------------------------------------------------------------------}
;{	playibmsound:							}
;{	  play a sound from tandy system				}
;{	  ax:bx = pointer to data					}
;{	  cx:dx = length of data					}
;{----------------------------------------------------------------------}
playibmsound	Proc	Near

		mov	ds,ax
		mov	si,bx
		mov	bx,cx
		mov	cx,dx

		xor	di,di
		cli
		mov	dx,PORTBOUT
@@2:
		push	bx
		push	cx
@@3:
		lodsb				; get a byte
		mov	ah,al
		cmp	si,0
		jne	@@4			; see if to next 64k
		mov	si,ds
		add	si,1000h		; update segment
		mov	ds,si
		xor	si,si			; zero this out again
@@4:
		xor	di,4			; shift value high nibble
		mov	bp,cs:psndrate
		mov	bl,ah			; into temp register
;		mov	cx,di			; get shift value
		mov	cx,4
		shr	bl,cl			; and shift it
;		mov	bh,0fh
;		sub	bh,bl
;		shr	bh,cl
;		and	bl,0fh			; mask off in case no shift
		mov	bh,0ffh			; get off time
		sub	bh,ah			; which is opposite bh
		shr	bh,cl
@@5:
		mov	cl,bl			; and start with on time
		jcxz	@@7
		mov	al,2			; set speaker on bit
		out	dx,al			; output it
@@6:
		loop	@@6			; delay between toggles
@@7:
		mov	cl,bh			; and off time now
		jcxz	@@9
		mov	al,0
		out	dx,al			; out put it
@@8:
		loop	@@8			; delay a little
@@9:
		dec	bp			; and do for snd rate
		jns	@@5			; times
;		or	di,di			; see if did last nibble yet
;		jne	@@4			; nope keep going

		pop	cx			; recover length pointers
		pop	bx
		loop	@@2			; and do in cx times
		cmp	bx,0			; is high zero?
		je	@@10			; yes so were finished
		dec	bx			; nope do next 64kbytes
		jmp	@@2
@@10:
		sti
		ret

playibmsound	Endp

;{----------------------------------------------------------------------}
;{	recordibmsnd:							}
;{----------------------------------------------------------------------}
recordibmsound	Proc	Near

		ret

recordibmsound	Endp

;{----------------------------------------------------------------------}
;{	getsoundparms:							}
;{	  get sound parameters						}
;{	  returns:							}
;{	   ax = sound recording rate value				}
;{	   bx = sound playing rate value				}
;{	   cx = sound volume level					}
;{	   dx = keypress to stop on if any, 0 = nokey			}
;{----------------------------------------------------------------------}
getsoundparms	Proc	Far

		mov	ax,cs:rsndrate
		mov	bx,cs:psndrate
		mov	cx,cs:sndvolume
		mov	dx,cs:keystopsound
		ret
		
getsoundparms	Endp

;{----------------------------------------------------------------------}
;{	setsoundparms:							}
;{	  set up sound parameters					}
;{	  ax = sound recording rate value				}
;{	  bx = sound playing rate value					}
;{	  cx = sound volume level					}
;{	  dx = keypress to stop on if any 0 = nokey			}
;{----------------------------------------------------------------------}
setsoundparms	Proc	Far

		mov	cs:rsndrate,ax
		mov	cs:psndrate,bx
		mov	cs:sndvolume,cx
		mov	cs:keystopsound,dx
		ret

setsoundparms	Endp

;{----------------------------------------------------------------------}
;{	playtandysound:							}
;{	  play a sound from tandy system				}
;{	  ax:bx = pointer to sound					}
;{	  cx:dx = length of sound					}
;{----------------------------------------------------------------------}
playtandysound	Proc	Near

		mov	bp,seg sounddone
		mov	ds,bp

		mov	sounddone,0		; check for sound done
		mov	cs:recording,0		; we are playing
		mov	sndptr,bx
		mov	sndptr+2,ax
		mov	es,ax			; set up initial buffer
		mov	soundsize,dx
		mov	soundsize+2,cx
		cmp	cx,0
		je	@@1
		xor	dx,dx
@@1:
		mov	cx,dx
		dec	cx
		mov	dx,cs:psndrate
		mov	ah,83h			; then start playing
		mov	al,byte ptr cs:sndvolume
		Int	TIMERA			; start playing
		jc	@@5
@@2:
		mov	ah,INPSTAT		; get input status
		Int	MSDOS
		cmp	al,0
		je	@@3
		mov	ah,UNFCHRIN
		Int	MSDOS
		xor	ah,ah
		cmp	al,0
		jne	@@2a
		mov	bl,al
		mov	ah,UNFCHRIN
		Int	MSDOS
		mov	ah,bl
@@2a:
		cmp	ax,cs:keystopsound
		jne	@@3
		stc
		jmp	@@5
@@3:
		cmp	sounddone,0
		je	@@2
@@4:
		mov	soundsize+2,0		; for no more to play
		mov	ah,84h			; stop all sound i/o
		int	TIMERA			; and do it
		clc
@@5:
		ret

playtandysound	Endp

;{----------------------------------------------------------------------}
;{	recordtandysound:						}
;{	  record a sound from tandy system				}
;{	  ax = recording KHZ value					}
;{	  returns:							}
;{	  ax:bx = pointer to sound					}
;{	  cx:dx = length of sound					}
;{----------------------------------------------------------------------}
recordtandysound Proc	Near

		mov	bp,seg sounddone
		mov	ds,bp

		mov	sounddone,0		; check for sound done
		mov	cs:recording,1		; we are recording
		mov	ax,-1			; get memory size
		call	far ptr malloc		; from malloc
		dec	ax			; for buffer
		mov	cx,ax
		xor	dx,dx			; zero out high byte
		paratolong cx,dx		; get size of buffer in bytes
		mov	maxssize,cx
		mov	maxssize+2,dx		; save sounds size
		cmp	dx,0
		je	@@1			; less than 64k?
		mov	dx,1
		xor	cx,cx			; then do 64k to start
@@1:
		mov	soundsize,cx
		mov	soundsize+2,dx
		call	far ptr malloc		; and allocate all memory
		mov	sndptr+2,ax
		mov	savesseg,ax
		mov	es,ax
		xor	bx,bx
		mov	sndptr,bx		; set sound initial pointer

		dec	cx
		mov	dx,cs:rsndrate
		mov	ah,82h			; then start recording
		Int	TIMERA			; do recording

@@2:
		mov	ah,INPSTAT		; get input status
		Int	MSDOS
		cmp	al,0
		je	@@3
		mov	dx,0ch			; reset lsb/msb stuff
		mov	al,0ffh
		out	dx,al
		mov	dx,02
		in	al,dx
		mov	ah,al
		in	al,dx
		xchg	ah,al
		mov	cl,4
		mov	bx,es
		shl	bx,cl
		sub	ax,bx
		dec	soundsize+2
		add	soundsize,ax
		adc	soundsize+2,0
		mov	ah,UNFCHRIN
		Int	MSDOS
		xor	ah,ah
		cmp	al,0
		jne	@@2a
		mov	bl,al
		mov	ah,UNFCHRIN
		Int	MSDOS
		mov	ah,bl
@@2a:
		cmp	ax,cs:keystopsound
		jne	@@3
		stc
		jmp	@@5
@@3:
		cmp	sounddone,0
		je	@@2
@@4:
		mov	dx,soundsize
		mov	maxssize,dx
		mov	cx,soundsize+2
		mov	maxssize+2,cx
		mov	ah,84h			; stop all sound i/o
		int	TIMERA			; and do it
		mov	ax,savesseg
		xor	bx,bx			; get pointer
		clc
@@5:
		ret

recordtandysound Endp

keystopsound	dw	0
going		dw	0
saveint15	dw	?,?
recording	dw	0
replacedint15	dw	0
sndvolume	dw	3
rsndrate	dw	16h
psndrate	dw	1c8h

;{----------------------------------------------------------------------}
;{	myint15:							}
;{	  takes care of recording/playing interrupts			}
;{----------------------------------------------------------------------}
myint15		Proc	Far

		cmp	cs:recording,1
		je	recint15

myint15		Endp
		; %%%%% don't seperate drops through %%%%% ;
;{----------------------------------------------------------------------}
;{	playint15:							}
;{	  playing interrupt						}
;{----------------------------------------------------------------------}
playint15	Proc	Far

		push	ax
		pushall

		cmp	ax,91fbh		; end of dma for sound?
		jne	@@3
		mov	ax,seg soundsize
		mov	ds,ax
		mov	ax,soundsize+2
		mov	bx,soundsize
		cmp	ax,0			; check high byte
		jne	@@1
		xor	bx,bx
		mov	soundsize,bx
		mov	soundsize+2,ax
		mov	sounddone,1		; flag sound done
		jmp	@@3			; no more sound to come in
@@1:
		xor	cx,cx
		dec	ax
		jne	@@2
		mov	cx,bx
@@2:
		mov	soundsize,bx
		mov	soundsize+2,ax
		add	sndptr+2,1000h		; next 64k segment
		les	bx,dword ptr sndptr	; next address to record to
		dec	cx
		mov	dx,cs:psndrate
		mov	ah,83h
		mov	al,byte ptr cs:sndvolume ; output volume
		Int	TIMERA			; and initiate it
@@3:
		popall
		pop	ax
		jmp	dword ptr cs:[saveint15]

playint15	Endp

;{----------------------------------------------------------------------}
;{	recint15:							}
;{	  recording interrupt						}
;{	  when finished or 64k boundary reached				}
;{----------------------------------------------------------------------}
recint15	Proc	Far

		push	ax
		pushall

		cmp	ax,91fbh		; end of dma for sound?
		jne	@@3
		mov	ax,seg maxssize
		mov	ds,ax
		mov	ax,maxssize+2
		mov	bx,maxssize		; get maximum size of sound
		cmp	soundsize+2,ax
		jb	@@1
		cmp	soundsize,bx		; how about low byte
		jne	@@1
		mov	sounddone,1		; flag sound done
		jmp	@@3			; no more sound to come in
@@1:
		sub	bx,soundsize		; get next values
		sbb	ax,soundsize+2
		mov	dx,1
		xor	cx,cx			; 64k transfer
		cmp	ax,0			; only fraction left
		jne	@@2
		mov	cx,bx			; max xfer left
		xor	dx,dx
@@2:
		add	soundsize,cx
		adc	soundsize+2,dx
		add	sndptr+2,1000h		; next 64k segment
		les	bx,dword ptr sndptr	; next address to record to
		dec	cx
		mov	dx,cs:rsndrate		; rate of input
		mov	ah,82h			; input from mike
		Int	TIMERA			; and initiate it
@@3:
		popall
		pop	ax
		jmp	dword ptr cs:[saveint15]

recint15	Endp

csound		Ends
		end
