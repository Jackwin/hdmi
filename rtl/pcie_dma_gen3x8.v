module pcie_dma_gen3x8 (

    input wire [7:0]    pcie_rx,
    output wire [7:0]   pcie_tx,
    input wire          refclk_clk,
    input wire          reconfig_xcvr_clk,
    input wire          local_rstn,

   // output wire         pld_clk_clk,
    output  reg [3:0]   lane_active_led,
    output  reg         L0_led,
    output  reg         alive_led,
    output  reg         comp_led,
    output  reg         gen2_led,
    output  reg         gen3_led,
    input  wire         perstn,             //  pcie_rstn.npor

    // DDR3 signals
    input  wire        pll_ref_clk,              //  pll_ref_clk.clk
    output wire [13:0] mem_a,                    //       memory.mem_a
    output wire [2:0]  mem_ba,                   //             .mem_ba
    output wire        mem_ck,                   //             .mem_ck
    output wire        mem_ck_n,                 //             .mem_ck_n
    output wire        mem_cke,                  //             .mem_cke
    output wire        mem_cs_n,                 //             .mem_cs_n
    output wire [7:0]  mem_dm,                   //             .mem_dm
    output wire        mem_ras_n,                //             .mem_ras_n
    output wire        mem_cas_n,                //             .mem_cas_n
    output wire        mem_we_n,                 //             .mem_we_n
    output wire        mem_reset_n,              //             .mem_reset_n
    inout  wire [63:0] mem_dq,                   //             .mem_dq
    inout  wire [7:0]  mem_dqs,                  //             .mem_dqs
    inout  wire [7:0]  mem_dqs_n,                //             .mem_dqs_n
    output wire        mem_odt,                  //             .mem_odt
    input  wire        oct_rzqin,                //          oct.rzqin
    input              cpu_resetn


);

wire [52:0]         tl_cfg_tl_cfg_sts;
wire [31:0]         tl_cfg_tl_cfg_ctl;            //            tl_cfg.tl_cfg_ctl
wire [3:0]          tl_cfg_tl_cfg_add;            //                  .tl_cfg_add

reg [ 24: 0]        alive_cnt;
wire                any_rstn;
reg                 any_rstn_r /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=R102"  */;
reg                 any_rstn_rr /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=R102"  */;
wire                gen2_speed;
wire                gen3_speed;
wire [5:0]          ltssm;

wire                pld_clk_clk;

assign any_rstn = perstn & local_rstn;
//assign hsma_clk_out_p2 = reconfig_xcvr_clk;
assign gen2_speed  = tl_cfg_tl_cfg_sts[32:31] == 2'b10;
assign gen3_speed  = tl_cfg_tl_cfg_sts[32:31] == 2'b11;

//For DDR3
assign mem_a[13] = 0;


reg    cbb_btn_r;
reg    [2:0] cbb_cnt;

localparam WID = 8;
wire [WID-1:0] cbb_btn=0;

//lpm_constant    cbb
//  (
//   .result (cbb_btn)
//   );
//defparam
//         cbb.lpm_cvalue = 0,
//         cbb.lpm_hint = "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=CBB2",
//         cbb.lpm_type = "LPM_CONSTANT",
//         cbb.lpm_width = WID;


//assign hip_ctrl_test_in[4:0]  =  5'b01000;
//assign hip_ctrl_test_in[5] =  1'b1;
//assign hip_ctrl_test_in[31:6] =  26'h2;


  //CBB push button
  always @(posedge reconfig_xcvr_clk or negedge any_rstn)
    begin
      if (any_rstn == 0)
        begin
        cbb_cnt <= 0;
        cbb_btn_r <= 0;
        end
      else
        begin
        cbb_btn_r <= cbb_btn[0];

        if (cbb_btn_r != cbb_btn[0])
          cbb_cnt <= 3'h7;
        else if (cbb_cnt == 0)
          cbb_cnt <= 0;
        else
          cbb_cnt <= cbb_cnt - 1;

        end
    end

  //reset Synchronizer
  always @(posedge reconfig_xcvr_clk or negedge any_rstn)
    begin
      if (any_rstn == 0)
        begin
          any_rstn_r <= 0;
          any_rstn_rr <= 0;
        end
      else
        begin
          any_rstn_r <= 1;
          any_rstn_rr <= any_rstn_r;
        end
    end

  //LED logic
  always @(posedge pld_clk_clk or negedge any_rstn_rr)
    begin
      if (any_rstn_rr == 0)
        begin
          alive_cnt <= 0;
          alive_led <= 0;
          comp_led <= 0;
          L0_led <= 0;
          gen2_led <= 0;
          gen3_led <= 0;
          lane_active_led[3:2] <= 0;
          lane_active_led[0] <= 0;
        end
      else
        begin
          alive_cnt <= alive_cnt +1;
          alive_led <= alive_cnt[24];
          comp_led <= ~(ltssm[4 : 0] == 5'b00011);
          L0_led <= ~(ltssm[4 : 0] == 5'b01111);
          gen2_led <= ~gen2_speed;
          gen3_led <= ~gen3_speed;
          if (tl_cfg_tl_cfg_sts[35])
            lane_active_led <= ~(4'b0001);
          else if (tl_cfg_tl_cfg_sts[36])
            lane_active_led <= ~(4'b0011);
          else if (tl_cfg_tl_cfg_sts[37])
            lane_active_led <= ~(4'b1111);
          else if (tl_cfg_tl_cfg_sts[38])
            lane_active_led <= alive_cnt[24] ? ~(4'b1111) : ~(4'b0111);
        end
    end


pcie_de_ep_dma_g3x8_integrated u0 (

    .pcie_256_hip_avmm_0_hip_serial_rx_in0                   (pcie_rx[0]),                   //          pcie_256_hip_avmm_0_hip_serial.rx_in0
    .pcie_256_hip_avmm_0_hip_serial_rx_in1                   (pcie_rx[1]),                   //                                        .rx_in1
    .pcie_256_hip_avmm_0_hip_serial_rx_in2                   (pcie_rx[2]),                   //                                        .rx_in2
    .pcie_256_hip_avmm_0_hip_serial_rx_in3                   (pcie_rx[3]),                   //                                        .rx_in3
    .pcie_256_hip_avmm_0_hip_serial_rx_in4                   (pcie_rx[4]),                   //                                        .rx_in4
    .pcie_256_hip_avmm_0_hip_serial_rx_in5                   (pcie_rx[5]),                   //                                        .rx_in5
    .pcie_256_hip_avmm_0_hip_serial_rx_in6                   (pcie_rx[6]),                   //                                        .rx_in6
    .pcie_256_hip_avmm_0_hip_serial_rx_in7                   (pcie_rx[7]),                   //                                        .rx_in7
    .pcie_256_hip_avmm_0_hip_serial_tx_out0                  (pcie_tx[0]),                  //                                        .tx_out0
    .pcie_256_hip_avmm_0_hip_serial_tx_out1                  (pcie_tx[1]),                  //                                        .tx_out1
    .pcie_256_hip_avmm_0_hip_serial_tx_out2                  (pcie_tx[2]),                  //                                        .tx_out2
    .pcie_256_hip_avmm_0_hip_serial_tx_out3                  (pcie_tx[3]),                  //                                        .tx_out3
    .pcie_256_hip_avmm_0_hip_serial_tx_out4                  (pcie_tx[4]),                  //                                        .tx_out4
    .pcie_256_hip_avmm_0_hip_serial_tx_out5                  (pcie_tx[5]),                  //                                        .tx_out5
    .pcie_256_hip_avmm_0_hip_serial_tx_out6                  (pcie_tx[6]),                  //                                        .tx_out6
    .pcie_256_hip_avmm_0_hip_serial_tx_out7                  (pcie_tx[7]),                  //                                        .tx_out7
    .pcie_256_hip_avmm_0_npor_npor                           (any_rstn_rr),                           //                pcie_256_hip_avmm_0_npor.npor
    .pcie_256_hip_avmm_0_npor_pin_perst                      (perstn),                      //                                        .pin_perst
    .reconfig_xcvr_clk_clk                                   (reconfig_xcvr_clk),                                   //                       reconfig_xcvr_clk.clk
    .reconfig_xcvr_reset_reset_n                             ((local_rstn==1'b0)?1'b0:(perstn==1'b0)?1'b0:1'b1),                             //                     reconfig_xcvr_reset.reset_n
    .refclk_clk                                              (refclk_clk),                                              //                                  refclk.clk
    .pld_clk_clk                                             (pld_clk_clk),
    .pcie_256_dma_config_tl_tl_cfg_add                       (tl_cfg_tl_cfg_add),                       //                  pcie_256_dma_config_tl.tl_cfg_add
    .pcie_256_dma_config_tl_tl_cfg_ctl                       (tl_cfg_tl_cfg_ctl),                       //                                        .tl_cfg_ctl
    .pcie_256_dma_config_tl_tl_cfg_sts                       (tl_cfg_tl_cfg_sts),                        //                                        .tl_cfg_sts
    .memory_mem_a                                            (mem_a[12:0]),                                            //                                  memory.mem_a
    .memory_mem_ba                                           (mem_ba),                                           //                                        .mem_ba
    .memory_mem_ck                                           (mem_ck),                                           //                                        .mem_ck
    .memory_mem_ck_n                                         (mem_ck_n),                                         //                                        .mem_ck_n
    .memory_mem_cke                                          (mem_cke),                                          //                                        .mem_cke
    .memory_mem_cs_n                                         (mem_cs_n),                                         //                                        .mem_cs_n
    .memory_mem_dm                                           (mem_dm),                                           //                                        .mem_dm
    .memory_mem_ras_n                                        (mem_ras_n),                                        //                                        .mem_ras_n
    .memory_mem_cas_n                                        (mem_cas_n),                                        //                                        .mem_cas_n
    .memory_mem_we_n                                         (mem_we_n),                                         //                                        .mem_we_n
    .memory_mem_reset_n                                      (mem_reset_n),                                      //                                        .mem_reset_n
    .memory_mem_dq                                           (mem_dq),                                           //                                        .mem_dq
    .memory_mem_dqs                                          (mem_dqs),                                          //                                        .mem_dqs
    .memory_mem_dqs_n                                        (mem_dqs_n),                                        //                                        .mem_dqs_n
    .memory_mem_odt                                          (mem_odt),                                          //                                        .mem_odt
    .oct_rzqin                                               (oct_rzqin),                                               //                                     oct.rzqin
    .clk_clk                                                 (pll_ref_clk),                                                 //                                     clk.clk
    .reset_reset_n                                           (cpu_resetn)                                            //                                   reset.reset_n
    );

endmodule