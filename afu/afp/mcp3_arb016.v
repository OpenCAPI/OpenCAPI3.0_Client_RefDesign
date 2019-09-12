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

module mcp3_arb016 (

  // -- Clocks & Reset
    input                 clock
  , input                 reset

  // -- input request bus
  , input                 req_taken
  , input          [15:0] req_bus
  , input          [15:0] req_bus_2pending                                                                                                         
  // -- encoded output select
  , output                winner_valid
  , output          [3:0] winner
  , output reg     [15:0] req_clear

  );


  wire     [15:0] decoded_winner;
  reg      [15:0] current_winner;
  wire            pnw_early;
  wire            pick_new_winner_b;
  wire            pick_new_winner;
  wire     [15:0] new_winner;
  reg       [3:0] new_winner_encoded;
  wire            any_new_winner;
  wire     [15:0] p1,p2,p4,p8,g1,g2,g4,g8,g16;
  wire     [15:0] p1_rot,p2_rot,p4_rot;
  wire     [15:0] g1_rot,g2_rot,g4_rot,g8_rot;

  reg       [3:0] winner_d;
  reg       [3:0] winner_q;
  wire            winner_valid_d;
  reg             winner_valid_q;


  // -- select next arb winner based upon active requests and the history of
  // -- ...who was the last to win

  // -- let Ri = req_bus(i), Wi = decoded_winner(i)
  // -- then let Ei+1 = Ei*!Ri + Wi (wrapping indices. this will be computed in parallel-prefix)
  // -- Ni = new_winner(i) = Ri*!(Valid*Wi)*Ei

  // -- note, none of these gates should be in critical path; this is all for area reduction.

  assign  p1[15:0] =  ~req_bus[15:0];
  assign  g1[15:0] =  decoded_winner[15:0];

  assign  p2[15:0] =  ~( p1[15:0] & p1_rot[15:0] );
  assign  p4[15:0] =  ~( p2[15:0] | p2_rot[15:0] ); 
  assign  p8[15:0] =  ~( p4[15:0] & p4_rot[15:0] ); 

  assign  g2[15:0] =  ~( g1[15:0] | ( p1[15:0] & g1_rot[15:0] ));
  assign  g4[15:0] =  ~( g2[15:0] & ( p2[15:0] | g2_rot[15:0] ));
  assign  g8[15:0] =  ~( g4[15:0] | ( p4[15:0] & g4_rot[15:0] )); 
  assign g16[15:0] =  ~( g8[15:0] & ( p8[15:0] | g8_rot[15:0] ));  // -- g8(i) is not(Ei+1)

  assign  p1_rot[15:0] = { p1[14:0], p1[15]    };
  assign  p2_rot[15:0] = { p2[13:0], p2[15:14] };
  assign  p4_rot[15:0] = { p4[11:0], p4[15:12] };
  assign  g1_rot[15:0] = { g1[14:0], g1[15]    };
  assign  g2_rot[15:0] = { g2[13:0], g2[15:14] };
  assign  g4_rot[15:0] = { g4[11:0], g4[15:12] };
  assign  g8_rot[15:0] = { g8[7:0] , g8[15:8]  };

  always @*
    begin
      if ( winner_valid_q )
        current_winner[15:0] =  decoded_winner[15:0];
      else
        current_winner[15:0] =  16'b0;
    end  // -- always @*

  assign  new_winner[15:0] = ( req_bus[15:0] & ~current_winner[15:0] & { g16[14:0], g16[15] } );

  mcp3_decoder4x016  winner_decoder
    (
      .din        ( winner_q[3:0] ),
      .dout       ( decoded_winner[15:0] )
    );

  // -- Encode the new winner
  always @*
    begin
      new_winner_encoded[3:0] = 4'b0000;
      if ( new_winner[15] )  new_winner_encoded[3:0] = 4'b1111;
      if ( new_winner[14] )  new_winner_encoded[3:0] = 4'b1110;
      if ( new_winner[13] )  new_winner_encoded[3:0] = 4'b1101;
      if ( new_winner[12] )  new_winner_encoded[3:0] = 4'b1100;
      if ( new_winner[11] )  new_winner_encoded[3:0] = 4'b1011;
      if ( new_winner[10] )  new_winner_encoded[3:0] = 4'b1010;
      if ( new_winner[9] )   new_winner_encoded[3:0] = 4'b1001;
      if ( new_winner[8] )   new_winner_encoded[3:0] = 4'b1000;
      if ( new_winner[7] )   new_winner_encoded[3:0] = 4'b0111;
      if ( new_winner[6] )   new_winner_encoded[3:0] = 4'b0110;
      if ( new_winner[5] )   new_winner_encoded[3:0] = 4'b0101;
      if ( new_winner[4] )   new_winner_encoded[3:0] = 4'b0100;
      if ( new_winner[3] )   new_winner_encoded[3:0] = 4'b0011;
      if ( new_winner[2] )   new_winner_encoded[3:0] = 4'b0010;
      if ( new_winner[1] )   new_winner_encoded[3:0] = 4'b0001;
      if ( new_winner[0] )   new_winner_encoded[3:0] = 4'b0000;
    end  // -- always @*

  assign  any_new_winner =  ( new_winner[15:0] != 16'b0 );

  assign  pnw_early         =  ( ~winner_valid_q  || ( | ( decoded_winner[15:0] & ~req_bus[15:0] )) );
  assign  pick_new_winner_b =  ~( req_taken || pnw_early );
  assign  pick_new_winner   =  ~pick_new_winner_b;


  // -- Winner valid if new_winner is non-zero OR if currently have a winner and not picking a new one
  assign  winner_valid_d =  ( any_new_winner || ~pick_new_winner ) && ~reset;


  // -- Update the winner latch
  always @*
    begin
      if ( reset )
        winner_d[3:0] =  4'b0;
      else if ( pick_new_winner )
        winner_d[3:0] =  new_winner_encoded[3:0];
      else
        winner_d[3:0] =  winner_q[3:0];
    end  // -- always @*


  // -- if request taken, feedback to previous stage(s) so they know which request latch to clear
  always @*
    begin
      if ( req_taken )
        req_clear[15:0] =  current_winner[15:0];
      else
        req_clear[15:0] =  16'b0;
    end  // -- always @*


  // -- Drive outputs
  assign  winner_valid =  winner_valid_q;
  assign  winner[3:0]  =  winner_q[3:0];


  // -- **************************************************
  // -- Latch Declarations
  // -- **************************************************

  always @ ( posedge clock )
    begin
      winner_q[3:0]    <= winner_d[3:0];
      winner_valid_q     <= winner_valid_d;
    end  // -- always @*

endmodule
