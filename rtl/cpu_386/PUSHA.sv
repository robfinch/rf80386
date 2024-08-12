// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  PUSHA push all registers to stack
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

rf80386_pkg::PUSHA:
	begin
		ad <= sssp;
		tUsp(OperandSize32 ? esp - 4'd4 : esp - 4'd2);
		if (OperandSize32) begin
			sel <= 16'h000F;
			dat <= eax;
		end
		else begin
			sel <= 16'h0003;
			dat <= {2{ax}};
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::PUSHA1);
	end
rf80386_pkg::PUSHA1:
	begin
		ad <= sssp;
		if (OperandSize32) begin
			dat <= ecx;
			tUsp(esp - 4'd4);
		end
		else begin
			dat <= {2{cx}};
			tUsp(esp - 4'd2);
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::PUSHA2);
	end	
rf80386_pkg::PUSHA2:
	begin
		ad <= sssp;
		if (OperandSize32) begin
			dat <= edx;
			tUsp(esp - 4'd4);
		end
		else begin
			dat <= {2{dx}};
			tUsp(esp - 4'd2);
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::PUSHA3);
	end	
rf80386_pkg::PUSHA3:
	begin
		ad <= sssp;
		if (OperandSize32) begin
			dat <= ebx;
			tUsp(esp - 4'd4);
		end
		else begin
			dat <= {2{bx}};
			tUsp(esp - 4'd2);
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::PUSHA4);
	end	
// Push the starting SP value before all the pushes.	
rf80386_pkg::PUSHA4:
	begin
		ad <= sssp;
		if (OperandSize32) begin
			dat <= tsp;
			tUsp(esp - 4'd4);
		end
		else begin
			dat <= {2{tsp[15:0]}};
			tUsp(esp - 4'd2);
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::PUSHA5);
	end	
rf80386_pkg::PUSHA5:
	begin
		ad <= sssp;
		if (OperandSize32) begin
			dat <= ebp;
			tUsp(esp - 4'd4);
		end
		else begin
			dat <= {2{ebp[15:0]}};
			tUsp(esp - 4'd2);
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::PUSHA6);
	end	
rf80386_pkg::PUSHA6:
	begin
		ad <= sssp;
		if (OperandSize32) begin
			dat <= esi;
			tUsp(esp - 4'd4);
		end
		else begin
			dat <= {2{esi[15:0]}};
			tUsp(esp - 4'd2);
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::PUSHA7);
	end	
rf80386_pkg::PUSHA7:
	begin
		ad <= sssp;
		if (OperandSize32) begin
			dat <= edi;
		end
		else begin
			dat <= {2{edi[15:0]}};
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::IFETCH);
	end	

