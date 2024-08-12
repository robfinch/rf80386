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
		tUsp(OperandSize32 ? esp + 4'd8 : esp + 4'd4);
		if (OperandSize32) begin
			sel <= 16'h00FF;
		end
		else begin
			sel <= 16'h000F;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::RETFPOP_RMD2);
	end
rf80386_pkg::RETFPOP_RMD2:
	begin
		if (OperandSize32)
			{selector,neip[31:0]} <= dat[47:0];
		else begin
			{selector,neip[15:0]} <= dat[31:0];
			neip[31:16] <= 16'h0;
		end
		tGoto(rf80386_pkg::RETFPOP_RMD3);
	end
rf80386_pkg::RETFPOP_RMD3:
	begin
		if (ir==`RETFPOP)
			tUsp(OperandSize32 ? esp + {bundle[15:0],1'b0} : esp + bundle[15:0]);
		cs <= selector;
		eip <= neip;
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
		{selector,neip} <= dat[47:0];
		tGoto(rf80386_pkg::RETFPOP3);
	end
rf80386_pkg::RETFPOP3:
	begin
		if (selector[15:2]==14'h0)				// selector null?
			tError(8'd13,selector&16'hFFFC,1'b1);
		else if (!selector_in_limit)			// selector within bounds?
			tError(8'd13,selector&16'hFFFC,1'b1);
		else begin
			if (selector.rpl >= cpl) begin// Check return priv. level
				old_cs <= cs;
				if (cs != selector)
					tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::RETFPOP4);
				else
					tGoto(rf80386_pkg::RETFPOP4);
			end
		end
	end
rf80386_pkg::RETFPOP4:
	begin
		eip <= neip;
		cs <= selector;
		if (!cs_desc.p)			// segment present?
			tError(8'd11,selector&16'hFFFC,1'b1);	// segment not present
		else if (!cs_desc.s || !cs_desc.typ[3])	// executable segment
			tError(8'd13,selector&16'hFFFC,1'b1);
		else if ((cs_desc.typ[1] && cs_desc.dpl <= cpl) || cs_desc.dpl==cpl)	begin		// conforming?, or non-conforming and cpl match
			if (selector.rpl==cpl)
				tGoto(rf80386_pkg::RETFPOP_SAME_LEVEL);
			else
				tGoto(rf80386_pkg::RETFPOP_OUTER_LEVEL);
		end
		else
			tError(8'd13,selector&16'hFFFC,1'b1);
	end
rf80386_pkg::RETFPOP_SAME_LEVEL:
	begin
		if (esp > ss_limit)
			tError(8'd12,ss&16'hFFFC,1'b1);	// stack exception
		else if (eip > cs_limit)
			tError(8'd13,cs&16'hFFFC,1'b1);	// general protection fault
		else begin
			ad <= sssp;
			tUsp(OperandSize32 ? esp + 4'd8 : esp + 4'd4);
			if (OperandSize32) begin
				sel <= 16'h00FF;
			end
			else begin
				sel <= 16'h000F;
			end
			tGosub(rf80386_pkg::LOAD,rf80386_pkg::RETFPOP5);
		end
	end

rf80386_pkg::RETFPOP5:
	begin
		if (ir==`RETFPOP)
			tUsp(OperandSize32 ? esp + {bundle[15:0],1'b0} : esp + bundle[15:0]);
		tGoto(rf80386_pkg::IFETCH);
	end

rf80386_pkg::RETFPOP_OUTER_LEVEL:
	begin
		if (ir==`RETFPOP) begin
			if (OperandSize32 && esp + 32'd16 + {bundle[15:0],1'b0} > ss_limit)
				tError(8'd12,ss&16'hFFFC,1'b1);		// stack exception
			else if (esp + 32'd8 + {bundle[15:0]} > ss_limit)
				tError(8'd12,ss&16'hFFFC,1'b1);		// stack exception
			else begin
				tUsp(OperandSize32 ? esp + {bundle[15:0],1'b0} : esp + bundle[15:0]);
				tGoto(rf80386_pkg::RETFPOP6);
			end
		end
		else begin
			if (OperandSize32 && esp + 32'd16 > ss_limit)
				tError(8'd12,ss&16'hFFFC,1'b1);		// stack exception
			else if (esp + 32'd8 > ss_limit)
				tError(8'd12,ss&16'hFFFC,1'b1);		// stack exception
			else
				tGoto(rf80386_pkg::RETFPOP6);
		end
	end
// Pop old SS:ESP
rf80386_pkg::RETFPOP6:
	begin
		ad <= sssp;
		sel <= 16'h00FF;
		tUsp(esp + 4'd8);
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
		tUsp(OperandSize32 ? esp + {bundle[15:0],1'b0} + 4'd8: esp + bundle[15:0] + 4'd8);
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

