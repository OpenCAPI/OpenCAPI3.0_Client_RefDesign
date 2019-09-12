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

module mcp3_arb128 (
  
  // -- clock control
    input                 clock
  , input                 reset

  // -- input request bus
  , input                 req_taken
  , input         [127:0] req_bus

  // -- encoded output select
  , output reg      [6:0] final_winner
  , output                final_valid

  , output        [127:0] req_clear
  , output                req_2pending

  );


  wire      [7:0] req_taken_int;
  wire      [7:0] winner_valid;

  wire     [15:0] req_bus7;
  wire     [15:0] req_bus6;
  wire     [15:0] req_bus5;
  wire     [15:0] req_bus4;
  wire     [15:0] req_bus3;
  wire     [15:0] req_bus2;
  wire     [15:0] req_bus1;
  wire     [15:0] req_bus0;

  wire      [3:0] winner7;
  wire      [3:0] winner6;
  wire      [3:0] winner5;
  wire      [3:0] winner4;
  wire      [3:0] winner3;
  wire      [3:0] winner2;
  wire      [3:0] winner1;
  wire      [3:0] winner0;

  wire     [15:0] winner7_decoded;
  wire     [15:0] winner6_decoded;
  wire     [15:0] winner5_decoded;
  wire     [15:0] winner4_decoded;
  wire     [15:0] winner3_decoded;
  wire     [15:0] winner2_decoded;
  wire     [15:0] winner1_decoded;
  wire     [15:0] winner0_decoded;

  wire     [15:0] req_clear7;
  wire     [15:0] req_clear6;
  wire     [15:0] req_clear5;
  wire     [15:0] req_clear4;
  wire     [15:0] req_clear3;
  wire     [15:0] req_clear2;
  wire     [15:0] req_clear1;
  wire     [15:0] req_clear0;

  wire            final_valid_int;
  wire      [2:0] final_winner_int;
  wire      [7:0] final_winner_int_decoded;
  wire      [7:0] req_bus_2pending;                                                                                                        

  assign  req_bus7[15:0] =  req_bus[127:112];
  assign  req_bus6[15:0] =  req_bus[111:96];
  assign  req_bus5[15:0] =  req_bus[95:80];
  assign  req_bus4[15:0] =  req_bus[79:64];
  assign  req_bus3[15:0] =  req_bus[63:48];
  assign  req_bus2[15:0] =  req_bus[47:32];
  assign  req_bus1[15:0] =  req_bus[31:16];
  assign  req_bus0[15:0] =  req_bus[15:0];

  assign  req_clear[127:0] =  { req_clear7[15:0], req_clear6[15:0], req_clear5[15:0], req_clear4[15:0], req_clear3[15:0], req_clear2[15:0], req_clear1[15:0], req_clear0[15:0] };


  mcp3_arb016  arb7_16to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[7] ),
      .req_bus                      ( req_bus7[15:0] ),
      .req_bus_2pending             ( 16'b0 ),
      // -- encode output select
      .winner_valid                 ( winner_valid[7] ),
      .winner                       ( winner7[3:0] ),
      .req_clear                    ( req_clear7[15:0] )
    );

  mcp3_arb016  arb6_16to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[6] ),
      .req_bus                      ( req_bus6[15:0] ),
      .req_bus_2pending             ( 16'b0 ),
      // -- encode output select
      .winner_valid                 ( winner_valid[6] ),
      .winner                       ( winner6[3:0] ),
      .req_clear                    ( req_clear6[15:0] )
    );

  mcp3_arb016  arb5_16to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[5] ),
      .req_bus                      ( req_bus5[15:0] ),
      .req_bus_2pending             ( 16'b0 ),
      // -- encode output select
      .winner_valid                 ( winner_valid[5] ),
      .winner                       ( winner5[3:0] ),
      .req_clear                    ( req_clear5[15:0] )
    );

  mcp3_arb016  arb4_16to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[4] ),
      .req_bus                      ( req_bus4[15:0] ),
      .req_bus_2pending             ( 16'b0 ),
      // -- encode output select
      .winner_valid                 ( winner_valid[4] ),
      .winner                       ( winner4[3:0] ),
      .req_clear                    ( req_clear4[15:0] )
    );

  mcp3_arb016  arb3_16to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[3] ),
      .req_bus                      ( req_bus3[15:0] ),
      .req_bus_2pending             ( 16'b0 ),
      // -- encode output select
      .winner_valid                 ( winner_valid[3] ),
      .winner                       ( winner3[3:0] ),
      .req_clear                    ( req_clear3[15:0] )
    );

  mcp3_arb016  arb2_16to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[2] ),
      .req_bus                      ( req_bus2[15:0] ),
      .req_bus_2pending             ( 16'b0 ),
      // -- encode output select
      .winner_valid                 ( winner_valid[2] ),
      .winner                       ( winner2[3:0] ),
      .req_clear                    ( req_clear2[15:0] )
    );

  mcp3_arb016  arb1_16to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[1] ),
      .req_bus                      ( req_bus1[15:0] ),
      .req_bus_2pending             ( 16'b0 ),
      // -- encode output select
      .winner_valid                 ( winner_valid[1] ),
      .winner                       ( winner1[3:0] ),
      .req_clear                    ( req_clear1[15:0] )
    );

  mcp3_arb016  arb0_16to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken_int[0] ),
      .req_bus                      ( req_bus0[15:0] ),
      .req_bus_2pending             ( 16'b0 ),
      // -- encode output select
      .winner_valid                 ( winner_valid[0] ),
      .winner                       ( winner0[3:0] ),
      .req_clear                    ( req_clear0[15:0] )
    );


  mcp3_decoder4x016   winner7_decoder
    (
      .din        ( winner7[3:0] ),
      .dout       ( winner7_decoded[15:0] )
    );

  mcp3_decoder4x016   winner6_decoder
    (
      .din        ( winner6[3:0] ),
      .dout       ( winner6_decoded[15:0] )
    );

  mcp3_decoder4x016   winner5_decoder
    (
      .din        ( winner5[3:0] ),
      .dout       ( winner5_decoded[15:0] )
    );

  mcp3_decoder4x016   winner4_decoder
    (
      .din        ( winner4[3:0] ),
      .dout       ( winner4_decoded[15:0] )
    );

  mcp3_decoder4x016   winner3_decoder
    (
      .din        ( winner3[3:0] ),
      .dout       ( winner3_decoded[15:0] )
    );

  mcp3_decoder4x016   winner2_decoder
    (
      .din        ( winner2[3:0] ),
      .dout       ( winner2_decoded[15:0] )
    );

  mcp3_decoder4x016   winner1_decoder
    (
      .din        ( winner1[3:0] ),
      .dout       ( winner1_decoded[15:0] )
    );

  mcp3_decoder4x016   winner0_decoder
    (
      .din        ( winner0[3:0] ),
      .dout       ( winner0_decoded[15:0] )
    );


  assign  req_bus_2pending[7] =  ( winner_valid[7] && ( | ( req_bus7[15:0] & ~winner7_decoded[15:0] )));
  assign  req_bus_2pending[6] =  ( winner_valid[6] && ( | ( req_bus6[15:0] & ~winner6_decoded[15:0] )));
  assign  req_bus_2pending[5] =  ( winner_valid[5] && ( | ( req_bus5[15:0] & ~winner5_decoded[15:0] )));
  assign  req_bus_2pending[4] =  ( winner_valid[4] && ( | ( req_bus4[15:0] & ~winner4_decoded[15:0] )));
  assign  req_bus_2pending[3] =  ( winner_valid[3] && ( | ( req_bus3[15:0] & ~winner3_decoded[15:0] )));
  assign  req_bus_2pending[2] =  ( winner_valid[2] && ( | ( req_bus2[15:0] & ~winner2_decoded[15:0] )));
  assign  req_bus_2pending[1] =  ( winner_valid[1] && ( | ( req_bus1[15:0] & ~winner1_decoded[15:0] )));
  assign  req_bus_2pending[0] =  ( winner_valid[0] && ( | ( req_bus0[15:0] & ~winner0_decoded[15:0] )));


  mcp3_arb008  arb_8to1
    (
      .clock                        ( clock ),
      .reset                        ( reset ),
      // -- input request bus
      .req_taken                    ( req_taken ),
      .req_bus                      ( winner_valid[7:0] ),
      .req_bus_2pending             ( req_bus_2pending[7:0] ),
      // -- encode output select
      .winner_valid                 ( final_valid_int ),
      .winner                       ( final_winner_int[2:0] ),
      .req_clear                    ( req_taken_int[7:0] )
    );

  assign  final_valid =  final_valid_int;

  always @*
    begin
      final_winner[6:4] =  final_winner_int[2:0];

      case ( final_winner_int[2:0] )
        3'b111 :  final_winner[3:0] =  winner7[3:0];
        3'b110 :  final_winner[3:0] =  winner6[3:0];
        3'b101 :  final_winner[3:0] =  winner5[3:0];
        3'b100 :  final_winner[3:0] =  winner4[3:0];
        3'b011 :  final_winner[3:0] =  winner3[3:0];
        3'b010 :  final_winner[3:0] =  winner2[3:0];
        3'b001 :  final_winner[3:0] =  winner1[3:0];
        3'b000 :  final_winner[3:0] =  winner0[3:0];
      endcase
    end  // -- always @*

  mcp3_decoder3x008   final_winner_decoder
    (
      .din        ( final_winner_int[2:0] ),
      .dout       ( final_winner_int_decoded[7:0] )
    );


  assign req_2pending =  ( final_valid_int && ( | ( winner_valid[7:0] & ~final_winner_int_decoded[7:0] )));


endmodule
