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



include $(OC_BIP_ROOT)/scripts/oc_bsp_env.mk


.PHONY: help create_ip unit_sim clean


help:
	@echo "Main targets for the $(FPGA_CARD) capi_board_support project make process:";
	@echo "====================================================================";
	@echo "* create_ip      Create capi_bsp ip for $(FPGA_DISPLAY) card";
	@echo "* clean          Remove all files generated in make process";
	@echo "* help           Print this message";
	@echo;


all: create_ip unit_sim


# Disabling implicit rule for shell scripts
%: %.sh


$(OC_BSP_LOGS):
	@mkdir -p $(OC_BSP_LOGS)


$(OC_BSP_GEN): $(OC_BSP_LOGS)
	@echo "[PREPARE DIRECTORIES.] start "`date +"%T %a %b %d %Y"`
	@mkdir -p $(OC_BSP_GEN)
	@echo "[PREPARE DIRECTORIES.] done  "`date +"%T %a %b %d %Y"`


$(BUILD_DIR)/.create_ip_done: $(OC_BSP_GEN) 
	@if [ -e $(BUILD_DIR)/.create_ip_done ]; then \
	    $(MAKE) clean || exit -1; \
	    echo "[RE-CREATE IP........] start "`date +"%T %a %b %d %Y"`; \
	    $(MAKE) $(OC_BSP_GEN);\
	fi
	@echo "	                Starting vivado in $(VIVADO_MODE) mode ..."
	@vivado -quiet -mode $(VIVADO_MODE) -source $(COMMON_TCL)/create_oc_bsp.tcl -notrace -log $(OC_BSP_LOGS)/vivado_create_project.log  -journal $(OC_BSP_LOGS)/vivado_create_project.jou
	@touch $(BUILD_DIR)/.create_ip_done

$(BUILD_DIR)/.create_ip_unit_sim_done: $(OC_BSP_GEN) 
	@if [ -e $(BUILD_DIR)/.create_ip_unit_sim_done ]; then \
	    $(MAKE) clean || exit -1; \
	    echo "[RE-CREATE IP........] start "`date +"%T %a %b %d %Y"`; \
	    $(MAKE) $(OC_BSP_GEN);\
	fi
	@echo "	                Starting vivado in $(VIVADO_MODE) mode ..."
	@vivado -quiet -mode $(VIVADO_MODE) -source $(COMMON_TCL)/create_oc_bsp_unit_sim.tcl -notrace -log $(OC_BSP_LOGS)/vivado_create_project.log  -journal $(OC_BSP_LOGS)/vivado_create_project.jou
	@touch $(BUILD_DIR)/.create_ip_unit_sim_done

create_ip: $(BUILD_DIR)/.create_ip_done
unit_sim: $(BUILD_DIR)/.create_ip_unit_sim_done


clean:
	@$(RM) *~
	@$(RM) .create_ip_done
	@$(RM) -r vivado.*
	@$(RM) -r build
	@$(RM) -r .Xil
