;{----------------------------------------------------------------------}
;{	textedit.inc text edit interface definitions			}
;{	COPYRIGHT 1993 Futurescape Productions Inc.			}
;{----------------------------------------------------------------------}

		ifndef	EQUATESINC
		include	equates.inc
		endif

TEXTEDITINC	equ	1

		ifndef	DIALOGINC
		include	dialog.inc
		endif

		ifndef	EVENTSINC
		include	events.inc
		endif

		ifndef	OBJECTINC
		include	object.inc
		endif

		ifndef	TIMERINC
		include	timer.inc
		endif

		ifndef	KEYBOARDINC
		include	keyboard.inc
		endif

		ifndef	SOUNDINC
		include	sound.inc
		endif

;
; ---- text edit device equates
;
TEXTEDITESCAPE	equ	1
TEXTEDITENTER	equ	2
TEXTEDITMOVELT	equ	3
TEXTEDITMOVERT	equ	4
TEXTEDITMOVEUP	equ	5
TEXTEDITMOVEDN	equ	6
TEXTEDITDEL	equ	7
TEXTEDITBS	equ	8
TEXTEDITPGUP	equ	9
TEXTEDITPGDN	equ	10
TEXTEDITHOME	equ	11
TEXTEDITEND	equ	12
TEXTEDITINS	equ	13
TEXTEDITTAB	equ	14
TEXTEDITNORMKEY	equ	15

;
; -----	global definitions
;

		global	_textCursorOn:byte, _textCursorPtr:dword
		global	_textCursorRate:word, _textCursorBlink:byte
		global	_textCursorX:word, _textCursorY:word, _EditText:far

