#
#   Tests MOV from segment registers in real mode
#
#   %1 the segment register to test
#
.macro testMovSegR_real arg1
	.if \arg1 = cs
	mov $C_SEG_REAL,%dx
	.else
	mov $D1_SEG_REAL,%dx
	.endif

	# MOV reg to Sreg
	.if \arg1 = cs
	realModeFaultTest EX_UD, "mov %dx", \arg1 # test for #UD
	.else
	mov %dx,%\arg1
	.endif

	# MOV Sreg to 16 bit reg
	xor %ax,%ax
	mov %\arg1,%ax
	cmp %dx,%ax
	jne error

	# MOV Sreg to 32 bit reg
	mov $-1,%eax
	mov %\arg1,%eax
	# bits 31:16 are undefined for Pentium and earlier processors.
	# TODO: verify on real hw and check TEST_UNDEF
	cmp %dx,%ax
	jne error

	# MOV Sreg to word mem
	movw $0xbeef,0
	mov %\arg1,0
	cmp %dx,0
	jne error

	# MOV word mem to Sreg
	.if \arg1 = cs
	realModeFaultTest EX_UD, "mov 0", \arg1 # test for #UD
	.else
	mov %ds,%cx	 	# save current DS in CX
	xor %ax,%ax
	mov %ax,%\arg1
	.if \arg1 = ds
	mov %cx,%es
	mov %es:0,%\arg1
	.else
	mov 0,%\arg1
	.endif
	mov %\arg1,%ax
	cmp %dx,%ax
	jne error
	.endif

.endm


.macro testMovSegR_prot arg1
	mov $-1,%edx
	.if \arg1 = cs
	mov $C_SEG_PROT32,%dx
	%else
	mov $D1_SEG_PROT,%dx
	%endif

	# MOV reg to Sreg
	.if \arg1 = cs
	loadProtModeStack
	protModeFaultTest EX_UD, $0, "mov %dx", \arg1 	# #UD: attempt is made to load the CS register.
	.else
	mov %dx,%\arg1
	.endif

	# MOV Sreg to 16 bit reg
	xor %ax,%ax
	mov %\arg1,%ax
	cmp %dx,%ax
	jne error

	# MOV Sreg to 32 bit reg
	mov $-1,%eax
	mov %\arg1,%eax
	# bits 31:16 are undefined for Pentium and earlier processors.
	# TODO: verify on real hw and check TEST_UNDEF
	cmp %dx,%ax
	jne error

	# MOV Sreg to word mem
	movl $-1,0
	mov %\arg1,0
	cmp %edx,0
	jne error

	# MOV word mem to Sreg
	.if \arg1 = cs
	protModeFaultTest EX_UD, $0, "mov 0", \arg1 # test for #UD
	.else
	mov %ds,%cx 	# save current DS in CX
	mov $DTEST_SEG_PROT,%ax
	mov %ax,%\arg1
	.if %1 = ds
	mov %cx,%es
	mov %es:0,%\arg1
	.else
	mov 0,%\arg1
	.endif
	mov %\arg1,%ax
	cmp %dx,%ax
	jne error
	.endif

	loadProtModeStack
	.if \arg1 = ss
	# #GP(0) If attempt is made to load SS register with NULL segment selector.
	mov $NULL,%ax
	protModeFaultTest EX_GP, $0, "mov %ax", \arg1
	# #GP(selector) If the SS register is being loaded and the segment selector's RPL and the segment descriptor’s DPL are not equal to the CPL.
	mov $DPL1_SEG_PROT|1,%ax
	protModeFaultTest EX_GP, $DPL1_SEG_PROT, "mov %ax" ,\arg1
	# #GP(selector) If the SS register is being loaded and the segment pointed to is a non-writable data segment.
	mov $RO_SEG_PROT,%ax
	protModeFaultTest EX_GP, $RO_SEG_PROT, "mov %ax", \arg1
	# #SS(selector) If the SS register is being loaded and the segment pointed to is marked not present.
	mov $NP_SEG_PROT,%ax
	protModeFaultTest EX_SS, $NP_SEG_PROT, "mov %ax", \arg1
	.endif
	.if \arg1 != cs
	# #GP(selector) If segment selector index is outside descriptor table limits.
	mov $0xFFF8,%ax
	protModeFaultTest EX_GP, $0xfff8, "mov %ax", \arg1
	.if \arg1 != ss
	# #NP(selector) If the DS, ES, FS, or GS register is being loaded and the segment pointed to is marked not present.
	mov $NP_SEG_PROT,%ax
	protModeFaultTest EX_NP, $NP_SEG_PROT, "mov %ax", \arg1
	# #GP(selector) If the DS, ES, FS, or GS register is being loaded and the segment pointed to is not a data or readable code segment.
	mov $SYS_SEG_PROT,%ax
	protModeFaultTest EX_GP, $SYS_SEG_PROT, "mov %ax", \arg1
	# #GP(selector)
	# If the DS, ES, FS, or GS register is being loaded and the segment pointed to is a data or nonconforming code segment, but both the RPL and the CPL are greater than the DPL.
	call switchToRing3 # CPL=3
	mov $DTEST_SEG_PROT|3,%ax 	# RPL=3,DPL=0
	protModeFaultTest EX_GP, $DTEST_SEG_PROT, "mov %ax", \arg1
	call switchToRing0
	.endif
	.endif

.endm
