//-----------------------------------------------------------------------------
//
// (c) Copyright 2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//Author : 
// 
// Create Date:    110916 
// Design Name: 
// Module Name:    drp_read_modify_write.v - Behavioral 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:  Hierarchal block to modify GTX modes via DRP interface.  
//
//
//--------------------------------------------------------------------------------

`timescale 1ns / 1ps
`define DLY #1
module drp_read_modify_write
(
  input  wire        RESET,             //   
  input  wire        START,             // start rmw 
  output wire        DONE,              // rmw complete
  input  wire [9:0]  GT_DRP_ADDRESS,    // DRP register address to be nodified
  input  wire [15:0] GT_DRP_DI_MASK,    // Write data value/s  to drp
  input  wire [15:0] GT_DRP_DO_MASK,    // preserve rd data with a '1'  from drp
  output wire [9:0]  GT_DRPADDR,        // 
  output wire [15:0] GT_DI,             //
  output wire        GT_DEN,            //
  output wire        GT_DWE,            //
  input  wire        GT_DRDY,           //
  input  wire [15:0] GT_DO,             //
  input  wire        DCLK               //
);

  localparam [6:0] DRP_WAIT      = 7'd1;
  localparam [6:0] DRP_READ      = 7'd2;
  localparam [6:0] DRP_READ_ACK  = 7'd4;
  localparam [6:0] DRP_MODIFY    = 7'd8;
  localparam [6:0] DRP_WRITE     = 7'd16;
  localparam [6:0] DRP_WRITE_ACK = 7'd32;
  localparam [6:0] DRP_DONE      = 7'd64;
  

  reg [6:0] drp_state = 7'd1;
  reg [15:0] di;
  reg den = 1'b0;
  reg dwe = 1'b0;
  reg wr  = 1'b0;
  reg rd  = 1'b0;
  wire drp_done;
  wire [15:0] data_out;
  wire drdy;


  assign GT_DRPADDR =  GT_DRP_ADDRESS;
  assign GT_DI      =  di;
  assign GT_DEN     =  den;
  assign GT_DWE     =  dwe;
  assign drdy       =  GT_DRDY;
  assign data_out   =  GT_DO;
  assign DONE       =  drp_done;
  
  // Start read modify write cycle
  always @(posedge DCLK or posedge RESET) begin
    if (RESET) begin 
      wr <= `DLY 1'b0;
      rd <= `DLY 1'b0;
    end
    else if (START && !rd) begin
      rd <= `DLY 1'b1;
    end
    else begin 
     rd <= `DLY 1'b0;
    end
  end
        

  // DRP FSM
  always @(posedge DCLK or posedge RESET) begin
  if (RESET) begin
    den     <= `DLY 1'b0;
    dwe     <= `DLY 1'b0;
    di      <= `DLY 16'h0000;
    drp_state <= `DLY DRP_WAIT;
  end
  else begin
    case (drp_state)
        DRP_WAIT: begin
    if (wr | rd) drp_state <= `DLY DRP_READ;
    else         drp_state <= `DLY DRP_WAIT;
  end
  DRP_READ: begin
    den <= `DLY 1'b1;
    drp_state <= `DLY DRP_READ_ACK;
  end
  DRP_READ_ACK: begin
    den <= `DLY 1'b0;
    if (drdy == 1'b1) begin
      if (rd) drp_state <= `DLY DRP_DONE;
      else    drp_state <= `DLY DRP_MODIFY;
    end
    else      drp_state <= `DLY DRP_READ_ACK; 
  end
  DRP_MODIFY: begin
    di <= `DLY GT_DRP_DI_MASK | (data_out & GT_DRP_DO_MASK);
    drp_state <= `DLY DRP_WRITE;
  end
  DRP_WRITE: begin
    den <= `DLY 1'b1;
    dwe <= `DLY 1'b1;
    drp_state <= `DLY DRP_WRITE_ACK;
  end
  DRP_WRITE_ACK: begin
    den <= `DLY 1'b0;
    dwe <= `DLY 1'b0;
    if (drdy == 1'b1) drp_state <= `DLY DRP_DONE;
    else              drp_state <= `DLY DRP_WRITE_ACK;
  end
  DRP_DONE: begin
    drp_state <= `DLY DRP_WAIT;
  end
        default: drp_state <= `DLY DRP_WAIT;
    endcase
  end
  end

  assign drp_done = (drp_state == DRP_DONE);



endmodule //drp_read_modify_write
