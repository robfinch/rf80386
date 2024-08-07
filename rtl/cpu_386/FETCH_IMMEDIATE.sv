// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  FETCH_IMM16
//  - fetch 16 bit immediate from instruction stream as operand 'B'
//  FETCH_IMM8
//  - Fetch 8 bit immediate as operand 'B'
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
//
//  System Verilog 
//
// - bus is locked if immediate value is unaligned in memory
// - immediate values are the last operand to be fetched, hence
//   the state machine can transition into the EXECUTE state.
// - we also know the immediate value can't be the target of an
//   operation.
// ============================================================================

rf80386_pkg::FETCH_IMM8:
	begin
		if (ir==`SHI8 || ir==`SHI16) begin
			shftamt <= bundle[4:0];
			b <= a;
		end
		else begin
			case(ir)
			`ALU_I2R8:
				begin
					a <= rmo;
				end
			`ALU_I2R16:
				begin
					a <= rmo;
				end
			`ALU_I82R8:
				begin
					a <= rmo;
				end
			`ALU_I82R16:
				begin
					a <= rmo;
				end
			default:	;
			endcase
			b <= {{24{bundle[7]}},bundle[7:0]};
		end
		bundle <= bundle[127:8];
		eip <= eip + 2'd1;
		tGoto(rf80386_pkg::EXECUTE);
	end

rf80386_pkg::FETCH_IMM16:
	begin
		if (!hasFetchedData)
		case(ir)
		`ALU_I2R8:
			begin
				a <= rmo;
			end
		`ALU_I2R16:
			begin
				a <= rmo;
			end
		`ALU_I82R8:
			begin
				a <= rmo;
			end
		`ALU_I82R16:
			begin
				a <= rmo;
			end
		default:	;
		endcase

		if (OperandSize32) begin
			b <= bundle[31:0];
			bundle <= bundle[127:32];
			eip <= eip + 4'd4;
		end
		else begin
			b <= {{16{bundle[15]}},bundle[15:0]};
			bundle <= bundle[127:16];
			eip <= eip + 4'd2;
		end
		$display("Fetched #%h", bundle[15:0]);
		tGoto(rf80386_pkg::EXECUTE);
	end

