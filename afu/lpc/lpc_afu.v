// *!***************************************************************************
// *! Copyright 2019 International Business Machines
// *!
// *! Licensed under the Apache License, Version 2.0 (the "License");
// *! you may not use this file except in compliance with the License.
// *! You may obtain a copy of the License at
// *! http://www.apache.org/licenses/LICENSE-2.0 
// *!
// *! The patent license granted to you in Section 3 of the License, as applied
// *! to the "Work," hereby includes implementations of the Work in physical form.  
// *!
// *! Unless required by applicable law or agreed to in writing, the reference design
// *! distributed under the License is distributed on an "AS IS" BASIS,
// *! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// *! See the License for the specific language governing permissions and
// *! limitations under the License.
// *! 
// *! The background Specification upon which this is based is managed by and available from
// *! the OpenCAPI Consortium.  More information can be found at https://opencapi.org. 
// *!***************************************************************************
`timescale 1ns / 1ps
// -------------------------------------------------------------------
// Title    : lpc_afu.v
// Function : This file is the top level wrapper for the LPC AFU.
//
// -------------------------------------------------------------------
// Modification History :
//                               |Version    |     |Author   |Description of change
//                               |-----------|     |-------- |---------------------
  `define LPC_AFU_VERSION         24_Aug_2018   //  
// -------------------------------------------------------------------

// Update below as AFU snapshots change. Do not change the format of these lines else scripts to auto-update them will falter.
`define AFU_VERSION_MAJOR 8'h06  
`define AFU_VERSION_MINOR 8'h05


// ==============================================================================================================================
// @@@  Module Declaration
// ==============================================================================================================================
module lpc_afu (

    // -----------------------------------
    // Miscellaneous Ports
    // -----------------------------------
    input          clock                        // Don't mark_debug the clock as it causes ILA timing problems
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          reset                        // (positive active
  , input    [5:0] ro_afu_index                 // Each AFU instance under a common Function needs a unique index number
   
    // -----------------------------------
    // TLX Parser -> AFU Receive Interface
    // -----------------------------------

  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_ready                // When 1, TLX is ready to receive both commands and responses from the AFU

    // Command interface to AFU
  , output [  6:0] afu_tlx_cmd_initial_credit   // (static) Number of cmd credits available for TLX to use in the AFU      
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         afu_tlx_cmd_credit           // Returns a cmd credit to the TLX
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_cmd_valid            // Indicates TLX has a valid cmd for AFU to process
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [  7:0] tlx_afu_cmd_opcode           // (w/cmd_valid) Cmd Opcode
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [  1:0] tlx_afu_cmd_dl               // (w/cmd_valid) Cmd Data Length (00=rsvd, 01=64B, 10=128B, 11=256B) 
  , input          tlx_afu_cmd_end              // (w/cmd_valid) Operand Endian-ess 
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [ 63:0] tlx_afu_cmd_pa               // (w/cmd_valid) Physical Address
  , input  [  3:0] tlx_afu_cmd_flag             // (w/cmd_valid) Specifies atomic memory operation (unsupported) 
  , input          tlx_afu_cmd_os               // (w/cmd_valid) Ordered Segment - 1 means ordering is guaranteed (unsupported) 
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [ 15:0] tlx_afu_cmd_capptag          // (w/cmd_valid) Unique operation tag from CAPP unit     
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [  2:0] tlx_afu_cmd_pl               // (w/cmd_valid) Partial Length (000=1B,001=2B,010=4B,011=8B,100=16B,101=32B,110/111=rsvd)
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [ 63:0] tlx_afu_cmd_be               // (w/cmd_valid) Byte Enable   

    // Response interface to AFU
  , output [  6:0] afu_tlx_resp_initial_credit  // (static) Number of resp credits available for TLX to use in the AFU     
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         afu_tlx_resp_credit          // Returns a resp credit to the TLX     
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_resp_valid           // Indicates TLX has a valid resp for AFU to process  
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [  7:0] tlx_afu_resp_opcode          // (w/resp_valid) Resp Opcode     
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [ 15:0] tlx_afu_resp_afutag          // (w/resp_valid) Resp Tag    
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [  3:0] tlx_afu_resp_code            // (w/resp_valid) Describes the reason for a failed transaction     
  , input  [  5:0] tlx_afu_resp_pg_size         // (w/resp_valid) Page size     
  , input  [  1:0] tlx_afu_resp_dl              // (w/resp_valid) Resp Data Length (00=rsvd, 01=64B, 10=128B, 11=256B)     
  , input  [  1:0] tlx_afu_resp_dp              // (w/resp_valid) Data Part, indicates the data content of the current resp packet     
  , input  [ 23:0] tlx_afu_resp_host_tag        // (w/resp_valid) Tag for data held in AFU L1 (unsupported, CAPI 4.0 feature)     
  , input  [  3:0] tlx_afu_resp_cache_state     // (w/resp_valid) Gives cache state of cache line obtained     
  , input  [ 17:0] tlx_afu_resp_addr_tag        // (w/resp_valid) Address translation tag for use by AFU with dot-t format commands

    // Command data interface to AFU
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         afu_tlx_cmd_rd_req           // Command Read Request     
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [  2:0] afu_tlx_cmd_rd_cnt           // Command Read Count, number of 64B flits requested (000 is not useful)    
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_cmd_data_valid       // Command Data Valid, when 1 valid data is present on cmd_data_bus
  , // `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_cmd_data_bdi         // (w/cmd_data_valid) Bad Data Indicator, when 1 data FLIT is corrupted
  , // `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [511:0] tlx_afu_cmd_data_bus         // (w/cmd_data_valid) Command Data Bus, contains the command for the AFU to process     

    // Response data interface to AFU
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         afu_tlx_resp_rd_req          // Response Read Request     
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [  2:0] afu_tlx_resp_rd_cnt          // Response Read Count, number of 64B flits requested (000 is not useful)      
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_resp_data_valid      // Response Valid, when 1 valid data is present on resp_data     
  , // `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_resp_data_bdi        // (w/resp_data_valid) Bad Data Indicator, when 1 data FLIT is corrupted
  , // `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [511:0] tlx_afu_resp_data_bus        // (w/resp_data_valid) Response Data, contains data for a read request     

    // ------------------------------------
    // AFU -> TLX Framer Transmit Interface
    // ------------------------------------

    // Initial credit allocation
//  , input  [  2:0] tlx_afu_cmd_resp_initial_credit   // Number of starting credits from TLX for both AFU->TLX cmd and resp interfaces
//  , input  [  4:0] tlx_afu_data_initial_credit       // Number of starting credits from TLX for both AFU->TLX cmd and resp data interfaces
  , input  [  3:0] tlx_afu_cmd_initial_credit           // Number of starting credits from TLX for AFU->TLX cmd interface
  , input  [  3:0] tlx_afu_resp_initial_credit          // Number of starting credits from TLX for AFU->TLX resp interface
  , input  [  5:0] tlx_afu_cmd_data_initial_credit      // Number of starting credits from TLX for both AFU->TLX cmd data interface
  , input  [  5:0] tlx_afu_resp_data_initial_credit     // Number of starting credits from TLX for both AFU->TLX resp data interface

    // Commands from AFU
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_cmd_credit                
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         afu_tlx_cmd_valid                 
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [  7:0] afu_tlx_cmd_opcode                
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [ 11:0] afu_tlx_cmd_actag                 
  , output [  3:0] afu_tlx_cmd_stream_id             
  , output [ 67:0] afu_tlx_cmd_ea_or_obj             
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [ 15:0] afu_tlx_cmd_afutag               
  , output [  1:0] afu_tlx_cmd_dl                    
  , output [  2:0] afu_tlx_cmd_pl                    
  , output         afu_tlx_cmd_os                    
  , output [ 63:0] afu_tlx_cmd_be                    
  , output [  3:0] afu_tlx_cmd_flag                  
  , output         afu_tlx_cmd_endian                
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [ 15:0] afu_tlx_cmd_bdf              // BDF = Concatenation of 8 bit Bus Number, 5 bit Device Number, and 3 bit Function                  
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [ 19:0] afu_tlx_cmd_pasid                 
  , output [  5:0] afu_tlx_cmd_pg_size               

    // Command data from AFU
  , input          tlx_afu_cmd_data_credit           
  , output         afu_tlx_cdata_valid               
  , output [511:0] afu_tlx_cdata_bus                 
  , output         afu_tlx_cdata_bdi           // When 1, marks command data associated with AFU->host command as bad        

    // Responses from AFU
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_resp_credit               
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         afu_tlx_resp_valid                
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [  7:0] afu_tlx_resp_opcode               
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [  1:0] afu_tlx_resp_dl   
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [ 15:0] afu_tlx_resp_capptag          
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [  1:0] afu_tlx_resp_dp                   
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [  3:0] afu_tlx_resp_code                 

    // Response data from AFU
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input          tlx_afu_resp_data_credit          
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         afu_tlx_rdata_valid               
  , // `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [511:0] afu_tlx_rdata_bus                 
  , // `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output         afu_tlx_rdata_bdi           // When 1, marks response data associated with AFU's reply to Host->AFU cmd as bad                

    // ------------------------------------
    // AFU <-> BDF Interface
    // ------------------------------------

  , input    [7:0] cfg_afu_bdf_bus               // Current BDF value held in CFG_SEQ
  , input    [4:0] cfg_afu_bdf_device 
  , input    [2:0] cfg_afu_bdf_function

    // ---------------------------------------
    // Configuration Space Outputs used by AFU
    // ---------------------------------------
 
    // MMIO
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input         cfg_csh_memory_space
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [63:0] cfg_csh_mmio_bar0 

    // 'assign_actag' generation controls
//, input   [4:0] cfg_ofunc_func_actag_base           // This is the base acTag      across all AFUs in the Function (2**n value) (not used in LPC)
//, input   [4:0] cfg_ofunc_func_actag_len_enab       // This is the range of acTags across all AFus in the Function (2**n value) (not used in LPC)
  , input  [11:0] cfg_octrl00_afu_actag_base          // This is the base acTag      this AFU can use (linear value)
  , input  [11:0] cfg_octrl00_afu_actag_len_enab      // This is the range of acTags this AFU can use (linear value)

    // Process termination controls
  , output        cfg_terminate_in_progress           // Unused by LPC since it doesn't make sense to terminate the general interrupt process
  , input         cfg_octrl00_terminate_valid         // Unused by LPC since it doesn't make sense to terminate the general interrupt process
  , input  [19:0] cfg_octrl00_terminate_pasid         // Unused by LPC since it doesn't make sense to terminate the general interrupt process 

    // PASID controls
  , input   [4:0] cfg_octrl00_pasid_length_enabled    // Should be >=0 for LPC to allow it to have at least 1 PASID for interrupts 
  , input  [19:0] cfg_octrl00_pasid_base              // Starting value of PASIDs, must be within 'Max PASID Width'
                                                      // Notes: 
                                                      // - 'PASID base' is for this AFU, used to keep PASID range within each AFU unique.
                                                      // - 'PASID Length Enabled' + 'PASID base' must be within range of 'Max PASID Width'
                                                      // More Notes:
                                                      // - 'Max PASID Width' and 'PASID Length Supported' are Read Only inputs to cfg_func.
                                                      // - 'Max PASID Width' is range of PASIDs across all AFUs controlled by this BDF.
                                                      // - 'PASID Length Supported' can be <, =, or > 'Max PASID Width' 
                                                      //   The case of 'PASID Length Supported' > 'Max PASID Width' may seem odd. However it 
                                                      //   is legal since an AFU may support more PASIDs than it advertizes, for instance
                                                      //   in the case where a more general purpose AFU is reused in an application that
                                                      //   has a restricted use.

    // Interrupt generation controls
  , input   [3:0] cfg_f0_otl0_long_backoff_timer      // TLX Configuration for the TLX port(s) connected to AFUs under this Function
  , input   [3:0] cfg_f0_otl0_short_backoff_timer
  , input         cfg_octrl00_enable_afu              // When 1, the AFU can initiate commands to the host
 
     // Metadata  (has no meaning in the LPC for OpenCAPI TL 3.0)
// , input        cfg_octrl00_metadata_enabled           
// , input  [6:0] cfg_octr00l_default_metadata         

    // AFU Descriptor Table interface to AFU Configuration Space
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input   [5:0] cfg_desc_afu_index
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input  [30:0] cfg_desc_offset
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    input         cfg_desc_cmd_valid
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output [31:0] desc_cfg_data
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output        desc_cfg_data_valid
  , `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
    output        desc_cfg_echo_cmd_valid

    // Errors to record from Configuration Sub-system, Descriptor Table, and VPD
  , input         vpd_err_unimplemented_addr
  , input         cfg0_cff_fifo_overflow
  , input         cfg1_cff_fifo_overflow
  , input         cfg0_rff_fifo_overflow
  , input         cfg1_rff_fifo_overflow
  , input [127:0] cfg_errvec
  , input         cfg_errvec_valid
 
    // Resync credits control
  , input         cfg_f1_octrl00_resync_credits

) ;


// ==============================================================================================================================
// @@@  PARM: Parameters
// ==============================================================================================================================
// There are none on this design.


// ==============================================================================================================================
// @@@  SIG: Internal signals 
// ==============================================================================================================================

// Signals for managing BDF
wire [15:0] afu_tlx_cmd_bdf_int;


// Signals from MMIO Register space
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire  [19:0] mmio_addr;                 // Target address for the read or write access
// `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg   [63:0] mmio_wdata;                // Write data into selected config reg
// `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire  [63:0] mmio_rdata;                // Read  data from selected config reg
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         mmio_rdata_vld;            // When observed in the proper cycle, indicates if rdata has valid information
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          mmio_wr_1B;                // When 1, triggers a write operation of 1 byte      (addr[2:0] selects byte)
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          mmio_wr_2B;                // When 1, triggers a write operation of 2 bytes     (addr[2:1] selects starting byte)
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          mmio_wr_4B;                // When 1, triggers a write operation of all 4 bytes (addr[2]   selects starting byte)
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          mmio_wr_8B;                // When 1, triggers a write operation of all 4 bytes
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          mmio_rd;                   // When 1, triggers a read operation that returns all 4 bytes of data from the reg
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         mmio_bad_op_or_align;      // Pulsed when multiple write/read strobes are active or writes are not naturally aligned
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         mmio_addr_not_implemented; // Pulsed when address provided is not implemented as an MMIO register
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire  [63:0] mmio_in_captured_errors;   // When pulsed to 1, the associated MMIO reg bit is captured and held to 1. Write to 0 to clear. 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire  [63:0] mmio_in_status;            // Provide a READ ONLY way for signals like status to be assigned an MMIO address
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         mmio_in_intrp_is_pending;  // When 1, set interrupt pending bit in MSI-X PBA register
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         mmio_out_sam_disable;      // When 1, SAM does no mapping and just passes addresses through unchanged
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         mmio_out_ignore_nomatch_on_read;  // When 1, reading from uninitialized memory is not a read error
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         mmio_out_enable_pipeline;  // When 1, enables bulk memory operations to be pipelined. When 0, they are processed one at a time.
wire  [63:0] mmio_out_intrp_ea;         // Effective Address to use in intrp_req
wire         mmio_out_intrp_vec_mask;   // Enable/disable indicator of intrp_ea
wire  [19:0] mmio_out_intrp_pasid;      // PASID value to use in assign_actag preceding intrp_req
wire   [3:0] mmio_out_intrp_cmd_flag;   // CMD_FLAG  value to use in intrp_req
wire   [3:0] mmio_out_intrp_stream_id;  // STREAM_ID value to use in intrp_req
wire  [15:0] mmio_out_intrp_afutag;     // AFUTAG    value to use in intrp_req
                                       
// Signals used by Sparse Array Map (SAM)
wire [11:0] sam_addr_out;
wire  [4:0] sam_entries_open;  
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        sam_overflow;  
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        sam_no_match;

// Signals used from Bulk Memory
wire         mem_dout_bdi;
wire [511:0] mem_dout;
wire         mem_err_multiops;
wire         mem_err_boundary;
wire         mem_err_internal;

// Signals used by Error Array
reg   [15:0] ery_loadsrc;
wire [127:0] ery_src15; 
wire [127:0] ery_src14;  
//wire [127:0] ery_src13;  // NOTE: To conserve resources, comment out sources which are not used right now.
//wire [127:0] ery_src12;
//wire [127:0] ery_src11;
//wire [127:0] ery_src10;
wire [127:0] ery_src09;
reg  [127:0] ery_src08;
reg  [127:0] ery_src07;
reg  [127:0] ery_src06;
reg  [127:0] ery_src05;
reg  [127:0] ery_src04;
reg  [127:0] ery_src03;
reg  [127:0] ery_src02;
reg  [127:0] ery_src01;
reg  [127:0] ery_src00;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [127:0] ery_data_out;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         ery_data_valid;
wire         ery_data_done;
wire         ery_simultaneous_load;
wire         ery_overflow;
wire         ery_trigger_intrp;

// Capture error information on config_write and config_read for reporting through interrupts and MMIO registers
always @(posedge(clock))
  begin
    ery_loadsrc[0]     <= cfg_errvec_valid;
    ery_src00[127:112] <= 16'h0001;                // Mark source as coming from config_write
    ery_src00[111:0]   <= cfg_errvec[111:0];       // Rest of fields are already formatted

    ery_loadsrc[1]     <= 1'b0;                    // UNUSED AT THIS TIME
    ery_src01[127:112] <= 16'h0002;                // Mark source as coming from config_read
    ery_src01[111:0]   <= 112'b0;                  // Rest of fields are already formatted
  end

always @(posedge(clock))
  ery_loadsrc[13:9] <= 5'b0;
//assign ery_src13   = 128'h00000013_00000000_00000000_00000000;
//assign ery_src12   = 128'h00000012_00000000_00000000_00000000;
//assign ery_src11   = 128'h00000011_00000000_00000000_00000000;
//assign ery_src10   = 128'h00000010_00000000_00000000_00000000;
assign ery_src09   = 128'h00000009_00000000_00000000_00000000;   // Reserve one active location for future function


// Signals used by interrupt request logic 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg [2:0] intrp_count;            // Counts 0-7 to match size of ERRARY. If that increases, this needs to also.
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire      irq_ok_to_send_intrp;   // Combine all the conditions necessary to enable sending an intrp_req


// Signals used by AFU->Host commands, Host->AFU responses
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire received_bad_op;               
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire err1_lock_afu_to_host_intf;   
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire err2_lock_afu_to_host_intf;


// Signals used by AFU Descriptor Table
wire desc_err_unimplemented_addr;



// ==============================================================================================================================
// @@@ ACS: AFU Configuration Signals (register configuration outputs before use)
// ==============================================================================================================================
// These signals can be registered since they should be relatively static during functional use. This may help with timing closure.
// Signals from the 'AFU Information DVSEC' (OINFO) and 'AFU Control DVSEC' (OCTRL) however must be captured and held, since 
// the same configuration space can target different AFUs. Each one has an 'AFU Index' field that identifies which AFU the 
// bits refer to at the current time.   


  reg          acs_memory_space
; reg   [63:0] acs_mmio_bar0 
//reg    [4:0] acs_base_actag_config
//reg    [4:0] acs_max_actag_config  
; reg   [11:0] acs_actag_len_enabled         
; reg   [11:0] acs_actag_base                
//reg          acs_terminate_valid         // Currently not used 
//reg   [19:0] acs_terminate_pasid         // Currently not used
; reg    [4:0] acs_pasid_length_enabled         
; reg   [19:0] acs_pasid_base                   
; reg          acs_enable_afu                  
; reg   [35:0] acs_long_backoff_timer      // Convert 2^n value to clock cycle count at 400 MHz (or close to it)    
//reg   [23:0] acs_short_backoff_timer     // Convert 2^n value to clock cycle count at 400 MHz (or close to it) (Currently not used)
;

always @(posedge(clock))
  begin
    acs_memory_space             <= cfg_csh_memory_space             ;
    acs_mmio_bar0                <= cfg_csh_mmio_bar0                ;
//  acs_base_actag_config        <= cfg_ofunc_base_actag_config      ;
//  acs_max_actag_config         <= cfg_ofunc_max_actag_config       ;
    acs_actag_len_enabled        <= cfg_octrl00_afu_actag_len_enab   ;
    acs_actag_base               <= cfg_octrl00_afu_actag_base       ;
//  acs_terminate_valid          <= cfg_octrl00_terminate_valid      ;    
//  acs_terminate_pasid          <= cfg_octrl00_terminate_pasid      ;     
    acs_pasid_length_enabled     <= cfg_octrl00_pasid_length_enabled ; 
    acs_pasid_base               <= cfg_octrl00_pasid_base           ; 
    acs_enable_afu               <= cfg_octrl00_enable_afu           ;
    case (cfg_f0_otl0_long_backoff_timer)                   // At 400 MHz, 40 clock cycles (x28) = 100 ns
      4'b0000: acs_long_backoff_timer  <= 36'h0_0000_0028;  //  2^(2*0)  =          1 * 100 ns  
      4'b0001: acs_long_backoff_timer  <= 36'h0_0000_00A0;  //  2^(2*1)  =          4 * 100 ns
      4'b0010: acs_long_backoff_timer  <= 36'h0_0000_0280;  //  2^(2*2)  =         16 * 100 ns   
      4'b0011: acs_long_backoff_timer  <= 36'h0_0000_0A00;  //  2^(2*3)  =         64 * 100 ns     
      4'b0100: acs_long_backoff_timer  <= 36'h0_0000_2800;  //  2^(2*4)  =        256 * 100 ns     
      4'b0101: acs_long_backoff_timer  <= 36'h0_0000_A000;  //  2^(2*5)  =       1024 * 100 ns     
      4'b0110: acs_long_backoff_timer  <= 36'h0_0002_8000;  //  2^(2*6)  =       4096 * 100 ns     
      4'b0111: acs_long_backoff_timer  <= 36'h0_000A_0000;  //  2^(2*7)  =      16384 * 100 ns     
      4'b1000: acs_long_backoff_timer  <= 36'h0_0028_0000;  //  2^(2*8)  =      65536 * 100 ns    
      4'b1001: acs_long_backoff_timer  <= 36'h0_00A0_0000;  //  2^(2*9)  =     262144 * 100 ns      
      4'b1010: acs_long_backoff_timer  <= 36'h0_0280_0000;  //  2^(2*10) =    1048576 * 100 ns     
      4'b1011: acs_long_backoff_timer  <= 36'h0_0A00_0000;  //  2^(2*11) =    4184304 * 100 ns    
      4'b1100: acs_long_backoff_timer  <= 36'h0_2800_0000;  //  2^(2*12) =   16777216 * 100 ns    
      4'b1101: acs_long_backoff_timer  <= 36'h0_A000_0000;  //  2^(2*13) =   67108864 * 100 ns    
      4'b1110: acs_long_backoff_timer  <= 36'h2_8000_0000;  //  2^(2*14) =  268435456 * 100 ns    
      4'b1111: acs_long_backoff_timer  <= 36'hA_0000_0000;  //  2^(2*15) = 1073741824 * 100 ns    
   endcase 
// case (cfg_f0_otl0_short_backoff_timer)               // At 400 MHz, 40 clock cycles (x28) = 100 ns
//    4'b0000: acs_short_backoff_timer <= 24'h00_0028;  //  2^0  =     1 * 100 ns  
//    4'b0001: acs_short_backoff_timer <= 24'h00_0050;  //  2^1  =     2 * 100 ns
//    4'b0010: acs_short_backoff_timer <= 24'h00_00A0;  //  2^2  =     4 * 100 ns   
//    4'b0011: acs_short_backoff_timer <= 24'h00_0140;  //  2^3  =     8 * 100 ns     
//    4'b0100: acs_short_backoff_timer <= 24'h00_0280;  //  2^4  =    16 * 100 ns     
//    4'b0101: acs_short_backoff_timer <= 24'h00_0500;  //  2^5  =    32 * 100 ns     
//    4'b0110: acs_short_backoff_timer <= 24'h00_0A00;  //  2^6  =    64 * 100 ns     
//    4'b0111: acs_short_backoff_timer <= 24'h00_1400;  //  2^7  =   128 * 100 ns     
//    4'b1000: acs_short_backoff_timer <= 24'h00_2800;  //  2^8  =   256 * 100 ns    
//    4'b1001: acs_short_backoff_timer <= 24'h00_5000;  //  2^9  =   512 * 100 ns      
//    4'b1010: acs_short_backoff_timer <= 24'h00_A000;  //  2^10 =  1024 * 100 ns     
//    4'b1011: acs_short_backoff_timer <= 24'h01_4000;  //  2^11 =  2048 * 100 ns    
//    4'b1100: acs_short_backoff_timer <= 24'h02_8000;  //  2^12 =  4096 * 100 ns    
//    4'b1101: acs_short_backoff_timer <= 24'h05_0000;  //  2^13 =  8192 * 100 ns    
//    4'b1110: acs_short_backoff_timer <= 24'h0A_0000;  //  2^14 = 16384 * 100 ns    
//    4'b1111: acs_short_backoff_timer <= 24'h14_0000;  //  2^15 = 32768 * 100 ns    
//  endcase
  end


// ==============================================================================================================================
// @@@ COM: Common / Miscellanous Logic
// ==============================================================================================================================


// To prevent synthesis warnings about inputs that are unused because the function they are associated with is unsupported,
// create a dummy logic structure that has no real use. Make a 1 bit latch that OR's together all the unused inputs.
// Also OR in itself so nothing is dangling, even the latch output. 
// Use the Verilog OR-reduction operator on vectors (| vector_name[x:0]) to shorten the code.
reg unused_inputs_q;
always @(posedge(clock))    
  unused_inputs_q <= unused_inputs_q | tlx_afu_cmd_os ;


// ==============================================================================================================================
// @@@ OR: OR logic driving signals to TLX
// ==============================================================================================================================
// Implement OR gates to combine control signals driven by AFU to TLX from various command state machines.
// The idea here is since there is 1 physical interface back to the TLX and multiple command state machines need to
// share it, enforce the rule that each state machine must set its copy of the signal to all 0 when not in use.
// That way a simple OR just before driving the output will allow the state machine that is engaged to control 
// the output to the TLX.

// -------------------------------------------
// Host to AFU commands, AFU to Host responses
// -------------------------------------------


reg         afu_tlx_cmd_rd_req_mmw;  
reg         afu_tlx_cmd_rd_req_fwm;
reg         afu_tlx_cmd_rd_req_pip;
assign afu_tlx_cmd_rd_req = afu_tlx_cmd_rd_req_mmw |    // MMIO write
                            afu_tlx_cmd_rd_req_fwm |    // write_mem
                            afu_tlx_cmd_rd_req_pip ;    // Pipeline
                      
reg  [2:0] afu_tlx_cmd_rd_cnt_mmw;
reg  [2:0] afu_tlx_cmd_rd_cnt_fwm;
reg  [2:0] afu_tlx_cmd_rd_cnt_pip;
assign afu_tlx_cmd_rd_cnt = afu_tlx_cmd_rd_cnt_mmw |    // MMIO write
                            afu_tlx_cmd_rd_cnt_fwm |    // write_mem
                            afu_tlx_cmd_rd_cnt_pip ;    // Pipeline

// afu_tlx_cmd_credit    <-- driven by CMD FIFO

reg         afu_tlx_resp_valid_mmw;
reg         afu_tlx_resp_valid_mmr;
reg         afu_tlx_resp_valid_fwm;
reg         afu_tlx_resp_valid_frm;
reg         afu_tlx_resp_valid_pip;
assign afu_tlx_resp_valid = afu_tlx_resp_valid_mmw |    // MMIO write
                            afu_tlx_resp_valid_mmr |    // MMIO read
                            afu_tlx_resp_valid_fwm |    // write_mem
                            afu_tlx_resp_valid_frm |    // rd_mem
                            afu_tlx_resp_valid_pip ;    // Pipeline


reg   [7:0] afu_tlx_resp_opcode_mmw;
reg   [7:0] afu_tlx_resp_opcode_mmr;
reg   [7:0] afu_tlx_resp_opcode_fwm;
reg   [7:0] afu_tlx_resp_opcode_frm;
reg   [7:0] afu_tlx_resp_opcode_pip;
assign afu_tlx_resp_opcode = afu_tlx_resp_opcode_mmw |    // MMIO write
                             afu_tlx_resp_opcode_mmr |    // MMIO read
                             afu_tlx_resp_opcode_fwm |    // write_mem  
                             afu_tlx_resp_opcode_frm |    // rd_mem          
                             afu_tlx_resp_opcode_pip ;    // Pipeline

reg   [1:0] afu_tlx_resp_dl_mmw;
reg   [1:0] afu_tlx_resp_dl_mmr;
reg   [1:0] afu_tlx_resp_dl_fwm;
reg   [1:0] afu_tlx_resp_dl_frm;
reg   [1:0] afu_tlx_resp_dl_pip;
assign afu_tlx_resp_dl = afu_tlx_resp_dl_mmw |    // MMIO write
                         afu_tlx_resp_dl_mmr |    // MMIO read
                         afu_tlx_resp_dl_fwm |    // write_mem
                         afu_tlx_resp_dl_frm |    // rd_mem
                         afu_tlx_resp_dl_pip ;    // Pipeline

reg  [15:0] afu_tlx_resp_capptag_mmw;
reg  [15:0] afu_tlx_resp_capptag_mmr;
reg  [15:0] afu_tlx_resp_capptag_fwm;
reg  [15:0] afu_tlx_resp_capptag_frm;
reg  [15:0] afu_tlx_resp_capptag_pip;
assign afu_tlx_resp_capptag = afu_tlx_resp_capptag_mmw |    // MMIO write
                              afu_tlx_resp_capptag_mmr |    // MMIO read
                              afu_tlx_resp_capptag_fwm |    // write_mem  
                              afu_tlx_resp_capptag_frm |    // rd_mem     
                              afu_tlx_resp_capptag_pip ;    // Pipeline    

reg   [1:0] afu_tlx_resp_dp_mmw;
reg   [1:0] afu_tlx_resp_dp_mmr;
reg   [1:0] afu_tlx_resp_dp_fwm;
reg   [1:0] afu_tlx_resp_dp_frm;
reg   [1:0] afu_tlx_resp_dp_pip;
assign afu_tlx_resp_dp = afu_tlx_resp_dp_mmw |    // MMIO write
                         afu_tlx_resp_dp_mmr |    // MMIO read
                         afu_tlx_resp_dp_fwm |    // write_mem
                         afu_tlx_resp_dp_frm |    // rd_mem
                         afu_tlx_resp_dp_pip ;    // Pipeline

reg   [3:0] afu_tlx_resp_code_mmw;
reg   [3:0] afu_tlx_resp_code_mmr;
reg   [3:0] afu_tlx_resp_code_fwm;
reg   [3:0] afu_tlx_resp_code_frm;
reg   [3:0] afu_tlx_resp_code_pip;
assign afu_tlx_resp_code = afu_tlx_resp_code_mmw |     // MMIO write
                           afu_tlx_resp_code_mmr |     // MMIO read
                           afu_tlx_resp_code_fwm |     // write_mem  
                           afu_tlx_resp_code_frm |     // rd_mem
                           afu_tlx_resp_code_pip ;     // Pipeline

reg          afu_tlx_rdata_valid_mmr;
reg          afu_tlx_rdata_valid_frm;
reg          afu_tlx_rdata_valid_pip;
assign afu_tlx_rdata_valid = afu_tlx_rdata_valid_mmr |     // MMIO read
                             afu_tlx_rdata_valid_frm |     // rd_mem
                             afu_tlx_rdata_valid_pip ;     // Pipeline

reg  [511:0] afu_tlx_rdata_bus_mmr;
reg  [511:0] afu_tlx_rdata_bus_frm;
reg  [511:0] afu_tlx_rdata_bus_pip;
assign afu_tlx_rdata_bus = afu_tlx_rdata_bus_mmr |      // MMIO read  
                           afu_tlx_rdata_bus_frm |      // rd_mem     
                           afu_tlx_rdata_bus_pip ;      // Pipeline

reg          afu_tlx_rdata_bdi_mmr;
reg          afu_tlx_rdata_bdi_frm;
reg          afu_tlx_rdata_bdi_pip;
assign afu_tlx_rdata_bdi = afu_tlx_rdata_bdi_mmr |      // MMIO read   
                           afu_tlx_rdata_bdi_frm |      // rd_mem         
                           afu_tlx_rdata_bdi_pip ;      // Pipeline


// Some inputs into MMIO space have multiple sources also
reg  [19:0] mmio_addr_mmw;
reg  [19:0] mmio_addr_mmr;
assign mmio_addr = mmio_addr_mmw |   // MMIO write
                   mmio_addr_mmr ;   // MMIO read


// -------------------------------------------
// AFU to Host commands, Host to AFU responses
// -------------------------------------------

reg          afu_tlx_resp_credit_irq1;
reg          afu_tlx_resp_credit_irq2;
wire         afu_tlx_resp_credit_tm1;
assign afu_tlx_resp_credit = afu_tlx_resp_credit_irq1 |   // Interrupt Request - intrp_resp sequencer
                             afu_tlx_resp_credit_irq2 |   // Interrupt Request - intrp_rdy  sequencer
                             afu_tlx_resp_credit_tm1  ;   // Test Mode 1

wire         afu_tlx_resp_rd_req_tm1;
assign afu_tlx_resp_rd_req = afu_tlx_resp_rd_req_tm1 ;   // Test Mode 1

wire   [2:0] afu_tlx_resp_rd_cnt_tm1;
assign afu_tlx_resp_rd_cnt = afu_tlx_resp_rd_cnt_tm1 ;   // Test Mode 1
  
reg          afu_tlx_cmd_valid_irq1;
reg          afu_tlx_cmd_valid_irq2;
wire         afu_tlx_cmd_valid_tm1; 
assign afu_tlx_cmd_valid = afu_tlx_cmd_valid_irq1 |   // Interrupt Request - assign_actag command
                           afu_tlx_cmd_valid_irq2 |   // Interrupt Request - intrp_req command
                           afu_tlx_cmd_valid_tm1  ;   // Test Mode 1

reg    [7:0] afu_tlx_cmd_opcode_irq1;
reg     [7:0] afu_tlx_cmd_opcode_irq2;
wire   [7:0] afu_tlx_cmd_opcode_tm1;
assign afu_tlx_cmd_opcode = afu_tlx_cmd_opcode_irq1 |   // Interrupt Request - assign_actag command
                            afu_tlx_cmd_opcode_irq2 |   // Interrupt Request - intrp_req command
                            afu_tlx_cmd_opcode_tm1  ;   // Test Mode 1

reg   [11:0] afu_tlx_cmd_actag_irq1;
reg   [11:0] afu_tlx_cmd_actag_irq2;
wire  [11:0] afu_tlx_cmd_actag_tm1;
assign afu_tlx_cmd_actag = afu_tlx_cmd_actag_irq1 |   // Interrupt Request - assign_actag command
                           afu_tlx_cmd_actag_irq2 |   // Interrupt Request - intrp_req command
                           afu_tlx_cmd_actag_tm1  ;   // Test Mode 1

reg    [3:0] afu_tlx_cmd_stream_id_irq;
wire   [3:0] afu_tlx_cmd_stream_id_tm1;
assign afu_tlx_cmd_stream_id = afu_tlx_cmd_stream_id_irq |   // Interrupt Request
                               afu_tlx_cmd_stream_id_tm1 ;   // Test Mode 1

reg   [67:0] afu_tlx_cmd_ea_or_obj_irq;
wire  [67:0] afu_tlx_cmd_ea_or_obj_tm1;
assign afu_tlx_cmd_ea_or_obj = afu_tlx_cmd_ea_or_obj_irq |   // Interrupt Request
                               afu_tlx_cmd_ea_or_obj_tm1 ;   // Test Mode 1                  

reg   [15:0] afu_tlx_cmd_afutag_irq;
wire  [15:0] afu_tlx_cmd_afutag_tm1;
assign afu_tlx_cmd_afutag = afu_tlx_cmd_afutag_irq |   // Interrupt Request
                            afu_tlx_cmd_afutag_tm1 ;   // Test Mode 1

wire   [1:0] afu_tlx_cmd_dl_tm1;
assign afu_tlx_cmd_dl = afu_tlx_cmd_dl_tm1 ;   // Test Mode 1

wire   [2:0] afu_tlx_cmd_pl_tm1;
assign afu_tlx_cmd_pl = afu_tlx_cmd_pl_tm1 ;   // Test Mode 1

wire         afu_tlx_cmd_os_tm1;
assign afu_tlx_cmd_os = afu_tlx_cmd_os_tm1 ;   // Test Mode 1

wire  [63:0] afu_tlx_cmd_be_tm1;
assign afu_tlx_cmd_be = afu_tlx_cmd_be_tm1 ;   // Test Mode 1

reg    [3:0] afu_tlx_cmd_flag_irq;
wire   [3:0] afu_tlx_cmd_flag_tm1;
assign afu_tlx_cmd_flag = afu_tlx_cmd_flag_irq |   // Interrupt Request
                          afu_tlx_cmd_flag_tm1 ;   // Test Mode 1

wire         afu_tlx_cmd_endian_tm1;
assign afu_tlx_cmd_endian = afu_tlx_cmd_endian_tm1 ;   // Test Mode 1

// afu_tlx_cmd_bdf is set directly by config space values, not controllable by Interrupt Request nor Test Mode 1
assign afu_tlx_cmd_bdf = afu_tlx_cmd_bdf_int;                                          

reg   [19:0] afu_tlx_cmd_pasid_irq;
wire  [19:0] afu_tlx_cmd_pasid_tm1;
assign afu_tlx_cmd_pasid = afu_tlx_cmd_pasid_irq |   // Interrupt Request
                           afu_tlx_cmd_pasid_tm1 ;   // Test Mode 1

wire   [5:0] afu_tlx_cmd_pg_size_tm1;
assign afu_tlx_cmd_pg_size = afu_tlx_cmd_pg_size_tm1 ;   // Test Mode 1

wire         afu_tlx_cdata_valid_tm1;
assign afu_tlx_cdata_valid = afu_tlx_cdata_valid_tm1 ;   // Test Mode 1

wire [511:0] afu_tlx_cdata_bus_tm1;
assign afu_tlx_cdata_bus = afu_tlx_cdata_bus_tm1 ;   // Test Mode 1

wire         afu_tlx_cdata_bdi_tm1;
assign afu_tlx_cdata_bdi = afu_tlx_cdata_bdi_tm1 ;   // Test Mode 1


// =====================================================================================
// Credit Management: Commands from Host to AFU and responses from AFU to Host
// =====================================================================================

// -------------------------------------------------------------------------------------
// @@@ ATCC: AFU to TLX Command Credit Manager, for commands from TLX to AFU
// -------------------------------------------------------------------------------------
// No credit manager is needed when the AFU operates on 1 command at a time.

assign afu_tlx_cmd_initial_credit = 7'b000_0000;    // Enable no commands to be presented to the AFU. CMDFIFO will manage initial credits.

// afu_tlx_cmd_credit -- AFU state machines pulse this signal when the current command is complete.

// -------------------------------------------------------------------------------------
// @@@ ATCDC: AFU to TLX Command Data Credit Manager, for command data from TLX to AFU
// -------------------------------------------------------------------------------------
// Signals do not exist, since AFU pulls FLITs from TLX using a Request+Count/Data Valid mechanism

// -------------------------------------------------------------------------------------
// @@@ TARC: TLX to AFU Response Credit manager, for responses from AFU to TLX
// -------------------------------------------------------------------------------------
reg  [3:0] tarc_consume_credit_mmw;
reg  [3:0] tarc_consume_credit_mmr;
reg  [3:0] tarc_consume_credit_fwm;
reg  [3:0] tarc_consume_credit_frm;
reg  [3:0] tarc_consume_credit_opd;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [3:0] tarc_credits_available;
wire       tarc_credit_overflow;
wire       tarc_credit_underflow;

lpc_tlx_afu_credit_mgr #(.MSB(3)) TARC (
    .clock                ( clock                           )
  , .reset                ( reset                           )
  , .resync_credits       ( cfg_f1_octrl00_resync_credits   )
  , .tlx_initial_credit   ( tlx_afu_resp_initial_credit     )  // Number of starting credits from TLX for AFU->TLX resp
  , .tlx_credit           ( tlx_afu_resp_credit             )  // But credit return is an individual signal for each operation type
  , .afu_consume_credit_0 ( 4'b0                            )
  , .afu_consume_credit_1 ( 4'b0                            )
  , .afu_consume_credit_2 ( tarc_consume_credit_mmw         )
  , .afu_consume_credit_3 ( tarc_consume_credit_mmr         )
  , .afu_consume_credit_4 ( tarc_consume_credit_fwm         )
  , .afu_consume_credit_5 ( tarc_consume_credit_frm         )
  , .afu_consume_credit_6 ( tarc_consume_credit_opd         )
  , .afu_consume_credit_7 ( 4'b0                            )
  , .afu_reclaim_credit_0 ( 4'b0                            )
  , .credits_available    ( tarc_credits_available          )
  , .credit_overflow      ( tarc_credit_overflow            )
  , .credit_underflow     ( tarc_credit_underflow           )
) ;

// -------------------------------------------------------------------------------------
// @@@ TARDC: TLX to AFU Response Data Credit manager, for response data from AFU to TLX
// -------------------------------------------------------------------------------------
reg  [5:0] tardc_consume_credit_mmr;
reg  [5:0] tardc_consume_credit_frm;
reg  [5:0] tardc_consume_credit_opd;
reg  [5:0] tardc_reclaim_credit_opd;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [5:0] tardc_credits_available;
wire       tardc_credit_overflow;
wire       tardc_credit_underflow;

lpc_tlx_afu_credit_mgr #(.MSB(5)) TARDC (
    .clock                ( clock                            )
  , .reset                ( reset                            )
  , .resync_credits       ( cfg_f1_octrl00_resync_credits    )
  , .tlx_initial_credit   ( tlx_afu_resp_data_initial_credit ) // Number of starting credits from TLX for AFU->TLX resp data
  , .tlx_credit           ( tlx_afu_resp_data_credit         ) // But credit return is an individual signal for each operation type
  , .afu_consume_credit_0 ( 6'b0                             )
  , .afu_consume_credit_1 ( tardc_consume_credit_mmr         )
  , .afu_consume_credit_2 ( tardc_consume_credit_frm         )
  , .afu_consume_credit_3 ( tardc_consume_credit_opd         )
  , .afu_consume_credit_4 ( 6'b0                             )
  , .afu_consume_credit_5 ( 6'b0                             )
  , .afu_consume_credit_6 ( 6'b0                             )
  , .afu_consume_credit_7 ( 6'b0                             )
  , .afu_reclaim_credit_0 ( tardc_reclaim_credit_opd         )
  , .credits_available    ( tardc_credits_available          )
  , .credit_overflow      ( tardc_credit_overflow            )
  , .credit_underflow     ( tardc_credit_underflow           )
) ;


// =====================================================================================
// Credit Management: Commands from AFU to Host and responses from Host to AFU
// =====================================================================================

// -------------------------------------------------------------------------------------
// @@@ TACC: TLX to AFU Command Credit manager, for commands from AFU to TLX
// -------------------------------------------------------------------------------------
reg  [3:0] tacc_consume_credit_irq1;   // Interrupt Request
reg  [3:0] tacc_consume_credit_irq2;   // Interrupt Request
//wire [3:0] tacc_consume_credit_tm1;   // Test mode 1
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [3:0] tacc_credits_available;
wire       tacc_credit_overflow;
wire       tacc_credit_underflow;

lpc_tlx_afu_credit_mgr #(.MSB(3)) TACC (
    .clock                ( clock                           )
  , .reset                ( reset                           )
  , .resync_credits       ( cfg_f1_octrl00_resync_credits   )
  , .tlx_initial_credit   ( tlx_afu_cmd_initial_credit      ) // Number of starting credits from TLX for AFU->TLX cmd
  , .tlx_credit           ( tlx_afu_cmd_credit              ) // TLX pulses to tell the AFU it can send another command
  , .afu_consume_credit_0 ( tacc_consume_credit_irq1        )
  , .afu_consume_credit_1 ( tacc_consume_credit_irq2        )
  , .afu_consume_credit_2 ( 4'b0                            )
  , .afu_consume_credit_3 ( 4'b0                            )
  , .afu_consume_credit_4 ( 4'b0                            )
  , .afu_consume_credit_5 ( 4'b0                            )
  , .afu_consume_credit_6 ( 4'b0                            )
  , .afu_consume_credit_7 ( 4'b0                            )
  , .afu_reclaim_credit_0 ( 4'b0                            )
  , .credits_available    ( tacc_credits_available          )
  , .credit_overflow      ( tacc_credit_overflow            )
  , .credit_underflow     ( tacc_credit_underflow           )
) ;

// -------------------------------------------------------------------------------------
// @@@ TACDC: TLX to AFU Command Data Credit manager, for command data from AFU to TLX
// -------------------------------------------------------------------------------------
//wire [5:0] tacdc_consume_credit_irq;   // Interrupt Request
//wire [5:0] tacdc_consume_credit_tm1;   // Test mode 1
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [5:0] tacdc_credits_available;
wire       tacdc_credit_overflow;
wire       tacdc_credit_underflow;

lpc_tlx_afu_credit_mgr #(.MSB(5)) TACDC (
    .clock                ( clock                           )
  , .reset                ( reset                           )
  , .resync_credits       ( cfg_f1_octrl00_resync_credits   )
  , .tlx_initial_credit   ( tlx_afu_cmd_data_initial_credit ) // Number of starting credits from TLX for both AFU->TLX cmd data
  , .tlx_credit           ( tlx_afu_cmd_data_credit         ) // But credit return is an individual signal for each operation type
  , .afu_consume_credit_0 ( 6'b0                            )
  , .afu_consume_credit_1 ( 6'b0                            )
  , .afu_consume_credit_2 ( 6'b0                            )
  , .afu_consume_credit_3 ( 6'b0                            )
  , .afu_consume_credit_4 ( 6'b0                            )
  , .afu_consume_credit_5 ( 6'b0                            )
  , .afu_consume_credit_6 ( 6'b0                            )
  , .afu_consume_credit_7 ( 6'b0                            )
  , .afu_reclaim_credit_0 ( 6'b0                            )
  , .credits_available    ( tacdc_credits_available         )
  , .credit_overflow      ( tacdc_credit_overflow           )
  , .credit_underflow     ( tacdc_credit_underflow          )
) ;


// -------------------------------------------------------------------------------------
// @@@ ATRC: AFU to TLX Response Credit Manager, for responses from TLX to AFU
// -------------------------------------------------------------------------------------
assign afu_tlx_resp_initial_credit = 7'b000_0001;   // Initialize TLX to present 1 response to the AFU. 
                                                    // Set to 1 so AFU can throttle response presentation to one at a time.

// afu_tlx_resp_credit  -- AFU state machines pulse this signal when the current response is complete.

// -------------------------------------------------------------------------------------
// @@@ ATRDC: AFU to TLX Response Data Credit Manager, for response data from TLX to AFU
// -------------------------------------------------------------------------------------
// Signals do not exist, since AFU pulls FLITs from TLX using a Request+Count/Data Valid mechanism



// ***************************************************************************************
// ***************************************************************************************
// @@@ Part 1: Host -> AFU Commands, AFU -> Host Responses
// ***************************************************************************************
// ***************************************************************************************



// ==============================================================================================================================
// @@@ OPD: Operation Decode - When see valid command from TLX, decode operation type as it enters the Command FIFO.
// ==============================================================================================================================
// Note: For timing reasons, decode the operation as it enters the Command FIFO rather than after it leaves. 
//       Trying to do both operation decode and dispatch in the same cycle takes too long.
// ==============================================================================================================================


// These signals are determined individually, based on the opcode
// Note: Per the OpenCAPI TL spec, NOP should be discarded at the TLX so the AFU should never see it as a valid command.
//         opd_start_nop           ; // Opcode x00                  (abbreviation NOP = NO Operation                  )
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire       opd_start_mmio_write    ; // Opcode x86 & match MMIO BAR (abbreviation MMW = MMio Write                    )
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire       opd_start_mmio_read     ; // Opcode x28 & match MMIO BAR (abbreviation MMR = MMio Read                     )
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire       opd_start_pr_wr_mem     ; // Opcode x86                  (abbreviation PWM = Partial Write Memory          )
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire       opd_start_write_mem     ; // Opcode x81                  (abbreviation FWM = Full    Write Memory          )
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire       opd_start_pr_rd_mem     ; // Opcode x28                  (abbreviation PRM = Partial Read  Memory          )
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire       opd_start_rd_mem        ; // Opcode x20                  (abbreviation FRM = Full    Read  Memory          )
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire       opd_start_write_mem_be  ; // Opcode x82                  (abbreviation WMB = Write Memory with Byte enables)  
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [4:0] opd_start_pipe_type     ; // Operation type entering the pipeline.
                                     // Define as a vector to make it easier to pass from one pipeline stage to the next.
                                     // IMPORTANT: If these assignment change, change all 'case' statements in the pipeline logic also.
parameter  PIPE_TYPE_RD_MEM       = 4;   // Bit number of start_pipe_type[4:0]    10000 = rd_mem
parameter  PIPE_TYPE_PR_RD_MEM    = 3;   // Bit number of start_pipe_type[4:0]    01000 = pr_rd_mem
parameter  PIPE_TYPE_WRITE_MEM    = 2;   // Bit number of start_pipe_type[4:0]    00100 = write_mem
parameter  PIPE_TYPE_PR_WR_MEM    = 1;   // Bit number of start_pipe_type[4:0]    00010 = pr_wr_mem
parameter  PIPE_TYPE_WRITE_MEM_BE = 0;   // Bit number of start_pipe_type[4:0]    00001 = write_mem_be
                                         // Value when command presented by TLX is none of these = 00000

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   opd_start_helper_mmio;        
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   opd_start_helper_pipe_off;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   opd_start_helper_pipe_on;

assign opd_start_helper_mmio     = (tlx_afu_cmd_valid == 1'b1 )                                    ? 1'b1 : 1'b0;
assign opd_start_helper_pipe_off = (tlx_afu_cmd_valid == 1'b1 && mmio_out_enable_pipeline == 1'b0) ? 1'b1 : 1'b0;
assign opd_start_helper_pipe_on  = (tlx_afu_cmd_valid == 1'b1 && mmio_out_enable_pipeline == 1'b1) ? 1'b1 : 1'b0;

// Note: BAR's are not valid until memory_space=1, so when =0 disable decoding as MMIO and send all partial operations to memory.
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   opd_mmio_range_check;  // When 1, passes check so can treat the cmd as an MMIO. When 0, do not treat as MMIO regardless of other checks.
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   opd_mem_range_check;   // When 1, passes check so can treat the cmd as a memory access. When 0, do not treat as memory access.       
assign opd_mmio_range_check = ( acs_memory_space == 1'b1 && acs_mmio_bar0[63:20] == tlx_afu_cmd_pa[63:20]  ) ? 1'b1 : 1'b0;  // 1MB MMIO space
assign opd_mem_range_check  = ( acs_memory_space == 1'b0 ||
                               (acs_memory_space == 1'b1 && acs_mmio_bar0[63:20] != tlx_afu_cmd_pa[63:20]) ) ? 1'b1 : 1'b0;

assign opd_start_mmio_write   = (opd_start_helper_mmio == 1'b1     && tlx_afu_cmd_opcode == 8'h86 && opd_mmio_range_check==1'b1) ? 1'b1 : 1'b0; 
assign opd_start_mmio_read    = (opd_start_helper_mmio == 1'b1     && tlx_afu_cmd_opcode == 8'h28 && opd_mmio_range_check==1'b1) ? 1'b1 : 1'b0; 

assign opd_start_pr_wr_mem    = (opd_start_helper_pipe_off == 1'b1 && tlx_afu_cmd_opcode == 8'h86 && opd_mem_range_check==1'b1 ) ? 1'b1 : 1'b0;
assign opd_start_write_mem    = (opd_start_helper_pipe_off == 1'b1 && tlx_afu_cmd_opcode == 8'h81 && opd_mem_range_check==1'b1 ) ? 1'b1 : 1'b0;
assign opd_start_pr_rd_mem    = (opd_start_helper_pipe_off == 1'b1 && tlx_afu_cmd_opcode == 8'h28 && opd_mem_range_check==1'b1 ) ? 1'b1 : 1'b0;
assign opd_start_rd_mem       = (opd_start_helper_pipe_off == 1'b1 && tlx_afu_cmd_opcode == 8'h20 && opd_mem_range_check==1'b1 ) ? 1'b1 : 1'b0; 
assign opd_start_write_mem_be = (opd_start_helper_pipe_off == 1'b1 && tlx_afu_cmd_opcode == 8'h82 && opd_mem_range_check==1'b1 ) ? 1'b1 : 1'b0; 

assign opd_start_pipe_type[PIPE_TYPE_RD_MEM]       = (opd_start_helper_pipe_on==1'b1 && tlx_afu_cmd_opcode == 8'h20 && opd_mem_range_check==1'b1) ? 1'b1 : 1'b0;

assign opd_start_pipe_type[PIPE_TYPE_PR_RD_MEM]    = (opd_start_helper_pipe_on==1'b1 && tlx_afu_cmd_opcode == 8'h28 && opd_mem_range_check==1'b1) ? 1'b1 : 1'b0;

assign opd_start_pipe_type[PIPE_TYPE_WRITE_MEM]    = (opd_start_helper_pipe_on==1'b1 && tlx_afu_cmd_opcode == 8'h81 && opd_mem_range_check==1'b1) ? 1'b1 : 1'b0;

assign opd_start_pipe_type[PIPE_TYPE_PR_WR_MEM]    = (opd_start_helper_pipe_on==1'b1 && tlx_afu_cmd_opcode == 8'h86 && opd_mem_range_check==1'b1) ? 1'b1 : 1'b0;

assign opd_start_pipe_type[PIPE_TYPE_WRITE_MEM_BE] = (opd_start_helper_pipe_on==1'b1 && tlx_afu_cmd_opcode == 8'h82 && opd_mem_range_check==1'b1) ? 1'b1 : 1'b0;

// --- Detect fatal error conditions ---

// These conditions will log an internal error, and in turn an interrupt. They should be treated as fatal errors even though
// the AFU may or may not stop processing commands.  
// - 'detect_bad_op' will hang because there is no sequencer to issue 'cmd_complete' and move the CMD FIFO to the next command.
// - 'write_mem_DL_is_reserved' will hang because no data FLITs will be requested from the TLX, so the 'wait for data' state will hang.

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire detect_bad_op;              // Opcode is not recognized 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire write_mem_DL_is_reserved;   // On write_mem command, DL field contains 00 which is a reserved

assign detect_bad_op = (tlx_afu_cmd_valid == 1'b1 &&  
                        !(opd_start_mmio_write | opd_start_mmio_read | opd_start_pr_wr_mem    | opd_start_write_mem | 
                          opd_start_pr_rd_mem  | opd_start_rd_mem    | opd_start_write_mem_be |
                          (| opd_start_pipe_type)   // OR reduce
                         ) ) ? 1'b1 : 1'b0;

assign write_mem_DL_is_reserved = (opd_start_write_mem == 1'b1 && tlx_afu_cmd_dl == 2'b00) ? 1'b1 : 1'b0;

// While 'read_mem_DL_is_reserved' is an error, the read state machine will flag this with bad response code and continue.
// Since it is not a hang condition, do not include it in the MMIO 'fatal' error register
//assign read_mem_DL_is_reserved  = (opd_start_rd_mem == 1'b1 && tlx_afu_cmd_dl == 2'b00) ? 1'b1 : 1'b0;


// ==============================================================================================================================
// @@@ CFF: Command FiFo
// ==============================================================================================================================


// Collect 'command completion' indicators from each state machine 
reg         cmd_complete_mmw;
reg         cmd_complete_mmr;
reg         cmd_complete_fwm;
reg         cmd_complete_frm;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        cmd_complete;
assign cmd_complete = cmd_complete_mmw |    // MMIO write
                      cmd_complete_mmr |    // MMIO read
                      cmd_complete_fwm |    // write_mem
                      cmd_complete_frm ;    // rd_mem

wire [171:0] cff_cmd_in, cff_cmd_out;
assign cff_cmd_in = {   tlx_afu_cmd_opcode 
                      , tlx_afu_cmd_dl 
//                    , tlx_afu_cmd_end
                      , tlx_afu_cmd_pa
//                    , tlx_afu_cmd_flag 
//                    , tlx_afu_cmd_os
                      , tlx_afu_cmd_capptag  
                      , tlx_afu_cmd_pl
                      , tlx_afu_cmd_be 
                      , 3'b0                        // Pad to keep aligned hex chars, easier to debug
                      , opd_start_mmio_write 
                      , opd_start_mmio_read 
                      , opd_start_pr_wr_mem 
                      , opd_start_write_mem 
                      , opd_start_pr_rd_mem  
                      , opd_start_rd_mem      
                      , opd_start_write_mem_be  
                      , opd_start_pipe_type
                    };
  wire  [7:0] cff_cmd_opcode;
  wire  [1:0] cff_cmd_dl;
//wire        cff_cmd_end;
  wire [63:0] cff_cmd_pa;
//wire  [3:0] cff_cmd_flag;
//wire        cff_cmd_os;
  wire [15:0] cff_cmd_capptag;
  wire  [2:0] cff_cmd_pl;
  wire [63:0] cff_cmd_be;
  wire        cff_start_mmio_write  ; 
  wire        cff_start_mmio_read   ; 
  wire        cff_start_pr_wr_mem   ; 
  wire        cff_start_write_mem   ; 
  wire        cff_start_pr_rd_mem   ; 
  wire        cff_start_rd_mem      ; 
  wire        cff_start_write_mem_be;   
  wire  [4:0] cff_start_pipe_type   ; 
  wire  [2:0] cff_remove_pad        ;
assign {   cff_cmd_opcode
         , cff_cmd_dl
//       , cff_cmd_end
         , cff_cmd_pa
//       , cff_cmd_flag
//       , cff_cmd_os
         , cff_cmd_capptag
         , cff_cmd_pl
         , cff_cmd_be 
         , cff_remove_pad
         , cff_start_mmio_write 
         , cff_start_mmio_read 
         , cff_start_pr_wr_mem 
         , cff_start_write_mem 
         , cff_start_pr_rd_mem  
         , cff_start_rd_mem      
         , cff_start_write_mem_be  
         , cff_start_pipe_type
       } = cff_cmd_out;

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire cff_cmd_valid;      // Internal version of tlx_afu_cmd_valid
wire cff_fifo_overflow;  // Added to internal error vector sent to MMIO logic
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg  cmd_dispatched;     // Pulsed to 1 when command is complete or sent into the pipeline

lpc_cmdfifo #(.WIDTH(172)) CFF  (                 // Set WIDTH to combined number of TLX command interface signal that are used
    .clock             ( clock               )   // Clock - samples & launches data on rising edge
  , .reset             ( reset               )   // Reset - when 1 set control logic to default state
  , .resync_credits    ( cfg_f1_octrl00_resync_credits   )
  , .tlx_is_ready      ( tlx_afu_ready       )   // When 1, TLX is ready to exchange commands and responses 
  , .cmd_in            ( cff_cmd_in          )   // Vector of command signals
  , .cmd_in_valid      ( tlx_afu_cmd_valid   )   // When 1, load 'cmd_in' into the FIFO
  , .cmd_credit_to_TLX ( afu_tlx_cmd_credit  )   // When 1, there is space in the FIFO for another command
  , .cmd_dispatched    ( cmd_dispatched      )   // When 1, increment read FIFO pointer to present the next FIFO entry
  , .cmd_out           ( cff_cmd_out         )   // Command information at head of FIFO
  , .cmd_out_valid     ( cff_cmd_valid       )   // When 1, 'cmd_out' contains valid information
  , .fifo_overflow     ( cff_fifo_overflow   )   // When 1, FIFO was full when another 'cmd_valid' arrived
) ;


// ==============================================================================================================================
// @@@ DIS: Dispatch an operation - When see valid command from Command FIFO, start appropriate command state machine.
// ==============================================================================================================================

// These conditions must be met to start processing a command:
// a) The TLX must indicate it is ready (the CMD FIFO handles this condition)
// b) The TLX must present a valid command indicator
// c) The opcode must decode to a supported command, targeting the right BAR region where appropriate.
// d1) If the opcode is for a configuration or MMIO operation, activate 'start' when the pipeline is empty or disabled. 
//     The command sequencer itself will return 'cmd_complete' to advance to the next command.
// d2) If the opcode is for a pipeline-able operation but pipelining is disabled, activate 'start' based on cmd_valid.
//     The command sequencer itself will return 'cmd_complete' to advance to the next command. 
// d3) If the opcode is for a pipeline-able operation, and pipelining is enabled, it is OK to set the start signal based on the
//     opcode and BAR checks because the command isn't started in the pipeline until the needed response credits are present. 
//     In this case 'start' is not a pulse but will remain at a constant level until 'afu_tlx_cmd_credit' is pulsed. 
//     cmd_credit waits for response credits to be present, thus not starting a command into the pipeline until it can make it through.
// - The 'start' signals are a level, because cff_cmd_valid is a steady state from the TLX 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        start_mmio_write  ; 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        start_mmio_read   ; 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        start_pr_wr_mem   ; 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        start_write_mem   ; 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        start_pr_rd_mem   ; 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        start_rd_mem      ; 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        start_write_mem_be;   
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire  [4:0] start_pipe_type   ; 

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire        pipe_is_empty;     // When 1, no command is in the pipeline

assign start_mmio_write   = (cff_cmd_valid == 1'b1 && pipe_is_empty == 1'b1) ? cff_start_mmio_write   : 1'b0;
assign start_mmio_read    = (cff_cmd_valid == 1'b1 && pipe_is_empty == 1'b1) ? cff_start_mmio_read    : 1'b0;
assign start_pr_wr_mem    = (cff_cmd_valid == 1'b1                         ) ? cff_start_pr_wr_mem    : 1'b0;
assign start_write_mem    = (cff_cmd_valid == 1'b1                         ) ? cff_start_write_mem    : 1'b0;
assign start_pr_rd_mem    = (cff_cmd_valid == 1'b1                         ) ? cff_start_pr_rd_mem    : 1'b0;
assign start_rd_mem       = (cff_cmd_valid == 1'b1                         ) ? cff_start_rd_mem       : 1'b0;
assign start_write_mem_be = (cff_cmd_valid == 1'b1                         ) ? cff_start_write_mem_be : 1'b0;
assign start_pipe_type    = (cff_cmd_valid == 1'b1                         ) ? cff_start_pipe_type    : 5'b00000;


// It is OK to dispatch a command into the pipeline when:
// a) Pipelining is enabled (handled by 'start_helper_pipe_on')
// b) The command is a write or read to bulk memory (handled by 'start_pipe_type' signals)
// c) Based on the command opcode and size, there are enough response and response data credits present to complete the command
// d) There will not be a collision of data at the bulk memory
//
// When dispatching a command into the pipeline:
// 1) Consume response and response data credits from the response buffer for commands in flight to avoid buffer overrun
// 2) Tell the CMD FIFO to move to the next command


// Check response and response data credits. At the same time, determine number of FLITs if it is a write cmd.
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg [3:0] num_resp_credits_needed;         // Make signals the width of the 'consume_credit' counter logic
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg [5:0] num_resp_data_credits_needed;    // Make signals the width of the 'consume_credit' counter logic
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg [5:0] num_write_flits_needed;
// Helper signals
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [5:0] opd_dl_to_num_flits;
assign opd_dl_to_num_flits = (cff_cmd_dl == 2'b00) ? 6'b000000 : (    // No data
                             (cff_cmd_dl == 2'b01) ? 6'b000001 : (    //  64B = 1 data FLIT
                             (cff_cmd_dl == 2'b10) ? 6'b000010 :      // 128B = 2 data FLITs
                                                     6'b000100   ));  // 256B = 4 data FLITs 
always @(*)  // Combinational logic
  case (start_pipe_type)
    5'b10000:  // PIPE_TYPE_RD_MEM    
               begin  
                 num_resp_credits_needed      = 4'b0001;
                 num_resp_data_credits_needed = opd_dl_to_num_flits;   // Num FLITs in dL field
                 num_write_flits_needed       = 6'b0;
               end
    5'b01000:  // PIPE_TYPE_PR_RD_MEM    
               begin  
                 num_resp_credits_needed      = 4'b0001;
                 num_resp_data_credits_needed = 6'b000001;              // Always 1 FLIT
                 num_write_flits_needed       = 6'b0;
               end
    5'b00100:  // PIPE_TYPE_WRITE_MEM    
               begin  
                 num_resp_credits_needed      = 4'b0001;
                 num_resp_data_credits_needed = 6'b0;
                 num_write_flits_needed       = opd_dl_to_num_flits;   // Num FLITs in dL field
               end
    5'b00010:  // PIPE_TYPE_PR_WR_MEM    
               begin  
                 num_resp_credits_needed      = 4'b0001;
                 num_resp_data_credits_needed = 6'b0;
                 num_write_flits_needed       = 6'b000001;              // Always 1 FLIT
               end
    5'b00001:  // PIPE_TYPE_WRITE_MEM_BE    
               begin  
                 num_resp_credits_needed      = 4'b0001;
                 num_resp_data_credits_needed = 6'b0;
                 num_write_flits_needed       = 6'b000001;              // Always 1 FLIT
               end
    default:   // No command is present or operation is not a pipeline-able type
               begin  
                 num_resp_credits_needed      = 4'b0;
                 num_resp_data_credits_needed = 6'b0;
                 num_write_flits_needed       = 6'b0;
               end
  endcase 

// Manage response buffer credits

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg        rff_resp_sent;      
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg  [5:0] rffcr_consume_credit;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [5:0] rffcr_buffers_available;
wire       rffcr_credit_overflow;
wire       rffcr_credit_underflow;

lpc_tlx_afu_credit_mgr #(.MSB(5)) RFF_CREDITS (    // Retask TLX-AFU credit manager logic
    .clock                ( clock                           )
  , .reset                ( reset                           )
  , .resync_credits       ( cfg_f1_octrl00_resync_credits   )
//, .tlx_initial_credit   ( 6'b100000                       )  // Response Buffer has 16 entries (value is incorrect)
  , .tlx_initial_credit   ( 6'b010000                       )  // Response Buffer has 16 entries
  , .tlx_credit           ( rff_resp_sent                   )  // Pulsed each time an entry in the Response Buffer is freed
  , .afu_consume_credit_0 ( rffcr_consume_credit            )
  , .afu_consume_credit_1 ( 6'b0                        )
  , .afu_consume_credit_2 ( 6'b0                        )
  , .afu_consume_credit_3 ( 6'b0                        )
  , .afu_consume_credit_4 ( 6'b0                        )
  , .afu_consume_credit_5 ( 6'b0                        )
  , .afu_consume_credit_6 ( 6'b0                        )
  , .afu_consume_credit_7 ( 6'b0                        )
  , .afu_reclaim_credit_0 ( 6'b0                        )  // rff_resp_sent reclaims credits, so this port is not needed
  , .credits_available    ( rffcr_buffers_available         )
  , .credit_overflow      ( rffcr_credit_overflow           )  
  , .credit_underflow     ( rffcr_credit_underflow          )  
) ;

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   resp_credits_are_available;
assign resp_credits_are_available = (rffcr_buffers_available >= {2'b00,num_resp_credits_needed} + num_resp_data_credits_needed) ? 1'b1 : 1'b0;

// Check if there will be a collision on data at bulk memory
// (Really all we are doing is spacing the commands apart in the pipeline so they don't collide at
//  common resources like bulk memory or the AFU->TLX response interface. The nice thing about 
//  checking response credits ahead of time is we can use bulk memory as the place to check for
//  collisions since collision free access there will ensure collision free access on the response
//  interface to the TLX.)
//
// Do this by keeping track of a 4 bit vector, in which '1' indicates bulk memory is busy for a cycle.
// The access to bulk memory can be read or write, it doesn't matter since the BRAM memory is implemented
// to do one or the other on a single cycle.
// It also doesn't matter which cycle of the pipeline is actually used to access bulk memory, since the 
// pipelined states will manage that properly.  
// However we don't want to dispatch a command that will use bulk memory into the pipeline until the one 
// preceeding it will be done using memory. 
// To manage this, load a 4 bit vector with the number of FLITs used by a command when it is started in
// the pipeline. On each cycle, shift the vector 1 position loading '0' into the shifted in position. 
// When there is not a '1' in last bit position of the vector, it is safe to start the next command. 
// If there is a '1' in that position then defer starting the next command because there would be a
// collision at bulk memory (and at the AFU->TLX response interface).
//
// Examples:
// a) Pipeline is empty 
//    After shift:  vector[3:0]=0000         
// b) Start a write command using 4 FLITs into the pipeline. Since vector[0]=0 after the shift,
//    dispatch the command into the pipeline. OR '1111' into the vector after the shift.
//    After shift:  vector[3:0]=0000        After OR: vector[3:0]=1111
// c) No command is present from the CMD FIFO on the next cycle
//    After shift:  vector[3:0]=0111        
// d) No command is present from the CMD FIFO on the next cycle
//    After shift:  vector[3:0]=0011        
// e) A read command of 2 FLITs arrives at the head of the CMD FIFO. Since after the shift vector[0]=1, 
//    don't dispatch it yet.
//    After shift:  vector[3:0]=0001        
// f) The read command remains at the head of CMD FIFO. Since after the shift vector[0]=0, 
//    dispatch the read command into the pipeline. OR '0011' into the vector after the shift.
//    After shift:  vector[3:0]=0000        After OR: vector[3:0]=0011
// g) A write command of 1 FLIT arrives at the head of the CMD FIFO. Since after the shift vector[0]=1,
//    don't dispatch it yet.
//    After shift:  vector[3:0]=0001        
// k) The write command remains at the head of CMD FIFO. Since vector[0]=0 after the shift,
//    dispatch the command into the pipeline. OR '0001' into the vector after the shift.
//    After shift:  vector[3:0]=0000        After OR: vector[3:0]=0001
// l) A read command of 1 FLIT arrives a the head of CMD FIFO. Since vector[0]=0 after the shift,
//    dispatch the command into the pipeline. OR '0001' into the vector after the shift.
//    After shift:  vector[3:0]=0000        After OR: vector[3:0]=0001
//
reg  [3:0] opd_data_position_in_use;
reg  [3:0] opd_data_position_in_use_OR;
always @(posedge(clock))
  if (reset == 1'b1) 
    opd_data_position_in_use <= 4'b0000;
  else
    opd_data_position_in_use <= (opd_data_position_in_use >> 1) | opd_data_position_in_use_OR ;  // OR after the shift, not before

// Helper signal
reg [3:0] opd_flit_vector;
always @(*)  // Combinational logic
  case (num_resp_data_credits_needed | num_write_flits_needed)   // Two conditions are mutually exclusive so can safely OR them
    6'b000000: opd_flit_vector = 4'b0000;
    6'b000001: opd_flit_vector = 4'b0000;  // One FLIT goes with the CMD, so wait cycles is 1 less than number of FLITs
    6'b000010: opd_flit_vector = 4'b0001;
    6'b000011: opd_flit_vector = 4'b0011;
    6'b000100: opd_flit_vector = 4'b0111;
    default:   opd_flit_vector = 4'b0000;  // When no command is present or if it is non-pipelineable
  endcase


// Dispatch a command if appropriate
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg  start_pipe_valid;             // Indicates send command credit back to TLX and to start current CFF cmd in 1st stage of pipeline
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire any_start_pipe_type_active;
assign any_start_pipe_type_active = (| start_pipe_type);  // OR Reduce
always @(*)  // Combinational logic
  if ( any_start_pipe_type_active == 1'b1  &&   // A pipeline-able command as at the head of the CMD FIFO
       resp_credits_are_available == 1'b1  &&   // Enough response credits are available
       opd_data_position_in_use[0] == 1'b0 )    // Data pipeline is open
    begin  // Dispatch the command
      // Consume response credits for response in flight. Because 1 RFF buffer entry is either a response or response with response data,
      // need to consume either 1 entry on response without data or (resp + resp_data - 1) to adjust for the buffer entry that holds both.
      rffcr_consume_credit         = {2'b0,num_resp_credits_needed} + 
                                     ((num_resp_data_credits_needed == 6'b0) ? 6'b0 : num_resp_data_credits_needed-6'b000001) ;
      opd_data_position_in_use_OR  = opd_flit_vector;               // Reserve data pipeline positions
      cmd_dispatched               = 1'b1;                          // Tell TLX to move to the next command
      start_pipe_valid             = 1'b1;                          // Start command in pipeline
    end  
  else     // Wait, something isn't quite right yet
    begin
      rffcr_consume_credit         = 6'b0;                      // Do not consume response or response data credits
      opd_data_position_in_use_OR  = 4'b0000;                       // Do not reserve data pipeline positions
      cmd_dispatched               = cmd_complete;                  // Allow other non-pipelined commands to tell TLX to advance
      start_pipe_valid             = 1'b0;                          // Do not start command in pipeline
    end


// ==============================================================================================================================
// @@@ PIP: States of pipelined writes or reads to bulk memory
// ==============================================================================================================================


// PIP1: Capture command to start the pipeline. 
// Note: If timing margins permit, it may be possible to merge PIP1 and PIP2. But for now keep them separate to ease timing.
//g   [7:0] pip1_cmd_opcode;  // Currently not used
reg  [15:0] pip1_cmd_capptag;
reg  [63:0] pip1_cmd_pa;
reg   [1:0] pip1_cmd_dl;
reg   [2:0] pip1_cmd_pl;
reg  [63:0] pip1_cmd_be;
reg   [5:0] pip1_num_resp_cred;
reg   [4:0] pip1_pipe_type;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg         pip1_valid;
always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  if (start_pipe_valid == 1'b1)
    begin   
//    pip1_cmd_opcode    <= cff_cmd_opcode;
      pip1_cmd_capptag   <= cff_cmd_capptag;
      pip1_cmd_pa        <= cff_cmd_pa;       
      pip1_cmd_dl        <= cff_cmd_dl;       
      pip1_cmd_pl        <= cff_cmd_pl;       
      pip1_cmd_be        <= cff_cmd_be;       
      pip1_num_resp_cred <= num_resp_data_credits_needed;  // Preserve to make reclaimation easier if there is an error response code
      pip1_pipe_type     <= start_pipe_type;
      pip1_valid         <= start_pipe_valid;
    end
  else    
    begin   
//    pip1_cmd_opcode    <= 8'b0;   // For easier debug, replace fields with all 0s when no command is in this pipeline position
      pip1_cmd_capptag   <= 16'b0;
      pip1_cmd_pa        <= 64'b0;       
      pip1_cmd_dl        <= 2'b0;       
      pip1_cmd_pl        <= 3'b0;       
      pip1_cmd_be        <= 64'b0; 
      pip1_num_resp_cred <= 6'b0;      
      pip1_pipe_type     <= 5'b0;
      pip1_valid         <= 1'b0;   // Important: Providing 0 on valid is important to keep invalid pipe cycles from taking action           
    end
 

// PIP2: Fill in unused fields and start SAM. If operation is a write, start fetch of data from TLX.
//
// Helper signal
reg  [63:0] pip2_pr_wren;
always @(*)   // Combinational logic
  case (pip1_cmd_pl[2:0])   // Align enables to 32 bit word based on address and size
    3'b000 : pip2_pr_wren = 64'h0000_0000_0000_0001 << (  pip1_cmd_pa[5:0]        );  //  1 byte
    3'b001 : pip2_pr_wren = 64'h0000_0000_0000_0003 << ( {pip1_cmd_pa[5:1], 1'b0} );  //  2 bytes
    3'b010 : pip2_pr_wren = 64'h0000_0000_0000_000F << ( {pip1_cmd_pa[5:2], 2'b0} );  //  4 bytes
    3'b011 : pip2_pr_wren = 64'h0000_0000_0000_00FF << ( {pip1_cmd_pa[5:3], 3'b0} );  //  8 bytes
    3'b100 : pip2_pr_wren = 64'h0000_0000_0000_FFFF << ( {pip1_cmd_pa[5:4], 4'b0} );  // 16 bytes
    3'b101 : pip2_pr_wren = 64'h0000_0000_FFFF_FFFF << ( {pip1_cmd_pa[5]  , 5'b0} );  // 32 bytes
    default: pip2_pr_wren = 64'h0000_0000_0000_0000;    // Suppress write, other logic should create error response
  endcase 

//g   [7:0] pip2_cmd_opcode;   // Currently not used
reg  [15:0] pip2_cmd_capptag;
reg  [63:0] pip2_cmd_pa;
reg   [1:0] pip2_cmd_dl;
reg   [2:0] pip2_cmd_pl;
reg  [63:0] pip2_cmd_be;
reg   [5:0] pip2_num_resp_cred;
reg   [4:0] pip2_pipe_type;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg         pip2_valid;
reg         sam_enable_pip;
reg  [63:0] sam_addr_in_pip;
// Helper signal: Raise error and suppress command going forward if dL value is illegal
wire   pip2_illegal_dl;
assign pip2_illegal_dl = ( (pip1_pipe_type[PIPE_TYPE_WRITE_MEM] == 1'b1 || pip1_pipe_type[PIPE_TYPE_RD_MEM] == 1'b1) 
                           && pip1_cmd_dl == 2'b00 && pip1_valid == 1'b1 
                         ) ? 1'b1 : 1'b0;

always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  begin   
    // Do not need to qualify all this logic with 'if (pip1_valid=1'b1)' because pip1 state sets pip1_*=0 if no cmd is present.
    // Therefore we can just evaluate everything knowing it won't do anything useful or damaging to signals set at 0.
//  pip2_cmd_opcode    <= pip1_cmd_opcode;
    pip2_cmd_capptag   <= pip1_cmd_capptag;
    // Fill in fields that vary by command
    case (pip1_pipe_type)
    5'b10000:  // PIPE_TYPE_RD_MEM    
               begin  
                 sam_addr_in_pip <= {pip1_cmd_pa[63:5], 5'b00000};   // SAM address is same as modified PA
                 pip2_cmd_pa     <= {pip1_cmd_pa[63:5], 5'b00000};   // PA[4:0] inferred as 0
                 pip2_cmd_dl     <= pip1_cmd_dl;                     // Command provides dL     
                 pip2_cmd_pl     <= 3'b111;                          // pL is unused, set to a reserved value                           
                 pip2_cmd_be     <= 64'b0;                           // be is unused on read
               end
    5'b01000:  // PIPE_TYPE_PR_RD_MEM    
               begin  
                 sam_addr_in_pip <= pip1_cmd_pa[63:0];               // SAM address is same as PA
                 pip2_cmd_pa     <= pip1_cmd_pa[63:0];               // Command provides entire address
                 pip2_cmd_dl     <= 2'b01;                           // Always 1 FLIT     
                 pip2_cmd_pl     <= pip1_cmd_pl;                     // Command provides pL                           
                 pip2_cmd_be     <= 64'b0;                           // be is unused on read
               end
    5'b00100:  // PIPE_TYPE_WRITE_MEM    
               begin  
                 sam_addr_in_pip <= {pip1_cmd_pa[63:6], 6'b000000};  // SAM address is same as modified PA  
                 pip2_cmd_pa     <= {pip1_cmd_pa[63:6], 6'b000000};  // PA[5:0] inferred as 0
                 pip2_cmd_dl     <= pip1_cmd_dl;                     // Command provides dL    
                 pip2_cmd_pl     <= 3'b111;                          // pL is unused, set to a reserved value                         
                 pip2_cmd_be     <= 64'hFFFFFFFF_FFFFFFFF;           // Write all bytes is inferred
               end
    5'b00010:  // PIPE_TYPE_PR_WR_MEM    
               begin  
                 sam_addr_in_pip <= pip1_cmd_pa[63:0];               // SAM address is same as PA
                 pip2_cmd_pa     <= pip1_cmd_pa[63:0];               // Command provides entire address
                 pip2_cmd_dl     <= 2'b01;                           // Always 1 FLIT     
                 pip2_cmd_pl     <= pip1_cmd_pl;                     // Command provides pL                           
                 pip2_cmd_be     <= pip2_pr_wren;                    // be is determined from pL field
               end
    5'b00001:  // PIPE_TYPE_WRITE_MEM_BE    
               begin  
                 sam_addr_in_pip <= {pip1_cmd_pa[63:6], 6'b000000};  // SAM address is same as modified PA  
                 pip2_cmd_pa     <= {pip1_cmd_pa[63:6], 6'b000000};  // PA[5:0] inferred as 0
                 pip2_cmd_dl     <= 2'b01;                           // Always 1 FLIT    
                 pip2_cmd_pl     <= 3'b111;                          // pL is unused, set to a reserved value                         
                 pip2_cmd_be     <= pip1_cmd_be;                     // Command provides byte enables
               end
    default:   // No command is present or operation is not a pipeline-able type
               begin  
                 sam_addr_in_pip <= pip1_cmd_pa;                     // SAM address is same as modified PA
                 pip2_cmd_pa     <= pip1_cmd_pa;                     // Propagate non-valid command values forward
                 pip2_cmd_dl     <= pip1_cmd_dl;                       
                 pip2_cmd_pl     <= pip1_cmd_pl;                                             
                 pip2_cmd_be     <= pip1_cmd_be;                     
               end
    endcase 
    pip2_num_resp_cred <= pip1_num_resp_cred;
    pip2_pipe_type     <= pip1_pipe_type;
    pip2_valid         <= (pip2_illegal_dl == 1'b1) ? 1'b0 : pip1_valid;   // Suppress cmd going forward if dL is illegal
    // Kick off access to SAM       
    sam_enable_pip     <= (pip2_illegal_dl == 1'b1) ? 1'b0 : pip1_valid;   // If valid=0, sam is disabled
    // If operation is a write, start fetch of data from TLX.
    if (pip1_pipe_type[PIPE_TYPE_WRITE_MEM] == 1'b1)
      begin
        afu_tlx_cmd_rd_req_pip <= 1'b1;
        afu_tlx_cmd_rd_cnt_pip <= {1'b0, pip1_cmd_dl} ;      // For legal sizes of 64, 128, 256 Bytes
      end
    else if (pip1_pipe_type[PIPE_TYPE_PR_WR_MEM] == 1'b1 || pip1_pipe_type[PIPE_TYPE_WRITE_MEM_BE] == 1'b1)
      begin
        afu_tlx_cmd_rd_req_pip <= 1'b1;
        afu_tlx_cmd_rd_cnt_pip <= {1'b0, 2'b01} ;            // Size is fixed at 64 Bytes
      end
    else
      begin
        afu_tlx_cmd_rd_req_pip <= 1'b0;                      // Set to 0 so other states can use the interface
        afu_tlx_cmd_rd_cnt_pip <= 3'b000;     
      end
  end


// PIP3: Absorb 1st cycle waiting for SAM, and possibly write data from TLX.
//
//g   [7:0] pip3_cmd_opcode;  // Currently not used
reg  [15:0] pip3_cmd_capptag;
reg  [63:0] pip3_cmd_pa;
reg   [1:0] pip3_cmd_dl;
reg   [2:0] pip3_cmd_pl;
reg  [63:0] pip3_cmd_be;
reg   [5:0] pip3_num_resp_cred;
reg   [4:0] pip3_pipe_type;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg         pip3_valid;
always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  begin
//  pip3_cmd_opcode    <= pip2_cmd_opcode;
    pip3_cmd_capptag   <= pip2_cmd_capptag;
    pip3_cmd_pa        <= pip2_cmd_pa;
    pip3_cmd_dl        <= pip2_cmd_dl;
    pip3_cmd_pl        <= pip2_cmd_pl;
    pip3_cmd_be        <= pip2_cmd_be;
    pip3_num_resp_cred <= pip2_num_resp_cred;
    pip3_pipe_type     <= pip2_pipe_type;
    pip3_valid         <= pip2_valid;
  end


// PIP4: Absorb 2nd cycle waiting for SAM, and possibly write data from TLX.
//
//g   [7:0] pip4_cmd_opcode;   // Currently not used
reg  [15:0] pip4_cmd_capptag;
reg  [63:0] pip4_cmd_pa;
reg   [1:0] pip4_cmd_dl;
reg   [2:0] pip4_cmd_pl;
reg  [63:0] pip4_cmd_be;
reg   [5:0] pip4_num_resp_cred;
reg   [4:0] pip4_pipe_type;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg         pip4_valid;
always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  begin
//  pip4_cmd_opcode    <= pip3_cmd_opcode;
    pip4_cmd_capptag   <= pip3_cmd_capptag;
    pip4_cmd_pa        <= pip3_cmd_pa;
    pip4_cmd_dl        <= pip3_cmd_dl;
    pip4_cmd_pl        <= pip3_cmd_pl;
    pip4_cmd_be        <= pip3_cmd_be;
    pip4_num_resp_cred <= pip3_num_resp_cred;
    pip4_pipe_type     <= pip3_pipe_type;
    pip4_valid         <= pip3_valid;
  end


// PIP5: SAM response is available, determine response code. 
//
// Helper signals
// 'legal_size':  set legal_size to 1 if requested operation was 
//                a) partial write or read of 1, 2, 4, 8, 16 or 32 Bytes 
//                b) write_mem.be (size assumed to be 64 Bytes)
//                c) write_mem or rd_mem of 64, 128, or 256 Bytes in size 
//                
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   pip5_legal_size;
assign pip5_legal_size  = ( ( (pip4_pipe_type[PIPE_TYPE_PR_WR_MEM] == 1'b1 || pip4_pipe_type[PIPE_TYPE_PR_RD_MEM] == 1'b1)
                              && (pip4_cmd_pl == 3'b000 || pip4_cmd_pl == 3'b001 || pip4_cmd_pl == 3'b010 ||
                                  pip4_cmd_pl == 3'b011 || pip4_cmd_pl == 3'b100 || pip4_cmd_pl == 3'b101)   ) ? 1'b1 : 1'b0 
                          ) |   // OR conditions together
                          ( (pip4_pipe_type[PIPE_TYPE_WRITE_MEM_BE] == 1'b1) ? 1'b1 : 1'b0
                          ) |
                          ( ( (pip4_pipe_type[PIPE_TYPE_WRITE_MEM] == 1'b1 || pip4_pipe_type[PIPE_TYPE_RD_MEM] == 1'b1)
                              && (pip4_cmd_dl == 2'b01  || pip4_cmd_dl == 2'b10  || pip4_cmd_dl == 2'b11) ) ? 1'b1 : 1'b0
                          );

// 'legal_align': set legal_align to 1 if address is naturally aligned to the size
//                a) partial write or partial read
//                b) write_mem.be (always aligned by command format)
//                c) write_mem or rd_mem
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   pip5_legal_align;
assign pip5_legal_align = ( ( (pip4_pipe_type[PIPE_TYPE_PR_WR_MEM] == 1'b1 || pip4_pipe_type[PIPE_TYPE_PR_RD_MEM] == 1'b1)
                              && ( (pip4_cmd_pl == 3'b000                                ) ||  //   1 byte has any alignment
                                   (pip4_cmd_pl == 3'b001 && pip4_cmd_pa[0]   == 1'b0    ) ||  //   2 bytes
                                   (pip4_cmd_pl == 3'b010 && pip4_cmd_pa[1:0] == 2'b00   ) ||  //   4 bytes
                                   (pip4_cmd_pl == 3'b011 && pip4_cmd_pa[2:0] == 3'b000  ) ||  //   8 bytes
                                   (pip4_cmd_pl == 3'b100 && pip4_cmd_pa[3:0] == 4'b0000 ) ||  //  16 bytes
                                   (pip4_cmd_pl == 3'b101 && pip4_cmd_pa[4:0] == 5'b00000) ||  //  32 bytes
                                   (pip4_cmd_pl == 3'b110                                ) ||  //  64 bytes - treat as legal so resp_code is illegal size
                                   (pip4_cmd_pl == 3'b111                                ) )   // 128 bytes - treat as legal so resp_code is illegal size
                            ) ? 1'b1 : 1'b0
                          ) |   // OR conditions together
                          ( (pip4_pipe_type[PIPE_TYPE_WRITE_MEM_BE] == 1'b1) ? 1'b1 : 1'b0
                          ) |
                          ( ( (pip4_pipe_type[PIPE_TYPE_WRITE_MEM] == 1'b1 || pip4_pipe_type[PIPE_TYPE_RD_MEM] == 1'b1)
                              && ( (pip4_cmd_dl == 2'b00                                      ) ||  // Treat reserved as aligned so resp_code is illegal size
                                   (pip4_cmd_dl == 2'b01 && pip4_cmd_pa[5:0] == 6'b00_0000  ) ||  //  64 Bytes
                                   (pip4_cmd_dl == 2'b10 && pip4_cmd_pa[6:0] == 7'b000_0000 ) ||  // 128 Bytes
                                   (pip4_cmd_dl == 2'b11 && pip4_cmd_pa[7:0] == 8'b0000_0000) )   // 256 Bytes
                            ) ? 1'b1 : 1'b0
                          ); 
// 'dl_to_cnt': convert dL into number of cycles FLITs take to transfer. 
wire [1:0] pip5_dl_to_cnt;
assign pip5_dl_to_cnt = ( (pip4_cmd_dl == 2'b01) ? 2'b00 : (    // 1 FLIT  ( 64B)  (check for dl=00 occurs earlier in pipeline)
                          (pip4_cmd_dl == 2'b10) ? 2'b01 :      // 2 FLITs (128B)
                                                   2'b11   ));  // 4 FLITs (256B)  There is no way for DL to specify 192 Bytes
//
//g   [7:0] pip5_cmd_opcode;   // Currently not used
reg  [15:0] pip5_cmd_capptag;
reg  [63:0] pip5_cmd_pa;
reg   [1:0] pip5_cmd_dl;
reg   [2:0] pip5_cmd_pl;
reg  [63:0] pip5_cmd_be;
reg   [4:0] pip5_pipe_type;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg         pip5_valid;
reg  [11:0] pip5_sam_addr_out;
reg   [1:0] pip5_flit_addr;
reg   [1:0] pip5_flit_cnt;
reg   [7:0] pip5_resp_opcode;
reg   [1:0] pip5_resp_dl;
reg   [1:0] pip5_resp_dp;
reg   [3:0] pip5_resp_code;
always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  begin
//  pip5_cmd_opcode    <= pip4_cmd_opcode;
    pip5_cmd_capptag   <= pip4_cmd_capptag;
    pip5_cmd_pa        <= pip4_cmd_pa;
    pip5_cmd_dl        <= pip4_cmd_dl;
    pip5_cmd_pl        <= pip4_cmd_pl;
    pip5_cmd_be        <= pip4_cmd_be;
    pip5_pipe_type     <= pip4_pipe_type;
    pip5_valid         <= pip4_valid;
    pip5_sam_addr_out  <= sam_addr_out;
    pip5_flit_addr     <= pip4_cmd_pa[7:6];   // Select starting FLIT from command address
    pip5_flit_cnt      <= pip5_dl_to_cnt;     // Number of cycles of data FLITs 
    if (pip4_valid == 1'b1)
      begin
        case (pip4_pipe_type)
        5'b10000,  // PIPE_TYPE_RD_MEM    
        5'b01000:  // PIPE_TYPE_PR_RD_MEM    
                   begin 
                     if (pip5_legal_align == 1'b0 || pip5_legal_size == 1'b0 || sam_overflow == 1'b1 ||
                         (sam_no_match == 1'b1 && mmio_out_ignore_nomatch_on_read == 1'b0) )
                       begin  // Failing response
                         pip5_resp_opcode         <= 8'h02;         // mem_rd_fail
                         pip5_resp_dl             <= pip4_cmd_dl;   // Response DL matches Command DL indicating all FLITs were covered by response
                         pip5_resp_dp             <= 2'b00;         // All FLITs covered by response, so start at 0
                         if (pip5_legal_align == 1'b0)
                           pip5_resp_code  <= 4'hB;                 // Address is not properly aligned
                         else if (pip5_legal_size == 1'b0)
                           pip5_resp_code  <= 4'h9;                 // Length is not legal, report unsupported size error
                         else if (sam_overflow == 1'b1)
                           pip5_resp_code  <= 4'hE;                 // Access to un-implemented address in SAM, use general fail code
                         else // if (sam_no_match == 1'b1 && mmio_out_ignoreno_match_on_read == 1'b0)
                           pip5_resp_code  <= 4'hE;                 // Bulk memory will return X's, use general fail code
                         tardc_reclaim_credit_opd <= pip4_num_resp_cred; // Return read response data credits as soon as know they won't be used.
                                                                         // This gives the dispatcher the most flexibility in filling the pipeline.
                       end
                     else     // Successful response
                       begin  
                         pip5_resp_opcode         <= 8'h01;         // mem_rd_response
                         pip5_resp_dl             <= pip4_cmd_dl;   // Response DL matches Command DL indicating all FLITs were covered by response
                         pip5_resp_dp             <= 2'b00;         // All FLITs covered by response, so start at 0
                         pip5_resp_code           <= 4'h0;          // Not used with mem_rd_response
                         tardc_reclaim_credit_opd <= 6'b0;      // No read response data credits to reclaim, read data FLITs will use them 
                       end
                    end
        5'b00100,  // PIPE_TYPE_WRITE_MEM    
        5'b00010,  // PIPE_TYPE_PR_WR_MEM    
        5'b00001:  // PIPE_TYPE_WRITE_MEM_BE    
                   begin  
                     if (pip5_legal_align == 1'b0 || pip5_legal_size == 1'b0 || sam_overflow == 1'b1)
                       begin  // Failing response
                         pip5_resp_opcode         <= 8'h05;         // mem_wr_fail
                         pip5_resp_dl             <= pip4_cmd_dl;   // Response DL matches Command DL indicating all FLITs were covered by response
                         pip5_resp_dp             <= 2'b00;         // All FLITs covered by response, so start at 0
                         if (pip5_legal_align == 1'b0)
                           pip5_resp_code  <= 4'hB;                 // Address is not properly aligned
                         else if (pip5_legal_size == 1'b0)
                           pip5_resp_code  <= 4'h9;                 // Length is not legal, report unsupported size error
                         else // if (sam_overflow == 1'b1)          // (sam_no_match is not an error on writes, although sam_overflow is)
                           pip5_resp_code  <= 4'hE;                 // Access to un-implemented address in SAM, use general fail code
                         tardc_reclaim_credit_opd <= 6'b0;      // No read response data credits to reclaim, it's a write 
                       end
                     else     // Successful response
                       begin  
                         pip5_resp_opcode         <= 8'h04;         // mem_wr_response
                         pip5_resp_dl             <= pip4_cmd_dl;   // Response DL matches Command DL indicating all FLITs were covered by response
                         pip5_resp_dp             <= 2'b00;         // All FLITs covered by response, so start at 0
                         pip5_resp_code           <= 4'h0;          // Not used with mem_wr_response
                         tardc_reclaim_credit_opd <= 6'b0;      // No read response data credits to reclaim, it's a write 
                       end
                   end
        default:   // No command is present or operation is not a pipeline-able type
                   begin  
                     pip5_resp_opcode         <= 8'b0;     
                     pip5_resp_dl             <= 2'b0; 
                     pip5_resp_dp             <= 2'b0;
                     pip5_resp_code           <= 4'b0; 
                     tardc_reclaim_credit_opd <= 6'b0;  // Keep OR gate inputs inactive
                   end
        endcase 
      end
    else  // No valid command on this cycle
      begin
        pip5_resp_opcode         <= 8'b0;      // Set to 0s to make simulation debug easier
        pip5_resp_dl             <= 2'b0; 
        pip5_resp_dp             <= 2'b0;
        pip5_resp_code           <= 4'b0; 
        tardc_reclaim_credit_opd <= 6'b0;  // Keep OR gate inputs inactive
      end
  end



// PIP6: Start Memory Access  (This state may repeat up to 4 times, expanding one command into 1 to 4 FLITs.)
//
// General flow
// On the 1st cycle, use pip5 values. Use pip5_valid to determine the first cycle (it should be 0 on remaining cycles of the cmd).
//   If the cmd is not valid, propagate the pip5 values downstream for 1 cycle. (no response, just absorb 1 cycle)
//   If the cmd is valid and not failing, access the memory. (covers response + 1st data FLIT)
//   If the cmd is valid and failing, suppress the write and read (no data). Continue to wait but only make 1st cycle valid. (resp w/o data)
// On cycle 2-4, use pip6 values.
//   [If the cmd is not valid, shouldn't enter this state. (there should be no expansion of invalid command)]
//   If the cmd is valid and not failing, continue to access the memory. Increment addr & local count until it matches total FLITs (2-4 data)
//   If the cmd is valid and failing, suppress the write and read (no data). Continue to wait until local count = total FLITs (no data on bad resp)
// If command insertion into pip1 is working correctly, pip5_valid should only be 1 on the 1st cycle of a multi-FLIT cmd. Also there
// should be non-valid cycles equal to the number of data FLITs just behind this command so the pip6 state shouldn't have to worry
// about leaving gaps or overloading commands in the pipelined command stream. If all works properly, the number of cycles this
// stage expands the 'pipeline valid' should exactly match the number of vacant spots in the pipeline inserted behind it.
//
// Also introduce a new valid type (cmd_valid) to indicate this is the 1st cycle of the data transfer. 
// pipe valid (pip*_valid) continues to indicate there is something useful in this cycle, which now can mean cmd+data or just data.
//Start
//g   [7:0]  pip6_cmd_opcode;   // Currently not used
reg  [15:0]  pip6_cmd_capptag;
reg  [63:0]  pip6_cmd_pa;
reg   [1:0]  pip6_cmd_dl;
reg   [2:0]  pip6_cmd_pl;
reg  [63:0]  pip6_cmd_be;
reg   [4:0]  pip6_pipe_type;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          pip6_cmd_valid;      // cmd_valid is 1 only on the 1st FLIT of the command
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          pip6_valid;          // valid is 1 on every FLIT of the command
reg   [1:0]  pip6_flit_addr;
reg   [1:0]  pip6_flit_cnt;
reg   [7:0]  pip6_resp_opcode;
reg   [1:0]  pip6_resp_dl;
reg   [1:0]  pip6_resp_dp;
reg   [3:0]  pip6_resp_code;
reg   [11:0] pip6_sam_addr_out;
reg   [63:0] mem_addr_pip;
reg   [63:0] mem_wren_pip;
reg  [511:0] mem_din_pip;
reg          mem_din_bdi_pip;
reg          mem_rden_pip;
reg    [1:0] mem_rdcnt_pip;
reg    [1:0] pip6_local_cnt;
// Helper signals
// 'fail_resp' = 1 when the response code is mem_wr_fail or mem_rd_fail. Make 2 copies because pip5 is only good on the first cycle.
wire pip5_fail_resp;
wire pip6_fail_resp;
assign pip5_fail_resp = (pip5_resp_opcode == 8'h05 || pip5_resp_opcode == 8'h02) ? 1'b1 : 1'b0;
assign pip6_fail_resp = (pip6_resp_opcode == 8'h05 || pip6_resp_opcode == 8'h02) ? 1'b1 : 1'b0;
//
always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  if (pip5_valid == 1'b0 && pip6_valid == 1'b0)   // Need to check pip6_valid to ensure no command is still in progress in this stage
  // On the 1st cycle, use pip5 values. Use pip5_valid to determine the first cycle (it should be 0 on remaining cycles of the cmd).
  //   (1st cycle) If the cmd is not valid, propagate the pip5 values downstream for 1 cycle. (no response, just absorb 1 cycle)
    begin        
//    pip6_cmd_opcode    <= pip5_cmd_opcode;
      pip6_cmd_capptag   <= pip5_cmd_capptag;
      pip6_cmd_pa        <= pip5_cmd_pa;
      pip6_cmd_dl        <= pip5_cmd_dl;
      pip6_cmd_pl        <= pip5_cmd_pl;
      pip6_cmd_be        <= pip5_cmd_be;
      pip6_pipe_type     <= pip5_pipe_type;
      pip6_resp_opcode   <= pip5_resp_opcode;
      pip6_resp_dl       <= pip5_resp_dl;
      pip6_resp_dp       <= pip5_resp_dp;
      pip6_resp_code     <= pip5_resp_code;
      pip6_cmd_valid     <= 1'b0;                // This is not the start of the command
      pip6_valid         <= pip5_valid;          // Propagate non-valid command downstream
      pip6_sam_addr_out  <= pip5_sam_addr_out;
      pip6_flit_addr     <= pip5_flit_addr;
      pip6_flit_cnt      <= pip5_flit_cnt;
      pip6_local_cnt     <= 2'b00;               // Unused, but set to the starting value anyway
      mem_addr_pip       <= 64'b0;               // Set control signals to bulk memory to inactive values
      mem_din_pip        <= 512'b0;             
      mem_din_bdi_pip    <= 1'b0; 
      mem_wren_pip       <= 64'b0;
      mem_rden_pip       <= 1'b0;
      mem_rdcnt_pip      <= 2'b00;
    end
  else if (pip5_valid == 1'b1 && pip5_fail_resp == 1'b0)
  //   (1st cycle) If the cmd is valid and not failing, access the memory. (covers response + 1st data FLIT)
    begin
      // Capture values from upstream stage
      // Note: Use pip5 signals only on 1st cycle, then need to use pip6 since pip5 will be overlaid with new cmd or all 0s if stall cycle
//    pip6_cmd_opcode    <= pip5_cmd_opcode;
      pip6_cmd_capptag   <= pip5_cmd_capptag;
      pip6_cmd_pa        <= pip5_cmd_pa;
      pip6_cmd_dl        <= pip5_cmd_dl;
      pip6_cmd_pl        <= pip5_cmd_pl;
      pip6_cmd_be        <= pip5_cmd_be;
      pip6_pipe_type     <= pip5_pipe_type;
      pip6_resp_opcode   <= pip5_resp_opcode;
      pip6_resp_dl       <= pip5_resp_dl;
      pip6_resp_dp       <= pip5_resp_dp;
      pip6_resp_code     <= pip5_resp_code;
      // Manage valids
      pip6_cmd_valid     <= 1'b1;      // This is the 1st FLIT of the command
      pip6_valid         <= 1'b1;      // Initialize to 1. Hold at 1 while data FLITs are being accessed to enable downstream pipeline stages.
      // Initialize to pip5 values, which are valid on the first data FLIT only.
      pip6_sam_addr_out  <= pip5_sam_addr_out;
      pip6_flit_addr     <= pip5_flit_addr;          // This is address of 1st FLIT of the burst
      pip6_flit_cnt      <= pip5_flit_cnt;           // This is total number of FLITs in access
      pip6_local_cnt     <= 2'b00;                   // Initialize to 1st FLIT
      // Determine control signals to bulk memory
      mem_addr_pip       <= {pip5_cmd_pa[63:14], pip5_sam_addr_out, pip5_flit_addr};
      mem_din_pip        <= tlx_afu_cmd_data_bus;    // 1st FLIT data from TLX
      mem_din_bdi_pip    <= tlx_afu_cmd_data_bdi;    // 1st FLIT bdi from TLX 
      mem_wren_pip       <= pip5_cmd_be;             // Will be 0s on a read, so safe to set to passed down value
      mem_rden_pip       <= (pip5_pipe_type[PIPE_TYPE_RD_MEM] == 1'b1 || pip5_pipe_type[PIPE_TYPE_PR_RD_MEM]) ? 1'b1 : 1'b0; // 1 on read
      mem_rdcnt_pip      <= pip5_flit_cnt;           // Request all FLITs when the read command is presented
    end    
  else if (pip5_valid == 1'b1 && pip5_fail_resp == 1'b1)
  //   (1st cycle) If the cmd is valid and failing, suppress the write and read (no data). Continue to wait but only make 1st cycle valid. (resp w/o data)
    begin
      // Capture values from upstream stage.
//    pip6_cmd_opcode    <= pip5_cmd_opcode;
      pip6_cmd_capptag   <= pip5_cmd_capptag;
      pip6_cmd_pa        <= pip5_cmd_pa;
      pip6_cmd_dl        <= pip5_cmd_dl;
      pip6_cmd_pl        <= pip5_cmd_pl;
      pip6_cmd_be        <= pip5_cmd_be;
      pip6_pipe_type     <= pip5_pipe_type;
      pip6_resp_opcode   <= pip5_resp_opcode;
      pip6_resp_dl       <= pip5_resp_dl;
      pip6_resp_dp       <= pip5_resp_dp;
      pip6_resp_code     <= pip5_resp_code;
      // Manage valids
      pip6_cmd_valid     <= 1'b1;      // This is the 1st FLIT of the command
      pip6_valid         <= 1'b1;      // Set to 1 only for this cycle, as it will issue the response to TLX. 
      // Initialize to pip5 values, which are valid on the first data FLIT only.
      pip6_sam_addr_out  <= pip5_sam_addr_out;
      pip6_flit_addr     <= pip5_flit_addr;          // This is address of 1st FLIT of the burst
      pip6_flit_cnt      <= pip5_flit_cnt;           // This is total number of FLITs in access
      pip6_local_cnt     <= 2'b00;                   // Initialize to 1st FLIT
      // Determine control signals to bulk memory
      mem_addr_pip       <= 64'b0;                   // Set control signals to bulk memory to inactive values
      mem_din_pip        <= 512'b0;             
      mem_din_bdi_pip    <= 1'b0; 
      mem_wren_pip       <= 64'b0;                   // Suppress the write, if it was write_mem
      mem_rden_pip       <= 1'b0;                    // Suppress the read, if it was rd_mem
      mem_rdcnt_pip      <= 2'b00; 
    end
  else if (pip6_valid == 1'b1 && pip6_fail_resp == 1'b0 && pip6_local_cnt < pip6_flit_cnt) 
  // On cycle 2-4, use pip6 values.
  //   [If the cmd is not valid, shouldn't enter this state. (there should be no expansion of invalid command)]
  //   (cycle 2-4) If the cmd is valid and not failing, continue to access the memory. Increment addr & local count until it matches total FLITs (2-4 data)
    begin
      // Preserve pip6 values until all data FLITs have passed
//    pip6_cmd_opcode    <= pip6_cmd_opcode;
      pip6_cmd_capptag   <= pip6_cmd_capptag;
      pip6_cmd_pa        <= pip6_cmd_pa;
      pip6_cmd_dl        <= pip6_cmd_dl;
      pip6_cmd_pl        <= pip6_cmd_pl;
      pip6_cmd_be        <= pip6_cmd_be;
      pip6_pipe_type     <= pip6_pipe_type;
      pip6_resp_opcode   <= pip6_resp_opcode;
      pip6_resp_dl       <= pip6_resp_dl;
      pip6_resp_dp       <= pip6_resp_dp;
      pip6_resp_code     <= pip6_resp_code;
      // Manage valids
      pip6_cmd_valid     <= 1'b0;    // This is not the 1st FLIT of the command
      pip6_valid         <= 1'b1;    // Set to 1 for while FLITs are still being accessed to enable downstream pipeline stages.
      // Use pip6 values since pip5 ones are not valid after 1st cycle
      pip6_sam_addr_out  <= pip6_sam_addr_out;
      pip6_flit_addr     <= pip6_flit_addr + 2'b01;    // Increment
      pip6_flit_cnt      <= pip6_flit_cnt;
      pip6_local_cnt     <= pip6_local_cnt + 2'b01;    // Increment
      // Determine control signals to bulk memory
      mem_addr_pip       <= {pip6_cmd_pa[63:14], pip6_sam_addr_out, pip6_flit_addr + 2'b01};    // Increment
      mem_din_pip        <= tlx_afu_cmd_data_bus;      // Next FLIT data from TLX
      mem_din_bdi_pip    <= tlx_afu_cmd_data_bdi;      // Next FLIT bdi from TLX 
      mem_wren_pip       <= pip6_cmd_be;               // A few things to mention about 'be' source:
                                                       // a) Should only get here if cmd is multi-FLIT write_mem or rd_mem
                                                       // b) Should only get here if on cycles 2-4 of multi-FLIT write_mem or rd_mem
                                                       // c) If write_mem, 'be' should be all 1s on the 1st cycle so can reuse for rest of FLITs
                                                       // d) If rd_mem, 'be' should be all 0s
      mem_rden_pip       <= 1'b0;                      // If rd_mem, all FLITs were requested in the first cycle, so just wait
      mem_rdcnt_pip      <= 2'b00;
    end
  else if (pip6_valid == 1'b1 && pip6_fail_resp == 1'b1 && pip6_local_cnt < pip6_flit_cnt)
  //   (cycle 2-4) If the cmd is valid and failing, suppress the write and read (no data). Continue to wait until local count = total FLITs (no data on bad resp)
    begin
      // Preserve pip6 values until all data FLITs have passed
//    pip6_cmd_opcode    <= pip6_cmd_opcode;
      pip6_cmd_capptag   <= pip6_cmd_capptag;
      pip6_cmd_pa        <= pip6_cmd_pa;
      pip6_cmd_dl        <= pip6_cmd_dl;
      pip6_cmd_pl        <= pip6_cmd_pl;
      pip6_cmd_be        <= pip6_cmd_be;
      pip6_pipe_type     <= pip6_pipe_type;
      pip6_resp_opcode   <= pip6_resp_opcode;
      pip6_resp_dl       <= pip6_resp_dl;
      pip6_resp_dp       <= pip6_resp_dp;
      pip6_resp_code     <= pip6_resp_code;
      // Manage valids
      pip6_cmd_valid     <= 1'b0;    // This is not the 1st FLIT of the command
      pip6_valid         <= 1'b0;    // Set to non-valid cycle in downstream stages, since at this point cycles are just a place holder to use up reserved FLIT cycles
      // Use pip6 values since pip5 ones are not valid after 1st cycle
      pip6_sam_addr_out  <= pip6_sam_addr_out;
      pip6_flit_addr     <= pip6_flit_addr + 2'b01;    // Increment
      pip6_flit_cnt      <= pip6_flit_cnt;
      pip6_local_cnt     <= pip6_local_cnt + 2'b01;    // Increment
      // Determine control signals to bulk memory
      mem_addr_pip       <= 64'b0;                     // Set control signals to bulk memory to inactive values
      mem_din_pip        <= 512'b0;             
      mem_din_bdi_pip    <= 1'b0; 
      mem_wren_pip       <= 64'b0;                     // Suppress the write, if it was write_mem
      mem_rden_pip       <= 1'b0;                      // Suppress the read, if it was rd_mem
      mem_rdcnt_pip      <= 2'b00; 
    end
  else // if (pip6_valid == 1'b1 && pip6_local_cnt >= pip6_flit_cnt) 
  // Will get here on the cycle after the last data FLIT, if there was not another command immediately following (pip5_valid = 0).
  // If there was another command immediately following, pip5_valid would be 1 and an earlier branch would be taken.
  // In this state, we want to gracefully 'reset' the pip6 registers to a non-active state.
    begin
      // Set pip6 values back to non-active state so downstream stages don't see a command
//    pip6_cmd_opcode    <= 8'b0;
      pip6_cmd_capptag   <= 16'b0;
      pip6_cmd_pa        <= 64'b0;
      pip6_cmd_dl        <= 2'b0;
      pip6_cmd_pl        <= 3'b0;
      pip6_cmd_be        <= 64'b0;
      pip6_pipe_type     <= 5'b0;           
      pip6_resp_opcode   <= 8'b0;
      pip6_resp_dl       <= 2'b0;
      pip6_resp_dp       <= 2'b0;
      pip6_resp_code     <= 4'b0;
      pip6_cmd_valid     <= 1'b0;                      // This is not the 1st FLIT of the command
      pip6_valid         <= 1'b0;                      // 'valid' must be set to 0 to get us back to the first branch (pip5_valid=0,pip6_valid=0)
      pip6_sam_addr_out  <= 12'b0;
      pip6_flit_addr     <= 2'b0;
      pip6_flit_cnt      <= 2'b0;                      
      pip6_local_cnt     <= 2'b0;                      
      mem_addr_pip       <= 64'b0;                     // Set control signals to bulk memory to inactive values
      mem_din_pip        <= 512'b0;             
      mem_din_bdi_pip    <= 1'b0; 
      mem_wren_pip       <= 64'b0;                     // Suppress the write, if it was write_mem
      mem_rden_pip       <= 1'b0;                      // Suppress the read, if it was rd_mem
      mem_rdcnt_pip      <= 2'b00; 
    end


// PIP7: Wait for Memory Access - 1st cycle
//
// Nothing to do, bulk memory is capturing the control signals from the last cycle.
//
//g   [7:0]  pip7_cmd_opcode;   // Currently not used
reg  [15:0]  pip7_cmd_capptag;
reg  [63:0]  pip7_cmd_pa;
reg   [1:0]  pip7_cmd_dl;
reg   [2:0]  pip7_cmd_pl;
//g  [63:0]  pip7_cmd_be;       // Currently not used
reg   [4:0]  pip7_pipe_type;
reg   [1:0]  pip7_flit_cnt;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          pip7_cmd_valid;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          pip7_valid;
reg   [7:0]  pip7_resp_opcode;
reg   [1:0]  pip7_resp_dl;
reg   [1:0]  pip7_resp_dp;
reg   [3:0]  pip7_resp_code;
always @(posedge(clock))     
  begin
//  pip7_cmd_opcode  <= pip6_cmd_opcode;   
    pip7_cmd_capptag <= pip6_cmd_capptag; 
    pip7_cmd_pa      <= pip6_cmd_pa;
    pip7_cmd_dl      <= pip6_cmd_dl;
    pip7_cmd_pl      <= pip6_cmd_pl;
//  pip7_cmd_be      <= pip6_cmd_be;
    pip7_pipe_type   <= pip6_pipe_type;
    pip7_flit_cnt    <= pip6_flit_cnt;
    pip7_cmd_valid   <= pip6_cmd_valid;
    pip7_valid       <= pip6_valid;        // Propagate valid
    pip7_resp_opcode <= pip6_resp_opcode;  // Will need response information in a few cycles
    pip7_resp_dl     <= pip6_resp_dl;
    pip7_resp_dp     <= pip6_resp_dp;
    pip7_resp_code   <= pip6_resp_code;
  end


// PIP8: Wait for Memory Access - 2nd cycle
//
// Nothing to do, bulk memory is writing or reading the memory in this cycle.
//
//g   [7:0]  pip8_cmd_opcode;    // Currently not used
reg  [15:0]  pip8_cmd_capptag;
reg  [63:0]  pip8_cmd_pa;
reg   [1:0]  pip8_cmd_dl;
reg   [2:0]  pip8_cmd_pl;
//g  [63:0]  pip8_cmd_be;       // Currently not used
reg   [4:0]  pip8_pipe_type;
reg   [1:0]  pip8_flit_cnt;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          pip8_cmd_valid;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          pip8_valid;
reg   [7:0]  pip8_resp_opcode;
reg   [1:0]  pip8_resp_dl;
reg   [1:0]  pip8_resp_dp;
reg   [3:0]  pip8_resp_code;
always @(posedge(clock))     
  begin
//  pip8_cmd_opcode  <= pip7_cmd_opcode;   
    pip8_cmd_capptag <= pip7_cmd_capptag; 
    pip8_cmd_pa      <= pip7_cmd_pa;
    pip8_cmd_dl      <= pip7_cmd_dl;
    pip8_cmd_pl      <= pip7_cmd_pl;
//  pip8_cmd_be      <= pip7_cmd_be;
    pip8_pipe_type   <= pip7_pipe_type;
    pip8_flit_cnt    <= pip7_flit_cnt;
    pip8_cmd_valid   <= pip7_cmd_valid;
    pip8_valid       <= pip7_valid;        // Propagate valid
    pip8_resp_opcode <= pip7_resp_opcode;  // Will need response information in a few cycles
    pip8_resp_dl     <= pip7_resp_dl;
    pip8_resp_dp     <= pip7_resp_dp;
    pip8_resp_code   <= pip7_resp_code;
  end


// PIP9: Wait for Memory Access - 3rd cycle
//
// Nothing to do, bulk memory is writing or reading the memory in this cycle.
//
//g   [7:0]  pip9_cmd_opcode;    // Currently not used
reg  [15:0]  pip9_cmd_capptag;
reg  [63:0]  pip9_cmd_pa;
reg   [1:0]  pip9_cmd_dl;
reg   [2:0]  pip9_cmd_pl;
//g  [63:0]  pip9_cmd_be;       // Currently not used
reg   [4:0]  pip9_pipe_type;
reg   [1:0]  pip9_flit_cnt;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          pip9_cmd_valid;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          pip9_valid;
reg   [7:0]  pip9_resp_opcode;
reg   [1:0]  pip9_resp_dl;
reg   [1:0]  pip9_resp_dp;
reg   [3:0]  pip9_resp_code;
always @(posedge(clock))     
  begin
//  pip9_cmd_opcode  <= pip8_cmd_opcode;   
    pip9_cmd_capptag <= pip8_cmd_capptag; 
    pip9_cmd_pa      <= pip8_cmd_pa;
    pip9_cmd_dl      <= pip8_cmd_dl;
    pip9_cmd_pl      <= pip8_cmd_pl;
//  pip9_cmd_be      <= pip8_cmd_be;
    pip9_pipe_type   <= pip8_pipe_type;
    pip9_flit_cnt    <= pip8_flit_cnt;
    pip9_cmd_valid   <= pip8_cmd_valid;
    pip9_valid       <= pip8_valid;        // Propagate valid
    pip9_resp_opcode <= pip8_resp_opcode;  // Will need response information in a few cycles
    pip9_resp_dl     <= pip8_resp_dl;
    pip9_resp_dp     <= pip8_resp_dp;
    pip9_resp_code   <= pip8_resp_code;
  end


// PIPA: Send response and 1-4 FLITs on read
//
// If this is the first cycle of the response, issue the response back to the TLX. This happens on read or write, success or failure.
// Next present data. If this is a read, data should be appearing at the bulk memory output registers on this cycle.
// - If this command is a write, then there is no response data. Pipeline is complete.
// - If this command is a read, the response code is 'success', and it's the first cycle, present the 1st FLIT of data.
// - If this command is a read, the response code is 'success', and it's cycle 2-4, present the remaining FLITs of data.
// If the response is a failure (for read or write), log it in the error array so an interrupt will be generated.
//g   [7:0]  pipA_cmd_opcode;   // Currently not used
//g  [15:0]  pipA_cmd_capptag;  // Currently not used
//g  [63:0]  pipA_cmd_pa;       // Currently not used
//g   [1:0]  pipA_cmd_dl;       // Currently not used
//g   [2:0]  pipA_cmd_pl;       // Currently not used
//g  [63:0]  pipA_cmd_be;       // Currently not used
reg   [4:0]  pipA_pipe_type;
reg   [1:0]  pipA_flit_cnt;
//g          pipA_cmd_valid;    // Currently not used
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg          pipA_valid;
reg   [7:0]  pipA_resp_opcode;
reg   [1:0]  pipA_flits_sent;   // NOTE: Compare flits_sent against flit_cnt to know how many to send (if not a failure)
// Response FIFO inputs
reg    [7:0] rff_in_resp_opcode;
reg    [3:0] rff_in_resp_code;
reg    [1:0] rff_in_resp_dl;
reg    [1:0] rff_in_resp_dp;
reg   [15:0] rff_in_resp_capptag;
reg          rff_in_resp_valid;
reg  [511:0] rff_in_rdata;
reg          rff_in_bdi;
reg          rff_in_rdata_valid;
reg    [1:0] rff_in_num_flits;
// Helper signals
// 'fail_resp' = 1 when the response code is mem_wr_fail or mem_rd_fail. Make 2 copies because pip5 is only good on the first cycle.
wire pip9_fail_resp;
wire pipA_fail_resp;
assign pip9_fail_resp = (pip9_resp_opcode == 8'h05 || pip9_resp_opcode == 8'h02) ? 1'b1 : 1'b0;
assign pipA_fail_resp = (pipA_resp_opcode == 8'h05 || pipA_resp_opcode == 8'h02) ? 1'b1 : 1'b0;
always @(posedge(clock))     
  begin
    // Preserve information
//  pipA_cmd_opcode   <= pip9_cmd_opcode;
//  pipA_cmd_capptag  <= pip9_cmd_capptag;
//  pipA_cmd_pa       <= pip9_cmd_pa;
//  pipA_cmd_dl       <= pip9_cmd_dl;
//  pipA_cmd_pl       <= pip9_cmd_pl;
//  pipA_cmd_be       <= pip9_cmd_be;
    pipA_pipe_type    <= pip9_pipe_type;
    pipA_flit_cnt     <= pip9_flit_cnt;
//  pipA_cmd_valid    <= pip9_cmd_valid;
    pipA_valid        <= pip9_valid;
    pipA_resp_opcode  <= pip9_resp_opcode;
    rff_in_num_flits  <= pip9_flit_cnt; 
    // Present response (pass or fail) since it must go back to the TLX on read or write
    if (pip9_cmd_valid == 1'b1)     // First cycle of command
      begin 
        rff_in_resp_opcode  <= pip9_resp_opcode;    // Put response into response FIFO  
        rff_in_resp_dl      <= pip9_resp_dl;       
        rff_in_resp_dp      <= pip9_resp_dp;       
        rff_in_resp_capptag <= pip9_cmd_capptag;        
        rff_in_resp_code    <= pip9_resp_code;   
        rff_in_resp_valid   <= 1'b1;                // Present response to TLX
        rff_in_num_flits    <= pip9_flit_cnt; 
      end
    else 
      begin
        rff_in_resp_opcode  <= 8'b0;                // Clear OR inputs when it is not the 1st FLIT of the command    
        rff_in_resp_dl      <= 2'b0;      
        rff_in_resp_dp      <= 2'b0;       
        rff_in_resp_capptag <= 16'b0; 
        rff_in_resp_code    <= 4'b0; 
        rff_in_resp_valid   <= 1'b0;                // Mark response not valid
        rff_in_num_flits    <= pip9_flit_cnt;
      end
    // If this command is a write, then there is no response data. Pipeline is complete.
    // If this command is a read, the response code is 'success', and it's the first cycle, present the 1st FLIT of data.
    if (pip9_cmd_valid == 1'b1 && pip9_fail_resp == 1'b0 && (pip9_pipe_type[PIPE_TYPE_RD_MEM] == 1'b1 || pip9_pipe_type[PIPE_TYPE_PR_RD_MEM]) )
      begin                                             // Present 1st data FLIT
        rff_in_rdata        <= mem_dout;
        rff_in_bdi          <= mem_dout_bdi;
        rff_in_rdata_valid  <= 1'b1; 
        pipA_flits_sent     <= 2'b00; 
      end
    // If this command is a read, the response code is 'success', and it's cycle 2-4, present the remaining FLITs of data.
    else if (pipA_valid == 1'b1 && pipA_fail_resp == 1'b0 && (pipA_pipe_type[PIPE_TYPE_RD_MEM] == 1'b1 || pipA_pipe_type[PIPE_TYPE_PR_RD_MEM]) )
      begin
        if (pipA_flits_sent < pipA_flit_cnt)
          begin                                         // Present next data FLIT(s)
           rff_in_rdata        <= mem_dout;
           rff_in_bdi          <= mem_dout_bdi;
           rff_in_rdata_valid  <= 1'b1; 
           pipA_flits_sent     <= pipA_flits_sent + 2'b01;
          end 
        else  // (pipA_flits_sent == pipA_flit_cnt)
          begin                                         // All FLITs sent, return interface to 0s so other states can OR onto it
           rff_in_rdata        <= 512'b0;
           rff_in_bdi          <= 1'b0;
           rff_in_rdata_valid  <= 1'b0; 
           pipA_flits_sent     <= 2'b00;
         end 
      end
    // Command is not valid, is a write, is a read with failing response code
    else 
      begin                                             // Set interface to 0s so other states can OR onto it
        rff_in_rdata        <= 512'b0;
        rff_in_bdi          <= 1'b0;
        rff_in_rdata_valid  <= 1'b0; 
        pipA_flits_sent     <= 2'b00;
      end 
    // Log an error (and raise an interrupt) if the response was 'fail'
    if (pip9_cmd_valid == 1'b1 && (pip9_resp_opcode == 8'h05 || pip9_resp_opcode == 8'h02)) // Only check when response is returned
      begin
        ery_loadsrc[8]     <= 1'b1;
        ery_src08[127:112] <= 16'h0100;
        ery_src08[111:108] <= pip9_resp_code;
        ery_src08[    107] <= 1'b0;                  // No BDI
        ery_src08[106: 93] <= 14'b0;                 // Reserved         
        ery_src08[ 92: 88] <= pip9_pipe_type;
        ery_src08[     87] <= 1'b0;                  // No T bit
        ery_src08[ 86: 84] <= pip9_cmd_pl;
        ery_src08[ 83: 82] <= 2'b0;
        ery_src08[ 81: 80] <= pip9_cmd_dl;
        ery_src08[ 79: 64] <= pip9_cmd_capptag;
        ery_src08[ 63:  0] <= pip9_cmd_pa;
      end
    else
      begin
        ery_loadsrc[8]     <= 1'b0;
        ery_src08[127:0]   <= 128'b0;
      end
  end


// ==============================================================================================================================
// @@@ RFF: Response FiFo for pipelined operations
// ==============================================================================================================================
wire [549:0] rff_resp_in, rff_resp_out;

wire   [7:0] rff_out_resp_opcode;
wire   [3:0] rff_out_resp_code;
wire   [1:0] rff_out_resp_dl;
wire   [1:0] rff_out_resp_dp;
wire  [15:0] rff_out_resp_capptag;
wire         rff_out_resp_valid;
wire [511:0] rff_out_rdata;
wire         rff_out_bdi;
wire         rff_out_rdata_valid;
wire   [1:0] rff_out_num_flits;
wire         rff_out_pad;

assign rff_resp_in = {
    rff_in_resp_valid 
  , rff_in_rdata_valid
  , rff_in_resp_opcode
  , rff_in_resp_code
  , rff_in_resp_dl
  , rff_in_resp_dp
  , rff_in_resp_capptag
  , rff_in_bdi
  , 1'b0                        // Add pad bit to make simulation output easier to read
  , rff_in_num_flits
  , rff_in_rdata 
};

assign {
    rff_out_resp_valid 
  , rff_out_rdata_valid
  , rff_out_resp_opcode
  , rff_out_resp_code
  , rff_out_resp_dl
  , rff_out_resp_dp
  , rff_out_resp_capptag
  , rff_out_bdi
  , rff_out_pad                 // Pad bit to make simulation output easier to read
  , rff_out_num_flits
  , rff_out_rdata 
  } = rff_resp_out;

wire   rff_resp_in_valid;
assign rff_resp_in_valid = rff_in_resp_valid | rff_in_rdata_valid;   // Load RESP without RDATA, RESP with RDATA, or RDATA in continuation of RESP
wire rff_fifo_overflow;  
wire [4:0] rff_buffers_available;   // For information only, rffcr_buffers_available is used to determine space available 
wire rff_resp_valid;

lpc_respfifo #(.WIDTH(550)) RFF  (                      // Set WIDTH to combined number of response & response data signals that are used
    .clock                  ( clock                 )   // Clock - samples & launches data on rising edge
  , .reset                  ( reset                 )   // Reset - when 1 set control logic to default state
  , .resp_in                ( rff_resp_in           )   // Vector of response signals
  , .resp_in_valid          ( rff_resp_in_valid     )   // When 1, load 'resp_in' into the FIFO
  , .resp_buffers_available ( rff_buffers_available )   // When >0, there is space in the FIFO for another command
  , .resp_sent              ( rff_resp_sent         )   // When 1, increment read FIFO pointer to present the next FIFO entry
  , .resp_out               ( rff_resp_out          )   // Response information at head of FIFO
  , .resp_out_valid         ( rff_resp_valid        )   // When 1, 'resp_out' contains valid information
  , .fifo_overflow          ( rff_fifo_overflow     )   // When 1, FIFO was full when another 'resp_valid' arrived
) ;

// As response and response data credits become available, flow queued information out to TLX.
// The assumption is the response at the head of the FIFO will be one of these formats:
// 1) Response only, no data                      (resp_valid = 1, rdata_valid = 0)
// 2) Response with 1 FLIT of data                (resp_valid = 1, rdata_valid = 1)
// 3) Continuing FLITs of a response in progress  (resp_valid = 0, rdata_valid = 1)
// 4) No response to send                         (resp_valid = 0, rdata_valid = 0)
wire [2:0] rff_converted_num_flits;   
assign rff_converted_num_flits = {1'b0,rff_out_num_flits} + 3'b001;  // num_flits = 00 to 11, so add 1 before compare 
always @(*)  
  if (rff_resp_valid     == 1'b1                  &&  // If the array hasn't been written yet, individual valids may be X so qualify with solid signal
      rff_out_resp_valid == 1'b1                  &&  // A response (with or without data) is waiting to be sent, and
      tarc_credits_available  >= 4'b0001          &&  // There is at least 1 response credit, and
      (rff_out_rdata_valid == 1'b0 ||                                // There is no data with this response
       tardc_credits_available >= {3'b000,rff_converted_num_flits} ) // OR there are enough data credits for the entire response
     )
    begin    
      afu_tlx_resp_opcode_pip  = rff_out_resp_opcode;      // Send Response                
      afu_tlx_resp_dl_pip      = rff_out_resp_dl;      
      afu_tlx_resp_dp_pip      = rff_out_resp_dp;       
      afu_tlx_resp_capptag_pip = rff_out_resp_capptag; 
      afu_tlx_resp_code_pip    = rff_out_resp_code; 
      afu_tlx_resp_valid_pip   = rff_out_resp_valid;                
      tarc_consume_credit_opd  = 4'b001;                   // Consume a response credit
      if (rff_out_rdata_valid == 1'b1)
        begin
          afu_tlx_rdata_bus_pip    = rff_out_rdata;        // Send Response Data 
          afu_tlx_rdata_bdi_pip    = rff_out_bdi;                            
          afu_tlx_rdata_valid_pip  = rff_out_rdata_valid;  
          tardc_consume_credit_opd = 6'b00001;             // Consume a response data credit for this data FLIT
        end
      else
        begin
          afu_tlx_rdata_bus_pip    = 512'b0;               // No Response Data 
          afu_tlx_rdata_bdi_pip    = 1'b0;                            
          afu_tlx_rdata_valid_pip  = 1'b0;  
          tardc_consume_credit_opd = 6'b00000;             
        end
      rff_resp_sent            = 1'b1;                     // Advance the FIFO
    end
  else if (rff_resp_valid     == 1'b1             &&  // If the array hasn't been written yet, individual valids may be X so qualify with solid signal
           rff_out_resp_valid == 1'b0             &&  // There is no response waiting, 
           rff_out_rdata_valid == 1'b1            )   // But this is a continuation of a response that has been started
    begin
      afu_tlx_resp_opcode_pip  = 8'b0;                // No Response (OR inputs must be 0)                
      afu_tlx_resp_dl_pip      = 2'b0;      
      afu_tlx_resp_dp_pip      = 2'b0;       
      afu_tlx_resp_capptag_pip = 16'b0; 
      afu_tlx_resp_code_pip    = 4'b0; 
      afu_tlx_resp_valid_pip   = 1'b0;                
      tarc_consume_credit_opd  = 4'b000;              // Do not consume a response credit
      afu_tlx_rdata_bus_pip    = rff_out_rdata;       // Send Response Data 
      afu_tlx_rdata_bdi_pip    = rff_out_bdi;
      afu_tlx_rdata_valid_pip  = rff_out_rdata_valid;
      tardc_consume_credit_opd = 6'b00001;            // Consume a response data credit for this data FLIT
      rff_resp_sent            = 1'b1;                // Advance the FIFO
    end
  else                                                // RFF output is not valid, no resp is pending, or there are not enough credits from TLX to send it
    begin
      afu_tlx_resp_opcode_pip  = 8'b0;                // No Response (OR inputs must be 0)                
      afu_tlx_resp_dl_pip      = 2'b0;      
      afu_tlx_resp_dp_pip      = 2'b0;       
      afu_tlx_resp_capptag_pip = 16'b0; 
      afu_tlx_resp_code_pip    = 4'b0; 
      afu_tlx_resp_valid_pip   = 1'b0;                
      tarc_consume_credit_opd  = 4'b0;                // Do not consume a response credit
      afu_tlx_rdata_bus_pip    = 512'b0;              // No Response Data 
      afu_tlx_rdata_bdi_pip    = 1'b0;
      afu_tlx_rdata_valid_pip  = 1'b0; 
      tardc_consume_credit_opd = 6'b0;                // Do not consume a response data credit
      rff_resp_sent            = 1'b0;                // Hold the FIFO
    end        



// Indicate when the pipeline is completely empty
assign pipe_is_empty = ~(pip1_valid | pip2_valid | pip3_valid | pip4_valid | pip5_valid | 
                         pip6_valid | pip7_valid | pip8_valid | pip9_valid | pipA_valid |
                         rff_resp_valid
                        );


// ==============================================================================================================================
// @@@ BDF: Bus / Device Function
// ==============================================================================================================================

assign afu_tlx_cmd_bdf_int = {cfg_afu_bdf_bus, cfg_afu_bdf_device, cfg_afu_bdf_function};   // Internal use version of BDF


// ==============================================================================================================================
// @@@ MMW: Command State Machine - MMIO Write (pr_wr_mem to MMIO BAR space)
// ==============================================================================================================================

// 1) Select the correct 8B of data to send to MMIO registers from the 64B flit

// To improve timing closure, select the data all the time and let the MMIO write state machine determine when to pass it to the MMIO regs.
// In a testbench, byte alignment can be done simplier using the shift operator, i.e. data << ({addr[5:3],3'b000}*8)
// But since this will be synthesized into hardware, use an explicit MUX structure. It is more verbose, but may synthesize & place better.
// The intent here is to extract the proper 8 Bytes, address bits [2:0] come into play within the MMIO regs to select the correct byte field(s).
reg  [63:0] mmw_data_to_mmio_regs;
always @(*)  // Combinational logic
  case ( cff_cmd_pa[5:3] )        
    3'b000:  mmw_data_to_mmio_regs = tlx_afu_cmd_data_bus[ 63:  0];
    3'b001:  mmw_data_to_mmio_regs = tlx_afu_cmd_data_bus[127: 64];
    3'b010:  mmw_data_to_mmio_regs = tlx_afu_cmd_data_bus[191:128];
    3'b011:  mmw_data_to_mmio_regs = tlx_afu_cmd_data_bus[255:192];
    3'b100:  mmw_data_to_mmio_regs = tlx_afu_cmd_data_bus[319:256];
    3'b101:  mmw_data_to_mmio_regs = tlx_afu_cmd_data_bus[383:320];
    3'b110:  mmw_data_to_mmio_regs = tlx_afu_cmd_data_bus[447:384];
    3'b111:  mmw_data_to_mmio_regs = tlx_afu_cmd_data_bus[511:448];
    default: mmw_data_to_mmio_regs = 64'hBADDBADD_BADDBADD;    // Short for 'BAD Data, BAD Data'
  endcase 

// 2) State Machine for MMio Write (MMW)

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg [2:0]  SM_MMW;                
parameter  SM_MMW_IDLE              = 3'b000;
parameter  SM_MMW_WAIT_FOR_DATA     = 3'b001;
parameter  SM_MMW_WAIT_FOR_MREG1    = 3'b010;
parameter  SM_MMW_WAIT_FOR_MREG2    = 3'b011;
parameter  SM_MMW_WAIT_FOR_MREG3    = 3'b100;
parameter  SM_MMW_WAIT_FOR_RESP_CR  = 3'b101;   // Wait for Response Credits to be available
parameter  SM_MMW_WAIT_FOR_NEXT_CMD = 3'b110;
parameter  SM_MMW_ERROR             = 3'b111;   

// Behavior to perform in each state

// IDLE: In this state, we're just waiting for a MMIO write (pr_wr_mem) command to appear from the TLX. 
//       When it does, request the write data from the TLX, which in this case will be a single 64B flit.
//       Note: For synthesis purposes, break this into a combinational and clocked section.
//
always @(*)    // Combinational
  if (SM_MMW == SM_MMW_IDLE)  // Note: This qualifying condition is redundant until the LPC starts handling pipelined commands.
                              //       But use it as a precaution to prevent a second command from being started if one is being processed.
    begin                             
      if (start_mmio_write == 1'b1)                 // Request data in the same cycle as seeing cmd_valid to improve performance.
        begin
          afu_tlx_cmd_rd_req_mmw = 1'b1;           // Request single flit from TLX
          afu_tlx_cmd_rd_cnt_mmw = 3'b001;    
        end
      else                                          
        begin                                       // Execute this code block when in IDLE but no MMIO write command is going on 
          afu_tlx_cmd_rd_req_mmw = 1'b0;           // Always set to 0 when not in use to not influence OR gate driving to TLX
          afu_tlx_cmd_rd_cnt_mmw = 3'b000;     
        end
    end
  else                                              // In the middle of a MMIO write, but not in the IDLE state
    begin
      afu_tlx_cmd_rd_req_mmw = 1'b0;               // Set to 0 to not request any more data from TLX
      afu_tlx_cmd_rd_cnt_mmw = 3'b000;    
    end
// Above is equivalent to:
// assign afu_tlx_cmd_rd_req_mmw = (SM_MMW == SM_MMW_IDLE && start_mmio_write == 1'b1) ? 1'b1   : 1'b0  ;  // Request flit from TLX
// assign afu_tlx_cmd_rd_cnt_mmw = (SM_MMW == SM_MMW_IDLE && start_mmio_write == 1'b1) ? 3'b001 : 3'b000;  // Only 1 flit requested
//
reg   [2:0] mmw_pl;    
reg  [15:0] mmw_capptag;
reg  [63:0] mmw_addr; 
always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  if (SM_MMW == SM_MMW_IDLE) 
    begin
      mmw_pl                 <= cff_cmd_pl;           // Latch copies for use later 
      mmw_capptag            <= cff_cmd_capptag;  
      mmw_addr               <= cff_cmd_pa;
    end
  else
    begin
      mmw_pl                 <= mmw_pl;               // Hold values so state machines below can use contents
      mmw_capptag            <= mmw_capptag;
      mmw_addr               <= mmw_addr;
    end


// WAIT_FOR_DATA: In this state, we're waiting for the TLX to present data. 
//                When it does, send the selected 8 Bytes to the MMIO regs, along with a write strobe of the correct size.
reg  mmw_data_bdi;
always @(posedge(clock))  
  if (SM_MMW == SM_MMW_WAIT_FOR_DATA)
    begin
      if (tlx_afu_cmd_data_valid == 1'b1)
        begin
          mmw_data_bdi     <= tlx_afu_cmd_data_bdi;  // Save Bad Data Indicator
          mmio_addr_mmw    <= mmw_addr[19:0];        // Send address, write strobe, and write data to MMIO regs
          mmio_wdata       <= mmw_data_to_mmio_regs;
          if (tlx_afu_cmd_data_bdi == 1'b0 && mmw_pl == 3'b000) mmio_wr_1B <= 1'b1; else mmio_wr_1B <= 1'b0;
          if (tlx_afu_cmd_data_bdi == 1'b0 && mmw_pl == 3'b001) mmio_wr_2B <= 1'b1; else mmio_wr_2B <= 1'b0;
          if (tlx_afu_cmd_data_bdi == 1'b0 && mmw_pl == 3'b010) mmio_wr_4B <= 1'b1; else mmio_wr_4B <= 1'b0;
          if (tlx_afu_cmd_data_bdi == 1'b0 && mmw_pl == 3'b011) mmio_wr_8B <= 1'b1; else mmio_wr_8B <= 1'b0;
          // if (mmw_pl <> 1,2,4,8), then no write strobe will be issued to MMIO regs. The check on legal pL is done in response generation.
        end
      else
        begin
          mmw_data_bdi  <= mmw_data_bdi;   // Keep for use in generating response
          mmio_addr_mmw <= 20'b0;   // To prevent unnecessary register switching in MMIO regs, tie write inputs to 0 while not in use
          mmio_wdata    <= 64'b0;  
          mmio_wr_1B    <= 1'b0;    // Set write controls inactive when not in use
          mmio_wr_2B    <= 1'b0;
          mmio_wr_4B    <= 1'b0;
          mmio_wr_8B    <= 1'b0;
        end
    end
  else
    begin
      mmw_data_bdi     <= mmw_data_bdi;
      mmio_addr_mmw    <= 20'b0;   // To prevent unnecessary register switching in ACS, tie write inputs to 0 while not in use
      mmio_wdata       <= 64'b0;
      mmio_wr_1B       <= 1'b0;    // Set write controls inactive when not in use
      mmio_wr_2B       <= 1'b0;
      mmio_wr_4B       <= 1'b0;
      mmio_wr_8B       <= 1'b0;
    end


// WAIT_FOR_MREG1: The MMIO regs take 2 cycles to process the write. This state absorbs the first cycle.
//                 From a behavior standpoint, there is nothing to do. 

// WAIT_FOR_MREG2: The MMIO regs take 2 cycles to process the write. This state absorbs the first cycle.
//                 From a behavior standpoint, there is nothing to do. 

// WAIT_FOR_MREG3: In this state, look for an error indicator from the MMIO regs. 
//                 In a high performance application where latency on MMIO operations is critical,
//                 it may be possible (timing closure permitting) to determine and present the response
//                 in the same cycle that the error indicator is present. In this case:
//                   If at least 1 response credit is available:
//                   - Present one of two responses to the TLX using resp_valid. 
//                   --- If no error is present, issue mem_wr_response
//                   --- If    error is present, issue mem_wr_fail
//                   - Issue command credit to the TLX in order to receive the next command. 
//                   - Operation is complete, jump to IDLE.
//                   If no response credits are available:
//                   - Enter state that waits for response credits.
//                   - Save the response from the MMIO regs so the wait state can use it later to determine the response type.
//                 However implemention of this could be messy. For this design which intends to be a reference
//                 model so should be as understandable as possible, and does not have critical latency requirements
//                 on MMIO operations, it was decided to spend another cycle and always use another state
//                 to manage the presence or absense of response credits. In this case:
//                   - Prepare one of two responses to the TLX. 
//                   --- If no error is present, prepare mem_wr_response
//                   --- If    error is present, prepare mem_wr_fail
//                   - Jump to WAIT_FOR_RESP_CR.
//                 The next state will check for the presense of response credits and wait for one if none are available.
//                 It will also issue the command credit before ending the operation and returning to IDLE.

// Helper signal: set mmw_legal_size to 1 if requested operation was 1, 2, 4, or 8 Bytes in size
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   mmw_legal_size;
assign mmw_legal_size = (mmw_pl == 3'b000 || mmw_pl == 3'b001 || mmw_pl == 3'b010 || mmw_pl == 3'b011) ? 1'b1 : 1'b0;

reg  [7:0] mmw_resp_opcode;
reg  [1:0] mmw_resp_dl;
reg  [1:0] mmw_resp_dp;
reg  [3:0] mmw_resp_code;
always @(posedge(clock))  
  if (SM_MMW == SM_MMW_WAIT_FOR_MREG3)
    begin
      if (mmw_data_bdi == 1'b1 || mmio_addr_not_implemented == 1'b1 || mmw_legal_size == 1'b0 || mmio_bad_op_or_align == 1'b1)
        begin
          mmw_resp_opcode  <= 8'h05;     // mem_wr_fail
          mmw_resp_dl      <= 2'b01;     // dL doesn't exist in command, set to 1 FLIT
          mmw_resp_dp      <= 2'b00;     // All FLITs covered by response, so start at 0
          if (mmw_data_bdi == 1'b1)
            begin
              mmw_resp_code      <= 4'h8;      // Data received was marked bad
              ery_src02[111:108] <= 4'h8;
            end
          else if (mmio_addr_not_implemented == 1'b1)
            begin
              mmw_resp_code      <= 4'hE;      // Access to un-implemented address in BAR range, use general fail code
              ery_src02[111:108] <= 4'hE;
            end
          else if (mmw_legal_size == 1'b0)
            begin
              mmw_resp_code      <= 4'h9;      // Length is not legal, report unsupported size error
              ery_src02[111:108] <= 4'h9;
            end
          else
            begin
              mmw_resp_code      <= 4'hB;      // Length was legal, so must be address alignment error
              ery_src02[111:108] <= 4'hB;
            end
          // Save error information which triggers interrupt
          ery_loadsrc[2]     <= 1'b1;          // source 2 = config_read state machine
          ery_src02[127:112] <= 16'h0004;      // source 2 = config_read state machine
          ery_src02[    107] <= mmw_data_bdi;
          ery_src02[106: 87] <= 20'b0;
          ery_src02[ 86: 84] <= mmw_pl;
          ery_src02[ 83: 82] <= 2'b0;
          ery_src02[ 81: 80] <= 2'b01;         // dL doesn't exist in command, set to 1 FLIT
          ery_src02[ 79: 64] <= mmw_capptag;
          ery_src02[ 63:  0] <= mmw_addr;
        end
      else                               // Operation was a success
        begin
          mmw_resp_opcode  <= 8'h04;     // mem_wr_response
          mmw_resp_dl      <= 2'b01;     // dL doesn't exist in command, set to 1 FLIT
          mmw_resp_dp      <= 2'b00;     // All FLITs covered by response, so start at 0
          mmw_resp_code    <= 4'h0;      // Not used with mem_wr_response
          ery_loadsrc[2]   <= 1'b0;      // No error information saved
          ery_src02        <= 128'b0;
        end
    end  
  else
    begin
       mmw_resp_opcode  <= mmw_resp_opcode;   // Hold values so state machines below can use contents
       mmw_resp_dl      <= mmw_resp_dl;      
       mmw_resp_dp      <= mmw_resp_dp;       
       mmw_resp_code    <= mmw_resp_code;       
       ery_loadsrc[2]   <= 1'b0;              // If error load was set by this state, clear the strobe when leave it
       ery_src02        <= 128'b0;
    end


//WAIT_FOR_RESP_CR: This state checks that response credits are available to present the response to the TLX.
//                  If one is available, do the following right away. If none are present, wait for one to
//                  show up then do the following.
//                  - Present the saved response to the TLX using resp_valid. 
//                  - Issue command credit to the TLX in order to receive the next command. 
//                  - Operation is complete, jump to IDLE.
always @(posedge(clock))  
  if (SM_MMW == SM_MMW_WAIT_FOR_RESP_CR)
    begin
      afu_tlx_resp_opcode_mmw  <= mmw_resp_opcode; // Put response on TLX interface, but might not trigger with resp_valid yet   
      afu_tlx_resp_dl_mmw      <= mmw_resp_dl;       
      afu_tlx_resp_dp_mmw      <= mmw_resp_dp;       
      afu_tlx_resp_capptag_mmw <= mmw_capptag;     // Use saved tag from command
      afu_tlx_resp_code_mmw    <= mmw_resp_code;   
      if (tarc_credits_available >= 4'b0001 )
        begin
          afu_tlx_resp_valid_mmw  <= 1'b1;         // Present response to TLX
          cmd_complete_mmw        <= 1'b1;         // Issue credit to TLX to get next cmd
          tarc_consume_credit_mmw <= 4'b0001;      // TLX consumes a credit with resp_valid, so echo that in credit counter
        end
      else                                         // Wait for response credit to show up
        begin
          afu_tlx_resp_valid_mmw  <= 1'b0;         // Do not issue resp_valid yet
          cmd_complete_mmw        <= 1'b0;         // Do not issue credit to TLX to get next cmd yet
          tarc_consume_credit_mmw <= 4'b0;       // Do not consume TLX credit yet
        end
    end  
  else
    begin
       afu_tlx_resp_valid_mmw   <= 1'b0;   // Clear OR inputs when not in this state 
       afu_tlx_resp_opcode_mmw  <= 8'b0;        
       afu_tlx_resp_dl_mmw      <= 2'b0;      
       afu_tlx_resp_dp_mmw      <= 2'b0;       
       afu_tlx_resp_capptag_mmw <= 16'b0; 
       afu_tlx_resp_code_mmw    <= 4'b0;       
       cmd_complete_mmw         <= 1'b0;   
       tarc_consume_credit_mmw  <= 4'b0;
    end


// WAIT_FOR_NEXT_CMD: Nothing to do in this state. It is required to allow the CMD FIFO time to present the next command.
//                    It is needed because 'cmd_complete' doesn't appear until the cycle after WAIT_FOR_RESP_CR. 
//                    There is no way to predictively send 'cmd_complete' in the cycle before to eliminate the need
//                    for this state, because it could stay in WAIT_FOR_RESP_CR indefinitely depending on when the TLX
//                    returns response credits. 


// ERROR: If this state is entered, something went wrong. For instance, a soft error might put the state machine into
//        an illegal state. Because this is a test design, don't try to recover and proceed but instead
//        lock up in this state so the user knows there is an error to go find and fix.


// Determine next state
always @(posedge(clock))
  if (reset == 1'b1) SM_MMW <= SM_MMW_IDLE;   
  else 
    case (SM_MMW)
      SM_MMW_IDLE:            
          if (start_mmio_write == 1'b1)          SM_MMW <= SM_MMW_WAIT_FOR_DATA;
          else                                   SM_MMW <= SM_MMW_IDLE;
      SM_MMW_WAIT_FOR_DATA:
          if (tlx_afu_cmd_data_valid == 1'b1)    SM_MMW <= SM_MMW_WAIT_FOR_MREG1;
          else                                   SM_MMW <= SM_MMW_WAIT_FOR_DATA;
      SM_MMW_WAIT_FOR_MREG1:
                                                 SM_MMW <= SM_MMW_WAIT_FOR_MREG2;
      SM_MMW_WAIT_FOR_MREG2:
                                                 SM_MMW <= SM_MMW_WAIT_FOR_MREG3;
      SM_MMW_WAIT_FOR_MREG3:
                                                 SM_MMW <= SM_MMW_WAIT_FOR_RESP_CR;  
      SM_MMW_WAIT_FOR_RESP_CR:
          if (tarc_credits_available >= 4'b0001) SM_MMW <= SM_MMW_WAIT_FOR_NEXT_CMD;
          else                                   SM_MMW <= SM_MMW_WAIT_FOR_RESP_CR;
      SM_MMW_WAIT_FOR_NEXT_CMD:
                                                 SM_MMW <= SM_MMW_IDLE;
      SM_MMW_ERROR:
          SM_MMW <= SM_MMW_ERROR;
      default:
          SM_MMW <= SM_MMW_ERROR;
    endcase
    

// ==============================================================================================================================
// @@@ MMR: Command State Machine - MMIO Read (pr_rd_mem from MMIO BAR space)
// ==============================================================================================================================

// State Machine for MMIO Read (MMR)

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg [2:0]  SM_MMR;                
parameter  SM_MMR_IDLE              = 3'b000;
parameter  SM_MMR_WAIT_FOR_MREG1    = 3'b001;
parameter  SM_MMR_WAIT_FOR_MREG2    = 3'b010;
parameter  SM_MMR_WAIT_FOR_RESP_CR  = 3'b011;   // Wait for Response Credits to be available
parameter  SM_MMR_WAIT_FOR_NEXT_CMD = 3'b100;
parameter  SM_MMR_ERROR             = 3'b111;   

// Behavior to perform in each state

// IDLE: In this state, we're just waiting for a MMIO read command to appear from the TLX. 
//       When it does, capture and hold some field values that need to be returned in the response.
//       Note: For synthesis purposes, break this into a combinational and clocked section.
//
// Because the TLX presents latched data and MMIO regs latch it upon receipt, it should make timing to present 
// the read address and strobe in the same cycle as the command is decoded.
always @(*)   // Combinational 
  if (SM_MMR == SM_MMR_IDLE && start_mmio_read == 1'b1)
    begin                                     
      mmio_addr_mmr = cff_cmd_pa[19:0];  // Send address, read strobe, and write data to MMIO regs
      mmio_rd       = 1'b1;
    end
  else
    begin
      mmio_addr_mmr = 20'b0;         // To prevent unnecessary register switching in MMIO regs, tie write inputs to 0 while not in use
      mmio_rd       = 1'b0;          // Set read controls inactive when not in use
    end
// Above is equivalent to:
// assign mmio_addr_mmr = (SM_MMR == SM_MMR_IDLE && start_mmio_read == 1'b1) ? cff_cmd_pa[19:0] : 20'b0;
// assign mmio_rd       = (SM_MMR == SM_MMR_IDLE && start_mmio_read == 1'b1) ? 1'b1 : 1'b0;
//
reg   [2:0] mmr_pl; 
reg  [15:0] mmr_capptag; 
reg  [63:0] mmr_addr;
always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  if (SM_MMR == SM_MMR_IDLE) 
    begin
      mmr_pl          <= cff_cmd_pl;                // Latch copies for use later 
      mmr_capptag     <= cff_cmd_capptag;  
      mmr_addr        <= cff_cmd_pa;
    end
  else
    begin
      mmr_pl          <= mmr_pl;                    // Hold values so state machines below can use contents
      mmr_capptag     <= mmr_capptag;
      mmr_addr        <= mmr_addr;
    end


// WAIT_FOR_MREG1: MMIO regs take 2 cycles to process the read. This state absorbs the first cycle.
//                 From a behavior standpoint, there is nothing to do. 


// WAIT_FOR_MREG2: In this state, look for data or an error indicator from the MMIO regs. 
//                 In a high performance application where latency on MMIO operations is critical,
//                 it may be possible (timing closure permitting) to determine and present the response and response data
//                 in the same cycle that the error indicator is present. In this case:
//                   If at least 1 response credit is available:
//                   - Present one of two responses to the TLX using resp_valid. 
//                   --- If no error is present, issue mem_rd_response
//                   --- If    error is present, issue mem_rd_fail
//                   - Issue command credit to the TLX in order to receive the next command. 
//                   - Operation is complete, jump to IDLE.
//                   If no response credits are available:
//                   - Enter state that waits for response credits.
//                   - Save the response from the MMIO regs so the wait state can use it later to determine the response type.
//                 However implemention of this could be messy. For this design which intends to be a reference
//                 model so should be as understandable as possible, and does not have critical latency requirements
//                 on MMIO operations, it was decided to spend another cycle and always use another state
//                 to manage the presence or absense of response credits. In this case:
//                   - Prepare one of two responses to the TLX. 
//                   --- If no error is present, prepare mem_rd_response
//                   --- If    error is present, prepare mem_rd_fail
//                   - Jump to WAIT_FOR_RESP_CR.
//                 The next state will check for the presense of response credits and wait for one if none are available.
//                 It will also issue the command credit before ending the operation and returning to IDLE.

// Helper signal: set mmr_legal_size to 1 if requested operation was 1, 2, 4, or 8 Bytes in size
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   mmr_legal_size;
assign mmr_legal_size = (mmr_pl == 3'b000 || mmr_pl == 3'b001 || mmr_pl == 3'b010 || mmr_pl == 3'b011) ? 1'b1 : 1'b0;

reg [63:0] mmr_rdata;
reg  [7:0] mmr_resp_opcode;
reg  [1:0] mmr_resp_dl;
reg  [1:0] mmr_resp_dp;
reg  [3:0] mmr_resp_code;
reg        mmr_rdata_bdi;
reg        mmr_rdata_valid;
always @(posedge(clock))  
  if (SM_MMR == SM_MMR_WAIT_FOR_MREG2)
    begin
      mmr_rdata <= mmio_rdata;           // Capture data from MMIO regs
      if (mmio_addr_not_implemented == 1'b1 || mmr_legal_size == 1'b0 || mmio_bad_op_or_align == 1'b1 ||  
          (mmio_bad_op_or_align == 1'b0 && mmio_addr_not_implemented == 1'b0 && mmio_rdata_vld == 1'b0) )
        begin                            // Error if unimplemented addr, bad alignment, illegal size, or data is not valid while no error present
          mmr_resp_opcode  <= 8'h02;     // mem_rd_fail 
          mmr_resp_dl      <= 2'b01;     // dL doesn't exist in command, set to 1 FLIT
          mmr_resp_dp      <= 2'b00;     // All FLITs covered by response, so start at 0
          mmr_rdata_bdi    <= 1'b0;      // fail response has no data associated with it
          mmr_rdata_valid  <= 1'b0;      // Set to 0 so fail response will not have valid data with it
          if (mmio_addr_not_implemented == 1'b1)
            begin
              mmr_resp_code      <= 4'hE;  // Access to un-implemented address in BAR range, use general fail code
              ery_src03[111:108] <= 4'hE;
            end
//        else if ('AFU memory reported bad ECC or parity on contents')  <-- there is no check on this since no protection is implemented 
//          begin                                                            on AFU memory at this time. If it is added later, enable this check.
//            mmr_resp_code      <= 4'h8;      (data error) 
//            ery_src03[111:108] <= 4'h8;
//          end
          else if (mmr_legal_size == 1'b0)
            begin
              mmr_resp_code      <= 4'h9;  // Length is not legal, read happened but data was suppressed - report 'unsupported length' error
              ery_src03[111:108] <= 4'h9;
            end
          else if (mmio_bad_op_or_align == 1'b1)
            begin
              mmr_resp_code      <= 4'hE;  // Note: MMIO regs does not do an alignment check on a read, so this condition only occurs if the design
                                           // issued an illegal combination of strobes. If this happens, then use general fail code (xE).
                                           // If MMIO regs ever adds an alignment check on reads, separate the two cases (bad strobes vs. 
                                           // bad alignment) with a new signal and use 'bad address specification' code xB for the bad alignment.
              ery_src03[111:108] <= 4'hE;
            end
          else 
            mmr_resp_code  <= 4'h8;      // No problem with size or address, something else went wrong - report 'data error'
          // Save error information which triggers interrupt
          ery_loadsrc[3]     <= 1'b1;          // source 3 = config_read state machine
          ery_src03[127:112] <= 16'h0008;      // source 3 = config_read state machine
          ery_src03[    107] <= 1'b0;          
          ery_src03[106: 87] <= 20'b0;
          ery_src03[ 86: 84] <= mmr_pl;
          ery_src03[ 83: 82] <= 2'b0;
          ery_src03[ 81: 80] <= 2'b01;         // dL doesn't exist in command, set to 1 FLIT
          ery_src03[ 79: 64] <= mmr_capptag;
          ery_src03[ 63:  0] <= mmr_addr;

        end
      else                               // Operation was a success
        begin
          mmr_resp_opcode  <= 8'h01;     // mem_rd_response
          mmr_resp_dl      <= 2'b01;     // Return data is one 64B FLIT
          mmr_resp_dp      <= 2'b00;     // MMIO read uses 1 flit, so starting offset is 0
          mmr_resp_code    <= 4'h0;      // Not used with mem_wr_response
          mmr_rdata_bdi    <= 1'b0;      // Data is good
          mmr_rdata_valid  <= 1'b1;      // Response has valid data response with it       
          ery_loadsrc[3]   <= 1'b0;      // No error information saved
          ery_src03        <= 128'b0;
        end
    end  
  else
    begin
       mmr_rdata        <= mmr_rdata;    // Hold values so state machines below can use contents
       mmr_resp_opcode  <= mmr_resp_opcode;
       mmr_resp_dl      <= mmr_resp_dl;      
       mmr_resp_dp      <= mmr_resp_dp;       
       mmr_resp_code    <= mmr_resp_code;       
       mmr_rdata_bdi    <= mmr_rdata_bdi;
       mmr_rdata_valid  <= mmr_rdata_valid;
       ery_loadsrc[3]   <= 1'b0;              // If error load was set by this state, clear the strobe when leave it
       ery_src03        <= 128'b0;
    end


// Align the 8B of data from MMIO regs into the proper position in the 64B flit
// Form the return data at all times. The state machine will determine when to validate it.
wire [511:0] mmr_rdata_flit;
assign mmr_rdata_flit[ 63:  0] = (mmr_addr[5:3] == 3'b000) ? mmr_rdata : 64'b0;
assign mmr_rdata_flit[127: 64] = (mmr_addr[5:3] == 3'b001) ? mmr_rdata : 64'b0;
assign mmr_rdata_flit[191:128] = (mmr_addr[5:3] == 3'b010) ? mmr_rdata : 64'b0;
assign mmr_rdata_flit[255:192] = (mmr_addr[5:3] == 3'b011) ? mmr_rdata : 64'b0;
assign mmr_rdata_flit[319:256] = (mmr_addr[5:3] == 3'b100) ? mmr_rdata : 64'b0;
assign mmr_rdata_flit[383:320] = (mmr_addr[5:3] == 3'b101) ? mmr_rdata : 64'b0;
assign mmr_rdata_flit[447:384] = (mmr_addr[5:3] == 3'b110) ? mmr_rdata : 64'b0;
assign mmr_rdata_flit[511:448] = (mmr_addr[5:3] == 3'b111) ? mmr_rdata : 64'b0;


//WAIT_FOR_RESP_CR: This state checks that response credits are available to present the response to the TLX.
//                  If one is available, do the following right away. If none are present, wait for one to
//                  show up then do the following.
//                  - Present the saved response to the TLX using resp_valid. 
//                  - Issue command credit to the TLX in order to receive the next command. 
//                  - Operation is complete, jump to IDLE.
always @(posedge(clock))  
  if (SM_MMR == SM_MMR_WAIT_FOR_RESP_CR)
    begin 
      afu_tlx_resp_opcode_mmr  <= mmr_resp_opcode;     // Put response on TLX interface, but might not trigger with resp_valid yet   
      afu_tlx_resp_dl_mmr      <= mmr_resp_dl;       
      afu_tlx_resp_dp_mmr      <= mmr_resp_dp;       
      afu_tlx_resp_capptag_mmr <= mmr_capptag;         // Use saved tag from command
      afu_tlx_resp_code_mmr    <= mmr_resp_code;   
      afu_tlx_rdata_bus_mmr    <= mmr_rdata_flit;
      afu_tlx_rdata_bdi_mmr    <= mmr_rdata_bdi;
      if ((mmr_rdata_valid == 1'b1 && tarc_credits_available >= 4'b0001 && tardc_credits_available >= 6'b000001) || // need resp & resp data credits
          (mmr_rdata_valid == 1'b0 && tarc_credits_available >= 4'b0001) )                                          // need only resp credits
        begin
          afu_tlx_resp_valid_mmr   <= 1'b1;            // Present response to TLX
          afu_tlx_rdata_valid_mmr  <= mmr_rdata_valid; // Present response data to TLX, if it exists
          tarc_consume_credit_mmr  <= 4'b0001;          // TLX consumes a credit with resp_valid, so echo that in credit counter
          if (mmr_rdata_valid == 1'b1)
            tardc_consume_credit_mmr <= 6'b000001;      // TLX consumes a data credit with resp_valid, so echo that in credit counter
          else
            tardc_consume_credit_mmr <= 6'b0;      // No data credit consumption since there is no rdata_valid returned
          cmd_complete_mmr   <= 1'b1;                  // Issue credit to TLX to get next cmd
        end
      else                                             // Wait for response credit to show up
        begin
          afu_tlx_resp_valid_mmr   <= 1'b0;            // Do not issue response valid yet
          afu_tlx_rdata_valid_mmr  <= 1'b0;            // Do not issue reponse data valid yet
          tarc_consume_credit_mmr  <= 4'b0;          // Do not consume response credit yet
          tardc_consume_credit_mmr <= 6'b0;        // Do not consume response data credit yet
          cmd_complete_mmr         <= 1'b0;            // Do not issue credit to TLX to get next cmd yet
        end
    end  
  else
    begin
       afu_tlx_resp_opcode_mmr  <= 8'b0;               // Clear OR inputs when not in this state      
       afu_tlx_resp_dl_mmr      <= 2'b0;      
       afu_tlx_resp_dp_mmr      <= 2'b0;       
       afu_tlx_resp_capptag_mmr <= 16'b0; 
       afu_tlx_resp_code_mmr    <= 4'b0; 
       afu_tlx_rdata_bus_mmr    <= 512'b0;     
       afu_tlx_rdata_bdi_mmr    <= 1'b0;
       afu_tlx_resp_valid_mmr   <= 1'b0;   
       afu_tlx_rdata_valid_mmr  <= 1'b0;
       tarc_consume_credit_mmr  <= 4'b0;
       tardc_consume_credit_mmr <= 6'b0;
       cmd_complete_mmr         <= 1'b0;   
    end


// WAIT_FOR_NEXT_CMD: Nothing to do in this state. It is required to allow the CMD FIFO time to present the next command.
//                    It is needed because 'cmd_complete' doesn't appear until the cycle after WAIT_FOR_RESP_CR. 
//                    There is no way to predictively send 'cmd_complete' in the cycle before to eliminate the need
//                    for this state, because it could stay in WAIT_FOR_RESP_CR indefinitely depending on when the TLX
//                    returns response credits. 


// ERROR: If this state is entered, something went wrong. For instance, a soft error might put the state machine into
//        an illegal state. Because this is a test design, don't try to recover and proceed but instead
//        lock up in this state so the user knows there is an error to go find and fix.


// Determine next state
always @(posedge(clock))
  if (reset == 1'b1) SM_MMR <= SM_MMR_IDLE;   
  else 
    case (SM_MMR)
      SM_MMR_IDLE:            
          if (start_mmio_read == 1'b1)           SM_MMR <= SM_MMR_WAIT_FOR_MREG1;
          else                                   SM_MMR <= SM_MMR_IDLE;
      SM_MMR_WAIT_FOR_MREG1:
                                                 SM_MMR <= SM_MMR_WAIT_FOR_MREG2;
      SM_MMR_WAIT_FOR_MREG2:
                                                 SM_MMR <= SM_MMR_WAIT_FOR_RESP_CR;  
      SM_MMR_WAIT_FOR_RESP_CR:
          if ((mmr_rdata_valid == 1'b1 && tarc_credits_available >= 4'b0001 && tardc_credits_available >= 6'b000001) || // need resp & resp data credits
              (mmr_rdata_valid == 1'b0 && tarc_credits_available >= 4'b0001) )                                          // need only resp credits
                                                 SM_MMR <= SM_MMR_WAIT_FOR_NEXT_CMD;
          else                                   SM_MMR <= SM_MMR_WAIT_FOR_RESP_CR;
      SM_MMR_WAIT_FOR_NEXT_CMD:
                                                 SM_MMR <= SM_MMR_IDLE;
      SM_MMR_ERROR:
                                                 SM_MMR <= SM_MMR_ERROR;
      default:
                                                 SM_MMR <= SM_MMR_ERROR;
    endcase


// ==============================================================================================================================
// @@@ PWM: Command State Machine - pr_wr_mem
// ==============================================================================================================================

// Combine Partial Write Memory into the Full Write Memory state machine. 

// ==============================================================================================================================
// @@@ FWM: Command State Machine - write_mem  (Full Write to Memory)
// ==============================================================================================================================

// In parallel with the state machine, determine the ending FLIT number given the operation size and alignment
// NOTE: Used in both FWM and FRM state machines
reg [1:0] max_flit_addr;    // Use to know when *_flit_addr has increased to the maximum number of FLITs in this operation
always @(*)    // Combinational
  case ({cff_cmd_dl, cff_cmd_pa[7:6]} )
    4'b00_00 : begin max_flit_addr = 2'b01; end     // Reserved Error - let LPC hang by waiting for data which won't come
    4'b00_01 : begin max_flit_addr = 2'b10; end     // Reserved Error - let LPC hang by waiting for data which won't come
    4'b00_10 : begin max_flit_addr = 2'b11; end     // Reserved Error - let LPC hang by waiting for data which won't come
    4'b00_11 : begin max_flit_addr = 2'b00; end     // Reserved Error - let LPC hang by waiting for data which won't come

    4'b01_00 : begin max_flit_addr = 2'b00; end     //  64 Bytes
    4'b01_01 : begin max_flit_addr = 2'b01; end     //  64 Bytes
    4'b01_10 : begin max_flit_addr = 2'b10; end     //  64 Bytes
    4'b01_11 : begin max_flit_addr = 2'b11; end     //  64 Bytes

    4'b10_00 : begin max_flit_addr = 2'b01; end     // 128 Bytes
    4'b10_01 : begin max_flit_addr = 2'b10; end     // 128 Bytes  Error - read but discard 2 FLITs from TLX
    4'b10_10 : begin max_flit_addr = 2'b11; end     // 128 Bytes
    4'b10_11 : begin max_flit_addr = 2'b00; end     // 128 Bytes  Error - read but discard 2 FLITs from TLX

    4'b11_00 : begin max_flit_addr = 2'b11; end     // 256 Bytes
    4'b11_01 : begin max_flit_addr = 2'b00; end     // 256 Bytes  Error - read but discard 4 FLITs from TLX
    4'b11_10 : begin max_flit_addr = 2'b01; end     // 256 Bytes  Error - read but discard 4 FLITs from TLX
    4'b11_11 : begin max_flit_addr = 2'b10; end     // 256 Bytes  Error - read but discard 4 FLITs from TLX

    default  : begin max_flit_addr = 2'b00; end     // Error - other checks should prevent writing and return fail response
  endcase


// State Machine for Full Write to Memory (FWM)

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg [3:0]  SM_FWM;                
parameter  SM_FWM_IDLE              = 4'b0000;
parameter  SM_FWM_WAIT_FOR_SAM1     = 4'b0001;
parameter  SM_FWM_WAIT_FOR_SAM2     = 4'b0010;
parameter  SM_FWM_WAIT_FOR_DATA     = 4'b0011;
parameter  SM_FWM_WAIT_FOR_RESP_CR  = 4'b0100;   // Wait for Response Credits to be available
parameter  SM_FWM_WAIT_FOR_NEXT_CMD = 4'b0101;
parameter  SM_FWM_ERROR             = 4'b1111;   

// Behavior to perform in each state

// IDLE: In this state, we're just waiting for a full write to memory (write_mem) command to appear from the TLX. 
//       When it does, kick off the sparse memory translation of the address.
//       Note: For synthesis purposes, break this into a combinational and clocked section.
//
reg         sam_enable_fwm;
reg  [63:0] sam_addr_in_fwm;
//
always @(*)    // Combinational
  if (SM_FWM == SM_FWM_IDLE)  // Note: This qualifying condition is redundant until the LPC starts handling pipelined commands.
                              //       But use it as a precaution to prevent a second command from being started if one is being processed.
    begin                             
      if (start_write_mem == 1'b1 || start_pr_wr_mem == 1'b1 || start_write_mem_be == 1'b1) // Perform action in the same cycle as seeing cmd_valid to improve performance
        begin
          sam_enable_fwm         = 1'b1;                     // Kick off Sparse Array Map translation
          if (start_write_mem == 1'b1 || start_write_mem_be == 1'b1)
            sam_addr_in_fwm      = { cff_cmd_pa[63:6], 6'b0} ;   // write_mem & write_mem.be assume PA[5:0]=0
          else
            sam_addr_in_fwm      = cff_cmd_pa[63:0];             // pr_wr_mem carries the entire address in the command
        end
      else                                          
        begin                                       // Execute this code block when in IDLE but no write_mem command is going on 
          sam_enable_fwm         = 1'b0;
          sam_addr_in_fwm        = 64'b0;
        end
    end
  else                                              // In the middle of a write_mem operation, but not in the IDLE state
    begin
      sam_enable_fwm         = 1'b0;
      sam_addr_in_fwm        = 64'b0;
    end
// Above is equivalent to:
// assign sam_enable_fwm  = (SM_FWM == SM_FWM_IDLE && (start_write_mem == 1'b1 || start_pr_wr_mem == 1'b1)) 
//                          ? 1'b1           : 1'b0 ;  // Kick off Sparse Array Map translation
// assign sam_addr_in_fwm = (SM_FWM == SM_FWM_IDLE && (start_write_mem == 1'b1 || start_pr_wr_mem == 1'b1))
//                          ? cff_cmd_pa : 64'b0;  // Address to map to Bulk Memory entry
//
reg   [1:0] fwm_dl;    
reg   [2:0] fwm_pl;
reg  [15:0] fwm_capptag;
reg  [63:0] fwm_addr; 
reg   [2:0] fwm_rd_cnt;
reg   [1:0] fwm_max_flit_addr;
reg         fwm_pr_wr_mem;
reg         fwm_write_mem_be;
reg  [63:0] fwm_be;
always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  if (SM_FWM == SM_FWM_IDLE) 
    begin
      fwm_capptag            <= cff_cmd_capptag;          // Latch signals used in all 3 command types
      if (start_pr_wr_mem == 1'b1)                        // Save information related to partial write memory
        begin 
          fwm_addr           <= cff_cmd_pa[63:0];         // pr_wr_mem carries the entire address in the command
          fwm_dl             <= 2'b01;                    // dL is not used, set to 1 FLIT to return in response
          fwm_pl             <= cff_cmd_pl;               // pL is used, capture it
          fwm_be             <= 64'b0;                    // be is not used, set to all 0s
          fwm_rd_cnt         <= 3'b001;                   // Always 64 bytes (DL field is not part of pr_wr_mem cmd)
          fwm_max_flit_addr  <= cff_cmd_pa[7:6];          // Set to starting address since always 1 FLIT long
          fwm_pr_wr_mem      <= 1'b1;                     // Save that this is partial mem write
          fwm_write_mem_be   <= 1'b0;                     // Command was not write_mem.be
        end
     else if (start_write_mem_be == 1'b1)                 // Save information related to 1 64B flit
        begin 
          fwm_addr           <= { cff_cmd_pa[63:6], 6'b0} ;   // write_mem & write_mem.be assume PA[5:0]=0
          fwm_dl             <= 2'b01;                    // dL is not used, set to 1 FLIT to return in response
          fwm_pl             <= 3'b111;                   // pL is not used, set to a reserved value
          fwm_be             <= cff_cmd_be;               // be is used, capture it
          fwm_rd_cnt         <= 3'b001;                   // Always 64 bytes (DL field is not part of pr_wr_mem cmd)
          fwm_max_flit_addr  <= cff_cmd_pa[7:6];          // Set to starting address since always 1 FLIT long
          fwm_pr_wr_mem      <= 1'b0;                     // Command was not pr_wr_mem
          fwm_write_mem_be   <= 1'b1;                     // Save that this is write_mem.be
        end
      else                                                // Assume if proceed out of this state, it was because (start_write_mem == 1)
        begin
          fwm_addr           <= { cff_cmd_pa[63:6], 6'b0} ;   // write_mem & write_mem.be assume PA[5:0]=0
          fwm_dl             <= cff_cmd_dl;               // dL is used, capture it
          fwm_pl             <= 3'b111;                   // pL is not used, set to a reserved value
          fwm_be             <= 64'b0;                    // be is not used, set to all 0s
          fwm_rd_cnt         <= {1'b0, cff_cmd_dl} ;      // For legal sizes of 64, 128, 256 Bytes
          fwm_max_flit_addr  <= max_flit_addr;            // Calculated based on length and starting address
          fwm_pr_wr_mem      <= 1'b0;                     // Command was not pr_wr_mem
          fwm_write_mem_be   <= 1'b0;                     // Command was not write_mem.be
        end
    end
  else
    begin
      fwm_capptag            <= fwm_capptag;              // Hold values so state machines below can use contents
      fwm_addr               <= fwm_addr;
      fwm_dl                 <= fwm_dl;                   
      fwm_pl                 <= fwm_pl;
      fwm_be                 <= fwm_be;
      fwm_rd_cnt             <= fwm_rd_cnt;
      fwm_max_flit_addr      <= fwm_max_flit_addr;
      fwm_pr_wr_mem          <= fwm_pr_wr_mem;
      fwm_write_mem_be       <= fwm_write_mem_be;
    end


// WAIT_FOR_SAM1: In this state, we're waiting for the Sparse Array Map to provide the correct Bulk Memory address.
//                Nothing to do in this state.

// Note: In preparation for adding pipelining, waste a few cycles to get the SAM address first before requesting data
//       from the TLX. In the current version where only one command is executed at a time, we could issue the 
//       read data request at the same time as starting the SAM. This is because the TLX takes 2 cycles to start
//       presenting data if there was no command back to back just before it. However when pipelining, data could
//       arrive the next cycle, 1, or 2 cycles after the read request. In this case data could start arriving before
//       the SAM finished (i.e. before the AFU knew where to put it), so to resolve this always complete the SAM
//       look up before requesting data. That way it can arrive whenever it wants to as the Bulk Memory location will
//       have already been determined.


// WAIT_FOR_SAM2: Capture the mapped Bulk Memory address. Request data from the TLX.
reg [11:0] fwm_sam_addr_out;
reg        fwm_sam_overflow;
//g        fwm_sam_no_match;   // Note: This may not need to be saved. When 1, SAM consumed a mapping resource with the current sam_addr_in value.
always @(posedge(clock))    
  if (SM_FWM == SM_FWM_WAIT_FOR_SAM2)  
    begin                             
      fwm_sam_addr_out       <= sam_addr_out;      // Capture mapped Bulk Memory address    
      fwm_sam_overflow       <= sam_overflow;      // Capture error conditions
//    fwm_sam_no_match       <= sam_no_match;
      afu_tlx_cmd_rd_req_fwm <= 1'b1;              // Request flits(s) from TLX
      afu_tlx_cmd_rd_cnt_fwm <= fwm_rd_cnt;        // Derive number of FLITs from command DL field (if 00, AFU will hang which is what we want)
    end
  else                                          
    begin
      fwm_sam_addr_out       <= fwm_sam_addr_out;  // Hold value
      fwm_sam_overflow       <= fwm_sam_overflow;
//    fwm_sam_no_match       <= fwm_sam_no_match;
      afu_tlx_cmd_rd_req_fwm <= 1'b0;              // Set to 0 to not request any more data from TLX
      afu_tlx_cmd_rd_cnt_fwm <= 3'b000;            // Set to 0 to not influence OR gate
    end


// WAIT_FOR_DATA: In this state, we're waiting for the TLX to present data. 
//                When it does, start writing FLITs to the Bulk Memory if the address is aligned.
//                If the address is not aligned, pull the data from the TLX to clear it out but don't overwrite memory contents.
//                Stay in this state until all the FLITs have been removed.
//
// To improve timing closure, determine the partial write enable bits all the time and 
// let the write state machine determine when to pass it to bulk memory.
reg  [63:0] fwm_pr_wren;
always @(*)  // Combinational logic
  case (fwm_pl[2:0])   // Align enables to 32 bit word based on address and size
    3'b000 : fwm_pr_wren = 64'h0000_0000_0000_0001 << (  fwm_addr[5:0]        );  //  1 byte
    3'b001 : fwm_pr_wren = 64'h0000_0000_0000_0003 << ( {fwm_addr[5:1], 1'b0} );  //  2 bytes
    3'b010 : fwm_pr_wren = 64'h0000_0000_0000_000F << ( {fwm_addr[5:2], 2'b0} );  //  4 bytes
    3'b011 : fwm_pr_wren = 64'h0000_0000_0000_00FF << ( {fwm_addr[5:3], 3'b0} );  //  8 bytes
    3'b100 : fwm_pr_wren = 64'h0000_0000_0000_FFFF << ( {fwm_addr[5:4], 4'b0} );  // 16 bytes
    3'b101 : fwm_pr_wren = 64'h0000_0000_FFFF_FFFF << ( {fwm_addr[5]  , 5'b0} );  // 32 bytes
    default: fwm_pr_wren = 64'h0000_0000_0000_0000;    // Suppress write, other logic should create error response
  endcase 

// Helper signal: set fwm_legal_size to 1 if requested operation was 
//                a) partial write of 1, 2, 4. 8. 16 or 32 Bytes 
//                b) write_mem.be (size assumed to be 64 Bytes)
//                c) write_mem of 64, 128, or 256 Bytes in size 
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   fwm_legal_size;
assign fwm_legal_size  = ( (fwm_pr_wr_mem == 1'b1 && (fwm_pl == 3'b000 || fwm_pl == 3'b001 || fwm_pl == 3'b010 ||
                                                      fwm_pl == 3'b011 || fwm_pl == 3'b100 || fwm_pl == 3'b101)) ? 1'b1 : 1'b0 
                         ) |   // OR conditions together
                         ( (fwm_write_mem_be == 1'b1) ? 1'b1 : 1'b0
                         ) |
                         ( (fwm_pr_wr_mem == 1'b0 && fwm_write_mem_be == 1'b0 &&
                            (fwm_dl == 2'b01  || fwm_dl == 2'b10  || fwm_dl == 2'b11 ) ) ? 1'b1 : 1'b0
                         );
// Helper signal: set fwm_legal_align to 1 if address is naturally aligned to the size
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   fwm_legal_align;
assign fwm_legal_align = ( (fwm_pr_wr_mem == 1'b1 && (
                             (fwm_pl == 3'b000                                ) ||  //   1 byte has any alignment
                             (fwm_pl == 3'b001 && fwm_addr[0]   == 1'b0       ) ||  //   2 bytes
                             (fwm_pl == 3'b010 && fwm_addr[1:0] == 2'b00      ) ||  //   4 bytes
                             (fwm_pl == 3'b011 && fwm_addr[2:0] == 3'b000     ) ||  //   8 bytes
                             (fwm_pl == 3'b100 && fwm_addr[3:0] == 4'b0000    ) ||  //  16 bytes
                             (fwm_pl == 3'b101 && fwm_addr[4:0] == 5'b00000   ) ||  //  32 bytes
                             (fwm_pl == 3'b110                                ) ||  //  64 bytes - treat as legal so resp_code is illegal size
                             (fwm_pl == 3'b111                                ) )   // 128 bytes - treat as legal so resp_code is illegal size
                           ) ? 1'b1 : 1'b0
                         ) |   // OR conditions together
                         ( (fwm_write_mem_be == 1'b1) ? 1'b1 : 1'b0
                         ) |
                         ( (fwm_pr_wr_mem == 1'b0 && fwm_write_mem_be == 1'b0 && (
                             (fwm_dl == 2'b00                                 ) ||  // Treat reserved as aligned so resp_code is illegal size
                             (fwm_dl == 2'b01 && fwm_addr[5:0] == 6'b00_0000  ) ||  //  64 Bytes
                             (fwm_dl == 2'b10 && fwm_addr[6:0] == 7'b000_0000 ) ||  // 128 Bytes
                             (fwm_dl == 2'b11 && fwm_addr[7:0] == 8'b0000_0000) )   // 256 Bytes
                           ) ? 1'b1 : 1'b0
                         );
//
reg    [1:0] fwm_flit_addr;   // Counts 00,01,10,11 to keep track of FLITs, but doubles as 2 bits of FLIT offset in Bulk Memory address
reg   [63:0] mem_addr_fwm;    // All 64 bits carried to bulk memory for future expansion
reg   [63:0] mem_wren_fwm;
reg  [511:0] mem_din_fwm;
reg          mem_din_bdi_fwm;
reg          fwm_all_bdi;
reg    [7:0] fwm_resp_opcode;
reg    [1:0] fwm_resp_dl;
reg    [1:0] fwm_resp_dp;
reg    [3:0] fwm_resp_code;
always @(posedge(clock))  
  if (SM_FWM == SM_FWM_WAIT_FOR_DATA)
    begin
      // Note: When TLX presents data, all requested FLITs will appear on back to back cycles.
      //       CMD_DATA_VALID will be 1 for each FLIT, not just the first one.  
      if (tlx_afu_cmd_data_valid == 1'b1)  // When DL is reserved value, no FLITs were requested so don't wait for valid.
        begin
          fwm_flit_addr   <= fwm_flit_addr + 2'b01;             // 'Next State' logic will exit this state when fwm_flit_addr = fwm_max_flit_addr
          mem_addr_fwm    <= {fwm_addr[63:14], fwm_sam_addr_out, fwm_flit_addr}; // [13:2] select 256B entry, [1:0] select the FLIT within entry
          mem_din_fwm     <= tlx_afu_cmd_data_bus;              // Pass data from TLX into Bulk Memory
          mem_din_bdi_fwm <= tlx_afu_cmd_data_bdi;              // Pass bad data indicator from TLX into Bulk Memory
          fwm_all_bdi     <= tlx_afu_cmd_data_bdi | fwm_all_bdi;  // OR reduce BDI bits from all FLITs
          // Check for errors: address not naturally aligned, illegal size (which includes 00=reserved), bad SAM translation
          // Note: sam_no_match = 1 is OK on write, since data will be written into bulk memory after a new translation entry is added
          //   But sam_no_match = 1 on read is not OK, since data read from bulk memory will be X, as it hasn't been initialized
          if (fwm_legal_align == 1'b0 || fwm_legal_size == 1'b0 || fwm_sam_overflow == 1'b1)  
            begin                                             // An error occurred
              mem_wren_fwm     <= 64'h0000_0000_0000_0000;    // Convert this into a read so no memory contents change
              fwm_resp_opcode  <= 8'h05;                      // mem_wr_fail
              fwm_resp_dl      <= fwm_dl;                     // Response DL matches Command DL indicating all FLITs were covered by response
              fwm_resp_dp      <= 2'b00;                      // All FLITs covered by response, so start at 0
              if (fwm_legal_align == 1'b0)
                fwm_resp_code  <= 4'hB;                       // Address is not aligned properly
              else if (fwm_legal_size == 1'b0)
                fwm_resp_code  <= 4'h9;                       // Length is not legal, report unsupported size error
              else // if (fwm_sam_overflow == 1'b1)           // (sam_no_match is not an error, although sam_overflow is)
                fwm_resp_code  <= 4'hE;                       // Access to un-implemented address in SAM, use general fail code
            end
          else
            begin                                             // Operation has no errors
              if      (fwm_pr_wr_mem == 1'b1)    mem_wren_fwm <= fwm_pr_wren;             // Write calculated bytes of the FLIT into memory
              else if (fwm_write_mem_be == 1'b1) mem_wren_fwm <= fwm_be;                  // Write selected   bytes of the FLIT into memory
              else                               mem_wren_fwm <= 64'hFFFF_FFFF_FFFF_FFFF; // Write all bytes of the FLIT into memory
              fwm_resp_opcode  <= 8'h04;                      // mem_wr_response
              fwm_resp_dl      <= fwm_dl;                     // Return saved dL from command or value set when cmd was decoded
              fwm_resp_dp      <= 2'b00;                      // All FLITs covered by response, so start at 0
              fwm_resp_code    <= 4'h0;                       // Not used with mem_wr_response
            end
        end
      else
        begin
          fwm_flit_addr    <= fwm_addr[7:6];            // Initialize to FLIT address points to while waiting for TLX data  
          mem_addr_fwm     <= 64'b0;                    // Set controls inactive when not in use
          mem_din_fwm      <= 512'b0; 
          mem_din_bdi_fwm  <= 1'b0;
          mem_wren_fwm     <= 64'h0000_0000_0000_0000;
          fwm_resp_opcode  <= 8'h00;                      
          fwm_resp_dl      <= 2'b00;               
          fwm_resp_dp      <= 2'b00;                  
          fwm_resp_code    <= 4'h0;                  
          fwm_all_bdi      <= 1'b0;                     // Initialize to 0 while waiting for TLX data 
                                                        // IMPORTANT: Requires waiting at least 1 cycle for this to execute to work properly.
                                                        //  This should be OK when FWM is not pipelined, since it takes 2 cycles to get data
                                                        //  from the TLX, but could be a problem if command pipelining is added.
        end
    end
  else
    begin
      fwm_flit_addr    <= fwm_addr[7:6];            // Initialize to FLIT address points to when not in this state
      fwm_all_bdi      <= fwm_all_bdi;              // Preserve value for use in next state
      mem_addr_fwm     <= 64'b0;                    // Set controls inactive when not in use
      mem_din_fwm      <= 512'b0; 
      mem_din_bdi_fwm  <= 1'b0;
      mem_wren_fwm     <= 64'h0000_0000_0000_0000;
      fwm_resp_opcode  <= fwm_resp_opcode;                              
      fwm_resp_dl      <= fwm_resp_dl;           
      fwm_resp_dp      <= fwm_resp_dp;            
      fwm_resp_code    <= fwm_resp_code;             
    end


//WAIT_FOR_RESP_CR: This state checks that response credits are available to present the response to the TLX.
//                  If one is available, do the following right away. If none are present, wait for one to
//                  show up then do the following.
//                  - Present the saved response to the TLX using resp_valid. 
//                  - Issue command credit to the TLX in order to receive the next command. 
//                  - Operation is complete, jump to IDLE.
always @(posedge(clock))  
  if (SM_FWM == SM_FWM_WAIT_FOR_RESP_CR)
    begin
      afu_tlx_resp_opcode_fwm  <= fwm_resp_opcode; // Put response on TLX interface, but might not trigger with resp_valid yet   
      afu_tlx_resp_dl_fwm      <= fwm_resp_dl;       
      afu_tlx_resp_dp_fwm      <= fwm_resp_dp;       
      afu_tlx_resp_capptag_fwm <= fwm_capptag;     // Use saved tag from command
      afu_tlx_resp_code_fwm    <= fwm_resp_code;   
      if (tarc_credits_available >= 4'b0001 )
        begin
          afu_tlx_resp_valid_fwm  <= 1'b1;         // Present response to TLX
          cmd_complete_fwm        <= 1'b1;         // Issue credit to TLX to get next cmd
          tarc_consume_credit_fwm <= 4'b0001;      // TLX consumes a credit with resp_valid, so echo that in credit counter

          // If response code is not successful (mem_wr_response), save error information and trigger interrupt
          // To ensure it checks only once, do it when sending the response code 
          if (fwm_resp_opcode != 8'h04)
            begin
              ery_loadsrc[4]     <= 1'b1;              // source 4 = full memory write state machine
              ery_src04[127:112] <= 16'h0010;          // source 4 = full memory write state machine
              ery_src04[111:108] <= fwm_resp_code;
              ery_src04[    107] <= fwm_all_bdi;       // OR of BDI from all FLITs received from host
              ery_src04[106: 87] <= 20'b0;
              ery_src04[ 86: 84] <= fwm_pl;
              ery_src04[ 83: 82] <= 2'b0;
              ery_src04[ 81: 80] <= fwm_dl;
              ery_src04[ 79: 64] <= fwm_capptag;
              ery_src04[ 63:  0] <= fwm_addr;
            end
          else
            begin
              ery_loadsrc[4]     <= 1'b0;              // Do not save or trigger interrupt on successful response code
              ery_src04          <= 128'b0;
            end  
        end
      else                                         // Wait for response credit to show up
        begin
          afu_tlx_resp_valid_fwm  <= 1'b0;         // Do not issue resp_valid yet
          cmd_complete_fwm        <= 1'b0;         // Do not issue credit to TLX to get next cmd yet
          tarc_consume_credit_fwm <= 4'b0;       // Do not consume TLX credit yet
          ery_loadsrc[4]          <= 1'b0;         // Do not save or trigger interrupt yet
          ery_src04               <= 128'b0;
        end
    end  
  else
    begin
       afu_tlx_resp_valid_fwm   <= 1'b0;   // Clear OR inputs when not in this state 
       afu_tlx_resp_opcode_fwm  <= 8'b0;        
       afu_tlx_resp_dl_fwm      <= 2'b0;      
       afu_tlx_resp_dp_fwm      <= 2'b0;       
       afu_tlx_resp_capptag_fwm <= 16'b0; 
       afu_tlx_resp_code_fwm    <= 4'b0;       
       cmd_complete_fwm         <= 1'b0;   
       tarc_consume_credit_fwm  <= 4'b0;
       ery_loadsrc[4]           <= 1'b0;   // Set to inactive value(s) when not in this state
       ery_src04                <= 128'b0;
    end


// WAIT_FOR_NEXT_CMD: Nothing to do in this state. It is required to allow the CMD FIFO time to present the next command.
//                    It is needed because 'cmd_complete' doesn't appear until the cycle after WAIT_FOR_RESP_CR. 
//                    There is no way to predictively send 'cmd_complete' in the cycle before to eliminate the need
//                    for this state, because it could stay in WAIT_FOR_RESP_CR indefinitely depending on when the TLX
//                    returns response credits. 


// ERROR: If this state is entered, something went wrong. For instance, a soft error might put the state machine into
//        an illegal state. Because this is a test design, don't try to recover and proceed but instead
//        lock up in this state so the user knows there is an error to go find and fix.


// Determine next state
always @(posedge(clock))
  if (reset == 1'b1) SM_FWM <= SM_FWM_IDLE;   
  else 
    case (SM_FWM)
      SM_FWM_IDLE:            
          if (start_write_mem == 1'b1 || start_pr_wr_mem == 1'b1 || start_write_mem_be == 1'b1) 
                                                  SM_FWM <= SM_FWM_WAIT_FOR_SAM1;
          else                                    SM_FWM <= SM_FWM_IDLE;
      SM_FWM_WAIT_FOR_SAM1:
                                                  SM_FWM <= SM_FWM_WAIT_FOR_SAM2;
      SM_FWM_WAIT_FOR_SAM2:
                                                  SM_FWM <= SM_FWM_WAIT_FOR_DATA;
      SM_FWM_WAIT_FOR_DATA:
          // Check tlx_afu_cmd_data_valid=1 since other condition could match while waiting for data to arrive
          if (tlx_afu_cmd_data_valid == 1'b1 && fwm_flit_addr == fwm_max_flit_addr)
                                                  SM_FWM <= SM_FWM_WAIT_FOR_RESP_CR;
          else                                    SM_FWM <= SM_FWM_WAIT_FOR_DATA;
      SM_FWM_WAIT_FOR_RESP_CR:
          if (tarc_credits_available >= 4'b0001)  SM_FWM <= SM_FWM_WAIT_FOR_NEXT_CMD;
          else                                    SM_FWM <= SM_FWM_WAIT_FOR_RESP_CR;
      SM_FWM_WAIT_FOR_NEXT_CMD:
                                                  SM_FWM <= SM_FWM_IDLE;
      SM_FWM_ERROR:
          SM_FWM <= SM_FWM_ERROR;
      default:
          SM_FWM <= SM_FWM_ERROR;
    endcase
    

// ==============================================================================================================================
// @@@ PRM: Command State Machine - pr_rd_mem
// ==============================================================================================================================

// Combine Partial Read Memory into the Full Read Memory state machine. 

// ==============================================================================================================================
// @@@ FRM: Command State Machine - rd_mem  (Full Read from Memory)
// ==============================================================================================================================


// State Machine for Full Read from Memory (FRM)

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg [3:0]  SM_FRM;                
parameter  SM_FRM_IDLE              = 4'b0000;
parameter  SM_FRM_WAIT_FOR_SAM1     = 4'b0001;
parameter  SM_FRM_WAIT_FOR_SAM2     = 4'b0010;
parameter  SM_FRM_WAIT_FOR_MEM1     = 4'b0011;
parameter  SM_FRM_WAIT_FOR_MEM2     = 4'b0100;
parameter  SM_FRM_WAIT_FOR_MEM3     = 4'b0101;
parameter  SM_FRM_ISSUE_RESPONSE    = 4'b0110;
parameter  SM_FRM_WAIT_FOR_NEXT_CMD = 4'b0111;
parameter  SM_FRM_ERROR             = 4'b1111;   

// Behavior to perform in each state

// IDLE: In this state, we're just waiting for a full read from memory (rd_mem) command to appear from the TLX. 
//       When it does, check that there are enough response and response data credits available to complete
//       the operation before kicking off the state machine. If not, stay in this state until there are.
//       Once enough credits for the 'maximum credit situation' are available, begin the "pipeline"
//       by kicking off the sparse memory translation of the address.
//       Note: For synthesis purposes, break this into a combinational and clocked section.
//
// TLX Implementation Behavior:
//       The TLX can only guarantee valid information on the command interface when valid is 1. It may
//       hold the interface for 2 cycles after valid returns to 0, but this is an artifact of the latency
//       between the array where commands are stored and the interface. The AFU should not rely on the
//       the TLX to present valid information except in the cycle when valid is 1.
//
reg         sam_enable_frm;
reg  [63:0] sam_addr_in_frm;
reg         start_rd_mem_pending;
reg         start_pr_rd_mem_pending;
reg   [1:0] frm_dl;  
reg  [63:0] frm_addr; 
// Note: When the state machine checks credit availability, it has to deal with the case where the 'start' pulse 
//       occurred while there was a lack of credits. To preserve 'start' in this case, latch up a copy of it in
//       a 'pending' register. Then the state machine can start on either the first cycle of command presentation
//       or sometime later. 
//
// Helper signal to know when response and response data credits are available
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire frm_have_resp_credits;
assign frm_have_resp_credits = 
  (  start_rd_mem == 1'b1 &&                                                  // Command is a full read, cmd valid = 1
     tarc_credits_available  >= 4'b0001 &&                                    // 1 response credit
     tardc_credits_available >= ( (cff_cmd_dl == 2'b00) ? 6'b000000 : (       // No response data, will issue fail response later
                                  (cff_cmd_dl == 2'b01) ? 6'b000001 : (       //  64B = 1 response data FLIT
                                  (cff_cmd_dl == 2'b10) ? 6'b000010 :         // 128B = 2 response data FLITs
                                                          6'b000100   )))     // 256B = 4 response data FLITs 
  ) |
  (  start_rd_mem_pending == 1'b1 &&                                         // Command is a full read, cmd valid = 0
     tarc_credits_available  >= 4'b0001 &&                                   // 1 response credit
     tardc_credits_available >= ( (frm_dl     == 2'b00) ? 6'b000000 : (      // No response data, will issue fail response later
                                  (frm_dl     == 2'b01) ? 6'b000001 : (      //  64B = 1 response data FLIT
                                  (frm_dl     == 2'b10) ? 6'b000010 :        // 128B = 2 response data FLITs
                                                          6'b000100   )))    // 256B = 4 response data FLITs 
  ) |
  ( (start_pr_rd_mem == 1'b1 || start_pr_rd_mem_pending == 1'b1) &&          // Command is a partial read (cmd valid doesn't matter)
     tarc_credits_available  >= 4'b0001 &&                                   // 1 response credit
     tardc_credits_available >= 6'b000001                                    // 1 response data FLIT
  );
//
always @(*)    // Combinational
  if (SM_FRM == SM_FRM_IDLE)  // Note: This qualifying condition is redundant until the LPC starts handling pipelined commands.
                              //       But use it as a precaution to prevent a second command from being started if one is being processed.
    begin                             
      // Perform action in the same cycle as seeing cmd_valid to improve performance, or some time later if waiting for enough credits to arrive
      if (start_rd_mem == 1'b1 || start_rd_mem_pending == 1'b1 || start_pr_rd_mem == 1'b1 || start_pr_rd_mem_pending == 1'b1)  
        begin
          // Capture address on cycle when valid = 1
          if (start_pr_rd_mem == 1'b1)  
            sam_addr_in_frm  = cff_cmd_pa[63:0];             // pr_rd_mem carries full address in the command
          else if (start_rd_mem == 1'b1)
            sam_addr_in_frm  = {cff_cmd_pa[63:5], 5'b0};     // rd_mem assumes PA[4:0]=0
          else
            sam_addr_in_frm  = frm_addr;                     // Use the value captured in the next cycle if 'pending'  
          // Determine when to enable SAM separately, start pipeline when have enough response credits
          if (frm_have_resp_credits == 1'b1)
            sam_enable_frm   = 1'b1;                         // Kick off Sparse Array Mapper
          else
            sam_enable_frm   = 1'b0;                         // Wait
        end
      else                                          
        begin                                       // Execute this code block when in IDLE but no read command is going on 
          sam_enable_frm     = 1'b0;
          sam_addr_in_frm    = 64'b0;
        end
    end
  else                                              // In the middle of a rd_mem or pr_rd_mem operation, but not in the IDLE state
    begin
      sam_enable_frm         = 1'b0;
      sam_addr_in_frm        = 64'b0;
    end
// Above is equivalent to:  
// assign sam_enable_frm  = (SM_FRM == SM_FRM_IDLE
//                        && (start_rd_mem == 1'b1 || start_rd_mem_pending == 1'b1 || start_pr_rd_mem == 1'b1 || start_pr_rd_mem_pending == 1'b1) 
//                        && frm_have_resp_credits == 1'b1)
//                           ? 1'b1 : 1'b0;             // Start pipeline by kicking off Sparse Address Mapping
// wire [63:0] temp_addr;
// assign temp_addr = (start_pr_rd_mem == 1'b1) ? cff_cmd_pa[63:0] : 
//                    ( (start_rd_mem == 1'b1) ? {cff_cmd_pa[63:5], 5'b0}; : frm_addr );
// assign sam_addr_in_frm = (SM_FRM == SM_FRM_IDLE
//                        && (start_rd_mem == 1'b1 || start_rd_mem_pending == 1'b1 || start_pr_rd_mem == 1'b1 || start_pr_rd_mem_pending == 1'b1) 
//                        && frm_have_resp_credits == 1'b1)
//                           ? temp_addr : 64'b0;  // Address to map to Bulk Memory entry
//
reg   [2:0] frm_pl;  
//g   [1:0] frm_max_flit_addr;    // Currently not used
reg  [15:0] frm_capptag;
reg         frm_pr_rd_mem;
always @(posedge(clock))     // Use registers to hold command information while this command is being processed
  if (SM_FRM == SM_FRM_IDLE) 
    begin
      if (start_rd_mem == 1'b1 || start_pr_rd_mem == 1'b1)     // Capture interface when command valid = 1
        begin
//        frm_max_flit_addr       <= max_flit_addr;
          frm_capptag             <= cff_cmd_capptag;  
          if (start_rd_mem == 1'b1)                            // Some values are command dependent 
            begin
              frm_dl                  <= cff_cmd_dl;           
              frm_pl                  <= 3'b111;               // Set to reserved value, rd_mem doesn't use pL field
              frm_addr                <= {cff_cmd_pa[63:5], 5'b0};  // rd_mem assumes lower 5 bits are 0
              start_rd_mem_pending    <= 1'b1;                 // Keep processing 'rd_mem'
              start_pr_rd_mem_pending <= 1'b0;                 
              frm_pr_rd_mem           <= 1'b0;                 // Command was not 'pr_rd_mem'
            end
          else                       
            begin
              frm_dl                  <= 2'b01;                // pr_rd_mem assumes 1 FLIT
              frm_pl                  <= cff_cmd_pl;           // Capture pL from command
              frm_addr                <= cff_cmd_pa[63:0];     // pr_rd_mem sends all address bits
              start_rd_mem_pending    <= 1'b0;                  
              start_pr_rd_mem_pending <= 1'b1;                 // Keep processing 'pr_rd_mem'
              frm_pr_rd_mem           <= 1'b1;                 // Command was pr_rd_mem'
            end
        end
      else                                                     // Hold values while 'pending'
        begin
          frm_dl                  <= frm_dl;
          frm_pl                  <= frm_pl;
//        frm_max_flit_addr       <= frm_max_flit_addr;
          frm_capptag             <= frm_capptag;  
          frm_addr                <= frm_addr;
          start_rd_mem_pending    <= start_rd_mem_pending;
          start_pr_rd_mem_pending <= start_pr_rd_mem_pending;
          frm_pr_rd_mem           <= frm_pr_rd_mem;
        end
    end
  else
    begin
      start_rd_mem_pending    <= 1'b0;                     // Clear when out of IDLE state
      start_pr_rd_mem_pending <= 1'b0;                     // Clear when out of IDLE state
      frm_dl                  <= frm_dl;                   // Hold values so state machines below can use contents
      frm_pl                  <= frm_pl;
//    frm_max_flit_addr       <= frm_max_flit_addr;
      frm_capptag             <= frm_capptag;
      frm_addr                <= frm_addr;
      frm_pr_rd_mem           <= frm_pr_rd_mem;            
    end 


// WAIT_FOR_SAM1: In this state, we're waiting for the Sparse Array Map to provide the correct Bulk Memory address.
//                Until this is done, we don't know where to fetch the data from. Thus there is nothing to do in this state.


// WAIT_FOR_SAM2: Capture the mapped Bulk Memory address and match indicators, which are valid to read in this cycle. 
//                Since the SAM look up result and captured TLX inputs are available, determine 
//                how many FLITs to read from the Bulk Memory. There can be 0-4 FLITs read.
//                At the same time, determine the response type and codes since beyond this point the only
//                error that could happen is to read bad data from bulk memory, but that is indicated by the 'bdi' on each FLIT.
//                
// Helper signal: set frm_legal_size to 1 if requested operation was full read and 64, 128, or 256 Bytes in size, or
//                operation was partial read and size is 1,2,4,8,16,32 bytes
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   frm_legal_size;
assign frm_legal_size  = ( (frm_pr_rd_mem == 1'b1 && (frm_pl == 3'b000 || frm_pl == 3'b001 || frm_pl == 3'b010 ||
                                                      frm_pl == 3'b011 || frm_pl == 3'b100 || frm_pl == 3'b101)) ? 1'b1 : 1'b0 
                         ) |   
                         ( (frm_pr_rd_mem == 1'b0 && (frm_dl == 2'b01  || frm_dl == 2'b10  || frm_dl == 2'b11 )) ? 1'b1 : 1'b0
                         );
// Helper signal: set frm_legal_align to 1 if address is naturally aligned to the size
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   frm_legal_align;
assign frm_legal_align = ( (frm_pr_rd_mem == 1'b1 && (
                             (frm_pl == 3'b000                                ) ||  //   1 byte has any alignment
                             (frm_pl == 3'b001 && frm_addr[0]   == 1'b0       ) ||  //   2 bytes
                             (frm_pl == 3'b010 && frm_addr[1:0] == 2'b00      ) ||  //   4 bytes
                             (frm_pl == 3'b011 && frm_addr[2:0] == 3'b000     ) ||  //   8 bytes
                             (frm_pl == 3'b100 && frm_addr[3:0] == 4'b0000    ) ||  //  16 bytes
                             (frm_pl == 3'b101 && frm_addr[4:0] == 5'b00000   ) ||  //  32 bytes
                             (frm_pl == 3'b110                                ) ||  //  64 bytes - treat as legal so resp_code is illegal size
                             (frm_pl == 3'b111                                ) )   // 128 bytes - treat as legal so resp_code is illegal size
                           ) ? 1'b1 : 1'b0
                         ) |   
                         ( (frm_pr_rd_mem == 1'b0 && (
                             (frm_dl == 2'b00                                 ) ||  // Treat reserved as aligned so resp_code is illegal size
                             (frm_dl == 2'b01 && frm_addr[5:0] == 6'b00_0000  ) ||  //  64 Bytes
                             (frm_dl == 2'b10 && frm_addr[6:0] == 7'b000_0000 ) ||  // 128 Bytes
                             (frm_dl == 2'b11 && frm_addr[7:0] == 8'b0000_0000) )   // 256 Bytes
                           ) ? 1'b1 : 1'b0
                         );
//
//g          frm_sam_overflow;   // Currently not used
//g          frm_sam_no_match;   // Currently not used
reg    [7:0] frm_resp_opcode;
reg    [1:0] frm_resp_dl;
reg    [1:0] frm_resp_dp;
reg    [3:0] frm_resp_code;
reg   [63:0] mem_addr_frm;        // All 64 bits carried to bulk mem for future expansion
reg          mem_rden_frm;
reg    [1:0] mem_rdcnt_frm;
always @(posedge(clock))    
  if (SM_FRM == SM_FRM_WAIT_FOR_SAM2)  
    begin                             
//    frm_sam_overflow       <= sam_overflow;             // Capture error conditions
//    frm_sam_no_match       <= sam_no_match;
      // Initiate read from memory
      mem_addr_frm    <= {frm_addr[63:14], sam_addr_out, frm_addr[7:6]};   // [13:2] select 256B entry, [1:0] select the FLIT within entry
      mem_rden_frm    <= 1'b1;
      // Check for errors: address not naturally aligned, illegal size (which includes 00=reserved), bad SAM translation, SAM no match
      // Note: sam_no_match = 1 is OK on write, since data will be written into bulk memory after a new translation entry is added
      //   But sam_no_match = 1 on read may not be not OK, since data read from bulk memory will be X, as it hasn't been initialized.
      //   However some random simulation environments may want this to be OK, so let them suppress this check and allow 
      //   a successful read from uninitialized memory.
      if (frm_legal_align == 1'b0 || frm_legal_size == 1'b0 || sam_overflow == 1'b1 || 
          (sam_no_match == 1'b1 && mmio_out_ignore_nomatch_on_read == 1'b0) )  
        begin                                             // An error occurred
          frm_resp_opcode  <= 8'h02;                      // mem_rd_fail
          frm_resp_dl      <= frm_dl;                     // Response DL matches Command DL indicating all FLITs were covered by response
          frm_resp_dp      <= 2'b00;                      // All FLITs covered by response, so start at 0
          if (frm_legal_align == 1'b0)
            frm_resp_code  <= 4'hB;                       // Address is not aligned properly
          else if (frm_legal_size == 1'b0)
            frm_resp_code  <= 4'h9;                       // Length is not legal, report unsupported size error
          else if (sam_overflow == 1'b1)                  
            frm_resp_code  <= 4'hE;                       // Access to un-implemented address in SAM, use general fail code
          else // if (sam_no_match == 1'b1 && mmio_out_ignore_nomatch_on_read == 1'b0)    
            frm_resp_code  <= 4'hE;                       // Bulk memory will return X's, use general fail code
          mem_rdcnt_frm    <= 2'b00;                      // On mem_rd_fail, issue read of 1 dummy FLIT to keep pipeline position of response
        end
      else
        begin                                             // Operation has no errors
          frm_resp_opcode  <= 8'h01;                      // mem_rd_response
          frm_resp_dl      <= frm_dl;                     // Response DL matches Command DL indicating all FLITs were covered by response
          frm_resp_dp      <= 2'b00;                      // All FLITs covered by response, so start at 0
          frm_resp_code    <= 4'h0;                       // Not used with mem_rd_response
          if (frm_pr_rd_mem == 1'b1)
            mem_rdcnt_frm  <= 2'b00;                      // 1 FLIT only on partial read
          else
            mem_rdcnt_frm  <= ((frm_dl == 2'b01) ? 2'b00 : (    // 1 FLIT  ( 64B)
                               (frm_dl == 2'b10) ? 2'b01 :      // 2 FLITs (128B)
                                                   2'b11   ));  // 4 FLITs (256B)  There is no way for DL to specify 192 Bytes
        end
    end
  else                                          
    begin
//    frm_sam_overflow       <= frm_sam_overflow;         // Hold value
//    frm_sam_no_match       <= frm_sam_no_match;
      frm_resp_opcode        <= frm_resp_opcode;
      frm_resp_dl            <= frm_resp_dl;
      frm_resp_dp            <= frm_resp_dp;
      frm_resp_code          <= frm_resp_code;
      mem_addr_frm           <= 64'b0;
      mem_rden_frm           <= 1'b0;
      mem_rdcnt_frm          <= 2'b00;
    end


// WAIT_FOR_MEM1: Wait a cycle for Bulk Memory to fetch the FLIT data. Nothing to do in this state - however...
//                Because the response opcode has been determined, this state can be used to save the 
//                error vector and trigger an interrupt if the response will be a failing one.
always @(posedge(clock))    
  if (SM_FRM == SM_FRM_WAIT_FOR_MEM1)  
    begin                             
      // If response code is not successful (mem_rd_response), save error information and trigger interrupt
      if (frm_resp_opcode != 8'h01)                    
        begin
          ery_loadsrc[5]     <= 1'b1;              // source 5 = full read from memory state machine
          ery_src05[127:112] <= 16'h0020;          // source 5 = full read from memory state machine
          ery_src05[111:108] <= frm_resp_code;
          ery_src05[    107] <= 1'b0;              // No BDI saved on reads
          ery_src05[106: 87] <= 20'b0;
          ery_src05[ 86: 84] <= frm_pl;
          ery_src05[ 83: 82] <= 2'b0;
          ery_src05[ 81: 80] <= frm_dl;
          ery_src05[ 79: 64] <= frm_capptag;
          ery_src05[ 63:  0] <= frm_addr;
        end
      else
        begin
          ery_loadsrc[5]     <= 1'b0;              // Do not save or trigger interrupt on successful response code
          ery_src05          <= 128'b0;
        end  
    end
  else                                    
    begin
      ery_loadsrc[5]         <= 1'b0;              // Do not save or trigger interrupt when not in this state
      ery_src05              <= 128'b0;
    end


// WAIT_FOR_MEM2: Wait a cycle for Bulk Memory to fetch the FLIT data. Nothing to do in this state.


// WAIT_FOR_MEM3: Wait a cycle for Bulk Memory to fetch the FLIT data. Nothing to do in this state.


// ISSUE_RESPONSE: FLITs from Bulk Memory arrive at the TLX interface on this cycle.
//                 If the response code is fail, then issue the response, consume a resp credit, and suppress all resp_data_valid's.
//                 To keep the pipeline progression the same, cycle through all data FLITs but don't consume a resp_data credit for them
//                 since the TLX won't see them (resp_data_valid = 0).
//                 If the response code is success, then issue the response, consume a resp credit, and for all the FLITs that
//                 are part of the return data set resp_data_valid and consume a resp_data credit.
//
// Helper signal: Reduce check of mem_rd_fail response code down to 1 bit, since used several times in upcoming states
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   frm_fail_resp;
assign frm_fail_resp = (frm_resp_opcode == 8'h02) ? 1'b1 : 1'b0;           
//
// Helper signal: Change encoding of DL into true flit count (0-3)
wire [1:0] frm_flit_cnt;
assign frm_flit_cnt  = (frm_pr_rd_mem == 1'b1) ? 2'b00 :   // 1 FLIT on partial read
                        ( (frm_dl == 2'b01) ? 2'b00 : (    // 1 FLIT  ( 64B)
                          (frm_dl == 2'b10) ? 2'b01 :      // 2 FLITs (128B)
                                              2'b11   ));  // 4 FLITs (256B)  There is no way for DL to specify 192 Bytes
//
reg  [1:0] frm_flits_sent;   // NOTE: Compare frm_flits_sent against frm_flit_cnt because frm_dl has a slightly different encoding.
always @(posedge(clock))  
  if (SM_FRM == SM_FRM_ISSUE_RESPONSE)
    begin 
      // Present response (pass or fail) since it must go back to the TLX
      if (frm_flits_sent == 2'b00)     // First cycle of ISSUE_RESPONSE
        begin 
          afu_tlx_resp_opcode_frm  <= frm_resp_opcode;     // Put response on TLX interface, but might not trigger with resp_valid yet   
          afu_tlx_resp_dl_frm      <= frm_resp_dl;       
          afu_tlx_resp_dp_frm      <= frm_resp_dp;       
          afu_tlx_resp_capptag_frm <= frm_capptag;         // Use saved tag from command
          afu_tlx_resp_code_frm    <= frm_resp_code;   
          afu_tlx_resp_valid_frm   <= 1'b1;                // Present response to TLX
          tarc_consume_credit_frm  <= 4'b0001;             // TLX consumes a credit with resp_valid, so echo that in credit counter
        end
      else 
        begin
          afu_tlx_resp_opcode_frm  <= 8'b0;                // Clear OR inputs when not response is not valid    
          afu_tlx_resp_dl_frm      <= 2'b0;      
          afu_tlx_resp_dp_frm      <= 2'b0;       
          afu_tlx_resp_capptag_frm <= 16'b0; 
          afu_tlx_resp_code_frm    <= 4'b0; 
          afu_tlx_resp_valid_frm   <= 1'b0;                // Mark response not valid
          tarc_consume_credit_frm  <= 4'b0;              // Not consuming another credit since resp is not valid
        end
      // Present data FLITs
      afu_tlx_rdata_bus_frm        <= mem_dout;
      afu_tlx_rdata_bdi_frm        <= mem_dout_bdi;
      if (frm_fail_resp == 1'b0 && frm_flits_sent <= frm_flit_cnt)   // While there is data to present and the response is not a fail response:
        begin
          afu_tlx_rdata_valid_frm  <= 1'b1;                // Mark FLIT as valid
          tardc_consume_credit_frm <= 6'b000001;           // TLX consumes a data credit with resp_valid, so echo that in credit counter
        end
      else
        begin
          afu_tlx_rdata_valid_frm  <= 1'b0;                // Mark FLIT as invalid so TLX doesn't see it
          tardc_consume_credit_frm <= 6'b0;            // No data credit consumption since there is no rdata_valid returned
        end
      // If this is the last cycle, send command credit back to TLX. Also increment frm_flits_sent until reach the last one.
      if (frm_flits_sent == frm_flit_cnt)
        begin
          cmd_complete_frm         <= 1'b1;                // Issue credit to TLX to get next cmd
          frm_flits_sent           <= 2'b00;               // Initialize for the next cmd, which may be back to back
        end
      else
        begin
          cmd_complete_frm         <= 1'b0;                    // Don't issue credit yet
          frm_flits_sent           <= frm_flits_sent + 2'b01;  // But increment the number of FLITs sent
        end
    end  
  else                                                    // Not in ISSUE_RESPONSE state
    begin
      afu_tlx_resp_opcode_frm  <= 8'b0;                   // Clear OR inputs when not response is not valid    
      afu_tlx_resp_dl_frm      <= 2'b0;      
      afu_tlx_resp_dp_frm      <= 2'b0;       
      afu_tlx_resp_capptag_frm <= 16'b0; 
      afu_tlx_resp_code_frm    <= 4'b0; 
      afu_tlx_resp_valid_frm   <= 1'b0;                
      tarc_consume_credit_frm  <= 4'b0;              
      afu_tlx_rdata_bus_frm    <= 512'b0;
      afu_tlx_rdata_bdi_frm    <= 1'b0;
      afu_tlx_rdata_valid_frm  <= 1'b0;               
      tardc_consume_credit_frm <= 6'b0;          
      cmd_complete_frm         <= 1'b0;      
      frm_flits_sent           <= 2'b00;                  // Note: This initializes flit_sent
    end


// WAIT_FOR_NEXT_CMD: Nothing to do in this state. It is required to allow the CMD FIFO time to present the next command.
//                    It is needed because 'cmd_complete' doesn't appear until the cycle after the last FLIT is sent. 
//                    While possible, it complicates the logic significantly to predictively send 'cmd_complete' 
//                    in the cycle before to eliminate the need for this state, so instead just insert this extra cycle. 
//                    (i.e. When sending 1 FLIT, the extra cycle is needed. When sending 2-4 FLITs, 'cmd_complete' could
//                    be sent a cycle before.) Since this state machine is only engaged in the low performance case
//                    don't worry about the extra state. In the pipelined version of reads, the need for
//                    the extra cycle should be eliminated.


// ERROR: If this state is entered, something went wrong. For instance, a soft error might put the state machine into
//        an illegal state. Because this is a test design, don't try to recover and proceed but instead
//        lock up in this state so the user knows there is an error to go find and fix.


// Determine next state
always @(posedge(clock))
  if (reset == 1'b1) SM_FRM <= SM_FRM_IDLE;   
  else 
    case (SM_FRM)
      SM_FRM_IDLE: 
          if ( (start_rd_mem == 1'b1    || start_rd_mem_pending == 1'b1     ||
                start_pr_rd_mem == 1'b1 || start_pr_rd_mem_pending == 1'b1) &&
                frm_have_resp_credits == 1'b1
             )                                  SM_FRM <= SM_FRM_WAIT_FOR_SAM1;
          else                                  SM_FRM <= SM_FRM_IDLE;
      SM_FRM_WAIT_FOR_SAM1:
                                                SM_FRM <= SM_FRM_WAIT_FOR_SAM2;
      SM_FRM_WAIT_FOR_SAM2:
                                                SM_FRM <= SM_FRM_WAIT_FOR_MEM1;
      SM_FRM_WAIT_FOR_MEM1:
                                                SM_FRM <= SM_FRM_WAIT_FOR_MEM2;
      SM_FRM_WAIT_FOR_MEM2:
                                                SM_FRM <= SM_FRM_WAIT_FOR_MEM3;
      SM_FRM_WAIT_FOR_MEM3:
                                                SM_FRM <= SM_FRM_ISSUE_RESPONSE;
      SM_FRM_ISSUE_RESPONSE:
          if (frm_flits_sent == frm_flit_cnt)   SM_FRM <= SM_FRM_WAIT_FOR_NEXT_CMD;      // wait for all FLITs to be presented
          else                                  SM_FRM <= SM_FRM_ISSUE_RESPONSE;    
      SM_FRM_WAIT_FOR_NEXT_CMD:
                                                SM_FRM <= SM_FRM_IDLE;
      SM_FRM_ERROR:
                                                SM_FRM <= SM_FRM_ERROR;
      default:
                                                SM_FRM <= SM_FRM_ERROR;
    endcase
    


// ==============================================================================================================================
// @@@ SAM: Sparse Address Mapping
// ==============================================================================================================================
// Address In from command:
// [63:8] = Physical Address from host, used by Sparse Array Map to associate with a 256B entry in the Bulk Memory
//  [7:6] = Used to select 1 of 4 rows within 256B entry, where each row contains a 64B FLIT (passed through directly, no address mapping)
//  [5:0] = Used to determine byte write enables within 64 bytes of a FLIT 
// Address Out to bulk memory:
// [11:0] = Used to select a single entry in the 1 MB Bulk Memory, where each entry is 256B (max write or read size)
//
// NOTE: These are the bit fields as bulk memory and lpc_afu sees them. The SAM implementation may adjust the mapping of physical address
//       to address out to bulk memory based on implementation restrictions.

wire        sam_enable;
wire [63:0] sam_addr_in;

// OR sources to get address into SAM and Bulk Memory. Important: Signals from inactive state machines must be 0.
assign sam_enable  = sam_enable_fwm  | sam_enable_frm  | sam_enable_pip ;
assign sam_addr_in = sam_addr_in_fwm | sam_addr_in_frm | sam_addr_in_pip;   

lpc_sparse SAM (
    .clock            ( clock                )
  , .reset            ( reset                )
  , .sam_enable       ( sam_enable           )
  , .sam_addr_in      ( sam_addr_in[63:8]    ) // Select which bulk memory entry of 256B to target, bits [7:0] index into the entry
  , .sam_addr_out     ( sam_addr_out         )
  , .sam_entries_open ( sam_entries_open     ) // Number of cross references in the SAM that are un-used
  , .sam_overflow     ( sam_overflow         ) // All cross references in the SAM are used when one more comes in
  , .sam_no_match     ( sam_no_match         ) // When 1, SAM consumed a mapping resource with the current sam_addr_in value
  , .sam_disable      ( mmio_out_sam_disable ) // When 1, SAM does no mapping and just passes addresses through unchanged
);


// ==============================================================================================================================
// @@@ BM: Bulk Memory
// ==============================================================================================================================

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire  [63:0] mem_addr;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire  [63:0] mem_wren;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         mem_rden;
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   [1:0] mem_rdcnt;
// `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire         mem_din_bdi;
// `ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [511:0] mem_din;

// Decode of mem_addr:
//  Bits [5:0] of cmd address are used to create byte write enables on partial write. On each access, entire 64B FLIT is written or read. 
//  Thus mem_addr[ 1:0] select one of four FLITs in the 256B entry
//  and  mem_addr[13:2] select which 256B entry in the bulk memory to target
//  Note: For 1 MB bulk memory size, have 4096 entries of size 256B
//        [13]   selects one of two BRAMs (lower or upper block of 2048 entries)
//        [12:2] select  one of 2048 entries of 256B within a BRAM (8192 rows total/4 rows per 256B entry)
//        [ 1:0] select  one of four 64B FLIT/rows that make up a 256B entry
//  Note: To allow easier future changes, carry all 64 bits into lpc_bulk_mem even though it may only use a lower subset.


// OR data from different state machines to get resultant information into bulk memory. Important: Signals from inactive state machines must be 0.
assign mem_addr    = mem_addr_fwm    | mem_addr_frm  | mem_addr_pip; 
assign mem_wren    = mem_wren_fwm    | mem_wren_pip  ; 
assign mem_rden    = mem_rden_frm    | mem_rden_pip  ; 
assign mem_rdcnt   = mem_rdcnt_frm   | mem_rdcnt_pip ;
assign mem_din     = mem_din_fwm     | mem_din_pip   ; 
assign mem_din_bdi = mem_din_bdi_fwm | mem_din_bdi_pip ;

lpc_bulk_mem MEM (
    .clock        ( clock            )   // Clock - samples & launches data on rising edge
  , .reset        ( reset            )   // Reset - when 1 set control logic to default state
  , .addr         ( mem_addr         )   // Address - selects the target row
  , .wren         ( mem_wren         )   // Write enable[63:0], 1 bit per byte. When 1, associated byte on 'din' is written into array. 
  , .rden         ( mem_rden         )   // Read enable - when 1 start reading FLITs from memory starting at 'addr'
  , .rdcnt        ( mem_rdcnt        )   // Read count - how many FLITs to read (00=1, 01=2, 10=3, 11=4) when rden=1
  , .din_bdi      ( mem_din_bdi      )   // Data In Bad Data Indicator - marks written FLIT as bad
  , .din          ( mem_din          )   // Data In  - data goes directly into array, loaded on next rising clock edge
  , .dout_bdi     ( mem_dout_bdi     )   // Data Out Bad Data Indicator - indicates read FLIT is bad
  , .dout         ( mem_dout         )   // Data Out - data from array is registered before presentation on Data Out
  , .err_multiops ( mem_err_multiops )   // Collision of write and read attempted at the same time. This should be treated as a fatal error.
  , .err_boundary ( mem_err_boundary )   // The combination of starting addr and number of FLITs exceeds the 256 Byte boundary.
  , .err_internal ( mem_err_internal )   // An internal condition that should never happen occurred.
);


// ==============================================================================================================================
// @@@ ERY: Error vector array
// ==============================================================================================================================

lpc_errary ERY (
    .clock                 ( clock                 ) // Clock - samples & launches data on rising edge
  , .reset                 ( reset                 ) // When 1, clear all cross reference logic to the 'unallocated' state
  , .ery_loadsrc           ( ery_loadsrc           ) // When bit is 1, load the error information from the corresponding source into the array 
  , .ery_src15             ( ery_src15             ) // Vector of data to save from error source
  , .ery_src14             ( ery_src14             ) 
//, .ery_src13             ( ery_src13             ) 
//, .ery_src12             ( ery_src12             ) 
//, .ery_src11             ( ery_src11             ) 
//, .ery_src10             ( ery_src10             ) 
  , .ery_src09             ( ery_src09             ) 
  , .ery_src08             ( ery_src08             )  
  , .ery_src07             ( ery_src07             )
  , .ery_src06             ( ery_src06             )
  , .ery_src05             ( ery_src05             ) 
  , .ery_src04             ( ery_src04             ) 
  , .ery_src03             ( ery_src03             ) 
  , .ery_src02             ( ery_src02             ) 
  , .ery_src01             ( ery_src01             ) 
  , .ery_src00             ( ery_src00             ) 
  , .ery_data_out          ( ery_data_out          ) // Contents of oldest error vector in the FIFO
  , .ery_data_valid        ( ery_data_valid        ) // When 1, contents of ery_data_out are valid. This triggers an interrupt to the host.
  , .ery_data_done         ( ery_data_done         ) // Pulsed to 1 when the current valid error vector has been read by software
  , .ery_simultaneous_load ( ery_simultaneous_load ) // When 1, multiple loadsrc bits were on in the same cycle
  , .ery_overflow          ( ery_overflow          ) // When 1, error FIFO was full when another loadsrc arrived
  , .ery_trigger_intrp     ( ery_trigger_intrp     ) // When pulsed (0-1-0), send an interrupt to the host 
);


// ==============================================================================================================================
// @@@ MMIO: MMIO Registers
// ==============================================================================================================================

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire [63:0] mmio_out_captured_errors;      // Test benches can probe this vector to see if any errors occurred 
wire        mmio_ery_loadsrc15;            // For proper reg/wire conversion
wire        mmio_ery_loadsrc14;            // For proper reg/wire conversion

reg  [63:0] mmio_in_captured_errors_q;     // Register incoming error signals to aid in timing closure
always @(posedge(clock))
  mmio_in_captured_errors_q <= mmio_in_captured_errors;

lpc_mmio_regs MMIO (
    .clock                               ( clock                            )
  , .reset                               ( reset                            )
    // Functional interface
  , .mmio_addr                           ( mmio_addr                        )
  , .mmio_wdata                          ( mmio_wdata                       )
  , .mmio_rdata                          ( mmio_rdata                       )
  , .mmio_rdata_vld                      ( mmio_rdata_vld                   )                                         
  , .mmio_wr_1B                          ( mmio_wr_1B                       )                                   
  , .mmio_wr_2B                          ( mmio_wr_2B                       )                                              
  , .mmio_wr_4B                          ( mmio_wr_4B                       )         
  , .mmio_wr_8B                          ( mmio_wr_8B                       )    
  , .mmio_rd                             ( mmio_rd                          )                                      
  , .mmio_bad_op_or_align                ( mmio_bad_op_or_align             )   
  , .mmio_addr_not_implemented           ( mmio_addr_not_implemented        )                                        
    // Inputs for readable MMIO fields
  , .mmio_in_captured_errors             ( mmio_in_captured_errors_q        )                                        
  , .mmio_in_status                      ( mmio_in_status                   )                                   
  , .mmio_ery_data_out                   ( ery_data_out                     )
  , .mmio_in_intrp_is_pending            ( mmio_in_intrp_is_pending         )
    // Writable MMIO fields used within the design
  , .mmio_out_sam_disable                ( mmio_out_sam_disable             )
  , .mmio_out_ignore_nomatch_on_read     ( mmio_out_ignore_nomatch_on_read  )
  , .mmio_out_enable_pipeline            ( mmio_out_enable_pipeline         )
  , .mmio_out_captured_errors            ( mmio_out_captured_errors         ) 
  , .mmio_out_intrp_ea                   ( mmio_out_intrp_ea                )
  , .mmio_out_intrp_vec_mask             ( mmio_out_intrp_vec_mask          )
  , .mmio_out_intrp_pasid                ( mmio_out_intrp_pasid             )
  , .mmio_out_intrp_cmd_flag             ( mmio_out_intrp_cmd_flag          )
  , .mmio_out_intrp_stream_id            ( mmio_out_intrp_stream_id         )
  , .mmio_out_intrp_afutag               ( mmio_out_intrp_afutag            )
    // Control outputs
  , .mmio_ery_data_done                  ( ery_data_done                    )
  , .mmio_ery_loadsrc15                  ( mmio_ery_loadsrc15               )
  , .mmio_ery_src15                      ( ery_src15                        )
  , .mmio_ery_loadsrc14                  ( mmio_ery_loadsrc14               )
  , .mmio_ery_src14                      ( ery_src14                        )
) ;

always @(*)
  begin
    ery_loadsrc[15] = mmio_ery_loadsrc15;    // For proper reg/wire conversion
    ery_loadsrc[14] = mmio_ery_loadsrc14;    
  end


// ***************************************************************************************
// ***************************************************************************************
// @@@ Part 2: AFU -> Host Commands, Host -> AFU Responses
// ***************************************************************************************
// ***************************************************************************************


// ==============================================================================================================================
// @@@ RESPDEC: Response Decode - When see valid response from TLX, decode it 
// ==============================================================================================================================

// These signals are pulsed individually, based on the opcode
//   received_nop          ; // Opcode x00 (abbreviation RNO = Received NO operation )
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire received_intrp_resp   ; // Opcode x0C (abbreviation IRP = Interrupt ResPonse    )
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire received_intrp_rdy    ; // Opcode x1A (abbreviation IRY = Interrupt ReadY       )
//   received_read_resp    ; // Opcode x04 (abbreviation RRP = Read ResPonse         )  // For Test Mode 1
//   received_read_failed  ; // Opcode x05 (abbreviation RFL = Read FaiLed           )  // For Test Mode 1
//   received_write_resp   ; // Opcode x08 (abbreviation WRP = Write ResPonse        )  // For Test Mode 1
//   received_write_failed ; // Opcode x09 (abbreviation WFL = Write FaiLed          )  // For Test Mode 1


// Three conditions must be met to start processing a response:
// a) The TLX must indicate it is ready (presumed to be true, if not AFU would not have issued the command waiting for a response)
// b) The TLX must present a valid response indicator
// c) The opcode must decode properly
// Notes:
// - This LPC version relies on the AFU sending only 1 cmd_credit back to the TLX at a time to prevent multiple commands from being started in parallel
// - The 'received' signals should be a single cycle pulse, because resp_valid is a pulse from the TLX (1 pulse per presented command)
assign received_intrp_resp   = (tlx_afu_resp_valid == 1'b1 && tlx_afu_resp_opcode == 8'h0C) ? 1'b1 : 1'b0;
assign received_intrp_rdy    = (tlx_afu_resp_valid == 1'b1 && tlx_afu_resp_opcode == 8'h1A) ? 1'b1 : 1'b0;
//sign received_read_resp    = (tlx_afu_resp_valid == 1'b1 && tlx_afu_resp_opcode == 8'h04) ? 1'b1 : 1'b0;
//sign received_read_failed  = (tlx_afu_resp_valid == 1'b1 && tlx_afu_resp_opcode == 8'h05) ? 1'b1 : 1'b0;
//sign received_write_resp   = (tlx_afu_resp_valid == 1'b1 && tlx_afu_resp_opcode == 8'h08) ? 1'b1 : 1'b0;
//sign received_write_failed = (tlx_afu_resp_valid == 1'b1 && tlx_afu_resp_opcode == 8'h09) ? 1'b1 : 1'b0;

// --- Detect fatal error conditions ---

// These conditions will generate an interrupt and will stop the AFU from responding to further host commands.
// This is because no response credit will be returned, which means the TLX will not be permitted to present the next response to the AFU.
// In this version of the design, fatal error signals will pulse and be logged in the MMIO error register associated with fatal errors.
// - 'received_bad_op' will hang because there is no state machine started to return a response credit to the TLX

assign received_bad_op = (tlx_afu_resp_valid == 1'b1 &&  
                        !(  received_intrp_resp | received_intrp_rdy 
                       // | received_read_resp  | received_read_failed | received_write_resp | received_write_failed
                         ) ) ? 1'b1 : 1'b0;


// ==============================================================================================================================
// @@@ ACTAG: Manage 'acTag'
// ==============================================================================================================================


wire [11:0] actag_first;      // First legal actag value to use for this AFU
wire [11:0] actag_last;       // Last  legal actag value to use for this AFU
wire [12:0] actag_sum;
wire        actag_sum_err;    // When 1, combination of actag_base and length_enabled overflows 12 bits

assign actag_first   = acs_actag_base;                                         
assign actag_sum     = {1'b0,acs_actag_base} + {1'b0,acs_actag_len_enabled};   
assign actag_last    = actag_sum[11:0];
assign actag_sum_err = actag_sum[12];    // Only check when issuing an interrupt (fold into irq_acs_settings_err below)

// Detect if BDF or PASID changed value

// First, create copy of BDF and PASID of previous cycle to detect when it changes
reg  [15:0] afu_old_bdf;
reg  [19:0] afu_old_pasid; 
always @(posedge(clock))                 
  begin
    afu_old_bdf   <= afu_tlx_cmd_bdf_int;    
    afu_old_pasid <= mmio_out_intrp_pasid;
  end

// Then set a 'changed' bit when either changes. Clear it when an 'assign_actag' command is sent by a sequencer. 
// The state of this bit tells the AFU-Host command sequencer if it needs to preface the command with 'assign_actag'.
// Note: Setting takes precedence over clearing in case of collision.
reg         irq_assign_actag_sent;
wire        tm1_assign_actag_sent;  // One 'sent' signal per AFU->Host command sequencer
reg         bdf_pasid_changed;
always @(posedge(clock))
  if (reset == 1'b1)
    bdf_pasid_changed <= 1'b1;      // Cause assign_actag to be sent on first intrp_req, even if BDF or PASID did not change
  else if (afu_old_bdf != afu_tlx_cmd_bdf_int || afu_old_pasid != mmio_out_intrp_pasid) // set if BDF or PASID changed 
    bdf_pasid_changed <= 1'b1;
  else if (irq_assign_actag_sent == 1'b1 || tm1_assign_actag_sent == 1'b1)              // clear if either sequencer sent assign_actag
    bdf_pasid_changed <= 1'b0;
  else
    bdf_pasid_changed <= bdf_pasid_changed;


wire [11:0] actag_to_use;             // Selected actag value to use
assign actag_to_use = actag_first;    // Temporary?

// Configuration space checks on PASID settings
wire   pasid_acs_settings_err;
assign pasid_acs_settings_err = ( intrp_count > 3'b000 && irq_ok_to_send_intrp == 1'b1 &&  // Check when intrp is pending and other checks allow it
                                  !(acs_pasid_length_enabled >= 5'b0 &&     // Number of PASID's allowed by software must be >= 1 (2^0)
                                    acs_pasid_base <= mmio_out_intrp_pasid) // Starting PASID must be at or before the value set in MMIO space
                                ) ? 1'b1 : 1'b0;
                                

// ==============================================================================================================================
// @@@ TERM: Manage process ID terminate interface with config space
// ==============================================================================================================================
// Note:
//   The interrupt reporting mechanism in the LPC is more of a general resource, even though it consumes a PASID.
//   The ACS termination interface was intended to reset specific processes, so doesn't make sense to apply it to 
//   the general interrupt. There are several other ways software can prevent interrupts from being issued, so the
///  LPC doesn't support this feature.

assign cfg_terminate_in_progress = 1'b0;  // Tie to 0


      
// ==============================================================================================================================
// @@@ IRQ: Interrupt Request
// ==============================================================================================================================


// 1) Determine if host has configured the configuration space and MMIOs to allow interrupts to be generated

assign irq_ok_to_send_intrp  = ( acs_enable_afu == 1'b1 &&         // AFU must be enabled to initiate commands to the host, and
                                 mmio_out_intrp_vec_mask == 1'b0   // general error interrupt must be unmasked (enabled)
                               ) ? 1'b1 : 1'b0;

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   irq_acs_settings_err;   // If enabled, check these other interrupt related fields when an interrupt needs to be sent
assign irq_acs_settings_err = ( intrp_count > 3'b000 && irq_ok_to_send_intrp == 1'b1 &&   // Check when intrp is pending and other checks allow it
                                actag_sum_err == 1'b1 // acTag field overflows when adding base and length_supported
                              ) ? 1'b1 : 1'b0;


// 2) Accumulate interrupt requests (i.e. more errors may happen while an interrupt is in progress)
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   trigger_intrp;
assign trigger_intrp = (ery_trigger_intrp & irq_ok_to_send_intrp);   // An interrupt needs to be sent, but interrupts need to be enabled

reg    intrp_count_dec;  // When 1, decrement interrupt count (i.e. an interrupt has been sent)
always @(posedge(clock))
  if (reset == 1'b1)
    intrp_count <= 3'b000;
  else if (trigger_intrp == 1'b1 && intrp_count_dec == 1'b0)  // Increment 
    intrp_count <= intrp_count + 3'b001;
  else if (trigger_intrp == 1'b1 && intrp_count_dec == 1'b1)  // Decrement
    intrp_count <= intrp_count - 3'b001;
  else                                                        // Hold if both or neither Increment & Decrement are active
    intrp_count <= intrp_count;

// Use intrp_count to tell MMIO register that at least 1 interrupt is pending 
assign mmio_in_intrp_is_pending = (intrp_count > 3'b000) ? 1'b1 : 1'b0;  


// 3) Create lock on the AFU->Host interface, as interrupts can happen anytime
reg   lock_afu_to_host_intf;
reg   lock_afu_to_host_intf_set_irq;
wire  lock_afu_to_host_intf_set_tm1;
reg   lock_afu_to_host_intf_clr_irq;
wire  lock_afu_to_host_intf_clr_tm1;
always @(posedge(clock))
  if (reset == 1'b1)
    lock_afu_to_host_intf <= 1'b0;  // Clear lock on reset
  else if ( lock_afu_to_host_intf_set_irq == 1'b1 || lock_afu_to_host_intf_set_tm1 == 1'b1)
    lock_afu_to_host_intf <= 1'b1;  // Set the lock
  else if ( lock_afu_to_host_intf_clr_irq == 1'b1 ||  lock_afu_to_host_intf_clr_tm1 == 1'b1)
    lock_afu_to_host_intf <= 1'b0;  // Clear lock via functional means
  else
    lock_afu_to_host_intf <=  lock_afu_to_host_intf;  // Hold
// Flag an error if someone tries to set a lock when it is already in place, or tries to clear a lock that is not in place
assign err1_lock_afu_to_host_intf = ( (lock_afu_to_host_intf_set_irq == 1'b1 || lock_afu_to_host_intf_set_tm1 == 1'b1) &&  lock_afu_to_host_intf == 1'b1) ? 1'b1 : 1'b0;
assign err2_lock_afu_to_host_intf = ( (lock_afu_to_host_intf_clr_irq == 1'b1 || lock_afu_to_host_intf_clr_tm1 == 1'b1) &&  lock_afu_to_host_intf == 1'b0) ? 1'b1 : 1'b0;


// 4) Interrupt Generation state machine

`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
reg  [3:0] SM_IRQ;
parameter  SM_IRQ_IDLE              = 4'b0000;
parameter  SM_IRQ_GET_LOCK          = 4'b0001;
parameter  SM_IRQ_SEND_INTRP        = 4'b0010;
parameter  SM_IRQ_WAIT_FOR_RESP     = 4'b0011;
parameter  SM_IRQ_RETRY_AFTER_DELAY = 4'b0100;
parameter  SM_IRQ_WAIT4_INTRP_RDY   = 4'b0101;
parameter  SM_IRQ_CLEAN_UP          = 4'b0110;
parameter  SM_IRQ_CLEAN_UP2         = 4'b0111;
parameter  SM_IRQ_ERROR             = 4'b1111;


// Behavior to perform in each state


// IDLE: No behavior to perform. When trigger comes along, jump to GET_LOCK state.


// GET_LOCK: Use to get the interface lock and send 'assign_actag' if it needs to be sent. 
// If it doesn't need to be, then just get the lock. If lock is unavailable, wait here until it becomes free.
// Also ensure the TLX can accept a command before proceeding.
always @(posedge(clock))
  if (SM_IRQ == SM_IRQ_GET_LOCK)
    begin
      if (irq_ok_to_send_intrp == 1'b1 && lock_afu_to_host_intf == 1'b0 && tacc_credits_available > 4'b0) // Interface is available and TLX can accept command
        begin
          lock_afu_to_host_intf_set_irq <= 1'b1;    // Lock interface for interrupt sequencer
          if (bdf_pasid_changed == 1'b1)            // Send 'assign_actag' if it needs to be sent
            begin
              // afu_tlx_cmd_bdf is always driven by BDF from LPC's config space
              afu_tlx_cmd_pasid_irq    <= mmio_out_intrp_pasid;
              afu_tlx_cmd_actag_irq1   <= actag_to_use;
              afu_tlx_cmd_opcode_irq1  <= 8'h50;
              afu_tlx_cmd_valid_irq1   <= 1'b1;
              irq_assign_actag_sent    <= 1'b1;     // Clear indicator that assign_actag needs to be sent
              tacc_consume_credit_irq1 <= 4'b0001;  // Consume 1 command credit when sending 'assign_actag'
            end
          else                                      // 'assign_actag' is not needed or need to wait for command credit
            begin
              afu_tlx_cmd_pasid_irq    <= 20'b0;
              afu_tlx_cmd_actag_irq1   <= 12'b0;
              afu_tlx_cmd_opcode_irq1  <= 8'h00;
              afu_tlx_cmd_valid_irq1   <= 1'b0;
              irq_assign_actag_sent    <= 1'b0;    
              tacc_consume_credit_irq1 <= 4'b000;
            end
        end
      else                                          // Wait for AFU to be enabled, lock to free, and at least 1 TLX command credit 
        begin
          lock_afu_to_host_intf_set_irq <= 1'b0;
          afu_tlx_cmd_pasid_irq         <= 20'b0;
          afu_tlx_cmd_actag_irq1        <= 12'b0;
          afu_tlx_cmd_opcode_irq1       <= 8'h00;
          afu_tlx_cmd_valid_irq1        <= 1'b0;
          irq_assign_actag_sent         <= 1'b0;    
          tacc_consume_credit_irq1      <= 4'b0;
        end
    end
  else                                              // not in this state
    begin
      lock_afu_to_host_intf_set_irq <= 1'b0;
      afu_tlx_cmd_pasid_irq         <= 20'b0;
      afu_tlx_cmd_actag_irq1        <= 12'b0;
      afu_tlx_cmd_opcode_irq1       <= 8'h00;
      afu_tlx_cmd_valid_irq1        <= 1'b0;
      irq_assign_actag_sent         <= 1'b0;    
      tacc_consume_credit_irq1      <= 4'b0;
    end


// SEND_INTRP: Once the TLX can accept it, send the 'intrp_req' command to the host.
always @(posedge(clock))
  if (SM_IRQ == SM_IRQ_SEND_INTRP)
    begin
      if (tacc_credits_available > 4'b0000)        // Wait for TLX to have a command credit available
        begin
          afu_tlx_cmd_stream_id_irq <= mmio_out_intrp_stream_id;
          afu_tlx_cmd_actag_irq2    <= actag_to_use;
          afu_tlx_cmd_flag_irq      <= mmio_out_intrp_cmd_flag;
          afu_tlx_cmd_ea_or_obj_irq <= { 4'b0000, mmio_out_intrp_ea };  // Extra upper bits not used on 'intrp_req'
          afu_tlx_cmd_afutag_irq    <= mmio_out_intrp_afutag;
          afu_tlx_cmd_opcode_irq2   <= 8'h58;
          afu_tlx_cmd_valid_irq2    <= 1'b1;
          tacc_consume_credit_irq2  <= 4'b0001;    // Consume 1 command credit when sending interrupt
        end
      else                                         // TLX is not ready to receive a command, so wait
        begin
          afu_tlx_cmd_stream_id_irq <= 4'b0;
          afu_tlx_cmd_actag_irq2    <= 12'b0;
          afu_tlx_cmd_flag_irq      <= 4'b0;
          afu_tlx_cmd_ea_or_obj_irq <= 68'b0;  
          afu_tlx_cmd_afutag_irq    <= 16'b0;
          afu_tlx_cmd_opcode_irq2   <= 8'h00;
          afu_tlx_cmd_valid_irq2    <= 1'b0;
          tacc_consume_credit_irq2  <= 4'b0;
        end
    end    
  else                                             // State machine is not in this state
    begin
      afu_tlx_cmd_stream_id_irq <= 4'b0;
      afu_tlx_cmd_actag_irq2    <= 12'b0;
      afu_tlx_cmd_flag_irq      <= 4'b0;
      afu_tlx_cmd_ea_or_obj_irq <= 68'b0;  
      afu_tlx_cmd_afutag_irq    <= 16'b0;
      afu_tlx_cmd_opcode_irq2   <= 8'h00;
      afu_tlx_cmd_valid_irq2    <= 1'b0;
      tacc_consume_credit_irq2  <= 4'b000;
    end


// WAIT_FOR_RESP: Wait for the TLX to present a response to the intrp_req. 
// Depending on the resp_code, take different actions.
//  resp_code = 0000  Interrupt was accepted.  Goto CLEAN_UP.
//  resp_code = 0010  Wait long delay, then resend intrp_req. Jump to RETRY_AFTER_DELAY.
//  resp_code = 0100  Wait for intrp_rdy to arrive. Jump to SEND_INTRP.
//  resp_code = 1000, 1001, 1011, 1110  Severe failure on host. Log error, jump to SM_IRQ_ERROR.
//  resp_code = anything else (i.e. reserved code)  Log error, jump to SM_IRQ_ERROR.
//  For all resp_codes, send response credit to TLX indicating AFU can accept another response.
always @(posedge(clock))
  if (SM_IRQ == SM_IRQ_WAIT_FOR_RESP)
    begin
      if (received_intrp_resp == 1'b1)
        begin
          afu_tlx_resp_credit_irq1 <= 1'b1;              // AFU got the response, tell TLX it can send another one
          // Check for these errors. If one occurs, capture error diagnosis information.
          // - AFUTag in response does not match AFUTag sent in request
          // - resp_code is error or reserved code
          if (tlx_afu_resp_afutag != mmio_out_intrp_afutag ||  // AFUTag didn't match OR
              !(tlx_afu_resp_code == 4'b0000 ||          // response code was not: Interrupt was accepted,
                tlx_afu_resp_code == 4'b0010 ||          //   Wait for long delay, or
                tlx_afu_resp_code == 4'b0100  )       )  //   Wait for intrp_rdy
            begin
              ery_loadsrc[6]     <= 1'b1;
              ery_src06[127:112] <= 16'h0040;
              ery_src06[111:108] <= tlx_afu_resp_code;
              ery_src06[107: 32] <= 76'b0;
              ery_src06[ 31: 16] <= tlx_afu_resp_afutag;
              ery_src06[ 15:  0] <= mmio_out_intrp_afutag;
            end
          else 
            begin
              ery_loadsrc[6]     <= 1'b0;
              ery_src06          <= 128'b0;
            end
        end
      else                                               // Waiting for response to show up
        begin
          afu_tlx_resp_credit_irq1 <= 1'b0;              // Do not give a credit back
          ery_loadsrc[6]           <= 1'b0;              // No error to report
          ery_src06                <= 128'b0;
        end
    end
  else                                                   // not in this state
    begin
      afu_tlx_resp_credit_irq1 <= 1'b0;                  // Do not give a credit back
      ery_loadsrc[6]           <= 1'b0;                  // No error to report
      ery_src06                <= 128'b0;
    end


// RETRY_AFTER_DELAY: Wait for "long" delay to expire, then reissue 'intrp_req'
reg [35:0] irq_delay_count;
always @(posedge(clock))
  if (SM_IRQ == SM_IRQ_RETRY_AFTER_DELAY)
    irq_delay_count <= irq_delay_count - 36'h0_0000_0001;       // Decrement each cycle. 'next state' section checks when = 0.
  else                                         
    irq_delay_count <= acs_long_backoff_timer;                   // Initialize counter to programmed delay



// WAIT4_INTRP_RDY: Wait for 'intrp_rdy' to arrive, then reissue 'intrp_req'
// Depending on the resp_code, take different actions.
//  resp_code = 0000  Host is ready to receive interrupt. Goto SEND_INTRP.
//  resp_code = 0010  Wait long delay, then resend intrp_req. Jump to RETRY_AFTER_DELAY.
//  resp_code = 1110  Severe failure on host. Log error, jump to SM_IRQ_ERROR.
//  resp_code = anything else (i.e. reserved code)  Log error, jump to SM_IRQ_ERROR.
//  For all resp_codes, send response credit to TLX indicating AFU can accept another response.
always @(posedge(clock))
  if (SM_IRQ == SM_IRQ_WAIT4_INTRP_RDY)
    begin
      if (received_intrp_rdy == 1'b1)
        begin
          afu_tlx_resp_credit_irq2 <= 1'b1;              // AFU got the response, tell TLX it can send another one
          // Check for these errors. If one occurs, capture error diagnosis information.
          // - AFUTag in response does not match AFUTag sent in request
          // - resp_code is error or reserved code
          if (tlx_afu_resp_afutag != mmio_out_intrp_afutag ||  // AFUTag didn't match OR
              !(tlx_afu_resp_code == 4'b0000 ||                // response code was not: Retry intrp_req, or
                tlx_afu_resp_code == 4'b0010 )              )  //   Wait for long delay
            begin
              ery_loadsrc[7]     <= 1'b1;
              ery_src07[127:112] <= 16'h0080;
              ery_src07[111:108] <= tlx_afu_resp_code;
              ery_src07[107: 32] <= 76'b0;
              ery_src07[ 31: 16] <= tlx_afu_resp_afutag;
              ery_src07[ 15:  0] <= mmio_out_intrp_afutag;
            end
          else 
            begin
              ery_loadsrc[7]     <= 1'b0;
              ery_src07          <= 128'b0;
            end
        end
      else                                               // Waiting for response to show up
        begin
          afu_tlx_resp_credit_irq2 <= 1'b0;              // Do not give a credit back
          ery_loadsrc[7]           <= 1'b0;              // No error to report
          ery_src07                <= 128'b0;
        end
    end
  else                                                   // not in this state
    begin
      afu_tlx_resp_credit_irq2 <= 1'b0;                  // Do not give a credit back
      ery_loadsrc[7]           <= 1'b0;                  // No error to report
      ery_src07                <= 128'b0;
    end


// CLEAN_UP: Interrupt has completed. Release lock on AFU->Host interface & decrement pending interrupt counter
always @(posedge(clock))
  if (SM_IRQ == SM_IRQ_CLEAN_UP)
    begin
      lock_afu_to_host_intf_clr_irq <= 1'b1;        // Release lock on AFU->Host interface
      intrp_count_dec               <= 1'b1;        // Decrement pending interrupt counter
    end
  else                                              // not in this state
    begin
      lock_afu_to_host_intf_clr_irq <= 1'b0;        // Set to inactive values
      intrp_count_dec               <= 1'b0;        
    end


// CLEAN_UP2: Nothing to do in this state except wait for intrp_count to get decremented and AFU->Host interface to free.
//            If this state is not included, SM_IRQ restarts too soon since it senses the value of intrp_count before it is decremented.


// Determine next state
always @(posedge(clock))
  if (reset == 1'b1) SM_IRQ <= SM_IRQ_IDLE;   
  else 
    case (SM_IRQ)
      SM_IRQ_IDLE:            
          if (intrp_count > 3'b000)            SM_IRQ <= SM_IRQ_GET_LOCK;
          else                                 SM_IRQ <= SM_IRQ_IDLE;
      SM_IRQ_GET_LOCK:
          if (irq_ok_to_send_intrp == 1'b1 && lock_afu_to_host_intf == 1'b0 && tacc_credits_available > 4'b0) 
                                               SM_IRQ <= SM_IRQ_SEND_INTRP;     // Proceed when lock is free and TLX has room for command
          else                                 SM_IRQ <= SM_IRQ_GET_LOCK;
      SM_IRQ_SEND_INTRP:
          if (tacc_credits_available > 4'b0)   SM_IRQ <= SM_IRQ_WAIT_FOR_RESP;  // If needed, wait for TLX to signal it can accept a command
          else                                 SM_IRQ <= SM_IRQ_SEND_INTRP;     
      SM_IRQ_WAIT_FOR_RESP:
          if (received_intrp_resp == 1'b0)                                      // Didn't receive intrp_resp yet, stay in state
                                               SM_IRQ <= SM_IRQ_WAIT_FOR_RESP;
          else if (tlx_afu_resp_afutag != mmio_out_intrp_afutag)                // AFUTag didn't match, treat as error
                                               SM_IRQ <= SM_IRQ_ERROR;          
          else if (tlx_afu_resp_code == 4'b0000)                                // Interrupt was accepted
                                               SM_IRQ <= SM_IRQ_CLEAN_UP;
          else if (tlx_afu_resp_code == 4'b0010)                                // Wait for long delay, then resent intrp_req
                                               SM_IRQ <= SM_IRQ_RETRY_AFTER_DELAY;
          else if (tlx_afu_resp_code == 4'b0100)                                // Wait for intrp_rdy
                                               SM_IRQ <= SM_IRQ_WAIT4_INTRP_RDY;
          else                                                                  // Received fatal or reserved resp_code, treat as error
                                               SM_IRQ <= SM_IRQ_ERROR;                                     
      SM_IRQ_RETRY_AFTER_DELAY:
          if (irq_delay_count == 36'h0_0000_0000) SM_IRQ <= SM_IRQ_SEND_INTRP;
          else                                    SM_IRQ <= SM_IRQ_RETRY_AFTER_DELAY;
      SM_IRQ_WAIT4_INTRP_RDY:
          if (received_intrp_rdy == 1'b0)                                       // Didn't receive intrp_resp yet, stay in state
                                               SM_IRQ <= SM_IRQ_WAIT4_INTRP_RDY;
          else if (tlx_afu_resp_afutag != mmio_out_intrp_afutag)                // AFUTag didn't match, treat as error
                                               SM_IRQ <= SM_IRQ_ERROR;          
          else if (tlx_afu_resp_code == 4'b0000)                                // Host is ready to receive interrupt
                                               SM_IRQ <= SM_IRQ_SEND_INTRP;
          else if (tlx_afu_resp_code == 4'b0010)                                // Wait for long delay, then resent intrp_req
                                               SM_IRQ <= SM_IRQ_RETRY_AFTER_DELAY;
          else                                                                  // Received fatal or reserved resp_code, treat as error
                                               SM_IRQ <= SM_IRQ_ERROR;                                     
      SM_IRQ_CLEAN_UP:
                                               SM_IRQ <= SM_IRQ_CLEAN_UP2;      // Wait for intrp_count to decrement
      SM_IRQ_CLEAN_UP2:
                                               SM_IRQ <= SM_IRQ_IDLE;           // Ready to issue next interrupt
      SM_IRQ_ERROR:
                                               SM_IRQ <= SM_IRQ_ERROR;          // Once in the error state, stay there
      default:
                                               SM_IRQ <= SM_IRQ_ERROR;
    endcase



      
// ==============================================================================================================================
// @@@ TM1: Test Mode 1  (Place holder for future feature that drives AFU->Host commands)
// ==============================================================================================================================

// Note: For signals which intrp_req does not use, these assignments also put an inactive, driven value on the AFU->TLX interface
assign tm1_assign_actag_sent         = 1'b0;
assign lock_afu_to_host_intf_set_tm1 = 1'b0;
assign lock_afu_to_host_intf_clr_tm1 = 1'b0;
assign afu_tlx_resp_credit_tm1       = 1'b0;
assign afu_tlx_resp_rd_req_tm1       = 1'b0;
assign afu_tlx_resp_rd_cnt_tm1       = 3'b000;
assign afu_tlx_cmd_valid_tm1         = 1'b0;
assign afu_tlx_cmd_opcode_tm1        = 8'h00;
assign afu_tlx_cmd_actag_tm1         = 12'h000;
assign afu_tlx_cmd_stream_id_tm1     = 4'h0;
assign afu_tlx_cmd_ea_or_obj_tm1     = 68'b0;
assign afu_tlx_cmd_afutag_tm1        = 16'h0000;
assign afu_tlx_cmd_dl_tm1            = 2'b00;
assign afu_tlx_cmd_pl_tm1            = 3'b000;
assign afu_tlx_cmd_os_tm1            = 1'b0;
assign afu_tlx_cmd_be_tm1            = 64'b0;
assign afu_tlx_cmd_flag_tm1          = 4'h0;
assign afu_tlx_cmd_endian_tm1        = 1'b0;
assign afu_tlx_cmd_pasid_tm1         = 20'h00000;
assign afu_tlx_cmd_pg_size_tm1       = 6'b0;
assign afu_tlx_cdata_valid_tm1       = 1'b0;
assign afu_tlx_cdata_bus_tm1         = 512'b0;
assign afu_tlx_cdata_bdi_tm1         = 1'b0;


// ==============================================================================================================================
// @@@ DESC: AFU Descriptor Table 0 - defines configuration space information about this AFU
// ==============================================================================================================================

cfg_descriptor DESC (
    .clock                                  ( clock                             )
  , .reset                                  ( reset                             )  // (positive active)
    // READ ONLY field inputs 
                                            // 222221111111111000000000
                                            // 432109876543210987654321   Keep string exactly 24 characters long
//, .ro_name_space                          ( "IBM,LPC00000000000000000"        ) // '.' is an illegal character in the name
  , .ro_name_space                          ({"IBM,LPC", {17{8'h00}} }          ) // String must contain EXACTLY 24 characters, so pad accordingly with NULLs
  , .ro_afu_version_major                   (  `AFU_VERSION_MAJOR               ) 
  , .ro_afu_version_minor                   (  `AFU_VERSION_MINOR               ) 
  , .ro_afuc_type                           (   3'b001                          ) // Type C1 issues commands to the host but does not cache host data
  , .ro_afum_type                           (   3'b001                          ) // Type M1 contains host mapped addresses (i.e. MMIO or memory)
  , .ro_profile                             (   8'h01                           ) // Device Interface Class
  , .ro_global_mmio_offset                  (  48'h0000_0000_0000               ) // MMIO space start offset from BAR 0 addr ([15:0] assumed to be h0000)
  , .ro_global_mmio_bar                     (   3'b000                          ) // MMIO space is contained in BAR0
  , .ro_global_mmio_size                    (  32'h0008_0000                    ) // LPC MMIO size is 1 MB, but Global MMIO section is 512 KB
  , .ro_cmd_flag_x1_supported               (   1'b0                            ) // cmd_flag x1 is not supported
  , .ro_cmd_flag_x3_supported               (   1'b0                            ) // cmd_flag x3 is not supported
  , .ro_atc_2M_page_supported               (   1'b0                            ) // Address Translation Cache page size of 2MB is not supported
  , .ro_atc_64K_page_supported              (   1'b0                            ) // Address Translation Cache page size of 64KB is not supported
  , .ro_max_host_tag_size                   (   5'b00000                        ) // Caching is not supported
  , .ro_per_pasid_mmio_offset               (  48'h0000_0000_0008               ) // PASID space start at BAR 0+512KB address ([15:0] assumed to be h0000)
  , .ro_per_pasid_mmio_bar                  (   3'b000                          ) // PASID space is contained in BAR0
  , .ro_per_pasid_mmio_stride               (  16'h0001                         ) // Stride is 64KB per PASID entry ([15:0] assumed to be h0000)
//, .ro_mem_size                            (   8'h14                           ) // Default is 1 MB (2^20, x14 = 20 decimal) - SAM disabled
  , .ro_mem_size                            (   8'h2A                           ) // Default is 4 TB (2^42, x2A = 42 decimal) - SAM enabled
  , .ro_mem_start_addr                      (  64'h0000_0000_0000_0000          ) // LPC has only one Memory Space, starting at addr 0
  , .ro_naa_wwid                            ( 128'h0000_0000_0000_0000_0000_0000_0000_0000 ) // LPC has no WWID
  , .ro_system_memory_length                (  64'h0000_0000_4000_0000          ) //General purpose system memory size, currently set to 1GB
    // Hardcoded 'AFU Index' number of this instance of descriptor table
  , .ro_afu_index                           ( ro_afu_index                      ) // Each AFU instance under a common Function needs a unique index number
    // Functional interface
  , .cfg_desc_afu_index                     ( cfg_desc_afu_index                )
  , .cfg_desc_offset                        ( cfg_desc_offset                   )
  , .cfg_desc_cmd_valid                     ( cfg_desc_cmd_valid                )
  , .desc_cfg_data                          ( desc_cfg_data                     )
  , .desc_cfg_data_valid                    ( desc_cfg_data_valid               )
  , .desc_cfg_echo_cmd_valid                ( desc_cfg_echo_cmd_valid           )
    // Error indicator
  , .err_unimplemented_addr                 ( desc_err_unimplemented_addr       )
);


// ==============================================================================================================================
// @@@ MMIO_INPUTS: Collect MMIO error and status input vectors as last thing in the file so everything is declared earlier.
// ==============================================================================================================================

// Miscellanous error checks
`ifdef MARK_DEBUG_ACTIVE (* mark_debug = "TRUE" *) `endif
wire   err_incorrect_endianness;
assign err_incorrect_endianness = (tlx_afu_cmd_end == 1'b1 && tlx_afu_cmd_valid == 1'b1) ? 1'b1 : 1'b0;  // 1=Big, 0=Little Endian


// Collect error sources into a vector, then pass that into an MMIO register that will capture it
assign mmio_in_captured_errors = {         // When pulsed to 1, the MMIO reg bit is captured and held to 1. Write to 0 to clear.
    detect_bad_op                          // (   63) TLX presented a command that had an unrecognized opcode
  , write_mem_DL_is_reserved               // (   62) write_mem saw a DL value of 00, which is reserved
  , 1'b0 // read_mem_DL_is_reserved        // (   61) Reserved [was: read_mem saw a DL value of 00, which is reserved, but this is not a hang]
  , 1'b0 // afu_cfg_bad_op_or_align        // (   60) Reserved [was: AFU Config Space reported a bad address alignment or improper combination of strobes, but this is not a hang]
  , 1'b0 // mmio_bad_op_or_align           // (   59) Reserved [was: MMIO registers   reported a bad address alignment or improper combination of strobes, but this is not a hang]
  , received_bad_op                        // (   58) TLX presented a response that had an unrecognized opcode
  , err1_lock_afu_to_host_intf             // (   57) Someone tried to lock the AFU->Host interface when it was already in use
  , err2_lock_afu_to_host_intf             // (   56) Someone tried to free the AFU->Host interface when it was already available
  , cff_fifo_overflow                      // (   55) Command FIFO overrun
  , pip2_illegal_dl                        // (   54) Pipeline detected dL=00 on write_mem or rd_mem
  , rff_fifo_overflow                      // (   53) Response FIFO overrun
  , err_incorrect_endianness               // (   52) TLX is saying interface is Big Endian
  , vpd_err_unimplemented_addr             // (   51) Access to VPD targeted an unimplemented address
  , desc_err_unimplemented_addr            // (   50) Access to AFU Descriptor Table targeted an unimplemented address
  , (SM_IRQ == SM_IRQ_ERROR) ? 1'b1 : 1'b0 // (   49) Interrupt    state machine entered an error state
  , 1'b0                                   // (   48) Reserved
  , tacc_credit_overflow                   // (   47) TLX->AFU Command       Credit overflow
  , tacc_credit_underflow                  // (   46) TLX->AFU Command       Credit underflow
  , tarc_credit_overflow                   // (   45) TLX->AFU Response      Credit overflow
  , tarc_credit_underflow                  // (   44) TLX->AFU Response      Credit underflow
  , tacdc_credit_overflow                  // (   43) TLX->AFU Command  Data Credit overflow
  , tacdc_credit_underflow                 // (   42) TLX->AFU Command  Data Credit underflow
  , tardc_credit_overflow                  // (   41) TLX->AFU Response Data Credit overflow
  , tardc_credit_underflow                 // (   40) TLX->AFU Response Data Credit underflow
  , rffcr_credit_overflow                  // (   39) Response Buffer        Credit overflow
  , rffcr_credit_underflow                 // (   38) Response Buffer        Credit underflow
  , cfg0_cff_fifo_overflow                 // (   37) TLX Port 0 CFG Command  FIFO Overflow
  , cfg1_cff_fifo_overflow                 // (   36) TLX Port 1 CFG Command  FIFO Overflow
  , cfg0_rff_fifo_overflow                 // (   35) TLX Port 0 CFG Response FIFO Overflow
  , cfg1_rff_fifo_overflow                 // (   34) TLX Port 1 CFG Response FIFO Overflow
  , 2'b0                                   // (33:32) Reserved
  , mem_err_multiops                       // (   31) Bulk Memory error: read and write operations arrived in same cycle     
  , mem_err_boundary                       // (   30) Bulk Memory error: on multi-FLIT read, start address and rdcnt crossed 256B boundary
  , mem_err_internal                       // (   29) Bulk Memory error: internal condition that should never happen did
  , sam_overflow                           // (   28) SAM error: Mapping resources are exceeded
  , ery_simultaneous_load                  // (   27) ERY error: Multiple loadsrc bits on in the same cycle  
  , ery_overflow                           // (   26) ERY error: Excess error vector rows needed, array overflowed 
  , irq_acs_settings_err                   // (   25) IRQ error: Something isn't configured right to allow LPC to send an interrupt
  , pasid_acs_settings_err                 // (   24) PASID error: Something isn't configured right with the PASID settings
  , 24'b0                                  // (23: 0) Reserved
};


// Collect status signals that can be read via an MMIO read only address
assign mmio_in_status = {                  // Provide a READ ONLY way for signals like status to be assigned an MMIO address
    tlx_afu_ready                          // (63)    Ready from TLX (may be useless since can't use MMIO to read status if TLX isn't ready)
  , sam_entries_open                       // (62:58) Number of SAM mapping resources available
  , ery_data_valid                         // (57)    When 1, valid error information is available for software to read
  , 57'b0                                  // Reserved
}; 


endmodule 
