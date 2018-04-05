`timescale 1ns/1ps
//Function:
//          1. Adjust the 256-bit input width to 24-bit output width
//          2. The clock at 256-bit side is 125MHz, and the clock at 24-bit side is 250MHz
module interface_256in_24out (
    input               rx_clock,
    input               rx_rst_n,

    input [255+32:0]    rx_data,
    input               rx_data_valid,
    output              rx_ready_out,

    input               tx_clock,
    input               tx_rst_n,
    output [23:0]       tx_data,
    output              tx_data_valid,
    input               tx_req_in
);

// l1_fifo signals
wire            l1_fifo_wr_clk;
wire            l1_fifo_wr_ena;
wire [255:0]    l1_fifo_din;
wire            l1_fifo_full;
wire            l1_fifo_pre_full;
wire            l1_fifo_rd_clk;
reg             l1_fifo_rd_ena;
wire [7:0]      l1_fifo_dout;
wire            l1_fifo_empty;

// l2_fifo signals
wire            l2_fifo_wr_clk;
wire            l2_fifo_wr_ena;
wire [7:0]      l2_fifo_din;
wire            l2_fifo_full;
wire            l2_fifo_rd_clk;
reg             l2_fifo_rd_ena;
wire [23:0]     l2_fifo_dout;
wire            l2_fifo_empty;

wire [8:0]      rx_data_vec[31:0];
wire [255:0]    rx_data_256bit;
wire [31:0]     rx_data_byte_valid;

//output preset_full
assign rx_ready_out = ~l1_fifo_pre_full;

assign rx_data_256bit = rx_data[287:32];
assign rx_data_byte_valid <= rx_data[31:0];
genvar var;
generate begin
    for (var = 0; var < 32; var = var + 1) begin
        assign l1_fifo_din[var*9 +: 9] = {rx_data[var*8 +: 8], rx_data_byte_valid[var]};
    end
end generate

assign l1_fifo_wr_ena = rx_data_valid;
assign l1_fifo_wr_clk = rx_clock;
assign l1_fifo_rd_clk = tx_clock;
assign l1_fifo_rd_ena = (~l1_fifo_empty & ~l2_fifo_full);
dcfifo_256inx128_8out l1_fifo (
    .data    (l1_fifo_din),    //  fifo_input.datain
    .wrreq   (l1_fifo_wr_ena),   //            .wrreq
    .rdreq   (l1_fifo_rd_ena),   //            .rdreq
    .wrclk   (l1_fifo_wr_clk),   //            .wrclk
    .rdclk   (l1_fifo_rd_clk),   //            .rdclk
    .q       (l1_fifo_dout),       // fifo_output.dataout
    .rdempty (l1_fifo_empty), //            .rdempty
    .wrfull  (l1_fifo_full)   //            .wrfull
);


assign l2_fifo_wr_clk = tx_clock;
assign l2_fifo_rd_clk = tx_clock;
assign l2_fifo_wr_ena = l1_fifo_dout[0];
assign l2_fifo_din = l1_fifo_dout[9:1];

assign l2_fifo_rd_ena = (~l2_fifo_empty & tx_req_in);
assign tx_data = l2_fifo_dout;
always @(posedge tx_clock) begin
    if (tx_rst_n) begin
        tx_data_valid <= 1'b0;
    end
    else begin
        tx_data_valid <= l2_fifo_rd_ena;
    end
end

dcfifo_8inx4096_24out l2_fifo (
    .data    (l2_fifo_din),    //  fifo_input.datain
    .wrreq   (l2_fifo_wr_ena),   //            .wrreq
    .rdreq   (l2_fifo_rd_ena),   //            .rdreq
    .wrclk   (l2_fifo_wr_clk),   //            .wrclk
    .rdclk   (l2_fifo_rd_clk),   //            .rdclk
    .q       (l2_fifo_dout),       // fifo_output.dataout
    .rdempty (l2_fifo_empty), //            .rdempty
    .wrfull  (l2_fifo_full)   //            .wrfull
);



endmodule