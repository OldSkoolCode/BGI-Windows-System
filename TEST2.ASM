	ifndef	??version
?debug	macro
	endm
publicdll macro	name
	public	name
	endm
$comm	macro	name,dist,size,count
	comm	dist name:BYTE:count*size
	endm
	else
$comm	macro	name,dist,size,count
	comm	dist name[size]:BYTE:count
	endm
	endif
	?debug	V 301h
	?debug	S "test2.c"
	?debug	C E9796E211D0774657374322E63
	?debug	C E94020CA1C16643A5C4243345C494E434C5544455C737464696F2E+
	?debug	C 68
	?debug	C E94020CA1C16643A5C4243345C494E434C5544455C5F646566732E+
	?debug	C 68
	?debug	C E94020CA1C17643A5C4243345C494E434C5544455C5F6E66696C65+
	?debug	C 2E68
	?debug	C E94020CA1C16643A5C4243345C494E434C5544455C5F6E756C6C2E+
	?debug	C 68
_TEXT	segment byte public 'CODE'
_TEXT	ends
DGROUP	group	_DATA,_BSS
	assume	cs:_TEXT,ds:DGROUP
_DATA	segment word public 'DATA'
d@	label	byte
d@w	label	word
_DATA	ends
_BSS	segment word public 'BSS'
b@	label	byte
b@w	label	word
_BSS	ends
_TEXT	segment byte public 'CODE'
   ;	
   ;	void main(void)
   ;	
	assume	cs:_TEXT,ds:DGROUP
_main	proc	near
	push	bp
	mov	bp,sp
   ;	
   ;	{
   ;	
   ;		printf("Hello world\n");
   ;	
	mov	ax,offset DGROUP:s@
	push	ax
	call	near ptr _printf
	pop	cx
   ;	
   ;	
   ;	}
   ;	
	pop	bp
	ret	
_main	endp
	?debug	C E9
	?debug	C FA00000000
_TEXT	ends
_DATA	segment word public 'DATA'
s@	label	byte
	db	'Hello world'
	db	10
	db	0
_DATA	ends
_TEXT	segment byte public 'CODE'
_TEXT	ends
_s@	equ	s@
	extrn	_printf:near
	public	_main
	end
