module fast_pat_fetch (
    input       clk,    // Clock
    input       rst_n,  // Asynchronous reset active low

    output          onchip_mem_chip_select,
    output          onchip_mem_chip_read,
    output [10:0]   onchip_mem_addr,
    output [31:0]   onchip_mem_byte_enable,
    output [255:0]  onchip_mem_write_data,
    output          onchip_mem_write,

    input [255:0]   onchip_mem_readd_data


);

endmodule