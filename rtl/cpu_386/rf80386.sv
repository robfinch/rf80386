// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rf80386.sv
//	- 80386 compatible CPU
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
//
//  System Verilog 
//
//  Vivado 2022.2
//	20000 LUTs / 3100 FFs / 8 DSPs
// ============================================================================

import const_pkg::*;
import fta_bus_pkg::*;
import rf80386_pkg::*;

module rf80386(rst_i, clk_i, nmi_i, irq_i, csip, ibundle, ihit, ftam_req, ftam_resp);
parameter CORENO = 6'd1;
parameter CID = 3'd1;
input rst_i;
input clk_i;
input nmi_i;	
input irq_i;
output [31:0] csip;
input [127:0] ibundle;
input ihit;

output fta_cmd_request128_t ftam_req;
input fta_cmd_response128_t ftam_resp;

reg [127:0] bundle;
reg    mio_o;
wire   busy_i;
reg [19:0] adr_o;

reg [1:0] seg_sel;			// segment selection	0=ES,1=SS,2=CS (or none), 3=DS

reg hasFetchedModrm;
reg hasFetchedDisp8;
reg hasFetchedDisp16;
reg hasFetchedData;
reg hasStoredData;
reg hasFetchedVector;

reg [31:0] res;				// result bus
wire pres;					// parity result
wire reszw;					// zero word
wire reszb;					// zero byte
wire resnb;					// negative byte
wire resnw;					// negative word
wire resn;
wire resz;

reg [31:0] tss_flags;
reg [2:0] cyc_type;			// type of bus sycle
reg wrvz, realModeLock;
reg lidt, lgdt, lmsw;
reg lsl, ltr;
reg sidt, sgdt, smsw;
reg sldt, str;
reg verr, verw;
reg jccl;
reg d_lss,d_lfs,d_lgs,d_lds,d_les;
reg int_disable;
reg w;						// 0=8 bit, 1=16 bit
reg d;
reg v;						// 1=count in cl, 0 = count is one
reg [7:0] modrm1;				// for bit scan instructions
reg [1:0] mod;
reg [2:0] rrr;
reg [2:0] rm;
reg [7:0] sib;
reg sxi;
reg [2:0] sreg;
reg [1:0] sreg2;
reg [2:0] sreg3;
reg [2:0] TTT;
reg [7:0] lock_insn;
reg [31:0] seg_reg;			// segment register value for memory access
reg [15:0] data16;			// caches data
reg [15:0] disp16;			// caches displacement
reg [31:0] data32;
reg [31:0] disp32;
reg [31:0] offset;			// caches offset
rf80386_pkg::selector_t selector;		// caches selector
reg [31:0] ea,ea1;		// effective address
reg [31:0] ftmp;			// temporary frame pointer (ENTER)
reg [39:0] desc;			// buffer for sescriptor
reg [6:0] cnt;				// counter
reg [1:0] S43;
reg wrregs;
reg wrsregs;
wire take_br;
reg [4:0] shftamt;
reg ld_div16,ld_div32,ld_div64;		// load divider
reg div_sign;
reg read_code;
reg [31:0] xlat_adr;
reg bus_cycle_started;
reg [7:0] dat_i;
reg ack_i;
reg rty_i;
reg cyc_done;
reg [31:0] tsp;
reg [31:0] sndx;		// scaled index
int_gate386_t igate;
call_gate386_t cgate;
task_gate386_t tgate = task_gate386_t'(cgate);
desc386_t cdesc = desc386_t'(cgate);
reg [4:0] cpycnt;		// parameter stack copy count for call gates
reg [3:0] tid;
reg [4:0] rty_wait;
reg [4:0] sto_wait;

reg nmi_armed;
reg rst_nmi;				// reset the nmi flag
wire pe_nmi;				// indicates positive edge on nmi signal

wire RESET = rst_i;
wire CLK = clk_i;
wire NMI = nmi_i;

`include "REGFILE.sv"	
`include "CONTROL_LOGIC.sv"
`include "WHICH_SEG.sv"
evaluate_branch u4 (OperandSize32,ir,ecx,zf,cf,sf,vf,pf,take_br);
`include "ALU.sv"
nmi_detector u6 (rst_i, clk_i, nmi_i, rst_nmi, pe_nmi);

always_comb
	ack_i = ftam_resp.ack;
always_comb
	rty_i = ftam_resp.rty;
always_comb
	dat_i = ftam_resp.dat >> {ea[3:0],3'd0};

wire [30:0] lfsr31o;
lfsr31 ulfsr1(rst_i, clk_i, 1'b1, 1'b0, lfsr31o);

always_ff @(posedge CLK)
	if (rst_i) begin
		tid <= 4'd1;
		rty_wait <= 5'd0;
		sto_wait <= 5'd0;
		tick <= 32'd0;
		insn_count <= 32'd0;
		imiss_count <= 32'd0;
		int_disable <= 1'b0;
		cpl <= 2'd0;		// most privileged
//		cr0 <= 32'd1;		// boot in protected mode
		cr0 <= 32'd0;		// boot in real mode
		OperandSize32 = 1'b0;
		AddrSize = 8'd16;
		StkAddrSize = 8'd16;
		lidt <= 1'b0;
		lgdt <= 1'b0;
		lmsw <= 1'b0;
		lsl <= 1'b0;
		ltr <= 1'b0;
		sidt <= 1'b0;
		sgdt <= 1'b0;
		sldt <= 1'b0;
		smsw <= 1'b0;
		str <= 1'b0;
		verr <= 1'b0;
		verw <= 1'b0;
		jccl <= 1'b0;
		d_lds <= 1'b0;
		d_les <= 1'b0;
		d_lfs <= 1'b0;
		d_lgs <= 1'b0;
		d_lss <= 1'b0;
		eax <= 32'h0;
		ebx <= 32'h0;
		ecx <= 32'h0;
		edx <= {16'h0,8'h03,8'h40};		// dh=cpu dl=revision
		ebp <= 32'h0;
		esp <= 32'h0;
		esi <= 32'h0;
		edi <= 32'h0;
		wrvz <= 1'b0;
		pf <= 1'b0;
		cf <= 1'b0;
		df <= 1'b0;
		vf <= 1'b0;
		zf <= 1'b0;
		ie <= 1'b0;
		cs <= 16'hF000;
		ds <= 16'h0;
		es <= 16'h0;
		fs <= 16'h0;
		gs <= 16'h0;
		ss <= 16'h0;
		cs_desc <= {$bits(desc386_t){1'b0}};
		ds_desc <= {$bits(desc386_t){1'b0}};
		es_desc <= {$bits(desc386_t){1'b0}};
		fs_desc <= {$bits(desc386_t){1'b0}};
		gs_desc <= {$bits(desc386_t){1'b0}};
		ss_desc <= {$bits(desc386_t){1'b0}};
		cs_desc_v <= 1'b1;
		ds_desc_v <= 1'b1;
		es_desc_v <= 1'b1;
		fs_desc_v <= 1'b1;
		gs_desc_v <= 1'b1;
		ss_desc_v <= 1'b1;
		hasFetchedModrm <= 1'b0;
//		cs <= `CS_RESET;
		cs_desc.db <= 1'b1;							// 32-bit mode
		cs_desc.base_lo <= 24'hF00000;	// base = 0
		cs_desc.base_hi <= 8'hFF;			
		cs_desc.limit_lo <= 16'hFFFF;		// limit = max
		cs_desc.limit_hi <= 4'hF;
		cs_desc.g <= 1'b1;							// 4096 bytes granularity
		cs_desc.p <= 1'b1;							// segment is present
		eip <= 32'h00000000;
		ds_desc.db <= 1'b1;							// 32-bit mode
		ds_desc.base_lo <= 24'hF00000;	// base = 0
		ds_desc.base_hi <= 8'hFF;			
		ds_desc.limit_lo <= 16'hFFFF;		// limit = max
		ds_desc.limit_hi <= 4'hF;
		ds_desc.g <= 1'b1;							// 4096 bytes granularity
		ds_desc.p <= 1'b1;							// segment is present
		es_desc.base_lo <= 24'hF00000;	// base = 0
		es_desc.base_hi <= 8'hFF;			
		es_desc.limit_lo <= 16'hFFFF;		// limit = max
		es_desc.limit_hi <= 4'hF;
		es_desc.g <= 1'b1;							// 4096 bytes granularity
		es_desc.p <= 1'b1;							// segment is present
		fs_desc.base_lo <= 24'hF00000;	// base = 0
		fs_desc.base_hi <= 8'hFF;			
		fs_desc.limit_lo <= 16'hFFFF;		// limit = max
		fs_desc.limit_hi <= 4'hF;
		fs_desc.g <= 1'b1;							// 4096 bytes granularity
		fs_desc.p <= 1'b1;							// segment is present
		gs_desc.base_lo <= 24'hF00000;	// base = 0
		gs_desc.base_hi <= 8'hFF;			
		gs_desc.limit_lo <= 16'hFFFF;		// limit = max
		gs_desc.limit_hi <= 4'hF;
		gs_desc.g <= 1'b1;							// 4096 bytes granularity
		gs_desc.p <= 1'b1;							// segment is present
		ss_desc.db <= 1'b1;							// 32-bit mode
		ss_desc.base_lo <= 24'hF00000;	// base = 0
		ss_desc.base_hi <= 8'hFF;			
		ss_desc.limit_lo <= 16'hFFFF;		// limit = max
		ss_desc.limit_hi <= 4'hF;
		ss_desc.g <= 1'b1;							// 4096 bytes granularity
		ss_desc.p <= 1'b1;							// segment is present
		ftam_req <= {$bits(fta_cmd_request128_t){1'b0}};
		ir <= `NOP;
		prefix1 <= 8'h00;
		prefix2 <= 8'h00;
		prefix3 <= 8'h00;
		prefix4 <= 8'h00;
		rst_nmi <= 1'b1;
		wrregs <= 1'b0;
		wrsregs <= 1'b0;
		ld_div16 <= 1'b0;
		ld_div32 <= 1'b0;
		read_code <= 1'b0;
		bus_cycle_started <= FALSE;
		cyc_done <= TRUE;
		ftam_req.tid.core <= CORENO;
		ftam_req.tid.channel <= CID;
		ftam_req.tid.tranid <= 4'd1;
		mod <= 2'd0;
		rm <= 3'd0;
		rrr <= 3'd0;
		sxi <= 1'b0;
		hasFetchedModrm <= 1'b0;
		hasFetchedDisp8 <= 1'b0;
		hasFetchedDisp16 <= 1'b0;
		hasFetchedVector <= 1'b0;
		hasStoredData <= 1'b0;
		hasFetchedData <= 1'b0;
		data16 <= 16'h0000;
		cnt <= 7'd0;
		tsp <= 16'd0;
		ftmp <= 32'h0;
		d_jmp <= 1'b0;
		nest_task <= 1'b0;
		next_ie <= 1'b0;
		internal_int <= 1'b0;
		tClearBus();
		int_num <= 8'h00;
		ea1 <= 32'h0;
		realModeLock <= 1'b0;
		tGoto(rf80386_pkg::IFETCH);
	end
	else begin
		irq_fifo_read <= 1'b0;
		rst_nmi <= 1'b0;
		wrregs <= 1'b0;
		wrsregs <= 1'b0;
		ld_div16 <= 1'b0;
		ld_div32 <= 1'b0;
		tick <= tick + 2'd1;
		if (!ihit)
			imiss_count <= imiss_count + 2'd1;

		tClearBus();

`include "WRITEBACK.sv"

		case(state)

`include "IFETCH.sv"
`include "DECODE.sv"
`include "DECODER2.sv"
`include "XLAT.sv"
`include "REGFETCHA.sv"
`include "EACALC.sv"
`include "CMPSB.sv"
`include "CMPSW.sv"
`include "MOVS.sv"
`include "LODS.sv"
`include "STOS.sv"
`include "SCASB.sv"
`include "SCASW.sv"
`include "EXECUTE.sv"
`include "FETCH_DATA.sv"
`include "FETCH_DISP8.sv"
`include "FETCH_DISP16.sv"
`include "FETCH_IMMEDIATE.sv"
`include "FETCH_OFFSET_AND_SEGMENT.sv"
`include "MOV_I2BYTREG.sv"
`include "STORE_DATA.sv"
`include "BRANCH.sv"
`include "CALL.sv"
`include "CALLF.sv"
`include "CALL_IN.sv"
`include "INTA.sv"
`include "INT.sv"
`include "FETCH_STK_ADJ.sv"
`include "RETPOP.sv"
`include "RETFPOP.sv"
`include "IRET.sv"
`include "JUMP_VECTOR.sv"
`include "PUSH.sv"
`include "PUSHA.sv"
`include "POP.sv"
`include "POPA.sv"
`include "INB.sv"
`include "INW.sv"
`include "OUTB.sv"
`include "OUTW.sv"
`include "INSB.sv"
`include "OUTSB.sv"
`include "XCHG_MEM.sv"
`include "DIVIDE.sv"
`include "ENTER.sv"
`include "LEAVE.sv"
`include "LOADSTORE.sv"
`include "LOAD_DESC.sv"
`include "TASK.sv"
				default:
				state <= rf80386_pkg::IFETCH;
			endcase
		end

int_queue iq1 (
	.rst(rst_i),
	.clk(CLK),
	.cpri(ipri),
	.wr(irq_fifo_write),
	.i(irq_fifo_data_in),
	.rd(irq_fifo_read),
	.o(irq_fifo_data_out),
	.ov(),
	.full(irq_fifo_full),
	.empty(irq_fifo_empty),
	.underflow(irq_fifo_underflow)
);

			
task nack_ir;
begin
	ir <= ibundle[7:0];
	bundle <= ibundle[127:8];
	eip <= ip_inc;
end
endtask

task nack_ir2;
begin
	ir2 <= bundle[7:0];
	bundle <= bundle[127:8];
	eip <= ip_inc;
end
endtask

task tCodeRead;
begin
	bundle <= {8'h90,bundle[127:8]};	// 90h = NOP
end
endtask

task tClearBus;
begin
	ftam_req.cmd <= fta_bus_pkg::CMD_NONE;
	ftam_req.tid.tranid <= 4'd0;
	ftam_req.cyc <= LOW;
	ftam_req.stb <= LOW;
	ftam_req.we <= LOW;
	ftam_req.sel <= 16'h0;
end
endtask

task tSetTid;
begin
	ftam_req.tid.tranid <= tid + 2'd1;
	tid <= tid + 2'd1;
	if (tid==4'd15) begin
		ftam_req.tid.tranid <= 4'd1;
		tid <= 4'd1;
	end
end
endtask

endmodule
