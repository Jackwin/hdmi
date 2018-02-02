`timescale 1 ns / 1 ps
//需要注意的是，DMD的HDMi接收芯片会对控制信号重新调整和整形，会和发送信号略有不同

/*
第一行的第1到6个48 bit (第0到第11个像素)
第 0个 像素 24 bit
低(10:0)位，指定偏移的行数X，DMD(1:1080) 的前1~(Z+1)*X行，是偏移行，HMDI发送的1-X行 (第0行是控制行)，都是偏移行
低(14:12), 制定生成额外的行触发信号 Z
0, 通常对应无偏移的情况。
1~4，对应额外有偏移的情况，在DMD底层实现上，按照8个DE，触发一个额外的偏移情况。
23bit 1 标示位

第1个像素
低(10:0)位，指定底部偏移的情况Y, HDMI发送的第Y行极其后面的，都可以看作偏移行,那么中间有效数据行是X+1:Y-1,一共Y-X-1行
23bit 1 标示位
*/

//代码与*faster一样，区别在于针对是1920x1080的分辨率

//`define DISPLAY_DMD_FAST_M1024x768

//`define DISPLAY_DMD_FAST_M1920x400

//`define DISPLAY_DMD_FAST_M1920x160

`define DISPLAY_DMD_FAST_M1920x1080
//`define DISPLAY_DMD_FAST_M1920x70

//
`ifdef DISPLAY_DMD_FAST_M1024x768 //1032x768的视场
//图像在相机上的位置偏移尚未确认解决

    `define DISPLAY_DMD_FAST_H_SYNC_PLUSE        8     //    Horizontal Parameter    ( Pixel )
    `define DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH   8
    `define DISPLAY_DMD_FAST_H_SYNC_FRONT_PORCH  8

     `define DISPLAY_DMD_FAST_H_LEFT_OFFSET    400 // 在整体1920x1080幅面上的左边的偏移位置 pixels

    `define DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD    68 //DISPLAY_DMD_FAST_H_ACTIVE_TIME+pulse+back+front
    `define DISPLAY_DMD_FAST_H_ACTIVE_TIME       44 // 必须是偶数, 比DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME略大
     `define DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME  43 // ceil(1024/24) = 43 == 1032 pixels


    `define DISPLAY_DMD_FAST_V_SYNC_PLUSE        2     //    vertical Parameter    ( line )
    `define DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH   3  // 1) at least 200 clk for frame preparation 2) + offset time to make enough time for phase memory preparement
    `define DISPLAY_DMD_FAST_V_SYNC_FRONT_PORCH  24    // enough time for dmd update (reset) > 100*16/DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD

     `define DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG 52     //实际的偏移floor(156/(DISPLAY_DMD_FAST_EXTRA_TRIG+1))
     `define DISPLAY_DMD_FAST_V_TOP_OFFSET   52 // DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG + (实际的偏移156-(DISPLAY_DMD_FAST_EXTRA_TRIG+1)*DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG)
     `define DISPLAY_DMD_FAST_EXTRA_TRIG 2 //对应在偏移行中，每个偏移行会生成DISPLAY_DMD_FAST_EXTRA_TRIG+1个DMD行填充,在DMD实现中，这边每发送16个de，会额外出发一个trig
     `define DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME   768

    `define DISPLAY_DMD_FAST_V_WHOLE_FRAME_PRD   902 //pulse+back+front+DISPLAY_DMD_FAST_V_ACTIVE_TIME
    `define DISPLAY_DMD_FAST_V_ACTIVE_TIME       873 //1080 plus one control line
     //ceil*((1080-DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME-实际的偏移156)/(DISPLAY_DMD_FAST_EXTRA_TRIG+1)+DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME + DISPLAY_DMD_FAST_V_TOP_OFFSET + 1

`endif

//
`ifdef DISPLAY_DMD_FAST_M1920x768 //1920x768的视场
//图像在相机上的位置偏移尚未确认解决

    `define DISPLAY_DMD_FAST_H_SYNC_PLUSE        8     //    Horizontal Parameter    ( Pixel )
    `define DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH   8
    `define DISPLAY_DMD_FAST_H_SYNC_FRONT_PORCH  8

     `define DISPLAY_DMD_FAST_H_LEFT_OFFSET    0 // 在整体1920x1080幅面上的左边的偏移位置 pixels

    `define DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD    106 //DISPLAY_DMD_FAST_H_ACTIVE_TIME+pulse+back+front
    `define DISPLAY_DMD_FAST_H_ACTIVE_TIME       82 // 必须是偶数, 比DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME略大
     `define DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME  80 // ceil(1920/24) = 80 == 1920 pixels


    `define DISPLAY_DMD_FAST_V_SYNC_PLUSE        2     //    vertical Parameter    ( line ) at least 2
    `define DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH   3  // 1) at least 200 clk for frame preparation 2) + offset time to make enough time for phase memory preparement
    `define DISPLAY_DMD_FAST_V_SYNC_FRONT_PORCH  16    // enough time for dmd update (reset) > 100*16/DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD

     `define DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG 31     //实际的偏移floor(156/(DISPLAY_DMD_FAST_EXTRA_TRIG+1))
     `define DISPLAY_DMD_FAST_V_TOP_OFFSET   32 // DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG + (实际的偏移156-(DISPLAY_DMD_FAST_EXTRA_TRIG+1)*DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG)
     `define DISPLAY_DMD_FAST_EXTRA_TRIG 4 //对应在偏移行中，每个偏移行会生成DISPLAY_DMD_FAST_EXTRA_TRIG+1个DMD行填充,在DMD实现中，这边每发送16个de，会额外出发一个trig
     `define DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME   768

    `define DISPLAY_DMD_FAST_V_WHOLE_FRAME_PRD   854 //pulse+back+front+DISPLAY_DMD_FAST_V_ACTIVE_TIME
    `define DISPLAY_DMD_FAST_V_ACTIVE_TIME       833 //1080 plus one control line
     //ceil*((1080-DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME-实际的偏移156)/(DISPLAY_DMD_FAST_EXTRA_TRIG+1)+DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME + DISPLAY_DMD_FAST_V_TOP_OFFSET + 1

`endif

//
`ifdef DISPLAY_DMD_FAST_M1920x160 //1920x160的视场
//图像在相机上的位置偏移尚未确认解决

    `define DISPLAY_DMD_FAST_H_SYNC_PLUSE        8     //    Horizontal Parameter    ( Pixel )
    `define DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH   8
    `define DISPLAY_DMD_FAST_H_SYNC_FRONT_PORCH  8

     `define DISPLAY_DMD_FAST_H_LEFT_OFFSET    0 // 在整体1920x1080幅面上的左边的偏移位置 pixels

    `define DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD    106 //DISPLAY_DMD_FAST_H_ACTIVE_TIME+pulse+back+front
    `define DISPLAY_DMD_FAST_H_ACTIVE_TIME       82 // 必须是偶数, 比DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME略大
     `define DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME  80 // ceil(1920/24) = 80 == 1920 pixels


    `define DISPLAY_DMD_FAST_V_SYNC_PLUSE        2     //    vertical Parameter    ( line ) at least 2
    `define DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH   3  // 1) at least 200 clk for frame preparation 2) + offset time to make enough time for phase memory preparement
    `define DISPLAY_DMD_FAST_V_SYNC_FRONT_PORCH  16    // enough time for dmd update (reset) > 100*16/DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD

     `define DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG 92     //实际的偏移floor(460/(DISPLAY_DMD_FAST_EXTRA_TRIG+1))
     `define DISPLAY_DMD_FAST_V_TOP_OFFSET   92 // DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG + (实际的偏移460-(DISPLAY_DMD_FAST_EXTRA_TRIG+1)*DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG)
     `define DISPLAY_DMD_FAST_EXTRA_TRIG 4 //对应在偏移行中，每个偏移行会生成DISPLAY_DMD_FAST_EXTRA_TRIG+1个DMD行填充,在DMD实现中，这边每发送16个de，会额外出发一个trig
     `define DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME   160

    `define DISPLAY_DMD_FAST_V_WHOLE_FRAME_PRD   366 //pulse+back+front+DISPLAY_DMD_FAST_V_ACTIVE_TIME
    `define DISPLAY_DMD_FAST_V_ACTIVE_TIME       345 //1080 plus one control line
     //ceil*((1080-DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME)/(DISPLAY_DMD_FAST_EXTRA_TRIG+1)+DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME + 1

`endif

//
`ifdef DISPLAY_DMD_FAST_M1920x70 //1920x70的视场
//图像在相机上的位置偏移尚未确认解决

    `define DISPLAY_DMD_FAST_H_SYNC_PLUSE        8     //    Horizontal Parameter    ( Pixel )
    `define DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH   8
    `define DISPLAY_DMD_FAST_H_SYNC_FRONT_PORCH  8

     `define DISPLAY_DMD_FAST_H_LEFT_OFFSET    0 // 在整体1920x1080幅面上的左边的偏移位置 pixels

    `define DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD    106 //DISPLAY_DMD_FAST_H_ACTIVE_TIME+pulse+back+front
    `define DISPLAY_DMD_FAST_H_ACTIVE_TIME       82 // 必须是偶数, 比DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME略大
     `define DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME  80 // ceil(1920/24) = 80 == 1920 pixels


    `define DISPLAY_DMD_FAST_V_SYNC_PLUSE        2     //    vertical Parameter    ( line ) at least 2
    `define DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH   3  // 1) at least 200 clk for frame preparation 2) + offset time to make enough time for phase memory preparement
    `define DISPLAY_DMD_FAST_V_SYNC_FRONT_PORCH  16    // enough time for dmd update (reset) > 100*16/DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD

     `define DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG 101     //实际的偏移floor(505/(DISPLAY_DMD_FAST_EXTRA_TRIG+1))
     `define DISPLAY_DMD_FAST_V_TOP_OFFSET   101 // DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG + (实际的偏移505-(DISPLAY_DMD_FAST_EXTRA_TRIG+1)*DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG)
     `define DISPLAY_DMD_FAST_EXTRA_TRIG 4 //对应在偏移行中，每个偏移行会生成DISPLAY_DMD_FAST_EXTRA_TRIG+1个DMD行填充,在DMD实现中，这边每发送16个de，会额外出发一个trig
     `define DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME   70

    `define DISPLAY_DMD_FAST_V_WHOLE_FRAME_PRD  196 //294 //pulse+back+front+DISPLAY_DMD_FAST_V_ACTIVE_TIME
    `define DISPLAY_DMD_FAST_V_ACTIVE_TIME      175 //273 //
     //original: ceil*((1080-DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME)/(DISPLAY_DMD_FAST_EXTRA_TRIG+1)+DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME + 1
     //faster @2015/02/17  DISPLAY_DMD_FAST_V_TOP_OFFSET+1+DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME+3

`endif


//
`ifdef DISPLAY_DMD_FAST_M1920x400 //1920x400的视场
//图像在相机上的位置偏移尚未确认解决

    `define DISPLAY_DMD_FAST_H_SYNC_PLUSE        8     //    Horizontal Parameter    ( Pixel )
    `define DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH   8
    `define DISPLAY_DMD_FAST_H_SYNC_FRONT_PORCH  8

     `define DISPLAY_DMD_FAST_H_LEFT_OFFSET    0 // 在整体1920x1080幅面上的左边的偏移位置 pixels

    `define DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD    106 //DISPLAY_DMD_FAST_H_ACTIVE_TIME+pulse+back+front
    `define DISPLAY_DMD_FAST_H_ACTIVE_TIME       82 // 必须是偶数, 比DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME略大
     `define DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME  80 // ceil(1920/24) = 80 == 1920 pixels


    `define DISPLAY_DMD_FAST_V_SYNC_PLUSE        2     //    vertical Parameter    ( line ) at least 2
    `define DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH   3  // 1) at least 200 clk for frame preparation 2) + offset time to make enough time for phase memory preparement
    `define DISPLAY_DMD_FAST_V_SYNC_FRONT_PORCH  16    // enough time for dmd update (reset) > 100*16/DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD

     `define DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG 68     //实际的偏移floor(340/(DISPLAY_DMD_FAST_EXTRA_TRIG+1))
     `define DISPLAY_DMD_FAST_V_TOP_OFFSET   68 // DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG + (实际的偏移340-(DISPLAY_DMD_FAST_EXTRA_TRIG+1)*DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG)
     `define DISPLAY_DMD_FAST_EXTRA_TRIG 4 //对应在偏移行中，每个偏移行会生成DISPLAY_DMD_FAST_EXTRA_TRIG+1个DMD行填充,在DMD实现中，这边每发送16个de，会额外出发一个trig
     `define DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME  400

    `define DISPLAY_DMD_FAST_V_WHOLE_FRAME_PRD   558 //pulse+back+front+DISPLAY_DMD_FAST_V_ACTIVE_TIME
    `define DISPLAY_DMD_FAST_V_ACTIVE_TIME       537 //1080 plus one control line
     //ceil*((1080-DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME)/(DISPLAY_DMD_FAST_EXTRA_TRIG+1)+DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME + 1

`endif


//
`ifdef DISPLAY_DMD_FAST_M1920x1080 //1920x1080的视场
//图像在相机上的位置偏移尚未确认解决

    `define DISPLAY_DMD_FAST_H_SYNC_PLUSE        8     //    Horizontal Parameter    ( Pixel )
    `define DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH   8
    `define DISPLAY_DMD_FAST_H_SYNC_FRONT_PORCH  8

     `define DISPLAY_DMD_FAST_H_LEFT_OFFSET    0 // 在整体1920x1080幅面上的左边的偏移位置 pixels

    `define DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD    106 //DISPLAY_DMD_FAST_H_ACTIVE_TIME+pulse+back+front
    `define DISPLAY_DMD_FAST_H_ACTIVE_TIME       82 // 必须是偶数, 比DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME略大
     `define DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME  80 // ceil(1920/24) = 80 == 1920 pixels


    `define DISPLAY_DMD_FAST_V_SYNC_PLUSE        2     //    vertical Parameter    ( line ) at least 2
    `define DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH   3  // 1) at least 200 clk for frame preparation 2) + offset time to make enough time for phase memory preparement
    `define DISPLAY_DMD_FAST_V_SYNC_FRONT_PORCH  16    // enough time for dmd update (reset) > 100*16/DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD

     `define DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG 0     //实际的偏移floor(156/(DISPLAY_DMD_FAST_EXTRA_TRIG+1))
     `define DISPLAY_DMD_FAST_V_TOP_OFFSET   0 // DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG + (实际的偏移156-(DISPLAY_DMD_FAST_EXTRA_TRIG+1)*DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG)
     `define DISPLAY_DMD_FAST_EXTRA_TRIG 0 //对应在偏移行中，每个偏移行会生成DISPLAY_DMD_FAST_EXTRA_TRIG+1个DMD行填充,在DMD实现中，这边每发送16个de，会额外出发一个trig
     `define DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME   1080

    `define DISPLAY_DMD_FAST_V_WHOLE_FRAME_PRD   1102 //pulse+back+front+DISPLAY_DMD_FAST_V_ACTIVE_TIME
    `define DISPLAY_DMD_FAST_V_ACTIVE_TIME       1081 //1080 plus one control line
     //ceil*((1080-DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME-实际的偏移156)/(DISPLAY_DMD_FAST_EXTRA_TRIG+1)+DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME + DISPLAY_DMD_FAST_V_TOP_OFFSET + 1

`endif

module display_vedio_generate_DMD_specific_faster
(
    input  wire         clk_i,
    input  wire         rst_ni,
    output wire         hsync_o_with_camera_format,//active high
    output wire         vsync_o_with_camera_format,//active low
    output wire         de_o,//active high

     output wire         hsync_o_with_hdmi_format,
    output wire         vsync_o_with_hdmi_format,
     output wire         de_o_with_hdmi_format,

     output wire de_o_first_offset_line,
     output reg [23:0] display_vedio_left_offset,

     input frame_start_trig,//a
     output frame_busy,

     input frame_all_zeros,//we have to send all zero frame during acqisitaion, high active (captured at the edge of frame_start_trig)
     output reg de_with_all_zeros,

     input dmd_correct_15_pixles_slope,//added by wdf @2014/11/03 dmd_correct_15_pixles_slope==1'b1 the display will compensate the slope
     input dmd_flip_left_and_right,//flip left and right //left right flip: flip first, the correct the 15 pixels == correct the -15 pixels and then flip

     output reg [10:0] frame_count
);


reg [10:0]r_pixel_cnt;  //0~2043
reg [10:0]r_line_cnt;  //0~2043
reg s_hsync,s_vsync,s_de_phase;
reg [10:0] pixel_number;

reg s_hsync_hdmi,s_vsync_hdmi,s_de;

wire [11:0] tmp1;
wire [2:0] tmp2;
assign tmp1 = `DISPLAY_DMD_FAST_V_TOP_OFFSET_TRIG;
assign tmp2 = `DISPLAY_DMD_FAST_EXTRA_TRIG;

wire [11:0] tmp3;
wire [2:0] tmp4;

assign tmp3 = `DISPLAY_DMD_FAST_V_TOP_OFFSET + `DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME + 1;
assign tmp4 = `DISPLAY_DMD_FAST_EXTRA_TRIG;

always @(pixel_number,tmp1,tmp2,tmp3,tmp4)
begin
    if(pixel_number[0]==1'b0 & pixel_number<12)
    begin
        display_vedio_left_offset = {1'b1,2'b0,dmd_correct_15_pixles_slope,dmd_flip_left_and_right,4'h0,tmp2,tmp1};//{1'b1,8'h0,tmp2,tmp1};
    end
    else if(pixel_number[0]==1'b1 & pixel_number<12)
    begin
        display_vedio_left_offset = {1'b1,2'b0,dmd_correct_15_pixles_slope,dmd_flip_left_and_right,4'h0,tmp4,tmp3};//{1'b1,8'h0,tmp4,tmp3};
    end
    else
    begin
        display_vedio_left_offset = `DISPLAY_DMD_FAST_H_LEFT_OFFSET;
    end
end

reg s_de_first_line;

reg display_busy;

assign frame_busy = display_busy;
//sync signal generation
always@(posedge clk_i or negedge rst_ni)//
begin
    if (rst_ni == 1'b0)
        r_pixel_cnt <= 0;
    else
     begin
        if (r_pixel_cnt >= `DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD)///
          begin
            r_pixel_cnt <= 0;
            end
        else if(display_busy)
          begin
            r_pixel_cnt <= r_pixel_cnt + 1'b1;
            end
     end

    if (rst_ni == 1'b0)
     begin
        r_line_cnt <= 11'd0;
          display_busy <= 1'b0;
          de_with_all_zeros <= 1'b0;
     end
    else
     begin
          if(display_busy)
          begin
                if (r_pixel_cnt == `DISPLAY_DMD_FAST_H_WHOLE_LINE_PRD)
                    if (r_line_cnt < `DISPLAY_DMD_FAST_V_WHOLE_FRAME_PRD)
                    begin
                        r_line_cnt  <= r_line_cnt + 1'b1;
                    end
                    else
                    begin
                        r_line_cnt  <= 11'd0;
                        display_busy <= 1'b0;
                    end
          end
          else if(frame_start_trig)
          begin
                r_line_cnt  <= 11'd0;
                display_busy <= 1'b1;
                if(frame_all_zeros)
                begin
                    de_with_all_zeros <= 1'b1;
                end
                else
                begin
                    de_with_all_zeros <= 1'b0;
                end
          end
     end


    //with camera format  == 用于发送给内部的phase的一个被控制的信号 -- 对于内部phase 而言，控制信号只有一段
    //
    if (rst_ni == 1'b0)     //hsync generation
        s_hsync <= 1'b0;
    else
     begin
            if (r_line_cnt >= (`DISPLAY_DMD_FAST_V_SYNC_PLUSE + `DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH + 1 + `DISPLAY_DMD_FAST_V_TOP_OFFSET) && r_line_cnt < (`DISPLAY_DMD_FAST_V_SYNC_PLUSE + `DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH + 1 + `DISPLAY_DMD_FAST_V_TOP_OFFSET + `DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME))
            begin
                if (r_pixel_cnt < `DISPLAY_DMD_FAST_H_SYNC_PLUSE)
                    s_hsync <= display_busy;//1'b1;
                else
                    s_hsync <= 1'b0;
            end
            else
            begin
                    s_hsync <= 1'b0;
            end
      end

    if (rst_ni == 1'b0)     //vsync generation
        s_vsync <= 1'b1;
          //modified @2015/02/17
    else if (r_line_cnt >= (`DISPLAY_DMD_FAST_V_SYNC_PLUSE + `DISPLAY_DMD_FAST_V_TOP_OFFSET) && r_line_cnt < (`DISPLAY_DMD_FAST_V_WHOLE_FRAME_PRD - `DISPLAY_DMD_FAST_V_SYNC_FRONT_PORCH))//active low
        s_vsync <= 1'b0;
    else
      s_vsync <= 1'b1;


    /****************with hdmi format***************************/

     if (rst_ni == 1'b0)     //hsync generation
        s_hsync_hdmi <= 1'b0;
    else
        if (r_pixel_cnt < `DISPLAY_DMD_FAST_H_SYNC_PLUSE)
            s_hsync_hdmi <= display_busy;//1'b1;
        else
            s_hsync_hdmi <= 1'b0;

    if (rst_ni == 1'b0)     //vsync generation
        s_vsync_hdmi <= 1'b0;
    else
        if (r_line_cnt < `DISPLAY_DMD_FAST_V_SYNC_PLUSE)
            s_vsync_hdmi <= display_busy;//1'b1;
        else
            s_vsync_hdmi <= 1'b0;

    /****************with hdmi format***************************/

     //s_de是所有的de value
    if (rst_ni == 1'b0)
        s_de <= 1'b0;
    else
        if (r_line_cnt >= (`DISPLAY_DMD_FAST_V_SYNC_PLUSE + `DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH) && r_line_cnt < (`DISPLAY_DMD_FAST_V_WHOLE_FRAME_PRD - `DISPLAY_DMD_FAST_V_SYNC_FRONT_PORCH))
            if (r_pixel_cnt >= (`DISPLAY_DMD_FAST_H_SYNC_PLUSE + `DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH ) && r_pixel_cnt < (`DISPLAY_DMD_FAST_H_SYNC_PLUSE + `DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH + `DISPLAY_DMD_FAST_H_ACTIVE_TIME))
                s_de <= 1'b1;
            else
                s_de <= 1'b0;
        else
            s_de <= 1'b0;


     if (rst_ni == 1'b0)
        s_de_phase <= 1'b0;
    else
        if(r_line_cnt >= (`DISPLAY_DMD_FAST_V_SYNC_PLUSE + `DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH + 1 + `DISPLAY_DMD_FAST_V_TOP_OFFSET) && r_line_cnt < (`DISPLAY_DMD_FAST_V_SYNC_PLUSE + `DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH + 1 + `DISPLAY_DMD_FAST_V_TOP_OFFSET + `DISPLAY_DMD_FAST_V_PHASE_ACTIVE_TIME))
            if (r_pixel_cnt >= (`DISPLAY_DMD_FAST_H_SYNC_PLUSE + `DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH ) && r_pixel_cnt < (`DISPLAY_DMD_FAST_H_SYNC_PLUSE + `DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH + `DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME))
                s_de_phase <= 1'b1;
            else
                s_de_phase <= 1'b0;
        else
            s_de_phase <= 1'b0;

    if (rst_ni == 1'b0)
        s_de_first_line <= 1'b0;
    else
       if ( r_line_cnt == (`DISPLAY_DMD_FAST_V_SYNC_PLUSE + `DISPLAY_DMD_FAST_V_SYNC_BACK_PORCH) ) //first line == control line
            if (r_pixel_cnt >= (`DISPLAY_DMD_FAST_H_SYNC_PLUSE + `DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH ) && r_pixel_cnt < (`DISPLAY_DMD_FAST_H_SYNC_PLUSE + `DISPLAY_DMD_FAST_H_SYNC_BACK_PORCH + `DISPLAY_DMD_FAST_H_PHASE_ACTIVE_TIME))
                s_de_first_line <= 1'b1;
            else
                s_de_first_line <= 1'b0;
        else
            s_de_first_line <= 1'b0;

end

assign  hsync_o_with_camera_format = s_hsync;
assign vsync_o_with_camera_format = s_vsync;//active low
assign de_o = s_de_phase;//active high

assign hsync_o_with_hdmi_format = s_hsync_hdmi;
assign vsync_o_with_hdmi_format = s_vsync_hdmi;
assign de_o_with_hdmi_format = s_de;

assign de_o_first_offset_line = s_de_first_line;

reg s_vsync_dl;

always@(posedge clk_i or negedge rst_ni)//
begin
    if (rst_ni == 1'b0)
     begin
        frame_count <= 1'b0;
          s_vsync_dl <= 1'b0;
     end
    else
     begin
        if(s_vsync_dl == 1'b0 & s_vsync==1'b1)
        begin
            frame_count <= frame_count + 1'b1;
       end
        s_vsync_dl <= s_vsync;
     end
end

always@(posedge clk_i or negedge rst_ni)
begin
    if (rst_ni == 1'b0)
    begin
        pixel_number <= 'h0;
    end
    else if(s_hsync_hdmi | s_vsync_hdmi)
    begin
        pixel_number <= 'h0;
    end
    else if(s_de)
    begin
        pixel_number <= pixel_number + 1'b1;
    end
end




endmodule

//SuperVGA timing from NEC monitor manual
//Horizontal :
//                ______________                 _____________
//               |              |               |
//_______________|  VIDEO       |_______________|  VIDEO (next line)
//
//___________   _____________________   ______________________
//           |_|                     |_|
//            B C <------D-----><-E->
//            <----------A---------->
//
//
//Vertical :
//                ______________                 _____________
//               |              |               |
//_______________|  VIDEO       |_______________|  VIDEO (next frame)
//
//___________   _____________________   ______________________
//           |_|                     |_|
//            P Q <------R-----><-S->
//            <----------O---------->
//
//For VESA 800*600 @ 60Hz:
//Fh (kHz) :37.88
//A  (us)  :26.4
//B  (us)  :3.2
//C  (us)  :2.2
//D  (us)  :20.0
//E  (us)  :1.0
//
//Fv (Hz)  :60.32
//O  (ms)  :16.579
//P  (ms)  :0.106
//Q  (ms)  :0.607
//R  (ms)  :15.84
//S  (ms)  :0.026
//
//Information source
//NEC Multisync manual
//
//--------------------------------------------------------------------------------
//
//Necessary timing information about VGA modes
//
//Vertical timing information
//Mode name          Lines   line    sync      back        active     front     whole frame
//                   Total   width   pulse     porch        time      porch        period
//                           (us)   (us)(lin) (us)(lin)  (us)  (lin)  (us)(lin)  (us)  (lin)
//
//VGA 640x480 60Hz    525    31.78   63   2   953   30   15382  484   285    9   16683  525
//VGA 640x480 72Hz    520    26.41   79   3   686   26   12782  484   184    7   13735  520
//VGA 720x400 70Hz    449    31.78   63   2  1016   32   12839  404   349   11   14268  449
//VGA 720x350 70Hz    449    31.78   63   2  1811   57   11250  354  1144   36   14268  449
//VGA 800x600 56Hz    625    28.44   56   1   568   20   17177  604         -1*  17775  625
//VGA 800x600 60Hz    628    26.40  106   4   554   21   15945  604         -1*  16579  628
//VGA 800x600 72Hz    666    20.80  125   6   436   21   12563  604   728   35   13853  666
//IBM 640x480 75Hz    525    25.397  51   2   761   30   12292  484   228    9   13333  525
//MAC 640x480 66Hz    525    28.57   86   3  1057   37   13827  484    28    1   14999  525
//
//Notes:
//Active area is actually an active area added with 4 overscan border lines (in some other VGA timing tables those border lines are included in back and front porch)
//Note than when the active part of VGA page is widened, it passes by the rising edge of the vertical sync signal in some modes (marked with *)
//
//Horizonal timing information
//
//Mode name          Pixel      sync      back  active  front whole line
//                   clock      pulse     porch  time   porch  period
//                   (MHz)   (us)  (pix)  (pix)  (pix)  (pix)  (pix)
//
//VGA 640x480 60Hz   25.175   3.81   96     45    646    13     800
//VGA 640x480 72Hz   31.5     1.27   40    125    646    21     832
//VGA 720x400 70Hz   28.322   3.81  108     51    726    15     900
//VGA 720x350 70Hz   28.322   3.81  108     51    726    15     900
//VGA 800x600 56Hz   36       2      72    125    806    21    1024
//VGA 800x600 60Hz   40       3.2   128     85    806    37    1056
//VGA 800x600 72Hz   50       2.4   120     61    806    53    1040
//IBM 640x480 75Hz   31.5     3.05   96     45    646    13     800
//MAC 640x480 66Hz   30.24    2.11   64     93    646    61     864
