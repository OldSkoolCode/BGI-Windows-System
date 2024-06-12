; $Header: e:/graphic\RCS\buff.asm_v 1.2 1993/05/17 16:33:03 KENH Exp KENH $

		.xlist
;{----------------------------------------------------------------------}
;{	MSDOS buffering library routines				}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	Written by Kenneth L. Hurley					}
;{	Started	4-23-1989						}
;{	Written with Turbo Assembler ver 1.0				}
;{----------------------------------------------------------------------}

; $Log: buff.asm_v $
; Revision 1.2  1993/05/17  16:33:03  KENH
; *** empty log message ***
;
; Revision 1.1  1993/04/23  21:02:56  KENH
; Initial revision
;

		locals

		include	buff.inc

DGROUP		GROUP	_DATA

_DATA		Segment Public 'DATA'

pflips		dw	cgapflip,egapflip,tanpflip
inibufferon	dw	0
pic2seg		dw	?

_DATA		Ends

INITSTART	Segment	Public 'FAR_DATA'

		Executehead	<"GRIN",63000,SortGRCH>
		Executehead	<"GRIN",32767,initbuffering>

INITSTART	Ends

GRAFCHANGE	Segment	Public 'FAR_DATA'
GRAFCHANGE	Ends

cbuff		Segment Public 'CODE'

		assume	cs:cbuff,ds:DGROUP,ss:nothing,es:DGROUP

;{----------------------------------------------------------------------}
;{	SortGRCH:							}
;{	  sort up the GRAFCHANGE execute header structures		}
;{----------------------------------------------------------------------}
SortGRCH	Proc	far

		pushall
		mov	ax,seg GRAFCHANGE
		xor	bx,bx
		mov	cx,"RG"
		mov	dx,"HC"
		call	far ptr SortRtns
		xor	ax,ax
		popall
		ret
		
SortGRCH	Endp

;{----------------------------------------------------------------------}
;{	enablebuffering:						}
;{	  enable buffering if was disabled before			}
;{----------------------------------------------------------------------}
enablebuffering	Proc	Far

		pushall

		mov	ax,seg DGROUP
		mov	ds,ax
		cmp	bufferon,0	; see if buffering is on
		jne	enbuexit
		cmp	inibufferon,0
		jne	@@1
		call	far ptr initbuffering
		jmp	enbuexit
@@1:
		mov	bufferon,1
		mov	ax,pic1seg
		xchg	ax,pic2seg
		mov	pic1seg,ax
		test	displayScr.scrflags,2
		je	enbuexit
		xor	pagenum,1
		call	far ptr pageflip
enbuexit:
		popall
		ret

enablebuffering	Endp

;{----------------------------------------------------------------------}
;{	disablebuffering:						}
;{	  disable buffering if it is enabled				}
;{----------------------------------------------------------------------}
disablebuffering	Proc	Far

		pushall

		mov	ax,seg DGROUP
		mov	ds,ax
		cmp	bufferon,0	; see if buffering is on
		je	dibuexit
		mov	ax,pic1seg
		xchg	ax,pic2seg
		mov	pic1seg,ax
		mov	bufferon,0	; disable it
		test	displayScr.scrflags,2
		je	dibuexit
		mov	bx,pagenum
		mov	bh,bl
		xor	bx,0101h
		shl	bx,1
		add	bx,tandyspage
		shl	bh,1
		shl	bh,1
		shl	bh,1
		or	bl,bh
		mov	dx,InitFF
@@1:
		in	al,dx
		test	al,9
		jne	@@1
		mov	dx,CrtProPage
		mov	al,bl
		or	al,11000000b	; make high 2 bits 11
		out	dx,al	
 		call	far ptr waitvbl		; wait for vertical blank
dibuexit:
		popall
		ret

disablebuffering	Endp

;{----------------------------------------------------------------------}
;{	initbuffering:							}
;{	  set double buffering (pageflipping) animation system		}
;{	  screen device file needs to be loaded				}
;{	  returns:							}
;{	    ax = 0 or error number					}
;{----------------------------------------------------------------------}
initbuffering	Proc	Far

		pushall
		mov	ax,seg DGROUP
		mov	ds,ax		; set our short segment

		cmp	inibufferon,0		; already inited stuff
		jne	inbuexit		; yes so don't redo it
		lea	ax,refrbuff2
		mov	rbuffptr2,ax
		mov	rbuff2beg,ax

		mov	cx,displayScr.nplanes
		mov	ax,displayScr.scrplnsize
		test	displayScr.scrflags,4
		je	@@1
		mov	cx,1
@@1:
		mul	cx
		longtopara ax,dx
		mov	bx,displayScr.scr2segment ; need another buffer?
		cmp	bx,0		; if zero then we do
		jne	@@2		; nope so no need for extra buffer
		call	far ptr malloc	; get the buffer
		jc	inbuexit	; exit if error
		mov	displayScr.scr2segment,ax ; save the segment pointer
		mov	bx,ax
@@2:
		xchg	pic1seg,bx
		mov	pic2seg,bx
		mov	pagenum,0 	; showing first so draw to second page
		mov	bufferon,1
		mov	inibufferon,1	; say buffering enabled
		mov	bufferon,1
		test	displayScr.scrflags,2
		je	inbuexit
		xchg	pic1seg,bx	; save ptr to screen to draw to 
		mov	pic2seg,bx	; and currently showing screen
		mov	pagenum,0 	; showing second so draw to first page
inbuexit:
		xor	ax,ax
		popall
		ret

initbuffering	Endp


;{----------------------------------------------------------------------}
;{	pageflip flips the page for mode				}
;{----------------------------------------------------------------------}
pageflip	Proc	Far

		pushall
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	bx,displayScr.scrflags
		and	bx,3
		shl	bx,1
		mov	ax,pflips[bx]
		call	ax

		mov	ax,seg GRAFCHANGE
		xor	bx,bx
		mov	cx,"RG"
		mov	dx,"HC"		; header checks
		mov	bp,CHGPAGE
 		call	far ptr ExecuteRtns

		mov	ax,xscroll1	; if any scroll positions to update
		xchg	ax,xscroll2
		mov	xscroll1,ax
		mov	ax,yscroll1	; if any scroll positions to update
		xchg	ax,yscroll2
		mov	yscroll1,ax

		popall
		ret

pageflip	Endp

;{----------------------------------------------------------------------}
;{	egapsuedoflip:							}
;{	  psuedo page flip for modes that cannot do it hardware		}
;{	  wise								}
;{----------------------------------------------------------------------}
egapsuedoflip	Proc	Near

		xor	si,si
		xor	di,di
		mov	es,pic2seg
		mov	cx,displayScr.hlinesize	; save in temporary register
		add	di,cx
		add	si,cx
		mov	bp,displayScr.scrvrez	; number of lines per screen
		mov	dx,displayScr.nlineadd
		mov	ds,pic1seg		; set up source segment
@@1:
		mov	bx,1
		push	si
		push	di
		push	ds
		push	es
@@2:
		push	dx
		mov	dx,EgaSeq
		mov	ah,bl		; get plane to select
		mov	al,02		; map mask select
		out	dx,ax		; select plane to write
		inc	bh		; next read plane if need be
		shl	bl,1		; and mask select
		pop	dx
@@3:
		push	cx
		sub	si,cx
		jnc	@@4
		push	bx
		mov	bx,si
		shr	bx,1
		shr	bx,1
		shr	bx,1
		shr	bx,1		; reset if going to go over 64k bndry
		mov	ax,ds
		add	ax,bx
		mov	ds,ax
		and	si,0fh
		pop	bx
@@4:
		sub	di,cx		; reset to beginning of line
		shr	cx,1		; size in words
		repne	movsw		; move in number of words
		pop	cx
		add	si,cx		; next plane source
		cmp	bx,410h
		jb	@@2

		pop	es
		pop	ds
		pop	di
		pop	si

		add	si,dx		; add in next line offset
		jnc	@@5
		mov	ax,ds
		add	ax,1000h	; next 64k segment
		mov	ds,ax
@@5:
		add	di,cx		; add in next line destination
		dec	bp		; minus 1 for height of screen
		jne	@@1		; do heighth

		ret

egapsuedoflip	Endp

;{----------------------------------------------------------------------}
;{	cgapflip psuedo page flips for cga mode				}
;{----------------------------------------------------------------------}
cgapflip	Proc	Near

		mov	ax,seg DGROUP
		mov	ds,ax
		test	displayScr.scrflags,4	; planar mode
		jne	@@1			; yes do this way then
		cli
		call	far ptr waitvbl
		sti
		jmp	near ptr egapsuedoflip	; copy buffer to screen
		ret
@@1:
		mov	ax,pic2seg
		mov	es,ax
		mov	bp,displayScr.scrplnsize
		mov	cx,displayScr.hlinesize
		mov	dx,bp
		sub	dx,displayScr.hlinesize
		neg	dx
		mov	ax,displayScr.nlineadd
		sub	ax,cx
		shr	cx,1
		xor	di,di
		mov	bx,displayScr.scrvrez
		mov	ds,pic1seg
		cli
		call	far ptr waitvbl
		sti
cgpfl1:
		mov	si,di
		push	cx
		repne	movsw
		pop	cx
		add	di,ax
		cmp	di,bp
		jb	cgpfl2
		add	di,dx
cgpfl2:
		dec	bx
		jne	cgpfl1
cgpfl3:

		ret

cgapflip	endp

;{----------------------------------------------------------------------}
;{	egapflip:							}
;{	 flips the page number for flicker free animation		}
;{----------------------------------------------------------------------}
egapflip	Proc	Near

		mov	dx,InitFF
ewvl1:
		in	al,dx		; wait till in horizontal retrace
		test	al,9
		jne	ewvl1

		mov	ax,seg DGROUP
		mov	ds,ax
		mov	bx,word ptr hardscrnsize

		xor	word ptr[pagenum],1	; if ok then do it
		jne	@@1
		xor	bx,bx		; set to zeroth page
@@1:
		mov	ah,bh		; get high byte of offset
		mov	al,0ch		; and start address high
		mov	dx,CrtC		; crt controller port
		out	dx,ax		; output high byte
		inc	al		; crt controller port next register
		mov	ah,bl		; get low byte
		out	dx,ax		; and output it

ewvl2:
		mov	dx,InitFF
		in	al,dx
		test	al,8
		je	ewvl2		; wait till in vertical retrace

		assume	ds:biosseg
		mov	dx,ds
		mov	ax,seg biosseg
		mov	ds,ax
		mov	[CRTStart],bx
		mov	ds,dx

		assume	ds:DGROUP

		mov	bx,xscroll1	; if any scroll positions to update

		and	bx,07		; get lowest value
		mov	al,33h		; horizontal pel panning register
		mov	dx,EgaAttr	; attribut controller register
		out	dx,al
		mov	al,bl
		out	dx,al		; set scroll value

		mov	ax,pic2seg
		xchg	ax,pic1seg
		mov	pic2seg,ax
		mov	ax,rbuffptr1
		xchg	ax,rbuffptr2
		mov	rbuffptr1,ax
		mov	ax,rbuff1beg
		xchg	ax,rbuff2beg
		mov	rbuff1beg,ax

;		xor	ax,ax
;		out	21h,al

;		sti

		ret

egapflip	endp

;{----------------------------------------------------------------------}
;{	tanpflip:							}
;{	 flips the page number for flicker free animation		}
;{----------------------------------------------------------------------}
tanpflip	Proc	Near

		mov	ax,seg DGROUP
		mov	ds,ax
		xor	pagenum,1

		mov	bx,pagenum

		mov	bh,bl
		xor	bl,1
		shl	bx,1
		add	bx,tandyspage
		shl	bh,1
		shl	bh,1
		shl	bh,1
		or	bl,bh
twvl1:
		mov	dx,InitFF
		in	al,dx		; wait till in horizontal retrace
		test	al,9
		jne	twvl1

;		mov	ax,0583h
;		int	VideoIO		; through bios call

		mov	dx,CrtProPage
		mov	al,bl
		or	al,11000000b	; make high 2 bits 11
		out	dx,al	
 		call	far ptr waitvbl		; wait for vertical blank
		mov	ax,rbuffptr1
		xchg	ax,rbuffptr2
		mov	rbuffptr1,ax
		mov	ax,rbuff1beg
		xchg	ax,rbuff2beg
		mov	rbuff1beg,ax

		ret

tanpflip	endp

cbuff		Ends

		end
