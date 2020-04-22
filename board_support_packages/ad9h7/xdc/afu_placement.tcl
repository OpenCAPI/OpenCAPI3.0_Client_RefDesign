
# Check to see if MCP AFU is used
if { [get_cells -quiet MCP] eq "MCP" } {
    set_property EXTRACT_ENABLE NO [get_cells {MCP?/func_1_mcp3/afu_0_mcp3/cmdo/available_cmd_credit_q_reg[*]}]
    set_property EXTRACT_ENABLE NO [get_cells {MCP?/func_1_mcp3/afu_0_mcp3/cmdi_rspo/available_resp_credit_q_reg[*]}]
    set_property EXTRACT_ENABLE NO [get_cells {MCP?/func_1_mcp3/func_1_cfg/reg_csh_014_q_reg[*]}]
    set_property EXTRACT_RESET  NO [get_cells {MCP?/func_1_mcp3/afu_0_mcp3/rspi/fastpath_*_reg}]
} else {
    puts "No Cells Matched MCP"
}
