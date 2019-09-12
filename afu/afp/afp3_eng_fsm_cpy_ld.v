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

module afp3_eng_fsm_cpy_ld 
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config & Misc Inputs
  //    , input                 mmio_eng_256B_op_disable
  //    , input                 mmio_eng_128B_op_disable
  , input           [1:0] mmio_eng_ld_size
  , input                 cpy_ld_type_sel
  , input                 rtry_backoff_timer_disable_q

  //    , input                 immed_terminate_enable_q
  //    , input                 num_cmds_sent_eq_resp_rcvd
  //    , input                 eng_pe_terminate_q

  // -- Command Inputs
  //    , input                 we_ld_capture_cmd
  //    , input                 we_ld_seq_done
  //    , input          [11:0] we_cmd_length_d
  //    , input          [63:6] we_cmd_source_ea_d
  //    , input          [63:6] we_cmd_source_ea_q
  //    , input           [9:0] cmd_pasid_q

  , input           [8:0] cpy_rtry_xx_afutag_q
  , input           [1:0] cpy_rtry_xx_dl_q
  //    , input          [63:6] cpy_rtry_ld_ea_q

  //    , input           [5:0] eng_num
  , input          [11:0] eng_actag
  , input           [7:0] cfg_afu_bdf_bus 
  , input           [4:0] cfg_afu_bdf_device
  , input           [2:0] cfg_afu_bdf_function

  // -- Main Sequencer Control Inputs & Arbitration Interface
  //    , input                 start_cpy_ld_seq
  , input          [63:6] cpy_ld_ea_q
  //    - unused on mcp3, input                 arb_ld_gnt_q
  , input                 rspi_cpy_ld_resp_val_q
  , input          [1:0]  rspi_resp_dl_q
  , input          [8:0]  rspi_resp_afutag_q

  //      , output                cpy_ld_req
  , input                 arb_eng_ld_gnt
  , input           [8:0] arb_eng_ld_tag
  , output        [511:0] eng_arb_set_ld_tag_avail
  , output                eng_arb_ld_fastpath_valid
  , output          [8:0] eng_arb_ld_fastpath_tag

  // -- Main Sequencer Outputs
  //    , output                cpy_ld_seq_done
  //    , output                cpy_ld_seq_error

  //    , output          [3:0] cpy_ld_state
  //    , output                cpy_ld_idle_st
  //    , output                cpy_ld_req_st
  //    , output                cpy_ld_wt4gnt_st
  //    , output                cpy_ld_wt4rsp_st

  // -- Rtry Sequencer Control Inputs & Arbitration Interface
  , input                 start_cpy_rtry_ld_seq
  , input                 rtry_decode_is_immediate
  , input                 rtry_decode_is_backoff
  , input                 rtry_decode_is_abort
  , input           [8:0] rtry_queue_afutag_q     
  , input           [1:0] rtry_queue_dl_q
  , input                 cpy_rtry_ld_backoff_done
  , input                 cpy_rtry_ld_backoff_done_q

  , output                eng_arb_rtry_ld_req
  , input                 arb_eng_rtry_ld_gnt

  // -- Rtry Sequencer Outputs
  , output                cpy_rtry_ld_seq_error

  , output          [3:0] cpy_rtry_ld_state
  , output                cpy_rtry_ld_idle_st
  , output                cpy_rtry_ld_wt4bckoff_st
  , output                cpy_rtry_ld_wt4gnt_st
  , output                cpy_rtry_ld_abort_st

  // -- Command Bus
  , output reg            cpy_ld_valid
  , output reg      [7:0] cpy_ld_opcode
  , output reg     [11:0] cpy_ld_actag
  , output reg      [3:0] cpy_ld_stream_id 
  , output reg     [67:0] cpy_ld_ea_or_obj
  , output reg     [15:0] cpy_ld_afutag
  , output reg      [1:0] cpy_ld_dl
  , output reg      [2:0] cpy_ld_pl
  , output reg            cpy_ld_os
  , output reg     [63:0] cpy_ld_be
  , output reg      [3:0] cpy_ld_flag
  , output reg            cpy_ld_endian
  , output reg     [15:0] cpy_ld_bdf
  //     , output reg     [19:0] cpy_ld_pasid
  , output reg      [5:0] cpy_ld_pg_size

  // -- Drive outbound to scorecard
  //    , output          [8:6] cpy_ld_size_q
  //    , output          [4:0] cpy_ld_afutag_q

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- Retry Sequencer Signals
  wire     [10:0] cpy_rtry_ld_seq_sel;
  reg       [4:0] cpy_rtry_ld_seq;
  wire            cpy_rtry_ld_seq_err_int;

  wire            cpy_rtry_ld_idle_state;
  wire            cpy_rtry_ld_wt4bckoff_state;
  wire            cpy_rtry_ld_wt4gnt_state;
  wire            cpy_rtry_ld_abort_state;

  wire            cpy_rtry_ld_req_int;

  // -- Retry Address Lookup
  wire            rtry_ea_wren;
  wire      [8:0] rtry_ea_wraddr;
  wire     [31:7] rtry_ea_wrdata;

  wire            rtry_ea_rden;
  wire      [8:0] rtry_ea_rdaddr;
  wire     [31:7] rtry_ea_rddata;

  wire            cpy_rtry_ld_ea_bit7;
  wire     [63:6] cpy_rtry_ld_ea;

  // -- Signals that have dependency on command type
  reg       [7:0] cpy_ld_opcode_int;

  // -- Command response tracking
  wire      [8:0] afutag_masked;
  wire    [511:0] afutag_decoded;
  wire    [511:0] afutag_decoded_valid;

  wire            rtry_abort_valid;
  wire      [8:0] rtry_afutag_masked;
  wire    [511:0] rtry_afutag_decoded;
  wire    [511:0] rtry_afutag_decoded_abort;

  // -- Command response fastpath
  wire            curr_resp_length;
  wire            fastpath_valid;

  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  // -- Sequencer latches
  wire      [3:0] cpy_rtry_ld_seq_d;
  reg       [3:0] cpy_rtry_ld_seq_q;
       
  wire            cpy_ld_resp_length_en;
  reg     [255:0] cpy_ld_resp_length_d;
  reg     [255:0] cpy_ld_resp_length_q;

  reg       [1:0] mmio_eng_ld_size_q;

  wire            resp_valid_dly1_d;
  reg             resp_valid_dly1_q;

  wire            resp_valid_dly2_d;
  reg             resp_valid_dly2_q;

  // -- ********************************************************************************************************************************
  // -- Constant declarations 
  // -- ********************************************************************************************************************************

  // -- TLX AP command encodes
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC              = 8'b00010000;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC_N            = 8'b00010100;  // -- Read with no intent to cache


  // -- ********************************************************************************************************************************
  // -- cpy_ld State Machine 
  // -- ********************************************************************************************************************************

  // --  64B, 128B, & 256B load cmds are available

  // -- State Outputs (For External Usage)
  //assign  cpy_ld_wt4rsp_st  =  1'b1;   // AFP - Moved signal to fsm_main


  // -- ********************************************************************************************************************************
  // -- Calculate next load size and corresponding next EA and AFUTAG
  // -- ********************************************************************************************************************************

  // -- NOTE: Source EA, Size, and AFUTag need to be held until grant so that they can be presented to cmdo 1 cycle after grant
  // --       Length and EA offset are updated earlier so that size calculation can be done in advance



  // -- ********************************************************************************************************************************
  // -- cpy_rtry_ld State Machine 
  // -- ********************************************************************************************************************************

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc04  cpy_rtry_ld_seq_err (
    .one_hot_vector   ( cpy_rtry_ld_seq_q[3:0] ),
    .one_hot_error    ( cpy_rtry_ld_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage)
  assign  cpy_rtry_ld_idle_state      =  cpy_rtry_ld_seq_q[0];  // -- Wait for delayed read of retry queue to trigger the start of this sequencer
  assign  cpy_rtry_ld_wt4bckoff_state =  cpy_rtry_ld_seq_q[1];  // -- Wait for backoff timer to count down 
  assign  cpy_rtry_ld_wt4gnt_state    =  cpy_rtry_ld_seq_q[2];  // -- Wait for grant to present cmd on cycle after the grant 
  assign  cpy_rtry_ld_abort_state     =  cpy_rtry_ld_seq_q[3];  // -- Abort the retry 

  // -- Sequencer Inputs
  assign  cpy_rtry_ld_seq_sel[10:0] = { start_cpy_rtry_ld_seq, ( rtry_decode_is_immediate || rtry_backoff_timer_disable_q ), rtry_decode_is_backoff, rtry_decode_is_abort,
                                        cpy_rtry_ld_backoff_done_q, cpy_rtry_ld_backoff_done, arb_eng_rtry_ld_gnt, cpy_rtry_ld_seq_q[3:0] };
  // -- Sequencer Table
  always @*
    begin
      casez ( cpy_rtry_ld_seq_sel[10:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------  
        // --  start_cpy_rtry_ld_seq     
        // --  |rtry_decode_is_immediate
        // --  ||rtry_decode_is_backoff 
        // --  |||rtry_decode_is_abort         
        // --  ||||cpy_rtry_ld_backoff_done_q             Outputs & Next State
        // --  |||||cpy_rtry_ld_backoff_done              --------------------
        // --  ||||||arb_eng_rtry_ld_gnt                  cpy_rtry_ld_req
        // --  ||||||| cpy_rtry_ld_seq_q[3:0]             | cpy_rtry_ld_seq_d[3:0]
        // --  1|||||| |                                  | |
        // --  0987654 3210                               4 3210
        // ------------------------------------------------------
           11'b0??????_0001 :  cpy_rtry_ld_seq[4:0] =  5'b0_0001 ;  // --       Idle_ST ->      Idle_ST  - Wait for valid cpy rtry ld
           11'b11?????_0001 :  cpy_rtry_ld_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - No Backoff, move directly to wt4gnt State
           11'b101?00?_0001 :  cpy_rtry_ld_seq[4:0] =  5'b0_0010 ;  // --       Idle_ST -> Wt4BckOff_ST  - Start - Backoff Required, Still in progress, move to wt4bckoff State
           11'b101?1??_0001 :  cpy_rtry_ld_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - Backoff Required, but already done, move directly to wt4gnt State
           11'b101?01?_0001 :  cpy_rtry_ld_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - Backoff Required, but already done, move directly to wt4gnt State
           11'b1001???_0001 :  cpy_rtry_ld_seq[4:0] =  5'b0_1000 ;  // --       Idle_ST ->     Abort_ST  - Start - Abort
        // ------------------------------------------------------  
           11'b?????0?_0010 :  cpy_rtry_ld_seq[4:0] =  5'b0_0010 ;  // --  Wt4BckOff_ST -> Wt4BckOff_ST  - Wait for Backoff Timer to count down
           11'b?????1?_0010 :  cpy_rtry_ld_seq[4:0] =  5'b1_0100 ;  // --  Wt4BckOff_ST ->    Wt4Gnt_ST  - Timer expired, drive request to arb, advance and wait for grant
        // ------------------------------------------------------  
           11'b??????0_0100 :  cpy_rtry_ld_seq[4:0] =  5'b0_0100 ;  // --     Wt4Gnt_ST -   > Wt4Gnt_ST  - Wait for grant from ARB
           11'b??????1_0100 :  cpy_rtry_ld_seq[4:0] =  5'b0_0001 ;  // --     Wt4Gnt_ST ->      Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle Immediately
        // ------------------------------------------------------
           11'b???????_1000 :  cpy_rtry_ld_seq[4:0] =  5'b0_0001 ;  // --      Abort_ST ->      Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle Immediately
        // ------------------------------------------------------
            default         :  cpy_rtry_ld_seq[4:0] =  5'b0_0001 ;  // --      Default  ->      Idle_ST  - (Needed to make case "full" and prevent inferred latches)
        // ------------------------------------------------------

      endcase
    end // -- always @ *

  // -- Outputs
  assign  eng_arb_rtry_ld_req =  cpy_rtry_ld_seq[4];
  assign  cpy_rtry_ld_req_int =  cpy_rtry_ld_seq[4];

  // -- State Outputs (For External Usage)
  assign  cpy_rtry_ld_state[3:0]   =  cpy_rtry_ld_seq_q[3:0];
  assign  cpy_rtry_ld_idle_st      =  cpy_rtry_ld_idle_state;
  assign  cpy_rtry_ld_wt4bckoff_st =  cpy_rtry_ld_wt4bckoff_state;
  assign  cpy_rtry_ld_wt4gnt_st    =  cpy_rtry_ld_wt4gnt_state;
  assign  cpy_rtry_ld_abort_st     =  cpy_rtry_ld_abort_state;

  // -- Error
  assign  cpy_rtry_ld_seq_error  =  cpy_rtry_ld_seq_err_int;

  // -- Next State
  assign  cpy_rtry_ld_seq_d[3:0] = ( reset || cpy_rtry_ld_seq_err_int ) ? 4'b1 : cpy_rtry_ld_seq[3:0];


  // -- ********************************************************************************************************************************
  // -- Retry Address Lookup
  // -- ********************************************************************************************************************************
  assign  rtry_ea_wren         =  arb_eng_ld_gnt;
  assign  rtry_ea_wraddr[8:0]  =  arb_eng_ld_tag[8:0];
  assign  rtry_ea_wrdata[31:7] =  cpy_ld_ea_q[31:7];

  assign  rtry_ea_rden         =  cpy_rtry_ld_req_int;

  //  cpy_rtry_xx_afutag_q contains the retry afutag that needs to be sent, so that we don't need to keep around DP from the response.
  //  (This is handled in afp3_eng_rtry_queue.v)
  //  If the original command was 256B, the original tag is even.
  //  We could receive two 128B responses.  If DP was for the 2nd half, cpy_rtry_xx_afutag_q will be odd.
  //  For 256B ops, the original EA is only stored in the even entries of the array.  Odd entries are unused for 256B.
  //  For 256B ops, zero-out rdaddr[0], so that we read the original EA
  assign  rtry_ea_rdaddr[8:0]  =  {cpy_rtry_xx_afutag_q[8:1], (cpy_rtry_xx_afutag_q[0] & ~(mmio_eng_ld_size_q[1:0] == 2'b11)) };

  // -- retry queue array
  mcp3_ram512x025  rtry_queue
    ( .clk   ( clock ),

      .wren  ( rtry_ea_wren ),
      .wrad  ( rtry_ea_wraddr[8:0] ),
      .data  ( rtry_ea_wrdata[31:7] ),

      .rden  ( rtry_ea_rden ),
      .rdad  ( rtry_ea_rdaddr[8:0] ),
      .q     ( rtry_ea_rddata[31:7] )
    );

  // [63:32] - Base Address from WED
  // [31:8]  - Address sent in original command
  // [7] - Address sent in original command, or which half of 256B address is retried
  // [6:0] - Zeros
  assign  cpy_rtry_ld_ea_bit7   = rtry_ea_rddata[7] || ((mmio_eng_ld_size_q[1:0] == 2'b11) && cpy_rtry_xx_afutag_q[0]);
  assign  cpy_rtry_ld_ea[63:6]  = { cpy_ld_ea_q[63:32],  rtry_ea_rddata[31:8], cpy_rtry_ld_ea_bit7, 1'b0 };

  // -- ********************************************************************************************************************************
  // -- Command Bus Out
  // -- ********************************************************************************************************************************

  // -- Support for Command Type
  always @*
    begin
      if ( cpy_ld_type_sel == 1'b0 )
        cpy_ld_opcode_int[7:0] =  AFU_TLX_CMD_ENCODE_RD_WNITC[7:0];
      else 
        cpy_ld_opcode_int[7:0] =  AFU_TLX_CMD_ENCODE_RD_WNITC_N[7:0];
    end // -- always @ *
   
  // -- Form the command
  always @*
    begin
      if ( arb_eng_ld_gnt || arb_eng_rtry_ld_gnt )
        begin
          cpy_ld_valid           =   (( arb_eng_ld_gnt ) || ( arb_eng_rtry_ld_gnt ));
          cpy_ld_opcode[7:0]     =     cpy_ld_opcode_int[7:0];
          cpy_ld_actag[11:0]     =     eng_actag[11:0];
          cpy_ld_stream_id[3:0]  =     4'b0;
          if ( arb_eng_rtry_ld_gnt )
            begin
              cpy_ld_ea_or_obj[67:0] = { 4'b0, cpy_rtry_ld_ea[63:6], 6'b0 };
              cpy_ld_afutag[15:0]    = { cpy_rtry_xx_dl_q[1:0], 4'b0, 1'b1, cpy_rtry_xx_afutag_q[8:0] };  // Set bit 9 for retries for easier debug
              cpy_ld_dl[1:0]         =   cpy_rtry_xx_dl_q[1:0];
            end 
          else   //if ( arb_eng_ld_gnt )
            begin
              cpy_ld_ea_or_obj[67:0] = { 4'b0, cpy_ld_ea_q[63:6], 6'b0 };
              cpy_ld_afutag[15:0]    = { mmio_eng_ld_size_q[1:0], 5'b0, arb_eng_ld_tag[8:0] };
              cpy_ld_dl[1:0]         =   mmio_eng_ld_size_q[1:0];
            end
          cpy_ld_pl[2:0]         =     3'b000;
          cpy_ld_os              =     1'b0;
          cpy_ld_be[63:0]        =    64'b0;
          cpy_ld_flag[3:0]       =     4'b0;
          cpy_ld_endian          =     1'b0;
          cpy_ld_bdf[15:0]       =  { cfg_afu_bdf_bus[7:0], cfg_afu_bdf_device[4:0], cfg_afu_bdf_function[2:0] };
//             cpy_ld_pasid[19:0]     =  { 10'b0, cmd_pasid_q[9:0] };
          cpy_ld_pg_size[5:0]    =     6'b0;
        end
      else
        begin
          cpy_ld_valid           =    1'b0;
          cpy_ld_opcode[7:0]     =    8'b0;
          cpy_ld_actag[11:0]     =   12'b0;
          cpy_ld_stream_id[3:0]  =    4'b0;
          cpy_ld_ea_or_obj[67:0] =   68'b0;
          cpy_ld_afutag[15:0]    =   16'b0;
          cpy_ld_dl[1:0]         =    2'b0;
          cpy_ld_pl[2:0]         =    3'b0;
          cpy_ld_os              =    1'b0;
          cpy_ld_be[63:0]        =   64'b0;
          cpy_ld_flag[3:0]       =    4'b0;
          cpy_ld_endian          =    1'b0;
          cpy_ld_bdf[15:0]       =   16'b0;
//             cpy_ld_pasid[19:0]     =   20'b0;
          cpy_ld_pg_size[5:0]    =    6'b0;
        end

    end // -- always @ *


  // -- ********************************************************************************************************************************
  // -- Command Response Tracking
  // -- ********************************************************************************************************************************

  // -- Track the responses
  assign  cpy_ld_resp_length_en =  reset || ((rspi_cpy_ld_resp_val_q || rtry_abort_valid) && (mmio_eng_ld_size_q == 2'b11));

  assign  afutag_masked[8:1] = rspi_resp_afutag_q[8:1];
  assign  afutag_masked[0]   = rspi_resp_afutag_q[0] && (mmio_eng_ld_size_q != 2'b11);  // Zero out last bit if 256B (Even tag is main tag.  Odd is for retries.)

  mcp3_decoder9x512  decode_afutag
    (
      .din        ( afutag_masked[8:0] ),
      .dout       ( afutag_decoded[511:0] )
    );

  assign  afutag_decoded_valid[511:0]  =  rspi_cpy_ld_resp_val_q ?  afutag_decoded[511:0]
                                                                 :  512'b0;

  // -- When response is abort, need to treat as complete and free the tag
  assign  rtry_abort_valid  = start_cpy_rtry_ld_seq & rtry_decode_is_abort;

  assign  rtry_afutag_masked[8:1] = rtry_queue_afutag_q[8:1];
  assign  rtry_afutag_masked[0]   = rtry_queue_afutag_q[0] && (mmio_eng_ld_size_q != 2'b11);  // Zero out last bit if 256B (Even tag is main tag.  Odd is for retries.)

  mcp3_decoder9x512  rtry_decode_afutag
    (
      .din        ( rtry_afutag_masked[8:0] ),
      .dout       ( rtry_afutag_decoded[511:0] )
    );

  assign  rtry_afutag_decoded_abort[511:0]  =  rtry_abort_valid  ?  rtry_afutag_decoded[511:0]
                                                                 :  512'b0;

  genvar i;
  generate
    for (i = 0; i < 256; i = i+1)
      begin: cpy_ld_resp_length_gen
        always @*
          begin
            if ( reset )
              cpy_ld_resp_length_d[i] = 1'b0;
            else
              begin
                if (( afutag_decoded_valid[i*2] == 1'b1 ) && (rtry_afutag_decoded_abort[i*2]))  // Resp & Abort simultaneously
                  begin
                      cpy_ld_resp_length_d[i] = 1'b0;   // The only way both will be valid is if both are 128B responses, and original dl was 256B.  All 256B received response.
                  end
                else if ( afutag_decoded_valid[i*2] == 1'b1 )   // Resp only
                  begin
                    if (rspi_resp_dl_q[1:0] == 2'b11)
                      cpy_ld_resp_length_d[i] = 1'b0;   // 256B response
                    else
	              cpy_ld_resp_length_d[i] = ~cpy_ld_resp_length_q[i];  // 128B response.  0->1, 1->0 and sets tag
                  end
                else if ( rtry_afutag_decoded_abort[i*2] == 1'b1 )  // Abort only
                  begin
                    if (rtry_queue_dl_q[1:0] == 2'b11)
                      cpy_ld_resp_length_d[i] = 1'b0;   // 256B response fail
                    else
	              cpy_ld_resp_length_d[i] = ~cpy_ld_resp_length_q[i];  // 128B response fail.  0->1, 1->0 and sets tag
                  end
                else
                  cpy_ld_resp_length_d[i] = cpy_ld_resp_length_q[i];
              end
          end    
        // Note: if logic below changes, check that fastpath logic is still correct.
        assign eng_arb_set_ld_tag_avail[i*2]   = (afutag_decoded_valid[i*2] & ((~cpy_ld_resp_length_d[i]) | (mmio_eng_ld_size_q != 2'b11))) |  // Only 256B loads use resp_length
                                            (rtry_afutag_decoded_abort[i*2] & ((~cpy_ld_resp_length_d[i]) | (mmio_eng_ld_size_q != 2'b11))) ;  // When response is abort, need to treat as complete and free the tag
        assign eng_arb_set_ld_tag_avail[i*2+1] = afutag_decoded_valid[i*2+1] | rtry_afutag_decoded_abort[i*2+1];
      end
  endgenerate


  // -- ********************************************************************************************************************************
  // -- Command Response Fastpath
  // -- ********************************************************************************************************************************
  // Currently, there is a 4 cycle delay between eng_arb_set_ld_tag_avail and arb.stg1_ld_req_q when arb is out of tags
  // Fastpath will shave off 3 cycles.
  // Block fastpath if any tags have been returned in the past 2 cycles, to avoid handling corner cases.
  // Blocking if any resp or rtry abort occurred, even partial responses that did not result in a tag being returned, to simplify logic.
  // Not setting fastpath valid for rtry_abort responses, to simplify logic.
  assign resp_valid_dly1_d  =  rspi_cpy_ld_resp_val_q  |  rtry_abort_valid;
  assign resp_valid_dly2_d  =  resp_valid_dly1_q;

  assign curr_resp_length = cpy_ld_resp_length_q[ afutag_masked[8:1] ];  // 256:1 Mux

  assign fastpath_valid  = rspi_cpy_ld_resp_val_q &                    // Good response
                           ~resp_valid_dly1_q & ~resp_valid_dly2_q &   // Block for 2 cycles
                           ~rtry_abort_valid &                         // Block just in case rtry abort occurs same cycle as good resp
                           ((mmio_eng_ld_size_q != 2'b11) |            // 64B & 128B commands always have full response
                            (rspi_resp_dl_q[1:0] == 2'b11) |           // 256B response
                            (curr_resp_length == 1'b1));               // Partial response, and only need 128B response

  assign eng_arb_ld_fastpath_valid     =  fastpath_valid;
  assign eng_arb_ld_fastpath_tag[8:0]  =  afutag_masked[8:0];

  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      // -- Sequencers
      cpy_rtry_ld_seq_q[3:0]                       <= cpy_rtry_ld_seq_d[3:0];

      // -- Offset, size, length calculations 
      if ( cpy_ld_resp_length_en )
        cpy_ld_resp_length_q[255:0]                <= cpy_ld_resp_length_d[255:0];

      // -- Mode/Config Repower Latches
      mmio_eng_ld_size_q[1:0]                      <= mmio_eng_ld_size[1:0];

      // -- Command Response Fastpath
      resp_valid_dly1_q                            <= resp_valid_dly1_d;
      resp_valid_dly2_q                            <= resp_valid_dly2_d;

    end // -- always @ *

endmodule
