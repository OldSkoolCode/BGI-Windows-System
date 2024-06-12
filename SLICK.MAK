#
#
#
#



.asm.obj:
	tasm /zi $<

slick.exe: slick.obj object.lib
	tlink /v slick,,,object

slick.obj: slick.asm slick.inc

