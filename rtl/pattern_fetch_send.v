`timescale 1ns/1ps
module pattern_fetch_send (
    input           pixel_clk,
    input           pixel_rst_n,

    input [11:0]    pixel_x,
    input [11:0]    pixel_y,
    input           pixel_de,
    input           pixel_hs,
    input           pixel_vs,
    input           de_first_offset_line_in,
    input [23:0]    display_video_left_offset_in,

    input [11:0]    image_width,
    input [11:0]    image_height,
    input [1:0]     image_color,

    //output reg      pat_ready_out,
    // Interface to HDMI chip
    output reg         gen_de,
    output reg         gen_hs,
    output reg         gen_vs,
    output reg [7:0]    gen_r,
    output reg [7:0]    gen_g,
    output reg [7:0]    gen_b,

    // On-chip memory bus
    output reg          onchip_mem_clken,
    output reg          onchip_mem_chip_select,
    output reg          onchip_mem_read,
    input wire [255:0]  onchip_mem_rddata,
    output reg [10:0]   onchip_mem_addr,
    output reg [31:0]   onchip_mem_byte_enable,
    output reg          onchip_mem_write,
    output reg [255:0]  onchip_mem_write_data,

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
    output [4:0]    ddr3_emif_burst_count
);


localparam  DDR3_IDLE = 3'd0,
            DDR3_RD_HEAD = 3'd1,
            DDR3_RD_HEAD_WAIT = 3'd2,
            DDR3_RD_BODY = 3'd3,
            DDR3_RD_BODY_WAIT = 3'd4;

// ------------------------------------- DDR3 read operation ---------------------------------------

wire [31:0] pat_total_pix_w;
// the number of total patterns
reg [31:0]  pat_num_ddr3;
// The times of reading one-pattern data from DDR3
reg [23:0]  per_pat_read_ddr3_cnt;
reg [23:0]  per_pat_read_ddr3_times;

reg [2:0]   ddr3_rd_state/*synthesis keep*/;

wire        ddr3_rd_start;
reg         ddr3_rd;
reg [21:0]  ddr3_rd_addr;

wire        ddr3_rddata_valid;
wire [255:0]ddr3_rddata;

wire        fifo_wr_clk, fifo_rd_clk;
wire        fifo_wr_ena, fifo_full /*synthesis keep*/;
wire        fifo_empty/*synthesis keep*/;
wire        fifo_rd_ena/*synthesis keep*/;
wire [255:0]fifo_wr_data, fifo_rd_data/*synthesis keep*/;


assign ddr3_rddata = ddr3_emif_read_data;
assign ddr3_rddata_valid = ddr3_emif_rddata_valid;
assign ddr3_emif_read = ddr3_rd;
assign ddr3_emif_addr = ddr3_rd_addr;
assign ddr3_rd_start = start;

assign fifo_wr_clk = ddr3_emif_clk;
assign fifo_wr_ena = ddr3_rddata_valid;
assign fifo_wr_data = ddr3_rddata;

assign pat_total_pix_w = ddr3_rddata[191:159];


always @(posedge ddr3_emif_clk or negedge ddr3_emif_rst_n) begin
    if(~ddr3_emif_rst_n) begin
        ddr3_rd <= 0;
        ddr3_rd_addr <= 0;
        per_pat_read_ddr3_times <= 0;
        per_pat_read_ddr3_cnt <= 0;
        ddr3_rd_state <= DDR3_IDLE;
        pat_num_ddr3 <= 'h0;

        onchip_mem_clken <= 0;
        onchip_mem_chip_select <= 0;
        onchip_mem_write <= 0;
        onchip_mem_addr <= 0;
        onchip_mem_byte_enable <= 0;
        onchip_mem_write_data <= 0;
        onchip_mem_read <= 0;
        onchip_mem_clken <= 0;

    end else begin
        onchip_mem_clken <= 0;
        onchip_mem_chip_select <= 0;
        onchip_mem_write <= 0;
        onchip_mem_addr <= 0;
        onchip_mem_byte_enable <= 0;
        onchip_mem_write_data <= 0;
        onchip_mem_read <= 0;
        onchip_mem_clken <= 0;

        case (ddr3_rd_state)
            DDR3_IDLE: begin
                // Read on-chip memory to determine whether the data has been loaded in DDR3
                onchip_mem_chip_select <= ddr3_rd_start;
                onchip_mem_read <= ddr3_rd_start;
                onchip_mem_addr <= 0;
                onchip_mem_clken <= 1;

                ddr3_rd_addr <= 'h1;
                ddr3_rd <= 1'b0;

                     if (ddr3_rd_start) begin
                        onchip_mem_addr <= 2;
                    end

                //if (ddr3_rd_start) ddr3_rd_state <= DDR3_RD_HEAD;
                if ((onchip_mem_rddata == 256'h77))
                        ddr3_rd_state <= DDR3_RD_HEAD;;
            end
            DDR3_RD_HEAD: begin
                if (!fifo_full && ddr3_emif_ready) begin
                    ddr3_rd <= 1'b1;
                    ddr3_rd_addr <= 22'h0;
                    ddr3_rd_state <= DDR3_RD_HEAD_WAIT;
                end
            end
            // Wait valid rddata
            DDR3_RD_HEAD_WAIT: begin
                ddr3_rd <= 1'b0;
                if (ddr3_rddata_valid) begin
                    ddr3_rd_state <= DDR3_RD_BODY;
                    ddr3_rd_addr <= ddr3_rd_addr + 1'd1;
                    // Acquire the total read times for one pattern, and get 256-bit every read operation
                    per_pat_read_ddr3_times <= pat_total_pix_w[31:9] + (|pat_total_pix_w[7:0]);
                    //pat_read_ddr3_times_reg <= pat_total_pix_w[31:9] + (|pat_total_pix_w[7:0]);
                    pat_num_ddr3 <= ddr3_rddata[255-32*3-1:255-32*4];
                end
            end
            DDR3_RD_BODY: begin
                if (pat_num_ddr3 == 'h1 && per_pat_read_ddr3_cnt == (per_pat_read_ddr3_times -1'd1))
                    ddr3_rd <= 1'b0;
                else
                    ddr3_rd <= 1'b1;
                ddr3_rd_state <= DDR3_RD_BODY_WAIT;
            end
            DDR3_RD_BODY_WAIT: begin
                ddr3_rd <= 1'b0;
                if ((per_pat_read_ddr3_cnt == (per_pat_read_ddr3_times -1'd1)) && ddr3_rddata_valid) begin
                    // Finish reading all the patterns
                    if (pat_num_ddr3 == 'h1) begin
                        ddr3_rd_state <= DDR3_IDLE;
                    end
                    // Finish reading one pattern
                    else begin
                        pat_num_ddr3 <= pat_num_ddr3 - 1'd1;
                        ddr3_rd_state <= DDR3_RD_BODY;
                        per_pat_read_ddr3_cnt <= 'h0;
                    end
                end
                else if (ddr3_rddata_valid) begin
                    ddr3_rd_addr <= ddr3_rd_addr + 1'd1;
                    ddr3_rd_state <= DDR3_RD_BODY;
                    //pat_read_ddr3_times <= pat_read_ddr3_times - 1'd1;
                    per_pat_read_ddr3_cnt <= per_pat_read_ddr3_cnt + 1'd1;
                end
            end
            default :begin
                ddr3_rd_addr <= 0;
                ddr3_rd <= 1'b0;
                ddr3_rd_state <= DDR3_IDLE;
            end
         endcase
    end
end

dcfifo_256inx512 dcfifo_256inx512_inst (
    .data    (fifo_wr_data),    //  fifo_input.datain
    .wrreq   (fifo_wr_ena),   //            .wrreq
    .rdreq   (fifo_rd_ena),   //            .rdreq
    .wrclk   (fifo_wr_clk),   //            .wrclk
    .rdclk   (fifo_rd_clk),   //            .rdclk
    .q       (fifo_rd_data),       // fifo_output.dataout
    .rdempty (fifo_empty), //            .rdempty
    .wrfull  (fifo_full)   //            .wrfull
);

// ------------------------------------- Transfer pixel ---------------------------------------
assign fifo_rd_clk = pixel_clk;

localparam  PAT_TX_IDLE = 3'd0,
            PAT_TX_HEAD = 3'd1,
            PAT_TX_HEAD_WAIT = 3'd2,
            PAT_TX_BODY = 3'd3,
            PAT_TX_BODY_WAIT = 3'd4,
            PAT_TX_TAIL = 3'd5,
            PAT_TX_TAIL_WAIT = 3'd6;
reg [2:0]   pat_tx_state;
// For one pattern, the times of reading FIFO
reg [23:0]  per_pat_read_times;
// Whether need to read tail.
reg         per_pat_read_tail;
// Flags the last pat
reg         last_pat_flag;
// Fill the same pixel in the horizonal direction to meet 1920
reg [7:0]   h_fill_cnt;
reg [7:0]   per_pat_tail_pixel_num;


// Pattern signals
reg [31:0]  pat_h_pix, pat_v_pix, pat_total_pix;
reg [31:0]  pat_num, h_fill_size, v_fill_size;
reg [31:0]  pat_start_addr, pat_end_addr;

always @(posedge pixel_clk or negedge pixel_rst_n) begin
    if(~pixel_rst_n) begin
        pat_tx_state <= PAT_TX_IDLE;
        //fifo_rd_ena <= 1'b0;
        //pat_ready_out <= 1'b0;
        per_pat_read_times <= 'h0;
        per_pat_read_tail <= 1'b0;
        per_pat_tail_pixel_num <= 'h0;
        last_pat_flag <= 1'b0;
        {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, h_fill_size, v_fill_size, pat_start_addr, pat_end_addr} <= 'h0;
    end else begin
         case(pat_tx_state)
            PAT_TX_IDLE: begin
                //pat_ready_out <= 1'b0;
                // Assume as long as the fifo is not empty in the idle state, it means pattern data is updated in FIFO
                // HOW TO CONTROL ??
                if (!fifo_empty) begin
                    pat_tx_state <= PAT_TX_HEAD;
                    //fifo_rd_ena <= 1'b1;
                    // FIFO output delay is 1 cycle
                end
            end
            PAT_TX_HEAD: begin
              //  fifo_rd_ena <= 1'b1;
                pat_tx_state <= PAT_TX_HEAD_WAIT; // Wait one cycle for the valid output data from FIFO
            end
            PAT_TX_HEAD_WAIT: begin
              //  fifo_rd_ena <= 1'b0;
                //pat_ready_out <= 1'b1;
                {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, h_fill_size, pat_start_addr, pat_end_addr, pat_rsv} <= fifo_rd_data;
                pat_tx_state <= PAT_TX_BODY;
            end
            PAT_TX_BODY: begin // Read a whole 256-bit data, named as body
                per_pat_read_times <= pat_total_pix[31:8] + (|pat_total_pix[7:0]);
                per_pat_read_tail <= |pat_total_pix[7:0];
                per_pat_tail_pixel_num <= pat_total_pix[7:0]; // The last 256 bit or less than 256
               // fifo_rd_ena <= 1'b1;
                pat_tx_state <= PAT_TX_BODY_WAIT;
            end
            PAT_TX_BODY_WAIT: begin
                //No filling
                if (h_fill_size == 'h0) begin // 1920x1080
                    if (shift_cnt == 8'd254) begin
                        per_pat_read_times <= per_pat_read_times - 1'd1;
                        if (per_pat_read_times == 'h2 && per_pat_read_tail) begin // Read enough data for one line
                            pat_tx_state <= PAT_TX_TAIL;
                            last_pat_flag <= 1'b1;
                        end
                        else if (per_pat_read_times == 'h1 && !per_pat_read_tail) begin
                            pat_tx_state <= PAT_TX_IDLE;
                            last_pat_flag <= 1'b1;
                            end
                        else begin
                            pat_tx_state <= PAT_TX_BODY;
                        end
                    end
                end
                else begin
                    if (shift_cnt == 8'd255 && h_fill_cnt == (h_fill_size - 2)) begin
                        per_pat_read_times <= per_pat_read_times - 1'd1;
                        if (per_pat_read_times == 'h2 && per_pat_read_tail) begin // Start to send the last 256 bit
                            pat_tx_state <= PAT_TX_TAIL;
                            last_pat_flag <= 1'b1;
                        end
                        else if (per_pat_read_times == 'h1 && !per_pat_read_tail) begin // If the tail
                            pat_tx_state <= PAT_TX_IDLE;
                            last_pat_flag <= 1'b1;
                            end
                        else begin
                            pat_tx_state <= PAT_TX_BODY;
                        end
                    end
                end
            end
            PAT_TX_TAIL: begin
               // fifo_rd_ena <= 1'b1;
                pat_tx_state <= PAT_TX_TAIL_WAIT;
            end
            PAT_TX_TAIL_WAIT: begin
               // No filling
               if (h_fill_size == 'h0) begin
                    // The last pixel
                    if (per_pat_tail_pixel_num == 'd1) begin
                        pat_num <= pat_num - 1'd1;
                        if (pat_num == 1'b1) begin
                            pat_tx_state <= PAT_TX_IDLE;
                        end
                        else begin
                            pat_tx_state <= PAT_TX_BODY;
                        end
                    end
                    else if (shift_cnt == (per_pat_tail_pixel_num - 2'd2)) begin
                        pat_num <= pat_num - 1'd1;
                        if (pat_num == 1'b1) begin
                            pat_tx_state <= PAT_TX_IDLE;
                        end
                    end
                    else begin
                        pat_tx_state <= PAT_TX_BODY;
                    end
                end
                // Have fillings
                else begin
                    // The tail length is 1
                    if (shift_cnt == (per_pat_tail_pixel_num - 1'd1) && h_fill_cnt == (h_fill_size - 2)) begin
                        pat_num <= pat_num - 1'd1;
                        if (pat_num == 'b0) begin
                            pat_tx_state <= PAT_TX_IDLE;
                        end
                        else begin
                            pat_tx_state <= PAT_TX_BODY;
                        end
                    end
                end
            end
            default: begin
                pat_tx_state <= PAT_TX_IDLE;
            end
        endcase
    end
end

assign fifo_rd_ena = (pat_tx_state == PAT_TX_HEAD | pat_tx_state == PAT_TX_BODY
                    | pat_tx_state == PAT_TX_TAIL |
                    (pat_tx_state == PAT_TX_TAIL_WAIT && shift_cnt == (per_pat_tail_pixel_num - 2'd1)
                        && h_fill_cnt == (h_fill_size - 2'd2) && h_fill_size!= 0))
                    |(pat_tx_state == PAT_TX_TAIL_WAIT && shift_cnt == (per_pat_tail_pixel_num - 2'd2) && h_fill_size == 'd0);

reg [7:0]   shift_cnt;
reg         h_shift_valid;
wire        msb_pat_data;
reg [7:0]   vpg_r, vpg_g, vpg_b;
 // Count the pixel in every de, and set 81st and 82nd pixel to be '0'
reg [6:0]   pix_cnt_per_de;
wire        h_fill_true;
wire        v_file_true;
reg [5:0]   v_fill_cnt;
reg         de_first_offset_line_r, de_first_offset_line_p;
reg         de_r, de_p;
assign      h_fill_true = |h_fill_size;
assign      v_fill_true = |v_fill_size;

// Generate every pixel output
assign msb_pat_data = h_shift_valid ? fifo_rd_data[255 - shift_cnt] : 1'b0;


always @(posedge pixel_clk or negedge pixel_rst_n) begin
    if(~pixel_rst_n) begin
        de_first_offset_line_r <= 0;
        de_first_offset_line_p <= 0;
        de_r <= 0;
        de_p <= 0;
    end else begin
        de_first_offset_line_r <= de_first_offset_line_in;
        de_first_offset_line_p <= ~de_first_offset_line_r & de_first_offset_line_in;
        de_r <= pixel_de;
        de_p <= ~de_r & pixel_de;
    end
end

always @(posedge pixel_clk or negedge pixel_rst_n) begin
    if(~pixel_rst_n) begin
         shift_cnt <= 0;
         h_fill_cnt <= 0;
         v_fill_cnt <= 0;
         pix_cnt_per_de <= 0;
         h_shift_valid <= 0;
    end else begin
        // When gen_de is '1', the pixel data should be ready and start to send pixel data
        // No need to fill the pixel
        if (pat_tx_state == PAT_TX_BODY_WAIT && pixel_de) begin
                pix_cnt_per_de <= pix_cnt_per_de + 1'd1;
            end
            else if (pat_tx_state == PAT_TX_TAIL_WAIT && pixel_de) begin
                pix_cnt_per_de <= pix_cnt_per_de + 1'd1;
            end
            else begin
                pix_cnt_per_de <= 'h0;
            end
        end

        // Initiate v_fill_cnt at the beginning of every picture
        if (de_first_offset_line_p) begin
            v_fill_cnt <= 0;
        end

        case ({h_fill_true, v_fill_true})
            2'b00: begin
                if ((pat_tx_state == PAT_TX_BODY_WAIT || pat_tx_state == PAT_TX_TAIL_WAIT) && pixel_de && (pix_cnt_per_de < 7'd80)) begin
                    shift_cnt <= shift_cnt + 1'd1;
                    h_shift_valid <= 1;
                end
                else begin
                    h_shift_valid <= 0; // Indicate the shift_cnt is not valid
                end
            end
            2'b01: begin
                if (v_fill_cnt == 'h0) begin
                    if ((pat_tx_state == PAT_TX_BODY_WAIT || pat_tx_state == PAT_TX_TAIL_WAIT) && pixel_de && (pix_cnt_per_de < 7'd80)) begin
                        shift_cnt <= shift_cnt + 1'd1;
                        h_shift_valid <= 1;
                    end
                end
                else begin
                    h_shift_valid <= 1'b0;
                    if (pix_cnt_per_de == 7'd81) begin
                        if (v_fill_cnt == (v_fill_size - 1'd1)) begin
                            v_fill_cnt <= 'h0;
                        end
                        else begin
                         v_fill_cnt <= v_fill_cnt + 1'd1;
                        end
                    end
                end
                else begin
                    h_shift_valid <= 1'b0; // Indicate the shift_cnt is not valid
                end
            end




        if (h_fill_size == 'h0) begin
            if (pat_tx_state == PAT_TX_BODY_WAIT && pixel_de) begin
               pix_cnt_per_de <= pix_cnt_per_de + 1'd1;
           end
           else if (pat_tx_state == PAT_TX_TAIL_WAIT && pixel_de) begin
                 pix_cnt_per_de <= pix_cnt_per_de + 1'd1;
            end
            else begin
                 pix_cnt_per_de <= 'h0;
            end

            if ((pat_tx_state == PAT_TX_BODY_WAIT || pat_tx_state == PAT_TX_TAIL_WAIT) && pixel_de && (pix_cnt_per_de < 7'd80)) begin
                shift_cnt <= shift_cnt + 1'd1;
                h_shift_valid <= 1;
            end
            else begin
                h_shift_valid <= 0; // Indicate the shift_cnt is not valid
            end

        end
        else begin // horizontal pixel filling
            if (pat_tx_state == PAT_TX_BODY_WAIT && pixel_de) begin
                pix_cnt_per_de <= pix_cnt_per_de + 1'd1;
            end
            else if (pat_tx_state == PAT_TX_TAIL_WAIT && pixel_de) begin
               pix_cnt_per_de <= pix_cnt_per_de + 1'd1;
            end
            else begin
                pix_cnt_per_de <= 0;
            end

            if (pat_tx_state == PAT_TX_BODY_WAIT && pixel_de && (pix_cnt_per_de < 7'd80)) begin
                h_fill_cnt <= h_fill_cnt + 1'd1;
                 h_shift_valid <= 1;
                if (h_fill_cnt == (h_fill_size - 1)) begin // Shift out the new bit from fifo_rd_data
                    shift_cnt <= shift_cnt + 1'd1;
                    h_fill_cnt <= 'h0;
                end
            end
            else if (pat_tx_state == PAT_TX_TAIL_WAIT && pixel_de && (pix_cnt_per_de < 7'd80)) begin
                h_fill_cnt <= h_fill_cnt + 1'd1;
                 h_shift_valid <= 1;
                if (shift_cnt != (per_pat_tail_pixel_num - 1) && h_fill_cnt == (h_fill_size - 1)) begin
                    shift_cnt <= shift_cnt + 1'd1;
                    h_fill_cnt <= 'h0;
                end
            else begin
                h_shift_valid <= 0; // Indicate the shift_cnt is not valid
            end
        end


    end
end

//-----------------------------------
//Cache every line pixel output for the vertial filling
wire [31:0]         line_pix_cache_din;
wire [31:0]         line_pix_cache_dout;
wire [7:0]          line_pix_cache_wr_addr;
wire [7:0]          line_pix_cache_rd_addr;

reg                 line_pix_cache_wr;

always @(posedge pixel_clk or negedge pixel_rst_n) begin
    if(~pixel_rst_n) begin
         line_pix_cache_wr <= 1'b0;
         line_pix_cache_din <= 'h0;
    end else begin

        if (h_shift_valid && shift_cnt == 7'd31) begin
            line_pix_cache_din <= fifo_rd_data[255:224];
            line_pix_cache_wr <= 1'b1;
        end
        else if (h_shift_valid && shift_cnt == 7'd63) begin
            line_pix_cache_din <= fifo_rd_data[223:192];
            line_pix_cache_wr <= 1'b1;
        end
        else if (h_shift_valid && shift_cnt == 7'd95) begin
            line_pix_cache_din <= fifo_rd_data[191:160];
            line_pix_cache_wr <= 1'b1;
        end
        else if (h_shift_valid && shift_cnt == 7'd127) begin
            line_pix_cache_din <= fifo_rd_data[159:128];
            line_pix_cache_wr <= 1'b1;
        end
        else if (h_shift_valid && shift_cnt == 7'd159) begin
            line_pix_cache_din <= fifo_rd_data[127:96];
            line_pix_cache_wr <= 1'b1;
        end
        else if (h_shift_valid && shift_cnt == 7'd191) begin
            line_pix_cache_din <= fifo_rd_data[95:64];
            line_pix_cache_wr <= 1'b1;
        end
        else if (h_shift_valid && shift_cnt == 7'd223) begin
            line_pix_cache_din <= fifo_rd_data[63:32];
            line_pix_cache_wr <= 1'b1;
        end
        else if (h_shift_valid && shift_cnt == 7'd255) begin
            line_pix_cache_din <= fifo_rd_data[31:0];
            line_pix_cache_wr <= 1'b1;
        end
        else begin
            line_pix_cache_wr <= 1'b0;
        end
            //TODO
    end
end

line_pix_cache dpram_32inx64 (
    .clock(pixel_clk),
    .data(line_pix_cache_din),
    .rdaddress(line_pix_cache_rd_addr),
    .wraddress(line_pix_cache_wr_addr),
    .wren(line_pix_cache_wr),
    .q(line_pix_cache_dout)
);

always @(posedge pixel_clk or negedge pixel_rst_n) begin
    if(~pixel_rst_n) begin
        {gen_r, gen_g, gen_b} <= 'h0;
        gen_de <= 1'b0;
        gen_hs <= 1'b1;
        gen_vs <= 1'b1;
    end else begin
        gen_de <= pixel_de;
        gen_hs <= pixel_hs;
        gen_vs <= pixel_vs;
         case(msb_pat_data)
            1'b1: {gen_r, gen_g, gen_b} <= 'h0; // black
            1'b0: {gen_r, gen_g, gen_b} <= 24'hffffff; // white
        endcase // msb_pat_data
    end
end


endmodule