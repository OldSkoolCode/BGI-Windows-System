; $Header$
;{----------------------------------------------------------------------}
;{	MSDOS malloc library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

;
; $Log$
;
		locals

		include	mymalloc.inc

DGROUP		GROUP	_DATA

_DATA		Segment Public 'DATA'
_DATA		Ends

		assume	cs:_TEXT,ds:DGROUP


_TEXT		segment word public 'CODE'

;{----------------------------------------------------------------------}
;{	void far *_myfarmalloc(long size)				}
;{	  allocate memory of size bytes					}
;{									}
;{	parameters:							}
;{	  size = number of bytes to allocate				}
;{									}
;{	returns:							}
;{	  far pointer to allocated memory				}
;{----------------------------------------------------------------------}
_myfarmalloc	Proc	C far

		arg	insize:dword
		uses	ds,es

		mov	ax,word ptr insize+2
		mov	bx,word ptr insize
		push	ax
		push	bx
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	ax,seg __MMODEL
		mov	es,ax
		test	es:__MMODEL,8000h
		je	@@ShortCall
		push	cs
@@ShortCall:
		call	near ptr _farmalloc
		pop	cx
		pop	cx

		ret

_myfarmalloc	Endp

;{----------------------------------------------------------------------}
;{	void _myfarfree(void far *memPtr)				}
;{	  free memory alloced previously				}
;{									}
;{	parameters:							}
;{	  memPtr = void far pointer to allocated memory			}
;{									}
;{----------------------------------------------------------------------}
_myfarfree	Proc	C far

		arg	memPtr:dword
		uses	ds,es

		mov	ax,word ptr memPtr+2
		mov	bx,word ptr memPtr
		push	ax
		push	bx
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	ax,seg __MMODEL
		mov	es,ax
		test	es:__MMODEL,8000h
		je	@@ShortCall
		push	cs
@@ShortCall:
		call	near ptr _farfree
		pop	cx
		pop	cx
		ret
		
_myfarfree	Endp

_TEXT		Ends


		end
