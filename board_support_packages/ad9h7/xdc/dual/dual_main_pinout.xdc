###############################################################
## Placement Constraints: xcvu37p-fsvh2892-2-e-es1
###############################################################

set_property PACKAGE_PIN BN31 [get_ports oc0_ocde]
set_property IOSTANDARD LVCMOS18 [get_ports oc0_ocde]


# CAPI0 Clocks - MGTREFCLK0P_128.  I/O bank 129 shares 128 clock
set_property PACKAGE_PIN AJ41 [get_ports oc0_mgtrefclk1_x0y0_n]
set_property PACKAGE_PIN AJ40 [get_ports oc0_mgtrefclk1_x0y0_p]

# Free run clock, FABRIC_SRC_CLK defaults to 300 MHz
set_property PACKAGE_PIN BJ53 [get_ports freerun_clk_n]
set_property PACKAGE_PIN BJ52 [get_ports freerun_clk_p]
set_property IOSTANDARD LVDS [get_ports freerun_clk_p]
set_property IOSTANDARD LVDS [get_ports freerun_clk_n]


# CAPI0 TRANSMIT/RECEIVE Channels
set_property PACKAGE_PIN AL50 [get_ports oc0_ch0_gtyrxn_in]
set_property PACKAGE_PIN AL49 [get_ports oc0_ch0_gtyrxp_in]
set_property PACKAGE_PIN AK52 [get_ports oc0_ch1_gtyrxn_in]
set_property PACKAGE_PIN AK51 [get_ports oc0_ch1_gtyrxp_in]
set_property PACKAGE_PIN AJ54 [get_ports oc0_ch2_gtyrxn_in]
set_property PACKAGE_PIN AJ53 [get_ports oc0_ch2_gtyrxp_in]
set_property PACKAGE_PIN AH52 [get_ports oc0_ch3_gtyrxn_in]
set_property PACKAGE_PIN AH51 [get_ports oc0_ch3_gtyrxp_in]
set_property PACKAGE_PIN AG54 [get_ports oc0_ch4_gtyrxn_in]
set_property PACKAGE_PIN AG53 [get_ports oc0_ch4_gtyrxp_in]
set_property PACKAGE_PIN AF52 [get_ports oc0_ch5_gtyrxn_in]
set_property PACKAGE_PIN AF51 [get_ports oc0_ch5_gtyrxp_in]
set_property PACKAGE_PIN AE54 [get_ports oc0_ch6_gtyrxn_in]
set_property PACKAGE_PIN AE53 [get_ports oc0_ch6_gtyrxp_in]
set_property PACKAGE_PIN AE50 [get_ports oc0_ch7_gtyrxn_in]
set_property PACKAGE_PIN AE49 [get_ports oc0_ch7_gtyrxp_in]

set_property PACKAGE_PIN AK47 [get_ports oc0_ch0_gtytxn_out]
set_property PACKAGE_PIN AK46 [get_ports oc0_ch0_gtytxp_out]
set_property PACKAGE_PIN AJ49 [get_ports oc0_ch1_gtytxn_out]
set_property PACKAGE_PIN AJ48 [get_ports oc0_ch1_gtytxp_out]
set_property PACKAGE_PIN AJ45 [get_ports oc0_ch2_gtytxn_out]
set_property PACKAGE_PIN AJ44 [get_ports oc0_ch2_gtytxp_out]
set_property PACKAGE_PIN AH47 [get_ports oc0_ch3_gtytxn_out]
set_property PACKAGE_PIN AH46 [get_ports oc0_ch3_gtytxp_out]
set_property PACKAGE_PIN AG49 [get_ports oc0_ch4_gtytxn_out]
set_property PACKAGE_PIN AG48 [get_ports oc0_ch4_gtytxp_out]
set_property PACKAGE_PIN AG45 [get_ports oc0_ch5_gtytxn_out]
set_property PACKAGE_PIN AG44 [get_ports oc0_ch5_gtytxp_out]
set_property PACKAGE_PIN AF47 [get_ports oc0_ch6_gtytxn_out]
set_property PACKAGE_PIN AF46 [get_ports oc0_ch6_gtytxp_out]
set_property PACKAGE_PIN AE45 [get_ports oc0_ch7_gtytxn_out]
set_property PACKAGE_PIN AE44 [get_ports oc0_ch7_gtytxp_out]


# Link 1
set_property PACKAGE_PIN BP31 [get_ports oc1_ocde]
set_property IOSTANDARD LVCMOS18 [get_ports oc1_ocde]


# CAPI1 Clocks - MGTREFCLK0P_130.  I/O bank 129 shares 128 clock
set_property PACKAGE_PIN AD43 [get_ports oc1_mgtrefclk1_x0y0_n]
set_property PACKAGE_PIN AD42 [get_ports oc1_mgtrefclk1_x0y0_p]


# CAPI1 TRANSMIT/RECEIVE Channels
set_property PACKAGE_PIN AD52 [get_ports oc1_ch0_gtyrxn_in]
set_property PACKAGE_PIN AD51 [get_ports oc1_ch0_gtyrxp_in]
set_property PACKAGE_PIN AC54 [get_ports oc1_ch1_gtyrxn_in]
set_property PACKAGE_PIN AC53 [get_ports oc1_ch1_gtyrxp_in]
set_property PACKAGE_PIN AC50 [get_ports oc1_ch2_gtyrxn_in]
set_property PACKAGE_PIN AC49 [get_ports oc1_ch2_gtyrxp_in]
set_property PACKAGE_PIN AB52 [get_ports oc1_ch3_gtyrxn_in]
set_property PACKAGE_PIN AB51 [get_ports oc1_ch3_gtyrxp_in]
set_property PACKAGE_PIN AA54 [get_ports oc1_ch4_gtyrxn_in]
set_property PACKAGE_PIN AA53 [get_ports oc1_ch4_gtyrxp_in]
set_property PACKAGE_PIN  Y52 [get_ports oc1_ch5_gtyrxn_in]
set_property PACKAGE_PIN  Y51 [get_ports oc1_ch5_gtyrxp_in]
set_property PACKAGE_PIN  W54 [get_ports oc1_ch6_gtyrxn_in]
set_property PACKAGE_PIN  W53 [get_ports oc1_ch6_gtyrxp_in]
set_property PACKAGE_PIN  V52 [get_ports oc1_ch7_gtyrxn_in]
set_property PACKAGE_PIN  V51 [get_ports oc1_ch7_gtyrxp_in]

set_property PACKAGE_PIN AD47 [get_ports oc1_ch0_gtytxn_out]
set_property PACKAGE_PIN AD46 [get_ports oc1_ch0_gtytxp_out]
set_property PACKAGE_PIN AC45 [get_ports oc1_ch1_gtytxn_out]
set_property PACKAGE_PIN AC44 [get_ports oc1_ch1_gtytxp_out]
set_property PACKAGE_PIN AB47 [get_ports oc1_ch2_gtytxn_out]
set_property PACKAGE_PIN AB46 [get_ports oc1_ch2_gtytxp_out]
set_property PACKAGE_PIN AA49 [get_ports oc1_ch3_gtytxn_out]
set_property PACKAGE_PIN AA48 [get_ports oc1_ch3_gtytxp_out]
set_property PACKAGE_PIN AA45 [get_ports oc1_ch4_gtytxn_out]
set_property PACKAGE_PIN AA44 [get_ports oc1_ch4_gtytxp_out]
set_property PACKAGE_PIN  Y47 [get_ports oc1_ch5_gtytxn_out]
set_property PACKAGE_PIN  Y46 [get_ports oc1_ch5_gtytxp_out]
set_property PACKAGE_PIN  W49 [get_ports oc1_ch6_gtytxn_out]
set_property PACKAGE_PIN  W48 [get_ports oc1_ch6_gtytxp_out]
set_property PACKAGE_PIN  W45 [get_ports oc1_ch7_gtytxn_out]
set_property PACKAGE_PIN  W44 [get_ports oc1_ch7_gtytxp_out]
