# Following ports should be added as outputs in top level, and assigned to data outputs of AXI QSPI Core passed through IOBUF

# DQ[0-3] are connected through STARTUPE3 primitive
# set_property PACKAGE_PIN AW15 [get_ports FPGA_FLASH_DQ0]
# set_property PACKAGE_PIN AY15 [get_ports FPGA_FLASH_DQ1]
# set_property PACKAGE_PIN AY14 [get_ports FPGA_FLASH_DQ2]
# set_property PACKAGE_PIN AY13 [get_ports FPGA_FLASH_DQ3]
set_property PACKAGE_PIN BE45 [get_ports FPGA_FLASH_DQ4]
set_property PACKAGE_PIN BE46 [get_ports FPGA_FLASH_DQ5]
set_property PACKAGE_PIN BF42 [get_ports FPGA_FLASH_DQ6]
set_property PACKAGE_PIN BF43 [get_ports FPGA_FLASH_DQ7]

# Slave select output of AXI QSPI Core
# FPGA_FLASH_CE1_L USER MANUAL states 0 and 1.  Use the upper (1) pinout since 0 is controlled through startupe3 primitive
set_property PACKAGE_PIN BP47 [get_ports FPGA_FLASH_CE2_L]

# set_property IOSTANDARD LVCMOS18 [get_ports FPGA_FLASH_DQ0]
# set_property IOSTANDARD LVCMOS18 [get_ports FPGA_FLASH_DQ1]
# set_property IOSTANDARD LVCMOS18 [get_ports FPGA_FLASH_DQ2]
# set_property IOSTANDARD LVCMOS18 [get_ports FPGA_FLASH_DQ3]
set_property IOSTANDARD LVCMOS18 [get_ports FPGA_FLASH_DQ4]
set_property IOSTANDARD LVCMOS18 [get_ports FPGA_FLASH_DQ5]
set_property IOSTANDARD LVCMOS18 [get_ports FPGA_FLASH_DQ6]
set_property IOSTANDARD LVCMOS18 [get_ports FPGA_FLASH_DQ7]
set_property IOSTANDARD LVCMOS18 [get_ports FPGA_FLASH_CE2_L]

# Adding pull-up as hardware misses them - 2021/02/08
set_property PULLTYPE PULLUP [get_ports FPGA_FLASH_DQ6]
set_property PULLTYPE PULLUP [get_ports FPGA_FLASH_DQ7]
set_property PULLTYPE PULLUP [get_ports FPGA_FLASH_CE2_L]
