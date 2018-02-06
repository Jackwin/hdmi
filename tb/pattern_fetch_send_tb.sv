`timescale 1ns/1ps
`define DDR_CLK_PERIOD 8
`define PIXEL_CLK_PERIOD 6.73
module pattern_fetch_send_tb ();

logic ddr_emif_clk, ddr_emif_rst_n;
logic pixel_clk, pixel_rst_n;
logic start;

initial begin
    ddr_emif_clk = 0;
    forever begin
        #(`DDR_CLK_PERIOD/2) ddr_emif_clk = ~ddr_emif_clk;
    end // forever
end

initial begin
    pixel_clk = 0;
    forever begin
        #(`PIXEL_CLK_PERIOD/2) pixel_clk = ~pixel_clk;
    end // forever
end

initial begin
    ddr_emif_rst_n = 1;
    #70 ddr_emif_rst_n = 0;
    #30 ddr_emif_rst_n = 1;
end

initial begin
    pixel_rst_n = 1;
    #90 pixel_rst_n = 0;
    #30 pixel_rst_n = 1;
end

initial begin
    start = 0;
    # 180 start = 1;
    # 10 start = 0;
end


//------------------------------------------------------------------------------
// DDR logics
logic [31:0] image_width = 32'd480, image_height = 32'd270;
logic [8:0][255:0] ddr_mem;
reg [31:0]  pat_h_pix = 32'd20, pat_v_pix = 32'd20, pat_total_pix = 32'd400;
reg [31:0]  pat_num = 4, pat_fill_size = image_width/pat_h_pix;
reg [31:0]  pat_start_addr = 'd1, pat_end_addr = 'd8;
reg [31:0]  pat_rsv = 0;;
initial begin
    ddr_mem[0] = {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, pat_fill_size, pat_start_addr, pat_end_addr, pat_rsv};
    ddr_mem[1] = 256'hfafafafafafafafafafafafafafafafafafafafafafafafafafafafafafafafa;
    ddr_mem[2] = 256'habababababababababababababababababababababababababababababababab;
    ddr_mem[3] = 256'h7777777777777777777777777777777777777777777777777777777777777777;
    ddr_mem[4] = 256'hf0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0;
    ddr_mem[5] = 256'hfafafafafafafafafafafafafafafafafafafafafafafafafafafafafafafafa;
    ddr_mem[6] = 256'habababababababababababababababababababababababababababababababab;
    ddr_mem[7] = 256'h7777777777777777777777777777777777777777777777777777777777777777;
    ddr_mem[8] = 256'hbabababababababababababababababababababababababababababababababa;

end


logic [21:0]    ddr_emif_addr;
logic [31:0]    ddr_emif_byte_enable;
logic [255:0]   ddr_emif_rd_data;
logic [4:0]    ddr_emif_burst_count;
logic           ddr_emif_rd_valid;
logic           ddr_emif_read;
logic           ddr_emif_ready = 1;
//logic           ddr_emif_write

always_ff @(posedge ddr_emif_clk or negedge ddr_emif_rst_n) begin : proc_ddr_read
    if(~ddr_emif_rst_n) begin
        ddr_emif_rd_data <= 0;
        ddr_emif_rd_valid <= 0;
    end else begin
        ddr_emif_rd_valid <= 0;
        if (ddr_emif_read) begin
            ddr_emif_rd_data <= ddr_mem[ddr_emif_addr];
            ddr_emif_rd_valid <= 1;
        end
    end
end

//-----------------------------------------------------------------------------
// VPG logics
logic [31:0] pixel_de_cnt;
logic pat_ready;
logic pixel_de;
always_ff @(posedge pixel_clk or negedge pixel_rst_n) begin : proc_vpg
    if(~pixel_rst_n) begin
    pixel_de_cnt <= 0;
    end else begin
        if (pat_ready) begin
            pixel_de_cnt <= pixel_de_cnt + 1'd1;
            if (pixel_de_cnt == (image_height * image_width + 30)) begin
                pixel_de_cnt <= 'd0;
            end
        end
        else begin
            pixel_de_cnt <= 'd0;
        end
    end
end

always_comb begin : proc_gen_de
    pixel_de = ((pixel_de_cnt < image_width * image_height) && pat_ready);
end

//-----------------------------------------------------------------------------

pattern_fetch_send pattern_fetch_send_inst (
    .pixel_clk            (pixel_clk),
    .pixel_rst_n          (pixel_rst_n),

    .pixel_x              (),
    .pixel_y              (),
    .pixel_de             (pixel_de),
    .pixel_hs             (),
    .pixel_vs             (),
    .image_width          (),
    .image_height         (),
    .image_color          (),

    .pat_ready_out        (pat_ready),
    .gen_de               (gen_de),
    .gen_hs               (gen_hs),
    .gen_vs               (gen_vs),
    .gen_r                (gen_r),
    .gen_g                (gen_g),
    .gen_b                (gen_b),

    .start                (start),
    .ddr_emif_clk         (ddr_emif_clk),
    .ddr_emif_rst_n       (ddr_emif_rst_n),
    .ddr_emif_ready       (ddr_emif_ready),
    .ddr_emif_read_data   (ddr_emif_rd_data),
    .ddr_emif_rddata_valid(ddr_emif_rd_valid),
    .ddr_emif_read        (ddr_emif_read),
    .ddr_emif_write       (),
    .ddr_emif_addr        (ddr_emif_addr),
    .ddr_emif_write_data  (),
    .ddr_emif_byte_enable (ddr_emif_byte_enable),
    .ddr_emif_burst_count (ddr_emif_burst_count)

    );





endmodule