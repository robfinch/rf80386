#
#   Execs LEA op with 16-bit addressing and compares the result with given value
#   %1 address to calculate
#   %2 value to compare
#   Uses: flags.
#
.macro testLEA16 arg1,arg2
	push %ax
	lea \arg1,%ax
	cmp \arg2,%ax
	jne error
	pop %ax
.endm

#
#   Execs LEA op with 32-bit addressing and compares the result with given value
#   %1 address to calculate
#   %2 value to compare
#   Uses: flags.
#
.macro testLEA32 arg1,arg2
	push %eax
	lea \arg1,%eax
	cmp \arg2,%eax
	jne error
	pop %eax
.endm
