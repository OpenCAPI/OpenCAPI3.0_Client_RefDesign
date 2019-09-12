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

module afp3_perfmon (

    input                 clock_afu

  , input                 reset                 //--Connect to mmio_perf_reset in afp3_afu module.

  // -- Display Read
  , input                  mmio_perf_rdval                      //--The mmio_perf_rdaddr (snapshot type) is valid. 
  , input                  mmio_perf_rdlatency                  //--Read the next entry of the latency array.
  , input            [3:0] mmio_perf_rdaddr                     //--Snapshot type.


  , output         [63:0] perf_mmio_rddata                      //--Snapshot data sent to mmio.
  , output                perf_mmio_rddata_valid                //--Snapshot data is valid.


  , input                 arb_perf_latency_update
  , input                 arb_perf_no_credits
  , input                 eng_perf_wkhstthrd_good
  , input                 trace_tlx_afu_resp_valid_with_data
  , input                 trace_tlx_afu_resp_valid_no_data
  , input          [15:0] trace_tlx_afu_resp_afutag             //--Bit 13 decides cmd0 or cmd1.        
  , input           [7:0] trace_tlx_afu_resp_opcode
  , input           [1:0] trace_tlx_afu_resp_dl


  );



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// (w/resp_valid) Resp Data Length (00=rsvd, 01=64B, 10=128B, 11=256B)

 
  localparam    [1:0] TLX_AFU_RESP_ENCODE_64B_DATA_LENGTH      = 2'b01;
  localparam    [1:0] TLX_AFU_RESP_ENCODE_128B_DATA_LENGTH     = 2'b10;
  localparam    [1:0] TLX_AFU_RESP_ENCODE_256B_DATA_LENGTH     = 2'b11;

  localparam    [7:0] TLX_AFU_RESP_ENCODE_READ_RESPONSE        = 8'b00000100;  // -- Read Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_WRITE_RESPONSE       = 8'b00001000;  // -- Write Response
  localparam    [7:0] TLX_AFU_RESP_ENCODE_READ_FAILED          = 8'b00000101;  // -- Read Failed
  localparam    [7:0] TLX_AFU_RESP_ENCODE_WRITE_FAILED         = 8'b00001001;  // -- Write Failed
  localparam    [7:0] TLX_AFU_RESP_ENCODE_INTRPT_RESP          = 8'b00001100;  // -- Interrupt Response

  localparam    [3:0] AFU_CYCLE_COUNT_SNAPSHOT                 = 4'b0000;
  localparam    [3:0] ANY_RESP_COUNT_SNAPSHOT                  = 4'b0001;       //-- These resp/retry counts are in terms of 64B data lengths.
  localparam    [3:0] CMD0_RESP_COUNT_SNAPSHOT                 = 4'b0010;
  localparam    [3:0] CMD1_RESP_COUNT_SNAPSHOT                 = 4'b0011;
  localparam    [3:0] ANY_RETRY_COUNT_SNAPSHOT                 = 4'b0100;
  localparam    [3:0] CMD0_RETRY_COUNT_SNAPSHOT                = 4'b0101;
  localparam    [3:0] CMD1_RETRY_COUNT_SNAPSHOT                = 4'b0110;
  localparam    [3:0] NO_CREDITS_COUNT_SNAPSHOT                = 4'b0111;
  localparam    [3:0] INTERRUPT_COUNT_SNAPSHOT                 = 4'b1000;
  localparam    [3:0] WKHSTTHRD_COUNT_SNAPSHOT                 = 4'b1001;

  wire      valid_snapshot;
  wire      [3:0] snapshot_type;
  wire      any_resp;
  wire      cmd0_resp;
  wire      cmd1_resp;
  wire      any_retry;
  wire      cmd0_retry;
  wire      cmd1_retry;
  wire      cmd;
  wire      no_credits;
  wire      intrpt_resp;
  wire      wkhstthrd_good;
  wire      [63:0] count_incr;
  wire      [63:0] any_resp_count_d;
  reg       [63:0] any_resp_count_q;
  wire      [63:0] cmd0_resp_count_d;
  reg       [63:0] cmd0_resp_count_q;
  wire      [63:0] cmd1_resp_count_d;
  reg       [63:0] cmd1_resp_count_q;
  wire      [63:0] any_retry_count_d;
  reg       [63:0] any_retry_count_q;
  wire      [63:0] cmd0_retry_count_d;
  reg       [63:0] cmd0_retry_count_q;
  wire      [63:0] cmd1_retry_count_d;
  reg       [63:0] cmd1_retry_count_q;
  wire      [63:0] afu_cycle_count_d;
  reg       [63:0] afu_cycle_count_q;
  wire      [63:0] no_credits_count_d;
  reg       [63:0] no_credits_count_q;
  wire      [63:0] interrupt_count_d;
  reg       [63:0] interrupt_count_q;
  wire      [63:0] wkhstthrd_count_d;
  reg       [63:0] wkhstthrd_count_q;
  wire      perf_mmio_rddata_valid_d;
  reg       perf_mmio_rddata_valid_q;
  wire      [63:0] perf_mmio_rddata_d;
  reg       [63:0] perf_mmio_rddata_q;

  wire      lat_array_wren;
  wire      lat_array_rden;
  wire      lat_array_addr_en;
  wire      [10:0] lat_array_addr_d;
  reg       [10:0] lat_array_addr_q;
  wire      [31:0] lat_array_wrdata;
  wire      [31:0] lat_array_rddata;
  wire      lat_array_rden_dly1_d;
  reg       lat_array_rden_dly1_q;
  wire      lat_array_rden_dly2_d;
  reg       lat_array_rden_dly2_q;
  wire      [31:0] lat_array_rddata_d;
  reg       [31:0] lat_array_rddata_q;


 assign  valid_snapshot =         mmio_perf_rdval;

 assign  cmd =                    trace_tlx_afu_resp_afutag[13];
 assign  any_resp =               ((trace_tlx_afu_resp_valid_no_data || trace_tlx_afu_resp_valid_with_data) && (( trace_tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_READ_RESPONSE[7:0] ) || ( trace_tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_WRITE_RESPONSE[7:0])));
 assign  cmd0_resp =              ( any_resp && ~cmd );
 assign  cmd1_resp =              ( any_resp &&  cmd );
 assign  any_retry =              ((trace_tlx_afu_resp_valid_no_data || trace_tlx_afu_resp_valid_with_data) && (( trace_tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_READ_FAILED[7:0] ) || ( trace_tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_WRITE_FAILED[7:0])));
 assign  cmd0_retry =             ( any_retry && ~cmd );
 assign  cmd1_retry =             ( any_retry &&  cmd );
 assign  no_credits =             ( arb_perf_no_credits );
 assign  intrpt_resp =            ( (trace_tlx_afu_resp_valid_no_data || trace_tlx_afu_resp_valid_with_data) && ( trace_tlx_afu_resp_opcode[7:0] ==  TLX_AFU_RESP_ENCODE_INTRPT_RESP[7:0] ) );
 assign  wkhstthrd_good =         ( eng_perf_wkhstthrd_good );
 assign  count_incr[63:0] =       trace_tlx_afu_resp_dl[1:0] == TLX_AFU_RESP_ENCODE_64B_DATA_LENGTH[1:0] ? 64'b1: trace_tlx_afu_resp_dl[1:0] == TLX_AFU_RESP_ENCODE_128B_DATA_LENGTH[1:0] ? 64'b10 : 64'b100;

 assign  snapshot_type[3:0] =     mmio_perf_rdaddr[3:0];

 assign    afu_cycle_count_d[63:0] =  afu_cycle_count_q[63:0]  + 64'b1;
 assign    any_resp_count_d[63:0]  =  any_resp   ? any_resp_count_q[63:0]   + count_incr[63:0] : any_resp_count_q[63:0];
 assign    cmd0_resp_count_d[63:0] =  cmd0_resp  ? cmd0_resp_count_q[63:0]  + count_incr[63:0] : cmd0_resp_count_q[63:0];                                    
 assign    cmd1_resp_count_d[63:0] =  cmd1_resp  ? cmd1_resp_count_q[63:0]  + count_incr[63:0] : cmd1_resp_count_q[63:0];                                    
 assign    any_retry_count_d[63:0]  = any_retry  ? any_retry_count_q[63:0]  + count_incr[63:0] : any_retry_count_q[63:0];                                     
 assign    cmd0_retry_count_d[63:0] = cmd0_retry ? cmd0_retry_count_q[63:0] + count_incr[63:0] : cmd0_retry_count_q[63:0];                                
 assign    cmd1_retry_count_d[63:0] = cmd1_retry ? cmd1_retry_count_q[63:0] + count_incr[63:0] : cmd1_retry_count_q[63:0];                                     
 assign    no_credits_count_d[63:0] = no_credits ? no_credits_count_q[63:0] + 64'b1 : no_credits_count_q[63:0];                                     
 assign    interrupt_count_d[63:0]  = intrpt_resp ? interrupt_count_q[63:0] + 64'b1 : interrupt_count_q[63:0];                                     
 assign    wkhstthrd_count_d[63:0]  = wkhstthrd_good ? wkhstthrd_count_q[63:0] + 64'b1 : wkhstthrd_count_q[63:0];                                     
 assign    perf_mmio_rddata_valid_d = (valid_snapshot & ~mmio_perf_rdlatency) | lat_array_rden_dly2_q;
 assign    perf_mmio_rddata_d[63:0] = (lat_array_rden_dly2_q)  ?                                   { 32'b0, lat_array_rddata_q[31:0] }  :
                                      (valid_snapshot && (snapshot_type[3:0] == AFU_CYCLE_COUNT_SNAPSHOT )) ? afu_cycle_count_q[63:0]   :
                                      (valid_snapshot && (snapshot_type[3:0] == ANY_RESP_COUNT_SNAPSHOT  )) ? any_resp_count_q[63:0]    :
                                      (valid_snapshot && (snapshot_type[3:0] == CMD0_RESP_COUNT_SNAPSHOT )) ? cmd0_resp_count_q[63:0]   :
                                      (valid_snapshot && (snapshot_type[3:0] == CMD1_RESP_COUNT_SNAPSHOT )) ? cmd1_resp_count_q[63:0]   :
                                      (valid_snapshot && (snapshot_type[3:0] == ANY_RETRY_COUNT_SNAPSHOT )) ? any_retry_count_q[63:0]   :
                                      (valid_snapshot && (snapshot_type[3:0] == CMD0_RETRY_COUNT_SNAPSHOT)) ? cmd0_retry_count_q[63:0]  :
                                      (valid_snapshot && (snapshot_type[3:0] == CMD1_RETRY_COUNT_SNAPSHOT)) ? cmd1_retry_count_q[63:0]  :
                                      (valid_snapshot && (snapshot_type[3:0] == NO_CREDITS_COUNT_SNAPSHOT)) ? no_credits_count_q[63:0]  :
                                      (valid_snapshot && (snapshot_type[3:0] == INTERRUPT_COUNT_SNAPSHOT))  ? interrupt_count_q[63:0]  :
                                      (valid_snapshot && (snapshot_type[3:0] == WKHSTTHRD_COUNT_SNAPSHOT))  ? wkhstthrd_count_q[63:0]  :
                                      64'b0;

  // -- ********************************************************************************************************************************
  // -- Latency Array
  // --   Stores time count when command is sent
  // --   Write when command sent, read by MMIO interface
  // --   Note: Latency measurements are intended for only 1 command at a time (1 tag)
  // -- ********************************************************************************************************************************
  assign lat_array_wren  =  arb_perf_latency_update;
  assign lat_array_rden  =  mmio_perf_rdlatency;

  // Use same address for reading and writing.  Reads will start at address after the last write, i.e., the oldest data
  assign lat_array_addr_en  = lat_array_wren | lat_array_rden ;
  assign lat_array_addr_d[10:0] = lat_array_addr_en  ?  lat_array_addr_q[10:0] + 11'b1  :  lat_array_addr_q;

  assign lat_array_wrdata[31:0] = afu_cycle_count_q[31:0];

  afp3_ram2048x032  latency_array
    ( .clk   ( clock_afu ),

      .wren  ( lat_array_wren ),
      .wrad  ( lat_array_addr_q[10:0] ),
      .data  ( lat_array_wrdata[31:0] ),

      .rden  ( lat_array_rden ),
      .rdad  ( lat_array_addr_q[10:0] ),
      .q     ( lat_array_rddata[31:0] )
    );

  assign lat_array_rden_dly1_d = lat_array_rden;
  assign lat_array_rden_dly2_d = lat_array_rden_dly1_q;
  assign lat_array_rddata_d[31:0] = lat_array_rddata;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  always @ ( posedge clock_afu )
    begin
     if (reset)
      begin 
       afu_cycle_count_q[63:0]    <=  64'b0;
       any_resp_count_q[63:0]     <=  64'b0;
       cmd0_resp_count_q[63:0]    <=  64'b0;
       cmd1_resp_count_q[63:0]    <=  64'b0;
       any_retry_count_q[63:0]    <=  64'b0;
       cmd0_retry_count_q[63:0]   <=  64'b0;
       cmd1_retry_count_q[63:0]   <=  64'b0;
       no_credits_count_q[63:0]   <=  64'b0;
       interrupt_count_q[63:0]    <=  64'b0;
       wkhstthrd_count_q[63:0]    <=  64'b0;
       perf_mmio_rddata_q[63:0]   <=  64'b0;
       perf_mmio_rddata_valid_q   <=  1'b0;
       lat_array_addr_q[10:0]     <=  11'b0;
       lat_array_rden_dly1_q      <=  1'b0;
       lat_array_rden_dly2_q      <=  1'b0;
       lat_array_rddata_q[31:0]   <=  32'b0;
      end 
     else
      begin 
       afu_cycle_count_q[63:0]    <=  afu_cycle_count_d[63:0];
       any_resp_count_q[63:0]     <=  any_resp_count_d[63:0];
       cmd0_resp_count_q[63:0]    <=  cmd0_resp_count_d[63:0];
       cmd1_resp_count_q[63:0]    <=  cmd1_resp_count_d[63:0];
       any_retry_count_q[63:0]    <=  any_retry_count_d[63:0];
       cmd0_retry_count_q[63:0]   <=  cmd0_retry_count_d[63:0];
       cmd1_retry_count_q[63:0]   <=  cmd1_retry_count_d[63:0];
       no_credits_count_q[63:0]   <=  no_credits_count_d[63:0];
       interrupt_count_q[63:0]    <=  interrupt_count_d[63:0];
       wkhstthrd_count_q[63:0]    <=  wkhstthrd_count_d[63:0];
       perf_mmio_rddata_q[63:0]   <=  perf_mmio_rddata_d[63:0];
       perf_mmio_rddata_valid_q   <=  perf_mmio_rddata_valid_d;
       lat_array_addr_q[10:0]     <=  lat_array_addr_d[10:0];
       lat_array_rden_dly1_q      <=  lat_array_rden_dly1_d;
       lat_array_rden_dly2_q      <=  lat_array_rden_dly2_d;
       lat_array_rddata_q[31:0]   <=  lat_array_rddata_d[31:0];
      end 
    end

 assign    perf_mmio_rddata[63:0] =  perf_mmio_rddata_q[63:0];
 assign    perf_mmio_rddata_valid =  perf_mmio_rddata_valid_q;

endmodule
