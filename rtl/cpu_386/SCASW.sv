// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  SCASW
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

rf80386_pkg::SCASW:
`include "check_for_ints.sv"
	else if (w && (AddrSize==8'd32 ? edi==32'hFFFFFFFF : di==16'hFFFF) && !df) begin
		ir <= `NOP;
		tGoInt(8'd13);
	end
	else if ((repz|repnz) & cxz)
		tGoto(rf80386_pkg::IFETCH);
	else begin
		ad <= esdi;
		sel <= OperandSize32 ? 16'h000F : 16'h0003;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::SCASW1);
	end
rf80386_pkg::SCASW1:
	begin
		tGoto(rf80386_pkg::SCASW2);
		a <= OperandSize32 ? eax : ax;
		b <= OperandSize32 ? dat[31:0] : {16'h0,dat[15:0]};
		if ((repz|repnz) ? !cxz : 1'b1) begin
			if (df)
				tUedi(OperandSize32 ? edi - 4'd4 : edi - 4'd2);
			else
				tUedi(OperandSize32 ? edi + 4'd4 : edi + 4'd2);
		end
	end
rf80386_pkg::SCASW2:
	begin
		pf <= pres;
		af <= carry   (1'b0,a[3],b[3],alu_o[3]);
		if (OperandSize32) begin
			cf <= carry   (1'b0,a[31],b[31],alu_o[31]);
			vf <= overflow(1'b0,a[31],b[31],alu_o[31]);
		end
		else begin
			cf <= carry   (1'b0,a[15],b[15],alu_o[15]);
			vf <= overflow(1'b0,a[15],b[15],alu_o[15]);
		end
		sf <= resnw;
		zf <= reszw;
		if (repz|repnz)
			ecx <= cx_dec;
		if ((repz & reszw) | (repnz & !reszw)) begin
			tGoto(rf80386_pkg::SCASW);
			insn_count <= insn_count + 2'd1;
		end
		else
			tGoto(rf80386_pkg::IFETCH);
	end
