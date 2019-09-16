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

set fpga_ip_dir      $::env(CARD_DIR)/ip

## Create a new Vivado IP Project
set log_file $::env(OC_BSP_LOGS)/create_required_ip.log
puts "\[CREATE REQUIRED IP FOR UNIT SIM..\] start [clock format [clock seconds] -format {%T %a %b %d %Y}]"
create_project managed_ip_project $ip_dir/managed_ip_project -force -part $fpga_part -ip >> $log_file

# Project IP Settings
# General
set_property target_language VERILOG [current_project]


####################################################################################################
#                                                                                                  #
#        Create axi_hwicap IP from Xilinx IP Catalog                                               #
#                                                                                                  #
####################################################################################################

set ip_name axi_hwicap_0
puts "	                generating $ip_name"
source $fpga_ip_dir/axi_hwicap.tcl 
set_property generate_synth_checkpoint false [get_files $ip_name.xci] >> $log_file


####################################################################################################
#                                                                                                  #
#        Create axi_quad_spi IP from Xilinx IP Catalog                                             #
#                                                                                                  #
####################################################################################################

set ip_name axi_quad_spi_0
puts "	                generating $ip_name"
source $fpga_ip_dir/axi_quad_spi.tcl 
set_property generate_synth_checkpoint false [get_files $ip_name.xci] >> $log_file

####################################################################################################
#                                                                                                  #
#        Create vio_reset IP from Xilinx IP Catalog                                                #
#                                                                                                  #
####################################################################################################

set ip_name vio_reset_n
puts "	                generating $ip_name"
source $fpga_ip_dir/create_vio_reset_n.tcl 
set_property generate_synth_checkpoint false [get_files $ip_name.xci] >> $log_file

####################################################################################################
#                                                                                                  #
#        Create DLx_phy_VIO IP from Xilinx IP Catalog                                              #
#                                                                                                  #
####################################################################################################

set ip_name DLx_phy_vio_0
puts "	                generating $ip_name"
source $fpga_ip_dir/create_vio_DLx_phy_vio_0.tcl 
set_property generate_synth_checkpoint false [get_files $ip_name.xci] >> $log_file

close_project >> $log_file
#open_example_project -force -in_process -dir $ip_dir [get_ips  $ip_name]

puts "\[CREATE REQUIRED IP FOR UNIT SIM..\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
