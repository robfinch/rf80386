#
# Advances the base address of data segments used by tests, D1_SEG_PROT and
# D2_SEG_PROT.
#
# Loads DS with D1_SEG_PROT and ES with D2_SEG_PROT.
#
.macro advTestSegProt
	advTestBase
	updLDTDescBase D1_SEG_PROT,TEST_BASE1
	updLDTDescBase D2_SEG_PROT,TEST_BASE2
	mov $D1_SEG_PROT,%dx
	mov %dx,%ds
	mov $D2_SEG_PROT,%dx
	mov %dx,%es
.endm


#
#   Defines an interrupt gate in ROM, given a selector (%1) and an offset (%2)
#
.macro defIntGate arg1,arg2
	.2byte (\arg2 & 0xffff) # OFFSET 15-0
	.2byte \arg1 	# SELECTOR
	.2byte ACC_TYPE_GATE386_INT | ACC_PRESENT # acc byte
	.2byte (\arg2 >> 16) & 0xffff # OFFSET 31-16
.endm

.set GDTSelDesc,0
#
#   Defines a GDT descriptor in ROM, given a name (%1), base (%2), limit (%3),
#   acc byte (%4), and ext nibble (%5)
#
.macro defGDTDescROM arg1,arg2,arg3,arg4,arg5
	.ifnc \arg1, 0
	.set \arg1,GDTSelDesc
	.endif
	.2byte (\arg3 & 0x0000ffff) # LIMIT 15-0
	.2byte (\arg2 & 0x0000ffff) # BASE 15-0
	.2byte ((\arg2 & 0x00ff0000) >> 16) | \arg4 # BASE 23-16 | acc byte
	.2byte ((\arg3 & 0x000f0000) >> 16) | \arg5 | ((\arg2 & 0xff000000) >> 16) # LIMIT 19-16 | ext nibble | BASE 31-24
	.ifnc \arg1, 0
	.set GDTSelDesc,GDTSelDesc+8
	.endif
.endm
#
#   Defines a GDT descriptor in RAM, given a name (%1), base (%2), limit (%3),
#   acc byte (%4), and ext nibble (%5)
#
.macro defGDTDesc arg1,arg2=0,arg3=0,arg4=0,arg5=0
	.ifnc \arg1, 0
	.set \arg1,GDTSelDesc
	.endif
	lds %cs:ptrGDTreal - TEST_CODE,%ebx # this macro is used in real mode to set up prot mode env.
	mov $\arg1,%eax
	mov $\arg2,%esi
	mov $\arg3,%edi
	mov $\arg4|\arg5,%dx
	initDescriptor
	.ifnc \arg1, 0
	.set GDTSelDesc,GDTSelDesc+8
	.endif
.endm

#
#   Defines a LDT descriptor, given a name (%1), base (%2), limit (%3), type (%4), and ext (%5)
#
.set LDTSelDesc,4
.macro defLDTDesc arg1,arg2,arg3,arg4,arg5=0
	.set \arg1,LDTSelDesc
	lds %cs:ptrLDTprot,%ebx  # this macro is used in prot mode to set up prot mode env.
	mov $\arg1,%eax
	mov $\arg2,%esi
	mov $\arg3,%edi
	mov $\arg4|\arg5,%dx
	initDescriptor
	.set LDTSelDesc,LDTSelDesc+8
.endm

#
#   Updates a LDT descriptor, given a name (%1), base (%2), limit (%3), type (%4), and ext (%5)
#
.macro updLDTDesc arg1,arg2,arg3,arg4,arg5
	pushad
	mov %ds,%ax
	push %ax
	lds %cs:ptrLDTprot,%ebx  # this macro is used in prot mode to set up prot mode env.
	mov $\arg1,%eax
	mov $\arg2,%esi
	mov $\arg3,%edi
	mov $\arg4|\arg5,%dx
	call initDescriptorProt
	pop %ax
	mov %ax,%ds
	popad
.endm

#
# Updates the access byte of a descriptor in the LDT
# %1 LDT selector
# %2 access byte new value (ACC_* or'd equs)
# Uses DS

.macro updLDTDescAcc arg1,arg2
	pushad
	pushf
	lds %cs:ptrLDTprot,%ebx
	add $(\arg1) & 0xFFF8,%ebx
	movb $(\arg2)>>8,5(%ebx) # acc byte
	popf
	popad
.endm

#
# Updates the base of a descriptor in the LDT
# %1 LDT selector
# %2 new base
# Uses DS,EBX,flags

.macro updLDTDescBase arg1,arg2
	lds %cs:ptrLDTprot,%ebx
	add $(\arg1) & 0xFFF8,%ebx
	movw $(\arg2)&0xFFFF,2(%ebx)      # BASE 15-0
	movb $((\arg2)>>16)&0xFF,4(%ebx) 	# BASE 23-16
	movb $((\arg2)>>24)&0xFF,7(%ebx) 	# BASE 31-24
.endm

#
# Updates the values of a GDT's entry with a Call Gate
# %1 GDT selector
# %2 destination selector
# %3 destination offset
# %4 word count
# %5 DPL
#
.macro updCallGate arg1,arg2,arg3,arg4,arg5
	lfs %cs:ptrGDTprot,%ebx
	mov $\arg1,%eax
	mov $\arg2,%esi
	mov $\arg3,%edi
	mov $\arg4|\arg5,%dx
	call initCallGate
.endm




#
# Loads SS:ESP with a pointer to the prot mode stack
#
.macro loadProtModeStack
	lss %cs:ptrSSprot,%esp
.endm


#
# Set a int gate on the IDT in protected mode
#
# %1: vector
# %2: offset
# %3: DPL, use ACC_DPL_* equs (optional)
#
# the stack must be initialized
#
.macro setProtModeIntGate arg1,arg2,arg3
	pushad
	pushf
	mov %ds,%ax  	# save ds
	push %ax
	mov $\arg1,%eax
	mov $\arg2,%edi
	.if \arg3 != -1
	mov $\arg3,%dx
	.else
	mov %cs,%dx
	and $7,%dx
	shl $13,%dx
	.endif
	cmp $ACC_DPL_0,%dx
	jne dpl3\@
dpl0\@:
	mov $C_SEG_PROT32,%esi
	jmp cont\@
dpl3\@:
	mov $CU_SEG_PROT32,%esi
cont\@:
	mov %cs,%cx
	test $7,%cx
	jnz ring3\@
ring0\@:
	lds (%cs:ptrIDTprot),%ebx
	jmp call\@
ring3\@:
	lds (%cs:ptrIDTUprot),%ebx
call\@:
	call initIntGateProt
	pop %ax
	mov %ax,%ds  # restore ds
	popf
	popad
.endm

#
# Tests a fault
#
# %1: vector
# %2: expected error code
# %3: fault causing instruction (can't be a call unless the call is the faulting instruction)
#
# the stack must be initialized
#
.macro protModeFaultTest arg1,arg2,arg3
	setProtModeIntGate \arg1, continue\@
test\@:
	\arg3
	jmp error
continue\@:
	protModeExcCheck \arg1, \arg2, test\@
	setProtModeIntGate \arg1, DefaultExcHandler, ACC_DPL_0
.endm

# %1: vector
# %2: expected error code
# %3: the provilege level the test code will run in
# %4: the expected value of pushed EIP (specify if %5 is a call, otherwise use -1)
# %5: fault causing code (can be a call to procedure)
#
# The fault handler is executed in ring 0. The caller must reset the data segments.
#
.macro protModeFaultTestEx arg1,arg2,arg3,arg4,arg5
	setProtModeIntGate \arg1, continue\@, ACC_DPL_0
test\@:
	\arg5
	jmp error
continue\@:
	.if \arg3 = 0
		.set expectedCS,C_SEG_PROT32
	.else
		.set expectedCS,CU_SEG_PROT32|3
	.endif
	.if \arg4 = -1
		protModeExcCheck \arg1, \arg2, test\@, expectedCS
	.else
		protModeExcCheck \arg1, \arg2, \arg4, expectedCS
	.endif
	setProtModeIntGate \arg1, DefaultExcHandler, ACC_DPL_0
.endm

#
# Checks exception result and restores the previous handler
#
# %1: vector
# %2: expected error code
# %3: expected pushed value of EIP
# %4: expected pushed value of CS (optional)
#
.macro protModeExcCheck arg1,arg2,arg3,arg4
	.if \arg1 == 8 || (\arg1 > 10 && \arg1 <= 14)
	.set exc_errcode,4
	cmpl $\arg2,(%ss:%esp)
	jne error
	.else
	.set exc_errcode,0
	.endif
	.if \arg4 != -1
		cmpl $\arg4,exc_errcode+4(%ss:esp)
		jne error
	.else
		mov %cs,%bx
		test $7,%bx
		jnz ring3\@
		ring0\@:
		cmpl $C_SEG_PROT32,exc_errcode+4(%ss:%esp) 
		jne error
		jmp continue\@
		ring3\@:
		cmpl $CU_SEG_PROT32|3,exc_errcode+4(%ss:%esp)
		jne error
		continue\@:
	.endif
	cmpl $\arg3,exc_errcode(%ss:%esp)
	jne error
	add $12+exc_errcode,%esp
.endm
