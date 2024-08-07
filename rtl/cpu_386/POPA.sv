// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  POPA pop all registers from stack
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

rf80386_pkg::POPA:
	begin
		ad <= sssp;
		if (OperandSize32) begin
			sel <= 16'h000F;
			esp <= esp + 4'd4;
		end
		else begin
			sel <= 16'h0003;
			esp <= esp + 4'd2;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::POPA1);
	end
rf80386_pkg::POPA1:
	begin
		if (OperandSize32)
			edi <= dat[31:0];
		else
			edi[15:0] <= dat[15:0];
		ad <= sssp;
		if (OperandSize32) begin
			sel <= 16'h000F;
			esp <= esp + 4'd4;
		end
		else begin
			sel <= 16'h0003;
			esp <= esp + 4'd2;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::POPA2);
	end
rf80386_pkg::POPA2:
	begin
		if (OperandSize32)
			esi <= dat[31:0];
		else
			esi[15:0] <= dat[15:0];
		ad <= sssp;
		if (OperandSize32) begin
			sel <= 16'h000F;
			esp <= esp + 4'd4;
		end
		else begin
			sel <= 16'h0003;
			esp <= esp + 4'd2;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::POPA3);
	end
rf80386_pkg::POPA3:
	begin
		if (OperandSize32)
			ebp <= dat[31:0];
		else
			ebp[15:0] <= dat[15:0];
		ad <= sssp;
		if (OperandSize32) begin
			sel <= 16'h000F;
			esp <= esp + 4'd4;
		end
		else begin
			sel <= 16'h0003;
			esp <= esp + 4'd2;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::POPA4);
	end
rf80386_pkg::POPA4:
	begin
		if (OperandSize32)
			eax <= dat[31:0];
		else
			eax[15:0] <= dat[15:0];
		ad <= sssp;
		if (OperandSize32) begin
			sel <= 16'h000F;
			esp <= esp + 4'd4;
		end
		else begin
			sel <= 16'h0003;
			esp <= esp + 4'd2;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::POPA5);
	end
rf80386_pkg::POPA5:
	begin
		if (OperandSize32)
			ebx <= dat[31:0];
		else
			ebx[15:0] <= dat[15:0];
		ad <= sssp;
		if (OperandSize32) begin
			sel <= 16'h000F;
			esp <= esp + 4'd4;
		end
		else begin
			sel <= 16'h0003;
			esp <= esp + 4'd2;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::POPA6);
	end
rf80386_pkg::POPA6:
	begin
		if (OperandSize32)
			edx <= dat[31:0];
		else
			edx[15:0] <= dat[15:0];
		ad <= sssp;
		if (OperandSize32) begin
			sel <= 16'h000F;
			esp <= esp + 4'd4;
		end
		else begin
			sel <= 16'h0003;
			esp <= esp + 4'd2;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::POPA7);
	end
rf80386_pkg::POPA7:
	begin
		if (OperandSize32)
			ecx <= dat[31:0];
		else
			ecx[15:0] <= dat[15:0];
		ad <= sssp;
		if (OperandSize32) begin
			sel <= 16'h000F;
			esp <= esp + 4'd4;
		end
		else begin
			sel <= 16'h0003;
			esp <= esp + 4'd2;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::POPA8);
	end
rf80386_pkg::POPA8:
	begin
		if (OperandSize32)
			eax <= dat[31:0];
		else
			eax[15:0] <= dat[15:0];
		tGoto(rf80386_pkg::IFETCH);
	end
