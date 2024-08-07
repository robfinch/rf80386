# t386.asm rf386 cpu test
# Port to vasm standard syntax including mods.
# (c) 2024 Robert Finch <robfinch@finitron.ca>
#
# Original work from test386.asm
#   Copyright (C) 2012-2015 Jeff Parsons <Jeff@pcjs.org>
#   Copyright (C) 2017-2021 Marco Bortolin <barotto@gmail.com>
#
#   This file is a derivative work of PCjs
#   https://www.pcjs.org/software/pcx86/test/cpu/80386/test386.asm
#
#   test386.asm is free software: you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation, either version 3 of the License, or (at your option)
#   any later version.
#
#   test386.asm is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS
#   FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#   details.
#
#   You should have received a copy of the GNU General Public License along with
#   test386.asm.  If not see <http://www.gnu.org/licenses/gpl.html>.
#
#   This program was originally developed for IBMulator
#   https://barotto.github.io/IBMulator
#
#   Overview
#   --------
#   This file is designed to run as a test ROM, loaded in place of the BIOS.
#   Its pourpose is to test the CPU, reporting its status to the POST port and
#   its computational results in ASCII form to various configurable ports.
#   A 80386 or later CPU is required. This ROM is designed to test an emulator
#   CPU and was never tested on real hardware.
#
#   It must be installed at physical address 0xffff0000 and aliased at physical
#   address 0xffff0000.  The jump at resetVector should align with the CPU reset
#   address 0xfffffff0, which will transfer control to f000:0045.  From that
#   point on, all memory accesses should remain within the first 1MB.
#

#
# WARNING
#
#   A word of caution before you start developing.
#   NASM (2.11.08) generates [ebp + ebp] for [ebp*2] (i.e. no base register),
#   which are not the same thing: [ebp+ebp] references the SS segment, [ebp*2]
#   references the DS segment.
#   NASM developers think [ebp*2] and [ebp+ebp] are the same, but that is true
#   only assuming a flat memory model. Until the time NASM authors realize their
#   mistake (any assumption of a flat memory model should be optional), you can
#   disable this behaviour by writing: [nosplit ebp*2].
#
#	NASM Assembly            Translated               Assembled
#	mov eax,[ebp*2]          mov eax,[ebp+ebp*1+0x0]  8B442D00
#	mov eax,[nosplit ebp*2]  mov eax,[ebp*2+0x0]      8B046D00000000
#

.macro cpyright
	.ascii "t386.asm (c) 2024 Robert Finch (C) 2012-2015 Jeff Parsons, (C) 2017-2021 Marco Bortolin ",0
.endm
.macro RELEASE
	.ascii "??/??/24",0
.endm

	.set POST_PORT,0x190

#
# memory map:
#  FFF80000-FFF8FFFF page table
#  FFF90000-FFF903FF real mode IDT
#  FFF90400-FFF904FF protected mode IDT
#  FFF90500-FFF9077F protected mode GDT
#  FFF90800-FFF90FFF protected mode LDT
#  FFFA0000-FFFAFFFF read only data
#  FFFC0000-FFFCFFFF stack
#  FFF01000-FFF01FFF page directory
#  FFF94000-FFF95FFF TSS
#  20000-9FFFF tests
#

.set realmd_mask,0x0000ffff
.set rodata_seg,0x0fffa000
.set start_rodata,0xfffa0000
.set TEST_BASE,0xFFFC0000
.set TEST_CODE,0xFFFF0000
.set TEST_BASE1,TEST_BASE+0x0000
.set TEST_BASE2,TEST_BASE+0x2000

	.section .pgtbl
	.space 10

	.bss
	.space	10

	.data
	.space	10

	.rodata
idt_addr:
	.2byte 0x400
	.4byte 0xFFF90000		# Linear address of table

#	.org	0xF0000
	.text
	.code16
#	.align	0
.extern	_bootrom
.extern _Fibonacci

#
#   Real mode segments
#
.set C_SEG_REAL,0xF000
.set S_SEG_REAL,0xC000
.set IDT_SEG_REAL,0x9000
.set IDT_SEG_PROT,0x9040
.set GDT_SEG_REAL,0x9050
.set GDT_SEG_LIMIT,0x2FF
.set D1_SEG_REAL,TEST_BASE1 >> 4
.set D2_SEG_REAL,TEST_BASE2 >> 4

.set ESP_REAL,0x7ffc


.include "x86_e.asm"
.include "macros_m.asm"
.include "shift_m.asm"

_start:
	jmp _start1
header:
	cpyright

_start1:
	cli	
# init IDT
#	mov $17,%cx
#	movl $error,%edx
#	movl $0xfff90000,%eax
#	movl $error,%edx
#.aloop:
#	movw %dx,(%eax)
#	movw $0xf000,2(%eax)
##	movw $error,(,%eax,4)
##	movw $0xf000,2(,%eax,4)
#	addl $4,%eax
#	loop .aloop

#	mov $ESP_REAL,%esp

# ==============================================================================
#	Real mode tests
# ==============================================================================

.include "real_m.asm"
#-------------------------------------------------------------------------------
	POST $0x00
#-------------------------------------------------------------------------------
#
#   Real mode initialization
#
	mov $rodata_seg & realmd_mask,%ax
	mov %ax,%ds
	lidt idt_addr-start_rodata
	initRealModeIDT
	mov $S_SEG_REAL,%ax
	mov %ax,%ss
	mov $ESP_REAL,%sp
	mov $D1_SEG_REAL,%dx
	mov %dx,%ds
	mov $D2_SEG_REAL,%dx
	mov %dx,%es

#-------------------------------------------------------------------------------
	POST $0x01
#-------------------------------------------------------------------------------
#
#   Conditional jumps
#
.include "jcc_m.asm"
	testJcc 8
	testJcc 16

#
#   Loops
#
.include "loop_m.asm"
#	testLoop
#	testLoopZ
#	testLoopNZ

#-------------------------------------------------------------------------------
	POST $0x02
#-------------------------------------------------------------------------------
#
#   Quick tests of unsigned 32-bit multiplication and division
#   Thorough arithmetical and logical tests are done later
#
	mov $0x80000001,%eax
	imul %eax
	mov $0x44332211,%eax
	mov %eax,%ebx
	mov $0x88776655,%ecx
	mul %ecx
	div %ecx
	cmp %ebx,%eax
	jne error

.include "mov_m.asm"
#-------------------------------------------------------------------------------
	POST $0x03
#-------------------------------------------------------------------------------
#
#   Move segment registers in real mode
#
	testMovSegR_real ss
	testMovSegR_real ds
	testMovSegR_real es
	testMovSegR_real fs
	testMovSegR_real gs
	testMovSegR_real cs

	advTestSegReal

.include "string_m.asm"
#-------------------------------------------------------------------------------
	POST $0x04
#-------------------------------------------------------------------------------
#
#   Test store, move, scan, and compare string data
#
.set b,0
.set w,1
.set d,2

	testStringOps b,0,16
	testStringOps w,0,16
	testStringOps d,0,16
	testStringOps b,1,16
	testStringOps w,1,16
	testStringOps d,1,16
	testStringReps b,0,16
	testStringReps w,0,16
	testStringReps d,0,16
	testStringReps b,1,16
	testStringReps w,1,16
	testStringReps d,1,16

	advTestSegReal

.include "call_m.asm"
#-------------------------------------------------------------------------------
	POST $0x05
#-------------------------------------------------------------------------------
#
#   Calls in real mode
#
	mov $0,%si
	testCallNear sp
	testCallFar C_SEG_REAL

	advTestSegReal


.include "load_ptr_m.asm"
#-------------------------------------------------------------------------------
	POST $0x06
#-------------------------------------------------------------------------------
#
#   Load full pointer in real mode
#
	mov $0,%di
	testLoadPtr ss
	testLoadPtr ds
	testLoadPtr es
	testLoadPtr fs
	testLoadPtr gs

	advTestSegReal

# ==============================================================================
#	Protected mode tests
# ==============================================================================

#-------------------------------------------------------------------------------
	POST $0x08
#-------------------------------------------------------------------------------
#
#   GDT, LDT, PDT, and PT setup, enter protected mode
#
	jmp initGDT

.set ESP_R0_PROT,0x0000FFFF
.set ESP_R3_PROT,0x00007FFF

.include "protected_m.asm"


#;; support for ROM based GDT (currently unused)
romGDT:
romGDTEnd:
romGDTaddr:
	.2byte romGDTEnd - romGDT - 1 	# 16-bit limit
	.4byte romGDT  									# 32-bit base address
#;;

ptrGDTreal: # pointer to the pmode GDT for real mode code
	.4byte 0         			# 32-bit offset
	.2byte GDT_SEG_REAL  	# 16-bit segment selector
ptrIDTreal: # pointer to the pmode IDT for real mode code
	.4byte 0
	.2byte IDT_SEG_REAL

initGDT:
	# the first descriptor in the GDT is always a dud (the null selector)
	defGDTDesc 0,0,0,0,0
	defGDTDesc C_SEG_PROT16,  0xffff0000,0x0000ffff,ACC_TYPE_CODE_R|ACC_PRESENT
	defGDTDesc C_SEG_PROT32,  0xffff0000,0x0000ffff,ACC_TYPE_CODE_R|ACC_PRESENT,EXT_32BIT
	defGDTDesc CU_SEG_PROT32, 0xffff0000,0x0000ffff,ACC_TYPE_CODE_R|ACC_PRESENT|ACC_DPL_3,EXT_32BIT
	defGDTDesc CC_SEG_PROT32, 0xffff0000,0x0000ffff,ACC_TYPE_CODE_R|ACC_TYPE_CONFORMING|ACC_PRESENT|EXT_32BIT
	defGDTDesc IDT_SEG_PROT,  0xFFF90400,0x000000ff,ACC_TYPE_DATA_W|ACC_PRESENT
	defGDTDesc IDTU_SEG_PROT, 0xFFF90400,0x000000ff,ACC_TYPE_DATA_W|ACC_PRESENT|ACC_DPL_3
	defGDTDesc GDT_DSEG_PROT, 0xFFF90500,0x000002ff,ACC_TYPE_DATA_W|ACC_PRESENT
	defGDTDesc GDTU_DSEG_PROT,0xFFF90500,0x000002ff,ACC_TYPE_DATA_W|ACC_PRESENT|ACC_DPL_3
	defGDTDesc LDT_SEG_PROT,  0xFFF90800,0x000007ff,ACC_TYPE_LDT|ACC_PRESENT
	defGDTDesc LDT_DSEG_PROT, 0xFFF90800,0x000007ff,ACC_TYPE_DATA_W|ACC_PRESENT
	defGDTDesc PG_SEG_PROT,   0xfff80000,0x0002ffff,ACC_TYPE_DATA_W|ACC_PRESENT
	defGDTDesc S_SEG_PROT32,  0xfffc0000,0x0008ffff,ACC_TYPE_DATA_W|ACC_PRESENT,EXT_32BIT
	defGDTDesc SU_SEG_PROT32, 0xfffc0000,0x0008ffff,ACC_TYPE_DATA_W|ACC_PRESENT|ACC_DPL_3,EXT_32BIT
	defGDTDesc TSS_PROT,      0xfff94000,0x00000fff,ACC_TYPE_TSS|ACC_PRESENT|ACC_DPL_3
	defGDTDesc TSS_DSEG_PROT, 0xfff94000,0x00000fff,ACC_TYPE_DATA_W|ACC_PRESENT
	defGDTDesc FLAT_SEG_PROT, 0x00000000,0xffffffff,ACC_TYPE_DATA_W|ACC_PRESENT
	defGDTDesc RING0_GATE # placeholder for a call gate used to switch to ring 0

	jmp initIDT

ptrIDTprot: # pointer to the IDT for pmode
	.4byte 0         		# 32-bit offset
	.2byte IDT_SEG_PROT # 16-bit segment selector
ptrIDTUprot: # pointer to the IDT for pmode
	.4byte 0            	# 32-bit offset
	.2byte IDTU_SEG_PROT  # 16-bit segment selector
ptrGDTprot: # pointer to the GDT for pmode (kernel mode data segment)
	.4byte 0
	.2byte GDT_DSEG_PROT
ptrGDTUprot: # pointer to the GDT for pmode (user mode data segment)
	.4byte 0
	.2byte GDTU_DSEG_PROT
ptrLDTprot: # pointer to the LDT for pmode
	.4byte 0
	.2byte LDT_DSEG_PROT
ptrPDprot: # pointer to the Page Directory for pmode
	.4byte 0
	.2byte PG_SEG_PROT
ptrPT0prot: # pointer to Page Table 0
	.4byte 0x1000
	.2byte PG_SEG_PROT
ptrPT1prot: # pointer to Page Table 1
	.4byte 0x2000
	.2byte PG_SEG_PROT
ptrSSprot: # pointer to the stack for pmode
	.4byte ESP_R0_PROT
	.2byte S_SEG_PROT32
ptrTSSprot: # pointer to the task state segment
	.4byte 0
	.2byte TSS_DSEG_PROT
addrProtIDT: # address of pmode IDT to be used with lidt
	.2byte 0xFF              						# 16-bit limit
	.4byte 0xffff0000|(IDT_SEG_REAL << 4) 	# 32-bit base address
addrGDT: # address of GDT to be used with lgdt
	.2byte GDT_SEG_LIMIT
	.4byte 0xffff0000|(GDT_SEG_REAL << 4)

# Initializes an interrupt gate in system memory in real mode
initIntGateReal:
	pushal
	initIntGate
	popal
	ret

initIDT:
	lds %cs:ptrIDTreal-TEST_CODE,%ebx
	mov $C_SEG_PROT32,%esi
	mov $DefaultExcHandler-TEST_CODE,%edi
	mov $ACC_DPL_0,%dx
.set vector,00
.rept 0x15
	mov $vector,%eax
	call initIntGateReal
.set vector,vector+1
.endr

	jmp initPaging

initPaging:
#
# pages:
#  FFF90000-FFF90FFF   1  1000h   4K IDTs, GDT and LDT
#  FFF80000-FFF81FFF   1  2000h   8K page directory
#  FFF82000-FFF83FFF   1  2000h   8K page table 0
#  FFF84000-FFF85FFF   1  2000h   8K page table 1
#  FFF94000-FFF95FFF   1  2000h   8K task switch segments
#  FFFC0000-FFFCFFFF  8  10000h   64K stack
#  FFFF0000-FFFFFFFF  8  10000h   64K tests
#  FFF86000-FFF87FFF   1  2000h   8K used for page faults (PTE 9Fh)
#
.set PAGE_DIR_ADDR,0x2000
.set PAGE_TBL0_ADDR,PAGE_DIR_ADDR+0x2000
.set PAGE_TBL1_ADDR,PAGE_DIR_ADDR+0x4000

#   Now we want to build a page table. We need two pages of
#   8K-aligned physical memory.  We use a hard-coded address, segment 0x8000,
#   corresponding to physical address 0xFFF80000.
#
	mov $PAGE_DIR_ADDR,%esi
	mov %esi,%eax
	shr $4,%eax
	or $0x8000,%ax
	mov %ax,%es
#
#   Build a page table at ES:EDI (8000:0000) with only 64 valid PTEs at end,
#   because we're not going to access any memory outside the last 512kB.
#
# The .if is to avoid a long loop during simulation.
.if 0
	cld
	xor %edi,%edi
	mov $1919,%ecx		# ECX == number of dwords to write = ((1024-64)*8)/4-1
	xor %eax,%eax    	# fill PTEs with 0
	rep
	stosl
.endif
	mov $7680,%edi		# index of last 64 PTEs
	mov $127,%ecx			# ECX = (64 * 8) / 4 - 1
	mov $0xfff80000,%edx
.ipt1:
	mov $PTE_PRESENT | PTE_USER | PTE_WRITE,%eax
	add %edx,%eax			# add in the address
	stosl
	# Bits 32 to 63 can all be zero. The high order page number is not used
	# because the test system uses only a 32-bit physical address.
	xor %eax,%eax			# page table hi order page number
	stosl
	add $0x2000,%edx	# increment address to next page
	loop .ipt1

switchToProtMode:
	cli 							# make sure interrupts are off now, since we've not initialized the IDT yet
	data32
	lidt %cs:addrProtIDT-TEST_CODE
	data32
	lgdt %cs:addrGDT-TEST_CODE
	mov %esi,%cr3
	mov %cr0,%eax
	or $CR0_MSW_PE | CR0_PG,%eax
	mov %eax,%cr0
	jmp $C_SEG_PROT32,$toProt32 	# jump to flush the prefetch queue
toProt32:
	.code32
	jmp initLDT

.include "protected_p.asm"

initLDT:
	defLDTDesc D_SEG_PROT16,   TEST_BASE, 0x000fffff,ACC_TYPE_DATA_W|ACC_PRESENT
	defLDTDesc D_SEG_PROT32,   TEST_BASE, 0x000fffff,ACC_TYPE_DATA_W|ACC_PRESENT,EXT_32BIT
	defLDTDesc DU_SEG_PROT,    TEST_BASE, 0x000fffff,ACC_TYPE_DATA_W|ACC_PRESENT|ACC_DPL_3
	defLDTDesc D1_SEG_PROT,    TEST_BASE1,0x000fffff,ACC_TYPE_DATA_W|ACC_PRESENT
	defLDTDesc D2_SEG_PROT,    TEST_BASE2,0x000fffff,ACC_TYPE_DATA_W|ACC_PRESENT
	defLDTDesc DC_SEG_PROT32,  TEST_BASE1,0x000fffff,ACC_TYPE_CODE_R|ACC_PRESENT,EXT_32BIT
	defLDTDesc RO_SEG_PROT,    TEST_BASE, 0x000fffff,ACC_TYPE_DATA_R|ACC_PRESENT
	defLDTDesc ROU_SEG_PROT,   TEST_BASE, 0x000fffff,ACC_TYPE_DATA_R|ACC_PRESENT|ACC_DPL_3
	defLDTDesc DTEST_SEG_PROT, TEST_BASE, 0x000fffff,ACC_TYPE_DATA_W|ACC_PRESENT,EXT_32BIT
	defLDTDesc DPL1_SEG_PROT,  TEST_BASE, 0x000fffff,ACC_TYPE_DATA_W|ACC_PRESENT|ACC_DPL_1
	defLDTDesc NP_SEG_PROT,    TEST_BASE, 0x000fffff,ACC_TYPE_DATA_W
	defLDTDesc SYS_SEG_PROT,   TEST_BASE, 0x000fffff,ACC_PRESENT

	mov  $LDT_SEG_PROT,%ax
	lldt %ax
	mov $TSS_PROT,%ax
	ltr %ax
	jmp protTests

#.include "tss_p.asm"
#.include "protected_rings_p.asm"

protTests:

.include "lea_m.asm"
#.include "lea_p.asm"
postD:

#-------------------------------------------------------------------------------
	POST $0x0D
#-------------------------------------------------------------------------------
#
#   16-bit addressing modes (LEA)
#
	mov $1,%ax
	mov $2,%bx
	mov $4,%cx
	mov $8,%dx
	mov $0x10,%si
	mov $0x20,%di
	testLEA16 0x4000, $0x4000
	testLEA16 (%bx), $0x0002
	testLEA16 (%si), $0x0010
	testLEA16 (%di), $0x0020
	testLEA16 0x40(%bx), $0x0042
	testLEA16 0x40(%si), $0x0050
	testLEA16 0x40(%di), $0x0060
	testLEA16 0x4000(%bx), $0x4002
	testLEA16 0x4000(%si), $0x4010
	testLEA16 (%bx,%si), $0x0012
	testLEA16 (%bx,%di), $0x0022
	testLEA16 0x40(%bx,%si), $0x0052
	testLEA16 0x40(%bx,%di), $0x0062
	testLEA16 0x4000(%bx,%si), $0x4012
	testLEA16 0x4000(%bx,%di), $0x4022


#-------------------------------------------------------------------------------
	POST $0xE0
#-------------------------------------------------------------------------------

.shifts386FlagsTest:

	# SHR al,cl - SHR ax,cl
	# undefined flags:
	#  CF when cl>7 (byte) or cl>15 (word):
	#    if byte operand and cl=8 or cl=16 or cl=24 then CF=MSB(operand)
	#    if word operand and cl=16 then CF=MSB(operand)
	#  OF when cl>1: set according to result   *** rf386 calc's overflow cl>1
	#  AF when cl>0: always 1
	# shift count is modulo 32 so if cl=32 then result is equal to cl=0

	testShiftBFlags shrb, $0x81, $1, $0, $(PS_CF|PS_AF|PS_OF)
	testShiftBFlags shrb, $0x82, $2, $0, $(PS_CF|PS_AF|PS_OF)
	testShiftBFlags shrb, $0x80, $8, $0, $(PS_CF|PS_PF|PS_AF|PS_ZF|PS_OF)
	testShiftBFlags shrb, $0x00,   $8,  $PS_CF, $(PS_PF|PS_ZF)
	testShiftBFlags shrb, $0x80,   $16, $0,     $(PS_PF|PS_ZF|PS_OF)
	testShiftBFlags shrb, $0x00,   $16, $PS_CF, $(PS_PF|PS_ZF)
	testShiftBFlags shrb, $0x80,   $24, $0,     $(PS_PF|PS_ZF|PS_OF)
	testShiftBFlags shrb, $0x00,   $24, $PS_CF, $(PS_PF|PS_ZF)
	testShiftBFlags shrb, $0x80,   $32, $0,     $PS_SF
	testShiftWFlags shrw, $0x8000, $16, $0,     $(PS_CF|PS_PF|PS_AF|PS_ZF|PS_OF)
	testShiftWFlags shrw, $0x0000, $16, $PS_CF, $(PS_PF|PS_ZF)
	testShiftWFlags shrw, $0x8000, $32, $0,     $PS_SF|PS_PF

	# SHL al,cl - SHL ax,cl
	# undefined flags:
	#  CF when cl>7 (byte) or cl>15 (word):
	#    if byte operand and cl=8 or cl=16 or cl=24 then CF=LSB(operand)
	#    if word operand and cl=16 then CF=LSB(operand)
	#  OF when cl>1: set according to result
	#  AF when cl>0: always 1
	# shift count is modulo 32 so if cl=32 then result is equal to cl=0

	testShiftBFlags shlb, $0x81, $1,  $0,     $(PS_CF|PS_OF)
	testShiftBFlags shlb, $0x41, $2,  $0,     $(PS_CF|PS_OF)
	testShiftBFlags shlb, $0x01, $8,  $0,     $(PS_CF|PS_PF|PS_ZF|PS_OF)
	testShiftBFlags shlb, $0x00, $8,  $PS_CF, $(PS_PF|PS_ZF)
	testShiftBFlags shlb, $0x01, $16, $0,     $(PS_CF|PS_PF|PS_ZF|PS_OF)
	testShiftBFlags shlb, $0x00, $16, $PS_CF, $(PS_PF|PS_ZF)
	testShiftBFlags shlb, $0x01, $24, $0,     $(PS_CF|PS_PF|PS_ZF|PS_OF)
	testShiftBFlags shlb, $0x00, $24, $PS_CF, $(PS_PF|PS_ZF)
	testShiftBFlags shlb, $0x01, $32, $0,     $0
	testShiftWFlags shlw, $0x01, $16, $0,     $(PS_CF|PS_PF|PS_ZF|PS_OF)
	testShiftWFlags shlw, $0x00, $16, $PS_CF, $(PS_PF|PS_ZF)
	testShiftWFlags shlw, $0x01, $32, $0,     $0

	jmp _bootrom

#	pushl $10
#	call _Fibonacci

#
# Default exception handler and error routine
#
DefaultExcHandler:
error:
# CLI and HLT are privileged instructions, don't use them in ring3
	mov %cs,%ax

# when in real mode, the jnz will be decoded together with test as
# "test eax,0xfe750007" (66A9070075FE)
	test $7,%ax     # 66 A9 07 00
.ring3: jnz .ring3 # 75 FE
	cli
	hlt
	jmp error


.rept 16
	nop
.endr
	
#	.type	_start,@function
#	.size	_start,$-_start

#.include "Fibonacci.asm"
#.include "serial.asm"
#.include "xmodem.asm"
#.include "bootrom.asm"

.global _disable_int
.global _restore_int
.extern _start_data
.extern _start_rodata
.extern _start_bss
