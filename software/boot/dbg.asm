	.text
	.code32
_DBGHideCursor:
	movl %eax,4(%esp)
	cmpl $0,%eax
	je .j1
	movw $0xffff,0xFEC80020
	ret
.j1:
	movw $0x00E7,0xFEC80020
	ret
