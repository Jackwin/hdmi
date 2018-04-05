`timescale 1 ns / 1 ps
module fast_pat_fetch (
    // onchip-mem shares the clock with hdmi
    input           clk,
    input           rst_n,

    output          onchip_mem_chip_select,
    output          onchip_mem_clk_ena,
    output          onchip_mem_chip_read,
    output [12:0]   onchip_mem_addr,
    output [31:0]   onchip_mem_byte_enable,
    output [255:0]  onchip_mem_write_data,
    output          onchip_mem_write,
    input [255:0]   onchip_mem_read_data,

    // DDR3 signals
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

    input           start,
    output reg      frame_trig,
    input           frame_busy,
    input           h_sync_in,
    input           v_sync_in,
    input           de_in,
    input           de_first_offset_line_in,
    input [23:0]    display_video_left_offset_in,
    output reg      h_sync_out,
    output reg      v_sync_out,
    output reg      de_out,
    output reg [23:0]   pix_data_out

);

localparam  DDR3_READ_DELAY = 6;
localparam ON_CHIP_MEM_READ_DEALY = 1;
localparam  DDR3_IDLE = 3'd0,
            DDR3_READ_HEAD = 3'd1,
            DDR3_READ_HEAD_WAIT = 3'd2,
            DDR3_READ_BODY = 3'd3,
            DDR3_READ_BODY_WAIT = 3'd4;

// ------------------------------------- DDR3 read operation ---------------------------------------

// the number of total patterns
reg [31:0]  pat_num_ddr3;
// The times of reading one-pattern data from DDR3
reg [23:0]  per_pat_read_ddr3_cnt;
reg [23:0]  per_pat_read_ddr3_times;

reg [31:0]  pattern_total_num;
reg [15:0]  addr_space_per_pattern;
reg [15:0]  rsv0;
reg [15:0]  pattern_h_pix;
reg [15:0]  pattern_v_line;
// DDR3 signals
reg [2:0]   ddr3_read_state/*synthesis keep*/;
wire        ddr3_read_start;
reg         ddr3_read;
reg [21:0]  ddr3_read_addr;
wire        ddr3_read_data_valid;
wire [255:0]ddr3_read_data;
reg [11:0]  ddr3_read_r;
reg         ddr3_timer_ena;
wire        ddr3_timer_out;


// FIFO signals
wire        fifo_wr_clk, fifo_rd_clk;
wire        fifo_wr_ena, fifo_full /*synthesis keep*/;
wire        fifo_empty/*synthesis keep*/;
reg        fifo_rd_ena/*synthesis keep*/;
reg         fifo_rd_valid;
wire [255:0]fifo_wr_data, fifo_rd_data/*synthesis keep*/;
reg [2:0]   fifo_rd_cnt;

//--------------------------------------------
assign ddr3_read_data = ddr3_emif_read_data;
//assign ddr3_read_data_valid = ddr3_emif_rddata_valid;
assign ddr3_emif_read = ddr3_read;
assign ddr3_emif_addr = ddr3_read_addr;
assign ddr3_read_start = start;

assign fifo_wr_clk = ddr3_emif_clk;
assign fifo_wr_ena = ddr3_read_data_valid;
assign fifo_wr_data = ddr3_read_data;
assign fifo_rd_clk = clk;

// Generate ddr_rddata_valid according to the DDR3 read delay
always @(posedge ddr3_emif_clk) begin
    ddr3_read_r[DDR3_READ_DELAY-1:1] <= ddr3_read_r[DDR3_READ_DELAY-2:0];
    ddr3_read_r[0] <= ddr3_read;
end

assign ddr3_read_data_valid = ddr3_read_r[DDR3_READ_DELAY-1];

timer ddr3_read_timer (
    .clk      (ddr3_emif_clk),
    .rst_n    (ddr3_emif_rst_n),
    .timer_ena(ddr3_timer_ena),
    .timer_rst(0),
    .timer_out(ddr3_timer_out)
    );

always @(posedge ddr3_emif_clk or negedge ddr3_emif_rst_n) begin
    if(~ddr3_emif_rst_n) begin
        ddr3_read <= 0;
        ddr3_read_addr <= 0;
        per_pat_read_ddr3_cnt <= 0;
        ddr3_read_state <= DDR3_IDLE;
        //pat_num_ddr3 <= 'h0;
        ddr3_timer_ena <= 0;
        pattern_total_num <= 0;
        addr_space_per_pattern <= 0;
        pattern_h_pix <= 0;
        pattern_v_line <= 0;
    end else begin
        case (ddr3_read_state)
            DDR3_IDLE: begin
                ddr3_timer_ena <= 1'b1;
                ddr3_read_addr <= 'h0;
                ddr3_read <= ddr3_timer_out;
                if (ddr3_read_data[3:0] == 4'ha && ddr3_read_data_valid) begin
                    //onchip_mem_addr <= 2;
                    ddr3_read_state <= DDR3_READ_HEAD;
                    ddr3_timer_ena <= 1'b0;
                end
            end
            DDR3_READ_HEAD: begin
                if (!fifo_full && ddr3_emif_ready) begin
                    ddr3_read <= 1'b1;
                    ddr3_read_addr <= 22'h1;
                    ddr3_read_state <= DDR3_READ_HEAD_WAIT;
                end
            end
            // Wait valid rddata
            DDR3_READ_HEAD_WAIT: begin
                ddr3_read <= 1'b0;
                if (ddr3_read_data_valid) begin
                    ddr3_read_state <= DDR3_READ_BODY;
                    ddr3_read_addr <= ddr3_read_addr + 1'd1;
                    // Acquire the total read times for one pattern, and get 256-bit every read operation
                    //per_pat_read_ddr3_times <= pat_total_pix_w[31:9] + (|pat_total_pix_w[7:0]);
                    //pat_read_ddr3_times_reg <= pat_total_pix_w[31:9] + (|pat_total_pix_w[7:0]);
                    //pat_num_ddr3 <= ddr3_read_data[255-32*3-1:255-32*4];

                    pattern_total_num <= ddr3_read_data[31:0];
                    addr_space_per_pattern <= ddr3_read_data[47:32];
                    rsv0 <= ddr3_read_data[63:48];
                    pattern_h_pix <= ddr3_read_data[79:64];
                    pattern_v_line <= ddr3_read_data[95:80];
                end
            end
            DDR3_READ_BODY: begin
                if (pattern_total_num == 'h1 && per_pat_read_ddr3_cnt == (addr_space_per_pattern -1'd1))
                    ddr3_read <= 1'b0;
                else if (~fifo_full) begin
                    ddr3_read <= 1'b1;
                    ddr3_read_state <= DDR3_READ_BODY_WAIT;
                end
                else begin
                    ddr3_read <= 1'b0;
                end
            end
            DDR3_READ_BODY_WAIT: begin
                ddr3_read <= 1'b0;
                if ((per_pat_read_ddr3_cnt == (addr_space_per_pattern -1'd1)) && ddr3_read_data_valid) begin
                    // Finish reading all the patterns
                    if (pattern_total_num == 'h0) begin
                        ddr3_read_state <= DDR3_IDLE;
                    end
                    // Finish reading one pattern
                    else begin
                        pattern_total_num <= pattern_total_num - 1'd1;
                        ddr3_read_state <= DDR3_READ_BODY;
                        per_pat_read_ddr3_cnt <= 'h0;
                    end
                end
                else if (ddr3_read_data_valid) begin
                    ddr3_read_addr <= ddr3_read_addr + 1'd1;
                    ddr3_read_state <= DDR3_READ_BODY;
                    //pat_read_ddr3_times <= pat_read_ddr3_times - 1'd1;
                    per_pat_read_ddr3_cnt <= per_pat_read_ddr3_cnt + 1'd1;
                end
            end
            default :begin
                ddr3_read_addr <= 0;
                ddr3_read <= 1'b0;
                ddr3_read_state <= DDR3_IDLE;
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

always @(posedge clk) begin
    fifo_rd_valid <= fifo_rd_ena & (~fifo_empty);
end

//------------------------------------------------------------------------------------------

localparam  IDLE_s = 2'd0,
            INIT_READ_MEM_s = 2'd1,
            SEND_DATA_s = 2'd2,
            END_s = 2'd3;


reg [1:0]   state;

// DDR3 FIFO signals
reg data_source;
reg        timer_ena;
wire        timer_out;
wire        timer_rst;

// On-chip memory signals
reg [2:0]   mem_rd_cnt;
reg         mem_rd, mem_rd_r;
reg         mem_rd_valid;
reg         mem_sel;
reg         mem_clken;
reg [12:0]  mem_addr;
reg [255:0] mem_wr_data;
reg         mem_wr;
reg [31:0]  mem_wr_byte_ena;
reg [767:0] mem_data;
reg [4:0]   cnt; // 256-bit counter

// Pattern information register
reg [31:0]  mem_pattern_total_num;
reg [15:0]  mem_addr_space_per_pattern;
reg [15:0]  mem_rsv0;
reg [31:0]  mem_pattern_h_pix;
reg [31:0]  mem_pattern_v_line;

// Every de should contain 80 pixels (1920/24bit = 80), but it contains 82 to accomodate to the DMD
reg [6:0]   pix_cnt_per_de;
reg [11:0]  line_cnt;
reg [31:0]  mem_pattern_cnt;

assign onchip_mem_clk_ena = mem_clken;
assign onchip_mem_chip_select = mem_sel;
assign onchip_mem_chip_read = mem_rd;
assign onchip_mem_addr = mem_addr;
assign onchip_mem_write_data = mem_wr_data;
assign onchip_mem_write = mem_wr;
assign onchip_mem_byte_enable = mem_wr_byte_ena;

// The read latency is 2 for the onchip memory
always @(posedge clk) begin
    mem_rd_r <= mem_rd;
    mem_rd_valid <= mem_rd_r;
end

always @(posedge clk) begin
    if(~rst_n) begin
         mem_data <= 0;
    end else begin
        // data_source = 1 means reading data from on-chip memory
        if (data_source & mem_rd_valid) begin
            //mem_data[767:512] <= mem_data[511:256];
            //mem_data[511:256] <= mem_data[255:0];
            //mem_data[255:0] <= onchip_mem_read_data;\
            case(mem_rd_cnt)
                2'd0: mem_data[767:512] <= onchip_mem_read_data;
                2'd1: mem_data[511:256] <= onchip_mem_read_data;
                2'd2: mem_data[255:0] <= onchip_mem_read_data;
                2'd3: mem_data <= mem_data;
                //2'd3: mem_data <= mem_data;
                default:mem_data <= 'h0;
            endcase // mem_rd_cnt
        end
        // data-source = 0 means reading data from DDR3 FIFO
        else if (~data_source & fifo_rd_valid) begin
            case(fifo_rd_cnt)
                2'd0: mem_data[767:512] <= fifo_rd_data;
                2'd1: mem_data[511:256] <= fifo_rd_data;
                2'd2: mem_data[255:0] <= fifo_rd_data;
                2'd3: mem_data <= mem_data;
                //2'd3: mem_data <= mem_data;
                default:mem_data <= 'h0;
            endcase // mem_rd_cnt
        end
    end
end

// Count the lines
reg h_sync_r, h_sync_p;
reg v_sync_r, v_sync_p;
reg [15:0] h_sync_cnt;
reg de_r, de_p;
reg de_fall_r1, de_fall_edge;
always @(posedge clk) begin
    if(~rst_n) begin
        h_sync_r <= 1'b0;
        h_sync_p <= 1'b0;
        v_sync_r <= 1'b0;
        v_sync_p <= 1'b0;
        de_fall_edge <= 1'b0;
    end else begin
        h_sync_r <= h_sync_in;
        h_sync_p <= ~h_sync_r & h_sync_in;

        v_sync_r <= v_sync_in;
        v_sync_p <= ~v_sync_r & v_sync_in;

        // capturing the falling edge of de_in
        de_r <= de_in;
        de_p <= ~de_r & de_in;
        de_fall_edge <= ~de_in & de_r;
    end
end

// Count the line, and the total line is 1081
always @(posedge clk) begin
    if(~rst_n) begin
        line_cnt <= 0;
    end else begin
        if (v_sync_p) begin
            line_cnt <= 'h0;
        end
        else if (de_p) begin
            line_cnt <= line_cnt + 1'd1;
            $display("line_cnt is %d",line_cnt);
        end
        //else if (de_fall_edge) begin
        //    line_cnt <= 'h0;
       // end
    end
end

// Count the h_sync in order to switch to the next pattern

always @(posedge clk) begin
    if (~rst_n) begin
        h_sync_cnt <= 'h0;
    end
    else begin
        if (v_sync_p) begin
            h_sync_cnt <= 'h0;
        end
        else if (h_sync_p) begin
            h_sync_cnt <= h_sync_cnt + 1'd1;
        end
    end
end

reg [1:0]   tmp_cnt;
//  Output the pixel data
always @(posedge clk) begin
    if(~rst_n) begin
        state <= IDLE_s;
        timer_ena <= 1'b0;
        mem_rd_cnt <= 'h0;
        fifo_rd_cnt <= 'h0;
        mem_rd <= 1'b0;
        mem_addr <= 'h0;
        mem_sel <= 1'b0;
        frame_trig <= 1'b0;
        cnt <= 'h0;
        pix_data_out <= 'h0;
        pix_cnt_per_de <= 'h0;
        mem_wr <= 1'b0;
        mem_wr_data <= 'h0;
        mem_wr_byte_ena <= 'h0;
        mem_clken <= 1'b0;
        data_source <= 0;
        fifo_rd_ena <= 0;
        tmp_cnt <= 0;
        mem_pattern_cnt <= 'h0;
        mem_pattern_total_num <= 'h0;
        mem_addr_space_per_pattern <= 'h0;
        mem_pattern_h_pix <= 'h0;
        mem_pattern_v_line <= 'h0;
    end else begin
        mem_rd <= 1'b0;
        mem_wr <= 1'b0;
        mem_wr_byte_ena <= 'h0;
        mem_clken <= 1'b1;
        fifo_rd_ena <= 1'b0;
       // pix_cnt_per_de <= 'h0;
        case (state)
            IDLE_s: begin
                mem_sel <= 1'b1;
                mem_rd <= 1'b1;
                // Read data from on-chip memory
                if (onchip_mem_read_data[7:0] == 8'h55) begin
                    data_source <= 1'b1;
                    state <= INIT_READ_MEM_s;
                    mem_rd <= 1'b1;
                    mem_sel <= 1'b1;
                    mem_addr <= 'h1;
                    // Get the pattern information
                    mem_pattern_total_num <= onchip_mem_read_data[63:32];
                    mem_addr_space_per_pattern <= onchip_mem_read_data[79:64];
                    mem_pattern_h_pix <= onchip_mem_read_data[127:96];
                    mem_pattern_v_line <= onchip_mem_read_data[159:128];

                end
                // Read data from FIFO
                else if (onchip_mem_read_data[7:0] == 8'haa || start) begin
                    data_source <= 1'b0;
                    mem_pattern_total_num <= onchip_mem_read_data[63:32];
                    mem_addr_space_per_pattern <= onchip_mem_read_data[79:64];
                    mem_pattern_h_pix <= onchip_mem_read_data[127:96];
                    mem_pattern_v_line <= onchip_mem_read_data[159:128];
                    if (~fifo_empty) begin
                        fifo_rd_ena <= 1'b1;
                    end
                    else begin
                        fifo_rd_ena <= 1'b0;
                    end
                    if (fifo_rd_valid) begin
                        tmp_cnt <= tmp_cnt + 1'd1;
                        if (tmp_cnt == 2'd1) begin
                            state <= INIT_READ_MEM_s;
                            tmp_cnt <= 'd0;
                        end
                    end
                end
                timer_ena <= 1'b1;
                pix_cnt_per_de <= 'h0;
            end
            INIT_READ_MEM_s: begin
                if (data_source) begin
                    // the address 0 and 1 are not the pattern data
                    if (mem_rd_cnt == 3'd2 && mem_rd_valid) begin
                        mem_rd <= 1'b0;
                        if (!frame_busy) begin
                            state <= SEND_DATA_s;
                            frame_trig <= 1'b1;
                            mem_rd_cnt <= 'h0;
                        end
                        else begin
                            state <= INIT_READ_MEM_s;
                        end
                    end
                    else if (mem_rd_valid) begin
                        mem_rd_cnt <= mem_rd_cnt + 1'd1;
                        mem_rd <= 1'b1;
                        mem_sel <= 1'b1;
                        mem_addr <= mem_addr + 1'd1;
                        $display("mem_addr is %d",mem_addr);
                    end
                end
                else begin
                    if (fifo_rd_cnt == 3'd2 && fifo_rd_valid) begin
                        fifo_rd_ena <= 1'b0;
                        if (!frame_busy) begin
                            state <= SEND_DATA_s;
                            frame_trig <= 1'b1;
                            fifo_rd_cnt <= 'h0;
                        end
                        else begin
                            state <= INIT_READ_MEM_s;
                        end
                    end
                    else if (fifo_rd_valid) begin
                        fifo_rd_cnt <= fifo_rd_cnt + 1'd1;

                    end
                    else if (~fifo_empty) begin
                        fifo_rd_ena <= 1'b1;
                    end
                    else begin
                        fifo_rd_ena <= 1'b0;
                    end
                end
            end
            SEND_DATA_s: begin
                frame_trig <= 1'b0;
                if (de_in) begin
                    pix_cnt_per_de <= pix_cnt_per_de + 1'd1;
                end
                else begin
                    pix_cnt_per_de <= 0;
                end

                if (de_in & de_first_offset_line_in) begin
                    pix_data_out <= display_video_left_offset_in;
                end
                else if (de_in) begin
                    if (pix_cnt_per_de < 7'd80) begin
                        cnt <= cnt + 1'd1;
                        case(cnt)
                            5'd0: pix_data_out <= mem_data[767: (767 - 24 * 1 + 1)];
                            5'd1: pix_data_out <= mem_data[(767 - 24 * 1) : (767 - 24 * 2 + 1)];
                            5'd2: pix_data_out <= mem_data[(767 - 24 * 2) : (767 - 24 * 3 + 1)];
                            5'd3: pix_data_out <= mem_data[(767 - 24 * 3) : (767 - 24 * 4 + 1)];
                            5'd4: pix_data_out <= mem_data[(767 - 24 * 4) : (767 - 24 * 5 + 1)];
                            5'd5: pix_data_out <= mem_data[(767 - 24 * 5) : (767 - 24 * 6 + 1)];
                            5'd6: pix_data_out <= mem_data[(767 - 24 * 6) : (767 - 24 * 7 + 1)];
                            5'd7: pix_data_out <= mem_data[(767 - 24 * 7) : (767 - 24 * 8 + 1)];
                            5'd8: pix_data_out <= mem_data[(767 - 24 * 8) : (767 - 24 * 9 + 1)];
                            5'd9: pix_data_out <= mem_data[(767 - 24 * 9) : (767 - 24 * 10 + 1)];
                            5'd10: pix_data_out <= mem_data[(767 - 24 * 10) : (767 - 24 * 11 + 1)];
                            5'd11: pix_data_out <= mem_data[(767 - 24 * 11) : (767 - 24 * 12 + 1)];
                            5'd12: pix_data_out <= mem_data[(767 - 24 * 12) : (767 - 24 * 13 + 1)];
                            5'd13: pix_data_out <= mem_data[(767 - 24 * 13) : (767 - 24 * 14 + 1)];
                            5'd14: pix_data_out <= mem_data[(767 - 24 * 14) : (767 - 24 * 15 + 1)];
                            5'd15: pix_data_out <= mem_data[(767 - 24 * 15) : (767 - 24 * 16 + 1)];
                            5'd16: pix_data_out <= mem_data[(767 - 24 * 16) : (767 - 24 * 17 + 1)];
                            5'd17: pix_data_out <= mem_data[(767 - 24 * 17) : (767 - 24 * 18 + 1)];
                            5'd18: pix_data_out <= mem_data[(767 - 24 * 18) : (767 - 24 * 19 + 1)];
                            5'd19: pix_data_out <= mem_data[(767 - 24 * 19) : (767 - 24 * 20 + 1)];
                            5'd20: pix_data_out <= mem_data[(767 - 24 * 20) : (767 - 24 * 21 + 1)];
                            5'd21: pix_data_out <= mem_data[(767 - 24 * 21) : (767 - 24 * 22 + 1)];
                            5'd22: pix_data_out <= mem_data[(767 - 24 * 22) : (767 - 24 * 23 + 1)];
                            5'd23: pix_data_out <= mem_data[(767 - 24 * 23) : (767 - 24 * 24 + 1)];
                            5'd24: pix_data_out <= mem_data[(767 - 24 * 24) : (767 - 24 * 25 + 1)];
                            5'd25: pix_data_out <= mem_data[(767 - 24 * 25) : (767 - 24 * 26 + 1)];
                            5'd26: pix_data_out <= mem_data[(767 - 24 * 26) : (767 - 24 * 27 + 1)];
                            5'd27: pix_data_out <= mem_data[(767 - 24 * 27) : (767 - 24 * 28 + 1)];
                            5'd28: pix_data_out <= mem_data[(767 - 24 * 28) : (767 - 24 * 29 + 1)];
                            5'd29: pix_data_out <= mem_data[(767 - 24 * 29) : (767 - 24 * 30 + 1)];
                            5'd30: pix_data_out <= mem_data[(767 - 24 * 30) : (767 - 24 * 31 + 1)];
                            5'd31: pix_data_out <= mem_data[(767 - 24 * 31) : 0];
                            default: pix_data_out <= 'h0;
                        endcase // cnt
                    end
                    else begin
                        cnt <= cnt;
                        pix_data_out <= 0;
                    end
                end

                if ((cnt == 5'd27 || cnt == 5'd29 || cnt == 5'd31) & de_in) begin
                    case(data_source)
                        1'b0: begin
                            fifo_rd_ena <= 1'd1;
                            $display("Read FIFO");
                        end
                        1'b1: begin
                            mem_rd <= 1'd1;
                            mem_sel <= 1'b1;
                            mem_addr <= mem_addr + 1'd1;
                            $display("mem_addr is %d",mem_addr);
                            $display("data is %d", $bits("/"));
                        end
                    endcase // data_source
                end
                else begin
                    mem_rd <= 1'd0;
                    fifo_rd_ena <= 1'b0;
                end

                if (data_source) begin
                    if (mem_rd_valid) begin
                        if (mem_rd_cnt == 2'd2) begin
                            mem_rd_cnt <= 'h0;
                        end
                        else begin
                            mem_rd_cnt <= mem_rd_cnt + 1'd1;
                        end
                    end
                end
                else begin
                    if (fifo_rd_valid) begin
                        if (fifo_rd_cnt == 2'd2) begin
                            fifo_rd_cnt <= 'h0;
                        end
                        else begin
                            fifo_rd_cnt <= fifo_rd_cnt + 1'd1;
                        end
                    end
                end

                if (line_cnt == 'd1081 && de_fall_edge) begin // the first line works as sync with DMD
                    if (mem_pattern_cnt == mem_pattern_total_num) begin
                        state <= END_s;
                    end
                    else begin
                        mem_pattern_cnt <= mem_pattern_cnt -1'd1;
                        frame_trig <= 1'b1;
                        mem_rd_cnt <= 'h0;
                        state <= SEND_DATA_s;
                        //line_cnt <= 'd0;
                    end
                end
            end
            END_s: begin
                mem_wr <= 1'b1;  // Clear the data in Addr 0x00 of onchip memory to prepare for next opearation
                mem_addr <= 'h0;
                mem_wr_data <= 'h0;
                mem_sel <= 1'b1;
                state <= IDLE_s;
                mem_wr_byte_ena <= 32'hffffffff;
                mem_rd_cnt <= 'h0;
                cnt <= 'h0;

                fifo_rd_ena <= 1'b0;
                fifo_rd_cnt <= 'h0;
                data_source <= 0;
            end
            default: begin
                state <= IDLE_s;
                mem_wr <= 1'b0;
                mem_rd <= 1'b0;
            end
        endcase
    end
end


always @(posedge clk) begin
    if(~rst_n) begin
        h_sync_out <= 1'b0;
        v_sync_out <= 1'b0;
        de_out <= 1'b0;
    end else begin
        h_sync_out <= h_sync_in;
        v_sync_out <= v_sync_in;
        de_out <= de_in;
    end
end
//-------------------------------------------------------------------------
/*
reg [23:0]      pixel_out_data_r[0:10];
reg [4:0]       pixel_out_cnt;

wire [255:0]    file_output_data0, file_output_data1, file_output_data2;
wire [23:0]     tmp_reg;
assign tmp_reg = pixel_out_data_r[10];
assign file_output_data0 = {pixel_out_data_r[9], pixel_out_data_r[8], pixel_out_data_r[7],
                            pixel_out_data_r[6], pixel_out_data_r[5], pixel_out_data_r[4],
                            pixel_out_data_r[3], pixel_out_data_r[2], pixel_out_data_r[1],
                            pixel_out_data_r[0], pix_data_out[23:8]};

assign file_output_data1 = {tmp_reg[7:0], pixel_out_data_r[9], pixel_out_data_r[8], pixel_out_data_r[7],
                            pixel_out_data_r[6], pixel_out_data_r[5], pixel_out_data_r[4],
                            pixel_out_data_r[3], pixel_out_data_r[2], pixel_out_data_r[1],
                            pixel_out_data_r[0], pix_data_out[23:16]};

assign file_output_data2 = {pixel_out_data_r[9][15:0], pixel_out_data_r[8], pixel_out_data_r[7],
                            pixel_out_data_r[6], pixel_out_data_r[5], pixel_out_data_r[4],
                            pixel_out_data_r[3], pixel_out_data_r[2], pixel_out_data_r[1],
                            pixel_out_data_r[0], pix_data_out};

integer w_file;

initial w_file = $fopen("fast_output_data.txt");

always @(posedge clk) begin
    if (~rst_n) begin
        pixel_out_cnt <= 0;
        for (int i = 0; i < 10; i = i + 1) begin
            pixel_out_data_r[i] <= 'h0;
        end
    end
    else begin
         //if (line_cnt > 0 && line_cnt < 1081) begin

        //end

        if (de_out) begin
            for(int i = 0; i < 10; i = i + 1) begin
                pixel_out_data_r[i + 1] <= pixel_out_data_r[i];
            end
            pixel_out_data_r[0] <= pix_data_out;
           // if (line_cnt > 0 && line_cnt < 1081) begin
            pixel_out_cnt <= pixel_out_cnt + 1'd1;
            if (pixel_out_cnt == 5'd10) begin
                $display($time);
                $display("line is %d, file_output_data is %h", line_cnt, file_output_data0);
                $fdisplay(w_file, "%h", file_output_data0);
            end
            else if (pixel_out_cnt == 5'd21) begin
                $display($time);
                $display("line is %d,file_output_data is %h",line_cnt, file_output_data1);
                $fdisplay(w_file, "%h", file_output_data1);
            end
            else if (pixel_out_cnt == 5'd31) begin
                $display($time);
                $display("line_cnt is %d, file_output_data is %h", line_cnt, file_output_data2);
                $fdisplay(w_file, "%h", file_output_data2);
            end
           // end
        end
    end
end
*/
/*
timer # (
    .MAX(512)
    )
timer_inst (
    .clk      (clk),
    .rst_n    (rst_n),
    .timer_ena(timer_ena),
    .timer_rst(timer_rst),
    .timer_out(timer_out)
    );
*/



endmodule