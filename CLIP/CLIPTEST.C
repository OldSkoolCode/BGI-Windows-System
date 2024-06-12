/* Cliptest.c, by John Schultz, a modification of: */

/* This is a line drawing demo for the Commodore/Amiga  */
/* Written by	John Riley, Lattice, Inc.		*/
/* 							*/

#include <exec/types.h>
#include <exec/nodes.h>
#include <exec/lists.h>
#include <intuition/intuition.h>
#include <graphics/text.h>
#include <proto/exec.h>
#include <proto/graphics.h>
#include <proto/intuition.h>
#include <hardware/custom.h>

/***************** This is all you need for the FC clipper **************/

typedef struct {short px,py,qx,qy;} line;

extern short __asm clipline(register __a0 line * l);

extern unsigned short far minX,far minY,far maxX,far maxY;

/************************************************************************/

line l;

extern struct Custom far custom;
                                            
USHORT wakeup;	/* Wake me up for event */
USHORT class;	/* Intu event class */
USHORT code;	/* Intu event code */

struct Window *w;
struct RastPort *rp,*cdrp;
struct ViewPort *vp;
struct IntuiMessage *message;
int event(void);
long rand(void);
void srand(int);

/************************ Window Defines ********************************/

struct NewWindow nw = {
		0,0,			/* Starting corner */
		80,40,			/* Width, height */
		2,1,			/* detail, block pens */
	CLOSEWINDOW | NEWSIZE,		/* IDCMP flags */
	WINDOWDEPTH | WINDOWDRAG | WINDOWCLOSE | GIMMEZEROZERO | WINDOWSIZING,
					/* Window flags */
		NULL,			/* Pointer to first gadget */
		NULL,			/* Pointer to checkmark */
		"FC Clipper Test",	/* title */
		NULL,			/* screen pointer */
		NULL,			/* bitmap pointer */
		0,0,640,400,		/* window not sized */
		WBENCHSCREEN		/* type of screen */
		};

int co,xlim,ylim;

short centerx,centery;

main(int argc,char * argv[])
{
  unsigned short linesize,halflinesize;

  if (argc > 1) {
    linesize = atoi(argv[1]);
    if (linesize > 32767) {
      printf("Maximum line size exceeded, using 32767 (max).\n");
      linesize = 32767;
    }
  } else {
    printf("USAGE: cliptest <linesize>\n");
    printf("  using default linesize of 500.\n");
    linesize = 500;
  } 
  halflinesize = linesize >> 1;


/************************ Set-Up routines **********************************/
	GfxBase = (struct GfxBase *)OpenLibrary("graphics.library",0);
	if(GfxBase == NULL) return;
	IntuitionBase = (struct IntuitionBase *)OpenLibrary("intuition.library",0);
	if(IntuitionBase == NULL) 
		{
		CloseLibrary((struct Library *)GfxBase);
		return;
		}
	w = OpenWindow(&nw);
	rp = w->RPort;			/* Get the raster port pointer */
	vp = &w->WScreen->ViewPort;	/* Get the view port pointer */
	SetAPen(rp,3);			/* Set foreground pen to white */
	SetDrMd(rp,JAM1);		/* Draw with foreground pen */

	minX = 0;
	minY = 0;
	maxX = w->Width-1;
	maxY = w->Height-1;

	centerx = w->Width >> 1;
	centery = w->Height >> 1;

	co = 1;
	do {

 /**************************  FC clipper test code *************************/

                srand(custom.vhposr); /* video beam position */
		SetAPen(rp,co);
                co = (co+1) & 3;

                l.px = (rand() & linesize) - halflinesize + centerx;
                l.py = (rand() & linesize) - halflinesize + centery;
                l.qx = (rand() & linesize) - halflinesize + centerx;
                l.qy = (rand() & linesize) - halflinesize + centery;

                if (clipline(&l)) {
                  if ((l.px < minX) || (l.px > maxX)
                   || (l.py < minY) || (l.py > maxY)  
                   || (l.qx < minX) || (l.qx > maxX)
                   || (l.qy < minY) || (l.qy > maxY)) {
                    printf("FC Clip Error.\n");
                  } else {  
                    Move(rp,l.px,l.py);
		    Draw(rp,l.qx,l.qy);
                  }
                }

 /************************** End FC clipper test code ***********************/

		if(w->UserPort->mp_SigBit)
		{
			message = (struct IntuiMessage *)GetMsg(w->UserPort);
			if(message != NULL)
			{
				class = message->Class;
				code = message->Code;
				ReplyMsg((struct Message *)message);
			}
		}
	} while(event());
	CloseWindow(w);
	CloseLibrary((struct Library *)GfxBase);
	CloseLibrary((struct Library *)IntuitionBase);
}

int event()
{
	switch(class)
	{
		case CLOSEWINDOW:
			return(0);
		case NEWSIZE:
		    	maxX = w->Width-1;
			maxY = w->Height-1;
		 	centerx = w->Width >> 1;
			centery = w->Height >> 1;
			return(1);

	}
	return(1);
}
