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

module afp3_eng (
  
  // -- clock control
    input                 clock                                                                                                                    
  , input                 reset                                                                                                                    

//     , input           [5:0] eng_num                        // -- static engine number - one extra bit for potential expansion from 32 to 64 engines     

  , input           [9:0] mmio_eng_pasid                 // -- context handle

  // -- Copy Machine Interface  (all engines snoop, respond if non-start command and cch matches)
//     , input                 weq_eng_any_enable             // -- indication of any engine receiving new process - for error checking
//     , input                 weq_eng_enable                 // -- give new process to engine
//     , input                 weq_eng_pe_terminate           // -- send terminate request to all engines (engine does pasid compare)                      
//     , input          [63:0] weq_eng_wed                   // -- work element descriptor               valid with (weq_eng_cmd_enb)  
//, input          [63:0] weq_eng_intrpt_obj             // -- Interrupt object_handle               valid with (weq_eng_cmd_enb)  
//, input          [31:0] weq_eng_intrpt_data            // -- Interrupt data                        valid with (weq_eng_cmd_enb)  
//, input           [1:0] weq_eng_intrpt_type            // -- Interrupt type                        valid with (weq_eng_cmd_enb)  
//     , input          [18:5] weq_eng_offset                 // -- cache line offset of next command     valid with (weq_eng_cmd_enb)                     
//     , input                 weq_eng_we_wrap                // -- bit to indicate current wrap through element queue memory    valid with (weq_eng_cmd_enb)
//     , output                eng_weq_pe_ack                 // -- ack from engine if match pasid on terminate     valid cycle after cmd_valid            

//     , output                eng_weq_we_req                 // -- request pulse to write to WEQ                                                          
//     , input                 weq_eng_we_gnt                 // -- write to weq granted                                                                   
//     , output         [19:0] eng_weq_we_pasid               // -- and-or structure in eng wrapper based on gnt     valid cycle after weq_emg_wr_gnt     
//     , output         [18:5] eng_weq_we_offset              // -- cache line offset of next line to process: in WED            valid cycle after weq_emg_wr_gnt
//     , output                eng_weq_we_wrap                // -- bit to indicate if element queue: in memory has wrapped
//     , output         [11:0] eng_weq_we_pe_stat             // -- status bus to store in process element array
//     , output                eng_weq_we_cmd_val_orig        // -- status bus to store in process element array

//     , output                eng_weq_done                   // -- done, one per engine, multiple engines can be done: IN same cycle

  // -- engine load cmd request interface
//     , output                eng_arb_ld_req                 // -- eng ld cmd req, pulse
  , input                 arb_eng_ld_gnt                 // -- req granted
  , input           [8:0] arb_eng_ld_tag
  , output        [511:0] eng_arb_set_ld_tag_avail
  , output                eng_arb_ld_fastpath_valid
  , output          [8:0] eng_arb_ld_fastpath_tag

  // -- engine store cmd request interface
//    , output                eng_arb_st_req                 // -- eng st cmd req, pulse
//    , output                eng_arb_st_256                 // -- eng st cmd data length
//    , output                eng_arb_st_128                 // -- eng st cmd data length
  , input                 arb_eng_st_gnt                 // -- req granted
  , input           [8:0] arb_eng_st_tag
  , output        [511:0] eng_arb_set_st_tag_avail
  , output                eng_arb_st_fastpath_valid
  , output          [8:0] eng_arb_st_fastpath_tag

  // -- engine misc cmd request interface
  , output                eng_arb_misc_req               // -- eng misc cmd req, pulse
  , output                eng_arb_misc_w_data            // -- eng misc cmd req has 64B data
  , output                eng_arb_misc_needs_extra_write // -- eng misc cmd req needs a write after the misc cmd
  , input                 arb_eng_misc_gnt               // -- req granted

  // -- engine rtry load cmd request interface
  , output                eng_arb_rtry_ld_req            // -- eng rtry ld cmd req, pulse
  , input                 arb_eng_rtry_ld_gnt            // -- req granted

  // -- engine rtry store cmd request interface
  , output                eng_arb_rtry_st_req            // -- eng rtry st cmd req, pulse
  , output                eng_arb_rtry_st_256            // -- eng rtry st cmd data length
  , output                eng_arb_rtry_st_128            // -- eng rtry st cmd data length
  , input                 arb_eng_rtry_st_gnt            // -- req granted

  // -- engine misc cmd request interface
  , output                eng_arb_rtry_misc_req          // -- eng rtry misc cmd req, pulse
  , output                eng_arb_rtry_misc_w_data       // -- eng rtry misc cmd req has 64B data
  , input                 arb_eng_rtry_misc_gnt          // -- req granted

  , input                 arb_eng_tags_idle              // -- no outstanding loads/stores
  , output                eng_arb_init
  , output                eng_arb_ld_enable
  , output                eng_arb_st_enable

  // -- command signals, shared between load/store/misc
  , output                eng_cmdo_valid
  , output          [7:0] eng_cmdo_opcode
  , output         [11:0] eng_cmdo_actag
  , output          [3:0] eng_cmdo_stream_id
  , output         [67:0] eng_cmdo_ea_or_obj
  , output         [15:0] eng_cmdo_afutag
  , output          [1:0] eng_cmdo_dl
  , output          [2:0] eng_cmdo_pl
  , output                eng_cmdo_os
  , output         [63:0] eng_cmdo_be
  , output          [3:0] eng_cmdo_flag
  , output                eng_cmdo_endian
  , output         [15:0] eng_cmdo_bdf
  , output         [19:0] eng_cmdo_pasid
  , output          [5:0] eng_cmdo_pg_size

  , output                eng_cmdo_st_valid
  , output       [1023:0] eng_cmdo_st_data

 // -- rspi resp interface
  , input                 rspi_eng_resp_valid            // -- response valid
  , input          [15:0] rspi_eng_resp_afutag           // -- response tag, used to retrieve data from outbound data buffer, valid with rsp_val
  , input           [7:0] rspi_eng_resp_opcode
  , input           [3:0] rspi_eng_resp_code
  , input           [1:0] rspi_eng_resp_dl
  , input           [1:0] rspi_eng_resp_dp
  , input                 rspi_eng_resp_data_valid       // -- response data valid
  , input           [1:0] rspi_eng_resp_data_bdi         // -- response data bad data indicator
  , input        [1023:0] rspi_eng_resp_data_bus         // -- response data

 // -- control and config signals
  , input          [11:0] cfg_afu_actag_base
  , input           [3:0] cfg_afu_long_backoff_timer
  , input           [3:0] cfg_afu_short_backoff_timer

  , input           [7:0] cfg_afu_bdf_bus
  , input           [4:0] cfg_afu_bdf_device
  , input           [2:0] cfg_afu_bdf_function

//     , input                 mmio_eng_intrpt_on_cpy_err_en
//     , input                 mmio_eng_stop_on_invalid_cmd
//     , input                 mmio_eng_256B_op_disable
//     , input                 mmio_eng_128B_op_disable
//     , input                 mmio_eng_hold_pasid_for_debug
  , input                 mmio_eng_use_pasid_for_actag
//     , input                 mmio_eng_xtouch_source_enable
//     , input                 mmio_eng_xtouch_dest_enable
//     , input                 mmio_eng_xtouch_wt4rsp_enable
//     , input           [5:0] mmio_eng_xtouch_ageout_pg_size
//     , input                 mmio_eng_immed_terminate_enable
  , input                 mmio_eng_rtry_backoff_timer_disable
  , input                 mmio_eng_memcpy2_format_enable

  , input                 mmio_eng_capture_all_resp_code_enable

//     , input           [1:0] mmio_eng_we_ld_type
//     , input           [3:0] mmio_eng_we_st_type
//     , input           [1:0] mmio_eng_cpy_ld_type
//     , input           [1:0] mmio_eng_cpy_st_type
//     , input           [1:0] mmio_eng_xtouch_type
//     , input           [4:0] mmio_eng_xtouch_flag
//     , input           [1:0] mmio_eng_incr_ld_type
//     , input           [1:0] mmio_eng_incr_st_type
//     , input           [1:0] mmio_eng_atomic_ld_type
//     , input           [1:0] mmio_eng_atomic_cas_type
//     , input           [1:0] mmio_eng_atomic_st_type

//     - New for AFP
  , input         [63:12] mmio_eng_base_addr
  , input         [31:12] mmio_eng_offset_mask
  , input           [1:0] mmio_eng_ld_size
  , input           [1:0] mmio_eng_st_size
  , input                 mmio_eng_type_ld
  , input                 mmio_eng_type_st
  , input                 mmio_eng_send_interrupt
  , input                 mmio_eng_send_wkhstthrd
  , input                 mmio_eng_error_intrpt_enable
  , input                 mmio_eng_wkhstthrd_intrpt_enable
  , input          [15:0] mmio_eng_wkhstthrd_tid
  , input                 mmio_eng_wkhstthrd_flag
  , input                 mmio_eng_extra_write_mode
  , input          [63:0] mmio_eng_obj_handle
  , input           [1:0] mmio_eng_xtouch_pg_n
  , input           [5:0] mmio_eng_xtouch_pg_size
  , input                 mmio_eng_xtouch_type
  , input                 mmio_eng_xtouch_hwt
  , input                 mmio_eng_xtouch_wt4rsp_enable
  , input                 mmio_eng_xtouch_enable
  , input                 mmio_eng_enable
  , input                 mmio_eng_resend_retries
  , input                 mmio_eng_mmio_lat_mode
  , input                 mmio_eng_mmio_lat_mode_sz_512_st
  , input                 mmio_eng_mmio_lat_mode_sz_512_ld
  , input                 mmio_eng_mmio_lat_use_reg_data
  , input                 mmio_eng_mmio_lat_extra_read
  , input          [63:7] mmio_eng_mmio_lat_ld_ea
  , input        [1023:0] mmio_eng_mmio_lat_data0
  , input        [1023:0] mmio_eng_mmio_lat_data1
  , input        [1023:0] mmio_eng_mmio_lat_data2
  , input        [1023:0] mmio_eng_mmio_lat_data3
  , output          [3:0] eng_mmio_extra_read_resp
  , output       [1023:0] eng_mmio_data

 // -- Display Read Interface
//     , input                 weq_eng_display_rdval
  , input                 mmio_eng_display_rdval
  , input           [1:0] mmio_eng_display_ary_select
  , input           [9:0] mmio_eng_display_addr
  , output                eng_mmio_display_rddata_valid

 // -- Performance Counter interface
  , output                eng_perf_wkhstthrd_good

 // -- Debug signal for ILA capture
  , output                unexpected_xlate_or_intrpt_done_200


 // -- Simulation Idle
  , output                sim_idle_eng

  );

  // --****************************************************************************
  // -- Signal declarations
  // --****************************************************************************

  wire      [5:0] eng_num;

  // -- cmd_rand Outputs 
//      wire      [1:0] we_ld_type_sel;               
//      wire      [3:0] we_st_type_sel;               
//      wire      [1:0] cpy_ld_type_sel;              
//      wire      [1:0] cpy_st_type_sel;              
//      wire      [1:0] xtouch_type_sel;              
//      wire      [4:0] xtouch_flag_sel;              
//      wire      [1:0] incr_ld_type_sel;             
//      wire      [1:0] incr_st_type_sel;             
  wire      [1:0] atomic_ld_type_sel;           
  wire      [1:0] atomic_cas_type_sel;          
  wire      [1:0] atomic_st_type_sel;           

  // -- enab cmd terms for use by various sequencers
//      wire     [63:5] cmd_we_ea_q;                  
//      wire     [63:0] cmd_intrpt_obj_q;             
  wire     [31:0] cmd_intrpt_data_q;            
  wire      [1:0] cmd_intrpt_type_q;            
  wire      [9:0] cmd_pasid_q;                  
//     wire     [18:5] cmd_offset_q;                 
//     wire     [11:0] cmd_weq_depth_q;              
//     wire            cmd_we_wrap_q;                

//      wire            eng_enable_q;
//      wire            start_main_seq;

//      wire            eng_pe_terminate_q;
//      wire            immed_terminate_enable_q;

//      wire            my_pasid_dispatched_to_diff_eng;

  // -- main State Machine
  wire      [4:0] main_state;                   
  wire            main_idle_st;                 
  wire            main_actag_st;
  wire            main_send_st;
  wire            main_err_intrpt_st;
  wire            main_stop_st;
//     wire            main_we_ld_st;                
//     wire            main_xtouch_st;               
//     wire            main_cpy_ld_st;               
//     wire            main_cpy_st_st;               
//     wire            main_wkhstthrd_st;            
//     wire            main_incr_st;                 
//     wire            main_atomic_st;               
//     wire            main_intrpt_st;               
//     wire            main_we_st_st;                
//     wire            main_wr_weq_st;               

  wire            start_actag_seq;              
//     wire            start_we_ld_seq;              
//     wire            start_xtouch_seq;             
  wire            start_cpy_ld_seq;             
  wire            start_cpy_st_seq;             
  wire            start_wkhstthrd_seq;          
//     wire            start_incr_seq;               
  wire            start_atomic_seq;             
  wire            start_intrpt_seq;             
//     wire            start_we_st_seq;              
//     wire            start_wr_weq_seq;             

  wire            main_seq_done;                
  wire            main_seq_error;               

  wire     [63:6] cpy_ld_ea_q;
  wire     [63:6] cpy_st_ea_q;
  wire     [63:0] xtouch_ea_q;
  wire            cpy_ld_idle_st;
  wire            cpy_st_idle_st;
  wire            cpy_ld_type_sel;
  wire            cpy_st_type_sel;

  // -- actag State Machine
  wire      [1:0] actag_state;                  
  wire            actag_idle_st;                
  wire            actag_wt4gnt_st;              

  wire            actag_req;                    
  wire            actag_seq_done;               
  wire            actag_seq_error;              

  wire            actag_valid;                  
  wire      [7:0] actag_opcode;                 
  wire     [11:0] actag_actag;                  
  wire      [3:0] actag_stream_id;              
  wire     [67:0] actag_ea_or_obj;              
  wire     [15:0] actag_afutag;                 
  wire      [1:0] actag_dl;                     
  wire      [2:0] actag_pl;                     
  wire            actag_os;                     
  wire     [63:0] actag_be;                     
  wire      [3:0] actag_flag;                   
  wire            actag_endian;                 
  wire     [15:0] actag_bdf;                    
//     wire     [19:0] actag_pasid;                  
  wire      [5:0] actag_pg_size;                

  wire     [11:0] eng_actag;                    

  // -- we_ld State Machine
  wire      [3:0] we_ld_state;                  
  wire            we_ld_idle_st;                
  wire            we_ld_wt4gnt_st;              
  wire            we_ld_wt4rsp_st;              
  wire            we_ld_decode_st;              

//     wire            we_ld_capture_cmd;            
  wire            we_ld_req;         
//     wire            we_ld_seq_done;               
  wire            we_ld_seq_error;              

  wire      [3:0] we_rtry_ld_state;             
  wire            we_rtry_ld_idle_st;           
  wire            we_rtry_ld_wt4bckoff_st;      
  wire            we_rtry_ld_wt4gnt_st;         
  wire            we_rtry_ld_abort_st;          

  wire            we_rtry_ld_req;         
  wire            we_rtry_ld_seq_error;         

  wire            we_ld_valid;                  
  wire      [7:0] we_ld_opcode;                 
  wire     [11:0] we_ld_actag;                  
  wire      [3:0] we_ld_stream_id;              
  wire     [67:0] we_ld_ea_or_obj;              
  wire     [15:0] we_ld_afutag;                 
  wire      [1:0] we_ld_dl;                     
  wire      [2:0] we_ld_pl;                     
  wire            we_ld_os;                     
  wire     [63:0] we_ld_be;                     
  wire      [3:0] we_ld_flag;                   
  wire            we_ld_endian;                 
  wire     [15:0] we_ld_bdf;                    
//     wire     [19:0] we_ld_pasid;                  
  wire      [5:0] we_ld_pg_size;                

  // -- cmd_decode
  wire            memcpy2_format_enable_q;

//     wire            we_cmd_valid_d;
//     wire            we_cmd_valid_q;

//     wire            we_cmd_val_q;
//     wire     [63:0] we_cmd_source_ea_d;           
//     wire     [63:0] we_cmd_source_ea_q;           
//     wire     [63:0] we_cmd_dest_ea_d;             
  wire     [63:0] we_cmd_dest_ea_q;             
  wire     [63:0] we_cmd_atomic_op1_q;          
  wire     [63:0] we_cmd_atomic_op2_q;          
//     wire     [15:0] we_cmd_length_d;              
  wire     [15:0] we_cmd_length_q;              
//     wire      [5:0] we_cmd_encode_q;              
  wire      [7:0] we_cmd_extra_q;               
//     wire            we_cmd_wrap_q;               

//     wire            we_cmd_is_copy_d;             
//     wire            we_cmd_is_copy_q;             
//     wire            we_cmd_is_intrpt_d;           
  wire            we_cmd_is_intrpt_q;           
//     wire            we_cmd_is_stop_d;             
//     wire            we_cmd_is_stop_q;             
//     wire            we_cmd_is_wkhstthrd_d;        
  wire            we_cmd_is_wkhstthrd_q;        
//     wire            we_cmd_is_incr_d;             
//     wire            we_cmd_is_incr_q;             
//     wire            we_cmd_is_atomic_d;           
//     wire            we_cmd_is_atomic_q;           
//     wire            we_cmd_is_atomic_ld_d;        
  wire            we_cmd_is_atomic_ld_q;        
  wire            we_cmd_is_atomic_cas_d;       
  wire            we_cmd_is_atomic_cas_q;       
  wire            we_cmd_is_atomic_st_d;        
  wire            we_cmd_is_atomic_st_q;        
//     wire            we_cmd_is_xtouch_d;           
//     wire            we_cmd_is_xtouch_q;           

//     wire            we_cmd_is_undefined_d;        
//     wire            we_cmd_is_undefined_q;        
//     wire            we_cmd_length_is_zero_d;      
//     wire            we_cmd_length_is_zero_q;
//     wire            we_cmd_cpy_length_lt_64B_d;
//     wire            we_cmd_cpy_length_lt_64B_q;    
//     wire            we_cmd_is_bad_atomic_d;       
//     wire            we_cmd_is_bad_atomic_q;       

  // -- xtouch State Machine
  wire      [3:0] xtouch_state;                 
  wire            xtouch_idle_st;               
  wire            xtouch_wt4gnt1_st;            
  wire            xtouch_wt4gnt2_st;            
  wire            xtouch_wt4rsp_st;             

  wire            xtouch_req;              
  wire            xtouch_seq_done;              
  wire            xtouch_seq_error;             

  wire      [5:0] xtouch_rtry_state;            
  wire            xtouch_rtry_idle_st;          
  wire            xtouch_rtry_wt4bckoff1_st;    
  wire            xtouch_rtry_wt4gnt1_st;       
  wire            xtouch_rtry_wt4bckoff2_st;    
  wire            xtouch_rtry_wt4gnt2_st;       
  wire            xtouch_rtry_abort_st;         

  wire            xtouch_rtry_req;        
  wire            xtouch_rtry_seq_error;        

  wire            xtouch_valid;                 
  wire      [7:0] xtouch_opcode;                
  wire     [11:0] xtouch_actag;                 
  wire      [3:0] xtouch_stream_id;             
  wire     [67:0] xtouch_ea_or_obj;             
  wire     [15:0] xtouch_afutag;                
  wire      [1:0] xtouch_dl;                    
  wire      [2:0] xtouch_pl;                    
  wire            xtouch_os;                    
  wire     [63:0] xtouch_be;                    
  wire      [3:0] xtouch_flag;                  
  wire            xtouch_endian;                
  wire     [15:0] xtouch_bdf;                   
//     wire     [19:0] xtouch_pasid;                 
  wire      [5:0] xtouch_pg_size;

//     wire            xtouch_enable_q;
  wire            xtouch_wt4rsp_enable_q;              

  // -- cpy_ld State Machine
//     wire      [3:0] cpy_ld_state;                 
//     wire            cpy_ld_req_st;                
//     wire            cpy_ld_wt4gnt_st;             
  wire            cpy_ld_wt4rsp_st;             

//     wire            cpy_ld_req;            
//     wire            cpy_ld_seq_done;            
//     wire            cpy_ld_seq_error;             

  wire      [3:0] cpy_rtry_ld_state;            
  wire            cpy_rtry_ld_idle_st;          
  wire            cpy_rtry_ld_wt4bckoff_st;     
  wire            cpy_rtry_ld_wt4gnt_st;        
  wire            cpy_rtry_ld_abort_st;         

//     wire            cpy_rtry_ld_req;        
  wire            cpy_rtry_ld_seq_error;        

  wire            cpy_ld_valid;                 
  wire      [7:0] cpy_ld_opcode;                
  wire     [11:0] cpy_ld_actag;                 
  wire      [3:0] cpy_ld_stream_id;             
  wire     [67:0] cpy_ld_ea_or_obj;             
  wire     [15:0] cpy_ld_afutag;                
  wire      [1:0] cpy_ld_dl;                    
  wire      [2:0] cpy_ld_pl;                    
  wire            cpy_ld_os;                    
  wire     [63:0] cpy_ld_be;                    
  wire      [3:0] cpy_ld_flag;                  
  wire            cpy_ld_endian;                
  wire     [15:0] cpy_ld_bdf;                   
//     wire     [19:0] cpy_ld_pasid;                 
  wire      [5:0] cpy_ld_pg_size;

//     wire      [8:6] cpy_ld_size_q;
//     wire      [4:0] cpy_ld_afutag_q;            

  // -- cpy_scorecard
  wire            cpy_cmd_resp_rcvd_overlap;    
  wire            cpy_cmd_resp_rcvd_mismatch;   

  //    wire     [31:0] cpy_cmd_sent_q;               
  //    wire     [31:0] cpy_cmd_resp_rcvd_q;          

  // -- cpy_st State Machine
//     wire      [3:0] cpy_st_state;                 
//     wire            cpy_st_req_st;                
//     wire            cpy_st_wt4gnt_st;             
  wire            cpy_st_wt4rsp_st;             

//     wire            cpy_st_req;                   
//     wire            cpy_st_seq_done;            
//     wire            cpy_st_seq_error;             

  wire      [4:0] cpy_rtry_st_state;            
  wire            cpy_rtry_st_idle_st;          
  wire            cpy_rtry_st_wt4bckoff_st;     
  wire            cpy_rtry_st_req_st;           
  wire            cpy_rtry_st_wt4gnt_st;        
  wire            cpy_rtry_st_abort_st;
       
  wire            cpy_rtry_st_req;              
  wire            cpy_rtry_st_seq_error;        

  wire            cpy_st_valid;                 
  wire      [7:0] cpy_st_opcode;                
  wire     [11:0] cpy_st_actag;                 
  wire      [3:0] cpy_st_stream_id;             
  wire     [67:0] cpy_st_ea_or_obj;             
  wire     [15:0] cpy_st_afutag;                
  wire      [1:0] cpy_st_dl;                    
  wire      [2:0] cpy_st_pl;                    
  wire            cpy_st_os;                    
  wire     [63:0] cpy_st_be;                    
  wire      [3:0] cpy_st_flag;                  
  wire            cpy_st_endian;                
  wire     [15:0] cpy_st_bdf;                   
//     wire     [19:0] cpy_st_pasid;                 
  wire      [5:0] cpy_st_pg_size;

//     wire      [4:0] cpy_st_afutag_d;              
//     wire      [4:0] cpy_st_afutag_q;              
//     wire      [1:0] cpy_st_size_encoded_d;                        
  wire            cpy_st_size_256_q;

  // -- wkhstthrd State Machine
  wire      [2:0] wkhstthrd_state;              
  wire            wkhstthrd_idle_st;            
  wire            wkhstthrd_wt4gnt_st;          
  wire            wkhstthrd_wt4rsp_st;          

  wire            wkhstthrd_req;                
  wire            wkhstthrd_seq_done;           
  wire            wkhstthrd_seq_error;          

  wire      [3:0] wkhstthrd_rtry_state;         
  wire            wkhstthrd_rtry_idle_st;       
  wire            wkhstthrd_rtry_wt4bckoff_st;  
  wire            wkhstthrd_rtry_wt4gnt_st;     
  wire            wkhstthrd_rtry_abort_st;      

  wire            wkhstthrd_rtry_req;           
  wire            wkhstthrd_rtry_seq_error;     

  wire            wkhstthrd_valid;              
  wire      [7:0] wkhstthrd_opcode;             
  wire     [11:0] wkhstthrd_actag;              
  wire      [3:0] wkhstthrd_stream_id;          
  wire     [67:0] wkhstthrd_ea_or_obj;          
  wire     [15:0] wkhstthrd_afutag;             
  wire      [1:0] wkhstthrd_dl;                 
  wire      [2:0] wkhstthrd_pl;                 
  wire            wkhstthrd_os;                 
  wire     [63:0] wkhstthrd_be;                 
  wire      [3:0] wkhstthrd_flag;               
  wire            wkhstthrd_endian;             
  wire     [15:0] wkhstthrd_bdf;                
//     wire     [19:0] wkhstthrd_pasid;              
  wire      [5:0] wkhstthrd_pg_size;            

  // -- incr State Machine
  wire      [4:0] incr_state;
  wire            incr_idle_st;                 
  wire            incr_wt4ldgnt_st;             
  wire            incr_wt4ldrsp_st;             
  wire            incr_wt4stgnt_st;             
  wire            incr_wt4strsp_st;             

  wire            incr_ld_req;                  
  wire            incr_st_req;                  
  wire            incr_seq_done;                
  wire            incr_seq_error;

  wire      [5:0] incr_rtry_state;
  wire            incr_rtry_idle_st;            
  wire            incr_rtry_wt4ldbckoff_st;     
  wire            incr_rtry_wt4ldgnt_st;        
  wire            incr_rtry_wt4stbckoff_st;     
  wire            incr_rtry_wt4stgnt_st;        
  wire            incr_rtry_abort_st;           

  wire            incr_rtry_ld_req;             
  wire            incr_rtry_st_req;             
  wire            incr_rtry_seq_error;          

  wire            incr_ld_valid;                
  wire      [7:0] incr_ld_opcode;               
  wire     [11:0] incr_ld_actag;                
  wire      [3:0] incr_ld_stream_id;            
  wire     [67:0] incr_ld_ea_or_obj;            
  wire     [15:0] incr_ld_afutag;               
  wire      [1:0] incr_ld_dl;                   
  wire      [2:0] incr_ld_pl;                   
  wire            incr_ld_os;                   
  wire     [63:0] incr_ld_be;                   
  wire      [3:0] incr_ld_flag;                 
  wire            incr_ld_endian;               
  wire     [15:0] incr_ld_bdf;                  
//     wire     [19:0] incr_ld_pasid;                
  wire      [5:0] incr_ld_pg_size;              

  wire            incr_st_valid;                
  wire      [7:0] incr_st_opcode;               
  wire     [11:0] incr_st_actag;                
  wire      [3:0] incr_st_stream_id;            
  wire     [67:0] incr_st_ea_or_obj;            
  wire     [15:0] incr_st_afutag;               
  wire      [1:0] incr_st_dl;                   
  wire      [2:0] incr_st_pl;                   
  wire            incr_st_os;                   
  wire     [63:0] incr_st_be;                   
  wire      [3:0] incr_st_flag;                 
  wire            incr_st_endian;               
  wire     [15:0] incr_st_bdf;                  
//     wire     [19:0] incr_st_pasid;                
  wire      [5:0] incr_st_pg_size;              

  wire    [511:0] incr_st_data;                 

  // -- atomic State Machine
  wire      [3:0] atomic_state;                 
  wire            atomic_idle_st;               
  wire            atomic_wt4gnt_st;             
  wire            atomic_wt4rsp_st;             
  wire            atomic_compare_st;            

  wire            atomic_req;                   
  wire            atomic_req_w_data;            
  wire            atomic_seq_done;              
  wire            atomic_seq_error;             

  wire      [3:0] atomic_rtry_state;            
  wire            atomic_rtry_idle_st;          
  wire            atomic_rtry_wt4bckoff_st;     
  wire            atomic_rtry_wt4gnt_st;        
  wire            atomic_rtry_abort_st;         

  wire            atomic_rtry_req;              
  wire            atomic_rtry_req_w_data;       
  wire            atomic_rtry_seq_error;        

  wire            atomic_valid;                 
  wire      [7:0] atomic_opcode;                
  wire     [11:0] atomic_actag;                 
  wire      [3:0] atomic_stream_id;             
  wire     [67:0] atomic_ea_or_obj;             
  wire     [15:0] atomic_afutag;                
  wire      [1:0] atomic_dl;                    
  wire      [2:0] atomic_pl;                    
  wire            atomic_os;                    
  wire     [63:0] atomic_be;                    
  wire      [3:0] atomic_flag;                  
  wire            atomic_endian;                
  wire     [15:0] atomic_bdf;                   
//     wire     [19:0] atomic_pasid;                 
  wire      [5:0] atomic_pg_size;               

  wire            atomic_data_valid;            
  wire    [511:0] atomic_data;                  

  wire            atomic_cas_failure_q;         

  // -- intrpt State Machine
  wire      [2:0] intrpt_state;                 
  wire            intrpt_idle_st;               
  wire            intrpt_wt4gnt_st;             
  wire            intrpt_wt4rsp_st;             

  wire            intrpt_req;                   
  wire            intrpt_req_w_data;            
  wire            intrpt_seq_done;              
  wire            intrpt_seq_error;             

  wire      [3:0] intrpt_rtry_state;            
  wire            intrpt_rtry_idle_st;          
  wire            intrpt_rtry_wt4bckoff_st;     
  wire            intrpt_rtry_wt4gnt_st;        
  wire            intrpt_rtry_abort_st;         

  wire            intrpt_rtry_req;              
  wire            intrpt_rtry_req_w_data;       
  wire            intrpt_rtry_seq_error;        

  wire            intrpt_valid;                 
  wire      [7:0] intrpt_opcode;                
  wire     [11:0] intrpt_actag;                 
  wire      [3:0] intrpt_stream_id;             
  wire     [67:0] intrpt_ea_or_obj;             
  wire     [15:0] intrpt_afutag;                
  wire      [1:0] intrpt_dl;                    
  wire      [2:0] intrpt_pl;                    
  wire            intrpt_os;                    
  wire     [63:0] intrpt_be;                    
  wire      [3:0] intrpt_flag;                  
  wire            intrpt_endian;                
  wire     [15:0] intrpt_bdf;                   
//     wire     [19:0] intrpt_pasid;                 
  wire      [5:0] intrpt_pg_size;               

  wire            intrpt_data_valid;            
  wire    [511:0] intrpt_data;                  

  wire            intrpt_sent_q;                

  // -- we_st State Machine
   wire      [2:0] we_st_state;                  
   wire            we_st_idle_st;                
   wire            we_st_wt4gnt_st;              
   wire            we_st_wt4rsp_st;              

   wire            we_st_req;                    
   wire            we_st_seq_done;               
   wire            we_st_seq_error;              

   wire      [3:0] we_rtry_st_state;             
   wire            we_rtry_st_idle_st;           
   wire            we_rtry_st_wt4bckoff_st;      
   wire            we_rtry_st_wt4gnt_st;         
   wire            we_rtry_st_abort_st;          

   wire            we_rtry_st_req;               
   wire            we_rtry_st_seq_error;         

   wire            we_st_valid;                  
   wire      [7:0] we_st_opcode;                 
   wire     [11:0] we_st_actag;                  
   wire      [3:0] we_st_stream_id;              
   wire     [67:0] we_st_ea_or_obj;              
   wire     [15:0] we_st_afutag;                 
   wire      [1:0] we_st_dl;                     
   wire      [2:0] we_st_pl;                     
   wire            we_st_os;                     
   wire     [63:0] we_st_be;                     
   wire      [3:0] we_st_flag;                   
   wire            we_st_endian;                 
   wire     [15:0] we_st_bdf;                    
//      wire     [19:0] we_st_pasid;                  
   wire      [5:0] we_st_pg_size;                

   wire    [511:0] we_st_data;                   

  // -- wr_weq State Machine
  wire      [1:0] wr_weq_state;               
  wire            wr_weq_idle_st;               
  wire            wr_weq_wt4gnt_st;             

  wire            wr_weq_seq_done;              
  wire            wr_weq_seq_error;             

  wire     [18:5] wr_weq_next_offset;           
  wire            wr_weq_next_wrap;             

  // -- resp_decode
  wire            rspi_resp_is_we_ld_rtry_w_backoff_q;
  wire            rspi_resp_is_xtouch_source_rtry_w_backoff_q;
  wire            rspi_resp_is_xtouch_dest_rtry_w_backoff_q;
  wire            rspi_resp_is_cpy_ld_rtry_w_backoff_q;
  wire            rspi_resp_is_cpy_st_rtry_w_backoff_q;
  wire            rspi_resp_is_wkhstthrd_rtry_w_backoff_q;
  wire            rspi_resp_is_incr_rtry_w_backoff_q;
  wire            rspi_resp_is_atomic_rtry_w_backoff_q;
  wire            rspi_resp_is_intrpt_rtry_w_backoff_q;
  wire            rspi_resp_is_we_st_rtry_w_backoff_q;

  wire            rspi_resp_is_rtry_req;        
  wire            rspi_resp_is_rtry_lwt;        

  wire            rspi_resp_is_rtry;            
  wire            rspi_resp_is_xtouch_rtry;     

  wire            rcvd_touch_resp_when_not_expected;
  wire            rcvd_touch_resp_w_bad_afutag; 
  wire            rcvd_unexpected_resp_w_xtouch_afutag;

  wire            rcvd_ld_resp_when_not_expected;
  wire            rcvd_ld_resp_w_bad_afutag;    
  wire            rcvd_unexpected_resp_w_ld_afutag;

  wire            rcvd_st_resp_when_not_expected;
  wire            rcvd_st_resp_w_bad_afutag;    
  wire            rcvd_unexpected_resp_w_st_afutag;

  wire            rcvd_wake_host_resp_when_not_expected;
  wire            rcvd_wake_host_resp_w_bad_afutag;
  wire            rcvd_unexpected_resp_w_wkhstthrd_afutag;

  wire            rcvd_intrp_resp_when_not_expected;
  wire            rcvd_intrp_resp_w_bad_afutag; 
  wire            rcvd_unexpected_resp_w_intrpt_afutag;

  wire            undefined_rspi_we_ld_afutag;  
  wire            undefined_rspi_xtouch_afutag; 
  wire            undefined_rspi_cpy_afutag;    
  wire            undefined_rspi_wkhstthrd_afutag;
  wire            undefined_rspi_incr_afutag;   
  wire            undefined_rspi_atomic_afutag; 
  wire            undefined_rspi_intrpt_afutag; 

  wire            undefined_cmdo_we_ld_afutag;  
  wire            undefined_cmdo_xtouch_afutag; 
  wire            undefined_cmdo_cpy_afutag;    
  wire            undefined_cmdo_wkhstthrd_afutag;
  wire            undefined_cmdo_incr_afutag;   
  wire            undefined_cmdo_atomic_afutag; 
  wire            undefined_cmdo_intrpt_afutag; 

  wire            rspi_we_ld_resp_val_q;        
  wire            rspi_xtouch_source_resp_val_q;
  wire            rspi_xtouch_dest_resp_val_q;  
  wire            rspi_cpy_ld_resp_val_q;       
  wire            rspi_cpy_st_resp_val_q;       
  wire            rspi_incr_ld_resp_val_q;      
  wire            rspi_incr_st_resp_val_q;      
  wire            rspi_atomic_ld_resp_val_q;    
  wire            rspi_atomic_st_resp_val_q;    
  wire            rspi_atomic_cas_resp_val_d;   
  wire            rspi_wkhstthrd_resp_val_q;    
  wire            rspi_intrpt_resp_val_q;       
  wire            rspi_we_st_resp_val_q;        

  wire      [4:0] pending_cnt_q;

  wire            rspi_resp_is_pending_q;
  wire            rspi_resp_is_rtry_hwt_q;
  wire            rspi_resp_is_rtry_req_q;
  wire            rspi_resp_is_rtry_lwt_q;           

  wire            rspi_resp_fault_q;            
  wire            rspi_resp_failed_q;           
  wire            rspi_resp_aerror_q;           
  wire            rspi_resp_derror_q;           

  wire            we_ld_error_q;                // Note: Unused on AFP3
  wire            xtouch_source_error_q;        
  wire            xtouch_dest_error_q;          
  wire            cpy_ld_error_q;               
  wire            cpy_st_error_q;               
  wire            wkhstthrd_error_q;            
  wire            incr_ld_error_q;              
  wire            incr_st_error_q;              
  wire            atomic_ld_error_q;            
  wire            atomic_st_error_q;            
  wire            atomic_cas_error_q;           
  wire            intrpt_cmd_error_q;           
  wire            intrpt_err_error_q;           
  wire            intrpt_wht_error_q;           
  wire            we_st_error_q;                

  wire            xtouch_error_q;               
  wire            cpy_error_q;                  
  wire            incr_error_q;                 
  wire            atomic_error_q;               
  wire            intrpt_error_q;               

  wire            error_q;                      

  wire            rspi_resp_is_cpy_xx_q;
  wire            rspi_resp_is_cpy_st_q;
  wire      [8:0] rspi_resp_afutag_q;           
  wire      [7:0] rspi_resp_opcode_q;           
  wire      [3:0] rspi_resp_code_q;             
  wire      [1:0] rspi_resp_dl_orig_q;          
  wire      [1:0] rspi_resp_dl_q;               
  wire      [1:0] rspi_resp_dp_q;               

  wire      [0:0] rspi_resp_afutag_dbuf_q;           
  wire      [1:0] rspi_resp_dl_dbuf_q;               

  wire   [1023:0] rspi_resp_data_q;             
  wire      [1:0] rspi_resp_data_bdi_q;         
  wire            rspi_resp_data_valid_q;       
  wire            rspi_resp_data_valid_xfer2_q; 

  // -- rtry_queue
  wire            rtry_queue_empty;
  wire            rtry_queue_func_rden_dly2_q;
  wire            rtry_queue_cpy_xx_q;          
  wire            rtry_queue_cpy_st_q;          
  wire      [8:0] rtry_queue_afutag_q;          
  wire      [1:0] rtry_queue_dl_q;              
  wire            rtry_queue_is_pending_q;      
  wire            rtry_queue_is_rtry_lwt_q;     
  wire            rtry_queue_is_rtry_req_q;     
  wire            rtry_queue_is_rtry_hwt_q;     

  wire            resp_code_is_done;            
  wire            resp_code_is_rty_req;         
  wire            resp_code_is_failed;          
  wire            resp_code_is_adr_error;       

//     wire      [4:0] cpy_rtry_xx_afutag_d;         
  wire      [8:0] cpy_rtry_xx_afutag_q;         
  wire      [1:0] cpy_rtry_xx_dl_q;             
  wire            cpy_rtry_st_size_256_q;           
//     wire     [63:6] cpy_rtry_ld_ea_q;             
//     wire     [63:6] cpy_rtry_st_ea_q;

  wire     [10:0] rtry_queue_rdaddr_q;
  wire     [10:0] rtry_queue_wraddr_q;
  wire     [17:0] rtry_queue_rddata;
  wire      [3:0] resp_code_rddata;                    

  // -- rtry_timer
  wire            we_rtry_ld_backoff_done;    
  wire            xtouch_rtry_source_backoff_done;
  wire            xtouch_rtry_dest_backoff_done;
  wire            cpy_rtry_ld_backoff_done;   
  wire            cpy_rtry_st_backoff_done;   
  wire            wkhstthrd_rtry_backoff_done;
  wire            incr_rtry_backoff_done;     
  wire            atomic_rtry_backoff_done;   
  wire            intrpt_rtry_backoff_done;   
  wire            we_rtry_st_backoff_done;    

  wire            rtry_backoff_timer_disable_q;
  wire            we_rtry_ld_backoff_done_q;    
  wire            xtouch_rtry_source_backoff_done_q;
  wire            xtouch_rtry_dest_backoff_done_q;
  wire            cpy_rtry_ld_backoff_done_q;   
  wire            cpy_rtry_st_backoff_done_q;   
  wire            wkhstthrd_rtry_backoff_done_q;
  wire            incr_rtry_backoff_done_q;     
  wire            atomic_rtry_backoff_done_q;   
  wire            intrpt_rtry_backoff_done_q;   
  wire            we_rtry_st_backoff_done_q;    

  // -- rtry_decode
  wire            start_we_rtry_ld_seq;         
  wire            start_xtouch_rtry_source_seq; 
  wire            start_xtouch_rtry_dest_seq;   
  wire            start_cpy_rtry_ld_seq;        
  wire            start_cpy_rtry_st_seq;        
  wire            start_wkhstthrd_rtry_seq;     
  wire            start_incr_rtry_ld_seq;       
  wire            start_incr_rtry_st_seq;       
  wire            start_atomic_rtry_seq;        
  wire            start_intrpt_rtry_seq;        
  wire            start_we_rtry_st_seq;         

  wire            rtry_decode_is_hwt;           
  wire            rtry_decode_is_immediate;     
  wire            rtry_decode_is_backoff;       
  wire            rtry_decode_is_abort;         

  // -- cmd_out
//wire            eng_cmdo_valid;               
//wire      [7:0] eng_cmdo_opcode;              
//wire     [11:0] eng_cmdo_actag;               
//wire      [3:0] eng_cmdo_stream_id;           
//wire     [67:0] eng_cmdo_ea_or_obj;           
//wire     [15:0] eng_cmdo_afutag;              
//wire      [1:0] eng_cmdo_dl;                  
//wire      [2:0] eng_cmdo_pl;                  
//wire            eng_cmdo_os;                  
//wire     [63:0] eng_cmdo_be;                  
//wire      [3:0] eng_cmdo_flag;                
//wire            eng_cmdo_endian;              
//wire     [15:0] eng_cmdo_bdf;                 
//wire     [19:0] eng_cmdo_pasid;               
//wire      [5:0] eng_cmdo_pg_size;             

//wire            eng_cmdo_st_valid;            
//wire   [1023:0] eng_cmdo_st_data;

  wire            cmdo_valid;
  wire     [15:0] cmdo_afutag;             

  // -- display
  wire            eng_display_idle_st;          
  wire            eng_display_wait_st;          
  wire            eng_display_req_st;           
  wire            eng_display_wt4gnt_st;        
  wire            eng_display_rddataval_st;     

  wire            eng_display_req;              
//wire            eng_mmio_display_rddata_valid;

  wire            eng_display_dbuf_rden;        
  wire            eng_display_dbuf_rden_dly1;   
//     wire      [1:0] eng_display_ary_select_q;     
  wire      [9:0] eng_display_addr_q;           
//     wire      [8:6] eng_display_size;
  wire     [63:0] eng_display_data;           

  // -- For use with immediate terminate
//     wire            num_cmds_sent_eq_resp_rcvd;

//     assign          num_cmds_sent_eq_resp_rcvd =  1'b0;  // -- Temporary until immed terminate implemented


  // -- Sim only hook to disable bugspray events on the one-hot sequencer checks
  wire            disable_seq_error_bugspray;

  assign          disable_seq_error_bugspray = 1'b0;  // -- Default to enabled, Sim can stick to 1'b1 to disable


  // --****************************************************************************
  // -- Latch Signal declarations (including enable signals)
  // --****************************************************************************

  // -- inbound grant latches
  reg             arb_ld_gnt_d;
  reg             arb_ld_gnt_q;
  reg             arb_st_gnt_d;
  reg             arb_st_gnt_q;
  reg             arb_misc_gnt_d;
  reg             arb_misc_gnt_q;
  reg             arb_rtry_st_gnt_d;
  reg             arb_rtry_st_gnt_q;
  reg             arb_rtry_ld_gnt_d;
  reg             arb_rtry_ld_gnt_q;
  reg             arb_rtry_misc_gnt_d;
  reg             arb_rtry_misc_gnt_q;


  // --****************************************************************************
  // -- Constant declarations
  // --****************************************************************************

  // -- TLX AP command encodes
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC              = 8'b00010000;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC_S            = 8'b00010001;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC_N            = 8'b00010100;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC_N_S          = 8'b00010101;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_PR_RD_WNITC           = 8'b00010010;  // -- Partial Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_PR_RD_WNITC_S         = 8'b00010011;  // -- Partial Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_PR_RD_WNITC_N         = 8'b00010110;  // -- Partial Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_PR_RD_WNITC_N_S       = 8'b00010111;  // -- Partial Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W                 = 8'b00100000;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_S               = 8'b00100001;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_P               = 8'b00100010;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_P_S             = 8'b00100011;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_N               = 8'b00100100;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_N_S             = 8'b00100101;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_N_P             = 8'b00100110;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_N_P_S           = 8'b00100111;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE              = 8'b00101000;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_S            = 8'b00101001;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_P            = 8'b00101010;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_P_S          = 8'b00101011;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_N            = 8'b00101100;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_N_S          = 8'b00101101;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_N_P          = 8'b00101110;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_N_P_S        = 8'b00101111;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W              = 8'b00110000;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_S            = 8'b00110001;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_P            = 8'b00110010;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_P_S          = 8'b00110011;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_N            = 8'b00110100;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_N_S          = 8'b00110101;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_N_P          = 8'b00110110;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_N_P_S        = 8'b00110111;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD                = 8'b00111000;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD_S              = 8'b00111001;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD_N              = 8'b00111100;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD_N_S            = 8'b00111101;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW                = 8'b01000000;  // -- Atomic Memory Operation - Read Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW_S              = 8'b01000001;  // -- Atomic Memory Operation - Read Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW_N              = 8'b01000100;  // -- Atomic Memory Operation - Read Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW_N_S            = 8'b01000101;  // -- Atomic Memory Operation - Read Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W                 = 8'b01001000;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_S               = 8'b01001001;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_P               = 8'b01001010;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_P_S             = 8'b01001011;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_N               = 8'b01001100;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_N_S             = 8'b01001101;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_N_P             = 8'b01001110;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_N_P_S           = 8'b01001111;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_ASSIGN_ACTAG          = 8'b01010000;  // -- Assign acTag
  localparam    [7:0] AFU_TLX_CMD_ENCODE_ADR_TAG_RELEASE       = 8'b01010001;  // -- Address Tag Release
  localparam    [7:0] AFU_TLX_CMD_ENCODE_MEM_PA_FLUSH          = 8'b01010010;  // -- Flush host system by PA
  localparam    [7:0] AFU_TLX_CMD_ENCODE_CASTOUT               = 8'b01010101;  // -- Cast out
  localparam    [7:0] AFU_TLX_CMD_ENCODE_CASTOUT_PUSH          = 8'b01010110;  // -- Cast out with data push
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ             = 8'b01011000;  // -- Interrupt Request
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ_S           = 8'b01011001;  // -- Interrupt Request
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ_D           = 8'b01011010;  // -- Interrupt Request
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ_D_S         = 8'b01011011;  // -- Interrupt Request
  localparam    [7:0] AFU_TLX_CMD_ENCODE_WAKE_HOST_THREAD      = 8'b01011100;  // -- Wake Host Thread
  localparam    [7:0] AFU_TLX_CMD_ENCODE_WAKE_HOST_THREAD_S    = 8'b01011101;  // -- Wake Host Thread
  localparam    [7:0] AFU_TLX_CMD_ENCODE_UPGRADE_STATE         = 8'b01100000;  // -- Upgrade State
  localparam    [7:0] AFU_TLX_CMD_ENCODE_READ_EXCLUSIVE        = 8'b01101000;  // -- Read Exclusive
  localparam    [7:0] AFU_TLX_CMD_ENCODE_READ_SHARED           = 8'b01101001;  // -- Read Shared
  localparam    [7:0] AFU_TLX_CMD_ENCODE_XLATE_TOUCH           = 8'b01111000;  // -- Address translation prefetch
  localparam    [7:0] AFU_TLX_CMD_ENCODE_XLATE_TOUCH_N         = 8'b01111001;  // -- Address translation prefetch
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC_T            = 8'b10010000;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC_T_S          = 8'b10010001;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC_T_N          = 8'b10010100;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC_T_N_S        = 8'b10010101;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_PR_RD_WNITC_T         = 8'b10010010;  // -- Partial Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_PR_RD_WNITC_T_S       = 8'b10010011;  // -- Partial Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_PR_RD_WNITC_T_N       = 8'b10010110;  // -- Partial Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_PR_RD_WNITC_T_N_S     = 8'b10010111;  // -- Partial Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_T               = 8'b10100000;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_T_S             = 8'b10100001;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_T_P             = 8'b10100010;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_T_P_S           = 8'b10100011;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_T_N             = 8'b10100100;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_T_N_S           = 8'b10100101;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_T_N_P           = 8'b10100110;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_T_N_P_S         = 8'b10100111;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_T            = 8'b10101000;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_T_S          = 8'b10101001;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_T_P          = 8'b10101010;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_T_P_S        = 8'b10101011;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_T_N          = 8'b10101100;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_T_N_S        = 8'b10101101;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_T_N_P        = 8'b10101110;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_T_N_P_S      = 8'b10101111;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_T            = 8'b10110000;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_T_S          = 8'b10110001;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_T_P          = 8'b10110010;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_T_P_S        = 8'b10110011;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_T_N          = 8'b10110100;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_T_N_S        = 8'b10110101;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_T_N_P        = 8'b10110110;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_T_N_P_S      = 8'b10110111;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD_T              = 8'b10111000;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD_T_S            = 8'b10111001;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD_T_N            = 8'b10111100;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD_T_N_S          = 8'b10111101;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW_T              = 8'b11000000;  // -- Atomic Memory Operation - Read Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW_T_S            = 8'b11000001;  // -- Atomic Memory Operation - Read Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW_T_N            = 8'b11000100;  // -- Atomic Memory Operation - Read Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW_T_N_S          = 8'b11000101;  // -- Atomic Memory Operation - Read Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_T               = 8'b11001000;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_T_S             = 8'b11001001;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_T_P             = 8'b11001010;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_T_P_S           = 8'b11001011;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_T_N             = 8'b11001100;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_T_N_S           = 8'b11001101;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_T_N_P           = 8'b11001110;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_T_N_P_S         = 8'b11001111;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_UPGRADE_STATE_T       = 8'b11100000;  // -- Upgrade State
  localparam    [7:0] AFU_TLX_CMD_ENCODE_READ_EXCLUSIVE_T      = 8'b11101000;  // -- Read Exclusive
  localparam    [7:0] AFU_TLX_CMD_ENCODE_READ_SHARED_T         = 8'b11101001;  // -- Read Shared

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
  localparam    [3:0] TLX_AFU_RESP_CODE_THREAD_NOT_FOUND       = 4'b0100;      // -- Machine Check
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
  // -- Mode/Config Bit Repower Latches
  // -- ********************************************************************************************************************************

  // -- Mode bits / config from mmio reg
//   -unused  assign  xtouch_enable_d         = ( mmio_eng_xtouch_source_enable || mmio_eng_xtouch_dest_enable );
//   -unused  assign  memcpy2_format_enable_d =   mmio_eng_memcpy2_format_enable;

  assign eng_num = 6'b0;

  // -- ********************************************************************************************************************************
  // -- Support for randomization of command types
  // -- ********************************************************************************************************************************

 //     - TEMP HACK
 assign  atomic_ld_type_sel[1:0] = 2'b0;
 assign  atomic_cas_type_sel[1:0] = 2'b0;
 assign  atomic_st_type_sel[1:0] = 2'b0;

/*    
  mcp3_cpeng_cmd_rand   cmd_rand
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs
      .mmio_eng_we_ld_type                         ( mmio_eng_we_ld_type[1:0] ),
      .mmio_eng_we_st_type                         ( mmio_eng_we_st_type[3:0] ),
      .mmio_eng_cpy_ld_type                        ( mmio_eng_cpy_ld_type[1:0] ),
      .mmio_eng_cpy_st_type                        ( mmio_eng_cpy_st_type[1:0] ),
      .mmio_eng_xtouch_type                        ( mmio_eng_xtouch_type[1:0] ),
      .mmio_eng_xtouch_flag                        ( mmio_eng_xtouch_flag[4:0] ),
      .mmio_eng_incr_ld_type                       ( mmio_eng_incr_ld_type[1:0] ),
      .mmio_eng_incr_st_type                       ( mmio_eng_incr_st_type[1:0] ),
      .mmio_eng_atomic_ld_type                     ( mmio_eng_atomic_ld_type[1:0] ),
      .mmio_eng_atomic_cas_type                    ( mmio_eng_atomic_cas_type[1:0] ),
      .mmio_eng_atomic_st_type                     ( mmio_eng_atomic_st_type[1:0] ),

      // -- State Inputs - Used to preserve same cmd type for retry
      .xtouch_idle_st                              ( xtouch_idle_st ),

      // -- Random Command Select Outpus
      .we_ld_type_sel                              ( we_ld_type_sel[1:0] ),
      .we_st_type_sel                              ( we_st_type_sel[3:0] ),
      .cpy_ld_type_sel                             ( cpy_ld_type_sel[1:0] ),
      .cpy_st_type_sel                             ( cpy_st_type_sel[1:0] ),
      .xtouch_type_sel                             ( xtouch_type_sel[1:0] ),
      .xtouch_flag_sel                             ( xtouch_flag_sel[4:0] ),
      .incr_ld_type_sel                            ( incr_ld_type_sel[1:0] ),
      .incr_st_type_sel                            ( incr_st_type_sel[1:0] ),
      .atomic_ld_type_sel                          ( atomic_ld_type_sel[1:0] ),
      .atomic_cas_type_sel                         ( atomic_cas_type_sel[1:0] ),
      .atomic_st_type_sel                          ( atomic_st_type_sel[1:0] )

    );
*/
  // -- ********************************************************************************************************************************
  // -- Inbound engine enablement from WEQ
  // -- ********************************************************************************************************************************
//      Temp hack
//assign cmd_intrpt_obj_q  = 64'b0;
assign cmd_intrpt_data_q = 32'b0;
assign cmd_intrpt_type_q =  2'b0;
//assign cmd_we_wrap_q  = 1'b0;

/*
  mcp3_cpeng_enab  enab
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // -- Modes/Config & Misc Inputs
      .mmio_eng_hold_pasid_for_debug               ( mmio_eng_hold_pasid_for_debug ),                
      .mmio_eng_immed_terminate_enable             ( mmio_eng_immed_terminate_enable ),

      // -- Sequencer Inputs
      .main_idle_st                                ( main_idle_st ),                                 
      .main_seq_done                               ( main_seq_done ),                                
      .wr_weq_seq_done                             ( wr_weq_seq_done ),                              

      // -- Engine Enablement signals ( 3 cycles of info piped over the wed bus )
      .weq_eng_any_enable                          ( weq_eng_any_enable ),                           
      .weq_eng_enable                              ( weq_eng_enable ),                               
      .weq_eng_pasid                               ( weq_eng_pasid[19:0] ),                          
      .weq_eng_wed                                 ( weq_eng_wed[63:0] ),                            
      .weq_eng_offset                              ( weq_eng_offset[18:5] ),                         
      .weq_eng_we_wrap                             ( weq_eng_we_wrap ),                              

      // -- Terminate Engine Queury
      .weq_eng_pe_terminate                        ( weq_eng_pe_terminate ),                         
      .eng_weq_pe_ack                              ( eng_weq_pe_ack ),                               

      // -- Feedback from wr_weq logic to update existing latches
      .wr_weq_next_offset                          ( wr_weq_next_offset[18:5] ),                     
      .wr_weq_next_wrap                            ( wr_weq_next_wrap ),                             
      .weq_eng_we_gnt                              ( weq_eng_we_gnt ),                               

      // -- Output to start main sequencer
      .eng_enable_q                                ( eng_enable_q ),
      .start_main_seq                              ( start_main_seq ),

      // -- Outputs for use by we_ld and we_st sequencers
      .cmd_we_ea_q                                 ( cmd_we_ea_q[63:5] ),                            

      // -- Outputs for use by interrupt sequencers
      .cmd_intrpt_obj_q                            ( cmd_intrpt_obj_q[63:0] ),                       
      .cmd_intrpt_data_q                           ( cmd_intrpt_data_q[31:0] ),                      
      .cmd_intrpt_type_q                           ( cmd_intrpt_type_q[1:0] ),                       

      // -- Outputs for use by all sequencers
      .cmd_pasid_q                                 ( cmd_pasid_q[19:0] ),
      .eng_pe_terminate_q                          ( eng_pe_terminate_q ),
      .immed_terminate_enable_q                    ( immed_terminate_enable_q ),                           

      // -- Outputs to wr_weq sequencer - used to caculate next offset and wrap
      .cmd_offset_q                                ( cmd_offset_q[18:5] ),                           
      .cmd_weq_depth_q                             ( cmd_weq_depth_q[11:0] ),                        
      .cmd_we_wrap_q                               ( cmd_we_wrap_q ),                                

      // -- Output to WEQ when engine done
      .eng_weq_done                                ( eng_weq_done ),

      // -- Error Detection
      .my_pasid_dispatched_to_diff_eng             ( my_pasid_dispatched_to_diff_eng )

    );                                 
*/

  // -- ********************************************************************************************************************************
  // -- Latch all inbound grants 
  // -- ********************************************************************************************************************************

  always @*
    begin

     // -- from arb
     arb_ld_gnt_d        =  arb_eng_ld_gnt;         // -- we_ld, cpy_ld, incr_ld, atomic_cas
     arb_st_gnt_d        =  arb_eng_st_gnt;         // -- we_st, cpy_st, incr_st, atomic_st
     arb_misc_gnt_d      =  arb_eng_misc_gnt;       // -- actag, intrpt, xtouch, wkhstthrd
     arb_rtry_ld_gnt_d   =  arb_eng_rtry_ld_gnt;    // -- we_rtry_ld, cpy_rtry_ld
     arb_rtry_st_gnt_d   =  arb_eng_rtry_st_gnt;    // -- we_rtry_st, cpy_rtry_st
     arb_rtry_misc_gnt_d =  arb_eng_rtry_misc_gnt;  // -- intrpt_rtry, xtouch_rtry, wkhstthrd_rtry

    end // -- always @ *


  // -- ********************************************************************************************************************************
  // -- Main State Machine
  // -- ********************************************************************************************************************************

  afp3_eng_fsm_main  fsm_main
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config
      .mmio_eng_use_pasid_for_actag                ( mmio_eng_use_pasid_for_actag ),
      .mmio_eng_enable                             ( mmio_eng_enable ),
      .mmio_eng_type_ld                            ( mmio_eng_type_ld ),
      .mmio_eng_type_st                            ( mmio_eng_type_st ),
      .mmio_eng_base_addr                          ( mmio_eng_base_addr[63:12] ),
      .mmio_eng_offset_mask                        ( mmio_eng_offset_mask[31:12] ),
      .mmio_eng_ld_size                            ( mmio_eng_ld_size[1:0] ),
      .mmio_eng_st_size                            ( mmio_eng_st_size[1:0] ),
      .mmio_eng_pasid                              ( mmio_eng_pasid ),
      .mmio_eng_send_interrupt                     ( mmio_eng_send_interrupt ),
      .mmio_eng_send_wkhstthrd                     ( mmio_eng_send_wkhstthrd ),
      .mmio_eng_error_intrpt_enable                ( mmio_eng_error_intrpt_enable ),
      .mmio_eng_wkhstthrd_intrpt_enable            ( mmio_eng_wkhstthrd_intrpt_enable ),
      .mmio_eng_extra_write_mode                   ( mmio_eng_extra_write_mode ),
      .mmio_eng_mmio_lat_mode                      ( mmio_eng_mmio_lat_mode ),
      .mmio_eng_mmio_lat_mode_sz_512_st            ( mmio_eng_mmio_lat_mode_sz_512_st ),
      .mmio_eng_mmio_lat_mode_sz_512_ld            ( mmio_eng_mmio_lat_mode_sz_512_ld ),
      .mmio_eng_mmio_lat_extra_read                ( mmio_eng_mmio_lat_extra_read ),
      .mmio_eng_mmio_lat_ld_ea                     ( mmio_eng_mmio_lat_ld_ea[63:7] ),
      .mmio_eng_xtouch_enable                      ( mmio_eng_xtouch_enable ),
      .mmio_eng_xtouch_pg_n                        ( mmio_eng_xtouch_pg_n[1:0] ),
      .mmio_eng_xtouch_pg_size                     ( mmio_eng_xtouch_pg_size[5:0] ),

      // -- Main Sequencer Control Inputs
      .actag_seq_done                              ( actag_seq_done ),
      .arb_eng_tags_idle                           ( arb_eng_tags_idle ),
      .arb_eng_ld_gnt                              ( arb_eng_ld_gnt ),
      .arb_eng_st_gnt                              ( arb_eng_st_gnt ),

      .xtouch_error_q                              ( xtouch_error_q ),
      .cpy_ld_error_q                              ( cpy_ld_error_q ),
      .cpy_st_error_q                              ( cpy_st_error_q ),
      .wkhstthrd_error_q                           ( wkhstthrd_error_q ),
      .atomic_error_q                              ( atomic_error_q ),

      .intrpt_idle_st                              ( intrpt_idle_st ),
      .intrpt_rtry_idle_st                         ( intrpt_rtry_idle_st ),
      .wkhstthrd_idle_st                           ( wkhstthrd_idle_st ),
      .wkhstthrd_rtry_idle_st                      ( wkhstthrd_rtry_idle_st ),
      .atomic_idle_st                              ( atomic_idle_st ),
      .atomic_rtry_idle_st                         ( atomic_rtry_idle_st ),

      // -- Main Sequencer Outputs
      .main_seq_error                              ( main_seq_error ),

      .main_state                                  ( main_state[4:0] ),
      .main_idle_st                                ( main_idle_st ),
      .main_actag_st                               ( main_actag_st ),
      .main_send_st                                ( main_send_st ),
      .main_err_intrpt_st                          ( main_err_intrpt_st ),
      .main_stop_st                                ( main_stop_st ),

      .start_actag_seq                             ( start_actag_seq ),
//         .start_we_ld_seq                             ( start_we_ld_seq ),
      .start_xtouch_seq                            ( start_xtouch_seq ),
      .start_cpy_ld_seq                            ( start_cpy_ld_seq ),
      .start_cpy_st_seq                            ( start_cpy_st_seq ),
      .start_wkhstthrd_seq                         ( start_wkhstthrd_seq ),
//         .start_incr_seq                              ( start_incr_seq ),
      .start_atomic_seq                            ( start_atomic_seq ),
      .start_intrpt_seq                            ( start_intrpt_seq ),
//         .start_we_st_seq                             ( start_we_st_seq ),
//         .start_wr_weq_seq                            ( start_wr_weq_seq )
      .main_seq_done                               ( main_seq_done ),

      .cpy_ld_ea_q                                 ( cpy_ld_ea_q[63:6] ),
      .cpy_st_ea_q                                 ( cpy_st_ea_q[63:6] ),
      .xtouch_ea_q                                 ( xtouch_ea_q[63:0] ),
      .cpy_ld_idle_st                              ( cpy_ld_idle_st ),
      .cpy_st_idle_st                              ( cpy_st_idle_st ),
      .cpy_ld_wt4rsp_st                            ( cpy_ld_wt4rsp_st ),
      .cpy_st_wt4rsp_st                            ( cpy_st_wt4rsp_st ),
      .cpy_ld_type_sel                             ( cpy_ld_type_sel ),
      .cpy_st_type_sel                             ( cpy_st_type_sel ),

      .we_cmd_is_intrpt_q                          ( we_cmd_is_intrpt_q ),
      .we_cmd_is_wkhstthrd_q                       ( we_cmd_is_wkhstthrd_q ),

      .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),
      .eng_arb_init                                ( eng_arb_init ),
      .eng_arb_ld_enable                           ( eng_arb_ld_enable ),
      .eng_arb_st_enable                           ( eng_arb_st_enable )

    );                                

  // -- ********************************************************************************************************************************
  // -- actag State Machine 
  // -- ********************************************************************************************************************************

  afp3_eng_fsm_actag  fsm_actag
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs
      .mmio_eng_use_pasid_for_actag                ( mmio_eng_use_pasid_for_actag ),
      .cfg_afu_actag_base                          ( cfg_afu_actag_base[11:0] ),

      .eng_actag                                   ( eng_actag[11:0] ),

//         .immed_terminate_enable_q                    ( immed_terminate_enable_q ),            
//         .eng_pe_terminate_q                          ( eng_pe_terminate_q ),                           

      // -- Command Inputs
//         .cmd_we_ea_q                                 ( cmd_we_ea_q[63:5] ),
      .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),
//         .we_cmd_length_q                             ( we_cmd_length_q[15:0] ),
//         .we_cmd_extra_q                              ( we_cmd_extra_q[0:0] ),

      .eng_num                                     ( eng_num[5:0] ),
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),

      // -- Main Sequencer Control Inputs & Arbitration Interface
      .start_actag_seq                             ( start_actag_seq ),

      .actag_req                                   ( actag_req ),
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),

      // -- Main Sequencer Outputs
      .actag_seq_done                              ( actag_seq_done ),
      .actag_seq_error                             ( actag_seq_error ),

      .actag_state                                 ( actag_state[1:0] ),
      .actag_idle_st                               ( actag_idle_st ),
      .actag_wt4gnt_st                             ( actag_wt4gnt_st ),

      // -- Command Bus
      .actag_valid                                 ( actag_valid ),
      .actag_opcode                                ( actag_opcode[7:0] ),
      .actag_actag                                 ( actag_actag[11:0] ),
      .actag_stream_id                             ( actag_stream_id[3:0] ),
      .actag_ea_or_obj                             ( actag_ea_or_obj[67:0] ),
      .actag_afutag                                ( actag_afutag[15:0] ),
      .actag_dl                                    ( actag_dl[1:0] ),
      .actag_pl                                    ( actag_pl[2:0] ),
      .actag_os                                    ( actag_os ),
      .actag_be                                    ( actag_be[63:0] ),
      .actag_flag                                  ( actag_flag[3:0] ),
      .actag_endian                                ( actag_endian ),
      .actag_bdf                                   ( actag_bdf[15:0] ),
//         .actag_pasid                                 ( actag_pasid[19:0] ),
      .actag_pg_size                               ( actag_pg_size[5:0] )

    );

  // -- ********************************************************************************************************************************
  // -- we_ld State Machine 
  // -- ********************************************************************************************************************************

//     Tie downs
assign we_ld_req = 1'b0;
//assign we_ld_seq_done = 1'b0;
//assign we_ld_capture_cmd = 1'b0;
assign we_ld_seq_error = 1'b0;
assign we_ld_state = 4'b1;
assign we_ld_idle_st = 1'b1;
assign we_ld_wt4gnt_st = 1'b0;
assign we_ld_wt4rsp_st = 1'b0;
assign we_ld_decode_st = 1'b0;
assign we_rtry_ld_req = 1'b0;
assign we_rtry_ld_seq_error = 1'b0;
assign we_rtry_ld_state = 4'b1;
assign we_rtry_ld_idle_st = 1'b1;
assign we_rtry_ld_wt4gnt_st = 1'b0;
assign we_rtry_ld_wt4bckoff_st = 1'b0;
assign we_rtry_ld_abort_st = 1'b0;

assign we_ld_valid = 1'b0;
assign we_ld_opcode[7:0] = 8'b0;
assign we_ld_actag[11:0] =12'b0;
assign we_ld_stream_id[3:0] = 4'b0;
assign we_ld_ea_or_obj[67:0] = 68'b0;
assign we_ld_afutag[15:0] = 16'b0;
assign we_ld_dl[1:0] = 2'b0;
assign we_ld_pl[2:0] = 3'b0;
assign we_ld_os = 1'b0;
assign we_ld_be[63:0] = 64'b0;
assign we_ld_flag[3:0] = 4'b0;
assign we_ld_endian = 1'b0;
assign we_ld_bdf[15:0] = 16'b0;
assign we_ld_pg_size[5:0] = 6'b0;

/*      mcp3_cpeng_fsm_we_ld  fsm_we_ld
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // -- Modes/Config & Misc Inputs
      .we_ld_type_sel                              ( we_ld_type_sel[1:0] ),
      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),                          

      .immed_terminate_enable_q                    ( immed_terminate_enable_q ),            
      .num_cmds_sent_eq_resp_rcvd                  ( num_cmds_sent_eq_resp_rcvd ),                   
      .eng_pe_terminate_q                          ( eng_pe_terminate_q ),                           

      // -- Command Inputs
      .cmd_we_ea_q                                 ( cmd_we_ea_q[63:5] ),                            
      .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),                             

      .eng_num                                     ( eng_num[5:0] ),                                 
      .eng_actag                                   ( eng_actag[11:0] ),                              
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),                         
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),                      
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),                    

      // -- Main Sequencer Control Inputs & Arbitration Interface
      .start_we_ld_seq                             ( start_we_ld_seq ),                              
      .arb_ld_gnt_q                                ( arb_ld_gnt_q ),                                 
      .rspi_we_ld_resp_val_q                       ( rspi_we_ld_resp_val_q ),                        

      .we_ld_req                                   ( we_ld_req ),                                    
      .arb_eng_ld_gnt                              ( arb_eng_ld_gnt ),                               

      // -- Main Sequencer Outputs
      .we_ld_capture_cmd                           ( we_ld_capture_cmd ),                               
      .we_ld_seq_done                              ( we_ld_seq_done ),                               
      .we_ld_seq_error                             ( we_ld_seq_error ),                              

      .we_ld_state                                 ( we_ld_state[3:0] ),
      .we_ld_idle_st                               ( we_ld_idle_st ),                                
      .we_ld_wt4gnt_st                             ( we_ld_wt4gnt_st ),                              
      .we_ld_wt4rsp_st                             ( we_ld_wt4rsp_st ),                              
      .we_ld_decode_st                             ( we_ld_decode_st ),                              

      // -- Rtry Sequencer Control Inputs & Arbitration Interface
      .start_we_rtry_ld_seq                        ( start_we_rtry_ld_seq ),                         
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),                     
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),                       
      .rtry_decode_is_abort                        ( rtry_decode_is_abort ),                         
      .we_rtry_ld_backoff_done                     ( we_rtry_ld_backoff_done ),                    
      .we_rtry_ld_backoff_done_q                   ( we_rtry_ld_backoff_done_q ),                    

      .we_rtry_ld_req                              ( we_rtry_ld_req ),                               
      .arb_eng_rtry_ld_gnt                         ( arb_eng_rtry_ld_gnt ),                          

      // -- Rtry Sequencer Outputs
      .we_rtry_ld_seq_error                        ( we_rtry_ld_seq_error ),                         

      .we_rtry_ld_state                            ( we_rtry_ld_state[3:0] ),
      .we_rtry_ld_idle_st                          ( we_rtry_ld_idle_st ),                           
      .we_rtry_ld_wt4bckoff_st                     ( we_rtry_ld_wt4bckoff_st ),                      
      .we_rtry_ld_wt4gnt_st                        ( we_rtry_ld_wt4gnt_st ),                         
      .we_rtry_ld_abort_st                         ( we_rtry_ld_abort_st ),                          

      // -- Command Bus
      .we_ld_valid                                 ( we_ld_valid ),                                  
      .we_ld_opcode                                ( we_ld_opcode[7:0] ),                            
      .we_ld_actag                                 ( we_ld_actag[11:0] ),                            
      .we_ld_stream_id                             ( we_ld_stream_id[3:0] ),                         
      .we_ld_ea_or_obj                             ( we_ld_ea_or_obj[67:0] ),                        
      .we_ld_afutag                                ( we_ld_afutag[15:0] ),                           
      .we_ld_dl                                    ( we_ld_dl[1:0] ),                                
      .we_ld_pl                                    ( we_ld_pl[2:0] ),                                
      .we_ld_os                                    ( we_ld_os ),                                     
      .we_ld_be                                    ( we_ld_be[63:0] ),                               
      .we_ld_flag                                  ( we_ld_flag[3:0] ),                              
      .we_ld_endian                                ( we_ld_endian ),                                 
      .we_ld_bdf                                   ( we_ld_bdf[15:0] ),                              
      .we_ld_pasid                                 ( we_ld_pasid[19:0] ),                            
      .we_ld_pg_size                               ( we_ld_pg_size[5:0] )                           

    );                      
*/
  // -- ********************************************************************************************************************************
  // -- Upon WE Load Response, decode the commmand 
  // -- ********************************************************************************************************************************

  // -- Capture into latches and hold (using gating)
  // -- After captured, decode the command in the following cycle

//    temp hack
//assign  we_cmd_source_ea_q[63:0]  =  64'b0;
assign  we_cmd_dest_ea_q[63:0]    =  64'b0;
assign  we_cmd_atomic_op1_q[63:0] =  64'b0;
assign  we_cmd_atomic_op2_q[63:0] =  64'b0;
assign  we_cmd_length_q[15:0]     =  16'b0;
assign  we_cmd_extra_q[7:0]       =   8'b0;
//assign  we_cmd_is_intrpt_q        =   1'b0;  //    - Moved to FSM Main
//assign  we_cmd_is_wkhstthrd_q     =   1'b0;  //    - Moved to FSM Main
assign  we_cmd_is_atomic_ld_q     =   1'b0;
assign  we_cmd_is_atomic_cas_d    =   1'b0;
assign  we_cmd_is_atomic_cas_q    =   1'b0;
assign  we_cmd_is_atomic_st_d     =   1'b0;
assign  we_cmd_is_atomic_st_q     =   1'b0;
assign  memcpy2_format_enable_q   =  mmio_eng_memcpy2_format_enable;  // ??? TODO: Might need to latch (was latched in MCP3)

/*       mcp3_cpeng_cmd_decode  cmd_decode
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // -- Modes/Config & Misc Inputs
      .mmio_eng_memcpy2_format_enable              ( mmio_eng_memcpy2_format_enable ),                      

      // -- Inputs
      .we_ld_capture_cmd                           ( we_ld_capture_cmd ),                            
      .we_ld_error_q                               ( we_ld_error_q ),                                
      .rspi_resp_data_q                            ( rspi_resp_data_q[511:0] ),                      
      .cmd_we_ea_q                                 ( 1'b0 ),    //     cmd_we_ea_q[5:5] ),                             
      .cmd_we_wrap_q                               ( cmd_we_wrap_q ),                                

      // -- Outputs
      .memcpy2_format_enable_q                     ( memcpy2_format_enable_q ),                      

      .we_cmd_valid_d                              ( we_cmd_valid_d ),                               
      .we_cmd_valid_q                              ( we_cmd_valid_q ),                               

      .we_cmd_val_q                                ( we_cmd_val_q ),                                 
      .we_cmd_source_ea_d                          ( we_cmd_source_ea_d[63:0] ),                     
      .we_cmd_source_ea_q                          ( we_cmd_source_ea_q[63:0] ),                     
      .we_cmd_dest_ea_d                            ( we_cmd_dest_ea_d[63:0] ),                       
      .we_cmd_dest_ea_q                            ( we_cmd_dest_ea_q[63:0] ),                       
      .we_cmd_atomic_op1_q                         ( we_cmd_atomic_op1_q[63:0] ),                    
      .we_cmd_atomic_op2_q                         ( we_cmd_atomic_op2_q[63:0] ),                    
      .we_cmd_length_d                             ( we_cmd_length_d[15:0] ),                        
      .we_cmd_length_q                             ( we_cmd_length_q[15:0] ),                        
      .we_cmd_encode_q                             ( we_cmd_encode_q[5:0] ),                         
      .we_cmd_extra_q                              ( we_cmd_extra_q[7:0] ),                          
      .we_cmd_wrap_q                               ( we_cmd_wrap_q ),                          

      .we_cmd_is_copy_d                            ( we_cmd_is_copy_d ),                             
      .we_cmd_is_copy_q                            ( we_cmd_is_copy_q ),                             
      .we_cmd_is_intrpt_d                          ( we_cmd_is_intrpt_d ),                           
      .we_cmd_is_intrpt_q                          ( we_cmd_is_intrpt_q ),                           
      .we_cmd_is_stop_d                            ( we_cmd_is_stop_d ),                             
      .we_cmd_is_stop_q                            ( we_cmd_is_stop_q ),                             
      .we_cmd_is_wkhstthrd_d                       ( we_cmd_is_wkhstthrd_d ),                        
      .we_cmd_is_wkhstthrd_q                       ( we_cmd_is_wkhstthrd_q ),                        
      .we_cmd_is_incr_d                            ( we_cmd_is_incr_d ),                             
      .we_cmd_is_incr_q                            ( we_cmd_is_incr_q ),                             
      .we_cmd_is_atomic_d                          ( we_cmd_is_atomic_d ),                           
      .we_cmd_is_atomic_q                          ( we_cmd_is_atomic_q ),                           
      .we_cmd_is_atomic_ld_d                       ( we_cmd_is_atomic_ld_d ),                        
      .we_cmd_is_atomic_ld_q                       ( we_cmd_is_atomic_ld_q ),                        
      .we_cmd_is_atomic_cas_d                      ( we_cmd_is_atomic_cas_d ),                       
      .we_cmd_is_atomic_cas_q                      ( we_cmd_is_atomic_cas_q ),                       
      .we_cmd_is_atomic_st_d                       ( we_cmd_is_atomic_st_d ),                        
      .we_cmd_is_atomic_st_q                       ( we_cmd_is_atomic_st_q ),                        
      .we_cmd_is_xtouch_d                          ( we_cmd_is_xtouch_d ),                           
      .we_cmd_is_xtouch_q                          ( we_cmd_is_xtouch_q ),                           

      .we_cmd_is_undefined_d                       ( we_cmd_is_undefined_d ),                        
      .we_cmd_is_undefined_q                       ( we_cmd_is_undefined_q ),                        
      .we_cmd_length_is_zero_d                     ( we_cmd_length_is_zero_d ),                      
      .we_cmd_length_is_zero_q                     ( we_cmd_length_is_zero_q ),
      .we_cmd_cpy_length_lt_64B_d                  ( we_cmd_cpy_length_lt_64B_d ),
      .we_cmd_cpy_length_lt_64B_q                  ( we_cmd_cpy_length_lt_64B_q ),           
      .we_cmd_is_bad_atomic_d                      ( we_cmd_is_bad_atomic_d ),                       
      .we_cmd_is_bad_atomic_q                      ( we_cmd_is_bad_atomic_q )                       

    );                       
*/
  // -- ********************************************************************************************************************************
  // -- xtouch State Machine
  // -- ********************************************************************************************************************************

  afp3_eng_fsm_xtouch  fsm_xtouch
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs
//         .mmio_eng_xtouch_source_enable               ( mmio_eng_xtouch_source_enable ),
//         .mmio_eng_xtouch_dest_enable                 ( mmio_eng_xtouch_dest_enable ),
      .mmio_eng_xtouch_wt4rsp_enable               ( mmio_eng_xtouch_wt4rsp_enable ),
//         .mmio_eng_xtouch_ageout_pg_size              ( mmio_eng_xtouch_ageout_pg_size[5:0] ),
//         .xtouch_type_sel                             ( xtouch_type_sel[1:0] ),
//         .xtouch_flag_sel                             ( xtouch_flag_sel[4:0] ),
      .mmio_eng_xtouch_type                        ( mmio_eng_xtouch_type ),
      .mmio_eng_xtouch_hwt                         ( mmio_eng_xtouch_hwt ),
      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),                          

//   -unused      .immed_terminate_enable_q                    ( immed_terminate_enable_q ),            
//   -unused      .num_cmds_sent_eq_resp_rcvd                  ( num_cmds_sent_eq_resp_rcvd ),                   
//   -unused      .eng_pe_terminate_q                          ( eng_pe_terminate_q ),                           

      // -- Command Inputs
//         .we_cmd_is_xtouch_d                          ( we_cmd_is_xtouch_d ),                           
//         .we_cmd_extra_q                              ( we_cmd_extra_q[2:0] ),                          
//         .we_cmd_source_ea_q                          ( we_cmd_source_ea_q[63:0] ),
      .xtouch_ea_q                                 ( xtouch_ea_q[63:0] ),
      .we_cmd_dest_ea_q                            ( we_cmd_dest_ea_q[63:0] ),
//         .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),
      .rtry_decode_is_hwt                          ( rtry_decode_is_hwt ),

      .eng_num                                     ( eng_num[5:0] ),
      .eng_actag                                   ( eng_actag[11:0] ),
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),

      // -- Main Sequencer Control Inputs & Arbitration Interface
      .start_xtouch_seq                            ( start_xtouch_seq ),
      .rspi_xtouch_source_resp_val_q               ( rspi_xtouch_source_resp_val_q ),
      .rspi_xtouch_dest_resp_val_q                 ( rspi_xtouch_dest_resp_val_q ),

      .xtouch_req                                  ( xtouch_req ),
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),

      // -- Main Sequencer Outputs
      .xtouch_seq_done                             ( xtouch_seq_done ),
      .xtouch_seq_error                            ( xtouch_seq_error ),

      .xtouch_state                                ( xtouch_state[3:0] ),
      .xtouch_idle_st                              ( xtouch_idle_st ),
      .xtouch_wt4gnt1_st                           ( xtouch_wt4gnt1_st ),
      .xtouch_wt4gnt2_st                           ( xtouch_wt4gnt2_st ),
      .xtouch_wt4rsp_st                            ( xtouch_wt4rsp_st ),

      // -- Rtry Sequencer Control Inputs & Arbitration Interface
      .start_xtouch_rtry_source_seq                ( start_xtouch_rtry_source_seq ),
      .start_xtouch_rtry_dest_seq                  ( start_xtouch_rtry_dest_seq ),
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),
      .rtry_decode_is_abort                        ( rtry_decode_is_abort ),
      .xtouch_rtry_source_backoff_done             ( xtouch_rtry_source_backoff_done ),
      .xtouch_rtry_source_backoff_done_q           ( xtouch_rtry_source_backoff_done_q ),
      .xtouch_rtry_dest_backoff_done               ( xtouch_rtry_dest_backoff_done ),
      .xtouch_rtry_dest_backoff_done_q             ( xtouch_rtry_dest_backoff_done_q ),

      .xtouch_rtry_req                             ( xtouch_rtry_req ),
      .arb_eng_rtry_misc_gnt                       ( arb_eng_rtry_misc_gnt ),

      // -- Rtry Sequencer Outputs
      .xtouch_rtry_seq_error                       ( xtouch_rtry_seq_error ),

      .xtouch_rtry_state                           ( xtouch_rtry_state[5:0] ),
      .xtouch_rtry_idle_st                         ( xtouch_rtry_idle_st ),
      .xtouch_rtry_wt4bckoff1_st                   ( xtouch_rtry_wt4bckoff1_st ),
      .xtouch_rtry_wt4gnt1_st                      ( xtouch_rtry_wt4gnt1_st ),
      .xtouch_rtry_wt4bckoff2_st                   ( xtouch_rtry_wt4bckoff2_st ),
      .xtouch_rtry_wt4gnt2_st                      ( xtouch_rtry_wt4gnt2_st ),
      .xtouch_rtry_abort_st                        ( xtouch_rtry_abort_st ),

      // -- Command Bus
      .xtouch_valid                                ( xtouch_valid ),
      .xtouch_opcode                               ( xtouch_opcode[7:0] ),
      .xtouch_actag                                ( xtouch_actag[11:0] ),
      .xtouch_stream_id                            ( xtouch_stream_id[3:0] ),
      .xtouch_ea_or_obj                            ( xtouch_ea_or_obj[67:0] ),
      .xtouch_afutag                               ( xtouch_afutag[15:0] ),
      .xtouch_dl                                   ( xtouch_dl[1:0] ),
      .xtouch_pl                                   ( xtouch_pl[2:0] ),
      .xtouch_os                                   ( xtouch_os ),
      .xtouch_be                                   ( xtouch_be[63:0] ),
      .xtouch_flag                                 ( xtouch_flag[3:0] ),
      .xtouch_endian                               ( xtouch_endian ),
      .xtouch_bdf                                  ( xtouch_bdf[15:0] ),
//         .xtouch_pasid                                ( xtouch_pasid[19:0] ),
      .xtouch_pg_size                              ( xtouch_pg_size[5:0] ),

      // -- Repowered Mode Bits for usage by other modules
//         .xtouch_enable_q                             ( xtouch_enable_q ),
      .xtouch_wt4rsp_enable_q                      ( xtouch_wt4rsp_enable_q )

    );

  // -- ********************************************************************************************************************************
  // -- cpy_ld State Machine
  // -- ********************************************************************************************************************************

  afp3_eng_fsm_cpy_ld  fsm_cpy_ld
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs
//         .mmio_eng_256B_op_disable                    ( mmio_eng_256B_op_disable ),
//         .mmio_eng_128B_op_disable                    ( mmio_eng_128B_op_disable ),
      .mmio_eng_ld_size                            ( mmio_eng_ld_size[1:0] ),
      .cpy_ld_type_sel                             ( cpy_ld_type_sel ),
      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),                          

//         .immed_terminate_enable_q                    ( immed_terminate_enable_q ),
//         .num_cmds_sent_eq_resp_rcvd                  ( num_cmds_sent_eq_resp_rcvd ),
//         .eng_pe_terminate_q                          ( eng_pe_terminate_q ),

      // -- Command Inputs
//         .we_ld_capture_cmd                           ( we_ld_capture_cmd ),
//         .we_ld_seq_done                              ( we_ld_seq_done ),
//         .we_cmd_length_d                             ( we_cmd_length_d[11:0] ),
//         .we_cmd_source_ea_d                          ( we_cmd_source_ea_d[63:6] ),
//         .we_cmd_source_ea_q                          ( we_cmd_source_ea_q[63:6] ),
//         .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),

      .cpy_rtry_xx_afutag_q                        ( cpy_rtry_xx_afutag_q[8:0] ),
      .cpy_rtry_xx_dl_q                            ( cpy_rtry_xx_dl_q[1:0] ),
//         .cpy_rtry_ld_ea_q                            ( cpy_rtry_ld_ea_q[63:6] ),

//         .eng_num                                     ( eng_num[5:0] ),
      .eng_actag                                   ( eng_actag[11:0] ),
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),

      // -- Main Sequencer Control Inputs & Arbitration Interface
//         .start_cpy_ld_seq                            ( start_cpy_ld_seq ),
      .cpy_ld_ea_q                                 ( cpy_ld_ea_q[63:6] ),
//         .arb_ld_gnt_q                                ( arb_ld_gnt_q ),
      .rspi_cpy_ld_resp_val_q                      ( rspi_cpy_ld_resp_val_q ),
      .rspi_resp_dl_q                              ( rspi_resp_dl_q[1:0] ),
      .rspi_resp_afutag_q                          ( rspi_resp_afutag_q[8:0] ),

//         .cpy_ld_req                                  ( cpy_ld_req ),    //eng_arb_ld_req
      .arb_eng_ld_gnt                              ( arb_eng_ld_gnt ),
      .arb_eng_ld_tag                              ( arb_eng_ld_tag[8:0] ),
      .eng_arb_set_ld_tag_avail                    ( eng_arb_set_ld_tag_avail[511:0] ),
      .eng_arb_ld_fastpath_valid                   ( eng_arb_ld_fastpath_valid ),
      .eng_arb_ld_fastpath_tag                     ( eng_arb_ld_fastpath_tag[8:0] ),

      // -- Main Sequencer Outputs
//         .cpy_ld_seq_done                             ( cpy_ld_seq_done ),
//         .cpy_ld_seq_error                            ( cpy_ld_seq_error ),

//         .cpy_ld_state                                ( cpy_ld_state[3:0] ),
//         .cpy_ld_idle_st                              ( cpy_ld_idle_st ),
//         .cpy_ld_req_st                               ( cpy_ld_req_st ),
//         .cpy_ld_wt4gnt_st                            ( cpy_ld_wt4gnt_st ),
//         .cpy_ld_wt4rsp_st                            ( cpy_ld_wt4rsp_st ),

      // -- Rtry Sequencer Control Inputs & Arbitration Interface
      .start_cpy_rtry_ld_seq                       ( start_cpy_rtry_ld_seq ),
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),
      .rtry_decode_is_abort                        ( rtry_decode_is_abort ),
      .rtry_queue_afutag_q                         ( rtry_queue_afutag_q[8:0]),
      .rtry_queue_dl_q                             ( rtry_queue_dl_q[1:0]),
      .cpy_rtry_ld_backoff_done                    ( cpy_rtry_ld_backoff_done ),
      .cpy_rtry_ld_backoff_done_q                  ( cpy_rtry_ld_backoff_done_q ),

      //.cpy_rtry_ld_req                             ( cpy_rtry_ld_req ),
      .eng_arb_rtry_ld_req                         ( eng_arb_rtry_ld_req ),
      .arb_eng_rtry_ld_gnt                         ( arb_eng_rtry_ld_gnt ),

      // -- Rtry Sequencer Outputs
      .cpy_rtry_ld_seq_error                       ( cpy_rtry_ld_seq_error ),

      .cpy_rtry_ld_state                           ( cpy_rtry_ld_state[3:0] ),
      .cpy_rtry_ld_idle_st                         ( cpy_rtry_ld_idle_st ),
      .cpy_rtry_ld_wt4bckoff_st                    ( cpy_rtry_ld_wt4bckoff_st ),
      .cpy_rtry_ld_wt4gnt_st                       ( cpy_rtry_ld_wt4gnt_st ),
      .cpy_rtry_ld_abort_st                        ( cpy_rtry_ld_abort_st ),

      // -- Command Bus
      .cpy_ld_valid                                ( cpy_ld_valid ),
      .cpy_ld_opcode                               ( cpy_ld_opcode[7:0] ),
      .cpy_ld_actag                                ( cpy_ld_actag[11:0] ),
      .cpy_ld_stream_id                            ( cpy_ld_stream_id[3:0] ),
      .cpy_ld_ea_or_obj                            ( cpy_ld_ea_or_obj[67:0] ),
      .cpy_ld_afutag                               ( cpy_ld_afutag[15:0] ),
      .cpy_ld_dl                                   ( cpy_ld_dl[1:0] ),
      .cpy_ld_pl                                   ( cpy_ld_pl[2:0] ),
      .cpy_ld_os                                   ( cpy_ld_os ),
      .cpy_ld_be                                   ( cpy_ld_be[63:0] ),
      .cpy_ld_flag                                 ( cpy_ld_flag[3:0] ),
      .cpy_ld_endian                               ( cpy_ld_endian ),
      .cpy_ld_bdf                                  ( cpy_ld_bdf[15:0] ),
//         .cpy_ld_pasid                                ( cpy_ld_pasid[19:0] ),
      .cpy_ld_pg_size                              ( cpy_ld_pg_size[5:0] )

      // -- Drive outbound to scorecard
//         .cpy_ld_size_q                               ( cpy_ld_size_q[8:6] ),
//         .cpy_ld_afutag_q                             ( cpy_ld_afutag_q[4:0] )

    );

  // -- ********************************************************************************************************************************
  // -- cpy_st State Machine
  // -- ********************************************************************************************************************************

  afp3_eng_fsm_cpy_st  fsm_cpy_st
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // -- Modes/Config & Misc Inputs
//         .mmio_eng_256B_op_disable                    ( mmio_eng_256B_op_disable ),                     
//         .mmio_eng_128B_op_disable                    ( mmio_eng_128B_op_disable ),                     
      .mmio_eng_st_size                            ( mmio_eng_st_size[1:0] ),                         
      .cpy_st_type_sel                             ( cpy_st_type_sel ),                         
      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),                          

//         .immed_terminate_enable_q                    ( immed_terminate_enable_q ),            
//         .num_cmds_sent_eq_resp_rcvd                  ( num_cmds_sent_eq_resp_rcvd ),                   
//         .eng_pe_terminate_q                          ( eng_pe_terminate_q ),                           

      // -- Command Inputs
//         .we_ld_capture_cmd                           ( we_ld_capture_cmd ),                            
//         .we_ld_seq_done                              ( we_ld_seq_done ),                               
//         .we_cmd_length_d                             ( we_cmd_length_d[11:0] ),                        
//         .we_cmd_dest_ea_d                            ( we_cmd_dest_ea_d[63:6] ),                       
//         .we_cmd_dest_ea_q                            ( we_cmd_dest_ea_q[63:6] ),                       
//         .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),                             

      .cpy_rtry_xx_afutag_q                        ( cpy_rtry_xx_afutag_q[8:0] ),                    
      .cpy_rtry_xx_dl_q                            ( cpy_rtry_xx_dl_q[1:0] ),                        
//         .cpy_rtry_st_ea_q                            ( cpy_rtry_st_ea_q[63:6] ),                       

//         .eng_num                                     ( eng_num[5:0] ),                                 
      .eng_actag                                   ( eng_actag[11:0] ),                              
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),                         
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),                      
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),                    

      // -- Main Sequencer Control Inputs & Arbitration Interface
//         .start_cpy_st_seq                            ( start_cpy_st_seq ),
      .cpy_st_ea_q                                 ( cpy_st_ea_q[63:6] ),
//         .arb_st_gnt_q                                ( arb_st_gnt_q ),                                 
      .rspi_cpy_st_resp_val_q                      ( rspi_cpy_st_resp_val_q ),                       
      .rspi_resp_dl_q                              ( rspi_resp_dl_q[1:0] ),                          
      .rspi_resp_afutag_q                          ( rspi_resp_afutag_q[8:0] ),

//         .cpy_st_req                                  ( cpy_st_req ),    //eng_arb_st_req
      .arb_eng_st_gnt                              ( arb_eng_st_gnt ),                               
      .arb_eng_st_tag                              ( arb_eng_st_tag[8:0] ),
      .eng_arb_set_st_tag_avail                    ( eng_arb_set_st_tag_avail[511:0] ),
      .eng_arb_st_fastpath_valid                   ( eng_arb_st_fastpath_valid ),
      .eng_arb_st_fastpath_tag                     ( eng_arb_st_fastpath_tag[8:0] ),

      // -- Main Sequencer Outputs
//         .cpy_st_seq_done                             ( cpy_st_seq_done ),                            
//         .cpy_st_seq_error                            ( cpy_st_seq_error ),                             

//         .cpy_st_state                                ( cpy_st_state[3:0] ),                            
//         .cpy_st_idle_st                              ( cpy_st_idle_st ),                               
//         .cpy_st_req_st                               ( cpy_st_req_st ),                                
//         .cpy_st_wt4gnt_st                            ( cpy_st_wt4gnt_st ),                             
//         .cpy_st_wt4rsp_st                            ( cpy_st_wt4rsp_st ),                             

      // -- Rtry Sequencer Control Inputs & Arbitration Interface
      .start_cpy_rtry_st_seq                       ( start_cpy_rtry_st_seq ),                        
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),                     
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),                       
      .rtry_decode_is_abort                        ( rtry_decode_is_abort ),                         
      .rtry_queue_afutag_q                         ( rtry_queue_afutag_q[8:0]),
      .rtry_queue_dl_q                             ( rtry_queue_dl_q[1:0]),
      .cpy_rtry_st_backoff_done                    ( cpy_rtry_st_backoff_done ),                   
      .cpy_rtry_st_backoff_done_q                  ( cpy_rtry_st_backoff_done_q ),                   

      .eng_arb_rtry_st_req                         ( eng_arb_rtry_st_req ),
      .cpy_rtry_st_req                             ( cpy_rtry_st_req ),                              
      .arb_eng_rtry_st_gnt                         ( arb_eng_rtry_st_gnt ),                          

      // -- Rtry Sequencer Outputs
      .cpy_rtry_st_seq_error                       ( cpy_rtry_st_seq_error ),                        

      .cpy_rtry_st_state                           ( cpy_rtry_st_state[4:0] ),                       
      .cpy_rtry_st_idle_st                         ( cpy_rtry_st_idle_st ),                          
      .cpy_rtry_st_wt4bckoff_st                    ( cpy_rtry_st_wt4bckoff_st ),                     
      .cpy_rtry_st_req_st                          ( cpy_rtry_st_req_st ),                           
      .cpy_rtry_st_wt4gnt_st                       ( cpy_rtry_st_wt4gnt_st ),                        
      .cpy_rtry_st_abort_st                        ( cpy_rtry_st_abort_st ),                         

      // -- Command Bus
      .cpy_st_valid                                ( cpy_st_valid ),                                 
      .cpy_st_opcode                               ( cpy_st_opcode[7:0] ),                           
      .cpy_st_actag                                ( cpy_st_actag[11:0] ),                           
      .cpy_st_stream_id                            ( cpy_st_stream_id[3:0] ),                        
      .cpy_st_ea_or_obj                            ( cpy_st_ea_or_obj[67:0] ),                       
      .cpy_st_afutag                               ( cpy_st_afutag[15:0] ),                          
      .cpy_st_dl                                   ( cpy_st_dl[1:0] ),                               
      .cpy_st_pl                                   ( cpy_st_pl[2:0] ),                               
      .cpy_st_os                                   ( cpy_st_os ),                                    
      .cpy_st_be                                   ( cpy_st_be[63:0] ),                              
      .cpy_st_flag                                 ( cpy_st_flag[3:0] ),                             
      .cpy_st_endian                               ( cpy_st_endian ),                                
      .cpy_st_bdf                                  ( cpy_st_bdf[15:0] ),                             
//         .cpy_st_pasid                                ( cpy_st_pasid[19:0] ),                           
      .cpy_st_pg_size                              ( cpy_st_pg_size[5:0] ),

      // -- Additional outputs needed by data buffer
//         .cpy_st_afutag_d                             ( cpy_st_afutag_d[4:0] ),                         
//         .cpy_st_afutag_q                             ( cpy_st_afutag_q[4:0] ),
//         .cpy_st_size_256_q                           ( cpy_st_size_256_q ),                          

      // -- Drive outbound to cmd_out for indicating size of data to the arbiter
      //.cpy_st_size_encoded_d                       ( cpy_st_size_encoded_d[1:0] ),
      .cpy_st_size_256_q                           ( cpy_st_size_256_q )                          

    );                          

  // -- ********************************************************************************************************************************
  // -- Score card for cpy loads/store cmds sent and responses received.
  // -- ********************************************************************************************************************************

//      Tie downs
  assign cpy_cmd_resp_rcvd_overlap   = 1'b0;
  assign cpy_cmd_resp_rcvd_mismatch  = 1'b0;

/*      mcp3_cpeng_cpy_scorecard  cpy_scorecard
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // -- Inputs
      .cpy_ld_idle_st                              ( cpy_ld_idle_st ),                               
      .cpy_ld_wt4gnt_st                            ( cpy_ld_wt4gnt_st ),                             
      .cpy_ld_size_q                               ( cpy_ld_size_q[8:6] ),                           
      .cpy_ld_afutag_q                             ( cpy_ld_afutag_q[4:0] ),                         
      .cpy_ld_seq_done                             ( cpy_ld_seq_done ),                            
      .arb_eng_ld_gnt                              ( arb_eng_ld_gnt ),                               

      .cpy_st_idle_st                              ( cpy_st_idle_st ),                               
      .cpy_st_wt4gnt_st                            ( cpy_st_wt4gnt_st ),                             
      .cpy_st_size_q                               ( cpy_st_size_q[8:6] ),                           
      .cpy_st_afutag_q                             ( cpy_st_afutag_q[4:0] ),                         
      .cpy_st_seq_done                             ( cpy_st_seq_done ),                            
      .arb_eng_st_gnt                              ( arb_eng_st_gnt ),                               

      .rspi_cpy_ld_resp_val_q                      ( rspi_cpy_ld_resp_val_q ),                       
      .rspi_cpy_st_resp_val_q                      ( rspi_cpy_st_resp_val_q ),                       
      .rspi_resp_afutag_q                          ( rspi_resp_afutag_q[4:0] ),                      
      .rspi_resp_dl_orig_q                         ( rspi_resp_dl_orig_q[1:0] ),                     
      .rspi_resp_dl_q                              ( rspi_resp_dl_q[1:0] ),                          
      .rspi_resp_dp_q                              ( rspi_resp_dp_q[1:0] ),                          

      // -- Outputs
      .cpy_cmd_resp_rcvd_overlap                   ( cpy_cmd_resp_rcvd_overlap ),                    
      .cpy_cmd_resp_rcvd_mismatch                  ( cpy_cmd_resp_rcvd_mismatch ),

      .cpy_cmd_sent_q                              ( cpy_cmd_sent_q[31:0] ),
      .cpy_cmd_resp_rcvd_q                         ( cpy_cmd_resp_rcvd_q[31:0] )

    );                  
*/
  // -- ********************************************************************************************************************************
  // -- wkhstthrd State Machine
  // -- ********************************************************************************************************************************

  afp3_eng_fsm_wkhstthrd  fsm_wkhstthrd
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs

      // -- Command Inputs
//         .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),
//         .we_cmd_length_q                             ( we_cmd_length_q[15:0] ),
//         .we_cmd_extra_q                              ( we_cmd_extra_q[0:0] ),
      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),                          
      .mmio_eng_wkhstthrd_tid                      ( mmio_eng_wkhstthrd_tid[15:0] ),
      .mmio_eng_wkhstthrd_flag                     ( mmio_eng_wkhstthrd_flag ),

      .eng_num                                     ( eng_num[5:0] ),
      .eng_actag                                   ( eng_actag[11:0] ),
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),

//         .immed_terminate_enable_q                    ( immed_terminate_enable_q ),            
//         .num_cmds_sent_eq_resp_rcvd                  ( num_cmds_sent_eq_resp_rcvd ),                   
//         .eng_pe_terminate_q                          ( eng_pe_terminate_q ),                           

      // -- Main Sequencer Control Inputs & Arbitration Interface
      .start_wkhstthrd_seq                         ( start_wkhstthrd_seq ),
      .rspi_wkhstthrd_resp_val_q                   ( rspi_wkhstthrd_resp_val_q ),

      .wkhstthrd_req                               ( wkhstthrd_req ),
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),

      // -- Main Sequencer Outputs
      .wkhstthrd_seq_done                          ( wkhstthrd_seq_done ),
      .wkhstthrd_seq_error                         ( wkhstthrd_seq_error ),

      .wkhstthrd_state                             ( wkhstthrd_state[2:0] ),
      .wkhstthrd_idle_st                           ( wkhstthrd_idle_st ),
      .wkhstthrd_wt4gnt_st                         ( wkhstthrd_wt4gnt_st ),
      .wkhstthrd_wt4rsp_st                         ( wkhstthrd_wt4rsp_st ),

      // -- Rtry Sequencer Control Inputs & Arbitration Interface
      .start_wkhstthrd_rtry_seq                    ( start_wkhstthrd_rtry_seq ),
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),
      .rtry_decode_is_abort                        ( rtry_decode_is_abort ),
      .wkhstthrd_rtry_backoff_done                 ( wkhstthrd_rtry_backoff_done ),
      .wkhstthrd_rtry_backoff_done_q               ( wkhstthrd_rtry_backoff_done_q ),

      .wkhstthrd_rtry_req                          ( wkhstthrd_rtry_req ),
      .arb_eng_rtry_misc_gnt                       ( arb_eng_rtry_misc_gnt ),

      // -- Rtry Sequencer Outputs
      .wkhstthrd_rtry_seq_error                    ( wkhstthrd_rtry_seq_error ),

      .wkhstthrd_rtry_state                        ( wkhstthrd_rtry_state[3:0] ),
      .wkhstthrd_rtry_idle_st                      ( wkhstthrd_rtry_idle_st ),
      .wkhstthrd_rtry_wt4bckoff_st                 ( wkhstthrd_rtry_wt4bckoff_st ),
      .wkhstthrd_rtry_wt4gnt_st                    ( wkhstthrd_rtry_wt4gnt_st ),
      .wkhstthrd_rtry_abort_st                     ( wkhstthrd_rtry_abort_st ),

      // -- Command Bus
      .wkhstthrd_valid                             ( wkhstthrd_valid ),
      .wkhstthrd_opcode                            ( wkhstthrd_opcode[7:0] ),
      .wkhstthrd_actag                             ( wkhstthrd_actag[11:0] ),
      .wkhstthrd_stream_id                         ( wkhstthrd_stream_id[3:0] ),
      .wkhstthrd_ea_or_obj                         ( wkhstthrd_ea_or_obj[67:0] ),
      .wkhstthrd_afutag                            ( wkhstthrd_afutag[15:0] ),
      .wkhstthrd_dl                                ( wkhstthrd_dl[1:0] ),
      .wkhstthrd_pl                                ( wkhstthrd_pl[2:0] ),
      .wkhstthrd_os                                ( wkhstthrd_os ),
      .wkhstthrd_be                                ( wkhstthrd_be[63:0] ),
      .wkhstthrd_flag                              ( wkhstthrd_flag[3:0] ),
      .wkhstthrd_endian                            ( wkhstthrd_endian ),
      .wkhstthrd_bdf                               ( wkhstthrd_bdf[15:0] ),
//         .wkhstthrd_pasid                             ( wkhstthrd_pasid[19:0] ),
      .wkhstthrd_pg_size                           ( wkhstthrd_pg_size[5:0] )

    );

  // -- ********************************************************************************************************************************
  // -- incr State Machine
  // -- ********************************************************************************************************************************
//     Tie downs
assign incr_ld_req = 1'b0;
assign incr_st_req = 1'b0;
assign incr_seq_done = 1'b0;
assign incr_seq_error = 1'b0;
assign incr_state = 5'b1;
assign incr_idle_st = 1'b1;
assign incr_wt4ldgnt_st = 1'b0;
assign incr_wt4ldrsp_st = 1'b0;
assign incr_wt4stgnt_st = 1'b0;
assign incr_wt4strsp_st = 1'b0;
assign incr_rtry_ld_req = 1'b0;
assign incr_rtry_st_req = 1'b0;
assign incr_rtry_seq_error = 1'b0;
assign incr_rtry_state = 6'b1;
assign incr_rtry_idle_st = 1'b1;
assign incr_rtry_wt4ldbckoff_st = 1'b0;
assign incr_rtry_wt4ldgnt_st = 1'b0;
assign incr_rtry_wt4stbckoff_st = 1'b0;
assign incr_rtry_wt4stgnt_st = 1'b0;
assign incr_rtry_abort_st = 1'b0;

assign incr_ld_valid = 1'b0;
assign incr_ld_opcode[7:0] = 8'b0;
assign incr_ld_actag[11:0] =12'b0;
assign incr_ld_stream_id[3:0] = 4'b0;
assign incr_ld_ea_or_obj[67:0] = 68'b0;
assign incr_ld_afutag[15:0] = 16'b0;
assign incr_ld_dl[1:0] = 2'b0;
assign incr_ld_pl[2:0] = 3'b0;
assign incr_ld_os = 1'b0;
assign incr_ld_be[63:0] = 64'b0;
assign incr_ld_flag[3:0] = 4'b0;
assign incr_ld_endian = 1'b0;
assign incr_ld_bdf[15:0] = 16'b0;
assign incr_ld_pg_size[5:0] = 6'b0;

assign incr_st_valid = 1'b0;
assign incr_st_opcode[7:0] = 8'b0;
assign incr_st_actag[11:0] =12'b0;
assign incr_st_stream_id[3:0] = 4'b0;
assign incr_st_ea_or_obj[67:0] = 68'b0;
assign incr_st_afutag[15:0] = 16'b0;
assign incr_st_dl[1:0] = 2'b0;
assign incr_st_pl[2:0] = 3'b0;
assign incr_st_os = 1'b0;
assign incr_st_be[63:0] = 64'b0;
assign incr_st_flag[3:0] = 4'b0;
assign incr_st_endian = 1'b0;
assign incr_st_bdf[15:0] = 16'b0;
assign incr_st_pg_size[5:0] = 6'b0;
assign incr_st_data[511:0] = 512'b0;

/*      mcp3_cpeng_fsm_incr  fsm_incr
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs
      .incr_ld_type_sel                            ( incr_ld_type_sel[1:0] ),
      .incr_st_type_sel                            ( incr_st_type_sel[1:0] ),
      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),                          

      .immed_terminate_enable_q                    ( immed_terminate_enable_q ),
      .num_cmds_sent_eq_resp_rcvd                  ( num_cmds_sent_eq_resp_rcvd ),
      .eng_pe_terminate_q                          ( eng_pe_terminate_q ),

      // -- Command Inputs
      .we_cmd_source_ea_q                          ( we_cmd_source_ea_q[63:0] ),
      .we_cmd_dest_ea_q                            ( we_cmd_dest_ea_q[63:0] ),
      .we_cmd_length_q                             ( we_cmd_length_q[3:3] ),
      .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),

      .eng_num                                     ( eng_num[5:0] ),
      .eng_actag                                   ( eng_actag[11:0] ),
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),

      // -- Data Inputs
      .rspi_resp_data_q                            ( rspi_resp_data_q[511:0] ),

      // -- Main Sequencer Control Inputs & Arbitration Interface
      .start_incr_seq                              ( start_incr_seq ),
      .incr_error_q                                ( incr_error_q ),
      .rspi_incr_ld_resp_val_q                     ( rspi_incr_ld_resp_val_q ),
      .rspi_incr_st_resp_val_q                     ( rspi_incr_st_resp_val_q ),

      .incr_ld_req                                 ( incr_ld_req ),
      .arb_eng_ld_gnt                              ( arb_eng_ld_gnt ),

      .incr_st_req                                 ( incr_st_req ),
      .arb_eng_st_gnt                              ( arb_eng_st_gnt ),

      // -- Main Sequencer Outputs
      .incr_seq_done                               ( incr_seq_done ),
      .incr_seq_error                              ( incr_seq_error ),

      .incr_state                                  ( incr_state[4:0] ),
      .incr_idle_st                                ( incr_idle_st ),
      .incr_wt4ldgnt_st                            ( incr_wt4ldgnt_st ),
      .incr_wt4ldrsp_st                            ( incr_wt4ldrsp_st ),
      .incr_wt4stgnt_st                            ( incr_wt4stgnt_st ),
      .incr_wt4strsp_st                            ( incr_wt4strsp_st ),

      // -- Rtry Sequencer Control Inputs & Arbitration Interface
      .start_incr_rtry_ld_seq                      ( start_incr_rtry_ld_seq ),
      .start_incr_rtry_st_seq                      ( start_incr_rtry_st_seq ),
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),
      .rtry_decode_is_abort                        ( rtry_decode_is_abort ),
      .incr_rtry_backoff_done                      ( incr_rtry_backoff_done ),
      .incr_rtry_backoff_done_q                    ( incr_rtry_backoff_done_q ),

      .incr_rtry_ld_req                            ( incr_rtry_ld_req ),
      .arb_eng_rtry_ld_gnt                         ( arb_eng_rtry_ld_gnt ),

      .incr_rtry_st_req                            ( incr_rtry_st_req ),
      .arb_eng_rtry_st_gnt                         ( arb_eng_rtry_st_gnt ),

      // -- Rtry Sequencer Outputs
      .incr_rtry_seq_error                         ( incr_rtry_seq_error ),

      .incr_rtry_state                             ( incr_rtry_state[5:0] ),
      .incr_rtry_idle_st                           ( incr_rtry_idle_st ),
      .incr_rtry_wt4ldbckoff_st                    ( incr_rtry_wt4ldbckoff_st ),
      .incr_rtry_wt4ldgnt_st                       ( incr_rtry_wt4ldgnt_st ),
      .incr_rtry_wt4stbckoff_st                    ( incr_rtry_wt4stbckoff_st ),
      .incr_rtry_wt4stgnt_st                       ( incr_rtry_wt4stgnt_st ),
      .incr_rtry_abort_st                          ( incr_rtry_abort_st ),

      // -- Command Bus
      .incr_ld_valid                               ( incr_ld_valid ),
      .incr_ld_opcode                              ( incr_ld_opcode[7:0] ),
      .incr_ld_actag                               ( incr_ld_actag[11:0] ),
      .incr_ld_stream_id                           ( incr_ld_stream_id[3:0] ),
      .incr_ld_ea_or_obj                           ( incr_ld_ea_or_obj[67:0] ),
      .incr_ld_afutag                              ( incr_ld_afutag[15:0] ),
      .incr_ld_dl                                  ( incr_ld_dl[1:0] ),
      .incr_ld_pl                                  ( incr_ld_pl[2:0] ),
      .incr_ld_os                                  ( incr_ld_os ),
      .incr_ld_be                                  ( incr_ld_be[63:0] ),
      .incr_ld_flag                                ( incr_ld_flag[3:0] ),
      .incr_ld_endian                              ( incr_ld_endian ),
      .incr_ld_bdf                                 ( incr_ld_bdf[15:0] ),
      .incr_ld_pasid                               ( incr_ld_pasid[19:0] ),
      .incr_ld_pg_size                             ( incr_ld_pg_size[5:0] ),

      .incr_st_valid                               ( incr_st_valid ),
      .incr_st_opcode                              ( incr_st_opcode[7:0] ),
      .incr_st_actag                               ( incr_st_actag[11:0] ),
      .incr_st_stream_id                           ( incr_st_stream_id[3:0] ),
      .incr_st_ea_or_obj                           ( incr_st_ea_or_obj[67:0] ),
      .incr_st_afutag                              ( incr_st_afutag[15:0] ),
      .incr_st_dl                                  ( incr_st_dl[1:0] ),
      .incr_st_pl                                  ( incr_st_pl[2:0] ),
      .incr_st_os                                  ( incr_st_os ),
      .incr_st_be                                  ( incr_st_be[63:0] ),
      .incr_st_flag                                ( incr_st_flag[3:0] ),
      .incr_st_endian                              ( incr_st_endian ),
      .incr_st_bdf                                 ( incr_st_bdf[15:0] ),
      .incr_st_pasid                               ( incr_st_pasid[19:0] ),
      .incr_st_pg_size                             ( incr_st_pg_size[5:0] ),

      // -- Data Bus
      .incr_st_data                                ( incr_st_data[511:0] )

    );
*/
  // -- ********************************************************************************************************************************
  // -- atomic State Machine
  // -- ********************************************************************************************************************************

  afp3_eng_fsm_atomic  fsm_atomic
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs
      .memcpy2_format_enable_q                     ( memcpy2_format_enable_q ),
      .atomic_ld_type_sel                          ( atomic_ld_type_sel[1:0] ),
      .atomic_st_type_sel                          ( atomic_st_type_sel[1:0] ),
      .atomic_cas_type_sel                         ( atomic_cas_type_sel[1:0] ),
      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),                          

      .main_seq_done                               ( main_seq_done ),

//         .immed_terminate_enable_q                    ( immed_terminate_enable_q ),            
//         .num_cmds_sent_eq_resp_rcvd                  ( num_cmds_sent_eq_resp_rcvd ),                   
//         .eng_pe_terminate_q                          ( eng_pe_terminate_q ),                           

      // -- Command Inputs
      .we_cmd_atomic_op1_q                         ( we_cmd_atomic_op1_q[63:0] ),
      .we_cmd_atomic_op2_q                         ( we_cmd_atomic_op2_q[63:0] ),
      .we_cmd_dest_ea_q                            ( we_cmd_dest_ea_q[63:0] ),
//         .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),
      .we_cmd_length_q                             ( we_cmd_length_q[3:3] ),
      .we_cmd_extra_q                              ( we_cmd_extra_q[7:0] ),

      .eng_num                                     ( eng_num[5:0] ),
      .eng_actag                                   ( eng_actag[11:0] ),
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),

      // -- Data Inputs
      .rspi_resp_data_q                            ( rspi_resp_data_q[511:0] ),

      // -- Main Sequencer Control Inputs & Arbitration Interface
      .start_atomic_seq                            ( start_atomic_seq ),
      .we_cmd_is_atomic_st_d                       ( we_cmd_is_atomic_st_d ),
      .we_cmd_is_atomic_cas_d                      ( we_cmd_is_atomic_cas_d ),
      .we_cmd_is_atomic_ld_q                       ( we_cmd_is_atomic_ld_q ),
      .we_cmd_is_atomic_st_q                       ( we_cmd_is_atomic_st_q ),
      .we_cmd_is_atomic_cas_q                      ( we_cmd_is_atomic_cas_q ),
      .rspi_atomic_ld_resp_val_q                   ( rspi_atomic_ld_resp_val_q ),
      .rspi_atomic_st_resp_val_q                   ( rspi_atomic_st_resp_val_q ),
      .rspi_atomic_cas_resp_val_d                  ( rspi_atomic_cas_resp_val_d ),

      .atomic_req                                  ( atomic_req ),
      .atomic_req_w_data                           ( atomic_req_w_data ),
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),

      // -- Main Sequencer Outputs
      .atomic_seq_done                             ( atomic_seq_done ),
      .atomic_seq_error                            ( atomic_seq_error ),

      .atomic_state                                ( atomic_state[3:0] ),
      .atomic_idle_st                              ( atomic_idle_st ),
      .atomic_wt4gnt_st                            ( atomic_wt4gnt_st ),
      .atomic_wt4rsp_st                            ( atomic_wt4rsp_st ),
      .atomic_compare_st                           ( atomic_compare_st ),

      // -- Rtry Sequencer Control Inputs & Arbitration Interface
      .start_atomic_rtry_seq                       ( start_atomic_rtry_seq ),
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),
      .rtry_decode_is_abort                        ( rtry_decode_is_abort ),
      .atomic_rtry_backoff_done                    ( atomic_rtry_backoff_done ),
      .atomic_rtry_backoff_done_q                  ( atomic_rtry_backoff_done_q ),

      .atomic_rtry_req                             ( atomic_rtry_req ),
      .atomic_rtry_req_w_data                      ( atomic_rtry_req_w_data ),
      .arb_eng_rtry_misc_gnt                       ( arb_eng_rtry_misc_gnt ),

      // -- Rtry Sequencer Outputs
      .atomic_rtry_seq_error                       ( atomic_rtry_seq_error ),

      .atomic_rtry_state                           ( atomic_rtry_state[3:0] ),
      .atomic_rtry_idle_st                         ( atomic_rtry_idle_st ),
      .atomic_rtry_wt4bckoff_st                    ( atomic_rtry_wt4bckoff_st ),
      .atomic_rtry_wt4gnt_st                       ( atomic_rtry_wt4gnt_st ),
      .atomic_rtry_abort_st                        ( atomic_rtry_abort_st ),

      // -- Command Bus
      .atomic_valid                                ( atomic_valid ),
      .atomic_opcode                               ( atomic_opcode[7:0] ),
      .atomic_actag                                ( atomic_actag[11:0] ),
      .atomic_stream_id                            ( atomic_stream_id[3:0] ),
      .atomic_ea_or_obj                            ( atomic_ea_or_obj[67:0] ),
      .atomic_afutag                               ( atomic_afutag[15:0] ),
      .atomic_dl                                   ( atomic_dl[1:0] ),
      .atomic_pl                                   ( atomic_pl[2:0] ),
      .atomic_os                                   ( atomic_os ),
      .atomic_be                                   ( atomic_be[63:0] ),
      .atomic_flag                                 ( atomic_flag[3:0] ),
      .atomic_endian                               ( atomic_endian ),
      .atomic_bdf                                  ( atomic_bdf[15:0] ),
//         .atomic_pasid                                ( atomic_pasid[19:0] ),
      .atomic_pg_size                              ( atomic_pg_size[5:0] ),

      // -- Data Bus
      .atomic_data_valid                           ( atomic_data_valid ),
      .atomic_data                                 ( atomic_data[511:0] ),

      // -- CAS fail indication to we_st - prevents updating offset that gets written back to WEQ
      .atomic_cas_failure_q                        ( atomic_cas_failure_q )

    );

  // -- ********************************************************************************************************************************
  // -- intrpt State Machine
  // -- ********************************************************************************************************************************

  afp3_eng_fsm_intrpt  fsm_intrpt
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs
      .main_seq_done                               ( main_seq_done ),
      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),                          

      // -- Command Inputs
//         .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),
      .cmd_intrpt_type_q                           ( cmd_intrpt_type_q[1:0] ),
//         .cmd_intrpt_obj_q                            ( cmd_intrpt_obj_q[63:0] ),
      .cmd_intrpt_data_q                           ( cmd_intrpt_data_q[31:0] ),
//         .we_cmd_source_ea_q                          ( we_cmd_source_ea_q[63:0] ),
      .we_cmd_dest_ea_q                            ( we_cmd_dest_ea_q[31:0] ),
      .we_cmd_is_intrpt_q                          ( we_cmd_is_intrpt_q ),
      .we_cmd_is_wkhstthrd_q                       ( we_cmd_is_wkhstthrd_q ),
      .we_cmd_extra_q                              ( we_cmd_extra_q[4:4] ),
      .mmio_eng_obj_handle                         ( mmio_eng_obj_handle ),

      .eng_num                                     ( eng_num[5:0] ),
      .eng_actag                                   ( eng_actag[11:0] ),
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),

//         .immed_terminate_enable_q                    ( immed_terminate_enable_q ),            
//         .num_cmds_sent_eq_resp_rcvd                  ( num_cmds_sent_eq_resp_rcvd ),                   
//         .eng_pe_terminate_q                          ( eng_pe_terminate_q ),                           

      // -- Main Sequencer Control Inputs & Arbitration Interface
      .start_intrpt_seq                            ( start_intrpt_seq ),
      .rspi_intrpt_resp_val_q                      ( rspi_intrpt_resp_val_q ),

      .intrpt_req                                  ( intrpt_req ),
      .intrpt_req_w_data                           ( intrpt_req_w_data ),
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),

      // -- Main Sequencer Outputs
      .intrpt_seq_done                             ( intrpt_seq_done ),
      .intrpt_seq_error                            ( intrpt_seq_error ),

      .intrpt_state                                ( intrpt_state[2:0] ),
      .intrpt_idle_st                              ( intrpt_idle_st ),
      .intrpt_wt4gnt_st                            ( intrpt_wt4gnt_st ),
      .intrpt_wt4rsp_st                            ( intrpt_wt4rsp_st ),

      // -- Rtry Sequencer Control Inputs & Arbitration Interface
      .start_intrpt_rtry_seq                       ( start_intrpt_rtry_seq ),
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),
      .rtry_decode_is_abort                        ( rtry_decode_is_abort ),
      .intrpt_rtry_backoff_done                    ( intrpt_rtry_backoff_done ),
      .intrpt_rtry_backoff_done_q                  ( intrpt_rtry_backoff_done_q ),

      .intrpt_rtry_req                             ( intrpt_rtry_req ),
      .intrpt_rtry_req_w_data                      ( intrpt_rtry_req_w_data ),
      .arb_eng_rtry_misc_gnt                       ( arb_eng_rtry_misc_gnt ),
      .arb_rtry_misc_gnt_q                         ( arb_rtry_misc_gnt_q ),

      // -- Rtry Sequencer Outputs
      .intrpt_rtry_seq_error                       ( intrpt_rtry_seq_error ),

      .intrpt_rtry_state                           ( intrpt_rtry_state[3:0] ),
      .intrpt_rtry_idle_st                         ( intrpt_rtry_idle_st ),
      .intrpt_rtry_wt4bckoff_st                    ( intrpt_rtry_wt4bckoff_st ),
      .intrpt_rtry_wt4gnt_st                       ( intrpt_rtry_wt4gnt_st ),
      .intrpt_rtry_abort_st                        ( intrpt_rtry_abort_st ),

      // -- Command Bus
      .intrpt_valid                                ( intrpt_valid ),
      .intrpt_opcode                               ( intrpt_opcode[7:0] ),
      .intrpt_actag                                ( intrpt_actag[11:0] ),
      .intrpt_stream_id                            ( intrpt_stream_id[3:0] ),
      .intrpt_ea_or_obj                            ( intrpt_ea_or_obj[67:0] ),
      .intrpt_afutag                               ( intrpt_afutag[15:0] ),
      .intrpt_dl                                   ( intrpt_dl[1:0] ),
      .intrpt_pl                                   ( intrpt_pl[2:0] ),
      .intrpt_os                                   ( intrpt_os ),
      .intrpt_be                                   ( intrpt_be[63:0] ),
      .intrpt_flag                                 ( intrpt_flag[3:0] ),
      .intrpt_endian                               ( intrpt_endian ),
      .intrpt_bdf                                  ( intrpt_bdf[15:0] ),
//         .intrpt_pasid                                ( intrpt_pasid[19:0] ),
      .intrpt_pg_size                              ( intrpt_pg_size[5:0] ),

      // -- Data Bus
      .intrpt_data_valid                           ( intrpt_data_valid ),
      .intrpt_data                                 ( intrpt_data[511:0] ),

      // -- Miscellaneous
      .intrpt_sent_q                               ( intrpt_sent_q )

    );

  // -- ********************************************************************************************************************************
  // -- we_st State Machine (update status in main memory we)
  // -- ********************************************************************************************************************************

//     Tie downs
assign we_st_req = 1'b0;
assign we_st_seq_done = 1'b0;
assign we_st_seq_error = 1'b0;
assign we_st_state = 3'b1;
assign we_st_idle_st = 1'b1;
assign we_st_wt4gnt_st = 1'b0;
assign we_st_wt4rsp_st = 1'b0;
assign we_rtry_st_req = 1'b0;
assign we_rtry_st_seq_error = 1'b0;
assign we_rtry_st_state = 4'b1;
assign we_rtry_st_idle_st = 1'b1;
assign we_rtry_st_wt4gnt_st = 1'b0;
assign we_rtry_st_wt4bckoff_st = 1'b0;
assign we_rtry_st_abort_st = 1'b0;

assign we_st_valid = 1'b0;
assign we_st_opcode[7:0] = 8'b0;
assign we_st_actag[11:0] =12'b0;
assign we_st_stream_id[3:0] = 4'b0;
assign we_st_ea_or_obj[67:0] = 68'b0;
assign we_st_afutag[15:0] = 16'b0;
assign we_st_dl[1:0] = 2'b0;
assign we_st_pl[2:0] = 3'b0;
assign we_st_os = 1'b0;
assign we_st_be[63:0] = 64'b0;
assign we_st_flag[3:0] = 4'b0;
assign we_st_endian = 1'b0;
assign we_st_bdf[15:0] = 16'b0;
assign we_st_pg_size[5:0] = 6'b0;
assign we_st_data[511:0] = 512'b0;
/*      mcp3_cpeng_fsm_we_st  fsm_we_st
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs
      .memcpy2_format_enable_q                     ( memcpy2_format_enable_q ),
      .we_st_type_sel                              ( we_st_type_sel[3:0] ),
      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),                          

      .immed_terminate_enable_q                    ( immed_terminate_enable_q ),
      .num_cmds_sent_eq_resp_rcvd                  ( num_cmds_sent_eq_resp_rcvd ),
      .eng_pe_terminate_q                          ( eng_pe_terminate_q ),

      // -- Inputs needed to form Status vector
      .we_ld_error_q                               ( we_ld_error_q ),
      .rspi_resp_failed_q                          ( rspi_resp_failed_q ),
      .rspi_resp_fault_q                           ( rspi_resp_fault_q ),
      .rspi_resp_derror_q                          ( rspi_resp_derror_q ),
      .rspi_resp_aerror_q                          ( rspi_resp_aerror_q ),

      // -- Command Inputs
      .we_cmd_val_q                                ( we_cmd_val_q ),
      .cmd_we_ea_q                                 ( cmd_we_ea_q[63:5] ),
      .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),

      .eng_num                                     ( eng_num[5:0] ),
      .eng_actag                                   ( eng_actag[11:0] ),
      .cfg_afu_bdf_bus                             ( cfg_afu_bdf_bus[7:0] ),
      .cfg_afu_bdf_device                          ( cfg_afu_bdf_device[4:0] ),
      .cfg_afu_bdf_function                        ( cfg_afu_bdf_function[2:0] ),

      // -- Main Sequencer Control Inputs & Arbitration Interface
      .start_we_st_seq                             ( start_we_st_seq ),
      .rspi_we_st_resp_val_q                       ( rspi_we_st_resp_val_q ),

      .we_st_req                                   ( we_st_req ),
      .arb_eng_st_gnt                              ( arb_eng_st_gnt ),

      // -- Main Sequencer Outputs
      .we_st_seq_done                              ( we_st_seq_done ),
      .we_st_seq_error                             ( we_st_seq_error ),

      .we_st_state                                 ( we_st_state[2:0] ),
      .we_st_idle_st                               ( we_st_idle_st ),
      .we_st_wt4gnt_st                             ( we_st_wt4gnt_st ),
      .we_st_wt4rsp_st                             ( we_st_wt4rsp_st ),

      // -- Rtry Sequencer Control Inputs & Arbitration Interface
      .start_we_rtry_st_seq                        ( start_we_rtry_st_seq ),
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),
      .rtry_decode_is_abort                        ( rtry_decode_is_abort ),
      .we_rtry_st_backoff_done                     ( we_rtry_st_backoff_done ),
      .we_rtry_st_backoff_done_q                   ( we_rtry_st_backoff_done_q ),

      .we_rtry_st_req                              ( we_rtry_st_req ),
      .arb_eng_rtry_st_gnt                         ( arb_eng_rtry_st_gnt ),

      // -- Rtry Sequencer Outputs
      .we_rtry_st_seq_error                        ( we_rtry_st_seq_error ),

      .we_rtry_st_state                            ( we_rtry_st_state[3:0] ),
      .we_rtry_st_idle_st                          ( we_rtry_st_idle_st ),
      .we_rtry_st_wt4bckoff_st                     ( we_rtry_st_wt4bckoff_st ),
      .we_rtry_st_wt4gnt_st                        ( we_rtry_st_wt4gnt_st ),
      .we_rtry_st_abort_st                         ( we_rtry_st_abort_st ),

      // -- Command Bus
      .we_st_valid                                 ( we_st_valid ),
      .we_st_opcode                                ( we_st_opcode[7:0] ),
      .we_st_actag                                 ( we_st_actag[11:0] ),
      .we_st_stream_id                             ( we_st_stream_id[3:0] ),
      .we_st_ea_or_obj                             ( we_st_ea_or_obj[67:0] ),
      .we_st_afutag                                ( we_st_afutag[15:0] ),
      .we_st_dl                                    ( we_st_dl[1:0] ),
      .we_st_pl                                    ( we_st_pl[2:0] ),
      .we_st_os                                    ( we_st_os ),
      .we_st_be                                    ( we_st_be[63:0] ),
      .we_st_flag                                  ( we_st_flag[3:0] ),
      .we_st_endian                                ( we_st_endian ),
      .we_st_bdf                                   ( we_st_bdf[15:0] ),
      .we_st_pasid                                 ( we_st_pasid[19:0] ),
      .we_st_pg_size                               ( we_st_pg_size[5:0] ),

      // -- Data Bus
      .we_st_data                                  ( we_st_data[511:0] )

    );
*/
  // -- ********************************************************************************************************************************
  // -- wr_weq State Machine (update status in weq module)
  // -- ********************************************************************************************************************************
//     Tie downs
assign wr_weq_seq_done = 1'b0;
assign wr_weq_seq_error = 1'b0;
assign wr_weq_state = 2'b1;
assign wr_weq_idle_st = 1'b1;
assign wr_weq_wt4gnt_st = 1'b0;

assign wr_weq_next_offset[18:5] = 14'b0;
assign wr_weq_next_wrap = 1'b0;

/*      mcp3_cpeng_fsm_wr_weq  fsm_wr_weq
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),
      .reset                                       ( reset ),

      // -- Modes/Config & Misc Inputs
      .mmio_eng_stop_on_invalid_cmd                ( mmio_eng_stop_on_invalid_cmd ),

      // -- Inputs used to for PE status vector
      .we_ld_error_q                               ( we_ld_error_q ),
      .xtouch_source_error_q                       ( xtouch_source_error_q ),
      .xtouch_dest_error_q                         ( xtouch_dest_error_q ),
      .cpy_ld_error_q                              ( cpy_ld_error_q ),
      .cpy_st_error_q                              ( cpy_st_error_q ),
      .wkhstthrd_error_q                           ( wkhstthrd_error_q ),
      .incr_ld_error_q                             ( incr_ld_error_q ),
      .incr_st_error_q                             ( incr_st_error_q ),
      .atomic_ld_error_q                           ( atomic_ld_error_q ),
      .atomic_st_error_q                           ( atomic_st_error_q ),
      .atomic_cas_error_q                          ( atomic_cas_error_q ),
      .intrpt_cmd_error_q                          ( intrpt_cmd_error_q ),
      .intrpt_err_error_q                          ( intrpt_err_error_q ),
      .intrpt_wht_error_q                          ( intrpt_wht_error_q ),
      .we_st_error_q                               ( we_st_error_q ),
      .rspi_resp_failed_q                          ( rspi_resp_failed_q ),
      .rspi_resp_fault_q                           ( rspi_resp_fault_q ),
      .rspi_resp_derror_q                          ( rspi_resp_derror_q ),
      .rspi_resp_aerror_q                          ( rspi_resp_aerror_q ),
      .atomic_cas_failure_q                        ( atomic_cas_failure_q ),
      .eng_pe_terminate_q                          ( eng_pe_terminate_q ),

      // -- Command Inputs
      .we_cmd_valid_q                              ( we_cmd_valid_q ),
      .we_cmd_is_stop_q                            ( we_cmd_is_stop_q ),

      .cmd_pasid_q                                 ( cmd_pasid_q[19:0] ),
      .cmd_offset_q                                ( cmd_offset_q[18:5] ),
      .cmd_weq_depth_q                             ( cmd_weq_depth_q[11:0] ),
      .cmd_we_wrap_q                               ( cmd_we_wrap_q ),

      .intrpt_sent_q                               ( intrpt_sent_q ),

      // -- Main Sequencer Control Inputs & Arbitration Interface
      .start_wr_weq_seq                            ( start_wr_weq_seq ),

      .eng_weq_we_req                              ( eng_weq_we_req ),
      .weq_eng_we_gnt                              ( weq_eng_we_gnt ),

      // -- Main Sequencer Outputs
      .wr_weq_seq_done                             ( wr_weq_seq_done ),
      .wr_weq_seq_error                            ( wr_weq_seq_error ),

      .wr_weq_state                                ( wr_weq_state[1:0] ),
      .wr_weq_idle_st                              ( wr_weq_idle_st ),
      .wr_weq_wt4gnt_st                            ( wr_weq_wt4gnt_st ),

      .wr_weq_next_offset                          ( wr_weq_next_offset[18:5] ),
      .wr_weq_next_wrap                            ( wr_weq_next_wrap ),

      .eng_weq_we_pasid                            ( eng_weq_we_pasid[19:0] ),
      .eng_weq_we_offset                           ( eng_weq_we_offset[18:5] ),
      .eng_weq_we_wrap                             ( eng_weq_we_wrap ),
      .eng_weq_we_pe_stat                          ( eng_weq_we_pe_stat[11:0] ),
      .eng_weq_we_cmd_val_orig                     ( eng_weq_we_cmd_val_orig )

    );
*/
  // -- ********************************************************************************************************************************
  // -- RSPi Response Interface
  // -- ********************************************************************************************************************************

  assign  rspi_eng_resp_valid_d =  rspi_eng_resp_valid;


   afp3_eng_resp_decode  resp_decode 

    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      .xtouch_wt4rsp_enable_q                      ( xtouch_wt4rsp_enable_q ),                       

      // -- Response Interface
      .rspi_eng_resp_valid                         ( rspi_eng_resp_valid ),                          
      .rspi_eng_resp_afutag                        ( rspi_eng_resp_afutag[15:0] ),                   
      .rspi_eng_resp_opcode                        ( rspi_eng_resp_opcode[7:0] ),                    
      .rspi_eng_resp_code                          ( rspi_eng_resp_code[3:0] ),                      
      .rspi_eng_resp_dl                            ( rspi_eng_resp_dl[1:0] ),                        
      .rspi_eng_resp_dp                            ( rspi_eng_resp_dp[1:0] ),                        

      .rspi_eng_resp_data_bus                      ( rspi_eng_resp_data_bus[1023:0] ),               
      .rspi_eng_resp_data_bdi                      ( rspi_eng_resp_data_bdi[1:0] ),                  

      // -- Sequencer States
      .main_idle_st                                ( main_idle_st ),                                 
      .we_ld_wt4rsp_st                             ( we_ld_wt4rsp_st ),                              
      .xtouch_idle_st                              ( xtouch_idle_st ),                               
      .cpy_ld_idle_st                              ( cpy_ld_idle_st ),                               
      .cpy_st_idle_st                              ( cpy_st_idle_st ),                               
      .wkhstthrd_wt4rsp_st                         ( wkhstthrd_wt4rsp_st ),                          
      .incr_wt4ldrsp_st                            ( incr_wt4ldrsp_st ),                             
      .incr_wt4strsp_st                            ( incr_wt4strsp_st ),                             
      .atomic_wt4rsp_st                            ( atomic_wt4rsp_st ),                             
      .intrpt_wt4rsp_st                            ( intrpt_wt4rsp_st ),                             
      .we_st_wt4rsp_st                             ( we_st_wt4rsp_st ),                              

      .we_cmd_is_atomic_ld_q                       ( we_cmd_is_atomic_ld_q ),                             
      .we_cmd_is_atomic_st_q                       ( we_cmd_is_atomic_st_q ),                             
      .we_cmd_is_atomic_cas_q                      ( we_cmd_is_atomic_cas_q ),                            

      // -- Cmdo afutag for checking
      .cmdo_valid                                  ( cmdo_valid ),                                   
      .cmdo_afutag                                 ( cmdo_afutag[15:0] ),                            

      // -- Data Error Terms from copy sequencers
      .cpy_cmd_resp_rcvd_overlap                   ( cpy_cmd_resp_rcvd_overlap ),                    
      .cpy_cmd_resp_rcvd_mismatch                  ( cpy_cmd_resp_rcvd_mismatch ),                   

      // -- Outputs
      .rspi_resp_is_we_ld_rtry_w_backoff_q         ( rspi_resp_is_we_ld_rtry_w_backoff_q ),          
      .rspi_resp_is_xtouch_source_rtry_w_backoff_q ( rspi_resp_is_xtouch_source_rtry_w_backoff_q ),  
      .rspi_resp_is_xtouch_dest_rtry_w_backoff_q   ( rspi_resp_is_xtouch_dest_rtry_w_backoff_q ),    
      .rspi_resp_is_cpy_ld_rtry_w_backoff_q        ( rspi_resp_is_cpy_ld_rtry_w_backoff_q ),         
      .rspi_resp_is_cpy_st_rtry_w_backoff_q        ( rspi_resp_is_cpy_st_rtry_w_backoff_q ),         
      .rspi_resp_is_wkhstthrd_rtry_w_backoff_q     ( rspi_resp_is_wkhstthrd_rtry_w_backoff_q ),      
      .rspi_resp_is_incr_rtry_w_backoff_q          ( rspi_resp_is_incr_rtry_w_backoff_q ),           
      .rspi_resp_is_atomic_rtry_w_backoff_q        ( rspi_resp_is_atomic_rtry_w_backoff_q ),         
      .rspi_resp_is_intrpt_rtry_w_backoff_q        ( rspi_resp_is_intrpt_rtry_w_backoff_q ),         
      .rspi_resp_is_we_st_rtry_w_backoff_q         ( rspi_resp_is_we_st_rtry_w_backoff_q ),          

      .rspi_resp_is_rtry_req                       ( rspi_resp_is_rtry_req ),                        
      .rspi_resp_is_rtry_lwt                       ( rspi_resp_is_rtry_lwt ),                        

      .rspi_resp_is_rtry                           ( rspi_resp_is_rtry ),                        
      .rspi_resp_is_xtouch_rtry                    ( rspi_resp_is_xtouch_rtry ),                        

      // -- Error cases for logging or bugspray
      .rcvd_touch_resp_when_not_expected           ( rcvd_touch_resp_when_not_expected ),            
      .rcvd_touch_resp_w_bad_afutag                ( rcvd_touch_resp_w_bad_afutag ),                 
      .rcvd_unexpected_resp_w_xtouch_afutag        ( rcvd_unexpected_resp_w_xtouch_afutag ),         

      .rcvd_ld_resp_when_not_expected              ( rcvd_ld_resp_when_not_expected ),               
      .rcvd_ld_resp_w_bad_afutag                   ( rcvd_ld_resp_w_bad_afutag ),                    
      .rcvd_unexpected_resp_w_ld_afutag            ( rcvd_unexpected_resp_w_ld_afutag ),             

      .rcvd_st_resp_when_not_expected              ( rcvd_st_resp_when_not_expected ),               
      .rcvd_st_resp_w_bad_afutag                   ( rcvd_st_resp_w_bad_afutag ),                    
      .rcvd_unexpected_resp_w_st_afutag            ( rcvd_unexpected_resp_w_st_afutag ),             

      .rcvd_wake_host_resp_when_not_expected       ( rcvd_wake_host_resp_when_not_expected ),        
      .rcvd_wake_host_resp_w_bad_afutag            ( rcvd_wake_host_resp_w_bad_afutag ),             
      .rcvd_unexpected_resp_w_wkhstthrd_afutag     ( rcvd_unexpected_resp_w_wkhstthrd_afutag ),      

      .rcvd_intrp_resp_when_not_expected           ( rcvd_intrp_resp_when_not_expected ),            
      .rcvd_intrp_resp_w_bad_afutag                ( rcvd_intrp_resp_w_bad_afutag ),                 
      .rcvd_unexpected_resp_w_intrpt_afutag        ( rcvd_unexpected_resp_w_intrpt_afutag ),         

      .undefined_rspi_we_ld_afutag                 ( undefined_rspi_we_ld_afutag ),                  
      .undefined_rspi_xtouch_afutag                ( undefined_rspi_xtouch_afutag ),                 
      .undefined_rspi_cpy_afutag                   ( undefined_rspi_cpy_afutag ),                    
      .undefined_rspi_wkhstthrd_afutag             ( undefined_rspi_wkhstthrd_afutag ),              
      .undefined_rspi_incr_afutag                  ( undefined_rspi_incr_afutag ),                   
      .undefined_rspi_atomic_afutag                ( undefined_rspi_atomic_afutag ),                 
      .undefined_rspi_intrpt_afutag                ( undefined_rspi_intrpt_afutag ),                 

      .undefined_cmdo_we_ld_afutag                 ( undefined_cmdo_we_ld_afutag ),                  
      .undefined_cmdo_xtouch_afutag                ( undefined_cmdo_xtouch_afutag ),                 
      .undefined_cmdo_cpy_afutag                   ( undefined_cmdo_cpy_afutag ),                    
      .undefined_cmdo_wkhstthrd_afutag             ( undefined_cmdo_wkhstthrd_afutag ),              
      .undefined_cmdo_incr_afutag                  ( undefined_cmdo_incr_afutag ),                   
      .undefined_cmdo_atomic_afutag                ( undefined_cmdo_atomic_afutag ),                 
      .undefined_cmdo_intrpt_afutag                ( undefined_cmdo_intrpt_afutag ),                 

      // -- Send Latched Valid to sequencers (ie. Indication of DONE, NOT Retried)
      .rspi_we_ld_resp_val_q                       ( rspi_we_ld_resp_val_q ),                        
      .rspi_xtouch_source_resp_val_q               ( rspi_xtouch_source_resp_val_q ),                
      .rspi_xtouch_dest_resp_val_q                 ( rspi_xtouch_dest_resp_val_q ),                  
      .rspi_cpy_ld_resp_val_q                      ( rspi_cpy_ld_resp_val_q ),                       
      .rspi_cpy_st_resp_val_q                      ( rspi_cpy_st_resp_val_q ),                       
      .rspi_incr_ld_resp_val_q                     ( rspi_incr_ld_resp_val_q ),                      
      .rspi_incr_st_resp_val_q                     ( rspi_incr_st_resp_val_q ),                      
      .rspi_atomic_ld_resp_val_q                   ( rspi_atomic_ld_resp_val_q ),                    
      .rspi_atomic_st_resp_val_q                   ( rspi_atomic_st_resp_val_q ),                    
      .rspi_atomic_cas_resp_val_d                  ( rspi_atomic_cas_resp_val_d ),                   
      .rspi_wkhstthrd_resp_val_q                   ( rspi_wkhstthrd_resp_val_q ),                    
      .rspi_intrpt_resp_val_q                      ( rspi_intrpt_resp_val_q ),                       
      .rspi_we_st_resp_val_q                       ( rspi_we_st_resp_val_q ),                        

      // -- Send Pending Cnt to retry queue to block reads
      .pending_cnt_q                               ( pending_cnt_q[4:0] ),                           

      // -- Send latched response decodes to be stored in the retry queue
      .rspi_resp_is_pending_q                      ( rspi_resp_is_pending_q ), 
      .rspi_resp_is_rtry_hwt_q                     ( rspi_resp_is_rtry_hwt_q ),
      .rspi_resp_is_rtry_req_q                     ( rspi_resp_is_rtry_req_q ),
      .rspi_resp_is_rtry_lwt_q                     ( rspi_resp_is_rtry_lwt_q ),

      // -- Send Latched Errors to wr_weq sequencer for inclusion in status
      .rspi_resp_fault_q                           ( rspi_resp_fault_q ),                            
      .rspi_resp_failed_q                          ( rspi_resp_failed_q ),                           
      .rspi_resp_aerror_q                          ( rspi_resp_aerror_q ),                           
      .rspi_resp_derror_q                          ( rspi_resp_derror_q ),                           

      .we_ld_error_q                               ( we_ld_error_q ),                                
      .xtouch_source_error_q                       ( xtouch_source_error_q ),                        
      .xtouch_dest_error_q                         ( xtouch_dest_error_q ),                          
      .cpy_ld_error_q                              ( cpy_ld_error_q ),                               
      .cpy_st_error_q                              ( cpy_st_error_q ),                               
      .wkhstthrd_error_q                           ( wkhstthrd_error_q ),                            
      .incr_ld_error_q                             ( incr_ld_error_q ),                              
      .incr_st_error_q                             ( incr_st_error_q ),                              
      .atomic_ld_error_q                           ( atomic_ld_error_q ),                            
      .atomic_st_error_q                           ( atomic_st_error_q ),                            
      .atomic_cas_error_q                          ( atomic_cas_error_q ),                           
      .intrpt_cmd_error_q                          ( intrpt_cmd_error_q ),                           
      .intrpt_err_error_q                          ( intrpt_err_error_q ),                           
      .intrpt_wht_error_q                          ( intrpt_wht_error_q ),                           
      .we_st_error_q                               ( we_st_error_q ),                                

      .xtouch_error_q                              ( xtouch_error_q ),                               
      .cpy_error_q                                 ( cpy_error_q ),                                  
      .incr_error_q                                ( incr_error_q ),                                 
      .atomic_error_q                              ( atomic_error_q ),                               
      .intrpt_error_q                              ( intrpt_error_q ),                               

      .error_q                                     ( error_q ),

      // -- Send latched outputs to dbuf
      .rspi_resp_is_cpy_xx_q                       ( rspi_resp_is_cpy_xx_q ),                     
      .rspi_resp_is_cpy_st_q                       ( rspi_resp_is_cpy_st_q ),                     
      .rspi_resp_afutag_q                          ( rspi_resp_afutag_q[8:0] ),                     
      .rspi_resp_opcode_q                          ( rspi_resp_opcode_q[7:0] ),                      
      .rspi_resp_code_q                            ( rspi_resp_code_q[3:0] ),                        
      .rspi_resp_dl_orig_q                         ( rspi_resp_dl_orig_q[1:0] ),                     
      .rspi_resp_dl_q                              ( rspi_resp_dl_q[1:0] ),                          
      .rspi_resp_dp_q                              ( rspi_resp_dp_q[1:0] ),                          

      .rspi_resp_afutag_dbuf_q                     ( rspi_resp_afutag_dbuf_q[0] ),                     
      .rspi_resp_dl_dbuf_q                         ( rspi_resp_dl_dbuf_q[1:0] ),                          

      .rspi_resp_data_q                            ( rspi_resp_data_q[1023:0] ),                     
      .rspi_resp_data_bdi_q                        ( rspi_resp_data_bdi_q[1:0] ),                    
      .rspi_resp_data_valid_q                      ( rspi_resp_data_valid_q ),                       
      .rspi_resp_data_valid_xfer2_q                ( rspi_resp_data_valid_xfer2_q ),

      .unexpected_xlate_or_intrpt_done_200         ( unexpected_xlate_or_intrpt_done_200 ),

      .eng_perf_wkhstthrd_good                     ( eng_perf_wkhstthrd_good ),

      .eng_mmio_extra_read_resp                    ( eng_mmio_extra_read_resp[3:0] ),
      .eng_mmio_data                               ( eng_mmio_data[1023:0] )

    );                                      

  // -- ********************************************************************************************************************************
  // -- cpy_dbuf - Copy Data Buffer
  // -- ********************************************************************************************************************************

/*       mcp3_cpeng_cpy_dbuf  cpy_dbuf
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // -- Inputs
      .main_idle_st                                ( main_idle_st ),                                 
      .rspi_eng_resp_valid                         ( rspi_eng_resp_valid ),                          
      .rspi_eng_resp_afutag                        ( rspi_eng_resp_afutag[4:1] ),                    

      .rspi_resp_afutag_dbuf_q                     ( rspi_resp_afutag_dbuf_q[0:0] ),                      
      .rspi_resp_dl_dbuf_q                         ( rspi_resp_dl_dbuf_q[1:0] ),                          
      .rspi_resp_dl_orig_q                         ( rspi_resp_dl_orig_q[1:0] ),                     
      .rspi_resp_dp_q                              ( rspi_resp_dp_q[1:0] ),                          
      .rspi_resp_data_valid_q                      ( rspi_resp_data_valid_q ),                       
      .rspi_resp_data_valid_xfer2_q                ( rspi_resp_data_valid_xfer2_q ),                 
      .rspi_resp_data_q                            ( rspi_resp_data_q[1023:0] ),                     

      .cpy_st_req                                  ( cpy_st_req ),                                
      .cpy_st_req_st                               ( cpy_st_req_st ),                                
      .cpy_st_wt4gnt_st                            ( cpy_st_wt4gnt_st ),                             
      .cpy_st_wt4rsp_st                            ( cpy_st_wt4rsp_st ),                             
      .cpy_st_afutag_d                             ( cpy_st_afutag_d[4:0] ),                         
      .cpy_st_afutag_q                             ( cpy_st_afutag_q[0:0] ),                         
      .cpy_st_size_q                               ( cpy_st_size_q[8:6] ),                           

      .cpy_rtry_st_req                             ( cpy_rtry_st_req ),                              
      .cpy_rtry_st_req_st                          ( cpy_rtry_st_req_st ),                           
      .cpy_rtry_st_wt4gnt_st                       ( cpy_rtry_st_wt4gnt_st ),                        
      .cpy_rtry_xx_afutag_d                        ( cpy_rtry_xx_afutag_d[4:0] ),                    
      .cpy_rtry_xx_afutag_q                        ( cpy_rtry_xx_afutag_q[0:0] ),                    
      .cpy_rtry_st_size_q                          ( cpy_rtry_st_size_q[8:6] ),                           

      .eng_display_ary_select_q                    ( eng_display_ary_select_q[1:0] ),                
      .eng_display_dbuf_rden                       ( eng_display_dbuf_rden ),                        
      .eng_display_dbuf_rden_dly1                  ( eng_display_dbuf_rden_dly1 ),                   
      .eng_display_req                             ( eng_display_req ),                              
      .eng_display_req_st                          ( eng_display_req_st ),                           
      .eng_display_wt4gnt_st                       ( eng_display_wt4gnt_st ),                        
      .eng_display_addr_q                          ( eng_display_addr_q[4:0] ),                      
      .eng_display_size                            ( eng_display_size[8:6] ),                        

      .arb_eng_st_gnt                              ( arb_eng_st_gnt ),                               
      .arb_eng_rtry_st_gnt                         ( arb_eng_rtry_st_gnt ),                          
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),                             

      // -- Outputs
      .cpy_st_data                                 ( cpy_st_data[1023:0] )

    );                         
*/
  // -- ********************************************************************************************************************************
  // -- Retry Queue 
  // -- ********************************************************************************************************************************

   afp3_eng_rtry_queue  rtry_queue
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // -- Modes/Config
      .xtouch_wt4rsp_enable_q                      ( xtouch_wt4rsp_enable_q ),
      .mmio_eng_capture_all_resp_code_enable       ( mmio_eng_capture_all_resp_code_enable ),                  

      // -- Inputs
      .main_idle_st                                ( main_idle_st ),                                 

      // -- Inputs from resp_decode to write into the rtry queue
      .rspi_eng_resp_valid                         ( rspi_eng_resp_valid ),                        
      .rspi_eng_resp_opcode                        ( rspi_eng_resp_opcode[7:0] ),                    
      .rspi_resp_is_rtry                           ( rspi_resp_is_rtry ),                            
      .rspi_resp_is_xtouch_rtry                    ( rspi_resp_is_xtouch_rtry ),                     
      .rspi_resp_is_cpy_xx_q                       ( rspi_resp_is_cpy_xx_q ),                     
      .rspi_resp_is_cpy_st_q                       ( rspi_resp_is_cpy_st_q ),                     
      .rspi_resp_afutag_q                          ( rspi_resp_afutag_q[8:0] ),                     
      .rspi_resp_dl_orig_q                         ( rspi_resp_dl_orig_q[1:0] ),                     
      .rspi_resp_dl_q                              ( rspi_resp_dl_q[1:0] ),                          
      .rspi_resp_dp_q                              ( rspi_resp_dp_q[1:0] ),                          
      .rspi_resp_code_q                            ( rspi_resp_code_q[3:0] ),                        
      .rspi_resp_is_pending_q                      ( rspi_resp_is_pending_q ),                       
      .rspi_resp_is_rtry_lwt_q                     ( rspi_resp_is_rtry_lwt_q ),                      
      .rspi_resp_is_rtry_req_q                     ( rspi_resp_is_rtry_req_q ),                      
      .rspi_resp_is_rtry_hwt_q                     ( rspi_resp_is_rtry_hwt_q ),                      

      // -- Inputs used to form functional rden blocker
      .we_ld_wt4rsp_st                             ( we_ld_wt4rsp_st ),                              
      .xtouch_wt4rsp_st                            ( xtouch_wt4rsp_st ),                             
      .cpy_ld_wt4rsp_st                            ( cpy_ld_wt4rsp_st ),                             
      .cpy_st_wt4rsp_st                            ( cpy_st_wt4rsp_st ),                             
      .wkhstthrd_wt4rsp_st                         ( wkhstthrd_wt4rsp_st ),                          
      .incr_wt4ldrsp_st                            ( incr_wt4ldrsp_st ),                             
      .incr_wt4strsp_st                            ( incr_wt4strsp_st ),                             
      .atomic_wt4rsp_st                            ( atomic_wt4rsp_st ),                             
      .intrpt_wt4rsp_st                            ( intrpt_wt4rsp_st ),                             
      .we_st_wt4rsp_st                             ( we_st_wt4rsp_st ),                              

      .we_rtry_ld_idle_st                          ( we_rtry_ld_idle_st ),                           
      .xtouch_rtry_idle_st                         ( xtouch_rtry_idle_st ),                          
      .cpy_rtry_ld_idle_st                         ( cpy_rtry_ld_idle_st ),                          
      .cpy_rtry_st_idle_st                         ( cpy_rtry_st_idle_st ),                          
      .wkhstthrd_rtry_idle_st                      ( wkhstthrd_rtry_idle_st ),                       
      .incr_rtry_idle_st                           ( incr_rtry_idle_st ),                            
      .atomic_rtry_idle_st                         ( atomic_rtry_idle_st ),                          
      .we_rtry_st_idle_st                          ( we_rtry_st_idle_st ),                           

      .pending_cnt_q                               ( pending_cnt_q[4:0] ),                           

      // -- Additional Inputs to block the functional rden when using display function
      .start_eng_display_seq                       ( start_eng_display_seq ),                        
      .eng_display_idle_st                         ( eng_display_idle_st ),                          

      // -- Inputs needed to read the rtry queue array via display function
      .eng_display_rtry_queue_rden                 ( eng_display_rtry_queue_rden ),                  
      .eng_display_addr_q                          ( eng_display_addr_q[9:0] ),                      

      // -- Inputs needed to calculate the new rtry cpy_ld/st_ea's
//         .we_cmd_source_ea_q                          ( we_cmd_source_ea_q[63:6] ),                     
//         .we_cmd_dest_ea_q                            ( we_cmd_dest_ea_q[63:6] ),                       

      // -- Outputs
      .rtry_queue_empty                            ( rtry_queue_empty ),
      .rtry_queue_func_rden_dly2_q                 ( rtry_queue_func_rden_dly2_q ),                        
      .rtry_queue_cpy_xx_q                         ( rtry_queue_cpy_xx_q ),                          
      .rtry_queue_cpy_st_q                         ( rtry_queue_cpy_st_q ),                          
      .rtry_queue_afutag_q                         ( rtry_queue_afutag_q[8:0] ),
      .rtry_queue_dl_q                             ( rtry_queue_dl_q[1:0] ),                         
      .rtry_queue_is_pending_q                     ( rtry_queue_is_pending_q ),                      
      .rtry_queue_is_rtry_lwt_q                    ( rtry_queue_is_rtry_lwt_q ),                     
      .rtry_queue_is_rtry_req_q                    ( rtry_queue_is_rtry_req_q ),                     
      .rtry_queue_is_rtry_hwt_q                    ( rtry_queue_is_rtry_hwt_q ),                     

      .resp_code_is_done                           ( resp_code_is_done ),                            
      .resp_code_is_rty_req                        ( resp_code_is_rty_req ),                         
      .resp_code_is_failed                         ( resp_code_is_failed ),                          
      .resp_code_is_adr_error                      ( resp_code_is_adr_error ),                       

      //    .cpy_rtry_xx_afutag_d                        ( cpy_rtry_xx_afutag_d[4:0] ),
      .cpy_rtry_xx_afutag_q                        ( cpy_rtry_xx_afutag_q[8:0] ),                    
      .cpy_rtry_xx_cpy_st_q                        ( cpy_rtry_xx_cpy_st_q ),      
      .cpy_rtry_xx_dl_q                            ( cpy_rtry_xx_dl_q[1:0] ),                        
      .cpy_rtry_st_size_256_q                      ( cpy_rtry_st_size_256_q ),                      
      //    .cpy_rtry_ld_ea_q                            ( cpy_rtry_ld_ea_q[63:6] ),                       
      //    .cpy_rtry_st_ea_q                            ( cpy_rtry_st_ea_q[63:6] ),

       // -- Outputs for display/debug
      .rtry_queue_func_rden_blocker                ( rtry_queue_func_rden_blocker ),                        
      .rtry_queue_rdaddr_q                         ( rtry_queue_rdaddr_q[10:0] ),                     
      .rtry_queue_wraddr_q                         ( rtry_queue_wraddr_q[10:0] ),                     
      .rtry_queue_rddata                           ( rtry_queue_rddata[17:0] ),                      
      .resp_code_rddata                            ( resp_code_rddata[3:0] )                       

    );                       

  // -- ********************************************************************************************************************************
  // -- rty_req long & rty_lwt short backoff timers 
  // -- ********************************************************************************************************************************

  mcp3_cpeng_rtry_timer  rtry_timer 
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // -- Modes/Config & Misc Inputs
      .mmio_eng_rtry_backoff_timer_disable         ( mmio_eng_rtry_backoff_timer_disable ),          
      .cfg_afu_long_backoff_timer                  ( cfg_afu_long_backoff_timer[3:0] ),              
      .cfg_afu_short_backoff_timer                 ( cfg_afu_short_backoff_timer[3:0] ),             
      .xtouch_wt4rsp_enable_q                      ( xtouch_wt4rsp_enable_q ),                       

      .rtry_queue_empty                            ( rtry_queue_empty ),                             

      // -- Idle State inputs from all of the sequencers
      .we_ld_idle_st                               ( we_ld_idle_st ),                                
      .xtouch_idle_st                              ( xtouch_idle_st ),                               
      .cpy_ld_idle_st                              ( cpy_ld_idle_st ),                               
      .cpy_st_idle_st                              ( cpy_st_idle_st ),                               
      .wkhstthrd_idle_st                           ( wkhstthrd_idle_st ),                            
      .incr_idle_st                                ( incr_idle_st ),                                 
      .atomic_idle_st                              ( atomic_idle_st ),                               
      .intrpt_idle_st                              ( intrpt_idle_st ),                               
      .we_st_idle_st                               ( we_st_idle_st ),                                

      // -- Responses that require retry with backoff
      .rspi_resp_is_we_ld_rtry_w_backoff_q         ( rspi_resp_is_we_ld_rtry_w_backoff_q ),               
      .rspi_resp_is_xtouch_source_rtry_w_backoff_q ( rspi_resp_is_xtouch_source_rtry_w_backoff_q ),       
      .rspi_resp_is_xtouch_dest_rtry_w_backoff_q   ( rspi_resp_is_xtouch_dest_rtry_w_backoff_q ),         
      .rspi_resp_is_cpy_ld_rtry_w_backoff_q        ( rspi_resp_is_cpy_ld_rtry_w_backoff_q ),              
      .rspi_resp_is_cpy_st_rtry_w_backoff_q        ( rspi_resp_is_cpy_st_rtry_w_backoff_q ),              
      .rspi_resp_is_wkhstthrd_rtry_w_backoff_q     ( rspi_resp_is_wkhstthrd_rtry_w_backoff_q ),           
      .rspi_resp_is_incr_rtry_w_backoff_q          ( rspi_resp_is_incr_rtry_w_backoff_q ),                
      .rspi_resp_is_atomic_rtry_w_backoff_q        ( rspi_resp_is_atomic_rtry_w_backoff_q ),              
      .rspi_resp_is_intrpt_rtry_w_backoff_q        ( rspi_resp_is_intrpt_rtry_w_backoff_q ),              
      .rspi_resp_is_we_st_rtry_w_backoff_q         ( rspi_resp_is_we_st_rtry_w_backoff_q ),               

      // -- Responses to determine long vs short timer
      .rspi_resp_is_rtry_req                       ( rspi_resp_is_rtry_req ),                        
      .rspi_resp_is_rtry_lwt                       ( rspi_resp_is_rtry_lwt ),                        

      // -- Outputs to the Rtry Sequencers
      .we_rtry_ld_backoff_done                     ( we_rtry_ld_backoff_done ),                      
      .xtouch_rtry_source_backoff_done             ( xtouch_rtry_source_backoff_done ),              
      .xtouch_rtry_dest_backoff_done               ( xtouch_rtry_dest_backoff_done ),                
      .cpy_rtry_ld_backoff_done                    ( cpy_rtry_ld_backoff_done ),                     
      .cpy_rtry_st_backoff_done                    ( cpy_rtry_st_backoff_done ),                     
      .wkhstthrd_rtry_backoff_done                 ( wkhstthrd_rtry_backoff_done ),                  
      .incr_rtry_backoff_done                      ( incr_rtry_backoff_done ),                       
      .atomic_rtry_backoff_done                    ( atomic_rtry_backoff_done ),                     
      .intrpt_rtry_backoff_done                    ( intrpt_rtry_backoff_done ),                     
      .we_rtry_st_backoff_done                     ( we_rtry_st_backoff_done ),                      

      .rtry_backoff_timer_disable_q                ( rtry_backoff_timer_disable_q ),
      .we_rtry_ld_backoff_done_q                   ( we_rtry_ld_backoff_done_q ),                    
      .xtouch_rtry_source_backoff_done_q           ( xtouch_rtry_source_backoff_done_q ),            
      .xtouch_rtry_dest_backoff_done_q             ( xtouch_rtry_dest_backoff_done_q ),              
      .cpy_rtry_ld_backoff_done_q                  ( cpy_rtry_ld_backoff_done_q ),                   
      .cpy_rtry_st_backoff_done_q                  ( cpy_rtry_st_backoff_done_q ),                   
      .wkhstthrd_rtry_backoff_done_q               ( wkhstthrd_rtry_backoff_done_q ),                
      .incr_rtry_backoff_done_q                    ( incr_rtry_backoff_done_q ),                     
      .atomic_rtry_backoff_done_q                  ( atomic_rtry_backoff_done_q ),                   
      .intrpt_rtry_backoff_done_q                  ( intrpt_rtry_backoff_done_q ),                   
      .we_rtry_st_backoff_done_q                   ( we_rtry_st_backoff_done_q )                    

    );                    

  // -- ********************************************************************************************************************************
  // -- retry queue and resp code array output decode 
  // -- ********************************************************************************************************************************

   afp3_eng_rtry_decode  rtry_decode
    (
      .mmio_eng_enable                             ( mmio_eng_enable ),
      .mmio_eng_resend_retries                     ( mmio_eng_resend_retries ),

      // -- Indication that latched output of the rtry queue is valid
      .rtry_queue_func_rden_dly2_q                 ( rtry_queue_func_rden_dly2_q ),                    

      // -- Latched outputs from the Retry Queue Array
      .rtry_queue_cpy_xx_q                         ( rtry_queue_cpy_xx_q ),                            
      .rtry_queue_cpy_st_q                         ( rtry_queue_cpy_st_q ),                            
      .rtry_queue_afutag_q                         ( rtry_queue_afutag_q[4:0] ),                       
      .rtry_queue_is_pending_q                     ( rtry_queue_is_pending_q ),                        
      .rtry_queue_is_rtry_lwt_q                    ( rtry_queue_is_rtry_lwt_q ),                       
      .rtry_queue_is_rtry_req_q                    ( rtry_queue_is_rtry_req_q ),                       
      .rtry_queue_is_rtry_hwt_q                    ( rtry_queue_is_rtry_hwt_q ),                       

      // -- Raw outputs from the Resp Code Array corresponding to latched rtry queue output
      .resp_code_is_done                           ( resp_code_is_done ),                            
      .resp_code_is_rty_req                        ( resp_code_is_rty_req ),                              
      .resp_code_is_failed                         ( resp_code_is_failed ),                               
      .resp_code_is_adr_error                      ( resp_code_is_adr_error ),                            

      // -- Sequencer states for qualifying rtry valids w/ afutags
      .we_ld_wt4rsp_st                             ( we_ld_wt4rsp_st ),                              
      .xtouch_wt4rsp_st                            ( xtouch_wt4rsp_st ),                             
      .cpy_ld_wt4rsp_st                            ( cpy_ld_wt4rsp_st ),                             
      .cpy_st_wt4rsp_st                            ( cpy_st_wt4rsp_st ),                             
      .wkhstthrd_wt4rsp_st                         ( wkhstthrd_wt4rsp_st ),                          
      .incr_wt4ldrsp_st                            ( incr_wt4ldrsp_st ),                             
      .incr_wt4strsp_st                            ( incr_wt4strsp_st ),                             
      .atomic_wt4rsp_st                            ( atomic_wt4rsp_st ),                             
      .intrpt_wt4rsp_st                            ( intrpt_wt4rsp_st ),                             
      .we_st_wt4rsp_st                             ( we_st_wt4rsp_st ),                              

      // -- Outputs
      .start_we_rtry_ld_seq                        ( start_we_rtry_ld_seq ),                         
      .start_xtouch_rtry_source_seq                ( start_xtouch_rtry_source_seq ),                 
      .start_xtouch_rtry_dest_seq                  ( start_xtouch_rtry_dest_seq ),                   
      .start_cpy_rtry_ld_seq                       ( start_cpy_rtry_ld_seq ),                        
      .start_cpy_rtry_st_seq                       ( start_cpy_rtry_st_seq ),                        
      .start_wkhstthrd_rtry_seq                    ( start_wkhstthrd_rtry_seq ),                     
      .start_incr_rtry_ld_seq                      ( start_incr_rtry_ld_seq ),                       
      .start_incr_rtry_st_seq                      ( start_incr_rtry_st_seq ),                       
      .start_atomic_rtry_seq                       ( start_atomic_rtry_seq ),                        
      .start_intrpt_rtry_seq                       ( start_intrpt_rtry_seq ),                        
      .start_we_rtry_st_seq                        ( start_we_rtry_st_seq ),                         

      .rtry_decode_is_hwt                          ( rtry_decode_is_hwt ),                           
      .rtry_decode_is_immediate                    ( rtry_decode_is_immediate ),                     
      .rtry_decode_is_backoff                      ( rtry_decode_is_backoff ),                       
      .rtry_decode_is_abort                        ( rtry_decode_is_abort )

    );                        

  // -- ********************************************************************************************************************************
  // -- Output Interface to cmdo 
  // -- ********************************************************************************************************************************

  // -- Group commands into 5 types:  Loads(we_ld & cpy_ld), Stores(we_st & cpy_st), Misc(actag & intrpt),
  // --   Retry Loads(we_rtry_ld & cpy_rtry_ld) and Retry Stores(we_rtry_st, cpy_rtry_st)
  // -- Gate with unlatched corresponding grant pulse from pcmd to form single cycle command
  // -- Assume that only 1 of the 5 grants from arb will be active
  // -- Combine the 3 types into a single command, latch, and drive latched cmd to pcmd module one cycle after grant

  afp3_eng_cmd_out  cmd_out
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // -- Register settings
      .mmio_eng_extra_write_mode                   ( mmio_eng_extra_write_mode ),
      .mmio_eng_mmio_lat_mode                      ( mmio_eng_mmio_lat_mode ),
      .mmio_eng_mmio_lat_mode_sz_512_st            ( mmio_eng_mmio_lat_mode_sz_512_st ),
      .mmio_eng_mmio_lat_use_reg_data              ( mmio_eng_mmio_lat_use_reg_data ),
      .mmio_eng_mmio_lat_extra_read                ( mmio_eng_mmio_lat_extra_read ),
      .mmio_eng_mmio_lat_data0                     ( mmio_eng_mmio_lat_data0[1023:0] ),
      .mmio_eng_mmio_lat_data1                     ( mmio_eng_mmio_lat_data1[1023:0] ),
      .mmio_eng_mmio_lat_data2                     ( mmio_eng_mmio_lat_data2[1023:0] ),
      .mmio_eng_mmio_lat_data3                     ( mmio_eng_mmio_lat_data3[1023:0] ),

      // -- Inbound Arbitration Requests from each sequencer
      .actag_req                                   ( actag_req ),                                    
//         .we_ld_req                                   ( we_ld_req ),                                    
//         .we_rtry_ld_req                              ( we_rtry_ld_req ),                               
      .xtouch_req                                  ( xtouch_req ),                                   
      .xtouch_rtry_req                             ( xtouch_rtry_req ),                              
//         .cpy_ld_req                                  ( cpy_ld_req ),                                   
//         .cpy_rtry_ld_req                             ( cpy_rtry_ld_req ),                              
//         .cpy_st_req                                  ( cpy_st_req ),                                   
      .cpy_rtry_st_req                             ( cpy_rtry_st_req ),                              
      .wkhstthrd_req                               ( wkhstthrd_req ),                                
      .wkhstthrd_rtry_req                          ( wkhstthrd_rtry_req ),                           
//         .incr_ld_req                                 ( incr_ld_req ),                                  
//         .incr_st_req                                 ( incr_st_req ),                                  
//         .incr_rtry_ld_req                            ( incr_rtry_ld_req ),                             
//         .incr_rtry_st_req                            ( incr_rtry_st_req ),                             
      .atomic_req                                  ( atomic_req ),                                   
      .atomic_req_w_data                           ( atomic_req_w_data ),                            
      .atomic_rtry_req                             ( atomic_rtry_req ),                              
      .atomic_rtry_req_w_data                      ( atomic_rtry_req_w_data ),                       
      .intrpt_req                                  ( intrpt_req ),                                   
      .intrpt_req_w_data                           ( intrpt_req_w_data ),                            
      .intrpt_rtry_req                             ( intrpt_rtry_req ),                              
      .intrpt_rtry_req_w_data                      ( intrpt_rtry_req_w_data ),                       
//         .we_st_req                                   ( we_st_req ),                                    
//         .we_rtry_st_req                              ( we_rtry_st_req ),                               
      .eng_display_req                             ( eng_display_req ),                              

      // -- Inbound Command Buses from each sequencer
      .actag_valid                                 ( actag_valid ),                                  
      .actag_opcode                                ( actag_opcode[7:0] ),                            
      .actag_actag                                 ( actag_actag[11:0] ),                            
      .actag_stream_id                             ( actag_stream_id[3:0] ),                         
      .actag_ea_or_obj                             ( actag_ea_or_obj[67:0] ),                        
      .actag_afutag                                ( actag_afutag[15:0] ),                           
      .actag_dl                                    ( actag_dl[1:0] ),                                
      .actag_pl                                    ( actag_pl[2:0] ),                                
      .actag_os                                    ( actag_os ),                                     
      .actag_be                                    ( actag_be[63:0] ),                               
      .actag_flag                                  ( actag_flag[3:0] ),                              
      .actag_endian                                ( actag_endian ),                                 
      .actag_bdf                                   ( actag_bdf[15:0] ),                              
//         .actag_pasid                                 ( actag_pasid[19:0] ),                            
      .actag_pg_size                               ( actag_pg_size[5:0] ),                           

      .we_ld_valid                                 ( we_ld_valid ),                                  
      .we_ld_opcode                                ( we_ld_opcode[7:0] ),                            
      .we_ld_actag                                 ( we_ld_actag[11:0] ),                            
      .we_ld_stream_id                             ( we_ld_stream_id[3:0] ),                         
      .we_ld_ea_or_obj                             ( we_ld_ea_or_obj[67:0] ),                        
      .we_ld_afutag                                ( we_ld_afutag[15:0] ),                           
      .we_ld_dl                                    ( we_ld_dl[1:0] ),                                
      .we_ld_pl                                    ( we_ld_pl[2:0] ),                                
      .we_ld_os                                    ( we_ld_os ),                                     
      .we_ld_be                                    ( we_ld_be[63:0] ),                               
      .we_ld_flag                                  ( we_ld_flag[3:0] ),                              
      .we_ld_endian                                ( we_ld_endian ),                                 
      .we_ld_bdf                                   ( we_ld_bdf[15:0] ),                              
//         .we_ld_pasid                                 ( we_ld_pasid[19:0] ),                            
      .we_ld_pg_size                               ( we_ld_pg_size[5:0] ),                           

      .xtouch_valid                                ( xtouch_valid ),                                 
      .xtouch_opcode                               ( xtouch_opcode[7:0] ),                           
      .xtouch_actag                                ( xtouch_actag[11:0] ),                           
      .xtouch_stream_id                            ( xtouch_stream_id[3:0] ),                        
      .xtouch_ea_or_obj                            ( xtouch_ea_or_obj[67:0] ),                       
      .xtouch_afutag                               ( xtouch_afutag[15:0] ),                          
      .xtouch_dl                                   ( xtouch_dl[1:0] ),                               
      .xtouch_pl                                   ( xtouch_pl[2:0] ),                               
      .xtouch_os                                   ( xtouch_os ),                                    
      .xtouch_be                                   ( xtouch_be[63:0] ),                              
      .xtouch_flag                                 ( xtouch_flag[3:0] ),                             
      .xtouch_endian                               ( xtouch_endian ),                                
      .xtouch_bdf                                  ( xtouch_bdf[15:0] ),                             
//         .xtouch_pasid                                ( xtouch_pasid[19:0] ),                           
      .xtouch_pg_size                              ( xtouch_pg_size[5:0] ),                          

      .cpy_ld_valid                                ( cpy_ld_valid ),                                 
      .cpy_ld_opcode                               ( cpy_ld_opcode[7:0] ),                           
      .cpy_ld_actag                                ( cpy_ld_actag[11:0] ),                           
      .cpy_ld_stream_id                            ( cpy_ld_stream_id[3:0] ),                        
      .cpy_ld_ea_or_obj                            ( cpy_ld_ea_or_obj[67:0] ),                       
      .cpy_ld_afutag                               ( cpy_ld_afutag[15:0] ),                          
      .cpy_ld_dl                                   ( cpy_ld_dl[1:0] ),                               
      .cpy_ld_pl                                   ( cpy_ld_pl[2:0] ),                               
      .cpy_ld_os                                   ( cpy_ld_os ),                                    
      .cpy_ld_be                                   ( cpy_ld_be[63:0] ),                              
      .cpy_ld_flag                                 ( cpy_ld_flag[3:0] ),                             
      .cpy_ld_endian                               ( cpy_ld_endian ),                                
      .cpy_ld_bdf                                  ( cpy_ld_bdf[15:0] ),                             
//         .cpy_ld_pasid                                ( cpy_ld_pasid[19:0] ),                           
      .cpy_ld_pg_size                              ( cpy_ld_pg_size[5:0] ),                          

      .cpy_st_valid                                ( cpy_st_valid ),                                 
      .cpy_st_opcode                               ( cpy_st_opcode[7:0] ),                           
      .cpy_st_actag                                ( cpy_st_actag[11:0] ),                           
      .cpy_st_stream_id                            ( cpy_st_stream_id[3:0] ),                        
      .cpy_st_ea_or_obj                            ( cpy_st_ea_or_obj[67:0] ),                       
      .cpy_st_afutag                               ( cpy_st_afutag[15:0] ),                          
      .cpy_st_dl                                   ( cpy_st_dl[1:0] ),                               
      .cpy_st_pl                                   ( cpy_st_pl[2:0] ),                               
      .cpy_st_os                                   ( cpy_st_os ),                                    
      .cpy_st_be                                   ( cpy_st_be[63:0] ),                              
      .cpy_st_flag                                 ( cpy_st_flag[3:0] ),                             
      .cpy_st_endian                               ( cpy_st_endian ),                                
      .cpy_st_bdf                                  ( cpy_st_bdf[15:0] ),                             
//         .cpy_st_pasid                                ( cpy_st_pasid[19:0] ),                           
      .cpy_st_pg_size                              ( cpy_st_pg_size[5:0] ),                          

      .wkhstthrd_valid                             ( wkhstthrd_valid ),                              
      .wkhstthrd_opcode                            ( wkhstthrd_opcode[7:0] ),                        
      .wkhstthrd_actag                             ( wkhstthrd_actag[11:0] ),                        
      .wkhstthrd_stream_id                         ( wkhstthrd_stream_id[3:0] ),                     
      .wkhstthrd_ea_or_obj                         ( wkhstthrd_ea_or_obj[67:0] ),                    
      .wkhstthrd_afutag                            ( wkhstthrd_afutag[15:0] ),                       
      .wkhstthrd_dl                                ( wkhstthrd_dl[1:0] ),                            
      .wkhstthrd_pl                                ( wkhstthrd_pl[2:0] ),                            
      .wkhstthrd_os                                ( wkhstthrd_os ),                                 
      .wkhstthrd_be                                ( wkhstthrd_be[63:0] ),                           
      .wkhstthrd_flag                              ( wkhstthrd_flag[3:0] ),                          
      .wkhstthrd_endian                            ( wkhstthrd_endian ),                             
      .wkhstthrd_bdf                               ( wkhstthrd_bdf[15:0] ),                          
//         .wkhstthrd_pasid                             ( wkhstthrd_pasid[19:0] ),                        
      .wkhstthrd_pg_size                           ( wkhstthrd_pg_size[5:0] ),                       

      .incr_ld_valid                               ( incr_ld_valid ),                                
      .incr_ld_opcode                              ( incr_ld_opcode[7:0] ),                          
      .incr_ld_actag                               ( incr_ld_actag[11:0] ),                          
      .incr_ld_stream_id                           ( incr_ld_stream_id[3:0] ),                       
      .incr_ld_ea_or_obj                           ( incr_ld_ea_or_obj[67:0] ),                      
      .incr_ld_afutag                              ( incr_ld_afutag[15:0] ),                         
      .incr_ld_dl                                  ( incr_ld_dl[1:0] ),                              
      .incr_ld_pl                                  ( incr_ld_pl[2:0] ),                              
      .incr_ld_os                                  ( incr_ld_os ),                                   
      .incr_ld_be                                  ( incr_ld_be[63:0] ),                             
      .incr_ld_flag                                ( incr_ld_flag[3:0] ),                            
      .incr_ld_endian                              ( incr_ld_endian ),                               
      .incr_ld_bdf                                 ( incr_ld_bdf[15:0] ),                            
//         .incr_ld_pasid                               ( incr_ld_pasid[19:0] ),                          
      .incr_ld_pg_size                             ( incr_ld_pg_size[5:0] ),                         

      .incr_st_valid                               ( incr_st_valid ),                                
      .incr_st_opcode                              ( incr_st_opcode[7:0] ),                          
      .incr_st_actag                               ( incr_st_actag[11:0] ),                          
      .incr_st_stream_id                           ( incr_st_stream_id[3:0] ),                       
      .incr_st_ea_or_obj                           ( incr_st_ea_or_obj[67:0] ),                      
      .incr_st_afutag                              ( incr_st_afutag[15:0] ),                         
      .incr_st_dl                                  ( incr_st_dl[1:0] ),                              
      .incr_st_pl                                  ( incr_st_pl[2:0] ),                              
      .incr_st_os                                  ( incr_st_os ),                                   
      .incr_st_be                                  ( incr_st_be[63:0] ),                             
      .incr_st_flag                                ( incr_st_flag[3:0] ),                            
      .incr_st_endian                              ( incr_st_endian ),                               
      .incr_st_bdf                                 ( incr_st_bdf[15:0] ),                            
//         .incr_st_pasid                               ( incr_st_pasid[19:0] ),                          
      .incr_st_pg_size                             ( incr_st_pg_size[5:0] ),                         

      .atomic_valid                                ( atomic_valid ),                                 
      .atomic_opcode                               ( atomic_opcode[7:0] ),                           
      .atomic_actag                                ( atomic_actag[11:0] ),                           
      .atomic_stream_id                            ( atomic_stream_id[3:0] ),                        
      .atomic_ea_or_obj                            ( atomic_ea_or_obj[67:0] ),                       
      .atomic_afutag                               ( atomic_afutag[15:0] ),                          
      .atomic_dl                                   ( atomic_dl[1:0] ),                               
      .atomic_pl                                   ( atomic_pl[2:0] ),                               
      .atomic_os                                   ( atomic_os ),                                    
      .atomic_be                                   ( atomic_be[63:0] ),                              
      .atomic_flag                                 ( atomic_flag[3:0] ),                             
      .atomic_endian                               ( atomic_endian ),                                
      .atomic_bdf                                  ( atomic_bdf[15:0] ),                             
//         .atomic_pasid                                ( atomic_pasid[19:0] ),                           
      .atomic_pg_size                              ( atomic_pg_size[5:0] ),                          

      .intrpt_valid                                ( intrpt_valid ),                                 
      .intrpt_opcode                               ( intrpt_opcode[7:0] ),                           
      .intrpt_actag                                ( intrpt_actag[11:0] ),                           
      .intrpt_stream_id                            ( intrpt_stream_id[3:0] ),                        
      .intrpt_ea_or_obj                            ( intrpt_ea_or_obj[67:0] ),                       
      .intrpt_afutag                               ( intrpt_afutag[15:0] ),                          
      .intrpt_dl                                   ( intrpt_dl[1:0] ),                               
      .intrpt_pl                                   ( intrpt_pl[2:0] ),                               
      .intrpt_os                                   ( intrpt_os ),                                    
      .intrpt_be                                   ( intrpt_be[63:0] ),                              
      .intrpt_flag                                 ( intrpt_flag[3:0] ),                             
      .intrpt_endian                               ( intrpt_endian ),                                
      .intrpt_bdf                                  ( intrpt_bdf[15:0] ),                             
//         .intrpt_pasid                                ( intrpt_pasid[19:0] ),                           
      .intrpt_pg_size                              ( intrpt_pg_size[5:0] ),                          

      .we_st_valid                                 ( we_st_valid ),                                  
      .we_st_opcode                                ( we_st_opcode[7:0] ),                            
      .we_st_actag                                 ( we_st_actag[11:0] ),                            
      .we_st_stream_id                             ( we_st_stream_id[3:0] ),                         
      .we_st_ea_or_obj                             ( we_st_ea_or_obj[67:0] ),                        
      .we_st_afutag                                ( we_st_afutag[15:0] ),                           
      .we_st_dl                                    ( we_st_dl[1:0] ),                                
      .we_st_pl                                    ( we_st_pl[2:0] ),                                
      .we_st_os                                    ( we_st_os ),                                     
      .we_st_be                                    ( we_st_be[63:0] ),                               
      .we_st_flag                                  ( we_st_flag[3:0] ),                              
      .we_st_endian                                ( we_st_endian ),                                 
      .we_st_bdf                                   ( we_st_bdf[15:0] ),                              
//         .we_st_pasid                                 ( we_st_pasid[19:0] ),                            
      .we_st_pg_size                               ( we_st_pg_size[5:0] ),                           

      .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),
      // -- Inbound Data Buses from each sequencer
//         .cpy_st_data                                 ( cpy_st_data[1023:0] ),                          
      .incr_st_data                                ( incr_st_data[511:0] ),                          
      .atomic_data                                 ( atomic_data[511:0] ),                           
      .intrpt_data                                 ( intrpt_data[511:0] ),                           
      .we_st_data                                  ( we_st_data[511:0] ),                            
      .eng_display_data                            ( eng_display_data[63:0] ),                       

      .atomic_data_valid                           ( atomic_data_valid ),                            
      .intrpt_data_valid                           ( intrpt_data_valid ),                            

      // -- Arbitration Requests to ARB (combine input arb requests and sent out to arb)
      .eng_arb_misc_req                            ( eng_arb_misc_req ),
      .eng_arb_misc_needs_extra_write              ( eng_arb_misc_needs_extra_write ),
//         .eng_arb_rtry_ld_req                         ( eng_arb_rtry_ld_req ),                          
//         .eng_arb_rtry_st_req                         ( eng_arb_rtry_st_req ),                          
      .eng_arb_rtry_misc_req                       ( eng_arb_rtry_misc_req ),                        

//         .cpy_st_size_encoded_d                       ( cpy_st_size_encoded_d[1:0] ),                   
      .rtry_queue_dl_q                             ( rtry_queue_dl_q[1:0] ),                         
      .cpy_st_size_256_q                           ( cpy_st_size_256_q ),                   
      .cpy_rtry_st_size_256_q                      ( cpy_rtry_st_size_256_q ),                   
//         .eng_display_ary_select_q                    ( eng_display_ary_select_q[1:0] ),

//         .eng_arb_st_256                              ( eng_arb_st_256 ),                               
//         .eng_arb_st_128                              ( eng_arb_st_128 ),                               
      .eng_arb_rtry_st_256                         ( eng_arb_rtry_st_256 ),                          
      .eng_arb_rtry_st_128                         ( eng_arb_rtry_st_128 ),                          
      .eng_arb_misc_w_data                         ( eng_arb_misc_w_data ),                          
      .eng_arb_rtry_misc_w_data                    ( eng_arb_rtry_misc_w_data ),                     

      // -- Arbitration Grants from ARB
      .arb_eng_ld_gnt                              ( arb_eng_ld_gnt ),                               
      .arb_eng_st_gnt                              ( arb_eng_st_gnt ),                               
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),                             
      .arb_eng_rtry_ld_gnt                         ( arb_eng_rtry_ld_gnt ),                          
      .arb_eng_rtry_st_gnt                         ( arb_eng_rtry_st_gnt ),                          
      .arb_eng_rtry_misc_gnt                       ( arb_eng_rtry_misc_gnt ),                        

      // -- Command Output signals
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

      // -- Data Output signals
      .eng_cmdo_st_valid                           ( eng_cmdo_st_valid ),                            
      .eng_cmdo_st_data                            ( eng_cmdo_st_data[1023:0] ),

      // -- Send to resp_decode for checking for valid afutag
      .cmdo_valid                                  ( cmdo_valid ),
      .cmdo_afutag                                 ( cmdo_afutag[15:0] ) 

    );
                                                                       

  // -- ********************************************************************************************************************************
  // -- Display Read Interface 
  // -- ********************************************************************************************************************************

  afp3_eng_display  display
    (
      // -- Clocks and Reset
      .clock                                       ( clock ),                                        
      .reset                                       ( reset ),                                        

      // --Modes/Config & Misc signals
      .memcpy2_format_enable_q                     ( memcpy2_format_enable_q ),                      
      .eng_num                                     ( eng_num[4:0] ),                                 

      // -- Display Interface signals
//         .weq_eng_display_rdval                       ( weq_eng_display_rdval ),                        
//         .weq_eng_wed                                 ( weq_eng_wed[25:8] ),                            
      .mmio_eng_display_rdval                      ( mmio_eng_display_rdval ),
      .mmio_eng_display_ary_select                 ( mmio_eng_display_ary_select[1:0] ),
      .mmio_eng_display_addr                       ( mmio_eng_display_addr[9:0] ),

      // -- Inputs for forming display data
      .main_state                                  ( main_state[4:0] ),                             
      .actag_state                                 ( actag_state[1:0] ),                             
      .we_ld_state                                 ( we_ld_state[3:0] ),                             
      .xtouch_state                                ( xtouch_state[3:0] ),                            
//         .cpy_ld_state                                ( cpy_ld_state[3:0] ),                            
//         .cpy_st_state                                ( cpy_st_state[3:0] ),                            
      .wkhstthrd_state                             ( wkhstthrd_state[2:0] ),                         
      .incr_state                                  ( incr_state[4:0] ),                              
      .atomic_state                                ( atomic_state[3:0] ),                            
      .intrpt_state                                ( intrpt_state[2:0] ),                            
      .we_st_state                                 ( we_st_state[2:0] ),                             
      .wr_weq_state                                ( wr_weq_state[1:0] ),                            

      .we_rtry_ld_state                            ( we_rtry_ld_state[3:0] ),                        
      .xtouch_rtry_state                           ( xtouch_rtry_state[5:0] ),                       
      .cpy_rtry_ld_state                           ( cpy_rtry_ld_state[3:0] ),                       
      .cpy_rtry_st_state                           ( cpy_rtry_st_state[4:0] ),                       
      .wkhstthrd_rtry_state                        ( wkhstthrd_rtry_state[3:0] ),                    
      .incr_rtry_state                             ( incr_rtry_state[5:0] ),                         
      .atomic_rtry_state                           ( atomic_rtry_state[3:0] ),                       
      .intrpt_rtry_state                           ( intrpt_rtry_state[3:0] ),                       
      .we_rtry_st_state                            ( we_rtry_st_state[3:0] ),                        
             
      .main_idle_st                                ( main_idle_st ),                                 
      .actag_idle_st                               ( actag_idle_st ),                                
      .we_ld_idle_st                               ( we_ld_idle_st ),                                
      .xtouch_idle_st                              ( xtouch_idle_st ),                               
      .cpy_ld_idle_st                              ( cpy_ld_idle_st ),                               
      .cpy_st_idle_st                              ( cpy_st_idle_st ),                               
      .wkhstthrd_idle_st                           ( wkhstthrd_idle_st ),                            
      .incr_idle_st                                ( incr_idle_st ),                                 
      .atomic_idle_st                              ( atomic_idle_st ),                               
      .intrpt_idle_st                              ( intrpt_idle_st ),                               
      .we_st_idle_st                               ( we_st_idle_st ),                                
      .wr_weq_idle_st                              ( wr_weq_idle_st ),                               

      .we_rtry_ld_idle_st                          ( we_rtry_ld_idle_st ),                           
      .xtouch_rtry_idle_st                         ( xtouch_rtry_idle_st ),                          
      .cpy_rtry_ld_idle_st                         ( cpy_rtry_ld_idle_st ),                          
      .cpy_rtry_st_idle_st                         ( cpy_rtry_st_idle_st ),                          
      .wkhstthrd_rtry_idle_st                      ( wkhstthrd_rtry_idle_st ),                       
      .incr_rtry_idle_st                           ( incr_rtry_idle_st ),                            
      .atomic_rtry_idle_st                         ( atomic_rtry_idle_st ),                          
      .intrpt_rtry_idle_st                         ( intrpt_rtry_idle_st ),                          
      .we_rtry_st_idle_st                          ( we_rtry_st_idle_st ),                           
               
      .we_ld_wt4rsp_st                             ( we_ld_wt4rsp_st ),                              
      .xtouch_wt4rsp_st                            ( xtouch_wt4rsp_st ),                             
      .cpy_ld_wt4rsp_st                            ( cpy_ld_wt4rsp_st ),                             
      .cpy_st_wt4rsp_st                            ( cpy_st_wt4rsp_st ),                             
      .wkhstthrd_wt4rsp_st                         ( wkhstthrd_wt4rsp_st ),                          
      .incr_wt4ldrsp_st                            ( incr_wt4ldrsp_st ),                             
      .incr_wt4strsp_st                            ( incr_wt4strsp_st ),                             
      .atomic_wt4rsp_st                            ( atomic_wt4rsp_st ),                             
      .intrpt_wt4rsp_st                            ( intrpt_wt4rsp_st ),                             
      .we_st_wt4rsp_st                             ( we_st_wt4rsp_st ),                              

//         .we_cmd_is_copy_q                            ( we_cmd_is_copy_q ),                             
      .we_cmd_is_intrpt_q                          ( we_cmd_is_intrpt_q ),                           
//         .we_cmd_is_stop_q                            ( we_cmd_is_stop_q ),                             
      .we_cmd_is_wkhstthrd_q                       ( we_cmd_is_wkhstthrd_q ),                        
//         .we_cmd_is_incr_q                            ( we_cmd_is_incr_q ),                             
//         .we_cmd_is_atomic_q                          ( we_cmd_is_atomic_q ),                           
      .we_cmd_is_atomic_ld_q                       ( we_cmd_is_atomic_ld_q ),                        
      .we_cmd_is_atomic_cas_q                      ( we_cmd_is_atomic_cas_q ),                       
      .we_cmd_is_atomic_st_q                       ( we_cmd_is_atomic_st_q ),                        
//         .we_cmd_is_xtouch_q                          ( we_cmd_is_xtouch_q ),                           

//         .we_cmd_is_undefined_q                       ( we_cmd_is_undefined_q ),                        
//         .we_cmd_length_is_zero_q                     ( we_cmd_length_is_zero_q ),                      
//         .we_cmd_is_bad_atomic_q                      ( we_cmd_is_bad_atomic_q ),                       

      .rtry_queue_func_rden_blocker                ( rtry_queue_func_rden_blocker ),                 
      .rtry_queue_rdaddr_q                         ( rtry_queue_rdaddr_q[10:0] ),                     
      .rtry_queue_wraddr_q                         ( rtry_queue_wraddr_q[10:0] ),                     
      .rtry_queue_rddata                           ( rtry_queue_rddata[17:0] ),                      
      .resp_code_rddata                            ( resp_code_rddata[3:0] ),                        
      .pending_cnt_q                               ( pending_cnt_q[4:0] ),                           
//         .eng_pe_terminate_q                          ( eng_pe_terminate_q ),                           

//         .cpy_cmd_sent_q                              ( cpy_cmd_sent_q[31:0] ),                         
//         .cpy_cmd_resp_rcvd_q                         ( cpy_cmd_resp_rcvd_q[31:0] ),                    

      .cmd_pasid_q                                 ( cmd_pasid_q[9:0] ),                            
//         .cmd_offset_q                                ( cmd_offset_q[18:5] ),                           
//         .cmd_we_ea_q                                 ( cmd_we_ea_q[63:5] ),                            
//         .cmd_we_wrap_q                               ( cmd_we_wrap_q ),                                
      .cpy_st_ea_q                                 ( cpy_st_ea_q[63:6] ),                            
      .xtouch_ea_q                                 ( xtouch_ea_q[63:0] ),

//         .we_cmd_source_ea_q                          ( we_cmd_source_ea_q[63:0] ),                     
      .we_cmd_dest_ea_q                            ( we_cmd_dest_ea_q[63:0] ),                       
      .we_cmd_atomic_op1_q                         ( we_cmd_atomic_op1_q[63:0] ),                    
// -- .we_cmd_atomic_op2_q                         ( we_cmd_atomic_op2_q[63:0] ),                    
//         .we_cmd_encode_q                             ( we_cmd_encode_q[5:0] ),                         
      .we_cmd_length_q                             ( we_cmd_length_q[15:0] ),                        
      .we_cmd_extra_q                              ( we_cmd_extra_q[7:0] ),                          
//         .we_cmd_wrap_q                               ( we_cmd_wrap_q ),                                

      // -- Signals used for collision detection to form blocker
      .start_actag_seq                             ( start_actag_seq ),                              
      .start_intrpt_seq                            ( start_intrpt_seq ),                             
      .start_xtouch_seq                            ( start_xtouch_seq ),                             
      .start_wkhstthrd_seq                         ( start_wkhstthrd_seq ),                          
      .start_atomic_seq                            ( start_atomic_seq ),                             
      .start_cpy_st_seq                            ( start_cpy_st_seq ),                             
      .start_cpy_rtry_st_seq                       ( start_cpy_rtry_st_seq ),                        

      .actag_req                                   ( actag_req ),                                    
      .intrpt_req                                  ( intrpt_req ),                                   
      .xtouch_req                                  ( xtouch_req ),                                   
      .wkhstthrd_req                               ( wkhstthrd_req ),                                
      .atomic_req                                  ( atomic_req ),                                   
//         .cpy_st_req                                  ( cpy_st_req ),                                   
      .cpy_rtry_st_req                             ( cpy_rtry_st_req ),                              

      .actag_wt4gnt_st                             ( actag_wt4gnt_st ),                              
      .intrpt_wt4gnt_st                            ( intrpt_wt4gnt_st ),                             
      .xtouch_wt4gnt1_st                           ( xtouch_wt4gnt1_st ),                             
      .xtouch_wt4gnt2_st                           ( xtouch_wt4gnt2_st ),                             
      .wkhstthrd_wt4gnt_st                         ( wkhstthrd_wt4gnt_st ),                          
      .atomic_wt4gnt_st                            ( atomic_wt4gnt_st ),                             
//         .cpy_st_wt4gnt_st                            ( cpy_st_wt4gnt_st ),                             
      .cpy_rtry_st_wt4gnt_st                       ( cpy_rtry_st_wt4gnt_st ),                        

      // -- Sequencer Outputs
      .start_eng_display_seq                       ( start_eng_display_seq ),                          
      .eng_display_idle_st                         ( eng_display_idle_st ),                          
      .eng_display_wait_st                         ( eng_display_wait_st ),                          
      .eng_display_req_st                          ( eng_display_req_st ),                           
      .eng_display_wt4gnt_st                       ( eng_display_wt4gnt_st ),                        
      .eng_display_rddataval_st                    ( eng_display_rddataval_st ),                     

      // -- Arbitration
      .eng_display_req                             ( eng_display_req ),                              
      .arb_eng_misc_gnt                            ( arb_eng_misc_gnt ),                             

      // -- Output to tell MMIO that the display data can be captured from cmdo module
      .eng_mmio_display_rddata_valid               ( eng_mmio_display_rddata_valid ),                

      // -- Output to control read of the data buffer and retry queue
      .eng_display_dbuf_rden                       ( eng_display_dbuf_rden ),                        
      .eng_display_dbuf_rden_dly1                  ( eng_display_dbuf_rden_dly1 ),                   
      .eng_display_rtry_queue_rden                 ( eng_display_rtry_queue_rden ),                        
//         .eng_display_ary_select_q                    ( eng_display_ary_select_q[1:0] ),                
      .eng_display_addr_q                          ( eng_display_addr_q[9:0] ),                      
//         .eng_display_size                            ( eng_display_size[8:6] ),
      .eng_display_data                            ( eng_display_data[63:0] )                       
                       
    );                

  // -- ********************************************************************************************************************************
  // -- Sim Idle 
  // -- ********************************************************************************************************************************

  assign  sim_idle_eng   = ( main_idle_st             &&  // -- Main Sequencer Idle

                             actag_idle_st            &&  // -- All non-retry sub-sequencers Idle
                             we_ld_idle_st            &&
                             xtouch_idle_st           &&
                             cpy_ld_idle_st           &&
                             cpy_st_idle_st           &&
                             wkhstthrd_idle_st        &&
                             incr_idle_st             &&
                             atomic_idle_st           &&
                             intrpt_idle_st           &&
                             we_st_idle_st            &&
                             wr_weq_idle_st           &&

                             we_rtry_st_idle_st       &&  // -- All retry sub-sequencers Idle          
                             intrpt_rtry_idle_st      &&
                             atomic_rtry_idle_st      &&
                             incr_rtry_idle_st        &&
                             wkhstthrd_rtry_idle_st   &&
                             cpy_rtry_st_idle_st      &&   
                             cpy_rtry_ld_idle_st      &&
                             xtouch_rtry_idle_st      &&
                             we_rtry_ld_idle_st       &&

                             eng_display_idle_st      &&  // -- Engine Display Sequencer Idle

                            ~arb_ld_gnt_q             &&  // -- No Grants currently active
                            ~arb_st_gnt_q             &&
                            ~arb_misc_gnt_q           &&
                            ~arb_rtry_ld_gnt_q        &&
                            ~arb_rtry_st_gnt_q        &&
                            ~arb_rtry_misc_gnt_q );


  // -- ********************************************************************************************************************************
  // -- Bugspray
  // -- ********************************************************************************************************************************
   
//!! Bugspray Include : afp3_eng ;


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      // -- inbound grants
      arb_ld_gnt_q                                <= arb_ld_gnt_d;                 
      arb_st_gnt_q                                <= arb_st_gnt_d;                 
      arb_misc_gnt_q                              <= arb_misc_gnt_d;               
      arb_rtry_ld_gnt_q                           <= arb_rtry_ld_gnt_d;            
      arb_rtry_st_gnt_q                           <= arb_rtry_st_gnt_d;            
      arb_rtry_misc_gnt_q                         <= arb_rtry_misc_gnt_d;            

    end // -- always @ *

endmodule
