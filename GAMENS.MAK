.asm.obj:
	tasm $<
	tlib game.lib +-$*.obj
	
gamens.lib: memory.obj dos.obj ilbm.obj graf.obj lines.obj shaps.obj fonts.obj\
	  devs.obj menus.obj scroll.obj compress.obj sound.obj mobs.obj rast.obj\
	  buff.obj refresh.obj

memory.obj: memory.i
dos.obj:  dos.i
ilbm.obj: ilbm.i
graf.obj:  graf.i
lines.obj: lines.i
shaps.obj: shaps.i
fonts.obj: fonts.i
devs.obj: devs.i
menus.obj: menus.i
scroll.obj: scroll.i
compress.obj: compress.i
sound.obj: sound.i
mobs.obj: mobs.i
rast.obj: rast.i
buff.obj: buff.i
refresh.obj: refresh.i
