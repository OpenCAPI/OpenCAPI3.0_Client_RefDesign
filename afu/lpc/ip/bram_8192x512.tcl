## LPC bram 8192x512

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name bram_native_1P_noOutReg_8192x512_A

set_property -dict [list CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Write_Width_A {512} CONFIG.Write_Depth_A {8192} \
CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Read_Width_A {512} CONFIG.Write_Width_B {512} \
CONFIG.Read_Width_B {512} CONFIG.Fill_Remaining_Memory_Locations {true}] [get_ips bram_native_1P_noOutReg_8192x512_A]

generate_target {all} [get_ips bram_native_1P_noOutReg_8192x512_A]
