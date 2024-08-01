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
		else if (v86)
			tGoto(rf80386_pkg::V86_INT3);
		else
			tGoto(rf80386_pkg::INT3);
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
		// Load interrupt gate
		ad <= idt_base + {int_num,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::V86_INT4);
	end
rf80386_pkg::V86_INT4:
	begin
		// Load ss:esp from TSS privilege level 0
		ad <= tss_base + 4'd4;		// esp
		sel <= 16'h00FF;					// read eight bytes
		igate <= int_gate386_t'(dat[63:0]);
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::V86_INT5);
	end
rf80386_pkg::V86_INT5:
	begin
		// record old instruction pointer. For an interrupt this will be the 
		// address of the interrupted instruction. For a trap this will be
		// the address of the following instruction.
		old_eip <= ir_ip;
		// get int routine target address (selector:offset)
		eip[15: 0] <= igate.offset_lo;
		eip[31:16] <= igate.offset_hi;
		cs <= igate.selector;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::V86_INT6);
	end
rf80386_pkg::V86_INT6:
	begin
		// Load ss:esp from TSS privilege level 0
		ad <= tss_base + 4'd4;		// esp
		sel <= 16'h00FF;					// read eight bytes
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
		igate <= int_gate386_t'(dat[63:0]);
		tGoto(rf80386_pkg::INT5);
	end
rf80386_pkg::INT5:
	begin
		// get int routine target address (selector:offset)
		eip[15: 0] <= igate.offset_lo;
		eip[31:16] <= igate.offset_hi;
		if (cs == igate.selector && cs_desc_v)
			tGoto(rf80386_pkg::INT11);
		else begin
			// Load CS descriptor, needed to know if priv level changes
			cs <= igate.selector;
			tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::INT6);
		end
	end
rf80386_pkg::INT6:
	begin
		// if cpl match dpl or it is conforming
		if (cs_desc.dpl==cpl || cs_desc.typ[1]) begin
			tGoto(rf80386_pkg::INT11);
			// priv level change?
			// If the priv level changes, the old ss:esp needs to be saved
			// on the stack. Setup to switch to stack of target priv.
			if (cs_desc.dpl != cpl) begin
				ad <= tss_base + 32'd4 + {cs_desc.dpl,3'd0};
				sel <= 16'h00FF;					// read eight bytes
				tGosub(rf80386_pkg::LOAD,rf80386_pkg::INT7);
			end
		end
		//else
			// fault
	end
rf80386_pkg::INT7:
	begin
		// Set ss:esp to priv level from tss
		ss <= dat[47:32];
		esp <= dat[31:0];
		tGoto(rf80386_pkg::INT8);
	end
rf80386_pkg::INT8:
	begin
		esp <= esp - 4'd4;
		tGoto(rf80386_pkg::INT9);
	end
rf80386_pkg::INT9:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_ss;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::INT10);
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
		dat <= cs;
		esp <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::INT13);
	end
rf80386_pkg::INT13:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_eip;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH);
	end
