`timescale 1ns/1ps

module pingpongFIFO (
    input           rx_clk,
    input           rx_rst_n,
    input [23:0]    rx_data,
    input           rx_data_valid,
    output          rx_ready_out,

    input           tx_clk,
    input           tx_rst_n,
    input           tx_read_in,
    output          tx_data_ready_out,
    output reg [23:0]   tx_data,
    output reg         tx_valid
);

// ping_fifo signals
wire            ping_fifo_wr_clk;
reg             ping_fifo_wr_ena;
reg [23:0]      ping_fifo_din;
wire            ping_fifo_full;
wire            ping_fifo_rd_clk;
reg             ping_fifo_rd_ena;
wire [23:0]      ping_fifo_dout;
wire            ping_fifo_empty;
reg             ping_fifo_dout_valid;
reg             ping_fifo_rx_ready;
wire             ping_fifo_tx_ready;
wire [8:0]      ping_fifo_wr_used;
wire [8:0]      ping_fifo_rd_used;
reg             ping_fifo_wr_done;
wire             ping_fifo_rd_done;

// pong_fifo signals
wire            pong_fifo_wr_clk;
reg            pong_fifo_wr_ena;
reg [23:0]      pong_fifo_din;
wire            pong_fifo_full;
wire            pong_fifo_rd_clk;
reg             pong_fifo_rd_ena;
wire [23:0]     pong_fifo_dout;
wire            pong_fifo_empty;
reg             pong_fifo_dout_valid;
reg            pong_fifo_rx_ready;
wire            pong_fifo_tx_ready;
wire [8:0]      pong_fifo_wr_used;
wire [8:0]      pong_fifo_rd_used;
reg             pong_fifo_wr_done;
wire             pong_fifo_rd_done;

reg [1:0]       wr_state;
reg [6:0]       wr_cnt;
reg [1:0]       rd_state;
reg [7:0]       rd_cnt;
//
reg [23:0]      rx_data_r;
reg             rx_data_valid_r;

localparam WR_IDLE = 2'd0,
            WR_PING = 2'd1,
            WR_PONG = 2'd2,
            WR_END = 2'd3;

localparam RD_IDLE = 2'd0,
            RD_PING = 2'd1,
            RD_PONG = 2'd2,
            RD_END = 2'd3;

assign ping_fifo_wr_clk = rx_clk;
assign ping_fifo_rd_clk = tx_clk;
assign pong_fifo_wr_clk = rx_clk;
assign pong_fifo_rd_clk = tx_clk;
// Because of the inertia (fifo output is one clock delay than the read_enable), brake ahead.
//assign rx_ready_out = ((ping_fifo_used < 8'd161) | (pong_fifo_used < 8'd161));
assign rx_ready_out = ping_fifo_rx_ready | pong_fifo_rx_ready;

assign tx_data_ready_out = ~ping_fifo_empty | ~pong_fifo_empty;
always @(posedge rx_clk) begin
    rx_data_r <= rx_data;
    rx_data_valid_r <= rx_data_valid;
end

//TODO: check the ping_fifo_ready's effect of the input data
//rx_clk 250M

always @(posedge rx_clk) begin
    if (~rx_rst_n) begin
        ping_fifo_rx_ready <= 1'b1;
        ping_fifo_wr_done <= 1'b0;
    end
    else if (ping_fifo_rd_done) begin
        ping_fifo_rx_ready <= 1'b1;
        ping_fifo_wr_done <= 1'b0;
    end
    else if (wr_cnt == 7'd77 & rx_data_valid & (wr_state == WR_PING)) begin
        ping_fifo_rx_ready <= 1'b0;
        ping_fifo_wr_done <= 1'b1;
    end
end

//assign ping_fifo_rx_ready = ping_fifo_wr_used < 9'd479 & ~ping_fifo_full;
//assign pong_fifo_rx_ready = pong_fifo_wr_used < 9'd479 & ~pong_fifo_full;
//assign ping_fifo_tx_ready = ping_fifo_rd_used > 9'd79;
//assign pong_fifo_tx_ready = pong_fifo_rd_used > 9'd79;
assign ping_fifo_tx_ready = ping_fifo_wr_done;
assign pong_fifo_tx_ready = pong_fifo_wr_done;
always @(posedge rx_clk) begin
    if (~rx_rst_n) begin
        pong_fifo_rx_ready <= 1'b1;
        pong_fifo_wr_done <= 1'b0;
    end
    else if (pong_fifo_rd_done) begin
        pong_fifo_rx_ready <= 1'b1;
        pong_fifo_wr_done <= 1'b0;
    end
    else if (wr_cnt == 7'd77 && (wr_state == WR_PONG)) begin
        pong_fifo_rx_ready <= 1'b0;
        pong_fifo_wr_done <= 1'b1;
    end
end

//---------------------------------------------------
always @(posedge rx_clk) begin
    if(~rx_rst_n) begin
        wr_state <= WR_IDLE;
        wr_cnt <= 'h0;
    end else begin
        case(wr_state)
            WR_IDLE: begin
                if (rx_data_valid) begin
                    // Make sure there is 80 address space left
                    if (ping_fifo_rx_ready) begin
                        wr_state <= WR_PING;
                    end
                    else if (pong_fifo_rx_ready) begin
                        wr_state <= WR_PONG;
                    end
                end
            end
            WR_PING: begin
                if (rx_data_valid) begin
                    wr_cnt <= wr_cnt + 1'd1;
                end
                // 使用剩余空间判断
                //if (wr_cnt == 7'd79 && pong_fifo_rx_ready && rx_data_valid) begin
               if (wr_cnt == 7'd79 && pong_fifo_rx_ready && rx_data_valid) begin
                    wr_state <= WR_PONG;
                    wr_cnt <= 'h0;
                end
                else if (wr_cnt == 7'd79 && ~pong_fifo_rx_ready) begin
                    wr_state <= WR_IDLE;
                    wr_cnt <= 'h0;
                end
            end
            WR_PONG: begin
                if (rx_data_valid) begin
                    wr_cnt <= wr_cnt + 1'd1;
                end
                if (wr_cnt == 7'd79 && ping_fifo_rx_ready && rx_data_valid) begin
                    wr_state <= WR_PING;
                    wr_cnt <= 'h0;
                end
                else if (wr_cnt == 7'd79 && ~ping_fifo_rx_ready) begin
                    wr_state <= WR_IDLE;
                    wr_cnt <= 'h0;
                end
            end
            default: wr_state <= WR_IDLE;
        endcase // wr_state
    end
end

always @* begin
    ping_fifo_din = 'h0;
    ping_fifo_wr_ena = 1'b0;
    pong_fifo_din = 'h0;
    pong_fifo_wr_ena = 1'b0;
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
            pong_fifo_wr_ena = 1'b0;
        end
        WR_PONG: begin
            pong_fifo_din = rx_data_r;
            ping_fifo_wr_ena = 1'b0;
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
                if (rd_cnt == 7'd79 & pong_fifo_tx_ready) begin
                    //if (pong_fifo_wr_done) begin
                    rd_state <= RD_PONG;
                end

                else if (rd_cnt == 7'd79 & ~pong_fifo_tx_ready)  begin
                    rd_state <= RD_IDLE;
                end
            end
            RD_PONG: begin
                if (rd_cnt == 7'd79 & ping_fifo_tx_ready) begin
                   // if (ping_fifo_wr_done) begin
                    rd_state <= RD_PING;
                end
                else if (rd_cnt == 7'd79 & ~ping_fifo_tx_ready) begin
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
            pong_fifo_rd_ena = 1'b0;
        end
        RD_PONG: begin
            pong_fifo_rd_ena = tx_read_in;
            ping_fifo_rd_ena = 1'b0;
        end
        default: begin
            ping_fifo_rd_ena = 1'b0;
            pong_fifo_rd_ena = 1'b0;
        end
    endcase // rd_state
end

//Count the read
always @(posedge tx_clk) begin
    if(~tx_rst_n) begin
        rd_cnt <= 0;
    end else begin
        if (ping_fifo_dout_valid | pong_fifo_dout_valid) begin
            rd_cnt <= rd_cnt + 1'd1;
        end
        else begin
            rd_cnt <= 'h0;
        end
    end
end
assign ping_fifo_rd_done = (ping_fifo_dout_valid & (rd_cnt == 7'd79));
assign pong_fifo_rd_done = (pong_fifo_dout_valid & (rd_cnt == 7'd79));
//----------------------------------

always @(posedge tx_clk) begin
    ping_fifo_dout_valid <= ping_fifo_rd_ena;
    pong_fifo_dout_valid <= pong_fifo_rd_ena;
end

always @(posedge tx_clk) begin
    if (ping_fifo_dout_valid) begin
        tx_valid <= ping_fifo_dout_valid;
        tx_data <= ping_fifo_dout;
    end
    else if (pong_fifo_dout_valid) begin
        tx_valid <= pong_fifo_dout_valid;
        tx_data <= pong_fifo_dout;
    end
    else begin
        tx_valid <= 1'b0;
    end
end

reg [6:0]   tx_data_cnt;

always @(posedge tx_clk) begin
    if (~tx_rst_n) begin
        tx_data_cnt <= 'h0;
    end
    else begin
        if (tx_valid) begin
            tx_data_cnt <= tx_data_cnt + 1'd1;
        end
        else begin
            tx_data_cnt <= 'h0;
        end
    end
end

dcfifo_24inx512 ping_fifo (
    .data    (ping_fifo_din),    //  fifo_input.datain
    .wrreq   (ping_fifo_wr_ena),   //            .wrreq
    .wrusedw (ping_fifo_wr_used),
    .rdreq   (ping_fifo_rd_ena),   //            .rdreq
    .rdusedw (ping_fifo_rd_used),
    .wrclk   (ping_fifo_wr_clk),   //            .wrclk
    .rdclk   (ping_fifo_rd_clk),   //            .rdclk
    .q       (ping_fifo_dout),       // fifo_output.dataout
    .rdempty (ping_fifo_empty), //            .rdempty
    .wrfull  (ping_fifo_full)   //            .wrfull
);

dcfifo_24inx512 pong_fifo (
    .data    (pong_fifo_din),    //  fifo_input.datain
    .wrreq   (pong_fifo_wr_ena),   //            .wrreq
    .wrusedw (pong_fifo_wr_used),
    .rdreq   (pong_fifo_rd_ena),   //            .rdreq
    .rdusedw (pong_fifo_rd_used),
    .wrclk   (pong_fifo_wr_clk),   //            .wrclk
    .rdclk   (pong_fifo_rd_clk),   //            .rdclk
    .q       (pong_fifo_dout),       // fifo_output.dataout
    .rdempty (pong_fifo_empty), //            .rdempty
    .wrfull  (pong_fifo_full)   //            .wrfull
);

endmodule