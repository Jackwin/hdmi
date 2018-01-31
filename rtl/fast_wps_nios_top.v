module fast_wps_nios_top (
    input           clk50m_in,
    input           reset_n,

    output [7:0]    led_o,
    output          shrink_led,
    output          pll_led,
    output          clk_200m_out,
    output          rst_n_out,

    output          iic_sda,
    inout           iic_scl,
// ---------- DAC --------------------------
    output [13:0]   dac_data,
// ---------- ADC --------------------------
    input           adc_dco,
    input [13:0]    adc_data,
    output          adc_oe_n,
    input           adc_or_in,

    output          fpga_adc_clk_p,
// On-chip memory interface
    output           onchip_mem_clken,
    output          onchip_mem_chip_select,
    output          onchip_mem_read,
    input  [255:0]  onchip_mem_rddata,
    output [10:0]   onchip_mem_addr,
    output [31:0]   onchip_mem_byte_enable,
    output          onchip_mem_write,
    output [255:0]  onchip_mem_write_data,

    // DDR3 interface
    input           start,
    input           ddr3_emif_clk,
    input           ddr3_emif_rst_n,
    input           ddr3_emif_ready,
    input [255:0]   ddr3_emif_read_data,
    input           ddr3_emif_rddata_valid,

    output          ddr3_emif_read,
    output          ddr3_emif_write,
    output [21:0]   ddr3_emif_addr,
    output [255:0]  ddr3_emif_write_data,
    output [31:0]   ddr3_emif_byte_enable,
    output [4:0]    ddr3_emif_burst_count,

//    output          fpga_adc_clk_n,
    output          or_led,
    output          adc_sclk,
    output          adc_sdio,
    output          adc_cs_n,
    //HDMI programming ports
    output          hdmi_tx_rst_n,
    input           hdmi_int_n,
    inout           hdmi_pcsda,
    output          hdmi_pcscl,
    output          hdmi_tx_pclk,
    output [11:0]   hdmi_tx_rd,
    output [11:0]   hdmi_tx_gd,
    output [11:0]   hdmi_tx_bd,
    output          hdmi_tx_de,
    output          hdmi_tx_vs,
    output          hdmi_tx_hs

);

// ------------------- PLL signals ---------------------------
wire            clk_100m/*synthesis keep*/;
wire            clk_200m/*synthesis keep*/;
wire            clk_100m_p/*synthesis keep*/;
wire            clk_100m_n/*synthesis keep*/;
wire            pll_locked;
// -------------------- LED signals -------------------------
reg [26:0]      counter;
// ------------------- HDMI signals --------------------------
wire            vpg_disp_mode_change/*synthesis keep*/;
wire [3:0]      vpg_disp_mode/*synthesis keep*/;
wire [1:0]      vpg_disp_color/*synthesis keep*/;
wire            time_gen;
wire            vpg_locked;
wire            vpg_pclk;
wire            vpg_de/*synthesis keep*/;
wire            vpg_hs/*synthesis keep*/;
wire            vpg_vs/*synthesis keep*/;
wire [7:0]      vpg_r/*synthesis keep*/;
wire [7:0]      vpg_g/*synthesis keep*/;
wire [7:0]      vpg_b/*synthesis keep*/;
// ------------------- reset signals --------------------------
reg             rst_n_meta, rst_n_sync;

// ----------------- ADC --------------------------------------

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
    .outclk_1 (clk_200m),
    .outclk_2 (clk_100m_p), // 100 Mhz phase shift 0
    .outclk_3 (clk_100m_n), // 100 MHz phase shift 180
    .locked   (pll_locked)    //  locked.export
);
assign clk_200m_out = clk_200m;
assign rst_n_out = rst_n_sync;

always @(posedge clk_200m or negedge pll_locked) begin
    if (~pll_locked) begin
        rst_n_meta <= 1'b0;
        rst_n_sync <= 1'b0;
    end
    else begin
        rst_n_sync <= rst_n_meta;
        rst_n_meta <= 1'b1;
    end
end

// -------------------- ADC -------------------------------

assign fpga_adc_clk_p = clk_100m_p;
//assign fpga_adc_clk_n = clk_100m_n;
adc adc_i (
    .reset_n  (reset_n),
    .sys_clk  (clk_100m),
    .adc_dco  (adc_dco),
    .adc_data (adc_data),
    .adc_oe_n (adc_oe_n),
    .adc_or_in(adc_or_in),
    .or_led   (or_led),
    .adc_sclk (adc_sclk),
    .adc_sdio (adc_sdio),
    .adc_cs_n (adc_cs_n)
  );
dac dac_i (
    .ref_clk  (clk_100m_p),
    .reset_n  (reset_n),
    .dac_data(dac_data)
    );

//--------------------- Shrink LED ------------------------
always @(posedge clk_200m or negedge reset_n) begin : proc_led
    if (~reset_n) begin
        counter <= 'h0;
    end else begin
         counter <= counter + 1'h1;
    end
end
assign shrink_led = counter[26];

//============== video pattern generator =====================

vpg vpg_inst(
    .clk_100m    (clk_100m),
    .reset_n    (pll_locked),

    .start                 (start),
    .ddr3_emif_clk         (ddr3_emif_clk),
    .ddr3_emif_rst_n       (ddr3_emif_rst_n),
    .ddr3_emif_ready       (ddr3_emif_ready),
    .ddr3_emif_read_data   (ddr3_emif_read_data),
    .ddr3_emif_rddata_valid(ddr3_emif_rddata_valid),
    .ddr3_emif_read        (ddr3_emif_read),
    .ddr3_emif_write       (ddr3_emif_write),
    .ddr3_emif_addr        (ddr3_emif_addr),
    .ddr3_emif_write_data  (ddr3_emif_write_data),
    .ddr3_emif_byte_enable (ddr3_emif_byte_enable),
    .ddr3_emif_burst_count (ddr3_emif_burst_count),

    .onchip_mem_clken      (onchip_mem_clken),
    .onchip_mem_chip_select(onchip_mem_chip_select),
    .onchip_mem_read       (onchip_mem_read),
    .onchip_mem_rddata     (onchip_mem_rddata),
    .onchip_mem_addr       (onchip_mem_addr),
    .onchip_mem_byte_enable(onchip_mem_byte_enable),
    .onchip_mem_write      (onchip_mem_write),
    .onchip_mem_write_data (onchip_mem_write_data),

    .mode       (vpg_disp_mode),
    .mode_change(vpg_disp_mode_change),
    .disp_color (vpg_disp_color),
    .vpg_locked (vpg_locked),
    .vpg_pclk   (vpg_pclk),
    .vpg_de     (vpg_de),
    .vpg_hs     (vpg_hs),
    .vpg_vs     (vpg_vs),
    .vpg_r      (vpg_r),
    .vpg_g      (vpg_g),
    .vpg_b      (vpg_b)
    );

//===== source selection, from pattern generator or hdmi-rx

assign hdmi_tx_pclk = ~vpg_pclk;
source_selector source_selector_inst(
                                                 .data0x({vpg_de, vpg_hs, vpg_vs, vpg_r, 4'b0000, vpg_g, 4'b0000, vpg_b, 4'b0000}),
                                                 .data1x({1'b1, 1'b1, 1'b1,,,}),
                                                 .sel   (1'b0),
                                                 .result({hdmi_tx_de, hdmi_tx_hs,hdmi_tx_vs,hdmi_tx_rd,hdmi_tx_gd,hdmi_tx_bd})
                                                );

// ---------------------- Debug ----------------------
/*
source_probe source_probe_i (
    .source (time_gen), // sources.source
	 .source_clk(clk_100m),
    .probe  (vpg_locked)   //  probes.probe
    );
*/
endmodule