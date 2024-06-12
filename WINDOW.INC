
windowinc	equ	1

		ifndef objectinc
		include object.inc
		endif

		ifndef keyboardinc
		include keyboard.inc
		endif

		ifndef mouseinc
		include mouse.inc
		endif

		ifndef refreshinc
		include	refresh.inc
		endif

		ifndef debuggerinc
		include debugger.inc
		endif

		ifndef mallocinc
		include mymalloc.inc
		endif

;
; ----- bit definitions for windows
;
WIN_DRAW	equ	1
WIN_TITLE_BAR	equ	2
WIN_CLOSE_BM	equ	4
WIN_VSCROLL	equ	8
WIN_HSCROLL	equ	16
WIN_SIZE_BM	equ	32
WIN_WORK_AREA	equ	64
;
; ----- object id's
;
WIN_TITLE_BAR_ID 	equ	2 OR 8000h
WIN_TITLE_STR_ID	equ	3 OR 8000h	; next available # past bit definition
WIN_CLOSE_ID		equ	5 OR 8000h	
WIN_VSCROLL_ID		equ	8 OR 8000h
WIN_VSCROLL_BAR_ID	equ	9 OR 8000h
WIN_HSCROLL_ID		equ	16 OR 8000h	
WIN_HSCROLL_BAR_ID	equ	17 OR 8000h	; 8000h makes system id's
WIN_SIZE_ID		equ	33 OR 8000h	
WIN_WORK_AREA_ID 	equ	64 OR 8000h


;
; -----	window events message #
;
WINDOW_REDRAW_WS equ	1		; redraw window's work space
WINDOW_CLOSE	equ	2
WINDOW_RESIZE	equ	3
WINDOW_MOVE	equ	4
WINDOW_VS_UP	equ	5		; vertical scroll up arrow
WINDOW_VS_DOWN	equ	6
WINDOW_VS_BAR	equ	7		; clicked in vertical scroll bar
WINDOW_HS_LEFT	equ	8		; horizontal left arrow 
WINDOW_HS_RIGHT	equ	9
WINDOW_HS_BAR	equ	10
WINDOW_TO_TOP	equ	11		; bring window to top
WINDOW_TO_BACK	equ	12		; put window in back
WINDOW_MOUSE_MOVE equ	13		; mouse movement in window area
WINDOW_MOUSE_CLICK equ	14		; mouse click in window area
WINDOW_KEY_PRESS  equ	15		; keyboard press for window
WINDOW_KEY_RELEASE equ	16		; keyboard release for window
WINDOW_COOKED_KEY equ	17		; window dos cooked key pressed
WINDOWITEMPRESS	equ	18		; window item was pressed
WINDOWITEMRELEASE equ	19		; window item was released
WINDOW_SYSREDRAW equ	20		; system entire rectangle redraw
WINDOW_START_RESIZE equ	21		; start windowing resize
WINDOW_END_RESIZE equ	22		; end windowing resizing
WINDOW_START_MOVE equ	23		; start windowing movement
WINDOW_END_MOVE	equ	24		; end windowing movement


;
; ----- window error messages
;
INVALID_WINDOW_HANDLE	equ	-10	; invalid window handle
NO_TITLE_BAR_FOUND	equ	-11	; couldn't find title bar in search

;
;
;
MINWINDOWHEIGHT	equ	36

;
;
;
winHeader	struc

winID		db	4 dup (?)	; 'WIND' id for window type
winX		dw	?
winY		dw	?
winW		dw	?
winH		dw	?
winNext		dw	?		; next window handle
winPrevious	dw	?		; previous window handle
winOffset	dw	?		; current structure malloced offset
winProcPtr	dd	?		; procedure & paramter structure
winParmsPtr	dd	?		; parameter(s) pointer
winReserved	db	6 dup (?)	; pad to segment size
winHeader	ends

;
; -----	global's for window.asm
;

		global	_makeWindow:far, makeWindow:far
		global	_DefWindProc:far, _SummonWinToTop:far
		global	_setWinTitle:far, _DrawWindow:far
		global	_winHandle:word, _startWinHandle:word



