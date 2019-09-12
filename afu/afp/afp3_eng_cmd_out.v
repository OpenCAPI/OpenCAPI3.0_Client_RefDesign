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

module afp3_eng_cmd_out
  (
  // -- Clocks and Reset
    input                 clock                                           
  , input                 reset

  // -- Register settings
  , input                 mmio_eng_extra_write_mode
  , input                 mmio_eng_mmio_lat_mode
  , input                 mmio_eng_mmio_lat_mode_sz_512_st
  , input                 mmio_eng_mmio_lat_use_reg_data
  , input                 mmio_eng_mmio_lat_extra_read

  , input        [1023:0] mmio_eng_mmio_lat_data0
  , input        [1023:0] mmio_eng_mmio_lat_data1
  , input        [1023:0] mmio_eng_mmio_lat_data2
  , input        [1023:0] mmio_eng_mmio_lat_data3

  // -- Inbound Arbitration Requests from each sequencer
  , input                 actag_req
  //, input                 we_ld_req
  //, input                 we_rtry_ld_req
  , input                 xtouch_req
  , input                 xtouch_rtry_req
  //, input                 cpy_ld_req
  //, input                 cpy_rtry_ld_req
  //, input                 cpy_st_req
  , input                 cpy_rtry_st_req
  , input                 wkhstthrd_req
  , input                 wkhstthrd_rtry_req
  //, input                 incr_ld_req
  //, input                 incr_st_req
  //, input                 incr_rtry_ld_req
  //, input                 incr_rtry_st_req
  , input                 atomic_req
  , input                 atomic_req_w_data
  , input                 atomic_rtry_req
  , input                 atomic_rtry_req_w_data
  , input                 intrpt_req
  , input                 intrpt_req_w_data
  , input                 intrpt_rtry_req
  , input                 intrpt_rtry_req_w_data
  //, input                 we_st_req
  //, input                 we_rtry_st_req
  , input                 eng_display_req

  // -- Inbound Command Buses from each sequencer
  , input                 actag_valid
  , input           [7:0] actag_opcode
  , input          [11:0] actag_actag
  , input           [3:0] actag_stream_id
  , input          [67:0] actag_ea_or_obj
  , input          [15:0] actag_afutag
  , input           [1:0] actag_dl
  , input           [2:0] actag_pl
  , input                 actag_os
  , input          [63:0] actag_be
  , input           [3:0] actag_flag
  , input                 actag_endian
  , input          [15:0] actag_bdf
  //, input          [19:0] actag_pasid
  , input           [5:0] actag_pg_size

  , input                 we_ld_valid
  , input           [7:0] we_ld_opcode
  , input          [11:0] we_ld_actag
  , input           [3:0] we_ld_stream_id
  , input          [67:0] we_ld_ea_or_obj
  , input          [15:0] we_ld_afutag
  , input           [1:0] we_ld_dl
  , input           [2:0] we_ld_pl
  , input                 we_ld_os
  , input          [63:0] we_ld_be
  , input           [3:0] we_ld_flag
  , input                 we_ld_endian
  , input          [15:0] we_ld_bdf
  //, input          [19:0] we_ld_pasid
  , input           [5:0] we_ld_pg_size

  , input                 xtouch_valid
  , input           [7:0] xtouch_opcode
  , input          [11:0] xtouch_actag
  , input           [3:0] xtouch_stream_id
  , input          [67:0] xtouch_ea_or_obj
  , input          [15:0] xtouch_afutag
  , input           [1:0] xtouch_dl
  , input           [2:0] xtouch_pl
  , input                 xtouch_os
  , input          [63:0] xtouch_be
  , input           [3:0] xtouch_flag
  , input                 xtouch_endian
  , input          [15:0] xtouch_bdf
  //, input          [19:0] xtouch_pasid
  , input           [5:0] xtouch_pg_size

  , input                 cpy_ld_valid
  , input           [7:0] cpy_ld_opcode
  , input          [11:0] cpy_ld_actag
  , input           [3:0] cpy_ld_stream_id
  , input          [67:0] cpy_ld_ea_or_obj
  , input          [15:0] cpy_ld_afutag
  , input           [1:0] cpy_ld_dl
  , input           [2:0] cpy_ld_pl
  , input                 cpy_ld_os
  , input          [63:0] cpy_ld_be
  , input           [3:0] cpy_ld_flag
  , input                 cpy_ld_endian
  , input          [15:0] cpy_ld_bdf
  //, input          [19:0] cpy_ld_pasid
  , input           [5:0] cpy_ld_pg_size

  , input                 cpy_st_valid
  , input           [7:0] cpy_st_opcode
  , input          [11:0] cpy_st_actag
  , input           [3:0] cpy_st_stream_id
  , input          [67:0] cpy_st_ea_or_obj
  , input          [15:0] cpy_st_afutag
  , input           [1:0] cpy_st_dl
  , input           [2:0] cpy_st_pl
  , input                 cpy_st_os
  , input          [63:0] cpy_st_be
  , input           [3:0] cpy_st_flag
  , input                 cpy_st_endian
  , input          [15:0] cpy_st_bdf
  //, input          [19:0] cpy_st_pasid
  , input           [5:0] cpy_st_pg_size

  , input                 wkhstthrd_valid
  , input           [7:0] wkhstthrd_opcode
  , input          [11:0] wkhstthrd_actag
  , input           [3:0] wkhstthrd_stream_id
  , input          [67:0] wkhstthrd_ea_or_obj
  , input          [15:0] wkhstthrd_afutag
  , input           [1:0] wkhstthrd_dl
  , input           [2:0] wkhstthrd_pl
  , input                 wkhstthrd_os
  , input          [63:0] wkhstthrd_be
  , input           [3:0] wkhstthrd_flag
  , input                 wkhstthrd_endian
  , input          [15:0] wkhstthrd_bdf
  //, input          [19:0] wkhstthrd_pasid
  , input           [5:0] wkhstthrd_pg_size

  , input                 incr_ld_valid
  , input           [7:0] incr_ld_opcode
  , input          [11:0] incr_ld_actag
  , input           [3:0] incr_ld_stream_id
  , input          [67:0] incr_ld_ea_or_obj
  , input          [15:0] incr_ld_afutag
  , input           [1:0] incr_ld_dl
  , input           [2:0] incr_ld_pl
  , input                 incr_ld_os
  , input          [63:0] incr_ld_be
  , input           [3:0] incr_ld_flag
  , input                 incr_ld_endian
  , input          [15:0] incr_ld_bdf
  //, input          [19:0] incr_ld_pasid
  , input           [5:0] incr_ld_pg_size

  , input                 incr_st_valid
  , input           [7:0] incr_st_opcode
  , input          [11:0] incr_st_actag
  , input           [3:0] incr_st_stream_id
  , input          [67:0] incr_st_ea_or_obj
  , input          [15:0] incr_st_afutag
  , input           [1:0] incr_st_dl
  , input           [2:0] incr_st_pl
  , input                 incr_st_os
  , input          [63:0] incr_st_be
  , input           [3:0] incr_st_flag
  , input                 incr_st_endian
  , input          [15:0] incr_st_bdf
  //, input          [19:0] incr_st_pasid
  , input           [5:0] incr_st_pg_size

  , input                 atomic_valid
  , input           [7:0] atomic_opcode
  , input          [11:0] atomic_actag
  , input           [3:0] atomic_stream_id
  , input          [67:0] atomic_ea_or_obj
  , input          [15:0] atomic_afutag
  , input           [1:0] atomic_dl
  , input           [2:0] atomic_pl
  , input                 atomic_os
  , input          [63:0] atomic_be
  , input           [3:0] atomic_flag
  , input                 atomic_endian
  , input          [15:0] atomic_bdf
  //, input          [19:0] atomic_pasid
  , input           [5:0] atomic_pg_size

  , input                 intrpt_valid
  , input           [7:0] intrpt_opcode
  , input          [11:0] intrpt_actag
  , input           [3:0] intrpt_stream_id
  , input          [67:0] intrpt_ea_or_obj
  , input          [15:0] intrpt_afutag
  , input           [1:0] intrpt_dl
  , input           [2:0] intrpt_pl
  , input                 intrpt_os
  , input          [63:0] intrpt_be
  , input           [3:0] intrpt_flag
  , input                 intrpt_endian
  , input          [15:0] intrpt_bdf
  //, input          [19:0] intrpt_pasid
  , input           [5:0] intrpt_pg_size

  , input                 we_st_valid
  , input           [7:0] we_st_opcode
  , input          [11:0] we_st_actag
  , input           [3:0] we_st_stream_id
  , input          [67:0] we_st_ea_or_obj
  , input          [15:0] we_st_afutag
  , input           [1:0] we_st_dl
  , input           [2:0] we_st_pl
  , input                 we_st_os
  , input          [63:0] we_st_be
  , input           [3:0] we_st_flag
  , input                 we_st_endian
  , input          [15:0] we_st_bdf
  //, input          [19:0] we_st_pasid
  , input           [5:0] we_st_pg_size

  , input           [9:0] cmd_pasid_q

  // -- Inbound Data Buses from each sequencer
  //, input        [1023:0] cpy_st_data
  , input         [511:0] incr_st_data
  , input         [511:0] atomic_data
  , input         [511:0] intrpt_data
  , input         [511:0] we_st_data
  , input          [63:0] eng_display_data

  , input                 atomic_data_valid
  , input                 intrpt_data_valid

  // -- Arbitration Requests to ARB (combine input arb requests and sent out to arb)
  //, output                eng_arb_ld_req
  //, output                eng_arb_st_req
  , output                eng_arb_misc_req
  , output                eng_arb_misc_needs_extra_write
  //, output                eng_arb_rtry_ld_req
  //, output                eng_arb_rtry_st_req
  , output                eng_arb_rtry_misc_req

  //, input            [1:0] cpy_st_size_encoded_d
  , input            [1:0] rtry_queue_dl_q
  , input                  cpy_st_size_256_q
  , input                  cpy_rtry_st_size_256_q
  //, input           [1:0] eng_display_ary_select_q

  //, output                eng_arb_st_256
  //, output                eng_arb_st_128
  , output                eng_arb_rtry_st_256
  , output                eng_arb_rtry_st_128
  , output                eng_arb_misc_w_data
  , output                eng_arb_rtry_misc_w_data

  // -- Arbitration Grants from ARB
  , input                 arb_eng_ld_gnt
  , input                 arb_eng_st_gnt
  , input                 arb_eng_misc_gnt
  , input                 arb_eng_rtry_ld_gnt                                                                  
  , input                 arb_eng_rtry_st_gnt                                                                  
  , input                 arb_eng_rtry_misc_gnt

  // -- Command Output signals
  , output                eng_cmdo_valid
  , output          [7:0] eng_cmdo_opcode
  , output         [11:0] eng_cmdo_actag
  , output          [3:0] eng_cmdo_stream_id
  , output         [67:0] eng_cmdo_ea_or_obj
  , output         [15:0] eng_cmdo_afutag
  , output          [1:0] eng_cmdo_dl
  , output          [2:0] eng_cmdo_pl
  , output                eng_cmdo_os
  , output         [63:0] eng_cmdo_be
  , output          [3:0] eng_cmdo_flag
  , output                eng_cmdo_endian
  , output         [15:0] eng_cmdo_bdf
  , output         [19:0] eng_cmdo_pasid
  , output          [5:0] eng_cmdo_pg_size

  // -- Data Output signals
  , output                eng_cmdo_st_valid
  , output       [1023:0] eng_cmdo_st_data

  // -- Send to resp_decode for checking for valid afutag
  , output                cmdo_valid 
  , output         [15:0] cmdo_afutag

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- cpy_st_data
  wire   [1023:0] counter_data;
  wire            mmio_lat_data_next_en;
  wire      [1:0] rtry_mmio_lat_data_sel;
  wire   [1023:0] mmio_lat_reg_data;
  wire   [1023:0] cpy_st_data_raw;
  wire   [1023:0] cpy_st_data;

  // -- cmdo_ld
  wire            cmdo_ld_valid;
  reg       [7:0] cmdo_ld_opcode;
  reg      [11:0] cmdo_ld_actag;
  reg       [3:0] cmdo_ld_stream_id;
  reg      [67:0] cmdo_ld_ea_or_obj;
  reg      [15:0] cmdo_ld_afutag;
  reg       [1:0] cmdo_ld_dl;
  reg       [2:0] cmdo_ld_pl;
  reg             cmdo_ld_os;
  reg      [63:0] cmdo_ld_be;
  reg       [3:0] cmdo_ld_flag;
  reg             cmdo_ld_endian;
  reg      [15:0] cmdo_ld_bdf;
  //reg      [19:0] cmdo_ld_pasid;
  reg       [5:0] cmdo_ld_pg_size;

  // -- cmdo_st
  wire            cmdo_st_valid;
  reg       [7:0] cmdo_st_opcode;
  reg      [11:0] cmdo_st_actag;
  reg       [3:0] cmdo_st_stream_id;
  reg      [67:0] cmdo_st_ea_or_obj;
  reg      [15:0] cmdo_st_afutag;
  reg       [1:0] cmdo_st_dl;
  reg       [2:0] cmdo_st_pl;
  reg             cmdo_st_os;
  reg      [63:0] cmdo_st_be;
  reg       [3:0] cmdo_st_flag;
  reg             cmdo_st_endian;
  reg      [15:0] cmdo_st_bdf;
  //reg      [19:0] cmdo_st_pasid;
  reg       [5:0] cmdo_st_pg_size;

  // -- cmdo_misc
  wire            cmdo_misc_valid;
  reg       [7:0] cmdo_misc_opcode;
  reg      [11:0] cmdo_misc_actag;
  reg       [3:0] cmdo_misc_stream_id;
  reg      [67:0] cmdo_misc_ea_or_obj;
  reg      [15:0] cmdo_misc_afutag;
  reg       [1:0] cmdo_misc_dl;
  reg       [2:0] cmdo_misc_pl;
  reg             cmdo_misc_os;
  reg      [63:0] cmdo_misc_be;
  reg       [3:0] cmdo_misc_flag;
  reg             cmdo_misc_endian;
  reg      [15:0] cmdo_misc_bdf;
  //reg      [19:0] cmdo_misc_pasid;
  reg       [5:0] cmdo_misc_pg_size;


  // -- ********************************************************************************************************************************
  // -- Latch Signal declarations (including latch enable signals)
  // -- ********************************************************************************************************************************

  // -- cpy_st_data
  wire     [63:0] time_counter_d;
 `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
  reg      [63:0] time_counter_q;
  wire            cpy_st_size_256_dly_d;
  reg             cpy_st_size_256_dly_q;
  wire            cpy_st_gnt_dly_d;
  reg             cpy_st_gnt_dly_q;
  wire            rtry_st_gnt_dly_d;
  reg             rtry_st_gnt_dly_q;

  //wire            mmio_eng_extra_write_mode_d;
  reg             mmio_eng_extra_write_mode_q;

  // -- for MMIO ping-pong latency mode
  wire            mmio_eng_mmio_lat_mode_sz_512_st_d;
  reg             mmio_eng_mmio_lat_mode_sz_512_st_q;
  wire            mmio_lat_use_reg_data_d;
  reg             mmio_lat_use_reg_data_q;
  wire      [1:0] mmio_lat_data_next_d;
  reg       [1:0] mmio_lat_data_next_q;
  wire      [1:0] mmio_lat_data_sel_d;
  reg       [1:0] mmio_lat_data_sel_q;

  // -- eng_cmdo outbound interface latches
  wire            cmdo_valid_d;
  reg             cmdo_valid_q;
  wire      [7:0] cmdo_opcode_d;
  reg       [7:0] cmdo_opcode_q;
  wire     [11:0] cmdo_actag_d;
  reg      [11:0] cmdo_actag_q;
  wire      [3:0] cmdo_stream_id_d;
  reg       [3:0] cmdo_stream_id_q;
  wire     [67:0] cmdo_ea_or_obj_d;
  reg      [67:0] cmdo_ea_or_obj_q;
  wire     [15:0] cmdo_afutag_d;
  reg      [15:0] cmdo_afutag_q;
  wire      [1:0] cmdo_dl_d;
  reg       [1:0] cmdo_dl_q;
  wire      [2:0] cmdo_pl_d;
  reg       [2:0] cmdo_pl_q;
  wire            cmdo_os_d;
  reg             cmdo_os_q;
  wire     [63:0] cmdo_be_d;
  reg      [63:0] cmdo_be_q;
  wire      [3:0] cmdo_flag_d;
  reg       [3:0] cmdo_flag_q;
  wire            cmdo_endian_d;
  reg             cmdo_endian_q;
  wire     [15:0] cmdo_bdf_d;
  reg      [15:0] cmdo_bdf_q;
  wire     [19:0] cmdo_pasid_d;
  reg      [19:0] cmdo_pasid_q;
  wire      [5:0] cmdo_pg_size_d;
  reg       [5:0] cmdo_pg_size_q;
  wire            cmdo_st_valid_d;
  reg             cmdo_st_valid_q;


  // -- ********************************************************************************************************************************
  // -- Output Interface to arb 
  // -- ********************************************************************************************************************************

  // -- Drive Requests interface raw (unlatched) - multiple engines may drive requests, only a single engine may drive cmd when granted to do so
//  assign  eng_arb_ld_req           =  ( we_ld_req       || cpy_ld_req || incr_ld_req );
//  assign  eng_arb_st_req           =  ( we_st_req       || cpy_st_req || incr_st_req );
  assign  eng_arb_misc_req         =  ( actag_req       || intrpt_req ||  xtouch_req || wkhstthrd_req || atomic_req || eng_display_req ); // -- If adding terms, update eng_display_req_blocker term
  assign  eng_arb_misc_needs_extra_write  =  ( intrpt_req || wkhstthrd_req ) && mmio_eng_extra_write_mode_q;

//  assign  eng_arb_rtry_ld_req      =  ( we_rtry_ld_req  || cpy_rtry_ld_req || incr_rtry_ld_req );
//  assign  eng_arb_rtry_st_req      =  ( we_rtry_st_req  || cpy_rtry_st_req || incr_rtry_st_req );
  assign  eng_arb_rtry_misc_req    =  ( intrpt_rtry_req || xtouch_rtry_req || wkhstthrd_rtry_req || atomic_rtry_req );

  // -- Arbiters need to know how many beats of data to determine if enough data credits
//  assign  eng_arb_st_256           =  ( cpy_st_req && ( cpy_st_size_encoded_d[1:0] == 2'b11 ));  // -- Attempt to improve single engine performance (size_encoded_d was dl)
//  assign  eng_arb_st_128           =  ( cpy_st_req && ( cpy_st_size_encoded_d[1:0] == 2'b10 ));  // --   (See corresponding change to cpy_st_req)

  assign  eng_arb_rtry_st_256      =  ( cpy_rtry_st_req && ( rtry_queue_dl_q[1:0] == 2'b11 ));   // -- Attempt to improve single engine performance (size_encoded_d was dl)
  assign  eng_arb_rtry_st_128      =  ( cpy_rtry_st_req && ( rtry_queue_dl_q[1:0] == 2'b10 ));   // --   (See corresponding change to cpy_rtry_st_req)

  // -- Arbiters need to know if cmd is to be sent with or without data to determine if need to check for a data credit
  assign  eng_arb_misc_w_data      =  ( intrpt_req_w_data      || atomic_req_w_data );
  assign  eng_arb_rtry_misc_w_data =  ( intrpt_rtry_req_w_data || atomic_rtry_req_w_data || eng_display_req );


  // -- ********************************************************************************************************************************
  // -- Time counter, for calculating latency
  // -- ********************************************************************************************************************************
  assign  time_counter_d[63:0]   =  reset ?  64'b0  :  (time_counter_q + 64'b1);

  assign  cpy_st_size_256_dly_d  =  ((  arb_eng_st_gnt      &&      cpy_st_size_256_q ) ||
                                     (  arb_eng_rtry_st_gnt && cpy_rtry_st_size_256_q ));
                                     // (  arb_eng_misc_gnt    &&   eng_display_size[8] ));  //     Removed: always 64B

  // Gate cpy_st_data with delayed grant
  assign  cpy_st_gnt_dly_d       =  ~reset &&
                                    (( ( arb_eng_st_gnt ) ||
				      ( cpy_st_gnt_dly_q && cpy_st_size_256_dly_q ) ||  // -- cpy_st_size_256B covers both normal and retry
				      ( arb_eng_rtry_st_gnt ) ));
				   //   ( arb_eng_misc_gnt && ( eng_display_ary_select_q[1:0] == 2'b00 )) );  //-- Removed 11/02/17.  I think I was trying to mimic the display scenario from MCP, but the arrays don't exist anymore, and this ends up putting data on actag command

  assign  rtry_st_gnt_dly_d      =    ~reset &&
                                      (  arb_eng_rtry_st_gnt ||
				       ( rtry_st_gnt_dly_q && cpy_st_size_256_dly_q ));


  //assign  cpy_st_data[1023:577]  =  447'b0;
  //assign  cpy_st_data[576]       =  rtry_st_gnt_dly_q;
  //assign  cpy_st_data[575:512]   =  cpy_st_gnt_dly_q ?  time_counter_q[63:0]  :  64'b0;

  //assign  cpy_st_data[511:65]    =  447'b0;
  //assign  cpy_st_data[64]        =  rtry_st_gnt_dly_q;
  //assign  cpy_st_data[63:0]      =  cpy_st_gnt_dly_q ?  time_counter_q[63:0]  :  64'b0;

  // Store data:  every 64B will contain the time_count, and whether or not this is a retry
  assign  counter_data[1023:512]   =  {447'b0, rtry_st_gnt_dly_q, time_counter_q[63:0]};
  assign  counter_data[ 511:0  ]   =  {447'b0, rtry_st_gnt_dly_q, time_counter_q[63:0]};

  // -- ********************************************************************************************************************************
  // -- Mux data for MMIO ping-pong latency mode
  // -- ********************************************************************************************************************************
  assign  mmio_eng_mmio_lat_mode_sz_512_st_d  = mmio_eng_mmio_lat_mode_sz_512_st;
  assign  mmio_lat_use_reg_data_d          = (~reset) & mmio_eng_mmio_lat_mode &
                                             (mmio_eng_mmio_lat_use_reg_data | mmio_eng_mmio_lat_extra_read);  // Use register data for extra read mode or when use_reg_data is set

  // Keep track of which data we need to send next when using register data
  assign  mmio_lat_data_next_en = //(reset |
                                   (cpy_st_gnt_dly_q & ~rtry_st_gnt_dly_q & mmio_lat_use_reg_data_q) |
                                   (mmio_lat_data_next_q[0] == 1'b1);  // Need to toggle after 2nd half of 256B store data

  // Wraps back to 00 at different points, depending on the data size
  assign  mmio_lat_data_next_d[1:0]  = reset  ?  2'b00 :
                      ~mmio_lat_data_next_en  ? mmio_lat_data_next_q[1:0] :  // added this because otherwise mmio_lat_data_sel_d is wrong
             (mmio_lat_data_next_q == 2'b10)  ?  2'b11 :
    (mmio_lat_data_next_q == 2'b01) &&  mmio_eng_mmio_lat_mode_sz_512_st_q  ?  2'b10 :
    (mmio_lat_data_next_q == 2'b00) && (mmio_eng_mmio_lat_mode_sz_512_st_q || cpy_st_size_256_q)  ?  2'b01 :
                                                 2'b00;

  // Data select for retries.  This signal is 1 cycle before data selected.
  assign  rtry_mmio_lat_data_sel[1:0]  =
    (rtry_st_gnt_dly_q && cpy_st_size_256_dly_q)  ? { mmio_lat_data_sel_q[1] , 1'b1 } :  // 2nd half of 256B retry
                                                    cpy_st_ea_or_obj[8:7];               // 128B retry or 1st half of 256B retry

  assign  mmio_lat_data_sel_d[1:0]  =  rtry_st_gnt_dly_d  ?  rtry_mmio_lat_data_sel[1:0]  :
						             mmio_lat_data_next_d[1:0];

  // Select which mmio latency data to use when using register data
  assign  mmio_lat_reg_data[1023:0]  =  (mmio_lat_data_sel_q == 2'b00)  ?  mmio_eng_mmio_lat_data0[1023:0]  :
                                        (mmio_lat_data_sel_q == 2'b01)  ?  mmio_eng_mmio_lat_data1[1023:0]  :
                                        (mmio_lat_data_sel_q == 2'b10)  ?  mmio_eng_mmio_lat_data2[1023:0]  :
                                                                           mmio_eng_mmio_lat_data3[1023:0] ;   //(mmio_lat_data_sel_q == 2'b11)

  // Select between register data and counter
  assign  cpy_st_data_raw[1023:0]  =  mmio_lat_use_reg_data_q  ?  mmio_lat_reg_data[1023:0] :
                                                                  counter_data[1023:0];

  assign  cpy_st_data[1023:0]  =  cpy_st_gnt_dly_q ?  cpy_st_data_raw[1023:0]  : 1024'b0;  // Zero out when not using

  // -- ********************************************************************************************************************************
  // -- Output Interface to cmdo 
  // -- ********************************************************************************************************************************

  // -- Group commands into 5 types:  Loads(we_ld & cpy_ld), Stores(we_st & cpy_st), Misc(actag & intrpt),
  // --   Retry Loads(we_rtry_ld & cpy_rtry_ld) and Retry Stores(we_rtry_st, cpy_rtry_st)
  // -- Gate with unlatched corresponding grant pulse from pcmd to form single cycle command
  // -- Assume that only 1 of the 5 grants from arb will be active
  // -- Combine the 3 types into a single command, latch, and drive latched cmd to pcmd module one cycle after grant
                                                                        
  // -- Form cmdo_ld command (OR together all *_ld), gate with unlatched arb_*_ld_gnt
  assign  cmdo_ld_valid =  ( we_ld_valid || cpy_ld_valid || incr_ld_valid );

  always @*
    begin
      if( arb_eng_ld_gnt || arb_eng_rtry_ld_gnt )
        begin
          cmdo_ld_opcode[7:0]          =  ( we_ld_opcode[7:0]      | cpy_ld_opcode[7:0]      | incr_ld_opcode[7:0]     );
          cmdo_ld_actag[11:0]          =  ( we_ld_actag[11:0]      | cpy_ld_actag[11:0]      | incr_ld_actag[11:0]     );
          cmdo_ld_stream_id[3:0]       =  ( we_ld_stream_id[3:0]   | cpy_ld_stream_id[3:0]   | incr_ld_stream_id[3:0]  );
          cmdo_ld_ea_or_obj[67:0]      =  ( we_ld_ea_or_obj[67:0]  | cpy_ld_ea_or_obj[67:0]  | incr_ld_ea_or_obj[67:0] );
          cmdo_ld_afutag[15:0]         =  ( we_ld_afutag[15:0]     | cpy_ld_afutag[15:0]     | incr_ld_afutag[15:0]    );
          cmdo_ld_dl[1:0]              =  ( we_ld_dl[1:0]          | cpy_ld_dl[1:0]          | incr_ld_dl[1:0]         );
          cmdo_ld_pl[2:0]              =  ( we_ld_pl[2:0]          | cpy_ld_pl[2:0]          | incr_ld_pl[2:0]         );
          cmdo_ld_os                   =  ( we_ld_os              || cpy_ld_os              || incr_ld_os              );
          cmdo_ld_be[63:0]             =  ( we_ld_be[63:0]         | cpy_ld_be[63:0]         | incr_ld_be[63:0]        );
          cmdo_ld_flag[3:0]            =  ( we_ld_flag[3:0]        | cpy_ld_flag[3:0]        | incr_ld_flag[3:0]       );
          cmdo_ld_endian               =  ( we_ld_endian          || cpy_ld_endian          || incr_ld_endian          );
          cmdo_ld_bdf[15:0]            =  ( we_ld_bdf[15:0]        | cpy_ld_bdf[15:0]        | incr_ld_bdf[15:0]       );
          //cmdo_ld_pasid[19:0]          =  ( we_ld_pasid[19:0]      | cpy_ld_pasid[19:0]      | incr_ld_pasid[19:0]     );
          cmdo_ld_pg_size[5:0]         =  ( we_ld_pg_size[5:0]     | cpy_ld_pg_size[5:0]     | incr_ld_pg_size[5:0]    );
        end
      else
        begin
          cmdo_ld_opcode[7:0]          =   8'b0;
          cmdo_ld_actag[11:0]          =  12'b0;
          cmdo_ld_stream_id[3:0]       =   4'b0;
          cmdo_ld_ea_or_obj[67:0]      =  68'b0;
          cmdo_ld_afutag[15:0]         =  16'b0;
          cmdo_ld_dl[1:0]              =   2'b0;
          cmdo_ld_pl[2:0]              =   3'b0;
          cmdo_ld_os                   =   1'b0;
          cmdo_ld_be[63:0]             =  64'b0;
          cmdo_ld_flag[3:0]            =   4'b0;
          cmdo_ld_endian               =   1'b0;
          cmdo_ld_bdf[15:0]            =  16'b0;
          //cmdo_ld_pasid[19:0]          =  20'b0;
          cmdo_ld_pg_size[5:0]         =   6'b0;
        end
    end // -- always @ *

  // -- Form cmdo_st command (OR together all *_st commands)
  assign  cmdo_st_valid =  ( we_st_valid || cpy_st_valid || incr_st_valid );

  always @*
    begin
      if( arb_eng_st_gnt || arb_eng_rtry_st_gnt )
        begin
          cmdo_st_opcode[7:0]          =  ( we_st_opcode[7:0]      | cpy_st_opcode[7:0]      | incr_st_opcode[7:0]     );
          cmdo_st_actag[11:0]          =  ( we_st_actag[11:0]      | cpy_st_actag[11:0]      | incr_st_actag[11:0]     );
          cmdo_st_stream_id[3:0]       =  ( we_st_stream_id[3:0]   | cpy_st_stream_id[3:0]   | incr_st_stream_id[3:0]  );
          cmdo_st_ea_or_obj[67:0]      =  ( we_st_ea_or_obj[67:0]  | cpy_st_ea_or_obj[67:0]  | incr_st_ea_or_obj[67:0] );
          cmdo_st_afutag[15:0]         =  ( we_st_afutag[15:0]     | cpy_st_afutag[15:0]     | incr_st_afutag[15:0]    );
          cmdo_st_dl[1:0]              =  ( we_st_dl[1:0]          | cpy_st_dl[1:0]          | incr_st_dl[1:0]         );
          cmdo_st_pl[2:0]              =  ( we_st_pl[2:0]          | cpy_st_pl[2:0]          | incr_st_pl[2:0]         );
          cmdo_st_os                   =  ( we_st_os              || cpy_st_os              || incr_st_os              );
          cmdo_st_be[63:0]             =  ( we_st_be[63:0]         | cpy_st_be[63:0]         | incr_st_be[63:0]        );
          cmdo_st_flag[3:0]            =  ( we_st_flag[3:0]        | cpy_st_flag[3:0]        | incr_st_flag[3:0]       );
          cmdo_st_endian               =  ( we_st_endian          || cpy_st_endian          || incr_st_endian          );
          cmdo_st_bdf[15:0]            =  ( we_st_bdf[15:0]        | cpy_st_bdf[15:0]        | incr_st_bdf[15:0]       );
          //cmdo_st_pasid[19:0]          =  ( we_st_pasid[19:0]      | cpy_st_pasid[19:0]      | incr_st_pasid[19:0]     );
          cmdo_st_pg_size[5:0]         =  ( we_st_pg_size[5:0]     | cpy_st_pg_size[5:0]     | incr_st_pg_size[5:0]    );
        end 
      else
        begin
          cmdo_st_opcode[7:0]          =   8'b0;
          cmdo_st_actag[11:0]          =  12'b0;
          cmdo_st_stream_id[3:0]       =   4'b0;
          cmdo_st_ea_or_obj[67:0]      =  68'b0;
          cmdo_st_afutag[15:0]         =  16'b0;
          cmdo_st_dl[1:0]              =   2'b0;
          cmdo_st_pl[2:0]              =   3'b0;
          cmdo_st_os                   =   1'b0;
          cmdo_st_be[63:0]             =  64'b0;
          cmdo_st_flag[3:0]            =   4'b0;
          cmdo_st_endian               =   1'b0;
          cmdo_st_bdf[15:0]            =  16'b0;
          //cmdo_st_pasid[19:0]          =  20'b0;
          cmdo_st_pg_size[5:0]         =   6'b0;
        end
    end // -- always @ *

  // -- Form cmdo_misc command (OR together all misc commands)
  assign  cmdo_misc_valid =  ( actag_valid || xtouch_valid || wkhstthrd_valid || atomic_valid || intrpt_valid );

  always @*
    begin
      if( arb_eng_misc_gnt || arb_eng_rtry_misc_gnt )
        begin
          cmdo_misc_opcode[7:0]        =  ( actag_opcode[7:0]      | intrpt_opcode[7:0]      | xtouch_opcode[7:0]      | wkhstthrd_opcode[7:0]      | atomic_opcode[7:0]     );
          cmdo_misc_actag[11:0]        =  ( actag_actag[11:0]      | intrpt_actag[11:0]      | xtouch_actag[11:0]      | wkhstthrd_actag[11:0]      | atomic_actag[11:0]     );
          cmdo_misc_stream_id[3:0]     =  ( actag_stream_id[3:0]   | intrpt_stream_id[3:0]   | xtouch_stream_id[3:0]   | wkhstthrd_stream_id[3:0]   | atomic_stream_id[3:0]  );
          cmdo_misc_ea_or_obj[67:0]    =  ( actag_ea_or_obj[67:0]  | intrpt_ea_or_obj[67:0]  | xtouch_ea_or_obj[67:0]  | wkhstthrd_ea_or_obj[67:0]  | atomic_ea_or_obj[67:0] );
          cmdo_misc_afutag[15:0]       =  ( actag_afutag[15:0]     | intrpt_afutag[15:0]     | xtouch_afutag[15:0]     | wkhstthrd_afutag[15:0]     | atomic_afutag[15:0]    );
          cmdo_misc_dl[1:0]            =  ( actag_dl[1:0]          | intrpt_dl[1:0]          | xtouch_dl[1:0]          | wkhstthrd_dl[1:0]          | atomic_dl[1:0]         );
          cmdo_misc_pl[2:0]            =  ( actag_pl[2:0]          | intrpt_pl[2:0]          | xtouch_pl[2:0]          | wkhstthrd_pl[2:0]          | atomic_pl[2:0]         );
          cmdo_misc_os                 =  ( actag_os              || intrpt_os              || xtouch_os              || wkhstthrd_os              || atomic_os              );
          cmdo_misc_be[63:0]           =  ( actag_be[63:0]         | intrpt_be[63:0]         | xtouch_be[63:0]         | wkhstthrd_be[63:0]         | atomic_be[63:0]        );
          cmdo_misc_flag[3:0]          =  ( actag_flag[3:0]        | intrpt_flag[3:0]        | xtouch_flag[3:0]        | wkhstthrd_flag[3:0]        | atomic_flag[3:0]       );
          cmdo_misc_endian             =  ( actag_endian          || intrpt_endian          || xtouch_endian          || wkhstthrd_endian          || atomic_endian          );                           
          cmdo_misc_bdf[15:0]          =  ( actag_bdf[15:0]        | intrpt_bdf[15:0]        | xtouch_bdf[15:0]        | wkhstthrd_bdf[15:0]        | atomic_bdf[15:0]       );
          //cmdo_misc_pasid[19:0]        =  ( actag_pasid[19:0]      | intrpt_pasid[19:0]      | xtouch_pasid[19:0]      | wkhstthrd_pasid[19:0]      | atomic_pasid[19:0]     );
          cmdo_misc_pg_size[5:0]       =  ( actag_pg_size[5:0]     | intrpt_pg_size[5:0]     | xtouch_pg_size[5:0]     | wkhstthrd_pg_size[5:0]     | atomic_pg_size[5:0]    );
        end
      else
        begin
          cmdo_misc_opcode[7:0]        =   8'b0;
          cmdo_misc_actag[11:0]        =  12'b0;
          cmdo_misc_stream_id[3:0]     =   4'b0;
          cmdo_misc_ea_or_obj[67:0]    =  68'b0;
          cmdo_misc_afutag[15:0]       =  16'b0;
          cmdo_misc_dl[1:0]            =   2'b0;
          cmdo_misc_pl[2:0]            =   3'b0;
          cmdo_misc_os                 =   1'b0;                               
          cmdo_misc_be[63:0]           =  64'b0;
          cmdo_misc_flag[3:0]          =   4'b0;
          cmdo_misc_endian             =   1'b0;                       
          cmdo_misc_bdf[15:0]          =  16'b0;
          //cmdo_misc_pasid[19:0]        =  20'b0;
          cmdo_misc_pg_size[5:0]       =   6'b0;
        end
    end // -- always @ *


  // -- Combine 3 types of commands into a single command and latch
  assign  cmdo_valid_d           =  ( cmdo_ld_valid          || cmdo_st_valid          || cmdo_misc_valid           );
  assign  cmdo_opcode_d[7:0]     =  ( cmdo_ld_opcode[7:0]     | cmdo_st_opcode[7:0]     | cmdo_misc_opcode[7:0]     );
  assign  cmdo_actag_d[11:0]     =  ( cmdo_ld_actag[11:0]     | cmdo_st_actag[11:0]     | cmdo_misc_actag[11:0]     );
  assign  cmdo_stream_id_d[3:0]  =  ( cmdo_ld_stream_id[3:0]  | cmdo_st_stream_id[3:0]  | cmdo_misc_stream_id[3:0]  );
  assign  cmdo_ea_or_obj_d[67:0] =  ( cmdo_ld_ea_or_obj[67:0] | cmdo_st_ea_or_obj[67:0] | cmdo_misc_ea_or_obj[67:0] );
  assign  cmdo_afutag_d[15:0]    =  ( cmdo_ld_afutag[15:0]    | cmdo_st_afutag[15:0]    | cmdo_misc_afutag[15:0]    );
  assign  cmdo_dl_d[1:0]         =  ( cmdo_ld_dl[1:0]         | cmdo_st_dl[1:0]         | cmdo_misc_dl[1:0]         );
  assign  cmdo_pl_d[2:0]         =  ( cmdo_ld_pl[2:0]         | cmdo_st_pl[2:0]         | cmdo_misc_pl[2:0]         );
  assign  cmdo_os_d              =  ( cmdo_ld_os             || cmdo_st_os             || cmdo_misc_os              );
  assign  cmdo_be_d[63:0]        =  ( cmdo_ld_be[63:0]        | cmdo_st_be[63:0]        | cmdo_misc_be[63:0]        );
  assign  cmdo_flag_d[3:0]       =  ( cmdo_ld_flag[3:0]       | cmdo_st_flag[3:0]       | cmdo_misc_flag[3:0]       );
  assign  cmdo_endian_d          =  ( cmdo_ld_endian         || cmdo_st_endian         || cmdo_misc_endian          );
  assign  cmdo_bdf_d[15:0]       =  ( cmdo_ld_bdf[15:0]       | cmdo_st_bdf[15:0]       | cmdo_misc_bdf[15:0]       );
  assign  cmdo_pasid_d[19:0]     =  cmdo_valid_d  ?  { 10'b0, cmd_pasid_q[9:0] }  :
                                                     20'b0;
  assign  cmdo_pg_size_d[5:0]    =  ( cmdo_ld_pg_size[5:0]    | cmdo_st_pg_size[5:0]    | cmdo_misc_pg_size[5:0]    );

  assign  cmdo_st_valid_d        =  cmdo_st_valid || atomic_data_valid || intrpt_data_valid;

  // -- Drive Command interface to cmdo module off a latch
  assign  eng_cmdo_valid             =  cmdo_valid_q;
  assign  eng_cmdo_opcode[7:0]       =  cmdo_opcode_q[7:0];
  assign  eng_cmdo_actag[11:0]       =  cmdo_actag_q[11:0];
  assign  eng_cmdo_stream_id[3:0]    =  cmdo_stream_id_q[3:0];
  assign  eng_cmdo_ea_or_obj[67:0]   =  cmdo_ea_or_obj_q[67:0];
  assign  eng_cmdo_afutag[15:0]      =  cmdo_afutag_q[15:0];
  assign  eng_cmdo_dl[1:0]           =  cmdo_dl_q[1:0];
  assign  eng_cmdo_pl[2:0]           =  cmdo_pl_q[2:0];
  assign  eng_cmdo_os                =  cmdo_os_q;
  assign  eng_cmdo_be[63:0]          =  cmdo_be_q[63:0];
  assign  eng_cmdo_flag[3:0]         =  cmdo_flag_q[3:0];
  assign  eng_cmdo_endian            =  cmdo_endian_q;
  assign  eng_cmdo_bdf[15:0]         =  cmdo_bdf_q[15:0];
  assign  eng_cmdo_pasid[19:0]       =  cmdo_pasid_q[19:0];
  assign  eng_cmdo_pg_size[5:0]      =  cmdo_pg_size_q[5:0];

  assign  eng_cmdo_st_valid          =  cmdo_st_valid_q;  // -- This is only valid for 1 cycle ... indicator to cmd xmit logic that there is data


  // -- OR data from cpy_st and we_st (NOTE: cpy_st_data is gated with latched copies of grant, so NOT right off of a latch)
  assign  eng_cmdo_st_data[1023:576] = cpy_st_data[1023:576];
  assign  eng_cmdo_st_data[575:512]  = cpy_st_data[575:512] | eng_display_data[63:0];                              
  assign  eng_cmdo_st_data[511:0]    = cpy_st_data[511:0] |
                                        we_st_data[511:0] |
                                      incr_st_data[511:0] |
                                       atomic_data[511:0] |
                                       intrpt_data[511:0];

  // -- Send to resp_decode for checking for valid afutag
  assign  cmdo_valid        =  cmdo_valid_q;
  assign  cmdo_afutag[15:0] =  cmdo_afutag_q[15:0];


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  always @ ( posedge clock )
    begin

      // -- cpy_st data
      time_counter_q[63:0]                        <= time_counter_d[63:0];
      cpy_st_size_256_dly_q                       <= cpy_st_size_256_dly_d;
      cpy_st_gnt_dly_q                            <= cpy_st_gnt_dly_d;
      rtry_st_gnt_dly_q                           <= rtry_st_gnt_dly_d;

      mmio_eng_extra_write_mode_q                 <= mmio_eng_extra_write_mode;

      // -- for MMIO ping-pong latency mode
      mmio_eng_mmio_lat_mode_sz_512_st_q          <= mmio_eng_mmio_lat_mode_sz_512_st_d;
      mmio_lat_use_reg_data_q                     <= mmio_lat_use_reg_data_d;
      //if (mmio_lat_data_next_en)
      mmio_lat_data_next_q[1:0]                   <= mmio_lat_data_next_d[1:0];

      mmio_lat_data_sel_q[1:0]                    <= mmio_lat_data_sel_d[1:0];

      // -- eng_cmdo outbound interface latches
      cmdo_valid_q                                <= cmdo_valid_d;                 
      cmdo_opcode_q[7:0]                          <= cmdo_opcode_d[7:0];           
      cmdo_actag_q[11:0]                          <= cmdo_actag_d[11:0];           
      cmdo_stream_id_q[3:0]                       <= cmdo_stream_id_d[3:0];        
      cmdo_ea_or_obj_q[67:0]                      <= cmdo_ea_or_obj_d[67:0];       
      cmdo_afutag_q[15:0]                         <= cmdo_afutag_d[15:0];          
      cmdo_dl_q[1:0]                              <= cmdo_dl_d[1:0];               
      cmdo_pl_q[2:0]                              <= cmdo_pl_d[2:0];               
      cmdo_os_q                                   <= cmdo_os_d;                    
      cmdo_be_q[63:0]                             <= cmdo_be_d[63:0];              
      cmdo_flag_q[3:0]                            <= cmdo_flag_d[3:0];             
      cmdo_endian_q                               <= cmdo_endian_d;                
      cmdo_bdf_q[15:0]                            <= cmdo_bdf_d[15:0];             
      cmdo_pasid_q[19:0]                          <= cmdo_pasid_d[19:0];           
      cmdo_pg_size_q[5:0]                         <= cmdo_pg_size_d[5:0];          
      cmdo_st_valid_q                             <= cmdo_st_valid_d;              

    end // -- always @ *

endmodule
