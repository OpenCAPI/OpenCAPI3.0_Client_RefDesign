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

set_false_path -from [get_clocks dbg_hub_APB_0_PCLK] -to [get_clocks txoutclk_out[0]_1]
set_false_path -from [get_clocks oc0_clock_afu] -to [get_clocks txoutclk_out[0]_1]
set_false_path -from [get_clocks hbm_ctrl_apb_pclk] -to [get_clocks oc0_clock_afu]
set_false_path -from [get_clocks hbm_ctrl_apb_pclk] -to [get_clocks txoutclk_out[0]_1]
set_false_path -from [get_clocks oc0_clock_afu] -to [get_clocks hbm_ctrl_apb_pclk]
set_false_path -from [get_clocks txoutclk_out[0]_1] -to [get_clocks hbm_ctrl_apb_pclk]

# Pblock for placing all logic in SLR1 except for HBM controller
create_pblock pblock_1
resize_pblock pblock_1 -add CLOCKREGION_X0Y4:CLOCKREGION_X1Y7
add_cells_to_pblock pblock_1 [get_cells [list dbg_hub bsp?/dlx_phy bsp?/DLx_phy_vio_0_inst bsp?/vio_reset_n_inst_tlx bsp?/tlx]]

remove_cells_from_pblock pblock_1 [get_cells dbg_hub/inst/BSCANID.u_xsdbm_id/SWITCH_N_EXT_BSCAN.u_bufg_icon_tck]
remove_cells_from_pblock pblock_1 [get_cells bsp?/dlx_phy/BUFGCE_DIV_inst]
remove_cells_from_pblock pblock_1 [get_cells dbg_hub/inst/BSCANID.u_xsdbm_id/SWITCH_N_EXT_BSCAN.bscan_inst/SERIES7_BSCAN.bscan_inst]

create_pblock pblock_2
resize_pblock pblock_2 -add CLOCKREGION_X2Y4:CLOCKREGION_X7Y7
add_cells_to_pblock pblock_2 [get_cells [list cfg? oc_func?/cfg_f1 oc_func?/fw_afu/action_w oc_func?/fw_afu/axi_dwidth_converter_act2hbm oc_func?/fw_afu/desc oc_func?/fw_afu/mvio_soft_reset oc_func?/fw_afu/snap_core_i]]
