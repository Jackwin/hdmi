`timescale 1ns/1ps

module pingpongFIFO (
    input           rx_clk,
    input           rx_rst_n,
    input [23:0]    rx_data,
    input           rx_data_valid
    output          rx_ready_out,

    input           tx_clk,
    input           tx_rst_n,
    input           tx_read_in,
    output          tx_data_ready_out,
    output [23:0]   tx_data,
    output          tx_valid
);

// ping_fifo signals
wire            ping_fifo_wr_clk;
wire            ping_fifo_wr_ena;
wire [255:0]    ping_fifo_din;
wire            ping_fifo_full;
wire            ping_fifo_rd_clk;
reg             ping_fifo_rd_ena;
wire [7:0]      ping_fifo_dout;
wire            ping_fifo_empty;
wire [7:0]      ping_fifo_used;
reg             ping_fifo_dout_valid;
reg             ping_fifo_rx_ready;
wire            ping_fifo_tx_ready;

// pong_fifo signals
wire            pong_fifo_wr_clk;
wire            pong_fifo_wr_ena;
wire [7:0]      pong_fifo_din;
wire            pong_fifo_full;
wire            pong_fifo_rd_clk;
reg             pong_fifo_rd_ena;
wire [23:0]     pong_fifo_dout;
wire            pong_fifo_empty;
wire [7:0]      pong_fifo_used;
reg             pong_fifo_dout_valid;
reg             pong_fifo_rx_ready;
wire            pong_fifo_tx_ready;

reg [1:0]       wr_state;
reg [6:0]       wr_cnt;
reg [1:0]       rd_state;
reg [6:0]       rd_cmt;
//
reg [23:0]      rx_data_r;
reg             rx_data_valid_r;
localparam WR_IDLE = 2'd0,
            WR_PING = 2'd1,
            WR_PONG = 2'd2;
            WR_END = 2'd3;

localparam RD_IDLE = 2'd0,
            RD_PING = 2'd1,
            RD_PONG = 2'd2,
            RD_END = 2'd3;

assign ping_fifo_wr_clk = rx_clk;
assign ping_fifo_rd_clk = tx_clk;
assign pong_fifo_wr_clk = tx_clk;
assign pong_fifo_rd_clk = tx_clk;
// Because of the inertia (fifo output is one clock delay than the read_enable), brake ahead.
//assign rx_ready_out = ((ping_fifo_used < 8'd161) | (pong_fifo_used < 8'd161));
assign rx_ready_out = ping_fifo_ready | pong_fifo_ready;

assign tx_data_ready_out = ~ping_fifo_empty | ~pong_fifo_empty;
always @(posedge rx_clk) begin
    rx_data_r <= rx_data;
    rx_data_valid_r <= rx_data_valid;
end

//TODO: check the ping_fifo_ready's effect of the input data
always @(posedge rx_clk) begin
    if (~rx_rst_n) begin
        ping_fifo_rx_ready <= 1'b1;
    end
    else if (ping_fifo_empty) begin
        ping_fifo_rx_ready <= 1'b1;
    end
    else if (wr_cnt == 7'd78 && state == WR_PING) begin
        ping_fifo_rx_ready <= 1'b0;
    end
end

always @(posedge rx_clk) begin
    if (~rx_rst_n) begin
        pong_fifo_rx_ready <= 1'b1;
    end
    else if (pong_fifo_empty) begin
        pong_fifo_rx_ready <= 1'b1;
    end
    else if (wr_cnt == 7'd78 && state == WR_PONG) begin
        pong_fifo_rx_ready <= 1'b0;
    end
end

assign ping_fifo_tx_ready = ~ping_fifo_rx_ready;
assign pong_fifo_tx_ready = ~pong_fifo_rx_ready;
//---------------------------------------------------
always @(posedge rx_clk) begin
    if(~rx_rst_n) begin
        state <= WR_IDLE;
        wr_cnt <= 'h0;
    end else begin
        case(wr_state)
            WR_IDLE: begin
                if (rx_data_valid) begin
                    // Make sure there is 80 address space left
                    if (ping_fifo_ready) begin
                        wr_state <= WR_PING;
                    end
                    else if (pong_fifo_ready) begin
                        wr_state <= WR_PONG;
                    end
                end
            end
            WR_PING: begin
                wr_cnt <= wr_cnt + 1'd1;
                if (wr_cnt == 7'd79 && pong_fifo_ready) begin
                    wr_state <= WR_PONG;
                    wr_cnt <= 'h0;
                end
                else if (wr_cnt == 7'd79 && ~pong_fifo_ready) begin
                    wr_state <= IDLE;
                    wr_cnt <= 'h0;
                end
            end
            WR_PONG: begin
                wr_cnt <= wr_cnt + 1'd1;
                if (wr_cnt == 7'd79 && ping_fifo_ready) begin
                    wr_state <= WR_PING;
                    wr_cnt <= 'h0;
                end
                else if (wr_cnt == 7'd79 && ~ping_fifo_ready) begin
                    wr_state <= WR_IDLE;
                    wr_cnt <= 'h0;
                end
            end
            default: wr_state <= WR_IDLE;
        endcase // wr_state
    end
end

always @* begin
    case(wr_state)
        WR_IDLE: begin
            ping_fifo_din = 'h0;
            ping_fifo_wr_ena = 1'b0;
            pong_fifo_din = 'h0;
            pong_fifo_wr_ena = 1'b0;
        end
        WR_PING: begin
            ping_fifo_din = rx_data_r;
            ping_fifo_wr_ena = rx_data_valid_r;
        end
        WR_PONG: begin
            pong_fifo_din = rx_data_r;
            pong_fifo_wr_ena = rx_data_valid_r;
        end
        default: begin
            ping_fifo_din = 'h0;
            ping_fifo_wr_ena = 1'b0;
            pong_fifo_din = 'h0;
            pong_fifo_wr_ena = 1'b0;
        end
    endcase // wr_state
end

always @(posedge tx_clk) begin
    if(~tx_rst_n) begin
        rd_state <= RD_IDLE;
    end else begin
        case(rd_state)
            RD_IDLE: begin
                if (ping_fifo_tx_ready) begin
                    rd_state <= RD_PING;
                end
                else if (pong_fifo_tx_ready) begin
                    rd_state <= RD_PONG;
                end
            end
            RD_PING: begin
                if (pong_fifo_tx_ready) begin
                    rd_state <= RD_PONG;
                end
                else  begin
                    rd_state <= RD_IDLE;
                end
            end
            RD_PONG: begin
                if (ping_fifo_tx_ready) begin
                    rd_state <= RD_PING;
                end
                else begin
                    rd_state <= RD_IDLE;
                end
            end
            default: rd_state <= RD_IDLE;
        endcase
    end
end

always @* begin
    case(rd_state)
        RD_IDLE: begin
            ping_fifo_rd_ena = 1'b0;
            pong_fifo_rd_ena = 1'b0;
        end
        RD_PING: begin
            ping_fifo_rd_ena = tx_read_in;
        end
        RD_PONG: begin
            pong_fifo_rd_ena = tx_read_in;
        end
        default: begin
            ping_fifo_rd_ena = 1'b0;
            pong_fifo_rd_ena = 1'b0;
        end
    endcase // rd_state
end

always @(posedge tx_clk) begin
    ping_fifo_dout_valid <= ping_fifo_rd_ena;
    pong_fifo_dout_valid <= pong_fifo_rd_ena;
end

always @(posedge tx_clk) begin
    if (ping_fifo_dout_valid) begin
        tx_data <= ping_fifo_dout;
    end
    else if (pong_fifo_dout_valid) begin
        tx_data <= pong_fifo_dout;
    end
end

dcfifo_24inx128 ping_fifo (
    .data    (ping_fifo_din),    //  fifo_input.datain
    .wrreq   (ping_fifo_wr_ena),   //            .wrreq
    .rdreq   (ping_fifo_rd_ena),   //            .rdreq
    .wrclk   (ping_fifo_wr_clk),   //            .wrclk
    .rdclk   (ping_fifo_rd_clk),   //            .rdclk
    .q       (ping_fifo_dout),       // fifo_output.dataout
    .rdempty (ping_fifo_empty), //            .rdempty
    .wrfull  (ping_fifo_full)   //            .wrfull
);

dcfifo_24inx128 pong_fifo (
    .data    (pong_fifo_din),    //  fifo_input.datain
    .wrreq   (pong_fifo_wr_ena),   //            .wrreq
    .rdreq   (pong_fifo_rd_ena),   //            .rdreq
    .wrclk   (pong_fifo_wr_clk),   //            .wrclk
    .rdclk   (pong_fifo_rd_clk),   //            .rdclk
    .q       (pong_fifo_dout),       // fifo_output.dataout
    .rdempty (pong_fifo_empty), //            .rdempty
    .wrfull  (pong_fifo_full)   //            .wrfull
);

endmodule