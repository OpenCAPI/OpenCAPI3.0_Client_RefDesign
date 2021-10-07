#Static pblock is only used for Partial reconfiguration
create_pblock pblock_static_BSP
add_cells_to_pblock [get_pblocks pblock_static_BSP] [get_cells -quiet [list bsp/dlx_phy bsp/tlx cfg oc_func/cfg_f1 oc_func/fw_afu/GND oc_func/fw_afu/VCC oc_func/fw_afu/desc oc_func/fw_afu/input_reset_q_reg oc_func/fw_afu/reset_snap_q_reg oc_func/fw_afu/snap_core_i]]

# Static zone for 9H3 (in SLR0) is
#     ----------------------------------
# Y3: |   |   |   |   ||   |   |   |   |
# Y2: |   |   |   |   ||   |   |   |   |
# Y1: | X | X | X |   ||   |   |   |   |
# Y0: | X | X |   |   ||   |   |   |   |
#     ----------------------------------
#      X0: X1: X2: X3:  X4: X5: X6: X7: 

resize_pblock [get_pblocks pblock_static_BSP] -add {CLOCKREGION_X0Y1:CLOCKREGION_X2Y1 CLOCKREGION_X0Y0:CLOCKREGION_X1Y0}

#add CONFIG_SITE in X7Y1 for ICAPE3
resize_pblock [get_pblocks pblock_static_BSP] -add {CONFIG_SITE_X0Y0:CONFIG_SITE_X0Y0}
#add IOB in X4Y0 and X4Y1 used by bsp/FLASH and bsp/dlx_phy
resize_pblock [get_pblocks pblock_static_BSP] -add {IOB_X0Y0:IOB_X0Y155}
