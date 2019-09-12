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

module afp3_eng_fsm_atomic 
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config & Misc Inputs
  , input                 memcpy2_format_enable_q
  , input           [1:0] atomic_ld_type_sel
  , input           [1:0] atomic_st_type_sel
  , input           [1:0] atomic_cas_type_sel
  , input                 rtry_backoff_timer_disable_q

  , input                 main_seq_done

//   -unused  , input                 immed_terminate_enable_q
//   -unused  , input                 num_cmds_sent_eq_resp_rcvd
//   -unused  , input                 eng_pe_terminate_q

  // -- Command Inputs
  , input          [63:0] we_cmd_atomic_op1_q
  , input          [63:0] we_cmd_atomic_op2_q
  , input          [63:0] we_cmd_dest_ea_q
//     , input           [9:0] cmd_pasid_q
  , input           [3:3] we_cmd_length_q
  , input           [7:0] we_cmd_extra_q

  , input           [5:0] eng_num
  , input          [11:0] eng_actag
  , input           [7:0] cfg_afu_bdf_bus 
  , input           [4:0] cfg_afu_bdf_device
  , input           [2:0] cfg_afu_bdf_function

  // -- Data Inputs
  , input         [511:0] rspi_resp_data_q

  // -- Main Sequencer Control Inputs & Arbitration Interface
  , input                 start_atomic_seq
  , input                 we_cmd_is_atomic_st_d
  , input                 we_cmd_is_atomic_cas_d
  , input                 we_cmd_is_atomic_ld_q
  , input                 we_cmd_is_atomic_st_q
  , input                 we_cmd_is_atomic_cas_q
  , input                 rspi_atomic_ld_resp_val_q
  , input                 rspi_atomic_st_resp_val_q
  , input                 rspi_atomic_cas_resp_val_d

  , output                atomic_req
  , output                atomic_req_w_data
  , input                 arb_eng_misc_gnt

  // -- Main Sequencer Outputs
  , output                atomic_seq_done
  , output                atomic_seq_error

  , output          [3:0] atomic_state
  , output                atomic_idle_st
  , output                atomic_wt4gnt_st
  , output                atomic_wt4rsp_st
  , output                atomic_compare_st

  // -- Rtry Sequencer Control Inputs & Arbitration Interface
  , input                 start_atomic_rtry_seq
  , input                 rtry_decode_is_immediate
  , input                 rtry_decode_is_backoff
  , input                 rtry_decode_is_abort
  , input                 atomic_rtry_backoff_done
  , input                 atomic_rtry_backoff_done_q

  , output                atomic_rtry_req
  , output                atomic_rtry_req_w_data
  , input                 arb_eng_rtry_misc_gnt

  // -- Rtry Sequencer Outputs
  , output                atomic_rtry_seq_error

  , output          [3:0] atomic_rtry_state
  , output                atomic_rtry_idle_st
  , output                atomic_rtry_wt4bckoff_st
  , output                atomic_rtry_wt4gnt_st
  , output                atomic_rtry_abort_st

  // -- Command Bus
  , output reg            atomic_valid
  , output reg      [7:0] atomic_opcode
  , output reg     [11:0] atomic_actag
  , output reg      [3:0] atomic_stream_id 
  , output reg     [67:0] atomic_ea_or_obj
  , output reg     [15:0] atomic_afutag
  , output reg      [1:0] atomic_dl
  , output reg      [2:0] atomic_pl
  , output reg            atomic_os
  , output reg     [63:0] atomic_be
  , output reg      [3:0] atomic_flag
  , output reg            atomic_endian
  , output reg     [15:0] atomic_bdf
//     , output reg     [19:0] atomic_pasid
  , output reg      [5:0] atomic_pg_size

  // -- Data Bus
  , output reg            atomic_data_valid
  , output reg    [511:0] atomic_data

  // -- CAS fail indication to we_st - prevents updating offset that gets written back to WEQ
  , output reg            atomic_cas_failure_q

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- Main Sequencer Signals
  wire      [9:0] atomic_seq_sel;
  reg       [5:0] atomic_seq;
  wire            atomic_seq_err_int;
  wire            atomic_seq_done_int;
  wire            atomic_req_int;

  wire            atomic_idle_state;
  wire            atomic_wt4gnt_state;
  wire            atomic_wt4rsp_state;

  // -- Rtry Sequencer Signals
  wire     [10:0] atomic_rtry_seq_sel;
  reg       [4:0] atomic_rtry_seq;
  wire            atomic_rtry_seq_err_int;
  wire            atomic_rtry_req_int;

  wire            atomic_rtry_idle_state;
  wire            atomic_rtry_wt4bckoff_state;
  wire            atomic_rtry_wt4gnt_state;
  wire            atomic_rtry_abort_state;

  // -- Translation of memcpy2 extra bits into opencapi flag
  reg       [3:0] atomic_flag_memcpy2;

  // -- Signals that have dependency on command randomizaton
  reg       [7:0] atomic_opcode_rand;

  // -- Signals used for performing compare on Compare/Swap operation
  wire            atomic_cas_compare_needed;
  reg      [63:0] atomic_cas_compare_op1;
  reg      [63:0] atomic_cas_compare_data;

  wire            set_atomic_cas_failure;

  // -- Atomic Store & Compare/Swap Data
  reg      [63:0] atomic_op1;
  reg      [63:0] atomic_op2;
  reg     [511:0] atomic_st_data;
  reg     [511:0] atomic_cas_data;


  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  // -- Sequencer latches
  wire      [3:0] atomic_seq_d;
  reg       [3:0] atomic_seq_q;

  wire      [3:0] atomic_rtry_seq_d;
  reg       [3:0] atomic_rtry_seq_q;

  reg             atomic_drive_data_d;
  reg             atomic_drive_data_q;

  wire            atomic_cas_failure_d;


  // -- ********************************************************************************************************************************
  // -- Constant declarations 
  // -- ********************************************************************************************************************************

  // -- AFUTAG Encode
  localparam    [4:0] ATOMIC_LD_AFUTAG_ENCODE                  = 5'b01010;     // -- AFUTAG[4:0] for atomic ld cmd               ( AFUTAG[11] = b'1 )
  localparam    [4:0] ATOMIC_ST_AFUTAG_ENCODE                  = 5'b01011;     // -- AFUTAG[4:0] for atomic st cmd               ( AFUTAG[11] = b'1 )
  localparam    [4:0] ATOMIC_CAS_AFUTAG_ENCODE                 = 5'b01100;     // -- AFUTAG[4:0] for atomic cas cmd              ( AFUTAG[11] = b'1 )

  // -- TLX AP command encodes
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD                = 8'b00111000;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RD_N              = 8'b00111100;  // -- Atomic Memory Operation - Read
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W                 = 8'b01001000;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_W_N               = 8'b01001100;  // -- Atomic Memory Operation - Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW                = 8'b01000000;  // -- Atomic Memory Operation - Read Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_AMO_RW_N              = 8'b01000100;  // -- Atomic Memory Operation - Read Write


  // -- ********************************************************************************************************************************
  // -- atomic State Machine 
  // -- ********************************************************************************************************************************

  mcp3_ohc04  atomic_seq_err (
    .one_hot_vector   ( atomic_seq_q[3:0] ),
    .one_hot_error    ( atomic_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage)
  assign  atomic_idle_state    =  atomic_seq_q[0];  // -- State 0 - atomic_idle_st    - Wait for Main sequencer to start this sequencer
  assign  atomic_wt4gnt_state  =  atomic_seq_q[1];  // -- State 1 - atomic_wt4gnt_st  - Wait for grant to present cmd on cycle after the grant 
  assign  atomic_wt4rsp_state  =  atomic_seq_q[2];  // -- State 2 - atomic_wt4rsp_st  - Enter this state after the atomic read has been sent (req+gnt), wait for response to come back
  assign  atomic_compare_state =  atomic_seq_q[3];  // -- State 3 - atomic_compare_st - Enter this state after the atomic read has been sent (req+gnt), wait for response to come back

  // -- Sequencer Inputs
  assign  atomic_seq_sel[9:0] = { start_atomic_seq, arb_eng_misc_gnt, rspi_atomic_ld_resp_val_q, rspi_atomic_st_resp_val_q, rspi_atomic_cas_resp_val_d, atomic_cas_compare_needed, atomic_seq_q[3:0] };

  // -- Sequencer Table
  always @*
    begin
      casez ( atomic_seq_sel[9:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ---------------------- 
        // --  start_atomic_seq             
        // --  |arb_eng_misc_gnt               
        // --  ||rspi_atomic_ld_resp_val_q         Outputs & Next State
        // --  |||rspi_atomic_st_resp_val_q        --------------------
        // --  ||||rspi_atomic_cas_resp_val_d      atomic_req
        // --  |||||atomic_cas_compare_needed      |atomic_seq_done
        // --  |||||| atomic_seq_q                 || atomic_seq_d
        // --  |||||| |                            || | 
        // --  987654 3210                         54 3210
        // --------------------------------------------------
           10'b0?????_0001 :  atomic_seq[5:0] =  6'b00_0001 ;  // --    Idle_ST ->    Idle_ST  - Wait for main sequencer to start this sequencer
           10'b1?????_0001 :  atomic_seq[5:0] =  6'b10_0010 ;  // --    Idle_ST ->  Wt4Gnt_ST  - Start - drive load arb request, advance to next state to wait for load grant
        // --------------------------------------------------
           10'b?0????_0010 :  atomic_seq[5:0] =  6'b00_0010 ;  // --  Wt4Gnt_ST ->  Wt4Gnt_ST  - Wait for read grant from ARB
           10'b?1????_0010 :  atomic_seq[5:0] =  6'b00_0100 ;  // --  Wt4Gnt_ST ->  Wt4Rsp_ST  - Grant received, drive cmd in nxt cycle, go wait for response
        // --------------------------------------------------
           10'b??000?_0100 :  atomic_seq[5:0] =  6'b00_0100 ;  // --  Wt4Rsp_ST ->  Wt4Rsp_ST  - Wait for response from TLX
           10'b??1???_0100 :  atomic_seq[5:0] =  6'b01_0001 ;  // --  Wt4Rsp_ST ->    Idle_ST  - Atomic Load Response received
           10'b??01??_0100 :  atomic_seq[5:0] =  6'b01_0001 ;  // --  Wt4Rsp_ST ->    Idle_ST  - Atomic Store Response received
           10'b??0010_0100 :  atomic_seq[5:0] =  6'b01_0001 ;  // --  Wt4Rsp_ST ->    Idle_ST  - Atomic RW Response received - no compare needed
           10'b??0011_0100 :  atomic_seq[5:0] =  6'b00_1000 ;  // --  Wt4Rsp_ST -> Compare_ST  - Atomic Compare And Swap Response received
        // --------------------------------------------------
           10'b??????_1000 :  atomic_seq[5:0] =  6'b01_0001 ;  // -- Compare_ST ->    Idle_ST  - Response received
        // --------------------------------------------------
            default        :  atomic_seq[5:0] =  6'b01_0001 ;  // --    Default ->    Idle_ST  - (Needed to make case "full" to prevent inferred latches)
        // --------------------------------------------------
      endcase
    end // -- always @ *                                  

  // -- Outputs (For Internal Usage)  
  assign  atomic_req_int      =  atomic_seq[5];
  assign  atomic_seq_done_int =  atomic_seq[4];

  // -- Outputs (For External Usage)  
  assign  atomic_req        =  atomic_req_int;
  assign  atomic_seq_done   =  atomic_seq_done_int;

  // -- State Outputs (For External Usage)
  assign  atomic_state[3:0] =  atomic_seq_q[3:0];
  assign  atomic_idle_st    =  atomic_idle_state;    
  assign  atomic_wt4gnt_st  =  atomic_wt4gnt_state;  
  assign  atomic_wt4rsp_st  =  atomic_wt4rsp_state ; 
  assign  atomic_compare_st =  atomic_compare_state;

  // -- Error
  assign  atomic_seq_error  =  atomic_seq_err_int;

  // -- Next State
  assign  atomic_seq_d[3:0] = ( reset || atomic_seq_err_int ) ? 4'b1 :  atomic_seq[3:0];

  // -- If cmd has data, need to send indication to the arbiter
  assign  atomic_req_w_data =  ( atomic_req_int && ( we_cmd_is_atomic_st_d || we_cmd_is_atomic_cas_d ));  // -- NOTE: atomic_cas has data, even though load response expected


  // -- ********************************************************************************************************************************
  // -- atomic_rtry State Machine 
  // -- ********************************************************************************************************************************

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc04  atomic_rtry_seq_err (
    .one_hot_vector   ( atomic_rtry_seq_q[3:0] ),
    .one_hot_error    ( atomic_rtry_seq_err_int )
  );

  // -- Current State Assignments (For Internal Usage)
  assign  atomic_rtry_idle_state      =  atomic_rtry_seq_q[0];  // -- Wait for delayed read of retry queue to trigger the start of this sequencer
  assign  atomic_rtry_wt4bckoff_state =  atomic_rtry_seq_q[1];  // -- Wait for backoff timer to count down 
  assign  atomic_rtry_wt4gnt_state    =  atomic_rtry_seq_q[2];  // -- Wait for grant to present cmd on cycle after the grant 
  assign  atomic_rtry_abort_state     =  atomic_rtry_seq_q[3];  // -- Abort, then return to idle 

  // -- Sequencer Inputs
  assign  atomic_rtry_seq_sel[10:0] = { start_atomic_rtry_seq, ( rtry_decode_is_immediate || rtry_backoff_timer_disable_q ), rtry_decode_is_backoff, rtry_decode_is_abort,
                                        atomic_rtry_backoff_done_q, atomic_rtry_backoff_done, arb_eng_rtry_misc_gnt, atomic_rtry_seq_q[3:0] };
  // -- Sequencer Table
  always @*
    begin
      casez ( atomic_rtry_seq_sel[10:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------
        // --  start_atomic_rtry_seq
        // --  |rtry_decode_is_immediate
        // --  ||rtry_decode_is_backoff 
        // --  |||rtry_decode_is_abort         
        // --  ||||atomic_rtry_backoff_done_q             Outputs & Next State
        // --  |||||atomic_rtry_backoff_done              --------------------
        // --  ||||||arb_eng_rtry_misc_gnt                atomic_rtry_req
        // --  ||||||| atomic_rtry_seq_q[3:0]             | atomic_rtry_seq_d[3:0]
        // --  1|||||| |                                  | |
        // --  0987654 3210                               4 3210
        // ------------------------------------------------------
           11'b00?????_0001 :  atomic_rtry_seq[4:0] =  5'b0_0001 ;  // --       Idle_ST ->      Idle_ST  - Wait for valid atomic rtry
           11'b11?????_0001 :  atomic_rtry_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - No Backoff Required, move directly to wt4gnt_st State
           11'b101?00?_0001 :  atomic_rtry_seq[4:0] =  5'b0_0010 ;  // --       Idle_ST -> Wt4Bckoff_ST  - Start - Backoff Required, In progresss, move to wt4bckoff_st State
           11'b101?1??_0001 :  atomic_rtry_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - Backoff Required, already completed, move directly to wt4gnt_st State
           11'b101?01?_0001 :  atomic_rtry_seq[4:0] =  5'b1_0100 ;  // --       Idle_ST ->    Wt4Gnt_ST  - Start - Backoff Required, already completed, move directly to wt4gnt_st State
           11'b1001???_0001 :  atomic_rtry_seq[4:0] =  5'b0_1000 ;  // --       Idle_ST ->     Abort_ST  - Abort, then return to idle state
        // ------------------------------------------------------          
           11'b?????0?_0010 :  atomic_rtry_seq[4:0] =  5'b0_0010 ;  // --  Wt4BckOff_ST -> Wt4BckOff_ST  - Wait for backoff timer to count down
           11'b?????1?_0010 :  atomic_rtry_seq[4:0] =  5'b1_0100 ;  // --  Wt4BckOff_ST ->    Wt4Gnt_ST  - Timer expired, issue request to ARB, move to wt4gnt_st State
        // ------------------------------------------------------          
           11'b??????0_0100 :  atomic_rtry_seq[4:0] =  5'b0_0100 ;  // --     Wt4Gnt_ST ->    Wt4Gnt_ST  - Wait for grant from ARB
           11'b??????1_0100 :  atomic_rtry_seq[4:0] =  5'b0_0001 ;  // --     Wt4Gnt_ST ->      Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle
        // ------------------------------------------------------          
           11'b???????_1000 :  atomic_rtry_seq[4:0] =  5'b0_0001 ;  // --      Abort_ST ->      Idle_ST  - Grant, drive cmd in nxt cycle, Return to Idle
        // ------------------------------------------------------          
            default         :  atomic_rtry_seq[4:0] =  5'b0_0001 ;  // --      Default  ->      Idle_ST  - (Needed to make case "full" to prevent inferred latches)
        // ------------------------------------------------------
      endcase
    end // -- always @ *

  // -- Outputs (For Internal Usage)
  assign  atomic_rtry_req_int      =  atomic_rtry_seq[4];

  // -- Outputs (For External Usage)
  assign  atomic_rtry_req          =  atomic_rtry_req_int;

  // -- State Outputs (For External Usage)
  assign  atomic_rtry_state[3:0]   =  atomic_rtry_seq_q[3:0];
  assign  atomic_rtry_idle_st      =  atomic_rtry_idle_state;
  assign  atomic_rtry_wt4bckoff_st =  atomic_rtry_wt4bckoff_state;
  assign  atomic_rtry_wt4gnt_st    =  atomic_rtry_wt4gnt_state;
  assign  atomic_rtry_abort_st     =  atomic_rtry_abort_state;

  // -- Error
  assign  atomic_rtry_seq_error    =  atomic_rtry_seq_err_int;

  // -- Next State
  assign  atomic_rtry_seq_d[3:0] = ( reset || atomic_rtry_seq_err_int ) ? 4'b1 : atomic_rtry_seq[3:0];

  // -- If cmd has data, need to send indication to the arbiter
  assign  atomic_rtry_req_w_data =  ( atomic_rtry_req_int && ( we_cmd_is_atomic_st_q || we_cmd_is_atomic_cas_q ));  


  // -- ********************************************************************************************************************************
  // -- Command Bus Out
  // -- ********************************************************************************************************************************

  // -- Form the atomic command
  // -- MemCpy2 uses PSL encodes in we_cmd_extra_q[5:0], need to map these into proper 4 bit command flag
  always @*
    begin
      if ( we_cmd_extra_q[5:4] == 2'b10 )
        atomic_flag_memcpy2[3:0] =  we_cmd_extra_q[3:0];                            // -- most of the atomic st flags match the lower 4 bits of the PSL encodes
      else if ( we_cmd_extra_q[5:4] == 2'b11 )
        atomic_flag_memcpy2[3:0] =  4'b1100;                                        // -- Store Twin
      else if (( we_cmd_extra_q[5:3] == 3'b010 ) && ~we_cmd_extra_q[0] )
        atomic_flag_memcpy2[3:0] =  4'b1010;                                        // -- Compare and Swap, Not Equal
      else if (( we_cmd_extra_q[5:3] == 3'b010 ) &&  we_cmd_extra_q[0] )
        atomic_flag_memcpy2[3:0] =  4'b1001;                                        // -- Compare and Swap, Equal
      else if ( we_cmd_extra_q[4:3] == 2'b11 )
        atomic_flag_memcpy2[3:0] =  { we_cmd_extra_q[4:2], we_cmd_extra_q[0] };     // -- Fetch and Increment/Decrement
      else
        atomic_flag_memcpy2[3:0] =  4'b0;
    end // -- always @ *

  // -- Determine if sequencer needs to go to atomic_compare_st
  assign  atomic_cas_compare_needed =  we_cmd_is_atomic_cas_q && (( ~memcpy2_format_enable_q && ((      we_cmd_extra_q[3:0] == 4'b1001 ) || (      we_cmd_extra_q[3:0] == 4'b1010 ))) ||
                                                                  (  memcpy2_format_enable_q && (( atomic_flag_memcpy2[3:0] == 4'b1001 ) || ( atomic_flag_memcpy2[3:0] == 4'b1010 ))));

  // -- Support for Command Randomization
  always @*
    begin
      if ( we_cmd_is_atomic_st_q )
        begin 
          if ( atomic_st_type_sel[0] )
            atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_W[7:0];
          else if ( atomic_st_type_sel[1] )
            atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_W_N[7:0];
          else
            atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_W[7:0];
        end
      else if ( we_cmd_is_atomic_cas_q )
        begin 
          if ( atomic_cas_type_sel[0] )
            atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_RW[7:0];
          else if ( atomic_cas_type_sel[1] )
            atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_RW_N[7:0];
          else
            atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_RW[7:0];
        end
      else if ( we_cmd_is_atomic_ld_q )
        begin 
          if ( atomic_ld_type_sel[0] )
            atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_RD[7:0];
          else if ( atomic_ld_type_sel[1] )
            atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_RD_N[7:0];
          else
            atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_RD[7:0];
        end
      else 
        atomic_opcode_rand[7:0] =  AFU_TLX_CMD_ENCODE_AMO_W[7:0];
    end // -- always @ *


  // -- Form the atomic command
  always @*
    begin
      if ( atomic_wt4gnt_state || atomic_rtry_wt4gnt_state )
        begin
          atomic_valid           =  (( atomic_wt4gnt_state && arb_eng_misc_gnt ) || ( atomic_rtry_wt4gnt_state && arb_eng_rtry_misc_gnt ));
          atomic_opcode[7:0]     =     atomic_opcode_rand[7:0];
          atomic_actag[11:0]     =     eng_actag[11:0];
          atomic_stream_id[3:0]  =     4'b0;
          atomic_ea_or_obj[67:0] =  {  4'b0, we_cmd_dest_ea_q[63:0] };
          if ( we_cmd_is_atomic_ld_q )
            atomic_afutag[15:0]  =  {  2'b00, 1'b1, we_cmd_length_q[3], 1'b1, eng_num[5:0], ATOMIC_LD_AFUTAG_ENCODE[4:0] };
          else if ( we_cmd_is_atomic_st_q )
            atomic_afutag[15:0]  =  {  2'b00, 1'b1, we_cmd_length_q[3], 1'b1, eng_num[5:0], ATOMIC_ST_AFUTAG_ENCODE[4:0] };
          else if ( we_cmd_is_atomic_cas_q )
            atomic_afutag[15:0]  =  {  2'b00, 1'b1, we_cmd_length_q[3], 1'b1, eng_num[5:0], ATOMIC_CAS_AFUTAG_ENCODE[4:0] };
          else
            atomic_afutag[15:0]  =  {  2'b00, 1'b1, we_cmd_length_q[3], 1'b1, eng_num[5:0], 5'b00000 };
          atomic_dl[1:0]         =     2'b00;
          atomic_os              =     1'b0;
          atomic_be[63:0]        =    64'b0;
          if ( ~memcpy2_format_enable_q )
            begin
              atomic_pl[2:0]     =  { ( we_cmd_is_atomic_cas_q && we_cmd_extra_q[3] ), 1'b1, we_cmd_length_q[3] };  // -- b'010 for 4B amo_w & amo_r, b'011 for 8B amo_w & amo_r, b'110 for 4B amo_rw, b'111 for 8B amo_rw 
              atomic_flag[3:0]   =     we_cmd_extra_q[3:0];
              atomic_endian      =     we_cmd_extra_q[7];
            end
          else
            begin
              atomic_pl[2:0]     =  { ( we_cmd_is_atomic_cas_q && atomic_flag_memcpy2[3] ), 1'b1, we_cmd_length_q[3] };  // -- b'010 for 4B amo_w & amo_r, b'011 for 8B amo_w & amo_r, b'110 for 4B amo_rw, b'111 for 8B amo_rw 
              atomic_flag[3:0]   =     atomic_flag_memcpy2[3:0];
              atomic_endian      =    ~we_cmd_extra_q[7];
            end
          atomic_bdf[15:0]       =  { cfg_afu_bdf_bus[7:0], cfg_afu_bdf_device[4:0], cfg_afu_bdf_function[2:0] };
//             atomic_pasid[19:0]     =  { 10'b0, cmd_pasid_q[9:0] };
          atomic_pg_size[5:0]    =     6'b0;
        end
      else
        begin
          atomic_valid           =    1'b0;
          atomic_opcode[7:0]     =    8'b0;
          atomic_actag[11:0]     =   12'b0;
          atomic_stream_id[3:0]  =    4'b0;
          atomic_ea_or_obj[67:0] =   68'b0;
          atomic_afutag[15:0]    =   16'b0;
          atomic_dl[1:0]         =    2'b0;
          atomic_pl[2:0]         =    3'b0;
          atomic_os              =    1'b0;
          atomic_be[63:0]        =   64'b0;
          atomic_flag[3:0]       =    4'b0;
          atomic_endian          =    1'b0;
          atomic_bdf[15:0]       =   16'b0;
//             atomic_pasid[19:0]     =   20'b0;
          atomic_pg_size[5:0]    =    6'b0;
        end
    end // -- always @ *


  // -- ********************************************************************************************************************************
  // -- Data Bus Out
  // -- ********************************************************************************************************************************
  
  // -- Atomic Store & Compare/Swap Data
  always @*
    begin
      // -- Align 4B or 8B OP data within 8B field
      if ( we_cmd_length_q[3] )
        begin
          atomic_op1[63:0] = we_cmd_atomic_op1_q[63:0];               // -- 8 Byte atomic op
          atomic_op2[63:0] = we_cmd_atomic_op2_q[63:0];
        end                                     
      else if ( ~we_cmd_dest_ea_q[2] )
        begin
          atomic_op1[63:0] =  { 32'b0, we_cmd_atomic_op1_q[31:0] };   // -- 4 Byte atomic op, 8 byte aligned  ( Bytes 3:0 )
          atomic_op2[63:0] =  { 32'b0, we_cmd_atomic_op2_q[31:0] };
        end                                     
      else
        begin
          atomic_op1[63:0] =  { we_cmd_atomic_op1_q[31:0], 32'b0 };   // -- 4 Byte atomic op, 4 byte aligned  ( Bytes 7:4 )
          atomic_op2[63:0] =  { we_cmd_atomic_op2_q[31:0], 32'b0 };
        end                                     

      // -- Form atomic st and atomic cas data, replicated to fill 64 Bytes
      atomic_st_data[511:0] =  { 8{ atomic_op1[63:0] }};

      if ( ~we_cmd_dest_ea_q[3] )
        atomic_cas_data[511:0] =  { 4{ atomic_op2[63:0], atomic_op1[63:0] }};
      else
        atomic_cas_data[511:0] =  { 4{ atomic_op1[63:0], atomic_op2[63:0] }};

      // -- Pulse the atomic store data for 1 cycle (coincident with the command)
      atomic_drive_data_d =  (( atomic_wt4gnt_state && arb_eng_misc_gnt ) || ( atomic_rtry_wt4gnt_state && arb_eng_rtry_misc_gnt ));

      if ( atomic_drive_data_q &&  we_cmd_is_atomic_st_q )
        atomic_data[511:0] =   atomic_st_data[511:0];
      else if ( atomic_drive_data_q &&  we_cmd_is_atomic_cas_q )      
        atomic_data[511:0] =   atomic_cas_data[511:0];
      else
        atomic_data[511:0] =   512'b0;

      atomic_data_valid =  atomic_drive_data_d;

    end // -- always @ *

                                

  // -- ********************************************************************************************************************************
  // -- Atomic Compare and swap - comparison of read response data with OP1 to determine success/failure 
  // -- ********************************************************************************************************************************

  // -- Capture into latches and hold (using gating)
  // -- After captured, decode the command in the following cycle

  always @*
    begin

      if (we_cmd_length_q[3] )
        begin
          atomic_cas_compare_op1[63:0] =  we_cmd_atomic_op1_q[63:0];  

          case ( we_cmd_dest_ea_q[5:3] )
            3'b111 :  atomic_cas_compare_data[63:0] =  rspi_resp_data_q[511:448];   // -- 8 Byte Atomic Compare and Swap operation
            3'b110 :  atomic_cas_compare_data[63:0] =  rspi_resp_data_q[447:384];
            3'b101 :  atomic_cas_compare_data[63:0] =  rspi_resp_data_q[383:320];
            3'b100 :  atomic_cas_compare_data[63:0] =  rspi_resp_data_q[319:256];
            3'b011 :  atomic_cas_compare_data[63:0] =  rspi_resp_data_q[255:192];
            3'b010 :  atomic_cas_compare_data[63:0] =  rspi_resp_data_q[191:128];
            3'b001 :  atomic_cas_compare_data[63:0] =  rspi_resp_data_q[127:64];
            3'b000 :  atomic_cas_compare_data[63:0] =  rspi_resp_data_q[63:0];
          endcase
        end
      else
        begin
          atomic_cas_compare_data[63:32] =   32'b0;
          atomic_cas_compare_op1[63:0]   = { 32'b0, we_cmd_atomic_op1_q[31:0] };  
          case (we_cmd_dest_ea_q[5:2] )
            4'b1111 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[511:480];   // -- 4 Byte Atomic Compare and Swap operation
            4'b1110 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[479:448];
            4'b1101 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[447:416];
            4'b1100 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[415:384];
            4'b1011 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[383:352];
            4'b1010 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[351:320];
            4'b1001 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[319:288];
            4'b1000 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[287:256];
            4'b0111 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[255:224];
            4'b0110 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[223:192];
            4'b0101 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[191:160];
            4'b0100 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[159:128];
            4'b0011 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[127:96];
            4'b0010 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[95:64];
            4'b0001 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[63:32];
            4'b0000 :  atomic_cas_compare_data[31:0] =  rspi_resp_data_q[31:0];
          endcase
        end
    end // -- always @ *

  // -- Set and hold atomic cas failure to present to wr_weq state machine - prevents updating offset in write back to WEQ
  assign  set_atomic_cas_failure =  (( atomic_compare_state &&                                                                      // -- Only set during atomic_compare_st
                                   ((( atomic_cas_compare_data[63:0] != atomic_cas_compare_op1[63:0] ) &&  we_cmd_extra_q[0] ) ||   // -- Compare and Swap Equal,  data miscompares
                                    (( atomic_cas_compare_data[63:0] == atomic_cas_compare_op1[63:0] ) && ~we_cmd_extra_q[0] ))));  // -- Compare and Swap Not Equal, data compares

  assign  atomic_cas_failure_en =  ( set_atomic_cas_failure || main_seq_done || reset );
  assign  atomic_cas_failure_d  =    set_atomic_cas_failure;


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      atomic_seq_q[3:0]                            <= atomic_seq_d[3:0];        
      atomic_rtry_seq_q[3:0]                       <= atomic_rtry_seq_d[3:0];

      atomic_drive_data_q                          <= atomic_drive_data_d;

      if ( atomic_cas_failure_en )
        atomic_cas_failure_q                       <= atomic_cas_failure_d;

    end // -- always @ *

endmodule
