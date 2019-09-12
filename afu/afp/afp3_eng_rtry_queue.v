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

module afp3_eng_rtry_queue
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config
  , input                 xtouch_wt4rsp_enable_q
  , input                 mmio_eng_capture_all_resp_code_enable

  // -- Inputs
  , input                 main_idle_st

  // -- Inputs from resp_decode to write into the rtry queue
  , input                 rspi_eng_resp_valid
  , input           [7:0] rspi_eng_resp_opcode
  , input                 rspi_resp_is_rtry
  , input                 rspi_resp_is_xtouch_rtry
  , input                 rspi_resp_is_cpy_xx_q
  , input                 rspi_resp_is_cpy_st_q
  , input           [8:0] rspi_resp_afutag_q
  , input           [1:0] rspi_resp_dl_orig_q
  , input           [1:0] rspi_resp_dl_q
  , input           [1:0] rspi_resp_dp_q
  , input           [3:0] rspi_resp_code_q
  , input                 rspi_resp_is_pending_q
  , input                 rspi_resp_is_rtry_lwt_q
  , input                 rspi_resp_is_rtry_req_q
  , input                 rspi_resp_is_rtry_hwt_q

  // -- Inputs used to form functional rden blocker
  , input                 we_ld_wt4rsp_st
  , input                 xtouch_wt4rsp_st
  , input                 cpy_ld_wt4rsp_st
  , input                 cpy_st_wt4rsp_st
  , input                 wkhstthrd_wt4rsp_st
  , input                 incr_wt4ldrsp_st
  , input                 incr_wt4strsp_st
  , input                 atomic_wt4rsp_st
  , input                 intrpt_wt4rsp_st
  , input                 we_st_wt4rsp_st

  , input                 we_rtry_ld_idle_st
  , input                 xtouch_rtry_idle_st
  , input                 cpy_rtry_ld_idle_st
  , input                 cpy_rtry_st_idle_st
  , input                 wkhstthrd_rtry_idle_st
  , input                 incr_rtry_idle_st
  , input                 atomic_rtry_idle_st
  , input                 we_rtry_st_idle_st

  ,`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input           [4:0] pending_cnt_q

  // -- Additional Inputs to block the functional rden when using display function
  , input                 start_eng_display_seq
  , input                 eng_display_idle_st

  // -- Inputs needed to read the rtry queue array via display function
  , input                 eng_display_rtry_queue_rden
  , input           [9:0] eng_display_addr_q

  // -- Outputs
  , output                rtry_queue_empty
  , output                rtry_queue_func_rden_dly2_q
  , output                rtry_queue_cpy_xx_q
  , output                rtry_queue_cpy_st_q
  , output          [8:0] rtry_queue_afutag_q     
  , output          [1:0] rtry_queue_dl_q         
  , output                rtry_queue_is_pending_q
  , output                rtry_queue_is_rtry_lwt_q
  , output                rtry_queue_is_rtry_req_q
  , output                rtry_queue_is_rtry_hwt_q

  , output                resp_code_is_done
  , output                resp_code_is_rty_req
  , output                resp_code_is_failed
  , output                resp_code_is_adr_error

//     , output          [9:0] cpy_rtry_xx_afutag_d
  , output          [8:0] cpy_rtry_xx_afutag_q
  , output reg            cpy_rtry_xx_cpy_st_q
  , output reg      [1:0] cpy_rtry_xx_dl_q
  , output reg            cpy_rtry_st_size_256_q
//     , output reg     [63:6] cpy_rtry_ld_ea_q
//     , output reg     [63:6] cpy_rtry_st_ea_q

  // -- Outputs for display/debug
  , output                rtry_queue_func_rden_blocker

  ,`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         [10:0] rtry_queue_rdaddr_q
  ,`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         [10:0] rtry_queue_wraddr_q
  ,`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         [17:0] rtry_queue_rddata
  ,`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output          [3:0] resp_code_rddata                 

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- rtry queue
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            rtry_queue_empty_int;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            rtry_queue_full;
  wire            rtry_queue_last_wraddr;
  wire            rtry_queue_last_rdaddr;
  reg       [3:0] rtry_queue_wr_sel;
  wire            rtry_queue_wren;
  wire            rtry_is_128B_2nd_half;
  wire      [9:0] new_afutag;
  wire     [17:0] rtry_queue_wrdata;
  wire            rtry_queue_func_rden_blocker_int;
  wire            rtry_queue_func_rden;
  reg             rtry_queue_rden;
  reg       [9:0] rtry_queue_rdaddr;
  reg       [2:0] rtry_queue_rd_sel;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire     [17:0] rtry_queue_rddata_int;
  //reg       [5:0] rtry_select;
  //reg       [4:0] rtry_afutag;

  // -- resp code array controls/data
  reg             resp_code_wren;
  wire      [9:0] resp_code_wraddr;
  wire      [3:0] resp_code_wrdata;
  reg             resp_code_rden;
  reg       [9:0] resp_code_rdaddr;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire      [3:0] resp_code_rddata_int;

  // -- retry queue entry tracking
  wire     [10:0] rtry_queue_size;
  wire            rtry_queue_wrap_match;
  wire     [10:0] rtry_queue_tl_mn_hd;
  wire     [10:0] rtry_queue_tl_pl_arysz_mn_hd;


  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  wire            mmio_eng_capture_all_resp_code_enable_d;
  reg             mmio_eng_capture_all_resp_code_enable_q;

  wire            rspi_eng_resp_valid_d;
  reg             rspi_eng_resp_valid_q;

  // -- Response Opcode decode
  wire            rspi_resp_is_xlate_done_d;
  reg             rspi_resp_is_xlate_done_q;

  wire            rspi_resp_is_intrp_rdy_d;
  reg             rspi_resp_is_intrp_rdy_q;


  wire            rtry_valid_d;
  reg             rtry_valid_q;
  reg      [10:0] rtry_queue_wraddr_int_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [10:0] rtry_queue_wraddr_int_q;
  reg      [10:0] rtry_queue_rdaddr_int_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [10:0] rtry_queue_rdaddr_int_q;
  wire            rtry_queue_func_rden_dly1_int_d;
  reg             rtry_queue_func_rden_dly1_int_q;
  wire            rtry_queue_func_rden_dly2_int_d;
  reg             rtry_queue_func_rden_dly2_int_q;

  wire            rtry_queue_capture_en;
  wire            rtry_queue_cpy_xx_int_d;
  reg             rtry_queue_cpy_xx_int_q;
  wire            rtry_queue_cpy_st_int_d;
  reg             rtry_queue_cpy_st_int_q;
  wire      [9:0] rtry_queue_afutag_int_d;
  reg       [9:0] rtry_queue_afutag_int_q;
  wire      [1:0] rtry_queue_dl_int_d;
  reg       [1:0] rtry_queue_dl_int_q;
  wire            rtry_queue_is_pending_int_d;
  reg             rtry_queue_is_pending_int_q;
  wire            rtry_queue_is_rtry_lwt_int_d;
  reg             rtry_queue_is_rtry_lwt_int_q;
  wire            rtry_queue_is_rtry_req_int_d;
  reg             rtry_queue_is_rtry_req_int_q;
  wire            rtry_queue_is_rtry_hwt_int_d;
  reg             rtry_queue_is_rtry_hwt_int_q;

  wire      [8:0] cpy_rtry_xx_afutag_int_d;
  reg       [8:0] cpy_rtry_xx_afutag_int_q;
  wire            cpy_rtry_xx_cpy_st_d;
//reg             cpy_rtry_xx_cpy_st_q;
  wire      [1:0] cpy_rtry_xx_dl_d;
//reg       [1:0] cpy_rtry_xx_dl_q;
  reg             cpy_rtry_st_size_256_d;
//reg       [8:6] cpy_rtry_st_size_q;
//     wire     [63:6] cpy_rtry_ld_ea_d;
//reg      [63:6] cpy_rtry_ld_ea_q;
//     wire     [63:6] cpy_rtry_st_ea_d;
//reg      [63:6] cpy_rtry_st_ea_q;

  // -- rtry queue entry tracking
  reg      [10:0] rtry_queue_numentriesval_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [10:0] rtry_queue_numentriesval_q;
  reg      [10:0] rtry_queue_maxqdepth_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [10:0] rtry_queue_maxqdepth_q;

  wire            rtry_wr_count_en;
  reg      [31:0] rtry_wr_count_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [31:0] rtry_wr_count_q;

  wire            rtry_rd_count_en;
  reg      [31:0] rtry_rd_count_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [31:0] rtry_rd_count_q;

  wire            rtry_pending_count_en;
  reg      [31:0] rtry_pending_count_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [31:0] rtry_pending_count_q;

  wire            rtry_req_count_en;
  reg      [31:0] rtry_req_count_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [31:0] rtry_req_count_q;

  wire            rtry_hwt_count_en;
  reg      [31:0] rtry_hwt_count_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [31:0] rtry_hwt_count_q;

  wire            rtry_lwt_count_en;
  reg      [31:0] rtry_lwt_count_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [31:0] rtry_lwt_count_q;


  // -- ********************************************************************************************************************************
  // -- Constant Declarations 
  // -- ********************************************************************************************************************************

  // -- TL CAPP response encodes
  localparam    [7:0] TLX_AFU_RESP_ENCODE_XLATE_DONE           = 8'b00011000;  // -- Address Translation Completed (Async Notification)
  localparam    [7:0] TLX_AFU_RESP_ENCODE_INTRP_RDY            = 8'b00011010;  // -- Interrupt ready (Async Notification)

  // -- TL CAPP response code encodes
  localparam    [3:0] TLX_AFU_RESP_CODE_DONE                   = 4'b0000;      // -- Done
  localparam    [3:0] TLX_AFU_RESP_CODE_RTY_HWT                = 4'b0001;      // -- Retry Xlate Touch w/ Heavy Weight
  localparam    [3:0] TLX_AFU_RESP_CODE_RTY_REQ                = 4'b0010;      // -- Retry Heavy weight (long backoff timer)                                 
  localparam    [3:0] TLX_AFU_RESP_CODE_LW_RTY_REQ             = 4'b0011;      // -- Retry Light Weight (short backoff timer)                                 
  localparam    [3:0] TLX_AFU_RESP_CODE_XLATE_PENDING          = 4'b0100;      // -- Toss, wait for xlate done with same AFU tag, convert to Retry
  localparam    [3:0] TLX_AFU_RESP_CODE_INTRP_PENDING          = 4'b0100;      // -- Toss, wait for intrp rdy with same AFU tag, convert to Retry
  localparam    [3:0] TLX_AFU_RESP_CODE_THREAD_NOT_FOUND       = 4'b0100;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_DERROR                 = 4'b1000;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_LENGTH             = 4'b1001;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_ADDR               = 4'b1011;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_HANDLE             = 4'b1011;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_FAILED                 = 4'b1110;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_ADR_ERROR              = 4'b1111;      // -- Machine Check


  // -- ********************************************************************************************************************************
  // -- Modes/Config from MMIO 
  // -- ********************************************************************************************************************************

  assign  mmio_eng_capture_all_resp_code_enable_d =  mmio_eng_capture_all_resp_code_enable;


  // -- ********************************************************************************************************************************
  // -- Retry Queue 
  // -- ********************************************************************************************************************************

  // -- A Retry Queue is needed in the event that multiple retry responses come back to the same engine faster than the engine can process them.
  // --     Worst case scenario is that every operation of a copy ld or cpy st has been split into 64B responses, but AFP doesn't handle the general case.  Our system will only split into 128B responses
  // --     Worst case, 512 tags each for loads & stores (for 64B, 128B), and 256 tags (w/two 128B responses each) for 256B commands ... so up to 1K retry responses

  assign  rtry_valid_d =  ( rspi_resp_is_rtry && ~( rspi_resp_is_xtouch_rtry && ~xtouch_wt4rsp_enable_q ));   // -- Block touch responses from entering the rtry queue when we are ignoring xtouch responses

  // -- Determine if queue is full or empty (bit 10 of the address toggles on every wrap)
  assign  rtry_queue_empty_int =  (( rtry_queue_wraddr_int_q[9:0] == rtry_queue_rdaddr_int_q[9:0] ) && ( rtry_queue_wraddr_int_q[10] == rtry_queue_rdaddr_int_q[10] ));
  assign  rtry_queue_full      =  (( rtry_queue_wraddr_int_q[9:0] == rtry_queue_rdaddr_int_q[9:0] ) && ( rtry_queue_wraddr_int_q[10] != rtry_queue_rdaddr_int_q[10] ));

  // -- Determine if the write address is currently pointing to the last entry of the array
  assign  rtry_queue_last_wraddr =  ( rtry_queue_wraddr_int_q[9:0] == 10'b11_1111_1111 );
  assign  rtry_queue_last_rdaddr =  ( rtry_queue_rdaddr_int_q[9:0] == 10'b11_1111_1111 );

  // -- Queue any response that cannot bypass the response queue
  assign  rtry_queue_wren = ( ~reset && ~rtry_queue_full && rtry_valid_q );


  // -- For Debug - count number of retry queue writes
  assign  rtry_wr_count_en = ( reset || main_idle_st || rtry_queue_wren );

  always @*
    begin
      if ( reset || main_idle_st )
        rtry_wr_count_d[31:0] =  32'b0;
      else if ( rtry_queue_wren && ~( rtry_wr_count_q[31:0] == 32'hFFFFFFFF ))
        rtry_wr_count_d[31:0] = ( rtry_wr_count_q[31:0] + 32'b1 );
      else
        rtry_wr_count_d[31:0] =   rtry_wr_count_q[31:0];
    end // -- always @ *                                  


  always @*
    begin
      rtry_queue_wr_sel[3:0] =  { ( reset || main_idle_st ), rtry_queue_full, rtry_valid_q, rtry_queue_last_wraddr };

      casez ( rtry_queue_wr_sel[3:0] )
        //
        // --  reset
        // --  |rtry_queue_full
        // --  ||rtry_valid_q
        // --  |||rtry_queue_last_wraddr
        // --  ||||
        // -------------------------------------------------------------------------------------------------------------------
            4'b1??? :  rtry_queue_wraddr_int_d[10:0] =  {                        1'b0,                           10'b0           };  // -- reset
            4'b01?? :  rtry_queue_wraddr_int_d[10:0] =  {  rtry_queue_wraddr_int_q[10],   rtry_queue_wraddr_int_q[9:0]           };  // -- rtry_queue_full
            4'b0010 :  rtry_queue_wraddr_int_d[10:0] =  {  rtry_queue_wraddr_int_q[10], ( rtry_queue_wraddr_int_q[9:0] + 10'b1 ) };  // -- write into the queue, NOT last wraddr, increment
            4'b0011 :  rtry_queue_wraddr_int_d[10:0] =  { ~rtry_queue_wraddr_int_q[10],                          10'b0           };  // -- write into the queue, last wraddr, flip toggle bit, wrap back to zero
        // -------------------------------------------------------------------------------------------------------------------
            default :  rtry_queue_wraddr_int_d[10:0] =  {  rtry_queue_wraddr_int_q[10],   rtry_queue_wraddr_int_q[9:0]           };  // -- Nothing valid - hold current value
        // -------------------------------------------------------------------------------------------------------------------
      endcase
    end // -- always @ *                                  

  // -- adjust the afutag bits for 128B partial responses on 256B load/stores
  assign  rtry_is_128B_2nd_half  =  rspi_resp_is_cpy_xx_q  &                    // -- Only update afutag for loads/stores
                                   (rspi_resp_dl_q[1:0] == 2'b10) &             // -- dl = 128B
                                   (rspi_resp_dl_orig_q[1:0] == 2'b11) &        // -- orig = 256B
                                   (rspi_resp_dp_q[1] == 1'b1);                 // -- dp = second half

  assign  new_afutag[9:0]  = {1'b1, rspi_resp_afutag_q[8:1], (rspi_resp_afutag_q[0] | rtry_is_128B_2nd_half)};  //Leaving new_afutag[9] as a placeholder in case we need to expand afutags later

  // -- form write data going into the array
  assign  rtry_queue_wrdata[17]    =  rspi_resp_is_cpy_xx_q;    // -- 0'b indicates Non-Copy operation,  1'b indicates copy load or copy store
  assign  rtry_queue_wrdata[16]    =  rspi_resp_is_cpy_st_q;    // -- 0'b indicates load (when cpy_xx=1),  1'b indicates store
  assign  rtry_queue_wrdata[15:6]  =  new_afutag[9:0];     // -- For non-Copy ops, [4:0] indicate the sequencer that issued and op type,  for copy ops, tag number
  assign  rtry_queue_wrdata[5:4]   =  rspi_resp_dl_q[1:0];
  assign  rtry_queue_wrdata[3]     =  rspi_resp_is_pending_q;
  assign  rtry_queue_wrdata[2]     =  rspi_resp_is_rtry_lwt_q;
  assign  rtry_queue_wrdata[1]     =  rspi_resp_is_rtry_req_q;
  assign  rtry_queue_wrdata[0]     =  rspi_resp_is_rtry_hwt_q;


  // -- retry queue array
  afp3_ram1024x018  rtry_queue
    ( .clk   ( clock ),

      .wren  ( rtry_queue_wren ),
      .wrad  ( rtry_queue_wraddr_int_q[9:0] ),
      .data  ( rtry_queue_wrdata[17:0] ),

      .rden  ( rtry_queue_rden ),
      .rdad  ( rtry_queue_rdaddr[9:0] ),
      .q     ( rtry_queue_rddata_int[17:0] )
    );


  // -- Always reading the queue when not empty and not blocked

  // -- need to block 2 cycles after read to allow data to get latched, then hold while retry sequencers are not idle
  // --  use an enable on the latch to hold the data
  // -- need 2 retry sequencers
  // -- write request can go right away since the op size is known.
  // -- watch for case when original op was a partial (need to convert 00 to 01 if addr xlate)

  assign  rtry_queue_func_rden_blocker_int =  ~( we_ld_wt4rsp_st ||    // -- Block rden until one of main (non-retry) sub-sequencers is in its Wt4RspST
                                                xtouch_wt4rsp_st ||
                                                cpy_ld_wt4rsp_st ||
                                                cpy_st_wt4rsp_st ||
                                             wkhstthrd_wt4rsp_st ||
                                                incr_wt4ldrsp_st ||
                                                incr_wt4strsp_st ||
                                                atomic_wt4rsp_st ||
                                                intrpt_wt4rsp_st ||
                                                 we_st_wt4rsp_st )  ||
                            
                               ( rtry_queue_func_rden_dly1_int_q ||    // -- Block rden for 2 cycles after rden asserted to allow retry queue output to be latched and one of the retry seq to start
                                 rtry_queue_func_rden_dly2_int_q )  ||  
             
                                           ( ~we_rtry_ld_idle_st ||    // -- Block rden while any retry sequencer is active
                                            ~xtouch_rtry_idle_st ||
                                            ~cpy_rtry_ld_idle_st ||
                                            ~cpy_rtry_st_idle_st ||
                                         ~wkhstthrd_rtry_idle_st ||
                                              ~incr_rtry_idle_st ||
                                            ~atomic_rtry_idle_st ||
                                             ~we_rtry_st_idle_st )  || 
             
                                   ~( pending_cnt_q[4:0] == 5'b0 );     // -- Block when pending_cnt != 0 (ie. have more xlate/intrp_pending outstanding than xlate_done/intrp_rdy received

  assign  rtry_queue_func_rden            = ~rtry_queue_empty_int && ~rtry_queue_func_rden_blocker_int && ~reset && ~start_eng_display_seq && eng_display_idle_st;
  assign  rtry_queue_func_rden_dly1_int_d =  rtry_queue_func_rden;
  assign  rtry_queue_func_rden_dly2_int_d =  rtry_queue_func_rden_dly1_int_q;

  // -- For Debug - count number of retry queue reads
  assign  rtry_rd_count_en = ( reset || main_idle_st || rtry_queue_func_rden );
  always @*
    begin
      if ( reset || main_idle_st )
        rtry_rd_count_d[31:0] =  32'b0;
      else if (  rtry_queue_func_rden && ~( rtry_rd_count_q[31:0] == 32'hFFFFFFFF ))
        rtry_rd_count_d[31:0] = ( rtry_rd_count_q[31:0] + 32'b1 );
      else
        rtry_rd_count_d[31:0] =   rtry_rd_count_q[31:0];
    end // -- always @ *                                  


  always @*
    begin
       // -- Choose rden/rdaddr from either Eng Display Read or Functional path - Eng Display Read Only allowed when Main sequencer is in Idle State
      if ( start_eng_display_seq || ~eng_display_idle_st )
        begin
          rtry_queue_rden        =  eng_display_rtry_queue_rden;
          rtry_queue_rdaddr[9:0] =  eng_display_addr_q[9:0];
        end
      else
        begin
          rtry_queue_rden        =  rtry_queue_func_rden;
          rtry_queue_rdaddr[9:0] =  rtry_queue_rdaddr_int_q[9:0]; 
        end

      // -- Manage the Functional Read Address latches 
      rtry_queue_rd_sel[2:0] =  { ( reset || main_idle_st ), rtry_queue_func_rden, rtry_queue_last_rdaddr };

      casez ( rtry_queue_rd_sel[2:0] )
        //
        // --  reset
        // --  |rtry_queue_func_rden
        // --  |||rtry_queue_last_rdaddr
        // --  |||
        // -----------------------------------------------------------------------------------------------------------------
            3'b1?? :  rtry_queue_rdaddr_int_d[10:0] =  {                    1'b0,                              10'b0            };  // -- reset
            3'b010 :  rtry_queue_rdaddr_int_d[10:0] =  {  rtry_queue_rdaddr_int_q[10], ( rtry_queue_rdaddr_int_q[9:0] + 10'b1 ) };  // -- write into the queue, NOT last wraddr, increment
            3'b011 :  rtry_queue_rdaddr_int_d[10:0] =  { ~rtry_queue_rdaddr_int_q[10],                         10'b0            };  // -- write into the queue, last wraddr, flip toggle bit, wrap back to zero
        // -----------------------------------------------------------------------------------------------------------------
           default :  rtry_queue_rdaddr_int_d[10:0] =  {  rtry_queue_rdaddr_int_q[10],   rtry_queue_rdaddr_int_q[9:0]           };  // -- Nothing valid - hold current value
        // -----------------------------------------------------------------------------------------------------------------
      endcase

    end // -- always @ *                                  

  // -- form the read data coming out of the array
  assign  rtry_queue_capture_en         =  rtry_queue_func_rden_dly1_int_q;
  assign  rtry_queue_cpy_xx_int_d       =  rtry_queue_rddata_int[17];      // -- Corresponds to inverted original AFUTag [11]  b'0 = Cpy Operation, b'1 = Non-Cpy Operation
  assign  rtry_queue_cpy_st_int_d       =  rtry_queue_rddata_int[16];      // -- Corresponds to original AFUTag [13]  b'0 = load, b'1 = store
  assign  rtry_queue_afutag_int_d[9:0]  =  rtry_queue_rddata_int[15:6];    // -- For non-Copy ops, indicator of the sequencer that issued and op type,  for copy ops, tag number;  Bit 9 is unused - placeholder for now in case we expand
  assign  rtry_queue_dl_int_d[1:0]      =  rtry_queue_rddata_int[5:4];
  assign  rtry_queue_is_pending_int_d   =  rtry_queue_rddata_int[3];
  assign  rtry_queue_is_rtry_lwt_int_d  =  rtry_queue_rddata_int[2];
  assign  rtry_queue_is_rtry_req_int_d  =  rtry_queue_rddata_int[1];
  assign  rtry_queue_is_rtry_hwt_int_d  =  rtry_queue_rddata_int[0];


  // -- latch the adjusted afutag, dl, and  base_ea's
  assign  cpy_rtry_xx_afutag_int_d[8:0] =  rtry_queue_afutag_int_q[8:0];
  assign  cpy_rtry_xx_cpy_st_d          =  rtry_queue_cpy_st_int_q;
  assign  cpy_rtry_xx_dl_d[1:0]         =  rtry_queue_dl_int_q[1:0];

/*
  // -- Decode the rtry dl to a size
  always @*
    begin
      case ( cpy_rtry_xx_dl_d[1:0] )
        2'b11  :  cpy_rtry_st_size_d[8:6] =  3'b100;
        2'b10  :  cpy_rtry_st_size_d[8:6] =  3'b010;
        2'b01  :  cpy_rtry_st_size_d[8:6] =  3'b001;
        2'b00  :  cpy_rtry_st_size_d[8:6] =  3'b000;
      endcase
    end // -- always @ *
*/
  // -- Decode the rtry dl to a size
  always @*
    begin
      if ( cpy_rtry_xx_dl_d[1:0] == 2'b11 )
        cpy_rtry_st_size_256_d  =  1'b1;
      else
        cpy_rtry_st_size_256_d  = 1'b0;
    end // -- always @ *

  // -- ******************************************************************************************************************************************
  // -- Determine number of Entries in the Retry Queue  
  // -- ******************************************************************************************************************************************

  assign  rtry_queue_size[10:0] =  11'b10000000000;

  // -- Determine if the Write pointer has wrapped or not
  assign  rtry_queue_wrap_match =  ( rtry_queue_rdaddr_int_q[10] == rtry_queue_wraddr_int_q[10] );

  // -- Calculate number of entries assuming no wrap
  assign  rtry_queue_tl_mn_hd[10:0]          =  ( { 1'b0, rtry_queue_wraddr_int_q[9:0] } - { 1'b0, rtry_queue_rdaddr_int_q[9:0] } );

  // -- Calculate number of entries assuming a wrap
  assign  rtry_queue_tl_pl_arysz_mn_hd[10:0] =  ( { 1'b0, rtry_queue_wraddr_int_q[9:0] } + ( rtry_queue_size[10:0] - { 1'b0, rtry_queue_rdaddr_int_q[9:0] } ));

  always @*
    begin
      // -- Choose the correct number of entries calculated above
      if ( rtry_queue_wrap_match )
        rtry_queue_numentriesval_d[10:0] =  rtry_queue_tl_mn_hd[10:0];
      else
        rtry_queue_numentriesval_d[10:0] =  rtry_queue_tl_pl_arysz_mn_hd[10:0];

      // -- Track Maximum number of Valid Entries
      if ( reset || main_idle_st )
        rtry_queue_maxqdepth_d[10:0] =  11'b0;
      else if  ( rtry_queue_numentriesval_q[10:0] > rtry_queue_maxqdepth_q[10:0] )
        rtry_queue_maxqdepth_d[10:0] =  rtry_queue_numentriesval_q[10:0];
      else
        rtry_queue_maxqdepth_d[10:0] =  rtry_queue_maxqdepth_q[10:0];

    end  // -- always @*


  // -- ********************************************************************************************************************************
  // -- Resp Code Array ( for xlate_done, intrp_rdy ) to match up with xlate_pending or intrp_pending from rtry queue by AFU Tag
  // -- ********************************************************************************************************************************

  assign  rspi_eng_resp_valid_d =  rspi_eng_resp_valid;

  // -- Response Encode
  assign  rspi_resp_is_xlate_done_d          =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_XLATE_DONE[7:0]     );  // -- check resp code
  assign  rspi_resp_is_intrp_rdy_d           =  ( rspi_eng_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_INTRP_RDY[7:0]      );  // -- check resp code

  always @*
    begin
     if (mmio_eng_capture_all_resp_code_enable_q )
       resp_code_wren        =  rspi_eng_resp_valid_q;    // -- Capture all response codes (Debug Mode ONLY, if host splits responses, need to disable cmd sizes down to smallest split response size)
     else
       resp_code_wren        =  rspi_eng_resp_valid_q && ( rspi_resp_is_xlate_done_q || rspi_resp_is_intrp_rdy_q );
    end  // -- always @*

  assign  resp_code_wraddr[9:0] =  { rspi_resp_is_cpy_st_q, rspi_resp_afutag_q[8:0] };  // -- Capture per AFUTAG
  assign  resp_code_wrdata[3:0] =  rspi_resp_code_q[3:0];    // -- Capture response code in its defined format, decode when pulling out of the array

  always @*
    begin
     if ( main_idle_st ) // -- Eng Display Read
       begin 
         resp_code_rden        =  eng_display_rtry_queue_rden;  // -- On Engine Display Read, will grab contents of both Rtry_Queue and Resp_Code Arrays
         resp_code_rdaddr[9:0] =  eng_display_addr_q[9:0]; 
       end
     else
       begin 
         resp_code_rden        =  rtry_queue_func_rden_dly1_int_q;
	 resp_code_rdaddr[9:0] =  { rtry_queue_cpy_st_int_d, rtry_queue_afutag_int_d[8:0]} ; // -- Use raw afutag output from the rtry_queue as the address of the resp code array.
	   // 0xx-loads, 1xx- stores
       end
    end  // -- always @*


  // -- Pending Done Response Code
  afp3_ram1024x004  resp_code_ary
    ( .clk   ( clock ),

      .wren  ( resp_code_wren ),
      .wrad  ( resp_code_wraddr[9:0] ),
      .data  ( resp_code_wrdata[3:0] ),

      .rden  ( resp_code_rden ),
      .rdad  ( resp_code_rdaddr[9:0] ),
      .q     ( resp_code_rddata_int[3:0] )
    );

  // -- Decode raw output from the array - avail during cycle of rtry_queue_func_rden_dly2_q
  // -- These are only needed for the pending commands in the rtry queue 
  assign  resp_code_is_done      =  ( resp_code_rddata_int[3:0] == TLX_AFU_RESP_CODE_DONE[3:0]      );  // -- Done
  assign  resp_code_is_rty_req   =  ( resp_code_rddata_int[3:0] == TLX_AFU_RESP_CODE_RTY_REQ[3:0]   );  // -- Retry (long backoff timer)
  assign  resp_code_is_failed    =  ( resp_code_rddata_int[3:0] == TLX_AFU_RESP_CODE_FAILED[3:0]    );  // -- Machine Check - do nothing
  assign  resp_code_is_adr_error =  ( resp_code_rddata_int[3:0] == TLX_AFU_RESP_CODE_ADR_ERROR[3:0] );  // -- Machine Check - do nothing


  // -- ********************************************************************************************************************************
  // -- Drive outbound to rtry_decode
  // -- ********************************************************************************************************************************

  assign  rtry_queue_func_rden_dly2_q =  rtry_queue_func_rden_dly2_int_q;
  assign  rtry_queue_cpy_xx_q         =  rtry_queue_cpy_xx_int_q;
  assign  rtry_queue_cpy_st_q         =  rtry_queue_cpy_st_int_q;
  assign  rtry_queue_afutag_q[8:0]    =  rtry_queue_afutag_int_q[8:0];       
  assign  rtry_queue_dl_q[1:0]        =  rtry_queue_dl_int_q[1:0];           
  assign  rtry_queue_is_pending_q     =  rtry_queue_is_pending_int_q;
  assign  rtry_queue_is_rtry_lwt_q    =  rtry_queue_is_rtry_lwt_int_q;
  assign  rtry_queue_is_rtry_req_q    =  rtry_queue_is_rtry_req_int_q;
  assign  rtry_queue_is_rtry_hwt_q    =  rtry_queue_is_rtry_hwt_int_q;

  // -- For Debug, count number of each type of rtry response
  assign  rtry_pending_count_en = ( reset || main_idle_st || ( rtry_queue_func_rden_dly2_int_q && rtry_queue_is_pending_int_q ));

  always @*
    begin
      if ( reset || main_idle_st )
        rtry_pending_count_d[31:0] = 32'b0;
      else if ( rtry_queue_func_rden_dly2_int_q && rtry_queue_is_pending_int_q && ~( rtry_pending_count_q[31:0] == 32'hFFFFFFFF ))
        rtry_pending_count_d[31:0] = ( rtry_pending_count_q[31:0] + 32'b1 );
      else
        rtry_pending_count_d[31:0] =   rtry_pending_count_q[31:0];
    end // -- always @ *                                  


  assign  rtry_req_count_en = ( reset || main_idle_st || ( rtry_queue_func_rden_dly2_int_q && rtry_queue_is_rtry_req_int_q ));

  always @*
    begin
      if ( reset || main_idle_st )
        rtry_req_count_d[31:0] =  32'b0;
      else if ( rtry_queue_func_rden_dly2_int_q && rtry_queue_is_rtry_req_int_q && ~( rtry_req_count_q[31:0] == 32'hFFFFFFFF ))
        rtry_req_count_d[31:0] = ( rtry_req_count_q[31:0] + 32'b1 );
      else
        rtry_req_count_d[31:0] =   rtry_req_count_q[31:0];
    end // -- always @ *                                  

  assign  rtry_hwt_count_en = ( reset || main_idle_st || ( rtry_queue_func_rden_dly2_int_q && rtry_queue_is_rtry_hwt_int_q ));

  always @*
    begin
      if ( reset || main_idle_st )
        rtry_hwt_count_d[31:0] =  32'b0;
      else if ( rtry_queue_func_rden_dly2_int_q && rtry_queue_is_rtry_hwt_int_q && ~( rtry_hwt_count_q[31:0] == 32'hFFFFFFFF ))
        rtry_hwt_count_d[31:0] = ( rtry_hwt_count_q[31:0] + 32'b1 );
      else
        rtry_hwt_count_d[31:0] =   rtry_hwt_count_q[31:0];
    end // -- always @ *                                  


  assign  rtry_lwt_count_en = ( reset || main_idle_st || ( rtry_queue_func_rden_dly2_int_q && rtry_queue_is_rtry_lwt_int_q ));

  always @*
    begin
      if ( reset || main_idle_st )
        rtry_lwt_count_d[31:0] =  32'b0;
      else if ( rtry_queue_func_rden_dly2_int_q && rtry_queue_is_rtry_lwt_int_q && ~( rtry_lwt_count_q[31:0] == 32'hFFFFFFFF ))
        rtry_lwt_count_d[31:0] = ( rtry_lwt_count_q[31:0] + 32'b1 );
      else
        rtry_lwt_count_d[31:0] =   rtry_lwt_count_q[31:0];
    end // -- always @ *                                  



  // -- ********************************************************************************************************************************
  // -- Drive outbound to dbuf
  // -- ********************************************************************************************************************************

  //    assign  cpy_rtry_xx_afutag_d[4:0]   =  cpy_rtry_xx_afutag_int_d[9:0];
  assign  cpy_rtry_xx_afutag_q[8:0]   =  cpy_rtry_xx_afutag_int_q[8:0];


  // -- ********************************************************************************************************************************
  // -- Drive outbound to rtry_timer
  // -- ********************************************************************************************************************************

  assign  rtry_queue_empty          =  rtry_queue_empty_int;


  // -- ********************************************************************************************************************************
  // -- Drive outbound to display
  // -- ********************************************************************************************************************************

  assign  rtry_queue_func_rden_blocker =  rtry_queue_func_rden_blocker_int;
  assign  rtry_queue_rdaddr_q[10:0]    =  rtry_queue_rdaddr_int_q[10:0];
  assign  rtry_queue_wraddr_q[10:0]    =  rtry_queue_wraddr_int_q[10:0];
  assign  rtry_queue_rddata[17:0]      =  rtry_queue_rddata_int[17:0];
  assign  resp_code_rddata[3:0]        =  resp_code_rddata_int[3:0];


  // -- ********************************************************************************************************************************
  // -- Bugspray
  // -- ********************************************************************************************************************************

//!! Bugspray Include : afp3_eng_rtry_queue ;


  // -- ********************************************************************************************************************************
  // -- Latch Assignments
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin
      mmio_eng_capture_all_resp_code_enable_q     <= mmio_eng_capture_all_resp_code_enable_d;

      rspi_eng_resp_valid_q                       <= rspi_eng_resp_valid_d;

      rspi_resp_is_xlate_done_q                   <= rspi_resp_is_xlate_done_d;
      rspi_resp_is_intrp_rdy_q                    <= rspi_resp_is_intrp_rdy_d;

      rtry_valid_q                                <= rtry_valid_d;
      rtry_queue_wraddr_int_q[10:0]               <= rtry_queue_wraddr_int_d[10:0];     
      rtry_queue_rdaddr_int_q[10:0]               <= rtry_queue_rdaddr_int_d[10:0];     
      rtry_queue_func_rden_dly1_int_q             <= rtry_queue_func_rden_dly1_int_d;       
      rtry_queue_func_rden_dly2_int_q             <= rtry_queue_func_rden_dly2_int_d;
      if ( rtry_queue_capture_en )
        begin      
          rtry_queue_cpy_xx_int_q                 <= rtry_queue_cpy_xx_int_d;     
          rtry_queue_cpy_st_int_q                 <= rtry_queue_cpy_st_int_d;     
          rtry_queue_afutag_int_q[9:0]            <= rtry_queue_afutag_int_d[9:0];     
          rtry_queue_dl_int_q[1:0]                <= rtry_queue_dl_int_d[1:0];         
          rtry_queue_is_pending_int_q             <= rtry_queue_is_pending_int_d; 
          rtry_queue_is_rtry_lwt_int_q            <= rtry_queue_is_rtry_lwt_int_d; 
          rtry_queue_is_rtry_req_int_q            <= rtry_queue_is_rtry_req_int_d; 
          rtry_queue_is_rtry_hwt_int_q            <= rtry_queue_is_rtry_hwt_int_d;
        end
      cpy_rtry_xx_afutag_int_q[8:0]               <= cpy_rtry_xx_afutag_int_d[8:0];    
      cpy_rtry_xx_cpy_st_q                        <= cpy_rtry_xx_cpy_st_d;
      cpy_rtry_xx_dl_q[1:0]                       <= cpy_rtry_xx_dl_d[1:0];        
      cpy_rtry_st_size_256_q                      <= cpy_rtry_st_size_256_d;     
//         cpy_rtry_ld_ea_q[63:6]                      <= cpy_rtry_ld_ea_d[63:6];       
//         cpy_rtry_st_ea_q[63:6]                      <= cpy_rtry_st_ea_d[63:6];       

      // -- Stats on maximum number of queue entries used
      rtry_queue_numentriesval_q[10:0]            <= rtry_queue_numentriesval_d[10:0];
      rtry_queue_maxqdepth_q[10:0]                <= rtry_queue_maxqdepth_d[10:0];

      if ( rtry_wr_count_en )
        rtry_wr_count_q[31:0]                     <= rtry_wr_count_d[31:0];

      if ( rtry_rd_count_en )
        rtry_rd_count_q[31:0]                     <= rtry_rd_count_d[31:0];

      if ( rtry_pending_count_en )
        rtry_pending_count_q[31:0]                <= rtry_pending_count_d[31:0];

      if ( rtry_req_count_en )
        rtry_req_count_q[31:0]                    <= rtry_req_count_d[31:0];

      if ( rtry_hwt_count_en )
        rtry_hwt_count_q[31:0]                    <= rtry_hwt_count_d[31:0];

      if ( rtry_lwt_count_en )
        rtry_lwt_count_q[31:0]                    <= rtry_lwt_count_d[31:0];

    end // -- always @ *

endmodule
