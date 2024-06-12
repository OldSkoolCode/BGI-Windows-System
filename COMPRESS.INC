;{----------------------------------------------------------------------}
;{	COMPRESS.inc compression interface definitions			}
;{	COPYRIGHT 1989 Monarch Development				}
;{----------------------------------------------------------------------}

compressinc	equ	1

		ifndef	grafinc
		include	graf.inc
		endif

		ifndef	dosinc
		include	dos.inc
		endif

GRCdatfile	struc
Header		db	"GRCO"		; Grace compressed file
comptech	dw	?		; compression techniques employed
					; bit 0 = Lemple-Ziv
;
; -----	these next 4 bytes are headers for each file
;
Filetype	db	?		; can be almost anything
					; picture,palette,text whatever
					; high bit set indicates no compression
nextoffset	db	3 dup (?)	; next offset is max 3 byte offset
					; if zero end of file then
GRCdatfile	ends

;
; -----	equate subsection
;
; - filetypes or 80h for no compression employed on this section
;
FtypePixHead	equ	1		; picture header
FtypePal	equ	2		; picture palette
FtypePix	equ	3		; picture binary
FtypeText	equ	4		; text file
FtypeName	equ	5		; a filename
FtypeSnd	equ	6		; sound file
FtypeFast	equ	40h		; or this value in for optimizing for
					; speed over compression
;
; - lemple-ziv codes
;
clear		equ	256		;Clear code
eof		equ	257		;End of file marker
firstfree	equ	258		;First free code
maxmax		equ	4096		;Max code + 1

;Hash table entry
hashrec		struc
first		dw	?		; First entry with this value
next		dw	?		; Next entry along chain
char		db	?		; Suffix char
hashrec		ends

;Hash table entry
dhashrec	struc
dnext		dw	?		; prefix code
dchar		db	?		; suffix char
dhashrec	ends


;
; -----	global definitions
;
		global	lzdcompress:far,LZCompress:far,CreateGRCO:far
		global	SaveGRCOFile:far,LZDeCompress:far,SeekGRCOFile:far
		global	OpenGRCOFile:far,LoadGRCOFile:far,grcofnum:word
		global	hashptr:word,actfileptr:word
