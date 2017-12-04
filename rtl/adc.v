`timescale 1ns/1ps
// Sample the data in Channel A
// The AD chip is AD9254 with the lowest conversion rate being 10 MSPS and
// the highest being 150 MSPS
module adc (

    input           reset_n,
    input           sys_clk, // Keep sys_clk as the same frequency as adc_dco

    input           adc_dco,
    input [13:0]    adc_data,
    output          adc_oe_n,
    input           adc_or_in,

    output          or_led,
    output          adc_sclk,
    output          adc_sdio,
    output          adc_cs_n
);

// Signals
reg [13:0]          adc_data_r1, adc_data_r2/*synthesis keep*/;
reg [13:0]          adc_usr/*synthesis keep*/;
assign adc_sclk = 1'b0; // Data format is Binary
assign adc_sdio = 1'b1; // Enable DCS
assign adc_cs_n = 1'b1;
assign adc_oe_n = 1'b0; // Enable ADC output
assign or_led = adc_or_in; // Indicator of out of range

always @(posedge adc_dco or negedge reset_n) begin
    if(~reset_n) begin
         adc_data_r1 <= 'h0;
         adc_data_r2 <= 'h0;
    end else begin
         adc_data_r1 <= adc_data;
         adc_data_r2 <= adc_data_r1;
    end
end

always @(posedge sys_clk or negedge reset_n) begin
    if(~reset_n) begin
         adc_usr <= 0;
    end else begin
         adc_usr <= adc_data_r2;
    end
end

endmodule