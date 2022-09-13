
# See xilinx doc PG153
# All the delay numbers have to be provided by the user

# Following are the SPI device parameters, for MT25QL512ABB8E12-0SIT
# Max Tco
# Min Tco
# Setup time requirement
# Hold time requirement

# Following are the board/trace delay numbers
# Assumption is that all Data lines are matched
# note: these are default values from PG153
### End of user provided delay numbers

# This is to ensure min routing delay from SCK generation to STARTUP input
# User should change this value based on the results
# Having more delay on this net reduces the Fmax
# Following constraint should be commented when STARTUP block is disabled

# set_max_delay 1.5 -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] -datapath_only
# set_min_delay 0.1 -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO]
set_max_delay -datapath_only -from [get_pins bsp/spi_clk_inst/O] -to [get_pins -hier *USRCCLKO] 0.300
set_min_delay -from [get_pins bsp/spi_clk_inst/O] -to [get_pins -hier *USRCCLKO] 0.100
set_max_delay -datapath_only -from [get_pins bsp/spi_clk_inst/O] -to [get_pins -hier *USRCCLKTS] 1.500
set_min_delay -from [get_pins bsp/spi_clk_inst/O] -to [get_pins -hier *USRCCLKTS] 0.100
# don't time sck_t pin as the generated clock.  sck_t is enabled before a command and left enabled.
set_disable_timing -from USRCCLKTS -to CCLK [get_cells bsp/FLASH/STARTUP]

# Following command creates a divide by 2 clock to use for interface timing constraints
# for Ultrascale+ parts, use CCLK output. STARTUPE3 models the delay from USRCCLK0/TS to CCLK
create_generated_clock -name clk_sck -source [get_pins bsp/FLASH/QSPI/ext_spi_clk] -edges {3 5 7} [get_pins -hierarchical */CCLK]


# Data is captured into FPGA on the second rising edge of ext_spi_clk after the SCK falling edge
# Data is driven by the FPGA on every alternate rising_edge of ext_spi_clk

set_input_delay -clock clk_sck -clock_fall -max 6.450 [get_ports *FPGA_FLASH*]
#set_input_delay -clock clk_sck -min [expr $tco_min + $tdata_trace_delay_min + $tclk_trace_delay_min] [get_ports *FPGA_FLASH*] -clock_fall;
set_input_delay -clock clk_sck -clock_fall -max 6.450 [get_pins -hierarchical {*STARTUP*/DATA_IN[*]}]
#set_input_delay -clock clk_sck -min [expr $tco_min + $tdata_trace_delay_min + $tclk_trace_delay_min] [get_pins -hierarchical *STARTUP*/DATA_IN[*]] -clock_fall;
set_multicycle_path -setup -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] 3
#set_multicycle_path 1 -hold -end -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]]


# Data is captured into SPI on the following rising edge of SCK
# Data is driven by the IP on alternate rising_edge of the ext_spi_clk

set_output_delay -clock clk_sck -max 1.800 [get_ports *FPGA_FLASH*]
#set_output_delay -clock clk_sck -min [expr $tdata_trace_delay_min -$th - $tclk_trace_delay_max]   [get_ports *FPGA_FLASH*];
set_output_delay -clock clk_sck -max 1.800 [get_pins -hierarchical {*STARTUP*/DATA_OUT[*]}]
#set_output_delay -clock clk_sck -min [expr $tdata_trace_delay_min -$th - $tclk_trace_delay_max]   [get_pins -hierarchical *STARTUP*/DATA_OUT[*]];
set_multicycle_path -setup -start -from [get_clocks -of_objects [get_pins bsp/spi_clk_inst/O]] -to [get_clocks clk_sck] 3
#set_multicycle_path 1 -hold -from [get_clocks -of_objects [get_pins bsp/spi_clk_inst/O]] -to [get_clocks clk_sck]





