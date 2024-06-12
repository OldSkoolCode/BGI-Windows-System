;{----------------------------------------------------------------------}
;{	REFRESH.INC for window refresh routines				}
;{	COPYRIGHT 1993 Futurescape Productions Inc.			}
;{----------------------------------------------------------------------}


refreshinc	equ	1

		ifndef objectinc
		include object.inc
		endif

		ifndef keyboardinc
		include keyboard.inc
		endif

		ifndef mouseinc
		include mouse.inc
		endif

		ifndef windowinc
		include window.inc
		endif

		ifndef	debuggerinc
		include	debugger.inc
		endif

;
; ----- background device sub-codes
;
REDRAW_SYSRECT	equ	1
BACK_SYSREDRAW	equ	2

;
; -----	Global's for this module
;
		global	_refreshRect:far, _RectangleUnion:far
		global	_Refresh1Object:far, _RectangleExclusion:far
		global	workRect:Rect,tempRect:Rect, RectangleUnion:far
