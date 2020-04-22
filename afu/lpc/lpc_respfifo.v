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
// -------------------------------------------------------------------
//
// Title    : lpc_respfifo.v
// Function : This file contains a response buffer FIFO to buffer a number of responses and response data FLITs
//            to the TLX when using pipelined mode. The pipeline depth is much larger than the number of outstanding
//            response and response data credits provided by the TLX, so without this buffer operations complete
//            in bursts of 4 because they run out of TLX credits. By inserting the buffer at outgoing TLX interface, 
//            the round trip latency with the TLX is significantly reduced allowing TLX credits to "keep up" with 
//            pipelined data. The depth of the FIFO needs to be longer than the pipeline latency.
//
// -------------------------------------------------------------------
// Modification History :
//                               |Version    |     |Author   |Description of change
//                               |-----------|     |-------- |---------------------
  `define lpc_respfifo_VERSION   27_Feb_2017   //
// -------------------------------------------------------------------


// ==============================================================================================================================
// @@@  Module Declaration
// ==============================================================================================================================
module lpc_respfifo #(parameter integer WIDTH = 550) (
    input              clock                   // Clock - samples & launches data on rising edge
  , input              reset                   // When 1, reset registers to an empty FIFO state

  // Input into FIFO
  , input  [WIDTH-1:0] resp_in                 // Vector of command information to save
  , input              resp_in_valid           // When 1, load 'resp_in' into the FIFO
  , output [4:0]       resp_buffers_available  // Number of buffer slots available (1 buffer holds response and data FLIT (if used))

  // Output from FIFO
  , input              resp_sent               // When 1, increment read FIFO pointer to present the next FIFO entry
  , output [WIDTH-1:0] resp_out                // Command information at head of FIFO
  , output             resp_out_valid          // When 1, 'cmd_out' contains valid information
 
    // Error conditions
  , output             fifo_overflow           // When 1, error FIFO was full when another 'resp_valid' arrived
) ;


// ==============================================================================================================================
// @@@  Implement FIFO
// ==============================================================================================================================

reg [WIDTH-1:0] respfifo [15:0];   // 16 row array
//wire [WIDTH-1:0] resp_out_reg;      // Explicit register on output of array

reg       [3:0] wrptr;             // Write pointer into array, points to next free entry
reg       [3:0] rdptr;             // Read  pointer from array, points to oldest valid entry
reg      [15:0] respfifo_val;      // 1=associated entry is used, 0=associated entry is open and can be overwritten

// Manage write pointer
always @(posedge(clock))
  begin
    if (reset == 1'b1) 
      wrptr <= 4'b0000;                                      // Initialize to location 0
    else if (resp_in_valid == 1'b1 && wrptr != 4'b1111)   
      wrptr <= wrptr + 4'b0001;                              // Add an entry, so increment
    else if (resp_in_valid == 1'b1 && wrptr == 4'b1111)   
      wrptr <= 4'b0000;                                      // Add an entry, but wrap around to increment
    else
      wrptr <= wrptr;                                        // Hold value, nothing to load
  end

// Manage read pointer 
always @(posedge(clock))
  begin
    if (reset == 1'b1)
      rdptr <= 4'b0000;                                      // Initialize to location 0
    else if (resp_sent == 1'b1 && rdptr != 4'b1111)
      rdptr <= rdptr + 4'b0001;                              // Move to next location, this one is complete
    else if (resp_sent == 1'b1 && rdptr == 4'b1111)
      rdptr <= 4'b0000;                                      // Move to next location, but wrap around
    else
      rdptr <= rdptr;                                        // Hold value, no operation or operation is still in progress
  end

// Manage valid indicator
always @(posedge(clock))
  begin 
    if (reset == 1'b1)  
      respfifo_val <= 16'h0000;                                                     // Initialize to all 0, all rows are free
    else if (resp_in_valid == 1'b1 && resp_sent == 1'b0)  
      respfifo_val <= respfifo_val | (16'h0001 << wrptr);                           // When loading, set wrptr bit to 1
    else if (resp_in_valid == 1'b0 && resp_sent == 1'b1)
      respfifo_val <= respfifo_val & ~(16'h0001 << rdptr);                          // When done, set rdptr bit to 0 
    else if (resp_in_valid == 1'b1 && resp_sent == 1'b1)
      respfifo_val <= (respfifo_val | (16'h0001 << wrptr)) & ~(16'h0001 << rdptr);  // Both set and clear a bit 
    else
      respfifo_val <= respfifo_val;                                                 // Hold value if neither bit is set
  end

// Manage row contents
// Note: Contents of array row will be 'X' until written the first time, but this should be OK.
always @(posedge(clock)) begin
  if (resp_in_valid) respfifo[wrptr] <= resp_in;   // Use code format recommended by Vivado
end
//  respfifo[wrptr] <= (resp_in_valid == 1'b1) ? resp_in : respfifo[wrptr];  // Load or hold array row

// Manage data output and valid. If valid is not set, drive 0's which should decode to NOP.
// Note: DISTRIBUTED arrays do not latch the output.
// Provide data directly out of array (if timing permits) to align with changing of rdptr with respect to resp_sent
assign resp_out = (respfifo_val[rdptr] == 1'b1) ? respfifo[rdptr] : {WIDTH{1'b0}};  

// Provide data directly out of array (if timing permits) to align with changing of rdptr with respect to resp_sent
assign resp_out_valid = respfifo_val[rdptr];  


// Check for overflow
assign fifo_overflow   = (resp_in_valid == 1'b1 && respfifo_val == 16'hFFFF) ? 1'b1 : 1'b0;

// Determine number of available buffers
// Note: wrptr points to the next location to write (one past the last written entry)
//       rdptr points to the next valid location
reg [4:0] resp_buffers_used;
always @(*)   // Combinational
  if (respfifo_val == 16'h0000)               // Empty FIFO
    resp_buffers_used = 5'b00000; 
  else if (wrptr > rdptr)                     // Pointers are not wrapped with respect to each other
    resp_buffers_used = {1'b0,wrptr} - {1'b0,rdptr};      // Bit extension circumvents IBM 'tvc' tool warnings 
  else if (wrptr < rdptr)                     // Write pointer wrapped around
    resp_buffers_used = (5'b10000 + {1'b0,wrptr}) - {1'b0,rdptr};   
  else // wrptr == rdptr                      // Pointers are equal, but FIFO is not empty so it must be full
    resp_buffers_used = 5'b10000; 
assign resp_buffers_available = 5'b10000 - resp_buffers_used;

endmodule
