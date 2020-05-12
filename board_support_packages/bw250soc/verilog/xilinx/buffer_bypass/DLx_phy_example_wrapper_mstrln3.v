//------------------------------------------------------------------------------
//  (c) Copyright 2013-2015 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES.
//------------------------------------------------------------------------------


`timescale 1ps/1ps

// =====================================================================================================================
// This example design wrapper module instantiates the core and any helper blocks which the user chose to exclude from
// the core, connects them as appropriate, and maps enabled ports
// =====================================================================================================================

module DLx_phy_example_wrapper (
  input  wire [7:0] gtyrxn_in
 ,input  wire [7:0] gtyrxp_in
 ,output wire [7:0] gtytxn_out
 ,output wire [7:0] gtytxp_out
 ,input  wire [0:0] gtwiz_userclk_tx_reset_in
 ,output wire [0:0] gtwiz_userclk_tx_srcclk_out
 ,output wire [0:0] gtwiz_userclk_tx_usrclk_out
 ,output wire [0:0] gtwiz_userclk_tx_usrclk2_out
 ,output wire [0:0] gtwiz_userclk_tx_active_out
 ,input  wire [0:0] gtwiz_userclk_rx_reset_in
 ,output wire [0:0] gtwiz_userclk_rx_srcclk_out
 ,output wire [0:0] gtwiz_userclk_rx_usrclk_out
 ,output wire [0:0] gtwiz_userclk_rx_usrclk2_out
 ,output wire [0:0] gtwiz_userclk_rx_active_out
 ,input  wire [0:0] gtwiz_buffbypass_tx_reset_in
 ,input  wire [0:0] gtwiz_buffbypass_tx_start_user_in
 ,output wire [0:0] gtwiz_buffbypass_tx_done_out
 ,output wire [0:0] gtwiz_buffbypass_tx_error_out
 ,input  wire [0:0] gtwiz_buffbypass_rx_reset_in
 ,input  wire [0:0] gtwiz_buffbypass_rx_start_user_in
 ,output wire [0:0] gtwiz_buffbypass_rx_done_out
 ,output wire [0:0] gtwiz_buffbypass_rx_error_out
 ,input  wire [0:0] gtwiz_reset_clk_freerun_in
 ,input  wire [0:0] gtwiz_reset_all_in
 ,input  wire [0:0] gtwiz_reset_tx_pll_and_datapath_in
 ,input  wire [0:0] gtwiz_reset_tx_datapath_in
 ,input  wire [0:0] gtwiz_reset_rx_pll_and_datapath_in
 ,input  wire [0:0] gtwiz_reset_rx_datapath_in
 ,output wire [0:0] gtwiz_reset_rx_cdr_stable_out
 ,output wire [0:0] gtwiz_reset_tx_done_out
 ,output wire [0:0] gtwiz_reset_rx_done_out
 ,input  wire [511:0] gtwiz_userdata_tx_in
 ,output wire [511:0] gtwiz_userdata_rx_out
 ,input  wire [1:0] gtrefclk01_in
 ,output wire [1:0] qpll1outclk_out
 ,output wire [1:0] qpll1outrefclk_out
 //,input  wire [79:0] drpaddr_in
 //,input  wire [7:0] drpclk_in
 //,input  wire [127:0] drpdi_in
 //,input  wire [7:0] drpen_in
 //,input  wire [7:0] drpwe_in
 //,input  wire [7:0] eyescanreset_in
 ,input  wire [7:0] rxgearboxslip_in
 ,input  wire [7:0] rxlpmen_in
 ,input  wire [23:0] rxrate_in
 ,input  wire [39:0] txdiffctrl_in
 ,input  wire [47:0] txheader_in
 ,input  wire [39:0] txpostcursor_in
 ,input  wire [39:0] txprecursor_in
 ,input  wire [55:0] txsequence_in
 //,output wire [127:0] drpdo_out
 //,output wire [7:0] drprdy_out
 ,output wire [15:0] rxdatavalid_out
 ,output wire [47:0] rxheader_out
 ,output wire [15:0] rxheadervalid_out
 ,output wire [7:0] rxpmaresetdone_out
 ,output wire [15:0] rxstartofseq_out
 ,output wire [7:0] txpmaresetdone_out
 ,output wire [7:0] txprgdivresetdone_out
 ,output wire       tx_clk_402MHz
 ,output wire       tx_clk_201MHz
);


  // ===================================================================================================================
  // PARAMETERS AND FUNCTIONS
  // ===================================================================================================================

  // Declare and initialize local parameters and functions used for HDL generation
  localparam [191:0] P_CHANNEL_ENABLE = 192'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111;
  `include "DLx_phy_example_wrapper_functions.v"
  localparam integer P_TX_MASTER_CH_PACKED_IDX = f_calc_pk_mc_idx(3);
  localparam integer P_RX_MASTER_CH_PACKED_IDX = f_calc_pk_mc_idx(3);

  wire        mmcm_locked; 
  wire        mmcm_reset;
  wire [7:0]    eyescanreset_int;
  assign eyescanreset_int   = 8'b0;
  //-- sim only
  //-- sim onlyassign tx_clk_402MHz = gtwiz_userclk_tx_usrclk2_out;
  //  mmcm_phase_align_bufg_gt test_cll_mmcm_inst
  //   (
  //    // Clock out ports
  //    // mmcm clock to main clock except tx/rx usrclk in
  //    .clk_out1(tx_clk_402MHz),              // output clk_out1
  ////-- sim only    .clk_out1( ),              // output clk_out1
  //    .clk_out2(tx_clk_201MHz),
  //    // Status and control signals
  //    .reset(gtwiz_buffbypass_tx_reset_in),                               // input reset
  //    .locked(mmcm_locked),                             // output locked
  //   // Clock in ports
  //    .clk_in1(gtwiz_userclk_tx_usrclk2_out)        // input clk_in1
  //    );
  // if no MMCM mmcm_locked = gtwiz_userclk_tx_active_out
  
  assign mmcm_locked = gtwiz_userclk_tx_active_out;
   
   
    
      (* MARK_DEBUG="true" *) wire [79:0]   drpaddr_int;
      (* MARK_DEBUG="true" *) wire [127:0]  drpdi_int;
      (* MARK_DEBUG="true" *) wire [7:0]    drpen_int;
      (* MARK_DEBUG="true" *) wire [7:0]    drpwe_int;
      (* MARK_DEBUG="true" *) wire [127:0]  drpdo_int;
      (* MARK_DEBUG="true" *) wire [7:0]    drprdy_int;
     (* MARK_DEBUG="true" *)  wire set_initial_drp_config_int;
                              wire enable_txphydly_cfg_int;
     (* MARK_DEBUG="true" *)  wire enable_txphydly_cfg_sync;
     (* MARK_DEBUG="true" *)  wire initial_drp_config_done_int;
     (* MARK_DEBUG="true" *)  wire txphydly_cfg_done_int;
     (* MARK_DEBUG="true" *)  wire enable_txsyncovrd_buf_cfg_sync;     
                              wire enable_txsyncovrd_buf_cfg_int;
     (* MARK_DEBUG="true" *)  wire txsyncovrd_buf_cfg_done_int; 
     
      (* DONT_TOUCH = "TRUE" *)
      DLx_phy_example_bit_synchronizer enable_txphydly_cfg_inst (
        .clk_in (gtwiz_reset_clk_freerun_in),
        .i_in   (enable_txphydly_cfg_int),
        .o_out  (enable_txphydly_cfg_sync)
      );  
      
      (* DONT_TOUCH = "TRUE" *)
      DLx_phy_example_bit_synchronizer enable_txsyncovrd_buf_cfg_inst (
        .clk_in (gtwiz_reset_clk_freerun_in),
        .i_in   (enable_txsyncovrd_buf_cfg_int),
        .o_out  (enable_txsyncovrd_buf_cfg_sync)
      );                      

      tx_mod_da_fsm #(
        .NUM_LANES   (8) 
      )    
      tx_delay_align_drpfsm_inst  
      (
      .reset                      (gtwiz_reset_all_in),
      .set_initial_cfg            (set_initial_drp_config_int),  
      .enable_txphydly_cfg        (enable_txphydly_cfg_sync),  
      .initial_cfg_done           (initial_drp_config_done_int),
      .txphydly_cfg_done          (txphydly_cfg_done_int),
      .enable_txsyncovrd_buf_cfg  (enable_txsyncovrd_buf_cfg_sync),
      .txsyncovrd_buf_cfg_done    (txsyncovrd_buf_cfg_done_int),
        // DRP port interface     
      .GT_DRPADDR                (drpaddr_int),
      .GT_DI                     (drpdi_int),
      .GT_DEN                    (drpen_int),
      .GT_DWE                    (drpwe_int),
      .GT_DRDY                   (drprdy_int),
      .GT_DO                     (drpdo_int),
      .DCLK                      (gtwiz_reset_clk_freerun_in)
      );

  // ===================================================================================================================
  // HELPER BLOCKS
  // ===================================================================================================================

  // Any helper blocks which the user chose to exclude from the core will appear below. In addition, some signal
  // assignments related to optionally-enabled ports may appear below.

  // -------------------------------------------------------------------------------------------------------------------
  // Transmitter user clocking network helper block
  // -------------------------------------------------------------------------------------------------------------------

  wire [7:0] txusrclk_int;
  wire [7:0] txusrclk2_int;
  wire [7:0] txoutclk_int;

  // Generate a single module instance which is driven by a clock source associated with the master transmitter channel,
  // and which drives TXUSRCLK and TXUSRCLK2 for all channels

  // The source clock is TXOUTCLK from the master transmitter channel
  assign gtwiz_userclk_tx_srcclk_out = txoutclk_int[P_TX_MASTER_CH_PACKED_IDX];

  // Instantiate a single instance of the transmitter user clocking network helper block
  DLx_phy_example_gtwiz_userclk_tx gtwiz_userclk_tx_inst (
    .gtwiz_userclk_tx_srcclk_in   (gtwiz_userclk_tx_srcclk_out),
    .gtwiz_userclk_tx_reset_in    (gtwiz_userclk_tx_reset_in),
    .gtwiz_userclk_tx_usrclk_out  (gtwiz_userclk_tx_usrclk_out),
    .gtwiz_userclk_tx_usrclk2_out (gtwiz_userclk_tx_usrclk2_out),
    .gtwiz_userclk_tx_active_out  (gtwiz_userclk_tx_active_out),
    .tx_clk_201MHz_out            (tx_clk_201MHz),
    .tx_clk_402MHz_out            (tx_clk_402MHz)
  );

  // Drive TXUSRCLK and TXUSRCLK2 for all channels with the respective helper block outputs
  assign txusrclk_int  = {8{gtwiz_userclk_tx_usrclk_out}};
  assign txusrclk2_int = {8{gtwiz_userclk_tx_usrclk2_out}};

  // -------------------------------------------------------------------------------------------------------------------
  // Receiver user clocking network helper block
  // -------------------------------------------------------------------------------------------------------------------

  wire [7:0] rxusrclk_int;
  wire [7:0] rxusrclk2_int;
  wire [7:0] rxoutclk_int;

  // Generate a single module instance which is driven by a clock source associated with the master receiver channel,
  // and which drives RXUSRCLK and RXUSRCLK2 for all channels

  // The source clock is RXOUTCLK from the master receiver channel
  assign gtwiz_userclk_rx_srcclk_out = rxoutclk_int[P_RX_MASTER_CH_PACKED_IDX];

  // Instantiate a single instance of the receiver user clocking network helper block
/*  DLx_phy_example_gtwiz_userclk_rx gtwiz_userclk_rx_inst (
    .gtwiz_userclk_rx_srcclk_in   (gtwiz_userclk_rx_srcclk_out),
    .gtwiz_userclk_rx_reset_in    (gtwiz_userclk_rx_reset_in),
    .gtwiz_userclk_rx_usrclk_out  (gtwiz_userclk_rx_usrclk_out),
    .gtwiz_userclk_rx_usrclk2_out (gtwiz_userclk_rx_usrclk2_out),
    .gtwiz_userclk_rx_active_out  (gtwiz_userclk_rx_active_out)
  );*/
  
  assign gtwiz_userclk_rx_usrclk_out  = gtwiz_userclk_tx_usrclk_out;
  assign gtwiz_userclk_rx_usrclk2_out = gtwiz_userclk_tx_usrclk2_out;
  assign gtwiz_userclk_rx_active_out  = gtwiz_userclk_tx_active_out;  

  // Drive RXUSRCLK and RXUSRCLK2 for all channels with the respective helper block outputs
  assign rxusrclk_int  = {8{gtwiz_userclk_rx_usrclk_out}};
  assign rxusrclk2_int = {8{gtwiz_userclk_rx_usrclk2_out}};

  // -------------------------------------------------------------------------------------------------------------------
  // Transmitter buffer bypass controller helper block
  // -------------------------------------------------------------------------------------------------------------------

  wire [7:0] txphaligndone_int;
  wire [7:0] txphinitdone_int;
  wire [7:0] txdlysresetdone_int;
  wire [7:0] txsyncout_int;
  wire [7:0] txsyncdone_int;
  wire [7:0] txphdlyreset_int;
  wire [7:0] txphalign_int;
  wire [7:0] txphalignen_int;
  wire [7:0] txphdlypd_int;
  wire [7:0] txphinit_int;
  wire [7:0] txphovrden_int;
  wire [7:0] txdlysreset_int;
  wire [7:0] txdlybypass_int;
  wire [7:0] txdlyen_int;
  wire [7:0] txdlyovrden_int;
  wire [7:0] txphdlytstclk_int;
  wire [7:0] txdlyhold_int;
  wire [7:0] txdlyupdown_int;
  wire [7:0] txsyncmode_int;
  wire [7:0] txsyncallin_int;
  wire [7:0] txsyncin_int;

  // Generate a single module instance which uses the designated transmitter master channel as the transmit buffer
  // bypass master channel, and all other channels as transmit buffer bypass slave channels

  // Depending on the number of reset controller helper blocks, either use the single reset done indicator or the
  // logical combination of per-channel reset done indicators as the reset done indicator for use in this block
  wire gtwiz_buffbypass_tx_resetdone_int;

 assign gtwiz_buffbypass_tx_resetdone_int = gtwiz_reset_tx_done_out & mmcm_locked ;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_gtwiz_buffbypass_tx #(
    .P_TOTAL_NUMBER_OF_CHANNELS (8),
    .P_MASTER_CHANNEL_POINTER   (P_TX_MASTER_CH_PACKED_IDX)
  ) gtwiz_buffbypass_tx_inst (
    .gtwiz_buffbypass_tx_clk_in        (gtwiz_userclk_tx_usrclk2_out),
    .gtwiz_buffbypass_tx_reset_in      (gtwiz_buffbypass_tx_reset_in),
    .gtwiz_buffbypass_tx_start_user_in (gtwiz_buffbypass_tx_start_user_in),
    .gtwiz_buffbypass_tx_resetdone_in  (gtwiz_buffbypass_tx_resetdone_int),
    .gtwiz_buffbypass_tx_done_out      (gtwiz_buffbypass_tx_done_out),
    .gtwiz_buffbypass_tx_error_out     (gtwiz_buffbypass_tx_error_out),
    .enable_txphydly_cfg_out           (enable_txphydly_cfg_int),
    .txphydly_cfg_done_in              (txphydly_cfg_done_int),
    .enable_txsyncovrd_buf_cfg_out     (enable_txsyncovrd_buf_cfg_int),
    .txsyncovrd_buf_cfg_done_in        (txsyncovrd_buf_cfg_done_int),    
    .txphaligndone_in                  (txphaligndone_int),
    .txphinitdone_in                   (txphinitdone_int),
    .txdlysresetdone_in                (txdlysresetdone_int),
    .txsyncout_in                      (txsyncout_int),
    .txsyncdone_in                     (txsyncdone_int),
    .txphdlyreset_out                  (txphdlyreset_int),
    .txphalign_out                     (txphalign_int),
    .txphalignen_out                   (txphalignen_int),
    .txphdlypd_out                     (txphdlypd_int),
    .txphinit_out                      (txphinit_int),
    .txphovrden_out                    (txphovrden_int),
    .txdlysreset_out                   (txdlysreset_int),
    .txdlybypass_out                   (txdlybypass_int),
    .txdlyen_out                       (txdlyen_int),
    .txdlyovrden_out                   (txdlyovrden_int),
    .txphdlytstclk_out                 (txphdlytstclk_int),
    .txdlyhold_out                     (txdlyhold_int),
    .txdlyupdown_out                   (txdlyupdown_int),
    .txsyncmode_out                    (txsyncmode_int),
    .txsyncallin_out                   (txsyncallin_int),
    .txsyncin_out                      (txsyncin_int)
  );

  // -------------------------------------------------------------------------------------------------------------------
  // Receiver buffer bypass controller helper block
  // -------------------------------------------------------------------------------------------------------------------

  wire [7:0] rxphaligndone_int;
  wire [7:0] rxdlysresetdone_int;
  wire [7:0] rxsyncout_int;
  wire [7:0] rxsyncdone_int;
  wire [7:0] rxphdlyreset_int;
  wire [7:0] rxphalign_int;
  wire [7:0] rxphalignen_int;
  wire [7:0] rxphdlypd_int;
  wire [7:0] rxphovrden_int;
  wire [7:0] rxdlysreset_int;
  wire [7:0] rxdlybypass_int;
  wire [7:0] rxdlyen_int;
  wire [7:0] rxdlyovrden_int;
  wire [7:0] rxsyncmode_int;
  wire [7:0] rxsyncallin_int;
  wire [7:0] rxsyncin_int;

  // Generate a single module instance which uses the designated receiver master channel as the receive buffer bypass
  // master channel, and all other channels as receive buffer bypass slave channels

  // Depending on the number of reset controller helper blocks, either use the single reset done indicator or the
  // logical combination of per-channel reset done indicators as the reset done indicator for use in this block
  wire gtwiz_buffbypass_rx_resetdone_int;

  assign gtwiz_buffbypass_rx_resetdone_int = gtwiz_reset_rx_done_out;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_gtwiz_buffbypass_rx #(
    .P_TOTAL_NUMBER_OF_CHANNELS (8),
    .P_MASTER_CHANNEL_POINTER   (P_RX_MASTER_CH_PACKED_IDX)
  ) gtwiz_buffbypass_rx_inst (
    .gtwiz_buffbypass_rx_clk_in        (gtwiz_userclk_rx_usrclk2_out),
    .gtwiz_buffbypass_rx_reset_in      (gtwiz_buffbypass_rx_reset_in),
    .gtwiz_buffbypass_rx_start_user_in (gtwiz_buffbypass_rx_start_user_in),
    .gtwiz_buffbypass_rx_resetdone_in  (gtwiz_buffbypass_rx_resetdone_int),
    .gtwiz_buffbypass_rx_done_out      (gtwiz_buffbypass_rx_done_out),
    .gtwiz_buffbypass_rx_error_out     (gtwiz_buffbypass_rx_error_out),
    .rxphaligndone_in                  (rxphaligndone_int),
    .rxdlysresetdone_in                (rxdlysresetdone_int),
    .rxsyncout_in                      (rxsyncout_int),
    .rxsyncdone_in                     (rxsyncdone_int),
    .rxphdlyreset_out                  (rxphdlyreset_int),
    .rxphalign_out                     (rxphalign_int),
    .rxphalignen_out                   (rxphalignen_int),
    .rxphdlypd_out                     (rxphdlypd_int),
    .rxphovrden_out                    (rxphovrden_int),
    .rxdlysreset_out                   (rxdlysreset_int),
    .rxdlybypass_out                   (rxdlybypass_int),
    .rxdlyen_out                       (rxdlyen_int),
    .rxdlyovrden_out                   (rxdlyovrden_int),
    .rxsyncmode_out                    (rxsyncmode_int),
    .rxsyncallin_out                   (rxsyncallin_int),
    .rxsyncin_out                      (rxsyncin_int)
  );

  // -------------------------------------------------------------------------------------------------------------------
  // Reset controller helper block
  // -------------------------------------------------------------------------------------------------------------------

  // Generate a single module instance which controls all PLLs and all channels within the core

  // Depending on the number of user clocking network helper blocks, either use the single user clock active indicator
  // or a logical combination of per-channel user clock active indicators as the user clock active indicator for use in
  // this block
  wire gtwiz_reset_userclk_tx_active_int;
  wire gtwiz_reset_userclk_rx_active_int;

  assign gtwiz_reset_userclk_tx_active_int = gtwiz_userclk_tx_active_out;
  assign gtwiz_reset_userclk_rx_active_int = gtwiz_userclk_rx_active_out;

  // Combine the appropriate PLL lock signals such that the reset controller can sense when all PLLs which clock each
  // data direction are locked, regardless of what PLL source is used
  wire gtwiz_reset_plllock_tx_int;
  wire gtwiz_reset_plllock_rx_int;

  wire [1:0] qpll1lock_int;

  assign gtwiz_reset_plllock_tx_int = &qpll1lock_int;
  assign gtwiz_reset_plllock_rx_int = &qpll1lock_int;

  // Combine the power good, reset done, and CDR lock indicators across all channels, per data direction
  wire [7:0] gtpowergood_int;
  wire [7:0] rxcdrlock_int;
  wire [7:0] txresetdone_int;
  wire [7:0] rxresetdone_int;
  wire gtwiz_reset_gtpowergood_int;
  wire gtwiz_reset_rxcdrlock_int;
  wire gtwiz_reset_txresetdone_int;
  wire gtwiz_reset_rxresetdone_int;

  assign gtwiz_reset_gtpowergood_int = &gtpowergood_int;
  assign gtwiz_reset_rxcdrlock_int   = &rxcdrlock_int;

  wire [7:0] txresetdone_sync;
  wire [7:0] rxresetdone_sync;
  genvar gi_ch_xrd;
  generate for (gi_ch_xrd = 0; gi_ch_xrd < 8; gi_ch_xrd = gi_ch_xrd + 1) begin : gen_ch_xrd
    (* DONT_TOUCH = "TRUE" *)
    DLx_phy_example_bit_synchronizer bit_synchronizer_txresetdone_inst (
      .clk_in (gtwiz_reset_clk_freerun_in),
      .i_in   (txresetdone_int[gi_ch_xrd]),
      .o_out  (txresetdone_sync[gi_ch_xrd])
    );
    (* DONT_TOUCH = "TRUE" *)
    DLx_phy_example_bit_synchronizer bit_synchronizer_rxresetdone_inst (
      .clk_in (gtwiz_reset_clk_freerun_in),
      .i_in   (rxresetdone_int[gi_ch_xrd]),
      .o_out  (rxresetdone_sync[gi_ch_xrd])
    );
  end
  endgenerate
  assign gtwiz_reset_txresetdone_int = &txresetdone_sync;
  assign gtwiz_reset_rxresetdone_int = &rxresetdone_sync;

  wire gtwiz_reset_pllreset_tx_int;
  wire gtwiz_reset_txprogdivreset_int;
  wire gtwiz_reset_gttxreset_int;
  wire gtwiz_reset_txuserrdy_int;
  wire gtwiz_reset_pllreset_rx_int;
  wire gtwiz_reset_rxprogdivreset_int;
  wire gtwiz_reset_gtrxreset_int;
  wire gtwiz_reset_rxuserrdy_int;

  // Instantiate the single reset controller
  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_gtwiz_reset gtwiz_reset_inst (
    .gtwiz_reset_clk_freerun_in         (gtwiz_reset_clk_freerun_in),
    .gtwiz_reset_all_in                 (gtwiz_reset_all_in),
    .gtwiz_reset_tx_pll_and_datapath_in (gtwiz_reset_tx_pll_and_datapath_in),
    .gtwiz_reset_tx_datapath_in         (gtwiz_reset_tx_datapath_in),
    .gtwiz_reset_rx_pll_and_datapath_in (gtwiz_reset_rx_pll_and_datapath_in),
    .gtwiz_reset_rx_datapath_in         (gtwiz_reset_rx_datapath_in),
    .gtwiz_reset_rx_cdr_stable_out      (gtwiz_reset_rx_cdr_stable_out),
    .gtwiz_reset_tx_done_out            (gtwiz_reset_tx_done_out),
    .gtwiz_reset_rx_done_out            (gtwiz_reset_rx_done_out),
    .gtwiz_reset_userclk_tx_active_in   (gtwiz_reset_userclk_tx_active_int),
    .gtwiz_reset_userclk_rx_active_in   (gtwiz_reset_userclk_rx_active_int),
    .gtpowergood_in                     (gtwiz_reset_gtpowergood_int),
    .txusrclk2_in                       (gtwiz_userclk_tx_usrclk2_out),
    .plllock_tx_in                      (gtwiz_reset_plllock_tx_int),
    .txresetdone_in                     (gtwiz_reset_txresetdone_int),
    .rxusrclk2_in                       (gtwiz_userclk_rx_usrclk2_out),
    .plllock_rx_in                      (gtwiz_reset_plllock_rx_int),
    .rxcdrlock_in                       (gtwiz_reset_rxcdrlock_int),
    .rxresetdone_in                     (gtwiz_reset_rxresetdone_int),
    .pllreset_tx_out                    (gtwiz_reset_pllreset_tx_int),
    .txprogdivreset_out                 (gtwiz_reset_txprogdivreset_int),
    .gttxreset_out                      (gtwiz_reset_gttxreset_int),
    .txuserrdy_out                      (gtwiz_reset_txuserrdy_int),
    .pllreset_rx_out                    (gtwiz_reset_pllreset_rx_int),
    .rxprogdivreset_out                 (gtwiz_reset_rxprogdivreset_int),
    .gtrxreset_out                      (gtwiz_reset_gtrxreset_int),
    .rxuserrdy_out                      (gtwiz_reset_rxuserrdy_int),
    .tx_enabled_tie_in                  (1'b1),
    .rx_enabled_tie_in                  (1'b1),
    .shared_pll_tie_in                  (1'b1),
    .initial_drp_config_done            (initial_drp_config_done_int),
    .set_initial_drp_config             (set_initial_drp_config_int)     
  );

  // Drive the internal PLL reset inputs with the appropriate PLL reset signals produced by the reset controller. The
  // single reset controller instance generates independent transmit PLL reset and receive PLL reset outputs, which are
  // used across all such PLLs in the core.
  wire [1:0] qpll1reset_int;

  assign qpll1reset_int = {2{gtwiz_reset_pllreset_tx_int || gtwiz_reset_pllreset_rx_int}};

  // Fan out appropriate reset controller outputs to all transceiver channels
  wire [7:0] txprogdivreset_int;
  wire [7:0] gttxreset_int;
  wire [7:0] txuserrdy_int;
  wire [7:0] rxprogdivreset_int;
  wire [7:0] gtrxreset_int;
  wire [7:0] rxuserrdy_int;

  assign txprogdivreset_int  = {8{gtwiz_reset_txprogdivreset_int}};
  assign gttxreset_int       = {8{gtwiz_reset_gttxreset_int}};
  assign txuserrdy_int       = {8{gtwiz_reset_txuserrdy_int}};
  assign rxprogdivreset_int  = {8{gtwiz_reset_rxprogdivreset_int}};
  assign gtrxreset_int       = {8{gtwiz_reset_gtrxreset_int}};
  assign rxuserrdy_int       = {8{gtwiz_reset_rxuserrdy_int}};


  // ===================================================================================================================
  // CORE INSTANCE
  // ===================================================================================================================

  // Instantiate the core, mapping its enabled ports to example design ports and helper blocks as appropriate
  DLx_phy DLx_phy_inst (
    .gtyrxn_in                               (gtyrxn_in)
   ,.gtyrxp_in                               (gtyrxp_in)
   ,.gtytxn_out                              (gtytxn_out)
   ,.gtytxp_out                              (gtytxp_out)
   ,.gtwiz_userclk_tx_active_in              (gtwiz_userclk_tx_active_out)
   ,.gtwiz_userclk_rx_active_in              (gtwiz_userclk_rx_active_out)
   ,.gtwiz_reset_tx_done_in                  (gtwiz_reset_tx_done_out)
   ,.gtwiz_reset_rx_done_in                  (gtwiz_reset_rx_done_out)
   ,.gtwiz_userdata_tx_in                    (gtwiz_userdata_tx_in)
   ,.gtwiz_userdata_rx_out                   (gtwiz_userdata_rx_out)
   ,.gtrefclk01_in                           (gtrefclk01_in)
   ,.qpll1reset_in                           (qpll1reset_int)
   ,.qpll1lock_out                           (qpll1lock_int)
   ,.qpll1outclk_out                         (qpll1outclk_out)
   ,.qpll1outrefclk_out                      (qpll1outrefclk_out)
   ,.drpaddr_in                              (drpaddr_int)
   ,.drpclk_in                               ({8{gtwiz_reset_clk_freerun_in}})
   ,.drpdi_in                                (drpdi_int)
   ,.drpen_in                                (drpen_int)
   ,.drpwe_in                                (drpwe_int)
   ,.eyescanreset_in                         (eyescanreset_int)
   ,.gtrxreset_in                            (gtrxreset_int)
   ,.gttxreset_in                            (gttxreset_int)
   ,.rxdlybypass_in                          (rxdlybypass_int)
   ,.rxdlyen_in                              (rxdlyen_int)
   ,.rxdlyovrden_in                          (rxdlyovrden_int)
   ,.rxdlysreset_in                          (rxdlysreset_int)
   ,.rxgearboxslip_in                        (rxgearboxslip_in)
   ,.rxlpmen_in                              (rxlpmen_in)
   ,.rxphalign_in                            (rxphalign_int)
   ,.rxphalignen_in                          (rxphalignen_int)
   ,.rxphdlypd_in                            (rxphdlypd_int)
   ,.rxphdlyreset_in                         (rxphdlyreset_int)
   ,.rxprogdivreset_in                       (rxprogdivreset_int)
   ,.rxrate_in                               (rxrate_in)
   ,.rxsyncallin_in                          (rxsyncallin_int)
   ,.rxsyncin_in                             (rxsyncin_int)
   ,.rxsyncmode_in                           (rxsyncmode_int)
   ,.rxuserrdy_in                            (rxuserrdy_int)
   ,.rxusrclk_in                             (rxusrclk_int)
   ,.rxusrclk2_in                            (rxusrclk2_int)
   ,.txdiffctrl_in                           (txdiffctrl_in)
   ,.txdlybypass_in                          (txdlybypass_int)
   ,.txdlyen_in                              (txdlyen_int)
   ,.txdlyhold_in                            (txdlyhold_int)
   ,.txdlyovrden_in                          (txdlyovrden_int)
   ,.txdlysreset_in                          (txdlysreset_int)
   ,.txdlyupdown_in                          (txdlyupdown_int)
   ,.txheader_in                             (txheader_in)
   ,.txphalign_in                            (txphalign_int)
   ,.txphalignen_in                          (txphalignen_int)
   ,.txphdlypd_in                            (txphdlypd_int)
   ,.txphdlyreset_in                         (txphdlyreset_int)
   ,.txphdlytstclk_in                        (txphdlytstclk_int)
   ,.txphinit_in                             (txphinit_int)
   ,.txphovrden_in                           (txphovrden_int)
   ,.txpostcursor_in                         (txpostcursor_in)
   ,.txprecursor_in                          (txprecursor_in)
   ,.txprogdivreset_in                       (txprogdivreset_int)
   ,.txsequence_in                           (txsequence_in)
   ,.txsyncallin_in                          (txsyncallin_int)
   ,.txsyncin_in                             (txsyncin_int)
   ,.txsyncmode_in                           (txsyncmode_int)
   ,.txuserrdy_in                            (txuserrdy_int)
   ,.txusrclk_in                             (txusrclk_int)
   ,.txusrclk2_in                            (txusrclk2_int)
   ,.drpdo_out                               (drpdo_int)
   ,.drprdy_out                              (drprdy_int)
   ,.gtpowergood_out                         (gtpowergood_int)
   ,.rxcdrlock_out                           (rxcdrlock_int)
   ,.rxdatavalid_out                         (rxdatavalid_out)
   ,.rxdlysresetdone_out                     (rxdlysresetdone_int)
   ,.rxheader_out                            (rxheader_out)
   ,.rxheadervalid_out                       (rxheadervalid_out)
   ,.rxoutclk_out                            (rxoutclk_int)
   ,.rxphaligndone_out                       (rxphaligndone_int)
   ,.rxpmaresetdone_out                      (rxpmaresetdone_out)
   ,.rxresetdone_out                         (rxresetdone_int)
   ,.rxstartofseq_out                        (rxstartofseq_out)
   ,.rxsyncdone_out                          (rxsyncdone_int)
   ,.rxsyncout_out                           (rxsyncout_int)
   ,.txdlysresetdone_out                     (txdlysresetdone_int)
   ,.txoutclk_out                            (txoutclk_int)
   ,.txphaligndone_out                       (txphaligndone_int)
   ,.txphinitdone_out                        (txphinitdone_int)
   ,.txpmaresetdone_out                      (txpmaresetdone_out)
   ,.txprgdivresetdone_out                   (txprgdivresetdone_out)
   ,.txresetdone_out                         (txresetdone_int)
   ,.txsyncdone_out                          (txsyncdone_int)
   ,.txsyncout_out                           (txsyncout_int)
);

endmodule
