`timescale 1ns/1ps
//Function: Schedule the wps control
//          1. Fetch data from ddr3_usr_logic.v or from onchip memory
//          2. Send data to wps_send.v
//          3. Register management
module wps_controller (
    input           clk,
    input           rst_n,

    // interface to ddr3_user_logic
    input           data_ready_in,
    output          read_out,
    input [255:0]   read_data_in,
    input           read_data_valid,

    output [26:0]   ddr3_usr_start_addr_out,
    output [31:0]   to_read_byte_in,
    output [31:0]   to_read_frame_num_out,
    output [19:0]   one_frame_byte_out,
    output          drr3_read_start,


);

endmodule