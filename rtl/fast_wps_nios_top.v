module fast_wps_nios_top (
    input       clk50m_in,
    input       reset_n,

    output [7:0]    led_o,
    output          shrink_led,
    output          pll_led,
	 inout 				pio_iic_sda,
	 output 				pio_iic_scl,
    output          iic_sda,
    inout           iic_scl,
	 output 				hdmi_tx_rst_n
);

wire            clk_100m;
wire            pll_locked;
reg [26:0]      counter;

assign pll_led = ~pll_locked;

nios nios_i (
    .clk_clk(clk50m_in),
    .reset_reset_n(reset_n),
	 .pio_i2c_scl_export(pio_iic_scl),
	 .pio_i2c_sda_export(pio_iic_sda),
    .i2c_scl(iic_scl),
    .i2c_sda(iic_sda),
    .led_export(led_o),
	 .hdmi_tx_rst_n_export(hdmi_tx_rst_n)
    );


pll_50m pll_50m_i (
    .refclk   (clk50m_in),   //  refclk.clk
    .rst      (~reset_n),      //   reset.reset
    .outclk_0 (clk_100m), // outclk0.clk
    .locked   (pll_locked)    //  locked.export
);

always @(posedge clk_100m or negedge reset_n) begin : proc_led
    if (~reset_n) begin
        counter <= 'h0;
    end else begin
         counter <= counter + 1'h1;
    end
end
assign shrink_led = counter[26];



endmodule