`timescale 1ps / 1ps
// -------------------------------------------------------------------
// Copyright 2017 IBM
//
// Title    : flash_sub_system.v
// Function : This file combines Xilinx Ultrascale+ IP cores and Micron FLASH memory into a sub-system to which
//            the CFG implementation registers can attach. The details are specific to the board identified above.
//            Other development or application boards may use a different approach to downloading an FPGA configuration
//            file from the host and triggering it to be loaded into the FPGA.
//
// Designer : Jeff Ruedinger   (rueding@us.ibm.com)
// -------------------------------------------------------------------
// Modification History :
//                               |Version    |     |Author   |Description of change
//                               |-----------|     |-------- |---------------------
  `define FLASH_SUB_SYS_VERSION   07_Dec_2017   //  rueding   Initial creation         
// -------------------------------------------------------------------


// ==============================================================================================================================
// @@@  Module Declaration
// ==============================================================================================================================

module flash_sub_system (

    // -----------------------------------
    // Miscellaneous Ports
    // -----------------------------------
    input          axi_clk                // This is the INTernal FPGA and AXI4-Lite interface clock
  , input          spi_clk                // Drive from a 200 MHz clock derived from the OpenCAPI link. The quad SPI core divides
                                          //   this down to half the frequency, allowing SPI to run at 100 MHz post configuration.
                                          //   During initial configuration, the FPGA uses the FLASH clock supplied by the 9V3 board
                                          //   (EMCCLK_B, 100 MHz, pin AJ28) but switches over to the internal clock supplied to
                                          //   the quad SPI core on .ext_spi_clk immediately after initial configuration is over.
                                          //   The quad SPI core divides this in half and drives it to the STARTUPE3 core on .USRCCLKO
                                          //   See ug570-ultrascale-configuration.pdf and ug470_7Series_Config.pdf page 92 for more details.
  , output         spi_clk_div_2          // Make half freq spi_clk available for wrapping back in as 'icap_clk' if desired
  , input          icap_clk               // This is a 100 MHz (max freq) clock into the ICAP block 
  , output         pl_clk0_0
  , input          reset_n                // (active low) Hardware reset

    // ------------------------------------------------------------
    // Interface to CFG registers, which act as an AXI4-Lite Master
    // ------------------------------------------------------------
  , input    [1:0] cfg_axi_devsel         // Select which AXI4-Lite slave is the target of the command
  , input   [13:0] cfg_axi_addr           // Read or write address to selected target (set upper unused bits to 0)
  , input          cfg_axi_wren           // Set to 1 to write a location, held stable through operation until done=1
  , input   [31:0] cfg_axi_wdata          // Contains write data (valid while wren=1)
  , input          cfg_axi_rden           // Set to 1 to read  a location, held stable through operation until done=1
  , output  [31:0] axi_cfg_rdata          // Contains read data (valid when rden=1 and done=1)
  , output         axi_cfg_done           // AXI logic pulses to 1 for 1 cycle when write is complete, or when rdata contains valid results
  , output   [1:0] axi_cfg_bresp          // Write response from selected AXI4-Lite device
  , output   [1:0] axi_cfg_rresp          // Read  response from selected AXI4-Lite device
  , output   [7:0] axi_cfg_status         // Device Specific status information
  , input          data_expand_enable     // When 1, expand/collapse 4 bytes of data into four, 1 byte AXI operations
  , input          data_expand_dir        // When 0, expand bytes [3:0] in order 0,1,2,3 . When 1, expand in order 3,2,1,0 .  
  , input          cfg_xfer_done_interrupt
  , input          cfg_icap_reload_en
  , inout          FPGA_FLASH_CE2_L       // jda 3/2 Interface to SPI flash
  , inout          FPGA_FLASH_DQ4         // jda 3/2 Interface to SPI flash
  , inout          FPGA_FLASH_DQ5         // jda 3/2 Interface to SPI flash
  , inout          FPGA_FLASH_DQ6         // jda 3/2 Interface to SPI flash
  , inout          FPGA_FLASH_DQ7         // jda 3/2 Interface to SPI flash
);

// AXI4-Lite signals between Master and Slave(s)
wire  [13:0] s_axi_awaddr; 
wire         s_axi_awvalid;
reg          s_axi_awready; 
wire  [31:0] s_axi_wdata;
wire   [3:0] s_axi_wstrb; 
wire         s_axi_wvalid; 
reg          s_axi_wready;
reg    [1:0] s_axi_bresp;
reg          s_axi_bvalid; 
wire         s_axi_bready; 
wire  [13:0] s_axi_araddr; 
wire         s_axi_arvalid; 
reg          s_axi_arready;
reg   [31:0] s_axi_rdata; 
reg    [1:0] s_axi_rresp; 
reg          s_axi_rvalid;
wire         s_axi_rready;

// Internal signals
wire [4:0] unused;
wire       icap_interrupt;
wire       qspi_interrupt;
wire       preq;
wire       eos;

wire [22:0]upper_address;

// External FPGA I/O to FLASH, as dictated by 9V3 card wiring in Alpha Data user manual
//wire EMCCLK_B;            // AJ28 (100 MHz drives SPI FLASH, redrive of REFCLK100M on ping AJ28)
// These wires only exist in simulation
`ifdef CFG_FLASH_SIM
  wire FPGA_FLASH_CE1_L;    // AE8  (9v3 signal name = FPGA_FLASH_CE1_L)
  wire FPGA_FLASH_DQ0;      // AB8  (9v3 signal name = FPGA_FLASH_DQ0)
  wire FPGA_FLASH_DQ1;      // AD8  (9v3 signal name = FPGA_FLASH_DQ1)
  wire FPGA_FLASH_DQ2;      // Y8   (9v3 signal name = FPGA_FLASH_DQ2)
  wire FPGA_FLASH_DQ3;      // AC8  (9v3 signal name = FPGA_FLASH_DQ3)
  wire FPGA_FLASH_CCLK;     // AB10 (9v3 signal name = CCLK)
`endif
// jda 3/2 wire FPGA_FLASH_CE2_L;    // AV30 (9v3 signal name = FPGA_FLASH_CE2_L)
// jda 3/2 wire FPGA_FLASH_DQ4;      // AF30 (9v3 signal name = FPGA_FLASH_DQ4)
// jda 3/2 wire FPGA_FLASH_DQ5;      // AG30 (9v3 signal name = FPGA_FLASH_DQ5)
// jda 3/2 wire FPGA_FLASH_DQ6;      // AF28 (9v3 signal name = FPGA_FLASH_DQ6)
// jda 3/2 wire FPGA_FLASH_DQ7;      // AG28 (9v3 signal name = FPGA_FLASH_DQ7)

// Combine signals into vectors
wire [7:0] spi_dq_i;   
wire [7:0] spi_dq_o;
wire [7:0] spi_dq_t;

// Quad SPI core to STARTUP clock
wire       spi_sck_o;
wire       spi_sck_t;

// Chip selects
wire [0:0] spi_ce1_o;
wire       spi_ce1_t;
wire       spi_ce2_o;
wire       spi_ce2_t;

// Assign status bits and other AXI4-Lite signals to config registers
assign axi_cfg_status[7:4]  = 4'b0;   
assign axi_cfg_status[3]    = qspi_interrupt;
assign axi_cfg_status[2]    = icap_interrupt;
assign axi_cfg_status[1]    = preq;
assign axi_cfg_status[0]    = eos;

//-- assign axi_cfg_bresp        = s_axi_bresp;
//-- assign axi_cfg_rresp        = s_axi_rresp;

//assign upper_address        = 23'b11111111000011110000000;
assign upper_address        = 23'b11111111000011110000000;

// ---------------------------------------------------------------------------------
// Convert CFG registers to AXI4-Lite master interface
// ---------------------------------------------------------------------------------
cfg_reg_to_axi4lite CFG2AXI4L (
    .s_axi_aclk       ( spi_clk         ) // input 
  , .s_axi_aresetn    ( reset_n         ) // input 
    // Configuration register interface
  , .cfg_axi_addr     ( cfg_axi_addr    ) // input   [15:0]
  , .cfg_axi_wren     ( cfg_axi_wren    ) // input 
  , .cfg_axi_wdata    ( cfg_axi_wdata   ) // input   [31:0]
  , .cfg_axi_rden     ( cfg_axi_rden    ) // input          
  , .axi_cfg_rdata    ( axi_cfg_rdata   ) // output  [31:0] 
  , .axi_cfg_done     ( axi_cfg_done    ) // output        
  , .axi_cfg_bresp    ( axi_cfg_bresp   ) // output   [1:0]
  , .axi_cfg_rresp    ( axi_cfg_rresp   ) // output   [1:0] 
//, .axi_cfg_status   ( axi_cfg_status  ) // output   [9:0]  (Pass directly from slaves to config regs)
  , .data_expand_enable ( data_expand_enable ) // input   
  , .data_expand_dir    ( data_expand_dir    ) // input

    // AXI4-Lite interface  (refer to "AMBA AXI and ACE Protocol Specification" from ARM)
  , .s_axi_awaddr     ( s_axi_awaddr    ) // output  [13:0]
  , .s_axi_awvalid    ( s_axi_awvalid   ) // output
  , .s_axi_awready    ( s_axi_awready   ) // input
  , .s_axi_wdata      ( s_axi_wdata     ) // output  [31:0]
  , .s_axi_wstrb      ( s_axi_wstrb     ) // output   [3:0]
  , .s_axi_wvalid     ( s_axi_wvalid    ) // output
  , .s_axi_wready     ( s_axi_wready    ) // input       
  , .s_axi_bresp      ( s_axi_bresp     ) // input    [1:0]
  , .s_axi_bvalid     ( s_axi_bvalid    ) // input
  , .s_axi_bready     ( s_axi_bready    ) // output
  , .s_axi_araddr     ( s_axi_araddr    ) // output  [13:0]
  , .s_axi_arvalid    ( s_axi_arvalid   ) // output
  , .s_axi_arready    ( s_axi_arready   ) // input  
  , .s_axi_rdata      ( s_axi_rdata     ) // input   [31:0]
  , .s_axi_rresp      ( s_axi_rresp     ) // input    [1:0]
  , .s_axi_rvalid     ( s_axi_rvalid    ) // input  
  , .s_axi_rready     ( s_axi_rready    ) // output   
);


// ---------------------------------------------------------------------------------
// Match one master to two slaves
// ---------------------------------------------------------------------------------
// . Most Master -> Slave signals are common, i.e. all Slaves "dot" on the same source
// . Condition AWVALID to each Slave by a unique device select value
// . Signals from Slaves to Master go through MUX based on device select
// . Use 'g' for Gated version of signals dependent on device select value
// . Create N-dimensional arrays (one per Slave) for the signals that are gated
//    (this allows consistency in the naming whether the signal is a bit or a vector)

//re [15:0] g_axi_awaddr  [1:0];    // broadcast
wire        g_axi_awvalid [1:0];    // gated
wire        g_axi_awready [1:0];    // muxed
//re [31:0] g_axi_wdata   [1:0];    // broadcast
//re  [3:0] g_axi_wstrb   [1:0];    // broadcast
wire        g_axi_wvalid  [1:0];    // gated
wire        g_axi_wready  [1:0];    // muxed
wire  [1:0] g_axi_bresp   [1:0];    // muxed
wire        g_axi_bvalid  [1:0];    // muxed
//re        g_axi_bready  [1:0];    // broadcast
//re [15:0] g_axi_araddr  [1:0];    // broadcast
wire        g_axi_arvalid [1:0];    // gated
wire        g_axi_arready [1:0];    // muxed
wire [31:0] g_axi_rdata   [1:0];    // muxed
wire  [1:0] g_axi_rresp   [1:0];    // muxed
wire        g_axi_rvalid  [1:0];    // muxed
//re        g_axi_rready  [1:0];    // broadcast

assign g_axi_awvalid[0] = (cfg_axi_devsel == 2'b00) ? s_axi_awvalid : 1'b0;
assign g_axi_wvalid[0]  = (cfg_axi_devsel == 2'b00) ? s_axi_wvalid  : 1'b0;
assign g_axi_arvalid[0] = (cfg_axi_devsel == 2'b00) ? s_axi_arvalid : 1'b0;

assign g_axi_awvalid[1] = (cfg_axi_devsel == 2'b01) ? s_axi_awvalid : 1'b0;
assign g_axi_wvalid[1]  = (cfg_axi_devsel == 2'b01) ? s_axi_wvalid  : 1'b0;
assign g_axi_arvalid[1] = (cfg_axi_devsel == 2'b01) ? s_axi_arvalid : 1'b0;

always @(*)  // Combinational
  case (cfg_axi_devsel)
    2'b00: begin
             s_axi_awready = g_axi_awready[0];
             s_axi_wready  = g_axi_wready[0];
             s_axi_bresp   = {2{g_axi_bresp[0]}};
//-- jda 3/5             s_axi_bresp   = g_axi_bresp[0];
             s_axi_bvalid  = g_axi_bvalid[0];
             s_axi_arready = g_axi_arready[0];
             s_axi_rdata   = g_axi_rdata[0];
             s_axi_rresp   = {2{g_axi_rresp[0]}};
//-- jda 3/5             s_axi_rresp   = g_axi_rresp[0];
             s_axi_rvalid  = g_axi_rvalid[0];
           end
    2'b01: begin
             s_axi_awready = g_axi_awready[1];
             s_axi_wready  = g_axi_wready[1];
             s_axi_bresp   = {2{g_axi_bresp[1]}};
//-- jda 3/5             s_axi_bresp   = g_axi_bresp[1];
             s_axi_bvalid  = g_axi_bvalid[1];
             s_axi_arready = g_axi_arready[1];
             s_axi_rdata   = g_axi_rdata[1];
             s_axi_rresp   = {2{g_axi_rresp[1]}};
//-- jda 3/5             s_axi_rresp   = g_axi_rresp[1];
             s_axi_rvalid  = g_axi_rvalid[1];
           end
    default: begin
             s_axi_awready = 1'b0;
             s_axi_wready  = 1'b0;
             s_axi_bresp   = 2'b11;   // DECode ERRor
             s_axi_bvalid  = 1'b0;
             s_axi_arready = 1'b0;
             s_axi_rdata   = 32'h0000_0000;
             s_axi_rresp   = 2'b00;
             s_axi_rvalid  = 1'b0;
           end
  endcase

// ---------------------------------------------------------------------------------
// Xilinx IP: AXI HWICAP (Internal reconfiguration controller, pg134-axi-hwicap.pdf)
// (Per configuration register definition, this is devsel=2'b01 )
// ---------------------------------------------------------------------------------
// You must compile the wrapper file axi_hwicap_0.v when simulating
// the core, axi_hwicap_0. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.
/*axi_hwicap_0 ICAP (
    .icap_clk       ( icap_clk           ) // input (max freq = 100 MHz, pg134-axi-hwicap.pdf)
  , .eos_in         ( eos                ) // input
  , .s_axi_aclk     ( spi_clk            ) // input
  , .s_axi_aresetn  ( reset_n            ) // input (active low)
  , .s_axi_awaddr   ( s_axi_awaddr[8:0]  ) // input [8:0]
  , .s_axi_awvalid  ( g_axi_awvalid[1]   ) // input 
  , .s_axi_awready  ( g_axi_awready[1]   ) // output 
  , .s_axi_wdata    ( s_axi_wdata        ) // input 
  , .s_axi_wstrb    ( s_axi_wstrb        ) // input [3:0]
  , .s_axi_wvalid   ( g_axi_wvalid[1]    ) // input
  , .s_axi_wready   ( g_axi_wready[1]    ) // output
  , .s_axi_bresp    ( g_axi_bresp[1]     ) // output [1:0]
  , .s_axi_bvalid   ( g_axi_bvalid[1]    ) // output
  , .s_axi_bready   ( s_axi_bready       ) // input
  , .s_axi_araddr   ( s_axi_araddr[8:0]  ) // input [8:0]
  , .s_axi_arvalid  ( g_axi_arvalid[1]   ) // input
  , .s_axi_arready  ( g_axi_arready[1]   ) // output 
  , .s_axi_rdata    ( g_axi_rdata[1]     ) // output [31:0]
  , .s_axi_rresp    ( g_axi_rresp[1]     ) // output [1:0]
  , .s_axi_rvalid   ( g_axi_rvalid[1]    ) // output
  , .s_axi_rready   ( s_axi_rready       ) // input
  , .ip2intc_irpt   ( icap_interrupt     ) // output
);*/

   
// ------------------------------------------------------------------
// Xilinx IP: axi_qu s_axi_rresp  ad_spi (FLASH controller, pg153-axi-quad-spi.pdf)
// (Per configuration register definition, this is devsel=2'b00 )
// ------------------------------------------------------------------
// Xilinx IP note: You must compile the wrapper file axi_quad_spi_0.v when simulating
// the core, axi_quad_spi_0. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.
/*axi_quad_spi_0 QSPI (
    .ext_spi_clk    ( spi_clk            ) // input 
  , .s_axi_aclk     ( spi_clk            ) // input 
  , .s_axi_aresetn  ( reset_n            ) // input (active low)
     // AXI_LITE
  , .s_axi_awaddr   ( s_axi_awaddr[6:0]  ) // input [6:0]
  , .s_axi_awvalid  ( g_axi_awvalid[0]   ) // input 
  , .s_axi_awready  ( g_axi_awready[0]   ) // output
  , .s_axi_wdata    ( s_axi_wdata        ) // input 
  , .s_axi_wstrb    ( s_axi_wstrb        ) // input [3:0]
  , .s_axi_wvalid   ( g_axi_wvalid[0]    ) // input
  , .s_axi_wready   ( g_axi_wready[0]    ) // output
  , .s_axi_bresp    ( g_axi_bresp[0]     ) // output [1:0]
  , .s_axi_bvalid   ( g_axi_bvalid[0]    ) // output
  , .s_axi_bready   ( s_axi_bready       ) // input
  , .s_axi_araddr   ( s_axi_araddr[6:0]  ) // input [6:0]
  , .s_axi_arvalid  ( g_axi_arvalid[0]   ) // input 
  , .s_axi_arready  ( g_axi_arready[0]   ) // output
  , .s_axi_rdata    ( g_axi_rdata[0]     ) // output [31:0]
  , .s_axi_rresp    ( g_axi_rresp[0]     ) // output [1:0]
  , .s_axi_rvalid   ( g_axi_rvalid[0]    ) // output 
  , .s_axi_rready   ( s_axi_rready       ) // input
     // SPI_0_TO_STARTUP (Route to dedicated Configuration pins on FPGA)
  , .io0_i          ( spi_dq_i[0]        )  // input 
  , .io0_o          ( spi_dq_o[0]        )  // output 
  , .io0_t          ( spi_dq_t[0]        )  // output 
  , .io1_i          ( spi_dq_i[1]        )  // input 
  , .io1_o          ( spi_dq_o[1]        )  // output 
  , .io1_t          ( spi_dq_t[1]        )  // output 
  , .io2_i          ( spi_dq_i[2]        )  // input 
  , .io2_o          ( spi_dq_o[2]        )  // output 
  , .io2_t          ( spi_dq_t[2]        )  // output 
  , .io3_i          ( spi_dq_i[3]        )  // input
  , .io3_o          ( spi_dq_o[3]        )  // output 
  , .io3_t          ( spi_dq_t[3]        )  // output 
  , .sck_i          ( spi_sck_o          )  // input  (wrap output clock back as input, not used in master mode of Dual Quad SPI anyway)
  , .sck_o          ( spi_sck_o          )  // output 
  , .sck_t          ( spi_sck_t          )  // output 
  , .ss_i           ( 1'b0               )  // input  (unused by core) 
  , .ss_o           ( spi_ce1_o          )  // output [0:0]  (single bit vector)
  , .ss_t           ( spi_ce1_t          )  // output 
     // SPI_1 (Route to User I/O pins, so need to be constrainted to only be used for configuration)
  , .io0_1_i        ( spi_dq_i[4]        )  // input 
  , .io0_1_o        ( spi_dq_o[4]        )  // output 
  , .io0_1_t        ( spi_dq_t[4]        )  // output 
  , .io1_1_i        ( spi_dq_i[5]        )  // input 
  , .io1_1_o        ( spi_dq_o[5]        )  // output 
  , .io1_1_t        ( spi_dq_t[5]        )  // output 
  , .io2_1_i        ( spi_dq_i[6]        )  // input 
  , .io2_1_o        ( spi_dq_o[6]        )  // output 
  , .io2_1_t        ( spi_dq_t[6]        )  // output 
  , .io3_1_i        ( spi_dq_i[7]        )  // input 
  , .io3_1_o        ( spi_dq_o[7]        )  // output 
  , .io3_1_t        ( spi_dq_t[7]        )  // output 
  , .ss_1_i         ( 1'b0               )  // input  (unused by core)
  , .ss_1_o         ( spi_ce2_o          )  // output 
  , .ss_1_t         ( spi_ce2_t          )  // output 
     // Misc
  , .ip2intc_irpt   ( qspi_interrupt     )  // output
);*/
assign spi_clk_div_2 = spi_sck_o;           // Pass clock going to STARTUP upwards so it can be used as ICAP clock




// ------------------------------------------------------------------
// Connections from PL to PS
// ------------------------------------------------------------------

  wire [31:0]S_AXI_0_araddr;
  wire [2:0]S_AXI_0_arprot;
  wire S_AXI_0_arready;
  wire S_AXI_0_arvalid;
  wire [31:0]S_AXI_0_awaddr;
  wire [2:0]S_AXI_0_awprot;
  wire S_AXI_0_awready;
  wire S_AXI_0_awvalid;
  wire S_AXI_0_bready;
  wire [1:0]S_AXI_0_bresp;
  wire S_AXI_0_bvalid;
  wire [31:0]S_AXI_0_rdata;
  wire S_AXI_0_rready;
  wire [1:0]S_AXI_0_rresp;
  wire S_AXI_0_rvalid;
  wire [31:0]S_AXI_0_wdata;
  wire S_AXI_0_wready;
  wire [3:0]S_AXI_0_wstrb;
  wire S_AXI_0_wvalid;
  wire aresetn;
  wire pl_clk0_0;
  wire saxihpc0_fpd_aclk_0;
  
//  reg [23:0] ddr_addr;
//  reg wvalid_old;
//  wire wvalid_neg_edge;
/*  
//  reg [23:0] ddr_addr_q               , ddr_addr_q2               , ddr_addr_q3               , ddr_addr_q4               ;
  reg        g_axi_arvalid_q          , g_axi_arvalid_q2          , g_axi_arvalid_q3          , g_axi_arvalid_q4          ;
  reg        g_axi_awvalid_q          , g_axi_awvalid_q2          , g_axi_awvalid_q3          , g_axi_awvalid_q4          ;
  reg        s_axi_bready_q           , s_axi_bready_q2           , s_axi_bready_q3           , s_axi_bready_q4           ;  
  reg        s_axi_rready_q           , s_axi_rready_q2           , s_axi_rready_q3           , s_axi_rready_q4           ;  
  reg [31:0] s_axi_wdata_q            , s_axi_wdata_q2            , s_axi_wdata_q3            , s_axi_wdata_q4            ;
  reg [3:0]  s_axi_wstrb_q            , s_axi_wstrb_q2            , s_axi_wstrb_q3            , s_axi_wstrb_q4            ;
  reg        g_axi_wvalid_q           , g_axi_wvalid_q2           , g_axi_wvalid_q3           , g_axi_wvalid_q4           ;
  reg        reset_n_q                , reset_n_q2                , reset_n_q3                , reset_n_q4                ;
  reg  [1:0]       cfg_xfer_done_interrupt_q, cfg_xfer_done_interrupt_q2, cfg_xfer_done_interrupt_q3, cfg_xfer_done_interrupt_q4;
  
    
  reg        g_axi_arready_q , g_axi_arready_q2, g_axi_arready_q3, g_axi_arready_q4;  
  reg        g_axi_awready_q , g_axi_awready_q2, g_axi_awready_q3, g_axi_awready_q4;   
  reg [1:0]  g_axi_bresp_q   , g_axi_bresp_q2  , g_axi_bresp_q3  , g_axi_bresp_q4  ; 
  reg        g_axi_bvalid_q  , g_axi_bvalid_q2 , g_axi_bvalid_q3 , g_axi_bvalid_q4 ; 
  reg [31:0] g_axi_rdata_q   , g_axi_rdata_q2  , g_axi_rdata_q3  , g_axi_rdata_q4  ;
  reg [1:0]  g_axi_rresp_q   , g_axi_rresp_q2  , g_axi_rresp_q3  , g_axi_rresp_q4  ;
  reg        g_axi_rvalid_q  , g_axi_rvalid_q2 , g_axi_rvalid_q3 , g_axi_rvalid_q4 ;
  reg        g_axi_wready_q  , g_axi_wready_q2 , g_axi_wready_q3 , g_axi_wready_q4 ;
  
  wire        g_axi_arready_d ;
  wire        g_axi_awready_d ;
  wire [1:0]  g_axi_bresp_d   ;
  wire        g_axi_bvalid_d  ;
  wire [31:0] g_axi_rdata_d   ;
  wire [1:0]  g_axi_rresp_d   ;
  wire        g_axi_rvalid_d  ;
  wire        g_axi_wready_d  ;
  reg [13:0] s_axi_araddr_q, s_axi_araddr_q2, s_axi_araddr_q3, s_axi_araddr_q4;
  reg [13:0] s_axi_awaddr_q, s_axi_awaddr_q2, s_axi_awaddr_q3, s_axi_awaddr_q4;

  
     
     
  always@(posedge spi_clk) begin
    //inputs
//        ddr_addr_q <= ddr_addr;
        g_axi_arvalid_q           <= g_axi_arvalid[0];
        g_axi_awvalid_q           <= g_axi_awvalid[0];
        s_axi_bready_q            <= s_axi_bready;
        s_axi_rready_q            <= s_axi_rready;
        s_axi_wdata_q             <= s_axi_wdata;
        s_axi_wstrb_q             <= s_axi_wstrb;
        g_axi_wvalid_q            <= g_axi_wvalid[0];
        reset_n_q                 <= reset_n;
        cfg_xfer_done_interrupt_q <= cfg_xfer_done_interrupt; 
        s_axi_araddr_q            <= s_axi_araddr;
        s_axi_awaddr_q            <= s_axi_awaddr;

        //ddr_addr_q2                <= ddr_addr_q;
        g_axi_arvalid_q2           <= g_axi_arvalid_q;
        g_axi_awvalid_q2           <= g_axi_awvalid_q;
        s_axi_bready_q2            <= s_axi_bready_q;
        s_axi_rready_q2            <= s_axi_rready_q;
        s_axi_wdata_q2             <= s_axi_wdata_q;
        s_axi_wstrb_q2             <= s_axi_wstrb_q;
        g_axi_wvalid_q2            <= g_axi_wvalid_q;
        reset_n_q2                 <= reset_n_q;
        cfg_xfer_done_interrupt_q2 <= cfg_xfer_done_interrupt_q; 
        s_axi_araddr_q2            <= s_axi_araddr_q;
        s_axi_awaddr_q2            <= s_axi_awaddr_q;

         
        //ddr_addr_q3                <= ddr_addr_q2;
        g_axi_arvalid_q3           <= g_axi_arvalid_q2;
        g_axi_awvalid_q3           <= g_axi_awvalid_q2;
        s_axi_bready_q3            <= s_axi_bready_q2;
        s_axi_rready_q3            <= s_axi_rready_q2;
        s_axi_wdata_q3             <= s_axi_wdata_q2;
        s_axi_wstrb_q3             <= s_axi_wstrb_q2;
        g_axi_wvalid_q3            <= g_axi_wvalid_q2;
        reset_n_q3                 <= reset_n_q2;
        cfg_xfer_done_interrupt_q3 <= cfg_xfer_done_interrupt_q2; 
        s_axi_araddr_q3            <= s_axi_araddr_q2;
        s_axi_awaddr_q3            <= s_axi_awaddr_q2;

        //ddr_addr_q4                <= ddr_addr_q3;
        g_axi_arvalid_q4           <= g_axi_arvalid_q3;
        g_axi_awvalid_q4           <= g_axi_awvalid_q3;
        s_axi_bready_q4            <= s_axi_bready_q3;
        s_axi_rready_q4            <= s_axi_rready_q3;
        s_axi_wdata_q4             <= s_axi_wdata_q3;
        s_axi_wstrb_q4             <= s_axi_wstrb_q3;
        g_axi_wvalid_q4            <= g_axi_wvalid_q3;
        reset_n_q4                 <= reset_n_q3;
        cfg_xfer_done_interrupt_q4 <= cfg_xfer_done_interrupt_q3;
        s_axi_araddr_q4            <= s_axi_araddr_q3;
        s_axi_awaddr_q4            <= s_axi_awaddr_q3;
               
    //outputs
        g_axi_arready_q            <= g_axi_arready_d;
        g_axi_awready_q            <= g_axi_awready_d;
        g_axi_bresp_q              <= g_axi_bresp_d; 
        g_axi_bvalid_q             <= g_axi_bvalid_d;
        g_axi_rdata_q              <= g_axi_rdata_d; 
        g_axi_rresp_q              <= g_axi_rresp_d;
        g_axi_rvalid_q             <= g_axi_rvalid_d;
        g_axi_wready_q             <= g_axi_wready_d;
  
        g_axi_arready_q2            <= g_axi_arready_q;
        g_axi_awready_q2            <= g_axi_awready_q;
        g_axi_bresp_q2              <= g_axi_bresp_q  ;
        g_axi_bvalid_q2             <= g_axi_bvalid_q ;
        g_axi_rdata_q2              <= g_axi_rdata_q  ;
        g_axi_rresp_q2              <= g_axi_rresp_q  ;
        g_axi_rvalid_q2             <= g_axi_rvalid_q ;
        g_axi_wready_q2             <= g_axi_wready_q ;
        
        g_axi_arready_q3            <= g_axi_arready_q2;
        g_axi_awready_q3            <= g_axi_awready_q2;
        g_axi_bresp_q3              <= g_axi_bresp_q2  ;
        g_axi_bvalid_q3             <= g_axi_bvalid_q2 ;
        g_axi_rdata_q3              <= g_axi_rdata_q2  ;
        g_axi_rresp_q3              <= g_axi_rresp_q2  ;
        g_axi_rvalid_q3             <= g_axi_rvalid_q2 ;
        g_axi_wready_q3             <= g_axi_wready_q2 ;
        
        g_axi_arready_q4            <= g_axi_arready_q3;
        g_axi_awready_q4            <= g_axi_awready_q3;
        g_axi_bresp_q4              <= g_axi_bresp_q3  ;
        g_axi_bvalid_q4             <= g_axi_bvalid_q3 ;
        g_axi_rdata_q4              <= g_axi_rdata_q3  ;
        g_axi_rresp_q4              <= g_axi_rresp_q3  ;
        g_axi_rvalid_q4             <= g_axi_rvalid_q3 ;
        g_axi_wready_q4             <= g_axi_wready_q3 ;
  end
  
  assign g_axi_arready[0]  = g_axi_arready_q4 ;
  assign g_axi_awready[0]  = g_axi_awready_q4 ;
  assign g_axi_bresp[0]    = g_axi_bresp_q4   ;
  assign g_axi_bvalid[0]   = g_axi_bvalid_q4  ;
  assign g_axi_rdata[0]    = g_axi_rdata_q4   ;
  assign g_axi_rresp[0]    = g_axi_rresp_q4   ;
  assign g_axi_rvalid[0]   = g_axi_rvalid_q4  ;
  assign g_axi_wready[0]   = g_axi_wready_q4  ;*/
  
  
                           
  wire cfg_xfer_done_interrupt_n;
  assign cfg_xfer_done_interrupt_n = ~ cfg_xfer_done_interrupt;
  
  wire [31:0] flashing_addr;
  wire [31:0] rst_addr;
  wire [31:0] addr_muxed;
  assign rst_addr = 32'hFF5E0218;
  assign flashing_addr = {16'h4000, 2'b00, s_axi_awaddr};
  assign addr_muxed = (cfg_icap_reload_en)? rst_addr:flashing_addr;

    design_1 design_1_i
     (.S_AXI_0_araddr(32'h40001000),   //input,  32 bit      
      .S_AXI_0_arprot(3'b0),                //input,  3 bit
      .S_AXI_0_arready(g_axi_arready[0]),   //output, 1 bit
      .S_AXI_0_arvalid(g_axi_arvalid[0]),   //input,  1 bit
      .S_AXI_0_awaddr(addr_muxed),   //input,  32 bit
      .S_AXI_0_awprot(3'b0),                //input,  3 bit
      .S_AXI_0_awready(g_axi_awready[0]),   //output, 1 bit
      .S_AXI_0_awvalid(g_axi_awvalid[0]),   //input,  1 bit
      .S_AXI_0_bready(s_axi_bready),        //input,  1 bit
      .S_AXI_0_bresp(g_axi_bresp[0]),       //output, 2 bit
      .S_AXI_0_bvalid(g_axi_bvalid[0]),     //output, 1 bit
      .S_AXI_0_rdata(g_axi_rdata[0]),       //output, 32 bit
      .S_AXI_0_rready(s_axi_rready),        //input,  1 bit
      .S_AXI_0_rresp(g_axi_rresp[0]),       //output, 2 bit
      .S_AXI_0_rvalid(g_axi_rvalid[0]),     //output, 1 bit
      .S_AXI_0_wdata(s_axi_wdata),          //input,  32 bit
      .S_AXI_0_wready(g_axi_wready[0]),     //output, 1 bit
      .S_AXI_0_wstrb(s_axi_wstrb),          //input,  4 bit
      .S_AXI_0_wvalid(g_axi_wvalid[0]),     //input,  1 bit
      .aresetn(reset_n),                    //input,  1 bit
      .pl_clk0_0(pl_clk0_0),                //output, 1 bit
      .saxihpc0_fpd_aclk_0(spi_clk),       //input,  1 bit
      .Reset_0(cfg_xfer_done_interrupt_n)
      );
      
      
    


endmodule 
