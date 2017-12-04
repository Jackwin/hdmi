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
    output  [8:0]        ddr3_dm,          //SSTL15  //Data Write Mask
    inout   [71:0]       ddr3_dq,          //SSTL15  //Data Bus
    inout   [8:0]        ddr3_dqs_n,       //SSTL15  //Diff Data Strobe - Neg
    inout   [8:0]        ddr3_dqs_p,       //SSTL15  //Diff Data Strobe - Pos
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
    //input  [7:0] pcie_rx_p,           //PCML14  //PCIe Receive Data-req's OCT
    //output [7:0] pcie_tx_p,           //PCML14  //PCIe Transmit Data
    //input        pcie_refclk_p,       //HCSL    //PCIe Clock- Terminate on MB
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

assign user_led_r[0] = shrink_led;
assign user_led_r[1] = pll_led;
assign user_led_r[2] = iic_sda;
assign user_led_r[3] = iic_scl;
assign user_led_r[4] = or_led;
assign user_led_r[7:5] = 3'b111;

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
assign adc_clk_p = fpga_adc_clk_p;
fast_wps_nios_top fast_wps_nios_top_i (
   .clk50m_in(clkin_50),
   .reset_n(cpu_resetn),

   .led_o(user_led_g),
   .shrink_led(shrink_led),
   .pll_led(pll_led),

    .iic_sda(iic_sda),
    .iic_scl(iic_scl),

    .adc_dco       (adc_dco),
    .adc_data      (adc_data),
    .adc_oe_n      (adc_oe_n),
    .adc_or_in     (adc_or_in),
    .fpga_adc_clk_p(fpga_adc_clk_p),
    //.fpga_adc_clk_n(fpga_adc_clk_n),
    .or_led        (or_led),
    .adc_sclk      (adc_sclk),
    .adc_sdio      (adc_sdio),
    .adc_cs_n      (adc_cs_n),
    .dac_data      (dac_data),

    .hdmi_tx_rst_n(hdmi_tx_rst_n),
    .hdmi_int_n(hdmi_tx_int_n),
    .hdmi_pcsda(hsma_d[3]),
    .hdmi_pcscl(hsma_d[1]),
    .hdmi_tx_pclk(hdmi_tx_pclk),
    .hdmi_tx_rd(hdmi_tx_rd),
    .hdmi_tx_gd(hdmi_tx_gd),
    .hdmi_tx_bd(hdmi_tx_bd),
    .hdmi_tx_de(hdmi_tx_de),
    .hdmi_tx_vs(hdmi_tx_vs),
    .hdmi_tx_hs(hdmi_tx_hs)

   );





endmodule
