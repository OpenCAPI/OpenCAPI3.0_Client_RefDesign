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

module afp3_mmio
  (
    input                 clock_tlx                                           
  , input                 clock_afu                                           
  , input                 reset                                           

  , input          [11:0] cfg_afu_actag_length_enabled

  , input           [4:0] cfg_afu_pasid_length_enabled
  , input          [19:0] cfg_afu_pasid_base
  , output         [19:0] mmio_cmdo_pasid_mask

  , input                 cmdi_mmio_rd                                    
  , input                 cmdi_mmio_wr                                    
  , input                 cmdi_mmio_large_rd
  , input                 cmdi_mmio_large_wr
  , input           [1:0] cmdi_mmio_large_wr_half_en     // -- If bit 0 is set, write [511:0]; if bit 1 is set, write [1023:0];  if both are set, write[1023:0]
  , input          [25:0] cmdi_mmio_addr                                  
  , input        [1023:0] cmdi_mmio_wrdata                                

  , input                 cmdi_mmio_early_wr                                    
  , input                 cmdi_mmio_early_large_wr
  , input           [1:0] cmdi_mmio_early_large_wr_half_en     // -- If bit 0 is set, write [511:0]; if bit 1 is set, write [1023:0];  if both are set, write[1023:0]
  , input          [25:0] cmdi_mmio_early_addr                                  

  , output                mmio_rspo_wr_done                               
  , output                mmio_rspo_rddata_valid                          
  , output       [1023:0] mmio_rspo_rddata                                
  , output                mmio_rspo_bad_op_or_align                       
  , output                mmio_rspo_addr_not_implemented                  

  , output                afu_tlx_fatal_error

  , output                mmio_weq_memcpy2_format_enable
  , output          [4:0] mmio_weq_term_reset_extend_en
  , output                mmio_weq_eng_wr_blk_mmio_rd_pe_ary_disable

  , output                mmio_weq_wr_wed                                 
  , output                mmio_weq_rd_wed                                 
  , output                mmio_weq_rd_process_status                      
  , output                mmio_weq_wr_intrpt_ctl                                 
  , output                mmio_weq_rd_intrpt_ctl                                 
  , output                mmio_weq_wr_intrpt_obj                                 
  , output                mmio_weq_rd_intrpt_obj                                 
  , output                mmio_weq_wr_intrpt_data                                 
  , output                mmio_weq_rd_intrpt_data                                 
  , output         [19:0] mmio_weq_pasid                                  
  , output         [63:0] mmio_weq_wrdata                                 

  , input                 weq_mmio_wr_wed_done                            
  , input                 weq_mmio_rd_wed_valid                           
  , input                 weq_mmio_rd_process_status_valid                  
  , input                 weq_mmio_wr_intrpt_ctl_done                            
  , input                 weq_mmio_rd_intrpt_ctl_valid                           
  , input                 weq_mmio_wr_intrpt_obj_done                            
  , input                 weq_mmio_rd_intrpt_obj_valid                           
  , input                 weq_mmio_wr_intrpt_data_done                            
  , input                 weq_mmio_rd_intrpt_data_valid                           
  , input          [63:0] weq_mmio_rddata                                 

  , input                 cfg_afu_terminate_valid                     
  , input          [19:0] cfg_afu_terminate_pasid        // -- bits 19:10 not used                       
  , output                afu_cfg_terminate_in_progress

  , output                mmio_weq_restart_process                                                   
  , input                 weq_mmio_restart_process_done                                              
  , input                 weq_mmio_restart_process_error                                             

//     , output                mmio_weq_terminate_process
//     , output         [19:0] mmio_weq_terminate_pasid                                                 
  , input                 weq_mmio_terminate_process_done                                             

  , output                mmio_perf_reset
  , output                mmio_perf_snapshot
  , output                mmio_perf_rdval
  , output                mmio_perf_rdlatency
  , output          [3:0] mmio_perf_rdaddr
  , input                 perf_mmio_rddata_valid
  , input          [63:0] perf_mmio_rddata

  , output                mmio_eng_intrpt_on_cpy_err_en                                              
  , output                mmio_eng_stop_on_invalid_cmd                                               
  , output                mmio_eng_256B_op_disable                                                   
  , output                mmio_eng_128B_op_disable
  , output                mmio_eng_immed_terminate_enable                                           
  , output                mmio_eng_xtouch_source_enable                                             
  , output                mmio_eng_xtouch_dest_enable
//     , output                mmio_eng_xtouch_wt4rsp_enable                                             
  , output          [5:0] mmio_eng_xtouch_ageout_pg_size
  , output                mmio_eng_use_pasid_for_actag
  , output                mmio_eng_hold_pasid_for_debug
  , output                mmio_eng_rtry_backoff_timer_disable                                           
  , output                mmio_eng_memcpy2_format_enable

  , output          [1:0] mmio_eng_we_ld_type
  , output          [3:0] mmio_eng_we_st_type
  , output          [1:0] mmio_eng_cpy_ld_type
  , output          [1:0] mmio_eng_cpy_st_type                                            
  , output          [1:0] mmio_eng_incr_ld_type
  , output          [1:0] mmio_eng_incr_st_type
  , output          [1:0] mmio_eng_atomic_ld_type
  , output          [1:0] mmio_eng_atomic_cas_type
  , output          [1:0] mmio_eng_atomic_st_type
//     , output          [1:0] mmio_eng_xtouch_type                                            
//     , output          [4:0] mmio_eng_xtouch_flag                                            

  , output                mmio_eng_capture_all_resp_code_enable
                                                                                      
  , output        [63:12] mmio_eng_base_addr
  , output          [1:0] mmio_eng_ld_size
  , output                mmio_eng_type_ld
  , output          [1:0] mmio_eng_st_size
  , output                mmio_eng_type_st
  , output        [31:12] mmio_eng_offset_mask
  , output          [9:0] mmio_eng_pasid
  , output                mmio_eng_send_interrupt
  , output                mmio_eng_send_wkhstthrd
  , output                mmio_eng_error_intrpt_enable
  , output                mmio_eng_wkhstthrd_intrpt_enable
  , output         [15:0] mmio_eng_wkhstthrd_tid
  , output                mmio_eng_wkhstthrd_flag
  , output                mmio_eng_extra_write_mode
  , output         [63:0] mmio_eng_obj_handle
  , output          [1:0] mmio_eng_xtouch_pg_n
  , output          [5:0] mmio_eng_xtouch_pg_size
  , output                mmio_eng_xtouch_type
  , output                mmio_eng_xtouch_hwt
  , output                mmio_eng_xtouch_wt4rsp_enable
  , output                mmio_eng_xtouch_enable
  , output                mmio_eng_enable
  , output                mmio_eng_resend_retries
  , output                mmio_eng_mmio_lat_mode
  , output                mmio_eng_mmio_lat_mode_sz_512_st
  , output                mmio_eng_mmio_lat_mode_sz_512_ld
  , output                mmio_eng_mmio_lat_use_reg_data
  , output                mmio_eng_mmio_lat_extra_read
  , output         [63:7] mmio_eng_mmio_lat_ld_ea
  , output       [1023:0] mmio_eng_mmio_lat_data0
  , output       [1023:0] mmio_eng_mmio_lat_data1
  , output       [1023:0] mmio_eng_mmio_lat_data2
  , output       [1023:0] mmio_eng_mmio_lat_data3
  , input           [3:0] eng_mmio_extra_read_resp
  , input        [1023:0] eng_mmio_data

  , output          [2:0] mmio_arb_num_ld_tags
  , output          [1:0] mmio_arb_ld_size
  , output                mmio_arb_type_ld
  , output          [2:0] mmio_arb_num_st_tags
  , output          [1:0] mmio_arb_st_size
  , output                mmio_arb_type_st

  , output          [1:0] mmio_arb_ldst_priority_mode                                                

  , output                mmio_arb_xtouch_wt4rsp_enable
  , output                mmio_arb_xtouch_enable

  , output                mmio_arb_mmio_lat_mode
  , output                mmio_arb_mmio_lat_mode_sz_512_st
  , output                mmio_arb_mmio_lat_mode_sz_512_ld
  , output                mmio_arb_mmio_lat_extra_read
  , output                mmio_arb_mmio_access

  , output                mmio_arb_fastpath_disable

  , output                mmio_cmdo_split_128B_cmds                                                  

  , output                mmio_rspi_fastpath_queue_bypass_disable                                             
  , output                mmio_rspi_fastpath_stg0_bypass_disable                                             
  , output                mmio_rspi_fastpath_stg1_bypass_disable                                             
  , output                mmio_rspi_fastpath_stg2_bypass_disable                                             
  , output                mmio_rspi_normal_stg1_bypass_disable                                             
  , output                mmio_rspi_normal_stg2_bypass_disable

  , output                mmio_rspi_fastpath_blocker_disable      

  , input           [7:0] rspi_mmio_resp_queue_maxqdepth                                             
  , output                mmio_rspi_resp_queue_maxqdepth_reset                                             

  , input          [11:0] rspi_mmio_max_outstanding_responses
  , output                mmio_rspi_max_outstanding_responses_reset

  , output                mmio_weq_eng_disable_updated
  , output         [31:0] mmio_weq_eng_disable
  , output                mmio_weq_use_pasid_for_actag

  , output                trace_rspi_wraddr_reset
  , input          [10:0] trace_rspi_wraddr
  , output                trace_cmdo_wraddr_reset
  , input          [10:0] trace_cmdo_wraddr
  , output                trace_cmdi_rspo_wraddr_reset
  , input          [10:0] trace_cmdi_rspo_wraddr

  // -- Trace array trigger enables for rspi interface
  , output                trace_tlx_afu_resp_data_valid_en
  , output                trace_afu_tlx_resp_rd_req_en
  , output                trace_afu_tlx_resp_credit_en             
  , output                trace_tlx_afu_resp_valid_retry_en          
  , output                trace_tlx_afu_resp_valid_no_data_en
  , output                trace_tlx_afu_resp_valid_with_data_en

  // -- Trace array trigger enables for cmdo interface
  , output                trace_tlx_afu_cmd_data_credit_en
  , output                trace_tlx_afu_cmd_credit_en
  , output                trace_afu_tlx_cdata_valid_en       
  , output                trace_afu_tlx_cmd_valid_en          

  // -- Trace array trigger enables for cmdi_rspo interface
  , output                trace_tlx_afu_resp_data_credit_en
  , output                trace_tlx_afu_resp_credit_en
  , output                trace_afu_tlx_rdata_valid_en
  , output                trace_afu_tlx_resp_valid_en

  , output                trace_afu_tlx_cmd_credit_en
  , output                trace_afu_tlx_cmd_rd_req_en
  , output                trace_tlx_afu_cmd_data_valid_en
  , output                trace_tlx_afu_cmd_valid_en

  // -- Trace array controls
  , output                trace_no_wrap      // -- Set to b'1 to prevent trace array from wrapping and overwriting existing trace data
  , output                trace_eng_en       // -- Set to b'1 to trace a specific engine
  , output          [4:0] trace_eng_num      // -- When trace_eng_en = b'1, set trace_eng_num[4:0] to the engine to trace
  , output                trace_events       // -- Set to b'1 to trace events enabled by the trigger enables, 0'b traces every cycle
  , output                trace_arm          // -- Set to b'1 to arm the trace array

  // -- Display Read Interface to Trace module
  , output                mmio_trace_display_rdval     // -- This is a pulse (sel, addr, and offset are static)
  , output          [8:0] mmio_trace_display_addr      // -- This picks a row in all arrays
  , output          [3:0] mmio_trace_display_offset    // -- This picks a data register (64 bits from one of the arrays)

  , input                 trace_mmio_display_rddata_valid
  , input          [63:0] trace_mmio_display_rddata

  // -- Display Read Interface to Response Queue
  , output                mmio_rspi_display_rdval      // -- This is a pulse (sel, addr, and offset are static)
  , output          [6:0] mmio_rspi_display_addr       // -- This picks a row of 128 entries in the response queue

  , input                 rspi_mmio_display_rddata_valid
  , input          [63:0] rspi_mmio_display_rddata

  // -- Display Read Interface to WEQ and Copy Engine modules
  , output                mmio_weq_display_rdval       // -- This is a pulse (sel, addr, and offset are static)
  , output                mmio_weq_display_mod_select  // -- This will pick either eng when b'0 or weq when b'1
  , output          [1:0] mmio_weq_display_ary_select  // -- In Engine, this will select dbuf when b'0, rtry_queue when b'1
  , output          [4:0] mmio_weq_display_eng_select  // -- Selects Engine
  , output          [4:0] mmio_weq_display_addr        // -- Select row/entry of array
  , output          [3:0] mmio_weq_display_offset      // -- This picks a data register (64 bits from one of the arrays)
  , output          [3:0] mmio_cmdo_display_offset     // -- This picks a data register (64 bits from one of the arrays)

  , input                 weq_mmio_display_rddata_valid
  , input          [63:0] weq_mmio_display_rddata

  , input                 eng_mmio_display_rddata_valid
  , input          [63:0] cmdo_mmio_display_rddata     // -- Engine display data will come from cmdo

  , input                 sim_idle_cmdi_rspo
  , input                 sim_idle_weq
  , input                 sim_idle_arb
  , input                 sim_idle_cmdo
  , input                 sim_idle_rspi
  , input                 sim_idle_eng

  // -- Simulation Idle
  , output                sim_idle_mmio                                                              

  );


  // --****************************************************************************
  // -- Signal declarations
  // --****************************************************************************

  // --  Mode bits
  wire            terminate_process_via_mmio_en;
  wire            mmio_eng_force_use_eng_num_for_actag;                                                                                           

  // -- Illegal conditions  
  wire            bad_wr_align;                                                                                                            
  wire            bad_large_wr_align;                                                                                                            
  wire            bad_op;                                                                                                                  
  wire            bad_op_or_align;                                                                                                         
  wire            addr_not_implemented;                                                                                                    

  // -- Qualified Rd/Wr Valids
  wire            mmio_rd_valid;                                                                                                           
  wire            mmio_wr_valid;                                                                                                           

  wire            mmio_large_rd_valid;
  wire            mmio_large_wr_valid;

  // -- Address Decode
  wire            addr_is_privileged;                                                                                                      
  wire            addr_is_per_process;                                                                                                     
  wire            addr_is_large_reg;

  wire            early_addr_is_privileged;
  wire            early_addr_is_large_reg;

  wire            addr_is_afu_config;                                                                                                      
  wire            addr_is_afu_config2;                                                                                                      
  wire            addr_is_afu_error;                                                                                                       
  wire            addr_is_afu_error_info;                                                                                                  
  wire            addr_is_afu_trace_ctl;                                                                                                   
  wire            addr_is_afu_stats;                                                                                                   

  wire            addr_is_afu_obj_handle;
  wire            addr_is_afu_extra_ea;
  wire            addr_is_afu_wed;
  wire            addr_is_afu_bufmask;
  wire            addr_is_afu_pasid;
  wire            addr_is_afu_misc;
  wire            addr_is_afu_enable;
  wire            addr_is_afu_control;
  wire            addr_is_afu_latency;

  wire            addr_is_afu_display_ctl;
  wire            addr_is_afu_display_data0;
  wire            addr_is_afu_display_data1;
  wire            addr_is_afu_display_data2;
  wire            addr_is_afu_display_data3;
  wire            addr_is_afu_display_data4;
  wire            addr_is_afu_display_data5;
  wire            addr_is_afu_display_data6;
  wire            addr_is_afu_display_data7;
  wire            addr_is_afu_perf_count0;
  wire            addr_is_afu_perf_count1;
  wire            addr_is_afu_perf_count2;
  wire            addr_is_afu_perf_count3;
  wire            addr_is_afu_perf_count4;
  wire            addr_is_afu_perf_count5;
  wire            addr_is_afu_perf_count6;
  wire            addr_is_afu_perf_count7;
  wire            addr_is_afu_perf_count8;
  wire            addr_is_afu_perf_count9;

  wire            addr_is_large_ping_pong_data0;
  wire            addr_is_large_ping_pong_data1;
  wire            addr_is_large_ping_pong_data2;
  wire            addr_is_large_ping_pong_data3;

  wire            rd_afu_config;
  wire            rd_afu_config2;
  wire            rd_afu_error;
  wire            rd_afu_error_info;
  wire            rd_afu_trace_ctl;
  wire            rd_afu_stats;
  wire            rd_afu_obj_handle;
  wire            rd_afu_extra_ea;
  wire            rd_afu_wed;
  wire            rd_afu_bufmask;
  wire            rd_afu_pasid;
  wire            rd_afu_misc;
  wire            rd_afu_enable;
  wire            rd_afu_control;
  wire            rd_afu_latency;
  wire            rd_afu_display_ctl;
  wire            rd_afu_display_data;
  wire            rd_afu_perf_count;
  wire            rd_large_ping_pong_data0;
  wire            rd_large_ping_pong_data1;
  wire            rd_large_ping_pong_data2;
  wire            rd_large_ping_pong_data3;

  wire            wr_afu_config;
  wire            wr_afu_config2;
  wire            wr_afu_error;
  wire            wr_afu_error_info;
  wire            wr_afu_trace_ctl;
  wire            wr_afu_stats;
  wire            wr_afu_obj_handle;
  wire            wr_afu_extra_ea;
  wire            wr_afu_wed;
  wire            wr_afu_bufmask;
  wire            wr_afu_pasid;
  wire            wr_afu_misc;
  wire            wr_afu_enable;
  wire            wr_afu_control;
  wire            wr_afu_latency;
  wire            wr_afu_display_ctl;
  wire            wr_afu_display_data;
  wire            wr_afu_perf_count;
  wire            wr_large_ping_pong_data0;
  wire            wr_large_ping_pong_data1;
  wire            wr_large_ping_pong_data2;
  wire            wr_large_ping_pong_data3;
  wire            addr_is_wed;
  wire            addr_is_process_handle;
  wire            addr_is_process_status;
  wire            addr_is_process_ctl;
  wire            addr_is_intrpt_ctl;
  wire            addr_is_intrpt_obj;
  wire            addr_is_intrpt_data;
        
  wire            rd_wed;
  wire            rd_process_handle;
  wire            rd_process_status;
  wire            rd_process_ctl;
  wire            rd_intrpt_ctl;
  wire            rd_intrpt_obj;
  wire            rd_intrpt_data;
         
  wire            wr_wed;
//wire            wr_process_handle;      // -- Read Only
//wire            wr_process_status;      // -- Read Only
  wire            wr_process_ctl;
  wire            wr_intrpt_ctl;
  wire            wr_intrpt_obj;
  wire            wr_intrpt_data;

  wire            wr_wed_done;
  wire            rd_wed_valid;
  wire            rd_process_status_valid;
  wire            wr_intrpt_ctl_done;
  wire            rd_intrpt_ctl_valid;
  wire            wr_intrpt_obj_done;
  wire            rd_intrpt_obj_valid;
  wire            wr_intrpt_data_done;
  wire            rd_intrpt_data_valid;

  wire      [7:0] scorecard_size;
  wire            clear_scorecard;
  wire            mmio_scorecard_complete;
  wire            mmio_access_enable_reg;
  wire            mmio_access_extra_ea;
  wire            mmio_access_misc;
  wire            mmio_access_large_data0;
  wire            mmio_access_large_data1;
  wire            mmio_access_large_data2;
  wire            mmio_access_large_data3;
  wire      [1:0] mmio_lat_trigger_src;
  wire            mmio_lat_mode_int;
  wire            mmio_lat_extra_read_int;

  wire            use_ld_resp_data;

  wire            rd_weq_valid;                                                                                                           

  // -- Read Data signals
  wire     [63:0] rddata_afu_config;                                                                                                       
  wire     [63:0] rddata_afu_config2;                                                                                                       
  wire     [63:0] rddata_afu_error;                                                                                                        
  wire     [63:0] rddata_afu_error_info;                                                                                                   
  wire     [63:0] rddata_afu_trace_ctl;                                                                                                    
  wire     [63:0] rddata_afu_stats;

  wire     [63:0] rddata_afu_obj_handle;
  wire     [63:0] rddata_afu_extra_ea;
  wire     [63:0] rddata_afu_wed;
  wire     [63:0] rddata_afu_bufmask;
  wire     [63:0] rddata_afu_pasid;
  wire     [63:0] rddata_afu_misc;
  wire     [63:0] rddata_afu_enable;
  wire     [63:0] rddata_afu_control;

  wire   [1023:0] rddata_large_ping_pong_data0;
  wire   [1023:0] rddata_large_ping_pong_data1;
  wire   [1023:0] rddata_large_ping_pong_data2;
  wire   [1023:0] rddata_large_ping_pong_data3;

  wire     [63:0] rddata_afu_display_ctl;                                                                                                  
  reg      [63:0] rddata_process_ctl;                                                                                                  
  reg      [63:0] rddata_process_handle;                                                                                                   
 
  wire            mmio_restart_process_done;                                                                                               
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            cfg_terminate_process_done;
  wire            cfg_terminate_pasid_match;
  wire            cfg_terminate_match_pending;
  wire            force_disable;

  // -- Terminate Queue / Arb signals
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            mmio_terminate_process;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            cfg_terminate_process;

//     wire    [511:0] mmio_terminate_pasid_decoded;
//     wire    [511:0] cfg_terminate_pasid_decoded;
//     reg     [511:0] set_nxt_terminate_req_mmio;
//     reg     [511:0] set_nxt_terminate_req_cfg;
//     wire    [511:0] set_nxt_terminate_req;
//     wire    [511:0] clr_nxt_terminate_req;

//     wire            nxt_terminate_req_taken;
//     wire            terminate_process_done;
//     wire            nxt_terminate_arb_reset;
//     wire            nxt_terminate_arb_winner_valid;
//     wire      [8:0] nxt_terminate_arb_winner_encoded;
//     wire    [511:0] nxt_terminate_arb_winner_decoded;  // -- valid only when nxt_terminate_req_taken asserted

  // -- Array Display signals
  wire            rd_afu_display_data_valid;

  wire            rd_afu_perf_count_valid;

  wire            afu_display_mod_is_trace;
  wire            afu_display_mod_is_rspi;
  wire            afu_display_mod_is_weq;
  wire            afu_display_mod_is_eng;

  wire            afu_display_eng_ary_is_dbuf;
  wire            afu_display_eng_ary_is_rtry_queue;
  wire            afu_display_eng_ary_is_latches;

  wire      [8:0] autoincr_sel;

  wire            autoincr_trigger_match;

  wire            autoincr_trigger_trace;
  wire            autoincr_trigger_rspi;
  wire            autoincr_trigger_weq;
  wire            autoincr_trigger_eng;

  wire            autoincr_last_addr_trace;
  wire            autoincr_last_addr_rspi;
  wire            autoincr_last_addr_weq;
  wire            autoincr_last_addr_eng;

  wire            autoincr_last_eng;

  wire            autoincr_update_afu_display_ctl;
  reg      [31:0] autoincr_nxt_afu_display_ctl;

                                                                                       
  // -- Misc
  wire     [19:0] process_handle;

  reg      [19:0] cfg_afu_pasid_length;

  wire            mmio_weq_eng_disable_updated_int;

  wire            sim_idle_mmio_int;


  // --****************************************************************************
  // -- Latch Signal declarations
  // --****************************************************************************

  // -- Even/Odd latches
  wire            toggle_d;                      // -- AFU clock domain
  reg             toggle_q;
  wire            sample_d;                      // -- TLX clock domain
  reg             sample_q;
  wire            odd_d;                         // -- TLX clock domain
  reg             odd_q;
  wire            even_d;
  reg             even_q;

  // -- AFU clock domain latches
  reg      [19:0] cfg_afu_pasid_mask_d;
  reg      [19:0] cfg_afu_pasid_mask_q;

  wire            mmio_weq_rd_wed_d;
  reg             mmio_weq_rd_wed_q;
  wire            mmio_weq_wr_wed_d;
  reg             mmio_weq_wr_wed_q;
  wire            mmio_weq_rd_process_status_d;
  reg             mmio_weq_rd_process_status_q;
  wire            mmio_weq_rd_intrpt_ctl_d;
  reg             mmio_weq_rd_intrpt_ctl_q;
  wire            mmio_weq_wr_intrpt_ctl_d;
  reg             mmio_weq_wr_intrpt_ctl_q;
  wire            mmio_weq_rd_intrpt_obj_d;
  reg             mmio_weq_rd_intrpt_obj_q;
  wire            mmio_weq_wr_intrpt_obj_d;
  reg             mmio_weq_wr_intrpt_obj_q;
  wire            mmio_weq_rd_intrpt_data_d;
  reg             mmio_weq_rd_intrpt_data_q;
  wire            mmio_weq_wr_intrpt_data_d;
  reg             mmio_weq_wr_intrpt_data_q;

  wire            weq_mmio_wr_wed_done_d;
  reg             weq_mmio_wr_wed_done_q;
  wire            weq_mmio_rd_wed_valid_d;
  reg             weq_mmio_rd_wed_valid_q;
  wire            weq_mmio_rd_process_status_valid_d;
  reg             weq_mmio_rd_process_status_valid_q;
  wire            weq_mmio_wr_intrpt_ctl_done_d;
  reg             weq_mmio_wr_intrpt_ctl_done_q;
  wire            weq_mmio_rd_intrpt_ctl_valid_d;
  reg             weq_mmio_rd_intrpt_ctl_valid_q;
  wire            weq_mmio_wr_intrpt_obj_done_d;
  reg             weq_mmio_wr_intrpt_obj_done_q;
  wire            weq_mmio_rd_intrpt_obj_valid_d;
  reg             weq_mmio_rd_intrpt_obj_valid_q;
  wire            weq_mmio_wr_intrpt_data_done_d;
  reg             weq_mmio_wr_intrpt_data_done_q;
  wire            weq_mmio_rd_intrpt_data_valid_d;
  reg             weq_mmio_rd_intrpt_data_valid_q;

  wire     [31:0] mmio_weq_eng_disable_d;
  reg      [31:0] mmio_weq_eng_disable_q;

  wire            mmio_perf_reset_d;
  reg             mmio_perf_reset_q;
  wire            mmio_perf_snapshot_d;
  reg             mmio_perf_snapshot_q;

  wire            mmio_eng_send_interrupt_d;
  reg             mmio_eng_send_interrupt_q;
  wire            mmio_eng_send_wkhstthrd_d;
  reg             mmio_eng_send_wkhstthrd_q;

  wire   [1023:0] mmio_eng_mmio_lat_data0_d;
  reg    [1023:0] mmio_eng_mmio_lat_data0_q;
  wire   [1023:0] mmio_eng_mmio_lat_data1_d;
  reg    [1023:0] mmio_eng_mmio_lat_data1_q;
  wire   [1023:0] mmio_eng_mmio_lat_data2_d;
  reg    [1023:0] mmio_eng_mmio_lat_data2_q;
  wire   [1023:0] mmio_eng_mmio_lat_data3_d;
  reg    [1023:0] mmio_eng_mmio_lat_data3_q;

  wire            mmio_eng_memcpy2_format_enable_d;
  reg             mmio_eng_memcpy2_format_enable_q;

  wire            mmio_eng_rtry_backoff_timer_disable_d;
  reg             mmio_eng_rtry_backoff_timer_disable_q;

  wire            mmio_eng_immed_terminate_enable_d;
  reg             mmio_eng_immed_terminate_enable_q;

  wire      [5:0] mmio_eng_xtouch_ageout_pg_size_d;
  reg       [5:0] mmio_eng_xtouch_ageout_pg_size_q;
//     wire            mmio_eng_xtouch_wt4rsp_enable_d;
//     reg             mmio_eng_xtouch_wt4rsp_enable_q;
  wire            mmio_eng_xtouch_dest_enable_d;
  reg             mmio_eng_xtouch_dest_enable_q;
  wire            mmio_eng_xtouch_source_enable_d;
  reg             mmio_eng_xtouch_source_enable_q;

  wire            mmio_eng_use_pasid_for_actag_d;
  reg             mmio_eng_use_pasid_for_actag_q;

  wire            mmio_eng_hold_pasid_for_debug_d;
  reg             mmio_eng_hold_pasid_for_debug_q;

  wire            mmio_eng_capture_all_resp_code_enable_d;
  reg             mmio_eng_capture_all_resp_code_enable_q;

  wire      [1:0] mmio_arb_ldst_priority_mode_d;
  reg       [1:0] mmio_arb_ldst_priority_mode_q;

  wire            mmio_eng_256B_op_disable_d;
  reg             mmio_eng_256B_op_disable_q;
  wire            mmio_eng_128B_op_disable_d;
  reg             mmio_eng_128B_op_disable_q;

  wire            mmio_eng_stop_on_invalid_cmd_d;
  reg             mmio_eng_stop_on_invalid_cmd_q;
  wire            mmio_eng_intrpt_on_cpy_err_en_d;
  reg             mmio_eng_intrpt_on_cpy_err_en_q;

  // AFP
  wire     [63:0] mmio_eng_obj_handle_d;
  reg      [63:0] mmio_eng_obj_handle_q;
  wire     [63:7] mmio_eng_mmio_lat_ld_ea_d;
  reg      [63:7] mmio_eng_mmio_lat_ld_ea_q;
  wire    [63:12] mmio_eng_base_addr_d;
  reg     [63:12] mmio_eng_base_addr_q;
  wire      [2:0] mmio_arb_num_ld_tags_d;
  reg       [2:0] mmio_arb_num_ld_tags_q;
  wire      [1:0] mmio_eng_ld_size_d;
  reg       [1:0] mmio_eng_ld_size_q;
  wire            mmio_eng_type_ld_d;
  reg             mmio_eng_type_ld_q;
  wire      [2:0] mmio_arb_num_st_tags_d;
  reg       [2:0] mmio_arb_num_st_tags_q;
  wire      [1:0] mmio_eng_st_size_d;
  reg       [1:0] mmio_eng_st_size_q;
  wire            mmio_eng_type_st_d;
  reg             mmio_eng_type_st_q;
  wire    [31:12] mmio_eng_offset_mask_d;
  reg     [31:12] mmio_eng_offset_mask_q;
  wire      [9:0] mmio_eng_pasid_d;
  reg       [9:0] mmio_eng_pasid_q;
  wire            fatal_error_inject_d;
  reg             fatal_error_inject_q;
  wire            mmio_arb_fastpath_disable_d;
  reg             mmio_arb_fastpath_disable_q;
  wire            mmio_eng_error_intrpt_enable_d;
  reg             mmio_eng_error_intrpt_enable_q;
  wire            mmio_eng_wkhstthrd_intrpt_enable_d;
  reg             mmio_eng_wkhstthrd_intrpt_enable_q;
  wire     [15:0] mmio_eng_wkhstthrd_tid_d;
  reg      [15:0] mmio_eng_wkhstthrd_tid_q;
  wire            mmio_eng_wkhstthrd_flag_d;
  reg             mmio_eng_wkhstthrd_flag_q;
  wire            mmio_eng_extra_write_mode_d;
  reg             mmio_eng_extra_write_mode_q;
  wire      [1:0] mmio_eng_xtouch_pg_n_d;
  reg       [1:0] mmio_eng_xtouch_pg_n_q;
  wire      [5:0] mmio_eng_xtouch_pg_size_d;
  reg       [5:0] mmio_eng_xtouch_pg_size_q;
  wire            mmio_eng_xtouch_type_d;
  reg             mmio_eng_xtouch_type_q;
  wire            mmio_eng_xtouch_hwt_d;
  reg             mmio_eng_xtouch_hwt_q;
  wire            mmio_eng_xtouch_wt4rsp_enable_d;
  reg             mmio_eng_xtouch_wt4rsp_enable_q;
  wire            mmio_eng_xtouch_enable_d;
  reg             mmio_eng_xtouch_enable_q;

  wire            mmio_eng_enable_d;
  reg             mmio_eng_enable_q;
  wire            mmio_eng_mmio_lat_mode_d;
  reg             mmio_eng_mmio_lat_mode_q;
  wire            mmio_eng_mmio_lat_mode_sz_512_st_d;
  reg             mmio_eng_mmio_lat_mode_sz_512_st_q;
  wire            mmio_eng_mmio_lat_mode_sz_512_ld_d;
  reg             mmio_eng_mmio_lat_mode_sz_512_ld_q;
  wire            mmio_eng_mmio_lat_use_reg_data_d;
  reg             mmio_eng_mmio_lat_use_reg_data_q;
  wire            mmio_eng_mmio_lat_extra_read_d;
  reg             mmio_eng_mmio_lat_extra_read_q;
  wire            mmio_eng_resend_retries_d;
  reg             mmio_eng_resend_retries_q;

  wire            mmio_weq_restart_process_d;
  reg             mmio_weq_restart_process_q;

  wire      [7:0] large_data_scorecard_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] large_data_scorecard_q;

 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            mmio_access_dly1_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_access_dly1_q;
  wire            mmio_access_dly2_d;
  reg             mmio_access_dly2_q;

  // -- TLX clock domain latches
  wire            mmio_rd_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_rd_q;
  wire            mmio_wr_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_wr_q;
  wire            mmio_large_rd_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_large_rd_q;
  wire            mmio_large_wr_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_large_wr_q;
  wire      [1:0] mmio_large_wr_half_en_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [1:0] mmio_large_wr_half_en_q;
  reg       [1:0] mmio_large_wr_half_en_dly1_q;

  wire            mmio_early_wr_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_early_wr_q;
  wire            mmio_early_large_wr_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_early_large_wr_q;
  wire      [1:0] mmio_early_large_wr_half_en_d;
  reg       [1:0] mmio_early_large_wr_half_en_q;

  wire            early_addr_is_afu_extra_ea_d;
  reg             early_addr_is_afu_extra_ea_q;
  wire            early_addr_is_afu_misc_d;
  reg             early_addr_is_afu_misc_q;
  wire            early_addr_is_afu_enable_d;
  reg             early_addr_is_afu_enable_q;
  wire            early_addr_is_large_ping_pong_data0_d;
  reg             early_addr_is_large_ping_pong_data0_q;
  wire            early_addr_is_large_ping_pong_data1_d;
  reg             early_addr_is_large_ping_pong_data1_q;
  wire            early_addr_is_large_ping_pong_data2_d;
  reg             early_addr_is_large_ping_pong_data2_q;
  wire            early_addr_is_large_ping_pong_data3_d;
  reg             early_addr_is_large_ping_pong_data3_q;

  wire            mmio_valid_400_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_valid_400_q;
  wire            mmio_rd_dly1_d;                                                    
  reg             mmio_rd_dly1_q;                                                    
  wire            mmio_wr_dly1_d;                                                    
  reg             mmio_wr_dly1_q;                                                    
  wire            mmio_large_rd_dly1_d;                                                    
  reg             mmio_large_rd_dly1_q;                                                    
  wire            mmio_large_wr_dly1_d;                                                    
  reg             mmio_large_wr_dly1_q;                                                    
  wire            mmio_valid_200_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_valid_200_q;
  wire            mmio_addr_en;
  wire     [25:0] mmio_addr_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [25:0] mmio_addr_q;
  wire     [25:0] mmio_addr_200_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [25:0] mmio_addr_200_q;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            mmio_wrdata_en;
  wire   [1023:0] mmio_wrdata_d;
//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg    [1023:0] mmio_wrdata_q;
  wire            mmio_wr_done_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_wr_done_q;
  wire            mmio_rddata_valid_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_rddata_valid_q;
  reg    [1023:0] mmio_rddata_d;
//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg    [1023:0] mmio_rddata_q;
  wire            mmio_bad_op_or_align_d;
  reg             mmio_bad_op_or_align_q;
  wire            mmio_addr_not_implemented_d;
  reg             mmio_addr_not_implemented_q;

  wire            rd_afu_config_d;
  reg             rd_afu_config_q;
  wire            rd_afu_config2_d;
  reg             rd_afu_config2_q;
  wire            rd_afu_error_d;
  reg             rd_afu_error_q;
  wire            rd_afu_error_info_d;
  reg             rd_afu_error_info_q;
  wire            rd_afu_trace_ctl_d;
  reg             rd_afu_trace_ctl_q;
  wire            rd_afu_stats_d;
  reg             rd_afu_stats_q;

  wire            rd_afu_obj_handle_d;
  reg             rd_afu_obj_handle_q;
  wire            rd_afu_extra_ea_d;
  reg             rd_afu_extra_ea_q;
  wire            rd_afu_wed_d;
  reg             rd_afu_wed_q;
  wire            rd_afu_bufmask_d;
  reg             rd_afu_bufmask_q;
  wire            rd_afu_pasid_d;
  reg             rd_afu_pasid_q;
  wire            rd_afu_misc_d;
  reg             rd_afu_misc_q;
  wire            rd_afu_enable_d;
  reg             rd_afu_enable_q;
  wire            rd_afu_control_d;
  reg             rd_afu_control_q;

  wire            rd_afu_display_ctl_d;
  reg             rd_afu_display_ctl_q;
  wire            rd_large_ping_pong_data0_d;
  reg             rd_large_ping_pong_data0_q;
  wire            rd_large_ping_pong_data1_d;
  reg             rd_large_ping_pong_data1_q;
  wire            rd_large_ping_pong_data2_d;
  reg             rd_large_ping_pong_data2_q;
  wire            rd_large_ping_pong_data3_d;
  reg             rd_large_ping_pong_data3_q;

  wire            rd_process_handle_d;
  reg             rd_process_handle_q;
  wire            rd_process_ctl_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             rd_process_ctl_q;

  wire            wr_afu_config_d;
  reg             wr_afu_config_q;
  wire            wr_afu_config2_d;
  reg             wr_afu_config2_q;
  wire            wr_afu_error_d;
  reg             wr_afu_error_q;
  wire            wr_afu_error_info_d;
  reg             wr_afu_error_info_q;
  wire            wr_afu_trace_ctl_d;
  reg             wr_afu_trace_ctl_q;
  wire            wr_afu_stats_d;
  reg             wr_afu_stats_q;

  wire            wr_afu_obj_handle_d;
  reg             wr_afu_obj_handle_q;
  wire            wr_afu_extra_ea_d;
  reg             wr_afu_extra_ea_q;
  wire            wr_afu_wed_d;
  reg             wr_afu_wed_q;
  wire            wr_afu_bufmask_d;
  reg             wr_afu_bufmask_q;
  wire            wr_afu_pasid_d;
  reg             wr_afu_pasid_q;
  wire            wr_afu_misc_d;
  reg             wr_afu_misc_q;
  wire            wr_afu_enable_d;
  reg             wr_afu_enable_q;
  wire            wr_afu_control_d;
  reg             wr_afu_control_q;
  wire            wr_afu_latency_d;
  reg             wr_afu_latency_q;
  wire            wr_afu_display_ctl_d;
  reg             wr_afu_display_ctl_q;
  wire            wr_afu_display_data_d;
  reg             wr_afu_display_data_q;
  wire            wr_afu_perf_count_d;
  reg             wr_afu_perf_count_q;

  wire            wr_large_ping_pong_data0_d;
  reg             wr_large_ping_pong_data0_q;
  wire            wr_large_ping_pong_data1_d;
  reg             wr_large_ping_pong_data1_q;
  wire            wr_large_ping_pong_data2_d;
  reg             wr_large_ping_pong_data2_q;
  wire            wr_large_ping_pong_data3_d;
  reg             wr_large_ping_pong_data3_q;

  wire      [3:0] ld_resp_ping_pong_data_d;
  reg       [3:0] ld_resp_ping_pong_data_q;

  wire   [1023:0] eng_mmio_data_d;
  reg    [1023:0] eng_mmio_data_q;

  wire            wr_process_ctl_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             wr_process_ctl_q;

  wire            rd_wed_dly1_d;
  reg             rd_wed_dly1_q;
  wire            rd_wed_pending_en;
  wire            rd_wed_pending_d;
  reg             rd_wed_pending_q;
  wire            wr_wed_dly1_d;
  reg             wr_wed_dly1_q;
  wire            wr_wed_pending_en;
  wire            wr_wed_pending_d;
  reg             wr_wed_pending_q;
  wire            rd_process_status_dly1_d;
  reg             rd_process_status_dly1_q;
  wire            rd_process_status_pending_en;
  wire            rd_process_status_pending_d;
  reg             rd_process_status_pending_q;
  wire            rd_intrpt_ctl_dly1_d;                                                
  reg             rd_intrpt_ctl_dly1_q;                                                
  wire            rd_intrpt_ctl_pending_en;                                            
  wire            rd_intrpt_ctl_pending_d;                                             
  reg             rd_intrpt_ctl_pending_q;                                             
  wire            wr_intrpt_ctl_dly1_d;                                                
  reg             wr_intrpt_ctl_dly1_q;                                                
  wire            wr_intrpt_ctl_pending_en;                                            
  wire            wr_intrpt_ctl_pending_d;                                             
  reg             wr_intrpt_ctl_pending_q;
  wire            rd_intrpt_obj_dly1_d;                                                
  reg             rd_intrpt_obj_dly1_q;                                                
  wire            rd_intrpt_obj_pending_en;                                            
  wire            rd_intrpt_obj_pending_d;                                             
  reg             rd_intrpt_obj_pending_q;                                             
  wire            wr_intrpt_obj_dly1_d;                                                
  reg             wr_intrpt_obj_dly1_q;                                                
  wire            wr_intrpt_obj_pending_en;                                            
  wire            wr_intrpt_obj_pending_d;                                             
  reg             wr_intrpt_obj_pending_q;
  wire            rd_intrpt_data_dly1_d;                                                
  reg             rd_intrpt_data_dly1_q;                                                
  wire            rd_intrpt_data_pending_en;                                            
  wire            rd_intrpt_data_pending_d;                                             
  reg             rd_intrpt_data_pending_q;                                             
  wire            wr_intrpt_data_dly1_d;                                                
  reg             wr_intrpt_data_dly1_q;                                                
  wire            wr_intrpt_data_pending_en;                                            
  wire            wr_intrpt_data_pending_d;                                             
  reg             wr_intrpt_data_pending_q;
  wire    [63:60] afu_control_dly1_d;
  reg     [63:60] afu_control_dly1_q;

  wire            rddata_weq_en;
  wire     [63:0] rddata_weq_d;
  reg      [63:0] rddata_weq_q;

  reg      [63:0] afu_config_d;
  reg      [63:0] afu_config_q;
  reg      [35:0] afu_config2_d;
  reg      [35:0] afu_config2_q;
  reg      [15:0] afu_error_d;
  reg      [15:0] afu_error_q;
  reg      [31:0] afu_error_info_d;
  reg      [31:0] afu_error_info_q;
  reg      [63:0] afu_trace_ctl_d;
  reg      [63:0] afu_trace_ctl_q;
  reg      [63:0] afu_stats_d;
  reg      [63:0] afu_stats_q;

  reg      [63:0] afu_obj_handle_d;
  reg      [63:0] afu_obj_handle_q;
  reg      [63:7] afu_extra_ea_d;
  reg      [63:7] afu_extra_ea_q;
  reg      [63:0] afu_wed_d;
  reg      [63:0] afu_wed_q;
  reg     [31:12] afu_bufmask_d;
  reg     [31:12] afu_bufmask_q;
  reg       [9:0] afu_pasid_d;
  reg       [9:0] afu_pasid_q;
  reg      [35:0] afu_misc_d;
  reg      [35:0] afu_misc_q;
  reg     [63:57] afu_enable_d;
  reg     [63:57] afu_enable_q;
  reg     [63:60] afu_control_d;
  reg     [63:60] afu_control_q;

  reg      [31:0] afu_display_ctl_d;
  reg      [31:0] afu_display_ctl_q;

  reg    [1023:0] large_ping_pong_data0_d;
  reg    [1023:0] large_ping_pong_data0_q;
  reg    [1023:0] large_ping_pong_data1_d;
  reg    [1023:0] large_ping_pong_data1_q;
  reg    [1023:0] large_ping_pong_data2_d;
  reg    [1023:0] large_ping_pong_data2_q;
  reg    [1023:0] large_ping_pong_data3_d;
  reg    [1023:0] large_ping_pong_data3_q;

//reg      [63:0] process_ctl_d;
//reg      [63:0] process_ctl_q;

  wire            mmio_weq_eng_disable_updated_dly1_d;    // -- 400 MHz
  reg             mmio_weq_eng_disable_updated_dly1_q;    // -- 400 MHz

  wire            mmio_weq_eng_disable_updated_d;         // -- 200 MHz
  reg             mmio_weq_eng_disable_updated_q;         // -- 200 MHz

  wire            mmio_restart_process_dly1_d;
  reg             mmio_restart_process_dly1_q;
  wire            mmio_restart_process_dly2_d;
  reg             mmio_restart_process_dly2_q;
  wire            mmio_restart_process_pending_en;
  wire            mmio_restart_process_pending_d;
  reg             mmio_restart_process_pending_q;

  wire            mmio_terminate_process_dly1_d;    // -- 400 MHz
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_terminate_process_dly1_q;    // -- 400 MHz

  // -- Terminate Queue / Arb latches
  wire            mmio_terminate_process_d;         // -- 200 MHz
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             mmio_terminate_process_q;         // -- 200 MHz

 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            mmio_terminate_pasid_en;
  wire     [19:0] mmio_terminate_pasid_d;           // -- 200 MHz
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [19:0] mmio_terminate_pasid_q;           // -- 200 MHz

  wire            cfg_afu_terminate_valid_dly1_d;   // -- 200 MHz
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             cfg_afu_terminate_valid_dly1_q;   // -- 200 MHz

  wire            cfg_terminate_process_d;          // -- 200 MHz
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             cfg_terminate_process_q;          // -- 200 MHz

 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            cfg_terminate_pasid_en;
  wire     [19:0] cfg_terminate_pasid_d;            // -- 200 MHz
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [19:0] cfg_terminate_pasid_q;            // -- 200 MHz

 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            cfg_terminate_process_pending_en;
  reg             cfg_terminate_process_pending_d;  // -- 200 MHz
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             cfg_terminate_process_pending_q;  // -- 200 MHz

//     reg     [511:0] nxt_terminate_req_d;              // -- 200 MHz
//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
//     reg     [511:0] nxt_terminate_req_q;              // -- 200 MHz

//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
//     wire            terminate_process_d;              // -- 200 MHz
//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
//     reg             terminate_process_q;              // -- 200 MHz

//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
//     wire            terminate_pasid_en;
//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
//     wire     [19:0] terminate_pasid_d;                // -- 200 MHz
//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
//     reg      [19:0] terminate_pasid_q;                // -- 200 MHz

//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
//     wire            terminate_process_pending_en;
//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
//     reg             terminate_process_pending_d;      // -- 200 MHz
//    `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
//     reg             terminate_process_pending_q;      // -- 200 MHz

  // -- Array Display latches
  wire            rd_afu_display_data_d;
  reg             rd_afu_display_data_q;
//  wire            rd_afu_display_data_dly1_d;
//  reg             rd_afu_display_data_dly1_q;
  wire            rd_afu_display_data_pending_en;
  wire            rd_afu_display_data_pending_d;
  reg             rd_afu_display_data_pending_q;
  wire            trace_mmio_display_rddata_valid_d;
  reg             trace_mmio_display_rddata_valid_q;
  wire            rspi_mmio_display_rddata_valid_d;
  reg             rspi_mmio_display_rddata_valid_q;
  wire            weq_mmio_display_rddata_valid_d;
  reg             weq_mmio_display_rddata_valid_q;
  wire            eng_mmio_display_rddata_valid_d;
  reg             eng_mmio_display_rddata_valid_q;
  wire            rddata_afu_display_data_en;
  reg      [63:0] rddata_afu_display_data_d;
  reg      [63:0] rddata_afu_display_data_q;

  // -- Perf Count latches
  wire            rd_afu_perf_count_d;
  reg             rd_afu_perf_count_q;
  wire            rd_afu_latency_d;
  reg             rd_afu_latency_q;
  wire            rd_afu_perf_count_pending_en;
  wire            rd_afu_perf_count_pending_d;
  reg             rd_afu_perf_count_pending_q;
  wire            perf_mmio_rddata_valid_d;
  reg             perf_mmio_rddata_valid_q;
  wire            rddata_afu_perf_count_en;
  wire     [63:0] rddata_afu_perf_count_d;
  reg      [63:0] rddata_afu_perf_count_q;

  // --          5 2 1               5 2 1               5 2 1               5 2 1               5 2 1
  // --          1 5 2 6 3 1         1 5 2 6 3 1         1 5 2 6 3 1         1 5 2 6 3 1         1 5 2 6 3 1         5 2 1
  // --  8 4 2 1 2 6 8 4 2 6 8 4 2 1 2 6 8 4 2 6 8 4 2 1 2 6 8 4 2 6 8 4 2 1 2 6 8 4 2 6 8 4 2 1 2 6 8 4 2 6 8 4 2 1 1 5 2 6 3 1
  // --  E E E E P P P P P P P P P P T T T T T T T T T T G G G G G G G G G G M M M M M M M M M M K K K K K K K K K K 2 6 8 4 2 6 8 4 2 1
  // -- +-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
  // --  6 6 6 6 5 5 5 5 5 5 5 5 5 5 4 4 4 4 4 4 4 4 4 4 3 3 3 3 3 3 3 3 3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1 
  // --  3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
  // -- +-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
  // -- |<------------------------------------------------------------------------->| |<--------------->|
  // --                                   \__ MMIO Bar0                               \        \__ Per Process MMIO Offset for 512 processes
  // --                                                                                \__  bit 25: 0 = privileged regs, 1 = per process regs 

  // -- General AFU mode/configuration MMMIO registers start at MMIO Bar0
  // -- Per Process MMIO registers begin at MMIO Bar0 + x'0200_0000 (32M)
  // -- Example:  MMIO Bar0 + x'0201_0000 used for process handle 1


  // -- ********************************************************************************************************************************
  // -- Determine Even/Odd Cycles
  // -- ********************************************************************************************************************************

  // --                          _______         _______         _______         _______         _______         
  // -- clock_afu             __|       |_______|       |_______|       |_______|       |_______|       |_______
  // --                          ___     ___     ___     ___     ___     ___     ___     ___     ___     ___     
  // -- clock_tlx             __|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___
  // --                          _______________                 _______________                 _______________
  // -- toggle_q              __|               |_______________|               |_______________|
  // --                                  _______________                 _______________                 _______
  // -- sample_q              __________|               |_______________|               |_______________|
  // --                          _______         _______         _______         _______         _______         
  // -- even_q                __|       |_______|       |_______|       |_______|       |_______|       |_______
  // --                       __         _______         _______         _______         _______         _______         
  // -- odd_q                   |_______|       |_______|       |_______|       |_______|       |_______|       


  assign  toggle_d = ~toggle_q && ~reset;

  assign  sample_d =  toggle_q;

  assign  odd_d    =  toggle_q ^ sample_q;

  assign  even_d   =  odd_q;


  // -- ********************************************************************************************************************************
  // -- Latch interface signals
  // -- ********************************************************************************************************************************

  // -- NOTE: addr and wrdata are latched and held because some accesses need to be forwarded to the WEQ sub-unit which
  // --       is in a clock domain that runs at half the frequency.

  assign  mmio_rd_d        =  cmdi_mmio_rd;
  assign  mmio_wr_d        =  cmdi_mmio_wr;
  assign  mmio_valid_400_d =  cmdi_mmio_rd || cmdi_mmio_wr;
  assign  mmio_large_rd_d  =  cmdi_mmio_large_rd;
  assign  mmio_large_wr_d  =  cmdi_mmio_large_wr;
  assign  mmio_large_wr_half_en_d[1:0]  =  cmdi_mmio_large_wr_half_en;

  assign  mmio_rd_dly1_d   =  mmio_rd_q;
  assign  mmio_wr_dly1_d   =  mmio_wr_q;
  assign  mmio_large_rd_dly1_d   =  mmio_large_rd_q;
  assign  mmio_large_wr_dly1_d   =  mmio_large_wr_q;
  assign  mmio_valid_200_d =  cmdi_mmio_rd || cmdi_mmio_wr || mmio_valid_400_q;

  assign  mmio_addr_en      =  cmdi_mmio_rd || cmdi_mmio_wr || cmdi_mmio_large_rd || cmdi_mmio_large_wr || reset;
  assign  mmio_addr_d[25:0] =  cmdi_mmio_addr[25:0];

  assign  mmio_addr_200_d[25:0] =  mmio_addr_q[25:0];


  assign  mmio_wrdata_en        =  cmdi_mmio_wr || cmdi_mmio_large_wr || reset;
  assign  mmio_wrdata_d[1023:0] =  cmdi_mmio_wrdata[1023:0];

  assign  mmio_early_wr_d       =  cmdi_mmio_early_wr;
  assign  mmio_early_large_wr_d =  cmdi_mmio_early_large_wr;
  assign  mmio_early_large_wr_half_en_d[1:0]  =  cmdi_mmio_early_large_wr_half_en[1:0];


  // -- ********************************************************************************************************************************
  // -- Check for bad op or bad alignment
  // -- ********************************************************************************************************************************

  assign  bad_wr_align    =  ( mmio_wr_q && ( mmio_addr_q[2:0] != 3'b0 ));
  assign  bad_large_wr_align =  ( mmio_large_wr_q && (( mmio_addr_q[5:0] != 6'b0 ) ||  // not 64B aligned
			                              ( (mmio_addr_q[6] == 1'b1) && (mmio_large_wr_half_en_q[1:0] == 2'b11)) ));  // 128B write, not aligned
  assign  bad_op          =  ( mmio_rd_q && mmio_wr_q ) || ( mmio_large_rd_q && mmio_large_wr_q );
  assign  bad_op_or_align =  ( bad_op || bad_wr_align || bad_large_wr_align );


  // -- ********************************************************************************************************************************
  // -- Qualify Valids
  // -- ********************************************************************************************************************************

  assign  mmio_rd_valid =  mmio_rd_q && ~mmio_wr_q;
  assign  mmio_wr_valid =  mmio_wr_q && ~mmio_rd_q && ~bad_wr_align;

  assign  mmio_large_rd_valid =  mmio_large_rd_q && ~mmio_large_wr_q;
  assign  mmio_large_wr_valid =  mmio_large_wr_q && ~mmio_large_rd_q && ~bad_large_wr_align;


  // -- ********************************************************************************************************************************
  // -- Decode address - map to target register
  // -- ********************************************************************************************************************************

  assign  addr_is_privileged  =  ( mmio_addr_q[25] == 1'b0 ) && ( mmio_addr_q[24:16] == 9'b0 ) && ( mmio_addr_q[15:9] ==  7'b0 );
  assign  addr_is_per_process =  ( mmio_addr_q[25] == 1'b1 )                                   && ( mmio_addr_q[15:6] == 10'b0 );

  assign  addr_is_large_reg   =  ( mmio_addr_q[25] == 1'b0 ) && ( mmio_addr_q[24:16] == 9'b01 ) && ( mmio_addr_q[15:9] ==  7'b0 );

  assign  early_addr_is_privileged  =  ( cmdi_mmio_early_addr[25] == 1'b0 ) && ( cmdi_mmio_early_addr[24:16] == 9'b0  ) && ( cmdi_mmio_early_addr[15:9] ==  7'b0 );
  assign  early_addr_is_large_reg   =  ( cmdi_mmio_early_addr[25] == 1'b0 ) && ( cmdi_mmio_early_addr[24:16] == 9'b01 ) && ( cmdi_mmio_early_addr[15:9] ==  7'b0 );

  // -- Privileged registers
  assign  addr_is_afu_config        =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b000000 );  // -- x0000  R/W
  assign  addr_is_afu_config2       =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b000001 );  // -- x0008  R/W
  assign  addr_is_afu_error         =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b000010 );  // -- x0010  R/W
  assign  addr_is_afu_error_info    =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b000011 );  // -- x0018  R/W
  assign  addr_is_afu_trace_ctl     =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b000100 );  // -- x0020  R/W
  assign  addr_is_afu_stats         =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b000101 );  // -- x0028  R/W

  assign  addr_is_afu_obj_handle    =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b000110 );  // -- x0030  R/W
  assign  addr_is_afu_extra_ea      =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b000111 );  // -- x0038  R/W
  assign  addr_is_afu_wed           =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b001000 );  // -- x0040  R/W
  assign  addr_is_afu_bufmask       =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b001001 );  // -- x0048  R/W
  assign  addr_is_afu_pasid         =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b001010 );  // -- x0050  R/W
  assign  addr_is_afu_misc          =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b001011 );  // -- x0058  R/W
  assign  addr_is_afu_enable        =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b001100 );  // -- x0060  R/W
  assign  addr_is_afu_control       =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b001101 );  // -- x0068  Write-Only

  assign  addr_is_afu_latency       =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b001110 );  // -- x0070  RO

  assign  addr_is_afu_display_ctl   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b001111 );  // -- x0078  R/W
  assign  addr_is_afu_display_data0 =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b010000 );  // -- x0080  RO
  assign  addr_is_afu_display_data1 =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b010001 );  // -- x0088  RO
  assign  addr_is_afu_display_data2 =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b010010 );  // -- x0090  RO
  assign  addr_is_afu_display_data3 =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b010011 );  // -- x0098  RO
  assign  addr_is_afu_display_data4 =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b010100 );  // -- x00A0  RO
  assign  addr_is_afu_display_data5 =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b010101 );  // -- x00A8  RO
  assign  addr_is_afu_display_data6 =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b010110 );  // -- x00B0  RO
  assign  addr_is_afu_display_data7 =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b010111 );  // -- x00B8  RO

  assign  addr_is_afu_perf_count0   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b011000 );  // -- x00C0  RO
  assign  addr_is_afu_perf_count1   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b011001 );  // -- x00C8  RO
  assign  addr_is_afu_perf_count2   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b011010 );  // -- x00D0  RO
  assign  addr_is_afu_perf_count3   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b011011 );  // -- x00D8  RO
  assign  addr_is_afu_perf_count4   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b011100 );  // -- x00E0  RO
  assign  addr_is_afu_perf_count5   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b011101 );  // -- x00E8  RO
  assign  addr_is_afu_perf_count6   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b011110 );  // -- x00F0  RO
  assign  addr_is_afu_perf_count7   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b011111 );  // -- x00F8  RO
  assign  addr_is_afu_perf_count8   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b100000 );  // -- x0100  RO
  assign  addr_is_afu_perf_count9   =  addr_is_privileged  && ( mmio_addr_q[8:3] == 6'b100001 );  // -- x0108  RO

  assign  addr_is_large_ping_pong_data0 = addr_is_large_reg && ( mmio_addr_q[8:7] == 2'b00 );  // -- x10000  R/W
  assign  addr_is_large_ping_pong_data1 = addr_is_large_reg && ( mmio_addr_q[8:7] == 2'b01 );  // -- x10080  R/W
  assign  addr_is_large_ping_pong_data2 = addr_is_large_reg && ( mmio_addr_q[8:7] == 2'b10 );  // -- x10100  R/W
  assign  addr_is_large_ping_pong_data3 = addr_is_large_reg && ( mmio_addr_q[8:7] == 2'b11 );  // -- x10180  R/W


  assign  early_addr_is_afu_extra_ea_d  =  early_addr_is_privileged  && ( cmdi_mmio_early_addr[8:3] == 6'b000111 );  // -- x0038  R/W
  assign  early_addr_is_afu_misc_d      =  early_addr_is_privileged  && ( cmdi_mmio_early_addr[8:3] == 6'b001011 );  // -- x0058  R/W
  assign  early_addr_is_afu_enable_d    =  early_addr_is_privileged  && ( cmdi_mmio_early_addr[8:3] == 6'b001100 );  // -- x0060  R/W

  assign  early_addr_is_large_ping_pong_data0_d  = early_addr_is_large_reg && ( cmdi_mmio_early_addr[8:7] == 2'b00 );  // -- x10000  R/W
  assign  early_addr_is_large_ping_pong_data1_d  = early_addr_is_large_reg && ( cmdi_mmio_early_addr[8:7] == 2'b01 );  // -- x10080  R/W
  assign  early_addr_is_large_ping_pong_data2_d  = early_addr_is_large_reg && ( cmdi_mmio_early_addr[8:7] == 2'b10 );  // -- x10100  R/W
  assign  early_addr_is_large_ping_pong_data3_d  = early_addr_is_large_reg && ( cmdi_mmio_early_addr[8:7] == 2'b11 );  // -- x10180  R/W


  assign  rd_afu_config             =  mmio_rd_valid &&   addr_is_afu_config;           // -- x0000  R/W
  assign  rd_afu_config2            =  mmio_rd_valid &&   addr_is_afu_config2;          // -- x0008  R/W
  assign  rd_afu_error              =  mmio_rd_valid &&   addr_is_afu_error;            // -- x0010  R/W
  assign  rd_afu_error_info         =  mmio_rd_valid &&   addr_is_afu_error_info;       // -- x0018  R/W
  assign  rd_afu_trace_ctl          =  mmio_rd_valid &&   addr_is_afu_trace_ctl;        // -- x0020  R/W
  assign  rd_afu_stats              =  mmio_rd_valid &&   addr_is_afu_stats;            // -- x0028  R/W
  assign  rd_afu_obj_handle         =  mmio_rd_valid &&   addr_is_afu_obj_handle;       // -- x0030  R/W
  assign  rd_afu_extra_ea           =  mmio_rd_valid &&   addr_is_afu_extra_ea;         // -- x0038  R/W
  assign  rd_afu_wed                =  mmio_rd_valid &&   addr_is_afu_wed;              // -- x0040  R/W
  assign  rd_afu_bufmask            =  mmio_rd_valid &&   addr_is_afu_bufmask;          // -- x0048  R/W
  assign  rd_afu_pasid              =  mmio_rd_valid &&   addr_is_afu_pasid;            // -- x0050  R/W
  assign  rd_afu_misc               =  mmio_rd_valid &&   addr_is_afu_misc;             // -- x0058  R/W
  assign  rd_afu_enable             =  mmio_rd_valid &&   addr_is_afu_enable;           // -- x0060  R/W
  assign  rd_afu_control            =  mmio_rd_valid &&   addr_is_afu_control;          // -- x0068  R/W
  assign  rd_afu_latency            =  mmio_rd_valid &&   addr_is_afu_latency;          // -- x0070  RO
  assign  rd_afu_display_ctl        =  mmio_rd_valid &&   addr_is_afu_display_ctl;      // -- x0078  R/W
  assign  rd_afu_display_data       =  mmio_rd_valid && ( addr_is_afu_display_data0 ||  // -- x0080  RO
                                                          addr_is_afu_display_data1 ||  // -- x0088  RO
                                                          addr_is_afu_display_data2 ||  // -- x0090  RO
                                                          addr_is_afu_display_data3 ||  // -- x0098  RO
                                                          addr_is_afu_display_data4 ||  // -- x00A0  RO
                                                          addr_is_afu_display_data5 ||  // -- x00A8  RO
                                                          addr_is_afu_display_data6 ||  // -- x00B0  RO
                                                          addr_is_afu_display_data7 );  // -- x00B8  RO
  assign  rd_afu_perf_count         =  mmio_rd_valid && ( addr_is_afu_perf_count0 ||    // -- x00C0  RO
                                                          addr_is_afu_perf_count1 ||    // -- x00C8  RO
                                                          addr_is_afu_perf_count2 ||    // -- x00D0  RO
                                                          addr_is_afu_perf_count3 ||    // -- x00D8  RO
                                                          addr_is_afu_perf_count4 ||    // -- x00E0  RO
                                                          addr_is_afu_perf_count5 ||    // -- x00E8  RO
                                                          addr_is_afu_perf_count6 ||    // -- x00F0  RO
                                                          addr_is_afu_perf_count7 ||    // -- x00F8  RO
                                                          addr_is_afu_perf_count8 ||    // -- x0100  RO
                                                          addr_is_afu_perf_count9 );    // -- x0108  RO

  assign  rd_large_ping_pong_data0  =  mmio_large_rd_valid &&  addr_is_large_ping_pong_data0;  // -- x10000  R/W
  assign  rd_large_ping_pong_data1  =  mmio_large_rd_valid &&  addr_is_large_ping_pong_data1;  // -- x10080  R/W
  assign  rd_large_ping_pong_data2  =  mmio_large_rd_valid &&  addr_is_large_ping_pong_data2;  // -- x10100  R/W
  assign  rd_large_ping_pong_data3  =  mmio_large_rd_valid &&  addr_is_large_ping_pong_data3;  // -- x10180  R/W

  assign  wr_afu_config             =  mmio_wr_valid &&   addr_is_afu_config;           // -- x0000  R/W
  assign  wr_afu_config2            =  mmio_wr_valid &&   addr_is_afu_config2;          // -- x0008  R/W
  assign  wr_afu_error              =  mmio_wr_valid &&   addr_is_afu_error;            // -- x0010  R/W
  assign  wr_afu_error_info         =  mmio_wr_valid &&   addr_is_afu_error_info;       // -- x0018  R/W
  assign  wr_afu_trace_ctl          =  mmio_wr_valid &&   addr_is_afu_trace_ctl;        // -- x0020  R/W
  assign  wr_afu_stats              =  mmio_wr_valid &&   addr_is_afu_stats;            // -- x0028  R/W
  assign  wr_afu_obj_handle         =  mmio_wr_valid &&   addr_is_afu_obj_handle;       // -- x0030  R/W
  assign  wr_afu_extra_ea           =  mmio_wr_valid &&   addr_is_afu_extra_ea;         // -- x0038  R/W
  assign  wr_afu_wed                =  mmio_wr_valid &&   addr_is_afu_wed;              // -- x0040  R/W
  assign  wr_afu_bufmask            =  mmio_wr_valid &&   addr_is_afu_bufmask;          // -- x0048  R/W
  assign  wr_afu_pasid              =  mmio_wr_valid &&   addr_is_afu_pasid;            // -- x0050  R/W
  assign  wr_afu_misc               =  mmio_wr_valid &&   addr_is_afu_misc;             // -- x0058  R/W
  assign  wr_afu_enable             =  mmio_wr_valid &&   addr_is_afu_enable;           // -- x0060  R/W
  assign  wr_afu_control            =  mmio_wr_valid &&   addr_is_afu_control;          // -- x0068  R/W
  assign  wr_afu_latency            =  mmio_wr_valid &&   addr_is_afu_latency;          // -- x0070  RO
  assign  wr_afu_display_ctl        =  mmio_wr_valid &&   addr_is_afu_display_ctl;      // -- x0078  R/W
  assign  wr_afu_display_data       =  mmio_wr_valid && ( addr_is_afu_display_data0 ||  // -- x0080  RO
                                                          addr_is_afu_display_data1 ||  // -- x0088  RO
                                                          addr_is_afu_display_data2 ||  // -- x0090  RO
                                                          addr_is_afu_display_data3 ||  // -- x0098  RO
                                                          addr_is_afu_display_data4 ||  // -- x00A0  RO
                                                          addr_is_afu_display_data5 ||  // -- x00A8  RO
                                                          addr_is_afu_display_data6 ||  // -- x00B0  RO
                                                          addr_is_afu_display_data7 );  // -- x00B8  RO
  assign  wr_afu_perf_count         =  mmio_wr_valid && ( addr_is_afu_perf_count0 ||    // -- x00C0  RO
                                                          addr_is_afu_perf_count1 ||    // -- x00C8  RO
                                                          addr_is_afu_perf_count2 ||    // -- x00D0  RO
                                                          addr_is_afu_perf_count3 ||    // -- x00D8  RO
                                                          addr_is_afu_perf_count4 ||    // -- x00E0  RO
                                                          addr_is_afu_perf_count5 ||    // -- x00E8  RO
                                                          addr_is_afu_perf_count6 ||    // -- x00F0  RO
                                                          addr_is_afu_perf_count7 ||    // -- x00F8  RO
                                                          addr_is_afu_perf_count8 ||    // -- x0100  RO
                                                          addr_is_afu_perf_count9 );    // -- x0108  RO

  assign  wr_large_ping_pong_data0  =  mmio_large_wr_valid &&  addr_is_large_ping_pong_data0;  // -- x10000  R/W
  assign  wr_large_ping_pong_data1  =  mmio_large_wr_valid &&  addr_is_large_ping_pong_data1;  // -- x10080  R/W
  assign  wr_large_ping_pong_data2  =  mmio_large_wr_valid &&  addr_is_large_ping_pong_data2;  // -- x10100  R/W
  assign  wr_large_ping_pong_data3  =  mmio_large_wr_valid &&  addr_is_large_ping_pong_data3;  // -- x10180  R/W


  // -- Per Process registers (bits 24:16    = process handle)
  assign  addr_is_wed               =  addr_is_per_process && ( mmio_addr_q[5:3] == 3'b000 );  // -- x0000  R/W
  assign  addr_is_process_handle    =  addr_is_per_process && ( mmio_addr_q[5:3] == 3'b001 );  // -- x0008  RO
  assign  addr_is_process_status    =  addr_is_per_process && ( mmio_addr_q[5:3] == 3'b010 );  // -- x0010  RO
  assign  addr_is_process_ctl       =  addr_is_per_process && ( mmio_addr_q[5:3] == 3'b011 );  // -- x0018  R/W
  assign  addr_is_intrpt_ctl        =  addr_is_per_process && ( mmio_addr_q[5:3] == 3'b100 );  // -- x0020  R/W
  assign  addr_is_intrpt_obj        =  addr_is_per_process && ( mmio_addr_q[5:3] == 3'b101 );  // -- x0028  R/W
  assign  addr_is_intrpt_data       =  addr_is_per_process && ( mmio_addr_q[5:3] == 3'b110 );  // -- x0030  R/W
                                  
  assign  rd_wed                    =  mmio_rd_valid && addr_is_wed;              // -- x0000  R/W - resides in WEQ
  assign  rd_process_handle         =  mmio_rd_valid && addr_is_process_handle;   // -- x0008  RO
  assign  rd_process_status         =  mmio_rd_valid && addr_is_process_status;   // -- x0010  RO  - resides in WEQ
  assign  rd_process_ctl            =  mmio_rd_valid && addr_is_process_ctl;      // -- x0018  R/W
  assign  rd_intrpt_ctl             =  mmio_rd_valid && addr_is_intrpt_ctl;       // -- x0020  R/W - resides in WEQ
  assign  rd_intrpt_obj             =  mmio_rd_valid && addr_is_intrpt_obj;       // -- x0028  R/W - resides in WEQ
  assign  rd_intrpt_data            =  mmio_rd_valid && addr_is_intrpt_data;      // -- x0030  R/W - resides in WEQ

  assign  wr_wed                    =  mmio_wr_valid && addr_is_wed;              // -- x0000  R/W - resides in WEQ
//assign  wr_process_handle         =  mmio_wr_valid && addr_is_process_handle;   // -- x0008  RO
//assign  wr_process_status         =  mmio_wr_valid && addr_is_process_status;   // -- x0010  RO  - resides in WEQ
  assign  wr_process_ctl            =  mmio_wr_valid && addr_is_process_ctl;      // -- x0018  WO
  assign  wr_intrpt_ctl             =  mmio_wr_valid && addr_is_intrpt_ctl;       // -- x0020  R/W - resides in WEQ
  assign  wr_intrpt_obj             =  mmio_wr_valid && addr_is_intrpt_obj;       // -- x0028  R/W - resides in WEQ
  assign  wr_intrpt_data            =  mmio_wr_valid && addr_is_intrpt_data;      // -- x0030  R/W - resides in WEQ


  // -- Forward wed and process status register requests to WEQ sub-unit
  // --   reads are NOT gauranteed to be returned in fixed number of cycles
  assign  rd_wed_dly1_d                =  rd_wed;
  assign  wr_wed_dly1_d                =  wr_wed;
  assign  rd_process_status_dly1_d     =  rd_process_status;
  assign  rd_intrpt_ctl_dly1_d         =  rd_intrpt_ctl;
  assign  wr_intrpt_ctl_dly1_d         =  wr_intrpt_ctl;
  assign  rd_intrpt_obj_dly1_d         =  rd_intrpt_obj;
  assign  wr_intrpt_obj_dly1_d         =  wr_intrpt_obj;
  assign  rd_intrpt_data_dly1_d        =  rd_intrpt_data;
  assign  wr_intrpt_data_dly1_d        =  wr_intrpt_data;

  assign  mmio_weq_rd_wed_d            =  rd_wed || rd_wed_dly1_q;                        // -- elongated to 2 cycles - WEQ runs at half frequency
  assign  mmio_weq_wr_wed_d            =  wr_wed || wr_wed_dly1_q;                        // -- elongated to 2 cycles - WEQ runs at half frequency
  assign  mmio_weq_rd_process_status_d =  rd_process_status || rd_process_status_dly1_q;  // -- elongated to 2 cycles - WEQ runs at half frequency
  assign  mmio_weq_rd_intrpt_ctl_d     =  rd_intrpt_ctl || rd_intrpt_ctl_dly1_q;          // -- elongated to 2 cycles - WEQ runs at half frequency
  assign  mmio_weq_wr_intrpt_ctl_d     =  wr_intrpt_ctl || wr_intrpt_ctl_dly1_q;          // -- elongated to 2 cycles - WEQ runs at half frequency
  assign  mmio_weq_rd_intrpt_obj_d     =  rd_intrpt_obj || rd_intrpt_obj_dly1_q;          // -- elongated to 2 cycles - WEQ runs at half frequency
  assign  mmio_weq_wr_intrpt_obj_d     =  wr_intrpt_obj || wr_intrpt_obj_dly1_q;          // -- elongated to 2 cycles - WEQ runs at half frequency
  assign  mmio_weq_rd_intrpt_data_d    =  rd_intrpt_data || rd_intrpt_data_dly1_q;        // -- elongated to 2 cycles - WEQ runs at half frequency
  assign  mmio_weq_wr_intrpt_data_d    =  wr_intrpt_data || wr_intrpt_data_dly1_q;        // -- elongated to 2 cycles - WEQ runs at half frequency

  assign  mmio_weq_rd_wed              =  mmio_weq_rd_wed_q;
  assign  mmio_weq_wr_wed              =  mmio_weq_wr_wed_q;
  assign  mmio_weq_rd_process_status   =  mmio_weq_rd_process_status_q;
  assign  mmio_weq_rd_intrpt_ctl       =  mmio_weq_rd_intrpt_ctl_q;
  assign  mmio_weq_wr_intrpt_ctl       =  mmio_weq_wr_intrpt_ctl_q;
  assign  mmio_weq_rd_intrpt_obj       =  mmio_weq_rd_intrpt_obj_q;
  assign  mmio_weq_wr_intrpt_obj       =  mmio_weq_wr_intrpt_obj_q;
  assign  mmio_weq_rd_intrpt_data      =  mmio_weq_rd_intrpt_data_q;
  assign  mmio_weq_wr_intrpt_data      =  mmio_weq_wr_intrpt_data_q;

  assign  mmio_weq_pasid[19:0]         = { 11'b0, mmio_addr_q[24:16] };
  assign  mmio_weq_wrdata[63:0]        =  mmio_wrdata_q[63:0];


  assign  afu_control_dly1_d           = afu_control_q;

  // -- Determine if address is NOT to an implemented register
  assign  addr_not_implemented =  ~addr_is_afu_config        &&
                                  ~addr_is_afu_config2       &&
                                  ~addr_is_afu_error         &&
                                  ~addr_is_afu_error_info    &&
                                  ~addr_is_afu_trace_ctl     &&
                                  ~addr_is_afu_stats         &&
                                  ~addr_is_afu_obj_handle    &&
                                  ~addr_is_afu_extra_ea      &&
                                  ~addr_is_afu_wed           &&
                                  ~addr_is_afu_bufmask       &&
                                  ~addr_is_afu_pasid         &&
                                  ~addr_is_afu_misc          &&
                                  ~addr_is_afu_enable        &&
                                  ~addr_is_afu_control       &&
                                  ~addr_is_afu_latency       &&
                                  ~addr_is_afu_display_ctl   &&
                                  ~addr_is_afu_display_data0 &&
                                  ~addr_is_afu_display_data1 &&
                                  ~addr_is_afu_display_data2 &&
                                  ~addr_is_afu_display_data3 &&
                                  ~addr_is_afu_display_data4 &&
                                  ~addr_is_afu_display_data5 &&
                                  ~addr_is_afu_display_data6 &&
                                  ~addr_is_afu_display_data7 &&
                                  ~addr_is_afu_perf_count0   &&
                                  ~addr_is_afu_perf_count1   &&
                                  ~addr_is_afu_perf_count2   &&
                                  ~addr_is_afu_perf_count3   &&
                                  ~addr_is_afu_perf_count4   &&
                                  ~addr_is_afu_perf_count5   &&
                                  ~addr_is_afu_perf_count6   &&
                                  ~addr_is_afu_perf_count7   &&
                                  ~addr_is_afu_perf_count8   &&
                                  ~addr_is_afu_perf_count9   &&
                               // -----------------------------
                                  ~addr_is_large_ping_pong_data0 &&
                                  ~addr_is_large_ping_pong_data1 &&
                                  ~addr_is_large_ping_pong_data2 &&
                                  ~addr_is_large_ping_pong_data3 &&
                               // -----------------------------
                                  ~addr_is_wed               &&
                                  ~addr_is_process_handle    &&
                                  ~addr_is_process_status    &&
                                  ~addr_is_process_ctl       &&
                                  ~addr_is_intrpt_ctl        &&
                                  ~addr_is_intrpt_obj        &&
                                  ~addr_is_intrpt_data;


  // -- Determine if there was an update to engine disable field
  assign  mmio_weq_eng_disable_updated_int   =  ( wr_afu_config_q && ~( mmio_wrdata_q[63:32] == afu_config_q[63:32] ));
  assign  mmio_weq_eng_disable_updated_dly1_d =  mmio_weq_eng_disable_updated_int ;  // -- Dly 400MHz clock

  assign  mmio_weq_eng_disable_updated_d      =  ( mmio_weq_eng_disable_updated_int || mmio_weq_eng_disable_updated_dly1_q );  // -- Latch in 200MHz latch

  // -- ********************************************************************************************************************************
  // -- Writes/Reads to WEQ
  // -- ********************************************************************************************************************************
// ??? TODO - Remove/hack done signals
  assign  weq_mmio_wr_wed_done_d              =  weq_mmio_wr_wed_done;
  assign  weq_mmio_rd_wed_valid_d             =  weq_mmio_rd_wed_valid;
  assign  weq_mmio_rd_process_status_valid_d  =  weq_mmio_rd_process_status_valid;
  assign  weq_mmio_wr_intrpt_ctl_done_d       =  weq_mmio_wr_intrpt_ctl_done;
  assign  weq_mmio_rd_intrpt_ctl_valid_d      =  weq_mmio_rd_intrpt_ctl_valid;
  assign  weq_mmio_wr_intrpt_obj_done_d       =  weq_mmio_wr_intrpt_obj_done;
  assign  weq_mmio_rd_intrpt_obj_valid_d      =  weq_mmio_rd_intrpt_obj_valid;
  assign  weq_mmio_wr_intrpt_data_done_d      =  weq_mmio_wr_intrpt_data_done;
  assign  weq_mmio_rd_intrpt_data_valid_d     =  weq_mmio_rd_intrpt_data_valid;

  // -- WED writes
//     assign  wr_wed_pending_en =  ( wr_wed ||  weq_mmio_wr_wed_done_q || reset );
//     assign  wr_wed_pending_d  =  ( wr_wed && ~weq_mmio_wr_wed_done_q );
//     assign  wr_wed_done       =  ( wr_wed_pending_q && weq_mmio_wr_wed_done_q );
  assign  wr_wed_pending_en =  ( wr_wed ||  wr_wed_pending_q || reset );
  assign  wr_wed_pending_d  =  ( wr_wed  );
  assign  wr_wed_done       =  ( wr_wed_pending_q  );

  // -- WED reads
  assign  rd_wed_pending_en =  ( rd_wed ||  weq_mmio_rd_wed_valid_q || reset );
  assign  rd_wed_pending_d  =  ( rd_wed && ~weq_mmio_rd_wed_valid_q ); 
  assign  rd_wed_valid      =  ( rd_wed_pending_q && weq_mmio_rd_wed_valid_q );

  // -- Process Status reads
  assign  rd_process_status_pending_en =  ( rd_process_status ||  weq_mmio_rd_process_status_valid_q || reset );
  assign  rd_process_status_pending_d  =  ( rd_process_status && ~weq_mmio_rd_process_status_valid_q );
  assign  rd_process_status_valid      =  ( rd_process_status_pending_q && weq_mmio_rd_process_status_valid_q );

  // -- Process Ctl - Restart initiated by an MMIO op                                                                                                 
  assign  mmio_restart_process_dly1_d =  ( wr_process_ctl && (( ~mmio_eng_memcpy2_format_enable_d && mmio_wrdata_q[0]  ) ||
                                                              (  mmio_eng_memcpy2_format_enable_d && mmio_wrdata_q[63] ))); // -- MemCpy2 Backward Compatibility
  assign  mmio_restart_process_dly2_d =    mmio_restart_process_dly1_q;

  assign  mmio_restart_process_pending_en =  ( mmio_restart_process_dly1_d ||  mmio_restart_process_done || reset );
  assign  mmio_restart_process_pending_d  =  ( mmio_restart_process_dly1_d && ~mmio_restart_process_done );
  assign  mmio_restart_process_done       =  ( mmio_restart_process_pending_q && weq_mmio_restart_process_done );

  // -- Process Ctl - Terminate initiated by an MMIO op                                                                                               
  assign  mmio_terminate_process =  ( wr_process_ctl && terminate_process_via_mmio_en && (( ~mmio_eng_memcpy2_format_enable_d  && mmio_wrdata_q[1]  ) ||
                                                                                          (  mmio_eng_memcpy2_format_enable_d  && mmio_wrdata_q[62] )));  // -- MemCpy2 Backward Compatibility
  assign  mmio_terminate_process_dly1_d =  mmio_terminate_process;  
  assign  mmio_terminate_process_d      =  ( mmio_terminate_process || mmio_terminate_process_dly1_q );  // -- Capture in 200 MHz latch

  assign  mmio_terminate_pasid_en      =  mmio_terminate_process_d;
  assign  mmio_terminate_pasid_d[19:0] =  { 11'b0, mmio_addr_d[24:16] };  // -- Capture in 200 MHz latches - to be decoded in 512 way decoder

  // -- Process Ctl - Terminate initiated by an cfg op
  assign  cfg_afu_terminate_valid_dly1_d =   cfg_afu_terminate_valid;  // -- Fix bug - valid is level, not a pulse, create a pulse internal to this mmio module
  assign  cfg_terminate_process          = ( cfg_afu_terminate_valid && ~cfg_afu_terminate_valid_dly1_q );  // -- This is a 1 cycle pulse in 200MHz domain
  assign  cfg_terminate_process_d        =   cfg_terminate_process;

  assign  cfg_terminate_process_pending_en =  ( cfg_terminate_process || cfg_terminate_process_done || reset );
  always @*
    begin
      if ( ~reset )
        cfg_terminate_process_pending_d    =  ( cfg_terminate_process && ~cfg_terminate_process_done );
      else
        cfg_terminate_process_pending_d    =  1'b0;
    end  // -- always @*
//     assign  cfg_terminate_process_done       =  ( cfg_terminate_process_pending_q && weq_mmio_terminate_process_done && ( terminate_pasid_q[19:0] == cfg_terminate_pasid_q[19:0] ));  
//  assign  cfg_terminate_process_done       =  1'b0;  // Oops - this doesn't clear cfg_terminate_process_pending for sim_idle_mmio_int
//     assign  cfg_terminate_process_done       =  cfg_terminate_process_pending_q;  // Clears after 1 cycle.
  assign  cfg_terminate_process_done  =  cfg_terminate_process_pending_q & (~cfg_terminate_pasid_match |    // Ignore terminate if not for this AFU's PASID
                                                                            sim_idle_eng);                  // Done when engine is idle

//     assign  afu_cfg_terminate_in_progress    =  cfg_terminate_process_pending_q;  // -- reflect pending back to cfg logic
//     assign  afu_cfg_terminate_in_progress = 1'b0;   // Always say we are done
  assign  afu_cfg_terminate_in_progress  =  cfg_terminate_process_pending_q;

  assign  cfg_terminate_pasid_en      =  cfg_terminate_process;
  assign  cfg_terminate_pasid_d[19:0] =  cfg_afu_terminate_pasid[19:0];   // -- Capture in 200 MHz latches - to be decoded in 512 way decoder

  assign  cfg_terminate_pasid_match   =  cfg_terminate_pasid_q[9:0] == afu_pasid_q[9:0];
  assign  cfg_terminate_match_pending =  cfg_terminate_process_pending_q & cfg_terminate_pasid_match;

  assign  force_disable  = cfg_terminate_match_pending | fatal_error_inject_q;

 // --                                               .     |     .     |     .     |     .     |     .     |     .     |     .     |     .
 // --                                                      ______________________________________________________________________________
 // -- cfg_afu_terminate_valid        (400)          ______/ ... /    
 // --                                                      ______________________________________________________________________________
 // -- cfg_afu_terminate_pasid[19:0]  (400)          ------< ... <________________________________________________________________________
 // --                                                                  __________________________________________________________________
 // -- cfg_afu_terminate_valid_dly1_q (200)          __________________|     
 // --                                                      ___________
 // -- cfg_terminate_process          (200)          ______| ... |     |__________________________________________________________________
 // --                                                      ___________
 // -- cfg_terminate_process_d        (200)          ______| ... |     |__________________________________________________________________
 // --                                                                  ___________
 // -- cfg_terminate_process_q        (200)          __________________|           |______________________________________________________
 // --                                                      ___________                                           ___________
 // -- cfg_terminate_process_pending_en  (200)       ______| ... |     |_________________________________________|           |____________
 // --                                                      ___________
 // -- cfg_terminate_process_pending_d   (200)       ______| ... |     |__________________________________________________________________
 // --                                                                  _____________________________________________________
 // -- cfg_terminate_process_pending_q   (200)       __________________|                                                     |____________
 // --                                                      ___________
 // -- cfg_terminate_pasid_en         (200)          ______| ... |     |__________________________________________________________________
 // --                                                      ______________________________________________________________________________
 // -- cfg_terminate_pasid_d[19:0]    (200)          ------< ... <________________________________________________________________________
 // --                                                                  __________________________________________________________________
 // -- cfg_terminate_pasid_q[19:0]    (200)          ------------------<__________________________________________________________________
 // --                                                                                                            ___________
 // -- weq_mmio_terminate_process_done (200)         ____________________________________________________________|           |____________
 // --                                                                                                            ___________
 // -- cfg_terminate_process_done      (200)         ____________________________________________________________|           |____________
 // -- 

  // -- intrpt_ctl writes
//     assign  wr_intrpt_ctl_pending_en  =  ( wr_intrpt_ctl ||  weq_mmio_wr_intrpt_ctl_done_q || reset );
//     assign  wr_intrpt_ctl_pending_d   =  ( wr_intrpt_ctl && ~weq_mmio_wr_intrpt_ctl_done_q );
//     assign  wr_intrpt_ctl_done        =  ( wr_intrpt_ctl_pending_q && weq_mmio_wr_intrpt_ctl_done_q );
  assign  wr_intrpt_ctl_pending_en  =  ( wr_intrpt_ctl ||  wr_intrpt_ctl_pending_q || reset );
  assign  wr_intrpt_ctl_pending_d   =  ( wr_intrpt_ctl && ~weq_mmio_wr_intrpt_ctl_done_q );
  assign  wr_intrpt_ctl_done        =  ( wr_intrpt_ctl_pending_q );

  // -- intrpt_ctl reads
  assign  rd_intrpt_ctl_pending_en  =  ( rd_intrpt_ctl ||  weq_mmio_rd_intrpt_ctl_valid_q || reset );
  assign  rd_intrpt_ctl_pending_d   =  ( rd_intrpt_ctl && ~weq_mmio_rd_intrpt_ctl_valid_q ); 
  assign  rd_intrpt_ctl_valid       =  ( rd_intrpt_ctl_pending_q && weq_mmio_rd_intrpt_ctl_valid_q );

  // -- intrpt_obj writes
//     assign  wr_intrpt_obj_pending_en  =  ( wr_intrpt_obj ||  weq_mmio_wr_intrpt_obj_done_q || reset );
//     assign  wr_intrpt_obj_pending_d   =  ( wr_intrpt_obj && ~weq_mmio_wr_intrpt_obj_done_q );
//     assign  wr_intrpt_obj_done        =  ( wr_intrpt_obj_pending_q && weq_mmio_wr_intrpt_obj_done_q );
  assign  wr_intrpt_obj_pending_en  =  ( wr_intrpt_obj ||  wr_intrpt_obj_pending_q || reset );
  assign  wr_intrpt_obj_pending_d   =  ( wr_intrpt_obj );
  assign  wr_intrpt_obj_done        =  ( wr_intrpt_obj_pending_q );

  // -- intrpt_obj reads
  assign  rd_intrpt_obj_pending_en  =  ( rd_intrpt_obj ||  weq_mmio_rd_intrpt_obj_valid_q || reset );
  assign  rd_intrpt_obj_pending_d   =  ( rd_intrpt_obj && ~weq_mmio_rd_intrpt_obj_valid_q ); 
  assign  rd_intrpt_obj_valid       =  ( rd_intrpt_obj_pending_q && weq_mmio_rd_intrpt_obj_valid_q );

  // -- intrpt_data writes
//     assign  wr_intrpt_data_pending_en =  ( wr_intrpt_data ||  weq_mmio_wr_intrpt_data_done_q || reset );
//     assign  wr_intrpt_data_pending_d  =  ( wr_intrpt_data && ~weq_mmio_wr_intrpt_data_done_q );
//     assign  wr_intrpt_data_done       =  ( wr_intrpt_data_pending_q && weq_mmio_wr_intrpt_data_done_q );
  assign  wr_intrpt_data_pending_en =  ( wr_intrpt_data ||  wr_intrpt_data_pending_q || reset );
  assign  wr_intrpt_data_pending_d  =  ( wr_intrpt_data );
  assign  wr_intrpt_data_done       =  ( wr_intrpt_data_pending_q );

  // -- intrpt_data reads
  assign  rd_intrpt_data_pending_en =  ( rd_intrpt_data ||  weq_mmio_rd_intrpt_data_valid_q || reset );
  assign  rd_intrpt_data_pending_d  =  ( rd_intrpt_data && ~weq_mmio_rd_intrpt_data_valid_q ); 
  assign  rd_intrpt_data_valid      =  ( rd_intrpt_data_pending_q && weq_mmio_rd_intrpt_data_valid_q );

  // -- Drive Request to WEQ (latch into 200 MHz domain first for timing - used to block engine enablement in WEQ)
  assign  mmio_weq_restart_process_d =  ( mmio_restart_process_dly1_q || mmio_restart_process_dly2_q );  // -- 2 cycle pulse (1 cycle in WEQ)

  // -- ********************************************************************************************************************************
  // -- MMIO Access logic for MMIO ping-pong latency tests
  // -- ********************************************************************************************************************************

  // Scorecard logic - trigger MMIO ping-pong once large data is all set up, based on load size
  // Probably could get by with 4 bits & require 128B Writes, but expanded to 8 bits in case of 64B Writes
  assign scorecard_size[7:0]  =   (mmio_eng_mmio_lat_mode_sz_512_ld_q == 1'b1)  ?  8'b11111111  :    // 512 B
                                  (mmio_eng_ld_size_q == 2'b11)                 ?  8'b00001111  :    // 256 B
                                                                                   8'b00000011 ;     // 128 B

  assign  clear_scorecard  =  reset |
                              mmio_access_misc |    // start off clean when trigger select is written
                              mmio_scorecard_complete;

  assign  large_data_scorecard_d[7]  =  (large_data_scorecard_q[7]  |  (mmio_access_large_data3 & mmio_early_large_wr_half_en_q[1])) & ~clear_scorecard;
  assign  large_data_scorecard_d[6]  =  (large_data_scorecard_q[6]  |  (mmio_access_large_data3 & mmio_early_large_wr_half_en_q[0])) & ~clear_scorecard;
  assign  large_data_scorecard_d[5]  =  (large_data_scorecard_q[5]  |  (mmio_access_large_data2 & mmio_early_large_wr_half_en_q[1])) & ~clear_scorecard;
  assign  large_data_scorecard_d[4]  =  (large_data_scorecard_q[4]  |  (mmio_access_large_data2 & mmio_early_large_wr_half_en_q[0])) & ~clear_scorecard;
  assign  large_data_scorecard_d[3]  =  (large_data_scorecard_q[3]  |  (mmio_access_large_data1 & mmio_early_large_wr_half_en_q[1])) & ~clear_scorecard;
  assign  large_data_scorecard_d[2]  =  (large_data_scorecard_q[2]  |  (mmio_access_large_data1 & mmio_early_large_wr_half_en_q[0])) & ~clear_scorecard;
  assign  large_data_scorecard_d[1]  =  (large_data_scorecard_q[1]  |  (mmio_access_large_data0 & mmio_early_large_wr_half_en_q[1])) & ~clear_scorecard;
  assign  large_data_scorecard_d[0]  =  (large_data_scorecard_q[0]  |  (mmio_access_large_data0 & mmio_early_large_wr_half_en_q[0])) & ~clear_scorecard;

  assign  mmio_scorecard_complete  =  (large_data_scorecard_q[7:0] == scorecard_size[7:0]);

  // Use early signal for writes.  Start processing for MMIO Ping-Pong while TLX FIFO is accessed.  Registers will be written by the time we need the data.
  //assign  mmio_access_dly1_d  =  ( mmio_rd_q | mmio_wr_q ) & ~rd_afu_perf_count_d;
  assign  mmio_access_enable_reg     =  ( mmio_rd_q & addr_is_afu_enable )   | ( mmio_early_wr_q & early_addr_is_afu_enable_q );
  assign  mmio_access_extra_ea       =  ( mmio_rd_q & addr_is_afu_extra_ea ) | ( mmio_early_wr_q & early_addr_is_afu_extra_ea_q );
  assign  mmio_access_misc           =  ( mmio_rd_q & addr_is_afu_misc )     | ( mmio_early_wr_q & early_addr_is_afu_misc_q );
  assign  mmio_access_large_data0    =  ( mmio_large_rd_q & addr_is_large_ping_pong_data0 ) | ( mmio_early_large_wr_q & early_addr_is_large_ping_pong_data0_q );
  assign  mmio_access_large_data1    =  ( mmio_large_rd_q & addr_is_large_ping_pong_data1 ) | ( mmio_early_large_wr_q & early_addr_is_large_ping_pong_data1_q );
  assign  mmio_access_large_data2    =  ( mmio_large_rd_q & addr_is_large_ping_pong_data2 ) | ( mmio_early_large_wr_q & early_addr_is_large_ping_pong_data2_q );
  assign  mmio_access_large_data3    =  ( mmio_large_rd_q & addr_is_large_ping_pong_data3) | ( mmio_early_large_wr_q & early_addr_is_large_ping_pong_data3_q );

  assign  mmio_access_dly1_d  =  (mmio_lat_trigger_src == 2'b11) ?  mmio_scorecard_complete :
                                 (mmio_lat_trigger_src == 2'b01) ?  mmio_access_large_data0 :
                                                                    (mmio_access_enable_reg | mmio_access_extra_ea);  // -- Choose which register access triggers MMIO Ping-Pong Latency DMA Write
  assign  mmio_access_dly2_d  =  mmio_access_dly1_q;

  //assign  mmio_arb_mmio_access  =  mmio_access_dly1_d | mmio_access_dly1_q;  // -- 2 cycle pulse (1 cycle in ARB)
  assign  mmio_arb_mmio_access  =  mmio_access_dly1_q | mmio_access_dly2_q;  // -- 2 TLX-cycle pulse (1 AFU-cycle)

  // -- ********************************************************************************************************************************
  // -- Terminate Queue - 200 MHz clock domain
  // -- ********************************************************************************************************************************

/*      mcp3_decoder9x512  mmio_terminate_pasid_decoder
    (
      .din        ( mmio_terminate_pasid_q[8:0] ),
      .dout       ( mmio_terminate_pasid_decoded[511:0] )
    );

  mcp3_decoder9x512  cfg_terminate_pasid_decoder
    (
      .din        ( cfg_terminate_pasid_q[8:0] ),
      .dout       ( cfg_terminate_pasid_decoded[511:0] )
    );

  always @*
    begin
      if ( mmio_terminate_process_q )
        set_nxt_terminate_req_mmio[511:0] =  mmio_terminate_pasid_decoded[511:0];
      else
        set_nxt_terminate_req_mmio[511:0] =  512'b0;

      if ( cfg_terminate_process_q )
        set_nxt_terminate_req_cfg[511:0]  =  cfg_terminate_pasid_decoded[511:0];
      else
        set_nxt_terminate_req_cfg[511:0]  =  512'b0;
    end  // -- always @*

  // -- Create set term
  assign  set_nxt_terminate_req[511:0] =  ( set_nxt_terminate_req_mmio[511:0] | set_nxt_terminate_req_cfg[511:0] ); 

  // -- Create clr term
  assign  clr_nxt_terminate_req[511:0] =  nxt_terminate_arb_winner_decoded[511:0];

  // -- set or reset the process request latches (clear all on master reset)
  always @*
    begin
      if ( ~reset )
        nxt_terminate_req_d[511:0] =  ( set_nxt_terminate_req[511:0] | ( nxt_terminate_req_q[511:0] & ~clr_nxt_terminate_req[511:0] ));
      else
        nxt_terminate_req_d[511:0] =  512'b0;
    end  // -- always @*

  assign  nxt_terminate_req_taken        =  nxt_terminate_arb_winner_valid && ~terminate_process_pending_q;        // -- Block taken if already one pending

  // -- Track terminate Pending - this will block nxt_terminate_req_taken until it clears
  assign  terminate_process_pending_en =  ( nxt_terminate_req_taken ||  terminate_process_done || reset );
  always @*
    begin
      if ( ~reset )
        terminate_process_pending_d  =  ( nxt_terminate_req_taken && ~terminate_process_done );
      else
        terminate_process_pending_d  =  1'b0;
    end  // -- always @*

  assign  terminate_process_done       =  ( terminate_process_pending_q && weq_mmio_terminate_process_done );

  // -- Capture and hold pasid corresponding to current terminate in progress
  assign  terminate_pasid_en       =  nxt_terminate_req_taken;
  assign  terminate_pasid_d[19:0]  =  { 11'b0, nxt_terminate_arb_winner_encoded[8:0] };  


  // -- Capture elongated request in a 200MHz latch
  assign  terminate_process_d =  nxt_terminate_req_taken; // -- 200 MHz pulse to WEQ

  // -- Drive request to WEQ off 200 MHz latch
  assign  mmio_weq_terminate_process     =  terminate_process_q;
  assign  mmio_weq_terminate_pasid[19:0] =  terminate_pasid_q[19:0];


  // --                                  ___________ ___________ ___________________________________ ___________________________________
  // -- nxt_terminate_arb_winner_encoded ____BBB____X___000_____X____CCC____________________________X____000____________________________
  // --                                  ___________             ___________________________________
  // -- nxt_terminate_arb_winner_valid              |___________|                                   |___________________________________
  // --                                        _____                                           _____
  // -- nxt_terminate_req_taken   ____________|     |_________________________________________|     |___________________________________
  // --                                                                                  _____
  // -- terminate_process_done    ______________________________________________________|     |_________________________________________
  // --                                        _____                                           _____
  // -- terminate_pasid_en        ____________|     |_________________________________________|     |___________________________________
  // --                           __________________ ___________ ___________________________________ ___________________________________
  // -- terminate_pasid_d[19:0]   ___________BBB____X____000____X_____CCC___________________________X____000____________________________
  // --                           __________________ _______________________________________________ ___________________________________
  // -- terminate_pasid_q[19:0]   ___________AAA____X_____BBB_______________________________________X____CCC____________________________
  // --                                        _____                                           _____
  // -- terminate_process_d       ____________|     |_________________________________________|     |___________________________________
  // --                                        _____                                     ___________
  // -- terminate_process_pending_en _________|     |___________________________________|           |___________________________________
  // --                                        _____
  // -- terminate_process_pending_d  _________|     |___________________________________________________________________________________
  // --                                              _________________________________________       ___________________________________
  // -- terminate_process_pending_q  _______________|                                         |_____|
  // --                                              _____                                           _____
  // -- terminate_process_q       __________________|     |_________________________________________|     |_____________________________
  // --                                              _____                                           _____
  // -- mmio_weq_terminate_process__________________|     |_________________________________________|     |_____________________________
  // --                           __________________ _______________________________________________ ___________________________________
  // -- mmio_weq_terminate_pasid[19:0]_______AAA____X_____BBB_______________________________________X____CCC____________________________


  // --                                              _____                                           _____
  // -- mmio_weq_terminate_process_d________________|     |_________________________________________|     |_____________________________
  // --                                              _____                                           _____
  // -- mmio_weq_terminate_pasid_en ________________|     |_________________________________________|     |_____________________________
  // --                                   __________ _______________________________________________ ___________________________________
  // -- mmio_weq_terminate_pasid_d[19:0]  ___AAA____X_____BBB_______________________________________X_____CCC___________________________
  // --                                                    _____                                           _____
  // -- mmio_weq_terminate_process_q______________________|     |_________________________________________|     |_______________________
  // --                                   ________________ _____________________________________________________________________________
  // -- mmio_weq_terminate_pasid_q[19:0]  _________AAA____X_____BBB_______________________________________X____CCC______________________


  // -- ********************************************************************************************************************************
  // -- Arbiter to choose next Terminate request from the Terminate Queue to process
  // -- ********************************************************************************************************************************

  // -- NOTE: arbitration is 3 cycles. 
  assign  nxt_terminate_arb_reset =  reset;

  mcp3_arb512  nxt_term_arb
    (
     .clock                  ( clock_afu ),
     .reset                  ( nxt_terminate_arb_reset ),
     // -- input request
     .req_taken              ( nxt_terminate_req_taken ),                 // -- IN
     .req_bus                ( nxt_terminate_req_q[511:0] ),              // -- IN 
     // -- arbiter results
     .final_valid            ( nxt_terminate_arb_winner_valid ),          // -- OUT
     .final_winner           ( nxt_terminate_arb_winner_encoded[8:0] ),   // -- OUT
     .req_clear              ( nxt_terminate_arb_winner_decoded[511:0] )  // -- OUT
   );
*/

  // -- ********************************************************************************************************************************
  // -- Update or hold register contents
  // -- ********************************************************************************************************************************

  always @*
    begin
      // -- AFU Config
      if ( reset )
        afu_config_d[63:0] =  64'b0;
      else if ( wr_afu_config_q )
        afu_config_d[63:0] =  mmio_wrdata_q[63:0];
      else
        afu_config_d[63:0] =  afu_config_q[63:0];

      // -- AFU Config2
      if ( reset )
        afu_config2_d[35:0] =  36'b0;
      else if ( wr_afu_config2_q )
        afu_config2_d[35:0] =  mmio_wrdata_q[35:0];
      else
        afu_config2_d[35:0] =  afu_config2_q[35:0];

      // -- AFU Error
      if ( reset )
        afu_error_d[15:0] =  16'b0;
      else if ( wr_afu_error_q )
        afu_error_d[15:0] =  mmio_wrdata_q[15:0];
      else if ( mmio_rd_dly1_q || mmio_wr_dly1_q || mmio_large_rd_dly1_q || mmio_large_wr_dly1_q )
  // -- afu_error_d[15:0] =  { mmio_wrdata_q[15:2], mmio_bad_op_or_align_q, mmio_addr_not_implemented_q };  // -- joek fixed 6/22/18
        afu_error_d[15:0] =  {   afu_error_q[15:2], mmio_bad_op_or_align_q, mmio_addr_not_implemented_q };  // -- joek fixed 6/22/18
      else
        afu_error_d[15:0] =  afu_error_q[15:0];

      // -- AFU Error Info                                                                                                                    
      if ( reset )
        afu_error_info_d[31:0] =  32'b0;
      else if ( wr_afu_error_info_q )
        afu_error_info_d[31:0] =  mmio_wrdata_q[31:0];
      else if ( mmio_bad_op_or_align_q || mmio_addr_not_implemented_q )
        afu_error_info_d[31:0] =  { mmio_large_rd_dly1_q, mmio_large_wr_dly1_q, mmio_rd_dly1_q, mmio_wr_dly1_q, 2'b0, mmio_addr_q[25:0] };
      else
        afu_error_info_d[31:0] =  afu_error_info_q[31:0];

      // -- AFU Trace Ctl
      if ( reset )
        afu_trace_ctl_d[63:0] =  64'h0000_0000_0023_3333;
      else if ( wr_afu_trace_ctl_q )
        afu_trace_ctl_d[63:0] =  mmio_wrdata_q[63:0];
      else
        afu_trace_ctl_d[63:0] =  { 1'b0, afu_trace_ctl_q[62:52], 1'b0, afu_trace_ctl_q[50:40], 1'b0, afu_trace_ctl_q[38:0] };

      // -- AFU Stats
      if ( reset )
        afu_stats_d[63:0] =  64'b0;
      else if ( wr_afu_stats_q )
        afu_stats_d[63:0]  =  mmio_wrdata_q[63:0];
      else
        afu_stats_d[63]    =  ~sim_idle_eng;
        afu_stats_d[62:32] =  31'b0;
        afu_stats_d[31]    =  ~sim_idle_rspi;
        afu_stats_d[30]    =  ~sim_idle_cmdo;
        afu_stats_d[29]    =  ~sim_idle_arb;
        afu_stats_d[28]    =  ~sim_idle_weq;
        afu_stats_d[27]    =  ~sim_idle_mmio_int;
        afu_stats_d[26]    =  ~sim_idle_cmdi_rspo;
        afu_stats_d[25:20] =   6'b0;
        afu_stats_d[19:12] = { 1'b0, rspi_mmio_resp_queue_maxqdepth[6:0] };
        afu_stats_d[11:0]  = { 1'b0, rspi_mmio_max_outstanding_responses[10:0] };

      // -- AFU Object Handle
      if ( reset )
        afu_obj_handle_d[63:0] =  64'b0;
      else if ( wr_afu_obj_handle_q )
        afu_obj_handle_d[63:0] =  mmio_wrdata_q[63:0];
      else
        afu_obj_handle_d[63:0] =  afu_obj_handle_q[63:0];

      // -- AFU Extra EA
      if ( reset )
        afu_extra_ea_d[63:7] =  57'b0;
      else if ( wr_afu_extra_ea_q )
        afu_extra_ea_d[63:7] =  mmio_wrdata_q[63:7];
      else
        afu_extra_ea_d[63:7] =  afu_extra_ea_q[63:7];

      // -- AFU WED
      if ( reset )
        afu_wed_d[63:0] =  64'b0;
      else if ( wr_afu_wed_q )
        afu_wed_d[63:0] =  mmio_wrdata_q[63:0];
      else
        afu_wed_d[63:0] =  afu_wed_q[63:0];

      // -- AFU Bufmask
      if ( reset )
        afu_bufmask_d[31:12] =  20'b0;
      else if ( wr_afu_bufmask_q )
        afu_bufmask_d[31:12] =  mmio_wrdata_q[31:12];
      else
        afu_bufmask_d[31:12] =  afu_bufmask_q[31:12];

      // -- AFU PASID
      if ( reset )
        afu_pasid_d[9:0] =  10'b0;
      else if ( wr_afu_pasid_q )
        afu_pasid_d[9:0] =  mmio_wrdata_q[9:0];
      else
        afu_pasid_d[9:0] =  afu_pasid_q[9:0];

      // -- AFU Miscellaneous
      if ( reset )
        afu_misc_d[35:0] =  36'b0;
      else if ( wr_afu_misc_q )
        afu_misc_d[35:0] =  mmio_wrdata_q[35:0];
      else
        afu_misc_d[35:0] =  afu_misc_q[35:0];

      // -- AFU Enable
      if ( reset )
	afu_enable_d[63:57] =  7'b0;
      else if ( wr_afu_enable_q )
	  afu_enable_d[63:57] =  {(mmio_wrdata_q[63] & ~force_disable), mmio_wrdata_q[62:57]};
      else if ( force_disable )
        afu_enable_d[63:57] =  {1'b0, afu_enable_q[62:57]};
      else
        afu_enable_d[63:57] =  afu_enable_q[63:57];

      // -- AFU Control (Write-Only:  1 cycle pulse)
      if ( reset )
        afu_control_d[63:60] =  4'b0;
      else if ( wr_afu_control_q )
        afu_control_d[63:60] =  mmio_wrdata_q[63:60];
      else
        afu_control_d =  4'b0;

      // -- AFU Display Ctl
      if ( reset )
        afu_display_ctl_d[31:0] =  32'b0;
      else if ( wr_afu_display_ctl_q )
        afu_display_ctl_d[31:0] =  mmio_wrdata_q[31:0];
      else if ( autoincr_update_afu_display_ctl )
        afu_display_ctl_d[31:0] =  autoincr_nxt_afu_display_ctl[31:0];
      else
        afu_display_ctl_d[31:0] =  afu_display_ctl_q[31:0];

      // -- AFU Large Ping-Pong Data 0
      //if ( reset )   // Removed reset on data registers, due to large fanout, and not needed
      //  large_ping_pong_data0_d[1023:512] =  512'b0;
      //else
      if ( ld_resp_ping_pong_data_q[0] )
        large_ping_pong_data0_d[1023:512] =  eng_mmio_data_q[1023:512];
      else if ( wr_large_ping_pong_data0_q && mmio_large_wr_half_en_dly1_q[1])
        large_ping_pong_data0_d[1023:512] =  mmio_wrdata_q[1023:512];
      else
        large_ping_pong_data0_d[1023:512] =  large_ping_pong_data0_q[1023:512];

      //if ( reset )
      //  large_ping_pong_data0_d[511:0] =  512'b0;
      //else
      if ( ld_resp_ping_pong_data_q[0] )
        large_ping_pong_data0_d[511:0] =  eng_mmio_data_q[511:0];
      else if ( wr_large_ping_pong_data0_q && mmio_large_wr_half_en_dly1_q[0])
        large_ping_pong_data0_d[511:0] =  mmio_wrdata_q[511:0];
      else
        large_ping_pong_data0_d[511:0] =  large_ping_pong_data0_q[511:0];

      // -- AFU Large Ping-Pong Data 1
      //if ( reset )
      //  large_ping_pong_data1_d[1023:512] =  512'b0;
      //else
      if ( ld_resp_ping_pong_data_q[1] )
        large_ping_pong_data1_d[1023:512] =  eng_mmio_data_q[1023:512];
      else if ( wr_large_ping_pong_data1_q && mmio_large_wr_half_en_dly1_q[1])
        large_ping_pong_data1_d[1023:512] =  mmio_wrdata_q[1023:512];
      else
        large_ping_pong_data1_d[1023:512] =  large_ping_pong_data1_q[1023:512];

      //if ( reset )
      //  large_ping_pong_data1_d[511:0] =  512'b0;
      //else
      if ( ld_resp_ping_pong_data_q[1] )
        large_ping_pong_data1_d[511:0] =  eng_mmio_data_q[511:0];
      else if ( wr_large_ping_pong_data1_q && mmio_large_wr_half_en_dly1_q[0])
        large_ping_pong_data1_d[511:0] =  mmio_wrdata_q[511:0];
      else
        large_ping_pong_data1_d[511:0] =  large_ping_pong_data1_q[511:0];

      // -- AFU Large Ping-Pong Data 2
      //if ( reset )
      //  large_ping_pong_data2_d[1023:512] =  512'b0;
      //else
      if ( ld_resp_ping_pong_data_q[2] )
        large_ping_pong_data2_d[1023:512] =  eng_mmio_data_q[1023:512];
      else if ( wr_large_ping_pong_data2_q && mmio_large_wr_half_en_dly1_q[1])
        large_ping_pong_data2_d[1023:512] =  mmio_wrdata_q[1023:512];
      else
        large_ping_pong_data2_d[1023:512] =  large_ping_pong_data2_q[1023:512];

      //if ( reset )
      //  large_ping_pong_data2_d[511:0] =  512'b0;
      //else
      if ( ld_resp_ping_pong_data_q[2] )
        large_ping_pong_data2_d[511:0] =  eng_mmio_data_q[511:0];
      else if ( wr_large_ping_pong_data2_q && mmio_large_wr_half_en_dly1_q[0])
        large_ping_pong_data2_d[511:0] =  mmio_wrdata_q[511:0];
      else
        large_ping_pong_data2_d[511:0] =  large_ping_pong_data2_q[511:0];

      // -- AFU Large Ping-Pong Data 3
      //if ( reset )
      //  large_ping_pong_data3_d[1023:512] =  512'b0;
      //else
      if ( ld_resp_ping_pong_data_q[3] )
        large_ping_pong_data3_d[1023:512] =  eng_mmio_data_q[1023:512];
      else if ( wr_large_ping_pong_data3_q && mmio_large_wr_half_en_dly1_q[1])
        large_ping_pong_data3_d[1023:512] =  mmio_wrdata_q[1023:512];
      else
        large_ping_pong_data3_d[1023:512] =  large_ping_pong_data3_q[1023:512];

      //if ( reset )
      //  large_ping_pong_data3_d[511:0] =  512'b0;
      //else
      if ( ld_resp_ping_pong_data_q[3] )
        large_ping_pong_data3_d[511:0] =  eng_mmio_data_q[511:0];
      else if ( wr_large_ping_pong_data3_q && mmio_large_wr_half_en_dly1_q[0])
        large_ping_pong_data3_d[511:0] =  mmio_wrdata_q[511:0];
      else
        large_ping_pong_data3_d[511:0] =  large_ping_pong_data3_q[511:0];


   end  // -- always @*


  // -- ********************************************************************************************************************************
  // -- Formulate the Read Data for each register
  // -- ********************************************************************************************************************************

  // -- Convert the enabled pasid length into a mask
  always @*
    begin
      case ( cfg_afu_pasid_length_enabled[4:0] )
        5'b10011 :  cfg_afu_pasid_length[19:0] = 20'h80000;
        5'b10010 :  cfg_afu_pasid_length[19:0] = 20'h40000;
        5'b10001 :  cfg_afu_pasid_length[19:0] = 20'h20000;
        5'b10000 :  cfg_afu_pasid_length[19:0] = 20'h10000;
        5'b01111 :  cfg_afu_pasid_length[19:0] = 20'h08000;
        5'b01110 :  cfg_afu_pasid_length[19:0] = 20'h04000;
        5'b01101 :  cfg_afu_pasid_length[19:0] = 20'h02000;
        5'b01100 :  cfg_afu_pasid_length[19:0] = 20'h01000;
        5'b01011 :  cfg_afu_pasid_length[19:0] = 20'h00800;
        5'b01010 :  cfg_afu_pasid_length[19:0] = 20'h00400;
        5'b01001 :  cfg_afu_pasid_length[19:0] = 20'h00200;
        5'b01000 :  cfg_afu_pasid_length[19:0] = 20'h00100;
        5'b00111 :  cfg_afu_pasid_length[19:0] = 20'h00080;
        5'b00110 :  cfg_afu_pasid_length[19:0] = 20'h00040;
        5'b00101 :  cfg_afu_pasid_length[19:0] = 20'h00020;
        5'b00100 :  cfg_afu_pasid_length[19:0] = 20'h00010;
        5'b00011 :  cfg_afu_pasid_length[19:0] = 20'h00008;
        5'b00010 :  cfg_afu_pasid_length[19:0] = 20'h00004;
        5'b00001 :  cfg_afu_pasid_length[19:0] = 20'h00002;
        5'b00000 :  cfg_afu_pasid_length[19:0] = 20'h00001;
        default  :  cfg_afu_pasid_length[19:0] = 20'h80000;
      endcase
      case ( cfg_afu_pasid_length_enabled[4:0] )
        5'b10011 :  cfg_afu_pasid_mask_d[19:0] = 20'h80000;
        5'b10010 :  cfg_afu_pasid_mask_d[19:0] = 20'hC0000;
        5'b10001 :  cfg_afu_pasid_mask_d[19:0] = 20'hE0000;
        5'b10000 :  cfg_afu_pasid_mask_d[19:0] = 20'hF0000;
        5'b01111 :  cfg_afu_pasid_mask_d[19:0] = 20'hF8000;
        5'b01110 :  cfg_afu_pasid_mask_d[19:0] = 20'hFC000;
        5'b01101 :  cfg_afu_pasid_mask_d[19:0] = 20'hFE000;
        5'b01100 :  cfg_afu_pasid_mask_d[19:0] = 20'hFF000;
        5'b01011 :  cfg_afu_pasid_mask_d[19:0] = 20'hFF800;
        5'b01010 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFC00;
        5'b01001 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFE00;
        5'b01000 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFF00;
        5'b00111 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFF80;
        5'b00110 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFFC0;
        5'b00101 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFFE0;
        5'b00100 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFFF0;
        5'b00011 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFFF8;
        5'b00010 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFFFC;
        5'b00001 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFFFE;
        5'b00000 :  cfg_afu_pasid_mask_d[19:0] = 20'hFFFFF;
        default  :  cfg_afu_pasid_mask_d[19:0] = 20'h00000;
      endcase
    end  // -- always @*

  // -- Forward the calculated pasid mask to cmdo module
  assign  mmio_cmdo_pasid_mask[19:0] =  cfg_afu_pasid_mask_q[19:0];


  assign  process_handle[19:0] =   (    cfg_afu_pasid_base[19:0]   &  cfg_afu_pasid_mask_q[19:0] ) |
                                   ( { 11'b0, mmio_addr_q[24:16] } & ~cfg_afu_pasid_mask_q[19:0] );


  assign  rddata_afu_config     [63:0] =                afu_config_q[63:0];
  assign  rddata_afu_config2    [63:0] =  { 28'b0,     afu_config2_q[35:0] };
  assign  rddata_afu_error      [63:0] =  { 48'b0,       afu_error_q[15:0] };
  assign  rddata_afu_error_info [63:0] =  { 32'b0,  afu_error_info_q[31:0] };
  assign  rddata_afu_trace_ctl  [63:0] =             afu_trace_ctl_q[63:0];
  assign  rddata_afu_stats      [63:0] =  {              afu_stats_q[63:0] };
  assign  rddata_afu_obj_handle [63:0] =  {         afu_obj_handle_q[63:0] };
  assign  rddata_afu_extra_ea   [63:0] =  { afu_extra_ea_q[63:7],     7'b0 };
  assign  rddata_afu_wed        [63:0] =  {                afu_wed_q[63:0] };
  assign  rddata_afu_bufmask    [63:0] =  { 32'b0,     afu_bufmask_q[31:12], 12'b0 };
  assign  rddata_afu_pasid      [63:0] =  { 54'b0,        afu_pasid_q[9:0] };
  assign  rddata_afu_misc       [63:0] =  { 28'b0,        afu_misc_q[35:0] };
  assign  rddata_afu_enable     [63:0] =  { afu_enable_q[63:57],     57'b0 };
  assign  rddata_afu_control    [63:0] =  { afu_control_q[63:60],    60'b0 };
  assign  rddata_afu_display_ctl[63:0] =  { 32'b0, afu_display_ctl_q[31:0] };

  assign  rddata_large_ping_pong_data0[1023:0] =  large_ping_pong_data0_q[1023:0];
  assign  rddata_large_ping_pong_data1[1023:0] =  large_ping_pong_data1_q[1023:0];
  assign  rddata_large_ping_pong_data2[1023:0] =  large_ping_pong_data2_q[1023:0];
  assign  rddata_large_ping_pong_data3[1023:0] =  large_ping_pong_data3_q[1023:0];

  always @*
    begin
      if ( ~mmio_eng_memcpy2_format_enable_d )
        begin
          rddata_process_handle[63:0] =  { 44'b0,   process_handle[19:0] };
          rddata_process_ctl[63:0]    =  { 63'b0, mmio_restart_process_pending_q };
        end
      else
        begin
          rddata_process_handle[63:0] =  { process_handle[19:0], 44'b0 };  // -- MemCpy2 Backward compatibility
          rddata_process_ctl[63:0]    =  { mmio_restart_process_pending_q, 63'b0 };
        end
    end  // -- always @*

  assign  rddata_weq_en      =  ( weq_mmio_rd_wed_valid || weq_mmio_rd_process_status_valid || weq_mmio_rd_intrpt_ctl_valid || weq_mmio_rd_intrpt_obj_valid || weq_mmio_rd_intrpt_data_valid );   // -- Timing fix
  assign  rddata_weq_d[63:0] =  weq_mmio_rddata[63:0];  // -- Timing fix - Latch the inbound rddata from WEQ


   // -- ********************************************************************************************************************************
   // -- Latch Before driving output
   // -- ********************************************************************************************************************************

  assign  rd_afu_config_d      =  rd_afu_config;       // -- Timing fix
  assign  rd_afu_config2_d     =  rd_afu_config2;      // -- Timing fix
  assign  rd_afu_error_d       =  rd_afu_error;        // -- Timing fix
  assign  rd_afu_error_info_d  =  rd_afu_error_info;   // -- Timing fix
  assign  rd_afu_trace_ctl_d   =  rd_afu_trace_ctl;    // -- Timing fix
  assign  rd_afu_stats_d       =  rd_afu_stats;        // -- Timing fix
  assign  rd_afu_obj_handle_d  =  rd_afu_obj_handle;   // -- Timing fix
  assign  rd_afu_extra_ea_d    =  rd_afu_extra_ea;     // -- Timing fix
  assign  rd_afu_wed_d         =  rd_afu_wed;          // -- Timing fix
  assign  rd_afu_bufmask_d     =  rd_afu_bufmask;      // -- Timing fix
  assign  rd_afu_pasid_d       =  rd_afu_pasid;        // -- Timing fix
  assign  rd_afu_misc_d        =  rd_afu_misc;         // -- Timing fix
  assign  rd_afu_enable_d      =  rd_afu_enable;       // -- Timing fix
  assign  rd_afu_control_d     =  rd_afu_control;      // -- Timing fix
  assign  rd_afu_display_ctl_d =  rd_afu_display_ctl;  // -- Timing fix
  assign  rd_process_handle_d  =  rd_process_handle;   // -- Timing fix
  assign  rd_process_ctl_d     =  rd_process_ctl;      // -- Timing fix
  assign  rd_large_ping_pong_data0_d  = rd_large_ping_pong_data0;  // -- Timing fix
  assign  rd_large_ping_pong_data1_d  = rd_large_ping_pong_data1;  // -- Timing fix
  assign  rd_large_ping_pong_data2_d  = rd_large_ping_pong_data2;  // -- Timing fix
  assign  rd_large_ping_pong_data3_d  = rd_large_ping_pong_data3;  // -- Timing fix

  assign  wr_afu_config_d       =  wr_afu_config;        // -- Timing fix
  assign  wr_afu_config2_d      =  wr_afu_config2;       // -- Timing fix
  assign  wr_afu_error_d        =  wr_afu_error;         // -- Timing fix
  assign  wr_afu_error_info_d   =  wr_afu_error_info;    // -- Timing fix
  assign  wr_afu_trace_ctl_d    =  wr_afu_trace_ctl;     // -- Timing fix
  assign  wr_afu_stats_d        =  wr_afu_stats;         // -- Timing fix
  assign  wr_afu_obj_handle_d   =  wr_afu_obj_handle;    // -- Timing fix
  assign  wr_afu_extra_ea_d     =  wr_afu_extra_ea;      // -- Timing fix
  assign  wr_afu_wed_d          =  wr_afu_wed;           // -- Timing fix
  assign  wr_afu_bufmask_d      =  wr_afu_bufmask;       // -- Timing fix
  assign  wr_afu_pasid_d        =  wr_afu_pasid;         // -- Timing fix
  assign  wr_afu_misc_d         =  wr_afu_misc;          // -- Timing fix
  assign  wr_afu_enable_d       =  wr_afu_enable;        // -- Timing fix
  assign  wr_afu_control_d      =  wr_afu_control;       // -- Timing fix
  assign  wr_afu_latency_d      =  wr_afu_latency;       // -- Timing fix
  assign  wr_afu_display_ctl_d  =  wr_afu_display_ctl;   // -- Timing fix
  assign  wr_afu_display_data_d =  wr_afu_display_data;  // -- Timing fix
  assign  wr_afu_perf_count_d   =  wr_afu_perf_count;    // -- Timing fix
  assign  wr_process_ctl_d      =  wr_process_ctl &&  (( ~mmio_eng_memcpy2_format_enable_d && ( mmio_wrdata_q[1:0]   == 2'b00 )) ||
                                                       (  mmio_eng_memcpy2_format_enable_d && ( mmio_wrdata_q[63:62] == 2'b00 )));  // -- MemCpy2 Backward Compatibility
                                                       // -- Note: The above is ONLY to handle creating a response when an unexpected write occurs
                                  
  assign  wr_large_ping_pong_data0_d  = wr_large_ping_pong_data0;  // -- Timing fix
  assign  wr_large_ping_pong_data1_d  = wr_large_ping_pong_data1;  // -- Timing fix
  assign  wr_large_ping_pong_data2_d  = wr_large_ping_pong_data2;  // -- Timing fix
  assign  wr_large_ping_pong_data3_d  = wr_large_ping_pong_data3;  // -- Timing fix

  assign  use_ld_resp_data               =  mmio_lat_mode_int && mmio_lat_extra_read_int;
  assign  ld_resp_ping_pong_data_d[3:0]  =  {4{use_ld_resp_data}} & eng_mmio_extra_read_resp[3:0];

  assign  eng_mmio_data_d[1023:0]  =  eng_mmio_data[1023:0];

  assign  rd_weq_valid         =  ( rd_wed_valid || rd_process_status_valid || rd_intrpt_ctl_valid || rd_intrpt_obj_valid || rd_intrpt_data_valid ); 


  //assign  mmio_bad_op_or_align_d      =  (( mmio_rd_q || mmio_wr_q ) && bad_op_or_align );
  assign  mmio_bad_op_or_align_d      =  bad_op_or_align ;  // mmio_rd, mmio_wr, mmio_large_rd/wr already feed into this signal
  assign  mmio_addr_not_implemented_d =  (( mmio_rd_q || mmio_wr_q || mmio_large_rd_q || mmio_large_wr_q ) && addr_not_implemented );

  assign  mmio_wr_done_d =  wr_afu_config_q       || 
                            wr_afu_config2_q      || 
                            wr_afu_error_q        || 
                            wr_afu_error_info_q   || 
                            wr_afu_trace_ctl_q    ||
                            wr_afu_stats_q        ||
                            wr_afu_obj_handle_q   ||
                            wr_afu_extra_ea_q     ||
                            wr_afu_wed_q          ||
                            wr_afu_bufmask_q      ||
                            wr_afu_pasid_q	  ||
                            wr_afu_misc_q	  ||
                            wr_afu_enable_q       ||
                            wr_afu_control_q      ||
                            wr_afu_latency_q      ||   // Include Read-Only regs, so that any writes complete instead of hanging
                            wr_afu_display_ctl_q  ||
                            wr_afu_display_data_q ||
                            wr_afu_perf_count_q   ||
                            wr_large_ping_pong_data0_q  ||
                            wr_large_ping_pong_data1_q  ||
                            wr_large_ping_pong_data2_q  ||
                            wr_large_ping_pong_data3_q  ||
                            wr_process_ctl_q      ||
                            wr_wed_done           ||
                            mmio_restart_process_done ||
                            mmio_terminate_process_dly1_q ||  // -- Give immediate response back on terminate requests
                            wr_intrpt_ctl_done || 
                            wr_intrpt_obj_done || 
                            wr_intrpt_data_done; 

  assign  mmio_rddata_valid_d =  rd_afu_config_q      || 
                                 rd_afu_config2_q     || 
                                 rd_afu_error_q       || 
                                 rd_afu_error_info_q  || 
                                 rd_afu_trace_ctl_q   || 
                                 rd_afu_stats_q       ||
                                 rd_afu_obj_handle_q  ||
                                 rd_afu_extra_ea_q    ||
                                 rd_afu_wed_q         ||
                                 rd_afu_bufmask_q     ||
                                 rd_afu_pasid_q       ||
                                 rd_afu_misc_q        ||
                                 rd_afu_enable_q      ||
                                 rd_afu_control_q     ||
                                 rd_afu_display_ctl_q ||
                                 rd_afu_display_data_valid ||
                                 rd_afu_perf_count_valid   ||
                                 rd_large_ping_pong_data0_q  ||
                                 rd_large_ping_pong_data1_q  ||
                                 rd_large_ping_pong_data2_q  ||
                                 rd_large_ping_pong_data3_q  ||
                                 rd_process_handle_q       ||
                                 rd_process_ctl_q          || 
                                 rd_weq_valid;

  always @*
    begin
      mmio_rddata_d[1023:0] = 1024'b0;  
      if ( rd_afu_config_q           )   mmio_rddata_d[63:0] =  rddata_afu_config[63:0];    
      if ( rd_afu_config2_q          )   mmio_rddata_d[63:0] =  rddata_afu_config2[63:0];    
      if ( rd_afu_error_q            )   mmio_rddata_d[63:0] =  rddata_afu_error[63:0];     
      if ( rd_afu_error_info_q       )   mmio_rddata_d[63:0] =  rddata_afu_error_info[63:0];
      if ( rd_afu_trace_ctl_q        )   mmio_rddata_d[63:0] =  rddata_afu_trace_ctl[63:0]; 
      if ( rd_afu_stats_q            )   mmio_rddata_d[63:0] =  rddata_afu_stats[63:0];
      if ( rd_afu_obj_handle_q       )   mmio_rddata_d[63:0] =  rddata_afu_obj_handle[63:0];
      if ( rd_afu_extra_ea_q         )   mmio_rddata_d[63:0] =  rddata_afu_extra_ea[63:0];
      if ( rd_afu_wed_q              )   mmio_rddata_d[63:0] =  rddata_afu_wed[63:0];
      if ( rd_afu_bufmask_q          )   mmio_rddata_d[63:0] =  rddata_afu_bufmask[63:0];
      if ( rd_afu_pasid_q            )   mmio_rddata_d[63:0] =  rddata_afu_pasid[63:0];
      if ( rd_afu_misc_q             )   mmio_rddata_d[63:0] =  rddata_afu_misc[63:0];
      if ( rd_afu_enable_q           )   mmio_rddata_d[63:0] =  rddata_afu_enable[63:0];
      if ( rd_afu_control_q          )   mmio_rddata_d[63:0] =  rddata_afu_control[63:0];

      if ( rd_afu_display_ctl_q      )   mmio_rddata_d[63:0] =  rddata_afu_display_ctl[63:0];  
      if ( rd_afu_display_data_valid )   mmio_rddata_d[63:0] =  rddata_afu_display_data_q[63:0];  
      if ( rd_afu_perf_count_valid   )   mmio_rddata_d[63:0] =  rddata_afu_perf_count_q[63:0];  
      if ( rd_process_handle_q       )   mmio_rddata_d[63:0] =  rddata_process_handle[63:0];
      if ( rd_process_ctl_q          )   mmio_rddata_d[63:0] =  rddata_process_ctl[63:0];           // -- This is all zeros
      if ( rd_weq_valid              )   mmio_rddata_d[63:0] =  rddata_weq_q[63:0]; 

      // For large reads, send all 128B to cmdi_rspo.  It will select proper half for 64B reads.
      if ( rd_large_ping_pong_data0_q)   mmio_rddata_d[1023:0] =  rddata_large_ping_pong_data0[1023:0];
      if ( rd_large_ping_pong_data1_q)   mmio_rddata_d[1023:0] =  rddata_large_ping_pong_data1[1023:0];
      if ( rd_large_ping_pong_data2_q)   mmio_rddata_d[1023:0] =  rddata_large_ping_pong_data2[1023:0];
      if ( rd_large_ping_pong_data3_q)   mmio_rddata_d[1023:0] =  rddata_large_ping_pong_data3[1023:0];

    end  // -- always @*         


   // -- ********************************************************************************************************************************
   // -- Interface back to cmdi_rspo
   // -- ********************************************************************************************************************************

  assign  mmio_rspo_wr_done              =  mmio_wr_done_q;
  assign  mmio_rspo_rddata_valid         =  mmio_rddata_valid_q;
  assign  mmio_rspo_rddata[1023:0]       =  mmio_rddata_q[1023:0];
  assign  mmio_rspo_bad_op_or_align      =  mmio_bad_op_or_align_q;
  assign  mmio_rspo_addr_not_implemented =  mmio_addr_not_implemented_q;


  // -- ********************************************************************************************************************************
  // -- Drive Mode/Config bits to the sub-units that need them
  // -- ********************************************************************************************************************************

  assign  mmio_weq_eng_disable_d[31:0]                =  afu_config_q[63:32];
  assign  mmio_eng_memcpy2_format_enable_d            =  afu_config_q[31];
  assign  mmio_eng_rtry_backoff_timer_disable_d       =  afu_config_q[30];
  assign  mmio_eng_hold_pasid_for_debug_d             =  afu_config_q[29];
  assign  mmio_eng_force_use_eng_num_for_actag        =  afu_config_q[28];  // -- Only applicable when ( pasid_length_enabled <  = actag_length_enabled )

  assign  mmio_eng_xtouch_ageout_pg_size_d[5:0]       =  afu_config_q[25:20];

  //    assign  mmio_eng_xtouch_wt4rsp_enable_d             =  afu_config_q[18];
  assign  mmio_eng_xtouch_dest_enable_d               =  afu_config_q[17];
  assign  mmio_eng_xtouch_source_enable_d             =  afu_config_q[16];

  assign  mmio_arb_ldst_priority_mode_d[1:0]          =  afu_config_q[15:14];

  assign  mmio_rspi_fastpath_queue_bypass_disable     =  afu_config_q[13];
  assign  mmio_rspi_fastpath_stg0_bypass_disable      =  afu_config_q[12];
  assign  mmio_rspi_fastpath_stg1_bypass_disable      =  afu_config_q[11];
  assign  mmio_rspi_fastpath_stg2_bypass_disable      =  afu_config_q[10];
  assign  mmio_rspi_normal_stg1_bypass_disable        =  afu_config_q[9];
  assign  mmio_rspi_normal_stg2_bypass_disable        =  afu_config_q[8];

  assign  mmio_eng_immed_terminate_enable_d           =  afu_config_q[6];
  assign  terminate_process_via_mmio_en               =  afu_config_q[5];

  assign  mmio_cmdo_split_128B_cmds                   =  afu_config_q[4]; // -- Disable 256B ops and set this to stress cmd bus to TLX (cmd every cycle)
  assign  mmio_eng_256B_op_disable_d                  =  afu_config_q[3];
  assign  mmio_eng_128B_op_disable_d                  =  afu_config_q[2];

  assign  mmio_eng_stop_on_invalid_cmd_d              =  afu_config_q[1];
  assign  mmio_eng_intrpt_on_cpy_err_en_d             =  afu_config_q[0];

  assign  mmio_eng_use_pasid_for_actag_d              =  ~mmio_eng_force_use_eng_num_for_actag && ( cfg_afu_pasid_length[19:0] <= { 8'b0, cfg_afu_actag_length_enabled[11:0] } );



  assign  mmio_eng_capture_all_resp_code_enable_d     =  afu_config2_q[34];  // -- THIS IS FOR DEBUG USE ONLY !! (allows capturing resp_code for ALL responses )
                                                                             // -- This allows using the display facility to grab residual info from array after a fail
                                                                             // -- It must be used with caution !!
                                                                             // -- If the Host splits 256B ops into 128B responses, must set bit 3 also to disable 256B ops
                                                                             // -- If the Host can split 256B or 128B ops into 64B responses, must also set bit 2
                                                                             // -- Reason:  the split responses come back with SAME AFUTag - can create rd/wr collision to array
                                                                             // -- Default b'0: capture responses ONLY for xlate_done and intrp_rdy

  assign  mmio_rspi_fastpath_blocker_disable          =  afu_config2_q[33];  // -- THIS IS FOR DEBUG USE ONLY
                                                                             // -- Disabling will allow xlate_done/intrp_rdy to bypass the resp_queue
                                                                             // -- Default is b'0 = doesn't allow bypass (bug fix)
                                                                             // -- Setting to b'1 allows bypass which can then pass the corresponding pending ... not good
                                                                             // -- Set to b'1 to recreate original bug 
  assign  mmio_weq_eng_wr_blk_mmio_rd_pe_ary_disable   = afu_config2_q[32];
  assign  mmio_weq_term_reset_extend_en[4:0]          =  afu_config2_q[31:27];  // -- Modes for possible terminate patches

//assign  mmio_eng_xtouch_flag[4]                     =  afu_config2_q[26];  // -- XLATE_TOUCH(_N) - ageout                         (cmd_flag = 4'b0001)
//assign  mmio_eng_xtouch_flag[3]                     =  afu_config2_q[25];  // -- XLATE_TOUCH(_N) - heavyweight, write      hwt.w  (cmd_flag = 4'b0110)
//assign  mmio_eng_xtouch_flag[2]                     =  afu_config2_q[24];  // -- XLATE_TOUCH(_N) - heavyweight, read-only  hwt.ro (cmd_flag = 4'b0100)
//assign  mmio_eng_xtouch_flag[1]                     =  afu_config2_q[23];  // -- XLATE_TOUCH(_N) - lightweight, write      lwt.w  (cmd_flag = 4'b0010)
//assign  mmio_eng_xtouch_flag[0]                     =  afu_config2_q[22];  // -- XLATE_TOUCH(_N) - lightweight, read-only  lwt.ro (cmd_flag = 4'b0000)

//assign  mmio_eng_xtouch_type[1]                     =  afu_config2_q[21];  // -- XLATE_TOUCH_N
//assign  mmio_eng_xtouch_type[0]                     =  afu_config2_q[20];  // -- XLATE_TOUCH

  assign  mmio_eng_atomic_st_type[1]                  =  afu_config2_q[19];  // -- AMO_W_N
  assign  mmio_eng_atomic_st_type[0]                  =  afu_config2_q[18];  // -- AMO_W

  assign  mmio_eng_atomic_cas_type[1]                 =  afu_config2_q[17];  // -- AMO_RW_N
  assign  mmio_eng_atomic_cas_type[0]                 =  afu_config2_q[16];  // -- AMO_RW

  assign  mmio_eng_atomic_ld_type[1]                  =  afu_config2_q[15];  // -- AMO_RD_N
  assign  mmio_eng_atomic_ld_type[0]                  =  afu_config2_q[14];  // -- AMO_RD

  assign  mmio_eng_incr_st_type[1]                    =  afu_config2_q[13];  // -- DMA_PR_W_N
  assign  mmio_eng_incr_st_type[0]                    =  afu_config2_q[12];  // -- DMA_PR_W

  assign  mmio_eng_incr_ld_type[1]                    =  afu_config2_q[11];  // -- RD_WNITC_N
  assign  mmio_eng_incr_ld_type[0]                    =  afu_config2_q[10];  // -- RD_WNITC

  assign  mmio_eng_cpy_st_type[1]                     =  afu_config2_q[9];   // -- DMA_W_N
  assign  mmio_eng_cpy_st_type[0]                     =  afu_config2_q[8];   // -- DMA_W

  assign  mmio_eng_cpy_ld_type[1]                     =  afu_config2_q[7];   // -- RD_WNITC_N
  assign  mmio_eng_cpy_ld_type[0]                     =  afu_config2_q[6];   // -- RD_WNITC

  assign  mmio_eng_we_st_type[3]                      =  afu_config2_q[5];   // -- DMA_W_BE_N
  assign  mmio_eng_we_st_type[2]                      =  afu_config2_q[4];   // -- DMA_W_BE
  assign  mmio_eng_we_st_type[1]                      =  afu_config2_q[3];   // -- DMA_PR_W_N
  assign  mmio_eng_we_st_type[0]                      =  afu_config2_q[2];   // -- DMA_PR_W

  assign  mmio_eng_we_ld_type[1]                      =  afu_config2_q[1];   // -- RD_WNITC_N
  assign  mmio_eng_we_ld_type[0]                      =  afu_config2_q[0];   // -- RD_WNITC


  assign  mmio_rspi_resp_queue_maxqdepth_reset        =  afu_stats_q[19];
//assign  rspi_mmio_resp_queue_maxqdepth[6:0]         =  afu_stats_q[18:12];  // -- reserved to capture MaxQDepth

  assign  mmio_rspi_max_outstanding_responses_reset   =  afu_stats_q[11];
//assign  rspi_mmio_max_outstanding_responses[10:0]   =  afu_stats_q[10:0];   // -- reserved to capture max_outstanding_responses


  assign  mmio_eng_obj_handle_d[63:0]                 =  afu_obj_handle_q[63:0];  // Object Handle for Interrupts

  assign  mmio_eng_mmio_lat_ld_ea_d[63:7]             =  afu_extra_ea_q[63:7];

  assign  mmio_eng_base_addr_d[63:12]                 =  afu_wed_q[63:12];
  assign  mmio_arb_num_ld_tags_d[2:0]                 =  afu_wed_q[11:9];
  assign  mmio_eng_ld_size_d[1:0]                     =  afu_wed_q[8:7];
  assign  mmio_eng_type_ld_d                          =  afu_wed_q[6];
  assign  mmio_arb_num_st_tags_d[2:0]                 =  afu_wed_q[5:3];
  assign  mmio_eng_st_size_d[1:0]                     =  afu_wed_q[2:1];
  assign  mmio_eng_type_st_d                          =  afu_wed_q[0];

  assign  mmio_eng_offset_mask_d[31:12]               =  afu_bufmask_q[31:12];

  assign  mmio_eng_pasid_d[9:0]                       =  afu_pasid_q[9:0];

  assign  fatal_error_inject_d                        =  afu_misc_q[35];  // Fatal error injection by software.
  assign  mmio_arb_fastpath_disable_d                 =  afu_misc_q[34];  // Disables ld/st fastpath in ARB.  For Lab Debug.
  assign  mmio_eng_error_intrpt_enable_d              =  afu_misc_q[33];  // Enable sending an interrupt when an error occurs
  assign  mmio_eng_wkhstthrd_intrpt_enable_d          =  afu_misc_q[32];  // Enable sending an interrupt when a wkhstthrd error occurs
  assign  mmio_eng_wkhstthrd_tid_d[15:0]              =  afu_misc_q[31:16];  // TID for wkhstthrd EA_or_OBJ field, when flag = 1
  assign  mmio_eng_wkhstthrd_flag_d                   =  afu_misc_q[15];  // Set cmd_flag=0x1 and put TID in EA_or_OBJ field
  assign  mmio_eng_extra_write_mode_d                 =  afu_misc_q[14];  // Used by WakeHostThread and Interrupts
  assign  mmio_lat_trigger_src[1:0]                   =  afu_misc_q[13:12];  // 00 - Enable register, 01 - large data 0 register,
                                                                             // 10 - Reserved, 11 - large data scorecard
  assign  mmio_eng_xtouch_pg_n_d[1:0]                 =  afu_misc_q[11:10];  // 0 - N=1, 1 - N=2, 2 = N=3, 3 - N=4
  assign  mmio_eng_xtouch_pg_size_d[5:0]              =  afu_misc_q[9:4];
  assign  mmio_eng_xtouch_type_d                      =  afu_misc_q[3];   // 0 - xlate_touch, 1 - xlate_touch.n
  assign  mmio_eng_xtouch_hwt_d                       =  afu_misc_q[2];   // 0 - lightweight, 1 - heavyweight
  assign  mmio_eng_xtouch_wt4rsp_enable_d             =  afu_misc_q[1];   // Note: AFP uses this one, MCP uses config(18)
  assign  mmio_eng_xtouch_enable_d                    =  afu_misc_q[0];

  assign  mmio_eng_enable_d                           =  afu_enable_q[63];
  assign  mmio_eng_mmio_lat_mode_d                    =  afu_enable_q[62];
  assign  mmio_lat_mode_int                           =  afu_enable_q[62];
  assign  mmio_eng_mmio_lat_mode_sz_512_st_d          =  afu_enable_q[61];
  assign  mmio_eng_mmio_lat_use_reg_data_d            =  afu_enable_q[60];
  assign  mmio_eng_mmio_lat_extra_read_d              =  afu_enable_q[59];
  assign  mmio_lat_extra_read_int                     =  afu_enable_q[59];
  assign  mmio_eng_mmio_lat_mode_sz_512_ld_d          =  afu_enable_q[58];
  assign  mmio_eng_resend_retries_d                   =  afu_enable_q[57];  // Only used when mmio_eng_enable = 0

  assign  mmio_perf_snapshot_d                        =  afu_control_q[63] | afu_control_dly1_q[63];
  assign  mmio_perf_reset_d                           =  reset | afu_control_q[62] | afu_control_dly1_q[62];
  assign  mmio_eng_send_interrupt_d                   =  afu_control_q[61] | afu_control_dly1_q[61];
  assign  mmio_eng_send_wkhstthrd_d                   =  afu_control_q[60] | afu_control_dly1_q[60];

  assign  mmio_eng_mmio_lat_data0_d[1023:0]           =  large_ping_pong_data0_q[1023:0];
  assign  mmio_eng_mmio_lat_data1_d[1023:0]           =  large_ping_pong_data1_q[1023:0];
  assign  mmio_eng_mmio_lat_data2_d[1023:0]           =  large_ping_pong_data2_q[1023:0];
  assign  mmio_eng_mmio_lat_data3_d[1023:0]           =  large_ping_pong_data3_q[1023:0];

  // -- Drive to 200MHz modules off a 200MHz latch for timing reasons (especially those that need to be distributed to all engines)
  assign  mmio_weq_eng_disable[31:0]                  =  mmio_weq_eng_disable_q[31:0];

  assign  mmio_weq_restart_process                    =  mmio_weq_restart_process_q;

  assign  mmio_eng_memcpy2_format_enable              =  mmio_eng_memcpy2_format_enable_q;
  assign  mmio_weq_memcpy2_format_enable              =  mmio_eng_memcpy2_format_enable_q;   // -- send a copy to WEQ
  assign  mmio_eng_immed_terminate_enable             =  mmio_eng_immed_terminate_enable_q;
  assign  mmio_eng_rtry_backoff_timer_disable         =  mmio_eng_rtry_backoff_timer_disable_q;

  assign  mmio_eng_hold_pasid_for_debug               =  mmio_eng_hold_pasid_for_debug_q;

  assign  mmio_eng_capture_all_resp_code_enable       =  mmio_eng_capture_all_resp_code_enable_q;

  assign  mmio_eng_xtouch_ageout_pg_size[5:0]         =  mmio_eng_xtouch_ageout_pg_size_q[5:0];

  assign  mmio_eng_xtouch_wt4rsp_enable               =  mmio_eng_xtouch_wt4rsp_enable_q;
  assign  mmio_eng_xtouch_dest_enable                 =  mmio_eng_xtouch_dest_enable_q;
  assign  mmio_eng_xtouch_source_enable               =  mmio_eng_xtouch_source_enable_q;

  assign  mmio_eng_use_pasid_for_actag                =  mmio_eng_use_pasid_for_actag_q;
  assign  mmio_weq_use_pasid_for_actag                =  mmio_eng_use_pasid_for_actag_q;     // -- send a copy to WEQ

  assign  mmio_arb_ldst_priority_mode[1:0]            =  mmio_arb_ldst_priority_mode_q[1:0];
                                                                                                             
  assign  mmio_eng_256B_op_disable                    =  mmio_eng_256B_op_disable_q;        
  assign  mmio_eng_128B_op_disable                    =  mmio_eng_128B_op_disable_q;        
                                                       
  assign  mmio_eng_stop_on_invalid_cmd                =  mmio_eng_stop_on_invalid_cmd_q;    
  assign  mmio_eng_intrpt_on_cpy_err_en               =  mmio_eng_intrpt_on_cpy_err_en_q;

  assign  mmio_weq_eng_disable_updated                =  mmio_weq_eng_disable_updated_q;

  // AFP
  assign  mmio_eng_obj_handle[63:0]                   =  mmio_eng_obj_handle_q[63:0];

  assign  mmio_eng_mmio_lat_ld_ea[63:7]               =  mmio_eng_mmio_lat_ld_ea_q[63:7];

  assign  mmio_eng_base_addr[63:12]                   =  mmio_eng_base_addr_q[63:12];
  assign  mmio_arb_num_ld_tags[2:0]                   =  mmio_arb_num_ld_tags_q[2:0];
  assign  mmio_eng_ld_size[1:0]                       =  mmio_eng_ld_size_q[1:0];
  assign  mmio_eng_type_ld                            =  mmio_eng_type_ld_q;
  assign  mmio_arb_num_st_tags[2:0]                   =  mmio_arb_num_st_tags_q[2:0];
  assign  mmio_eng_st_size[1:0]                       =  mmio_eng_st_size_q[1:0];
  assign  mmio_eng_type_st                            =  mmio_eng_type_st_q;
  // ARB copies of signals to eng
  assign  mmio_arb_ld_size[1:0]                       =  mmio_eng_ld_size_q[1:0];
  assign  mmio_arb_type_ld                            =  mmio_eng_type_ld_q;
  assign  mmio_arb_st_size[1:0]                       =  mmio_eng_st_size_q[1:0];
  assign  mmio_arb_type_st                            =  mmio_eng_type_st_q;

  assign  mmio_eng_offset_mask[31:12]                 =  mmio_eng_offset_mask_q[31:12];

  assign  mmio_eng_pasid[9:0]                         =  mmio_eng_pasid_q[9:0];

  assign  afu_tlx_fatal_error                         =  fatal_error_inject_q;
  assign  mmio_arb_fastpath_disable                   =  mmio_arb_fastpath_disable_q;
  assign  mmio_eng_error_intrpt_enable                =  mmio_eng_error_intrpt_enable_q;
  assign  mmio_eng_wkhstthrd_intrpt_enable            =  mmio_eng_wkhstthrd_intrpt_enable_q;
  assign  mmio_eng_wkhstthrd_tid[15:0]                =  mmio_eng_wkhstthrd_tid_q[15:0];
  assign  mmio_eng_wkhstthrd_flag                     =  mmio_eng_wkhstthrd_flag_q;
  assign  mmio_eng_extra_write_mode                   =  mmio_eng_extra_write_mode_q;
  assign  mmio_eng_xtouch_pg_n[1:0]                   =  mmio_eng_xtouch_pg_n_q[1:0];
  assign  mmio_eng_xtouch_pg_size[5:0]                =  mmio_eng_xtouch_pg_size_q[5:0];
  assign  mmio_eng_xtouch_type                        =  mmio_eng_xtouch_type_q;
  assign  mmio_eng_xtouch_hwt                         =  mmio_eng_xtouch_hwt_q;
  assign  mmio_eng_xtouch_wt4rsp_enable               =  mmio_eng_xtouch_wt4rsp_enable_q;
  assign  mmio_eng_xtouch_enable                      =  mmio_eng_xtouch_enable_q;
  assign  mmio_arb_xtouch_wt4rsp_enable               =  mmio_eng_xtouch_wt4rsp_enable_q;
  assign  mmio_arb_xtouch_enable                      =  mmio_eng_xtouch_enable_q;

  assign  mmio_eng_enable                             =  mmio_eng_enable_q;
  assign  mmio_eng_mmio_lat_mode                      =  mmio_eng_mmio_lat_mode_q;
  assign  mmio_arb_mmio_lat_mode                      =  mmio_eng_mmio_lat_mode_q;
  assign  mmio_eng_mmio_lat_mode_sz_512_st            =  mmio_eng_mmio_lat_mode_sz_512_st_q;
  assign  mmio_arb_mmio_lat_mode_sz_512_st            =  mmio_eng_mmio_lat_mode_sz_512_st_q;
  assign  mmio_eng_mmio_lat_use_reg_data              =  mmio_eng_mmio_lat_use_reg_data_q;
  assign  mmio_eng_mmio_lat_extra_read                =  mmio_eng_mmio_lat_extra_read_q;
  assign  mmio_arb_mmio_lat_extra_read                =  mmio_eng_mmio_lat_extra_read_q;
  assign  mmio_eng_mmio_lat_mode_sz_512_ld            =  mmio_eng_mmio_lat_mode_sz_512_ld_q;
  assign  mmio_arb_mmio_lat_mode_sz_512_ld            =  mmio_eng_mmio_lat_mode_sz_512_ld_q;
  assign  mmio_eng_resend_retries                     =  mmio_eng_resend_retries_q;

  assign  mmio_perf_snapshot                          = mmio_perf_snapshot_q;
  assign  mmio_perf_reset                             = mmio_perf_reset_q;
  assign  mmio_eng_send_interrupt                     = mmio_eng_send_interrupt_q;
  assign  mmio_eng_send_wkhstthrd                     = mmio_eng_send_wkhstthrd_q;

  assign  mmio_eng_mmio_lat_data0[1023:0]             = mmio_eng_mmio_lat_data0_q[1023:0];
  assign  mmio_eng_mmio_lat_data1[1023:0]             = mmio_eng_mmio_lat_data1_q[1023:0];
  assign  mmio_eng_mmio_lat_data2[1023:0]             = mmio_eng_mmio_lat_data2_q[1023:0];
  assign  mmio_eng_mmio_lat_data3[1023:0]             = mmio_eng_mmio_lat_data3_q[1023:0];

  // -- ********************************************************************************************************************************
  // -- Trace Array
  // -- ********************************************************************************************************************************

  // -- Reserved to reflect current write pointer of 3 arrays
  assign  trace_rspi_wraddr_reset               =  afu_trace_ctl_q[63];
  // --   trace_rspi_wraddr[10:0]               =  afu_trace_ctl_q[62:52];
  assign  trace_cmdo_wraddr_reset               =  afu_trace_ctl_q[51];
  // --   trace_cmdo_wraddr[10:0]               =  afu_trace_ctl_q[50:40];
  assign  trace_cmdi_rspo_wraddr_reset          =  afu_trace_ctl_q[39];
  // --   trace_cmdi_rspo_wraddr[10:0]          =  afu_trace_ctl_q[38:28];


  assign  trace_eng_num[4:0]                    =  afu_trace_ctl_q[26:22]; // -- Bit 3 to enable trace by engine number

  // -- Trace array trigger enables for rspi interface
  assign  trace_tlx_afu_resp_data_valid_en      =  afu_trace_ctl_q[21];
  assign  trace_afu_tlx_resp_rd_req_en          =  afu_trace_ctl_q[20];
  assign  trace_afu_tlx_resp_credit_en          =  afu_trace_ctl_q[19];
  assign  trace_tlx_afu_resp_valid_retry_en     =  afu_trace_ctl_q[18];
  assign  trace_tlx_afu_resp_valid_no_data_en   =  afu_trace_ctl_q[17];
  assign  trace_tlx_afu_resp_valid_with_data_en =  afu_trace_ctl_q[16];

  // -- Trace array trigger enables for cmdo interface
  assign  trace_tlx_afu_cmd_data_credit_en      =  afu_trace_ctl_q[15];
  assign  trace_tlx_afu_cmd_credit_en           =  afu_trace_ctl_q[14];
  assign  trace_afu_tlx_cdata_valid_en          =  afu_trace_ctl_q[13];   
  assign  trace_afu_tlx_cmd_valid_en            =  afu_trace_ctl_q[12];    

  // -- Trace array trigger enables for cmdi_rspo interface
  assign  trace_tlx_afu_resp_data_credit_en     =  afu_trace_ctl_q[11];
  assign  trace_tlx_afu_resp_credit_en          =  afu_trace_ctl_q[10];
  assign  trace_afu_tlx_rdata_valid_en          =  afu_trace_ctl_q[9];
  assign  trace_afu_tlx_resp_valid_en           =  afu_trace_ctl_q[8];

  assign  trace_afu_tlx_cmd_credit_en           =  afu_trace_ctl_q[7];
  assign  trace_afu_tlx_cmd_rd_req_en           =  afu_trace_ctl_q[6];
  assign  trace_tlx_afu_cmd_data_valid_en       =  afu_trace_ctl_q[5];
  assign  trace_tlx_afu_cmd_valid_en            =  afu_trace_ctl_q[4];

  // -- Trace array control
  assign  trace_eng_en                          =  afu_trace_ctl_q[3];  // -- See Bits 26:22
  assign  trace_no_wrap                         =  afu_trace_ctl_q[2];
  assign  trace_events                          =  afu_trace_ctl_q[1];
  assign  trace_arm                             =  afu_trace_ctl_q[0];


  // -- ********************************************************************************************************************************
  // -- Display interfaces - for gathering of debug information 
  // -- ********************************************************************************************************************************

  // -- The reads will be done via a generic array display interface

  // -- Display_Control Register
  // --
  // -- [31:28] - Module select
  // --         - b'0011 - mcp3_trace
  // --         - b'0010 - mcp3_rspi
  // --         - b'0001 - mcp3_weq
  // --         - b'0000 - mcp3_cpeng
  // -- 
  // -- [27:24] - Array select
  // --         - b'0000 - mcp3_trace - Trace Array    512 x ~64B 
  // --         - b'0000 - mcp3_rspi  - Response Queue 128 x 36
  // --         - b'0000 - mcp3_weq   - nxt_proc_req_vector, nxt_eng_req_vector, sequencer states (term, restart, etc)
  // --         - b'0001 - mcp3_cpeng - Retry Queue     32 x 
  // --         - b'0000 - mcp3_cpeng - Data Buffer     32 x 64B
  // --
  // -- [23:8]  - Address (Differs by unit)
  // --      - trace Trace Array
  // --         - [23:17] - Not Used
  // --         - [16:8]  - Entry number (0-511)
  // --      - rspi Response Queue
  // --         - [23:15] - Not Used
  // --         - [14:8]  - Entry number (0-127)
  // --      - cpeng Retry Queue
  // --         - [23:21] - Not Used
  // --         - [20:16] - Engine # (0-31) 
  // --         - [15:13] - Not Used
  // --         - [12:8]  - Entry number (0-31)
  // --      - cpeng data buffer
  // --         - [23:21] - Not Used
  // --         - [20:16] - Engine # (0-31)
  // --         - [15:13] - Not Used
  // --         - [12:8]  - 64B Buffer number (0-31)
  // --
  // -- [7:4]   - AutoIncr Data Reg Encode that Triggers the address to increment
  // --
  // -- [3:1]   - Unused
  // -- [0]     - AutoIncr Enable



  // -- Clock            |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |
  // --                           ___ ...
  // -- cmdi_mmio_wr           __|   |____________________________________________________________________________________________________
  // --                           ___ ...
  // -- cmdi_mmio_addr/wrdata  --<___>----------------------------------------------------------------------------------------------------
  // --                               ___ ...
  // -- mmio_wr_q              ______|   |________________________________________________________________________________________________
  // --                        _____ ____________________ ________________________________________________________________________________
  // -- mmio_addr_q            _____X____________________X________________________________________________________________________________
  // --                        _____ _____________________________________________________________________________________________________
  // -- mmio_wrdata_q          _____X_____________________________________________________________________________________________________
  // --                               ___ ...
  // -- mmio_wr_valid          ______|   |________________________________________________________________________________________________
  // --                              _____________________________________________________________________________________________________
  // -- addr_is_privileged     _____|
  // --                              ____________________
  // -- addr_is_afu_display_ctl  ___|                    |________________________________________________________________________________
  // --                               ___ ...
  // -- wr_afu_display_ctl     ______|   |________________________________________________________________________________________________
  // --                                   ___ ...
  // -- wr_afu_display_ctl_q   __________|   |____________________________________________________________________________________________
  // --                         _____________ ____________________________________________________________________________________________
  // -- afu_display_ctl_q[31:0] _____________X____________________________________________________________________________________________

  // -- Clock            |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |
  // --                                               ___ ...
  // -- cmdi_mmio_rd           ______________________|   |________________________________________________________________________________
  // --                                               ___ ...
  // -- cmdi_mmio_addr         ----------------------<___>--------------------------------------------------------------------------------
  // --                                                   ___ ...
  // -- mmio_rd_q              __________________________|   |____________________________________________________________________________
  // --                        _____ ____________________ ________________________________________________________________________________
  // -- mmio_addr_q            _____X____________________X________________________________________________________________________________
  // --                              _____________________________________________________________________________________________________
  // -- mmio_addr_q/wrdata_q   -----<_____________________________________________________________________________________________________
  // --                                                   ___ ...
  // -- mmio_rd_valid          __________________________|   |____________________________________________________________________________
  // --                              _____________________________________________________________________________________________________
  // -- addr_is_privileged     _____|                    |
  // --                                                   ________________________________
  // -- addr_is_afu_display_data[x] _____________________|                                |_______________________________________________
  // --                                                   ___ ...
  // -- rd_afu_display_data[x]      _____________________|   |____________________________________________________________________________
  // --                                                       ___ ...
  // -- rd_afu_display_data_q       _________________________|   |________________________________________________________________________

  // --                       _______________________
  // -- disp_rd_pending_q ___|                       |___________________________________________________________________________________


  // -- Display Read Access
  assign  rd_afu_display_data_d =  rd_afu_display_data;

  // -- Perf Read Access
  assign  rd_afu_perf_count_d =    rd_afu_perf_count || rd_afu_latency;

  assign  rd_afu_latency_d =  rd_afu_latency;

  // -- Latch delayed value for creation of double wide pulse
//  assign  rd_afu_display_data_dly1_d =  rd_afu_display_data_q; 

  // -- Assign names to encodes
  assign  afu_display_mod_is_trace          =  ( afu_display_ctl_q[31:28] == 4'b0011 );
  assign  afu_display_mod_is_rspi           =  ( afu_display_ctl_q[31:28] == 4'b0010 );
  assign  afu_display_mod_is_weq            =  ( afu_display_ctl_q[31:28] == 4'b0001 );
  assign  afu_display_mod_is_eng            =  ( afu_display_ctl_q[31:28] == 4'b0000 );

  assign  afu_display_eng_ary_is_dbuf       =  ( afu_display_ctl_q[27:24] == 4'b0000 ); 
  assign  afu_display_eng_ary_is_rtry_queue =  ( afu_display_ctl_q[27:24] == 4'b0001 ); 
  assign  afu_display_eng_ary_is_latches    =  ( afu_display_ctl_q[27:24] == 4'b0010 ); 

  // -- Send display request to trace function
  assign  mmio_trace_display_rdval          =  (( rd_afu_display_data_d || rd_afu_display_data_q ) && afu_display_mod_is_trace ); 
  assign  mmio_trace_display_addr[8:0]      =  afu_display_ctl_q[16:8];
  assign  mmio_trace_display_offset[3:0]    =  mmio_addr_q[6:3];

  // -- Send display request to rspi function
  assign  mmio_rspi_display_rdval           =  (( rd_afu_display_data_d || rd_afu_display_data_q ) && afu_display_mod_is_rspi ); 
  assign  mmio_rspi_display_addr[6:0]       =  afu_display_ctl_q[14:8];
 
  // -- Send display request to weq and engine via weq
  assign  mmio_weq_display_rdval            =  (( rd_afu_display_data_d || rd_afu_display_data_q ) && ( afu_display_mod_is_weq || afu_display_mod_is_eng )); 
  assign  mmio_weq_display_mod_select       =  afu_display_ctl_q[28];     // -- Tunnel the request for engine through weq
  assign  mmio_weq_display_ary_select[1:0]  =  afu_display_ctl_q[25:24];  // -- For engine, select between data buffer and retry queue
  assign  mmio_weq_display_eng_select[4:0]  =  afu_display_ctl_q[20:16];
  assign  mmio_weq_display_addr[4:0]        =  afu_display_ctl_q[12:8];
  assign  mmio_weq_display_offset[3:0]      =  mmio_addr_q[6:3];
  assign  mmio_cmdo_display_offset[3:0]     =  mmio_addr_q[6:3];

  // -- Set and hold pending latch until one of the targets replies with rddata_val
  assign  trace_mmio_display_rddata_valid_d =  trace_mmio_display_rddata_valid;
  assign  rspi_mmio_display_rddata_valid_d  =  rspi_mmio_display_rddata_valid;
  assign  weq_mmio_display_rddata_valid_d   =  weq_mmio_display_rddata_valid;
  assign  eng_mmio_display_rddata_valid_d   =  eng_mmio_display_rddata_valid;

  assign  rd_afu_display_data_pending_en    =  ( rd_afu_display_data_d ||  rd_afu_display_data_valid || reset );
  assign  rd_afu_display_data_pending_d     =  ( rd_afu_display_data_d && ~rd_afu_display_data_valid ); 
  assign  rd_afu_display_data_valid         =  ( rd_afu_display_data_pending_q &&
                                               ( trace_mmio_display_rddata_valid_q ||
                                                  rspi_mmio_display_rddata_valid_q ||
                                                   weq_mmio_display_rddata_valid_q ||
                                                   eng_mmio_display_rddata_valid_q ));

  assign  mmio_perf_rdval                 =  ( rd_afu_perf_count_d || rd_afu_perf_count_q );
  assign  mmio_perf_rdlatency             =  ( rd_afu_latency_d || rd_afu_latency_q );
  assign  mmio_perf_rdaddr[3:0]           =  { ~mmio_addr_q[6], mmio_addr_q[5:3] };
  assign  perf_mmio_rddata_valid_d        =  perf_mmio_rddata_valid;
  assign  rd_afu_perf_count_pending_en    =  ( rd_afu_perf_count_d ||  rd_afu_perf_count_valid || reset );
  assign  rd_afu_perf_count_pending_d     =  ( rd_afu_perf_count_d && ~rd_afu_perf_count_valid ); 
  assign  rd_afu_perf_count_valid         =  ( rd_afu_perf_count_pending_q && perf_mmio_rddata_valid_q );

  // -- Capture display data response from various targets
  assign  rddata_afu_display_data_en =  ( trace_mmio_display_rddata_valid || rspi_mmio_display_rddata_valid || weq_mmio_display_rddata_valid || eng_mmio_display_rddata_valid ); 

  always @*
    begin
      if ( trace_mmio_display_rddata_valid )
        rddata_afu_display_data_d[63:0] =  trace_mmio_display_rddata[63:0];
      else if ( rspi_mmio_display_rddata_valid )
        rddata_afu_display_data_d[63:0] =  rspi_mmio_display_rddata[63:0];
      else if ( weq_mmio_display_rddata_valid )
        rddata_afu_display_data_d[63:0] =  weq_mmio_display_rddata[63:0];
      else if ( eng_mmio_display_rddata_valid )
        rddata_afu_display_data_d[63:0] =  cmdo_mmio_display_rddata[63:0];
      else
        rddata_afu_display_data_d[63:0] =  64'b0;
    end

  assign  rddata_afu_perf_count_en =  perf_mmio_rddata_valid;
  assign  rddata_afu_perf_count_d[63:0] =  perf_mmio_rddata[63:0];


  // -- ********************************************************************************************************************************
  // -- Display AutoIncr logic
  // -- ********************************************************************************************************************************

  assign  autoincr_trigger_match  = ( mmio_addr_q[6:3] == afu_display_ctl_q[7:4] );

  assign  autoincr_trigger_trace   =  ( afu_display_mod_is_trace && trace_mmio_display_rddata_valid && autoincr_trigger_match && odd_q );
  assign  autoincr_trigger_rspi    =  ( afu_display_mod_is_rspi  &&  rspi_mmio_display_rddata_valid && autoincr_trigger_match && odd_q );
  assign  autoincr_trigger_weq     =  ( afu_display_mod_is_weq   &&   weq_mmio_display_rddata_valid && autoincr_trigger_match && odd_q );
  assign  autoincr_trigger_eng     =  ( afu_display_mod_is_eng   &&   eng_mmio_display_rddata_valid && autoincr_trigger_match && odd_q );
                           
  assign  autoincr_last_addr_trace =  ( afu_display_ctl_q[16:8] == 9'b111111111 );
  assign  autoincr_last_addr_rspi  =  ( afu_display_ctl_q[14:8] == 7'b1111111 );
  assign  autoincr_last_addr_weq   =  ( afu_display_ctl_q[ 9:8] == 2'b10 );
  assign  autoincr_last_addr_eng   = (( afu_display_ctl_q[12:8] == 5'b11111 ) && ( afu_display_eng_ary_is_dbuf || afu_display_eng_ary_is_rtry_queue )) ||
                                     (( afu_display_ctl_q[12:8] == 5'b00111 ) && ( afu_display_eng_ary_is_latches ));

  assign  autoincr_last_eng        =  ( afu_display_ctl_q[20:16] == 5'b11111 );


  assign  autoincr_sel[8:0] =  { autoincr_trigger_trace, autoincr_trigger_rspi, autoincr_trigger_weq, autoincr_trigger_eng,
                                 autoincr_last_addr_trace, autoincr_last_addr_rspi, autoincr_last_addr_weq, autoincr_last_addr_eng, autoincr_last_eng };

  always @*
    begin
      casez ( autoincr_sel[8:0] )
      // --
      // --  autoincr_trigger_trace
      // --  |autoincr_trigger_rspi
      // --  ||autoincr_trigger_weq
      // --  |||autoincr_trigger_eng
      // --  ||||
      // --  |||| autoincr_last_addr_trace
      // --  |||| |autoincr_last_addr_rspi
      // --  |||| ||autoincr_last_addr_weq
      // --  |||| |||autoincr_last_addr_eng
      // --  |||| ||||
      // --  |||| |||| autoincr_last_eng
      // --  |||| |||| |
      // --  8765 4321 0
      // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
          9'b0000_????_?  :  autoincr_nxt_afu_display_ctl[31:0] =    afu_display_ctl_q[31:0] ;
      // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
          9'b1???_0???_?  :  autoincr_nxt_afu_display_ctl[31:0] =  { afu_display_ctl_q[31:17], afu_display_ctl_q[16:8]  + 9'b1, afu_display_ctl_q[7:1], afu_display_ctl_q[0] };
          9'b1???_1???_?  :  autoincr_nxt_afu_display_ctl[31:0] =  { afu_display_ctl_q[31:17],                            9'b0, afu_display_ctl_q[7:1],                 1'b0 };
      // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
          9'b01??_?0??_?  :  autoincr_nxt_afu_display_ctl[31:0] =  { afu_display_ctl_q[31:15], afu_display_ctl_q[14:8]  + 7'b1, afu_display_ctl_q[7:1], afu_display_ctl_q[0] };
          9'b01??_?1??_?  :  autoincr_nxt_afu_display_ctl[31:0] =  { afu_display_ctl_q[31:15],                            7'b0, afu_display_ctl_q[7:1],                 1'b0 };
      // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
          9'b001?_??0?_?  :  autoincr_nxt_afu_display_ctl[31:0] =  { afu_display_ctl_q[31:10], afu_display_ctl_q[ 9:8]  + 2'b1, afu_display_ctl_q[7:1], afu_display_ctl_q[0] };
          9'b001?_??1?_?  :  autoincr_nxt_afu_display_ctl[31:0] =  { afu_display_ctl_q[31:10],                            2'b0, afu_display_ctl_q[7:1],                 1'b0 };
      // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
          9'b0001_???0_?  :  autoincr_nxt_afu_display_ctl[31:0] =  { afu_display_ctl_q[31:21], afu_display_ctl_q[20:16]       , afu_display_ctl_q[15:13], afu_display_ctl_q[12:8] + 5'b1, afu_display_ctl_q[7:1], afu_display_ctl_q[0] };
          9'b0001_???1_0  :  autoincr_nxt_afu_display_ctl[31:0] =  { afu_display_ctl_q[31:21], afu_display_ctl_q[20:16] + 5'b1, afu_display_ctl_q[15:13],                           5'b0, afu_display_ctl_q[7:1], afu_display_ctl_q[0] };
          9'b0001_???1_1  :  autoincr_nxt_afu_display_ctl[31:0] =  { afu_display_ctl_q[31:21],                            5'b0, afu_display_ctl_q[15:13],                           5'b0, afu_display_ctl_q[7:1],                 1'b0 };
      // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
           default        :  autoincr_nxt_afu_display_ctl[31:0] =    afu_display_ctl_q[31:0] ;
      // ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      endcase
    end  // -- always @*

    assign  autoincr_update_afu_display_ctl =  ( afu_display_ctl_q[0] && ( autoincr_trigger_trace || autoincr_trigger_rspi || autoincr_trigger_weq || autoincr_trigger_eng ));


  // -- ********************************************************************************************************************************
  // -- Sim Idle
  // -- ********************************************************************************************************************************

  // -- Create sim idle for use in capturing in a register internally
  assign  sim_idle_mmio_int =  ~mmio_rd_q       &&
                               ~mmio_wr_q       &&
                               ~mmio_rd_dly1_q  &&
                               ~mmio_wr_dly1_q  &&
                               ~mmio_large_rd_q       &&
                               ~mmio_large_wr_q       &&
                               ~mmio_large_rd_dly1_q  &&
                               ~mmio_large_wr_dly1_q  &&
                               ~rd_wed_pending_q                  &&
                               ~wr_wed_pending_q                  &&
                               ~rd_process_status_pending_q       &&
                               ~rd_intrpt_ctl_pending_q           &&                                           
                               ~wr_intrpt_ctl_pending_q           &&
                               ~rd_intrpt_obj_pending_q           &&                                
                               ~wr_intrpt_obj_pending_q           &&
                               ~rd_intrpt_data_pending_q          &&                                 
                               ~wr_intrpt_data_pending_q          &&
                               ~mmio_restart_process_pending_q    &&
                             //    ~terminate_process_pending_q       &&
                               ~cfg_terminate_process_pending_q   &&
                               ~rd_afu_display_data_pending_q;

  // -- Also send it outbound for combining with other units for sim to determine when the afu is idle
  assign  sim_idle_mmio =  sim_idle_mmio_int;


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock_afu )
    begin
      // -- Even/Odd Clock determination (AFU clock domain)
      toggle_q                                     <= toggle_d;                     

      cfg_afu_pasid_mask_q[19:0]                   <= cfg_afu_pasid_mask_d[19:0];                

      mmio_weq_rd_wed_q                            <= mmio_weq_rd_wed_d;
      mmio_weq_wr_wed_q                            <= mmio_weq_wr_wed_d;
      mmio_weq_rd_process_status_q                 <= mmio_weq_rd_process_status_d;
      mmio_weq_rd_intrpt_ctl_q                     <= mmio_weq_rd_intrpt_ctl_d;
      mmio_weq_wr_intrpt_ctl_q                     <= mmio_weq_wr_intrpt_ctl_d;
      mmio_weq_rd_intrpt_obj_q                     <= mmio_weq_rd_intrpt_obj_d;
      mmio_weq_wr_intrpt_obj_q                     <= mmio_weq_wr_intrpt_obj_d;
      mmio_weq_rd_intrpt_data_q                    <= mmio_weq_rd_intrpt_data_d;
      mmio_weq_wr_intrpt_data_q                    <= mmio_weq_wr_intrpt_data_d;

      weq_mmio_wr_wed_done_q                       <= weq_mmio_wr_wed_done_d;           
      weq_mmio_rd_wed_valid_q                      <= weq_mmio_rd_wed_valid_d;          
      weq_mmio_rd_process_status_valid_q           <= weq_mmio_rd_process_status_valid_d;
      weq_mmio_wr_intrpt_ctl_done_q                <= weq_mmio_wr_intrpt_ctl_done_d;      
      weq_mmio_rd_intrpt_ctl_valid_q               <= weq_mmio_rd_intrpt_ctl_valid_d;     
      weq_mmio_wr_intrpt_obj_done_q                <= weq_mmio_wr_intrpt_obj_done_d;      
      weq_mmio_rd_intrpt_obj_valid_q               <= weq_mmio_rd_intrpt_obj_valid_d;     
      weq_mmio_wr_intrpt_data_done_q               <= weq_mmio_wr_intrpt_data_done_d;      
      weq_mmio_rd_intrpt_data_valid_q              <= weq_mmio_rd_intrpt_data_valid_d;     

      if ( rddata_weq_en )
        rddata_weq_q[63:0]                         <= rddata_weq_d[63:0];

      mmio_weq_eng_disable_q[31:0]                 <= mmio_weq_eng_disable_d[31:0];

      mmio_eng_memcpy2_format_enable_q             <= mmio_eng_memcpy2_format_enable_d;
      mmio_eng_rtry_backoff_timer_disable_q        <= mmio_eng_rtry_backoff_timer_disable_d;
      mmio_eng_immed_terminate_enable_q            <= mmio_eng_immed_terminate_enable_d;

      mmio_eng_xtouch_ageout_pg_size_q[5:0]        <= mmio_eng_xtouch_ageout_pg_size_d[5:0];
      mmio_eng_xtouch_wt4rsp_enable_q              <= mmio_eng_xtouch_wt4rsp_enable_d;
      mmio_eng_xtouch_dest_enable_q                <= mmio_eng_xtouch_dest_enable_d;
      mmio_eng_xtouch_source_enable_q              <= mmio_eng_xtouch_source_enable_d;

      mmio_eng_use_pasid_for_actag_q               <= mmio_eng_use_pasid_for_actag_d;
      mmio_eng_hold_pasid_for_debug_q              <= mmio_eng_hold_pasid_for_debug_d;

      mmio_eng_capture_all_resp_code_enable_q      <= mmio_eng_capture_all_resp_code_enable_d;

      mmio_arb_ldst_priority_mode_q[1:0]           <= mmio_arb_ldst_priority_mode_d[1:0];
                                                                                           
      mmio_eng_256B_op_disable_q                   <= mmio_eng_256B_op_disable_d;        
      mmio_eng_128B_op_disable_q                   <= mmio_eng_128B_op_disable_d;        
                                              
      mmio_eng_stop_on_invalid_cmd_q               <= mmio_eng_stop_on_invalid_cmd_d;    
      mmio_eng_intrpt_on_cpy_err_en_q              <= mmio_eng_intrpt_on_cpy_err_en_d;


      // -- AFP controls to ENG & PERF

      mmio_eng_obj_handle_q[63:0]                  <= mmio_eng_obj_handle_d[63:0];

      mmio_eng_mmio_lat_ld_ea_q[63:7]              <= mmio_eng_mmio_lat_ld_ea_d[63:7];

      mmio_eng_base_addr_q[63:12]                  <= mmio_eng_base_addr_d[63:12];
      mmio_arb_num_ld_tags_q[2:0]                  <= mmio_arb_num_ld_tags_d[2:0];
      mmio_eng_ld_size_q[1:0]                      <= mmio_eng_ld_size_d[1:0];
      mmio_eng_type_ld_q                           <= mmio_eng_type_ld_d;
      mmio_arb_num_st_tags_q[2:0]                  <= mmio_arb_num_st_tags_d[2:0];
      mmio_eng_st_size_q[1:0]                      <= mmio_eng_st_size_d[1:0];
      mmio_eng_type_st_q                           <= mmio_eng_type_st_d;

      mmio_eng_offset_mask_q[31:12]                <= mmio_eng_offset_mask_d[31:12];

      mmio_eng_pasid_q[9:0]                        <= mmio_eng_pasid_d[9:0];

      fatal_error_inject_q                         <= fatal_error_inject_d;
      mmio_arb_fastpath_disable_q                  <= mmio_arb_fastpath_disable_d;
      mmio_eng_error_intrpt_enable_q               <= mmio_eng_error_intrpt_enable_d;
      mmio_eng_wkhstthrd_intrpt_enable_q           <= mmio_eng_wkhstthrd_intrpt_enable_d;
      mmio_eng_wkhstthrd_tid_q[15:0]               <= mmio_eng_wkhstthrd_tid_d[15:0];
      mmio_eng_wkhstthrd_flag_q                    <= mmio_eng_wkhstthrd_flag_d;
      mmio_eng_extra_write_mode_q                  <= mmio_eng_extra_write_mode_d;
      mmio_eng_xtouch_pg_n_q[1:0]                  <= mmio_eng_xtouch_pg_n_d[1:0];
      mmio_eng_xtouch_pg_size_q[5:0]               <= mmio_eng_xtouch_pg_size_d[5:0];
      mmio_eng_xtouch_type_q                       <= mmio_eng_xtouch_type_d;
      mmio_eng_xtouch_hwt_q                        <= mmio_eng_xtouch_hwt_d;
      mmio_eng_xtouch_wt4rsp_enable_q              <= mmio_eng_xtouch_wt4rsp_enable_d;
      mmio_eng_xtouch_enable_q                     <= mmio_eng_xtouch_enable_d;

      mmio_eng_enable_q                            <= mmio_eng_enable_d;
      mmio_eng_mmio_lat_mode_q                     <= mmio_eng_mmio_lat_mode_d;
      mmio_eng_mmio_lat_mode_sz_512_st_q           <= mmio_eng_mmio_lat_mode_sz_512_st_d;
      mmio_eng_mmio_lat_mode_sz_512_ld_q           <= mmio_eng_mmio_lat_mode_sz_512_ld_d;
      mmio_eng_mmio_lat_use_reg_data_q             <= mmio_eng_mmio_lat_use_reg_data_d;
      mmio_eng_mmio_lat_extra_read_q               <= mmio_eng_mmio_lat_extra_read_d;
      mmio_eng_resend_retries_q                    <= mmio_eng_resend_retries_d;

      mmio_perf_snapshot_q                         <= mmio_perf_snapshot_d;
      mmio_perf_reset_q                            <= mmio_perf_reset_d;
      mmio_eng_send_interrupt_q                    <= mmio_eng_send_interrupt_d;
      mmio_eng_send_wkhstthrd_q                    <= mmio_eng_send_wkhstthrd_d;

      mmio_eng_mmio_lat_data0_q[1023:0]            <= mmio_eng_mmio_lat_data0_d[1023:0];
      mmio_eng_mmio_lat_data1_q[1023:0]            <= mmio_eng_mmio_lat_data1_d[1023:0];
      mmio_eng_mmio_lat_data2_q[1023:0]            <= mmio_eng_mmio_lat_data2_d[1023:0];
      mmio_eng_mmio_lat_data3_q[1023:0]            <= mmio_eng_mmio_lat_data3_d[1023:0];

      // End AFP


      mmio_weq_restart_process_q                   <= mmio_weq_restart_process_d;

      mmio_weq_eng_disable_updated_q               <= mmio_weq_eng_disable_updated_d;

      trace_mmio_display_rddata_valid_q            <= trace_mmio_display_rddata_valid_d;
      rspi_mmio_display_rddata_valid_q             <= rspi_mmio_display_rddata_valid_d;
      weq_mmio_display_rddata_valid_q              <= weq_mmio_display_rddata_valid_d;
      eng_mmio_display_rddata_valid_q              <= eng_mmio_display_rddata_valid_d;
      if ( rddata_afu_display_data_en )
        rddata_afu_display_data_q[63:0]            <= rddata_afu_display_data_d[63:0];

      perf_mmio_rddata_valid_q                     <= perf_mmio_rddata_valid_d;
      if ( rddata_afu_perf_count_en )
        rddata_afu_perf_count_q[63:0]              <= rddata_afu_perf_count_d[63:0];

      // -- Terminate Queue / Arb latches
      mmio_terminate_process_q                     <= mmio_terminate_process_d;
      if ( mmio_terminate_pasid_en )
        mmio_terminate_pasid_q[19:0]               <= mmio_terminate_pasid_d[19:0];

      cfg_afu_terminate_valid_dly1_q               <= cfg_afu_terminate_valid_dly1_d;
      cfg_terminate_process_q                      <= cfg_terminate_process_d;
      if ( cfg_terminate_pasid_en )
        cfg_terminate_pasid_q[19:0]                <= cfg_terminate_pasid_d[19:0];
      if ( cfg_terminate_process_pending_en )
        cfg_terminate_process_pending_q            <= cfg_terminate_process_pending_d;

//         nxt_terminate_req_q[511:0]                   <= nxt_terminate_req_d[511:0];

//         terminate_process_q                          <= terminate_process_d;
//         if ( terminate_pasid_en )
//           terminate_pasid_q[19:0]                    <= terminate_pasid_d[19:0];

//         if ( terminate_process_pending_en )
//           terminate_process_pending_q                <= terminate_process_pending_d;

      mmio_valid_200_q                             <= mmio_valid_200_d;
      mmio_addr_200_q[25:0]                        <= mmio_addr_200_d[25:0];

    end  // -- always @


  always @ ( posedge clock_tlx )
    begin
      // -- Even/Odd Clock determination (TLX clock domain)
      sample_q                                     <= sample_d;                     
      odd_q                                        <= odd_d;                        
      even_q                                       <= even_d;

      mmio_rd_q                                    <= mmio_rd_d;                    
      mmio_wr_q                                    <= mmio_wr_d;
      mmio_large_rd_q                              <= mmio_large_rd_d;                    
      mmio_large_wr_q                              <= mmio_large_wr_d;
      mmio_large_wr_half_en_q[1:0]                 <= mmio_large_wr_half_en_d[1:0];
      mmio_large_wr_half_en_dly1_q[1:0]            <= mmio_large_wr_half_en_q[1:0];
      mmio_rd_dly1_q                               <= mmio_rd_dly1_d;                    
      mmio_wr_dly1_q                               <= mmio_wr_dly1_d;
      mmio_large_rd_dly1_q                         <= mmio_large_rd_dly1_d;                    
      mmio_large_wr_dly1_q                         <= mmio_large_wr_dly1_d;
      mmio_valid_400_q                             <= mmio_valid_400_d;
                   
      if ( mmio_addr_en )
        mmio_addr_q[25:0]                          <= mmio_addr_d[25:0];
           
      if ( mmio_wrdata_en )
        mmio_wrdata_q[1023:0]                      <= mmio_wrdata_d[1023:0];
         
      mmio_early_wr_q                              <= mmio_early_wr_d;
      mmio_early_large_wr_q                        <= mmio_early_large_wr_d;
      mmio_early_large_wr_half_en_q[1:0]           <= mmio_early_large_wr_half_en_d[1:0];

      early_addr_is_afu_extra_ea_q                 <= early_addr_is_afu_extra_ea_d;
      early_addr_is_afu_misc_q                     <= early_addr_is_afu_misc_d;
      early_addr_is_afu_enable_q                   <= early_addr_is_afu_enable_d;
      early_addr_is_large_ping_pong_data0_q        <= early_addr_is_large_ping_pong_data0_d;
      early_addr_is_large_ping_pong_data1_q        <= early_addr_is_large_ping_pong_data1_d;
      early_addr_is_large_ping_pong_data2_q        <= early_addr_is_large_ping_pong_data2_d;
      early_addr_is_large_ping_pong_data3_q        <= early_addr_is_large_ping_pong_data3_d;

      mmio_wr_done_q                               <= mmio_wr_done_d;               
      mmio_rddata_valid_q                          <= mmio_rddata_valid_d;          
      mmio_rddata_q[1023:0]                        <= mmio_rddata_d[1023:0];          
      mmio_bad_op_or_align_q                       <= mmio_bad_op_or_align_d;       
      mmio_addr_not_implemented_q                  <= mmio_addr_not_implemented_d;  

      rd_afu_config_q                              <= rd_afu_config_d;
      rd_afu_config2_q                             <= rd_afu_config2_d;
      rd_afu_error_q                               <= rd_afu_error_d;
      rd_afu_error_info_q                          <= rd_afu_error_info_d;
      rd_afu_trace_ctl_q                           <= rd_afu_trace_ctl_d;
      rd_afu_stats_q                               <= rd_afu_stats_d;
      rd_afu_obj_handle_q                          <= rd_afu_obj_handle_d;
      rd_afu_extra_ea_q                            <= rd_afu_extra_ea_d;
      rd_afu_wed_q                                 <= rd_afu_wed_d;
      rd_afu_bufmask_q                             <= rd_afu_bufmask_d;
      rd_afu_pasid_q                               <= rd_afu_pasid_d;
      rd_afu_misc_q                                <= rd_afu_misc_d;
      rd_afu_enable_q                              <= rd_afu_enable_d;
      rd_afu_control_q                             <= rd_afu_control_d;
      rd_afu_display_ctl_q                         <= rd_afu_display_ctl_d;
      rd_large_ping_pong_data0_q                   <= rd_large_ping_pong_data0_d;
      rd_large_ping_pong_data1_q                   <= rd_large_ping_pong_data1_d;
      rd_large_ping_pong_data2_q                   <= rd_large_ping_pong_data2_d;
      rd_large_ping_pong_data3_q                   <= rd_large_ping_pong_data3_d;
      rd_process_handle_q                          <= rd_process_handle_d;
      rd_process_ctl_q                             <= rd_process_ctl_d;

      wr_afu_config_q                              <= wr_afu_config_d;
      wr_afu_config2_q                             <= wr_afu_config2_d;
      wr_afu_error_q                               <= wr_afu_error_d;
      wr_afu_error_info_q                          <= wr_afu_error_info_d;
      wr_afu_trace_ctl_q                           <= wr_afu_trace_ctl_d;
      wr_afu_stats_q                               <= wr_afu_stats_d;
      wr_afu_obj_handle_q                          <= wr_afu_obj_handle_d;
      wr_afu_extra_ea_q                            <= wr_afu_extra_ea_d;
      wr_afu_wed_q                                 <= wr_afu_wed_d;
      wr_afu_bufmask_q                             <= wr_afu_bufmask_d;
      wr_afu_pasid_q                               <= wr_afu_pasid_d;
      wr_afu_misc_q                                <= wr_afu_misc_d;
      wr_afu_enable_q                              <= wr_afu_enable_d;
      wr_afu_control_q                             <= wr_afu_control_d;
      wr_afu_latency_q                             <= wr_afu_latency_d;
      wr_afu_display_ctl_q                         <= wr_afu_display_ctl_d;
      wr_afu_display_data_q                        <= wr_afu_display_data_d;
      wr_afu_perf_count_q                          <= wr_afu_perf_count_d;
      wr_large_ping_pong_data0_q                   <= wr_large_ping_pong_data0_d;
      wr_large_ping_pong_data1_q                   <= wr_large_ping_pong_data1_d;
      wr_large_ping_pong_data2_q                   <= wr_large_ping_pong_data2_d;
      wr_large_ping_pong_data3_q                   <= wr_large_ping_pong_data3_d;
      ld_resp_ping_pong_data_q[3:0]                <= ld_resp_ping_pong_data_d[3:0];
      eng_mmio_data_q[1023:0]                      <= eng_mmio_data_d[1023:0];
      wr_process_ctl_q                             <= wr_process_ctl_d;

      rd_wed_dly1_q                                <= rd_wed_dly1_d;
      wr_wed_dly1_q                                <= wr_wed_dly1_d;

      mmio_weq_eng_disable_updated_dly1_q          <= mmio_weq_eng_disable_updated_dly1_d;
     
      if ( rd_wed_pending_en )
        rd_wed_pending_q                           <= rd_wed_pending_d;             
              
      if ( wr_wed_pending_en )
        wr_wed_pending_q                           <= wr_wed_pending_d;
          
      rd_process_status_dly1_q                     <= rd_process_status_dly1_d;
    
      if ( rd_process_status_pending_en )
        rd_process_status_pending_q                <= rd_process_status_pending_d;

      rd_intrpt_ctl_dly1_q                         <= rd_intrpt_ctl_dly1_d;
      wr_intrpt_ctl_dly1_q                         <= wr_intrpt_ctl_dly1_d;
      rd_intrpt_obj_dly1_q                         <= rd_intrpt_obj_dly1_d;
      wr_intrpt_obj_dly1_q                         <= wr_intrpt_obj_dly1_d;
      rd_intrpt_data_dly1_q                        <= rd_intrpt_data_dly1_d;
      wr_intrpt_data_dly1_q                        <= wr_intrpt_data_dly1_d;

      afu_control_dly1_q[63:60]                    <= afu_control_dly1_d[63:60];
      mmio_access_dly1_q                           <= mmio_access_dly1_d;
      mmio_access_dly2_q                           <= mmio_access_dly2_d;
      large_data_scorecard_q[7:0]                  <= large_data_scorecard_d[7:0];

      if ( rd_intrpt_ctl_pending_en )
        rd_intrpt_ctl_pending_q                    <= rd_intrpt_ctl_pending_d;             
              
      if ( wr_intrpt_ctl_pending_en )
        wr_intrpt_ctl_pending_q                    <= wr_intrpt_ctl_pending_d;
             
      if ( rd_intrpt_obj_pending_en )
        rd_intrpt_obj_pending_q                    <= rd_intrpt_obj_pending_d;             
              
      if ( wr_intrpt_obj_pending_en )
        wr_intrpt_obj_pending_q                    <= wr_intrpt_obj_pending_d;

      if ( rd_intrpt_data_pending_en )
        rd_intrpt_data_pending_q                   <= rd_intrpt_data_pending_d;             
              
      if ( wr_intrpt_data_pending_en )
        wr_intrpt_data_pending_q                   <= wr_intrpt_data_pending_d;

      afu_config_q[63:0]                           <= afu_config_d[63:0];           
      afu_config2_q[35:0]                          <= afu_config2_d[35:0];           
      afu_error_q[15:0]                            <= afu_error_d[15:0];            
      afu_error_info_q[31:0]                       <= afu_error_info_d[31:0];       
      afu_trace_ctl_q[63:0]                        <= afu_trace_ctl_d[63:0];        
      afu_stats_q[63:0]                            <= afu_stats_d[63:0];           
      afu_obj_handle_q[63:0]                       <= afu_obj_handle_d[63:0];
      afu_extra_ea_q[63:7]                         <= afu_extra_ea_d[63:7];
      afu_wed_q[63:0]                              <= afu_wed_d[63:0];
      afu_bufmask_q[31:12]                         <= afu_bufmask_d[31:12];
      afu_pasid_q[9:0]                             <= afu_pasid_d[9:0];
      afu_misc_q[35:0]                             <= afu_misc_d[35:0];
      afu_enable_q[63:57]                          <= afu_enable_d[63:57];
      afu_control_q[63:60]                         <= afu_control_d[63:60];
      afu_display_ctl_q[31:0]                      <= afu_display_ctl_d[31:0];
      large_ping_pong_data0_q[1023:0]              <= large_ping_pong_data0_d[1023:0];
      large_ping_pong_data1_q[1023:0]              <= large_ping_pong_data1_d[1023:0];
      large_ping_pong_data2_q[1023:0]              <= large_ping_pong_data2_d[1023:0];
      large_ping_pong_data3_q[1023:0]              <= large_ping_pong_data3_d[1023:0];
// -- process_ctl_q[63:0]                          <= process_ctl_d[63:0];        
      mmio_restart_process_dly1_q                  <= mmio_restart_process_dly1_d;  
      mmio_restart_process_dly2_q                  <= mmio_restart_process_dly2_d;

      if ( mmio_restart_process_pending_en )
        mmio_restart_process_pending_q             <= mmio_restart_process_pending_d;

      mmio_terminate_process_dly1_q                <= mmio_terminate_process_dly1_d;

      // -- Array Display latches
      rd_afu_display_data_q                        <= rd_afu_display_data_d;
//      rd_afu_display_data_dly1_q                   <= rd_afu_display_data_dly1_d;
      if ( rd_afu_display_data_pending_en )
        rd_afu_display_data_pending_q              <= rd_afu_display_data_pending_d;

      // -- Perf Count latches
      rd_afu_perf_count_q                          <= rd_afu_perf_count_d;
      rd_afu_latency_q                             <= rd_afu_latency_d;
      if ( rd_afu_perf_count_pending_en )
        rd_afu_perf_count_pending_q                <= rd_afu_perf_count_pending_d;

    end  // -- always @

endmodule
