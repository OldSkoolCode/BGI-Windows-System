


		global	theptr:dword

DGROUP		group	mydata

mydata		segment	public	'DATA'

it1		db	40 dup (?)
mydata		ends


myfardata	segment	public	'DATA'

test1data	dw	?
myfardata	ends


		assume	cs:mycode, ds:myfardata

mycode		segment	'CODE'

start:
		mov	ax,seg test1data
		mov	ds,ax

		mov	ax,seg DGROUP
		mov	ds,ax

		call	dword ptr theptr

		mov	ax,4c00h
		int	21h


mycode		ends

		end	start
