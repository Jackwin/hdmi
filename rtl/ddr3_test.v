module ddr3_test # (
    parameter DATA_WIDTH = 256,
    parameter ADDR_WIDTH = 22,
    )
(
    input usr_clk,    // Clock
    input usr_rst_n,  // Asynchronous reset active low

    output [ADDR_WIDTH-1:0]     ddr3_addr_o,
    output                      ddr3_write_o,
    output                      ddr3_read_o,
    output [DATA_WIDTH/8-1:0]   ddr3_byte_enable_o,
    output [DATA_WIDTH-1:0]     ddr3_write_data_o,

    input  [DATA_WIDTH-1:0]     ddr3_rddata_in,
    input                       ddr3_rddata_valid_in
    );



endmodule