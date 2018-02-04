`timescale 1 ns / 1 ps

module fast_pat_tb ();
logic clk;
logic rst_n;

logic           hsync_o_with_camera_format;//active high
logic           vsync_o_with_camera_format;//active low
logic           de_o;//active high
logic           hsync_o_with_hdmi_format;
logic           vsync_o_with_hdmi_format;
logic           de_o_with_hdmi_format;
logic           de_o_first_offset_line;
logic [23:0]    display_vedio_left_offset;
logic           frame_start_trig;//a
logic           frame_busy;
logic           frame_all_zeros;//we have to send all zero frame during acqisitaion, high active (captured at the edge of frame_start_trig)
logic           de_with_all_zeros;
logic           dmd_correct_15_pixles_slope;//added by wdf @2014/11/03 dmd_correct_15_pixles_slope==1'b1 the display will compensate the slope
logic           dmd_flip_left_and_right;//flip left and right //left right flip: flip first, the correct the 15 pixels == correct the -15 pixels and then flip
logic [10:0]    frame_count;

logic h_sync, v_sync, de;

display_vedio_generate_DMD_specific_faster display_vedio_generate_DMD_specific_faster_inst (
    .clk_i(clk),
    .rst_ni(rst_n),
    .hsync_o_with_camera_format(hsync_o_with_camera_format),//active high
    .vsync_o_with_camera_format(vsync_o_with_camera_format),//active low
    .de_o(de_o),//active high

    .hsync_o_with_hdmi_format(h_sync),
    .vsync_o_with_hdmi_format(v_sync),
    .de_o_with_hdmi_format(de),

    .de_o_first_offset_line(de_o_first_offset_line),
    .display_vedio_left_offset(display_vedio_left_offset),

    .frame_start_trig(frame_start_trig),//a
    .frame_busy(frame_busy),

    .frame_all_zeros('h0),//we have to send all zero frame during acqisitaion, high active (captured at the edge of frame_start_trig)
    .de_with_all_zeros(),

    .dmd_correct_15_pixles_slope('h0),//added by wdf @2014/11/03 dmd_correct_15_pixles_slope==1'b1 the display will compensate the slope
    .dmd_flip_left_and_right('h0),//flip left and right //left right flip: flip first, the correct the 15 pixels == correct the -15 pixels and then flip

    .frame_count(frame_count)
);


logic [0:1023][255:0]   onchip_mem;

logic           onchip_mem_select;
logic           onchip_mem_read;
logic [10:0]    onchip_mem_addr;
logic [31:0]    onchip_mem_byte_enable;
logic [255:0]   onchip_mem_write_data;
logic           onchip_mem_write;
logic [255:0]   onchip_mem_read_data;

logic [23:0]    pix_data_out;

fast_pat_fetch fast_pat_fetch_inst (
    .clk                   (clk),
    .rst_n                 (rst_n),
    .onchip_mem_chip_select(onchip_mem_select),
    .onchip_mem_chip_read  (onchip_mem_read),
    .onchip_mem_addr       (onchip_mem_addr),
    .onchip_mem_byte_enable(onchip_mem_byte_enable),
    .onchip_mem_write_data (onchip_mem_write_data),
    .onchip_mem_write      (onchip_mem_write),
    .onchip_mem_read_data  (onchip_mem_read_data),
    .frame_trig            (frame_start_trig),
    .frame_busy            (frame_busy),
    .h_sync_in             (h_sync),
    .v_sync_in             (v_sync),
    .de_in                 (de),
    .pix_data_out          (pix_data_out)
    );

initial begin
    onchip_mem[0] = 256'h000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e77;
    for (int i = 1; i < 1024; i++) begin
        onchip_mem[i] = onchip_mem[i-1] + 256'h1010101010101010101010101010101010101010101010101010101010101010;
    end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_rd_onchip_mem
    if(~rst_n) begin
        onchip_mem_read_data <= 0;
    end else begin
        if (onchip_mem_read & onchip_mem_select) begin
            onchip_mem_read_data <= onchip_mem[onchip_mem_addr[9:0]];
        end
    end
end

initial begin
    clk = 0;
    forever begin
        # 3.125 clk = ~clk;
    end
end

initial begin
    rst_n = 1;
    #50 rst_n = 0;
    #15 rst_n = 1;
end




endmodule