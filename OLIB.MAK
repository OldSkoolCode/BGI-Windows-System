.asm.obj:
		tasm /zi $<
		tlib object.lib +-$*.obj
	
object.lib:	memory.obj dos.obj menu.obj window.obj filedlg.obj\
		sound.obj dialog.obj mouse.obj object.obj\
		keyboard.obj timer.obj events.obj\
		textedit.obj math.obj rast.obj refresh.obj debugger.obj\
		mymalloc.obj 

memory.obj:	memory.inc equates.inc
dos.obj: 	dos.inc equates.inc
ilbm.obj:	ilbm.inc equates.inc
menu.obj:	menu.inc object.inc equates.inc
sound.obj:	sound.inc math.inc equates.inc
mobs.obj:	mobs.inc equates.inc
refresh.obj:	refresh.inc equates.inc
dialog.obj:	dialog.inc menu.inc object.inc equates.inc
filedlg.obj:	filedlg.inc dialog.inc object.inc equates.inc
mouse.obj:	mouse.inc events.inc  equates.inc
object.obj:	object.inc bitmaps.inc equates.inc
window.obj:	object.inc window.inc equates.inc
keyboard.obj:	keyboard.inc equates.inc
joystick.obj:	joystick.inc equates.inc
timer.obj:	timer.inc equates.inc events.inc
events.obj:	events.inc equates.inc
textedit.obj:	textedit.inc equates.inc events.inc
math.obj:	math.inc equates.inc
rast.obj:	rast.inc equates.inc
debugger.obj:	debugger.inc equates.inc
mymalloc.obj:	mymalloc.inc
