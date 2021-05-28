//
// Copyright 2019 International Business Machines
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// This is the top file for simulation.
// It's different to hardware/oc-bip/board_support_packages/${FPGA_CARD}/verilog/framework_top/oc_fpga_top.v
//  1) Please pay attention to the name of clocks: tlx_clock and afu_clock
//     They are named as clock_tlx/afu in oc_fpga_top.v
//     But here they come from ocse afu_driver
//  2) Reset is also generated here just for simulation.

`include "snap_global_vars.v"

module top (
    output          breakpoint
);
    import "DPI-C" function void tlx_bfm_init();
    import "DPI-C" function void set_simulation_time(input [0:63] simulationTime);
    import "DPI-C" function void get_simuation_error(inout simulationError);
    import "DPI-C" function void tlx_bfm(
        input tlx_clock,
        input afu_clock,
        input reset,
        // Table 1: TLX to AFU Response Interface
        inout             tlx_afu_resp_valid_top,
        inout       [7:0] tlx_afu_resp_opcode_top,
        inout      [15:0] tlx_afu_resp_afutag_top,
        inout       [3:0] tlx_afu_resp_code_top,
        inout       [5:0] tlx_afu_resp_pg_size_top,
        inout       [1:0] tlx_afu_resp_dl_top,
        inout       [1:0] tlx_afu_resp_dp_top,
        inout      [23:0] tlx_afu_resp_host_tag_top,
        inout      [17:0] tlx_afu_resp_addr_tag_top,
        inout       [3:0] tlx_afu_resp_cache_state_top,

        // Table 2: TLX Response Credit Interface
        input             afu_tlx_resp_credit_top,
        input       [6:0] afu_tlx_resp_initial_credit_top,

        // Table 3: TLX to AFU Command Interface
        inout             tlx_afu_cmd_valid_top,
        inout       [7:0] tlx_afu_cmd_opcode_top,
        inout      [15:0] tlx_afu_cmd_capptag_top,
        inout       [1:0] tlx_afu_cmd_dl_top,
        inout       [2:0] tlx_afu_cmd_pl_top,
        inout      [63:0] tlx_afu_cmd_be_top,
        inout             tlx_afu_cmd_end_top,
        // inout             tlx_afu_cmd_t_top,
        inout      [63:0] tlx_afu_cmd_pa_top,
        inout       [3:0] tlx_afu_cmd_flag_top,
        inout             tlx_afu_cmd_os_top,

        // Table 4: TLX Command Credit Interface
        input             afu_tlx_cmd_credit_top,
        input       [6:0] afu_tlx_cmd_initial_credit_top,

        // Table 5: TLX to AFU Response Data Interface
        inout             tlx_afu_resp_data_valid_top,
        inout     [511:0] tlx_afu_resp_data_bus_top,
        inout             tlx_afu_resp_data_bdi_top,
        input             afu_tlx_resp_rd_req_top,
        input       [2:0] afu_tlx_resp_rd_cnt_top,

        // Table 6: TLX to AFU Command Data Interface
        inout             tlx_afu_cmd_data_valid_top,
        inout     [511:0] tlx_afu_cmd_data_bus_top,
        inout             tlx_afu_cmd_data_bdi_top,

        input   afu_tlx_cmd_rd_req_top,
        input       [2:0] afu_tlx_cmd_rd_cnt_top,

        // Table 7: TLX Framer credit interface
        inout             tlx_afu_resp_credit_top,
        inout             tlx_afu_resp_data_credit_top,
        inout             tlx_afu_cmd_credit_top,
        inout             tlx_afu_cmd_data_credit_top,
        inout       [3:0] tlx_afu_cmd_resp_initial_credit_top,
        inout       [3:0] tlx_afu_data_initial_credit_top,
        inout       [5:0] tlx_afu_cmd_data_initial_credit_top,
        inout       [5:0] tlx_afu_resp_data_initial_credit_top,

        // Table 8: TLX Framer Command Interface
        input             afu_tlx_cmd_valid_top,
        input       [7:0] afu_tlx_cmd_opcode_top,
        input      [11:0] afu_tlx_cmd_actag_top,
        input       [3:0] afu_tlx_cmd_stream_id_top,
        input      [67:0] afu_tlx_cmd_ea_or_obj_top,
        input      [15:0] afu_tlx_cmd_afutag_top,
        input       [1:0] afu_tlx_cmd_dl_top,
        input       [2:0] afu_tlx_cmd_pl_top,
        input             afu_tlx_cmd_os_top,
        input      [63:0] afu_tlx_cmd_be_top,
        input       [3:0] afu_tlx_cmd_flag_top,
        input             afu_tlx_cmd_endian_top,
        input      [15:0] afu_tlx_cmd_bdf_top,
        input      [19:0] afu_tlx_cmd_pasid_top,
        input       [5:0] afu_tlx_cmd_pg_size_top,
        input     [511:0] afu_tlx_cdata_bus_top,
        input             afu_tlx_cdata_bdi_top,// TODO: TLX Ref Design doc lists this as afu_tlx_cdata_bad
        input             afu_tlx_cdata_valid_top,

        // Table 9: TLX Framer Response Interface
        input             afu_tlx_resp_valid_top,
        input       [7:0] afu_tlx_resp_opcode_top,
        input       [1:0] afu_tlx_resp_dl_top,
        input      [15:0] afu_tlx_resp_capptag_top,
        input       [1:0] afu_tlx_resp_dp_top,
        input       [3:0] afu_tlx_resp_code_top,
        input             afu_tlx_rdata_valid_top,
        input     [511:0] afu_tlx_rdata_bus_top,
        input             afu_tlx_rdata_bdi_top,

        // These signals do not appear on the RefDesign Doc. However it is present
        // on the TLX spec
        inout             tlx_afu_ready_top,
        inout             tlx_cfg0_in_rcv_tmpl_capability_0_top,
        inout             tlx_cfg0_in_rcv_tmpl_capability_1_top,
        inout             tlx_cfg0_in_rcv_tmpl_capability_2_top,
        inout             tlx_cfg0_in_rcv_tmpl_capability_3_top,
        inout       [3:0] tlx_cfg0_in_rcv_rate_capability_0_top,
        inout       [3:0] tlx_cfg0_in_rcv_rate_capability_1_top,
        inout       [3:0] tlx_cfg0_in_rcv_rate_capability_2_top,
        inout       [3:0] tlx_cfg0_in_rcv_rate_capability_3_top,
        inout             tlx_cfg0_valid_top,
        inout       [7:0] tlx_cfg0_opcode_top,
        inout      [63:0] tlx_cfg0_pa_top,
        inout             tlx_cfg0_t_top,
        inout       [2:0] tlx_cfg0_pl_top,
        inout      [15:0] tlx_cfg0_capptag_top,
        inout      [31:0] tlx_cfg0_data_bus_top,
        inout             tlx_cfg0_data_bdi_top,
        inout             tlx_cfg0_resp_ack_top,
        input       [3:0] cfg0_tlx_initial_credit_top,
        input             cfg0_tlx_credit_return_top,
        input             cfg0_tlx_resp_valid_top ,
        input       [7:0] cfg0_tlx_resp_opcode_top,
        input      [15:0] cfg0_tlx_resp_capptag_top,
        input       [3:0] cfg0_tlx_resp_code_top ,
        input       [3:0] cfg0_tlx_rdata_offset_top,
        input      [31:0] cfg0_tlx_rdata_bus_top ,
        input             cfg0_tlx_rdata_bdi_top,
        inout       [4:0] ro_device_top
       );
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////


    parameter RESET_CYCLES = 25;
    reg              tlx_clock;
    reg              afu_clock;
    reg              reset;

 `ifdef ENABLE_9H3_EEPROM
    wire             eeprom_scl;
    wire             eeprom_sda;
 `endif
 `ifdef ENABLE_9H3_AVR
    reg              avr_rx;
    reg              avr_ck;
 `endif

    // Table 1: TLX to AFU Response Interface
    reg              tlx_afu_resp_valid_top;
    reg   [7:0]      tlx_afu_resp_opcode_top;
    reg  [15:0]      tlx_afu_resp_afutag_top;
    reg   [3:0]      tlx_afu_resp_code_top;
    reg   [5:0]      tlx_afu_resp_pg_size_top;
    reg   [1:0]      tlx_afu_resp_dl_top;
    reg   [1:0]      tlx_afu_resp_dp_top;
    reg  [23:0]      tlx_afu_resp_host_tag_top;
    reg  [17:0]      tlx_afu_resp_addr_tag_top;
    reg   [3:0]      tlx_afu_resp_cache_state_top;

    // Table 3: TLX to AFU Command Interface
    reg             tlx_afu_cmd_valid_top;
    reg   [7:0]     tlx_afu_cmd_opcode_top;
    reg  [15:0]     tlx_afu_cmd_capptag_top;
    reg   [1:0]     tlx_afu_cmd_dl_top;
    reg   [2:0]     tlx_afu_cmd_pl_top;
    reg  [63:0]     tlx_afu_cmd_be_top;
    reg             tlx_afu_cmd_end_top;
    // reg             tlx_afu_cmd_t_top;
    reg  [63:0]     tlx_afu_cmd_pa_top;
    reg   [3:0]     tlx_afu_cmd_flag_top;
    reg             tlx_afu_cmd_os_top;

    // Table 5: TLX to AFU Response Data Interface
    reg             tlx_afu_resp_data_valid_top;
    reg [511:0]     tlx_afu_resp_data_bus_top;
    reg             tlx_afu_resp_data_bdi_top;

    // Table 5: TLX to AFU Response Data Interface delays
    reg             tlx_afu_resp_data_valid_dly1;
    reg [511:0]     tlx_afu_resp_data_bus_dly1;
    reg             tlx_afu_resp_data_bdi_dly1;

    // Table 5: TLX to AFU Response Data Interface delays
    reg             tlx_afu_resp_data_valid_dly2;
    reg [511:0]     tlx_afu_resp_data_bus_dly2;
    reg             tlx_afu_resp_data_bdi_dly2;

    // Table 6: TLX to AFU Command Data Interface
    reg             tlx_afu_cmd_data_valid_top;
    reg [511:0]     tlx_afu_cmd_data_bus_top;
    reg             tlx_afu_cmd_data_bdi_top;

    // Table 7: TLX Framer credit interface
    reg             tlx_afu_resp_credit_top;
    reg             tlx_afu_resp_data_credit_top;
    reg             tlx_afu_cmd_credit_top;
    reg             tlx_afu_cmd_data_credit_top;
    reg   [3:0]     tlx_afu_cmd_resp_initial_credit_top;
    reg   [3:0]     tlx_afu_data_initial_credit_top;
    reg   [5:0]     tlx_afu_cmd_data_initial_credit_top;
    reg   [5:0]     tlx_afu_resp_data_initial_credit_top;

    // These signals do not appear on the RefDesign Doc. However it is present
    // on the TLX spec
    reg             tlx_afu_ready_top;
    reg   [4:0]     ro_device_top;
    reg             tlx_cfg0_in_rcv_tmpl_capability_0_top;
    reg             tlx_cfg0_in_rcv_tmpl_capability_1_top;
    reg             tlx_cfg0_in_rcv_tmpl_capability_2_top;
    reg             tlx_cfg0_in_rcv_tmpl_capability_3_top;
    reg   [3:0]     tlx_cfg0_in_rcv_rate_capability_0_top;
    reg   [3:0]     tlx_cfg0_in_rcv_rate_capability_1_top;
    reg   [3:0]     tlx_cfg0_in_rcv_rate_capability_2_top;
    reg   [3:0]     tlx_cfg0_in_rcv_rate_capability_3_top;
    reg  [31:0]     cfg_ro_ovsec_tlx0_version_top;
    reg  [31:0]     cfg_ro_ovsec_dlx0_version_top;

    reg             tlx_cfg0_valid_top;
    reg   [7:0]     tlx_cfg0_opcode_top;
    reg  [63:0]     tlx_cfg0_pa_top;
    reg             tlx_cfg0_t_top;
    reg   [2:0]     tlx_cfg0_pl_top;
    reg  [15:0]     tlx_cfg0_capptag_top;
    reg  [31:0]     tlx_cfg0_data_bus_top;
    reg             tlx_cfg0_data_bdi_top;
    reg             tlx_cfg0_resp_ack_top;
    reg   [3:0]     cfg0_tlx_initial_credit_top;
    reg             cfg0_tlx_credit_return_top;
    reg             cfg0_tlx_resp_valid_top ;
    reg   [7:0]     cfg0_tlx_resp_opcode_top;
    reg  [15:0]     cfg0_tlx_resp_capptag_top;
    reg   [3:0]     cfg0_tlx_resp_code_top ;
    reg   [3:0]     cfg0_tlx_rdata_offset_top;
    reg  [31:0]     cfg0_tlx_rdata_bus_top ;
    reg             cfg0_tlx_rdata_bdi_top ;

    // Table 2: TLX Response Credit Interface
    reg             afu_tlx_resp_credit_top;
    reg   [6:0]     afu_tlx_resp_initial_credit_top;

    // Table 4: TLX Command Credit Interface
    reg             afu_tlx_cmd_credit_top;
    reg   [6:0]     afu_tlx_cmd_initial_credit_top;

    // Table 5: TLX to AFU Response Data Interface
    reg             afu_tlx_resp_rd_req_top;
    reg   [2:0]     afu_tlx_resp_rd_cnt_top;

    // Table 6: TLX to AFU Command Data Interface
    reg             afu_tlx_cmd_rd_req_top;
    reg   [2:0]     afu_tlx_cmd_rd_cnt_top;

    // Table 8: TLX Framer Command Interface
    reg             afu_tlx_cmd_valid_top;
    reg   [7:0]     afu_tlx_cmd_opcode_top;
    reg  [11:0]     afu_tlx_cmd_actag_top;
    reg   [3:0]     afu_tlx_cmd_stream_id_top;
    reg  [67:0]     afu_tlx_cmd_ea_or_obj_top;
    reg  [15:0]     afu_tlx_cmd_afutag_top;
    reg   [1:0]     afu_tlx_cmd_dl_top;
    reg   [2:0]     afu_tlx_cmd_pl_top;
    reg             afu_tlx_cmd_os_top;
    reg  [63:0]     afu_tlx_cmd_be_top;
    reg   [3:0]     afu_tlx_cmd_flag_top;
    reg             afu_tlx_cmd_endian_top;
    reg  [15:0]     afu_tlx_cmd_bdf_top ;
    reg  [19:0]     afu_tlx_cmd_pasid_top;
    reg   [5:0]     afu_tlx_cmd_pg_size_top;
    reg [511:0]     afu_tlx_cdata_bus_top;
    reg             afu_tlx_cdata_bdi_top;             // TODO: TLX Ref Design doc lists this as afu_tlx_cdata_bad
    reg             afu_tlx_cdata_valid_top;

    // Table 9: TLX Framer Response Interface
    reg             afu_tlx_resp_valid_top;
    reg   [7:0]     afu_tlx_resp_opcode_top;
    reg   [1:0]     afu_tlx_resp_dl_top;
    reg  [15:0]     afu_tlx_resp_capptag_top;
    reg   [1:0]     afu_tlx_resp_dp_top;
    reg   [3:0]     afu_tlx_resp_code_top;
    reg             afu_tlx_rdata_valid_top;
    reg [511:0]     afu_tlx_rdata_bus_top;
    reg             afu_tlx_rdata_bdi_top;

    // Table 10: TLX Framer Template Configuration

    // Wires for AFU o/p
    // Table 2: TLX Response Credit Interface
    wire        afu_tlx_resp_credit;
    wire [6:0]  afu_tlx_resp_initial_credit;

    // Table 4: TLX Command Credit Interface
    wire        afu_tlx_cmd_credit;
    wire [6:0]  afu_tlx_cmd_initial_credit;

    // Table 5: TLX to AFU Response Data Interface
    wire         afu_tlx_resp_rd_req;
    wire  [2:0]  afu_tlx_resp_rd_cnt;

    // Table 6: TLX to AFU Command Data Interface
    wire        afu_tlx_cmd_rd_req;
    wire [2:0]  afu_tlx_cmd_rd_cnt;

    // Table 8: TLX Framer Command Interface
    wire          afu_tlx_cmd_valid;
    wire [7:0]    afu_tlx_cmd_opcode;
    wire [11:0]   afu_tlx_cmd_actag;
    wire [3:0]    afu_tlx_cmd_stream_id;
    wire [67:0]   afu_tlx_cmd_ea_or_obj;
    wire [15:0]   afu_tlx_cmd_afutag;
    wire [1:0]    afu_tlx_cmd_dl;
    wire [2:0]    afu_tlx_cmd_pl;
    wire          afu_tlx_cmd_os;
    wire [63:0]   afu_tlx_cmd_be;
    wire [3:0]    afu_tlx_cmd_flag;
    wire          afu_tlx_cmd_endian;
    wire [15:0]   afu_tlx_cmd_bdf;
    wire [19:0]   afu_tlx_cmd_pasid;
    wire [5:0]    afu_tlx_cmd_pg_size;

    wire          fen_afu_tlx_cmd_valid;
    wire [7:0]    fen_afu_tlx_cmd_opcode;
    wire [11:0]   fen_afu_tlx_cmd_actag;
    wire [3:0]    fen_afu_tlx_cmd_stream_id;
    wire [67:0]   fen_afu_tlx_cmd_ea_or_obj;
    wire [15:0]   fen_afu_tlx_cmd_afutag;
    wire [1:0]    fen_afu_tlx_cmd_dl;
    wire [2:0]    fen_afu_tlx_cmd_pl;
    wire          fen_afu_tlx_cmd_os;
    wire [63:0]   fen_afu_tlx_cmd_be;
    wire [3:0]    fen_afu_tlx_cmd_flag;
    wire          fen_afu_tlx_cmd_endian;
    wire [15:0]   fen_afu_tlx_cmd_bdf;
    wire [19:0]   fen_afu_tlx_cmd_pasid;
    wire [5:0]    fen_afu_tlx_cmd_pg_size;

    wire [511:0]  afu_tlx_cdata_bus;
    wire          afu_tlx_cdata_bdi;
    wire          afu_tlx_cdata_valid;

    // Table 9: TLX Framer Response Interface
    wire         afu_tlx_resp_valid;
    wire [7:0]   afu_tlx_resp_opcode;
    wire [1:0]   afu_tlx_resp_dl;
    wire [15:0]  afu_tlx_resp_capptag;
    wire [1:0]   afu_tlx_resp_dp;
    wire [3:0]   afu_tlx_resp_code;
    wire         afu_tlx_rdata_valid;
    wire [511:0] afu_tlx_rdata_bus;
    wire         afu_tlx_rdata_bdi;

    // Table 10: TLX Framer Template Configuration

    // Other wires
    wire            reset_n;
    // Table 1: TLX to AFU Response Interface
    wire          tlx_afu_resp_valid;
    wire [7:0]    tlx_afu_resp_opcode;
    wire [15:0]   tlx_afu_resp_afutag;
    wire [3:0]    tlx_afu_resp_code;
    wire [5:0]    tlx_afu_resp_pg_size;
    wire [1:0]    tlx_afu_resp_dl;
    wire [1:0]    tlx_afu_resp_dp;
    wire [23:0]   tlx_afu_resp_host_tag;
    wire [17:0]   tlx_afu_resp_addr_tag;
    wire [3:0]    tlx_afu_resp_cache_state;

    // Table 3: TLX to AFU Command Interface
    wire          tlx_afu_cmd_valid;
    wire [7:0]    tlx_afu_cmd_opcode;
    wire [15:0]   tlx_afu_cmd_capptag;
    wire [1:0]    tlx_afu_cmd_dl;
    wire [2:0]    tlx_afu_cmd_pl;
    wire [63:0]   tlx_afu_cmd_be;
    wire          tlx_afu_cmd_end;
    // wire         tlx_afu_cmd_t;
    wire [63:0]   tlx_afu_cmd_pa;
    wire [3:0]    tlx_afu_cmd_flag;
    wire          tlx_afu_cmd_os;

    // Table 5: TLX to AFU Response Data Interface
    reg           tlx_afu_resp_data_valid;
    reg [511:0]   tlx_afu_resp_data_bus;
    reg           tlx_afu_resp_data_bdi;

    // Table 6: TLX to AFU Command Data Interface
    wire          tlx_afu_cmd_data_valid;
    wire [511:0]  tlx_afu_cmd_data_bus;
    wire          tlx_afu_cmd_data_bdi;

    // Table 7: TLX Framer credit interface
    wire          tlx_afu_resp_credit;
    wire          tlx_afu_resp_data_credit;
    wire          tlx_afu_cmd_credit;
    wire          tlx_afu_cmd_data_credit;
    wire [3:0]    tlx_afu_cmd_initial_credit;
    wire [3:0]    tlx_afu_resp_initial_credit;
    wire [5:0]    tlx_afu_cmd_data_initial_credit;
    wire [5:0]    tlx_afu_resp_data_initial_credit;

    // These signals do not appear on the RefDesign Doc. However it is present
    // on the TLX spec
    wire          tlx_afu_ready;
    wire          tlx_cfg0_in_rcv_tmpl_capability_0;
    wire          tlx_cfg0_in_rcv_tmpl_capability_1;
    wire          tlx_cfg0_in_rcv_tmpl_capability_2;
    wire          tlx_cfg0_in_rcv_tmpl_capability_3;
    wire [3:0]    tlx_cfg0_in_rcv_rate_capability_0;
    wire [3:0]    tlx_cfg0_in_rcv_rate_capability_1;
    wire [3:0]    tlx_cfg0_in_rcv_rate_capability_2;
    wire [3:0]    tlx_cfg0_in_rcv_rate_capability_3;
    wire          tlx_cfg0_valid;
    wire [7:0]    tlx_cfg0_opcode;
    wire [63:0]   tlx_cfg0_pa;
    wire          tlx_cfg0_t;
    wire [2:0]    tlx_cfg0_pl;
    wire [15:0]   tlx_cfg0_capptag;
    wire [31:0]   tlx_cfg0_data_bus;
    wire          tlx_cfg0_data_bdi;
    wire          tlx_cfg0_resp_ack;
    wire [3:0]    cfg0_tlx_initial_credit;
    wire          cfg0_tlx_credit_return;
    wire          cfg0_tlx_resp_valid ;
    wire [7:0]    cfg0_tlx_resp_opcode;
    wire [15:0]   cfg0_tlx_resp_capptag;
    wire [3:0]    cfg0_tlx_resp_code ;
    wire [3:0]    cfg0_tlx_rdata_offset;
    wire [31:0]   cfg0_tlx_rdata_bus ;
    wire          cfg0_tlx_rdata_bdi ;
    wire [4:0]    ro_device;
    wire [31:0]   ro_dlx0_version ;                  // -- Connect to DLX output at next level, or tie off to all 0s
    wire [31:0]   tlx0_cfg_oc4_tlx_version ;         // -- (was ro_tlx0_version[31:0])
    wire [31:0]   flsh_cfg_rdata ;                   // -- Contains data read back from FLASH register (valid when rden=1 and 'flsh_done'=1)
    wire          flsh_cfg_done  ;                   // -- FLASH logic pulses to 1 for 1 cycle when write is complete, or when rdata contains valid results
    wire [7:0]    flsh_cfg_status;                   // -- Device Specific status information
    wire [1:0]    flsh_cfg_bresp ;                   // -- Write response from selected AXI4-Lite device
    wire [1:0]    flsh_cfg_rresp ;                   // -- Read  response from selected AXI4-Lite device

    // Integers
    integer         i;
    integer         resetCnt;
    // Sim related variables
    reg [0:63]     simulationTime ;
    reg            simulationError;

    // --  Wires added for ocse_top
    wire   [2612:0] trace_vector ;   // -- RG: sinkless at this point
    wire      [7:0] cfg_bus_num;
    wire      [4:0] cfg_device_num;
    wire      [2:0] cfg_function_num;


    wire           fen_tlx_afu_ready;
    wire           fen_tlx_afu_cmd_valid;
    wire     [7:0] fen_tlx_afu_cmd_opcode;
    wire    [15:0] fen_tlx_afu_cmd_capptag;
    wire     [1:0] fen_tlx_afu_cmd_dl;
    wire     [2:0] fen_tlx_afu_cmd_pl;
    wire    [63:0] fen_tlx_afu_cmd_be;
    wire           fen_tlx_afu_cmd_end;
    wire    [63:0] fen_tlx_afu_cmd_pa;
    wire     [3:0] fen_tlx_afu_cmd_flag;
    wire           fen_tlx_afu_cmd_os;

    wire           fen_tlx_afu_resp_valid;
    wire    [7:0]  fen_tlx_afu_resp_opcode;
    wire   [15:0]  fen_tlx_afu_resp_afutag;
    wire    [3:0]  fen_tlx_afu_resp_code;
    wire    [1:0]  fen_tlx_afu_resp_dl;
    wire    [1:0]  fen_tlx_afu_resp_dp;
    wire    [5:0]  fen_tlx_afu_resp_pg_size;
    wire   [17:0]  fen_tlx_afu_resp_addr_tag;
    wire   [23:0]  fen_tlx_afu_resp_host_tag;
    wire    [3:0]  fen_tlx_afu_resp_cache_state;

    wire           fen_afu_tlx_cmd_credit;
    wire    [6:0]  fen_afu_tlx_cmd_initial_credit;

    wire           fen_afu_tlx_resp_credit;
    wire    [6:0]  fen_afu_tlx_resp_initial_credit;

    wire           fen_afu_tlx_cmd_rd_req;
    wire    [2:0]  fen_afu_tlx_cmd_rd_cnt;

    wire           fen_tlx_afu_cmd_data_valid;
    wire  [511:0]  fen_tlx_afu_cmd_data_bus;
    wire           fen_tlx_afu_cmd_data_bdi;

    wire           fen_afu_tlx_resp_rd_req;
    wire    [2:0]  fen_afu_tlx_resp_rd_cnt;


    wire           fen_tlx_afu_resp_data_valid;
    wire   [511:0] fen_tlx_afu_resp_data_bus;
    wire           fen_tlx_afu_resp_data_bdi;


    wire     [3:0] fen_tlx_afu_cmd_initial_credit;
    wire           fen_tlx_afu_cmd_credit;

    wire     [5:0] fen_tlx_afu_cmd_data_initial_credit;
    wire           fen_tlx_afu_cmd_data_credit;

    wire  [511:0] fen_afu_tlx_cdata_bus;
    wire          fen_afu_tlx_cdata_bdi;
    wire          fen_afu_tlx_cdata_valid;

    wire    [3:0] fen_tlx_afu_resp_initial_credit;
    wire          fen_tlx_afu_resp_credit;

    wire    fen_afu_tlx_resp_valid;
    wire    [7:0] fen_afu_tlx_resp_opcode;
    wire    [1:0] fen_afu_tlx_resp_dl;
    wire   [15:0] fen_afu_tlx_resp_capptag;
    wire    [1:0] fen_afu_tlx_resp_dp;
    wire    [3:0] fen_afu_tlx_resp_code;
    wire          fen_afu_tlx_rdata_valid;
    wire  [511:0] fen_afu_tlx_rdata_bus;
    wire          fen_afu_tlx_rdata_bdi;

    wire     [5:0] fen_tlx_afu_resp_data_initial_credit;
    wire           fen_tlx_afu_resp_data_credit;


    wire         cfg_tlx_xmit_tmpl_config_0;   // -- cfg_tlx_xmit_*  left sinkless. Temporary
    wire         cfg_tlx_xmit_tmpl_config_1;
    wire         cfg_tlx_xmit_tmpl_config_2;
    wire         cfg_tlx_xmit_tmpl_config_3;
    wire   [3:0] cfg_tlx_xmit_rate_config_0;
    wire   [3:0] cfg_tlx_xmit_rate_config_1;
    wire   [3:0] cfg_tlx_xmit_rate_config_2;
    wire   [3:0] cfg_tlx_xmit_rate_config_3;
    wire         vpd_cfg_done;
    wire  [31:0] vpd_cfg_rdata;

    // -- Flash interface is not implemented yet in sim model
    wire   [1:0] cfg_flsh_devsel;  // --  left sinkless. Temporary
    wire  [13:0] cfg_flsh_addr;
    wire         cfg_flsh_wren;
    wire  [31:0] cfg_flsh_wdata;
    wire         cfg_flsh_rden;

    wire         cfg_flsh_expand_enable;
    wire         cfg_flsh_expand_dir;

    wire  [14:0] cfg_vpd_addr;
    wire         cfg_vpd_wren;
    wire  [31:0] cfg_vpd_wdata;
    wire         cfg_vpd_rden;


    wire         cfg_f1_octrl00_fence_afu;


    wire   [2:0] cfg_function;
    wire   [1:0] cfg_portnum;
    wire  [11:0] cfg_addr;
    wire  [31:0] cfg_wdata;
    wire  [31:0] cfg_f1_rdata;
    wire         cfg_f1_rdata_vld;
    wire         cfg_wr_1B;
    wire         cfg_wr_2B;
    wire         cfg_wr_4B;
    wire         cfg_rd;
    wire         cfg_f1_bad_op_or_align;
    wire         cfg_f1_addr_not_implemented;

    wire         cfg0_cff_fifo_overflow;
    wire         cfg0_rff_fifo_overflow;
    wire [127:0] cfg_errvec;
    wire         cfg_errvec_valid;


    wire  [31:0] cfg_ro_ovsec_tlx0_version;
    wire  [31:0] cfg_ro_ovsec_dlx0_version;

    wire   [3:0] cfg_f0_otl0_long_backoff_timer;
    wire   [3:0] cfg_f0_otl0_short_backoff_timer;

    wire         vpd_err_unimplemented_addr;

    wire  [31:0] f1_csh_expansion_rom_bar;       
    wire  [15:0] f1_csh_subsystem_id;
    wire  [15:0] f1_csh_subsystem_vendor_id;
    wire  [63:0] f1_csh_mmio_bar0_size;
    wire  [63:0] f1_csh_mmio_bar1_size;
    wire  [63:0] f1_csh_mmio_bar2_size;
    wire         f1_csh_mmio_bar0_prefetchable;
    wire         f1_csh_mmio_bar1_prefetchable;
    wire         f1_csh_mmio_bar2_prefetchable;
    wire   [4:0] f1_pasid_max_pasid_width;
    wire   [7:0] f1_ofunc_reset_duration;
    wire         f1_ofunc_afu_present;
    wire   [4:0] f1_ofunc_max_afu_index;
    wire   [7:0] f1_octrl00_reset_duration;
    wire   [5:0] f1_octrl00_afu_control_index;
    wire   [4:0] f1_octrl00_pasid_len_supported;
    wire         f1_octrl00_metadata_supported;
    wire  [11:0] f1_octrl00_actag_len_supported;
  
    // we define ethernet wires only if in simulation and emac requested (no loopback before emac)
    `ifdef ENABLE_ETHERNET
    `ifndef ENABLE_ETH_LOOP_BACK
    wire  gt_trx_gt_port_0_n;
    wire  gt_trx_gt_port_0_p;
    wire  gt_trx_gt_port_1_n;
    wire  gt_trx_gt_port_1_p;
    wire  gt_trx_gt_port_2_n;
    wire  gt_trx_gt_port_2_p;
    wire  gt_trx_gt_port_3_n;
    wire  gt_trx_gt_port_3_p;
    `endif
    `endif
 
    `ifdef ENABLE_DDR
        wire          c0_ddr4_act_n;
        wire  [16:0]  c0_ddr4_adr;
        wire  [1:0]   c0_ddr4_ba;
        wire  [1:0]   c0_ddr4_bg;
        wire  [0:0]   c0_ddr4_cke;
        wire  [0:0]   c0_ddr4_odt;
        wire  [0:0]   c0_ddr4_cs_n;
        wire  [0:0]   c0_ddr4_ck_t;
        wire  [0:0]   c0_ddr4_ck_c;
        wire          c0_ddr4_reset_n;
        wire  [8:0]   c0_ddr4_dm_dbi_n;
        wire  [71:0]  c0_ddr4_dq;
        wire  [8:0]   c0_ddr4_dqs_c;
        wire  [8:0]   c0_ddr4_dqs_t;
    `endif

    initial begin
        resetCnt = 0;
        i = 0;
        tlx_clock    <= 0;
        afu_clock    <= 0;
        reset        <= 1;

    `ifdef ENABLE_9H3_EEPROM
//        eeprom_scl   <= 0; // User can define this clk here
//        eeprom_sda   <= 0;
    `endif
    `ifdef ENABLE_9H3_AVR
        avr_rx       <= 0;
        avr_ck       <= 0;  // User can define this clk here
    `endif

        // Table 1: TLX to AFU Response Interface
        tlx_afu_resp_valid_top   <= 0;
        tlx_afu_resp_opcode_top   <= 8'b0;
        tlx_afu_resp_afutag_top   <= 16'b0;
        tlx_afu_resp_code_top   <= 4'b0;
        tlx_afu_resp_pg_size_top  <= 6'b0;
        tlx_afu_resp_dl_top   <= 2'b0;
        tlx_afu_resp_dp_top   <= 2'b0;
        tlx_afu_resp_host_tag_top  <= 24'b0;
        tlx_afu_resp_addr_tag_top  <= 18'b0;
        tlx_afu_resp_cache_state_top  <= 4'b0;

        // Table 3: TLX to AFU Command Interface
        tlx_afu_cmd_valid_top   <= 0;
        tlx_afu_cmd_opcode_top   <= 8'b0;
        tlx_afu_cmd_capptag_top   <= 16'b0;
        tlx_afu_cmd_dl_top   <= 2'b0;
        tlx_afu_cmd_pl_top   <= 3'b0;
        tlx_afu_cmd_be_top   <= 64'b0;
        tlx_afu_cmd_end_top   <= 0;
        // tlx_afu_cmd_t_top   <= 0;
        tlx_afu_cmd_pa_top   <= 64'b0;
        tlx_afu_cmd_flag_top   <= 4'b0;
        tlx_afu_cmd_os_top   <= 0;

        // Table 5: TLX to AFU Response Data Interface
        tlx_afu_resp_data_valid_top  <= 0;
        tlx_afu_resp_data_bus_top  <= 512'b0;
        tlx_afu_resp_data_bdi_top  <= 0;

        // Table 6: TLX to AFU Command Data Interface
        tlx_afu_cmd_data_valid_top  <= 0;
        tlx_afu_cmd_data_bus_top  <= 512'b0;
        tlx_afu_cmd_data_bdi_top  <= 0;

        // Table 7: TLX Framer credit interface
        tlx_afu_resp_credit_top   <= 0;
        tlx_afu_resp_data_credit_top  <= 0;
        tlx_afu_cmd_credit_top   <= 0;
        tlx_afu_cmd_data_credit_top  <= 0;
        tlx_afu_cmd_resp_initial_credit_top <= 4'b1000;
        tlx_afu_data_initial_credit_top <= 4'b0111;
        tlx_afu_cmd_data_initial_credit_top  <= 6'b100000;
        tlx_afu_resp_data_initial_credit_top <= 6'b100000;

        // These signals do not appear on the RefDesign Doc. However it is present
        // on the TLX spec
        tlx_afu_ready_top   <= 1;
        tlx_cfg0_in_rcv_tmpl_capability_0_top <= 0;
        tlx_cfg0_in_rcv_tmpl_capability_1_top <= 0;
        tlx_cfg0_in_rcv_tmpl_capability_2_top <= 0;
        tlx_cfg0_in_rcv_tmpl_capability_3_top <= 0;
        tlx_cfg0_in_rcv_rate_capability_0_top <= 4'b0;
        tlx_cfg0_in_rcv_rate_capability_1_top <= 4'b0;
        tlx_cfg0_in_rcv_rate_capability_2_top <= 4'b0;
        tlx_cfg0_in_rcv_rate_capability_3_top <= 4'b0;
        cfg_ro_ovsec_tlx0_version_top <= 32'b0;
        cfg_ro_ovsec_dlx0_version_top <= 32'b0;
        tlx_cfg0_valid_top    <= 0;
        tlx_cfg0_opcode_top    <= 8'b0;
        tlx_cfg0_pa_top    <= 64'b0;
        tlx_cfg0_t_top    <= 0;
        tlx_cfg0_pl_top    <= 3'b0;
        tlx_cfg0_capptag_top   <= 16'b0;
        tlx_cfg0_data_bus_top   <= 32'b0;
        tlx_cfg0_data_bdi_top   <= 0;
        tlx_cfg0_resp_ack_top   <= 0;
        ro_device_top    <= 5'b0;   //Updated per Jeff R's note of 23/Jun/2017
    end

    // Clock generation
    always begin
        tlx_clock = !tlx_clock; #1.25;
    end

    always @ (posedge tlx_clock) begin
        afu_clock = !afu_clock;
    end

    always @ ( tlx_clock ) begin
        if(resetCnt < 30)
            resetCnt = resetCnt + 1;
        else
            i = 1;
    end

    always @ ( tlx_clock ) begin
        if(resetCnt == RESET_CYCLES + 2)
            tlx_bfm_init(); #0;
    end

    always @ ( tlx_clock ) begin
        if(resetCnt < RESET_CYCLES)
            reset = 1'b1;
        else
            reset = 1'b0;
    end

    `ifdef ENABLE_DDR
        // SDRAM System Clock generation
        reg       sys_clk_p;
        initial   sys_clk_p <= 0;

        `ifdef AD9V3
            // 300.MHz DDR4 system clock
            always begin
                sys_clk_p = !sys_clk_p; #(3.332ns / 2.0); // a line can not start with "#", because SNAP is unsing the C preprocessor
            end
        `endif
        `ifdef BW250SOC
            // 200.MHz DDR4 system clock
            always begin
                sys_clk_p = !sys_clk_p; #(5.0ns / 2.0); // a line can not start with "#", because SNAP is unsing the C preprocessor
            end
        `endif

    `endif
    `ifdef AD9H3
    `ifdef ENABLE_ETHERNET
      `ifndef ENABLE_ETH_LOOP_BACK
        reg       gt_ref_clk_p;
        initial   gt_ref_clk_p <= 0;
        // 161.1132812MHz Ethernet system clock
        always begin
            gt_ref_clk_p = !gt_ref_clk_p; #(6.206 / 2.0); 
        end
      `endif
    `endif
    `endif

    reg sys_reset_n_q;
    initial begin
       sys_reset_n_q <= 1;  #10ns;   // a line can not start with "#", because SNAP is unsing the C preprocessor
       sys_reset_n_q <= 0;  #100ns;  // a line can not start with "#", because SNAP is unsing the C preprocessor
       sys_reset_n_q <= 1 ;
    end

    always @ (posedge tlx_clock) begin
        afu_tlx_resp_credit_top               <= afu_tlx_resp_credit;
        afu_tlx_resp_initial_credit_top       <= afu_tlx_resp_initial_credit;
        afu_tlx_cmd_credit_top                <= afu_tlx_cmd_credit;
        afu_tlx_cmd_initial_credit_top        <= afu_tlx_cmd_initial_credit;
        afu_tlx_resp_rd_req_top               <= afu_tlx_resp_rd_req;
        afu_tlx_resp_rd_cnt_top               <= afu_tlx_resp_rd_cnt;
        afu_tlx_cmd_rd_req_top                <= afu_tlx_cmd_rd_req;
        afu_tlx_cmd_rd_cnt_top                <= afu_tlx_cmd_rd_cnt;
        afu_tlx_cmd_valid_top                 <= afu_tlx_cmd_valid;
        afu_tlx_cmd_opcode_top                <= afu_tlx_cmd_opcode;
        afu_tlx_cmd_actag_top                 <= afu_tlx_cmd_actag;
        afu_tlx_cmd_stream_id_top             <= afu_tlx_cmd_stream_id;
        afu_tlx_cmd_ea_or_obj_top             <= afu_tlx_cmd_ea_or_obj;
        afu_tlx_cmd_afutag_top                <= afu_tlx_cmd_afutag;
        afu_tlx_cmd_dl_top                    <= afu_tlx_cmd_dl;
        afu_tlx_cmd_pl_top                    <= afu_tlx_cmd_pl;
        afu_tlx_cmd_os_top                    <= afu_tlx_cmd_os;
        afu_tlx_cmd_be_top                    <= afu_tlx_cmd_be;
        afu_tlx_cmd_flag_top                  <= afu_tlx_cmd_flag;
        afu_tlx_cmd_endian_top                <= afu_tlx_cmd_endian;
        afu_tlx_cmd_bdf_top                   <= afu_tlx_cmd_bdf;
        afu_tlx_cmd_pasid_top                 <= afu_tlx_cmd_pasid;
        afu_tlx_cmd_pg_size_top               <= afu_tlx_cmd_pg_size;
        afu_tlx_cdata_bus_top                 <= afu_tlx_cdata_bus;
        afu_tlx_cdata_bdi_top                 <= afu_tlx_cdata_bdi;
        afu_tlx_cdata_valid_top               <= afu_tlx_cdata_valid;
        afu_tlx_resp_valid_top                <= afu_tlx_resp_valid;
        afu_tlx_resp_opcode_top               <= afu_tlx_resp_opcode;
        afu_tlx_resp_dl_top                   <= afu_tlx_resp_dl;
        afu_tlx_resp_capptag_top              <= afu_tlx_resp_capptag;
        afu_tlx_resp_dp_top                   <= afu_tlx_resp_dp;
        afu_tlx_resp_code_top                 <= afu_tlx_resp_code;
        afu_tlx_rdata_valid_top               <= afu_tlx_rdata_valid;
        afu_tlx_rdata_bus_top                 <= afu_tlx_rdata_bus;
        afu_tlx_rdata_bdi_top                 <= afu_tlx_rdata_bdi;
        cfg0_tlx_initial_credit_top  <= cfg0_tlx_initial_credit; // new
        cfg0_tlx_credit_return_top  <= cfg0_tlx_credit_return;  // new lgt
        cfg0_tlx_resp_valid_top              <= cfg0_tlx_resp_valid;
        cfg0_tlx_resp_opcode_top             <= cfg0_tlx_resp_opcode;
        cfg0_tlx_resp_capptag_top            <= cfg0_tlx_resp_capptag;
        cfg0_tlx_resp_code_top               <= cfg0_tlx_resp_code;
        cfg0_tlx_rdata_offset_top            <= cfg0_tlx_rdata_offset;
        cfg0_tlx_rdata_bus_top               <= cfg0_tlx_rdata_bus;
        cfg0_tlx_rdata_bdi_top               <= cfg0_tlx_rdata_bdi;
    end

    assign  reset_n  = !reset;

    // Pass Through Signals
    // Table 1: TLX to AFU Response Interface
    assign  tlx_afu_resp_valid  = tlx_afu_resp_valid_top;
    assign  tlx_afu_resp_opcode  = tlx_afu_resp_opcode_top;
    assign  tlx_afu_resp_afutag  = tlx_afu_resp_afutag_top;
    assign  tlx_afu_resp_code  = tlx_afu_resp_code_top;
    assign  tlx_afu_resp_pg_size  = tlx_afu_resp_pg_size_top;
    assign  tlx_afu_resp_dl   = tlx_afu_resp_dl_top;
    assign  tlx_afu_resp_dp   = tlx_afu_resp_dp_top;
    assign  tlx_afu_resp_host_tag  = tlx_afu_resp_host_tag_top;
    assign  tlx_afu_resp_addr_tag  = tlx_afu_resp_addr_tag_top;
    assign  tlx_afu_resp_cache_state = tlx_afu_resp_cache_state_top;

    // Table 3: TLX to AFU Command Interface
    assign  tlx_afu_cmd_valid  = tlx_afu_cmd_valid_top;
    assign  tlx_afu_cmd_opcode  = tlx_afu_cmd_opcode_top;
    assign  tlx_afu_cmd_capptag  = tlx_afu_cmd_capptag_top;
    assign  tlx_afu_cmd_dl   = tlx_afu_cmd_dl_top;
    assign  tlx_afu_cmd_pl   = tlx_afu_cmd_pl_top;
    assign  tlx_afu_cmd_be   = tlx_afu_cmd_be_top;
    assign  tlx_afu_cmd_end   = tlx_afu_cmd_end_top;
    // assign  tlx_afu_cmd_t   = tlx_afu_cmd_t_top;
    assign  tlx_afu_cmd_pa   = tlx_afu_cmd_pa_top;
    assign  tlx_afu_cmd_flag  = tlx_afu_cmd_flag_top;
    assign  tlx_afu_cmd_os   = tlx_afu_cmd_os_top;

    // Table 5: TLX to AFU Response Data Interface
    always @( negedge tlx_clock ) begin
        tlx_afu_resp_data_valid  <= tlx_afu_resp_data_valid_dly1;
        tlx_afu_resp_data_bus  <= tlx_afu_resp_data_bus_dly1;
        tlx_afu_resp_data_bdi  <= tlx_afu_resp_data_bdi_dly1;
     end

    // Table 6: TLX to AFU Command Data Interface
    assign  tlx_afu_cmd_data_valid  = tlx_afu_cmd_data_valid_top;
    assign  tlx_afu_cmd_data_bus  = tlx_afu_cmd_data_bus_top;
    assign  tlx_afu_cmd_data_bdi  = tlx_afu_cmd_data_bdi_top;

    // Table 7: TLX Framer credit interface
    assign  tlx_afu_resp_credit   = tlx_afu_resp_credit_top;
    assign  tlx_afu_resp_data_credit  = tlx_afu_resp_data_credit_top;
    assign  tlx_afu_cmd_credit   = tlx_afu_cmd_credit_top;
    assign  tlx_afu_cmd_data_credit   = tlx_afu_cmd_data_credit_top;
    assign  tlx_afu_cmd_initial_credit  = tlx_afu_cmd_resp_initial_credit_top;
    assign  tlx_afu_resp_initial_credit  = tlx_afu_data_initial_credit_top;
    assign  tlx_afu_cmd_data_initial_credit  = tlx_afu_cmd_data_initial_credit_top;
    assign  tlx_afu_resp_data_initial_credit = tlx_afu_resp_data_initial_credit_top;

    // These signals do not appear on the RefDesign Doc. However it is present
    // on the TLX spec
    assign  tlx_afu_ready                     = tlx_afu_ready_top;
    assign  ro_device                         = ro_device_top;
    assign  tlx_cfg0_in_rcv_tmpl_capability_0 = tlx_cfg0_in_rcv_tmpl_capability_0_top;
    assign  tlx_cfg0_in_rcv_tmpl_capability_1 = tlx_cfg0_in_rcv_tmpl_capability_1_top;
    assign  tlx_cfg0_in_rcv_tmpl_capability_2 = tlx_cfg0_in_rcv_tmpl_capability_2_top;
    assign  tlx_cfg0_in_rcv_tmpl_capability_3 = tlx_cfg0_in_rcv_tmpl_capability_3_top;
    assign  tlx_cfg0_in_rcv_rate_capability_0 = tlx_cfg0_in_rcv_rate_capability_0_top;
    assign  tlx_cfg0_in_rcv_rate_capability_1 = tlx_cfg0_in_rcv_rate_capability_1_top;
    assign  tlx_cfg0_in_rcv_rate_capability_2 = tlx_cfg0_in_rcv_rate_capability_2_top;
    assign  tlx_cfg0_in_rcv_rate_capability_3 = tlx_cfg0_in_rcv_rate_capability_3_top;
    assign  cfg_ro_ovsec_tlx0_version         = cfg_ro_ovsec_tlx0_version_top;
    assign  cfg_ro_ovsec_dlx0_version         = cfg_ro_ovsec_dlx0_version_top;

    assign tlx_cfg0_valid                     = tlx_cfg0_valid_top;
    assign  tlx_cfg0_opcode                   = tlx_cfg0_opcode_top;
    assign  tlx_cfg0_pa                       = tlx_cfg0_pa_top;
    assign  tlx_cfg0_t                        = tlx_cfg0_t_top;
    assign  tlx_cfg0_pl                       = tlx_cfg0_pl_top;
    assign  tlx_cfg0_capptag                  = tlx_cfg0_capptag_top;
    assign  tlx_cfg0_data_bus                 = tlx_cfg0_data_bus_top;
    assign  tlx_cfg0_data_bdi                 = tlx_cfg0_data_bdi_top;
    assign  tlx_cfg0_resp_ack                 = tlx_cfg0_resp_ack_top;
    assign  ro_dlx0_version                   = 32'b0;
    assign  tlx0_cfg_oc4_tlx_version          = 32'b0;

    assign  flsh_cfg_rdata                    = 32'b0;
    assign  flsh_cfg_done                     = 1'b0;
    assign  flsh_cfg_status                   = 8'b0;
    assign  flsh_cfg_bresp                    = 2'b0;
    assign  flsh_cfg_rresp                    = 2'b0;

    // a block to delay the resp_data path 1 cycle
    // todo: variable number of cycles from 1 to n
    always @ ( negedge tlx_clock ) begin
        tlx_afu_resp_data_valid_dly1 <= tlx_afu_resp_data_valid_top;
        tlx_afu_resp_data_bus_dly1 <= tlx_afu_resp_data_bus_top;
        tlx_afu_resp_data_bdi_dly1 <= tlx_afu_resp_data_bdi_top;
    end

    always @ ( negedge tlx_clock ) begin
        tlx_afu_resp_data_valid_dly2 <= tlx_afu_resp_data_valid_dly1;
        tlx_afu_resp_data_bus_dly2 <= tlx_afu_resp_data_bus_dly1;
        tlx_afu_resp_data_bdi_dly2 <= tlx_afu_resp_data_bdi_dly1;
    end

    always @ ( tlx_clock ) begin
        simulationTime = $time; #0;
        set_simulation_time(simulationTime); #0;
        tlx_bfm(
            tlx_clock,
            afu_clock,
            reset,
            // Table 1: TLX to AFU Response Interface
            tlx_afu_resp_valid_top,
            tlx_afu_resp_opcode_top,
            tlx_afu_resp_afutag_top,
            tlx_afu_resp_code_top,
            tlx_afu_resp_pg_size_top,
            tlx_afu_resp_dl_top,
            tlx_afu_resp_dp_top,
            tlx_afu_resp_host_tag_top,
            tlx_afu_resp_addr_tag_top,
            tlx_afu_resp_cache_state_top,

            // Table 2: TLX Response Credit Interface
            afu_tlx_resp_credit_top,
            afu_tlx_resp_initial_credit_top,

            // Table 3: TLX to AFU Command Interface
            tlx_afu_cmd_valid_top,
            tlx_afu_cmd_opcode_top,
            tlx_afu_cmd_capptag_top,
            tlx_afu_cmd_dl_top,
            tlx_afu_cmd_pl_top,
            tlx_afu_cmd_be_top,
            tlx_afu_cmd_end_top,
            // tlx_afu_cmd_t_top,
            tlx_afu_cmd_pa_top,
            tlx_afu_cmd_flag_top,
            tlx_afu_cmd_os_top,

            // Table 4: TLX Command Credit Interface
            afu_tlx_cmd_credit_top,
            afu_tlx_cmd_initial_credit_top,

            // Table 5: TLX to AFU Response Data Interface
            tlx_afu_resp_data_valid_top,
            tlx_afu_resp_data_bus_top,
            tlx_afu_resp_data_bdi_top,
            afu_tlx_resp_rd_req_top,
            afu_tlx_resp_rd_cnt_top,

            // Table 6: TLX to AFU Command Data Interface
            tlx_afu_cmd_data_valid_top,
            tlx_afu_cmd_data_bus_top,
            tlx_afu_cmd_data_bdi_top,
            afu_tlx_cmd_rd_req_top,
            afu_tlx_cmd_rd_cnt_top,

            // Table 7: TLX Framer credit interface
            tlx_afu_resp_credit_top,
            tlx_afu_resp_data_credit_top,
            tlx_afu_cmd_credit_top,
            tlx_afu_cmd_data_credit_top,
            tlx_afu_cmd_resp_initial_credit_top,
            tlx_afu_data_initial_credit_top,
            tlx_afu_cmd_data_initial_credit_top,
            tlx_afu_resp_data_initial_credit_top,

            // Table 8: TLX Framer Command Interface
            afu_tlx_cmd_valid_top,
            afu_tlx_cmd_opcode_top,
            afu_tlx_cmd_actag_top,
            afu_tlx_cmd_stream_id_top,
            afu_tlx_cmd_ea_or_obj_top,
            afu_tlx_cmd_afutag_top,
            afu_tlx_cmd_dl_top,
            afu_tlx_cmd_pl_top,
            afu_tlx_cmd_os_top,
            afu_tlx_cmd_be_top,
            afu_tlx_cmd_flag_top,
            afu_tlx_cmd_endian_top,
            afu_tlx_cmd_bdf_top,
            afu_tlx_cmd_pasid_top,
            afu_tlx_cmd_pg_size_top,
            afu_tlx_cdata_bus_top,
            afu_tlx_cdata_bdi_top,// TODO: TLX Ref Design doc lists this as afu_tlx_cdata_bad
            afu_tlx_cdata_valid_top,

            // Table 9: TLX Framer Response Interface
            afu_tlx_resp_valid_top,
            afu_tlx_resp_opcode_top,
            afu_tlx_resp_dl_top,
            afu_tlx_resp_capptag_top,
            afu_tlx_resp_dp_top,
            afu_tlx_resp_code_top,
            afu_tlx_rdata_valid_top,
            afu_tlx_rdata_bus_top,
            afu_tlx_rdata_bdi_top,
            tlx_afu_ready_top,

            tlx_cfg0_in_rcv_tmpl_capability_0_top,
            tlx_cfg0_in_rcv_tmpl_capability_1_top,
            tlx_cfg0_in_rcv_tmpl_capability_2_top,
            tlx_cfg0_in_rcv_tmpl_capability_3_top,
            tlx_cfg0_in_rcv_rate_capability_0_top,
            tlx_cfg0_in_rcv_rate_capability_1_top,
            tlx_cfg0_in_rcv_rate_capability_2_top,
            tlx_cfg0_in_rcv_rate_capability_3_top,

            tlx_cfg0_valid_top,
            tlx_cfg0_opcode_top,
            tlx_cfg0_pa_top,
            tlx_cfg0_t_top,
            tlx_cfg0_pl_top,
            tlx_cfg0_capptag_top,
            tlx_cfg0_data_bus_top,
            tlx_cfg0_data_bdi_top,
            tlx_cfg0_resp_ack_top,

            cfg0_tlx_initial_credit_top,
            cfg0_tlx_credit_return_top,
            cfg0_tlx_resp_valid_top ,
            cfg0_tlx_resp_opcode_top,
            cfg0_tlx_resp_capptag_top,
            cfg0_tlx_resp_code_top ,
            cfg0_tlx_rdata_offset_top,
            cfg0_tlx_rdata_bus_top ,
            cfg0_tlx_rdata_bdi_top,
            ro_device_top
        );
    end

    always @ (negedge tlx_clock) begin
        get_simuation_error(simulationError); #0;
    end

    always @ (posedge tlx_clock) begin
        if(simulationError) begin
            $finish;
        end
    end


// -- ********************************************************************************************************************************
// -- AFU
// -- ********************************************************************************************************************************

    oc_function oc_function (
        // -- Clocks & Reset
        .clock_tlx                          ( tlx_clock                                 ),
        .clock_afu                          ( afu_clock                                 ),
        .reset                          ( ~reset_n                                  ),

        // -- Bus number comes from CFG_SEQ
        .cfg_bus                        ( cfg_bus_num                               ),  // -- Attached to TLX Port 0, so use cfg0_ instance
        .ro_device                     ( cfg_device_num                            ),  // -- Attached to TLX Port 0, so use cfg0_ instance

        // -- Device/Function
        .ro_function                   ( 3'b001                                      ),  // -- Defined in (this function instance is number 1)

        // -- TLX_AFU command receive interface
        .tlx_afu_ready                      ( fen_tlx_afu_ready                         ),
        .tlx_afu_cmd_valid                  ( fen_tlx_afu_cmd_valid                     ),
        .tlx_afu_cmd_opcode                 ( fen_tlx_afu_cmd_opcode[7:0]               ),
        .tlx_afu_cmd_capptag                ( fen_tlx_afu_cmd_capptag[15:0]             ),
        .tlx_afu_cmd_dl                     ( fen_tlx_afu_cmd_dl[1:0]                   ),
        .tlx_afu_cmd_pl                     ( fen_tlx_afu_cmd_pl[2:0]                   ),
        .tlx_afu_cmd_be                     ( fen_tlx_afu_cmd_be[63:0]                  ),
        .tlx_afu_cmd_end                    ( fen_tlx_afu_cmd_end                       ),
        .tlx_afu_cmd_pa                     ( fen_tlx_afu_cmd_pa[63:0]                  ),
        .tlx_afu_cmd_flag                   ( fen_tlx_afu_cmd_flag[3:0]                 ),
        .tlx_afu_cmd_os                     ( fen_tlx_afu_cmd_os                        ),

        .afu_tlx_cmd_credit                 ( fen_afu_tlx_cmd_credit                        ),
        .afu_tlx_cmd_initial_credit         ( fen_afu_tlx_cmd_initial_credit[6:0]           ),

        .afu_tlx_cmd_rd_req                 ( fen_afu_tlx_cmd_rd_req                        ),
        .afu_tlx_cmd_rd_cnt                 ( fen_afu_tlx_cmd_rd_cnt[2:0]                   ),

        .tlx_afu_cmd_data_valid             ( fen_tlx_afu_cmd_data_valid                ),
        .tlx_afu_cmd_data_bdi               ( fen_tlx_afu_cmd_data_bdi                  ),
        .tlx_afu_cmd_data_bus               ( fen_tlx_afu_cmd_data_bus[511:0]           ),

        // -- AFU_TLX response transmit interface
        .afu_tlx_resp_valid                 ( fen_afu_tlx_resp_valid                        ),
        .afu_tlx_resp_opcode                ( fen_afu_tlx_resp_opcode[7:0]                  ),
        .afu_tlx_resp_dl                    ( fen_afu_tlx_resp_dl[1:0]                      ),
        .afu_tlx_resp_capptag               ( fen_afu_tlx_resp_capptag[15:0]                ),
        .afu_tlx_resp_dp                    ( fen_afu_tlx_resp_dp[1:0]                      ),
        .afu_tlx_resp_code                  ( fen_afu_tlx_resp_code[3:0]                    ),

        .afu_tlx_rdata_valid                ( fen_afu_tlx_rdata_valid                       ),
        .afu_tlx_rdata_bdi                  ( fen_afu_tlx_rdata_bdi                         ),
        .afu_tlx_rdata_bus                  ( fen_afu_tlx_rdata_bus[511:0]                  ),

        .tlx_afu_resp_credit                ( fen_tlx_afu_resp_credit                   ),
        .tlx_afu_resp_data_credit           ( fen_tlx_afu_resp_data_credit              ),

        // -- AFU_TLX command transmit interface
        .afu_tlx_cmd_valid                  ( fen_afu_tlx_cmd_valid                         ),
        .afu_tlx_cmd_opcode                 ( fen_afu_tlx_cmd_opcode[7:0]                   ),
        .afu_tlx_cmd_actag                  ( fen_afu_tlx_cmd_actag[11:0]                   ),
        .afu_tlx_cmd_stream_id              ( fen_afu_tlx_cmd_stream_id[3:0]                ),
        .afu_tlx_cmd_ea_or_obj              ( fen_afu_tlx_cmd_ea_or_obj[67:0]               ),
        .afu_tlx_cmd_afutag                 ( fen_afu_tlx_cmd_afutag[15:0]                  ),
        .afu_tlx_cmd_dl                     ( fen_afu_tlx_cmd_dl[1:0]                       ),
        .afu_tlx_cmd_pl                     ( fen_afu_tlx_cmd_pl[2:0]                       ),
        .afu_tlx_cmd_os                     ( fen_afu_tlx_cmd_os                            ),
        .afu_tlx_cmd_be                     ( fen_afu_tlx_cmd_be[63:0]                      ),
        .afu_tlx_cmd_flag                   ( fen_afu_tlx_cmd_flag[3:0]                     ),
        .afu_tlx_cmd_endian                 ( fen_afu_tlx_cmd_endian                        ),
        .afu_tlx_cmd_bdf                    ( fen_afu_tlx_cmd_bdf[15:0]                     ),
        .afu_tlx_cmd_pasid                  ( fen_afu_tlx_cmd_pasid[19:0]                   ),
        .afu_tlx_cmd_pg_size                ( fen_afu_tlx_cmd_pg_size[5:0]                  ),

        .afu_tlx_cdata_valid                ( fen_afu_tlx_cdata_valid                       ),
        .afu_tlx_cdata_bdi                  ( fen_afu_tlx_cdata_bdi                         ),
        .afu_tlx_cdata_bus                  ( fen_afu_tlx_cdata_bus[511:0]                  ),

        .tlx_afu_cmd_credit                 ( fen_tlx_afu_cmd_credit                    ),
        .tlx_afu_cmd_data_credit            ( fen_tlx_afu_cmd_data_credit               ),

        .tlx_afu_cmd_initial_credit         ( fen_tlx_afu_cmd_initial_credit[3:0]       ),
        .tlx_afu_cmd_data_initial_credit    ( fen_tlx_afu_cmd_data_initial_credit[5:0]  ),
        .tlx_afu_resp_initial_credit        ( fen_tlx_afu_resp_initial_credit[3:0]      ),
        .tlx_afu_resp_data_initial_credit   ( fen_tlx_afu_resp_data_initial_credit[5:0] ),

        // -- TLX_AFU response receive interface
        .tlx_afu_resp_valid                 ( fen_tlx_afu_resp_valid                    ),
        .tlx_afu_resp_opcode                ( fen_tlx_afu_resp_opcode[7:0]              ),
        .tlx_afu_resp_afutag                ( fen_tlx_afu_resp_afutag[15:0]             ),
        .tlx_afu_resp_code                  ( fen_tlx_afu_resp_code[3:0]                ),
        .tlx_afu_resp_dl                    ( fen_tlx_afu_resp_dl[1:0]                  ),
        .tlx_afu_resp_dp                    ( fen_tlx_afu_resp_dp[1:0]                  ),
        .tlx_afu_resp_pg_size               ( fen_tlx_afu_resp_pg_size[5:0]             ),
        .tlx_afu_resp_addr_tag              ( fen_tlx_afu_resp_addr_tag[17:0]           ),
        //.tlx_afu_resp_host_tag              ( tlx_afu_resp_host_tag[23:0]               ),  // -- Reserved for CAPI 4.0
        //.tlx_afu_resp_cache_state           ( tlx_afu_resp_cache_state[3:0]             ),  // -- Reserved for CAPI 4.0

        .afu_tlx_resp_rd_req                ( fen_afu_tlx_resp_rd_req                       ),
        .afu_tlx_resp_rd_cnt                ( fen_afu_tlx_resp_rd_cnt[2:0]                  ),

        .tlx_afu_resp_data_valid            ( fen_tlx_afu_resp_data_valid               ),
        .tlx_afu_resp_data_bdi              ( fen_tlx_afu_resp_data_bdi                 ),
        .tlx_afu_resp_data_bus              ( fen_tlx_afu_resp_data_bus[511:0]          ),

        .afu_tlx_resp_credit                ( fen_afu_tlx_resp_credit                       ),
        .afu_tlx_resp_initial_credit        ( fen_afu_tlx_resp_initial_credit[6:0]          ),

`ifdef ENABLE_ETHERNET
`ifndef ENABLE_ETH_LOOP_BACK
    .gt_ref_clk_n      ( ~gt_ref_clk_p       )
   ,.gt_ref_clk_p      ( gt_ref_clk_p        )
   ,.gt_rx_gt_port_0_n ( gt_trx_gt_port_0_n  )
   ,.gt_rx_gt_port_0_p ( gt_trx_gt_port_0_p  )
   ,.gt_rx_gt_port_1_n ( gt_trx_gt_port_1_n  )
   ,.gt_rx_gt_port_1_p ( gt_trx_gt_port_1_p  )
   ,.gt_rx_gt_port_2_n ( gt_trx_gt_port_2_n  )
   ,.gt_rx_gt_port_2_p ( gt_trx_gt_port_2_p  )
   ,.gt_rx_gt_port_3_n ( gt_trx_gt_port_3_n  )
   ,.gt_rx_gt_port_3_p ( gt_trx_gt_port_3_p  )
   ,.gt_tx_gt_port_0_n ( gt_trx_gt_port_0_n  )
   ,.gt_tx_gt_port_0_p ( gt_trx_gt_port_0_p  )
   ,.gt_tx_gt_port_1_n ( gt_trx_gt_port_1_n  )
   ,.gt_tx_gt_port_1_p ( gt_trx_gt_port_1_p  )
   ,.gt_tx_gt_port_2_n ( gt_trx_gt_port_2_n  )
   ,.gt_tx_gt_port_2_p ( gt_trx_gt_port_2_p  )
   ,.gt_tx_gt_port_3_n ( gt_trx_gt_port_3_n  )
   ,.gt_tx_gt_port_3_p ( gt_trx_gt_port_3_p  ),
`endif
`endif

// EXTRA_IO 
`ifdef ENABLE_9H3_LED
    .user_led_a0     ()        // These outputs can be user defined
   ,.user_led_a1     ()
   ,.user_led_g0     ()
   ,.user_led_g1     (),
`endif

`ifdef ENABLE_9H3_EEPROM
    .eeprom_scl       (eeprom_scl)
   ,.eeprom_sda       (eeprom_sda)
   ,.eeprom_wp        (),      // This output can be user defined
`endif

`ifdef ENABLE_9H3_AVR
    .avr_rx          (avr_rx)
   ,.avr_tx          ()        // This output can be user defined
   ,.avr_ck          (avr_ck),
 `endif


        `ifdef ENABLE_DDR
          `ifdef AD9V3
            // DDR4
            .c0_sys_clk_p           (sys_clk_p),
            .c0_sys_clk_n           (~sys_clk_p),
            .c0_ddr4_act_n          (c0_ddr4_act_n),
            .c0_ddr4_adr            (c0_ddr4_adr),
            .c0_ddr4_ba             (c0_ddr4_ba),
            .c0_ddr4_bg             (c0_ddr4_bg),
            .c0_ddr4_cke            (c0_ddr4_cke),
            .c0_ddr4_odt            (c0_ddr4_odt),
            .c0_ddr4_cs_n           (c0_ddr4_cs_n),
            .c0_ddr4_ck_t           (c0_ddr4_ck_t),
            .c0_ddr4_ck_c           (c0_ddr4_ck_c),
            .c0_ddr4_reset_n        (c0_ddr4_reset_n),
            .c0_ddr4_dm_dbi_n       (c0_ddr4_dm_dbi_n),
            .c0_ddr4_dq             (c0_ddr4_dq),
            .c0_ddr4_dqs_c          (c0_ddr4_dqs_c),
            .c0_ddr4_dqs_t          (c0_ddr4_dqs_t),
          `endif
          `ifdef BW250SOC
            // DDR4
            .c0_sys_clk_p           (sys_clk_p),
            .c0_sys_clk_n           (~sys_clk_p),
            .c0_ddr4_act_n          (c0_ddr4_act_n),
            .c0_ddr4_adr            (c0_ddr4_adr),
            .c0_ddr4_ba             (c0_ddr4_ba),
            .c0_ddr4_bg             (c0_ddr4_bg),
            .c0_ddr4_cke            (c0_ddr4_cke),
            .c0_ddr4_odt            (c0_ddr4_odt),
            .c0_ddr4_cs_n           (c0_ddr4_cs_n),
            .c0_ddr4_ck_t           (c0_ddr4_ck_t),
            .c0_ddr4_ck_c           (c0_ddr4_ck_c),
            .c0_ddr4_reset_n        (c0_ddr4_reset_n),
            .c0_ddr4_dm_dbi_n       (c0_ddr4_dm_dbi_n),
            .c0_ddr4_dq             (c0_ddr4_dq),
            .c0_ddr4_dqs_c          (c0_ddr4_dqs_c),
            .c0_ddr4_dqs_t          (c0_ddr4_dqs_t),
          `endif
        `endif

        // -- Configuration Sequencer Interface [cfg_seq -> cfg_func<n> (n=1-7)]
        .cfg_function                       ( cfg_function[2:0]                         ),
        .cfg_portnum                        ( cfg_portnum[1:0]                          ),
        .cfg_addr                           ( cfg_addr[11:0]                            ),
        .cfg_wdata                          ( cfg_wdata[31:0]                           ),
        .cfg_f1_rdata                       ( cfg_f1_rdata[31:0]                        ),
        .cfg_f1_rdata_vld                   ( cfg_f1_rdata_vld                          ),
        .cfg_wr_1B                          ( cfg_wr_1B                                 ),
        .cfg_wr_2B                          ( cfg_wr_2B                                 ),
        .cfg_wr_4B                          ( cfg_wr_4B                                 ),
        .cfg_rd                             ( cfg_rd                                    ),
        .cfg_f1_bad_op_or_align             ( cfg_f1_bad_op_or_align                    ),
        .cfg_f1_addr_not_implemented        ( cfg_f1_addr_not_implemented               ),

        // -- Fence control
        .cfg_f1_octrl00_fence_afu           ( cfg_f1_octrl00_fence_afu                  ),

        // -- TLX Configuration for the TLX port(s) connected to AFUs under this Function
        .cfg_f0_otl0_long_backoff_timer     ( cfg_f0_otl0_long_backoff_timer[3:0]       ),
        .cfg_f0_otl0_short_backoff_timer    ( cfg_f0_otl0_short_backoff_timer[3:0]      ),

        // -- Error signals into MMIO capture register
        .vpd_err_unimplemented_addr         ( vpd_err_unimplemented_addr                ),
        .cfg0_cff_fifo_overflow             ( cfg0_cff_fifo_overflow                    ),
        .cfg0_rff_fifo_overflow             ( cfg0_rff_fifo_overflow                    ),
        .cfg_errvec                         ( cfg_errvec[127:0]                         ),
        .cfg_errvec_valid                   ( cfg_errvec_valid                          ),

        .f1_csh_expansion_rom_bar           ( f1_csh_expansion_rom_bar                  ), 
        .f1_csh_subsystem_id                ( f1_csh_subsystem_id                       ),
        .f1_csh_subsystem_vendor_id         ( f1_csh_subsystem_vendor_id                ),
        .f1_csh_mmio_bar0_size              ( f1_csh_mmio_bar0_size                     ),
        .f1_csh_mmio_bar1_size              ( f1_csh_mmio_bar1_size                     ),
        .f1_csh_mmio_bar2_size              ( f1_csh_mmio_bar2_size                     ),
        .f1_csh_mmio_bar0_prefetchable      ( f1_csh_mmio_bar0_prefetchable             ),
        .f1_csh_mmio_bar1_prefetchable      ( f1_csh_mmio_bar1_prefetchable             ),
        .f1_csh_mmio_bar2_prefetchable      ( f1_csh_mmio_bar2_prefetchable             ),
        .f1_pasid_max_pasid_width           ( f1_pasid_max_pasid_width                  ),
        .f1_ofunc_reset_duration            ( f1_ofunc_reset_duration                   ),
        .f1_ofunc_afu_present               ( f1_ofunc_afu_present                      ),
        .f1_ofunc_max_afu_index             ( f1_ofunc_max_afu_index                    ),
        .f1_octrl00_reset_duration          ( f1_octrl00_reset_duration                 ),
        .f1_octrl00_afu_control_index       ( f1_octrl00_afu_control_index              ),
        .f1_octrl00_pasid_len_supported     ( f1_octrl00_pasid_len_supported            ),
        .f1_octrl00_metadata_supported      ( f1_octrl00_metadata_supported             ),
        .f1_octrl00_actag_len_supported     ( f1_octrl00_actag_len_supported            )
    );

    assign  vpd_err_unimplemented_addr = 1'b0;     // -- VPD not yet in current design

// -- ********************************************************************************************************************************
// -- CONFIG
// -- ********************************************************************************************************************************

    oc_cfg oc_cfg(
        //.fen_trace_vector                     ( trace_vector                              ),  //--output [2612:0]

        //--      Clocks & Reset
        //.clock_tlx                            ( tlx_clock                                 ),  //-- input
        //.clock_afu                            ( afu_clock                                 ),  //-- input
        .clock                                ( tlx_clock                                 ),
        .reset_n                              ( reset_n                                   ),  //-- input

        //--      Bus and device numbers come from CFG_SEQ
        .cfg0_bus_num                          ( cfg_bus_num                               ),  //-- output   [7:0]  Extracted from config_write command
        .cfg0_device_num                       ( cfg_device_num                            ),  //-- output   [4:0]  Extracted from config_write command
        .ro_device                             ( ro_device                            ),  //-- ro_device input

        //--      Hardcoded configuration outputs
        //.cfg_function_num                     ( cfg_function_num                          ),  //-- output   [2:0]  oc_function instance is number 1

        //--      AFU command receive interface.  To fence
        .tlx_afu_ready                        ( tlx_afu_ready                             ),  //-- input           TLX indicates it is ready to receive cmds and responses from AFU.

        //--      AFU command receive interface.  Fenced TL_VC.1
        .fen_afu_ready                    ( fen_tlx_afu_ready                         ),  //-- output          Fenced.  TLX indicates it is ready to receive cmds and responses from AFU

        //--      AFU CMD credit to Fence component.  TL_VC.1  Flow control
        .afu_tlx_cmd_credit                   ( afu_tlx_cmd_credit                        ),  //-- input           AFU returns cmd credit to TLX
        .afu_tlx_cmd_initial_credit           ( afu_tlx_cmd_initial_credit                ),  //-- input    [6:0]  AFU indicates number of command credits available (static value),

        //--      fenced Parser TL_VC;1 FC to oc_bsp
        .afu_fen_cmd_initial_credit       ( fen_afu_tlx_cmd_initial_credit            ),  //-- output   [6:0]  fenced Parser TL_VC;1 FC  .
        .afu_fen_cmd_credit               ( fen_afu_tlx_cmd_credit                    ),  //-- output          fenced Parser TL_VC;1 FC  .

        //--      Parser TL_VC;1  From oc_bsp to Fence
        .tlx_afu_cmd_valid                    ( tlx_afu_cmd_valid                         ),  //-- input           Parser TL_VC;1 Command Valid (Receive),
        .tlx_afu_cmd_opcode                   ( tlx_afu_cmd_opcode                        ),  //-- input    [7:0]  Parser TL_VC;1 Command Opcode
        .tlx_afu_cmd_dl                       ( tlx_afu_cmd_dl                            ),  //-- input    [1:0]  Parser TL_VC;1 Command Tag
        .tlx_afu_cmd_end                      ( tlx_afu_cmd_end                           ),  //-- input           Parser TL_VC;1 Command Data Length
        .tlx_afu_cmd_pa                       ( tlx_afu_cmd_pa                            ),  //-- input   [63:0]  Parser TL_VC;1 Command Partial Length
        .tlx_afu_cmd_flag                     ( tlx_afu_cmd_flag                          ),  //-- input    [3:0]  Parser TL_VC;1 Command Byte Enable
        .tlx_afu_cmd_os                       ( tlx_afu_cmd_os                            ),  //-- input           Parser TL_VC;1 Endianness
        .tlx_afu_cmd_capptag                  ( tlx_afu_cmd_capptag                       ),  //-- input   [15:0]  Parser TL_VC;1 Physical Address
        .tlx_afu_cmd_pl                       ( tlx_afu_cmd_pl                            ),  //-- input    [2:0]  Parser TL_VC;1 Atomic memory operation specifier
        .tlx_afu_cmd_be                       ( tlx_afu_cmd_be                            ),  //-- input   [63:0]  Parser TL_VC;1 Ordered segment

        //--      Fenced Parser TL VC1 CMD tags
        .fen_afu_cmd_valid                ( fen_tlx_afu_cmd_valid                     ),  //-- output          Command Valid (Receive),
        .fen_afu_cmd_opcode               ( fen_tlx_afu_cmd_opcode                    ),  //-- output   [7:0]  Command Opcode
        .fen_afu_cmd_capptag              ( fen_tlx_afu_cmd_capptag                   ),  //-- output  [15:0]  Command Tag
        .fen_afu_cmd_dl                   ( fen_tlx_afu_cmd_dl                        ),  //-- output   [1:0]  Command Data Length
        .fen_afu_cmd_pl                   ( fen_tlx_afu_cmd_pl                        ),  //-- output   [2:0]  Command Partial Length
        .fen_afu_cmd_be                   ( fen_tlx_afu_cmd_be                        ),  //-- output  [63:0]  Command Byte Enable
        .fen_afu_cmd_end                  ( fen_tlx_afu_cmd_end                       ),  //-- output          Endianness
        .fen_afu_cmd_pa                   ( fen_tlx_afu_cmd_pa                        ),  //-- output  [63:0]  Physical Address
        .fen_afu_cmd_flag                 ( fen_tlx_afu_cmd_flag                      ),  //-- output   [3:0]  Atomic memory operation specifier
        .fen_afu_cmd_os                   ( fen_tlx_afu_cmd_os                        ),  //-- output          Ordered segment

        //--      Config Command Flow Control to oc_bsp
        .cfg0_tlx_initial_credit               ( cfg0_tlx_initial_credit                   ),  //-- output   [3:0]
        .cfg0_tlx_credit_return                ( cfg0_tlx_credit_return                    ),  //-- output

         //--      Port 0: config_write/read commands from host to oc_cfg  cfg_cmdfifo
        .tlx_cfg0_valid                        ( tlx_cfg0_valid                            ),  //-- input
        .tlx_cfg0_opcode                       ( tlx_cfg0_opcode                           ),  //-- input   [7:0]
        .tlx_cfg0_pa                           ( tlx_cfg0_pa                               ),  //-- input  [63:0]
        .tlx_cfg0_t                            ( tlx_cfg0_t                                ),  //-- input
        .tlx_cfg0_pl                           ( tlx_cfg0_pl                               ),  //-- input   [2:0]
        .tlx_cfg0_capptag                      ( tlx_cfg0_capptag                          ),  //-- input  [15:0]
        .tlx_cfg0_data_bus                     ( tlx_cfg0_data_bus                         ),  //-- input  [31:0]
        .tlx_cfg0_data_bdi                     ( tlx_cfg0_data_bdi                         ),  //-- input

        //--      Fenced TL VC.0 FC. To oc_bsp
        .afu_tlx_resp_credit                  ( afu_tlx_resp_credit                       ),  //-- input           AFU returns resp credit to TLX
        .afu_tlx_resp_initial_credit          ( afu_tlx_resp_initial_credit               ),  //-- input    [6:0]  AFU indicates number of response credits available (static value),

        .afu_fen_resp_initial_credit      ( fen_afu_tlx_resp_initial_credit           ),  //-- output   [6:0]
        .afu_fen_resp_credit              ( fen_afu_tlx_resp_credit                   ),  //-- output

        //--      Parser TLX_AFU response receive interface  (TL  VC0), To fence
        .tlx_afu_resp_valid                   ( tlx_afu_resp_valid                        ),  //-- input           Indicates TLX has a valid resp for AFU to process.
        .tlx_afu_resp_opcode                  ( tlx_afu_resp_opcode                       ),  //-- input    [7:0]  (w/resp_valid), Resp Opcode .
        .tlx_afu_resp_afutag                  ( tlx_afu_resp_afutag                       ),  //-- input   [15:0]  (w/resp_valid), Resp Tag.
        .tlx_afu_resp_code                    ( tlx_afu_resp_code                         ),  //-- input    [3:0]  (w/resp_valid), Describes the reason for a failed transaction.
        .tlx_afu_resp_pg_size                 ( tlx_afu_resp_pg_size                      ),  //-- input    [5:0]  (w/resp_valid), Page size.
        .tlx_afu_resp_dl                      ( tlx_afu_resp_dl                           ),  //-- input    [1:0]  (w/resp_valid), Resp Data Length (00=rsvd,. 01=64B,. 10=128B,. 11=256B),.
        .tlx_afu_resp_dp                      ( tlx_afu_resp_dp                           ),  //-- input    [1:0]  (w/resp_valid), Data Part,. indicates the data content of the current resp packet.
        .tlx_afu_resp_addr_tag                ( tlx_afu_resp_addr_tag                     ),  //-- input   [17:0]  (w/resp_valid), Address translation tag for use by AFU with dot-t format commands.
        .tlx_afu_resp_host_tag                ( tlx_afu_resp_host_tag                     ),  // Reserved for CAPI 4.0 //--       input   [23:0]  (w/resp_valid), Tag for data held in AFU L1 (unsupported,. CAPI 4.0 feature),.
        .tlx_afu_resp_cache_state             ( tlx_afu_resp_cache_state                  ),  // Reserved for CAPI 4.0 //--       input    [3:0]  (w/resp_valid), Gives cache state of cache line obtained.

        //--      TLX_AFU response receive interface  (TL  VC0),
        .fen_afu_resp_valid               ( fen_tlx_afu_resp_valid                    ),  //-- output          Response Valid (Receive),
        .fen_afu_resp_opcode              ( fen_tlx_afu_resp_opcode                   ),  //-- output   [7:0]  Response Opcode
        .fen_afu_resp_afutag              ( fen_tlx_afu_resp_afutag                   ),  //-- output  [15:0]  Response Tag
        .fen_afu_resp_code                ( fen_tlx_afu_resp_code                     ),  //-- output   [3:0]  Response Code - reason for failed transation
        .fen_afu_resp_dl                  ( fen_tlx_afu_resp_dl                       ),  //-- output   [1:0]  Response Data Length
        .fen_afu_resp_dp                  ( fen_tlx_afu_resp_dp                       ),  //-- output   [1:0]  Response Data Part - indictes the data content of the current response packet
        .fen_afu_resp_pg_size             ( fen_tlx_afu_resp_pg_size                  ),  //-- output   [5:0]  Not used in this implementation
        .fen_afu_resp_addr_tag            ( fen_tlx_afu_resp_addr_tag                 ),  //-- output  [17:0]  Not used in this implementation
        // New signals for Configure logic - qianqc Apr 12th
        .fen_afu_resp_host_tag            ( fen_tlx_afu_resp_host_tag                 ),  // Reserved for CAPI 4.0 //--       output  [23:0]  (w/resp_valid), Tag for data held in AFU L1 (unsupported,. CAPI 4.0 feature),.
        .fen_afu_resp_cache_state         ( fen_tlx_afu_resp_cache_state              ),  // Reserved for CAPI 4.0 //--       output   [3:0]  (w/resp_valid), Gives cache state of cache line obtained.

        // -- Command data interface to AFU  (TL DCP1)
        .afu_tlx_cmd_rd_req                   ( afu_tlx_cmd_rd_req                        ),  //-- input           Command Read Request
        .afu_tlx_cmd_rd_cnt                   ( afu_tlx_cmd_rd_cnt                        ),  //-- input    [2:0]  Command Read Count

        .afu_fen_cmd_rd_req               ( fen_afu_tlx_cmd_rd_req                    ),  //-- output
        .afu_fen_cmd_rd_cnt               ( fen_afu_tlx_cmd_rd_cnt                    ),  //-- output   [2:0]

        //--      TL_DCP1 Command DATA to fence .
        .tlx_afu_cmd_data_valid               ( tlx_afu_cmd_data_valid                    ),  //-- input           Command Data Valid,. when 1 valid data is present on cmd_data_bus
        .tlx_afu_cmd_data_bus                 ( tlx_afu_cmd_data_bus                      ),  //-- input  [511:0]  Command Data Bus;  (w/cmd_data_valid),, contains the command for the AFU to process
        .tlx_afu_cmd_data_bdi                 ( tlx_afu_cmd_data_bdi                      ),  //-- input           (w/cmd_data_valid), Bad Data Indicator, when 1 data FLIT is corrupted

        .fen_afu_cmd_data_valid           ( fen_tlx_afu_cmd_data_valid                ),  //-- output          Command Data Valid. Indicates valid data available
        .fen_afu_cmd_data_bus             ( fen_tlx_afu_cmd_data_bus                  ),  //-- output [511:0]  Command Data Bus
        .fen_afu_cmd_data_bdi             ( fen_tlx_afu_cmd_data_bdi                  ),  //-- output          Command Data Bad Data Indicator

        //--      fenced Parser TL_DCP0 Read control.
        .afu_tlx_resp_rd_req                  ( afu_tlx_resp_rd_req                       ),  //-- input           Response Read Request
        .afu_tlx_resp_rd_cnt                  ( afu_tlx_resp_rd_cnt                       ),  //-- input    [2:0]  Response Read Count

        .afu_fen_resp_rd_req              ( fen_afu_tlx_resp_rd_req                   ),  //-- output          Response Read Request .
        .afu_fen_resp_rd_cnt              ( fen_afu_tlx_resp_rd_cnt                   ),  //-- output   [2:0]  Response Read Count,. number of 64B flits requested (000 is not useful), .

        //--       Parser TL_DCP0 to fence.
        .tlx_afu_resp_data_valid              ( tlx_afu_resp_data_valid                   ),  //-- input           Response Valid,. when 1 valid data is present on resp_data
        .tlx_afu_resp_data_bus                ( tlx_afu_resp_data_bus                     ),  //-- input  [511:0]  (w/resp_data_valid), Response Data,. contains data for a read request
        .tlx_afu_resp_data_bdi                ( tlx_afu_resp_data_bdi                     ),  //-- input           (w/resp_data_valid), Bad Data Indicator,. when 1 data FLIT is corrupted

        .fen_afu_resp_data_valid          ( fen_tlx_afu_resp_data_valid               ),  //-- output          Response Data Valid. Indicates valid data available
        .fen_afu_resp_data_bdi            ( fen_tlx_afu_resp_data_bdi                 ),  //-- output          Response Data Bad Data Indicator
        .fen_afu_resp_data_bus            ( fen_tlx_afu_resp_data_bus                 ),  //-- output [511:0]  Response Data Bus

        //--      Framer  TLX_VC3 FC to fence.
        .tlx_afu_cmd_initial_credit           ( tlx_afu_cmd_initial_credit                ),  //-- input    [3:0]  TLX informs AFU cmd credits available
        .tlx_afu_cmd_credit                   ( tlx_afu_cmd_credit                        ),  //-- input           TLX returns cmd credit to AFU when cmd taken from FIFO by DLX

        .fen_afu_cmd_initial_credit       ( fen_tlx_afu_cmd_initial_credit            ),  //-- output   [3:0]  TLX informs AFU cmd credits available       02/08/18 - Split credit Interface Change
        .fen_afu_cmd_credit               ( fen_tlx_afu_cmd_credit                    ),  //-- output          TLX returns cmd credit to AFU when cmd taken from FIFO by DLX

        //--      Fence AFU_TLX command transmit interface. (Framer TLX  VC3),
        .afu_tlx_cmd_valid                    ( afu_tlx_cmd_valid                         ),  //-- input           Command Valid (Transmit),
        .afu_tlx_cmd_opcode                   ( afu_tlx_cmd_opcode                        ),  //-- input    [7:0]  Command Opcode
        .afu_tlx_cmd_actag                    ( afu_tlx_cmd_actag                         ),  //-- input   [11:0]  Address Context Tag
        .afu_tlx_cmd_stream_id                ( afu_tlx_cmd_stream_id                     ),  //-- input    [3:0]  Stream ID
        .afu_tlx_cmd_ea_or_obj                ( afu_tlx_cmd_ea_or_obj                     ),  //-- input   [67:0]  Effective Address/Object Handle
        .afu_tlx_cmd_afutag                   ( afu_tlx_cmd_afutag                        ),  //-- input   [15:0]  Command Tag
        .afu_tlx_cmd_dl                       ( afu_tlx_cmd_dl                            ),  //-- input    [1:0]  Command Data Length
        .afu_tlx_cmd_pl                       ( afu_tlx_cmd_pl                            ),  //-- input    [2:0]  Partial Length
        .afu_tlx_cmd_os                       ( afu_tlx_cmd_os                            ),  //-- input           Ordered Segment
        .afu_tlx_cmd_be                       ( afu_tlx_cmd_be                            ),  //-- input   [63:0]  Byte Enable
        .afu_tlx_cmd_flag                     ( afu_tlx_cmd_flag                          ),  //-- input    [3:0]  Command Flag, used in atomic operations
        .afu_tlx_cmd_endian                   ( afu_tlx_cmd_endian                        ),  //-- input           Endianness
        .afu_tlx_cmd_bdf                      ( afu_tlx_cmd_bdf                           ),  //-- input   [15:0]  Bus Device Function
        .afu_tlx_cmd_pasid                    ( afu_tlx_cmd_pasid                         ),  //-- input   [19:0]  User Process ID
        .afu_tlx_cmd_pg_size                  ( afu_tlx_cmd_pg_size                       ),  //-- input    [5:0]  Page Size

        .afu_fen_cmd_valid                ( fen_afu_tlx_cmd_valid                     ),  //-- output          Command Valid (Transmit),
        .afu_fen_cmd_opcode               ( fen_afu_tlx_cmd_opcode                    ),  //-- output   [7:0]  Command Opcode
        .afu_fen_cmd_actag                ( fen_afu_tlx_cmd_actag                     ),  //-- output  [11:0]  Address Context Tag
        .afu_fen_cmd_stream_id            ( fen_afu_tlx_cmd_stream_id                 ),  //-- output   [3:0]  Stream ID
        .afu_fen_cmd_ea_or_obj            ( fen_afu_tlx_cmd_ea_or_obj                 ),  //-- output  [67:0]  Effective Address/Object Handle
        .afu_fen_cmd_afutag               ( fen_afu_tlx_cmd_afutag                    ),  //-- output  [15:0]  Command Tag
        .afu_fen_cmd_dl                   ( fen_afu_tlx_cmd_dl                        ),  //-- output   [1:0]  Command Data Length
        .afu_fen_cmd_pl                   ( fen_afu_tlx_cmd_pl                        ),  //-- output   [2:0]  Partial Length
        .afu_fen_cmd_os                   ( fen_afu_tlx_cmd_os                        ),  //-- output          Ordered Segment
        .afu_fen_cmd_be                   ( fen_afu_tlx_cmd_be                        ),  //-- output  [63:0]  Byte Enable
        .afu_fen_cmd_flag                 ( fen_afu_tlx_cmd_flag                      ),  //-- output   [3:0]  Command Flag, used in atomic operations
        .afu_fen_cmd_endian               ( fen_afu_tlx_cmd_endian                    ),  //-- output          Endianness
        .afu_fen_cmd_bdf                  ( fen_afu_tlx_cmd_bdf                       ),  //-- output  [15:0]  Bus Device Function
        .afu_fen_cmd_pasid                ( fen_afu_tlx_cmd_pasid                     ),  //-- output  [19:0]  User Process ID
        .afu_fen_cmd_pg_size              ( fen_afu_tlx_cmd_pg_size                   ),  //-- output   [5:0]  Page Size

        //--        Framer TLX  DCP3 FC to Fence.
        .tlx_afu_cmd_data_initial_credit      ( tlx_afu_cmd_data_initial_credit           ),  //-- input    [5:0]  Number of starting credits from TLX for both AFU->TLX cmd data interface
        .tlx_afu_cmd_data_credit              ( tlx_afu_cmd_data_credit                   ),  //-- input           TLX returns cmd data credit to AFU when cmd data taken from FIFO by DLX

        .fen_afu_cmd_data_initial_credit  ( fen_tlx_afu_cmd_data_initial_credit       ),  //-- output   [5:0]  TLX informs AFU cmd data credits available
        .fen_afu_cmd_data_credit          ( fen_tlx_afu_cmd_data_credit               ),  //-- output          TLX returns cmd data credit to AFU when cmd data taken from FIFO by DLX

        //--      Fenced Framer TLX DCP3 Data.
        .afu_tlx_cdata_valid                  ( afu_tlx_cdata_valid                       ),  //-- input           Command Data Valid. Indicates valid data available
        .afu_tlx_cdata_bdi                    ( afu_tlx_cdata_bdi                         ),  //-- input           Command Data Bad Data Indicator
        .afu_tlx_cdata_bus                    ( afu_tlx_cdata_bus                         ),  //-- input  [511:0]  Command Data Bus

        .afu_fen_cdata_valid              ( fen_afu_tlx_cdata_valid                   ),  //-- output
        .afu_fen_cdata_bus                ( fen_afu_tlx_cdata_bus                     ),  //-- output [511:0]
        .afu_fen_cdata_bdi                ( fen_afu_tlx_cdata_bdi                     ),  //-- output

        //--      Framer TLX VC.0 FC to Fence.
        .tlx_afu_resp_initial_credit          ( tlx_afu_resp_initial_credit               ),  //-- input    [3:0]  TLX informs AFU resp credits available
        .tlx_afu_resp_credit                  ( tlx_afu_resp_credit                       ),  //-- input           TLX returns resp credit to AFU when resp taken from FIFO by DLX

        .fen_afu_resp_initial_credit      ( fen_tlx_afu_resp_initial_credit           ),  //-- output   [3:0]
        .fen_afu_resp_credit              ( fen_tlx_afu_resp_credit                   ),  //-- output

        //--      Fenced AFU_TLX response transmit interface (Framer TLX VC0),
        .afu_tlx_resp_valid                   ( afu_tlx_resp_valid                        ),  //-- input           Response Valid (Transmit),
        .afu_tlx_resp_opcode                  ( afu_tlx_resp_opcode                       ),  //-- input    [7:0]  Response Opcode
        .afu_tlx_resp_dl                      ( afu_tlx_resp_dl                           ),  //-- input    [1:0]  Response Data Length
        .afu_tlx_resp_capptag                 ( afu_tlx_resp_capptag                      ),  //-- input   [15:0]  Response Tag
        .afu_tlx_resp_dp                      ( afu_tlx_resp_dp                           ),  //-- input    [1:0]  Response Data Part - indictes the data content of the current response packet
        .afu_tlx_resp_code                    ( afu_tlx_resp_code                         ),  //-- input    [3:0]  Response Code - reason for failed transation


        .afu_fen_resp_valid               (  fen_afu_tlx_resp_valid                   ),  //-- output          Response Valid (Transmit),
        .afu_fen_resp_opcode              (  fen_afu_tlx_resp_opcode                  ),  //-- output   [7:0]  Response Opcode
        .afu_fen_resp_dl                  (  fen_afu_tlx_resp_dl                      ),  //-- output   [1:0]  Response Data Length
        .afu_fen_resp_capptag             (  fen_afu_tlx_resp_capptag                 ),  //-- output  [15:0]  Response Tag
        .afu_fen_resp_dp                  (  fen_afu_tlx_resp_dp                      ),  //-- output   [1:0]  Response Data Part - indictes the data content of the current response packet
        .afu_fen_resp_code                (  fen_afu_tlx_resp_code                    ),  //-- output   [3:0]  Response Code - reason for failed transation

        //--      Framer TLX_DCP0 FC to fence.
        .tlx_afu_resp_data_initial_credit     ( tlx_afu_resp_data_initial_credit          ),  //-- input    [5:0]  Number of starting credits from TLX for both AFU->TLX resp data interface
        .tlx_afu_resp_data_credit             ( tlx_afu_resp_data_credit                  ),  //-- input           TLX returns resp data credit to AFU when resp data taken from FIFO by DLX

        .fen_afu_resp_data_initial_credit ( fen_tlx_afu_resp_data_initial_credit      ),  //-- output   [5:0]  TLX informs AFU resp data credits available     02/08/18 - Split credit Interface Change
        .fen_afu_resp_data_credit         ( fen_tlx_afu_resp_data_credit              ),  //-- output          TLX returns resp data credit to AFU when resp data taken from FIFO by DLX

        //--       Fenced Framer TLX_ DCP3
        .afu_tlx_rdata_valid                  ( afu_tlx_rdata_valid                       ),  //-- input           Response Valid
        .afu_tlx_rdata_bdi                    ( afu_tlx_rdata_bdi                         ),  //-- input           Response Bad Data Indicator
        .afu_tlx_rdata_bus                    ( afu_tlx_rdata_bus                         ),  //-- input  [511:0]  Response Opcode

        .afu_fen_rdata_valid              ( fen_afu_tlx_rdata_valid                   ),  //-- output          Response Valid
        .afu_fen_rdata_bus                ( fen_afu_tlx_rdata_bus                     ),  //-- output [511:0]  Response Bad Data Indicator
        .afu_fen_rdata_bdi                ( fen_afu_tlx_rdata_bdi                     ),  //-- output          Response Opcode

        //--      Port 0: config_* responses back to host. From oc_cfg  cfg_respfifo
        .cfg0_tlx_resp_valid                   ( cfg0_tlx_resp_valid                       ),  //-- output          Tell TLX when a response is ready for it to send
        .cfg0_tlx_resp_opcode                  ( cfg0_tlx_resp_opcode                      ),  //-- output   [7:0]
        .cfg0_tlx_resp_capptag                 ( cfg0_tlx_resp_capptag                     ),  //-- output  [15:0]
        .cfg0_tlx_resp_code                    ( cfg0_tlx_resp_code                        ),  //-- output   [3:0]
        .cfg0_tlx_rdata_offset                 ( cfg0_tlx_rdata_offset                     ),  //-- output   [3:0]
        .cfg0_tlx_rdata_bus                    ( cfg0_tlx_rdata_bus                        ),  //-- output  [31:0]
        .cfg0_tlx_rdata_bdi                    ( cfg0_tlx_rdata_bdi                        ),  //-- output

        .tlx_cfg0_resp_ack                     ( tlx_cfg0_resp_ack                         ),  //-- input           TLX indicates current valid response has been sent

        .cfg0_tlx_xmit_tmpl_config_0           ( cfg_tlx_xmit_tmpl_config_0                ),  //-- output
        .cfg0_tlx_xmit_tmpl_config_1           ( cfg_tlx_xmit_tmpl_config_1                ),  //-- output
        .cfg0_tlx_xmit_tmpl_config_2           ( cfg_tlx_xmit_tmpl_config_2                ),  //-- output
        .cfg0_tlx_xmit_tmpl_config_3           ( cfg_tlx_xmit_tmpl_config_3                ),  //-- output
        .cfg0_tlx_xmit_rate_config_0           ( cfg_tlx_xmit_rate_config_0                ),  //-- output  [3:0]
        .cfg0_tlx_xmit_rate_config_1           ( cfg_tlx_xmit_rate_config_1                ),  //-- output  [3:0]
        .cfg0_tlx_xmit_rate_config_2           ( cfg_tlx_xmit_rate_config_2                ),  //-- output  [3:0]
        .cfg0_tlx_xmit_rate_config_3           ( cfg_tlx_xmit_rate_config_3                ),  //-- output  [3:0]

        .tlx_cfg0_in_rcv_tmpl_capability_0     ( tlx_cfg0_in_rcv_tmpl_capability_0         ),  //-- output
        .tlx_cfg0_in_rcv_tmpl_capability_1     ( tlx_cfg0_in_rcv_tmpl_capability_1         ),  //-- output
        .tlx_cfg0_in_rcv_tmpl_capability_2     ( tlx_cfg0_in_rcv_tmpl_capability_2         ),  //-- output
        .tlx_cfg0_in_rcv_tmpl_capability_3     ( tlx_cfg0_in_rcv_tmpl_capability_3         ),  //-- output
        .tlx_cfg0_in_rcv_rate_capability_0     ( tlx_cfg0_in_rcv_rate_capability_0         ),  //-- output  [3:0]
        .tlx_cfg0_in_rcv_rate_capability_1     ( tlx_cfg0_in_rcv_rate_capability_1         ),  //-- output  [3:0]
        .tlx_cfg0_in_rcv_rate_capability_2     ( tlx_cfg0_in_rcv_rate_capability_2         ),  //-- output  [3:0]
        .tlx_cfg0_in_rcv_rate_capability_3     ( tlx_cfg0_in_rcv_rate_capability_3         ),  //-- output  [3:0]


        // .cfg_ro_ovsec_tlx0_version            ( cfg_ro_ovsec_tlx0_version                 ),  //-- input   [31:0]
        // .cfg_ro_ovsec_tlx1_version            ( 32'h00000000                              ),  //-- input   [31:0]
        // .cfg_ro_ovsec_tlx2_version            ( 32'h00000000                              ),  //-- input   [31:0]
        // .cfg_ro_ovsec_tlx3_version            ( 32'h00000000                              ),  //-- input   [31:0]

        // .cfg_ro_ovsec_dlx0_version            ( cfg_ro_ovsec_dlx0_version                 ),  //-- input   [31:0]
        // .cfg_ro_ovsec_dlx1_version            ( 32'h00000000                              ),  //-- input   [31:0]
        // .cfg_ro_ovsec_dlx2_version            ( 32'h00000000                              ),  //-- input   [31:0]
        // .cfg_ro_ovsec_dlx3_version            ( 32'h00000000                              ),  //-- input   [31:0]

        //--      Interface to FLASH control logic
        .cfg_flsh_devsel                      ( cfg_flsh_devsel                           ),  //-- output   [1:0]  Select AXI4-Lite device to target
        .cfg_flsh_addr                        ( cfg_flsh_addr                             ),  //-- output  [13:0]  Read or write address to selected target
        .cfg_flsh_wren                        ( cfg_flsh_wren                             ),  //-- output          Set to 1 to write a location, hold at 1 until see 'flsh_done' = 1 then clear to 0
        .cfg_flsh_wdata                       ( cfg_flsh_wdata                            ),  //-- output  [31:0]  Contains data to write to FLASH register (valid while wren=1),
        .cfg_flsh_rden                        ( cfg_flsh_rden                             ),  //-- output          Set to 1 to read  a location, hold at 1 until see 'flsh_done' = 1 the clear to 0
        .flsh_cfg_rdata                       ( flsh_cfg_rdata                            ),  //-- input   [31:0]  Contains data read back from FLASH register (valid when rden=1 and 'flsh_done'=1),
        .flsh_cfg_done                        ( flsh_cfg_done                             ),  //-- input           FLASH logic pulses to 1 for 1 cycle when write is complete, or when rdata contains valid results
        .flsh_cfg_status                      ( flsh_cfg_status                           ),  //-- input    [7:0]  Device Specific status information
        .flsh_cfg_bresp                       ( flsh_cfg_bresp                            ),  //-- input    [1:0]  Write response from selected AXI4-Lite device
        .flsh_cfg_rresp                       ( flsh_cfg_rresp                            ),  //-- input    [1:0]  Read  response from selected AXI4-Lite device

        .cfg_flsh_expand_enable               ( cfg_flsh_expand_enable                    ),  //-- output          When 1, expand/collapse 4 bytes of data into four, 1 byte AXI operations
        .cfg_flsh_expand_dir                  ( cfg_flsh_expand_dir                       ),  //-- output          When 0, expand bytes [3:0] in order 0,1,2,3 . When 1, expand in order 3,2,1,0 .

        //--      Interface to VPD STUB
        .cfg_vpd_addr                         ( cfg_vpd_addr                              ),  //-- output  [14:0]
        .cfg_vpd_wren                         ( cfg_vpd_wren                              ),  //-- output
        .cfg_vpd_wdata                        ( cfg_vpd_wdata                             ),  //-- output  [31:0]
        .cfg_vpd_rden                         ( cfg_vpd_rden                              ),  //-- output
        .vpd_cfg_rdata                        ( vpd_cfg_rdata                             ),  //-- input   [31:0]  Tied down  temporary
        .vpd_cfg_done                         ( vpd_cfg_done                              ),  //-- input           Tied down  temporary

        //--      Error signals into MMIO capture register
        .cfg0_cff_fifo_overflow               ( cfg0_cff_fifo_overflow                    ),  //-- output
        .cfg0_rff_fifo_overflow               ( cfg0_rff_fifo_overflow                    ),  //-- output
        .cfg_errvec                           ( cfg_errvec                                ),  //-- output [127:0]
        .cfg_errvec_valid                     ( cfg_errvec_valid                          ),  //-- output

        // OpenCAPI TL - port 0
        //.cfg_ro_otl0_rcv_tmpl_capbl           ( { 60'h0000_0000_0000_000,
        //                                        tlx_cfg0_in_rcv_tmpl_capability_3,
        //                                        tlx_cfg0_in_rcv_tmpl_capability_2,
        //                                        tlx_cfg0_in_rcv_tmpl_capability_1,
        //                                        tlx_cfg0_in_rcv_tmpl_capability_0 }       ),  //-- input   [63:0]  // = 64'h0000_0000_0000_0001 // Template 0 must be supported

        //.cfg_ro_otl0_rcv_rate_tmpl_capbl      ( { {60{4'b0000}},
        //                                        tlx_cfg0_in_rcv_rate_capability_3[3:0],
        //                                        tlx_cfg0_in_rcv_rate_capability_2[3:0],
        //                                        tlx_cfg0_in_rcv_rate_capability_1[3:0],
        //                                        tlx_cfg0_in_rcv_rate_capability_0[3:0] }  ),  //-- input  [255:0]  // = { {63{4'b0000}},4'b1111 } // Template 0 supports slowest speed of '1111'

        //--      Configuration Sequencer Interface [cfg_seq -> cfg_func<n> (n=1-7),]
        .cfg_function                         ( cfg_function                              ),  //-- output   [2:0]
        .cfg_portnum                          ( cfg_portnum                               ),  //-- output   [1:0]
        .cfg_addr                             ( cfg_addr                                  ),  //-- output  [11:0]
        .cfg_wdata                            ( cfg_wdata                                 ),  //-- output  [31:0]
        .cfg_f1_rdata                         ( cfg_f1_rdata                              ),  //-- input   [31:0]
        .cfg_f1_rdata_vld                     ( cfg_f1_rdata_vld                          ),  //-- input
        .cfg_wr_1B                            ( cfg_wr_1B                                 ),  //-- output
        .cfg_wr_2B                            ( cfg_wr_2B                                 ),  //-- output
        .cfg_wr_4B                            ( cfg_wr_4B                                 ),  //-- output
        .cfg_rd                               ( cfg_rd                                    ),  //-- output

        .cfg_f1_bad_op_or_align               ( cfg_f1_bad_op_or_align                    ),  //-- input
        .cfg_f1_addr_not_implemented          ( cfg_f1_addr_not_implemented               ),  //-- input

        //--      Fence control
        .cfg_f1_octrl00_fence_afu             ( cfg_f1_octrl00_fence_afu                  ),  //-- input

        //--      TLX Configuration for the TLX port(s), connected to AFUs under this Function
        .cfg_f0_otl0_long_backoff_timer       ( cfg_f0_otl0_long_backoff_timer            ),  //-- output   [3:0]
        .cfg_f0_otl0_short_backoff_timer      ( cfg_f0_otl0_short_backoff_timer           ),  //-- output   [3:0]

        .f1_csh_expansion_rom_bar             ( f1_csh_expansion_rom_bar                  ), 
        .f1_csh_subsystem_id                  ( f1_csh_subsystem_id                       ),
        .f1_csh_subsystem_vendor_id           ( f1_csh_subsystem_vendor_id                ),
        .f1_csh_mmio_bar0_size                ( f1_csh_mmio_bar0_size                     ),
        .f1_csh_mmio_bar1_size                ( f1_csh_mmio_bar1_size                     ),
        .f1_csh_mmio_bar2_size                ( f1_csh_mmio_bar2_size                     ),
        .f1_csh_mmio_bar0_prefetchable        ( f1_csh_mmio_bar0_prefetchable             ),
        .f1_csh_mmio_bar1_prefetchable        ( f1_csh_mmio_bar1_prefetchable             ),
        .f1_csh_mmio_bar2_prefetchable        ( f1_csh_mmio_bar2_prefetchable             ),
        .f1_pasid_max_pasid_width             ( f1_pasid_max_pasid_width                  ),
        .f1_ofunc_reset_duration              ( f1_ofunc_reset_duration                   ),
        .f1_ofunc_afu_present                 ( f1_ofunc_afu_present                      ),
        .f1_ofunc_max_afu_index               ( f1_ofunc_max_afu_index                    ),
        .f1_octrl00_reset_duration            ( f1_octrl00_reset_duration                 ),
        .f1_octrl00_afu_control_index         ( f1_octrl00_afu_control_index              ),
        .f1_octrl00_pasid_len_supported       ( f1_octrl00_pasid_len_supported            ),
        .f1_octrl00_metadata_supported        ( f1_octrl00_metadata_supported             ),
        .f1_octrl00_actag_len_supported       ( f1_octrl00_actag_len_supported            )
    );

    `ifdef AD9V3
        `ifdef ENABLE_DDR
            ddr4_dimm_ad9v3 ddr4_dimm_ad9v3 (
                .sys_reset              (~sys_reset_n_q),
                .c0_ddr4_act_n          (c0_ddr4_act_n),
                .c0_ddr4_adr            (c0_ddr4_adr),
                .c0_ddr4_ba             (c0_ddr4_ba),
                .c0_ddr4_bg             (c0_ddr4_bg),
                .c0_ddr4_cke            (c0_ddr4_cke),
                .c0_ddr4_odt            (c0_ddr4_odt),
                .c0_ddr4_cs_n           (c0_ddr4_cs_n),
                .c0_ddr4_ck_t           (c0_ddr4_ck_t),
                .c0_ddr4_ck_c           (c0_ddr4_ck_c),
                .c0_ddr4_reset_n        (c0_ddr4_reset_n),
                .c0_ddr4_dm_dbi_n       (c0_ddr4_dm_dbi_n),
                .c0_ddr4_dq             (c0_ddr4_dq),
                .c0_ddr4_dqs_c          (c0_ddr4_dqs_c),
                .c0_ddr4_dqs_t          (c0_ddr4_dqs_t)
            );
        `endif
    `endif
    `ifdef BW250SOC
        `ifdef ENABLE_DDR
            ddr4_dimm_250soc ddr4_dimm_250soc (
                .sys_reset              (~sys_reset_n_q),
                .c0_ddr4_act_n          (c0_ddr4_act_n),
                .c0_ddr4_adr            (c0_ddr4_adr),
                .c0_ddr4_ba             (c0_ddr4_ba),
                .c0_ddr4_bg             (c0_ddr4_bg),
                .c0_ddr4_cke            (c0_ddr4_cke),
                .c0_ddr4_odt            (c0_ddr4_odt),
                .c0_ddr4_cs_n           (c0_ddr4_cs_n),
                .c0_ddr4_ck_t           (c0_ddr4_ck_t),
                .c0_ddr4_ck_c           (c0_ddr4_ck_c),
                .c0_ddr4_reset_n        (c0_ddr4_reset_n),
                .c0_ddr4_dm_dbi_n       (c0_ddr4_dm_dbi_n),
                .c0_ddr4_dq             (c0_ddr4_dq),
                .c0_ddr4_dqs_c          (c0_ddr4_dqs_c),
                .c0_ddr4_dqs_t          (c0_ddr4_dqs_t)
            );
        `endif
    `endif

    assign vpd_cfg_rdata [31:0] = 32'h00000000;
    assign vpd_cfg_done = 1'b0;

endmodule

