###############################################################
## FPGA: xcvu37p-fsvh2892-2-i-es1
###############################################################

#Static pblock is only used for Partial reconfiguration
#
 create_pblock pblock_static_BSP
 add_cells_to_pblock pblock_static_BSP [get_cells [list bsp?/dlx_phy bsp?/DLx_phy_vio_0_inst bsp?/vio_reset_n_inst_tlx bsp?/tlx]]
 add_cells_to_pblock pblock_static_BSP [get_cells [list cfg? oc_func?]]
 #remove the code which will be in dynamic zone
 remove_cells_from_pblock pblock_static_BSP [get_cells [list oc_func?/fw_afu/action_core_i]]

# Static zone for 9H7 is
#      ----------------------------------
# Y11: |   |   |   |   ||   |   |   |   |
# Y10: |   |   |   |   ||   |   |   |   |
# Y9 : |   |   |   |   ||   |   |   |   |
# Y8 : |   |   |   |   ||   |   |   |   |SLR2
#      ----------------------------------
# Y7 : |   |   |   |   ||   |   |   |   |
# Y6 : |   |   |   |   ||   |   |   |   |
# Y5 : | X | X | X | X ||   |   |   |   |
# Y4 : | X | X | X | X ||   |   |   |   |SLR1
#      ----------------------------------
# Y3 : |   |   |   |   ||   |   |   |   |
# Y2 : |   |   |   |   ||   |   |   |   |
# Y1 : |   |   |   |   ||   |   |   |   |
# Y0 : |   |   |   |   ||   |   |   |   |SLR0
#      ----------------------------------
#       X0: X1: X2: X3:  X4: X5: X6: X7: 
#

 resize_pblock pblock_static_BSP -add CLOCKREGION_X0Y4:CLOCKREGION_X3Y5

 #add IOB in X4Y0 and X4Y1 used by bsp/FLASH and bsp/dlx_phy
 resize_pblock [get_pblocks pblock_static_BSP] -add {IOB_X0Y52:IOB_X0Y155}
 #add IBUFDS_freerun + bsp0/FLASH is located in X4Y12
 resize_pblock [get_pblocks pblock_static_BSP] -add {HPIOBDIFFINBUF_X0Y60}
 #add CONFIG_SITE in X7Y1 for ICAPE3
 resize_pblock [get_pblocks pblock_static_BSP] -add {CONFIG_SITE_X0Y0:CONFIG_SITE_X0Y0}
