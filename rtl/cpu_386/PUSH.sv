// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  PUSH register to stack
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

rf80386_pkg::PUSH:
	begin
		ad <= sssp;
		// Note SP is predecremented at the decode stage
		if (OperandSize32) begin
			sel <= 16'h000F;
			case(ir)
			`EXTOP:			
				case(ir2)
				`PUSH_FS:	begin dat <= {16'h0,fs}; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
				`PUSH_GS:	begin dat <= {16'h0,gs}; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
				default:	tGoto(rf80386_pkg::RESET);
				endcase
			`PUSH_AX: begin dat <= eax; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_BX: begin dat <= ebx; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_CX: begin dat <= ecx; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_DX: begin dat <= edx; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_SP: begin dat <= esp; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_BP: begin dat <= ebp; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_SI: begin dat <= esi; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_DI: begin dat <= edi; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_CS: begin dat <= {16'h0,cs}; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_DS: begin dat <= {16'h0,ds}; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_SS: begin dat <= {16'h0,ss}; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_ES: begin dat <= {16'h0,es}; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSHF:   begin dat <= flags[31:0]; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSHI:		begin dat <= bundle[31:0]; eip <= eip + 4'd4; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSHI8:	begin dat <= {{24{bundle[7]}},bundle[7:0]}; eip <= eip + 4'd1; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			8'hFF:	begin dat <= ea[31:0]; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			default:	tGoto(rf80386_pkg::RESET);	// only gets here if there's a hardware error
			endcase
		end
		else begin
			sel <= 16'h0003;
			case(ir)
			`EXTOP:			
				case(ir2)
				`PUSH_FS:	begin dat <= fs; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
				`PUSH_GS:	begin dat <= gs; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
				default:	tGoto(rf80386_pkg::RESET);
				endcase
			`PUSH_AX: begin dat <= ax; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_BX: begin dat <= bx; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_CX: begin dat <= cx; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_DX: begin dat <= dx; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_SP: begin dat <= sp; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_BP: begin dat <= bp; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_SI: begin dat <= si; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_DI: begin dat <= di; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_CS: begin dat <= cs; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_DS: begin dat <= ds; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_SS: begin dat <= ss; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSH_ES: begin dat <= es; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSHF:   begin dat <= flags[15:0]; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSHI:		begin dat <= bundle[15:0]; eip <= eip + 4'd2; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			`PUSHI8:	begin dat <= {{8{bundle[7]}},bundle[7:0]}; eip <= eip + 4'd1; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			8'hFF:	begin dat <= ea[15:0]; tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH); end
			default:	tGoto(rf80386_pkg::RESET);	// only gets here if there's a hardware error
			endcase
		end
	end
