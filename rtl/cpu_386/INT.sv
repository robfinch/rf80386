// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  INT.sv
//  - Interrupt handling
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
//
// Fetch interrupt number from instruction stream

rf80386_pkg::INT:
	begin
		eip <= eip + 2'd1;
		ir_ip <= eip + 2'd1;
		int_num <= bundle[7:0];
		tGoto(rf80386_pkg::INT2);
	end

// Dispatch interrupt sequence according to mode.
rf80386_pkg::INT2:
	begin
		if (realMode)
			tGoto(rf80386_pkg::RMD_INT3);
		else if (v86) begin
			if ({int_num,3'd0} > idt_limit)
				tSetInt(8'd13);		// general protection fault
			else
				tGoto(rf80386_pkg::V86_INT3);
		end
		else begin
			if ({int_num,3'd0} > idt_limit)
				tSetInt(8'd13);		// general protection fault
			else
				tGoto(rf80386_pkg::INT3);
		end
	end

// Real mode interrupt sequence
rf80386_pkg::RMD_INT3:
	begin
		ad <= idt_base + {int_num,2'd0};
		sel <= 16'h000F;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::RMD_INT4);
	end
rf80386_pkg::RMD_INT4:
	begin
		offset[15:0] <= dat[15:0];
		offset[31:16] <= 16'h0;
		selector <= dat[31:16];
		esp <= esp - 4'd2;
		tGoto(rf80386_pkg::RMD_INT5);
	end
rf80386_pkg::RMD_INT5:
	begin
		ad <= sssp;
		sel <= 16'h0003;
		dat <= flags[15:0];
		esp <= esp - 4'd2;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::RMD_INT6);
	end
rf80386_pkg::RMD_INT6:
	begin
		ad <= sssp;
		sel <= 16'h0003;
		dat <= cs;
		esp <= esp - 4'd2;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::RMD_INT7);
	end
rf80386_pkg::RMD_INT7:
	begin
		ad <= sssp;
		sel <= 16'h0003;
		dat <= ir_ip[15:0];
		tGosub(rf80386_pkg::STORE,rf80386_pkg::RMD_INT8);
	end
rf80386_pkg::RMD_INT8:
	begin
		cs <= selector;
		eip <= offset;
		tGoto(rf80386_pkg::IFETCH);
	end

// virtual x86 mode interrupt sequence
rf80386_pkg::V86_INT3:
	begin
		old_cs <= cs;
		old_eip <= eip;
		old_ds <= ds;
		old_es <= es;
		old_fs <= fs;
		old_gs <= gs;
		old_ss <= ss;
		old_esp <= esp;
		// Load gate
		ad <= idt_base + {int_num,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::V86_INT4);
	end
rf80386_pkg::V86_INT4:
	begin
		tGoto(rf80386_pkg::INT2);
		case({igatei.s,igatei.typ})
		5'b00101:	// task gate
			tGoto(rf80386_pkg::INT_TASK1);
		5'b00110,	// 286 int gate
		5'b00111,	// 286 trap gate
		5'b01110,	// 386 int gate
		5'b01111:	// 386 trap gate
			begin
				// Load ss:esp from TSS privilege level 0
				ad <= tss_base + 4'd4;		// esp
				sel <= 16'h00FF;					// read eight bytes
				igate <= int_gate386_t'(dat[63:0]);
				tGosub(rf80386_pkg::LOAD,rf80386_pkg::V86_INT5);
			end
		default:
			begin
				tGoInt(8'd13);	// general protection fault
			end
		endcase
		// Traps do not affect the interrupt enable flag, other interrupts clear it.
		case({igatei.s,igatei.typ})
		5'b00110,	// 286 int gate
		5'b01110:	// 386 int gate
			next_ie <= 1'b0;
		default:
			next_ie <= ie;
		endcase
	end
rf80386_pkg::V86_INT5:
	begin
		// record old instruction pointer. For an interrupt this will be the 
		// address of the interrupted instruction. For a trap this will be
		// the address of the following instruction.
		old_eip <= ir_ip;
		// get int routine target address (selector:offset)
		neip[15: 0] <= igate.offset_lo;
		neip[31:16] <= igate.offset_hi;
		selector <= igate.selector;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::V86_INT6);
	end
rf80386_pkg::V86_INT6:
	begin
		// Load ss:esp from TSS privilege level 0
		ad <= tss_base + 4'd4;		// esp
		sel <= 16'h00FF;					// read eight bytes
		eip <= neip;
		cs <= selector;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::V86_INT7);
	end
	// Push segement registers for v86 mode
rf80386_pkg::V86_INT7:
	begin
		// Set ss:esp to priv level 0 from tss
		ss <= dat[47:32];
		esp <= dat[31:0];
		tGoto(rf80386_pkg::V86_INT9);
	end
rf80386_pkg::V86_INT9:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_gs;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::V86_INT10);
	end
rf80386_pkg::V86_INT10:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_fs;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::V86_INT11);
	end
rf80386_pkg::V86_INT11:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_ds;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::V86_INT12);
	end
rf80386_pkg::V86_INT12:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_es;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::V86_INT13);
	end
rf80386_pkg::V86_INT13:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_ss;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::V86_INT14);
	end
rf80386_pkg::V86_INT14:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_esp;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::V86_INT15);
	end
rf80386_pkg::V86_INT15:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= flags[31:0];
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::V86_INT16);
	end
rf80386_pkg::V86_INT16:
	begin
		ad <= sssp;
		sel <= 16'h0003;
		dat <= cs;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::V86_INT17);
	end
rf80386_pkg::V86_INT17:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_eip;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::V86_INT18);
	end
rf80386_pkg::V86_INT18:
	begin
		ds <= 16'h0;
		es <= 16'h0;
		fs <= 16'h0;
		gs <= 16'h0;
		ds_desc_v <= 1'b0;
		es_desc_v <= 1'b0;
		fs_desc_v <= 1'b0;
		gs_desc_v <= 1'b0;
		vm <= 1'b0;
		tf <= 1'b0;
		ie <= next_ie;
		tGoto(rf80386_pkg::IFETCH);
	end

// Protected mode interrupt sequence
rf80386_pkg::INT3:
	begin
		old_cs <= cs;
		old_eip <= ir_ip;
		old_ds <= ds;
		old_es <= es;
		old_fs <= fs;
		old_gs <= gs;
		old_ss <= ss;
		old_esp <= esp;
		// Load interrupt gate
		ad <= idt_base + {int_num,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::INT4);
	end
rf80386_pkg::INT4:
	begin
		case({igatei.s,igatei.typ})
		5'b00101:	// task gate
			tGoto(rf80386_pkg::INT_TASK1);
		5'b00110,	// 286 int gate
		5'b00111,	// 286 trap gate
		5'b01110,	// 386 int gate
		5'b01111:	// 386 trap gate
			begin
				// Load ss:esp from TSS privilege level 0
				ad <= tss_base + 4'd4;		// esp
				sel <= 16'h00FF;					// read eight bytes
				igate <= int_gate386_t'(dat[63:0]);
				tGoto(rf80386_pkg::INT5);
			end
		default:
			tGoInt(8'd13);	// general protection fault
		endcase
		// Traps do not affect the interrupt enable flag, other interrupts clear it.
		case({igatei.s,igatei.typ})
		5'b00110,	// 286 int gate
		5'b01110:	// 386 int gate
			next_ie <= 1'b0;
		default:
			next_ie <= ie;
		endcase
	end
rf80386_pkg::INT5:
	begin
		// get int routine target address (selector:offset)
		neip[15: 0] <= igate.offset_lo;
		neip[31:16] <= igate.offset_hi;
		if (cs == igate.selector && cs_desc_v) begin
			eip[15: 0] <= igate.offset_lo;
			eip[31:16] <= igate.offset_hi;
			tGoto(rf80386_pkg::INT11);
		end
		else begin
			// Load CS descriptor, needed to know if priv level changes
			selector <= igate.selector;
			if (!fnSelectorInLimit(igate.selector))
				tGoInt(8'd13);		// general protection fault
			else
				tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::INT6);
		end
	end
rf80386_pkg::INT6:
	begin
		eip <= neip;
		cs <= selector;
		// Descriptor must be for a code segment
		if ({cs_desc.s,cs_desc.typ[3]} != 2'b11)
			tGoInt(8'd13);		// general protection fault
		else if (!cs_desc.p)
			tGoInt(8'd11);		// segment not present
		else if (!cs_desc.typ[1] && cs_desc.dpl < cpl)
			tGoto(rf80386_pkg::INT_INNER_PRIV);
		// if cpl match dpl or it is conforming
		else if (cs_desc.dpl==cpl || cs_desc.typ[1]) begin
			tGoto(rf80386_pkg::INT_SAME_PRIV);
		/*
			// priv level change?
			// If the priv level changes, the old ss:esp needs to be saved
			// on the stack. Setup to switch to stack of target priv.
			if (cs_desc.dpl != cpl) begin
				ad <= tss_base + 32'd4 + {cs_desc.dpl,3'd0};
				sel <= 16'h00FF;					// read eight bytes
				tGosub(rf80386_pkg::LOAD,rf80386_pkg::INT7);
			end
		*/
		end
		else
			tGoInt(8'd13);		// general protection fault
	end

rf80386_pkg::INT_INNER_PRIV:
	begin
		ad <= tss_base + 32'd4 + {cs_desc.dpl,3'd0};
		sel <= 16'h00FF;					// read eight bytes
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::INT7);
	end

rf80386_pkg::INT7:
	begin
		// Set ss:esp to priv level from tss
		ss <= dat[47:32];
		esp <= dat[31:0];
		selector <= dat[47:32];
		tGoto(rf80386_pkg::INT8);
	end
rf80386_pkg::INT8:
	begin
		// selector NULL?
		if (ss[15:2]==14'd0)
			tGoInt(8'd13);		// general protection fault
		else if (!fnSelectorInLimit(ss))
			tGoInt(8'd10);		// invalid TSS
		else if (ss[1:0] != cs_desc.dpl)
			tGoInt(8'd10);		// invalid TSS
		else begin
			esp <= esp - 4'd4;
			selector <= ss;
			tGosub(rf80386_pkg::LOAD_SS_DESC,rf80386_pkg::INT9);
		end
	end
rf80386_pkg::INT9:
	begin
		// Must be writable data segment
		if (!ss_desc.s || ss_desc.typ[3] || !ss_desc.typ[1])
			tGoInt(8'd10);		// invalid TSS
		// and must be present
		else if (!ss_desc.p)
			tGoInt(8'd12);		// stack exception
		// must have room for 20 bytes
		// ToDo: check for 10 bytes room for 16-bit
		else if (esp > ss_limit - 8'd20)
			tGoInt(8'd12);		// stack exception
		// instruction pointer must be within cs limit
		else if (eip > cs_limit)
			tGoInt(8'd13);		// general protection fault
		else begin
			ad <= sssp;
			sel <= 16'h000F;
			dat <= old_ss;
			esp <= esp - 4'd4;
			tGosub(rf80386_pkg::STORE,rf80386_pkg::INT10);
		end
	end
rf80386_pkg::INT10:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_esp;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::INT11);
	end
rf80386_pkg::INT11:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= flags[31:0];
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::INT12);
	end
rf80386_pkg::INT12:
	begin
		ad <= sssp;
		sel <= 16'h0003;
		dat <= old_cs;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::INT13);
	end
rf80386_pkg::INT13:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_eip;
		cpl <= cs_desc.dpl;
		cs[1:0] <= cs_desc.dpl;
		tf <= 1'b0;
		nt <= 1'b0;
		ie <= next_ie;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH);
	end
rf80386_pkg::INT_SAME_PRIV:
	begin
		// must have room for 10 bytes
		// ToDo: check for 6 bytes room for 16-bit
		if (esp > ss_limit - 8'd10)
			tGoInt(8'd12);		// stack exception
		// instruction pointer must be within cs limit
		else if (eip > cs_limit)
			tGoInt(8'd13);		// general protection fault
		else
			tGoto(rf80386_pkg::INT11);
	end


rf80386_pkg::INT_TASK1:
	begin
		if (igate.selector[2])	// global table?
			tGoInt(8'd10);			// invalid TSS
		else if (!fnSelectorInLimit(igate.selector))
			tGoInt(8'd10);			// invalid TSS
		else begin
			selector <= igate.selector;
			new_tr <= igate.selector;
			old_tss_desc <= tss_desc;
			rrr <= 3'd6;
			tGosub(rf80386_pkg::LOAD_DESC,rf80386_pkg::INT_TASK2);
		end
	end
rf80386_pkg::INT_TASK2:
	begin
		if (!tss_desc.p)
			tGoInt(8'd11);		// segment not present
		else begin
			nest_task <= 1'b1;
			tGosub(rf80386_pkg::TASK_SWITCH1,rf80386_pkg::INT_TASK3);
		end
	end
rf80386_pkg::INT_TASK3:
	begin
		if (eip > cs_limit)
			tGoInt(8'd13);		// general protection fault
		else
			tGoto(rf80386_pkg::IFETCH);
	end

