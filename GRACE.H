//----------------------------------------------------------------------//
//	GRAphics Control Environment Definitions file								//
//	Copyright (C) 1992 Kenneth L. Hurley											//
//	GRACE.H
//----------------------------------------------------------------------//

//----------------------------------------------------------------------//
// Defines																					//
//----------------------------------------------------------------------//

//
// ----- defines
//
#define	FALSE					0
#define	TRUE					1

//
// ----- modes for BGI write modes
//
#define	REPLACE_MODE		0
#define	XOR_MODE				1
#define	OR_MODE				2
#define	AND_MODE				3
#define	XPARENT_MODE		4
//
// ----- Devices global numbers
//
#define	NULLDEVICE			0
#define	KEYBOARDDEVICE		1
#define	JOYSTICKDEVICE		2
#define	HWTIMERDEVICE		3
#define	TIMERDEVICE			4
#define	HWMOUSEDEVICE		5
#define	MOUSEDEVICE			6
#define	MENUDEVICE			7
#define	WINDOWDEVICE		8
#define	DIALOGDEVICE		9
#define	OBJECTDEVICE		10
#define	TEXTEDITDEVICE		11

//
// ----- Object
//
#define	OBJCIRCLE			(0*sizeof(objBitmap))
#define	OBJCLOSEWIN			(1*sizeof(objBitmap))
#define	OBJDIAMON			(2*sizeof(objBitmap))
#define	OBJDNARROW			(3*sizeof(objBitmap))
#define	OBJLFARROW			(4*sizeof(objBitmap))
#define	OBJSIZEWIN			(5*sizeof(objBitmap))
#define	OBJRTARROW			(6*sizeof(objBitmap))
#define	OBJBLOCK				(7*sizeof(objBitmap))
#define	OBJUPARROW			(8*sizeof(objBitmap))
#define	OBJOKBUTTON			(9*sizeof(objBitmap))
#define	OBJCANCELBUTTON	(10*sizeof(objBitmap))
#define	OBJSTOPICON			(11*sizeof(objBitmap))

//
// ----- Dialog bits
//
#define	DIALOG_OK_BIT		1
#define	DIALOG_CANCEL_BIT 2
#define	DIALOG_ICON_BIT	4

//
//
//
#define	OK_BUTTON			1000
#define	CANCEL_BUTTON		1001

//
// -----	Window objects
//
#define		WIN_DRAW				1
#define		WIN_TITLE_BAR		2
#define		WIN_CLOSE_BM		4
#define		WIN_VSCROLL			8
#define		WIN_HSCROLL			16
#define		WIN_SIZE_BM			32

//
// -----	Window messages
//
#define		WINDOW_REDRAW_WS		1		// redraw window's work space
#define		WINDOW_CLOSE	 		2
#define		WINDOW_RESIZE	 		3
#define		WINDOW_MOVE		 		4
#define		WINDOW_VS_UP			5		// vertical scroll up arrow
#define		WINDOW_VS_DOWN			6
#define		WINDOW_VS_BAR			7		// clicked in vertical scroll bar
#define		WINDOW_HS_LEFT			8		// horizontal left arrow 
#define		WINDOW_HS_RIGHT		9
#define		WINDOW_HS_BAR			10
#define		WINDOW_TO_TOP			11		// bring window to top
#define		WINDOW_TO_BACK			12		// put window in back
#define		WINDOW_MOUSE_MOVE 	13		// mouse movement in window area
#define		WINDOW_MOUSE_CLICK 	14		// mouse click in window area
#define		WINDOW_KEYPRESS		15		// keyboard press for window
#define		WINDOW_KEYRELEASE 	16		// keyboard release for window
#define		WINDOW_COOKED_KEY 	17		// window dos cooked key pressed

//
// ----- Misceallaneous window defines
//
#define		MINWINDOWHEIGHT	36

//
// -----	Menu device messages
//
#define		MENUSELECT			1
#define		MENUDESELECT		2
#define		MENUMOUSEMOVE		3
#define		MENUITEMSELECT		4
#define		MENUITEMDESELECT 	5
#define		MENUITEMRELEASE	6

//
// ----- Errors returned
//
//
// ----- window error messages
//
#define	INVALID_WINDOW_HANDLE	-10	// invalid window handle
#define	NO_TITLE_BAR_FOUND		-11	// no title bar found for this window

//
// -----	string flag settings
//
#define	STR_NORMAL				0
#define	STR_LIGHTENED			1
#define	STR_TOUPPER				4			// only upper case allowed
#define	STR_TOLOWER				8			// only lower case allowed
#define	STR_CENTERED			16			// centered in parent structure
#define	STR_LEFT_JUSTIFY		32			// left justified in parent structure
#define	STR_RIGHT_JUSTIFY		64			// right justified in parent structure

//
// -----	fill patterns
//
#define	EMPTYPATTERN			0			// empty pattern
#define	SOLIDPATTERN			1			// solid pattern
#define	VECTPATTERN				2			// vector pattern
#define	LTSLASHPATTERN			3			// light slash pattern
#define	SLASHPATTERN			4			// slash pattern
#define	BKSLASHPATTERN			5			// backwards slash pattern
#define	LTBKSLASHPATTERN		6			// light backwards slash pattern
#define	HATCHPATTERN			7			// hatch pattern
#define	XHATCHPATTERN			8			// hatch pattern in x
#define	INTERLEAVEPATTERN		9			// interleaved pattern
#define	WIDEDOTPATTERN			10			// wide dot pattern
#define	CLOSEDOTPATTERN		11			// close dot pattern
#define	USERPATTERN				-1			// user defined pattern







//----------------------------------------------------------------------//
//	Structures																				//
//----------------------------------------------------------------------//

//
//	-----	object types structure
//
typedef struct object
	{
	int		objX;						// x position
	int		objY;						// y position
	int		objW;		 				//	width of object when drawn (filled in?)
	int		objH;		 				//	height of object when drawn
	int		objtype;	 				//	type of object
	int		objflags; 				//	generic object flags
	int		objID;	 				//	generic object ID
	void		huge *objptr; 			//	pointer to object
	} object;

typedef struct objBitmap
	{
	unsigned char bitmapflags;		// bitmap flags
	unsigned char bitmapdrawMode;	// Drawing mode for bitmap
	char far *bitmapNormalPtr;		// Pointer to normal bitmap
	char far *bitmapPressPtr;		// Pressed bitmap pointer
	} objBitmap;


typedef	struct	objectParent
	{
	unsigned int numObjects;		// number of objects in this list
	object theObjects[];				// 1...numObjects
	} objectParent;


//
//	-----	Window structures
//
typedef struct winHeader
	{
	char	winID[4];					// 'WIND' id for window type
	int	winX;
	int	winY;
	int	winW;
	int	winH;
	unsigned int winNext;			// next window handle
	unsigned int winPrevious;		// previous window handle
	void far *wndProc;				// window procedure pointer
	char	winreserved[10];
	} winHeader;

//
// -----	Rectangle structure
//
typedef	struct Rect
	{
	int	rectX;						// x position of rectangle
	int	rectY;						// y position of rectangle
	int	rectW;						// width of rectangle
	int	rectH;						// height of rectangle
	} Rect;

//
// -----	Timer structure
//
typedef struct timeSlice
	{
	int	timerNotify;				// ticks before notification
	int	temp;							// current tick counter
	void	far *notifyRtn;			// notification routine
	void	far *nextRtn;
	} timeSlice;

//
// ----- Raster structure
//
typedef struct RASTER
	{
	unsigned int	RastX;			// x Position of raster
	unsigned int	RastY;			// y position of raster
	unsigned int	RastWidth;		// width of raster
	unsigned int	RastHeight;		// height of raster
	char far *DataPtr;				// Pointer to raster Data
	} RASTER;

//
// -----	Copy raster structure
//
typedef struct	COPYRASTER
	{
	int	RasterWidth;				// copying raster width
	int	RasterHeight;				// copying raster height
	RASTER SrcRast;					// source raster
	RASTER DstRast;					// destination raster
	} COPYRASTER;


//----------------------------------------------------------------------//
// Global variables																		//
//----------------------------------------------------------------------//
extern char backColor;				// back ground color
extern char backPatternCol;		// background pattern color
extern char far *backPatternPtr;	// background pattern pointer if user def.
extern char backPattern;			// -1 for user otherwise bgi defined

//----------------------------------------------------------------------//
// Function Prototypes																	//
//----------------------------------------------------------------------//

//
// -----	system function prototypes
//
void far InstallSystem(void);
void far initGRACE(void);
//
// -----	dialog function prototypes
//
int far alert(int x, int y, char far *string, int buttons, int icon);
int far fileDialog(char far *filename, char far *pathname,char far *titleStr);				
//
// ----- window function prototypes
//
int far makeWindow(int workX, int workY, int workW, int workH, int flags,
						void far *wndProc, void far *wndParms);
int far DefWindProc(int msgBits);
int far SummonWinToTop(int winHandle);
int far DrawWindow(int winHandle);
int far setWinTitle(int winHandle, char far *TitleStr, int flags);
void far freeWindow(int winHandle);

//
// ----- menu function prototypes
//
int far drawMenuBar(int x, int y, object far *objList);
void far freeMenu(void);
//
// ----- event manager function prototypes
//
void far eventManager(void);
int far getTempMsgBuff(int huge *bufPtr, int nMsgs);
void far addMsgQueue(int msg);
void far addMsgBuff(int nMessages, int *msgs);
int far getTempMsgWord(void);
//
// ----- text editing function prototypes
//
int far EditText(int x, int y, char huge *curText, int bufLen, Rect *parentRect,
						int curPos);
//
// -----	Raster function prototypes
//
void far copyRaster(COPYRASTER *);
//
// -----	Refresh rectangle prototypes
//
void far RectangleUnion(Rect *Rect1, Rect *Rect2);
void far RefreshRect(Rect *srcRect, int lastWindow);
void far Refresh1Object(int handle, Rect *srcRect);
void far RectangleExclusion(Rect *firstrect, Rect *secondRect);  
//
// -----	object prototypes
//
void far redrawBackground(Rect *clipRect);

