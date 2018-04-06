`timescale 1ns/1ps
module wps_send (
    input           clk,
    input           rst_n,

    input [31:0]    to_send_frame_num_in,
    input [31:0]    one_frame_byte_in,
    input [31:0]    to_send_byte_in,
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
    output reg [23:0]   pix_data_out,

    input           pingpong_ready_in,
    output reg         read_pingpong_out,
    input [23:0]    pingpong_data_in,
    input           pingpong_data_valid_in

);

localparam IDLE = 3'd0,
            WAIT_DATA = 3'd1,
            SEND_TRIG = 3'd2,
            SEND_DATA = 3'd3,
            UPDATE_REG = 3'd4;

reg [2:0] state;

reg         de_in_r, de_first_offset_line_in_r;
reg [23:0]  display_video_left_offset_in_r;
reg         de_rising, de_falling;
reg         h_sync_r, h_sync_rising;
reg         v_sync_r, v_sync_rising;
reg [6:0]   pulse_cnt_per_de;
reg [10:0]   line_cnt;
reg [31:0]  one_frame_byte_reg;
reg [31:0]  fame_num_reg;
reg [31:0]  frame_cnt;
reg         delay_timer_ena;
reg         delay_timer_out;

always @(posedge clk) begin
    h_sync_r <= h_sync_in;
    h_sync_rising <= ~h_sync_in & h_sync_r;
    //h_sync output
    h_sync_out <= h_sync_r;

    v_sync_r <= v_sync_in;
    v_sync_rising <= ~v_sync_r & v_sync_in;
    //v_sync output
    v_sync_out <= v_sync_r;

    de_in_r <= de_in;
    de_rising <= ~de_in_r & de_in;
    de_falling <= ~de_in & de_in_r;
    // de output
    de_out <= de_in_r;

    de_first_offset_line_in_r <= de_first_offset_line_in;
    display_video_left_offset_in_r <= display_video_left_offset_in;
    delay_timer_ena <= 1'b0;
end

always @(posedge clk) begin
    if(~rst_n) begin
        state <= IDLE;
        frame_trig <= 1'b0;
        pix_data_out <= 'h0;
        frame_cnt <= 'h0;
        one_frame_byte_reg <= 'h0;
        fame_num_reg <= 'h0;
    end else begin
        frame_trig <= 1'b0;
        read_pingpong_out <= 1'b0;
        pix_data_out <= 'h0;
        delay_timer_ena <= 1'b0;
        case(state)
            IDLE: begin
                if (start & (to_send_frame_num_in != 'h0)) begin
                     state <= WAIT_DATA;
                    fame_num_reg <= to_send_frame_num_in - 1'd1;
                    one_frame_byte_reg <= one_frame_byte_in - 1'd1;
                end
            end
            // Wait for data flowing to the PingPong Buffer
            WAIT_DATA: begin
                if (pingpong_ready_in) begin
                    delay_timer_ena <= 1'b1;
                    if (delay_timer_out) begin // Give some time to the interface_256in FIFO to fill in enough data
                        state <= SEND_TRIG;
                    end
                end
            end
            // Send trig to display_vedio_generate_DMD_specific_faster
            SEND_TRIG: begin
                if (!frame_busy) begin
                    frame_trig <= 1'b1;
                    state <= SEND_DATA;
                end
            end
            SEND_DATA: begin
                read_pingpong_out <= de_in & (~de_first_offset_line_in) & (pulse_cnt_per_de < 7'd79);// Brake ahead(<79)
                //TODO 考虑读取pingpong的延迟和de_in的时序
                if (de_in_r & de_first_offset_line_in_r) begin
                    pix_data_out <= display_video_left_offset_in_r;
                end
                else if (de_in_r & pingpong_data_valid_in & ~de_first_offset_line_in_r) begin
                    pix_data_out <= pingpong_data_in;
                end
                else begin
                    pix_data_out <= 'h0;
                end

                if (line_cnt == 11'd1081 & de_falling) begin
                    state <= SEND_TRIG;
                    if (frame_cnt == fame_num_reg) begin
                        state <= UPDATE_REG;
                    end
                    else begin
                        frame_cnt <= frame_cnt + 1'd1;
                    end
                end
            end
            UPDATE_REG: begin
                fame_num_reg <= 'h0;
                one_frame_byte_reg <= 'h0;
                state <= IDLE;
                $stop;
            end
            default: begin
                state <= IDLE;
            end
        endcase // state
    end
end

// Count the pulse in every pe_in
always @(posedge clk) begin
    if(~rst_n) begin
        pulse_cnt_per_de <= 'h0;
    end else begin
        if (de_in_r) begin
            if (pulse_cnt_per_de == 7'd81) begin
                pulse_cnt_per_de <= 'h0;
            end
            else begin
                pulse_cnt_per_de <= pulse_cnt_per_de + 1'd1;
            end
        end
        else begin
            pulse_cnt_per_de <= 'h0;
        end
    end
end

// Count the line, and the total line is 1081
always @(posedge clk) begin
    if(~rst_n) begin
        line_cnt <= 0;
    end else begin
        if (v_sync_rising) begin
            line_cnt <= 'h0;
        end
        else if (de_rising) begin
            line_cnt <= line_cnt + 1'd1;
            $display("line_cnt is %d",line_cnt);
        end
    end
end

timer  # (.MAX(3500))
delay_timer(
    .clk      (clk),
    .rst_n    (rst_n),
    .timer_ena(delay_timer_ena),
    .timer_rst(1'b0),
    .timer_out(delay_timer_out)
);
endmodule