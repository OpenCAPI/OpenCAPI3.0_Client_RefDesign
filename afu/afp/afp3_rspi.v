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

module afp3_rspi (
  
    input                 clock_afu                      // -- target frequency 200MHz
  , input                 clock_tlx                      // -- target frequency 400MHz
  , input                 reset

  // -- CMDO_RSPI interface (for tracking cmds sent vs responses received)
  , input                 cmdo_rspi_cmd_valid
  , input           [7:0] cmdo_rspi_cmd_opcode
  , input           [1:0] cmdo_rspi_cmd_dl

  // -- TLX_AFU response receive interface
  , input                 tlx_afu_resp_valid             // -- Response Valid (Receive)
  , input          [15:0] tlx_afu_resp_afutag            // -- Response Tag
  , input           [7:0] tlx_afu_resp_opcode            // -- Response Opcode
  , input           [3:0] tlx_afu_resp_code              // -- Response Code - reason for failed transation
  , input           [1:0] tlx_afu_resp_dl                // -- Response Data Length
  , input           [1:0] tlx_afu_resp_dp                // -- Response Data Part - indicates the data content of the current response packet
  //input           [5:0] tlx_afu_resp_pg_size           // -- Page Size   - not used in this implementation
  //input          [17:0] tlx_afu_resp_addr_tag          // -- Address Tag - not used in this implementation
  , output                afu_tlx_resp_rd_req            // -- Response Read Request
  , output          [2:0] afu_tlx_resp_rd_cnt            // -- Response Read Count                                                                    

  , input                 tlx_afu_resp_data_valid        // -- Response Data Valid. Indicates valid data available
  , input                 tlx_afu_resp_data_bdi          // -- Response Data Bad Data Indicator
  , input         [511:0] tlx_afu_resp_data_bus          // -- Response Data Bus

  , output                afu_tlx_resp_credit            // -- AFU returns resp credit to TLX
  , output          [6:0] afu_tlx_resp_initial_credit    // -- AFU indicates number of response credits available (static value)

  // -- pcmd resp interface
  , output                rspi_eng_resp_valid            // -- response valid
  , output         [15:0] rspi_eng_resp_afutag           // -- response tag, used to retrieve data from outbound data buffer, valid with rsp_val
  , output          [7:0] rspi_eng_resp_opcode           // -- dl from original command is contained in the afutag
  , output          [3:0] rspi_eng_resp_code
  , output          [1:0] rspi_eng_resp_dl
  , output          [1:0] rspi_eng_resp_dp
  , output                rspi_eng_resp_data_valid       // -- response data valid
  , output          [1:0] rspi_eng_resp_data_bdi         // -- response data bad data indicator
  , output       [1023:0] rspi_eng_resp_data_bus         // -- response data

  // -- Configuration/Mode Bits
  , input                 mmio_rspi_fastpath_queue_bypass_disable // -- Bypass to go around the queue into stg0/resp_queue output latches     - responses WITH data only
  , input                 mmio_rspi_fastpath_stg0_bypass_disable  // -- Bypass to go around the queue and stg0 into the stg1 latches          - responses without data only
  , input                 mmio_rspi_fastpath_stg1_bypass_disable  // -- Bypass to go around the queue and stg1 into the stg2 latches          - responses without data only
  , input                 mmio_rspi_fastpath_stg2_bypass_disable  // -- Bypass to go around the queue and stg1 and stg2 into the stg3 latches - responses without data only 
  , input                 mmio_rspi_normal_stg1_bypass_disable    // -- Used for normal responses coming through the queue to bypass stg1 latches (directly to stg 2 latches) - responses without data only 
  , input                 mmio_rspi_normal_stg2_bypass_disable    // -- Used for normal responses coming through the queue to bypass stg2 latches (directly to stg 3 latches) - responses without data only  
                                                                  // -- Normal Bypass to stg3 trumps fastpath bypass to stg3,  Normal Bypass to stg2 trumps fastpath bypass to stg2
  , input                 mmio_rspi_fastpath_blocker_disable      // -- This mode bit preserves original failure mode of a bug when set to 1,  default is 0, ie. blocker enabled

  , output          [7:0] rspi_mmio_resp_queue_maxqdepth          // -- Indication of maximum number of entries ever contained in the Resp Queue               
  , input                 mmio_rspi_resp_queue_maxqdepth_reset    // -- Reset maximum number of entries to 0                                                   

  , output         [11:0] rspi_mmio_max_outstanding_responses        // -- Indication of maximum number of responses ever outstanding               
  , input                 mmio_rspi_max_outstanding_responses_reset  // -- Reset maximum number of responses outstanding to 0

  // -- TLX_AFU Response Bus Trace outputs
  , output                trace_tlx_afu_resp_valid_with_data
  , output                trace_tlx_afu_resp_valid_no_data
  , output                trace_tlx_afu_resp_valid_retry
  , output         [15:0] trace_tlx_afu_resp_afutag
  , output          [7:0] trace_tlx_afu_resp_opcode
  , output          [3:0] trace_tlx_afu_resp_code
  , output          [1:0] trace_tlx_afu_resp_dl
  , output          [1:0] trace_tlx_afu_resp_dp
//, output          [5:0] trace_tlx_afu_resp_pg_size
//, output         [17:0] trace_tlx_afu_resp_addr_tag

  , output                trace_afu_tlx_resp_rd_req
  , output          [2:0] trace_afu_tlx_resp_rd_cnt                

  , output                trace_tlx_afu_resp_data_valid
  , output          [1:0] trace_tlx_afu_resp_data_bdi
//, output        [511:0] trace_tlx_afu_resp_data_bus

  , output                trace_afu_tlx_resp_credit

  // -- Display Read Interface
  , input                 mmio_rspi_display_rdval  
  , input           [6:0] mmio_rspi_display_addr

  , output                rspi_mmio_display_rddata_valid
  , output         [63:0] rspi_mmio_display_rddata

  // -- Simulation Idle
  , output                sim_idle_rspi                                                                                                            

  );

// -- The diagram below illustrates the structure of the Response Queue Pipeline
// -- There are 6 Bypasses labeled A,B,C,D,E,F
// --   A - Fastpath Queue Bypass - ONLY for command WITH data
// --   B - Fastpath Stg0 Bypass  - ONLY for command with NO data
// --   C - Fastpath Stg1 Bypass  - ONLY for command with NO data
// --   D - Fastpath Stg2 Bypass  - ONLY for command with NO data
// --   E - Normal Stg1 Bypass    - ONLY for command with NO data
// --   F - Normal Stg2 Bypass    - ONLY for command with NO data
// -- Each Bypass may be disabled by MMIO config register
// --
// -- Interface latches, the Response Queue Array, and the Stg0 (Resp Queue Output) latches are all clocked with TLX clk
// -- Stg1,2,3 latches are all clocked with AFU clk (half the frequency of the TLX clk)
// --
// -- The Response Queue produces Valid Read data at its output 2 cycles after assertion of RdEn
// -- The array can be written to on ANY clock cycle
// -- The array RdEn can ONLY be asserted on EVEN clock cycles (thus producing valid data out on an EVEN clock)
// --
// -- For responses WITH data, the AFU_TLX_RESP_RD_REQ is asserted only on an EVEN clock
// -- due to the latency of TLX and alignment to the AFU clock domain.
// -- This will be asserted the cycle that the response is in the Interface latches if it can use Fastpath A.
// -- It will be asserted the cycle that valid response is output from the Response Queue if coming through the queue.
// --
// -- The only restriction for which need to stall the pipeline is if there is a 256B op with data
// -- followed by ANY op with data.   In this case, the next read from the response queue is blocked
// -- and stage 1 wraps back on itself.
// -- Responses without data are allowed to follow a response with 256B data as long as it is NOT
// -- to the same engine.
// --
// -- All bypasses other than A allow for efficiently getting responses having NO data to the interface
// -- to the engines as fast as possible.
// -- Bypasses from the Interface Latches are evaluated to see if they can go on the current cycle
// -- or the next cycle.  If they can go the next cycle, the latches hold value for 1 clock
// -- to allow for proper alignment in the following cycle.  If the queue cannot be bypassed
// -- the response is written into the Response Queue array. 
// --
// --
// --                                          Responses
// --                                          from TLX    _______
// --                                              |      |       |
// --                                     _________V______V__     | Hold if possible to take a fastpath
// --                                    | Interface Latches |____|    on the next clock cycle
// --                                    |_____(TLX CLK)_____|      A can only be taken on an even clk
// --                                              |                B,C,D,E,F can only be taken on an odd clk
// --                          --------------------|
// --                         |      ______________|
// --                         |     |              |
// --                         |     |     _________V_________
// --                         |     |    |  Response Queue   |
// --                         |     |    |    128 Entries    |
// --                         |     |    |    (TLX CLK)      |
// --                         |     |    |                   | <-- Rden asserted ONLY on EVEN clk cycles
// --                         |     |    |                   |
// --                         |     |    |                   |
// --                         |     |    |                   |
// --                         |     |    |___________________|
// --                         |     |____________  |
// --                         |          A       | |
// --                         |                  | |
// --                         |           _______V_V_________
// --                         |          |    Stg0 Latches   |
// --                         |          |_____(TLX_CLK)_____|
// --                         |__________________  |____________________
// --                         |      B           | |  ___________       |              
// --                         |                  | | |           |      |
// --                         |           _______V_V_V_______    |      |
// --                         |          |    Stg1 Latches   |___|      |
// --                         |          |_____(AFU_CLK)_____|          |
// --                         |__________________  |  __________________|           
// --                         |      C           | | |          E       |
// --                         |                  | | |                  |
// --                         |           _______V_V_V_______           |
// --                         |          |    Stg2 Latches   |          |
// --                         |          |_____(AFU_CLK)_____|          |
// --                         |__________________  |  __________________|
// --                                D           | | |          F
// --                                            | | |
// --                                     _______V_V_V_______
// --                                    |    Stg3 Latches   |
// --                                    |_____(AFU_CLK)_____|
// --                                              |
// --                                              V
// --                                      To the Cpy Engines                   


  // --****************************************************************************
  // -- Signal declarations
  // --****************************************************************************

  // -- Response Encode
  wire            tlx_afu_resp_is_nop;
  wire            tlx_afu_resp_is_read_response;
  wire            tlx_afu_resp_is_write_response;
  wire            tlx_afu_resp_is_read_failed;
  wire            tlx_afu_resp_is_write_failed;
  wire            tlx_afu_resp_is_xlate_done;
  wire            tlx_afu_resp_is_intrp_rdy;
  wire            tlx_afu_resp_is_touch_resp;

  // -- Response codes
  wire            tlx_afu_resp_code_is_done;
  wire            tlx_afu_resp_code_is_rty_hwt;
  wire            tlx_afu_resp_code_is_rty_req;
  wire            tlx_afu_resp_code_is_xlate_pending;
  wire            tlx_afu_resp_code_is_intrp_pending;
  wire            tlx_afu_resp_code_is_derror;
  wire            tlx_afu_resp_code_is_bad_length;
  wire            tlx_afu_resp_code_is_bad_addr;
  wire            tlx_afu_resp_code_is_failed;
  wire            tlx_afu_resp_code_is_adr_error;

  // -- Fastpath bypass eligible/taken
  wire            fastpath_hold_tlx_afu_resp;
  wire            fastpath_queue_bypass_possible;
  wire            fastpath_queue_bypass_eligible;
  wire            fastpath_stg0_bypass_possible;
  wire            fastpath_stg0_bypass_eligible;
  wire            fastpath_stg1_bypass_eligible;
  wire            fastpath_stg2_bypass_eligible;
  wire            fastpath_queue_bypass_taken;
  wire            fastpath_stg0_bypass_taken;
  wire            fastpath_stg1_bypass_taken;
  wire            fastpath_stg2_bypass_taken;
  wire            any_fastpath_bypass_taken;

  // -- Response Queue signals
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            resp_queue_empty;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            resp_queue_full;
  wire            resp_queue_last_wraddr;
  wire            resp_queue_last_rdaddr;
//wire      [5:0] resp_queue_wr_sel;
  wire            resp_queue_wren;
  wire     [35:0] resp_queue_wrdata;
//wire      [2:0] resp_queue_rd_sel;
  wire            resp_queue_rden;
  reg       [6:0] resp_queue_rdaddr;

  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            resp_queue_func_rden;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            resp_queue_func_rden_blocker;
  wire     [35:0] resp_queue_rddata;

  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            resp_queue_valid_with_data;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            resp_queue_valid_no_data;
  wire            resp_queue_valid_retry;
  wire            resp_queue_spare;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire     [15:0] resp_queue_afutag;
  wire      [7:0] resp_queue_opcode;
  wire      [3:0] resp_queue_code;
  wire      [1:0] resp_queue_dl;
  wire      [1:0] resp_queue_dp;

  // -- Normal bypass eligible/taken
  wire            normal_stg1_bypass_eligible;
  wire            normal_stg2_bypass_eligible;
  wire            normal_stg1_bypass_taken;
  wire            normal_stg2_bypass_taken;

  // -- Decoded Engine Valid
//     wire     [31:0] resp_engine_stg2;

  // -- Signals for maintaining cmds sent vs responses received
  wire            cmdo_rspi_cmd_opcode_is_rd_wnitc;
  wire            cmdo_rspi_cmd_opcode_is_rd_wnitc_n;
  wire            cmdo_rspi_cmd_opcode_is_dma_w;
  wire            cmdo_rspi_cmd_opcode_is_dma_w_n;
  wire            cmdo_rspi_cmd_opcode_is_dma_pr_w;
  wire            cmdo_rspi_cmd_opcode_is_dma_pr_w_n;
  wire            cmdo_rspi_cmd_opcode_is_dma_w_be;
  wire            cmdo_rspi_cmd_opcode_is_dma_w_be_n;
  wire            cmdo_rspi_cmd_opcode_is_intrp_req;
  wire            cmdo_rspi_cmd_opcode_is_intrp_req_d;
  wire            cmdo_rspi_cmd_opcode_is_xlate_touch;
  wire            cmdo_rspi_cmd_opcode_is_xlate_touch_n;

  wire            stg2_resp_is_read_response;
  wire            stg2_resp_is_read_failed;
  wire            stg2_resp_is_write_response;
  wire            stg2_resp_is_write_failed;
  wire            stg2_resp_is_intrp_rdy;
  wire            stg2_resp_is_xlate_done;
  wire            stg2_resp_is_touch_resp;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            stg2_resp_is_read_or_write;

  wire            outstanding_responses_en;
  wire     [11:0] outstanding_responses_add_4;
  wire     [11:0] outstanding_responses_add_3;
  wire     [11:0] outstanding_responses_add_2;
  wire     [11:0] outstanding_responses_add_1;
  wire     [11:0] outstanding_responses_sub_4;
  wire     [11:0] outstanding_responses_sub_3;
  wire     [11:0] outstanding_responses_sub_2;
  wire     [11:0] outstanding_responses_sub_1;

  wire            quiesced;                                                                                                                

  // -- translated dl to rd_cnt for responses with data
  wire      [2:0] tlx_afu_resp_rd_cnt;
  wire      [2:0] resp_queue_rd_cnt;
  wire      [2:0] resp_rd_cnt_stg1;

  // -- response queue entry tracking
  wire      [7:0] resp_queue_size;
  wire            resp_queue_wrap_match;
  wire      [7:0] resp_queue_tl_mn_hd;
  wire      [7:0] resp_queue_tl_pl_arysz_mn_hd;

  // -- Display Read 
  reg       [6:0] resp_queue_display_seq_sel;
  reg       [7:0] resp_queue_display_seq;
  wire            resp_queue_display_seq_error;

  reg             resp_queue_display_idle_st;      
  reg             resp_queue_display_wait_st;
  reg             resp_queue_display_dly1_st;
  reg             resp_queue_display_dly2_st;
  reg             resp_queue_display_rddataval_st;

  reg             resp_queue_display_rden;
  wire            resp_queue_display_rden_blocker;
  wire      [6:0] resp_queue_display_rdaddr;
  reg             resp_queue_display_rddata_capture;
  reg             resp_queue_display_rddata_valid;


  // --****************************************************************************
  // -- Latch Signal declarations (including enable signals)
  // --****************************************************************************

  // -- Even/Odd latches
  wire            toggle_d;                      // -- AFU clock domain
  reg             toggle_q;
  wire            sample_d;                      // -- TLX clock domain
  reg             sample_q;
  wire            odd_d;                         // -- TLX clock domain
  reg             odd_q;
  wire            even_d;
  reg             even_q;

  // -- Mode/Config Repower latches
  wire            fastpath_queue_bypass_disable_d;
  reg             fastpath_queue_bypass_disable_q;
  wire            fastpath_stg0_bypass_disable_d;
  reg             fastpath_stg0_bypass_disable_q;
  wire            fastpath_stg1_bypass_disable_d;
  reg             fastpath_stg1_bypass_disable_q;
  wire            fastpath_stg2_bypass_disable_d;
  reg             fastpath_stg2_bypass_disable_q;
  wire            normal_stg1_bypass_disable_d;
  reg             normal_stg1_bypass_disable_q;
  wire            normal_stg2_bypass_disable_d;
  reg             normal_stg2_bypass_disable_q;

  // -- TLX input interface latches (TLX clock domain)
  wire            tlx_afu_resp_valid_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             tlx_afu_resp_valid_q;
  wire            tlx_afu_resp_valid_filtered_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             tlx_afu_resp_valid_filtered_q;
  wire            tlx_afu_resp_valid_with_data_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             tlx_afu_resp_valid_with_data_q;
  wire            tlx_afu_resp_valid_no_data_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             tlx_afu_resp_valid_no_data_q;
  wire            tlx_afu_resp_valid_retry_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             tlx_afu_resp_valid_retry_q;
  wire            tlx_afu_resp_en;
  wire     [15:0] tlx_afu_resp_afutag_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [15:0] tlx_afu_resp_afutag_q;
  wire      [7:0] tlx_afu_resp_opcode_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] tlx_afu_resp_opcode_q;
  wire      [3:0] tlx_afu_resp_code_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [3:0] tlx_afu_resp_code_q;
  wire      [1:0] tlx_afu_resp_dl_d;
  reg       [1:0] tlx_afu_resp_dl_q;
  wire      [1:0] tlx_afu_resp_dp_d;
  reg       [1:0] tlx_afu_resp_dp_q;
//wire      [5:0] tlx_afu_resp_pg_size_d;   // -- Not used in this implementation
//reg       [5:0] tlx_afu_resp_pg_size_q;   // -- Not used in this implementation
//wire     [17:0] tlx_afu_resp_addr_tag_d;  // -- Not used in this implementation
//reg      [17:0] tlx_afu_resp_addr_tag_q;  // -- Not used in this implementation

  // -- Fastpath latches
  wire            fastpath_queue_bypass_eligible_nxt_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             fastpath_queue_bypass_eligible_nxt_q;
  wire            fastpath_queue_bypass_possible_nxt_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             fastpath_queue_bypass_possible_nxt_q;
  wire            fastpath_stg0_bypass_eligible_nxt_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             fastpath_stg0_bypass_eligible_nxt_q;
  wire            fastpath_stg0_bypass_possible_nxt_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             fastpath_stg0_bypass_possible_nxt_q;
  wire            fastpath_stg1_bypass_eligible_nxt_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             fastpath_stg1_bypass_eligible_nxt_q;
  wire            fastpath_stg2_bypass_eligible_nxt_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             fastpath_stg2_bypass_eligible_nxt_q;
  wire            normal_stg1_bypass_eligible_nxt_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             normal_stg1_bypass_eligible_nxt_q;
  wire            normal_stg2_bypass_eligible_nxt_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             normal_stg2_bypass_eligible_nxt_q;

  // -- Response Queue latches
  reg       [7:0] resp_queue_wraddr_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] resp_queue_wraddr_q;
  reg       [7:0] resp_queue_rdaddr_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] resp_queue_rdaddr_q;

  wire            resp_queue_empty_d;
  reg             resp_queue_empty_q;

  wire            resp_queue_func_rden_blocker_dly1_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_func_rden_blocker_dly1_q;
  wire            resp_queue_func_rden_blocker_dly2_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_func_rden_blocker_dly2_q;
  wire            resp_queue_func_rden_blocker_dly3_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_func_rden_blocker_dly3_q;
  wire            resp_queue_func_rden_dly1_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_func_rden_dly1_q;
  wire            resp_queue_func_rden_dly2_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_func_rden_dly2_q;
  wire            resp_queue_func_rden_dly3_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_func_rden_dly3_q;
  wire            resp_queue_func_rden_dly4_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_func_rden_dly4_q;

  // -- Response Queue latches (TLX clock domain)
  reg             resp_queue_valid_with_data_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_valid_with_data_q;
  reg             resp_queue_valid_no_data_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_valid_no_data_q;
  reg             resp_queue_valid_retry_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_queue_valid_retry_q;
  reg             resp_queue_spare_d;
  reg             resp_queue_spare_q;
  reg      [15:0] resp_queue_afutag_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [15:0] resp_queue_afutag_q;
  reg       [7:0] resp_queue_opcode_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] resp_queue_opcode_q;
  reg       [3:0] resp_queue_code_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [3:0] resp_queue_code_q;
  reg       [1:0] resp_queue_dl_d;
  reg       [1:0] resp_queue_dl_q;
  reg       [1:0] resp_queue_dp_d;
  reg       [1:0] resp_queue_dp_q;
//reg       [5:0] resp_queue_pg_size_d;   // -- Not used in this implementation
//reg       [5:0] resp_queue_pg_size_q;   // -- Not used in this implementation
//reg      [17:0] resp_queue_addr_tag_d;  // -- Not used in this implementation
//reg      [17:0] resp_queue_addr_tag_q;  // -- Not used in this implementation

  // -- Response Stage 1 latches (AFU clock domain)
  reg             resp_valid_with_data_stg1_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_valid_with_data_stg1_q;
  reg             resp_valid_no_data_stg1_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_valid_no_data_stg1_q;
  reg             resp_valid_retry_stg1_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_valid_retry_stg1_q;
  reg             resp_spare_stg1_d;
  reg             resp_spare_stg1_q;
  reg      [15:0] resp_afutag_stg1_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [15:0] resp_afutag_stg1_q;
  reg       [7:0] resp_opcode_stg1_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] resp_opcode_stg1_q;
  reg       [3:0] resp_code_stg1_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [3:0] resp_code_stg1_q;
  reg       [1:0] resp_dl_stg1_d;
  reg       [1:0] resp_dl_stg1_q;
  reg       [1:0] resp_dp_stg1_d;
  reg       [1:0] resp_dp_stg1_q;
//reg       [5:0] resp_pg_size_stg1_d;   // -- Not used in this implementation
//reg       [5:0] resp_pg_size_stg1_q;   // -- Not used in this implementation
//reg      [17:0] resp_addr_tag_stg1_d;  // -- Not used in this implementation
//reg      [17:0] resp_addr_tag_stg1_q;  // -- Not used in this implementation

  // -- Response Stage 2 latches (AFU clock domain)
  reg             resp_valid_with_data_stg2_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_valid_with_data_stg2_q;
  reg             resp_valid_no_data_stg2_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_valid_no_data_stg2_q;
  reg             resp_valid_retry_stg2_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_valid_retry_stg2_q;
  reg             resp_spare_stg2_d;
  reg             resp_spare_stg2_q;
  reg      [15:0] resp_afutag_stg2_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [15:0] resp_afutag_stg2_q;
  reg       [7:0] resp_opcode_stg2_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] resp_opcode_stg2_q;
  reg       [3:0] resp_code_stg2_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [3:0] resp_code_stg2_q;
  reg       [1:0] resp_dl_stg2_d;
  reg       [1:0] resp_dl_stg2_q;
  reg       [1:0] resp_dp_stg2_d;
  reg       [1:0] resp_dp_stg2_q;
//reg       [5:0] resp_pg_size_stg2_d;   // -- Not used in this implementation
//reg       [5:0] resp_pg_size_stg2_q;   // -- Not used in this implementation
//reg      [17:0] resp_addr_tag_stg2_d;  // -- Not used in this implementation
//reg      [17:0] resp_addr_tag_stg2_q;  // -- Not used in this implementation

  // -- Response Stage 3 latches (AFU clock domain)
  reg             resp_valid_stg3_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_valid_stg3_q;
  reg             resp_valid_with_data_stg3_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_valid_with_data_stg3_q;
  reg             resp_valid_no_data_stg3_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             resp_valid_no_data_stg3_q;
  reg             resp_valid_retry_stg3_d;
  reg             resp_valid_retry_stg3_q;
  reg             resp_spare_stg3_d;
  reg             resp_spare_stg3_q;
  reg      [15:0] resp_afutag_stg3_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [15:0] resp_afutag_stg3_q;
  reg       [7:0] resp_opcode_stg3_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] resp_opcode_stg3_q;
  reg       [3:0] resp_code_stg3_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [3:0] resp_code_stg3_q;
  reg       [1:0] resp_dl_stg3_d;
  reg       [1:0] resp_dl_stg3_q;
  reg       [1:0] resp_dp_stg3_d;
  reg       [1:0] resp_dp_stg3_q;
//reg       [5:0] resp_pg_size_stg3_d;   // -- Not used in this implementation
//reg       [5:0] resp_pg_size_stg3_q;   // -- Not used in this implementation
//reg      [17:0] resp_addr_tag_stg3_d;  // -- Not used in this implementation
//reg      [17:0] resp_addr_tag_stg3_q;  // -- Not used in this implementation

  // -- Data Delay latches (TLX clock domain)
  wire            tlx_afu_resp_data_valid_dly1_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             tlx_afu_resp_data_valid_dly1_q;
  wire            tlx_afu_resp_data_bdi_dly1_d;
  reg             tlx_afu_resp_data_bdi_dly1_q;
  wire    [511:0] tlx_afu_resp_data_bus_dly1_d;
  reg     [511:0] tlx_afu_resp_data_bus_dly1_q;

  wire            tlx_afu_resp_data_valid_dly2_d;
  reg             tlx_afu_resp_data_valid_dly2_q;
  wire            tlx_afu_resp_data_bdi_dly2_d;
  reg             tlx_afu_resp_data_bdi_dly2_q;
  wire    [511:0] tlx_afu_resp_data_bus_dly2_d;
  reg     [511:0] tlx_afu_resp_data_bus_dly2_q;

  // -- Data Stage 3 latches (AFU clock domain - aligns with Response stage 3 latches)
  wire            resp_data_valid_stg3_d;
  reg             resp_data_valid_stg3_q;
  wire      [1:0] resp_data_bdi_stg3_d;
  reg       [1:0] resp_data_bdi_stg3_q;
  wire   [1023:0] resp_data_bus_stg3_d;
  reg    [1023:0] resp_data_bus_stg3_q;

  // -- Credit Return indicator (TLX clock domain)
  wire            return_resp_credit_to_tlx_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             return_resp_credit_to_tlx_q;

  // -- Latches for maintaining cmds sent vs responses received (AFU clock domain)
  wire            cmdo_rspi_cmd_valid_d;
  reg             cmdo_rspi_cmd_valid_q;

  wire            add_4_d;
  reg             add_4_q;
  wire            add_2_d;
  reg             add_2_q;
  wire            add_1_d;
  reg             add_1_q;
  wire            add_0_d;
  reg             add_0_q;

  wire            sub_4_d;
  reg             sub_4_q;
  wire            sub_2_d;
  reg             sub_2_q;
  wire            sub_1_d;
  reg             sub_1_q;
  wire            sub_0_d;
  reg             sub_0_q;

  reg      [11:0] outstanding_responses_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [11:0] outstanding_responses_q;
  reg      [11:0] max_outstanding_responses_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [11:0] max_outstanding_responses_q;

  // -- response queue entry tracking
  reg       [7:0] resp_queue_numentriesval_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] resp_queue_numentriesval_q;
  reg       [7:0] resp_queue_maxqdepth_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [7:0] resp_queue_maxqdepth_q;

  // -- Latches for timing fixes
  reg       [1:0] tlx_afu_resp_dl_cpy_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [1:0] tlx_afu_resp_dl_cpy_q;

  wire      [1:0] resp_dl_stg1_cpy_d;
  reg       [1:0] resp_dl_stg1_cpy_q;

  // -- Latches for trace array
  wire            afu_tlx_resp_rd_req_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             afu_tlx_resp_rd_req_q;

  reg       [2:0] afu_tlx_resp_rd_cnt_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg       [2:0] afu_tlx_resp_rd_cnt_q;

  // -- Latches for Display Read 
  wire            mmio_rspi_display_rdval_d;
  reg             mmio_rspi_display_rdval_q;
  wire            mmio_rspi_display_addr_en;
  wire      [6:0] mmio_rspi_display_addr_d;
  reg       [6:0] mmio_rspi_display_addr_q;

  reg       [4:0] resp_queue_display_seq_d;
  reg       [4:0] resp_queue_display_seq_q;
  wire            resp_queue_display_rddata_en;
  wire     [35:0] resp_queue_display_rddata_d;
  reg      [35:0] resp_queue_display_rddata_q;

  // -- Bug Fix
  wire            fastpath_blocker_disable_d;
  reg             fastpath_blocker_disable_q;

  wire            xlate_done_or_intrp_rdy_fastpath_blocker_d;
  reg             xlate_done_or_intrp_rdy_fastpath_blocker_q;


  // --****************************************************************************
  // -- Constant declarations
  // --****************************************************************************

  // -- TLX AP command encodes (for tracking of outstanding responses)
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC              = 8'b00010000;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_RD_WNITC_N            = 8'b00010100;  // -- Read with no intent to cache
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W                 = 8'b00100000;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_N               = 8'b00100100;  // -- DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W              = 8'b00110000;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_PR_W_N            = 8'b00110100;  // -- DMA Partial Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE              = 8'b00101000;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_DMA_W_BE_N            = 8'b00101100;  // -- Byte Enable DMA Write
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ             = 8'b01011000;  // -- Interrupt Request
  localparam    [7:0] AFU_TLX_CMD_ENCODE_INTRP_REQ_D           = 8'b01011010;  // -- Interrupt Request
  localparam    [7:0] AFU_TLX_CMD_ENCODE_XLATE_TOUCH           = 8'b01111000;  // -- Address translation prefetch
  localparam    [7:0] AFU_TLX_CMD_ENCODE_XLATE_TOUCH_N         = 8'b01111001;  // -- Address translation prefetch

  // -- TL CAPP response encodes
  localparam    [7:0] TLX_AFU_RESP_ENCODE_NOP                  = 8'b00000000;  // -- Nop
  localparam    [7:0] TLX_AFU_RESP_ENCODE_RETURN_TLX_CREDITS   = 8'b00000001;  // -- Return TLX Credits
  localparam    [7:0] TLX_AFU_RESP_ENCODE_TOUCH_RESP           = 8'b00000010;  // -- Touch Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_READ_RESPONSE        = 8'b00000100;  // -- Read Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_UPGRADE_RESP         = 8'b00000111;  // -- Upgrade Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_READ_FAILED          = 8'b00000101;  // -- Read Failed
  localparam    [7:0] TLX_AFU_RESP_ENCODE_CL_RD_RESP           = 8'b00000110;  // -- Cachable Read Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_WRITE_RESPONSE       = 8'b00001000;  // -- Write Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_WRITE_FAILED         = 8'b00001001;  // -- Write Failed
  localparam    [7:0] TLX_AFU_RESP_ENCODE_MEM_FLUSH_DONE       = 8'b00001010;  // -- Memory Flush Done
  localparam    [7:0] TLX_AFU_RESP_ENCODE_INTRP_RESP           = 8'b00001100;  // -- Interrupt Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_WAKE_HOST_RESP       = 8'b00010000;  // -- Wake Host Thread Response
                                                  
  localparam    [7:0] TLX_AFU_RESP_ENCODE_XLATE_DONE           = 8'b00011000;  // -- Address Translation Completed (Async Notification)
  localparam    [7:0] TLX_AFU_RESP_ENCODE_INTRP_RDY            = 8'b00011010;  // -- Interrupt ready (Async Notification)

  // -- TL CAPP response codes
  localparam    [3:0] TLX_AFU_RESP_CODE_DONE                   = 4'b0000;
  localparam    [3:0] TLX_AFU_RESP_CODE_RTY_HWT                = 4'b0001;
  localparam    [3:0] TLX_AFU_RESP_CODE_RTY_REQ                = 4'b0010;
  localparam    [3:0] TLX_AFU_RESP_CODE_XLATE_PENDING          = 4'b0100;
  localparam    [3:0] TLX_AFU_RESP_CODE_INTRP_PENDING          = 4'b0100;
  localparam    [3:0] TLX_AFU_RESP_CODE_DERROR                 = 4'b1000;
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_LENGTH             = 4'b1001;
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_ADDR               = 4'b1011;
  localparam    [3:0] TLX_AFU_RESP_CODE_FAILED                 = 4'b1110;
  localparam    [3:0] TLX_AFU_RESP_CODE_ADR_ERROR              = 4'b1111;


  // -- ********************************************************************************************************************************
  // -- Determine Even/Odd Cycles
  // -- ********************************************************************************************************************************

  // --                          _______         _______         _______         _______         _______         
  // -- clock_afu             __|       |_______|       |_______|       |_______|       |_______|       |_______
  // --                          ___     ___     ___     ___     ___     ___     ___     ___     ___     ___     
  // -- clock_tlx             __|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___
  // --                          _______________                 _______________                 _______________
  // -- toggle_q              __|               |_______________|               |_______________|
  // --                                  _______________                 _______________                 _______
  // -- sample_q              __________|               |_______________|               |_______________|
  // --                          _______         _______         _______         _______         _______         
  // -- even_q                __|       |_______|       |_______|       |_______|       |_______|       |_______
  // --                       __         _______         _______         _______         _______         _______         
  // -- odd_q                   |_______|       |_______|       |_______|       |_______|       |_______|       


  assign  toggle_d = ~toggle_q && ~reset;

  assign  sample_d =  toggle_q;

  assign  odd_d    =  toggle_q ^ sample_q;

  assign  even_d   =  odd_q;


  // -- ******************************************************************************************************************************************
  // -- Decode the latched response opcode and response code
  // -- ******************************************************************************************************************************************

  // -- Response Encode
  assign  tlx_afu_resp_is_nop                =  ( tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_NOP[7:0]            );
  assign  tlx_afu_resp_is_read_response      =  ( tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_READ_RESPONSE[7:0]  );  // -- good response
  assign  tlx_afu_resp_is_write_response     =  ( tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_WRITE_RESPONSE[7:0] );  // -- good response
  assign  tlx_afu_resp_is_read_failed        =  ( tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_READ_FAILED[7:0]    );  // -- failed response, check resp code
  assign  tlx_afu_resp_is_write_failed       =  ( tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_WRITE_FAILED[7:0]   );  // -- failed response, check resp code
  assign  tlx_afu_resp_is_xlate_done         =  ( tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_XLATE_DONE[7:0]     );  // -- check resp code
  assign  tlx_afu_resp_is_intrp_rdy          =  ( tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_INTRP_RDY[7:0]      );  // -- check resp code
  assign  tlx_afu_resp_is_touch_resp         =  ( tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_TOUCH_RESP[7:0]     );  // -- check resp code
                                                                                                                        
  // -- Response codes                                                                                                  
  assign  tlx_afu_resp_code_is_done          =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_DONE[3:0]             );   // -- Done
  assign  tlx_afu_resp_code_is_rty_hwt       =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_RTY_HWT[3:0]          );   // -- Retry translate touch with using Heavy-weight code
  assign  tlx_afu_resp_code_is_rty_req       =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_RTY_REQ[3:0]          );   // -- Retry Immediate
  assign  tlx_afu_resp_code_is_xlate_pending =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_XLATE_PENDING[3:0]    );   // -- Toss, wait for xlate done with same AFU tag, convert to Retry
  assign  tlx_afu_resp_code_is_intrp_pending =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_INTRP_PENDING[3:0]    );   // -- Toss, wait for intrp rdy same AFU tag, convert to Retry
  assign  tlx_afu_resp_code_is_derror        =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_DERROR[3:0]           );   // -- Machine Check
  assign  tlx_afu_resp_code_is_bad_length    =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_BAD_LENGTH[3:0]       );   // -- Machine Check
  assign  tlx_afu_resp_code_is_bad_addr      =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_BAD_ADDR[3:0]         );   // -- Machine Check
  assign  tlx_afu_resp_code_is_failed        =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_FAILED[3:0]           );   // -- Machine Check
  assign  tlx_afu_resp_code_is_adr_error     =  ( tlx_afu_resp_code[3:0]   ==  TLX_AFU_RESP_CODE_ADR_ERROR[3:0]        );   // -- Machine Check

  // -- Create filtered valid response (Filter out xlate_pending, intrp_pending, touch responses when the engine xtouch sequencer is not waiting for responses)
  // --assign  tlx_afu_resp_valid_filtered_d =  ( tlx_afu_resp_valid && ~tlx_afu_resp_code_is_xlate_pending  && ~tlx_afu_resp_code_is_intrp_pending && ~((tlx_afu_resp_is_touch_resp || (tlx_afu_resp_is_xlate_done && tlx_afu_resp_afutag[13])) && ~mmio_rspi_xtouch_wt4rsp_enable));

  // -- Change was made to NOT filter out any responses, pass everything to the engine  (leave the latch named as is in case need to add filtering later)
  assign  tlx_afu_resp_valid_filtered_d =  tlx_afu_resp_valid;

  // -- Valid responses requiring data movement (and translated response)
  assign  tlx_afu_resp_valid_with_data_d =  ( tlx_afu_resp_valid_filtered_d &&  tlx_afu_resp_is_read_response ) ||
                                            ( fastpath_hold_tlx_afu_resp && tlx_afu_resp_valid_with_data_q );

  // -- Valid responses NOT requiring data movement - simply forward response to the engines (including retries and xlate_done ... which will also be retried)
  assign  tlx_afu_resp_valid_no_data_d   =  ( tlx_afu_resp_valid_filtered_d && ~tlx_afu_resp_is_read_response ) ||
                                            ( fastpath_hold_tlx_afu_resp && tlx_afu_resp_valid_no_data_q );
 
  // -- Keep an indicator if this response requires a retry
  assign  tlx_afu_resp_valid_retry_d     = (tlx_afu_resp_valid_filtered_d &&
                                          (( tlx_afu_resp_is_read_failed  && tlx_afu_resp_code_is_rty_req ) ||  // -- These conditions will be retried by MCP AFU
                                           ( tlx_afu_resp_is_write_failed && tlx_afu_resp_code_is_rty_req ) || 
                                           ( tlx_afu_resp_is_xlate_done   && tlx_afu_resp_code_is_rty_req ) || 
                                           ( tlx_afu_resp_is_intrp_rdy    && tlx_afu_resp_code_is_rty_req ) || 
                                           ( tlx_afu_resp_is_xlate_done   && tlx_afu_resp_code_is_done )    ||
                                           ( tlx_afu_resp_is_intrp_rdy    && tlx_afu_resp_code_is_done )    ||
                                           ( tlx_afu_resp_is_touch_resp   && tlx_afu_resp_code_is_rty_req ) || 
                                           ( tlx_afu_resp_is_touch_resp   && tlx_afu_resp_code_is_rty_hwt ))) || 
                                           ( fastpath_hold_tlx_afu_resp && tlx_afu_resp_valid_retry_q );


  // -- ******************************************************************************************************************************************
  // -- Based upon the decode of the latched response opcode and response code and other info, determine which fastpaths can be taken
  // -- ******************************************************************************************************************************************

  // -- latch mode bits from mmio
  assign  fastpath_queue_bypass_disable_d =  mmio_rspi_fastpath_queue_bypass_disable;  // -- For Responses with Data only
  assign  fastpath_stg0_bypass_disable_d  =  mmio_rspi_fastpath_stg0_bypass_disable;   // -- For Responses with NO Data only
  assign  fastpath_stg1_bypass_disable_d  =  mmio_rspi_fastpath_stg1_bypass_disable;   // -- For Responses with NO Data only 
  assign  fastpath_stg2_bypass_disable_d  =  mmio_rspi_fastpath_stg2_bypass_disable;   // -- For Responses with NO Data only
  assign  normal_stg1_bypass_disable_d    =  mmio_rspi_normal_stg1_bypass_disable;     // -- For Responses with NO Data only - taken from output of stg0 latch   
  assign  normal_stg2_bypass_disable_d    =  mmio_rspi_normal_stg2_bypass_disable;     // -- For Responses with NO Data only - taken from output of stg0 latch    

  // -- This mode bit was added for a bug fix - it preserves the original function (ie. leaves the bug in when disable is active)
  // -- Default is fix enabled (ie - disable = b'0)
  // -- This blocker is to block allowing non-data fastpaths to be taken for xlate_done and intrp_rdy responses
  // -- A case was hit during lab testing in which the host delivered both in the same response flit and TLX
  // --    presented them to the AFU 2 cycles apart.  Actual Sequence  Failed/Retry, Failed/xlate_pending, dead cycle, Failed/xlate_done, Failed/Retry
  // -- The xlate pending went into the response queue, but exited such that the queue went empty and the xlate done was allowed to jump ahead of it via fastpath
  // -- This behavior, although legal, was not anticipated from the host, so want to preserve the original function for further testing, hence the mode bit
  // -- The fix will prevent/block xlate_done and intrp_rdy responses from taking fastpath, thus avoiding the reordering.
  assign  fastpath_blocker_disable_d      =  mmio_rspi_fastpath_blocker_disable;   // -- Blocker disable for xlate_done and intrp_rdy
  
  // -- Because xlate_pending and xlate_done must have order preserved, xlate_done cannot go fastpath.  similar argument with intrp_pending and intrp_rdy
  assign  xlate_done_or_intrp_rdy_fastpath_blocker_d = (( fastpath_blocker_disable_q == 1'b0 ) && ( tlx_afu_resp_is_xlate_done || tlx_afu_resp_is_intrp_rdy ));  // -- bug fix

  // -- Determine if response queue array can be bypassed THIS cycle for response WITH data (fastpath)
  assign  fastpath_queue_bypass_eligible_nxt_d = 
     ( fastpath_queue_bypass_disable_q      == 1'b0 ) &&  // -- Fastpath to bypass the Resp Queue Array is enabled
     ( even_d                               == 1'b1 ) &&  // -- Even Cycle
     ( resp_queue_empty_d                   == 1'b1 ) &&  // -- Resp Queue is empty
     ( resp_queue_func_rden_dly2_d          == 1'b0 ) &&  // -- Resp Queue rden was ! asserted in previous two cycles
     ( resp_queue_func_rden_blocker_dly2_d  == 1'b0 ) &&  // -- *Bug Fix*
//-- ( tlx_afu_resp_valid_with_data_q       == 1'b1 ) &&  // -- Valid response (with data)
    (( resp_valid_with_data_stg1_d          == 1'b0 ) ||                                      // -- No Valid Response OR Valid response with no data currently in the stg1 latches OR
    (( resp_valid_with_data_stg1_d          == 1'b1 ) && ( resp_dl_stg1_d[1:0] != 2'b11 )));  // -- Valid Response with data in stg1, but its NOT 256B

  assign  fastpath_queue_bypass_eligible =  fastpath_queue_bypass_eligible_nxt_q && tlx_afu_resp_valid_with_data_q;

  // -- Determine if response queue array has potential to be bypassed NEXT cycle for response WITH data (fastpath)
  assign  fastpath_queue_bypass_possible_nxt_d = 
     ( fastpath_queue_bypass_disable_q      == 1'b0 ) &&  // -- Fastpath to bypass the Resp Queue Array is enabled
     ( odd_d                                == 1'b1 ) &&  // -- Odd Cycle
     ( resp_queue_empty_d                   == 1'b1 ) &&  // -- Resp Queue is empty
     ( resp_queue_func_rden_dly1_d          == 1'b0 ) &&  // -- Resp Queue rden was ! asserted in previous two cycles
     ( resp_queue_func_rden_blocker_dly1_d  == 1'b0 ) &&  // -- *Bug Fix*
//-- ( tlx_afu_resp_valid_with_data_q       == 1'b1 ) &&  // -- Valid response (with data)
    (( resp_queue_valid_with_data_d         == 1'b0 ) ||                                       // -- No Valid Response OR Valid response with no data currently in the stg0 latches OR
    (( resp_queue_valid_with_data_d         == 1'b1 ) && ( resp_queue_dl_d[1:0] != 2'b11 )));  // -- Valid Response with data in stg0, but its NOT 256B

  assign  fastpath_queue_bypass_possible =  fastpath_queue_bypass_possible_nxt_q && tlx_afu_resp_valid_with_data_q;

  // -- Determine if response queue array can be bypassed THIS cycle for cmd with NO data (fastpath)
  assign  fastpath_stg0_bypass_eligible_nxt_d = 
     ( fastpath_stg0_bypass_disable_q       == 1'b0 ) &&  // -- Fastpath to bypass the Resp Queue Array is enabled
     ( odd_d                                == 1'b1 ) &&  // -- Odd Cycle
     ( resp_queue_empty_d                   == 1'b1 ) &&  // -- Resp Queue is empty
     ( resp_queue_func_rden_dly1_d          == 1'b0 ) &&  // -- Resp Queue rden was ! asserted in previous two cycles
     ( resp_queue_valid_with_data_d         == 1'b0 ) &&  // -- Stg0 latches are empty
     ( resp_queue_valid_no_data_d           == 1'b0 ) &&  // -- Stg0 latches are empty
     ( resp_queue_func_rden_blocker_dly3_d  == 1'b0 );    // -- *Bug Fix*
//-- ( tlx_afu_resp_valid_no_data_q         == 1'b1 );    // -- Valid response (no data)

//-- ( tlx_afu_resp_valid_no_data_q         == 1'b1 ) &&  // -- Valid response (no data)
//-- (( resp_valid_with_data_stg1_q         == 1'b0 ) ||                          // -- No Valid Response OR Valid response with no data currently in the stg1 latches 
//-- (( resp_valid_with_data_stg1_q         == 1'b1 ) && ( resp_dl_stg1_q[1:0] != 2'b11 ) && ( resp_queue_func_rden_blocker_dly3_q == 1'b0 )) ||
//-- (( resp_valid_with_data_stg1_q         == 1'b1 ) && ( resp_dl_stg1_q[1:0] == 2'b11 ) && ( resp_queue_func_rden_blocker_dly3_q == 1'b0 ) &&  // -- Valid Response with data in stg1, but its NOT 256B OR
//--  ( tlx_afu_resp_afutag_q[10:5]         != resp_afutag_stg1_q[10:5] )));

  assign  fastpath_stg0_bypass_eligible =  fastpath_stg0_bypass_eligible_nxt_q && tlx_afu_resp_valid_no_data_q && ~xlate_done_or_intrp_rdy_fastpath_blocker_q;
                                       


  // -- Determine if response queue array can be bypassed NEXT cycle for cmd with NO data (fastpath)
  assign  fastpath_stg0_bypass_possible_nxt_d = 
     ( fastpath_stg0_bypass_disable_q       == 1'b0 ) &&  // -- Fastpath to bypass the Resp Queue Array is enabled
     ( even_d                               == 1'b1 ) &&  // -- Even Cycle
     ( resp_queue_empty_d                   == 1'b1 ) &&  // -- Resp Queue is empty
     ( resp_queue_func_rden_dly2_d          == 1'b0 ) &&  // -- Resp Queue rden was ! asserted in previous two cycles
//-- ( tlx_afu_resp_valid_no_data_q         == 1'b1 ) &&  // -- Valid response (no data)
     ( resp_queue_func_rden_blocker_dly2_d  == 1'b0 );    // -- *Bug Fix*

//-- ( resp_queue_func_rden_blocker_dly2_q  == 1'b0 ) &&  // -- *Bug Fix*
//--(( resp_valid_with_data_stg1_q          == 1'b0 ) ||                          // -- No Valid Response OR Valid response with no data currently in the stg1 latches OR
//--(( resp_valid_with_data_stg1_q          == 1'b1 ) && (resp_dl_stg1_q[1:0] != 2'b11) && ( resp_queue_func_rden_blocker_dly2_q == 1'b0 )) ||
//--(( resp_valid_with_data_stg1_q          == 1'b1 ) && (resp_dl_stg1_q[1:0] == 2'b11) && ( resp_queue_func_rden_blocker_dly2_q == 1'b0 ) &&  // -- Valid Response with data in stg1, but its NOT 256B OR
//-- ( tlx_afu_resp_afutag_q[10:5]          != resp_afutag_stg1_q[10:5] )));

  assign  fastpath_stg0_bypass_possible = fastpath_stg0_bypass_possible_nxt_q && tlx_afu_resp_valid_no_data_q && ~xlate_done_or_intrp_rdy_fastpath_blocker_q;

  // -- If fastpath is possible, but clock is even and no new inbound response from TLX, hold the command until odd cycle so it can go fastpath
  assign  fastpath_hold_tlx_afu_resp  =  (( fastpath_queue_bypass_possible || fastpath_stg0_bypass_possible) && ~tlx_afu_resp_valid );

  // -- In addition to bypassing the queue, determine if the Stg1 latches can also be bypassed (only possible for responses with no data )
  assign  fastpath_stg1_bypass_eligible_nxt_d =
     ( fastpath_stg1_bypass_disable_q == 1'b0 ) &&  // -- Fastpath to bypass the Stg1 latches is also enabled
     ( odd_d                          == 1'b1 ) &&  // -- Odd Cycle
//-- ( tlx_afu_resp_valid_no_data_q   == 1'b1 ) &&  // -- Valid response (no_data)
     ( resp_valid_with_data_stg1_q    == 1'b0 ) &&  // -- Stg1 latches are empty
     ( resp_valid_no_data_stg1_q      == 1'b0 );    // -- Stg1 latches are empty

//-- ( resp_valid_no_data_stg1_q      == 1'b0 ) &&  // -- Stg1 latches are empty
//--(( resp_valid_with_data_stg2_q    == 1'b0 )                                       ||  // -- No Valid Response || Valid response with no data currently in the stg2 latches ||
//--(( resp_valid_with_data_stg2_q    == 1'b1 ) && (resp_dl_stg2_q[1:0] != 2'b11 ))   ||  // -- Valid Response with data in Stg2, but its ! 256B ||
//--(( resp_valid_with_data_stg2_q    == 1'b1 ) && (resp_dl_stg2_q[1:0] == 2'b11 ) &&     // -- Valid Response with data in Stg2, and it IS 256B, BUT ... 
//-- ( tlx_afu_resp_afutag_q[10:5]    != resp_afutag_stg2_q[10:5] )));                       // -- Current response doesn't have data && not to same engine

  assign  fastpath_stg1_bypass_eligible =  fastpath_stg1_bypass_eligible_nxt_q && tlx_afu_resp_valid_no_data_q && ~xlate_done_or_intrp_rdy_fastpath_blocker_q;

  // -- In addition to bypassing the queue, determine if the Stg1 AND Stg2 latches can also be bypassed (only possible for responses with no data )
  assign  fastpath_stg2_bypass_eligible_nxt_d = 
     ( fastpath_stg2_bypass_disable_q == 1'b0 ) &&  // -- Fastpath to bypass the Stg2 latches is also enabled
     ( odd_d                          == 1'b1 ) &&  // -- Odd Cycle
//-- ( tlx_afu_resp_valid_no_data_q   == 1'b1 ) &&  // -- Valid response (no_data)
     ( resp_valid_with_data_stg2_q    == 1'b0 ) &&  // -- Stg2 latches are empty (OK if Stg1 latches DO have valid response)
     ( resp_valid_no_data_stg2_q      == 1'b0 );    // -- Stg2 latches are empty (OK if Stg1 latches DO have valid response)

//-- ( resp_valid_no_data_stg2_q      == 1'b0 ) &&  // -- Stg2 latches are empty (OK if Stg1 latches DO have valid response)
//--(( resp_valid_with_data_stg3_q    == 1'b0 )                                       ||  // -- No Valid Response || Valid response with no data currently in the stg3 latches ||
//--(( resp_valid_with_data_stg3_q    == 1'b1 ) && (resp_dl_stg3_q[1:0] != 2'b11 ))   ||  // -- Valid Response with data in Stg3, but its ! 256B ||
//--(( resp_valid_with_data_stg3_q    == 1'b1 ) && (resp_dl_stg3_q[1:0] == 2'b11 ) &&     // -- Valid Response with data in Stg3, and it IS 256B, BUT ... 
//-- ( tlx_afu_resp_afutag_q[10:5]    != resp_afutag_stg3_q[10:5] )));                       // -- Current response doesn't have data && not to same engine

  assign  fastpath_stg2_bypass_eligible =  fastpath_stg2_bypass_eligible_nxt_q && tlx_afu_resp_valid_no_data_q && ~xlate_done_or_intrp_rdy_fastpath_blocker_q;

  // -- Choose one of the eligible fastpaths
  assign  fastpath_stg2_bypass_taken  =  ( fastpath_stg2_bypass_eligible  &&   ~normal_stg2_bypass_taken );                                 // -- Allow older responses to advance
  assign  fastpath_stg1_bypass_taken  =  ( fastpath_stg1_bypass_eligible  && ~fastpath_stg2_bypass_taken &&   ~normal_stg1_bypass_taken );  // -- Allow older responses to advance
  assign  fastpath_stg0_bypass_taken  =  ( fastpath_stg0_bypass_eligible  && ~fastpath_stg1_bypass_taken && ~fastpath_stg2_bypass_taken );
  assign  fastpath_queue_bypass_taken =  ( fastpath_queue_bypass_eligible );

  assign  any_fastpath_bypass_taken   =  ( fastpath_stg2_bypass_taken || fastpath_stg1_bypass_taken || fastpath_stg0_bypass_taken || fastpath_queue_bypass_taken );


  // -- ******************************************************************************************************************************************
  // -- Latch interface signals (TLX clock domain)
  // -- ******************************************************************************************************************************************

  // -- Latch or hold the interface (see fastpath stuff above)

  assign  tlx_afu_resp_valid_d =  ( tlx_afu_resp_valid   && ~fastpath_hold_tlx_afu_resp) ||
                                  ( tlx_afu_resp_valid_q &&  fastpath_hold_tlx_afu_resp);

  assign  tlx_afu_resp_en =  tlx_afu_resp_valid;

  assign  tlx_afu_resp_afutag_d[15:0]   =  tlx_afu_resp_afutag[15:0];                                          
  assign  tlx_afu_resp_opcode_d[7:0]    =  tlx_afu_resp_opcode[7:0];                                           
  assign  tlx_afu_resp_code_d[3:0]      =  tlx_afu_resp_code[3:0];                                         
  assign  tlx_afu_resp_dl_d[1:0]        =  tlx_afu_resp_dl[1:0];                                            
  assign  tlx_afu_resp_dp_d[1:0]        =  tlx_afu_resp_dp[1:0];                                           
//assign  tlx_afu_resp_pg_size_d[5:0]   =  tlx_afu_resp_pg_size[5:0];    // -- Not used in this implementation                                         
//assign  tlx_afu_resp_addr_tag_d[17:0] =  tlx_afu_resp_addr_tag[17:0];  // -- Not used in this implementation                                         


  // -- ******************************************************************************************************************************************
  // -- Response Queue  
  // -- ******************************************************************************************************************************************
  // -- The response queue is needed to absorb number of responses from tlx as set by afu_tlx_resp_initial_credit.
  // -- It takes 3 cycles to go through the queue, so when the queue is empty, a fastpath is provided around the queue.

  // -- Determine if queue is full or empty (bit 7 of the address toggles on every wrap)
  assign  resp_queue_empty_d =  (( resp_queue_wraddr_d[6:0] == resp_queue_rdaddr_d[6:0] ) && ( resp_queue_wraddr_d[7] == resp_queue_rdaddr_d[7] ));
  assign  resp_queue_empty   =  (( resp_queue_wraddr_q[6:0] == resp_queue_rdaddr_q[6:0] ) && ( resp_queue_wraddr_q[7] == resp_queue_rdaddr_q[7] ));
  assign  resp_queue_full    =  (( resp_queue_wraddr_q[6:0] == resp_queue_rdaddr_q[6:0] ) && ( resp_queue_wraddr_q[7] != resp_queue_rdaddr_q[7] ));

  // -- Determine if the write address is currently pointing to the last entry of the array
  assign  resp_queue_last_wraddr =  ( resp_queue_wraddr_q[6:0] == 7'b1111111 );  // -- Set the same as afu_tlx_resp_initial_credit
  assign  resp_queue_last_rdaddr =  ( resp_queue_rdaddr_q[6:0] == 7'b1111111 );  // -- Set the same as afu_tlx_resp_initial_credit

  // -- Queue any response that cannot bypass the response queue
  //--gn  resp_queue_wren = ( ~reset && ~resp_queue_full && ~any_fastpath_bypass_taken && ~fastpath_hold_tlx_afu_resp && tlx_afu_resp_valid_filtered_q );
  assign  resp_queue_wren = ( ~reset && ~resp_queue_full && ~any_fastpath_bypass_taken && ~fastpath_hold_tlx_afu_resp && tlx_afu_resp_valid_q );

  // -- assign  resp_queue_wr_sel[5:0] =  { reset, resp_queue_full, any_fastpath_bypass_taken, fastpath_hold_tlx_afu_resp, tlx_afu_resp_valid_filtered_q, resp_queue_last_wraddr };

  // --always @*
  // --  begin
  // --    casez ( resp_queue_wr_sel[5:0] )
  // --      //
  // --      // --  reset
  // --      // --  |resp_queue_full
  // --      // --  ||any_fastpath_bypass_taken
  // --      // --  |||fastpath_hold_tlx_afu_resp
  // --      // --  ||||tlx_afu_resp_valid_filtered_q
  // --      // --  |||||resp_queue_last_wraddr
  // --      // --  ||||||
  // --      // ---------------------------------------------------------------------------------------------------------
  // --          6'b1????? :  resp_queue_wraddr_d[7:0] =  {                    1'b0,                      7'b0           };  // -- reset
  // --          6'b000010 :  resp_queue_wraddr_d[7:0] =  {  resp_queue_wraddr_q[7], ( resp_queue_wraddr_q[6:0] + 7'b1 ) };  // -- write into the queue, NOT last wraddr, increment
  // --          6'b000011 :  resp_queue_wraddr_d[7:0] =  { ~resp_queue_wraddr_q[7],                      7'b0           };  // -- write into the queue, last wraddr, flip toggle bit, wrap back to zero
  // --      // ---------------------------------------------------------------------------------------------------------
  // --          default   :  resp_queue_wraddr_d[7:0] =  {  resp_queue_wraddr_q[7],   resp_queue_wraddr_q[6:0]          };  // -- Hold current value
  // --      // ---------------------------------------------------------------------------------------------------------
  // --     endcase
  // --  end  // -- always @*

  always @*
    begin
      if ( reset )
        resp_queue_wraddr_d[7:0] =  8'b0;                                                              // -- reset
// -- else if ( ~resp_queue_full && ~any_fastpath_bypass_taken && ~fastpath_hold_tlx_afu_resp && tlx_afu_resp_valid_filtered_q && ~resp_queue_last_wraddr )
      else if ( ~resp_queue_full && ~any_fastpath_bypass_taken && ~fastpath_hold_tlx_afu_resp && tlx_afu_resp_valid_q && ~resp_queue_last_wraddr )
        resp_queue_wraddr_d[7:0] =  {  resp_queue_wraddr_q[7], ( resp_queue_wraddr_q[6:0] + 7'b1 ) };  // -- write into the queue, NOT last wraddr, increment
// -- else if ( ~resp_queue_full && ~any_fastpath_bypass_taken && ~fastpath_hold_tlx_afu_resp && tlx_afu_resp_valid_filtered_q &&  resp_queue_last_wraddr )
      else if ( ~resp_queue_full && ~any_fastpath_bypass_taken && ~fastpath_hold_tlx_afu_resp && tlx_afu_resp_valid_q &&  resp_queue_last_wraddr )
        resp_queue_wraddr_d[7:0] =  { ~resp_queue_wraddr_q[7], 7'b0 };                                 // -- write into the queue, last wraddr, flip toggle bit, wrap back to zero
      else
        resp_queue_wraddr_d[7:0] =  resp_queue_wraddr_q[7:0];                                          // -- Hold current value
    end  // -- always @*

  // -- form write data going into the array
  assign  resp_queue_wrdata[35:34] =  tlx_afu_resp_dp_q[1:0]; 
  assign  resp_queue_wrdata[33:32] =  tlx_afu_resp_dl_q[1:0]; 
  assign  resp_queue_wrdata[31:28] =  tlx_afu_resp_code_q[3:0]; 
  assign  resp_queue_wrdata[27:20] =  tlx_afu_resp_opcode_q[7:0]; 
  assign  resp_queue_wrdata[19:4]  =  tlx_afu_resp_afutag_q[15:0]; 
  assign  resp_queue_wrdata[3]     =  1'b0;   // -- spare
  assign  resp_queue_wrdata[2]     =  tlx_afu_resp_valid_retry_q;
  assign  resp_queue_wrdata[1]     =  tlx_afu_resp_valid_no_data_q;
  assign  resp_queue_wrdata[0]     =  tlx_afu_resp_valid_with_data_q;

  // -- Response queue array
  mcp3_ram128x036q  response_queue
    ( .clk   ( clock_tlx ),

      .wren  ( resp_queue_wren ),
      .wrad  ( resp_queue_wraddr_q[6:0] ),
      .data  ( resp_queue_wrdata[35:0] ),

      .rden  ( resp_queue_rden ),
      .rdad  ( resp_queue_rdaddr[6:0] ),
      .q     ( resp_queue_rddata[35:0] )
    );

  // -- Always reading the queue when not empty, not blocked, and only on even clock cycles
  assign  resp_queue_func_rden        =  ( ~resp_queue_empty && ~reset && ~resp_queue_func_rden_blocker && even_q );
  assign  resp_queue_func_rden_dly1_d =  resp_queue_func_rden;
  assign  resp_queue_func_rden_dly2_d =  resp_queue_func_rden_dly1_q; 
  assign  resp_queue_func_rden_dly3_d =  resp_queue_func_rden_dly2_q; 
  assign  resp_queue_func_rden_dly4_d =  resp_queue_func_rden_dly3_q;

  // -- OR the func_rden w/ display_rden - resp_queue_display sequencer responsible for ensuring no collision
  assign  resp_queue_rden =  ( resp_queue_func_rden || resp_queue_display_rden );

  // -- Choose functional vs display address to assert on read
  always @*
    begin
      if ( resp_queue_display_rden )
        resp_queue_rdaddr[6:0] =  resp_queue_display_rdaddr[6:0];
      else
        resp_queue_rdaddr[6:0] =  resp_queue_rdaddr_q[6:0];
    end  // -- always @*


  // --assign  resp_queue_rd_sel[2:0] = { reset, resp_queue_func_rden, resp_queue_last_rdaddr };

  // --always @*
  // --  begin
  // --    casez ( resp_queue_rd_sel[2:0] )
  // --      //
  // --      // --  reset
  // --      // --  |resp_queue_func_rden
  // --      // --  ||resp_queue_last_rdaddr
  // --      // --  |||
  // --      // --------------------------------------------------------------------------------------------------------
  // --          3'b1?? :  resp_queue_rdaddr_d[7:0] =  {                    1'b0,                      7'b0           };  // -- reset
  // --          3'b010 :  resp_queue_rdaddr_d[7:0] =  {  resp_queue_rdaddr_q[7], ( resp_queue_rdaddr_q[6:0] + 7'b1 ) };  // -- write into the queue, NOT last wraddr, increment
  // --          3'b011 :  resp_queue_rdaddr_d[7:0] =  { ~resp_queue_rdaddr_q[7],                      7'b0           };  // -- write into the queue, last wraddr, flip toggle bit, wrap back to zero
  // --      // --------------------------------------------------------------------------------------------------------
  // --          default:  resp_queue_rdaddr_d[7:0] =  {  resp_queue_rdaddr_q[7],   resp_queue_rdaddr_q[6:0]          };  // -- Hold current value
  // --      // --------------------------------------------------------------------------------------------------------
  // --     endcase
  // --  end  // -- always @*


  always @*
    begin
      if ( reset )
        resp_queue_rdaddr_d[7:0] =  8'b0;                                                              // -- reset
      else if ( resp_queue_func_rden && ~resp_queue_last_rdaddr )
        resp_queue_rdaddr_d[7:0] =  {  resp_queue_rdaddr_q[7], ( resp_queue_rdaddr_q[6:0] + 7'b1 ) };  // -- read from the queue, NOT last rdaddr, increment
      else if ( resp_queue_func_rden &&  resp_queue_last_rdaddr )
        resp_queue_rdaddr_d[7:0] =  { ~resp_queue_rdaddr_q[7], 7'b0 };                                 // -- read from the queue, last rdaddr, flip toggle bit, wrap back to zero
      else
        resp_queue_rdaddr_d[7:0] =  resp_queue_rdaddr_q[7:0];                                          // -- Hold current value
    end  // -- always @*


  // -- form the read data coming out of the array
  assign  resp_queue_dp[1:0]         =  resp_queue_rddata[35:34];
  assign  resp_queue_dl[1:0]         =  resp_queue_rddata[33:32];
  assign  resp_queue_code[3:0]       =  resp_queue_rddata[31:28];
  assign  resp_queue_opcode[7:0]     =  resp_queue_rddata[27:20];
  assign  resp_queue_afutag[15:0]    =  resp_queue_rddata[19:4];
  assign  resp_queue_spare           =  resp_queue_rddata[3];
  assign  resp_queue_valid_retry     =  resp_queue_rddata[2];
  assign  resp_queue_valid_no_data   =  resp_queue_rddata[1];
  assign  resp_queue_valid_with_data =  resp_queue_rddata[0];

  // -- Compare the output of the queue with what is in stg1 to determine if rden should be blocked
  // --   Case 1: Stg1 is valid with data = 256B and response out of the array also has data
  // --   Case 2: Stg1 is valid with data = 256B and response out of the array also has no data, but matches the same engine as in stg1
  assign  resp_queue_func_rden_blocker = ( resp_valid_with_data_stg1_q && ( resp_dl_stg1_q[1:0] == 2'b11 ) && resp_queue_func_rden_dly2_q &&
                                         ( resp_queue_valid_with_data ||
                                         ( resp_queue_valid_no_data && ( resp_queue_afutag[10:5] == resp_afutag_stg1_q[10:5] ))));

  assign  resp_queue_func_rden_blocker_dly1_d =  resp_queue_func_rden_blocker; 
  assign  resp_queue_func_rden_blocker_dly2_d =  resp_queue_func_rden_blocker_dly1_q;
  assign  resp_queue_func_rden_blocker_dly3_d =  resp_queue_func_rden_blocker_dly2_q;


  // -- ******************************************************************************************************************************************
  // -- Determine number of Entries in the Response Queue  
  // -- ******************************************************************************************************************************************

  assign  resp_queue_size[7:0] =  8'h80;

  // -- Determine if the Write pointer has wrapped or not
  assign  resp_queue_wrap_match =  ( resp_queue_rdaddr_q[7] == resp_queue_wraddr_q[7] );

  // -- Calculate number of entries assuming no wrap
  assign  resp_queue_tl_mn_hd[7:0]          =  ( { 1'b0, resp_queue_wraddr_q[6:0] } - { 1'b0, resp_queue_rdaddr_q[6:0] } );

  // -- Calculate number of entries assuming a wrap
  assign  resp_queue_tl_pl_arysz_mn_hd[7:0] =  ( { 1'b0, resp_queue_wraddr_q[6:0] } + ( resp_queue_size[7:0] - { 1'b0, resp_queue_rdaddr_q[6:0] } ));

  always @*
    begin
      // -- Choose the correct number of entries calculated above
      if ( resp_queue_wrap_match )
        resp_queue_numentriesval_d[7:0] =  resp_queue_tl_mn_hd[7:0];
      else
        resp_queue_numentriesval_d[7:0] =  resp_queue_tl_pl_arysz_mn_hd[7:0];

      // -- Track Maximum number of Valid Entries
      if ( reset || mmio_rspi_resp_queue_maxqdepth_reset )
        resp_queue_maxqdepth_d[7:0] =  8'b0;
      else if  ( resp_queue_numentriesval_q[7:0] > resp_queue_maxqdepth_q[7:0] )
        resp_queue_maxqdepth_d[7:0] =  resp_queue_numentriesval_q[7:0];
      else
        resp_queue_maxqdepth_d[7:0] =  resp_queue_maxqdepth_q[7:0];

    end  // -- always @*

  // -- Send to mmio partition for logging
  assign  rspi_mmio_resp_queue_maxqdepth[7:0] =  resp_queue_maxqdepth_q[7:0];


  // -- ******************************************************************************************************************************************
  // -- Based upon the read output of the queue and the current state of stg1 and stg2 latches, determine if bypasses can be taken
  // -- ******************************************************************************************************************************************

  // -- Determine if stg1 latches can be bypassed
  assign  normal_stg1_bypass_eligible_nxt_d = 
     ( normal_stg1_bypass_disable_d == 1'b0 ) &&  // -- normal stg1 bypss is enabled
     ( resp_queue_valid_no_data_d   == 1'b1 ) &&  // -- Valid w/ no data out of the resp queue array output
     ( resp_queue_func_rden_dly3_d  == 1'b1 ) &&  // -- Qualify valid with the fact that rden was asserted 3 cycles ago
     ( resp_valid_with_data_stg1_q  == 1'b0 ) &&  // -- Nothing Valid in the Stg1 latches  // -- HW412187
     ( resp_valid_no_data_stg1_q    == 1'b0 );    // -- Nothing Valid in the Stg1 latches  // -- HW412187
//-- ( resp_valid_no_data_stg1_q    == 1'b0 ) &&  // -- Nothing Valid in the Stg1 latches
//--(( resp_valid_with_data_stg2_q  == 1'b0 )                                         ||  // -- No Valid Response || Valid response with no data currently in the stg2 latches ||
//--(( resp_valid_with_data_stg2_q  == 1'b1 ) && ( resp_dl_stg2_q[1:0] != 2'b11 ))    ||  // -- Valid Response with data in Stg2, but its ! 256B ||
//--(( resp_valid_with_data_stg2_q  == 1'b1 ) && ( resp_dl_stg2_q[1:0] == 2'b11 ) &&      // -- Valid Response with data in Stg2, and it IS 256B, BUT ... 
//-- ( resp_queue_afutag_q[10:5]    != resp_afutag_stg2_q[10:5] )));                         // -- Current response doesn't have data && not to same engine

  assign  normal_stg1_bypass_eligible =  normal_stg1_bypass_eligible_nxt_q;
 

  // -- Determine if stg1 & stg2 latches can be bypassed
  assign  normal_stg2_bypass_eligible_nxt_d = 
     ( normal_stg2_bypass_disable_q == 1'b0 ) &&  // -- normal stg2 bypss is enabled
     ( resp_queue_valid_no_data_q   == 1'b1 ) &&  // -- Valid w/ no data out of the resp queue array output
     ( resp_queue_func_rden_dly3_q  == 1'b1 ) &&  // -- Qualify valid with the fact that rden was asserted 2 cycles ago
     ( resp_valid_with_data_stg2_q  == 1'b0 ) &&  // -- Nothing Valid in the Stg2 latches (OK if Stg1 latches DO have valid response)
     ( resp_valid_no_data_stg2_q    == 1'b0 );    // -- Nothing Valid in the Stg2 latches (OK if Stg1 latches DO have valid response)
//-- ( resp_valid_no_data_stg2_q    == 1'b0 ) &&  // -- Nothing Valid in the Stg2 latches (OK if Stg1 latches DO have valid response)
//--(( resp_valid_with_data_stg3_q  == 1'b0 )                                        ||  // -- No Valid Response || Valid response with no data currently in the stg2 latches ||
//--(( resp_valid_with_data_stg3_q  == 1'b1 ) && (resp_dl_stg3_q[1:0] != 2'b11 ))    ||  // -- Valid Response with data in Stg3, but its ! 256B ||
//--(( resp_valid_with_data_stg3_q  == 1'b1 ) && (resp_dl_stg3_q[1:0] == 2'b11 ) &&      // -- Valid Response with data in Stg3, and it IS 256B, BUT ... 
//-- ( resp_queue_afutag_q[10:5]    != resp_afutag_stg3_q[10:5] )));                        // -- Current response doesn't have data && not to same engine

  assign  normal_stg2_bypass_eligible =  normal_stg2_bypass_eligible_nxt_q;


  assign  normal_stg2_bypass_taken =    normal_stg2_bypass_eligible;
  assign  normal_stg1_bypass_taken =  ( normal_stg1_bypass_eligible && ~normal_stg2_bypass_eligible );


  // -- ******************************************************************************************************************************************
  // -- Stg0/Resp_Queue Latches (clocked by TLX clock) - 1st stage of latching out of the queue 
  // -- ******************************************************************************************************************************************

  always @*
    begin
      if ( fastpath_queue_bypass_taken )
        begin
          resp_queue_valid_with_data_d =  tlx_afu_resp_valid_with_data_q;
          resp_queue_valid_no_data_d   =  tlx_afu_resp_valid_no_data_q;
          resp_queue_valid_retry_d     =  tlx_afu_resp_valid_retry_q;
          resp_queue_spare_d           =  1'b0;
          resp_queue_afutag_d[15:0]    =  tlx_afu_resp_afutag_q[15:0];
          resp_queue_opcode_d[7:0]     =  tlx_afu_resp_opcode_q[7:0];
          resp_queue_code_d[3:0]       =  tlx_afu_resp_code_q[3:0];
          resp_queue_dl_d[1:0]         =  tlx_afu_resp_dl_q[1:0];
          resp_queue_dp_d[1:0]         =  tlx_afu_resp_dp_q[1:0]; 
        end
      else
        begin
          resp_queue_valid_with_data_d =  ( resp_queue_valid_with_data && resp_queue_func_rden_dly2_q );
          resp_queue_valid_no_data_d   =  ( resp_queue_valid_no_data   && resp_queue_func_rden_dly2_q );
          resp_queue_valid_retry_d     =  ( resp_queue_valid_retry     && resp_queue_func_rden_dly2_q ); 
          resp_queue_spare_d           =  resp_queue_spare;
          resp_queue_afutag_d[15:0]    =  resp_queue_afutag[15:0];
          resp_queue_opcode_d[7:0]     =  resp_queue_opcode[7:0];
          resp_queue_code_d[3:0]       =  resp_queue_code[3:0];
          resp_queue_dl_d[1:0]         =  resp_queue_dl[1:0];
          resp_queue_dp_d[1:0]         =  resp_queue_dp[1:0];    
        end
    end  // -- always @*


  // -- ******************************************************************************************************************************************
  // -- Stg1 Latches (clocked by AFU clock) - 1st stage of AFU clocked latching out of the queue 
  // -- ******************************************************************************************************************************************

  always @*
    begin
      if ( resp_queue_func_rden_blocker_dly3_q )
        begin
          resp_valid_with_data_stg1_d =  resp_valid_with_data_stg1_q;
          resp_valid_no_data_stg1_d   =  resp_valid_no_data_stg1_q;
          resp_valid_retry_stg1_d     =  resp_valid_retry_stg1_q;
          resp_spare_stg1_d           =  resp_spare_stg1_q;
          resp_afutag_stg1_d[15:0]    =  resp_afutag_stg1_q[15:0];
          resp_opcode_stg1_d[7:0]     =  resp_opcode_stg1_q[7:0];
          resp_code_stg1_d[3:0]       =  resp_code_stg1_q[3:0];
          resp_dl_stg1_d[1:0]         =  resp_dl_stg1_q[1:0];
          resp_dp_stg1_d[1:0]         =  resp_dp_stg1_q[1:0]; 
        end
      else if ( fastpath_stg0_bypass_taken )
        begin
          resp_valid_with_data_stg1_d =  tlx_afu_resp_valid_with_data_q;
          resp_valid_no_data_stg1_d   =  tlx_afu_resp_valid_no_data_q;
          resp_valid_retry_stg1_d     =  tlx_afu_resp_valid_retry_q;
          resp_spare_stg1_d           =  1'b0;
          resp_afutag_stg1_d[15:0]    =  tlx_afu_resp_afutag_q[15:0];
          resp_opcode_stg1_d[7:0]     =  tlx_afu_resp_opcode_q[7:0];
          resp_code_stg1_d[3:0]       =  tlx_afu_resp_code_q[3:0];
          resp_dl_stg1_d[1:0]         =  tlx_afu_resp_dl_q[1:0];
          resp_dp_stg1_d[1:0]         =  tlx_afu_resp_dp_q[1:0]; 
        end
      else
        begin
          resp_valid_with_data_stg1_d =  ( resp_queue_valid_with_data_q && ~normal_stg1_bypass_taken && ~normal_stg2_bypass_taken );
          resp_valid_no_data_stg1_d   =  ( resp_queue_valid_no_data_q   && ~normal_stg1_bypass_taken && ~normal_stg2_bypass_taken );
          resp_valid_retry_stg1_d     =  ( resp_queue_valid_retry_q     && ~normal_stg1_bypass_taken && ~normal_stg2_bypass_taken ); 
          resp_spare_stg1_d           =  resp_queue_spare_q;
          resp_afutag_stg1_d[15:0]    =  resp_queue_afutag_q[15:0];
          resp_opcode_stg1_d[7:0]     =  resp_queue_opcode_q[7:0];
          resp_code_stg1_d[3:0]       =  resp_queue_code_q[3:0];
          resp_dl_stg1_d[1:0]         =  resp_queue_dl_q[1:0];
          resp_dp_stg1_d[1:0]         =  resp_queue_dp_q[1:0];    
        end
    end  // -- always @*


  // -- ******************************************************************************************************************************************
  // -- Stg2 Latches (clocked by AFU clock)
  // -- ******************************************************************************************************************************************

  always @*
    begin
      if ( fastpath_stg1_bypass_taken )
        begin
          resp_valid_with_data_stg2_d =  tlx_afu_resp_valid_with_data_q;
          resp_valid_no_data_stg2_d   =  tlx_afu_resp_valid_no_data_q;
          resp_valid_retry_stg2_d     =  tlx_afu_resp_valid_retry_q;
          resp_spare_stg2_d           =  1'b0;
          resp_afutag_stg2_d[15:0]    =  tlx_afu_resp_afutag_q[15:0];
          resp_opcode_stg2_d[7:0]     =  tlx_afu_resp_opcode_q[7:0];
          resp_code_stg2_d[3:0]       =  tlx_afu_resp_code_q[3:0];
          resp_dl_stg2_d[1:0]         =  tlx_afu_resp_dl_q[1:0];
          resp_dp_stg2_d[1:0]         =  tlx_afu_resp_dp_q[1:0]; 
        end
      else if ( normal_stg1_bypass_taken )
        begin
          resp_valid_with_data_stg2_d =  resp_queue_valid_with_data_q;
          resp_valid_no_data_stg2_d   =  resp_queue_valid_no_data_q;
          resp_valid_retry_stg2_d     =  resp_queue_valid_retry_q; 
          resp_spare_stg2_d           =  resp_queue_spare_q; 
          resp_afutag_stg2_d[15:0]    =  resp_queue_afutag_q[15:0];
          resp_opcode_stg2_d[7:0]     =  resp_queue_opcode_q[7:0];
          resp_code_stg2_d[3:0]       =  resp_queue_code_q[3:0];
          resp_dl_stg2_d[1:0]         =  resp_queue_dl_q[1:0];
          resp_dp_stg2_d[1:0]         =  resp_queue_dp_q[1:0];    
        end
      else
        begin
          resp_valid_with_data_stg2_d =  ( resp_valid_with_data_stg1_q && ~resp_queue_func_rden_blocker_dly3_q );
          resp_valid_no_data_stg2_d   =  ( resp_valid_no_data_stg1_q   && ~resp_queue_func_rden_blocker_dly3_q );
          resp_valid_retry_stg2_d     =  ( resp_valid_retry_stg1_q     && ~resp_queue_func_rden_blocker_dly3_q );
          resp_spare_stg2_d           =  resp_spare_stg1_q; 
          resp_afutag_stg2_d[15:0]    =  resp_afutag_stg1_q[15:0];
          resp_opcode_stg2_d[7:0]     =  resp_opcode_stg1_q[7:0];
          resp_code_stg2_d[3:0]       =  resp_code_stg1_q[3:0];
          resp_dl_stg2_d[1:0]         =  resp_dl_stg1_q[1:0];
          resp_dp_stg2_d[1:0]         =  resp_dp_stg1_q[1:0]; 
        end
    end  // -- always @*


  // -- ******************************************************************************************************************************************
  // -- Stg3 Latches (clocked by AFU clock) - These latch outputs are driven to the engines
  // -- ******************************************************************************************************************************************

  always @*
    begin
      if ( fastpath_stg2_bypass_taken )
        begin
          resp_valid_with_data_stg3_d =  tlx_afu_resp_valid_with_data_q;
          resp_valid_no_data_stg3_d   =  tlx_afu_resp_valid_no_data_q;
          resp_valid_retry_stg3_d     =  tlx_afu_resp_valid_retry_q;
          resp_spare_stg3_d           =  1'b0;
          resp_afutag_stg3_d[15:0]    =  tlx_afu_resp_afutag_q[15:0];
          resp_opcode_stg3_d[7:0]     =  tlx_afu_resp_opcode_q[7:0];
          resp_code_stg3_d[3:0]       =  tlx_afu_resp_code_q[3:0];
          resp_dl_stg3_d[1:0]         =  tlx_afu_resp_dl_q[1:0];
          resp_dp_stg3_d[1:0]         =  tlx_afu_resp_dp_q[1:0]; 
        end
      else if ( normal_stg2_bypass_taken )
        begin
          resp_valid_with_data_stg3_d =  resp_queue_valid_with_data_q;
          resp_valid_no_data_stg3_d   =  resp_queue_valid_no_data_q;
          resp_valid_retry_stg3_d     =  resp_queue_valid_retry_q; 
          resp_spare_stg3_d           =  resp_queue_spare_q;
          resp_afutag_stg3_d[15:0]    =  resp_queue_afutag_q[15:0];
          resp_opcode_stg3_d[7:0]     =  resp_queue_opcode_q[7:0];
          resp_code_stg3_d[3:0]       =  resp_queue_code_q[3:0];
          resp_dl_stg3_d[1:0]         =  resp_queue_dl_q[1:0];
          resp_dp_stg3_d[1:0]         =  resp_queue_dp_q[1:0];    
        end
      else
        begin
          resp_valid_with_data_stg3_d =  resp_valid_with_data_stg2_q;
          resp_valid_no_data_stg3_d   =  resp_valid_no_data_stg2_q;
          resp_valid_retry_stg3_d     =  resp_valid_retry_stg2_q;
          resp_spare_stg3_d           =  resp_spare_stg2_q;
          resp_afutag_stg3_d[15:0]    =  resp_afutag_stg2_q[15:0];
          resp_opcode_stg3_d[7:0]     =  resp_opcode_stg2_q[7:0];
          resp_code_stg3_d[3:0]       =  resp_code_stg2_q[3:0];
          resp_dl_stg3_d[1:0]         =  resp_dl_stg2_q[1:0];
          resp_dp_stg3_d[1:0]         =  resp_dp_stg2_q[1:0]; 
        end
    end  // -- always @*


  // -- ********************************************************************************************************************************
  // -- Send read request to TLX for responses with data
  // -- ********************************************************************************************************************************

// --  assign  tlx_afu_resp_dl_cpy_d[1:0]      =  tlx_afu_resp_dl[1:0];   // -- Timing Fix   // -- JAK - 07/19/18 - HW455967

  always @*
    begin
      if ( fastpath_queue_bypass_possible )
        tlx_afu_resp_dl_cpy_d[1:0]        =  tlx_afu_resp_dl_q[1:0]; // -- JAK - 07/19/18 - HW455967
      else
        tlx_afu_resp_dl_cpy_d[1:0]        =  tlx_afu_resp_dl[1:0];   // -- JAK - 07/19/18 - HW455967
    end  // -- always @*

  assign  resp_dl_stg1_cpy_d[1:0]         =  resp_dl_stg1_d[1:0];    // -- Timing Fix

  assign  afu_tlx_resp_rd_req_d  =  fastpath_queue_bypass_taken ||
                                  ( resp_queue_func_rden_dly2_q && resp_queue_valid_with_data  && ~resp_queue_func_rden_blocker ) || 
                                  ( resp_queue_func_rden_dly4_q && resp_valid_with_data_stg1_q &&  resp_queue_func_rden_blocker_dly2_q );

  assign  afu_tlx_resp_rd_req =  afu_tlx_resp_rd_req_d;

  assign  tlx_afu_resp_rd_cnt[2:0] =  { 1'b0, tlx_afu_resp_dl_cpy_q[1:0] };
  assign  resp_queue_rd_cnt[2:0]   =  { 1'b0,         resp_queue_dl[1:0] };
  assign  resp_rd_cnt_stg1[2:0]    =  { 1'b0,    resp_dl_stg1_cpy_q[1:0] }; 

  always @*
    begin
      if ( fastpath_queue_bypass_taken )
        afu_tlx_resp_rd_cnt_d[2:0] =  tlx_afu_resp_rd_cnt[2:0];
      else if ( resp_queue_func_rden_dly2_q && resp_queue_valid_with_data  && ~resp_queue_func_rden_blocker )
        afu_tlx_resp_rd_cnt_d[2:0] =  resp_queue_rd_cnt[2:0];
      else if ( resp_queue_func_rden_dly4_q && resp_valid_with_data_stg1_q &&  resp_queue_func_rden_blocker_dly2_q )
        afu_tlx_resp_rd_cnt_d[2:0] =  resp_rd_cnt_stg1[2:0];
      else
        afu_tlx_resp_rd_cnt_d[2:0] =  3'b0;

    end  // -- always @*

 assign  afu_tlx_resp_rd_cnt[2:0] =  afu_tlx_resp_rd_cnt_d[2:0];


  // -- ********************************************************************************************************************************
  // -- get the data back from TLX and move it to stage 3
  // -- ********************************************************************************************************************************

  // -- capture valid in TLX clock domain and delay it
  assign  tlx_afu_resp_data_valid_dly1_d =  tlx_afu_resp_data_valid;          // -- in dly1 on even cycle 
  assign  tlx_afu_resp_data_valid_dly2_d =  tlx_afu_resp_data_valid_dly1_q;   // -- in dly2 on odd cycle

  assign  tlx_afu_resp_data_bdi_dly1_d =  tlx_afu_resp_data_bdi;          // -- in dly1 on even cycle 
  assign  tlx_afu_resp_data_bdi_dly2_d =  tlx_afu_resp_data_bdi_dly1_q;   // -- in dly2 on odd cycle

  // -- capture 64B data in TLX clock domain and delay it
  assign  tlx_afu_resp_data_bus_dly1_d[511:0] =  tlx_afu_resp_data_bus[511:0];        
  assign  tlx_afu_resp_data_bus_dly2_d[511:0] =  tlx_afu_resp_data_bus_dly1_q[511:0]; 


  // -- capture valid in the AFU clock domain
  assign  resp_data_valid_stg3_d =  tlx_afu_resp_data_valid_dly2_q;

  assign  resp_data_bdi_stg3_d[1:0]    =  { tlx_afu_resp_data_bdi_dly1_q,
                                            tlx_afu_resp_data_bdi_dly2_q };

  // -- capture 128B data in the AFU clock domain
  assign  resp_data_bus_stg3_d[1023:0] =  { tlx_afu_resp_data_bus_dly1_q[511:0],    // -- Data Hi
                                            tlx_afu_resp_data_bus_dly2_q[511:0] };  // -- Data Lo


  // -- ********************************************************************************************************************************
  // -- Drive the interface back to the engines
  // -- ********************************************************************************************************************************

  // -- create a 1-hot engine decode vector in stg2
//     mcp3_decoder5x032  resp_engine_decoder
//    (
//      .din    ( resp_afutag_stg3_d[9:5] ),
//      .dout   ( resp_engine_stg2[31:0] )
//    );


  // -- Decode Engine to create a 1-hot engine decode valid vector in stg2 and latch into stg3
  always @*
    begin
      if ( resp_valid_with_data_stg3_d || resp_valid_no_data_stg3_d )
        resp_valid_stg3_d =  1'b1;   //resp_engine_stg2[31:0];
      else
        resp_valid_stg3_d =  1'b0;

    end  // -- always @*

  assign  rspi_eng_resp_valid        =  resp_valid_stg3_q;
  assign  rspi_eng_resp_afutag[15:0] =  resp_afutag_stg3_q[15:0];
  assign  rspi_eng_resp_opcode[7:0]  =  resp_opcode_stg3_q[7:0];
  assign  rspi_eng_resp_code[3:0]    =  resp_code_stg3_q[3:0];   
  assign  rspi_eng_resp_dl[1:0]      =  resp_dl_stg3_q[1:0];   
  assign  rspi_eng_resp_dp[1:0]      =  resp_dp_stg3_q[1:0];

  assign  rspi_eng_resp_data_valid       =  resp_data_valid_stg3_q;
  assign  rspi_eng_resp_data_bdi[1:0]    =  resp_data_bdi_stg3_q[1:0];
  assign  rspi_eng_resp_data_bus[1023:0] =  resp_data_bus_stg3_q[1023:0];


  // -- ********************************************************************************************************************************
  // -- Return a response credit to TLX
  // -- ********************************************************************************************************************************

  // -- Tell TLX how many responses that the AFU can buffer 
  assign  afu_tlx_resp_initial_credit[6:0]  =  7'b1111111;  // -- allow 127 responses outstanding

  // -- prepare to return a credit to TLX as each response is forwarded to the engines
  assign  return_resp_credit_to_tlx_d =  (( resp_valid_with_data_stg3_d || resp_valid_no_data_stg3_d ) && odd_q );

  assign  afu_tlx_resp_credit =  return_resp_credit_to_tlx_q;  // -- drive off a latch in the TLX clock domain


  // -- ********************************************************************************************************************************
  // -- Track cmds sent vs responses received
  // -- ********************************************************************************************************************************

  // -- Not sure if this is needed or not anymore (MemCpy 2.0 needed to determine when quiesced for its error handling state machine) 
  // -- Need to factor that responses can be split
  // -- increase count by 1,2,4 when dispatched
  // -- decrease count by 1,2,4 when response received
  // -- don't count assign_actag cmds

  // -- snoop outgoing commands
  assign  cmdo_rspi_cmd_opcode_is_rd_wnitc      =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_RD_WNITC[7:0]      );
  assign  cmdo_rspi_cmd_opcode_is_rd_wnitc_n    =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_RD_WNITC_N[7:0]    );
  assign  cmdo_rspi_cmd_opcode_is_dma_w         =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_DMA_W[7:0]         );
  assign  cmdo_rspi_cmd_opcode_is_dma_w_n       =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_DMA_W_N[7:0]       );
  assign  cmdo_rspi_cmd_opcode_is_dma_pr_w      =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_DMA_PR_W[7:0]      );
  assign  cmdo_rspi_cmd_opcode_is_dma_pr_w_n    =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_DMA_PR_W_N[7:0]    );
  assign  cmdo_rspi_cmd_opcode_is_dma_w_be      =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_DMA_W_BE[7:0]      );
  assign  cmdo_rspi_cmd_opcode_is_dma_w_be_n    =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_DMA_W_BE_N[7:0]    );
  assign  cmdo_rspi_cmd_opcode_is_intrp_req     =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_INTRP_REQ[7:0]     );
  assign  cmdo_rspi_cmd_opcode_is_intrp_req_d   =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_INTRP_REQ_D[7:0]   );
  assign  cmdo_rspi_cmd_opcode_is_xlate_touch   =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_XLATE_TOUCH[7:0]   );
  assign  cmdo_rspi_cmd_opcode_is_xlate_touch_n =  ( cmdo_rspi_cmd_opcode[7:0] ==  AFU_TLX_CMD_ENCODE_XLATE_TOUCH_N[7:0] );

  assign  cmdo_rspi_cmd_valid_d =  cmdo_rspi_cmd_valid;

  assign  add_4_d =  ((( cmdo_rspi_cmd_opcode_is_rd_wnitc    || cmdo_rspi_cmd_opcode_is_rd_wnitc_n    ) && ( cmdo_rspi_cmd_dl[1:0] == 2'b11 )) ||  // -- 256B Read Cmd
                      (( cmdo_rspi_cmd_opcode_is_dma_w       || cmdo_rspi_cmd_opcode_is_dma_w_n       ) && ( cmdo_rspi_cmd_dl[1:0] == 2'b11 )));   // -- 256B Write Cmd

  assign  add_2_d =  ((( cmdo_rspi_cmd_opcode_is_rd_wnitc    || cmdo_rspi_cmd_opcode_is_rd_wnitc_n    ) && ( cmdo_rspi_cmd_dl[1:0] == 2'b10 )) ||  // -- 128B Read Cmd
                      (( cmdo_rspi_cmd_opcode_is_dma_w       || cmdo_rspi_cmd_opcode_is_dma_w_n       ) && ( cmdo_rspi_cmd_dl[1:0] == 2'b10 )));   // -- 128B Write Cmd

  assign  add_1_d =  ((( cmdo_rspi_cmd_opcode_is_rd_wnitc    || cmdo_rspi_cmd_opcode_is_rd_wnitc_n    ) && ( cmdo_rspi_cmd_dl[1:0] == 2'b01 )) ||  // --  64B Read Cmd
                      (( cmdo_rspi_cmd_opcode_is_dma_w       || cmdo_rspi_cmd_opcode_is_dma_w_n       ) && ( cmdo_rspi_cmd_dl[1:0] == 2'b01 )) ||  // --  64B Write Cmd
                       ( cmdo_rspi_cmd_opcode_is_dma_pr_w    || cmdo_rspi_cmd_opcode_is_dma_pr_w_n    )                                        ||  // -- <64B Partial Write Cmd
                       ( cmdo_rspi_cmd_opcode_is_dma_w_be    || cmdo_rspi_cmd_opcode_is_dma_w_be_n    )                                        ||  // -- <64B Write Cmd (BE)
                       ( cmdo_rspi_cmd_opcode_is_intrp_req   || cmdo_rspi_cmd_opcode_is_intrp_req_d   )                                        ||  // --  Interrupt Cmd
                       ( cmdo_rspi_cmd_opcode_is_xlate_touch || cmdo_rspi_cmd_opcode_is_xlate_touch_n ));                                          // --  xlate touch Cmd

  assign  add_0_d = ( ~add_4_d && ~add_2_d && ~add_1_d );

  // -- snoop inbound responses
  assign  stg2_resp_is_read_response  =  ( resp_opcode_stg3_d[7:0] ==  TLX_AFU_RESP_ENCODE_READ_RESPONSE[7:0]  );
  assign  stg2_resp_is_read_failed    =  ( resp_opcode_stg3_d[7:0] ==  TLX_AFU_RESP_ENCODE_READ_FAILED[7:0]    );
  assign  stg2_resp_is_write_response =  ( resp_opcode_stg3_d[7:0] ==  TLX_AFU_RESP_ENCODE_WRITE_RESPONSE[7:0] );
  assign  stg2_resp_is_write_failed   =  ( resp_opcode_stg3_d[7:0] ==  TLX_AFU_RESP_ENCODE_WRITE_FAILED[7:0]   );
  assign  stg2_resp_is_intrp_rdy      =  ( resp_opcode_stg3_d[7:0] ==  TLX_AFU_RESP_ENCODE_INTRP_RDY[7:0]      );
  assign  stg2_resp_is_xlate_done     =  ( resp_opcode_stg3_d[7:0] ==  TLX_AFU_RESP_ENCODE_XLATE_DONE[7:0]     );
  assign  stg2_resp_is_touch_resp     =  ( resp_opcode_stg3_d[7:0] ==  TLX_AFU_RESP_ENCODE_TOUCH_RESP[7:0]     );

  assign  stg2_resp_is_read_or_write  =  ( resp_valid_with_data_stg3_d || resp_valid_no_data_stg3_d) &&
                                         ( stg2_resp_is_read_response  ||
                                           stg2_resp_is_read_failed    ||
                                           stg2_resp_is_write_response ||
                                           stg2_resp_is_write_failed );


  assign  sub_4_d =  (( stg2_resp_is_read_or_write && ( resp_dl_stg3_d[1:0] == 2'b11 )) || ( stg2_resp_is_xlate_done && ( resp_afutag_stg3_d[15:14] == 2'b11)));
  assign  sub_2_d =  (( stg2_resp_is_read_or_write && ( resp_dl_stg3_d[1:0] == 2'b10 )) || ( stg2_resp_is_xlate_done && ( resp_afutag_stg3_d[15:14] == 2'b10)));
//--sign  sub_1_d =  (( stg2_resp_is_read_or_write && ( resp_dl_stg3_d[1]   == 1'b0  )) || ( stg2_resp_is_xlate_done && ( resp_afutag_stg3_d[15]    == 1'b0 )) || stg2_resp_is_intrp_rdy || stg2_resp_is_touch_resp);
  assign  sub_1_d =  (( stg2_resp_is_read_or_write && ( resp_dl_stg3_d[1]   == 1'b0  )) ||
                      ( resp_valid_no_data_stg3_d &&
                      (( stg2_resp_is_xlate_done && ( resp_afutag_stg3_d[15] == 1'b0 )) || stg2_resp_is_intrp_rdy || stg2_resp_is_touch_resp )));

  assign  sub_0_d = ( ~sub_4_d && ~sub_2_d && ~sub_1_d );

  // -- pre-calculate all possibilities
  assign  outstanding_responses_add_4[11:0] =  ( outstanding_responses_q[11:0] + 12'h004 );
  assign  outstanding_responses_add_3[11:0] =  ( outstanding_responses_q[11:0] + 12'h003 );
  assign  outstanding_responses_add_2[11:0] =  ( outstanding_responses_q[11:0] + 12'h002 );
  assign  outstanding_responses_add_1[11:0] =  ( outstanding_responses_q[11:0] + 12'h001 );

  assign  outstanding_responses_sub_4[11:0] =  ( outstanding_responses_q[11:0] - 12'h004 );
  assign  outstanding_responses_sub_3[11:0] =  ( outstanding_responses_q[11:0] - 12'h003 );
  assign  outstanding_responses_sub_2[11:0] =  ( outstanding_responses_q[11:0] - 12'h002 );
  assign  outstanding_responses_sub_1[11:0] =  ( outstanding_responses_q[11:0] - 12'h001 );


  // -- only update the latches when either an outbound command is valid or a response is valid (or both), clear on reset
  assign  outstanding_responses_en =  ( cmdo_rspi_cmd_valid_q || resp_valid_with_data_stg3_q || resp_valid_no_data_stg3_q || reset );

  always @*
    begin
      outstanding_responses_d[11:0] =  outstanding_responses_q[11:0];
      if ( reset )
        outstanding_responses_d[11:0] = 12'b0;
      else 
        begin
        //----------------------------------------------------------------------------------------------
          if ( add_4_q && sub_4_q )  outstanding_responses_d[11:0] =  outstanding_responses_q[11:0]    ;  // -- +4-4 
          if ( add_2_q && sub_4_q )  outstanding_responses_d[11:0] =  outstanding_responses_sub_2[11:0];  // -- +2-4
          if ( add_1_q && sub_4_q )  outstanding_responses_d[11:0] =  outstanding_responses_sub_3[11:0];  // -- +1-4
          if ( add_0_q && sub_4_q )  outstanding_responses_d[11:0] =  outstanding_responses_sub_4[11:0];  // --  0-4
        //----------------------------------------------------------------------------------------------
          if ( add_4_q && sub_2_q )  outstanding_responses_d[11:0] =  outstanding_responses_add_2[11:0];  // -- +4-2
          if ( add_2_q && sub_2_q )  outstanding_responses_d[11:0] =  outstanding_responses_q[11:0]    ;  // -- +2-2
          if ( add_1_q && sub_2_q )  outstanding_responses_d[11:0] =  outstanding_responses_sub_1[11:0];  // -- +1-2
          if ( add_0_q && sub_2_q )  outstanding_responses_d[11:0] =  outstanding_responses_sub_2[11:0];  // --  0-2
        //----------------------------------------------------------------------------------------------
          if ( add_4_q && sub_1_q )  outstanding_responses_d[11:0] =  outstanding_responses_add_3[11:0];  // -- +4-1
          if ( add_2_q && sub_1_q )  outstanding_responses_d[11:0] =  outstanding_responses_add_1[11:0];  // -- +2-1
          if ( add_1_q && sub_1_q )  outstanding_responses_d[11:0] =  outstanding_responses_q[11:0]    ;  // -- +1-1
          if ( add_0_q && sub_1_q )  outstanding_responses_d[11:0] =  outstanding_responses_sub_1[11:0];  // --  0-1
        //----------------------------------------------------------------------------------------------
          if ( add_4_q && sub_0_q )  outstanding_responses_d[11:0] =  outstanding_responses_add_4[11:0];  // -- +4-0
          if ( add_2_q && sub_0_q )  outstanding_responses_d[11:0] =  outstanding_responses_add_2[11:0];  // -- +2-0
          if ( add_1_q && sub_0_q )  outstanding_responses_d[11:0] =  outstanding_responses_add_1[11:0];  // -- +1-0
          if ( add_0_q && sub_0_q )  outstanding_responses_d[11:0] =  outstanding_responses_q[11:0]    ;  // --  0-0
        //----------------------------------------------------------------------------------------------
        end


      // -- Track Maximum number of Outstanding_responses
      if ( reset || mmio_rspi_max_outstanding_responses_reset )
        max_outstanding_responses_d[11:0] =  12'b0;
      else if  ( outstanding_responses_q[11:0] > max_outstanding_responses_q[11:0] )
        max_outstanding_responses_d[11:0] =  outstanding_responses_q[11:0];
      else
        max_outstanding_responses_d[11:0] =  max_outstanding_responses_q[11:0];

    end  // -- always @*

  assign  quiesced =  ( outstanding_responses_q[11:0] == 12'b0 );

  assign  rspi_mmio_max_outstanding_responses[11:0] =  max_outstanding_responses_q[11:0];


  // -- ********************************************************************************************************************************
  // -- Send latched interface signals to the trace array for debug
  // -- ********************************************************************************************************************************

   assign  trace_tlx_afu_resp_valid_with_data  =  resp_valid_with_data_stg3_q;             
   assign  trace_tlx_afu_resp_valid_no_data    =  resp_valid_no_data_stg3_q;              
   assign  trace_tlx_afu_resp_valid_retry      =  resp_valid_retry_stg3_q;                
   assign  trace_tlx_afu_resp_afutag[15:0]     =  resp_afutag_stg3_q[15:0];         
   assign  trace_tlx_afu_resp_opcode[7:0]      =  resp_opcode_stg3_q[7:0];         
   assign  trace_tlx_afu_resp_code[3:0]        =  resp_code_stg3_q[3:0];           
   assign  trace_tlx_afu_resp_dl[1:0]          =  resp_dl_stg3_q[1:0];             
   assign  trace_tlx_afu_resp_dp[1:0]          =  resp_dp_stg3_q[1:0];             
// assign  trace_tlx_afu_resp_pg_size[5:0]     =  6'b0;
// assign  trace_tlx_afu_resp_addr_tag[17:0]   = 18'b0;
                                 
   assign  trace_afu_tlx_resp_rd_req           =  afu_tlx_resp_rd_req_q;
   assign  trace_afu_tlx_resp_rd_cnt[2:0]      =  afu_tlx_resp_rd_cnt_q[2:0];         
                                 
   assign  trace_tlx_afu_resp_data_valid       =  resp_data_valid_stg3_q; 
   assign  trace_tlx_afu_resp_data_bdi[1:0]    =  resp_data_bdi_stg3_q[1:0];         
// assign  trace_tlx_afu_resp_data_bus[511:0]

   assign  trace_afu_tlx_resp_credit           =  ( resp_valid_with_data_stg3_q || resp_valid_no_data_stg3_q );  // -- Credits always returned on even clock


  // -- ********************************************************************************************************************************
  // -- Display Read Interface
  // -- ********************************************************************************************************************************

  // -- Latch the inbound Display read request
  assign  mmio_rspi_display_rdval_d         =  mmio_rspi_display_rdval;

  // -- Capture and hold the address
  assign  mmio_rspi_display_addr_en         =  mmio_rspi_display_rdval;
  assign  mmio_rspi_display_addr_d[6:0]     =  mmio_rspi_display_addr[6:0];

  assign  resp_queue_display_rdaddr[6:0]    =  mmio_rspi_display_addr_q[6:0];

  // -- Form a blocker to avoid collision with functional usage of the resp queue
  assign  resp_queue_display_rden_blocker   = ( ~resp_queue_empty || even_q );


  // -- Determine if the Current State of the Sequencer is invalid
  mcp3_ohc05  resp_queue_display_seq_err (
    .one_hot_vector   ( resp_queue_display_seq_q[4:0] ),
    .one_hot_error    ( resp_queue_display_seq_error )
  );

  // -- Table Inputs
  always @*
    begin

      // -- Current State Assignments
      resp_queue_display_idle_st      =  resp_queue_display_seq_q[0];
      resp_queue_display_wait_st      =  resp_queue_display_seq_q[1];
      resp_queue_display_dly1_st      =  resp_queue_display_seq_q[2];
      resp_queue_display_dly2_st      =  resp_queue_display_seq_q[3];
      resp_queue_display_rddataval_st =  resp_queue_display_seq_q[4];

      // -- Inputs
      resp_queue_display_seq_sel[6:0] = { mmio_rspi_display_rdval_q, resp_queue_display_rden_blocker, resp_queue_display_seq_q[4:0] };

      casez ( resp_queue_display_seq_sel[6:0] )  // -- NOTE:  For casez usage, all case "items" must be mutually exclusive to prevent inferred priority
        // --
        // --
        // --  Inputs & Current State                        Outputs & Next State
        // --  ----------------------                        --------------------
        // --  mmio_resp_queue_display_rdval_q               resp_queue_display_rden
        // --  |resp_queue_display_rden_blocker              |resp_queue_display_rddata_capture
        // --  ||                                            ||resp_queue_display_rddata_valid
        // --  ||                                            |||
        // --  || resp_queue_display_seq_q                   ||| resp_queue_display_seq_d
        // --  || |                                          ||| |
        // --  65 43210                                      765 43210
        // -----------------------------------------------------------
            7'b0?_00001 :  resp_queue_display_seq[7:0] =  8'b000_00001 ;  // --      idle_st -> idle_st      - stay in idle until valid request
            7'b11_00001 :  resp_queue_display_seq[7:0] =  8'b000_00010 ;  // --      idle_st -> Wait_st      - Engine Enable in progress, need to wait until there is an opening
            7'b10_00001 :  resp_queue_display_seq[7:0] =  8'b100_00100 ;  // --      idle_st -> dly1_st      - No conflict with Engine Enable, Fwd Request to Eng in next cycle
        // -----------------------------------------------------------
            7'b?1_00010 :  resp_queue_display_seq[7:0] =  8'b000_00010 ;  // --      Wait_st -> Wait_st      - Engine Enable in progres, continue to wait until there is an opening
            7'b?0_00010 :  resp_queue_display_seq[7:0] =  8'b100_00100 ;  // --      Wait_st -> dly1_st      - No conflict with Engine Enable, Fwd Request to Eng in next cycle
        // -----------------------------------------------------------
            7'b??_00100 :  resp_queue_display_seq[7:0] =  8'b000_01000 ;  // --      dly1_st -> dly2_st      - No conflict with Engine Enable, Fwd Request to Eng in next cycle
        // -----------------------------------------------------------
            7'b??_01000 :  resp_queue_display_seq[7:0] =  8'b010_10000 ;  // --      dly2_st -> rddataval_st - No conflict with Engine Enable, Fwd Request to Eng in next cycle
        // -----------------------------------------------------------
            7'b??_10000 :  resp_queue_display_seq[7:0] =  8'b001_00001 ;  // -- rddataval_st -> idle_st      - No conflict with Engine Enable, Fwd Request to Eng in next cycle
        // -----------------------------------------------------------
            default     :  resp_queue_display_seq[7:0] =  8'b000_00001 ;  // --     default  -> idle_ST      (Needed to make case "full" to prevent inferred latches)
        // -----------------------------------------------------------  
      endcase

      // -- Outputs
      resp_queue_display_rden           =  resp_queue_display_seq[7];
      resp_queue_display_rddata_capture =  resp_queue_display_seq[6];
      resp_queue_display_rddata_valid   =  resp_queue_display_seq[5]; 

      // -- Next State
      resp_queue_display_seq_d[4:0] = ( reset || resp_queue_display_seq_error ) ? 5'b1 :  resp_queue_display_seq[4:0];

    end // -- always @ *                                  


  // -- Capture the Read Data out of the Read Queue
  assign  resp_queue_display_rddata_en      =  resp_queue_display_rddata_capture;
  assign  resp_queue_display_rddata_d[35:0] =  resp_queue_rddata[35:0];
  
  assign  rspi_mmio_display_rddata_valid =   resp_queue_display_rddata_valid;
  assign  rspi_mmio_display_rddata[63:0] =  { 12'b0, resp_queue_wraddr_q[7:0], resp_queue_rdaddr_q[7:0], resp_queue_display_rddata_q[35:0] };


  // -- ********************************************************************************************************************************
  // -- Sim Idle
  // -- ********************************************************************************************************************************

  assign  sim_idle_rspi =  ( quiesced                     == 1'b1 ) &&
                           ( tlx_afu_resp_valid_q         == 1'b0 ) &&
                           ( resp_queue_empty             == 1'b1 ) &&
                           ( resp_queue_func_rden_dly1_q  == 1'b0 ) &&
                           ( resp_queue_func_rden_dly2_q  == 1'b0 ) &&
                           ( resp_queue_valid_no_data_q   == 1'b0 ) &&
                           ( resp_queue_valid_with_data_q == 1'b0 ) &&
                           ( resp_valid_no_data_stg1_q    == 1'b0 ) &&
                           ( resp_valid_with_data_stg1_q  == 1'b0 ) &&
                           ( resp_valid_no_data_stg2_q    == 1'b0 ) &&
                           ( resp_valid_with_data_stg2_q  == 1'b0 ) &&
                           ( resp_valid_no_data_stg3_q    == 1'b0 ) &&
                           ( resp_valid_with_data_stg3_q  == 1'b0 );


  // -- ********************************************************************************************************************************
  // -- Bugspray
  // -- ********************************************************************************************************************************

//!! Bugspray include : afp3_rspi


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  // -- TLX clock domain latches
  always @ ( posedge clock_tlx )
    begin
      // -- Even/Odd Clock determination (TLX clock domain)
      sample_q                         <= sample_d;                     
      odd_q                            <= odd_d;                        
      even_q                           <= even_d;
                      
       // -- TLX input interface latches (TLX clock domain)
      tlx_afu_resp_valid_q             <= tlx_afu_resp_valid_d;
      tlx_afu_resp_valid_filtered_q    <= tlx_afu_resp_valid_filtered_d;
      tlx_afu_resp_valid_with_data_q   <= tlx_afu_resp_valid_with_data_d;
      tlx_afu_resp_valid_no_data_q     <= tlx_afu_resp_valid_no_data_d;
      tlx_afu_resp_valid_retry_q       <= tlx_afu_resp_valid_retry_d;
        
      if ( tlx_afu_resp_en )
        begin
          tlx_afu_resp_afutag_q[15:0]  <= tlx_afu_resp_afutag_d[15:0];  
          tlx_afu_resp_opcode_q[7:0]   <= tlx_afu_resp_opcode_d[7:0];   
          tlx_afu_resp_code_q[3:0]     <= tlx_afu_resp_code_d[3:0];     
          tlx_afu_resp_dl_q[1:0]       <= tlx_afu_resp_dl_d[1:0];       
          tlx_afu_resp_dp_q[1:0]       <= tlx_afu_resp_dp_d[1:0];
        end

      // -- Fastpath latches
      fastpath_queue_bypass_eligible_nxt_q <= fastpath_queue_bypass_eligible_nxt_d;  
      fastpath_queue_bypass_possible_nxt_q <= fastpath_queue_bypass_possible_nxt_d; 
      fastpath_stg0_bypass_eligible_nxt_q  <= fastpath_stg0_bypass_eligible_nxt_d;
      fastpath_stg0_bypass_possible_nxt_q  <= fastpath_stg0_bypass_possible_nxt_d;
      fastpath_stg1_bypass_eligible_nxt_q  <= fastpath_stg1_bypass_eligible_nxt_d;
      fastpath_stg2_bypass_eligible_nxt_q  <= fastpath_stg2_bypass_eligible_nxt_d;  
      normal_stg1_bypass_eligible_nxt_q    <= normal_stg1_bypass_eligible_nxt_d;   
      normal_stg2_bypass_eligible_nxt_q    <= normal_stg2_bypass_eligible_nxt_d;

      // -- Response Queue control latches (TLX clock domain)
      resp_queue_wraddr_q[7:0]             <= resp_queue_wraddr_d[7:0];     
      resp_queue_rdaddr_q[7:0]             <= resp_queue_rdaddr_d[7:0];     
      resp_queue_empty_q                   <= resp_queue_empty_d;       
      resp_queue_func_rden_blocker_dly1_q  <= resp_queue_func_rden_blocker_dly1_d;
      resp_queue_func_rden_blocker_dly2_q  <= resp_queue_func_rden_blocker_dly2_d;
      resp_queue_func_rden_blocker_dly3_q  <= resp_queue_func_rden_blocker_dly3_d;
      resp_queue_func_rden_dly1_q          <= resp_queue_func_rden_dly1_d;       
      resp_queue_func_rden_dly2_q          <= resp_queue_func_rden_dly2_d;       
      resp_queue_func_rden_dly3_q          <= resp_queue_func_rden_dly3_d;       
      resp_queue_func_rden_dly4_q          <= resp_queue_func_rden_dly4_d;       

      // -- Response Queue output latches (TLX clock domain)
      resp_queue_valid_with_data_q         <= resp_queue_valid_with_data_d; 
      resp_queue_valid_no_data_q           <= resp_queue_valid_no_data_d;   
      resp_queue_valid_retry_q             <= resp_queue_valid_retry_d;     
      resp_queue_spare_q                   <= resp_queue_spare_d;    
      resp_queue_afutag_q[15:0]            <= resp_queue_afutag_d[15:0];    
      resp_queue_opcode_q[7:0]             <= resp_queue_opcode_d[7:0];     
      resp_queue_code_q[3:0]               <= resp_queue_code_d[3:0];       
      resp_queue_dl_q[1:0]                 <= resp_queue_dl_d[1:0];         
      resp_queue_dp_q[1:0]                 <= resp_queue_dp_d[1:0];

      // -- Data dly latches (TLX clock domain)
      tlx_afu_resp_data_valid_dly1_q       <= tlx_afu_resp_data_valid_dly1_d;
      tlx_afu_resp_data_valid_dly2_q       <= tlx_afu_resp_data_valid_dly2_d;
      tlx_afu_resp_data_bdi_dly1_q         <= tlx_afu_resp_data_bdi_dly1_d;
      tlx_afu_resp_data_bdi_dly2_q         <= tlx_afu_resp_data_bdi_dly2_d;
      tlx_afu_resp_data_bus_dly1_q[511:0]  <= tlx_afu_resp_data_bus_dly1_d[511:0]; 
      tlx_afu_resp_data_bus_dly2_q[511:0]  <= tlx_afu_resp_data_bus_dly2_d[511:0]; 

      // -- Credit Return indicator (TLX clock domain)
      return_resp_credit_to_tlx_q          <= return_resp_credit_to_tlx_d;  

      // -- Stats on maximum number of queue entries used (TLX clock domain)
      resp_queue_numentriesval_q[7:0]      <= resp_queue_numentriesval_d[7:0]; 
      resp_queue_maxqdepth_q[7:0]          <= resp_queue_maxqdepth_d[7:0];  

      // -- Bug Fix
      fastpath_blocker_disable_q                 <= fastpath_blocker_disable_d;
      xlate_done_or_intrp_rdy_fastpath_blocker_q <= xlate_done_or_intrp_rdy_fastpath_blocker_d;

    end  // -- always @*


  // -- AFU clock domain latches       
  always @ ( posedge clock_afu )
    begin
      // -- Even/Odd Clock determination (AFU clock domain)
      toggle_q                             <= toggle_d;                     

      // -- Modes/Config from mmio (AFU clock domain)
      fastpath_queue_bypass_disable_q      <= fastpath_queue_bypass_disable_d;
      fastpath_stg0_bypass_disable_q       <= fastpath_stg0_bypass_disable_d;
      fastpath_stg1_bypass_disable_q       <= fastpath_stg1_bypass_disable_d;
      fastpath_stg2_bypass_disable_q       <= fastpath_stg2_bypass_disable_d;
      normal_stg1_bypass_disable_q         <= normal_stg1_bypass_disable_d; 
      normal_stg2_bypass_disable_q         <= normal_stg2_bypass_disable_d;

      // -- Staging latches in the AFU clock domain (AFU clock domain)
      resp_valid_with_data_stg1_q          <= resp_valid_with_data_stg1_d;  
      resp_valid_no_data_stg1_q            <= resp_valid_no_data_stg1_d;    
      resp_valid_retry_stg1_q              <= resp_valid_retry_stg1_d;      
      resp_spare_stg1_q                    <= resp_spare_stg1_d;     
      resp_afutag_stg1_q[15:0]             <= resp_afutag_stg1_d[15:0];     
      resp_opcode_stg1_q[7:0]              <= resp_opcode_stg1_d[7:0];      
      resp_code_stg1_q[3:0]                <= resp_code_stg1_d[3:0];        
      resp_dl_stg1_q[1:0]                  <= resp_dl_stg1_d[1:0];          
      resp_dp_stg1_q[1:0]                  <= resp_dp_stg1_d[1:0];
         
      resp_valid_with_data_stg2_q          <= resp_valid_with_data_stg2_d;  
      resp_valid_no_data_stg2_q            <= resp_valid_no_data_stg2_d;    
      resp_valid_retry_stg2_q              <= resp_valid_retry_stg2_d;      
      resp_spare_stg2_q                    <= resp_spare_stg2_d;     
      resp_afutag_stg2_q[15:0]             <= resp_afutag_stg2_d[15:0];     
      resp_opcode_stg2_q[7:0]              <= resp_opcode_stg2_d[7:0];      
      resp_code_stg2_q[3:0]                <= resp_code_stg2_d[3:0];        
      resp_dl_stg2_q[1:0]                  <= resp_dl_stg2_d[1:0];          
      resp_dp_stg2_q[1:0]                  <= resp_dp_stg2_d[1:0];
          
      resp_valid_stg3_q                    <= resp_valid_stg3_d;      
      resp_valid_with_data_stg3_q          <= resp_valid_with_data_stg3_d;  
      resp_valid_no_data_stg3_q            <= resp_valid_no_data_stg3_d;    
      resp_valid_retry_stg3_q              <= resp_valid_retry_stg3_d;      
      resp_spare_stg3_q                    <= resp_spare_stg3_d;     
      resp_afutag_stg3_q[15:0]             <= resp_afutag_stg3_d[15:0];     
      resp_opcode_stg3_q[7:0]              <= resp_opcode_stg3_d[7:0];      
      resp_code_stg3_q[3:0]                <= resp_code_stg3_d[3:0];        
      resp_dl_stg3_q[1:0]                  <= resp_dl_stg3_d[1:0];          
      resp_dp_stg3_q[1:0]                  <= resp_dp_stg3_d[1:0];

      resp_data_valid_stg3_q               <= resp_data_valid_stg3_d;       
      resp_data_bdi_stg3_q[1:0]            <= resp_data_bdi_stg3_d[1:0]; 
      resp_data_bus_stg3_q[1023:0]         <= resp_data_bus_stg3_d[1023:0]; 

      cmdo_rspi_cmd_valid_q                <= cmdo_rspi_cmd_valid_d;        

      // -- Latches for maintaining cmds sent vs responses received (AFU clock domain)
      add_4_q                              <= add_4_d;                      
      add_2_q                              <= add_2_d;                      
      add_1_q                              <= add_1_d;                      
      add_0_q                              <= add_0_d;                      
      sub_4_q                              <= sub_4_d;                      
      sub_2_q                              <= sub_2_d;                      
      sub_1_q                              <= sub_1_d;                      
      sub_0_q                              <= sub_0_d;                      

      // -- Latches for maintaining cmds sent vs responses received (AFU clock domain)
      if ( outstanding_responses_en )
        outstanding_responses_q[11:0]      <= outstanding_responses_d[11:0];

        max_outstanding_responses_q[11:0]  <= max_outstanding_responses_d[11:0];

      // -- Latches for timing fixes
      tlx_afu_resp_dl_cpy_q[1:0]           <= tlx_afu_resp_dl_cpy_d[1:0];
      resp_dl_stg1_cpy_q[1:0]              <= resp_dl_stg1_cpy_d[1:0];

      // -- Latches for trace array
      afu_tlx_resp_rd_req_q                <= afu_tlx_resp_rd_req_d;
      afu_tlx_resp_rd_cnt_q[2:0]           <= afu_tlx_resp_rd_cnt_d[2:0];

      // -- Latches for Display Read          
      mmio_rspi_display_rdval_q            <=  mmio_rspi_display_rdval_d;    
      if ( mmio_rspi_display_addr_en )         
        mmio_rspi_display_addr_q[6:0]      <= mmio_rspi_display_addr_d[6:0];
                                     
      resp_queue_display_seq_q[4:0]        <= resp_queue_display_seq_d[4:0];
      if ( resp_queue_display_rddata_en ) 
        resp_queue_display_rddata_q[35:0]  <= resp_queue_display_rddata_d[35:0];


    end  // -- always @*

endmodule
