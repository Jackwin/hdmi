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
// Only support 1920x108o
// --------------------------------------------------------------------

`include "vpg.h"

module vpg(
input               clk_100m,
input               reset_n,

input               time_gen,

input  [3:0]        mode,
input               mode_change,
input  [1:0]        disp_color,
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
wire                clk_148_5;
wire                vpg_pll_locked;

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


always @(clk_148_5 or negedge reset_n) begin
    if (~reset_n) begin
        {h_disp, h_fporch, h_sync, h_bporch} <= 'h0;
        {v_disp, v_fporch, v_sync, v_bporch} <= 'h0;
        {frame_interlaced, vs_polarity, hs_polarity} <= 'h0;
        timing_change <= 1'b0;
    end
    else begin
        {h_disp, h_fporch, h_sync, h_bporch} <= {12'd1920, 12'd88, 12'd44, 12'd148};// total: 2200
        {v_disp, v_fporch, v_sync, v_bporch} <= {12'd1080,  12'd4, 12'd5,  12'd36};// total: 1125
        {frame_interlaced, vs_polarity, hs_polarity} <= 3'b011;
        time_gen_r <= time_gen;

        timing_change <= ~time_gen_r & time_gen;
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


vga_time_generator vga_time_generator_inst(

   .clk(clk_148_5),
   .reset_n(~vpg_pll_locked),
   .timing_change(timing_change),

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

wire  gen_hs;
wire  gen_vs;
wire  gen_de;
wire [7:0]    gen_r;
wire [7:0]    gen_g;
wire [7:0]    gen_b;

//convert time: 1-clock
pattern_gen pattern_gen_inst(
    .reset_n(~vpg_pll_locked),
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


//===== output
assign vpg_pclk = clk_148_5;
assign vpg_de     = gen_de;
assign vpg_hs     = gen_hs;
assign vpg_vs     = gen_vs;
assign vpg_r     = gen_r;
assign vpg_g     = gen_g;
assign vpg_b     = gen_b;


endmodule


