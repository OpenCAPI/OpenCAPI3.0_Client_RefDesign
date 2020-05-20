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
// This example design top module instantiates the example design wrapper; slices vectored ports for per-channel
// assignment; and instantiates example resources such as buffers, pattern generators, and pattern checkers for core
// demonstration purposes
// =====================================================================================================================

module dlx_phy_wrap
(

  // Differential reference clock inputs
  input  wire mgtrefclk1_x0y0_p,
  input  wire mgtrefclk1_x0y0_n,
  input  wire mgtrefclk1_x0y1_p,
  input  wire mgtrefclk1_x0y1_n,
  
  input  wire freerun_clk_p,
  input  wire freerun_clk_n,


  // Serial data ports for transceiver channel 0
  input  wire ch0_gtyrxn_in,
  input  wire ch0_gtyrxp_in,
  output wire ch0_gtytxn_out,
  output wire ch0_gtytxp_out,

  // Serial data ports for transceiver channel 1
  input  wire ch1_gtyrxn_in,
  input  wire ch1_gtyrxp_in,
  output wire ch1_gtytxn_out,
  output wire ch1_gtytxp_out,

  // Serial data ports for transceiver channel 2
  input  wire ch2_gtyrxn_in,
  input  wire ch2_gtyrxp_in,
  output wire ch2_gtytxn_out,
  output wire ch2_gtytxp_out,

  // Serial data ports for transceiver channel 3
  input  wire ch3_gtyrxn_in,
  input  wire ch3_gtyrxp_in,
  output wire ch3_gtytxn_out,
  output wire ch3_gtytxp_out,

  // Serial data ports for transceiver channel 4
  input  wire ch4_gtyrxn_in,
  input  wire ch4_gtyrxp_in,
  output wire ch4_gtytxn_out,
  output wire ch4_gtytxp_out,

  // Serial data ports for transceiver channel 5
  input  wire ch5_gtyrxn_in,
  input  wire ch5_gtyrxp_in,
  output wire ch5_gtytxn_out,
  output wire ch5_gtytxp_out,

  // Serial data ports for transceiver channel 6
  input  wire ch6_gtyrxn_in,
  input  wire ch6_gtyrxp_in,
  output wire ch6_gtytxn_out,
  output wire ch6_gtytxp_out,

  // Serial data ports for transceiver channel 7
  input  wire ch7_gtyrxn_in,
  input  wire ch7_gtyrxp_in,
  output wire ch7_gtytxn_out,
  output wire ch7_gtytxp_out,

  // output       hb0_gtwiz_userclk_rx_usrclk2_int,
  output       hb_gtwiz_reset_clk_freerun_buf_int,
  output       init_done_int,
  output [3:0] init_retry_ctr_int,
  output [0:0] gtwiz_reset_tx_done_vio_sync,
  output [0:0] gtwiz_reset_rx_done_vio_sync,
  output [0:0] gtwiz_buffbypass_tx_done_vio_sync,
  output [0:0] gtwiz_buffbypass_rx_done_vio_sync,
  output [0:0] gtwiz_buffbypass_tx_error_vio_sync,
  output [0:0] gtwiz_buffbypass_rx_error_vio_sync,
  input  [0:0] hb_gtwiz_reset_all_vio_int,
  input  [0:0] hb0_gtwiz_reset_tx_pll_and_datapath_int,
  input  [0:0] hb0_gtwiz_reset_tx_datapath_int,
  input  [0:0] hb_gtwiz_reset_rx_pll_and_datapath_vio_int,
  input  [0:0] hb_gtwiz_reset_rx_datapath_vio_int,
  
  
  // --@ Josh Andersen added port declarations to interface with DLx drivers
  output wire [31:0]   dlx_config_info,
  output wire [31:0]   ro_dlx_version,
  output wire [2:0]    dlx_tlx_init_flit_depth, 
  output wire [511:0]  dlx_tlx_flit,            
  output wire          dlx_tlx_flit_crc_err,    
  output wire          dlx_tlx_flit_credit,     
  output wire          dlx_tlx_flit_valid,      
  output wire          dlx_tlx_link_up,                
  input  wire [3:0]    tlx_dlx_debug_encode,    
  input  wire [31:0]   tlx_dlx_debug_info,      
  input  wire [511:0]  tlx_dlx_flit,            
  input  wire          tlx_dlx_flit_valid,      
  input  wire          send_first,
  input  wire          ocde,
  output wire          tx_clk_402MHz,
  output wire          tx_clk_201MHz,

  
  // IBERT Logic
//--  input  [79:0]  drpaddr_in,
//--  input  [7:0]   drpclk_in,
//--  input  [127:0] drpdi_in,
//--  input  [7:0]   drpen_in,
//--  input  [7:0]   drpwe_in,
//--  input  [7:0]   eyescanreset_in, 
  input  [7:0]   rxlpmen_in,
  input  [23:0]  rxrate_in,
  input  [39:0]  txdiffctrl_in,
  input  [39:0]  txpostcursor_in,
  input  [39:0]  txprecursor_in    
//--  output [127:0] drpdo_out, 
//--  output [7:0]   drprdy_out
  
);

  //-- wire [79:0]  drpaddr_in;      // jda 02/20/17
  //-- wire [7:0]   drpclk_in;       // jda 02/20/17
  //-- wire [127:0] drpdi_in;        // jda 02/20/17
  //-- wire [7:0]   drpen_in;        // jda 02/20/17
  //-- wire [7:0]   drpwe_in;        // jda 02/20/17
  //-- wire [7:0]   eyescanreset_in; // jda 02/20/17
  //-- wire [7:0]   rxlpmen_in;      // jda 02/20/17
  //-- wire [23:0]  rxrate_in;       // jda 02/20/17
  //-- wire [39:0]  txdiffctrl_in;   // jda 02/20/17
  //-- wire [39:0]  txpostcursor_in; // jda 02/20/17
  //-- wire [39:0]  txprecursor_in;  // jda 02/20/17
  //-- wire [127:0] drpdo_out;       // jda 02/20/17
  //-- wire [7:0]   drprdy_out;      // jda 02/20/17
  
  //-- assign rxlpmen_in      = {8{1'b1}};      // DFE OFF            
  //-- assign txpostcursor_in = {8{5'b00000}};  // no postcursor
  //-- assign txprecursor_in  = {8{5'b00000}};  // no precursor 
  //-- assign txdiffctrl_in   = {8{5'b10010}};  // 720 mV       
  //-- assign rxrate_int       = {8{3'b000}};                      
  //-- // transceiver DRP port tie off       
  //-- assign drpen_in        = {8{1'b0}};            
  //-- assign drpwe_in        = {8{1'b0}};            
  //-- assign drpaddr_in      = {8{10'b0000000000}};    
  //-- assign drpclk_in       = {8{1'b0}};            
  //-- assign drpdi_in        = {8{16'h0000}};     
  //-- // eyescan control tie offs
  //-- assign eyescanreset_in = {8{1'b0}}; 

  // ===================================================================================================================
  // PER-CHANNEL SIGNAL ASSIGNMENTS
  // ===================================================================================================================

  // The core and example design wrapper vectorize ports across all enabled transceiver channel and common instances for
  // simplicity and compactness. This example design top module assigns slices of each vector to individual, per-channel
  // signal vectors for use if desired. Signals which connect to helper blocks are prefixed "hb#", signals which connect
  // to transceiver common primitives are prefixed "cm#", and signals which connect to transceiver channel primitives
  // are prefixed "ch#", where "#" is the sequential resource number.

  //--------------------------------------------------------------------------------------------------------------------
  wire [7:0] gtyrxn_int;
  assign gtyrxn_int[0:0] = ch0_gtyrxn_in;
  assign gtyrxn_int[1:1] = ch1_gtyrxn_in;
  assign gtyrxn_int[2:2] = ch2_gtyrxn_in;
  assign gtyrxn_int[3:3] = ch3_gtyrxn_in;
  assign gtyrxn_int[4:4] = ch4_gtyrxn_in;
  assign gtyrxn_int[5:5] = ch5_gtyrxn_in;
  assign gtyrxn_int[6:6] = ch6_gtyrxn_in;
  assign gtyrxn_int[7:7] = ch7_gtyrxn_in;

  //--------------------------------------------------------------------------------------------------------------------
  wire [7:0] gtyrxp_int;
  assign gtyrxp_int[0:0] = ch0_gtyrxp_in;
  assign gtyrxp_int[1:1] = ch1_gtyrxp_in;
  assign gtyrxp_int[2:2] = ch2_gtyrxp_in;
  assign gtyrxp_int[3:3] = ch3_gtyrxp_in;
  assign gtyrxp_int[4:4] = ch4_gtyrxp_in;
  assign gtyrxp_int[5:5] = ch5_gtyrxp_in;
  assign gtyrxp_int[6:6] = ch6_gtyrxp_in;
  assign gtyrxp_int[7:7] = ch7_gtyrxp_in;

  //--------------------------------------------------------------------------------------------------------------------
  wire [7:0] gtytxn_int;
  assign ch0_gtytxn_out = gtytxn_int[0:0];
  assign ch1_gtytxn_out = gtytxn_int[1:1];
  assign ch2_gtytxn_out = gtytxn_int[2:2];
  assign ch3_gtytxn_out = gtytxn_int[3:3];
  assign ch4_gtytxn_out = gtytxn_int[4:4];
  assign ch5_gtytxn_out = gtytxn_int[5:5];
  assign ch6_gtytxn_out = gtytxn_int[6:6];
  assign ch7_gtytxn_out = gtytxn_int[7:7];

  //--------------------------------------------------------------------------------------------------------------------
  wire [7:0] gtytxp_int;
  assign ch0_gtytxp_out = gtytxp_int[0:0];
  assign ch1_gtytxp_out = gtytxp_int[1:1];
  assign ch2_gtytxp_out = gtytxp_int[2:2];
  assign ch3_gtytxp_out = gtytxp_int[3:3];
  assign ch4_gtytxp_out = gtytxp_int[4:4];
  assign ch5_gtytxp_out = gtytxp_int[5:5];
  assign ch6_gtytxp_out = gtytxp_int[6:6];
  assign ch7_gtytxp_out = gtytxp_int[7:7];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_tx_reset_int;
  wire [0:0] hb0_gtwiz_userclk_tx_reset_int;
  assign gtwiz_userclk_tx_reset_int[0:0] = hb0_gtwiz_userclk_tx_reset_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_tx_srcclk_int;
  wire [0:0] hb0_gtwiz_userclk_tx_srcclk_int;
  assign hb0_gtwiz_userclk_tx_srcclk_int = gtwiz_userclk_tx_srcclk_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_tx_usrclk_int;
  wire [0:0] hb0_gtwiz_userclk_tx_usrclk_int;
  assign hb0_gtwiz_userclk_tx_usrclk_int = gtwiz_userclk_tx_usrclk_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_tx_usrclk2_int;
  wire [0:0] hb0_gtwiz_userclk_tx_usrclk2_int;
  assign hb0_gtwiz_userclk_tx_usrclk2_int = gtwiz_userclk_tx_usrclk2_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_tx_active_int;
  wire [0:0] hb0_gtwiz_userclk_tx_active_int;
  assign hb0_gtwiz_userclk_tx_active_int = gtwiz_userclk_tx_active_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_rx_reset_int;
  wire [0:0] hb0_gtwiz_userclk_rx_reset_int;
  assign gtwiz_userclk_rx_reset_int[0:0] = hb0_gtwiz_userclk_rx_reset_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_rx_srcclk_int;
  wire [0:0] hb0_gtwiz_userclk_rx_srcclk_int;
  assign hb0_gtwiz_userclk_rx_srcclk_int = gtwiz_userclk_rx_srcclk_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
//-- jda 5/17  wire [0:0] gtwiz_userclk_rx_usrclk_int;
//-- jda 5/17  wire [0:0] hb0_gtwiz_userclk_rx_usrclk_int;
//-- jda 5/17  assign hb0_gtwiz_userclk_rx_usrclk_int = gtwiz_userclk_rx_usrclk_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_rx_usrclk2_int;
//  wire [0:0] hb0_gtwiz_userclk_rx_usrclk2_int;
  //assign hb0_gtwiz_userclk_rx_usrclk2_int = gtwiz_userclk_rx_usrclk2_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_rx_active_int;
  wire [0:0] hb0_gtwiz_userclk_rx_active_int;
  assign hb0_gtwiz_userclk_rx_active_int = gtwiz_userclk_rx_active_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_buffbypass_tx_reset_int;
  wire [0:0] hb0_gtwiz_buffbypass_tx_reset_int;
  assign gtwiz_buffbypass_tx_reset_int[0:0] = hb0_gtwiz_buffbypass_tx_reset_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_buffbypass_tx_start_user_int;
  wire [0:0] hb0_gtwiz_buffbypass_tx_start_user_int = 1'b0;
  assign gtwiz_buffbypass_tx_start_user_int[0:0] = hb0_gtwiz_buffbypass_tx_start_user_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_buffbypass_tx_done_int;
  wire [0:0] hb0_gtwiz_buffbypass_tx_done_int;
  assign hb0_gtwiz_buffbypass_tx_done_int = gtwiz_buffbypass_tx_done_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_buffbypass_tx_error_int;
  wire [0:0] hb0_gtwiz_buffbypass_tx_error_int;
  assign hb0_gtwiz_buffbypass_tx_error_int = gtwiz_buffbypass_tx_error_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_buffbypass_rx_reset_int;
  wire [0:0] hb0_gtwiz_buffbypass_rx_reset_int;
  assign gtwiz_buffbypass_rx_reset_int[0:0] = hb0_gtwiz_buffbypass_rx_reset_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_buffbypass_rx_start_user_int;
  wire [0:0] hb0_gtwiz_buffbypass_rx_start_user_int = 1'b0;
  assign gtwiz_buffbypass_rx_start_user_int[0:0] = hb0_gtwiz_buffbypass_rx_start_user_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_buffbypass_rx_done_int;
  wire [0:0] hb0_gtwiz_buffbypass_rx_done_int;
  assign hb0_gtwiz_buffbypass_rx_done_int = gtwiz_buffbypass_rx_done_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_buffbypass_rx_error_int;
  wire [0:0] hb0_gtwiz_buffbypass_rx_error_int;
  assign hb0_gtwiz_buffbypass_rx_error_int = gtwiz_buffbypass_rx_error_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_reset_clk_freerun_int;
  wire [0:0] hb0_gtwiz_reset_clk_freerun_int = 1'b0;
  assign gtwiz_reset_clk_freerun_int[0:0] = hb0_gtwiz_reset_clk_freerun_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_reset_all_int;
  wire [0:0] hb0_gtwiz_reset_all_int = 1'b0;
  assign gtwiz_reset_all_int[0:0] = hb0_gtwiz_reset_all_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_reset_tx_pll_and_datapath_int;// = 1'b0;
  //wire [0:0] hb0_gtwiz_reset_tx_pll_and_datapath_int;
  assign gtwiz_reset_tx_pll_and_datapath_int[0:0] = hb0_gtwiz_reset_tx_pll_and_datapath_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_reset_tx_datapath_int; // = 1'b0;
  //wire [0:0] hb0_gtwiz_reset_tx_datapath_int;
  assign gtwiz_reset_tx_datapath_int[0:0] = hb0_gtwiz_reset_tx_datapath_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_reset_rx_pll_and_datapath_int;
  wire [0:0] hb0_gtwiz_reset_rx_pll_and_datapath_int = 1'b0;
  assign gtwiz_reset_rx_pll_and_datapath_int[0:0] = hb0_gtwiz_reset_rx_pll_and_datapath_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_reset_rx_datapath_int;
  wire [0:0] hb0_gtwiz_reset_rx_datapath_int = 1'b0;
  assign gtwiz_reset_rx_datapath_int[0:0] = hb0_gtwiz_reset_rx_datapath_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_reset_rx_cdr_stable_int;
  wire [0:0] hb0_gtwiz_reset_rx_cdr_stable_int;
  assign hb0_gtwiz_reset_rx_cdr_stable_int = gtwiz_reset_rx_cdr_stable_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_reset_tx_done_int;
  wire [0:0] hb0_gtwiz_reset_tx_done_int;
  assign hb0_gtwiz_reset_tx_done_int = gtwiz_reset_tx_done_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_reset_rx_done_int;
  wire [0:0] hb0_gtwiz_reset_rx_done_int;
  assign hb0_gtwiz_reset_rx_done_int = gtwiz_reset_rx_done_int[0:0];

  //--------------------------------------------------------------------------------------------------------------------
  wire [511:0] gtwiz_userdata_tx_int;
  wire [63:0] hb0_gtwiz_userdata_tx_int;
  wire [63:0] hb1_gtwiz_userdata_tx_int;
  wire [63:0] hb2_gtwiz_userdata_tx_int;
  wire [63:0] hb3_gtwiz_userdata_tx_int;
  wire [63:0] hb4_gtwiz_userdata_tx_int;
  wire [63:0] hb5_gtwiz_userdata_tx_int;
  wire [63:0] hb6_gtwiz_userdata_tx_int;
  wire [63:0] hb7_gtwiz_userdata_tx_int;
  assign gtwiz_userdata_tx_int[63:0] = hb0_gtwiz_userdata_tx_int;
  assign gtwiz_userdata_tx_int[127:64] = hb1_gtwiz_userdata_tx_int;
  assign gtwiz_userdata_tx_int[191:128] = hb2_gtwiz_userdata_tx_int;
  assign gtwiz_userdata_tx_int[255:192] = hb3_gtwiz_userdata_tx_int;
  assign gtwiz_userdata_tx_int[319:256] = hb4_gtwiz_userdata_tx_int;
  assign gtwiz_userdata_tx_int[383:320] = hb5_gtwiz_userdata_tx_int;
  assign gtwiz_userdata_tx_int[447:384] = hb6_gtwiz_userdata_tx_int;
  assign gtwiz_userdata_tx_int[511:448] = hb7_gtwiz_userdata_tx_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [511:0] gtwiz_userdata_rx_int;
  wire [63:0] hb0_gtwiz_userdata_rx_int;
  wire [63:0] hb1_gtwiz_userdata_rx_int;
  wire [63:0] hb2_gtwiz_userdata_rx_int;
  wire [63:0] hb3_gtwiz_userdata_rx_int;
  wire [63:0] hb4_gtwiz_userdata_rx_int;
  wire [63:0] hb5_gtwiz_userdata_rx_int;
  wire [63:0] hb6_gtwiz_userdata_rx_int;
  wire [63:0] hb7_gtwiz_userdata_rx_int;
  assign hb0_gtwiz_userdata_rx_int = gtwiz_userdata_rx_int[63:0];
  assign hb1_gtwiz_userdata_rx_int = gtwiz_userdata_rx_int[127:64];
  assign hb2_gtwiz_userdata_rx_int = gtwiz_userdata_rx_int[191:128];
  assign hb3_gtwiz_userdata_rx_int = gtwiz_userdata_rx_int[255:192];
  assign hb4_gtwiz_userdata_rx_int = gtwiz_userdata_rx_int[319:256];
  assign hb5_gtwiz_userdata_rx_int = gtwiz_userdata_rx_int[383:320];
  assign hb6_gtwiz_userdata_rx_int = gtwiz_userdata_rx_int[447:384];
  assign hb7_gtwiz_userdata_rx_int = gtwiz_userdata_rx_int[511:448];

  //--------------------------------------------------------------------------------------------------------------------
  wire [1:0] gtrefclk01_int;
  wire [0:0] cm0_gtrefclk01_int;
  wire [0:0] cm1_gtrefclk01_int;
  assign gtrefclk01_int[0:0] = cm0_gtrefclk01_int;
  assign gtrefclk01_int[1:1] = cm1_gtrefclk01_int;

  //--------------------------------------------------------------------------------------------------------------------
  wire [1:0] qpll1outclk_int;
  wire [0:0] cm0_qpll1outclk_int;
  wire [0:0] cm1_qpll1outclk_int;
  assign cm0_qpll1outclk_int = qpll1outclk_int[0:0];
  assign cm1_qpll1outclk_int = qpll1outclk_int[1:1];

  //--------------------------------------------------------------------------------------------------------------------
  wire [1:0] qpll1outrefclk_int;
  wire [0:0] cm0_qpll1outrefclk_int;
  wire [0:0] cm1_qpll1outrefclk_int;
  assign cm0_qpll1outrefclk_int = qpll1outrefclk_int[0:0];
  assign cm1_qpll1outrefclk_int = qpll1outrefclk_int[1:1];

  //--------------------------------------------------------------------------------------------------------------------
  wire [7:0] rxgearboxslip_int;
  wire       ch0_rxgearboxslip_int;
  wire       ch1_rxgearboxslip_int;
  wire       ch2_rxgearboxslip_int;
  wire       ch3_rxgearboxslip_int;
  wire       ch4_rxgearboxslip_int;
  wire       ch5_rxgearboxslip_int;
  wire       ch6_rxgearboxslip_int;
  wire       ch7_rxgearboxslip_int;
  assign rxgearboxslip_int[0:0] = ch0_rxgearboxslip_int;
  assign rxgearboxslip_int[1:1] = ch1_rxgearboxslip_int;
  assign rxgearboxslip_int[2:2] = ch2_rxgearboxslip_int;
  assign rxgearboxslip_int[3:3] = ch3_rxgearboxslip_int;
  assign rxgearboxslip_int[4:4] = ch4_rxgearboxslip_int;
  assign rxgearboxslip_int[5:5] = ch5_rxgearboxslip_int;
  assign rxgearboxslip_int[6:6] = ch6_rxgearboxslip_int;
  assign rxgearboxslip_int[7:7] = ch7_rxgearboxslip_int; 

  //--------------------------------------------------------------------------------------------------------------------
//-- jda 6/22   wire [7:0] rxpolarity_int;
//-- jda 6/22   wire [0:0] ch0_rxpolarity_int = 1'b0;
//-- jda 6/22   wire [0:0] ch1_rxpolarity_int = 1'b0;
//-- jda 6/22   wire [0:0] ch2_rxpolarity_int = 1'b0;
//-- jda 6/22   wire [0:0] ch3_rxpolarity_int = 1'b0;
//-- jda 6/22   wire [0:0] ch4_rxpolarity_int = 1'b0;
//-- jda 6/22   wire [0:0] ch5_rxpolarity_int = 1'b0;
//-- jda 6/22   wire [0:0] ch6_rxpolarity_int = 1'b0;
//-- jda 6/22   wire [0:0] ch7_rxpolarity_int = 1'b0;
//-- jda 6/22   wire [7:0] polarity_invert;
  
//-- jda 6/22   vio_polarity_invert vio_polarity (
//-- jda 6/22     .clk(gtwiz_userclk_tx_usrclk2_int),                // input wire clk
//-- jda 6/22     .probe_out0(polarity_invert[7:0])  // output wire [7 : 0] probe_out0
//-- jda 6/22   );
  
//-- jda 6/22  assign rxpolarity_int[0:0] = ch0_rxpolarity_int;
//-- jda 6/22  assign rxpolarity_int[1:1] = ch1_rxpolarity_int;
//-- jda 6/22  assign rxpolarity_int[2:2] = ch2_rxpolarity_int;
//-- jda 6/22  assign rxpolarity_int[3:3] = ch3_rxpolarity_int;
//-- jda 6/22  assign rxpolarity_int[4:4] = ch4_rxpolarity_int;
//-- jda 6/22  assign rxpolarity_int[5:5] = ch5_rxpolarity_int;
//-- jda 6/22  assign rxpolarity_int[6:6] = ch6_rxpolarity_int;
//-- jda 6/22  assign rxpolarity_int[7:7] = ch7_rxpolarity_int;

//-- jda 6/22    assign rxpolarity_int[0:0] = polarity_invert[0];
//-- jda 6/22    assign rxpolarity_int[1:1] = polarity_invert[1];
//-- jda 6/22    assign rxpolarity_int[2:2] = polarity_invert[2];
//-- jda 6/22    assign rxpolarity_int[3:3] = polarity_invert[3];
//-- jda 6/22    assign rxpolarity_int[4:4] = polarity_invert[4];
//-- jda 6/22    assign rxpolarity_int[5:5] = polarity_invert[5];
//-- jda 6/22    assign rxpolarity_int[6:6] = polarity_invert[6];
//-- jda 6/22    assign rxpolarity_int[7:7] = polarity_invert[7];
  
  //--------------------------------------------------------------------------------------------------------------------
  wire [47:0] txheader_int;
  wire [5:0] ch0_txheader_int;
  wire [5:0] ch1_txheader_int;
  wire [5:0] ch2_txheader_int;
  wire [5:0] ch3_txheader_int;
  wire [5:0] ch4_txheader_int;
  wire [5:0] ch5_txheader_int;
  wire [5:0] ch6_txheader_int;
  wire [5:0] ch7_txheader_int;
  assign txheader_int[5:0] = ch0_txheader_int;
  assign txheader_int[11:6] = ch1_txheader_int;
  assign txheader_int[17:12] = ch2_txheader_int;
  assign txheader_int[23:18] = ch3_txheader_int;
  assign txheader_int[29:24] = ch4_txheader_int;
  assign txheader_int[35:30] = ch5_txheader_int;
  assign txheader_int[41:36] = ch6_txheader_int;
  assign txheader_int[47:42] = ch7_txheader_int;
  
  //--------------------------------------------------------------------------------------------------------------------
  wire [55:0] txsequence_int;
  wire [6:0] ch0_txsequence_int;
  wire [6:0] ch1_txsequence_int;
  wire [6:0] ch2_txsequence_int;
  wire [6:0] ch3_txsequence_int;
  wire [6:0] ch4_txsequence_int;
  wire [6:0] ch5_txsequence_int;
  wire [6:0] ch6_txsequence_int;
  wire [6:0] ch7_txsequence_int;
  assign txsequence_int[6:0] = ch0_txsequence_int;
  assign txsequence_int[13:7] = ch1_txsequence_int;
  assign txsequence_int[20:14] = ch2_txsequence_int;
  assign txsequence_int[27:21] = ch3_txsequence_int;
  assign txsequence_int[34:28] = ch4_txsequence_int;
  assign txsequence_int[41:35] = ch5_txsequence_int;
  assign txsequence_int[48:42] = ch6_txsequence_int;
  assign txsequence_int[55:49] = ch7_txsequence_int;
  
  //--------------------------------------------------------------------------------------------------------------------
  wire [15:0] rxdatavalid_int;
  wire [1:0] ch0_rxdatavalid_int;
  wire [1:0] ch1_rxdatavalid_int;
  wire [1:0] ch2_rxdatavalid_int;
  wire [1:0] ch3_rxdatavalid_int;
  wire [1:0] ch4_rxdatavalid_int;
  wire [1:0] ch5_rxdatavalid_int;
  wire [1:0] ch6_rxdatavalid_int;
  wire [1:0] ch7_rxdatavalid_int;
  assign ch0_rxdatavalid_int = rxdatavalid_int[1:0];
  assign ch1_rxdatavalid_int = rxdatavalid_int[3:2];
  assign ch2_rxdatavalid_int = rxdatavalid_int[5:4];
  assign ch3_rxdatavalid_int = rxdatavalid_int[7:6];
  assign ch4_rxdatavalid_int = rxdatavalid_int[9:8];
  assign ch5_rxdatavalid_int = rxdatavalid_int[11:10];
  assign ch6_rxdatavalid_int = rxdatavalid_int[13:12];
  assign ch7_rxdatavalid_int = rxdatavalid_int[15:14];

  //--------------------------------------------------------------------------------------------------------------------
  wire [47:0] rxheader_int;
  wire [5:0] ch0_rxheader_int;
  wire [5:0] ch1_rxheader_int;
  wire [5:0] ch2_rxheader_int;
  wire [5:0] ch3_rxheader_int;
  wire [5:0] ch4_rxheader_int;
  wire [5:0] ch5_rxheader_int;
  wire [5:0] ch6_rxheader_int;
  wire [5:0] ch7_rxheader_int;
  assign ch0_rxheader_int = rxheader_int[5:0];
  assign ch1_rxheader_int = rxheader_int[11:6];
  assign ch2_rxheader_int = rxheader_int[17:12];
  assign ch3_rxheader_int = rxheader_int[23:18];
  assign ch4_rxheader_int = rxheader_int[29:24];
  assign ch5_rxheader_int = rxheader_int[35:30];
  assign ch6_rxheader_int = rxheader_int[41:36];
  assign ch7_rxheader_int = rxheader_int[47:42];

  //--------------------------------------------------------------------------------------------------------------------
  wire [15:0] rxheadervalid_int;
  wire [1:0] ch0_rxheadervalid_int;
  wire [1:0] ch1_rxheadervalid_int;
  wire [1:0] ch2_rxheadervalid_int;
  wire [1:0] ch3_rxheadervalid_int;
  wire [1:0] ch4_rxheadervalid_int;
  wire [1:0] ch5_rxheadervalid_int;
  wire [1:0] ch6_rxheadervalid_int;
  wire [1:0] ch7_rxheadervalid_int;
  assign ch0_rxheadervalid_int = rxheadervalid_int[1:0];
  assign ch1_rxheadervalid_int = rxheadervalid_int[3:2];
  assign ch2_rxheadervalid_int = rxheadervalid_int[5:4];
  assign ch3_rxheadervalid_int = rxheadervalid_int[7:6];
  assign ch4_rxheadervalid_int = rxheadervalid_int[9:8];
  assign ch5_rxheadervalid_int = rxheadervalid_int[11:10];
  assign ch6_rxheadervalid_int = rxheadervalid_int[13:12];
  assign ch7_rxheadervalid_int = rxheadervalid_int[15:14];

  //--------------------------------------------------------------------------------------------------------------------
  wire [7:0] rxpmaresetdone_int;
  wire [0:0] ch0_rxpmaresetdone_int;
  wire [0:0] ch1_rxpmaresetdone_int;
  wire [0:0] ch2_rxpmaresetdone_int;
  wire [0:0] ch3_rxpmaresetdone_int;
  wire [0:0] ch4_rxpmaresetdone_int;
  wire [0:0] ch5_rxpmaresetdone_int;
  wire [0:0] ch6_rxpmaresetdone_int;
  wire [0:0] ch7_rxpmaresetdone_int;
  assign ch0_rxpmaresetdone_int = rxpmaresetdone_int[0:0];
  assign ch1_rxpmaresetdone_int = rxpmaresetdone_int[1:1];
  assign ch2_rxpmaresetdone_int = rxpmaresetdone_int[2:2];
  assign ch3_rxpmaresetdone_int = rxpmaresetdone_int[3:3];
  assign ch4_rxpmaresetdone_int = rxpmaresetdone_int[4:4];
  assign ch5_rxpmaresetdone_int = rxpmaresetdone_int[5:5];
  assign ch6_rxpmaresetdone_int = rxpmaresetdone_int[6:6];
  assign ch7_rxpmaresetdone_int = rxpmaresetdone_int[7:7];

  //--------------------------------------------------------------------------------------------------------------------
  wire [15:0] rxstartofseq_int;
  wire [1:0] ch0_rxstartofseq_int;
  wire [1:0] ch1_rxstartofseq_int;
  wire [1:0] ch2_rxstartofseq_int;
  wire [1:0] ch3_rxstartofseq_int;
  wire [1:0] ch4_rxstartofseq_int;
  wire [1:0] ch5_rxstartofseq_int;
  wire [1:0] ch6_rxstartofseq_int;
  wire [1:0] ch7_rxstartofseq_int;
  assign ch0_rxstartofseq_int = rxstartofseq_int[1:0];
  assign ch1_rxstartofseq_int = rxstartofseq_int[3:2];
  assign ch2_rxstartofseq_int = rxstartofseq_int[5:4];
  assign ch3_rxstartofseq_int = rxstartofseq_int[7:6];
  assign ch4_rxstartofseq_int = rxstartofseq_int[9:8];
  assign ch5_rxstartofseq_int = rxstartofseq_int[11:10];
  assign ch6_rxstartofseq_int = rxstartofseq_int[13:12];
  assign ch7_rxstartofseq_int = rxstartofseq_int[15:14];
  
  //--------------------------------------------------------------------------------------------------------------------
  wire [7:0] txpmaresetdone_int;
  wire [0:0] ch0_txpmaresetdone_int;
  wire [0:0] ch1_txpmaresetdone_int;
  wire [0:0] ch2_txpmaresetdone_int;
  wire [0:0] ch3_txpmaresetdone_int;
  wire [0:0] ch4_txpmaresetdone_int;
  wire [0:0] ch5_txpmaresetdone_int;
  wire [0:0] ch6_txpmaresetdone_int;
  wire [0:0] ch7_txpmaresetdone_int;
  assign ch0_txpmaresetdone_int = txpmaresetdone_int[0:0];
  assign ch1_txpmaresetdone_int = txpmaresetdone_int[1:1];
  assign ch2_txpmaresetdone_int = txpmaresetdone_int[2:2];
  assign ch3_txpmaresetdone_int = txpmaresetdone_int[3:3];
  assign ch4_txpmaresetdone_int = txpmaresetdone_int[4:4];
  assign ch5_txpmaresetdone_int = txpmaresetdone_int[5:5];
  assign ch6_txpmaresetdone_int = txpmaresetdone_int[6:6];
  assign ch7_txpmaresetdone_int = txpmaresetdone_int[7:7];

  //--------------------------------------------------------------------------------------------------------------------
  wire [7:0] txprgdivresetdone_int;
  wire [0:0] ch0_txprgdivresetdone_int;
  wire [0:0] ch1_txprgdivresetdone_int;
  wire [0:0] ch2_txprgdivresetdone_int;
  wire [0:0] ch3_txprgdivresetdone_int;
  wire [0:0] ch4_txprgdivresetdone_int;
  wire [0:0] ch5_txprgdivresetdone_int;
  wire [0:0] ch6_txprgdivresetdone_int;
  wire [0:0] ch7_txprgdivresetdone_int;
  assign ch0_txprgdivresetdone_int = txprgdivresetdone_int[0:0];
  assign ch1_txprgdivresetdone_int = txprgdivresetdone_int[1:1];
  assign ch2_txprgdivresetdone_int = txprgdivresetdone_int[2:2];
  assign ch3_txprgdivresetdone_int = txprgdivresetdone_int[3:3];
  assign ch4_txprgdivresetdone_int = txprgdivresetdone_int[4:4];
  assign ch5_txprgdivresetdone_int = txprgdivresetdone_int[5:5];
  assign ch6_txprgdivresetdone_int = txprgdivresetdone_int[6:6];
  assign ch7_txprgdivresetdone_int = txprgdivresetdone_int[7:7];
  
  // ===================================================================================================================
  // BUFFERS
  // ===================================================================================================================

  // Buffer the hb_gtwiz_reset_all_in input and logically combine it with the internal signal from the example
  // initialization block as well as the VIO-sourced reset
  //wire hb_gtwiz_reset_all_vio_int;
  //wire hb_gtwiz_reset_all_buf_int;
  wire hb_gtwiz_reset_all_init_int;
  wire hb_gtwiz_reset_all_int;
  
  wire hb_gtwiz_reset_all_DLx_reset;

  // Reset happens from DLx instead of testbench stimulus
  //assign hb_gtwiz_reset_all_int = hb_gtwiz_reset_all_DLx_reset || hb_gtwiz_reset_all_init_int || hb_gtwiz_reset_all_vio_int;
  assign hb_gtwiz_reset_all_int = hb_gtwiz_reset_all_DLx_reset || hb_gtwiz_reset_all_init_int;

  // Globally buffer the free-running input clock
 // wire hb_gtwiz_reset_clk_freerun_buf_int;

/*  BUFG bufg_clk_freerun_inst (
    .I (hb_gtwiz_reset_clk_freerun_in),
    .O (hb_gtwiz_reset_clk_freerun_buf_int)
  );*/

  // Instantiate a differential reference clock buffer for each reference clock differential pair in this configuration,
  // and assign the single-ended output of each differential reference clock buffer to the appropriate PLL input signal

  // Differential reference clock buffer for MGTREFCLK0_X0Y0
  wire mgtrefclk1_x0y0_int;
  wire reset_clk_156_25MHz;  

  IBUFDS_GTE4 #(
    .REFCLK_EN_TX_PATH  (1'b0),
    .REFCLK_HROW_CK_SEL (2'b00),
    .REFCLK_ICNTL_RX    (2'b00)
  ) IBUFDS_GTE4_MGTREFCLK0_X0Y0_INST (
    .I     (mgtrefclk1_x0y0_p),
    .IB    (mgtrefclk1_x0y0_n),
    .CEB   (1'b0),
    .O     (mgtrefclk1_x0y0_int),
    .ODIV2 ()
//-- jda 6/21    .ODIV2 (reset_clk_156_25MHz)
  );

   // Output of IO Differential Buffer
   wire freerun_clk; // 300 MHz

   // BUFGCE_DIV: General Clock Buffer with Divide Function
   //             Virtex UltraScale+
   // Xilinx HDL Language Template, version 2017.1
   BUFGCE_DIV #(
      .BUFGCE_DIVIDE(2),      // 1-8
      // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
      .IS_CE_INVERTED(1'b0),  // Optional inversion for CE
      .IS_CLR_INVERTED(1'b0), // Optional inversion for CLR
      .IS_I_INVERTED(1'b0)    // Optional inversion for I
   )
   BUFGCE_DIV_inst (
      .O   (hb_gtwiz_reset_clk_freerun_buf_int), // 1-bit output: Buffer
      .CE  (1'b1),                               // 1-bit input: Buffer enable
      .CLR (1'b0),                               // 1-bit input: Asynchronous clear
      .I   (freerun_clk)                         // 1-bit input: Buffer
   );



   IBUFDS #(
      .DQS_BIAS("FALSE") // (FALSE, TRUE)
   )
   IBUFDS_freerun (
      .O  (freerun_clk),   // 1-bit output: Buffer output
      .I  (freerun_clk_p), // 1-bit input: Diff_p buffer input (connect directly to top-level port)
      .IB (freerun_clk_n)  // 1-bit input: Diff_n buffer input (connect directly to top-level port)
   );

//-- jda 6/21   // added to support using 156_25MHz reference clock for the reset logic   
//-- jda 6/21   // provides startup clock buffering for reset logic
//-- jda 6/21   BUFG_GT reset_clock_buf_inst (
//-- jda 6/21       .O(hb_gtwiz_reset_clk_freerun_buf_int),   
//-- jda 6/21       .CE(1'b1),        
//-- jda 6/21       .CEMASK(1'b0),   
//-- jda 6/21       .CLR(1'b0),      
//-- jda 6/21       .CLRMASK(1'b0), 
//-- jda 6/21       .DIV(3'b000),    
//-- jda 6/21       .I(reset_clk_156_25MHz)
//-- jda 6/21    );  
  

  // Differential reference clock buffer for MGTREFCLK0_X0Y1
  wire mgtrefclk1_x0y1_int;

  IBUFDS_GTE4 #(
    .REFCLK_EN_TX_PATH  (1'b0),
    .REFCLK_HROW_CK_SEL (2'b00),
    .REFCLK_ICNTL_RX    (2'b00)
  ) IBUFDS_GTE4_MGTREFCLK0_X0Y1_INST (
    .I     (mgtrefclk1_x0y1_p),
    .IB    (mgtrefclk1_x0y1_n),
    .CEB   (1'b0),
    .O     (mgtrefclk1_x0y1_int),
    .ODIV2 ()
  );

  assign cm0_gtrefclk01_int = mgtrefclk1_x0y0_int;
  assign cm1_gtrefclk01_int = mgtrefclk1_x0y1_int;


  // ===================================================================================================================
  // USER CLOCKING RESETS
  // ===================================================================================================================

  // The TX user clocking helper block should be held in reset until the clock source of that block is known to be
  // stable. The following assignment is an example of how that stability can be determined, based on the selected TX
  // user clock source. Replace the assignment with the appropriate signal or logic to achieve that behavior as needed.
  assign hb0_gtwiz_userclk_tx_reset_int = ~(&txprgdivresetdone_int && &txpmaresetdone_int);

  // The RX user clocking helper block should be held in reset until the clock source of that block is known to be
  // stable. The following assignment is an example of how that stability can be determined, based on the selected RX
  // user clock source. Replace the assignment with the appropriate signal or logic to achieve that behavior as needed.
  assign hb0_gtwiz_userclk_rx_reset_int = ~(&rxpmaresetdone_int);


  // ===================================================================================================================
  // BUFFER BYPASS CONTROLLER RESETS
  // ===================================================================================================================

  // The TX buffer bypass controller helper block should be held in reset until the TX user clocking network helper
  // block which drives it is active
  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_reset_synchronizer reset_synchronizer_gtwiz_buffbypass_tx_reset_inst (
    .clk_in  (hb0_gtwiz_userclk_tx_usrclk2_int),
    .rst_in  (~hb0_gtwiz_userclk_tx_active_int),
    .rst_out (hb0_gtwiz_buffbypass_tx_reset_int)
  );

  // The RX buffer bypass controller helper block should be held in reset until the RX user clocking network helper
  // block which drives it is active and the TX buffer bypass sequence has completed for this loopback configuration
  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_reset_synchronizer reset_synchronizer_gtwiz_buffbypass_rx_reset_inst (
    .clk_in  (hb0_gtwiz_userclk_tx_usrclk2_int),
    //.clk_in  (hb0_gtwiz_userclk_rx_usrclk2_int),       
    .rst_in  (~hb0_gtwiz_userclk_rx_active_int || ~hb0_gtwiz_buffbypass_tx_done_int),
    .rst_out (hb0_gtwiz_buffbypass_rx_reset_int)
  );



  // ===================================================================================================================
  // INITIALIZATION
  // ===================================================================================================================

  // Declare the receiver reset signals that interface to the reset controller helper block. For this configuration,
  // which uses the same PLL type for transmitter and receiver, the "reset RX PLL and datapath" feature is not used.
  wire hb_gtwiz_reset_rx_pll_and_datapath_int = 1'b0;
  wire hb_gtwiz_reset_rx_datapath_int;

  // Declare signals which connect the VIO instance to the initialization module for debug purposes
  //wire       init_done_int;
  //wire [3:0] init_retry_ctr_int;

  // Combine the receiver reset signals form the initialization module and the VIO to drive the appropriate reset
  // controller helper block reset input
  //wire hb_gtwiz_reset_rx_pll_and_datapath_vio_int;
  //wire hb_gtwiz_reset_rx_datapath_vio_int;
  wire hb_gtwiz_reset_rx_datapath_init_int;
  wire hb_gtwiz_reset_rx_datapath_DLx_int; // Josh added to retrain the transceiver's receiver
  
  assign hb_gtwiz_reset_rx_datapath_int = hb_gtwiz_reset_rx_datapath_init_int || hb_gtwiz_reset_rx_datapath_vio_int || hb_gtwiz_reset_rx_datapath_DLx_int;
//  assign hb_gtwiz_reset_rx_datapath_int = hb_gtwiz_reset_rx_datapath_init_int || hb_gtwiz_reset_rx_datapath_DLx_int;

  // The example initialization module interacts with the reset controller helper block and other example design logic
  // to retry failed reset attempts in order to mitigate bring-up issues such as initially-unavilable reference clocks
  // or data connections. It also resets the receiver in the event of link loss in an attempt to regain link, so please
  // note the possibility that this behavior can have the effect of overriding or disturbing user-provided inputs that
  // destabilize the data stream. It is a demonstration only and can be modified to suit your system needs.
  DLx_phy_example_init example_init_inst (
    .clk_freerun_in  (hb_gtwiz_reset_clk_freerun_buf_int),
    .reset_all_in    (hb_gtwiz_reset_all_int),
    .tx_init_done_in (gtwiz_reset_tx_done_int && gtwiz_buffbypass_tx_done_int),
    .rx_init_done_in (gtwiz_reset_rx_done_int && gtwiz_buffbypass_rx_done_int),
    .rx_data_good_in (gtwiz_reset_rx_done_int && gtwiz_buffbypass_rx_done_int), // if you get through bufferbypasss assume data is good.
    .reset_all_out   (hb_gtwiz_reset_all_init_int),
    .reset_rx_out    (hb_gtwiz_reset_rx_datapath_init_int),
    .init_done_out   (init_done_int),
    .retry_ctr_out   (init_retry_ctr_int)
  );


  // ===================================================================================================================
  // VIO FOR HARDWARE BRING-UP AND DEBUG
  // ===================================================================================================================

  // Synchronize txprgdivresetdone into the free-running clock domain for VIO usage
  wire [7:0] txprgdivresetdone_vio_sync;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txprgdivresetdone_0_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txprgdivresetdone_int[0]),
    .o_out  (txprgdivresetdone_vio_sync[0])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txprgdivresetdone_1_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txprgdivresetdone_int[1]),
    .o_out  (txprgdivresetdone_vio_sync[1])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txprgdivresetdone_2_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txprgdivresetdone_int[2]),
    .o_out  (txprgdivresetdone_vio_sync[2])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txprgdivresetdone_3_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txprgdivresetdone_int[3]),
    .o_out  (txprgdivresetdone_vio_sync[3])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txprgdivresetdone_4_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txprgdivresetdone_int[4]),
    .o_out  (txprgdivresetdone_vio_sync[4])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txprgdivresetdone_5_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txprgdivresetdone_int[5]),
    .o_out  (txprgdivresetdone_vio_sync[5])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txprgdivresetdone_6_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txprgdivresetdone_int[6]),
    .o_out  (txprgdivresetdone_vio_sync[6])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txprgdivresetdone_7_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txprgdivresetdone_int[7]),
    .o_out  (txprgdivresetdone_vio_sync[7])
  );

  // Synchronize txpmaresetdone into the free-running clock domain for VIO usage
  wire [7:0] txpmaresetdone_vio_sync;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txpmaresetdone_0_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txpmaresetdone_int[0]),
    .o_out  (txpmaresetdone_vio_sync[0])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txpmaresetdone_1_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txpmaresetdone_int[1]),
    .o_out  (txpmaresetdone_vio_sync[1])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txpmaresetdone_2_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txpmaresetdone_int[2]),
    .o_out  (txpmaresetdone_vio_sync[2])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txpmaresetdone_3_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txpmaresetdone_int[3]),
    .o_out  (txpmaresetdone_vio_sync[3])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txpmaresetdone_4_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txpmaresetdone_int[4]),
    .o_out  (txpmaresetdone_vio_sync[4])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txpmaresetdone_5_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txpmaresetdone_int[5]),
    .o_out  (txpmaresetdone_vio_sync[5])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txpmaresetdone_6_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txpmaresetdone_int[6]),
    .o_out  (txpmaresetdone_vio_sync[6])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_txpmaresetdone_7_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (txpmaresetdone_int[7]),
    .o_out  (txpmaresetdone_vio_sync[7])
  );

  // Synchronize rxpmaresetdone into the free-running clock domain for VIO usage
  wire [7:0] rxpmaresetdone_vio_sync;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_rxpmaresetdone_0_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (rxpmaresetdone_int[0]),
    .o_out  (rxpmaresetdone_vio_sync[0])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_rxpmaresetdone_1_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (rxpmaresetdone_int[1]),
    .o_out  (rxpmaresetdone_vio_sync[1])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_rxpmaresetdone_2_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (rxpmaresetdone_int[2]),
    .o_out  (rxpmaresetdone_vio_sync[2])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_rxpmaresetdone_3_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (rxpmaresetdone_int[3]),
    .o_out  (rxpmaresetdone_vio_sync[3])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_rxpmaresetdone_4_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (rxpmaresetdone_int[4]),
    .o_out  (rxpmaresetdone_vio_sync[4])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_rxpmaresetdone_5_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (rxpmaresetdone_int[5]),
    .o_out  (rxpmaresetdone_vio_sync[5])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_rxpmaresetdone_6_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (rxpmaresetdone_int[6]),
    .o_out  (rxpmaresetdone_vio_sync[6])
  );

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_rxpmaresetdone_7_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (rxpmaresetdone_int[7]),
    .o_out  (rxpmaresetdone_vio_sync[7])
  );

  // Synchronize gtwiz_reset_tx_done into the free-running clock domain for VIO usage
  //wire [0:0] gtwiz_reset_tx_done_vio_sync;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_gtwiz_reset_tx_done_0_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (gtwiz_reset_tx_done_int[0]),
    .o_out  (gtwiz_reset_tx_done_vio_sync[0])
  );

  // Synchronize gtwiz_reset_rx_done into the free-running clock domain for VIO usage
  //wire [0:0] gtwiz_reset_rx_done_vio_sync;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_gtwiz_reset_rx_done_0_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (gtwiz_reset_rx_done_int[0]),
    .o_out  (gtwiz_reset_rx_done_vio_sync[0])
  );

  // Synchronize gtwiz_buffbypass_tx_done into the free-running clock domain for VIO usage
  //wire [0:0] gtwiz_buffbypass_tx_done_vio_sync;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_gtwiz_buffbypass_tx_done_0_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (gtwiz_buffbypass_tx_done_int[0]),
    .o_out  (gtwiz_buffbypass_tx_done_vio_sync[0])
  );

  // Synchronize gtwiz_buffbypass_rx_done into the free-running clock domain for VIO usage
  //wire [0:0] gtwiz_buffbypass_rx_done_vio_sync;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_gtwiz_buffbypass_rx_done_0_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (gtwiz_buffbypass_rx_done_int[0]),
    .o_out  (gtwiz_buffbypass_rx_done_vio_sync[0])
  );

  // Synchronize gtwiz_buffbypass_tx_error into the free-running clock domain for VIO usage
  //wire [0:0] gtwiz_buffbypass_tx_error_vio_sync;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_gtwiz_buffbypass_tx_error_0_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (gtwiz_buffbypass_tx_error_int[0]),
    .o_out  (gtwiz_buffbypass_tx_error_vio_sync[0])
  );

  // Synchronize gtwiz_buffbypass_rx_error into the free-running clock domain for VIO usage
  //wire [0:0] gtwiz_buffbypass_rx_error_vio_sync;

  (* DONT_TOUCH = "TRUE" *)
  DLx_phy_example_bit_synchronizer bit_synchronizer_vio_gtwiz_buffbypass_rx_error_0_inst (
    .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
    .i_in   (gtwiz_buffbypass_rx_error_int[0]),
    .o_out  (gtwiz_buffbypass_rx_error_vio_sync[0])
  );
  
  
  // --@ Joshua Andersen 09/06/2016  Initial interface DLx to transceiver
  // ===================================================================================================================
  // DLx INSTANCE
  // ===================================================================================================================
//--  wire   gtwiz_userclk_tx_usrclk3_int;
//--  assign tx_clk_402MHz = gtwiz_userclk_tx_usrclk2_int; // Clock is used by DLx and DLx drivers
//--  assign tx_clk_201MHz = gtwiz_userclk_tx_usrclk3_int; // Clock is used by AFU  // -- joek added for 201MHz support
//  wire   gnd;
//  wire   vdn;
//  assign gnd = 1'b0;
//  assign vdn = 1'b1;
  
  
  wire [1:0] dlx_l0_tx_header_int;
  wire [1:0] dlx_l1_tx_header_int;
  wire [1:0] dlx_l2_tx_header_int;
  wire [1:0] dlx_l3_tx_header_int;
  wire [1:0] dlx_l4_tx_header_int;
  wire [1:0] dlx_l5_tx_header_int;
  wire [1:0] dlx_l6_tx_header_int;
  wire [1:0] dlx_l7_tx_header_int;

  assign ch0_txheader_int = {4'b0000, dlx_l0_tx_header_int};
  assign ch1_txheader_int = {4'b0000, dlx_l1_tx_header_int};
  assign ch2_txheader_int = {4'b0000, dlx_l2_tx_header_int};
  assign ch3_txheader_int = {4'b0000, dlx_l3_tx_header_int};
  assign ch4_txheader_int = {4'b0000, dlx_l4_tx_header_int};
  assign ch5_txheader_int = {4'b0000, dlx_l5_tx_header_int};
  assign ch6_txheader_int = {4'b0000, dlx_l6_tx_header_int};
  assign ch7_txheader_int = {4'b0000, dlx_l7_tx_header_int};
  
  wire [5:0] dlx_l0_tx_seq;
  wire [5:0] dlx_l1_tx_seq;
  wire [5:0] dlx_l2_tx_seq;
  wire [5:0] dlx_l3_tx_seq;
  wire [5:0] dlx_l4_tx_seq;
  wire [5:0] dlx_l5_tx_seq;
  wire [5:0] dlx_l6_tx_seq;
  wire [5:0] dlx_l7_tx_seq;
  
  
  assign ch0_txsequence_int = {1'b0, dlx_l0_tx_seq};
  assign ch1_txsequence_int = {1'b0, dlx_l1_tx_seq};
  assign ch2_txsequence_int = {1'b0, dlx_l2_tx_seq};
  assign ch3_txsequence_int = {1'b0, dlx_l3_tx_seq};
  assign ch4_txsequence_int = {1'b0, dlx_l4_tx_seq};
  assign ch5_txsequence_int = {1'b0, dlx_l5_tx_seq};
  assign ch6_txsequence_int = {1'b0, dlx_l6_tx_seq};
  assign ch7_txsequence_int = {1'b0, dlx_l7_tx_seq};
  
  
  
  
  
  
  ocx_dlx_top ocx_dlx_top_inst (
    // ----------------------
    // -- RX interface
    // ----------------------
    // -- interface to TLx
     .dlx_tlx_flit_valid      (dlx_tlx_flit_valid)               // --  > output            
    ,.dlx_tlx_flit            (dlx_tlx_flit)                     // --  > output [511:0]    
    ,.dlx_tlx_flit_crc_err    (dlx_tlx_flit_crc_err)             // --  > output           
    ,.dlx_tlx_link_up         (dlx_tlx_link_up)                  // --  > output            
    ,.dlx_config_info         (dlx_config_info)                  // --  > output
    ,.ro_dlx_version          (ro_dlx_version[31:0])             // --  > output
    ,.ln0_rx_valid            (ch0_rxdatavalid_int[0])          // --  < input ch0_rxdatavalid_int originally 2 bits
    ,.ln1_rx_valid            (ch1_rxdatavalid_int[0])          // --  < input ch1_rxdatavalid_int originally 2 bits
    ,.ln2_rx_valid            (ch2_rxdatavalid_int[0])          // --  < input ch2_rxdatavalid_int originally 2 bits
    ,.ln3_rx_valid            (ch3_rxdatavalid_int[0])          // --  < input ch3_rxdatavalid_int originally 2 bits
    ,.ln4_rx_valid            (ch4_rxdatavalid_int[0])          // --  < input ch4_rxdatavalid_int originally 2 bits
    ,.ln5_rx_valid            (ch5_rxdatavalid_int[0])          // --  < input ch5_rxdatavalid_int originally 2 bits
    ,.ln6_rx_valid            (ch6_rxdatavalid_int[0])          // --  < input ch6_rxdatavalid_int originally 2 bits
    ,.ln7_rx_valid            (ch7_rxdatavalid_int[0])          // --  < input ch7_rxdatavalid_int originally 2 bits
    ,.ln0_rx_header           (ch0_rxheader_int[1:0])            // --  < input [1:0] ch0_rxheader_int originally 6 bits                             
    ,.ln1_rx_header           (ch1_rxheader_int[1:0])            // --  < input [1:0] ch1_rxheader_int originally 6 bits                              
    ,.ln2_rx_header           (ch2_rxheader_int[1:0])            // --  < input [1:0] ch2_rxheader_int originally 6 bits                              
    ,.ln3_rx_header           (ch3_rxheader_int[1:0])            // --  < input [1:0] ch3_rxheader_int originally 6 bits                              
    ,.ln4_rx_header           (ch4_rxheader_int[1:0])            // --  < input [1:0] ch4_rxheader_int originally 6 bits                              
    ,.ln5_rx_header           (ch5_rxheader_int[1:0])            // --  < input [1:0] ch5_rxheader_int originally 6 bits                              
    ,.ln6_rx_header           (ch6_rxheader_int[1:0])            // --  < input [1:0] ch6_rxheader_int originally 6 bits                              
    ,.ln7_rx_header           (ch7_rxheader_int[1:0])            // --  < input [1:0] ch7_rxheader_int originally 6 bits                              
    ,.ln0_rx_data             (hb0_gtwiz_userdata_rx_int)        // --  < input  [63:0]                               
    ,.ln1_rx_data             (hb1_gtwiz_userdata_rx_int)        // --  < input  [63:0]                               
    ,.ln2_rx_data             (hb2_gtwiz_userdata_rx_int)        // --  < input  [63:0]                               
    ,.ln3_rx_data             (hb3_gtwiz_userdata_rx_int)        // --  < input  [63:0]                               
    ,.ln4_rx_data             (hb4_gtwiz_userdata_rx_int)        // --  < input  [63:0]                               
    ,.ln5_rx_data             (hb5_gtwiz_userdata_rx_int)        // --  < input  [63:0]                               
    ,.ln6_rx_data             (hb6_gtwiz_userdata_rx_int)        // --  < input  [63:0]                               
    ,.ln7_rx_data             (hb7_gtwiz_userdata_rx_int)        // --  < input  [63:0]                               
    ,.ln0_rx_slip             (ch0_rxgearboxslip_int)            // --  < output                               
    ,.ln1_rx_slip             (ch1_rxgearboxslip_int)            // --  < output                               
    ,.ln2_rx_slip             (ch2_rxgearboxslip_int)            // --  < output                               
    ,.ln3_rx_slip             (ch3_rxgearboxslip_int)            // --  < output                               
    ,.ln4_rx_slip             (ch4_rxgearboxslip_int)            // --  < output                               
    ,.ln5_rx_slip             (ch5_rxgearboxslip_int)            // --  < output                               
    ,.ln6_rx_slip             (ch6_rxgearboxslip_int)            // --  < output                               
    ,.ln7_rx_slip             (ch7_rxgearboxslip_int)            // --  < output                                                      
    
    // ----------------------                          
    // -- TX interface
    // ----------------------                          
    // -- tlx interface
    ,.dlx_tlx_init_flit_depth (dlx_tlx_init_flit_depth)          // --  > output [2:0]            
    ,.dlx_tlx_flit_credit     (dlx_tlx_flit_credit)              // --  > output             
    ,.tlx_dlx_flit_valid      (tlx_dlx_flit_valid)               // --  < input             
    ,.tlx_dlx_flit            (tlx_dlx_flit)                     // --  < input  [511:0]    
    
    // -- Phy interface
    ,.dlx_l0_tx_data          (hb0_gtwiz_userdata_tx_int)        // --  > output [63:0]     
    ,.dlx_l1_tx_data          (hb1_gtwiz_userdata_tx_int)        // --  > output [63:0]     
    ,.dlx_l2_tx_data          (hb2_gtwiz_userdata_tx_int)        // --  > output [63:0]     
    ,.dlx_l3_tx_data          (hb3_gtwiz_userdata_tx_int)        // --  > output [63:0]     
    ,.dlx_l4_tx_data          (hb4_gtwiz_userdata_tx_int)        // --  > output [63:0]     
    ,.dlx_l5_tx_data          (hb5_gtwiz_userdata_tx_int)        // --  > output [63:0]     
    ,.dlx_l6_tx_data          (hb6_gtwiz_userdata_tx_int)        // --  > output [63:0]     
    ,.dlx_l7_tx_data          (hb7_gtwiz_userdata_tx_int)        // --  > output [63:0]     
    ,.dlx_l0_tx_header        (dlx_l0_tx_header_int)             // --  > output [1:0] ch0_txheader_int originally 6 bits
    ,.dlx_l1_tx_header        (dlx_l1_tx_header_int)             // --  > output [1:0] ch1_txheader_int originally 6 bits
    ,.dlx_l2_tx_header        (dlx_l2_tx_header_int)             // --  > output [1:0] ch2_txheader_int originally 6 bits
    ,.dlx_l3_tx_header        (dlx_l3_tx_header_int)             // --  > output [1:0] ch3_txheader_int originally 6 bits
    ,.dlx_l4_tx_header        (dlx_l4_tx_header_int)             // --  > output [1:0] ch4_txheader_int originally 6 bits
    ,.dlx_l5_tx_header        (dlx_l5_tx_header_int)             // --  > output [1:0] ch5_txheader_int originally 6 bits
    ,.dlx_l6_tx_header        (dlx_l6_tx_header_int)             // --  > output [1:0] ch6_txheader_int originally 6 bits
    ,.dlx_l7_tx_header        (dlx_l7_tx_header_int)             // --  > output [1:0] ch7_txheader_int originally 6 bits
    ,.dlx_l0_tx_seq           (dlx_l0_tx_seq)                    // --  > output [5:0] ch0_tx_sequence_int originally 7 bits
    ,.dlx_l1_tx_seq           (dlx_l1_tx_seq)                    // --  > output [5:0] ch1_tx_sequence_int originally 7 bits
    ,.dlx_l2_tx_seq           (dlx_l2_tx_seq)                    // --  > output [5:0] ch2_tx_sequence_int originally 7 bits
    ,.dlx_l3_tx_seq           (dlx_l3_tx_seq)                    // --  > output [5:0] ch3_tx_sequence_int originally 7 bits
    ,.dlx_l4_tx_seq           (dlx_l4_tx_seq)                    // --  > output [5:0] ch4_tx_sequence_int originally 7 bits
    ,.dlx_l5_tx_seq           (dlx_l5_tx_seq)                    // --  > output [5:0] ch5_tx_sequence_int originally 7 bits
    ,.dlx_l6_tx_seq           (dlx_l6_tx_seq)                    // --  > output [5:0] ch6_tx_sequence_int originally 7 bits
    ,.dlx_l7_tx_seq           (dlx_l7_tx_seq)                    // --  > output [5:0] ch7_tx_sequence_int originally 7 bits
    ,.tlx_dlx_debug_encode    (tlx_dlx_debug_encode)             // --  < input [3:0]
    ,.tlx_dlx_debug_info      (tlx_dlx_debug_info)               // --  < input [31:0]                       
//--    ,.opt_gckn                (gtwiz_userclk_tx_usrclk2_int)     // --  < input                                         
    ,.opt_gckn                (tx_clk_402MHz)                    // --  < input                                         
    
//    ,.gnd                     (gnd)                              // -- <> inout             
//    ,.vdn                     (vdn)                              // -- <> inout        
    ,.ocde                    (ocde)                             // -- < input
    // -- Josh Andersen added
    ,.clk_156_25MHz                (hb_gtwiz_reset_clk_freerun_buf_int) // --  < input
    ,.gtwiz_reset_all_out          (hb_gtwiz_reset_all_DLx_reset)       // --  > output
    ,.hb_gtwiz_reset_all_in        (hb_gtwiz_reset_all_int)             // --  > input 
    ,.gtwiz_reset_tx_done_in       (gtwiz_reset_tx_done_int)            // --  < input
    ,.gtwiz_reset_rx_done_in       (gtwiz_reset_rx_done_int)            // --  < input
    ,.gtwiz_buffbypass_tx_done_in  (gtwiz_buffbypass_tx_done_int)       // --  < input
    ,.gtwiz_buffbypass_rx_done_in  (gtwiz_buffbypass_rx_done_int)       // --  < input
    ,.gtwiz_userclk_tx_active_in   (gtwiz_userclk_tx_active_int)        // --  < input
    ,.gtwiz_userclk_rx_active_in   (gtwiz_userclk_rx_active_int)        // --  < input
    ,.send_first                   (send_first)                         // --  < input
    ,.gtwiz_reset_rx_datapath_out  (hb_gtwiz_reset_rx_datapath_DLx_int) // --  > output
  );
  // ===================================================================================================================
  // TRANSCEIVER WRAPPER INSTANCE
  // ===================================================================================================================

  // Instantiate the example design wrapper, mapping its enabled ports to per-channel internal signals and example
  // resources as appropriate
  DLx_phy_example_wrapper example_wrapper_inst (
    .gtyrxn_in                               (gtyrxn_int)
   ,.gtyrxp_in                               (gtyrxp_int)
   ,.gtytxn_out                              (gtytxn_int)
   ,.gtytxp_out                              (gtytxp_int)
   ,.gtwiz_userclk_tx_reset_in               (gtwiz_userclk_tx_reset_int)
   ,.gtwiz_userclk_tx_srcclk_out             (gtwiz_userclk_tx_srcclk_int)
   ,.gtwiz_userclk_tx_usrclk_out             (gtwiz_userclk_tx_usrclk_int)
   ,.gtwiz_userclk_tx_usrclk2_out            (gtwiz_userclk_tx_usrclk2_int)
//--   ,.gtwiz_userclk_tx_usrclk3_out            (gtwiz_userclk_tx_usrclk3_int)
   ,.gtwiz_userclk_tx_active_out             (gtwiz_userclk_tx_active_int)
   ,.gtwiz_userclk_rx_reset_in               (gtwiz_userclk_rx_reset_int)
   ,.gtwiz_userclk_rx_srcclk_out             (gtwiz_userclk_rx_srcclk_int)
//-- jda 5/17   ,.gtwiz_userclk_rx_usrclk_out             (gtwiz_userclk_rx_usrclk_int)
//-- jda 5/17   ,.gtwiz_userclk_rx_usrclk2_out            (gtwiz_userclk_rx_usrclk2_int)
   ,.gtwiz_userclk_rx_active_out             (gtwiz_userclk_rx_active_int)
   ,.gtwiz_buffbypass_tx_reset_in            (gtwiz_buffbypass_tx_reset_int)
   ,.gtwiz_buffbypass_tx_start_user_in       (gtwiz_buffbypass_tx_start_user_int)
   ,.gtwiz_buffbypass_tx_done_out            (gtwiz_buffbypass_tx_done_int)
   ,.gtwiz_buffbypass_tx_error_out           (gtwiz_buffbypass_tx_error_int)
   ,.gtwiz_buffbypass_rx_reset_in            (gtwiz_buffbypass_rx_reset_int)
   ,.gtwiz_buffbypass_rx_start_user_in       (gtwiz_buffbypass_rx_start_user_int)
   ,.gtwiz_buffbypass_rx_done_out            (gtwiz_buffbypass_rx_done_int)
   ,.gtwiz_buffbypass_rx_error_out           (gtwiz_buffbypass_rx_error_int)
   ,.gtwiz_reset_clk_freerun_in              ({1{hb_gtwiz_reset_clk_freerun_buf_int}})
   ,.gtwiz_reset_all_in                      ({1{hb_gtwiz_reset_all_int}})
   ,.gtwiz_reset_tx_pll_and_datapath_in      (gtwiz_reset_tx_pll_and_datapath_int)
   ,.gtwiz_reset_tx_datapath_in              (gtwiz_reset_tx_datapath_int)
   ,.gtwiz_reset_rx_pll_and_datapath_in      ({1{hb_gtwiz_reset_rx_pll_and_datapath_int}})
   ,.gtwiz_reset_rx_datapath_in              ({1{hb_gtwiz_reset_rx_datapath_int}})
   ,.gtwiz_reset_rx_cdr_stable_out           (gtwiz_reset_rx_cdr_stable_int)
   ,.gtwiz_reset_tx_done_out                 (gtwiz_reset_tx_done_int)
   ,.gtwiz_reset_rx_done_out                 (gtwiz_reset_rx_done_int)
   ,.gtwiz_userdata_tx_in                    (gtwiz_userdata_tx_int)
   ,.gtwiz_userdata_rx_out                   (gtwiz_userdata_rx_int)
   ,.gtrefclk01_in                           (gtrefclk01_int)
   ,.qpll1outclk_out                         (qpll1outclk_int)
   ,.qpll1outrefclk_out                      (qpll1outrefclk_int)
   ,.rxgearboxslip_in                        (rxgearboxslip_int)
//--   ,.rxpolarity_in                           (rxpolarity_int)                                                                                          
   ,.txheader_in                             (txheader_int)
   ,.txsequence_in                           (txsequence_int)
   ,.rxdatavalid_out                         (rxdatavalid_int) 
   ,.rxheader_out                            (rxheader_int)
   ,.rxheadervalid_out                       (rxheadervalid_int)
   ,.rxpmaresetdone_out                      (rxpmaresetdone_int)
   ,.rxstartofseq_out                        (rxstartofseq_int)
   ,.txpmaresetdone_out                      (txpmaresetdone_int)
   ,.txprgdivresetdone_out                   (txprgdivresetdone_int)
   
//--  ,.drpaddr_in                              (drpaddr_in)      // -- jda 02/20/17 
//--  ,.drpclk_in                               (drpclk_in)       // -- jda 02/20/17 
//--  ,.drpdi_in                                (drpdi_in)        // -- jda 02/20/17 
//--  ,.drpen_in                                (drpen_in)        // -- jda 02/20/17 
//--  ,.drpwe_in                                (drpwe_in)        // -- jda 02/20/17 
//--  ,.eyescanreset_in                         (eyescanreset_in) // -- jda 02/20/17 
   ,.rxlpmen_in                              (rxlpmen_in)      // -- jda 02/20/17 
   ,.rxrate_in                               (rxrate_in)       // -- jda 02/20/17 
   ,.txdiffctrl_in                           (txdiffctrl_in)   // -- jda 02/20/17 
   ,.txpostcursor_in                         (txpostcursor_in) // -- jda 02/20/17 
   ,.txprecursor_in                          (txprecursor_in)  // -- jda 02/20/17 
   ,.tx_clk_402MHz                           (tx_clk_402MHz)
   ,.tx_clk_201MHz                           (tx_clk_201MHz)
//--   ,.drpdo_out                               (drpdo_out)       // -- jda 02/20/17 
//--   ,.drprdy_out                              (drprdy_out)      // -- jda 02/20/17 
  );
  // --@ End of added comments


endmodule
