// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  Register file
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

reg [31:0] cr0;
reg [31:0] rrro;			
reg [31:0] rmo;				// register output (controlled by mod r/m byte)
reg [31:0] rfso;
wire realMode = ~cr0[0];

reg pf;						// parity flag
reg af;						// auxillary carry (half carry) flag
reg zf, cf, vf;
reg sf;						// sign flag
reg df;						// direction flag
reg ie;						// interrupt enable flag
reg tf;
reg vm;
wire [31:0] flags = {vm,1'b0,1'b0,1'b0,1'b0,2'b00,vf,df,ie,tf,sf,zf,1'b0,af,1'b0,pf,1'b0,cf};
wire v86 = vm;
reg [1:0] cpl;

reg [7:0] ir;				// instruction register
reg [7:0] ir2;				// extended instruction register
reg [31:0] eip;				// instruction pointer
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
reg [15:0] old_cs;		// code segment
reg [15:0] old_ds;		// data segment
reg [15:0] old_es;		// extra segment
reg [15:0] old_fs;		// extra segment
reg [15:0] old_gs;		// extra segment
reg [15:0] old_ss;		// stack segment
reg [15:0] new_ss;		// for CALL far

desc386_t cs_desc;
desc386_t ds_desc;
desc386_t es_desc;
desc386_t fs_desc;
desc386_t gs_desc;
desc386_t ss_desc;
desc386_t tss_desc;
desc386_t idt_desc;
desc386_t gdt_desc;
desc386_t ldt_desc;
reg cs_desc_v;
reg ds_desc_v;
reg es_desc_v;
reg fs_desc_v;
reg gs_desc_v;
reg ss_desc_v;
reg [31:0] gdtr, ldtr;

reg [31:0] tick;
reg [31:0] insn_count;
reg [31:0] imiss_count;

// renamed byte registers for convenience
wire [7:0] al = eax[7:0];
wire [7:0] ah = eax[15:8];
wire [7:0] dl = edx[7:0];
wire [7:0] dh = edx[15:8];
wire [7:0] cl = ecx[7:0];
wire [7:0] ch = ecx[15:8];
wire [7:0] bl = ebx[7:0];
wire [7:0] bh = ebx[15:8];
wire [15:0] ax = eax[15:0];
wire [15:0] bx = ebx[15:0];
wire [15:0] cx = ecx[15:0];
wire [15:0] dx = edx[15:0];
wire [15:0] sp = esp[15:0];
wire [15:0] bp = ebp[15:0];
wire [15:0] si = esi[15:0];
wire [15:0] di = edi[15:0];

// A pipeline stage is inserted to the base address determination to avoid a
// cascade of a lot of combo logic and improve the performance. The base values
// are essentially static unless the segment register is changed. So, there will
// be a delay in calculating the base address, but that only happens on a move
// to a segment register. The value is always valid by the time it is needed for
// addressing.

reg [31:0] cs_base, ss_base, ds_base, es_base, fs_base, gs_base;
reg [31:0] cs_limit, ds_limit, es_limit, fs_limit, gs_limit, ss_limit;

always_ff @(posedge clk_i) cs_base <= ~realMode ? {cs_desc.base_hi, cs_desc.base_lo} : {`REALMODE_PG1M,cs,`SEG_SHIFT};
always_ff @(posedge clk_i) ss_base <= ~realMode ? {ss_desc.base_hi, ss_desc.base_lo} : {`REALMODE_PG1M,ss,`SEG_SHIFT};
always_ff @(posedge clk_i) ds_base <= ~realMode ? {ds_desc.base_hi, ds_desc.base_lo} : {`REALMODE_PG1M,ds,`SEG_SHIFT};
always_ff @(posedge clk_i) es_base <= ~realMode ? {es_desc.base_hi, es_desc.base_lo} : {`REALMODE_PG1M,es,`SEG_SHIFT};
always_ff @(posedge clk_i) fs_base <= ~realMode ? {fs_desc.base_hi, fs_desc.base_lo} : {`REALMODE_PG1M,fs,`SEG_SHIFT};
always_ff @(posedge clk_i) gs_base <= ~realMode ? {gs_desc.base_hi, gs_desc.base_lo} : {`REALMODE_PG1M,gs,`SEG_SHIFT};

always_comb cs_limit = realMode ? 32'h000FFFFF : cs_desc.g ? {cs_desc.limit_hi,cs_desc.limit_lo,12'h0} : {12'h0,cs_desc.limit_hi,cs_desc.limit_lo};
always_comb ds_limit = realMode ? 32'h000FFFFF : ds_desc.g ? {ds_desc.limit_hi,ds_desc.limit_lo,12'h0} : {12'h0,ds_desc.limit_hi,ds_desc.limit_lo};
always_comb es_limit = realMode ? 32'h000FFFFF : es_desc.g ? {es_desc.limit_hi,es_desc.limit_lo,12'h0} : {12'h0,es_desc.limit_hi,es_desc.limit_lo};
always_comb fs_limit = realMode ? 32'h000FFFFF : fs_desc.g ? {fs_desc.limit_hi,fs_desc.limit_lo,12'h0} : {12'h0,fs_desc.limit_hi,fs_desc.limit_lo};
always_comb gs_limit = realMode ? 32'h000FFFFF : gs_desc.g ? {gs_desc.limit_hi,gs_desc.limit_lo,12'h0} : {12'h0,gs_desc.limit_hi,gs_desc.limit_lo};
always_comb ss_limit = realMode ? 32'h000FFFFF : ss_desc.g ? {ss_desc.limit_hi,ss_desc.limit_lo,12'h0} : {12'h0,ss_desc.limit_hi,ss_desc.limit_lo};

wire [31:0] idt_base = {idt_desc.base_hi, idt_desc.base_lo};
wire [31:0] gdt_base = {gdt_desc.base_hi, gdt_desc.base_lo};
wire [31:0] ldt_base = {ldt_desc.base_hi, ldt_desc.base_lo};
wire [31:0] tss_base = {tss_desc.base_hi, tss_desc.base_lo};

wire [31:0] csip = cs_base + eip;
wire [31:0] sssp = ss_base + (StkAddrSize==8'd32 ? esp : sp);
wire [31:0] dssi = ds_base + (AddrSize==8'd32 ? esi : si);
wire [31:0] esdi = es_base + (AddrSize==8'd32 ? edi : di);

// Read port
// Cannot easily pipeline this read port. rrr is set in the DECODE stage and
// the register value is needed in the next clock cycle.
//
always_comb
	case({w,rrr})
	4'd0:	rrro <= {{24{eax[7]}},eax[7:0]};
	4'd1:	rrro <= {{24{ecx[7]}},ecx[7:0]};
	4'd2:	rrro <= {{24{edx[7]}},edx[7:0]};
	4'd3:	rrro <= {{24{ebx[7]}},ebx[7:0]};
	4'd4:	rrro <= {{24{eax[15]}},eax[15:8]};
	4'd5:	rrro <= {{24{ecx[15]}},ecx[15:8]};
	4'd6:	rrro <= {{24{edx[15]}},edx[15:8]};
	4'd7:	rrro <= {{24{ebx[15]}},ebx[15:8]};
	4'd8:	rrro <= eax;
	4'd9:	rrro <= ecx;
	4'd10:	rrro <= edx;
	4'd11:	rrro <= ebx;
	4'd12:	rrro <= esp;
	4'd13:	rrro <= ebp;
	4'd14:	rrro <= esi;
	4'd15:	rrro <= edi;
	endcase


// Second Read port
//
always_comb
	case({w,rm})
	4'd0:	rmo <= {{24{eax[7]}},eax[7:0]};
	4'd1:	rmo <= {{24{ecx[7]}},ecx[7:0]};
	4'd2:	rmo <= {{24{edx[7]}},edx[7:0]};
	4'd3:	rmo <= {{24{ebx[7]}},ebx[7:0]};
	4'd4:	rmo <= {{24{eax[15]}},eax[15:8]};
	4'd5:	rmo <= {{24{ecx[15]}},ecx[15:8]};
	4'd6:	rmo <= {{24{edx[15]}},edx[15:8]};
	4'd7:	rmo <= {{24{ebx[15]}},ebx[15:8]};
	4'd8:	rmo <= eax;
	4'd9:	rmo <= ecx;
	4'd10:	rmo <= edx;
	4'd11:	rmo <= ebx;
	4'd12:	rmo <= esp;
	4'd13:	rmo <= ebp;
	4'd14:	rmo <= esi;
	4'd15:	rmo <= edi;
	endcase


// Read segment registers
// Needed only for moving the sreg to a reg in the EACALC. Plenty of room to
// pipeline this, so it is.
//
always_comb
	case(sreg3)
	3'd0:	rfso <= es;
	3'd1:	rfso <= cs;
	3'd2:	rfso <= ss;
	3'd3:	rfso <= ds;
	3'd4:	rfso <= fs;
	3'd5:	rfso <= gs;
	default:	rfso <= 16'h0000;
	endcase
