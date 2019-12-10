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
// Title    : lpc_bulk_mem.v
// Function : This file is the wrapper around the bulk memory option used by the LPC. The LPC may use one of a number 
//            of different solutions to implement bulk memory (i.e. latches, embedded block memory, DDR4 DRAM), but all
//            must conform to this interface to be used with the rest of the LPC design. (Note: timing differences in
//            read or write behavior not withstanding.) 
//            The interface is a native memory block interface, to allow for pipelined operation where read and write
//            operations occur back to back.
//            Inputs are registered before going into the array, and outputs are registered just after the array to
//            allow for maximum operational frequency.
//            To conform to the OpenCAPI AFU spec, memory addressing starts at 0 and increases in a contiguous block to 
//            the maximum implemented depth. The amount of memory available can vary implementation to implementation,  
//            but the width is fixed to 512 bits (64 Bytes) to match the size of one data flit. A one bit array 
//            acts as an extention of the data to indicate the entire FLIT contains 'bad data'.
//
// Usage notes:
// - When no write or read is requested, data output is set to the contents of last accessed memory location.
// - Read data will appear 2 cycles after pulsing the read enable (rden) signal.
// - On reads, 'addr', 'rdcnt' and 'rden' are captured by this logic so the caller can pulse them for 1 cycle.
// - Error detection signals can go on at any time, the appearance of any of them for one or more cycles should be 
//   treated as a fatal error as data corruption could have occurred.
// - A write operation is identified by a non-0 value on 'wren'.
// - A read  operation is identified by a 1 on 'rden'.
// - On writes, the expectation is the caller will write 1 FLIT at a time, providing the address and write enables for each FLIT.
//   No auto increment feature is available on writes.
// - On reads, the expectation is the caller will provide the starting address and count of number of FLITs to stream out
//   of the memory. This logic will take care of incrementing the address when multiple FLITs are requested.
// - Multi-FLIT read data will appear as a continous stream of FLITs, the caller must be able to accept all FLITs requested.
//
// ********************************************
// * The caller MUST adhere to the following: *
// ********************************************
// - No other operations (i.e. writes or different reads) should be started while a multi-FLIT read is underway.
// - It is an error to indicate both write and read at the same time (wren <> all 0 and rden = 1). If this happens, unpredictable
//   results will occur.
// - The caller is responsible for ensuring the combination of starting addr and number of FLITs does not exceed a 256 Byte boundary.
//   If this happens, the address may wrap beyond the boundary of implemented memory and unpredictable results can occur.
//
// -------------------------------------------------------------------
// Modification History :
//                               |Version    |     |Author   |Description of change
//                               |-----------|     |-------- |---------------------
  `define LPC_BULK_MEM_VERSION   01_May_2017   //
// -------------------------------------------------------------------


// ==============================================================================================================================
// @@@  Module Declaration
// ==============================================================================================================================
module lpc_bulk_mem (
    input          clock         // Clock - samples & launches data on rising edge
  , input          reset         // Reset - when 1 set control logic to default state
  , input   [63:0] addr          // BRAM select bit [13] + Address[12:0], selects the target row, [63:14] are present for future expansion
  , input   [63:0] wren          // Write enable[63:0], 1 bit per byte. When 1, appropriate byte on 'din' is written into array. When 0 implies read only.
  , input          rden          // Read enable, when 1 start reading data from the Bulk Memory starting from 'addr'
  , input    [1:0] rdcnt         // Read count, indicates how many FLITs to read from Bulk Memory (00=1, 01=2, 10=3, 11=4) when rden=1
  , input          din_bdi       // Data In Bad Data Indictor, when 1 data FLIT is marked as bad
  , input  [511:0] din           // Data In[ 511:0], data goes directly into array, loaded on next rising clock edge
  , output         dout_bdi      // Data Out Bad Data Indicator, when 1 data FLIT is marked as bad
  , output [511:0] dout          // Data Out[511:0], data from array is registered before presentation on Data Out
  , output         err_multiops  // Collision of write and read attempted at the same time. This should be treated as a fatal error.
  , output         err_boundary  // The combination of starting addr and number of FLITs exceeds the 256 Byte boundary.
  , output         err_internal  // An internal condition that should never happen occurred.
) ;


// ==============================================================================================================================
// @@@  Input / Output latches around the array
// ==============================================================================================================================

// For timing purposes, latch inputs into the array before presenting them to it.
reg    [1:0] flit_cnt_q;
reg   [63:0] addr_q;
reg          rden_q;
reg    [1:0] rdcnt_q;

reg   [63:0] wren_q;
reg          wren_bdi_q;
reg          din_bdi_q;
reg  [511:0] din_q;
always @(posedge(clock))
  begin
    // Manage address during reads
    if (reset == 1'b1)                                      // Set read control logic to default state
      begin                                           
        flit_cnt_q <= 2'b00;                                // Starting value is 00, so is ready for 1 FLIT read
        rden_q     <= 1'b0;                                 // Start in valid state so 'if' clauses evaluate correctly when reset goes away
        rdcnt_q    <= 2'b00;                                // Start in valid state so 'if' clauses evaluate correctly when reset goes away
        addr_q     <= 64'b0;                                // Any non-X value will do
      end
    // When a read is started, rden_q will now be 1 and held to 1 until all the FLITs have been sent.
    else if (rden_q == 1'b1 && flit_cnt_q == rdcnt_q)       // This is the last (or only) cycle of the read
      begin
        flit_cnt_q <= 2'b00;                                // Prepare for new operation (which could be read or write)
        rden_q     <= rden;                                 // This read is over, capture new operation (which may be back to back read)
        rdcnt_q    <= rdcnt;                                // This read is over, capture new operation (which may be back to back read)
        addr_q     <= addr;                                 // Let caller take control of addr on next cycle (in case of back to back ops)
      end
    else if (rden_q == 1'b1 && flit_cnt_q < rdcnt_q)        // In the middle of a read that isn't finished yet
      begin
        flit_cnt_q <= flit_cnt_q + 2'b01;                   // Bump FLIT offset for next cycle of read
        rden_q     <= 1'b1;                                 // Continue with read operation
        rdcnt_q    <= rdcnt_q;                              // Preserve rdcnt value that was captured when read was initiated
        addr_q     <= addr_q + 64'h0000_0000_0000_0001;     // Increment address to next FLIT location (remove tvc warning by giving all 14 bits)
      end
//  else if (rden_q == 1'b1 && flit_cnt_q > rdcnt_q)        // This should never happen!
    else                                                    // This is a write or no-op cycle
      begin                                           
        flit_cnt_q <= 2'b00;                                // Starting value is 00, so is ready for 1 FLIT read  
        rden_q     <= rden;                                 // Allow read control logic to detect a read operation from the caller
        rdcnt_q    <= rdcnt;                                // Capture rdcnt, which has valid value coincident with rden pulsing to 1
        addr_q     <= addr;                                 // Let caller take control of addr so next cycle can be nop, write, or start of read
      end

    // Write related inputs to the array use a simple latch and go directly to the array, since writes are always 1 cycle in duration
    wren_q     <= wren;
    wren_bdi_q <= (| wren);  // OR Reduce operator, output set to 1 if any bit is 1
    din_bdi_q  <= din_bdi;
    din_q      <= din;
  end

// Detect errors:
// a) write (wren <> 0s) and read (rden = 1) operations arrive at the same time
assign err_multiops = (rden == 1'b1 && wren != 64'b0) ? 1'b1 : 1'b0;

// b) starting addr + rdcnt crosses 256B boundary
assign err_boundary = (rden == 1'b1 && 
                        ( // rdcnt == 2'b00 can have any address, being 1 FLIT long
                          (rdcnt == 2'b01 && addr[0]   != 1'b0 ) ||  // 2 FLITs must start on even row
                          (rdcnt == 2'b10 && addr[1:0] != 2'b00) ||  // 3 or 4 FLITs must start at beginning of 256B block
                          (rdcnt == 2'b11 && addr[1:0] != 2'b00) )   
                      ) ? 1'b1 : 1'b0;

// c) flit_cnt_q > rdcnt_q
assign err_internal = (rden_q == 1'b1 && flit_cnt_q > rdcnt_q) ? 1'b1 : 1'b0;


// Use upper address bit(s) to select which BRAM to enable
wire enab_00;
wire enab_01;
assign enab_00 = !(addr_q[13]);  
assign enab_01 =   addr_q[13] ;
// When reading the array, data out appears on the clock after the read enable. 
// To properly select the data out between the arrays, create a delayed copy of the selection 'enab_*' signals as well.
reg  enab_00_q;
//g  enab_01_q;    // Currently not used
always @(posedge(clock))
  begin
    enab_00_q <= enab_00;
//  enab_01_q <= enab_01;
  end

// Use upper address bit(s) to select which BRAM to latch before driving back to caller
  wire [511:0] dout_ary_00;
  wire [511:0] dout_ary_01;
  wire         dout_bdi_00;
  wire         dout_bdi_01;
// (Primitives Output Register) Data out of array can go directly back to the caller. The array contains an output latch already.
// assign dout = dout_ary;
// (Core       Output Register) Data out of array can go directly back to the caller. The array contains an output latch already.
// assign dout = dout_ary;
// (no         output register) Use manual register on DOUT. Useful for pipelining commands though since ENAB=1 is not needed after read cmd cycle.
   reg  [511:0] dout_q;
   reg          dout_bdi_q;
   always @(posedge(clock))
     begin
       dout_q     <= (enab_00_q == 1'b1) ? dout_ary_00 : dout_ary_01 ;
       dout_bdi_q <= (enab_00_q == 1'b1) ? dout_bdi_00 : dout_bdi_01 ;
     end
   assign dout     = dout_q;
   assign dout_bdi = dout_bdi_q;
// Note: If array timing is an issue, move the MUX after registering dout_ary_00 and dout_ary_01 individually. But since this adds 
//       512 extra registers, I tried the MUX before the register first.


// ==============================================================================================================================
// @@@  Instances of Sub Modules
// ==============================================================================================================================

// Total memory = 1 MB, implemented as two 512 KB BRAM blocks of 8192 rows x 64 bytes each

`ifdef BEHARY
  bram_8192x512_noOutReg_beh              BRAM_00 ( // Hand coded behavior model that is Mesa compatible
`else
  bram_native_1P_noOutReg_8192x512_A      BRAM_00 ( // No output register selected. Use with manually added output register (1 cycle ENAB on read)
`endif
    .clka  ( clock           )  // clock
  , .ena   ( enab_00         )  // Enable, 1 = array will respond, 0 = array will not respond
  , .wea   ( wren_q          )  // Write enable[63:0], 1 bit per byte. When 1, appropriate byte on 'din' is written into array. When 0 implies read only.
  , .addra ( addr_q[12:0]    )  // Address[12:0]
  , .dina  ( din_q           )  // Data In[ 511:0], data goes directly into array, loaded on next rising clock edge
  , .douta ( dout_ary_00     )  // Data Out[511:0], data from array may or may not be registered before presentation on Data Out, depends on configuration
);

`ifdef BEHARY
  bram_8192x512_noOutReg_beh              BRAM_01 ( // Hand coded behavior model that is Mesa compatible
`else
  bram_native_1P_noOutReg_8192x512_A      BRAM_01 ( // No output register selected. Use with manually added output register (1 cycle ENAB on read)
`endif
    .clka  ( clock           )  // clock
  , .ena   ( enab_01         )  // Enable, 1 = array will respond, 0 = array will not respond
  , .wea   ( wren_q          )  // Write enable[63:0], 1 bit per byte. When 1, appropriate byte on 'din' is written into array. When 0 implies read only.
  , .addra ( addr_q[12:0]    )  // Address[12:0]
  , .dina  ( din_q           )  // Data In[ 511:0], data goes directly into array, loaded on next rising clock edge
  , .douta ( dout_ary_01     )  // Data Out[511:0], data from array may or may not be registered before presentation on Data Out, depends on configuration
);


// These arrays hold the 'bdi' bit associated with each FLIT

`ifdef BEHARY
  bram_8192x1_noOutReg_beh                BRAM_B00 ( // Hand coded behavior model that is Mesa compatible
`else
  bram_native_1P_noOutReg_8192x1_A        BRAM_B00 ( // No output register selected. Use with manually added output register (1 cycle ENAB on read)
`endif
    .clka  ( clock           )  // clock
  , .ena   ( enab_00         )  // Enable, 1 = array will respond, 0 = array will not respond
  , .wea   ( wren_bdi_q      )  // Write enable, When 1, 'din' is written into array. When 0 implies read only.
  , .addra ( addr_q[12:0]    )  // Address[12:0]
  , .dina  ( din_bdi_q       )  // Data In[ 0:0], data goes directly into array, loaded on next rising clock edge
  , .douta ( dout_bdi_00     )  // Data Out[0:0], data from array may or may not be registered before presentation on Data Out, depends on configuration
);

`ifdef BEHARY
  bram_8192x1_noOutReg_beh                BRAM_B01 ( // Hand coded behavior model that is Mesa compatible
`else
  bram_native_1P_noOutReg_8192x1_A        BRAM_B01 ( // No output register selected. Use with manually added output register (1 cycle ENAB on read)
`endif
    .clka  ( clock           )  // clock
  , .ena   ( enab_01         )  // Enable, 1 = array will respond, 0 = array will not respond
  , .wea   ( wren_bdi_q      )  // Write enable, When 1, 'din' is written into array. When 0 implies read only.
  , .addra ( addr_q[12:0]    )  // Address[12:0]
  , .dina  ( din_bdi_q       )  // Data In[ 0:0], data goes directly into array, loaded on next rising clock edge
  , .douta ( dout_bdi_01     )  // Data Out[0:0], data from array may or may not be registered before presentation on Data Out, depends on configuration
);

endmodule 
