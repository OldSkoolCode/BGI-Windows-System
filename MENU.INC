		ifndef objectinc
		include	object.inc
		endif

MENUINC		equ	1

		ifndef mouseinc
		include mouse.inc
		endif

		ifndef KEYBOARDINC
		include	keyboard.inc
		endif

		ifndef mallocinc
		include mymalloc.inc
		endif
;
; -----	menu device messages
;
MENUSELECT	equ	1
MENUDESELECT	equ	2
MENUMOUSEMOVE	equ	3
MENUITEMSELECT	equ	4
MENUITEMDESELECT equ	5
MENUITEMRELEASE	equ	6

;
; -----	global definitions
;

		global	drawMenuBar:far, freeMenu:far
		global	_drawMenuBar:far, _freeMenu:far
		global	mBarXPos:word, mBarYPos:word, mBarPtr:dword
