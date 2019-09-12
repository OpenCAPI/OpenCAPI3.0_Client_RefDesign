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

module afp3_eng_fsm_xtouch 
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config & Misc Inputs
//     , input                 mmio_eng_xtouch_source_enable
//     , input                 mmio_eng_xtouch_dest_enable
  , input                 mmio_eng_xtouch_wt4rsp_enable
//     , input           [5:0] mmio_eng_xtouch_ageout_pg_size
//     , input           [1:0] xtouch_type_sel
//     , input           [4:0] xtouch_flag_sel
  , input                 mmio_eng_xtouch_type   // 0 - xlate_touch, 1 - xlate_touch.n
  , input                 mmio_eng_xtouch_hwt    // 0 - lightweight, 1 - heavyweight
  , input                 rtry_backoff_timer_disable_q

//   -unused  , input                 immed_terminate_enable_q
//   -unused  , input                 num_cmds_sent_eq_resp_rcvd
//   -unused  , input                 eng_pe_terminate_q


  // -- Command Inputs
//     , input                 we_cmd_is_xtouch_d
//     , input           [2:0] we_cmd_extra_q
//     , input          [63:0] we_cmd_source_ea_q
  , input          [63:0] xtouch_ea_q
  , input          [63:0] we_cmd_dest_ea_q
//     , input           [9:0] cmd_pasid_q
  , input                 rtry_decode_is_hwt

  , input           [5:0] eng_num
  , input          [11:0] eng_actag
  , input           [7:0] cfg_afu_bdf_bus 
  , input           [4:0] cfg_afu_bdf_device
  , input           [2:0] cfg_afu_bdf_function

  // -- Main Sequencer Control Inputs & Arbitration Interface
  , input                 start_xtouch_seq
  , input                 rspi_xtouch_source_resp_val_q
  , input                 rspi_xtouch_dest_resp_val_q

  , output                xtouch_req
  , input                 arb_eng_misc_gnt

  // -- Main Sequencer Outputs
  , output                xtouch_seq_done
  , output                xtouch_seq_error

  , output          [3:0] xtouch_state
  , output                xtouch_idle_st
  , output                xtouch_wt4gnt1_st
  , output                xtouch_wt4gnt2_st
  , output                xtouch_wt4rsp_st

  // -- Rtry Sequencer Control Inputs & Arbitration Interface
  , input                 start_xtouch_rtry_source_seq
  , input                 start_xtouch_rtry_dest_seq
  , input                 rtry_decode_is_immediate
  , input                 rtry_decode_is_backoff
  , input                 rtry_decode_is_abort
  , input                 xtouch_rtry_source_backoff_done
  , input                 xtouch_rtry_source_backoff_done_q
  , input                 xtouch_rtry_dest_backoff_done
  , input                 xtouch_rtry_dest_backoff_done_q

  , output                xtouch_rtry_req
  , input                 arb_eng_rtry_misc_gnt

  // -- Rtry Sequencer Outputs
  , output                xtouch_rtry_seq_error

  , output          [5:0] xtouch_rtry_state
  , output                xtouch_rtry_idle_st
  , output                xtouch_rtry_wt4bckoff1_st
  , output                xtouch_rtry_wt4gnt1_st
  , output                xtouch_rtry_wt4bckoff2_st
  , output                xtouch_rtry_wt4gnt2_st
  , output                xtouch_rtry_abort_st

  // -- Command Bus
  , output reg            xtouch_valid
  , output reg      [7:0] xtouch_opcode
  , output reg     [11:0] xtouch_actag
  , output reg      [3:0] xtouch_stream_id 
  , output reg     [67:0] xtouch_ea_or_obj
  , output reg     [15:0] xtouch_afutag
  , output reg      [1:0] xtouch_dl
  , output reg      [2:0] xtouch_pl
  , output reg            xtouch_os
  , output reg     [63:0] xtouch_be
  , output reg      [3:0] xtouch_flag
  , output reg            xtouch_endian
  , output reg     [15:0] xtouch_bdf
//     , output reg     [19:0] xtouch_pasid
  , output reg      [5:0] xtouch_pg_size

  // -- Repowered Mode Bits
//     , output reg            xtouch_enable_q
  , output                xtouch_wt4rsp_enable_q

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- Mode/Config
  wire            xtouch_source_enable;
  wire            xtouch_dest_enable;
  wire            xtouch_wt4rsp_enable;

  // -- Main Sequencer Signals
  wire      [9:0] xtouch_seq_sel;
  reg       [5:0] xtouch_seq;
  wire            xtouch_seq_err_int;
  wire            xtouch_seq_done_int;
  wire            xtouch_req_int;

  wire            xtouch_idle_state;
  wire            xtouch_wt4gnt1_state;
  wire            xtouch_wt4gnt2_state;
  wire            xtouch_wt4rsp_state;

  // -- Rtry Sequencer Signals
  wire     [15:0] xtouch_rtry_seq_sel;
  reg       [6:0] xtouch_rtry_seq;
  wire            xtouch_rtry_seq_err_int;

  wire            xtouch_rtry_idle_state;
  wire            xtouch_rtry_wt4bckoff1_state;
  wire            xtouch_rtry_wt4gnt1_state;
  wire            xtouch_rtry_wt4bckoff2_state;
  wire            xtouch_rtry_wt4gnt2_state;
  wire            xtouch_rtry_abort_state;

  // -- Signals that have dependency on command randomizaton
  reg       [7:0] xtouch_opcode_rand;
  reg       [3:0] xtouch_flag_rand;
  reg       [3:0] xtouch_rtry_flag_rand;

  wire            xtouch_source_cmd_sent;
  wire            xtouch_dest_cmd_sent;
  wire            xtouch_source_rsp_rcvd;
  wire            xtouch_dest_rsp_rcvd;
  wire            xtouch_all_rsp_rcvd;


  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  // -- Mode/Config latches
//     wire            xtouch_enable_d;
//reg             xtouch_enable_q;
//     wire            xtouch_source_enable_d;
//     reg             xtouch_source_enable_q;
//     wire            xtouch_dest_enable_d;
//     reg             xtouch_dest_enable_q;
  wire            xtouch_wt4rsp_enable_int_d;
  reg             xtouch_wt4rsp_enable_int_q;
//     reg       [5:0] xtouch_ageout_pg_size_d;
//     reg       [5:0] xtouch_ageout_pg_size_q;

  // -- Sequencer latches
  wire      [3:0] xtouch_seq_d;
  reg       [3:0] xtouch_seq_q;

  wire      [5:0] xtouch_rtry_seq_d;
  reg       [5:0] xtouch_rtry_seq_q;

  // -- Scorecard latches
  wire            xtouch_cmd_sent_en;
  reg       [1:0] xtouch_cmd_sent_d;
  reg       [1:0] xtouch_cmd_sent_q;

  wire            xtouch_rsp_rcvd_en;
  reg       [1:0] xtouch_rsp_rcvd_d;
  reg       [1:0] xtouch_rsp_rcvd_q;


  // -- ********************************************************************************************************************************
  // -- Constant declarations 
  // -- ********************************************************************************************************************************

  // -- AFUTAG Encode
  localparam    [4:0] XTOUCH_SOURCE_AFUTAG_ENCODE              = 5'b00010;     // -- AFUTAG[4:0] for xtouch_source cmd           ( AFUTAG[11] = b'1 )
  localparam    [4:0] XTOUCH_DEST_AFUTAG_ENCODE                = 5'b00011;     // -- AFUTAG[4:0] for xtouch_dest cmd             ( AFUTAG[11] = b'1 )

  // -- TLX AP command encodes
  localparam    [7:0] AFU_TLX_CMD_ENCODE_XLATE_TOUCH           = 8'b01111000;  // -- Address translation prefetch
  localparam    [7:0] AFU_TLX_CMD_ENCODE_XLATE_TOUCH_N         = 8'b01111001;  // -- Address translation prefetch


  // -- ********************************************************************************************************************************
  // -- Mode/Config Bit Repower Latches
  // -- ********************************************************************************************************************************

//     assign  xtouch_source_enable_d     =  mmio_eng_xtouch_source_enable;
//     assign  xtouch_dest_enable_d       =  mmio_eng_xtouch_dest_enable;
  assign  xtouch_wt4rsp_enable_int_d =  mmio_eng_xtouch_wt4rsp_enable;

/*      always @*
    begin
      if ( ~we_cmd_is_xtouch_d )
        begin 
          xtouch_source_enable =   xtouch_source_enable_q;
          xtouch_dest_enable   =   xtouch_dest_enable_q;
          xtouch_wt4rsp_enable =   xtouch_wt4rsp_enable_int_q;
        end
      else
        begin 
          xtouch_source_enable =  (( we_cmd_extra_q[0] == 1'b1 ) || ( we_cmd_extra_q[1:0] == 2'b0 ));  // -- Default to Source enabled
          xtouch_dest_enable   =   ( we_cmd_extra_q[1] == 1'b1 );                                      // -- Dest only if specified by xtouch
          xtouch_wt4rsp_enable =  (( we_cmd_extra_q[2] == 1'b1 ) || ( we_cmd_extra_q[1:0] == 2'b0 ));  // -- Default to wait for resp enabled
        end
    end  // -- always @*


  assign  xtouch_enable_d            = ( mmio_eng_xtouch_source_enable || mmio_eng_xtouch_dest_enable );
*/

  // For AFP, only need one xtouch at a time.  Will use Source tag, and leave Dest logic unused.
  // Tying values to avoid changing state machine.
  assign  xtouch_source_enable       =  1'b1;
  assign  xtouch_dest_enable         =  1'b0;
  assign  xtouch_wt4rsp_enable       =  xtouch_wt4rsp_enable_int_q;
  // -- Drive out to rtry module
  assign  xtouch_wt4rsp_enable_q =  xtouch_wt4rsp_enable;


/* AFP does not send AgeOut command
  // -- Default the ageout page size if one not specified
  always @*
    begin
      if ( | mmio_eng_xtouch_ageout_pg_size[5:0] == 1'b1 )
        xtouch_ageout_pg_size_d[5:0] =  mmio_eng_xtouch_ageout_pg_size[5:0];
      else
        xtouch_ageout_pg_size_d[5:0] =  6'b010000;  // -- If nothing specified, default to 2**bin2dec(010000) = 2**16 = 64K page size
    end  // -- always @*
*/


  // -- ********************************************************************************************************************************
  // -- xtouch State Machine 
  // -- ********************************************************************************************************************************

  // -- This state machine was added to test xlate touch commands - it was not part of the original design point and is certainly not functionally needed

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc04  xtouch_seq_err (
    .one_hot_vector   ( xtouch_seq_q[3:0] ),
    .one_hot_error    ( xtouch_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage)
  assign  xtouch_idle_state    =  xtouch_seq_q[0];  // -- State 0 - xtouch_idle_st     - Issue assign xtouch cmd request when leaving idle
  assign  xtouch_wt4gnt1_state =  xtouch_seq_q[1];  // -- State 1 - xtouch_wt4gnt1_st  - Wait for grant (latched) to present xtouch cmd for source ea on cycle after the grant 
  assign  xtouch_wt4gnt2_state =  xtouch_seq_q[2];  // -- State 2 - xtouch_wt4gnt2_st  - Wait for grant (latched) to present xtouch cmd for dest ea on cycle after the grant 
  assign  xtouch_wt4rsp_state  =  xtouch_seq_q[3];  // -- State 3 - xtouch_wt4rsp_st   - Wait for response(s) 

  // -- Sequencer Inputs
  assign  xtouch_seq_sel[9:0] = { start_xtouch_seq, xtouch_source_enable, xtouch_dest_enable, arb_eng_misc_gnt, xtouch_wt4rsp_enable, xtouch_all_rsp_rcvd, xtouch_seq_q[3:0] };

  // -- Sequencer Table
  always @*
    begin
      casez ( xtouch_seq_sel[9:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------
        // --  start_xtouch_seq
        // --  |xtouch_source_enable
        // --  ||xtouch_dest_enable                 Outputs & Next State
        // --  |||arb_eng_misc_gnt                  --------------------
        // --  ||||xtouch_wt4rsp_enable             xtouch_req
        // --  |||||xtouch_all_rsp_rcvd             |xtouch_seq_done
        // --  |||||| xtouch_seq_q                  || xtouch_seq_d
        // --  |||||| |                             || |
        // --  987654 3210                          54 3210
        // --------------------------------------------------
           10'b0?????_0001 :  xtouch_seq[5:0] =  6'b00_0001 ;  // --     Idle_ST -> Idle_ST    - Wait for Main Sequencer to start this sequencer
           10'b11????_0001 :  xtouch_seq[5:0] =  6'b10_0010 ;  // --     Idle_ST -> Wt4Gnt1_ST - Issue arb request to send xtouch cmd for source ea
           10'b101???_0001 :  xtouch_seq[5:0] =  6'b10_0100 ;  // --     Idle_ST -> Wt4Gnt2_ST - Issue arb request to send xtouch cmd for dest ea
           10'b100???_0001 :  xtouch_seq[5:0] =  6'b01_0001 ;  // --     Idle_ST -> Idle_ST    - Nothing enabled, indicate done back to main sequencer (should not happen)
        // --------------------------------------------------
           10'b???0??_0010 :  xtouch_seq[5:0] =  6'b00_0010 ;  // --  Wt4Gnt1_ST -> Wt4Gnt1_ST - Wait for grant (latched) to send source xtouch cmd
           10'b??11??_0010 :  xtouch_seq[5:0] =  6'b10_0100 ;  // --  Wt4Gnt1_ST -> Wt4Gnt2_ST - Got grant to send xtouch for source ea, Issue arb request to send xtouch for dest ea
           10'b??010?_0010 :  xtouch_seq[5:0] =  6'b01_0001 ;  // --  Wt4Gnt1_ST ->    Idle_ST - Got grant to send xtouch for source ea, Return to Idle
           10'b??011?_0010 :  xtouch_seq[5:0] =  6'b00_1000 ;  // --  Wt4Gnt1_ST ->  Wt4Rsp_ST - Got grant to send xtouch for source ea, Go wait for response
        // --------------------------------------------------
           10'b???0??_0100 :  xtouch_seq[5:0] =  6'b00_0100 ;  // --  Wt4Gnt2_ST -> Wt4Gnt2_ST - Wait for grant (latched) to send dest xtouch cmd
           10'b???10?_0100 :  xtouch_seq[5:0] =  6'b01_0001 ;  // --  Wt4Gnt2_ST ->    Idle_ST - Got grant to send xtouch for dest ea, Return to Idle
           10'b???11?_0100 :  xtouch_seq[5:0] =  6'b00_1000 ;  // --  Wt4Gnt2_ST ->  Wt4Rsp_ST - Got grant to send xtouch for dest ea, Go Wait for response(s)
        // --------------------------------------------------
           10'b?????0_1000 :  xtouch_seq[5:0] =  6'b00_1000 ;  // --   Wt4Rsp_ST ->  Wt4Rsp_ST - Wait for response(s)
           10'b?????1_1000 :  xtouch_seq[5:0] =  6'b01_0001 ;  // --   Wt4Rsp_ST ->    Idle_ST - All reponses received
        // --------------------------------------------------
            default        :  xtouch_seq[5:0] =  6'b01_0001 ;  // --     default -> Idle_ST   - (Needed to make case "full" to prevent inferred latches)
        // --------------------------------------------------
      endcase
    end // -- always @ *

  // -- Outputs
  assign  xtouch_req_int      =  xtouch_seq[5];
  assign  xtouch_seq_done_int =  xtouch_seq[4];

  // -- Outputs (For External Usage)
  assign  xtouch_req        =  xtouch_req_int;
  assign  xtouch_seq_done   =  xtouch_seq_done_int;

  // -- State Outputs (For External Usage)
  assign  xtouch_state[3:0] =  xtouch_seq_q[3:0];
  assign  xtouch_idle_st    =  xtouch_idle_state;
  assign  xtouch_wt4gnt1_st =  xtouch_wt4gnt1_state; 
  assign  xtouch_wt4gnt2_st =  xtouch_wt4gnt2_state;
  assign  xtouch_wt4rsp_st  =  xtouch_wt4rsp_state;

  // -- Error
  assign  xtouch_seq_error =  xtouch_seq_err_int;

  // -- Next State
  assign  xtouch_seq_d[3:0] = ( reset || xtouch_seq_err_int ) ? 4'b1 : xtouch_seq[3:0];


  // -- ********************************************************************************************************************************
  // -- xtouch_rtry State Machine 
  // -- ********************************************************************************************************************************

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc06  xtouch_rtry_seq_err (
    .one_hot_vector   ( xtouch_rtry_seq_q[5:0] ),
    .one_hot_error    ( xtouch_rtry_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage)
  assign  xtouch_rtry_idle_state       =  xtouch_rtry_seq_q[0];  // -- Wait for delayed read of retry queue to trigger the start of this sequencer
  assign  xtouch_rtry_wt4bckoff1_state =  xtouch_rtry_seq_q[1];  // -- Wait for backoff timer to count down 
  assign  xtouch_rtry_wt4gnt1_state    =  xtouch_rtry_seq_q[2];  // -- Wait for grant to present cmd on cycle after the grant 
  assign  xtouch_rtry_wt4bckoff2_state =  xtouch_rtry_seq_q[3];  // -- Wait for backoff timer to count down 
  assign  xtouch_rtry_wt4gnt2_state    =  xtouch_rtry_seq_q[4];  // -- Wait for grant to present cmd on cycle after the grant 
  assign  xtouch_rtry_abort_state      =  xtouch_rtry_seq_q[5];  // -- Abort the retry 

  // -- Sequencer Inputs
  assign xtouch_rtry_seq_sel[15:0] = { start_xtouch_rtry_source_seq, start_xtouch_rtry_dest_seq, ( rtry_decode_is_immediate || rtry_backoff_timer_disable_q ), rtry_decode_is_backoff, rtry_decode_is_abort,
                                    xtouch_rtry_source_backoff_done_q, xtouch_rtry_source_backoff_done, xtouch_rtry_dest_backoff_done_q, xtouch_rtry_dest_backoff_done,
                                    arb_eng_rtry_misc_gnt, xtouch_rtry_seq_q[5:0] };
  // -- Sequencer Table
  always @*
    begin
      casez ( xtouch_rtry_seq_sel[15:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------  
        // --  start_xtouch_rtry_source_seq
        // --  |start_xtouch_rtry_dest_seq      
        // --  ||rtry_decode_is_immediate       
        // --  |||rtry_decode_is_backoff 
        // --  ||||rtry_decode_is_abort     
        // --  |||||xtouch_rtry_source_backoff_done_q
        // --  ||||||xtouch_rtry_source_backoff_done 
        // --  |||||||xtouch_rtry_dest_backoff_done_q         Outputs & Next State
        // --  ||||||||xtouch_rtry_dest_backoff_done           --------------------
        // --  |||||||||arb_eng_rtry_misc_gnt                  xtouch_rtry_req
        // --  |||||||||| xtouch_rtry_seq_q[5:0]               | xtouch_rtry_seq_d[5:0]
        // --  1111|||||| |                                    | |
        // --  5432109876 543210                               6 543210
        // -------------------------------------------------------------
           16'b00????????_000001 :  xtouch_rtry_seq[6:0] =  7'b0_000001 ;  // --        Idle_ST ->       Idle_ST  - Wait for valid xtouch rtry (source or dest)
           16'b1?1???????_000001 :  xtouch_rtry_seq[6:0] =  7'b1_000100 ;  // --        Idle_ST ->    Wt4Gnt1_ST  - Start - No Backoff, move directly to wt4gnt State
           16'b1?01?00???_000001 :  xtouch_rtry_seq[6:0] =  7'b0_000010 ;  // --        Idle_ST -> Wt4BckOff1_ST  - Start - Backoff Required, Still in progress, move to wt4bckoff State
           16'b1?01?1????_000001 :  xtouch_rtry_seq[6:0] =  7'b1_000100 ;  // --        Idle_ST ->    Wt4Gnt1_ST  - Start - Backoff Required, but already done, move directly to wt4gnt State
           16'b1?01?01???_000001 :  xtouch_rtry_seq[6:0] =  7'b1_000100 ;  // --        Idle_ST ->    Wt4Gnt1_ST  - Start - Backoff Required, but already done, move directly to wt4gnt State
           16'b1?001?????_000001 :  xtouch_rtry_seq[6:0] =  7'b0_100000 ;  // --        Idle_ST ->      Abort_ST  - Start - Abort
           16'b011???????_000001 :  xtouch_rtry_seq[6:0] =  7'b1_010000 ;  // --        Idle_ST ->    Wt4Gnt2_ST  - Start - No Backoff, move directly to wt4gnt State
           16'b0101???00?_000001 :  xtouch_rtry_seq[6:0] =  7'b0_001000 ;  // --        Idle_ST -> Wt4BckOff2_ST  - Start - Backoff Required, Still in progress, move to wt4bckoff State
           16'b0101???1??_000001 :  xtouch_rtry_seq[6:0] =  7'b1_010000 ;  // --        Idle_ST ->    Wt4Gnt2_ST  - Start - Backoff Required, but already done, move directly to wt4gnt State
           16'b0101???01?_000001 :  xtouch_rtry_seq[6:0] =  7'b1_010000 ;  // --        Idle_ST ->    Wt4Gnt2_ST  - Start - Backoff Required, but already done, move directly to wt4gnt State
           16'b01001?????_000001 :  xtouch_rtry_seq[6:0] =  7'b0_100000 ;  // --        Idle_ST ->      Abort_ST  - Start - Abort
        // -------------------------------------------------------------  
           16'b??????0???_000010 :  xtouch_rtry_seq[6:0] =  7'b0_000010 ;  // --  Wt4BckOff1_ST -> Wt4BckOff1_ST  - Wait for Backoff Timer to count down
           16'b??????1???_000010 :  xtouch_rtry_seq[6:0] =  7'b1_000100 ;  // --  Wt4BckOff1_ST ->    Wt4Gnt1_ST  - Timer expired, drive request to arb, advance and wait for grant
        // -------------------------------------------------------------  
           16'b?????????0_000100 :  xtouch_rtry_seq[6:0] =  7'b0_000100 ;  // --     Wt4Gnt1_ST ->    Wt4Gnt1_ST  - Wait for grant from ARB
           16'b?????????1_000100 :  xtouch_rtry_seq[6:0] =  7'b0_000001 ;  // --     Wt4Gnt1_ST ->       Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle Immediately
        // -------------------------------------------------------------
           16'b????????0?_001000 :  xtouch_rtry_seq[6:0] =  7'b0_001000 ;  // --  Wt4BckOff2_ST -> Wt4BckOff2_ST  - Wait for Backoff Timer to count down
           16'b????????1?_001000 :  xtouch_rtry_seq[6:0] =  7'b1_010000 ;  // --  Wt4BckOff2_ST ->    Wt4Gnt2_ST  - Timer expired, drive request to arb, advance and wait for grant
        // -------------------------------------------------------------  
           16'b?????????0_010000 :  xtouch_rtry_seq[6:0] =  7'b0_010000 ;  // --     Wt4Gnt2_ST ->    Wt4Gnt2_ST  - Wait for grant from ARB
           16'b?????????1_010000 :  xtouch_rtry_seq[6:0] =  7'b0_000001 ;  // --     Wt4Gnt2_ST ->       Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle Immediately
        // -------------------------------------------------------------
           16'b??????????_100000 :  xtouch_rtry_seq[6:0] =  7'b0_000001 ;  // --       Abort_ST ->       Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle Immediately
        // -------------------------------------------------------------
            default              :  xtouch_rtry_seq[6:0] =  7'b0_000001 ;  // --       Default  ->       Idle_ST  - (Needed to make case "full" and prevent inferred latches)
        // -------------------------------------------------------------

      endcase
    end // -- always @ *

  // -- Outputs
  assign  xtouch_rtry_req =  xtouch_rtry_seq[6];

  // -- State Outputs (For External Usage)
  assign  xtouch_rtry_state[5:0]    =  xtouch_rtry_seq_q[5:0];
  assign  xtouch_rtry_idle_st       =  xtouch_rtry_idle_state;
  assign  xtouch_rtry_wt4bckoff1_st =  xtouch_rtry_wt4bckoff1_state;
  assign  xtouch_rtry_wt4gnt1_st    =  xtouch_rtry_wt4gnt1_state;
  assign  xtouch_rtry_wt4bckoff2_st =  xtouch_rtry_wt4bckoff2_state;
  assign  xtouch_rtry_wt4gnt2_st    =  xtouch_rtry_wt4gnt2_state;
  assign  xtouch_rtry_abort_st      =  xtouch_rtry_abort_state;

  // -- Error
  assign  xtouch_rtry_seq_error =  xtouch_rtry_seq_err_int;

  // -- Next State
  assign  xtouch_rtry_seq_d[5:0] = ( reset || xtouch_rtry_seq_err_int ) ? 6'b1 : xtouch_rtry_seq[5:0];


  // -- ********************************************************************************************************************************
  // -- Command Bus Out
  // -- ********************************************************************************************************************************

  // -- Support for Command Randomization
  // -- AFP does not randomize
  always @*
    begin
/*         // -- Opcode
      if ( xtouch_type_sel[0] )
        xtouch_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_XLATE_TOUCH[7:0];
      else if ( xtouch_type_sel[1] )
        xtouch_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_XLATE_TOUCH_N[7:0];
      else
        xtouch_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_XLATE_TOUCH[7:0];

      // -- Flag (Presented with Original Command)
      if ( xtouch_flag_sel[0] )
        xtouch_flag_rand[3:0] =  4'b0000;  // -- Lightweight, Read Only, no TA
      else if ( xtouch_flag_sel[1] )
        xtouch_flag_rand[3:0] =  4'b0010;  // -- Lightweight, Write, no TA  
      else if ( xtouch_flag_sel[2] )
        xtouch_flag_rand[3:0] =  4'b0100;  // -- Heavyweight, Read Only, no TA 
      else if ( xtouch_flag_sel[3] )
        xtouch_flag_rand[3:0] =  4'b0110;  // -- Heavyweight, Write, no TA 
      else if ( xtouch_flag_sel[4] )
        xtouch_flag_rand[3:0] =  4'b0001;  // -- Age Out
      else
        xtouch_flag_rand[3:0] =  4'b0000;  // -- Lightweight, Read Only, no TA

      // -- Flag (Presented with Retried Command) - Has dependency on original command
      if      ( ~rtry_decode_is_hwt && ~xtouch_flag_rand[1] )      // -- Use original flag bit 1 to determine Read Only vs Write on Retry command
        xtouch_rtry_flag_rand[3:0] =  4'b0000;  // -- Lightweight, Read Only, no TA
      else if ( ~rtry_decode_is_hwt &&  xtouch_flag_rand[1] )
        xtouch_rtry_flag_rand[3:0] =  4'b0010;  // -- Lightweight, Write, no TA  
      else if ( rtry_decode_is_hwt && ~xtouch_flag_rand[1] )
        xtouch_rtry_flag_rand[3:0] =  4'b0100;  // -- Heavyweight, Read Only, no TA 
      else if ( rtry_decode_is_hwt &&  xtouch_flag_rand[1] )
        xtouch_rtry_flag_rand[3:0] =  4'b0110;  // -- Heavyweight, Write, no TA 
      else
        xtouch_rtry_flag_rand[3:0] =  4'b0000;  // -- Lightweight, Read Only, no TA
      // -- NOTE: xtouch command w/ ageout flag should not see retry
*/
      // -- Opcode
      if ( ~mmio_eng_xtouch_type )
        xtouch_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_XLATE_TOUCH[7:0];
      else
        xtouch_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_XLATE_TOUCH_N[7:0];

      // -- Flag (Presented with Original Command)
      if ( ~mmio_eng_xtouch_hwt )
        xtouch_flag_rand[3:0] =  4'b0010;  // -- Lightweight, Write, no TA  
      else
        xtouch_flag_rand[3:0] =  4'b0110;  // -- Heavyweight, Write, no TA

      // -- Flag (Presented with Retried Command) - Has dependency on original command
      if ( ~rtry_decode_is_hwt )
        xtouch_rtry_flag_rand[3:0] =  4'b0010;  // -- Lightweight, Write, no TA  
      else
        xtouch_rtry_flag_rand[3:0] =  4'b0110;  // -- Heavyweight, Write, no TA
    end // -- always @ *

  // -- Form the command
  always @*
    begin
      if ( xtouch_wt4gnt1_state || xtouch_rtry_wt4gnt1_state || xtouch_wt4gnt2_state || xtouch_rtry_wt4gnt2_state )
        begin
          xtouch_valid             =  (((      xtouch_wt4gnt1_state ||      xtouch_wt4gnt2_state ) &&      arb_eng_misc_gnt) ||
                                       (( xtouch_rtry_wt4gnt1_state || xtouch_rtry_wt4gnt2_state ) && arb_eng_rtry_misc_gnt ));
          xtouch_opcode[7:0]       =     xtouch_opcode_rand[7:0];
          xtouch_actag[11:0]       =     eng_actag[11:0];
          xtouch_stream_id[3:0]    =     4'b0;
          if ( xtouch_wt4gnt1_state || xtouch_rtry_wt4gnt1_state )
            begin
              xtouch_ea_or_obj[67:0] =  {  4'b0,  xtouch_ea_q[63:0] };  //     we_cmd_source_ea_q[63:0] };
              xtouch_afutag[15:0]    =  {  2'b00, 3'b001, eng_num[5:0], XTOUCH_SOURCE_AFUTAG_ENCODE[4:0] };
            end
          else // -- if ( xtouch_wt4gnt2_state || xtouch_rtry_wt4gnt2_state )
            begin
              xtouch_ea_or_obj[67:0] =  {  4'b0,  we_cmd_dest_ea_q[63:0] };
              xtouch_afutag[15:0]    =  {  2'b00, 3'b001, eng_num[5:0], XTOUCH_DEST_AFUTAG_ENCODE[4:0] };
            end
          xtouch_dl[1:0]           =     2'b00;
          xtouch_pl[2:0]           =     3'b000;
          xtouch_os                =     1'b0;
          xtouch_be[63:0]          =    64'b0;
          if ( xtouch_wt4gnt1_state || xtouch_wt4gnt2_state )
            xtouch_flag[3:0]       =     xtouch_flag_rand[3:0];
 // --    else if ( xtouch_rtry_wt4gnt1_state || xtouch_rtry_wt4gnt2_state )           // -- Change for Lint error - 11/27/18
          else // -- if ( xtouch_rtry_wt4gnt1_state || xtouch_rtry_wt4gnt2_state )     // -- Change for Lint error - 11/27/18
            xtouch_flag[3:0]       =     xtouch_rtry_flag_rand[3:0];
          xtouch_endian            =     1'b0;
          xtouch_bdf[15:0]         =  { cfg_afu_bdf_bus[7:0], cfg_afu_bdf_device[4:0], cfg_afu_bdf_function[2:0] };
//             xtouch_pasid[19:0]       =  { 10'b0, cmd_pasid_q[9:0] };
//             if ( xtouch_flag_sel[4] )
//               xtouch_pg_size[5:0]    =     xtouch_ageout_pg_size_q[5:0];
//             else 
            xtouch_pg_size[5:0]    =     6'b0;
        end
      else
        begin
          xtouch_valid           =    1'b0;
          xtouch_opcode[7:0]     =    8'b0;
          xtouch_actag[11:0]     =   12'b0;
          xtouch_stream_id[3:0]  =    4'b0;
          xtouch_ea_or_obj[67:0] =   68'b0;
          xtouch_afutag[15:0]    =   16'b0;
          xtouch_dl[1:0]         =    2'b0;
          xtouch_pl[2:0]         =    3'b0;
          xtouch_os              =    1'b0;
          xtouch_be[63:0]        =   64'b0;
          xtouch_flag[3:0]       =    4'b0;
          xtouch_endian          =    1'b0;
          xtouch_bdf[15:0]       =   16'b0;
//             xtouch_pasid[19:0]     =   20'b0;
          xtouch_pg_size[5:0]    =    6'b0;
        end

    end // -- always @ *


  // -- ********************************************************************************************************************************
  // -- Score card for xlate touch cmds sent and responses received.
  // -- ********************************************************************************************************************************

  assign  xtouch_source_cmd_sent  =  xtouch_wt4gnt1_state && arb_eng_misc_gnt;
  assign  xtouch_dest_cmd_sent    =  xtouch_wt4gnt2_state && arb_eng_misc_gnt;

  assign  xtouch_source_rsp_rcvd  =  rspi_xtouch_source_resp_val_q;
  assign  xtouch_dest_rsp_rcvd    =  rspi_xtouch_dest_resp_val_q;

  assign  xtouch_cmd_sent_en      =  (( xtouch_wt4rsp_enable && ( xtouch_source_cmd_sent || xtouch_dest_cmd_sent )) || xtouch_seq_done_int || reset );
  always @*
    begin
      if ( xtouch_wt4rsp_enable && ( xtouch_source_cmd_sent || xtouch_dest_cmd_sent ) && ~reset )
        xtouch_cmd_sent_d[1:0]  =  ( xtouch_cmd_sent_q[1:0] | { xtouch_dest_cmd_sent, xtouch_source_cmd_sent } );
      else
        xtouch_cmd_sent_d[1:0]  =  2'b0;
    end // -- always @ *

  assign xtouch_rsp_rcvd_en      =  (( xtouch_wt4rsp_enable && ( xtouch_source_rsp_rcvd || xtouch_dest_rsp_rcvd )) || xtouch_seq_done_int || reset );
  always @*
    begin
      if ( xtouch_wt4rsp_enable && ( xtouch_source_rsp_rcvd || xtouch_dest_rsp_rcvd ) && ~reset )
        xtouch_rsp_rcvd_d[1:0]  =  ( xtouch_rsp_rcvd_q[1:0] | { xtouch_dest_rsp_rcvd, xtouch_source_rsp_rcvd } );
      else
        xtouch_rsp_rcvd_d[1:0]  =  2'b0;
    end // -- always @ *

  assign  xtouch_all_rsp_rcvd     =  xtouch_wt4rsp_state && ( xtouch_cmd_sent_q[1:0] == xtouch_rsp_rcvd_q[1:0] );


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      // -- Modes/Config
//         xtouch_enable_q                              <= xtouch_enable_d;
//         xtouch_source_enable_q                       <= xtouch_source_enable_d;
//         xtouch_dest_enable_q                         <= xtouch_dest_enable_d;
      xtouch_wt4rsp_enable_int_q                   <= xtouch_wt4rsp_enable_int_d;
//         xtouch_ageout_pg_size_q[5:0]                 <= xtouch_ageout_pg_size_d[5:0];

      // -- Sequencers
      xtouch_seq_q[3:0]                            <= xtouch_seq_d[3:0];        
      xtouch_rtry_seq_q[5:0]                       <= xtouch_rtry_seq_d[5:0];

      // -- Scorecard
      if ( xtouch_cmd_sent_en )
        xtouch_cmd_sent_q[1:0]                     <= xtouch_cmd_sent_d[1:0];
      if ( xtouch_rsp_rcvd_en )
        xtouch_rsp_rcvd_q[1:0]                     <= xtouch_rsp_rcvd_d[1:0]; 

    end // -- always @ *

endmodule
