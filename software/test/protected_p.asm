# Procedures for 32 bit code segment

initIntGateProt:
	initIntGate
	ret

initDescriptorProt:
	initDescriptor
	ret

#
# Defines a Call Gate in GDT
#
#    7                             0 7                             0
#   ╔═══════════════════════════════════════════════════════════════╗
# +7║                  DESTINATION OFFSET 31-16                     ║+6
#   ╟───┬───────┬───┬───────────────┬───────────┬───────────────────╢
# +5║ P │  DPL  │ 0 │ 1   1   0   0 │ x   x   x │  WORD COUNT 4-0   ║+4
#   ╟───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───────────┬───────╢
# +3║                 DESTINATION SELECTOR 15-2             │ x   x ║+2
#   ╟───────────────────────────────┴───────────────────────┴───┴───╢
# +1║                  DESTINATION OFFSET 15-0                      ║ 0
#   ╚═══════════════════════════════╧═══════════════════════════════╝
#    15                                                            0
#
# FS:EBX pointer to the GDT
# EAX GDT selector
# SI  destination selector
# EDI destination offset
# DL word count
# DH DPL (as bit field, use ACC_DPL_* equs on dx)
#;
initCallGate:
	and $0xFFF8,%eax
	add %eax,%ebx
	movw %di,%fs:(,%ebx,1)   	# DESTINATION OFFSET 15-0
	movw %si,%fs:2(,%ebx,1)		# DESTINATION SELECTOR 15-2
	or $ACC_TYPE_GATE386_CALL | ACC_PRESENT,%dx
	movw %dx,%fs:4(,%ebx,1) 	# ACC byte | WORD COUNT 4-0
	shr $16,%edi
	movw %di,%fs:6(,%ebx,1) 	# DESTINATION OFFSET 31-16
	ret
