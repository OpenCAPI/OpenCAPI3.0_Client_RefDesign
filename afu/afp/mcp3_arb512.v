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

module mcp3_arb512 (

  // Clocks & Reset
    input                 clock
  , input                 reset

  // -- input request bus
  , input                 req_taken
  , input         [511:0] req_bus
  , output        [511:0] req_clear

  // -- encoded output select
  , output reg      [8:0] final_winner
  , output                final_valid

  );


  wire      [3:0] req_taken_int;
  wire      [3:0] winner_valid;
  wire      [6:0] winner0;
  wire      [6:0] winner1;
  wire      [6:0] winner2;
  wire      [6:0] winner3;
  wire    [127:0] req_bus0;
  wire    [127:0] req_bus1;
  wire    [127:0] req_bus2;
  wire    [127:0] req_bus3;
  wire    [127:0] req_clear0;
  wire    [127:0] req_clear1;
  wire    [127:0] req_clear2;
  wire    [127:0] req_clear3;
  wire      [1:0] final_winner_int;
  wire      [3:0] req_bus_2pending;


  assign  req_bus3[127:0] =  req_bus[511:384];
  assign  req_bus2[127:0] =  req_bus[383:256];
  assign  req_bus1[127:0] =  req_bus[255:128];
  assign  req_bus0[127:0] =  req_bus[127:0];

  assign  req_clear[511:0] =  { req_clear3[127:0], req_clear2[127:0], req_clear1[127:0], req_clear0[127:0] };


  mcp3_arb128  arb3_128to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[3] ),
      .req_bus                      ( req_bus3[127:0] ),
      .req_clear                    ( req_clear3[127:0] ),
      // -- encode output select
      .final_valid                  ( winner_valid[3] ),
      .final_winner                 ( winner3[6:0] ),
      .req_2pending                 ( req_bus_2pending[3] )
    );

  mcp3_arb128  arb2_128to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[2] ),
      .req_bus                      ( req_bus2[127:0] ),
      .req_clear                    ( req_clear2[127:0] ),
      // -- encode output select
      .final_valid                  ( winner_valid[2] ),
      .final_winner                 ( winner2[6:0] ),
      .req_2pending                 ( req_bus_2pending[2] )
    );

  mcp3_arb128  arb1_128to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[1] ),
      .req_bus                      ( req_bus1[127:0] ),
      .req_clear                    ( req_clear1[127:0] ),
      // -- encode output select
      .final_valid                  ( winner_valid[1] ),
      .final_winner                 ( winner1[6:0] ),
      .req_2pending                 ( req_bus_2pending[1] )
    );

  mcp3_arb128  arb0_128to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[0] ),
      .req_bus                      ( req_bus0[127:0] ),
      .req_clear                    ( req_clear0[127:0] ),
      // -- encode output select
      .final_valid                  ( winner_valid[0] ),
      .final_winner                 ( winner0[6:0] ),
      .req_2pending                 ( req_bus_2pending[0] )
    );


  mcp3_arb004  arb_4to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken ),
      .req_bus                      ( winner_valid[3:0] ),
      .req_bus_2pending             ( req_bus_2pending[3:0] ),
      // -- encode output select
      .winner_valid                 ( final_valid ),
      .winner                       ( final_winner_int[1:0] ),
      .req_clear                    ( req_taken_int[3:0] )
    );


  always @*
    begin
      final_winner[8:7] =  final_winner_int[1:0];

      case ( final_winner_int[1:0] )
        2'b11 :  final_winner[6:0] =  winner3[6:0];
        2'b10 :  final_winner[6:0] =  winner2[6:0];
        2'b01 :  final_winner[6:0] =  winner1[6:0];
        2'b00 :  final_winner[6:0] =  winner0[6:0];
      endcase
    end  // -- always @*


endmodule
