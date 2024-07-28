#
#   Test of loop, loopz, loopnz
#   Use: EAX, ECX, Flags
#

.macro testLoop

	mov $0x20000,%ecx
	mov $0,%eax
loop16\@:
	inc %eax
	loopw loop16\@
	cmp $0x10000,%eax
	jne error
	cmp $0x20000,%ecx
	jne error

	mov $0x20000,%ecx
	mov $0,%eax
loop32\@:
	inc %eax
	loopl loop32\@
	cmp $0x20000,%eax
	jne error
	cmp $0,%ecx
	jne error

.endm

.macro testLoopZ

	mov $0xFFFF,%cx
	mov $0,%ax
loop16a\@:
	inc %ax
	cmp $0,%ah
	loopzw loop16a\@
	cmp $0x0100,%ax
	jne error
	cmp $0xFEFF,%cx
	jne error

	mov $0x00FF,%cx
	mov $0,%ax
loop16b\@:
	inc %ax
	cmp $0,%ah
	loopzw loop16b\@
	cmp $0x00FF,%ax
	jne error
	cmp $0,%cx
	jne error

	mov $0x20000,%ecx
	mov $0,%eax
loop32\@:
	inc %eax
	test $0x10000,%eax
	loopzl loop32\@
	cmp $0x10000,%eax
	jne error
	cmp $0x10000,%ecx
	jne error

.endm

.macro testLoopNZ

	mov $0xFFFF,%cx
	mov $0,%ax
loop16a\@:
	inc %ax
	test $0xFF,%al
	loopnzw loop16a\@
	cmp $0x0100,%ax
	jne error
	cmp $0xFEFF,%cx
	jne error

	mov $0x00FF,%cx
	mov $0,%ax
loop16b\@:
	inc %ax
	test $0xFF,%al
	loopnzw loop16b\@
	cmp $0x00FF,%ax
	jne error
	cmp $0,%cx
	jne error

	mov $0x10000,%ecx
	mov $0,%eax
loop32\@:
	inc %eax
	test $0x0FFFF,%eax
	loopnzl loop32\@
	cmp $0x10000,%eax
	jne error
	cmp $0,%ecx
	jne error

.endm