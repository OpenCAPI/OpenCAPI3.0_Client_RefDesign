# *!***************************************************************************
# *! Copyright 2019 International Business Machines
# *!
# *! Licensed under the Apache License, Version 2.0 (the "License");
# *! you may not use this file except in compliance with the License.
# *! You may obtain a copy of the License at
# *! http://www.apache.org/licenses/LICENSE-2.0 
# *!
# *! The patent license granted to you in Section 3 of the License, as applied
# *! to the "Work," hereby includes implementations of the Work in physical form.  
# *!
# *! Unless required by applicable law or agreed to in writing, the reference design
# *! distributed under the License is distributed on an "AS IS" BASIS,
# *! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# *! See the License for the specific language governing permissions and
# *! limitations under the License.
# *! 
# *! The background Specification upon which this is based is managed by and available from
# *! the OpenCAPI Consortium.  More information can be found at https://opencapi.org. 
# *!***************************************************************************
# 
# Description: Creates a Vivado project for OpenCAPI AFUs on a variety of different OpenCAPI enabled cards
# HELP: See the Github wiki

# Create the default command line arguments
set afu               "afp"
set transceiver_type  "bypass"
set transceiver_speed "25.78125"
set use_flash         ""
set use_unencrypted   "false"
set card              "ad9v3"
set proj              "viv_proj"

# Available options to set
set afus { lpc afp }
set transceiver_types { bypass elastic}
set transceiver_speeds { 25.78125 25.625 20.0 }
set cards { ad9v3 }
set fpgas { xcvu3p-ffvc1517-2-i }
set fpga  ""


# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."
if { [info exists ::env(OPENCAPI_BUILD_DIR)] } {
    set origin_dir $::env(OPENCAPI_BUILD_DIR)
} else {
    puts "Need to create environmental variable OPENCAPI_BUILD_DIR\n"
    puts "EG: source scripts/setup_environment"
    exit 0
}


# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

variable script_file
set script_file "create_project.tcl"

# Help information for this script
proc help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--origin_dir <path>\]  Determine source file paths wrt this path. Default"
  puts "                       origin_dir path value is \".\", otherwise, the value"
  puts "                       that was set with the \"-paths_relative_to\" switch"
  puts "                       when this script was generated.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < [llength $::argv]} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"  { incr i; set origin_dir [lindex $::argv $i] }
      "--help"        { help }
      "--afu"         {incr i; set afu               [string tolower [lindex $::argv $i]]}
      "--buffer"      {incr i; set transceiver_type  [string tolower [lindex $::argv $i]]}
      "--speed"       {incr i; set transceiver_speed [string tolower [lindex $::argv $i]]}
      "--flash"       {        set use_flash         "yes"                               }
      "--proj"        {incr i; set proj              [string tolower [lindex $::argv $i]]}
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Determine if command line options are valid
if { [file exists $origin_dir/viv_proj] } {
    puts "Vivado project: viv_proj already exits"
    exit 1
}



if {[lsearch $afus $afu] >= 0} {
    puts "AFU..............[string toupper $afu]"
} else {
    puts "--afu: |$afu| not recognized"
    puts "Options: $afus"
    return
}

if {[lsearch $transceiver_types $transceiver_type] >= 0} {
    puts "buffer...........[string toupper $transceiver_type]"
} else {
    puts "--buffer: |$transceiver_type| not recognized"
    puts "Options: $transceiver_types"
    return
}

if {([lsearch $transceiver_speeds $transceiver_speed] >= 0) || ($transceiver_speed eq "20")} {
    if {$transceiver_speed eq "20"} {
        set transceiver_speed "20.0" 
    }
    puts "Speed............$transceiver_speed Gbps"
} else {
    puts "--speed: |$transceiver_speed| not recognized"
    puts "Options: $transceiver_speeds"
    return
}

if { $use_flash ne "" } {
    puts "Flashing logic...YES"
} else {
    puts "Flashing logic...NO"
}


if { $transceiver_speed == [lindex $transceiver_speeds 0] } {
    puts "DFE..............ON"
} else {
    puts "DFE..............OFF"
}

if {[lsearch $cards $card] >= 0} {
    puts "Card.............[string toupper $card]"
    set fpga [lindex $fpgas [lsearch $cards $card]]
    puts "FPGA.............[string tolower $fpga]"
} else {
    puts "--card: |$card| not recognized"
    puts "Options: $cards"
}

# Files for the various OpenCAPI Units
set verilog_DLx     [list \
 "[file normalize "$origin_dir/dlx/ocx_bram_infer.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_crc.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_rx_lane.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_rx_lane_66.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_rx_main.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_rxdf.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_top.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_tx_ctl.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_tx_flt.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_tx_gbx.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_tx_que.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_txdf.v"]"\
 "[file normalize "$origin_dir/dlx/ocx_dlx_xlx_if.v"]"\
]
set verilog_TLx     [list \
 "[file normalize "$origin_dir/tlx/bram_syn_test.v"]"\
 "[file normalize "$origin_dir/tlx/dram_syn_test.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_leaf_inferd_regfile.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_513x32_fifo.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_514x16_fifo.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_bdi_mac.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_cfg_mac.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_cmd_fifo_mac.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_ctl_fsm.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_data_arb.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_data_fifo_mac.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_dcp_fifo_ctl.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_fifo_cntlr.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_flit_parser.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_framer.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_framer_cmd_fifo.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_framer_rsp_fifo.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_parse_mac.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_parser_err_mac.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_rcv_mac.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_rcv_top.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_resp_fifo_mac.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_top.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_vc0_fifo_ctl.v"]"\
 "[file normalize "$origin_dir/tlx/ocx_tlx_vc1_fifo_ctl.v"]"\
]
set verilog_flash [list \
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/cfg_reg_to_axi4lite.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/flash_sub_system.v"]"\
]
set verilog_cfg [list \
 "[file normalize "$origin_dir/config_subsystem/cfg_cmdfifo.v"]"\
 "[file normalize "$origin_dir/config_subsystem/cfg_descriptor.v"]"\
 "[file normalize "$origin_dir/config_subsystem/cfg_fence.v"]"\
 "[file normalize "$origin_dir/config_subsystem/cfg_func1_init.v"]"\
 "[file normalize "$origin_dir/config_subsystem/cfg_func1.v"]"\
 "[file normalize "$origin_dir/config_subsystem/cfg_func0_init.v"]"\
 "[file normalize "$origin_dir/config_subsystem/cfg_func0.v"]"\
 "[file normalize "$origin_dir/config_subsystem/cfg_respfifo.v"]"\
 "[file normalize "$origin_dir/config_subsystem/cfg_seq.v"]"\
 "[file normalize "$origin_dir/config_subsystem/oc_cfg.v"]"\
]
set verilog_mcp     [list ""]
set verilog_afp     [list \
 "[file normalize "$origin_dir/afu/afp/afp3_afu.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_arb.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_cmdi_rspo.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_cmd_out.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_display.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_fsm_actag.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_fsm_atomic.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_fsm_cpy_ld.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_fsm_cpy_st.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_fsm_intrpt.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_fsm_main.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_fsm_wkhstthrd.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_fsm_xtouch.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_resp_decode.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_rtry_decode.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng_rtry_queue.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_eng.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_mmio.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_perfmon.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_ram1024x004.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_ram1024x018.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_ram2048x032.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_rspi.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_arb004.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_arb008.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_arb016.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_arb128.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_arb512.v"]"\
 "[file normalize "$origin_dir/afu/afp/afp3_cmdo.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_cpeng_rtry_timer.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_decoder3x008.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_decoder4x016.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_decoder5x032.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_decoder9x512.v"]"\
 "[file normalize "$origin_dir/afu/afp/oc_function.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ohc03.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ohc04.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ohc05.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ohc06.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ram128x036q.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ram512x025.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ram512x052.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ram512x064q.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ram512x064.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_ram512x080.v"]"\
 "[file normalize "$origin_dir/afu/afp/mcp3_trace.v"]"\
]
set verilog_lpc     [list \
 "[file normalize "$origin_dir/afu/lpc/lpc_afu.v"]"\
 "[file normalize "$origin_dir/afu/lpc/lpc_bulk_mem.v"]"\
 "[file normalize "$origin_dir/afu/lpc/lpc_cmdfifo.v"]"\
 "[file normalize "$origin_dir/afu/lpc/lpc_errary.v"]"\
 "[file normalize "$origin_dir/afu/lpc/oc_function.v"]"\
 "[file normalize "$origin_dir/afu/lpc/lpc_mmio_regs.v"]"\
 "[file normalize "$origin_dir/afu/lpc/lpc_respfifo.v"]"\
 "[file normalize "$origin_dir/afu/lpc/lpc_sparse.v"]"\
 "[file normalize "$origin_dir/afu/lpc/lpc_tlx_afu_credit_mgr.v"]"\
]
set verilog_xlx     [list ""]

# Select to correct afu to build with.  config is common to all AFUs
set verilog_AFU [list {*}$verilog_cfg]
if {$afu eq "mcp"} {
    set verilog_AFU [list {*}$verilog_AFU {*}$verilog_mcp]
} elseif { $afu eq "lpc" } {
    set verilog_AFU [list {*}$verilog_AFU {*}$verilog_lpc]
} elseif { ($afu eq "afp") || ($afu eq "dual_afp") } {
    set verilog_AFU [list {*}$verilog_AFU {*}$verilog_afp]
} elseif { $afu eq "xlx" } {
    set verilog_AFU [list {*}$verilog_AFU {*}$verilog_xlx]
}

set verilog_board_support [list \
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/hdk_top/oc_fpga_top.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/oc_bsp.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/cfg_tieoffs.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/vpd_stub.v"]"\
"[file normalize "$origin_dir/board_support_packages/$card/verilog/iprog_icap.vhdl"]"\
]

# Xilinx Example Design Wrappers for either buffer bypass or elastic buffer
set buffer_bypass_type  ""
set elastic_buffer_type ""
if { $use_unencrypted eq "false"} {
    set buffer_bypass_type  "encrypted_buffer_bypass"
    set elastic_buffer_type "encrypted_elastic_buffer"
} else {
    set buffer_bypass_type  "buffer_bypass"
    set elastic_buffer_type "elastic_buffer"
}
set verilog_bypass  [list \
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_bit_sync.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_gtwiz_userclk_tx.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_init.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_reset_sync.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_wrapper_functions.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_wrapper.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_gtwiz_buffbypass_rx.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_gtwiz_buffbypass_tx.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_gtwiz_reset.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/dlx_phy_wrap.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/tx_mod_da_fsm.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/drp_read_modify_write.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${buffer_bypass_type}/DLx_phy_example_reset_inv_sync.v"]"\
]
set verilog_elastic [list \
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${elastic_buffer_type}/DLx_phy_example_bit_sync.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${elastic_buffer_type}/DLx_phy_example_gtwiz_userclk_tx.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${elastic_buffer_type}/DLx_phy_example_init.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${elastic_buffer_type}/DLx_phy_example_reset_sync.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${elastic_buffer_type}/DLx_phy_example_wrapper_functions.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${elastic_buffer_type}/DLx_phy_example_wrapper.v"]"\
 "[file normalize "$origin_dir/board_support_packages/$card/verilog/xilinx/${elastic_buffer_type}/dlx_phy_wrap.v"]"\
]

# Add correct transceiver type to list as well as flash if necessary
set config_setting ""
if {$transceiver_type eq "bypass"} {
    set verilog_board_support [list {*}$verilog_board_support {*}$verilog_bypass]
    set config_setting "buffer_bypass"
} else {
    set verilog_board_support [list {*}$verilog_board_support {*}$verilog_elastic]
    set config_setting "elastic_buffer"
}

if {$use_flash ne ""} {
    set verilog_board_support [list {*}$verilog_board_support {*}$verilog_flash]
    # Ignore the following flash message since XDC handles this warning properly
    set_msg_config -suppress -id {Constraints 18-514} -string "CRITICAL WARNING: \[Constraints 18-514\] set_max_delay: Path segmentation by forcing 'bsp/FLASH/STARTUP/USRCCLKO' to be timing endpoint. There will be no hold timing paths to this pin unless set_min_delay is used to constrain the paths. \[/afs/rchland.ibm.com/rel/common/proj/eclipz/c14/usr/us6g0694/p9nd2/extra1/dev/OpenCapiBuilds/board_support_packages/${card}/xdc/qspi_timing.xdc:29\]
        Resolution: Use valid endpoint to avoid path segmentation such as the data pin of a register."
}


# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/viv_proj"]"

# Create project
create_project $proj $orig_proj_dir -part $fpga

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Reconstruct message rules
# None

# Set project properties
set obj [get_projects viv_proj]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/viv_proj.cache/ip" -objects $obj
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object, create list of all nececessary verilog files
set obj [get_filesets sources_1]

set files [list {*}$verilog_DLx {*}$verilog_TLx {*}$verilog_AFU {*}$verilog_board_support]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for remote files
# None

# Set 'sources_1' fileset file properties for local files
set file "DLx_phy_example_wrapper_functions.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "cfg_func1_init.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "cfg_func0_init.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj


# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "oc_fpga_top" -objects $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Initial list of XDC files to use
if {$afu eq "dual_afp" } {
    set xdc_files [list \
                       "[file normalize "$origin_dir/board_support_packages/$card/xdc/dual/dual_main_pinout.xdc"]" \
                       "[file normalize "$origin_dir/board_support_packages/$card/xdc/dual/dual_main_timing.xdc"]" \
                       "[file normalize "$origin_dir/board_support_packages/$card/xdc/extra.xdc"]" \
                   ]
} else {
    set xdc_files [list \
                       "[file normalize "$origin_dir/board_support_packages/$card/xdc/main_pinout.xdc"]" \
                       "[file normalize "$origin_dir/board_support_packages/$card/xdc/main_timing.xdc"]" \
                       "[file normalize "$origin_dir/board_support_packages/$card/xdc/extra.xdc"]" \
                   ]
}

# Additional XDC to add based on specified modes
if { ($transceiver_type eq "bypass") && ($afu eq "dual_afp") } {
    set xdc_files [list {*}$xdc_files \
                         "[file normalize "$origin_dir/board_support_packages/$card/xdc/main_placement_bypass.xdc"]" \
                         "[file normalize "$origin_dir/board_support_packages/$card/xdc/dual/dual_gty_properties.xdc"]" \
                   ]
} elseif {$transceiver_type eq "bypass" } {
    set xdc_files [list {*}$xdc_files \
                         "[file normalize "$origin_dir/board_support_packages/$card/xdc/main_placement_bypass.xdc"]" \
                         "[file normalize "$origin_dir/board_support_packages/$card/xdc/gty_properties.xdc"]" \
                   ]
} else {
    set xdc_files [list {*}$xdc_files \
                         "[file normalize "$origin_dir/board_support_packages/$card/xdc/main_placement_elastic.xdc"]" \
                   ]
}

if {$use_flash ne ""} {
    set xdc_files [list {*}$xdc_files \
                         "[file normalize "$origin_dir/board_support_packages/$card/xdc/qspi_pinout.xdc"]" \
                         "[file normalize "$origin_dir/board_support_packages/$card/xdc/qspi_timing.xdc"]" \
                   ]
}

# Add all XDC files to project
foreach item $xdc_files {
    puts $item
    set file $item
    set file_added [add_files -norecurse -fileset $obj $file]
    set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]

    if {[string first "afu_placement" $file] != -1} {
        set_property -name "file_type"          -value "TCL"   -objects $file_obj
        set_property -name "used_in_simulation" -value "false" -objects $file_obj

    } else {
        set_property -name "file_type"          -value "XDC"   -objects $file_obj
    }
}

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property -name "target_constrs_file" -value "[file normalize "$origin_dir/board_support_packages/$card/xdc/extra.xdc"]" -objects $obj


# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "oc_fpga_top" -objects $obj

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part $fpga -flow {Vivado Synthesis 2018} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2018" [get_runs synth_1]
}

# Change initial synthesis strategy to aggressive if MCP is selected
if {$afu eq "mcp"} {
  set_property strategy "Flow_PerfOptimized_high" [get_runs synth_1]
}

set synth_verilog_defines ""
if {$transceiver_speed == [lindex $transceiver_speeds 0]} {set synth_verilog_defines [concat $synth_verilog_defines "DFE"]}
if {$transceiver_type  eq [lindex $transceiver_types  0]} {set synth_verilog_defines [concat $synth_verilog_defines "BUFFER_BYPASS"]}
if {$transceiver_type  eq [lindex $transceiver_types  1]} {set synth_verilog_defines [concat $synth_verilog_defines "BUFFER_ELASTIC"]}
if {$use_flash         ne ""                            } {set synth_verilog_defines [concat $synth_verilog_defines "FLASH"] }

# Define the selected AFU to build
if {$afu eq "dual_afp"} {
    set synth_verilog_defines [concat $synth_verilog_defines "[string toupper $afu] DUAL_AFU AFP"]
} else {
    set synth_verilog_defines [concat $synth_verilog_defines "[string toupper $afu]"]
}

set obj [get_runs synth_1]
set_property -name "part" -value "$fpga" -objects $obj
set_property verilog_define "$synth_verilog_defines" [get_filesets sources_1]
set_property verilog_define "$synth_verilog_defines" [get_filesets sim_1]

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part $fpga -flow {Vivado Implementation 2018} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2018" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0" -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0" -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj


# Create 'impl_2' run (if not found)
if {[string equal [get_runs -quiet impl_2] ""]} {
  create_run -name impl_2 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_ExplorePostRoutePhysOpt" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_2]
  set_property flow "Vivado Implementation 2018" [get_runs impl_2]
}
set obj [get_runs impl_2]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.opt_design.args.directive"                 -value "Explore"      -objects $obj
set_property -name "steps.place_design.args.directive"               -value "Explore"      -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"            -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "Explore"      -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"      -objects $obj
set_property -name "steps.route_design.args.more options"            -value "-tns_cleanup" -objects $obj
set_property -name "steps.post_route_phys_opt_design.is_enabled"     -value "1"            -objects $obj
set_property -name "steps.post_route_phys_opt_design.args.directive" -value "Explore"      -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"            -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"            -objects $obj
set_property -name "STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST"       -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj
# Create 'impl_3' run (if not found)
if {[string equal [get_runs -quiet impl_3] ""]} {
  create_run -name impl_3 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_WLBlockPlacement" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_WLBlockPlacement" [get_runs impl_3]
  set_property flow "Vivado Implementation 2018" [get_runs impl_3]
}
set obj [get_runs impl_3]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "WLDrivenBlockPlacement" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                      -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "AlternateReplication"   -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"                -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                      -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                      -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_4' run (if not found)
if {[string equal [get_runs -quiet impl_4] ""]} {
  create_run -name impl_4 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_WLBlockPlacementFanoutOpt" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_WLBlockPlacementFanoutOpt" [get_runs impl_4]
  set_property flow "Vivado Implementation 2018" [get_runs impl_4]
}
set obj [get_runs impl_4]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "WLDrivenBlockPlacement" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                      -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "AggressiveFanoutOpt"    -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"                -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                      -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                      -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_5' run (if not found)
if {[string equal [get_runs -quiet impl_5] ""]} {
  create_run -name impl_5 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_EarlyBlockPlacement" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_EarlyBlockPlacement" [get_runs impl_5]
  set_property flow "Vivado Implementation 2018" [get_runs impl_5]
}
set obj [get_runs impl_5]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "EarlyBlockPlacement" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                   -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "Explore"             -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"             -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                   -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                   -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_6' run (if not found)
if {[string equal [get_runs -quiet impl_6] ""]} {
  create_run -name impl_6 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_NetDelay_high" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_NetDelay_high" [get_runs impl_6]
  set_property flow "Vivado Implementation 2018" [get_runs impl_6]
}
set obj [get_runs impl_6]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "ExtraNetDelay_high" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                  -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "AggressiveExplore"  -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"            -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                  -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                  -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_7' run (if not found)
if {[string equal [get_runs -quiet impl_7] ""]} {
  create_run -name impl_7 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_NetDelay_low" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_NetDelay_low" [get_runs impl_7]
  set_property flow "Vivado Implementation 2018" [get_runs impl_7]
}
set obj [get_runs impl_7]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "ExtraNetDelay_low" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                 -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "AggressiveExplore" -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"           -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                 -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                 -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_8' run (if not found)
if {[string equal [get_runs -quiet impl_8] ""]} {
  create_run -name impl_8 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_Retiming" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_Retiming" [get_runs impl_8]
  set_property flow "Vivado Implementation 2018" [get_runs impl_8]
}
set obj [get_runs impl_8]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "ExtraPostPlacementOpt"     -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                         -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "AlternateFlowWithRetiming" -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"                   -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                         -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                         -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_9' run (if not found)
if {[string equal [get_runs -quiet impl_9] ""]} {
  create_run -name impl_9 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_ExtraTimingOpt" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_ExtraTimingOpt" [get_runs impl_9]
  set_property flow "Vivado Implementation 2018" [get_runs impl_9]
}
set obj [get_runs impl_9]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "ExtraTimingOpt" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"              -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "Explore"        -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"        -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"              -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"              -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_10' run (if not found)
if {[string equal [get_runs -quiet impl_10] ""]} {
  create_run -name impl_10 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_RefinePlacement" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_RefinePlacement" [get_runs impl_10]
  set_property flow "Vivado Implementation 2018" [get_runs impl_10]
}
set obj [get_runs impl_10]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "ExtraPostPlacementOpt" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                     -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "Explore"               -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"               -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                     -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                     -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_11' run (if not found)
if {[string equal [get_runs -quiet impl_11] ""]} {
  create_run -name impl_11 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_SpreadSLLs" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_SpreadSLLs" [get_runs impl_11]
  set_property flow "Vivado Implementation 2018" [get_runs impl_11]
}
set obj [get_runs impl_11]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "SSI_SpreadSLLs" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"              -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "Explore"        -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"        -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"              -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"              -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_12' run (if not found)
if {[string equal [get_runs -quiet impl_12] ""]} {
  create_run -name impl_12 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_BalanceSLLs" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_BalanceSLLs" [get_runs impl_12]
  set_property flow "Vivado Implementation 2018" [get_runs impl_12]
}
set obj [get_runs impl_12]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "SSI_BalanceSLLs" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"               -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "Explore"         -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"         -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"               -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"               -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_13' run (if not found)
if {[string equal [get_runs -quiet impl_13] ""]} {
  create_run -name impl_13 -part $fpga -flow {Vivado Implementation 2018} -strategy "Congestion_SpreadLogic_high" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Congestion_SpreadLogic_high" [get_runs impl_13]
  set_property flow "Vivado Implementation 2018" [get_runs impl_13]
}
set obj [get_runs impl_13]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "AltSpreadLogic_high" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                   -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "AggressiveExplore"   -objects $obj
set_property -name "steps.route_design.args.directive"               -value "AlternateCLBRouting" -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                   -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                   -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_14' run (if not found)
if {[string equal [get_runs -quiet impl_14] ""]} {
  create_run -name impl_14 -part $fpga -flow {Vivado Implementation 2018} -strategy "Congestion_SpreadLogic_medium" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Congestion_SpreadLogic_medium" [get_runs impl_14]
  set_property flow "Vivado Implementation 2018" [get_runs impl_14]
}
set obj [get_runs impl_14]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "AltSpreadLogic_medium" -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                     -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "Explore"               -objects $obj
set_property -name "steps.route_design.args.directive"               -value "AlternateCLBRouting"   -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                     -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                     -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_15' run (if not found)
if {[string equal [get_runs -quiet impl_15] ""]} {
  create_run -name impl_15 -part $fpga -flow {Vivado Implementation 2018} -strategy "Congestion_SpreadLogic_low" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Congestion_SpreadLogic_low" [get_runs impl_15]
  set_property flow "Vivado Implementation 2018" [get_runs impl_15]
}
set obj [get_runs impl_15]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "AltSpreadLogic_low"  -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                   -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "Explore"             -objects $obj
set_property -name "steps.route_design.args.directive"               -value "AlternateCLBRouting" -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                   -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                   -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# Create 'impl_16' run (if not found)
if {[string equal [get_runs -quiet impl_16] ""]} {
  create_run -name impl_16 -part $fpga -flow {Vivado Implementation 2018} -strategy "Performance_HighUtilSLRs" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Congestion_SpreadLogic_Explore" [get_runs impl_16]
  set_property flow "Vivado Implementation 2018" [get_runs impl_16]
}
set obj [get_runs impl_16]
set_property -name "part" -value "$fpga" -objects $obj
set_property -name "steps.place_design.args.directive"               -value "SSI_HighUtilSLRs"    -objects $obj
set_property -name "steps.phys_opt_design.is_enabled"                -value "1"                   -objects $obj
set_property -name "steps.phys_opt_design.args.directive"            -value "Explore"             -objects $obj
set_property -name "steps.route_design.args.directive"               -value "Explore"             -objects $obj
set_property -name "steps.write_bitstream.args.readback_file"        -value "0"                   -objects $obj
set_property -name "steps.write_bitstream.args.verbose"              -value "0"                   -objects $obj
set_property -name "STEPS.ROUTE_DESIGN.TCL.POST"                     -value "${origin_dir}/tcl/write_bitstream.tcl" -objects $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:viv_proj"

# Generate board specific IP
source $origin_dir/board_support_packages/$card/ip/create_vio_DLx_phy_vio_0.tcl
source $origin_dir/board_support_packages/$card/ip/create_vio_reset_n.tcl
source $origin_dir/board_support_packages/$card/ip/create_DLx_PHY_${transceiver_type}_${transceiver_speed}g.tcl

if {$use_flash ne ""} {
    source $origin_dir/board_support_packages/$card/ip/axi_quad_spi.tcl
    source $origin_dir/board_support_packages/$card/ip/axi_hwicap.tcl
}

# Generate all AFU specific IP
foreach tcl_ip [glob -nocomplain -path ${origin_dir}/afu/${afu}/ip/ *.tcl] {
    source $tcl_ip
}

# Create global variable to pass to the following tcl script
set cfg_file_transceiver_speed [string map {.    _ } $transceiver_speed         ]
set cfg_file_transceiver_speed [string map {20_0 20} $cfg_file_transceiver_speed]
set ::config_contents "${afu}|${config_setting}|${cfg_file_transceiver_speed}g|${card}";
source $origin_dir/tcl/write_proj_config.tcl;
