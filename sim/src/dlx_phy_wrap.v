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
  
  
  // Add port declarations to interface with DLx drivers
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
  input  [79:0]  drpaddr_in,
  input  [7:0]   drpclk_in,
  input  [127:0] drpdi_in,
  input  [7:0]   drpen_in,
  input  [7:0]   drpwe_in,
  input  [7:0]   eyescanreset_in, 
  input  [7:0]   rxlpmen_in,
  input  [23:0]  rxrate_in,
  input  [39:0]  txdiffctrl_in,
  input  [39:0]  txpostcursor_in,
  input  [39:0]  txprecursor_in,    
  output [127:0] drpdo_out, 
  output [7:0]   drprdy_out      
  
);


endmodule;
