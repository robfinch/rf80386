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
// - All of the state control flags are reset.
//
// - If the current instruction is a prefix then we want to shift it
//   into the prefix buffer before fetching the instruction. Also
//   interrupts are blocked if the previous instruction is a prefix.
//
// - two bytes are fetched at once if the instruction is aligned on
//   an even address. This saves a bus cycle most of the time.
//
// ToDo:
// - add an exception if more than two prefixes are present.
//
//=============================================================================
//
rf80386_pkg::IFETCH:
	begin
		insn_count <= insn_count + 2'd1;
		$display("\r\n******************************************************");
		$display("time: %d  tick: %d  insns: %d  imiss: %d", $time, tick, insn_count, imiss_count);
		$display("Machine mode: %s states: %d", realMode ? "real" : v86 ? "v86" : "prot", LAST_STATE);
		$display("CSIP: %h", csip);
		$display("EAX=%h  ESI=%h", eax, esi);
		$display("EBX=%h  EDI=%h", ebx, edi);
		$display("ECX=%h  EBP=%h", ecx, ebp);
		$display("EDX=%h  ESP=%h", edx, esp);
		$display("CS=%h DS=%h ES=%h FS=%h GS=%h SS=%h", cs, ds, es, fs, gs, ss);
		$display("Bases");
		$display("   CS=%h DS=%h ES=%h FS=%h GS=%h, SS=%h",
			cs_base, ds_base, es_base, fs_base, gs_base, ss_base);
		$display("Limits");
		$display("   CS=%h DS=%h ES=%h FS=%h GS=%h, SS=%h",
			cs_limit, ds_limit, es_limit, fs_limit, gs_limit, ss_limit);

		// Reset all instruction processing flags at instruction fetch
		
		// Default the size of operands and addresses, but not if there is a
		// size prefix.
		if (prefix1!=`OPSZ && prefix2!=`OPSZ && ir!=`OPSZ) begin
			if (cs_desc.db & ~realMode)
				OperandSize32 = 1'b1;
			else
				OperandSize32 = 1'b0;
		end
		if (prefix1!=`ADSZ && prefix2!=`ADSZ && ir!=`ADSZ) begin
			if (cs_desc.db & ~realMode)
				AddrSize = 8'd32;
			else
				AddrSize = 8'd16;
			if (ss_desc.db & ~realMode)
				StkAddrSize = 8'd32;
			else
				StkAddrSize = 8'd16;
		end

		mod <= 2'd0;
		rrr <= 3'd0;
		rm <= 3'd0;
		sxi <= 1'b0;
		hasFetchedModrm <= 1'b0;
		hasFetchedDisp8 <= 1'b0;
		hasFetchedDisp16 <= 1'b0;
		hasFetchedVector <= 1'b0;
		hasStoredData <= 1'b0;
		hasFetchedData <= 1'b0;
		lidt <= 1'b0;
		lgdt <= 1'b0;
		lmsw <= 1'b0;
		lsl <= 1'b0;
		ltr <= 1'b0;
		sidt <= 1'b0;
		sgdt <= 1'b0;
		sldt <= 1'b0;
		smsw <= 1'b0;
		d_lds <= 1'b0;
		d_les <= 1'b0;
		d_lfs <= 1'b0;
		d_lgs <= 1'b0;
		d_lss <= 1'b0;
		d_jmp <= 1'b0;
		nest_task <= 1'b0;
		str <= 1'b0;
		verr <= 1'b0;
		verw <= 1'b0;
		jccl <= 1'b0;
		data16 <= 16'h0000;
		cnt <= 7'd0;
		wrvz <= 1'b0;
		int_disable <= 1'b0;
		internal_int <= 1'b0;
		if (!hasPrefix)
			ir_ip <= eip;
//		if (prefix1!=8'h00 && prefix2 !=8'h00 && is_prefix)
//			state <= TRIPLE_PREFIX;
		begin
			if (cs_desc.db & ~realMode)
				OperandSize32 = 1'b1;
			else
				OperandSize32 = 1'b0;
			if (cs_desc.db & ~realMode)
				AddrSize = 8'd32;
			else
				AddrSize = 8'd16;
			if (ss_desc.db & ~realMode)
				StkAddrSize = 8'd32;
			else
				StkAddrSize = 8'd16;
			if (ir==`XCHG_MEM && mod==2'b11) begin
				wrregs <= 1'b1;
				rrr <= TTT;
				res <= b;
			end
		end

    if (pe_nmi & checkForInts) begin
      rst_nmi <= 1'b1;
      tGoInt(8'h02);
      ir <= `NOP;
    end
    else if (!irq_fifo_underflow & ie & checkForInts && int_priorityp > ipri) begin
    	int_device <= int_devicep;
    	int_num <= int_nump;
    	ipri <= int_priorityp;
      tGoto(rf80386_pkg::INT2);
      ir <= `NOP;
    end
    else if (ir==`HLT) begin
    	;
    end
    else if (eip > cs_limit)
    	tGoInt(8'd13);
    else begin
			tGoto(rf80386_pkg::IFETCH_ACK);
		end
		// Flags for shifts and rotates
		if (wrvz) begin
			case(TTT)
			3'b000:	af <= res[4];	// ROL
			3'b001:	af <= cf;			// ROR
			3'b010:	af <= res[4];	// RCL
			3'b011:	af <= cf;			// RCR
			3'b100:	af <= res[4];	// SHL
			3'b101:	af <= cf;			// SHR
			3'b110:	;
			3'b111:	af <= cf;			// SAR
			endcase
			pf <= ~^res[7:0];
			if (w) begin
				if (OperandSize32) begin
					zf <= res[31:0]==32'h00;
					sf <= res[31];
				end
				else begin
					zf <= res[15:0]==16'h00;
					sf <= res[15];
				end
			end
			else begin
				zf <= res[7:0]==8'h00;
				sf <= res[7];
			end
		end
	end

rf80386_pkg::IFETCH_ACK:
	if (ihit) begin
		$display("CSIP: %h IR: %h",csip,bundle[7:0]);
		if (fnIsPrefix(ibundle[7:0])) begin
			if (fnIsInsnPrefix(ibundle[7:0]))
				prefix1 <= ibundle[7:0];
			else if (fnIsAddrszPrefix(ibundle[7:0]))
				prefix2 <= ibundle[7:0];
			else if (fnIsOpszPrefix(ibundle[7:0]))
				prefix3 <= ibundle[7:0];
			else if (fnIsSegPrefix(ibundle[7:0]))
				prefix4 <= ibundle[7:0];
			eip <= ip_inc;
			// The logic in tGoto() is undesirable here.
			state <= rf80386_pkg::IFETCH;
		end
		else begin
			bundle <= ibundle;
			nack_ir();
			w <= ibundle[0];
			d <= ibundle[1];
			v <= ibundle[1];
			sxi <= ibundle[1];
			sreg2 <= ibundle[4:3];
			sreg3 <= {1'b0,ibundle[4:3]};
			ir2 <= 8'h00;
			tGoto(rf80386_pkg::DECODE);
		end
	end

// Fetch extended opcode
//
XI_FETCH:
	begin
		nack_ir2();
		tGoto(rf80386_pkg::DECODER2);
	end
