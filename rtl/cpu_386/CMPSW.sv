// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CMPSW
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

rf80386_pkg::CMPSW:
`include "check_for_ints.sv"
	else begin
		ad <= seg_reg + (AddrSize==8'd32 ? esi : si);
		if (OperandSize32)
			sel <= 16'h000F;
		else
			sel <= 16'h0003;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::CMPSW1);
	end

rf80386_pkg::CMPSW1:
	begin
		if ((repz|repnz) ? !cxz : 1'b1) begin
			if (df) begin
				if (OperandSize32)
					tUesi(esi - 4'd4);
				else
					tUesi(esi - 4'd2);
			end
			else begin
				if (OperandSize32)
					tUesi(esi + 4'd4);
				else
					tUesi(esi + 4'd2);
			end
		end
		if (df) begin
			if (OperandSize32)
				a <= dat[31:0];
			else
				a <= {{16{dat[15]}},dat[15:0]};
		end
		else begin
			if (OperandSize32)
				a <= dat[31:0];
			else
				a <= {{16{dat[15]}},dat[15:0]};
		end
		tGoto(rf80386_pkg::CMPSW2);
	end

rf80386_pkg::CMPSW2:
	begin
		ad <= esdi;
		if (OperandSize32)
			sel <= 16'h000F;
		else
			sel <= 16'h0003;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::CMPSW3);
	end

rf80386_pkg::CMPSW3:
	begin
		if ((repz|repnz) ? !cxz : 1'b1) begin
			if (df) begin
				if (OperandSize32)
					tUedi(edi - 4'd4);
				else
					tUedi(edi - 4'd2);
			end
			else begin
				if (OperandSize32)
					tUedi(edi + 4'd4);
				else
					tUedi(edi + 4'd2);
			end
		end
		if (df) begin
			if (OperandSize32)
				b <= dat[31:0];
			else
				b <= {{16{dat[15]}},dat[15:0]};
		end
		else begin
			if (OperandSize32)
				b <= dat[31:0];
			else
				b <= {{16{dat[15]}},dat[15:0]};
		end
		tGoto(rf80386_pkg::CMPSW4);
	end

rf80386_pkg::CMPSW4:
	begin
		pf <= pres;
		zf <= reszw;
		sf <= resnw;
		af <= carry   (1'b1,a[3],b[3],alu_o[3]);
		if (OperandSize32) begin
			cf <= carry   (1'b1,a[31],b[31],alu_o[31]);
			vf <= overflow(1'b1,a[31],b[31],alu_o[31]);
		end
		else begin
			cf <= carry   (1'b1,a[15],b[15],alu_o[15]);
			vf <= overflow(1'b1,a[15],b[15],alu_o[15]);
		end
		if ((repz & !cxz & zf) | (repnz & !cxz & !zf)) begin
			ecx <= cx_dec;
			insn_count <= insn_count + 2'd1;
			tGoto(rf80386_pkg::CMPSW);
		end
		else
			tGoto(rf80386_pkg::IFETCH);
	end
