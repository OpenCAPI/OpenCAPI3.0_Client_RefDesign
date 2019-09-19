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

#Adding source files
#add_files -scan_for_includes $common_src >> $log_file
#add_files -scan_for_includes $dlxtlx_dir >> $log_file


#create_fileset -srcset sources_0

############################################################################
#                                                                          #
# Add encrypted DLx/TLx sources                                            #
#                                                                          #
############################################################################
add_files -scan_for_includes $dlx_dir >> $log_file
add_files -scan_for_includes $tlx_dir >> $log_file


############################################################################
#                                                                          #
# Add config subsystem sources                                             #
#                                                                          #
############################################################################
#add_files -scan_for_includes $cfg_src >> $log_file


############################################################################
#                                                                          #
# Add card specific sources                                                #
#                                                                          #
############################################################################
add_files -scan_for_includes $card_src/cfg_reg_to_axi4lite.v >> $log_file
add_files -scan_for_includes $card_src/flash_sub_system.v >> $log_file
add_files -scan_for_includes $card_src/oc_bsp.v >> $log_file
add_files -scan_for_includes $card_src/vpd_stub.v >> $log_file
if {$transceiver_type eq "bypass"} {
    add_files -scan_for_includes $card_src/xilinx/encrypted_buffer_bypass >> $log_file
} else {
   add_files -scan_for_includes $card_src/xilinx/encrypted_elastic_buffer >> $log_file
}

