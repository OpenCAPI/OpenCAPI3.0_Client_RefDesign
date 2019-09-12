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

module mcp3_trace (

  // -- Clocks & Reset
    input                 clock_tlx
  , input                 clock_afu
  , input                 reset

  , input                 unexpected_xlate_or_intrpt_done_200

  // -- Trace array current write address pointers
  , input                 trace_rspi_wraddr_reset
  , output         [10:0] trace_rspi_wraddr
  , input                 trace_cmdo_wraddr_reset
  , output         [10:0] trace_cmdo_wraddr
  , input                 trace_cmdi_rspo_wraddr_reset
  , output         [10:0] trace_cmdi_rspo_wraddr

  // -- Trace array trigger enables for rspi interface
  , input                 trace_tlx_afu_resp_data_valid_en
  , input                 trace_afu_tlx_resp_rd_req_en
  , input                 trace_afu_tlx_resp_credit_en             
  , input                 trace_tlx_afu_resp_valid_retry_en          
  , input                 trace_tlx_afu_resp_valid_no_data_en
  , input                 trace_tlx_afu_resp_valid_with_data_en

  // -- Trace array trigger enables for cmdo interface
  , input                 trace_tlx_afu_cmd_data_credit_en
  , input                 trace_tlx_afu_cmd_credit_en
  , input                 trace_afu_tlx_cdata_valid_en       
  , input                 trace_afu_tlx_cmd_valid_en          

  // -- Trace array trigger enables for cmdi_rspo interface
  , input                 trace_tlx_afu_resp_data_credit_en
  , input                 trace_tlx_afu_resp_credit_en
  , input                 trace_afu_tlx_rdata_valid_en
  , input                 trace_afu_tlx_resp_valid_en

  , input                 trace_afu_tlx_cmd_credit_en
  , input                 trace_afu_tlx_cmd_rd_req_en
  , input                 trace_tlx_afu_cmd_data_valid_en
  , input                 trace_tlx_afu_cmd_valid_en

  // -- Trace array controls
  , input                 trace_no_wrap
  , input                 trace_eng_en
  , input           [4:0] trace_eng_num
  , input                 trace_events
  , input                 trace_arm


  // -- TLX_AFU Command Receive Bus Trace inputs   (MMIO requests)
//, input                 trace_tlx_afu_ready

  , input                 trace_tlx_afu_cmd_valid
  , input           [7:0] trace_tlx_afu_cmd_opcode    // -- could get by with just 2 bits for read/write, Rd = b'00101000,  Wr = b'10000110
  , input          [15:0] trace_tlx_afu_cmd_capptag
//, input           [1:0] trace_tlx_afu_cmd_dl        // -- never used within memcpy as all mem ops should be partial of 8B 
  , input           [2:0] trace_tlx_afu_cmd_pl        // -- Expected to always be b'011 for 8B operations
//, input          [63:0] trace_tlx_afu_cmd_be
//, input                 trace_tlx_afu_cmd_end
//, input                 trace_tlx_afu_cmd_t
  , input          [25:0] trace_tlx_afu_cmd_pa
//, input           [3:0] trace_tlx_afu_cmd_flag
//, input                 trace_tlx_afu_cmd_os

  , input                 trace_tlx_afu_cmd_data_valid
  , input                 trace_tlx_afu_cmd_data_bdi
  , input          [63:0] trace_tlx_afu_cmd_data_bus  // -- This will give visibility as WED being written

  , input                 trace_afu_tlx_cmd_rd_req
//, input           [2:0] trace_afu_tlx_cmd_rd_cnt    // -- no need to trace this, hard coded to b'001

  , input                 trace_afu_tlx_cmd_credit    // -- only need to trace single bit because only 1 initial credit given to tlx (single threaded)

  , input                 trace_tlx_afu_mmio_rd_cmd_valid
  , input                 trace_tlx_afu_mmio_wr_cmd_valid

  // -- AFU_TLX Response Transmit Bus Trace inputs   (MMIO responses)
  , input                 trace_afu_tlx_resp_valid
  , input           [3:0] trace_afu_tlx_resp_opcode   // -- Only need bottom 3 bits:  b'001 = Rd Resp
  , input           [1:0] trace_afu_tlx_resp_dl
  , input          [15:0] trace_afu_tlx_resp_capptag
//, input           [1:0] trace_afu_tlx_resp_dp       // -- resp_dp is always b'00
  , input           [3:0] trace_afu_tlx_resp_code

  , input                 trace_afu_tlx_rdata_valid
//, input                 trace_afu_tlx_rdata_bdi     // -- rdata_bdi is always b'0
//, input          [63:0] trace_afu_tlx_rdata_bus     // -- Tracing MMIO read data is probably not of interest

  , input                 trace_tlx_afu_resp_credit
  , input                 trace_tlx_afu_resp_data_credit

  , input           [3:0] trace_rspo_avail_resp_credit       // -- only ever expect to consume 1 of the initial credits
  , input           [5:0] trace_rspo_avail_resp_data_credit  // -- only ever expect to consume 1 of the initial credits


  // -- AFU_TLX Command Transmit Bus Trace inputs
  , input                 trace_afu_tlx_cmd_valid
  , input           [7:0] trace_afu_tlx_cmd_opcode
  , input           [5:0] trace_afu_tlx_cmd_actag
//, input           [3:0] trace_afu_tlx_cmd_stream_id
  , input          [67:0] trace_afu_tlx_cmd_ea_or_obj
  , input          [15:0] trace_afu_tlx_cmd_afutag
  , input           [1:0] trace_afu_tlx_cmd_dl
  , input           [2:0] trace_afu_tlx_cmd_pl
//, input                 trace_afu_tlx_cmd_os
//, input          [63:0] trace_afu_tlx_cmd_be
  , input           [3:0] trace_afu_tlx_cmd_flag
//, input                 trace_afu_tlx_cmd_endian
//, input          [15:0] trace_afu_tlx_cmd_bdf
  , input           [9:0] trace_afu_tlx_cmd_pasid
  , input           [5:0] trace_afu_tlx_cmd_pg_size

  , input                 trace_afu_tlx_cdata_valid
//, input                 trace_afu_tlx_cdata_bdi
//, input        [1023:0] trace_afu_tlx_cdata_bus

  , input           [1:0] trace_tlx_afu_cmd_credit
  , input           [1:0] trace_tlx_afu_cmd_data_credit

  , input           [4:0] trace_cmdo_avail_cmd_credit
  , input           [6:0] trace_cmdo_avail_cmd_data_credit

  // -- TLX_AFU Response Receive Bus Trace inputs
  , input                 trace_tlx_afu_resp_valid_with_data
  , input                 trace_tlx_afu_resp_valid_no_data
  , input                 trace_tlx_afu_resp_valid_retry
  , input          [15:0] trace_tlx_afu_resp_afutag
  , input           [7:0] trace_tlx_afu_resp_opcode
  , input           [3:0] trace_tlx_afu_resp_code
  , input           [1:0] trace_tlx_afu_resp_dl
  , input           [1:0] trace_tlx_afu_resp_dp
//, input           [5:0] trace_tlx_afu_resp_pg_size
//, input          [17:0] trace_tlx_afu_resp_addr_tag

  , input                 trace_afu_tlx_resp_rd_req
  , input           [2:0] trace_afu_tlx_resp_rd_cnt

  , input                 trace_tlx_afu_resp_data_valid
  , input           [1:0] trace_tlx_afu_resp_data_bdi
//, input         [511:0] trace_tlx_afu_resp_data_bus

  , input                 trace_afu_tlx_resp_credit            // -- AFU returns resp credit to TLX

  // -- Display Read
  , input                 mmio_trace_display_rdval   // -- This is a pulse (sel, addr, and offset are static)
  , input           [8:0] mmio_trace_display_addr    // -- This picks a row in all arrays
  , input           [3:0] mmio_trace_display_offset  // -- This picks a data register (64 bits from one of the arrays)

  , output                trace_mmio_display_rddata_valid
  , output         [63:0] trace_mmio_display_rddata

  );


  // --****************************************************************************
  // -- Signal declarations
  // --****************************************************************************

  wire            trace_cmdi_rspo_wren;
  wire    [191:0] trace_cmdi_rspo_wrdata;
  wire            trace_cmdi_rspo_rden;
  wire      [8:0] trace_cmdi_rspo_rdaddr;
  wire    [191:0] trace_cmdi_rspo_rddata;

  wire            trace_cmdo_wren;
  wire    [179:0] trace_cmdo_wrdata;
  wire            trace_cmdo_rden;
  wire      [8:0] trace_cmdo_rdaddr;
  wire    [179:0] trace_cmdo_rddata;

  wire            trace_rspi_wren;
  wire     [79:0] trace_rspi_wrdata;
  wire            trace_rspi_rden;
  wire      [8:0] trace_rspi_rdaddr;
  wire     [79:0] trace_rspi_rddata;

  wire      [9:0] trace_unused;

  // -- ILA trigger signals
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            any_st_fail;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            any_ld_fail;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            any_fail;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  wire            we_ld_fail;

  // --****************************************************************************
  // -- Latch Signal declarations (including enable signals)
  // --****************************************************************************

  // -- Even/Odd latches
  wire            toggle_d;                                                                                                                
  reg             toggle_q;                                                                                                                
  wire            sample_d;                                                                                                                
  reg             sample_q;                                                                                                                
  wire            odd_d;                                                                                                                   
  reg             odd_q;                                                                                                                   
  wire            even_d;                                                                                                                  
  (* keep = "true", max_fanout = 128 *) reg             even_q;                                                                                                                  


  reg      [35:0] trace_timestamp_d;
  reg      [35:0] trace_timestamp_q;

  reg       [8:0] trace_cmdi_rspo_wraddr_d;
  reg       [8:0] trace_cmdi_rspo_wraddr_q;

  reg       [8:0] trace_cmdo_wraddr_d;
  reg       [8:0] trace_cmdo_wraddr_q;

  reg       [8:0] trace_rspi_wraddr_d;
  reg       [8:0] trace_rspi_wraddr_q;

  wire            trace_cmdi_rspo_wrapped_d;
  reg             trace_cmdi_rspo_wrapped_q;
  wire            trace_cmdo_wrapped_d;
  reg             trace_cmdo_wrapped_q;
  wire            trace_rspi_wrapped_d;
  reg             trace_rspi_wrapped_q;

  wire            trace_display_rdval_d;
  reg             trace_display_rdval_q;
  wire            trace_display_rdval_dly1_d;
  reg             trace_display_rdval_dly1_q;
  wire            trace_display_rdval_dly2_d;
  reg             trace_display_rdval_dly2_q;
  wire            trace_display_addr_en;
  wire      [8:0] trace_display_addr_d;
  reg       [8:0] trace_display_addr_q;
  wire            trace_display_offset_en;
  wire      [3:0] trace_display_offset_d;
  reg       [3:0] trace_display_offset_q;
  wire            trace_display_rddata_en;
  reg      [63:0] trace_display_rddata_d;
  reg      [63:0] trace_display_rddata_q;

  wire            unexpected_xlate_or_intrpt_done_400_d;
  `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg             unexpected_xlate_or_intrpt_done_400_q;


  // -- ********************************************************************************************************************************
  // -- Constant declarations
  // -- ********************************************************************************************************************************

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

  // -- TL CAP response code encodes
  localparam    [3:0] TLX_AFU_RESP_CODE_DONE                   = 4'b0000;      // -- Done
  localparam    [3:0] TLX_AFU_RESP_CODE_RTY_HWT                = 4'b0001;      // -- Retry Xlate Touch w/ Heavy Weight
  localparam    [3:0] TLX_AFU_RESP_CODE_RTY_REQ                = 4'b0010;      // -- Retry Heavy weight (long backoff timer)                                 
  localparam    [3:0] TLX_AFU_RESP_CODE_LW_RTY_REQ             = 4'b0011;      // -- Retry Light Weight (short backoff timer)                                 
  localparam    [3:0] TLX_AFU_RESP_CODE_XLATE_PENDING          = 4'b0100;      // -- Toss, wait for xlate done with same AFU tag, convert to Retry
  localparam    [3:0] TLX_AFU_RESP_CODE_INTRP_PENDING          = 4'b0100;      // -- Toss, wait for intrp rdy with same AFU tag, convert to Retry
  localparam    [3:0] TLX_AFU_RESP_CODE_THREAD_NOT_FOUND       = 4'b0101;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_DERROR                 = 4'b1000;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_LENGTH             = 4'b1001;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_ADDR               = 4'b1011;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_BAD_HANDLE             = 4'b1011;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_FAILED                 = 4'b1110;      // -- Machine Check
  localparam    [3:0] TLX_AFU_RESP_CODE_ADR_ERROR              = 4'b1111;      // -- Machine Check

  // -- AFUTAG Encode
  localparam    [4:0] ACTAG_AFUTAG_ENCODE                      = 5'b00000;     // -- AFUTAG[4:0] for actag cmd                   ( AFUTAG[11] = b'1 )
  localparam    [4:0] WE_LD_AFUTAG_ENCODE                      = 5'b00001;     // -- AFUTAG[4:0] for we_ld cmd                   ( AFUTAG[11] = b'1 )
  localparam    [4:0] XTOUCH_SOURCE_AFUTAG_ENCODE              = 5'b00010;     // -- AFUTAG[4:0] for xtouch_source cmd           ( AFUTAG[11] = b'1 )
  localparam    [4:0] XTOUCH_DEST_AFUTAG_ENCODE                = 5'b00011;     // -- AFUTAG[4:0] for xtouch_dest cmd             ( AFUTAG[11] = b'1 )
  localparam    [4:0] WKHSTTHRD_AFUTAG_ENCODE                  = 5'b00110;     // -- AFUTAG[4:0] for wkhstthrd cmd               ( AFUTAG[11] = b'1 )
  localparam    [4:0] INTRPT_WHT_AFUTAG_ENCODE                 = 5'b00111;     // -- AFUTAG[4:0] for intrpt due to wkhstthrd cmd ( AFUTAG[11] = b'1, AFUTAG[12] = b'1 if "intrpt_w_data" )
  localparam    [4:0] INCR_LD_AFUTAG_ENCODE                    = 5'b01000;     // -- AFUTAG[4:0] for incr ld cmd                 ( AFUTAG[11] = b'1 )
  localparam    [4:0] INCR_ST_AFUTAG_ENCODE                    = 5'b01001;     // -- AFUTAG[4:0] for incr st cmd                 ( AFUTAG[11] = b'1 )
  localparam    [4:0] ATOMIC_LD_AFUTAG_ENCODE                  = 5'b01010;     // -- AFUTAG[4:0] for atomic ld cmd               ( AFUTAG[11] = b'1 )
  localparam    [4:0] ATOMIC_ST_AFUTAG_ENCODE                  = 5'b01011;     // -- AFUTAG[4:0] for atomic st cmd               ( AFUTAG[11] = b'1 )
  localparam    [4:0] ATOMIC_CAS_AFUTAG_ENCODE                 = 5'b01100;     // -- AFUTAG[4:0] for atomic cas cmd              ( AFUTAG[11] = b'1 )
  localparam    [4:0] INTRPT_ERR_AFUTAG_ENCODE                 = 5'b01101;     // -- AFUTAG[4:0] for intrpt due to error         ( AFUTAG[11] = b'1, AFUTAG[12] = b'1 if "intrpt_w_data" )
  localparam    [4:0] INTRPT_CMD_AFUTAG_ENCODE                 = 5'b01110;     // -- AFUTAG[4:0] for intrpt cmd                  ( AFUTAG[11] = b'1, AFUTAG[12] = b'1 if "intrpt_w_data" )
  localparam    [4:0] WE_ST_AFUTAG_ENCODE                      = 5'b01111;     // -- AFUTAG[4:0] for we_ld cmd                   ( AFUTAG[11] = b'1 )


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


  // -- ********************************************************************************************************************************
  // -- Add trigger for ILA
  // -- ********************************************************************************************************************************

  assign  any_st_fail =  ( trace_tlx_afu_resp_valid_no_data && (trace_tlx_afu_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_WRITE_FAILED[7:0]) &&
                                                              ((trace_tlx_afu_resp_code[3:0] == TLX_AFU_RESP_CODE_DERROR[3:0])     ||   
                                                               (trace_tlx_afu_resp_code[3:0] == TLX_AFU_RESP_CODE_BAD_LENGTH[3:0]) ||
                                                               (trace_tlx_afu_resp_code[3:0] == TLX_AFU_RESP_CODE_BAD_ADDR[3:0])   ||
                                                               (trace_tlx_afu_resp_code[3:0] == TLX_AFU_RESP_CODE_FAILED[3:0])));


  assign  any_ld_fail =  ( trace_tlx_afu_resp_valid_no_data && (trace_tlx_afu_resp_opcode[7:0] == TLX_AFU_RESP_ENCODE_READ_FAILED[7:0]) &&
                                                              ((trace_tlx_afu_resp_code[3:0] == TLX_AFU_RESP_CODE_DERROR[3:0])     ||   
                                                               (trace_tlx_afu_resp_code[3:0] == TLX_AFU_RESP_CODE_BAD_LENGTH[3:0]) ||
                                                               (trace_tlx_afu_resp_code[3:0] == TLX_AFU_RESP_CODE_BAD_ADDR[3:0])   ||
                                                               (trace_tlx_afu_resp_code[3:0] == TLX_AFU_RESP_CODE_FAILED[3:0])));

  assign  any_fail    =  ( any_st_fail || any_ld_fail );

  assign  we_ld_fail  =  ( any_ld_fail && ( trace_tlx_afu_resp_afutag[11] == 1'b1 ) && ( trace_tlx_afu_resp_afutag[4:0] == WE_LD_AFUTAG_ENCODE[4:0] ));


  // -- ********************************************************************************************************************************
  // -- Timestamp timer
  // -- ********************************************************************************************************************************

  always @*
    begin
     if ( reset )
       trace_timestamp_d[35:0] =  36'b0;
     else
       trace_timestamp_d[35:0] =  trace_timestamp_q[35:0] + 36'b1;
    end  // -- always @*


  // -- ********************************************************************************************************************************
  // -- Form the write data for the interfaces
  // -- ********************************************************************************************************************************

  // -- The TLX_AFU cmd in and AFU_TLX resp out is a single threaded interface
  // -- The signals originate from latches in the 400MHz clock domain within the mcp3_cmdi_rspo module
  // --   The entire interface (both cmd in and resp out) will be traced in a single array

  // -- form the cmdi_rspo trace array write data
  assign  trace_cmdi_rspo_wrdata[191:128] =  trace_tlx_afu_cmd_data_bus[63:0];

  assign  trace_cmdi_rspo_wrdata[127:96]  =  trace_timestamp_q[31:0];
  assign  trace_cmdi_rspo_wrdata[95:80]   =  trace_afu_tlx_resp_capptag[15:0];
  assign  trace_cmdi_rspo_wrdata[79]      =  trace_rspo_avail_resp_data_credit[0];// -- only ever expect to consume 1 of the initial credits
  assign  trace_cmdi_rspo_wrdata[78]      =  trace_rspo_avail_resp_credit[0];     // -- only ever expect to consume 1 of the initial credits
  assign  trace_cmdi_rspo_wrdata[77:76]   =  trace_afu_tlx_resp_dl[1:0];          // -- only ever expect dl to be driven to b'01 on rd/wr responses (b'00 on fail responses)
  assign  trace_cmdi_rspo_wrdata[75:72]   =  trace_afu_tlx_resp_code[3:0];        // -- only ever expect x'0, x'8, x'9, x'B, x'E
  assign  trace_cmdi_rspo_wrdata[71:68]   =  trace_afu_tlx_resp_opcode[3:0];      // -- only ever expect x'1, x'2, x'4, x'5
  assign  trace_cmdi_rspo_wrdata[67]      =  trace_tlx_afu_resp_data_credit;      // -- trigger source
  assign  trace_cmdi_rspo_wrdata[66]      =  trace_tlx_afu_resp_credit;           // -- trigger source
  assign  trace_cmdi_rspo_wrdata[65]      =  trace_afu_tlx_rdata_valid;           // -- trigger source
  assign  trace_cmdi_rspo_wrdata[64]      =  trace_afu_tlx_resp_valid;            // -- trigger source

  assign  trace_cmdi_rspo_wrdata[63:60]   =  trace_timestamp_q[35:32];
  assign  trace_cmdi_rspo_wrdata[59]      =  trace_tlx_afu_mmio_wr_cmd_valid;
  assign  trace_cmdi_rspo_wrdata[58]      =  trace_tlx_afu_mmio_rd_cmd_valid;
  assign  trace_cmdi_rspo_wrdata[57:32]   =  trace_tlx_afu_cmd_pa[25:0];
  assign  trace_cmdi_rspo_wrdata[31:16]   =  trace_tlx_afu_cmd_capptag[15:0];
  assign  trace_cmdi_rspo_wrdata[15]      =  trace_tlx_afu_cmd_data_bdi;
  assign  trace_cmdi_rspo_wrdata[14:12]   =  trace_tlx_afu_cmd_pl[2:0];
  assign  trace_cmdi_rspo_wrdata[11:4]    =  trace_tlx_afu_cmd_opcode[7:0];
  assign  trace_cmdi_rspo_wrdata[3]       =  trace_afu_tlx_cmd_credit;            // -- trigger source
  assign  trace_cmdi_rspo_wrdata[2]       =  trace_afu_tlx_cmd_rd_req;            // -- trigger source
  assign  trace_cmdi_rspo_wrdata[1]       =  trace_tlx_afu_cmd_data_valid;        // -- trigger source
  assign  trace_cmdi_rspo_wrdata[0]       =  trace_tlx_afu_cmd_valid;             // -- trigger source


  // -- Trace data for both the cmdo and rspi arrays is sourced from latches in the 200MHz clock domain

  // -- form the cmdo trace array write data
  assign  trace_cmdo_wrdata[179:144]      =  trace_timestamp_q[35:0];
  assign  trace_cmdo_wrdata[143]          =  trace_cmdo_avail_cmd_credit[4];
  assign  trace_cmdo_wrdata[142:136]      =  trace_cmdo_avail_cmd_data_credit[6:0];
  assign  trace_cmdo_wrdata[135:132]      =  trace_cmdo_avail_cmd_credit[3:0];
  assign  trace_cmdo_wrdata[131:128]      =  trace_afu_tlx_cmd_ea_or_obj[67:64];

  assign  trace_cmdo_wrdata[127:64]       =  trace_afu_tlx_cmd_ea_or_obj[63:0];

  assign  trace_cmdo_wrdata[63:60]        =  trace_afu_tlx_cmd_pg_size[5:2];
  assign  trace_cmdo_wrdata[59]           =  1'b0;
  assign  trace_cmdo_wrdata[58:56]        =  trace_afu_tlx_cmd_pl[2:0];
  assign  trace_cmdo_wrdata[55:52]        =  trace_afu_tlx_cmd_flag[3:0];
  assign  trace_cmdo_wrdata[51:50]        =  2'b0;
  assign  trace_cmdo_wrdata[49:44]        =  trace_afu_tlx_cmd_actag[5:0];
  assign  trace_cmdo_wrdata[43:42]        =  2'b0;
  assign  trace_cmdo_wrdata[41:32]        =  trace_afu_tlx_cmd_pasid[9:0];
  assign  trace_cmdo_wrdata[31:16]        =  trace_afu_tlx_cmd_afutag[15:0];
  assign  trace_cmdo_wrdata[15:8]         =  trace_afu_tlx_cmd_opcode[7:0];
  assign  trace_cmdo_wrdata[7:6]          =  trace_afu_tlx_cmd_dl[1:0];
  assign  trace_cmdo_wrdata[5:4]          =  trace_tlx_afu_cmd_data_credit[1:0];  // -- trigger source (odd/even)
  assign  trace_cmdo_wrdata[3:2]          =  trace_tlx_afu_cmd_credit[1:0];       // -- trigger source (odd/even)
  assign  trace_cmdo_wrdata[1]            =  trace_afu_tlx_cdata_valid;           // -- trigger source
  assign  trace_cmdo_wrdata[0]            =  trace_afu_tlx_cmd_valid;             // -- trigger source

  // -- form the rspi trace array write data

  assign  trace_rspi_wrdata[79:44]        =  trace_timestamp_q[35:0];
  assign  trace_rspi_wrdata[43:42]        =  trace_tlx_afu_resp_dp[1:0];
  assign  trace_rspi_wrdata[41:40]        =  trace_tlx_afu_resp_dl[1:0];
  assign  trace_rspi_wrdata[39:24]        =  trace_tlx_afu_resp_afutag[15:0];
  assign  trace_rspi_wrdata[23:20]        =  trace_tlx_afu_resp_code[3:0];
  assign  trace_rspi_wrdata[19:12]        =  trace_tlx_afu_resp_opcode[7:0];
  assign  trace_rspi_wrdata[11]           =  1'b0;
  assign  trace_rspi_wrdata[10:8]         =  trace_afu_tlx_resp_rd_cnt[2:0]; 
  assign  trace_rspi_wrdata[7:6]          =  trace_tlx_afu_resp_data_bdi[1:0]; 
  assign  trace_rspi_wrdata[5]            =  trace_tlx_afu_resp_data_valid;       // -- trigger source
  assign  trace_rspi_wrdata[4]            =  trace_afu_tlx_resp_rd_req;           // -- trigger source

  assign  trace_rspi_wrdata[3]            =  trace_afu_tlx_resp_credit;           // -- trigger source
  assign  trace_rspi_wrdata[2]            =  trace_tlx_afu_resp_valid_retry;      // -- trigger source
  assign  trace_rspi_wrdata[1]            =  trace_tlx_afu_resp_valid_no_data;    // -- trigger source
  assign  trace_rspi_wrdata[0]            =  trace_tlx_afu_resp_valid_with_data;  // -- trigger source


  // -- 8 registers total


  // -- ********************************************************************************************************************************
  // -- Write Controls
  // -- ********************************************************************************************************************************

  assign  trace_cmdi_rspo_wren =   ( trace_arm && (~trace_no_wrap || (trace_no_wrap && ~trace_cmdi_rspo_wrapped_q)) && (~trace_events ||
                                   ( trace_events && 
                                  (( trace_tlx_afu_resp_data_credit && trace_tlx_afu_resp_data_credit_en ) ||
                                   ( trace_tlx_afu_resp_credit      && trace_tlx_afu_resp_credit_en      ) ||
                                   ( trace_afu_tlx_rdata_valid      && trace_afu_tlx_rdata_valid_en      ) ||
                                   ( trace_afu_tlx_resp_valid       && trace_afu_tlx_resp_valid_en       ) ||
                                                                    
                                   ( trace_afu_tlx_cmd_credit       && trace_afu_tlx_cmd_credit_en       ) ||
                                   ( trace_afu_tlx_cmd_rd_req       && trace_afu_tlx_cmd_rd_req_en       ) ||
                                   ( trace_tlx_afu_cmd_data_valid   && trace_tlx_afu_cmd_data_valid_en   ) ||
                                   ( trace_tlx_afu_cmd_valid        && trace_tlx_afu_cmd_valid_en        ))))); 

  assign  trace_cmdo_wren =    ( trace_arm &&
                               (~trace_no_wrap || ( trace_no_wrap && ~trace_cmdo_wrapped_q)) &&
                               (~trace_eng_en  || ( trace_eng_en  && ( trace_eng_num[4:0] == trace_afu_tlx_cmd_afutag[9:5] ))) &&
                               (~trace_events  || ( trace_events  && ((( trace_tlx_afu_cmd_data_credit[1:0] != 2'b00 )  && trace_tlx_afu_cmd_data_credit_en ) ||
                                                                      (( trace_tlx_afu_cmd_credit[1:0] != 2'b00 )       && trace_tlx_afu_cmd_credit_en      ) ||
                                                                       ( trace_afu_tlx_cdata_valid                      && trace_afu_tlx_cdata_valid_en     ) ||   
                                                                       ( trace_afu_tlx_cmd_valid                        && trace_afu_tlx_cmd_valid_en       )))));     

  assign  trace_rspi_wren =    ( trace_arm &&
                               (~trace_no_wrap || ( trace_no_wrap && ~trace_rspi_wrapped_q)) &&
                               (~trace_eng_en  || ( trace_eng_en  && ( trace_eng_num[4:0] == trace_tlx_afu_resp_afutag[9:5] ))) &&
                               (~trace_events  || ( trace_events  && (( trace_tlx_afu_resp_data_valid      && trace_tlx_afu_resp_data_valid_en      ) ||
                                                                      ( trace_afu_tlx_resp_rd_req          && trace_afu_tlx_resp_rd_req_en          ) ||
                                                                      ( trace_afu_tlx_resp_credit          && trace_afu_tlx_resp_credit_en          ) ||   
                                                                      ( trace_tlx_afu_resp_valid_retry     && trace_tlx_afu_resp_valid_retry_en     ) ||     
                                                                      ( trace_tlx_afu_resp_valid_no_data   && trace_tlx_afu_resp_valid_no_data_en   ) ||
                                                                      ( trace_tlx_afu_resp_valid_with_data && trace_tlx_afu_resp_valid_with_data_en )))));


  assign  trace_cmdi_rspo_wrapped_d =  ( trace_cmdi_rspo_wren &&  & trace_cmdi_rspo_wraddr_q[8:0] && ~reset && ~trace_cmdi_rspo_wraddr_reset );
  assign  trace_cmdo_wrapped_d      =  ( trace_cmdo_wren      &&  & trace_cmdo_wraddr_q[8:0]      && ~reset && ~trace_cmdo_wraddr_reset );
  assign  trace_rspi_wrapped_d      =  ( trace_cmdo_wren      &&  & trace_rspi_wraddr_q[8:0]      && ~reset && ~trace_rspi_wraddr_reset);


  always @*
    begin
      if ( reset || trace_cmdi_rspo_wraddr_reset || ( & trace_cmdi_rspo_wraddr_q[8:0] && trace_cmdi_rspo_wren ))
        trace_cmdi_rspo_wraddr_d[8:0] =  9'b0;
      else if ( trace_cmdi_rspo_wren )
        trace_cmdi_rspo_wraddr_d[8:0] =  trace_cmdi_rspo_wraddr_q[8:0] + 9'b1;
      else
        trace_cmdi_rspo_wraddr_d[8:0] =  trace_cmdi_rspo_wraddr_q[8:0];

    end  // -- always @*

  assign  trace_cmdi_rspo_wraddr[10:0] =  { trace_cmdi_rspo_wrapped_q, 1'b0, trace_cmdi_rspo_wraddr_q[8:0] };  // -- Send to MMIO to track current write pointer

  always @*
    begin
      if ( reset || trace_cmdo_wraddr_reset || ( & trace_cmdo_wraddr_q[8:0] && trace_cmdo_wren ))
        trace_cmdo_wraddr_d[8:0] =  9'b0;
      else if ( trace_cmdo_wren )
        trace_cmdo_wraddr_d[8:0] =  trace_cmdo_wraddr_q[8:0] + 9'b1;
      else
        trace_cmdo_wraddr_d[8:0] =  trace_cmdo_wraddr_q[8:0];

    end  // -- always @*

  assign  trace_cmdo_wraddr[10:0] =  { trace_cmdo_wrapped_q, 1'b0, trace_cmdo_wraddr_q[8:0] };  // -- Send to MMIO to track current write pointer

  always @*
    begin
      if ( reset || trace_rspi_wraddr_reset || ( & trace_rspi_wraddr_q[8:0] && trace_rspi_wren ))
        trace_rspi_wraddr_d[8:0] =  9'b0;
      else if ( trace_rspi_wren )
        trace_rspi_wraddr_d[8:0] =  trace_rspi_wraddr_q[8:0] + 9'b1;
      else
        trace_rspi_wraddr_d[8:0] =  trace_rspi_wraddr_q[8:0];

    end  // -- always @*

  assign  trace_rspi_wraddr[10:0] =  { trace_rspi_wrapped_q, 1'b0, trace_rspi_wraddr_q[8:0] };  // -- Send to MMIO to track current write pointer


  // -- ********************************************************************************************************************************
  // -- Read Controls
  // -- ********************************************************************************************************************************


  // -- The reads will be done via a generic array display interface

  // -- Display_Control Register
  // --
  // -- [31:28] - Module and Array select
  // --         - b'1000 - mcp3_trace - Trace Array    512 x ~64B 
  // --         - b'1000 - mcp3_rspi  - Response Queue 128 x 36
  // --         - b'0100 - mcp3_weq   - Response Queue 128 x 36
  // --         - b'0001 - mcp3_cpeng - Retry Queue     32 x 
  // --         - b'0000 - mcp3_cpeng - Data Buffer     32 x 64B
  // --
  // -- [27:12] - Address (Differs by unit)
  // --      - trace Trace Arrau
  // --         - [27:21] - Not Used
  // --         - [20:12] - Entry number (0-511)
  // --      - rspi Response Queue
  // --         - [27:19] - Not Used
  // --         - [18:12] - Entry number (0-127)
  // --      - cpeng Retry Queue
  // --         - [27:25] - Not Used
  // --         - [24:20] - Engine # (0-31) 
  // --         - [19:17] - Not Used
  // --         - [16:12] - Entry number (0-31)
  // --      - cpeng data buffer
  // --         - [27:25] - Not Used
  // --         - [24:20] - Engine # (0-31)
  // --         - [19:17] - Not Used
  // --         - [16:12] - 64B Buffer number (0-31)
  // --
  // -- [11:8]  - Starting Data Reg
  // --      - trace Trace Arrau
  // --         - [11]    - Not Used
  // --         - [10:8]  - Reg offset - currently all trace data fits in 8 regs
  // --      - rspi Response Queue
  // --         - [11:8]  - Not Used
  // --      - cpeng Retry Queue
  // --         - [11:8]  - Not Used
  // --      - cpeng data buffer
  // --         - [11]    - Not Used
  // --         - [10:8]  - 8B offset within 64B Buffer number
  // --
  // -- [7:4]   - AutoIncr Data Reg Engode that Triggers the address to increment
  // --
  // -- [3]     - Unused
  // -- [2]     - AutoIncr Enable
  // -- [1]     - Write ( b'1 = Write if supported.  b'0 = Read)
  // -- [0]     - Valid - 1 cycle pulse (400MHz) - Self clears

  // -- Clock    |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |   .   |
  // --               ___ ...
  // -- display_wr __|   |_______________________________________________________________________________________________________________
  // --                   ___ ...
  // -- valid_q    ______|   |___________________________________________________________________________________________________________
  // --                       ___ ...
  // -- valid_dly_q _________|   |_______________________________________________________________________________________________________
  // --                       _______________________
  // -- disp_rd_pending_q ___|                       |___________________________________________________________________________________
  // --                   _______________________________________________________________________________________________________________
  // -- display_reg_q ---<_______________________________________________________________________________________________________________
  // --                           _______
  // -- valid_200_q    __________|       |_______________________________________________________________________________________________
  // --                           _______________________________________________________________________________________________________
  // -- display_200_q -----------<_______________________________________________________________________________________________________
  // --                           _______
  // -- rden           __________|       |_______________________________________________________________________________________________
  // --                                   _______
  // -- rddata_200     ------------------<_______>---------------------------------------------------------------------------------------
  // --                                   ___ ___
  // -- rddata_400     ------------------<___X___>---------------------------------------------------------------------------------------
  // --                                           _______
  // -- rddata_q(200)  --------------------------<_______>-------------------------------------------------------------------------------
  // --                                           _______
  // -- rddata_valid_q __________________________|       |_______________________________________________________________________________
  // -- 

  assign  trace_display_rdval_d       =  mmio_trace_display_rdval;
  assign  trace_display_rdval_dly1_d  =  trace_display_rdval_q;
  assign  trace_display_rdval_dly2_d  =  trace_display_rdval_dly1_q;

  assign  trace_display_addr_en       =  ( reset || trace_display_rdval_d );
  assign  trace_display_addr_d[8:0]   =    mmio_trace_display_addr[8:0];

  assign  trace_display_offset_en     =  ( reset || trace_display_rdval_d );
  assign  trace_display_offset_d[3:0] =    mmio_trace_display_offset[3:0];

  assign  trace_cmdi_rspo_rdaddr[8:0] =  trace_display_addr_q[8:0]; 
  assign  trace_rspi_rdaddr[8:0]      =  trace_display_addr_q[8:0]; 
  assign  trace_cmdo_rdaddr[8:0]      =  trace_display_addr_q[8:0]; 

  assign  trace_cmdi_rspo_rden        =  trace_display_rdval_q && ( trace_display_offset_q[3:0] <= 4'b0111 ) && ( trace_display_offset_q[3:0] >= 4'b0101 );
  assign  trace_rspi_rden             =  trace_display_rdval_q && ( trace_display_offset_q[3:0] <= 4'b0100 ) && ( trace_display_offset_q[3:0] >= 4'b0011 );
  assign  trace_cmdo_rden             =  trace_display_rdval_q && ( trace_display_offset_q[3:0] <= 4'b0010 ) && ( trace_display_offset_q[3:0] >= 4'b0000 );

  assign  trace_display_rddata_en =  ( reset || trace_display_rdval_dly1_q );
  always @*
    begin
      case ( trace_display_offset_q[3:0] )
        4'b0111 :  trace_display_rddata_d[63:0] =      trace_cmdi_rspo_rddata[191:128]; 
        4'b0110 :  trace_display_rddata_d[63:0] =      trace_cmdi_rspo_rddata[127:64]; 
        4'b0101 :  trace_display_rddata_d[63:0] =      trace_cmdi_rspo_rddata[63:0]; 
        4'b0100 :  trace_display_rddata_d[63:0] =  { 48'b0, trace_rspi_rddata[79:64] };
        4'b0011 :  trace_display_rddata_d[63:0] =           trace_rspi_rddata[63:0]; 
        4'b0010 :  trace_display_rddata_d[63:0] =  { 12'b0, trace_cmdo_rddata[179:128] }; 
        4'b0001 :  trace_display_rddata_d[63:0] =           trace_cmdo_rddata[127:64]; 
        4'b0000 :  trace_display_rddata_d[63:0] =           trace_cmdo_rddata[63:0];
        default :  trace_display_rddata_d[63:0] =    64'b0;
      endcase
    end  // -- always @*

  assign  trace_mmio_display_rddata_valid =  trace_display_rdval_dly2_q;
  assign  trace_mmio_display_rddata[63:0] =  trace_display_rddata_q[63:0];

  assign  trace_unused[9:8] =  trace_afu_tlx_cmd_pg_size[1:0];
  assign  trace_unused[7:3] =  trace_rspo_avail_resp_data_credit[5:1];
  assign  trace_unused[2:0] =  trace_rspo_avail_resp_credit[3:1];


  // -- ********************************************************************************************************************************
  // -- Instantiate the arrays
  // -- ********************************************************************************************************************************

  // -- cmdi_rspo trace array (400MHz)
  mcp3_ram512x064q  trace_cmdi_rspo_2
    ( .clk   ( clock_tlx ),

      .wren  ( trace_cmdi_rspo_wren ),
      .wrad  ( trace_cmdi_rspo_wraddr_q[8:0] ),
      .data  ( trace_cmdi_rspo_wrdata[191:128] ),

      .rden  ( trace_cmdi_rspo_rden ),
      .rdad  ( trace_cmdi_rspo_rdaddr[8:0] ),
      .q     ( trace_cmdi_rspo_rddata[191:128] )
    );

  mcp3_ram512x064q  trace_cmdi_rspo_1
    ( .clk   ( clock_tlx ),

      .wren  ( trace_cmdi_rspo_wren ),
      .wrad  ( trace_cmdi_rspo_wraddr_q[8:0] ),
      .data  ( trace_cmdi_rspo_wrdata[127:64] ),

      .rden  ( trace_cmdi_rspo_rden ),
      .rdad  ( trace_cmdi_rspo_rdaddr[8:0] ),
      .q     ( trace_cmdi_rspo_rddata[127:64] )
    );

  mcp3_ram512x064q  trace_cmdi_rspo_0
    ( .clk   ( clock_tlx ),

      .wren  ( trace_cmdi_rspo_wren ),
      .wrad  ( trace_cmdi_rspo_wraddr_q[8:0] ),
      .data  ( trace_cmdi_rspo_wrdata[63:0] ),

      .rden  ( trace_cmdi_rspo_rden ),
      .rdad  ( trace_cmdi_rspo_rdaddr[8:0] ),
      .q     ( trace_cmdi_rspo_rddata[63:0] )
    );

  // -- cmdo trace array  (200MHz)
  mcp3_ram512x052  trace_cmdo_2
    ( .clk   ( clock_afu ),

      .wren  ( trace_cmdo_wren ),
      .wrad  ( trace_cmdo_wraddr_q[8:0] ),
      .data  ( trace_cmdo_wrdata[179:128] ),

      .rden  ( trace_cmdo_rden ),
      .rdad  ( trace_cmdo_rdaddr[8:0] ),
      .q     ( trace_cmdo_rddata[179:128] )
    );

  mcp3_ram512x064  trace_cmdo_1
    ( .clk   ( clock_tlx ),

      .wren  ( trace_cmdo_wren ),
      .wrad  ( trace_cmdo_wraddr_q[8:0] ),
      .data  ( trace_cmdo_wrdata[127:64] ),

      .rden  ( trace_cmdo_rden ),
      .rdad  ( trace_cmdo_rdaddr[8:0] ),
      .q     ( trace_cmdo_rddata[127:64] )
    );

  mcp3_ram512x064  trace_cmdo_0
    ( .clk   ( clock_tlx ),

      .wren  ( trace_cmdo_wren ),
      .wrad  ( trace_cmdo_wraddr_q[8:0] ),
      .data  ( trace_cmdo_wrdata[63:0] ),

      .rden  ( trace_cmdo_rden ),
      .rdad  ( trace_cmdo_rdaddr[8:0] ),
      .q     ( trace_cmdo_rddata[63:0] )
    );

  // -- rspi trace array  (200MHz)
  mcp3_ram512x080  trace_rspi
    ( .clk   ( clock_afu ),

      .wren  ( trace_rspi_wren ),
      .wrad  ( trace_rspi_wraddr_q[8:0] ),
      .data  ( trace_rspi_wrdata[79:0] ),

      .rden  ( trace_rspi_rden ),
      .rdad  ( trace_rspi_rdaddr[8:0] ),
      .q     ( trace_rspi_rddata[79:0] )
    );


  assign  unexpected_xlate_or_intrpt_done_400_d =  ( unexpected_xlate_or_intrpt_done_200 && ~unexpected_xlate_or_intrpt_done_400_q );


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  // -- Latches in the AFU Clock Domain
  always @ ( posedge clock_afu )
    begin
      toggle_q                             <= toggle_d;

      trace_cmdo_wraddr_q[8:0]             <= trace_cmdo_wraddr_d[8:0];
      trace_rspi_wraddr_q[8:0]             <= trace_rspi_wraddr_d[8:0];
      trace_cmdo_wrapped_q                 <= trace_cmdo_wrapped_d;
      trace_rspi_wrapped_q                 <= trace_rspi_wrapped_d;

      trace_display_rdval_q                <= trace_display_rdval_d;
      trace_display_rdval_dly1_q           <= trace_display_rdval_dly1_d;
      trace_display_rdval_dly2_q           <= trace_display_rdval_dly2_d;
      if ( trace_display_addr_en )
        trace_display_addr_q[8:0]          <= trace_display_addr_d[8:0];
      if ( trace_display_offset_en )
        trace_display_offset_q[3:0]        <= trace_display_offset_d[3:0];
      if ( trace_display_rddata_en )
        trace_display_rddata_q[63:0]       <= trace_display_rddata_d[63:0];

    end   // -- always  @                     

  // -- Latches in the TLX Clock Domain
  always @ ( posedge clock_tlx )
    begin
      sample_q                             <= sample_d;                     
      odd_q                                <= odd_d;                        
      even_q                               <= even_d;                 

      trace_timestamp_q[35:0]              <= trace_timestamp_d[35:0];

      trace_cmdi_rspo_wraddr_q[8:0]        <= trace_cmdi_rspo_wraddr_d[8:0];
      trace_cmdi_rspo_wrapped_q            <= trace_cmdi_rspo_wrapped_d;

      unexpected_xlate_or_intrpt_done_400_q <= unexpected_xlate_or_intrpt_done_400_d;

    end   // -- always  @                     

endmodule
