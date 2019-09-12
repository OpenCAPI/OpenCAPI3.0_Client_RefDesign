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

module mcp3_cpeng_rtry_timer (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Modes/Config & Misc Inputs
  , input                 mmio_eng_rtry_backoff_timer_disable
  , input           [3:0] cfg_afu_long_backoff_timer
  , input           [3:0] cfg_afu_short_backoff_timer
  , input                 xtouch_wt4rsp_enable_q

  , input                 rtry_queue_empty

  // -- Idle State inputs from all of the sequencers
  , input                 we_ld_idle_st
  , input                 xtouch_idle_st
  , input                 cpy_ld_idle_st
  , input                 cpy_st_idle_st
  , input                 wkhstthrd_idle_st
  , input                 incr_idle_st
  , input                 atomic_idle_st
  , input                 intrpt_idle_st
  , input                 we_st_idle_st

  // -- Responses that require retry with backoff
  , input                 rspi_resp_is_we_ld_rtry_w_backoff_q
  , input                 rspi_resp_is_xtouch_source_rtry_w_backoff_q 
  , input                 rspi_resp_is_xtouch_dest_rtry_w_backoff_q
  , input                 rspi_resp_is_cpy_ld_rtry_w_backoff_q
  , input                 rspi_resp_is_cpy_st_rtry_w_backoff_q
  , input                 rspi_resp_is_wkhstthrd_rtry_w_backoff_q
  , input                 rspi_resp_is_incr_rtry_w_backoff_q
  , input                 rspi_resp_is_atomic_rtry_w_backoff_q
  , input                 rspi_resp_is_intrpt_rtry_w_backoff_q
  , input                 rspi_resp_is_we_st_rtry_w_backoff_q

  // -- Responses to determine long vs short timer
  , input                 rspi_resp_is_rtry_req 
  , input                 rspi_resp_is_rtry_lwt  

  // -- Outputs to the Rtry Sequencers
  , output                we_rtry_ld_backoff_done
  , output                xtouch_rtry_source_backoff_done
  , output                xtouch_rtry_dest_backoff_done
  , output                cpy_rtry_ld_backoff_done
  , output                cpy_rtry_st_backoff_done
  , output                wkhstthrd_rtry_backoff_done
  , output                incr_rtry_backoff_done
  , output                atomic_rtry_backoff_done
  , output                intrpt_rtry_backoff_done
  , output                we_rtry_st_backoff_done

  , output                rtry_backoff_timer_disable_q
  , output                we_rtry_ld_backoff_done_q
  , output                xtouch_rtry_source_backoff_done_q
  , output                xtouch_rtry_dest_backoff_done_q
  , output                cpy_rtry_ld_backoff_done_q
  , output                cpy_rtry_st_backoff_done_q
  , output                wkhstthrd_rtry_backoff_done_q
  , output                incr_rtry_backoff_done_q
  , output                atomic_rtry_backoff_done_q
  , output                intrpt_rtry_backoff_done_q
  , output                we_rtry_st_backoff_done_q

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  reg      [35:0] cfg_long_backoff_timer;
  reg      [23:0] cfg_short_backoff_timer;

  wire            we_rtry_ld_backoff_start;
  wire            we_rtry_ld_backoff_done_int;

  wire            xtouch_rtry_source_backoff_start;
  wire            xtouch_rtry_source_backoff_done_int;

  wire            xtouch_rtry_dest_backoff_start;
  wire            xtouch_rtry_dest_backoff_done_int;

  wire            cpy_rtry_ld_backoff_start;
  wire            cpy_rtry_ld_backoff_done_int;

  wire            cpy_rtry_st_backoff_start;
  wire            cpy_rtry_st_backoff_done_int;

  wire            wkhstthrd_rtry_backoff_start;
  wire            wkhstthrd_rtry_backoff_done_int;

  wire            incr_rtry_backoff_start;
  wire            incr_rtry_backoff_done_int;

  wire            atomic_rtry_backoff_start;
  wire            atomic_rtry_backoff_done_int;

  wire            intrpt_rtry_backoff_start;
  wire            intrpt_rtry_backoff_done_int;

  wire            we_rtry_st_backoff_start;
  wire            we_rtry_st_backoff_done_int;

  wire            rtry_backoff_timer1_eq_one;
  wire            rtry_backoff_timer2_eq_one;

  wire            rtry_backoff_timer1_start;
  wire            rtry_backoff_timer2_start;

  wire            rtry_backoff_timer1_in_progress;
  wire            rtry_backoff_timer2_in_progress;


  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations
  // -- ********************************************************************************************************************************

  wire            rtry_backoff_timer_disable_int_d;
  reg             rtry_backoff_timer_disable_int_q;

  wire      [3:0] cfg_afu_long_backoff_timer_d;
  reg       [3:0] cfg_afu_long_backoff_timer_q;

  wire      [3:0] cfg_afu_short_backoff_timer_d;
  reg       [3:0] cfg_afu_short_backoff_timer_q;

  wire            we_rtry_ld_backoff_in_progress_d;
  reg             we_rtry_ld_backoff_in_progress_q;
  wire            we_rtry_ld_backoff_done_int_d;
  reg             we_rtry_ld_backoff_done_int_q;

  wire            xtouch_rtry_source_backoff_in_progress_d;
  reg             xtouch_rtry_source_backoff_in_progress_q;
  wire            xtouch_rtry_source_backoff_done_int_d;
  reg             xtouch_rtry_source_backoff_done_int_q;

  wire            xtouch_rtry_dest_backoff_in_progress_d;
  reg             xtouch_rtry_dest_backoff_in_progress_q;
  wire            xtouch_rtry_dest_backoff_done_int_d;
  reg             xtouch_rtry_dest_backoff_done_int_q;

  wire            cpy_rtry_ld_backoff_in_progress_d;
  reg             cpy_rtry_ld_backoff_in_progress_q;
  wire            cpy_rtry_ld_backoff_done_int_d;
  reg             cpy_rtry_ld_backoff_done_int_q;

  wire            cpy_rtry_st_backoff_in_progress_d;
  reg             cpy_rtry_st_backoff_in_progress_q;
  wire            cpy_rtry_st_backoff_done_int_d;
  reg             cpy_rtry_st_backoff_done_int_q;

  wire            wkhstthrd_rtry_backoff_in_progress_d;
  reg             wkhstthrd_rtry_backoff_in_progress_q;
  wire            wkhstthrd_rtry_backoff_done_int_d;
  reg             wkhstthrd_rtry_backoff_done_int_q;

  wire            incr_rtry_backoff_in_progress_d;
  reg             incr_rtry_backoff_in_progress_q;
  wire            incr_rtry_backoff_done_int_d;
  reg             incr_rtry_backoff_done_int_q;

  wire            atomic_rtry_backoff_in_progress_d;
  reg             atomic_rtry_backoff_in_progress_q;
  wire            atomic_rtry_backoff_done_int_d;
  reg             atomic_rtry_backoff_done_int_q;

  wire            intrpt_rtry_backoff_in_progress_d;
  reg             intrpt_rtry_backoff_in_progress_q;
  wire            intrpt_rtry_backoff_done_int_d;
  reg             intrpt_rtry_backoff_done_int_q;

  wire            we_rtry_st_backoff_in_progress_d;
  reg             we_rtry_st_backoff_in_progress_q;
  wire            we_rtry_st_backoff_done_int_d;
  reg             we_rtry_st_backoff_done_int_q;

  wire            rtry_backoff_timer1_en;
  reg      [35:0] rtry_backoff_timer1_d;
  reg      [35:0] rtry_backoff_timer1_q;

  wire            rtry_backoff_timer2_en;
  reg      [35:0] rtry_backoff_timer2_d;
  reg      [35:0] rtry_backoff_timer2_q;

  wire            rtry_queue_empty_dly1_d;
  reg             rtry_queue_empty_dly1_q;


  // -- ********************************************************************************************************************************
  // -- Config/Mode repower 
  // -- ********************************************************************************************************************************

  assign  rtry_backoff_timer_disable_int_d =  mmio_eng_rtry_backoff_timer_disable;

  // -- Drive outbound for use by retry sequencers
  assign  rtry_backoff_timer_disable_q     =  rtry_backoff_timer_disable_int_q; 

  assign  cfg_afu_long_backoff_timer_d[3:0]  =  cfg_afu_long_backoff_timer[3:0];
  assign  cfg_afu_short_backoff_timer_d[3:0] =  cfg_afu_short_backoff_timer[3:0];


  // -- ********************************************************************************************************************************
  // -- rty_req long & short backoff timer conversion 
  // -- ********************************************************************************************************************************

  always @*
    begin
      case (cfg_afu_long_backoff_timer_q[3:0])                      // -- At 200 MHz, 20 clock cycles (x14) = 100 ns
        4'b0000:  cfg_long_backoff_timer[35:0] =  36'h0_0000_0014;  // --  2^(2*0)  =          1 * 100 ns  
        4'b0001:  cfg_long_backoff_timer[35:0] =  36'h0_0000_0050;  // --  2^(2*1)  =          4 * 100 ns
        4'b0010:  cfg_long_backoff_timer[35:0] =  36'h0_0000_0140;  // --  2^(2*2)  =         16 * 100 ns   
        4'b0011:  cfg_long_backoff_timer[35:0] =  36'h0_0000_0500;  // --  2^(2*3)  =         64 * 100 ns     
        4'b0100:  cfg_long_backoff_timer[35:0] =  36'h0_0000_1400;  // --  2^(2*4)  =        256 * 100 ns     
        4'b0101:  cfg_long_backoff_timer[35:0] =  36'h0_0000_5000;  // --  2^(2*5)  =       1024 * 100 ns     
        4'b0110:  cfg_long_backoff_timer[35:0] =  36'h0_0001_4000;  // --  2^(2*6)  =       4096 * 100 ns     
        4'b0111:  cfg_long_backoff_timer[35:0] =  36'h0_0005_0000;  // --  2^(2*7)  =      16384 * 100 ns     
        4'b1000:  cfg_long_backoff_timer[35:0] =  36'h0_0014_0000;  // --  2^(2*8)  =      65536 * 100 ns    
        4'b1001:  cfg_long_backoff_timer[35:0] =  36'h0_0050_0000;  // --  2^(2*9)  =     262144 * 100 ns      
        4'b1010:  cfg_long_backoff_timer[35:0] =  36'h0_0140_0000;  // --  2^(2*10) =    1048576 * 100 ns     
        4'b1011:  cfg_long_backoff_timer[35:0] =  36'h0_0500_0000;  // --  2^(2*11) =    4184304 * 100 ns    
        4'b1100:  cfg_long_backoff_timer[35:0] =  36'h0_1400_0000;  // --  2^(2*12) =   16777216 * 100 ns    
        4'b1101:  cfg_long_backoff_timer[35:0] =  36'h0_5000_0000;  // --  2^(2*13) =   67108864 * 100 ns    
        4'b1110:  cfg_long_backoff_timer[35:0] =  36'h1_4000_0000;  // --  2^(2*14) =  268435456 * 100 ns    
        4'b1111:  cfg_long_backoff_timer[35:0] =  36'h5_0000_0000;  // --  2^(2*15) = 1073741824 * 100 ns    
     endcase
    end // -- always @ *

  always @*
    begin
      case (cfg_afu_short_backoff_timer_q[3:0])                  // -- At 200 MHz, 20 clock cycles (x14) = 100 ns
        4'b0000:  cfg_short_backoff_timer[23:0] =  24'h00_0014;  // --  2^0  =     1 * 100 ns  
        4'b0001:  cfg_short_backoff_timer[23:0] =  24'h00_0028;  // --  2^1  =     2 * 100 ns
        4'b0010:  cfg_short_backoff_timer[23:0] =  24'h00_0050;  // --  2^2  =     4 * 100 ns   
        4'b0011:  cfg_short_backoff_timer[23:0] =  24'h00_00A0;  // --  2^3  =     8 * 100 ns     
        4'b0100:  cfg_short_backoff_timer[23:0] =  24'h00_0140;  // --  2^4  =    16 * 100 ns     
        4'b0101:  cfg_short_backoff_timer[23:0] =  24'h00_0280;  // --  2^5  =    32 * 100 ns     
        4'b0110:  cfg_short_backoff_timer[23:0] =  24'h00_0500;  // --  2^6  =    64 * 100 ns     
        4'b0111:  cfg_short_backoff_timer[23:0] =  24'h00_0A00;  // --  2^7  =   128 * 100 ns     
        4'b1000:  cfg_short_backoff_timer[23:0] =  24'h00_1400;  // --  2^8  =   256 * 100 ns    
        4'b1001:  cfg_short_backoff_timer[23:0] =  24'h00_2800;  // --  2^9  =   512 * 100 ns      
        4'b1010:  cfg_short_backoff_timer[23:0] =  24'h00_5000;  // --  2^10 =  1024 * 100 ns     
        4'b1011:  cfg_short_backoff_timer[23:0] =  24'h00_A000;  // --  2^11 =  2048 * 100 ns    
        4'b1100:  cfg_short_backoff_timer[23:0] =  24'h01_4000;  // --  2^12 =  4096 * 100 ns    
        4'b1101:  cfg_short_backoff_timer[23:0] =  24'h02_8000;  // --  2^13 =  8192 * 100 ns    
        4'b1110:  cfg_short_backoff_timer[23:0] =  24'h05_0000;  // --  2^14 = 16384 * 100 ns    
        4'b1111:  cfg_short_backoff_timer[23:0] =  24'h0A_0000;  // --  2^15 = 32768 * 100 ns    
      endcase
    end // -- always @ *

  // -- Retry Backoff Timers are started on the front end of the retry queue (as the response is received)
  // -- They are checked as the retried cmds are read from the rtry_queue.  If timer still active, need to wait, else proceed.
  // -- In the case of a xlate_pending or intrp_pending, those are queued in the queue to be released at a later time, no timer started until see xlate_done or intrp_rdy
  // -- Copy's are a special case because there are up to 32 outstanding operations ... not worth the real estate to track them individually
  // -- For copy's, a single timer will be used,  started on first retry.  After it counts down, all cmds in the rtry queue will be allowed to drain.
  // -- Once the rtry queue goes empty, done latch is reset, subsequent retry will again start the backoff timer.
  // -- xlate touches will use two individual timers, one for source, other for dest.
  // -- All other retries are single command, single timer

  // -- NOTE: rtry_req term includes both the normal response w/ resp_code of rty_req as well as pending_done w/ resp_code of rty_req

  assign  rtry_queue_empty_dly1_d = rtry_queue_empty;

  // -- we_rtry_ld backoff timer management  
  assign  we_rtry_ld_backoff_start                  =  ( rspi_resp_is_we_ld_rtry_w_backoff_q && ~( we_rtry_ld_backoff_in_progress_q && ~we_rtry_ld_backoff_done_int ) &&
                                                      ~(( we_rtry_ld_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q )); 
  assign  we_rtry_ld_backoff_in_progress_d          =  ( ~reset && ~we_ld_idle_st && ( we_rtry_ld_backoff_start || ( we_rtry_ld_backoff_in_progress_q && ~we_rtry_ld_backoff_done_int )));
  assign  we_rtry_ld_backoff_done_int_d             =  ( ~reset && ~we_ld_idle_st && ( we_rtry_ld_backoff_done_int  || we_rtry_ld_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- xtouch_rtry_source backoff timer management
  assign  xtouch_rtry_source_backoff_start          =  ( rspi_resp_is_xtouch_source_rtry_w_backoff_q && ~(xtouch_rtry_source_backoff_in_progress_q && ~xtouch_rtry_source_backoff_done_int ) &&
                                                      ~(( xtouch_rtry_source_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q ) && xtouch_wt4rsp_enable_q );   
  assign  xtouch_rtry_source_backoff_in_progress_d  =  ( ~reset && ~xtouch_idle_st && ( xtouch_rtry_source_backoff_start || ( xtouch_rtry_source_backoff_in_progress_q && ~xtouch_rtry_source_backoff_done_int )));
  assign  xtouch_rtry_source_backoff_done_int_d     =  ( ~reset && ~xtouch_idle_st && ( xtouch_rtry_source_backoff_done_int  || xtouch_rtry_source_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- xtouch_rtry_dest backoff timer management
  assign  xtouch_rtry_dest_backoff_start            =  ( rspi_resp_is_xtouch_dest_rtry_w_backoff_q && ~(xtouch_rtry_dest_backoff_in_progress_q && ~xtouch_rtry_dest_backoff_done_int ) &&
                                                      ~(( xtouch_rtry_dest_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q ) && xtouch_wt4rsp_enable_q );   
  assign  xtouch_rtry_dest_backoff_in_progress_d    =  ( ~reset && ~xtouch_idle_st && ( xtouch_rtry_dest_backoff_start || ( xtouch_rtry_dest_backoff_in_progress_q && ~xtouch_rtry_dest_backoff_done_int )));
  assign  xtouch_rtry_dest_backoff_done_int_d       =  ( ~reset && ~xtouch_idle_st && ( xtouch_rtry_dest_backoff_done_int  || xtouch_rtry_dest_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- cpy_rtry_ld backoff timer management
  assign  cpy_rtry_ld_backoff_start                 =  ( rspi_resp_is_cpy_ld_rtry_w_backoff_q && ~( cpy_rtry_ld_backoff_in_progress_q && ~cpy_rtry_ld_backoff_done_int ) &&
                                                      ~(( cpy_rtry_ld_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q )); 
  assign  cpy_rtry_ld_backoff_in_progress_d         =  ( ~reset && ~cpy_ld_idle_st && ( cpy_rtry_ld_backoff_start || ( cpy_rtry_ld_backoff_in_progress_q && ~cpy_rtry_ld_backoff_done_int )));
  assign  cpy_rtry_ld_backoff_done_int_d            =  ( ~reset && ~cpy_ld_idle_st && ( cpy_rtry_ld_backoff_done_int  || cpy_rtry_ld_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- cpy_rtry_st backoff timer management
  assign  cpy_rtry_st_backoff_start                 =  ( rspi_resp_is_cpy_st_rtry_w_backoff_q && ~( cpy_rtry_st_backoff_in_progress_q && ~cpy_rtry_st_backoff_done_int ) &&
                                                      ~(( cpy_rtry_st_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q )); 
  assign  cpy_rtry_st_backoff_in_progress_d         =  ( ~reset && ~cpy_st_idle_st && ( cpy_rtry_st_backoff_start || ( cpy_rtry_st_backoff_in_progress_q && ~cpy_rtry_st_backoff_done_int )));
  assign  cpy_rtry_st_backoff_done_int_d            =  ( ~reset && ~cpy_st_idle_st && ( cpy_rtry_st_backoff_done_int  || cpy_rtry_st_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- wkhstthrd_rtry backoff timer management  
  assign  wkhstthrd_rtry_backoff_start              =  ( rspi_resp_is_wkhstthrd_rtry_w_backoff_q && ~( wkhstthrd_rtry_backoff_in_progress_q && ~wkhstthrd_rtry_backoff_done_int ) &&
                                                      ~(( wkhstthrd_rtry_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q )); 
  assign  wkhstthrd_rtry_backoff_in_progress_d      =  ( ~reset && ~wkhstthrd_idle_st && ( wkhstthrd_rtry_backoff_start || ( wkhstthrd_rtry_backoff_in_progress_q && ~wkhstthrd_rtry_backoff_done_int )));
  assign  wkhstthrd_rtry_backoff_done_int_d         =  ( ~reset && ~wkhstthrd_idle_st && ( wkhstthrd_rtry_backoff_done_int  || wkhstthrd_rtry_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- incr_rtry backoff timer management  
  assign  incr_rtry_backoff_start                   =  ( rspi_resp_is_incr_rtry_w_backoff_q && ~( incr_rtry_backoff_in_progress_q && ~incr_rtry_backoff_done_int ) &&
                                                      ~(( incr_rtry_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q )); 
  assign  incr_rtry_backoff_in_progress_d           =  ( ~reset && ~incr_idle_st && ( incr_rtry_backoff_start || ( incr_rtry_backoff_in_progress_q && ~incr_rtry_backoff_done_int )));
  assign  incr_rtry_backoff_done_int_d              =  ( ~reset && ~incr_idle_st && ( incr_rtry_backoff_done_int  || incr_rtry_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- atomic_rtry backoff timer management
  assign  atomic_rtry_backoff_start                 =  ( rspi_resp_is_atomic_rtry_w_backoff_q && ~( atomic_rtry_backoff_in_progress_q && ~atomic_rtry_backoff_done_int ) &&
                                                      ~(( atomic_rtry_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q )); 
  assign  atomic_rtry_backoff_in_progress_d         =  ( ~reset && ~atomic_idle_st && ( atomic_rtry_backoff_start || ( atomic_rtry_backoff_in_progress_q && ~atomic_rtry_backoff_done_int )));
  assign  atomic_rtry_backoff_done_int_d            =  ( ~reset && ~atomic_idle_st && ( atomic_rtry_backoff_done_int  || atomic_rtry_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- intrpt_rtry backoff timer management
  assign  intrpt_rtry_backoff_start                 =  ( rspi_resp_is_intrpt_rtry_w_backoff_q && ~( intrpt_rtry_backoff_in_progress_q && ~intrpt_rtry_backoff_done_int ) &&
                                                      ~(( intrpt_rtry_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q )); 
  assign  intrpt_rtry_backoff_in_progress_d         =  ( ~reset && ~intrpt_idle_st && ( intrpt_rtry_backoff_start || ( intrpt_rtry_backoff_in_progress_q && ~intrpt_rtry_backoff_done_int )));
  assign  intrpt_rtry_backoff_done_int_d            =  ( ~reset && ~intrpt_idle_st && ( intrpt_rtry_backoff_done_int  || intrpt_rtry_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- we_st_rtry backoff timer management
  assign  we_rtry_st_backoff_start                  =  ( rspi_resp_is_we_st_rtry_w_backoff_q && ~( we_rtry_st_backoff_in_progress_q && ~we_rtry_st_backoff_done_int ) &&
                                                      ~(( we_rtry_st_backoff_done_int_q && ~( rtry_queue_empty && rtry_queue_empty_dly1_q )) || rtry_backoff_timer_disable_int_q )); 
  assign  we_rtry_st_backoff_in_progress_d          =  ( ~reset && ~we_st_idle_st && ( we_rtry_st_backoff_start || ( we_rtry_st_backoff_in_progress_q && ~we_rtry_st_backoff_done_int )));
  assign  we_rtry_st_backoff_done_int_d             =  ( ~reset && ~we_st_idle_st && ( we_rtry_st_backoff_done_int  || we_rtry_st_backoff_done_int_q ) && ~( rtry_queue_empty && rtry_queue_empty_dly1_q ));

  // -- Send Raw Dones outbound for use by retry sequencers
  assign  we_rtry_ld_backoff_done           =  we_rtry_ld_backoff_done_int;
  assign  xtouch_rtry_source_backoff_done   =  xtouch_rtry_source_backoff_done_int;
  assign  xtouch_rtry_dest_backoff_done     =  xtouch_rtry_dest_backoff_done_int;
  assign  cpy_rtry_ld_backoff_done          =  cpy_rtry_ld_backoff_done_int;
  assign  cpy_rtry_st_backoff_done          =  cpy_rtry_st_backoff_done_int;
  assign  wkhstthrd_rtry_backoff_done       =  wkhstthrd_rtry_backoff_done_int;
  assign  incr_rtry_backoff_done            =  incr_rtry_backoff_done_int;
  assign  atomic_rtry_backoff_done          =  atomic_rtry_backoff_done_int;
  assign  intrpt_rtry_backoff_done          =  intrpt_rtry_backoff_done_int;
  assign  we_rtry_st_backoff_done           =  we_rtry_st_backoff_done_int;                                          

  // -- Send Backoff Enable and Done Latches outbound for use by retry sequencers
  assign  rtry_backoff_timer_disable_q      =  rtry_backoff_timer_disable_int_q;
  assign  we_rtry_ld_backoff_done_q         =  we_rtry_ld_backoff_done_int_q;
  assign  xtouch_rtry_source_backoff_done_q =  xtouch_rtry_source_backoff_done_int_q;
  assign  xtouch_rtry_dest_backoff_done_q   =  xtouch_rtry_dest_backoff_done_int_q;
  assign  cpy_rtry_ld_backoff_done_q        =  cpy_rtry_ld_backoff_done_int_q;
  assign  cpy_rtry_st_backoff_done_q        =  cpy_rtry_st_backoff_done_int_q;
  assign  wkhstthrd_rtry_backoff_done_q     =  wkhstthrd_rtry_backoff_done_int_q;
  assign  incr_rtry_backoff_done_q          =  incr_rtry_backoff_done_int_q;
  assign  atomic_rtry_backoff_done_q        =  atomic_rtry_backoff_done_int_q;
  assign  intrpt_rtry_backoff_done_q        =  intrpt_rtry_backoff_done_int_q;
  assign  we_rtry_st_backoff_done_q         =  we_rtry_st_backoff_done_int_q;                                          

  assign  rtry_backoff_timer1_eq_one =  ( rtry_backoff_timer1_q[35:0] == 36'b1 );

  assign          we_rtry_ld_backoff_done_int =  (         we_rtry_ld_backoff_in_progress_q && rtry_backoff_timer1_eq_one ); 
  assign  xtouch_rtry_source_backoff_done_int =  ( xtouch_rtry_source_backoff_in_progress_q && rtry_backoff_timer1_eq_one ); 
  assign    xtouch_rtry_dest_backoff_done_int =  (   xtouch_rtry_dest_backoff_in_progress_q && rtry_backoff_timer2_eq_one );  // -- xtouch dest uses timer2
  assign         cpy_rtry_ld_backoff_done_int =  (        cpy_rtry_ld_backoff_in_progress_q && rtry_backoff_timer1_eq_one ); 
  assign         cpy_rtry_st_backoff_done_int =  (        cpy_rtry_st_backoff_in_progress_q && rtry_backoff_timer1_eq_one ); 
  assign      wkhstthrd_rtry_backoff_done_int =  (     wkhstthrd_rtry_backoff_in_progress_q && rtry_backoff_timer1_eq_one ); 
  assign           incr_rtry_backoff_done_int =  (          incr_rtry_backoff_in_progress_q && rtry_backoff_timer1_eq_one ); 
  assign         atomic_rtry_backoff_done_int =  (        atomic_rtry_backoff_in_progress_q && rtry_backoff_timer1_eq_one ); 
  assign         intrpt_rtry_backoff_done_int =  (        intrpt_rtry_backoff_in_progress_q && rtry_backoff_timer1_eq_one ); 
  assign          we_rtry_st_backoff_done_int =  (         we_rtry_st_backoff_in_progress_q && rtry_backoff_timer1_eq_one ); 


  assign  rtry_backoff_timer1_start =
            (         we_rtry_ld_backoff_start ||
              xtouch_rtry_source_backoff_start ||
                     cpy_rtry_ld_backoff_start ||
                     cpy_rtry_st_backoff_start || 
                  wkhstthrd_rtry_backoff_start ||
                       incr_rtry_backoff_start ||
                     atomic_rtry_backoff_start ||
                     intrpt_rtry_backoff_start ||
                      we_rtry_st_backoff_start );

  assign  rtry_backoff_timer1_in_progress =
            (         we_rtry_ld_backoff_in_progress_q ||
              xtouch_rtry_source_backoff_in_progress_q ||
                     cpy_rtry_ld_backoff_in_progress_q ||
                     cpy_rtry_st_backoff_in_progress_q ||
                  wkhstthrd_rtry_backoff_in_progress_q ||
                       incr_rtry_backoff_in_progress_q ||
                     atomic_rtry_backoff_in_progress_q ||
                     intrpt_rtry_backoff_in_progress_q ||
                      we_rtry_st_backoff_in_progress_q );

  assign  rtry_backoff_timer1_en =  ( rtry_backoff_timer1_start || rtry_backoff_timer1_in_progress ); 


  always @*
    begin
      if ( rtry_backoff_timer1_start )
        begin
          if ( rspi_resp_is_rtry_lwt )
            rtry_backoff_timer1_d[35:0] =  { 12'b0, cfg_short_backoff_timer[23:0] };
          else
            rtry_backoff_timer1_d[35:0] =  cfg_long_backoff_timer[35:0];
        end
      else if ( rtry_backoff_timer1_in_progress ) 
        rtry_backoff_timer1_d[35:0] =  ( rtry_backoff_timer1_q[35:0] - 36'h000000001 );
      else 
        rtry_backoff_timer1_d[35:0] =  36'b0;
    end // -- always @ *


  assign  rtry_backoff_timer2_eq_one      =  ( rtry_backoff_timer2_q[35:0] == 36'b1 );
  assign  rtry_backoff_timer2_start       =    xtouch_rtry_dest_backoff_start;
  assign  rtry_backoff_timer2_in_progress =    xtouch_rtry_dest_backoff_in_progress_q;
  assign  rtry_backoff_timer2_en          =  ( rtry_backoff_timer2_start || rtry_backoff_timer2_in_progress ); 

  always @*
    begin
      if ( rtry_backoff_timer2_start )
        begin
          if ( rspi_resp_is_rtry_lwt )
            rtry_backoff_timer2_d[35:0] =  { 12'b0, cfg_short_backoff_timer[23:0] };
          else
            rtry_backoff_timer2_d[35:0] =  cfg_long_backoff_timer[35:0];
        end
      else if ( rtry_backoff_timer2_in_progress ) 
        rtry_backoff_timer2_d[35:0] =  ( rtry_backoff_timer2_q[35:0] - 36'h000000001 );
      else 
        rtry_backoff_timer2_d[35:0] =  36'b0;
    end // -- always @ *


  // -- ********************************************************************************************************************************
  // -- Latch assignments
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      rtry_backoff_timer_disable_int_q            <= rtry_backoff_timer_disable_int_d;

      cfg_afu_long_backoff_timer_q[3:0]           <= cfg_afu_long_backoff_timer_d[3:0];
      cfg_afu_short_backoff_timer_q[3:0]          <= cfg_afu_short_backoff_timer_d[3:0];

      // -- rtry backoff timer in_progress/done latches
      we_rtry_ld_backoff_in_progress_q            <= we_rtry_ld_backoff_in_progress_d;       
      we_rtry_ld_backoff_done_int_q               <= we_rtry_ld_backoff_done_int_d;
       
      xtouch_rtry_source_backoff_in_progress_q    <= xtouch_rtry_source_backoff_in_progress_d;
      xtouch_rtry_source_backoff_done_int_q       <= xtouch_rtry_source_backoff_done_int_d;

      xtouch_rtry_dest_backoff_in_progress_q      <= xtouch_rtry_dest_backoff_in_progress_d;
      xtouch_rtry_dest_backoff_done_int_q         <= xtouch_rtry_dest_backoff_done_int_d;

      cpy_rtry_ld_backoff_in_progress_q           <= cpy_rtry_ld_backoff_in_progress_d;
      cpy_rtry_ld_backoff_done_int_q              <= cpy_rtry_ld_backoff_done_int_d;

      cpy_rtry_st_backoff_in_progress_q           <= cpy_rtry_st_backoff_in_progress_d;
      cpy_rtry_st_backoff_done_int_q              <= cpy_rtry_st_backoff_done_int_d;

      wkhstthrd_rtry_backoff_in_progress_q        <= wkhstthrd_rtry_backoff_in_progress_d;
      wkhstthrd_rtry_backoff_done_int_q           <= wkhstthrd_rtry_backoff_done_int_d;

      incr_rtry_backoff_in_progress_q             <= incr_rtry_backoff_in_progress_d;
      incr_rtry_backoff_done_int_q                <= incr_rtry_backoff_done_int_d;

      atomic_rtry_backoff_in_progress_q           <= atomic_rtry_backoff_in_progress_d;
      atomic_rtry_backoff_done_int_q              <= atomic_rtry_backoff_done_int_d;

      intrpt_rtry_backoff_in_progress_q           <= intrpt_rtry_backoff_in_progress_d;
      intrpt_rtry_backoff_done_int_q              <= intrpt_rtry_backoff_done_int_d;

      we_rtry_st_backoff_in_progress_q            <= we_rtry_st_backoff_in_progress_d;       
      we_rtry_st_backoff_done_int_q               <= we_rtry_st_backoff_done_int_d;       

      // -- rtry backoff timer latches
      if ( rtry_backoff_timer1_en )      
        rtry_backoff_timer1_q[35:0]               <= rtry_backoff_timer1_d[35:0];

      if ( rtry_backoff_timer2_en )      
        rtry_backoff_timer2_q[35:0]               <= rtry_backoff_timer2_d[35:0];

      rtry_queue_empty_dly1_q                     <= rtry_queue_empty_dly1_d;


    end // -- always @ *

endmodule


  // -- Simple In/Out
  // --                          |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
  // --                          
  // -- *_backoff_done_q         __________________________________________________________________________________________________________________
  // --                                       _____
  // -- resp_is_*_rtry_w_backoff_q / wren ___|     |________________________________________________________________________________________________
  // --                                             _____
  // -- rden                     __________________|     |__________________________________________________________________________________________
  // --                          __________________       __________________________________________________________________________________________
  // -- empty                                      |_____|
  // --                          ________________________       ____________________________________________________________________________________
  // -- empty_dly1_q                                     |_____|
  // --                                       _____
  // -- *_backoff_start          ____________|     |________________________________________________________________________________________________
  // --                                             _________________________________________
  // -- *_backoff_in_progress_q  __________________|                                         |______________________________________________________
  // --                          __________________ _____ _____ _____ _____ _____ _____ _____ ______________________________________________________
  // -- *_backoff_timer          __________________X__7__X__6__X__5__X__4__X__3__X__2__X__1__X______________________________________________________
  // --                                                                                 _____
  // -- *_backoff_done           ______________________________________________________|     |______________________________________________________
  // --                          ____________________________________ _______________________ _______________________ ______________________________
  // -- *_rtry_seq_q             __________________1_________________X___________2___________X___________4___________X_________________1____________


  // --  Last one in queue
  // --                          |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
  // --                          ____________________________________
  // -- *_backoff_done_q                   hold this til -->   xxxxx |______________________________________________________________________________
  // --                                                
  // -- resp_is_*_rtry_w_backoff_q / wren __________________________________________________________________________________________________________
  // --                                             _____
  // -- rden                     __________________|     |______xxxxx_______________________________________________________________________________
  // --                                                   __________________________________________________________________________________________
  // -- empty                    ________________________|
  // --                                                         ____________________________________________________________________________________
  // -- empty_dly1_q             ______________________________|
  // --                                                         xxxxx  <--- latched output of rtry queue decoded here
  // -- *_backoff_start          ___________________________________________________________________________________________________________________
  // --                                                                                           
  // -- *_backoff_in_progress_q  ___________________________________________________________________________________________________________________
  // --                          ___________________________________________________________________________________________________________________
  // -- *_backoff_timer          ___________________________0's_____________________________________________________________________________________
  // --                                                                                      
  // -- *_backoff_done           ___________________________________________________________________________________________________________________
  // --                          ____________________________________ _______________________ ______________________________________________________
  // -- *_rtry_seq_q             __________________1_________________X___________4___________X___________1__________________________________________


  // -- 2nd comes in 1 cycle before done
  // --                          |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
  // --                                                                                       _________________________________________
  // -- *_backoff_done_q         ____________________________________________________________|                                         |____________
  // --                                       _____                               _____
  // -- resp_is_*_rtry_w_backoff_q / wren ___|     |_____________________________|     |____________________________________________________________
  // --                                             _____                                                             _____
  // -- rden                     __________________|     |______xxxxx________________________________________________|     |______xxxxx_____________
  // --                          __________________       _____________________________                                     ________________________
  // -- empty                                      |_____|                             |___________________________________|
  // --                          ________________________       _____________________________                                     __________________
  // -- empty_dly1_q                                     |_____|                             |___________________________________|
  // --                                       _____
  // -- *_backoff_start          ____________|     |________________________________________________________________________________________________
  // --                                             _________________________________________
  // -- *_backoff_in_progress_q  __________________|                                         |______________________________________________________
  // --                          __________________ _____ _____ _____ _____ _____ _____ _____ ______________________________________________________
  // -- *_backoff_timer          __________________X__7__X__6__X__5__X__4__X__3__X__2__X__1__X______________________________________________________
  // --                                                                                 _____
  // -- *_backoff_done           ______________________________________________________|     |______________________________________________________
  // --                          ____________________________________ _______________________ _______________________ _________________ ____________
  // -- *_rtry_seq_q             __________________1_________________X___________2___________X___________4___________X________1________X____________


  // -- 2nd comes in cycle of done
  // --                          |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
  // --                                                                                                                                   
  // -- *_backoff_done_q         ___________________________________________________________________________________________________________________
  // --                                       _____                                     _____
  // -- resp_is_*_rtry_w_backoff_q / wren ___|     |___________________________________|     |______________________________________________________
  // --                                             _____                                                             _____
  // -- rden                     __________________|     |______xxxxx________________________________________________|     |______xxxxx_____________
  // --                          __________________       ___________________________________                               ________________________
  // -- empty                                      |_____|                                   |_____________________________|
  // --                          ________________________       ___________________________________                               __________________
  // -- empty_dly1_q                                     |_____|                                   |_____________________________|
  // --                                       _____                                     _____
  // -- *_backoff_start          ____________|     |___________________________________|     |______________________________________________________
  // --                                             _________________________________________
  // -- *_backoff_in_progress_q  __________________|                                         |______________________________________________________
  // --                          __________________ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ ____________
  // -- *_backoff_timer          __________________X__7__X__6__X__5__X__4__X__3__X__2__X__1__X__7__X__6__X__5__X__4__X__3__X__2__X__1__X____________
  // --                                                                                 _____                                     _____
  // -- *_backoff_done           ______________________________________________________|     |___________________________________|     |____________
  // --                          ____________________________________ _______________________ _______________________ _________________ ____________
  // -- *_rtry_seq_q             __________________1_________________X___________2___________X___________4___________X________1________X________4___


  // -- 2nd comes in cycle of done
  // --                          |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
  // --                                                                                                                           _____
  // -- *_backoff_done_q         ________________________________________________________________________________________________|     |____________
  // --                                       _____                                     _____
  // -- resp_is_*_rtry_w_backoff_q / wren ___|     |___________________________________|     |______________________________________________________
  // --                                             _____                                                             _____
  // -- rden                     __________________|     |______xxxxx________________________________________________|     |______xxxxx_____________
  // --                          __________________       ___________________________________                               ________________________
  // -- empty                                      |_____|                                   |_____________________________|
  // --                          ________________________       ___________________________________                               __________________
  // -- empty_dly1_q                                     |_____|                                   |_____________________________|
  // --                                       _____                                     _____
  // -- *_backoff_start          ____________|     |___________________________________|     |______________________________________________________
  // --                                             _________________________________________
  // -- *_backoff_in_progress_q  __________________|                                         |______________________________________________________
  // --                          __________________ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ __________________
  // -- *_backoff_timer          __________________X__7__X__6__X__5__X__4__X__3__X__2__X__1__X__6__X__5__X__4__X__3__X__2__X__1__X__________________
  // --                                                                                 _____                               _____
  // -- *_backoff_done           ______________________________________________________|     |_____________________________|     |__________________
  // --                          ____________________________________ _______________________ _______________________ _________________ ____________
  // -- *_rtry_seq_q             __________________1_________________X___________2___________X___________4___________X________1________X_______4____



  // -- 2nd comes in cycle of done
  // --                          |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
  // --                                                                                                                                   
  // -- *_backoff_done_q         ___________________________________________________________________________________________________________________
  // --                                       _____                                     _____
  // -- resp_is_*_rtry_w_backoff_q / wren ___|     |___________________________________|     |______________________________________________________
  // --                                             _____                                                             _____
  // -- rden                     __________________|     |______xxxxx________________________________________________|     |______xxxxx_____________
  // --                          __________________       ___________________________________                               ________________________
  // -- empty                                      |_____|                                   |_____________________________|
  // --                          ________________________       ___________________________________                               __________________
  // -- empty_dly1_q                                     |_____|                                   |_____________________________|
  // --                                       _____                                     _____
  // -- *_backoff_start          ____________|     |___________________________________|     |______________________________________________________
  // --                                             _________________________________________
  // -- *_backoff_in_progress_q  __________________|                                         |______________________________________________________
  // --                          __________________ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ ______
  // -- *_backoff_timer          __________________X__7__X__6__X__5__X__4__X__3__X__2__X__1__X__8__X__7__X__6__X__5__X__4__X__3__X__2__X__1__X______
  // --                                                                                 _____                                           _____
  // -- *_backoff_done           ______________________________________________________|     |_________________________________________|     |______
  // --                          ____________________________________ _______________________ _______________________ _________________ _____ ______
  // -- *_rtry_seq_q             __________________1_________________X___________2___________X___________4___________X________1________X__2__X__4___



