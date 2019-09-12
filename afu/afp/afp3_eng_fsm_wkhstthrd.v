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

module afp3_eng_fsm_wkhstthrd 
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config & Misc Inputs
  , input                 rtry_backoff_timer_disable_q
//   -unused  , input                 immed_terminate_enable_q
//   -unused  , input                 num_cmds_sent_eq_resp_rcvd
//   -unused  , input                 eng_pe_terminate_q

  // -- Command Inputs
//     , input           [9:0] cmd_pasid_q
//     , input          [15:0] we_cmd_length_q
//     , input           [0:0] we_cmd_extra_q
  , input          [15:0] mmio_eng_wkhstthrd_tid
  , input                 mmio_eng_wkhstthrd_flag

  , input           [5:0] eng_num
  , input          [11:0] eng_actag
  , input           [7:0] cfg_afu_bdf_bus 
  , input           [4:0] cfg_afu_bdf_device
  , input           [2:0] cfg_afu_bdf_function

  // -- Main Sequencer Control Inputs & Arbitration Interface
  , input                 start_wkhstthrd_seq
  , input                 rspi_wkhstthrd_resp_val_q

  , output                wkhstthrd_req
  , input                 arb_eng_misc_gnt

  // -- Main Sequencer Outputs
  , output                wkhstthrd_seq_done
  , output                wkhstthrd_seq_error

  , output          [2:0] wkhstthrd_state
  , output                wkhstthrd_idle_st
  , output                wkhstthrd_wt4gnt_st
  , output                wkhstthrd_wt4rsp_st

  // -- Rtry Sequencer Control Inputs & Arbitration Interface
  , input                 start_wkhstthrd_rtry_seq
  , input                 rtry_decode_is_immediate
  , input                 rtry_decode_is_backoff
  , input                 rtry_decode_is_abort
  , input                 wkhstthrd_rtry_backoff_done
  , input                 wkhstthrd_rtry_backoff_done_q

  , output                wkhstthrd_rtry_req
  , input                 arb_eng_rtry_misc_gnt

  // -- Rtry Sequencer Outputs
  , output                wkhstthrd_rtry_seq_error

  , output          [3:0] wkhstthrd_rtry_state
  , output                wkhstthrd_rtry_idle_st
  , output                wkhstthrd_rtry_wt4bckoff_st
  , output                wkhstthrd_rtry_wt4gnt_st
  , output                wkhstthrd_rtry_abort_st

  // -- Command Bus
  , output reg            wkhstthrd_valid
  , output reg      [7:0] wkhstthrd_opcode
  , output reg     [11:0] wkhstthrd_actag
  , output reg      [3:0] wkhstthrd_stream_id 
  , output reg     [67:0] wkhstthrd_ea_or_obj
  , output reg     [15:0] wkhstthrd_afutag
  , output reg      [1:0] wkhstthrd_dl
  , output reg      [2:0] wkhstthrd_pl
  , output reg            wkhstthrd_os
  , output reg     [63:0] wkhstthrd_be
  , output reg      [3:0] wkhstthrd_flag
  , output reg            wkhstthrd_endian
  , output reg     [15:0] wkhstthrd_bdf
//     , output reg     [19:0] wkhstthrd_pasid
  , output reg      [5:0] wkhstthrd_pg_size

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- Main Sequencer Signals
  wire      [5:0] wkhstthrd_seq_sel;
  reg       [4:0] wkhstthrd_seq;
  wire            wkhstthrd_seq_err_int;

  wire            wkhstthrd_idle_state;
  wire            wkhstthrd_wt4gnt_state;
  wire            wkhstthrd_wt4rsp_state;

  // -- Rtry Sequencer Signals
  wire     [10:0] wkhstthrd_rtry_seq_sel;
  reg       [4:0] wkhstthrd_rtry_seq;
  wire            wkhstthrd_rtry_seq_err_int;

  wire            wkhstthrd_rtry_idle_state;
  wire            wkhstthrd_rtry_wt4bckoff_state;
  wire            wkhstthrd_rtry_wt4gnt_state;
  wire            wkhstthrd_rtry_abort_state;


  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  // -- Sequencer latches
  wire      [2:0] wkhstthrd_seq_d;
  reg       [2:0] wkhstthrd_seq_q;

  wire      [3:0] wkhstthrd_rtry_seq_d;
  reg       [3:0] wkhstthrd_rtry_seq_q;


  // -- ********************************************************************************************************************************
  // -- Constant declarations 
  // -- ********************************************************************************************************************************

  // -- AFUTAG Encode
  localparam    [4:0] WKHSTTHRD_AFUTAG_ENCODE                  = 5'b00110;     // -- AFUTAG[4:0] for wkhstthrd cmd               ( AFUTAG[11] = b'1 )

  // -- TLX AP command encodes
  localparam    [7:0] AFU_TLX_CMD_ENCODE_WAKE_HOST_THREAD      = 8'b01011100;  // -- Wake Host Thread


  // -- ********************************************************************************************************************************
  // -- wkhstthrd State Machine
  // -- ********************************************************************************************************************************

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc03  wkhstthrd_seq_err (
    .one_hot_vector   ( wkhstthrd_seq_q[2:0] ),
    .one_hot_error    ( wkhstthrd_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage)
  assign  wkhstthrd_idle_state   =  wkhstthrd_seq_q[0];  // -- State 0 - wkhstthrd_idle_st   - Wait for Main sequencer to start this sequencer
  assign  wkhstthrd_wt4gnt_state =  wkhstthrd_seq_q[1];  // -- State 1 - wkhstthrd_wt4gnt_st - Wait for grant to present cmd on cycle after the grant 
  assign  wkhstthrd_wt4rsp_state =  wkhstthrd_seq_q[2];  // -- State 2 - wkhstthrd_wt4rsp_st - Enter this state after the we store has been sent (req+gnt), wait for response to come back

  // -- Inputs
  assign  wkhstthrd_seq_sel[5:0] = { start_wkhstthrd_seq, arb_eng_misc_gnt, rspi_wkhstthrd_resp_val_q, wkhstthrd_seq_q[2:0] };

  always @*
    begin
      casez ( wkhstthrd_seq_sel[5:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------              Outputs & Next State
        // --  start_wkhstthrd_seq                 --------------------
        // --  |arb_eng_misc_gnt                   wkhstthrd_req
        // --  ||rspi_wkhstthrd_resp_val_q         |wkhstthrd_seq_done
        // --  ||| wkhstthrd_seq_q                 || wkhstthrd_seq_d
        // --  ||| |                               || |
        // --  543 210                             43 210
        // -----------------------------------------------
            6'b0??_001 :  wkhstthrd_seq[4:0] =  5'b00_001 ;  // --    Idle_ST ->   Idle_ST  - Wait for main sequencer to start this sequencer
            6'b1??_001 :  wkhstthrd_seq[4:0] =  5'b10_010 ;  // --    Idle_ST -> Wt4Gnt_ST  - Start - move to Req State
        // -----------------------------------------------
            6'b?0?_010 :  wkhstthrd_seq[4:0] =  5'b00_010 ;  // --  Wt4Gnt_ST -> Wt4Gnt_ST  - Wait for grant from ARB
            6'b?1?_010 :  wkhstthrd_seq[4:0] =  5'b00_100 ;  // --  Wt4Gnt_ST -> Wt4Rsp_ST  - Grant, drive cmd in nxt cycle, go wait for response
        // -----------------------------------------------
            6'b??0_100 :  wkhstthrd_seq[4:0] =  5'b00_100 ;  // --  Wt4Rsp_ST -> Wt4Rsp_ST  - Wait for response
            6'b??1_100 :  wkhstthrd_seq[4:0] =  5'b01_001 ;  // --  Wt4Rsp_ST ->   Idle_ST  - Response received, go to idle, tell main seq done
        // -----------------------------------------------
            default    :  wkhstthrd_seq[4:0] =  5'b01_001 ;  // --    Idle_ST ->   Idle_ST  - (Needed to make case "full" to prevent inferred latches)
        // -----------------------------------------------
      endcase
    end // -- always @ *                                  

  // -- Outputs  
  assign  wkhstthrd_req      =  wkhstthrd_seq[4];
  assign  wkhstthrd_seq_done =  wkhstthrd_seq[3];

  // -- State Outputs (For External Usage)
  assign  wkhstthrd_state[2:0] =  wkhstthrd_seq_q[2:0]; 
  assign  wkhstthrd_idle_st    =  wkhstthrd_idle_state;
  assign  wkhstthrd_wt4gnt_st  =  wkhstthrd_wt4gnt_state;
  assign  wkhstthrd_wt4rsp_st  =  wkhstthrd_wt4rsp_state;

  // -- Error
  assign  wkhstthrd_seq_error =  wkhstthrd_seq_err_int;

  // -- Next State
  assign  wkhstthrd_seq_d[2:0] = ( reset || wkhstthrd_seq_err_int ) ? 3'b1 :  wkhstthrd_seq[2:0];


  // -- ********************************************************************************************************************************
  // -- wkhstthrd rtry State Machine
  // -- ********************************************************************************************************************************

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc04  wkhstthrd_rtry_seq_err (
    .one_hot_vector   ( wkhstthrd_rtry_seq_q[3:0] ),
    .one_hot_error    ( wkhstthrd_rtry_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage)
  assign  wkhstthrd_rtry_idle_state      =  wkhstthrd_rtry_seq_q[0];  // -- Wait for delayed read of retry queue to trigger the start of this sequencer
  assign  wkhstthrd_rtry_wt4bckoff_state =  wkhstthrd_rtry_seq_q[1];  // -- Wait for backoff timer to count down 
  assign  wkhstthrd_rtry_wt4gnt_state    =  wkhstthrd_rtry_seq_q[2];  // -- Wait for grant to present cmd on cycle after the grant 
  assign  wkhstthrd_rtry_abort_state     =  wkhstthrd_rtry_seq_q[3];  // -- Abort the retry 

  // -- Sequencer Inputs
  assign  wkhstthrd_rtry_seq_sel[10:0] = { start_wkhstthrd_rtry_seq, ( rtry_decode_is_immediate || rtry_backoff_timer_disable_q ), rtry_decode_is_backoff, rtry_decode_is_abort,
                                           wkhstthrd_rtry_backoff_done_q,  wkhstthrd_rtry_backoff_done, arb_eng_rtry_misc_gnt, wkhstthrd_rtry_seq_q[3:0] };
  // -- Sequencer
  always @*
    begin
      casez ( wkhstthrd_rtry_seq_sel[10:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------
        // --  start_wkhstthrd_rtry_seq    
        // --  |rtry_decode_is_immediate
        // --  ||rtry_decode_is_backoff 
        // --  |||rtry_decode_is_abort           
        // --  ||||wkhstthrd_rtry_backoff_done_q             Outputs & Next State
        // --  |||||wkhstthrd_rtry_backoff_done              --------------------
        // --  ||||||arb_eng_rtry_misc_gnt                   wkhstthrd_rtry_req
        // --  ||||||| wkhstthrd_rtry_seq_q[2:0]             | wkhstthrd_rtry_seq_d[3:0]
        // --  1|||||| |                                     | |
        // --  0987654 3210                                  4 3210
        // ----------------------------------------------------------
           11'b0??????_0001 :  wkhstthrd_rtry_seq[4:0] =  5'b0_0001 ;  // --       Idle_ST ->      Idle_ST  - Wait for valid wkhstthrd rtry
           11'b11?????_0001 :  wkhstthrd_rtry_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - No Backoff Required, move directly to wt4gnt State
           11'b101?00?_0001 :  wkhstthrd_rtry_seq[4:0] =  5'b0_0010 ;  // --       Idle_ST -> Wt4Bckoff_ST  - Start - Backoff Required, in progress, move to wt4bckoff State
           11'b101?1??_0001 :  wkhstthrd_rtry_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - Backoff Required, but already done, move directly to wt4gnt State
           11'b101?01?_0001 :  wkhstthrd_rtry_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - Backoff Required, but already done, move directly to wt4gnt State
           11'b1001???_0001 :  wkhstthrd_rtry_seq[4:0] =  5'b0_1000 ;  // --       Idle_ST ->     Abort_ST  - Start - Abort, then return to idle State
        // ----------------------------------------------------------          
           11'b?????0?_0010 :  wkhstthrd_rtry_seq[4:0] =  5'b0_0010 ;  // --  Wt4BckOff_ST -> Wt4BckOff_ST  - Wait for backoff timer to count down
           11'b?????1?_0010 :  wkhstthrd_rtry_seq[4:0] =  5'b1_0100 ;  // --  Wt4BckOff_ST ->    Wt4Gnt_ST  - Timer expired, issue request to ARB, move to wt4gnt_st State
        // ----------------------------------------------------------         
           11'b??????0_0100 :  wkhstthrd_rtry_seq[4:0] =  5'b0_0100 ;  // --     Wt4Gnt_ST ->    Wt4Gnt_ST  - Wait for grant from ARB
           11'b??????1_0100 :  wkhstthrd_rtry_seq[4:0] =  5'b0_0001 ;  // --     Wt4Gnt_ST ->      Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle
        // ----------------------------------------------------------          
           11'b???????_1000 :  wkhstthrd_rtry_seq[4:0] =  5'b0_0001 ;  // --     Wt4Gnt_ST ->      Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle
        // ----------------------------------------------------------          
            default         :  wkhstthrd_rtry_seq[4:0] =  5'b0_0001 ;  // --      Default  ->      Idle_ST  - (Needed to make case "full" to prevent inferred latches)
        // ----------------------------------------------------------
      endcase
    end // -- always @ *

  // -- Outputs
  assign  wkhstthrd_rtry_req =  wkhstthrd_rtry_seq[4];

  // -- State Outputs (For External Usage)
  assign  wkhstthrd_rtry_state[3:0]   =  wkhstthrd_rtry_seq_q[3:0]; 
  assign  wkhstthrd_rtry_idle_st      =  wkhstthrd_rtry_idle_state;     
  assign  wkhstthrd_rtry_wt4bckoff_st =  wkhstthrd_rtry_wt4bckoff_state;
  assign  wkhstthrd_rtry_wt4gnt_st    =  wkhstthrd_rtry_wt4gnt_state;   
  assign  wkhstthrd_rtry_abort_st     =  wkhstthrd_rtry_abort_state;

  // -- Error
  assign  wkhstthrd_rtry_seq_error    =  wkhstthrd_rtry_seq_err_int;

  // -- Next State
  assign  wkhstthrd_rtry_seq_d[3:0] = ( reset || wkhstthrd_rtry_seq_err_int ) ? 4'b1 : wkhstthrd_rtry_seq[3:0];


  // -- ********************************************************************************************************************************
  // -- Command Bus Out
  // -- ********************************************************************************************************************************

  // -- Form the command
  always @*
    begin

      if ( wkhstthrd_wt4gnt_state || wkhstthrd_rtry_wt4gnt_state )
        begin
          wkhstthrd_valid           =  (( wkhstthrd_wt4gnt_state && arb_eng_misc_gnt ) || ( wkhstthrd_rtry_wt4gnt_state && arb_eng_rtry_misc_gnt ));
          wkhstthrd_opcode[7:0]     =     AFU_TLX_CMD_ENCODE_WAKE_HOST_THREAD[7:0];
          wkhstthrd_actag[11:0]     =     eng_actag[11:0];
          wkhstthrd_stream_id[3:0]  =     4'b0;
          //    if ( we_cmd_extra_q[0] )
          //      wkhstthrd_ea_or_obj[67:0] =  { 52'b0, we_cmd_length_q[15:0] };      // -- length field contains TID rather than length for wkhstthrd cmd
          if ( mmio_eng_wkhstthrd_flag )
            wkhstthrd_ea_or_obj[67:0] =  { 52'b0, mmio_eng_wkhstthrd_tid[15:0] };
          else
            wkhstthrd_ea_or_obj[67:0] =    68'b0;
          wkhstthrd_afutag[15:0]    =  {  2'b00, 3'b001, eng_num[5:0], WKHSTTHRD_AFUTAG_ENCODE[4:0] }; 
          wkhstthrd_dl[1:0]         =     2'b00;
          wkhstthrd_pl[2:0]         =     3'b000;
          wkhstthrd_os              =     1'b0;
          wkhstthrd_be[63:0]        =    64'b0;
          //    wkhstthrd_flag[3:0]       =  {  3'b0, we_cmd_extra_q[0] };
          wkhstthrd_flag[3:0]       =  {  3'b0, mmio_eng_wkhstthrd_flag };
          wkhstthrd_endian          =     1'b0;
          wkhstthrd_bdf[15:0]       =  { cfg_afu_bdf_bus[7:0], cfg_afu_bdf_device[4:0], cfg_afu_bdf_function[2:0] };
//             wkhstthrd_pasid[19:0]     =  { 10'b0, cmd_pasid_q[9:0] };
          wkhstthrd_pg_size[5:0]    =     6'b0;
        end
      else
        begin
          wkhstthrd_valid           =    1'b0;
          wkhstthrd_opcode[7:0]     =    8'b0;
          wkhstthrd_actag[11:0]     =   12'b0;
          wkhstthrd_stream_id[3:0]  =    4'b0;
          wkhstthrd_ea_or_obj[67:0] =   68'b0;
          wkhstthrd_afutag[15:0]    =   16'b0;
          wkhstthrd_dl[1:0]         =    2'b0;
          wkhstthrd_pl[2:0]         =    3'b0;
          wkhstthrd_os              =    1'b0;
          wkhstthrd_be[63:0]        =   64'b0;
          wkhstthrd_flag[3:0]       =    4'b0;
          wkhstthrd_endian          =    1'b0;
          wkhstthrd_bdf[15:0]       =   16'b0;
//             wkhstthrd_pasid[19:0]     =   20'b0;
          wkhstthrd_pg_size[5:0]    =    6'b0;
        end

    end // -- always @ *


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      wkhstthrd_seq_q[2:0]                            <= wkhstthrd_seq_d[2:0];        
      wkhstthrd_rtry_seq_q[3:0]                       <= wkhstthrd_rtry_seq_d[3:0];        

    end // -- always @ *

endmodule
