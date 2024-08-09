// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  RETFPOP: far return from subroutine and pop stack items
//  Fetch ip from stack
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

rf80386_pkg::RETFPOP:
	begin
		if (realMode | v86)
			tGoto(rf80386_pkg::RETFPOP_RMD1);
		else
			tGoto(rf80386_pkg::RETFPOP1);
	end
rf80386_pkg::RETFPOP_RMD1:
	begin
		ad <= sssp;
		if (OperandSize32) begin
			esp[15:0] <= esp[15:0] + 4'd8;
			sel <= 16'h00FF;
		end
		else begin
			esp[15:0] <= esp[15:0] + 4'd4;
			sel <= 16'h000F;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::RETFPOP_RMD2);
	end
rf80386_pkg::RETFPOP_RMD2:
	begin
		if (OperandSize32)
			{selector,eip[31:0]} <= dat[47:0];
		else begin
			{selector,eip[15:0]} <= dat[31:0];
			eip[31:16] <= 16'h0;
		end
		tGoto(rf80386_pkg::RETFPOP_RMD3);
	end
rf80386_pkg::RETFPOP_RMD3:
	begin
		if (ir==`RETFPOP) begin
			wrregs <= 1'b1;
			w <= 1'b1;
			rrr <= 3'd4;
			if (OperandSize32)
				res <= esp + {bundle[15:0],1'b0};
			else
				res <= esp + bundle[15:0];
		end
		cs <= selector;
		tGoto(rf80386_pkg::IFETCH);
	end

rf80386_pkg::RETFPOP1:
	begin
		ad <= sssp;
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::RETFPOP2);
	end
rf80386_pkg::RETFPOP2:
	begin
		esp <= esp + 4'd8;
		{selector,eip} <= dat[47:0];
		tGoto(rf80386_pkg::RETFPOP3);
	end
rf80386_pkg::RETFPOP3:
	begin
		tGoInt(8'd13);
		if (selector[15:2]!=14'h0) begin	// selector non-null?
			if (selector_in_limit) begin		// selector within bounds?
				if (selector.rpl >= cpl) begin// Check return priv. level
					old_cs <= cs;
					cs <= selector;
					if (cs != selector)
						tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::RETFPOP4);
					else
						tGoto(rf80386_pkg::RETFPOP4);
				end
			end
		end
	end
rf80386_pkg::RETFPOP4:
	begin
		tGoInt(8'd13);	// default: general protection fault
		if (cs_desc.s && cs_desc.typ[3]) begin	// executable segment
			if ((cs_desc.typ[1] && cs_desc.dpl <= cpl) || cs_desc.dpl==cpl)	begin		// conforming?, or non-conforming and cpl match
				if (cs_desc.p) begin			// segment present
					if (selector.rpl==cpl)
						tGoto(rf80386_pkg::RETFPOP_SAME_LEVEL);
					else
						tGoto(rf80386_pkg::RETFPOP_OUTER_LEVEL);
				end
			end
		end
	end
rf80386_pkg::RETFPOP_SAME_LEVEL:
	begin
		tGoInt(8'd13);	// default: general protection fault
		if (esp <= ss_limit) begin	// stack within limit
			if (eip <= cs_limit) begin
				ad <= sssp;
				if (OperandSize32) begin
					sel <= 16'h00FF;
					esp <= esp + 4'd8;
				end
				else begin
					sel <= 16'h000F;
					esp <= esp + 4'd4;
				end
				tGosub(rf80386_pkg::LOAD,rf80386_pkg::RETFPOP5);
			end
			else begin
				tGoInt(8'd11);	// segment not present
			end
		end
		else
			tGoInt(8'd12);		// stack exception
	end

rf80386_pkg::RETFPOP5:
	begin
		if (ir==`RETFPOP) begin
			wrregs <= 1'b1;
			w <= 1'b1;
			rrr <= 3'd4;
			if (OperandSize32)
				res <= esp + {bundle[15:0],1'b0};
			else
				res <= esp + bundle[15:0];
		end
		tGoto(rf80386_pkg::IFETCH);
	end

rf80386_pkg::RETFPOP_OUTER_LEVEL:
	begin
		if (OperandSize32) begin
			if (esp + 32'd16 + {bundle[15:0],1'b0} > ss_limit)
				tGoInt(8'd12);		// stack exception
		end
		else if (esp + 32'd8 + {bundle[15:0]} > ss_limit)
			tGoInt(8'd12);		// stack exception
		else begin
			if (OperandSize32)
				esp <= esp + {bundle[15:0],1'b0};
			else
				esp <= esp + bundle[15:0];
		end
	end
// Pop old SS:ESP
rf80386_pkg::RETFPOP6:
	begin
		ad <= sssp;
		sel <= 16'h00FF;
		esp <= esp + 4'd8;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::RETFPOP7);
	end
	// Store SS:ESP in TSS
rf80386_pkg::RETFPOP7:
	begin
		{old_ss,old_esp} <= dat[47:0];
		ad <= tss_base + 32'd4 + {ss[1:0],3'd0};	//ss.rpl
		sel <= 16'h00FF;
		dat <= {ss,esp};
		tGosub(rf80386_pkg::STORE,rf80386_pkg::RETFPOP8);
	end
rf80386_pkg::RETFPOP8:
	begin
		ss <= old_ss;
		esp <= old_esp;
		selector <= old_ss;
		tGosub(rf80386_pkg::LOAD_SS_DESC,rf80386_pkg::RETFPOP9);
	end
rf80386_pkg::RETFPOP9:
	begin
		if (OperandSize32)
			esp <= esp + {bundle[15:0],1'b0} + 4'd8;
		else
			esp <= esp + bundle[15:0] + 4'd8;
		selector <= ds;
		tGoto(rf80386_pkg::RETFPOP10);
	end
rf80386_pkg::RETFPOP10:
	begin
		selector <= es;
		tGoto(rf80386_pkg::RETFPOP11);
		if (selector_in_limit) begin		// selector within bounds?
			if (fnIsReadableCodeOrData(ds_desc)) begin
				// data or non-conforming code?
				if (ds_desc.typ[3]==1'b0 || ds_desc.typ[2]==1'b0)	begin
					if (!(ds_desc.dpl >= cpl || ds_desc.dpl >= cs_desc.dpl))
						ds <= 16'h0;
				end
			end
		end
	end
rf80386_pkg::RETFPOP11:
	begin
		selector <= fs;
		tGoto(rf80386_pkg::RETFPOP12);
		if (selector_in_limit) begin		// selector within bounds?
			if (fnIsReadableCodeOrData(es_desc)) begin
				// data or non-conforming code?
				if (es_desc.typ[3]==1'b0 || es_desc.typ[2]==1'b0)	begin
					if (!(es_desc.dpl >= cpl || es_desc.dpl >= cs_desc.dpl))
						es <= 16'h0;
				end
			end
		end
	end
rf80386_pkg::RETFPOP12:
	begin
		selector <= gs;
		tGoto(rf80386_pkg::RETFPOP13);
		if (selector_in_limit) begin		// selector within bounds?
			if (fnIsReadableCodeOrData(fs_desc)) begin
				// data or non-conforming code?
				if (fs_desc.typ[3]==1'b0 || fs_desc.typ[2]==1'b0)	begin
					if (!(fs_desc.dpl >= cpl || fs_desc.dpl >= cs_desc.dpl))
						fs <= 16'h0;
				end
			end
		end
	end
rf80386_pkg::RETFPOP13:
	begin
		tGoto(rf80386_pkg::IFETCH);
		if (selector_in_limit) begin		// selector within bounds?
			if (fnIsReadableCodeOrData(gs_desc)) begin
				// data or non-conforming code?
				if (gs_desc.typ[3]==1'b0 || gs_desc.typ[2]==1'b0)	begin
					if (!(gs_desc.dpl >= cpl || gs_desc.dpl >= cs_desc.dpl))
						gs <= 16'h0;
				end
			end
		end
	end

