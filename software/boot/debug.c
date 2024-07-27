#define DBGScreen	(int *)0xFEC00000
#define DBGCOLS		64
#define DBGROWS		31

int DBGAttr;
char DBGCursorCol;
char DBGCursorRow;

void DBGClearScreen()
{
	int *p;
	int vc;
	int r;

	p = DBGScreen;
	vc = ' ' | DBGAttr;
	for (r = 0; r < DBGCOLS * DBGROWS; r++)
		p[r] = vc;
}

static void DBGSetVideoReg(int regno, int val)
{
	int* p = 0xFEC80000;

	p[regno] = val;
}

char AsciiToScreen(char ch)
{
/*
	if (ch==0x5B)
		return (0x1B);
	if (ch==0x5D)
		return (0x1D);
	ch &= 0xFF;
	ch |= 0x100;
	if (!(ch & 0x20))
		return (ch);
	if (!(ch & 0x40))
		return (ch);
	ch = ch & 0x19F;
*/
	return (ch);
}

char ScreenToAscii(char ch)
{
/*
	ch &= 0xFF;
	if (ch==0x1B)
		return 0x5B;
	if (ch==0x1D)
		return 0x5D;
	if (ch < 27)
		ch += 0x60;
*/
	return (ch);
}
    

void DBGSetCursorPos(short int pos)
{
	short int*p = 0xFEC1DF1C;
	*p = pos;
}

void DBGUpdateCursorPos()
{
	int pos;

	pos = DBGCursorRow * DBGCOLS + DBGCursorCol;
  DBGSetCursorPos(pos);
}

void DBGHomeCursor()
{
	DBGCursorCol = 0;
	DBGCursorRow = 0;
	DBGUpdateCursorPos();
}

void DBGBlankLine(int row)
{
	int *p;
	int nn;
	int mx;
	int vc;

	p = DBGScreen;
	p = row * DBGCOLS + p;
	vc = DBGAttr | ' ';
	for (nn = 0; nn < DBGCOLS; nn++)
		p[nn] = vc;
}

void DBGScrollUp()
{
	int *scrn = DBGScreen;
	int nn;
	int count;

	count = DBGROWS * DBGCOLS;
	for (nn = 0; nn < count; nn++)
		scrn[nn] = scrn[nn+DBGCOLS];

	DBGBlankLine(DBGROWS-1);
}

void DBGIncrementCursorRow()
{
	if (DBGCursorRow < DBGROWS - 1) {
		DBGCursorRow++;
		DBGUpdateCursorPos();
		return;
	}
	DBGScrollUp();
}

void DBGIncrementCursorPos()
{
	DBGCursorCol++;
	if (DBGCursorCol < DBGCOLS) {
		DBGUpdateCursorPos();
		return;
	}
	DBGCursorCol = 0;
	DBGIncrementCursorRow();
}

void DBGDisplayChar(char ch)
{
	int *p;
	int nn;

	switch(ch) {
	case '\r':  DBGCursorCol = 0; DBGUpdateCursorPos(); break;
	case '\n':  DBGIncrementCursorRow(); break;
	case 0x91:
    if (DBGCursorCol < DBGCOLS - 1) {
       DBGCursorCol++;
       DBGUpdateCursorPos();
    }
    break;
	case 0x90:
    if (DBGCursorRow > 0) {
         DBGCursorRow--;
         DBGUpdateCursorPos();
    }
    break;
	case 0x93:
    if (DBGCursorCol > 0) {
         DBGCursorCol--;
         DBGUpdateCursorPos();
    }
    break;
	case 0x92:
    if (DBGCursorRow < DBGROWS-1) {
       DBGCursorRow++;
       DBGUpdateCursorPos();
    }
    break;
	case 0x94:
    if (DBGCursorCol==0)
       DBGCursorRow = 0;
    DBGCursorCol = 0;
    DBGUpdateCursorPos();
    break;
	case 0x99:  // delete
    p = DBGScreen + DBGCursorRow * DBGCOLS;
    for (nn = DBGCursorCol; nn < DBGCOLS-1; nn++) {
      p[nn] = p[nn+1];
    }
		p[nn] = DBGAttr | ' ';
    break;
	case 0x08: // backspace
    if (DBGCursorCol > 0) {
      DBGCursorCol--;
//	      p = DBGScreen;
  		p = DBGScreen + DBGCursorRow * DBGCOLS;
      for (nn = DBGCursorCol; nn < DBGCOLS-1; nn++) {
          p[nn] = p[nn+1];
      }
      p[nn] = DBGAttr | ' ';
		}
    break;
	case 0x0C:   // CTRL-L
    DBGClearScreen();
    DBGHomeCursor();
    break;
	case '\t':
    DBGDisplayChar(' ');
    DBGDisplayChar(' ');
    DBGDisplayChar(' ');
    DBGDisplayChar(' ');
    break;
	default:
	  p = DBGScreen;
	  nn = DBGCursorRow * DBGCOLS + DBGCursorCol;
	  p[nn] = ch | DBGAttr;
	  DBGIncrementCursorPos();
	}
}

void DBGCRLF()
{
   DBGDisplayChar('\r');
   DBGDisplayChar('\n');
}

void DBGDisplayString(char *s)
{
	// Declaring ch here causes the compiler to generate shorter faster code
	// because it doesn't have to process another *s inside in the loop.
	char ch;
  while (ch = *s) { DBGDisplayChar(ch); s++; }
}

void DBGDisplayStringCRLF(char *s)
{
   DBGDisplayString(s);
   DBGCRLF();
}

