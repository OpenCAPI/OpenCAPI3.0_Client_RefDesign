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

module mcp3_decoder3x008 (

    input        [2:0] din 
  , output reg   [7:0] dout

  );

  always @*
    case ( din[2:0] )
      3'b111 :  dout[7:0] =  8'b10000000;
      3'b110 :  dout[7:0] =  8'b01000000;
      3'b101 :  dout[7:0] =  8'b00100000; 
      3'b100 :  dout[7:0] =  8'b00010000; 
      3'b011 :  dout[7:0] =  8'b00001000;
      3'b010 :  dout[7:0] =  8'b00000100;
      3'b001 :  dout[7:0] =  8'b00000010; 
      3'b000 :  dout[7:0] =  8'b00000001; 
    endcase

endmodule
