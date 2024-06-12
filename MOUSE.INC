;{----------------------------------------------------------------------}
;{	MOUSE.inc mouse equates						}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

mouseinc	equ	1

		ifndef	eventsinc
		include	events.inc
		endif

		ifndef	objectinc
		include	object.inc
		endif

;
; -----	Mouse Interrupt Numbers
;
MOUSEINT	equ	33h
;
;	functions
;
MRESET		equ	0
MSHOWCUR	equ	1
MHIDECUR	equ	2
MGETINFO	equ	3
MSETCURPOS	equ	4
MGETBUTPRESS	equ	5
MGETBUTRELEASE	equ	6
MSETMINMAXH	equ	7
MSETMINMAXV	equ	8
MSETGRCURBLK	equ	9
MSETTXTCUR	equ	10
MREADMCOUNTERS	equ	11
MSETINTADDR	equ	12
MSETLPENON	equ	13
MSETLPENOFF	equ	14
MSETMICRATIO	equ	15
MSETCONDOFF	equ	16
MSETDSPDTHRES	equ	19
MSWAPINTRTNS	equ	20
MGETMDSSTORREQ	equ	21
MSAVEMDS	equ	22
MRESTMDS	equ	23
MSETALTRTN	equ	24
MGETUSRINT	equ	25
MSETMSENS	equ	26
MGETMSENS	equ	27
MSETMINTRATE	equ	28
MSETCRTPAGENUM	equ	29
MGETCRTPAGENUM	equ	30
MDISABLE	equ	31
MENABLE		equ	32
MSOFTRESET	equ	33
MSETLANG	equ	34
MGETLANGNUM	equ	35
MGETDRVVER	equ	36

;
; ----- messages from mouse hardware
;
HWMOUSEMOVEMENT	equ	1
HWMBUTTON1PRESS	equ	2
HWMBUTTON1RELEASE equ	4
HWMBUTTON2PRESS	equ	8
HWMBUTTON2RELEASE equ	16
HWMBUTTON3PRESS	equ	32
HWMBUTTON3RELEASE equ	64
;
; ---- mouse device equates
;
MOUSEMOVEMENT	equ	1
MBUTTON1PRESS	equ	2
MBUTTON1RELEASE	equ	3
MBUTTON2PRESS	equ	4
MBUTTON2RELEASE	equ	5
MBUTTON3PRESS	equ	6
MBUTTON3RELEASE	equ	7

;
; -----	global definitions
;
		global	showMouse:far, hideMouse:far,FindMouseDriver:far
		global	ReadMouse:far, UninstallMouse:far,mousegch:far
		global	initmouse:far, _mouseX:word, _mouseY:word
		global	_mousePtr:dword, _oldMousePtr:dword



