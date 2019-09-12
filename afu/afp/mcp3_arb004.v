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

module mcp3_arb004 (

  // -- Clocks & Reset
    input                 clock
  , input                 reset

  // -- input request bus
  , input                 req_taken
  , input           [3:0] req_bus
  , input           [3:0] req_bus_2pending

  // -- encoded output select
  , output                winner_valid
  , output          [1:0] winner
  , output reg      [3:0] req_clear

  );

  reg       [3:0] decoded_winner;        // -- decode of the current winner_q(1:0), unqualified                                      
  reg       [3:0] current_winner;        // -- decode of the current winner_q(1:0), qualified with valid winner_valid_q             
  wire      [3:0] new_winner_gt;         // -- Used to block current winner from winning in next cycle unless prior stage has 2 or more requests pending 
  wire            pick_new_winner;                                                                                                 
  wire      [3:0] new_winner;            // -- next winner based upon request bus and who currently has lowest priority               
  reg       [1:0] new_winner_encoded;                                                                                              
  wire            any_new_winner;                                                                                                  

  reg       [1:0] winner_d;                                                                                                        
  reg       [1:0] winner_q;              // -- encode of lowest priority.  If winner_valid_q set, then this is the current winner    
  wire            winner_valid_d;                                                                                                          
  reg             winner_valid_q;                                                                                                          


  always @*
    begin
      // -- Decode the winner latches
      case ( winner_q[1:0] )
        2'b00 :  decoded_winner[3:0] = 4'b0001;
        2'b01 :  decoded_winner[3:0] = 4'b0010;
        2'b10 :  decoded_winner[3:0] = 4'b0100;
        2'b11 :  decoded_winner[3:0] = 4'b1000;
      endcase

      // -- qualify with current winner_lt to get current_winner decode
      if ( winner_valid_q )
        current_winner[3:0] =  decoded_winner[3:0];
      else
        current_winner[3:0] =  4'b0;

    end  // -- always @*


  // -- Create a gate to keep the current winner from winning again in the next cycle (allowing request to clear)
  // --   If, however, there are multiple stages to the arbitration, and the previous stage has multiple requests
  // --   active (as indicated by req_bus_2pending), then this stage can take back-to-back requests from the prior stage.
  assign  new_winner_gt[3] =  current_winner[3] && ~req_bus_2pending[3];
  assign  new_winner_gt[2] =  current_winner[2] && ~req_bus_2pending[2];
  assign  new_winner_gt[1] =  current_winner[1] && ~req_bus_2pending[1];
  assign  new_winner_gt[0] =  current_winner[0] && ~req_bus_2pending[0];


  // -- Determine next winner based on history and req_bus
  assign  new_winner[0] =  ( req_bus[0] && ~new_winner_gt[0] &&
                          (( decoded_winner[0] && ~req_bus[3] && ~req_bus[2] && ~req_bus[1] ) ||
                           ( decoded_winner[1] && ~req_bus[3] && ~req_bus[2]                ) ||
                           ( decoded_winner[2] && ~req_bus[3]                               ) ||
                           ( decoded_winner[3]                                              )));

  assign  new_winner[1] =  ( req_bus[1] && ~new_winner_gt[1] &&
                          (( decoded_winner[0]                                              ) ||
                           ( decoded_winner[1] && ~req_bus[3] && ~req_bus[2] && ~req_bus[0] ) ||
                           ( decoded_winner[2] && ~req_bus[3]                && ~req_bus[0] ) ||
                           ( decoded_winner[3]                               && ~req_bus[0] )));
                                                            
  assign  new_winner[2] =  ( req_bus[2] && ~new_winner_gt[2] &&
                          (( decoded_winner[0]                && ~req_bus[1]                ) ||
                           ( decoded_winner[1]                                              ) ||
                           ( decoded_winner[2] && ~req_bus[3] && ~req_bus[1] && ~req_bus[0] ) ||
                           ( decoded_winner[3]                && ~req_bus[1] && ~req_bus[0] )));

  assign  new_winner[3] =  ( req_bus[3] && ~new_winner_gt[3] &&
                          (( decoded_winner[0] && ~req_bus[2] && ~req_bus[1]                ) ||
                           ( decoded_winner[1] && ~req_bus[2]                               ) ||
                           ( decoded_winner[2]                                              ) ||
                           ( decoded_winner[3] && ~req_bus[2] && ~req_bus[1] && ~req_bus[0] )));


  // -- Encode the new winner
  always @*
    begin
      new_winner_encoded[1:0] = 2'b00;
      if ( new_winner[3] )  new_winner_encoded[1:0] = 2'b11;
      if ( new_winner[2] )  new_winner_encoded[1:0] = 2'b10;
      if ( new_winner[1] )  new_winner_encoded[1:0] = 2'b01;
      if ( new_winner[0] )  new_winner_encoded[1:0] = 2'b00;
    end  // -- always @*

  assign  any_new_winner =  ( new_winner[3:0] != 4'b0 );

  // -- Determine if winner latch should be updated
  // --   1) Current winner indicated that he is done
  // --   2) There is no current winner
  // --   3) The request for the current winner has been withdrawn, so pick a new winner 
  assign  pick_new_winner =  ( req_taken || ~winner_valid_q || ( | ( current_winner[3:0] & ~req_bus[3:0] )));


  // -- Winner valid if new_winner is non-zero OR if currently have a winner and not picking a new one
  assign  winner_valid_d =  (( any_new_winner || ( winner_valid_q && ~pick_new_winner )) && ~reset );


  // -- Update the winner latch
  always @*
    begin
      if ( reset )
        winner_d[1:0] =  2'b11;
      else if ( pick_new_winner )
        winner_d[1:0] =  new_winner_encoded[1:0];
      else
        winner_d[1:0] =  winner_q[1:0];
    end  // -- always @*


  // -- if request taken, feedback to previous stage(s) so they know which request latch to clear
  always @*
    begin
      if ( req_taken )
        req_clear[3:0] =  current_winner[3:0];
      else
        req_clear[3:0] =  4'b0;
    end  // -- always @*


  // -- Drive outputs
  assign  winner_valid =  winner_valid_q;
  assign  winner[1:0]  =  winner_q[1:0];


  // -- **************************************************
  // -- Latch Declarations
  // -- **************************************************

  always @ ( posedge clock )
    begin
      winner_q[1:0]     <= winner_d[1:0];
      winner_valid_q    <= winner_valid_d;               
    end

endmodule













































