;{----------------------------------------------------------------------}
;{	RAST.inc raster equates						}
;{	COPYRIGHT 1993 Futurescape Productions Inc.			}
;{----------------------------------------------------------------------}


		ifndef	equatesinc
		include	equates.inc
		endif

rastinc		equ	1

		ifndef	objectinc
		include	object.inc
		endif

;
;
;
		global	_copyRaster:far

