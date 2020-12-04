# Generates Transceive IP
create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name DLx_phy
set_property -dict [list CONFIG.CHANNEL_ENABLE {X0Y7 X0Y6 X0Y5 X0Y4 X0Y3 X0Y2 X0Y1 X0Y0} \
                         CONFIG.TX_MASTER_CHANNEL {X0Y4} \
                         CONFIG.RX_MASTER_CHANNEL {X0Y4} \
                         CONFIG.TX_LINE_RATE {20} \
                         CONFIG.TX_REFCLK_FREQUENCY {156.25} \
                         CONFIG.TX_DATA_ENCODING {64B66B} \
                         CONFIG.TX_USER_DATA_WIDTH {64} \
                         CONFIG.TX_INT_DATA_WIDTH {64} \
                         CONFIG.RX_LINE_RATE {20} \
                         CONFIG.RX_REFCLK_FREQUENCY {156.25} \
                         CONFIG.RX_DATA_DECODING {64B66B} \
                         CONFIG.RX_USER_DATA_WIDTH {64} \
                         CONFIG.RX_INT_DATA_WIDTH {64} \
                         CONFIG.RX_JTOL_FC {10} \
                         CONFIG.RX_CB_MAX_LEVEL {4} \
                         CONFIG.ENABLE_OPTIONAL_PORTS {rxpolarity_in} \
                         CONFIG.RX_REFCLK_SOURCE {X0Y7 clk0-1 X0Y6 clk0-1 X0Y5 clk0-1 X0Y4 clk0-1} \
                         CONFIG.TX_REFCLK_SOURCE {X0Y7 clk0-1 X0Y6 clk0-1 X0Y5 clk0-1 X0Y4 clk0-1} \
                         CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {EXAMPLE_DESIGN} \
                         CONFIG.TXPROGDIV_FREQ_VAL {312.5} \
                         CONFIG.FREERUN_FREQUENCY {150} \
                         CONFIG.Component_Name {DLx_phy}] [get_ips DLx_phy]
generate_target {all} [get_ips DLx_phy]
