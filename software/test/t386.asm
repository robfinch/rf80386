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
#  FFF94000-FFF94FFF TSS
#  20000-9FFFF tests
#

.set realmd_mask,0x0000ffff
.set rodata_seg,0x0fffa000
.set start_rodata,0xfffa0000
.set TEST_BASE,0x20000
.set TEST_BASE1,TEST_BASE+0x00000
.set TEST_BASE2,TEST_BASE+0x40000

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
.set C_SEG_REAL,0x0000
.set S_SEG_REAL,0xC000
.set IDT_SEG_REAL,0x9000
.set IDT_SEG_PROT,0x9040
.set GDT_SEG_REAL,0x9050
.set GDT_SEG_LIMIT,0x2FF
.set D1_SEG_REAL,TEST_BASE1 >> 4
.set D2_SEG_REAL,TEST_BASE2 >> 4

.set ESP_REAL,0xfffc


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
	POST $0
#-------------------------------------------------------------------------------
#
#   Real mode initialisation
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
	POST $1
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
	POST $2
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
