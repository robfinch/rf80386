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
//  EACALC
//  - calculation of effective address
//
// - the effective address calculation may need to fetch an additional
//   eight or sixteen bit displacement value in order to calculate the
//   effective address.
// - the EA calc only needs to be done once as there is only ever a 
//   single memory operand address. Once the EA is calculated it is
//   used for both the fetch and the store when memory is the target.
// ============================================================================
//
rf80386_pkg::EACALC:
	begin

		disp32 <= 32'h0000;
		
		// Absorb mod/rm
		bundle <= bundle[127:8];
		eip <= ip_inc;

		case(mod)

		2'b00:
			begin
				tGoto(rf80386_pkg::EACALC1);
				// ToDo: error on stack state
				if (realMode) begin
					casez({AddrSize==8'd32,rm})
					4'b0000:	offset <= {16'h0,bx + si};
					4'b0001:	offset <= {16'h0,bx + di};
					4'b0010:	offset <= {16'h0,bp + si};
					4'b0011:	offset <= {16'h0,bp + di};
					4'b0100:	offset <= {16'h0,si};
					4'b0101:	offset <= {16'h0,di};
					4'b0110:	
						begin
							tGoto(rf80386_pkg::EACALC_DISP16);
							offset <= 32'h0000;
						end
					4'b0111:	offset <= {16'h0,bx};
					4'd8:	offset <= eax;
					4'd9:	offset <= ecx;
					4'd10:	offset <= edx;
					4'd11:	offset <= ebx;
					4'd12:
						begin
							tGoto(rf80386_pkg::EACALC_SIB);
							offset <= 32'h0000;
						end
					4'd13:
						begin
							tGoto(rf80386_pkg::EACALC_DISP16);
							offset <= 32'h0000;
						end
					4'd14:	offset <= esi;
					4'd15:	offset <= edi;
					/*
					4'b1000:	offset <= {ebx + esi};
					4'b1001:	offset <= {ebx + edi};
					4'b1010:	offset <= {ebp + esi};
					4'b1011:	offset <= {ebp + edi};
					4'b1100:	offset <= esi;
					4'b1101:	offset <= edi;
					4'b1110:	
						begin
							tGoto(rf80386_pkg::EACALC_DISP16);
							offset <= 32'h0000;
						end
					4'b1111:	offset <= ebx;
					*/
					endcase
				end
				else begin
					casez({AddrSize==8'd32,rm})
					4'd0:	offset <= {16'h0,ax};
					4'd1:	offset <= {16'h0,cx};
					4'd2:	offset <= {16'h0,dx};
					4'd3:	offset <= {16'h0,bx};
					4'd4:	
						begin
							tGoto(rf80386_pkg::EACALC_SIB);
							offset <= 32'h0000;
						end
					4'd5:
						begin
							tGoto(rf80386_pkg::EACALC_DISP16);
							offset <= 32'h0000;
						end
					4'd6:	offset <= {16'h0,si};
					4'd7:	offset <= {16'h0,di};
					4'd8:	offset <= eax;
					4'd9:	offset <= ecx;
					4'd10:	offset <= edx;
					4'd11:	offset <= ebx;
					4'd12:
						begin
							tGoto(rf80386_pkg::EACALC_SIB);
							offset <= 32'h0000;
						end
					4'd13:
						begin
							tGoto(rf80386_pkg::EACALC_DISP16);
							offset <= 32'h0000;
						end
					4'd14:	offset <= esi;
					4'd15:	offset <= edi;
					endcase
				end
			end

		2'b01:
			begin
				tGoto(rf80386_pkg::EACALC_DISP8);
				if (realMode) begin
					case({AddrSize==8'd32,rm})
					4'd0:	offset <= bx + si;
					4'd1:	offset <= bx + di;
					4'd2:	offset <= bp + si;
					4'd3:	offset <= bp + di;
					4'd4:	offset <= si;
					4'd5:	offset <= di;
					4'd6:	offset <= bp;
					4'd7:	offset <= bx;
					4'd8:	offset <= ebx + esi;
					4'd9:	offset <= ebx + edi;
					4'd10:	offset <= ebp + esi;
					4'd11:	offset <= ebp + edi;
					4'd12:	offset <= esi;
					4'd13:	offset <= edi;
					4'd14:	offset <= ebp;
					4'd15:	offset <= ebx;
					endcase
				end
				else begin
					case({AddrSize==8'd32,rm})
					4'd0:	offset <= bx + si;
					4'd1:	offset <= bx + di;
					4'd2:	offset <= bp + si;
					4'd3:	offset <= bp + di;
					4'd4:	offset <= si;
					4'd5:	offset <= di;
					4'd6:	offset <= bp;
					4'd7:	offset <= bx;
					4'd8:	offset <= eax;
					4'd9:	offset <= ecx;
					4'd10:	offset <= edx;
					4'd11:	offset <= ebx;
					4'd12:
						begin
							tGoto(rf80386_pkg::EACALC_SIB);
							offset <= 32'h0000;
						end
					4'd13:	offset <= ebp;
					4'd14:	offset <= esi;
					4'd15:	offset <= edi;
					endcase
				end
			end

		2'b10:
			begin
				tGoto(rf80386_pkg::EACALC_DISP16);
				if (realMode) begin
					case({AddrSize==8'd32,rm})
					4'd0:	offset <= bx + si;
					4'd1:	offset <= bx + di;
					4'd2:	offset <= bp + si;
					4'd3:	offset <= bp + di;
					4'd4:	offset <= si;
					4'd5:	offset <= di;
					4'd6:	offset <= bp;
					4'd7:	offset <= bx;
					4'd8:	offset <= ebx + esi;
					4'd9:	offset <= ebx + edi;
					4'd10:	offset <= ebp + esi;
					4'd11:	offset <= ebp + edi;
					4'd12:	offset <= esi;
					4'd13:	offset <= edi;
					4'd14:	offset <= ebp;
					4'd15:	offset <= ebx;
					endcase
				end
				else begin
					case({AddrSize==8'd32,rm})
					4'd0:	offset <= bx + si;
					4'd1:	offset <= bx + di;
					4'd2:	offset <= bp + si;
					4'd3:	offset <= bp + di;
					4'd4:	offset <= si;
					4'd5:	offset <= di;
					4'd6:	offset <= bp;
					4'd7:	offset <= bx;
					4'd8:	offset <= eax;
					4'd9:	offset <= ecx;
					4'd10:	offset <= edx;
					4'd11:	offset <= ebx;
					4'd12:
						begin
							tGoto(rf80386_pkg::EACALC_SIB);
							offset <= 32'h0000;
						end
					4'd13:	offset <= ebp;
					4'd14:	offset <= esi;
					4'd15:	offset <= edi;
					endcase
				end
			end

		2'b11:
			begin
				tGoto(rf80386_pkg::EXECUTE);
				casez(ir)
				`EXTOP:
					case(ir2)
					`MOV_R2CR:
						begin
							a <= rmo;
						end
					default:
					  begin
							// d=1 value goes to register, d=0 value comes from reg.
							if (~d) begin
								a <= rmo;
								b <= rrro;
								rrr <= rm;
							end
							else begin
								a <= rrro;
								b <= rmo;
							end
						end
					endcase
				`SHI8,`SHI16,
				`ALU_I2R8:
					begin
						a <= rmo;
						tGoto(rf80386_pkg::FETCH_IMM8);
					end
				`ALU_I2R16:
					begin
						a <= rmo;
						tGoto(rf80386_pkg::FETCH_IMM16);
					end
				`ALU_I82R8:
					begin
						a <= rmo;
						tGoto(rf80386_pkg::FETCH_IMM8);
					end
				`ALU_I82R16:
					begin
						a <= rmo;
						tGoto(rf80386_pkg::FETCH_IMM8);
					end
				`MOV_I8M:
					begin
						rrr <= rm;
						if (rrr==3'd0) tGoto(rf80386_pkg::FETCH_IMM8);
					end
				`MOV_I16M:
					begin
						rrr <= rm;
						if (rrr==3'd0) tGoto(rf80386_pkg::FETCH_IMM16);
					end
				`MOV_S2R:
					begin
						a <= rfso;
						b <= rfso;
					end
				`MOV_R2S:
					begin
						a <= rmo;
						b <= rmo;
					end
				`POP_MEM:
					begin
						ir <= 8'h58|rm;
						tGoto(POP);
					end
				`XCHG_MEM:
					begin
						wrregs <= 1'b1;
						res <= rmo;
						b <= rrro;
					end
				// shifts and rotates
				8'hD0,8'hD1,8'hD2,8'hD3:
					begin
						b <= rmo;
					end
				// The TEST instruction is the only one needing to fetch an immediate value.
				8'hF6,8'hF7:
					// 000 = TEST
					// 010 = NOT
					// 011 = NEG
					// 100 = MUL
					// 101 = IMUL
					// 110 = DIV
					// 111 = IDIV
					begin
						if (rrr==3'b000) begin	// TEST
							a <= rmo;
							tGoto(w ? rf80386_pkg::FETCH_IMM16 : rf80386_pkg::FETCH_IMM8);
						end
						else begin
							a <= eax;
							b <= rmo;
						end
					end
				`CMP:
					begin
						if (~d) begin
							a <= rmo;
							b <= rrro;
						end
						else begin
							a <= rrro;
							b <= rmo;
						end
					end
				default:
				  begin
						// d=1 value goes to register, d=0 value comes from reg.
						if (~d) begin
							a <= rmo;
							b <= rrro;
							rrr <= rm;
						end
						else begin
							a <= rrro;
							b <= rmo;
						end
					end
				endcase
				hasFetchedData <= 1'b1;
			end
		endcase
	end

rf80386_pkg::EACALC_SIB:
	begin
		sib <= bundle[7:0];
		bundle <= bundle[127:8];
		eip <= ip_inc;
		tGoto(rf80386_pkg::EACALC_SIB1);
	end
rf80386_pkg::EACALC_SIB1:
	begin
		offset <= sndx;
		case(mod)
		2'b00:	tGoto(rf80386_pkg::EACALC1);
		2'b01:	tGoto(rf80386_pkg::EACALC_DISP8);
		2'b10:	tGoto(rf80386_pkg::EACALC_DISP16);
		2'b11:	tGoto(rf80386_pkg::RESET);	// Should not be able to get here
		endcase
	end

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Fetch 16 bit displacement
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

rf80386_pkg::EACALC_DISP16:
	begin
		disp32[15:0] <= bundle[15:0];
		if (AddrSize==8'd32) begin
			disp32[31:16] <= bundle[31:16];
			bundle <= bundle[127:32];
			eip <= eip + 4'd4;
		end
		else begin
			disp32[31:16] <= {16{bundle[15]}};
			bundle <= bundle[127:16];
			eip <= eip + 4'd2;
		end
		tGoto(rf80386_pkg::EACALC1);
	end

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Fetch 8 bit displacement
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

rf80386_pkg::EACALC_DISP8:
	begin
		disp32 <= {{24{bundle[7]}},bundle[7:0]};
		bundle <= bundle[127:8];
		eip <= ip_inc;
		tGoto(rf80386_pkg::EACALC1);
	end


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Add the displacement into the effective address
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

rf80386_pkg::EACALC1:
	begin
		casez(ir)
		`EXTOP:
			casez(ir2)
			`LSS,`LFS,`LGS:
				begin
					$display("EACALC1: tGoto(FETCH_DATA");
					if (w && (OperandSize32 ? offsdisp > 32'hFFFFFFFC : offsdisp==32'h0000FFFF))
						tGoInt(8'h0d);
					else	
						tGoto(rf80386_pkg::FETCH_DATA);
				end
			8'h00:
				begin
					case(rrr)
					3'b010: tGoto(rf80386_pkg::LLDT);	// LLDT
					3'b011: begin ltr <= 1'b1; tGoto(rf80386_pkg::FETCH_DATA); end// LTR
					default: tGoto(rf80386_pkg::FETCH_DATA);
					endcase
					if (w && (OperandSize32 ? offsdisp > 32'hFFFFFFFC : offsdisp==32'h0000FFFF))
						tGoInt(8'h0d);
				end
			8'h01:
				begin
					case(rrr)
					3'b010: begin lgdt <= 1'b1; tGoto(rf80386_pkg::LxDT); end
					3'b011: begin lidt <= 1'b1; tGoto(rf80386_pkg::LxDT); end
					3'b110:	begin lmsw <= 1'b1;	tGoto(rf80386_pkg::FETCH_DATA); end
					default: tGoto(rf80386_pkg::FETCH_DATA);
					endcase
					if (w && (OperandSize32 ? offsdisp > 32'hFFFFFFFC : offsdisp==32'h0000FFFF))
						tGoInt(8'h0d);
				end
			8'h03:
				if (w && (OperandSize32 ? offsdisp > 32'hFFFFFFFC : offsdisp==32'h0000FFFF))
					tGoInt(8'h0d);
				else
					tGoto(rf80386_pkg::FETCH_DATA);
			default:
				if (w && (OperandSize32 ? offsdisp > 32'hFFFFFFFC : offsdisp==32'h0000FFFF))
					tGoInt(8'h0d);
				else
					tGoto(rf80386_pkg::FETCH_DATA);
			endcase
		`MOV_I8M: tGoto(rf80386_pkg::FETCH_IMM8);
		`MOV_I16M:
			if (OperandSize32 ? eip > 32'hFFFFFFFC : eip==32'h0000FFFF)
				tGoInt(8'h0d);
			else
				tGoto(rf80386_pkg::FETCH_IMM16);
		`POP_MEM:
			begin
				tGoto(rf80386_pkg::POP);
			end
		`XCHG_MEM:
			begin
//				bus_locked <= 1'b1;
				tGoto(rf80386_pkg::FETCH_DATA);
			end
		`MOV_S2R:
			begin
				$display("EACALC1: tGoto(STORE_DATA");
				if (w && (OperandSize32 ? offsdisp > 32'hFFFFFFFC : offsdisp==32'h0000FFFF))
					tGoInt(8'h0d);
				else begin	
					res <= rfso;
					tGoto(rf80386_pkg::STORE_DATA);
				end
			end
		8'b1000100?:	// Move to memory
			begin
				$display("EACALC1: tGoto(STORE_DATA");
				if (w && (OperandSize32 ? offsdisp > 32'hFFFFFFFC : offsdisp==32'h0000FFFF))
					tGoInt(8'h0d);
				else begin	
					res <= rrro;
					tGoto(rf80386_pkg::STORE_DATA);
				end
			end
		`LEA:	tGoto(rf80386_pkg::EXECUTE);
		default:
			begin
				$display("EACALC1: tGoto(FETCH_DATA");
				if (w && (OperandSize32 ? offsdisp > 32'hFFFFFFFC : offsdisp==32'h0000FFFF))
					tGoInt(8'h0d);
				else	
					tGoto(rf80386_pkg::FETCH_DATA);
				if (ir==8'hff) begin
					case(rrr)
					3'b011: tGoto(rf80386_pkg::CALLF);	// CAll FAR indirect
					3'b101: tGoto(rf80386_pkg::JUMP_VECTOR1);	// JMP FAR indirect
					3'b110:	begin d <= 1'b0; tGoto(rf80386_pkg::PUSH); end// for a push
					default: ;
					endcase
				end
			end
		endcase
//		ea <= ea + disp16;
		ea <= seg_reg + offsdisp;	// offsdisp = offset + disp16
		ea1 <= seg_reg + offsdisp;	
	end
