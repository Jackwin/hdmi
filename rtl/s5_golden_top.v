//--------------------------------------------------------------------------//
// Title:       golden_top.v                                                //
// Rev:         Rev 1                                                       //
//--------------------------------------------------------------------------//
// Description: All DSP Development Kit, Stratix V GX Edition I/O signals   //
//              and settings                                                               //
//              such as termination, drive strength, etc...                 //
//              Some toggle_rate=0 where needed for fitter rules. (TR=0)    //
//--------------------------------------------------------------------------//
// Revision History:                                                        //
// Rev 1:       First-cut
//----------------------------------------------------------------------------
//------ 1 ------- 2 ------- 3 ------- 4 ------- 5 ------- 6 ------- 7 ------7
//------ 0 ------- 0 ------- 0 ------- 0 ------- 0 ------- 0 ------- 0 ------8
//----------------------------------------------------------------------------
//Copyright � 2012 Altera Corporation. All rights reserved.  Altera products
//are protected under numerous U.S. and foreign patents, maskwork rights,
//copyrights and other intellectual property laws.
//
//This reference design file, and your use thereof, is subject to and
//governed by the terms and conditions of the applicable Altera Reference
//Design License Agreement.  By using this reference design file, you
//indicate your acceptance of such terms and conditions between you and
//Altera Corporation.  In the event that you do not agree with such terms and
//conditions, you may not use the reference design file. Please promptly
//destroy any copies you have made.
//
//This reference design file being provided on an "as-is" basis and as an
//accommodation and therefore all warranties, representations or guarantees
//of any kind (whether express, implied or statutory) including, without
//limitation, warranties of merchantability, non-infringement, or fitness for
//a particular purpose, are specifically disclaimed.  By making this
//reference design file available, Altera expressly does not recommend,
//suggest or require that this reference design file be used in combination
//with any other product not provided by Altera.
//
`define clock
`define sdi
`define ddr3
`define qdr
`define rldram
`define ethernet
`define FSM
`define LCD
`define userio
`define pcie
`define usb
`define qsfp
`define displayport
`define SDI
`define hsmcportA
`define hsmcportB

module s5_golden_top
(
`ifdef clock
//GPLL-CLK-----------------------------//8 pins
    input                clkin_50,            //1.8V    //50 MHz, also to EPM2210F256
    input   [1:0]        clkintop_p,      //LVDS    //100 MHz prog osc External Term.
    input   [1:0]        clkinbot_p,      //LVDS    //100 MHz prog osc clkinbot_p[0], clkinbot_p[1] External Term.
    input                clk_125_p,           //LVDS    //125 MHz GPLL-req's OCT.
`endif

`ifdef ddr3
//DDR3 Devices-x72--------------------------//125pins //--------------------------
    output  [13:0]       ddr3_a,           //SSTL15  //Address
    output  [2:0]        ddr3_ba,          //SSTL15  //Bank Address
    output               ddr3_casn,        //SSTL15  //Column Address Strobe
    output               ddr3_clk_n,        //SSTL15  //Diff Clock - Neg
    output               ddr3_clk_p,        //SSTL15  //Diff Clock - Pos
    output               ddr3_cke,         //SSTL15  //Clock Enable
    output               ddr3_csn,         //SSTL15  //Chip Select
    output  [7:0]        ddr3_dm,          //SSTL15  //Data Write Mask
    inout   [63:0]       ddr3_dq,          //SSTL15  //Data Bus
    inout   [7:0]        ddr3_dqs_n,       //SSTL15  //Diff Data Strobe - Neg
    inout   [7:0]        ddr3_dqs_p,       //SSTL15  //Diff Data Strobe - Pos
    output               ddr3_odt,         //SSTL15  //On-Die Termination Enable
    output               ddr3_rasn,        //SSTL15  //Row Address Strobe
    output               ddr3_resetn,        //SSTL15  //Reset
    output               ddr3_wen,         //SSTL15  //Write Enable
`endif
    input                rzqin_1p5,            //OCT Pin in Bank 4A

`ifdef FSM

//FSM-Shared-Bus---(Flash/Max)----//74 pins //--------------------------
    output  [26:0]      fm_a,               //1.8V    //Address
    inout   [31:0]      fm_d,               //1.8V    //Data
    output              flash_advn,          //1.8V    //Flash Address Valid
    output   [1:0]      flash_cen,           //1.8V    //Flash Chip Enable
    output              flash_clk,           //1.8V    //Flash Clock
    output              flash_oen,           //1.8V    //Flash Output Enable
    input    [1:0]      flash_rdybsyn,       //1.8V    //Flash Ready/Busy
    output              flash_resetn,        //1.8V    //Flash Reset
    output              flash_wen,           //1.8V    //Flash Write Enable

    output   [3:0]      max5_ben,            //1.5V    //Max V Byte Enable Per Byte
    inout               max5_clk,            //1.5V    //Max V Clk
    output              max5_csn,            //1.5V    //Max V Chip Select
    output              max5_oen,            //1.5V    //Max V Output Enable
    output              max5_wen,            //1.5V    //Max V Write Enable
`endif
//Configuration -----------------------//32 pins//---------------------------
//   inout   [31:0] fpga_data,            //2.5V    //Configuration Data
`ifdef LCD
//Character-LCD------------------------//11 pins //--------------------------
    output              lcd_csn,             //2.5V    //LCD Chip Select
    output              lcd_d_cn,            //2.5V    //LCD Data / Command Select
    inout    [7:0]      lcd_data,            //2.5V    //LCD Data
    output              lcd_wen,             //2.5V    //LCD Write Enable
`endif

`ifdef userio
//User-IO------------------------------//27 pins //--------------------------
    input   [7:0]       user_dipsw,          //HSMB_VAR    //User DIP Switches (TR=0)
    output  [7:0]       user_led_g,            //2.5V    //User LEDs
    output  [7:0]       user_led_r,            //2.5V/1.8V    //User LEDs
    input   [2:0]       user_pb,             //HSMB_VAR    //User Pushbuttons (TR=0)
    input               cpu_resetn,          //2.5V    //CPU Reset Pushbutton (TR=0)
`endif

`ifdef pcie
//PCI-Express--------------------------//25 pins //--------------------------
    input  [7:0] pcie_rx_p,           //PCML14  //PCIe Receive Data-req's OCT
    output [7:0] pcie_tx_p,           //PCML14  //PCIe Transmit Data
    input        pcie_refclk_p,       //HCSL    //PCIe Clock- Terminate on MB
    output              pcie_led_g3,         //2.5V    //User LED - Labeled Gen3
    output              pcie_led_g2,         //2.5V    //User LED - Labeled Gen2
    output              pcie_led_x1,         //2.5V    //User LED - Labeled x1
    output              pcie_led_x4,         //2.5V    //User LED - Labeled x4
    output              pcie_led_x8,         //2.5V    //User LED - Labeled x8
    input               pcie_perstn,         //2.5V    //PCIe Reset
    input               pcie_smbclk,         //2.5V    //SMBus Clock (TR=0)
    inout               pcie_smbdat,         //2.5V    //SMBus Data (TR=0)
    output              pcie_waken,          //2.5V    //PCIe Wake-Up (TR=0)
                                               //must install 0-ohm resistor
`endif

`ifdef usb

//USB 2.0-----------------------------//19 pins  //--------------------------
    inout  [7:0]        usb_data,                //1.5V from MAXV
    inout  [1:0]        usb_addr,                //1.5V from MAXV
    inout               usb_clk,                //3.3V from Cypress USB
    output              usb_full,                //1.5V from MAXV
    output              usb_empty,                //1.5V from MAXV
    input               usb_scl,                    //1.5V from MAXV
    inout               usb_sda,                    //1.5V from MAXV
    input               usb_oen,                    //1.5V from MAXV
    input               usb_rdn,                    //1.5V from MAXV
    input               usb_wrn,                    //1.5V from MAXV
    input               usb_resetn,                //1.5V from MAXV
`endif

//Transceiver-SMA-Output---------------//2 pins  //--------------------------
   //input          sma_tx_p,          //PCML14  //SMA Output Pair
`ifdef hsmcportA
//HSMC-Port-A--------------------------//107pins //--------------------------
    input               hsma_clk_in0,        //2.5V    //Primary single-ended CLKIN
    input               hsma_clk_in_p1,      //LVDS    //Secondary diff. CLKIN
    input               hsma_clk_in_p2,      //LVDS    //Primary Source-Sync CLKIN
    output              hsma_clk_out0,       //2.5V    //Primary single-ended CLKOUT
    output              hsma_clk_out_p1,     //LVDS    //Secondary diff. CLKOUT
    output              hsma_clk_out_p2,     //LVDS    //Primary Source-Sync CLKOUT
    inout    [3:0]      hsma_d,              //2.5V    //Dedicated CMOS IO
    input               hsma_prsntn,         //2.5V    //HSMC Presence Detect Input
   //output   [16:1] hsma_rx_p,         //LVDS    //LVDS Sounce-Sync Input
    output  [16:0]      hsma_rx_p,
    output  [16:0]      hsma_rx_n,
    output  [16:0]      hsma_tx_n,
    output  [16:0]      hsma_tx_p,         //LVDS    //LVDS Sounce-Sync Output
    output              hsma_rx_led,         //2.5V    //User LED - Labeled RX
    output              hsma_scl,            //2.5V    //SMBus Clock
    inout               hsma_sda,            //2.5V    //SMBus Data
    output              hsma_tx_led,         //2.5V    //User LED - Labeled TX
    inout               hdmi_rx_sda,
    output              hdmi_rx_scl,
`endif

//HSMC-Port-B--------------------------//107pins //--------------------------

    output [13:0]       dac_data,

    input               adc_dco,
    input [13:0]        adc_data,
    output              adc_oe_n,
    input               adc_or_in,
    output              adc_clk_p,
    //output              adc_clk_n,
    output              adc_sclk,
    output              adc_sdio,
    output              adc_cs_n
);

wire                shrink_led;
wire                pll_led;
wire                pi_iic_scl;
wire                pi_iic_sda;
wire                iic_scl, iic_sda;

// -------------- HDMI signals declaration -----------------
wire                hdmi_tx_rst_n;
wire [11:0]         hdmi_tx_rd;
wire [11:0]         hdmi_tx_gd;
wire [11:0]         hdmi_tx_bd;
wire                hdmi_tx_de;
wire                hdmi_tx_hs;
wire                hdmi_tx_vs;
wire                hdmi_tx_pclk;
wire                hdmi_tx_int_n;

// --------------- ADC signals declaration -----------------
wire                or_led;
// -------------- Capture signals
wire                capture_pulse_out;

assign user_led_r[0] = shrink_led;
assign user_led_r[1] = pll_led;
assign user_led_r[2] = or_led;
//assign user_led_r[2] = iic_sda;
//assign user_led_r[3] = iic_scl;

//assign user_led_r[7:5] = 3'b111;

//-------------- HDMI interface assignment -------------------
assign hsma_rx_p[7] = hdmi_tx_pclk;

assign hsma_tx_p[1] = hdmi_tx_rd[11];
assign hsma_tx_n[1] = hdmi_tx_rd[10];
assign hsma_tx_p[2] = hdmi_tx_rd[9];
assign hsma_tx_n[2] = hdmi_tx_rd[8];
assign hsma_tx_p[3] = hdmi_tx_rd[7];
assign hsma_tx_n[3] = hdmi_tx_rd[6];
assign hsma_tx_p[4] = hdmi_tx_rd[5];
assign hsma_tx_n[4] = hdmi_tx_rd[4];
assign hsma_tx_p[5] = hdmi_tx_rd[3];
assign hsma_tx_n[5] = hdmi_tx_rd[2];
assign hsma_tx_p[6] = hdmi_tx_rd[1];
assign hsma_tx_n[6] = hdmi_tx_rd[0];

assign hsma_tx_p[8] = hdmi_tx_gd[11];
assign hsma_tx_n[8] = hdmi_tx_gd[10];
assign hsma_tx_p[9] = hdmi_tx_gd[9];
assign hsma_tx_n[9] = hdmi_tx_gd[8];
assign hsma_tx_p[10] = hdmi_tx_gd[7];
assign hsma_tx_n[10] = hdmi_tx_gd[6];
assign hsma_tx_p[11] = hdmi_tx_gd[5];
assign hsma_tx_n[11] = hdmi_tx_gd[4];
assign hsma_tx_p[12] = hdmi_tx_gd[3];
assign hsma_tx_n[12] = hdmi_tx_gd[2];
assign hsma_tx_p[13] = hdmi_tx_gd[1];
assign hsma_tx_n[13] = hdmi_tx_gd[0];

assign hsma_tx_p[14] = hdmi_tx_bd[11];
assign hsma_rx_p[9] = hdmi_tx_bd[10];
assign hsma_rx_n[9] = hdmi_tx_bd[9];
assign hsma_rx_p[10] = hdmi_tx_bd[8];
assign hsma_rx_n[10] = hdmi_tx_bd[7];
assign hsma_rx_p[11] = hdmi_tx_bd[6];
assign hsma_rx_n[11] = hdmi_tx_bd[5];
assign hsma_rx_p[12] = hdmi_tx_bd[4];
assign hsma_rx_n[12] = hdmi_tx_bd[3];
assign hsma_rx_p[13] = hdmi_tx_bd[2];
assign hsma_rx_n[13] = hdmi_tx_bd[1];
assign hsma_rx_p[14] = hdmi_tx_bd[0];

assign hsma_rx_n[14] = hdmi_tx_de;
assign hsma_rx_p[15] = hdmi_tx_hs;
assign hsma_rx_n[15] = hdmi_tx_vs;
assign hsma_rx_n[0] = hdmi_tx_rst_n;
assign hsma_rx_p[1] = hdmi_tx_int_n;
// ----------------- ADC interface assignment ----------------

/*
iobuf iobuf (
    .datain(fpga_adc_clk_p),
    .dataout(adc_clk_p),
    );
*/
wire          fpga_adc_clk_p;
assign adc_clk_p = fpga_adc_clk_p;

wire          onchip_mem_clk;
wire          onchip_mem_rstn;
wire          onchip_mem_clken;
wire          onchip_mem_chip_select;
wire          onchip_mem_read;
wire [255:0]  onchip_mem_rddata;
wire [12:0]   onchip_mem_addr;
wire [31:0]   onchip_mem_byte_enable;
wire          onchip_mem_write;
wire [255:0]  onchip_mem_write_data;

// DDR3 interface
reg            start, start_r/*synthesis keep*/;
wire           start_vio;
wire           ddr3_clk;
wire           ddr3_rst_n;
wire           ddr3_ready;
wire [255:0]   ddr3_read_data;
wire           ddr3_rddata_valid;

wire          ddr3_read;
wire          ddr3_write;
wire [21:0]   ddr3_addr;
wire [255:0]  ddr3_write_data;
wire [31:0]   ddr3_byte_enable;
wire [4:0]    ddr3_burst_count;
wire          ddr3_begin_burst;
wire [31:0]   ddr3_byte_ena;


fast_wps_nios_top fast_wps_nios_top_i (
    .clk50m_in              (clkin_50),
    .reset_n                (cpu_resetn),

    .led_o                  (user_led_g),
    .shrink_led             (shrink_led),
    .pll_led                (pll_led),
    //.clk_200m_out           (ddr3_usr_clk),
    //.rst_n_out              (ddr3_usr_rst_n),

    .iic_sda                (iic_sda),
    .iic_scl                (iic_scl),

    .adc_dco                (adc_dco),
    .adc_data               (adc_data),
    .adc_oe_n               (adc_oe_n),
    .adc_or_in              (adc_or_in),
    .fpga_adc_clk_p         (fpga_adc_clk_p),

// DDR3 interface
    .start                 (start),
    .ddr3_emif_clk         (ddr3_clk),
    .ddr3_emif_rst_n       (ddr3_rst_n),
    .ddr3_emif_ready       (ddr3_ready),
    .ddr3_emif_read_data   (ddr3_read_data),
    .ddr3_emif_rddata_valid(ddr3_rddata_valid),
    .ddr3_emif_read        (ddr3_read),
    .ddr3_emif_write       (ddr3_write),
    .ddr3_emif_addr        (ddr3_addr),
    .ddr3_emif_write_data  (ddr3_write_data),
    .ddr3_emif_byte_enable (ddr3_byte_enable),
    .ddr3_emif_burst_count (ddr3_burst_count),

    .onchip_mem_clk        (onchip_mem_clk),
    .onchip_mem_rstn       (onchip_mem_rstn),
    .onchip_mem_clken      (onchip_mem_clken),
    .onchip_mem_chip_select(onchip_mem_chip_select),
    .onchip_mem_read       (onchip_mem_read),
    .onchip_mem_rddata     (onchip_mem_rddata),
    .onchip_mem_addr       (onchip_mem_addr),
    .onchip_mem_byte_enable(onchip_mem_byte_enable),
    .onchip_mem_write      (onchip_mem_write),
    .onchip_mem_write_data (onchip_mem_write_data),
    //.fpga_adc_clk_n(fpga_adc_clk_n),
    .or_led                 (or_led),
    .adc_sclk               (adc_sclk),
    .adc_sdio               (adc_sdio),
    .adc_cs_n               (adc_cs_n),
    .dac_data               (dac_data),

    .hdmi_tx_rst_n          (hdmi_tx_rst_n),
    .hdmi_int_n             (hdmi_tx_int_n),
    .hdmi_pcsda             (hsma_d[3]),
    .hdmi_pcscl             (hsma_d[1]),
    .hdmi_tx_pclk           (hdmi_tx_pclk),
    .hdmi_tx_rd             (hdmi_tx_rd),
    .hdmi_tx_gd             (hdmi_tx_gd),
    .hdmi_tx_bd             (hdmi_tx_bd),
    .hdmi_tx_de             (hdmi_tx_de),
    .hdmi_tx_vs             (hdmi_tx_vs),
    .hdmi_tx_hs             (hdmi_tx_hs),

    .capture_pulse_out     (capture_pulse_out)

   );

// PCI-e signals
wire L0_led, alive_led, comp_led, gen2_led, gen3_led;
wire [3:0] lane_active_led;
wire reconfig_xcvr_clk, pll_ref_clk, oct_rzqin;
wire local_rstn;

wire                ddr3_usr_clk/*synthesis keep*/;
wire                ddr3_usr_rst_n/*synthesis keep*/;

localparam ADDR_WIDTH = 22;
localparam LEN_WIDTH = 8;
wire [ADDR_WIDTH-1:0]           ddr3_start_to_wr_addr_in;
wire [LEN_WIDTH-1:0]            ddr3_bytes_to_wr_in;
wire                            ddr3_wr_req_in;
wire [31:0]                     ddr3_wr_data_in;
wire                            ddr3_wr_valid_in;

wire                            ddr3_rd_req_in;
wire [ADDR_WIDTH-1:0]           ddr3_start_to_rd_addr_in;
wire [LEN_WIDTH-1:0]            ddr3_bytes_to_rd_in;
wire                            ddr3_rddata_valid_out/*synthesis keep*/;
wire [31:0]                     ddr3_rddata_out/*synthesis keep*/;

assign reconfig_xcvr_clk = clkinbot_p[0];
assign local_rstn = user_pb[0];
assign user_led_r[3] = gen2_led;
assign user_led_r[4] = gen3_led;
assign user_led_r[5] = comp_led;
assign user_led_r[6] = alive_led;
assign user_led_r[7] = L0_led;
assign pll_ref_clk = clkintop_p[0];
assign oct_rzqin = rzqin_1p5;

pcie_dma_gen3x8 pcie_dma_gen3x8_i (
   .pcie_rx          (pcie_rx_p),
   .pcie_tx          (pcie_tx_p),
   .refclk_clk       (pcie_refclk_p),
   .reconfig_xcvr_clk(reconfig_xcvr_clk),
   .local_rstn       (local_rstn),

   //.pld_clk_clk      (pld_clk_clk),
   .lane_active_led  (lane_active_led),
   .L0_led           (L0_led),
   .alive_led        (alive_led),
   .comp_led         (comp_led),
   .gen2_led         (gen2_led),
   .gen3_led         (gen3_led),
   .perstn           (pcie_perstn),

   .pll_ref_clk      (pll_ref_clk),
   .mem_a            (ddr3_a),
   .mem_ba           (ddr3_ba),
   .mem_ck           (ddr3_clk_p),
   .mem_ck_n         (ddr3_clk_n),
   .mem_cke          (ddr3_cke),
   .mem_cs_n         (ddr3_csn),
   .mem_dm           (ddr3_dm[7:0]),
   .mem_ras_n        (ddr3_rasn),
   .mem_cas_n        (ddr3_casn),
   .mem_we_n         (ddr3_wen),
   .mem_reset_n      (ddr3_resetn),
   .mem_dq           (ddr3_dq[63:0]),
   .mem_dqs          (ddr3_dqs_p[7:0]),
   .mem_dqs_n        (ddr3_dqs_n[7:0]),
   .mem_odt          (ddr3_odt),
   .oct_rzqin        (oct_rzqin),
   .cpu_resetn       (cpu_resetn),

   .ddr3_clk            (ddr3_clk),
   .ddr3_rst_n          (ddr3_rst_n),
   .ddr3_addr             (ddr3_addr),
   .ddr3_burst_count      (ddr3_burst_count),
   .ddr3_begin_burst      (ddr3_begin_burst),
   .ddr3_write             (ddr3_write),
   .ddr3_write_data       (ddr3_write_data),
   .ddr3_byte_ena         (ddr3_byte_ena),
   .ddr3_read             (ddr3_read),
   .ddr3_ready            (ddr3_ready),
   .ddr3_read_data        (ddr3_read_data),
   .ddr3_rddata_valid     (ddr3_rddata_valid),
   .onchip_mem_clk        (onchip_mem_clk),
   .onchip_mem_rstn       (onchip_mem_rstn),
   .onchip_mem_clken      (onchip_mem_clken),
   .onchip_mem_chip_select(onchip_mem_chip_select),
   //.onchip_mem_read       (onchip_mem_read),
   .onchip_mem_rddata     (onchip_mem_rddata),
   .onchip_mem_addr       (onchip_mem_addr),
   .onchip_mem_byte_enable(onchip_mem_byte_enable),
   .onchip_mem_write      (onchip_mem_write),
   .onchip_mem_write_data (onchip_mem_write_data)
   );

altsource_probe #(
    .sld_auto_instance_index ("YES"),
    .sld_instance_index      (0),
    .instance_id             ("STA"),
    .probe_width             (0),
    .source_width            (1),
    .source_initial_value    ("0"),
    .enable_metastability    ("NO")
) ddr3_addr_source (
    .source(start_vio)
);


always @(posedge hdmi_tx_pclk or negedge ddr3_rst_n) begin
    if(~ddr3_rst_n) begin
        start_r <= 0;
        start <= 0;
    end else begin
        start_r <= start_vio;
        start <= ~start_r & start_vio;
    end
end

/*
timer #(.MAX(32'h2d7bc00))
timer_inst(
    .clk      (hdmi_tx_pclk),
    .rst_n    (1'b1),
    .timer_ena(1'b1),
    .timer_rst(1'b0),
    .timer_out(start)

    );

// Generate data for DDR testing

// DDR write
reg [31:0]  data_gen;
reg         data_gen_valid;
reg         data_gen_ena, data_gen_ena_r;
reg [ADDR_WIDTH-1:0]  start_wr_addr;
reg [LEN_WIDTH-1:0] bytes_to_write;
wire [ADDR_WIDTH-1:0]  start_wr_addr_vio;
wire [LEN_WIDTH-1:0] bytes_to_write_vio;
wire                 data_gen_ena_vio;

// DDR read
wire [ADDR_WIDTH-1:0]  start_rd_addr_vio;
wire [LEN_WIDTH-1:0] bytes_to_read_vio;
wire                 data_read_req_vio;
reg                  data_read_req, data_read_req_r;

reg [1:0] state;
localparam S0 = 2'h0, S1 = 2'h1, S2 = 2'h2;
reg [7:0] bytes_cnt;

// DDR write logics
assign ddr3_wr_valid_in = data_gen_valid;
assign ddr3_bytes_to_wr_in = bytes_to_write;
assign ddr3_start_to_wr_addr_in = start_wr_addr;
assign ddr3_wr_data_in = data_gen;
always @(posedge ddr3_usr_clk or negedge ddr3_usr_rst_n) begin
    if(~ddr3_usr_rst_n) begin
         data_gen_ena_r <= 'h0;
         data_gen_ena <= 'h0;
    end else begin
         data_gen_ena_r <= data_gen_ena_vio;
         data_gen_ena <= ~data_gen_ena_r & data_gen_ena_vio;
    end
end

always @(posedge ddr3_usr_clk or negedge ddr3_usr_rst_n) begin
    if(~ddr3_usr_rst_n) begin
         data_gen <= 'h0;
         data_gen_valid <= 1'b0;
         start_wr_addr <= 'h0;
         bytes_to_write <= 'h0;
         state <= S0;
    end else begin
        case(state)
            S0: begin
                data_gen <= 'h0;
                data_gen_valid <= 1'b0;
                start_wr_addr <= 'h0;
                bytes_to_write <= 'h0;
                bytes_cnt <= 'h0;
                if (data_gen_ena) begin
                    state <= S1;
                end
            end
            S1: begin
                data_gen_valid <= 1'b1;
                start_wr_addr <= start_wr_addr_vio;
                bytes_to_write <= bytes_to_write_vio;
                data_gen <= 32'h00010203;
                bytes_cnt <= bytes_cnt + 8'd4;
                if (bytes_to_write_vio <= 8'd4) begin
                    state <= S0;
                end
                else begin
                    state <= S2;
                end
            end
            S2: begin
                if (bytes_cnt <= (bytes_to_write_vio - 8'd4)) begin
                    state <= S0;
                    data_gen_valid <= 1'b0;
                end
                else begin
                    bytes_cnt <= bytes_cnt + 8'd4;
                    data_gen <= data_gen + 32'h04040404;
                    data_gen_valid <= 1'b1;
                end
            end
            default: begin
                state <= S0;
                data_gen_valid <= 0;
                data_gen <= 0;
                start_wr_addr <= 0;
                bytes_to_write <= 0;
            end
        endcase // state
    end
end

source_probe ddr3_wr_source (
    .source_clk (ddr3_usr_clk), // source_clk.clk
    .source     ({start_wr_addr_vio, bytes_to_write_vio, data_gen_ena_vio,1'b0})      //    sources.source
);

// DDR read logics

assign ddr3_rd_req_in = data_read_req;
assign ddr3_start_to_rd_addr_in = start_rd_addr_vio;
assign ddr3_bytes_to_rd_in = bytes_to_read_vio;

always @(posedge ddr3_usr_clk or negedge ddr3_usr_rst_n) begin
    if(~ddr3_usr_rst_n) begin
         data_read_req <= 'h0;
         data_read_req_r <= 'h0;
    end else begin
         data_read_req_r <= data_read_req_vio;
         data_read_req <= ~data_read_req_r & data_read_req_vio;
    end
end

source_probe ddr3_rd_source (
    .source_clk (ddr3_usr_clk), // source_clk.clk
    .source     ({start_rd_addr_vio, bytes_to_read_vio, data_read_req_vio,1'b0})      //    sources.source
);

source_probe ddr3_rddata_source (
    .source_clk (ddr3_usr_clk), // source_clk.clk
    .probe     ({ddr3_rddata_out, ddr3_rddata_valid_out})      //    sources.source
);
*/
endmodule
