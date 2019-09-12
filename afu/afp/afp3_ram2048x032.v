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

module afp3_ram2048x032 (

  // -- Clock
    input              clk

  // -- Write Port
  , input              wren
  , input       [10:0] wrad
  , input       [31:0] data

  // -- Read Port
  , input              rden
  , input       [10:0] rdad
  , output      [31:0] q

  );

 (* ram_style = "block" *)

  reg    [31:0] ram [0:2047];
  reg    [31:0] q_int;

  always @(posedge clk)
   begin
     if ( wren == 1'b1 )
        ram [wrad] <= data[31:0];
    
     if ( rden == 1'b1)
       begin
          if (( rdad[10:0] != wrad[10:0] ) || ( wren == 1'b0 ))
             q_int[31:0] <= ram[rdad];
          else
             q_int[31:0] <= 32'bx; 
        end
   end  // -- always @*

  assign q[31:0] =  q_int[31:0];

endmodule
