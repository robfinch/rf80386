ENTRY (_start)

MEMORY {
	TEST_PGTBL : ORIGIN = 0xFFF80000, LENGTH = 128k
}

MEMORY {
	TEST_RODATA : ORIGIN = 0xFFFA0000, LENGTH = 64k
}

MEMORY {
	TEST_STACK : ORIGIN = 0xFFFCF000, LENGTH = 0x1000
}

MEMORY {
	TEST_BSS : ORIGIN = 0xFFFD0000, LENGTH = 64k
}

MEMORY {
	TEST_DATA : ORIGIN = 0xFFFE0000, LENGTH = 64k
}

MEMORY {
	TEST_CODE : ORIGIN = 0xFFFF0000, LENGTH = 63K
}

MEMORY {
	TEST_RESET: ORIGIN = 0xFFFFFC00, LENGTH=1k
}

PHDRS {
	test_pgtbl PT_LOAD AT (0xFFF80000);
	test_idt PT_LOAD AT (0xFFF90000);
	test_rodata PT_LOAD AT (0xFFFA0000);
	test_stack PT_LOAD AT (0xFFFCF000);
	test_bss PT_LOAD AT (0xFFFD0000);
	test_data PT_LOAD AT (0xFFFE0000);
	test_code PT_LOAD AT (0xFFFF0000);
	test_reset PT_LOAD AT (0xFFFFFC00);
}

SECTIONS {
	.text: {
		. = 0xffff0000;
		*(.text);
		_etext = .;
	} >TEST_CODE
	.pgtbl: {
		. = 0xfff80000;
		*(.pgtbl);
	} >TEST_PGTBL
	.bss: {
		. = 0xfffd0000;
		_start_bss = .;
		_SDA_BASE_ = .;
		*(.bss);
		_end_bss = .;
	} >TEST_BSS
	.data: {
		. = 0xfffe0000;
		_start_data = .;
		*(.data);
		_end_data = .;
	} >TEST_DATA
	.rodata: {
		. = 0xfffa0000;
		_start_rodata = .;
		*(.rodata);
		_end_rodata = .;
	} >TEST_RODATA
	.reset_vect: {
		_start_reset_vect = .;
		. = 0xfffffc00;
		*(.reset_vect);
		. = ALIGN(6);
		_end_reset_vect = .;
	} >TEST_RESET
}
