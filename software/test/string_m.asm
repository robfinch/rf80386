#
#   Tests store, compare, scan, and move string operands
#   %1 data size b=byte, w=word, d=dword
#   %2 direction 0=increment, 1=decrement
#   %3 addressing a16=16-bit, a32=32-bit
#   DS test segment 1
#   ES test segment 2
#
.macro testStringOps arg1,arg2,arg3

	.set value,0x12345678
	.if \arg1 = b
		.set val_size,1
		.set val_mask,0x000000ff
	.endif
	.if \arg1 = w
		.set val_size,2
		.set val_mask,0x0000ffff
	.endif
	.if \arg1 = d
		.set val_size,4
		.set val_mask,0xffffffff
	.endif

	.if \arg2 == 0
		cld
		.set off_value,0x0001ffff-(val_size-1)
		.if \arg3 = 16
			# 16-bit addressing
			.set off_cmp,0x00010000
		.else
			# 32-bit addressing
			.set off_cmp,0x00020000
		.endif
	.else
		std
		.set off_value,0x00010000
		.if \arg3 = 16
			# 16-bit addressing
			.set off_cmp,0x0001ffff-(val_size-1)
		.else
			# 32-bit addressing
			.set off_cmp,0x0000ffff-(val_size-1)
		.endif
	.endif

	.if \arg3 = 16
		.set off_mask,0x0000ffff
	.else
		.set off_mask,0xffffffff
	.endif

	# VERIFY string operands
	.if \arg1 = b
		mov $off_value,%edi
		mov $off_value & off_mask,%ebx
		mov $0,%al
		mov %al,%es:(%ebx)
		mov $value,%al
		addr\arg3
		stosb		 	# STORE EAX in ES:EDI
		.if \arg3 = 16
			addr32
			cmp %al,%es:(%ebx)
		.else
			cmp %al,%es:(%ebx)
		.endif
		jne error
		cmp $off_cmp,%edi
		jne error

		mov $off_value,%esi
		mov $off_value,%edi
		mov $off_value & off_mask,%ebx
		mov %al,%ds:(%ebx)
		mov %al,%es:(%ebx)
		cmp $0,%al
		je error
		addr\arg3
		cmpsb     # COMPARE ES:EDI with DS:ESI
		jne error
		cmp $off_cmp,%edi
		jne error
		cmp $off_cmp,%esi
		jne error

		mov $off_value,%edi
		mov $value,%al
		mov %al,%es:(%ebx)
		cmp $0,%al
		addr\arg3
		scasb     # SCAN/COMPARE ES:EDI with EAX
		jne error
		cmp $off_cmp,%edi
		jne error

		mov $off_value,%esi
		mov $off_value,%edi
		mov $value,%al
		mov %al,%ds:(%ebx)
		mov $0,%al
		mov %al,%es:(%ebx)
		addr\arg3
		movsb        # MOVE data from DS:ESI to ES:EDI
		mov $value,%al
		.if \arg3 = 16
			addr32
			cmp %al,%es:(%ebx)
		.else
			cmp %al,%es:(%ebx)
		.endif
		jne error
		cmp $off_cmp,%edi
		jne error
		cmp $off_cmp,%esi
		jne error

		mov $off_value,%esi
		mov $value,%al
		mov %al,%es:(%ebx)
		xor %eax,%eax
		addr\arg3
		lodsb       # LOAD data from DS:ESI into EAX
		cmp $value & val_mask,%al
		jne error
		cmp $off_cmp,%esi
		jne error
	.endif

	.if \arg1 = w
		mov $off_value,%edi
		mov $off_value & off_mask,%ebx
		mov $0,%ax
		mov %ax,%es:(%ebx)
		mov $value,%ax
		addr\arg3
		stosw     # STORE EAX in ES:EDI
		.if \arg3 = 16
			addr32
			cmp %ax,%es:(%ebx)
		.else
			cmp %ax,%es:(%ebx)
		.endif
		jne error
		cmp $off_cmp,%edi
		jne error

		mov $off_value,%esi
		mov $off_value,%edi
		mov $off_value & off_mask,%ebx
		mov %ax,%ds:(%ebx)
		mov %ax,%es:(%ebx)
		cmp $0,%ax
		je error
		addr\arg3
		cmpsw     # COMPARE ES:EDI with DS:ESI
		jne error
		cmp $off_cmp,%edi
		jne error
		cmp $off_cmp,%esi
		jne error

		mov $off_value,%edi
		mov $value,%ax
		mov %ax,%es:(%ebx)
		cmp $0,%ax
		addr\arg3
		scasw     # SCAN/COMPARE ES:EDI with EAX
		jne error
		cmp $off_cmp,%edi
		jne error

		mov $off_value,%esi
		mov $off_value,%edi
		mov $value,%ax
		mov %ax,%ds:(%ebx)
		mov $0,%ax
		mov %ax,%es:(%ebx)
		addr\arg3
		movsw 					# MOVE data from DS:ESI to ES:EDI
		mov $value,%ax
		.if \arg3 = 16
			addr32
			cmp %ax,%es:(%ebx)
		.else
			cmp %ax,%es:(%ebx)
		.endif
		jne error
		cmp $off_cmp,%edi
		jne error
		cmp $off_cmp,%esi
		jne error

		mov $off_value,%esi
		mov $value,%ax
		mov %ax,%es:(%ebx)
		xor %eax,%eax
		addr\arg3
		lodsw       # LOAD data from DS:ESI into EAX
		cmp $value & val_mask,%ax
		jne error
		cmp $off_cmp,%esi
		jne error
	.endif

	.if \arg1 = d
		mov $off_value,%edi
		mov $off_value & off_mask,%ebx
		mov $0,%eax
		mov %eax,%es:(%ebx)
		mov $value,%eax
		addr\arg3
		stosl     # STORE EAX in ES:EDI
		.if \arg3 = 16
			addr32
			cmp %eax,%es:(%ebx)
		.else
			cmp %eax,%es:(%ebx)
		.endif
		jne error
		cmp $off_cmp,%edi
		jne error

		mov $off_value,%esi
		mov $off_value,%edi
		mov $off_value & off_mask,%ebx
		mov %eax,%ds:(%ebx)
		mov %eax,%es:(%ebx)
		cmp $0,%eax
		je error
		addr\arg3
		cmpsl     # COMPARE ES:EDI with DS:ESI
		jne error
		cmp $off_cmp,%edi
		jne error
		cmp $off_cmp,%esi
		jne error

		mov $off_value,%edi
		mov $value,%eax
		mov %eax,%es:(%ebx)
		cmp $0,%eax
		addr\arg3
		scasl     # SCAN/COMPARE ES:EDI with EAX
		jne error
		cmp $off_cmp,%edi
		jne error

		mov $off_value,%esi
		mov $off_value,%edi
		mov $value,%eax
		mov %eax,%ds:(%ebx)
		mov $0,%eax
		mov %eax,%es:(%ebx)
		addr\arg3
		movsl        # MOVE data from DS:ESI to ES:EDI
		mov $value,%eax
		.if \arg3 = 16
			addr32
			cmp %eax,%es:(%ebx)
		.else
			cmp %eax,%es:(%ebx)
		.endif
		jne error
		cmp $off_cmp,%edi
		jne error
		cmp $off_cmp,%esi
		jne error

		mov $off_value,%esi
		mov $value,%eax
		mov %eax,%es:(%ebx)
		xor %eax,%eax
		addr\arg3
		lodsl       # LOAD data from DS:ESI into EAX
		cmp $value & val_mask,%eax
		jne error
		cmp $off_cmp,%esi
		jne error
	.endif

.endm

#
#   Tests store, compare, scan, and move string operands with repetitions
#   %1 element size b=byte, w=word, d=dword
#   %2 direction 0=increment, 1=decrement
#   %3 addressing a16=16-bit, a32=32-bit
#   DS test segment 1
#   ES test segment 2
#
.macro testStringReps arg1,arg2,arg3

	.set bytes,0x100

	.if \arg1 = b
		.set items,bytes
	.endif
	.if \arg1 = w
		.set items,bytes/2
	.endif
	.if \arg1 = d
		.set items,bytes/4
	.endif

	.if \arg2 == 0
		cld
		.set off_value,0x0001ff00
		.if \arg3 = 16
			# 16-bit addressing
			.set off_cmp,0x00010000
		.else
			# 32-bit addressing
			.set off_cmp,0x00020000
		.endif
	.else
		std
		.set off_value,0x000100ff
		.if \arg3 = 16
			# 16-bit addressing
			.set off_cmp,0x0001ffff
		.else
			# 32-bit addressing
			.set off_cmp,0x0000ffff
		.endif
	.endif

	mov $0x12345678,%eax
	mov $off_value,%esi
	mov $off_value,%edi

	# VERIFY REPs on memory buffers

	# STORE buffers with pattern in EAX
	mov $0x12345678,%eax
	mov $off_value,%esi
	mov $off_value,%edi
	mov $items,%ecx
	.if \arg1 = b
		addr\arg3
		rep
		stosb    # store ECX items at ES:EDI with the value in EAX
	.endif
	.if \arg1 = w
		addr\arg3
		rep
		stosw    # store ECX items at ES:EDI with the value in EAX
	.endif
	.if \arg1 = d
		addr\arg3
		rep
		stosl    # store ECX items at ES:EDI with the value in EAX
	.endif
	cmp $0,%ecx
	jnz error           		# ECX must be 0
	cmp $off_cmp,%edi
	jnz error
	mov $off_value,%edi  # reset EDI
	# now switch ES:EDI with DS:ESI
	mov %es,%dx
	mov %ds,%cx
	xchg %cx,%dx
	mov %dx,%es
	mov %cx,%ds
	xchg %esi,%edi
	# store again ES:EDI with pattern in EAX
	mov $items,%ecx      	# reset ECX
	.if \arg1 = b
		addr\arg3
		rep
		stosb
	.endif
	.if \arg1 = w
		addr\arg3
		rep
		stosw
	.endif
	.if \arg1 = d
		addr\arg3
		rep
		stosl
	.endif
	mov $off_value,%edi  	# reset EDI

	# COMPARE two buffers
	mov $items,%ecx      # reset ECX
	.if \arg1 = b
		addr\arg3
		repe
		cmpsb # find nonmatching items in ES:EDI and DS:ESI
	.endif
	.if \arg1 = w
		addr\arg3
		repe
		cmpsw # find nonmatching items in ES:EDI and DS:ESI
	.endif
	.if \arg1 = d
		addr\arg3
		repe
		cmpsl # find nonmatching items in ES:EDI and DS:ESI
	.endif
	cmp $0,%ecx
	jnz error           		# ECX must be 0
	cmp $off_cmp,%esi
	jne error
	cmp $off_cmp,%edi
	jne error
	mov $off_value,%edi  # reset EDI
	mov $off_value,%esi  # reset ESI

	# SCAN buffer for pattern
	mov $items,%ecx      # reset ECX
	.if \arg1 = b
		addr\arg3
		repe
		scasb         # SCAN first dword not equal to EAX
	.endif
	.if \arg1 = w
		addr\arg3
		repe
		scasw         # SCAN first dword not equal to EAX
	.endif
	.if \arg1 = d
		addr\arg3
		repe
		scasl         # SCAN first dword not equal to EAX
	.endif
	cmp $0,%ecx
	jne error           		# ECX must be 0
	cmp $off_cmp,%edi
	jne error
	mov $off_value,%edi  		# rewind EDI

	# MOVE and COMPARE data between buffers
	# first zero-fill ES:EDI so that we can compare the moved data later
	mov $0,%eax
	mov $items,%ecx      # reset ECX
	.if \arg1 = b
		addr\arg3
		rep
		stosb          # zero fill ES:EDI
	.endif
	.if \arg1 = w
		addr\arg3
		rep
		stosw          # zero fill ES:EDI
	.endif
	.if \arg1 = d
		addr\arg3
		rep
		stosl          # zero fill ES:EDI
	.endif
	mov $off_value,%edi  # reset EDI
	mov $items,%ecx      # reset ECX
	.if \arg1 = b
		addr\arg3
		rep
		movsb          # MOVE data from DS:ESI to ES:EDI
	.endif
	.if \arg1 = w
		addr\arg3
		rep
		movsw          # MOVE data from DS:ESI to ES:EDI
	.endif
	.if \arg1 = d
		addr\arg3
		rep
		movsl          # MOVE data from DS:ESI to ES:EDI
	.endif
	cmp $0,%ecx
	jne error           	# ECX must be 0
	cmp $off_cmp,%esi
	jne error
	cmp $off_cmp,%edi
	jne error
	mov $items,%ecx      	# reset ECX
	mov $off_value,%edi  	# reset EDI
	mov $off_value,%esi  	# reset ESI
	.if \arg1 = b
		addr\arg3
		repe
		cmpsb  # COMPARE moved data in ES:EDI with DS:ESI
	.endif
	.if \arg1 = w
		addr\arg3
		repe
		cmpsw  # COMPARE moved data in ES:EDI with DS:ESI
	.endif
	.if \arg1 = d
		addr\arg3
		repe
		cmpsl  # COMPARE moved data in ES:EDI with DS:ESI
	.endif
	cmp $0,%ecx
	jne error           # ECX must be 0
	cmp $off_cmp,%esi
	jne error
	cmp $off_cmp,%edi
	jne error
.endm
