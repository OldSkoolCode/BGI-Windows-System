;{----------------------------------------------------------------------}
;{	events.inc device interface definitions				}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

		ifndef	equatesinc
		include	equates.inc
		endif

eventsinc	equ	1

		ifndef	dosinc
		include	dos.inc
		endif



;
;
; -----	graphic parameter change event equates
;
CHGMODE		equ	0
CHGPAGE		equ	5
CHGSCROLLUP	equ	6
CHGSCROLLDOWN	equ	7
CHGPALETTE	equ	0bh

;
; ----- general parameter passing
;
INITMODE	equ	0

;
; ----- globals
;

		global	sortEVHA:far, addMsgQueue:far, eventManager:far
		global	getMsgQueue:far,waitForEvent:far,getTempMsgWord:far
		global	sendMessage:far, getMsgBuff:far, tMsgQueue:word:16
		global	addMsgBuff:far, getTempMsgBuff:far, _getTempMsgBuff:far
		global	clearMessageParms:far, _eventManager:far
		global	_addMsgBuff:far, _addMsgQueue:far, _getTempMsgWord:far

