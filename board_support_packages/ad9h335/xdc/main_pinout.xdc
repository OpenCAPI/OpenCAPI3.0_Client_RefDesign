###############################################################
## Placement Constraints: xcvu33p-fsvh2104-2-e-es1
###############################################################

set_property PACKAGE_PIN BF19 [get_ports ocde]
set_property IOSTANDARD LVCMOS18 [get_ports ocde]

########################
## Bottom Left Corner ##
########################

# DLX0 Clocks
set_property PACKAGE_PIN AK39 [get_ports mgtrefclk1_x0y0_n]
set_property PACKAGE_PIN AK38 [get_ports mgtrefclk1_x0y0_p]


# Free run clock constraint
# page 13 AD9H3        user manual.pdf
# Signal: FABRIC_CLK
set_property PACKAGE_PIN   BA31     [get_ports freerun_clk_n]
set_property PACKAGE_PIN   AY31     [get_ports freerun_clk_p]
set_property IOSTANDARD    LVDS     [get_ports freerun_clk_p]
set_property IOSTANDARD    LVDS     [get_ports freerun_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports freerun_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports freerun_clk_n]

# DLX0 TRANSMIT/RECEIVE Channels
set_property PACKAGE_PIN BF43 [get_ports ch0_gtyrxn_in]
set_property PACKAGE_PIN BF42 [get_ports ch0_gtyrxp_in]
set_property PACKAGE_PIN BD44 [get_ports ch1_gtyrxn_in]
set_property PACKAGE_PIN BD43 [get_ports ch1_gtyrxp_in]
set_property PACKAGE_PIN BB44 [get_ports ch2_gtyrxn_in]
set_property PACKAGE_PIN BB43 [get_ports ch2_gtyrxp_in]
set_property PACKAGE_PIN AY44 [get_ports ch3_gtyrxn_in]
set_property PACKAGE_PIN AY43 [get_ports ch3_gtyrxp_in]
set_property PACKAGE_PIN BC46 [get_ports ch4_gtyrxn_in]
set_property PACKAGE_PIN BC45 [get_ports ch4_gtyrxp_in]
set_property PACKAGE_PIN BA46 [get_ports ch5_gtyrxn_in]
set_property PACKAGE_PIN BA45 [get_ports ch5_gtyrxp_in]
set_property PACKAGE_PIN AW46 [get_ports ch6_gtyrxn_in]
set_property PACKAGE_PIN AW45 [get_ports ch6_gtyrxp_in]
set_property PACKAGE_PIN AV44 [get_ports ch7_gtyrxn_in]
set_property PACKAGE_PIN AV43 [get_ports ch7_gtyrxp_in]

set_property PACKAGE_PIN AT39 [get_ports ch0_gtytxn_out]
set_property PACKAGE_PIN AT38 [get_ports ch0_gtytxp_out]
set_property PACKAGE_PIN AR41 [get_ports ch1_gtytxn_out]
set_property PACKAGE_PIN AR40 [get_ports ch1_gtytxp_out]
set_property PACKAGE_PIN AP39 [get_ports ch2_gtytxn_out]
set_property PACKAGE_PIN AP38 [get_ports ch2_gtytxp_out]
set_property PACKAGE_PIN AN41 [get_ports ch3_gtytxn_out]
set_property PACKAGE_PIN AN40 [get_ports ch3_gtytxp_out]
set_property PACKAGE_PIN AM39 [get_ports ch4_gtytxn_out]
set_property PACKAGE_PIN AM38 [get_ports ch4_gtytxp_out]
set_property PACKAGE_PIN AL41 [get_ports ch5_gtytxn_out]
set_property PACKAGE_PIN AL40 [get_ports ch5_gtytxp_out]
set_property PACKAGE_PIN AJ41 [get_ports ch6_gtytxn_out]
set_property PACKAGE_PIN AJ40 [get_ports ch6_gtytxp_out]
set_property PACKAGE_PIN AG41 [get_ports ch7_gtytxn_out]
set_property PACKAGE_PIN AG40 [get_ports ch7_gtytxp_out]
















