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

module afp3_eng_fsm_cpy_st
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config & Misc Inputs
  //    , input                 mmio_eng_256B_op_disable
  //    , input                 mmio_eng_128B_op_disable
  , input           [1:0] mmio_eng_st_size
  , input                 cpy_st_type_sel
  , input                 rtry_backoff_timer_disable_q

  //    , input                 immed_terminate_enable_q
  //    , input                 num_cmds_sent_eq_resp_rcvd
  //    , input                 eng_pe_terminate_q

  // -- Command Inputs
  //    , input                 we_ld_capture_cmd
  //    , input                 we_ld_seq_done
  //    , input          [11:0] we_cmd_length_d
  //    , input          [63:6] we_cmd_dest_ea_d
  //    , input          [63:6] we_cmd_dest_ea_q
  //    , input           [9:0] cmd_pasid_q

  , input           [8:0] cpy_rtry_xx_afutag_q
  , input           [1:0] cpy_rtry_xx_dl_q
  //    , input          [63:6] cpy_rtry_st_ea_q

  //    , input           [5:0] eng_num
  , input          [11:0] eng_actag
  , input           [7:0] cfg_afu_bdf_bus 
  , input           [4:0] cfg_afu_bdf_device
  , input           [2:0] cfg_afu_bdf_function

  // -- Main Sequencer Control Inputs & Arbitration Interface
  //    , input                 start_cpy_st_seq
  , input          [63:6] cpy_st_ea_q
  //    - unused on mcp3, input                 arb_st_gnt_q
  , input                 rspi_cpy_st_resp_val_q
  , input          [1:0]  rspi_resp_dl_q
  , input          [8:0]  rspi_resp_afutag_q

  //    , output                cpy_st_req    //eng_arb_st_req
  , input                 arb_eng_st_gnt
  , input           [8:0] arb_eng_st_tag
  , output        [511:0] eng_arb_set_st_tag_avail
  , output                eng_arb_st_fastpath_valid
  , output          [8:0] eng_arb_st_fastpath_tag

  // -- Main Sequencer Outputs
  //    , output                cpy_st_seq_done
  //    , output                cpy_st_seq_error

  //    , output          [3:0] cpy_st_state
  //    , output                cpy_st_idle_st
  //    , output                cpy_st_req_st
  //    , output                cpy_st_wt4gnt_st
  //    , output                cpy_st_wt4rsp_st

  // -- Rtry Sequencer Control Inputs & Arbitration Interface
  , input                 start_cpy_rtry_st_seq
  , input                 rtry_decode_is_immediate
  , input                 rtry_decode_is_backoff
  , input                 rtry_decode_is_abort
  , input           [8:0] rtry_queue_afutag_q     
  , input           [1:0] rtry_queue_dl_q
  , input                 cpy_rtry_st_backoff_done
  , input                 cpy_rtry_st_backoff_done_q

  , output                eng_arb_rtry_st_req
  , output                cpy_rtry_st_req
  , input                 arb_eng_rtry_st_gnt

  // -- Rtry Sequencer Outputs
  , output                cpy_rtry_st_seq_error

  , output          [4:0] cpy_rtry_st_state
  , output                cpy_rtry_st_idle_st
  , output                cpy_rtry_st_wt4bckoff_st
  , output                cpy_rtry_st_req_st
  , output                cpy_rtry_st_wt4gnt_st
  , output                cpy_rtry_st_abort_st

  // -- Command Bus
  , output reg            cpy_st_valid
  , output reg      [7:0] cpy_st_opcode
  , output reg     [11:0] cpy_st_actag
  , output reg      [3:0] cpy_st_stream_id 
  , output reg     [67:0] cpy_st_ea_or_obj
  , output reg     [15:0] cpy_st_afutag
  , output reg      [1:0] cpy_st_dl
  , output reg      [2:0] cpy_st_pl
  , output reg            cpy_st_os
  , output reg     [63:0] cpy_st_be
  , output reg      [3:0] cpy_st_flag
  , output reg            cpy_st_endian
  , output reg     [15:0] cpy_st_bdf
  //    , output reg     [19:0] cpy_st_pasid
  , output reg      [5:0] cpy_st_pg_size

  // -- Additional outputs needed by data buffer
  //    , output          [4:0] cpy_st_afutag_d
  //    , output          [4:0] cpy_st_afutag_q
  //    , output          [1:0] cpy_st_size_encoded_d
  , output                cpy_st_size_256_q

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- Retry Sequencer Signals
  wire     [11:0] cpy_rtry_st_seq_sel;
  reg       [5:0] cpy_rtry_st_seq;
  wire            cpy_rtry_st_seq_err_int;

  wire            cpy_rtry_st_idle_state;
  wire            cpy_rtry_st_wt4bckoff_state;
  wire            cpy_rtry_st_req_state;
  wire            cpy_rtry_st_wt4gnt_state;
  wire            cpy_rtry_st_abort_state;

  wire            cpy_rtry_st_req_int;

  // -- Retry Address Lookup
  wire            rtry_ea_wren;
  wire      [8:0] rtry_ea_wraddr;
  wire     [31:7] rtry_ea_wrdata;

  wire            rtry_ea_rden;
  wire      [8:0] rtry_ea_rdaddr;
  wire     [31:7] rtry_ea_rddata;

  wire            cpy_rtry_st_ea_bit7;
  wire     [63:6] cpy_rtry_st_ea;

  // -- Signals that have dependency on command type
  reg       [7:0] cpy_st_opcode_int;

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
  wire      [4:0] cpy_rtry_st_seq_d;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [4:0] cpy_rtry_st_seq_q;
         
  wire            cpy_st_resp_length_en;
  reg     [255:0] cpy_st_resp_length_d;
  reg     [255:0] cpy_st_resp_length_q;

  reg       [1:0] mmio_eng_st_size_q;

  wire            resp_valid_dly1_d;
  reg             resp_valid_dly1_q;

  wire            resp_valid_dly2_d;
  reg             resp_valid_dly2_q;

  // -- ********************************************************************************************************************************
  // -- Constant declarations 
  // -- ********************************************************************************************************************************

  // -- TLX AP command encodes
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W                 = 8'b00100000;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_N               = 8'b00100100;  // -- DMA Write


  // -- ********************************************************************************************************************************
  // -- Cpy_St State Machine 
  // -- ********************************************************************************************************************************

  // -- Assume 64B, 128B, & 256B store cmds are available

  // -- State Outputs (For External Usage)
  //assign  cpy_st_wt4rsp_st  =  1'b1;   // AFP - Moved signal to fsm_main


  // -- ********************************************************************************************************************************
  // -- cpy_rtry_st State Machine 
  // -- ********************************************************************************************************************************

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc05  cpy_rtry_st_seq_err (
    .one_hot_vector   ( cpy_rtry_st_seq_q[4:0] ),
    .one_hot_error    ( cpy_rtry_st_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage)
  assign  cpy_rtry_st_idle_state      =  cpy_rtry_st_seq_q[0];  // -- Wait for delayed read of retry queue to trigger the start of this sequencer 
  assign  cpy_rtry_st_wt4bckoff_state =  cpy_rtry_st_seq_q[1];  // -- Need to wait required backoff time
  assign  cpy_rtry_st_req_state       =  cpy_rtry_st_seq_q[2];  // -- Need an extra state here to allow calculation of new AFUTag and DL to figure out dbuf read addr
  assign  cpy_rtry_st_wt4gnt_state    =  cpy_rtry_st_seq_q[3];  // -- Wait for grant to present cmd on cycle after the grant 
  assign  cpy_rtry_st_abort_state     =  cpy_rtry_st_seq_q[4];  // -- Abort

  // -- Sequencer Inputs
  assign  cpy_rtry_st_seq_sel[11:0] = { start_cpy_rtry_st_seq, ( rtry_decode_is_immediate || rtry_backoff_timer_disable_q ), rtry_decode_is_backoff, rtry_decode_is_abort,
                                        cpy_rtry_st_backoff_done_q, cpy_rtry_st_backoff_done, arb_eng_rtry_st_gnt, cpy_rtry_st_seq_q[4:0] };
  // -- Sequencer Table
  always @*
    begin
      casez ( cpy_rtry_st_seq_sel[11:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------
        // --  start_cpy_rtry_st_seq
        // --  |rtry_decode_is_immediate
        // --  ||rtry_decode_is_backoff 
        // --  |||rtry_decode_is_abort        
        // --  ||||cpy_rtry_st_backoff_done_q              Outputs & Next State
        // --  |||||cpy_rtry_st_backoff_done               --------------------
        // --  ||||||arb_eng_rtry_st_gnt                   cpy_rtry_st_req
        // --  ||||||| cpy_rtry_st_seq_q[4:0]              | cpy_rtry_st_seq_d[4:0]
        // --  11||||| |                                   | |
        // --  1098765 43210                               5 43210
        // --------------------------------------------------------
           12'b0??????_00001 :  cpy_rtry_st_seq[5:0] =  6'b0_00001 ;  // --      Idle_ST ->      Idle_ST  - Wait for valid cpy rtry st
           12'b11?????_00001 :  cpy_rtry_st_seq[5:0] =  6'b1_00100 ;  // --      Idle_ST ->       Req_ST  - Start - No Backoff Required, move directly to req State
           12'b101?00?_00001 :  cpy_rtry_st_seq[5:0] =  6'b0_00010 ;  // --      Idle_ST -> wt4bckoff_ST  - Start - Backoff Required, In progress, move to wt4bckoff State
           12'b101?1??_00001 :  cpy_rtry_st_seq[5:0] =  6'b1_00100 ;  // --      Idle_ST ->       Req_ST  - Start - Backoff Required, already done, move directly to req State
           12'b101?01?_00001 :  cpy_rtry_st_seq[5:0] =  6'b1_00100 ;  // --      Idle_ST ->       Req_ST  - Start - Backoff Required, already done, move directly to req State
           12'b1001???_00001 :  cpy_rtry_st_seq[5:0] =  6'b0_10000 ;  // --      Idle_ST ->     Abort_ST  - Start - move to abort state and then back to idle
        // --------------------------------------------------------  
           12'b?????0?_00010 :  cpy_rtry_st_seq[5:0] =  6'b0_00010 ;  // -- wt4bckoff_ST -> wt4bckoff_ST   - Wait for Backoff Timer to count down
           12'b?????1?_00010 :  cpy_rtry_st_seq[5:0] =  6'b1_00100 ;  // -- wt4bckoff_ST ->       Reg_ST   - Timer expired, drive request to arb, advance through req st then wait for grant
        // --------------------------------------------------------  
           12'b???????_00100 :  cpy_rtry_st_seq[5:0] =  6'b0_01000 ;  // --       Reg_ST ->    Wt4Gnt_ST  - Assert read to dbuf this cycle
        // --------------------------------------------------------  
           12'b??????0_01000 :  cpy_rtry_st_seq[5:0] =  6'b0_01000 ;  // --    Wt4Gnt_ST ->    Wt4Gnt_ST  - Wait for grant from ARB
           12'b??????1_01000 :  cpy_rtry_st_seq[5:0] =  6'b0_00001 ;  // --    Wt4Gnt_ST ->      Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle Immediately
        // --------------------------------------------------------  
           12'b???????_10000 :  cpy_rtry_st_seq[5:0] =  6'b0_00001 ;  // --     Abort_ST ->      Idle_ST  - Abort and return to idle
        // --------------------------------------------------------
            default          :  cpy_rtry_st_seq[5:0] =  6'b0_00001 ;  // --     Default  ->      Idle_ST  - (Needed to make case "full" to prevent inferred latches)
        // --------------------------------------------------------                                    
      endcase
    end // -- always @ *

  // -- Outputs
  assign  eng_arb_rtry_st_req  =  cpy_rtry_st_seq[5];
  assign  cpy_rtry_st_req      =  cpy_rtry_st_seq[5];
  assign  cpy_rtry_st_req_int  =  cpy_rtry_st_seq[5];

  // -- State Outputs (For External Usage)
  assign  cpy_rtry_st_state[4:0]   =  cpy_rtry_st_seq_q[4:0];
  assign  cpy_rtry_st_idle_st      =  cpy_rtry_st_idle_state;
  assign  cpy_rtry_st_wt4bckoff_st =  cpy_rtry_st_wt4bckoff_state;
  assign  cpy_rtry_st_req_st       =  cpy_rtry_st_req_state;
  assign  cpy_rtry_st_wt4gnt_st    =  cpy_rtry_st_wt4gnt_state;
  assign  cpy_rtry_st_abort_st     =  cpy_rtry_st_abort_state;

  // -- Error
  assign  cpy_rtry_st_seq_error    =  cpy_rtry_st_seq_err_int;

  // -- Next State
  assign  cpy_rtry_st_seq_d[4:0] = ( reset || cpy_rtry_st_seq_err_int ) ? 5'b1 : cpy_rtry_st_seq[4:0];


  // -- ********************************************************************************************************************************
  // -- Calculate next store size and corresponding next EA and AFUTAG
  // -- ********************************************************************************************************************************

  // -- NOTE: Dest EA, Size, and AFUTag need to be held until grant so that they can be presented to cmdo 1 cycle after grant
  // --       Length and EA offset are updated earlier so that size calculation can be done in advance


  // -- ********************************************************************************************************************************
  // -- Retry Address Lookup
  // -- ********************************************************************************************************************************
  assign  rtry_ea_wren         =  arb_eng_st_gnt;
  assign  rtry_ea_wraddr[8:0]  =  arb_eng_st_tag[8:0];
  assign  rtry_ea_wrdata[31:7] =  cpy_st_ea_q[31:7];

  assign  rtry_ea_rden         =  cpy_rtry_st_req_int;

  //  cpy_rtry_xx_afutag_q contains the retry afutag that needs to be sent, so that we don't need to keep around DP from the response.
  //  (This is handled in afp3_eng_rtry_queue.v)
  //  If the original command was 256B, the original tag is even.
  //  We could receive two 128B responses.  If DP was for the 2nd half, cpy_rtry_xx_afutag_q will be odd.
  //  For 256B ops, the original EA is only stored in the even entries of the array.  Odd entries are unused for 256B.
  //  For 256B ops, zero-out rdaddr[0], so that we read the original EA
  assign  rtry_ea_rdaddr[8:0]  =  {cpy_rtry_xx_afutag_q[8:1], (cpy_rtry_xx_afutag_q[0] & ~(mmio_eng_st_size_q[1:0] == 2'b11)) };

  
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
  assign  cpy_rtry_st_ea_bit7   = rtry_ea_rddata[7] || ((mmio_eng_st_size_q[1:0] == 2'b11) && cpy_rtry_xx_afutag_q[0]);
  assign  cpy_rtry_st_ea[63:6]  = { cpy_st_ea_q[63:32],  rtry_ea_rddata[31:8], cpy_rtry_st_ea_bit7, 1'b0 };

  // -- ********************************************************************************************************************************
  // -- Command Bus Out
  // -- ********************************************************************************************************************************

  // -- Support for Command Type
  always @*
    begin
      if ( cpy_st_type_sel == 1'b0 )
        cpy_st_opcode_int[7:0] =  AFU_TLX_CMD_ENCODE_DMA_W[7:0];
      else
        cpy_st_opcode_int[7:0] =  AFU_TLX_CMD_ENCODE_DMA_W_N[7:0];
    end // -- always @ *                                  

   
  // -- Form the command
  always @*
    begin
      if ( arb_eng_st_gnt || arb_eng_rtry_st_gnt )
        begin
          cpy_st_valid           =   (( arb_eng_st_gnt ) || ( arb_eng_rtry_st_gnt ));
          cpy_st_opcode[7:0]     =     cpy_st_opcode_int[7:0];
          cpy_st_actag[11:0]     =     eng_actag[11:0];
          cpy_st_stream_id[3:0]  =     4'b0;
          if ( arb_eng_rtry_st_gnt )
            begin
              cpy_st_ea_or_obj[67:0] = { 4'b0, cpy_rtry_st_ea[63:6], 6'b0 };
              cpy_st_afutag[15:0]    = { cpy_rtry_xx_dl_q[1:0], 4'b1000, 1'b1, cpy_rtry_xx_afutag_q[8:0] };   // Bit 13 = 1 for store(cmd1), Bit 9 = 1 for retry (for easier debug)
              cpy_st_dl[1:0]         =   cpy_rtry_xx_dl_q[1:0];
            end 
          else   //if ( arb_eng_st_gnt )
            begin
              cpy_st_ea_or_obj[67:0] = { 4'b0, cpy_st_ea_q[63:6], 6'b0 };
              cpy_st_afutag[15:0]    = { mmio_eng_st_size_q[1:0], 5'b10000, arb_eng_st_tag[8:0] };
              cpy_st_dl[1:0]         =   mmio_eng_st_size_q[1:0];
            end
          cpy_st_pl[2:0]         =     3'b000;
          cpy_st_os              =     1'b0;
          cpy_st_be[63:0]        =    64'b0;
          cpy_st_flag[3:0]       =     4'b0;
          cpy_st_endian          =     1'b0;
          cpy_st_bdf[15:0]       =  { cfg_afu_bdf_bus[7:0], cfg_afu_bdf_device[4:0], cfg_afu_bdf_function[2:0] };
//             cpy_st_pasid[19:0]     =  { 10'b0, cmd_pasid_q[9:0] };
          cpy_st_pg_size[5:0]    =     6'b0;
        end
      else
        begin
          cpy_st_valid           =    1'b0;
          cpy_st_opcode[7:0]     =    8'b0;
          cpy_st_actag[11:0]     =   12'b0;
          cpy_st_stream_id[3:0]  =    4'b0;
          cpy_st_ea_or_obj[67:0] =   68'b0;
          cpy_st_afutag[15:0]    =   16'b0;
          cpy_st_dl[1:0]         =    2'b0;
          cpy_st_pl[2:0]         =    3'b0;
          cpy_st_os              =    1'b0;
          cpy_st_be[63:0]        =   64'b0;
          cpy_st_flag[3:0]       =    4'b0;
          cpy_st_endian          =    1'b0;
          cpy_st_bdf[15:0]       =   16'b0;
//             cpy_st_pasid[19:0]     =   20'b0;
          cpy_st_pg_size[5:0]    =    6'b0;
        end

    end // -- always @ *


  // -- Drive outbound to cmd_out for indicating size of data to the arbiter
  assign  cpy_st_size_256_q    =  (mmio_eng_st_size_q == 2'b11);


  // -- ********************************************************************************************************************************
  // -- Command Response Tracking
  // -- ********************************************************************************************************************************

  // -- Track the responses
  assign  cpy_st_resp_length_en =  reset || ((rspi_cpy_st_resp_val_q || rtry_abort_valid) && (mmio_eng_st_size_q == 2'b11));

  assign  afutag_masked[8:1] = rspi_resp_afutag_q[8:1];
  assign  afutag_masked[0]   = rspi_resp_afutag_q[0] && (mmio_eng_st_size_q != 2'b11);  // Zero out last bit if 256B (Even tag is main tag.  Odd is for retries.)

  mcp3_decoder9x512  decode_afutag
    (
      .din        ( afutag_masked[8:0] ),
      .dout       ( afutag_decoded[511:0] )
    );

  assign  afutag_decoded_valid[511:0]  =  rspi_cpy_st_resp_val_q ?  afutag_decoded[511:0]
                                                                 :  512'b0;

  // -- When response is abort, need to treat as complete and free the tag
  assign  rtry_abort_valid  = start_cpy_rtry_st_seq & rtry_decode_is_abort;

  assign  rtry_afutag_masked[8:1] = rtry_queue_afutag_q[8:1];
  assign  rtry_afutag_masked[0]   = rtry_queue_afutag_q[0] && (mmio_eng_st_size_q != 2'b11);  // Zero out last bit if 256B (Even tag is main tag.  Odd is for retries.)

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
      begin: cpy_st_resp_length_gen
        always @*
          begin
            if ( reset )
              cpy_st_resp_length_d[i] = 1'b0;
            else
              begin
                if (( afutag_decoded_valid[i*2] == 1'b1 ) && (rtry_afutag_decoded_abort[i*2]))  // Resp & Abort simultaneously
                  begin
                      cpy_st_resp_length_d[i] = 1'b0;   // The only way both will be valid is if both are 128B responses, and original dl was 256B.  All 256B received response.
                  end
                else if ( afutag_decoded_valid[i*2] == 1'b1 )
                  begin
                    if (rspi_resp_dl_q[1:0] == 2'b11)
                      cpy_st_resp_length_d[i] = 1'b0;   // 256B response
                    else
	              cpy_st_resp_length_d[i] = ~cpy_st_resp_length_q[i];  // 128B response.  0->1, 1->0 and sets tag
                  end
                else if ( rtry_afutag_decoded_abort[i*2] == 1'b1 )  // Abort only
                  begin
                    if (rtry_queue_dl_q[1:0] == 2'b11)
                      cpy_st_resp_length_d[i] = 1'b0;   // 256B response fail
                    else
	              cpy_st_resp_length_d[i] = ~cpy_st_resp_length_q[i];  // 128B response fail.  0->1, 1->0 and sets tag
                  end
                else
                  cpy_st_resp_length_d[i] = cpy_st_resp_length_q[i];
              end
          end
        // Note: if logic below changes, check that fastpath logic is still correct.
        assign eng_arb_set_st_tag_avail[i*2]   = (afutag_decoded_valid[i*2] & ((~cpy_st_resp_length_d[i]) | (mmio_eng_st_size_q != 2'b11))) |  // Only 256B stores use resp_length
                                            (rtry_afutag_decoded_abort[i*2] & ((~cpy_st_resp_length_d[i]) | (mmio_eng_st_size_q != 2'b11)));  // When response is abort, need to treat as complete and free the tag
        assign eng_arb_set_st_tag_avail[i*2+1] = afutag_decoded_valid[i*2+1] | rtry_afutag_decoded_abort[i*2+1];
      end
  endgenerate


  // -- ********************************************************************************************************************************
  // -- Command Response Fastpath
  // -- ********************************************************************************************************************************
  // Currently, there is a 4 cycle delay between eng_arb_set_st_tag_avail and arb.stg1_st_req_q when arb is out of tags
  // Fastpath will shave off 3 cycles.
  // Block fastpath if any tags have been returned in the past 2 cycles, to avoid handling corner cases.
  // Blocking if any resp or rtry abort occurred, even partial responses that did not result in a tag being returned, to simplify logic.
  // Not setting fastpath valid for rtry_abort responses, to simplify logic.
  assign resp_valid_dly1_d  =  rspi_cpy_st_resp_val_q  |  rtry_abort_valid;
  assign resp_valid_dly2_d  =  resp_valid_dly1_q;

  assign curr_resp_length = cpy_st_resp_length_q[ afutag_masked[8:1] ];  // 256:1 Mux

  assign fastpath_valid  = rspi_cpy_st_resp_val_q &                    // Good response
                           ~resp_valid_dly1_q & ~resp_valid_dly2_q &   // Block for 2 cycles
                           ~rtry_abort_valid &                         // Block just in case rtry abort occurs same cycle as good resp
                           ((mmio_eng_st_size_q != 2'b11) |            // 64B & 128B commands always have full response
                            (rspi_resp_dl_q[1:0] == 2'b11) |           // 256B response
                            (curr_resp_length == 1'b1));               // Partial response, and only need 128B response

  assign eng_arb_st_fastpath_valid     =  fastpath_valid;
  assign eng_arb_st_fastpath_tag[8:0]  =  afutag_masked[8:0];

  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      // -- Sequencers
      cpy_rtry_st_seq_q[4:0]                       <= cpy_rtry_st_seq_d[4:0];

      // -- Offset, size, length calculations 
      if ( cpy_st_resp_length_en )
        cpy_st_resp_length_q[255:0]                <= cpy_st_resp_length_d[255:0];

      // -- Mode/Config Repower Latches
      mmio_eng_st_size_q[1:0]                      <= mmio_eng_st_size[1:0];

      // -- Command Response Fastpath
      resp_valid_dly1_q                            <= resp_valid_dly1_d;
      resp_valid_dly2_q                            <= resp_valid_dly2_d;

    end // -- always @ *

endmodule
