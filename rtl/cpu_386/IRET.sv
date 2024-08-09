// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  IRET
//  - return from interrupt
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
//  IRET: return from interrupt
//  Fetch cs:ip from stack
//  pop ip
//  pop cs
//  pop flags
// ============================================================================
//
rf80386_pkg::IRET1:
	begin
		ad <= sssp;
		if (realMode) begin
			sel <= 16'h003F;
			esp[15:0] <= esp[15:0] + 4'd6;
		end
		else begin
			sel <= 16'h0FFF;
			esp <= esp + 4'd12;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::IRET2);
	end
rf80386_pkg::IRET2:
	begin
		if (realMode) begin
			neip[15:0] <= dat[15:0];
			selector <= dat[31:16];
			cf <= dat[32];
			pf <= dat[34];
			af <= dat[36];
			zf <= dat[38];
			sf <= dat[39];
			tf <= dat[40];
			ie <= dat[41];
			df <= dat[42];
			vf <= dat[43];
			ipri <= 4'h0;
		end
		else begin
			neip <= dat[31:0];
			selector <= dat[47:32];
			cf <= dat[64];
			pf <= dat[66];
			af <= dat[68];
			zf <= dat[70];
			sf <= dat[71];
			tf <= dat[72];
			ie <= dat[73];
			df <= dat[74];
			vf <= dat[75];
			vm <= dat[81];
			ipri <= dat[95:92];
		end
		tGoto(rf80386_pkg::IRET3);
	end
rf80386_pkg::IRET3:
	begin
		if (vm) begin
			ad <= sssp;
			sel <= 16'h00FF;
			esp <= esp + 4'd8;
			tGosub(rf80386_pkg::LOAD,rf80386_pkg::IRET4);
		end
		else
			tGoto(rf80386_pkg::IRET5);
	end
rf80386_pkg::IRET4:
	begin
		esp <= dat[31:0];
		ss <= dat[47:32];
		if (ss != dat[47:32] || !ss_desc_v)
			tGosub(rf80386_pkg::LOAD_SS_DESC,rf80386_pkg::IRET5);
		else
			tGoto(rf80386_pkg::IRET5);
	end
rf80386_pkg::IRET5:
	begin
		if (cs != selector || !cs_desc_v)
			tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::IRET6);
		else
			tGoto(rf80386_pkg::IRET6);
	end
rf80386_pkg::IRET5:
	begin
		eip <= neip;
		cs <= selector;
		tGoto(rf80386_pkg::IFETCH);
	end
