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

module afp3_eng_fsm_intrpt 
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config & Misc Inputs
  , input                 rtry_backoff_timer_disable_q
  , input                 main_seq_done

  // -- Command Inputs
//     , input           [9:0] cmd_pasid_q
  , input           [1:0] cmd_intrpt_type_q
//     , input          [63:0] cmd_intrpt_obj_q
  , input          [31:0] cmd_intrpt_data_q
//     , input          [63:0] we_cmd_source_ea_q
  , input          [31:0] we_cmd_dest_ea_q
  , input                 we_cmd_is_intrpt_q
  , input                 we_cmd_is_wkhstthrd_q
  , input           [4:4] we_cmd_extra_q
  , input          [63:0] mmio_eng_obj_handle

  , input           [5:0] eng_num
  , input          [11:0] eng_actag
  , input           [7:0] cfg_afu_bdf_bus 
  , input           [4:0] cfg_afu_bdf_device
  , input           [2:0] cfg_afu_bdf_function

//   -unused  , input                 immed_terminate_enable_q
//   -unused  , input                 num_cmds_sent_eq_resp_rcvd
//   -unused  , input                 eng_pe_terminate_q

  // -- Main Sequencer Control Inputs & Arbitration Interface
  , input                 start_intrpt_seq
  , input                 rspi_intrpt_resp_val_q

  , output                intrpt_req
  , output reg            intrpt_req_w_data
  , input                 arb_eng_misc_gnt

  // -- Main Sequencer Outputs
  , output                intrpt_seq_done
  , output                intrpt_seq_error

  , output          [2:0] intrpt_state
  , output                intrpt_idle_st
  , output                intrpt_wt4gnt_st
  , output                intrpt_wt4rsp_st

  // -- Rtry Sequencer Control Inputs & Arbitration Interface
  , input                 start_intrpt_rtry_seq
  , input                 rtry_decode_is_immediate
  , input                 rtry_decode_is_backoff
  , input                 rtry_decode_is_abort
  , input                 intrpt_rtry_backoff_done
  , input                 intrpt_rtry_backoff_done_q

  , output                intrpt_rtry_req
  , output reg            intrpt_rtry_req_w_data
  , input                 arb_eng_rtry_misc_gnt
  , input                 arb_rtry_misc_gnt_q

  // -- Rtry Sequencer Outputs
  , output                intrpt_rtry_seq_error

  , output          [3:0] intrpt_rtry_state
  , output                intrpt_rtry_idle_st
  , output                intrpt_rtry_wt4bckoff_st
  , output                intrpt_rtry_wt4gnt_st
  , output                intrpt_rtry_abort_st

  // -- Command Bus
  , output reg            intrpt_valid
  , output reg      [7:0] intrpt_opcode
  , output reg     [11:0] intrpt_actag
  , output reg      [3:0] intrpt_stream_id 
  , output reg     [67:0] intrpt_ea_or_obj
  , output reg     [15:0] intrpt_afutag
  , output reg      [1:0] intrpt_dl
  , output reg      [2:0] intrpt_pl
  , output reg            intrpt_os
  , output reg     [63:0] intrpt_be
  , output reg      [3:0] intrpt_flag
  , output reg            intrpt_endian
  , output reg     [15:0] intrpt_bdf
//     , output reg     [19:0] intrpt_pasid
  , output reg      [5:0] intrpt_pg_size

  // -- Data Bus
  , output                intrpt_data_valid
  , output        [511:0] intrpt_data

  // -- Miscellaneous
  , output reg            intrpt_sent_q

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- Main Sequencer Signals
  wire      [5:0] intrpt_seq_sel;
  reg       [4:0] intrpt_seq;
  wire            intrpt_seq_err_int;
  wire            intrpt_req_int;

  wire            intrpt_idle_state;
  wire            intrpt_wt4gnt_state;
  wire            intrpt_wt4rsp_state;

  // -- Rtry Sequencer Signals
  wire     [10:0] intrpt_rtry_seq_sel;
  reg       [4:0] intrpt_rtry_seq;
  wire            intrpt_rtry_seq_err_int;
  wire            intrpt_rtry_req_int;

  wire            intrpt_rtry_idle_state;
  wire            intrpt_rtry_wt4bckoff_state;
  wire            intrpt_rtry_wt4gnt_state;
  wire            intrpt_rtry_abort_state;

  wire            intrpt_cmd_data_valid;
  wire            intrpt_err_data_valid;


  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  // -- Sequencer latches
  wire      [2:0] intrpt_seq_d;
  reg       [2:0] intrpt_seq_q;

  wire      [3:0] intrpt_rtry_seq_d;
  reg       [3:0] intrpt_rtry_seq_q;

  wire            intrpt_data_valid_d;
  reg             intrpt_data_valid_q;

  wire            intrpt_data_en;
  reg      [31:0] intrpt_data_d;
  reg      [31:0] intrpt_data_q;

  wire            intrpt_sent_en;
  wire            intrpt_sent_d;


  // -- ********************************************************************************************************************************
  // -- Constant declarations 
  // -- ********************************************************************************************************************************

  // -- AFUTAG Encode
  localparam    [4:0] INTRPT_WHT_AFUTAG_ENCODE                 = 5'b00111;     // -- AFUTAG[4:0] for intrpt due to wkhstthrd cmd ( AFUTAG[11] = b'1, AFUTAG[12] = b'1 if "intrpt_w_data" )
  localparam    [4:0] INTRPT_ERR_AFUTAG_ENCODE                 = 5'b01101;     // -- AFUTAG[4:0] for intrpt due to error         ( AFUTAG[11] = b'1, AFUTAG[12] = b'1 if "intrpt_w_data" )
  localparam    [4:0] INTRPT_CMD_AFUTAG_ENCODE                 = 5'b01110;     // -- AFUTAG[4:0] for intrpt cmd                  ( AFUTAG[11] = b'1, AFUTAG[12] = b'1 if "intrpt_w_data" )

  // -- TLX AP command encodes
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ             = 8'b01011000;  // -- Interrupt Request
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ_S           = 8'b01011001;  // -- Interrupt Request
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ_D           = 8'b01011010;  // -- Interrupt Request
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ_D_S         = 8'b01011011;  // -- Interrupt Request


  // -- ********************************************************************************************************************************
  // -- intrpt State Machine (update status in main memory we) 
  // -- ********************************************************************************************************************************

  mcp3_ohc03  intrpt_seq_err (
    .one_hot_vector   ( intrpt_seq_q[2:0] ),
    .one_hot_error    ( intrpt_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage) 
  assign  intrpt_idle_state   =  intrpt_seq_q[0];  // -- State 0 - intrpt_idle_st   - Wait for Main sequencer to start this sequencer
  assign  intrpt_wt4gnt_state =  intrpt_seq_q[1];  // -- State 1 - intrpt_wt4gnt_st - Wait for grant to present cmd on cycle after the grant 
  assign  intrpt_wt4rsp_state =  intrpt_seq_q[2];  // -- State 2 - intrpt_wt4rsp_st - Enter this state after the we store has been sent (req+gnt), wait for response to come back

  // -- Sequencer Inputs
  assign  intrpt_seq_sel[5:0] = { start_intrpt_seq, arb_eng_misc_gnt, rspi_intrpt_resp_val_q, intrpt_seq_q[2:0] };

  // -- Sequencer Table
  always @*
    begin
      casez ( intrpt_seq_sel[5:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------           Outputs & Next State
        // --  start_intrpt_seq                 --------------------
        // --  |arb_eng_misc_gnt                intrpt_req
        // --  ||rspi_intrpt_resp_val_d         |intrpt_seq_done
        // --  ||| intrpt_seq_q                 || intrpt_seq_d
        // --  ||| |                            || |
        // --  543 210                          43 210
        // --------------------------------------------
            6'b0??_001 :  intrpt_seq[4:0] =  5'b00_001 ;  // --    Idle_ST ->   Idle_ST  - Wait for main sequencer to start this sequencer
            6'b1??_001 :  intrpt_seq[4:0] =  5'b10_010 ;  // --    Idle_ST -> Wt4Gnt_ST  - Start - move to Req State
        // --------------------------------------------
            6'b?0?_010 :  intrpt_seq[4:0] =  5'b00_010 ;  // --  Wt4Gnt_ST -> Wt4Gnt_ST  - Wait for grant from ARB
            6'b?1?_010 :  intrpt_seq[4:0] =  5'b00_100 ;  // --  Wt4Gnt_ST -> Wt4Rsp_ST  - Grant, drive cmd in nxt cycle, go wait for response
        // --------------------------------------------
            6'b??0_100 :  intrpt_seq[4:0] =  5'b00_100 ;  // --  Wt4Rsp_ST -> Wt4Rsp_ST  - Wait for response
            6'b??1_100 :  intrpt_seq[4:0] =  5'b01_001 ;  // --  Wt4Rsp_ST ->   Idle_ST  - Response received, go to idle, tell main seq done
        // --------------------------------------------
            default    :  intrpt_seq[4:0] =  5'b01_001 ;  // --    Idle_ST ->   Idle_ST  - (Needed to make case "full" to prevent inferred latches)
        // --------------------------------------------
      endcase
    end // -- always @ *                                  

  // -- Outputs (For Internal Usage) 
  assign  intrpt_req_int      =  intrpt_seq[4];
  assign  intrpt_seq_done_int =  intrpt_seq[3];

  // -- Outputs (For External Usage) 
  assign  intrpt_req      =  intrpt_req_int;
  assign  intrpt_seq_done =  intrpt_seq_done_int;

  // -- State Outputs (For External Usage)
  assign  intrpt_state[2:0] =  intrpt_seq_q[2:0];  
  assign  intrpt_idle_st    =  intrpt_idle_state;
  assign  intrpt_wt4gnt_st  =  intrpt_wt4gnt_state;
  assign  intrpt_wt4rsp_st  =  intrpt_wt4rsp_state;

  // -- Error
  assign  intrpt_seq_error =  intrpt_seq_err_int;

  // -- Next State
  assign  intrpt_seq_d[2:0] = ( reset || intrpt_seq_err_int ) ? 3'b1 :  intrpt_seq[2:0];

  // -- Determine which type of interrupt and if it has data, send with the arb request
  always @*
    begin
      if ( we_cmd_is_intrpt_q || we_cmd_is_wkhstthrd_q )
        intrpt_req_w_data =  intrpt_req_int && we_cmd_extra_q[4];
      else
        intrpt_req_w_data =  intrpt_req_int && cmd_intrpt_type_q[1];
    end // -- always @ *                                  


  // -- ********************************************************************************************************************************
  // -- intrpt_rtry State Machine 
  // -- ********************************************************************************************************************************

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc04  intrpt_rtry_seq_err (
    .one_hot_vector   ( intrpt_rtry_seq_q[3:0] ),
    .one_hot_error    ( intrpt_rtry_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage)
  assign  intrpt_rtry_idle_state      =  intrpt_rtry_seq_q[0];  // -- Wait for delayed read of retry queue to trigger the start of this sequencer
  assign  intrpt_rtry_wt4bckoff_state =  intrpt_rtry_seq_q[1];  // -- Wait for backoff timer to count down 
  assign  intrpt_rtry_wt4gnt_state    =  intrpt_rtry_seq_q[2];  // -- Wait for grant to present cmd on cycle after the grant 
  assign  intrpt_rtry_abort_state     =  intrpt_rtry_seq_q[3];  // -- Abort, then return to idle 

  // -- Sequencer Inputs
  assign  intrpt_rtry_seq_sel[10:0] = { start_intrpt_rtry_seq, ( rtry_decode_is_immediate || rtry_backoff_timer_disable_q ), rtry_decode_is_backoff, rtry_decode_is_abort,
                                        intrpt_rtry_backoff_done_q, intrpt_rtry_backoff_done, arb_eng_rtry_misc_gnt, intrpt_rtry_seq_q[3:0] };
  // -- Sequencer Table
  always @*
    begin
      casez ( intrpt_rtry_seq_sel[10:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        //
        // --  Inputs & Current State
        // --  ----------------------
        // --  start_intrpt_rtry_seq
        // --  |rtry_decode_is_immediate
        // --  ||rtry_decode_is_backoff  
        // --  |||rtry_decode_is_abort        
        // --  ||||intrpt_rtry_backoff_done_q             Outputs & Next State
        // --  |||||intrpt_rtry_backoff_done              --------------------
        // --  ||||||arb_eng_rtry_misc_gnt                intrpt_rtry_req
        // --  ||||||| intrpt_rtry_seq_q[3:0]             | intrpt_rtry_seq_d[3:0]
        // --  1|||||| |                                  | |
        // --  0987654 3210                               4 3210
        // -----------------------------------------------------
           11'b0??????_0001 :  intrpt_rtry_seq[4:0] =  5'b0_0001 ;  // --       Idle_ST ->      Idle_ST  - Wait for a valid intrpt rtry
           11'b11?????_0001 :  intrpt_rtry_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - No Backoff Required, move directly to wt4gnt_st State
           11'b101?00?_0001 :  intrpt_rtry_seq[4:0] =  5'b0_0010 ;  // --       Idle_ST -> Wt4Bckoff_ST  - Start - Backoff Required, In Progress, move to wt4bckoff_st State
           11'b101?1??_0001 :  intrpt_rtry_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - Backoff Required, Already Completed, move to wt4gnt_st State
           11'b101?01?_0001 :  intrpt_rtry_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - Backoff Required, Already Completed, move to wt4gnt_st State
           11'b1001???_0001 :  intrpt_rtry_seq[4:0] =  5'b0_1000 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - issue request to ARB, move to wt4gnt_st State
        // ------------------------------------------------------          
           11'b?????0?_0010 :  intrpt_rtry_seq[4:0] =  5'b0_0010 ;  // --  Wt4BckOff_ST -> Wt4BckOff_ST  - Wait for backoff timer to count down
           11'b?????1?_0010 :  intrpt_rtry_seq[4:0] =  5'b1_0100 ;  // --  Wt4BckOff_ST ->    Wt4Gnt_ST  - Timer expired, issue request to ARB, move to wt4gnt_st State
        // ------------------------------------------------------          
           11'b??????0_0100 :  intrpt_rtry_seq[4:0] =  5'b0_0100 ;  // --     Wt4Gnt_ST ->    Wt4Gnt_ST  - Wait for grant from ARB
           11'b??????1_0100 :  intrpt_rtry_seq[4:0] =  5'b0_0001 ;  // --     Wt4Gnt_ST ->      Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle
        // ------------------------------------------------------          
           11'b???????_1000 :  intrpt_rtry_seq[4:0] =  5'b0_0001 ;  // --      Abort_ST ->      Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle
        // ------------------------------------------------------          
            default         :  intrpt_rtry_seq[4:0] =  5'b0_0001 ;  // --      Default  ->      Idle_ST  - (Needed to make case "full" to prevent inferred latches)
        // ------------------------------------------------------
      endcase
    end // -- always @ *

  // -- Outputs (For Internal Usage)
  assign  intrpt_rtry_req_int      =  intrpt_rtry_seq[4];

  // -- Outputs (For External Usage)
  assign  intrpt_rtry_req          =  intrpt_rtry_req_int;

  // -- State Outputs (For External Usage)
  assign  intrpt_rtry_state[3:0]   =  intrpt_rtry_seq_q[3:0];  
  assign  intrpt_rtry_idle_st      =  intrpt_rtry_idle_state;
  assign  intrpt_rtry_wt4bckoff_st =  intrpt_rtry_wt4bckoff_state;
  assign  intrpt_rtry_wt4gnt_st    =  intrpt_rtry_wt4gnt_state;
  assign  intrpt_rtry_abort_st     =  intrpt_rtry_abort_state;

  // -- Error
  assign  intrpt_rtry_seq_error  =  intrpt_rtry_seq_err_int;

  // -- Next State
  assign  intrpt_rtry_seq_d[3:0] = ( reset || intrpt_rtry_seq_err_int ) ? 4'b1 : intrpt_rtry_seq[3:0];


  // -- Determine which type of interrupt and if it has data, send with the request
  always @*
    begin
      if ( we_cmd_is_intrpt_q || we_cmd_is_wkhstthrd_q )
        intrpt_rtry_req_w_data =  intrpt_rtry_req_int && we_cmd_extra_q[4];
      else
        intrpt_rtry_req_w_data =  intrpt_rtry_req_int && cmd_intrpt_type_q[1];
    end // -- always @ *


  // -- ********************************************************************************************************************************
  // -- Command Bus Out
  // -- ********************************************************************************************************************************

  // -- Form the command
  always @*
    begin

      if ( intrpt_wt4gnt_state || intrpt_rtry_wt4gnt_state )
        begin
          intrpt_valid           =  (( intrpt_wt4gnt_state && arb_eng_misc_gnt ) || ( intrpt_rtry_wt4gnt_state && arb_eng_rtry_misc_gnt ));
          if (( we_cmd_is_intrpt_q || we_cmd_is_wkhstthrd_q ) && ~we_cmd_extra_q[4] )
            intrpt_opcode[7:0]   =     AFU_TLX_CMD_ENCODE_INTRP_REQ[7:0];
          else if (( we_cmd_is_intrpt_q || we_cmd_is_wkhstthrd_q ) && we_cmd_extra_q[4] )
            intrpt_opcode[7:0]   =     AFU_TLX_CMD_ENCODE_INTRP_REQ_D[7:0];
          else
            begin
              case ( cmd_intrpt_type_q[1:0] )
                2'b00 :  intrpt_opcode[7:0] =  AFU_TLX_CMD_ENCODE_INTRP_REQ[7:0];
                2'b01 :  intrpt_opcode[7:0] =  AFU_TLX_CMD_ENCODE_INTRP_REQ_S[7:0];
                2'b10 :  intrpt_opcode[7:0] =  AFU_TLX_CMD_ENCODE_INTRP_REQ_D[7:0];
                2'b11 :  intrpt_opcode[7:0] =  AFU_TLX_CMD_ENCODE_INTRP_REQ_D_S[7:0];
              endcase
            end
          intrpt_actag[11:0]     =     eng_actag[11:0];
          intrpt_stream_id[3:0]  =     4'b0;
          if ( we_cmd_is_intrpt_q || we_cmd_is_wkhstthrd_q)
            //intrpt_ea_or_obj[67:0] =  {  4'b0, we_cmd_source_ea_q[63:0] };      // -- Interrupt as result of wkhstthrd or intrpt cmd
            intrpt_ea_or_obj[67:0] =  {  4'b0, mmio_eng_obj_handle[63:0] };       // -- Interrupt as result of wkhstthrd or intrpt cmd
          else
            //intrpt_ea_or_obj[67:0] =  {  4'b0, cmd_intrpt_obj_q[63:0] };        // -- Interrupt as result of error condition
            intrpt_ea_or_obj[67:0] =  {  4'b0, mmio_eng_obj_handle[63:0] };       // -- Interrupt as result of error condition

          if ( we_cmd_is_wkhstthrd_q )
            begin
              if ( we_cmd_extra_q[4] || cmd_intrpt_type_q[1] )
                begin
                  intrpt_afutag[15:0] =  {  2'b00, 3'b011, eng_num[5:0], INTRPT_WHT_AFUTAG_ENCODE[4:0] };  // -- Interrupt as result of wkhstthrd cmd,  w/ data
                  intrpt_pl[2:0]      =     3'b010;  // -- 4Byte
                end
              else
                begin
                  intrpt_afutag[15:0] =  {  2'b00, 3'b001, eng_num[5:0], INTRPT_WHT_AFUTAG_ENCODE[4:0] };  // -- Interrupt as result of wkhstthrd cmd, no data
                  intrpt_pl[2:0]      =     3'b000;
                end
            end
          else if ( we_cmd_is_intrpt_q )
            begin
              if ( we_cmd_extra_q[4] || cmd_intrpt_type_q[1] )
                begin
                  intrpt_afutag[15:0] =  {  2'b00, 3'b011, eng_num[5:0], INTRPT_CMD_AFUTAG_ENCODE[4:0] };  // -- Interrupt as result of intrpt cmd,  w/ data
                  intrpt_pl[2:0]      =     3'b010;  // -- 4Byte
                end
              else
                begin
                  intrpt_afutag[15:0] =  {  2'b00, 3'b001, eng_num[5:0], INTRPT_CMD_AFUTAG_ENCODE[4:0] };  // -- Interrupt as result of intrpt cmd, no data
                  intrpt_pl[2:0]      =     3'b000;
                end
            end
          else
            begin
              if ( we_cmd_extra_q[4] || cmd_intrpt_type_q[1] )
                begin
                  intrpt_afutag[15:0] =  {  2'b00, 3'b011, eng_num[5:0], INTRPT_ERR_AFUTAG_ENCODE[4:0] };  // -- Interrupt as result of error condition,  w/ data
                  intrpt_pl[2:0]      =     3'b010;  // -- 4Byte
                end
              else
                begin
                  intrpt_afutag[15:0] =  {  2'b00, 3'b001, eng_num[5:0], INTRPT_ERR_AFUTAG_ENCODE[4:0] };  // -- Interrupt as result of error condition,  no/ data
                  intrpt_pl[2:0]      =     3'b000;
                end
            end

          intrpt_dl[1:0]         =     2'b00;
          intrpt_os              =     1'b0;
          intrpt_be[63:0]        =    64'b0;
          intrpt_flag[3:0]       =     4'b0;
          intrpt_endian          =     1'b0;
          intrpt_bdf[15:0]       =  { cfg_afu_bdf_bus[7:0], cfg_afu_bdf_device[4:0], cfg_afu_bdf_function[2:0] };
//             intrpt_pasid[19:0]     =  { 10'b0, cmd_pasid_q[9:0] };
          intrpt_pg_size[5:0]    =     6'b0;
        end
      else
        begin
          intrpt_valid           =    1'b0;
          intrpt_opcode[7:0]     =    8'b0;
          intrpt_actag[11:0]     =   12'b0;
          intrpt_stream_id[3:0]  =    4'b0;
          intrpt_ea_or_obj[67:0] =   68'b0;
          intrpt_afutag[15:0]    =   16'b0;
          intrpt_dl[1:0]         =    2'b0;
          intrpt_pl[2:0]         =    3'b0;
          intrpt_os              =    1'b0;
          intrpt_be[63:0]        =   64'b0;
          intrpt_flag[3:0]       =    4'b0;
          intrpt_endian          =    1'b0;
          intrpt_bdf[15:0]       =   16'b0;
//             intrpt_pasid[19:0]     =   20'b0;
          intrpt_pg_size[5:0]    =    6'b0;
        end
    end // -- always @ *


  // -- ********************************************************************************************************************************
  // -- Data Bus Out
  // -- ********************************************************************************************************************************
  // Note:  Interrupt with data is unimplemented on AFP3.  Leaving code in case we implement later.
  assign  intrpt_cmd_data_valid = ((( intrpt_wt4gnt_state  && arb_eng_misc_gnt ) || ( intrpt_rtry_wt4gnt_state && arb_eng_rtry_misc_gnt )) &&
                                   (( we_cmd_is_intrpt_q || we_cmd_is_wkhstthrd_q ) && we_cmd_extra_q[4] )); 

  assign  intrpt_err_data_valid = ((( intrpt_wt4gnt_state  && arb_eng_misc_gnt ) || ( intrpt_rtry_wt4gnt_state && arb_eng_rtry_misc_gnt )) &&
                                   ( ~we_cmd_is_intrpt_q && ~we_cmd_is_wkhstthrd_q && cmd_intrpt_type_q[1] )); 

  assign  intrpt_data_valid_d   =  ( intrpt_cmd_data_valid || intrpt_err_data_valid );

  // -- Load Interrupt data to present for 1 cycle w/ cmd
  assign  intrpt_data_en =  ( reset || intrpt_cmd_data_valid || intrpt_err_data_valid || intrpt_data_valid_q );

  always @*
    begin
      if ( intrpt_cmd_data_valid )
        intrpt_data_d[31:0] =  we_cmd_dest_ea_q[31:0];
      else if ( intrpt_err_data_valid )
        intrpt_data_d[31:0] =  cmd_intrpt_data_q[31:0];
      else
        intrpt_data_d[31:0] =  32'b0;
     end // -- always @ *                                  

  assign  intrpt_data_valid  =  intrpt_data_valid_d;
  assign  intrpt_data[511:0] =  { 480'b0, intrpt_data_q[31:0] };


  // -- ********************************************************************************************************************************
  // -- Miscellaneous
  // -- ********************************************************************************************************************************

  // -- Keep track if interrupt was sent (make sure it doesn't get set on terminate immediate )
  assign  intrpt_sent_en =  ( intrpt_wt4rsp_state && rspi_intrpt_resp_val_q ) || main_seq_done || reset;
  assign  intrpt_sent_d  =  ( intrpt_wt4rsp_state && rspi_intrpt_resp_val_q );


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      intrpt_seq_q[2:0]                            <= intrpt_seq_d[2:0];        
      intrpt_rtry_seq_q[3:0]                       <= intrpt_rtry_seq_d[3:0];        

      intrpt_data_valid_q                          <= intrpt_data_valid_d;
      if ( intrpt_data_en )
        intrpt_data_q[31:0]                        <= intrpt_data_d[31:0];

      if (intrpt_sent_en )
        intrpt_sent_q                              <= intrpt_sent_d;

    end // -- always @ *

endmodule
