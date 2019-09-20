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

#Adding source files
#add_files -scan_for_includes $common_src >> $log_file
#add_files -scan_for_includes $dlxtlx_dir >> $log_file

# Files for the various OpenCAPI Units
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
 "[file normalize "$oc_bip_sim_dir/src/dlx_phy_wrap.v"]"\
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

set verilog_board_support [list \
 "[file normalize "$card_src/oc_bsp.v"]"\
 "[file normalize "$card_src/cfg_tieoffs.v"]"\
 "[file normalize "$card_src/vpd_stub.v"]"\
]

if {$use_flash ne ""} {
    set verilog_board_support [list {*}$verilog_board_support {*}$verilog_flash]
}



# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object, create list of all nececessary verilog files
set obj [get_filesets sources_1]

set files [list {*}$verilog_DLx {*}$verilog_TLx {*}$verilog_board_support]
add_files -norecurse -fileset $obj $files

set synth_verilog_defines ""
if {$use_flash         ne ""                            } {set synth_verilog_defines [concat $synth_verilog_defines "FLASH"] }

set_property verilog_define "$synth_verilog_defines" [get_filesets sources_1]



############################################################################
#                                                                          #
# Add encrypted DLx/TLx sources                                            #
#                                                                          #
############################################################################
#add_files -scan_for_includes $dlx_dir >> $log_file
#add_files -scan_for_includes $tlx_dir >> $log_file
## This is a dummy file. No DLX and phy in unit sim mode
#add_files -scan_for_includes $oc_bip_sim_dir/src/dlx_phy_wrap.v >> $log_file
#
#############################################################################
##                                                                          #
## Add config subsystem sources                                             #
##                                                                          #
#############################################################################
##add_files -scan_for_includes $cfg_src >> $log_file
#
#
#############################################################################
##                                                                          #
## Add card specific sources                                                #
##                                                                          #
#############################################################################
#add_files -scan_for_includes $card_src/cfg_reg_to_axi4lite.v >> $log_file
#add_files -scan_for_includes $card_src/flash_sub_system.v >> $log_file
#add_files -scan_for_includes $card_src/oc_bsp.v >> $log_file
#add_files -scan_for_includes $card_src/vpd_stub.v >> $log_file
#add_files -scan_for_includes $card_src/xilinx/encrypted_buffer_bypass >> $log_file
#add_files -scan_for_includes $card_src/xilinx/encrypted_elastic_buffer >> $log_file

