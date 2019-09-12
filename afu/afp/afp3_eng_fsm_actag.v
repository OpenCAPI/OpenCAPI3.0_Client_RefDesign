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

module afp3_eng_fsm_actag
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config & Misc Inputs
  , input                 mmio_eng_use_pasid_for_actag
  , input          [11:0] cfg_afu_actag_base

  , output         [11:0] eng_actag

//   -unused  , input                 immed_terminate_enable_q
//   -unused  , input                 eng_pe_terminate_q

  // -- Command Inputs
//    -unused  , input          [63:5] cmd_we_ea_q
  , input           [9:0] cmd_pasid_q
//    -unused  , input          [15:0] we_cmd_length_q
//    -unused  , input           [0:0] we_cmd_extra_q

  , input           [5:0] eng_num
  , input           [7:0] cfg_afu_bdf_bus 
  , input           [4:0] cfg_afu_bdf_device
  , input           [2:0] cfg_afu_bdf_function

  // -- Main Sequencer Control Inputs & Arbitration Interface
  , input                 start_actag_seq

  , output                actag_req
  , input                 arb_eng_misc_gnt

  // -- Main Sequencer Outputs
  , output                actag_seq_done
  , output                actag_seq_error

  , output          [1:0] actag_state
  , output                actag_idle_st
  , output                actag_wt4gnt_st

  , output reg            actag_valid
  , output reg      [7:0] actag_opcode
  , output reg     [11:0] actag_actag
  , output reg      [3:0] actag_stream_id 
  , output reg     [67:0] actag_ea_or_obj
  , output reg     [15:0] actag_afutag
  , output reg      [1:0] actag_dl
  , output reg      [2:0] actag_pl
  , output reg            actag_os
  , output reg     [63:0] actag_be
  , output reg      [3:0] actag_flag
  , output reg            actag_endian
  , output reg     [15:0] actag_bdf
//     , output reg     [19:0] actag_pasid
  , output reg      [5:0] actag_pg_size

  );


  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- Misc
  reg      [11:0] eng_actag_int;

  // -- Main Sequencer Signals
  wire      [3:0] actag_seq_sel;
  reg       [3:0] actag_seq;
  wire            actag_seq_err_int;

  wire            actag_idle_state;
  wire            actag_wt4gnt_state;


  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  // -- Mode/Config
  wire     [11:0] cfg_afu_actag_base_d;
  reg      [11:0] cfg_afu_actag_base_q;

  // -- Sequencer latches
  wire      [1:0] actag_seq_d;
  reg       [1:0] actag_seq_q;


  // -- ********************************************************************************************************************************
  // -- Constant declarations 
  // -- ********************************************************************************************************************************

  // -- AFUTAG Encode
  localparam    [4:0] ACTAG_AFUTAG_ENCODE                      = 5'b00000;     // -- AFUTAG[4:0] for actag cmd                   ( AFUTAG[11] = b'1 )

  // -- TLX AP command encodes
  localparam    [7:0] AFU_TLX_CMD_ENCODE_ASSIGN_ACTAG          = 8'b01010000;  // -- Assign acTag


  // -- ********************************************************************************************************************************
  // -- Calculate ACTAG - Base from Config + internal offset 
  // -- ********************************************************************************************************************************

  // -- Latch actag base
  assign  cfg_afu_actag_base_d[11:0] =  cfg_afu_actag_base[11:0];

  // -- Calculate the actag using info from CNFG
  always @*
    begin
      if ( mmio_eng_use_pasid_for_actag )
        eng_actag_int[11:0] =  cfg_afu_actag_base_q[11:0] + { 2'b0, cmd_pasid_q[9:0] };
      else
        eng_actag_int[11:0] =  cfg_afu_actag_base_q[11:0] + { 6'b0, eng_num[5:0] } ;
    end // -- always @ *

   // -- Output for use by all other state machines
   assign  eng_actag[11:0]  = eng_actag_int[11:0];


  // -- ********************************************************************************************************************************
  // -- actag State Machine 
  // -- ********************************************************************************************************************************

  // -- Determine if the Current State of the Sequencer is invalid
  assign  actag_seq_err_int =  (( actag_seq_q[1:0] == 2'b00 ) || ( actag_seq_q[1:0] == 2'b11 ));

  // -- Current State Assignments (For Internal Usage)
  assign  actag_idle_state   =  actag_seq_q[0];  // -- State 0 - actag_idle_st     - Issue assign ACTag cmd request when leaving idle
  assign  actag_wt4gnt_state =  actag_seq_q[1];  // -- State 1 - actag_wt4gnt_st   - Wait for grant (latched) to present cmd on cycle after the grant 

  // -- Sequencer Inputs
  assign  actag_seq_sel[3:0] = { start_actag_seq, arb_eng_misc_gnt, actag_seq_q[1:0] };

  always @*
    begin

      casez ( actag_seq_sel[3:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State        Outputs & Next State
        // --  ----------------------        --------------------
        // --  start_actag_seq               actag_req
        // --  |arb_eng_misc_gnt             |actag_seq_done
        // --  || actag_seq_q                || actag_seq_d
        // --  || |                          || |
        // --  32 10                         32 10
        // -----------------------------------------
            4'b0?_01 :  actag_seq[3:0] =  4'b00_01 ;  // --     Idle_ST -> Idle_ST   - Wait for Main Sequencer to start this sequencer
            4'b1?_01 :  actag_seq[3:0] =  4'b10_10 ;  // --     Idle_ST -> Wt4Gnt_ST - Issue request to send assign actag cmd
        // -----------------------------------------
            4'b?0_10 :  actag_seq[3:0] =  4'b00_10 ;  // --   Wt4Gnt_ST -> Wt4Gnt_ST - Wait for grant (latched) to send assign actag cmd
            4'b?1_10 :  actag_seq[3:0] =  4'b01_01 ;  // --   Wt4Gnt_ST -> Idle_ST   - Return to Idle
        // -----------------------------------------
            default  :  actag_seq[3:0] =  4'b00_01 ;  // --     default -> Idle_ST   - (Needed to make case "full" to prevent inferred latches)
        // -----------------------------------------
      endcase
    end // -- always @ *

  // -- Outputs
  assign  actag_req        =  actag_seq[3];
  assign  actag_seq_done   =  actag_seq[2];

  // -- State Outputs (For External Usage)
  assign  actag_state[1:0] =  actag_seq_q[1:0];
  assign  actag_idle_st    =  actag_idle_state;
  assign  actag_wt4gnt_st  =  actag_wt4gnt_state;

  // -- Error
  assign  actag_seq_error =  actag_seq_err_int;

  // -- Next State
  assign  actag_seq_d[1:0] = ( reset || actag_seq_err_int ) ? 2'b1 : actag_seq[1:0];


  // -- ********************************************************************************************************************************
  // -- Command Bus Out
  // -- ********************************************************************************************************************************

  // -- Form AC Tag command
  always @*
    begin
      if ( actag_wt4gnt_state )
        begin
          actag_valid           =     arb_eng_misc_gnt;
          actag_opcode[7:0]     =     AFU_TLX_CMD_ENCODE_ASSIGN_ACTAG[7:0];
          actag_actag[11:0]     =     eng_actag_int[11:0];
          actag_stream_id[3:0]  =     4'b0;
          actag_ea_or_obj[67:0] =    68'b0;
          actag_afutag[15:0]    =  {  2'b00, 3'b001, eng_num[5:0], ACTAG_AFUTAG_ENCODE[4:0] };
          actag_dl[1:0]         =     2'b00;
          actag_pl[2:0]         =     3'b000;
          actag_os              =     1'b0;
          actag_be[63:0]        =    64'b0;
          actag_flag[3:0]       =     4'b0;
          actag_endian          =     1'b0;
          actag_bdf[15:0]       =  { cfg_afu_bdf_bus[7:0], cfg_afu_bdf_device[4:0], cfg_afu_bdf_function[2:0] };
          //    actag_pasid[19:0]     =  { 10'b0, cmd_pasid_q[9:0] };
          actag_pg_size[5:0]    =     6'b0;
        end
      else
        begin
          actag_valid           =    1'b0;
          actag_opcode[7:0]     =    8'b0;
          actag_actag[11:0]     =   12'b0;
          actag_stream_id[3:0]  =    4'b0;
          actag_ea_or_obj[67:0] =   68'b0;
          actag_afutag[15:0]    =   16'b0;
          actag_dl[1:0]         =    2'b0;
          actag_pl[2:0]         =    3'b0;
          actag_os              =    1'b0;
          actag_be[63:0]        =   64'b0;
          actag_flag[3:0]       =    4'b0;
          actag_endian          =    1'b0;
          actag_bdf[15:0]       =   16'b0;
          //    actag_pasid[19:0]     =   20'b0;
          actag_pg_size[5:0]    =    6'b0;
        end

    end // -- always @ *


  // -- ********************************************************************************************************************************
  // -- Latch Assignments
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      cfg_afu_actag_base_q[11:0]                  <= cfg_afu_actag_base_d[11:0];

      actag_seq_q[1:0]                            <= actag_seq_d[1:0];        

    end // -- always @ *

endmodule
