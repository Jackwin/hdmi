module fast_wps_nios_top (
    input           clk50m_in,
    input           reset_n,

    output [7:0]    led_o,
    output          shrink_led,
    output          pll_led,

    output          iic_sda,
    inout           iic_scl,


    //HDMI programming ports
    output          hdmi_tx_rst_n,
    output          hdmi_int_n,
    //inout           pio_iic_sda,
    //output          pio_iic_scl,
    inout           hdmi_pcsda,
    output          hdmi_pcscl,
    // Digital vide
    output          hdmi_pclk,
    output [11:0]   hdmi_tx_rd,
    output [11:0]   hdmi_tx_gd,
    output [11:0]   hdmi_tx_bd,
    output          hdmi_tx_de,
    output          hdmi_tx_vs,
    output          hdmi_tx_hs

);

wire            clk_100m;
wire            pll_locked;
reg [26:0]      counter;

wire            vpg_disp_mode_change;
wire [3:0]      vpg_disp_mode;
wire [1:0]      vpg_disp_color;

assign pll_led = ~pll_locked;
//------------------------NIOS CPU -----------------------------
nios nios_i (
    .clk_clk(clk50m_in),
    .reset_reset_n(reset_n),
     .pio_i2c_scl_export(hdmi_pcscl),
     .pio_i2c_sda_export(hdmi_pcsda),
    .i2c_scl(iic_scl),
    .i2c_sda(iic_sda),
    .led_export(led_o),
     .hdmi_tx_rst_n_export(hdmi_tx_rst_n),
     .hdmi_tx_disp_mode_export(vpg_disp_mode),
     .hdmi_tx_mode_change_export(vpg_disp_mode_change),
     .hdmi_tx_vpg_color_export(vpg_disp_color)
    );

//---------------------- PLL -------------------------------
pll_50m pll_50m_i (
    .refclk   (clk50m_in),   //  refclk.clk
    .rst      (~reset_n),      //   reset.reset
    .outclk_0 (clk_100m), // outclk0.clk
    .locked   (pll_locked)    //  locked.export
);

//--------------------- Shrink LED ------------------------
always @(posedge clk_100m or negedge reset_n) begin : proc_led
    if (~reset_n) begin
        counter <= 'h0;
    end else begin
         counter <= counter + 1'h1;
    end
end
assign shrink_led = counter[26];

//============== video pattern generator =====================
//wire      user_change_mode;


wire                    vpg_pclk;
wire                    vpg_de;
wire                    vpg_hs;
wire                    vpg_vs;
wire        [7:0]       vpg_r;
wire        [7:0]       vpg_g;
wire        [7:0]       vpg_b;


vpg vpg_inst(
                    .clk_100    (pll_100M),
                    .reset_n    (reset_n),
                    .mode       (vpg_disp_mode),
                    .mode_change(vpg_disp_mode_change),
                    .disp_color (vpg_disp_color),
                    .vpg_pclk   (vpg_pclk),
                    .vpg_de     (vpg_de),
                    .vpg_hs     (vpg_hs),
                    .vpg_vs     (vpg_vs),
                    .vpg_r      (vpg_r),
                    .vpg_g      (vpg_g),
                    .vpg_b      (vpg_b)
                    );

//===== source selection, from pattern generator or hdmi-rx
wire     rx_sync;

clk_slector clk_slector_inst(
                                      .data0 (~vpg_pclk),
                                      .data1 (1'b0),
                                      .sel   (rx_sync),
                                      .result(HDMI_TX_PCLK)
                                    );

source_selector source_selector_inst(
                                                 .data0x({vpg_de, vpg_hs, vpg_vs, vpg_r, 4'b0000, vpg_g, 4'b0000, vpg_b, 4'b0000}),
                                                 .data1x({1'b1, 1'b1, 1'b1,,,}),
                                                 .sel   (rx_sync),
                                                 .result({HDMI_TX_DE, HDMI_TX_HS, HDMI_TX_VS, HDMI_TX_RD,HDMI_TX_GD,HDMI_TX_BD})
                                                );

assign HDMI_TX_SCK = gen_sck;
assign HDMI_TX_I2S = {gen_i2s, gen_i2s, gen_i2s, gen_i2s};
assign HDMI_TX_WS  = gen_ws;



endmodule