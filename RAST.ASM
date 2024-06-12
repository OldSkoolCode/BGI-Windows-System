; $Header: e:/graphic\RCS\rast.asm_v 1.1 1993/04/23 21:10:21 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	MSDOS raster library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	Written by Kenneth L. Hurley					}
;{	Started	4-1-1989						}
;{	Written with Turbo Assembler ver 1.0				}
;{----------------------------------------------------------------------}

; $Log: rast.asm_v $
; Revision 1.1  1993/04/23  21:10:21  KENH
; Initial revision
;

		include	rast.inc

		locals

DGROUP		GROUP	_DATA
_DATA		Segment Public 'DATA'
_DATA		Ends

crast		Segment Public 'CODE'

		assume	cs:crast, ds:DGROUP

;{----------------------------------------------------------------------}
;{ Function:	copyRaster(COPYRASTER *cpyRastPtr);			}
;{ Description:	copy raster from one place to another			}
;{ Parameters:	cpyRastPtr = pointer to copy raster structure		}
;{ Returns:	.							}
;{----------------------------------------------------------------------}
_copyRaster	Proc	C Far

		uses	si,di,ds,es
		arg	cpyRastPtr:dword

		les	bx,cpyRastPtr
		mov	ax,seg DGROUP
		mov	ds,ax

		callBGI	copyRaster	; do the raster copy

		ret

_copyRaster	Endp

crast		Ends

		end
