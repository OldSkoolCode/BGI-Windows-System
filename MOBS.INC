;{----------------------------------------------------------------------}
;{	MOBS.inc animation object routines				}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

		ifndef	equatesinc
		include	equates.inc
		endif

mobsinc		equ	1

		ifndef	grafinc
		include	graf.inc
		endif

		ifndef	shapsinc
		include shaps.inc
		endif

;
; ----- draw routines # defines
;
R_DRAWSHAPE	equ	0		; just normal draw shape
R_RASCOPY	equ	1		; raster copy image
R_BYTECOPY	equ	2		; byte aligned copy
R_BSDRAWSHAPE	equ	3		; draw shape saving background to buffer

;
; -----	moveable object structure
;
object		struc
obnext		dw	?		; next object pointer
obprev		dw	?		; previous object pointer
obx		dw	?		; current objects x position on screen
oby		dw	?		; current objects y position on screen
obaniptr	dd	?		; current animation sequence pointer
obstat		dw	?		; some object status bits
					; routines can vary these to anything
obpriority	dw	?		; objects priority index

object		ends

;
; -----	path variables structure
;
pathvars	struc
pinitval	dw	?
pathmoves	dw	?
pdelsx		dw	?
pdelsy		dw	?
pdeldx		dw	?
pdeldy		dw	?
pdelse		dw	?
pdelde		dw	?
		ends

;
; -----	global definitions
;
		global	addobject:far,updaobjects:far,killallobjects:far
		global	InitPath:far,MovePath:far,nshpobj:word
		global	doshape:far,SetPriority:far

