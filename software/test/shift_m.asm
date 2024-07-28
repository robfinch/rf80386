#
#   Executes a byte shift operation and checks the resulting flags.
#
#   %1 operation
#   %2 al: byte operand
#   %3 cl: shift count
#   %4 flags: value of flags before %1 execution
#   %5 flags: expected value of flags after %1 execution (cmp with PS_ARITH mask)
#
#   Uses: AX, CL, Flags
#

.macro testShiftBFlags arg1,arg2,arg3,arg4,arg5
	mov \arg4,%ax
	push %ax
	popf
	mov $0xff,%ah
	mov \arg2,%al
	mov \arg3,%cl
	\arg1 %cl,%al
	pushf
	pop %ax
	and $PS_ARITH,%ax
	cmp \arg5,%ax
	jne error
.endm

#
#   Executes a word shift operation and checks the resulting flags.
#
#   %1 operation
#   %2 ax: word operand
#   %3 cl: shift count
#   %4 flags: value of flags before %1 execution
#   %5 flags: expected value of flags after %1 execution (cmp with PS_ARITH mask)
#
#   Uses: AX, CL, Flags
#
.macro testShiftWFlags arg1,arg2,arg3,arg4,arg5
	mov \arg4,%ax
	push %ax
	popf
	mov \arg2,%ax
	mov \arg3,%cl
	\arg1 %cl,%ax
	pushf
	pop %ax
	and $PS_ARITH,%ax
	cmp \arg5,%ax
	jne error
.endm
