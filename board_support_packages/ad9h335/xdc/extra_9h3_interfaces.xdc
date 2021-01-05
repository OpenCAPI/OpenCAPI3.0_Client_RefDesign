set_property PACKAGE_PIN BE30 [get_ports {eeprom_scl}]    ; #SPARE_SCL
set_property PACKAGE_PIN BC30 [get_ports {eeprom_sda}]    ; #SPARE_SDA
set_property PACKAGE_PIN BD30 [get_ports {eeprom_wp}]     ; #SPARE_WP

set_property PACKAGE_PIN AV32 [get_ports {user_led_a0}]   ; #USER_LED_A0_1V8
set_property PACKAGE_PIN AW32 [get_ports {user_led_a1}]   ; #USER_LED_A1_1V8
set_property PACKAGE_PIN AY30 [get_ports {user_led_g0}]   ; #USER_LED_G0_1V8
set_property PACKAGE_PIN AV31 [get_ports {user_led_g1}]   ; #USER_LED_G1_1V8

set_property PACKAGE_PIN BA33    [get_ports {avr_ck}] ; AVR_MON_CLK_1V8
set_property PACKAGE_PIN BF34    [get_ports {avr_rx}] ; AVR_U2B_1V8
set_property PACKAGE_PIN BF33    [get_ports {avr_tx}] ; AVR_B2U_1V8

set_property IOSTANDARD LVCMOS18 [get_ports {eeprom_scl}]
set_property IOSTANDARD LVCMOS18 [get_ports {eeprom_sda}]
set_property IOSTANDARD LVCMOS18 [get_ports {eeprom_wp}]

set_property IOSTANDARD LVCMOS18 [get_ports {user_led_a0}]
set_property IOSTANDARD LVCMOS18 [get_ports {user_led_a1}]
set_property IOSTANDARD LVCMOS18 [get_ports {user_led_g0}]
set_property IOSTANDARD LVCMOS18 [get_ports {user_led_g1}]

set_property IOSTANDARD LVCMOS18 [get_ports {avr_ck}]
set_property IOSTANDARD LVCMOS18 [get_ports {avr_rx}]
set_property IOSTANDARD LVCMOS18 [get_ports {avr_tx}]
