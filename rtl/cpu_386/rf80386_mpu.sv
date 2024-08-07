import const_pkg::*;
import fta_bus_pkg::*;
import bigfoot_pkg::*;

module rf80386_mpu(rst, clk, fta_req, fta_resp);
parameter CORENO = 1;
parameter CID=1;
input rst;
input clk;
output fta_cmd_request128_t fta_req;
input fta_cmd_response128_t fta_resp;

fta_cmd_request128_t ftaim_req;
fta_cmd_response128_t ftaim_resp;
fta_cmd_request128_t [1:0] ftadm_req;
fta_cmd_response128_t [1:0] ftadm_resp;
fta_cmd_request128_t ftatm_req;
fta_cmd_response128_t ftatm_resp;
fta_cmd_response128_t fta_resp1;
fta_cmd_request128_t fta_mmu_req;
fta_cmd_response128_t fta_mmu_sresp;
fta_cmd_response128_t fta_mmu_resp;

wire invce = 1'b0;
wire [31:0] snoop_adr = 32'h0;
wire snoop_v = 1'b0;
wire ic_invall = 1'b0;
wire ic_invline = 1'b0;
wire brtgtv = 1'b0;
wire icnop;
wire [15:0] ip_asid=16'h0;
wire [31:0] csip,pcsip;
wire [31:0] icpc;
wire ihito;
wire ihit;
ICacheLine ic_line_lo, ic_line_hi, ic_line_o, ic_dline;
reg [1023:0] ic_line;
wire ic_valid, ic_dvalid;
wire [31:0] ic_miss_adr;
wire [15:0] ic_miss_asid;
wire [1:0] ic_wway;
wire wr_ic;
wire [31:0] icdp = 32'h0;
wire ic_port;
reg [127:0] bundle;
wire pc_padr_v;

always_comb
	ic_line = {ic_line_hi.data,ic_line_lo.data};
always_comb
	bundle = ic_line >> {icpc[5:0],3'd0};

icache
#(.CORENO(CORENO),.CID(0))
uic1
(
	.rst(rst),
	.clk(clk),
	.ce(1'b1),
	.invce(invce),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid),
	.invall(ic_invall),
	.invline(ic_invline),
	.nop(brtgtv),
	.nop_o(icnop),
	.ip_asid(ip_asid),
	.ip({8'd0,csip}),
	.ip_o(icpc),
	.ihit_o(ihito),
	.ihit(ihit),
	.ic_line_hi_o(ic_line_hi),
	.ic_line_lo_o(ic_line_lo),
	.ic_valid(ic_valid),
	.miss_vadr(ic_miss_adr),
	.miss_asid(ic_miss_asid),
	.ic_line_i(ic_line_o),
	.wway(ic_wway),
	.wr_ic(wr_ic),
	.dp(icdp),
	.dp_asid(ip_asid),
	.dhit_o(),//ic_dhit),
	.dc_line_o(ic_dline),
	.dc_valid(ic_dvalid),
	.port(ic_port),
	.port_i(1'b0)
);
assign ic_dhit = 1'b1;

icache_ctrl
#(.CORENO(CORENO),.CID(0))
icctrl1
(
	.rst(rst),
	.clk(clk),
	.wbm_req(ftaim_req),
	.wbm_resp(ftaim_resp),
	.ftam_full(ftaim_resp.rty),
	.hit(ihit),
//	.tlb_v(pc_tlb_v),
//	.tlb_v(1'b1),
	.miss_vadr(ic_miss_adr),
	.miss_padr(pcsip),
//	.miss_padr(ic_miss_adr),
//	.miss_asid(tlb_pc_entry.vpn.asid),
	.miss_asid(ip_asid),
	.miss_padr_v(pc_padr_v),
	.wr_ic(wr_ic),
	.way(ic_wway),
	.line_o(ic_line_o),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid)
);

mmu #(.CID(4)) ummu (
	.rst(rst),
	.clk(clk),
	.paging_en(1'b1),
	.tlb_pmt_base(64'h0),
	.ic_miss_adr({8'h00,ic_miss_adr}),
	.ic_miss_asid(ip_asid),
	.vadr_ir(1'b0),
	.vadr_v(1'b0),
	.vadr_asid(16'h0),
	.tlb_entry0(),
	.tlb_pc_entry(),
	.padr(),
	.tlb0_v(),
	.pc_padr(pcsip),
	.pc_padr_v(pc_padr_v),
	.commit0_id(8'h0),
	.commit0_idv(1'b0),
	.commit1_id(8'h0),
	.commit1_idv(1'b0),
	.commit2_id(8'h0),
	.commit2_idv(1'b0),
	.commit3_id(8'h0),
	.commit3_idv(1'b0),
	.ftas_req(fta_req),
	.ftas_resp(fta_mmu_sresp),
	.ftam_req(fta_mmu_req),
	.ftam_resp(fta_mmu_resp),
	.fault_o(),
	.faultq_o(),
	.pe_fault_o(),
	.tlb_wr(),
	.tlb_way(),
	.tlb_entryno(),
	.tlb_entry()
);

rf80386 #(.CORENO(CORENO), .CID(1)) ucpu1
(
	.rst_i(rst),
	.clk_i(clk),
	.nmi_i(1'b0),
	.irq_i(1'b0),
	.csip(csip),
	.ibundle(bundle),
	.ihit(ihito),
	.ftam_req(ftadm_req[0]),
	.ftam_resp(ftadm_resp[0])
);

// External bus arbiter. Simple priority encoded.

always_comb
	ftatm_req <= 'd0;

always_comb
begin
	
	ftatm_resp = {$bits(fta_cmd_response128_t){1'd0}};
	ftaim_resp = {$bits(fta_cmd_response128_t){1'd0}};
	ftadm_resp[0] = {$bits(fta_cmd_response128_t){1'd0}};
	ftadm_resp[1] = {$bits(fta_cmd_response128_t){1'd0}};
	fta_mmu_resp = {$bits(fta_cmd_response128_t){1'd0}};

	// Setup to retry.
	fta_mmu_resp.rty = 1'b1;
	ftatm_resp.rty = 1'b1;
	ftaim_resp.rty = 1'b1;
	ftadm_resp[0].rty = 1'b1;
	ftadm_resp[1].rty = 1'b1;
	ftadm_resp[0].tid = ftadm_req[0].tid;
	ftadm_resp[1].tid = ftadm_req[1].tid;
		
	// Cancel retry if bus aquired.
	if (fta_mmu_req.cyc) begin
		fta_mmu_resp.rty = 1'b0;
		fta_mmu_resp.tid = 'd0;
	end
	else if (ftatm_req.cyc) begin
		ftatm_resp.rty = 1'b0;
		ftatm_resp.tid = 'd0;
	end
	else if (ftaim_req.cyc) begin
		ftaim_resp.rty = 1'b0;
		ftaim_resp.tid = 'd0;
	end
	else if (ftadm_req[0].cyc) begin
		ftadm_resp[0].rty = 1'b0;
		ftadm_resp[0].tid = 'd0;
	end
	else if (ftadm_req[1].cyc) begin
		ftadm_resp[1].rty = 1'b0;
		ftadm_resp[1].tid = 'd0;
	end

	// Route bus responses.
	case(fta_resp1.tid.channel)
	3'd0:	ftaim_resp = fta_resp1;
	3'd1:	ftadm_resp[0] = fta_resp1;
//	3'd2:	ftadm_resp[1] <= fta_resp1;
	3'd3:	ftatm_resp = fta_resp1;
	3'd4:	fta_mmu_resp = fta_resp1;
	default:	;	// response was not for us
	endcase
	
end

always_comb	//ff @(posedge clk)
	if (fta_mmu_req.cyc)
		fta_req <= fta_mmu_req;
	else if (ftatm_req.cyc)
		fta_req <= ftatm_req;
	else if (ftaim_req.cyc)
		fta_req <= ftaim_req;
	else if (ftadm_req[0].cyc)
		fta_req <= ftadm_req[0];
	else if (ftadm_req[1].cyc)
		fta_req <= ftadm_req[1];
	else
		fta_req <= {$bits(fta_cmd_request128_t){1'd0}};


fta_cmd_response128_t [1:0] resp_ch;

fta_respbuf #(.CHANNELS(2))
urb1
(
	.rst(rst),
	.clk(clk),
	.resp(resp_ch),
	.resp_o(fta_resp1)
);

always_ff @(posedge clk)
begin
	if (fta_req.cyc) begin
		if (fta_req.we) begin
			$display("Q+: Bus Write: %h <= %h", fta_req.padr, fta_req.data1);
		end
	end
	if (fta_resp.ack) begin
		$display("Q+: Bus ack: %h = %h", fta_resp.adr, fta_resp.dat);
	end
end

assign resp_ch[0] = fta_resp;
assign resp_ch[1] = fta_mmu_sresp;//ptable_resp;

endmodule
