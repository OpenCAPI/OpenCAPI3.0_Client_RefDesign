###############################################################
## FPGA: xcvu3p-ffvc1517-2-i
###############################################################

# Configuration from SPI Flash as per XAPP1233
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]



set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable [current_design]

set_property CLOCK_DELAY_GROUP group1 [get_nets bsp/dlx_phy/example_wrapper_inst/gtwiz_userclk_tx_inst/tx_clk_201MHz]
set_property CLOCK_DELAY_GROUP group1 [get_nets {bsp/dlx_phy/example_wrapper_inst/gtwiz_userclk_tx_inst/rxusrclk2_in[0]}]
set_property CLOCK_DELAY_GROUP group1 [get_nets bsp/dlx_phy/example_wrapper_inst/gtwiz_userclk_tx_inst/tx_clk_100MHz]
# Pblock for placing VIO IPs and Debug Hub IP closer to DLx logic. This Pblock includes everything in the design except for a couple of I/O and clock buffers and BSCAN primitives which are constrained outside of this Pblock
#create_pblock pblock_1
#resize_pblock pblock_1 -add CLOCKREGION_X0Y6:CLOCKREGION_X0Y7
#add_cells_to_pblock pblock_1 [get_cells [list dbg_hub bsp/dlx_phy bsp/DLx_phy_vio_0_inst bsp/vio_reset_n_inst_tlx]]
#add_cells_to_pblock pblock_1 [get_cells [list dbg_hub bsp/dlx_phy]]


#remove_cells_from_pblock pblock_1 [get_cells [list bsp/dlx_phy/reset_clock_buf_inst bsp/dlx_phy/IBUFDS_GTE4_FREERUN_CLK_INST bsp/dlx_phy/BUFG_GT_SYNC]]



set_property EXTRACT_ENABLE false [get_cells {{bsp/dlx_phy/ocx_dlx_top_inst/rx/main/replay_deskew_cntr_q_reg[*]} {bsp/dlx_phy/ocx_dlx_top_inst/rx/lane?/ts1_cntr_q_reg[*]} {bsp/dlx_phy/ocx_dlx_top_inst/rx/lane?/lfsr_q_reg[*]} {bsp/dlx_phy/ocx_dlx_top_inst/rx/lane?/deskew_buffer?_q_reg[*]} {bsp/dlx_phy/ocx_dlx_top_inst/rx/main/crc_bits_q_reg[*]}}]


# 1024: Added more constraints to disable inference of enable/reset for some regs
set_property EXTRACT_ENABLE false [get_cells {bsp/tlx/OCX_TLX_FRAMER/cmd_cntl_flit_reg_reg[*]}]
set_property EXTRACT_ENABLE false [get_cells {bsp/tlx/OCX_TLX_FRAMER/vc0_fifo/valid_entry_counter_reg[*]}]
set_property EXTRACT_ENABLE false [get_cells {bsp/tlx/OCX_TLX_PARSER/TLX_Parser/flit_parser/ctl_flit_dout_reg[*]}]

set_property EXTRACT_RESET false [get_cells {bsp/tlx/OCX_TLX_PARSER/TLX_RCV_FIFO/CMD_FIFO_MAC/CMD_INFO_CTL/ctl_cnt_dout_reg[*]}]
set_property EXTRACT_RESET false [get_cells {bsp/dlx_phy/ocx_dlx_top_inst/tx/flt/pre_crc_data_q_reg[*]}]
set_property EXTRACT_RESET false [get_cells {bsp/tlx/OCX_TLX_PARSER/TLX_RCV_FIFO/RESP_FIFO_MAC/RESP_INFO_CTL/data_wr_cnt_dout_reg[*]}]
set_property EXTRACT_RESET false [get_cells {bsp/tlx/OCX_TLX_PARSER/TLX_RCV_FIFO/CMD_FIFO_MAC/CMD_INFO_CTL/data_wr_cnt_dout_reg[*]}]




####################################################################################
# Constraints from file : 'snap_ddr4_b0pins.xdc'
####################################################################################


set_power_opt -exclude_cells [get_cells bsp/dlx_phy/ocx_dlx_top_inst/tx/flt/bram/ram_sdp_reg_?]

####################################################################################
# Constraints from file : 'snap_ddr4_b0pins.xdc'
####################################################################################

