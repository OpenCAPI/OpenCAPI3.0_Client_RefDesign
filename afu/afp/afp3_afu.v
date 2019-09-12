// *!***************************************************************************
// *! Copyright 2019 International Business Machines
// *!
// *! Licensed under the Apache License, Version 2.0 (the "License");
// *! you may not use this file except in compliance with the License.
// *! You may obtain a copy of the License at
// *! http://www.apache.org/licenses/LICENSE-2.0 
// *!
// *! The patent license granted to you in Section 3 of the License, as applied
// *! to the "Work," hereby includes implementations of the Work in physical form.  
// *!
// *! Unless required by applicable law or agreed to in writing, the reference design
// *! distributed under the License is distributed on an "AS IS" BASIS,
// *! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// *! See the License for the specific language governing permissions and
// *! limitations under the License.
// *! 
// *! The background Specification upon which this is based is managed by and available from
// *! the OpenCAPI Consortium.  More information can be found at https://opencapi.org. 
// *!***************************************************************************
`timescale 1ns / 1ps

module afp3_afu (

  // -- Clocks & Reset
    input                 clock_tlx
  , input                 clock_afu
  , input                 reset

  // -- AFU Index
  , input           [5:0] afu_index                            // -- This AFU's Index within the Function
                                                             
  // -- TLX_AFU command receive interface                    
  , input                 tlx_afu_ready                        // -- TLX indicates it is ready to receive cmds and responses from AFU
  , input                 tlx_afu_cmd_valid                    // -- Command Valid (Receive)
  , input           [7:0] tlx_afu_cmd_opcode                   // -- Command Opcode
  , input          [15:0] tlx_afu_cmd_capptag                  // -- Command Tag
  , input           [1:0] tlx_afu_cmd_dl                       // -- Command Data Length
  , input           [2:0] tlx_afu_cmd_pl                       // -- Command Partial Length
  , input          [63:0] tlx_afu_cmd_be                       // -- Command Byte Enable
  , input                 tlx_afu_cmd_end                      // -- Endianness
  , input          [63:0] tlx_afu_cmd_pa                       // -- Physical Address
  , input           [3:0] tlx_afu_cmd_flag                     // -- Atomic memory operation specifier
  , input                 tlx_afu_cmd_os                       // -- Ordered segment
                                                             
  , output                afu_tlx_cmd_rd_req                   // -- Command Read Request
  , output          [2:0] afu_tlx_cmd_rd_cnt                   // -- Command Read Count
                                                             
  , input                 tlx_afu_cmd_data_valid               // -- Command Data Valid. Indicates valid data available
  , input                 tlx_afu_cmd_data_bdi                 // -- Command Data Bad Data Indicator
  , input         [511:0] tlx_afu_cmd_data_bus                 // -- Command Data Bus
                                                                         
  , output                afu_tlx_cmd_credit                   // -- AFU returns cmd credit to TLX
  , output          [6:0] afu_tlx_cmd_initial_credit           // -- AFU indicates number of command credits available (static value)
                                                             
  // -- AFU_TLX response transmit interface                  
  , output                afu_tlx_resp_valid                   // -- Response Valid (Transmit)
  , output          [7:0] afu_tlx_resp_opcode                  // -- Response Opcode
  , output          [1:0] afu_tlx_resp_dl                      // -- Response Data Length
  , output         [15:0] afu_tlx_resp_capptag                 // -- Response Tag
  , output          [1:0] afu_tlx_resp_dp                      // -- Response Data Part - indicates the data content of the current response packet
  , output          [3:0] afu_tlx_resp_code                    // -- Response Code - reason for failed transaction
                                                             
  , output                afu_tlx_rdata_valid                  // -- Response Valid
  , output                afu_tlx_rdata_bdi                    // -- Response Bad Data Indicator
  , output        [511:0] afu_tlx_rdata_bus                    // -- Response Opcode
                                                             
  , input                 tlx_afu_resp_credit                  // -- TLX returns resp credit to AFU when resp taken from FIFO by DLX
  , input                 tlx_afu_resp_data_credit             // -- TLX returns resp data credit to AFU when resp data taken from FIFO by DLX
                                                             
  // -- AFU_TLX command transmit interface                   
  , output                afu_tlx_cmd_valid                    // -- Command Valid (Transmit)
  , output          [7:0] afu_tlx_cmd_opcode                   // -- Command Opcode
  , output         [11:0] afu_tlx_cmd_actag                    // -- Address Context Tag
  , output          [3:0] afu_tlx_cmd_stream_id                // -- Stream ID
  , output         [67:0] afu_tlx_cmd_ea_or_obj                // -- Effective Address/Object Handle
  , output         [15:0] afu_tlx_cmd_afutag                   // -- Command Tag
  , output          [1:0] afu_tlx_cmd_dl                       // -- Command Data Length
  , output          [2:0] afu_tlx_cmd_pl                       // -- Partial Length
  , output                afu_tlx_cmd_os                       // -- Ordered Segment
  , output         [63:0] afu_tlx_cmd_be                       // -- Byte Enable
  , output          [3:0] afu_tlx_cmd_flag                     // -- Command Flag, used in atomic operations
  , output                afu_tlx_cmd_endian                   // -- Endianness
  , output         [15:0] afu_tlx_cmd_bdf                      // -- Bus Device Function
  , output         [19:0] afu_tlx_cmd_pasid                    // -- User Process ID
  , output          [5:0] afu_tlx_cmd_pg_size                  // -- Page Size
                                                             
  , output                afu_tlx_cdata_valid                  // -- Command Data Valid. Indicates valid data available
  , output                afu_tlx_cdata_bdi                    // -- Command Data Bad Data Indicator
  , output        [511:0] afu_tlx_cdata_bus                    // -- Command Data Bus 
                                                             
  , input                 tlx_afu_cmd_credit                   // -- TLX returns cmd credit to AFU when cmd taken from FIFO by DLX
  , input                 tlx_afu_cmd_data_credit              // -- TLX returns cmd data credit to AFU when cmd data taken from FIFO by DLX
                                                             
//GFP  , input           [4:3] tlx_afu_cmd_resp_initial_credit_x    // -- EAC informs AFU of additional cmd/resp credits available
  , input           [4:4] tlx_afu_cmd_initial_credit_x         // -- EAC informs AFU of additional cmd credits available
//GFP  , input           [2:0] tlx_afu_cmd_resp_initial_credit      // -- TLX informs AFU cmd/resp credits available - same for cmd and resp
  , input           [3:0] tlx_afu_cmd_initial_credit           // -- TLX informs AFU cmd credits available
  , input           [3:0] tlx_afu_resp_initial_credit          // -- TLX informs AFU resp credits available
//GFP  , input           [6:5] tlx_afu_data_initial_credit_x        // -- EAC informs AFU of additional data credits available
  , input           [6:6] tlx_afu_cmd_data_initial_credit_x    // -- EAC informs AFU of additional data credits available
//GFP  , input           [4:0] tlx_afu_data_initial_credit          // -- TLX informs AFU data credits available
  , input           [5:0] tlx_afu_cmd_data_initial_credit      // -- TLX informs AFU data credits available
  , input           [5:0] tlx_afu_resp_data_initial_credit     // -- TLX informs AFU data credits available
                                                                                                                          
  // -- TLX_AFU response receive interface                   
  , input                 tlx_afu_resp_valid                   // -- Response Valid (Receive)
  , input           [7:0] tlx_afu_resp_opcode                  // -- Response Opcode
  , input          [15:0] tlx_afu_resp_afutag                  // -- Response Tag
  , input           [3:0] tlx_afu_resp_code                    // -- Response Code - reason for failed transaction
  , input           [1:0] tlx_afu_resp_dl                      // -- Response Data Length
  , input           [1:0] tlx_afu_resp_dp                      // -- Response Data Part - indicates the data content of the current response packet
  , input           [5:0] tlx_afu_resp_pg_size                 // -- Not used in this implementation
  , input          [17:0] tlx_afu_resp_addr_tag                // -- Not used in this implementation
//, input          [23:0] tlx_afu_resp_host_tag                // -- Reserved for CAPI 4.0
//, input           [3:0] tlx_afu_resp_cache_state             // -- Reserved for CAPI 4.0
                                                             
  , output                afu_tlx_resp_rd_req                  // -- Response Read Request
  , output          [2:0] afu_tlx_resp_rd_cnt                  // -- Response Read Count
                                                             
  , input                 tlx_afu_resp_data_valid              // -- Response Data Valid. Indicates valid data available
  , input                 tlx_afu_resp_data_bdi                // -- Response Data Bad Data Indicator
  , input         [511:0] tlx_afu_resp_data_bus                // -- Response Data Bus
                                                                           
  , output                afu_tlx_resp_credit                  // -- AFU returns resp credit to TLX
  , output          [6:0] afu_tlx_resp_initial_credit          // -- AFU indicates number of response credits available (static value)

  , output                afu_tlx_fatal_error                  // -- A fatal error occurred on this AFU, or software injected an error

  // -- BDF Interface
  , input           [7:0] cfg_afu_bdf_bus 
  , input           [4:0] cfg_afu_bdf_device 
  , input           [2:0] cfg_afu_bdf_function


  // -- Configuration Space Outputs used by AFU
 
  // -- MMIO
  , input                 cfg_csh_memory_space
  , input          [63:0] cfg_csh_mmio_bar0 

  // -- 'assign_actag' generation controls
  , input          [11:0] cfg_octrl00_afu_actag_base        // -- This is the base acTag      this AFU can use (linear value)
  , input          [11:0] cfg_octrl00_afu_actag_len_enab    // -- This is the range of acTags this AFU can use (linear value)

  // -- Process termination controls
  , output                cfg_octrl00_terminate_in_progress // -- Unused by LPC since it doesn't make sense to terminate the general interrupt process
  , input                 cfg_octrl00_terminate_valid       // -- Unused by LPC since it doesn't make sense to terminate the general interrupt process
  , input          [19:0] cfg_octrl00_terminate_pasid       // -- Unused by LPC since it doesn't make sense to terminate the general interrupt process 

  // -- PASID controls
  , input           [4:0] cfg_octrl00_pasid_length_enabled  // -- Should be >=0 for LPC to allow it to have at least 1 PASID for interrupts 
  , input          [19:0] cfg_octrl00_pasid_base            // -- Starting value of PASIDs, must be within 'Max PASID Width'
                                                            // -- Notes: 
                                                            // -- - 'PASID base' is for this AFU, used to keep PASID range within each AFU unique.
                                                            // -- - 'PASID Length Enabled' + 'PASID base' must be within range of 'Max PASID Width'
                                                            // -- More Notes:
                                                            // -- - 'Max PASID Width' and 'PASID Length Supported' are Read Only inputs to cfg_func.
                                                            // -- - 'Max PASID Width' is range of PASIDs across all AFUs controlled by this BDF.
                                                            // -- - 'PASID Length Supported' can be <, =, or > 'Max PASID Width' 
                                                            // --   The case of 'PASID Length Supported' > 'Max PASID Width' may seem odd. However it 
                                                            // --   is legal since an AFU may support more PASIDs than it advertizes, for instance
                                                            // --   in the case where a more general purpose AFU is reused in an application that
                                                            // --   has a restricted use.
                                                      
  // -- Interrupt generation controls                  
  , input           [3:0] cfg_f0_otl0_long_backoff_timer    // -- TLX Configuration for the TLX port(s) connected to AFUs under this Function
  , input           [3:0] cfg_f0_otl0_short_backoff_timer
  , input                 cfg_octrl00_enable_afu            // -- When 1, the AFU can initiate commands to the host

   // -- Metadata
//, input                cfg_octrl00_metadata_enabled       // -- Not Used
//, input          [6:0] cfg_octr00l_default_metadata       // -- Not Used

  // -- AFU Descriptor Table interface to AFU Configuration Space
  , input           [5:0] cfg_desc_afu_index
  , input          [30:0] cfg_desc_offset
  , input                 cfg_desc_cmd_valid
  , output         [31:0] desc_cfg_data
  , output                desc_cfg_data_valid
  , output                desc_cfg_echo_cmd_valid

  // -- Errors to record from Configuration Sub-system, Descriptor Table, and VPD
  , input                 vpd_err_unimplemented_addr
  , input                 cfg0_cff_fifo_overflow
//, input                 cfg1_cff_fifo_overflow
  , input                 cfg0_rff_fifo_overflow
//, input                 cfg1_rff_fifo_overflow
  , input         [127:0] cfg_errvec
  , input                 cfg_errvec_valid

  );


  // --****************************************************************************
  // -- Signal declarations
  // --****************************************************************************

  // -- resets
  wire            reset_desc;
  wire            reset_mmio;
  wire            reset_weq;
  wire            reset_eng;
  wire            reset_arb;
  wire            reset_cmdo;
  wire            reset_rspi;
  wire            reset_cmdi_rspo;
  wire            reset_trace;

  // -- weq-eng interface signals
//     wire     [31:0] eng_weq_available;
//     wire            weq_eng_any_enable;
//     wire     [31:0] weq_eng_enable;
//     wire            weq_eng_pe_terminate;
//     wire     [19:0] weq_eng_pasid;
//     wire     [63:0] weq_eng_wed;
//wire      [1:0] weq_eng_intrpt_type;  // -- Change made to share weq_eng_wed bus (3 xfers) 
//wire     [63:0] weq_eng_intrpt_obj;   // -- Change made to share weq_eng_wed bus (3 xfers) 
//wire     [31:0] weq_eng_intrpt_data;  // -- Change made to share weq_eng_wed bus (3 xfers) 
//     wire     [18:5] weq_eng_offset;
//     wire            weq_eng_we_wrap;
//     wire     [31:0] eng_weq_pe_ack;

//     wire     [31:0] eng_weq_we_req;
//     wire     [31:0] weq_eng_we_gnt;
//     wire     [19:0] eng_weq_we_pasid;
//     wire     [18:5] eng_weq_we_offset;
//     wire            eng_weq_we_wrap;
//     wire     [11:0] eng_weq_we_pe_stat;

//     wire     [31:0] eng_weq_done;

 // -- eng-arb interface signals
//     wire            eng_arb_ld_req;
  wire            arb_eng_ld_gnt;
//     wire            eng_arb_st_req;
//     wire            eng_arb_st_256;
//     wire            eng_arb_st_128;
  wire            arb_eng_st_gnt;
  wire            eng_arb_misc_req;
  wire            eng_arb_misc_w_data;
  wire            eng_arb_misc_needs_extra_write;
  wire            arb_eng_misc_gnt;
  wire            eng_arb_rtry_ld_req;
  wire            arb_eng_rtry_ld_gnt;
  wire            eng_arb_rtry_st_req;
  wire            eng_arb_rtry_st_256;
  wire            eng_arb_rtry_st_128;
  wire            arb_eng_rtry_st_gnt;
  wire            eng_arb_rtry_misc_req;
  wire            eng_arb_rtry_misc_w_data;
  wire            arb_eng_rtry_misc_gnt;

  wire            eng_arb_init;
  wire            eng_arb_ld_enable;
  wire            eng_arb_st_enable;
  wire      [8:0] arb_eng_ld_tag;
  wire      [8:0] arb_eng_st_tag;
  wire    [511:0] eng_arb_set_ld_tag_avail;
  wire    [511:0] eng_arb_set_st_tag_avail;
  wire            eng_arb_ld_fastpath_valid;
  wire            eng_arb_st_fastpath_valid;
  wire      [8:0] eng_arb_ld_fastpath_tag;
  wire      [8:0] eng_arb_st_fastpath_tag;

  // -- eng-cmdo interface signals
  wire            eng_cmdo_valid;
  wire      [7:0] eng_cmdo_opcode;
  wire     [11:0] eng_cmdo_actag;
  wire      [3:0] eng_cmdo_stream_id;
  wire     [67:0] eng_cmdo_ea_or_obj;
  wire     [15:0] eng_cmdo_afutag;
  wire      [1:0] eng_cmdo_dl;
  wire      [2:0] eng_cmdo_pl;
  wire            eng_cmdo_os;
  wire     [63:0] eng_cmdo_be;
  wire      [3:0] eng_cmdo_flag;
  wire            eng_cmdo_endian;
  wire     [15:0] eng_cmdo_bdf;
  wire     [19:0] eng_cmdo_pasid;
  wire      [5:0] eng_cmdo_pg_size;
  wire            eng_cmdo_st_valid;
  wire   [1023:0] eng_cmdo_st_data;

  // -- cmdo-rspi interface signals
  wire            cmdo_rspi_cmd_valid;
  wire      [7:0] cmdo_rspi_cmd_opcode;
  wire      [1:0] cmdo_rspi_cmd_dl;

  // -- rspi-eng interface signals
  wire            rspi_eng_resp_valid;
  wire     [15:0] rspi_eng_resp_afutag;
  wire      [7:0] rspi_eng_resp_opcode;
  wire      [3:0] rspi_eng_resp_code;
  wire      [1:0] rspi_eng_resp_dl;
  wire      [1:0] rspi_eng_resp_dp;
  wire            rspi_eng_resp_data_valid;
  wire      [1:0] rspi_eng_resp_data_bdi;
  wire   [1023:0] rspi_eng_resp_data_bus;

  // -- mmio-cmdo
  wire     [19:0] mmio_cmdo_pasid_mask;

  // -- cmdi-mmio
  wire            cmdi_mmio_rd;
  wire            cmdi_mmio_wr;
  wire            cmdi_mmio_large_rd;
  wire            cmdi_mmio_large_wr;
  wire      [1:0] cmdi_mmio_large_wr_half_en;
  wire     [25:0] cmdi_mmio_addr;
  wire   [1023:0] cmdi_mmio_wrdata;

  wire            cmdi_mmio_early_wr;
  wire            cmdi_mmio_early_large_wr;
  wire      [1:0] cmdi_mmio_early_large_wr_half_en;
  wire     [25:0] cmdi_mmio_early_addr;

  // -- mmio-rspo
  wire            mmio_rspo_wr_done;
  wire            mmio_rspo_rddata_valid;
  wire   [1023:0] mmio_rspo_rddata;
  wire            mmio_rspo_bad_op_or_align;
  wire            mmio_rspo_addr_not_implemented;

  // -- mmio-weq
  wire            mmio_weq_wr_wed;
  wire            mmio_weq_rd_wed;
  wire            mmio_weq_rd_process_status;
  wire     [19:0] mmio_weq_pasid;
  wire            mmio_weq_wr_intrpt_obj;
  wire            mmio_weq_rd_intrpt_obj;
  wire     [63:0] mmio_weq_wrdata;

  wire            weq_mmio_wr_wed_done;
  wire            weq_mmio_rd_wed_valid;
  wire            weq_mmio_rd_process_status_valid;
  wire            weq_mmio_wr_intrpt_ctl_done;
  wire            weq_mmio_rd_intrpt_ctl_valid;
  wire            weq_mmio_wr_intrpt_obj_done;
  wire            weq_mmio_rd_intrpt_obj_valid;
  wire            weq_mmio_wr_intrpt_data_done;
  wire            weq_mmio_rd_intrpt_data_valid;
  wire     [63:0] weq_mmio_rddata;

  wire            mmio_weq_restart_process;
  wire            weq_mmio_restart_process_done;
  wire            weq_mmio_restart_process_error;

//     wire            mmio_weq_terminate_process;
//     wire     [19:0] mmio_weq_terminate_pasid;
  wire            weq_mmio_terminate_process_done;

  wire            mmio_weq_memcpy2_format_enable;
  wire      [4:0] mmio_weq_term_reset_extend_en;
  wire            mmio_weq_eng_wr_blk_mmio_rd_pe_ary_disable;

  wire            mmio_perf_reset;
  wire            mmio_perf_snapshot;
  wire            mmio_perf_rdval;
  wire            mmio_perf_rdlatency;
  wire      [3:0] mmio_perf_rdaddr;
  wire            perf_mmio_rddata_valid;
  wire     [63:0] perf_mmio_rddata;

  // -- control and config signals
  wire            mmio_eng_intrpt_on_cpy_err_en;
  wire            mmio_eng_stop_on_invalid_cmd;
  wire            mmio_eng_256B_op_disable;
  wire            mmio_eng_128B_op_disable;
  wire            mmio_eng_immed_terminate_enable;
  wire            mmio_eng_xtouch_source_enable;
  wire            mmio_eng_xtouch_dest_enable;
//     wire            mmio_eng_xtouch_wt4rsp_enable;
  wire      [5:0] mmio_eng_xtouch_ageout_pg_size;
  wire            mmio_eng_use_pasid_for_actag;
  wire            mmio_eng_hold_pasid_for_debug;
  wire            mmio_eng_rtry_backoff_timer_disable;
  wire            mmio_eng_memcpy2_format_enable;

  wire            mmio_eng_capture_all_resp_code_enable;


  wire      [1:0] mmio_eng_we_ld_type;
  wire      [3:0] mmio_eng_we_st_type;
  wire      [1:0] mmio_eng_cpy_ld_type;
  wire      [1:0] mmio_eng_cpy_st_type;
//     wire      [1:0] mmio_eng_xtouch_type;
//     wire      [4:0] mmio_eng_xtouch_flag;
  wire      [1:0] mmio_eng_incr_ld_type;
  wire      [1:0] mmio_eng_incr_st_type;
  wire      [1:0] mmio_eng_atomic_ld_type;
  wire      [1:0] mmio_eng_atomic_cas_type;
  wire      [1:0] mmio_eng_atomic_st_type;

  wire    [63:12] mmio_eng_base_addr;
  wire      [2:0] mmio_arb_num_ld_tags;
  wire      [1:0] mmio_eng_ld_size;
  wire            mmio_eng_type_ld;
  wire      [2:0] mmio_arb_num_st_tags;
  wire      [1:0] mmio_eng_st_size;
  wire            mmio_eng_type_st;
  wire    [31:12] mmio_eng_offset_mask;
  wire      [9:0] mmio_eng_pasid;
  wire            mmio_eng_send_interrupt;
  wire            mmio_eng_send_wkhstthrd;
  wire            mmio_eng_error_intrpt_enable;
  wire            mmio_eng_wkhstthrd_intrpt_enable;
  wire     [15:0] mmio_eng_wkhstthrd_tid;
  wire            mmio_eng_wkhstthrd_flag;
  wire            mmio_eng_extra_write_mode;
  wire     [63:0] mmio_eng_obj_handle;
  wire      [1:0] mmio_eng_xtouch_pg_n;
  wire      [5:0] mmio_eng_xtouch_pg_size;
  wire            mmio_eng_xtouch_type;
  wire            mmio_eng_xtouch_hwt;
  wire            mmio_eng_xtouch_wt4rsp_enable;
  wire            mmio_eng_xtouch_enable;
  wire            mmio_eng_enable;
  wire            mmio_eng_resend_retries;
  wire            mmio_eng_mmio_lat_mode;
  wire            mmio_eng_mmio_lat_mode_sz_512_st;
  wire            mmio_eng_mmio_lat_mode_sz_512_ld;
  wire            mmio_eng_mmio_lat_use_reg_data;
  wire            mmio_eng_mmio_lat_extra_read;
  wire     [63:7] mmio_eng_mmio_lat_ld_ea;
  wire   [1023:0] mmio_eng_mmio_lat_data0;
  wire   [1023:0] mmio_eng_mmio_lat_data1;
  wire   [1023:0] mmio_eng_mmio_lat_data2;
  wire   [1023:0] mmio_eng_mmio_lat_data3;
  wire      [3:0] eng_mmio_extra_read_resp;
  wire   [1023:0] eng_mmio_data;

  wire      [1:0] mmio_arb_ld_size;
  wire            mmio_arb_type_ld;
  wire      [1:0] mmio_arb_st_size;
  wire            mmio_arb_type_st;
  wire            mmio_arb_xtouch_wt4rsp_enable;
  wire            mmio_arb_xtouch_enable;
  wire            mmio_arb_mmio_lat_mode;
  wire            mmio_arb_mmio_lat_mode_sz_512_st;
  wire            mmio_arb_mmio_lat_mode_sz_512_ld;
  wire            mmio_arb_mmio_lat_extra_read;
  wire            mmio_arb_mmio_access;
  wire            mmio_arb_fastpath_disable;

  wire            mmio_cmdo_split_128B_cmds;                                                  

  wire            mmio_rspi_fastpath_queue_bypass_disable;
  wire            mmio_rspi_fastpath_stg0_bypass_disable;
  wire            mmio_rspi_fastpath_stg1_bypass_disable;
  wire            mmio_rspi_fastpath_stg2_bypass_disable;
  wire            mmio_rspi_normal_stg1_bypass_disable;
  wire            mmio_rspi_normal_stg2_bypass_disable;

  wire            mmio_rspi_fastpath_blocker_disable;      

  wire      [7:0] rspi_mmio_resp_queue_maxqdepth;
  wire            mmio_rspi_resp_queue_maxqdepth_reset;

  wire     [11:0] rspi_mmio_max_outstanding_responses;
  wire            mmio_rspi_max_outstanding_responses_reset;

  wire      [1:0] mmio_arb_ldst_priority_mode;

  wire            mmio_weq_eng_disable_updated;
  wire     [31:0] mmio_weq_eng_disable;
  wire            mmio_weq_use_pasid_for_actag;
 
  // -- Display Read Interface - trace
  wire            mmio_trace_display_rdval;
  wire      [8:0] mmio_trace_display_addr;
  wire      [3:0] mmio_trace_display_offset;

  wire            trace_mmio_display_rddata_valid;
  wire     [63:0] trace_mmio_display_rddata;

  // -- Display Read Interface - Response Queue
  wire            mmio_rspi_display_rdval;
  wire      [6:0] mmio_rspi_display_addr;
  
  wire            rspi_mmio_display_rddata_valid;
  wire     [63:0] rspi_mmio_display_rddata;

  // -- Display Read Interface - WEQ / Copy Engines
  wire            mmio_eng_display_rdval;
  wire            mmio_weq_display_mod_select;
  wire      [1:0] mmio_eng_display_ary_select;
//     wire      [4:0] mmio_weq_display_eng_select;
  wire      [9:0] mmio_eng_display_addr;
  wire      [3:0] mmio_weq_display_offset;
  wire      [3:0] mmio_cmdo_display_offset;

  wire            weq_mmio_display_rddata_valid;
  wire     [63:0] weq_mmio_display_rddata;

//     wire            weq_eng_display_rdval;
  wire            eng_mmio_display_rddata_valid;
  wire     [63:0] cmdo_mmio_display_rddata;

  // -- cmdo-arb interface
  wire            cmdo_arb_cmd_credit_ge_1;
  wire            cmdo_arb_cmd_credit_ge_2;
  wire            cmdo_arb_data_credit_ge_4;
  wire            cmdo_arb_data_credit_ge_2;
  wire            cmdo_arb_data_credit_ge_1;

  wire            arb_cmdo_decr_cmd_credit;
  wire            arb_cmdo_decr_data_credit_4;
  wire            arb_cmdo_decr_data_credit_2;
  wire            arb_cmdo_decr_data_credit_1;

  // -- Interface to AFU Descriptor table (interface is Read Only)
  wire [24*8-1:0] ro_name_space;                   
  wire      [7:0] ro_afu_version_major;         
  wire      [7:0] ro_afu_version_minor;
  wire      [2:0] ro_afuc_type;         
  wire      [2:0] ro_afum_type;         
  wire      [7:0] ro_profile;         
  wire    [63:16] ro_global_mmio_offset;        
  wire      [2:0] ro_global_mmio_bar;           
  wire     [31:0] ro_global_mmio_size;          
  wire            ro_cmd_flag_x1_supported;
  wire            ro_cmd_flag_x3_supported;
  wire            ro_atc_2M_page_supported;
  wire            ro_atc_64K_page_supported;
  wire      [4:0] ro_max_host_tag_size;
  wire    [63:16] ro_per_pasid_mmio_offset;     
  wire      [2:0] ro_per_pasid_mmio_bar;        
  wire    [31:16] ro_per_pasid_mmio_stride;     
  wire      [7:0] ro_mem_size;
  wire     [63:0] ro_mem_start_addr;                   
  wire    [127:0] ro_naa_wwid;                  

  wire            unexpected_xlate_or_intrpt_done_200;

  // -- Trace array current write address pointers
  wire            trace_rspi_wraddr_reset;
  wire     [10:0] trace_rspi_wraddr;
  wire            trace_cmdo_wraddr_reset;
  wire     [10:0] trace_cmdo_wraddr;
  wire            trace_cmdi_rspo_wraddr_reset;
  wire     [10:0] trace_cmdi_rspo_wraddr;

  // -- Trace array trigger enables for rspi interface
  wire            trace_tlx_afu_resp_data_valid_en;
  wire            trace_afu_tlx_resp_rd_req_en;
  wire            trace_afu_tlx_resp_credit_en;             
  wire            trace_tlx_afu_resp_valid_retry_en;          
  wire            trace_tlx_afu_resp_valid_no_data_en;
  wire            trace_tlx_afu_resp_valid_with_data_en;

  // -- Trace array trigger enables for cmdo interface
  wire            trace_tlx_afu_cmd_data_credit_en;
  wire            trace_tlx_afu_cmd_credit_en;
  wire            trace_afu_tlx_cdata_valid_en;       
  wire            trace_afu_tlx_cmd_valid_en;          

  // -- Trace array trigger enables for cmdi_rspo interface
  wire            trace_tlx_afu_resp_data_credit_en;
  wire            trace_tlx_afu_resp_credit_en;
  wire            trace_afu_tlx_rdata_valid_en;
  wire            trace_afu_tlx_resp_valid_en;

  wire            trace_afu_tlx_cmd_credit_en;
  wire            trace_afu_tlx_cmd_rd_req_en;
  wire            trace_tlx_afu_cmd_data_valid_en;
  wire            trace_tlx_afu_cmd_valid_en;

  // -- Trace array controls
  wire            trace_no_wrap;
  wire            trace_eng_en;
  wire      [4:0] trace_eng_num;
  wire            trace_events;
  wire            trace_arm;

  // -- TLX_AFU Command Receive Bus Trace signals   (MMIO requests)
//wire            trace_tlx_afu_ready;          

  wire            trace_tlx_afu_cmd_valid;      
  wire      [7:0] trace_tlx_afu_cmd_opcode;     
  wire     [15:0] trace_tlx_afu_cmd_capptag;    
//wire      [1:0] trace_tlx_afu_cmd_dl;         
  wire      [2:0] trace_tlx_afu_cmd_pl;         
//wire     [63:0] trace_tlx_afu_cmd_be;         
//wire            trace_tlx_afu_cmd_end;        
//wire            trace_tlx_afu_cmd_t;          
  wire     [25:0] trace_tlx_afu_cmd_pa;         
//wire      [3:0] trace_tlx_afu_cmd_flag;       
//wire            trace_tlx_afu_cmd_os;         

  wire            trace_tlx_afu_cmd_data_valid; 
  wire            trace_tlx_afu_cmd_data_bdi;   
  wire     [63:0] trace_tlx_afu_cmd_data_bus;   

  wire            trace_afu_tlx_cmd_rd_req;     
//wire      [2:0] trace_afu_tlx_cmd_rd_cnt;     

  wire            trace_afu_tlx_cmd_credit;     

  wire            trace_tlx_afu_mmio_rd_cmd_valid;
  wire            trace_tlx_afu_mmio_wr_cmd_valid;


  // -- AFU_TLX Response Transmit Bus Trace signals   (MMIO responses)
  wire            trace_afu_tlx_resp_valid;     
  wire      [3:0] trace_afu_tlx_resp_opcode;    
  wire      [1:0] trace_afu_tlx_resp_dl;        
  wire     [15:0] trace_afu_tlx_resp_capptag;   
//wire      [1:0] trace_afu_tlx_resp_dp;        
  wire      [3:0] trace_afu_tlx_resp_code;      

  wire            trace_afu_tlx_rdata_valid;    
//wire            trace_afu_tlx_rdata_bdi;      
//wire     [63:0] trace_afu_tlx_rdata_bus;      

  wire            trace_tlx_afu_resp_credit;    
  wire            trace_tlx_afu_resp_data_credit;

//GFP  wire      [2:0] trace_rspo_avail_resp_credit; 
  wire      [3:0] trace_rspo_avail_resp_credit; 
//GFP  wire      [4:0] trace_rspo_avail_data_credit; 
  wire      [5:0] trace_rspo_avail_data_credit; 

  // -- AFU_TLX Command Transmit Bus Trace signals
  wire            trace_afu_tlx_cmd_valid;      
  wire      [7:0] trace_afu_tlx_cmd_opcode;     
  wire      [5:0] trace_afu_tlx_cmd_actag;      
//wire      [3:0] trace_afu_tlx_cmd_stream_id;  
  wire     [67:0] trace_afu_tlx_cmd_ea_or_obj;  
  wire     [15:0] trace_afu_tlx_cmd_afutag;     
  wire      [1:0] trace_afu_tlx_cmd_dl;         
  wire      [2:0] trace_afu_tlx_cmd_pl;         
//wire            trace_afu_tlx_cmd_os;         
//wire     [63:0] trace_afu_tlx_cmd_be;         
  wire      [3:0] trace_afu_tlx_cmd_flag;       
//wire            trace_afu_tlx_cmd_endian;     
//wire     [15:0] trace_afu_tlx_cmd_bdf;        
  wire      [9:0] trace_afu_tlx_cmd_pasid;      
  wire      [5:0] trace_afu_tlx_cmd_pg_size;    

  wire            trace_afu_tlx_cdata_valid;    
//wire            trace_afu_tlx_cdata_bdi;      
//wire   [1023:0] trace_afu_tlx_cdata_bus;      

  wire      [1:0] trace_tlx_afu_cmd_credit;     
  wire      [1:0] trace_tlx_afu_cmd_data_credit;

  wire      [4:0] trace_cmdo_avail_cmd_credit;  
  wire      [6:0] trace_cmdo_avail_cmd_data_credit; 

  // -- TLX_AFU Response Receive Bus Trace signals
  wire            trace_tlx_afu_resp_valid_with_data;
  wire            trace_tlx_afu_resp_valid_no_data;
  wire            trace_tlx_afu_resp_valid_retry;
  wire     [15:0] trace_tlx_afu_resp_afutag;    
  wire      [7:0] trace_tlx_afu_resp_opcode;    
  wire      [3:0] trace_tlx_afu_resp_code;      
  wire      [1:0] trace_tlx_afu_resp_dl;        
  wire      [1:0] trace_tlx_afu_resp_dp;        
//wire      [5:0] trace_tlx_afu_resp_pg_size;   
//wire     [17:0] trace_tlx_afu_resp_addr_tag;  

  wire            trace_afu_tlx_resp_rd_req;    
  wire      [2:0] trace_afu_tlx_resp_rd_cnt;    

  wire            trace_tlx_afu_resp_data_valid;
  wire      [1:0] trace_tlx_afu_resp_data_bdi;  
//wire    [511:0] trace_tlx_afu_resp_data_bus;  

  wire            trace_afu_tlx_resp_credit;    

  wire            arb_perf_latency_update;
  wire            arb_perf_no_credits;

  wire            eng_perf_wkhstthrd_good;

  // -- Simulation Idle signals
  wire            sim_idle_top;
  wire            sim_idle_cmdi_rspo;
  wire            sim_idle_mmio;
  wire            sim_idle_weq;
  wire            sim_idle_arb;
  wire            sim_idle_cmdo;
  wire            sim_idle_rspi;
  wire            sim_idle_eng;

  wire            reset_d;  
  reg             reset_q;  


  // -- ********************************************************************************************************************************
  // -- Sim Idle
  // -- ********************************************************************************************************************************

  assign  sim_idle_top  = ( sim_idle_cmdi_rspo   ==  1'b1 ) &&
                          ( sim_idle_mmio        ==  1'b1 ) &&
                          ( sim_idle_weq         ==  1'b1 ) &&
                          ( sim_idle_arb         ==  1'b1 ) &&
                          ( sim_idle_cmdo        ==  1'b1 ) &&
                          ( sim_idle_rspi        ==  1'b1 ) &&
                          ( sim_idle_eng         ==  1'b1 );
                                              

  // -- ********************************************************************************************************************************
  // -- Reset
  // -- ********************************************************************************************************************************

  // -- ToDo: This will likely need repowering
  assign  reset_d         =  reset;

  assign  reset_desc      =  reset_q;
  assign  reset_mmio      =  reset_q;
  assign  reset_weq       =  reset_q;
  assign  reset_eng       =  reset_q;   
  assign  reset_arb       =  reset_q;       
  assign  reset_cmdo      =  reset_q;     
  assign  reset_rspi      =  reset_q;      
  assign  reset_cmdi_rspo =  reset_q;
  assign  reset_trace     =  reset_q;


  // -- ********************************************************************************************************************************
  // -- AFU DESCRIPTOR TIES
  // -- ********************************************************************************************************************************

  assign  ro_name_space[191:0]            =  { "IBM,AFP3", { 16{8'h00} } };       // -- Keep this string EXACTLY 24 characters long   // AFP3.0
  assign  ro_afu_version_major[7:0]       =    8'h02;
  assign  ro_afu_version_minor[7:0]       =    8'h05;
  assign  ro_afuc_type[2:0]               =    3'b001;                            // -- Type C1 issues commands to the host (i.e. interrupts) but does not cache host data
  assign  ro_afum_type[2:0]               =    3'b001;                            // -- Type M1 contains host mapped address space, which could be MMIO or memory
  assign  ro_profile[7:0]                 =    8'h01;                             // -- Device Interface Class (see AFU documentation for additional command restrictions)
  assign  ro_global_mmio_offset[63:16]    =   48'h0000_0000_0000;                 // -- MMIO space starts at BAR 0 address  
  assign  ro_global_mmio_bar[2:0]         =    3'b0;
  assign  ro_global_mmio_size[31:0]       =   32'h0200_0000;                      // -- 32MB (1st 32MB of 64MB is for global AFU regs)
  assign  ro_cmd_flag_x1_supported        =    1'b0;                              // -- cmd_flag x1 is not supported
  assign  ro_cmd_flag_x3_supported        =    1'b0;                              // -- cmd_flag x3 is not supported
  assign  ro_atc_2M_page_supported        =    1'b0;                              // -- Address Translation Cache page size of 2MB is not supported
  assign  ro_atc_64K_page_supported       =    1'b0;                              // -- Address Translation Cache page size of 64KB is not supported
  assign  ro_max_host_tag_size[4:0]       =    5'b00000;                          // -- Caching is not supported
  assign  ro_per_pasid_mmio_offset[63:16] =   48'h0000_0000_0200;                 // -- Per Process PASID space starts at BAR 0 + 32MB address
  assign  ro_per_pasid_mmio_bar[2:0]      =    3'b0;
  assign  ro_per_pasid_mmio_stride[31:16] =   16'h0001;                           // -- Stride is 64KB per PASID entry
  assign  ro_mem_size[7:0]                =    8'h00;                             // -- 64MB MMIO size (64MB = 2^26, 26 decimal = x1A). Set to 0 when no LPC memory space in AFU
  assign  ro_mem_start_addr[63:0]         =   64'h0000_0000_0000_0000;            // -- At Device level, Memory Space must start at addr 0
  assign  ro_naa_wwid[127:0]              =  128'b0;


  // -- ********************************************************************************************************************************
  // -- CFG DESCRIPTOR
  // -- ********************************************************************************************************************************

  cfg_descriptor  desc
    (
      // -- Miscellaneous Ports
      .clock                                       ( clock_tlx ),                           // -- input
      .reset                                       ( reset_desc ),                          // -- input

      .ro_name_space                               ( ro_name_space[24*8-1:0] ),             // -- input
      .ro_afu_version_major                        ( ro_afu_version_major[7:0] ),           // -- input
      .ro_afu_version_minor                        ( ro_afu_version_minor[7:0] ),           // -- input
      .ro_afuc_type                                ( ro_afuc_type[2:0] ),                   // -- input
      .ro_afum_type                                ( ro_afum_type[2:0] ),                   // -- input
      .ro_profile                                  ( ro_profile[7:0] ),                     // -- input
      .ro_global_mmio_offset                       ( ro_global_mmio_offset[63:16] ),        // -- input
      .ro_global_mmio_bar                          ( ro_global_mmio_bar[2:0] ),             // -- input
      .ro_global_mmio_size                         ( ro_global_mmio_size[31:0] ),           // -- input
      .ro_cmd_flag_x1_supported                    ( ro_cmd_flag_x1_supported ),            // -- input
      .ro_cmd_flag_x3_supported                    ( ro_cmd_flag_x3_supported ),            // -- input
      .ro_atc_2M_page_supported                    ( ro_atc_2M_page_supported ),            // -- input
      .ro_atc_64K_page_supported                   ( ro_atc_64K_page_supported ),           // -- input
      .ro_max_host_tag_size                        ( ro_max_host_tag_size[4:0] ),           // -- input
      .ro_per_pasid_mmio_offset                    ( ro_per_pasid_mmio_offset[63:16] ),     // -- input
      .ro_per_pasid_mmio_bar                       ( ro_per_pasid_mmio_bar[2:0] ),          // -- input
      .ro_per_pasid_mmio_stride                    ( ro_per_pasid_mmio_stride[31:16] ),     // -- input
      .ro_mem_size                                 ( ro_mem_size[7:0] ),                    // -- input
      .ro_mem_start_addr                           ( ro_mem_start_addr[63:0] ),             // -- input
      .ro_naa_wwid                                 ( ro_naa_wwid[127:0] ),                  // -- input

      .ro_afu_index                                ( afu_index[5:0] ),                      // -- input

      // -- Functional interface
      .cfg_desc_cmd_valid                          ( cfg_desc_cmd_valid ),                  // -- input
      .cfg_desc_afu_index                          ( cfg_desc_afu_index[5:0] ),             // -- input
      .cfg_desc_offset                             ( cfg_desc_offset[30:0] ),               // -- input

      .desc_cfg_data_valid                         ( desc_cfg_data_valid ),                 // -- output
      .desc_cfg_data                               ( desc_cfg_data[31:0] ),                 // -- output
      .desc_cfg_echo_cmd_valid                     ( desc_cfg_echo_cmd_valid ),             // -- output

      // -- Error indicator
      .err_unimplemented_addr                      ( err_unimplemented_addr )               // -- output

    );
            

  // -- ********************************************************************************************************************************
  // -- MMIO 
  // -- ********************************************************************************************************************************

  afp3_mmio  mmio
    (
      .clock_tlx                                   ( clock_tlx ),                                    
      .clock_afu                                   ( clock_afu ),                                    
      .reset                                       ( reset_mmio ),                                   

      .cfg_afu_actag_length_enabled                ( cfg_octrl00_afu_actag_len_enab[11:0] ),

      .cfg_afu_pasid_length_enabled                ( cfg_octrl00_pasid_length_enabled[4:0] ),
      .cfg_afu_pasid_base                          ( cfg_octrl00_pasid_base[19:0] ),                   
      .mmio_cmdo_pasid_mask                        ( mmio_cmdo_pasid_mask[19:0] ),                 
                                                 
      .cmdi_mmio_rd                                ( cmdi_mmio_rd ),                                 
      .cmdi_mmio_wr                                ( cmdi_mmio_wr ),                                 
      .cmdi_mmio_large_rd                          ( cmdi_mmio_large_rd ),                                 
      .cmdi_mmio_large_wr                          ( cmdi_mmio_large_wr ),                                 
      .cmdi_mmio_large_wr_half_en                  ( cmdi_mmio_large_wr_half_en[1:0] ),                                 
      .cmdi_mmio_addr                              ( cmdi_mmio_addr[25:0] ),                         
      .cmdi_mmio_wrdata                            ( cmdi_mmio_wrdata[1023:0] ),                       

      .cmdi_mmio_early_wr                          ( cmdi_mmio_early_wr ),
      .cmdi_mmio_early_large_wr                    ( cmdi_mmio_early_large_wr ),
      .cmdi_mmio_early_large_wr_half_en            ( cmdi_mmio_early_large_wr_half_en[1:0] ),
      .cmdi_mmio_early_addr                        ( cmdi_mmio_early_addr[25:0] ),

      .mmio_rspo_wr_done                           ( mmio_rspo_wr_done ),                            
      .mmio_rspo_rddata_valid                      ( mmio_rspo_rddata_valid ),                       
      .mmio_rspo_rddata                            ( mmio_rspo_rddata[1023:0] ),                       
      .mmio_rspo_bad_op_or_align                   ( mmio_rspo_bad_op_or_align ),                    
      .mmio_rspo_addr_not_implemented              ( mmio_rspo_addr_not_implemented ),               

      .afu_tlx_fatal_error                         ( afu_tlx_fatal_error ),

      .mmio_weq_memcpy2_format_enable              ( mmio_weq_memcpy2_format_enable ),
      .mmio_weq_term_reset_extend_en               ( mmio_weq_term_reset_extend_en ),
      .mmio_weq_eng_wr_blk_mmio_rd_pe_ary_disable  ( mmio_weq_eng_wr_blk_mmio_rd_pe_ary_disable ),
                                                   
      .mmio_weq_rd_wed                             ( mmio_weq_rd_wed ),                              
      .mmio_weq_wr_wed                             ( mmio_weq_wr_wed ),                              
      .mmio_weq_rd_process_status                  ( mmio_weq_rd_process_status ),                   
      .mmio_weq_pasid                              ( mmio_weq_pasid[19:0] ),
      .mmio_weq_rd_intrpt_ctl                      ( mmio_weq_rd_intrpt_ctl ),                              
      .mmio_weq_wr_intrpt_ctl                      ( mmio_weq_wr_intrpt_ctl ),                              
      .mmio_weq_rd_intrpt_obj                      ( mmio_weq_rd_intrpt_obj ),                              
      .mmio_weq_wr_intrpt_obj                      ( mmio_weq_wr_intrpt_obj ),                              
      .mmio_weq_rd_intrpt_data                     ( mmio_weq_rd_intrpt_data ),                              
      .mmio_weq_wr_intrpt_data                     ( mmio_weq_wr_intrpt_data ),                              
      .mmio_weq_wrdata                             ( mmio_weq_wrdata[63:0] ),                        
                                                   
      .weq_mmio_wr_wed_done                        ( weq_mmio_wr_wed_done ),                         
      .weq_mmio_rd_wed_valid                       ( weq_mmio_rd_wed_valid ),                        
      .weq_mmio_rd_process_status_valid            ( weq_mmio_rd_process_status_valid ),             
      .weq_mmio_wr_intrpt_ctl_done                 ( weq_mmio_wr_intrpt_ctl_done ),                         
      .weq_mmio_rd_intrpt_ctl_valid                ( weq_mmio_rd_intrpt_ctl_valid ),                        
      .weq_mmio_wr_intrpt_obj_done                 ( weq_mmio_wr_intrpt_obj_done ),                         
      .weq_mmio_rd_intrpt_obj_valid                ( weq_mmio_rd_intrpt_obj_valid ),                        
      .weq_mmio_wr_intrpt_data_done                ( weq_mmio_wr_intrpt_data_done ),                         
      .weq_mmio_rd_intrpt_data_valid               ( weq_mmio_rd_intrpt_data_valid ),                        
      .weq_mmio_rddata                             ( weq_mmio_rddata[63:0] ),                        
                                                   
      .cfg_afu_terminate_valid                     ( cfg_octrl00_terminate_valid ),                  
      .cfg_afu_terminate_pasid                     ( cfg_octrl00_terminate_pasid[19:0] ),              
      .afu_cfg_terminate_in_progress               ( cfg_octrl00_terminate_in_progress ),
                                                  
      .mmio_weq_restart_process                    ( mmio_weq_restart_process ),                     
      .weq_mmio_restart_process_done               ( weq_mmio_restart_process_done ),                
      .weq_mmio_restart_process_error              ( weq_mmio_restart_process_error ),               

//         .mmio_weq_terminate_process                  ( mmio_weq_terminate_process ),                   
//         .mmio_weq_terminate_pasid                    ( mmio_weq_terminate_pasid[19:0] ),                   
      .weq_mmio_terminate_process_done             ( weq_mmio_terminate_process_done ),              
                                                   
      .mmio_perf_reset                             ( mmio_perf_reset ),
      .mmio_perf_snapshot                          ( mmio_perf_snapshot ),
      .mmio_perf_rdval                             ( mmio_perf_rdval ),
      .mmio_perf_rdlatency                         ( mmio_perf_rdlatency ),
      .mmio_perf_rdaddr                            ( mmio_perf_rdaddr[3:0] ),
      .perf_mmio_rddata_valid                      ( perf_mmio_rddata_valid ),
      .perf_mmio_rddata                            ( perf_mmio_rddata[63:0] ),

      .mmio_eng_intrpt_on_cpy_err_en               ( mmio_eng_intrpt_on_cpy_err_en ),                
      .mmio_eng_stop_on_invalid_cmd                ( mmio_eng_stop_on_invalid_cmd ),                 
      .mmio_eng_256B_op_disable                    ( mmio_eng_256B_op_disable ),                     
      .mmio_eng_128B_op_disable                    ( mmio_eng_128B_op_disable ),                     
      .mmio_eng_hold_pasid_for_debug               ( mmio_eng_hold_pasid_for_debug ),
      .mmio_eng_use_pasid_for_actag                ( mmio_eng_use_pasid_for_actag ),
      .mmio_eng_xtouch_source_enable               ( mmio_eng_xtouch_source_enable ),
      .mmio_eng_xtouch_dest_enable                 ( mmio_eng_xtouch_dest_enable ),
//         .mmio_eng_xtouch_wt4rsp_enable               ( mmio_eng_xtouch_wt4rsp_enable ),
      .mmio_eng_xtouch_ageout_pg_size              ( mmio_eng_xtouch_ageout_pg_size[5:0] ),
      .mmio_eng_immed_terminate_enable             ( mmio_eng_immed_terminate_enable ),
      .mmio_eng_rtry_backoff_timer_disable         ( mmio_eng_rtry_backoff_timer_disable ),
      .mmio_eng_memcpy2_format_enable              ( mmio_eng_memcpy2_format_enable ),

      .mmio_eng_capture_all_resp_code_enable       ( mmio_eng_capture_all_resp_code_enable ),
                                                                                 
      .mmio_eng_we_ld_type                         ( mmio_eng_we_ld_type[1:0] ),
      .mmio_eng_we_st_type                         ( mmio_eng_we_st_type[3:0] ),
      .mmio_eng_cpy_ld_type                        ( mmio_eng_cpy_ld_type[1:0] ),
      .mmio_eng_cpy_st_type                        ( mmio_eng_cpy_st_type[1:0] ),
//         .mmio_eng_xtouch_type                        ( mmio_eng_xtouch_type[1:0] ),
//         .mmio_eng_xtouch_flag                        ( mmio_eng_xtouch_flag[4:0] ),
      .mmio_eng_incr_ld_type                       ( mmio_eng_incr_ld_type[1:0] ),
      .mmio_eng_incr_st_type                       ( mmio_eng_incr_st_type[1:0] ),
      .mmio_eng_atomic_ld_type                     ( mmio_eng_atomic_ld_type[1:0] ),
      .mmio_eng_atomic_cas_type                    ( mmio_eng_atomic_cas_type[1:0] ),
      .mmio_eng_atomic_st_type                     ( mmio_eng_atomic_st_type[1:0] ),

      .mmio_eng_base_addr                          ( mmio_eng_base_addr[63:12] ),
      .mmio_eng_ld_size                            ( mmio_eng_ld_size[1:0] ),
      .mmio_eng_type_ld                            ( mmio_eng_type_ld ),
      .mmio_eng_st_size                            ( mmio_eng_st_size[1:0] ),
      .mmio_eng_type_st                            ( mmio_eng_type_st ),
      .mmio_eng_offset_mask                        ( mmio_eng_offset_mask[31:12] ),
      .mmio_eng_pasid                              ( mmio_eng_pasid[9:0] ),
      .mmio_eng_send_interrupt                     ( mmio_eng_send_interrupt ),
      .mmio_eng_send_wkhstthrd                     ( mmio_eng_send_wkhstthrd ),
      .mmio_eng_error_intrpt_enable                ( mmio_eng_error_intrpt_enable ),
      .mmio_eng_wkhstthrd_intrpt_enable            ( mmio_eng_wkhstthrd_intrpt_enable ),
      .mmio_eng_wkhstthrd_tid                      ( mmio_eng_wkhstthrd_tid[15:0] ),
      .mmio_eng_wkhstthrd_flag                     ( mmio_eng_wkhstthrd_flag ),
      .mmio_eng_extra_write_mode                   ( mmio_eng_extra_write_mode ),
      .mmio_eng_obj_handle                         ( mmio_eng_obj_handle[63:0] ),
      .mmio_eng_xtouch_pg_n                        ( mmio_eng_xtouch_pg_n[1:0] ),
      .mmio_eng_xtouch_pg_size                     ( mmio_eng_xtouch_pg_size[5:0] ),
      .mmio_eng_xtouch_type                        ( mmio_eng_xtouch_type ),
      .mmio_eng_xtouch_hwt                         ( mmio_eng_xtouch_hwt ),
      .mmio_eng_xtouch_wt4rsp_enable               ( mmio_eng_xtouch_wt4rsp_enable ),
      .mmio_eng_xtouch_enable                      ( mmio_eng_xtouch_enable ),
      .mmio_eng_enable                             ( mmio_eng_enable ),
      .mmio_eng_resend_retries                     ( mmio_eng_resend_retries ),
      .mmio_eng_mmio_lat_mode                      ( mmio_eng_mmio_lat_mode ),
      .mmio_eng_mmio_lat_mode_sz_512_st            ( mmio_eng_mmio_lat_mode_sz_512_st ),
      .mmio_eng_mmio_lat_mode_sz_512_ld            ( mmio_eng_mmio_lat_mode_sz_512_ld ),
      .mmio_eng_mmio_lat_use_reg_data              ( mmio_eng_mmio_lat_use_reg_data ),
      .mmio_eng_mmio_lat_extra_read                ( mmio_eng_mmio_lat_extra_read ),
      .mmio_eng_mmio_lat_ld_ea                     ( mmio_eng_mmio_lat_ld_ea[63:7] ),
      .mmio_eng_mmio_lat_data0                     ( mmio_eng_mmio_lat_data0[1023:0] ),
      .mmio_eng_mmio_lat_data1                     ( mmio_eng_mmio_lat_data1[1023:0] ),
      .mmio_eng_mmio_lat_data2                     ( mmio_eng_mmio_lat_data2[1023:0] ),
      .mmio_eng_mmio_lat_data3                     ( mmio_eng_mmio_lat_data3[1023:0] ),
      .eng_mmio_extra_read_resp                    ( eng_mmio_extra_read_resp[3:0] ),
      .eng_mmio_data                               ( eng_mmio_data[1023:0] ),

      .mmio_arb_num_ld_tags                        ( mmio_arb_num_ld_tags[2:0] ),
      .mmio_arb_ld_size                            ( mmio_arb_ld_size[1:0] ),
      .mmio_arb_type_ld                            ( mmio_arb_type_ld ),
      .mmio_arb_num_st_tags                        ( mmio_arb_num_st_tags[2:0] ),
      .mmio_arb_st_size                            ( mmio_arb_st_size[1:0] ),
      .mmio_arb_type_st                            ( mmio_arb_type_st ),

      .mmio_arb_ldst_priority_mode                 ( mmio_arb_ldst_priority_mode[1:0] ),             
      .mmio_arb_xtouch_wt4rsp_enable               ( mmio_arb_xtouch_wt4rsp_enable ),
      .mmio_arb_xtouch_enable                      ( mmio_arb_xtouch_enable ),
      .mmio_arb_mmio_lat_mode                      ( mmio_arb_mmio_lat_mode ),
      .mmio_arb_mmio_lat_mode_sz_512_st            ( mmio_arb_mmio_lat_mode_sz_512_st ),
      .mmio_arb_mmio_lat_mode_sz_512_ld            ( mmio_arb_mmio_lat_mode_sz_512_ld ),
      .mmio_arb_mmio_lat_extra_read                ( mmio_arb_mmio_lat_extra_read ),
      .mmio_arb_mmio_access                        ( mmio_arb_mmio_access ),
      .mmio_arb_fastpath_disable                   ( mmio_arb_fastpath_disable ),

      .mmio_cmdo_split_128B_cmds                   ( mmio_cmdo_split_128B_cmds ),                                             
                                                   
      .mmio_rspi_fastpath_queue_bypass_disable     ( mmio_rspi_fastpath_queue_bypass_disable ),      
      .mmio_rspi_fastpath_stg0_bypass_disable      ( mmio_rspi_fastpath_stg0_bypass_disable ),       
      .mmio_rspi_fastpath_stg1_bypass_disable      ( mmio_rspi_fastpath_stg1_bypass_disable ),       
      .mmio_rspi_fastpath_stg2_bypass_disable      ( mmio_rspi_fastpath_stg2_bypass_disable ),       
      .mmio_rspi_normal_stg1_bypass_disable        ( mmio_rspi_normal_stg1_bypass_disable ),         
      .mmio_rspi_normal_stg2_bypass_disable        ( mmio_rspi_normal_stg2_bypass_disable ),

      .mmio_rspi_fastpath_blocker_disable          ( mmio_rspi_fastpath_blocker_disable ),       

      .rspi_mmio_resp_queue_maxqdepth              ( rspi_mmio_resp_queue_maxqdepth[7:0] ),          
      .mmio_rspi_resp_queue_maxqdepth_reset        ( mmio_rspi_resp_queue_maxqdepth_reset ),         

      .rspi_mmio_max_outstanding_responses         ( rspi_mmio_max_outstanding_responses[11:0] ),          
      .mmio_rspi_max_outstanding_responses_reset   ( mmio_rspi_max_outstanding_responses_reset ),         

      .mmio_weq_eng_disable_updated                ( mmio_weq_eng_disable_updated ),
      .mmio_weq_eng_disable                        ( mmio_weq_eng_disable[31:0] ),                   
      .mmio_weq_use_pasid_for_actag                ( mmio_weq_use_pasid_for_actag ),

    // -- Trace array current write address pointers
      .trace_rspi_wraddr_reset                     ( trace_rspi_wraddr_reset ),              
      .trace_rspi_wraddr                           ( trace_rspi_wraddr[10:0] ),
      .trace_cmdo_wraddr_reset                     ( trace_cmdo_wraddr_reset ),            
      .trace_cmdo_wraddr                           ( trace_cmdo_wraddr[10:0] ),
      .trace_cmdi_rspo_wraddr_reset                ( trace_cmdi_rspo_wraddr_reset ),
      .trace_cmdi_rspo_wraddr                      ( trace_cmdi_rspo_wraddr[10:0] ),

    // -- Trace array trigger enables for rspi interface
      .trace_tlx_afu_resp_data_valid_en            ( trace_tlx_afu_resp_data_valid_en ),     
      .trace_afu_tlx_resp_rd_req_en                ( trace_afu_tlx_resp_rd_req_en ),        
      .trace_afu_tlx_resp_credit_en                ( trace_afu_tlx_resp_credit_en ),         
      .trace_tlx_afu_resp_valid_retry_en           ( trace_tlx_afu_resp_valid_retry_en ),    
      .trace_tlx_afu_resp_valid_no_data_en         ( trace_tlx_afu_resp_valid_no_data_en ),  
      .trace_tlx_afu_resp_valid_with_data_en       ( trace_tlx_afu_resp_valid_with_data_en ),

    // -- Trace array trigger enables for cmdo interface
      .trace_tlx_afu_cmd_data_credit_en            ( trace_tlx_afu_cmd_data_credit_en ),
      .trace_tlx_afu_cmd_credit_en                 ( trace_tlx_afu_cmd_credit_en ),     
      .trace_afu_tlx_cdata_valid_en                ( trace_afu_tlx_cdata_valid_en ),    
      .trace_afu_tlx_cmd_valid_en                  ( trace_afu_tlx_cmd_valid_en ),      

    // -- Trace array trigger enables for cmdi_rspo interface
      .trace_tlx_afu_resp_data_credit_en           ( trace_tlx_afu_resp_data_credit_en ),
      .trace_tlx_afu_resp_credit_en                ( trace_tlx_afu_resp_credit_en ),     
      .trace_afu_tlx_rdata_valid_en                ( trace_afu_tlx_rdata_valid_en ),     
      .trace_afu_tlx_resp_valid_en                 ( trace_afu_tlx_resp_valid_en ),      

      .trace_afu_tlx_cmd_credit_en                 ( trace_afu_tlx_cmd_credit_en ),    
      .trace_afu_tlx_cmd_rd_req_en                 ( trace_afu_tlx_cmd_rd_req_en ),    
      .trace_tlx_afu_cmd_data_valid_en             ( trace_tlx_afu_cmd_data_valid_en ),
      .trace_tlx_afu_cmd_valid_en                  ( trace_tlx_afu_cmd_valid_en ),     

    // -- Trace array controls
      .trace_no_wrap                               ( trace_no_wrap ),
      .trace_eng_en                                ( trace_eng_en ), 
      .trace_eng_num                               ( trace_eng_num[4:0] ), 
      .trace_events                                ( trace_events ), 
      .trace_arm                                   ( trace_arm ),    

    // -- Display Read Interface - trace
      .mmio_trace_display_rdval                    ( mmio_trace_display_rdval ),                
      .mmio_trace_display_addr                     ( mmio_trace_display_addr[8:0] ),
      .mmio_trace_display_offset                   ( mmio_trace_display_offset[3:0] ),
                                                                                    
      .trace_mmio_display_rddata_valid             ( trace_mmio_display_rddata_valid ),          
      .trace_mmio_display_rddata                   ( trace_mmio_display_rddata[63:0] ),

    // -- Display Read Interface - Response Queue
      .mmio_rspi_display_rdval                     ( mmio_rspi_display_rdval ),               
      .mmio_rspi_display_addr                      ( mmio_rspi_display_addr[6:0] ),
                                                                                    
      .rspi_mmio_display_rddata_valid              ( rspi_mmio_display_rddata_valid ),        
      .rspi_mmio_display_rddata                    ( rspi_mmio_display_rddata[63:0] ),

    // -- Display Read Interface - WEQ / Copy Engines
      .mmio_weq_display_rdval                      ( mmio_eng_display_rdval ),        
      .mmio_weq_display_mod_select                 ( mmio_weq_display_mod_select ),         
      .mmio_weq_display_ary_select                 ( mmio_eng_display_ary_select[1:0] ),         
      .mmio_weq_display_eng_select                 ( mmio_eng_display_addr[9:5] ),         
      .mmio_weq_display_addr                       ( mmio_eng_display_addr[4:0] ),
      .mmio_weq_display_offset                     ( mmio_weq_display_offset[3:0] ),
      .mmio_cmdo_display_offset                    ( mmio_cmdo_display_offset[3:0] ),
                                                                                 
      .weq_mmio_display_rddata_valid               ( weq_mmio_display_rddata_valid ),
      .weq_mmio_display_rddata                     ( weq_mmio_display_rddata[63:0] ),

      .eng_mmio_display_rddata_valid               ( eng_mmio_display_rddata_valid ),
      .cmdo_mmio_display_rddata                    ( cmdo_mmio_display_rddata[63:0] ),

    // -- Simulation Idle signals into mmio for capture
      .sim_idle_cmdi_rspo                          ( sim_idle_cmdi_rspo ),   
      .sim_idle_weq                                ( sim_idle_weq ),          
      .sim_idle_arb                                ( sim_idle_arb ),          
      .sim_idle_cmdo                               ( sim_idle_cmdo ),         
      .sim_idle_rspi                               ( sim_idle_rspi ),        
      .sim_idle_eng                                ( sim_idle_eng ),

    // -- Simulation Idle out
      .sim_idle_mmio                               ( sim_idle_mmio )

    );              


  // -- ********************************************************************************************************************************
  // -- Work Element Queue (WEQ)
  // -- ********************************************************************************************************************************
//    Tie off signals previously driven by WEQ
assign  weq_mmio_wr_wed_done  = 1'b0;
assign  weq_mmio_rd_wed_valid = 1'b0;
assign  weq_mmio_rd_process_status_valid = 1'b0;
assign  weq_mmio_wr_intrpt_ctl_done   = 1'b0;
assign  weq_mmio_rd_intrpt_ctl_valid  = 1'b0;
assign  weq_mmio_wr_intrpt_obj_done   = 1'b0;
assign  weq_mmio_rd_intrpt_obj_valid  = 1'b0;
assign  weq_mmio_wr_intrpt_data_done  = 1'b0;
assign  weq_mmio_rd_intrpt_data_valid = 1'b0;
assign  weq_mmio_rddata[63:0]         = 64'b0;

assign  weq_mmio_restart_process_done = 1'b0;
assign  weq_mmio_restart_process_error = 1'b0;

assign  weq_mmio_terminate_process_done = 1'b0;
assign  weq_mmio_display_rddata_valid = 1'b0;
assign  weq_mmio_display_rddata[63:0] = 64'b0;

assign  sim_idle_weq = 1'b1;

/*
  mcp3_weq  weq
    (
      .clock                                       ( clock_afu ),                                    
      .reset                                       ( reset_weq ),                                    

    // -- Mode to support MemCpy2 Backward compatibility
      .mmio_weq_memcpy2_format_enable              ( mmio_weq_memcpy2_format_enable ),

    // -- Mode bits for potential patches with terminates
      .mmio_weq_term_reset_extend_en               ( mmio_weq_term_reset_extend_en ),

    // -- Mode bit for bug with read/write collision to pe_ary
      .mmio_weq_eng_wr_blk_mmio_rd_pe_ary_disable  ( mmio_weq_eng_wr_blk_mmio_rd_pe_ary_disable ),

    // -- static value indicating how many engines implemented
      .eng_weq_available                           ( eng_weq_available[31:0] ),                      

    // -- Mechanism to reduce engine availability via MMIO config reg 
      .mmio_weq_eng_disable_updated                ( mmio_weq_eng_disable_updated ),
      .mmio_weq_eng_disable                        ( mmio_weq_eng_disable[31:0] ),                   
      .mmio_weq_use_pasid_for_actag                ( mmio_weq_use_pasid_for_actag ),

    // -- CNFG interface - # of actags can limit the # of engines
      .cfg_afu_actag_length_enabled                ( cfg_octrl00_afu_actag_len_enab[11:0] ),               

    // -- MMIO interface 
      .mmio_weq_rd_wed                             ( mmio_weq_rd_wed ),                              
      .mmio_weq_wr_wed                             ( mmio_weq_wr_wed ),                              
      .mmio_weq_rd_process_status                  ( mmio_weq_rd_process_status ),                   
      .mmio_weq_pasid                              ( mmio_weq_pasid[19:0] ),                         
      .mmio_weq_rd_intrpt_ctl                      ( mmio_weq_rd_intrpt_ctl ),                              
      .mmio_weq_wr_intrpt_ctl                      ( mmio_weq_wr_intrpt_ctl ),                              
      .mmio_weq_rd_intrpt_obj                      ( mmio_weq_rd_intrpt_obj ),                              
      .mmio_weq_wr_intrpt_obj                      ( mmio_weq_wr_intrpt_obj ),                              
      .mmio_weq_rd_intrpt_data                     ( mmio_weq_rd_intrpt_data ),                              
      .mmio_weq_wr_intrpt_data                     ( mmio_weq_wr_intrpt_data ),                              
      .mmio_weq_wrdata                             ( mmio_weq_wrdata[63:0] ),                        
                                                   
      .weq_mmio_wr_wed_done                        ( weq_mmio_wr_wed_done ),                         
      .weq_mmio_rd_wed_valid                       ( weq_mmio_rd_wed_valid ),                        
      .weq_mmio_rd_process_status_valid            ( weq_mmio_rd_process_status_valid ),             
      .weq_mmio_wr_intrpt_ctl_done                 ( weq_mmio_wr_intrpt_ctl_done ),                         
      .weq_mmio_rd_intrpt_ctl_valid                ( weq_mmio_rd_intrpt_ctl_valid ),                        
      .weq_mmio_wr_intrpt_obj_done                 ( weq_mmio_wr_intrpt_obj_done ),                         
      .weq_mmio_rd_intrpt_obj_valid                ( weq_mmio_rd_intrpt_obj_valid ),                        
      .weq_mmio_wr_intrpt_data_done                ( weq_mmio_wr_intrpt_data_done ),                         
      .weq_mmio_rd_intrpt_data_valid               ( weq_mmio_rd_intrpt_data_valid ),                        
      .weq_mmio_rddata                             ( weq_mmio_rddata[63:0] ),                        
  
      .mmio_weq_restart_process                    ( mmio_weq_restart_process ),                     
      .weq_mmio_restart_process_done               ( weq_mmio_restart_process_done ),                
      .weq_mmio_restart_process_error              ( weq_mmio_restart_process_error ),               
                                                                                    
      .mmio_weq_terminate_process                  ( mmio_weq_terminate_process ),                   
      .mmio_weq_terminate_pasid                    ( mmio_weq_terminate_pasid[19:0] ),                   
      .weq_mmio_terminate_process_done             ( weq_mmio_terminate_process_done ),              

    // -- interface for weq to assign work to an engine
      .weq_eng_any_enable                          ( weq_eng_any_enable ),
      .weq_eng_enable                              ( weq_eng_enable[31:0] ),                         
      .weq_eng_pasid                               ( weq_eng_pasid[19:0] ),                          
      .weq_eng_wed                                 ( weq_eng_wed[63:0] ),                            
// -- .weq_eng_intrpt_type                         ( weq_eng_intrpt_type[1:0] ),   // -- Change made to share weq_eng_wed bus (3 xfers) 
// -- .weq_eng_intrpt_obj                          ( weq_eng_intrpt_obj[63:0] ),   // -- Change made to share weq_eng_wed bus (3 xfers) 
// -- .weq_eng_intrpt_data                         ( weq_eng_intrpt_data[31:0] ),  // -- Change made to share weq_eng_wed bus (3 xfers) 
      .weq_eng_offset                              ( weq_eng_offset[18:5] ),
      .weq_eng_we_wrap                             ( weq_eng_we_wrap ),                              

    // -- interface for weq to queury engines for matching pasid when terminating
      .weq_eng_pe_terminate                        ( weq_eng_pe_terminate ),                         

    // -- interface for engine to respond to a terminate queury
      .eng_weq_pe_ack                              ( eng_weq_pe_ack[31:0] ),                         

    // -- interface for engine to request and update the pe array
      .eng_weq_we_req                              ( eng_weq_we_req[31:0] ),                         
      .weq_eng_we_gnt                              ( weq_eng_we_gnt[31:0] ),                         

      .eng_weq_we_pasid                            ( eng_weq_we_pasid[19:0] ),                       
      .eng_weq_we_offset                           ( eng_weq_we_offset[18:5] ),                      
      .eng_weq_we_wrap                             ( eng_weq_we_wrap ),                              
      .eng_weq_we_pe_stat                          ( eng_weq_we_pe_stat[11:0] ),                     
      .eng_weq_we_cmd_val_orig                     ( eng_weq_we_cmd_val_orig ),

    // -- interface for engine to report that it has completed
      .eng_weq_done                                ( eng_weq_done[31:0] ),

    // -- Display Read Interface - WEQ / Copy Engines
      .mmio_weq_display_rdval                      ( mmio_weq_display_rdval ),        
      .mmio_weq_display_mod_select                 ( mmio_weq_display_mod_select ),         
      .mmio_weq_display_ary_select                 ( mmio_weq_display_ary_select[1:0] ),         
      .mmio_weq_display_eng_select                 ( mmio_weq_display_eng_select[4:0] ),         
      .mmio_weq_display_addr                       ( mmio_weq_display_addr[4:0] ),
      .mmio_weq_display_offset                     ( mmio_weq_display_offset[3:0] ),
                                                                                 
      .weq_mmio_display_rddata_valid               ( weq_mmio_display_rddata_valid ),
      .weq_mmio_display_rddata                     ( weq_mmio_display_rddata[63:0] ),
                                                                                  
      .weq_eng_display_rdval                       ( weq_eng_display_rdval ),
                           
    // -- Simulation Idle 
      .sim_idle_weq                                ( sim_idle_weq )                                 

    );              
*/

  // -- ********************************************************************************************************************************
  // -- TLX_AFU Command In (CMDi) & AFU_TLX Response Out (RSPo)
  // -- ********************************************************************************************************************************

  afp3_cmdi_rspo  cmdi_rspo
    (
      .clock                                       ( clock_tlx ),                                    
      .reset                                       ( reset_cmdi_rspo ),                              
                                                   
    // -- TLX_AFU credit
//GFP      .tlx_afu_cmd_resp_initial_credit             ( tlx_afu_cmd_resp_initial_credit[2:0] ),         
      .tlx_afu_resp_initial_credit                 ( tlx_afu_resp_initial_credit[3:0] ),         
//GFP      .tlx_afu_data_initial_credit                 ( tlx_afu_data_initial_credit[4:0] ),             
      .tlx_afu_resp_data_initial_credit            ( tlx_afu_resp_data_initial_credit[5:0] ),             
                                                   
    // -- TLX_AFU command receive interface
      .tlx_afu_ready                               ( tlx_afu_ready ),                                
                                                   
      .tlx_afu_cmd_valid                           ( tlx_afu_cmd_valid ),                            
      .tlx_afu_cmd_opcode                          ( tlx_afu_cmd_opcode[7:0] ),                      
      .tlx_afu_cmd_capptag                         ( tlx_afu_cmd_capptag[15:0] ),                    
      .tlx_afu_cmd_dl                              ( tlx_afu_cmd_dl[1:0] ),                          
      .tlx_afu_cmd_pl                              ( tlx_afu_cmd_pl[2:0] ),                          
      .tlx_afu_cmd_be                              ( tlx_afu_cmd_be[63:0] ),                         
      .tlx_afu_cmd_end                             ( tlx_afu_cmd_end ),                              
      .tlx_afu_cmd_pa                              ( tlx_afu_cmd_pa[63:0] ),                         
      .tlx_afu_cmd_flag                            ( tlx_afu_cmd_flag[3:0] ),                        
      .tlx_afu_cmd_os                              ( tlx_afu_cmd_os ),                               
                                                   
      .tlx_afu_cmd_data_valid                      ( tlx_afu_cmd_data_valid ),                       
      .tlx_afu_cmd_data_bdi                        ( tlx_afu_cmd_data_bdi ),                         
      .tlx_afu_cmd_data_bus                        ( tlx_afu_cmd_data_bus[511:0] ),                  
                                                   
      .afu_tlx_cmd_rd_req                          ( afu_tlx_cmd_rd_req ),                           
      .afu_tlx_cmd_rd_cnt                          ( afu_tlx_cmd_rd_cnt[2:0] ),                      
                                                   
      .afu_tlx_cmd_credit                          ( afu_tlx_cmd_credit ),                           
      .afu_tlx_cmd_initial_credit                  ( afu_tlx_cmd_initial_credit[6:0] ),              
                                                   
    // -- MMIO interface
      .cmdi_mmio_rd                                ( cmdi_mmio_rd ),                                 
      .cmdi_mmio_wr                                ( cmdi_mmio_wr ),                                 
      .cmdi_mmio_large_rd                          ( cmdi_mmio_large_rd ),                                 
      .cmdi_mmio_large_wr                          ( cmdi_mmio_large_wr ),                                 
      .cmdi_mmio_large_wr_half_en                  ( cmdi_mmio_large_wr_half_en[1:0] ),                                 
      .cmdi_mmio_addr                              ( cmdi_mmio_addr[25:0] ),                         
      .cmdi_mmio_wrdata                            ( cmdi_mmio_wrdata[1023:0] ),                       
      .cmdi_mmio_early_wr                          ( cmdi_mmio_early_wr ),
      .cmdi_mmio_early_large_wr                    ( cmdi_mmio_early_large_wr ),
      .cmdi_mmio_early_large_wr_half_en            ( cmdi_mmio_early_large_wr_half_en[1:0] ),
      .cmdi_mmio_early_addr                        ( cmdi_mmio_early_addr[25:0] ),
      .mmio_rspo_wr_done                           ( mmio_rspo_wr_done ),

      .mmio_rspo_rddata_valid                      ( mmio_rspo_rddata_valid ),                       
      .mmio_rspo_rddata                            ( mmio_rspo_rddata[1023:0] ),                       
      .mmio_rspo_bad_op_or_align                   ( mmio_rspo_bad_op_or_align ),                    
      .mmio_rspo_addr_not_implemented              ( mmio_rspo_addr_not_implemented ),               
                                                                                                      
    // -- AFU_TLX response transmit interface
      .afu_tlx_resp_valid                          ( afu_tlx_resp_valid ),                           
      .afu_tlx_resp_opcode                         ( afu_tlx_resp_opcode[7:0] ),                     
      .afu_tlx_resp_dl                             ( afu_tlx_resp_dl[1:0] ),                         
      .afu_tlx_resp_capptag                        ( afu_tlx_resp_capptag[15:0] ),                   
      .afu_tlx_resp_dp                             ( afu_tlx_resp_dp[1:0] ),                         
      .afu_tlx_resp_code                           ( afu_tlx_resp_code[3:0] ),                       
                                                   
      .afu_tlx_rdata_valid                         ( afu_tlx_rdata_valid ),                          
      .afu_tlx_rdata_bdi                           ( afu_tlx_rdata_bdi ),                            
      .afu_tlx_rdata_bus                           ( afu_tlx_rdata_bus[511:0] ),                     
                                                   
      .tlx_afu_resp_credit                         ( tlx_afu_resp_credit ),                          
      .tlx_afu_resp_data_credit                    ( tlx_afu_resp_data_credit ),                     


    // -- TLX_AFU Command Receive Bus Trace output   (MMIO requests)
//--  .trace_tlx_afu_ready                         ( trace_tlx_afu_ready ),                          

      .trace_tlx_afu_cmd_valid                     ( trace_tlx_afu_cmd_valid ),                      
      .trace_tlx_afu_cmd_opcode                    ( trace_tlx_afu_cmd_opcode[7:0] ),                
      .trace_tlx_afu_cmd_capptag                   ( trace_tlx_afu_cmd_capptag[15:0] ),              
// -- .trace_tlx_afu_cmd_dl                        ( trace_tlx_afu_cmd_dl[1:0] ),                    
      .trace_tlx_afu_cmd_pl                        ( trace_tlx_afu_cmd_pl[2:0] ),                    
// -- .trace_tlx_afu_cmd_be                        ( trace_tlx_afu_cmd_be[63:0] ),                   
// -- .trace_tlx_afu_cmd_end                       ( trace_tlx_afu_cmd_end ),                        
// -- .trace_tlx_afu_cmd_t                         ( trace_tlx_afu_cmd_t ),                          
      .trace_tlx_afu_cmd_pa                        ( trace_tlx_afu_cmd_pa[25:0] ),                   
// -- .trace_tlx_afu_cmd_flag                      ( trace_tlx_afu_cmd_flag[3:0] ),                  
// -- .trace_tlx_afu_cmd_os                        ( trace_tlx_afu_cmd_os ),                         

      .trace_tlx_afu_cmd_data_valid                ( trace_tlx_afu_cmd_data_valid ),                 
      .trace_tlx_afu_cmd_data_bdi                  ( trace_tlx_afu_cmd_data_bdi ),                   
      .trace_tlx_afu_cmd_data_bus                  ( trace_tlx_afu_cmd_data_bus[63:0] ),             

      .trace_afu_tlx_cmd_rd_req                    ( trace_afu_tlx_cmd_rd_req ),                     
// -- .trace_afu_tlx_cmd_rd_cnt                    ( trace_afu_tlx_cmd_rd_cnt[2:0] ),                

      .trace_afu_tlx_cmd_credit                    ( trace_afu_tlx_cmd_credit ),                     

      .trace_tlx_afu_mmio_rd_cmd_valid             ( trace_tlx_afu_mmio_rd_cmd_valid ),
      .trace_tlx_afu_mmio_wr_cmd_valid             ( trace_tlx_afu_mmio_wr_cmd_valid ),


    // -- AFU_TLX Response Transmit Bus Trace outputs   (MMIO responses)
      .trace_afu_tlx_resp_valid                    ( trace_afu_tlx_resp_valid ),                     
      .trace_afu_tlx_resp_opcode                   ( trace_afu_tlx_resp_opcode[3:0] ),               
      .trace_afu_tlx_resp_dl                       ( trace_afu_tlx_resp_dl[1:0] ),                   
      .trace_afu_tlx_resp_capptag                  ( trace_afu_tlx_resp_capptag[15:0] ),             
// -- .trace_afu_tlx_resp_dp                       ( trace_afu_tlx_resp_dp[1:0] ),                   
      .trace_afu_tlx_resp_code                     ( trace_afu_tlx_resp_code[3:0] ),                 

      .trace_afu_tlx_rdata_valid                   ( trace_afu_tlx_rdata_valid ),                    
// -- .trace_afu_tlx_rdata_bdi                     ( trace_afu_tlx_rdata_bdi ),                      
// -- .trace_afu_tlx_rdata_bus                     ( trace_afu_tlx_rdata_bus[63:0] ),                

      .trace_tlx_afu_resp_credit                   ( trace_tlx_afu_resp_credit ),                    
      .trace_tlx_afu_resp_data_credit              ( trace_tlx_afu_resp_data_credit ),               

//GFP      .trace_rspo_avail_resp_credit                ( trace_rspo_avail_resp_credit[2:0] ),            
      .trace_rspo_avail_resp_credit                ( trace_rspo_avail_resp_credit[3:0] ),            
//GFP      .trace_rspo_avail_data_credit                ( trace_rspo_avail_data_credit[4:0] ),            
      .trace_rspo_avail_data_credit                ( trace_rspo_avail_data_credit[5:0] ),            
    
    // -- CNFG/MMIO                                               
      .cfg_csh_mmio_bar0                           ( cfg_csh_mmio_bar0[63:20] ),                   

      .sim_idle_cmdi_rspo                          ( sim_idle_cmdi_rspo )                           

    );              


  // -- ********************************************************************************************************************************
  // -- AFU_TLX Command Out (CMDo)
  // -- ********************************************************************************************************************************

  afp3_cmdo  cmdo
    (
      .clock_afu                                   ( clock_afu ),                                    
      .clock_tlx                                   ( clock_tlx ),                                    
      .reset                                       ( reset_cmdo ),                                   

    // -- Config/Mode info
      .cfg_afu_pasid_base                          ( cfg_octrl00_pasid_base[19:0] ),                   
      .mmio_cmdo_pasid_mask                        ( mmio_cmdo_pasid_mask[19:0] ),
      .mmio_cmdo_split_128B_cmds                   ( mmio_cmdo_split_128B_cmds ),                                             

    // -- Command input from Engines
      .eng_cmdo_valid                              ( eng_cmdo_valid ),                               
      .eng_cmdo_opcode                             ( eng_cmdo_opcode[7:0] ),                         
      .eng_cmdo_actag                              ( eng_cmdo_actag[11:0] ),                         
      .eng_cmdo_stream_id                          ( eng_cmdo_stream_id[3:0] ),                      
      .eng_cmdo_ea_or_obj                          ( eng_cmdo_ea_or_obj[67:0] ),                     
      .eng_cmdo_afutag                             ( eng_cmdo_afutag[15:0] ),                        
      .eng_cmdo_dl                                 ( eng_cmdo_dl[1:0] ),                             
      .eng_cmdo_pl                                 ( eng_cmdo_pl[2:0] ),                             
      .eng_cmdo_os                                 ( eng_cmdo_os ),                                  
      .eng_cmdo_be                                 ( eng_cmdo_be[63:0] ),                            
      .eng_cmdo_flag                               ( eng_cmdo_flag[3:0] ),                           
      .eng_cmdo_endian                             ( eng_cmdo_endian ),                              
      .eng_cmdo_bdf                                ( eng_cmdo_bdf[15:0] ),                           
      .eng_cmdo_pasid                              ( eng_cmdo_pasid[19:0] ),                         
      .eng_cmdo_pg_size                            ( eng_cmdo_pg_size[5:0] ),                        
      .eng_cmdo_st_valid                           ( eng_cmdo_st_valid ),                            
      .eng_cmdo_st_data                            ( eng_cmdo_st_data[1023:0] ),                     

    // -- Send latched Command to response logic to capture into response array
      .cmdo_rspi_cmd_valid                         ( cmdo_rspi_cmd_valid ),                          
      .cmdo_rspi_cmd_opcode                        ( cmdo_rspi_cmd_opcode[7:0] ),                    
      .cmdo_rspi_cmd_dl                            ( cmdo_rspi_cmd_dl[1:0] ),                        

    // -- AFU_TLX command transmit interface
      .afu_tlx_cmd_valid                           ( afu_tlx_cmd_valid ),                            
      .afu_tlx_cmd_opcode                          ( afu_tlx_cmd_opcode[7:0] ),                      
      .afu_tlx_cmd_actag                           ( afu_tlx_cmd_actag[11:0] ),                      
      .afu_tlx_cmd_stream_id                       ( afu_tlx_cmd_stream_id[3:0] ),                   
      .afu_tlx_cmd_ea_or_obj                       ( afu_tlx_cmd_ea_or_obj[67:0] ),                  
      .afu_tlx_cmd_afutag                          ( afu_tlx_cmd_afutag[15:0] ),                     
      .afu_tlx_cmd_dl                              ( afu_tlx_cmd_dl[1:0] ),                          
      .afu_tlx_cmd_pl                              ( afu_tlx_cmd_pl[2:0] ),                          
      .afu_tlx_cmd_os                              ( afu_tlx_cmd_os ),                               
      .afu_tlx_cmd_be                              ( afu_tlx_cmd_be[63:0] ),                         
      .afu_tlx_cmd_flag                            ( afu_tlx_cmd_flag[3:0] ),                        
      .afu_tlx_cmd_endian                          ( afu_tlx_cmd_endian ),                           
      .afu_tlx_cmd_bdf                             ( afu_tlx_cmd_bdf[15:0] ),                        
      .afu_tlx_cmd_pasid                           ( afu_tlx_cmd_pasid[19:0] ),                      
      .afu_tlx_cmd_pg_size                         ( afu_tlx_cmd_pg_size[5:0] ),                     
                                            
      .afu_tlx_cdata_valid                         ( afu_tlx_cdata_valid ),                          
      .afu_tlx_cdata_bdi                           ( afu_tlx_cdata_bdi ),                          
      .afu_tlx_cdata_bus                           ( afu_tlx_cdata_bus[511:0] ),                     
                                      
      .tlx_afu_cmd_credit                          ( tlx_afu_cmd_credit ),                           
      .tlx_afu_cmd_data_credit                     ( tlx_afu_cmd_data_credit ),                      

//GFP      .tlx_afu_cmd_resp_initial_credit_x           ( tlx_afu_cmd_resp_initial_credit_x[4:3] ),         
      .tlx_afu_cmd_initial_credit_x                ( tlx_afu_cmd_initial_credit_x[4:4] ),         
//GFP      .tlx_afu_cmd_resp_initial_credit             ( tlx_afu_cmd_resp_initial_credit[2:0] ),         
      .tlx_afu_cmd_initial_credit                  ( tlx_afu_cmd_initial_credit[3:0] ),         
//GFP      .tlx_afu_data_initial_credit_x               ( tlx_afu_data_initial_credit_x[6:5] ),             
      .tlx_afu_cmd_data_initial_credit_x           ( tlx_afu_cmd_data_initial_credit_x[6:6] ),             
//GFP      .tlx_afu_data_initial_credit                 ( tlx_afu_data_initial_credit[4:0] ),             
      .tlx_afu_cmd_data_initial_credit             ( tlx_afu_cmd_data_initial_credit[5:0] ),

      .cmdo_arb_cmd_credit_ge_1                    ( cmdo_arb_cmd_credit_ge_1 ),                     
      .cmdo_arb_cmd_credit_ge_2                    ( cmdo_arb_cmd_credit_ge_2 ),                     
      .cmdo_arb_data_credit_ge_4                   ( cmdo_arb_data_credit_ge_4 ),                    
      .cmdo_arb_data_credit_ge_2                   ( cmdo_arb_data_credit_ge_2 ),                    
      .cmdo_arb_data_credit_ge_1                   ( cmdo_arb_data_credit_ge_1 ),                    

      .arb_cmdo_decr_cmd_credit                    ( arb_cmdo_decr_cmd_credit ),                     
      .arb_cmdo_decr_data_credit_4                 ( arb_cmdo_decr_data_credit_4 ),                  
      .arb_cmdo_decr_data_credit_2                 ( arb_cmdo_decr_data_credit_2 ),                  
      .arb_cmdo_decr_data_credit_1                 ( arb_cmdo_decr_data_credit_1 ),                  

    // -- AFU_TLX Command Transmit Bus Trace inputs
      .trace_afu_tlx_cmd_valid                     ( trace_afu_tlx_cmd_valid ),                      
      .trace_afu_tlx_cmd_opcode                    ( trace_afu_tlx_cmd_opcode[7:0] ),                
      .trace_afu_tlx_cmd_actag                     ( trace_afu_tlx_cmd_actag[5:0] ),                 
// -- .trace_afu_tlx_cmd_stream_id                 ( trace_afu_tlx_cmd_stream_id[3:0] ),             
      .trace_afu_tlx_cmd_ea_or_obj                 ( trace_afu_tlx_cmd_ea_or_obj[67:0] ),            
      .trace_afu_tlx_cmd_afutag                    ( trace_afu_tlx_cmd_afutag[15:0] ),               
      .trace_afu_tlx_cmd_dl                        ( trace_afu_tlx_cmd_dl[1:0] ),                    
      .trace_afu_tlx_cmd_pl                        ( trace_afu_tlx_cmd_pl[2:0] ),                    
// -- .trace_afu_tlx_cmd_os                        ( trace_afu_tlx_cmd_os ),                         
// -- .trace_afu_tlx_cmd_be                        ( trace_afu_tlx_cmd_be[63:0] ),                   
      .trace_afu_tlx_cmd_flag                      ( trace_afu_tlx_cmd_flag[3:0] ),                  
// -- .trace_afu_tlx_cmd_endian                    ( trace_afu_tlx_cmd_endian ),                     
// -- .trace_afu_tlx_cmd_bdf                       ( trace_afu_tlx_cmd_bdf[15:0] ),                  
      .trace_afu_tlx_cmd_pasid                     ( trace_afu_tlx_cmd_pasid[9:0] ),                 
      .trace_afu_tlx_cmd_pg_size                   ( trace_afu_tlx_cmd_pg_size[5:0] ),               

      .trace_afu_tlx_cdata_valid                   ( trace_afu_tlx_cdata_valid ),                    
// -- .trace_afu_tlx_cdata_bdi                     ( trace_afu_tlx_cdata_bdi ),                      
// -- .trace_afu_tlx_cdata_bus                     ( trace_afu_tlx_cdata_bus[1023:0] ),              

      .trace_tlx_afu_cmd_credit                    ( trace_tlx_afu_cmd_credit[1:0] ),                
      .trace_tlx_afu_cmd_data_credit               ( trace_tlx_afu_cmd_data_credit[1:0] ),           

      .trace_cmdo_avail_cmd_credit                 ( trace_cmdo_avail_cmd_credit[4:0] ),             
      .trace_cmdo_avail_cmd_data_credit            ( trace_cmdo_avail_cmd_data_credit[6:0] ),            

    // -- Display Read Interface - Copy Engines
      .mmio_cmdo_display_offset                    ( mmio_cmdo_display_offset[3:0] ),
      .cmdo_mmio_display_rddata                    ( cmdo_mmio_display_rddata[63:0] ),

    // -- Simulation Idle
      .sim_idle_cmdo                               ( sim_idle_cmdo )
                                
    );              


  // -- ********************************************************************************************************************************
  // -- TLX_AFU Response In (RSPi)
  // -- ********************************************************************************************************************************

  afp3_rspi  rspi
    (
      .clock_afu                                   ( clock_afu ),                                    
      .clock_tlx                                   ( clock_tlx ),                                    
      .reset                                       ( reset_rspi ),                                   

    // -- CMDO_RSPI interface (for tracking cmds sent vs responses received)
      .cmdo_rspi_cmd_valid                         ( cmdo_rspi_cmd_valid ),                          
      .cmdo_rspi_cmd_opcode                        ( cmdo_rspi_cmd_opcode[7:0] ),                    
      .cmdo_rspi_cmd_dl                            ( cmdo_rspi_cmd_dl[1:0] ),                        

    // -- TLX_AFU response receive interface
      .tlx_afu_resp_valid                          ( tlx_afu_resp_valid ),                           
      .tlx_afu_resp_afutag                         ( tlx_afu_resp_afutag[15:0] ),                    
      .tlx_afu_resp_opcode                         ( tlx_afu_resp_opcode[7:0] ),                     
      .tlx_afu_resp_code                           ( tlx_afu_resp_code[3:0] ),                       
      .tlx_afu_resp_dl                             ( tlx_afu_resp_dl[1:0] ),                         
      .tlx_afu_resp_dp                             ( tlx_afu_resp_dp[1:0] ),                         
  // --, tlx_afu_resp_pg_size[5:0]            => tlx_afu_resp_pg_size[5:0]   -- Not used in this implementation
  // --, tlx_afu_resp_addr_tag[17:0]          => tlx_afu_resp_addr_tag[17:0] -- Not used in this implementation

      .afu_tlx_resp_rd_req                         ( afu_tlx_resp_rd_req ),                          
      .afu_tlx_resp_rd_cnt                         ( afu_tlx_resp_rd_cnt[2:0] ),                     
                                                   
      .tlx_afu_resp_data_valid                     ( tlx_afu_resp_data_valid ),                      
      .tlx_afu_resp_data_bdi                       ( tlx_afu_resp_data_bdi ),                      
      .tlx_afu_resp_data_bus                       ( tlx_afu_resp_data_bus[511:0] ),                 
                                                   
      .afu_tlx_resp_credit                         ( afu_tlx_resp_credit ),                          
      .afu_tlx_resp_initial_credit                 ( afu_tlx_resp_initial_credit[6:0] ),             

    // -- pcmd resp interface
      .rspi_eng_resp_valid                         ( rspi_eng_resp_valid ),                    
      .rspi_eng_resp_afutag                        ( rspi_eng_resp_afutag[15:0] ),                   
      .rspi_eng_resp_opcode                        ( rspi_eng_resp_opcode[7:0] ),                    
      .rspi_eng_resp_code                          ( rspi_eng_resp_code[3:0] ),                      
      .rspi_eng_resp_dl                            ( rspi_eng_resp_dl[1:0] ),                        
      .rspi_eng_resp_dp                            ( rspi_eng_resp_dp[1:0] ),                        
      .rspi_eng_resp_data_valid                    ( rspi_eng_resp_data_valid ),                     
      .rspi_eng_resp_data_bdi                      ( rspi_eng_resp_data_bdi[1:0] ),                     
      .rspi_eng_resp_data_bus                      ( rspi_eng_resp_data_bus[1023:0] ),               

    // -- Configuration/Mode Bits
      .mmio_rspi_fastpath_queue_bypass_disable     ( mmio_rspi_fastpath_queue_bypass_disable ),      
      .mmio_rspi_fastpath_stg0_bypass_disable      ( mmio_rspi_fastpath_stg0_bypass_disable ),       
      .mmio_rspi_fastpath_stg1_bypass_disable      ( mmio_rspi_fastpath_stg1_bypass_disable ),       
      .mmio_rspi_fastpath_stg2_bypass_disable      ( mmio_rspi_fastpath_stg2_bypass_disable ),       
      .mmio_rspi_normal_stg1_bypass_disable        ( mmio_rspi_normal_stg1_bypass_disable ),         
      .mmio_rspi_normal_stg2_bypass_disable        ( mmio_rspi_normal_stg2_bypass_disable ),

      .mmio_rspi_fastpath_blocker_disable          ( mmio_rspi_fastpath_blocker_disable ),       

      .rspi_mmio_resp_queue_maxqdepth              ( rspi_mmio_resp_queue_maxqdepth[7:0] ),          
      .mmio_rspi_resp_queue_maxqdepth_reset        ( mmio_rspi_resp_queue_maxqdepth_reset ),         

      .rspi_mmio_max_outstanding_responses         ( rspi_mmio_max_outstanding_responses[11:0] ),          
      .mmio_rspi_max_outstanding_responses_reset   ( mmio_rspi_max_outstanding_responses_reset ),         

    // -- TLX_AFU Response Receive Bus Trace inputs
      .trace_tlx_afu_resp_valid_with_data          ( trace_tlx_afu_resp_valid_with_data ),           
      .trace_tlx_afu_resp_valid_no_data            ( trace_tlx_afu_resp_valid_no_data ),             
      .trace_tlx_afu_resp_valid_retry              ( trace_tlx_afu_resp_valid_retry ),               
      .trace_tlx_afu_resp_afutag                   ( trace_tlx_afu_resp_afutag[15:0] ),              
      .trace_tlx_afu_resp_opcode                   ( trace_tlx_afu_resp_opcode[7:0] ),               
      .trace_tlx_afu_resp_code                     ( trace_tlx_afu_resp_code[3:0] ),                 
      .trace_tlx_afu_resp_dl                       ( trace_tlx_afu_resp_dl[1:0] ),                   
      .trace_tlx_afu_resp_dp                       ( trace_tlx_afu_resp_dp[1:0] ),                   
// -- .trace_tlx_afu_resp_pg_size                  ( trace_tlx_afu_resp_pg_size[5:0] ),              
// -- .trace_tlx_afu_resp_addr_tag                 ( trace_tlx_afu_resp_addr_tag[17:0] ),            

      .trace_afu_tlx_resp_rd_req                   ( trace_afu_tlx_resp_rd_req ),                    
      .trace_afu_tlx_resp_rd_cnt                   ( trace_afu_tlx_resp_rd_cnt[2:0] ),               

      .trace_tlx_afu_resp_data_valid               ( trace_tlx_afu_resp_data_valid ),                
      .trace_tlx_afu_resp_data_bdi                 ( trace_tlx_afu_resp_data_bdi[1:0] ),             
// -- .trace_tlx_afu_resp_data_bus                 ( trace_tlx_afu_resp_data_bus[511:0] ),           

      .trace_afu_tlx_resp_credit                   ( trace_afu_tlx_resp_credit ),
                    
    // -- Display Read Interface - Response Queue
      .mmio_rspi_display_rdval                     ( mmio_rspi_display_rdval ),               
      .mmio_rspi_display_addr                      ( mmio_rspi_display_addr[6:0] ),
                                                                                    
      .rspi_mmio_display_rddata_valid              ( rspi_mmio_display_rddata_valid ),        
      .rspi_mmio_display_rddata                    ( rspi_mmio_display_rddata[63:0] ),

    // -- Simulation Idle
      .sim_idle_rspi                               ( sim_idle_rspi )                                

    );              


  // -- ********************************************************************************************************************************
  // -- Engine Arbiters
  // -- ********************************************************************************************************************************

  afp3_arb  arb
    (
      .clock                                       ( clock_afu ),                                    
      .reset                                       ( reset_arb ),                                    

    // -- inbound controls from engine
      .eng_arb_init                                ( eng_arb_init ),
      .eng_arb_ld_enable                           ( eng_arb_ld_enable ),
      .eng_arb_st_enable                           ( eng_arb_st_enable ),

    // -- inbound cmd request pulses from the engines
      .eng_arb_rtry_misc_req                       ( eng_arb_rtry_misc_req ),                       
      .eng_arb_rtry_misc_w_data                    ( eng_arb_rtry_misc_w_data ),                       
      .eng_arb_rtry_st_req                         ( eng_arb_rtry_st_req ),                    
      .eng_arb_rtry_st_256                         ( eng_arb_rtry_st_256 ),                    
      .eng_arb_rtry_st_128                         ( eng_arb_rtry_st_128 ),                    
      .eng_arb_rtry_ld_req                         ( eng_arb_rtry_ld_req ),                    
      .eng_arb_misc_req                            ( eng_arb_misc_req ),                       
      .eng_arb_misc_w_data                         ( eng_arb_misc_w_data ),                       
      .eng_arb_misc_needs_extra_write              ( eng_arb_misc_needs_extra_write ),                       

    // -- outbound grant pulses to the engines - engines may drive bus on cycle after grant
      .arb_eng_rtry_misc_gnt                       ( arb_eng_rtry_misc_gnt ),                    
      .arb_eng_rtry_st_gnt                         ( arb_eng_rtry_st_gnt ),                    
      .arb_eng_rtry_ld_gnt                         ( arb_eng_rtry_ld_gnt ),                    
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),                       
      .arb_eng_st_gnt                              ( arb_eng_st_gnt ),                         
      .arb_eng_ld_gnt                              ( arb_eng_ld_gnt ),                         

      .arb_eng_ld_tag                              ( arb_eng_ld_tag[8:0] ),
      .arb_eng_st_tag                              ( arb_eng_st_tag[8:0] ),
      .eng_arb_set_ld_tag_avail                    ( eng_arb_set_ld_tag_avail[511:0] ),
      .eng_arb_set_st_tag_avail                    ( eng_arb_set_st_tag_avail[511:0] ),

      .eng_arb_ld_fastpath_valid                   ( eng_arb_ld_fastpath_valid ),
      .eng_arb_ld_fastpath_tag                     ( eng_arb_ld_fastpath_tag[8:0] ),
      .eng_arb_st_fastpath_valid                   ( eng_arb_st_fastpath_valid ),
      .eng_arb_st_fastpath_tag                     ( eng_arb_st_fastpath_tag[8:0] ),

      .arb_eng_tags_idle                           ( arb_eng_tags_idle ),

    // -- credit interface
      .cmdo_arb_cmd_credit_ge_1                    ( cmdo_arb_cmd_credit_ge_1 ),                     
      .cmdo_arb_cmd_credit_ge_2                    ( cmdo_arb_cmd_credit_ge_2 ),                     
      .cmdo_arb_data_credit_ge_4                   ( cmdo_arb_data_credit_ge_4 ),                    
      .cmdo_arb_data_credit_ge_2                   ( cmdo_arb_data_credit_ge_2 ),                    
      .cmdo_arb_data_credit_ge_1                   ( cmdo_arb_data_credit_ge_1 ),                    

      .arb_cmdo_decr_cmd_credit                    ( arb_cmdo_decr_cmd_credit ),                     
      .arb_cmdo_decr_data_credit_4                 ( arb_cmdo_decr_data_credit_4 ),                  
      .arb_cmdo_decr_data_credit_2                 ( arb_cmdo_decr_data_credit_2 ),                  
      .arb_cmdo_decr_data_credit_1                 ( arb_cmdo_decr_data_credit_1 ),                  

    // -- control and config signals
      .cfg_afu_enable_afu                          ( cfg_octrl00_enable_afu ),                   
      .mmio_arb_ldst_priority_mode                 ( mmio_arb_ldst_priority_mode[1:0] ),             
      .mmio_arb_num_ld_tags                        ( mmio_arb_num_ld_tags[2:0] ),             
      .mmio_arb_num_st_tags                        ( mmio_arb_num_st_tags[2:0] ),             
      .mmio_arb_type_ld                            ( mmio_arb_type_ld ),             
      .mmio_arb_type_st                            ( mmio_arb_type_st ),             
      .mmio_arb_ld_size                            ( mmio_arb_ld_size[1:0] ),             
      .mmio_arb_st_size                            ( mmio_arb_st_size[1:0] ),             
      .mmio_arb_mmio_lat_mode                      ( mmio_arb_mmio_lat_mode ),
      .mmio_arb_mmio_lat_mode_sz_512_st            ( mmio_arb_mmio_lat_mode_sz_512_st ),
      .mmio_arb_mmio_lat_mode_sz_512_ld            ( mmio_arb_mmio_lat_mode_sz_512_ld ),
      .mmio_arb_mmio_lat_extra_read                ( mmio_arb_mmio_lat_extra_read ),
      .mmio_arb_mmio_access                        ( mmio_arb_mmio_access ),
      .mmio_arb_xtouch_enable                      ( mmio_arb_xtouch_enable ),
      .mmio_arb_xtouch_wt4rsp_enable               ( mmio_arb_xtouch_wt4rsp_enable ),
      .mmio_arb_fastpath_disable                   ( mmio_arb_fastpath_disable ),

      .arb_perf_latency_update                     ( arb_perf_latency_update ),
      .arb_perf_no_credits                         ( arb_perf_no_credits ),

      .sim_idle_arb                                ( sim_idle_arb )                                

    );              


  // -- ********************************************************************************************************************************
  // -- Engine Wrapper
  // -- ********************************************************************************************************************************

  afp3_eng  eng
    (
      .clock                                       ( clock_afu ),
      .reset                                       ( reset_eng ),

//         .eng_weq_available                           ( eng_weq_available[31:0] ),
//         .weq_eng_any_enable                          ( weq_eng_any_enable ),
//         .weq_eng_enable                              ( weq_eng_enable[31:0] ),
//         .weq_eng_pe_terminate                        ( weq_eng_pe_terminate ),
      .mmio_eng_pasid                              ( mmio_eng_pasid[9:0] ),
//         .weq_eng_wed                                ( weq_eng_wed[63:0] ),
// -- .weq_eng_intrpt_obj                          ( weq_eng_intrpt_obj[63:0] ),   // -- Change made to share weq_eng_wed bus (3 xfers) 
// -- .weq_eng_intrpt_data                         ( weq_eng_intrpt_data[31:0] ),  // -- Change made to share weq_eng_wed bus (3 xfers) 
// -- .weq_eng_intrpt_type                         ( weq_eng_intrpt_type[1:0] ),   // -- Change made to share weq_eng_wed bus (3 xfers) 
//         .weq_eng_offset                              ( weq_eng_offset[18:5] ),
//         .weq_eng_we_wrap                             ( weq_eng_we_wrap ),
//         .eng_weq_pe_ack                              ( eng_weq_pe_ack[31:0] ),

//         .eng_weq_we_req                              ( eng_weq_we_req[31:0] ),
//         .weq_eng_we_gnt                              ( weq_eng_we_gnt[31:0] ),
//         .eng_weq_we_pasid                            ( eng_weq_we_pasid[19:0] ),
//         .eng_weq_we_offset                           ( eng_weq_we_offset[18:5] ),
//         .eng_weq_we_wrap                             ( eng_weq_we_wrap ),
//         .eng_weq_we_pe_stat                          ( eng_weq_we_pe_stat[11:0] ),
//         .eng_weq_we_cmd_val_orig                     ( eng_weq_we_cmd_val_orig ),

//         .eng_weq_done                                ( eng_weq_done[31:0] ),

    // -- engine load cmd request interface, commands that require inbound data buffer slot
//         .eng_arb_ld_req                              ( eng_arb_ld_req ),
      .arb_eng_ld_gnt                              ( arb_eng_ld_gnt ),
      .arb_eng_ld_tag                              ( arb_eng_ld_tag[8:0] ),
      .eng_arb_set_ld_tag_avail                    ( eng_arb_set_ld_tag_avail[511:0] ),
      .eng_arb_ld_fastpath_valid                   ( eng_arb_ld_fastpath_valid ),
      .eng_arb_ld_fastpath_tag                     ( eng_arb_ld_fastpath_tag[8:0] ),
//         .eng_arb_st_req                              ( eng_arb_st_req ),
//         .eng_arb_st_256                              ( eng_arb_st_256 ),
//         .eng_arb_st_128                              ( eng_arb_st_128 ),
      .arb_eng_st_gnt                              ( arb_eng_st_gnt ),
      .arb_eng_st_tag                              ( arb_eng_st_tag[8:0] ),
      .eng_arb_set_st_tag_avail                    ( eng_arb_set_st_tag_avail[511:0] ),
      .eng_arb_st_fastpath_valid                   ( eng_arb_st_fastpath_valid ),
      .eng_arb_st_fastpath_tag                     ( eng_arb_st_fastpath_tag[8:0] ),
      .eng_arb_misc_req                            ( eng_arb_misc_req ),
      .eng_arb_misc_w_data                         ( eng_arb_misc_w_data ),
      .eng_arb_misc_needs_extra_write              ( eng_arb_misc_needs_extra_write ),
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),
      .eng_arb_rtry_ld_req                         ( eng_arb_rtry_ld_req ),
      .arb_eng_rtry_ld_gnt                         ( arb_eng_rtry_ld_gnt ),
      .eng_arb_rtry_st_req                         ( eng_arb_rtry_st_req ),
      .eng_arb_rtry_st_256                         ( eng_arb_rtry_st_256 ),
      .eng_arb_rtry_st_128                         ( eng_arb_rtry_st_128 ),
      .arb_eng_rtry_st_gnt                         ( arb_eng_rtry_st_gnt ),
      .eng_arb_rtry_misc_req                       ( eng_arb_rtry_misc_req ),
      .eng_arb_rtry_misc_w_data                    ( eng_arb_rtry_misc_w_data ),
      .arb_eng_rtry_misc_gnt                       ( arb_eng_rtry_misc_gnt ),

      .arb_eng_tags_idle                           ( arb_eng_tags_idle ),
      .eng_arb_init                                ( eng_arb_init ),
      .eng_arb_ld_enable                           ( eng_arb_ld_enable ),
      .eng_arb_st_enable                           ( eng_arb_st_enable ),

    // -- command signals, shared between load/store/misc  (gnt <= ld_gnt or st_gnt or misc_gnt)
      .eng_cmdo_valid                              ( eng_cmdo_valid ),
      .eng_cmdo_opcode                             ( eng_cmdo_opcode[7:0] ),
      .eng_cmdo_actag                              ( eng_cmdo_actag[11:0] ),
      .eng_cmdo_stream_id                          ( eng_cmdo_stream_id[3:0] ),
      .eng_cmdo_ea_or_obj                          ( eng_cmdo_ea_or_obj[67:0] ),
      .eng_cmdo_afutag                             ( eng_cmdo_afutag[15:0] ),
      .eng_cmdo_dl                                 ( eng_cmdo_dl[1:0] ),
      .eng_cmdo_pl                                 ( eng_cmdo_pl[2:0] ),
      .eng_cmdo_os                                 ( eng_cmdo_os ),
      .eng_cmdo_be                                 ( eng_cmdo_be[63:0] ),
      .eng_cmdo_flag                               ( eng_cmdo_flag[3:0] ),
      .eng_cmdo_endian                             ( eng_cmdo_endian ),
      .eng_cmdo_bdf                                ( eng_cmdo_bdf[15:0] ),
      .eng_cmdo_pasid                              ( eng_cmdo_pasid[19:0] ),
      .eng_cmdo_pg_size                            ( eng_cmdo_pg_size[5:0] ),

      .eng_cmdo_st_valid                           ( eng_cmdo_st_valid ),
      .eng_cmdo_st_data                            ( eng_cmdo_st_data[1023:0] ),

      .rspi_eng_resp_valid                         ( rspi_eng_resp_valid ),
      .rspi_eng_resp_afutag                        ( rspi_eng_resp_afutag[15:0] ),
      .rspi_eng_resp_opcode                        ( rspi_eng_resp_opcode[7:0] ),
      .rspi_eng_resp_code                          ( rspi_eng_resp_code[3:0] ),
      .rspi_eng_resp_dl                            ( rspi_eng_resp_dl[1:0] ),
      .rspi_eng_resp_dp                            ( rspi_eng_resp_dp[1:0] ),
      .rspi_eng_resp_data_valid                    ( rspi_eng_resp_data_valid ),
      .rspi_eng_resp_data_bdi                      ( rspi_eng_resp_data_bdi[1:0] ),
      .rspi_eng_resp_data_bus                      ( rspi_eng_resp_data_bus[1023:0] ),

      .cfg_afu_actag_base                          ( cfg_octrl00_afu_actag_base[11:0] ),
      .cfg_afu_long_backoff_timer                  ( cfg_f0_otl0_long_backoff_timer[3:0] ),
      .cfg_afu_short_backoff_timer                 ( cfg_f0_otl0_short_backoff_timer[3:0] ),

      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),

//         .mmio_eng_intrpt_on_cpy_err_en               ( mmio_eng_intrpt_on_cpy_err_en ),
//         .mmio_eng_stop_on_invalid_cmd                ( mmio_eng_stop_on_invalid_cmd ),
//         .mmio_eng_256B_op_disable                    ( mmio_eng_256B_op_disable ),
//         .mmio_eng_128B_op_disable                    ( mmio_eng_128B_op_disable ),
//         .mmio_eng_hold_pasid_for_debug               ( mmio_eng_hold_pasid_for_debug ),
      .mmio_eng_use_pasid_for_actag                ( mmio_eng_use_pasid_for_actag ),
//         .mmio_eng_xtouch_source_enable               ( mmio_eng_xtouch_source_enable ),
//         .mmio_eng_xtouch_dest_enable                 ( mmio_eng_xtouch_dest_enable ),
//         .mmio_eng_xtouch_wt4rsp_enable               ( mmio_eng_xtouch_wt4rsp_enable ),
//         .mmio_eng_xtouch_ageout_pg_size              ( mmio_eng_xtouch_ageout_pg_size[5:0] ),
//         .mmio_eng_immed_terminate_enable             ( mmio_eng_immed_terminate_enable ),
      .mmio_eng_rtry_backoff_timer_disable         ( mmio_eng_rtry_backoff_timer_disable ),
      .mmio_eng_memcpy2_format_enable              ( mmio_eng_memcpy2_format_enable ),

      .mmio_eng_capture_all_resp_code_enable       ( mmio_eng_capture_all_resp_code_enable ),

//         .mmio_eng_we_ld_type                         ( mmio_eng_we_ld_type[1:0] ),
//         .mmio_eng_we_st_type                         ( mmio_eng_we_st_type[3:0] ),
//         .mmio_eng_cpy_ld_type                        ( mmio_eng_cpy_ld_type[1:0] ),
//         .mmio_eng_cpy_st_type                        ( mmio_eng_cpy_st_type[1:0] ),
//         .mmio_eng_xtouch_type                        ( mmio_eng_xtouch_type[1:0] ),
//         .mmio_eng_xtouch_flag                        ( mmio_eng_xtouch_flag[4:0] ),
//         .mmio_eng_incr_ld_type                       ( mmio_eng_incr_ld_type[1:0] ),
//         .mmio_eng_incr_st_type                       ( mmio_eng_incr_st_type[1:0] ),
//         .mmio_eng_atomic_ld_type                     ( mmio_eng_atomic_ld_type[1:0] ),
//         .mmio_eng_atomic_cas_type                    ( mmio_eng_atomic_cas_type[1:0] ),
//         .mmio_eng_atomic_st_type                     ( mmio_eng_atomic_st_type[1:0] ),

      .mmio_eng_base_addr                          ( mmio_eng_base_addr[63:12] ),
      .mmio_eng_offset_mask                        ( mmio_eng_offset_mask[31:12] ),
      .mmio_eng_ld_size                            ( mmio_eng_ld_size[1:0] ),
      .mmio_eng_st_size                            ( mmio_eng_st_size[1:0] ),
      .mmio_eng_type_ld                            ( mmio_eng_type_ld ),
      .mmio_eng_type_st                            ( mmio_eng_type_st ),
      .mmio_eng_send_interrupt                     ( mmio_eng_send_interrupt ),
      .mmio_eng_send_wkhstthrd                     ( mmio_eng_send_wkhstthrd ),
      .mmio_eng_error_intrpt_enable                ( mmio_eng_error_intrpt_enable ),
      .mmio_eng_wkhstthrd_intrpt_enable            ( mmio_eng_wkhstthrd_intrpt_enable ),
      .mmio_eng_wkhstthrd_tid                      ( mmio_eng_wkhstthrd_tid[15:0] ),
      .mmio_eng_wkhstthrd_flag                     ( mmio_eng_wkhstthrd_flag ),
      .mmio_eng_extra_write_mode                   ( mmio_eng_extra_write_mode ),
      .mmio_eng_obj_handle                         ( mmio_eng_obj_handle[63:0] ),
      .mmio_eng_xtouch_pg_n                        ( mmio_eng_xtouch_pg_n[1:0] ),
      .mmio_eng_xtouch_pg_size                     ( mmio_eng_xtouch_pg_size[5:0] ),
      .mmio_eng_xtouch_type                        ( mmio_eng_xtouch_type ),
      .mmio_eng_xtouch_hwt                         ( mmio_eng_xtouch_hwt ),
      .mmio_eng_xtouch_wt4rsp_enable               ( mmio_eng_xtouch_wt4rsp_enable ),
      .mmio_eng_xtouch_enable                      ( mmio_eng_xtouch_enable ),
      .mmio_eng_enable                             ( mmio_eng_enable ),
      .mmio_eng_resend_retries                     ( mmio_eng_resend_retries ),
      .mmio_eng_mmio_lat_mode                      ( mmio_eng_mmio_lat_mode ),
      .mmio_eng_mmio_lat_mode_sz_512_st            ( mmio_eng_mmio_lat_mode_sz_512_st ),
      .mmio_eng_mmio_lat_mode_sz_512_ld            ( mmio_eng_mmio_lat_mode_sz_512_ld ),
      .mmio_eng_mmio_lat_use_reg_data              ( mmio_eng_mmio_lat_use_reg_data ),
      .mmio_eng_mmio_lat_extra_read                ( mmio_eng_mmio_lat_extra_read ),
      .mmio_eng_mmio_lat_ld_ea                     ( mmio_eng_mmio_lat_ld_ea[63:7] ),
      .mmio_eng_mmio_lat_data0                     ( mmio_eng_mmio_lat_data0[1023:0] ),
      .mmio_eng_mmio_lat_data1                     ( mmio_eng_mmio_lat_data1[1023:0] ),
      .mmio_eng_mmio_lat_data2                     ( mmio_eng_mmio_lat_data2[1023:0] ),
      .mmio_eng_mmio_lat_data3                     ( mmio_eng_mmio_lat_data3[1023:0] ),
      .eng_mmio_extra_read_resp                    ( eng_mmio_extra_read_resp[3:0] ),
      .eng_mmio_data                               ( eng_mmio_data[1023:0] ),

//         .weq_eng_display_rdval                       ( weq_eng_display_rdval ),
      .mmio_eng_display_rdval                      ( mmio_eng_display_rdval ),
      .mmio_eng_display_ary_select                 ( mmio_eng_display_ary_select[1:0] ),
      .mmio_eng_display_addr                       ( mmio_eng_display_addr[9:0] ),
      .eng_mmio_display_rddata_valid               ( eng_mmio_display_rddata_valid ),

      .eng_perf_wkhstthrd_good                     ( eng_perf_wkhstthrd_good ),

      .unexpected_xlate_or_intrpt_done_200         ( unexpected_xlate_or_intrpt_done_200 ),

      .sim_idle_eng                                ( sim_idle_eng )

    );              


  // -- ********************************************************************************************************************************
  // -- Trace Array
  // -- ********************************************************************************************************************************

   mcp3_trace  trace
    (
      // -- Clocks & Reset
      .clock_afu                                   ( clock_afu ),                                    
      .clock_tlx                                   ( clock_tlx ),
      .reset                                       ( reset_trace ),                                   

      .unexpected_xlate_or_intrpt_done_200         ( unexpected_xlate_or_intrpt_done_200 ),

    // -- Trace array current write address pointers
      .trace_rspi_wraddr_reset                     ( trace_rspi_wraddr_reset ),              
      .trace_rspi_wraddr                           ( trace_rspi_wraddr[10:0] ),
      .trace_cmdo_wraddr_reset                     ( trace_cmdo_wraddr_reset ),            
      .trace_cmdo_wraddr                           ( trace_cmdo_wraddr[10:0] ),
      .trace_cmdi_rspo_wraddr_reset                ( trace_cmdi_rspo_wraddr_reset ),
      .trace_cmdi_rspo_wraddr                      ( trace_cmdi_rspo_wraddr[10:0] ),

    // -- Trace array trigger enables for rspi interface
      .trace_tlx_afu_resp_data_valid_en            ( trace_tlx_afu_resp_data_valid_en ),     
      .trace_afu_tlx_resp_rd_req_en                ( trace_afu_tlx_resp_rd_req_en ),        
      .trace_afu_tlx_resp_credit_en                ( trace_afu_tlx_resp_credit_en ),         
      .trace_tlx_afu_resp_valid_retry_en           ( trace_tlx_afu_resp_valid_retry_en ),    
      .trace_tlx_afu_resp_valid_no_data_en         ( trace_tlx_afu_resp_valid_no_data_en ),  
      .trace_tlx_afu_resp_valid_with_data_en       ( trace_tlx_afu_resp_valid_with_data_en ),

    // -- Trace array trigger enables for cmdo interface
      .trace_tlx_afu_cmd_data_credit_en            ( trace_tlx_afu_cmd_data_credit_en ),
      .trace_tlx_afu_cmd_credit_en                 ( trace_tlx_afu_cmd_credit_en ),     
      .trace_afu_tlx_cdata_valid_en                ( trace_afu_tlx_cdata_valid_en ),    
      .trace_afu_tlx_cmd_valid_en                  ( trace_afu_tlx_cmd_valid_en ),      

    // -- Trace array trigger enables for cmdi_rspo interface
      .trace_tlx_afu_resp_data_credit_en           ( trace_tlx_afu_resp_data_credit_en ),
      .trace_tlx_afu_resp_credit_en                ( trace_tlx_afu_resp_credit_en ),     
      .trace_afu_tlx_rdata_valid_en                ( trace_afu_tlx_rdata_valid_en ),     
      .trace_afu_tlx_resp_valid_en                 ( trace_afu_tlx_resp_valid_en ),      

      .trace_afu_tlx_cmd_credit_en                 ( trace_afu_tlx_cmd_credit_en ),    
      .trace_afu_tlx_cmd_rd_req_en                 ( trace_afu_tlx_cmd_rd_req_en ),    
      .trace_tlx_afu_cmd_data_valid_en             ( trace_tlx_afu_cmd_data_valid_en ),
      .trace_tlx_afu_cmd_valid_en                  ( trace_tlx_afu_cmd_valid_en ),     

    // -- Trace array controls
      .trace_no_wrap                               ( trace_no_wrap ),
      .trace_eng_en                                ( trace_eng_en ), 
      .trace_eng_num                               ( trace_eng_num[4:0] ), 
      .trace_events                                ( trace_events ), 
      .trace_arm                                   ( trace_arm ),    


      // -- TLX_AFU Command Receive Bus Trace inputs   (MMIO requests)
//--  .trace_tlx_afu_ready                         ( trace_tlx_afu_ready ),                          

      .trace_tlx_afu_cmd_valid                     ( trace_tlx_afu_cmd_valid ),                      
      .trace_tlx_afu_cmd_opcode                    ( trace_tlx_afu_cmd_opcode[7:0] ),                
      .trace_tlx_afu_cmd_capptag                   ( trace_tlx_afu_cmd_capptag[15:0] ),              
// -- .trace_tlx_afu_cmd_dl                        ( trace_tlx_afu_cmd_dl[1:0] ),                    
      .trace_tlx_afu_cmd_pl                        ( trace_tlx_afu_cmd_pl[2:0] ),                    
// -- .trace_tlx_afu_cmd_be                        ( trace_tlx_afu_cmd_be[63:0] ),                   
// -- .trace_tlx_afu_cmd_end                       ( trace_tlx_afu_cmd_end ),                        
// -- .trace_tlx_afu_cmd_t                         ( trace_tlx_afu_cmd_t ),                          
      .trace_tlx_afu_cmd_pa                        ( trace_tlx_afu_cmd_pa[25:0] ),                   
// -- .trace_tlx_afu_cmd_flag                      ( trace_tlx_afu_cmd_flag[3:0] ),                  
// -- .trace_tlx_afu_cmd_os                        ( trace_tlx_afu_cmd_os ),                         

      .trace_tlx_afu_cmd_data_valid                ( trace_tlx_afu_cmd_data_valid ),                 
      .trace_tlx_afu_cmd_data_bdi                  ( trace_tlx_afu_cmd_data_bdi ),                   
      .trace_tlx_afu_cmd_data_bus                  ( trace_tlx_afu_cmd_data_bus[63:0] ),             

      .trace_afu_tlx_cmd_rd_req                    ( trace_afu_tlx_cmd_rd_req ),                     
// -- .trace_afu_tlx_cmd_rd_cnt                    ( trace_afu_tlx_cmd_rd_cnt[2:0] ),                

      .trace_afu_tlx_cmd_credit                    ( trace_afu_tlx_cmd_credit ),                     

      .trace_tlx_afu_mmio_rd_cmd_valid             ( trace_tlx_afu_mmio_rd_cmd_valid ),
      .trace_tlx_afu_mmio_wr_cmd_valid             ( trace_tlx_afu_mmio_wr_cmd_valid ),


      // -- AFU_TLX Response Transmit Bus Trace inputs   (MMIO responses)
      .trace_afu_tlx_resp_valid                    ( trace_afu_tlx_resp_valid ),                     
      .trace_afu_tlx_resp_opcode                   ( trace_afu_tlx_resp_opcode[3:0] ),               
      .trace_afu_tlx_resp_dl                       ( trace_afu_tlx_resp_dl[1:0] ),                   
      .trace_afu_tlx_resp_capptag                  ( trace_afu_tlx_resp_capptag[15:0] ),             
// -- .trace_afu_tlx_resp_dp                       ( trace_afu_tlx_resp_dp[1:0] ),                   
      .trace_afu_tlx_resp_code                     ( trace_afu_tlx_resp_code[3:0] ),                 

      .trace_afu_tlx_rdata_valid                   ( trace_afu_tlx_rdata_valid ),                    
// -- .trace_afu_tlx_rdata_bdi                     ( trace_afu_tlx_rdata_bdi ),                      
// -- .trace_afu_tlx_rdata_bus                     ( trace_afu_tlx_rdata_bus[63:0] ),                

      .trace_tlx_afu_resp_credit                   ( trace_tlx_afu_resp_credit ),                    
      .trace_tlx_afu_resp_data_credit              ( trace_tlx_afu_resp_data_credit ),               

      .trace_rspo_avail_resp_credit                ( trace_rspo_avail_resp_credit[3:0] ),            
      .trace_rspo_avail_resp_data_credit           ( trace_rspo_avail_data_credit[5:0] ),            


      // -- AFU_TLX Command Transmit Bus Trace inputs
      .trace_afu_tlx_cmd_valid                     ( trace_afu_tlx_cmd_valid ),                      
      .trace_afu_tlx_cmd_opcode                    ( trace_afu_tlx_cmd_opcode[7:0] ),                
      .trace_afu_tlx_cmd_actag                     ( trace_afu_tlx_cmd_actag[5:0] ),                 
// -- .trace_afu_tlx_cmd_stream_id                 ( trace_afu_tlx_cmd_stream_id[3:0] ),             
      .trace_afu_tlx_cmd_ea_or_obj                 ( trace_afu_tlx_cmd_ea_or_obj[67:0] ),            
      .trace_afu_tlx_cmd_afutag                    ( trace_afu_tlx_cmd_afutag[15:0] ),               
      .trace_afu_tlx_cmd_dl                        ( trace_afu_tlx_cmd_dl[1:0] ),                    
      .trace_afu_tlx_cmd_pl                        ( trace_afu_tlx_cmd_pl[2:0] ),                    
// -- .trace_afu_tlx_cmd_os                        ( trace_afu_tlx_cmd_os ),                         
// -- .trace_afu_tlx_cmd_be                        ( trace_afu_tlx_cmd_be[63:0] ),                   
      .trace_afu_tlx_cmd_flag                      ( trace_afu_tlx_cmd_flag[3:0] ),                  
// -- .trace_afu_tlx_cmd_endian                    ( trace_afu_tlx_cmd_endian ),                     
// -- .trace_afu_tlx_cmd_bdf                       ( trace_afu_tlx_cmd_bdf[15:0] ),                  
      .trace_afu_tlx_cmd_pasid                     ( trace_afu_tlx_cmd_pasid[9:0] ),                 
      .trace_afu_tlx_cmd_pg_size                   ( trace_afu_tlx_cmd_pg_size[5:0] ),               

      .trace_afu_tlx_cdata_valid                   ( trace_afu_tlx_cdata_valid ),                    
// -- .trace_afu_tlx_cdata_bdi                     ( trace_afu_tlx_cdata_bdi ),                      
// -- .trace_afu_tlx_cdata_bus                     ( trace_afu_tlx_cdata_bus[1023:0] ),              

      .trace_tlx_afu_cmd_credit                    ( trace_tlx_afu_cmd_credit[1:0] ),                
      .trace_tlx_afu_cmd_data_credit               ( trace_tlx_afu_cmd_data_credit[1:0] ),           

      .trace_cmdo_avail_cmd_credit                 ( trace_cmdo_avail_cmd_credit[4:0] ),             
      .trace_cmdo_avail_cmd_data_credit            ( trace_cmdo_avail_cmd_data_credit[6:0] ),            

      // -- TLX_AFU Response Receive Bus Trace inputs
      .trace_tlx_afu_resp_valid_with_data          ( trace_tlx_afu_resp_valid_with_data ),           
      .trace_tlx_afu_resp_valid_no_data            ( trace_tlx_afu_resp_valid_no_data ),             
      .trace_tlx_afu_resp_valid_retry              ( trace_tlx_afu_resp_valid_retry ),               
      .trace_tlx_afu_resp_afutag                   ( trace_tlx_afu_resp_afutag[15:0] ),              
      .trace_tlx_afu_resp_opcode                   ( trace_tlx_afu_resp_opcode[7:0] ),               
      .trace_tlx_afu_resp_code                     ( trace_tlx_afu_resp_code[3:0] ),                 
      .trace_tlx_afu_resp_dl                       ( trace_tlx_afu_resp_dl[1:0] ),                   
      .trace_tlx_afu_resp_dp                       ( trace_tlx_afu_resp_dp[1:0] ),                   
// -- .trace_tlx_afu_resp_pg_size                  ( trace_tlx_afu_resp_pg_size[5:0] ),              
// -- .trace_tlx_afu_resp_addr_tag                 ( trace_tlx_afu_resp_addr_tag[17:0] ),            

      .trace_afu_tlx_resp_rd_req                   ( trace_afu_tlx_resp_rd_req ),                    
      .trace_afu_tlx_resp_rd_cnt                   ( trace_afu_tlx_resp_rd_cnt[2:0] ),               

      .trace_tlx_afu_resp_data_valid               ( trace_tlx_afu_resp_data_valid ),                
      .trace_tlx_afu_resp_data_bdi                 ( trace_tlx_afu_resp_data_bdi[1:0] ),             
// -- .trace_tlx_afu_resp_data_bus                 ( trace_tlx_afu_resp_data_bus[511:0] ),           

      .trace_afu_tlx_resp_credit                   ( trace_afu_tlx_resp_credit ),                    

    // -- Display Read Interface - trace
      .mmio_trace_display_rdval                    ( mmio_trace_display_rdval ),                
      .mmio_trace_display_addr                     ( mmio_trace_display_addr[8:0] ),
      .mmio_trace_display_offset                   ( mmio_trace_display_offset[3:0] ),
                                                                                    
      .trace_mmio_display_rddata_valid             ( trace_mmio_display_rddata_valid ),          
      .trace_mmio_display_rddata                   ( trace_mmio_display_rddata[63:0] )

    );              



   afp3_perfmon  afp3_perfmon
    (
      // -- Clocks & Reset
      .clock_afu                                   ( clock_afu ),                                    
      .reset                                       ( mmio_perf_reset ),                                   
      .mmio_perf_rdval                             ( mmio_perf_rdval ),
      .mmio_perf_rdlatency                         ( mmio_perf_rdlatency ),
      .mmio_perf_rdaddr                            ( mmio_perf_rdaddr[3:0] ),
      .perf_mmio_rddata                            ( perf_mmio_rddata[63:0] ),                 //output
      .perf_mmio_rddata_valid                      ( perf_mmio_rddata_valid ),                 //output
      .arb_perf_latency_update                     ( arb_perf_latency_update ),
      .arb_perf_no_credits                         ( arb_perf_no_credits ),
      .eng_perf_wkhstthrd_good                     ( eng_perf_wkhstthrd_good ),
      .trace_tlx_afu_resp_valid_with_data          ( trace_tlx_afu_resp_valid_with_data ),
      .trace_tlx_afu_resp_valid_no_data            ( trace_tlx_afu_resp_valid_no_data ),
      .trace_tlx_afu_resp_afutag                   ( trace_tlx_afu_resp_afutag[15:0] ),
      .trace_tlx_afu_resp_opcode                   ( trace_tlx_afu_resp_opcode[7:0] ),
      .trace_tlx_afu_resp_dl                       ( trace_tlx_afu_resp_dl[1:0] )
    );


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  // -- latches
  always @ ( posedge clock_afu )
    begin

      reset_q                                     <= reset_d;

    end // -- always @ *



endmodule
