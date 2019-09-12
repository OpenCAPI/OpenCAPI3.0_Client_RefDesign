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

module mcp3_ohc03 (

  // -- input vector
    input           [2:0] one_hot_vector

  // -- encoded output select
  , output                one_hot_error

  );

  assign  one_hot_error =  ( one_hot_vector[2:0] == 3'b0 )            ||  // -- Error - No Bits Active
                           ( one_hot_vector[2] && one_hot_vector[1] ) ||  // -- Error - More than 1 Bit Active
                           ( one_hot_vector[2] && one_hot_vector[0] ) ||  // -- Error - More than 1 Bit Active
                           ( one_hot_vector[1] && one_hot_vector[0] );    // -- Error - More than 1 Bit Active

endmodule













































