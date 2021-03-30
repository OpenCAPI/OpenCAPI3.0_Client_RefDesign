## LPC axi_hwicap
create_ip -name axi_hwicap -vendor xilinx.com -library ip -version 3.0 -module_name axi_hwicap_0
set_property -dict [list CONFIG.C_BRAM_SRL_FIFO_TYPE {0} CONFIG.C_ENABLE_ASYNC {1}] [get_ips axi_hwicap_0]
#set_property -dict [list CONFIG.C_ICAP_EXTERNAL {1}] [get_ips axi_hwicap_0] //change for PR
set_property -dict [list CONFIG.C_ICAP_EXTERNAL {0}] [get_ips axi_hwicap_0]
generate_target {all} [get_ips axi_hwicap_0]

#DBG create_ip -name dfx_bitstream_monitor -vendor xilinx.com -library ip -version 1.0 -module_name ICAP_monitor_0
#DBG set_property -dict [list CONFIG.DP_PROTOCOL {AXI4LITE}] [get_ips ICAP_monitor_0]
#DBG generate_target {all} [get_ips ICAP_monitor_0]

