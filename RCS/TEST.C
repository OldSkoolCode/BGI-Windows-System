head	1.2;
access;
symbols;
locks
	KENH:1.2; strict;
comment	@ * @;


1.2
date	93.04.23.21.56.53;	author KENH;	state Exp;
branches;
next	1.1;

1.1
date	93.04.23.20.47.43;	author KENH;	state Exp;
branches;
next	;


desc
@@


1.2
log
@Take out window until bug fixed
@
text
@// $Header: e:/graphic/RCS/test.c 1.1 1993/04/23 20:47:43 KENH Exp KENH $
//----------------------------------------------------------------------//
//	test.c																					//
//																								//
//	Program to test GRACE (GRAphics Control Environment						//
//	Copyright (C) 1993 Futurescape Productions Inc.								//
//																								//
//----------------------------------------------------------------------//

/*

$Log: test.c $
 * Revision 1.1  1993/04/23  20:47:43  KENH
 * Initial revision
 *

*/

//
// -----	Defines
//
#define	MY_WIN_DEFAULTS	(WIN_DRAW | WIN_TITLE_BAR | WIN_CLOSE_BM | \
									WIN_VSCROLL | WIN_HSCROLL | WIN_SIZE_BM)

//
// -----	Includes
//
#include <stdio.h>
#include <graphics.h>
#include "grace.h"
#include "test.h"

//
// -----	global variables
//
int   GraphDriver;		/* The Graphics device driver		*/
int   GraphMode;		/* The Graphics mode value		*/
int   ErrorCode;		/* Reports any graphics errors		*/
char	far backfName[13] = "*.LBM";
char	far backPath[65]	= "E:\\GRAPHICS\\";
char	far LoadBackStr[] = "Load Background File";

COPYRASTER tempRast = { 312, 200, 
								{ 8, 0, 320, 200, (char far *)0xA0000000},
								{ 0, 0, 320, 200, (char far *)0xA0000000}
							 };

//
//
//

int huge detectMCGA(void)
{
	return(0);

}

void checkerrors(void)
{
  ErrorCode = graphresult();		/* Read result of initialization*/
  if( ErrorCode != grOk ){		/* Error occured during init	*/
    printf(" Graphics System Error: %s\n", grapherrormsg( ErrorCode ) );
    exit( 1 );
  }
}

//
//	INITIALIZE: Initializes the graphics system and reports
//	any errors which occured.
//

void Initialize(void)
{
	GraphMode = installuserdriver("mcga", detectMCGA);

  checkerrors();
  GraphDriver = DETECT; 		/* Request auto-detection	*/
  initgraph( &GraphDriver, &GraphMode, "" );
  checkerrors();

}

void myWndProc(int msgBits)
{
	return(DefWindProc(msgBits));
}

void main()
{

	int	mainWin;

	InstallSystem();
	Initialize();
	initGRACE();
	
	alert(20, 20, "Hello this is a test\n", DIALOG_OK_BIT | DIALOG_ICON_BIT, 
						OBJSTOPICON);


//	mainWin = makeWindow(50, 50, 200, 100, MY_WIN_DEFAULTS, myWndProc);
	

 	drawMenuBar(0, 0, &menuobject);

	alert(40, 40, "Warrick was\n\r here Dude!!!\n\r", DIALOG_CANCEL_BIT, 
						OBJSTOPICON);

	eventManager();


}


int myWinEventHandler(int msgBits, int parm1)
{

	return(0);
}


int myMenuEventHandler(int msgBits, int parm1)
{

	int tbuff[3];
	int button;
	int msgCount;

	switch (msgBits & 0xff)
		{
		case MENUITEMRELEASE:
			msgCount = getTempMsgBuff(tbuff, 3);
//			if (msgCount != 3)
//
			switch (tbuff[0])
				{
				case FILE_QUIT:
					if (alert(75, 75, "Are you sure you\n\rwant to quit?", 
						DIALOG_CANCEL_BIT | DIALOG_OK_BIT | DIALOG_ICON_BIT, 
								OBJSTOPICON) != CANCEL_BUTTON)
						exit(0);				
					break;
				case FILE_LOAD_B:
					fileDialog(backfName, backPath, LoadBackStr);
					break;
				case FILE_SAVE_B:
					alert(75, 75, "Fuck you BOB.!!!!",
							DIALOG_OK_BIT, 0);
					break;

				default:
					alert(75, 75, "That menu item is not\n\rfunctioning yet!!!!",
							DIALOG_OK_BIT, 0);
					break;
				}
			break;
		default:
			break;

		}


	return(0);

}
@


1.1
log
@Initial revision
@
text
@d1 1
a1 1
// $Header$
d12 4
a15 1
$Log$
d101 1
a101 1
	mainWin = makeWindow(50, 50, 200, 100, MY_WIN_DEFAULTS, myWndProc);
d106 1
a106 1
	alert(40, 40, "Test #2\n", DIALOG_OK_BIT | DIALOG_ICON_BIT, 
@
