// --------------------------------------------------------------------
// Copyright (c) 2007 by Terasic Technologies Inc.
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development
//   Kits made by Terasic.  Other use of this code, including the selling
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use
//   or functionality of this code.
//
// --------------------------------------------------------------------
//
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
// Chunjie 2017-11-14
// Only support 1920x1080
// --------------------------------------------------------------------

`include "vpg.h"

module vpg(


input               clk_100m,
input               reset_n,


// DDR3 interface
input           start,
input           ddr3_emif_clk,
input           ddr3_emif_rst_n,
input           ddr3_emif_ready,
input [255:0]   ddr3_emif_read_data,
input           ddr3_emif_rddata_valid,

output          ddr3_emif_read,
output          ddr3_emif_write,
output [21:0]   ddr3_emif_addr,
output [255:0]  ddr3_emif_write_data,
output [31:0]   ddr3_emif_byte_enable,
output [4:0]    ddr3_emif_burst_count,

output          onchip_mem_clken,
output          onchip_mem_chip_select,
output          onchip_mem_read,
input [255:0]   onchip_mem_rddata,
output [10:0]   onchip_mem_addr,
output [31:0]   onchip_mem_byte_enable,
output          onchip_mem_write,
output [255:0]  onchip_mem_write_data,

input  [3:0]        mode,
input               mode_change,
input  [1:0]        disp_color,
output              vpg_locked,
output              vpg_pclk,
output              vpg_de,
output              vpg_hs,
output              vpg_vs,
output    [7:0]     vpg_r,
output    [7:0]     vpg_g,
output    [7:0]     vpg_b
);


reg    [3:0]        config_state;
reg    [3:0]        disp_mode;
reg     [2:0]       timing_change_dur;

// timing_change is a pulse
reg                 time_gen_r;
reg                 timing_change;
wire                clk_148_5/*synthesis keep*/;
wire                vpg_pll_locked/*synthesis keep*/;

//============= assign timing constant

reg     [11:0]     h_disp;
reg     [11:0]     h_fporch;
reg     [11:0]     h_sync;
reg     [11:0]     h_bporch;
reg     [11:0]     v_disp;
reg     [11:0]     v_fporch;
reg     [11:0]     v_sync;
reg     [11:0]    v_bporch;
reg               hs_polarity;
reg               vs_polarity;
reg               frame_interlaced;

// Set 1920 x 1080 standard
// sync_polarity = 0:
// ______    _________
//       |__|
//        sync (hs_vs)
//
// sync_polarity = 1:
//        __
// ______|  |__________
//       sync (hs/vs)


always @(posedge clk_148_5 or negedge reset_n) begin
    if (~reset_n) begin
        {h_disp, h_fporch, h_sync, h_bporch} <= 'h0;
        {v_disp, v_fporch, v_sync, v_bporch} <= 'h0;
        {frame_interlaced, vs_polarity, hs_polarity} <= 'h0;
    end
    else begin
        {h_disp, h_fporch, h_sync, h_bporch} <= {12'd1920, 12'd88, 12'd44, 12'd148};// total: 2200
        {v_disp, v_fporch, v_sync, v_bporch} <= {12'd1080,  12'd4, 12'd5,  12'd36};// total: 1125
        {frame_interlaced, vs_polarity, hs_polarity} <= 3'b011;
    end
end

//============ pattern generator: vga timming generator


wire                 time_hs;
wire                 time_vs;
wire                 time_de;

wire     [11:0]    time_x;
wire     [11:0]    time_y;

pll_vpg pll_vpg_i (
    .refclk   (clk_100m),   //  refclk.clk
    .rst      (~reset_n),      //   reset.reset
    .outclk_0 (clk_148_5), // outclk0.clk  148.5MHz
    .locked   (vpg_pll_locked)    //  locked.export
);
assign vpg_locked = vpg_pll_locked;

vga_time_generator vga_time_generator_inst(

   .clk(clk_148_5),
   .reset_n(vpg_pll_locked),
   .timing_change(mode_change),

   .h_disp( h_disp),
   .h_fporch(h_fporch),
   .h_sync(h_sync),
   .h_bporch(h_bporch),

   .v_disp(v_disp),
   .v_fporch(v_fporch),
   .v_sync(v_sync),
   .v_bporch(v_bporch),

   .hs_polarity(hs_polarity),
   .vs_polarity(vs_polarity),
   .frame_interlaced(frame_interlaced),


   .vga_hs(time_hs),
   .vga_vs(time_vs),
   .vga_de(time_de),
   .pixel_i_odd_frame(),
   .pixel_x(time_x),
   .pixel_y(time_y)

);

//===== pattern generator according to vga timing

wire  gen_hs/*synthesis keep*/;
wire  gen_vs/*synthesis keep*/;
wire  gen_de/*synthesis keep*/;
wire [7:0]    gen_r/*synthesis keep*/;
wire [7:0]    gen_g/*synthesis keep*/;
wire [7:0]    gen_b/*synthesis keep*/;

//convert time: 1-clock
/*
pattern_gen pattern_gen_inst(
    .reset_n(vpg_pll_locked & ~mode_change),
    .pixel_clk(clk_148_5),
    .pixel_de(time_de),
    .pixel_hs(time_hs),
    .pixel_vs(time_vs),
    .pixel_x(time_x),
    .pixel_y(time_y),
    .image_width(h_disp),
    .image_height(v_disp),
    .image_color(disp_color),
    .gen_de(gen_de),
    .gen_hs(gen_hs),
    .gen_vs(gen_vs),
    .gen_r(gen_r),
    .gen_g(gen_g),
    .gen_b(gen_b)
);
*/
// Load DMD pattern from DDR3 and gennerate HDMI standard signals

pattern_fetch_send pattern_fetch_send_inst (
    .pixel_clk            (clk_148_5),
    .pixel_rst_n          (vpg_pll_locked & ~mode_change),
    .pixel_x              (time_x),
    .pixel_y              (time_y),
    .pixel_de             (time_de),
    .pixel_hs             (time_hs),
    .pixel_vs             (time_vs),
    .image_width          (h_disp),
    .image_height         (v_disp),
    .image_color          (disp_color),

    //.pat_ready_out        (pat_ready_out),
    .ddr3_emif_clk         (ddr3_emif_clk),
    .ddr3_emif_rst_n       (ddr3_emif_rst_n),
    .onchip_mem_clken      (onchip_mem_clken),
    .onchip_mem_chip_select(onchip_mem_chip_select),
    .onchip_mem_read       (onchip_mem_read),
    .onchip_mem_rddata     (onchip_mem_rddata),
    .onchip_mem_addr       (onchip_mem_addr),
    .onchip_mem_byte_enable(onchip_mem_byte_enable),
    .onchip_mem_write      (onchip_mem_write),
    .onchip_mem_write_data (onchip_mem_write_data),

    .start                (start),
    .ddr3_emif_ready       (ddr3_emif_ready),
    .ddr3_emif_read_data   (ddr3_emif_read_data),
    .ddr3_emif_rddata_valid(ddr3_emif_rddata_valid),
    .ddr3_emif_read        (ddr3_emif_read),
    .ddr3_emif_write       (ddr3_emif_write),
    .ddr3_emif_addr        (ddr3_emif_addr),
    .ddr3_emif_write_data  (ddr3_emif_write_data),
    .ddr3_emif_byte_enable (ddr3_emif_byte_enable),
    .ddr3_emif_burst_count (ddr3_emif_burst_count),

    .gen_de               (gen_de),
    .gen_hs               (gen_hs),
    .gen_vs               (gen_vs),
    .gen_r                (gen_r),
    .gen_g                (gen_g),
    .gen_b                (gen_b)
    );
/*
wire           hsync_o_with_camera_format;//active high
wire           vsync_o_with_camera_format;//active low
wire           de_o;//active high
wire           hsync_o_with_hdmi_format;
wire           vsync_o_with_hdmi_format;
wire           de_o_with_hdmi_format;
wire           de_o_first_offset_line;
wire [23:0]    display_vedio_left_offset;
wire           frame_start_trig;
wire           frame_busy;

wire           dmd_correct_15_pixles_slope;//added by wdf @2014/11/03 dmd_correct_15_pixles_slope==1'b1 the display will compensate the slope
wire           dmd_flip_left_and_right;//flip left and right //left right flip: flip first, the correct the 15 pixels == correct the -15 pixels and then flip
wire [10:0]    frame_count;
display_vedio_generate_DMD_specific_faster display_vedio_generate_DMD_specific_faster_inst (
    .clk_i(clk_148_5),
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

fast_pat_fetch fast_pat_fetch_inst (
    .clk                   (clk_148_5),
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
*/
//===== output
assign vpg_pclk = clk_148_5;
assign vpg_de     = gen_de;
assign vpg_hs     = gen_hs;
assign vpg_vs     = gen_vs;
assign vpg_r     = gen_r;
assign vpg_g     = gen_g;
assign vpg_b     = gen_b;

endmodule


