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

module afp3_eng_fsm_main
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config
  , input                 mmio_eng_use_pasid_for_actag
  , input                 mmio_eng_enable
  , input                 mmio_eng_type_ld
  , input                 mmio_eng_type_st
  , input         [63:12] mmio_eng_base_addr
  , input         [31:12] mmio_eng_offset_mask
  , input           [1:0] mmio_eng_ld_size
  , input           [1:0] mmio_eng_st_size
  , input           [9:0] mmio_eng_pasid
  , input                 mmio_eng_send_interrupt
  , input                 mmio_eng_send_wkhstthrd
  , input                 mmio_eng_error_intrpt_enable
  , input                 mmio_eng_wkhstthrd_intrpt_enable
  , input                 mmio_eng_extra_write_mode
  , input                 mmio_eng_mmio_lat_mode
  , input                 mmio_eng_mmio_lat_mode_sz_512_st
  , input                 mmio_eng_mmio_lat_mode_sz_512_ld
  , input                 mmio_eng_mmio_lat_extra_read
  , input          [63:7] mmio_eng_mmio_lat_ld_ea
  , input                 mmio_eng_xtouch_enable
  , input           [1:0] mmio_eng_xtouch_pg_n
  , input           [5:0] mmio_eng_xtouch_pg_size
//     , input          [18:5] cmd_offset_q

  // -- Main Sequencer Control Inputs
  , input                 actag_seq_done
  , input                 arb_eng_tags_idle
  , input                 arb_eng_ld_gnt
  , input                 arb_eng_st_gnt

  , input                 xtouch_error_q
  , input                 cpy_ld_error_q
  , input                 cpy_st_error_q
  , input                 wkhstthrd_error_q
  , input                 atomic_error_q
//     , input                 mmio_eng_intrpt_on_cpy_err_en

  , input                 intrpt_idle_st
  , input                 intrpt_rtry_idle_st
  , input                 wkhstthrd_idle_st
  , input                 wkhstthrd_rtry_idle_st
  , input                 atomic_idle_st
  , input                 atomic_rtry_idle_st

  // -- Main Sequencer Outputs
  , output                main_seq_error

  , output          [4:0] main_state
  , output                main_idle_st
  , output                main_actag_st
  , output                main_send_st
  , output                main_err_intrpt_st
  , output                main_stop_st

  , output                start_actag_seq
//     , output                start_we_ld_seq
  , output                start_xtouch_seq
  , output                start_cpy_ld_seq
  , output                start_cpy_st_seq
  , output                start_wkhstthrd_seq
//     , output                start_incr_seq
  , output                start_atomic_seq
  , output                start_intrpt_seq
//     , output                start_we_st_seq
//     , output                start_wr_weq_seq
  , output                main_seq_done

  , output         [63:6] cpy_ld_ea_q
  , output         [63:6] cpy_st_ea_q
  , output         [63:0] xtouch_ea_q
  , output                cpy_ld_idle_st
  , output                cpy_st_idle_st
  , output                cpy_ld_wt4rsp_st
  , output                cpy_st_wt4rsp_st
  , output                cpy_ld_type_sel
  , output                cpy_st_type_sel

  , output                we_cmd_is_intrpt_q       //     - Added for AFP.  Mimics MCP's WEQ cmd
  , output                we_cmd_is_wkhstthrd_q    //     - Added for AFP.  Mimics MCP's WEQ cmd

  , output          [9:0] cmd_pasid_q
  , output                eng_arb_init
  , output                eng_arb_ld_enable
  , output                eng_arb_st_enable

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  wire            skip_assign_actag;
  wire            misc_idle;
  wire      [1:0] intrpt_cmd;

  wire            any_major_error;
  wire            stop_for_wkhstthrd_error;
  wire            all_tags_idle;
  wire            main_seq_err_int;
  wire            main_idle_st_int;
  wire     [12:0] main_seq_sel;
  reg       [6:0] main_seq;

  wire            start_capture;

  wire            ld_enable;
  wire            st_enable;
  wire            send_error_intrpt;
  wire            start_intrpt;
  wire            start_wkhstthrd;
  wire            xtouch_enable;

  // Effective Address
  wire            inc_addr;
  wire     [31:7] offset_addr_plus1;
  wire     [31:7] offset_addr_plus2;
  wire     [31:7] offset_addr_plus1or2;
  wire     [31:7] next_addr;
  wire            toggle_addr_for_mmio_lat;
  wire     [31:7] toggle_addr;
  wire     [63:6] curr_addr;

  wire            extra_read_mode;
  wire            toggle_ld_addr_for_extra_read;
  wire            extra_read_ea_bit8;

  // Xlate touch
  wire            xtouch_pg_size_4k;  // Unused - leaving in for easier debug
  wire            xtouch_pg_size_64k;
  wire            xtouch_pg_size_2m;
  wire            xtouch_pg_size_16m;
  wire            xtouch_pg_size_1g;

  reg      [63:0] xtouch_addr_mask;
  wire            crossed_page;
  wire      [7:0] xtouch_adder_sel;
  reg     [31:12] xtouch_addr_adder;
  wire    [31:12] xtouch_plus_n;

  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  wire             use_pasid_for_actag_d;
  reg              use_pasid_for_actag_q;

  //wire             mmio_eng_enable_d;
  reg              mmio_eng_enable_q;

  //wire             mmio_eng_mmio_lat_mode_d;
  reg              mmio_eng_mmio_lat_mode_q;

  //wire             mmio_eng_mmio_lat_mode_sz_512_st_d;
  reg              mmio_eng_mmio_lat_mode_sz_512_st_q;

  //wire             mmio_eng_mmio_lat_mode_sz_512_ld_d;
  reg              mmio_eng_mmio_lat_mode_sz_512_ld_q;

  //wire             mmio_eng_mmio_lat_extra_read_d;
  reg              mmio_eng_mmio_lat_extra_read_q;

  //wire             mmio_eng_type_ld_d;
  reg              mmio_eng_type_ld_q;

  //wire             mmio_eng_type_st_d;
  reg              mmio_eng_type_st_q;

  reg      [63:12] base_addr_q;

  reg      [31:12] offset_mask_q;

  reg        [9:0] mmio_eng_pasid_q;

  wire       [4:0] main_seq_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg        [4:0] main_seq_q;

  wire             step_size_256_d;
  reg              step_size_256_q;

  wire      [31:7] offset_addr_d;
  reg       [31:7] offset_addr_q;

  wire             toggle_ld_addr_bit8_d;
  reg              toggle_ld_addr_bit8_q;

  wire      [63:7] cpy_ld_ea_int_d;
  reg       [63:7] cpy_ld_ea_int_q;

  wire       [5:0] xtouch_pg_size_d;
  reg        [5:0] xtouch_pg_size_q;

  wire             inc_addr_d;
  reg              inc_addr_q;

  wire             xtouch_addr_en;
  wire     [31:12] xtouch_addr_d;
  reg      [31:12] xtouch_addr_q;

  wire             send_interrupt_d;
  reg              send_interrupt_q;

  wire             send_wkhstthrd_d;
  reg              send_wkhstthrd_q;

  wire             send_wkhstthrd_intrpt_d;
  reg              send_wkhstthrd_intrpt_q;

  wire             cmd_is_intrpt_d;
  reg              cmd_is_intrpt_q;

  wire             cmd_is_wkhstthrd_d;
  reg              cmd_is_wkhstthrd_q;

  //wire             mmio_eng_error_intrpt_enable_d;
  reg              mmio_eng_error_intrpt_enable_q;

  //wire             mmio_eng_wkhstthrd_intrpt_enable_d;
  reg              mmio_eng_wkhstthrd_intrpt_enable_q;

  //wire             mmio_eng_extra_write_mode_d;
  reg              mmio_eng_extra_write_mode_q;

  //wire             mmio_eng_xtouch_enable_d;
  reg              mmio_eng_xtouch_enable_q;

  //wire       [1:0] mmio_eng_xtouch_pg_n_d;
  reg        [1:0] mmio_eng_xtouch_pg_n_q;

  // -- ********************************************************************************************************************************
  // -- Constant declarations 
  // -- ********************************************************************************************************************************



  // -- ********************************************************************************************************************************
  // -- Mode/Config Repower Latches
  // -- ********************************************************************************************************************************

  assign  use_pasid_for_actag_d   =   mmio_eng_use_pasid_for_actag;

//     assign  skip_assign_actag       =  ( use_pasid_for_actag_q && | cmd_offset_q[18:5] );  // -- Only issue assign actag cmd for cmd_offset = zeros
  assign  skip_assign_actag       =  ( use_pasid_for_actag_q );  // -- Only issue assign actag cmd for cmd_offset = zeros // ??? TODO Do I still need this?  I don't think cmd_offset applies any more, since we start aligned, and we only get actag once

  assign  cmd_pasid_q[9:0]  =  mmio_eng_pasid_q[9:0];

  // -- ********************************************************************************************************************************
  // -- Interrupt / Wake Host Thread Latches
  // -- ********************************************************************************************************************************

  assign  send_interrupt_d  =  mmio_eng_send_interrupt | (send_interrupt_q & ~start_intrpt);      // -- MMIO sends a single pulse.  Keep it around if it is set before AFP is ready to go (enabled + actag sent)

  assign  send_wkhstthrd_d  =  mmio_eng_send_wkhstthrd | (send_wkhstthrd_q & ~start_wkhstthrd);   // -- MMIO sends a single pulse.  Keep it around if it is set before AFP is ready to go (enabled + actag sent)

  // Only allow one misc command at a time, since that was the way MCP was written.
  assign  misc_idle  =  intrpt_idle_st    & intrpt_rtry_idle_st &
                        wkhstthrd_idle_st & wkhstthrd_rtry_idle_st &
                        atomic_idle_st    & atomic_rtry_idle_st;

  assign  send_wkhstthrd_intrpt_d  =  ( wkhstthrd_error_q | send_wkhstthrd_intrpt_q) & ~start_intrpt & mmio_eng_wkhstthrd_intrpt_enable_q;

  // Interrupt logic uses this to determine if int request is due to interrupt request, wkhstthrd error, or other error
  assign  intrpt_cmd[1:0]    =  (start_intrpt & send_error_intrpt)       ?  2'b00 :
                                (start_intrpt & send_wkhstthrd_intrpt_q) ?  2'b01 :
                                (start_intrpt & send_interrupt_q)        ?  2'b10 :
                                (start_wkhstthrd)                        ?  2'b01 :
                                                                         { cmd_is_intrpt_q, cmd_is_wkhstthrd_q };   // Feedback path

  assign  cmd_is_intrpt_d    = intrpt_cmd[1];
  assign  cmd_is_wkhstthrd_d = intrpt_cmd[0];

  assign  we_cmd_is_intrpt_q    =  cmd_is_intrpt_q;
  assign  we_cmd_is_wkhstthrd_q =  cmd_is_wkhstthrd_q;

  // -- ********************************************************************************************************************************
  // -- Main State Machine
  // -- ********************************************************************************************************************************

  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc05  main_seq_err (
    .one_hot_vector   ( main_seq_q[4:0] ),
    .one_hot_error    ( main_seq_err_int )
  );

  assign  any_major_error  =  xtouch_error_q | cpy_ld_error_q | cpy_st_error_q | atomic_error_q ;   // Handle wkhstthrd_error separately

  assign  stop_for_wkhstthrd_error =  wkhstthrd_error_q & ~mmio_eng_wkhstthrd_intrpt_enable_q;      // On a wkhstthrd error, send an interrupt or stop engine, depending on mode setting

  assign  all_tags_idle  =  arb_eng_tags_idle & misc_idle;

  // -- Current State Assignments
  assign  main_idle_st      =  main_seq_q[0];  // -- State 0  - main_idle_st      - Waiting for MMIO to assign work to this engine
  assign  main_actag_st     =  main_seq_q[1];  // -- State 1  - main_actag_st     - Issue assign actag cmd 
  assign  main_send_st      =  main_seq_q[2];  // -- State 2  - main_send_st      - Send load/store commands
  assign  main_err_intrpt_st=  main_seq_q[3];  // -- State 3  - main_err_intrpt_st- Send interrupt for error condition. Stop sending other commands
  assign  main_stop_st      =  main_seq_q[4];  // -- State 4  - main_stop_st      - Stop sending commands and wait for outstanding responses

  assign  main_idle_st_int  =  main_seq_q[0];  // -- State 0  - main_idle_st      - Waiting for MMIO to assign work to this engine
              
  // -- Inputs
  assign  main_seq_sel[12:0] = { mmio_eng_enable_q, skip_assign_actag, actag_seq_done, any_major_error, mmio_eng_error_intrpt_enable_q, stop_for_wkhstthrd_error, start_intrpt, all_tags_idle, main_seq_q[4:0] };

  always @*
    begin
      casez ( main_seq_sel[12:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // -- 
        // --   Inputs & Current State
        // --   ----------------------
        // --   mmio_eng_enable_q
        // --   |skip_assign_actag
        // --   ||actag_seq_done
        // --   ||| any_major_error
        // --   ||| |mmio_eng_error_intrpt_enable_q
        // --   ||| ||stop_for_wkhstthrd_error
        // --   ||| |||start_intrpt
        // --   ||| ||||all_tags_idle
        // --   ||| |||||                              start_actag_seq
        // --   ||| |||||                              |start_capture
        // --   ||| |||||                              ||
        // --   ||| ||||| main_seq_q                   || main_seq
        // --   111 ||||| |                            || |
        // --   210_98765_43210                        65_43210
        // --------------------------------------------------------------------------------------------------------
            13'b00?_?????_00001 :  main_seq[6:0] =  7'b00_00001 ;  // --       idle_ST -> idle_ST
            13'b10?_0????_00001 :  main_seq[6:0] =  7'b11_00010 ;  // --       idle_ST -> actag_ST
            13'b11?_0????_00001 :  main_seq[6:0] =  7'b01_00100 ;  // --       idle_ST -> send_ST
        // --------------------------------------------------------------------------------------------------------        
            13'b??0_?????_00010 :  main_seq[6:0] =  7'b00_00010 ;  // --      actag_ST -> actag_ST
            13'b1?1_?????_00010 :  main_seq[6:0] =  7'b00_00100 ;  // --      actag_ST -> send_ST
            13'b0?1_?????_00010 :  main_seq[6:0] =  7'b00_00001 ;  // --      actag_ST -> idle_ST
        // --------------------------------------------------------------------------------------------------------        
            13'b1??_0?0??_00100 :  main_seq[6:0] =  7'b00_00100 ;  // --       send_ST -> send_ST
            13'b0??_?????_00100 :  main_seq[6:0] =  7'b00_10000 ;  // --       send_ST -> stop_ST       Stop when no longer enabled
            13'b1??_??1??_00100 :  main_seq[6:0] =  7'b00_10000 ;  // --       send_ST -> stop_ST       Stop on error
            13'b1??_100??_00100 :  main_seq[6:0] =  7'b00_10000 ;  // --       send_ST -> stop_ST       Stop on error
            13'b1??_110??_00100 :  main_seq[6:0] =  7'b00_01000 ;  // --       send_ST -> err_intrpt_ST Send interrupt on error
        // --------------------------------------------------------------------------------------------------------        
            13'b1??_???0?_01000 :  main_seq[6:0] =  7'b00_01000 ;  // -- err_intrpt_ST -> err_intrpt_ST Send an interrupt due to error
            13'b1??_???1?_01000 :  main_seq[6:0] =  7'b00_10000 ;  // -- err_intrpt_ST -> stop_ST       Stop after interrupt is sent
            13'b0??_?????_01000 :  main_seq[6:0] =  7'b00_10000 ;  // -- err_intrpt_ST -> stop_ST       Stop when no longer enabled
        // --------------------------------------------------------------------------------------------------------        
            13'b???_????0_10000 :  main_seq[6:0] =  7'b00_10000 ;  // --       stop_ST -> stop_ST       Wait for outstanding commands to finish
            13'b???_????1_10000 :  main_seq[6:0] =  7'b00_00001 ;  // --       stop_ST -> idle_ST
        // --------------------------------------------------------------------------------------------------------        
            default             :  main_seq[6:0] =  7'b00_00001 ;  // --       default -> idle_ST       (Needed to make case "full" to prevent inferred latches)
        // --------------------------------------------------------------------------------------------------------
      endcase
    end // -- always @ *

  // -- Table Outputs
  assign  start_actag_seq      =  main_seq[6];
  assign  start_capture        =  main_seq[5];

  // -- Next State
  assign  main_seq_d[4:0]      = ( reset || main_seq_err_int ) ? 5'b1 : main_seq[4:0];

  // -- State Outputs (For External Usage)
  assign  main_state[4:0]      =  main_seq_q[4:0];

  assign  eng_arb_init         =  start_capture;
  assign  ld_enable            =  main_seq_q[2] & ~mmio_eng_extra_write_mode_q;
  assign  st_enable            =  main_seq_q[2] & ~mmio_eng_extra_write_mode_q;

  assign  send_error_intrpt    =  main_seq_q[3];

  assign  start_intrpt         =  ( (main_seq_q[2] & send_interrupt_q) |
                                    (main_seq_q[2] & send_wkhstthrd_intrpt_q) |
                                    (send_error_intrpt) )  &
                                  misc_idle &
                                  ~send_wkhstthrd_q;  // If wkhstthrd is pending, send wkhstthrd first

  assign  start_wkhstthrd      =  main_seq_q[2] & send_wkhstthrd_q & misc_idle;

  assign  xtouch_enable        =  main_seq_q[2] & mmio_eng_xtouch_enable_q;

  assign  cpy_ld_idle_st       =  main_seq_q[0];  // Idle, ??? TODO: Do I want to OR in when we are not doing loads?
  assign  cpy_st_idle_st       =  main_seq_q[0];  // Idle, ??? TODO: Do I want to OR in when we are not doing stores?

  assign  cpy_ld_wt4rsp_st     =  main_seq_q[2] | main_seq_q[3] | main_seq_q[4];  // Used by rtry for enabling arrays and sanity check that load retries can occur
  assign  cpy_st_wt4rsp_st     =  main_seq_q[2] | main_seq_q[3] | main_seq_q[4];  // Used by rtry for enabling arrays and sanity check that load retries can occur

  assign  eng_arb_ld_enable    =  ld_enable;
  assign  eng_arb_st_enable    =  st_enable;

  assign  cpy_ld_type_sel      =  mmio_eng_type_ld_q;
  assign  cpy_st_type_sel      =  mmio_eng_type_st_q;

  assign  start_xtouch_seq     =  xtouch_enable & crossed_page;  //    main_seq[21];
  assign  start_cpy_ld_seq     =  ld_enable;  //main_seq[20];
  assign  start_cpy_st_seq     =  st_enable;  //main_seq[19];
  assign  start_wkhstthrd_seq  =  start_wkhstthrd;
  //assign  start_incr_seq       =  1'b0;  //main_seq[17];
  assign  start_atomic_seq     =  1'b0;  //main_seq[16];
  assign  start_intrpt_seq     =  start_intrpt;
  //assign  start_we_st_seq      =  1'b0;  //main_seq[14];
  //assign  start_wr_weq_seq     =  1'b0;  //main_seq[13];
  //assign  main_seq_done        =  1'b0;  //main_seq[12];
  assign  main_seq_done        =  main_idle_st_int;

  // -- Error
  assign  main_seq_error  =  main_seq_err_int;


  // -- ********************************************************************************************************************************
  // -- Effective Address
  // -- ********************************************************************************************************************************

  assign  step_size_256_d  =  (mmio_eng_ld_size[1:0] == 2'b11) || (mmio_eng_st_size[1:0] == 2'b11);  // clk_enable:  main_idle_st_int

  assign  inc_addr  =  (arb_eng_ld_gnt | arb_eng_st_gnt) &
                        ~mmio_eng_mmio_lat_mode_q & ~mmio_eng_extra_write_mode_q;  // Always use base address for MMIO latency mode & extra write mode

  assign  offset_addr_plus1[31:7]  =  offset_addr_q[31:7] + 25'b1;
  assign  offset_addr_plus2[31:7]  =  {(offset_addr_q[31:8] + 24'b1), 1'b0};

  assign  offset_addr_plus1or2[31:7]  = step_size_256_q ?  offset_addr_plus2[31:7]  :  // Increment by 256B if any command is 256B
                                                           offset_addr_plus1[31:7];    // Increment by 128B for 128B & 64B

  assign  next_addr[31:12]  =  (base_addr_q[31:12]          & ~offset_mask_q[31:12]) |
	                       (offset_addr_plus1or2[31:12] &  offset_mask_q[31:12]);

  assign  next_addr[11:7]   =  offset_addr_plus1or2[11:7];  

  // For 512B MMIO Ping-Pong Latency Mode, send two 256B stores.  Alternate between base_addr & base_addr + 256.
  assign  toggle_addr_for_mmio_lat  = mmio_eng_mmio_lat_mode_q & mmio_eng_mmio_lat_mode_sz_512_st_q & arb_eng_st_gnt;
  assign  toggle_addr[31:7] =  { offset_addr_q[31:9], (~offset_addr_q[8]), offset_addr_q[7] };

  assign  offset_addr_d[31:7]  =  start_capture ? { base_addr_q[31:12] , 5'b0 } :
                                  inc_addr      ?   next_addr[31:7] :
                       toggle_addr_for_mmio_lat ?   toggle_addr[31:7] :
                                                    offset_addr_q[31:7];

  assign  curr_addr[63:32]   =  base_addr_q[63:32];
  assign  curr_addr[31:7]    =  offset_addr_q[31:7];
  assign  curr_addr[6]       =  1'b0;

  assign  cpy_st_ea_q[63:6]  =  curr_addr[63:6];

  // For Extra Read for MMIO Ping-Pong Latency Mode, use separate address for loads.  For 512B mode, send two 256B reads.  Alternate between base_addr & base_addr + 256.
  // Note: For 512B, extra read address must be 512B aligned
  // (this way the logic can just toggle the bit instead of implementing a full incrementer)
  assign  extra_read_mode = mmio_eng_mmio_lat_mode_q & mmio_eng_mmio_lat_extra_read_q;
  assign  toggle_ld_addr_for_extra_read  = mmio_eng_mmio_lat_mode_q & mmio_eng_mmio_lat_mode_sz_512_ld_q & mmio_eng_mmio_lat_extra_read_q & arb_eng_ld_gnt;

  assign  toggle_ld_addr_bit8_d  =  reset | (~extra_read_mode) ? 1'b0 :
                                    toggle_ld_addr_for_extra_read ? (~toggle_ld_addr_bit8_q) :
                                                                      toggle_ld_addr_bit8_q;

  assign  extra_read_ea_bit8  =  mmio_eng_mmio_lat_ld_ea[8] | toggle_ld_addr_bit8_d;

  assign  cpy_ld_ea_int_d[63:7]  = extra_read_mode ? { mmio_eng_mmio_lat_ld_ea[63:9], extra_read_ea_bit8, mmio_eng_mmio_lat_ld_ea[7]} :
                                                     { base_addr_q[63:32], offset_addr_d[31:7] };

  assign  cpy_ld_ea_q[63:6]  =  { cpy_ld_ea_int_q[63:7] , 1'b0 };   //curr_addr[63:6];

  // -- ********************************************************************************************************************************
  // -- Xlate touch (xtouch)
  // -- ********************************************************************************************************************************
  // -- When enabled, AFP will issue a xlate_touch when it crosses a page boundary, for the Nth page after the current page.
  // -- For example, if N=1, page size = 4K, & addr= 0xABCD_1000, AFP will issue a xlate_touch for 0xABCD_2000.
  // -- Since offset_addr is currently only implemented for [31:7], xlate touch is not implemented for page sizes or N values that
  // -- go outside of this range.  (e.g. no 16 G pages).

  // (Not implemented): If mode is use_prev_pg_size, load log2_pg_size field when touch_done response occurs.
  // Else, use page_size from MMIO register
  //assign  xtouch_pg_size_d[5:0]  =  reset ? 6'b001100 :   // initialize to 4K
                                    //mmio_eng_xtouch_use_prev_pg_size ?  // not implemented
                                    //  (rspi_resp_is_xtouch_good ? cmd_xtouch_log2_pg_size[5:0] :
                                    //                              xtouch_pg_size_q[5:0]) :
                                    //mmio_eng_xtouch_pg_size[5:0];
  assign  xtouch_pg_size_d[5:0]  = mmio_eng_xtouch_pg_size[5:0];

  assign  xtouch_pg_size_4k   =  ( xtouch_pg_size_q[5:0] == 6'b00_1100 );
  assign  xtouch_pg_size_64k  =  ( xtouch_pg_size_q[5:0] == 6'b01_0000 );
  assign  xtouch_pg_size_2m   =  ( xtouch_pg_size_q[5:0] == 6'b01_0101 );
  assign  xtouch_pg_size_16m  =  ( xtouch_pg_size_q[5:0] == 6'b01_1000 );
  assign  xtouch_pg_size_1g   =  ( xtouch_pg_size_q[5:0] == 6'b01_1110 );
  //assign  xtouch_pg_size_16g  =  ( xtouch_pg_size_q[5:0] == 6'b10_0010 );  // Currently not implemented since it does not fall into offset_addr range

  always @*
    begin
    casez ( xtouch_pg_size_q[5:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------             Outputs & Next State
        // --  xtouch_pg_size_q                 --------------------
        // --  |
        // --  54 3210
        // -------------------------------------------------
            //6'b10_0010 :  xtouch_addr_mask[63:0] = 64'h0000_0003_FFFF_FFFF ;  // -- 16 G
            6'b01_1110 :  xtouch_addr_mask[63:0] = 64'h0000_0000_3FFF_FFFF ;  // --  1 G
            6'b01_1000 :  xtouch_addr_mask[63:0] = 64'h0000_0000_00FF_FFFF ;  // -- 16 M
            6'b01_0101 :  xtouch_addr_mask[63:0] = 64'h0000_0000_001F_FFFF ;  // --  2 M
            6'b01_0000 :  xtouch_addr_mask[63:0] = 64'h0000_0000_0000_FFFF ;  // -- 64 K
            6'b00_1100 :  xtouch_addr_mask[63:0] = 64'h0000_0000_0000_0FFF ;  // --  4 K
        // -------------------------------------------------
            default    :  xtouch_addr_mask[63:0] = 64'h0000_0000_0000_0FFF ;  // --  4 K  default (Needed to make case "full" to prevent inferred latches)
        // -------------------------------------------------
      endcase
    end // -- always @ *  

  // Detect when crossing a page boundary
  // _q = 0's for 2^(n-1):0
  assign  inc_addr_d  = inc_addr;

  assign  crossed_page  =  inc_addr_q  &  ~(| (curr_addr[63:6] & xtouch_addr_mask[63:6]) );  // incremented address last cycle
                                                                                             // and  addr[log2pagesize-1:0] = all zeros

  // Calculate address to touch
  // Add pagesize, then mask with offset_mask (to handle looping around)
  assign  xtouch_adder_sel[7:0]  =  { mmio_eng_xtouch_pg_n_q[1:0], xtouch_pg_size_q[5:0] };

  always @*
    begin
    casez ( xtouch_adder_sel[7:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority logic
        // --
        // --  Inputs & Current State
        // --  ----------------------                Outputs & Next State
        // --  mmio_eng_xtouch_pg_n_q                --------------------
        // --  |  xtouch_pg_size_q
        // --  |  |
        // --  10 54 3210
        // -------------------------------------------------
            8'b00_00_1100 :  xtouch_addr_adder[31:12] = 20'h00001 ;  // --  4 K, N=1
            8'b01_00_1100 :  xtouch_addr_adder[31:12] = 20'h00002 ;  // --  4 K, N=2
            8'b10_00_1100 :  xtouch_addr_adder[31:12] = 20'h00003 ;  // --  4 K, N=3
            8'b11_00_1100 :  xtouch_addr_adder[31:12] = 20'h00004 ;  // --  4 K, N=4
        // -------------------------------------------------
            8'b00_01_0000 :  xtouch_addr_adder[31:12] = 20'h00010 ;  // -- 64 K, N=1
            8'b01_01_0000 :  xtouch_addr_adder[31:12] = 20'h00020 ;  // -- 64 K, N=2
            8'b10_01_0000 :  xtouch_addr_adder[31:12] = 20'h00030 ;  // -- 64 K, N=3
            8'b11_01_0000 :  xtouch_addr_adder[31:12] = 20'h00040 ;  // -- 64 K, N=4
        // -------------------------------------------------
            8'b00_01_0101 :  xtouch_addr_adder[31:12] = 20'h00200 ;  // --  2 M, N=1
            8'b01_01_0101 :  xtouch_addr_adder[31:12] = 20'h00400 ;  // --  2 M, N=2
            8'b10_01_0101 :  xtouch_addr_adder[31:12] = 20'h00600 ;  // --  2 M, N=3
            8'b11_01_0101 :  xtouch_addr_adder[31:12] = 20'h00800 ;  // --  2 M, N=4
        // -------------------------------------------------
            8'b00_01_1000 :  xtouch_addr_adder[31:12] = 20'h01000 ;  // -- 16 M, N=1
            8'b01_01_1000 :  xtouch_addr_adder[31:12] = 20'h01000 ;  // -- 16 M, N=2
            8'b10_01_1000 :  xtouch_addr_adder[31:12] = 20'h01000 ;  // -- 16 M, N=3
            8'b11_01_1000 :  xtouch_addr_adder[31:12] = 20'h01000 ;  // -- 16 M, N=4
        // -------------------------------------------------
            8'b00_01_1110 :  xtouch_addr_adder[31:12] = 20'h40000 ;  // --  1 G, N=1
            8'b01_01_1110 :  xtouch_addr_adder[31:12] = 20'h80000 ;  // --  1 G, N=2
            8'b10_01_1110 :  xtouch_addr_adder[31:12] = 20'hC0000 ;  // --  1 G, N=3
            //8'b11_01_1110 :  xtouch_addr_adder[63:12] = 64'h0000_0001_0000_0 ;  // --  1 G, N=4
        // -------------------------------------------------
            //8'b00_10_0010 :  xtouch_addr_adder[63:12] = 64'h0000_0004_0000_0 ;  // -- 16 G, N=1
            //8'b01_10_0010 :  xtouch_addr_adder[63:12] = 64'h0000_0004_0000_0 ;  // -- 16 G, N=2
            //8'b10_10_0010 :  xtouch_addr_adder[63:12] = 64'h0000_0004_0000_0 ;  // -- 16 G, N=3
            //8'b11_10_0010 :  xtouch_addr_adder[63:12] = 64'h0000_0004_0000_0 ;  // -- 16 G, N=4
        // -------------------------------------------------
            default       :  xtouch_addr_adder[31:12] = 20'h00001 ;  // --  4 K, N=1; default (Needed to make case "full" to prevent inferred latches)
        // -------------------------------------------------
      endcase
    end // -- always @ *

  assign  xtouch_plus_n[31:12]  =  curr_addr[31:12] + xtouch_addr_adder[31:12];

  assign  xtouch_addr_en  =  crossed_page & xtouch_enable;
  assign  xtouch_addr_d[31:12]  =  (base_addr_q[31:12]   & ~offset_mask_q[31:12]) |
	                         (xtouch_plus_n[31:12]   &  offset_mask_q[31:12]);

  assign  xtouch_ea_q[63:0]  =  { base_addr_q[63:32], xtouch_addr_q[31:12], 12'b0 };

  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      if (reset)
        begin
            mmio_eng_enable_q                    <=  1'b0;
            mmio_eng_mmio_lat_mode_q             <=  1'b0;
            mmio_eng_mmio_lat_mode_sz_512_st_q   <=  1'b0;
            mmio_eng_mmio_lat_mode_sz_512_ld_q   <=  1'b0;
            mmio_eng_mmio_lat_extra_read_q       <=  1'b0;
	    send_interrupt_q                     <=  1'b0;
	    send_wkhstthrd_q                     <=  1'b0;
	    send_wkhstthrd_intrpt_q              <=  1'b0;
        end
      else
        begin
            mmio_eng_enable_q                    <=  mmio_eng_enable;
            mmio_eng_mmio_lat_mode_q             <=  mmio_eng_mmio_lat_mode;
            mmio_eng_mmio_lat_mode_sz_512_st_q   <=  mmio_eng_mmio_lat_mode_sz_512_st;
            mmio_eng_mmio_lat_mode_sz_512_ld_q   <=  mmio_eng_mmio_lat_mode_sz_512_ld;
            mmio_eng_mmio_lat_extra_read_q       <=  mmio_eng_mmio_lat_extra_read;
	    send_interrupt_q                     <= send_interrupt_d;
	    send_wkhstthrd_q                     <= send_wkhstthrd_d;
	    send_wkhstthrd_intrpt_q              <= send_wkhstthrd_intrpt_d;
        end


      if (main_idle_st_int)    // Could use start_capture, but then offset_addr would need another signal to initialize, or use unlatched mmio signals
        begin
          mmio_eng_type_ld_q                 <= mmio_eng_type_ld;
          mmio_eng_type_st_q                 <= mmio_eng_type_st;
	  base_addr_q[63:12]                 <= mmio_eng_base_addr[63:12];
	  offset_mask_q[31:12]               <= mmio_eng_offset_mask[31:12];
	  mmio_eng_pasid_q[9:0]              <= mmio_eng_pasid[9:0];
          step_size_256_q                    <= step_size_256_d;
        end

      use_pasid_for_actag_q                  <= use_pasid_for_actag_d;

      cmd_is_intrpt_q                        <= cmd_is_intrpt_d;
      cmd_is_wkhstthrd_q                     <= cmd_is_wkhstthrd_d;

      mmio_eng_error_intrpt_enable_q         <= mmio_eng_error_intrpt_enable;
      mmio_eng_wkhstthrd_intrpt_enable_q     <= mmio_eng_wkhstthrd_intrpt_enable;
      mmio_eng_extra_write_mode_q            <= mmio_eng_extra_write_mode;

      main_seq_q[4:0]                        <= main_seq_d[4:0];        

      offset_addr_q[31:7]                    <= offset_addr_d[31:7];

      toggle_ld_addr_bit8_q                  <= toggle_ld_addr_bit8_d;
      cpy_ld_ea_int_q[63:7]                  <= cpy_ld_ea_int_d[63:7];

      xtouch_pg_size_q[5:0]                  <= xtouch_pg_size_d[5:0];
      inc_addr_q                             <= inc_addr_d;

      if (xtouch_addr_en)
       begin
         xtouch_addr_q[31:12]                <= xtouch_addr_d[31:12];
       end

      mmio_eng_xtouch_enable_q               <= mmio_eng_xtouch_enable;
      mmio_eng_xtouch_pg_n_q[1:0]            <= mmio_eng_xtouch_pg_n[1:0];

    end // -- always @ posedge clock

endmodule
