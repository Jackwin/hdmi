`timescale 1ns/1ps
`define DDR_CLK_PERIOD 8
`define PIXEL_CLK_PERIOD 6.73
module pattern_fetch_send_tb ();

logic ddr_emif_clk, ddr_emif_rst_n;
logic pixel_clk, pixel_rst_n;


initial begin
    ddr_emif_clk = 0;
    forever begin
        #(`DDR_CLK_PERIOD/2) ddr_emif_clk = ~ddr_emif_clk;
    end // forever
end

initial begin
    pixel_clk = 0;
    forever begin
        #(`DDR_CLK_PERIOD/2) pixel_clk = ~pixel_clk;
    end // forever
end

initial begin
    ddr_emif_rst_n = 1;
    #70 ddr_emif_rst_n = 0;
    #30 ddr_emif_rst_n = 1;
end

initial begin
    pixel_rst_n = 1;
    #90 pixel_rst_n = 0;
    #30 pixel_rst_n = 1;
end





endmodule