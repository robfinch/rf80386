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
		if (realMode)
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
		cs <= selector;
		eip <= offset;
		tGoto(rf80386_pkg::IFETCH);
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
		if (max_pl <= cgate.dpl) begin
			case({cgate.s,cgate.typ})
			5'b01100:	// CALL gate
				begin
					if (cgate.dpl <= cpl) begin
						eip <= {cgate.offset_hi,cgate.offset_lo};
						selector <= cgate.selector;
						if (cgate.dpl==cpl)
							tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::CALLF14);
						else begin
							cpycnt <= cgate.count;
							tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::CALLF6);
						end
					end
				end
			endcase
		end
	end
rf80386_pkg::CALLF6:
	begin
		if (cpycnt > 5'd0) begin
			ad <= sssp;
			sel <= 16'h000F;	// a word
			tGosub(rf80386_pkg::LOAD,rf80386_pkg::CALLF7);
		end
		else begin
			esp <= esp - {cgate.count,2'd0};
			tGoto(rf80386_pkg::CALLF8);
		end
	end
rf80386_pkg::CALLF7:
	begin
		cpycnt <= cpycnt - 2'd1;
		esp <= esp + 4'd4;
		parmbuf[cpycnt] <= dat[31:0];
		tGoto(rf80386_pkg::CALLF6);
	end
rf80386_pkg::CALLF8:
	begin
		// Load ss:esp from TSS based on privilege level
		ad <= tss_base + 32'd4 + {cgate.dpl,3'b0};
		sel <= 16'h00FF;					// read eight bytes
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::CALLF9);
	end
rf80386_pkg::CALLF9:
	begin
		// Set ss:esp to priv level 0 from tss
		old_ss <= ss;
		old_esp <= esp;
		ss <= dat[47:32];
		esp <= dat[31:0];
		tGoto(rf80386_pkg::CALLF10);
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
		tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH);
	end
