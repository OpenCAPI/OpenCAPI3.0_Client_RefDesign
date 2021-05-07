//
// Copyright 2019 International Business Machines
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
    `include "../../../hdl/core/snap_global_vars.v"
`define FLASH

module unit_top (
    output          breakpoint
);

//**********************************************
// CLOCK & RESET
//**********************************************
parameter        RESET_CYCLES = 25;
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

//**********************************************
// VIP INSTANCE FOR VERIF
//**********************************************
`ifndef ENABLE_ODMA
    axi_vip_lite_passthrough lite_passthrough(
        .aclk                           (dut0.oc_func.fw_afu.action_w.ap_clk),
        .aresetn                        (dut0.oc_func.fw_afu.action_w.ap_rst_n),
        .s_axi_awaddr			(dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_awaddr),
        .s_axi_awvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_awvalid),
        .m_axi_awready			(dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_awready),	
        .s_axi_wdata			(dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_wdata),
        //.s_axi_wstrb			(dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_wstrb),
        .s_axi_wvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_wvalid),
        .m_axi_wready			(dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_wready),
        .s_axi_bready			(dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_bready),
        .m_axi_bresp			(dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_bresp),
        .m_axi_bvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_bvalid),
        .s_axi_araddr			(dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_araddr),
        .s_axi_arvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_arvalid),
        .m_axi_arready			(dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_arready),
        .m_axi_rdata			(dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_rdata),
        .m_axi_rresp			(dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_rresp),
        .m_axi_rvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_conv2snap_rvalid),
        .s_axi_rready			(dut0.oc_func.fw_afu.snap_core_i.lite_snap2conv_rready)
    );
    axi_vip_lite_slave lite_slave(
        .aclk                           (unit_top.dut0.oc_func.fw_afu.action_w.ap_clk),
        .aresetn                        (unit_top.dut0.oc_func.fw_afu.action_w.ap_rst_n),
        .s_axi_awaddr			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_awaddr),
        .s_axi_awvalid			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_awvalid),
        .s_axi_awready			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_awready),	
        .s_axi_wdata			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_wdata),
        //.s_axi_wstrb			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_wstrb),
        .s_axi_wvalid			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_wvalid),
        .s_axi_wready			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_wready),
        .s_axi_bready			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_bready),
        .s_axi_bresp			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_bresp),
        .s_axi_bvalid			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_bvalid),
        .s_axi_araddr			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_araddr),
        .s_axi_arvalid			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_arvalid),
        .s_axi_arready			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_arready),
        .s_axi_rdata			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_rdata),
        .s_axi_rresp			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_rresp),
        .s_axi_rvalid			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_rvalid),
        .s_axi_rready			(unit_top.dut0.oc_func.fw_afu.action_w.s_axi_ctrl_reg_rready)
    );
    axi_vip_mm_passthrough mm_passthrough(
        .aclk                  (dut0.oc_func.fw_afu.action_w.ap_clk),
        .aresetn               (dut0.oc_func.fw_afu.action_w.ap_rst_n),
        // AXI write address channel
        .s_axi_awid            (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awid),
        .s_axi_awaddr          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awaddr),
        .s_axi_awlen           (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awlen),
        .s_axi_awsize          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awsize),
        .s_axi_awburst         (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awburst),
        .s_axi_awuser          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awuser),
        //.s_axi_awlock          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awlock),
        //.s_axi_awcache         (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awcache),
        //.s_axi_awprot          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awprot),
        //.s_axi_awregion        (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awregion),
        //.s_axi_awqos           (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awqos),
        .s_axi_awvalid         (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_awvalid),
        .m_axi_awready         (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_awready),
        // AXI write data channel
        .s_axi_wdata           (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wdata),
        .s_axi_wstrb           (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wstrb),
        .s_axi_wlast           (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wlast),
        //.s_axi_wuser           (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wuser),
        .s_axi_wvalid          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_wvalid),
        .m_axi_wready          (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_wready),
        // AXI write response channel
        .s_axi_bready          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_bready),
        .m_axi_bid             (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_bid),
        .m_axi_bresp           (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_bresp),
        .m_axi_buser           (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_buser),
        .m_axi_bvalid          (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_bvalid),
        // AXI read response channel
        .s_axi_arid            (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arid),
        .s_axi_araddr          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_araddr),
        .s_axi_arlen           (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arlen),
        .s_axi_arsize          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arsize),
        .s_axi_arburst         (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arburst),
        .s_axi_aruser          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_aruser),
        //.s_axi_arlock          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arlock),
        //.s_axi_arcache         (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arcache),
        //.s_axi_arprot          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arprot),
        //.s_axi_arregion        (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arregion),
        //.s_axi_arqos           (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arqos),
        .s_axi_arvalid         (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_arvalid),
        .m_axi_arready         (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_arready),
        // AXI read data channel
        .s_axi_rready          (dut0.oc_func.fw_afu.snap_core_i.mm_conv2snap_rready),
        .m_axi_rid             (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rid),
        .m_axi_rdata           (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rdata),
        .m_axi_rresp           (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rresp),
        .m_axi_rlast           (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rlast),
        .m_axi_ruser           (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_ruser),
        .m_axi_rvalid          (dut0.oc_func.fw_afu.snap_core_i.mm_snap2conv_rvalid)
    );
    axi_vip_mm_master mm_master(
        .aclk                  (dut0.oc_func.fw_afu.action_w.ap_clk),
        .aresetn               (dut0.oc_func.fw_afu.action_w.ap_rst_n),
        // AXI write address channel
        .m_axi_awid            (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awid),
        .m_axi_awaddr          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awaddr),
        .m_axi_awlen           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awlen),
        .m_axi_awsize          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awsize),
        .m_axi_awburst         (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awburst),
        .m_axi_awuser          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awuser),
        //.m_axi_awlock          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awlock),
        //.m_axi_awcache         (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awcache),
        //.m_axi_awprot          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awprot),
        //.m_axi_awregion        (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awregion),
        //.m_axi_awqos           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awqos),
        .m_axi_awvalid         (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awvalid),
        .m_axi_awready         (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_awready),
        // AXI write data channel
        .m_axi_wdata           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_wdata),
        .m_axi_wstrb           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_wstrb),
        .m_axi_wlast           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_wlast),
        //.m_axi_wuser           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_wuser),
        .m_axi_wvalid          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_wvalid),
        .m_axi_wready          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_wready),
        // AXI write response channel
        .m_axi_bready          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_bready),
        .m_axi_bid             (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_bid),
        .m_axi_bresp           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_bresp),
        .m_axi_buser           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_buser),
        .m_axi_bvalid          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_bvalid),
        // AXI read response channel
        .m_axi_arid            (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arid),
        .m_axi_araddr          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_araddr),
        .m_axi_arlen           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arlen),
        .m_axi_arsize          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arsize),
        .m_axi_arburst         (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arburst),
        .m_axi_aruser          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_aruser),
        //.m_axi_arlock          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arlock),
        //.m_axi_arcache         (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arcache),
        //.m_axi_arprot          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arprot),
        //.m_axi_arregion        (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arregion),
        //.m_axi_arqos           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arqos),
        .m_axi_arvalid         (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arvalid),
        .m_axi_arready         (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_arready),
        // AXI read data channel
        .m_axi_rready          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_rready),
        .m_axi_rid             (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_rid),
        .m_axi_rdata           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_rdata),
        .m_axi_rresp           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_rresp),
        .m_axi_rlast           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_rlast),
        .m_axi_ruser           (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_ruser),
        .m_axi_rvalid          (dut0.oc_func.fw_afu.action_w.m_axi_host_mem_rvalid)
    );
`else
    axi_vip_lite_passthrough lite_passthrough(
        .aclk                           (dut0.oc_func.fw_afu.action_w.ap_clk),
        .aresetn                        (dut0.oc_func.fw_afu.action_w.ap_rst_n),
        .s_axi_awaddr			(dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_awaddr),
        .s_axi_awvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_awvalid),
        .m_axi_awready			(dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_awready),	
        .s_axi_wdata			(dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_wdata),
        //.s_axi_wstrb			(dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_wstrb),
        .s_axi_wvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_wvalid),
        .m_axi_wready			(dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_wready),
        .s_axi_bready			(dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_bready),
        .m_axi_bresp			(dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_bresp),
        .m_axi_bvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_bvalid),
        .s_axi_araddr			(dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_araddr),
        .s_axi_arvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_arvalid),
        .m_axi_arready			(dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_arready),
        .m_axi_rdata			(dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_rdata),
        .m_axi_rresp			(dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_rresp),
        .m_axi_rvalid			(dut0.oc_func.fw_afu.snap_core_i.lite_odma2mmio_rvalid),
        .s_axi_rready			(dut0.oc_func.fw_afu.snap_core_i.lite_mmio2odma_rready)
    );
    axi_vip_lite_slave lite_slave(
        .aclk                           (unit_top.dut0.oc_func.fw_afu.action_w.ap_clk),
        .aresetn                        (unit_top.dut0.oc_func.fw_afu.action_w.ap_rst_n),
        .s_axi_awaddr			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_awaddr),
        .s_axi_awvalid			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_awvalid),
        .s_axi_awready			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_awready),	
        .s_axi_wdata			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_wdata),
        //.s_axi_wstrb			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_wstrb),
        .s_axi_wvalid			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_wvalid),
        .s_axi_wready			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_wready),
        .s_axi_bready			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_bready),
        .s_axi_bresp			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_bresp),
        .s_axi_bvalid			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_bvalid),
        .s_axi_araddr			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_araddr),
        .s_axi_arvalid			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_arvalid),
        .s_axi_arready			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_arready),
        .s_axi_rdata			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_rdata),
        .s_axi_rresp			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_rresp),
        .s_axi_rvalid			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_rvalid),
        .s_axi_rready			(unit_top.dut0.oc_func.fw_afu.action_w.a_s_axi_rready)
    );
    `ifndef ENABLE_ODMA_ST_MODE
        axi_vip_mm_passthrough mm_passthrough(
            .aclk                  (dut0.oc_func.fw_afu.action_w.ap_clk),
            .aresetn               (dut0.oc_func.fw_afu.action_w.ap_rst_n),
            // AXI write address channel
            .s_axi_awid            (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awid),
            .s_axi_awaddr          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awaddr),
            .s_axi_awlen           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awlen),
            .s_axi_awsize          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awsize),
            .s_axi_awburst         (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awburst),
            .s_axi_awuser          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awuser),
            //.s_axi_awlock          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awlock),
            //.s_axi_awcache         (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awcache),
            //.s_axi_awprot          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awprot),
            //.s_axi_awregion        (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awregion),
            //.s_axi_awqos           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awqos),
            .s_axi_awvalid         (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awvalid),
            .m_axi_awready         (dut0.oc_func.fw_afu.snap_core_i.axi_mm_awready),
            // AXI write data channel
            .s_axi_wdata           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_wdata),
            .s_axi_wstrb           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_wstrb),
            .s_axi_wlast           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_wlast),
            //.s_axi_wuser           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_wuser),
            .s_axi_wvalid          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_wvalid),
            .m_axi_wready          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_wready),
            // AXI write response channel
            .s_axi_bready          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_bready),
            .m_axi_bid             (dut0.oc_func.fw_afu.snap_core_i.axi_mm_bid),
            .m_axi_bresp           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_bresp),
            .m_axi_buser           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_buser),
            .m_axi_bvalid          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_bvalid),
            // AXI read response channel
            .s_axi_arid            (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arid),
            .s_axi_araddr          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_araddr),
            .s_axi_arlen           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arlen),
            .s_axi_arsize          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arsize),
            .s_axi_arburst         (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arburst),
            .s_axi_aruser          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_aruser),
            //.s_axi_arlock          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arlock),
            //.s_axi_arcache         (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arcache),
            //.s_axi_arprot          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arprot),
            //.s_axi_arregion        (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arregion),
            //.s_axi_arqos           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arqos),
            .s_axi_arvalid         (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arvalid),
            .m_axi_arready         (dut0.oc_func.fw_afu.snap_core_i.axi_mm_arready),
            // AXI read data channel
            .s_axi_rready          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_rready),
            .m_axi_rid             (dut0.oc_func.fw_afu.snap_core_i.axi_mm_rid),
            .m_axi_rdata           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_rdata),
            .m_axi_rresp           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_rresp),
            .m_axi_rlast           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_rlast),
            .m_axi_ruser           (dut0.oc_func.fw_afu.snap_core_i.axi_mm_ruser),
            .m_axi_rvalid          (dut0.oc_func.fw_afu.snap_core_i.axi_mm_rvalid)
        );
        axi_vip_mm_slave mm_slave(
            .aclk                  (dut0.oc_func.fw_afu.action_w.ap_clk),
            .aresetn               (dut0.oc_func.fw_afu.action_w.ap_rst_n),
            // AXI write address channel
            .s_axi_awid            (dut0.oc_func.fw_afu.action_w.axi_mm_awid),
            .s_axi_awaddr          (dut0.oc_func.fw_afu.action_w.axi_mm_awaddr),
            .s_axi_awlen           (dut0.oc_func.fw_afu.action_w.axi_mm_awlen),
            .s_axi_awsize          (dut0.oc_func.fw_afu.action_w.axi_mm_awsize),
            .s_axi_awburst         (dut0.oc_func.fw_afu.action_w.axi_mm_awburst),
            .s_axi_awuser          (dut0.oc_func.fw_afu.action_w.axi_mm_awuser),
            //.s_axi_awlock          (dut0.oc_func.fw_afu.action_w.axi_mm_awlock),
            //.s_axi_awcache         (dut0.oc_func.fw_afu.action_w.axi_mm_awcache),
            //.s_axi_awprot          (dut0.oc_func.fw_afu.action_w.axi_mm_awprot),
            //.s_axi_awregion        (dut0.oc_func.fw_afu.action_w.axi_mm_awregion),
            //.s_axi_awqos           (dut0.oc_func.fw_afu.action_w.axi_mm_awqos),
            .s_axi_awvalid         (dut0.oc_func.fw_afu.action_w.axi_mm_awvalid),
            .s_axi_awready         (dut0.oc_func.fw_afu.action_w.axi_mm_awready),
            // AXI write data channel
            .s_axi_wdata           (dut0.oc_func.fw_afu.action_w.axi_mm_wdata),
            .s_axi_wstrb           (dut0.oc_func.fw_afu.action_w.axi_mm_wstrb),
            .s_axi_wlast           (dut0.oc_func.fw_afu.action_w.axi_mm_wlast),
            //.s_axi_wuser           (dut0.oc_func.fw_afu.action_w.axi_mm_wuser),
            .s_axi_wvalid          (dut0.oc_func.fw_afu.action_w.axi_mm_wvalid),
            .s_axi_wready          (dut0.oc_func.fw_afu.action_w.axi_mm_wready),
            // AXI write response channel
            .s_axi_bready          (dut0.oc_func.fw_afu.action_w.axi_mm_bready),
            .s_axi_bid             (dut0.oc_func.fw_afu.action_w.axi_mm_bid),
            .s_axi_bresp           (dut0.oc_func.fw_afu.action_w.axi_mm_bresp),
            .s_axi_buser           (dut0.oc_func.fw_afu.action_w.axi_mm_buser),
            .s_axi_bvalid          (dut0.oc_func.fw_afu.action_w.axi_mm_bvalid),
            // AXI read response channel
            .s_axi_arid            (dut0.oc_func.fw_afu.action_w.axi_mm_arid),
            .s_axi_araddr          (dut0.oc_func.fw_afu.action_w.axi_mm_araddr),
            .s_axi_arlen           (dut0.oc_func.fw_afu.action_w.axi_mm_arlen),
            .s_axi_arsize          (dut0.oc_func.fw_afu.action_w.axi_mm_arsize),
            .s_axi_arburst         (dut0.oc_func.fw_afu.action_w.axi_mm_arburst),
            .s_axi_aruser          (dut0.oc_func.fw_afu.action_w.axi_mm_aruser),
            //.s_axi_arlock          (dut0.oc_func.fw_afu.action_w.axi_mm_arlock),
            //.s_axi_arcache         (dut0.oc_func.fw_afu.action_w.axi_mm_arcache),
            //.s_axi_arprot          (dut0.oc_func.fw_afu.action_w.axi_mm_arprot),
            //.s_axi_arregion        (dut0.oc_func.fw_afu.action_w.axi_mm_arregion),
            //.s_axi_arqos           (dut0.oc_func.fw_afu.action_w.axi_mm_arqos),
            .s_axi_arvalid         (dut0.oc_func.fw_afu.action_w.axi_mm_arvalid),
            .s_axi_arready         (dut0.oc_func.fw_afu.action_w.axi_mm_arready),
            // AXI read data channel
            .s_axi_rready          (dut0.oc_func.fw_afu.action_w.axi_mm_rready),
            .s_axi_rid             (dut0.oc_func.fw_afu.action_w.axi_mm_rid),
            .s_axi_rdata           (dut0.oc_func.fw_afu.action_w.axi_mm_rdata),
            .s_axi_rresp           (dut0.oc_func.fw_afu.action_w.axi_mm_rresp),
            .s_axi_rlast           (dut0.oc_func.fw_afu.action_w.axi_mm_rlast),
            .s_axi_ruser           (dut0.oc_func.fw_afu.action_w.axi_mm_ruser),
            .s_axi_rvalid          (dut0.oc_func.fw_afu.action_w.axi_mm_rvalid)
        );
    `else
        axi_vip_st_passthrough_h2a st_passthrough_h2a(
            .aclk                  (dut0.oc_func.fw_afu.action_w.ap_clk),
            .aresetn               (dut0.oc_func.fw_afu.action_w.ap_rst_n),
            .s_axis_tvalid         (dut0.oc_func.fw_afu.snap_core_i.m_axis_tvalid),
            //.s_axis_tready         (),
            .s_axis_tdata          (dut0.oc_func.fw_afu.snap_core_i.m_axis_tdata),
            .s_axis_tkeep          (dut0.oc_func.fw_afu.snap_core_i.m_axis_tkeep),
            .s_axis_tlast          (dut0.oc_func.fw_afu.snap_core_i.m_axis_tlast),
            .s_axis_tid            (dut0.oc_func.fw_afu.snap_core_i.m_axis_tid),
            .s_axis_tuser          (dut0.oc_func.fw_afu.snap_core_i.m_axis_tuser),
            //.m_axis_tvalid         (),
            .m_axis_tready         (dut0.oc_func.fw_afu.snap_core_i.m_axis_tready)
            //.m_axis_tdata          (),
            //.m_axis_tkeep          (),
            //.m_axis_tlast          (),
            //.m_axis_tid            (),
            //.m_axis_tuser          ()
        );
        axi_vip_st_passthrough_a2h st_passthrough_a2h(
            .aclk                  (dut0.oc_func.fw_afu.action_w.ap_clk),
            .aresetn               (dut0.oc_func.fw_afu.action_w.ap_rst_n),
            .s_axis_tvalid         (dut0.oc_func.fw_afu.snap_core_i.s_axis_tvalid),
            //.s_axis_tready         (),
            .s_axis_tdata          (dut0.oc_func.fw_afu.snap_core_i.s_axis_tdata),
            .s_axis_tkeep          (dut0.oc_func.fw_afu.snap_core_i.s_axis_tkeep),
            .s_axis_tlast          (dut0.oc_func.fw_afu.snap_core_i.s_axis_tlast),
            .s_axis_tid            (dut0.oc_func.fw_afu.snap_core_i.s_axis_tid),
            .s_axis_tuser          (dut0.oc_func.fw_afu.snap_core_i.s_axis_tuser),
            //.m_axis_tvalid         (),
            .m_axis_tready         (dut0.oc_func.fw_afu.snap_core_i.s_axis_tready)
            //.m_axis_tdata          (),
            //.m_axis_tkeep          (),
            //.m_axis_tlast          (),
            //.m_axis_tid            (),
            //.m_axis_tuser          ()
        );
        axi_vip_st_slave st_slave(
            .aclk                  (dut0.oc_func.fw_afu.action_w.ap_clk),
            .aresetn               (dut0.oc_func.fw_afu.action_w.ap_rst_n),
            .s_axis_tvalid         (dut0.oc_func.fw_afu.action_w.m_axis_tvalid),
            .s_axis_tdata          (dut0.oc_func.fw_afu.action_w.m_axis_tdata),
            .s_axis_tkeep          (dut0.oc_func.fw_afu.action_w.m_axis_tkeep),
            .s_axis_tlast          (dut0.oc_func.fw_afu.action_w.m_axis_tlast),
            .s_axis_tid            (dut0.oc_func.fw_afu.action_w.m_axis_tid),
            .s_axis_tuser          (dut0.oc_func.fw_afu.action_w.m_axis_tuser),
            .s_axis_tready         (dut0.oc_func.fw_afu.action_w.m_axis_tready)
        );
         axi_vip_st_master st_master(
            .aclk                  (dut0.oc_func.fw_afu.action_w.ap_clk),
            .aresetn               (dut0.oc_func.fw_afu.action_w.ap_rst_n),
            .m_axis_tvalid         (dut0.oc_func.fw_afu.action_w.s_axis_tvalid),
            .m_axis_tdata          (dut0.oc_func.fw_afu.action_w.s_axis_tdata),
            .m_axis_tkeep          (dut0.oc_func.fw_afu.action_w.s_axis_tkeep),
            .m_axis_tlast          (dut0.oc_func.fw_afu.action_w.s_axis_tlast),
            .m_axis_tid            (dut0.oc_func.fw_afu.action_w.s_axis_tid),
            .m_axis_tuser          (dut0.oc_func.fw_afu.action_w.s_axis_tuser),
            .m_axis_tready         (dut0.oc_func.fw_afu.action_w.s_axis_tready)
        );
    `endif
`endif

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

assign                             intrp_vif.intrp_ack = dut0.oc_func.fw_afu.action_w.interrupt_ack;
`ifndef ENABLE_ODMA
    assign                             dut0.oc_func.fw_afu.action_w.interrupt = intrp_vif.intrp_req;
    assign                             dut0.oc_func.fw_afu.action_w.interrupt_src = intrp_vif.intrp_src;
    assign                             dut0.oc_func.fw_afu.action_w.interrupt_ctx = intrp_vif.intrp_ctx;
`else
    assign                             intrp_vif.intrp_req = dut0.oc_func.fw_afu.action_w.interrupt;
    assign                             intrp_vif.intrp_src = dut0.oc_func.fw_afu.action_w.interrupt_src;
    assign                             intrp_vif.intrp_ctx = dut0.oc_func.fw_afu.action_w.interrupt_ctx;
`endif

//**********************************************
// DLX TLX INTERFACE FOR VERIF
//**********************************************
tl_dl_if tl_dl_vif(
    .clock                 (tlx_clock)
);

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
    uvm_config_db#(virtual tlx_afu_interface)::set(null, "*", "tlx_afu_vif", tlx_afu_vif);
    uvm_config_db#(virtual intrp_interface)::set(null, "*", "intrp_vif", intrp_vif);
    uvm_config_db#(virtual tl_dl_if)::set(null, "*", "tl_dl_vif", tl_dl_vif);
    `ifndef ENABLE_ODMA
        uvm_config_db#(virtual axi_vip_if `AXI_VIP_MM_PASSTHROUGH_PARAMS)::set(null, "*", "axi_vip_mm_passthrough_vif", mm_passthrough.inst.IF);
        mm_passthrough.inst.set_passthrough_mode();
        mm_passthrough.inst.IF.set_enable_xchecks_to_warn();
        mm_passthrough.inst.IF.set_xilinx_reset_check_to_warn();
        uvm_config_db#(virtual axi_vip_if `AXI_VIP_MM_MASTER_PARAMS)::set(null, "*", "axi_vip_mm_master_vif", mm_master.inst.IF);
        mm_master.inst.IF.set_enable_xchecks_to_warn();
        mm_master.inst.IF.set_xilinx_reset_check_to_warn();
    `else
        `ifndef ENABLE_ODMA_ST_MODE
            uvm_config_db#(virtual axi_vip_if `AXI_VIP_MM_PASSTHROUGH_PARAMS)::set(null, "*", "axi_vip_mm_passthrough_vif", mm_passthrough.inst.IF);
            mm_passthrough.inst.set_passthrough_mode();
            mm_passthrough.inst.IF.set_enable_xchecks_to_warn();
            mm_passthrough.inst.IF.set_xilinx_reset_check_to_warn();
            uvm_config_db#(virtual axi_vip_if `AXI_VIP_MM_SLAVE_PARAMS)::set(null, "*", "axi_vip_mm_slave_vif", mm_slave.inst.IF);
            mm_slave.inst.IF.set_enable_xchecks_to_warn();
            mm_slave.inst.IF.set_xilinx_reset_check_to_warn();
        `else
            uvm_config_db#(virtual axi4stream_vip_if `AXI_VIP_ST_PASSTHROUGH_H2A_PARAMS)::set(null, "*", "axi_vip_st_passthrough_h2a_vif", st_passthrough_h2a.inst.IF);
            st_passthrough_h2a.inst.set_passthrough_mode();
            st_passthrough_h2a.inst.IF.set_enable_xchecks_to_warn(); 
            st_passthrough_h2a.inst.IF.set_xilinx_reset_check_to_warn();
            uvm_config_db#(virtual axi4stream_vip_if `AXI_VIP_ST_PASSTHROUGH_A2H_PARAMS)::set(null, "*", "axi_vip_st_passthrough_a2h_vif", st_passthrough_a2h.inst.IF);
            st_passthrough_a2h.inst.set_passthrough_mode();
            st_passthrough_a2h.inst.IF.set_enable_xchecks_to_warn(); 
            st_passthrough_a2h.inst.IF.set_xilinx_reset_check_to_warn();
            uvm_config_db#(virtual axi4stream_vip_if `AXI_VIP_ST_SLAVE_PARAMS)::set(null, "*", "axi_vip_st_slave_vif", st_slave.inst.IF);
            st_slave.inst.IF.set_enable_xchecks_to_warn();
            st_slave.inst.IF.set_xilinx_reset_check_to_warn();
            uvm_config_db#(virtual axi4stream_vip_if `AXI_VIP_ST_MASTER_PARAMS)::set(null, "*", "axi_vip_st_master_vif", st_master.inst.IF);
            st_master.inst.IF.set_enable_xchecks_to_warn();
            st_master.inst.IF.set_xilinx_reset_check_to_warn();
        `endif
    `endif
    uvm_config_db#(virtual axi_vip_if `AXI_VIP_LITE_PASSTHROUGH_PARAMS)::set(null, "*", "axi_vip_lite_passthrough_vif", lite_passthrough.inst.IF);
    lite_passthrough.inst.set_passthrough_mode();
    lite_passthrough.inst.IF.set_enable_xchecks_to_warn();
    lite_passthrough.inst.IF.set_xilinx_reset_check_to_warn();
    uvm_config_db#(virtual axi_vip_if `AXI_VIP_LITE_SLAVE_PARAMS)::set(null, "*", "axi_vip_lite_slave_vif", lite_slave.inst.IF);
    lite_slave.inst.IF.set_enable_xchecks_to_warn();
    lite_slave.inst.IF.set_xilinx_reset_check_to_warn();
end

initial run_test();

endmodule

