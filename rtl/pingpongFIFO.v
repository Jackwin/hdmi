`timescale 1ns/1ps

module pingpongFIFO (
    input           rx_clk,
    input           rx_rst_n,
    input [23:0]    rx_data,
    input           rx_data_valid
    output          rx_ready_out,

    input           tx_clk,
    input           tx_rst_n,
    output [23:0]   tx_data,
    output          tx_valid,
    input           tx_ready_in

);

endmodule