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
#  FFF90000-FFF903FF real mode IDT
#  FFF90400-FFF904FF protected mode IDT
#  FFF90500-FFF9077F protected mode GDT
#  FFF90800-FFF90FFF protected mode LDT
#  01000-01FFF page directory
#  FFF80000-FFF8FFFF page table
#  FFF94000-FFF94FFF TSS
#  FFFC0000-FFFCFFFF stack
#  20000-9FFFF tests
#


	.bss
	.space	10

	.data
	.space	10

#	.org	0xFFFF0000
	.text
	.code32
#	.align	0
.extern	_bootrom
.extern _Fibonacci

#
#   Real mode segments
#
.set C_SEG_REAL,0x0000
.set S_SEG_REAL,0xC000
.set IDT_SEG_REAL,0x9040
.set GDT_SEG_REAL,0x9050
.set GDT_SEG_LIMIT,0x2FF
.set D1_SEG_REAL,TEST_BASE1 >> 4
.set D2_SEG_REAL,TEST_BASE2 >> 4

.set ESP_REAL,0xfffcfffc


.include "x86_e.asm"
.include "macros_m.asm"
.include "shift_m.asm"

header:
	cpyright

_start:
	cli	
# init IDT
	mov $17,%cx
	movl $error,%edx
	movl $0xfff90000,%eax
	movl $error,%edx
.aloop:
	movw %dx,(%eax)
	movw $0xf000,2(%eax)
#	movw $error,(,%eax,4)
#	movw $0xf000,2(,%eax,4)
	addl $4,%eax
	loop .aloop

	mov $ESP_REAL,%esp

#-------------------------------------------------------------------------------
	POST $1
#-------------------------------------------------------------------------------
#
#   Conditional jumps
#
.include "jcc_m.asm"
	testJcc 8
	testJcc 16

	
#-------------------------------------------------------------------------------
	POST $0xE0
#-------------------------------------------------------------------------------

.shifts386FlagsTest:

	# SHR al,cl - SHR ax,cl
	# undefined flags:
	#  CF when cl>7 (byte) or cl>15 (word):
	#    if byte operand and cl=8 or cl=16 or cl=24 then CF=MSB(operand)
	#    if word operand and cl=16 then CF=MSB(operand)
	#  OF when cl>1: set according to result
	#  AF when cl>0: always 1
	# shift count is modulo 32 so if cl=32 then result is equal to cl=0

	tsbf sarb, $0x81, 	$1, 	$0, 	$(PS_CF|PS_AF|PS_OF)
	tsbf sarb, $0x82,   $2,  $0,     $(PS_CF|PS_AF)
	testShiftBFlags   sarb, $0x80,   $8,  $0,     $(PS_CF|PS_PF|PS_AF|PS_ZF)

	#testShiftBFlags   sarb, $0x00,   $8,  $PS_CF, $(PS_PF|PS_AF|PS_ZF)
	#testShiftBFlags   sarb, $0x80,   $16, $0,     $(PS_CF|PS_PF|PS_AF|PS_ZF)
	#testShiftBFlags   sarb, $0x00,   $16, $PS_CF, $(PS_PF|PS_AF|PS_ZF)
	#testShiftBFlags   sarb, $0x80,   $24, $0,     $(PS_CF|PS_PF|PS_AF|PS_ZF)
	#testShiftBFlags   sarb, $0x00,   $24, $PS_CF, $(PS_PF|PS_AF|PS_ZF)
	#testShiftBFlags   sarb, $0x80,   $32, $0,     $0
	#testShiftWFlags   sarw, $0x8000, $16, $0,     $(PS_CF|PS_PF|PS_AF|PS_ZF)
	#testShiftWFlags   sarw, $0x0000, $16, $PS_CF, $(PS_PF|PS_AF|PS_ZF)
	#testShiftWFlags   sarw, $0x8000, $32, $0,     $0

	# SHL al,cl - SHL ax,cl
	# undefined flags:
	#  CF when cl>7 (byte) or cl>15 (word):
	#    if byte operand and cl=8 or cl=16 or cl=24 then CF=LSB(operand)
	#    if word operand and cl=16 then CF=LSB(operand)
	#  OF when cl>1: set according to result
	#  AF when cl>0: always 1
	# shift count is modulo 32 so if cl=32 then result is equal to cl=0
	#testShiftBFlags   salb, $0x81, $1,  $0,     $(PS_CF|PS_AF|PS_OF)
	#testShiftBFlags   salb, $0x41, $2,  $0,     $(PS_CF|PS_AF|PS_OF)
	#testShiftBFlags   salb, $0x01, $8,  $0,     $(PS_CF|PS_PF|PS_AF|PS_ZF|PS_OF)
	#testShiftBFlags   salb, $0x00, $8,  $PS_CF, $(PS_PF|PS_AF|PS_ZF)
	#testShiftBFlags   salb, $0x01, $16, $0,     $(PS_CF|PS_PF|PS_AF|PS_ZF|PS_OF)
	#testShiftBFlags   salb, $0x00, $16, $PS_CF, $(PS_PF|PS_AF|PS_ZF)
	#testShiftBFlags   salb, $0x01, $24, $0,     $(PS_CF|PS_PF|PS_AF|PS_ZF|PS_OF)
	#testShiftBFlags   salb, $0x00, $24, $PS_CF, $(PS_PF|PS_AF|PS_ZF)
	#testShiftBFlags   salb, $0x01, $32, $0,     $0
	#testShiftWFlags   salw, $0x01, $16, $0,     $(PS_CF|PS_PF|PS_AF|PS_ZF|PS_OF)
	#testShiftWFlags   salw, $0x00, $16, $PS_CF, $(PS_PF|PS_AF|PS_ZF)
	#testShiftWFlags   salw, $0x01, $32, $0,     $0

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
