// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
//  DECODER2.v
//  - Extended opcode decoder
//
//=============================================================================

rf80386_pkg::DECODER2:
	begin
		case(ir)
		`MORE1:
			casez(ir2)
			`AAM:
				begin
					wrregs <= 1'b1;
					w <= 1'b1;
					rrr <= 3'd0;
					res <= alu_o;
					sf <= 1'b0;
					zf <= reszb;
					pf <= pres;
					tGoto(rf80386_pkg::IFETCH);
				end
			default: tGoto(rf80386_pkg::IFETCH);
			endcase
		`MORE2:
			casez(ir2)
			`AAD:
				begin
					wrregs <= 1'b1;
					w <= 1'b1;
					rrr <= 3'd0;
					res <= alu_o;
					sf <= 1'b0;
					zf <= reszw;
					pf <= pres;
					tGoto(rf80386_pkg::IFETCH);
				end
			default:	tGoto(rf80386_pkg::IFETCH);
			endcase
		`EXTOP:
			casez(ir2)
			`CLTS:
				begin
					cr0[3] <= 1'b0;
					tGoto(rf80386_pkg::IFETCH);
				end
			`LSL:
				begin
					lsl <= 1'b1;
					tGosub(rf80386_pkg::LAR,rf80386_pkg::IFETCH);
				end
			`LAR:
				begin
					tGosub(rf80386_pkg::LAR,rf80386_pkg::IFETCH);
				end
			`LSS:
				begin
					d_lss <= 1'b1;
					w <= 1'b1;
					mod   <= bundle[7:6];
					rrr   <= bundle[5:3];
					sreg3 <= bundle[5:3];
					TTT   <= bundle[5:3];
					rm    <= bundle[2:0];
					$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
					tGoto(rf80386_pkg::EACALC);
				end
			`LFS:
				begin
					d_lfs <= 1'b1;
					w <= 1'b1;
					mod   <= bundle[7:6];
					rrr   <= bundle[5:3];
					sreg3 <= bundle[5:3];
					TTT   <= bundle[5:3];
					rm    <= bundle[2:0];
					$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
					tGoto(rf80386_pkg::EACALC);
				end
			`LGS:
				begin
					d_lgs <= 1'b1;
					w <= 1'b1;
					mod   <= bundle[7:6];
					rrr   <= bundle[5:3];
					sreg3 <= bundle[5:3];
					TTT   <= bundle[5:3];
					rm    <= bundle[2:0];
					$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
					tGoto(rf80386_pkg::EACALC);
				end
			`BSF,`BSR,`BT,`BTCI,`BTR,`BTS:
				begin
					mod   <= bundle[7:6];
					rrr   <= bundle[5:3];
					sreg3 <= bundle[5:3];
					TTT   <= bundle[5:3];
					rm    <= bundle[2:0];
					$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
					tGoto(rf80386_pkg::EACALC);		// override state transition
				end
			`LxDT:
				begin
					sgdt <= bundle[5:3]==3'h0;
					sidt <= bundle[5:3]==3'h1;
					lgdt <= bundle[5:3]==3'h2;
					lidt <= bundle[5:3]==3'h3;
					smsw <= bundle[5:3]==3'h4;
					lmsw <= bundle[5:3]==3'h6;
					w <= 1'b1;
					mod   <= bundle[7:6];
					rrr   <= bundle[5:3];
					sreg3 <= bundle[5:3];
					TTT   <= bundle[5:3];
					rm    <= bundle[2:0];
					$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
					tGoto(rf80386_pkg::EACALC);		// override state transition
				end
			`LLDT:
				begin
					sldt <= bundle[5:3]==3'h0;
					str <= bundle[5:3]==3'h1;
					ltr <= bundle[5:3]==3'h3;
					verr <= bundle[5:3]==3'h4;
					verw <= bundle[5:3]==3'h5;
					w <= 1'b1;
					mod   <= bundle[7:6];
					rrr   <= bundle[5:3];
					sreg3 <= bundle[5:3];
					TTT   <= bundle[5:3];
					rm    <= bundle[2:0];
					$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
					tGoto(rf80386_pkg::EACALC);		// override state transition
				end
			`BSWAP:
				begin
					tGoto(rf80386_pkg::IFETCH);
					wrregs <= 1'b1;
					w <= 1'b1;
					rrr <= ir[2:0];
					case(ir[2:0])
					3'd0:	res <= {eax[7:0],eax[15:8],eax[23:16],eax[31:24]};
					3'd1:	res <= {ecx[7:0],ecx[15:8],ecx[23:16],ecx[31:24]};
					3'd2:	res <= {edx[7:0],edx[15:8],edx[23:16],edx[31:24]};
					3'd3:	res <= {ebx[7:0],ebx[15:8],ebx[23:16],ebx[31:24]};
					3'd4:	res <= {esp[7:0],esp[15:8],esp[23:16],esp[31:24]};
					3'd5:	res <= {ebp[7:0],ebp[15:8],ebp[23:16],ebp[31:24]};
					3'd6:	res <= {esi[7:0],esi[15:8],esi[23:16],esi[31:24]};
					3'd7:	res <= {edi[7:0],edi[15:8],edi[23:16],edi[31:24]};
					endcase
				end
			`PUSH_FS,`PUSH_GS:
				begin esp <= esp - 4'd2; tGoto(rf80386_pkg::PUSH); end
			`JccL:	
				begin
					ir <= {4'h7,ir2[3:0]};	// for eval_branch
					jccl <= 1'b1;
					tGoto(rf80386_pkg::BRANCH1);
				end
			//-----------------------------------------------------------------
			// Move control register
			//-----------------------------------------------------------------
			`MOV_R2CR,`MOV_CR2R:	
				begin
					w <= 1'b1;
					mod   <= bundle[7:6];
					rrr   <= bundle[5:3];
					sreg3 <= bundle[5:3];
					TTT   <= bundle[5:3];
					rm    <= bundle[2:0];
					$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
					tGoto(rf80386_pkg::EACALC);		// override state transition
				end

			default:	tGoto(rf80386_pkg::IFETCH);
			endcase
		default:	tGoto(rf80386_pkg::IFETCH);
		endcase
	end

