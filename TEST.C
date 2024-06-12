// $Header: e:/graphic\RCS\test.c 1.2 1993/04/23 21:56:53 KENH Exp KENH $
//----------------------------------------------------------------------//
//	test.c																					//
//																								//
//	Program to test GRACE (GRAphics Control Environment						//
//	Copyright 1993 Futurescape Productions Inc.									//
//																								//
//----------------------------------------------------------------------//

/*

$Log: test.c $
 * Revision 1.2  1993/04/23  21:56:53  KENH
 * Take out window until bug fixed
 *
 * Revision 1.1  1993/04/23  20:47:43  KENH
 * Initial revision
 *

*/

//
// -----	Defines
//
#define	MY_WIN_DEFAULTS	(WIN_DRAW | WIN_TITLE_BAR | WIN_CLOSE_BM | \
									WIN_VSCROLL | WIN_HSCROLL | WIN_SIZE_BM)

#define	MAIN_WIN_DEFAULTS	(WIN_TITLE_BAR | WIN_CLOSE_BM | \
									WIN_VSCROLL | WIN_HSCROLL | WIN_SIZE_BM)

//
// -----	Includes
//
#include <stdio.h>
#include <graphics.h>
#include	<stdlib.h>
#include <alloc.h>
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

int	mainWin = 0;
int	win2 = 0;
int	win3 = 0;
int	winCnt = 0;

int	winArray[100];

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
/*    printf(" Graphics System Error: %s\n", grapherrormsg( ErrorCode ) ); */
    exit( 1 );
  }
}

//
//	INITIALIZE: Initializes the graphics system and reports
//	any errors which occured.
//

void Initialize(void)
{
	GraphMode = installuserdriver("MCGA", detectMCGA);
//  GraphMode = VGAHI;

  checkerrors();
  GraphDriver = DETECT; 		/* Request auto-detection	*/
  initgraph( &GraphDriver, &GraphMode, "" );
  checkerrors();

}


//
//
//
//

int far myWndProc(int msgBits, char far *parm1)
{
	int i;
	if (msgBits == ((WINDOWDEVICE << 8) | WINDOW_CLOSE))
		i = getTempMsgWord();

	if (i == mainWin)
		mainWin = NULL;
	if (i == win2)
		win2 = NULL;

	return(DefWindProc(msgBits));
}

void main()
{
	int	i;

	int tmsgs[10];

//	backPatternCol = 255;
//	backColor = 255;
//	backPattern = LTBKSLASHPATTERN;			/* just for testing */

	Initialize();
	initGRACE();

	mainWin = makeWindow(50, 50, 200, 100, MAIN_WIN_DEFAULTS, myWndProc, NULL);
	setWinTitle(mainWin, "Ken's Main Window", STR_CENTERED);
	DrawWindow(mainWin);
	
 	drawMenuBar(0, 0, &menuobject);

	eventManager();


}


int far myMenuEventHandler(int msgBits)
{

	int tbuff[3];
	int button;
	int msgCount;
	char tstr[80];
	int retVal;

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
					alert(75, 75, "Fuck you Brent.!!!!",
							DIALOG_OK_BIT, 0);
					if (win2)
						SummonWinToTop(win2);
					else
						win2 = makeWindow(25, 25, 100, 150, MY_WIN_DEFAULTS,
													myWndProc, NULL);
					break;

				case OPTION_FREE_MEM:
					sprintf(tstr, "Free Memory:\n\r%ld", farcoreleft());
					alert(75,75, tstr, DIALOG_OK_BIT, 0);
					break;

				case OPTION_NEW_WIN:
					winArray[winCnt++] = makeWindow(40+(winCnt*5), 40+(winCnt*5),
												50, 50 , MY_WIN_DEFAULTS, myWndProc, NULL);
					break;

				default:
					alert(75, 75, "That menu item is not\n\rfunctioning yet!!!!",
							DIALOG_OK_BIT, 0);
					if (mainWin)
						SummonWinToTop(mainWin);
					else {
						mainWin = makeWindow(50, 50, 200, 100, MAIN_WIN_DEFAULTS,
														myWndProc, NULL);
						setWinTitle(mainWin, "Ken's Main Window", STR_CENTERED);
						DrawWindow(mainWin);
					}
					break;
				}
			break;
		default:
			break;

		}


	return(0);

}
