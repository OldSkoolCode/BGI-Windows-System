;{----------------------------------------------------------------------}
;{	MYMALLOC.INC memory allocation definitions			}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

		ifndef	equatesinc
		include	equates.inc
		endif

mallocinc	equ	1



		global	__MMODEL:word, _myfarmalloc:far, _myfarfree:far
		global	_farmalloc:near, _farfree:near

