############################################################################
############################################################################
##
## Copyright 2019 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
############################################################################
############################################################################

set dlx_dir          $root_dir/oc-bip/dlx
set tlx_dir          $root_dir/oc-bip/tlx
set cfg_dir          $root_dir/oc-bip/config_subsystem
set common_tcl       $root_dir/oc-bip/tcl
set oc_bsp_xdc       $fpga_card_dir/xdc
set card_dir         $fpga_card_dir
set card_src         $fpga_card_dir/verilog
set use_flash        $::env(FLASH_USED)
set transceiver_type   "bypass"
set transceiver_speed  $::env(PHY_SPEED)
set fpga_card          $::env(FPGACARD)


############################################################################
#      Print information
puts "                        FLASH=$use_flash, transceiver type=$transceiver_type, speed=$transceiver_speed"






############################################################################
#      Prepare files and contraints
set verilog_DLx     [list \
 "[file normalize "$dlx_dir/ocx_bram_infer.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_crc.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_rx_lane.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_rx_lane_66.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_rx_main.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_rxdf.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_top.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_tx_ctl.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_tx_flt.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_tx_gbx.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_tx_que.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_txdf.v"]"\
 "[file normalize "$dlx_dir/ocx_dlx_xlx_if.v"]"\
]
set verilog_TLx     [list \
 "[file normalize "$tlx_dir/bram_syn_test.v"]"\
 "[file normalize "$tlx_dir/dram_syn_test.v"]"\
 "[file normalize "$tlx_dir/ocx_leaf_inferd_regfile.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_513x32_fifo.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_514x16_fifo.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_bdi_mac.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_cfg_mac.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_cmd_fifo_mac.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_ctl_fsm.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_data_arb.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_data_fifo_mac.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_dcp_fifo_ctl.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_fifo_cntlr.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_flit_parser.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_framer.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_framer_cmd_fifo.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_framer_rsp_fifo.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_parse_mac.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_parser_err_mac.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_rcv_mac.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_rcv_top.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_resp_fifo_mac.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_top.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_vc0_fifo_ctl.v"]"\
 "[file normalize "$tlx_dir/ocx_tlx_vc1_fifo_ctl.v"]"\
]
set verilog_flash [list \
 "[file normalize "$card_src/cfg_reg_to_axi4lite.v"]"\
 "[file normalize "$card_src/flash_sub_system.v"]"\
]

set verilog_cfg [list \
 "[file normalize "$cfg_dir/cfg_cmdfifo.v"]"\
 "[file normalize "$cfg_dir/cfg_descriptor.v"]"\
 "[file normalize "$cfg_dir/cfg_fence.v"]"\
 "[file normalize "$cfg_dir/cfg_func1_init.v"]"\
 "[file normalize "$cfg_dir/cfg_func1.v"]"\
 "[file normalize "$cfg_dir/cfg_func0_init.v"]"\
 "[file normalize "$cfg_dir/cfg_func0.v"]"\
 "[file normalize "$cfg_dir/cfg_respfifo.v"]"\
 "[file normalize "$cfg_dir/cfg_seq.v"]"\
 "[file normalize "$cfg_dir/oc_cfg.v"]"\
]


set verilog_bypass  [list \
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_bit_sync.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_gtwiz_userclk_tx.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_init.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_reset_sync.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_wrapper_functions.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_wrapper.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_gtwiz_buffbypass_rx.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_gtwiz_buffbypass_tx.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_gtwiz_reset.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/dlx_phy_wrap.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/tx_mod_da_fsm.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/drp_read_modify_write.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_buffer_bypass/DLx_phy_example_reset_inv_sync.v"]"\
]
set verilog_elastic [list \
 "[file normalize "$card_src/xilinx/encrypted_elastic_buffer/DLx_phy_example_bit_sync.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_elastic_buffer/DLx_phy_example_gtwiz_userclk_tx.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_elastic_buffer/DLx_phy_example_init.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_elastic_buffer/DLx_phy_example_reset_sync.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_elastic_buffer/DLx_phy_example_wrapper_functions.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_elastic_buffer/DLx_phy_example_wrapper.v"]"\
 "[file normalize "$card_src/xilinx/encrypted_elastic_buffer/dlx_phy_wrap.v"]"\
]

set verilog_bsp [list \
 "[file normalize "$card_src/cfg_tieoffs.v"]"\
 "[file normalize "$card_src/vpd_stub.v"]"\
 "[file normalize "$card_src/oc_bsp.v"]"\
 "[file normalize "$card_src/iprog_icap.vhdl"]"\
]

if {$transceiver_type eq "bypass"} {
    set phy_package [list {*}$verilog_bypass]
} else {
    set phy_package [list {*}$verilog_elastic]
}

if {$use_flash ne "FALSE"} {
    set verilog_board_support [list {*}$phy_package {*}$verilog_bsp {*}$verilog_cfg {*}$verilog_flash]
} else {
    set verilog_board_support [list {*}$phy_package {*}$verilog_bsp {*}$verilog_cfg ]
}


############################################################################
#Add source files
puts "	                Adding design sources to oc_bsp project"
# Set 'sources_1' fileset object, create list of all nececessary verilog files
set obj [get_filesets sources_1]
set files [list {*}$verilog_DLx {*}$verilog_TLx {*}$verilog_board_support]
add_files -norecurse -fileset $obj $files

# deal with header files
set file "DLx_phy_example_wrapper_functions.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "cfg_func1_init.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "cfg_func0_init.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj



############################################################################
# Add constraint files
set xdc_files [list \
                       "[file normalize "$oc_bsp_xdc/main_pinout.xdc"]" \
                       "[file normalize "$oc_bsp_xdc/main_timing.xdc"]" \
                       "[file normalize "$oc_bsp_xdc/extra.xdc"]" \
                   ]

if {$transceiver_type eq "bypass" } {
    set xdc_files [list {*}$xdc_files \
                         "[file normalize "$oc_bsp_xdc/main_placement_bypass.xdc"]" \
                         "[file normalize "$oc_bsp_xdc/gty_properties.xdc"]" \
                   ]
} else {
    set xdc_files [list {*}$xdc_files \
                         "[file normalize "$oc_bsp_xdc/main_placement_elastic.xdc"]" \
                   ]
}

if {$use_flash ne "FALSE"} {
    set xdc_files [list {*}$xdc_files \
                         "[file normalize "$oc_bsp_xdc/qspi_pinout.xdc"]" \
                         "[file normalize "$oc_bsp_xdc/qspi_timing.xdc"]" \
                   ]
}

puts "	                Adding constraints to oc_bsp project"
set obj [get_filesets constrs_1]
add_files -fileset constrs_1 -norecurse $xdc_files >> $log_file
set_property -name "target_constrs_file" -value "[file normalize "$oc_bsp_xdc/extra.xdc"]" -objects $obj

############################################################################
set synth_verilog_defines ""
if {$transceiver_type  eq "bypass" } {set synth_verilog_defines [concat $synth_verilog_defines "BUFFER_BYPASS"]}
if {$transceiver_type  eq "elastic"} {set synth_verilog_defines [concat $synth_verilog_defines "BUFFER_ELASTIC"]}
if {$use_flash         ne "FALSE"       } {set synth_verilog_defines [concat $synth_verilog_defines "FLASH"] }
set synth_verilog_defines [concat $synth_verilog_defines "FRAMEWORK"] 
set_property verilog_define "$synth_verilog_defines" [get_filesets sources_1]
set_property verilog_define "$synth_verilog_defines" [get_filesets sim_1]


############################################################################
# Generate board specific IP
#
source $card_dir/ip/create_vio_DLx_phy_vio_0.tcl
source $card_dir/ip/create_vio_reset_n.tcl

if { $fpga_card == "BW250SOC"  } {
  source $card_dir/ip/create_clk_wiz.tcl
  source $card_dir/ip/create_flash_ip.tcl
}
puts " sourcing $card_dir/ip/create_DLx_PHY_${transceiver_type}_${transceiver_speed}g.tcl"
source $card_dir/ip/create_DLx_PHY_${transceiver_type}_${transceiver_speed}g.tcl

if {$use_flash ne "FALSE"} {
    source $card_dir/ip/axi_quad_spi.tcl
    source $card_dir/ip/axi_hwicap.tcl
}




update_compile_order -fileset sources_1
