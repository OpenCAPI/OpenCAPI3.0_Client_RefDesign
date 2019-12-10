## LPC bram 8192x1
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name bram_native_1P_noOutReg_8192x1_A

set_property -dict [list CONFIG.Interface_Type {Native} CONFIG.Memory_Type {Single_Port_RAM} CONFIG.Write_Width_A {1} CONFIG.Write_Depth_A {8192} CONFIG.Read_Width_A {1} \
CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Use_AXI_ID {false} CONFIG.Use_Byte_Write_Enable {false} \
CONFIG.Byte_Size {9} CONFIG.Assume_Synchronous_Clk {false} CONFIG.Write_Width_B {1} CONFIG.Read_Width_B {1} CONFIG.Operating_Mode_B {WRITE_FIRST} CONFIG.Enable_B {Always_Enabled} \
CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.Use_RSTB_Pin {false} CONFIG.Reset_Type {SYNC} CONFIG.Port_B_Clock {0} CONFIG.Port_B_Enable_Rate {0} \
CONFIG.Fill_Remaining_Memory_Locations {true}] [get_ips bram_native_1P_noOutReg_8192x1_A]

generate_target {all} [get_ips bram_native_1P_noOutReg_8192x1_A]
