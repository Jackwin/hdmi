`timescale 1ns/1ps
//Function: Schedule the wps control
//          1. Fetch data from ddr3_usr_logic.v or from onchip memory
//          2. Send data to wps_send.v
//          3. Register management

`define START_PLAY_REG_OFFSET 255
`define PATTERN_SOURCE_REG_OFFSET 254
`define RSV2_OFFSET 253
`define PLAY_DONE_REG_OFFSET 247
`define RSV0_OFFSET 246

`define TO_SEND_FRAME_REG_OFFSET 223
`define ONE_FRAME_REG_OFFSET 191
`define PATTERN_H_PIX_REG_OFFSET 159
`define PATTERN_V_LINE_REG_OFFSET 144
`define TO_SEND_TOTAL_BYTE_REG_OFFSET 127
`define START_ADDR_REG_OFFSET 95
`define RSV1_OFFSET 63
`define RSV3_OFFSET 31
module wps_controller (
    input               clk,
    input               rst_n,

    output reg [31:0]   usr_start_addr_out,
    output reg [31:0]   to_read_byte_out,
    output reg [31:0]   to_read_frame_num_out,
    output reg [31:0]   one_frame_byte_out,

    //---Interface to ddr3_usr_logic------
    output reg          ddr3_read_start_out,
    input               ddr3_read_done_in,
    //---Interface to onchip_mem_usr_logic------
    output reg          onchip_mem_read_start_out,
    input               onchip_mem_read_done_in,
    // -- Interface to wps_send.v
    output reg          wps_send_start_out,
    //
    output              onchip_mem_chip_select,
    output              onchip_mem_clk_ena,
    input               onchip_mem_read_valid,
    output              onchip_mem_chip_read,
    output [12:0]       onchip_mem_addr,
    output [31:0]       onchip_mem_byte_enable,
    output [255:0]      onchip_mem_write_data,
    output              onchip_mem_write,
    input [255:0]       onchip_mem_read_data

);


localparam  POLL_REG = 3'd0,
            ISSUE_CMD = 3'd1,
            FETCH_DDR3 = 3'd2,
            FETCH_ONCHIP_MEM = 3'd3,
            WAIT_ONCHIP_MEM = 3'd4,
            UPDATE_REG = 3'd5;
// Register list
reg         pattern_source_reg;
reg         start_play_reg;
reg [5:0]   rsv2_reg;
reg         play_done_reg;
reg [23:0]  rsv0_reg;
reg [31:0]  to_send_frame_reg;
reg [31:0]  one_frame_byte_reg;
reg [15:0]  pattern_h_pix_reg;
reg [15:0]  pattern_v_line_reg;
reg [31:0]  to_send_total_byte_reg;
reg [31:0]  start_addr_reg;
reg [31:0]  rsv1_reg;
reg [31:0]  rsv3_reg;

reg [2:0]   state;
reg         mem_sel;
reg         mem_rd;
wire        mem_rd_valid;
reg [12:0]  mem_addr;
reg         mem_wr;
reg [31:0]  mem_byte_enable;
reg [255:0] mem_wr_data;

reg         poll_reg_timer_ena;
wire        poll_reg_timer_out;

/*
// The read latency is 2 for the onchip memory
always @(posedge clk) begin
    mem_rd_r <= mem_rd;
    mem_rd_valid <= mem_rd_r;
end
*/

assign onchip_mem_clk_ena = 1'b1;
assign onchip_mem_chip_select = mem_sel;
assign onchip_mem_chip_read = mem_rd;
assign onchip_mem_addr = mem_addr;
assign onchip_mem_write_data = mem_wr_data;
assign onchip_mem_write = mem_wr;
assign onchip_mem_byte_enable = mem_byte_enable;

assign mem_rd_valid = onchip_mem_read_valid;

always @(posedge clk) begin
    if(~rst_n) begin
        state <= POLL_REG;
        mem_sel <= 1'b0;
        mem_rd <= 1'b0;
        mem_addr <= 'h0;

        poll_reg_timer_ena <= 1'b0;

        mem_byte_enable <= 'h0;
        mem_wr <= 1'b0;

        ddr3_read_start_out <= 'h0;
        wps_send_start_out <= 1'b0;
        onchip_mem_read_start_out <= 1'b0;
    end else begin
        ddr3_read_start_out <= 1'b0;
        onchip_mem_read_start_out <= 1'b0;
        wps_send_start_out <= 1'b0;
        mem_wr <= 1'b0;
        mem_sel <= 1'b0;
        mem_rd <= 1'b0;
        mem_byte_enable <= 'h0;
        case (state)
            POLL_REG: begin
                // If poll more than one onchip memory address, add a counter
                mem_sel <= poll_reg_timer_out;
                mem_rd <= poll_reg_timer_out;
                mem_addr <= 'h0;
                poll_reg_timer_ena <= 1'b1;
                if (mem_rd_valid && onchip_mem_read_data[`START_PLAY_REG_OFFSET]) begin
                    start_play_reg <= onchip_mem_read_data[`START_PLAY_REG_OFFSET];
                    pattern_source_reg <= onchip_mem_read_data[`PATTERN_SOURCE_REG_OFFSET];
                    play_done_reg <= 1'b0;
                    rsv2_reg <= onchip_mem_read_data[`RSV2_OFFSET : (`PLAY_DONE_REG_OFFSET + 1)];
                    rsv0_reg <= onchip_mem_read_data[`RSV0_OFFSET : (`TO_SEND_FRAME_REG_OFFSET + 1)];
                    to_send_frame_reg <= onchip_mem_read_data[`TO_SEND_FRAME_REG_OFFSET : (`ONE_FRAME_REG_OFFSET + 1)];
                    one_frame_byte_reg <= onchip_mem_read_data[`ONE_FRAME_REG_OFFSET : (`PATTERN_H_PIX_REG_OFFSET + 1)];
                    pattern_h_pix_reg <= onchip_mem_read_data[`PATTERN_H_PIX_REG_OFFSET : (`PATTERN_V_LINE_REG_OFFSET + 1)];
                    pattern_v_line_reg <= onchip_mem_read_data[`PATTERN_V_LINE_REG_OFFSET : (`TO_SEND_TOTAL_BYTE_REG_OFFSET + 1)];
                    to_send_total_byte_reg <= onchip_mem_read_data[`TO_SEND_TOTAL_BYTE_REG_OFFSET: (`START_ADDR_REG_OFFSET + 1)];

                    start_addr_reg <= onchip_mem_read_data[`START_ADDR_REG_OFFSET : (`RSV1_OFFSET + 1)];
                    rsv1_reg <= onchip_mem_read_data[`RSV1_OFFSET : (`RSV3_OFFSET + 1)];
                    rsv3_reg <= onchip_mem_read_data[`RSV3_OFFSET : 0];
                    mem_sel <= 1'b0;
                    mem_rd <= 1'b0;
                    state <= ISSUE_CMD;
                    poll_reg_timer_ena <= 1'b0;

                    mem_wr <= 1'b1;
                    mem_wr_data <= {8'h0, 8'h00, 240'h0};
                    mem_sel <= 1'b1;
                    mem_byte_enable <= 32'h40000000; //de-assert play_done reg
                    mem_addr <= 'h0;
                end
            end
            ISSUE_CMD: begin
                usr_start_addr_out <= start_addr_reg;
                to_read_byte_out <= to_send_total_byte_reg;
                to_read_frame_num_out <= to_send_frame_reg;
                one_frame_byte_out <= one_frame_byte_reg;
                wps_send_start_out <= 1'b1;
                if (~pattern_source_reg) begin
                    ddr3_read_start_out <= 1'b1;
                    state <= FETCH_DDR3;
                    $display("Start to DDR3 Fetch");
                end
                else begin
                    onchip_mem_read_start_out <= 1'b1;
                    state <= FETCH_ONCHIP_MEM;
                end
            end
            FETCH_DDR3: begin
                if (ddr3_read_done_in) begin
                    state <= UPDATE_REG;
                    $display("DDR3 Fetch Done");
                end
            end
            FETCH_ONCHIP_MEM: begin
                if (onchip_mem_read_done_in) begin
                    state <= UPDATE_REG;
                end
            end
            UPDATE_REG: begin
                start_play_reg <= 1'b0;
                pattern_source_reg <= 1'b0;
                to_send_frame_reg <= 'h0;
                one_frame_byte_reg <= 'h0;
                pattern_h_pix_reg <= 'h0;
                pattern_v_line_reg <= 'h0;
                start_addr_reg <= 'h0;

                mem_addr <= 1'b0;
                mem_sel <= 1'b1;
                mem_byte_enable <= 31'h40000000;
                mem_wr <=1'b1;
                mem_wr_data <= {8'h0, 8'h80, 240'h0}; // Assert read_done
                state <= POLL_REG;
                $display("Update reg Done");

            end
            default: state <= POLL_REG;
        endcase // stsate
    end
end

timer  # (.MAX(256))
poll_reg_timer(
    .clk      (clk),
    .rst_n    (rst),
    .timer_ena(poll_reg_timer_ena),
    .timer_rst(1'b0),
    .timer_out(poll_reg_timer_out)
);

endmodule