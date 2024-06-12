;{----------------------------------------------------------------------}
;{	FILEDLG.inc file dialog interface definitions			}
;{	COPYRIGHT 1992 Futurescape Productions Inc.			}
;{----------------------------------------------------------------------}

		ifndef	EQUATESINC
		include	equates.inc
		endif

FILEDLGINC	equ	1

		ifndef	DIALOGINC
		include	dialog.inc
		endif

		ifndef	OBJECTINC
		include	object.inc
		endif

		ifndef	MOUSEINC
		include	mouse.inc
		endif

		ifndef	TEXTEDITINC
		include	textedit.inc
		endif

;
; -----	global definitions
;

		global	fileDialog:far, _fileDialog:far
