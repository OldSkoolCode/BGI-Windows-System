
; $Header$

;{----------------------------------------------------------------------}
;{	MSDOS debugger library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	Written by Kenneth L. Hurley					}
;{	Started	9-14-1993						}
;{	Written with Turbo Assembler ver 1.0				}
;{----------------------------------------------------------------------}

; $Log$
		locals

		include	debugger.inc

DGROUP		GROUP	_DATA
_DATA		Segment Public 'DATA'
_DATA		Ends

cdebugger	Segment Public 'CODE'

		assume	cs:cdebugger,ds:DGROUP,ss:nothing

;{----------------------------------------------------------------------}
;{ Function:	void winDebugger(int msgNumber);			}
;{ Description:	'C' callable debugger part of grace			}
;{ Parameters:	msgNumber = error message #				}
;{ returns:	.							}
;{----------------------------------------------------------------------}
_winDebugger	Proc C far

		arg	msgNumber:word

		mov	ax,msgNumber		; get error message
		call	far ptr WinDebugger
		ret

_winDebugger	Endp

;{----------------------------------------------------------------------}
;{ Function:	winDebugger						}
;{ Description:	debugger part of grace					}
;{ Parameters:	msgNumber = error message #				}
;{ returns:	.							}
;{----------------------------------------------------------------------}
WinDebugger	Proc	far

		ret

winDebugger	Endp


cdebugger	Ends

		end
