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

module mcp3_arb008 (

  // -- Clock & Reset
    input                 clock
  , input                 reset

  // -- input request bus
  , input                 req_taken
  , input           [7:0] req_bus
  , input           [7:0] req_bus_2pending

  // -- encoded output select
  , output                winner_valid
  , output          [2:0] winner
  , output reg      [7:0] req_clear

  );


  wire      [7:0] decoded_winner;
  reg       [7:0] current_winner;
  wire            pnw_early;
  wire            pick_new_winner_b;
  wire            pick_new_winner;
  wire      [7:0] new_winner;
  reg       [2:0] new_winner_encoded;
  wire            any_new_winner;
  wire      [7:0] p1,p2,p4,g1,g2,g4,g8;
  wire      [7:0] p1_rot,p2_rot;
  wire      [7:0] g1_rot,g2_rot,g4_rot;

  reg       [2:0] winner_d;
  reg       [2:0] winner_q;
  wire            winner_valid_d;
  reg             winner_valid_q;


  // -- select next arb winner based upon active requests and the history of
  // -- ...who was the last to win

  // -- let Ri = req_bus(i), Wi = decoded_winner(i)
  // -- then let Ei+1 = Ei*!Ri + Wi (wrapping indices. this will be computed in parallel-prefix)
  // -- Ni = new_winner(i) = Ri*!(Valid*Wi)*Ei

  // -- note, none of these gates should be in critical path; this is all for area reduction.

  assign  p1[7:0] =  ~req_bus[7:0];
  assign  g1[7:0] =  decoded_winner[7:0];

  assign  p2[7:0] =  ~( p1[7:0] & p1_rot[7:0] );
  assign  p4[7:0] =  ~( p2[7:0] | p2_rot[7:0] ); 

  assign  g2[7:0] =  ~( g1[7:0] | (p1[7:0] & g1_rot[7:0] ));
  assign  g4[7:0] =  ~( g2[7:0] & (p2[7:0] | g2_rot[7:0] ));
  assign  g8[7:0] =  ~( g4[7:0] | (p4[7:0] & g4_rot[7:0] ));  // -- g8(i) is not(Ei+1)

  assign  p1_rot[7:0] = { p1[6:0], p1[7]   };
  assign  p2_rot[7:0] = { p2[5:0], p2[7:6] };
  assign  g1_rot[7:0] = { g1[6:0], g1[7]   };
  assign  g2_rot[7:0] = { g2[5:0], g2[7:6] };
  assign  g4_rot[7:0] = { g4[3:0], g4[7:4] };

  always @*
    begin
      if ( winner_valid_q )
        current_winner[7:0] =  decoded_winner[7:0];
      else
        current_winner[7:0] =  8'b0;
    end  // -- always @*

  assign  new_winner[7:0] =  ( req_bus[7:0] & ~( current_winner[7:0] & ~req_bus_2pending[7:0] ) & ~{ g8[6:0], g8[7] } ) ;

  mcp3_decoder3x008  winner_decoder
    (
      .din        ( winner_q[2:0] ),
      .dout       ( decoded_winner[7:0] )
    );

  // -- Encode the new winner
  always @*
    begin
      new_winner_encoded[2:0] = 3'b000;
      if ( new_winner[7] )  new_winner_encoded[2:0] = 3'b111;
      if ( new_winner[6] )  new_winner_encoded[2:0] = 3'b110;
      if ( new_winner[5] )  new_winner_encoded[2:0] = 3'b101;
      if ( new_winner[4] )  new_winner_encoded[2:0] = 3'b100;
      if ( new_winner[3] )  new_winner_encoded[2:0] = 3'b011;
      if ( new_winner[2] )  new_winner_encoded[2:0] = 3'b010;
      if ( new_winner[1] )  new_winner_encoded[2:0] = 3'b001;
      if ( new_winner[0] )  new_winner_encoded[2:0] = 3'b000;
    end  // -- always @*

  assign  any_new_winner =  ( new_winner[7:0] != 8'b0 );

  assign  pnw_early         =  ( ~winner_valid_q  || ( | ( decoded_winner[7:0] & ~req_bus[7:0] )) );
  assign  pick_new_winner_b =  ~( req_taken || pnw_early );
  assign  pick_new_winner   =  ~pick_new_winner_b;


  // -- Winner valid if new_winner is non-zero OR if currently have a winner and not picking a new one
  assign  winner_valid_d =  ( any_new_winner || ~pick_new_winner ) && ~reset;


  // -- Update the winner latch
  always @*
    begin
      if ( reset )
        winner_d[2:0] =  3'b111;
      else if ( pick_new_winner )
        winner_d[2:0] =  new_winner_encoded[2:0];
      else
        winner_d[2:0] =  winner_q[2:0];
    end  // -- always @*


  // -- if request taken, feedback to previous stage(s) so they know which request latch to clear
  always @*
    begin
      if ( req_taken )
        req_clear[7:0] =  current_winner[7:0];
      else
        req_clear[7:0] =  8'b0;
    end  // -- always @*


  // -- Drive outputs
  assign  winner_valid =  winner_valid_q;
  assign  winner[2:0]  =  winner_q[2:0];


  // -- **************************************************
  // -- Latch Declarations
  // -- **************************************************

  always @ ( posedge clock )
    begin
      winner_q[2:0]     <= winner_d[2:0];
      winner_valid_q    <= winner_valid_d;
    end  // -- always @*

endmodule
