`timescale 1ns / 1ps

module oc_fpga_top (

  // -- Reset
    input                 oc0_ocde
   ,input                 freerun_clk_p
   ,input                 freerun_clk_n

  // -- Phy Interface
   ,output                oc0_ch0_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc0_ch0_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc0_ch1_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc0_ch1_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc0_ch2_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc0_ch2_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc0_ch3_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc0_ch3_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc0_ch4_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc0_ch4_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc0_ch5_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc0_ch5_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc0_ch6_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc0_ch6_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc0_ch7_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc0_ch7_gtytxp_out     // -- XLX PHY transmit channels

   ,input                 oc0_ch0_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc0_ch0_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc0_ch1_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc0_ch1_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc0_ch2_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc0_ch2_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc0_ch3_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc0_ch3_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc0_ch4_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc0_ch4_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc0_ch5_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc0_ch5_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc0_ch6_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc0_ch6_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc0_ch7_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc0_ch7_gtyrxp_in      // -- XLX PHY receive channels

   ,input                 oc0_mgtrefclk1_x0y0_p  // -- XLX PHY transcieve clocks 156.25 MHz
   ,input                 oc0_mgtrefclk1_x0y0_n  // -- XLX PHY transcieve clocks 156.25 MHz

`ifdef DUAL_AFU
   ,input                 oc1_ocde

   ,output                oc1_ch0_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc1_ch0_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc1_ch1_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc1_ch1_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc1_ch2_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc1_ch2_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc1_ch3_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc1_ch3_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc1_ch4_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc1_ch4_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc1_ch5_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc1_ch5_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc1_ch6_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc1_ch6_gtytxp_out     // -- XLX PHY transmit channels
   ,output                oc1_ch7_gtytxn_out     // -- XLX PHY transmit channels
   ,output                oc1_ch7_gtytxp_out     // -- XLX PHY transmit channels

   ,input                 oc1_ch0_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc1_ch0_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc1_ch1_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc1_ch1_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc1_ch2_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc1_ch2_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc1_ch3_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc1_ch3_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc1_ch4_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc1_ch4_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc1_ch5_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc1_ch5_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc1_ch6_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc1_ch6_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 oc1_ch7_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 oc1_ch7_gtyrxp_in      // -- XLX PHY receive channels

   ,input                 oc1_mgtrefclk1_x0y0_p  // -- XLX PHY transcieve clocks 156.25 MHz
   ,input                 oc1_mgtrefclk1_x0y0_n  // -- XLX PHY transcieve clocks 156.25 MHz
`endif



// -- IMPORTANT: FLASH logic hasn't been hooked up for the Alphadata 9H7 card
`ifdef FLASH
   ,inout  FPGA_FLASH_CE2_L       // To/From FLASH of flash_sub_system.v
   ,inout  FPGA_FLASH_DQ4         // To/From FLASH of flash_sub_system.v
   ,inout  FPGA_FLASH_DQ5         // To/From FLASH of flash_sub_system.v
   ,inout  FPGA_FLASH_DQ6         // To/From FLASH of flash_sub_system.v
   ,inout  FPGA_FLASH_DQ7         // To/From FLASH of flash_sub_system.v
`endif
  // -- Interface between VPD Stub to external VPD EEPROM

  );

wire           oc0_clock_afu; //-- Frequency = clock_tlx/2
wire           oc0_clock_tlx;
wire           oc0_reset_n;
wire   [4:0]   oc0_ro_device;
wire   [31:0]  oc0_ro_dlx0_version;
wire   [31:0]  oc0_ro_tlx0_version;
wire           oc0_tlx_afu_ready;
wire   [6:0]   oc0_afu_tlx_cmd_initial_credit;
wire           oc0_afu_tlx_cmd_credit;
wire           oc0_tlx_afu_cmd_valid;
wire   [7:0]   oc0_tlx_afu_cmd_opcode;
wire   [1:0]   oc0_tlx_afu_cmd_dl;
wire           oc0_tlx_afu_cmd_end;
wire   [63:0]  oc0_tlx_afu_cmd_pa;
wire   [3:0]   oc0_tlx_afu_cmd_flag;
wire           oc0_tlx_afu_cmd_os;
wire   [15:0]  oc0_tlx_afu_cmd_capptag;
wire   [2:0]   oc0_tlx_afu_cmd_pl;
wire   [63:0]  oc0_tlx_afu_cmd_be;
wire   [6:0]   oc0_afu_tlx_resp_initial_credit;
wire           oc0_afu_tlx_resp_credit;
wire           oc0_tlx_afu_resp_valid;
wire   [7:0]   oc0_tlx_afu_resp_opcode;
wire   [15:0]  oc0_tlx_afu_resp_afutag;
wire   [3:0]   oc0_tlx_afu_resp_code;
wire   [5:0]   oc0_tlx_afu_resp_pg_size;
wire   [1:0]   oc0_tlx_afu_resp_dl;
wire   [1:0]   oc0_tlx_afu_resp_dp;
wire   [23:0]  oc0_tlx_afu_resp_host_tag;
wire   [3:0]   oc0_tlx_afu_resp_cache_state;
wire   [17:0]  oc0_tlx_afu_resp_addr_tag;
wire           oc0_afu_tlx_cmd_rd_req;
wire   [2:0]   oc0_afu_tlx_cmd_rd_cnt;
wire           oc0_tlx_afu_cmd_data_valid;
wire           oc0_tlx_afu_cmd_data_bdi;
wire   [511:0] oc0_tlx_afu_cmd_data_bus;
wire           oc0_afu_tlx_resp_rd_req;
wire   [2:0]   oc0_afu_tlx_resp_rd_cnt;
wire           oc0_tlx_afu_resp_data_valid;
wire           oc0_tlx_afu_resp_data_bdi;
wire   [511:0] oc0_tlx_afu_resp_data_bus;
wire           oc0_cfg0_tlx_xmit_tmpl_config_0;
wire           oc0_cfg0_tlx_xmit_tmpl_config_1;
wire           oc0_cfg0_tlx_xmit_tmpl_config_2;
wire           oc0_cfg0_tlx_xmit_tmpl_config_3;
wire   [3:0]   oc0_cfg0_tlx_xmit_rate_config_0;
wire   [3:0]   oc0_cfg0_tlx_xmit_rate_config_1;
wire   [3:0]   oc0_cfg0_tlx_xmit_rate_config_2;
wire   [3:0]   oc0_cfg0_tlx_xmit_rate_config_3;
wire           oc0_tlx_cfg0_in_rcv_tmpl_capability_0;
wire           oc0_tlx_cfg0_in_rcv_tmpl_capability_1;
wire           oc0_tlx_cfg0_in_rcv_tmpl_capability_2;
wire           oc0_tlx_cfg0_in_rcv_tmpl_capability_3;
wire   [3:0]   oc0_tlx_cfg0_in_rcv_rate_capability_0;
wire   [3:0]   oc0_tlx_cfg0_in_rcv_rate_capability_1;
wire   [3:0]   oc0_tlx_cfg0_in_rcv_rate_capability_2;
wire   [3:0]   oc0_tlx_cfg0_in_rcv_rate_capability_3;
wire   [3:0]   oc0_tlx_afu_cmd_initial_credit;
wire   [3:0]   oc0_tlx_afu_resp_initial_credit;
wire   [5:0]   oc0_tlx_afu_cmd_data_initial_credit;
wire   [5:0]   oc0_tlx_afu_resp_data_initial_credit;
wire           oc0_tlx_afu_cmd_credit;
wire           oc0_afu_tlx_cmd_valid;
wire   [7:0]   oc0_afu_tlx_cmd_opcode;
wire   [11:0]  oc0_afu_tlx_cmd_actag;
wire   [3:0]   oc0_afu_tlx_cmd_stream_id;
wire   [67:0]  oc0_afu_tlx_cmd_ea_or_obj;
wire   [15:0]  oc0_afu_tlx_cmd_afutag;
wire   [1:0]   oc0_afu_tlx_cmd_dl;
wire   [2:0]   oc0_afu_tlx_cmd_pl;
wire           oc0_afu_tlx_cmd_os;
wire   [63:0]  oc0_afu_tlx_cmd_be;
wire   [3:0]   oc0_afu_tlx_cmd_flag;
wire           oc0_afu_tlx_cmd_endian;
wire   [15:0]  oc0_afu_tlx_cmd_bdf;
wire   [19:0]  oc0_afu_tlx_cmd_pasid;
wire   [5:0]   oc0_afu_tlx_cmd_pg_size;
wire           oc0_tlx_afu_cmd_data_credit;
wire           oc0_afu_tlx_cdata_valid;
wire   [511:0] oc0_afu_tlx_cdata_bus;
wire           oc0_afu_tlx_cdata_bdi;
wire           oc0_tlx_afu_resp_credit;
wire           oc0_afu_tlx_resp_valid;
wire   [7:0]   oc0_afu_tlx_resp_opcode;
wire   [1:0]   oc0_afu_tlx_resp_dl;
wire   [15:0]  oc0_afu_tlx_resp_capptag;
wire   [1:0]   oc0_afu_tlx_resp_dp;
wire   [3:0]   oc0_afu_tlx_resp_code;
wire           oc0_tlx_afu_resp_data_credit;
wire           oc0_afu_tlx_rdata_valid;
wire   [511:0] oc0_afu_tlx_rdata_bus;
wire           oc0_afu_tlx_rdata_bdi;
wire           oc0_tlx_cfg0_valid;
wire   [7:0]   oc0_tlx_cfg0_opcode;
wire   [63:0]  oc0_tlx_cfg0_pa;
wire           oc0_tlx_cfg0_t;
wire   [2:0]   oc0_tlx_cfg0_pl;
wire   [15:0]  oc0_tlx_cfg0_capptag;
wire   [31:0]  oc0_tlx_cfg0_data_bus;
wire           oc0_tlx_cfg0_data_bdi;
wire   [3:0]   oc0_cfg0_tlx_initial_credit;
wire           oc0_cfg0_tlx_credit_return;
wire           oc0_cfg0_tlx_resp_valid;
wire   [7:0]   oc0_cfg0_tlx_resp_opcode;
wire   [15:0]  oc0_cfg0_tlx_resp_capptag;
wire   [3:0]   oc0_cfg0_tlx_resp_code;
wire   [3:0]   oc0_cfg0_tlx_rdata_offset;
wire   [31:0]  oc0_cfg0_tlx_rdata_bus;
wire           oc0_cfg0_tlx_rdata_bdi;
wire           oc0_tlx_cfg0_resp_ack;
wire           oc0_cfg_f1_octrl00_resync_credits;
wire   [14:0]  oc0_cfg_vpd_addr;
wire           oc0_cfg_vpd_wren;
wire   [31:0]  oc0_cfg_vpd_wdata;
wire           oc0_cfg_vpd_rden;
wire   [31:0]  oc0_vpd_cfg_rdata;
wire           oc0_vpd_cfg_done;
wire           oc0_vpd_err_unimplemented_addr;
wire   [1:0]   oc0_cfg_flsh_devsel;
wire   [13:0]  oc0_cfg_flsh_addr;
wire           oc0_cfg_flsh_wren;
wire   [31:0]  oc0_cfg_flsh_wdata;
wire           oc0_cfg_flsh_rden;
wire   [31:0]  oc0_flsh_cfg_rdata;
wire           oc0_flsh_cfg_done;
wire   [7:0]   oc0_flsh_cfg_status;
wire   [1:0]   oc0_flsh_cfg_bresp;
wire   [1:0]   oc0_flsh_cfg_rresp;
wire           oc0_cfg_flsh_expand_enable;
wire           oc0_cfg_flsh_expand_dir;
wire           oc0_cfg0_cff_fifo_overflow;        // Added to internal error vector sent to MMIO logic
wire  [7:0]    oc0_cfg0_bus_num;
wire  [4:0]    oc0_cfg0_device_num;
wire   [2:0]   oc0_cfg_function;
wire   [1:0]   oc0_cfg_portnum;
wire  [11:0]   oc0_cfg_addr;
wire  [31:0]   oc0_cfg_wdata;
wire  [31:0]   oc0_cfg_f1_rdata;                // CFG_F1 outputs
wire           oc0_cfg_f1_rdata_vld;
wire           oc0_cfg_wr_1B;
wire           oc0_cfg_wr_2B;
wire           oc0_cfg_wr_4B;
wire           oc0_cfg_rd;
wire           oc0_cfg_f1_bad_op_or_align;       // CFG_F1 outputs
wire           oc0_cfg_f1_addr_not_implemented;
wire [127:0]   oc0_cfg_errvec;
wire           oc0_cfg_errvec_valid;
wire           oc0_cfg0_rff_fifo_overflow;       // Added to internal error vector sent to MMIO logic
wire   [3:0]   oc0_cfg_f0_otl0_long_backoff_timer;
wire   [3:0]   oc0_cfg_f0_otl0_short_backoff_timer;
wire  [63:0]   oc0_cfg_f0_otl0_xmt_tmpl_config;
wire [255:0]   oc0_cfg_f0_otl0_xmt_rate_tmpl_config;
wire           oc0_cfg_f1_octrl00_fence_afu;   // Driven by FUNC1 inside lpc_func
wire           oc0_fen_afu_ready;
wire   [  6:0] oc0_afu_fen_cmd_initial_credit;
wire           oc0_afu_fen_cmd_credit;
wire           oc0_fen_afu_cmd_valid;
wire   [  7:0] oc0_fen_afu_cmd_opcode;
wire   [  1:0] oc0_fen_afu_cmd_dl;
wire           oc0_fen_afu_cmd_end;
wire   [ 63:0] oc0_fen_afu_cmd_pa;
wire   [  3:0] oc0_fen_afu_cmd_flag;
wire           oc0_fen_afu_cmd_os;
wire   [ 15:0] oc0_fen_afu_cmd_capptag;
wire   [  2:0] oc0_fen_afu_cmd_pl;
wire   [ 63:0] oc0_fen_afu_cmd_be;
wire   [  6:0] oc0_afu_fen_resp_initial_credit;
wire           oc0_afu_fen_resp_credit;
wire           oc0_fen_afu_resp_valid;
wire   [  7:0] oc0_fen_afu_resp_opcode;
wire   [ 15:0] oc0_fen_afu_resp_afutag;
wire   [  3:0] oc0_fen_afu_resp_code;
wire   [  5:0] oc0_fen_afu_resp_pg_size;
wire   [  1:0] oc0_fen_afu_resp_dl;
wire   [  1:0] oc0_fen_afu_resp_dp;
wire   [ 23:0] oc0_fen_afu_resp_host_tag;
wire   [  3:0] oc0_fen_afu_resp_cache_state;
wire   [ 17:0] oc0_fen_afu_resp_addr_tag;
wire           oc0_afu_fen_cmd_rd_req;
wire   [  2:0] oc0_afu_fen_cmd_rd_cnt;
wire           oc0_fen_afu_cmd_data_valid;
wire           oc0_fen_afu_cmd_data_bdi;
wire   [511:0] oc0_fen_afu_cmd_data_bus;
wire           oc0_afu_fen_resp_rd_req;
wire   [  2:0] oc0_afu_fen_resp_rd_cnt;
wire           oc0_fen_afu_resp_data_valid;
wire           oc0_fen_afu_resp_data_bdi;
wire   [511:0] oc0_fen_afu_resp_data_bus;
wire   [  3:0] oc0_fen_afu_cmd_initial_credit;
wire   [  3:0] oc0_fen_afu_resp_initial_credit;
wire   [  5:0] oc0_fen_afu_cmd_data_initial_credit;
wire   [  5:0] oc0_fen_afu_resp_data_initial_credit;
wire           oc0_fen_afu_cmd_credit;
wire           oc0_afu_fen_cmd_valid;
wire   [  7:0] oc0_afu_fen_cmd_opcode;
wire   [ 11:0] oc0_afu_fen_cmd_actag;
wire   [  3:0] oc0_afu_fen_cmd_stream_id;
wire   [ 67:0] oc0_afu_fen_cmd_ea_or_obj;
wire   [ 15:0] oc0_afu_fen_cmd_afutag;
wire   [  1:0] oc0_afu_fen_cmd_dl;
wire   [  2:0] oc0_afu_fen_cmd_pl;
wire           oc0_afu_fen_cmd_os;
wire   [ 63:0] oc0_afu_fen_cmd_be;
wire   [  3:0] oc0_afu_fen_cmd_flag;
wire           oc0_afu_fen_cmd_endian;
wire   [ 15:0] oc0_afu_fen_cmd_bdf;
wire   [ 19:0] oc0_afu_fen_cmd_pasid;
wire   [  5:0] oc0_afu_fen_cmd_pg_size;
wire           oc0_fen_afu_cmd_data_credit;
wire           oc0_afu_fen_cdata_valid;
wire   [511:0] oc0_afu_fen_cdata_bus;
wire           oc0_afu_fen_cdata_bdi;
wire           oc0_fen_afu_resp_credit;
wire           oc0_afu_fen_resp_valid;
wire   [  7:0] oc0_afu_fen_resp_opcode;
wire   [  1:0] oc0_afu_fen_resp_dl;
wire   [ 15:0] oc0_afu_fen_resp_capptag;
wire   [  1:0] oc0_afu_fen_resp_dp;
wire   [  3:0] oc0_afu_fen_resp_code;
wire           oc0_fen_afu_resp_data_credit;
wire           oc0_afu_fen_rdata_valid;
wire   [511:0] oc0_afu_fen_rdata_bus;
wire           oc0_afu_fen_rdata_bdi;
wire           oc0_reset = ~oc0_reset_n;   //-- Create positive active version of reset
wire [31:0]    oc0_f1_ro_csh_expansion_rom_bar;
wire [15:0]    oc0_f1_ro_csh_subsystem_id;
wire [15:0]    oc0_f1_ro_csh_subsystem_vendor_id;
wire [63:0]    oc0_f1_ro_csh_mmio_bar0_size;
wire [63:0]    oc0_f1_ro_csh_mmio_bar1_size;
wire [63:0]    oc0_f1_ro_csh_mmio_bar2_size;
wire           oc0_f1_ro_csh_mmio_bar0_prefetchable;
wire           oc0_f1_ro_csh_mmio_bar1_prefetchable;
wire           oc0_f1_ro_csh_mmio_bar2_prefetchable;
wire  [4:0]    oc0_f1_ro_pasid_max_pasid_width;
wire  [7:0]    oc0_f1_ro_ofunc_reset_duration;
wire           oc0_f1_ro_ofunc_afu_present;
wire  [4:0]    oc0_f1_ro_ofunc_max_afu_index;
wire  [7:0]    oc0_f1_ro_octrl00_reset_duration;
wire  [5:0]    oc0_f1_ro_octrl00_afu_control_index;
wire  [4:0]    oc0_f1_ro_octrl00_pasid_len_supported;
wire           oc0_f1_ro_octrl00_metadata_supported;
wire [11:0]    oc0_f1_ro_octrl00_actag_len_supported;

`ifdef DUAL_AFU
wire           oc1_clock_afu; //-- Frequency = clock_tlx/2
wire           oc1_clock_tlx;
wire           oc1_reset_n;
wire   [4:0]   oc1_ro_device;
wire   [31:0]  oc1_ro_dlx0_version;
wire   [31:0]  oc1_ro_tlx0_version;
wire           oc1_tlx_afu_ready;
wire   [6:0]   oc1_afu_tlx_cmd_initial_credit;
wire           oc1_afu_tlx_cmd_credit;
wire           oc1_tlx_afu_cmd_valid;
wire   [7:0]   oc1_tlx_afu_cmd_opcode;
wire   [1:0]   oc1_tlx_afu_cmd_dl;
wire           oc1_tlx_afu_cmd_end;
wire   [63:0]  oc1_tlx_afu_cmd_pa;
wire   [3:0]   oc1_tlx_afu_cmd_flag;
wire           oc1_tlx_afu_cmd_os;
wire   [15:0]  oc1_tlx_afu_cmd_capptag;
wire   [2:0]   oc1_tlx_afu_cmd_pl;
wire   [63:0]  oc1_tlx_afu_cmd_be;
wire   [6:0]   oc1_afu_tlx_resp_initial_credit;
wire           oc1_afu_tlx_resp_credit;
wire           oc1_tlx_afu_resp_valid;
wire   [7:0]   oc1_tlx_afu_resp_opcode;
wire   [15:0]  oc1_tlx_afu_resp_afutag;
wire   [3:0]   oc1_tlx_afu_resp_code;
wire   [5:0]   oc1_tlx_afu_resp_pg_size;
wire   [1:0]   oc1_tlx_afu_resp_dl;
wire   [1:0]   oc1_tlx_afu_resp_dp;
wire   [23:0]  oc1_tlx_afu_resp_host_tag;
wire   [3:0]   oc1_tlx_afu_resp_cache_state;
wire   [17:0]  oc1_tlx_afu_resp_addr_tag;
wire           oc1_afu_tlx_cmd_rd_req;
wire   [2:0]   oc1_afu_tlx_cmd_rd_cnt;
wire           oc1_tlx_afu_cmd_data_valid;
wire           oc1_tlx_afu_cmd_data_bdi;
wire   [511:0] oc1_tlx_afu_cmd_data_bus;
wire           oc1_afu_tlx_resp_rd_req;
wire   [2:0]   oc1_afu_tlx_resp_rd_cnt;
wire           oc1_tlx_afu_resp_data_valid;
wire           oc1_tlx_afu_resp_data_bdi;
wire   [511:0] oc1_tlx_afu_resp_data_bus;
wire           oc1_cfg0_tlx_xmit_tmpl_config_0;
wire           oc1_cfg0_tlx_xmit_tmpl_config_1;
wire           oc1_cfg0_tlx_xmit_tmpl_config_2;
wire           oc1_cfg0_tlx_xmit_tmpl_config_3;
wire   [3:0]   oc1_cfg0_tlx_xmit_rate_config_0;
wire   [3:0]   oc1_cfg0_tlx_xmit_rate_config_1;
wire   [3:0]   oc1_cfg0_tlx_xmit_rate_config_2;
wire   [3:0]   oc1_cfg0_tlx_xmit_rate_config_3;
wire           oc1_tlx_cfg0_in_rcv_tmpl_capability_0;
wire           oc1_tlx_cfg0_in_rcv_tmpl_capability_1;
wire           oc1_tlx_cfg0_in_rcv_tmpl_capability_2;
wire           oc1_tlx_cfg0_in_rcv_tmpl_capability_3;
wire   [3:0]   oc1_tlx_cfg0_in_rcv_rate_capability_0;
wire   [3:0]   oc1_tlx_cfg0_in_rcv_rate_capability_1;
wire   [3:0]   oc1_tlx_cfg0_in_rcv_rate_capability_2;
wire   [3:0]   oc1_tlx_cfg0_in_rcv_rate_capability_3;
wire   [3:0]   oc1_tlx_afu_cmd_initial_credit;
wire   [3:0]   oc1_tlx_afu_resp_initial_credit;
wire   [5:0]   oc1_tlx_afu_cmd_data_initial_credit;
wire   [5:0]   oc1_tlx_afu_resp_data_initial_credit;
wire           oc1_tlx_afu_cmd_credit;
wire           oc1_afu_tlx_cmd_valid;
wire   [7:0]   oc1_afu_tlx_cmd_opcode;
wire   [11:0]  oc1_afu_tlx_cmd_actag;
wire   [3:0]   oc1_afu_tlx_cmd_stream_id;
wire   [67:0]  oc1_afu_tlx_cmd_ea_or_obj;
wire   [15:0]  oc1_afu_tlx_cmd_afutag;
wire   [1:0]   oc1_afu_tlx_cmd_dl;
wire   [2:0]   oc1_afu_tlx_cmd_pl;
wire           oc1_afu_tlx_cmd_os;
wire   [63:0]  oc1_afu_tlx_cmd_be;
wire   [3:0]   oc1_afu_tlx_cmd_flag;
wire           oc1_afu_tlx_cmd_endian;
wire   [15:0]  oc1_afu_tlx_cmd_bdf;
wire   [19:0]  oc1_afu_tlx_cmd_pasid;
wire   [5:0]   oc1_afu_tlx_cmd_pg_size;
wire           oc1_tlx_afu_cmd_data_credit;
wire           oc1_afu_tlx_cdata_valid;
wire   [511:0] oc1_afu_tlx_cdata_bus;
wire           oc1_afu_tlx_cdata_bdi;
wire           oc1_tlx_afu_resp_credit;
wire           oc1_afu_tlx_resp_valid;
wire   [7:0]   oc1_afu_tlx_resp_opcode;
wire   [1:0]   oc1_afu_tlx_resp_dl;
wire   [15:0]  oc1_afu_tlx_resp_capptag;
wire   [1:0]   oc1_afu_tlx_resp_dp;
wire   [3:0]   oc1_afu_tlx_resp_code;
wire           oc1_tlx_afu_resp_data_credit;
wire           oc1_afu_tlx_rdata_valid;
wire   [511:0] oc1_afu_tlx_rdata_bus;
wire           oc1_afu_tlx_rdata_bdi;
wire           oc1_tlx_cfg0_valid;
wire   [7:0]   oc1_tlx_cfg0_opcode;
wire   [63:0]  oc1_tlx_cfg0_pa;
wire           oc1_tlx_cfg0_t;
wire   [2:0]   oc1_tlx_cfg0_pl;
wire   [15:0]  oc1_tlx_cfg0_capptag;
wire   [31:0]  oc1_tlx_cfg0_data_bus;
wire           oc1_tlx_cfg0_data_bdi;
wire   [3:0]   oc1_cfg0_tlx_initial_credit;
wire           oc1_cfg0_tlx_credit_return;
wire           oc1_cfg0_tlx_resp_valid;
wire   [7:0]   oc1_cfg0_tlx_resp_opcode;
wire   [15:0]  oc1_cfg0_tlx_resp_capptag;
wire   [3:0]   oc1_cfg0_tlx_resp_code;
wire   [3:0]   oc1_cfg0_tlx_rdata_offset;
wire   [31:0]  oc1_cfg0_tlx_rdata_bus;
wire           oc1_cfg0_tlx_rdata_bdi;
wire           oc1_tlx_cfg0_resp_ack;
wire           oc1_cfg_f1_octrl00_resync_credits;
wire   [14:0]  oc1_cfg_vpd_addr;
wire           oc1_cfg_vpd_wren;
wire   [31:0]  oc1_cfg_vpd_wdata;
wire           oc1_cfg_vpd_rden;
wire   [31:0]  oc1_vpd_cfg_rdata;
wire           oc1_vpd_cfg_done;
wire           oc1_vpd_err_unimplemented_addr;
wire   [1:0]   oc1_cfg_flsh_devsel;
wire   [13:0]  oc1_cfg_flsh_addr;
wire           oc1_cfg_flsh_wren;
wire   [31:0]  oc1_cfg_flsh_wdata;
wire           oc1_cfg_flsh_rden;
wire   [31:0]  oc1_flsh_cfg_rdata;
wire           oc1_flsh_cfg_done;
wire   [7:0]   oc1_flsh_cfg_status;
wire   [1:0]   oc1_flsh_cfg_bresp;
wire   [1:0]   oc1_flsh_cfg_rresp;
wire           oc1_cfg_flsh_expand_enable;
wire           oc1_cfg_flsh_expand_dir;
wire           oc1_cfg0_cff_fifo_overflow;        // Added to internal error vector sent to MMIO logic
wire  [7:0]    oc1_cfg0_bus_num;
wire  [4:0]    oc1_cfg0_device_num;
wire   [2:0]   oc1_cfg_function;
wire   [1:0]   oc1_cfg_portnum;
wire  [11:0]   oc1_cfg_addr;
wire  [31:0]   oc1_cfg_wdata;
wire  [31:0]   oc1_cfg_f1_rdata;                // CFG_F1 outputs
wire           oc1_cfg_f1_rdata_vld;
wire           oc1_cfg_wr_1B;
wire           oc1_cfg_wr_2B;
wire           oc1_cfg_wr_4B;
wire           oc1_cfg_rd;
wire           oc1_cfg_f1_bad_op_or_align;       // CFG_F1 outputs
wire           oc1_cfg_f1_addr_not_implemented;
wire [127:0]   oc1_cfg_errvec;
wire           oc1_cfg_errvec_valid;
wire           oc1_cfg0_rff_fifo_overflow;       // Added to internal error vector sent to MMIO logic
wire   [3:0]   oc1_cfg_f0_otl0_long_backoff_timer;
wire   [3:0]   oc1_cfg_f0_otl0_short_backoff_timer;
wire  [63:0]   oc1_cfg_f0_otl0_xmt_tmpl_config;
wire [255:0]   oc1_cfg_f0_otl0_xmt_rate_tmpl_config;
wire           oc1_cfg_f1_octrl00_fence_afu;   // Driven by FUNC1 inside lpc_func
wire           oc1_fen_afu_ready;
wire   [  6:0] oc1_afu_fen_cmd_initial_credit;
wire           oc1_afu_fen_cmd_credit;
wire           oc1_fen_afu_cmd_valid;
wire   [  7:0] oc1_fen_afu_cmd_opcode;
wire   [  1:0] oc1_fen_afu_cmd_dl;
wire           oc1_fen_afu_cmd_end;
wire   [ 63:0] oc1_fen_afu_cmd_pa;
wire   [  3:0] oc1_fen_afu_cmd_flag;
wire           oc1_fen_afu_cmd_os;
wire   [ 15:0] oc1_fen_afu_cmd_capptag;
wire   [  2:0] oc1_fen_afu_cmd_pl;
wire   [ 63:0] oc1_fen_afu_cmd_be;
wire   [  6:0] oc1_afu_fen_resp_initial_credit;
wire           oc1_afu_fen_resp_credit;
wire           oc1_fen_afu_resp_valid;
wire   [  7:0] oc1_fen_afu_resp_opcode;
wire   [ 15:0] oc1_fen_afu_resp_afutag;
wire   [  3:0] oc1_fen_afu_resp_code;
wire   [  5:0] oc1_fen_afu_resp_pg_size;
wire   [  1:0] oc1_fen_afu_resp_dl;
wire   [  1:0] oc1_fen_afu_resp_dp;
wire   [ 23:0] oc1_fen_afu_resp_host_tag;
wire   [  3:0] oc1_fen_afu_resp_cache_state;
wire   [ 17:0] oc1_fen_afu_resp_addr_tag;
wire           oc1_afu_fen_cmd_rd_req;
wire   [  2:0] oc1_afu_fen_cmd_rd_cnt;
wire           oc1_fen_afu_cmd_data_valid;
wire           oc1_fen_afu_cmd_data_bdi;
wire   [511:0] oc1_fen_afu_cmd_data_bus;
wire           oc1_afu_fen_resp_rd_req;
wire   [  2:0] oc1_afu_fen_resp_rd_cnt;
wire           oc1_fen_afu_resp_data_valid;
wire           oc1_fen_afu_resp_data_bdi;
wire   [511:0] oc1_fen_afu_resp_data_bus;
wire   [  3:0] oc1_fen_afu_cmd_initial_credit;
wire   [  3:0] oc1_fen_afu_resp_initial_credit;
wire   [  5:0] oc1_fen_afu_cmd_data_initial_credit;
wire   [  5:0] oc1_fen_afu_resp_data_initial_credit;
wire           oc1_fen_afu_cmd_credit;
wire           oc1_afu_fen_cmd_valid;
wire   [  7:0] oc1_afu_fen_cmd_opcode;
wire   [ 11:0] oc1_afu_fen_cmd_actag;
wire   [  3:0] oc1_afu_fen_cmd_stream_id;
wire   [ 67:0] oc1_afu_fen_cmd_ea_or_obj;
wire   [ 15:0] oc1_afu_fen_cmd_afutag;
wire   [  1:0] oc1_afu_fen_cmd_dl;
wire   [  2:0] oc1_afu_fen_cmd_pl;
wire           oc1_afu_fen_cmd_os;
wire   [ 63:0] oc1_afu_fen_cmd_be;
wire   [  3:0] oc1_afu_fen_cmd_flag;
wire           oc1_afu_fen_cmd_endian;
wire   [ 15:0] oc1_afu_fen_cmd_bdf;
wire   [ 19:0] oc1_afu_fen_cmd_pasid;
wire   [  5:0] oc1_afu_fen_cmd_pg_size;
wire           oc1_fen_afu_cmd_data_credit;
wire           oc1_afu_fen_cdata_valid;
wire   [511:0] oc1_afu_fen_cdata_bus;
wire           oc1_afu_fen_cdata_bdi;
wire           oc1_fen_afu_resp_credit;
wire           oc1_afu_fen_resp_valid;
wire   [  7:0] oc1_afu_fen_resp_opcode;
wire   [  1:0] oc1_afu_fen_resp_dl;
wire   [ 15:0] oc1_afu_fen_resp_capptag;
wire   [  1:0] oc1_afu_fen_resp_dp;
wire   [  3:0] oc1_afu_fen_resp_code;
wire           oc1_fen_afu_resp_data_credit;
wire           oc1_afu_fen_rdata_valid;
wire   [511:0] oc1_afu_fen_rdata_bus;
wire           oc1_afu_fen_rdata_bdi;
wire           oc1_reset = ~oc1_reset_n;   //-- Create positive active version of reset
wire [31:0]    oc1_f1_ro_csh_expansion_rom_bar;
wire [15:0]    oc1_f1_ro_csh_subsystem_id;
wire [15:0]    oc1_f1_ro_csh_subsystem_vendor_id;
wire [63:0]    oc1_f1_ro_csh_mmio_bar0_size;
wire [63:0]    oc1_f1_ro_csh_mmio_bar1_size;
wire [63:0]    oc1_f1_ro_csh_mmio_bar2_size;
wire           oc1_f1_ro_csh_mmio_bar0_prefetchable;
wire           oc1_f1_ro_csh_mmio_bar1_prefetchable;
wire           oc1_f1_ro_csh_mmio_bar2_prefetchable;
wire  [4:0]    oc1_f1_ro_pasid_max_pasid_width;
wire  [7:0]    oc1_f1_ro_ofunc_reset_duration;
wire           oc1_f1_ro_ofunc_afu_present;
wire  [4:0]    oc1_f1_ro_ofunc_max_afu_index;
wire  [7:0]    oc1_f1_ro_octrl00_reset_duration;
wire  [5:0]    oc1_f1_ro_octrl00_afu_control_index;
wire  [4:0]    oc1_f1_ro_octrl00_pasid_len_supported;
wire           oc1_f1_ro_octrl00_metadata_supported;
wire [11:0]    oc1_f1_ro_octrl00_actag_len_supported;
`endif

// ==============================================================================================================================
// @@@ Miscellaneous Signals
// ==============================================================================================================================
wire           freerun_clk; //-- Needed on top level because of dual AFU designs.  Have same freerun clock used by both OpenCAPI links


IBUFDS #(
   .DQS_BIAS("FALSE") // (FALSE, TRUE)
)
IBUFDS_freerun (
   .O  (freerun_clk),   // 1-bit output: Buffer output
   .I  (freerun_clk_p), // 1-bit input: Diff_p buffer input (connect directly to top-level port)
   .IB (freerun_clk_n)  // 1-bit input: Diff_n buffer input (connect directly to top-level port)
);


oc_bsp bsp0(
//-------------
//-- FPGA I/O
//-------------
  .ocde                                        (oc0_ocde                             ) //-- oc_bsp0:  input
 ,.freerun_clk                                 (freerun_clk                          ) //-- oc_bsp0:  input
 ,.ch0_gtytxn_out                              (oc0_ch0_gtytxn_out                   ) //-- oc_bsp0:  output
 ,.ch0_gtytxp_out                              (oc0_ch0_gtytxp_out                   ) //-- oc_bsp0:  output
 ,.ch1_gtytxn_out                              (oc0_ch1_gtytxn_out                   ) //-- oc_bsp0:  output
 ,.ch1_gtytxp_out                              (oc0_ch1_gtytxp_out                   ) //-- oc_bsp0:  output
 ,.ch2_gtytxn_out                              (oc0_ch2_gtytxn_out                   ) //-- oc_bsp0:  output
 ,.ch2_gtytxp_out                              (oc0_ch2_gtytxp_out                   ) //-- oc_bsp0:  output
 ,.ch3_gtytxn_out                              (oc0_ch3_gtytxn_out                   ) //-- oc_bsp0:  output
 ,.ch3_gtytxp_out                              (oc0_ch3_gtytxp_out                   ) //-- oc_bsp0:  output
 ,.ch4_gtytxn_out                              (oc0_ch4_gtytxn_out                   ) //-- oc_bsp0:  output
 ,.ch4_gtytxp_out                              (oc0_ch4_gtytxp_out                   ) //-- oc_bsp0:  output
 ,.ch5_gtytxn_out                              (oc0_ch5_gtytxn_out                   ) //-- oc_bsp0:  output
 ,.ch5_gtytxp_out                              (oc0_ch5_gtytxp_out                   ) //-- oc_bsp0:  output
 ,.ch6_gtytxn_out                              (oc0_ch6_gtytxn_out                   ) //-- oc_bsp0:  output
 ,.ch6_gtytxp_out                              (oc0_ch6_gtytxp_out                   ) //-- oc_bsp0:  output
 ,.ch7_gtytxn_out                              (oc0_ch7_gtytxn_out                   ) //-- oc_bsp0:  output
 ,.ch7_gtytxp_out                              (oc0_ch7_gtytxp_out                   ) //-- oc_bsp0:  output
 ,.ch0_gtyrxn_in                               (oc0_ch0_gtyrxn_in                    ) //-- oc_bsp0:  input
 ,.ch0_gtyrxp_in                               (oc0_ch0_gtyrxp_in                    ) //-- oc_bsp0:  input
 ,.ch1_gtyrxn_in                               (oc0_ch1_gtyrxn_in                    ) //-- oc_bsp0:  input
 ,.ch1_gtyrxp_in                               (oc0_ch1_gtyrxp_in                    ) //-- oc_bsp0:  input
 ,.ch2_gtyrxn_in                               (oc0_ch2_gtyrxn_in                    ) //-- oc_bsp0:  input
 ,.ch2_gtyrxp_in                               (oc0_ch2_gtyrxp_in                    ) //-- oc_bsp0:  input
 ,.ch3_gtyrxn_in                               (oc0_ch3_gtyrxn_in                    ) //-- oc_bsp0:  input
 ,.ch3_gtyrxp_in                               (oc0_ch3_gtyrxp_in                    ) //-- oc_bsp0:  input
 ,.ch4_gtyrxn_in                               (oc0_ch4_gtyrxn_in                    ) //-- oc_bsp0:  input
 ,.ch4_gtyrxp_in                               (oc0_ch4_gtyrxp_in                    ) //-- oc_bsp0:  input
 ,.ch5_gtyrxn_in                               (oc0_ch5_gtyrxn_in                    ) //-- oc_bsp0:  input
 ,.ch5_gtyrxp_in                               (oc0_ch5_gtyrxp_in                    ) //-- oc_bsp0:  input
 ,.ch6_gtyrxn_in                               (oc0_ch6_gtyrxn_in                    ) //-- oc_bsp0:  input
 ,.ch6_gtyrxp_in                               (oc0_ch6_gtyrxp_in                    ) //-- oc_bsp0:  input
 ,.ch7_gtyrxn_in                               (oc0_ch7_gtyrxn_in                    ) //-- oc_bsp0:  input
 ,.ch7_gtyrxp_in                               (oc0_ch7_gtyrxp_in                    ) //-- oc_bsp0:  input
 ,.mgtrefclk1_x0y0_p                           (oc0_mgtrefclk1_x0y0_p                ) //-- oc_bsp0:  input
 ,.mgtrefclk1_x0y0_n                           (oc0_mgtrefclk1_x0y0_n                ) //-- oc_bsp0:  input
`ifdef FLASH
 ,.FPGA_FLASH_CE2_L                            (FPGA_FLASH_CE2_L                     ) //-- oc_bsp0:  inout
 ,.FPGA_FLASH_DQ4                              (FPGA_FLASH_DQ4                       ) //-- oc_bsp0:  inout
 ,.FPGA_FLASH_DQ5                              (FPGA_FLASH_DQ5                       ) //-- oc_bsp0:  inout
 ,.FPGA_FLASH_DQ6                              (FPGA_FLASH_DQ6                       ) //-- oc_bsp0:  inout
 ,.FPGA_FLASH_DQ7                              (FPGA_FLASH_DQ7                       ) //-- oc_bsp0:  inout
`endif

//-------------
//-- AFU Ports
//-------------
 ,.clock_afu                                   (oc0_clock_afu                        ) // -- oc_bsp0:  output
 ,.clock_tlx                                   (oc0_clock_tlx                        ) // -- oc_bsp0:  output
 ,.reset_n                                     (oc0_reset_n                          ) // -- oc_bsp0:  output
 ,.ro_device                                   (oc0_ro_device                        ) // -- oc_bsp0:  output  [4:0]
 ,.ro_dlx_version                              (oc0_ro_dlx0_version                  ) // -- oc_bsp0:  output  [31:0]
 ,.ro_tlx_version                              (oc0_ro_tlx0_version                  ) // -- oc_bsp0:  output  [31:0]
 ,.tlx_afu_ready                               (oc0_tlx_afu_ready                    ) // -- oc_bsp0:  output
 ,.afu_tlx_cmd_initial_credit                  (oc0_afu_tlx_cmd_initial_credit       ) // -- oc_bsp0:  input   [6:0]
 ,.afu_tlx_cmd_credit                          (oc0_afu_tlx_cmd_credit               ) // -- oc_bsp0:  input
 ,.tlx_afu_cmd_valid                           (oc0_tlx_afu_cmd_valid                ) // -- oc_bsp0:  output
 ,.tlx_afu_cmd_opcode                          (oc0_tlx_afu_cmd_opcode               ) // -- oc_bsp0:  output  [7:0]
 ,.tlx_afu_cmd_dl                              (oc0_tlx_afu_cmd_dl                   ) // -- oc_bsp0:  output  [1:0]
 ,.tlx_afu_cmd_end                             (oc0_tlx_afu_cmd_end                  ) // -- oc_bsp0:  output
 ,.tlx_afu_cmd_pa                              (oc0_tlx_afu_cmd_pa                   ) // -- oc_bsp0:  output  [63:0]
 ,.tlx_afu_cmd_flag                            (oc0_tlx_afu_cmd_flag                 ) // -- oc_bsp0:  output  [3:0]
 ,.tlx_afu_cmd_os                              (oc0_tlx_afu_cmd_os                   ) // -- oc_bsp0:  output
 ,.tlx_afu_cmd_capptag                         (oc0_tlx_afu_cmd_capptag              ) // -- oc_bsp0:  output  [15:0]
 ,.tlx_afu_cmd_pl                              (oc0_tlx_afu_cmd_pl                   ) // -- oc_bsp0:  output  [2:0]
 ,.tlx_afu_cmd_be                              (oc0_tlx_afu_cmd_be                   ) // -- oc_bsp0:  output  [63:0]
 ,.afu_tlx_resp_initial_credit                 (oc0_afu_tlx_resp_initial_credit      ) // -- oc_bsp0:  input   [6:0]
 ,.afu_tlx_resp_credit                         (oc0_afu_tlx_resp_credit              ) // -- oc_bsp0:  input
 ,.tlx_afu_resp_valid                          (oc0_tlx_afu_resp_valid               ) // -- oc_bsp0:  output
 ,.tlx_afu_resp_opcode                         (oc0_tlx_afu_resp_opcode              ) // -- oc_bsp0:  output  [7:0]
 ,.tlx_afu_resp_afutag                         (oc0_tlx_afu_resp_afutag              ) // -- oc_bsp0:  output  [15:0]
 ,.tlx_afu_resp_code                           (oc0_tlx_afu_resp_code                ) // -- oc_bsp0:  output  [3:0]
 ,.tlx_afu_resp_pg_size                        (oc0_tlx_afu_resp_pg_size             ) // -- oc_bsp0:  output  [5:0]
 ,.tlx_afu_resp_dl                             (oc0_tlx_afu_resp_dl                  ) // -- oc_bsp0:  output  [1:0]
 ,.tlx_afu_resp_dp                             (oc0_tlx_afu_resp_dp                  ) // -- oc_bsp0:  output  [1:0]
 ,.tlx_afu_resp_host_tag                       (oc0_tlx_afu_resp_host_tag            ) // -- oc_bsp0:  output  [23:0]
 ,.tlx_afu_resp_cache_state                    (oc0_tlx_afu_resp_cache_state         ) // -- oc_bsp0:  output  [3:0]
 ,.tlx_afu_resp_addr_tag                       (oc0_tlx_afu_resp_addr_tag            ) // -- oc_bsp0:  output  [17:0]
 ,.afu_tlx_cmd_rd_req                          (oc0_afu_tlx_cmd_rd_req               ) // -- oc_bsp0:  input
 ,.afu_tlx_cmd_rd_cnt                          (oc0_afu_tlx_cmd_rd_cnt               ) // -- oc_bsp0:  input   [2:0]
 ,.tlx_afu_cmd_data_valid                      (oc0_tlx_afu_cmd_data_valid           ) // -- oc_bsp0:  output
 ,.tlx_afu_cmd_data_bdi                        (oc0_tlx_afu_cmd_data_bdi             ) // -- oc_bsp0:  output
 ,.tlx_afu_cmd_data_bus                        (oc0_tlx_afu_cmd_data_bus             ) // -- oc_bsp0:  output  [511:0]
 ,.afu_tlx_resp_rd_req                         (oc0_afu_tlx_resp_rd_req              ) // -- oc_bsp0:  input
 ,.afu_tlx_resp_rd_cnt                         (oc0_afu_tlx_resp_rd_cnt              ) // -- oc_bsp0:  input   [2:0]
 ,.tlx_afu_resp_data_valid                     (oc0_tlx_afu_resp_data_valid          ) // -- oc_bsp0:  output
 ,.tlx_afu_resp_data_bdi                       (oc0_tlx_afu_resp_data_bdi            ) // -- oc_bsp0:  output
 ,.tlx_afu_resp_data_bus                       (oc0_tlx_afu_resp_data_bus            ) // -- oc_bsp0:  output  [511:0]
 ,.cfg_tlx_xmit_tmpl_config_0                  (oc0_cfg0_tlx_xmit_tmpl_config_0      ) // -- oc_bsp0:  input
 ,.cfg_tlx_xmit_tmpl_config_1                  (oc0_cfg0_tlx_xmit_tmpl_config_1      ) // -- oc_bsp0:  input
 ,.cfg_tlx_xmit_tmpl_config_2                  (oc0_cfg0_tlx_xmit_tmpl_config_2      ) // -- oc_bsp0:  input
 ,.cfg_tlx_xmit_tmpl_config_3                  (oc0_cfg0_tlx_xmit_tmpl_config_3      ) // -- oc_bsp0:  input
 ,.cfg_tlx_xmit_rate_config_0                  (oc0_cfg0_tlx_xmit_rate_config_0      ) // -- oc_bsp0:  input   [3:0]
 ,.cfg_tlx_xmit_rate_config_1                  (oc0_cfg0_tlx_xmit_rate_config_1      ) // -- oc_bsp0:  input   [3:0]
 ,.cfg_tlx_xmit_rate_config_2                  (oc0_cfg0_tlx_xmit_rate_config_2      ) // -- oc_bsp0:  input   [3:0]
 ,.cfg_tlx_xmit_rate_config_3                  (oc0_cfg0_tlx_xmit_rate_config_3      ) // -- oc_bsp0:  input   [3:0]
 ,.tlx_cfg_in_rcv_tmpl_capability_0            (oc0_tlx_cfg0_in_rcv_tmpl_capability_0) // -- oc_bsp0:  output
 ,.tlx_cfg_in_rcv_tmpl_capability_1            (oc0_tlx_cfg0_in_rcv_tmpl_capability_1) // -- oc_bsp0:  output
 ,.tlx_cfg_in_rcv_tmpl_capability_2            (oc0_tlx_cfg0_in_rcv_tmpl_capability_2) // -- oc_bsp0:  output
 ,.tlx_cfg_in_rcv_tmpl_capability_3            (oc0_tlx_cfg0_in_rcv_tmpl_capability_3) // -- oc_bsp0:  output
 ,.tlx_cfg_in_rcv_rate_capability_0            (oc0_tlx_cfg0_in_rcv_rate_capability_0) // -- oc_bsp0:  output  [3:0]
 ,.tlx_cfg_in_rcv_rate_capability_1            (oc0_tlx_cfg0_in_rcv_rate_capability_1) // -- oc_bsp0:  output  [3:0]
 ,.tlx_cfg_in_rcv_rate_capability_2            (oc0_tlx_cfg0_in_rcv_rate_capability_2) // -- oc_bsp0:  output  [3:0]
 ,.tlx_cfg_in_rcv_rate_capability_3            (oc0_tlx_cfg0_in_rcv_rate_capability_3) // -- oc_bsp0:  output  [3:0]
 ,.tlx_afu_cmd_initial_credit                  (oc0_tlx_afu_cmd_initial_credit       ) // -- oc_bsp0:  output  [3:0]
 ,.tlx_afu_resp_initial_credit                 (oc0_tlx_afu_resp_initial_credit      ) // -- oc_bsp0:  output  [3:0]
 ,.tlx_afu_cmd_data_initial_credit             (oc0_tlx_afu_cmd_data_initial_credit  ) // -- oc_bsp0:  output  [5:0]
 ,.tlx_afu_resp_data_initial_credit            (oc0_tlx_afu_resp_data_initial_credit ) // -- oc_bsp0:  output  [5:0]
 ,.tlx_afu_cmd_credit                          (oc0_tlx_afu_cmd_credit               ) // -- oc_bsp0:  output
 ,.afu_tlx_cmd_valid                           (oc0_afu_tlx_cmd_valid                ) // -- oc_bsp0:  input
 ,.afu_tlx_cmd_opcode                          (oc0_afu_tlx_cmd_opcode               ) // -- oc_bsp0:  input   [7:0]
 ,.afu_tlx_cmd_actag                           (oc0_afu_tlx_cmd_actag                ) // -- oc_bsp0:  input   [11:0]
 ,.afu_tlx_cmd_stream_id                       (oc0_afu_tlx_cmd_stream_id            ) // -- oc_bsp0:  input   [3:0]
 ,.afu_tlx_cmd_ea_or_obj                       (oc0_afu_tlx_cmd_ea_or_obj            ) // -- oc_bsp0:  input   [67:0]
 ,.afu_tlx_cmd_afutag                          (oc0_afu_tlx_cmd_afutag               ) // -- oc_bsp0:  input   [15:0]
 ,.afu_tlx_cmd_dl                              (oc0_afu_tlx_cmd_dl                   ) // -- oc_bsp0:  input   [1:0]
 ,.afu_tlx_cmd_pl                              (oc0_afu_tlx_cmd_pl                   ) // -- oc_bsp0:  input   [2:0]
 ,.afu_tlx_cmd_os                              (oc0_afu_tlx_cmd_os                   ) // -- oc_bsp0:  input
 ,.afu_tlx_cmd_be                              (oc0_afu_tlx_cmd_be                   ) // -- oc_bsp0:  input   [63:0]
 ,.afu_tlx_cmd_flag                            (oc0_afu_tlx_cmd_flag                 ) // -- oc_bsp0:  input   [3:0]
 ,.afu_tlx_cmd_endian                          (oc0_afu_tlx_cmd_endian               ) // -- oc_bsp0:  input
 ,.afu_tlx_cmd_bdf                             (oc0_afu_tlx_cmd_bdf                  ) // -- oc_bsp0:  input   [15:0]
 ,.afu_tlx_cmd_pasid                           (oc0_afu_tlx_cmd_pasid                ) // -- oc_bsp0:  input   [19:0]
 ,.afu_tlx_cmd_pg_size                         (oc0_afu_tlx_cmd_pg_size              ) // -- oc_bsp0:  input   [5:0]
 ,.tlx_afu_cmd_data_credit                     (oc0_tlx_afu_cmd_data_credit          ) // -- oc_bsp0:  output
 ,.afu_tlx_cdata_valid                         (oc0_afu_tlx_cdata_valid              ) // -- oc_bsp0:  input
 ,.afu_tlx_cdata_bus                           (oc0_afu_tlx_cdata_bus                ) // -- oc_bsp0:  input   [511:0]
 ,.afu_tlx_cdata_bdi                           (oc0_afu_tlx_cdata_bdi                ) // -- oc_bsp0:  input
 ,.tlx_afu_resp_credit                         (oc0_tlx_afu_resp_credit              ) // -- oc_bsp0:  output
 ,.afu_tlx_resp_valid                          (oc0_afu_tlx_resp_valid               ) // -- oc_bsp0:  input
 ,.afu_tlx_resp_opcode                         (oc0_afu_tlx_resp_opcode              ) // -- oc_bsp0:  input   [7:0]
 ,.afu_tlx_resp_dl                             (oc0_afu_tlx_resp_dl                  ) // -- oc_bsp0:  input   [1:0]
 ,.afu_tlx_resp_capptag                        (oc0_afu_tlx_resp_capptag             ) // -- oc_bsp0:  input   [15:0]
 ,.afu_tlx_resp_dp                             (oc0_afu_tlx_resp_dp                  ) // -- oc_bsp0:  input   [1:0]
 ,.afu_tlx_resp_code                           (oc0_afu_tlx_resp_code                ) // -- oc_bsp0:  input   [3:0]
 ,.tlx_afu_resp_data_credit                    (oc0_tlx_afu_resp_data_credit         ) // -- oc_bsp0:  output
 ,.afu_tlx_rdata_valid                         (oc0_afu_tlx_rdata_valid              ) // -- oc_bsp0:  input
 ,.afu_tlx_rdata_bus                           (oc0_afu_tlx_rdata_bus                ) // -- oc_bsp0:  input   [511:0]
 ,.afu_tlx_rdata_bdi                           (oc0_afu_tlx_rdata_bdi                ) // -- oc_bsp0:  input
 ,.tlx_cfg_valid                               (oc0_tlx_cfg0_valid                   ) // -- oc_bsp0:  output
 ,.tlx_cfg_opcode                              (oc0_tlx_cfg0_opcode                  ) // -- oc_bsp0:  output  [7:0]
 ,.tlx_cfg_pa                                  (oc0_tlx_cfg0_pa                      ) // -- oc_bsp0:  output  [63:0]
 ,.tlx_cfg_t                                   (oc0_tlx_cfg0_t                       ) // -- oc_bsp0:  output
 ,.tlx_cfg_pl                                  (oc0_tlx_cfg0_pl                      ) // -- oc_bsp0:  output  [2:0]
 ,.tlx_cfg_capptag                             (oc0_tlx_cfg0_capptag                 ) // -- oc_bsp0:  output  [15:0]
 ,.tlx_cfg_data_bus                            (oc0_tlx_cfg0_data_bus                ) // -- oc_bsp0:  output  [31:0]
 ,.tlx_cfg_data_bdi                            (oc0_tlx_cfg0_data_bdi                ) // -- oc_bsp0:  output
 ,.cfg_tlx_initial_credit                      (oc0_cfg0_tlx_initial_credit          ) // -- oc_bsp0:  input   [3:0]
 ,.cfg_tlx_credit_return                       (oc0_cfg0_tlx_credit_return           ) // -- oc_bsp0:  input
 ,.cfg_tlx_resp_valid                          (oc0_cfg0_tlx_resp_valid              ) // -- oc_bsp0:  input
 ,.cfg_tlx_resp_opcode                         (oc0_cfg0_tlx_resp_opcode             ) // -- oc_bsp0:  input   [7:0]
 ,.cfg_tlx_resp_capptag                        (oc0_cfg0_tlx_resp_capptag            ) // -- oc_bsp0:  input   [15:0]
 ,.cfg_tlx_resp_code                           (oc0_cfg0_tlx_resp_code               ) // -- oc_bsp0:  input   [3:0]
 ,.cfg_tlx_rdata_offset                        (oc0_cfg0_tlx_rdata_offset            ) // -- oc_bsp0:  input   [3:0]
 ,.cfg_tlx_rdata_bus                           (oc0_cfg0_tlx_rdata_bus               ) // -- oc_bsp0:  input   [31:0]
 ,.cfg_tlx_rdata_bdi                           (oc0_cfg0_tlx_rdata_bdi               ) // -- oc_bsp0:  input
 ,.tlx_cfg_resp_ack                            (oc0_tlx_cfg0_resp_ack                ) // -- oc_bsp0:  output
 ,.cfg_f1_octrl00_resync_credits               (oc0_cfg_f1_octrl00_resync_credits    ) // -- oc_bsp0:  input
 ,.cfg_vpd_addr                                (oc0_cfg_vpd_addr                     ) // -- oc_bsp0:  input   [14:0]
 ,.cfg_vpd_wren                                (oc0_cfg_vpd_wren                     ) // -- oc_bsp0:  input
 ,.cfg_vpd_wdata                               (oc0_cfg_vpd_wdata                    ) // -- oc_bsp0:  input   [31:0]
 ,.cfg_vpd_rden                                (oc0_cfg_vpd_rden                     ) // -- oc_bsp0:  input
 ,.vpd_cfg_rdata                               (oc0_vpd_cfg_rdata                    ) // -- oc_bsp0:  output  [31:0]
 ,.vpd_cfg_done                                (oc0_vpd_cfg_done                     ) // -- oc_bsp0:  output
 ,.vpd_err_unimplemented_addr                  (oc0_vpd_err_unimplemented_addr       ) // -- oc_bsp0:  output
 ,.cfg_flsh_devsel                             (oc0_cfg_flsh_devsel                  ) // -- oc_bsp0:  input   [1:0]
 ,.cfg_flsh_addr                               (oc0_cfg_flsh_addr                    ) // -- oc_bsp0:  input   [13:0]
 ,.cfg_flsh_wren                               (oc0_cfg_flsh_wren                    ) // -- oc_bsp0:  input
 ,.cfg_flsh_wdata                              (oc0_cfg_flsh_wdata                   ) // -- oc_bsp0:  input   [31:0]
 ,.cfg_flsh_rden                               (oc0_cfg_flsh_rden                    ) // -- oc_bsp0:  input
 ,.flsh_cfg_rdata                              (oc0_flsh_cfg_rdata                   ) // -- oc_bsp0:  output  [31:0]
 ,.flsh_cfg_done                               (oc0_flsh_cfg_done                    ) // -- oc_bsp0:  output
 ,.flsh_cfg_status                             (oc0_flsh_cfg_status                  ) // -- oc_bsp0:  output  [7:0]
 ,.flsh_cfg_bresp                              (oc0_flsh_cfg_bresp                   ) // -- oc_bsp0:  output  [1:0]
 ,.flsh_cfg_rresp                              (oc0_flsh_cfg_rresp                   ) // -- oc_bsp0:  output  [1:0]
 ,.cfg_flsh_expand_enable                      (oc0_cfg_flsh_expand_enable           ) // -- oc_bsp0:  input
 ,.cfg_flsh_expand_dir                         (oc0_cfg_flsh_expand_dir              ) // -- oc_bsp0:  input
);

oc_cfg cfg0 (
  .clock                             (oc0_clock_tlx                        ) // -- oc_cfg0:  input
 ,.reset_n                           (oc0_reset_n                          ) // -- oc_cfg0:  input
 ,.ro_device                         (oc0_ro_device                        ) // -- oc_cfg0:  input  [4:0]
 ,.ro_dlx0_version                   (oc0_ro_dlx0_version                  ) // -- oc_cfg0:  input  [31:0]
 ,.ro_tlx0_version                   (oc0_ro_tlx0_version                  ) // -- oc_cfg0:  input  [31:0]
 ,.tlx_afu_ready                     (oc0_tlx_afu_ready                    ) // -- oc_cfg0:  input
 ,.afu_tlx_cmd_initial_credit        (oc0_afu_tlx_cmd_initial_credit       ) // -- oc_cfg0:  output [6:0]
 ,.afu_tlx_cmd_credit                (oc0_afu_tlx_cmd_credit               ) // -- oc_cfg0:  output
 ,.tlx_afu_cmd_valid                 (oc0_tlx_afu_cmd_valid                ) // -- oc_cfg0:  input
 ,.tlx_afu_cmd_opcode                (oc0_tlx_afu_cmd_opcode               ) // -- oc_cfg0:  input  [7:0]
 ,.tlx_afu_cmd_dl                    (oc0_tlx_afu_cmd_dl                   ) // -- oc_cfg0:  input  [1:0]
 ,.tlx_afu_cmd_end                   (oc0_tlx_afu_cmd_end                  ) // -- oc_cfg0:  input
 ,.tlx_afu_cmd_pa                    (oc0_tlx_afu_cmd_pa                   ) // -- oc_cfg0:  input  [63:0]
 ,.tlx_afu_cmd_flag                  (oc0_tlx_afu_cmd_flag                 ) // -- oc_cfg0:  input  [3:0]
 ,.tlx_afu_cmd_os                    (oc0_tlx_afu_cmd_os                   ) // -- oc_cfg0:  input
 ,.tlx_afu_cmd_capptag               (oc0_tlx_afu_cmd_capptag              ) // -- oc_cfg0:  input  [15:0]
 ,.tlx_afu_cmd_pl                    (oc0_tlx_afu_cmd_pl                   ) // -- oc_cfg0:  input  [2:0]
 ,.tlx_afu_cmd_be                    (oc0_tlx_afu_cmd_be                   ) // -- oc_cfg0:  input  [63:0]
 ,.afu_tlx_resp_initial_credit       (oc0_afu_tlx_resp_initial_credit      ) // -- oc_cfg0:  output [6:0]
 ,.afu_tlx_resp_credit               (oc0_afu_tlx_resp_credit              ) // -- oc_cfg0:  output
 ,.tlx_afu_resp_valid                (oc0_tlx_afu_resp_valid               ) // -- oc_cfg0:  input
 ,.tlx_afu_resp_opcode               (oc0_tlx_afu_resp_opcode              ) // -- oc_cfg0:  input  [7:0]
 ,.tlx_afu_resp_afutag               (oc0_tlx_afu_resp_afutag              ) // -- oc_cfg0:  input  [15:0]
 ,.tlx_afu_resp_code                 (oc0_tlx_afu_resp_code                ) // -- oc_cfg0:  input  [3:0]
 ,.tlx_afu_resp_pg_size              (oc0_tlx_afu_resp_pg_size             ) // -- oc_cfg0:  input  [5:0]
 ,.tlx_afu_resp_dl                   (oc0_tlx_afu_resp_dl                  ) // -- oc_cfg0:  input  [1:0]
 ,.tlx_afu_resp_dp                   (oc0_tlx_afu_resp_dp                  ) // -- oc_cfg0:  input  [1:0]
 ,.tlx_afu_resp_host_tag             (oc0_tlx_afu_resp_host_tag            ) // -- oc_cfg0:  input  [23:0]
 ,.tlx_afu_resp_cache_state          (oc0_tlx_afu_resp_cache_state         ) // -- oc_cfg0:  input  [3:0]
 ,.tlx_afu_resp_addr_tag             (oc0_tlx_afu_resp_addr_tag            ) // -- oc_cfg0:  input  [17:0]
 ,.afu_tlx_cmd_rd_req                (oc0_afu_tlx_cmd_rd_req               ) // -- oc_cfg0:  output
 ,.afu_tlx_cmd_rd_cnt                (oc0_afu_tlx_cmd_rd_cnt               ) // -- oc_cfg0:  output [2:0]
 ,.tlx_afu_cmd_data_valid            (oc0_tlx_afu_cmd_data_valid           ) // -- oc_cfg0:  input
 ,.tlx_afu_cmd_data_bdi              (oc0_tlx_afu_cmd_data_bdi             ) // -- oc_cfg0:  input
 ,.tlx_afu_cmd_data_bus              (oc0_tlx_afu_cmd_data_bus             ) // -- oc_cfg0:  input  [511:0]
 ,.afu_tlx_resp_rd_req               (oc0_afu_tlx_resp_rd_req              ) // -- oc_cfg0:  output
 ,.afu_tlx_resp_rd_cnt               (oc0_afu_tlx_resp_rd_cnt              ) // -- oc_cfg0:  output [2:0]
 ,.tlx_afu_resp_data_valid           (oc0_tlx_afu_resp_data_valid          ) // -- oc_cfg0:  input
 ,.tlx_afu_resp_data_bdi             (oc0_tlx_afu_resp_data_bdi            ) // -- oc_cfg0:  input
 ,.tlx_afu_resp_data_bus             (oc0_tlx_afu_resp_data_bus            ) // -- oc_cfg0:  input  [511:0]
 ,.cfg0_tlx_xmit_tmpl_config_0       (oc0_cfg0_tlx_xmit_tmpl_config_0      ) // -- oc_cfg0:  output
 ,.cfg0_tlx_xmit_tmpl_config_1       (oc0_cfg0_tlx_xmit_tmpl_config_1      ) // -- oc_cfg0:  output
 ,.cfg0_tlx_xmit_tmpl_config_2       (oc0_cfg0_tlx_xmit_tmpl_config_2      ) // -- oc_cfg0:  output
 ,.cfg0_tlx_xmit_tmpl_config_3       (oc0_cfg0_tlx_xmit_tmpl_config_3      ) // -- oc_cfg0:  output
 ,.cfg0_tlx_xmit_rate_config_0       (oc0_cfg0_tlx_xmit_rate_config_0      ) // -- oc_cfg0:  output [3:0]
 ,.cfg0_tlx_xmit_rate_config_1       (oc0_cfg0_tlx_xmit_rate_config_1      ) // -- oc_cfg0:  output [3:0]
 ,.cfg0_tlx_xmit_rate_config_2       (oc0_cfg0_tlx_xmit_rate_config_2      ) // -- oc_cfg0:  output [3:0]
 ,.cfg0_tlx_xmit_rate_config_3       (oc0_cfg0_tlx_xmit_rate_config_3      ) // -- oc_cfg0:  output [3:0]
 ,.tlx_cfg0_in_rcv_tmpl_capability_0 (oc0_tlx_cfg0_in_rcv_tmpl_capability_0) // -- oc_cfg0:  input
 ,.tlx_cfg0_in_rcv_tmpl_capability_1 (oc0_tlx_cfg0_in_rcv_tmpl_capability_1) // -- oc_cfg0:  input
 ,.tlx_cfg0_in_rcv_tmpl_capability_2 (oc0_tlx_cfg0_in_rcv_tmpl_capability_2) // -- oc_cfg0:  input
 ,.tlx_cfg0_in_rcv_tmpl_capability_3 (oc0_tlx_cfg0_in_rcv_tmpl_capability_3) // -- oc_cfg0:  input
 ,.tlx_cfg0_in_rcv_rate_capability_0 (oc0_tlx_cfg0_in_rcv_rate_capability_0) // -- oc_cfg0:  input  [3:0]
 ,.tlx_cfg0_in_rcv_rate_capability_1 (oc0_tlx_cfg0_in_rcv_rate_capability_1) // -- oc_cfg0:  input  [3:0]
 ,.tlx_cfg0_in_rcv_rate_capability_2 (oc0_tlx_cfg0_in_rcv_rate_capability_2) // -- oc_cfg0:  input  [3:0]
 ,.tlx_cfg0_in_rcv_rate_capability_3 (oc0_tlx_cfg0_in_rcv_rate_capability_3) // -- oc_cfg0:  input  [3:0]
 ,.tlx_afu_cmd_initial_credit        (oc0_tlx_afu_cmd_initial_credit       ) // -- oc_cfg0:  input  [3:0]
 ,.tlx_afu_resp_initial_credit       (oc0_tlx_afu_resp_initial_credit      ) // -- oc_cfg0:  input  [3:0]
 ,.tlx_afu_cmd_data_initial_credit   (oc0_tlx_afu_cmd_data_initial_credit  ) // -- oc_cfg0:  input  [5:0]
 ,.tlx_afu_resp_data_initial_credit  (oc0_tlx_afu_resp_data_initial_credit ) // -- oc_cfg0:  input  [5:0]
 ,.tlx_afu_cmd_credit                (oc0_tlx_afu_cmd_credit               ) // -- oc_cfg0:  input
 ,.afu_tlx_cmd_valid                 (oc0_afu_tlx_cmd_valid                ) // -- oc_cfg0:  output
 ,.afu_tlx_cmd_opcode                (oc0_afu_tlx_cmd_opcode               ) // -- oc_cfg0:  output [7:0]
 ,.afu_tlx_cmd_actag                 (oc0_afu_tlx_cmd_actag                ) // -- oc_cfg0:  output [11:0]
 ,.afu_tlx_cmd_stream_id             (oc0_afu_tlx_cmd_stream_id            ) // -- oc_cfg0:  output [3:0]
 ,.afu_tlx_cmd_ea_or_obj             (oc0_afu_tlx_cmd_ea_or_obj            ) // -- oc_cfg0:  output [67:0]
 ,.afu_tlx_cmd_afutag                (oc0_afu_tlx_cmd_afutag               ) // -- oc_cfg0:  output [15:0]
 ,.afu_tlx_cmd_dl                    (oc0_afu_tlx_cmd_dl                   ) // -- oc_cfg0:  output [1:0]
 ,.afu_tlx_cmd_pl                    (oc0_afu_tlx_cmd_pl                   ) // -- oc_cfg0:  output [2:0]
 ,.afu_tlx_cmd_os                    (oc0_afu_tlx_cmd_os                   ) // -- oc_cfg0:  output
 ,.afu_tlx_cmd_be                    (oc0_afu_tlx_cmd_be                   ) // -- oc_cfg0:  output [63:0]
 ,.afu_tlx_cmd_flag                  (oc0_afu_tlx_cmd_flag                 ) // -- oc_cfg0:  output [3:0]
 ,.afu_tlx_cmd_endian                (oc0_afu_tlx_cmd_endian               ) // -- oc_cfg0:  output
 ,.afu_tlx_cmd_bdf                   (oc0_afu_tlx_cmd_bdf                  ) // -- oc_cfg0:  output [15:0]
 ,.afu_tlx_cmd_pasid                 (oc0_afu_tlx_cmd_pasid                ) // -- oc_cfg0:  output [19:0]
 ,.afu_tlx_cmd_pg_size               (oc0_afu_tlx_cmd_pg_size              ) // -- oc_cfg0:  output [5:0]
 ,.tlx_afu_cmd_data_credit           (oc0_tlx_afu_cmd_data_credit          ) // -- oc_cfg0:  input
 ,.afu_tlx_cdata_valid               (oc0_afu_tlx_cdata_valid              ) // -- oc_cfg0:  output
 ,.afu_tlx_cdata_bus                 (oc0_afu_tlx_cdata_bus                ) // -- oc_cfg0:  output [511:0]
 ,.afu_tlx_cdata_bdi                 (oc0_afu_tlx_cdata_bdi                ) // -- oc_cfg0:  output
 ,.tlx_afu_resp_credit               (oc0_tlx_afu_resp_credit              ) // -- oc_cfg0:  input
 ,.afu_tlx_resp_valid                (oc0_afu_tlx_resp_valid               ) // -- oc_cfg0:  output
 ,.afu_tlx_resp_opcode               (oc0_afu_tlx_resp_opcode              ) // -- oc_cfg0:  output [7:0]
 ,.afu_tlx_resp_dl                   (oc0_afu_tlx_resp_dl                  ) // -- oc_cfg0:  output [1:0]
 ,.afu_tlx_resp_capptag              (oc0_afu_tlx_resp_capptag             ) // -- oc_cfg0:  output [15:0]
 ,.afu_tlx_resp_dp                   (oc0_afu_tlx_resp_dp                  ) // -- oc_cfg0:  output [1:0]
 ,.afu_tlx_resp_code                 (oc0_afu_tlx_resp_code                ) // -- oc_cfg0:  output [3:0]
 ,.tlx_afu_resp_data_credit          (oc0_tlx_afu_resp_data_credit         ) // -- oc_cfg0:  input
 ,.afu_tlx_rdata_valid               (oc0_afu_tlx_rdata_valid              ) // -- oc_cfg0:  output
 ,.afu_tlx_rdata_bus                 (oc0_afu_tlx_rdata_bus                ) // -- oc_cfg0:  output [511:0]
 ,.afu_tlx_rdata_bdi                 (oc0_afu_tlx_rdata_bdi                ) // -- oc_cfg0:  output
 ,.tlx_cfg0_valid                    (oc0_tlx_cfg0_valid                   ) // -- oc_cfg0:  input
 ,.tlx_cfg0_opcode                   (oc0_tlx_cfg0_opcode                  ) // -- oc_cfg0:  input  [7:0]
 ,.tlx_cfg0_pa                       (oc0_tlx_cfg0_pa                      ) // -- oc_cfg0:  input  [63:0]
 ,.tlx_cfg0_t                        (oc0_tlx_cfg0_t                       ) // -- oc_cfg0:  input
 ,.tlx_cfg0_pl                       (oc0_tlx_cfg0_pl                      ) // -- oc_cfg0:  input  [2:0]
 ,.tlx_cfg0_capptag                  (oc0_tlx_cfg0_capptag                 ) // -- oc_cfg0:  input  [15:0]
 ,.tlx_cfg0_data_bus                 (oc0_tlx_cfg0_data_bus                ) // -- oc_cfg0:  input  [31:0]
 ,.tlx_cfg0_data_bdi                 (oc0_tlx_cfg0_data_bdi                ) // -- oc_cfg0:  input
 ,.cfg0_tlx_initial_credit           (oc0_cfg0_tlx_initial_credit          ) // -- oc_cfg0:  output [3:0]
 ,.cfg0_tlx_credit_return            (oc0_cfg0_tlx_credit_return           ) // -- oc_cfg0:  output
 ,.cfg0_tlx_resp_valid               (oc0_cfg0_tlx_resp_valid              ) // -- oc_cfg0:  output
 ,.cfg0_tlx_resp_opcode              (oc0_cfg0_tlx_resp_opcode             ) // -- oc_cfg0:  output [7:0]
 ,.cfg0_tlx_resp_capptag             (oc0_cfg0_tlx_resp_capptag            ) // -- oc_cfg0:  output [15:0]
 ,.cfg0_tlx_resp_code                (oc0_cfg0_tlx_resp_code               ) // -- oc_cfg0:  output [3:0]
 ,.cfg0_tlx_rdata_offset             (oc0_cfg0_tlx_rdata_offset            ) // -- oc_cfg0:  output [3:0]
 ,.cfg0_tlx_rdata_bus                (oc0_cfg0_tlx_rdata_bus               ) // -- oc_cfg0:  output [31:0]
 ,.cfg0_tlx_rdata_bdi                (oc0_cfg0_tlx_rdata_bdi               ) // -- oc_cfg0:  output
 ,.tlx_cfg0_resp_ack                 (oc0_tlx_cfg0_resp_ack                ) // -- oc_cfg0:  input
 ,.cfg_vpd_addr                      (oc0_cfg_vpd_addr                     ) // -- oc_cfg0:  output [14:0]
 ,.cfg_vpd_wren                      (oc0_cfg_vpd_wren                     ) // -- oc_cfg0:  output
 ,.cfg_vpd_wdata                     (oc0_cfg_vpd_wdata                    ) // -- oc_cfg0:  output [31:0]
 ,.cfg_vpd_rden                      (oc0_cfg_vpd_rden                     ) // -- oc_cfg0:  output
 ,.vpd_cfg_rdata                     (oc0_vpd_cfg_rdata                    ) // -- oc_cfg0:  input  [31:0]
 ,.vpd_cfg_done                      (oc0_vpd_cfg_done                     ) // -- oc_cfg0:  input
 ,.cfg_flsh_devsel                   (oc0_cfg_flsh_devsel                  ) // -- oc_cfg0:  output [1:0]
 ,.cfg_flsh_addr                     (oc0_cfg_flsh_addr                    ) // -- oc_cfg0:  output [13:0]
 ,.cfg_flsh_wren                     (oc0_cfg_flsh_wren                    ) // -- oc_cfg0:  output
 ,.cfg_flsh_wdata                    (oc0_cfg_flsh_wdata                   ) // -- oc_cfg0:  output [31:0]
 ,.cfg_flsh_rden                     (oc0_cfg_flsh_rden                    ) // -- oc_cfg0:  output
 ,.flsh_cfg_rdata                    (oc0_flsh_cfg_rdata                   ) // -- oc_cfg0:  input  [31:0]
 ,.flsh_cfg_done                     (oc0_flsh_cfg_done                    ) // -- oc_cfg0:  input
 ,.flsh_cfg_status                   (oc0_flsh_cfg_status                  ) // -- oc_cfg0:  input  [7:0]
 ,.flsh_cfg_bresp                    (oc0_flsh_cfg_bresp                   ) // -- oc_cfg0:  input  [1:0]
 ,.flsh_cfg_rresp                    (oc0_flsh_cfg_rresp                   ) // -- oc_cfg0:  input  [1:0]
 ,.cfg_flsh_expand_enable            (oc0_cfg_flsh_expand_enable           ) // -- oc_cfg0:  output
 ,.cfg_flsh_expand_dir               (oc0_cfg_flsh_expand_dir              ) // -- oc_cfg0:  output
 ,.cfg0_bus_num                      (oc0_cfg0_bus_num                     ) // -- oc_cfg0:  output [7:0] 
 ,.cfg0_device_num                   (oc0_cfg0_device_num                  ) // -- oc_cfg0:  output [4:0] 
 ,.fen_afu_ready                     (oc0_fen_afu_ready                    ) // -- oc_cfg0:  output       
 ,.afu_fen_cmd_initial_credit        (oc0_afu_fen_cmd_initial_credit       ) // -- oc_cfg0:  input  [6:0] 
 ,.afu_fen_cmd_credit                (oc0_afu_fen_cmd_credit               ) // -- oc_cfg0:  input        
 ,.fen_afu_cmd_valid                 (oc0_fen_afu_cmd_valid                ) // -- oc_cfg0:  output       
 ,.fen_afu_cmd_opcode                (oc0_fen_afu_cmd_opcode               ) // -- oc_cfg0:  output [7:0] 
 ,.fen_afu_cmd_dl                    (oc0_fen_afu_cmd_dl                   ) // -- oc_cfg0:  output [1:0] 
 ,.fen_afu_cmd_end                   (oc0_fen_afu_cmd_end                  ) // -- oc_cfg0:  output       
 ,.fen_afu_cmd_pa                    (oc0_fen_afu_cmd_pa                   ) // -- oc_cfg0:  output [63:0]
 ,.fen_afu_cmd_flag                  (oc0_fen_afu_cmd_flag                 ) // -- oc_cfg0:  output [3:0] 
 ,.fen_afu_cmd_os                    (oc0_fen_afu_cmd_os                   ) // -- oc_cfg0:  output       
 ,.fen_afu_cmd_capptag               (oc0_fen_afu_cmd_capptag              ) // -- oc_cfg0:  output [15:0]
 ,.fen_afu_cmd_pl                    (oc0_fen_afu_cmd_pl                   ) // -- oc_cfg0:  output [2:0] 
 ,.fen_afu_cmd_be                    (oc0_fen_afu_cmd_be                   ) // -- oc_cfg0:  output [63:0]
 ,.afu_fen_resp_initial_credit       (oc0_afu_fen_resp_initial_credit      ) // -- oc_cfg0:  input  [6:0] 
 ,.afu_fen_resp_credit               (oc0_afu_fen_resp_credit              ) // -- oc_cfg0:  input  
 ,.fen_afu_resp_valid                (oc0_fen_afu_resp_valid               ) // -- oc_cfg0:  output 
 ,.fen_afu_resp_opcode               (oc0_fen_afu_resp_opcode              ) // -- oc_cfg0:  output [7:0]
 ,.fen_afu_resp_afutag               (oc0_fen_afu_resp_afutag              ) // -- oc_cfg0:  output [15:0]
 ,.fen_afu_resp_code                 (oc0_fen_afu_resp_code                ) // -- oc_cfg0:  output [3:0]
 ,.fen_afu_resp_pg_size              (oc0_fen_afu_resp_pg_size             ) // -- oc_cfg0:  output [5:0]
 ,.fen_afu_resp_dl                   (oc0_fen_afu_resp_dl                  ) // -- oc_cfg0:  output [1:0]
 ,.fen_afu_resp_dp                   (oc0_fen_afu_resp_dp                  ) // -- oc_cfg0:  output [1:0]
 ,.fen_afu_resp_host_tag             (oc0_fen_afu_resp_host_tag            ) // -- oc_cfg0:  output [23:0]
 ,.fen_afu_resp_cache_state          (oc0_fen_afu_resp_cache_state         ) // -- oc_cfg0:  output [3:0]
 ,.fen_afu_resp_addr_tag             (oc0_fen_afu_resp_addr_tag            ) // -- oc_cfg0:  output [17:0]
 ,.afu_fen_cmd_rd_req                (oc0_afu_fen_cmd_rd_req               ) // -- oc_cfg0:  input  
 ,.afu_fen_cmd_rd_cnt                (oc0_afu_fen_cmd_rd_cnt               ) // -- oc_cfg0:  input  [2:0]
 ,.fen_afu_cmd_data_valid            (oc0_fen_afu_cmd_data_valid           ) // -- oc_cfg0:  output 
 ,.fen_afu_cmd_data_bdi              (oc0_fen_afu_cmd_data_bdi             ) // -- oc_cfg0:  output 
 ,.fen_afu_cmd_data_bus              (oc0_fen_afu_cmd_data_bus             ) // -- oc_cfg0:  output [511:0]
 ,.afu_fen_resp_rd_req               (oc0_afu_fen_resp_rd_req              ) // -- oc_cfg0:  input  
 ,.afu_fen_resp_rd_cnt               (oc0_afu_fen_resp_rd_cnt              ) // -- oc_cfg0:  input  [2:0]
 ,.fen_afu_resp_data_valid           (oc0_fen_afu_resp_data_valid          ) // -- oc_cfg0:  output 
 ,.fen_afu_resp_data_bdi             (oc0_fen_afu_resp_data_bdi            ) // -- oc_cfg0:  output 
 ,.fen_afu_resp_data_bus             (oc0_fen_afu_resp_data_bus            ) // -- oc_cfg0:  output [511:0]
 ,.fen_afu_cmd_initial_credit        (oc0_fen_afu_cmd_initial_credit       ) // -- oc_cfg0:  output [3:0]
 ,.fen_afu_resp_initial_credit       (oc0_fen_afu_resp_initial_credit      ) // -- oc_cfg0:  output [3:0]
 ,.fen_afu_cmd_data_initial_credit   (oc0_fen_afu_cmd_data_initial_credit  ) // -- oc_cfg0:  output [5:0]
 ,.fen_afu_resp_data_initial_credit  (oc0_fen_afu_resp_data_initial_credit ) // -- oc_cfg0:  output [5:0]
 ,.fen_afu_cmd_credit                (oc0_fen_afu_cmd_credit               ) // -- oc_cfg0:  output 
 ,.afu_fen_cmd_valid                 (oc0_afu_fen_cmd_valid                ) // -- oc_cfg0:  input  
 ,.afu_fen_cmd_opcode                (oc0_afu_fen_cmd_opcode               ) // -- oc_cfg0:  input  [7:0]
 ,.afu_fen_cmd_actag                 (oc0_afu_fen_cmd_actag                ) // -- oc_cfg0:  input  [11:0]
 ,.afu_fen_cmd_stream_id             (oc0_afu_fen_cmd_stream_id            ) // -- oc_cfg0:  input  [3:0]
 ,.afu_fen_cmd_ea_or_obj             (oc0_afu_fen_cmd_ea_or_obj            ) // -- oc_cfg0:  input  [67:0]
 ,.afu_fen_cmd_afutag                (oc0_afu_fen_cmd_afutag               ) // -- oc_cfg0:  input  [15:0]
 ,.afu_fen_cmd_dl                    (oc0_afu_fen_cmd_dl                   ) // -- oc_cfg0:  input  [1:0]
 ,.afu_fen_cmd_pl                    (oc0_afu_fen_cmd_pl                   ) // -- oc_cfg0:  input  [2:0]
 ,.afu_fen_cmd_os                    (oc0_afu_fen_cmd_os                   ) // -- oc_cfg0:  input  
 ,.afu_fen_cmd_be                    (oc0_afu_fen_cmd_be                   ) // -- oc_cfg0:  input  [63:0]
 ,.afu_fen_cmd_flag                  (oc0_afu_fen_cmd_flag                 ) // -- oc_cfg0:  input  [3:0]
 ,.afu_fen_cmd_endian                (oc0_afu_fen_cmd_endian               ) // -- oc_cfg0:  input  
 ,.afu_fen_cmd_bdf                   (oc0_afu_fen_cmd_bdf                  ) // -- oc_cfg0:  input  [15:0]
 ,.afu_fen_cmd_pasid                 (oc0_afu_fen_cmd_pasid                ) // -- oc_cfg0:  input  [19:0]
 ,.afu_fen_cmd_pg_size               (oc0_afu_fen_cmd_pg_size              ) // -- oc_cfg0:  input  [5:0]
 ,.fen_afu_cmd_data_credit           (oc0_fen_afu_cmd_data_credit          ) // -- oc_cfg0:  output 
 ,.afu_fen_cdata_valid               (oc0_afu_fen_cdata_valid              ) // -- oc_cfg0:  input  
 ,.afu_fen_cdata_bus                 (oc0_afu_fen_cdata_bus                ) // -- oc_cfg0:  input  [511:0]
 ,.afu_fen_cdata_bdi                 (oc0_afu_fen_cdata_bdi                ) // -- oc_cfg0:  input  
 ,.fen_afu_resp_credit               (oc0_fen_afu_resp_credit              ) // -- oc_cfg0:  output 
 ,.afu_fen_resp_valid                (oc0_afu_fen_resp_valid               ) // -- oc_cfg0:  input  
 ,.afu_fen_resp_opcode               (oc0_afu_fen_resp_opcode              ) // -- oc_cfg0:  input  [7:0]
 ,.afu_fen_resp_dl                   (oc0_afu_fen_resp_dl                  ) // -- oc_cfg0:  input  [1:0]
 ,.afu_fen_resp_capptag              (oc0_afu_fen_resp_capptag             ) // -- oc_cfg0:  input  [15:0]
 ,.afu_fen_resp_dp                   (oc0_afu_fen_resp_dp                  ) // -- oc_cfg0:  input  [1:0]
 ,.afu_fen_resp_code                 (oc0_afu_fen_resp_code                ) // -- oc_cfg0:  input  [3:0]
 ,.fen_afu_resp_data_credit          (oc0_fen_afu_resp_data_credit         ) // -- oc_cfg0:  output 
 ,.afu_fen_rdata_valid               (oc0_afu_fen_rdata_valid              ) // -- oc_cfg0:  input  
 ,.afu_fen_rdata_bus                 (oc0_afu_fen_rdata_bus                ) // -- oc_cfg0:  input  [511:0]
 ,.afu_fen_rdata_bdi                 (oc0_afu_fen_rdata_bdi                ) // -- oc_cfg0:  input  
 ,.cfg_function                      (oc0_cfg_function                     ) // -- oc_cfg0:  output [2:0]
 ,.cfg_portnum                       (oc0_cfg_portnum                      ) // -- oc_cfg0:  output [1:0]
 ,.cfg_addr                          (oc0_cfg_addr                         ) // -- oc_cfg0:  output [11:0]
 ,.cfg_wdata                         (oc0_cfg_wdata                        ) // -- oc_cfg0:  output [31:0]
 ,.cfg_f1_rdata                      (oc0_cfg_f1_rdata                     ) // -- oc_cfg0:  input  [31:0]
 ,.cfg_f1_rdata_vld                  (oc0_cfg_f1_rdata_vld                 ) // -- oc_cfg0:  input  
 ,.cfg_wr_1B                         (oc0_cfg_wr_1B                        ) // -- oc_cfg0:  output 
 ,.cfg_wr_2B                         (oc0_cfg_wr_2B                        ) // -- oc_cfg0:  output 
 ,.cfg_wr_4B                         (oc0_cfg_wr_4B                        ) // -- oc_cfg0:  output 
 ,.cfg_rd                            (oc0_cfg_rd                           ) // -- oc_cfg0:  output 
 ,.cfg_f1_bad_op_or_align            (oc0_cfg_f1_bad_op_or_align           ) // -- oc_cfg0:  input  
 ,.cfg_f1_addr_not_implemented       (oc0_cfg_f1_addr_not_implemented      ) // -- oc_cfg0:  input  
 ,.cfg_f1_octrl00_fence_afu          (oc0_cfg_f1_octrl00_fence_afu         ) // -- oc_cfg0:  input  
 ,.cfg_f0_otl0_long_backoff_timer    (oc0_cfg_f0_otl0_long_backoff_timer   ) // -- oc_cfg0:  output [3:0]
 ,.cfg_f0_otl0_short_backoff_timer   (oc0_cfg_f0_otl0_short_backoff_timer  ) // -- oc_cfg0:  output [3:0]
 ,.cfg0_cff_fifo_overflow            (oc0_cfg0_cff_fifo_overflow           ) // -- oc_cfg0:  output 
 ,.cfg0_rff_fifo_overflow            (oc0_cfg0_rff_fifo_overflow           ) // -- oc_cfg0:  output 
 ,.cfg_errvec                        (oc0_cfg_errvec                       ) // -- oc_cfg0:  output [127:0]
 ,.cfg_errvec_valid                  (oc0_cfg_errvec_valid                 ) // -- oc_cfg0:  output 
 ,.f1_csh_expansion_rom_bar          (oc0_f1_ro_csh_expansion_rom_bar      ) // -- oc_cfg0:  output [31:0]
 ,.f1_csh_subsystem_id               (oc0_f1_ro_csh_subsystem_id           ) // -- oc_cfg0:  output [15:0]
 ,.f1_csh_subsystem_vendor_id        (oc0_f1_ro_csh_subsystem_vendor_id    ) // -- oc_cfg0:  output [15:0]
 ,.f1_csh_mmio_bar0_size             (oc0_f1_ro_csh_mmio_bar0_size         ) // -- oc_cfg0:  output [63:0]
 ,.f1_csh_mmio_bar1_size             (oc0_f1_ro_csh_mmio_bar1_size         ) // -- oc_cfg0:  output [63:0]
 ,.f1_csh_mmio_bar2_size             (oc0_f1_ro_csh_mmio_bar2_size         ) // -- oc_cfg0:  output [63:0]
 ,.f1_csh_mmio_bar0_prefetchable     (oc0_f1_ro_csh_mmio_bar0_prefetchable ) // -- oc_cfg0:  output 
 ,.f1_csh_mmio_bar1_prefetchable     (oc0_f1_ro_csh_mmio_bar1_prefetchable ) // -- oc_cfg0:  output 
 ,.f1_csh_mmio_bar2_prefetchable     (oc0_f1_ro_csh_mmio_bar2_prefetchable ) // -- oc_cfg0:  output 
 ,.f1_pasid_max_pasid_width          (oc0_f1_ro_pasid_max_pasid_width      ) // -- oc_cfg0:  output [4:0]
 ,.f1_ofunc_reset_duration           (oc0_f1_ro_ofunc_reset_duration       ) // -- oc_cfg0:  output [7:0]
 ,.f1_ofunc_afu_present              (oc0_f1_ro_ofunc_afu_present          ) // -- oc_cfg0:  output 
 ,.f1_ofunc_max_afu_index            (oc0_f1_ro_ofunc_max_afu_index        ) // -- oc_cfg0:  output [4:0]
 ,.f1_octrl00_reset_duration         (oc0_f1_ro_octrl00_reset_duration     ) // -- oc_cfg0:  output [7:0]
 ,.f1_octrl00_afu_control_index      (oc0_f1_ro_octrl00_afu_control_index  ) // -- oc_cfg0:  output [5:0]
 ,.f1_octrl00_pasid_len_supported    (oc0_f1_ro_octrl00_pasid_len_supported) // -- oc_cfg0:  output [4:0]
 ,.f1_octrl00_metadata_supported     (oc0_f1_ro_octrl00_metadata_supported ) // -- oc_cfg0:  output 
 ,.f1_octrl00_actag_len_supported    (oc0_f1_ro_octrl00_actag_len_supported) // -- oc_cfg0:  output [11:0]       
);

oc_function oc_func0(
   .clock_tlx                              (oc0_clock_tlx                          ) // -- oc_function0:   input  
  ,.clock_afu                              (oc0_clock_afu                          ) // -- oc_function0:   input  
  ,.reset                                  (oc0_reset                              ) // -- oc_function0:   input  
    // Bus number comes from CFG_SEQ
  ,.cfg_bus                                (oc0_cfg0_bus_num                       ) // -- oc_function0:   input  [7:0]
    // Hardcoded configuration inputs
  ,.ro_device                              (oc0_cfg0_device_num                    ) // -- oc_function0:   input  [4:0]
  ,.ro_function                            (3'b001                                 ) // -- oc_function0:   input  [2:0]
    // -----------------------------------
    // TLX Parser -> AFU Receive Interface
    // -----------------------------------
  ,.tlx_afu_ready                          (oc0_fen_afu_ready                      ) // -- oc_function0:   input  
    // Command interface to AFU
  ,.afu_tlx_cmd_initial_credit             (oc0_afu_fen_cmd_initial_credit         ) // -- oc_function0:   output [6:0]
  ,.afu_tlx_cmd_credit                     (oc0_afu_fen_cmd_credit                 ) // -- oc_function0:   output 
  ,.tlx_afu_cmd_valid                      (oc0_fen_afu_cmd_valid                  ) // -- oc_function0:   input  
  ,.tlx_afu_cmd_opcode                     (oc0_fen_afu_cmd_opcode                 ) // -- oc_function0:   input  [7:0]
  ,.tlx_afu_cmd_dl                         (oc0_fen_afu_cmd_dl                     ) // -- oc_function0:   input  [1:0]
  ,.tlx_afu_cmd_end                        (oc0_fen_afu_cmd_end                    ) // -- oc_function0:   input  
  ,.tlx_afu_cmd_pa                         (oc0_fen_afu_cmd_pa                     ) // -- oc_function0:   input  [63:0]
  ,.tlx_afu_cmd_flag                       (oc0_fen_afu_cmd_flag                   ) // -- oc_function0:   input  [3:0]
  ,.tlx_afu_cmd_os                         (oc0_fen_afu_cmd_os                     ) // -- oc_function0:   input  
  ,.tlx_afu_cmd_capptag                    (oc0_fen_afu_cmd_capptag                ) // -- oc_function0:   input  [15:0]
  ,.tlx_afu_cmd_pl                         (oc0_fen_afu_cmd_pl                     ) // -- oc_function0:   input  [2:0]
  ,.tlx_afu_cmd_be                         (oc0_fen_afu_cmd_be                     ) // -- oc_function0:   input  [63:0]
    // Response interface to AFU
  ,.afu_tlx_resp_initial_credit            (oc0_afu_fen_resp_initial_credit        ) // -- oc_function0:   output [6:0]
  ,.afu_tlx_resp_credit                    (oc0_afu_fen_resp_credit                ) // -- oc_function0:   output 
  ,.tlx_afu_resp_valid                     (oc0_fen_afu_resp_valid                 ) // -- oc_function0:   input  
  ,.tlx_afu_resp_opcode                    (oc0_fen_afu_resp_opcode                ) // -- oc_function0:   input  [7:0]
  ,.tlx_afu_resp_afutag                    (oc0_fen_afu_resp_afutag                ) // -- oc_function0:   input  [15:0]
  ,.tlx_afu_resp_code                      (oc0_fen_afu_resp_code                  ) // -- oc_function0:   input  [3:0]
  ,.tlx_afu_resp_pg_size                   (oc0_fen_afu_resp_pg_size               ) // -- oc_function0:   input  [5:0]
  ,.tlx_afu_resp_dl                        (oc0_fen_afu_resp_dl                    ) // -- oc_function0:   input  [1:0]
  ,.tlx_afu_resp_dp                        (oc0_fen_afu_resp_dp                    ) // -- oc_function0:   input  [1:0]
  ,.tlx_afu_resp_host_tag                  (oc0_fen_afu_resp_host_tag              ) // -- oc_function0:   input  [23:0]
  ,.tlx_afu_resp_cache_state               (oc0_fen_afu_resp_cache_state           ) // -- oc_function0:   input  [3:0]
  ,.tlx_afu_resp_addr_tag                  (oc0_fen_afu_resp_addr_tag              ) // -- oc_function0:   input  [17:0]
    // Command data interface to AFU
  ,.afu_tlx_cmd_rd_req                     (oc0_afu_fen_cmd_rd_req                 ) // -- oc_function0:   output 
  ,.afu_tlx_cmd_rd_cnt                     (oc0_afu_fen_cmd_rd_cnt                 ) // -- oc_function0:   output [2:0]
  ,.tlx_afu_cmd_data_valid                 (oc0_fen_afu_cmd_data_valid             ) // -- oc_function0:   input  
  ,.tlx_afu_cmd_data_bdi                   (oc0_fen_afu_cmd_data_bdi               ) // -- oc_function0:   input  
  ,.tlx_afu_cmd_data_bus                   (oc0_fen_afu_cmd_data_bus               ) // -- oc_function0:   input  [511:0]
    // Response data interface to AFU
  ,.afu_tlx_resp_rd_req                    (oc0_afu_fen_resp_rd_req                ) // -- oc_function0:   output 
  ,.afu_tlx_resp_rd_cnt                    (oc0_afu_fen_resp_rd_cnt                ) // -- oc_function0:   output [2:0]
  ,.tlx_afu_resp_data_valid                (oc0_fen_afu_resp_data_valid            ) // -- oc_function0:   input  
  ,.tlx_afu_resp_data_bdi                  (oc0_fen_afu_resp_data_bdi              ) // -- oc_function0:   input  
  ,.tlx_afu_resp_data_bus                  (oc0_fen_afu_resp_data_bus              ) // -- oc_function0:   input  [511:0]
    // ------------------------------------
    // AFU -> TLX Framer Transmit Interface
    // ------------------------------------
    // Initial credit allocation
  ,.tlx_afu_cmd_initial_credit             (oc0_fen_afu_cmd_initial_credit         ) // -- oc_function0:   input  [3:0]
  ,.tlx_afu_resp_initial_credit            (oc0_fen_afu_resp_initial_credit        ) // -- oc_function0:   input  [3:0]
  ,.tlx_afu_cmd_data_initial_credit        (oc0_fen_afu_cmd_data_initial_credit    ) // -- oc_function0:   input  [5:0]
  ,.tlx_afu_resp_data_initial_credit       (oc0_fen_afu_resp_data_initial_credit   ) // -- oc_function0:   input  [5:0]

    // Commands from AFU
  ,.tlx_afu_cmd_credit                     (oc0_fen_afu_cmd_credit                 ) // -- oc_function0:   input  
  ,.afu_tlx_cmd_valid                      (oc0_afu_fen_cmd_valid                  ) // -- oc_function0:   output 
  ,.afu_tlx_cmd_opcode                     (oc0_afu_fen_cmd_opcode                 ) // -- oc_function0:   output [7:0]
  ,.afu_tlx_cmd_actag                      (oc0_afu_fen_cmd_actag                  ) // -- oc_function0:   output [11:0]
  ,.afu_tlx_cmd_stream_id                  (oc0_afu_fen_cmd_stream_id              ) // -- oc_function0:   output [3:0]
  ,.afu_tlx_cmd_ea_or_obj                  (oc0_afu_fen_cmd_ea_or_obj              ) // -- oc_function0:   output [67:0]
  ,.afu_tlx_cmd_afutag                     (oc0_afu_fen_cmd_afutag                 ) // -- oc_function0:   output [15:0]
  ,.afu_tlx_cmd_dl                         (oc0_afu_fen_cmd_dl                     ) // -- oc_function0:   output [1:0]
  ,.afu_tlx_cmd_pl                         (oc0_afu_fen_cmd_pl                     ) // -- oc_function0:   output [2:0]
  ,.afu_tlx_cmd_os                         (oc0_afu_fen_cmd_os                     ) // -- oc_function0:   output 
  ,.afu_tlx_cmd_be                         (oc0_afu_fen_cmd_be                     ) // -- oc_function0:   output [63:0]
  ,.afu_tlx_cmd_flag                       (oc0_afu_fen_cmd_flag                   ) // -- oc_function0:   output [3:0]
  ,.afu_tlx_cmd_endian                     (oc0_afu_fen_cmd_endian                 ) // -- oc_function0:   output 
  ,.afu_tlx_cmd_bdf                        (oc0_afu_fen_cmd_bdf                    ) // -- oc_function0:   output [15:0]
  ,.afu_tlx_cmd_pasid                      (oc0_afu_fen_cmd_pasid                  ) // -- oc_function0:   output [19:0]
  ,.afu_tlx_cmd_pg_size                    (oc0_afu_fen_cmd_pg_size                ) // -- oc_function0:   output [5:0]
    // Command data from AFU
  ,.tlx_afu_cmd_data_credit                (oc0_fen_afu_cmd_data_credit            ) // -- oc_function0:   input  
  ,.afu_tlx_cdata_valid                    (oc0_afu_fen_cdata_valid                ) // -- oc_function0:   output 
  ,.afu_tlx_cdata_bus                      (oc0_afu_fen_cdata_bus                  ) // -- oc_function0:   output [511:0]
  ,.afu_tlx_cdata_bdi                      (oc0_afu_fen_cdata_bdi                  ) // -- oc_function0:   output 
    // Responses from AFU
  ,.tlx_afu_resp_credit                    (oc0_fen_afu_resp_credit                ) // -- oc_function0:   output 
  ,.afu_tlx_resp_valid                     (oc0_afu_fen_resp_valid                 ) // -- oc_function0:   input  
  ,.afu_tlx_resp_opcode                    (oc0_afu_fen_resp_opcode                ) // -- oc_function0:   output [7:0]
  ,.afu_tlx_resp_dl                        (oc0_afu_fen_resp_dl                    ) // -- oc_function0:   output [1:0]
  ,.afu_tlx_resp_capptag                   (oc0_afu_fen_resp_capptag               ) // -- oc_function0:   output [15:0]
  ,.afu_tlx_resp_dp                        (oc0_afu_fen_resp_dp                    ) // -- oc_function0:   output [1:0]
  ,.afu_tlx_resp_code                      (oc0_afu_fen_resp_code                  ) // -- oc_function0:   output [3:0]
    // Response data from AFU
  ,.tlx_afu_resp_data_credit               (oc0_fen_afu_resp_data_credit           ) // -- oc_function0:   input   
  ,.afu_tlx_rdata_valid                    (oc0_afu_fen_rdata_valid                ) // -- oc_function0:   output 
  ,.afu_tlx_rdata_bus                      (oc0_afu_fen_rdata_bus                  ) // -- oc_function0:   output [511:0]
  ,.afu_tlx_rdata_bdi                      (oc0_afu_fen_rdata_bdi                  ) // -- oc_function0:   output 
    // -------------------------------------------------------------
    // Configuration Sequencer Interface [CFG_SEQ -> CFG_Fn (n=1-7)]
    // -------------------------------------------------------------
  ,.cfg_function                           (oc0_cfg_function                       ) // -- oc_function0:   input  [2:0]
  ,.cfg_portnum                            (oc0_cfg_portnum                        ) // -- oc_function0:   input  [1:0]
  ,.cfg_addr                               (oc0_cfg_addr                           ) // -- oc_function0:   input  [11:0]
  ,.cfg_wdata                              (oc0_cfg_wdata                          ) // -- oc_function0:   input  [31:0]
  ,.cfg_f1_rdata                           (oc0_cfg_f1_rdata                       ) // -- oc_function0:   output [31:0]
  ,.cfg_f1_rdata_vld                       (oc0_cfg_f1_rdata_vld                   ) // -- oc_function0:   output 
  ,.cfg_wr_1B                              (oc0_cfg_wr_1B                          ) // -- oc_function0:   input  
  ,.cfg_wr_2B                              (oc0_cfg_wr_2B                          ) // -- oc_function0:   input  
  ,.cfg_wr_4B                              (oc0_cfg_wr_4B                          ) // -- oc_function0:   input  
  ,.cfg_rd                                 (oc0_cfg_rd                             ) // -- oc_function0:   input  
  ,.cfg_f1_bad_op_or_align                 (oc0_cfg_f1_bad_op_or_align             ) // -- oc_function0:   output 
  ,.cfg_f1_addr_not_implemented            (oc0_cfg_f1_addr_not_implemented        ) // -- oc_function0:   output 
    // ------------------------------------
    // Other signals
    // ------------------------------------
    // Fence control
  ,.cfg_f1_octrl00_fence_afu               (oc0_cfg_f1_octrl00_fence_afu           ) // -- oc_function0:   output 
    // TLX Configuration for the TLX port(s) connected to AFUs under this Function
  ,.cfg_f0_otl0_long_backoff_timer         (oc0_cfg_f0_otl0_long_backoff_timer     ) // -- oc_function0:   input  [3:0]
  ,.cfg_f0_otl0_short_backoff_timer        (oc0_cfg_f0_otl0_short_backoff_timer    ) // -- oc_function0:   input  [3:0]
    // Error signals into MMIO capture register
  ,.vpd_err_unimplemented_addr             (oc0_vpd_err_unimplemented_addr         ) // -- oc_function0:   input  
  ,.cfg0_cff_fifo_overflow                 (oc0_cfg0_cff_fifo_overflow             ) // -- oc_function0:   input  
  ,.cfg1_cff_fifo_overflow                 (1'b0                                   ) // -- oc_function0:   input  
  ,.cfg0_rff_fifo_overflow                 (oc0_cfg0_rff_fifo_overflow             ) // -- oc_function0:   input  
  ,.cfg1_rff_fifo_overflow                 (1'b0                                   ) // -- oc_function0:   input  
  ,.cfg_errvec                             (oc0_cfg_errvec                         ) // -- oc_function0:   input  [127:0]
  ,.cfg_errvec_valid                       (oc0_cfg_errvec_valid                   ) // -- oc_function0:   input  
    // Resync credits control
  ,.cfg_f1_octrl00_resync_credits          (oc0_cfg_f1_octrl00_resync_credits      ) // -- oc_function0:   output 

  ,.f1_csh_expansion_rom_bar               (oc0_f1_ro_csh_expansion_rom_bar        ) // -- oc_function0:   input  [31:0]
  ,.f1_csh_subsystem_id                    (oc0_f1_ro_csh_subsystem_id             ) // -- oc_function0:   input  [15:0]
  ,.f1_csh_subsystem_vendor_id             (oc0_f1_ro_csh_subsystem_vendor_id      ) // -- oc_function0:   input  [15:0]
  ,.f1_csh_mmio_bar0_size                  (oc0_f1_ro_csh_mmio_bar0_size           ) // -- oc_function0:   input  [63:0]
  ,.f1_csh_mmio_bar1_size                  (oc0_f1_ro_csh_mmio_bar1_size           ) // -- oc_function0:   input  [63:0]
  ,.f1_csh_mmio_bar2_size                  (oc0_f1_ro_csh_mmio_bar2_size           ) // -- oc_function0:   input  [63:0]
  ,.f1_csh_mmio_bar0_prefetchable          (oc0_f1_ro_csh_mmio_bar0_prefetchable   ) // -- oc_function0:   input  
  ,.f1_csh_mmio_bar1_prefetchable          (oc0_f1_ro_csh_mmio_bar1_prefetchable   ) // -- oc_function0:   input  
  ,.f1_csh_mmio_bar2_prefetchable          (oc0_f1_ro_csh_mmio_bar2_prefetchable   ) // -- oc_function0:   input  
  ,.f1_pasid_max_pasid_width               (oc0_f1_ro_pasid_max_pasid_width        ) // -- oc_function0:   input  [4:0]
  ,.f1_ofunc_reset_duration                (oc0_f1_ro_ofunc_reset_duration         ) // -- oc_function0:   input  [7:0]
  ,.f1_ofunc_afu_present                   (oc0_f1_ro_ofunc_afu_present            ) // -- oc_function0:   input  
  ,.f1_ofunc_max_afu_index                 (oc0_f1_ro_ofunc_max_afu_index          ) // -- oc_function0:   input  [4:0]
  ,.f1_octrl00_reset_duration              (oc0_f1_ro_octrl00_reset_duration       ) // -- oc_function0:   input  [7:0]
  ,.f1_octrl00_afu_control_index           (oc0_f1_ro_octrl00_afu_control_index    ) // -- oc_function0:   input  [5:0]
  ,.f1_octrl00_pasid_len_supported         (oc0_f1_ro_octrl00_pasid_len_supported  ) // -- oc_function0:   input  [4:0]
  ,.f1_octrl00_metadata_supported          (oc0_f1_ro_octrl00_metadata_supported   ) // -- oc_function0:   input  
  ,.f1_octrl00_actag_len_supported         (oc0_f1_ro_octrl00_actag_len_supported  ) // -- oc_function0:   input  [11:0]
);

`ifdef DUAL_AFU
oc_bsp bsp1(
//-------------
//-- FPGA I/O
//-------------
  .ocde                                        (oc1_ocde                             ) //-- oc_bsp1:  input
 ,.freerun_clk                                 (freerun_clk                          ) //-- oc_bsp1:  input
 ,.ch0_gtytxn_out                              (oc1_ch0_gtytxn_out                   ) //-- oc_bsp1:  output
 ,.ch0_gtytxp_out                              (oc1_ch0_gtytxp_out                   ) //-- oc_bsp1:  output
 ,.ch1_gtytxn_out                              (oc1_ch1_gtytxn_out                   ) //-- oc_bsp1:  output
 ,.ch1_gtytxp_out                              (oc1_ch1_gtytxp_out                   ) //-- oc_bsp1:  output
 ,.ch2_gtytxn_out                              (oc1_ch2_gtytxn_out                   ) //-- oc_bsp1:  output
 ,.ch2_gtytxp_out                              (oc1_ch2_gtytxp_out                   ) //-- oc_bsp1:  output
 ,.ch3_gtytxn_out                              (oc1_ch3_gtytxn_out                   ) //-- oc_bsp1:  output
 ,.ch3_gtytxp_out                              (oc1_ch3_gtytxp_out                   ) //-- oc_bsp1:  output
 ,.ch4_gtytxn_out                              (oc1_ch4_gtytxn_out                   ) //-- oc_bsp1:  output
 ,.ch4_gtytxp_out                              (oc1_ch4_gtytxp_out                   ) //-- oc_bsp1:  output
 ,.ch5_gtytxn_out                              (oc1_ch5_gtytxn_out                   ) //-- oc_bsp1:  output
 ,.ch5_gtytxp_out                              (oc1_ch5_gtytxp_out                   ) //-- oc_bsp1:  output
 ,.ch6_gtytxn_out                              (oc1_ch6_gtytxn_out                   ) //-- oc_bsp1:  output
 ,.ch6_gtytxp_out                              (oc1_ch6_gtytxp_out                   ) //-- oc_bsp1:  output
 ,.ch7_gtytxn_out                              (oc1_ch7_gtytxn_out                   ) //-- oc_bsp1:  output
 ,.ch7_gtytxp_out                              (oc1_ch7_gtytxp_out                   ) //-- oc_bsp1:  output
 ,.ch0_gtyrxn_in                               (oc1_ch0_gtyrxn_in                    ) //-- oc_bsp1:  input
 ,.ch0_gtyrxp_in                               (oc1_ch0_gtyrxp_in                    ) //-- oc_bsp1:  input
 ,.ch1_gtyrxn_in                               (oc1_ch1_gtyrxn_in                    ) //-- oc_bsp1:  input
 ,.ch1_gtyrxp_in                               (oc1_ch1_gtyrxp_in                    ) //-- oc_bsp1:  input
 ,.ch2_gtyrxn_in                               (oc1_ch2_gtyrxn_in                    ) //-- oc_bsp1:  input
 ,.ch2_gtyrxp_in                               (oc1_ch2_gtyrxp_in                    ) //-- oc_bsp1:  input
 ,.ch3_gtyrxn_in                               (oc1_ch3_gtyrxn_in                    ) //-- oc_bsp1:  input
 ,.ch3_gtyrxp_in                               (oc1_ch3_gtyrxp_in                    ) //-- oc_bsp1:  input
 ,.ch4_gtyrxn_in                               (oc1_ch4_gtyrxn_in                    ) //-- oc_bsp1:  input
 ,.ch4_gtyrxp_in                               (oc1_ch4_gtyrxp_in                    ) //-- oc_bsp1:  input
 ,.ch5_gtyrxn_in                               (oc1_ch5_gtyrxn_in                    ) //-- oc_bsp1:  input
 ,.ch5_gtyrxp_in                               (oc1_ch5_gtyrxp_in                    ) //-- oc_bsp1:  input
 ,.ch6_gtyrxn_in                               (oc1_ch6_gtyrxn_in                    ) //-- oc_bsp1:  input
 ,.ch6_gtyrxp_in                               (oc1_ch6_gtyrxp_in                    ) //-- oc_bsp1:  input
 ,.ch7_gtyrxn_in                               (oc1_ch7_gtyrxn_in                    ) //-- oc_bsp1:  input
 ,.ch7_gtyrxp_in                               (oc1_ch7_gtyrxp_in                    ) //-- oc_bsp1:  input
 ,.mgtrefclk1_x0y0_p                           (oc1_mgtrefclk1_x0y0_p                ) //-- oc_bsp1:  input
 ,.mgtrefclk1_x0y0_n                           (oc1_mgtrefclk1_x0y0_n                ) //-- oc_bsp1:  input
`ifdef FLASH
 ,.FPGA_FLASH_CE2_L                            (FPGA_FLASH_CE2_L                     ) //-- oc_bsp1:  inout
 ,.FPGA_FLASH_DQ4                              (FPGA_FLASH_DQ4                       ) //-- oc_bsp1:  inout
 ,.FPGA_FLASH_DQ5                              (FPGA_FLASH_DQ5                       ) //-- oc_bsp1:  inout
 ,.FPGA_FLASH_DQ6                              (FPGA_FLASH_DQ6                       ) //-- oc_bsp1:  inout
 ,.FPGA_FLASH_DQ7                              (FPGA_FLASH_DQ7                       ) //-- oc_bsp1:  inout
`endif

//-------------
//-- AFU Ports
//-------------
 ,.clock_afu                                   (oc1_clock_afu                        ) // -- oc_bsp1:  output
 ,.clock_tlx                                   (oc1_clock_tlx                        ) // -- oc_bsp1:  output
 ,.reset_n                                     (oc1_reset_n                          ) // -- oc_bsp1:  output
 ,.ro_device                                   (oc1_ro_device                        ) // -- oc_bsp1:  output  [4:0]
 ,.ro_dlx_version                              (oc1_ro_dlx0_version                  ) // -- oc_bsp1:  output  [31:0]
 ,.ro_tlx_version                              (oc1_ro_tlx0_version                  ) // -- oc_bsp1:  output  [31:0]
 ,.tlx_afu_ready                               (oc1_tlx_afu_ready                    ) // -- oc_bsp1:  output
 ,.afu_tlx_cmd_initial_credit                  (oc1_afu_tlx_cmd_initial_credit       ) // -- oc_bsp1:  input   [6:0]
 ,.afu_tlx_cmd_credit                          (oc1_afu_tlx_cmd_credit               ) // -- oc_bsp1:  input
 ,.tlx_afu_cmd_valid                           (oc1_tlx_afu_cmd_valid                ) // -- oc_bsp1:  output
 ,.tlx_afu_cmd_opcode                          (oc1_tlx_afu_cmd_opcode               ) // -- oc_bsp1:  output  [7:0]
 ,.tlx_afu_cmd_dl                              (oc1_tlx_afu_cmd_dl                   ) // -- oc_bsp1:  output  [1:0]
 ,.tlx_afu_cmd_end                             (oc1_tlx_afu_cmd_end                  ) // -- oc_bsp1:  output
 ,.tlx_afu_cmd_pa                              (oc1_tlx_afu_cmd_pa                   ) // -- oc_bsp1:  output  [63:0]
 ,.tlx_afu_cmd_flag                            (oc1_tlx_afu_cmd_flag                 ) // -- oc_bsp1:  output  [3:0]
 ,.tlx_afu_cmd_os                              (oc1_tlx_afu_cmd_os                   ) // -- oc_bsp1:  output
 ,.tlx_afu_cmd_capptag                         (oc1_tlx_afu_cmd_capptag              ) // -- oc_bsp1:  output  [15:0]
 ,.tlx_afu_cmd_pl                              (oc1_tlx_afu_cmd_pl                   ) // -- oc_bsp1:  output  [2:0]
 ,.tlx_afu_cmd_be                              (oc1_tlx_afu_cmd_be                   ) // -- oc_bsp1:  output  [63:0]
 ,.afu_tlx_resp_initial_credit                 (oc1_afu_tlx_resp_initial_credit      ) // -- oc_bsp1:  input   [6:0]
 ,.afu_tlx_resp_credit                         (oc1_afu_tlx_resp_credit              ) // -- oc_bsp1:  input
 ,.tlx_afu_resp_valid                          (oc1_tlx_afu_resp_valid               ) // -- oc_bsp1:  output
 ,.tlx_afu_resp_opcode                         (oc1_tlx_afu_resp_opcode              ) // -- oc_bsp1:  output  [7:0]
 ,.tlx_afu_resp_afutag                         (oc1_tlx_afu_resp_afutag              ) // -- oc_bsp1:  output  [15:0]
 ,.tlx_afu_resp_code                           (oc1_tlx_afu_resp_code                ) // -- oc_bsp1:  output  [3:0]
 ,.tlx_afu_resp_pg_size                        (oc1_tlx_afu_resp_pg_size             ) // -- oc_bsp1:  output  [5:0]
 ,.tlx_afu_resp_dl                             (oc1_tlx_afu_resp_dl                  ) // -- oc_bsp1:  output  [1:0]
 ,.tlx_afu_resp_dp                             (oc1_tlx_afu_resp_dp                  ) // -- oc_bsp1:  output  [1:0]
 ,.tlx_afu_resp_host_tag                       (oc1_tlx_afu_resp_host_tag            ) // -- oc_bsp1:  output  [23:0]
 ,.tlx_afu_resp_cache_state                    (oc1_tlx_afu_resp_cache_state         ) // -- oc_bsp1:  output  [3:0]
 ,.tlx_afu_resp_addr_tag                       (oc1_tlx_afu_resp_addr_tag            ) // -- oc_bsp1:  output  [17:0]
 ,.afu_tlx_cmd_rd_req                          (oc1_afu_tlx_cmd_rd_req               ) // -- oc_bsp1:  input
 ,.afu_tlx_cmd_rd_cnt                          (oc1_afu_tlx_cmd_rd_cnt               ) // -- oc_bsp1:  input   [2:0]
 ,.tlx_afu_cmd_data_valid                      (oc1_tlx_afu_cmd_data_valid           ) // -- oc_bsp1:  output
 ,.tlx_afu_cmd_data_bdi                        (oc1_tlx_afu_cmd_data_bdi             ) // -- oc_bsp1:  output
 ,.tlx_afu_cmd_data_bus                        (oc1_tlx_afu_cmd_data_bus             ) // -- oc_bsp1:  output  [511:0]
 ,.afu_tlx_resp_rd_req                         (oc1_afu_tlx_resp_rd_req              ) // -- oc_bsp1:  input
 ,.afu_tlx_resp_rd_cnt                         (oc1_afu_tlx_resp_rd_cnt              ) // -- oc_bsp1:  input   [2:0]
 ,.tlx_afu_resp_data_valid                     (oc1_tlx_afu_resp_data_valid          ) // -- oc_bsp1:  output
 ,.tlx_afu_resp_data_bdi                       (oc1_tlx_afu_resp_data_bdi            ) // -- oc_bsp1:  output
 ,.tlx_afu_resp_data_bus                       (oc1_tlx_afu_resp_data_bus            ) // -- oc_bsp1:  output  [511:0]
 ,.cfg_tlx_xmit_tmpl_config_0                  (oc1_cfg0_tlx_xmit_tmpl_config_0      ) // -- oc_bsp1:  input
 ,.cfg_tlx_xmit_tmpl_config_1                  (oc1_cfg0_tlx_xmit_tmpl_config_1      ) // -- oc_bsp1:  input
 ,.cfg_tlx_xmit_tmpl_config_2                  (oc1_cfg0_tlx_xmit_tmpl_config_2      ) // -- oc_bsp1:  input
 ,.cfg_tlx_xmit_tmpl_config_3                  (oc1_cfg0_tlx_xmit_tmpl_config_3      ) // -- oc_bsp1:  input
 ,.cfg_tlx_xmit_rate_config_0                  (oc1_cfg0_tlx_xmit_rate_config_0      ) // -- oc_bsp1:  input   [3:0]
 ,.cfg_tlx_xmit_rate_config_1                  (oc1_cfg0_tlx_xmit_rate_config_1      ) // -- oc_bsp1:  input   [3:0]
 ,.cfg_tlx_xmit_rate_config_2                  (oc1_cfg0_tlx_xmit_rate_config_2      ) // -- oc_bsp1:  input   [3:0]
 ,.cfg_tlx_xmit_rate_config_3                  (oc1_cfg0_tlx_xmit_rate_config_3      ) // -- oc_bsp1:  input   [3:0]
 ,.tlx_cfg_in_rcv_tmpl_capability_0            (oc1_tlx_cfg0_in_rcv_tmpl_capability_0) // -- oc_bsp1:  output
 ,.tlx_cfg_in_rcv_tmpl_capability_1            (oc1_tlx_cfg0_in_rcv_tmpl_capability_1) // -- oc_bsp1:  output
 ,.tlx_cfg_in_rcv_tmpl_capability_2            (oc1_tlx_cfg0_in_rcv_tmpl_capability_2) // -- oc_bsp1:  output
 ,.tlx_cfg_in_rcv_tmpl_capability_3            (oc1_tlx_cfg0_in_rcv_tmpl_capability_3) // -- oc_bsp1:  output
 ,.tlx_cfg_in_rcv_rate_capability_0            (oc1_tlx_cfg0_in_rcv_rate_capability_0) // -- oc_bsp1:  output  [3:0]
 ,.tlx_cfg_in_rcv_rate_capability_1            (oc1_tlx_cfg0_in_rcv_rate_capability_1) // -- oc_bsp1:  output  [3:0]
 ,.tlx_cfg_in_rcv_rate_capability_2            (oc1_tlx_cfg0_in_rcv_rate_capability_2) // -- oc_bsp1:  output  [3:0]
 ,.tlx_cfg_in_rcv_rate_capability_3            (oc1_tlx_cfg0_in_rcv_rate_capability_3) // -- oc_bsp1:  output  [3:0]
 ,.tlx_afu_cmd_initial_credit                  (oc1_tlx_afu_cmd_initial_credit       ) // -- oc_bsp1:  output  [3:0]
 ,.tlx_afu_resp_initial_credit                 (oc1_tlx_afu_resp_initial_credit      ) // -- oc_bsp1:  output  [3:0]
 ,.tlx_afu_cmd_data_initial_credit             (oc1_tlx_afu_cmd_data_initial_credit  ) // -- oc_bsp1:  output  [5:0]
 ,.tlx_afu_resp_data_initial_credit            (oc1_tlx_afu_resp_data_initial_credit ) // -- oc_bsp1:  output  [5:0]
 ,.tlx_afu_cmd_credit                          (oc1_tlx_afu_cmd_credit               ) // -- oc_bsp1:  output
 ,.afu_tlx_cmd_valid                           (oc1_afu_tlx_cmd_valid                ) // -- oc_bsp1:  input
 ,.afu_tlx_cmd_opcode                          (oc1_afu_tlx_cmd_opcode               ) // -- oc_bsp1:  input   [7:0]
 ,.afu_tlx_cmd_actag                           (oc1_afu_tlx_cmd_actag                ) // -- oc_bsp1:  input   [11:0]
 ,.afu_tlx_cmd_stream_id                       (oc1_afu_tlx_cmd_stream_id            ) // -- oc_bsp1:  input   [3:0]
 ,.afu_tlx_cmd_ea_or_obj                       (oc1_afu_tlx_cmd_ea_or_obj            ) // -- oc_bsp1:  input   [67:0]
 ,.afu_tlx_cmd_afutag                          (oc1_afu_tlx_cmd_afutag               ) // -- oc_bsp1:  input   [15:0]
 ,.afu_tlx_cmd_dl                              (oc1_afu_tlx_cmd_dl                   ) // -- oc_bsp1:  input   [1:0]
 ,.afu_tlx_cmd_pl                              (oc1_afu_tlx_cmd_pl                   ) // -- oc_bsp1:  input   [2:0]
 ,.afu_tlx_cmd_os                              (oc1_afu_tlx_cmd_os                   ) // -- oc_bsp1:  input
 ,.afu_tlx_cmd_be                              (oc1_afu_tlx_cmd_be                   ) // -- oc_bsp1:  input   [63:0]
 ,.afu_tlx_cmd_flag                            (oc1_afu_tlx_cmd_flag                 ) // -- oc_bsp1:  input   [3:0]
 ,.afu_tlx_cmd_endian                          (oc1_afu_tlx_cmd_endian               ) // -- oc_bsp1:  input
 ,.afu_tlx_cmd_bdf                             (oc1_afu_tlx_cmd_bdf                  ) // -- oc_bsp1:  input   [15:0]
 ,.afu_tlx_cmd_pasid                           (oc1_afu_tlx_cmd_pasid                ) // -- oc_bsp1:  input   [19:0]
 ,.afu_tlx_cmd_pg_size                         (oc1_afu_tlx_cmd_pg_size              ) // -- oc_bsp1:  input   [5:0]
 ,.tlx_afu_cmd_data_credit                     (oc1_tlx_afu_cmd_data_credit          ) // -- oc_bsp1:  output
 ,.afu_tlx_cdata_valid                         (oc1_afu_tlx_cdata_valid              ) // -- oc_bsp1:  input
 ,.afu_tlx_cdata_bus                           (oc1_afu_tlx_cdata_bus                ) // -- oc_bsp1:  input   [511:0]
 ,.afu_tlx_cdata_bdi                           (oc1_afu_tlx_cdata_bdi                ) // -- oc_bsp1:  input
 ,.tlx_afu_resp_credit                         (oc1_tlx_afu_resp_credit              ) // -- oc_bsp1:  output
 ,.afu_tlx_resp_valid                          (oc1_afu_tlx_resp_valid               ) // -- oc_bsp1:  input
 ,.afu_tlx_resp_opcode                         (oc1_afu_tlx_resp_opcode              ) // -- oc_bsp1:  input   [7:0]
 ,.afu_tlx_resp_dl                             (oc1_afu_tlx_resp_dl                  ) // -- oc_bsp1:  input   [1:0]
 ,.afu_tlx_resp_capptag                        (oc1_afu_tlx_resp_capptag             ) // -- oc_bsp1:  input   [15:0]
 ,.afu_tlx_resp_dp                             (oc1_afu_tlx_resp_dp                  ) // -- oc_bsp1:  input   [1:0]
 ,.afu_tlx_resp_code                           (oc1_afu_tlx_resp_code                ) // -- oc_bsp1:  input   [3:0]
 ,.tlx_afu_resp_data_credit                    (oc1_tlx_afu_resp_data_credit         ) // -- oc_bsp1:  output
 ,.afu_tlx_rdata_valid                         (oc1_afu_tlx_rdata_valid              ) // -- oc_bsp1:  input
 ,.afu_tlx_rdata_bus                           (oc1_afu_tlx_rdata_bus                ) // -- oc_bsp1:  input   [511:0]
 ,.afu_tlx_rdata_bdi                           (oc1_afu_tlx_rdata_bdi                ) // -- oc_bsp1:  input
 ,.tlx_cfg_valid                               (oc1_tlx_cfg0_valid                   ) // -- oc_bsp1:  output
 ,.tlx_cfg_opcode                              (oc1_tlx_cfg0_opcode                  ) // -- oc_bsp1:  output  [7:0]
 ,.tlx_cfg_pa                                  (oc1_tlx_cfg0_pa                      ) // -- oc_bsp1:  output  [63:0]
 ,.tlx_cfg_t                                   (oc1_tlx_cfg0_t                       ) // -- oc_bsp1:  output
 ,.tlx_cfg_pl                                  (oc1_tlx_cfg0_pl                      ) // -- oc_bsp1:  output  [2:0]
 ,.tlx_cfg_capptag                             (oc1_tlx_cfg0_capptag                 ) // -- oc_bsp1:  output  [15:0]
 ,.tlx_cfg_data_bus                            (oc1_tlx_cfg0_data_bus                ) // -- oc_bsp1:  output  [31:0]
 ,.tlx_cfg_data_bdi                            (oc1_tlx_cfg0_data_bdi                ) // -- oc_bsp1:  output
 ,.cfg_tlx_initial_credit                      (oc1_cfg0_tlx_initial_credit          ) // -- oc_bsp1:  input   [3:0]
 ,.cfg_tlx_credit_return                       (oc1_cfg0_tlx_credit_return           ) // -- oc_bsp1:  input
 ,.cfg_tlx_resp_valid                          (oc1_cfg0_tlx_resp_valid              ) // -- oc_bsp1:  input
 ,.cfg_tlx_resp_opcode                         (oc1_cfg0_tlx_resp_opcode             ) // -- oc_bsp1:  input   [7:0]
 ,.cfg_tlx_resp_capptag                        (oc1_cfg0_tlx_resp_capptag            ) // -- oc_bsp1:  input   [15:0]
 ,.cfg_tlx_resp_code                           (oc1_cfg0_tlx_resp_code               ) // -- oc_bsp1:  input   [3:0]
 ,.cfg_tlx_rdata_offset                        (oc1_cfg0_tlx_rdata_offset            ) // -- oc_bsp1:  input   [3:0]
 ,.cfg_tlx_rdata_bus                           (oc1_cfg0_tlx_rdata_bus               ) // -- oc_bsp1:  input   [31:0]
 ,.cfg_tlx_rdata_bdi                           (oc1_cfg0_tlx_rdata_bdi               ) // -- oc_bsp1:  input
 ,.tlx_cfg_resp_ack                            (oc1_tlx_cfg0_resp_ack                ) // -- oc_bsp1:  output
 ,.cfg_f1_octrl00_resync_credits               (oc1_cfg_f1_octrl00_resync_credits    ) // -- oc_bsp1:  input
 ,.cfg_vpd_addr                                (oc1_cfg_vpd_addr                     ) // -- oc_bsp1:  input   [14:0]
 ,.cfg_vpd_wren                                (oc1_cfg_vpd_wren                     ) // -- oc_bsp1:  input
 ,.cfg_vpd_wdata                               (oc1_cfg_vpd_wdata                    ) // -- oc_bsp1:  input   [31:0]
 ,.cfg_vpd_rden                                (oc1_cfg_vpd_rden                     ) // -- oc_bsp1:  input
 ,.vpd_cfg_rdata                               (oc1_vpd_cfg_rdata                    ) // -- oc_bsp1:  output  [31:0]
 ,.vpd_cfg_done                                (oc1_vpd_cfg_done                     ) // -- oc_bsp1:  output
 ,.vpd_err_unimplemented_addr                  (oc1_vpd_err_unimplemented_addr       ) // -- oc_bsp1:  output
 ,.cfg_flsh_devsel                             (oc1_cfg_flsh_devsel                  ) // -- oc_bsp1:  input   [1:0]
 ,.cfg_flsh_addr                               (oc1_cfg_flsh_addr                    ) // -- oc_bsp1:  input   [13:0]
 ,.cfg_flsh_wren                               (oc1_cfg_flsh_wren                    ) // -- oc_bsp1:  input
 ,.cfg_flsh_wdata                              (oc1_cfg_flsh_wdata                   ) // -- oc_bsp1:  input   [31:0]
 ,.cfg_flsh_rden                               (oc1_cfg_flsh_rden                    ) // -- oc_bsp1:  input
 ,.flsh_cfg_rdata                              (oc1_flsh_cfg_rdata                   ) // -- oc_bsp1:  output  [31:0]
 ,.flsh_cfg_done                               (oc1_flsh_cfg_done                    ) // -- oc_bsp1:  output
 ,.flsh_cfg_status                             (oc1_flsh_cfg_status                  ) // -- oc_bsp1:  output  [7:0]
 ,.flsh_cfg_bresp                              (oc1_flsh_cfg_bresp                   ) // -- oc_bsp1:  output  [1:0]
 ,.flsh_cfg_rresp                              (oc1_flsh_cfg_rresp                   ) // -- oc_bsp1:  output  [1:0]
 ,.cfg_flsh_expand_enable                      (oc1_cfg_flsh_expand_enable           ) // -- oc_bsp1:  input
 ,.cfg_flsh_expand_dir                         (oc1_cfg_flsh_expand_dir              ) // -- oc_bsp1:  input
);

oc_cfg cfg1 (
  .clock                             (oc1_clock_tlx                        ) // -- oc_cfg1:  input
 ,.reset_n                           (oc1_reset_n                          ) // -- oc_cfg1:  input
 ,.ro_device                         (oc1_ro_device                        ) // -- oc_cfg1:  input  [4:0]
 ,.ro_dlx0_version                   (oc1_ro_dlx0_version                  ) // -- oc_cfg1:  input  [31:0]
 ,.ro_tlx0_version                   (oc1_ro_tlx0_version                  ) // -- oc_cfg1:  input  [31:0]
 ,.tlx_afu_ready                     (oc1_tlx_afu_ready                    ) // -- oc_cfg1:  input
 ,.afu_tlx_cmd_initial_credit        (oc1_afu_tlx_cmd_initial_credit       ) // -- oc_cfg1:  output [6:0]
 ,.afu_tlx_cmd_credit                (oc1_afu_tlx_cmd_credit               ) // -- oc_cfg1:  output
 ,.tlx_afu_cmd_valid                 (oc1_tlx_afu_cmd_valid                ) // -- oc_cfg1:  input
 ,.tlx_afu_cmd_opcode                (oc1_tlx_afu_cmd_opcode               ) // -- oc_cfg1:  input  [7:0]
 ,.tlx_afu_cmd_dl                    (oc1_tlx_afu_cmd_dl                   ) // -- oc_cfg1:  input  [1:0]
 ,.tlx_afu_cmd_end                   (oc1_tlx_afu_cmd_end                  ) // -- oc_cfg1:  input
 ,.tlx_afu_cmd_pa                    (oc1_tlx_afu_cmd_pa                   ) // -- oc_cfg1:  input  [63:0]
 ,.tlx_afu_cmd_flag                  (oc1_tlx_afu_cmd_flag                 ) // -- oc_cfg1:  input  [3:0]
 ,.tlx_afu_cmd_os                    (oc1_tlx_afu_cmd_os                   ) // -- oc_cfg1:  input
 ,.tlx_afu_cmd_capptag               (oc1_tlx_afu_cmd_capptag              ) // -- oc_cfg1:  input  [15:0]
 ,.tlx_afu_cmd_pl                    (oc1_tlx_afu_cmd_pl                   ) // -- oc_cfg1:  input  [2:0]
 ,.tlx_afu_cmd_be                    (oc1_tlx_afu_cmd_be                   ) // -- oc_cfg1:  input  [63:0]
 ,.afu_tlx_resp_initial_credit       (oc1_afu_tlx_resp_initial_credit      ) // -- oc_cfg1:  output [6:0]
 ,.afu_tlx_resp_credit               (oc1_afu_tlx_resp_credit              ) // -- oc_cfg1:  output
 ,.tlx_afu_resp_valid                (oc1_tlx_afu_resp_valid               ) // -- oc_cfg1:  input
 ,.tlx_afu_resp_opcode               (oc1_tlx_afu_resp_opcode              ) // -- oc_cfg1:  input  [7:0]
 ,.tlx_afu_resp_afutag               (oc1_tlx_afu_resp_afutag              ) // -- oc_cfg1:  input  [15:0]
 ,.tlx_afu_resp_code                 (oc1_tlx_afu_resp_code                ) // -- oc_cfg1:  input  [3:0]
 ,.tlx_afu_resp_pg_size              (oc1_tlx_afu_resp_pg_size             ) // -- oc_cfg1:  input  [5:0]
 ,.tlx_afu_resp_dl                   (oc1_tlx_afu_resp_dl                  ) // -- oc_cfg1:  input  [1:0]
 ,.tlx_afu_resp_dp                   (oc1_tlx_afu_resp_dp                  ) // -- oc_cfg1:  input  [1:0]
 ,.tlx_afu_resp_host_tag             (oc1_tlx_afu_resp_host_tag            ) // -- oc_cfg1:  input  [23:0]
 ,.tlx_afu_resp_cache_state          (oc1_tlx_afu_resp_cache_state         ) // -- oc_cfg1:  input  [3:0]
 ,.tlx_afu_resp_addr_tag             (oc1_tlx_afu_resp_addr_tag            ) // -- oc_cfg1:  input  [17:0]
 ,.afu_tlx_cmd_rd_req                (oc1_afu_tlx_cmd_rd_req               ) // -- oc_cfg1:  output
 ,.afu_tlx_cmd_rd_cnt                (oc1_afu_tlx_cmd_rd_cnt               ) // -- oc_cfg1:  output [2:0]
 ,.tlx_afu_cmd_data_valid            (oc1_tlx_afu_cmd_data_valid           ) // -- oc_cfg1:  input
 ,.tlx_afu_cmd_data_bdi              (oc1_tlx_afu_cmd_data_bdi             ) // -- oc_cfg1:  input
 ,.tlx_afu_cmd_data_bus              (oc1_tlx_afu_cmd_data_bus             ) // -- oc_cfg1:  input  [511:0]
 ,.afu_tlx_resp_rd_req               (oc1_afu_tlx_resp_rd_req              ) // -- oc_cfg1:  output
 ,.afu_tlx_resp_rd_cnt               (oc1_afu_tlx_resp_rd_cnt              ) // -- oc_cfg1:  output [2:0]
 ,.tlx_afu_resp_data_valid           (oc1_tlx_afu_resp_data_valid          ) // -- oc_cfg1:  input
 ,.tlx_afu_resp_data_bdi             (oc1_tlx_afu_resp_data_bdi            ) // -- oc_cfg1:  input
 ,.tlx_afu_resp_data_bus             (oc1_tlx_afu_resp_data_bus            ) // -- oc_cfg1:  input  [511:0]
 ,.cfg0_tlx_xmit_tmpl_config_0       (oc1_cfg0_tlx_xmit_tmpl_config_0      ) // -- oc_cfg1:  output
 ,.cfg0_tlx_xmit_tmpl_config_1       (oc1_cfg0_tlx_xmit_tmpl_config_1      ) // -- oc_cfg1:  output
 ,.cfg0_tlx_xmit_tmpl_config_2       (oc1_cfg0_tlx_xmit_tmpl_config_2      ) // -- oc_cfg1:  output
 ,.cfg0_tlx_xmit_tmpl_config_3       (oc1_cfg0_tlx_xmit_tmpl_config_3      ) // -- oc_cfg1:  output
 ,.cfg0_tlx_xmit_rate_config_0       (oc1_cfg0_tlx_xmit_rate_config_0      ) // -- oc_cfg1:  output [3:0]
 ,.cfg0_tlx_xmit_rate_config_1       (oc1_cfg0_tlx_xmit_rate_config_1      ) // -- oc_cfg1:  output [3:0]
 ,.cfg0_tlx_xmit_rate_config_2       (oc1_cfg0_tlx_xmit_rate_config_2      ) // -- oc_cfg1:  output [3:0]
 ,.cfg0_tlx_xmit_rate_config_3       (oc1_cfg0_tlx_xmit_rate_config_3      ) // -- oc_cfg1:  output [3:0]
 ,.tlx_cfg0_in_rcv_tmpl_capability_0 (oc1_tlx_cfg0_in_rcv_tmpl_capability_0) // -- oc_cfg1:  input
 ,.tlx_cfg0_in_rcv_tmpl_capability_1 (oc1_tlx_cfg0_in_rcv_tmpl_capability_1) // -- oc_cfg1:  input
 ,.tlx_cfg0_in_rcv_tmpl_capability_2 (oc1_tlx_cfg0_in_rcv_tmpl_capability_2) // -- oc_cfg1:  input
 ,.tlx_cfg0_in_rcv_tmpl_capability_3 (oc1_tlx_cfg0_in_rcv_tmpl_capability_3) // -- oc_cfg1:  input
 ,.tlx_cfg0_in_rcv_rate_capability_0 (oc1_tlx_cfg0_in_rcv_rate_capability_0) // -- oc_cfg1:  input  [3:0]
 ,.tlx_cfg0_in_rcv_rate_capability_1 (oc1_tlx_cfg0_in_rcv_rate_capability_1) // -- oc_cfg1:  input  [3:0]
 ,.tlx_cfg0_in_rcv_rate_capability_2 (oc1_tlx_cfg0_in_rcv_rate_capability_2) // -- oc_cfg1:  input  [3:0]
 ,.tlx_cfg0_in_rcv_rate_capability_3 (oc1_tlx_cfg0_in_rcv_rate_capability_3) // -- oc_cfg1:  input  [3:0]
 ,.tlx_afu_cmd_initial_credit        (oc1_tlx_afu_cmd_initial_credit       ) // -- oc_cfg1:  input  [3:0]
 ,.tlx_afu_resp_initial_credit       (oc1_tlx_afu_resp_initial_credit      ) // -- oc_cfg1:  input  [3:0]
 ,.tlx_afu_cmd_data_initial_credit   (oc1_tlx_afu_cmd_data_initial_credit  ) // -- oc_cfg1:  input  [5:0]
 ,.tlx_afu_resp_data_initial_credit  (oc1_tlx_afu_resp_data_initial_credit ) // -- oc_cfg1:  input  [5:0]
 ,.tlx_afu_cmd_credit                (oc1_tlx_afu_cmd_credit               ) // -- oc_cfg1:  input
 ,.afu_tlx_cmd_valid                 (oc1_afu_tlx_cmd_valid                ) // -- oc_cfg1:  output
 ,.afu_tlx_cmd_opcode                (oc1_afu_tlx_cmd_opcode               ) // -- oc_cfg1:  output [7:0]
 ,.afu_tlx_cmd_actag                 (oc1_afu_tlx_cmd_actag                ) // -- oc_cfg1:  output [11:0]
 ,.afu_tlx_cmd_stream_id             (oc1_afu_tlx_cmd_stream_id            ) // -- oc_cfg1:  output [3:0]
 ,.afu_tlx_cmd_ea_or_obj             (oc1_afu_tlx_cmd_ea_or_obj            ) // -- oc_cfg1:  output [67:0]
 ,.afu_tlx_cmd_afutag                (oc1_afu_tlx_cmd_afutag               ) // -- oc_cfg1:  output [15:0]
 ,.afu_tlx_cmd_dl                    (oc1_afu_tlx_cmd_dl                   ) // -- oc_cfg1:  output [1:0]
 ,.afu_tlx_cmd_pl                    (oc1_afu_tlx_cmd_pl                   ) // -- oc_cfg1:  output [2:0]
 ,.afu_tlx_cmd_os                    (oc1_afu_tlx_cmd_os                   ) // -- oc_cfg1:  output
 ,.afu_tlx_cmd_be                    (oc1_afu_tlx_cmd_be                   ) // -- oc_cfg1:  output [63:0]
 ,.afu_tlx_cmd_flag                  (oc1_afu_tlx_cmd_flag                 ) // -- oc_cfg1:  output [3:0]
 ,.afu_tlx_cmd_endian                (oc1_afu_tlx_cmd_endian               ) // -- oc_cfg1:  output
 ,.afu_tlx_cmd_bdf                   (oc1_afu_tlx_cmd_bdf                  ) // -- oc_cfg1:  output [15:0]
 ,.afu_tlx_cmd_pasid                 (oc1_afu_tlx_cmd_pasid                ) // -- oc_cfg1:  output [19:0]
 ,.afu_tlx_cmd_pg_size               (oc1_afu_tlx_cmd_pg_size              ) // -- oc_cfg1:  output [5:0]
 ,.tlx_afu_cmd_data_credit           (oc1_tlx_afu_cmd_data_credit          ) // -- oc_cfg1:  input
 ,.afu_tlx_cdata_valid               (oc1_afu_tlx_cdata_valid              ) // -- oc_cfg1:  output
 ,.afu_tlx_cdata_bus                 (oc1_afu_tlx_cdata_bus                ) // -- oc_cfg1:  output [511:0]
 ,.afu_tlx_cdata_bdi                 (oc1_afu_tlx_cdata_bdi                ) // -- oc_cfg1:  output
 ,.tlx_afu_resp_credit               (oc1_tlx_afu_resp_credit              ) // -- oc_cfg1:  input
 ,.afu_tlx_resp_valid                (oc1_afu_tlx_resp_valid               ) // -- oc_cfg1:  output
 ,.afu_tlx_resp_opcode               (oc1_afu_tlx_resp_opcode              ) // -- oc_cfg1:  output [7:0]
 ,.afu_tlx_resp_dl                   (oc1_afu_tlx_resp_dl                  ) // -- oc_cfg1:  output [1:0]
 ,.afu_tlx_resp_capptag              (oc1_afu_tlx_resp_capptag             ) // -- oc_cfg1:  output [15:0]
 ,.afu_tlx_resp_dp                   (oc1_afu_tlx_resp_dp                  ) // -- oc_cfg1:  output [1:0]
 ,.afu_tlx_resp_code                 (oc1_afu_tlx_resp_code                ) // -- oc_cfg1:  output [3:0]
 ,.tlx_afu_resp_data_credit          (oc1_tlx_afu_resp_data_credit         ) // -- oc_cfg1:  input
 ,.afu_tlx_rdata_valid               (oc1_afu_tlx_rdata_valid              ) // -- oc_cfg1:  output
 ,.afu_tlx_rdata_bus                 (oc1_afu_tlx_rdata_bus                ) // -- oc_cfg1:  output [511:0]
 ,.afu_tlx_rdata_bdi                 (oc1_afu_tlx_rdata_bdi                ) // -- oc_cfg1:  output
 ,.tlx_cfg0_valid                    (oc1_tlx_cfg0_valid                   ) // -- oc_cfg1:  input
 ,.tlx_cfg0_opcode                   (oc1_tlx_cfg0_opcode                  ) // -- oc_cfg1:  input  [7:0]
 ,.tlx_cfg0_pa                       (oc1_tlx_cfg0_pa                      ) // -- oc_cfg1:  input  [63:0]
 ,.tlx_cfg0_t                        (oc1_tlx_cfg0_t                       ) // -- oc_cfg1:  input
 ,.tlx_cfg0_pl                       (oc1_tlx_cfg0_pl                      ) // -- oc_cfg1:  input  [2:0]
 ,.tlx_cfg0_capptag                  (oc1_tlx_cfg0_capptag                 ) // -- oc_cfg1:  input  [15:0]
 ,.tlx_cfg0_data_bus                 (oc1_tlx_cfg0_data_bus                ) // -- oc_cfg1:  input  [31:0]
 ,.tlx_cfg0_data_bdi                 (oc1_tlx_cfg0_data_bdi                ) // -- oc_cfg1:  input
 ,.cfg0_tlx_initial_credit           (oc1_cfg0_tlx_initial_credit          ) // -- oc_cfg1:  output [3:0]
 ,.cfg0_tlx_credit_return            (oc1_cfg0_tlx_credit_return           ) // -- oc_cfg1:  output
 ,.cfg0_tlx_resp_valid               (oc1_cfg0_tlx_resp_valid              ) // -- oc_cfg1:  output
 ,.cfg0_tlx_resp_opcode              (oc1_cfg0_tlx_resp_opcode             ) // -- oc_cfg1:  output [7:0]
 ,.cfg0_tlx_resp_capptag             (oc1_cfg0_tlx_resp_capptag            ) // -- oc_cfg1:  output [15:0]
 ,.cfg0_tlx_resp_code                (oc1_cfg0_tlx_resp_code               ) // -- oc_cfg1:  output [3:0]
 ,.cfg0_tlx_rdata_offset             (oc1_cfg0_tlx_rdata_offset            ) // -- oc_cfg1:  output [3:0]
 ,.cfg0_tlx_rdata_bus                (oc1_cfg0_tlx_rdata_bus               ) // -- oc_cfg1:  output [31:0]
 ,.cfg0_tlx_rdata_bdi                (oc1_cfg0_tlx_rdata_bdi               ) // -- oc_cfg1:  output
 ,.tlx_cfg0_resp_ack                 (oc1_tlx_cfg0_resp_ack                ) // -- oc_cfg1:  input
 ,.cfg_vpd_addr                      (oc1_cfg_vpd_addr                     ) // -- oc_cfg1:  output [14:0]
 ,.cfg_vpd_wren                      (oc1_cfg_vpd_wren                     ) // -- oc_cfg1:  output
 ,.cfg_vpd_wdata                     (oc1_cfg_vpd_wdata                    ) // -- oc_cfg1:  output [31:0]
 ,.cfg_vpd_rden                      (oc1_cfg_vpd_rden                     ) // -- oc_cfg1:  output
 ,.vpd_cfg_rdata                     (oc1_vpd_cfg_rdata                    ) // -- oc_cfg1:  input  [31:0]
 ,.vpd_cfg_done                      (oc1_vpd_cfg_done                     ) // -- oc_cfg1:  input
 ,.cfg_flsh_devsel                   (oc1_cfg_flsh_devsel                  ) // -- oc_cfg1:  output [1:0]
 ,.cfg_flsh_addr                     (oc1_cfg_flsh_addr                    ) // -- oc_cfg1:  output [13:0]
 ,.cfg_flsh_wren                     (oc1_cfg_flsh_wren                    ) // -- oc_cfg1:  output
 ,.cfg_flsh_wdata                    (oc1_cfg_flsh_wdata                   ) // -- oc_cfg1:  output [31:0]
 ,.cfg_flsh_rden                     (oc1_cfg_flsh_rden                    ) // -- oc_cfg1:  output
 ,.flsh_cfg_rdata                    (oc1_flsh_cfg_rdata                   ) // -- oc_cfg1:  input  [31:0]
 ,.flsh_cfg_done                     (oc1_flsh_cfg_done                    ) // -- oc_cfg1:  input
 ,.flsh_cfg_status                   (oc1_flsh_cfg_status                  ) // -- oc_cfg1:  input  [7:0]
 ,.flsh_cfg_bresp                    (oc1_flsh_cfg_bresp                   ) // -- oc_cfg1:  input  [1:0]
 ,.flsh_cfg_rresp                    (oc1_flsh_cfg_rresp                   ) // -- oc_cfg1:  input  [1:0]
 ,.cfg_flsh_expand_enable            (oc1_cfg_flsh_expand_enable           ) // -- oc_cfg1:  output
 ,.cfg_flsh_expand_dir               (oc1_cfg_flsh_expand_dir              ) // -- oc_cfg1:  output
 ,.cfg0_bus_num                      (oc1_cfg0_bus_num                     ) // -- oc_cfg1:  output [7:0] 
 ,.cfg0_device_num                   (oc1_cfg0_device_num                  ) // -- oc_cfg1:  output [4:0] 
 ,.fen_afu_ready                     (oc1_fen_afu_ready                    ) // -- oc_cfg1:  output       
 ,.afu_fen_cmd_initial_credit        (oc1_afu_fen_cmd_initial_credit       ) // -- oc_cfg1:  input  [6:0] 
 ,.afu_fen_cmd_credit                (oc1_afu_fen_cmd_credit               ) // -- oc_cfg1:  input        
 ,.fen_afu_cmd_valid                 (oc1_fen_afu_cmd_valid                ) // -- oc_cfg1:  output       
 ,.fen_afu_cmd_opcode                (oc1_fen_afu_cmd_opcode               ) // -- oc_cfg1:  output [7:0] 
 ,.fen_afu_cmd_dl                    (oc1_fen_afu_cmd_dl                   ) // -- oc_cfg1:  output [1:0] 
 ,.fen_afu_cmd_end                   (oc1_fen_afu_cmd_end                  ) // -- oc_cfg1:  output       
 ,.fen_afu_cmd_pa                    (oc1_fen_afu_cmd_pa                   ) // -- oc_cfg1:  output [63:0]
 ,.fen_afu_cmd_flag                  (oc1_fen_afu_cmd_flag                 ) // -- oc_cfg1:  output [3:0] 
 ,.fen_afu_cmd_os                    (oc1_fen_afu_cmd_os                   ) // -- oc_cfg1:  output       
 ,.fen_afu_cmd_capptag               (oc1_fen_afu_cmd_capptag              ) // -- oc_cfg1:  output [15:0]
 ,.fen_afu_cmd_pl                    (oc1_fen_afu_cmd_pl                   ) // -- oc_cfg1:  output [2:0] 
 ,.fen_afu_cmd_be                    (oc1_fen_afu_cmd_be                   ) // -- oc_cfg1:  output [63:0]
 ,.afu_fen_resp_initial_credit       (oc1_afu_fen_resp_initial_credit      ) // -- oc_cfg1:  input  [6:0] 
 ,.afu_fen_resp_credit               (oc1_afu_fen_resp_credit              ) // -- oc_cfg1:  input  
 ,.fen_afu_resp_valid                (oc1_fen_afu_resp_valid               ) // -- oc_cfg1:  output 
 ,.fen_afu_resp_opcode               (oc1_fen_afu_resp_opcode              ) // -- oc_cfg1:  output [7:0]
 ,.fen_afu_resp_afutag               (oc1_fen_afu_resp_afutag              ) // -- oc_cfg1:  output [15:0]
 ,.fen_afu_resp_code                 (oc1_fen_afu_resp_code                ) // -- oc_cfg1:  output [3:0]
 ,.fen_afu_resp_pg_size              (oc1_fen_afu_resp_pg_size             ) // -- oc_cfg1:  output [5:0]
 ,.fen_afu_resp_dl                   (oc1_fen_afu_resp_dl                  ) // -- oc_cfg1:  output [1:0]
 ,.fen_afu_resp_dp                   (oc1_fen_afu_resp_dp                  ) // -- oc_cfg1:  output [1:0]
 ,.fen_afu_resp_host_tag             (oc1_fen_afu_resp_host_tag            ) // -- oc_cfg1:  output [23:0]
 ,.fen_afu_resp_cache_state          (oc1_fen_afu_resp_cache_state         ) // -- oc_cfg1:  output [3:0]
 ,.fen_afu_resp_addr_tag             (oc1_fen_afu_resp_addr_tag            ) // -- oc_cfg1:  output [17:0]
 ,.afu_fen_cmd_rd_req                (oc1_afu_fen_cmd_rd_req               ) // -- oc_cfg1:  input  
 ,.afu_fen_cmd_rd_cnt                (oc1_afu_fen_cmd_rd_cnt               ) // -- oc_cfg1:  input  [2:0]
 ,.fen_afu_cmd_data_valid            (oc1_fen_afu_cmd_data_valid           ) // -- oc_cfg1:  output 
 ,.fen_afu_cmd_data_bdi              (oc1_fen_afu_cmd_data_bdi             ) // -- oc_cfg1:  output 
 ,.fen_afu_cmd_data_bus              (oc1_fen_afu_cmd_data_bus             ) // -- oc_cfg1:  output [511:0]
 ,.afu_fen_resp_rd_req               (oc1_afu_fen_resp_rd_req              ) // -- oc_cfg1:  input  
 ,.afu_fen_resp_rd_cnt               (oc1_afu_fen_resp_rd_cnt              ) // -- oc_cfg1:  input  [2:0]
 ,.fen_afu_resp_data_valid           (oc1_fen_afu_resp_data_valid          ) // -- oc_cfg1:  output 
 ,.fen_afu_resp_data_bdi             (oc1_fen_afu_resp_data_bdi            ) // -- oc_cfg1:  output 
 ,.fen_afu_resp_data_bus             (oc1_fen_afu_resp_data_bus            ) // -- oc_cfg1:  output [511:0]
 ,.fen_afu_cmd_initial_credit        (oc1_fen_afu_cmd_initial_credit       ) // -- oc_cfg1:  output [3:0]
 ,.fen_afu_resp_initial_credit       (oc1_fen_afu_resp_initial_credit      ) // -- oc_cfg1:  output [3:0]
 ,.fen_afu_cmd_data_initial_credit   (oc1_fen_afu_cmd_data_initial_credit  ) // -- oc_cfg1:  output [5:0]
 ,.fen_afu_resp_data_initial_credit  (oc1_fen_afu_resp_data_initial_credit ) // -- oc_cfg1:  output [5:0]
 ,.fen_afu_cmd_credit                (oc1_fen_afu_cmd_credit               ) // -- oc_cfg1:  output 
 ,.afu_fen_cmd_valid                 (oc1_afu_fen_cmd_valid                ) // -- oc_cfg1:  input  
 ,.afu_fen_cmd_opcode                (oc1_afu_fen_cmd_opcode               ) // -- oc_cfg1:  input  [7:0]
 ,.afu_fen_cmd_actag                 (oc1_afu_fen_cmd_actag                ) // -- oc_cfg1:  input  [11:0]
 ,.afu_fen_cmd_stream_id             (oc1_afu_fen_cmd_stream_id            ) // -- oc_cfg1:  input  [3:0]
 ,.afu_fen_cmd_ea_or_obj             (oc1_afu_fen_cmd_ea_or_obj            ) // -- oc_cfg1:  input  [67:0]
 ,.afu_fen_cmd_afutag                (oc1_afu_fen_cmd_afutag               ) // -- oc_cfg1:  input  [15:0]
 ,.afu_fen_cmd_dl                    (oc1_afu_fen_cmd_dl                   ) // -- oc_cfg1:  input  [1:0]
 ,.afu_fen_cmd_pl                    (oc1_afu_fen_cmd_pl                   ) // -- oc_cfg1:  input  [2:0]
 ,.afu_fen_cmd_os                    (oc1_afu_fen_cmd_os                   ) // -- oc_cfg1:  input  
 ,.afu_fen_cmd_be                    (oc1_afu_fen_cmd_be                   ) // -- oc_cfg1:  input  [63:0]
 ,.afu_fen_cmd_flag                  (oc1_afu_fen_cmd_flag                 ) // -- oc_cfg1:  input  [3:0]
 ,.afu_fen_cmd_endian                (oc1_afu_fen_cmd_endian               ) // -- oc_cfg1:  input  
 ,.afu_fen_cmd_bdf                   (oc1_afu_fen_cmd_bdf                  ) // -- oc_cfg1:  input  [15:0]
 ,.afu_fen_cmd_pasid                 (oc1_afu_fen_cmd_pasid                ) // -- oc_cfg1:  input  [19:0]
 ,.afu_fen_cmd_pg_size               (oc1_afu_fen_cmd_pg_size              ) // -- oc_cfg1:  input  [5:0]
 ,.fen_afu_cmd_data_credit           (oc1_fen_afu_cmd_data_credit          ) // -- oc_cfg1:  output 
 ,.afu_fen_cdata_valid               (oc1_afu_fen_cdata_valid              ) // -- oc_cfg1:  input  
 ,.afu_fen_cdata_bus                 (oc1_afu_fen_cdata_bus                ) // -- oc_cfg1:  input  [511:0]
 ,.afu_fen_cdata_bdi                 (oc1_afu_fen_cdata_bdi                ) // -- oc_cfg1:  input  
 ,.fen_afu_resp_credit               (oc1_fen_afu_resp_credit              ) // -- oc_cfg1:  output 
 ,.afu_fen_resp_valid                (oc1_afu_fen_resp_valid               ) // -- oc_cfg1:  input  
 ,.afu_fen_resp_opcode               (oc1_afu_fen_resp_opcode              ) // -- oc_cfg1:  input  [7:0]
 ,.afu_fen_resp_dl                   (oc1_afu_fen_resp_dl                  ) // -- oc_cfg1:  input  [1:0]
 ,.afu_fen_resp_capptag              (oc1_afu_fen_resp_capptag             ) // -- oc_cfg1:  input  [15:0]
 ,.afu_fen_resp_dp                   (oc1_afu_fen_resp_dp                  ) // -- oc_cfg1:  input  [1:0]
 ,.afu_fen_resp_code                 (oc1_afu_fen_resp_code                ) // -- oc_cfg1:  input  [3:0]
 ,.fen_afu_resp_data_credit          (oc1_fen_afu_resp_data_credit         ) // -- oc_cfg1:  output 
 ,.afu_fen_rdata_valid               (oc1_afu_fen_rdata_valid              ) // -- oc_cfg1:  input  
 ,.afu_fen_rdata_bus                 (oc1_afu_fen_rdata_bus                ) // -- oc_cfg1:  input  [511:0]
 ,.afu_fen_rdata_bdi                 (oc1_afu_fen_rdata_bdi                ) // -- oc_cfg1:  input  
 ,.cfg_function                      (oc1_cfg_function                     ) // -- oc_cfg1:  output [2:0]
 ,.cfg_portnum                       (oc1_cfg_portnum                      ) // -- oc_cfg1:  output [1:0]
 ,.cfg_addr                          (oc1_cfg_addr                         ) // -- oc_cfg1:  output [11:0]
 ,.cfg_wdata                         (oc1_cfg_wdata                        ) // -- oc_cfg1:  output [31:0]
 ,.cfg_f1_rdata                      (oc1_cfg_f1_rdata                     ) // -- oc_cfg1:  input  [31:0]
 ,.cfg_f1_rdata_vld                  (oc1_cfg_f1_rdata_vld                 ) // -- oc_cfg1:  input  
 ,.cfg_wr_1B                         (oc1_cfg_wr_1B                        ) // -- oc_cfg1:  output 
 ,.cfg_wr_2B                         (oc1_cfg_wr_2B                        ) // -- oc_cfg1:  output 
 ,.cfg_wr_4B                         (oc1_cfg_wr_4B                        ) // -- oc_cfg1:  output 
 ,.cfg_rd                            (oc1_cfg_rd                           ) // -- oc_cfg1:  output 
 ,.cfg_f1_bad_op_or_align            (oc1_cfg_f1_bad_op_or_align           ) // -- oc_cfg1:  input  
 ,.cfg_f1_addr_not_implemented       (oc1_cfg_f1_addr_not_implemented      ) // -- oc_cfg1:  input  
 ,.cfg_f1_octrl00_fence_afu          (oc1_cfg_f1_octrl00_fence_afu         ) // -- oc_cfg1:  input  
 ,.cfg_f0_otl0_long_backoff_timer    (oc1_cfg_f0_otl0_long_backoff_timer   ) // -- oc_cfg1:  output [3:0]
 ,.cfg_f0_otl0_short_backoff_timer   (oc1_cfg_f0_otl0_short_backoff_timer  ) // -- oc_cfg1:  output [3:0]
 ,.cfg0_cff_fifo_overflow            (oc1_cfg0_cff_fifo_overflow           ) // -- oc_cfg1:  output 
 ,.cfg0_rff_fifo_overflow            (oc1_cfg0_rff_fifo_overflow           ) // -- oc_cfg1:  output 
 ,.cfg_errvec                        (oc1_cfg_errvec                       ) // -- oc_cfg1:  output [127:0]
 ,.cfg_errvec_valid                  (oc1_cfg_errvec_valid                 ) // -- oc_cfg1:  output 
 ,.f1_csh_expansion_rom_bar          (oc1_f1_ro_csh_expansion_rom_bar      ) // -- oc_cfg1:  output [31:0]
 ,.f1_csh_subsystem_id               (oc1_f1_ro_csh_subsystem_id           ) // -- oc_cfg1:  output [15:0]
 ,.f1_csh_subsystem_vendor_id        (oc1_f1_ro_csh_subsystem_vendor_id    ) // -- oc_cfg1:  output [15:0]
 ,.f1_csh_mmio_bar0_size             (oc1_f1_ro_csh_mmio_bar0_size         ) // -- oc_cfg1:  output [63:0]
 ,.f1_csh_mmio_bar1_size             (oc1_f1_ro_csh_mmio_bar1_size         ) // -- oc_cfg1:  output [63:0]
 ,.f1_csh_mmio_bar2_size             (oc1_f1_ro_csh_mmio_bar2_size         ) // -- oc_cfg1:  output [63:0]
 ,.f1_csh_mmio_bar0_prefetchable     (oc1_f1_ro_csh_mmio_bar0_prefetchable ) // -- oc_cfg1:  output 
 ,.f1_csh_mmio_bar1_prefetchable     (oc1_f1_ro_csh_mmio_bar1_prefetchable ) // -- oc_cfg1:  output 
 ,.f1_csh_mmio_bar2_prefetchable     (oc1_f1_ro_csh_mmio_bar2_prefetchable ) // -- oc_cfg1:  output 
 ,.f1_pasid_max_pasid_width          (oc1_f1_ro_pasid_max_pasid_width      ) // -- oc_cfg1:  output [4:0]
 ,.f1_ofunc_reset_duration           (oc1_f1_ro_ofunc_reset_duration       ) // -- oc_cfg1:  output [7:0]
 ,.f1_ofunc_afu_present              (oc1_f1_ro_ofunc_afu_present          ) // -- oc_cfg1:  output 
 ,.f1_ofunc_max_afu_index            (oc1_f1_ro_ofunc_max_afu_index        ) // -- oc_cfg1:  output [4:0]
 ,.f1_octrl00_reset_duration         (oc1_f1_ro_octrl00_reset_duration     ) // -- oc_cfg1:  output [7:0]
 ,.f1_octrl00_afu_control_index      (oc1_f1_ro_octrl00_afu_control_index  ) // -- oc_cfg1:  output [5:0]
 ,.f1_octrl00_pasid_len_supported    (oc1_f1_ro_octrl00_pasid_len_supported) // -- oc_cfg1:  output [4:0]
 ,.f1_octrl00_metadata_supported     (oc1_f1_ro_octrl00_metadata_supported ) // -- oc_cfg1:  output 
 ,.f1_octrl00_actag_len_supported    (oc1_f1_ro_octrl00_actag_len_supported) // -- oc_cfg1:  output [11:0]       
);

oc_function oc_func1(
   .clock_tlx                              (oc1_clock_tlx                          ) // -- oc_function1:   input  
  ,.clock_afu                              (oc1_clock_afu                          ) // -- oc_function1:   input  
  ,.reset                                  (oc1_reset                              ) // -- oc_function1:   input  
    // Bus number comes from CFG_SEQ
  ,.cfg_bus                                (oc1_cfg0_bus_num                       ) // -- oc_function1:   input  [7:0]
    // Hardcoded configuration inputs
  ,.ro_device                              (oc1_cfg0_device_num                    ) // -- oc_function1:   input  [4:0]
  ,.ro_function                            (3'b001                                 ) // -- oc_function1:   input  [2:0]
    // -----------------------------------
    // TLX Parser -> AFU Receive Interface
    // -----------------------------------
  ,.tlx_afu_ready                          (oc1_fen_afu_ready                      ) // -- oc_function1:   input  
    // Command interface to AFU
  ,.afu_tlx_cmd_initial_credit             (oc1_afu_fen_cmd_initial_credit         ) // -- oc_function1:   output [6:0]
  ,.afu_tlx_cmd_credit                     (oc1_afu_fen_cmd_credit                 ) // -- oc_function1:   output 
  ,.tlx_afu_cmd_valid                      (oc1_fen_afu_cmd_valid                  ) // -- oc_function1:   input  
  ,.tlx_afu_cmd_opcode                     (oc1_fen_afu_cmd_opcode                 ) // -- oc_function1:   input  [7:0]
  ,.tlx_afu_cmd_dl                         (oc1_fen_afu_cmd_dl                     ) // -- oc_function1:   input  [1:0]
  ,.tlx_afu_cmd_end                        (oc1_fen_afu_cmd_end                    ) // -- oc_function1:   input  
  ,.tlx_afu_cmd_pa                         (oc1_fen_afu_cmd_pa                     ) // -- oc_function1:   input  [63:0]
  ,.tlx_afu_cmd_flag                       (oc1_fen_afu_cmd_flag                   ) // -- oc_function1:   input  [3:0]
  ,.tlx_afu_cmd_os                         (oc1_fen_afu_cmd_os                     ) // -- oc_function1:   input  
  ,.tlx_afu_cmd_capptag                    (oc1_fen_afu_cmd_capptag                ) // -- oc_function1:   input  [15:0]
  ,.tlx_afu_cmd_pl                         (oc1_fen_afu_cmd_pl                     ) // -- oc_function1:   input  [2:0]
  ,.tlx_afu_cmd_be                         (oc1_fen_afu_cmd_be                     ) // -- oc_function1:   input  [63:0]
    // Response interface to AFU
  ,.afu_tlx_resp_initial_credit            (oc1_afu_fen_resp_initial_credit        ) // -- oc_function1:   output [6:0]
  ,.afu_tlx_resp_credit                    (oc1_afu_fen_resp_credit                ) // -- oc_function1:   output 
  ,.tlx_afu_resp_valid                     (oc1_fen_afu_resp_valid                 ) // -- oc_function1:   input  
  ,.tlx_afu_resp_opcode                    (oc1_fen_afu_resp_opcode                ) // -- oc_function1:   input  [7:0]
  ,.tlx_afu_resp_afutag                    (oc1_fen_afu_resp_afutag                ) // -- oc_function1:   input  [15:0]
  ,.tlx_afu_resp_code                      (oc1_fen_afu_resp_code                  ) // -- oc_function1:   input  [3:0]
  ,.tlx_afu_resp_pg_size                   (oc1_fen_afu_resp_pg_size               ) // -- oc_function1:   input  [5:0]
  ,.tlx_afu_resp_dl                        (oc1_fen_afu_resp_dl                    ) // -- oc_function1:   input  [1:0]
  ,.tlx_afu_resp_dp                        (oc1_fen_afu_resp_dp                    ) // -- oc_function1:   input  [1:0]
  ,.tlx_afu_resp_host_tag                  (oc1_fen_afu_resp_host_tag              ) // -- oc_function1:   input  [23:0]
  ,.tlx_afu_resp_cache_state               (oc1_fen_afu_resp_cache_state           ) // -- oc_function1:   input  [3:0]
  ,.tlx_afu_resp_addr_tag                  (oc1_fen_afu_resp_addr_tag              ) // -- oc_function1:   input  [17:0]
    // Command data interface to AFU
  ,.afu_tlx_cmd_rd_req                     (oc1_afu_fen_cmd_rd_req                 ) // -- oc_function1:   output 
  ,.afu_tlx_cmd_rd_cnt                     (oc1_afu_fen_cmd_rd_cnt                 ) // -- oc_function1:   output [2:0]
  ,.tlx_afu_cmd_data_valid                 (oc1_fen_afu_cmd_data_valid             ) // -- oc_function1:   input  
  ,.tlx_afu_cmd_data_bdi                   (oc1_fen_afu_cmd_data_bdi               ) // -- oc_function1:   input  
  ,.tlx_afu_cmd_data_bus                   (oc1_fen_afu_cmd_data_bus               ) // -- oc_function1:   input  [511:0]
    // Response data interface to AFU
  ,.afu_tlx_resp_rd_req                    (oc1_afu_fen_resp_rd_req                ) // -- oc_function1:   output 
  ,.afu_tlx_resp_rd_cnt                    (oc1_afu_fen_resp_rd_cnt                ) // -- oc_function1:   output [2:0]
  ,.tlx_afu_resp_data_valid                (oc1_fen_afu_resp_data_valid            ) // -- oc_function1:   input  
  ,.tlx_afu_resp_data_bdi                  (oc1_fen_afu_resp_data_bdi              ) // -- oc_function1:   input  
  ,.tlx_afu_resp_data_bus                  (oc1_fen_afu_resp_data_bus              ) // -- oc_function1:   input  [511:0]
    // ------------------------------------
    // AFU -> TLX Framer Transmit Interface
    // ------------------------------------
    // Initial credit allocation
  ,.tlx_afu_cmd_initial_credit             (oc1_fen_afu_cmd_initial_credit         ) // -- oc_function1:   input  [3:0]
  ,.tlx_afu_resp_initial_credit            (oc1_fen_afu_resp_initial_credit        ) // -- oc_function1:   input  [3:0]
  ,.tlx_afu_cmd_data_initial_credit        (oc1_fen_afu_cmd_data_initial_credit    ) // -- oc_function1:   input  [5:0]
  ,.tlx_afu_resp_data_initial_credit       (oc1_fen_afu_resp_data_initial_credit   ) // -- oc_function1:   input  [5:0]

    // Commands from AFU
  ,.tlx_afu_cmd_credit                     (oc1_fen_afu_cmd_credit                 ) // -- oc_function1:   input  
  ,.afu_tlx_cmd_valid                      (oc1_afu_fen_cmd_valid                  ) // -- oc_function1:   output 
  ,.afu_tlx_cmd_opcode                     (oc1_afu_fen_cmd_opcode                 ) // -- oc_function1:   output [7:0]
  ,.afu_tlx_cmd_actag                      (oc1_afu_fen_cmd_actag                  ) // -- oc_function1:   output [11:0]
  ,.afu_tlx_cmd_stream_id                  (oc1_afu_fen_cmd_stream_id              ) // -- oc_function1:   output [3:0]
  ,.afu_tlx_cmd_ea_or_obj                  (oc1_afu_fen_cmd_ea_or_obj              ) // -- oc_function1:   output [67:0]
  ,.afu_tlx_cmd_afutag                     (oc1_afu_fen_cmd_afutag                 ) // -- oc_function1:   output [15:0]
  ,.afu_tlx_cmd_dl                         (oc1_afu_fen_cmd_dl                     ) // -- oc_function1:   output [1:0]
  ,.afu_tlx_cmd_pl                         (oc1_afu_fen_cmd_pl                     ) // -- oc_function1:   output [2:0]
  ,.afu_tlx_cmd_os                         (oc1_afu_fen_cmd_os                     ) // -- oc_function1:   output 
  ,.afu_tlx_cmd_be                         (oc1_afu_fen_cmd_be                     ) // -- oc_function1:   output [63:0]
  ,.afu_tlx_cmd_flag                       (oc1_afu_fen_cmd_flag                   ) // -- oc_function1:   output [3:0]
  ,.afu_tlx_cmd_endian                     (oc1_afu_fen_cmd_endian                 ) // -- oc_function1:   output 
  ,.afu_tlx_cmd_bdf                        (oc1_afu_fen_cmd_bdf                    ) // -- oc_function1:   output [15:0]
  ,.afu_tlx_cmd_pasid                      (oc1_afu_fen_cmd_pasid                  ) // -- oc_function1:   output [19:0]
  ,.afu_tlx_cmd_pg_size                    (oc1_afu_fen_cmd_pg_size                ) // -- oc_function1:   output [5:0]
    // Command data from AFU
  ,.tlx_afu_cmd_data_credit                (oc1_fen_afu_cmd_data_credit            ) // -- oc_function1:   input  
  ,.afu_tlx_cdata_valid                    (oc1_afu_fen_cdata_valid                ) // -- oc_function1:   output 
  ,.afu_tlx_cdata_bus                      (oc1_afu_fen_cdata_bus                  ) // -- oc_function1:   output [511:0]
  ,.afu_tlx_cdata_bdi                      (oc1_afu_fen_cdata_bdi                  ) // -- oc_function1:   output 
    // Responses from AFU
  ,.tlx_afu_resp_credit                    (oc1_fen_afu_resp_credit                ) // -- oc_function1:   output 
  ,.afu_tlx_resp_valid                     (oc1_afu_fen_resp_valid                 ) // -- oc_function1:   input  
  ,.afu_tlx_resp_opcode                    (oc1_afu_fen_resp_opcode                ) // -- oc_function1:   output [7:0]
  ,.afu_tlx_resp_dl                        (oc1_afu_fen_resp_dl                    ) // -- oc_function1:   output [1:0]
  ,.afu_tlx_resp_capptag                   (oc1_afu_fen_resp_capptag               ) // -- oc_function1:   output [15:0]
  ,.afu_tlx_resp_dp                        (oc1_afu_fen_resp_dp                    ) // -- oc_function1:   output [1:0]
  ,.afu_tlx_resp_code                      (oc1_afu_fen_resp_code                  ) // -- oc_function1:   output [3:0]
    // Response data from AFU
  ,.tlx_afu_resp_data_credit               (oc1_fen_afu_resp_data_credit           ) // -- oc_function1:   input   
  ,.afu_tlx_rdata_valid                    (oc1_afu_fen_rdata_valid                ) // -- oc_function1:   output 
  ,.afu_tlx_rdata_bus                      (oc1_afu_fen_rdata_bus                  ) // -- oc_function1:   output [511:0]
  ,.afu_tlx_rdata_bdi                      (oc1_afu_fen_rdata_bdi                  ) // -- oc_function1:   output 
    // -------------------------------------------------------------
    // Configuration Sequencer Interface [CFG_SEQ -> CFG_Fn (n=1-7)]
    // -------------------------------------------------------------
  ,.cfg_function                           (oc1_cfg_function                       ) // -- oc_function1:   input  [2:0]
  ,.cfg_portnum                            (oc1_cfg_portnum                        ) // -- oc_function1:   input  [1:0]
  ,.cfg_addr                               (oc1_cfg_addr                           ) // -- oc_function1:   input  [11:0]
  ,.cfg_wdata                              (oc1_cfg_wdata                          ) // -- oc_function1:   input  [31:0]
  ,.cfg_f1_rdata                           (oc1_cfg_f1_rdata                       ) // -- oc_function1:   output [31:0]
  ,.cfg_f1_rdata_vld                       (oc1_cfg_f1_rdata_vld                   ) // -- oc_function1:   output 
  ,.cfg_wr_1B                              (oc1_cfg_wr_1B                          ) // -- oc_function1:   input  
  ,.cfg_wr_2B                              (oc1_cfg_wr_2B                          ) // -- oc_function1:   input  
  ,.cfg_wr_4B                              (oc1_cfg_wr_4B                          ) // -- oc_function1:   input  
  ,.cfg_rd                                 (oc1_cfg_rd                             ) // -- oc_function1:   input  
  ,.cfg_f1_bad_op_or_align                 (oc1_cfg_f1_bad_op_or_align             ) // -- oc_function1:   output 
  ,.cfg_f1_addr_not_implemented            (oc1_cfg_f1_addr_not_implemented        ) // -- oc_function1:   output 
    // ------------------------------------
    // Other signals
    // ------------------------------------
    // Fence control
  ,.cfg_f1_octrl00_fence_afu               (oc1_cfg_f1_octrl00_fence_afu           ) // -- oc_function1:   output 
    // TLX Configuration for the TLX port(s) connected to AFUs under this Function
  ,.cfg_f0_otl0_long_backoff_timer         (oc1_cfg_f0_otl0_long_backoff_timer     ) // -- oc_function1:   input  [3:0]
  ,.cfg_f0_otl0_short_backoff_timer        (oc1_cfg_f0_otl0_short_backoff_timer    ) // -- oc_function1:   input  [3:0]
    // Error signals into MMIO capture register
  ,.vpd_err_unimplemented_addr             (oc1_vpd_err_unimplemented_addr         ) // -- oc_function1:   input  
  ,.cfg0_cff_fifo_overflow                 (oc1_cfg0_cff_fifo_overflow             ) // -- oc_function1:   input  
  ,.cfg1_cff_fifo_overflow                 (1'b0                                   ) // -- oc_function1:   input  
  ,.cfg0_rff_fifo_overflow                 (oc1_cfg0_rff_fifo_overflow             ) // -- oc_function1:   input  
  ,.cfg1_rff_fifo_overflow                 (1'b0                                   ) // -- oc_function1:   input  
  ,.cfg_errvec                             (oc1_cfg_errvec                         ) // -- oc_function1:   input  [127:0]
  ,.cfg_errvec_valid                       (oc1_cfg_errvec_valid                   ) // -- oc_function1:   input  
    // Resync credits control
  ,.cfg_f1_octrl00_resync_credits          (oc1_cfg_f1_octrl00_resync_credits      ) // -- oc_function1:   output 

  ,.f1_csh_expansion_rom_bar               (oc1_f1_ro_csh_expansion_rom_bar        ) // -- oc_function1:   input  [31:0]
  ,.f1_csh_subsystem_id                    (oc1_f1_ro_csh_subsystem_id             ) // -- oc_function1:   input  [15:0]
  ,.f1_csh_subsystem_vendor_id             (oc1_f1_ro_csh_subsystem_vendor_id      ) // -- oc_function1:   input  [15:0]
  ,.f1_csh_mmio_bar0_size                  (oc1_f1_ro_csh_mmio_bar0_size           ) // -- oc_function1:   input  [63:0]
  ,.f1_csh_mmio_bar1_size                  (oc1_f1_ro_csh_mmio_bar1_size           ) // -- oc_function1:   input  [63:0]
  ,.f1_csh_mmio_bar2_size                  (oc1_f1_ro_csh_mmio_bar2_size           ) // -- oc_function1:   input  [63:0]
  ,.f1_csh_mmio_bar0_prefetchable          (oc1_f1_ro_csh_mmio_bar0_prefetchable   ) // -- oc_function1:   input  
  ,.f1_csh_mmio_bar1_prefetchable          (oc1_f1_ro_csh_mmio_bar1_prefetchable   ) // -- oc_function1:   input  
  ,.f1_csh_mmio_bar2_prefetchable          (oc1_f1_ro_csh_mmio_bar2_prefetchable   ) // -- oc_function1:   input  
  ,.f1_pasid_max_pasid_width               (oc1_f1_ro_pasid_max_pasid_width        ) // -- oc_function1:   input  [4:0]
  ,.f1_ofunc_reset_duration                (oc1_f1_ro_ofunc_reset_duration         ) // -- oc_function1:   input  [7:0]
  ,.f1_ofunc_afu_present                   (oc1_f1_ro_ofunc_afu_present            ) // -- oc_function1:   input  
  ,.f1_ofunc_max_afu_index                 (oc1_f1_ro_ofunc_max_afu_index          ) // -- oc_function1:   input  [4:0]
  ,.f1_octrl00_reset_duration              (oc1_f1_ro_octrl00_reset_duration       ) // -- oc_function1:   input  [7:0]
  ,.f1_octrl00_afu_control_index           (oc1_f1_ro_octrl00_afu_control_index    ) // -- oc_function1:   input  [5:0]
  ,.f1_octrl00_pasid_len_supported         (oc1_f1_ro_octrl00_pasid_len_supported  ) // -- oc_function1:   input  [4:0]
  ,.f1_octrl00_metadata_supported          (oc1_f1_ro_octrl00_metadata_supported   ) // -- oc_function1:   input  
  ,.f1_octrl00_actag_len_supported         (oc1_f1_ro_octrl00_actag_len_supported  ) // -- oc_function1:   input  [11:0]
);
`endif

endmodule //-- oc_fpga_top
