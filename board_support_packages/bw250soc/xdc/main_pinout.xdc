###############################################################
## Placement Constraints: xcvu3p-ffvc1517
###############################################################

###############################################################
## Reset
###############################################################

set_property PACKAGE_PIN F13 [get_ports ocde]
set_property IOSTANDARD LVCMOS18 [get_ports ocde]

########################
## Bottom Left Corner ##
########################

# DLX0 Clocks
set_property PACKAGE_PIN T33 [get_ports mgtrefclk1_x0y0_n]
set_property PACKAGE_PIN T32 [get_ports mgtrefclk1_x0y0_p]
set_property PACKAGE_PIN Y33 [get_ports mgtrefclk1_x0y1_n]
set_property PACKAGE_PIN Y32 [get_ports mgtrefclk1_x0y1_p]

# Free run clock constraint
# page 13 adm-pcie-9v3 user manual.pdf
# Signal: FABRIC_CLK
#set_property PACKAGE_PIN AH9 [get_ports freerun_clk_n]
#set_property PACKAGE_PIN AH10 [get_ports freerun_clk_p]
#set_property PACKAGE_PIN J18 [get_ports freerun_clk_n]
#set_property PACKAGE_PIN J19 [get_ports freerun_clk_p]

#set_property IOSTANDARD  LVDS [get_ports freerun_clk_p]
#set_property IOSTANDARD  LVDS [get_ports freerun_clk_n]
