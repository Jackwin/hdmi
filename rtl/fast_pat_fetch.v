`timescale 1 ns / 1 ps
module fast_pat_fetch (
    input           clk,
    input           rst_n,

    output          onchip_mem_chip_select,
    output          onchip_mem_chip_read,
    output [10:0]   onchip_mem_addr,
    output [31:0]   onchip_mem_byte_enable,
    output [255:0]  onchip_mem_write_data,
    output          onchip_mem_write,

    input [255:0]   onchip_mem_read_data,

    output reg      frame_trig,
    input           frame_busy,
    input           h_sync_in,
    input           v_sync_in,
    input           de_in,
    output reg [23:0]   pix_data_out

);

localparam  IDLE = 2'd0,
            INIT_READ_ONCHIP_MEM = 2'd1,
            READ_ONCHIP_MEM = 2'd2,
            HALT = 2'd3;

reg        timer_ena;
wire        timer_out;
wire        timer_rst;
reg [1:0]   state;

// On-chip memory signals
reg [1:0]   mem_rd_cnt;
reg         mem_rd;
reg         mem_rd_valid;
reg         mem_sel;
reg [10:0]  mem_addr;
//reg [255:0] mem_data_r0, mem_data_r1, mem_data_r2;
reg [767:0] mem_data;
reg [4:0]   cnt;
reg [11:0]  line_cnt;


assign onchip_mem_chip_select = mem_sel;
assign onchip_mem_chip_read = mem_rd;
assign onchip_mem_addr = mem_addr;
//assign onchip_mem_byte_enable =

// The read latency is 1 for the onchip memory
always @(posedge clk) begin
    mem_rd_valid <= mem_rd;
end

always @(posedge clk) begin
    if(~rst_n) begin
         mem_data <= 0;
    end else begin
        if (mem_rd_valid) begin
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

    end
end

// Count the lines
reg h_sync_r, h_sync_p;
reg v_sync_r, v_sync_p;
reg de_r, de_p;
always @(posedge clk) begin
    if(~rst_n) begin
        h_sync_r <= 1'b0;
        h_sync_p <= 1'b0;
        v_sync_r <= 1'b0;
        v_sync_p <= 1'b0;
    end else begin
        h_sync_r <= h_sync_in;
        h_sync_p <= ~h_sync_r & h_sync_in;

        v_sync_r <= v_sync_in;
        v_sync_p <= ~v_sync_r & v_sync_in;

        // capturing the falling edge of de_in
        de_r <= de_in;
        de_p <= ~de_in & de_r;
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        line_cnt <= 0;
    end else begin
        if (v_sync_p) begin
            line_cnt <= 'h0;
        end
        else if (h_sync_p) begin
            line_cnt <= line_cnt + 1'd1;
        end
    end
end

//  Output the pixel data
always @(posedge clk) begin
    if(~rst_n) begin
        state <= IDLE;
        timer_ena <= 1'b0;
        mem_rd_cnt <= 'h0;
        mem_rd <= 1'b0;
        mem_addr <= 'h0;
        mem_sel <= 1'b0;
        frame_trig <= 1'b0;
        cnt <= 'h0;
        pix_data_out <= 'h0;
        line_cnt <= 'h0;
    end else begin
        mem_rd <= 1'b0;
        mem_sel <= 1'b0;
        case (state)
            IDLE: begin
                mem_sel <= 1'b1;
                mem_rd <= 1'b1;
                if (onchip_mem_read_data[7:0] == 'h77) begin
                    state <= INIT_READ_ONCHIP_MEM;
                    mem_rd <= 1'b0;
                    mem_sel <= 1'b0;
                end
                timer_ena <= 1'b1;
            end
            INIT_READ_ONCHIP_MEM: begin
                if (mem_rd_cnt == 2'd2 && mem_rd_valid) begin
                    mem_rd <= 1'b0;
                    if (!frame_busy) begin
                        state <= HALT;
                        frame_trig <= 1'b1;
                        mem_rd_cnt <= 'h0;
                    end
                    else begin
                        state <= INIT_READ_ONCHIP_MEM;
                    end
                end
                else if (mem_rd_valid) begin
                    mem_rd_cnt <= mem_rd_cnt + 1'd1;
                    mem_rd <= 1'b1;
                    mem_sel <= 1'b1;
                    mem_addr <= mem_addr + 1'd1;
                end
                else begin
                    mem_rd <= 1'b0;
                    mem_sel <= 1'b0;
                end

            end
            HALT: begin
                frame_trig <= 1'b0;
                if (de_in) begin
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
                    cnt <= 'h0;
                end

                if (cnt == 5'd27 || cnt == 5'd29 || cnt == 5'd31) begin
                    mem_rd <= 1'd1;
                    mem_sel <= 1'b1;
                    mem_addr <= mem_addr + 1'd1;
                end
                else begin
                    mem_rd <= 1'd0;
                end

                if (line_cnt == 'd1080 && de_p) begin
                    state <= IDLE;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
end


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