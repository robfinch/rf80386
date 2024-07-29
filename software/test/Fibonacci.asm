	.file	"Fibonacci.c"
	.text
	.globl	_Fibonacci
_Fibonacci:
	pushl	%ebx
	pushl	%esi
	subl	$20,%esp
	movl	32(%esp),%esi
	xorl	%ebx,%ebx
	movl	$1,%ecx
	movl	$2,%edx
	cmpl	$2,%esi
	jle	l8
l7:
	movl	%ecx,%eax
	addl	%ebx,%eax
	movl	%ecx,%ebx
	movl	%eax,%ecx
	incl	%edx
	cmpl	%edx,%esi
	jg	l7
l8:
	movl	%ebx,%eax
	addl	$20,%esp
	popl	%esi
	popl	%ebx
	ret
	.type	_Fibonacci,@function
	.size	_Fibonacci,.-_Fibonacci
