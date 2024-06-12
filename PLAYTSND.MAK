INC =

.asm.obj:
	tasm /zi $<

playtsnd.exe: playtsnd.obj memory.obj dos.obj sound.obj
	tlink /v playtsnd+memory+dos+sound
#
playtsnd.obj:



	

