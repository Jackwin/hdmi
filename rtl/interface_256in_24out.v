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
    output reg [23:0]       tx_data,
    output reg             tx_data_valid,
    input               tx_req_in
);

// l1_fifo signals
wire            l1_fifo_wr_clk;
wire            l1_fifo_wr_ena;
wire [255+32:0]    l1_fifo_din;
wire            l1_fifo_full;
wire            l1_fifo_pre_full;
wire            l1_fifo_rd_clk;
wire            l1_fifo_rd_ena;
//wire [8:0]      l1_fifo_dout;
wire [17:0]      l1_fifo_dout;

wire            l1_fifo_empty;
wire [6:0]      l1_fifo_wr_used;
wire [10:0]     l1_fifo_rd_used;
reg             l1_fifo_rd_valid;
// l2_fifo signals
wire            l2_fifo_wr_ena;
//wire [7:0]      l2_fifo_din;
wire [15:0]      l2_fifo_din;
wire            l2_fifo_full;
wire            l2_fifo_clk;
wire            l2_fifo_rd_ena;
wire [15:0]     l2_fifo_dout;
reg [15:0]      l2_fifo_dout_r1;
wire            l2_fifo_empty;
reg             l2_fifo_dout_valid;
wire [12:0]     l2_fifo_used;

wire [255:0]    rx_data_256bit;
wire [31:0]     rx_data_byte_valid;

reg [23:0]      tx_data_r;
reg             tx_data_valid_r;

//output preset_full
assign rx_ready_out = (l1_fifo_wr_used < 7'd125);

assign rx_data_256bit = rx_data[287:32];
assign rx_data_byte_valid = rx_data[31:0];


genvar var_i;
generate

    for (var_i = 0; var_i < 16; var_i = var_i + 1) begin :l1_fifo_din_assignment
        assign l1_fifo_din[((var_i + 1)*18 - 1) -: 18] = {rx_data_256bit[((32 - var_i * 2)*8 - 1) -: 8], rx_data_byte_valid[31 - var_i * 2],
                                                          rx_data_256bit[((32 - var_i * 2 - 1)*8 - 1) -: 8], rx_data_byte_valid[31 - var_i * 2 - 1]};
    end
    /*
    for (var_i = 0; var_i < 32; var_i = var_i + 1) begin :l1_fifo_din_assignment
        assign l1_fifo_din[((var_i + 1)*9 - 1) -: 9] = {rx_data_256bit[((32 - var_i)*8 - 1) -: 8], rx_data_byte_valid[31 - var_i]};

    end
    */
endgenerate

assign l1_fifo_wr_ena = rx_data_valid;
assign l1_fifo_wr_clk = rx_clock;
assign l1_fifo_rd_clk = tx_clock;
assign l1_fifo_rd_ena = (~l1_fifo_empty & ~l2_fifo_full);
//dcfifo_288inx128_18out
dcfifo_288inx128_18out l1_fifo (
    .data    (l1_fifo_din),    //  fifo_input.datain
    .wrreq   (l1_fifo_wr_ena),   //            .wrreq
    .wrusedw (l1_fifo_wr_used),
    .rdreq   (l1_fifo_rd_ena),   //            .rdreq
    .wrclk   (l1_fifo_wr_clk),   //            .wrclk
    .rdclk   (l1_fifo_rd_clk),   //            .rdclk
    .q       (l1_fifo_dout),       // fifo_output.dataout
    .rdempty (l1_fifo_empty), //            .rdempty
    .rdusedw (l1_fifo_rd_used),
    .wrfull  (l1_fifo_full)   //            .wrfull
);


assign l2_fifo_clk = tx_clock;
always @(posedge l1_fifo_rd_clk) begin
    if (~tx_rst_n) begin
        l1_fifo_rd_valid <= 1'b0;
    end
    else begin
        l1_fifo_rd_valid <= l1_fifo_rd_ena;
    end
end

assign l2_fifo_wr_ena = l1_fifo_rd_valid ? (l1_fifo_dout[0] & l1_fifo_dout[9]): 1'b0;
assign l2_fifo_din = {l1_fifo_dout[17:10], l1_fifo_dout[8:1]};

assign l2_fifo_rd_ena = (~l2_fifo_empty & tx_req_in);
//assign tx_data = l2_fifo_dout;
always @(posedge tx_clock) begin
    if (~tx_rst_n) begin
        l2_fifo_dout_valid <= 1'b0;
    end
    else begin
        l2_fifo_dout_valid <= l2_fifo_rd_ena;
    end
end

reg [1:0]   l2_rd_cnt;

always @(posedge l2_fifo_clk) begin
    if(~tx_rst_n) begin
         l2_rd_cnt <= 0;
         l2_fifo_dout_r1 <= 'h0;
    end else begin
        if (l2_fifo_dout_valid) begin
            if (l2_rd_cnt == 2'd2) begin
                l2_rd_cnt <= 2'd0;
            end
            else begin
                l2_rd_cnt <= l2_rd_cnt + 1'd1;
            end
            l2_fifo_dout_r1 <= l2_fifo_dout;
        end
    end
end

// The start address in DDR3 must be at even address, otherwise it's complivated to align with 16-bit
always @* begin
    tx_data_valid_r <= 1'b0;
    if (l2_fifo_dout_valid & l2_rd_cnt == 2'd1) begin
        tx_data_r = {l2_fifo_dout_r1,l2_fifo_dout[15:8]};
        tx_data_valid_r <= 1'b1;
    end
    else if (l2_fifo_dout_valid & l2_rd_cnt == 2'd2) begin
        tx_data_r = {l2_fifo_dout_r1[7:0], l2_fifo_dout};
        tx_data_valid_r <= 1'b1;
    end
    else begin
        tx_data_r <= 0;
    end
end

always @(posedge tx_clock) begin
    tx_data <= tx_data_r;
    tx_data_valid <= tx_data_valid_r;
end

//dcfifo_16inx4096_16out
scfifo_16inx8192 l2_fifo (
    .data    (l2_fifo_din),    //  fifo_input.datain
    .wrreq   (l2_fifo_wr_ena),   //            .wrreq
    .rdreq   (l2_fifo_rd_ena),   //            .rdreq
    .clock   (l2_fifo_clk),   //            .wrclk
    .q       (l2_fifo_dout),       // fifo_output.dataout
    .usedw   (l2_fifo_used),
    .empty (l2_fifo_empty), //            .rdempty
    .full  (l2_fifo_full)   //            .wrfull
);



endmodule