// ============================================================================
//        __
//   \\__/ o\    (C) 2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  int_que.sv
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

module int_queue(rst, clk, cpri, wr, i, rd, o, ov, full, empty, underflow);
input rst;
input clk;
input [3:0] cpri;				// current interrupt priority
input wr;
input [27:0] i;
input rd;
output [27:0] o;
output ov;							// output valid
output full;
output empty;
output underflow;
parameter DEPTH = 32;

reg did_rd;
reg [27:0] qo;					// victim buffer output
reg vic_datv;						// victim data valid
reg vic_rd, vic_wr;
wire irq_fifo_rd_rst_busy, irq_fifo_wr_rst_busy;
wire vic_rd_rst_busy, vic_wr_rst_busy;
wire vic_empty, vic_underflow;
wire irq_fifo_wr = (wr || !vic_empty) && !irq_fifo_wr_rst_busy;
wire [27:0] irq_fifo_data_in = wr ? i : qo;

   // xpm_fifo_sync: Synchronous FIFO
   // Xilinx Parameterized Macro, version 2022.2

   xpm_fifo_sync #(
      .CASCADE_HEIGHT(0),        // DECIMAL
      .DOUT_RESET_VALUE("0"),    // String
      .ECC_MODE("no_ecc"),       // String
      .FIFO_MEMORY_TYPE("auto"), // String
      .FIFO_READ_LATENCY(1),     // DECIMAL
      .FIFO_WRITE_DEPTH(DEPTH),   // DECIMAL
      .FULL_RESET_VALUE(0),      // DECIMAL
      .PROG_EMPTY_THRESH(10),    // DECIMAL
      .PROG_FULL_THRESH(10),     // DECIMAL
      .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
      .READ_DATA_WIDTH(28),      // DECIMAL
      .READ_MODE("std"),         // String
      .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_ADV_FEATURES("0707"), // String
      .WAKEUP_TIME(0),           // DECIMAL
      .WRITE_DATA_WIDTH(28),     // DECIMAL
      .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
   irq_fifo (
      .almost_empty(),
      .almost_full(),
      .data_valid(ov),
      .dbiterr(),
      .dout(o),
      .empty(empty),
      .full(full),
      .overflow(),
      .prog_empty(),
      .prog_full(),
      .rd_data_count(),
      .rd_rst_busy(irq_fifo_rd_rst_busy),
      .sbiterr(),
      .underflow(underflow),
      .wr_ack(),
      .wr_data_count(),
      .wr_rst_busy(irq_fifo_wr_rst_busy),
      .din(irq_fifo_data_in),
      .injectdbiterr(1'b0),
      .injectsbiterr(1'b0),
      .rd_en(rd & ~irq_fifo_rd_rst_busy),
      .rst(rst),
      .sleep(1'b0),
      .wr_clk(clk),
      .wr_en(irq_fifo_wr)
   );

   // xpm_fifo_sync: Synchronous FIFO
   // Xilinx Parameterized Macro, version 2022.2

   xpm_fifo_sync #(
      .CASCADE_HEIGHT(0),        // DECIMAL
      .DOUT_RESET_VALUE("0"),    // String
      .ECC_MODE("no_ecc"),       // String
      .FIFO_MEMORY_TYPE("auto"), // String
      .FIFO_READ_LATENCY(1),     // DECIMAL
      .FIFO_WRITE_DEPTH(16),	   // DECIMAL
      .FULL_RESET_VALUE(0),      // DECIMAL
      .PROG_EMPTY_THRESH(10),    // DECIMAL
      .PROG_FULL_THRESH(10),     // DECIMAL
      .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
      .READ_DATA_WIDTH(28),      // DECIMAL
      .READ_MODE("fwft"),         // String
      .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_ADV_FEATURES("0707"), // String
      .WAKEUP_TIME(0),           // DECIMAL
      .WRITE_DATA_WIDTH(28),     // DECIMAL
      .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
   vic_fifo (
      .almost_empty(),
      .almost_full(),
      .data_valid(),
      .dbiterr(),
      .dout(qo),
      .empty(vic_empty),
      .full(),
      .overflow(),
      .prog_empty(),
      .prog_full(),
      .rd_data_count(),
      .rd_rst_busy(vic_rd_rst_busy),
      .sbiterr(),
      .underflow(vic_underflow),
      .wr_ack(),
      .wr_data_count(),
      .wr_rst_busy(vic_wr_rst_busy),
      .din(o),
      .injectdbiterr(1'b0),
      .injectsbiterr(1'b0),
      .rd_en(vic_rd & ~vic_rd_rst_busy),
      .rst(rst),
      .sleep(1'b0),
      .wr_clk(clk),
      .wr_en(vic_wr & ~vic_wr_rst_busy)
   );

always_ff @(posedge clk)
	if (rst) did_rd <= 1'b0; else did_rd <= rd;
always_comb
	vic_datv = did_rd && o[27:24] <= cpri && !underflow;
always_comb
	vic_rd = !wr && !vic_empty;
always_comb
	vic_wr = wr && vic_datv;

endmodule
