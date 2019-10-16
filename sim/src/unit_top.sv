//
// Copyright 2018 International Business Machines
//
// Licensed under the Apache License, Version 2.0 (the "License");(),
// you may not use this file except in compliance with the License.(),
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0(),
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.(),
// See the License for the specific language governing permissions and
// limitations under the License.(),
//

// This is the top file for simulation.(),
// It's different to hardware/oc-bip/board_support_packages/${FPGA_CARD}/verilog/oc_fpga_top.v(),
//  1) Please pay attention to the name of clocks: tlx_clock and afu_clock
//     They are named as clock_tlx/afu in oc_fpga_top.v(),
//     But here they come from ocse afu_driver
//  2) Reset is also generated here just for simulation.(),

`timescale 1ns / 10ps
    // Include verification files
    `include "../../sim/unit_verif/env/action_tb_pkg.svh"
`define FLASH

module unit_top (
    output          breakpoint
);

//**********************************************
// CLOCK & RESET
//**********************************************
parameter        RESET_CYCLES = 9;
integer          resetCnt;
reg              clock_400m;
reg              clock_200m;
reg              reset;

initial begin
    clock_400m   <= 0;
    clock_200m   <= 0;
    reset        <= 1;
    resetCnt     = 0;
end

always begin
    clock_400m = !clock_400m; #1.25;
end
always begin
    clock_200m = !clock_200m; #2.5;
end
always @ (clock_400m) begin
    if(resetCnt < 30)
        resetCnt = resetCnt + 1;
end
always @ (clock_400m) begin
    if(resetCnt < RESET_CYCLES)
        reset = 1'b1;
    else
        reset = 1'b0;
end

//**********************************************
// HDL DESIGN
//**********************************************
oc_fpga_top dut0 (
   .ocde()
   ,.freerun_clk_p()
   ,.freerun_clk_n()

   ,.ch0_gtytxn_out()
   ,.ch0_gtytxp_out()
   ,.ch1_gtytxn_out()
   ,.ch1_gtytxp_out()
   ,.ch2_gtytxn_out()
   ,.ch2_gtytxp_out()
   ,.ch3_gtytxn_out()
   ,.ch3_gtytxp_out()
   ,.ch4_gtytxn_out()
   ,.ch4_gtytxp_out()
   ,.ch5_gtytxn_out()
   ,.ch5_gtytxp_out()
   ,.ch6_gtytxn_out()
   ,.ch6_gtytxp_out()
   ,.ch7_gtytxn_out()
   ,.ch7_gtytxp_out()

   ,.ch0_gtyrxn_in()
   ,.ch0_gtyrxp_in()
   ,.ch1_gtyrxn_in()
   ,.ch1_gtyrxp_in()
   ,.ch2_gtyrxn_in()
   ,.ch2_gtyrxp_in()
   ,.ch3_gtyrxn_in()
   ,.ch3_gtyrxp_in()
   ,.ch4_gtyrxn_in()
   ,.ch4_gtyrxp_in()
   ,.ch5_gtyrxn_in()
   ,.ch5_gtyrxp_in()
   ,.ch6_gtyrxn_in()
   ,.ch6_gtyrxp_in()
   ,.ch7_gtyrxn_in()
   ,.ch7_gtyrxp_in()

   ,.mgtrefclk1_x0y0_p()
   ,.mgtrefclk1_x0y0_n()
   ,.mgtrefclk1_x0y1_p()
   ,.mgtrefclk1_x0y1_n()
`ifdef FLASH
   ,.FPGA_FLASH_CE2_L()
   ,.FPGA_FLASH_DQ4()
   ,.FPGA_FLASH_DQ5()
   ,.FPGA_FLASH_DQ6()
   ,.FPGA_FLASH_DQ7()
`endif
  );
  
assign                             dut0.bsp.clock_tlx = clock_400m;
assign                             dut0.bsp.clock_afu = clock_200m;
//assign                             dut0.reset = reset;

`ifndef ENABLE_ODMA_ST_MODE
    //**********************************************
    // MM AXI INTERFACE FOR VERIF
    //**********************************************
    /**************** Write Address Channel Signals ****************/
    wire                               mm_axi_clk;
    wire                               mm_axi_rstn;
    wire [64-1:0]                      mm_axi_awaddr;
    wire [3-1:0]                       mm_axi_awprot;
    wire                               mm_axi_awvalid;
    wire                               mm_axi_awready;
    wire [3-1:0]                       mm_axi_awsize;
    wire [2-1:0]                       mm_axi_awburst;
    wire [4-1:0]                       mm_axi_awcache;
    wire [8-1:0]                       mm_axi_awlen;
    wire [1-1:0]                       mm_axi_awlock;
    wire [4-1:0]                       mm_axi_awqos;
    wire [4-1:0]                       mm_axi_awregion;
    wire [5-1:0]                       mm_axi_awid;
    wire [9-1:0]                       mm_axi_awuser;
    /**************** Write Data Channel Signals ****************/
    wire [`AXI_MM_DW-1:0]              mm_axi_wdata;
    wire [`AXI_MM_DW/8-1:0]            mm_axi_wstrb;
    wire                               mm_axi_wvalid;
    wire                               mm_axi_wready;
    wire                               mm_axi_wlast;
    wire [1-1:0]                       mm_axi_wuser;
    /**************** Write Response Channel Signals ****************/
    wire [2-1:0]                       mm_axi_bresp;
    wire                               mm_axi_bvalid;
    wire                               mm_axi_bready;
    wire [8-1:0]                       mm_axi_bid;
    wire [1-1:0]                       mm_axi_buser;
    /**************** Read Address Channel Signals ****************/
    wire [64-1:0]                      mm_axi_araddr;
    wire [3-1:0]                       mm_axi_arprot;
    wire                               mm_axi_arvalid;
    wire                               mm_axi_arready;
    wire [3-1:0]                       mm_axi_arsize;
    wire [2-1:0]                       mm_axi_arburst;
    wire [4-1:0]                       mm_axi_arcache;
    wire [1-1:0]                       mm_axi_arlock;
    wire [8-1:0]                       mm_axi_arlen;
    wire [4-1:0]                       mm_axi_arqos;
    wire [4-1:0]                       mm_axi_arregion;
    wire [8-1:0]                       mm_axi_arid;
    wire [9-1:0]                       mm_axi_aruser;
    /**************** Read Data Channel Signals ****************/
    wire [`AXI_MM_DW-1:0]              mm_axi_rdata;
    wire [2-1:0]                       mm_axi_rresp;
    wire                               mm_axi_rvalid;
    wire                               mm_axi_rready;
    wire                               mm_axi_rlast;
    wire [8-1:0]                       mm_axi_rid;
    wire [1-1:0]                       mm_axi_ruser;
`else
    wire                               h2a_axis_tready     ,
    wire                               h2a_axis_tlast      ,
    wire [AXI_ST_DW - 1:0]             h2a_axis_tdata      ,
    wire [AXI_ST_DW/8 - 1:0]           h2a_axis_tkeep      ,
    wire                               h2a_axis_tvalid     ,
    wire [AXI_ST_USER - 1:0]           h2a_axis_tuser      ,
    wire                               a2h_axis_tready     ,
    wire                               a2h_axis_tlast      ,
    wire [AXI_ST_DW - 1:0]             a2h_axis_tdata      ,
    wire [AXI_ST_DW/8 - 1:0]           a2h_axis_tkeep      ,
    wire                               a2h_axis_tvalid     ,
    wire [AXI_ST_USER - 1:0]           a2h_axis_tuser      ,
`endif

/**************** AXI Lite Signals ****************/
wire                               axi_lite_arvalid;      
wire [32-1:0]                      axi_lite_araddr ;         
wire                               axi_lite_arready;
wire                               axi_lite_rvalid;         
wire [32-1:0]                      axi_lite_rdata ;         
wire [   1:0]                      axi_lite_rresp ;          
wire                               axi_lite_rready;
wire                               axi_lite_awvalid;        
wire  [32-1:0]                     axi_lite_awaddr ;         
wire                               axi_lite_awready;
wire                               axi_lite_wvalid ;         
wire  [32-1:0]                     axi_lite_wdata  ;          
wire  [ 4-1:0]                     axi_lite_wstrb  ;          
wire                               axi_lite_wready ;
wire                               axi_lite_bvalid;        
wire [1:0]                         axi_lite_bresp ;          
wire                               axi_lite_bready;

assign                             mm_axi_clk = clock_200m;
assign                             mm_axi_rstn = dut0.oc_func.fw_afu.action_w.ap_rst_n;

`ifndef ENABLE_ODMA
// AXI write resquest channel
assign                             mm_axi_awid     = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awid;
assign                             mm_axi_awuser   = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awuser;
assign                             mm_axi_awaddr   = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awaddr;
assign                             mm_axi_awlen    = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awlen;
assign                             mm_axi_awsize   = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awsize;
assign                             mm_axi_awburst  = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awburst;
assign                             mm_axi_awlock   = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awlock;
assign                             mm_axi_awcache  = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awcache;
assign                             mm_axi_awprot   = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awprot;
assign                             mm_axi_awregion = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awregion;
assign                             mm_axi_awqos    = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awqos;
assign                             mm_axi_awvalid  = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awvalid;
assign                             mm_axi_awready  = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_awready;
assign                             mm_axi_wdata    = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wdata;
assign                             mm_axi_wstrb    = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wstrb;
assign                             mm_axi_wlast    = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wlast;
assign                             mm_axi_wvalid   = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wvalid;
assign                             mm_axi_wuser    = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wuser;
assign                             mm_axi_wready   = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_wready;
// AXI write response channel
assign                             mm_axi_bready   = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_bready;
assign                             mm_axi_bid      = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_bid;
assign                             mm_axi_buser    = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_buser;
assign                             mm_axi_bresp    = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_bresp;
assign                             mm_axi_bvalid   = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_bvalid;
// AXI read response channel
assign                             mm_axi_arid     = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arid;
assign                             mm_axi_aruser   = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_aruser;
assign                             mm_axi_araddr   = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_araddr;
assign                             mm_axi_arlen    = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arlen;
assign                             mm_axi_arsize   = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arsize;
assign                             mm_axi_arburst  = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arburst;
assign                             mm_axi_arlock   = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arlock;
assign                             mm_axi_arcache  = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arcache;
assign                             mm_axi_arprot   = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arprot;
assign                             mm_axi_arregion = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arregion;
assign                             mm_axi_arqos    = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arqos;
assign                             mm_axi_arvalid  = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arvalid;
assign                             mm_axi_arready  = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_arready;
// AXI read data channel
assign                             mm_axi_rready   = dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_rready;
assign                             mm_axi_rid      = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rid;
assign                             mm_axi_ruser    = 0;// = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_ruser;
assign                             mm_axi_rdata    = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rdata;
assign                             mm_axi_rresp    = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rresp;
assign                             mm_axi_rlast    = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rlast;
assign                             mm_axi_rvalid   = dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rvalid;
//AXI Lite Signals
assign                             axi_lite_arvalid= dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_arvalid;      
assign                             axi_lite_araddr = dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_araddr ;         
assign                             axi_lite_arready= dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_arready;	
assign                             axi_lite_rvalid = dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_rvalid;         
assign                             axi_lite_rdata  = dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_rdata;         
assign                             axi_lite_rresp  = dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_rresp;          
assign                             axi_lite_rready = dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_rready;
assign                             axi_lite_awvalid= dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_awvalid;        
assign                             axi_lite_awaddr = dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_awaddr;         
assign                             axi_lite_awready= dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_awready;
assign                             axi_lite_wvalid = dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_wvalid;         
assign                             axi_lite_wdata  = dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_wdata;          
assign                             axi_lite_wstrb  = dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_wstrb;          
assign                             axi_lite_wready = dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_wready;
assign                             axi_lite_bvalid = dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_bvalid;        
assign                             axi_lite_bresp  = dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_bresp;          
assign                             axi_lite_bready = dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_bready;


`else
    `ifndef ENABLE_ODMA_ST_MODE
    // AXI write resquest channel
        assign                             mm_axi_awid     = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awid;
        assign                             mm_axi_awuser   = 0; // = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awuser;
        assign                             mm_axi_awaddr   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awaddr;
        assign                             mm_axi_awlen    = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awlen;
        assign                             mm_axi_awsize   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awsize;
        assign                             mm_axi_awburst  = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awburst;
        assign                             mm_axi_awlock   = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awlock;
        assign                             mm_axi_awcache  = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awcache;
        assign                             mm_axi_awprot   = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awprot;
        assign                             mm_axi_awregion = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awregion;
        assign                             mm_axi_awqos    = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awqos;
        assign                             mm_axi_awvalid  = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awvalid;
        assign                             mm_axi_awready  = dut0.oc_func.fw_afu.snap_core_i.axi_mm_awready;
        assign                             mm_axi_wdata    = dut0.oc_func.fw_afu.snap_core_i.axi_mm_wdata;
        assign                             mm_axi_wstrb    = dut0.oc_func.fw_afu.snap_core_i.axi_mm_wstrb;
        assign                             mm_axi_wlast    = dut0.oc_func.fw_afu.snap_core_i.axi_mm_wlast;
        assign                             mm_axi_wvalid   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_wvalid;
        assign                             mm_axi_wuser    = 1'b0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_wuser;
        assign                             mm_axi_wready   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_wready;
        // AXI write response channel
        assign                             mm_axi_bready   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_bready;
        assign                             mm_axi_bid      = dut0.oc_func.fw_afu.snap_core_i.axi_mm_bid;
        assign                             mm_axi_buser    = 1'b0;//= dut0.oc_func.fw_afu.snap_core_i.axi_mm_buser;
        assign                             mm_axi_bresp    = dut0.oc_func.fw_afu.snap_core_i.axi_mm_bresp;
        assign                             mm_axi_bvalid   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_bvalid;
        // AXI read response channel
        assign                             mm_axi_arid     = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arid;
        assign                             mm_axi_aruser   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_aruser;
        assign                             mm_axi_araddr   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_araddr;
        assign                             mm_axi_arlen    = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arlen;
        assign                             mm_axi_arsize   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arsize;
        assign                             mm_axi_arburst  = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arburst;
        assign                             mm_axi_arlock   = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arlock;
        assign                             mm_axi_arcache  = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arcache;
        assign                             mm_axi_arprot   = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arprot;
        assign                             mm_axi_arregion = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arregion;
        assign                             mm_axi_arqos    = 0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arqos;
        assign                             mm_axi_arvalid  = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arvalid;
        assign                             mm_axi_arready  = dut0.oc_func.fw_afu.snap_core_i.axi_mm_arready;
        // AXI read data channel
        assign                             mm_axi_rready   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_rready;
        assign                             mm_axi_rid      = dut0.oc_func.fw_afu.snap_core_i.axi_mm_rid;
        assign                             mm_axi_ruser    = 1'b0;// = dut0.oc_func.fw_afu.snap_core_i.axi_mm_ruser;
        assign                             mm_axi_rdata    = dut0.oc_func.fw_afu.snap_core_i.axi_mm_rdata;
        assign                             mm_axi_rresp    = dut0.oc_func.fw_afu.snap_core_i.axi_mm_rresp;
        assign                             mm_axi_rlast    = dut0.oc_func.fw_afu.snap_core_i.axi_mm_rlast;
        assign                             mm_axi_rvalid   = dut0.oc_func.fw_afu.snap_core_i.axi_mm_rvalid;
    `else
        assign                             h2a_axis_tready = dut0.oc_func.fw_afu.snap_core_i.m_axis_tready;
        assign                             h2a_axis_tlast  = dut0.oc_func.fw_afu.snap_core_i.m_axis_tlast;
        assign                             h2a_axis_tdata  = dut0.oc_func.fw_afu.snap_core_i.m_axis_tdata;
        assign                             h2a_axis_tkeep  = dut0.oc_func.fw_afu.snap_core_i.m_axis_tkeep;
        assign                             h2a_axis_tvalid = dut0.oc_func.fw_afu.snap_core_i.m_axis_tvalid;
        assign                             h2a_axis_tuser  = dut0.oc_func.fw_afu.snap_core_i.m_axis_tuser;
        assign                             a2h_axis_tready = dut0.oc_func.fw_afu.snap_core_i.s_axis_tready;
        assign                             a2h_axis_tlast  = dut0.oc_func.fw_afu.snap_core_i.s_axis_tlast;
        assign                             a2h_axis_tdata  = dut0.oc_func.fw_afu.snap_core_i.s_axis_tdata;
        assign                             a2h_axis_tkeep  = dut0.oc_func.fw_afu.snap_core_i.s_axis_tkeep;
        assign                             a2h_axis_tvalid = dut0.oc_func.fw_afu.snap_core_i.s_axis_tvalid;
        assign                             a2h_axis_tuser  = dut0.oc_func.fw_afu.snap_core_i.s_axis_tuser;
    `endif
//AXI Lite Signals
assign                             axi_lite_arvalid= dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_arvalid;      
assign                             axi_lite_araddr = dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_araddr ;         
assign                             axi_lite_arready= dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_arready;
assign                             axi_lite_rvalid = dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_rvalid;         
assign                             axi_lite_rdata  = dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_rdata;         
assign                             axi_lite_rresp  = dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_rresp;          
assign                             axi_lite_rready = dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_rready;
assign                             axi_lite_awvalid= dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_awvalid;        
assign                             axi_lite_awaddr = dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_awaddr;         
assign                             axi_lite_awready= dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_awready;
assign                             axi_lite_wvalid = dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_wvalid;         
assign                             axi_lite_wdata  = dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_wdata;          
assign                             axi_lite_wstrb  = dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_wstrb;          
assign                             axi_lite_wready = dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_wready;
assign                             axi_lite_bvalid = dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_bvalid;        
assign                             axi_lite_bresp  = dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_bresp;          
assign                             axi_lite_bready = dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_bready;

`endif

`ifndef ENABLE_ODMA_ST_MODE
    axi_vip_mm_check mm_check_passthrough(
        .aclk                  (mm_axi_clk),
        .aresetn               (mm_axi_rstn),
        // AXI write address channel
        .s_axi_awid            (mm_axi_awid),
        .s_axi_awaddr          (mm_axi_awaddr),
        .s_axi_awlen           (mm_axi_awlen),
        .s_axi_awsize          (mm_axi_awsize),
        .s_axi_awburst         (mm_axi_awburst),
        .s_axi_awlock          (mm_axi_awlock),
        .s_axi_awcache         (mm_axi_awcache),
        .s_axi_awprot          (mm_axi_awprot),
        .s_axi_awregion        (mm_axi_awregion),
        .s_axi_awqos           (mm_axi_awqos),
        .s_axi_awvalid         (mm_axi_awvalid),
        .m_axi_awready         (mm_axi_awready),
        // AXI write data channel
        .s_axi_wdata           (mm_axi_wdata),
        .s_axi_wstrb           (mm_axi_wstrb),
        .s_axi_wlast           (mm_axi_wlast),
        .s_axi_wvalid          (mm_axi_wvalid),
        .m_axi_wready          (mm_axi_wready),
        // AXI write response channel
        .s_axi_bready          (mm_axi_bready),
        .m_axi_bid             (mm_axi_bid),
        .m_axi_bresp           (mm_axi_bresp),
        .m_axi_bvalid          (mm_axi_bvalid),
        // AXI read response channel
        .s_axi_arid            (mm_axi_arid),
        .s_axi_araddr          (mm_axi_araddr),
        .s_axi_arlen           (mm_axi_arlen),
        .s_axi_arsize          (mm_axi_arsize),
        .s_axi_arburst         (mm_axi_arburst),
        .s_axi_arlock          (mm_axi_arlock),
        .s_axi_arcache         (mm_axi_arcache),
        .s_axi_arprot          (mm_axi_arprot),
        .s_axi_arregion        (mm_axi_arregion),
        .s_axi_arqos           (mm_axi_arqos),
        .s_axi_arvalid         (mm_axi_arvalid),
        .m_axi_arready         (mm_axi_arready),
        // AXI read data channel
        .s_axi_rready          (mm_axi_rready),
        .m_axi_rid             (mm_axi_rid),
        .m_axi_rdata           (mm_axi_rdata),
        .m_axi_rresp           (mm_axi_rresp),
        .m_axi_rlast           (mm_axi_rlast),
        .m_axi_rvalid          (mm_axi_rvalid)
    );
`endif

axi_lite_passthrough lite_passthrough(
	.aclk                  (mm_axi_clk),
    .aresetn               (mm_axi_rstn),
	// AXI Lite write address channel
	.s_axi_awaddr			(axi_lite_awaddr),
	.s_axi_awvalid			(axi_lite_awvalid),
	.m_axi_awready			(axi_lite_awready),	
	.s_axi_wdata			(axi_lite_wdata),
	.s_axi_wstrb			(axi_lite_wstrb),
	.s_axi_wvalid			(axi_lite_wvalid),
	.m_axi_wready			(axi_lite_wready),
	.s_axi_bready			(axi_lite_bready),
	.m_axi_bresp			(axi_lite_bresp),
	.m_axi_bvalid			(axi_lite_bvalid),
	.s_axi_araddr			(axi_lite_araddr),
	.s_axi_arvalid			(axi_lite_arvalid),
	.m_axi_arready			(axi_lite_arready),
	.m_axi_rdata			(axi_lite_rdata),
	.m_axi_rresp			(axi_lite_rresp),
	.m_axi_rvalid			(axi_lite_rvalid),
	.s_axi_rready			(axi_lite_rready)
);


//**********************************************
// TLX AFU INTERFACE FOR VERIF
//**********************************************
wire                               tlx_clock;
wire                               afu_clock;
assign                             tlx_clock = clock_400m;
assign                             afu_clock = clock_200m;

tlx_afu_interface tlx_afu_vif(
    .tlx_clock             (tlx_clock),
    .afu_clock             (afu_clock)
);

// Table 1: TLX to AFU Response Interface
assign                             tlx_afu_vif.tlx_afu_resp_valid_top = dut0.oc_func.tlx_afu_resp_valid;
assign                             tlx_afu_vif.tlx_afu_resp_opcode_top = dut0.oc_func.tlx_afu_resp_opcode;
assign                             tlx_afu_vif.tlx_afu_resp_afutag_top = dut0.oc_func.tlx_afu_resp_afutag;
assign                             tlx_afu_vif.tlx_afu_resp_code_top = dut0.oc_func.tlx_afu_resp_code;
assign                             tlx_afu_vif.tlx_afu_resp_pg_size_top = dut0.oc_func.tlx_afu_resp_pg_size;
assign                             tlx_afu_vif.tlx_afu_resp_dl_top = dut0.oc_func.tlx_afu_resp_dl;
assign                             tlx_afu_vif.tlx_afu_resp_dp_top = dut0.oc_func.tlx_afu_resp_dp;
//assign                             tlx_afu_vif.tlx_afu_resp_host_tag_top = dut0.oc_func.tlx_afu_resp_host_tag;
assign                             tlx_afu_vif.tlx_afu_resp_addr_tag_top = dut0.oc_func.tlx_afu_resp_addr_tag;
//assign                             tlx_afu_vif.tlx_afu_resp_cache_state_top = dut0.oc_func.tlx_afu_resp_cache_state;
// Table 2: TLX Response Credit Interface
assign                             tlx_afu_vif.afu_tlx_resp_credit_top = dut0.oc_func.afu_tlx_resp_credit;
assign                             tlx_afu_vif.afu_tlx_resp_initial_credit_top = dut0.oc_func.afu_tlx_resp_initial_credit;
// Table 3: TLX to AFU Command Interface
assign                             tlx_afu_vif.tlx_afu_cmd_valid_top = dut0.oc_func.tlx_afu_cmd_valid;
assign                             tlx_afu_vif.tlx_afu_cmd_opcode_top = dut0.oc_func.tlx_afu_cmd_opcode;
assign                             tlx_afu_vif.tlx_afu_cmd_capptag_top = dut0.oc_func.tlx_afu_cmd_capptag;
assign                             tlx_afu_vif.tlx_afu_cmd_dl_top = dut0.oc_func.tlx_afu_cmd_dl;
assign                             tlx_afu_vif.tlx_afu_cmd_pl_top = dut0.oc_func.tlx_afu_cmd_pl;
assign                             tlx_afu_vif.tlx_afu_cmd_be_top = dut0.oc_func.tlx_afu_cmd_be;
assign                             tlx_afu_vif.tlx_afu_cmd_end_top = dut0.oc_func.tlx_afu_cmd_end;
assign                             tlx_afu_vif.tlx_afu_cmd_pa_top = dut0.oc_func.tlx_afu_cmd_pa;
assign                             tlx_afu_vif.tlx_afu_cmd_flag_top = dut0.oc_func.tlx_afu_cmd_flag;
assign                             tlx_afu_vif.tlx_afu_cmd_os_top = dut0.oc_func.tlx_afu_cmd_os;
// Table 4: TLX Command Credit Interface
assign                             tlx_afu_vif.afu_tlx_cmd_credit_top = dut0.oc_func.afu_tlx_cmd_credit;
assign                             tlx_afu_vif.afu_tlx_cmd_initial_credit_top = dut0.oc_func.afu_tlx_cmd_initial_credit;
// Table 5: TLX to AFU Response Data Interface
assign                             tlx_afu_vif.tlx_afu_resp_data_valid_top = dut0.oc_func.tlx_afu_resp_data_valid;
assign                             tlx_afu_vif.tlx_afu_resp_data_bus_top = dut0.oc_func.tlx_afu_resp_data_bus;
assign                             tlx_afu_vif.tlx_afu_resp_data_bdi_top = dut0.oc_func.tlx_afu_resp_data_bdi;
assign                             tlx_afu_vif.afu_tlx_resp_rd_req_top = dut0.oc_func.afu_tlx_resp_rd_req;
assign                             tlx_afu_vif.afu_tlx_resp_rd_cnt_top = dut0.oc_func.afu_tlx_resp_rd_cnt;
// Table 6: TLX to AFU Command Data Interface
assign                             tlx_afu_vif.tlx_afu_cmd_data_valid_top = dut0.oc_func.tlx_afu_cmd_data_valid;
assign                             tlx_afu_vif.tlx_afu_cmd_data_bus_top = dut0.oc_func.tlx_afu_cmd_data_bus;
assign                             tlx_afu_vif.tlx_afu_cmd_data_bdi_top = dut0.oc_func.tlx_afu_cmd_data_bdi;
assign                             tlx_afu_vif.afu_tlx_cmd_rd_req_top = dut0.oc_func.afu_tlx_cmd_rd_req;
assign                             tlx_afu_vif.afu_tlx_cmd_rd_cnt_top = dut0.oc_func.afu_tlx_cmd_rd_cnt;
// Table 7: TLX Framer credit interface
assign                             tlx_afu_vif.tlx_afu_resp_credit_top = dut0.oc_func.tlx_afu_resp_credit;
assign                             tlx_afu_vif.tlx_afu_resp_data_credit_top = dut0.oc_func.tlx_afu_resp_data_credit;
assign                             tlx_afu_vif.tlx_afu_cmd_credit_top = dut0.oc_func.tlx_afu_cmd_credit;
assign                             tlx_afu_vif.tlx_afu_cmd_data_credit_top = dut0.oc_func.tlx_afu_cmd_data_credit;
assign                             tlx_afu_vif.tlx_afu_cmd_resp_initial_credit_top = dut0.oc_func.tlx_afu_cmd_initial_credit;
assign                             tlx_afu_vif.tlx_afu_data_initial_credit_top = dut0.oc_func.tlx_afu_resp_initial_credit;
assign                             tlx_afu_vif.tlx_afu_cmd_data_initial_credit_top = dut0.oc_func.tlx_afu_cmd_data_initial_credit;
assign                             tlx_afu_vif.tlx_afu_resp_data_initial_credit_top = dut0.oc_func.tlx_afu_resp_data_initial_credit;
// Table 8: TLX Framer Command Interface
assign                             tlx_afu_vif.afu_tlx_cmd_valid_top = dut0.oc_func.afu_tlx_cmd_valid;
assign                             tlx_afu_vif.afu_tlx_cmd_opcode_top = dut0.oc_func.afu_tlx_cmd_opcode;
assign                             tlx_afu_vif.afu_tlx_cmd_actag_top = dut0.oc_func.afu_tlx_cmd_actag;
assign                             tlx_afu_vif.afu_tlx_cmd_stream_id_top = dut0.oc_func.afu_tlx_cmd_stream_id;
assign                             tlx_afu_vif.afu_tlx_cmd_ea_or_obj_top = dut0.oc_func.afu_tlx_cmd_ea_or_obj;
assign                             tlx_afu_vif.afu_tlx_cmd_afutag_top = dut0.oc_func.afu_tlx_cmd_afutag;
assign                             tlx_afu_vif.afu_tlx_cmd_dl_top = dut0.oc_func.afu_tlx_cmd_dl;
assign                             tlx_afu_vif.afu_tlx_cmd_pl_top = dut0.oc_func.afu_tlx_cmd_pl;
assign                             tlx_afu_vif.afu_tlx_cmd_os_top = dut0.oc_func.afu_tlx_cmd_os;
assign                             tlx_afu_vif.afu_tlx_cmd_be_top = dut0.oc_func.afu_tlx_cmd_be;
assign                             tlx_afu_vif.afu_tlx_cmd_flag_top = dut0.oc_func.afu_tlx_cmd_flag;
assign                             tlx_afu_vif.afu_tlx_cmd_endian_top = dut0.oc_func.afu_tlx_cmd_endian;
assign                             tlx_afu_vif.afu_tlx_cmd_bdf_top = dut0.oc_func.afu_tlx_cmd_bdf;
assign                             tlx_afu_vif.afu_tlx_cmd_pasid_top = dut0.oc_func.afu_tlx_cmd_pasid;
assign                             tlx_afu_vif.afu_tlx_cmd_pg_size_top = dut0.oc_func.afu_tlx_cmd_pg_size;
assign                             tlx_afu_vif.afu_tlx_cdata_bus_top = dut0.oc_func.afu_tlx_cdata_bus;
assign                             tlx_afu_vif.afu_tlx_cdata_bdi_top = dut0.oc_func.afu_tlx_cdata_bdi;// TODO: TLX Ref Design doc lists this as afu_tlx_cdata_bad
assign                             tlx_afu_vif.afu_tlx_cdata_valid_top = dut0.oc_func.afu_tlx_cdata_valid;
// Table 9: TLX Framer Response Interface
assign                             tlx_afu_vif.afu_tlx_resp_valid_top = dut0.oc_func.afu_tlx_resp_valid;
assign                             tlx_afu_vif.afu_tlx_resp_opcode_top = dut0.oc_func.afu_tlx_resp_opcode;
assign                             tlx_afu_vif.afu_tlx_resp_dl_top = dut0.oc_func.afu_tlx_resp_dl;
assign                             tlx_afu_vif.afu_tlx_resp_capptag_top = dut0.oc_func.afu_tlx_resp_capptag;
assign                             tlx_afu_vif.afu_tlx_resp_dp_top = dut0.oc_func.afu_tlx_resp_dp;
assign                             tlx_afu_vif.afu_tlx_resp_code_top = dut0.oc_func.afu_tlx_resp_code;
assign                             tlx_afu_vif.afu_tlx_rdata_valid_top = dut0.oc_func.afu_tlx_rdata_valid;
assign                             tlx_afu_vif.afu_tlx_rdata_bus_top = dut0.oc_func.afu_tlx_rdata_bus;
assign                             tlx_afu_vif.afu_tlx_rdata_bdi_top = dut0.oc_func.afu_tlx_rdata_bdi;

//**********************************************
// INTERRUPT INTERFACE FOR VERIF
//**********************************************
intrp_interface intrp_vif(
    .action_clock             (dut0.oc_func.fw_afu.action_w.ap_clk),
    .action_rst_n             (dut0.oc_func.fw_afu.action_w.ap_rst_n)
);

assign                             intrp_vif.intrp_req = dut0.oc_func.fw_afu.action_w.interrupt;
assign                             intrp_vif.intrp_ack = dut0.oc_func.fw_afu.action_w.interrupt_ack;
assign                             intrp_vif.intrp_src = dut0.oc_func.fw_afu.action_w.interrupt_src;
assign                             intrp_vif.intrp_ctx = dut0.oc_func.fw_afu.action_w.interrupt_ctx;

//**********************************************
// DLX TLX INTERFACE FOR VERIF
//**********************************************
tl_dl_if tl_dl_vif(
    .clock                 (tlx_clock)
);
//assign                             tl_dl_vif.tl_dl_flit_vld = dut0.bsp.inst.tlx_dlx_flit_valid;
//assign                             tl_dl_vif.tl_dl_flit_data = dut0.bsp.inst.tlx_dlx_flit;
//
//assign                             dut0.bsp.inst.dlx_tlx_flit_valid = tl_dl_vif.dl_tl_flit_vld;
//assign                             dut0.bsp.inst.dlx_tlx_flit_crc_err = tl_dl_vif.dl_tl_flit_error;
//assign                             dut0.bsp.inst.dlx_tlx_flit = tl_dl_vif.dl_tl_flit_data;
//assign                             dut0.bsp.inst.dlx_tlx_flit_credit = tl_dl_vif.dl_tl_flit_credit;
//assign                             dut0.bsp.inst.dlx_tlx_link_up = tl_dl_vif.dl_tl_link_up;
//assign                             dut0.bsp.inst.dlx_config_info = 32'b0;
//assign                             dut0.bsp.inst.dlx_tlx_init_flit_depth = tl_dl_vif.dl_tl_init_flit_depth;

assign                             tl_dl_vif.tl_dl_flit_vld = dut0.bsp.tlx_dlx_flit_valid;
assign                             tl_dl_vif.tl_dl_flit_data = dut0.bsp.tlx_dlx_flit;

assign                             dut0.bsp.dlx_tlx_flit_valid = tl_dl_vif.dl_tl_flit_vld;
assign                             dut0.bsp.dlx_tlx_flit_crc_err = tl_dl_vif.dl_tl_flit_error;
assign                             dut0.bsp.dlx_tlx_flit = tl_dl_vif.dl_tl_flit_data;
assign                             dut0.bsp.dlx_tlx_flit_credit = tl_dl_vif.dl_tl_flit_credit;
assign                             dut0.bsp.dlx_tlx_link_up = tl_dl_vif.dl_tl_link_up;
assign                             dut0.bsp.dlx_config_info = 32'b0;
assign                             dut0.bsp.dlx_tlx_init_flit_depth = tl_dl_vif.dl_tl_init_flit_depth;
//**********************************************
// VERIFICATION INITIALIZATION
//**********************************************
initial begin
    uvm_config_db#(virtual axi_vip_if `AXI_VIP_MM_CHECK_PARAMS)::set(null, "*", "mm_check_vif", mm_check_passthrough.inst.IF);
    uvm_config_db#(virtual tlx_afu_interface)::set(null, "*", "tlx_afu_vif", tlx_afu_vif);
    uvm_config_db#(virtual intrp_interface)::set(null, "*", "intrp_vif", intrp_vif);
    uvm_config_db#(virtual tl_dl_if)::set(null, "*", "tl_dl_vif", tl_dl_vif);
    mm_check_passthrough.inst.set_passthrough_mode();
    mm_check_passthrough.inst.IF.set_enable_xchecks_to_warn();
    mm_check_passthrough.inst.IF.set_xilinx_reset_check_to_warn();
    uvm_config_db#(virtual axi_vip_if `AXI_LITE_PARAMS)::set(null, "*", "axi_lite_vif", lite_passthrough.inst.IF);
    lite_passthrough.inst.set_passthrough_mode();
    lite_passthrough.inst.IF.set_enable_xchecks_to_warn();
    lite_passthrough.inst.IF.set_xilinx_reset_check_to_warn();
end

initial run_test();

endmodule

