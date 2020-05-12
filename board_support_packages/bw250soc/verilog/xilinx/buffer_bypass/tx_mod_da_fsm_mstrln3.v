//-----------------------------------------------------------------------------
//
// (c) Copyright 2017 Xilinx, Inc. All rights reserved.
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

// Design Name: 
// Module Name:    
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:  Hierarchal block to modify GTY modes via DRP interface.  
//
//
//--------------------------------------------------------------------------------

`timescale 1ns / 1ps
`define DLY #1

module tx_mod_da_fsm #(
  parameter NUM_LANES             = 8      // Number of data lane
)
(
  input  wire                     reset,
  input  wire                     set_initial_cfg,
  input  wire                     enable_txphydly_cfg,
  input  wire                     enable_txsyncovrd_buf_cfg,
  output reg                      initial_cfg_done =1'b1,
  output reg                      txphydly_cfg_done =1'b0, 
  output reg                      txsyncovrd_buf_cfg_done =1'b0,
  // DRP port interface,  
  output wire [NUM_LANES*10-1:0]  GT_DRPADDR,        // 
  output wire [NUM_LANES*16-1:0]  GT_DI,             //
  output wire [NUM_LANES -1:0]    GT_DEN,            //
  output wire [NUM_LANES -1:0]    GT_DWE,            //
  input  wire [NUM_LANES -1:0]    GT_DRDY,           //
  input  wire [NUM_LANES*16-1:0]  GT_DO,             //
  input  wire                     DCLK               //
);


/*
    Initial Configuration:
      TXPHDLY_CFG0[13] = 1   address = 0090  bit [13] = 1
      TXSYNC_OVRD = 1'b1     address = 008A  bit [13] = 1
      TXDLY_CFG = 16'h101f   address = 008E  = 16'h101f
      TXBUF_EN = 'TRUE'      address = 007C  BIT [7]  = 1
    Initial Inputs
      TXPHALIGNEN = 1'b0     Buffer Bypass input 
      TXDLYOVRDEN = 1'b1     Buffer Bypass input
    Tx Channel Reset
      After TXRESETDONE = 1
      TXDLYOVRDEN = 1'b0     Buffer Bypass input
    Tx Configuraton 
      TXPHDLY_CFG0[13] = 0   address = 0090  bit [13] = 0
      TXSYNC_OVRD = 1'b0     address = 008A  bit [13] = 0
      TXBUF_EN = 'FALSE'     address = 007C  BIT [7]  = 0
    TXDLYSRESET (USRCLK source lane followed by all other lanes).
     Wait for TXDLYSRESETDONE to go high.
*/ 


   localparam [4:0]IDLE                   = 5'd0; 
   localparam [4:0]INIT_TXPHDLY_CFG0      = 5'd1; 
   localparam [4:0]WAIT1                  = 5'd2; 
   localparam [4:0]INIT_TXSYNC_OVRD       = 5'd3; 
   localparam [4:0]WAIT2                  = 5'd4; 
   localparam [4:0]INIT_TXDLY_CFG         = 5'd5; 
   localparam [4:0]WAIT3                  = 5'd6; 
   localparam [4:0]INIT_TXBUF_EN          = 5'd7; 
   localparam [4:0]WAIT4                  = 5'd8; 
   localparam [4:0]INIT_DONE              = 5'd9; 
   localparam [4:0]TXPHDLY_CFG0           = 5'd10;
   localparam [4:0]WAIT5                  = 5'd11;
   localparam [4:0]TXPHDLY_CFG0_DONE      = 5'd12;
   localparam [4:0]TXSYNCOVRD_BUFEN       = 5'd13;
   localparam [4:0]WAIT6                  = 5'd14;
   localparam [4:0]SET_TXBUF_EN           = 5'd15;
   localparam [4:0]WAIT7                  = 5'd16;
   localparam [4:0]TXSYNCOVRD_BUFEN_DONE  = 5'd17;  
 
  reg  [4:0]               fsm_state                     =  IDLE;
  reg                      start_drprmw                  =  1'b0;
  reg                      init_cfg                      =  1'b0;
  reg                      set_initial_cfg_reg           =  1'b0;
  reg                      enable_txphydly_cfg_reg       =  1'b0;
  reg                      enable_txsyncovrd_buf_cfg_reg =  1'b0;
  reg                      reset_init_cfg                =  1'b0; 
  reg                      txphydly_cfg                  =  1'b0;
  reg                      txsyncovrd_buf_cfg            =  1'b0;
  reg                      reset_align_cfg               =  1'b0;
  reg                      reset_txsyncovrd_buf_cfg      =  1'b0;
  reg  [10-1:0]            drprmw_address                = 10'b0;
  reg  [16-1:0]            drprmw_di_mask                = 16'b0; 
  reg  [16-1:0]            drprmw_do_mask                = 16'b0;
  wire [NUM_LANES -1:0]    drprmw_done;
  wire [NUM_LANES -1:0]    den_rip;
  wire [NUM_LANES -1:0]    dwe_rip;
  
  // only enamle master lane
  assign GT_DEN = {1'b0,1'b0,1'b0,1'b0, den_rip[3],1'b0,1'b0,1'b0};
  assign GT_DWE = {1'b0,1'b0,1'b0,1'b0, dwe_rip[3],1'b0,1'b0,1'b0};
  // instanciate DRP RMW module
  genvar lanes;
  generate
    for (lanes=0; lanes < NUM_LANES; lanes=lanes+1)
    begin: GEN_GTY_LANE
    drp_read_modify_write drp_rmw_inst
    (
      .RESET            (reset),              //   
      .START            (start_drprmw),       // start rmw 
      .DONE             (drprmw_done[lanes]), // rmw complete
      .GT_DRP_ADDRESS   (drprmw_address),     // DRP register address to be nodified
      .GT_DRP_DI_MASK   (drprmw_di_mask),     // Write data value/s  to drp
      .GT_DRP_DO_MASK   (drprmw_do_mask),     // preserve rd data with a '1'  from drp
      // I/O to GTY DRP ports
      .GT_DRPADDR       (GT_DRPADDR[(lanes+1)*10-1:lanes*10]),    // 
      .GT_DI            (GT_DI[(lanes+1)*16-1:lanes*16]),         //
      //.GT_DEN           (GT_DEN[lanes]),                          //
      //.GT_DWE           (GT_DWE[lanes]),
      .GT_DEN           (den_rip[lanes]),                          //
      .GT_DWE           (dwe_rip[lanes]),                          //                                    //
      .GT_DRDY          (GT_DRDY[lanes]),                         //
      .GT_DO            (GT_DO[(lanes+1)*16-1:lanes*16]),         //
      .DCLK             (DCLK)                                    //
    );
  end 
  endgenerate


   
  begin                     
     always @(posedge DCLK)begin
      set_initial_cfg_reg            <= set_initial_cfg;
      enable_txphydly_cfg_reg        <= enable_txphydly_cfg;
      enable_txsyncovrd_buf_cfg_reg  <= enable_txsyncovrd_buf_cfg;
    end
  end
       
  begin
    always @(posedge DCLK)
    if (reset_init_cfg) begin
     init_cfg <= 1'b0;
    end 
    else if (set_initial_cfg == 1'b1 && set_initial_cfg_reg == 1'b0)begin
     init_cfg <=    1'b1;
    end 
    else begin
     init_cfg <= init_cfg;
    end
  end           

  begin
    always @(posedge DCLK)
    if (reset_align_cfg) begin
     txphydly_cfg <= 1'b0;
    end
    else if (enable_txphydly_cfg == 1'b1 && enable_txphydly_cfg_reg == 1'b0)begin
     txphydly_cfg <= 1'b1;
    end       
    else begin
     txphydly_cfg <= txphydly_cfg;
    end
  end                    
                         
  begin
    always @(posedge DCLK)
    if (reset_txsyncovrd_buf_cfg) begin
     txsyncovrd_buf_cfg <= 1'b0;
    end
    else if (enable_txsyncovrd_buf_cfg == 1'b1 && enable_txsyncovrd_buf_cfg_reg == 1'b0)begin
     txsyncovrd_buf_cfg <= 1'b1;
    end       
    else begin
     txsyncovrd_buf_cfg <= txsyncovrd_buf_cfg;
    end
  end   
 

                         
   always @(posedge DCLK)
      if (reset) begin
         fsm_state <= IDLE;
         //<outputs> <= <initial_values>;
         start_drprmw      <=    1'b0;
         initial_cfg_done  <=    1'b0;
         reset_init_cfg    <=    1'b0;
         txphydly_cfg_done  <=    1'b0;
         reset_align_cfg   <=    1'b0;
         drprmw_address    <=   10'b0;
         drprmw_di_mask    <=   16'b0;
         drprmw_do_mask    <=   16'b0;
      end
      else
         case (fsm_state)
            IDLE : begin
               if (init_cfg)
                  fsm_state <= INIT_TXPHDLY_CFG0;
               else if (txphydly_cfg)
                  fsm_state <= TXPHDLY_CFG0;
               else if (txsyncovrd_buf_cfg)
                  fsm_state <= TXSYNCOVRD_BUFEN;
               else
                  fsm_state <= IDLE;
               //<outputs> <= <values>;
               start_drprmw      <=    1'b0;
               //initial_cfg_done  <=    1'b0;
               //txphydly_cfg_done  <=    1'b0;
               drprmw_address    <=   10'b0;
               drprmw_di_mask    <=   16'b0;
               drprmw_do_mask    <=   16'b0;
            end
            INIT_TXPHDLY_CFG0 : begin
             fsm_state         <=    WAIT1;
             start_drprmw      <=    1'b1;
             txsyncovrd_buf_cfg_done    <=    1'b0;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h0090;
             drprmw_di_mask    <=   16'b0010_0000_0000_0000;
             drprmw_do_mask    <=   16'b1101_1111_1111_1111;
            end
            WAIT1 : begin
             start_drprmw      <=    1'b0;
             //if (&drprmw_done) begin
             if (|drprmw_done) begin   // just master lane is don          
                fsm_state <= INIT_TXSYNC_OVRD;
             end
             else
                fsm_state <= WAIT1;
             reset_init_cfg    <=    1'b1;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h0090;
             drprmw_di_mask    <=   16'b0010_0000_0000_0000;
             drprmw_do_mask    <=   16'b1101_1111_1111_1111;
            end            
            INIT_TXSYNC_OVRD : begin
             fsm_state         <=    WAIT2;
             reset_init_cfg    <=    1'b0;             
             start_drprmw      <=    1'b1;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h008A;
             drprmw_di_mask    <=   16'b0010_0000_0000_0000;
             drprmw_do_mask    <=   16'b1101_1111_1111_1111;
            end
            WAIT2 : begin
            start_drprmw      <=    1'b0;
             //if (&drprmw_done) begin
            if (|drprmw_done) begin   // just master lane is done  
                fsm_state <= INIT_TXDLY_CFG;
             end
             else 
             fsm_state         <=   WAIT2;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h008A;
             drprmw_di_mask    <=   16'b0010_0000_0000_0000;
             drprmw_do_mask    <=   16'b1101_1111_1111_1111;
            end                                
            INIT_TXDLY_CFG : begin
             fsm_state         <=    WAIT3;
             start_drprmw      <=    1'b1;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h008E;
             drprmw_di_mask    <=   16'h101f;
             drprmw_do_mask    <=   16'b0;
            end            
            WAIT3 : begin
             start_drprmw      <=    1'b0;
             //if (&drprmw_done) begin
             if (|drprmw_done) begin   // just master lane is done  
                fsm_state <= INIT_TXBUF_EN;
              end 
              else begin
             fsm_state         <= WAIT3;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h008E;
             drprmw_di_mask    <=   16'h101f;
             drprmw_do_mask    <=   16'b0;
              end
            end
            INIT_TXBUF_EN : begin
             fsm_state         <=    WAIT4;
             start_drprmw      <=    1'b1;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h007C;
             drprmw_di_mask    <=   16'b0000_0000_1000_0000;
             drprmw_do_mask    <=   16'b1111_1111_0111_1111;
            end
            WAIT4 : begin
             start_drprmw      <=    1'b0;
             //if (&drprmw_done) begin
             if (|drprmw_done) begin   // just master lane is done  
                fsm_state <= INIT_DONE;
              end              
             else begin
             fsm_state         <=   WAIT4;
             initial_cfg_done  <=    1'b0;               
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h007C;
             drprmw_di_mask    <=   16'b0000_0000_1000_0000;
             drprmw_do_mask    <=   16'b1111_1111_0111_1111;
              end
            end
            INIT_DONE : begin
             fsm_state         <=    IDLE;
             start_drprmw      <=    1'b0;
             initial_cfg_done  <=    1'b1;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'b0;
             drprmw_di_mask    <=   16'b0;
             drprmw_do_mask    <=   16'b0;
            end 
            
            
            
            TXPHDLY_CFG0 : begin
             fsm_state         <=    WAIT5;
             txsyncovrd_buf_cfg_done    <=    1'b0;
             start_drprmw      <=    1'b1;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h0090;               
             drprmw_di_mask    <=   16'b0000_0000_0000_0000;
             drprmw_do_mask    <=   16'b1101_1111_1111_1111;
            end
            WAIT5 : begin
             start_drprmw      <=    1'b0;
             //if (&drprmw_done) begin
             if (|drprmw_done) begin   // just master lane is done  
                //fsm_state <= TXSYNCOVRD_BUFEN;
                fsm_state <= TXPHDLY_CFG0_DONE;
                end
             else begin
             fsm_state         <=    WAIT5;
             reset_align_cfg   <=    1'b1;             
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h0090;
             drprmw_di_mask    <=   16'b0000_0000_0000_0000;
             drprmw_do_mask    <=   16'b1101_1111_1111_1111;
              end
            end
            
            TXPHDLY_CFG0_DONE:begin
             fsm_state                <=    IDLE;
             start_drprmw             <=    1'b0;
             reset_align_cfg          <=    1'b0;
             initial_cfg_done         <=    1'b0;
             txphydly_cfg_done        <=    1'b1;
             txsyncovrd_buf_cfg_done  <=    1'b0;
             drprmw_address           <=   10'b0;
             drprmw_di_mask           <=   16'b0;
             drprmw_do_mask           <=   16'b0; 
             end  
            
            TXSYNCOVRD_BUFEN : begin
             fsm_state                <=    WAIT6;
             reset_align_cfg          <=    1'b0;
             reset_txsyncovrd_buf_cfg <=    1'b1;            
             start_drprmw             <=    1'b1;
             txsyncovrd_buf_cfg_done  <=    1'b0;
             initial_cfg_done         <=    1'b0;
             txphydly_cfg_done        <=    1'b0;
             
             drprmw_address           <=   10'h008A;
             drprmw_di_mask           <=   16'b0000_0000_0000_0000;
             drprmw_do_mask           <=   16'b1101_1111_1111_1111;
            end
            WAIT6 : begin
             start_drprmw      <=    1'b0;
             reset_txsyncovrd_buf_cfg <=    1'b0; 
             //if (&drprmw_done) begin
             if (|drprmw_done) begin   // just master lane is done  
                fsm_state <=  SET_TXBUF_EN;
              end
             else begin
             fsm_state         <=    WAIT6;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h008A;
             drprmw_di_mask    <=   16'b0000_0000_0000_0000;
             drprmw_do_mask    <=   16'b1101_1111_1111_1111;
              end
            end
            SET_TXBUF_EN : begin
             fsm_state         <=    WAIT7;
             start_drprmw      <=    1'b1;
             initial_cfg_done  <=    1'b0;
             txphydly_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h007C;
             drprmw_di_mask    <=   16'b0000_0000_0000_0000;
             drprmw_do_mask    <=   16'b1111_1111_0111_1111;
            end
            WAIT7 : begin
             start_drprmw      <=    1'b0;
             //if (&drprmw_done) begin
             if (|drprmw_done) begin   // just master lane is done  
                fsm_state <= TXSYNCOVRD_BUFEN_DONE;
                end
             else begin
             fsm_state         <=    WAIT7;
             initial_cfg_done  <=    1'b0;
             drprmw_address    <=   10'h007C;
             drprmw_di_mask    <=   16'b0000_0000_0000_0000;
             drprmw_do_mask    <=   16'b1111_1111_0111_1111;
              end
            end
            TXSYNCOVRD_BUFEN_DONE : begin
             fsm_state                  <=    IDLE;
             start_drprmw               <=    1'b0;
             reset_align_cfg            <=    1'b0;
             initial_cfg_done           <=    1'b0;
             txphydly_cfg_done          <=    1'b0;
             txsyncovrd_buf_cfg_done    <=    1'b1;
             drprmw_address             <=   10'b0;
             drprmw_di_mask             <=   16'b0;
             drprmw_do_mask             <=   16'b0; 
             end           
            default: begin  // Fault Recovery
               fsm_state <= IDLE;
	    end
      endcase

endmodule