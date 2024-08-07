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

rf80386_pkg::LOAD:
	if (ihit) begin
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
rf80386_pkg::LOAD_ACK:
	begin
		if (ack_i && ftam_resp.tid.tranid==tid) begin
			dat <= (ftam_resp.dat >> {ad[3:0],3'b0}) & ls_mask;
			if (|sel_shift[19:16])
				tGoto(rf80386_pkg::LOAD2);
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
		ea <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		tSetTid();
		ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {12'h0,sel_shift[19:16]};
		ftam_req.we <= LOW;
		ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		ftam_req.padr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		adr_o <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		cyc_done <= FALSE;
		rty_wait <= 5'd0;
		tGoto(rf80386_pkg::LOAD2_ACK);
	end
rf80386_pkg::LOAD2_ACK:
	begin
		if (ftam_resp.ack && ftam_resp.tid.tranid==tid) begin
			dat <= (dat | (ftam_resp.dat << {5'd16-ad[3:0],3'b0})) & ls_mask;
			tReturn();
		end
		else if (rty_i) begin
			rty_wait <= rty_wait + 2'd1;
			if (rty_wait==5'd31) begin
				rty_wait <= 5'd0;
				ea <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				tSetTid();
				ftam_req.cmd <= fta_bus_pkg::CMD_LOAD;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::CLASSIC;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= {12'h0,sel_shift[19:16]};
				ftam_req.we <= LOW;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				adr_o <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				cyc_done <= FALSE;
			end
		end
		else
			cyc_done <= TRUE;
	end

rf80386_pkg::STORE:
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
		ftam_req.data1 <= {128'd0,dat} << {ad[3:0],3'd0};
		adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};
		cyc_done <= FALSE;
		rty_wait <= 5'd0;
		tGoto(rf80386_pkg::STORE_ACK);
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
					ftam_req.data1 <= {128'd0,dat} << {ad[3:0],3'd0};
					adr_o <= {ad[$bits(ad)-1:LSBIT],{LSBIT{1'd0}}};;
					cyc_done <= FALSE;
				end
			end
		end
		else begin
			if (|sel_shift[19:16])
				tGoto(rf80386_pkg::STORE2);
			else
				tReturn();
		end
	end
rf80386_pkg::STORE2:
	if (ihit) begin
		ea <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		tSetTid();
		ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {12'h0,sel_shift[19:16]};
		ftam_req.we <= HIGH;
		ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		ftam_req.padr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		ftam_req.data1 <= {128'd0,dat} >> {5'd16-ad[3:0],3'd0};
		adr_o <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
		rty_wait <= 5'd0;
		tGoto(rf80386_pkg::STORE2_ACK);
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
				ea <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				tSetTid();
				ftam_req.cmd <= fta_bus_pkg::CMD_STORE;
				ftam_req.blen <= 6'd0;
				ftam_req.bte <= fta_bus_pkg::LINEAR;
				ftam_req.cti <= fta_bus_pkg::CLASSIC;
				ftam_req.cyc <= HIGH;
				ftam_req.stb <= HIGH;
				ftam_req.sel <= {12'h0,sel_shift[19:16]};
				ftam_req.we <= HIGH;
				ftam_req.vadr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				ftam_req.padr <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
				ftam_req.data1 <= {128'd0,dat} >> {5'd16-ad[3:0],3'd0};
				adr_o <= {ad[$bits(ad)-1:LSBIT]+2'd1,{LSBIT{1'd0}}};
			end
		end
	end
	else
		tReturn();

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
		ftam_req.sel <= sel_shift[15:0];
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
				ftam_req.sel <= sel_shift[15:0];
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
		ftam_req.sel <= {12'h0,sel_shift[19:16]};
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
				ftam_req.sel <= {12'h0,sel_shift[19:16]};
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
		ftam_req.sel <= sel_shift[15:0];
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
				ftam_req.sel <= sel_shift[15:0];
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
		ftam_req.sel <= {12'h0,sel_shift[19:16]};
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
				ftam_req.sel <= {12'h0,sel_shift[19:16]};
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
