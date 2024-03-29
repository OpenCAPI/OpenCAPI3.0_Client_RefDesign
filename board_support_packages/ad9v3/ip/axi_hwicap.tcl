## LPC axi_hwicap
create_ip -name axi_hwicap -vendor xilinx.com -library ip -version 3.0 -module_name axi_hwicap_0
set_property -dict [list CONFIG.C_BRAM_SRL_FIFO_TYPE {0} CONFIG.C_ENABLE_ASYNC {1}] [get_ips axi_hwicap_0]
#For Partial reconfiguration, ICAP_EXTERNAL need to be set to 0 (vs 1) 
#set_property -dict [list CONFIG.C_ICAP_EXTERNAL {1}] [get_ips axi_hwicap_0]
set_property -dict [list CONFIG.C_ICAP_EXTERNAL {0}] [get_ips axi_hwicap_0]
generate_target {all} [get_ips axi_hwicap_0]
