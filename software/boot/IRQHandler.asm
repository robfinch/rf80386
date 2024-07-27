	.text
	.code32
_IRQHandler:
	pushal
	inc $0xFEC000FC
	popal
	iret

.global _IRQHandler
