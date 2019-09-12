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

module mcp3_decoder4x016 (

    input        [3:0] din 
  , output reg  [15:0] dout

  );

  always @*
    case ( din[3:0] )
      4'b1111 :  dout[15:0] =  16'b1000000000000000;
      4'b1110 :  dout[15:0] =  16'b0100000000000000;
      4'b1101 :  dout[15:0] =  16'b0010000000000000; 
      4'b1100 :  dout[15:0] =  16'b0001000000000000; 
      4'b1011 :  dout[15:0] =  16'b0000100000000000;
      4'b1010 :  dout[15:0] =  16'b0000010000000000;
      4'b1001 :  dout[15:0] =  16'b0000001000000000; 
      4'b1000 :  dout[15:0] =  16'b0000000100000000; 
      4'b0111 :  dout[15:0] =  16'b0000000010000000;
      4'b0110 :  dout[15:0] =  16'b0000000001000000;
      4'b0101 :  dout[15:0] =  16'b0000000000100000; 
      4'b0100 :  dout[15:0] =  16'b0000000000010000; 
      4'b0011 :  dout[15:0] =  16'b0000000000001000;
      4'b0010 :  dout[15:0] =  16'b0000000000000100;
      4'b0001 :  dout[15:0] =  16'b0000000000000010; 
      4'b0000 :  dout[15:0] =  16'b0000000000000001; 
    endcase

endmodule
