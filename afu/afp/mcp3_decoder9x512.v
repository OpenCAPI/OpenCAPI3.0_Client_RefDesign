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

module mcp3_decoder9x512 (

    input        [8:0] din 
  , output reg [511:0] dout

  );
                                                                                                                  
  wire          [31:0] bottom_decoded;

  mcp3_decoder5x032  bottom_level_decoder
    (
      .din        ( din[4:0] ),
      .dout       ( bottom_decoded[31:0] )
    );

  always @*
    case ( din[8:5] )
      4'b1111 :  dout[511:0] =  {         bottom_decoded[31:0], 480'b0 };
      4'b1110 :  dout[511:0] =  {  32'b0, bottom_decoded[31:0], 448'b0 };
      4'b1101 :  dout[511:0] =  {  64'b0, bottom_decoded[31:0], 416'b0 };
      4'b1100 :  dout[511:0] =  {  96'b0, bottom_decoded[31:0], 384'b0 };
      4'b1011 :  dout[511:0] =  { 128'b0, bottom_decoded[31:0], 352'b0 };
      4'b1010 :  dout[511:0] =  { 160'b0, bottom_decoded[31:0], 320'b0 };
      4'b1001 :  dout[511:0] =  { 192'b0, bottom_decoded[31:0], 288'b0 };
      4'b1000 :  dout[511:0] =  { 224'b0, bottom_decoded[31:0], 256'b0 };
      4'b0111 :  dout[511:0] =  { 256'b0, bottom_decoded[31:0], 224'b0 };
      4'b0110 :  dout[511:0] =  { 288'b0, bottom_decoded[31:0], 192'b0 };
      4'b0101 :  dout[511:0] =  { 320'b0, bottom_decoded[31:0], 160'b0 };
      4'b0100 :  dout[511:0] =  { 352'b0, bottom_decoded[31:0], 128'b0 };
      4'b0011 :  dout[511:0] =  { 384'b0, bottom_decoded[31:0],  96'b0 };
      4'b0010 :  dout[511:0] =  { 416'b0, bottom_decoded[31:0],  64'b0 };
      4'b0001 :  dout[511:0] =  { 448'b0, bottom_decoded[31:0],  32'b0 };
      4'b0000 :  dout[511:0] =  { 480'b0, bottom_decoded[31:0] };
    endcase

endmodule

  
