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

module mcp3_decoder5x032 (

    input        [4:0] din 
  , output reg   [31:0] dout

  );
                                                                                                                  
  wire         [7:0] bottom_decoded;

  mcp3_decoder3x008  bottom_level_decoder
    (
      .din        ( din[2:0] ),
      .dout       ( bottom_decoded[7:0] )
    );

  always @*
    case ( din[4:3] )
      2'b11 :  dout[31:0] =  {        bottom_decoded[7:0], 24'b0 };
      2'b10 :  dout[31:0] =  {  8'b0, bottom_decoded[7:0], 16'b0 };
      2'b01 :  dout[31:0] =  { 16'b0, bottom_decoded[7:0],  8'b0 };
      2'b00 :  dout[31:0] =  { 24'b0, bottom_decoded[7:0] };
    endcase

endmodule

  
