	.file	"..\boot\bootrom.c"
	.text
l5:
	subl	$16,%esp
	movl	$4276092672,%ecx
	xorl	%eax,%eax
l12:
	movl	%eax,%edx
	shrl	$17,%edx
	movl	%edx,(%ecx)
	incl	%eax
	cmpl	$6000000,%eax
	jb	l12
	addl	$16,%esp
	ret
	.type	l5,@function
	.size	l5,.-l5
l14:
	pushl	%ebx
	pushl	%esi
	subl	$92,%esp
	movl	108(%esp),%esi
	movl	104(%esp),%ebx
	xorl	%edx,%edx
	testl	%esi,%esi
	jle	l22
l21:
	movl	%edx,%eax
	sall	$2,%eax
	movl	%eax,%ecx
	sall	$2,%ecx
	addl	%ebx,%ecx
	movl	$0,(%ecx)
	movl	%eax,%ecx
	incl	%ecx
	sall	$2,%ecx
	addl	%ebx,%ecx
	movl	$0,(%ecx)
	movl	%eax,%ecx
	addl	$2,%ecx
	sall	$2,%ecx
	addl	%ebx,%ecx
	movl	$0,(%ecx)
	addl	$3,%eax
	sall	$2,%eax
	addl	%ebx,%eax
	movl	$0,(%eax)
	incl	%edx
	cmpl	%edx,%esi
	jg	l21
l22:
	addl	$92,%esp
	popl	%esi
	popl	%ebx
	ret
	.type	l14,@function
	.size	l14,.-l14
l23:
	pushl	%ebx
	pushl	%esi
	subl	$112,%esp
	movl	$4294705152,%esi
	xorl	%ebx,%ebx
l30:
	movl	%ebx,%eax
	incl	%eax
	sall	$2,%eax
	addl	$l4,%eax
	movl	%ebx,%ecx
	sall	$2,%ecx
	addl	$l4,%ecx
	movl	(%ecx),%edx
	sall	$2,%edx
	addl	%esi,%edx
	pushl	%ecx
	movl	(%eax),%ecx
	movl	%ecx,(%edx)
	popl	%ecx
	movl	%ebx,%eax
	addl	$2,%eax
	sall	$2,%eax
	addl	$l4,%eax
	movl	(%ecx),%ecx
	incl	%ecx
	sall	$2,%ecx
	addl	%esi,%ecx
	movl	(%eax),%edx
	movl	%edx,(%ecx)
	addl	$3,%ebx
	cmpl	$45,%ebx
	jl	l30
	addl	$112,%esp
	popl	%esi
	popl	%ebx
	ret
	.type	l23,@function
	.size	l23,.-l23
	.globl	_bootrom
_bootrom:
	subl	$68,%esp
	movl	$1071673344,_DBGAttr
	movl	$-262144,4294246176
	pushl	$8
	pushl	l1
	call	l14
	pushl	$64
	pushl	l2
	call	l14
	pushl	$8192
	pushl	l3
	call	l14
	call	l23
	movl	$-1,4276092672
	movl	$0,4276223236
	movl	$-1717986919,4276223240
	movl	$-1717986919,4276223244
	call	l5
	addl	$24,%esp
	addl	$68,%esp
	ret
	.type	_bootrom,@function
	.size	_bootrom,.-_bootrom
	.globl	_DBGAttr
	.type	l4,@object
	.size	l4,180
	.align	4
l4:
	.long	7903
	.long	-289
	.long	-2097147905
	.long	7872
	.long	-320
	.long	-2097147905
	.long	7888
	.long	-304
	.long	-2097147905
	.long	7900
	.long	-292
	.long	-2097147905
	.long	7905
	.long	-287
	.long	-2097147905
	.long	7906
	.long	-286
	.long	-2097147905
	.long	7908
	.long	-284
	.long	-2097147905
	.long	8184
	.long	-8
	.long	-2113925121
	.long	8185
	.long	-7
	.long	-2113925121
	.long	8186
	.long	-6
	.long	-2113925121
	.long	8187
	.long	-5
	.long	-2113925121
	.long	8188
	.long	-4
	.long	-2088759297
	.long	8189
	.long	-3
	.long	-2088759297
	.long	8190
	.long	-2
	.long	-2088759297
	.long	8191
	.long	-1
	.long	-2088759297
	.type	l1,@object
	.size	l1,4
	.data
	.align	4
l1:
	.long	4278189952
	.type	l2,@object
	.size	l2,4
	.align	4
l2:
	.long	4278188032
	.type	l3,@object
	.size	l3,4
	.align	4
l3:
	.long	4277665792
