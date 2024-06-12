;{----------------------------------------------------------------------}
;{	ILBM.inc ilbm interface definitions				}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}


		ifndef	equatesinc
		include	equates.inc
		endif

ilbminc		equ	1

		ifndef	dosinc
		include	dos.inc
		endif

;
; -----	ILBM structure for Dpaint Files
;
BMHead		struc
BMHeadW		dw	?		; width of raster area
BMHeadH		dw	?		; height of raster area
BMHeadX		dw	?		; x position of raster area
BMHeadY		dw	?		; y position of raster area
BMHeadNplns	db	?		; number of bit planes
BMHeadMask	db	?		; type of masking
BMHeadComp	db	?		; compressed or not
BMHeadpad1	db	?		; for word alignment
BMHeadXparent	dw	?		; transparent color number
BMHeadXaspect	db	?		; x aspect ratio
BMHeadYaspect	db	?		; y aspect ratio
BMHeadPageW	dw	?		; page width
BMHeadPageH	dw	?		; page height
BMHead		ends


;
;
;

		global		loadiff:far,saveiff:far
