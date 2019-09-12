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

module afp3_eng_rtry_decode (
    input                 mmio_eng_enable
  , input                 mmio_eng_resend_retries

  // -- Indication that latched output of the rtry queue is valid
  , input                 rtry_queue_func_rden_dly2_q

  // -- Latched outputs from the Retry Queue Array
  , input                 rtry_queue_cpy_xx_q
  , input                 rtry_queue_cpy_st_q
  , input           [4:0] rtry_queue_afutag_q
  , input                 rtry_queue_is_pending_q
  , input                 rtry_queue_is_rtry_lwt_q
  , input                 rtry_queue_is_rtry_req_q
  , input                 rtry_queue_is_rtry_hwt_q

  // -- Raw outputs from the Resp Code Array corresponding to latched rtry queue output
  , input                 resp_code_is_done
  , input                 resp_code_is_rty_req
  , input                 resp_code_is_failed
  , input                 resp_code_is_adr_error

  // -- Sequencer states for qualifying rtry valids w/ afutags
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

  // -- Outputs
  , output                start_we_rtry_ld_seq
  , output                start_xtouch_rtry_source_seq
  , output                start_xtouch_rtry_dest_seq
  , output                start_cpy_rtry_ld_seq
  , output                start_cpy_rtry_st_seq
  , output                start_wkhstthrd_rtry_seq
  , output                start_incr_rtry_ld_seq 
  , output                start_incr_rtry_st_seq 
  , output                start_atomic_rtry_seq
  , output                start_intrpt_rtry_seq
  , output                start_we_rtry_st_seq

  , output                rtry_decode_is_hwt
  , output                rtry_decode_is_immediate 
  , output                rtry_decode_is_backoff
  , output                rtry_decode_is_abort

  );

  // -- ********************************************************************************************************************************
  // -- Signal declarations
  // -- ********************************************************************************************************************************

  // -- Retry Queue AFUTAG decode
  wire            rtry_queue_afutag_is_we_ld;
  wire            rtry_queue_afutag_is_xtouch_source;
  wire            rtry_queue_afutag_is_xtouch_dest;
  wire            rtry_queue_afutag_is_cpy_ld;
  wire            rtry_queue_afutag_is_cpy_st;
  wire            rtry_queue_afutag_is_wkhstthrd;
  wire            rtry_queue_afutag_is_intrpt_wht;
  wire            rtry_queue_afutag_is_incr_ld;
  wire            rtry_queue_afutag_is_incr_st;
  wire            rtry_queue_afutag_is_atomic_ld;
  wire            rtry_queue_afutag_is_atomic_st;
  wire            rtry_queue_afutag_is_atomic_cas;
  wire            rtry_queue_afutag_is_intrpt_err;
  wire            rtry_queue_afutag_is_intrpt_cmd;
  wire            rtry_queue_afutag_is_we_st;

  // -- Output AFUTAG decode groupings
  wire            rtry_queue_afutag_is_xtouch;
  wire            rtry_queue_afutag_is_cpy;
  wire            rtry_queue_afutag_is_incr;
  wire            rtry_queue_afutag_is_atomic;
  wire            rtry_queue_afutag_is_intrpt;

  wire      [8:0] rtry_decode_sel;
  reg       [3:0] rtry_decode;


  // -- ********************************************************************************************************************************
  // -- Constant declarations
  // -- ********************************************************************************************************************************

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
  // -- Decode AFUTAG from Retry Queue
  // -- ********************************************************************************************************************************

  // -- Response AFUTAG decodes
  assign  rtry_queue_afutag_is_we_ld          =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] ==  WE_LD_AFUTAG_ENCODE[4:0]        ));
  assign  rtry_queue_afutag_is_xtouch_source  =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == XTOUCH_SOURCE_AFUTAG_ENCODE[4:0] ));
  assign  rtry_queue_afutag_is_xtouch_dest    =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == XTOUCH_DEST_AFUTAG_ENCODE[4:0]   ));
//     assign  rtry_queue_afutag_is_cpy_ld         =  ( rtry_queue_cpy_xx_q &&   cpy_ld_wt4rsp_st                                            );
//     assign  rtry_queue_afutag_is_cpy_st         =  ( rtry_queue_cpy_xx_q &&   cpy_st_wt4rsp_st                                            );
  assign  rtry_queue_afutag_is_cpy_ld         =  ( rtry_queue_cpy_xx_q &&   ~rtry_queue_cpy_st_q  );
  assign  rtry_queue_afutag_is_cpy_st         =  ( rtry_queue_cpy_xx_q &&    rtry_queue_cpy_st_q  );
  assign  rtry_queue_afutag_is_wkhstthrd      =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == WKHSTTHRD_AFUTAG_ENCODE [4:0]    ));
  assign  rtry_queue_afutag_is_intrpt_wht     =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == INTRPT_WHT_AFUTAG_ENCODE[4:0]    ));  // -- AFUTAG[12] = b'1 if "intrpt_w_data"
  assign  rtry_queue_afutag_is_incr_ld        =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == INCR_LD_AFUTAG_ENCODE[4:0]       ));
  assign  rtry_queue_afutag_is_incr_st        =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == INCR_ST_AFUTAG_ENCODE[4:0]       ));
  assign  rtry_queue_afutag_is_atomic_ld      =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == ATOMIC_LD_AFUTAG_ENCODE[4:0]     ));
  assign  rtry_queue_afutag_is_atomic_st      =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == ATOMIC_ST_AFUTAG_ENCODE[4:0]     ));
  assign  rtry_queue_afutag_is_atomic_cas     =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == ATOMIC_CAS_AFUTAG_ENCODE[4:0]    ));
  assign  rtry_queue_afutag_is_intrpt_err     =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == INTRPT_ERR_AFUTAG_ENCODE[4:0]    ));  // -- AFUTAG[12] = b'1 if "intrpt_w_data"
  assign  rtry_queue_afutag_is_intrpt_cmd     =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == INTRPT_CMD_AFUTAG_ENCODE[4:0]    ));  // -- AFUTAG[12] = b'1 if "intrpt_w_data"
  assign  rtry_queue_afutag_is_we_st          =  (~rtry_queue_cpy_xx_q && ( rtry_queue_afutag_q[4:0] == WE_ST_AFUTAG_ENCODE[4:0]         ));
 
  // -- Group Response AFUTAG decodes for sequencers that can issue more than one type of command
  assign  rtry_queue_afutag_is_cpy     =  ( rtry_queue_afutag_is_cpy_ld        || rtry_queue_afutag_is_cpy_st );            // -- cpy_ld or cpy_st
  assign  rtry_queue_afutag_is_xtouch  =  ( rtry_queue_afutag_is_xtouch_source || rtry_queue_afutag_is_xtouch_dest );       // -- xtouch seq issues two commands - both can be outstanding
  assign  rtry_queue_afutag_is_incr    =  ( rtry_queue_afutag_is_incr_ld       || rtry_queue_afutag_is_incr_st );           // -- incr   seq issues two commands - serially. (ld must complete before st can be issued)
  assign  rtry_queue_afutag_is_atomic  =  ( rtry_queue_afutag_is_atomic_ld     || rtry_queue_afutag_is_atomic_st  || rtry_queue_afutag_is_atomic_cas );  // -- atomic seq issues only 1 cmd (can be 1 of 3 types) 
  assign  rtry_queue_afutag_is_intrpt  =  ( rtry_queue_afutag_is_intrpt_cmd    || rtry_queue_afutag_is_intrpt_err || rtry_queue_afutag_is_intrpt_wht );  // -- intrpt seq issues only 1 cmd (can be 1 of 3 types)

  // -- When AFU is disabled, do not re-send commands that received retry responses, unless mode bit is set.
  // --   The easiest way to do this is to treat all retries as if they received a failed response, and abort the command.
  assign  abort_all_retries  = ~mmio_eng_enable & ~mmio_eng_resend_retries;

  // -- Decode the rtry queue output and resp code array output
  assign  rtry_decode_sel[8:0] =  { rtry_queue_is_pending_q, rtry_queue_is_rtry_lwt_q, rtry_queue_is_rtry_req_q, rtry_queue_is_rtry_hwt_q,
                                    resp_code_is_done, resp_code_is_rty_req, resp_code_is_failed, resp_code_is_adr_error, abort_all_retries };
  always @*
    begin
      casez ( rtry_decode_sel[8:0] )
        // --
        // --  Inputs                   
        // --  --------------------     
        // --  rtry_queue_is_pending_q    
        // --  |rtry_queue_is_rtry_lwt_q  
        // --  ||rtry_queue_is_rtry_req_q 
        // --  |||rtry_queue_is_rtry_hwt_q           Outputs
        // --  ||||                                  ------------------
        // --  |||| resp_code_is_done                rtry_decode_is_immediate
        // --  |||| |resp_is_rty_req                 |rtry_decode_is_backoff
        // --  |||| ||resp_is_failed                 ||rtry_decode_is_abort
        // --  |||| |||resp_is_adr_error             ||| rtry_decode_is_hwt
        // --  |||| ||||abort_all_retries            ||| |
        // --  |||| |||||                            ||| |
        // --  8765 43210                            321 0
        // -----------------------------------------------
            9'b01??_????0  :  rtry_decode[3:0] =  4'b010_0 ; 
            9'b001?_????0  :  rtry_decode[3:0] =  4'b010_0 ; 
            9'b0001_????0  :  rtry_decode[3:0] =  4'b100_1 ; 
        // -----------------------------------------------
            9'b01??_????1  :  rtry_decode[3:0] =  4'b001_0 ; 
            9'b001?_????1  :  rtry_decode[3:0] =  4'b001_0 ; 
            9'b0001_????1  :  rtry_decode[3:0] =  4'b001_0 ; 
        // -----------------------------------------------
            9'b1???_1???0  :  rtry_decode[3:0] =  4'b100_0 ; 
            9'b1???_01??0  :  rtry_decode[3:0] =  4'b010_0 ; 
            9'b1???_001?0  :  rtry_decode[3:0] =  4'b001_0 ; 
            9'b1???_00010  :  rtry_decode[3:0] =  4'b001_0 ; 
            9'b1???_????1  :  rtry_decode[3:0] =  4'b001_0 ; 
        // -----------------------------------------------
            default        :  rtry_decode[3:0] =  4'b000_0 ;
        // -----------------------------------------------
      endcase
    end // -- always @ *

  assign  rtry_decode_is_immediate =  rtry_decode[3];
  assign  rtry_decode_is_backoff   =  rtry_decode[2];
  assign  rtry_decode_is_abort     =  rtry_decode[1];
  assign  rtry_decode_is_hwt       =  rtry_decode[0];

  // -- start the appropriate sequencer depending upon which is in its Wt4Rsp State
  assign  start_we_rtry_ld_seq         =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_we_ld         &&     we_ld_wt4rsp_st ));
  assign  start_xtouch_rtry_source_seq =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_xtouch_source &&    xtouch_wt4rsp_st ));
  assign  start_xtouch_rtry_dest_seq   =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_xtouch_dest   &&    xtouch_wt4rsp_st ));
  assign  start_cpy_rtry_ld_seq        =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_cpy_ld        &&    cpy_ld_wt4rsp_st ));
  assign  start_cpy_rtry_st_seq        =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_cpy_st        &&    cpy_st_wt4rsp_st ));
  assign  start_wkhstthrd_rtry_seq     =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_wkhstthrd     && wkhstthrd_wt4rsp_st ));
  assign  start_incr_rtry_ld_seq       =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_incr_ld       &&    incr_wt4ldrsp_st ));
  assign  start_incr_rtry_st_seq       =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_incr_st       &&    incr_wt4strsp_st ));
  assign  start_atomic_rtry_seq        =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_atomic        &&    atomic_wt4rsp_st ));
  assign  start_intrpt_rtry_seq        =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_intrpt        &&    intrpt_wt4rsp_st ));
  assign  start_we_rtry_st_seq         =  ( rtry_queue_func_rden_dly2_q && ( rtry_queue_afutag_is_we_st         &&     we_st_wt4rsp_st ));

endmodule




