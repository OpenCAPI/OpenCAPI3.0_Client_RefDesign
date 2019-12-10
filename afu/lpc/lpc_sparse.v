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
// Title    : lpc_sparse.v
// Function : This file contains a sparse address translation table, converting a larger physical address from the
//            TLX into a smaller address offset into the bulk memory which is contiguous. The intent is to allow
//            the user (simulation or lab testing) to have the illusion of having a full OpenCAPI AFU address space
//            while physically implementing a much smaller amount of memory that is containable in an FPGA.
//
// -------------------------------------------------------------------
// Modification History :
//                               |Version    |     |Author   |Description of change
//                               |-----------|     |-------- |---------------------
  `define LPC_SPARSE_VERSION     05_Jan_2018   //
// -------------------------------------------------------------------
// Notes:
// 
// -------------------------------------------------------------------


// ==============================================================================================================================
// @@@  Module Declaration
// ==============================================================================================================================
module lpc_sparse (
    input          clock             // Clock - samples & launches data on rising edge
  , input          reset             // When 1, clear all cross reference logic to the 'unallocated' state
  , input          sam_enable        // When 1, accept a new addr_in and map it. When 0, do nothing with the addr_in.
  , input  [63:8]  sam_addr_in       // The upper physical address bits to cross reference, which come from the TLX 
                                     // Note: Odd bit index helps keep bit alignment with command address of [63:0]
  , output [11:0]  sam_addr_out      // The cross referenced bits, which go to the bulk memory (width determined by size of bulk memory)
  , output  [4:0]  sam_entries_open  // Number of cross reference entries that remain unused (width determined by NUM_ENTRIES)
  , output         sam_overflow      // Set to 1 when too many different physical addresses are requested (no more cross reference entries left)
  , output         sam_no_match      // Set to 1 when a match was not found, meaning a read was tried to an undefined address. Write it before reading.
  , input          sam_disable       // When 1, SAM does no mapping and just passes addresses through unchanged
) ;

// ==============================================================================================================================
// @@@  Register inputs and outputs 
// ==============================================================================================================================

// Run input directly into a register so we have a full cycle to do look up
reg [63:8] addr_in;
reg        enable;
reg        disabl;   // disable is a Verilog keyword
always @(posedge(clock))
  begin
    addr_in <= sam_addr_in;
    enable  <= sam_enable;
    disabl  <= sam_disable;
  end

// Run outputs into registers so we have a full cycle downstream to use it
wire [11:0] addr_out;
wire [11:0] passthru_addr_out;
reg  [11:0] addr_out_q;
always @(posedge(clock))
  addr_out_q     <= (disabl == 1'b0) ? addr_out : passthru_addr_out;   // Choose between mapping or no mapping
assign sam_addr_out = addr_out_q;

wire [4:0] entries_open;
reg  [4:0] entries_open_q;
always @(posedge(clock))
  entries_open_q <= (disabl == 1'b0) ? entries_open : 5'b11111;        // If disabled, all entries are open
assign sam_entries_open = entries_open_q;

wire overflow;
reg  overflow_q;
always @(posedge(clock))
  overflow_q     <= (disabl == 1'b0) ? overflow : 1'b0;                // If disabled, will never have an overflow
assign sam_overflow = overflow_q;

wire no_match;
reg  no_match_q;
always @(posedge(clock))
  no_match_q <= (disabl == 1'b0) ? no_match : 1'b0;                // If disabled, always have a match

assign sam_no_match = no_match_q;


// ==============================================================================================================================
// @@@  Perform look up - no mapping (pass through)
// ==============================================================================================================================

// Pass address input to output, making bulk memory a contiguous block of storage
assign passthru_addr_out = addr_in[19:8];   


// ==============================================================================================================================
// @@@  Helper function (remove Portals warning)
// ==============================================================================================================================
// The IBM compile flow for Verilog uses Portals, which throws warnings if integers are truncated or signals extended to match
// bit sizes. To avoid masking other important warnings, it is desired to remove these by making a special function to return the
// proper number of bits when converting the 'genvar' integer (32 bits) into the index number of the mapping entry (5 bits).
//
// IMPORTANT! Function is defined for integer values 0-31, adjust if other sizes are needed.
//
function [4:0] int_to_bits (input integer i);
  reg [31:0] temp;
  begin
    temp = i;                 // Convert integer into a 32 bit vector, should not throw a warning since both are the same size
    int_to_bits = temp[4:0];  // Return the desired number of bits from the vector
  end
endfunction


// ==============================================================================================================================
// @@@  Perform look up - mapping
// ==============================================================================================================================
// Note: The code below is only partially parameterized. To make it fully parameterizable, the size of the input address field
//       used by the mapping registers would need to vary, as would the bit width of the index number of each mapping entry.
//       If I could have figured out a good way to make the 'index OR gate' parameterizable, I might have completed this 
//       but since I couldn't I only did it part way (leaving NUM_ENTRIES which came in useful during implementation experiments).

//32 parameter NUM_ENTRIES = 32;        // Number of mapping entry copies (4096 max, coming from the size of bulk memory)
parameter NUM_ENTRIES = 16;        // Number of mapping entry copies (4096 max, coming from the size of bulk memory)

// Each entry gets these signals. 'maddr' and 'inuse' are stored values, 'index' and 'match' are combinational
//32 reg  [41:15] maddr_q [NUM_ENTRIES-1:0]; // Mapped Address - reg holds the incoming address bits associated with the entry
reg  [41:16] maddr_q [NUM_ENTRIES-1:0]; // Mapped Address - reg holds the incoming address bits associated with the entry
reg          inuse_q [NUM_ENTRIES-1:0]; // In Use - when 1, means entry has been used. 0 means entry is unassigned
wire [NUM_ENTRIES-1:0] match_x ; // Match - set to 1 when the maddr_q value matches the incoming address (cannot be array if using OR_REDUCE)

// Note: Width of the next signals is chosen to match width of 'sam_addr_out'
//32 reg    [5:0] next_free_entry_q;         // Pointer to the next free entry 
//32 wire   [4:0] index;                     // Summary index value, combined from individual entries
//32 parameter   FIRST_ENTRY = 5'b00000;     // Reset makes this the first entry (all 0's)
//32 parameter   MAX_ENTRY   = 5'b11111;     // Assign value of last entry (all 1's) 
reg    [4:0] next_free_entry_q;         // Pointer to the next free entry 
wire   [3:0] index;                     // Summary index value, combined from individual entries
parameter   FIRST_ENTRY = 4'b0000;      // Reset makes this the first entry (all 0's)
parameter   MAX_ENTRY   = 4'b1111;      // Assign value of last entry (all 1's) 

wire        match;                      // Summary match signal, combined from individual entries

// Generate combinational signals for each entry.
// match - Set to 1 if looking for a match (enable=1), incoming address matches stored address, and entry is valid
genvar i;
generate
  for (i=0; i <=NUM_ENTRIES-1; i=i+1) begin: GEN_MATCHES
//32 assign match_x[i] = (enable == 1'b1 && addr_in[41:15] == maddr_q[i] && inuse_q[i] == 1'b1) ? 1'b1 : 1'b0;
    assign match_x[i] = (enable == 1'b1 && addr_in[41:16] == maddr_q[i] && inuse_q[i] == 1'b1) ? 1'b1 : 1'b0;
  end
endgenerate

// Check for match across all the entries
assign match = (| match_x[NUM_ENTRIES-1:0]);   // OR Reduce match bits down to a single signal

// Convert 1 hot vector to encoded value
//32 wire [31:0] m;  // short hand
wire [NUM_ENTRIES-1:0] m;  // short hand
assign m = match_x;
//32 assign index[4] = (| {m[31:16]} );
//32 assign index[3] = (| {m[31:24],m[15:8]} );
//32 assign index[2] = (| {m[31:28],m[23:20],m[15:12],m[7:4]} );
//32 assign index[1] = (| {m[31:30],m[27:26],m[23:22],m[19:18],m[15:14],m[11:10],m[7:6],m[3:2]} );
//32 assign index[0] = (| {m[31],m[29],m[27],m[25],m[23],m[21],m[19],m[17],m[15],m[13],m[11],m[9],m[7],m[5],m[3],m[1]} );
assign index[3] = (| {m[15:8]} );
assign index[2] = (| {m[15:12],m[7:4]} );
assign index[1] = (| {m[15:14],m[11:10],m[7:6],m[3:2]} );
assign index[0] = (| {m[15],m[13],m[11],m[9],m[7],m[5],m[3],m[1]} );


// Determine address to send to bulk memory. 
// If match was found, send its index. If no match found, send index of next free entry which will contain the searched address
//32 assign addr_out[11:7] = (match == 1'b1) ? index : next_free_entry_q[4:0];  
assign addr_out[11:8] = (match == 1'b1) ? index : next_free_entry_q[3:0]; 
assign addr_out[   7] = addr_in[15]; 
assign addr_out[ 6:0] = addr_in[14:8];

// Keep track of next free entry
always @(posedge(clock))
  if (reset == 1'b1 || disabl == 1'b1)           // Use 'disable' to prevent mapping overflows when SAM is disabled (always overwrite location 0)
    next_free_entry_q <= {1'b0,FIRST_ENTRY};     // Start with location 0. Include extra bit to allow for overflow detection.
  else if (enable == 1'b1 && match == 1'b1)
    next_free_entry_q <= next_free_entry_q;      // If match is found, make no change to pointer
  else if (enable == 1'b1 && next_free_entry_q <= {1'b0,MAX_ENTRY} )
//32 next_free_entry_q <= next_free_entry_q + 6'b000001;  // If no match found and not full, increment pointer
    next_free_entry_q <= next_free_entry_q + 5'b00001;  // If no match found and not full, increment pointer
  else 
    next_free_entry_q <= next_free_entry_q;      // Either not enabled or all entries are full

// Check for overflow - happens when all entries are full and get a no match condition
assign overflow = (enable == 1'b1 && match == 1'b0 && next_free_entry_q > {1'b0,MAX_ENTRY}) ? 1'b1 : 1'b0;

// Manage mapping entry contents
generate
  for (i=0; i <=NUM_ENTRIES-1; i=i+1) begin: GEN_ENTRIES
    always @(posedge(clock))
      if (reset == 1'b1)
        begin
//32      maddr_q[i] <= 27'b0;
          maddr_q[i] <= 26'b0;
          inuse_q[i] <= 1'b0;
        end
      else if (enable == 1'b1 && match == 1'b0 && next_free_entry_q[4:0] == int_to_bits(i) )
        // If no match found and not full, save the address in the next free location
        begin
//32      maddr_q[i] <= addr_in[41:15];            // Assign this entry to the search address
          maddr_q[i] <= addr_in[41:16];            // Assign this entry to the search address
          inuse_q[i] <= 1'b1;                      // Indicate it is now used
        end
      else
        begin
          maddr_q[i] <= maddr_q[i];
          inuse_q[i] <= inuse_q[i];
        end
  end
endgenerate

// Provide status indicators as outputs. If all entries are full (check only last one), return 0. Otherwise return remaining open ones.
//32 assign entries_open = (inuse_q[31] == 1'b1) ? 5'b00000 : (MAX_ENTRY - next_free_entry_q[4:0]); 
assign entries_open = (inuse_q[15] == 1'b1) ? 5'b00000 : {1'b0,(MAX_ENTRY - next_free_entry_q[3:0])} ; 

assign no_match = ~(match);


endmodule
