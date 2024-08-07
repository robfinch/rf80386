// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  STOSB,STOSW
//  Store string data to memory.
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

rf80386_pkg::STOS:
`include "check_for_ints.sv"
	else if (repdone)
		tGoto(rf80386_pkg::IFETCH);
	else if (w && (AddrSize==8'd32 ? edi==32'hFFFFFFFF : di==16'hFFFF)) begin
		ir <= `NOP;
		tGoInt(8'd13);
	end
	else begin
		ad <= esdi;
		dat <= eax;
		if (OperandSize32) begin
			sel <= w ? 16'h000F : 16'h0001;
		end
		else begin
			sel <= w ? 16'h0003 : 16'h0001;
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::STOS1);
	end
rf80386_pkg::STOS1:
	begin
		if (repz|repnz) begin
			tGoto(rf80386_pkg::STOS);
			ecx <= cx_dec;
			insn_count <= insn_count + 2'd1;
		end
		else
			tGoto(rf80386_pkg::IFETCH);
		if ((repz|repnz) ? !cxz : 1'b1) begin
			if (w) begin
				if (OperandSize32) begin
					if (df)
						tUedi(edi - 4'd4);
					else
					 	tUedi(edi + 4'd4);
				end
				else begin
					if (df)
						tUedi(edi - 2'd2);
					else
					 	tUedi(edi + 2'd2);
				end
			end
			else begin
				if (df)
					tUedi(edi - 2'd1);
				else
				 	tUedi(edi + 2'd1);
			end
		end
	end
