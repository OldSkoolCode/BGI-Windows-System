;{----------------------------------------------------------------------}
;{	EQUATES.inc general file to include everything			}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

		nowarn	PDC
		warn	ALN
		jumps

equatesinc	equ	1

TIMERA		equ	1ah
PORTBOUT	equ	61h

DEBUG		equ	1
;
; -----	Some other misceallneous equates
;
CR		equ	0dh
LF		equ	0ah
TAB		equ	09h
FALSE		equ	0
TRUE		equ	NOT FALSE

;{----------------------------------------------------------------------}
;{	macro subsection						}
;{----------------------------------------------------------------------}

;
; -----	pushall pushes all the registers
;
pushall		Macro

		push	bx
		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	es
		push	ds

		EndM

; -----	popall pops all the registers off the stack
popall		Macro

		pop	ds
		pop	es
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		pop	bx

		EndM

;
; -----	GetRword gets reversed word from files that store words
;	high to low order
;

GetRWord	Macro	reg1,wherefrom

		if (("&reg1" eq "AX") or ("&reg1" eq "ax") or ("&reg1" eq "Ax") or ("&reg1" eq "aX"))
		mov	ax,wherefrom
		xchg	ah,al

		elseif (("&reg1" eq "BX") or ("&reg1" eq "bx") or ("&reg1" eq "Bx") or ("&reg1" eq "bX"))
		mov	bx,wherefrom
		xchg	bh,bl

		elseif (("&reg1" eq "CX") or ("&reg1" eq "cx") or ("&reg1" eq "Cx") or ("&reg1" eq "cX"))
		mov	cx,wherefrom
		xchg	ch,cl

		elseif (("&reg1" eq "DX") or ("&reg1" eq "dx") or ("&reg1" eq "Dx") or ("&reg1" eq "dX"))
		mov	dx,wherefrom
		xchg	dh,dl
		else
		err
		%out	Unusable register &reg1 in macro GetRWord
		endif

		Endm
		

;
; -----	StorRword stores reversed word that are
;	high to low order
;

StorRWord	Macro	whereto,reg1

		if (("&reg1" eq "AX") or ("&reg1" eq "ax") or ("&reg1" eq "Ax") or ("&reg1" eq "aX"))
		xchg	ah,al
		mov	whereto,ax

		elseif (("&reg1" eq "BX") or ("&reg1" eq "bx") or ("&reg1" eq "Bx") or ("&reg1" eq "bX"))
		xchg	bh,bl
		mov	whereto,bx

		elseif (("&reg1" eq "CX") or ("&reg1" eq "cx") or ("&reg1" eq "Cx") or ("&reg1" eq "cX"))
		xchg	ch,cl
		mov	whereto,cx

		elseif (("&reg1" eq "DX") or ("&reg1" eq "dx") or ("&reg1" eq "Dx") or ("&reg1" eq "dX"))
		xchg	dh,dl
		mov	whereto,dx
		else
		.err
		%out	Unusable register &reg1 in macro StorRWord
		endif

		Endm
		

longtopara	macro	reg1,reg2
		shr	reg1,1
		rcr	reg2,1
		shr	reg1,1
		rcr	reg2,1
		shr	reg1,1
		rcr	reg2,1
		shr	reg1,1
		rcr	reg2,1		; make long to paragraph size
		EndM

paratolong	macro	reg1,reg2
		shl	reg1,1
		rcl	reg2,1
		shl	reg1,1
		rcl	reg2,1
		shl	reg1,1
		rcl	reg2,1
		shl	reg1,1
		rcl	reg2,1
		EndM

fartohuge	macro	reg1,segreg
		push	ax
		push	bx
		mov	ax,reg1
		shr	ax,1
		shr	ax,1
		shr	ax,1
		shr	ax,1
		mov	bx,segreg
		add	ax,bx
		mov	segreg,ax
		and	reg1,0fh
		pop	bx
		pop	ax
		endM


;
; ----- modes for BGI write modes
;
REPLACE_MODE	equ	0
XOR_MODE	equ	1
OR_MODE		equ	2
AND_MODE	equ	3
XPARENT_MODE	equ	4
;
; ----- Devices global numbers
;
NULLDEVICE	equ	0
KEYBOARDDEVICE	equ	1
JOYSTICKDEVICE	equ	2
HWTIMERDEVICE	equ	3
TIMERDEVICE	equ	4
HWMOUSEDEVICE	equ	5
MOUSEDEVICE	equ	6
MENUDEVICE	equ	7
WINDOWDEVICE	equ	8
DIALOGDEVICE	equ	9
OBJECTDEVICE	equ	10
TEXTEDITDEVICE	equ	11
REFRESHDEVICE 	equ	12
;
; ----- Debugging Errors
;
INVALID_NUM_PARMS	equ	-100		; invalid # parms sent with msg

