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
set_false_path -from [get_clocks refclk_bufg_apb_clk_BUFGCE_O] -to [get_clocks txoutclk_out[0]_1]
set_false_path -from [get_clocks txoutclk_out[0]_1] -to [get_clocks refclk_bufg_apb_clk_BUFGCE_O]
