

.asm.obj:
	tasm /zi $<



convert.exe: convert.obj
	tlink /v convert,,,olib.lib
