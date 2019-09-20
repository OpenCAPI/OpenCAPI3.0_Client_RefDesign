############################################################################
############################################################################
##
## Copyright 2018 International Business Machines
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

set ip_dir           $::env(OC_BSP_IP)
set card_ip_dir      $::env(CARD_IP)
set dlx_dir          $::env(DLx_DIR)
set tlx_dir          $::env(TLx_DIR)
set oc_bsp_gen_dir   $::env(OC_BSP_GEN)
set oc_bsp_version   $::env(OC_BSP_VERSION)
set fpga_card        $::env(FPGA_CARD)
set fpga_part        $::env(FPGA_PART)
set proj_dir         $::env(BUILD_DIR)/viv_project
set common_tcl       $::env(COMMON_TCL)
set oc_bsp_xdc       $::env(OC_BSP_XDC)
set top_level        oc_bsp
set proj_name        oc_board_support_package
set cfg_src          $::env(CFG_DIR)
set card_dir         $::env(CARD_DIR)
set card_src         $::env(CARD_SRC)
set use_flash        "true"
set transceiver_type "bypass"
set transceiver_speed "25.78125"

source $common_tcl/create_ip.tcl

set log_file $::env(OC_BSP_LOGS)/create_oc_bsp.log
## Create a new Vivado IP Project
puts "\[CREATE OC BSP.......\] start [clock format [clock seconds] -format {%T %a %b %d %Y}]"
create_project $proj_name $proj_dir -part $fpga_part -force >> $log_file

#Add source files
puts "	                Adding design sources to oc_bsp project"
source $common_tcl/add_src.tcl

if { $use_flash ne "" } {
    puts "    Flashing logic is enabled"
} else {
    puts "    Flashing logic is disabled"
}

puts "    buffer...........[string toupper $transceiver_type]"
set_property top $top_level [current_fileset]

# Add card specific IP
if [file exists $common_tcl/add_card_ip.tcl] {
  puts "	                Adding $fpga_card specific IP to oc_bsp project"
  source $common_tcl/add_card_ip.tcl
}

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

if {$use_flash ne ""} {
    set xdc_files [list {*}$xdc_files \
                         "[file normalize "$oc_bsp_xdc/qspi_pinout.xdc"]" \
                         "[file normalize "$oc_bsp_xdc/qspi_timing.xdc"]" \
                   ]
}

puts "	                Adding constraints to oc_bsp project"
foreach xdc_files [glob -nocomplain -dir $oc_bsp_xdc *] {
  add_files -fileset constrs_1 -norecurse $xdc_files >> $log_file
}

#### Package project as IP
#puts "	                Packaging oc_bsp project as IP"
#update_compile_order -fileset sources_1 >> $log_file
#ipx::package_project -root_dir $oc_bsp_gen_dir -vendor ibm.com -library OpenCAPI -taxonomy /UserIP -import_files -force >> $log_file
#set_property sim.ip.auto_export_scripts false [current_project] >> $log_file
#
#set_property version $oc_bsp_version [ipx::current_core] >> $log_file
#set_property vendor_display_name IBM [ipx::current_core] >> $log_file
#set_property supported_families {zynquplus Production virtexuplus Production kintexuplus Production virtexuplushbm Production } [ipx::current_core] >> $log_file
#set_property core_revision 1 [ipx::current_core] >> $log_file
#ipx::create_xgui_files [ipx::current_core] >> $log_file
#ipx::update_checksums [ipx::current_core] >> $log_file
#ipx::save_core [ipx::current_core] >> $log_file
#ipx::check_integrity [ipx::current_core] >> $log_file
#
#
#### Add oc_bsp IP path to IP repository paths
#set_property ip_repo_paths [file normalize $oc_bsp_gen_dir] [current_project] >> $log_file
#### Rebuild user ip_repo's index before creating IP container
#update_ip_catalog >> $log_file
#
#puts "	                Generating oc_bsp IP"
#create_ip -name oc_bsp -vendor ibm.com -library OpenCAPI -version $oc_bsp_version -module_name oc_bsp_wrap -dir $ip_dir >> $log_file
#set_property generate_synth_checkpoint false [get_files oc_bsp_wrap.xci] >> $log_file
#set_property used_in_simulation false [get_files oc_bsp_wrap.xci] >> $log_file
#generate_target all [get_files oc_bsp_wrap.xci] >> $log_file
#
#set oc_bsp_ip_dir $ip_dir/oc_bsp_wrap

#puts "	                Creating oc_bsp IP container"
#convert_ips -to_core_container [get_files $oc_bsp_ip_dir/oc_bsp_wrap.xci] >> $log_file

close_project >> $log_file

#if [file exists $ip_dir/oc_bsp_wrap.xcix] {
#  puts "	                Created $ip_dir/oc_bsp_wrap.xcix"
#} else {
#    puts "	         ERROR: no oc_bsp_wrap.xcix file created!!!"
#}
puts "\[CREATE OC BSP.......\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
