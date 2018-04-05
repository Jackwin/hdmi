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
logic [31:0] image_width = 32'd1920, image_height = 32'd1080;
logic [8:0][255:0] ddr_mem;
reg [31:0]  pat_h_pix = image_width/4, pat_v_pix = image_height/4, pat_total_pix = pat_h_pix * pat_v_pix;
reg [31:0]  pat_num = 4, h_fill_size = image_width/pat_h_pix;
reg [31:0]  v_fill_size = image_height/pat_v_pix;
reg [31:0]  pat_start_addr = 'd1, pat_end_addr = 'd8;
reg [31:0]  pat_rsv = 0;;
initial begin
    ddr_mem[0] = {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, h_fill_size, v_fill_size, pat_start_addr, pat_end_addr};
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
            ddr_emif_rd_data <= ddr_mem[ddr_emif_addr[2:0]];
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

logic       hsync_o_with_camera_format;//active high
logic       vsync_o_with_camera_format;//active low
logic       de_o;//active high

logic         hsync_o_with_hdmi_format;
logic         vsync_o_with_hdmi_format;
logic         de_o_with_hdmi_format;

logic           de_o_first_offset_line;
logic [23:0]    display_vedio_left_offset;

logic           frame_start_trig;//a
logic           frame_busy;

logic       frame_all_zeros;//we have to send all zero frame during acqisitaion, high active (captured at the edge of frame_start_trig)
logic       de_with_all_zeros;

logic       dmd_correct_15_pixles_slope;//added by wdf @2014/11/03 dmd_correct_15_pixles_slope==1'b1 the display will compensate the slope
logic       dmd_flip_left_and_right;//flip left and right //left right flip: flip first, the correct the 15 pixels == correct the -15 pixels and then flip

logic        [10:0] frame_count;

initial begin
    frame_start_trig = 0;
    #800;
    @(posedge pixel_clk) frame_start_trig <= 1;
    @(posedge pixel_clk) frame_start_trig <= 0;
end

display_vedio_generate_DMD_specific_faster display_vedio_generate_DMD_specific_faster_inst (
    .clk_i                      (pixel_clk),
    .rst_ni                     (pixel_rst_n),
    .hsync_o_with_camera_format (hsync_o_with_camera_format),
    .vsync_o_with_camera_format (vsync_o_with_camera_format),
    .de_o                       (de_o),
    .hsync_o_with_hdmi_format   (hsync_o_with_hdmi_format),
    .vsync_o_with_hdmi_format   (vsync_o_with_hdmi_format),
    .de_o_with_hdmi_format      (de_o_with_hdmi_format),
    .de_o_first_offset_line     (de_o_first_offset_line),
    .display_vedio_left_offset  (display_vedio_left_offset),
    .frame_start_trig           (frame_start_trig),
    .frame_busy                 (frame_busy),
    .frame_all_zeros            (frame_all_zeros),
    .de_with_all_zeros          (de_with_all_zeros),
    .dmd_correct_15_pixles_slope(dmd_correct_15_pixles_slope),
    .dmd_flip_left_and_right    (dmd_flip_left_and_right),
    .frame_count                (frame_count)
    );


pattern_fetch_send pattern_fetch_send_inst (
    .pixel_clk            (pixel_clk),
    .pixel_rst_n          (pixel_rst_n),

    .pixel_x              (),
    .pixel_y              (),
    .pixel_de             (de_o_with_hdmi_format),
    .pixel_hs             (hsync_o_with_hdmi_format),
    .pixel_vs             (vsync_o_with_hdmi_format),
    .image_width          (),
    .image_height         (),
    .image_color          (),

    .de_first_offset_line_in     (de_first_offset_line_in),
    .display_video_left_offset_in(display_video_left_offset_in),

    //.pat_ready_out        (pat_ready),
    .gen_de               (gen_de),
    .gen_hs               (gen_hs),
    .gen_vs               (gen_vs),
    .gen_r                (gen_r),
    .gen_g                (gen_g),
    .gen_b                (gen_b),

    .start                (start),
    .ddr3_emif_clk         (ddr_emif_clk),
    .ddr3_emif_rst_n       (ddr_emif_rst_n),
    .ddr3_emif_ready       (ddr_emif_ready),
    .ddr3_emif_read_data   (ddr_emif_rd_data),
    .ddr3_emif_rddata_valid(ddr_emif_rd_valid),
    .ddr3_emif_read        (ddr_emif_read),
    .ddr3_emif_write       (),
    .ddr3_emif_addr        (ddr_emif_addr),
    .ddr3_emif_write_data  (),
    .ddr3_emif_byte_enable (ddr_emif_byte_enable),
    .ddr3_emif_burst_count (ddr_emif_burst_count)

    );

//--------------------------- Test fast_pattern_fetch -----------------------------------------




endmodule