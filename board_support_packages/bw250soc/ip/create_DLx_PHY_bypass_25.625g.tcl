# Generates Transceive IP with buffer-bypass at 25.625 Gbps Using lane 4 as the master lane
create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name DLx_phy
set_property -dict {	 CONFIG.GT_TYPE {GTY}  \
			 CONFIG.CHANNEL_ENABLE {X0Y19 X0Y18 X0Y17 X0Y16 X0Y15 X0Y14 X0Y13 X0Y12} \
                         CONFIG.TX_MASTER_CHANNEL {X0Y19} \
                         CONFIG.RX_MASTER_CHANNEL {X0Y19} \
                         CONFIG.TX_LINE_RATE {25.625} \
                         CONFIG.TX_REFCLK_FREQUENCY {156.25} \
                         CONFIG.TX_DATA_ENCODING {64B66B} \
                         CONFIG.TX_USER_DATA_WIDTH {64} \
                         CONFIG.TX_INT_DATA_WIDTH {64} \
                         CONFIG.TX_BUFFER_MODE {0} \
                         CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
                         CONFIG.RX_LINE_RATE {25.625} \
                         CONFIG.RX_REFCLK_FREQUENCY {156.25} \
                         CONFIG.RX_DATA_DECODING {64B66B} \
                         CONFIG.RX_USER_DATA_WIDTH {64} \
                         CONFIG.RX_INT_DATA_WIDTH {64} \
                         CONFIG.RX_BUFFER_MODE {0} \
                         CONFIG.RX_JTOL_FC {10} \
                         CONFIG.RX_CB_MAX_LEVEL {4} \
                         CONFIG.RX_REFCLK_SOURCE {X0Y19 clk1+1 X0Y18 clk1+1 X0Y17 clk1+1 X0Y16 clk1+1} \
                         CONFIG.TX_REFCLK_SOURCE {X0Y19 clk1+1 X0Y18 clk1+1 X0Y17 clk1+1 X0Y16 clk1+1} \
                         CONFIG.LOCATE_RESET_CONTROLLER {EXAMPLE_DESIGN} \
                         CONFIG.LOCATE_TX_BUFFER_BYPASS_CONTROLLER {EXAMPLE_DESIGN} \
                         CONFIG.LOCATE_RX_BUFFER_BYPASS_CONTROLLER {EXAMPLE_DESIGN} \
                         CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {EXAMPLE_DESIGN} \
                         CONFIG.TXPROGDIV_FREQ_VAL {400.390625} \
                         CONFIG.Component_Name {DLx_phy}
			 } [get_ips DLx_phy]
 generate_target {all} [get_ips DLx_phy]
