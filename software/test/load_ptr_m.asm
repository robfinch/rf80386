#
#   Tests LSS,LDS,LES,LFS,LGS in 16 and 32 bit mode
#   %1 segment register name, one of ss,ds,es,fs,gs
#   [ed:di] memory address to use for the pointer
#   Uses: nothing
#

.macro testLoadPtr arg1
	mov \arg1,%cx
	mov %es,%dx

	movw $0x1234,(%es:%di)
	movw $0xabcd,2(%es:%di)
	l\arg1 (%es:%di),%bx
	mov \arg1,%ax
	cmp $0xabcd,%ax
	jne error
	cmp $0x1234,%bx
	jne error

	mov %dx,%es

	movd 0x12345678,(%es:%di)
	movw 0xbcde,4(%es:%di)
	l\arg1 (%es:%di),%ebx
	mov \arg1,%ax
	cmp $0xbcde,%ax
	jne error
	cmp $0x12345678,%ebx
	jne error

	mov %dx,%es
	mov %cx,\arg1
.endm
