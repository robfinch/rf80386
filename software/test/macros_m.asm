#
#   Output a byte to the POST port, destroys al and dx
#
.macro POST arg1
	movb \arg1,%al
	movw $POST_PORT,%dx
	out %al,%dx
.endm

#
# Initializes an interrupt gate in system memory.
# This is the body of procedures used in 16 and 32-bit code segments.
#
#    7                             0 7                             0
#   ╔═══════════════════════════════╤═══════════════════════════════╗
# +7║                          OFFSET 31-16                         ║+6
#   ╟───┬───────┬───┬───────────────┬───────────────────────────────╢
# +5║ P │  DPL  │ 0 │ 1   1   1   0 │            UNUSED             ║+4
#   ╟───┴───┴───┴───┴───┴───┴───┴───┴───────────────────────────────╢
# +3║                           SELECTOR                            ║+2
#   ╟───────────────────────────────┴───────────────────────────────╢
# +1║                          OFFSET 15-0                          ║ 0
#   ╚═══════════════════════════════╧═══════════════════════════════╝
#    15                                                            0
#
# DS:EBX pointer to IDT
# EAX vector
# ESI selector
# EDI offset
# DX DPL (use ACC_DPL_* equs)
#
.macro initIntGate
	shl $3,%eax
	add	%eax,%ebx
	movw %di,(%ebx)
	movw %si,2(%ebx)
	orw $ACC_TYPE_GATE386_INT | ACC_PRESENT, %dx
	movw %dx,4(%ebx)
	shr $16,%edi
	movw %di,6(%ebx)
.endm

#
# Set a descriptor in system memory.
# This is the body of procedures used in 16 and 32-bit code segments.
#
#    7                             0 7                             0
#   ╔═══════════════════════════════╤═══╤═══╤═══╤═══╤═══════════════╗
# +7║            BASE 31-24         │ G │B/D│ 0 │AVL│  LIMIT 19-16  ║+6
#   ╟───┬───────┬───┬───────────┬───┼───┴───┴───┴───┴───┴───┴───┴───╢
# +5║ P │  DPL  │ S │    TYPE    (A)│          BASE 23-16           ║+4
#   ╟───┴───┴───┴───┴───┴───┴───┴───┴───────────────────────────────╢
# +3║                           BASE 15-0                           ║+2
#   ╟───────────────────────────────┴───────────────────────────────╢
# +1║                           LIMIT 15-0                          ║ 0
#   ╚═══════════════════════════════╧═══════════════════════════════╝
#    15                                                            0
#
# DS:EBX pointer to the descriptor table
# EAX segment selector
# ESI base
# EDI limit
# DL ext nibble (upper 4 bits)
# DH acc byte (P|DPL|S|TYPE|A)
#
.macro initDescriptor
	and $0xFFF8,%eax
	add %eax,%ebx
	movw %di,(%ebx)						# LIMIT 15-0
	movw %si,2(%ebx)					# BASE 15-0
	shr $16,%esi
	mov %si,%ax								# AX := BASE 31-16
	movb %al,4(%ebx)					# BASE 23-16
	movb %dh,5(%ebx)					# acc byte
	shr $16,%edi
	mov %di,%cx
	and $0x0f,%cl
	movb %cl,6(%ebx)					# LIMIT 19-16
	and $0xf0,%dl
	orb %dl,6(%ebx)						# ext nybble
	movb %ah,7(%ebx)					# BASE 31-24
.endm


.macro advTestBase
	.set TEST_BASE1,TEST_BASE1+0x1000
	.set TEST_BASE2,TEST_BASE2+0x1000
.endm
