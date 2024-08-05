#
# Advances the base address of data segments used by tests, D1_SEG_REAL and
# D2_SEG_REAL.
#
# Loads DS with D1_SEG_REAL and ES with D2_SEG_REAL.
#
.macro advTestSegReal
	advTestBase
	.set D1_SEG_REAL,TEST_BASE1 >> 4
	.set D2_SEG_REAL,TEST_BASE2 >> 4
	mov $D1_SEG_REAL,%dx
	mov %dx,%ds
	mov $D2_SEG_REAL,%dx
	mov %dx,%es
.endm

#
# Initializes the real mode IDT with C_SEG_REAL:error
# This code is called in real mode.
#
.macro initRealModeIDT
	mov $IDT_SEG_REAL,%ax
	mov %ax,%ds
	xor %di,%di
	mov $17,%cx
aloop\@:
	movw $error,(%di)
	movw $C_SEG_REAL,2(%di)
	add $4,%di
	loop aloop\@
.endm


#
# Exception handling testing in real mode
#

# Initialises an exc handler
# %1: vector
# %2: handler IP
# Trashes AX,DS

.macro realModeExcInit arg1,arg2
	mov $IDT_SEG_REAL,%ax
	mov %ax,%ds
	movw $\arg2,\arg1*4
	movw $C_SEG_REAL,\arg1*4+2
.endm

# Checks exc result and restores the default handler
# %1: vector
# %2: expected pushed value of IP
# Trashes AX,DS

.macro realModeExcCheck arg1,arg2
	cmp $ESP_REAL-6,%sp
	jne error
	cmpw $C_SEG_REAL,%ss:ESP_REAL-4
	jne error
	cmpw $\arg2,%ss:ESP_REAL-6
	jne error
	mov $0,%ax
	mov %ax,%ds
	movw $error,\arg1*4
	movw $C_SEG_REAL,\arg1*4+2
.endm


# Tests a fault
# %1: vector
# %2: instruction to execute that causes a fault

.macro realModeFaultTest arg1,arg2,arg3
	realModeExcInit \arg1,continue\@
	mov $S_SEG_REAL,%ax
	mov %ax,%ss
	mov $ESP_REAL,%sp
test\@:
	\arg2,%\arg3
	jmp error
continue\@:
	realModeExcCheck \arg1,test\@
.endm
