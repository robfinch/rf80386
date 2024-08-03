// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  CALL FAR and CALL FAR indirect
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

rf80386_pkg::CALLF:
	begin
		old_cs <= cs;
		old_eip <= eip;
		if (realMode || v86)
			tGoto(rf80386_pkg::CALLF_RMD1);
		else
			tGoto(rf80386_pkg::CALLF1);
	end
rf80386_pkg::CALLF_RMD1:
	begin
		if (StkAddrSize==8'd32)
			esp <= esp - 4'd2;
		else
			esp[15:0] <= esp - 4'd2;
		tGoto(rf80386_pkg::CALLF_RMD2);
	end
rf80386_pkg::CALLF_RMD2:
	begin
		ad <= sssp;
		dat <= cs;
		sel <= 16'h0003;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF_RMD3);
	end
rf80386_pkg::CALLF_RMD3:
	begin
		if (StkAddrSize==8'd32) begin
			if (OperandSize32)
				esp <= esp - 4'd4;
			else
				esp <= esp - 4'd2;
		end
		else begin
			if (OperandSize32)
				esp[15:0] <= esp - 4'd4;
			else
				esp[15:0] <= esp - 4'd2;
		end
		tGoto(rf80386_pkg::CALLF_RMD4);
	end
rf80386_pkg::CALLF_RMD4:
	begin
		ad <= sssp;
		dat <= eip;
		if (OperandSize32)
			sel <= 16'h000F;
		else
			sel <= 16'h0003;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF_RMD5);
	end
rf80386_pkg::CALLF_RMD5:
	begin
		if (ir==8'hFF && rrr==3'b011)	// CALL FAR indirect
			tGoto(rf80386_pkg::JUMP_VECTOR1);
		else begin
			cs <= selector;
			eip <= offset;
			tGoto(rf80386_pkg::IFETCH);
		end
	end

rf80386_pkg::CALLF1:
	begin
		tGosub(rf80386_pkg::LOAD_GATE,rf80386_pkg::CALLF2);
	end
rf80386_pkg::CALLF2:
	begin
		// Default to general protection fault. It will be overridden if things
		// work.
		int_num = 8'd13;					// GP fault
		tGoto(rf80386_pkg::INT2);
		if (cgate.selector[15:2] != 14'h0) begin	// target selector cannot be NULL
			if (!cgate.p)
				int_num = 8'd11;						// segment not present
			if (max_pl <= cgate.dpl) begin
				casez({cgate.s,cgate.typ})
				5'b00011,	// busy 286 task
				5'b01011:	// busy 386 task
					int_num = 8'd10;					// invalid TSS
				5'b00101:	// task gate
					if (cgate.dpl < cpl || cgate.dpl < selector[1:0])
						int_num = 8'd10;					// invalid TSS
					else if (!cgate.p)
						int_num = 8'd11;					// segment not present
					else if (tgate.selector[2]!=1'b0)	// must be global
						int_num = 8'd10;					// invalid TSS
					else if (!fnSelectorInLimit(tgate.selector))						
						int_num = 8'd10;					// invalid TSS
					else
						tGoto(rf80386_pkg::TASK_SWITCH);
				5'b110??:	// non-conforming code segment
					begin
						if (selector[1:0] <= cpl && cdesc.p) begin
							if (cdesc.dpl == cpl) begin
								if (esp < ss_limit - 4'd8) begin
									if (eip < (cdesc.g ? {cdesc.limit_hi,cdesc.limit_lo,12'h0} : {12'h0,cdesc.limit_hi,cdesc.limit_lo})) begin
										cs <= selector;
										cs[1:0] <= cpl;
										if (OperandSize32)
											eip <= offset;
										else
											eip <= offset & 32'h0ffff;
										tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::IFETCH);
									end
								end
							end
						end
					end
				5'b111??:	// conforming code segment
					begin
						if (cgate.dpl <= cpl && cgate.p) begin
							if (esp < ss_limit - 4'd8) begin
								if (eip < (cdesc.g ? {cdesc.limit_hi,cdesc.limit_lo,12'h0} : {12'h0,cdesc.limit_hi,cdesc.limit_lo})) begin
									cs <= selector;
									if (OperandSize32)
										eip <= offset;
									else
										eip <= offset & 32'h0ffff;
									tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::IFETCH);
								end
							end
						end
					end
				5'b01100:	// CALL gate
					begin
						if (cgate.dpl >= cpl) begin
							if (cgate.dpl >= selector[1:0] && cgate.p) begin
								if (|cgate.selector[15:2] && fnSelectorInLimit(cgate.selector)) begin	// selector must be non-null and within limits
									eip <= {cgate.offset_hi,cgate.offset_lo};
									selector <= cgate.selector;
									if (cgate.dpl < cpl && !cgate.typ[2])	begin // non-conforming and dpl < cpl  (increasing priv)
										cpycnt <= cgate.count;
										tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::CALLF6);
									end
									else
										tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::CALLF20);	// staying at the same priv
								end
							end
						end
					end
				default:	;
				endcase
			end
		end
	end
rf80386_pkg::CALLF6:
	begin
		if (cs_desc.dpl > cpl) begin
			int_num <= 8'd13;
			tGoto(rf80386_pkg::INT2);
		end
		else begin
			// Load ss:esp from TSS based on privilege level
			ad <= tss_base + 32'd4 + {cgate.dpl,3'b0};
			sel <= 16'h00FF;					// read eight bytes
			tGosub(rf80386_pkg::LOAD,rf80386_pkg::CALLF7);
		end
	end
rf80386_pkg::CALLF7:
	begin
		// Set ss:esp to priv level 0 from tss
		old_ss <= ss;
		old_esp <= esp;
		new_ss <= dat[47:32];
		new_esp <= dat[31:0];
		selector <= dat[47:32];
		tGosub(rf80386_pkg::LOAD_SS_DESC,rf80386_pkg::CALLF8);
	end
rf80386_pkg::CALLF8:
	begin
		// not writeable data segment
		if (new_ss[15:2]==14'h0 || !fnSelectorInLimit(new_ss) || new_ss[1:0] != cs_desc.dpl || ss_desc.s==1'b0 || ss_desc.typ[3] || ss_desc[1]==1'b0) begin
			int_num <= 8'd10;	// invalid TSS
			tGoto(rf80386_pkg::INT2);
		end
		else if (!ss_desc.p) begin
			int_num <= 8'd12;	// stack exception
			tGoto(rf80386_pkg::INT2);
		end
		else if ((OperandSize32 && new_esp > ss_limit - 8'd16 + {cgate.count,2'b0}) || eip > cs_limit) begin
			int_num <= eip > cs_limit ? 8'd13 : 8'd12;
			tGoto(rf80386_pkg::INT2);
		end
		else if ((!OperandSize32 && new_esp > ss_limit - 8'd8 + {cgate.count,2'b0}) || {16'h0,eip[15:0]} > cs_limit) begin
			int_num <= {16'h0,eip[15:0]} > cs_limit ? 8'd13 : 8'd12;
			tGoto(rf80386_pkg::INT2);
		end
		else if (cpycnt > 5'd0) begin
			ad <= sssp;
			sel <= 16'h000F;	// a word
			tGosub(rf80386_pkg::LOAD,rf80386_pkg::CALLF9);
		end
		else begin
			esp <= esp - {cgate.count,2'd0};
			esp <= new_esp;
			ss <= new_ss;
			cpl <= ss_desc.dpl;
			cs[1:0] <= ss_desc.dpl;
			tGoto(rf80386_pkg::CALLF10);
		end
	end
rf80386_pkg::CALLF9:
	begin
		cpycnt <= cpycnt - 2'd1;
		esp <= esp + 4'd4;
		parmbuf[cpycnt] <= dat[31:0];
		tGoto(rf80386_pkg::CALLF8);
	end
rf80386_pkg::CALLF10:
	begin
		if (StkAddrSize==8'd32)
			esp <= esp - 4'd4;
		else
			esp[15:0] <= esp - 4'd4;
		tGoto(rf80386_pkg::CALLF11);
	end
rf80386_pkg::CALLF11:
	begin
		ad <= sssp;
		dat <= old_ss;
		sel <= 16'h0003;
		if (StkAddrSize==8'd32)
			esp <= esp - 4'd4;
		else
			esp[15:0] <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF12);
	end
rf80386_pkg::CALLF12:
	begin
		ad <= sssp;
		dat <= old_esp;
		sel <= 16'h000F;
		cpycnt <= cgate.count;
		if (StkAddrSize==8'd32)
			esp <= esp - 4'd4;
		else
			esp[15:0] <= esp - 4'd4;
		if (cgate.count > 5'd0)
			tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF13);
		else
			tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF14);
	end
rf80386_pkg::CALLF13:
	begin
		if (cpycnt > 5'd0) begin
			ad <= sssp;
			sel <= 16'h000F;
			dat <= parmbuf[cpycnt];
			if (StkAddrSize==8'd32)
				esp <= esp - 4'd4;
			else
				esp[15:0] <= esp - 4'd4;
			tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF13);
			cpycnt <= cpycnt - 2'd1;
		end
		else
			tGoto(rf80386_pkg::CALLF14);
	end
rf80386_pkg::CALLF14:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_cs;
		if (StkAddrSize==8'd32)
			esp <= esp - 4'd4;
		else
			esp[15:0] <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF15);
	end
rf80386_pkg::CALLF15:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_eip;
		if (StkAddrSize==8'd32)
			esp <= esp - 4'd4;
		else
			esp[15:0] <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF16);
	end
rf80386_pkg::CALLF16:
	begin
		if (ir==8'hFF && rrr==3'b011)	// CALL FAR indirect
			tGoto(rf80386_pkg::JUMP_VECTOR1);
		else
			tGoto(rf80386_pkg::IFETCH);
	end

// Call at same privilege level
rf80386_pkg::CALLF20:
	begin
		if (cs_desc.dpl > cpl) begin
			int_num <= 8'd13;
			tGoto(rf80386_pkg::INT2);
		end
		else if (OperandSize32 && esp > ss_limit - 4'd6) begin
			int_num <= 8'd12;
			tGoto(rf80386_pkg::INT2);
		end
		else if (OperandSize32 && eip > cs_limit) begin
			int_num <= 8'd13;
			tGoto(rf80386_pkg::INT2);
		end
		else if (!OperandSize32 && esp > ss_limit - 4'd4) begin
			int_num <= 8'd12;
			tGoto(rf80386_pkg::INT2);
		end
		else if (!OperandSize32 && {16'h0,eip[15:0]} > cs_limit) begin
			int_num <= 8'd13;
			tGoto(rf80386_pkg::INT2);
		end
		else begin
			ad <= sssp;
			sel <= 16'h000F;
			dat <= old_cs;
			if (StkAddrSize==8'd32)
				esp <= esp - 4'd4;
			else
				esp[15:0] <= esp - 4'd4;
			tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF21);
		end
	end
rf80386_pkg::CALLF21:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= old_eip;
		if (StkAddrSize==8'd32)
			esp <= esp - 4'd4;
		else
			esp[15:0] <= esp - 4'd4;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::CALLF22);
	end
rf80386_pkg::CALLF22:
	begin
		cs[1:0] <= cpl;
		if (ir==8'hFF && rrr==3'b011)	// CALL FAR indirect
			tGoto(rf80386_pkg::JUMP_VECTOR1);
		else
			tGoto(rf80386_pkg::IFETCH);
	end
