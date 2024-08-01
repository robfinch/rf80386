// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  LOAD_DESC
//  - descriptor load states
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
//  System Verilog 
//
// ============================================================================
//
rf80386_pkg::LOAD_CS_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_CS_DESC1);
	end
rf80386_pkg::LOAD_CS_DESC1:
	begin
		cs_desc <= dat;
		tGoto(rf80386_pkg::LOAD_CS_DESC2);
	end
rf80386_pkg::LOAD_CS_DESC2:
	begin
		if (!cs_desc.typ[1])	// conforming? If so, retain CPL by not loading it.
			cpl <= cs_desc.dpl;
		cs_desc_v <= 1'b1;
		tReturn();
	end

rf80386_pkg::LOAD_DS_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DS_DESC1);
	end
rf80386_pkg::LOAD_DS_DESC1:
	begin
		ds_desc <= dat;
		ds_desc_v <= 1'b1;
		tReturn();
	end

rf80386_pkg::LOAD_ES_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_ES_DESC1);
	end
rf80386_pkg::LOAD_ES_DESC1:
	begin
		es_desc <= dat;
		es_desc_v <= 1'b1;
		tReturn();
	end

rf80386_pkg::LOAD_SS_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_SS_DESC1);
	end
rf80386_pkg::LOAD_SS_DESC1:
	begin
		ss_desc <= dat;
		ss_desc_v <= 1'b1;
		tReturn();
	end

rf80386_pkg::LOAD_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		case(rrr)
		3'd0:	if (es == selector && es_desc_v) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd1:	if (cs == selector && cs_desc_v) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd2:	if (ss == selector && ss_desc_v) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd3:	if (ds == selector && ds_desc_v) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd4:	if (fs == selector && fs_desc_v) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd5:	if (gs == selector && gs_desc_v) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		default:	tGoto(rf80386_pkg::RESET);
		endcase
	end
rf80386_pkg::LOAD_DESC1:
	begin
		case(rrr)
		3'd0:	begin es_desc <= dat; es_desc_v <= 1'b1; end
		3'd1:	begin cs_desc <= dat; cs_desc_v <= 1'b1; end
		3'd2:	begin ss_desc <= dat; ss_desc_v <= 1'b1; end
		3'd3:	begin ds_desc <= dat; ds_desc_v <= 1'b1; end
		3'd4:	begin fs_desc <= dat; fs_desc_v <= 1'b1; end
		3'd5:	begin gs_desc <= dat; gs_desc_v <= 1'b1; end
		default:	;
		endcase
		tReturn();
	end

rf80386_pkg::LxDT:
	begin
		ad <= ea;
		if (lmsw|smsw)
			sel <= 16'h0003;
		else
			sel <= 16'h003F;
		if (smsw) begin
			dat <= cr0[15:0];
			res <= cr0[15:0];
			if (mod==2'b11) begin
				w <= 1'b0;
				wrregs <= 1'b1;
				tGoto(rf80386_pkg::IFETCH);
			end
			else
				tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH);
		end
		else if (sgdt) begin
			sel <= 16'h003F;
			dat <= {gdt_desc.base_hi,gdt_desc.base_lo,gdt_desc.limit_lo};
			tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH);
		end
		else if (sidt) begin
			sel <= 16'h003F;
			dat <= {idt_desc.base_hi,idt_desc.base_lo,idt_desc.limit_lo};
			tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH);
		end
		else
			tGosub(rf80386_pkg::LOAD,rf80386_pkg::LxDT1);
	end
rf80386_pkg::LxDT1:
	begin
		if (lidt) begin
			idt_desc.limit_lo <= dat[15:0];
			{idt_desc.base_hi,idt_desc.base_lo} <= OperandSize32 ? dat[47:16] : {`REALMODE_PG16,dat[39:16]};
		end
		else if (lgdt) begin
			gdt_desc.limit_lo <= dat[15:0];
			{gdt_desc.base_hi,gdt_desc.base_lo} <= OperandSize32 ? dat[47:16] : {`REALMODE_PG16,dat[39:16]};
		end
		else if (lmsw) begin
			cr0[3:0] <= dat[3:0];
		end
		tGoto(rf80386_pkg::IFETCH);
	end

rf80386_pkg::LLDT:
	begin
		ad <= ea;
		sel <= 16'h0003;
		dat <= ldtr;
		if (sldt) begin
			if (mod==2'b11) begin
				res <= ldtr;
				w <= 1'b0;
				wrregs <= 1'b1;
				tGoto(rf80386_pkg::IFETCH);
			end
			else
				tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH);
		end
		else if (str) begin
			dat <= tr;
			if (mod==2'b11) begin
				w <= cs_desc.db;
				wrregs <= 1'b1;
				res <= {16'd0,tr};
				tGoto(rf80386_pkg::IFETCH);
			end
			else
				tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH);
		end
		else
			tGosub(rf80386_pkg::LOAD,rf80386_pkg::LLDT1);
	end
rf80386_pkg::LLDT1:
	begin
		selector <= dat[15:0];
		tGoto(rf80386_pkg::LLDT2);
	end
rf80386_pkg::LLDT2:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LLDT3);
	end
rf80386_pkg::LLDT3:
	begin
		if (verr) begin
			zf <= 1'b0;
			if (!(cs_desc.dpl > dat[46:45] || selector[1:0] > dat[46:45])) begin
				if (dat[44]==1'b1) begin	// data or executable, 0=system
					if (dat[43]==1'b0)	// 0=data segment
						zf <= 1'b1;				// always readable
					else								// 1=code segment
						zf <= dat[41];
				end
			end
		end
		else if (verw) begin
			zf <= 1'b0;
			if (!(cs_desc.dpl > dat[46:45] || selector[1:0] > dat[46:45])) begin
				if (dat[44]==1'b1) begin
					if (dat[43]==1'b0)
						zf <= dat[41];
					else
						zf <= 1'b0;				// code is never writable
				end
			end
		end
		else if (ltr) begin
			tr <= selector;
			tss_desc <= dat;
		end
		else begin
			ldtr <= selector;
			ldt_desc <= dat;
		end
		tGoto(rf80386_pkg::IFETCH);
	end

rf80386_pkg::LAR:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LAR1);
	end
rf80386_pkg::LAR1:
	begin
		zf <= 1'b1;
		wrregs <= 1'b1;
		if (lsl) begin
			if (dat[55])	// 'g' bit
				res <= {dat[51:48],dat[15:0],12'h0};
			else
				res <= {dat[51:48],dat[15:0]};
		end
		else begin
			if (OperandSize32)
				res <= {8'h00,dat[55:52],4'h0,dat[47:40],8'h00};
			else
				res <= {dat[47:40],8'h00};
		end
		tReturn();
	end

rf80386_pkg::LOAD_GATE:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_GATE1);
	end
rf80386_pkg::LOAD_GATE1:
	begin
		cgate <= call_gate386_t'(dat);
		tReturn();
	end
