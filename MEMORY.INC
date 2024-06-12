;{----------------------------------------------------------------------}
;{	MEMORY.inc memory definitions					}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

		ifndef	equatesinc
		include	equates.inc
		endif

memoryinc	equ	1

		ifndef	dosinc
		include	dos.inc
		endif

;
; -----	taken from MSdos error numbers
;
EMEMCBD		equ	-7	; memory control block destroyed
EINSMEM		equ	-8	; insufficient memory
EMEMBLINV	equ	-9	; memory block invalid
;
; -----	Internal memory control block structure to GRACE
;	GRACE handles memory more effeciently than DOS
;

MCB		struc

MCBkeyword	dw	?	; 'AM' = allocated memory "FM' = free memory
				; 'LM' = last memory block
MCBnext 	dw	?	; link list to next memory control block
MCBprev 	dw	?	; previous memory control block
MCBsize  	dw	?	; size of Memory control block including header
MCBreserved	dw	4 dup (?) ; reserved for future expansion

MCB		Ends

BiosActiveMonitor	equ 410h
VideoIO		equ	10h
;
; -----	at start up several modules need to be initialized before
;	their routines can be called the initialize routines are set
;	up in a segment called INITSTART.  Each entry in this segment
;	contains an identifier of GRIN or Grace Initialization.  If
;	this identifier isn't present Grace will assume there are no more
;	entries into this table.  Priority is the priority of the 
;	initialization routine. 0 being the lowest and 65535 being the 
;	highest.  Normally this should be set to 32767.
;

Executehead	struc
identifier	db	4 dup (?)
priority	dw	?
routine		dd	?		; far call to routine to initialize
misc		db	6 dup (?)	; miscellaneous parameters
Executehead	Ends

;
; -----	global definitions
;

		global	membptrs:word,savetprog:word,topprog:word
		global	topmem:word,malloc:far,ExecuteRtns:far
		global	mfree:far,mfreeall:far,mshrink:far
		global	init:far,pspseg:word,pspcurptr:word,temptop:word
		global	endstack:byte,topused:word,pspseg:word
		global	oldvmode:byte, oldvmonitor:byte, ShellSort:far
		global	_exittext:far,setctrlcvector:far,cleanup:far
		global	_initGRACE:far,	_InstallSystem:far, memcpy:far
		global	SortRtns:far


