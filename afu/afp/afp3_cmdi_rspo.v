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

module afp3_cmdi_rspo (
  
    input                 clock                                                                                                                    
  , input                 reset                                                                                                                    

  // -- TLX_AFU credit
//GFP  , input           [2:0] tlx_afu_cmd_resp_initial_credit                                                                                           
  , input           [3:0] tlx_afu_resp_initial_credit                                                                                           
//GFP  , input           [4:0] tlx_afu_data_initial_credit                                                                                              
  , input           [5:0] tlx_afu_resp_data_initial_credit                                                                                              

  // -- TLX_AFU command receive interface
  , input                 tlx_afu_ready                  // -- TLX indicates it is ready to receive cmds and responses from AFU                       
                                  
  , input                 tlx_afu_cmd_valid              // -- Command Valid (Receive)                                                                
  , input           [7:0] tlx_afu_cmd_opcode             // -- Command Opcode                                                                         
  , input          [15:0] tlx_afu_cmd_capptag            // -- Command Tag                                                                            
  , input           [1:0] tlx_afu_cmd_dl                 // -- Command Data Length                                                                    
  , input           [2:0] tlx_afu_cmd_pl                 // -- Command Partial Length                                                                 
  , input          [63:0] tlx_afu_cmd_be                 // -- Command Byte Enable                                                                    
  , input                 tlx_afu_cmd_end                // -- Endianness                                                                             
  , input          [63:0] tlx_afu_cmd_pa                 // -- Physical Address                                                                       
  , input           [3:0] tlx_afu_cmd_flag               // -- Atomic memory operation specifier                                                      
  , input                 tlx_afu_cmd_os                 // -- Ordered segment                                                                        
                                  
  , input                 tlx_afu_cmd_data_valid         // -- Command Data Valid. Indicates valid data available                                     
  , input                 tlx_afu_cmd_data_bdi           // -- Bad Data Indicator                                                                     
  , input         [511:0] tlx_afu_cmd_data_bus           // -- Command Data Bus                                                                       
                                  
  , output                afu_tlx_cmd_rd_req             // -- Command Read Request                                                                   
  , output          [2:0] afu_tlx_cmd_rd_cnt             // -- Command Read Count                                                                     
                                  
  , output                afu_tlx_cmd_credit             // -- AFU returns cmd credit to TLX                                                          
  , output          [6:0] afu_tlx_cmd_initial_credit     // -- AFU indicates number of command credits available (static value)                       

  // -- MMIO interface              
  , output                cmdi_mmio_rd                   // -- When 1, triggers a read operation that returns all 8 bytes of data from the reg        
  , output                cmdi_mmio_wr                   // -- When 1, triggers a write operation of 8 bytes                                          
  , output                cmdi_mmio_large_rd             // -- When 1, triggers a read operation that returns all 128 bytes of data from the reg        
  , output                cmdi_mmio_large_wr             // -- When 1, triggers a write operation of 128 bytes or 64 bytes
  , output          [1:0] cmdi_mmio_large_wr_half_en     // -- If bit 0 is set, write [511:0]; if bit 1 is set, write [1023:512];  if both are set, write[1023:0]
  , output         [25:0] cmdi_mmio_addr                 // -- Target address for the read or write access                                            
  , output       [1023:0] cmdi_mmio_wrdata               // -- Write data into selected config reg                                                    
  , output                cmdi_mmio_early_wr             // -- When 1, early detection of a write operation of 8 bytes                                          
  , output                cmdi_mmio_early_large_wr       // -- When 1, early_detection of a write operation of 128 bytes or 64 bytes
  , output          [1:0] cmdi_mmio_early_large_wr_half_en     // -- If bit 0 is set, write [511:0]; if bit 1 is set, write [1023:512];  if both are set, write[1023:0]
  , output         [25:0] cmdi_mmio_early_addr           // -- Target address for early write access                                            
  , input                 mmio_rspo_wr_done              // -- When observed in the proper cycle, indicates if afu_mmio_rdata has valid information   
  , input                 mmio_rspo_rddata_valid         // -- When observed in the proper cycle, indicates if afu_mmio_rdata has valid information   
  , input        [1023:0] mmio_rspo_rddata               // -- Read  data from selected config reg                                                    
  , input                 mmio_rspo_bad_op_or_align      // -- Pulsed when multiple write/read strobes are active or writes are not naturally aligned 
  , input                 mmio_rspo_addr_not_implemented // -- Pulsed when address provided is not implemented within the ACS space                                     

  // -- AFU_TLX response transmit interface
  , output                afu_tlx_resp_valid             // -- Response Valid (Transmit)                                                              
  , output          [7:0] afu_tlx_resp_opcode            // -- Response Opcode                                                                        
  , output          [1:0] afu_tlx_resp_dl                // -- Response Data Length                                                                   
  , output         [15:0] afu_tlx_resp_capptag           // -- Response Tag                                                                           
  , output          [1:0] afu_tlx_resp_dp                // -- Response Data Part - indicates the data content of the current response packet          
  , output          [3:0] afu_tlx_resp_code              // -- Response Code - reason for failed transation                                           
                                  
  , output                afu_tlx_rdata_valid            // -- Response Valid                                                                         
  , output                afu_tlx_rdata_bdi              // -- Bad command data indicator                                                             
  , output reg    [511:0] afu_tlx_rdata_bus              // -- Response Data                                                                          
                                  
  , input                 tlx_afu_resp_credit            // -- TLX returns resp credit to AFU when resp taken from FIFO by DLX                        
  , input                 tlx_afu_resp_data_credit       // -- TLX returns resp data credit to AFU when resp data taken from FIFO by DLX              


  // -- TLX_AFU Command Receive Bus Trace outputs   (MMIO requests)
//, output                trace_tlx_afu_ready

  , output                trace_tlx_afu_cmd_valid
  , output          [7:0] trace_tlx_afu_cmd_opcode
  , output         [15:0] trace_tlx_afu_cmd_capptag
//, output          [1:0] trace_tlx_afu_cmd_dl
  , output          [2:0] trace_tlx_afu_cmd_pl
//, output         [63:0] trace_tlx_afu_cmd_be
//, output                trace_tlx_afu_cmd_end
  , output         [25:0] trace_tlx_afu_cmd_pa
//, output          [3:0] trace_tlx_afu_cmd_flag
//, output                trace_tlx_afu_cmd_os

  , output                trace_tlx_afu_cmd_data_valid
  , output                trace_tlx_afu_cmd_data_bdi
  , output         [63:0] trace_tlx_afu_cmd_data_bus

  , output                trace_afu_tlx_cmd_rd_req
//, output          [2:0] trace_afu_tlx_cmd_rd_cnt

  , output                trace_afu_tlx_cmd_credit

  , output                trace_tlx_afu_mmio_rd_cmd_valid
  , output                trace_tlx_afu_mmio_wr_cmd_valid

  // -- AFU_TLX Response Transmit Bus Trace inputs   (MMIO responses)
  , output                trace_afu_tlx_resp_valid
  , output          [3:0] trace_afu_tlx_resp_opcode
  , output          [1:0] trace_afu_tlx_resp_dl
  , output         [15:0] trace_afu_tlx_resp_capptag
//, output          [1:0] trace_afu_tlx_resp_dp
  , output          [3:0] trace_afu_tlx_resp_code

  , output                trace_afu_tlx_rdata_valid
//, output                trace_afu_tlx_rdata_bdi
//, output         [63:0] trace_afu_tlx_rdata_bus

  , output                trace_tlx_afu_resp_credit
  , output                trace_tlx_afu_resp_data_credit

//GFP  , output          [2:0] trace_rspo_avail_resp_credit
  , output          [3:0] trace_rspo_avail_resp_credit
//GFP  , output          [4:0] trace_rspo_avail_data_credit
  , output          [5:0] trace_rspo_avail_data_credit


  , input         [63:20] cfg_csh_mmio_bar0                                                                                                      

  , output                sim_idle_cmdi_rspo                                                                                                       

  );


  // --****************************************************************************
  // -- Signal declarations
  // --****************************************************************************

  // -- TLX to AFU command interface
  wire            tlx_afu_pr_rd_mem_cmd;                                                                                             
  wire            tlx_afu_pr_wr_mem_cmd;
  wire            tlx_afu_write_mem_cmd;
  wire            tlx_afu_rd_mem_cmd;
  wire      [1:0] tlx_afu_cmd_type_encode;
  wire            dl_is_64_byte;
  wire            dl_is_128_byte;
  wire            pl_is_8_byte;
  wire            tlx_afu_cmd_pa_matches_bar;
  wire            new_entry_valid_lite;
  wire            new_entry_valid;
  wire            tlx_afu_mmio_rd_cmd_valid;                                                                                               
  wire            tlx_afu_mmio_wr_cmd_valid;                                                                                               
  //wire            tlx_afu_mmio_large_rd_cmd_valid;
  wire            tlx_afu_mmio_large_wr_cmd_valid;
  wire            mmio_wr_bad_op;
  wire            mmio_large_wr_bad_op;
  wire            next_mmio_rd_cmd_valid;
  wire            next_mmio_large_rd_cmd_valid;

  // -- 4-Deep command buffer
  wire            buffer_empty;
  wire            buffer_full;
  wire            buffer_error;
  wire      [3:0] set_cmdbuf_valid;

  // -- MMIO Read Sequencer
  reg       [9:0] mmio_rd_seq_sel;                                                                                                         
  reg       [6:0] mmio_rd_seq;                                                                                                             
  reg             send_mmio_rd_response_to_tlx;                                                                                            
  reg             capture_mmio_rd_data;                                                                                                    
  reg             issue_mmio_rd_req;                                                                                                       
  reg             mmio_rd_idle_st;                                                                                                         
  reg             mmio_rd_wt4rddata_st;                                                                                                  
  reg             mmio_rd_rddataval_st;                                                                                                    
  reg             mmio_rd_wt4respcredit_st;                                                                                              
  reg             mmio_rd_seq_error;                                                                                                       
  wire   [1023:0] mmio_rd_data;

  // -- MMIO Large Read Sequencer
  reg      [12:0] mmio_large_rd_seq_sel;
  reg       [8:0] mmio_large_rd_seq;
  reg             send_mmio_large_rd_data_2nd_half;
  reg             send_mmio_large_rd_response_to_tlx;
  reg             capture_mmio_large_rd_data;
  reg             issue_mmio_large_rd_req;
  reg             mmio_large_rd_idle_st;
  reg             mmio_large_rd_wt4rddata_st;
  reg             mmio_large_rd_rddataval_st;
  reg             mmio_large_rd_wt4respcredit_st;
  reg             mmio_large_rd_rddata2ndhalf_st;
  reg             mmio_large_rd_seq_error;

  // -- MMIO Write Sequencer
  //reg      [10:0] mmio_wr_seq_sel;                                                                                                         
  //reg       [7:0] mmio_wr_seq;                                                                                                             
  //reg             request_mmio_wr_data_from_tlx;                                                                                           
  //reg             early_mmio_wr_req;
  //reg             issue_mmio_wr_req;                                                                                                       
  //reg             send_mmio_wr_response_to_tlx;                                                                                            
  //reg             mmio_wr_idle_st;                                                                                                         
  //reg             mmio_wr_wt4wrdata_st;                                                                                                  
  //reg             mmio_wr_issuewrcmd_st;                                                                                                   
  //reg             mmio_wr_wt4wrresp_st;                                                                                                  
  //reg             mmio_wr_wt4respcredit_st;                                                                                              
  //reg             mmio_wr_seq_error;                                                                                                       

  // -- MMIO Large Write Sequencer
  //reg      [12:0] mmio_large_wr_seq_sel;
  //reg       [8:0] mmio_large_wr_seq;
  //reg             request_mmio_large_wr_data_from_tlx;
  //reg             early_mmio_large_wr_req;
  //reg             issue_mmio_large_wr_req;
  //reg             send_mmio_large_wr_response_to_tlx;
  //reg             mmio_large_wr_idle_st;
  //reg             mmio_large_wr_wt4wrdata_st;
  //reg             mmio_large_wr_wt4wrdata2_st;
  //reg             mmio_large_wr_issuewrcmd_st;
  //reg             mmio_large_wr_wt4wrresp_st;
  //reg             mmio_large_wr_wt4respcredit_st;
  //reg             mmio_large_wr_seq_error;
  wire            request_128_byte_data;
  wire            large_write_1st_half;
  wire            large_write_2nd_half;

  // -- Next_Wr_Data
  wire            cmdbuf_wr_data_valid;
  wire            fastpath_wr_data;
  wire            next_wr_data_valid;
  wire      [1:0] next_wr_data_cmd_type;
  wire            next_wr_data_dl_is_64_byte;
  wire            next_wr_data_dl_is_128_byte;
  wire            next_wr_data_pl_is_8_byte;
  wire     [25:0] next_wr_data_pa;
  wire            request_mmio_wr_data_from_tlx;                                                                                           
  wire            inc_cmdbuf_wr_data_ptr;
  wire      [1:0] cmdbuf_wr_data_ptr_inc;

  // -- Next_MMIO
  wire            next_mmio_cmd_valid;
  wire      [1:0] next_mmio_cmd_type;
  wire            next_mmio_dl_is_64_byte;
  wire            next_mmio_dl_is_128_byte;
  wire            next_mmio_pl_is_8_byte;
  wire     [25:0] next_mmio_pa;
  wire            next_mmio_wr_bad_op;
  wire            inc_cmdbuf_mmio_ptr;
  wire      [1:0] cmdbuf_mmio_ptr_inc;

  // -- MMIO Errors
  wire            mmio_error_raw;                                                                                                          
  wire            mmio_error;                                                                                                              
  wire            mmio_rd_error;                                                                                                           
  wire            mmio_wr_error;                                                                                                           
  wire            mmio_large_rd_error;
  wire            mmio_large_wr_error;

  // -- Track MMIO Done
  wire            decr_done_cnt;
  wire            incr_done_cnt;
  wire            done_cnt_en;
  wire      [2:0] done_cnt_sel;
  wire            done_cnt_ge_1;

  // -- Next_resp
  wire            next_resp_valid;
  wire      [1:0] next_resp_cmd_type;
  wire     [15:0] next_resp_capptag;
  wire            next_resp_dl_is_64_byte;
  wire            next_resp_dl_is_128_byte;
  wire     [25:0] next_resp_pa;
  wire            next_resp_wr_bad_op;
  wire            next_resp_bdi;
  wire            next_resp_bad_op_or_align;
  wire            next_resp_addr_not_implemented;
  wire            inc_cmdbuf_resp_ptr;
  wire            send_mmio_wr_response_to_tlx;
  wire            send_mmio_large_wr_response_to_tlx;

  // -- AFU to TLX response interface
  wire      [7:0] afu_tlx_resp_sel;
  wire            afu_tlx_resp_dl_64;
  wire            afu_tlx_resp_dl_128;

  // -- Response credit management
  wire            decr_resp_credit;                                                                                                        
  wire            incr_resp_credit;
  wire      [2:0] available_resp_credit_sel;
  wire            resp_credit_ge_1;                                                                                                        

  // -- Response data credit management
  wire            decr_data_credit;                                                                                                        
  wire            incr_data_credit;                                                                                                        
  wire      [2:0] available_data_credit_sel;
  wire            resp_data_credit_ge_1;                                                                                                   
  wire            resp_data_credit_ge_2;



  // --****************************************************************************
  // -- Latch Signal declarations (including enable signals)
  // --****************************************************************************

  // -- TLX to AFU cmd Interface
  wire            tlx_afu_ready_d;                                                                                                         
  reg             tlx_afu_ready_q;                                                                                                         

  wire            tlx_afu_cmd_valid_d;                                                                                                     
  reg             tlx_afu_cmd_valid_q;                                                                                                     

  wire            tlx_afu_cmd_xxx_en;                                                                                                      
  wire      [7:0] tlx_afu_cmd_opcode_d;                                                                                                    
  reg       [7:0] tlx_afu_cmd_opcode_q;                                                                                                    
  wire     [15:0] tlx_afu_cmd_capptag_d;                                                                                                   
  reg      [15:0] tlx_afu_cmd_capptag_q;                                                                                                   
  wire      [1:0] tlx_afu_cmd_dl_d;                                                                                                        
  reg       [1:0] tlx_afu_cmd_dl_q;                                                                                                        
  wire      [2:0] tlx_afu_cmd_pl_d;                                                                                                        
  reg       [2:0] tlx_afu_cmd_pl_q;                                                                                                        
  wire     [63:0] tlx_afu_cmd_be_d;                                                                                                        
  reg      [63:0] tlx_afu_cmd_be_q;                                                                                                        
  wire            tlx_afu_cmd_end_d;                                                                                                       
  reg             tlx_afu_cmd_end_q;                                                                                                       
  wire     [63:0] tlx_afu_cmd_pa_d;                                                                                                        
  reg      [63:0] tlx_afu_cmd_pa_q;                                                                                                        
  wire      [3:0] tlx_afu_cmd_flag_d;                                                                                                      
  reg       [3:0] tlx_afu_cmd_flag_q;                                                                                                      
  wire            tlx_afu_cmd_os_d;                                                                                                        
  reg             tlx_afu_cmd_os_q;                                                                                                        

  wire            tlx_afu_cmd_data_valid_d;                                                                                                
  reg             tlx_afu_cmd_data_valid_q;                                                                                                
  wire            tlx_afu_cmd_data_bdi_en;                                                                                                 
  wire            tlx_afu_cmd_data_bdi_d;                                                                                                  
  reg             tlx_afu_cmd_data_bdi_q;                                                                                                  
  wire            tlx_afu_cmd_data_bus_en;                                                                                                 
  wire            tlx_afu_cmd_data_large_bus0_en;
  wire            tlx_afu_cmd_data_large_bus1_en;
  reg    [1023:0] tlx_afu_cmd_data_bus_d;
  reg    [1023:0] tlx_afu_cmd_data_bus_q;

  // -- 4-Deep command buffer
  wire      [1:0] cmdbuf_wrt_ptr_d;
  reg       [1:0] cmdbuf_wrt_ptr_q;
  wire            cmdbuf0_valid_d;
  reg             cmdbuf0_valid_q;
  wire            cmdbuf0_en;
  wire      [1:0] cmdbuf0_cmd_type_d;
  reg       [1:0] cmdbuf0_cmd_type_q;
  wire     [15:0] cmdbuf0_capptag_d;
  reg      [15:0] cmdbuf0_capptag_q;
  wire            cmdbuf0_dl_is_64_byte_d;
  reg             cmdbuf0_dl_is_64_byte_q;
  wire            cmdbuf0_dl_is_128_byte_d;
  reg             cmdbuf0_dl_is_128_byte_q;
  wire            cmdbuf0_pl_is_8_byte_d;
  reg             cmdbuf0_pl_is_8_byte_q;
  wire     [25:0] cmdbuf0_pa_d;
  reg      [25:0] cmdbuf0_pa_q;
  wire            cmdbuf0_wr_bad_op_d;
  reg             cmdbuf0_wr_bad_op_q;
  wire            cmdbuf1_valid_d;
  reg             cmdbuf1_valid_q;
  wire            cmdbuf1_en;
  wire      [1:0] cmdbuf1_cmd_type_d;
  reg       [1:0] cmdbuf1_cmd_type_q;
  wire     [15:0] cmdbuf1_capptag_d;
  reg      [15:0] cmdbuf1_capptag_q;
  wire            cmdbuf1_dl_is_64_byte_d;
  reg             cmdbuf1_dl_is_64_byte_q;
  wire            cmdbuf1_dl_is_128_byte_d;
  reg             cmdbuf1_dl_is_128_byte_q;
  wire            cmdbuf1_pl_is_8_byte_d;
  reg             cmdbuf1_pl_is_8_byte_q;
  wire     [25:0] cmdbuf1_pa_d;
  reg      [25:0] cmdbuf1_pa_q;
  wire            cmdbuf1_wr_bad_op_d;
  reg             cmdbuf1_wr_bad_op_q;
  wire            cmdbuf2_valid_d;
  reg             cmdbuf2_valid_q;
  wire            cmdbuf2_en;
  wire      [1:0] cmdbuf2_cmd_type_d;
  reg       [1:0] cmdbuf2_cmd_type_q;
  wire     [15:0] cmdbuf2_capptag_d;
  reg      [15:0] cmdbuf2_capptag_q;
  wire            cmdbuf2_dl_is_64_byte_d;
  reg             cmdbuf2_dl_is_64_byte_q;
  wire            cmdbuf2_dl_is_128_byte_d;
  reg             cmdbuf2_dl_is_128_byte_q;
  wire            cmdbuf2_pl_is_8_byte_d;
  reg             cmdbuf2_pl_is_8_byte_q;
  wire     [25:0] cmdbuf2_pa_d;
  reg      [25:0] cmdbuf2_pa_q;
  wire            cmdbuf2_wr_bad_op_d;
  reg             cmdbuf2_wr_bad_op_q;
  wire            cmdbuf3_valid_d;
  reg             cmdbuf3_valid_q;
  wire            cmdbuf3_en;
  wire      [1:0] cmdbuf3_cmd_type_d;
  reg       [1:0] cmdbuf3_cmd_type_q;
  wire     [15:0] cmdbuf3_capptag_d;
  reg      [15:0] cmdbuf3_capptag_q;
  wire            cmdbuf3_dl_is_64_byte_d;
  reg             cmdbuf3_dl_is_64_byte_q;
  wire            cmdbuf3_dl_is_128_byte_d;
  reg             cmdbuf3_dl_is_128_byte_q;
  wire            cmdbuf3_pl_is_8_byte_d;
  reg             cmdbuf3_pl_is_8_byte_q;
  wire     [25:0] cmdbuf3_pa_d;
  reg      [25:0] cmdbuf3_pa_q;
  wire            cmdbuf3_wr_bad_op_d;
  reg             cmdbuf3_wr_bad_op_q;

  // -- MMIO Read Sequencer
  reg       [3:0] mmio_rd_seq_d;                                                                                                           
  reg       [3:0] mmio_rd_seq_q;                                                                                                           

  wire            send_mmio_rd_response_to_tlx_d;                                                                                           
  reg             send_mmio_rd_response_to_tlx_q;                                                                                           

  // -- MMIO Large Read Sequencer
  reg       [4:0] mmio_large_rd_seq_d;                                                                                                           
  reg       [4:0] mmio_large_rd_seq_q;                                                                                                           

  //wire            send_mmio_large_rd_response_to_tlx_d;
  //reg             send_mmio_large_rd_response_to_tlx_q;
  wire            send_mmio_large_rd_response_to_tlx_lower_d;
  reg             send_mmio_large_rd_response_to_tlx_lower_q;
  wire            send_mmio_large_rd_response_to_tlx_upper_d;
  reg             send_mmio_large_rd_response_to_tlx_upper_q;
  wire            send_mmio_large_rd_data_2nd_half_d;                                                                                           
  reg             send_mmio_large_rd_data_2nd_half_q;                                                                                           

  // -- MMIO Write Sequencer
  //reg       [4:0] mmio_wr_seq_d;                                                                                                           
  //reg       [4:0] mmio_wr_seq_q;                                                                                                           
  //wire            mmio_wr_bad_op_en;                                                                                                       
  //wire            mmio_wr_bad_op_d;                                                                                                        
  //reg             mmio_wr_bad_op_q;                                                                                                        

  // -- MMIO Large Write Sequencer
  //reg       [5:0] mmio_large_wr_seq_d;                                                                                                           
  //reg       [5:0] mmio_large_wr_seq_q;                                                                                                           
  //wire            mmio_large_wr_bad_op_en;                                                                                                       
  //wire            mmio_large_wr_bad_op_d;                                                                                                        
  //reg             mmio_large_wr_bad_op_q;                                                                                                        

  // -- Next_wr_data
  wire            wait_for_128_byte_data_d;
  reg             wait_for_128_byte_data_q;
  wire      [1:0] cmdbuf_wr_data_ptr_d;
  reg       [1:0] cmdbuf_wr_data_ptr_q;
  wire            cmdbuf_wr_data_ptr_wrap_d;
  reg             cmdbuf_wr_data_ptr_wrap_q;

  // -- Next_MMIO
  wire      [1:0] cmdbuf_mmio_ptr_d;
  reg       [1:0] cmdbuf_mmio_ptr_q;
  wire            cmdbuf_mmio_ptr_wrap_d;
  reg             cmdbuf_mmio_ptr_wrap_q;
  wire            tlx_2nd_half_d;
  reg             tlx_2nd_half_q;
  wire            issue_mmio_wr_req_d;
  reg             issue_mmio_wr_req_q;
  wire            issue_mmio_large_wr_req_d;
  reg             issue_mmio_large_wr_req_q;
  wire      [1:0] mmio_large_wr_half_en_d;
  reg       [1:0] mmio_large_wr_half_en_q;
  wire     [25:0] next_mmio_pa_d;
  reg      [25:0] next_mmio_pa_q;
  wire            cmdbuf0_bdi_d;
  reg             cmdbuf0_bdi_q;
  wire            cmdbuf1_bdi_d;
  reg             cmdbuf1_bdi_q;
  wire            cmdbuf2_bdi_d;
  reg             cmdbuf2_bdi_q;
  wire            cmdbuf3_bdi_d;
  reg             cmdbuf3_bdi_q;

  // -- MMIO interface
  wire      [1:0] cmdbuf_mmio_ptr_dly1_d;
  reg       [1:0] cmdbuf_mmio_ptr_dly1_q;
  wire      [1:0] cmdbuf_mmio_ptr_dly2_d;
  reg       [1:0] cmdbuf_mmio_ptr_dly2_q;
  wire      [1:0] cmdbuf_mmio_ptr_dly3_d;
  reg       [1:0] cmdbuf_mmio_ptr_dly3_q;
  wire            mmio_rspo_bad_op_or_align_en;                                                                                            
  wire            mmio_rspo_bad_op_or_align_d;                                                                                             
  reg             mmio_rspo_bad_op_or_align_q;                                                                                             
  wire            mmio_rspo_addr_not_implemented_en;                                                                                           
  wire            mmio_rspo_addr_not_implemented_d;                                                                                           
  reg             mmio_rspo_addr_not_implemented_q;                                                                                           
  wire            cmdbuf0_bad_op_or_align_d;
  reg             cmdbuf0_bad_op_or_align_q;
  wire            cmdbuf1_bad_op_or_align_d;
  reg             cmdbuf1_bad_op_or_align_q;
  wire            cmdbuf2_bad_op_or_align_d;
  reg             cmdbuf2_bad_op_or_align_q;
  wire            cmdbuf3_bad_op_or_align_d;
  reg             cmdbuf3_bad_op_or_align_q;
  wire            cmdbuf0_addr_not_implemented_d;
  reg             cmdbuf0_addr_not_implemented_q;
  wire            cmdbuf1_addr_not_implemented_d;
  reg             cmdbuf1_addr_not_implemented_q;
  wire            cmdbuf2_addr_not_implemented_d;
  reg             cmdbuf2_addr_not_implemented_q;
  wire            cmdbuf3_addr_not_implemented_d;
  reg             cmdbuf3_addr_not_implemented_q;

  // -- Track MMIO done
  reg       [2:0] done_cnt_d;
  reg       [2:0] done_cnt_q;

  // -- Next_resp
  wire      [1:0] cmdbuf_resp_ptr_d;
  reg       [1:0] cmdbuf_resp_ptr_q;

  // -- AFU to TLX Response Interface
  wire            afu_tlx_resp_valid_d;                                                                                                    
  reg             afu_tlx_resp_valid_q;                                                                                                    
  wire            afu_tlx_rdata_valid_d;                                                                                                   
  reg             afu_tlx_rdata_valid_q;                                                                                                   
  reg       [7:0] afu_tlx_resp_opcode_d;                                                                                                   
  reg       [7:0] afu_tlx_resp_opcode_q;                                                                                                   
  reg       [1:0] afu_tlx_resp_dl_d;                                                                                                       
  reg       [1:0] afu_tlx_resp_dl_q;                                                                                                       
  reg      [15:0] afu_tlx_resp_capptag_d;                                                                                                  
  reg      [15:0] afu_tlx_resp_capptag_q;                                                                                                  
  reg       [3:0] afu_tlx_resp_code_d;                                                                                                     
  reg       [3:0] afu_tlx_resp_code_q;                                                                                                     
  wire            afu_tlx_rdata_bdi_d;                                                                                                     
  reg             afu_tlx_rdata_bdi_q;                                                                                                     

  // -- MMIO Read Data
  wire            rd_data_en;                                                                                                              
  reg    [1023:0] rd_data_d;                                                                                                               
  reg    [1023:0] rd_data_q;                                                                                                               

  // -- Command Credit Management
  wire            return_cmd_credit_d;                                                                                                     
  reg             return_cmd_credit_q;                                                                                                     

  // -- Response Credit Management
  wire            tlx_afu_resp_credit_d;       // -- Trace array only
  reg             tlx_afu_resp_credit_q;
  wire            available_resp_credit_en;                                                                                                
//GFP  reg       [2:0] available_resp_credit_d;                                                                                                 
  reg       [3:0] available_resp_credit_d;                                                                                                 
//GFP  reg       [2:0] available_resp_credit_q;                                                                                                 
  reg       [3:0] available_resp_credit_q;                                                                                                 

  // -- Response Data Credit Management
  wire            tlx_afu_resp_data_credit_d;  // -- Trace array only
  reg             tlx_afu_resp_data_credit_q;
  wire            available_data_credit_en;                                                                                                
//GFP  reg       [4:0] available_data_credit_d;                                                                                                 
  reg       [5:0] available_data_credit_d;                                                                                                 
//GFP  reg       [4:0] available_data_credit_q;                                                                                                 
  reg       [5:0] available_data_credit_q;                                                                                                 


  // -- Sim only hook to disable bugspray events on the one-hot sequencer checks
  wire            disable_seq_error_bugspray;

  assign          disable_seq_error_bugspray = 1'b0;  // -- Default to enabled, Sim can stick to 1'b1 to disable


  // --****************************************************************************
  // -- Constant declarations
  // --****************************************************************************

  // -- TL CAPP command encodes
  localparam    [7:0] TLX_AFU_CMD_ENCODE_RETURN_ADR_TAG        = 8'b00011001;  // -- Return Address Tag                                                                     
  localparam    [7:0] TLX_AFU_CMD_ENCODE_RD_MEM                = 8'b00100000;  // -- Read Memory                                                                            
  localparam    [7:0] TLX_AFU_CMD_ENCODE_PR_RD_MEM             = 8'b00101000;  // -- Partial Memory Read                                                                    
  localparam    [7:0] TLX_AFU_CMD_ENCODE_AMO_RD                = 8'b00110000;  // -- Atomic Memory Operation - Read                                                         
  localparam    [7:0] TLX_AFU_CMD_ENCODE_AMO_RW                = 8'b00111000;  // -- Atomic Memory Operation - Read Write                                                   
  localparam    [7:0] TLX_AFU_CMD_ENCODE_AMO_W                 = 8'b01000000;  // -- Atomic Memory Operation - Write                                                        
  localparam    [7:0] TLX_AFU_CMD_ENCODE_WRITE_MEM             = 8'b10000001;  // -- Write Memory                                                                           
  localparam    [7:0] TLX_AFU_CMD_ENCODE_WRITE_MEM_BE          = 8'b10000010;  // -- Byte Enable Memory Write                                                               
  localparam    [7:0] TLX_AFU_CMD_ENCODE_PR_WR_MEM             = 8'b10000110;  // -- Partial Cache Line Memory Write                                                        
  localparam    [7:0] TLX_AFU_CMD_ENCODE_FORCE_EVICT           = 8'b11010000;  // -- Force Eviction                                                                         
  localparam    [7:0] TLX_AFU_CMD_ENCODE_WAKE_AFU_THREAD       = 8'b11011111;  // -- Wake AFU Thread                                                                        
  localparam    [7:0] TLX_AFU_CMD_ENCODE_CONFIG_READ           = 8'b11100000;  // -- Configuration Read                                                                     
  localparam    [7:0] TLX_AFU_CMD_ENCODE_CONFIG_WRITE          = 8'b11100001;  // -- Configuration Write                                                                    

  // -- TLX AP response encodes
  localparam    [7:0] AFU_TLX_RESP_ENCODE_NOP                  = 8'b00000000;  // -- Nop                                                                                    
  localparam    [7:0] AFU_TLX_RESP_ENCODE_MEM_RD_RESPONSE      = 8'b00000001;  // -- Memory Read Response                                                                   
  localparam    [7:0] AFU_TLX_RESP_ENCODE_MEM_RD_FAIL          = 8'b00000010;  // -- Memory Read Failure                                                                    
  localparam    [7:0] AFU_TLX_RESP_ENCODE_MEM_WR_RESPONSE      = 8'b00000100;  // -- Memory Write Response                                                                  
  localparam    [7:0] AFU_TLX_RESP_ENCODE_MEM_WR_FAIL          = 8'b00000101;  // -- Memory Write Failure                                                                   
  localparam    [7:0] AFU_TLX_RESP_ENCODE_RETURN_TL_CREDITS    = 8'b00001000;  // -- Return TL Credits                                                                      
  localparam    [7:0] AFU_TLX_RESP_ENCODE_WAKE_AFU_RESP        = 8'b00001010;  // -- Wake AFU Thread Response                                                               


  // -- ******************************************************************************************************************************************
  // -- Latch inbound commands from TLX (TLX clock domain)
  // -- ******************************************************************************************************************************************

  assign  tlx_afu_cmd_valid_d =  tlx_afu_cmd_valid;

  assign  tlx_afu_cmd_xxx_en =  ( tlx_afu_cmd_valid || reset );

  assign  tlx_afu_cmd_opcode_d[7:0]   =  tlx_afu_cmd_opcode[7:0];
  assign  tlx_afu_cmd_capptag_d[15:0] =  tlx_afu_cmd_capptag[15:0];
  assign  tlx_afu_cmd_dl_d[1:0]       =  tlx_afu_cmd_dl[1:0];
  assign  tlx_afu_cmd_pl_d[2:0]       =  tlx_afu_cmd_pl[2:0];
  assign  tlx_afu_cmd_be_d[63:0]      =  tlx_afu_cmd_be[63:0];
  assign  tlx_afu_cmd_end_d           =  tlx_afu_cmd_end;
  assign  tlx_afu_cmd_pa_d[63:0]      =  tlx_afu_cmd_pa[63:0];
  assign  tlx_afu_cmd_flag_d[3:0]     =  tlx_afu_cmd_flag[3:0];
  assign  tlx_afu_cmd_os_d            =  tlx_afu_cmd_os;


  // -- ******************************************************************************************************************************************
  // -- Decode the latched cmd opcode
  // -- ******************************************************************************************************************************************

  assign  tlx_afu_ready_d =  tlx_afu_ready;

  //assign  tlx_afu_pr_rd_mem_cmd_valid =  ( tlx_afu_ready_q && tlx_afu_cmd_valid_q && ( tlx_afu_cmd_opcode_q[7:0] == TLX_AFU_CMD_ENCODE_PR_RD_MEM[7:0]    ));
  assign  tlx_afu_pr_rd_mem_cmd =  ( tlx_afu_cmd_opcode_q[7:0] == TLX_AFU_CMD_ENCODE_PR_RD_MEM[7:0]    );
  assign  tlx_afu_pr_wr_mem_cmd =  ( tlx_afu_cmd_opcode_q[7:0] == TLX_AFU_CMD_ENCODE_PR_WR_MEM[7:0]    );
  assign  tlx_afu_write_mem_cmd =  ( tlx_afu_cmd_opcode_q[7:0] == TLX_AFU_CMD_ENCODE_WRITE_MEM[7:0]    );
  assign  tlx_afu_rd_mem_cmd    =  ( tlx_afu_cmd_opcode_q[7:0] == TLX_AFU_CMD_ENCODE_RD_MEM[7:0]       );

  assign  tlx_afu_cmd_type_encode[1:0]  = ((2'b00) & {2{tlx_afu_pr_rd_mem_cmd}}) |   // 00 - 8B Partial Read
                                          ((2'b01) & {2{tlx_afu_pr_wr_mem_cmd}}) |   // 01 - 8B Partial Write
                                          ((2'b10) & {2{tlx_afu_rd_mem_cmd}})    |   // 10 - Large Read
                                          ((2'b11) & {2{tlx_afu_write_mem_cmd}}) ;   // 11 - Large Write

  assign  dl_is_64_byte   =  (tlx_afu_cmd_dl_q[1:0] == 2'b01);
  assign  dl_is_128_byte  =  (tlx_afu_cmd_dl_q[1:0] == 2'b10);

  assign  pl_is_8_byte    =  (tlx_afu_cmd_pl_q[2:0] == 3'b011);

  // -- Qualify partial reads/writes with mmio_bar to determine if they are mmio operations
  // --  bit 25 determines privileged vs per process regs  (bits 24:16 give 64K offset into per process areas)
  assign  tlx_afu_cmd_pa_matches_bar  =  ( tlx_afu_cmd_pa_q[63:26] == cfg_csh_mmio_bar0[63:26] );
  assign  new_entry_valid_lite  = tlx_afu_ready_q & tlx_afu_cmd_valid_q & tlx_afu_cmd_pa_matches_bar;
  assign  new_entry_valid  = new_entry_valid_lite &
                           ( tlx_afu_pr_rd_mem_cmd | tlx_afu_pr_wr_mem_cmd | tlx_afu_write_mem_cmd | tlx_afu_rd_mem_cmd );

  assign  tlx_afu_mmio_rd_cmd_valid   =  tlx_afu_pr_rd_mem_cmd && new_entry_valid_lite;
  assign  tlx_afu_mmio_wr_cmd_valid   =  tlx_afu_pr_wr_mem_cmd && new_entry_valid_lite;
  //assign  tlx_afu_mmio_large_rd_cmd_valid   =  tlx_afu_rd_mem_cmd && new_entry_valid_lite;
  assign  tlx_afu_mmio_large_wr_cmd_valid   =  tlx_afu_write_mem_cmd && new_entry_valid_lite;

  //assign  mmio_wr_bad_op_en =  ( tlx_afu_mmio_wr_cmd_valid || send_mmio_wr_response_to_tlx || reset );
  assign  mmio_wr_bad_op    =  ( tlx_afu_mmio_wr_cmd_valid && ( tlx_afu_cmd_pl_q[2:0] != 3'b011 ));  // -- Only support 8B

  //assign  mmio_large_wr_bad_op_en =  ( tlx_afu_mmio_large_wr_cmd_valid || send_mmio_large_wr_response_to_tlx || reset );
  assign  mmio_large_wr_bad_op  =  ( tlx_afu_mmio_large_wr_cmd_valid && ( ~dl_is_64_byte ) && ( ~dl_is_128_byte ));  // -- Only support 64B & 128B

  assign  next_mmio_rd_cmd_valid  = next_mmio_cmd_valid &  (next_mmio_cmd_type == 2'b00) &  // Valid Read
                                    (cmdbuf_mmio_ptr_q[1:0] == cmdbuf_resp_ptr_q[1:0]);    // Previous commands have completed

  assign  next_mmio_large_rd_cmd_valid  = next_mmio_cmd_valid & (next_mmio_cmd_type == 2'b10) &  // Valid Large Read
                                    (cmdbuf_mmio_ptr_q[1:0] == cmdbuf_resp_ptr_q[1:0]);    // Previous commands have completed

  // -- ******************************************************************************************************************************************
  // -- 4-Deep command buffer / queue
  // -- ******************************************************************************************************************************************
  // Contents: valid, cmd_type[1:0], capptag[15:0], dl_is_64_byte, dl_is_128_byte, pl_is_8_byte, pa[25:0], wr_bad_op
  // Pointers: cmdbuf_wrt_ptr (Next entry to write to), cmdbuf_wr_data_ptr (next entry that needs write data from TLX),
  //           cmdbuf_mmio_ptr (next entry to send to MMIO), cmdbuf_resp_ptr (next entry that needs a response)


  assign  cmdbuf_wrt_ptr_d[1:0]  =  reset           ?  2'b00 :
                                    new_entry_valid ?  cmdbuf_wrt_ptr_q[1:0] + 2'b01 :
                                                       cmdbuf_wrt_ptr_q[1:0];

  assign  buffer_empty  =  ~(cmdbuf0_valid_q | cmdbuf1_valid_q | cmdbuf2_valid_q | cmdbuf3_valid_q);
  assign  buffer_full   =  cmdbuf0_valid_q & cmdbuf1_valid_q & cmdbuf2_valid_q & cmdbuf3_valid_q;
  assign  buffer_error  =  buffer_full & new_entry_valid;

  // -- Entry 0
  assign  set_cmdbuf_valid[0]  =  ((cmdbuf_wrt_ptr_q[1:0] == 2'b00) & new_entry_valid);

  assign  cmdbuf0_valid_d  =  (cmdbuf0_valid_q | set_cmdbuf_valid[0]) &
                             ~((cmdbuf_resp_ptr_q[1:0] == 2'b00) & afu_tlx_resp_valid_d) & ~reset;

  assign  cmdbuf0_en       =  reset | set_cmdbuf_valid[0];

  assign  cmdbuf0_cmd_type_d[1:0]     =  tlx_afu_cmd_type_encode[1:0];

  assign  cmdbuf0_capptag_d[15:0]     =  tlx_afu_cmd_capptag_q[15:0];
  assign  cmdbuf0_dl_is_64_byte_d     =  dl_is_64_byte;
  assign  cmdbuf0_dl_is_128_byte_d    =  dl_is_128_byte;
  assign  cmdbuf0_pl_is_8_byte_d      =  pl_is_8_byte;
  assign  cmdbuf0_pa_d[25:0]          =  tlx_afu_cmd_pa_q[25:0];
  assign  cmdbuf0_wr_bad_op_d         =  mmio_wr_bad_op | mmio_large_wr_bad_op;

  // -- Entry 1
  assign  set_cmdbuf_valid[1]  =  ((cmdbuf_wrt_ptr_q[1:0] == 2'b01) & new_entry_valid);

  assign  cmdbuf1_valid_d  =  (cmdbuf1_valid_q | set_cmdbuf_valid[1]) &
                             ~((cmdbuf_resp_ptr_q[1:0] == 2'b01) & afu_tlx_resp_valid_d) & ~reset;

  assign  cmdbuf1_en       =  reset | set_cmdbuf_valid[1];

  assign  cmdbuf1_cmd_type_d[1:0]     =  tlx_afu_cmd_type_encode[1:0];

  assign  cmdbuf1_capptag_d[15:0]     =  tlx_afu_cmd_capptag_q[15:0];
  assign  cmdbuf1_dl_is_64_byte_d     =  dl_is_64_byte;
  assign  cmdbuf1_dl_is_128_byte_d    =  dl_is_128_byte;
  assign  cmdbuf1_pl_is_8_byte_d      =  pl_is_8_byte;
  assign  cmdbuf1_pa_d[25:0]          =  tlx_afu_cmd_pa_q[25:0];
  assign  cmdbuf1_wr_bad_op_d         =  mmio_wr_bad_op | mmio_large_wr_bad_op;

  // -- Entry 2
  assign  set_cmdbuf_valid[2]  =  ((cmdbuf_wrt_ptr_q[1:0] == 2'b10) & new_entry_valid);

  assign  cmdbuf2_valid_d  =  (cmdbuf2_valid_q | set_cmdbuf_valid[2]) &
                             ~((cmdbuf_resp_ptr_q[1:0] == 2'b10) & afu_tlx_resp_valid_d) & ~reset;

  assign  cmdbuf2_en       =  reset | set_cmdbuf_valid[2];

  assign  cmdbuf2_cmd_type_d[1:0]     =  tlx_afu_cmd_type_encode[1:0];

  assign  cmdbuf2_capptag_d[15:0]     =  tlx_afu_cmd_capptag_q[15:0];
  assign  cmdbuf2_dl_is_64_byte_d     =  dl_is_64_byte;
  assign  cmdbuf2_dl_is_128_byte_d    =  dl_is_128_byte;
  assign  cmdbuf2_pl_is_8_byte_d      =  pl_is_8_byte;
  assign  cmdbuf2_pa_d[25:0]          =  tlx_afu_cmd_pa_q[25:0];
  assign  cmdbuf2_wr_bad_op_d         =  mmio_wr_bad_op | mmio_large_wr_bad_op;

  // -- Entry 3
  assign  set_cmdbuf_valid[3]  =  ((cmdbuf_wrt_ptr_q[1:0] == 2'b11) & new_entry_valid);

  assign  cmdbuf3_valid_d  =  (cmdbuf3_valid_q | set_cmdbuf_valid[3]) &
                             ~((cmdbuf_resp_ptr_q[1:0] == 2'b11) & afu_tlx_resp_valid_d) & ~reset;

  assign  cmdbuf3_en       =  reset | set_cmdbuf_valid[3];

  assign  cmdbuf3_cmd_type_d[1:0]     =  tlx_afu_cmd_type_encode[1:0];

  assign  cmdbuf3_capptag_d[15:0]     =  tlx_afu_cmd_capptag_q[15:0];
  assign  cmdbuf3_dl_is_64_byte_d     =  dl_is_64_byte;
  assign  cmdbuf3_dl_is_128_byte_d    =  dl_is_128_byte;
  assign  cmdbuf3_pl_is_8_byte_d      =  pl_is_8_byte;
  assign  cmdbuf3_pa_d[25:0]          =  tlx_afu_cmd_pa_q[25:0];
  assign  cmdbuf3_wr_bad_op_d         =  mmio_wr_bad_op | mmio_large_wr_bad_op;


  // -- ******************************************************************************************************************************************
  // -- MMIO Read Sequencer (State Machine)
  // -- ******************************************************************************************************************************************

  // -- MMIO Read Sequencer (State Machine)
  // --   Sequencer waits in Idle until a valid MMIO Read command is presented by TLX
  // --   (With the 4-deep buffer, reads are only processed one command at a time, but may come from the buffer or fastpath from TLX)
  // --     A Valid MMIO Read command meets the following criteria:
  // --       1) Partial Mem Read Cmd (ie: pr_rd_mem)
  // --       2) Partial Length is either 8B or 4B
  // --       3) The Physical Address hits in the MMIO Bar area
  // --       4) TLX is indicating to AFU that it is ready
  // --   Upon receipt of a valid MMIO Read command, an MMIO Read is issued to the MMIO sub-unit
  // --   After issuing the MMIO Read command, wait for MMIO to send a valid signifying that read data is available
  // --   Read Data is latched for use in the following cycle as sequencer advances to next state to check for response credits
  // --   If response credits (both cmd and data) are available, the latched read data from MMIO may be forwarded to TLX
  // --   If either cmd or data response credits are not available, must wait until both are available, then forward latched data to TLX
  // --   As read data is being presented to TLX, pulse the signal to return cmd credit.  (no cmd data credit exists)

  always @*
    begin

      // -- Current State Assignments
      mmio_rd_idle_st          =  mmio_rd_seq_q[0];  // -- State 0 - mmio_rd_idle_st
      mmio_rd_wt4rddata_st     =  mmio_rd_seq_q[1];  // -- State 1 - mmio_rd_wt4rddata_st
      mmio_rd_rddataval_st     =  mmio_rd_seq_q[2];  // -- State 2 - mmio_rd_rddataval_st
      mmio_rd_wt4respcredit_st =  mmio_rd_seq_q[3];  // -- State 3 - mmio_rd_wt4respcredit_st

      // -- Determine if the Current State of the Sequencer is invalid
      mmio_rd_seq_error = ( mmio_rd_seq_q[3:0] == 4'b0 )           ||  // -- Error - No State Active
                          ( mmio_rd_seq_q[3] && mmio_rd_seq_q[2] ) ||  // -- Error - More than 1 State Active
                          ( mmio_rd_seq_q[3] && mmio_rd_seq_q[1] ) ||  // -- Error - More than 1 State Active
                          ( mmio_rd_seq_q[3] && mmio_rd_seq_q[0] ) ||  // -- Error - More than 1 State Active
                          ( mmio_rd_seq_q[2] && mmio_rd_seq_q[1] ) ||  // -- Error - More than 1 State Active
                          ( mmio_rd_seq_q[2] && mmio_rd_seq_q[0] ) ||  // -- Error - More than 1 State Active
                          ( mmio_rd_seq_q[1] && mmio_rd_seq_q[0] );    // -- Error - More than 1 State Active
      // -- Inputs
      mmio_rd_seq_sel[9:0] = { next_mmio_rd_cmd_valid, mmio_rspo_rddata_valid, mmio_error_raw, mmio_error, resp_credit_ge_1, resp_data_credit_ge_1, mmio_rd_seq_q[3:0] };

      casez ( mmio_rd_seq_sel[9:0] )

        // -- next_mmio_rd_cmd_valid
        // -- |mmio_rspo_rddata_valid
        // -- ||mmio_error_raw               
        // -- |||mmio_error                         issue_mmio_rd_req
        // -- ||||resp_credit_ge_1                  |capture_mmio_rd_data
        // -- |||||resp_data_credit_ge_1            ||send_mmio_rd_response_to_tlx
        // -- ||||||                                |||
        // -- |||||| mmio_rd_seq_q                  ||| mmio_rd_seq_d  
        // -- |||||| |                              ||| |
        // -- 987654 3210                           654 3210
        // ---------------------------------------------------
          10'b0?????_0001 :  mmio_rd_seq[6:0] =  7'b000_0001 ;  // -- No Valid mmio Read Cmd
          10'b1?????_0001 :  mmio_rd_seq[6:0] =  7'b100_0010 ;  // -- Valid mmio Read Cmd
        // ---------------------------------------------------
          10'b??????_0010 :  mmio_rd_seq[6:0] =  7'b000_0100 ;  // -- 
        // ---------------------------------------------------
          10'b?00???_0100 :  mmio_rd_seq[6:0] =  7'b000_0100 ;  // -- 
          10'b?10???_0100 :  mmio_rd_seq[6:0] =  7'b010_1000 ;  // -- 
          10'b??1???_0100 :  mmio_rd_seq[6:0] =  7'b000_1000 ;  // -- 
        // ---------------------------------------------------
          10'b???00?_1000 :  mmio_rd_seq[6:0] =  7'b000_1000 ;  // -- Have Read Data, no response credits
          10'b???010_1000 :  mmio_rd_seq[6:0] =  7'b000_1000 ;  // -- Have Read Data, no data response credits            // -- LINT: 10'b???0?0_1000 -> 10'b???010_1000
          10'b???011_1000 :  mmio_rd_seq[6:0] =  7'b001_0001 ;  // -- Have Read Data, and both response and data credit
          10'b???10?_1000 :  mmio_rd_seq[6:0] =  7'b000_1000 ;  // -- Error, No Read Data, no response credit
          10'b???11?_1000 :  mmio_rd_seq[6:0] =  7'b001_0001 ;  // -- Error, No Read Data, have response credit
        // ---------------------------------------------------
          default         :  mmio_rd_seq[6:0] =  7'b000_0001 ;  // -- No Valid mmio Read Cmd
        // ---------------------------------------------------
      endcase

      // -- Outputs
      issue_mmio_rd_req            =  mmio_rd_seq[6];
      capture_mmio_rd_data         =  mmio_rd_seq[5];
      send_mmio_rd_response_to_tlx =  mmio_rd_seq[4];

      // -- Next State
      mmio_rd_seq_d[3:0] =  ( reset || mmio_rd_seq_error ) ? 4'b1 :  mmio_rd_seq[3:0];

    end // -- always @ *                                  


  // -- ******************************************************************************************************************************************
  // -- MMIO Large Read Sequencer (State Machine)
  // -- ******************************************************************************************************************************************

  // -- MMIO Large Read Sequencer (State Machine)
  // --   Sequencer waits in Idle until a valid MMIO Large Read command is presented by TLX
  // --   (With the 4-deep buffer, reads are only processed one command at a time, but may come from the buffer or fastpath from TLX)
  // --     A Valid MMIO Large Read command meets the following criteria:
  // --       1) Mem Read Cmd (ie: rd_mem)
  // --       2) Data Length is either 128B or 64B
  // --       3) The Physical Address hits in the MMIO Bar area
  // --       4) TLX is indicating to AFU that it is ready
  // --   Upon receipt of a valid MMIO Large Read command, an MMIO Large Read is issued to the MMIO sub-unit
  // --   After issuing the MMIO Large Read command, wait for MMIO to send a valid signifying that read data is available
  // --   Read Data is latched for use in the following cycle as sequencer advances to next state to check for response credits
  // --   If response credits (both cmd and data) are available, the latched read data from MMIO may be forwarded to TLX
  // --   If either cmd or data response credits are not available, must wait until both are available, then forward latched data to TLX
  // --   As read data is being presented to TLX, pulse the signal to return cmd credit.  (no cmd data credit exists)

  always @*
    begin

      // -- Current State Assignments
      mmio_large_rd_idle_st          =  mmio_large_rd_seq_q[0];  // -- State 0 - mmio_large_rd_idle_st
      mmio_large_rd_wt4rddata_st     =  mmio_large_rd_seq_q[1];  // -- State 1 - mmio_large_rd_wt4rddata_st
      mmio_large_rd_rddataval_st     =  mmio_large_rd_seq_q[2];  // -- State 2 - mmio_large_rd_rddataval_st
      mmio_large_rd_wt4respcredit_st =  mmio_large_rd_seq_q[3];  // -- State 3 - mmio_large_rd_wt4respcredit_st
      mmio_large_rd_rddata2ndhalf_st =  mmio_large_rd_seq_q[4];  // -- State 4 - mmio_large_rd_rddata2ndhalf_st

      // -- Determine if the Current State of the Sequencer is invalid
      mmio_large_rd_seq_error = ( mmio_large_rd_seq_q[4:0] == 5'b0 )           ||  // -- Error - No State Active
                                ( mmio_large_rd_seq_q[4] && mmio_large_rd_seq_q[3] ) ||  // -- Error - More than 1 State Active
                                ( mmio_large_rd_seq_q[4] && mmio_large_rd_seq_q[2] ) ||  // -- Error - More than 1 State Active
                                ( mmio_large_rd_seq_q[4] && mmio_large_rd_seq_q[1] ) ||  // -- Error - More than 1 State Active
                                ( mmio_large_rd_seq_q[4] && mmio_large_rd_seq_q[0] ) ||  // -- Error - More than 1 State Active
                                ( mmio_large_rd_seq_q[3] && mmio_large_rd_seq_q[2] ) ||  // -- Error - More than 1 State Active
                                ( mmio_large_rd_seq_q[3] && mmio_large_rd_seq_q[1] ) ||  // -- Error - More than 1 State Active
                                ( mmio_large_rd_seq_q[3] && mmio_large_rd_seq_q[0] ) ||  // -- Error - More than 1 State Active
                                ( mmio_large_rd_seq_q[2] && mmio_large_rd_seq_q[1] ) ||  // -- Error - More than 1 State Active
                                ( mmio_large_rd_seq_q[2] && mmio_large_rd_seq_q[0] ) ||  // -- Error - More than 1 State Active
                                ( mmio_large_rd_seq_q[1] && mmio_large_rd_seq_q[0] );    // -- Error - More than 1 State Active
      // -- Inputs
      mmio_large_rd_seq_sel[12:0] = { next_mmio_large_rd_cmd_valid, mmio_rspo_rddata_valid, mmio_error_raw, mmio_error, resp_credit_ge_1, resp_data_credit_ge_1, resp_data_credit_ge_2, next_resp_dl_is_128_byte, mmio_large_rd_seq_q[4:0] };

      casez ( mmio_large_rd_seq_sel[12:0] )

        // -- next_mmio_large_rd_cmd_valid
        // -- |mmio_rspo_rddata_valid
        // -- ||mmio_error_raw               
        // -- |||mmio_error                                  issue_mmio_large_rd_req
        // -- ||||resp_credit_ge_1                           |capture_mmio_large_rd_data
        // -- |||||resp_data_credit_ge_1                     ||send_mmio_large_rd_response_to_tlx
        // -- ||||||resp_data_credit_ge_2                    |||send_mmio_large_rd_data_2nd_half
        // -- |||||||next_resp_dl_is_128_byte                ||||
        // -- ||||||||                                       ||||
        // -- |||||||| mmio_large_rd_seq_q                   |||| mmio_large_rd_seq_d  
        // -- 111||||| |                                     |||| |
        // -- 21098765 43210                                 8765 43210
        // --------------------------------------------------------------
          13'b0???????_00001 :  mmio_large_rd_seq[8:0] =  9'b0000_00001 ;  // -- No Valid mmio Read Cmd
          13'b1???????_00001 :  mmio_large_rd_seq[8:0] =  9'b1000_00010 ;  // -- Valid mmio Read Cmd
        // --------------------------------------------------------------
          13'b????????_00010 :  mmio_large_rd_seq[8:0] =  9'b0000_00100 ;  // -- 
        // --------------------------------------------------------------
          13'b?00?????_00100 :  mmio_large_rd_seq[8:0] =  9'b0000_00100 ;  // -- 
          13'b?10?????_00100 :  mmio_large_rd_seq[8:0] =  9'b0100_01000 ;  // -- 
          13'b??1?????_00100 :  mmio_large_rd_seq[8:0] =  9'b0000_01000 ;  // -- 
        // --------------------------------------------------------------
          13'b???00???_01000 :  mmio_large_rd_seq[8:0] =  9'b0000_01000 ;  // -- Have Read Data, no response credits
          13'b???010??_01000 :  mmio_large_rd_seq[8:0] =  9'b0000_01000 ;  // -- Have Read Data, no data response credits            // -- LINT:  13'b???0?0??_01000 -> 13'b???010??_01000
          13'b???0??01_01000 :  mmio_large_rd_seq[8:0] =  9'b0000_01000 ;  // -- Have Read Data, not enough data response credits, 128B
          13'b???011?0_01000 :  mmio_large_rd_seq[8:0] =  9'b0010_00001 ;  // -- Have Read Data, and both response and data credit, 64B
          13'b???01?11_01000 :  mmio_large_rd_seq[8:0] =  9'b0010_10000 ;  // -- Have Read Data, and both response and data credit, 128B
          13'b???10???_01000 :  mmio_large_rd_seq[8:0] =  9'b0000_01000 ;  // -- Error, No Read Data, no response credit
          13'b???11???_01000 :  mmio_large_rd_seq[8:0] =  9'b0010_00001 ;  // -- Error, No Read Data, have response credit
        // --------------------------------------------------------------
          13'b????????_10000 :  mmio_large_rd_seq[8:0] =  9'b0001_00001 ;  // -- Send 2nd half of data for 128B Read
        // --------------------------------------------------------------
          default            :  mmio_large_rd_seq[8:0] =  9'b0000_00001 ;  // -- No Valid mmio Read Cmd
        // --------------------------------------------------------------
      endcase

      // -- Outputs
      issue_mmio_large_rd_req            =  mmio_large_rd_seq[8];
      capture_mmio_large_rd_data         =  mmio_large_rd_seq[7];
      send_mmio_large_rd_response_to_tlx =  mmio_large_rd_seq[6];
      send_mmio_large_rd_data_2nd_half   =  mmio_large_rd_seq[5];

      // -- Next State
      mmio_large_rd_seq_d[4:0] =  ( reset || mmio_large_rd_seq_error ) ? 5'b1 :  mmio_large_rd_seq[4:0];

    end // -- always @ *                                  

/*
 IMPLEMENTED DIFFERENTLY for 4-buffer solution
  // -- ******************************************************************************************************************************************
  // -- MMIO Write Sequencer (State Machine)
  // -- ******************************************************************************************************************************************

  // -- MMIO Write Sequencer (State Machine)
  // --   Sequencer waits in Idle until a valid MMIO Write command is presented by TLX
  // --     A Valid MMIO Write command meets the following criteria:
  // --       1) Partial Mem Write Cmd (ie: pr_wr_mem)
  // --       2) Partial Length is either 8B or 4B
  // --       3) The Physical Address hits in the MMIO Bar area
  // --       4) TLX is indicating to AFU that it is ready
  // --   Upon receipt of a valid MMIO Write command, a 64B Read Request is issued to TLX to obtain the write data
  // --   After issuing the Read request to TLX, wait for TLX to send data valid signifying that Write data is available - latch it
  // --   After receiving the data valid from TLX, translate data from Little Endian to Big Endian, select proper 4 or 8B of data and issue MMIO Write Command to AFP
  // --   After issuing the MMIO Write command to AFP, wait for AFP to send an ack signifying that it has completed 
  // --   If response credit is available, then issue command response to TLX
  // --   As response command is being presented to TLX, pulse the signal to return cmd and cmd data credits.


  // -- These are the signals used as inputs to the MMIO Read Sequencer
  always @*
    begin

      // -- Current State Assignments
      mmio_wr_idle_st          =  mmio_wr_seq_q[0];  // -- State 0 - mmio_wr_idle_st         
      mmio_wr_wt4wrdata_st     =  mmio_wr_seq_q[1];  // -- State 1 - mmio_wr_wt4wrdata_st    
      mmio_wr_issuewrcmd_st    =  mmio_wr_seq_q[2];  // -- State 2 - mmio_wr_issuewrcmd_st   
      mmio_wr_wt4wrresp_st     =  mmio_wr_seq_q[3];  // -- State 3 - mmio_wr_wt4wrresp_st    
      mmio_wr_wt4respcredit_st =  mmio_wr_seq_q[4];  // -- State 4 - mmio_wr_wt4respcredit_st

      // -- Determine if the Current State of the Sequencer is invalid
      mmio_wr_seq_error = ( mmio_wr_seq_q[4:0] == 5'b0 )           ||  // -- Error - No State Active
                          ( mmio_wr_seq_q[4] && mmio_wr_seq_q[3] ) ||  // -- Error - More than 1 State Active
                          ( mmio_wr_seq_q[4] && mmio_wr_seq_q[2] ) ||  // -- Error - More than 1 State Active
                          ( mmio_wr_seq_q[4] && mmio_wr_seq_q[1] ) ||  // -- Error - More than 1 State Active
                          ( mmio_wr_seq_q[4] && mmio_wr_seq_q[0] ) ||  // -- Error - More than 1 State Active
                          ( mmio_wr_seq_q[3] && mmio_wr_seq_q[2] ) ||  // -- Error - More than 1 State Active
                          ( mmio_wr_seq_q[3] && mmio_wr_seq_q[1] ) ||  // -- Error - More than 1 State Active
                          ( mmio_wr_seq_q[3] && mmio_wr_seq_q[0] ) ||  // -- Error - More than 1 State Active
                          ( mmio_wr_seq_q[2] && mmio_wr_seq_q[1] ) ||  // -- Error - More than 1 State Active
                          ( mmio_wr_seq_q[2] && mmio_wr_seq_q[0] ) ||  // -- Error - More than 1 State Active
                          ( mmio_wr_seq_q[1] && mmio_wr_seq_q[0] );    // -- Error - More than 1 State Active
      // -- Inputs
      mmio_wr_seq_sel[10:0] = { tlx_afu_mmio_wr_cmd_valid, tlx_afu_cmd_data_valid, tlx_afu_cmd_data_bdi, mmio_wr_bad_op_q, mmio_rspo_wr_done, resp_credit_ge_1, mmio_wr_seq_q[4:0] };

      casez ( mmio_wr_seq_sel[10:0] )
        // --
        // -- tlx_afu_mmio_wr_cmd_valid
        // -- |tlx_afu_cmd_data_valid
        // -- ||tlx_afu_cmd_data_bdi    
        // -- |||mmio_wr_bad_op_q                    request_mmio_wr_data_from_tlx
        // -- ||||mmio_rspo_wr_done                  |issue_mmio_wr_req
        // -- |||||resp_credit_ge_1                  ||send_mmio_wr_response_to_tlx
        // -- ||||||                                 |||
        // -- |||||| mmio_wr_seq_q                   ||| mmio_wr_seq_d  
        // -- 1||||| |                               ||| |
        // -- 098765 43210                           765 43210
        // -----------------------------------------------------
          11'b0?????_00001 :  mmio_wr_seq[7:0] =  8'b000_00001 ;  // -- No Valid MMIO Write Cmd
          11'b1?????_00001 :  mmio_wr_seq[7:0] =  8'b100_00010 ;  // -- Valid MMIO Write Cmd
        // -----------------------------------------------------
          11'b?0????_00010 :  mmio_wr_seq[7:0] =  8'b000_00010 ;  // -- No Data, continue waiting
          11'b?100??_00010 :  mmio_wr_seq[7:0] =  8'b000_00100 ;  // -- Data, send latched data next cycle
          11'b?11??0_00010 :  mmio_wr_seq[7:0] =  8'b000_10000 ;  // -- Bad Data Indicator, Do NOT issue Write Req to MMIO
          11'b?101?0_00010 :  mmio_wr_seq[7:0] =  8'b000_10000 ;  // -- Bad Op, Do NOT issue Write Req to MMIO                // -- LINT:  11'b?1?1?0_00010 ->  11'b?101?0_00010
          11'b?11??1_00010 :  mmio_wr_seq[7:0] =  8'b001_00001 ;  // -- Bad Data Indicator, Do NOT issue Write Req to MMIO
          11'b?101?1_00010 :  mmio_wr_seq[7:0] =  8'b001_00001 ;  // -- Bad Op, Do NOT issue Write Req to MMIO                // -- LINT:  11'b?1?1?1_00010 ->  11'b?101?1_00010
        // -----------------------------------------------------
          11'b??????_00100 :  mmio_wr_seq[7:0] =  8'b010_01000 ;  // -- Send Write Cmd & Data to MMIO sub-unit
        // -----------------------------------------------------
          11'b????0?_01000 :  mmio_wr_seq[7:0] =  8'b000_01000 ;  // -- Wait for MMIO sub-unit to indicate Done
          11'b????10_01000 :  mmio_wr_seq[7:0] =  8'b000_10000 ;  // -- MMIO sub-unit done, no response credit
          11'b????11_01000 :  mmio_wr_seq[7:0] =  8'b001_00001 ;  // -- MMIO sub-unit done, have response credit
        // -----------------------------------------------------
          11'b?????0_10000 :  mmio_wr_seq[7:0] =  8'b000_10000 ;  // -- No response credit
          11'b?????1_10000 :  mmio_wr_seq[7:0] =  8'b001_00001 ;  // -- Response credit
        // -----------------------------------------------------
          default          :  mmio_wr_seq[7:0] =  8'b000_00001 ;  // -- No Valid MMIO Write Cmd
        // -----------------------------------------------------
      endcase

      // -- Outputs
      request_mmio_wr_data_from_tlx =  mmio_wr_seq[7];
      early_mmio_wr_req             =  mmio_wr_seq[7];  // For MMIO ping-pong test.  Can start processing as data is fetched from TLX
      issue_mmio_wr_req             =  mmio_wr_seq[6];
      send_mmio_wr_response_to_tlx  =  mmio_wr_seq[5];

      // -- Next State
      mmio_wr_seq_d[4:0] =  ( reset || mmio_wr_seq_error ) ? 5'b1 :  mmio_wr_seq[4:0];

    end // -- always @ *                                  


  // -- ******************************************************************************************************************************************
  // -- MMIO Large Write Sequencer (State Machine)
  // -- ******************************************************************************************************************************************

  // -- MMIO Large Write Sequencer (State Machine)
  // --   Sequencer waits in Idle until a valid MMIO Large Write command is presented by TLX
  // --     A Valid MMIO Large Write command meets the following criteria:
  // --       1) Write Mem Cmd (ie: write_mem)
  // --       2) Data Length is either 128B or 64B
  // --       3) The Physical Address hits in the MMIO Bar area
  // --       4) TLX is indicating to AFU that it is ready
  // --   Upon receipt of a valid MMIO Large Write command, a 64B or 128B Read Request is issued to TLX to obtain the write data
  // --   After issuing the Read request to TLX, wait for TLX to send data valid signifying that Write data is available - latch it.  Two beats of data are needed for 128B writes.
  // --   After receiving the data valid from TLX, translate data from Little Endian to Big Endian, and issue MMIO Large Write Command to AFP MMIO
  // --   After issuing the MMIO Write command to AFP, wait for AFP to send an ack signifying that it has completed 
  // --   If response credit is available, then issue command response to TLX
  // --   As response command is being presented to TLX, pulse the signal to return cmd and cmd data credits.


  always @*
    begin

      // -- Current State Assignments
      mmio_large_wr_idle_st          =  mmio_large_wr_seq_q[0];  // -- State 0 - mmio_large_wr_idle_st         
      mmio_large_wr_wt4wrdata_st     =  mmio_large_wr_seq_q[1];  // -- State 1 - mmio_large_wr_wt4wrdata_st  (1st half of 128B data)
      mmio_large_wr_wt4wrdata2_st    =  mmio_large_wr_seq_q[2];  // -- State 2 - mmio_large_wr_wt4wrdata2_st (2nd half of 128B data or all of 64B data)
      mmio_large_wr_issuewrcmd_st    =  mmio_large_wr_seq_q[3];  // -- State 3 - mmio_large_wr_issuewrcmd_st   
      mmio_large_wr_wt4wrresp_st     =  mmio_large_wr_seq_q[4];  // -- State 4 - mmio_large_wr_wt4wrresp_st    
      mmio_large_wr_wt4respcredit_st =  mmio_large_wr_seq_q[5];  // -- State 5 - mmio_large_wr_wt4respcredit_st

      // -- Determine if the Current State of the Sequencer is invalid
      mmio_large_wr_seq_error = ( mmio_large_wr_seq_q[5:0] == 6'b0 )           ||  // -- Error - No State Active
                          ( mmio_large_wr_seq_q[5] && mmio_large_wr_seq_q[4] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[5] && mmio_large_wr_seq_q[3] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[5] && mmio_large_wr_seq_q[2] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[5] && mmio_large_wr_seq_q[1] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[5] && mmio_large_wr_seq_q[0] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[4] && mmio_large_wr_seq_q[3] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[4] && mmio_large_wr_seq_q[2] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[4] && mmio_large_wr_seq_q[1] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[4] && mmio_large_wr_seq_q[0] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[3] && mmio_large_wr_seq_q[2] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[3] && mmio_large_wr_seq_q[1] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[3] && mmio_large_wr_seq_q[0] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[2] && mmio_large_wr_seq_q[1] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[2] && mmio_large_wr_seq_q[0] ) ||  // -- Error - More than 1 State Active
                          ( mmio_large_wr_seq_q[1] && mmio_large_wr_seq_q[0] );    // -- Error - More than 1 State Active
      // -- Inputs
      mmio_large_wr_seq_sel[12:0] = { tlx_afu_mmio_large_wr_cmd_valid, dl_is_128_byte, tlx_afu_cmd_data_valid, tlx_afu_cmd_data_bdi, mmio_large_wr_bad_op_q, mmio_rspo_wr_done, resp_credit_ge_1, mmio_large_wr_seq_q[5:0] };

      casez ( mmio_large_wr_seq_sel[12:0] )
        // --
        // -- tlx_afu_mmio_large_wr_cmd_valid
        // -- |dl_is_128_byte
        // -- ||tlx_afu_cmd_data_valid
        // -- |||tlx_afu_cmd_data_bdi    
        // -- ||||mmio_large_wr_bad_op_q                     request_mmio_large_wr_data_from_tlx
        // -- |||||mmio_rspo_wr_done                         |issue_mmio_large_wr_req
        // -- ||||||resp_credit_ge_1                         ||send_mmio_large_wr_response_to_tlx
        // -- |||||||                                        |||
        // -- ||||||| mmio_large_wr_seq_q                    ||| mmio_large_wr_seq_d  
        // -- 111|||| |                                      ||| |
        // -- 2109876 543210                                 876 543210
        // --------------------------------------------------------------
          13'b0??????_000001 :  mmio_large_wr_seq[8:0] =  9'b000_000001 ;  // -- No Valid Large MMIO Write Cmd
          13'b10?????_000001 :  mmio_large_wr_seq[8:0] =  9'b100_000100 ;  // -- Valid Large MMIO Write Cmd - 64B
          13'b11?????_000001 :  mmio_large_wr_seq[8:0] =  9'b100_000010 ;  // -- Valid Large MMIO Write Cmd - 128B
        // --------------------------------------------------------------
          13'b??0????_000010 :  mmio_large_wr_seq[8:0] =  9'b000_000010 ;  // -- No Data, continue waiting
          13'b??100??_000010 :  mmio_large_wr_seq[8:0] =  9'b000_000100 ;  // -- Data for 1st half of 128B, wait for 2nd half
          13'b??11??0_000010 :  mmio_large_wr_seq[8:0] =  9'b000_100000 ;  // -- Bad Data Indicator, Do NOT issue Write Req to MMIO
          13'b??101?0_000010 :  mmio_large_wr_seq[8:0] =  9'b000_100000 ;  // -- Bad Op, Do NOT issue Write Req to MMIO                // -- LINT: 13'b??1?1?0_000010 -> 13'b??101?0_000010
          13'b??11??1_000010 :  mmio_large_wr_seq[8:0] =  9'b001_000001 ;  // -- Bad Data Indicator, Do NOT issue Write Req to MMIO
          13'b??101?1_000010 :  mmio_large_wr_seq[8:0] =  9'b001_000001 ;  // -- Bad Op, Do NOT issue Write Req to MMIO                // -- LINT: 13'b??1?1?1_000010 -> 13'b??101?1_000010
        // --------------------------------------------------------------
          13'b??0????_000100 :  mmio_large_wr_seq[8:0] =  9'b000_000100 ;  // -- No Data, continue waiting
          13'b??100??_000100 :  mmio_large_wr_seq[8:0] =  9'b000_001000 ;  // -- Data (for 2nd half of 128B, or all of 64B data), send latched data next cycle
          13'b??11??0_000100 :  mmio_large_wr_seq[8:0] =  9'b000_100000 ;  // -- Bad Data Indicator, Do NOT issue Write Req to MMIO
          13'b??101?0_000100 :  mmio_large_wr_seq[8:0] =  9'b000_100000 ;  // -- Bad Op, Do NOT issue Write Req to MMIO                // -- LINT: 13'b??1?1?0_000100 -> 13'b??101?0_000100
          13'b??11??1_000100 :  mmio_large_wr_seq[8:0] =  9'b001_000001 ;  // -- Bad Data Indicator, Do NOT issue Write Req to MMIO
          13'b??101?1_000100 :  mmio_large_wr_seq[8:0] =  9'b001_000001 ;  // -- Bad Op, Do NOT issue Write Req to MMIO                // -- LINT: 13'b??1?1?1_000100 -> 13'b??101?1_000100
        // --------------------------------------------------------------
          13'b???????_001000 :  mmio_large_wr_seq[8:0] =  9'b010_010000 ;  // -- Send Write Cmd & Data to MMIO sub-unit
        // --------------------------------------------------------------
          13'b?????0?_010000 :  mmio_large_wr_seq[8:0] =  9'b000_010000 ;  // -- Wait for MMIO sub-unit to indicate Done
          13'b?????10_010000 :  mmio_large_wr_seq[8:0] =  9'b000_100000 ;  // -- MMIO sub-unit done, no response credit
          13'b?????11_010000 :  mmio_large_wr_seq[8:0] =  9'b001_000001 ;  // -- MMIO sub-unit done, have response credit
        // --------------------------------------------------------------
          13'b??????0_100000 :  mmio_large_wr_seq[8:0] =  9'b000_100000 ;  // -- No response credit
          13'b??????1_100000 :  mmio_large_wr_seq[8:0] =  9'b001_000001 ;  // -- Response credit
        // --------------------------------------------------------------
          default            :  mmio_large_wr_seq[8:0] =  9'b000_000001 ;  // -- No Valid MMIO Write Cmd
        // --------------------------------------------------------------
      endcase

      // -- Outputs
      request_mmio_large_wr_data_from_tlx =  mmio_large_wr_seq[8];
      early_mmio_large_wr_req             =  mmio_large_wr_seq[8];  // For MMIO ping-pong test.  Can start processing as data is fetched from TLX
      issue_mmio_large_wr_req             =  mmio_large_wr_seq[7];
      send_mmio_large_wr_response_to_tlx  =  mmio_large_wr_seq[6];

      // -- Next State
      mmio_large_wr_seq_d[5:0] =  ( reset || mmio_large_wr_seq_error ) ? 6'b1 :  mmio_large_wr_seq[5:0];

    end // -- always @ *                                  

  assign  dl_is_64_byte   =  (tlx_afu_cmd_dl_q[1:0] == 2'b01);
  assign  dl_is_128_byte  =  (tlx_afu_cmd_dl_q[1:0] == 2'b10);
  assign  request_128_byte_data  = request_mmio_large_wr_data_from_tlx & dl_is_128_byte;

  assign  large_write_1st_half  = ( ( dl_is_128_byte && mmio_large_wr_wt4wrdata_st )  || ( dl_is_64_byte  && (tlx_afu_cmd_pa_q[6] == 1'b0) ) );   // Note: does not include data_valid
  assign  large_write_2nd_half  = ( ( dl_is_128_byte && mmio_large_wr_wt4wrdata2_st ) || ( dl_is_64_byte  && (tlx_afu_cmd_pa_q[6] == 1'b1) ) );   // Note: does not include data_valid
*/
  // -- ******************************************************************************************************************************************
  // -- Issue a 64B or 128B Read Request to TLX to Pull the MMIO Write Data from TLX
  // -- ******************************************************************************************************************************************
  // Select info for next command
  assign  cmdbuf_wr_data_valid  = ( (cmdbuf_wr_data_ptr_q == 2'b00)  & cmdbuf0_valid_q )  |
                                  ( (cmdbuf_wr_data_ptr_q == 2'b01)  & cmdbuf1_valid_q )  |
                                  ( (cmdbuf_wr_data_ptr_q == 2'b10)  & cmdbuf2_valid_q )  |
                                  ( (cmdbuf_wr_data_ptr_q == 2'b11)  & cmdbuf3_valid_q );

  assign  fastpath_wr_data    = new_entry_valid & ~cmdbuf_wr_data_valid;

  assign  next_wr_data_valid  =  (cmdbuf_wr_data_valid | fastpath_wr_data)  & ~(cmdbuf_wr_data_ptr_wrap_q) ;

  assign  next_wr_data_cmd_type[1:0]  =  fastpath_wr_data  ?  tlx_afu_cmd_type_encode[1:0] :
                                       // else not fastpath_wr_data
                                       ( ( {2{(cmdbuf_wr_data_ptr_q == 2'b00)}}  & cmdbuf0_cmd_type_q[1:0] )  |
                                         ( {2{(cmdbuf_wr_data_ptr_q == 2'b01)}}  & cmdbuf1_cmd_type_q[1:0] )  |
                                         ( {2{(cmdbuf_wr_data_ptr_q == 2'b10)}}  & cmdbuf2_cmd_type_q[1:0] )  |
                                         ( {2{(cmdbuf_wr_data_ptr_q == 2'b11)}}  & cmdbuf3_cmd_type_q[1:0] ) );

  assign  next_wr_data_dl_is_64_byte =  fastpath_wr_data  ?  dl_is_64_byte  :
                                          // else not fastpath_wr_data
                                       ( ( (cmdbuf_wr_data_ptr_q == 2'b00)  & cmdbuf0_dl_is_64_byte_q )  |
                                         ( (cmdbuf_wr_data_ptr_q == 2'b01)  & cmdbuf0_dl_is_64_byte_q )  |
                                         ( (cmdbuf_wr_data_ptr_q == 2'b10)  & cmdbuf0_dl_is_64_byte_q )  |
                                         ( (cmdbuf_wr_data_ptr_q == 2'b11)  & cmdbuf0_dl_is_64_byte_q ) );

  assign  next_wr_data_dl_is_128_byte =  fastpath_wr_data  ?  dl_is_128_byte  :
                                          // else not fastpath_wr_data
                                       ( ( (cmdbuf_wr_data_ptr_q == 2'b00)  & cmdbuf0_dl_is_128_byte_q )  |
                                         ( (cmdbuf_wr_data_ptr_q == 2'b01)  & cmdbuf0_dl_is_128_byte_q )  |
                                         ( (cmdbuf_wr_data_ptr_q == 2'b10)  & cmdbuf0_dl_is_128_byte_q )  |
                                         ( (cmdbuf_wr_data_ptr_q == 2'b11)  & cmdbuf0_dl_is_128_byte_q ) );

  assign  next_wr_data_pl_is_8_byte   =  fastpath_wr_data  ?  pl_is_8_byte :
                                          // else not fastpath_wr_data
                                         ( (cmdbuf_wr_data_ptr_q == 2'b00)  & cmdbuf0_pl_is_8_byte_q )  |
                                         ( (cmdbuf_wr_data_ptr_q == 2'b01)  & cmdbuf0_pl_is_8_byte_q )  |
                                         ( (cmdbuf_wr_data_ptr_q == 2'b10)  & cmdbuf0_pl_is_8_byte_q )  |
                                         ( (cmdbuf_wr_data_ptr_q == 2'b11)  & cmdbuf0_pl_is_8_byte_q ) ;

  assign  next_wr_data_pa[25:0]     =  fastpath_wr_data  ?  tlx_afu_cmd_pa_q[25:0] :
                                          // else not fastpath_wr_data
                                     ( ( {26{(cmdbuf_wr_data_ptr_q == 2'b00)}}  & cmdbuf0_pa_q[25:0] )  |
                                       ( {26{(cmdbuf_wr_data_ptr_q == 2'b01)}}  & cmdbuf1_pa_q[25:0] )  |
                                       ( {26{(cmdbuf_wr_data_ptr_q == 2'b10)}}  & cmdbuf2_pa_q[25:0] )  |
                                       ( {26{(cmdbuf_wr_data_ptr_q == 2'b11)}}  & cmdbuf3_pa_q[25:0] ) );

  // 8B write or large write
  assign  request_mmio_wr_data_from_tlx  =  mmio_rd_idle_st & mmio_large_rd_idle_st &    // Wait for any pending reads to finish
                                            ~wait_for_128_byte_data_q &                  // Wait an extra cycle for 2-cycle data fetches
                                            next_wr_data_valid & (next_wr_data_cmd_type[0] == 1'b1);  // Valid write

  assign  request_128_byte_data  = (next_wr_data_cmd_type[1:0] == 2'b11)  & next_wr_data_dl_is_128_byte;

  assign  wait_for_128_byte_data_d  = request_mmio_wr_data_from_tlx & request_128_byte_data;

  assign  inc_cmdbuf_wr_data_ptr  =  request_mmio_wr_data_from_tlx |
                                     issue_mmio_rd_req | issue_mmio_large_rd_req;     // Reads do not fetch data from TLX, so advance pointer when sending rd command to mmio

  assign  cmdbuf_wr_data_ptr_inc[1:0] =  cmdbuf_wr_data_ptr_q[1:0] + 2'b01;
  assign  cmdbuf_wr_data_ptr_d[1:0] =  reset                  ?  2'b00 :
                                       inc_cmdbuf_wr_data_ptr ?  cmdbuf_wr_data_ptr_inc[1:0] :
                                                                 cmdbuf_wr_data_ptr_q[1:0];

  assign  cmdbuf_wr_data_ptr_wrap_d  =  (cmdbuf_wr_data_ptr_wrap_q | (inc_cmdbuf_wr_data_ptr & (cmdbuf_wr_data_ptr_inc[1:0] == cmdbuf_resp_ptr_q[1:0]))) &
                                        buffer_full & ~inc_cmdbuf_resp_ptr & ~reset;

  //assign  afu_tlx_cmd_rd_req      =  request_mmio_wr_data_from_tlx | request_mmio_large_wr_data_from_tlx;
  assign  afu_tlx_cmd_rd_req      =  request_mmio_wr_data_from_tlx;    // 8B write or large write
  assign  afu_tlx_cmd_rd_cnt[2:0] =  request_128_byte_data ? 3'b010 : 3'b001;


  // -- ******************************************************************************************************************************************
  // -- Latch the Write Data from TLX
  // -- ******************************************************************************************************************************************

  assign  tlx_afu_cmd_data_valid_d = tlx_afu_cmd_data_valid;

  assign  tlx_afu_cmd_data_bus_en =  ( (tlx_afu_cmd_data_valid & ~tlx_afu_cmd_data_large_bus1_en) || reset );
  //assign  tlx_afu_cmd_data_large_bus0_en =  ( (tlx_afu_cmd_data_valid && ~mmio_large_wr_idle_st && large_write_1st_half) || reset );
  //assign  tlx_afu_cmd_data_large_bus1_en =  ( (tlx_afu_cmd_data_valid && ~mmio_large_wr_idle_st && large_write_2nd_half) || reset );
  assign  tlx_afu_cmd_data_large_bus0_en =  ( (tlx_afu_cmd_data_valid && (next_mmio_cmd_type[1] == 1'b1) && large_write_1st_half) || reset );
  assign  tlx_afu_cmd_data_large_bus1_en =  ( (tlx_afu_cmd_data_valid && (next_mmio_cmd_type[1] == 1'b1) && large_write_2nd_half) || reset );

  always @*
    begin
     if (next_mmio_cmd_type[1:0] == 2'b01)  // Data is from normal MMIO write
     begin
      case ( next_mmio_pa[5:3] )
        3'b111 :  tlx_afu_cmd_data_bus_d[63:0] =  tlx_afu_cmd_data_bus[511:448];
        3'b110 :  tlx_afu_cmd_data_bus_d[63:0] =  tlx_afu_cmd_data_bus[447:384];
        3'b101 :  tlx_afu_cmd_data_bus_d[63:0] =  tlx_afu_cmd_data_bus[383:320];
        3'b100 :  tlx_afu_cmd_data_bus_d[63:0] =  tlx_afu_cmd_data_bus[319:256];
        3'b011 :  tlx_afu_cmd_data_bus_d[63:0] =  tlx_afu_cmd_data_bus[255:192];
        3'b010 :  tlx_afu_cmd_data_bus_d[63:0] =  tlx_afu_cmd_data_bus[191:128];
        3'b001 :  tlx_afu_cmd_data_bus_d[63:0] =  tlx_afu_cmd_data_bus[127:64] ;
        3'b000 :  tlx_afu_cmd_data_bus_d[63:0] =  tlx_afu_cmd_data_bus[63:0]   ;
      endcase
     end // if
     else  // Data is from large MMIO write
     begin
       tlx_afu_cmd_data_bus_d[63:0]    =  tlx_afu_cmd_data_bus[63:0];   // Note: uses tlx_afu_cmd_data_en  clock enable
     end

     tlx_afu_cmd_data_bus_d[511:64]   =  tlx_afu_cmd_data_bus[511:64];  // Note: uses tlx_afu_cmd_data_large_bus0_en  clock enable
     tlx_afu_cmd_data_bus_d[1023:512] =  tlx_afu_cmd_data_bus[511:0];   // Note: uses tlx_afu_cmd_data_large_bus1_en  clock enable

    end // -- always @ *                                  

  assign  tlx_afu_cmd_data_bdi_en =  ( tlx_afu_cmd_data_valid || reset );  //tlx_afu_cmd_data_bus_en;
  assign  tlx_afu_cmd_data_bdi_d  =  tlx_afu_cmd_data_bdi;


  // -- ******************************************************************************************************************************************
  // -- Select next command to MMIO logic
  // -- ******************************************************************************************************************************************
  // *** NOTE:  For writes, the MMIO pointer is incremented a cycle before the command is sent to the MMIO sub-unit, and the address, etc. is
  //     latched.  This allows us to also use the mmio_ptr for capturing the write data, and cmdi_mmio_addr is almost off a latch, for better timing
  // mmio_ptr can used for the cycle wr_data is returned, since there is no back pressure from MMIO sub-unit, so the next command to MMIO is the one getting
  // the next data

  assign  next_mmio_cmd_valid   = (( (buffer_empty)                & new_entry_valid )  |   // MMIO fastpath, only happens for reads
                                   ( (cmdbuf_mmio_ptr_q == 2'b00)  & cmdbuf0_valid_q )  |
                                   ( (cmdbuf_mmio_ptr_q == 2'b01)  & cmdbuf1_valid_q )  |
                                   ( (cmdbuf_mmio_ptr_q == 2'b10)  & cmdbuf2_valid_q )  |
                                   ( (cmdbuf_mmio_ptr_q == 2'b11)  & cmdbuf3_valid_q )) &
                                  ~(cmdbuf_mmio_ptr_wrap_q);

  assign  next_mmio_cmd_type[1:0]  =  buffer_empty  ?  tlx_afu_cmd_type_encode[1:0] :
                                     // else not buffer_empty
                                      ( ( {2{(cmdbuf_mmio_ptr_q == 2'b00)}}  & cmdbuf0_cmd_type_q[1:0] )  |
                                        ( {2{(cmdbuf_mmio_ptr_q == 2'b01)}}  & cmdbuf1_cmd_type_q[1:0] )  |
                                        ( {2{(cmdbuf_mmio_ptr_q == 2'b10)}}  & cmdbuf2_cmd_type_q[1:0] )  |
                                        ( {2{(cmdbuf_mmio_ptr_q == 2'b11)}}  & cmdbuf3_cmd_type_q[1:0] ) );

  assign  next_mmio_dl_is_64_byte  =  buffer_empty  ?  dl_is_64_byte :
                                     // else not buffer_empty
                                      ( ( (cmdbuf_mmio_ptr_q == 2'b00)  & cmdbuf0_dl_is_64_byte_q )  |
                                        ( (cmdbuf_mmio_ptr_q == 2'b01)  & cmdbuf1_dl_is_64_byte_q )  |
                                        ( (cmdbuf_mmio_ptr_q == 2'b10)  & cmdbuf2_dl_is_64_byte_q )  |
                                        ( (cmdbuf_mmio_ptr_q == 2'b11)  & cmdbuf3_dl_is_64_byte_q ) );

  assign  next_mmio_dl_is_128_byte =  buffer_empty  ?  dl_is_128_byte :
                                     // else not buffer_empty
                                      ( ( (cmdbuf_mmio_ptr_q == 2'b00)  & cmdbuf0_dl_is_128_byte_q )  |
                                        ( (cmdbuf_mmio_ptr_q == 2'b01)  & cmdbuf1_dl_is_128_byte_q )  |
                                        ( (cmdbuf_mmio_ptr_q == 2'b10)  & cmdbuf2_dl_is_128_byte_q )  |
                                        ( (cmdbuf_mmio_ptr_q == 2'b11)  & cmdbuf3_dl_is_128_byte_q ) );

  assign  next_mmio_pl_is_8_byte =  buffer_empty  ?  pl_is_8_byte :
                                     // else not buffer_empty
                                      ( ( (cmdbuf_mmio_ptr_q == 2'b00)  & cmdbuf0_pl_is_8_byte_q )  |
                                        ( (cmdbuf_mmio_ptr_q == 2'b01)  & cmdbuf1_pl_is_8_byte_q )  |
                                        ( (cmdbuf_mmio_ptr_q == 2'b10)  & cmdbuf2_pl_is_8_byte_q )  |
                                        ( (cmdbuf_mmio_ptr_q == 2'b11)  & cmdbuf3_pl_is_8_byte_q ) );

  assign  next_mmio_pa[25:0]     =  buffer_empty  ?  tlx_afu_cmd_pa_q[25:0] :
                                     // else not buffer_empty
                                    ( ( {26{(cmdbuf_mmio_ptr_q == 2'b00)}}  & cmdbuf0_pa_q[25:0] )  |
                                      ( {26{(cmdbuf_mmio_ptr_q == 2'b01)}}  & cmdbuf1_pa_q[25:0] )  |
                                      ( {26{(cmdbuf_mmio_ptr_q == 2'b10)}}  & cmdbuf2_pa_q[25:0] )  |
                                      ( {26{(cmdbuf_mmio_ptr_q == 2'b11)}}  & cmdbuf3_pa_q[25:0] ) );

  assign  next_mmio_wr_bad_op    =  //( (buffer_empty)                & (mmio_wr_bad_op | mmio_large_wr_bad_op ))  |  // MMIO fastpath only happens for reads
                                    ( (cmdbuf_mmio_ptr_q == 2'b00)  & cmdbuf0_wr_bad_op_q )  |
                                    ( (cmdbuf_mmio_ptr_q == 2'b01)  & cmdbuf1_wr_bad_op_q )  |
                                    ( (cmdbuf_mmio_ptr_q == 2'b10)  & cmdbuf2_wr_bad_op_q )  |
                                    ( (cmdbuf_mmio_ptr_q == 2'b11)  & cmdbuf3_wr_bad_op_q ) ;


  assign  inc_cmdbuf_mmio_ptr  =  issue_mmio_rd_req | issue_mmio_wr_req_d |
                                  issue_mmio_large_rd_req | issue_mmio_large_wr_req_d |
                                  (tlx_afu_cmd_data_valid & tlx_afu_cmd_data_bdi);   // Don't send to MMIO when bdi

  assign  cmdbuf_mmio_ptr_inc[1:0]  =  cmdbuf_mmio_ptr_q[1:0] + 2'b01;
  assign  cmdbuf_mmio_ptr_d[1:0]  =  reset                  ?  2'b00 :
                                     inc_cmdbuf_mmio_ptr    ?  cmdbuf_mmio_ptr_inc :
                                                               cmdbuf_mmio_ptr_q[1:0];

  assign  cmdbuf_mmio_ptr_wrap_d  =  (cmdbuf_mmio_ptr_wrap_q | (inc_cmdbuf_mmio_ptr & (cmdbuf_mmio_ptr_inc[1:0] == cmdbuf_resp_ptr_q[1:0]))) &
                                     buffer_full & ~inc_cmdbuf_resp_ptr & ~reset;


  assign  tlx_2nd_half_d  = tlx_afu_cmd_data_valid & next_mmio_dl_is_128_byte & (next_mmio_cmd_type[1] == 1'b1) & ~tlx_2nd_half_q;

  assign  large_write_1st_half  = ( ( next_mmio_dl_is_128_byte && ~tlx_2nd_half_q )  || ( next_mmio_dl_is_64_byte  && (next_mmio_pa[6] == 1'b0) ) );   // Note: does not include data_valid
  assign  large_write_2nd_half  = ( ( next_mmio_dl_is_128_byte &&  tlx_2nd_half_q )  || ( next_mmio_dl_is_64_byte  && (next_mmio_pa[6] == 1'b1) ) );   // Note: does not include data_valid

  // Send MMIO cycle after we have data
  assign  issue_mmio_wr_req_d        =  tlx_afu_cmd_data_valid & ~tlx_afu_cmd_data_bdi & ~next_mmio_wr_bad_op & (next_mmio_cmd_type[1:0] == 2'b01) & next_mmio_pl_is_8_byte;
  assign  issue_mmio_large_wr_req_d  =  tlx_afu_cmd_data_valid & ~tlx_afu_cmd_data_bdi & ~next_mmio_wr_bad_op & (next_mmio_cmd_type[1:0] == 2'b11) & ~tlx_2nd_half_d;    // Don't set if we still need 2nd half of 128B data
  assign  mmio_large_wr_half_en_d[1] =  next_mmio_dl_is_128_byte  || ( next_mmio_dl_is_64_byte && (next_mmio_pa[6]==1'b1) );
  assign  mmio_large_wr_half_en_d[0] =  next_mmio_dl_is_128_byte  || ( next_mmio_dl_is_64_byte && (next_mmio_pa[6]==1'b0) );

  assign  next_mmio_pa_d[25:0] = next_mmio_pa[25:0];

  assign  cmdbuf0_bdi_d  =  (cmdbuf_mmio_ptr_q == 2'b00)  & tlx_afu_cmd_data_valid & tlx_afu_cmd_data_bdi &     // Set
                            ~reset & cmdbuf0_valid_q;                      // Clear
  assign  cmdbuf1_bdi_d  =  (cmdbuf_mmio_ptr_q == 2'b01)  & tlx_afu_cmd_data_valid & tlx_afu_cmd_data_bdi &     // Set
                            ~reset & cmdbuf1_valid_q;                      // Clear
  assign  cmdbuf2_bdi_d  =  (cmdbuf_mmio_ptr_q == 2'b10)  & tlx_afu_cmd_data_valid & tlx_afu_cmd_data_bdi &     // Set
                            ~reset & cmdbuf2_valid_q;                      // Clear
  assign  cmdbuf3_bdi_d  =  (cmdbuf_mmio_ptr_q == 2'b11)  & tlx_afu_cmd_data_valid & tlx_afu_cmd_data_bdi &     // Set
                            ~reset & cmdbuf3_valid_q;                      // Clear

  // -- ******************************************************************************************************************************************
  // -- simple rename
  // -- ******************************************************************************************************************************************

  assign  mmio_rd_data[1023:0] =  mmio_rspo_rddata[1023:0];


  // -- ******************************************************************************************************************************************
  // -- Interface to MMIO Logic
  // -- ******************************************************************************************************************************************

  assign  cmdi_mmio_rd =    issue_mmio_rd_req;
  assign  cmdi_mmio_wr =    issue_mmio_wr_req_q;
  assign  cmdi_mmio_large_rd =  issue_mmio_large_rd_req;
  assign  cmdi_mmio_large_wr =  issue_mmio_large_wr_req_q;
  assign  cmdi_mmio_large_wr_half_en[1:0] =  mmio_large_wr_half_en_q[1:0];

  assign  cmdi_mmio_addr[25:0] =  buffer_empty  ? tlx_afu_cmd_pa_q[25:0] :   // Read fastpath
                                                  next_mmio_pa_q[25:0] ;     // Reads could use non-latched version, but this works for reads, since mmio_ptr was incremented cycles before previous command completed, so mmio_pa is steady for several cycles before we send new read to mmio

  // Send early write signals once we start fetching data from TLX
  assign  cmdi_mmio_early_wr =  request_mmio_wr_data_from_tlx & (next_wr_data_cmd_type[1:0] == 2'b01) & next_wr_data_pl_is_8_byte ;
  assign  cmdi_mmio_early_large_wr  =  request_mmio_wr_data_from_tlx & ( next_wr_data_cmd_type[1:0] == 2'b11 );
  assign  cmdi_mmio_early_large_wr_half_en[1] =  next_wr_data_dl_is_128_byte  || ( next_wr_data_dl_is_64_byte && (next_wr_data_pa[6]==1'b1) );
  assign  cmdi_mmio_early_large_wr_half_en[0] =  next_wr_data_dl_is_128_byte  || ( next_wr_data_dl_is_64_byte && (next_wr_data_pa[6]==1'b0) );
  assign  cmdi_mmio_early_addr[25:0] =  next_wr_data_pa[25:0];

  // -- mmio Write Data
  assign  cmdi_mmio_wrdata[1023:0] =  tlx_afu_cmd_data_bus_q[1023:0];

  // This is for capturing mmio errors for writes
  assign  cmdbuf_mmio_ptr_dly1_d[1:0]  =  cmdbuf_mmio_ptr_q[1:0];
  assign  cmdbuf_mmio_ptr_dly2_d[1:0]  =  cmdbuf_mmio_ptr_dly1_q[1:0];
  assign  cmdbuf_mmio_ptr_dly3_d[1:0]  =  cmdbuf_mmio_ptr_dly2_q[1:0];

  // -- These Errors are valid 2 clocks after valid presented - just capture anytime rd or wr sequencer is NOT idle, clear when returning to idle
  assign  mmio_rspo_bad_op_or_align_en      =  ( mmio_rd_rddataval_st || send_mmio_rd_response_to_tlx ||
                                                 mmio_large_rd_rddataval_st ||
                                                 send_mmio_large_rd_response_to_tlx ||
                                                 (next_resp_valid & (next_resp_cmd_type[0] == 1'b1)) || reset );
  assign  mmio_rspo_addr_not_implemented_en =    mmio_rspo_bad_op_or_align_en;

  assign  mmio_rspo_bad_op_or_align_d      =  mmio_rspo_bad_op_or_align;
  assign  mmio_rspo_addr_not_implemented_d =  mmio_rspo_addr_not_implemented;

  assign  mmio_error_raw =  ( mmio_rspo_bad_op_or_align   || mmio_rspo_addr_not_implemented );    
  assign  mmio_error     =  ( mmio_rspo_bad_op_or_align_q || mmio_rspo_addr_not_implemented_q );
  assign  mmio_rd_error  =  ( ~mmio_rd_idle_st &&  mmio_error );
  assign  mmio_wr_error  =  ( next_resp_wr_bad_op || next_resp_bdi || next_resp_bad_op_or_align || next_resp_addr_not_implemented );  // Don't need to look at valid or cmd_type because it's used with send_mmio_wr_response_to_tlx
  assign  mmio_large_rd_error  =  ( ~mmio_large_rd_idle_st &&  mmio_error );
  assign  mmio_large_wr_error  =  mmio_wr_error;

  assign  cmdbuf0_bad_op_or_align_d  =  (((cmdbuf_mmio_ptr_dly3_q == 2'b00) & mmio_rd_idle_st & mmio_large_rd_idle_st) | ((cmdbuf_resp_ptr_q == 2'b00) & (mmio_rd_idle_st | mmio_large_rd_idle_st))) &  // Writes: use mmio_dly3, reads: use resp_ptr, since only process one at a time
                            mmio_rspo_bad_op_or_align_en & mmio_rspo_bad_op_or_align &     // Set
                            ~reset & cmdbuf0_valid_q;                      // Clear
  assign  cmdbuf1_bad_op_or_align_d  =  (((cmdbuf_mmio_ptr_dly3_q == 2'b01) & mmio_rd_idle_st & mmio_large_rd_idle_st) | ((cmdbuf_resp_ptr_q == 2'b01) & (mmio_rd_idle_st | mmio_large_rd_idle_st))) &  // Writes: use mmio_dly3, reads: use resp_ptr, since only process one at a time
                            mmio_rspo_bad_op_or_align_en & mmio_rspo_bad_op_or_align &     // Set
                            ~reset & cmdbuf1_valid_q;                      // Clear
  assign  cmdbuf2_bad_op_or_align_d  =  (((cmdbuf_mmio_ptr_dly3_q == 2'b10) & mmio_rd_idle_st & mmio_large_rd_idle_st) | ((cmdbuf_resp_ptr_q == 2'b10) & (mmio_rd_idle_st | mmio_large_rd_idle_st))) &  // Writes: use mmio_dly3, reads: use resp_ptr, since only process one at a time
                            mmio_rspo_bad_op_or_align_en & mmio_rspo_bad_op_or_align &     // Set
                            ~reset & cmdbuf2_valid_q;                      // Clear
  assign  cmdbuf3_bad_op_or_align_d  =  (((cmdbuf_mmio_ptr_dly3_q == 2'b11) & mmio_rd_idle_st & mmio_large_rd_idle_st) | ((cmdbuf_resp_ptr_q == 2'b11) & (mmio_rd_idle_st | mmio_large_rd_idle_st))) &  // Writes: use mmio_dly3, reads: use resp_ptr, since only process one at a time
                            mmio_rspo_bad_op_or_align_en & mmio_rspo_bad_op_or_align &     // Set
                            ~reset & cmdbuf3_valid_q;                      // Clear

  assign  cmdbuf0_addr_not_implemented_d  =  (((cmdbuf_mmio_ptr_dly3_q == 2'b00) & mmio_rd_idle_st & mmio_large_rd_idle_st) | ((cmdbuf_resp_ptr_q == 2'b00) & (mmio_rd_idle_st | mmio_large_rd_idle_st))) &  // Writes: use mmio_dly3, reads: use resp_ptr, since only process one at a time
                            mmio_rspo_addr_not_implemented_en & mmio_rspo_addr_not_implemented &     // Set
                            ~reset & cmdbuf0_valid_q;                      // Clear
  assign  cmdbuf1_addr_not_implemented_d  =  (((cmdbuf_mmio_ptr_dly3_q == 2'b01) & mmio_rd_idle_st & mmio_large_rd_idle_st) | ((cmdbuf_resp_ptr_q == 2'b01) & (mmio_rd_idle_st | mmio_large_rd_idle_st))) &  // Writes: use mmio_dly3, reads: use resp_ptr, since only process one at a time
                            mmio_rspo_addr_not_implemented_en & mmio_rspo_addr_not_implemented &     // Set
                            ~reset & cmdbuf1_valid_q;                      // Clear
  assign  cmdbuf2_addr_not_implemented_d  =  (((cmdbuf_mmio_ptr_dly3_q == 2'b10) & mmio_rd_idle_st & mmio_large_rd_idle_st) | ((cmdbuf_resp_ptr_q == 2'b10) & (mmio_rd_idle_st | mmio_large_rd_idle_st))) &  // Writes: use mmio_dly3, reads: use resp_ptr, since only process one at a time
                            mmio_rspo_addr_not_implemented_en & mmio_rspo_addr_not_implemented &     // Set
                            ~reset & cmdbuf2_valid_q;                      // Clear
  assign  cmdbuf3_addr_not_implemented_d  =  (((cmdbuf_mmio_ptr_dly3_q == 2'b11) & mmio_rd_idle_st & mmio_large_rd_idle_st) | ((cmdbuf_resp_ptr_q == 2'b11) & (mmio_rd_idle_st | mmio_large_rd_idle_st))) &  // Writes: use mmio_dly3, reads: use resp_ptr, since only process one at a time
                            mmio_rspo_addr_not_implemented_en & mmio_rspo_addr_not_implemented &     // Set
                            ~reset & cmdbuf3_valid_q;                      // Clear


  // -- ******************************************************************************************************************************************
  // -- Track MMIO done until we have enough credits to send responses
  // -- ******************************************************************************************************************************************

  assign  decr_done_cnt =  afu_tlx_resp_valid_d  &  // Decrement when sending response
                           ~(mmio_wr_error);        // Don't decrement for error responses since we didn't get a mmio_done to increment count

  assign  incr_done_cnt =  mmio_rspo_rddata_valid  |  mmio_rspo_wr_done ;

  assign  done_cnt_en =  ( reset || decr_done_cnt || incr_done_cnt );

  assign  done_cnt_sel[2:0] = { reset, decr_done_cnt, incr_done_cnt };

  always @*
    begin
      casez ( done_cnt_sel[2:0] )
        // --
        // --  reset
        // --  | decr_done_cnt
        // --  | | incr_done_cnt
        // --  | | |
        // -----------------------------------------------------------------------------------
            3'b1_?_? :  done_cnt_d[2:0] =  3'b0       ;  // -- Reset
            3'b0_1_0 :  done_cnt_d[2:0] =  ( done_cnt_q[2:0] - 3'b1 );  // -- Decrement
            3'b0_0_1 :  done_cnt_d[2:0] =  ( done_cnt_q[2:0] + 3'b1 );  // -- Increment
        // -----------------------------------------------------------------------------------
            default  :  done_cnt_d[2:0] =  done_cnt_q[2:0]           ;  // -- Hold (BOTH Increment & Decrement or neither )
        // -----------------------------------------------------------------------------------
      endcase
    end  // -- always @*

  assign  done_cnt_ge_1  =  |(done_cnt_q[2:0]);   // Any bit is set

  // -- ******************************************************************************************************************************************
  // -- Select next command for responses
  // -- ******************************************************************************************************************************************
  assign  next_resp_valid       =  ( (cmdbuf_resp_ptr_q == 2'b00)  & cmdbuf0_valid_q )  |
                                   ( (cmdbuf_resp_ptr_q == 2'b01)  & cmdbuf1_valid_q )  |
                                   ( (cmdbuf_resp_ptr_q == 2'b10)  & cmdbuf2_valid_q )  |
                                   ( (cmdbuf_resp_ptr_q == 2'b11)  & cmdbuf3_valid_q ) ;

  assign  next_resp_cmd_type[1:0]  =  ( {2{(cmdbuf_resp_ptr_q == 2'b00)}}  & cmdbuf0_cmd_type_q[1:0] )  |
                                      ( {2{(cmdbuf_resp_ptr_q == 2'b01)}}  & cmdbuf1_cmd_type_q[1:0] )  |
                                      ( {2{(cmdbuf_resp_ptr_q == 2'b10)}}  & cmdbuf2_cmd_type_q[1:0] )  |
                                      ( {2{(cmdbuf_resp_ptr_q == 2'b11)}}  & cmdbuf3_cmd_type_q[1:0] ) ;

  assign  next_resp_capptag[15:0]  =  ( {16{(cmdbuf_resp_ptr_q == 2'b00)}}  & cmdbuf0_capptag_q[15:0] )  |
                                      ( {16{(cmdbuf_resp_ptr_q == 2'b01)}}  & cmdbuf1_capptag_q[15:0] )  |
                                      ( {16{(cmdbuf_resp_ptr_q == 2'b10)}}  & cmdbuf2_capptag_q[15:0] )  |
                                      ( {16{(cmdbuf_resp_ptr_q == 2'b11)}}  & cmdbuf3_capptag_q[15:0] ) ;

  assign  next_resp_dl_is_64_byte  =  ( (cmdbuf_resp_ptr_q == 2'b00)  & cmdbuf0_dl_is_64_byte_q )  |
                                      ( (cmdbuf_resp_ptr_q == 2'b01)  & cmdbuf1_dl_is_64_byte_q )  |
                                      ( (cmdbuf_resp_ptr_q == 2'b10)  & cmdbuf2_dl_is_64_byte_q )  |
                                      ( (cmdbuf_resp_ptr_q == 2'b11)  & cmdbuf3_dl_is_64_byte_q ) ;

  assign  next_resp_dl_is_128_byte =  ( (cmdbuf_resp_ptr_q == 2'b00)  & cmdbuf0_dl_is_128_byte_q )  |
                                      ( (cmdbuf_resp_ptr_q == 2'b01)  & cmdbuf1_dl_is_128_byte_q )  |
                                      ( (cmdbuf_resp_ptr_q == 2'b10)  & cmdbuf2_dl_is_128_byte_q )  |
                                      ( (cmdbuf_resp_ptr_q == 2'b11)  & cmdbuf3_dl_is_128_byte_q ) ;

  assign  next_resp_pa[25:0]     =  ( {26{(cmdbuf_resp_ptr_q == 2'b00)}}  & cmdbuf0_pa_q[25:0] )  |
                                    ( {26{(cmdbuf_resp_ptr_q == 2'b01)}}  & cmdbuf1_pa_q[25:0] )  |
                                    ( {26{(cmdbuf_resp_ptr_q == 2'b10)}}  & cmdbuf2_pa_q[25:0] )  |
                                    ( {26{(cmdbuf_resp_ptr_q == 2'b11)}}  & cmdbuf3_pa_q[25:0] ) ;

  assign  next_resp_wr_bad_op   =  ( (cmdbuf_resp_ptr_q == 2'b00)  & cmdbuf0_wr_bad_op_q )  |
                                   ( (cmdbuf_resp_ptr_q == 2'b01)  & cmdbuf1_wr_bad_op_q )  |
                                   ( (cmdbuf_resp_ptr_q == 2'b10)  & cmdbuf2_wr_bad_op_q )  |
                                   ( (cmdbuf_resp_ptr_q == 2'b11)  & cmdbuf3_wr_bad_op_q ) ;

  assign  next_resp_bdi         =  ( (cmdbuf_resp_ptr_q == 2'b00)  & cmdbuf0_bdi_q )  |
                                   ( (cmdbuf_resp_ptr_q == 2'b01)  & cmdbuf1_bdi_q )  |
                                   ( (cmdbuf_resp_ptr_q == 2'b10)  & cmdbuf2_bdi_q )  |
                                   ( (cmdbuf_resp_ptr_q == 2'b11)  & cmdbuf3_bdi_q ) ;

  assign  next_resp_bad_op_or_align   =     ( (cmdbuf_resp_ptr_q == 2'b00)  & cmdbuf0_bad_op_or_align_q )  |
                                            ( (cmdbuf_resp_ptr_q == 2'b01)  & cmdbuf1_bad_op_or_align_q )  |
                                            ( (cmdbuf_resp_ptr_q == 2'b10)  & cmdbuf2_bad_op_or_align_q )  |
                                            ( (cmdbuf_resp_ptr_q == 2'b11)  & cmdbuf3_bad_op_or_align_q ) ;

  assign  next_resp_addr_not_implemented =  ( (cmdbuf_resp_ptr_q == 2'b00)  & cmdbuf0_addr_not_implemented_q )  |
                                            ( (cmdbuf_resp_ptr_q == 2'b01)  & cmdbuf1_addr_not_implemented_q )  |
                                            ( (cmdbuf_resp_ptr_q == 2'b10)  & cmdbuf2_addr_not_implemented_q )  |
                                            ( (cmdbuf_resp_ptr_q == 2'b11)  & cmdbuf3_addr_not_implemented_q ) ;

  assign  inc_cmdbuf_resp_ptr  =  afu_tlx_resp_valid_d;

  assign  cmdbuf_resp_ptr_d[1:0]  =  reset                  ?  2'b00 :
                                     inc_cmdbuf_resp_ptr    ?  cmdbuf_resp_ptr_q[1:0] + 2'b01 :
                                                               cmdbuf_resp_ptr_q[1:0];


  assign  send_mmio_wr_response_to_tlx        =  next_resp_valid  &  (next_resp_cmd_type[1:0] == 2'b01)  &  resp_credit_ge_1  &
                                                 (done_cnt_ge_1 | mmio_rspo_wr_done | next_resp_wr_bad_op | next_resp_bdi );

  assign  send_mmio_large_wr_response_to_tlx  =  next_resp_valid  &  (next_resp_cmd_type[1:0] == 2'b11)  &  resp_credit_ge_1  &
                                                 (done_cnt_ge_1 | mmio_rspo_wr_done | next_resp_wr_bad_op | next_resp_bdi );


  // -- ******************************************************************************************************************************************
  // -- Response to TLX for both MMIO and CONFIG reads/writes 
  // -- ******************************************************************************************************************************************

  assign  afu_tlx_resp_valid_d  =  ( send_mmio_rd_response_to_tlx ||
                                     send_mmio_wr_response_to_tlx ||
                                     send_mmio_large_rd_response_to_tlx ||
                                     send_mmio_large_wr_response_to_tlx );

  assign  afu_tlx_rdata_valid_d =  ( send_mmio_rd_response_to_tlx && ~mmio_rd_error ) ||      // -- Send Read Data same cycle Read Response Valid
                                   ( send_mmio_large_rd_response_to_tlx && ~mmio_large_rd_error ) ||
                                   ( send_mmio_large_rd_data_2nd_half );                      // -- 2nd cycle of data for 128B Read Response

  assign  afu_tlx_resp_sel[3:0] =  { ( send_mmio_rd_response_to_tlx && ~mmio_rd_error ),    // -- Mem Read Response 
                                     ( send_mmio_rd_response_to_tlx &&  mmio_rd_error ),    // -- Mem Read Fail
                                     ( send_mmio_wr_response_to_tlx && ~mmio_wr_error ),    // -- Mem Write Response
                                     ( send_mmio_wr_response_to_tlx &&  mmio_wr_error ) };  // -- Mem Write Fail

  assign  afu_tlx_resp_sel[7:4] =  { ( send_mmio_large_rd_response_to_tlx && ~mmio_large_rd_error ),    // -- Mem Read Response 
                                     ( send_mmio_large_rd_response_to_tlx &&  mmio_large_rd_error ),    // -- Mem Read Fail
                                     ( send_mmio_large_wr_response_to_tlx && ~mmio_large_wr_error ),    // -- Mem Write Response
                                     ( send_mmio_large_wr_response_to_tlx &&  mmio_large_wr_error ) };  // -- Mem Write Fail

  assign  afu_tlx_resp_dl_64   =  afu_tlx_resp_sel[3] || afu_tlx_resp_sel[1] ||     // partial read/write
                                  ( (afu_tlx_resp_sel[7] || afu_tlx_resp_sel[5]) && next_resp_dl_is_64_byte );    // Large read/write - 64B

  assign  afu_tlx_resp_dl_128  =  ( (afu_tlx_resp_sel[7] || afu_tlx_resp_sel[5]) && next_resp_dl_is_128_byte );    // Large read/write - 128B

  always @*
    begin
      afu_tlx_resp_opcode_d[7:0] = 8'b0;
      if ( afu_tlx_resp_sel[3] || afu_tlx_resp_sel[7] )  afu_tlx_resp_opcode_d[7:0] =  AFU_TLX_RESP_ENCODE_MEM_RD_RESPONSE[7:0];  // -- Mem Read Response   
      if ( afu_tlx_resp_sel[2] || afu_tlx_resp_sel[6] )  afu_tlx_resp_opcode_d[7:0] =  AFU_TLX_RESP_ENCODE_MEM_RD_FAIL[7:0];      // -- Mem Read Fail
      if ( afu_tlx_resp_sel[1] || afu_tlx_resp_sel[5] )  afu_tlx_resp_opcode_d[7:0] =  AFU_TLX_RESP_ENCODE_MEM_WR_RESPONSE[7:0];  // -- Mem Write Response
      if ( afu_tlx_resp_sel[0] || afu_tlx_resp_sel[4] )  afu_tlx_resp_opcode_d[7:0] =  AFU_TLX_RESP_ENCODE_MEM_WR_FAIL[7:0];      // -- Mem Write Fail

      if (afu_tlx_resp_dl_128)
        afu_tlx_resp_dl_d[1:0] =  2'b10;
      //if ( afu_tlx_resp_sel[3] || afu_tlx_resp_sel[1] )
      else if (afu_tlx_resp_dl_64)
        afu_tlx_resp_dl_d[1:0] =  2'b01;
      else
        afu_tlx_resp_dl_d[1:0] =  2'b00;

      if ( afu_tlx_resp_valid_d )
        afu_tlx_resp_capptag_d[15:0] =  next_resp_capptag[15:0];
      else 
        afu_tlx_resp_capptag_d[15:0] =  16'b0;

      if ( next_resp_valid & next_resp_bdi )                                     // -- These errors are prevented from being issued to MMIO
        afu_tlx_resp_code_d[3:0] =  4'b1000;
      else if ( next_resp_valid & next_resp_wr_bad_op )                          // -- These errors are prevented from being issued to MMIO
        afu_tlx_resp_code_d[3:0] =  4'b1001;
      else if ( next_resp_valid & next_resp_bad_op_or_align )                    // -- Because of the filtering, this is really bad alignment error 
        afu_tlx_resp_code_d[3:0] =  4'b1011;
      else if ( next_resp_valid & mmio_rd_seq_error || mmio_large_rd_seq_error)  // -- Use this for case where failure and no recovery possible
        afu_tlx_resp_code_d[3:0] =  4'b1110;
      else
        afu_tlx_resp_code_d[3:0] =  4'b0;

    end // -- always @ *                                  

  assign  afu_tlx_rdata_bdi_d =  1'b0;  // -- Bad response data indicator -- Use if data has known ECC, Parity, or CRC error - not used in this implementation

  // -- Drive response to TLX off a latch
  assign  afu_tlx_resp_valid         =  afu_tlx_resp_valid_q;
  assign  afu_tlx_resp_opcode[7:0]   =  afu_tlx_resp_opcode_q[7:0];
  assign  afu_tlx_resp_dl[1:0]       =  afu_tlx_resp_dl_q[1:0];
  assign  afu_tlx_resp_capptag[15:0] =  afu_tlx_resp_capptag_q[15:0]; 
  assign  afu_tlx_resp_dp            =  2'b00; 
  assign  afu_tlx_resp_code[3:0]     =  afu_tlx_resp_code_q[3:0]; 

  assign  afu_tlx_rdata_valid        =  afu_tlx_rdata_valid_q;
  assign  afu_tlx_rdata_bdi          =  afu_tlx_rdata_bdi_q;


  // -- Latch rd data from mmio
  assign  rd_data_en =  ( capture_mmio_rd_data || capture_mmio_large_rd_data || reset );

  always @*
    begin
      if ( capture_mmio_rd_data || capture_mmio_large_rd_data)
        rd_data_d[1023:0] =  mmio_rd_data[1023:0];
      else
        rd_data_d[1023:0] =  1024'b0;
    end // -- always @ *                                  

  // -- Mux between zeros and latched rd_data (which originated from mmio read)
  assign  send_mmio_rd_response_to_tlx_d =  send_mmio_rd_response_to_tlx;
  assign  send_mmio_large_rd_response_to_tlx_lower_d =  send_mmio_large_rd_response_to_tlx &&
                                                       (next_resp_dl_is_128_byte || (next_resp_dl_is_64_byte && ~next_resp_pa[6] ));
  assign  send_mmio_large_rd_response_to_tlx_upper_d =  send_mmio_large_rd_response_to_tlx &&
                                                                                    (next_resp_dl_is_64_byte &&  next_resp_pa[6] );
  assign  send_mmio_large_rd_data_2nd_half_d   =  send_mmio_large_rd_data_2nd_half;

  always @*
    begin
      afu_tlx_rdata_bus[511:0] = 512'b0;
      if ( send_mmio_rd_response_to_tlx_q )
        case ( tlx_afu_cmd_pa_q[5:3] )
          3'b111 :  afu_tlx_rdata_bus[511:448] =  rd_data_q[63:0];
          3'b110 :  afu_tlx_rdata_bus[447:384] =  rd_data_q[63:0];
          3'b101 :  afu_tlx_rdata_bus[383:320] =  rd_data_q[63:0];
          3'b100 :  afu_tlx_rdata_bus[319:256] =  rd_data_q[63:0];
          3'b011 :  afu_tlx_rdata_bus[255:192] =  rd_data_q[63:0];
          3'b010 :  afu_tlx_rdata_bus[191:128] =  rd_data_q[63:0];
          3'b001 :  afu_tlx_rdata_bus[127:64]  =  rd_data_q[63:0];
          3'b000 :  afu_tlx_rdata_bus[63:0]    =  rd_data_q[63:0];
        endcase
      if ( send_mmio_large_rd_response_to_tlx_lower_q  )
	  afu_tlx_rdata_bus[511:0]  =  rd_data_q[511:0];
      if ( send_mmio_large_rd_response_to_tlx_upper_q  )
	  afu_tlx_rdata_bus[511:0]  =  rd_data_q[1023:512];
      if ( send_mmio_large_rd_data_2nd_half_q )
	  afu_tlx_rdata_bus[511:0]  =  rd_data_q[1023:512];

    end // -- always @ *                                  


  // -- ******************************************************************************************************************************************
  // -- Manage receive cmd credits
  // -- ******************************************************************************************************************************************

  // -- Provide AFU's Initial Cmd Credit to TLX
  assign  afu_tlx_cmd_initial_credit[6:0] =  7'b100;  // -- Buffer size is 4 (previously 1, to single thread cmds)

  // -- Return cmd credit to TLX when command has been fully processed (which is actually when the response is ready to be sent)
  assign  return_cmd_credit_d =  ( send_mmio_rd_response_to_tlx || send_mmio_large_rd_response_to_tlx ||
                                   send_mmio_wr_response_to_tlx || send_mmio_large_wr_response_to_tlx );

  assign  afu_tlx_cmd_credit =  return_cmd_credit_q;


  // -- ******************************************************************************************************************************************
  // -- Manage Resp Credit
  // -- ******************************************************************************************************************************************

  assign  decr_resp_credit =  ( send_mmio_rd_response_to_tlx || send_mmio_large_rd_response_to_tlx ||
                                send_mmio_wr_response_to_tlx || send_mmio_large_wr_response_to_tlx );

  assign  incr_resp_credit =  tlx_afu_resp_credit;  // -- TLX returning a credit back to the AFU

  assign  available_resp_credit_en =  ( reset || decr_resp_credit || incr_resp_credit );

  assign  available_resp_credit_sel[2:0] = { reset, decr_resp_credit, incr_resp_credit };

  always @*
    begin
      casez ( available_resp_credit_sel[2:0] )
        // --
        // --  reset
        // --  | decr_resp_credit
        // --  | | incr_resp_credit
        // --  | | |
        // -----------------------------------------------------------------------------------
         //GFP   3'b1_?_? :  available_resp_credit_d[2:0] =  tlx_afu_cmd_resp_initial_credit[2:0]   ;  // -- Reset - Load initial Credit
         //GFP   3'b0_1_0 :  available_resp_credit_d[2:0] =  ( available_resp_credit_q[2:0] - 3'b1 );  // -- Decrement
         //GFP   3'b0_0_1 :  available_resp_credit_d[2:0] =  ( available_resp_credit_q[2:0] + 3'b1 );  // -- Increment
        // -----------------------------------------------------------------------------------
         //GFP   default  :  available_resp_credit_d[2:0] =  available_resp_credit_q[2:0]           ;  // -- Hold (BOTH Increment & Decrement or neither )
        // -----------------------------------------------------------------------------------
        // -----------------------------------------------------------------------------------
            3'b1_?_? :  available_resp_credit_d[3:0] =  tlx_afu_resp_initial_credit[3:0]       ;  // -- Reset - Load initial Credit
            3'b0_1_0 :  available_resp_credit_d[3:0] =  ( available_resp_credit_q[3:0] - 4'b1 );  // -- Decrement
            3'b0_0_1 :  available_resp_credit_d[3:0] =  ( available_resp_credit_q[3:0] + 4'b1 );  // -- Increment
        // -----------------------------------------------------------------------------------
            default  :  available_resp_credit_d[3:0] =  available_resp_credit_q[3:0]           ;  // -- Hold (BOTH Increment & Decrement or neither )
        // -----------------------------------------------------------------------------------
      endcase

    end  // -- always @*

//assign  resp_credit_ge_1 =  (( available_resp_credit_q[2:0] != 3'b0 ) || tlx_afu_resp_credit );  // -- timing fix
//GFP  assign  resp_credit_ge_1 =  ( available_resp_credit_q[2:0] != 3'b0 );
  assign  resp_credit_ge_1 =  ( available_resp_credit_q[3:0] != 4'b0 );


  // -- ******************************************************************************************************************************************
  // -- Manage Resp Data Credit
  // -- ******************************************************************************************************************************************

  assign  decr_data_credit =  send_mmio_rd_response_to_tlx ||
                              send_mmio_large_rd_response_to_tlx || send_mmio_large_rd_data_2nd_half;

  assign  incr_data_credit =  tlx_afu_resp_data_credit;  // -- TLX returning a credit back to the AFU

  assign  available_data_credit_en =  ( reset || decr_data_credit || incr_data_credit );

  assign  available_data_credit_sel[2:0] = { reset, decr_data_credit, incr_data_credit };

  always @*
    begin
      casez ( available_data_credit_sel[2:0] )
        // --
        // --  reset
        // --  | decr_data_credit
        // --  | | incr_data_credit
        // --  | | |
        // -----------------------------------------------------------------------------------
//GFP            3'b1_?_? :  available_data_credit_d[4:0] =  tlx_afu_data_initial_credit[4:0]       ;  // -- Reset - Load initial Credit
//GFP            3'b0_1_0 :  available_data_credit_d[4:0] =  ( available_data_credit_q[4:0] - 5'b1 );  // -- Decrement
//GFP            3'b0_0_1 :  available_data_credit_d[4:0] =  ( available_data_credit_q[4:0] + 5'b1 );  // -- Increment
        // -----------------------------------------------------------------------------------
//GFP            default  :  available_data_credit_d[4:0] =  available_data_credit_q[4:0]           ;  // -- Hold (BOTH Increment & Decrement or neither )
        // -----------------------------------------------------------------------------------
            3'b1_?_? :  available_data_credit_d[5:0] =  tlx_afu_resp_data_initial_credit[5:0]  ;  // -- Reset - Load initial Credit
            3'b0_1_0 :  available_data_credit_d[5:0] =  ( available_data_credit_q[5:0] - 6'b1 );  // -- Decrement
            3'b0_0_1 :  available_data_credit_d[5:0] =  ( available_data_credit_q[5:0] + 6'b1 );  // -- Increment
        // -----------------------------------------------------------------------------------
            default  :  available_data_credit_d[5:0] =  available_data_credit_q[5:0]           ;  // -- Hold (BOTH Increment & Decrement or neither )
        // -----------------------------------------------------------------------------------
      endcase

    end  // -- always @*

//assign  resp_data_credit_ge_1 =  (( available_data_credit_q[4:0] != 5'b0 ) || tlx_afu_resp_data_credit );  // -- timing fix
//GFP  assign  resp_data_credit_ge_1 =  ( available_data_credit_q[4:0] != 5'b0 );
//GFP  assign  resp_data_credit_ge_2 =  ( available_data_credit_q[4:1] != 4'b0 );
  assign  resp_data_credit_ge_1 =  ( available_data_credit_q[5:0] != 6'b0 );
  assign  resp_data_credit_ge_2 =  ( available_data_credit_q[5:1] != 5'b0 );


  // -- ********************************************************************************************************************************
  // -- Send latched interface signals to the trace array for debug
  // -- ********************************************************************************************************************************

  // -- Latches added for trace only
  assign  tlx_afu_resp_credit_d             =   tlx_afu_resp_credit;
  assign  tlx_afu_resp_data_credit_d        =   tlx_afu_resp_data_credit;

  // -- TLX_AFU Command Receive Bus Trace outputs   (MMIO requests)
//assign  trace_tlx_afu_ready               =  tlx_afu_ready_q;
                                              
  assign  trace_tlx_afu_cmd_valid           =  tlx_afu_cmd_valid_q;         
  assign  trace_tlx_afu_cmd_opcode[7:0]     =  tlx_afu_cmd_opcode_q[7:0];
  assign  trace_tlx_afu_cmd_capptag[15:0]   =  tlx_afu_cmd_capptag_q[15:0];
//assign  trace_tlx_afu_cmd_dl[1:0]         =  tlx_afu_cmd_dl_q[1:0];
  assign  trace_tlx_afu_cmd_pl[2:0]         =  tlx_afu_cmd_pl_q[2:0];
//assign  trace_tlx_afu_cmd_be[63:0]        =  tlx_afu_cmd_be_q[63:0];
//assign  trace_tlx_afu_cmd_end             =  tlx_afu_cmd_end_q;           
  assign  trace_tlx_afu_cmd_pa[25:0]        =  tlx_afu_cmd_pa_q[25:0];
//assign  trace_tlx_afu_cmd_flag[3:0]       =  tlx_afu_cmd_flag_q[3:0];
//assign  trace_tlx_afu_cmd_os              =  tlx_afu_cmd_os_q;            
                                                                          
  assign  trace_tlx_afu_cmd_data_valid      =  tlx_afu_cmd_data_valid_q;    
  assign  trace_tlx_afu_cmd_data_bdi        =  tlx_afu_cmd_data_bdi_q;      
  assign  trace_tlx_afu_cmd_data_bus[63:0]  =  tlx_afu_cmd_data_bus_q[63:0];
                                                                          
  assign  trace_afu_tlx_cmd_rd_req          =  request_mmio_wr_data_from_tlx;        
//assign  trace_afu_tlx_cmd_rd_cnt[2:0]     =  3b'001;
                                                                          
  assign  trace_afu_tlx_cmd_credit          =  return_cmd_credit_q;        

  assign  trace_tlx_afu_mmio_rd_cmd_valid   =  tlx_afu_mmio_rd_cmd_valid;
  assign  trace_tlx_afu_mmio_wr_cmd_valid   =  tlx_afu_mmio_wr_cmd_valid;
                                              
  // -- AFU_TLX Response Transmit Bus Trace inputs   (MMIO responses)
  assign  trace_afu_tlx_resp_valid          =  afu_tlx_resp_valid_q;        
  assign  trace_afu_tlx_resp_opcode[3:0]    =  afu_tlx_resp_opcode_q[3:0];
  assign  trace_afu_tlx_resp_dl[1:0]        =  afu_tlx_resp_dl_q[1:0];
  assign  trace_afu_tlx_resp_capptag[15:0]  =  afu_tlx_resp_capptag_q[15:0];
//assign  trace_afu_tlx_resp_dp[1:0]        =  2'b00;
  assign  trace_afu_tlx_resp_code[3:0]      =  afu_tlx_resp_code_q[3:0];
                                                                           
  assign  trace_afu_tlx_rdata_valid         =  afu_tlx_rdata_valid_q;       
//assign  trace_afu_tlx_rdata_bdi           =  1'b0;         
//assign  trace_afu_tlx_rdata_bus[63:0]     =  afu_tlx_rdata_bus_q[63:0];
                                                                           
  assign  trace_tlx_afu_resp_credit         =  tlx_afu_resp_credit_q;       
  assign  trace_tlx_afu_resp_data_credit    =  tlx_afu_resp_data_credit_q;  
                                                                           
//GFP  assign  trace_rspo_avail_resp_credit[2:0] =  available_resp_credit_q[2:0];     
//GFP  assign  trace_rspo_avail_data_credit[4:0] =  available_data_credit_q[4:0];    
  assign  trace_rspo_avail_resp_credit[3:0] =  available_resp_credit_q[3:0];     
  assign  trace_rspo_avail_data_credit[5:0] =  available_data_credit_q[5:0];    


  // -- ********************************************************************************************************************************
  // -- Sim Idle
  // -- ********************************************************************************************************************************

//assign  sim_idle_cmdi_rspo =  (( available_resp_credit_q[2:0] == tlx_afu_cmd_resp_initial_credit[2:0] ) &&
//GFP  assign  sim_idle_cmdi_rspo =  (( available_resp_credit_q[2:0] == ( tlx_afu_cmd_resp_initial_credit[2:0] + 3'b011 )) && // -- account for change in tlx
//GFP                                 ( available_data_credit_q[4:0] == tlx_afu_data_initial_credit[4:0]     ) &&
  assign  sim_idle_cmdi_rspo =  (( available_resp_credit_q[3:0] == ( tlx_afu_resp_initial_credit[3:0] )) && // -- account for change in tlx - GFP no longer need to add "3".
                                 ( available_data_credit_q[5:0] == tlx_afu_resp_data_initial_credit[5:0]     ) &&
                                 ( tlx_afu_cmd_valid_q  == 1'b0) &&
                                 ( mmio_rd_idle_st      == 1'b1) &&
                                 //( mmio_wr_idle_st      == 1'b1) &&
                                 ( mmio_large_rd_idle_st  == 1'b1) &&
                                 //( mmio_large_wr_idle_st  == 1'b1) &&
                                 ( buffer_empty         == 1'b1) &&
                                 ( afu_tlx_resp_valid_q == 1'b0));



  // -- ********************************************************************************************************************************
  // -- Bugspray
  // -- ********************************************************************************************************************************

//!! Bugspray include : afp3_cmdi_rspo


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  // -- TLX to AFU Cmd Interface
  always @ ( posedge clock )
    begin
      tlx_afu_ready_q                      <= tlx_afu_ready_d;              
      tlx_afu_cmd_valid_q                  <= tlx_afu_cmd_valid_d;          

      if ( tlx_afu_cmd_xxx_en )
        begin 
          tlx_afu_cmd_opcode_q[7:0]        <= tlx_afu_cmd_opcode_d[7:0];    
          tlx_afu_cmd_capptag_q[15:0]      <= tlx_afu_cmd_capptag_d[15:0];  
          tlx_afu_cmd_dl_q[1:0]            <= tlx_afu_cmd_dl_d[1:0];        
          tlx_afu_cmd_pl_q[2:0]            <= tlx_afu_cmd_pl_d[2:0];        
          tlx_afu_cmd_be_q[63:0]           <= tlx_afu_cmd_be_d[63:0];       
          tlx_afu_cmd_end_q                <= tlx_afu_cmd_end_d;            
          tlx_afu_cmd_pa_q[63:0]           <= tlx_afu_cmd_pa_d[63:0];       
          tlx_afu_cmd_flag_q[3:0]          <= tlx_afu_cmd_flag_d[3:0];      
          tlx_afu_cmd_os_q                 <= tlx_afu_cmd_os_d;             
        end
      cmdbuf_wrt_ptr_q[1:0]                <= cmdbuf_wrt_ptr_d[1:0];
      cmdbuf0_valid_q                      <= cmdbuf0_valid_d;
      if ( cmdbuf0_en )
        begin 
          cmdbuf0_cmd_type_q[1:0]          <= cmdbuf0_cmd_type_d[1:0];
          cmdbuf0_capptag_q[15:0]          <= cmdbuf0_capptag_d[15:0];
          cmdbuf0_dl_is_64_byte_q          <= cmdbuf0_dl_is_64_byte_d;
          cmdbuf0_dl_is_128_byte_q         <= cmdbuf0_dl_is_128_byte_d;
          cmdbuf0_pl_is_8_byte_q           <= cmdbuf0_pl_is_8_byte_d;
          cmdbuf0_pa_q[25:0]               <= cmdbuf0_pa_d[25:0];
          cmdbuf0_wr_bad_op_q              <= cmdbuf0_wr_bad_op_d;
        end
      cmdbuf1_valid_q                      <= cmdbuf1_valid_d;
      if ( cmdbuf1_en )
        begin 
          cmdbuf1_cmd_type_q[1:0]          <= cmdbuf1_cmd_type_d[1:0];
          cmdbuf1_capptag_q[15:0]          <= cmdbuf1_capptag_d[15:0];
          cmdbuf1_dl_is_64_byte_q          <= cmdbuf1_dl_is_64_byte_d;
          cmdbuf1_dl_is_128_byte_q         <= cmdbuf1_dl_is_128_byte_d;
          cmdbuf1_pl_is_8_byte_q           <= cmdbuf1_pl_is_8_byte_d;
          cmdbuf1_pa_q[25:0]               <= cmdbuf1_pa_d[25:0];
          cmdbuf1_wr_bad_op_q              <= cmdbuf1_wr_bad_op_d;
        end
      cmdbuf2_valid_q                      <= cmdbuf2_valid_d;
      if ( cmdbuf2_en )
        begin 
          cmdbuf2_cmd_type_q[1:0]          <= cmdbuf2_cmd_type_d[1:0];
          cmdbuf2_capptag_q[15:0]          <= cmdbuf2_capptag_d[15:0];
          cmdbuf2_dl_is_64_byte_q          <= cmdbuf2_dl_is_64_byte_d;
          cmdbuf2_dl_is_128_byte_q         <= cmdbuf2_dl_is_128_byte_d;
          cmdbuf2_pl_is_8_byte_q           <= cmdbuf2_pl_is_8_byte_d;
          cmdbuf2_pa_q[25:0]               <= cmdbuf2_pa_d[25:0];
          cmdbuf2_wr_bad_op_q              <= cmdbuf2_wr_bad_op_d;
        end
      cmdbuf3_valid_q                      <= cmdbuf3_valid_d;
      if ( cmdbuf3_en )
        begin 
          cmdbuf3_cmd_type_q[1:0]          <= cmdbuf3_cmd_type_d[1:0];
          cmdbuf3_capptag_q[15:0]          <= cmdbuf3_capptag_d[15:0];
          cmdbuf3_dl_is_64_byte_q          <= cmdbuf3_dl_is_64_byte_d;
          cmdbuf3_dl_is_128_byte_q         <= cmdbuf3_dl_is_128_byte_d;
          cmdbuf3_pl_is_8_byte_q           <= cmdbuf3_pl_is_8_byte_d;
          cmdbuf3_pa_q[25:0]               <= cmdbuf3_pa_d[25:0];
          cmdbuf3_wr_bad_op_q              <= cmdbuf3_wr_bad_op_d;
        end
      tlx_afu_cmd_data_valid_q             <= tlx_afu_cmd_data_valid_d;     
      if ( tlx_afu_cmd_data_bdi_en )
        tlx_afu_cmd_data_bdi_q             <= tlx_afu_cmd_data_bdi_d;    
      if ( tlx_afu_cmd_data_bus_en )
        tlx_afu_cmd_data_bus_q[63:0]       <= tlx_afu_cmd_data_bus_d[63:0]; 
      if ( tlx_afu_cmd_data_large_bus0_en )
        tlx_afu_cmd_data_bus_q[511:64]     <= tlx_afu_cmd_data_bus_d[511:64];
      if ( tlx_afu_cmd_data_large_bus1_en )
        tlx_afu_cmd_data_bus_q[1023:512]   <= tlx_afu_cmd_data_bus_d[1023:512];

      mmio_rd_seq_q[3:0]                   <= mmio_rd_seq_d[3:0];           
      send_mmio_rd_response_to_tlx_q       <= send_mmio_rd_response_to_tlx_d;
      mmio_large_rd_seq_q[4:0]             <= mmio_large_rd_seq_d[4:0];           
      //send_mmio_large_rd_response_to_tlx_q <= send_mmio_large_rd_response_to_tlx_d;
      send_mmio_large_rd_response_to_tlx_lower_q <= send_mmio_large_rd_response_to_tlx_lower_d;
      send_mmio_large_rd_response_to_tlx_upper_q <= send_mmio_large_rd_response_to_tlx_upper_d;
      send_mmio_large_rd_data_2nd_half_q   <= send_mmio_large_rd_data_2nd_half_d;
      //mmio_wr_seq_q[4:0]                   <= mmio_wr_seq_d[4:0];           
      //mmio_large_wr_seq_q[5:0]             <= mmio_large_wr_seq_d[5:0];           
      //if ( mmio_wr_bad_op_en )
      //  mmio_wr_bad_op_q                   <= mmio_wr_bad_op_d;             
      //if ( mmio_large_wr_bad_op_en )
      //  mmio_large_wr_bad_op_q             <= mmio_large_wr_bad_op_d;             
      wait_for_128_byte_data_q             <= wait_for_128_byte_data_d;
      cmdbuf_wr_data_ptr_q[1:0]            <= cmdbuf_wr_data_ptr_d[1:0];
      cmdbuf_wr_data_ptr_wrap_q            <= cmdbuf_wr_data_ptr_wrap_d;
      cmdbuf_mmio_ptr_q[1:0]               <= cmdbuf_mmio_ptr_d[1:0];
      cmdbuf_mmio_ptr_wrap_q               <= cmdbuf_mmio_ptr_wrap_d;
      tlx_2nd_half_q                       <= tlx_2nd_half_d;
      issue_mmio_wr_req_q                  <= issue_mmio_wr_req_d;
      issue_mmio_large_wr_req_q            <= issue_mmio_large_wr_req_d;
      mmio_large_wr_half_en_q[1:0]         <= mmio_large_wr_half_en_d[1:0];
      next_mmio_pa_q[25:0]                 <= next_mmio_pa_d[25:0];
      cmdbuf0_bdi_q                        <= cmdbuf0_bdi_d;
      cmdbuf1_bdi_q                        <= cmdbuf1_bdi_d;
      cmdbuf2_bdi_q                        <= cmdbuf2_bdi_d;
      cmdbuf3_bdi_q                        <= cmdbuf3_bdi_d;
      cmdbuf_mmio_ptr_dly1_q[1:0]          <= cmdbuf_mmio_ptr_dly1_d[1:0];
      cmdbuf_mmio_ptr_dly2_q[1:0]          <= cmdbuf_mmio_ptr_dly2_d[1:0];
      cmdbuf_mmio_ptr_dly3_q[1:0]          <= cmdbuf_mmio_ptr_dly3_d[1:0];
      if ( mmio_rspo_bad_op_or_align_en )
        mmio_rspo_bad_op_or_align_q        <= mmio_rspo_bad_op_or_align_d;  
      if ( mmio_rspo_addr_not_implemented_en )
        mmio_rspo_addr_not_implemented_q   <= mmio_rspo_addr_not_implemented_d;
      cmdbuf0_bad_op_or_align_q            <= cmdbuf0_bad_op_or_align_d;
      cmdbuf1_bad_op_or_align_q            <= cmdbuf1_bad_op_or_align_d;
      cmdbuf2_bad_op_or_align_q            <= cmdbuf2_bad_op_or_align_d;
      cmdbuf3_bad_op_or_align_q            <= cmdbuf3_bad_op_or_align_d;
      cmdbuf0_addr_not_implemented_q       <= cmdbuf0_addr_not_implemented_d;
      cmdbuf1_addr_not_implemented_q       <= cmdbuf1_addr_not_implemented_d;
      cmdbuf2_addr_not_implemented_q       <= cmdbuf2_addr_not_implemented_d;
      cmdbuf3_addr_not_implemented_q       <= cmdbuf3_addr_not_implemented_d;
      if ( done_cnt_en )
        done_cnt_q[2:0]                    <= done_cnt_d[2:0];
      cmdbuf_resp_ptr_q[1:0]               <= cmdbuf_resp_ptr_d[1:0];
      afu_tlx_resp_valid_q                 <= afu_tlx_resp_valid_d;         
      afu_tlx_rdata_valid_q                <= afu_tlx_rdata_valid_d;        
      afu_tlx_resp_opcode_q[7:0]           <= afu_tlx_resp_opcode_d[7:0];   
      afu_tlx_resp_dl_q[1:0]               <= afu_tlx_resp_dl_d[1:0];       
      afu_tlx_resp_capptag_q[15:0]         <= afu_tlx_resp_capptag_d[15:0]; 
      afu_tlx_resp_code_q[3:0]             <= afu_tlx_resp_code_d[3:0];     
      afu_tlx_rdata_bdi_q                  <= afu_tlx_rdata_bdi_d;          
      if ( rd_data_en )
        rd_data_q[1023:0]                  <= rd_data_d[1023:0];              
      return_cmd_credit_q                  <= return_cmd_credit_d;
      tlx_afu_resp_credit_q                <= tlx_afu_resp_credit_d;         
      if ( available_resp_credit_en )
//GFP        available_resp_credit_q[2:0]       <= available_resp_credit_d[2:0]; 
        available_resp_credit_q[3:0]       <= available_resp_credit_d[3:0]; 
      tlx_afu_resp_data_credit_q           <= tlx_afu_resp_data_credit_d;         
      if ( available_data_credit_en )
//GFP        available_data_credit_q[4:0]       <= available_data_credit_d[4:0];
        available_data_credit_q[5:0]       <= available_data_credit_d[5:0];
 
    end  // -- always @*
endmodule
