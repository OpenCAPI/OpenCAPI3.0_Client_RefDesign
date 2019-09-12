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

module afp3_eng_resp_decode (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  , input                 xtouch_wt4rsp_enable_q

  // -- Response Interface
  , input                 rspi_eng_resp_valid
  , input          [15:0] rspi_eng_resp_afutag
  , input           [7:0] rspi_eng_resp_opcode
  , input           [3:0] rspi_eng_resp_code
  , input           [1:0] rspi_eng_resp_dl
  , input           [1:0] rspi_eng_resp_dp

  , input        [1023:0] rspi_eng_resp_data_bus
  , input           [1:0] rspi_eng_resp_data_bdi

  // -- Sequencer States
  , input                 main_idle_st
  , input                 we_ld_wt4rsp_st
  , input                 xtouch_idle_st  // -- Multiple cmds, so need to consider may not be in wt4rsp_st yet
  , input                 cpy_ld_idle_st  // -- Multiple cmds, so need to consider may not be in wt4rsp_st yet
  , input                 cpy_st_idle_st  // -- Multiple cmds, so need to consider may not be in wt4rsp_st yet
  , input                 wkhstthrd_wt4rsp_st
  , input                 incr_wt4ldrsp_st
  , input                 incr_wt4strsp_st
  , input                 atomic_wt4rsp_st
  , input                 intrpt_wt4rsp_st
  , input                 we_st_wt4rsp_st

  , input                 we_cmd_is_atomic_ld_q
  , input                 we_cmd_is_atomic_st_q
  , input                 we_cmd_is_atomic_cas_q

  // -- Cmdo afutag for checking
  , input                 cmdo_valid
  , input          [15:0] cmdo_afutag

  // -- Data Error Terms from copy sequencers
  , input                 cpy_cmd_resp_rcvd_overlap
  , input                 cpy_cmd_resp_rcvd_mismatch

  // -- Outputs
  , output reg            rspi_resp_is_we_ld_rtry_w_backoff_q
  , output reg            rspi_resp_is_xtouch_source_rtry_w_backoff_q 
  , output reg            rspi_resp_is_xtouch_dest_rtry_w_backoff_q
  , output reg            rspi_resp_is_cpy_ld_rtry_w_backoff_q
  , output reg            rspi_resp_is_cpy_st_rtry_w_backoff_q
  , output reg            rspi_resp_is_wkhstthrd_rtry_w_backoff_q
  , output reg            rspi_resp_is_incr_rtry_w_backoff_q
  , output reg            rspi_resp_is_atomic_rtry_w_backoff_q
  , output reg            rspi_resp_is_intrpt_rtry_w_backoff_q
  , output reg            rspi_resp_is_we_st_rtry_w_backoff_q

  , output                rspi_resp_is_rtry_req 
  , output                rspi_resp_is_rtry_lwt  

  , output                rspi_resp_is_rtry 
  , output                rspi_resp_is_xtouch_rtry  

  // -- Error cases for logging or bugspray
  , output                rcvd_touch_resp_when_not_expected
  , output                rcvd_touch_resp_w_bad_afutag
  , output                rcvd_unexpected_resp_w_xtouch_afutag

  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                rcvd_ld_resp_when_not_expected
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                rcvd_ld_resp_w_bad_afutag
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                rcvd_unexpected_resp_w_ld_afutag

  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                rcvd_st_resp_when_not_expected
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                rcvd_st_resp_w_bad_afutag
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                rcvd_unexpected_resp_w_st_afutag

  , output                rcvd_wake_host_resp_when_not_expected
  , output                rcvd_wake_host_resp_w_bad_afutag
  , output                rcvd_unexpected_resp_w_wkhstthrd_afutag

  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                rcvd_intrp_resp_when_not_expected
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                rcvd_intrp_resp_w_bad_afutag
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                rcvd_unexpected_resp_w_intrpt_afutag

  , output                undefined_rspi_we_ld_afutag
  , output                undefined_rspi_xtouch_afutag
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                undefined_rspi_cpy_afutag
  , output                undefined_rspi_wkhstthrd_afutag
  , output                undefined_rspi_incr_afutag
  , output                undefined_rspi_atomic_afutag
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                undefined_rspi_intrpt_afutag

  , output                undefined_cmdo_we_ld_afutag
  , output                undefined_cmdo_xtouch_afutag
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                undefined_cmdo_cpy_afutag
  , output                undefined_cmdo_wkhstthrd_afutag
  , output                undefined_cmdo_incr_afutag
  , output                undefined_cmdo_atomic_afutag
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output                undefined_cmdo_intrpt_afutag

  // -- Send Latched Valid to sequencers (ie. Indication of DONE, NOT Retried)
  , output reg            rspi_we_ld_resp_val_q
  , output reg            rspi_xtouch_source_resp_val_q
  , output reg            rspi_xtouch_dest_resp_val_q
  , output reg            rspi_cpy_ld_resp_val_q
  , output reg            rspi_cpy_st_resp_val_q
  , output reg            rspi_incr_ld_resp_val_q
  , output reg            rspi_incr_st_resp_val_q
  , output reg            rspi_atomic_ld_resp_val_q
  , output reg            rspi_atomic_st_resp_val_q
  , output                rspi_atomic_cas_resp_val_d
  , output reg            rspi_wkhstthrd_resp_val_q
  , output reg            rspi_intrpt_resp_val_q
  , output reg            rspi_we_st_resp_val_q

  // -- Send Pending Cnt to retry queue to block reads
  , output          [4:0] pending_cnt_q

  // -- Send latched response decodes to be stored in the retry queue
  , output                rspi_resp_is_pending_q
  , output                rspi_resp_is_rtry_hwt_q
  , output                rspi_resp_is_rtry_req_q
  , output                rspi_resp_is_rtry_lwt_q

  // -- Send Latched Errors to wr_weq sequencer for inclusion in status
  , output                rspi_resp_fault_q
  , output                rspi_resp_failed_q
  , output                rspi_resp_aerror_q
  , output                rspi_resp_derror_q

  , output                we_ld_error_q
  , output                xtouch_source_error_q
  , output                xtouch_dest_error_q
  , output                cpy_ld_error_q                              
  , output                cpy_st_error_q
  , output                wkhstthrd_error_q
  , output                incr_ld_error_q
  , output                incr_st_error_q
  , output                atomic_ld_error_q
  , output                atomic_st_error_q
  , output                atomic_cas_error_q
  , output                intrpt_cmd_error_q
  , output                intrpt_err_error_q
  , output                intrpt_wht_error_q
  , output                we_st_error_q

  , output                xtouch_error_q
  , output                cpy_error_q                              
  , output                incr_error_q
  , output                atomic_error_q
  , output                intrpt_error_q

  , output                error_q

  // -- Send latched outputs to other modules
  , output                rspi_resp_is_cpy_xx_q
  , output                rspi_resp_is_cpy_st_q
  , output          [8:0] rspi_resp_afutag_q
  , output          [7:0] rspi_resp_opcode_q
  , output          [3:0] rspi_resp_code_q
  , output          [1:0] rspi_resp_dl_orig_q
  , output          [1:0] rspi_resp_dl_q
  , output          [1:0] rspi_resp_dp_q

  , output          [0:0] rspi_resp_afutag_dbuf_q
  , output          [1:0] rspi_resp_dl_dbuf_q

  , output       [1023:0] rspi_resp_data_q
  , output          [1:0] rspi_resp_data_bdi_q
  , output                rspi_resp_data_valid_q
  , output                rspi_resp_data_valid_xfer2_q

  , output                unexpected_xlate_or_intrpt_done_200

  , output                eng_perf_wkhstthrd_good

  , output          [3:0] eng_mmio_extra_read_resp
  , output       [1023:0] eng_mmio_data

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- Response AFUTAG decode
  wire            rspi_resp_afutag_is_we_ld;
  wire            rspi_resp_afutag_is_xtouch_source;
  wire            rspi_resp_afutag_is_xtouch_dest;
  wire            rspi_resp_afutag_is_cpy_ld;
  wire            rspi_resp_afutag_is_cpy_st;
  wire            rspi_resp_afutag_is_wkhstthrd;
  wire            rspi_resp_afutag_is_intrpt_wht;
  wire            rspi_resp_afutag_is_incr_ld;
  wire            rspi_resp_afutag_is_incr_st;
  wire            rspi_resp_afutag_is_atomic_ld;
  wire            rspi_resp_afutag_is_atomic_st;
  wire            rspi_resp_afutag_is_atomic_cas;
  wire            rspi_resp_afutag_is_intrpt_err;
  wire            rspi_resp_afutag_is_intrpt_cmd;
  wire            rspi_resp_afutag_is_we_st;

  // -- Response AFUTAG decode groupings
  wire            rspi_resp_afutag_is_xtouch;
  wire            rspi_resp_afutag_is_cpy;
  wire            rspi_resp_afutag_is_incr;
  wire            rspi_resp_afutag_is_atomic;
  wire            rspi_resp_afutag_is_intrpt;

  wire            rspi_resp_afutag_is_ld;
  wire            rspi_resp_afutag_is_st;

  // -- Response Opcode decode
  wire            rspi_resp_is_nop;
  wire            rspi_resp_is_read_response;
  wire            rspi_resp_is_write_response;
  wire            rspi_resp_is_read_failed;
  wire            rspi_resp_is_write_failed;
  wire            rspi_resp_is_intrp_resp;
  wire            rspi_resp_is_xlate_done;
  wire            rspi_resp_is_intrp_rdy;
  wire            rspi_resp_is_touch_resp;
  wire            rspi_resp_is_wake_host_resp;

  // -- Response Code decode
  wire            rspi_resp_code_is_done;
  wire            rspi_resp_code_is_rty_hwt;
  wire            rspi_resp_code_is_rty_req;
  wire            rspi_resp_code_is_rty_lwt;
  wire            rspi_resp_code_is_xlate_pending;
  wire            rspi_resp_code_is_intrp_pending;
  wire            rspi_resp_code_is_thread_not_found;
  wire            rspi_resp_code_is_derror;
  wire            rspi_resp_code_is_bad_length;
  wire            rspi_resp_code_is_bad_addr;
  wire            rspi_resp_code_is_bad_handle;
  wire            rspi_resp_code_is_failed;
  wire            rspi_resp_code_is_adr_error;

  wire     [10:0] rspi_resp_xtouch_sel;
  wire     [13:0] rspi_resp_ld_sel;
  wire     [13:0] rspi_resp_st_sel;
  wire     [11:0] rspi_resp_wkhstthrd_sel;
  wire     [10:0] rspi_resp_intrpt_sel;

  reg      [11:0] rspi_resp_xtouch_decode;
  reg      [11:0] rspi_resp_ld_decode;
  reg      [11:0] rspi_resp_st_decode;
  reg      [11:0] rspi_resp_wkhstthrd_decode;
  reg      [11:0] rspi_resp_intrpt_decode;

  wire            xtouch_resp_expected;
  wire            any_ld_resp_expected;
  wire            any_st_resp_expected;
  wire            wkhstthrd_resp_expected;
  wire            intrpt_resp_expected;

  // -- Output AFUTAG decode
  wire            cmdo_afutag_is_we_ld;
  wire            cmdo_afutag_is_xtouch_source;
  wire            cmdo_afutag_is_xtouch_dest;
  wire            cmdo_afutag_is_cpy_ld;
  wire            cmdo_afutag_is_cpy_st;
  wire            cmdo_afutag_is_wkhstthrd;
  wire            cmdo_afutag_is_intrpt_wht;
  wire            cmdo_afutag_is_incr_ld;
  wire            cmdo_afutag_is_incr_st;
  wire            cmdo_afutag_is_atomic_ld;
  wire            cmdo_afutag_is_atomic_st;
  wire            cmdo_afutag_is_atomic_cas;
  wire            cmdo_afutag_is_intrpt_err;
  wire            cmdo_afutag_is_intrpt_cmd;
  wire            cmdo_afutag_is_we_st;

  // -- Output AFUTAG decode groupings
  wire            cmdo_afutag_is_xtouch;
  wire            cmdo_afutag_is_cpy;
  wire            cmdo_afutag_is_incr;
  wire            cmdo_afutag_is_atomic;
  wire            cmdo_afutag_is_intrpt;


  // -- Decodes per Sequencer (non-retry)
  wire            rspi_resp_is_we_ld_good;      
  wire            rspi_resp_is_we_ld_rtry_hwt;
  wire            rspi_resp_is_we_ld_rtry_req;
  wire            rspi_resp_is_we_ld_rtry_lwt;
  wire            rspi_resp_is_we_ld_pending;   
  wire            rspi_resp_is_we_ld_derror;    
  wire            rspi_resp_is_we_ld_fault;     
  wire            rspi_resp_is_we_ld_failed;    
  wire            rspi_resp_is_we_ld_aerror;    
  wire            rspi_resp_is_we_ld_pending_done;
  wire            rspi_resp_is_we_ld_rtry;      
  wire            rspi_resp_is_we_ld_done;
    
  wire            rspi_resp_is_xtouch_source_good;
  wire            rspi_resp_is_xtouch_source_rtry_hwt;
  wire            rspi_resp_is_xtouch_source_rtry_req;
  wire            rspi_resp_is_xtouch_source_rtry_lwt;
  wire            rspi_resp_is_xtouch_source_pending;
  wire            rspi_resp_is_xtouch_source_derror;
  wire            rspi_resp_is_xtouch_source_fault;
  wire            rspi_resp_is_xtouch_source_failed;
  wire            rspi_resp_is_xtouch_source_aerror;
  wire            rspi_resp_is_xtouch_source_pending_done;
  wire            rspi_resp_is_xtouch_source_rtry;
  wire            rspi_resp_is_xtouch_source_done;

  wire            rspi_resp_is_xtouch_dest_good;
  wire            rspi_resp_is_xtouch_dest_rtry_hwt;
  wire            rspi_resp_is_xtouch_dest_rtry_req;
  wire            rspi_resp_is_xtouch_dest_rtry_lwt;
  wire            rspi_resp_is_xtouch_dest_pending;
  wire            rspi_resp_is_xtouch_dest_derror;
  wire            rspi_resp_is_xtouch_dest_fault;
  wire            rspi_resp_is_xtouch_dest_failed;
  wire            rspi_resp_is_xtouch_dest_aerror;
  wire            rspi_resp_is_xtouch_dest_pending_done;
  wire            rspi_resp_is_xtouch_dest_rtry;
  wire            rspi_resp_is_xtouch_dest_done;

  wire            rspi_resp_is_cpy_ld_good;     
  wire            rspi_resp_is_cpy_ld_rtry_hwt;
  wire            rspi_resp_is_cpy_ld_rtry_req;
  wire            rspi_resp_is_cpy_ld_rtry_lwt;
  wire            rspi_resp_is_cpy_ld_pending;  
  wire            rspi_resp_is_cpy_ld_derror;   
  wire            rspi_resp_is_cpy_ld_fault;    
  wire            rspi_resp_is_cpy_ld_failed;   
  wire            rspi_resp_is_cpy_ld_aerror;   
  wire            rspi_resp_is_cpy_ld_pending_done;
  wire            rspi_resp_is_cpy_ld_rtry;     
  wire            rspi_resp_is_cpy_ld_done;
     
  wire            rspi_resp_is_cpy_st_good;     
  wire            rspi_resp_is_cpy_st_rtry_hwt;
  wire            rspi_resp_is_cpy_st_rtry_req;
  wire            rspi_resp_is_cpy_st_rtry_lwt;
  wire            rspi_resp_is_cpy_st_pending;  
  wire            rspi_resp_is_cpy_st_derror;   
  wire            rspi_resp_is_cpy_st_fault;    
  wire            rspi_resp_is_cpy_st_failed;   
  wire            rspi_resp_is_cpy_st_aerror;   
  wire            rspi_resp_is_cpy_st_pending_done;
  wire            rspi_resp_is_cpy_st_rtry;     
  wire            rspi_resp_is_cpy_st_done;
   
  wire            rspi_resp_is_wkhstthrd_good;  
  wire            rspi_resp_is_wkhstthrd_rtry_hwt;
  wire            rspi_resp_is_wkhstthrd_rtry_req;
  wire            rspi_resp_is_wkhstthrd_rtry_lwt;
  wire            rspi_resp_is_wkhstthrd_pending;
  wire            rspi_resp_is_wkhstthrd_derror;
  wire            rspi_resp_is_wkhstthrd_fault; 
  wire            rspi_resp_is_wkhstthrd_failed;
  wire            rspi_resp_is_wkhstthrd_aerror;
  wire            rspi_resp_is_wkhstthrd_pending_done;
  wire            rspi_resp_is_wkhstthrd_rtry;  
  wire            rspi_resp_is_wkhstthrd_done;
 
  wire            rspi_resp_is_incr_ld_good;    
  wire            rspi_resp_is_incr_ld_rtry_hwt;
  wire            rspi_resp_is_incr_ld_rtry_req;
  wire            rspi_resp_is_incr_ld_rtry_lwt;
  wire            rspi_resp_is_incr_ld_pending; 
  wire            rspi_resp_is_incr_ld_derror;  
  wire            rspi_resp_is_incr_ld_fault;   
  wire            rspi_resp_is_incr_ld_failed;  
  wire            rspi_resp_is_incr_ld_aerror;  
  wire            rspi_resp_is_incr_ld_pending_done;
  wire            rspi_resp_is_incr_ld_rtry;    
  wire            rspi_resp_is_incr_ld_done;
   
  wire            rspi_resp_is_incr_st_good;    
  wire            rspi_resp_is_incr_st_rtry_hwt;
  wire            rspi_resp_is_incr_st_rtry_req;
  wire            rspi_resp_is_incr_st_rtry_lwt;
  wire            rspi_resp_is_incr_st_pending; 
  wire            rspi_resp_is_incr_st_derror;  
  wire            rspi_resp_is_incr_st_fault;   
  wire            rspi_resp_is_incr_st_failed;  
  wire            rspi_resp_is_incr_st_aerror;  
  wire            rspi_resp_is_incr_st_pending_done;
  wire            rspi_resp_is_incr_st_rtry;    
  wire            rspi_resp_is_incr_st_done;
   
  wire            rspi_resp_is_atomic_ld_good;  
  wire            rspi_resp_is_atomic_ld_rtry_hwt;
  wire            rspi_resp_is_atomic_ld_rtry_req;
  wire            rspi_resp_is_atomic_ld_rtry_lwt;
  wire            rspi_resp_is_atomic_ld_pending;
  wire            rspi_resp_is_atomic_ld_derror;
  wire            rspi_resp_is_atomic_ld_fault; 
  wire            rspi_resp_is_atomic_ld_failed;
  wire            rspi_resp_is_atomic_ld_aerror;
  wire            rspi_resp_is_atomic_ld_pending_done;
  wire            rspi_resp_is_atomic_ld_rtry;  
  wire            rspi_resp_is_atomic_ld_done;
  
  wire            rspi_resp_is_atomic_st_good;  
  wire            rspi_resp_is_atomic_st_rtry_hwt;
  wire            rspi_resp_is_atomic_st_rtry_req;
  wire            rspi_resp_is_atomic_st_rtry_lwt;
  wire            rspi_resp_is_atomic_st_pending;
  wire            rspi_resp_is_atomic_st_derror;
  wire            rspi_resp_is_atomic_st_fault; 
  wire            rspi_resp_is_atomic_st_failed;
  wire            rspi_resp_is_atomic_st_aerror;
  wire            rspi_resp_is_atomic_st_pending_done;
  wire            rspi_resp_is_atomic_st_rtry;  
  wire            rspi_resp_is_atomic_st_done;
 
  wire            rspi_resp_is_atomic_cas_good; 
  wire            rspi_resp_is_atomic_cas_rtry_hwt;
  wire            rspi_resp_is_atomic_cas_rtry_req;
  wire            rspi_resp_is_atomic_cas_rtry_lwt;
  wire            rspi_resp_is_atomic_cas_pending;
  wire            rspi_resp_is_atomic_cas_derror;
  wire            rspi_resp_is_atomic_cas_fault;
  wire            rspi_resp_is_atomic_cas_failed;
  wire            rspi_resp_is_atomic_cas_aerror;
  wire            rspi_resp_is_atomic_cas_pending_done;
  wire            rspi_resp_is_atomic_cas_rtry; 
  wire            rspi_resp_is_atomic_cas_done;
 
  wire            rspi_resp_is_intrpt_cmd_good;     
  wire            rspi_resp_is_intrpt_cmd_rtry_hwt;
  wire            rspi_resp_is_intrpt_cmd_rtry_req;
  wire            rspi_resp_is_intrpt_cmd_rtry_lwt;
  wire            rspi_resp_is_intrpt_cmd_pending;  
  wire            rspi_resp_is_intrpt_cmd_derror;   
  wire            rspi_resp_is_intrpt_cmd_fault;    
  wire            rspi_resp_is_intrpt_cmd_failed;   
  wire            rspi_resp_is_intrpt_cmd_aerror;   
  wire            rspi_resp_is_intrpt_cmd_pending_done;
  wire            rspi_resp_is_intrpt_cmd_rtry;     
  wire            rspi_resp_is_intrpt_cmd_done;
     
  wire            rspi_resp_is_intrpt_err_good;     
  wire            rspi_resp_is_intrpt_err_rtry_hwt;
  wire            rspi_resp_is_intrpt_err_rtry_req;
  wire            rspi_resp_is_intrpt_err_rtry_lwt;
  wire            rspi_resp_is_intrpt_err_pending;  
  wire            rspi_resp_is_intrpt_err_derror;   
  wire            rspi_resp_is_intrpt_err_fault;    
  wire            rspi_resp_is_intrpt_err_failed;   
  wire            rspi_resp_is_intrpt_err_aerror;   
  wire            rspi_resp_is_intrpt_err_pending_done;
  wire            rspi_resp_is_intrpt_err_rtry;     
  wire            rspi_resp_is_intrpt_err_done;
     
  wire            rspi_resp_is_intrpt_wht_good;     
  wire            rspi_resp_is_intrpt_wht_rtry_hwt;
  wire            rspi_resp_is_intrpt_wht_rtry_req;
  wire            rspi_resp_is_intrpt_wht_rtry_lwt;
  wire            rspi_resp_is_intrpt_wht_pending;  
  wire            rspi_resp_is_intrpt_wht_derror;   
  wire            rspi_resp_is_intrpt_wht_fault;    
  wire            rspi_resp_is_intrpt_wht_failed;   
  wire            rspi_resp_is_intrpt_wht_aerror;   
  wire            rspi_resp_is_intrpt_wht_pending_done;
  wire            rspi_resp_is_intrpt_wht_rtry;     
  wire            rspi_resp_is_intrpt_wht_done;
     
  wire            rspi_resp_is_we_st_good;      
  wire            rspi_resp_is_we_st_rtry_hwt;
  wire            rspi_resp_is_we_st_rtry_req;
  wire            rspi_resp_is_we_st_rtry_lwt;
  wire            rspi_resp_is_we_st_pending;   
  wire            rspi_resp_is_we_st_derror;    
  wire            rspi_resp_is_we_st_fault;     
  wire            rspi_resp_is_we_st_failed;    
  wire            rspi_resp_is_we_st_aerror;    
  wire            rspi_resp_is_we_st_pending_done;
  wire            rspi_resp_is_we_st_rtry;      
  wire            rspi_resp_is_we_st_done;
      
  wire            rspi_resp_is_ld_good;         
  wire            rspi_resp_is_ld_rtry_hwt;   
  wire            rspi_resp_is_ld_rtry_req;   
  wire            rspi_resp_is_ld_rtry_lwt;   
  wire            rspi_resp_is_ld_pending;      
  wire            rspi_resp_is_ld_derror;       
  wire            rspi_resp_is_ld_fault;        
  wire            rspi_resp_is_ld_failed;       
  wire            rspi_resp_is_ld_aerror;       
  wire            rspi_resp_is_ld_pending_done; 
  wire            rspi_resp_is_ld_rtry;         
  wire            rspi_resp_is_ld_done;
        
  wire            rspi_resp_is_st_good;         
  wire            rspi_resp_is_st_rtry_hwt;   
  wire            rspi_resp_is_st_rtry_req;   
  wire            rspi_resp_is_st_rtry_lwt;   
  wire            rspi_resp_is_st_pending;      
  wire            rspi_resp_is_st_derror;       
  wire            rspi_resp_is_st_fault;        
  wire            rspi_resp_is_st_failed;       
  wire            rspi_resp_is_st_aerror;       
  wire            rspi_resp_is_st_pending_done; 
  wire            rspi_resp_is_st_rtry;         
  wire            rspi_resp_is_st_done;
        
  wire            rspi_resp_is_xtouch_good;     
  wire            rspi_resp_is_xtouch_rtry_hwt;
  wire            rspi_resp_is_xtouch_rtry_req;
  wire            rspi_resp_is_xtouch_rtry_lwt;
  wire            rspi_resp_is_xtouch_pending;  
  wire            rspi_resp_is_xtouch_derror;   
  wire            rspi_resp_is_xtouch_fault;    
  wire            rspi_resp_is_xtouch_failed;   
  wire            rspi_resp_is_xtouch_aerror;   
  wire            rspi_resp_is_xtouch_pending_done;
//wire            rspi_resp_is_xtouch_rtry;     
  wire            rspi_resp_is_xtouch_done;
    
  wire            rspi_resp_is_cpy_good;        
  wire            rspi_resp_is_cpy_rtry_hwt;  
  wire            rspi_resp_is_cpy_rtry_req;  
  wire            rspi_resp_is_cpy_rtry_lwt;  
  wire            rspi_resp_is_cpy_pending;     
  wire            rspi_resp_is_cpy_derror;      
  wire            rspi_resp_is_cpy_fault;       
  wire            rspi_resp_is_cpy_failed;      
  wire            rspi_resp_is_cpy_aerror;      
  wire            rspi_resp_is_cpy_pending_done;
  wire            rspi_resp_is_cpy_rtry;        
  wire            rspi_resp_is_cpy_done;
       
  wire            rspi_resp_is_incr_good;       
  wire            rspi_resp_is_incr_rtry_hwt; 
  wire            rspi_resp_is_incr_rtry_req;
  wire            rspi_resp_is_incr_rtry_lwt;
  wire            rspi_resp_is_incr_pending;    
  wire            rspi_resp_is_incr_derror;     
  wire            rspi_resp_is_incr_fault;      
  wire            rspi_resp_is_incr_failed;     
  wire            rspi_resp_is_incr_aerror;     
  wire            rspi_resp_is_incr_pending_done;
  wire            rspi_resp_is_incr_rtry;       
  wire            rspi_resp_is_incr_done;
       
  wire            rspi_resp_is_atomic_good;     
  wire            rspi_resp_is_atomic_rtry_hwt;
  wire            rspi_resp_is_atomic_rtry_req;
  wire            rspi_resp_is_atomic_rtry_lwt;
  wire            rspi_resp_is_atomic_pending;  
  wire            rspi_resp_is_atomic_derror;   
  wire            rspi_resp_is_atomic_fault;    
  wire            rspi_resp_is_atomic_failed;   
  wire            rspi_resp_is_atomic_aerror;   
  wire            rspi_resp_is_atomic_pending_done;
  wire            rspi_resp_is_atomic_rtry;     
  wire            rspi_resp_is_atomic_done;
     
  wire            rspi_resp_is_intrpt_good;     
  wire            rspi_resp_is_intrpt_rtry_hwt;
  wire            rspi_resp_is_intrpt_rtry_req;
  wire            rspi_resp_is_intrpt_rtry_lwt;
  wire            rspi_resp_is_intrpt_pending;  
  wire            rspi_resp_is_intrpt_derror;   
  wire            rspi_resp_is_intrpt_fault;    
  wire            rspi_resp_is_intrpt_failed;   
  wire            rspi_resp_is_intrpt_aerror;   
  wire            rspi_resp_is_intrpt_pending_done;
  wire            rspi_resp_is_intrpt_rtry;     
  wire            rspi_resp_is_intrpt_done;
    
  wire            rspi_resp_is_good_int;            
  wire            rspi_resp_is_rtry_hwt_int;      
  wire            rspi_resp_is_rtry_req_int;      
  wire            rspi_resp_is_rtry_lwt_int;      
  wire            rspi_resp_is_pending_int;         
  wire            rspi_resp_is_derror_int;          
  wire            rspi_resp_is_fault_int;           
  wire            rspi_resp_is_failed_int;          
  wire            rspi_resp_is_aerror_int;          
  wire            rspi_resp_is_pending_done_int;    
  wire            rspi_resp_is_rtry_int;            
  wire            rspi_resp_is_done_int;

  wire            we_ld_bdi_error;
  wire            cpy_ld_bdi_error;
  wire            incr_ld_bdi_error;
  wire            atomic_ld_bdi_error;
  wire            atomic_cas_bdi_error;

  // -- Error Signals per sequencer   
  wire            rspi_resp_is_we_ld_error;
  wire            rspi_resp_is_xtouch_source_error;
  wire            rspi_resp_is_xtouch_dest_error;
  wire            rspi_resp_is_cpy_ld_error;
  wire            rspi_resp_is_cpy_st_error;
  wire            rspi_resp_is_wkhstthrd_error;
  wire            rspi_resp_is_incr_ld_error;
  wire            rspi_resp_is_incr_st_error;
  wire            rspi_resp_is_atomic_ld_error;
  wire            rspi_resp_is_atomic_st_error;
  wire            rspi_resp_is_atomic_cas_error;
  wire            rspi_resp_is_intrpt_cmd_error;
  wire            rspi_resp_is_intrpt_err_error;
  wire            rspi_resp_is_intrpt_wht_error;
  wire            rspi_resp_is_we_st_error;

  wire            rspi_resp_is_xtouch_error;
  wire            rspi_resp_is_cpy_error;
  wire            rspi_resp_is_incr_error;
  wire            rspi_resp_is_atomic_error;
  wire            rspi_resp_is_intrpt_error;

  wire            rspi_resp_is_error;

  wire            undefined_cmdo_incr_ld_afutag;
  wire            undefined_cmdo_incr_st_afutag;
  wire            undefined_rspi_incr_ld_afutag;
  wire            undefined_rspi_incr_st_afutag;

  wire      [5:0] data_reg_sel;

 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            unexpected_xlate_done;

  // -- ********************************************************************************************************************************
  // -- Latch Signal Declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  // -- Response latches
  reg       [0:0] rspi_resp_afutag_dbuf_int_d;
  reg       [0:0] rspi_resp_afutag_dbuf_int_q;
  reg       [1:0] rspi_resp_dl_dbuf_int_d;
  reg       [1:0] rspi_resp_dl_dbuf_int_q;

  wire            rspi_resp_is_cpy_xx_int_d;
  reg             rspi_resp_is_cpy_xx_int_q;
  wire            rspi_resp_is_cpy_st_int_d;
  reg             rspi_resp_is_cpy_st_int_q;
  wire      [9:0] rspi_resp_afutag_int_d;
  reg       [9:0] rspi_resp_afutag_int_q;
  wire      [7:0] rspi_resp_opcode_int_d;
  reg       [7:0] rspi_resp_opcode_int_q;
  wire      [3:0] rspi_resp_code_int_d;
  reg       [3:0] rspi_resp_code_int_q;
  wire      [1:0] rspi_resp_dl_orig_int_d;
  reg       [1:0] rspi_resp_dl_orig_int_q;
  wire      [1:0] rspi_resp_dl_int_d;
  reg       [1:0] rspi_resp_dl_int_q;
  wire      [1:0] rspi_resp_dp_int_d;
  reg       [1:0] rspi_resp_dp_int_q;

  wire   [1023:0] rspi_resp_data_int_d;
  reg    [1023:0] rspi_resp_data_int_q;
  wire      [1:0] rspi_resp_data_bdi_int_d;
  reg       [1:0] rspi_resp_data_bdi_int_q;
  wire            rspi_resp_data_valid_int_d;
  reg             rspi_resp_data_valid_int_q;
  reg             rspi_resp_data_valid_xfer2_int_d;
  reg             rspi_resp_data_valid_xfer2_int_q;

  // -- Responsed Valid latches per sequencer
  wire            rspi_we_ld_resp_val_d;
  wire            rspi_xtouch_source_resp_val_d;
  wire            rspi_xtouch_dest_resp_val_d;
  wire            rspi_cpy_ld_resp_val_d;
  wire            rspi_cpy_st_resp_val_d;
  wire            rspi_incr_ld_resp_val_d;
  wire            rspi_incr_st_resp_val_d;
  wire            rspi_atomic_ld_resp_val_d;
  wire            rspi_atomic_st_resp_val_d;
  wire            rspi_atomic_cas_resp_val_int_d;
  reg             rspi_atomic_cas_resp_val_int_q;
  wire            rspi_wkhstthrd_resp_val_d;
  wire            rspi_intrpt_resp_val_d;
  wire            rspi_we_st_resp_val_d;

  // -- Latches that will feed into Retry Queue
  wire            rspi_resp_is_pending_int_d; 
  reg             rspi_resp_is_pending_int_q;  // -- increments pending cnt
  wire            rspi_resp_is_rtry_lwt_int_d;
  reg             rspi_resp_is_rtry_lwt_int_q;
  wire            rspi_resp_is_rtry_req_int_d;
  reg             rspi_resp_is_rtry_req_int_q;
  wire            rspi_resp_is_rtry_hwt_int_d;
  reg             rspi_resp_is_rtry_hwt_int_q;

  // -- Latch used to decrement Pending Cnt
  wire            rspi_resp_is_pending_done_d;
  reg             rspi_resp_is_pending_done_q;

  wire            rspi_resp_is_we_ld_rtry_w_backoff_d;
//reg             rspi_resp_is_we_ld_rtry_w_backoff_q;
  wire            rspi_resp_is_xtouch_source_rtry_w_backoff_d; 
//reg             rspi_resp_is_xtouch_source_rtry_w_backoff_q; 
  wire            rspi_resp_is_xtouch_dest_rtry_w_backoff_d;
//reg             rspi_resp_is_xtouch_dest_rtry_w_backoff_q;   
  wire            rspi_resp_is_cpy_ld_rtry_w_backoff_d;
//reg             rspi_resp_is_cpy_ld_rtry_w_backoff_q;        
  wire            rspi_resp_is_cpy_st_rtry_w_backoff_d;
//reg             rspi_resp_is_cpy_st_rtry_w_backoff_q;        
  wire            rspi_resp_is_wkhstthrd_rtry_w_backoff_d;
//reg             rspi_resp_is_wkhstthrd_rtry_w_backoff_q;     
  wire            rspi_resp_is_incr_rtry_w_backoff_d;
//reg             rspi_resp_is_incr_rtry_w_backoff_q;          
  wire            rspi_resp_is_atomic_rtry_w_backoff_d;
//reg             rspi_resp_is_atomic_rtry_w_backoff_q;        
  wire            rspi_resp_is_intrpt_rtry_w_backoff_d;
//reg             rspi_resp_is_intrpt_rtry_w_backoff_q;        
  wire            rspi_resp_is_we_st_rtry_w_backoff_d;
//reg             rspi_resp_is_we_st_rtry_w_backoff_q;         

  // -- To Performance
  wire            rspi_resp_is_wkhstthrd_good_d;
  reg             rspi_resp_is_wkhstthrd_good_q;

  // -- Extra Read mode
  reg       [3:0] extra_read_reg_d;
  reg       [3:0] extra_read_reg_q;

  // -- Pending Cnt Latches
  wire            pending_cnt_int_en;
  reg       [4:0] pending_cnt_int_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [4:0] pending_cnt_int_q;

  wire            pending_cnt_max_en;
  reg       [4:0] pending_cnt_max_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [4:0] pending_cnt_max_q;

  wire            pending_cnt_total_en;
  reg       [7:0] pending_cnt_total_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] pending_cnt_total_q;

  // -- Error Latches
  reg             rspi_resp_fault_int_d;
  reg             rspi_resp_fault_int_q;
  reg             rspi_resp_failed_int_d;
  reg             rspi_resp_failed_int_q;
  reg             rspi_resp_aerror_int_d;
  reg             rspi_resp_aerror_int_q;
  reg             rspi_resp_derror_int_d;
  reg             rspi_resp_derror_int_q;

  reg             we_ld_error_int_d;
  reg             we_ld_error_int_q;
  reg             xtouch_source_error_int_d;
  reg             xtouch_source_error_int_q;
  reg             xtouch_dest_error_int_d;
  reg             xtouch_dest_error_int_q;
  reg             cpy_ld_error_int_d;
  reg             cpy_ld_error_int_q;
  reg             cpy_st_error_int_d;
  reg             cpy_st_error_int_q;
  reg             wkhstthrd_error_int_d;
  reg             wkhstthrd_error_int_q;
  reg             incr_ld_error_int_d;
  reg             incr_ld_error_int_q;
  reg             incr_st_error_int_d;
  reg             incr_st_error_int_q;
  reg             atomic_ld_error_int_d;
  reg             atomic_ld_error_int_q;
  reg             atomic_st_error_int_d;
  reg             atomic_st_error_int_q;
  reg             atomic_cas_error_int_d;
  reg             atomic_cas_error_int_q;
  reg             intrpt_cmd_error_int_d;
  reg             intrpt_cmd_error_int_q;
  reg             intrpt_err_error_int_d;
  reg             intrpt_err_error_int_q;
  reg             intrpt_wht_error_int_d;
  reg             intrpt_wht_error_int_q;
  reg             we_st_error_int_d;
  reg             we_st_error_int_q;

  // -- Grouped Error Latches
  reg             xtouch_error_int_d;
  reg             xtouch_error_int_q;
  reg             cpy_error_int_d;
  reg             cpy_error_int_q;
  reg             incr_error_int_d;
  reg             incr_error_int_q;
  reg             atomic_error_int_d;
  reg             atomic_error_int_q;
  reg             intrpt_error_int_d;
  reg             intrpt_error_int_q;

  reg             error_int_d;
  reg             error_int_q;

  wire            unexpected_xlate_or_intrpt_done_200_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             unexpected_xlate_or_intrpt_done_200_q;

  wire            rspi_resp_is_xlate_pending_d;         
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             rspi_resp_is_xlate_pending_q;

  wire            rspi_resp_is_intrp_pending_d;         
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             rspi_resp_is_intrp_pending_q;

  wire            back_to_back_xlate_pending_and_done_d;         
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             back_to_back_xlate_pending_and_done_q;

  wire            back_to_back_intrp_pending_and_rdy_d;         
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             back_to_back_intrp_pending_and_rdy_q;


  // -- ********************************************************************************************************************************
  // -- Constant declarations
  // -- ********************************************************************************************************************************

  // -- TL CAPP response encodes
  localparam    [7:0] TLX_AFU_RESP_ENCODE_NOP                  = 8'b00000000;  // -- Nop
  localparam    [7:0] TLX_AFU_RESP_ENCODE_RETURN_TLX_CREDITS   = 8'b00000001;  // -- Return TLX Credits
  localparam    [7:0] TLX_AFU_RESP_ENCODE_TOUCH_RESP           = 8'b00000010;  // -- Touch Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_READ_RESPONSE        = 8'b00000100;  // -- Read Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_UPGRADE_RESP         = 8'b00000111;  // -- Upgrade Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_READ_FAILED          = 8'b00000101;  // -- Read Failed
  localparam    [7:0] TLX_AFU_RESP_ENCODE_CL_RD_RESP           = 8'b00000110;  // -- Cachable Read Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_WRITE_RESPONSE       = 8'b00001000;  // -- Write Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_WRITE_FAILED         = 8'b00001001;  // -- Write Failed
  localparam    [7:0] TLX_AFU_RESP_ENCODE_MEM_FLUSH_DONE       = 8'b00001010;  // -- Memory Flush Done
  localparam    [7:0] TLX_AFU_RESP_ENCODE_INTRP_RESP           = 8'b00001100;  // -- Interrupt Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_WAKE_HOST_RESP       = 8'b00010000;  // -- Wake Host Thread Response

  localparam    [7:0] TLX_AFU_RESP_ENCODE_XLATE_DONE           = 8'b00011000;  // -- Address Translation Completed (Async Notification)
  localparam    [7:0] TLX_AFU_RESP_ENCODE_INTRP_RDY            = 8'b00011010;  // -- Interrupt ready (Async Notification)

  // -- TL CAP response code encodes
  localparam    [3:0] TLX_AFU_RESP_CODE_DONE                   = 4'b0000;      // -- Done
  localparam    [3:0] TLX_AFU_RESP_CODE_RTY_HWT                = 4'b0001;      // -- Retry Xlate Touch w/ Heavy Weight
  localparam    [3:0] TLX_AFU_RESP_CODE_RTY_REQ                = 4'b0010;      // -- Retry Heavy weight (long backoff timer)                                 
  localparam    [3:0] TLX_AFU_RESP_CODE_LW_RTY_REQ             = 4'b0011;      // -- Retry Light Weight (short backoff timer)                                 
  localparam    [3:0] TLX_AFU_RESP_CODE_XLATE_PENDING          = 4'b0100;      // -- Toss, wait for xlate done with same AFU tag, convert to Retry
  localparam    [3:0] TLX_AFU_RESP_CODE_INTRP_PENDING          = 4'b0100;      // -- Toss, wait for intrp rdy with same AFU tag, convert to Retry
  localparam    [3:0] TLX_AFU_RESP_CODE_THREAD_NOT_FOUND       = 4'b0101;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_DERROR                 = 4'b1000;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_LENGTH             = 4'b1001;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_ADDR               = 4'b1011;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_HANDLE             = 4'b1011;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_FAILED                 = 4'b1110;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_ADR_ERROR              = 4'b1111;      // -- Machine Check

  // -- AFUTAG Encode
  localparam    [4:0] ACTAG_AFUTAG_ENCODE                      = 5'b00000;     // -- AFUTAG[4:0] for actag cmd                   ( AFUTAG[11] = b'1 )
  localparam    [4:0] WE_LD_AFUTAG_ENCODE                      = 5'b00001;     // -- AFUTAG[4:0] for we_ld cmd                   ( AFUTAG[11] = b'1 )
  localparam    [4:0] XTOUCH_SOURCE_AFUTAG_ENCODE              = 5'b00010;     // -- AFUTAG[4:0] for xtouch_source cmd           ( AFUTAG[11] = b'1 )
  localparam    [4:0] XTOUCH_DEST_AFUTAG_ENCODE                = 5'b00011;     // -- AFUTAG[4:0] for xtouch_dest cmd             ( AFUTAG[11] = b'1 )
  localparam    [4:0] WKHSTTHRD_AFUTAG_ENCODE                  = 5'b00110;     // -- AFUTAG[4:0] for wkhstthrd cmd               ( AFUTAG[11] = b'1 )
  localparam    [4:0] INTRPT_WHT_AFUTAG_ENCODE                 = 5'b00111;     // -- AFUTAG[4:0] for intrpt due to wkhstthrd cmd ( AFUTAG[11] = b'1, AFUTAG[12] = b'1 if "intrpt_w_data" )
  localparam    [4:0] INCR_LD_AFUTAG_ENCODE                    = 5'b01000;     // -- AFUTAG[4:0] for incr ld cmd                 ( AFUTAG[11] = b'1 )
  localparam    [4:0] INCR_ST_AFUTAG_ENCODE                    = 5'b01001;     // -- AFUTAG[4:0] for incr st cmd                 ( AFUTAG[11] = b'1 )
  localparam    [4:0] ATOMIC_LD_AFUTAG_ENCODE                  = 5'b01010;     // -- AFUTAG[4:0] for atomic ld cmd               ( AFUTAG[11] = b'1 )
  localparam    [4:0] ATOMIC_ST_AFUTAG_ENCODE                  = 5'b01011;     // -- AFUTAG[4:0] for atomic st cmd               ( AFUTAG[11] = b'1 )
  localparam    [4:0] ATOMIC_CAS_AFUTAG_ENCODE                 = 5'b01100;     // -- AFUTAG[4:0] for atomic cas cmd              ( AFUTAG[11] = b'1 )
  localparam    [4:0] INTRPT_ERR_AFUTAG_ENCODE                 = 5'b01101;     // -- AFUTAG[4:0] for intrpt due to error         ( AFUTAG[11] = b'1, AFUTAG[12] = b'1 if "intrpt_w_data" )
  localparam    [4:0] INTRPT_CMD_AFUTAG_ENCODE                 = 5'b01110;     // -- AFUTAG[4:0] for intrpt cmd                  ( AFUTAG[11] = b'1, AFUTAG[12] = b'1 if "intrpt_w_data" )
  localparam    [4:0] WE_ST_AFUTAG_ENCODE                      = 5'b01111;     // -- AFUTAG[4:0] for we_ld cmd                   ( AFUTAG[11] = b'1 )


  // -- ********************************************************************************************************************************
  // -- Decode Response
  // -- ********************************************************************************************************************************

  // -- Response AFUTAG decodes
  assign  rspi_resp_afutag_is_we_ld          =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == WE_LD_AFUTAG_ENCODE[4:0]         ));
  assign  rspi_resp_afutag_is_xtouch_source  =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == XTOUCH_SOURCE_AFUTAG_ENCODE[4:0] ));
  assign  rspi_resp_afutag_is_xtouch_dest    =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == XTOUCH_DEST_AFUTAG_ENCODE[4:0]   ));
  assign  rspi_resp_afutag_is_cpy_ld         =  (~rspi_eng_resp_afutag[11] &&  ~rspi_eng_resp_afutag[13]                                       );
  assign  rspi_resp_afutag_is_cpy_st         =  (~rspi_eng_resp_afutag[11] &&   rspi_eng_resp_afutag[13]                                       );
  assign  rspi_resp_afutag_is_wkhstthrd      =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == WKHSTTHRD_AFUTAG_ENCODE [4:0]    ));
  assign  rspi_resp_afutag_is_intrpt_wht     =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == INTRPT_WHT_AFUTAG_ENCODE[4:0]    ));  // -- AFUTAG[12] = b'1 if "intrpt_w_data"
  assign  rspi_resp_afutag_is_incr_ld        =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == INCR_LD_AFUTAG_ENCODE[4:0]       ));
  assign  rspi_resp_afutag_is_incr_st        =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == INCR_ST_AFUTAG_ENCODE[4:0]       ));
  assign  rspi_resp_afutag_is_atomic_ld      =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == ATOMIC_LD_AFUTAG_ENCODE[4:0]     ));
  assign  rspi_resp_afutag_is_atomic_st      =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == ATOMIC_ST_AFUTAG_ENCODE[4:0]     ));
  assign  rspi_resp_afutag_is_atomic_cas     =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == ATOMIC_CAS_AFUTAG_ENCODE[4:0]    ));
  assign  rspi_resp_afutag_is_intrpt_err     =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == INTRPT_ERR_AFUTAG_ENCODE[4:0]    ));  // -- AFUTAG[12] = b'1 if "intrpt_w_data"
  assign  rspi_resp_afutag_is_intrpt_cmd     =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == INTRPT_CMD_AFUTAG_ENCODE[4:0]    ));  // -- AFUTAG[12] = b'1 if "intrpt_w_data"
  assign  rspi_resp_afutag_is_we_st          =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:0] == WE_ST_AFUTAG_ENCODE[4:0]         ));

  // -- Group Response AFUTAG decodes for sequencers that can issue more than one type of command
  assign  rspi_resp_afutag_is_cpy            =  (~rspi_eng_resp_afutag[11] );                                                                               // -- cpy_ld or cpy_st
  assign  rspi_resp_afutag_is_xtouch         =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:1] == XTOUCH_SOURCE_AFUTAG_ENCODE[4:1] ));           // -- xtouch seq issues two commands - both can be outstanding
  assign  rspi_resp_afutag_is_incr           =  ( rspi_eng_resp_afutag[11] && ( rspi_eng_resp_afutag[4:1] == INCR_LD_AFUTAG_ENCODE[4:1]       ));           // -- incr   seq issues two commands - serially. (ld must complete before st can be issued)
  assign  rspi_resp_afutag_is_atomic         =  ( rspi_resp_afutag_is_atomic_ld     || rspi_resp_afutag_is_atomic_st  || rspi_resp_afutag_is_atomic_cas );  // -- atomic seq issues only 1 cmd (can be 1 of 3 types) 
  assign  rspi_resp_afutag_is_intrpt         =  ( rspi_resp_afutag_is_intrpt_cmd    || rspi_resp_afutag_is_intrpt_err || rspi_resp_afutag_is_intrpt_wht );  // -- intrpt seq issues only 1 cmd (can be 1 of 3 types)

  // -- Group Response AFUTAT
  assign  rspi_resp_afutag_is_ld             =  ( rspi_resp_afutag_is_we_ld  || rspi_resp_afutag_is_cpy_ld  || rspi_resp_afutag_is_incr_ld   || rspi_resp_afutag_is_atomic_ld || rspi_resp_afutag_is_atomic_cas ); 
  assign  rspi_resp_afutag_is_st             =  ( rspi_resp_afutag_is_cpy_st || rspi_resp_afutag_is_incr_st || rspi_resp_afutag_is_atomic_st || rspi_resp_afutag_is_we_st ); 

  // -- Response Encode
  assign  rspi_resp_is_nop                   =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_NOP[7:0]            );
  assign  rspi_resp_is_read_response         =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_READ_RESPONSE[7:0]  );  // -- good response
  assign  rspi_resp_is_write_response        =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_WRITE_RESPONSE[7:0] );  // -- good response
  assign  rspi_resp_is_read_failed           =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_READ_FAILED[7:0]    );  // -- failed response, check resp code
  assign  rspi_resp_is_write_failed          =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_WRITE_FAILED[7:0]   );  // -- failed response, check resp code
  assign  rspi_resp_is_intrp_resp            =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_INTRP_RESP[7:0]     );  // -- check resp code
  assign  rspi_resp_is_xlate_done            =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_XLATE_DONE[7:0]     );  // -- check resp code
  assign  rspi_resp_is_intrp_rdy             =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_INTRP_RDY[7:0]      );  // -- check resp code
  assign  rspi_resp_is_touch_resp            =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_TOUCH_RESP[7:0]     );  // -- check resp code
  assign  rspi_resp_is_wake_host_resp        =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_WAKE_HOST_RESP[7:0] );  // -- check resp code

  // -- Response codes
  assign  rspi_resp_code_is_done             =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_DONE[3:0]             );  // -- Done
  assign  rspi_resp_code_is_rty_hwt          =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_RTY_HWT[3:0]          );  // -- Retry xlate touch w/ heavy weight        -> rtry_queue
  assign  rspi_resp_code_is_rty_req          =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_RTY_REQ[3:0]          );  // -- Retry Heavy weight (long backoff timer)  -> rtry_queue
  assign  rspi_resp_code_is_rty_lwt          =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_LW_RTY_REQ[3:0]       );  // -- Retry Light weight (short backoff timer) -> rtry_queue
  assign  rspi_resp_code_is_xlate_pending    =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_XLATE_PENDING[3:0]    );  // -- Pending                                  -> rtry_queue, wait for xlate done with same AFU tag, Retry
  assign  rspi_resp_code_is_intrp_pending    =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_INTRP_PENDING[3:0]    );  // -- Pending                                  -> rtry_queue, wait for intrp rdy  with same AFU tag, Retry
  assign  rspi_resp_code_is_thread_not_found =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_THREAD_NOT_FOUND[3:0] );  // -- Machine Check - FAULT 
  assign  rspi_resp_code_is_derror           =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_DERROR[3:0]           );  // -- Machine Check - DERROR
  assign  rspi_resp_code_is_bad_length       =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_BAD_LENGTH[3:0]       );  // -- Machine Check - FAULT
  assign  rspi_resp_code_is_bad_addr         =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_BAD_ADDR[3:0]         );  // -- Machine Check - FAULT 
  assign  rspi_resp_code_is_bad_handle       =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_BAD_HANDLE[3:0]       );  // -- Machine Check - FAULT
  assign  rspi_resp_code_is_failed           =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_FAILED[3:0]           );  // -- Machine Check - FAILED
  assign  rspi_resp_code_is_adr_error        =  ( rspi_eng_resp_code[3:0] == TLX_AFU_RESP_CODE_ADR_ERROR[3:0]        );  // -- Machine Check - AERROR


  // -- ********************************************************************************************************************************
  // --  xtouch decode 
  // -- ********************************************************************************************************************************

  assign  xtouch_resp_expected                 =  ( ~xtouch_idle_st && xtouch_wt4rsp_enable_q );
  assign  rcvd_touch_resp_when_not_expected    =  ( rspi_eng_resp_valid &&  rspi_resp_is_touch_resp && ( ~xtouch_wt4rsp_enable_q || ( xtouch_wt4rsp_enable_q && xtouch_idle_st )));
  assign  rcvd_touch_resp_w_bad_afutag         =  ( rspi_eng_resp_valid &&  rspi_resp_is_touch_resp && ~rspi_resp_afutag_is_xtouch );
  assign  rcvd_unexpected_resp_w_xtouch_afutag =  ( rspi_eng_resp_valid && ~rspi_resp_is_touch_resp && ~rspi_resp_is_xlate_done && rspi_resp_afutag_is_xtouch );

  assign  rspi_resp_xtouch_sel[10:0] = { rspi_eng_resp_valid, rspi_resp_is_touch_resp, rspi_resp_is_xlate_done,                                             // -- Response Decode
                                         xtouch_resp_expected,                                                                                              // -- Qualify with sequencer state
                                         rspi_resp_code_is_done,                                                                                            // -- done                               -> Done
                                         rspi_resp_code_is_rty_hwt, rspi_resp_code_is_rty_req, rspi_resp_code_is_rty_lwt, rspi_resp_code_is_xlate_pending,  // -- rty_hwt, rty_req_ rty_lwt, pending -> Rtry 
                                         rspi_resp_code_is_failed,  rspi_resp_code_is_adr_error };                                                          // -- derror,fault,failed,aerror         -> Done

  always @*
    begin
      casez ( rspi_resp_xtouch_sel[10:0] )
        // --                                    
        // --  Inputs                                                 Outputs              
        // --  -------------------                                    ---------------------              
        // --  rspi_eng_resp_valid                                    rspi_resp_is_xtouch_good           
        // --  |                                                      |rspi_resp_is_xtouch_rtry_hwt      
        // --  | rspi_resp_is_touch_resp                              ||rspi_resp_is_xtouch_rtry_req              
        // --  | |rspi_resp_is_xlate_done                             |||rspi_resp_is_xtouch_rtry_lwt  
        // --  | ||xtouch_resp_expected                               ||||rspi_resp_is_xtouch_pending
        // --  | |||                                                  |||||rspi_resp_is_xtouch_derror
        // --  | ||| rspi_resp_code_is_done                           ||||||rspi_resp_is_xtouch_fault    
        // --  | ||| |rspi_resp_code_is_rty_hwt                       |||||||rspi_resp_is_xtouch_failed  
        // --  | ||| ||rspi_resp_code_is_rty_req                      ||||||||rspi_resp_is_xtouch_aerror 
        // --  | ||| |||rspi_resp_code_is_rty_lwt                     |||||||||           
        // --  | ||| ||||rspi_resp_code_is_xlate_pending              ||||||||| rspi_resp_is_xtouch_pending_done            
        // --  | ||| |||||rspi_resp_code_is_failed                    ||||||||| |rspi_resp_is_xtouch_rtry               
        // --  | ||| ||||||rspi_resp_code_is_adr_error                ||||||||| ||rspi_resp_is_xtouch_done          
        // --  1 ||| |||||||                                          11||||||| |||                       
        // --  0 987 6543210                                          109876543 210
        // ------------------------------------------------------------------------
           11'b1_1?1_1??????  :  rspi_resp_xtouch_decode[11:0] =  12'b100000000_001 ;  // -- touch_resp - done          - done
           11'b1_1?1_01?????  :  rspi_resp_xtouch_decode[11:0] =  12'b010000000_010 ;  // -- touch_resp - rty_hwt       - retry
           11'b1_1?1_001????  :  rspi_resp_xtouch_decode[11:0] =  12'b001000000_010 ;  // -- touch_resp - rty_req       - retry
           11'b1_1?1_0001???  :  rspi_resp_xtouch_decode[11:0] =  12'b000100000_010 ;  // -- touch_resp - rty_lwt       - retry
           11'b1_1?1_00001??  :  rspi_resp_xtouch_decode[11:0] =  12'b000010000_010 ;  // -- touch_resp - xlate_pending - retry
           11'b1_1?1_000001?  :  rspi_resp_xtouch_decode[11:0] =  12'b000000010_001 ;  // -- touch_resp - failed        - done  - set failed latch
        // ------------------------------------------------------------------------
           11'b1_011_1??????  :  rspi_resp_xtouch_decode[11:0] =  12'b000000000_100 ;  // -- xlate_done - done          - release xlate_pending retry from retry queue
           11'b1_011_0?1????  :  rspi_resp_xtouch_decode[11:0] =  12'b001000000_100 ;  // -- xlate_done - rty_req       - release xlate_pending retry from retry queue
           11'b1_011_0?0???1  :  rspi_resp_xtouch_decode[11:0] =  12'b000000001_101 ;  // -- xlate_done - adr_error     - done  - set aerror latch - abort from retry queue
        // ------------------------------------------------------------------------
           default            :  rspi_resp_xtouch_decode[11:0] =  12'b000000000_000 ;  // 
        // ------------------------------------------------------------------------
      endcase
    end // -- always @ *

  assign  rspi_resp_is_xtouch_good                =  rspi_resp_xtouch_decode[11] && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_rtry_hwt            =  rspi_resp_xtouch_decode[10] && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_rtry_req            =  rspi_resp_xtouch_decode[9]  && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_rtry_lwt            =  rspi_resp_xtouch_decode[8]  && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_pending             =  rspi_resp_xtouch_decode[7]  && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_derror              =  rspi_resp_xtouch_decode[6]  && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_fault               =  rspi_resp_xtouch_decode[5]  && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_failed              =  rspi_resp_xtouch_decode[4]  && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_aerror              =  rspi_resp_xtouch_decode[3]  && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_pending_done        =  rspi_resp_xtouch_decode[2]  && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_rtry                =  rspi_resp_xtouch_decode[1]  && rspi_resp_afutag_is_xtouch;
  assign  rspi_resp_is_xtouch_done                =  rspi_resp_xtouch_decode[0]  && rspi_resp_afutag_is_xtouch;
                                                                            
  assign  rspi_resp_is_xtouch_source_good         =  rspi_resp_xtouch_decode[11] && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_rtry_hwt     =  rspi_resp_xtouch_decode[10] && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_rtry_req     =  rspi_resp_xtouch_decode[9]  && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_rtry_lwt     =  rspi_resp_xtouch_decode[8]  && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_pending      =  rspi_resp_xtouch_decode[7]  && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_derror       =  rspi_resp_xtouch_decode[6]  && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_fault        =  rspi_resp_xtouch_decode[5]  && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_failed       =  rspi_resp_xtouch_decode[4]  && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_aerror       =  rspi_resp_xtouch_decode[3]  && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_pending_done =  rspi_resp_xtouch_decode[2]  && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_rtry         =  rspi_resp_xtouch_decode[1]  && rspi_resp_afutag_is_xtouch_source;
  assign  rspi_resp_is_xtouch_source_done         =  rspi_resp_xtouch_decode[0]  && rspi_resp_afutag_is_xtouch_source;
                                                                            
  assign  rspi_resp_is_xtouch_dest_good           =  rspi_resp_xtouch_decode[11] && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_rtry_hwt       =  rspi_resp_xtouch_decode[10] && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_rtry_req       =  rspi_resp_xtouch_decode[9]  && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_rtry_lwt       =  rspi_resp_xtouch_decode[8]  && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_pending        =  rspi_resp_xtouch_decode[7]  && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_derror         =  rspi_resp_xtouch_decode[6]  && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_fault          =  rspi_resp_xtouch_decode[5]  && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_failed         =  rspi_resp_xtouch_decode[4]  && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_aerror         =  rspi_resp_xtouch_decode[3]  && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_pending_done   =  rspi_resp_xtouch_decode[2]  && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_rtry           =  rspi_resp_xtouch_decode[1]  && rspi_resp_afutag_is_xtouch_dest;
  assign  rspi_resp_is_xtouch_dest_done           =  rspi_resp_xtouch_decode[0]  && rspi_resp_afutag_is_xtouch_dest;


  // -- ********************************************************************************************************************************
  // -- ld decode 
  // -- ********************************************************************************************************************************

  assign  any_ld_resp_expected              =  ( we_ld_wt4rsp_st || ~cpy_ld_idle_st || incr_wt4ldrsp_st || ( atomic_wt4rsp_st && ( we_cmd_is_atomic_ld_q || we_cmd_is_atomic_cas_q )));
  assign  rcvd_ld_resp_when_not_expected    =  ( rspi_eng_resp_valid &&  ( rspi_resp_is_read_response || rspi_resp_is_read_failed ) && ~any_ld_resp_expected );
  assign  rcvd_ld_resp_w_bad_afutag         =  ( rspi_eng_resp_valid &&  ( rspi_resp_is_read_response || rspi_resp_is_read_failed ) && ~rspi_resp_afutag_is_ld );
  assign  rcvd_unexpected_resp_w_ld_afutag  =  ( rspi_eng_resp_valid && ~( rspi_resp_is_read_response || rspi_resp_is_read_failed || rspi_resp_is_xlate_done ) && rspi_resp_afutag_is_ld );

  assign  rspi_resp_ld_sel[13:0] = { rspi_eng_resp_valid, rspi_resp_is_read_response, rspi_resp_is_read_failed, rspi_resp_is_xlate_done,                                             // -- Response Decode
                                     any_ld_resp_expected,                                                                                                                           // -- Qualify with sequencer active
                                     rspi_resp_code_is_done,                                                                                                                         // -- done                               -> Done
                                     rspi_resp_code_is_rty_req, rspi_resp_code_is_rty_lwt, rspi_resp_code_is_xlate_pending,                                                          // -- rty_hwt, rty_req_ rty_lwt, pending -> Rtry 
                                     rspi_resp_code_is_derror,  rspi_resp_code_is_bad_length, rspi_resp_code_is_bad_addr, rspi_resp_code_is_failed,  rspi_resp_code_is_adr_error };  // -- derror,fault,failed,aerror         -> Done

  always @*
    begin
      casez ( rspi_resp_ld_sel[13:0] )
        // --                                    
        // --  Inputs                                                                      
        // --  -------------------
        // --  rspi_eng_resp_valid                                          
        // --  |                                                     Outputs              
        // --  | rspi_resp_is_read_response                          ---------------------           
        // --  | |rspi_resp_is_read_failed                           rspi_resp_is_ld_good               
        // --  | ||rspi_resp_is_xlate_done                           |rspi_resp_is_ld_rtry_hwt       
        // --  | |||any_ld_resp_expected                             ||rspi_resp_is_ld_rtry_req       
        // --  | ||||                                                |||rspi_resp_is_ld_rtry_lwt  
        // --  | |||| rspi_resp_code_is_done                         ||||rspi_resp_is_ld_pending
        // --  | |||| |rspi_resp_code_is_rty_req                     |||||rspi_resp_is_ld_derror
        // --  | |||| ||rspi_resp_code_is_rty_lwt                    ||||||rspi_resp_is_ld_fault    
        // --  | |||| |||rspi_resp_code_is_xlate_pending             |||||||rspi_resp_is_ld_failed  
        // --  | |||| ||||rspi_resp_code_is_derror                   ||||||||rspi_resp_is_ld_aerror  
        // --  | |||| |||||rspi_resp_code_is_bad_length              |||||||||   
        // --  | |||| ||||||rspi_resp_code_is_bad_addr               ||||||||| rspi_resp_is_ld_pending_done            
        // --  | |||| |||||||rspi_resp_code_is_failed                ||||||||| |rspi_resp_is_ld_rtry   
        // --  | |||| ||||||||rspi_resp_code_is_adr_error            ||||||||| ||rspi_resp_is_ld_done  
        // --  1 11|| |||||||||                                      11||||||| |||                      
        // --  3 2109 876543210                                      109876543 210
        // -----------------------------------------------------------------------
           14'b1_1??1_?????????  :  rspi_resp_ld_decode[11:0] =  12'b100000000_001 ;  // -- read_response               - done
        // -----------------------------------------------------------------------
           14'b1_01?1_?1???????  :  rspi_resp_ld_decode[11:0] =  12'b001000000_010 ;  // -- read_failed - rty_req       - retry
           14'b1_01?1_?01??????  :  rspi_resp_ld_decode[11:0] =  12'b000100000_010 ;  // -- read_failed - rty_lwt       - retry
           14'b1_01?1_?001?????  :  rspi_resp_ld_decode[11:0] =  12'b000010000_010 ;  // -- read_failed - xlate_pending - retry
           14'b1_01?1_?0001????  :  rspi_resp_ld_decode[11:0] =  12'b000001000_001 ;  // -- read_failed - derror        - done - set derror latch
           14'b1_01?1_?00001???  :  rspi_resp_ld_decode[11:0] =  12'b000000100_001 ;  // -- read_failed - bad_length    - done - set fault  latch 
           14'b1_01?1_?000001??  :  rspi_resp_ld_decode[11:0] =  12'b000000100_001 ;  // -- read_failed - bad_addr      - done - set fault  latch
           14'b1_01?1_?0000001?  :  rspi_resp_ld_decode[11:0] =  12'b000000010_001 ;  // -- read_failed - failed        - done - set failed latch
        // -----------------------------------------------------------------------
           14'b1_0011_1????????  :  rspi_resp_ld_decode[11:0] =  12'b000000000_100 ;  // -- xlate_done - done           - release xlate_pending retry from retry queue 
           14'b1_0011_01???????  :  rspi_resp_ld_decode[11:0] =  12'b001000000_100 ;  // -- xlate_done - rty_req        - release xlate_pending retry from retry queue
           14'b1_0011_00??????1  :  rspi_resp_ld_decode[11:0] =  12'b000000001_101 ;  // -- xlate_done - adr_error      - done - set aerror latch- abort from retry queue
        // -----------------------------------------------------------------------
           default               :  rspi_resp_ld_decode[11:0] =  12'b000000000_000 ;  //
        // -----------------------------------------------------------------------
      endcase
    end // -- always @ *

  assign  rspi_resp_is_ld_good                 =  rspi_resp_ld_decode[11] && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_rtry_hwt             =  rspi_resp_ld_decode[10] && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_rtry_req             =  rspi_resp_ld_decode[9]  && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_rtry_lwt             =  rspi_resp_ld_decode[8]  && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_pending              =  rspi_resp_ld_decode[7]  && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_derror               =  rspi_resp_ld_decode[6]  && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_fault                =  rspi_resp_ld_decode[5]  && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_failed               =  rspi_resp_ld_decode[4]  && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_aerror               =  rspi_resp_ld_decode[3]  && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_pending_done         =  rspi_resp_ld_decode[2]  && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_rtry                 =  rspi_resp_ld_decode[1]  && rspi_resp_afutag_is_ld;
  assign  rspi_resp_is_ld_done                 =  rspi_resp_ld_decode[0]  && rspi_resp_afutag_is_ld;
                                                                     
  assign  rspi_resp_is_we_ld_good              =  rspi_resp_ld_decode[11] && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_rtry_hwt          =  rspi_resp_ld_decode[10] && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_rtry_req          =  rspi_resp_ld_decode[9]  && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_rtry_lwt          =  rspi_resp_ld_decode[8]  && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_pending           =  rspi_resp_ld_decode[7]  && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_derror            =  rspi_resp_ld_decode[6]  && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_fault             =  rspi_resp_ld_decode[5]  && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_failed            =  rspi_resp_ld_decode[4]  && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_aerror            =  rspi_resp_ld_decode[3]  && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_pending_done      =  rspi_resp_ld_decode[2]  && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_rtry              =  rspi_resp_ld_decode[1]  && rspi_resp_afutag_is_we_ld;
  assign  rspi_resp_is_we_ld_done              =  rspi_resp_ld_decode[0]  && rspi_resp_afutag_is_we_ld;
                                                                     
  assign  rspi_resp_is_cpy_ld_good             =  rspi_resp_ld_decode[11] && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_rtry_hwt         =  rspi_resp_ld_decode[10] && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_rtry_req         =  rspi_resp_ld_decode[9]  && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_rtry_lwt         =  rspi_resp_ld_decode[8]  && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_pending          =  rspi_resp_ld_decode[7]  && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_derror           =  rspi_resp_ld_decode[6]  && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_fault            =  rspi_resp_ld_decode[5]  && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_failed           =  rspi_resp_ld_decode[4]  && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_aerror           =  rspi_resp_ld_decode[3]  && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_pending_done     =  rspi_resp_ld_decode[2]  && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_rtry             =  rspi_resp_ld_decode[1]  && rspi_resp_afutag_is_cpy_ld;
  assign  rspi_resp_is_cpy_ld_done             =  rspi_resp_ld_decode[0]  && rspi_resp_afutag_is_cpy_ld;
                                                                     
  assign  rspi_resp_is_incr_ld_good            =  rspi_resp_ld_decode[11] && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_rtry_hwt        =  rspi_resp_ld_decode[10] && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_rtry_req        =  rspi_resp_ld_decode[9]  && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_rtry_lwt        =  rspi_resp_ld_decode[8]  && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_pending         =  rspi_resp_ld_decode[7]  && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_derror          =  rspi_resp_ld_decode[6]  && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_fault           =  rspi_resp_ld_decode[5]  && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_failed          =  rspi_resp_ld_decode[4]  && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_aerror          =  rspi_resp_ld_decode[3]  && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_pending_done    =  rspi_resp_ld_decode[2]  && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_rtry            =  rspi_resp_ld_decode[1]  && rspi_resp_afutag_is_incr_ld;
  assign  rspi_resp_is_incr_ld_done            =  rspi_resp_ld_decode[0]  && rspi_resp_afutag_is_incr_ld;
                                                                     
  assign  rspi_resp_is_atomic_ld_good          =  rspi_resp_ld_decode[11] && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_rtry_hwt      =  rspi_resp_ld_decode[10] && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_rtry_req      =  rspi_resp_ld_decode[9]  && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_rtry_lwt      =  rspi_resp_ld_decode[8]  && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_pending       =  rspi_resp_ld_decode[7]  && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_derror        =  rspi_resp_ld_decode[6]  && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_fault         =  rspi_resp_ld_decode[5]  && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_failed        =  rspi_resp_ld_decode[4]  && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_aerror        =  rspi_resp_ld_decode[3]  && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_pending_done  =  rspi_resp_ld_decode[2]  && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_rtry          =  rspi_resp_ld_decode[1]  && rspi_resp_afutag_is_atomic_ld;
  assign  rspi_resp_is_atomic_ld_done          =  rspi_resp_ld_decode[0]  && rspi_resp_afutag_is_atomic_ld;
                                              
  assign  rspi_resp_is_atomic_cas_good         =  rspi_resp_ld_decode[11] && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_rtry_hwt     =  rspi_resp_ld_decode[10] && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_rtry_req     =  rspi_resp_ld_decode[9]  && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_rtry_lwt     =  rspi_resp_ld_decode[8]  && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_pending      =  rspi_resp_ld_decode[7]  && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_derror       =  rspi_resp_ld_decode[6]  && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_fault        =  rspi_resp_ld_decode[5]  && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_failed       =  rspi_resp_ld_decode[4]  && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_aerror       =  rspi_resp_ld_decode[3]  && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_pending_done =  rspi_resp_ld_decode[2]  && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_rtry         =  rspi_resp_ld_decode[1]  && rspi_resp_afutag_is_atomic_cas;
  assign  rspi_resp_is_atomic_cas_done         =  rspi_resp_ld_decode[0]  && rspi_resp_afutag_is_atomic_cas;


  // -- ********************************************************************************************************************************
  // -- st decode 
  // -- ********************************************************************************************************************************

  assign  any_st_resp_expected              =  ( ~cpy_st_idle_st || incr_wt4strsp_st || ( atomic_wt4rsp_st && we_cmd_is_atomic_st_q ) || we_st_wt4rsp_st );
  assign  rcvd_st_resp_when_not_expected    =  ( rspi_eng_resp_valid &&  ( rspi_resp_is_write_response || rspi_resp_is_write_failed ) && ~any_st_resp_expected );
  assign  rcvd_st_resp_w_bad_afutag         =  ( rspi_eng_resp_valid &&  ( rspi_resp_is_write_response || rspi_resp_is_write_failed ) && ~rspi_resp_afutag_is_st );
  assign  rcvd_unexpected_resp_w_st_afutag  =  ( rspi_eng_resp_valid && ~( rspi_resp_is_write_response || rspi_resp_is_write_failed || rspi_resp_is_xlate_done ) && rspi_resp_afutag_is_st );

  assign rspi_resp_st_sel[13:0] = { rspi_eng_resp_valid, rspi_resp_is_write_response, rspi_resp_is_write_failed, rspi_resp_is_xlate_done,                                           // -- Response Decode
                                    any_st_resp_expected,                                                                                                                           // -- Qualify with sequencer active
                                    rspi_resp_code_is_done,                                                                                                                         // -- done                               -> Done
                                    rspi_resp_code_is_rty_req, rspi_resp_code_is_rty_lwt, rspi_resp_code_is_xlate_pending,                                                          // -- rty_hwt, rty_req_ rty_lwt, pending -> Rtry 
                                    rspi_resp_code_is_derror,  rspi_resp_code_is_bad_length, rspi_resp_code_is_bad_addr, rspi_resp_code_is_failed,  rspi_resp_code_is_adr_error };  // -- derror,fault,failed,aerror         -> Done

  always @*
    begin
      casez ( rspi_resp_st_sel[13:0] )
        // --                                    
        // --  Inputs                                                                      
        // --  -------------------
        // --  rspi_eng_resp_valid                                          
        // --  |                                                     Outputs              
        // --  | rspi_resp_is_write_response                         ---------------------         
        // --  | |rspi_resp_is_write_failed                          rspi_resp_is_st_good               
        // --  | ||rspi_resp_is_xlate_done                           |rspi_resp_is_st_rtry_hwt      
        // --  | |||any_st_resp_expected                             ||rspi_resp_is_st_rtry_req       
        // --  | ||||                                                |||rspi_resp_is_st_rtry_lwt  
        // --  | |||| rspi_resp_code_is_done                         ||||rspi_resp_is_st_pending
        // --  | |||| |rspi_resp_code_is_rty_req                     |||||rspi_resp_is_st_derror
        // --  | |||| ||rspi_resp_code_is_rty_lwt                    ||||||rspi_resp_is_st_fault   
        // --  | |||| |||rspi_resp_code_is_xlate_pending             |||||||rspi_resp_is_st_failed  
        // --  | |||| ||||rspi_resp_code_is_derror                   ||||||||rspi_resp_is_st_aerror 
        // --  | |||| |||||rspi_resp_code_is_bad_length              |||||||||   
        // --  | |||| ||||||rspi_resp_code_is_bad_addr               ||||||||| rspi_resp_is_st_pending_done             
        // --  | |||| |||||||rspi_resp_code_is_failed                ||||||||| |rspi_resp_is_st_rtry   
        // --  | |||| ||||||||rspi_resp_code_is_adr_error            ||||||||| ||rspi_resp_is_st_done  
        // --  1 11|| |||||||||                                      11|||||||| |||                      
        // --  3 2109 876543210                                      109876543 210
        // -----------------------------------------------------------------------
           14'b1_1??1_?????????  :  rspi_resp_st_decode[11:0] =  12'b100000000_001 ;  // -- read_response                - done
        // -----------------------------------------------------------------------
           14'b1_01?1_?1???????  :  rspi_resp_st_decode[11:0] =  12'b001000000_010 ;  // -- write_failed - rty_req       - retry
           14'b1_01?1_?01??????  :  rspi_resp_st_decode[11:0] =  12'b000100000_010 ;  // -- write_failed - rty_lwt       - retry
           14'b1_01?1_?001?????  :  rspi_resp_st_decode[11:0] =  12'b000010000_010 ;  // -- write_failed - xlate_pending - retry
           14'b1_01?1_?0001????  :  rspi_resp_st_decode[11:0] =  12'b000001000_001 ;  // -- write_failed - derror        - done - set derror latch
           14'b1_01?1_?00001???  :  rspi_resp_st_decode[11:0] =  12'b000000100_001 ;  // -- write_failed - bad_length    - done - set fault  latch 
           14'b1_01?1_?000001??  :  rspi_resp_st_decode[11:0] =  12'b000000100_001 ;  // -- write_failed - bad_addr      - done - set fault  latch
           14'b1_01?1_?0000001?  :  rspi_resp_st_decode[11:0] =  12'b000000010_001 ;  // -- write_failed - failed        - done - set failed latch
        // -----------------------------------------------------------------------
           14'b1_0011_1????????  :  rspi_resp_st_decode[11:0] =  12'b000000000_100 ;  // -- xlate_done - done            - release xlate_pending retry from retry queue
           14'b1_0011_01???????  :  rspi_resp_st_decode[11:0] =  12'b001000000_100 ;  // -- xlate_done - rty_req         - release xlate_pending retry from retry queue
           14'b1_0011_00??????1  :  rspi_resp_st_decode[11:0] =  12'b000000001_101 ;  // -- xlate_done - adr_error       - done - set aerror latch - abort from retry queue
        // -----------------------------------------------------------------------
           default               :  rspi_resp_st_decode[11:0] =  12'b000000000_000 ;  // 
        // -----------------------------------------------------------------------
      endcase
    end // -- always @ *

  assign  rspi_resp_is_st_good                =  rspi_resp_st_decode[11] && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_rtry_hwt            =  rspi_resp_st_decode[10] && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_rtry_req            =  rspi_resp_st_decode[9]  && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_rtry_lwt            =  rspi_resp_st_decode[8]  && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_pending             =  rspi_resp_st_decode[7]  && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_derror              =  rspi_resp_st_decode[6]  && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_fault               =  rspi_resp_st_decode[5]  && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_failed              =  rspi_resp_st_decode[4]  && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_aerror              =  rspi_resp_st_decode[3]  && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_pending_done        =  rspi_resp_st_decode[2]  && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_rtry                =  rspi_resp_st_decode[1]  && rspi_resp_afutag_is_st;
  assign  rspi_resp_is_st_done                =  rspi_resp_st_decode[0]  && rspi_resp_afutag_is_st;
                                             
  assign  rspi_resp_is_we_st_good             =  rspi_resp_st_decode[11] && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_rtry_hwt         =  rspi_resp_st_decode[10] && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_rtry_req         =  rspi_resp_st_decode[9]  && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_rtry_lwt         =  rspi_resp_st_decode[8]  && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_pending          =  rspi_resp_st_decode[7]  && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_derror           =  rspi_resp_st_decode[6]  && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_fault            =  rspi_resp_st_decode[5]  && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_failed           =  rspi_resp_st_decode[4]  && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_aerror           =  rspi_resp_st_decode[3]  && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_pending_done     =  rspi_resp_st_decode[2]  && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_rtry             =  rspi_resp_st_decode[1]  && rspi_resp_afutag_is_we_st;
  assign  rspi_resp_is_we_st_done             =  rspi_resp_st_decode[0]  && rspi_resp_afutag_is_we_st;
                                             
  assign  rspi_resp_is_cpy_st_good            =  rspi_resp_st_decode[11] && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_rtry_hwt        =  rspi_resp_st_decode[10] && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_rtry_req        =  rspi_resp_st_decode[9]  && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_rtry_lwt        =  rspi_resp_st_decode[8]  && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_pending         =  rspi_resp_st_decode[7]  && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_derror          =  rspi_resp_st_decode[6]  && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_fault           =  rspi_resp_st_decode[5]  && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_failed          =  rspi_resp_st_decode[4]  && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_aerror          =  rspi_resp_st_decode[3]  && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_pending_done    =  rspi_resp_st_decode[2]  && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_rtry            =  rspi_resp_st_decode[1]  && rspi_resp_afutag_is_cpy_st;
  assign  rspi_resp_is_cpy_st_done            =  rspi_resp_st_decode[0]  && rspi_resp_afutag_is_cpy_st;
                                             
  assign  rspi_resp_is_incr_st_good           =  rspi_resp_st_decode[11] && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_rtry_hwt       =  rspi_resp_st_decode[10] && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_rtry_req       =  rspi_resp_st_decode[9]  && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_rtry_lwt       =  rspi_resp_st_decode[8]  && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_pending        =  rspi_resp_st_decode[7]  && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_derror         =  rspi_resp_st_decode[6]  && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_fault          =  rspi_resp_st_decode[5]  && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_failed         =  rspi_resp_st_decode[4]  && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_aerror         =  rspi_resp_st_decode[3]  && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_pending_done   =  rspi_resp_st_decode[2]  && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_rtry           =  rspi_resp_st_decode[1]  && rspi_resp_afutag_is_incr_st;
  assign  rspi_resp_is_incr_st_done           =  rspi_resp_st_decode[0]  && rspi_resp_afutag_is_incr_st;
                                             
  assign  rspi_resp_is_atomic_st_good         =  rspi_resp_st_decode[11] && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_rtry_hwt     =  rspi_resp_st_decode[10] && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_rtry_req     =  rspi_resp_st_decode[9]  && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_rtry_lwt     =  rspi_resp_st_decode[8]  && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_pending      =  rspi_resp_st_decode[7]  && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_derror       =  rspi_resp_st_decode[6]  && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_fault        =  rspi_resp_st_decode[5]  && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_failed       =  rspi_resp_st_decode[4]  && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_aerror       =  rspi_resp_st_decode[3]  && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_pending_done =  rspi_resp_st_decode[2]  && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_rtry         =  rspi_resp_st_decode[1]  && rspi_resp_afutag_is_atomic_st;
  assign  rspi_resp_is_atomic_st_done         =  rspi_resp_st_decode[0]  && rspi_resp_afutag_is_atomic_st;


  // -- ********************************************************************************************************************************
  // -- wkhstthrd decode 
  // -- ********************************************************************************************************************************

  assign  wkhstthrd_resp_expected                  =  wkhstthrd_wt4rsp_st;
  assign  rcvd_wake_host_resp_when_not_expected    =  ( rspi_eng_resp_valid &&  rspi_resp_is_wake_host_resp && ~wkhstthrd_resp_expected );
  assign  rcvd_wake_host_resp_w_bad_afutag         =  ( rspi_eng_resp_valid &&  rspi_resp_is_wake_host_resp && ~rspi_resp_afutag_is_wkhstthrd );
  assign  rcvd_unexpected_resp_w_wkhstthrd_afutag  =  ( rspi_eng_resp_valid && ~rspi_resp_is_wake_host_resp && ~rspi_resp_is_xlate_done && rspi_resp_afutag_is_wkhstthrd );

  assign  rspi_resp_wkhstthrd_sel[11:0] = { rspi_eng_resp_valid, rspi_resp_is_wake_host_resp, rspi_resp_is_xlate_done,                                                  // -- Response Decode
                                            wkhstthrd_resp_expected,                                                                                                    // -- Qualify with sequencer active
                                            rspi_resp_code_is_done,                                                                                                     // -- done                               -> Done
                                            rspi_resp_code_is_rty_req, rspi_resp_code_is_rty_lwt, rspi_resp_code_is_xlate_pending,                                      // -- rty_hwt, rty_req_ rty_lwt, pending -> Rtry 
                                            rspi_resp_code_is_thread_not_found, rspi_resp_code_is_bad_handle, rspi_resp_code_is_failed, rspi_resp_code_is_adr_error };  // -- derror,fault,failed,aerror         -> Done

  always @*
    begin
      casez ( rspi_resp_wkhstthrd_sel[11:0] )
        // --                                    
        // --  Inputs                                        
        // --  -------------------                                        Outputs                          
        // --  rspi_eng_resp_valid                                        ---------------------            
        // --  |                                                          rspi_resp_is_wkhstthrd_good          
        // --  | rspi_resp_is_wake_host_resp                              |rspi_resp_is_wkhstthrd_rtry_hwt       
        // --  | |rspi_resp_is_xlate_done                                 ||rspi_resp_is_wkhstthrd_rtry_req      
        // --  | ||wkhstthrd_resp_expected                                |||rspi_resp_is_wkhstthrd_rtry_lwt  
        // --  | |||                                                      ||||rspi_resp_is_wkhstthrd_pending
        // --  | ||| rspi_resp_code_is_done                               |||||rspi_resp_is_wkhstthrd_derror
        // --  | ||| |rspi_resp_code_is_rty_req                           ||||||rspi_resp_is_wkhstthrd_fault   
        // --  | ||| ||rspi_resp_code_is_rty_lwt                          |||||||rspi_resp_is_wkhstthrd_failed 
        // --  | ||| |||rspi_resp_code_is_xlate_pending                   ||||||||rspi_resp_is_wkhstthrd_aerror  
        // --  | ||| ||||rspi_resp_code_is_thread_not_found               |||||||||   
        // --  | ||| |||||rspi_resp_code_is_bad_handle                    ||||||||| rspi_resp_is_wkhstthrd_pending_done                       
        // --  | ||| ||||||rspi_resp_code_is_failed                       ||||||||| |rspi_resp_is_wkhstthrd_rtry   
        // --  | ||| |||||||rspi_resp_code_is_failed                      ||||||||| ||rspi_resp_is_wkhstthrd_done  
        // --  1 1|| ||||||||                                             11||||||| |||                     
        // --  1 098 76543210                                             109876543 210
        // ----------------------------------------------------------------------------
           12'b1_1?1_1???????  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b100000000_001 ;  // -- wake_host_resp - done              - done
           12'b1_1?1_01??????  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b001000000_010 ;  // -- wake_host_resp - rty_req           - retry
           12'b1_1?1_001?????  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b000100000_010 ;  // -- wake_host_resp - rty_lwt           - retry
           12'b1_1?1_0001????  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b000010000_010 ;  // -- wake_host_resp - xlate_pending     - retry 
           12'b1_1?1_00001???  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b000000100_001 ;  // -- wake_host_resp - thread_not_found  - done - set fault  latch 
           12'b1_1?1_000001??  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b000000100_001 ;  // -- wake_host_resp - bad_handle        - done - set fault  latch
           12'b1_1?1_0000001?  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b000000010_001 ;  // -- wake_host_resp - failed            - done - set failed latch
        // ----------------------------------------------------------------------------
           12'b1_011_1???????  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b000000000_100 ;  // -- xlate_done - done                  - release xlate_pending retry from retry queue
           12'b1_011_01??????  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b001000000_100 ;  // -- xlate_done - rty_req               - release xlate_pending retry from retry queue
           12'b1_011_00?????1  :  rspi_resp_wkhstthrd_decode[11:0] =  12'b000000001_101 ;  // -- xlate_done - adr_error             - done - set aerror latch - abort from retry queue
        // ----------------------------------------------------------------------------
           default             :  rspi_resp_wkhstthrd_decode[11:0] =  12'b000000000_000 ;  // 
        // ----------------------------------------------------------------------------
      endcase
    end // -- always @ *

  assign  rspi_resp_is_wkhstthrd_good         =  rspi_resp_wkhstthrd_decode[11] && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_rtry_hwt     =  rspi_resp_wkhstthrd_decode[10] && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_rtry_req     =  rspi_resp_wkhstthrd_decode[9]  && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_rtry_lwt     =  rspi_resp_wkhstthrd_decode[8]  && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_pending      =  rspi_resp_wkhstthrd_decode[7]  && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_derror       =  rspi_resp_wkhstthrd_decode[6]  && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_fault        =  rspi_resp_wkhstthrd_decode[5]  && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_failed       =  rspi_resp_wkhstthrd_decode[4]  && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_aerror       =  rspi_resp_wkhstthrd_decode[3]  && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_pending_done =  rspi_resp_wkhstthrd_decode[2]  && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_rtry         =  rspi_resp_wkhstthrd_decode[1]  && rspi_resp_afutag_is_wkhstthrd;
  assign  rspi_resp_is_wkhstthrd_done         =  rspi_resp_wkhstthrd_decode[0]  && rspi_resp_afutag_is_wkhstthrd;


  // -- ********************************************************************************************************************************
  // -- intrpt decode 
  // -- ********************************************************************************************************************************

  assign  intrpt_resp_expected                  =  intrpt_wt4rsp_st;
  assign  rcvd_intrp_resp_when_not_expected     =  ( rspi_eng_resp_valid &&  rspi_resp_is_intrp_resp && ~intrpt_resp_expected );
  assign  rcvd_intrp_resp_w_bad_afutag          =  ( rspi_eng_resp_valid &&  rspi_resp_is_intrp_resp && ~rspi_resp_afutag_is_intrpt );
  assign  rcvd_unexpected_resp_w_intrpt_afutag  =  ( rspi_eng_resp_valid && ~rspi_resp_is_intrp_resp && ~rspi_resp_is_intrp_rdy && rspi_resp_afutag_is_intrpt );

  assign  rspi_resp_intrpt_sel[10:0] = { rspi_eng_resp_valid, rspi_resp_is_intrp_resp, rspi_resp_is_intrp_rdy,                                              // -- Response Decode
                                         intrpt_resp_expected,                                                                                              // -- Qualify with sequencer active
                                         rspi_resp_code_is_done,                                                                                            // -- done                               -> Done
                                         rspi_resp_code_is_rty_req,  rspi_resp_code_is_intrp_pending,                                                       // -- rty_hwt, rty_req_ rty_lwt, pending -> Rtry 
                                         rspi_resp_code_is_derror, rspi_resp_code_is_bad_length, rspi_resp_code_is_bad_handle, rspi_resp_code_is_failed };  // -- derror,fault,failed,aerror         -> Done

  always @*
    begin
      casez ( rspi_resp_intrpt_sel[10:0] )
        // --                                    
        // --  Inputs                                                 Outputs                             
        // --  -------------------                                    ---------------------                                                                         
        // --  rspi_eng_resp_valid                                    rspi_resp_is_intrpt_good           
        // --  |                                                      |rspi_resp_is_intrpt_rtry_hwt      
        // --  | rspi_resp_is_intrp_resp                              ||rspi_resp_is_intrpt_rtry_req   
        // --  | |rspi_resp_is_intrp_rdy                              |||rspi_resp_is_intrpt_rtry_lwt  
        // --  | ||intrpt_resp_expected                               ||||rspi_resp_is_intrpt_pending
        // --  | |||                                                  |||||rspi_resp_is_intrpt_derror
        // --  | ||| rspi_resp_code_is_done                           ||||||rspi_resp_is_intrpt_fault    
        // --  | ||| |rspi_resp_code_is_rty_req                       |||||||rspi_resp_is_intrpt_failed  
        // --  | ||| ||rspi_resp_code_is_intrp_pending                ||||||||rspi_resp_is_intrpt_aerror 
        // --  | ||| |||rspi_resp_code_is_derror                      ||||||||| 
        // --  | ||| ||||rspi_resp_code_is_bad_length                 ||||||||| rspi_resp_is_intrpt_pending_done                       
        // --  | ||| |||||rspi_resp_code_is_bad_handle                ||||||||| |rspi_resp_is_intrpt_rtry 
        // --  | ||| ||||||rspi_resp_code_is_failed                   ||||||||| ||rspi_resp_is_intrpt_done
        // --  1 ||| |||||||                                          11||||||| |||                     
        // --  0 987 6543210                                          109876543 210
        // ------------------------------------------------------------------------
           11'b1_1?1_1??????  :  rspi_resp_intrpt_decode[11:0] =  12'b100000000_001 ;  // -- intrp_resp - done           - done
           11'b1_1?1_01?????  :  rspi_resp_intrpt_decode[11:0] =  12'b001000000_010 ;  // -- intrp_resp - rty_req        - retry
           11'b1_1?1_001????  :  rspi_resp_intrpt_decode[11:0] =  12'b000010000_010 ;  // -- intrp_resp - intrp_pending  - retry
           11'b1_1?1_0001???  :  rspi_resp_intrpt_decode[11:0] =  12'b000001000_001 ;  // -- intrp_resp - derror         - done - set derror latch
           11'b1_1?1_00001??  :  rspi_resp_intrpt_decode[11:0] =  12'b000000100_001 ;  // -- intrp_resp - bad_length     - done - set fault  latch 
           11'b1_1?1_000001?  :  rspi_resp_intrpt_decode[11:0] =  12'b000000100_001 ;  // -- intrp_resp - bad_handle     - done - set fault  latch
           11'b1_1?1_0000001  :  rspi_resp_intrpt_decode[11:0] =  12'b000000010_001 ;  // -- intrp_resp - failed         - done - set failed latch
        // ------------------------------------------------------------------------                                      
           11'b1_011_1??????  :  rspi_resp_intrpt_decode[11:0] =  12'b000000000_100 ;  // -- intrp_rdy - done            - release intrp_pending retry from retry queue
           11'b1_011_01?????  :  rspi_resp_intrpt_decode[11:0] =  12'b001000000_100 ;  // -- intrp_rdy - rty_req         - release intrp_pending retry from retry queue
           11'b1_011_00????1  :  rspi_resp_intrpt_decode[11:0] =  12'b000000010_101 ;  // -- intrp_rdy - failed          - done - set failed latch - abort from retry queue
        // ------------------------------------------------------------------------
           default            :  rspi_resp_intrpt_decode[11:0] =  12'b000000000_000 ;  // 
        // ------------------------------------------------------------------------
      endcase
    end // -- always @ *

  assign  rspi_resp_is_intrpt_good             =  rspi_resp_intrpt_decode[11] && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_rtry_hwt         =  rspi_resp_intrpt_decode[10] && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_rtry_req         =  rspi_resp_intrpt_decode[9]  && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_rtry_lwt         =  rspi_resp_intrpt_decode[8]  && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_pending          =  rspi_resp_intrpt_decode[7]  && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_derror           =  rspi_resp_intrpt_decode[6]  && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_fault            =  rspi_resp_intrpt_decode[5]  && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_failed           =  rspi_resp_intrpt_decode[4]  && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_aerror           =  rspi_resp_intrpt_decode[3]  && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_pending_done     =  rspi_resp_intrpt_decode[2]  && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_rtry             =  rspi_resp_intrpt_decode[1]  && rspi_resp_afutag_is_intrpt;
  assign  rspi_resp_is_intrpt_done             =  rspi_resp_intrpt_decode[0]  && rspi_resp_afutag_is_intrpt;

  assign  rspi_resp_is_intrpt_cmd_good         =  rspi_resp_intrpt_decode[11] && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_rtry_hwt     =  rspi_resp_intrpt_decode[10] && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_rtry_req     =  rspi_resp_intrpt_decode[9]  && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_rtry_lwt     =  rspi_resp_intrpt_decode[8]  && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_pending      =  rspi_resp_intrpt_decode[7]  && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_derror       =  rspi_resp_intrpt_decode[6]  && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_fault        =  rspi_resp_intrpt_decode[5]  && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_failed       =  rspi_resp_intrpt_decode[4]  && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_aerror       =  rspi_resp_intrpt_decode[3]  && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_pending_done =  rspi_resp_intrpt_decode[2]  && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_rtry         =  rspi_resp_intrpt_decode[1]  && rspi_resp_afutag_is_intrpt_cmd;
  assign  rspi_resp_is_intrpt_cmd_done         =  rspi_resp_intrpt_decode[0]  && rspi_resp_afutag_is_intrpt_cmd;

  assign  rspi_resp_is_intrpt_err_good         =  rspi_resp_intrpt_decode[11] && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_rtry_hwt     =  rspi_resp_intrpt_decode[10] && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_rtry_req     =  rspi_resp_intrpt_decode[9]  && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_rtry_lwt     =  rspi_resp_intrpt_decode[8]  && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_pending      =  rspi_resp_intrpt_decode[7]  && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_derror       =  rspi_resp_intrpt_decode[6]  && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_fault        =  rspi_resp_intrpt_decode[5]  && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_failed       =  rspi_resp_intrpt_decode[4]  && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_aerror       =  rspi_resp_intrpt_decode[3]  && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_pending_done =  rspi_resp_intrpt_decode[2]  && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_rtry         =  rspi_resp_intrpt_decode[1]  && rspi_resp_afutag_is_intrpt_err;
  assign  rspi_resp_is_intrpt_err_done         =  rspi_resp_intrpt_decode[0]  && rspi_resp_afutag_is_intrpt_err;

  assign  rspi_resp_is_intrpt_wht_good         =  rspi_resp_intrpt_decode[11] && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_rtry_hwt     =  rspi_resp_intrpt_decode[10] && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_rtry_req     =  rspi_resp_intrpt_decode[9]  && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_rtry_lwt     =  rspi_resp_intrpt_decode[8]  && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_pending      =  rspi_resp_intrpt_decode[7]  && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_derror       =  rspi_resp_intrpt_decode[6]  && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_fault        =  rspi_resp_intrpt_decode[5]  && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_failed       =  rspi_resp_intrpt_decode[4]  && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_aerror       =  rspi_resp_intrpt_decode[3]  && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_pending_done =  rspi_resp_intrpt_decode[2]  && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_rtry         =  rspi_resp_intrpt_decode[1]  && rspi_resp_afutag_is_intrpt_wht;
  assign  rspi_resp_is_intrpt_wht_done         =  rspi_resp_intrpt_decode[0]  && rspi_resp_afutag_is_intrpt_wht;


  // -- ********************************************************************************************************************************
  // -- Group cpy ld,st
  // -- ********************************************************************************************************************************

  assign  rspi_resp_is_cpy_good         =  ( rspi_resp_st_decode[11] || rspi_resp_ld_decode[10] ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_rtry_hwt     =  ( rspi_resp_st_decode[10] || rspi_resp_ld_decode[9]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_rtry_req     =  ( rspi_resp_st_decode[9]  || rspi_resp_ld_decode[8]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_rtry_lwt     =  ( rspi_resp_st_decode[8]  || rspi_resp_ld_decode[7]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_pending      =  ( rspi_resp_st_decode[7]  || rspi_resp_ld_decode[6]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_derror       =  ( rspi_resp_st_decode[6]  || rspi_resp_ld_decode[5]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_fault        =  ( rspi_resp_st_decode[5]  || rspi_resp_ld_decode[4]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_failed       =  ( rspi_resp_st_decode[4]  || rspi_resp_ld_decode[3]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_aerror       =  ( rspi_resp_st_decode[3]  || rspi_resp_ld_decode[2]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_pending_done =  ( rspi_resp_st_decode[2]  || rspi_resp_ld_decode[1]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_rtry         =  ( rspi_resp_st_decode[1]  || rspi_resp_ld_decode[1]  ) && rspi_resp_afutag_is_cpy;
  assign  rspi_resp_is_cpy_done         =  ( rspi_resp_st_decode[0]  || rspi_resp_ld_decode[0]  ) && rspi_resp_afutag_is_cpy;


  // -- ********************************************************************************************************************************
  // -- Group incr ld,st
  // -- ********************************************************************************************************************************

  assign  rspi_resp_is_incr_good         =  ( rspi_resp_st_decode[10] || rspi_resp_ld_decode[11] ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_rtry_hwt     =  ( rspi_resp_st_decode[9]  || rspi_resp_ld_decode[10] ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_rtry_req     =  ( rspi_resp_st_decode[8]  || rspi_resp_ld_decode[9]  ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_rtry_lwt     =  ( rspi_resp_st_decode[7]  || rspi_resp_ld_decode[8]  ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_pending      =  ( rspi_resp_st_decode[6]  || rspi_resp_ld_decode[7]  ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_derror       =  ( rspi_resp_st_decode[5]  || rspi_resp_ld_decode[6]  ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_fault        =  ( rspi_resp_st_decode[4]  || rspi_resp_ld_decode[5]  ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_failed       =  ( rspi_resp_st_decode[3]  || rspi_resp_ld_decode[4]  ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_aerror       =  ( rspi_resp_st_decode[2]  || rspi_resp_ld_decode[3]  ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_pending_done =  ( rspi_resp_st_decode[1]  || rspi_resp_ld_decode[2]  ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_rtry         =  ( rspi_resp_st_decode[1]  || rspi_resp_ld_decode[1]  ) && rspi_resp_afutag_is_incr;
  assign  rspi_resp_is_incr_done         =  ( rspi_resp_st_decode[0]  || rspi_resp_ld_decode[0]  ) && rspi_resp_afutag_is_incr;


  // -- ********************************************************************************************************************************
  // -- Group atomic ld, st, cas
  // -- ********************************************************************************************************************************

  assign  rspi_resp_is_atomic_good         =  ( rspi_resp_st_decode[11] || rspi_resp_ld_decode[11] ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_rtry_hwt     =  ( rspi_resp_st_decode[10] || rspi_resp_ld_decode[10] ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_rtry_req     =  ( rspi_resp_st_decode[9]  || rspi_resp_ld_decode[9]  ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_rtry_lwt     =  ( rspi_resp_st_decode[8]  || rspi_resp_ld_decode[8]  ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_pending      =  ( rspi_resp_st_decode[7]  || rspi_resp_ld_decode[7]  ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_derror       =  ( rspi_resp_st_decode[6]  || rspi_resp_ld_decode[6]  ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_fault        =  ( rspi_resp_st_decode[5]  || rspi_resp_ld_decode[5]  ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_failed       =  ( rspi_resp_st_decode[4]  || rspi_resp_ld_decode[4]  ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_aerror       =  ( rspi_resp_st_decode[3]  || rspi_resp_ld_decode[3]  ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_pending_done =  ( rspi_resp_st_decode[2]  || rspi_resp_ld_decode[2]  ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_rtry         =  ( rspi_resp_st_decode[1]  || rspi_resp_ld_decode[1]  ) && rspi_resp_afutag_is_atomic;
  assign  rspi_resp_is_atomic_done         =  ( rspi_resp_st_decode[0]  || rspi_resp_ld_decode[0]  ) && rspi_resp_afutag_is_atomic;


  // -- ********************************************************************************************************************************
  // -- combine the terms that have been qualified with sequencer state and afutag
  // -- ********************************************************************************************************************************

  assign  rspi_resp_is_good_int         =  rspi_resp_xtouch_decode[11] || rspi_resp_ld_decode[11] || rspi_resp_st_decode[11] || rspi_resp_wkhstthrd_decode[11] || rspi_resp_intrpt_decode[11];
  assign  rspi_resp_is_rtry_hwt_int     =  rspi_resp_xtouch_decode[10] || rspi_resp_ld_decode[10] || rspi_resp_st_decode[10] || rspi_resp_wkhstthrd_decode[10] || rspi_resp_intrpt_decode[10];
  assign  rspi_resp_is_rtry_req_int     =  rspi_resp_xtouch_decode[9]  || rspi_resp_ld_decode[9]  || rspi_resp_st_decode[9]  || rspi_resp_wkhstthrd_decode[9]  || rspi_resp_intrpt_decode[9]; 
  assign  rspi_resp_is_rtry_lwt_int     =  rspi_resp_xtouch_decode[8]  || rspi_resp_ld_decode[8]  || rspi_resp_st_decode[8]  || rspi_resp_wkhstthrd_decode[8]  || rspi_resp_intrpt_decode[8]; 
  assign  rspi_resp_is_pending_int      =  rspi_resp_xtouch_decode[7]  || rspi_resp_ld_decode[7]  || rspi_resp_st_decode[7]  || rspi_resp_wkhstthrd_decode[7]  || rspi_resp_intrpt_decode[7]; 
  assign  rspi_resp_is_derror_int       =  rspi_resp_xtouch_decode[6]  || rspi_resp_ld_decode[6]  || rspi_resp_st_decode[6]  || rspi_resp_wkhstthrd_decode[6]  || rspi_resp_intrpt_decode[6]; 
  assign  rspi_resp_is_fault_int        =  rspi_resp_xtouch_decode[5]  || rspi_resp_ld_decode[5]  || rspi_resp_st_decode[5]  || rspi_resp_wkhstthrd_decode[5]  || rspi_resp_intrpt_decode[5]; 
  assign  rspi_resp_is_failed_int       =  rspi_resp_xtouch_decode[4]  || rspi_resp_ld_decode[4]  || rspi_resp_st_decode[4]  || rspi_resp_wkhstthrd_decode[4]  || rspi_resp_intrpt_decode[4]; 
  assign  rspi_resp_is_aerror_int       =  rspi_resp_xtouch_decode[3]  || rspi_resp_ld_decode[3]  || rspi_resp_st_decode[3]  || rspi_resp_wkhstthrd_decode[3]  || rspi_resp_intrpt_decode[3]; 
  assign  rspi_resp_is_pending_done_int =  rspi_resp_xtouch_decode[2]  || rspi_resp_ld_decode[2]  || rspi_resp_st_decode[2]  || rspi_resp_wkhstthrd_decode[2]  || rspi_resp_intrpt_decode[2]; 
  assign  rspi_resp_is_rtry_int         =  rspi_resp_xtouch_decode[1]  || rspi_resp_ld_decode[1]  || rspi_resp_st_decode[1]  || rspi_resp_wkhstthrd_decode[1]  || rspi_resp_intrpt_decode[1]; 
  assign  rspi_resp_is_done_int         =  rspi_resp_xtouch_decode[0]  || rspi_resp_ld_decode[0]  || rspi_resp_st_decode[0]  || rspi_resp_wkhstthrd_decode[0]  || rspi_resp_intrpt_decode[0]; 

  // -- Send to retry  queue to form rtry_valid
  assign  rspi_resp_is_rtry =  rspi_resp_is_rtry_int;


  // -- ********************************************************************************************************************************
  // -- Check for xlate_done or intrpt_done when there isn't one pending
  // -- ********************************************************************************************************************************

  assign  unexpected_xlate_or_intrpt_done_200_d =  ( rspi_eng_resp_valid && ( rspi_resp_is_xlate_done || rspi_resp_is_intrpt_done ) && ( pending_cnt_int_d[4:0] == 5'b0 ));

  assign  unexpected_xlate_or_intrpt_done_200 =  unexpected_xlate_or_intrpt_done_200_q;

  assign  rspi_resp_is_xlate_pending_d =  ( rspi_eng_resp_valid && ( rspi_resp_is_write_failed || rspi_resp_is_read_failed ) &&  rspi_resp_code_is_xlate_pending );
  assign  rspi_resp_is_intrp_pending_d =  ( rspi_eng_resp_valid && rspi_resp_is_intrp_resp && rspi_resp_code_is_intrp_pending );

  assign  back_to_back_xlate_pending_and_done_d = ( rspi_resp_is_xlate_pending_q && ( rspi_eng_resp_valid && rspi_resp_is_xlate_done ));
  assign  back_to_back_intrp_pending_and_rdy_d =  ( rspi_resp_is_intrp_pending_q && ( rspi_eng_resp_valid && rspi_resp_is_intrp_rdy  ));


  // -- ********************************************************************************************************************************
  // -- Check for illegal/unexpected Response AFUTAGs
  // -- ********************************************************************************************************************************

  assign  undefined_rspi_we_ld_afutag     =  rspi_eng_resp_valid && rspi_resp_afutag_is_we_ld     && (( rspi_eng_resp_afutag[15:14] != 2'b01 ) || // -- should always be 01 for 64B load
                                                                                                      ( rspi_eng_resp_afutag[13:12] != 2'b00 ));

  assign  undefined_rspi_xtouch_afutag    =  rspi_eng_resp_valid && rspi_resp_afutag_is_xtouch    && (( rspi_eng_resp_afutag[15:14] != 2'b00 ) ||
                                                                                                      ( rspi_eng_resp_afutag[13:12] != 2'b00 ));

  assign  undefined_rspi_cpy_afutag       =  rspi_eng_resp_valid && rspi_resp_afutag_is_cpy       && (( rspi_eng_resp_afutag[15:14] == 2'b00 ) || // -- 15:14 = b'01, b'10, b'11 for 64B, 128B, 256B ops
                                                                                                      ( rspi_eng_resp_afutag[13:12] != 2'b00 ));   

  assign  undefined_rspi_wkhstthrd_afutag =  rspi_eng_resp_valid && rspi_resp_afutag_is_wkhstthrd && (( rspi_eng_resp_afutag[15:14] != 2'b00 ) ||
                                                                                                      ( rspi_eng_resp_afutag[13:12] != 2'b00 ));

  assign  undefined_rspi_incr_ld_afutag   =  rspi_eng_resp_valid && rspi_resp_afutag_is_incr_ld   && (( rspi_eng_resp_afutag[15:14] != 2'b01 ) ||
                                                                                                      ( rspi_eng_resp_afutag[13:12] != 2'b00 ));     

  assign  undefined_rspi_incr_st_afutag   =  rspi_eng_resp_valid && rspi_resp_afutag_is_incr_st   && (( rspi_eng_resp_afutag[15:14] != 2'b00 ) ||
                                                                                                      ( rspi_eng_resp_afutag[13]    != 1'b1  ));  // -- 13:12 = b'10 or b'11 for 4B vs 8B    

  assign  undefined_rspi_incr_afutag      =  undefined_rspi_incr_ld_afutag || undefined_rspi_incr_st_afutag;

  assign  undefined_rspi_atomic_afutag    =  rspi_eng_resp_valid && rspi_resp_afutag_is_atomic    && (( rspi_eng_resp_afutag[15:14] != 2'b00 ) ||
                                                                                                      ( rspi_eng_resp_afutag[13]    != 1'b1  ));  // -- 13:12 = b'10 or b'11 for 4B vs 8B    

  assign  undefined_rspi_intrpt_afutag    =  rspi_eng_resp_valid && rspi_resp_afutag_is_intrpt    && (( rspi_eng_resp_afutag[15:14] != 2'b00 ) ||
                                                                                                      ( rspi_eng_resp_afutag[13]    != 1'b0  ));  // -- 13:12 = b'00 or b'01 for no data vs w/ data    

  // -- ********************************************************************************************************************************
  // -- Check for illegal outbound AFUTAGs
  // -- ********************************************************************************************************************************

  // -- Outbound AFUTAG decodes
  assign  cmdo_afutag_is_we_ld          =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] ==  WE_LD_AFUTAG_ENCODE[4:0]        ));
  assign  cmdo_afutag_is_xtouch_source  =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == XTOUCH_SOURCE_AFUTAG_ENCODE[4:0] ));
  assign  cmdo_afutag_is_xtouch_dest    =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == XTOUCH_DEST_AFUTAG_ENCODE[4:0]   ));
  assign  cmdo_afutag_is_cpy_ld         =  (~cmdo_afutag[11] &&  ~cmdo_afutag[13]                                       );
  assign  cmdo_afutag_is_cpy_st         =  (~cmdo_afutag[11] &&   cmdo_afutag[13]                                       );
  assign  cmdo_afutag_is_wkhstthrd      =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == WKHSTTHRD_AFUTAG_ENCODE [4:0]    ));
  assign  cmdo_afutag_is_intrpt_wht     =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == INTRPT_WHT_AFUTAG_ENCODE[4:0]    ));  // -- AFUTAG[12] = b'1 if "intrpt_w_data"
  assign  cmdo_afutag_is_incr_ld        =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == INCR_LD_AFUTAG_ENCODE[4:0]       ));
  assign  cmdo_afutag_is_incr_st        =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == INCR_ST_AFUTAG_ENCODE[4:0]       ));
  assign  cmdo_afutag_is_atomic_ld      =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == ATOMIC_LD_AFUTAG_ENCODE[4:0]     ));
  assign  cmdo_afutag_is_atomic_st      =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == ATOMIC_ST_AFUTAG_ENCODE[4:0]     ));
  assign  cmdo_afutag_is_atomic_cas     =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == ATOMIC_CAS_AFUTAG_ENCODE[4:0]    ));
  assign  cmdo_afutag_is_intrpt_err     =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == INTRPT_ERR_AFUTAG_ENCODE[4:0]    ));  // -- AFUTAG[12] = b'1 if "intrpt_w_data"
  assign  cmdo_afutag_is_intrpt_cmd     =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == INTRPT_CMD_AFUTAG_ENCODE[4:0]    ));  // -- AFUTAG[12] = b'1 if "intrpt_w_data"
  assign  cmdo_afutag_is_we_st          =  ( cmdo_afutag[11] && ( cmdo_afutag[4:0] == WE_ST_AFUTAG_ENCODE[4:0]         ));

  // -- Group Outbound AFUTAG decodes for sequencers that can issue more than one type of command
  assign  cmdo_afutag_is_cpy            =  ( cmdo_afutag_is_cpy_ld        || cmdo_afutag_is_cpy_st );                                   // -- cpy_ld or cpy_st
  assign  cmdo_afutag_is_xtouch         =  ( cmdo_afutag_is_xtouch_source || cmdo_afutag_is_xtouch_dest );                              // -- xtouch seq issues two commands - both can be outstanding
  assign  cmdo_afutag_is_incr           =  ( cmdo_afutag_is_incr_ld       || cmdo_afutag_is_incr_st );                                  // -- incr   seq issues two commands - serially. (ld must complete before st can be issued)
  assign  cmdo_afutag_is_atomic         =  ( cmdo_afutag_is_atomic_ld     || cmdo_afutag_is_atomic_st  || cmdo_afutag_is_atomic_cas );  // -- atomic seq issues only 1 cmd (can be 1 of 3 types) 
  assign  cmdo_afutag_is_intrpt         =  ( cmdo_afutag_is_intrpt_cmd    || cmdo_afutag_is_intrpt_err || cmdo_afutag_is_intrpt_wht );  // -- intrpt seq issues only 1 cmd (can be 1 of 3 types)

  assign  undefined_cmdo_we_ld_afutag     =  cmdo_valid && cmdo_afutag_is_we_ld     && (( cmdo_afutag[15:14] != 2'b01 ) || // -- should always be 01 for 64B load
                                                                                        ( cmdo_afutag[13:12] != 2'b00 ));

  assign  undefined_cmdo_xtouch_afutag    =  cmdo_valid && cmdo_afutag_is_xtouch    && (( cmdo_afutag[15:14] != 2'b00 ) ||
                                                                                        ( cmdo_afutag[13:12] != 2'b00 ));

  assign  undefined_cmdo_cpy_afutag       =  cmdo_valid && cmdo_afutag_is_cpy       && (( cmdo_afutag[15:14] == 2'b00 ) || // -- 15:14 = b'01, b'10, b'11 for 64B, 128B, 256B ops
                                                                                        ( cmdo_afutag[13:12] != 2'b00 ));   

  assign  undefined_cmdo_wkhstthrd_afutag =  cmdo_valid && cmdo_afutag_is_wkhstthrd && (( cmdo_afutag[15:14] != 2'b00 ) ||
                                                                                        ( cmdo_afutag[13:12] != 2'b00 ));

  assign  undefined_cmdo_incr_ld_afutag   =  cmdo_valid && cmdo_afutag_is_incr_ld   && (( cmdo_afutag[15:14] != 2'b01 ) ||
                                                                                        ( cmdo_afutag[13:12] != 2'b00 )); 
   
  assign  undefined_cmdo_incr_st_afutag   =  cmdo_valid && cmdo_afutag_is_incr_st   && (( cmdo_afutag[15:14] != 2'b00 ) ||
                                                                                        ( cmdo_afutag[13]    != 1'b1  ));  // -- 13:12 = b'10 or b'11 for 4B vs 8B    

  assign  undefined_cmdo_incr_afutag      =  undefined_cmdo_incr_ld_afutag || undefined_cmdo_incr_st_afutag;

  assign  undefined_cmdo_atomic_afutag    =  cmdo_valid && cmdo_afutag_is_atomic    && (( cmdo_afutag[15:14] != 2'b00 ) ||
                                                                                        ( cmdo_afutag[13]    != 1'b1  ));  // -- 13:12 = b'10 or b'11 for 4B vs 8B    

  assign  undefined_cmdo_intrpt_afutag    =  cmdo_valid && cmdo_afutag_is_intrpt    && (( cmdo_afutag[15:14] != 2'b00 ) ||
                                                                                        ( cmdo_afutag[13]    != 1'b0  ));  // -- 13:12 = b'00 or b'01 for no data vs w/ data    


  // -- ********************************************************************************************************************************
  // -- Latch the Response
  // -- ********************************************************************************************************************************

  // -- Latch the response info
  always @*
    begin
      if  ( rspi_resp_data_valid_int_q && ( rspi_resp_dl_int_q[1:0] == 2'b11 ))
        begin
          rspi_resp_data_valid_xfer2_int_d = 1'b1;                            // -- for beat2 of 256B
          rspi_resp_afutag_dbuf_int_d[0]   =  rspi_resp_afutag_dbuf_int_q[0];
          rspi_resp_dl_dbuf_int_d[1:0]     =  rspi_resp_dl_dbuf_int_q[1:0];
        end
      else
        begin
          rspi_resp_data_valid_xfer2_int_d = 1'b0; 
          rspi_resp_afutag_dbuf_int_d[0]   =  rspi_eng_resp_afutag[0];
          rspi_resp_dl_dbuf_int_d[1:0]     =  rspi_eng_resp_dl[1:0];
        end
    end // -- always @ *                                  

  assign  rspi_resp_is_cpy_xx_int_d     = ~rspi_eng_resp_afutag[11];
  assign  rspi_resp_is_cpy_st_int_d     =  rspi_eng_resp_afutag[13];
  assign  rspi_resp_afutag_int_d[9:0]   =  rspi_eng_resp_afutag[9:0];
  assign  rspi_resp_opcode_int_d[7:0]   =  rspi_eng_resp_opcode[7:0];
  assign  rspi_resp_code_int_d[3:0]     =  rspi_eng_resp_code[3:0];
  assign  rspi_resp_dl_orig_int_d[1:0]  =  rspi_eng_resp_afutag[15:14];
  assign  rspi_resp_dl_int_d[1:0]       =  rspi_eng_resp_dl[1:0];
  assign  rspi_resp_dp_int_d[1:0]       =  rspi_eng_resp_dp[1:0];

  assign  rspi_resp_data_int_d[1023:0]  =  rspi_eng_resp_data_bus[1023:0];
  assign  rspi_resp_data_bdi_int_d[1:0] =  rspi_eng_resp_data_bdi[1:0];
  assign  rspi_resp_data_valid_int_d    =  rspi_resp_is_ld_good;


  // -- ********************************************************************************************************************************
  // -- Latch "Done" terms - (ie. NOT Retried)
  // -- ********************************************************************************************************************************

  // -- Latch "done" indicators - these are what allow the main sub-sequencers (non-retry sequencers) to advance
  // -- NOTE: "done" means good, fault, failed, derror, or aerror (nothing that is retried) 
  assign  rspi_we_ld_resp_val_d          =  rspi_resp_is_we_ld_done;
  assign  rspi_xtouch_source_resp_val_d  =  rspi_resp_is_xtouch_source_done && xtouch_wt4rsp_enable_q;
  assign  rspi_xtouch_dest_resp_val_d    =  rspi_resp_is_xtouch_dest_done   && xtouch_wt4rsp_enable_q;
  assign  rspi_cpy_ld_resp_val_d         =  rspi_resp_is_cpy_ld_done;
  assign  rspi_cpy_st_resp_val_d         =  rspi_resp_is_cpy_st_done;
  assign  rspi_wkhstthrd_resp_val_d      =  rspi_resp_is_wkhstthrd_done;
  assign  rspi_incr_ld_resp_val_d        =  rspi_resp_is_incr_ld_done;
  assign  rspi_incr_st_resp_val_d        =  rspi_resp_is_incr_st_done;
  assign  rspi_atomic_ld_resp_val_d      =  rspi_resp_is_atomic_ld_done;
  assign  rspi_atomic_st_resp_val_d      =  rspi_resp_is_atomic_st_done; 
  assign  rspi_atomic_cas_resp_val_int_d =  rspi_resp_is_atomic_cas_done;
  assign  rspi_intrpt_resp_val_d         =  rspi_resp_is_intrpt_done;
  assign  rspi_we_st_resp_val_d          =  rspi_resp_is_we_st_done;

  // -- send outbound to atomic seq
  assign  rspi_atomic_cas_resp_val_d     =  rspi_atomic_cas_resp_val_int_d;

  // -- Delay to align with wren into the array
  assign  rspi_resp_is_we_ld_rtry_w_backoff_d         =  (         rspi_resp_is_we_ld_rtry_req ||         rspi_resp_is_we_ld_rtry_lwt );
  assign  rspi_resp_is_xtouch_source_rtry_w_backoff_d =  ( rspi_resp_is_xtouch_source_rtry_req || rspi_resp_is_xtouch_source_rtry_lwt );
  assign  rspi_resp_is_xtouch_dest_rtry_w_backoff_d   =  (   rspi_resp_is_xtouch_dest_rtry_req ||   rspi_resp_is_xtouch_dest_rtry_lwt );
  assign  rspi_resp_is_cpy_ld_rtry_w_backoff_d        =  (        rspi_resp_is_cpy_ld_rtry_req ||        rspi_resp_is_cpy_ld_rtry_lwt );
  assign  rspi_resp_is_cpy_st_rtry_w_backoff_d        =  (        rspi_resp_is_cpy_st_rtry_req ||        rspi_resp_is_cpy_st_rtry_lwt );
  assign  rspi_resp_is_wkhstthrd_rtry_w_backoff_d     =  (     rspi_resp_is_wkhstthrd_rtry_req ||     rspi_resp_is_wkhstthrd_rtry_lwt );
  assign  rspi_resp_is_incr_rtry_w_backoff_d          =  (          rspi_resp_is_incr_rtry_req ||          rspi_resp_is_incr_rtry_lwt );
  assign  rspi_resp_is_atomic_rtry_w_backoff_d        =  (        rspi_resp_is_atomic_rtry_req ||        rspi_resp_is_atomic_rtry_lwt );
  assign  rspi_resp_is_intrpt_rtry_w_backoff_d        =  (        rspi_resp_is_intrpt_rtry_req ||        rspi_resp_is_intrpt_rtry_lwt );
  assign  rspi_resp_is_we_st_rtry_w_backoff_d         =  (         rspi_resp_is_we_st_rtry_req ||         rspi_resp_is_we_st_rtry_lwt );

  // -- send to performance counters
  assign  rspi_resp_is_wkhstthrd_good_d  =  rspi_resp_is_wkhstthrd_good;

  assign  eng_perf_wkhstthrd_good        =  rspi_resp_is_wkhstthrd_good_q;

  // -- ********************************************************************************************************************************
  // -- Latch "Rtry" terms - (ie. NOT "Done")
  // -- ********************************************************************************************************************************

  // -- Latch info that will be carried through the retry queue
  assign  rspi_resp_is_pending_int_d    =  rspi_resp_is_pending_int;       // -- Use this single cycle pulse to increment pending_cnt counter
  assign  rspi_resp_is_rtry_hwt_int_d   =  rspi_resp_is_rtry_hwt_int;      // -- Retry Immediate (no Backoff timer)
  assign  rspi_resp_is_rtry_req_int_d   =  rspi_resp_is_rtry_req_int;      // -- Retry after Long Backoff
  assign  rspi_resp_is_rtry_lwt_int_d   =  rspi_resp_is_rtry_lwt_int;      // -- Retry after Short Backoff

  // -- Drive outbound to the rtry queue
  assign  rspi_resp_is_pending_q    =  rspi_resp_is_pending_int_q;
  assign  rspi_resp_is_rtry_hwt_q   =  rspi_resp_is_rtry_hwt_int_q;
  assign  rspi_resp_is_rtry_req_q   =  rspi_resp_is_rtry_req_int_q;
  assign  rspi_resp_is_rtry_lwt_q   =  rspi_resp_is_rtry_lwt_int_q;

  assign  rspi_resp_is_pending_done_d   =  rspi_resp_is_pending_done_int;  // -- Use this single cycle pulse to decrement pending_cnt counter

  // -- Sent outbound to rtry partition to determine short vs long value to load into backoff timer
  assign  rspi_resp_is_rtry_req         =  rspi_resp_is_rtry_req_int;      // -- Retry after Long Backoff
  assign  rspi_resp_is_rtry_lwt         =  rspi_resp_is_rtry_lwt_int;      // -- Retry after Short Backoff



  // -- ********************************************************************************************************************************
  // -- Determine which data response when Extra Read mode for MMIO Ping-Pong Latency
  // -- ********************************************************************************************************************************

  assign  data_reg_sel[5:0]  =  { rspi_resp_data_valid_int_d, rspi_resp_data_valid_xfer2_int_d, rspi_resp_dl_int_d[0], rspi_resp_dp_int_d[1], rspi_resp_afutag_int_d[1], rspi_resp_afutag_int_q[1]};

  always @*
    begin
      casez ( data_reg_sel[5:0] )
        // --                                    
        // --  Inputs                                                 Outputs                             
        // --  -------------------                                    ---------------------                                                                         
        // --  rspi_resp_data_valid_int_d
        // --  |rspi_resp_data_valid_xfer2_int_d
        // --  ||
        // --  || rspi_resp_dl_int_d[0]
        // --  || |rspi_resp_dp_int_d[1]
        // --  || ||rspi_resp_afutag_int_d[1]
        // --  || |||rspi_resp_afutag_int_q[1]
        // --  || |||
        // --  54 3210
        // ------------------------------------------------------------------------
            6'b10_000?    :    extra_read_reg_d[3:0] =  4'b0001 ;  // -- Reg0:  dL=10, dp=00, tag=0, xfer2=0
            6'b10_1?0?    :    extra_read_reg_d[3:0] =  4'b0001 ;  // -- Reg0:  dL=11,      , tag=0, xfer2=0
        // ------------------------------------------------------------------------
            6'b10_010?    :    extra_read_reg_d[3:0] =  4'b0010 ;  // -- Reg1:  dL=10, dp=10, tag=0, xfer2=0
            6'b01_???0    :    extra_read_reg_d[3:0] =  4'b0010 ;  // -- Reg1:  dL=11,      , tag=0, xfer2=1
        // ------------------------------------------------------------------------
            6'b10_001?    :    extra_read_reg_d[3:0] =  4'b0100 ;  // -- Reg2:  dL=10, dp=00, tag=2, xfer2=0
            6'b10_1?1?    :    extra_read_reg_d[3:0] =  4'b0100 ;  // -- Reg2:  dL=11,      , tag=2, xfer2=0
        // ------------------------------------------------------------------------
            6'b10_011?    :    extra_read_reg_d[3:0] =  4'b1000 ;  // -- Reg3:  dL=10, dp=10, tag=2, xfer2=0
            6'b01_???1    :    extra_read_reg_d[3:0] =  4'b1000 ;  // -- Reg3:  dL=11,      , tag=2, xfer2=1
        // ------------------------------------------------------------------------
            6'b00_????    :    extra_read_reg_d[3:0] =  4'b0000 ;  // -- No valid response
            6'b11_????    :    extra_read_reg_d[3:0] =  4'b0000 ;  // -- Should be impossible
        // ------------------------------------------------------------------------
           default        :    extra_read_reg_d[3:0] =  4'b0000 ;  // -- No valid response
        // ------------------------------------------------------------------------
      endcase
    end // -- always @ *

  assign  eng_mmio_extra_read_resp[3:0]  =  extra_read_reg_q[3:0];  // Note: MMIO checks if extra_read mode is enabled

  // -- ********************************************************************************************************************************
  // -- Maintain "Pending" Count - used to block reading retry queue - xlate/intrp_pending responses are queued, released on xlate_done/intrp_rdy
  // -- ********************************************************************************************************************************

  // --                                       |     |     |     |     |     |     |     |     |     |     |
  // --                                        _____
  // -- rspi_resp_is_pending_int_d       _____|     |______________________________________________________
  // --                                              _____
  // -- rspi_resp_is_pending_done_d      ___________|     |________________________________________________
  // --
  // --                                              _____
  // -- rspi_resp_is_pending_int_q       ___________|     |________________________________________________
  // --                                                    _____
  // -- rspi_resp_is_pending_done_q      _________________|     |__________________________________________
  // --                                              ___________
  // -- pending_cnt_int_en               ___________|           |__________________________________________
  // --                                  ___________ _____ ________________________________________________
  // -- pending_cnt_int_d                _____0_____X__1__X_____0__________________________________________
  // --                                  _________________ _____ __________________________________________
  // -- pending_cnt_int_q                ___________0_____X__1__X_____0____________________________________


  // -- Table below shows which terms below cover retry case due to response code of *_pending
  // --  we_ld      
  // --  | xtouch_source_ea     
  // --  | | xtouch_dest_ea         
  // --  | | | cpy_ld          
  // --  | | | | cpy_st         
  // --  | | | | | wkhstthrd          
  // --  | | | | | | incr_ld          
  // --  | | | | | | | incr_st         
  // --  | | | | | | | | atomic_ld         
  // --  | | | | | | | | | atomic_cas         
  // --  | | | | | | | | | | atomic_st
  // --  | | | | | | | | | | | intrpt
  // --  | | | | | | | | | | | | we_st
  // --  | | | | | | | | | | | | |
  // --  -------------------------
  // --  X . . X . . X . X X . . .   rspi_resp_is_read_failed    && rspi_resp_code_is_xlate_pending
  // --  . . . . X . . X . . X . X   rspi_resp_is_write_failed   && rspi_resp_code_is_xlate_pending
  // --  . X X . . . . . . . . . .   rspi_resp_is_touch_resp     && rspi_resp_code_is_xlate_pending
  // --  . . . . . . . . . . . X .   rspi_resp_is_intrp_resp     && rspi_resp_code_is_intrp_pending
  // --  . . . . . X . . . . . . .   rspi_resp_is_wake_host_resp && rspi_resp_code_is_intrp_pending
  // --  -------------------------

  // -- Keep track of rtry_pending responses vs pending_done responses
  assign  pending_cnt_int_en =  ( reset || main_idle_st || rspi_resp_is_pending_int_q || rspi_resp_is_pending_done_q );  
  assign  pending_cnt_max_en =  ( reset || main_idle_st || rspi_resp_is_pending_int_q );

  always @*
    begin

      if ( reset || main_idle_st )
        pending_cnt_int_d[4:0] =  5'b0;
      else if (( rspi_resp_is_pending_int_q ) && ~( pending_cnt_int_q[4:0] == 5'b11111 ))
        pending_cnt_int_d[4:0] =  pending_cnt_int_q[4:0] + 5'b1; // -- Increment on a pending response (xlate_pending, intrp_pending)
      else if (( rspi_resp_is_pending_done_q ) && ~( pending_cnt_int_q[4:0] == 5'b0 ))
        pending_cnt_int_d[4:0] =  pending_cnt_int_q[4:0] - 5'b1; // -- Decrement on a pending done response (xlate_done, intrp_rdy)
      else
        pending_cnt_int_d[4:0] =  pending_cnt_int_q[4:0];        // -- Hold count value

      if ( reset || main_idle_st )
        pending_cnt_max_d[4:0] =  5'b0;
      else if (( rspi_resp_is_pending_int_q ) && ( pending_cnt_int_d[4:0] > pending_cnt_max_q[4:0] ))
        pending_cnt_max_d[4:0] = pending_cnt_int_d[4:0];       // -- Track maximum number of the pending_cnt
      else
        pending_cnt_max_d[4:0] =  pending_cnt_max_q[4:0];      // -- Hold count value

    end  // -- always @*

  // -- Send to Rtry Queue to block reads and to Display
  assign  pending_cnt_q[4:0] =  pending_cnt_int_q[4:0];


  // -- Detect an "extra/unexpected" xlate done
  assign  unexpected_xlate_done =  (( pending_cnt_int_q[4:0] == 5'b0 ) && (rspi_resp_is_pending_done_q ));


  // -- For Debug, count the total number of pendings
  assign  pending_cnt_total_en =  ( reset || main_idle_st || rspi_resp_is_pending_int_q );  
  always @*
    begin
      if ( reset || main_idle_st )
        pending_cnt_total_d[7:0] =  8'b0;
      else if (( rspi_resp_is_pending_int_q ) && ~( pending_cnt_total_q[7:0] == 8'hFF ))
        pending_cnt_total_d[7:0] =  ( pending_cnt_total_q[7:0] + 8'b1 );
      else
        pending_cnt_total_d[7:0] =    pending_cnt_total_q[7:0];
    end  // -- always @*



  // -- ********************************************************************************************************************************
  // -- Latch and hold error terms - needs holding for wr_weq fsm to put in the status
  // -- ********************************************************************************************************************************

  // -- Create Response Error Terms per sequencer
  assign  rspi_resp_is_we_ld_error         =  ( rspi_resp_is_we_ld_derror         || rspi_resp_is_we_ld_fault         || rspi_resp_is_we_ld_failed         || rspi_resp_is_we_ld_aerror         );
  assign  rspi_resp_is_xtouch_source_error =  ( rspi_resp_is_xtouch_source_derror || rspi_resp_is_xtouch_source_fault || rspi_resp_is_xtouch_source_failed || rspi_resp_is_xtouch_source_aerror );
  assign  rspi_resp_is_xtouch_dest_error   =  ( rspi_resp_is_xtouch_dest_derror   || rspi_resp_is_xtouch_dest_fault   || rspi_resp_is_xtouch_dest_failed   || rspi_resp_is_xtouch_dest_aerror   );
  assign  rspi_resp_is_cpy_ld_error        =  ( rspi_resp_is_cpy_ld_derror        || rspi_resp_is_cpy_ld_fault        || rspi_resp_is_cpy_ld_failed        || rspi_resp_is_cpy_ld_aerror        );
  assign  rspi_resp_is_cpy_st_error        =  ( rspi_resp_is_cpy_st_derror        || rspi_resp_is_cpy_st_fault        || rspi_resp_is_cpy_st_failed        || rspi_resp_is_cpy_st_aerror        );
  assign  rspi_resp_is_wkhstthrd_error     =  ( rspi_resp_is_wkhstthrd_derror     || rspi_resp_is_wkhstthrd_fault     || rspi_resp_is_wkhstthrd_failed     || rspi_resp_is_wkhstthrd_aerror     );
  assign  rspi_resp_is_incr_ld_error       =  ( rspi_resp_is_incr_ld_derror       || rspi_resp_is_incr_ld_fault       || rspi_resp_is_incr_ld_failed       || rspi_resp_is_incr_ld_aerror       );
  assign  rspi_resp_is_incr_st_error       =  ( rspi_resp_is_incr_st_derror       || rspi_resp_is_incr_st_fault       || rspi_resp_is_incr_st_failed       || rspi_resp_is_incr_st_aerror       );
  assign  rspi_resp_is_atomic_ld_error     =  ( rspi_resp_is_atomic_ld_derror     || rspi_resp_is_atomic_ld_fault     || rspi_resp_is_atomic_ld_failed     || rspi_resp_is_atomic_ld_aerror     );
  assign  rspi_resp_is_atomic_st_error     =  ( rspi_resp_is_atomic_st_derror     || rspi_resp_is_atomic_st_fault     || rspi_resp_is_atomic_st_failed     || rspi_resp_is_atomic_st_aerror     );
  assign  rspi_resp_is_atomic_cas_error    =  ( rspi_resp_is_atomic_cas_derror    || rspi_resp_is_atomic_cas_fault    || rspi_resp_is_atomic_cas_failed    || rspi_resp_is_atomic_cas_aerror    );
  assign  rspi_resp_is_intrpt_cmd_error    =  ( rspi_resp_is_intrpt_cmd_derror    || rspi_resp_is_intrpt_cmd_fault    || rspi_resp_is_intrpt_cmd_failed    || rspi_resp_is_intrpt_cmd_aerror    );
  assign  rspi_resp_is_intrpt_err_error    =  ( rspi_resp_is_intrpt_err_derror    || rspi_resp_is_intrpt_err_fault    || rspi_resp_is_intrpt_err_failed    || rspi_resp_is_intrpt_err_aerror    );
  assign  rspi_resp_is_intrpt_wht_error    =  ( rspi_resp_is_intrpt_wht_derror    || rspi_resp_is_intrpt_wht_fault    || rspi_resp_is_intrpt_wht_failed    || rspi_resp_is_intrpt_wht_aerror    );
  assign  rspi_resp_is_we_st_error         =  ( rspi_resp_is_we_st_derror         || rspi_resp_is_we_st_fault         || rspi_resp_is_we_st_failed         || rspi_resp_is_we_st_aerror         );

  assign  rspi_resp_is_xtouch_error        =  ( rspi_resp_is_xtouch_derror        || rspi_resp_is_xtouch_fault        || rspi_resp_is_xtouch_failed        || rspi_resp_is_xtouch_aerror        );
  assign  rspi_resp_is_cpy_error           =  ( rspi_resp_is_cpy_derror           || rspi_resp_is_cpy_fault           || rspi_resp_is_cpy_failed           || rspi_resp_is_cpy_aerror           );
  assign  rspi_resp_is_incr_error          =  ( rspi_resp_is_incr_derror          || rspi_resp_is_incr_fault          || rspi_resp_is_incr_failed          || rspi_resp_is_incr_aerror          );
  assign  rspi_resp_is_atomic_error        =  ( rspi_resp_is_atomic_derror        || rspi_resp_is_atomic_fault        || rspi_resp_is_atomic_failed        || rspi_resp_is_atomic_aerror        );
  assign  rspi_resp_is_intrpt_error        =  ( rspi_resp_is_intrpt_derror        || rspi_resp_is_intrpt_fault        || rspi_resp_is_intrpt_failed        || rspi_resp_is_intrpt_aerror        );

  assign  rspi_resp_is_error               =  ( rspi_resp_is_derror_int           || rspi_resp_is_fault_int           || rspi_resp_is_failed_int           || rspi_resp_is_aerror_int           );


  // -- Create Other Error Terms per sequencer
  assign  we_ld_bdi_error      =  (( rspi_resp_data_bdi_int_q[0]   != 1'b0 ) &&   rspi_resp_data_valid_int_q                                       &&  we_ld_wt4rsp_st );
  assign  cpy_ld_bdi_error     =  (( rspi_resp_data_bdi_int_q[1:0] != 2'b0 ) && ( rspi_resp_data_valid_int_q || rspi_resp_data_valid_xfer2_int_q ) &&  ~cpy_ld_idle_st );  // TODO:  If AFP ends up implementing another type of load besides cpy_ld, will need to add different logic than ~cpy_ld_idle_st.  This worked on MCP because only one type was active at a time, but on AFP, cpy_ld is basically always non-idle.
  assign  incr_ld_bdi_error    =  (( rspi_resp_data_bdi_int_q[0]   != 1'b0 ) &&   rspi_resp_data_valid_int_q                                       && incr_wt4ldrsp_st );
  assign  atomic_ld_bdi_error  =  (( rspi_resp_data_bdi_int_q[0]   != 1'b0 ) &&   rspi_resp_data_valid_int_q                                       && atomic_wt4rsp_st && we_cmd_is_atomic_ld_q  );
  assign  atomic_cas_bdi_error =  (( rspi_resp_data_bdi_int_q[0]   != 1'b0 ) &&   rspi_resp_data_valid_int_q                                       && atomic_wt4rsp_st && we_cmd_is_atomic_cas_q );

  // -- Latch and hold error terms
  always @*
    begin 
      if (reset)
        begin
          rspi_resp_fault_int_d     =  1'b0;
          rspi_resp_failed_int_d    =  1'b0;
          rspi_resp_aerror_int_d    =  1'b0;
          rspi_resp_derror_int_d    =  1'b0;
     
          we_ld_error_int_d         =  1'b0;
          xtouch_source_error_int_d =  1'b0;
          xtouch_dest_error_int_d   =  1'b0;
          cpy_ld_error_int_d        =  1'b0;                           
          cpy_st_error_int_d        =  1'b0;
          wkhstthrd_error_int_d     =  1'b0;
          incr_ld_error_int_d       =  1'b0;
          incr_st_error_int_d       =  1'b0;
          atomic_ld_error_int_d     =  1'b0;
          atomic_st_error_int_d     =  1'b0;
          atomic_cas_error_int_d    =  1'b0;
          intrpt_cmd_error_int_d    =  1'b0;
          intrpt_err_error_int_d    =  1'b0;
          intrpt_wht_error_int_d    =  1'b0;
          we_st_error_int_d         =  1'b0;

          xtouch_error_int_d        =  1'b0;
          cpy_error_int_d           =  1'b0;                           
          incr_error_int_d          =  1'b0;
          atomic_error_int_d        =  1'b0;
          intrpt_error_int_d        =  1'b0;

          error_int_d               =  1'b0;
        end
      else
        begin
          rspi_resp_fault_int_d  =  ( rspi_resp_is_fault_int  || ( rspi_resp_fault_int_q  && ~main_idle_st ));
          rspi_resp_failed_int_d =  ( rspi_resp_is_failed_int || ( rspi_resp_failed_int_q && ~main_idle_st ));
          rspi_resp_aerror_int_d =  ( rspi_resp_is_aerror_int || ( rspi_resp_aerror_int_q && ~main_idle_st ));
          rspi_resp_derror_int_d =  ( rspi_resp_is_derror_int || ( rspi_resp_derror_int_q && ~main_idle_st ) ||
                                    ( cpy_cmd_resp_rcvd_overlap || cpy_cmd_resp_rcvd_mismatch ) ||
                                    ( we_ld_bdi_error || cpy_ld_bdi_error || incr_ld_bdi_error || atomic_ld_bdi_error || atomic_cas_bdi_error ));

          we_ld_error_int_d         =  ( rspi_resp_is_we_ld_error         || (         we_ld_error_int_q && ~main_idle_st ) || we_ld_bdi_error );
          xtouch_source_error_int_d =  ( rspi_resp_is_xtouch_source_error || ( xtouch_source_error_int_q && ~main_idle_st ));
          xtouch_dest_error_int_d   =  ( rspi_resp_is_xtouch_dest_error   || (   xtouch_dest_error_int_q && ~main_idle_st ));
          cpy_ld_error_int_d        =  ( rspi_resp_is_cpy_ld_error        || (        cpy_ld_error_int_q && ~main_idle_st ) || cpy_cmd_resp_rcvd_overlap || cpy_cmd_resp_rcvd_mismatch || cpy_ld_bdi_error );                                  
          cpy_st_error_int_d        =  ( rspi_resp_is_cpy_st_error        || (        cpy_st_error_int_q && ~main_idle_st ) || cpy_cmd_resp_rcvd_overlap || cpy_cmd_resp_rcvd_mismatch );
          wkhstthrd_error_int_d     =  ( rspi_resp_is_wkhstthrd_error     || (     wkhstthrd_error_int_q && ~main_idle_st ));
          incr_ld_error_int_d       =  ( rspi_resp_is_incr_ld_error       || (       incr_ld_error_int_q && ~main_idle_st ) || incr_ld_bdi_error);
          incr_st_error_int_d       =  ( rspi_resp_is_incr_st_error       || (       incr_st_error_int_q && ~main_idle_st ));
          atomic_ld_error_int_d     =  ( rspi_resp_is_atomic_ld_error     || (     atomic_ld_error_int_q && ~main_idle_st ) || atomic_ld_bdi_error );
          atomic_st_error_int_d     =  ( rspi_resp_is_atomic_st_error     || (     atomic_st_error_int_q && ~main_idle_st ));
          atomic_cas_error_int_d    =  ( rspi_resp_is_atomic_cas_error    || (    atomic_cas_error_int_q && ~main_idle_st ) || atomic_cas_bdi_error );
          intrpt_cmd_error_int_d    =  ( rspi_resp_is_intrpt_cmd_error    || (    intrpt_cmd_error_int_q && ~main_idle_st ));
          intrpt_err_error_int_d    =  ( rspi_resp_is_intrpt_err_error    || (    intrpt_err_error_int_q && ~main_idle_st ));
          intrpt_wht_error_int_d    =  ( rspi_resp_is_intrpt_wht_error    || (    intrpt_wht_error_int_q && ~main_idle_st ));
          we_st_error_int_d         =  ( rspi_resp_is_we_st_error         || (         we_st_error_int_q && ~main_idle_st ));
                                                                           
          xtouch_error_int_d        =  ( rspi_resp_is_xtouch_error        || (        xtouch_error_int_q && ~main_idle_st ));
          cpy_error_int_d           =  ( rspi_resp_is_cpy_error           || (           cpy_error_int_q && ~main_idle_st ) || cpy_cmd_resp_rcvd_overlap || cpy_cmd_resp_rcvd_mismatch || cpy_ld_bdi_error );                                  
          incr_error_int_d          =  ( rspi_resp_is_incr_error          || (          incr_error_int_q && ~main_idle_st ) || incr_ld_bdi_error );
          atomic_error_int_d        =  ( rspi_resp_is_atomic_error        || (        atomic_error_int_q && ~main_idle_st ) || atomic_ld_bdi_error || atomic_cas_bdi_error );
          intrpt_error_int_d        =  ( rspi_resp_is_intrpt_error        || (        intrpt_error_int_q && ~main_idle_st ));
 
          error_int_d               =  ( rspi_resp_is_error               || (               error_int_q && ~main_idle_st ));
        end

    end // -- always @ *

  // -- Send outbound to wr_weq sequencer for inclusion in status
  assign  rspi_resp_fault_q     =  rspi_resp_fault_int_q;
  assign  rspi_resp_failed_q    =  rspi_resp_failed_int_q;
  assign  rspi_resp_aerror_q    =  rspi_resp_aerror_int_q;
  assign  rspi_resp_derror_q    =  rspi_resp_derror_int_q;

  assign  we_ld_error_q         =  we_ld_error_int_q;
  assign  xtouch_source_error_q =  xtouch_source_error_int_q;
  assign  xtouch_dest_error_q   =  xtouch_dest_error_int_q;
  assign  cpy_ld_error_q        =  cpy_ld_error_int_q;                                  
  assign  cpy_st_error_q        =  cpy_st_error_int_q;
  assign  wkhstthrd_error_q     =  wkhstthrd_error_int_q;
  assign  incr_ld_error_q       =  incr_ld_error_int_q;
  assign  incr_st_error_q       =  incr_st_error_int_q;
  assign  atomic_ld_error_q     =  atomic_ld_error_int_q;
  assign  atomic_st_error_q     =  atomic_st_error_int_q;
  assign  atomic_cas_error_q    =  atomic_cas_error_int_q;
  assign  intrpt_cmd_error_q    =  intrpt_cmd_error_int_q;
  assign  intrpt_err_error_q    =  intrpt_err_error_int_q;
  assign  intrpt_wht_error_q    =  intrpt_wht_error_int_q;
  assign  we_st_error_q         =  we_st_error_int_q;

  assign  xtouch_error_q        =  xtouch_error_int_q;
  assign  cpy_error_q           =  cpy_error_int_q;                                  
  assign  incr_error_q          =  incr_error_int_q;
  assign  atomic_error_q        =  atomic_error_int_q;
  assign  intrpt_error_q        =  intrpt_error_int_q;

  assign  error_q               =  error_int_q;

  // -- Send outbound
  assign  rspi_resp_afutag_dbuf_q[0:0]  =  rspi_resp_afutag_dbuf_int_q[0:0];
  assign  rspi_resp_dl_dbuf_q[1:0]      =  rspi_resp_dl_dbuf_int_q[1:0];

  assign  rspi_resp_is_cpy_xx_q         =  rspi_resp_is_cpy_xx_int_q;
  assign  rspi_resp_is_cpy_st_q         =  rspi_resp_is_cpy_st_int_q;
  assign  rspi_resp_afutag_q[8:0]       =  rspi_resp_afutag_int_q[8:0];
  assign  rspi_resp_opcode_q[7:0]       =  rspi_resp_opcode_int_q[7:0];
  assign  rspi_resp_code_q[3:0]         =  rspi_resp_code_int_q[3:0];
  assign  rspi_resp_dl_orig_q[1:0]      =  rspi_resp_dl_orig_int_q[1:0];
  assign  rspi_resp_dl_q[1:0]           =  rspi_resp_dl_int_q[1:0];
  assign  rspi_resp_dp_q[1:0]           =  rspi_resp_dp_int_q[1:0];
  assign  rspi_resp_data_q[1023:0]      =  rspi_resp_data_int_q[1023:0];
  assign  rspi_resp_data_bdi_q[1:0]     =  rspi_resp_data_bdi_int_q[1:0];
  assign  rspi_resp_data_valid_q        =  rspi_resp_data_valid_int_q;
  assign  rspi_resp_data_valid_xfer2_q  =  rspi_resp_data_valid_xfer2_int_q;

  assign  eng_mmio_data[1023:0]         =  rspi_resp_data_int_q[1023:0];

  // -- ********************************************************************************************************************************
  // -- Bugspray
  // -- ********************************************************************************************************************************

//!! Bugspray include : afp3_eng_resp_decode.bil


  // -- ********************************************************************************************************************************
  // -- Latch Assignments
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      // -- rspi response latches
//--  rspi_eng_resp_valid_q                       <= rspi_eng_resp_valid_d;

      rspi_resp_afutag_dbuf_int_q[0]              <= rspi_resp_afutag_dbuf_int_d[0];     
      rspi_resp_dl_dbuf_int_q[1:0]                <= rspi_resp_dl_dbuf_int_d[1:0];          

      rspi_resp_is_cpy_xx_int_q                   <= rspi_resp_is_cpy_xx_int_d;
      rspi_resp_is_cpy_st_int_q                   <= rspi_resp_is_cpy_st_int_d;
      rspi_resp_afutag_int_q[9:0]                 <= rspi_resp_afutag_int_d[9:0];
      rspi_resp_opcode_int_q[7:0]                 <= rspi_resp_opcode_int_d[7:0];      
      rspi_resp_code_int_q[3:0]                   <= rspi_resp_code_int_d[3:0];        
      rspi_resp_dl_orig_int_q[1:0]                <= rspi_resp_dl_orig_int_d[1:0];     
      rspi_resp_dl_int_q[1:0]                     <= rspi_resp_dl_int_d[1:0];          
      rspi_resp_dp_int_q[1:0]                     <= rspi_resp_dp_int_d[1:0];          
      rspi_resp_data_int_q[1023:0]                <= rspi_resp_data_int_d[1023:0];     
      rspi_resp_data_bdi_int_q[1:0]               <= rspi_resp_data_bdi_int_d[1:0];     
      rspi_resp_data_valid_int_q                  <= rspi_resp_data_valid_int_d;       
      rspi_resp_data_valid_xfer2_int_q            <= rspi_resp_data_valid_xfer2_int_d;

      rspi_we_ld_resp_val_q                       <= rspi_we_ld_resp_val_d;        
      rspi_xtouch_source_resp_val_q               <= rspi_xtouch_source_resp_val_d;       
      rspi_xtouch_dest_resp_val_q                 <= rspi_xtouch_dest_resp_val_d;       
      rspi_cpy_ld_resp_val_q                      <= rspi_cpy_ld_resp_val_d;       
      rspi_cpy_st_resp_val_q                      <= rspi_cpy_st_resp_val_d;       
      rspi_intrpt_resp_val_q                      <= rspi_intrpt_resp_val_d;       
      rspi_wkhstthrd_resp_val_q                   <= rspi_wkhstthrd_resp_val_d;       
      rspi_incr_ld_resp_val_q                     <= rspi_incr_ld_resp_val_d;       
      rspi_incr_st_resp_val_q                     <= rspi_incr_st_resp_val_d;       
      rspi_atomic_ld_resp_val_q                   <= rspi_atomic_ld_resp_val_d;       
      rspi_atomic_st_resp_val_q                   <= rspi_atomic_st_resp_val_d;       
      rspi_atomic_cas_resp_val_int_q              <= rspi_atomic_cas_resp_val_int_d;       
      rspi_we_st_resp_val_q                       <= rspi_we_st_resp_val_d;

      rspi_resp_is_pending_int_q                  <= rspi_resp_is_pending_int_d;  
      rspi_resp_is_rtry_hwt_int_q                 <= rspi_resp_is_rtry_hwt_int_d;  
      rspi_resp_is_rtry_req_int_q                 <= rspi_resp_is_rtry_req_int_d;  
      rspi_resp_is_rtry_lwt_int_q                 <= rspi_resp_is_rtry_lwt_int_d;  

      rspi_resp_is_pending_done_q                 <= rspi_resp_is_pending_done_d;

      rspi_resp_is_we_ld_rtry_w_backoff_q         <= rspi_resp_is_we_ld_rtry_w_backoff_d;
      rspi_resp_is_xtouch_source_rtry_w_backoff_q <= rspi_resp_is_xtouch_source_rtry_w_backoff_d;
      rspi_resp_is_xtouch_dest_rtry_w_backoff_q   <= rspi_resp_is_xtouch_dest_rtry_w_backoff_d;
      rspi_resp_is_cpy_ld_rtry_w_backoff_q        <= rspi_resp_is_cpy_ld_rtry_w_backoff_d;
      rspi_resp_is_cpy_st_rtry_w_backoff_q        <= rspi_resp_is_cpy_st_rtry_w_backoff_d;
      rspi_resp_is_wkhstthrd_rtry_w_backoff_q     <= rspi_resp_is_wkhstthrd_rtry_w_backoff_d;
      rspi_resp_is_incr_rtry_w_backoff_q          <= rspi_resp_is_incr_rtry_w_backoff_d;
      rspi_resp_is_atomic_rtry_w_backoff_q        <= rspi_resp_is_atomic_rtry_w_backoff_d;
      rspi_resp_is_intrpt_rtry_w_backoff_q        <= rspi_resp_is_intrpt_rtry_w_backoff_d;
      rspi_resp_is_we_st_rtry_w_backoff_q         <= rspi_resp_is_we_st_rtry_w_backoff_d;

      rspi_resp_is_wkhstthrd_good_q               <= rspi_resp_is_wkhstthrd_good_d;

      extra_read_reg_q[3:0]                       <= extra_read_reg_d[3:0];

      if ( pending_cnt_int_en )
        pending_cnt_int_q[4:0]                    <= pending_cnt_int_d[4:0];

      if ( pending_cnt_max_en )
        pending_cnt_max_q[4:0]                    <= pending_cnt_max_d[4:0];

      if ( pending_cnt_total_en )
        pending_cnt_total_q[7:0]                  <= pending_cnt_total_d[7:0];

      rspi_resp_fault_int_q                       <= rspi_resp_fault_int_d;            
      rspi_resp_failed_int_q                      <= rspi_resp_failed_int_d;           
      rspi_resp_aerror_int_q                      <= rspi_resp_aerror_int_d;           
      rspi_resp_derror_int_q                      <= rspi_resp_derror_int_d;           

      we_ld_error_int_q                           <= we_ld_error_int_d;                
      xtouch_source_error_int_q                   <= xtouch_source_error_int_d;
      xtouch_dest_error_int_q                     <= xtouch_dest_error_int_d;
      cpy_ld_error_int_q                          <= cpy_ld_error_int_d;               
      cpy_st_error_int_q                          <= cpy_st_error_int_d;               
      wkhstthrd_error_int_q                       <= wkhstthrd_error_int_d;               
      incr_ld_error_int_q                         <= incr_ld_error_int_d;
      incr_st_error_int_q                         <= incr_st_error_int_d;
      atomic_ld_error_int_q                       <= atomic_ld_error_int_d;
      atomic_st_error_int_q                       <= atomic_st_error_int_d;
      atomic_cas_error_int_q                      <= atomic_cas_error_int_d;
      intrpt_cmd_error_int_q                      <= intrpt_cmd_error_int_d;               
      intrpt_err_error_int_q                      <= intrpt_err_error_int_d;               
      intrpt_wht_error_int_q                      <= intrpt_wht_error_int_d;               
      we_st_error_int_q                           <= we_st_error_int_d;                

      xtouch_error_int_q                          <= xtouch_error_int_d;
      cpy_error_int_q                             <= cpy_error_int_d;   
      incr_error_int_q                            <= incr_error_int_d;
      atomic_error_int_q                          <= atomic_error_int_d;
      intrpt_error_int_q                          <= intrpt_error_int_d;               

      error_int_q                                 <= error_int_d;

      unexpected_xlate_or_intrpt_done_200_q       <= unexpected_xlate_or_intrpt_done_200_d;

      rspi_resp_is_xlate_pending_q                <= rspi_resp_is_xlate_pending_d;          
      rspi_resp_is_intrp_pending_q                <= rspi_resp_is_intrp_pending_d;         
                                                     
      back_to_back_xlate_pending_and_done_q       <= back_to_back_xlate_pending_and_done_d; 
      back_to_back_intrp_pending_and_rdy_q        <= back_to_back_intrp_pending_and_rdy_d;  


    end // -- always @ *

endmodule



  // -- Sequencer    Command      Size   Response Opcode   Response Code  Action
  // -- -----------  -----------  -----  ----------------  -------------  --------------------------------------------------------------------------------------------------------------------------------------------------
  // -- we_ld        rd_wnitc      64B   read_response          NA        Good full response (no partial/split) - we_ld seq advance to decode - no
  // -- -----------  -----------  -----  ----------------  -------------  --------------------------------------------------------------------------------------------------------------------------------------------------
  // -- we_ld        rd_wnitc      64B   read_failed       rty_req        1) Write afutag, dl, dp, into the retry queue (rtry_queue_wren)
  // --                                                                   2) Increment rtry_queue_wraddr_q  ( +1 or wrap back to 0 ) 
  // --                                                                   3) rtry_queue_wraddr_q != rtry_queue_rdaddr_q ->  rtry_queue_empty = b'0  -> assert rtry_queue_func_rden
  // --                                                                   4) Increment rtry_queue_rdaddr_q  ( +1 or wrap back to 0 ) 
  // --                                                                   5) rtry_queue_wraddr_q == rtry_queue_rdaddr_q ->  rtry_queue_empty = b'1
  // --                                                                   6) block subsequent rtry_queue_func_rden for 2 cycles to allow only 1 retry request to propagate to the output latches of the rtry_queue  
  // --                                                                   7) 2 cycles after rtry_queue_func_rden, output of rtry_queue is latched - assert start_we_rtry_ld_seq
  // --                                                                   8) Continue to block rtry_queue_func_rden while we_rtry_ld_seq is active (ie. NOT we_rtry_ld_idle_st)
  // --                                                                   9) we_ld_seq remains in we_ld_wt4rsp_st as the we_rtry_ld_seq walks through retry sequence
  // --                                                                      A) start backoff timer as we_rtry_ld_seq advances from we_rtry_ld_idle_st to we_rtry_ld_wt4bckoff_st
  // --                                                                      B) wait for backoff timer to count down
  // --                                                                      C) assert we_rtry_ld_req / eng_arb_rtry_ld_req to the arbiter as we_rtry_ld_seq advances from we_rtry_ld_wt4bckoff_st to we_rtry_ld_wt4gnt_st
  // --                                                                      D) wait for grant from arbiter ( arb_eng_rtry_ld_gnt )
  // --                                                                      E) arb_eng_rtry_ld_gnt obtained, drive the retry command (1 cycle after grant), we_rtry_ld_seq advances from we_rtry_ld_wt4gnt_st to we_rtry_ld_idle_st
  // --                                                                  10) we_ld_seq remains in we_ld_wt4rsp_st and will advance if it gets good read response.  It can be again retried and loop retries until good response
  // -- -----------  -----------  -----  ----------------  -------------  --------------------------------------------------------------------------------------------------------------------------------------------------
  // -- we_ld        rd_wnitc      64B   read_failed       lw_rty_req     Not supported until OpenCAPI 4.0 so no support in the AFU - would be treated same as rty_req,  but make use of the short backoff timer instead of long
  // -- -----------  -----------  -----  ----------------  -------------  --------------------------------------------------------------------------------------------------------------------------------------------------
  // -- we_ld        rd_wnitc      64B   read_failed       xlate_pending  Treat the same as rty_req with the following acceptions
  // --                                                                   1a) Increment pending_cnt_q (+1)
  // --                                                                   3') rtry_queue_wraddr_q != rtry_queue_rdaddr_q ->  rtry_queue_empty = b'0  -> DO NOT assert rtry_queue_func_rden (blocked by 3b)
  // --                                                                   3b) pending_cnt_q != 0 -> rtry_queue_func_rden_blocker = b'1                       ------
  // --                                                                   3c) wait for xlate_done
  // --                                                                   3d) when xlate_done comes back, Decrement pending_cnt (-1)
  // --                                                                   3e) pending_cnt_q == 0 -> rtry_queue_func_rden_blocker = b'0  
  // --                                                                   3-10) same as rty_req
  // -- -----------  -----------  -----  ----------------  -------------  --------------------------------------------------------------------------------------------------------------------------------------------------
  // -- we_ld        rd_wnitc      64B   read_failed       derror         1) rspi_resp_is_derror -> latch and hold in rspi_resp_is_derror_q until main sequencer goes idle
  // --                                                                   2) rspi_resp_ld_done -> rspi_we_ld_resp_val_d/q (because ~we_ld_idle_st)
  // --                                                                      NOTE: rspi_resp_ld_done is active for anything that is read_response OR (read_failed AND ~rty_req AND ~lw_rty_req AND ~xlate_pending)
  // --                                                                   3) sequencer will continue to completion, setting bit 3 of status to indicate derror
  // -- -----------  -----------  -----  ----------------  -------------  --------------------------------------------------------------------------------------------------------------------------------------------------
  // -- we_ld        rd_wnitc      64B   read_failed       bad_length     1) rspi_resp_ld_fail -> latch and hold in rspi_resp_is_failed_q until main sequencer goes idle
  // --                                                                   2) latch and hold in we_ld_error_q until main sequencer goes idle
  // --                                                                      NOTE: rspi_resp_ld_done is active for anything that is read_response OR (read_failed AND ~rty_req AND ~lw_rty_req AND ~xlate_pending)
  // --                                                                   3) sequencer will continue to completion, setting bit 5 of status to indicate failed, and bit 7 to indicate fail occurred on we_ld 
  // -- -----------  -----------  -----  ----------------  -------------  --------------------------------------------------------------------------------------------------------------------------------------------------
  // -- we_ld        rd_wnitc      64B   read_failed       bad_addr       Same as bad_length
  // -- -----------  -----------  -----  ----------------  -------------  --------------------------------------------------------------------------------------------------------------------------------------------------
  // -- we_ld        rd_wnitc      64B   read_failed       failed         Same as bad_length
  // -- -----------  -----------  -----  ----------------  -------------  --------------------------------------------------------------------------------------------------------------------------------------------------
  // -- xtouch       xlate_touch lwt_ro  touch_resp        Done           Good responsee 
  // --                                                    rty_hwt        Does NOT go through Retry Queue - xtouch sequencer maintains 







