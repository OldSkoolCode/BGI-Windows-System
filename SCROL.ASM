		locals

		include	equates.i
		include	devs.i
		include	graf.i
		include	ilbm.i
		include	dos.i
		include	memory.i
		include	shaps.i
		include	scroll.i
		include	fonts.i
		include	lines.i
		include	buff.i
		include refresh.i

_STACK		segment byte public STACK 'STACK'

		dd	50h dup (?)

_STACK		ends

dmain		Segment	Public 'FAR_DATA'

file1		db	"beach",0
iffptr		dw	?
curx		dw	?
cury		dw	?
tjoyup		dw	?
tjoydown	dw	?
tjoyleft	dw	?
tjoyright	dw	?
topleft		dw	?
ypart		dw	0

modeerror	db	cr,lf,"No supported Video modes found!",cr,lf,"$",0
dataerror	db	cr,lf,"Error reading data files!",cr,lf,"$",0
joyerror	db	CR,LF,"No Joystick found!.",CR,LF,"$",0

TESTREZ		equ	(REZ_320x200)
TESTCOLORS	equ	(COLOR16)

STARTX		equ	0
STARTY		equ	0

dmain		ends


main		Segment	Public 'CODE'

		assume	cs:main,ds:dmain

start:
		mov	ax,seg dmain
		mov	ds,ax
		mov	minscroll,8

		mov	ax,TESTREZ
		mov	bx,TESTCOLORS
		call	far ptr findbestmode

		call	far ptr init
		mov	ax,seg dmain
		mov	ds,ax
		test	joysactive,3
		jne	@@0
		mov	dx,seg dmain
		mov	ds,dx
		mov	dx,offset joyerror
		mov	ah,PrintStr
		int	MsDos
		jmp	exit2
@@0:
		call	far ptr grafmode

		mov	ax,seg dmain
		lea	bx,file1
		call	far ptr loadmem		; load map into memory
		jnc	@@1
		jmp	exit
@@1:
		mov	ax,es
		mov	ds,ax
		mov	si,di			; get load address

		cmp	word ptr [si],'ML'	; see if lmap type
		je	@@2
		jmp	exit

		add	si,4			; skip header
@@2:
		
		
	
		mov	ax,seg dmain
		mov	ds,ax
		mov	cx,12000
		lea	si,scrn1
@@1:
		test	word ptr[si],4000h
		je	@@1a
;		mov	word ptr[si],2000
@@1a:
		add	si,2
		loop	@@1
		mov	ax,seg dmain
		mov	ds,ax
		mov	blockandvalue,0
		mov	mapinvram,FALSE
@@5:
		mov	bx,seg dmain
		mov	ds,bx
		mov	bitmapptr,ax
		mov	cx,ax
		mov	ax,es
		mov	bx,size rawpix
		call	far ptr setpalette
		mov	ax,seg dmain
		mov	ds,ax
		mov	refron,0
		mov	ax,seg dmain
		mov	ds,ax
		mov	es,pic1seg
		lea	bx,scrn11
		mov	dx,40
		xor	si,si
		xor	bp,bp
		mov	ax,seg dmain
		mov	ds,ax
		mov	di,25
@@2:
		push	cx
		push	di
		mov	di,cx
		mov	cx,40
		mov	ax,240
		call	far ptr drawcharrow
		pop	di
		pop	cx
		add	bx,240
		add	si,8
		dec	di
		jne	@@2
		mov	ax,seg dmain
		mov	ds,ax
		mov	ax,pic1seg
		mov	cx,backseg
		xor	bx,bx
		xor	dx,dx
		call	far ptr copyfromscr
		mov	ax,backseg
		mov	cx,pic2seg
		call	far ptr copytoscr
		mov	xscroll1,320
		mov	xscroll2,320
		mov	yscroll1,600
		mov	yscroll2,600
		
		mov	ax,seg dmain
		mov	ds,ax
;		call	far ptr readjoys

		lea	bx,scrn11
		mov	topleft,bx
		mov	curx,320
		mov	cury,600
@@4:
		call	far ptr pageflip
		mov	ax,seg dmain
		mov	es,ax
		mov	es,es:pic1seg
		call	far ptr readjoys
		test	bp,0Fh
		je	@@6
		jmp	exit
@@6:
		mov	di,topleft
		mov	dx,curx
		mov	bp,cury
		test	si,JOYRIGHT
		je	@@10
		cmp	curx,640
		je	@@10
		add	dx,8
		add	di,2
@@10:
		test	si,JOYLEFT
		je	@@12
		cmp	curx,0
		je	@@12
		add	dx,-8 
		sub	di,2
@@12:
		test	si,JOYUP
		je	@@7
		cmp	cury,0
		je	@@7
		add	bp,-8
		sub	di,240
@@7:
		test	si,JOYDOWN
		je	@@8
		cmp	cury,600
		je	@@8
		add	bp,8
		add	di,240
@@8:
;		mov	cx,25
;		mov	bx,di
@@9:
;		mov	ax,[bx]
;		and	ax,3fffh
;		je	@@13
;		mov	ax,[bx+78]
;		and	ax,3fffh
;		je	@@13
;		add	bx,240
;		loop	@@9
		mov	topleft,di
		mov	cury,bp
		mov	curx,dx
@@13:
		push	ds
		mov	bx,seg dmain
		mov	ds,bx
		mov	bx,xscrollptr
		mov	ax,[bx]
		mov	bx,yscrollptr
		mov	bx,[bx]
		pop	ds
		sub	ax,curx
		neg	ax
		sub	bx,cury
		neg	bx
@@11:
		mov	dx,ax
		mov	bp,bx
		call	far ptr scroll
@@14:
		push	dx
		mov	bx,topleft
		xor	si,si
		or	bp,bp
		je	@@16
		js	@@15
		mov	si,192
		add	bx,5760
@@15:
		push	bp
		xor	bp,bp
		mov	dx,40
		mov	cx,40
		mov	di,iffptr
		call	far ptr drawcharrow
		mov	ax,8
		mov	cx,240
		pop	bp
		or	bp,bp
		js	@@15a
		neg	ax
		neg	cx
@@15a:
		add	bx,cx
		add	si,ax
		add	bp,ax
		jne	@@15
@@16:
		pop	dx
		mov	bx,topleft
		xor	bp,bp
		or	dx,dx
		je	@@18
		js	@@17
		add	bx,78
		mov	bp,312
@@17:
		push	dx
		mov	dx,25
		mov	cx,40
		mov	ax,240
		xor	si,si
		mov	di,iffptr
		call	far ptr drawcharcol
		mov	ax,8
		mov	cx,2
		pop	dx
		or	dx,dx
		js	@@17a
		neg	ax
		neg	cx
@@17a:
		add	bx,cx
		add	bp,ax
		add	dx,ax
		jne	@@17
@@18:
		jmp	@@4
exit:
		mov	ax,3
		int	VideoIO
exit2:
		call	far ptr mfreeall
		mov	ax,4c00h
		int	MsDos

main		Ends

		end	start

