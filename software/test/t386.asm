# t386.asm rf386 assembly language

	.set POST_PORT,0x190

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

.include "x86_e.asm"
.include "macros_m.asm"

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

	mov $0xFFFD0000,%esp
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
