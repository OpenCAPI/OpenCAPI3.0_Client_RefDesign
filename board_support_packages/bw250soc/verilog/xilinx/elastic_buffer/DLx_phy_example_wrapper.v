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

module  DLx_phy_example_wrapper (
  input  wire [7:0] gtyrxn_in
 ,input  wire [7:0] gtyrxp_in
 ,output wire [7:0] gtytxn_out
 ,output wire [7:0] gtytxp_out
 ,input  wire [0:0] gtwiz_userclk_tx_reset_in
 ,output wire [0:0] gtwiz_userclk_tx_srcclk_out
 ,output wire [0:0] gtwiz_userclk_tx_usrclk_out
 ,output wire [0:0] gtwiz_userclk_tx_usrclk2_out
 ,output wire [0:0] gtwiz_userclk_tx_usrclk3_out  // -- joek added for 201MHz support
 ,output wire [0:0] gtwiz_userclk_tx_active_out
 ,input  wire [0:0] gtwiz_userclk_rx_reset_in
 ,output wire [0:0] gtwiz_userclk_rx_srcclk_out
//-- jda 5/17 ,output wire [0:0] gtwiz_userclk_rx_usrclk_out
//-- jda 5/17 ,output wire [0:0] gtwiz_userclk_rx_usrclk2_out
 ,output wire [0:0] gtwiz_userclk_rx_active_out
// ,input  wire [0:0] gtwiz_buffbypass_tx_reset_in
// ,input  wire [0:0] gtwiz_buffbypass_tx_start_user_in
// ,output wire [0:0] gtwiz_buffbypass_tx_done_out
// ,output wire [0:0] gtwiz_buffbypass_tx_error_out
// ,input  wire [0:0] gtwiz_buffbypass_rx_reset_in
// ,input  wire [0:0] gtwiz_buffbypass_rx_start_user_in
// ,output wire [0:0] gtwiz_buffbypass_rx_done_out
// ,output wire [0:0] gtwiz_buffbypass_rx_error_out
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
 ,input  wire [79:0] drpaddr_in
 ,input  wire [7:0] drpclk_in
 ,input  wire [127:0] drpdi_in
 ,input  wire [7:0] drpen_in
 ,input  wire [7:0] drpwe_in
 ,input  wire [7:0] eyescanreset_in
 ,input  wire [7:0] rxgearboxslip_in
 ,input  wire [7:0] rxlpmen_in
 ,input  wire [7:0] rxpolarity_in 
 ,input  wire [23:0] rxrate_in
 ,input  wire [39:0] txdiffctrl_in
 ,input  wire [47:0] txheader_in
 ,input  wire [39:0] txpostcursor_in
 ,input  wire [39:0] txprecursor_in
 ,input  wire [55:0] txsequence_in
 ,output wire [127:0] drpdo_out
 ,output wire [7:0] drprdy_out
 ,output wire [15:0] rxdatavalid_out
 ,output wire [47:0] rxheader_out
 ,output wire [15:0] rxheadervalid_out
 ,output wire [7:0] rxpmaresetdone_out
 ,output wire [15:0] rxstartofseq_out
 ,output wire [7:0] txpmaresetdone_out
 //,output wire [7:0] txprgdivresetdone_out
 //,output wire [23:0] rxbufstatus_out
 //,input  wire [7:0] rxbufreset_in 
);


  // ===================================================================================================================
  // PARAMETERS AND FUNCTIONS
  // ===================================================================================================================
/*
  // Declare and initialize local parameters and functions used for HDL generation
  localparam [191:0] P_CHANNEL_ENABLE = 192'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111;
  `include "DLx_phy_example_wrapper_functions.v"
  localparam integer P_TX_MASTER_CH_PACKED_IDX = f_calc_pk_mc_idx(3);
  localparam integer P_RX_MASTER_CH_PACKED_IDX = f_calc_pk_mc_idx(3);
*/

  // Declare and initialize local parameters and functions used for HDL generation
  localparam [191:0] P_CHANNEL_ENABLE = 192'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111000000000000;
  `include "DLx_phy_example_wrapper_functions.v"
  localparam integer P_TX_MASTER_CH_PACKED_IDX = f_calc_pk_mc_idx(16);
  localparam integer P_RX_MASTER_CH_PACKED_IDX = f_calc_pk_mc_idx(16);


  // ===================================================================================================================
  // HELPER BLOCKS
  // ===================================================================================================================

  // Any helper blocks which the user chose to exclude from the core will appear below. In addition, some signal
  // assignments related to optionally-enabled ports may appear below.

  // --------------------------------------------gtwiz_userclk_rx_usrclk2_out-----------------------------------------------------------------------
  // Transmitter user clocking network helper block
  // -------------------------------------------------------------------------------------------------------------------

  wire [7:0] txusrclk_int;
  wire [7:0] txusrclk2_int;
  wire [7:0] txoutclk_int;
  wire gtwiz_userclk_tx_active_int;

  // Generate a single module instance which is driven by a clock source associated with the master transmitter channel,
  // and which drives TXUSRCLK and TXUSRCLK2 for all channels

  // The source clock is TXOUTCLK from the master transmitter channel
  assign gtwiz_userclk_tx_srcclk_out = txoutclk_int[P_TX_MASTER_CH_PACKED_IDX];

  // Instantiate a single instance of the transmitter user clocking network helper block
  DLx_phy_example_gtwiz_userclk_tx gtwiz_userclk_tx_inst  (
    .gtwiz_userclk_tx_srcclk_in   (gtwiz_userclk_tx_srcclk_out),
    .gtwiz_userclk_tx_reset_in    (gtwiz_userclk_tx_reset_in),
    .gtwiz_userclk_tx_usrclk_out  (gtwiz_userclk_tx_usrclk_out),
    .gtwiz_userclk_tx_usrclk2_out (gtwiz_userclk_tx_usrclk2_out),
    .gtwiz_userclk_tx_usrclk3_out (gtwiz_userclk_tx_usrclk3_out),   // -- joek added for 201MHz support
    .gtwiz_userclk_tx_active_out  (gtwiz_userclk_tx_active_int)
  );

  // Drive TXUSRCLK and TXUSRCLK2 for all channels with the respective helper block outputs
  assign txusrclk_int  = {8{gtwiz_userclk_tx_usrclk_out}};
  assign txusrclk2_int = {8{gtwiz_userclk_tx_usrclk2_out}};
  assign gtwiz_userclk_tx_active_out = gtwiz_userclk_tx_active_int;

  // -------------------------------------------------------------------------------------------------------------------
  // Receiver user clocking network helper block
  // -------------------------------------------------------------------------------------------------------------------

  wire [7:0] rxusrclk_int;
  wire [7:0] rxusrclk2_int;
  wire [7:0] rxoutclk_int;

  // Generate a single module instance which is driven by a clock source associated with the master receiver channel,
  // and which drives RXUSRCLK and RXUSRCLK2 for all channels

  // The source clock is RXOUTCLK from the master receiver channel
  //assign gtwiz_userclk_rx_srcclk_out = rxoutclk_int[P_RX_MASTER_CH_PACKED_IDX];
  assign gtwiz_userclk_rx_srcclk_out = txoutclk_int[P_RX_MASTER_CH_PACKED_IDX];
  
  // Instantiate a single instance of the receiver user clocking network helper block
  /*
  gty_25gx8_core_example_gtwiz_userclk_rx gtwiz_userclk_rx_inst (
    .gtwiz_userclk_rx_srcclk_in   (gtwiz_userclk_rx_srcclk_out),
    .gtwiz_userclk_rx_reset_in    (gtwiz_userclk_rx_reset_in),
    .gtwiz_userclk_rx_usrclk_out  (gtwiz_userclk_rx_usrclk_out),
    .gtwiz_userclk_rx_usrclk2_out (gtwiz_userclk_rx_usrclk2_out),
    .gtwiz_userclk_rx_active_out  (gtwiz_userclk_rx_active_out)
  );
  */

  // Drive RXUSRCLK and RXUSRCLK2 for all channels with the respective helper block outputs
  /*
  assign rxusrclk_int  = {8{gtwiz_userclk_rx_usrclk_out}};
  assign rxusrclk2_int = {8{gtwiz_userclk_rx_usrclk2_out}};
  */
  assign rxusrclk_int  = {8{1'b0}}; 
  assign rxusrclk2_int = {8{1'b0}}; 
  assign gtwiz_userclk_rx_active_out = gtwiz_userclk_tx_active_int;
  
  // -------------------------------------------------------------------------------------------------------------------
  // Transmitter buffer bypass controller helper block
  // -------------------------------------------------------------------------------------------------------------------
  wire gtwiz_buffbypass_tx_resetdone_int;

  assign gtwiz_buffbypass_tx_resetdone_int = gtwiz_reset_tx_done_out;
  
  wire gtwiz_buffbypass_rx_resetdone_int;

  assign gtwiz_buffbypass_rx_resetdone_int = gtwiz_reset_rx_done_out;
  
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
  

  // Generate a single module instance which uses the designated transmitter master channel as the transmit buffer
  // bypass master channel, and all other channels as transmit buffer bypass slave channels

  // Depending on the number of reset controller helper blocks, either use the single reset done indicator or the
  // logical combination of per-channel reset done indicators as the reset done indicator for use in this block

  
/*  (* DONT_TOUCH = "TRUE" *)
    rxtx_shared_clk_buffbypass #(
    .P_TOTAL_NUMBER_OF_CHANNELS (8),
    .P_MASTER_CHANNEL_POINTER   (P_TX_MASTER_CH_PACKED_IDX)
  ) rxtx_shared_clk_buffbypass_inst (
     //TX
    .gtwiz_buffbypass_tx_master_clk_in (gtwiz_userclk_tx_usrclk2_out),
    .gtwiz_buffbypass_tx_reset_in      (gtwiz_buffbypass_tx_reset_in),
    .gtwiz_buffbypass_tx_start_user_in (gtwiz_buffbypass_tx_start_user_in),
    .gtwiz_buffbypass_tx_resetdone_in  (gtwiz_buffbypass_tx_resetdone_int),
    .gtwiz_buffbypass_tx_done_out      (gtwiz_buffbypass_tx_done_out),
    .gtwiz_buffbypass_tx_error_out     (gtwiz_buffbypass_tx_error_out),
    //RX
    .gtwiz_buffbypass_rx_reset_in      (gtwiz_buffbypass_rx_reset_in),
    .gtwiz_buffbypass_rx_start_user_in (gtwiz_buffbypass_rx_start_user_in),
    .gtwiz_buffbypass_rx_resetdone_in  (gtwiz_buffbypass_rx_resetdone_int),
    .gtwiz_buffbypass_rx_done_out      (gtwiz_buffbypass_rx_done_out),
    .gtwiz_buffbypass_rx_error_out     (gtwiz_buffbypass_rx_error_out),    
     //TX
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
    .txsyncin_out                      (txsyncin_int),
     //RX
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
  );  */             
/*  
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
 */ 
  // -------------------------------------------------------------------------------------------------------------------
  // Receiver buffer bypass controller helper block
  // -------------------------------------------------------------------------------------------------------------------


  // Generate a single module instance which uses the designated receiver master channel as the receive buffer bypass
  // master channel, and all other channels as receive buffer bypass slave channels

  // Depending on the number of reset controller helper blocks, either use the single reset done indicator or the
  // logical combination of per-channel reset done indicators as the reset done indicator for use in this block

/*
  
  (* DONT_TOUCH = "TRUE" *)
   DLx_phy_example_gtwiz_buffbypass_rx #(
    .P_TOTAL_NUMBER_OF_CHANNELS (8),
    .P_MASTER_CHANNEL_POINTER   (P_RX_MASTER_CH_PACKED_IDX)
  ) gtwiz_buffbypass_rx_inst (
    //.gtwiz_buffbypass_rx_clk_in        (gtwiz_userclk_rx_usrclk2_out),
    .gtwiz_buffbypass_rx_clk_in        (gtwiz_userclk_tx_usrclk2_out),
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
 */ 

  // ===================================================================================================================
  // CORE INSTANCE
  // ===================================================================================================================
 wire [7:0] txprgdivresetdone_out; //-- jda 8/22 get rid of ncsim error
 wire [7:0] gtpowergood_out; 
 DLx_phy DLx_phy_inst (
     .gtyrxn_in                               (gtyrxn_in)
    ,.gtyrxp_in                               (gtyrxp_in)
    ,.gtytxn_out                              (gtytxn_out)
    ,.gtytxp_out                              (gtytxp_out)
    ,.gtwiz_userclk_tx_active_in              (gtwiz_userclk_tx_active_out)
    ,.gtpowergood_out                         (gtpowergood_out)               // output wire [7 : 0] gtpowergood_out
    //,.gtwiz_userclk_rx_active_in              (gtwiz_userclk_rx_active_out)
    ,.gtwiz_userclk_rx_active_in              (gtwiz_userclk_tx_active_int)   
    ,.gtwiz_reset_clk_freerun_in              (gtwiz_reset_clk_freerun_in)
    ,.gtwiz_reset_all_in                      (gtwiz_reset_all_in)
    ,.gtwiz_reset_tx_pll_and_datapath_in      (gtwiz_reset_tx_pll_and_datapath_in)
    ,.gtwiz_reset_tx_datapath_in              (gtwiz_reset_tx_datapath_in)
    ,.gtwiz_reset_rx_pll_and_datapath_in      (gtwiz_reset_rx_pll_and_datapath_in)
    ,.gtwiz_reset_rx_datapath_in              (gtwiz_reset_rx_datapath_in)
    ,.gtwiz_reset_rx_cdr_stable_out           (gtwiz_reset_rx_cdr_stable_out)
    ,.gtwiz_reset_tx_done_out                 (gtwiz_reset_tx_done_out)
    ,.gtwiz_reset_rx_done_out                 (gtwiz_reset_rx_done_out)
    ,.gtwiz_userdata_tx_in                    (gtwiz_userdata_tx_in)
    ,.gtwiz_userdata_rx_out                   (gtwiz_userdata_rx_out)
    ,.gtrefclk01_in                           (gtrefclk01_in)
    ,.qpll1outclk_out                         (qpll1outclk_out)
    ,.qpll1outrefclk_out                      (qpll1outrefclk_out)
    ,.drpaddr_in                              (drpaddr_in)
    ,.drpclk_in                               (drpclk_in)
    ,.drpdi_in                                (drpdi_in)
    ,.drpen_in                                (drpen_in)
    ,.drpwe_in                                (drpwe_in)
    ,.eyescanreset_in                         (eyescanreset_in)
    ,.rxgearboxslip_in                        (rxgearboxslip_in)
    ,.rxlpmen_in                              (rxlpmen_in)
    ,.rxrate_in                               (rxrate_in)
    //,.rxusrclk_in                             (rxusrclk_int)
    //,.rxusrclk2_in                            (rxusrclk2_int)
    ,.rxusrclk_in                             (txusrclk_int) 
    ,.rxusrclk2_in                            (txusrclk2_int)
    ,.txdiffctrl_in                           (txdiffctrl_in)
    ,.txheader_in                             (txheader_in)
    ,.txpostcursor_in                         (txpostcursor_in)
    ,.txprecursor_in                          (txprecursor_in)
    ,.txsequence_in                           (txsequence_in)
    ,.txusrclk_in                             (txusrclk_int)
    ,.txusrclk2_in                            (txusrclk2_int)
    ,.drpdo_out                               (drpdo_out)
    ,.drprdy_out                              (drprdy_out)
    ,.rxdatavalid_out                         (rxdatavalid_out)
    ,.rxheader_out                            (rxheader_out)
    ,.rxheadervalid_out                       (rxheadervalid_out)
    ,.rxoutclk_out                            (rxoutclk_int)
    ,.rxpmaresetdone_out                      (rxpmaresetdone_out)
    ,.rxstartofseq_out                        (rxstartofseq_out)
    ,.txoutclk_out                            (txoutclk_int)
    ,.txpmaresetdone_out                      (txpmaresetdone_out)
    ,.rxpolarity_in                           (rxpolarity_in) 
    
  //,.loopback_in                             (loopback_in)   
  //,.rxbufreset_in                           (rxbufreset_in)        
  //,.rxbufstatus_out                         (rxbufstatus_out)    
  // ,.rxprgdivresetdone_out                   (rxprgdivresetdone_out)    
    ,.txprgdivresetdone_out                   (txprgdivresetdone_out)   //-- jda 8/22 get rid of ncsim error
 //   ,.txdlybypass_in                          (txdlybypass_int)
 //   ,.txdlyen_in                              (txdlyen_int)
 //   ,.txdlyhold_in                            (txdlyhold_int)
 //   ,.txdlyovrden_in                          (txdlyovrden_int)
 //   ,.txdlysreset_in                          (txdlysreset_int)
 //   ,.txdlyupdown_in                          (txdlyupdown_int)
 //   ,.txphalign_in                            (txphalign_int)
 //   ,.txphalignen_in                          (txphalignen_int)
 //   ,.txphdlypd_in                            (txphdlypd_int)
 //   ,.txphdlyreset_in                         (txphdlyreset_int)
 //   ,.txphdlytstclk_in                        (txphdlytstclk_int)
 //   ,.txphinit_in                             (txphinit_int)
 //   ,.txsyncallin_in                          (txsyncallin_int)
 //   ,.txsyncin_in                             (txsyncin_int)
 //   ,.txsyncmode_in                           (txsyncmode_int)
 //   ,.txdlysresetdone_out                     (txdlysresetdone_int)
 //   ,.txphaligndone_out                       (txphaligndone_int)
 //   ,.txphinitdone_out                        (txphinitdone_int)
 //   ,.txsyncdone_out                          (txsyncdone_int)
 //   ,.txsyncout_out                           (txsyncout_int)               
 );  
  
/*
  // Instantiate the core, mapping its enabled ports to example design ports and helper blocks as appropriate
  DLx_phy DLx_phy_inst (
    .gtyrxn_in                               (gtyrxn_in)
   ,.gtyrxp_in                               (gtyrxp_in)
   ,.gtytxn_out                              (gtytxn_out)
   ,.gtytxp_out                              (gtytxp_out)
   ,.gtwiz_userclk_tx_active_in              (gtwiz_userclk_tx_active_out)
   //,.gtwiz_userclk_rx_active_in              (gtwiz_userclk_rx_active_out)
   // use tx_active_out
   ,.gtwiz_userclk_rx_active_in              (gtwiz_userclk_tx_active_int)
   ,.gtwiz_reset_clk_freerun_in              (gtwiz_reset_clk_freerun_in)
   ,.gtwiz_reset_all_in                      (gtwiz_reset_all_in)
   ,.gtwiz_reset_tx_pll_and_datapath_in      (gtwiz_reset_tx_pll_and_datapath_in)
   ,.gtwiz_reset_tx_datapath_in              (gtwiz_reset_tx_datapath_in)
   ,.gtwiz_reset_rx_pll_and_datapath_in      (gtwiz_reset_rx_pll_and_datapath_in)
   ,.gtwiz_reset_rx_datapath_in              (gtwiz_reset_rx_datapath_in)
   ,.gtwiz_reset_rx_cdr_stable_out           (gtwiz_reset_rx_cdr_stable_out)
   ,.gtwiz_reset_tx_done_out                 (gtwiz_reset_tx_done_out)
   ,.gtwiz_reset_rx_done_out                 (gtwiz_reset_rx_done_out)
   ,.gtwiz_userdata_tx_in                    (gtwiz_userdata_tx_in)
   ,.gtwiz_userdata_rx_out                   (gtwiz_userdata_rx_out)
   ,.gtrefclk01_in                           (gtrefclk01_in)
   ,.qpll1outclk_out                         (qpll1outclk_out)
   ,.qpll1outrefclk_out                      (qpll1outrefclk_out)
   ,.drpaddr_in                              (drpaddr_in)
   ,.drpclk_in                               (drpclk_in)
   ,.drpdi_in                                (drpdi_in)
   ,.drpen_in                                (drpen_in)
   ,.drpwe_in                                (drpwe_in)
   ,.eyescanreset_in                         (eyescanreset_in)
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
   ,.rxpolarity_in                           (rxpolarity_in)   
   ,.rxrate_in                               (rxrate_in)
   ,.rxsyncallin_in                          (rxsyncallin_int)
   ,.rxsyncin_in                             (rxsyncin_int)
   ,.rxsyncmode_in                           (rxsyncmode_int)
   //,.rxusrclk2_in                            (rxusrclk2_int)
   //,.rxusrclk_in                             (rxusrclk_int)   
   ,.rxusrclk_in                             (txusrclk_int)
   ,.rxusrclk2_in                            (txusrclk2_int)   
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
   ,.txsequence_in                           (txsequence_in)
   ,.txsyncallin_in                          (txsyncallin_int)
   ,.txsyncin_in                             (txsyncin_int)
   ,.txsyncmode_in                           (txsyncmode_int)
   ,.txusrclk_in                             (txusrclk_int)
   ,.txusrclk2_in                            (txusrclk2_int)
   ,.drpdo_out                               (drpdo_out)
   ,.drprdy_out                              (drprdy_out)
   ,.rxdatavalid_out                         (rxdatavalid_out)
   ,.rxdlysresetdone_out                     (rxdlysresetdone_int)
   ,.rxheader_out                            (rxheader_out)
   ,.rxheadervalid_out                       (rxheadervalid_out)
   ,.rxoutclk_out                            (rxoutclk_int)
   ,.rxphaligndone_out                       (rxphaligndone_int)
   ,.rxpmaresetdone_out                      (rxpmaresetdone_out)
   ,.rxstartofseq_out                        (rxstartofseq_out)
   ,.rxsyncdone_out                          (rxsyncdone_int)
   ,.rxsyncout_out                           (rxsyncout_int)
   ,.txdlysresetdone_out                     (txdlysresetdone_int)
   ,.txoutclk_out                            (txoutclk_int)
   ,.txphaligndone_out                       (txphaligndone_int)
   ,.txphinitdone_out                        (txphinitdone_int)
   ,.txpmaresetdone_out                      (txpmaresetdone_out)
   ,.txprgdivresetdone_out                   (txprgdivresetdone_out)
   ,.txsyncdone_out                          (txsyncdone_int)
   ,.txsyncout_out                           (txsyncout_int)
);
*/

endmodule
