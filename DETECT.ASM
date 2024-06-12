; $Header$


; $Log$


		locals

detect		Segment	Public 'CODE'


		assume	cs:detect

		org	0h


		jmp	DetectEntry

		dw	NMODES

cgamodes	db	2
		dw	REZ_320x200,REZ_640x200
		dw	COLOR4,COLOR2
		dw	0,1
		db	'CGA',0

tandymodes	db	3
		dw	REZ_160x200, REZ_320x200, REZ_640x200
		dw	COLOR16, COLOR16, COLOR4
		dw	2,3,4
		db	'TANDY',0

egamodes	db	4
		dw	REZ_320x200,REZ_640x200,REZ_640x350,REZ_640x350
		dw	COLOR16,COLOR16,COLOR2,COLOR16
		dw	5,6,7,8
		db	'EGAVGA',0

mcgamodes	db	2
		dw	REZ_320x200,REZ_640x480
		dw	COLOR256,COLOR2
		dw	9,10
		db	'MCGA',0

vgamodes	db	1
		dw	REZ_640x480
		dw	COLOR16
		dw	11
		db	'EGAVGA',0

nvgamodes	db	1
		dw	REZ_320x200
		dw	COLOR256
		dw	12
		db	'NVGA',0

monomodes	db	1
		dw	REZ_720x348
		dw	COLOR2
		dw	13
		db	'MONO',0




		org	1000h
; ----- Detect entry point
;
Entry		label	word
;		mov	ax,REZ_720x348
;		mov	bx,COLOR2
;		call	near ptr findbestmode
;		mov	ax,4c00h
;		int	21h

DetectEntry	Proc	far

		call	near ptr findbestmode
		ret

DetectEntry	Endp

grafnum		dw	?
card1_found	dw	?
card2_found	dw	?
rez_bits	dw	?
color_bits	dw	?
name_ptr	dw	?

;
; -----	card check routines
;

cardchecks	dw	vgacheck
		dw	nvgacheck
		dw	mcgacheck
		dw	egacheck
		dw	tandycheck
		dw	cgacheck
		dw	monocheck

;
; ---- Detect tables for detection of graphics modes available
;
;	db	?	; number of entries in table
;	dw	?,?	; 1..num_entries of resolutions available
;	dw	?,?	; 1..num_entries of colors available
;	dw	?,?	; 1..num_entries of unique internal mode number
;	db	? dup (?) ; name of mode wanted
;


;{----------------------------------------------------------------------}
;{	ExecuteRtns:							}
;{	  Execute a batch of routines from a structure			}
;{	  of initialization routines					}
;{	  ax:bx = ptr to structures					}
;{	  cx = number of checks						}
;{	  bp = parm1							}
;{	  si = parm2							}
;{----------------------------------------------------------------------}
ExecuteRtns	Proc	Near

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	ds,ax		; set up initialization segment
		mov	di,bx
@@checkloop:
		mov	ax,bp
		mov	bx,si
		call	word ptr [di]
		jc	exrtexit	; card found so exit
		add	di,2
		loop	@@checkloop
		clc			; none found so return
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
;{	findbestmode:							}
;{	  finds the best mode for displayScr				}
;{	  ax = bit settings to check for rez				}
;{	  bx = bit settings to check for colors				}
;{	  returns:							}
;{	    ax = mode							}
;{	    dx = card found						}
;{	    carry set if no modes avialable				}
;{----------------------------------------------------------------------}
findbestmode	Proc	Near

		push	cx
		push	dx
		push	bp
		push	ds

		mov	bp,ax			; pass parameters
		mov	si,bx

		mov	ax,cs
		mov	bx,offset cardchecks
		mov	cx,nchecks
		call	near ptr ExecuteRtns

		mov	rez_bits,ax
		mov	color_bits,bx

		mov	ax,grafnum
		mov	bx,card1_found
		cmc				; c = 1 if found card
		pop	ds
		pop	bp
		pop	dx
		pop	cx

		ret

findbestmode	Endp

;{----------------------------------------------------------------------}
;{	testgmode:							}
;{	  test for graphics mode wanted corresponds to card found	}
;{	  in:								}
;{	    ax:bx = seg:offset of graphics mode parameters		}
;{	    bp = rez bits wanted					}
;{	    si = color bits wanted					}
;{	  out:								}
;{	    ax = mode number						}
;{	    c = 1 if mode found						}
;{	    bp = rez bits found						}
;{	    dx = color bits found					}
;{----------------------------------------------------------------------}
testgmode	Proc	near

		push	bx
		push	cx
		push	si
		push	di
		push	ds

		mov	dx,bp			; get into registers
		mov	bp,si

		mov	si,bx			; set up offsets

		mov	ds,ax			; set up pointer to table
		lodsb				; get number of items in table
		mov	name_ptr,si
		xor	ah,ah
		mov	di,si
		mov	bx,si
		mov	cx,ax			; counter register
		shl	ax,1
		add	di,ax			; color table pointer
		add	name_ptr,ax
		shl	ax,1
		add	bx,ax
		add	name_ptr,ax
@@1:
		lodsw
		test	ax,dx			; see if rez wanted
		je	@@2
		test	bp,[di]			; if colors match then exit
		je	@@2
		and	dx,ax
		mov	ax,[di]
		and	bp,ax
		stc				; match found return
		mov	ax,[bx]			; return mode #
		jmp	@@3
@@2:
		add	di,2			; next color set
		add	bx,2
		loop	@@1
		clc				; none found
@@3:
		pop	ds
		pop	di
		pop	si
		pop	cx
		pop	bx
		ret

testgmode	Endp

;{----------------------------------------------------------------------}
;{	cgacheck:							}
;{	  check for cga mode capability					}
;{----------------------------------------------------------------------}
cgacheck	Proc	near

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	bp,ax
		mov	si,bx
		mov	dx,3d4h
		call	near ptr find6845	; find 6845 chip
		jnc	@@2			; not found here
		cmp	card1_found,NONE		; was card found previously
		jne	@@1
		mov	card1_found,CGA_CARD	; nope so set cga card here
@@1:
		mov	ax,cs
		mov	bx,offset cgamodes
		call	near ptr testgmode
		jnc	@@2
		mov	grafnum,ax
		mov	ax,dx
		mov	bx,bp
@@2:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret
cgacheck	Endp

;{----------------------------------------------------------------------}
;{	egacheck:							}
;{	  check for ega system						}
;{----------------------------------------------------------------------}
egacheck	Proc	near

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	bp,ax
		mov	si,bx
		mov	ah,12h
		mov	bl,10h
		int	VideoIO
		cmp	bl,10h			; no ega found
		je	egacexit		; c = 0 non ega
		cmp	card1_found,NONE
		jne	@@1
		mov	card1_found,EGA_CARD	; set ega card was found
@@1:
		mov	ax,cs
		mov	bx,offset egamodes
		call	near ptr testgmode
		jnc	egacexit
		mov	grafnum,ax
		mov	ax,dx
		mov	bx,bp
egacexit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

egacheck	Endp

;{----------------------------------------------------------------------}
;{	vgacheck:							}
;{----------------------------------------------------------------------}
vgacheck	Proc	near

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	bp,ax
		mov	si,bx
		mov	ax,1a00h
		int	VideoIO
		cmp	al,1ah
		clc
		jne	@@3		; no vga present
		cmp	bl,08
		je	@@1
		cmp	bh,08		; see if color vga present
		clc
		jne	@@3
@@1:
		mov	ah,12h
		mov	bl,10h
		int	Videoio			; get video configuration
		cmp	card1_found,NONE
		jne	@@2
		mov	card1_found,VGA_CARD	; set ega card was found
@@2:
		mov	ax,cs
		mov	bx,offset vgamodes
		call	testgmode
		jnc	@@3
		mov	grafnum,ax
		mov	ax,dx
		mov	bx,bp
@@3:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

vgacheck	Endp

;{----------------------------------------------------------------------}
;{	mcgacheck:							}
;{	  check for mcga present in system				}
;{----------------------------------------------------------------------}
mcgacheck	Proc	near

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	bp,ax
		mov	si,bx
		mov	ax,1a00h
		int	VideoIO
		cmp	al,1ah
		clc
		jne	@@3
		cmp	bl,0ah
		je	@@1
		cmp	bl,0ch			; test for inactive or active
		je	@@1
		cmp	bh,0ah
		je	@@1
		cmp	bh,0ch
		je	@@1
		cmp	bl,8
		je	@@1
		cmp	bh,8
		clc
		jne	@@3
@@1:
		cmp	card1_found,NONE
		jne	@@2
		mov	card1_found,MCGA_CARD	; set mcga card was found
@@2:
		mov	ax,cs
		mov	bx,offset mcgamodes
		call	testgmode
		jnc	@@3
		mov	grafnum,ax
		mov	ax,dx
		mov	bx,bp
@@3:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

mcgacheck	Endp

;{----------------------------------------------------------------------}
;{	tandycheck:							}
;{	  check for presence of tandy modes				}
;{----------------------------------------------------------------------}
tandycheck	Proc	near

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	bp,ax
		mov	si,bx

		mov	ax,0580h		; read crt/cpu page number
		mov	bx,-1			; can't be this value?
		Int	VideoIO
		rcl	bx,1			; if high bit still set
		cmc
		jnc	@@2
		cmp	card1_found,NONE
		je	@@1
		mov	card1_found,TANDY_CARD	; set tandy card was found
@@1:

		mov	ax,cs
		mov	bx,offset tandymodes
		call	testgmode
		jnc	@@2
		mov	grafnum,ax
		mov	ax,dx
		mov	bx,bp
@@2:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

tandycheck	Endp

;{----------------------------------------------------------------------}
;{	find6845:							}
;{	  detect presence of 6845 controller				}
;{	  dx = controller port to check					}
;{	  out:								}
;{	    c = 1 if found						}
;{----------------------------------------------------------------------}
find6845	Proc	near

		push	ax
		push	bx
		push	cx
		push	dx

		mov	al,0fh
		out	dx,al
		inc	dx

		in	al,dx
		mov	ah,al
		inc	al
		mov	bl,al
		out	dx,al

		mov	cx,100h
@@1:
		loop	@@1
		in	al,dx
		xchg	ah,al
		out	dx,al
		cmp	ah,bl
		stc
		je	@@2
		clc
@@2:
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		
		ret

find6845	Endp

;{----------------------------------------------------------------------}
;{	monocheck:							}
;{	  check for monochrome setup					}
;{----------------------------------------------------------------------}
monocheck	Proc	near

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	bp,ax
		mov	si,bx
		mov	dx,index_6845
		call	near ptr find6845
		jnc	@@2
		cmp	card1_found,NONE
		jne	@@1
		mov	card1_found,MONO_CARD	; set mono is primary card 
		jmp	@@2
@@1:
		mov	card2_found,MONO_CARD	; set mono is secondary card
@@2:
		mov	ax,cs
		mov	bx,offset monomodes
		call	near ptr testgmode
		jnc	@@3
		mov	grafnum,ax
		mov	ax,dx
		mov	bx,bp
@@3:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

monocheck	EndP


;{----------------------------------------------------------------------}
;{	nvgacheck:							}
;{	  Check for presence of vga to see if this mode is		}
;{	  avialable.							}
;{----------------------------------------------------------------------}
nvgacheck	Proc	near

		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es

		mov	bp,ax
		mov	si,bx
		cmp	card1_found,VGA_CARD
		clc
		jne	@@2
		mov	ax,cs
		mov	bx,offset nvgamodes
		call	testgmode
		jnc	@@2
		mov	grafnum,ax
		mov	ax,dx
		mov	bx,bp
@@2:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		ret

nvgacheck	Endp

detect		ends

		end	Entry

