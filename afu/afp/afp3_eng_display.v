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

module afp3_eng_display
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // --Modes/Config & Misc signals
  , input                 memcpy2_format_enable_q
  , input           [4:0] eng_num

  // -- Display Interface signals
//     , input                 weq_eng_display_rdval
//     , input          [25:8] weq_eng_wed 
  , input                 mmio_eng_display_rdval
  , input           [1:0] mmio_eng_display_ary_select
  , input           [9:0] mmio_eng_display_addr

  // -- Inputs for forming display data
  , input           [4:0] main_state                   
  , input           [1:0] actag_state                  
  , input           [3:0] we_ld_state                  
  , input           [3:0] xtouch_state                 
//     , input           [3:0] cpy_ld_state                 
//     , input           [3:0] cpy_st_state                 
  , input           [2:0] wkhstthrd_state              
  , input           [4:0] incr_state
  , input           [3:0] atomic_state                 
  , input           [2:0] intrpt_state                 
  , input           [2:0] we_st_state                  
  , input           [1:0] wr_weq_state                  

  , input           [3:0] we_rtry_ld_state             
  , input           [5:0] xtouch_rtry_state            
  , input           [3:0] cpy_rtry_ld_state            
  , input           [4:0] cpy_rtry_st_state            
  , input           [3:0] wkhstthrd_rtry_state         
  , input           [5:0] incr_rtry_state
  , input           [3:0] atomic_rtry_state            
  , input           [3:0] intrpt_rtry_state            
  , input           [3:0] we_rtry_st_state
             
  , input                 main_idle_st                 
  , input                 actag_idle_st                
  , input                 we_ld_idle_st                
  , input                 xtouch_idle_st               
  , input                 cpy_ld_idle_st               
  , input                 cpy_st_idle_st               
  , input                 wkhstthrd_idle_st            
  , input                 incr_idle_st                 
  , input                 atomic_idle_st               
  , input                 intrpt_idle_st               
  , input                 we_st_idle_st                
  , input                 wr_weq_idle_st

  , input                 we_rtry_ld_idle_st           
  , input                 xtouch_rtry_idle_st          
  , input                 cpy_rtry_ld_idle_st          
  , input                 cpy_rtry_st_idle_st          
  , input                 wkhstthrd_rtry_idle_st       
  , input                 incr_rtry_idle_st            
  , input                 atomic_rtry_idle_st          
  , input                 intrpt_rtry_idle_st          
  , input                 we_rtry_st_idle_st           
               
  , input                 we_ld_wt4rsp_st              
  , input                 xtouch_wt4rsp_st             
  , input                 cpy_ld_wt4rsp_st             
  , input                 cpy_st_wt4rsp_st             
  , input                 wkhstthrd_wt4rsp_st
  , input                 incr_wt4ldrsp_st         
  , input                 incr_wt4strsp_st         
  , input                 atomic_wt4rsp_st             
  , input                 intrpt_wt4rsp_st             
  , input                 we_st_wt4rsp_st

//     , input                 we_cmd_is_copy_q             
  , input                 we_cmd_is_intrpt_q           
//     , input                 we_cmd_is_stop_q             
  , input                 we_cmd_is_wkhstthrd_q        
//     , input                 we_cmd_is_incr_q             
//     , input                 we_cmd_is_atomic_q           
  , input                 we_cmd_is_atomic_ld_q        
  , input                 we_cmd_is_atomic_cas_q       
  , input                 we_cmd_is_atomic_st_q        
//     , input                 we_cmd_is_xtouch_q           

//     , input                 we_cmd_is_undefined_q        
//     , input                 we_cmd_length_is_zero_q      
//     , input                 we_cmd_is_bad_atomic_q

  , input                 rtry_queue_func_rden_blocker
  , input          [10:0] rtry_queue_rdaddr_q
  , input          [10:0] rtry_queue_wraddr_q
  , input          [17:0] rtry_queue_rddata
  , input           [3:0] resp_code_rddata
  , input           [4:0] pending_cnt_q
//     , input                 eng_pe_terminate_q

//     , input          [31:0] cpy_cmd_sent_q
//     , input          [31:0] cpy_cmd_resp_rcvd_q

  , input           [9:0] cmd_pasid_q
//     , input          [18:5] cmd_offset_q
//     , input          [63:5] cmd_we_ea_q
//     , input                 cmd_we_wrap_q
  , input          [63:6] cpy_st_ea_q    //     Added for AFP3
  , input          [63:0] xtouch_ea_q    //     Added for AFP3

//     , input          [63:0] we_cmd_source_ea_q           
  , input          [63:0] we_cmd_dest_ea_q             
  , input          [63:0] we_cmd_atomic_op1_q          
//, input          [63:0] we_cmd_atomic_op2_q          
//     , input           [5:0] we_cmd_encode_q              
  , input          [15:0] we_cmd_length_q              
  , input           [7:0] we_cmd_extra_q
//     , input                 we_cmd_wrap_q              

  // -- Signals used for collision detection to form blocker
  , input                 start_actag_seq
  , input                 start_intrpt_seq
  , input                 start_xtouch_seq
  , input                 start_wkhstthrd_seq
  , input                 start_atomic_seq
  , input                 start_cpy_st_seq
  , input                 start_cpy_rtry_st_seq

  , input                 actag_req
  , input                 intrpt_req
  , input                 xtouch_req
  , input                 wkhstthrd_req
  , input                 atomic_req
//     , input                 cpy_st_req
  , input                 cpy_rtry_st_req

  , input                 actag_wt4gnt_st
  , input                 intrpt_wt4gnt_st
  , input                 xtouch_wt4gnt1_st
  , input                 xtouch_wt4gnt2_st
  , input                 wkhstthrd_wt4gnt_st
  , input                 atomic_wt4gnt_st
  //    , input                 cpy_st_wt4gnt_st
  , input                 cpy_rtry_st_wt4gnt_st

  // -- Sequencer Outputs
  , output                start_eng_display_seq
  , output                eng_display_idle_st
  , output                eng_display_wait_st
  , output                eng_display_req_st
  , output                eng_display_wt4gnt_st
  , output                eng_display_rddataval_st

  // -- Arbitration
  , output reg            eng_display_req
  , input                 arb_eng_misc_gnt

  // -- Output to tell MMIO that the display data can be captured from cmdo module
  , output                eng_mmio_display_rddata_valid

  // -- Output to control read of the data buffer and retry queue
  , output reg            eng_display_dbuf_rden
  , output reg            eng_display_dbuf_rden_dly1
  , output reg            eng_display_rtry_queue_rden
  //   , output          [1:0] eng_display_ary_select_q
  , output          [9:0] eng_display_addr_q
  //    , output          [8:6] eng_display_size

  , output         [63:0] eng_display_data

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  wire            start_eng_display_seq_int;
  wire      [9:0] eng_display_seq_sel;
  reg      [11:0] eng_display_seq;
  wire            eng_display_seq_error;

  wire            eng_display_req_blocker;
//reg             eng_display_rtry_queue_rden;
  reg             eng_display_rtry_queue_rddata_capture;
  reg             eng_display_latch_rddata_capture;
  reg             eng_display_rddata_valid;

  wire            xtouch_wt4gnt_st;


  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  reg       [4:0] eng_display_seq_d;
  reg       [4:0] eng_display_seq_q;

  wire            eng_display_rdval_d;
  reg             eng_display_rdval_q;

  wire            eng_display_cmdinfo_en;
  reg       [1:0] eng_display_ary_select_int_d; 
  reg       [1:0] eng_display_ary_select_int_q; 
//    reg       [4:0] eng_display_eng_select_d; 
//    reg       [4:0] eng_display_eng_select_q; 
  reg       [9:0] eng_display_addr_int_d; 
  reg       [9:0] eng_display_addr_int_q;

  reg      [63:0] eng_display_rddata_d;
  reg      [63:0] eng_display_rddata_q;


  // -- ********************************************************************************************************************************
  // -- Display Read Interface 
  // -- ********************************************************************************************************************************

  // -- Latch the valid and capture cmd info that arrived on the intrpt_data_bus
  assign  eng_display_rdval_d               =  mmio_eng_display_rdval;   // weq_eng_display_rdval;

  //    assign  eng_display_cmdinfo_en            =  ( weq_eng_display_rdval || reset );
  assign  eng_display_cmdinfo_en            =  ( mmio_eng_display_rdval || reset );
  always @*
    begin
      if ( ~reset )
        begin
          eng_display_ary_select_int_d[1:0] =  mmio_eng_display_ary_select[1:0];   // weq_eng_wed[25:24]; 
          //eng_display_eng_select_d[4:0]     =  5'b0;                             // weq_eng_wed[20:16];  // AFP3: Using the MMIO eng_select bits for upper bits of address
          eng_display_addr_int_d[9:0]       =  mmio_eng_display_addr[9:0];         // weq_eng_wed[12:8];
        end
      else
        begin
          eng_display_ary_select_int_d[1:0] =  2'b0; 
          //eng_display_eng_select_d[4:0]     =  5'b0;
          eng_display_addr_int_d[9:0]       = 10'b0;
        end
    end // -- always @ *

  //     assign  eng_display_size[8:6]             =  3'b001;  // -- Hardcode to 64B 


  // -- Determine if the request is for this engine
  //    assign  start_eng_display_seq_int =  ( eng_display_rdval_q && ( eng_display_eng_select_q[4:0] == eng_num[4:0] ));
  assign  start_eng_display_seq_int =   eng_display_rdval_q;  // AFP has only one engine

  assign  start_eng_display_seq =  start_eng_display_seq_int;

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc05  eng_display_seq_err (
    .one_hot_vector   ( eng_display_seq_q[4:0] ),
    .one_hot_error    ( eng_display_seq_error )
  );

  // -- Current State Assignments
  assign  eng_display_idle_st      =  eng_display_seq_q[0];  // -- Wait for eng_display read request
  assign  eng_display_wait_st      =  eng_display_seq_q[1];  // -- Wait for req blocker to clear 
  assign  eng_display_req_st       =  eng_display_seq_q[2];  // -- Req State - used for dbuf access to drive delayed rden  
  assign  eng_display_wt4gnt_st    =  eng_display_seq_q[3];  // -- Wait for misc arb grant  
  assign  eng_display_rddataval_st =  eng_display_seq_q[4];  // -- Rd Data is on the bus to cmdo this cycle,  valid presented back to mmio on this cycle  

  // -- Form blockers - Display Sequencer can run concurrently with others - avoid collision with other misc requests and cpy_st_req (to avoid dbuf collision)
  assign  xtouch_wt4gnt_st =  xtouch_wt4gnt1_st || xtouch_wt4gnt2_st;

  assign  eng_display_req_blocker  = ( start_actag_seq || start_intrpt_seq || start_xtouch_seq || start_wkhstthrd_seq || start_atomic_seq || start_cpy_st_seq || start_cpy_rtry_st_seq ||
                                             actag_req ||       intrpt_req ||       xtouch_req || wkhstthrd_req       ||       atomic_req  || cpy_rtry_st_req       ||
                                       actag_wt4gnt_st || intrpt_wt4gnt_st || xtouch_wt4gnt_st || wkhstthrd_wt4gnt_st || atomic_wt4gnt_st ||  cpy_rtry_st_wt4gnt_st );   //    - removed  || cpy_st_wt4gnt_st  ||       cpy_st_req

  // -- Sequencer Inputs
  assign  eng_display_seq_sel[9:0] = { start_eng_display_seq_int, eng_display_req_blocker, eng_display_ary_select_int_q[1:0],  arb_eng_misc_gnt, eng_display_seq_q[4:0] };

  // -- Sequencer Table
  always @*
    begin
      casez ( eng_display_seq_sel[9:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --                                            
        // --                                              Outputs & Next State
        // --                                              --------------------
        // --  Inputs & Current State                      eng_display_req        
        // --  ----------------------                      |eng_display_dbuf_rden
        // --  start_eng_display_seq_int                   ||eng_display_dbuf_rden_dly1
        // --  |eng_display_req_blocker                    |||eng_display_rtry_queue_rden
        // --  ||eng_display_ary_select_int_q[1:0]         ||||eng_display_rtry_queue_rddata_capture
        // --  |||                                         |||||eng_display_latch_rddata_capture
        // --  ||| arb_eng_misc_gnt                        ||||||eng_display_rddata_valid
        // --  ||| |                                       ||||||| 
        // --  ||10| eng_display_seq_q[4:0]                ||||||| eng_display_seq_d[4:0]
        // --  ||||| |                                     11||||| | 
        // --  98765 43210                                 1098765 43210
        // ---------------------------------------------------------------
           10'b0????_00001 :  eng_display_seq[11:0] =  12'b0000000_00001 ;  // --       Idle_ST ->      Idle_ST  - Wait for main sequencer to start this sequencer
           10'b11???_00001 :  eng_display_seq[11:0] =  12'b0000000_00010 ;  // --       Idle_ST ->   Wt4Idle_ST  - Start - Req Blocker IS active, move to wait_st
           10'b1000?_00001 :  eng_display_seq[11:0] =  12'b1100000_00100 ;  // --       Idle_ST ->       Req_ST  - Start - engine IS idle, assert misc arb req & dbuf rden
           10'b1001?_00001 :  eng_display_seq[11:0] =  12'b1001000_01000 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - engine IS idle, assert misc arb req & rtry_queue rden
           10'b101??_00001 :  eng_display_seq[11:0] =  12'b1000000_01000 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - engine IS idle, assert misc arb req (capturing latch info rather than array) 
        // ---------------------------------------------------------------  
           10'b?1???_00010 :  eng_display_seq[11:0] =  12'b0000000_00010 ;  // --    Wt4Idle_ST ->   Wt4Idle_ST  - Wait for Main Sequencer to go to Idle State
           10'b?000?_00010 :  eng_display_seq[11:0] =  12'b1100000_00100 ;  // --    Wt4Idle_ST ->       Req_ST  - Engine IS idle, assert misc arb req & dbuf rden
           10'b?001?_00010 :  eng_display_seq[11:0] =  12'b1001000_01000 ;  // --    Wt4Idle_ST ->    Wt4Gnt_ST  - engine IS idle, assert misc arb req & rtry_queue rden
           10'b?01??_00010 :  eng_display_seq[11:0] =  12'b1000000_01000 ;  // --    Wt4Idle_ST ->    Wt4Gnt_ST  - engine IS idle, assert misc arb req (capturing latch info rather than array)
        // ---------------------------------------------------------------  
           10'b?????_00100 :  eng_display_seq[11:0] =  12'b0010000_01000 ;  // --        Req_ST ->    Wt4Gnt_ST  - dbuf dataflow follows cpy_st dataflow, need a delayed version of rden
        // ---------------------------------------------------------------  
           10'b?00?0_01000 :  eng_display_seq[11:0] =  12'b0000000_01000 ;  // --     Wt4Gnt_ST ->    Wt4Gnt_ST  - Wait for grant from ARB  (dbuf)
           10'b?01?0_01000 :  eng_display_seq[11:0] =  12'b0001000_01000 ;  // --     Wt4Gnt_ST ->    Wt4Gnt_ST  - Wait for grant from ARB, (rtry queue), continue to assert rden
           10'b?1??0_01000 :  eng_display_seq[11:0] =  12'b0000000_01000 ;  // --     Wt4Gnt_ST ->    Wt4Gnt_ST  - Wait for grant from ARB, (latch groupings)
           10'b?00?1_01000 :  eng_display_seq[11:0] =  12'b0000000_10000 ;  // --     Wt4Gnt_ST -> RdDataVal_ST  - Grant (dbuf) - Data follows cpy_st dataflow
           10'b?01?1_01000 :  eng_display_seq[11:0] =  12'b0000100_10000 ;  // --     Wt4Gnt_ST -> RdDataVal_ST  - Grant (rtry queue) - capture data to be driven in nxt cycle
           10'b?1??1_01000 :  eng_display_seq[11:0] =  12'b0000010_10000 ;  // --     Wt4Gnt_ST -> RdDataVal_ST  - Grant (latch group 02) - capture data to be driven in nxt cycle
        // ---------------------------------------------------------------
           10'b?????_10000 :  eng_display_seq[11:0] =  12'b0000001_00001 ;  // --   RdDataVal_ST ->     Idle_ST  - drive request to arb, advance and wait for grant
        // ---------------------------------------------------------------  
            default        :  eng_display_seq[11:0] =  12'b0000000_00001 ;  // --      Default  ->      Idle_ST  - (Needed to make case "full" and prevent inferred latches)
        // ---------------------------------------------------------------

      endcase

      // -- Outputs
      eng_display_req                       =  eng_display_seq[11];
      eng_display_dbuf_rden                 =  eng_display_seq[10];
      eng_display_dbuf_rden_dly1            =  eng_display_seq[9];
      eng_display_rtry_queue_rden           =  eng_display_seq[8];
      eng_display_rtry_queue_rddata_capture =  eng_display_seq[7];
      eng_display_latch_rddata_capture      =  eng_display_seq[6];
      eng_display_rddata_valid              =  eng_display_seq[5];

      // -- Next State
      eng_display_seq_d[4:0] = ( reset || eng_display_seq_error ) ? 5'b1 : eng_display_seq[4:0];

    end // -- always @ *

  // -- Capture Read Data from the selected target array (note: dbuf data will follow its normal path through cpy_st_data route )
  always @*
    begin
      if ( eng_display_rtry_queue_rddata_capture )
        begin
          eng_display_rddata_d[63:30] = 34'b0;
          eng_display_rddata_d[29:28] =  rtry_queue_rddata[17:16];   //     Added for AFP3
          eng_display_rddata_d[27:20] =  { rtry_queue_func_rden_blocker, 2'b0, pending_cnt_q[4:0] };
          eng_display_rddata_d[19:16] =  resp_code_rddata[3:0];
          eng_display_rddata_d[15:0]  =  rtry_queue_rddata[15:0];
        end
      else if ( eng_display_latch_rddata_capture )
        begin
          if ( eng_display_addr_int_q[4:0] == 5'b00000 )
            begin
              eng_display_rddata_d[63:56] =  { rtry_queue_wraddr_q[7:0] };   // Note: [10:8] are below
              eng_display_rddata_d[55:48] =  { rtry_queue_rdaddr_q[7:0] };   // Note: [10:8] are below
              eng_display_rddata_d[47]    =  ~( pending_cnt_q[4:0] == 5'b0 );
              eng_display_rddata_d[46]    =  rtry_queue_func_rden_blocker;
              eng_display_rddata_d[45]    =  1'b0;   // eng_pe_terminate_q;
            
              eng_display_rddata_d[44] =  ~we_rtry_st_idle_st;           
              eng_display_rddata_d[43] =  ~intrpt_rtry_idle_st;
              eng_display_rddata_d[42] =  ~atomic_rtry_idle_st;
              eng_display_rddata_d[41] =  ~incr_rtry_idle_st;
              eng_display_rddata_d[40] =  ~wkhstthrd_rtry_idle_st;
              eng_display_rddata_d[39] =  ~cpy_rtry_st_idle_st;           
              eng_display_rddata_d[38] =  ~cpy_rtry_ld_idle_st;
              eng_display_rddata_d[37] =  ~xtouch_rtry_idle_st;
              eng_display_rddata_d[36] =  ~we_rtry_ld_idle_st;
            
            //eng_display_rddata_d[35] =  1'b0;
            //eng_display_rddata_d[34] =  1'b0;
            
            //eng_display_rddata_d[33] =   we_st_wt4rsp_st; 
              eng_display_rddata_d[35:33] = rtry_queue_wraddr_q[10:8];  //     Added for AFP3
              eng_display_rddata_d[32] =   intrpt_wt4rsp_st; 
              eng_display_rddata_d[31] =   atomic_wt4rsp_st;
              eng_display_rddata_d[30] =   incr_wt4strsp_st; 
              eng_display_rddata_d[29] =   incr_wt4ldrsp_st; 
              eng_display_rddata_d[28] =   wkhstthrd_wt4rsp_st;
              eng_display_rddata_d[27] =   cpy_st_wt4rsp_st; 
              eng_display_rddata_d[26] =   cpy_ld_wt4rsp_st; 
              eng_display_rddata_d[25] =   xtouch_wt4rsp_st;
              eng_display_rddata_d[24] =   we_ld_wt4rsp_st; 
            
              eng_display_rddata_d[23] =  ~wr_weq_idle_st;
              eng_display_rddata_d[22] =  ~we_st_idle_st;           
              eng_display_rddata_d[21] =  ~intrpt_idle_st;
              eng_display_rddata_d[10] =  ~atomic_idle_st;
              eng_display_rddata_d[19] =  ~incr_idle_st;
              eng_display_rddata_d[18] =  ~wkhstthrd_idle_st;
              eng_display_rddata_d[17] =  ~cpy_st_idle_st;           
              eng_display_rddata_d[16] =  ~cpy_ld_idle_st;
              eng_display_rddata_d[15] =  ~xtouch_idle_st;
              eng_display_rddata_d[14] =  ~we_ld_idle_st;
              eng_display_rddata_d[13] =  ~actag_idle_st;
              eng_display_rddata_d[12] =  ~main_idle_st;
            
            //eng_display_rddata_d[11] =  1'b0;  //we_cmd_length_is_zero_q;
            //eng_display_rddata_d[10] =  1'b0;  //we_cmd_is_undefined_q;
            //eng_display_rddata_d[9]  =  1'b0;  //we_cmd_is_bad_atomic_q;
              eng_display_rddata_d[11:9] = rtry_queue_rdaddr_q[10:8];  //     Added for AFP3
              eng_display_rddata_d[8]  =  we_cmd_is_atomic_cas_q;
              eng_display_rddata_d[7]  =  we_cmd_is_atomic_st_q;
              eng_display_rddata_d[6]  =  we_cmd_is_atomic_ld_q;
              eng_display_rddata_d[5]  =  1'b0;  //we_cmd_is_incr_q;
              eng_display_rddata_d[4]  =  we_cmd_is_wkhstthrd_q;
              eng_display_rddata_d[3]  =  1'b0;  //we_cmd_is_stop_q;
              eng_display_rddata_d[2]  =  we_cmd_is_intrpt_q;
              eng_display_rddata_d[1]  =  1'b0;  //we_cmd_is_xtouch_q;
              eng_display_rddata_d[0]  =  1'b0;  //we_cmd_is_copy_q;
            end

          else if ( eng_display_addr_int_q[4:0] == 5'b00001 )
            begin
              eng_display_rddata_d[63:60] =              we_rtry_st_state[3:0]   ; 
              eng_display_rddata_d[59:56] =   { 1'b0,         we_st_state[2:0] } ; 
              eng_display_rddata_d[55:52] =             intrpt_rtry_state[3:0]   ;
              eng_display_rddata_d[51:48] =   { 1'b0,        intrpt_state[2:0] } ;
              eng_display_rddata_d[47:44] =             atomic_rtry_state[3:0]   ; 
              eng_display_rddata_d[43:40] =                  atomic_state[3:0]   ; 
              eng_display_rddata_d[39:36] =               incr_rtry_state[4:1]   ; 
              eng_display_rddata_d[35:32] =                    incr_state[3:0]   ; 
              eng_display_rddata_d[31:28] =          wkhstthrd_rtry_state[3:0]   ;
              eng_display_rddata_d[27:24] =   { 1'b0,     wkhstthrd_state[2:0] } ;
              eng_display_rddata_d[23:20] =             cpy_rtry_st_state[3:0]   ;
              eng_display_rddata_d[19:16] =                           4'b0       ; // cpy_st_state[3:0]   ;
              eng_display_rddata_d[15:12] =             cpy_rtry_ld_state[3:0]   ;
              eng_display_rddata_d[11:8]  =                            4'b0      ; // cpy_ld_state[3:0]   ;
              eng_display_rddata_d[7:4]   =              we_rtry_ld_state[3:0]   ;
              eng_display_rddata_d[3:0]   =                   we_ld_state[3:0]   ;
            end

          else if ( eng_display_addr_int_q[4:0] == 5'b00010 )
           eng_display_rddata_d[63:0]  =  64'b0;   // { cpy_cmd_resp_rcvd_q [31:0], cpy_cmd_sent_q[31:0] };

          else if ( eng_display_addr_int_q[4:0] == 5'b00011 )
            eng_display_rddata_d[63:0]  =  xtouch_ea_q[63:0];  // { cmd_we_ea_q[63:5], 5'b0 };      Changed for AFP3

          else if ( eng_display_addr_int_q[4:0] == 5'b00100 && ~memcpy2_format_enable_q )
            begin
              eng_display_rddata_d[63:48] = { 6'b0,  cmd_pasid_q[9:0] };   //cmd_pasid_q[15:0]
              eng_display_rddata_d[47:32] = { 1'b0, 14'b0, 1'b0 };  //{ cmd_we_wrap_q, cmd_offset_q[18:5], 1'b0 }; 
              eng_display_rddata_d[31:24] =   we_cmd_extra_q[7:0];
              eng_display_rddata_d[23:8]  =   we_cmd_length_q[15:0];
              eng_display_rddata_d[7:2]   =   6'b0;  //we_cmd_encode_q[5:0];
              eng_display_rddata_d[1]     =   1'b0;  //we_cmd_wrap_q; 
              eng_display_rddata_d[0]     =   1'b0;
            end

          else if ( eng_display_addr_int_q[4:0] == 5'b00100 && memcpy2_format_enable_q )
            begin
              eng_display_rddata_d[63]    =   1'b0;
              eng_display_rddata_d[62]    =   1'b0;  //we_cmd_wrap_q; 
              eng_display_rddata_d[61:56] =   6'b0;  //we_cmd_encode_q[5:0];
              eng_display_rddata_d[55:40] =   we_cmd_length_q[15:0];
              eng_display_rddata_d[39:32] =   we_cmd_extra_q[7:0];
              eng_display_rddata_d[31:16] = { 1'b0, 14'b0, 1'b0 };  //{ cmd_we_wrap_q, cmd_offset_q[18:5], 1'b0 };
              eng_display_rddata_d[15:0]  = { 6'b0,  cmd_pasid_q[9:0] };   // cmd_pasid_q[15:0];
            end 

          else if ( eng_display_addr_int_q[4:0] == 5'b00101 )
            eng_display_rddata_d[63:0]  =   we_cmd_atomic_op1_q[63:0]; 

          else if ( eng_display_addr_int_q[4:0] == 5'b00110 )
            eng_display_rddata_d[63:0]  =   { cpy_st_ea_q[63:6], 6'b0 };  //we_cmd_source_ea_q[63:0];      Changed for AFP3

          else if ( eng_display_addr_int_q[4:0] == 5'b00111 )
            eng_display_rddata_d[63:0]  =   we_cmd_dest_ea_q[63:0]; 

          else
             eng_display_rddata_d[63:34]     =  30'b0;
             eng_display_rddata_d[33:31]     =  3'b0;  //weq_eng_wed[23:21];
             eng_display_rddata_d[30:28]     =  3'b0;  //weq_eng_wed[15:13];
             eng_display_rddata_d[27]        =  1'b0;  //we_cmd_is_atomic_q;
             eng_display_rddata_d[26]        =  incr_rtry_state[5];
             eng_display_rddata_d[25]        =  incr_rtry_state[0];
             eng_display_rddata_d[24]        =  cpy_rtry_st_state[4];
             eng_display_rddata_d[23:22]     =  actag_state[1:0];
             eng_display_rddata_d[21:16]     =  xtouch_rtry_state[5:0];
             eng_display_rddata_d[15:12]     =  xtouch_state[3:0];
             eng_display_rddata_d[11:5]      =  7'b0;              // main_state[11:5];
             eng_display_rddata_d[4:0]       =  main_state[4:0];
         end
      else
        eng_display_rddata_d[63:0]  =  64'b0;
    end // -- always @ *

    // -- Drive valid back to mmio
    // --   - this is active same cycle data is on the bus to cmdo
    // --   - mmio should latch this to align with the same cycle cmdo presents latched/muxed data to mmio
    assign  eng_mmio_display_rddata_valid =  eng_display_rddata_valid;

    //    assign  eng_display_ary_select_q[1:0] =  eng_display_ary_select_int_q[1:0];
    assign  eng_display_addr_q[9:0]       =  eng_display_addr_int_q[9:0];

    assign  eng_display_data[63:0]        =  eng_display_rddata_q[63:0];

 
  // -- ********************************************************************************************************************************
  // -- Latch Assignments
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      eng_display_seq_q[4:0]                      <= eng_display_seq_d[4:0];
      eng_display_rdval_q                         <= eng_display_rdval_d;          
      if ( eng_display_cmdinfo_en )
        begin        
          eng_display_ary_select_int_q[1:0]       <= eng_display_ary_select_int_d[1:0];
          //    eng_display_eng_select_q[4:0]           <= eng_display_eng_select_d[4:0];
          eng_display_addr_int_q[9:0]             <= eng_display_addr_int_d[9:0];
        end
      eng_display_rddata_q[63:0]                  <= eng_display_rddata_d[63:0];

    end // -- always @ *

endmodule
