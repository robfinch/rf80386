// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  RETPOP
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
//  RETPOP: near return from subroutine and pop stack items
//  Fetch ip from stack
// ============================================================================

rf80386_pkg::RETPOP:
	begin
		ad <= sssp;
		sel <= OperandSize32 ? 16'h000F : 16'h0003;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::RETPOP_NACK);
	end
rf80386_pkg::RETPOP_NACK:
	begin
		if (OperandSize32) begin
			if (realMode|v86)
				esp[15:0] <= esp + 4'd4;
			else
				esp <= esp + 4'd4;
			eip <= dat[31:0];
		end
		else begin
			if (realMode|v86)
				esp[15:0] <= esp + 4'd2;
			else
				esp <= esp + 4'd2;
			eip <= dat[15:0];
		end
		tGoto(rf80386_pkg::RETPOP1);
	end
rf80386_pkg::RETPOP1:
	begin
		tGoto(rf80386_pkg::IFETCH);
		if (ir==`RETPOP) begin
			wrregs <= 1'b1;
			w <= 1'b1;
			rrr <= 3'd4;
			if (OperandSize32)
				res <= esp + {bundle[15:0],1'b0};
			else
				res <= esp + bundle[15:0];
		end
	end
