// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================

package rf80386_pkg;

`ifdef BIG_SEGS
`define SEG_SHIFT		8'b0
`define AMSB			23
`define CS_RESET		16'hFF00
`else
`define SEG_SHIFT		4'b0
`define AMSB			19
`define CS_RESET		16'hF000
`endif

`define REALMODE_PG16		8'hFF			// for lidt, lgdt
`define REALMODE_PG1M		12'hFFF
parameter IRQ_FIFO_DEPTH = 32;
parameter LSBIT = 4;

// Opcodes
//
`define MOV_RR	8'b1000100?
`define MOV_MR	8'b1000101?
`define MOV_IM	8'b1100011?
`define MOV_MA	8'b1010000?
`define MOV_AM	8'b0101001?

`define ADD			8'b000000??
`define ADD_ALI8	8'h04
`define ADD_AXI16	8'h05
`define PUSH_ES		8'h06
`define POP_ES		8'h07
`define OR          8'b000010??
`define AAD			8'h0A
`define AAM			8'h0A
`define OR_ALI8		8'h0C
`define OR_AXI16	8'h0D
`define PUSH_CS     8'h0E
`define EXTOP		8'h0F	// extended opcode

`define ADC			8'b000100??
`define ADC_ALI8	8'h14
`define ADC_AXI16	8'h15
`define PUSH_SS     8'h16
`define POP_SS		8'h17
`define SBB         8'b000110??
`define SBB_ALI8	8'h1C
`define SBB_AXI16	8'h1D
`define PUSH_DS     8'h1E
`define POP_DS		8'h1F

`define AND			8'b001000??
`define AND_ALI8	8'h24
`define AND_AXI16	8'h25
`define ES			8'h26
`define DAA			8'h27
`define SUB     	8'b001010??
`define SUB_ALI8	8'h2C
`define SUB_AXI16	8'h2D
`define CS			8'h2E
`define DAS			8'h2F

`define XOR     	8'b001100??
`define XOR_ALI8	8'h34
`define XOR_AXI16	8'h35
`define SS			8'h36
`define AAA			8'h37
`define CMP			8'b001110??
`define CMP_ALI8	8'h3C
`define CMP_AXI16	8'h3D
`define DS			8'h3E
`define AAS			8'h3F

`define INC_REG 8'b01000???
`define INC_AX	8'h40
`define INC_CX	8'h41
`define INC_DX	8'h42
`define INC_BX	8'h43
`define INC_SP	8'h44
`define INC_BP	8'h45
`define INC_SI	8'h46
`define INC_DI	8'h47
`define DEC_REG	8'b01001???
`define DEC_AX	8'h48
`define DEC_CX	8'h49
`define DEC_DX	8'h4A
`define DEC_BX	8'h4B
`define DEC_SP	8'h4C
`define DEC_BP	8'h4D
`define DEC_SI	8'h4E
`define DEC_DI	8'h4F

`define PUSH_REG	8'b01010???
`define PUSH_AX 8'h50
`define PUSH_CX	8'h51
`define PUSH_DX	8'h52
`define PUSH_BX	8'h53
`define PUSH_SP 8'h54
`define PUSH_BP 8'h55
`define PUSH_SI 8'h56
`define PUSH_DI 8'h57
`define POP_REG		8'b01011???
`define POP_AX	8'h58
`define POP_CX	8'h59
`define POP_DX	8'h5A
`define POP_BX	8'h5B
`define POP_SP  8'h5C
`define POP_BP  8'h5D
`define POP_SI  8'h5E
`define POP_DI  8'h5F

`define PUSHA	8'h60
`define POPA	8'h61
`define BOUND	8'h62
`define ARPL	8'h63
`define FS		8'h64
`define GS		8'h65
`define OPSZ	8'h66
`define ADSZ	8'h67
`define PUSHI	8'h68
`define IMULI	8'h69
`define PUSHI8	8'h6A
`define IMULI8	8'h6B
`define INSB	8'h6C
`define INSW	8'h6D
`define OUTSB	8'h6E
`define OUTSW	8'h6F

`define Jcc		8'b0111????
`define JO		8'h70
`define JNO		8'h71
`define JB		8'h72
`define JAE		8'h73
`define JE		8'h74
`define JNE		8'h75
`define JBE		8'h76
`define JA		8'h77
`define JS		8'h78
`define JNS		8'h79
`define JP		8'h7A
`define JNP		8'h7B
`define JL		8'h7C
`define JNL		8'h7D
`define JLE		8'h7E
`define JNLE	8'h7F

`define JNA		8'h76
`define JNAE	8'h72
`define JNB     8'h73
`define JNBE    8'h77
`define JC      8'h72
`define JNC     8'h73
`define JG		8'h7F
`define JNG		8'h7E
`define JGE		8'h7D
`define JNGE	8'h7C
`define JPE     8'h7A
`define JPO     8'h7B

`define ALU_I2R8	8'h80
`define ALU_I2R16	8'h81
`define ALU_I82R8	8'h82
`define ALU_I82R16 8'h83
`define TEST        8'b1000010?
`define XCHG_MEM	8'b1000011?
`define MOV_RR8		8'h88
`define MOV_RR16	8'h89
`define MOV_MR8		8'h8A
`define MOV_MR16	8'h8B
`define MOV_S2R		8'h8C
`define LEA			8'h8D
`define MOV_R2S		8'h8E
`define POP_MEM		8'h8F

`define XCHG_AXR	8'b10010???
`define NOP			8'h90
`define CBW			8'h98
`define CWD			8'h99
`define CALLF		8'h9A
`define WAI         8'h9B
`define PUSHF		8'h9C
`define POPF		8'h9D
`define SAHF		8'h9E
`define LAHF		8'h9F

`define MOV_M2AL	8'hA0
`define MOV_M2AX	8'hA1
`define MOV_AL2M	8'hA2
`define MOV_AX2M	8'hA3

`define MOVSB		8'hA4
`define MOVSW		8'hA5
`define CMPSB		8'hA6
`define CMPSW		8'hA7
`define TEST_ALI8	8'hA8
`define TEST_AXI16	8'hA9
`define STOSB		8'hAA
`define STOSW		8'hAB
`define LODSB		8'hAC
`define LODSW		8'hAD
`define SCASB		8'hAE
`define SCASW		8'hAF

`define MOV_I2BYTREG	8'h1011_0???
`define MOV_I2AL	8'hB0
`define MOV_I2CL	8'hB1
`define MOV_I2DL	8'hB2
`define MOV_I2BL	8'hB3
`define MOV_I2AH	8'hB4
`define MOV_I2CH	8'hB5
`define MOV_I2DH	8'hB6
`define MOV_I2BH	8'hB7
`define MOV_I2AX	8'hB8
`define MOV_I2CX	8'hB9
`define MOV_I2DX	8'hBA
`define MOV_I2BX	8'hBB
`define MOV_I2SP	8'hBC
`define MOV_I2BP	8'hBD
`define MOV_I2SI	8'hBE
`define MOV_I2DI	8'hBF

`define SHI8		8'hC0
`define SHI16		8'hC1
`define RETPOP		8'hC2
`define RET			8'hC3
`define LES			8'hC4
`define LDS			8'hC5
`define MOV_I8M		8'hC6
`define MOV_I16M	8'hC7
`define ENTER		8'hC8
`define LEAVE		8'hC9
`define RETFPOP		8'hCA
`define RETF		8'hCB
`define INT3		8'hCC
`define INT     	8'hCD
`define INTO		8'hCE
`define IRET		8'hCF

`define RCL_81	8'hD0
`define RCL_161	8'hD1
`define MORE1	8'hD4
`define MORE2	8'hD5
`define XLAT    8'hD7

`define LOOPNZ	8'hE0
`define LOOPZ	8'hE1
`define LOOP	8'hE2
`define JCXZ	8'hE3
`define INB		8'hE4
`define INW		8'hE5
`define OUTB	8'hE6
`define OUTW	8'hE7
`define CALL	8'hE8
`define JMP 	8'hE9
`define JMPF	8'hEA
`define JMPS	8'hEB
`define INB_DX	8'hEC
`define INW_DX	8'hED
`define OUTB_DX	8'hEE
`define OUTW_DX	8'hEF

`define LOCK	8'hF0
`define REPNZ	8'hF2
`define REPZ	8'hF3
`define HLT		8'hF4
`define CMC		8'hF5
//`define IMUL	8'b1111011x
`define CLC		8'hF8
`define STC		8'hF9
`define CLI		8'hFA
`define STI		8'hFB
`define CLD		8'hFC
`define STD		8'hFD
`define GRPFF	8'b1111111?

// extended opcodes
// "OF"
`define LLDT	8'h00
`define LxDT	8'h01
`define LAR		8'h02
`define LSL		8'h03
`define CLTS	8'h06

`define MOV_CR2R	8'h20
`define MOV_R2CR	8'h22

`define LSS		8'hB2
`define LFS		8'hB4
`define LGS		8'hB5

`define JccL	8'h8?
`define Scc		8'h9?
`define PUSH_FS	8'hA0
`define BT		8'hA3
`define PUSH_GS	8'hA8
`define BTS		8'hAB
`define BTR		8'hB3
`define BTCI	8'hBA
`define BTC		8'hBB
`define BSF		8'hBC
`define BSR		8'hBD
`define BSWAP	8'b11001???

`define INITIATE_CODE_READ		cyc_type <= `CT_CODE; cyc_o <= 1'b1; stb_o <= 1'b1; we_o <= 1'b0; adr_o <= csip;
`define TERMINATE_CYCLE			cyc_type <= `CT_PASSIVE; cyc_o <= 1'b0; stb_o <= 1'b0; we_o <= 1'b0;
`define TERMINATE_CODE_READ		cyc_type <= `CT_PASSIVE; cyc_o <= 1'b0; stb_o <= 1'b0; we_o <= 1'b0; ip <= ip_inc;
`define PAUSE_CODE_READ			cyc_type <= `CT_PASSIVE; stb_o <= 1'b0; ip <= ip_inc;
`define CONTINUE_CODE_READ		cyc_type <= `CT_CODE; stb_o <= 1'b1; adr_o <= csip;
`define INITIATE_STACK_WRITE	cyc_type <= `CT_WRMEM; cyc_o <= 1'b1; stb_o <= 1'b1; we_o <= 1'b1; adr_o <= sssp;
`define PAUSE_STACK_WRITE		cyc_type <= `CT_PASSIVE; sp <= sp_dec; stb_o <= 1'b0; we_o <= 1'b0;

`define INITIATE_STACK_POP		cyc_type <= `CT_RDMEM; lock_o <= 1'b1; cyc_o <= 1'b1; stb_o <= 1'b1; adr_o <= sssp;
`define COMPLETE_STACK_POP		cyc_type <= `CT_PASSIVE; lock_o <= bus_locked; cyc_o <= 1'b0; stb_o <= 1'b0; sp <= sp_inc;
`define PAUSE_STACK_POP			cyc_type <= `CT_PASSIVE; stb_o <= 1'b0; sp <= sp_inc;
`define CONTINUE_STACK_POP		cyc_type <= `CT_RDMEM; stb_o <= 1'b1; adr_o <= sssp;


/*
Some modrm codes specify register-immediate or memory-immediate operations.
The operation to be performed is coded in the rrr field as only one register
spec (rm) is required.

80/81/83
	rrr   Operation
	---------------
	000 = ADD
	001 = OR
	010 = ADC
	011 = SBB
	100 = AND
	101 = SUB
	110 = XOR
	111 = CMP
FE/FF	
	000 = INC
	001 = DEC
	010 = CALL
	011 =
	100 =
	101 =
	110 =
	111 = 
F6/F7:
	000 = TEST
	001 = 
	010 = NOT
	011 = NEG
	100 = MUL
	101 = IMUL
	110 = DIV
	111 = IDIV
*/
`define ADDRESS_INACTIVE	20'hFFFFF
`define DATA_INACTIVE		8'hFF

// States
typedef enum logic [8:0] {
	RESET = 9'd1,
	IFETCH,
  IFETCH_ACK,
  XI_FETCH,
  XI_FETCH_ACK,
  REGFETCHA,
  DECODE,
  DECODER2,
  DECODER3,

  FETCH_VECTOR,
  FETCH_IMM8,
  FETCH_IMM8_ACK,
  FETCH_IMM16,
  FETCH_IMM16_ACK,
  FETCH_IMM16a,
  FETCH_IMM16a_ACK,

  MOV_I2BYTREG,

  FETCH_DISP8,
  FETCH_DISP16,
  FETCH_DISP16b,

  FETCH_OFFSET,

  FETCH_STK_ADJ1,
  FETCH_STK_ADJ1_ACK,
  FETCH_STK_ADJ2,
  FETCH_STK_ADJ2_ACK,
 
  FETCH_DATA,
  FETCH_DATA1,

  BRANCH1,
  BRANCH2,

  RET,
  RETF,
  RETF1,

  CALLF,
  CALLF1,
  CALLF2,
  CALLF3,
  CALLF4,
  CALLF5,
  CALLF6,
  CALLF7,
  CALLF8,
  CALLF9,
  CALLF10,
  CALLF11,
  CALLF12,
  CALLF13,
  CALLF14,
  CALLF15,
  CALLF16,
  CALLF17,
  CALLF18,
  CALLF20,
  CALLF21,
  CALLF22,
  CALLF25,

  CALLF_RMD1,
  CALLF_RMD2,
  CALLF_RMD3,
  CALLF_RMD4,
  CALLF_RMD5,

  CALL,
  CALL1,
  CALL2,

  PUSH,

  POP,
  POP1,
  POP2,
  POP3,

  CALL_IN,
  CALL_IN1,
  CALL_IN2,
  CALL_IN3,
  CALL_IN4,
  CALL_IN5,
  CALL_IN6,
  CALL_IN7,
  CALL_IN8,

  STOS,
  STOS1,

  MOVS,
  MOVS1,
  MOVS2,
  MOVS3,
  MOVS4,

  WRITE_REG,

  EACALC,
  EACALC1,
  EACALC_DISP8,
  EACALC_DISP8_ACK,
  EACALC_DISP16,
  EACALC_DISP16_ACK,
  EACALC_DISP16a,
  EACALC_DISP16a_ACK,
  EACALC_SIB,
  EACALC_SIB1,

  EXECUTE,

  INB,
  INB1,
  INB2,
  INB3,
 
  INW,
  INW1,
  INW2,
  INW3,
	INW4,
	INW5,

  OUTB,
  OUTB_NACK,
  OUTB1,
  OUTB1_NACK,
  OUTW,
  OUTW_NACK,
  OUTW1,
  OUTW1_NACK,
  OUTW2,
  OUTW2_NACK,
  FETCH_PORTNUMBER,

  INVALID_OPCODE,
  IRQ1,

  JUMP_VECTOR1,
  JUMP_VECTOR2,
  JUMP_VECTOR3,
  JUMP_VECTOR4,

  STORE_DATA,
  STORE_DATA1,
  STORE_DATA2,
  STORE_DATA3,

  INTO,
  FIRST,

  INTA0,
  INTA1,

  RETPOP,
  RETPOP_NACK,
  RETPOP1,
  RETPOP1_NACK,

  RETFPOP,
  RETFPOP1,
  RETFPOP2,
  RETFPOP3,
  RETFPOP4,
  RETFPOP5,
  RETFPOP6,
  RETFPOP7,
  RETFPOP8,
  RETFPOP9,
  RETFPOP10,
  RETFPOP11,
  RETFPOP12,
  RETFPOP13,
  RETFPOP_SAME_LEVEL,
  RETFPOP_OUTER_LEVEL,
  RETFPOP_RMD1,
  RETFPOP_RMD2,
  RETFPOP_RMD3,

	XLAT,
  XLAT_ACK,

  FETCH_DESC,
  FETCH_DESC1,
  FETCH_DESC2,
  FETCH_DESC3,
  FETCH_DESC4,
  FETCH_DESC5,

  INSB,
  INSB1,
  INSB2,
  INSB3,

  OUTSB,
  OUTSB1,
  OUTSB2,
  OUTSB3,

  SCASB,
  SCASB1,
  SCASB2,
 
  SCASW,
  SCASW1,
  SCASW2,
  SCASW3,
  SCASW4,

  CMPSW,
  CMPSW1,
  CMPSW2,
  CMPSW3,
  CMPSW4,
  CMPSW5,
  CMPSW6,
  CMPSW7,
  CMPSW8,
  CMPSW9,
  CMPSW10,
  CMPSW11,
  CMPSW12,
  CMPSW13,
  CMPSW14,
  CMPSW15,
  CMPSW16,

  LODS,
  LODS_NACK,
  LODS1,
  LODS1_NACK,

  INSW,
  INSW1,
  INSW2,
  INSW3,

  OUTSW,
  OUTSW1,
  OUTSW2,
  OUTSW3,

  CALL_FIN,
  CALL_FIN1,
  CALL_FIN2,
  CALL_FIN3,
  CALL_FIN4,

  DIVIDE1,
  DIVIDE1a,
  DIVIDE2,
  DIVIDE2a,
  DIVIDE3,

  INT,
  INT1,
  INT2,
  
  INT3,
  INT4,
  INT5,
  INT6,
  INT7,
  INT8,
  INT9,
  INT10,
  INT11,
  INT12,
  INT13,
  
  INT_TASK1,
  INT_TASK2,
  INT_TASK3,
  
  RMD_INT3,
  RMD_INT4,
  RMD_INT5,
  RMD_INT6,
  RMD_INT7,
  RMD_INT8,

	V86_INT3,
	V86_INT4,
	V86_INT5,
	V86_INT6,
	V86_INT7,
	V86_INT8,
	V86_INT9,
	V86_INT10,
	V86_INT11,
	V86_INT12,
	V86_INT13,
	V86_INT14,
	V86_INT15,
	V86_INT16,
	V86_INT17,
	V86_INT18,

	INT_INNER_PRIV,
	INT_SAME_PRIV,
	
  IRET1,
  IRET2,
  IRET3,
  IRET4,
  IRET5,
  IRET6,

  XCHG_MEM,

  CMPSB,
  CMPSB1,
  CMPSB2,
  CMPSB3,
  CMPSB4,
  
  PUSHA,
  PUSHA1,
  PUSHA2,
  PUSHA3,
  PUSHA4,
  PUSHA5,
  PUSHA6,
  PUSHA7,

	POPA,
	POPA1,
	POPA2,
	POPA3,
	POPA4,
	POPA5,
	POPA6,
	POPA7,
	POPA8,

	LOAD,
	LOAD_ACK,
	LOAD1,
	LOAD2,
	LOAD2_ACK,
	STORE,
	STORE_ACK,
	STORE_WAIT,
	STORE1,
	STORE2,
	STORE2_ACK,
	STORE_WAIT2,
	IRQ_LOAD,
	IRQ_LOAD_ACK,
	LOAD_IO,
	LOAD_IO_ACK,
	LOAD_IO1,
	LOAD_IO2,
	LOAD_IO2_ACK,
	STORE_IO,
	STORE_IO_ACK,
	STORE_IO_WAIT,
	STORE_IO1,
	STORE_IO2,
	STORE_IO2_ACK,
	STORE_IO2_WAIT,

	LOAD_CS_DESC,
	LOAD_CS_DESC1,
	LOAD_CS_DESC2,
	LOAD_DS_DESC,
	LOAD_DS_DESC1,
	LOAD_ES_DESC,
	LOAD_ES_DESC1,
	LOAD_SS_DESC,
	LOAD_SS_DESC1,
	LOAD_DESC,
	LOAD_DESC1,
	
	LOAD_GATE,
	LOAD_GATE1,
	
	LxDT,
	LxDT1,
	
	LLDT,
	LLDT1,
	LLDT2,
	LLDT3,
	
	ENTER,
	ENTER0,
	ENTER1,
	ENTERN,
	
	LEAVE,
	LEAVE1,
	
	LAR,
	LAR1,
	
	TASK_SWITCH,
	TASK_SWITCH1,
	TASK_SWITCH2,
	TASK_SWITCH3,
	TASK_SWITCH4,
	TASK_SWITCH5,
	TASK_SWITCH6,
	TASK_SWITCH7,
	TASK_SWITCH8,
	TASK_SWITCH9,
	TASK_SWITCH10,
	TASK_SWITCH11,
	TASK_SWITCH12,
	TASK_SWITCH13,
	TASK_SWITCH14,
	TASK_SWITCH15,
	TASK_SWITCH16,
	TASK_SWITCH17,
	TASK_SWITCH18,
	TASK_SWITCH19,
	TASK_SWITCH20,
	TASK_SWITCH30,
	TASK_SWITCH31,
	TASK_SWITCH32,
	TASK_SWITCH33,
	TASK_SWITCH34,
	TASK_SWITCH35,
	TASK_SWITCH36,
	TASK_SWITCH37,
	TASK_SWITCH38,
	TASK_SWITCH39,
	TASK_SWITCH40,
	TASK_SWITCH41,
	TASK_SWITCH42,
	TASK_SWITCH43,
	TASK_SWITCH44,
	TASK_SWITCH45,
	TASK_SWITCH46,
	TASK_SWITCH47,
	TASK_SWITCH48,
	
	LAST_STATE
} e_80386state;

typedef struct packed
{
	logic [12:0] ndx;
	logic ti;
	logic [1:0] rpl;
} selector_t;

// A generic descriptor

typedef struct packed
{
	logic [7:0] base_hi;
	logic g;
	logic db;
	logic L;
	logic a;
	logic [3:0] limit_hi;
	logic p;
	logic [1:0] dpl;
	logic s;
	logic [3:0] typ;
	logic [23:0] base_lo;
	logic [15:0] limit_lo;
} desc386_t;

typedef struct packed
{
	logic [15:0] offset_hi;
	logic p;
	logic [1:0] dpl;
	logic s;
	logic [3:0] typ;
	logic [2:0] zero;
	logic [4:0] resv;
	logic [15:0] selector;
	logic [15:0] offset_lo;
} int_gate386_t;

typedef struct packed
{
	logic [15:0] resv3;
	logic p;
	logic [1:0] dpl;
	logic [4:0] five;
	logic [7:0] resv2;
	logic [15:0] selector;
	logic [15:0] resv1;
} task_gate386_t;

typedef struct packed
{
	logic [15:0] offset_hi;
	logic p;
	logic [1:0] dpl;
	logic s;
	logic [3:0] typ;
	logic [2:0] zero;
	logic [4:0] count;
	logic [15:0] selector;
	logic [15:0] offset_lo;
} call_gate386_t;

typedef struct packed
{
	logic [15:0] io_map_base;
	logic [14:0] resv12;
	logic t;
	logic [15:0] resv11;
	logic [15:0] ldt;
	logic [15:0] resv10;
	logic [15:0] gs;
	logic [15:0] resv9;
	logic [15:0] fs;
	logic [15:0] resv8;
	logic [15:0] ds;
	logic [15:0] resv7;
	logic [15:0] ss;
	logic [15:0] resv6;
	logic [15:0] cs;
	logic [15:0] resv5;
	logic [15:0] es;
	logic [31:0] edi;
	logic [31:0] esi;
	logic [31:0] ebp;
	logic [31:0] esp;
	logic [31:0] ebx;
	logic [31:0] edx;
	logic [31:0] ecx;
	logic [31:0] eax;
	logic [31:0] eflags;
	logic [31:0] eip;
	logic [31:0] cr3;
	logic [15:0] resv4;
	logic [15:0] ss2;
	logic [31:0] esp2;
	logic [15:0] resv3;
	logic [15:0] ss1;
	logic [31:0] esp1;
	logic [15:0] resv2;
	logic [15:0] ss0;
	logic [31:0] esp0;
	logic [15:0] resv1;
	logic [15:0] link;
} task_state_segment386_t;

`define TSS_LINK	8'd0
`define TSS_ESP0	8'd4
`define TSS_SS0		8'd8
`define TSS_ESP1	8'd12
`define TSS_SS1		8'd16
`define TSS_ESP2	8'd20
`define TSS_SS2		8'd24
`define TSS_CR3		8'd28
`define TSS_EIP		8'd32
`define TSS_EFLAGS	8'd36
`define TSS_EAX		8'd40
`define TSS_ECX		8'd44
`define TSS_EDX		8'd48
`define TSS_EBX		8'd52
`define TSS_ESP		8'd56
`define TSS_EBP		8'd60
`define TSS_ESI		8'd64
`define TSS_EDI		8'd68
`define TSS_ES		8'd72
`define TSS_CS		8'd76
`define TSS_SS		8'd80
`define TSS_DS		8'd84
`define TSS_FS		8'd88
`define TSS_GS		8'd92
`define TSS_LDT		8'd96
`define TSS_T			8'd100
`define TSS_IO_MAP_BASE		8'd102

// g: granularity 1=4096 byte pages, 0=byte, limit is granular
// DB: default operand size, 1=32 bit, 0=16 bit for code. data: max offset 1=0xffffffff, 0=0x0000ffff
// L (64-bit mode)
// a = available for software use
// p = present
// dpl = descriptor privilege level
// s: 1=system segment, 0=code or data
// 

// Global variables
reg OperandSize32;
reg [7:0] AddrSize;
reg [7:0] StkAddrSize;
reg [7:0] prefix1;
reg [7:0] prefix2;
reg [7:0] prefix3;
reg [7:0] prefix4;

reg [7:0] ir;				// instruction register
reg [7:0] ir2;				// extended instruction register
reg [31:0] eip;				// instruction pointer
reg [31:0] neip;			// next instruction pointer (far flushing)
reg [31:0] old_eip;
reg [31:0] ir_ip;			// instruction pointer of ir
reg [31:0] eax;
reg [31:0] ebx;
reg [31:0] ecx;
reg [31:0] edx;
reg [31:0] esi;				// source index
reg [31:0] edi;				// destination index
reg [31:0] ebp;				// base pointer
reg [31:0] esp;				// stack pointer
reg [31:0] old_esp;		// stack pointer
reg [31:0] new_esp;		// CALL far
wire cxz = ecx==32'h0000;	// CX is zero

reg [15:0] cs;				// code segment
reg [15:0] ds;				// data segment
reg [15:0] es;				// extra segment
reg [15:0] fs;				// extra segment
reg [15:0] gs;				// extra segment
reg [15:0] ss;				// stack segment
reg [15:0] tr;				// task register
reg [15:0] ldt;
reg [15:0] old_cs;		// code segment
reg [15:0] old_ds;		// data segment
reg [15:0] old_es;		// extra segment
reg [15:0] old_fs;		// extra segment
reg [15:0] old_gs;		// extra segment
reg [15:0] old_ss;		// stack segment
reg [15:0] new_ss;		// for CALL far

reg d_jmp;							// jump instruction decoded
e_80386state state;			// machine state
e_80386state [5:0] stk_state;	// stacked machine state
reg nest_task;
reg [1:0] rpl;
reg [31:0] ad;
reg [19:0] sel;
reg [127:0] dat;
reg [31:0] ldt_limit, gdt_limit;
reg [31:0] tbase;
reg [15:0] new_tr;
desc386_t old_tss_desc;
desc386_t new_tss_desc;

reg ie;								// interrupt enable flag
reg next_ie;
wire irq_fifo_empty;
reg irq_fifo_read;
wire irq_fifo_write;
wire irq_fifo_underflow;
wire irq_fifo_wr_rst_busy, irq_fifo_rd_rst_busy;
wire [27:0] irq_fifo_data_in;
wire [27:0] irq_fifo_data_out;
reg intp;						// INT pending
reg [7:0] int_num, int_nump;	// pending INT number
reg [15:0] int_device, int_devicep;
reg int_priority, int_priorityp;
reg internal_int;

function fnIsInsnPrefix;
input [7:0] byt;
begin
	fnIsInsnPrefix =
		byt==`REPZ ||
		byt==`REPNZ ||
		byt==`LOCK
		;
end
endfunction

function fnIsOpszPrefix;
input [7:0] byt;
begin
	fnIsOpszPrefix = byt==`OPSZ;
end
endfunction

function fnIsAddrszPrefix;
input [7:0] byt;
begin
	fnIsAddrszPrefix = byt==`ADSZ;
end
endfunction

function fnIsSegPrefix;
input [7:0] byt;
begin
	fnIsSegPrefix =
		byt==`CS ||
		byt==`DS ||
		byt==`ES ||
		byt==`SS ||
		byt==`FS ||
		byt==`GS
		;
end
endfunction

function fnIsPrefix;
input [7:0] byt;
begin
	fnIsPrefix =
		fnIsInsnPrefix(byt) ||
		fnIsOpszPrefix(byt) ||
		fnIsAddrszPrefix(byt) ||
		fnIsSegPrefix(byt)
		;
end
endfunction


function fnIsReadableCodeOrData;
input desc386_t	desc;
begin
	fnIsReadableCodeOrData = desc.s && desc.typ[3] ? desc.typ[1] : 1'b1;
end
endfunction

function fnSelectorInLimit;
input selector_t selector;
reg [31:0] table_limit;
begin
	table_limit = selector.ti ? ldt_limit : gdt_limit;
	fnSelectorInLimit = {selector.ndx,3'b0} < table_limit;
end
endfunction

task tGoto;
input e_80386state nst;
begin
	// Whenever there is a transition to the IFETCH state or a string state,
	// check for an outstanding interrupt request which will be in the fifo.
	// However, do not read the fifo if interrupts are disabled.
	if (nst==rf80386_pkg::IFETCH ||
		nst==rf80386_pkg::MOVS ||
		nst==rf80386_pkg::STOS ||
		nst==rf80386_pkg::CMPSW ||
		nst==rf80386_pkg::SCASW
		)
		irq_fifo_read <= ie;
	if (nst==rf80386_pkg::IFETCH) begin
		prefix1 <= 8'h00;
		prefix2 <= 8'h00;
		prefix3 <= 8'h00;
		prefix4 <= 8'h00;
	end
	state <= nst;
end
endtask

task tGosub;
input e_80386state tgt;
input e_80386state rts;
begin
	stk_state[0] <= rts;
	stk_state[1] <= stk_state[0];
	stk_state[2] <= stk_state[1];
	stk_state[3] <= stk_state[2];
	stk_state[4] <= stk_state[3];
	stk_state[5] <= stk_state[4];
	tGoto(tgt);
end
endtask

task tReturn;
begin
	tGoto(stk_state[0]);
	stk_state[0] <= stk_state[1];
	stk_state[1] <= stk_state[2];
	stk_state[2] <= stk_state[3];
	stk_state[3] <= stk_state[4];
	stk_state[4] <= stk_state[5];
	stk_state[5] <= rf80386_pkg::RESET;
end
endtask

task tWriteTSSReg;
input [31:0] rval;
input [7:0] offs;
input wid;
input e_80386state nxt;
begin
	ad <= tbase + offs;
	sel <= wid ? 16'h000F : 16'h0003;
	dat <= rval;
	tGosub(rf80386_pkg::STORE,nxt);
end
endtask

task tReadTSSReg;
input [7:0] offs;
input wid;
input e_80386state nxt;
begin
	ad <= tbase + offs;
	sel <= wid ? 16'h000F : 16'h0003;
	tGosub(rf80386_pkg::LOAD,nxt);
end
endtask

task tSetInt;
input [7:0] ino;
begin
	int_num <= ino;
	int_device <= 16'h0;
end
endtask

task tGoInt;
input [7:0] ino;
begin
	internal_int <= 1'b1;
	tSetInt(ino);
	tGoto(rf80386_pkg::INT2);
end
endtask

task tUedi;
input [31:0] nv;
begin
	if (AddrSize==8'd32)
		edi <= nv;
	else
		edi[15:0] <= nv[15:0];
end
endtask

task tUesi;
input [31:0] nv;
begin
	if (AddrSize==8'd32)
		esi <= nv;
	else
		esi[15:0] <= nv[15:0];
end
endtask

endpackage
