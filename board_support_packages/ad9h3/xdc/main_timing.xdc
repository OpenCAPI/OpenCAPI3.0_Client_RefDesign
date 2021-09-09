###############################################################
## FPGA: xcvu33p-fsvh2104-2-e
###############################################################

###############################################################
## Synthesis Constraints
###############################################################
create_clock -period 6.400 -name mgtrefclk1_x0y0_p [get_ports mgtrefclk1_x0y0_p]

create_clock -period 3.333 -name freerun_clk_p [get_ports freerun_clk_p]

# Timing analysis tools are unable to calculate fabric clock correctly because of the fractional-N in the
# transceiver.  Therefore, overconstrain the design to get the correct clock calculation.
# create_clock -period 6.361 -name mgtrefclk1_x0y0_p [get_ports mgtrefclk1_x0y0_p]
# create_clock -period 6.361 -name mgtrefclk1_x0y1_p [get_ports mgtrefclk1_x0y1_p]


# False path constraints
# --------------------------
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *bit_synchronizer*inst/i_in_meta_reg}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *bit_synchronizer*inst/i_in_meta_reg}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_*_reg}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_*_reg}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *gtwiz_userclk_tx_inst/*gtwiz_userclk_tx_active_*_reg}]
set_false_path -from [get_clocks mgtrefclk1_x0y0_p] -to [get_clocks -of_objects [get_pins {bsp/dlx_phy/example_wrapper_inst/DLx_phy_inst/inst/gen_gtwizard_gtye4_top.DLx_phy_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_false_path -from [get_clocks -of_objects [get_pins {bsp/dlx_phy/example_wrapper_inst/DLx_phy_inst/inst/gen_gtwizard_gtye4_top.DLx_phy_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins bsp/dlx_phy/BUFGCE_DIV_inst/O]]

# ocde signal can be treated as a static signal
set_input_delay -clock [get_clocks  clock_156_25] 0.0 [get_ports -filter { NAME =~ "*ocde*" && DIRECTION == "IN" }]
set_false_path -from [get_ports -filter { NAME =~ "*ocde*" && DIRECTION == "IN" }]
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *decouple*}]
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *monitor*}]

#======================================================================================
#Following lines are added to try and finalize the timing closure of the PR design
#create_generated_clock -name oc_func/fw_afu/action_core_i/clock_afu -source bsp/dlx_phy/example_wrapper_inst/gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_clk_201MHz/O -multiply_by 1 bsp/dlx_phy/example_wrapper_inst/gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_clk_201MHz/O

#create_generated_clock -source [get_pins bsp/dlx_phy/example_wrapper_inst/gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_clk_201MHz/I] -master_clock [get_clocks txoutclk_out[0]_1] [get_pins bsp/dlx_phy/example_wrapper_inst/gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_clk_201MHz/O]

#create_generated_clock -name clock_afu_201MHz -source [get_pins bsp/dlx_phy/example_wrapper_inst/gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_clk_201MHz/I] -master_clock [get_clocks txoutclk_out[0]_1] [get_pins bsp/dlx_phy/example_wrapper_inst/gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_clk_201MHz/O]
#set_clock_groups -name clock_afu_201MHz -asynchronous -group [get_clocks  "*afu*"] -group [get_clocks  "*txoutclk*"]

create_clock -period 4.965 -name clock_afu -waveform {0.000 2.482} -add [get_nets [list clock_afu oc_func/fw_afu/action_core_i/action_w/clock_afu ]]

set_false_path -from oc_func/fw_afu/reset_snap_q_reg_replica_*
set_false_path -from oc_func/fw_afu/snap_core_i/mmio/mmmio/soft_reset_brdg_odma_reg_replica*


