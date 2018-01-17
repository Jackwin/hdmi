module pattern_fetch_send (
    input           pixel_clk,
    input           pixel_rst_n,

    input [11:0]    pixel_x,
    input [11:0]    pixel_y,
    input           pixel_de,
    input           pixel_hs,
    input           pixel_vs,
    input [11:0]    image_width,
    input [11:0]    image_height,
    input [1:0]     image_color,
    // Interface to HDMI chip
    output          gen_de,
    output          gen_hs,
    output          gen_vs,
    output [7:0]    gen_r,
    output [7:0]    gen_g,
    output [7:0]    gen_b,

    // DDR3 interface
    input           ddr_emif_clk,
    input           ddr_emif_rst_n,
    input           ddr_emif_ready,
    input [255:0]   ddr_emif_read_data,
    input           ddr_emif_rddata_valid,

    output          ddr_emif_read,
    output          ddr_emif_write,
    output [21:0]   ddr_emif_addr,
    output [255:0]  ddr_emif_write_data,
    output [321:0]  ddr_emif_byte_enable,
    output [4:0]    ddr_emif_burst_count

);


localparam  DDR3_IDLE = 3'd0,
            DDR3_RD_HEAD = 3'd1,
            DDR3_RD_HEAD_WAIT = 3'd2,
            DDR3_RD_BODY = 3'd3,
            DDR3_RD_BODY_WAIT = 3'd4;

// ------------------------------------- DDR3 read operation ---------------------------------------
// Pattern signals
reg [31:0]  pat_h_pix, pat_v_pix, pat_total_pix;
reg [31:0]  pat_num, pat_fill_size;
reg [31:0]  pat_start_addr, pat_end_addr;
reg [31:0]  pat_rsv;

reg [31:0]  pat_cnt;
wire [31:0] pat_total_pix_w;
// The times of reading one-pattern data from DDR3
reg [23:0]  pat_read_ddr3_times;

reg [2:0]   ddr3_rd_cs, ddr3_rd_state;

reg         ddr3_rd_start;
reg         ddr3_rd;
reg [21:0]  ddr3_rd_addr;

wire        ddr3_rddata_valid;
wire [255:0]ddr3_rddata;

wire        fifo_wr_clk, fifo_rd_clk;
wire        fifo_wr_ena, fifo_full;
wire        fifo_empty;
reg         fifo_rd_ena;
wire [255:0]fifo_wr_data, fifo_rd_data;


assign ddr3_rddata = ddr_emif_read_data;
assign ddr3_rddata_valid = ddr_emif_rddata_valid;

assign fifo_wr_ena = ddr3_rddata_valid;
assign fifo_wr_data = ddr3_rddata;

assign pat_total_pix_w = ddr3_rddata[191:159];

always @(posedge ddr_emif_clk or negedge ddr_emif_rst_n) begin
    if(~ddr_emif_rst_n) begin
        ddr3_rd <= 0;
        ddr3_rd_addr <= 0;
        pat_read_ddr3_times <= 0;
    end else begin
         case (ddr3_rd_state)
            DDR3_IDLE: begin
                ddr3_rd_addr <= 0;
                ddr3_rd <= 1'b1;
                if (ddr3_rd_start) ddr3_rd_state <= DDR3_RD_HEAD;
            end
            DDR3_RD_HEAD: begin
                if (!fifo_full && pat_cnt!= 0) begin
                    ddr3_rd <= 1'b1;
                    ddr3_addr <= 22'h0;
                    ddr3_rd_state <= DDR3_RD_HEAD_WAIT;
                end
            end
            // Wait valid rddata
            DDR3_RD_HEAD_WAIT: begin
                ddr3_rd <= 1'b0;
                if (ddr3_rddata_valid) begin

                    ddr3_rd_state <= DDR3_RD_BODY;
                    ddr3_addr <= ddr3_addr + 1'd1;
                    // Acquire the total read times for one pattern, and get 256-bit every read operation
                    pat_read_ddr3_times <= pat_total_pix_w[31:9] + (|pat_total_pix_w[7:0]);
                end
            end
            DDR3_RD_BODY: begin
                ddr3_rd <= 1'b1;
                ddr3_rd_state <= DDR3_RD_BODY_WAIT;
            end
            DDR3_RD_BODY_WAIT: begin
                ddr3_rd <= 1'b0;
                if (ddr3_rddata_valid) begin
                    if (pat_read_ddr3_times == 'h0) begin
                        ddr3_rd_state <= DDR3_IDLE;
                    end
                    else begin
                        ddr3_addr <= ddr3_addr + 1'd1;
                        ddr3_rd_state <= DDR3_RD_BODY;
                        pat_read_ddr3_times <= pat_read_ddr3_times - 1'd1;
                    end
                end
            end
            default :begin
                ddr3_rd_addr <= 0;
                ddr3_rd <= 1'b1;
                ddr3_rd_state <= DDR3_IDLE;
            end
         endcase
    end
end

// ------------------------------------- Transfer pixel ---------------------------------------

localparam  PAT_TX_IDLE = 3'd0,
            PAT_TX_HEAD = 3'd1,
            PAT_TX_HEAD_WAIT = 3'd2,
            PAT_TX_BODY = 3'd3,
            PAT_TX_BODY_WAIT = 3'd4,
            PAT_TX_TAIL = 3'd5;
            PAT_TX_TAIL_WAIT = 3'd6;
reg [2:0]   pat_tx_state;
reg         delay_cnt;

always @(posedge pixel_clk or negedge pixel_rst_n) begin
    if(~pixel_rst_n) begin
        pat_tx_state <= PAT_TX_IDLE;
        fifo_rd_ena <= 1'b0;
        delay_cnt <= 'h0;
        {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, pat_fill_size, pat_start_addr, pat_end_addr, pat_rsv} <= 'h0;
    end else begin
         case(pat_tx_state)
            PAT_TX_IDLE: begin
                // Assume as long as the fifo is not empty in the idle state, it means pattern data is updated in FIFO
                if (!fifo_empty) begin
                    pat_tx_state <= PAT_TX_HEAD;
                    fifo_rd_ena <= 1'b1;
                    // FIFO output delay is 1 cycle
                    delay_cnt <= ~delay_cnt ;
                end
                if (delay_cnt == 'h1) begin

                    delay_cnt <= 'h0;
                end
            end
            PAT_TX_HEAD: begin
                fifo_rd_ena <= 1'b1;
                pat_tx_state <= PAT_TX_HEAD_WAIT;
            end
            PAT_TX_HEAD_WAIT: begin
                fifo_rd_ena <= 1'b0;
                {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, pat_fill_size, pat_start_addr, pat_end_addr, pat_rsv} <= fifo_rd_data;


    end
end

endmodule