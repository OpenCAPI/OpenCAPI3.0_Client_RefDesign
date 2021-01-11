############################################################################
############################################################################
##
## Copyright 2018 Alpha Data Parallel Systems Ltd.
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

#set_false_path -from [get_clocks dbg_hub_APB_0_PCLK] -to [get_clocks txoutclk_out[0]_1]

set_false_path -from [get_clocks oc0_clock_afu] -to [get_clocks txoutclk_out[0]_1]
set_false_path -from [get_clocks refclk_bufg_apb_clk_BUFGCE_O] -to [get_clocks oc0_clock_afu]
set_false_path -from [get_clocks refclk_bufg_apb_clk_BUFGCE_O] -to [get_clocks txoutclk_out[0]_1]
set_false_path -from [get_clocks oc0_clock_afu] -to [get_clocks refclk_bufg_apb_clk_BUFGCE_O]
set_false_path -from [get_clocks txoutclk_out[0]_1] -to [get_clocks refclk_bufg_apb_clk_BUFGCE_O]

#--START--emoved temporarily for PR 
## Pblock for placing all logic in SLR1 except for HBM controller
#create_pblock pblock_1
#resize_pblock pblock_1 -add CLOCKREGION_X0Y4:CLOCKREGION_X1Y7
#add_cells_to_pblock pblock_1 [get_cells [list dbg_hub bsp?/dlx_phy bsp?/DLx_phy_vio_0_inst bsp?/vio_reset_n_inst_tlx bsp?/tlx]]

#remove_cells_from_pblock pblock_1 [get_cells bsp?/dlx_phy/BUFGCE_DIV_inst]

#create_pblock pblock_2
#resize_pblock pblock_2 -add CLOCKREGION_X2Y4:CLOCKREGION_X7Y7
#add_cells_to_pblock pblock_2 [get_cells [list cfg? oc_func?/cfg_f1 oc_func?/fw_afu/action_w oc_func?/fw_afu/hbm_top_wrapper_i oc_func?/fw_afu/desc oc_func?/fw_afu/mvio_soft_reset oc_func?/fw_afu/snap_core_i]]
#remove_cells_from_pblock pblock_2 [get_cells oc_func?/fw_afu/hbm_top_wrapper_i/hbm_top_i/hbm]

##set_false_path -from [get_pins { dbg_hub/inst/BSCANID.u_xsdbm_id/CORE_XSDB.UUT_MASTER/U_XSDB_ADDRESS
##set_false_path -to [get_pins {oc_func0/fw_afu/hbm_top_wrapper_i/hbm_top_i/hbm/inst/TWO_STACK.u_hbm_t
#--END--removed temporarily for PR
set_false_path -from [get_pins { bsp0/tlx/OCX_TLX_FRAMER/por_on_reg/C }]
