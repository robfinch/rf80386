	.file	"..\boot\debug.c"
	.text
	.globl	_DBGClearScreen
_DBGClearScreen:
	pushl	%ebx
	subl	$32,%esp
	movl	$4273995776,%edx
	movl	_DBGAttr,%ebx
	orl	$32,%ebx
	xorl	%ecx,%ecx
l7:
	movl	%ecx,%eax
	sall	$2,%eax
	addl	%edx,%eax
	movl	%ebx,(%eax)
	incl	%ecx
	cmpl	$1984,%ecx
	jl	l7
	addl	$32,%esp
	popl	%ebx
	ret
	.type	_DBGClearScreen,@function
	.size	_DBGClearScreen,.-_DBGClearScreen
l9:
	subl	$16,%esp
	movl	20(%esp),%eax
	sall	$2,%eax
	addl	$-20447232,%eax
	movl	24(%esp),%ecx
	movl	%ecx,(%eax)
	addl	$16,%esp
	ret
	.type	l9,@function
	.size	l9,.-l9
	.globl	_AsciiToScreen
_AsciiToScreen:
	movb	4(%esp),%al
	ret
	.type	_AsciiToScreen,@function
	.size	_AsciiToScreen,.-_AsciiToScreen
	.globl	_ScreenToAscii
_ScreenToAscii:
	movb	4(%esp),%al
	ret
	.type	_ScreenToAscii,@function
	.size	_ScreenToAscii,.-_ScreenToAscii
	.globl	_DBGSetCursorPos
_DBGSetCursorPos:
	subl	$4,%esp
	movw	8(%esp),%ax
	movw	%ax,4274118428
	addl	$4,%esp
	ret
	.type	_DBGSetCursorPos,@function
	.size	_DBGSetCursorPos,.-_DBGSetCursorPos
	.globl	_DBGUpdateCursorPos
_DBGUpdateCursorPos:
	subl	$20,%esp
	movsbl	_DBGCursorRow,%ecx
	sall	$6,%ecx
	movsbl	_DBGCursorCol,%eax
	addl	%ecx,%eax
	pushl	%eax
	call	_DBGSetCursorPos
	addl	$4,%esp
	addl	$20,%esp
	ret
	.type	_DBGUpdateCursorPos,@function
	.size	_DBGUpdateCursorPos,.-_DBGUpdateCursorPos
	.globl	_DBGHomeCursor
_DBGHomeCursor:
	movb	$0,_DBGCursorCol
	movb	$0,_DBGCursorRow
	call	_DBGUpdateCursorPos
	ret
	.type	_DBGHomeCursor,@function
	.size	_DBGHomeCursor,.-_DBGHomeCursor
	.globl	_DBGBlankLine
_DBGBlankLine:
	pushl	%ebx
	subl	$52,%esp
	movl	60(%esp),%eax
	sall	$6,%eax
	sall	$2,%eax
	movl	$-20971520,%edx
	addl	%eax,%edx
	movl	_DBGAttr,%ebx
	orl	$32,%ebx
	xorl	%ecx,%ecx
l28:
	movl	%ecx,%eax
	sall	$2,%eax
	addl	%edx,%eax
	movl	%ebx,(%eax)
	incl	%ecx
	cmpl	$64,%ecx
	jl	l28
	addl	$52,%esp
	popl	%ebx
	ret
	.type	_DBGBlankLine,@function
	.size	_DBGBlankLine,.-_DBGBlankLine
	.globl	_DBGScrollUp
_DBGScrollUp:
	pushl	%ebx
	pushl	%esi
	subl	$40,%esp
	movl	$4273995776,%ebx
	movl	$1984,%esi
	xorl	%edx,%edx
l36:
	movl	%edx,%eax
	addl	$64,%eax
	sall	$2,%eax
	addl	%ebx,%eax
	movl	%edx,%ecx
	sall	$2,%ecx
	addl	%ebx,%ecx
	pushl	%edx
	movl	(%eax),%edx
	movl	%edx,(%ecx)
	popl	%edx
	incl	%edx
	cmpl	%edx,%esi
	jg	l36
	pushl	$30
	call	_DBGBlankLine
	addl	$4,%esp
	addl	$40,%esp
	popl	%esi
	popl	%ebx
	ret
	.type	_DBGScrollUp,@function
	.size	_DBGScrollUp,.-_DBGScrollUp
	.globl	_DBGIncrementCursorRow
_DBGIncrementCursorRow:
	subl	$8,%esp
	movsbl	_DBGCursorRow,%eax
	cmpl	$30,%eax
	jge	l41
	incb	_DBGCursorRow
	call	_DBGUpdateCursorPos
	jmp	l38
l41:
	call	_DBGScrollUp
l38:
	addl	$8,%esp
	ret
	.type	_DBGIncrementCursorRow,@function
	.size	_DBGIncrementCursorRow,.-_DBGIncrementCursorRow
	.globl	_DBGIncrementCursorPos
_DBGIncrementCursorPos:
	subl	$8,%esp
	movb	_DBGCursorCol,%al
	incb	%al
	movb	%al,_DBGCursorCol
	movsbl	%al,%eax
	cmpl	$64,%eax
	jge	l45
	call	_DBGUpdateCursorPos
	jmp	l42
l45:
	movb	$0,_DBGCursorCol
	call	_DBGIncrementCursorRow
l42:
	addl	$8,%esp
	ret
	.type	_DBGIncrementCursorPos,@function
	.size	_DBGIncrementCursorPos,.-_DBGIncrementCursorPos
	.globl	_DBGDisplayChar
_DBGDisplayChar:
	pushl	%ebx
	pushl	%esi
	subl	$160,%esp
	movb	172(%esp),%dl
	movsbl	%dl,%eax
	movl	%eax,%ecx
	subl	$8,%ecx
	cmpl	$5,%ecx
	ja	l86
	jmp	*l85(,%ecx,4)
	.align	2
l85:
	.long	l71
	.long	l79
	.long	l50
	.long	l86
	.long	l78
	.long	l49
l86:
	movl	%eax,%ecx
	subl	$144,%ecx
	cmpl	$4,%ecx
	ja	l88
	jmp	*l87(,%ecx,4)
	.align	2
l87:
	.long	l54
	.long	l51
	.long	l60
	.long	l57
	.long	l63
l88:
	cmpl	$153,%eax
	jz	l66
	jmp	l80
l49:
	movb	$0,_DBGCursorCol
	call	_DBGUpdateCursorPos
	jmp	l48
l50:
	call	_DBGIncrementCursorRow
	jmp	l48
l51:
	movsbl	_DBGCursorCol,%eax
	cmpl	$63,%eax
	jge	l48
	incb	_DBGCursorCol
	call	_DBGUpdateCursorPos
	jmp	l48
l54:
	movsbl	_DBGCursorRow,%eax
	testl	%eax,%eax
	jle	l48
	decb	_DBGCursorRow
	call	_DBGUpdateCursorPos
	jmp	l48
l57:
	movsbl	_DBGCursorCol,%eax
	testl	%eax,%eax
	jle	l48
	decb	_DBGCursorCol
	call	_DBGUpdateCursorPos
	jmp	l48
l60:
	movsbl	_DBGCursorRow,%eax
	cmpl	$30,%eax
	jge	l48
	incb	_DBGCursorRow
	call	_DBGUpdateCursorPos
	jmp	l48
l63:
	movsbl	_DBGCursorCol,%eax
	testl	%eax,%eax
	jnz	l65
	movb	$0,_DBGCursorRow
l65:
	movb	$0,_DBGCursorCol
	call	_DBGUpdateCursorPos
	jmp	l48
l66:
	movsbl	_DBGCursorRow,%eax
	sall	$6,%eax
	sall	$2,%eax
	movl	$-20971520,%esi
	addl	%eax,%esi
	movsbl	_DBGCursorCol,%ebx
	cmpl	$63,%ebx
	jge	l83
l81:
	movl	%ebx,%eax
	incl	%eax
	movl	%eax,%ecx
	sall	$2,%ecx
	addl	%esi,%ecx
	movl	%ebx,%edx
	sall	$2,%edx
	addl	%esi,%edx
	pushl	%eax
	movl	(%ecx),%eax
	movl	%eax,(%edx)
	popl	%eax
	movl	%eax,%ebx
	cmpl	$63,%eax
	jl	l81
l83:
	movl	_DBGAttr,%eax
	orl	$32,%eax
	movl	%ebx,%ecx
	sall	$2,%ecx
	addl	%esi,%ecx
	movl	%eax,(%ecx)
	jmp	l48
l71:
	movsbl	_DBGCursorCol,%eax
	testl	%eax,%eax
	jle	l48
	movb	_DBGCursorCol,%al
	decb	%al
	movb	%al,_DBGCursorCol
	movsbl	_DBGCursorRow,%ecx
	sall	$6,%ecx
	sall	$2,%ecx
	movl	$-20971520,%esi
	addl	%ecx,%esi
	movsbl	%al,%ebx
	cmpl	$63,%ebx
	jge	l84
l82:
	movl	%ebx,%eax
	incl	%eax
	movl	%eax,%ecx
	sall	$2,%ecx
	addl	%esi,%ecx
	movl	%ebx,%edx
	sall	$2,%edx
	addl	%esi,%edx
	pushl	%eax
	movl	(%ecx),%eax
	movl	%eax,(%edx)
	popl	%eax
	movl	%eax,%ebx
	cmpl	$63,%eax
	jl	l82
l84:
	movl	_DBGAttr,%eax
	orl	$32,%eax
	movl	%ebx,%ecx
	sall	$2,%ecx
	addl	%esi,%ecx
	movl	%eax,(%ecx)
	jmp	l48
l78:
	call	_DBGClearScreen
	call	_DBGHomeCursor
	jmp	l48
l79:
	pushl	$32
	call	_DBGDisplayChar
	pushl	$32
	call	_DBGDisplayChar
	pushl	$32
	call	_DBGDisplayChar
	pushl	$32
	call	_DBGDisplayChar
	addl	$16,%esp
	jmp	l48
l80:
	movsbl	_DBGCursorRow,%eax
	sall	$6,%eax
	movsbl	_DBGCursorCol,%ecx
	addl	%eax,%ecx
	movsbl	%dl,%eax
	orl	_DBGAttr,%eax
	sall	$2,%ecx
	addl	$-20971520,%ecx
	movl	%eax,(%ecx)
	call	_DBGIncrementCursorPos
l48:
	addl	$160,%esp
	popl	%esi
	popl	%ebx
	ret
	.type	_DBGDisplayChar,@function
	.size	_DBGDisplayChar,.-_DBGDisplayChar
	.globl	_DBGCRLF
_DBGCRLF:
	pushl	$13
	call	_DBGDisplayChar
	pushl	$10
	call	_DBGDisplayChar
	addl	$8,%esp
	ret
	.type	_DBGCRLF,@function
	.size	_DBGCRLF,.-_DBGCRLF
	.globl	_DBGDisplayString
_DBGDisplayString:
	pushl	%ebx
	subl	$8,%esp
	movl	16(%esp),%ebx
	movb	(%ebx),%cl
	testb	%cl,%cl
	jz	l97
l96:
	movsbl	%cl,%eax
	pushl	%eax
	call	_DBGDisplayChar
	incl	%ebx
	movb	(%ebx),%cl
	addl	$4,%esp
	testb	%cl,%cl
	jnz	l96
l97:
	addl	$8,%esp
	popl	%ebx
	ret
	.type	_DBGDisplayString,@function
	.size	_DBGDisplayString,.-_DBGDisplayString
	.globl	_DBGDisplayStringCRLF
_DBGDisplayStringCRLF:
	pushl	4(%esp)
	call	_DBGDisplayString
	call	_DBGCRLF
	addl	$4,%esp
	ret
	.type	_DBGDisplayStringCRLF,@function
	.size	_DBGDisplayStringCRLF,.-_DBGDisplayStringCRLF
	.globl	_DBGAttr
	.type	_DBGAttr,@object
	.size	_DBGAttr,4
	.comm	_DBGAttr,4
	.globl	_DBGCursorCol
	.type	_DBGCursorCol,@object
	.size	_DBGCursorCol,1
	.comm	_DBGCursorCol,1
	.globl	_DBGCursorRow
	.type	_DBGCursorRow,@object
	.size	_DBGCursorRow,1
	.comm	_DBGCursorRow,1
