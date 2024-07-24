# t386.asm rf386 assembly language

	.bss
	.space	10

	.data
	.space	10

#	.org	0xFFFF0000
	.text
#	.align	0
.extern	_bootrom

_start:
	cli	
# initRealModeIDT
	xor %eax,%eax
	mov %ax,%ds
	mov $17,%cx
aloop:
	movw $error,(%eax*4)
	movw $0xf000,2(%eax*4)
	inc %ax
	loop aloop

	xor %eax,%eax
	mov %ax,%ss
	mov $0xFFFD0000,%esp

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
