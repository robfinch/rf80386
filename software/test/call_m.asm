#
#   Tests Call near by displacement and register indirect
#   Stack must be initilized.
#   %1: stack pointer register
#   Uses: AX, EBX, Flags
#
.macro testCallNear arg1

	.ifc \arg1, sp
		mov %\arg1,%ax
rel16\@:
		clc
#		data16
		callw nearfn16\@
		jnc error
		jmp rel32\@
nearfn16\@:
		sub $2,%ax
		cmp %ax,%\arg1
		jne error
		add $2,%ax
		stc
#		data16
		ret
		jmp error

rel32\@:
		clc
		data32
		call nearfn32\@
		jnc error
		jmp rm16\@
nearfn32\@:
		sub $4,%ax
		cmp %ax,%\arg1
		jne error
		add $4,%ax
		stc
		data32
		ret
		jmp error

rm16\@:
		clc
		mov $nearfn16\@,%bx
#		data16
		call %bx
		jnc error
rm32\@:
		clc
		mov $nearfn32\@-TEST_CODE,%ebx
		call %ebx
		jnc error
	.else
		mov %\arg1,%eax
rel16\@:
		clc
#		data16
		callw nearfn16\@
		jnc error
		jmp rel32\@
nearfn16\@:
		sub $2,%eax
		cmp %eax,%\arg1
		jne error
		add $2,%eax
		stc
#		data16
		ret
		jmp error

rel32\@:
		clc
#		data32
		calll nearfn32\@
		jnc error
		jmp rm16\@
nearfn32\@:
		sub $4,%eax
		cmp %eax,%\arg1
		jne error
		add $4,%eax
		stc
		data32
		ret
		jmp error

rm16\@:
		clc
		mov $nearfn16\@,%bx
#		data16
		call %bx
		jnc error
rm32\@:
		clc
		mov $nearfn32\@-TEST_CODE,%ebx
#		data32
		call %ebx
		jnc error
	.endif
.endm

#
#   Tests Call far by immediate and memory pointers
#   Stack must be initilized
#   %1: code segment
#   Uses: AX, Flags, DS:SI as scratch memory
#
.macro testCallFar arg1
	mov %sp,%ax

	clc
#	data16
	callw $\arg1,$farfn16\@
	jnc error
	jmp o32\@
farfn16\@:
	sub $4,%ax
	cmp %ax,%sp
	jne error
	add $4,%ax
	stc
#	data16
	retl
	jmp error

o32\@:
	clc
	calll $\arg1,$farfn32\@
	jnc error
	jmp m1616\@
farfn32\@:
	sub $8,%ax
	cmp %ax,%sp
	jne error
	add $8,%ax
	stc
	retl
	jmp error

m1616\@:
	clc
	movw $farfn16\@,(%si)
	movw $\arg1,2(%si)
#	data16
	calll (%si)
	jnc error
m1632\@:
	clc
	movl $farfn32\@-TEST_CODE,(%si)
	movw $\arg1,4(%si)
#	data32
	calll (%si)
	jnc error
exit\@:
.endm
