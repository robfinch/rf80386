.set PS_CF,0x0001
.set PS_PF,0x0004
.set PS_AF,0x0010
.set PS_ZF,0x0040
.set PS_SF,0x0080
.set PS_TF,0x0100
.set PS_IF,0x0200
.set PS_DF,0x0400
.set PS_OF,0x0800
.set PS_ARITH,(PS_CF | PS_PF | PS_AF | PS_ZF | PS_SF | PS_OF)
.set PS_LOGIC,(PS_CF | PS_PF | PS_ZF | PS_SF | PS_OF)
.set PS_MULTIPLY,(PS_CF | PS_OF) # only CF and OF are "defined" following MUL or IMUL
.set PS_DIVIDE,0 # none of the Processor Status flags are "defined" following DIV or IDIV
.set PS_SHIFTS_1,(PS_CF | PS_SF | PS_ZF | PS_PF | PS_OF)
.set PS_SHIFTS_R,(PS_CF | PS_SF | PS_ZF | PS_PF)

.set CR0_MSW_PE,0x0001
.set CR0_PG,0x80000000	# set if paging enabled

.set ACC_TYPE_GATE386_INT,0x0E00
.set ACC_TYPE_GATE386_CALL,0x0C00
.set ACC_TYPE_SEG,0x1000
.set ACC_PRESENT,0x8000
.set ACC_TYPE_CODE_R,0x1a00
.set ACC_TYPE_CONFORMING,0x0400
.set ACC_TYPE_DATA_R,0x1000
.set ACC_TYPE_DATA_W,0x1200
.set ACC_TYPE_LDT,0x0200
.set ACC_TYPE_TSS,0x0900

.set ACC_DPL_0,0x0000
.set ACC_DPL_1,0x2000
.set ACC_DPL_2,0x4000
.set ACC_DPL_3,0x6000

.set EXT_NONE,0x0000
.set EXT_16BIT,EXT_NONE
.set EXT_32BIT,0x0040 # size bit
.set EXT_PAGE,0x0080 # granularity bit

# i386 paging
#PTE_FRAME,0xffffe000
#PTE_DIRTY,0x00000040 		# page has been modified
#PTE_ACCESSED  equ 0x00000020 ; page has been accessed
#PTE_USER      equ 0x00000004 ; set for user level (CPL 3), clear for supervisor level (CPL 0-2)
#PTE_WRITE     equ 0x00000002 ; set for read/write, clear for read-only (affects CPL 3 only)
#PTE_PRESENT   equ 0x00000001 ; set for present page, clear for not-present page

# Bigfoot paging
.set PTE_FRAME,0xffffe000
.set PTE_DIRTY,0x00000080 		# page has been modified
.set PTE_ACCESSED,0x00000040 	# page has been accessed
.set PTE_USER,0x00000010 			# set for user level (CPL 3), clear for supervisor level (CPL 0-2)
.set PTE_WRITE,0x00000004 		# set for read/write, clear for read-only (affects CPL 3 only)
.set PTE_PRESENT,0x00000001 	# set for present page, clear for not-present page

#PTE_PRESENT_BIT   equ 0000001b
#PTE_WRITE_BIT     equ 0000010b
#PTE_USER_BIT      equ 0000100b
#PTE_ACCESSED_BIT  equ 0100000b
#PTE_DIRTY_BIT     equ 1000000b

.set EX_DE,0
.set EX_DB,1
.set EX_BP,3
.set EX_OF,4
.set EX_BR,5
.set EX_UD,6
.set EX_NM,7
.set EX_DF,8
.set EX_MP,9
.set EX_TS,10
.set EX_NP,11
.set EX_SS,12
.set EX_GP,13
.set EX_PF,14
.set EX_MF,15
