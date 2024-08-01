// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  EXECUTE
//  - execute instruction
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

rf80386_pkg::EXECUTE:
	begin
		casez(ir)

		`EXTOP:
			casez(ir2)
			`BSF,`BSR:
				begin
					wrregs <= 1'b1;
					res <= alu_o;
					tGoto(rf80386_pkg::IFETCH);
				end
			`LSS:
				begin
					wrregs <= 1'b1;
					res <= a;
					ss <= b;
					tGoto(rf80386_pkg::IFETCH);
				end
			`LFS:
				begin
					wrregs <= 1'b1;
					res <= a;
					fs <= b;
					tGoto(rf80386_pkg::IFETCH);
				end
			`LGS:
				begin
					wrregs <= 1'b1;
					res <= a;
					gs <= b;
					tGoto(rf80386_pkg::IFETCH);
				end
			`LLDT: tGoto(rf80386_pkg::LLDT);
			`LxDT: tGoto(rf80386_pkg::LxDT);
			default:	;
			endcase

		`DAA:
			tGoto(rf80386_pkg::IFETCH);

		`ALU_I2R8,`ALU_I2R16,`ALU_I82R8,`ALU_I82R16:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrregs <= TTT!=3'd7;	// CMP does not update regs
				res <= alu_o;
				pf <= pres;
				af <= carry   (1'b0,a[3],b[3],alu_o[3]);
				cf <= carry   (1'b0,amsb,bmsb,resn);
				vf <= overflow(1'b0,amsb,bmsb,resn);
				sf <= resn;
				zf <= resz;
			end
		`ADD,`ADD_ALI8,`ADD_AXI16,`ADC,`ADC_ALI8,`ADC_AXI16:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrregs <= 1'b1;
				res <= alu_o;
				pf <= pres;
				af <= carry   (1'b0,a[3],b[3],alu_o[3]);
				cf <= carry   (1'b0,amsb,bmsb,resn);
				vf <= overflow(1'b0,amsb,bmsb,resn);
				sf <= resn;
				zf <= resz;
			end

		`AND,`OR,`XOR,`AND_ALI8,`OR_ALI8,`XOR_ALI8,`AND_AXI16,`OR_AXI16,`XOR_AXI16:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrregs <= 1'b1;
				res <= alu_o;
				pf <= pres;
				cf <= 1'b0;
				vf <= 1'b0;
				sf <= resn;
				zf <= resz;
			end

		`TEST:
			begin
				tGoto(rf80386_pkg::IFETCH);
				res <= alu_o;
				pf <= pres;
				cf <= 1'b0;
				vf <= 1'b0;
				sf <= resn;
				zf <= resz;
			end

		`CMP,`CMP_ALI8,`CMP_AXI16:
			begin
				tGoto(rf80386_pkg::IFETCH);
				pf <= pres;
				af <= carry   (1'b1,a[3],b[3],alu_o[3]);
				cf <= carry   (1'b1,amsb,bmsb,resn);
				vf <= overflow(1'b1,amsb,bmsb,resn);
				sf <= resn;
				zf <= resz;
			end

		`SBB,`SUB,`SBB_ALI8,`SUB_ALI8,`SBB_AXI16,`SUB_AXI16:
			begin
				wrregs <= 1'b1;
				tGoto(rf80386_pkg::IFETCH);
				res <= alu_o;
				pf <= pres;
				af <= carry   (1'b1,a[3],b[3],alu_o[3]);
				cf <= carry   (1'b1,amsb,bmsb,resn);
				vf <= overflow(1'b1,amsb,bmsb,resn);
				sf <= resn;
				zf <= resz;
			end
			
		`ARPL:
			begin
				if (a[1:0] < b[1:0]) begin
					res <= {a[15:2],b[1:0]};
					zf <= 1'b1;
					if (mod==2'b11) begin
						wrregs <= 1'b1;
						tGoto(rf80386_pkg::IFETCH);
					end
					else
						tGoto(rf80386_pkg::STORE_DATA);
				end
				else
					zf <= 1'b0;
			end

		`BOUND:
			if (c < a || c > b) begin
				int_num <= 8'h05;
				tGoto(rf80386_pkg::INT2);
			end

		`IMULI8,`IMULI:
			begin
				if (cs_desc.db) begin
					eax <= sp32x32[31:0];
					edx <= sp32x32[63:32];
					cf <= sp32x32[63:32]!=32'd0;
					vf <= sp32x32[63:32]!=32'd0;
				end
				else begin
					eax[15:0] <= sp16x16[15:0];
					edx[15:0] <= sp16x16[31:16];
					cf <= sp16x16[31:16]!=16'd0;
					vf <= sp16x16[31:16]!=16'd0;
				end
				tGoto(rf80386_pkg::IFETCH);
			end

		8'hF6,8'hF7:
			begin
				tGoto(rf80386_pkg::IFETCH);
				res <= alu_o;
				case(TTT)
				3'd0:	// TEST
					begin
						pf <= pres;
						cf <= 1'b0;
						vf <= 1'b0;
						sf <= resn;
						zf <= resz;
					end
				3'd2:	// NOT
					begin
						wrregs <= 1'b1;
					end
				3'd3:	// NEG
					begin
						pf <= pres;
						af <= carry   (1'b1,1'b0,b[3],alu_o[3]);
						cf <= carry   (1'b1,1'b0,bmsb,resn);
						vf <= overflow(1'b1,1'b0,bmsb,resn);
						sf <= resn;
						zf <= resz;
						wrregs <= 1'b1;
					end
				// Normally only a single register update is required, however with 
				// multiply word both AX and DX need to be updated. So we bypass the
				// regular update here.
				3'd4:
					begin
						if (w) begin
							if (OperandSize32) begin
								eax <= p64[31:0];
								edx <= p64[63:32];
								cf <= p64[63:32]!=32'd0;
								vf <= p64[63:32]!=32'd0;
								sf <= p64[32];
								zf <= p64==64'd0;
							end
							else begin
								eax[15:0] <= p32[15:0];
								edx[15:0] <= p32[31:16];
								cf <= p32[31:16]!=16'd0;
								vf <= p32[31:16]!=16'd0;
								sf <= p32[16];
								zf <= p32==32'd0;
							end
						end
						else begin
							eax[15:0] <= p16;
							cf <= p16[15:8]!=8'd0;
							vf <= p16[15:8]!=8'd0;
							sf <= p16[8];
							zf <= p16==16'd0;
						end
					end
				3'd5:
					begin
						if (w) begin
							if (OperandSize32) begin
								eax <= wp[31:0];
								edx <= wp[63:32];
								cf <= wp[63:32]!=16'd0;
								vf <= wp[63:32]!=16'd0;
								sf <= wp[32];
								zf <= wp==64'd0;
							end
							else begin
								eax[15:0] <= wp[15:0];
								edx[15:0] <= wp[31:16];
								cf <= wp[31:16]!=16'd0;
								vf <= wp[31:16]!=16'd0;
								sf <= wp[16];
								zf <= wp[31:0]==32'd0;
							end
						end
						else begin
							eax[15:0] <= p;
							cf <= p[15:8]!=8'd0;
							vf <= p[15:8]!=8'd0;
							sf <= p[8];
							zf <= p[15:0]==16'h0;
						end
					end
				3'd6,3'd7:
					begin
						$display("tGoto(DIVIDE1");
						tGoto(DIVIDE1);
					end
				default:	;
				endcase
			end

		`INC_REG:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrregs <= 1'b1;
				w <= 1'b1;
				res <= alu_o;
				pf <= pres;
				af <= carry   (1'b0,a[3],b[3],alu_o[3]);
				vf <= overflow(1'b0,cs_desc.db ? a[31] : a[15],cs_desc.db ? b[31] : b[15],resnw);
				sf <= resnw;
				zf <= reszw;
			end
		`DEC_REG:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrregs <= 1'b1;
				w <= 1'b1;
				res <= alu_o;
				pf <= pres;
				af <= carry   (1'b1,a[3],b[3],alu_o[3]);
				vf <= overflow(1'b1,cs_desc.db ? a[31] : a[15],cs_desc.db ? b[31] : b[15],resnw);
				sf <= resnw;
				zf <= reszw;
			end
//		`IMUL:
//			begin
//				tGoto(IFETCH;
//				wrregs <= 1'b1;
//				w <= 1'b1;
//				rrr <= 3'd0;
//				res <= alu_o;
//				if (w) begin
//					cf <= wp[31:16]!={16{resnw}};
//					vf <= wp[31:16]!={16{resnw}};
//					dx <= wp[31:16];
//				end
//				else begin
//					cf <= ah!={8{resnb}};
//					vf <= ah!={8{resnb}};
//				end
//			end


		//-----------------------------------------------------------------
		// Memory Operations
		//-----------------------------------------------------------------

		// registers not allowed on LEA
		// invalid opcode
		//
		`LEA:
			begin
				w <= 1'b1;
				res <= offsdisp;
				if (mod==2'b11) begin
					int_num <= 8'h06;
					tGoto(INT);
				end
				else begin
					tGoto(rf80386_pkg::IFETCH);
					wrregs <= 1'b1;
				end
			end
		`LDS:
			begin
				wrregs <= 1'b1;
				res <= a;
				ds <= b;
				tGoto(rf80386_pkg::IFETCH);
			end
		`LES:
			begin
				wrregs <= 1'b1;
				res <= a;
				es <= b;
				tGoto(rf80386_pkg::IFETCH);
			end
		`MOV_RR8,`MOV_RR16:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrregs <= 1'b1;
				rrr <= rm;
				res <= alu_o;
			end
		`MOV_MR,
		`MOV_M2AL,`MOV_M2AX,
		`MOV_I2AL,`MOV_I2DL,`MOV_I2CL,`MOV_I2BL,`MOV_I2AH,`MOV_I2DH,`MOV_I2CH,`MOV_I2BH,
		`MOV_I2AX,`MOV_I2DX,`MOV_I2CX,`MOV_I2BX,`MOV_I2SP,`MOV_I2BP,`MOV_I2SI,`MOV_I2DI:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrregs <= 1'b1;
				res <= alu_o;
			end
		`XCHG_MEM:
			begin
				wrregs <= 1'b1;
				if (mod==2'b11) rrr <= rm;
				res <= alu_o;
				b <= rrro;
				tGoto(mod==2'b11 ? rf80386_pkg::IFETCH : XCHG_MEM);
			end
		`MOV_I8M,`MOV_I16M:
			begin
				res <= alu_o;
				if (mod==2'd3) begin
					wrregs <= 1'b1;
					tGoto(rf80386_pkg::IFETCH);
				end
				else
					tGoto(TTT==3'd0 ? STORE_DATA : INVALID_OPCODE);
			end

		`MOV_S2R:
			begin
				w <= 1'b1;
				rrr <= rm;
				res <= alu_o;
				if (mod==2'b11) begin
					tGoto(rf80386_pkg::IFETCH);
					wrregs <= 1'b1;
				end
				else
					tGoto(STORE_DATA);
			end
		`MOV_R2S:
			begin
				// Disable interrupts until after fetch of next instruction if a move
				// into ss is taking place. To simplify logic this is done even if the
				// instruction causes a fault.
				if (sreg3==3'd2)
					int_disable <= 1'b1;
				if (sreg3==3'd1)	begin // move to CS?
					int_num = 8'd6;				// Invalid opcode
					tGoto(rf80386_pkg::INT2);
				end
				else if (realMode) begin
					wrsregs <= 1'b1;
					res <= alu_o;
					tGoto(rf80386_pkg::IFETCH);
				end
				else begin
					if (sreg3==3'd2 && alu_o[15:2]==14'h0)	begin // move NULL to SS?
						int_num = 8'd13;					// GP
						tGoto(rf80386_pkg::INT2);
					end
					else begin
						wrsregs <= 1'b1;
						res <= alu_o;
						// Loading a NULL selector into a selector marks descriptor invalid.
						// The descriptor cache is not loaded.
						if (alu_o[15:2]==14'h0) begin
							case(sreg3)
							3'd0:	es_desc_v <= 1'b0;
							3'd3:	ds_desc_v <= 1'b0;
							3'd4:	fs_desc_v <= 1'b0;
							3'd5: gs_desc_v <= 1'b0;
							default:	;
							endcase
							tGoto(rf80386_pkg::IFETCH);
						end
						else
							tGosub(rf80386_pkg::LOAD_DESC,rf80386_pkg::IFETCH);
					end
				end
			end
		`LODSB:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrregs <= 1'b1;
				w <= 1'b0;
				rrr <= 3'd0;
				res <= a[7:0];
				if ( df) esi <= si_dec;
				if (!df) esi <= si_inc;
			end
		`LODSW:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrregs <= 1'b1;
				w <= 1'b1;
				rrr <= 3'd0;
				res <= a;
				if (OperandSize32) begin
					if ( df) esi <= esi - 16'd4;
					if (!df) esi <= esi + 16'd4;
				end
				else begin
					if ( df) esi <= esi - 16'd2;
					if (!df) esi <= esi + 16'd2;
				end
			end

		8'hD0,8'hD1,8'hD2,8'hD3,`SHI8,`SHI16:
			begin
				tGoto(rf80386_pkg::IFETCH);
				wrvz <= 1'b1;
				if (mod==2'd3)
					wrregs <= 1'b1;
				else
					tGosub(rf80386_pkg::STORE_DATA,rf80386_pkg::IFETCH);
				rrr <= rm;
				if (w) begin
					if (OperandSize32)
						case(rrr)
						3'b000:	// ROL
							begin
								res <= shlo32[31:0]|shlo32[63:32];
								cf <= shlo32[32];
								vf <= shlo32[32]^shlo32[31];
							end
						3'b001:	// ROR
							begin
								res <= shruo32[31:0]|shruo32[63:32];
								cf <= shruo32[31];
								vf <= shruo32[31]^shruo32[30];
							end
						3'b010:	// RCL
							begin
								res <= shlco32[31:0]|shlco32[63:32];
								cf <= shlco32[32];
								vf <= shlo32[32]^shlo32[31];
							end
						3'b011:	// RCR
							begin
								res <= shrcuo32[31:0]|shrcuo32[63:32];
								cf <= shrcuo32[31];
								vf <= shrcuo32[31]^shrcuo32[30];
							end
						3'b100:	// SHL
							begin
								res <= shlo32[31:0];
								cf <= |shlo32[63:32];
								vf <= b[31] ? ~&shlo32[63:31] : |shlo32[63:31];
							end
						3'b101:	// SHR
							begin
								res <= shruo32[63:32];
								cf <= shruo32[31];
								vf <= shruo32[63]^b[31];
							end
						3'b110:
							tGoto(INVALID_OPCODE);
						3'b111:	// SAR
							begin
								res <= shro32[63:32];
								cf <= shro32[31];
								vf <= 1'b0;
							end
						endcase
					else
						case(rrr)
						3'b000:	// ROL
							begin
								res <= shlo16[15:0]|shlo16[31:16];
								cf <= shlo16[16];
								vf <= shlo16[16]^shlo16[15];
							end
						3'b001:	// ROR
							begin
								res <= shruo16[15:0]|shruo16[31:16];
								cf <= shruo16[15];
								vf <= shruo16[15]^shruo16[14];
							end
						3'b010:	// RCL
							begin
								res <= shlco16[15:0]|shlco16[31:16];
								cf <= shlco16[16];
								vf <= shlco16[16]^shlco16[15];
							end
						3'b011:	// RCR
							begin
								res <= shrcuo16[15:0]|shrcuo16[31:16];
								cf <= shrcuo16[15];
								vf <= shrcuo16[15]^shrcuo16[14];
							end
						3'b100:	// SHL
							begin
								res <= shlo16[15:0];
								cf <= |shlo16[63:16];
								vf <= b[15] ? ~&shlo16[63:15] : |shlo16[63:15];
							end
						3'b101:	// SHR
							begin
								res <= shruo16[31:16];
								cf <= shruo16[15];
								vf <= shruo16[31]^b[15];
							end
						3'b110:
							tGoto(INVALID_OPCODE);
						3'b111:	// SAR
							begin
								res <= shro16[31:16];
								cf <= shro16[15];
								vf <= 1'b0;
							end
						endcase
				end
				else
					case(rrr)
					3'b000:	// ROL
						begin
							res <= shlo8[7:0]|shlo8[15:8];
							cf <= shlo8[8];
							vf <= shlo8[8]^shlo8[7];
						end
					3'b001:	// ROR
						begin
							res <= shruo8[15:8]|shruo8[7:0];
							cf <= shruo8[7];
							vf <= shruo8[7]^shruo8[6];
						end
					3'b010:	// RCL
						begin
							res <= shlco8[7:0]|shlco8[15:8];
							cf <= shlco8[8];
							vf <= shlco8[8]^shlco8[7];
						end
					3'b011:	// RCR
						begin
							res <= shrcuo8[15:8]|shrcuo8[7:0];
							cf <= shrcuo8[7];
							vf <= shrcuo8[7]^shrcuo8[6];
						end
					3'b100:	// SHL
						begin
							res <= shlo8[7:0];
							cf <= |shlo8[63:8];
							vf <= b[7] ? ~&shlo8[63:7] : |shlo8[63:7];
						end
					3'b101:	// SHR
						begin
							res <= shruo8[15:8];
							cf <= shruo8[7];
							vf <= shruo8[15]^b[7];
						end
					3'b110:
						tGoto(INVALID_OPCODE);
					3'b111:	// SAR
						begin
							res <= shro8[15:8];
							cf <= shro8[7];
							vf <= 1'b0;
						end
					endcase
			end

		//-----------------------------------------------------------------
		//-----------------------------------------------------------------
		`GRPFF:
			begin
				case(rrr)
				3'b000:		// INC
					begin
						tGoto(rf80386_pkg::IFETCH);
						wrregs <= 1'b1;
						af <= carry   (1'b0,a[3],b[3],alu_o[3]);
						if (cs_desc.db)
							vf <= overflow(1'b0,a[31],b[31],alu_o[31]);
						else
							vf <= overflow(1'b0,a[15],b[15],alu_o[15]);
						w <= 1'b1;
						res <= alu_o;
						rrr <= rm;
						pf <= pres;
						sf <= resnw;
						zf <= reszw;
					end
				3'b001:		// DEC
					begin
						tGoto(rf80386_pkg::IFETCH);
						wrregs <= 1'b1;
						af <= carry   (1'b1,a[3],b[3],alu_o[3]);
						if (cs_desc.db)
							vf <= overflow(1'b1,a[31],b[31],alu_o[31]);
						else
							vf <= overflow(1'b1,a[15],b[15],alu_o[15]);
						w <= 1'b1;
						res <= alu_o;
						rrr <= rm;
						pf <= pres;
						sf <= resnw;
						zf <= reszw;
					end
				3'b010:	begin esp <= sp_dec; tGoto(rf80386_pkg::CALL_IN); end
				// These two should not be reachable here, as they would
				// be trapped by the EACALC.
				3'b011:	tGoto(rf80386_pkg::CALL_FIN);	// CALL FAR indirect
				3'b101:	// JMP FAR indirect
					begin
						eip <= offset;
						cs <= selector;
						tGoto(rf80386_pkg::IFETCH);
					end
				3'b110:	begin esp <= sp_dec; tGoto(PUSH); end
				default:
					begin
						af <= carry   (1'b0,a[3],b[3],alu_o[3]);
						if (OperandSize32)
							vf <= overflow(1'b0,a[31],b[31],alu_o[31]);
						else
							vf <= overflow(1'b0,a[15],b[15],alu_o[15]);
					end
				endcase
			end

		//-----------------------------------------------------------------
		//-----------------------------------------------------------------
		default:
			tGoto(rf80386_pkg::IFETCH);
		endcase
	end

