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

module afp3_arb (

  // -- Clocks & Reset
    input                 clock
  , input                 reset

  // -- inbound controls from engine
  , input                 eng_arb_init
  , input                 eng_arb_ld_enable
  , input                 eng_arb_st_enable

  // -- inbound cmd request pulses from the engines
  , input                 eng_arb_rtry_misc_req
  , input                 eng_arb_rtry_misc_w_data
  , input                 eng_arb_rtry_st_req
  , input                 eng_arb_rtry_st_256
  , input                 eng_arb_rtry_st_128
  , input                 eng_arb_rtry_ld_req
  , input                 eng_arb_misc_req
  , input                 eng_arb_misc_w_data
  , input                 eng_arb_misc_needs_extra_write

  // -- outbound grant pulses to the engines - engines may drive bus on cycle after grant
  , output                arb_eng_rtry_misc_gnt
  , output                arb_eng_rtry_st_gnt
  , output                arb_eng_rtry_ld_gnt
  , output                arb_eng_misc_gnt
  , output                arb_eng_st_gnt
  , output                arb_eng_ld_gnt

  , output          [8:0] arb_eng_ld_tag
  , output          [8:0] arb_eng_st_tag
  , output                arb_eng_tags_idle

  // set tag input from engines
  , input         [511:0] eng_arb_set_ld_tag_avail
  , input         [511:0] eng_arb_set_st_tag_avail

  // tag fastpath
  , input                 eng_arb_ld_fastpath_valid
  , input           [8:0] eng_arb_ld_fastpath_tag
  , input                 eng_arb_st_fastpath_valid
  , input           [8:0] eng_arb_st_fastpath_tag

  // -- credit interface
  , input                 cmdo_arb_cmd_credit_ge_1
  , input                 cmdo_arb_cmd_credit_ge_2
  , input                 cmdo_arb_data_credit_ge_1
  , input                 cmdo_arb_data_credit_ge_2
  , input                 cmdo_arb_data_credit_ge_4

  , output                arb_cmdo_decr_cmd_credit
  , output                arb_cmdo_decr_data_credit_4
  , output                arb_cmdo_decr_data_credit_2
  , output                arb_cmdo_decr_data_credit_1

  // -- control and config signals
  , input                 cfg_afu_enable_afu
  , input           [1:0] mmio_arb_ldst_priority_mode
  , input           [2:0] mmio_arb_num_ld_tags
  , input           [2:0] mmio_arb_num_st_tags
  , input                 mmio_arb_type_ld
  , input                 mmio_arb_type_st
  , input           [1:0] mmio_arb_ld_size
  , input           [1:0] mmio_arb_st_size
  , input                 mmio_arb_mmio_lat_mode
  , input                 mmio_arb_mmio_lat_mode_sz_512_st
  , input                 mmio_arb_mmio_lat_mode_sz_512_ld
  , input                 mmio_arb_mmio_lat_extra_read
  , input                 mmio_arb_mmio_access
  , input                 mmio_arb_xtouch_enable
  , input                 mmio_arb_xtouch_wt4rsp_enable
  , input                 mmio_arb_fastpath_disable

  , output                arb_perf_latency_update
  , output                arb_perf_no_credits

  , output                sim_idle_arb

  );


  // --****************************************************************************
  // -- Signal declarations
  // --****************************************************************************

  wire            stg1_st_256;

  // -- MMIO Ping-Pong Latency Test
  wire            stg1_st_or_ld_req_taken;
  wire     [15:0] mmio_lat_state_sel;
  wire            mmio_lat_idle_st;
  wire            mmio_lat_read1_st;
  wire            mmio_lat_read2_st;
  wire            mmio_lat_wt4rsp_st;
  wire            mmio_lat_write1_st;
  wire            mmio_lat_write2_st;
  wire            mmio_lat_wt4mmio_st;
  wire            block_for_mmio_lat_mode;
  wire            mmio_lat_extra_read_states;
  wire     [1:0]  extra_read_req_taken;
  wire            extra_reads_complete;

  wire            stg1_ld_req;
  wire            stg1_ld_fastpath_taken;

  wire            stg1_st_req;
  wire            stg1_st_fastpath_taken;

  wire            stg1_rtry_misc_req_taken;
  wire            stg1_rtry_st_req_taken;
  wire            stg1_rtry_ld_req_taken;
  wire            stg1_misc_req_taken;
  wire            stg1_st_req_taken;
  wire            stg1_ld_req_taken;

  // -- Load Tags
  wire      [3:0] init_ld_tag_select;
  reg     [511:0] init_ld_tag_avail;
  wire    [511:0] req_clear_ld;
  wire      [8:0] stg1_ld_tag;
  wire    [511:0] set_ld_tag_avail_not_extra_read;
  wire            tag_reset;
  wire            stg1_ld_req_taken_not_extra;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            stg1_ld_req_slow;

  // -- Store Tags
  wire      [4:0] init_st_tag_select;
  reg     [511:0] init_st_tag_avail;
  wire    [511:0] req_clear_st;
  wire      [8:0] stg1_st_tag;
  wire            stg1_st_req_taken_or_fp;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            stg1_st_req_slow;

  // -- 
  wire      [6:0] stg2_grant_select;
  reg       [5:0] stg2_grant;

  wire            stg2_rtry_misc_request;
  //reg      [31:0] stg2_rtry_misc_grant;

  wire            stg2_rtry_st_request;
  //reg      [31:0] stg2_rtry_st_grant;

  wire            stg2_rtry_ld_request;
  //reg      [31:0] stg2_rtry_ld_grant;

  wire            stg2_misc_request;
  //reg      [31:0] stg2_misc_grant;

  wire            stg2_st_request;
  //reg      [31:0] stg2_st_grant;

  wire            stg2_ld_request;
  //reg      [31:0] stg2_ld_grant;

  wire            stg2_ld_no_credits;
  wire            stg2_st_no_credits;

  //wire     [31:0] rtry_st_winner_decoded;
  //wire     [31:0] st_winner_decoded;

  wire            stg1_rtry_st_winner_256;
  wire            stg1_rtry_st_winner_128;
  wire            stg1_rtry_st_winner_064;

  wire            stg1_st_winner_256;
  wire            stg1_st_winner_128;
  wire            stg1_st_winner_064;

  //wire     [31:0] rtry_misc_winner_decoded;
  //wire     [31:0] misc_winner_decoded;

  wire            stg1_rtry_misc_winner_w_data;

  wire            stg1_misc_winner_w_data;

  // --****************************************************************************
  // -- Latch Signal declarations (including enable signals)
  // --****************************************************************************

  wire            cfg_afu_enable_afu_d;
  reg             cfg_afu_enable_afu_q;
  wire      [1:0] mmio_arb_ldst_priority_mode_d;
  reg       [1:0] mmio_arb_ldst_priority_mode_q;
  wire      [2:0] mmio_arb_num_ld_tags_d;
  reg       [2:0] mmio_arb_num_ld_tags_q;
  wire      [2:0] mmio_arb_num_st_tags_d;
  reg       [2:0] mmio_arb_num_st_tags_q;
  wire            mmio_arb_mmio_lat_mode_d;
  reg             mmio_arb_mmio_lat_mode_q;
  wire            mmio_arb_mmio_lat_mode_sz_512_st_d;
  reg             mmio_arb_mmio_lat_mode_sz_512_st_q;
  wire            mmio_arb_mmio_lat_mode_sz_512_ld_d;
  reg             mmio_arb_mmio_lat_mode_sz_512_ld_q;
  wire            mmio_arb_mmio_lat_extra_read_d;
  reg             mmio_arb_mmio_lat_extra_read_q;
  //wire            mmio_arb_mmio_access_d;
  //reg             mmio_arb_mmio_access_q;

  wire            eng_arb_init_d;
  reg             eng_arb_init_q;
  wire            eng_arb_ld_enable_d;
  reg             eng_arb_ld_enable_q;
  wire            eng_arb_st_enable_d;
  reg             eng_arb_st_enable_q;
  wire            xtouch_rtry_enable_d;
  reg             xtouch_rtry_enable_q;


  wire            stg1_ld_256_d;
  reg             stg1_ld_256_q;
  wire      [1:0] stg1_st_size_d;
  reg       [1:0] stg1_st_size_q;

  reg       [6:0] mmio_lat_state_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [6:0] mmio_lat_state_q;

  wire      [1:0] extra_read_tag_avail_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [1:0] extra_read_tag_avail_q;

  reg             stg1_ld_fastpath_valid_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg1_ld_fastpath_valid_q;
  wire      [8:0] stg1_ld_fastpath_tag_d;
  reg       [8:0] stg1_ld_fastpath_tag_q;
  reg             ld_fastpath_taken_dly1_d;
  reg             ld_fastpath_taken_dly1_q;
  reg             ld_fastpath_taken_dly2_d;
  reg             ld_fastpath_taken_dly2_q;
  reg             ld_fastpath_taken_dly3_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             ld_fastpath_taken_dly3_q;

  reg             stg1_st_fastpath_valid_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg1_st_fastpath_valid_q;
  wire      [8:0] stg1_st_fastpath_tag_d;
  reg       [8:0] stg1_st_fastpath_tag_q;
  reg             st_fastpath_taken_dly1_d;
  reg             st_fastpath_taken_dly1_q;
  reg             st_fastpath_taken_dly2_d;
  reg             st_fastpath_taken_dly2_q;
  reg             st_fastpath_taken_dly3_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             st_fastpath_taken_dly3_q;

  reg             ldst_priority_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             ldst_priority_q;

  reg             stg1_rtry_misc_req_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg1_rtry_misc_req_q;
  reg             stg1_rtry_misc_w_data_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg1_rtry_misc_w_data_q;
  reg             stg1_rtry_st_req_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg1_rtry_st_req_q;
  reg             stg1_rtry_st_256_d;
  reg             stg1_rtry_st_256_q;
  reg             stg1_rtry_st_128_d;
  reg             stg1_rtry_st_128_q;
  reg             stg1_rtry_ld_req_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg1_rtry_ld_req_q;
  reg             stg1_misc_req_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg1_misc_req_q;
  reg             stg1_misc_w_data_d;
  reg             stg1_misc_w_data_q;
  reg             stg1_misc_needs_extra_write_d;
  reg             stg1_misc_needs_extra_write_q;
  reg             stg2_extra_write_req_d;
  reg             stg2_extra_write_req_q;
  //reg             stg1_st_req_d;
  //reg             stg1_st_req_q;
  //reg             stg1_st_256_d;
  //reg             stg1_st_256_q;
  //reg             stg1_st_128_d;
  //reg             stg1_st_128_q;
  //reg             stg1_ld_req_d;
  //reg             stg1_ld_req_q;
  wire    [511:0] ld_tag_avail_d;
  reg     [511:0] ld_tag_avail_q;
  wire    [511:0] st_tag_avail_d;
  reg     [511:0] st_tag_avail_q;

  wire            stg2_rtry_misc_grant_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg2_rtry_misc_grant_q;
  wire            stg2_rtry_st_grant_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg2_rtry_st_grant_q;
  wire            stg2_rtry_st_grant_256_d;
  reg             stg2_rtry_st_grant_256_q;
  wire            stg2_rtry_ld_grant_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg2_rtry_ld_grant_q;
  wire            stg2_misc_grant_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg2_misc_grant_q;
  wire            stg2_st_grant_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg2_st_grant_q;
  wire            stg2_st_grant_256_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg2_st_grant_256_q;
  wire            stg2_ld_grant_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             stg2_ld_grant_q;
  wire      [8:0] stg2_ld_tag_d;
  reg       [8:0] stg2_ld_tag_q;
  wire      [8:0] stg2_st_tag_d;
  reg       [8:0] stg2_st_tag_q;

  wire            decr_cmd_credit_d;
  reg             decr_cmd_credit_q;
  wire            decr_data_credit_4_d;
  reg             decr_data_credit_4_q;
  wire            decr_data_credit_2_d;
  reg             decr_data_credit_2_q;
  wire            decr_data_credit_1_d;
  reg             decr_data_credit_1_q;

  wire            tags_idle_d;
  reg             tags_idle_q;

  // -- ********************************************************************************************************************************
  // -- Repower latches for mode/config bits
  // -- ********************************************************************************************************************************

  assign  cfg_afu_enable_afu_d               =  cfg_afu_enable_afu;
  assign  mmio_arb_ldst_priority_mode_d[1:0] =  mmio_arb_ldst_priority_mode[1:0];
  assign  mmio_arb_num_ld_tags_d[2:0]        =  mmio_arb_num_ld_tags[2:0];
  assign  mmio_arb_num_st_tags_d[2:0]        =  mmio_arb_num_st_tags[2:0];
  assign  mmio_arb_mmio_lat_mode_d           =  mmio_arb_mmio_lat_mode;
  assign  mmio_arb_mmio_lat_mode_sz_512_st_d =  mmio_arb_mmio_lat_mode_sz_512_st;
  assign  mmio_arb_mmio_lat_mode_sz_512_ld_d =  mmio_arb_mmio_lat_mode_sz_512_ld;
  assign  mmio_arb_mmio_lat_extra_read_d     =  mmio_arb_mmio_lat_extra_read;
  //assign  mmio_arb_mmio_access_d             =  mmio_arb_mmio_access;
  assign  eng_arb_init_d                     =  eng_arb_init;
  assign  eng_arb_ld_enable_d                =  eng_arb_ld_enable;
  assign  eng_arb_st_enable_d                =  eng_arb_st_enable;
  assign  xtouch_rtry_enable_d               =  mmio_arb_xtouch_enable & mmio_arb_xtouch_wt4rsp_enable;

  assign  stg1_ld_256_d                      =  (mmio_arb_ld_size == 2'b11);
  assign  stg1_st_size_d[1:0]                =  mmio_arb_st_size[1:0];
  assign  stg1_st_256                        =  (stg1_st_size_q == 2'b11);

  // -- ********************************************************************************************************************************
  // -- MMIO Ping-Pong Latency Test Mode
  // -- ********************************************************************************************************************************
  // -- How to set up:
  // --  1) MMIO Write the WED.  This will set up:
  // --     a) base address:  MMIO latency test will write to this address (offset=0)
  // --     b) num_tags:  It is recommended to send DMA_Writes, and disable reads.  The logic will send whichever is enabled.
  // --                   num_st_tags should be at least 1, but can be bigger to avoid tags delaying the next write
  // --                   num_ld_tags should be 0, to prevent AFP from sending reads
  // --     c) st_size: 64B, 128B, or 256B.  For 512B tests, set this field to 256B and also set the sz_512 register bit(s).
  // --                   If using scorecarding for large register data, make sure to set the load size even if loads are disabled.
  // --     d) cmd_sel_st: selects between dma_w or dma_w.n
  // --     e) for extra_read mode, make sure to set ld_size and cmd_sel_ld to the desired value
  // --  2) MMIO Write to set the trigger mode to Large Data 0 register, if needed.  Default is Enable register.
  // --     MMIO Write to set MMIO latency mode, and, if needed, sz_512, use_reg_data, extra_read, & scorecard modes.
  // --     If extra read mode is set, MMIO Write to set the Extra Read address.  (For 512B, must be 512B aligned.)
  // --  3) Set the AFP Enable bit (via MMIO Write).  (Step #2 & #3 can be done at the same time.)
  // --  4) ARB will send 1 write (or read) to the base address.  (For 512B mode, two 256B writes will be sent.)
  // --     Note: The first write (or read) will occur when the Enable bit is set, regardless of trigger mode.
  // --     For extra read mode, ARB will send 1 read (two for 512B mode), wait for the response data, then
  // --     send the write(s) with the response data.
  // --  5) Upon seeing the write, the App sends an MMIO to trigger the next DMA write.
  // --     If the trigger mode is 0, the App sends an MMIO to the Enable register or Extra Read Address register.
  // --       If it wishes to change the data, it should do that before accessing the Enable register or Extra Read Address register.
  // --     If the trigger mode is 1, the App sends an MMIO to the Large Data 0 register.
  // --       If scorecarding is off and if the data is larger than 128B, it should write Large Data 0 register last.
  // --       If scorecarding is enabled, AFP will wait for all the large data register(s) to be written, based on the load size.
  // --         If load size = 128B, AFP will wait for just Data0; for 256B, Data0 & Data1; for 512B, all four data registers.
  // --  6) Upon seeing a valid MMIO, AFP will repeat steps 4 & 5, using the same base address.
  // --     The latency array will be written with a counter value for each read or write.
  // --     Performance Counters will count as normal for each write.
  // --     Repeat steps 4 & 5 for length of test.
  // --  7) STOP the test.  Preferred method:  MMIO Write to clear the enable bit.
  // --  8) Read the latency register as for other latency tests, and/or read the counters.

  assign  stg1_st_or_ld_req_taken  =  stg1_st_req_taken | stg1_ld_req_taken;

  assign  mmio_lat_state_sel[15:0]  =  { reset, mmio_arb_mmio_lat_mode_q, mmio_arb_mmio_lat_extra_read_q,
                                         stg1_ld_req_taken, extra_reads_complete, stg1_st_or_ld_req_taken,
                                         mmio_arb_mmio_access, mmio_arb_mmio_lat_mode_sz_512_st_q, mmio_arb_mmio_lat_mode_sz_512_ld_q, mmio_lat_state_q[6:0]};

  always @*
    begin
      casez ( mmio_lat_state_sel[15:0] )
        // --
        // --  reset
        // --  |mmio_arb_mmio_lat_mode_q
        // --  ||mmio_arb_mmio_lat_extra_read_q
        // --  |||
        // --  ||| stg1_ld_req_taken
        // --  ||| |extra_reads_complete
        // --  ||| ||stg1_st_or_ld_req_taken
        // --  ||| |||mmio_arb_mmio_access
        // --  ||| ||||mmio_arb_mmio_lat_mode_sz_512_st_q
        // --  ||| |||||mmio_arb_mmio_lat_mode_sz_512_ld_q
        // --  ||| |||||| mmio_lat_state_q[6:0]                   mmio_lat_state_d[6:0]
        // --  111 111||| |                                       |
        // --  543 210987 6543210                                 654_3210
        // ------------------------------------------------------------------
           16'b1??_??????_???????  :  mmio_lat_state_d[6:0] =  7'b000_0001 ;    // -- any state -> Idle
           16'b00?_??????_???????  :  mmio_lat_state_d[6:0] =  7'b000_0001 ;    // -- any state -> Idle
        // ------------------------------------------------------------------
           16'b011_??????_0000001  :  mmio_lat_state_d[6:0] =  7'b000_0010 ;    // -- Idle -> 1st Read
           16'b010_??????_0000001  :  mmio_lat_state_d[6:0] =  7'b001_0000 ;    // -- Idle -> 1st Write
        // ------------------------------------------------------------------
           16'b01?_0?????_0000010  :  mmio_lat_state_d[6:0] =  7'b000_0010 ;    // -- 1st Read -> 1st Read
           16'b01?_1????1_0000010  :  mmio_lat_state_d[6:0] =  7'b000_0100 ;    // -- 1st Read -> 2nd Read (512B)
           16'b01?_1????0_0000010  :  mmio_lat_state_d[6:0] =  7'b000_1000 ;    // -- 1st Read -> Wait for Response
        // ------------------------------------------------------------------
           16'b01?_0?????_0000100  :  mmio_lat_state_d[6:0] =  7'b000_0100 ;    // -- 2nd Read -> 2nd Read
           16'b01?_1?????_0000100  :  mmio_lat_state_d[6:0] =  7'b000_1000 ;    // -- 2nd Read -> Wait for Response
        // ------------------------------------------------------------------
           16'b01?_?0????_0001000  :  mmio_lat_state_d[6:0] =  7'b000_1000 ;    // -- Wait for Response -> Wait for Response
           16'b01?_?1????_0001000  :  mmio_lat_state_d[6:0] =  7'b001_0000 ;    // -- Wait for Response -> 1st Write
        // ------------------------------------------------------------------
           16'b01?_??0???_0010000  :  mmio_lat_state_d[6:0] =  7'b001_0000 ;    // -- 1st Write -> 1st Write
           16'b01?_??1?1?_0010000  :  mmio_lat_state_d[6:0] =  7'b010_0000 ;    // -- 1st Write -> 2nd Write (512B)
           16'b01?_??1?0?_0010000  :  mmio_lat_state_d[6:0] =  7'b100_0000 ;    // -- 1st Write -> Wait for MMIO
        // ------------------------------------------------------------------
           16'b01?_??0???_0100000  :  mmio_lat_state_d[6:0] =  7'b010_0000 ;    // -- 2nd Write -> 2nd Write
           16'b01?_??1???_0100000  :  mmio_lat_state_d[6:0] =  7'b100_0000 ;    // -- 2nd Write -> Wait for MMIO
        // ------------------------------------------------------------------
           16'b01?_???0??_1000000  :  mmio_lat_state_d[6:0] =  7'b100_0000 ;    // -- Wait for MMIO -> Wait for MMIO
           16'b011_???1??_1000000  :  mmio_lat_state_d[6:0] =  7'b000_0010 ;    // -- Wait for MMIO -> 1st Read
           16'b010_???1??_1000000  :  mmio_lat_state_d[6:0] =  7'b001_0000 ;    // -- Wait for MMIO -> 1st Write
        // ------------------------------------------------------------------
           default                 :  mmio_lat_state_d[6:0] =  7'b000_0001 ;    // -- default -> Idle
      endcase
    end  // -- always @*

  assign  mmio_lat_idle_st    =  mmio_lat_state_q[0];
  assign  mmio_lat_read1_st   =  mmio_lat_state_q[1];
  assign  mmio_lat_read2_st   =  mmio_lat_state_q[2];
  assign  mmio_lat_wt4rsp_st  =  mmio_lat_state_q[3];
  assign  mmio_lat_write1_st  =  mmio_lat_state_q[4];
  assign  mmio_lat_write2_st  =  mmio_lat_state_q[5];
  assign  mmio_lat_wt4mmio_st =  mmio_lat_state_q[6];

  assign  block_for_mmio_lat_mode = mmio_lat_read1_st | mmio_lat_read2_st | mmio_lat_wt4rsp_st | mmio_lat_wt4mmio_st;
  assign  mmio_lat_extra_read_states = mmio_lat_read1_st | mmio_lat_read2_st;

  //assign arb_perf_mmio_lat_update  =  mmio_arb_mmio_lat_mode_q & (stg1_st_req_taken | stg1_ld_req_taken);  // Record latency when command is sent
  assign arb_perf_latency_update  =  stg1_st_req_taken | stg1_ld_req_taken;  // Record latency when command is sent

  // -- ********************************************************************************************************************************
  // -- Extra Read Load Tags
  // -- ********************************************************************************************************************************
  // -- For MMIO Ping-Pong extra reads, always use load tag 0 and 2 (because of 256B reads), and track separately from normal loads.
  // -- This makes it easier to know which address the response data is for.
  assign  extra_read_req_taken[0]  =  stg1_ld_req_taken & mmio_lat_read1_st;
  assign  extra_read_req_taken[1]  =  stg1_ld_req_taken & mmio_lat_read2_st;

  assign  extra_read_tag_avail_d[1:0] =  eng_arb_init_q  ? 2'b11  :         // IF init, ELSE :
		 ( (extra_read_tag_avail_q[1:0] | {eng_arb_set_ld_tag_avail[2], eng_arb_set_ld_tag_avail[0]} ) &
                          ~(extra_read_req_taken[1:0]) & 
		          ~( { req_clear_ld[2], req_clear_ld[0] } ));   // also clear tags on normal loads, in case normal test was run before enabling mmio_lat mode

  assign  extra_reads_complete = &(extra_read_tag_avail_q[1:0]);  // Both tags available

  // -- ********************************************************************************************************************************
  // -- Fastpath Logic
  // -- ********************************************************************************************************************************
  // -- fastpath_valid arrives same cycle as set_*_tag_avail.  We do not know in that cycle whether ld/st req will be granted.
  // -- To avoid re-decoding the tag to clear it, wait 3 cycles for tag to show up on stg1_*_req_q, and use the normal
  // -- clear/taken logic.
  assign  stg1_ld_fastpath_tag_d[8:0]  =  eng_arb_ld_fastpath_tag[8:0];

  assign  stg1_ld_req  =  (stg1_ld_req_slow && ~ld_fastpath_taken_dly3_q) || (stg1_ld_fastpath_valid_q);

  assign  stg1_ld_fastpath_taken  =  stg1_ld_req_taken & ~(stg1_ld_req_slow && ~ld_fastpath_taken_dly3_q) & ~mmio_lat_read1_st & ~mmio_lat_read2_st;


  assign  stg1_st_fastpath_tag_d[8:0]  =  eng_arb_st_fastpath_tag[8:0];

  assign  stg1_st_req  = (stg1_st_req_slow && ~st_fastpath_taken_dly3_q) || (stg1_st_fastpath_valid_q);

  assign  stg1_st_fastpath_taken  =  stg1_st_req_taken & ~(stg1_st_req_slow && ~st_fastpath_taken_dly3_q);

  always @ *
    begin
      if ( ~reset )
        begin
          stg1_ld_fastpath_valid_d  =  eng_arb_ld_fastpath_valid && ~mmio_arb_fastpath_disable &&
                                               (mmio_arb_num_ld_tags_q != 3'b000);   // Don't use fastpath if resp caused by Extra Read
          ld_fastpath_taken_dly1_d  =  stg1_ld_fastpath_taken & ~reset;
          ld_fastpath_taken_dly2_d  =  ld_fastpath_taken_dly1_q;
          ld_fastpath_taken_dly3_d  =  ld_fastpath_taken_dly2_q;

          stg1_st_fastpath_valid_d  =  eng_arb_st_fastpath_valid && ~mmio_arb_fastpath_disable;
          st_fastpath_taken_dly1_d  =  stg1_st_fastpath_taken;
          st_fastpath_taken_dly2_d  =  st_fastpath_taken_dly1_q;
          st_fastpath_taken_dly3_d  =  st_fastpath_taken_dly2_q;
        end
      else
        begin
          stg1_ld_fastpath_valid_d  =  1'b0;
          ld_fastpath_taken_dly1_d  =  1'b0;
          ld_fastpath_taken_dly2_d  =  1'b0;
          ld_fastpath_taken_dly3_d  =  1'b0;

          stg1_st_fastpath_valid_d  =  1'b0;
          st_fastpath_taken_dly1_d  =  1'b0;
          st_fastpath_taken_dly2_d  =  1'b0;
          st_fastpath_taken_dly3_d  =  1'b0;
        end

    end  // -- always @*


  // -- ********************************************************************************************************************************
  // -- Maintain latches of valid requestors
  // -- ********************************************************************************************************************************

  // -- new request or previous request that is not being granted on this cycle - clear all latches on reset
  always @ *
    begin
      if ( ~reset )
        begin
          stg1_rtry_misc_req_d    =  ( eng_arb_rtry_misc_req    | ( stg1_rtry_misc_req_q    & ~stg1_rtry_misc_req_taken ));
          stg1_rtry_misc_w_data_d =  ( eng_arb_rtry_misc_w_data | ( stg1_rtry_misc_w_data_q & ~stg1_rtry_misc_req_taken ));
          stg1_rtry_st_req_d      =  ( eng_arb_rtry_st_req      | ( stg1_rtry_st_req_q      & ~stg1_rtry_st_req_taken   ));
          stg1_rtry_st_256_d      =  ( eng_arb_rtry_st_256      | ( stg1_rtry_st_256_q      & ~stg1_rtry_st_req_taken   ));
          stg1_rtry_st_128_d      =  ( eng_arb_rtry_st_128      | ( stg1_rtry_st_128_q      & ~stg1_rtry_st_req_taken   ));
          stg1_rtry_ld_req_d      =  ( eng_arb_rtry_ld_req      | ( stg1_rtry_ld_req_q      & ~stg1_rtry_ld_req_taken   ));
          stg1_misc_req_d         =  ( eng_arb_misc_req         | ( stg1_misc_req_q         & ~stg1_misc_req_taken      ));
          stg1_misc_w_data_d      =  ( eng_arb_misc_w_data      | ( stg1_misc_w_data_q      & ~stg1_misc_req_taken      ));
          stg1_misc_needs_extra_write_d =  ( eng_arb_misc_needs_extra_write | ( stg1_misc_needs_extra_write_q  & ~stg1_misc_req_taken ));
          // Note: Extra Write mode will send a load or a store, whichever has tags.  Typical usage is to only give tags to stores.
          // Extra Write is sent immediately after a wkhstthrd or interrupt, when mode is enabled
          stg2_extra_write_req_d  =  ( (stg1_misc_req_taken & stg1_misc_needs_extra_write_q) |
                                                                  (stg2_extra_write_req_q  & ~(stg1_ld_req_taken | stg1_st_req_taken)));
          //stg1_st_req_d           =  ( eng_arb_st_req           | ( stg1_st_req_q           & ~stg1_st_req_taken        ));
          //stg1_st_256_d           =  ( eng_arb_st_256           | ( stg1_st_256_q           & ~stg1_st_req_taken        ));
          //stg1_st_128_d           =  ( eng_arb_st_128           | ( stg1_st_128_q           & ~stg1_st_req_taken        ));
          //stg1_ld_req_d           =  ( eng_arb_ld_req           | ( stg1_ld_req_q           & ~stg1_ld_req_taken        ));
        end
      else
        begin
          stg1_rtry_misc_req_d    =  1'b0;
          stg1_rtry_misc_w_data_d =  1'b0;
          stg1_rtry_st_req_d      =  1'b0;
          stg1_rtry_st_256_d      =  1'b0;
          stg1_rtry_st_128_d      =  1'b0;
          stg1_rtry_ld_req_d      =  1'b0;
          stg1_misc_req_d         =  1'b0;
          stg1_misc_w_data_d      =  1'b0;
          stg1_misc_needs_extra_write_d  =  1'b0;
          stg2_extra_write_req_d  =  1'b0;
          //stg1_st_req_d           =  1'b0;
          //stg1_st_256_d           =  1'b0;
          //stg1_st_128_d           =  1'b0;
          //stg1_ld_req_d           =  1'b0;
        end

    end  // -- always @*


  // -- ********************************************************************************************************************************
  // -- 1st Round of arbitration from the engines for each type (ld, str, misc, rtry)
  // -- ********************************************************************************************************************************
  // -- Reset tags to all available
  // -- Clear when command send granted
  // -- Set on response

  // -- ********************************************************************************************************************************
  // -- Load Tags
  // -- ********************************************************************************************************************************
  assign  init_ld_tag_select[3:0] = { stg1_ld_256_q, mmio_arb_num_ld_tags_q[2:0]};

  // ??? TODO - Need to verify that these init in a way that we get back-to-back tag selection
  // If 256B, only use 256 tags, leaving right-most encode bit for 128B retries
  // Make sure not to use any odd-numbered tags for 256B mode, so we can use those for 128B retries
  always @*
    begin
      casez ( init_ld_tag_select[3:0] )
        // --
        // --  stg1_ld_256_q
        // --  |mmio_arb_num_ld_tags_q[2:0]         init_ld_tag_avail
        // --  ||                                   |
        // --  3210                                 511:0
        // ----------------------------------------------
            4'b?000  :  init_ld_tag_avail[511:0] =  512'b0;                           //  0 tags
            4'b?001  :  init_ld_tag_avail[511:0] =  {511'b0, 1'b1};                   //  1 tag
            4'b?010  :  init_ld_tag_avail[511:0] =  {1'b0, 1'b1, 509'b0, 1'b1};       //  2 tags
	    4'b?011  :  init_ld_tag_avail[511:0] =
 	     {1'b0, 1'b1, 126'b0, 1'b0, 1'b1, 126'b0, 127'b0, 1'b1, 127'b0, 1'b1};    //  4 tags
        // ----------------------------------------------
            4'b?100  :  init_ld_tag_avail[511:0] =  {  8{1'b0, 1'b1, 61'b0, 1'b1} };  //  16 tags
            4'b?101  :  init_ld_tag_avail[511:0] =  { 32{1'b0, 1'b1, 13'b0, 1'b1} };  //  64 tags
	    4'b?110  :  init_ld_tag_avail[511:0] =  { 256{2'b01} };                   // 256 tags
            4'b1111  :  init_ld_tag_avail[511:0] =  { 256{2'b01} };                   // 256 tags, forced due to 256B ops
            4'b0111  :  init_ld_tag_avail[511:0] =  { 512{1'b1} };                    // 512 tags
        // ----------------------------------------------
            default  :  init_ld_tag_avail[511:0] =  { 512{1'b1} };                    // 512 tags
        // ----------------------------------------------
      endcase
    end  // -- always @*

  assign set_ld_tag_avail_not_extra_read[511:3] = eng_arb_set_ld_tag_avail[511:3];
  assign set_ld_tag_avail_not_extra_read[2:0] = eng_arb_set_ld_tag_avail[2:0] & init_ld_tag_avail[2:0];  // Don't set if not enabled (set is due to mmio_lat extra_read)

  assign ld_tag_avail_d[511:0] =  eng_arb_init_q  ? init_ld_tag_avail :         // IF init
	      ((ld_tag_avail_q | set_ld_tag_avail_not_extra_read) & ~(req_clear_ld));  // ELSE

  assign tag_reset =  reset |  eng_arb_init_q;

  assign stg1_ld_req_taken_not_extra =  (stg1_ld_req_taken | ld_fastpath_taken_dly3_q) & ~mmio_lat_extra_read_states;

  mcp3_arb512  arb_ld_tags
    (
      .clock                        ( clock ),
      .reset                        ( tag_reset ),
      // -- input request bus
      .req_taken                    ( stg1_ld_req_taken_not_extra ),
      .req_bus                      ( ld_tag_avail_q[511:0] ),
      .req_clear                    ( req_clear_ld[511:0] ),
      // -- encode output select
      .final_winner                 ( stg1_ld_tag[8:0] ),
      .final_valid                  ( stg1_ld_req_slow )
    );

  // -- ********************************************************************************************************************************
  // -- Store Tags
  // -- ********************************************************************************************************************************
  assign  init_st_tag_select[4:0] = { xtouch_rtry_enable_q, stg1_st_256, mmio_arb_num_st_tags_q[2:0]};

  // ??? TODO - Need to verify that these init in a way that we get back-to-back tag selection
  // If 256B, only use 256 tags, leaving right-most encode bit for 128B retries
  // Make sure not to use any odd-numbered tags for 256B mode, so we can use those for 128B retries
  // If xlate_touch with wt4rsp is enabled, leave at least one tag unused to avoid possibly overflowing retry queue
  always @*
    begin
      casez ( init_st_tag_select[4:0] )
        // --
        // --  xtouch_rtry_enable_q
        // --  |stg1_st_256
        // --  || mmio_arb_num_st_tags_q[2:0]         init_st_tag_avail
        // --  || |                                   |
        // --  43_210                                 511:0
        // ------------------------------------------------------------
            5'b??_000  :  init_st_tag_avail[511:0] =  512'b0;                           //  0 tags
            5'b??_001  :  init_st_tag_avail[511:0] =  {511'b0, 1'b1};                   //  1 tag
            5'b??_010  :  init_st_tag_avail[511:0] =  {1'b0, 1'b1, 509'b0, 1'b1};       //  2 tags
            5'b??_011  :  init_st_tag_avail[511:0] =
             {1'b0, 1'b1, 126'b0, 1'b0, 1'b1, 126'b0, 127'b0, 1'b1, 127'b0, 1'b1};      //  4 tags
        // ------------------------------------------------------------
            5'b??_100  :  init_st_tag_avail[511:0] =  {  8{1'b0, 1'b1, 61'b0, 1'b1} };  //  16 tags
            5'b??_101  :  init_st_tag_avail[511:0] =  { 32{1'b0, 1'b1, 13'b0, 1'b1} };  //  64 tags
            5'b11_110  :  init_st_tag_avail[511:0] =  { 2'b00, { 255{2'b01} } };        // 255 tags
            5'b10_110  :  init_st_tag_avail[511:0] =  { 256{2'b01} };                   // 256 tags
            5'b0?_110  :  init_st_tag_avail[511:0] =  { 256{2'b01} };                   // 256 tags
            5'b11_111  :  init_st_tag_avail[511:0] =  { 2'b00, { 255{2'b01} } };        // 255 tags, forced due to 256B ops
            5'b01_111  :  init_st_tag_avail[511:0] =  { 256{2'b01} };                   // 256 tags, forced due to 256B ops
            5'b10_111  :  init_st_tag_avail[511:0] =  { 1'b0, { 511{1'b1} } };          // 511 tags
            5'b00_111  :  init_st_tag_avail[511:0] =  { 512{1'b1} };                    // 512 tags
        // ------------------------------------------------------------
            default    :  init_st_tag_avail[511:0] =  { 512{1'b1} };                    // 512 tags
        // ------------------------------------------------------------
      endcase
    end  // -- always @*

  assign st_tag_avail_d[511:0] =  eng_arb_init_q  ? init_st_tag_avail :
	      ((st_tag_avail_q | eng_arb_set_st_tag_avail) & ~(req_clear_st));

  assign stg1_st_req_taken_or_fp  =  stg1_st_req_taken | st_fastpath_taken_dly3_q;

  mcp3_arb512  arb_st_tags
    (
      .clock                        ( clock ),
      .reset                        ( tag_reset ),
      // -- input request bus
      .req_taken                    ( stg1_st_req_taken_or_fp ),
      .req_bus                      ( st_tag_avail_q[511:0] ),
      .req_clear                    ( req_clear_st[511:0] ),
      // -- encode output select
      .final_winner                 ( stg1_st_tag[8:0] ),
      .final_valid                  ( stg1_st_req_slow )
    );

  // -- ********************************************************************************************************************************
  // -- For Stores, determine if the winner is for a 256B store op
  // -- ********************************************************************************************************************************

  // -- Because 256B will require 2 transfers of 128B each, need to give grant to the engine to drive in same manner, but need to
  // -- defer asserting taken to allow the engine to drive for 2 clocks.
  // -- Cannot used the decoded winner from arbiter because it is gated with "taken"


  assign  stg1_rtry_st_winner_256 =  ( | ( stg1_rtry_st_req_q & stg1_rtry_st_256_q ));
  assign  stg1_rtry_st_winner_128 =  ( | ( stg1_rtry_st_req_q & stg1_rtry_st_128_q ));
  assign  stg1_rtry_st_winner_064 =  ( stg1_rtry_st_req_q && 
                                      ~stg1_rtry_st_winner_256 &&
                                      ~stg1_rtry_st_winner_128 );


  assign  stg1_st_winner_256 =  ( stg1_st_req && (stg1_st_size_q[1:0] == 2'b11 ));
  assign  stg1_st_winner_128 =  ( stg1_st_req && (stg1_st_size_q[1:0] == 2'b10 ));
  assign  stg1_st_winner_064 =  ( stg1_st_req && (stg1_st_size_q[1]   == 1'b0  ));   // 01: 64B, 00: shouldn't be set, treat as 64B


  // -- ********************************************************************************************************************************
  // -- For Interrupts, determine if the winner is for an interrupt w/ data
  // -- ********************************************************************************************************************************

  assign  stg1_rtry_misc_winner_w_data =  ( | ( stg1_rtry_misc_req_q & stg1_rtry_misc_w_data_q ));

  assign  stg1_misc_winner_w_data =  ( | ( stg1_misc_req_q & stg1_misc_w_data_q ));


  // -- ********************************************************************************************************************************
  // -- 2nd Round of arbitration to choose between retry queue and winners from eng arb
  // -- ********************************************************************************************************************************

  // -- if winner from stage 1, it becomes request to stage 2
  assign  stg2_rtry_misc_request =  cfg_afu_enable_afu_q &&
                                  ( stg1_rtry_misc_req_q && cmdo_arb_cmd_credit_ge_1 ) &&
                                  (~stg1_rtry_misc_winner_w_data ||
                                  ( stg1_rtry_misc_winner_w_data && cmdo_arb_data_credit_ge_1 && ~( stg2_rtry_st_grant_256_q || stg2_st_grant_256_q )));

  assign  stg2_rtry_st_request   =  cfg_afu_enable_afu_q && ~( stg2_rtry_st_grant_256_q || stg2_st_grant_256_q ) &&  // -- prev store winner needs data bus for 2 cycles, so blk request
                                  ( stg1_rtry_st_req_q && cmdo_arb_cmd_credit_ge_1) &&
                                 (( stg1_rtry_st_winner_256   && cmdo_arb_data_credit_ge_4) ||
                                  ( stg1_rtry_st_winner_128   && cmdo_arb_data_credit_ge_2) ||
                                  ( stg1_rtry_st_winner_064   && cmdo_arb_data_credit_ge_1));

  assign  stg2_rtry_ld_request   =  cfg_afu_enable_afu_q && ( stg1_rtry_ld_req_q && cmdo_arb_cmd_credit_ge_1 );

  assign  stg2_misc_request      =  cfg_afu_enable_afu_q &&
                                  ( stg1_misc_req_q && cmdo_arb_cmd_credit_ge_1 ) &&
                                  (~stg1_misc_winner_w_data ||
                                   ( stg1_misc_winner_w_data && cmdo_arb_data_credit_ge_1 && ~( stg2_rtry_st_grant_256_q || stg2_st_grant_256_q ))) &&
                                  (~stg1_misc_needs_extra_write_q ||
                                     (cmdo_arb_cmd_credit_ge_2 &&  // Must have 2 cmd credits if sending write after interrupt/wkhstthrd
                                       (stg1_ld_req_slow ||           //   And load/store tag for "extra write"; don't use fastpath
                                        (stg1_st_req_slow && cmdo_arb_data_credit_ge_1))) );  // Technically, should check data credits based on size, but it is unlikely that we will run out of data credits before command credits, since we only send one store per wkhstthrd/interrupt
  assign  stg2_st_request        =  cfg_afu_enable_afu_q && (eng_arb_st_enable_q || stg2_extra_write_req_q) &&
                                   ~block_for_mmio_lat_mode &&
                                 ~( stg2_rtry_st_grant_256_q || stg2_st_grant_256_q ) &&  // -- prev store winner needs data bus for 2 cycles, so blk request
                                  ( stg1_st_req && cmdo_arb_cmd_credit_ge_1) &&
                                  (( stg1_st_winner_256   && cmdo_arb_data_credit_ge_4) ||
                                   ( stg1_st_winner_128   && cmdo_arb_data_credit_ge_2) ||
                                   ( stg1_st_winner_064   && cmdo_arb_data_credit_ge_1));

  assign  stg2_ld_request        =  cfg_afu_enable_afu_q && (eng_arb_ld_enable_q || stg2_extra_write_req_q) &&
                                 ( ((mmio_lat_idle_st || ~mmio_arb_mmio_lat_extra_read_q) &&
				     stg1_ld_req && cmdo_arb_cmd_credit_ge_1 && ~block_for_mmio_lat_mode)  ||
                                   ( mmio_lat_read1_st && extra_read_tag_avail_q[0] && cmdo_arb_cmd_credit_ge_1) ||
                                   ( mmio_lat_read2_st && extra_read_tag_avail_q[1] && cmdo_arb_cmd_credit_ge_1) );


  // Determine if request was blocked due to lack of credits
  assign  stg2_st_no_credits     =  cfg_afu_enable_afu_q && eng_arb_st_enable_q &&
                                   ~block_for_mmio_lat_mode &&
                                 ~( stg2_rtry_st_grant_256_q || stg2_st_grant_256_q ) &&  // -- prev store winner needs data bus for 2 cycles, so blk request
                                    stg1_st_req &&
                                 ~stg2_st_request;

  assign  stg2_ld_no_credits     =  cfg_afu_enable_afu_q && eng_arb_ld_enable_q && ~block_for_mmio_lat_mode &&
                                    stg1_ld_req && ~cmdo_arb_cmd_credit_ge_1 ; 

  assign  arb_perf_no_credits    = stg2_ld_no_credits || stg2_st_no_credits;

  // -- determine whether stores or load will have higher priority
  always @*
    begin
      if ( reset )
        ldst_priority_d = 1'b0;
      else
        begin
         if      ( mmio_arb_ldst_priority_mode_q[1:0] == 2'b10 )  // -- fixed priority  loads have priority over stores
           ldst_priority_d = 1'b1;
         else if ( mmio_arb_ldst_priority_mode_q[1:0] == 2'b01 )  // -- fixed priority stores have priority over loads
           ldst_priority_d = 1'b0;
         else                                                     // -- priority toggles
           begin
             if ( stg2_ld_grant_d || stg2_rtry_ld_grant_d )       // -- priority toggles to stores when ld taken
               ldst_priority_d = 1'b0;                
             else if ( stg2_st_grant_d || stg2_rtry_st_grant_d )  // -- priority toggles to loads when st taken
               ldst_priority_d = 1'b1;                
             else                                                 // -- Hold current priority when no ld or st taken
               ldst_priority_d = ldst_priority_q;
          end
        end
    end  // -- always @*


  // -- select final grant
  assign  stg2_grant_select[6:0] = { ldst_priority_q, stg2_rtry_misc_request, stg2_rtry_st_request, stg2_rtry_ld_request, stg2_misc_request, stg2_st_request, stg2_ld_request };
 
  always @*
    begin
      casez ( stg2_grant_select[6:0] )
        // --
        // --  ldst_priority_q
        // --  | stg2_rtry_misc_request           stg2_rtry_misc_grant_d
        // --  | |stg2_rtry_st_request            |stg2_rtry_st_grant_d
        // --  | ||stg2_rtry_ld_request           ||stg2_rtry_ld_grant_d
        // --  | |||stg2_misc_request             |||stg2_misc_grant_d
        // --  | ||||stg2_st_request              ||||stg2_st_grant_d
        // --  | |||||stg2_ld_request             |||||stg2_ld_grant_d
        // --  | ||||||                           ||||||
        // --  6 543210                           543210
        // ----------------------------------------------
            7'b?_1?????  :  stg2_grant[5:0] =  6'b100000;
        // ----------------------------------------------
            7'b0_01????  :  stg2_grant[5:0] =  6'b010000;
            7'b1_010???  :  stg2_grant[5:0] =  6'b010000;
        // ----------------------------------------------
            7'b0_001???  :  stg2_grant[5:0] =  6'b001000;
            7'b1_0?1???  :  stg2_grant[5:0] =  6'b001000;
        // ----------------------------------------------
            7'b?_0001??  :  stg2_grant[5:0] =  6'b000100;
        // ----------------------------------------------
            7'b0_00001?  :  stg2_grant[5:0] =  6'b000010;
            7'b1_000010  :  stg2_grant[5:0] =  6'b000010;
        // ----------------------------------------------
            7'b0_000001  :  stg2_grant[5:0] =  6'b000001;
            7'b1_0000?1  :  stg2_grant[5:0] =  6'b000001;
        // ----------------------------------------------
            default      :  stg2_grant[5:0] =  6'b000000;
        // ----------------------------------------------
      endcase
    end  // -- always @*

  // -- Outputs
  assign  stg2_rtry_misc_grant_d =  stg2_grant[5];
  assign  stg2_rtry_st_grant_d   =  stg2_grant[4];
  assign  stg2_rtry_ld_grant_d   =  stg2_grant[3];
  assign  stg2_misc_grant_d      =  stg2_grant[2];
  assign  stg2_st_grant_d        =  stg2_grant[1];
  assign  stg2_ld_grant_d        =  stg2_grant[0];

  // -- Carry 256B indication into cycle where latched grant is active
  // --   This is to be used in blocking subsequent store requests for 1 cycle (other requestors having no store data may drive their cmd)
  assign  stg2_rtry_st_grant_256_d =  ( stg2_rtry_st_grant_d && stg1_rtry_st_winner_256 );
  assign  stg2_st_grant_256_d      =  ( stg2_st_grant_d && stg1_st_winner_256 );

  // -- Carry tags into cycle of the latched grant
  assign  stg2_ld_tag_d[8:0]       =  mmio_lat_read1_st ? 9'h00 :
                                      mmio_lat_read2_st ? 9'h02 :
                                 stg1_ld_fastpath_taken ? stg1_ld_fastpath_tag_q[8:0] :
                                                          stg1_ld_tag[8:0];

  assign  stg2_st_tag_d[8:0]       =  stg1_st_fastpath_taken ? stg1_st_fastpath_tag_q[8:0] :
                                                               stg1_st_tag[8:0];

  // -- feedback the engine grants from stage 2 to the stage 1 arbiters so that they can clear the corresponding request latch
  assign  stg1_rtry_misc_req_taken =  stg2_rtry_misc_grant_d;
  assign  stg1_rtry_st_req_taken   =  stg2_rtry_st_grant_d;
  assign  stg1_rtry_ld_req_taken   =  stg2_rtry_ld_grant_d;
  assign  stg1_misc_req_taken      =  stg2_misc_grant_d;
  assign  stg1_st_req_taken        =  stg2_st_grant_d;
  assign  stg1_ld_req_taken        =  stg2_ld_grant_d;

  assign  arb_eng_rtry_misc_gnt =  stg2_rtry_misc_grant_q;
  assign  arb_eng_rtry_st_gnt   =  stg2_rtry_st_grant_q;
  assign  arb_eng_rtry_ld_gnt   =  stg2_rtry_ld_grant_q;
  assign  arb_eng_misc_gnt      =  stg2_misc_grant_q;
  assign  arb_eng_st_gnt        =  stg2_st_grant_q;
  assign  arb_eng_ld_gnt        =  stg2_ld_grant_q;

  assign  arb_eng_ld_tag[8:0]   =  stg2_ld_tag_q[8:0];
  assign  arb_eng_st_tag[8:0]   =  stg2_st_tag_q[8:0];

  // -- ********************************************************************************************************************************
  // -- Credit management
  // -- ********************************************************************************************************************************

  assign   decr_cmd_credit_d =  stg2_rtry_misc_grant_d ||
                                stg2_rtry_st_grant_d ||
                                stg2_rtry_ld_grant_d ||
                                stg2_misc_grant_d    ||
                                stg2_st_grant_d      ||
                                stg2_ld_grant_d;
 
  assign   decr_data_credit_4_d =  ((   stg2_rtry_st_grant_d &&   stg1_rtry_st_winner_256    ) || (   stg2_st_grant_d &&   stg1_st_winner_256    ));
  assign   decr_data_credit_2_d =  ((   stg2_rtry_st_grant_d &&   stg1_rtry_st_winner_128    ) || (   stg2_st_grant_d &&   stg1_st_winner_128    ));
  assign   decr_data_credit_1_d =  ((   stg2_rtry_st_grant_d &&   stg1_rtry_st_winner_064    ) || (   stg2_st_grant_d &&   stg1_st_winner_064    )) ||
                                   (( stg2_rtry_misc_grant_d && stg1_rtry_misc_winner_w_data ) || ( stg2_misc_grant_d && stg1_misc_winner_w_data ));

  assign   arb_cmdo_decr_cmd_credit =  decr_cmd_credit_q;

  assign   arb_cmdo_decr_data_credit_4 =  decr_data_credit_4_q;
  assign   arb_cmdo_decr_data_credit_2 =  decr_data_credit_2_q;
  assign   arb_cmdo_decr_data_credit_1 =  decr_data_credit_1_q;


  // -- ********************************************************************************************************************************
  // -- Sim Idle
  // -- ********************************************************************************************************************************
  assign  tags_idle_d  =  ( st_tag_avail_q[511:0]  == init_st_tag_avail[511:0]) &&
                          ( ld_tag_avail_q[511:0]  == init_ld_tag_avail[511:0]) &&
                          ( extra_read_tag_avail_q[1:0]  ==  2'b11 );

  assign  arb_eng_tags_idle  =  tags_idle_q;

  assign  sim_idle_arb =  ( stg1_rtry_misc_req_q   == 1'b0 ) &&  
                          ( stg1_rtry_st_req_q     == 1'b0 ) &&  
                          ( stg1_rtry_ld_req_q     == 1'b0 ) &&
                          ( stg1_misc_req_q        == 1'b0 ) &&
                          ( tags_idle_q                    ) &&
                          ( stg2_rtry_misc_grant_q == 1'b0 ) &&
                          ( stg2_rtry_st_grant_q   == 1'b0 ) &&
                          ( stg2_rtry_ld_grant_q   == 1'b0 ) &&
                          ( stg2_misc_grant_q      == 1'b0 ) &&
                          ( stg2_st_grant_q        == 1'b0 ) &&
                          ( stg2_ld_grant_q        == 1'b0 );


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin
      cfg_afu_enable_afu_q                <= cfg_afu_enable_afu_d;
      mmio_arb_ldst_priority_mode_q[1:0]  <= mmio_arb_ldst_priority_mode_d[1:0];
      mmio_arb_num_ld_tags_q[2:0]         <= mmio_arb_num_ld_tags_d[2:0];
      mmio_arb_num_st_tags_q[2:0]         <= mmio_arb_num_st_tags_d[2:0];
      mmio_arb_mmio_lat_mode_q            <= mmio_arb_mmio_lat_mode_d;
      mmio_arb_mmio_lat_mode_sz_512_st_q  <= mmio_arb_mmio_lat_mode_sz_512_st_d;
      mmio_arb_mmio_lat_mode_sz_512_ld_q  <= mmio_arb_mmio_lat_mode_sz_512_ld_d;
      mmio_arb_mmio_lat_extra_read_q      <= mmio_arb_mmio_lat_extra_read_d;
      //mmio_arb_mmio_access_q              <= mmio_arb_mmio_access_d;
      eng_arb_init_q                      <= eng_arb_init_d;
      eng_arb_ld_enable_q                 <= eng_arb_ld_enable_d;
      eng_arb_st_enable_q                 <= eng_arb_st_enable_d;
      xtouch_rtry_enable_q                <= xtouch_rtry_enable_d;
      stg1_ld_256_q                       <= stg1_ld_256_d;
      stg1_st_size_q[1:0]                 <= stg1_st_size_d[1:0];
      mmio_lat_state_q[6:0]               <= mmio_lat_state_d[6:0];
      extra_read_tag_avail_q[1:0]         <= extra_read_tag_avail_d[1:0];
      stg1_ld_fastpath_valid_q            <= stg1_ld_fastpath_valid_d;
      stg1_ld_fastpath_tag_q[8:0]         <= stg1_ld_fastpath_tag_d[8:0];
      ld_fastpath_taken_dly1_q            <= ld_fastpath_taken_dly1_d;
      ld_fastpath_taken_dly2_q            <= ld_fastpath_taken_dly2_d;
      ld_fastpath_taken_dly3_q            <= ld_fastpath_taken_dly3_d;
      stg1_st_fastpath_valid_q            <= stg1_st_fastpath_valid_d;
      stg1_st_fastpath_tag_q[8:0]         <= stg1_st_fastpath_tag_d[8:0];
      st_fastpath_taken_dly1_q            <= st_fastpath_taken_dly1_d;
      st_fastpath_taken_dly2_q            <= st_fastpath_taken_dly2_d;
      st_fastpath_taken_dly3_q            <= st_fastpath_taken_dly3_d;
      ldst_priority_q                     <= ldst_priority_d;
      stg1_rtry_misc_req_q                <= stg1_rtry_misc_req_d;
      stg1_rtry_misc_w_data_q             <= stg1_rtry_misc_w_data_d;
      stg1_rtry_st_req_q                  <= stg1_rtry_st_req_d;
      stg1_rtry_st_256_q                  <= stg1_rtry_st_256_d;
      stg1_rtry_st_128_q                  <= stg1_rtry_st_128_d;
      stg1_rtry_ld_req_q                  <= stg1_rtry_ld_req_d;
      stg1_misc_req_q                     <= stg1_misc_req_d;
      stg1_misc_w_data_q                  <= stg1_misc_w_data_d;
      stg1_misc_needs_extra_write_q       <= stg1_misc_needs_extra_write_d;
      stg2_extra_write_req_q              <= stg2_extra_write_req_d;
      //stg1_st_req_q                       <= stg1_st_req_d;
      //stg1_st_256_q                       <= stg1_st_256_d;
      //stg1_st_128_q                       <= stg1_st_128_d;
      //stg1_ld_req_q                       <= stg1_ld_req_d;
      ld_tag_avail_q[511:0]               <= ld_tag_avail_d[511:0];
      st_tag_avail_q[511:0]               <= st_tag_avail_d[511:0];
      stg2_rtry_misc_grant_q              <= stg2_rtry_misc_grant_d;
      stg2_rtry_st_grant_q                <= stg2_rtry_st_grant_d;
      stg2_rtry_st_grant_256_q            <= stg2_rtry_st_grant_256_d;
      stg2_rtry_ld_grant_q                <= stg2_rtry_ld_grant_d;
      stg2_misc_grant_q                   <= stg2_misc_grant_d;
      stg2_st_grant_q                     <= stg2_st_grant_d;
      stg2_st_grant_256_q                 <= stg2_st_grant_256_d;
      stg2_ld_grant_q                     <= stg2_ld_grant_d;
      stg2_ld_tag_q[8:0]                  <= stg2_ld_tag_d[8:0];
      stg2_st_tag_q[8:0]                  <= stg2_st_tag_d[8:0];
      decr_cmd_credit_q                   <= decr_cmd_credit_d;
      decr_data_credit_4_q                <= decr_data_credit_4_d;
      decr_data_credit_2_q                <= decr_data_credit_2_d;
      decr_data_credit_1_q                <= decr_data_credit_1_d;
      tags_idle_q                         <= tags_idle_d;
    end  // -- always @*

endmodule
