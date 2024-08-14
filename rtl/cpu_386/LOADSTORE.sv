// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  LOADSTORE
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

// Run two bus cycles if the data is badly aligned.
// A load or store will not proceed if there is an instruction cache miss.
// It will wait until the miss clears.

// Capture the original parameters for the load and the cache enable status.
// The cache enable needs to be disabled temporarily so that a store to 
// memory can occur for modified cache lines.
// Compute the data load mask and setup select signals for corresponding
// data alignment.
rf80386_pkg::LOAD:
	begin
		org_ad <= ad;
		org_sel <= sel;
		org_dat <= dat;
		org_dce <= dce;
		sel_shift <= {16'h0,sel} << ad[3:0];
		org_sel_shift <= {16'h0,sel} << ad[3:0];
		store_mod <= 1'b0;
		case(sel)
		16'h0001:	ls_mask <= 128'hFF;
		16'h0003:	ls_mask <= 128'hFFFF;
		16'h000F:	ls_mask <= 128'hFFFFFFFF;
		16'h003F:	ls_mask <= 128'hFFFFFFFFFFFF;	// lidt / lgdt
		16'h00FF:	ls_mask <= 128'hFFFFFFFFFFFFFFFF;
		16'hFFFF:	ls_mask <= 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
		default:	ls_mask <= 128'h0;
		endcase
		tGoto(rf80386_pkg::LOAD1);
	end
rf80386_pkg::LOAD1:
	begin
		// If there is a hit, capture the data from the data cache.
		if (dc_hit) begin
			dat <= (dc_line[ad[`DC_LINENO_BITS]] >> {ad[3:0],3'b0}) & ls_mask;
			// If a second bus cycle is needed for an unaligned load, increment the
			// address pointer and goto the second load state. Otherwise we're done
			// so return.
			if (need_load2) begin
				ad <= ad2;
				tGoto(rf80386_pkg::LOAD2);
			end
			else
				tReturn();
		end
		else if (ihit) begin
			// There was a cache miss or the data cache was not enabled.
			// For a modified line, compute the parameters for a store operation,
			// then disable caching so a store to memory may take place.
			if (dc_modified[ad[`DC_LINENO_BITS]] && dce) begin
				ad <= {dc_tag[ad[`DC_LINENO_BITS]],ad[`DC_LINENO_BITS],4'h0};
				sel <= 16'hFFFF;
				sel_shift <= 20'h0FFFF;
				dat_shift <= dc_line[ad[`DC_LINENO_BITS]];
				dce <= 1'b0;
				store_mod <= 1'b1;
				tGosub(rf80386_pkg::STORE,rf80386_pkg::LOAD1a);
			end
			else begin
				ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
	//		ea <= ad;
				tSetTid();
				ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::CLASSIC;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= sel_shift[15:0];
				ftam_req.we <= LOW;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				cyc_done <= FALSE;
				rty_wait <= 5'd0;
				tGoto(rf80386_pkg::LOAD_ACK);
			end
		end
	end

// Reset the parameters for the load after storing the cache line.
// The cache line was just written out to memory so it is no longer modified.
// Now it can be loaded.
rf80386_pkg::LOAD1a:
	begin
		ad <= org_ad;
		sel <= org_sel;
		dat <= org_dat;
		dce <= org_dce;
		sel_shift <= org_sel_shift;
		dc_modified[org_ad[`DC_LINENO_BITS]] <= 1'b0;
		tGoto(rf80386_pkg::LOAD1);
	end

// If data caching is enabled, capture the load data in the cache. The tag
// needs to be recorded and the line can be marked not-modified.
rf80386_pkg::LOAD_ACK:
	begin
		if (ack_i && ftam_resp.tid.tranid==tid) begin
			if (dce) begin
				dc_line[ad[`DC_LINENO_BITS]] <= ftam_resp.dat;
				dc_tag[ad[`DC_LINENO_BITS]] <= ad[$bits(ad)-1:`DC_TAGBIT];
				dc_modified[ad[`DC_LINENO_BITS]] <= 1'b0;
			end
			dat <= (ftam_resp.dat >> {ad[3:0],3'b0}) & ls_mask;
			ad <= ad2;
			sel <= sel_shift[19:16];
			if (need_load2)
				tGoto(rf80386_pkg::LOAD2);
			else begin
				ad <= ad;
				tReturn();
			end
		end
		else if (rty_i) begin
			rty_wait <= rty_wait + 2'd1;
			if (rty_wait==5'd31) begin
				rty_wait <= 5'd0;
				if (ihit) begin
					ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					tSetTid();
					ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
					ftam_req.blen <= 6'd0;
					ftam_req.bte <= fta_bus_pkg::LINEAR;
					ftam_req.cti <= fta_bus_pkg::CLASSIC;
					ftam_req.cyc <= HIGH;
					ftam_req.stb <= HIGH;
					ftam_req.sel <= sel_shift[15:0];
					ftam_req.we <= LOW;
					ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					adr_o <= ad;
				end
			end
		end
		else begin
			cyc_done <= TRUE;
		end
	end
rf80386_pkg::LOAD2:
	begin
		// If a data cache hit, merge in the data from the second cache line and
		// mask the result. Return as we're done.
		if (dc_hit) begin
			dat <= (dat | ({128'd0,dc_line[ad[`DC_LINENO_BITS]]} << {5'd16-org_ad[3:0],3'b0})) & ls_mask;
			ad <= org_ad;
			tReturn();
		end
		else begin
			// If the second cache line is modified, write it out to memory. The
			// line's tag is used to form the address. Data caching is temporarily
			// disable so the store may go to memory.
			if (dce && dc_modified[ad[`DC_LINENO_BITS]]) begin
				store_mod <= 1'b1;
				sel <= 16'hFFFF;
				sel_shift <= 20'h0FFFF;
				dat_shift <= dc_line[ad[`DC_LINENO_BITS]];
				dc_modified[ad[`DC_LINENO_BITS]] <= 1'b0;
				ad <= {dc_tag[ad[`DC_LINENO_BITS]],ad[`DC_LINENO_BITS],4'h0};
				dce <= 1'b0;
				tGosub(rf80386_pkg::STORE,rf80386_pkg::LOAD2a);
			end
			else begin
				ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				tSetTid();
				ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::CLASSIC;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= {12'h0,sel_shift[19:16]};
				ftam_req.we <= LOW;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				cyc_done <= FALSE;
				rty_wait <= 5'd0;
				tGoto(rf80386_pkg::LOAD2_ACK);
			end
		end
	end

// Reset the parameters for the load. Mark the line as not-modified and restore
// the data cache enable. The store completed above will mark the line as
// modified, this needs to be cancelled.
rf80386_pkg::LOAD2a:
	begin
		ad <= ad2;
		sel <= org_sel;
		sel_shift <= org_sel_shift;
		dc_modified[ad[`DC_LINENO_BITS]] <= 1'b0;
		dce <= org_dce;
		store_mod <= 1'b0;
		tGoto(rf80386_pkg::LOAD2);
	end

rf80386_pkg::LOAD2_ACK:
	begin
		if (ftam_resp.ack && ftam_resp.tid.tranid==tid) begin
			if (dce) begin
				dc_line[ad[`DC_LINENO_BITS]] <= ftam_resp.dat;
				dc_tag[ad[`DC_LINENO_BITS]] <= ad[$bits(ad)-1:10];
				dc_modified[ad[`DC_LINENO_BITS]] <= 1'b0;
			end
			dat <= (dat | ({128'h0,ftam_resp.dat} << {5'd16-org_ad[3:0],3'b0})) & ls_mask;
			ad <= org_ad;
			tReturn();
		end
		else if (rty_i) begin
			rty_wait <= rty_wait + 2'd1;
			if (rty_wait==5'd31) begin
				rty_wait <= 5'd0;
				ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				tSetTid();
				ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::CLASSIC;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= {12'h0,sel_shift[19:16]};
				ftam_req.we <= LOW;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				cyc_done <= FALSE;
			end
		end
		else
			cyc_done <= TRUE;
	end

// Capture a copy of the parameters for a store operation. Align the data
// to the correct position.
rf80386_pkg::STORE:
	begin
		sorg_ad <= ad;
		sorg_sel <= sel;
		sorg_dat <= dat;
		sorg_dce <= dce;
		sorg_sel_shift <= {16'h0,sel} << ad[3:0];
		sel_shift <= {16'h0,sel} << ad[3:0];
		if (!store_mod)
			dat_shift <= {128'd0,dat} << {ad[3:0],3'd0};
		tGoto(rf80386_pkg::STORE1);
	end

rf80386_pkg::STORE1:
	begin
		// If there is a cache hit, update the part of the cache line indicated by
		// the select lines. Mark the line as modified. Increment the address pointer
		// and goto store the second line if needed.
		if (dc_hit) begin
			ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			if (sel_shift[0]) dc_line[ad[`DC_LINENO_BITS]][7:0] <= dat_shift[7:0];
			if (sel_shift[1]) dc_line[ad[`DC_LINENO_BITS]][15:8] <= dat_shift[15:8];
			if (sel_shift[2]) dc_line[ad[`DC_LINENO_BITS]][23:16] <= dat_shift[23:16];
			if (sel_shift[3]) dc_line[ad[`DC_LINENO_BITS]][31:24] <= dat_shift[31:24];
			if (sel_shift[4]) dc_line[ad[`DC_LINENO_BITS]][39:32] <= dat_shift[39:32];
			if (sel_shift[5]) dc_line[ad[`DC_LINENO_BITS]][47:40] <= dat_shift[47:40];
			if (sel_shift[6]) dc_line[ad[`DC_LINENO_BITS]][55:48] <= dat_shift[55:48];
			if (sel_shift[7]) dc_line[ad[`DC_LINENO_BITS]][63:56] <= dat_shift[63:56];
			if (sel_shift[8]) dc_line[ad[`DC_LINENO_BITS]][71:64] <= dat_shift[71:64];
			if (sel_shift[9]) dc_line[ad[`DC_LINENO_BITS]][79:72] <= dat_shift[79:72];
			if (sel_shift[10]) dc_line[ad[`DC_LINENO_BITS]][87:80] <= dat_shift[87:80];
			if (sel_shift[11]) dc_line[ad[`DC_LINENO_BITS]][95:88] <= dat_shift[95:88];
			if (sel_shift[12]) dc_line[ad[`DC_LINENO_BITS]][103:96] <= dat_shift[103:96];
			if (sel_shift[13]) dc_line[ad[`DC_LINENO_BITS]][111:104] <= dat_shift[111:104];
			if (sel_shift[14]) dc_line[ad[`DC_LINENO_BITS]][119:112] <= dat_shift[119:112];
			if (sel_shift[15]) dc_line[ad[`DC_LINENO_BITS]][127:120] <= dat_shift[127:120];
			dc_modified[ad[`DC_LINENO_BITS]] <= 1'b1;
			if (need_store2) begin
				ad <= sad2;
				tGoto(rf80386_pkg::STORE2);
			end
			else begin
				ad <= sorg_ad;
				sel_shift <= sorg_sel_shift;
				tReturn();
			end
		end
		else
		if (ihit) begin
			ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			tSetTid();
			ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
			ftam_req.blen <= 6'd0;
			ftam_req.bte <= fta_bus_pkg::LINEAR;
			ftam_req.cti <= fta_bus_pkg::CLASSIC;
			ftam_req.cyc <= HIGH;
			ftam_req.stb <= HIGH;
			ftam_req.sel <= store_mod ? 16'hFFFF : sel_shift[15:0];
			ftam_req.we <= HIGH;
			ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			ftam_req.data1 <= dat_shift[127:0];
			adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			cyc_done <= FALSE;
			rty_wait <= 5'd0;
			tGoto(rf80386_pkg::STORE_ACK);
		end
	end
rf80386_pkg::STORE_ACK:
	begin
	/*
		if (ack_i && ftam_resp.tid.tranid==tid) begin
			if (|sel_shift[19:16])
				tGoto(rf80386_pkg::STORE2);
			else
				tReturn();
		end
		else
	*/
		if (rty_i) begin
			rty_wait <= rty_wait + 2'd1;
			if (rty_wait==5'd31) begin
				rty_wait <= 5'd0;
				if (ihit) begin
					ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					tSetTid();
					ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
					ftam_req.blen <= 6'd0;
					ftam_req.bte <= fta_bus_pkg::LINEAR;
					ftam_req.cti <= fta_bus_pkg::CLASSIC;
					ftam_req.cyc <= HIGH;
					ftam_req.stb <= HIGH;
					ftam_req.sel <= sel_shift[15:0];
					ftam_req.we <= HIGH;
					ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					ftam_req.data1 <= dat_shift[127:0];
					adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};;
					cyc_done <= FALSE;
				end
			end
		end
		else begin
			if (need_store2 && !store_mod) begin
				ad <= sad2;
				tGoto(rf80386_pkg::STORE2);
			end
			else begin
				ad <= sorg_ad;
				sel_shift <= sorg_sel_shift;
				store_mod <= 1'b0;
				tReturn();
			end
		end
	end
rf80386_pkg::STORE2:
	begin
		if (dc_hit) begin
			if (sel_shift[16]) dc_line[ad[`DC_LINENO_BITS]][7:0] <= dat_shift[135:128];
			if (sel_shift[17]) dc_line[ad[`DC_LINENO_BITS]][15:8] <= dat_shift[143:136];
			if (sel_shift[18]) dc_line[ad[`DC_LINENO_BITS]][23:16] <= dat_shift[151:144];
			if (sel_shift[19]) dc_line[ad[`DC_LINENO_BITS]][31:24] <= dat_shift[159:152];
			dc_modified[ad[`DC_LINENO_BITS]] <= 1'b1;
			ad <= sorg_ad;
			sel_shift <= sorg_sel_shift;
			tReturn();
		end
		else
		if (ihit) begin
			ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			tSetTid();
			ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
			ftam_req.blen <= 6'd0;
			ftam_req.bte <= fta_bus_pkg::LINEAR;
			ftam_req.cti <= fta_bus_pkg::CLASSIC;
			ftam_req.cyc <= HIGH;
			ftam_req.stb <= HIGH;
			ftam_req.sel <= {12'h0,sel_shift[19:16]};
			ftam_req.we <= HIGH;
			ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			ftam_req.data1 <= dat_shift[255:128];
			adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			rty_wait <= 5'd0;
			tGoto(rf80386_pkg::STORE2_ACK);
		end
	end
rf80386_pkg::STORE2_ACK:
/*
	if (ack_i && ftam_resp.tid.tranid==tid) begin
		tReturn();
	end
	else
*/
	if (rty_i) begin
		rty_wait <= rty_wait + 2'd1;
		if (rty_wait==5'd31) begin
			rty_wait <= 5'd0;
			if (ihit) begin
				ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				tSetTid();
				ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::CLASSIC;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= {12'h0,sel_shift[19:16]};
				ftam_req.we <= HIGH;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				ftam_req.data1 <= dat_shift[255:128];
				adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
			end
		end
	end
	else begin
		ad <= sorg_ad;
		sel_shift <= sorg_sel_shift;
		tReturn();
	end

rf80386_pkg::IRQ_LOAD:
	if (ihit) begin
		ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		tSetTid();
		ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::IRQA;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= 16'h0001;
		ftam_req.we <= LOW;
		ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		cyc_done <= FALSE;
		rty_wait <= 5'd0;
		tGoto(rf80386_pkg::IRQ_LOAD_ACK);
	end
rf80386_pkg::IRQ_LOAD_ACK:
		if (ftam_resp.ack && ftam_resp.tid.tranid==tid) begin
			dat <= ftam_resp.dat[7:0];
			tReturn();
		end
		else if (rty_i) begin
			rty_wait <= rty_wait + 2'd1;
			if (rty_wait==5'd31) begin
				rty_wait <= 5'd0;
				if (ihit) begin
					ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					tSetTid();
					ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
					ftam_req.blen <= 6'd0;
					ftam_req.bte <= fta_bus_pkg::LINEAR;
					ftam_req.cti <= fta_bus_pkg::IRQA;
					ftam_req.cyc <= HIGH;
					ftam_req.stb <= HIGH;
					ftam_req.sel <= 16'h0001;
					ftam_req.we <= LOW;
					ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
					cyc_done <= FALSE;
				end
			end
		end
		else
			cyc_done <= TRUE;

rf80386_pkg::LOAD_IO:
	if (ihit) begin
		ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		tSetTid();
		ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::IO;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {16'h0,sel} << ad[3:0];
		ftam_req.we <= LOW;
		ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		cyc_done <= FALSE;
		rty_wait <= 5'd0;
		tGoto(rf80386_pkg::LOAD_IO_ACK);
	end
rf80386_pkg::LOAD_IO_ACK:
	if (ftam_resp.ack && ftam_resp.tid.tranid==tid) begin
		dat <= (ftam_resp.dat >> {ad[3:0],3'b0}) & ls_mask;
		if (|sel_shift[19:16])
			tGoto(rf80386_pkg::LOAD_IO2);
		else
			tReturn();
	end
	else if (rty_i) begin
		rty_wait <= rty_wait + 2'd1;
		if (rty_wait==5'd31) begin
			rty_wait <= 5'd0;
			if (ihit) begin
				ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				tSetTid();
				ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::IO;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= {16'h0,sel} << ad[3:0];
				ftam_req.we <= LOW;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				cyc_done <= FALSE;
			end
		end
	end
	else
		cyc_done <= TRUE;
rf80386_pkg::LOAD_IO2:
	if (ihit) begin
		ea <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		tSetTid();
		ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::IO;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {16'h0,sel}>>(5'd16-ad[3:0]);
		ftam_req.we <= LOW;
		ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		ftam_req.padr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		adr_o <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		cyc_done <= FALSE;
		rty_wait <= 5'd0;
		tGoto(rf80386_pkg::LOAD_IO2_ACK);
	end
rf80386_pkg::LOAD_IO2_ACK:
	if (ftam_resp.ack && ftam_resp.tid.tranid==tid) begin
		dat <= (dat | (ftam_resp.dat << {5'd16-ad[3:0],3'b0})) & ls_mask;
		tReturn();
	end
	else if (rty_i) begin
		rty_wait <= rty_wait + 2'd1;
		if (rty_wait==5'd31) begin
			rty_wait <= 5'd0;
			if (ihit) begin
				ea <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				tSetTid();
				ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::IO;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= {16'h0,sel}>>(5'd16-ad[3:0]);
				ftam_req.we <= LOW;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				adr_o <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				cyc_done <= FALSE;
			end
		end
	end
	else
		cyc_done <= TRUE;

rf80386_pkg::STORE_IO:
	if (ihit) begin
		ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::IO;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {16'h0,sel} << ad[3:0];
		ftam_req.we <= HIGH;
		ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		ftam_req.data1 <= {128'd0,dat} << {ad[3:0],3'd0};
		adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		cyc_done <= FALSE;
		rty_wait <= 5'd0;
		tGoto(rf80386_pkg::STORE_IO_ACK);
	end
rf80386_pkg::STORE_IO_ACK:
	if (rty_i) begin
		rty_wait <= rty_wait + 2'd1;
		if (rty_wait==5'd31) begin
			rty_wait <= 5'd0;
			if (ihit) begin
				ea <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::IO;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= {16'h0,sel} << ad[3:0];
				ftam_req.we <= HIGH;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				ftam_req.data1 <= {128'd0,dat} << {ad[3:0],3'd0};
				adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
				cyc_done <= FALSE;
			end
		end
	end
	else begin
		if (|sel_shift[19:16])
			tGoto(rf80386_pkg::STORE_IO2);
		else
			tReturn();
	end
rf80386_pkg::STORE_IO2:
	if (ihit) begin
		ea <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::IO;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {16'h0,sel}>>(5'd16-ad[3:0]);
		ftam_req.we <= HIGH;
		ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		ftam_req.padr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		ftam_req.data1 <= {128'd0,dat} >> {5'd16-ad[3:0],3'd0};
		adr_o <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		rty_wait <= 5'd0;
		tGoto(rf80386_pkg::STORE_IO2_ACK);
	end
rf80386_pkg::STORE_IO2_ACK:
	if (rty_i) begin
		rty_wait <= rty_wait + 2'd1;
		if (rty_wait==5'd31) begin
			rty_wait <= 5'd0;
			if (ihit) begin
				ea <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::IO;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= {16'h0,sel}>>(5'd16-ad[3:0]);
				ftam_req.we <= HIGH;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				ftam_req.data1 <= {128'd0,dat} >> {5'd16-ad[3:0],3'd0};
				adr_o <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
			end
		end
	end
	else begin
		tReturn();
	end
