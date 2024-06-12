;{----------------------------------------------------------------------}
;{	DIALOG.inc menus interface definitions				}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

dialoginc	equ	1	

		ifndef	objectinc
		include	object.inc
		endif

		ifndef	mouseinc
		include	mouse.inc
		endif

		ifndef	keyboardinc
		include	keyboard.inc
		endif

		ifndef	refreshinc
		include	refresh.inc
		endif

		ifndef mallocinc
		include mymalloc.inc
		endif

;
; -----	dialog object events
;
DIALOGSELECT	equ	1
DIALOGDESELECT	equ	2
DIALOGMOUSEMOVE	equ	3
DIALOGITEMSELECT equ	4
DIALOGITEMDESELECT equ	5
DIALOGITEMRELEASE equ	6
DIALOGITEMPRESS	equ	7
DIALOGCLOSE	equ	8

;
;
;
DIALOG_OK_BIT	equ	1
DIALOG_CANCEL_BIT equ	2
DIALOG_ICON_BIT	equ	4
;
; -----	global definitions
;

		global	alert:far, dialogX:word, dialogY:word, dialogW:word
		global	dialogH:word, sysDialogBar:objBar, fileDialog:far
		global	_alert:far, doDialog:far
