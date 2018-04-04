`timescale 1ns/1ps
module wps_send (
    input           clk,
    input           rst_n,

    input [31:0]    to_send_frame_num_in,
    input           send_trig,

    input [23:0]    rx_data,
    input           rx_data_valid,

);

endmodule