# Generates Transceive IP
create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name DLx_phy
set_property -dict {	 CONFIG.GT_TYPE {GTY}  \
			 CONFIG.CHANNEL_ENABLE {X0Y19 X0Y18 X0Y17 X0Y16 X0Y15 X0Y14 X0Y13 X0Y12} \
                         CONFIG.TX_MASTER_CHANNEL {X0Y19} \
                         CONFIG.RX_MASTER_CHANNEL {X0Y19} \
                         CONFIG.TX_LINE_RATE {25.78125} \
                         CONFIG.TX_DATA_ENCODING {64B66B} \
                         CONFIG.TX_QPLL_FRACN_NUMERATOR {8388608} \
                         CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
                         CONFIG.RX_LINE_RATE {25.78125} \
                         CONFIG.RX_REFCLK_FREQUENCY {156.25} \
                         CONFIG.RX_DATA_DECODING {64B66B} \
                         CONFIG.ENABLE_OPTIONAL_PORTS {rxpolarity_in} \
                         CONFIG.RX_REFCLK_SOURCE {X0Y19 clk1+1 X0Y18 clk1+1 X0Y17 clk1+1 X0Y16 clk1+1} \
                         CONFIG.TX_REFCLK_SOURCE {X0Y19 clk1+1 X0Y18 clk1+1 X0Y17 clk1+1 X0Y16 clk1+1} \
                         CONFIG.TX_REFCLK_FREQUENCY {156.25} \
                         CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {EXAMPLE_DESIGN} \
                         CONFIG.TX_USER_DATA_WIDTH {64} \
                         CONFIG.TX_INT_DATA_WIDTH {64} \
                         CONFIG.RX_USER_DATA_WIDTH {64} \
                         CONFIG.RX_INT_DATA_WIDTH {64} \
                         CONFIG.RX_QPLL_FRACN_NUMERATOR {8388608} \
                         CONFIG.RX_JTOL_FC {10} \
                         CONFIG.RX_CB_MAX_LEVEL {4} \
                         CONFIG.TXPROGDIV_FREQ_VAL {402.8320312} \
			 CONFIG.Component_Name {DLx_phy}
			 } [get_ips DLx_phy]
generate_target {all} [get_ips DLx_phy]


