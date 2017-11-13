`timescale 1ns/1ps

module adc (

    input           reset_n,
    input           sys_clk,

    input           adc_dco,
    input [13:0]    adc_data,
    output          adc_oe_n,
    input           adc_or_in,

    output          adc_sclk,
    output          adc_sdio,
    output          adc_cs_n
);

endmodule