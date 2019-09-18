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

SHELL=/bin/bash
export OC_BIP_ROOT  = $(abspath .)
export SNAP_ROOT    = $(abspath .)/../../
snap_config_sh      = ../../.snap_config.sh
-include $(snap_config_sh)

export CARDS += ad9v3 ad9h3 ad9h7

SIM_SRC=$(OC_BIP_ROOT)/sim/src

.PHONY: help $(CARDS) unit_sim clean


help:
	@echo "Main targets for the OpenCAPI IP catalog make process:";
	@echo "======================================================";
	@echo "* ad9v3          Creates ip for AlphaData 9V3 card";
	@echo "* ad9h3          Creates ip for AlphaData 9H3 card";
	@echo "* ad9h7          Creates ip for AlphaData 9H7 card";
	@echo "* unit_sim       Creates ip for unit level simulation";
	@echo "* clean          Removes all files generated in make process";
	@echo "* help           Prints this message";
	@echo "* Example : make ad9v3";


all: $(CARDS) unit_sim


# Disabling implicit rule for shell scripts
%: %.sh


$(CARDS):
	@if [ -d board_support_packages/$@ ]; then                                  \
	    $(MAKE) -sC board_support_packages/$@ create_ip || exit -1;             \
	else                                                        \
	    echo "ERROR: Directory $@ doesn't exist. Terminating."; \
	    exit -1;                                                \
	fi
#	@echo "[CREATE SIM TOP............] start "`date +"%T %a %b %d %Y"`
#	$(SIM_SRC)/top_config.sh
#	@echo "[CREATE SIM TOP............] done  "`date +"%T %a %b %d %Y"`

unit_sim:
	@if [ -d board_support_packages/ad9v3 ]; then                                  \
	    $(MAKE) -sC board_support_packages/ad9v3 unit_sim || exit -1;             \
	else                                                        \
	    echo "ERROR: Directory ad9v3 doesn't exist. Terminating."; \
	    exit -1;                                                \
	fi
	# Take ad9v3 as the vehicle for unit simulation


clean:
	@echo "[CLEANING............] start "`date +"%T %a %b %d %Y"`
#	@for dir in $(CARDS); do                   \
#	    if [ -d $$dir/oc-bsp ]; then                  \
#	        $(MAKE) -s -C  $$dir/oc-bsp $@ || exit 1; \
#	    fi                                     \
#	done
	@$(RM) *~
	@$(RM) -rf $(OC_BIP_ROOT)/build
	@$(RM) $(SIM_SRC)/unit_top.sv
	@$(RM) -r vivado*
	@$(RM) -r .Xil
	@echo "[CLEANING............] done  "`date +"%T %a %b %d %Y"`
