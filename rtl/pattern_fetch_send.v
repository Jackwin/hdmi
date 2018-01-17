module pattern_fetch_send (
    input           pixel_clk,
    input           rst_n,

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


localparam  DDR3_IDLE_s = 3'd0,
            DDR3_RD_HEAD_s = 3'd1,
            DDR3_RD_HEAD_WAIT_s = 3'd2,
            DDR3_RD_BODY_s = 3'd3,
            DDR3_RD_BODY__WAIT_s = 3'd4;

// Pattern signals
reg [31:0]  pat_h_pix, pat_v_pix, pat_total_pix;
reg [31:0]  pat_num, pat_fill_size;
reg [31:0]  pat_start_addr, pat_end_addr;
reg [31:0]  pat_rsv;

reg [31:0]  pat_cnt;
wire [31:0] pat_total_pix_w;
// The times of reading one-pattern data from DDR3
reg [23:0]  pat_read_ddr3_times;

reg [1:0]   ddr3_rd_cs, ddr3_rd_ns;

reg         ddr3_rd_start;
reg         ddr3_rd;
reg [21:0]  ddr3_rd_addr;

wire        ddr3_rddata_valid;
wire [255:0]ddr3_rddata;

wire        fifo_wr_clk, fifo_rd_clk;
wire        fifo_wr_ena, fifo_full;
wire        fifo_rd_ena, fifo_empty;
wire [255:0]fifo_wr_data, fifo_rd_data;


assign ddr3_rddata = ddr_emif_read_data;
assign ddr3_rddata_valid = ddr_emif_rddata_valid;

assign fifo_wr_ena = ddr3_rddata_valid;
assign fifo_wr_data = ddr3_rddata;

always @(posedge ddr_emif_clk or negedge ddr_emif_rst_n) begin :
    if(~ddr_emif_rst_n) begin
         ddr3_rd_cs <= DDR3_IDLE_s;
    end else begin
         ddr3_rd_cs <= ddr3_rd_ns;
    end
end

assign pat_total_pix_w = ddr3_rddata[191:159];
always @(posedge ddr_emif_clk or negedge ddr_emif_rst_n) begin
    if(~ddr_emif_rst_n) begin
        ddr3_rd <= 0;
        ddr3_rd_addr <= 0;
        pat_read_ddr3_times <= 0;
    end else begin
         case (ddr3_rd_cs)
            DDR3_IDLE_s: if (ddr3_rd_start) ddr3_rd_ns <= ddr3_rd_cs;
            DDR3_RD_HEAD_s: begin
                if (!fifo_full && pat_cnt!= 0) begin
                    ddr3_rd <= 1'b1;
                    ddr3_addr <= 22'h0;
                    ddr3_rd_ns <= DDR3_RD_HEAD_WAIT_s;
                end
            end
            // Wait valid rddata
            DDR3_RD_HEAD_WAIT_s: begin
                ddr3_rd <= 1'b0;
                if (ddr3_rddata_valid) begin
                    {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, pat_fill_size, pat_start_addr, pat_end_addr, pat_rsv} <= ddr3_rddata;
                    ddr3_rd_ns <= DDR3_RD_BODY_s;
                    ddr3_addr <= ddr3_addr + 1'd1;
                    pat_read_ddr3_times <= pat_total_pix_w[31:9] + (|pat_total_pix_w[7:0]);
                end
            end
            DDR3_RD_BODY_s: begin
                ddr3_rd <= 1'b1;
                ddr3_rd_ns <= DDR3_RD_BODY_WAIT_s;
            end
            DDR3_RD_BODY__WAIT_s: begin
                ddr3_rd <= 1'b0;
                if (ddr3_rddata_valid) begin
                    ddr3_addr <= ddr3_addr + 1'd1;
                    ddr3_rd_ns <= DDR3_RD_BODY_s;
                    pat_read_ddr3_times <= pat_read_ddr3_times - 1'd1;
                end
            end

             default : /* default */;
         endcase
    end
end

endmodule