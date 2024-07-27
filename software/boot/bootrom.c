extern int DBGAttr;
extern void SerialInit(void);
extern void SerialTest(void);

static const int* pROM_memgate = 0xFEFFFF80;	// 8 gates
static const int* pIO_memgate = 0xFEFFF800;		// 64 gates
static const int* pDRAM_memgate = 0xFEF80000;	// 8192 gates

static const int pte[45] = {
	/*
	PTE#       PAGE#       ATTR
	*/
	0x1EDF, 0xFFFFFEDF,	0x83000FFF, /* LEDs */
	0x1EC0, 0xFFFFFEC0,	0x83000FFF, /* text mode screen */
	0x1ED0,	0xFFFFFED0,	0x83000FFF, /* Serial port */
	0x1EDC, 0xFFFFFEDC,	0x83000FFF, /* Keyboard */
	0x1EE1, 0xFFFFFEE1,	0x83000FFF, /* random number generator */
	0x1EE2,	0xFFFFFEE2,	0x83000FFF, /* interrupt controller */
	0x1EE4,	0xFFFFFEE4,	0x83000FFF, /* Programmable timer #1 */
	0x1FF8,	0xFFFFFFF8,	0x82000FFF, /* BIOS RAM */
	0x1FF9,	0xFFFFFFF9,	0x82000FFF, /* BIOS RAM */
	0x1FFA,	0xFFFFFFFA,	0x82000FFF, /* BIOS RAM */
	0x1FFB,	0xFFFFFFFB,	0x82000FFF, /* BIOS RAM */
	0x1FFC,	0xFFFFFFFC,	0x83800FFF, /* BIOS ROM */
	0x1FFD,	0xFFFFFFFD,	0x83800FFF, /* BIOS ROM */
	0x1FFE,	0xFFFFFFFE,	0x83800FFF, /* BIOS ROM */
	0x1FFF,	0xFFFFFFFF,	0x83800FFF, /* BIOS ROM */
};

/* Display blinking LEDs while delaying to show CPU is working.
*/
static void Delay3s(void)
{
	int* leds = 0x0FEDFFF00;
	unsigned int cnt;
	
	for (cnt = 0; cnt < 6000000; cnt++)
		leds[0] = cnt >> 17U;
}

/*
*/
static void ResetMemgates(int* gates, int count)
{
	int nn;

	for (nn = 0; nn < count; nn++) {
		gates[(nn*4) + 0] = 0;
		gates[(nn*4) + 1] = 0;
		gates[(nn*4) + 2] = 0;
		gates[(nn*4) + 3] = 0;
	}
}
/*
		The startup page table is located in the scratchpad RAM space at $FFFC0000,
		and has only 15 entries needed to access the BOOT ROM and some IO.
*/
static void ResetPageTable()
{
	int cnt;
	int* pgtbl 	= 0xfffc0000;
	
	for (cnt = 0; cnt < 45; cnt+= 3) {
		pgtbl[pte[cnt]+0] = pte[cnt+1];
		pgtbl[pte[cnt]+1] = pte[cnt+2];
	}
}

/*
static void SetupPMT()
{
	int cnt;
	int* pmt 	= 0xfff00000;
	
	for (cnt = 0; cnt < 4096; cnt = cnt + 2) {
		pmt[cnt] = 0x0000000000000000;		// Key=all zeros, PL=0, access count=0
		if (cnt < 4048)
			// rwx=7 for all modes, modified=1,ACL,Sharecount=0
			// content = data
			pmt[cnt+1] = 0xC000FFFF00000000;
		else
			// rwx=7 for all modes, modified=1,ACL,Sharecount=0
			// content = stack
			pmt[cnt+1] = 0xC002FFFF00000000;
	}
}
*/

void bootrom(void)
{
	int* pgtbl 	= 0xfffc0000;
	int* PTBR 	= 0xfff4ff20;
	int* leds 	= 0xFEDFFF00;
	int* timer1 = 0xFEE40000;
	int* intctrl = 0xFEE20000;
	int cnt, ndx;
	int* pRand;

	DBGAttr = 0x3FE07000;	/* white text on blue background */
	*PTBR = (int)(&pgtbl[0]) & -8;
	pRand = 0xFEE1FD00;
	
	ResetMemgates(pROM_memgate, 8);
	ResetMemgates(pIO_memgate, 64);
	ResetMemgates(pDRAM_memgate, 8192);

	/* Clear out page table */
	/*
	for (cnt = 0; cnt < 8192; cnt++) {
		pgtbl[cnt*2+0] = 0;
		pgtbl[cnt*2+1] = 0;
	}
	*/
	ResetPageTable();
//	SetupPMT();
//	DBGClearScreen();
	/* Initialize timer */
//	timer1[1] = 333333;			/* max count */
//	timer1[2] = 10;					/* on time */
//	timer1[3] = 7;					/* auto-reload, load, count enable */
	/* Initialize interrupt controller */
//	intctrl[61] = 0x0101040A;		/* cause=IRQ, IPL=4, send to CORE#1 */
/*
	__asm {
			loadi t0,8					; 8 = MIE
			csrrs	r0,t0,0x3004	; enable interrupts
	}
*/
	leds[0] = -1;						/* turn on all LEDs */
	pRand[1] = 0;						/* select random stream #0 */
	pRand[2] = 0x99999999;	/* set random seed value */
	pRand[3] = 0x99999999;
	Delay3s();
//	SerialInit();
//	SerialTest();
}

/* Save all registers except SP and r0 */
/*
__interrupt void PageFaultHandler()
{
	ResetPageTable();	
}

__interrupt void IRQHandler()
{
	int* screen = 0xFEC00000;

	screen[63] = screen[63] + 1;
}
*/
