; $Header: e:/graphic\RCS\menu.asm_v 1.1 1993/04/23 21:07:33 KENH Exp KENH $

;{----------------------------------------------------------------------}
;{	MsDos Menu library routines					}
;{	Copyright 1994 Kenneth L. Hurley				}
;{	written by Kenneth L. Hurley					}
;{	started	9-1-1992						}
;{	written with turbo assembler ver 3.1				}
;{----------------------------------------------------------------------}

; $Log: menu.asm_v $
; Revision 1.1  1993/04/23  21:07:33  KENH
; Initial revision
;

		locals

		include menu.inc

INITEND		Segment Public 'FAR_DATA'

		Executehead	<"GREN",32767,freeMenu>

INITEND		Ends

EVENTHANDLER	Segment	Public 'FAR_DATA'

		Executehead	<"EVHA", 33000, menuDeviceEvent, MOUSEDEVICE>
		Executehead	<"EVHA", 32767, menuSelectEvent, MENUDEVICE>
		Executehead	<"EVHA", 32767, menuDeSelectEvent, MENUDEVICE>
		Executehead	<"EVHA", 32767, menuMouseEvent, MENUDEVICE>
		Executehead	<"EVHA", 32767, menuItemSelEvent, MENUDEVICE>
		Executehead	<"EVHA", 32767, menuItemDeslEvent, MENUDEVICE>
		Executehead	<"EVHA", 32700, menuItemRelEvent, MENUDEVICE>

EVENTHANDLER	Ends

menudseg	segment 'FAR_DATA'

largestX	dw	?
largestY	dw	?
numMenuItems	dw	?
menuBPtr	dd	?
menuBarOn	db	FALSE
menuPopUp	db	FALSE
mBarXPos	dw	?
mBarYPos	dw	?
mBarPtr		dd	?
lastMenuTitle	dw	0
lastMenuItem	dw	-1
tempRect	Rect	<>
mousehidden	dw	?
tMsgBuff	dw	16 dup (?)

menudseg	ends

DGROUP		GROUP 	_DATA

_DATA		segment public 'DATA'
_DATA		ends

menucseg	segment 'CODE'

		assume	cs:menucseg,ds:menudseg

;{----------------------------------------------------------------------}
;{	menuDeviceEvent:						}
;{	  Check for events from devices that affect menus.		}
;{									}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bits							}
;{----------------------------------------------------------------------}
menuDeviceEvent	Proc	Far

		pushall
		cmp	ah,MOUSEDEVICE		; mouse device event?
		jne	NoMenuEvent
		mov	bx,seg menuBarOn
		mov	ds,bx

		cmp	menuBarOn,FALSE
		je	NoMenuEvent
		mov	dx,ax			; save bits for later
		les	si,mBarPtr		; get menu bar pointer
		mov	cx,es:[si]		; get number of items
		add	si,2
		xor	bp,bp
@@MenuLoop:
		test	es:[si].objflags,OBJ_MENU_TITLE
		je	@@NotMenu
@@isMenuTitle:
		push	cx
		push	dx
		mov	cx,seg tempRect
		mov	ds,cx
		mov	di,offset tempRect
		mov	dx,di
		mov	ax,mBarXPos
		mov	bx,mBarYPos
		add	ax,es:[si].objX
		sub	ax,2
		mov	[di].rectX,ax
		add	bx,es:[si].objY
		sub	bx,2
		mov	[di].rectY,bx
		mov	ax,es:[si].objW
		add	ax,4
		mov	[di].rectW,ax
		mov	bx,es:[si].objH
		add	bx,4
		mov	[di].rectH,bx
		assume	ds:DGROUP
		mov	ax,seg DGROUP
		mov	ds,ax
		mov	ax,_mouseX
		mov	bx,_mouseY
		call	far ptr ptInRect	; is mouse in this rectangle?
		assume	ds:menudseg
		pop	dx
		pop	cx
		or	ax,ax
		jne	@@InMenuTitle
@@NotMenu:
		add	si,size object
		inc	bp
		loop	@@MenuLoop
		xor	ax,ax
@@InMenuTitle:
		mov	bx,seg lastMenuTitle
		mov	ds,bx
		cmp	dl,MBUTTON1PRESS	; button 1 pressed
		jne	@@NotMouseButtonDown
		or	ax,ax
		je	usedMenuEvent

		mov	ah,MENUDEVICE
		mov	al,MENUSELECT
		mov	bx,bp
		call	far ptr sendMessage	; send menu select message
		jmp	usedMenuEvent
@@menuDeSelect:
		mov	bx,lastMenuTitle
		or	bx,bx
		je	usedMenuEvent

		mov	bp,bx
		mov	cx,lastMenuItem		; get last item in menu
		mov	ah,MENUDEVICE
		mov	al,MENUDESELECT
		call	far ptr sendMessage	; send menu select message
		cmp	cx,-1
		je	usedMenuEvent

		mov	ax,seg tMsgQueue
		mov	es,ax
		mov	di,offset tMsgQueue
		mov	ah,MENUDEVICE
		mov	al,MENUITEMRELEASE
		stosw
		les	si,mBarPtr
		mov	ax,bp
		mov	bx,size object
		mul	bx			
		add	si,ax
		add	si,2			; bypass # objects
		add	si,size object		; bypass title object
		les	si,es:[si].objptr	; get to menu object
		mov	ax,cx
		mul	bx
		add	si,ax
		add	si,2
		mov	ax,es:[si].objID
		mov	dx,seg tMsgQueue
		mov	es,dx
		stosw
		mov	ax,bp
		stosw
		mov	ax,cx
		stosw
		mov	ax,4
		push	si
		push	ds
		push	es
		pop	ds
		mov	si,offset tMsgQueue
		call	far ptr addMsgBuff
		pop	ds
		pop	si
		jmp	usedMenuEvent
@@NotMouseButtonDown:
		cmp	dl,MBUTTON1RELEASE
		je	@@menuDeSelect
		cmp	dl,MOUSEMOVEMENT
		jne	usedMenuEvent
		or	ax,ax
		je	@@NotInMenuTitle
		mov	ax,seg lastMenuTitle
		mov	ds,ax
		cmp	bp,lastMenuTitle	; see if same title
		je	@@NotInMenuTitle
		cmp	lastMenuTitle,0
		je	@@NotInMenuTitle
		mov	ah,MENUDEVICE
		mov	al,MENUDESELECT
		mov	bx,lastMenuTitle
		call	far ptr sendMessage	; send menu deselect message
		mov	lastMenuTitle,0
		mov	ah,MENUDEVICE
		mov	al,MENUSELECT
		mov	bx,bp
		call	far ptr sendMessage	; send menu select message
@@NotInMenuTitle:
		cmp	lastMenuTitle,0
		je	usedMenuEvent
		mov	ah,MENUDEVICE
		mov	al,MENUMOUSEMOVE
		call	far ptr sendMessage
		jmp	usedMenuEvent
@@NotMouseEvent:
		cmp	dh,KEYBOARDDEVICE
		jne	usedMenuEvent
		cmp	dl,KEYBOARDPRESS
		jne	usedMenuEvent

		mov	ah,UNFCHRIN
		int	MSDOS

		cmp	al,1bh			; escape backs out of menu
		je	@@menuDeSelect
UsedMenuEvent:
		mov	ax,1
		cmp	menuPopUp,TRUE		; if menu up say we took it
		je	@@Exit
NoMenuEvent:
		xor	ax,ax
@@Exit:
		popall
		ret

menuDeviceEvent	Endp

;{----------------------------------------------------------------------}
;{	menuSelectEvent:						}
;{	  process events dealing with selecting menus			}
;{	 								}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bit setting for device					}
;{	  bx = object number						}
;{----------------------------------------------------------------------}
menuSelectEvent Proc	far

		pushall

		cmp	al,MENUSELECT
		jne	NoMenuEvent

		mov	ax,seg menuBarOn
		mov	ds,ax

		cmp	menuBarOn,TRUE		; see if menu bar is on
		jne	NotMenuSelMessage

		call	far ptr hideMouse
		les	si,mBarPtr
		mov	ax,size object
		mul	bx			; mult kills dx
		mov	dx,si
		add	si,ax
		add	si,2			; bypass # objects

  		or	es:[si].objflags,OBJ_SELECTED

		mov	lastMenuTitle,bx
		mov	lastMenuItem,-1

		push	bx
		push	dx
		push	si

		mov	si,bx			; save object number off

		mov	ax,mBarXPos
		mov	bx,mBarYPos

		mov	cx,es

		call	far ptr redrawObject	; redraw menu title

		pop	si
		pop	dx
		pop	bx

		add	si,size object
		test	es:[si].objflags,OBJ_MENU
		je	@@NoPopUp
		and	es:[si].objflags,NOT OBJ_INVISIBLE

		mov	menuPopUp,TRUE

		inc	bx

		push	bx
		push	dx
		push	es
		mov	si,bx
		mov	ax,mBarXPos
		mov	bx,mBarYPos
		mov	cx,es
		les	di,menuBPtr
		call	far ptr savePopUpBack	; save back ground for popup
		pop	es
		pop	dx
		pop	bx

		mov	si,bx
		mov	ax,mBarXPos
		mov	bx,mBarYPos
		mov	cx,es

		call	far ptr redrawObject	; and now draw the object
@@NoPopUp:

		call	far ptr showMouse
NotMenuSelMessage:
		xor	ax,ax
		popall
		ret

menuSelectEvent	Endp

;{----------------------------------------------------------------------}
;{	menuDeSelectEvent:						}
;{	  process events dealing with de-selecting menus		}
;{	 								}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bit setting for device					}
;{	  bx = object number						}
;{----------------------------------------------------------------------}
menuDeSelectEvent Proc	far

		pushall
		cmp	ah,MENUDEVICE
		jne	NotMenuSelMessage
		cmp	al,MENUDESELECT
		jne	NotMenuSelMessage

		mov	bx,seg lastMenuTitle
		mov	ds,bx

		mov	bx,lastMenuTitle
		or	bx,bx
		je	NotMenuSelMessage

		cmp	lastMenuItem,-1
		je	@@NoLastMenuItem
		mov	ah,MENUDEVICE
		mov	al,MENUITEMDESELECT
		mov	bx,lastMenuItem
		call	far ptr sendMessage
@@NoLastMenuItem:

		call	far ptr hideMouse

		mov	bx,lastMenuTitle
		les	si,mBarPtr
		mov	ax,size object
		mul	bx
		mov	dx,si
		add	si,ax
		add	si,2

		and	es:[si].objflags,NOT OBJ_SELECTED

		push	bx
		push	dx
		push	si

		mov	si,bx			; save object number off
		mov	ax,mBarXPos
		mov	bx,mBarYPos
		mov	cx,es

		call	far ptr redrawObject	; redraw menu title

		pop	si
		pop	dx
		pop	bx

		add	si,size object
		test	es:[si].objflags,OBJ_MENU
		je	@@NoPopUp2

		mov	menuPopUp,FALSE
		or	es:[si].objflags,OBJ_INVISIBLE
		inc	bx

		mov	si,bx
		mov	ax,mBarXPos
		mov	bx,mBarYPos
		mov	cx,es
		les	di,menuBPtr
		call	far ptr restorePopUpBack ; restore back ground for popup
@@NoPopUp2:
		call	far ptr showMouse
		mov	lastMenuTitle,0
NotMenuDeselect:
		xor	ax,ax
		popall
		ret

menuDeSelectEvent Endp

;{----------------------------------------------------------------------}
;{	menuMouseEvent:							}
;{	  process events dealing with de-selecting menus		}
;{	 								}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bit setting for device					}
;{	  bx = object number						}
;{----------------------------------------------------------------------}
menuMouseEvent	Proc	far

		pushall
		cmp	ah,MENUDEVICE
		jne	NotMenuDeselect
		cmp	al,MENUMOUSEMOVE
		jne	NotMenuDeselect

		mov	ax,seg menuPopUp
		mov	ds,ax
		cmp	menuPopUp,TRUE		; is menu popped up?
		jne	NotMenuDeselect

		les	si,mBarPtr		; get pointer to menu
		mov	bx,lastMenuTitle
		mov	ax,size object
		mul	bx
		mov	dx,si
		add	si,ax
		add	si,2

		add	si,size object
		test	es:[si].objflags,OBJ_MENU
		je	NotMenuDeselect

		mov	ax,mBarXPos
		mov	bx,mBarYPos
		add	ax,es:[si].objX
		add	bx,es:[si].objY

		les	si,es:[si].objptr	; get pointer to parent struct

		mov	di,si

		mov	cx,es:[si]
		add	si,2
		xor	bp,bp			; starting item
@@MenuItemLoop:
		test	es:[si].objflags,OBJ_MENU_ITEM
		je	@@NextMenuItem
@@IsMenuItem:
		push	ax
		push	bx
		push	cx
		push	ds
		assume	ds:DGROUP
		mov	cx,seg DGROUP
		mov	ds,cx
		mov	cx,_mouseX
		sub	cx,ax
		mov	ax,cx
		mov	cx,_mouseY
		sub	cx,bx
		mov	bx,cx
		mov	cx,es
		mov	dx,si
		call	far ptr ptInRect
		assume	ds:menudseg
		or	ax,ax
		pop	ds
		pop	cx
		pop	bx
		pop	ax
		jne	@@FoundMenuItem
@@NextMenuItem:
		add	si,size object
		inc	bp
		loop	@@MenuItemLoop
		mov	bp,-1
@@FoundMenuItem:
		cmp	bp,lastMenuItem
		je	NotMenuMouse
		mov	ah,MENUDEVICE
		mov	al,MENUITEMDESELECT
		mov	bx,lastMenuItem
		call	far ptr sendMessage
		mov	lastMenuItem,-1

		mov	ah,MENUDEVICE
		mov	al,MENUITEMSELECT
		mov	bx,bp
		call	far ptr sendMessage
NotMenuMouse:
		xor	ax,ax
		popall
		ret

menuMouseEvent	Endp

;{----------------------------------------------------------------------}
;{	menuItemRelEvent:						}
;{	  come here when menu item is selected and mouse is released	}
;{									}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bits for device						}
;{----------------------------------------------------------------------}
menuItemRelEvent Proc	Far

		pushall

		cmp	ah,MENUDEVICE
		jne	@@NotMenuItem
		cmp	al,MENUITEMRELEASE
		jne	@@NotMenuItem

		mov	ax,seg mBarPtr
		mov	ds,ax
		les	si,mBarPtr		; get pointer

		mov	bx,offset tMsgBuff
		mov	cx,3
		call	far ptr getTempMsgBuff

		mov	ax,[bx+2]		; get menu bars title

		mov	cx,size object
		mul	cx
		add	si,ax
		add	si,2

		add	si,size object		; get menu parent

		les	si,es:[si].objptr

		mov	ax,[bx+4]		; and menu item

		mov	cx,size object
		mul	cx
		add	si,ax
		add	si,2			; points to menu item object
		and	es:[si].objflags,NOT OBJ_SELECTED
@@NotMenuItem:
		xor	ax,ax
		popall
		ret

menuItemRelEvent Endp

;{----------------------------------------------------------------------}
;{	menuItemSelEvent:						}
;{	  come here when menu item is selected				}
;{									}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bits for device						}
;{	  bx = object							}
;{----------------------------------------------------------------------}
menuItemSelEvent Proc	Far

		cmp	ah,MENUDEVICE
		jne	@@NotMyEvent
		cmp	al,MENUITEMSELECT
		jne	@@NotMyEvent
		cmp	bx,-1
		je	@@NotMyEvent
		pushall

		mov	cx,seg lastMenuItem
		mov	ds,cx
		mov	lastMenuItem,bx		; save last item selected
		les	si,mBarPtr
		mov	cx,lastMenuTitle
		mov	ax,size object
		mul	cx
		add	si,ax
		add	si,2
		add	si,size object		; bypass menu title
		mov	cx,bx			; save item deselected
		mov	bp,mBarXPos
		mov	bx,mBarYPos		; get menu x & y
		add	bp,es:[si].objX
		add	bx,es:[si].objY
		les	si,es:[si].objptr	; and get pop-up

		mov	di,si

		mov	ax,size object
		mul	cx
		add	si,ax
		add	si,2			; get to item released selected

		test	es:[si].objflags,OBJ_DISABLED
		jne	@@NoItem
		call	far ptr hideMouse
		mov	ax,bp
		or	es:[si].objflags,OBJ_SELECTED
		mov	si,cx
		mov	cx,es
		mov	dx,di
		call	far ptr redrawObject

		call	far ptr showMouse
@@NoItem:
		popall
@@NotMyEvent:
		xor	ax,ax
		ret

menuItemSelEvent Endp

;{----------------------------------------------------------------------}
;{	menuItemDeslEvent:						}
;{	  come here when menu item is deselected			}
;{									}
;{	parameters:							}
;{	  ah = device #							}
;{	  al = bits for device						}
;{	  bx = object							}
;{----------------------------------------------------------------------}
menuItemDeslEvent Proc	Far

		cmp	ah,MENUDEVICE
		jne	@@NotMyEvent
		cmp	al,MENUITEMDESELECT
		jne	@@NotMyEvent
		cmp	bx,-1
		je	@@NotMyEvent
		pushall

		mov	cx,seg mBarPtr
		mov	ds,cx
		les	si,mBarPtr
		mov	cx,lastMenuTitle
		mov	ax,size object
		mul	cx
		add	si,ax
		add	si,2
		add	si,size object		; bypass menu title
		mov	cx,bx			; save item deselected
		mov	bp,mBarXPos
		mov	bx,mBarYPos
		add	bp,es:[si].objX
		add	bx,es:[si].objY
		les	si,es:[si].objptr	; and get pop-up

		mov	di,si
		mov	ax,size object
		mul	cx
		add	si,ax
		add	si,2			; get to item released selected

		test	es:[si].objflags,OBJ_DISABLED
		jne	@@NoItem
		call	far ptr hideMouse
		mov	ax,bp
		and	es:[si].objflags,NOT OBJ_SELECTED
		mov	si,cx
		mov	cx,es
		mov	dx,di
		call	far ptr redrawObject
		call	far ptr showMouse
@@NoItem:
		mov	lastMenuItem,-1
		popall
@@NotMyEvent:
		xor	ax,ax
		ret

menuItemDeslEvent Endp

;{----------------------------------------------------------------------}
;{	int _drawMenuBar(int x, int y, void far *objList);		}
;{	  'C' callable drawMenuBar					}
;{									}
;{----------------------------------------------------------------------}
_drawMenuBar	Proc	C far

		arg	argX:word, argY:word, objList:dword

		mov	ax,argY
		mov	bx,argY
		mov	cx,word ptr objList+2
		mov	dx,word ptr objList
		call	far ptr drawMenuBar
		ret

_drawMenuBar	Endp

;{----------------------------------------------------------------------}
;{	drawMenuBar:							}
;{	  draw a menu bar to the screen	and setup memory for save	}
;{	  save buffer of background.					}
;{									}
;{	parameters:							}
;{	  ax = x position of menu bar					}
;{	  bx = y position of menu bar					}
;{	  cx:dx = pointer to objects that make menu bar tree list	}
;{									}
;{	returns:							}
;{	 ax = 0 if out of memory					}
;{									}
;{----------------------------------------------------------------------}
drawMenuBar	Proc	far


		pushall

		mov	es,cx
		mov	si,dx			; setup pointer to object list

		mov	cx,seg largestX
		mov	ds,cx
		mov	largestX,0
		mov	largestY,0
		mov	mBarXPos,ax
		mov	mBarYPos,bx

		mov	word ptr mBarPtr,si
		mov	word ptr mBarPtr+2,es

		mov	cx,es:[si]		; get number of objects
		add	si,2
		xor	bp,bp			; number of menu items
		
@@MBLoopObjects:
;
; is this a menu item (pop-up)?
;
		test	es:[si].objflags,OBJ_MENU
		je	@@skipObject

		inc	bp
		push	cx
		mov	cx,word ptr es:[si].objptr+2
		mov	dx,word ptr es:[si].objptr
		call	far ptr sizeObjects
		pop	cx

		mov	es:[si].objW,ax
		mov	es:[si].objH,bx		; save width & height
		cmp	ax,largestX
		jle	@@NotBiggestX
		mov	largestX,ax
@@NotBiggestX:
		cmp	bx,largestY
		jle	@@skipObject
		mov	largestY,bx
@@skipObject:
		add	si,size object
		loop	@@MBLoopObjects

		mov	numMenuItems,bp

		mov	ax,seg DGROUP
		mov	ds,ax

		assume	ds:DGROUP

		callBGIUtil bitsperpixel

		mov	bp,ax
		and	bp,7
		mov	cl,ds:[bp+shiftvalues]
		mov	bp,ax
		shr	bp,1
		shr	bp,1
		shr	bp,1
		jne	@@OnlyMult
		mov	bp,1
@@OnlyMult:
		assume	ds:menudseg
		mov	bx,seg largestX
		mov	ds,bx

		mov	ax,largestX
		mul	bp
		shr	ax,cl

		mul	largestY

		add	ax,4
		adc	dx,0			; add width & height words
		push	dx
		push	ax
		call 	far ptr _myfarmalloc	; allocate memory for pop-ups
		pop	cx
		pop	cx

		mov	word ptr menuBPtr,ax
		mov	word ptr menuBPtr+2,dx

		or	ax,dx
		je	@@OutofMem

		call	far ptr hideMouse

		mov	ax,mBarXPos
		mov	bx,mBarYPos

		mov	cx,word ptr mBarPtr+2
		mov	dx,word ptr mBarPtr

		call	far ptr drawObjects	; draw menu bar

		call	far ptr showMouse

		mov	ax,TRUE
		mov	menuBarOn,al
@@OutofMem:
		popall
		ret

drawMenuBar	Endp

;{----------------------------------------------------------------------}
;{	void _freeMenu(void);						}
;{	  'C' callable free up menu background save buffer		}
;{----------------------------------------------------------------------}
_freeMenu	Proc	far
;{----------------------------------------------------------------------}
;{	freeMenu:							}
;{	  free up menu background save buffer				}
;{----------------------------------------------------------------------}
freeMenu	Proc	far

		push	ax
		push	bx
		push	cx
		push	dx
		push	ds

		mov	ax,seg menuBPtr
		mov	ds,ax

		xor	ax,ax
		xor	bx,bx
		xchg	word ptr menuBPtr,bx
		xchg	word ptr menuBPtr+2,ax
		mov	cx,ax
		or	cx,bx
		je	@@NothingAlloced
		push	ax
		push	bx
		call	far ptr _myfarfree
		pop	ax
		pop	ax
@@NothingAlloced:
		mov	menuBarOn,FALSE
		pop	ds
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		xor	ax,ax
		ret

freeMenu	Endp

_freeMenu	Endp

menucseg	ends


		end

