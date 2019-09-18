#
# Copyright 2018 International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

###########################################################################
##  File:          oc_bsp_env.mk
##  Description:    
###########################################################################


export DLx_DIR                 ?= $(OC_BIP_ROOT)/dlx
export TLx_DIR                 ?= $(OC_BIP_ROOT)/tlx
export CFG_DIR                 ?= $(OC_BIP_ROOT)/config_subsystem
export BUILD_DIR               ?= $(OC_BIP_ROOT)/build
export COMMON_TCL              ?= $(OC_BIP_ROOT)/tcl
export OC_BSP_GEN              ?= $(BUILD_DIR)/oc_bsp_gen
export OC_BSP_IP               ?= $(BUILD_DIR)/ip
export CARD_IP                 ?= $(BUILD_DIR)/ip/card_ip_project/card_ip_project.srcs/sources_1/ip
export OC_BSP_LOGS             ?= $(BUILD_DIR)/logs
export DLxTLx_VERSION          ?= 022
export OC_BSP_VERSION          ?= 1.00
export FPGA_CARD               ?= $@
export CARD_DIR                ?= $(OC_BIP_ROOT)/board_support_packages/$(FPGA_CARD)
export CARD_SRC                ?= $(CARD_DIR)/verilog
export OC_BSP_XDC              ?= $(CARD_DIR)/xdc
export VIVADO_MODE             ?= batch

