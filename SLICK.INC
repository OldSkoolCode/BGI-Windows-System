
FILE_MENU	equ	2000
FILE_NEW_B	equ	2001
FILE_LOAD_B	equ	2002
FILE_SAVE_B	equ	2003
FILE_QUIT	equ	2005

menuobject	dw	16
		object	<0, 0, 320, 12, OBJ_BAR, 0, 0, bar1>
		object	<0, 0, 319, 0, OBJ_LINE, 0, 0, line1>
		object	<0, 1, 0, 11, OBJ_LINE, 0, 0, line1>
		object	<319, 0, 319, 10, OBJ_LINE, 0, 0, line2>
		object	<1, 11, 319, 11, OBJ_LINE, 0, 0, line2>
		object	<-1, -1, 322, 14, OBJ_RECT, 0, 0, rect1>
		object	<4, 1, 36, 10, OBJ_STR, OBJ_MENU_TITLE, FILE_MENU, oStr1>
		object	<8, 12, 192, 98, OBJ_PARENT, \
				OBJ_INVISIBLE OR OBJ_MENU, 0, menu1>
		object	<44, 1, 36, 10, OBJ_STR, OBJ_MENU_TITLE, 0, oStr2>
		object	<44, 12, 72, 58, OBJ_PARENT, \
				OBJ_INVISIBLE OR OBJ_MENU, 0, menu2>
		object	<88, 1, 44, 10, OBJ_STR, OBJ_MENU_TITLE, 0, oStr3>
		object	<88, 12, 144, 28, OBJ_PARENT, \
				OBJ_INVISIBLE OR OBJ_MENU, 0, menu3>
		object	<140, 1, 60, 10, OBJ_STR, OBJ_MENU_TITLE, 0, oStr4>
		object	<140, 12,88, 28, OBJ_PARENT, \
				OBJ_INVISIBLE OR OBJ_MENU, 0, menu4>
		object	<208, 1, 52, 10, OBJ_STR, OBJ_MENU_TITLE, 0, oStr5>
		object	<208, 12, 88, 28, OBJ_PARENT, \
				OBJ_INVISIBLE OR OBJ_MENU, 0, menu5>
menu1		dw	15
		object	<0, 0, 192, 98, OBJ_RECT, 0, 0, rect1>
		object	<1, 1, 190, 96, OBJ_BAR, 0, 0, bar1>
		object	<1, 1, 190, 1, OBJ_LINE, 0, 0, line1>
		object	<1, 2, 1, 96, OBJ_LINE, 0, 0, line1>
		object	<190, 1, 190, 96, OBJ_LINE, 0, 0, line2>
		object	<2, 96, 190, 96, OBJ_LINE, 0, 0, line2>
		object	<4, 4, 184, 10, OBJ_STR, OBJ_MENU_ITEM,\
				FILE_NEW_B, oStr1a>
		object	<4, 14, 184, 10, OBJ_STR, OBJ_MENU_ITEM,\
				FILE_LOAD_B, oStr1b>
		object	<4, 24, 184, 10, OBJ_STR, OBJ_MENU_ITEM,\
				FILE_SAVE_B, oStr1c>
		object	<4, 34, 184, 10, OBJ_STR, \
				OBJ_MENU_ITEM OR OBJ_DISABLED, 0, oStr1d>
		object	<4, 44, 184, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr1e>
		object	<4, 54, 184, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr1f>
		object	<4, 64, 184, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr1g>
		object	<4, 74, 184, 10, OBJ_STR, \
				OBJ_MENU_ITEM OR OBJ_DISABLED, 0, oStr1h>
		object	<4, 84, 184, 10, OBJ_STR, OBJ_MENU_ITEM, \
				FILE_QUIT, oStr1i>

menu2		dw	11
		object	<0, 0, 72, 58, OBJ_RECT, 0, 0, rect1>
		object	<1, 1, 70, 56, OBJ_BAR, 0, 0, bar1>
		object	<1, 1, 70, 1, OBJ_LINE, 0, 0, line1>
		object	<1, 2, 1, 56, OBJ_LINE, 0, 0, line1>
		object	<70, 1, 70, 56, OBJ_LINE, 0, 0, line2>
		object	<2, 56, 70, 56, OBJ_LINE, 0, 0, line2>
		object	<4, 4, 64, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr2a>
		object	<4, 14, 64, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr2b>
		object	<4, 24, 64, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr2c>
		object	<4, 34, 64, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr2d>
		object	<4, 44, 64, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr2e>

menu3		dw	8
		object	<0, 0, 144, 28, OBJ_RECT, 0, 0, rect1>
		object	<1, 1, 142, 26, OBJ_BAR, 0, 0, bar1>
		object	<1, 1, 142, 1, OBJ_LINE, 0, 0, line1>
		object	<1, 2, 1, 26, OBJ_LINE, 0, 0, line1>
		object	<142, 1, 142, 26, OBJ_LINE, 0, 0, line2>
		object	<2, 26, 142, 26, OBJ_LINE, 0, 0, line2>
		object	<4, 4, 136, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr3a>
		object	<4, 14, 136, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr3b>

menu4		dw	8
		object	<0, 0, 88, 28, OBJ_RECT, 0, 0, rect1>
		object	<1, 1, 86, 26, OBJ_BAR, 0, 0, bar1>
		object	<1, 1, 86, 1, OBJ_LINE, 0, 0, line1>
		object	<1, 2, 1, 26, OBJ_LINE, 0, 0, line1>
		object	<86, 1, 86, 26, OBJ_LINE, 0, 0, line2>
		object	<2, 26, 86, 26, OBJ_LINE, 0, 0, line2>
		object	<4, 4, 80, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr4a>
		object	<4, 14, 80, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr4b>

menu5		dw	8
		object	<0, 0, 88, 28, OBJ_RECT, 0, 0, rect1>
		object	<1, 1, 86, 26, OBJ_BAR, 0, 0, bar1>
		object	<1, 1, 86, 1, OBJ_LINE, 0, 0, line1>
		object	<1, 2, 1, 26, OBJ_LINE, 0, 0, line1>
		object	<86, 1, 86, 26, OBJ_LINE, 0, 0, line2>
		object	<2, 26, 86, 26, OBJ_LINE, 0, 0, line2>
		object	<4, 4, 80, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr5a>
		object	<4, 14, 80, 10, OBJ_STR, OBJ_MENU_ITEM, 0, oStr5b>

rect1		objRect	<0, 0, REPLACE_MODE>
bar1		objBar	<0, 7, REPLACE_MODE, 1, 0>
line1		objLine	<0, 0fh, REPLACE_MODE, 0, 0>
line2		objLine	<0, 8, REPLACE_MODE, 0, 0>
line3		objLine	<0, 0, REPLACE_MODE, 0, 0>
oStr1		objStr	<2, 1, 0, 0, 8, 7, XPARENT_MODE, string1>
oStr1a		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string1a>
oStr1b		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string1b>
oStr1c		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string1c>
oStr1d		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string1d>
oStr1e		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string1e>
oStr1f		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string1f>
oStr1g		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string1g>
oStr1h		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string1h>
oStr1i		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string1i>
oStr2		objStr	<2, 1, 0, 0, 8, 7, XPARENT_MODE, string2>
oStr2a		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string2a>
oStr2b		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string2b>
oStr2c		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string2c>
oStr2d		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string2d>
oStr2e		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string2e>
oStr3		objStr	<2, 1, 0, 0, 8, 7, XPARENT_MODE, string3>
oStr3a		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string3a>
oStr3b		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string3b>
oStr4		objStr	<2, 1, 0, 0, 8, 7, XPARENT_MODE, string4>
oStr4a		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string4a>
oStr4b		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string4b>
oStr5		objStr	<2, 1, 0, 0, 8, 7, XPARENT_MODE, string5>
oStr5a		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string4a>
oStr5b		objStr	<0, 1, 0, 0, 8, 7, XPARENT_MODE, string4b>

string1		db	'~File',0
string1a	db	' ~New Background      N',0
string1b	db	' ~Load Background...  L',0
string1c	db	' ~Save Background...  S',0
string1d	db	'-----------------------',0
string1e	db	' N~ew Map            ',143,'N ',0
string1f	db	' L~oad Map...        ',143,'L ',0
string1g	db	' S~ave Map...        ',143,'S ',0
string1h	db	'-----------------------',0
string1i	db	' Quit                  ',0

string2		db	'~Edit',0
string2a	db	' Undo   ',0
string2b	db	' Copy   ',0
string2c	db	' Paste  ',0
string2d	db	' Delete ',0
string2e	db	' Cut    ',0

string3		db	'~Tiles',0
string3a	db	' Load Tileset... ',0
string3b	db	' Save Tileset... ',0

string4		db	'~Options',0
string4a	db	' ?????????',0
string4b	db	' ?????????',0

string5		db	'~Sprite',0
string5a	db	' ?????????',0
string5b	db	' ?????????',0

