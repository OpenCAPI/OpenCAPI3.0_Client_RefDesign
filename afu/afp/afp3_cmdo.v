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

module afp3_cmdo (

  // -- Clocks & Reset
    input                 clock_afu          // -- target frequency 200MHz
  , input                 clock_tlx          // -- target frequency 400MHz
  , input                 reset                                                                                                                    

  // -- Config info
  , input          [19:0] cfg_afu_pasid_base                                                                                                     
  , input          [19:0] mmio_cmdo_pasid_mask                                                                                                     
  , input                 mmio_cmdo_split_128B_cmds

  // -- Command input from Engines
  , input                 eng_cmdo_valid                                                                                                           
  , input           [7:0] eng_cmdo_opcode                                                                                                          
  , input          [11:0] eng_cmdo_actag                                                                                                           
  , input           [3:0] eng_cmdo_stream_id                                                                                                       
  , input          [67:0] eng_cmdo_ea_or_obj                                                                                                       
  , input          [15:0] eng_cmdo_afutag                                                                                                          
  , input           [1:0] eng_cmdo_dl                                                                                                              
  , input           [2:0] eng_cmdo_pl                                                                                                              
  , input                 eng_cmdo_os                                                                                                              
  , input          [63:0] eng_cmdo_be                                                                                                              
  , input           [3:0] eng_cmdo_flag                                                                                                            
  , input                 eng_cmdo_endian                                                                                                          
  , input          [15:0] eng_cmdo_bdf                                                                                                             
  , input          [19:0] eng_cmdo_pasid                                                                                                           
  , input           [5:0] eng_cmdo_pg_size                                                                                                         
  , input                 eng_cmdo_st_valid                                                                                                        
  , input        [1023:0] eng_cmdo_st_data                                                                                                         

  // -- Send latched Command to response logic for tracking outstanding ops
  , output                cmdo_rspi_cmd_valid
  , output          [7:0] cmdo_rspi_cmd_opcode
  , output          [1:0] cmdo_rspi_cmd_dl

  // -- AFU_TLX command transmit interface
  , output                afu_tlx_cmd_valid
  , output          [7:0] afu_tlx_cmd_opcode
  , output         [11:0] afu_tlx_cmd_actag
  , output          [3:0] afu_tlx_cmd_stream_id
  , output         [67:0] afu_tlx_cmd_ea_or_obj
  , output         [15:0] afu_tlx_cmd_afutag
  , output          [1:0] afu_tlx_cmd_dl
  , output          [2:0] afu_tlx_cmd_pl
  , output                afu_tlx_cmd_os
  , output         [63:0] afu_tlx_cmd_be
  , output          [3:0] afu_tlx_cmd_flag
  , output                afu_tlx_cmd_endian
  , output         [15:0] afu_tlx_cmd_bdf
  , output         [19:0] afu_tlx_cmd_pasid
  , output          [5:0] afu_tlx_cmd_pg_size

  , output                afu_tlx_cdata_valid
  , output                afu_tlx_cdata_bdi
  , output        [511:0] afu_tlx_cdata_bus

  // -- Cmd & Data Credit
  , input                 tlx_afu_cmd_credit                //  -- TLX returns cmd credit to AFU when cmd taken from FIFO by DLX
  , input                 tlx_afu_cmd_data_credit           //  -- TLX returns cmd data credit to AFU when cmd data taken from FIFO by DLX

//--input           [4:3] tlx_afu_cmd_resp_initial_credit_x //  -- TLX informs AFU cmd/resp credits available - same for cmd and resp
//--input           [2:0] tlx_afu_cmd_resp_initial_credit   //  -- TLX informs AFU cmd/resp credits available - same for cmd and resp
//--input           [6:5] tlx_afu_data_initial_credit_x     //  -- TLX informs AFU data credits available
//--input           [4:0] tlx_afu_data_initial_credit       //  -- TLX informs AFU data credits available

  , input           [4:4] tlx_afu_cmd_initial_credit_x      //  -- TLX informs AFU cmd credits available
  , input           [3:0] tlx_afu_cmd_initial_credit        //  -- TLX informs AFU cmd credits available
  , input           [6:6] tlx_afu_cmd_data_initial_credit_x //  -- TLX informs AFU cmd data credits available
  , input           [5:0] tlx_afu_cmd_data_initial_credit   //  -- TLX informs AFU cmd data credits available
 
  , output                cmdo_arb_cmd_credit_ge_1
  , output                cmdo_arb_cmd_credit_ge_2
  , output                cmdo_arb_data_credit_ge_1
  , output                cmdo_arb_data_credit_ge_2
  , output                cmdo_arb_data_credit_ge_4

  , input                 arb_cmdo_decr_cmd_credit
  , input                 arb_cmdo_decr_data_credit_4
  , input                 arb_cmdo_decr_data_credit_2
  , input                 arb_cmdo_decr_data_credit_1

  // -- AFU_TLX Command Bus Trace outputs
  , output                trace_afu_tlx_cmd_valid
  , output          [7:0] trace_afu_tlx_cmd_opcode
  , output          [5:0] trace_afu_tlx_cmd_actag
//, output          [3:0] trace_afu_tlx_cmd_stream_id
  , output         [67:0] trace_afu_tlx_cmd_ea_or_obj
  , output         [15:0] trace_afu_tlx_cmd_afutag
  , output          [1:0] trace_afu_tlx_cmd_dl
  , output          [2:0] trace_afu_tlx_cmd_pl
//, output                trace_afu_tlx_cmd_os
//, output         [63:0] trace_afu_tlx_cmd_be
  , output          [3:0] trace_afu_tlx_cmd_flag
//, output                trace_afu_tlx_cmd_endian
//, output         [15:0] trace_afu_tlx_cmd_bdf
  , output          [9:0] trace_afu_tlx_cmd_pasid
  , output          [5:0] trace_afu_tlx_cmd_pg_size

  , output                trace_afu_tlx_cdata_valid
//, output                trace_afu_tlx_cdata_bdi
//, output       [1023:0] trace_afu_tlx_cdata_bus

  , output          [1:0] trace_tlx_afu_cmd_credit
  , output          [1:0] trace_tlx_afu_cmd_data_credit

  , output          [4:0] trace_cmdo_avail_cmd_credit
  , output          [6:0] trace_cmdo_avail_cmd_data_credit

  // -- Display Read Interface - Copy Engines
  , input           [3:0] mmio_cmdo_display_offset
  , output reg     [63:0] cmdo_mmio_display_rddata

  // -- Simulation Idle
  , output                sim_idle_cmdo

  );


  // --****************************************************************************
  // -- Signal declarations
  // --****************************************************************************

  // -- 128B cmd split support
  wire            cmd_is_128B_cpy;

  // -- Command Credit
  wire            decr_cmd_credit;                                                                                                         
  wire            incr_cmd_credit;
  wire      [2:0] available_cmd_credit_sel;                                                                                                         

  // -- Data Credit
  wire            decr_data_credit_4;                                                                                                      
  wire            decr_data_credit_2;                                                                                                      
  wire            decr_data_credit_1;                                                                                                      
  wire            incr_data_credit;                                                                                                        
  wire      [4:0] available_cmd_data_credit_sel;                                                                                               

  // -- PASID modification per CNFG sourced Base/Mask
  wire     [19:0] eng_cmdo_pasid_aligned;                                                                                                  


  // --****************************************************************************
  // -- Latch Signal declarations (including enable signals)
  // --****************************************************************************

  // -- Even/Odd latches
  wire            toggle_d;                                                                                                                
  reg             toggle_q;                                                                                                                
  wire            sample_d;                                                                                                                
  reg             sample_q;                                                                                                                
  wire            odd_d;                                                                                                                   
  reg             odd_q;                                                                                                                   
  wire            even_d;                                                                                                                  
  (* keep = "true", max_fanout = 128 *) reg             even_q;                                                                                                                  


  // -- Repower mode bits
  wire            mmio_cmdo_split_128B_cmds_d;
  reg             mmio_cmdo_split_128B_cmds_q;

  // -- Engine interface latches (inbound)
  wire            eng_cmdo_valid_d;                                                                                                        
  reg             eng_cmdo_valid_q;                                                                                                        
  wire      [7:0] eng_cmdo_opcode_d;                                                                                                       
  reg       [7:0] eng_cmdo_opcode_q;                                                                                                       
  wire     [11:0] eng_cmdo_actag_d;                                                                                                        
  reg      [11:0] eng_cmdo_actag_q;                                                                                                        
  wire      [3:0] eng_cmdo_stream_id_d;                                                                                                    
  reg       [3:0] eng_cmdo_stream_id_q;                                                                                                    
  wire     [67:0] eng_cmdo_ea_or_obj_d;                                                                                                    
  reg      [67:0] eng_cmdo_ea_or_obj_q;                                                                                                    
  wire     [15:0] eng_cmdo_afutag_d;                                                                                                       
  reg      [15:0] eng_cmdo_afutag_q;                                                                                                       
  wire      [1:0] eng_cmdo_dl_d;                                                                                                           
  reg       [1:0] eng_cmdo_dl_q;                                                                                                           
  wire      [2:0] eng_cmdo_pl_d;                                                                                                           
  reg       [2:0] eng_cmdo_pl_q;                                                                                                           
  wire            eng_cmdo_os_d;                                                                                                           
  reg             eng_cmdo_os_q;                                                                                                           
  wire     [63:0] eng_cmdo_be_d;                                                                                                           
  reg      [63:0] eng_cmdo_be_q;                                                                                                           
  wire      [3:0] eng_cmdo_flag_d;                                                                                                         
  reg       [3:0] eng_cmdo_flag_q;                                                                                                         
  wire            eng_cmdo_endian_d;                                                                                                       
  reg             eng_cmdo_endian_q;                                                                                                       
  wire     [15:0] eng_cmdo_bdf_d;                                                                                                          
  reg      [15:0] eng_cmdo_bdf_q;                                                                                                          
  wire     [19:0] eng_cmdo_pasid_d;                                                                                                        
  reg      [19:0] eng_cmdo_pasid_q;                                                                                                        
  wire      [5:0] eng_cmdo_pg_size_d;                                                                                                      
  reg       [5:0] eng_cmdo_pg_size_q;                                                                                                      
  wire            eng_cmdo_st_valid_d;                                                                                                     
  reg             eng_cmdo_st_valid_q;                                                                                                     
  wire   [1023:0] eng_cmdo_st_data_d;                                                                                                      
  reg    [1023:0] eng_cmdo_st_data_q;

  // -- Repowering for gating
  wire            eng_cmdo_st_valid_dly_d;                                                                                                 
  reg             eng_cmdo_st_valid_dly_q;                                                                                                 
  wire            eng_cmdo_dl_ge_128B_d;                                                                                                   
 (* keep = "true", max_fanout = 256 *)   reg             eng_cmdo_dl_ge_128B_q;                                                                                                   

  // -- Trace Array Latches
  wire      [1:0] trace_tlx_afu_cmd_credit_d;
  reg       [1:0] trace_tlx_afu_cmd_credit_q;
  wire      [1:0] trace_tlx_afu_cmd_data_credit_d;
  reg       [1:0] trace_tlx_afu_cmd_data_credit_q;

  wire      [4:0] trace_cmdo_avail_cmd_credit_d;
  reg       [4:0] trace_cmdo_avail_cmd_credit_q;
  wire      [6:0] trace_cmdo_avail_cmd_data_credit_d;
  reg       [6:0] trace_cmdo_avail_cmd_data_credit_q;


  // -- TLX interface latches (outbound)
  reg             afu_tlx_cmd_valid_d;                                                                                                     
  reg             afu_tlx_cmd_valid_q;                                                                                                     
  reg       [7:0] afu_tlx_cmd_opcode_d;                                                                                                    
  reg       [7:0] afu_tlx_cmd_opcode_q;                                                                                                    
  reg      [11:0] afu_tlx_cmd_actag_d;                                                                                                     
  reg      [11:0] afu_tlx_cmd_actag_q;                                                                                                     
  reg       [3:0] afu_tlx_cmd_stream_id_d;                                                                                                 
  reg       [3:0] afu_tlx_cmd_stream_id_q;                                                                                                 
  reg      [67:0] afu_tlx_cmd_ea_or_obj_d;                                                                                                 
  reg      [67:0] afu_tlx_cmd_ea_or_obj_q;                                                                                                 
  reg      [15:0] afu_tlx_cmd_afutag_d;                                                                                                    
  reg      [15:0] afu_tlx_cmd_afutag_q;                                                                                                    
  reg       [1:0] afu_tlx_cmd_dl_d;                                                                                                        
  reg       [1:0] afu_tlx_cmd_dl_q;                                                                                                        
  reg       [2:0] afu_tlx_cmd_pl_d;                                                                                                        
  reg       [2:0] afu_tlx_cmd_pl_q;                                                                                                        
  reg             afu_tlx_cmd_os_d;                                                                                                        
  reg             afu_tlx_cmd_os_q;                                                                                                        
  reg      [63:0] afu_tlx_cmd_be_d;                                                                                                        
  reg      [63:0] afu_tlx_cmd_be_q;                                                                                                        
  reg       [3:0] afu_tlx_cmd_flag_d;                                                                                                      
  reg       [3:0] afu_tlx_cmd_flag_q;                                                                                                      
  reg             afu_tlx_cmd_endian_d;                                                                                                    
  reg             afu_tlx_cmd_endian_q;                                                                                                    
  reg      [15:0] afu_tlx_cmd_bdf_d;                                                                                                       
  reg      [15:0] afu_tlx_cmd_bdf_q;                                                                                                       
  reg      [19:0] afu_tlx_cmd_pasid_d;                                                                                                     
  reg      [19:0] afu_tlx_cmd_pasid_q;                                                                                                     
  reg       [5:0] afu_tlx_cmd_pg_size_d;                                                                                                   
  reg       [5:0] afu_tlx_cmd_pg_size_q;                                                                                                   
  reg             afu_tlx_cdata_valid_d;                                                                                                   
  reg             afu_tlx_cdata_valid_q;                                                                                                   
  reg     [511:0] afu_tlx_cdata_bus_d;                                                                                                     
  reg     [511:0] afu_tlx_cdata_bus_q;                                                                                                     

  // -- Command Credit
  wire            tlx_afu_cmd_credit_d;
  reg             tlx_afu_cmd_credit_q;

  wire            available_cmd_credit_en;                                                                                                 
  reg       [4:0] available_cmd_credit_d;                                                                                                  
  reg       [4:0] available_cmd_credit_q;                                                                                                  

  // -- Data Credit
  wire            tlx_afu_cmd_data_credit_d;
  reg             tlx_afu_cmd_data_credit_q;

  wire            available_cmd_data_credit_en;                                                                                                
  reg       [6:0] available_cmd_data_credit_d;                                                                                                 
  reg       [6:0] available_cmd_data_credit_q;                                                                                                 



  // -- ********************************************************************************************************************************
  // -- Determine Even/Odd Cycles
  // -- ********************************************************************************************************************************

  // --                          _______         _______         _______         _______         _______         
  // -- clock_afu             __|       |_______|       |_______|       |_______|       |_______|       |_______
  // --                          ___     ___     ___     ___     ___     ___     ___     ___     ___     ___     
  // -- clock_tlx             __|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___
  // --                          _______________                 _______________                 _______________
  // -- toggle_q              __|               |_______________|               |_______________|
  // --                                  _______________                 _______________                 _______
  // -- sample_q              __________|               |_______________|               |_______________|
  // --                          _______         _______         _______         _______         _______         
  // -- even_q                __|       |_______|       |_______|       |_______|       |_______|       |_______
  // --                       __         _______         _______         _______         _______         _______         
  // -- odd_q                   |_______|       |_______|       |_______|       |_______|       |_______|       
  // --                          _______________          
  // -- eng_cmdo_xxx          --<_______________>---------------------------------------------------------------
  // --                                          _______________          
  // -- eng_cmdo_xxx_q        ------------------<_______________>-----------------------------------------------
  // --                                                  _______          
  // -- afu_tlx_xxx_q         --------------------------<_______>-----------------------------------------------
  // --                                                  _______ _______ _______ _______
  // -- afu_tlx_cdata_valid_q   ________________________|       |   ?   |   ?   |   ?   |_______________________
  // --                                                  _______ _______ _______ _______
  // -- afu_tlx_cdata_bus_q     ------------------------<_______X_______X_______X_______>-----------------------


  assign  toggle_d = ~toggle_q && ~reset;

  assign  sample_d =  toggle_q;

  assign  odd_d    =  toggle_q ^ sample_q;

  assign  even_d   =  odd_q;

  // -- ********************************************************************************************************************************
  // -- Repower Mode bits (AFU clock domain)
  // -- ********************************************************************************************************************************

  assign  mmio_cmdo_split_128B_cmds_d =  mmio_cmdo_split_128B_cmds;


  // -- ********************************************************************************************************************************
  // -- Latch inputs from engines (AFU clock domain)
  // -- ********************************************************************************************************************************

  // -- NOTE: for timing purposes, need to latch in the AFU clock domain.
  // --       These signals originate from the engines and go through big OR tree
  // --       There is some minimal amount of gating logic on the store data between latch and output within the engine

  assign  eng_cmdo_valid_d           =  eng_cmdo_valid;
  assign  eng_cmdo_opcode_d[7:0]     =  eng_cmdo_opcode[7:0];
  assign  eng_cmdo_actag_d[11:0]     =  eng_cmdo_actag[11:0];
  assign  eng_cmdo_stream_id_d[3:0]  =  eng_cmdo_stream_id[3:0];
  assign  eng_cmdo_ea_or_obj_d[67:0] =  eng_cmdo_ea_or_obj[67:0];
  assign  eng_cmdo_afutag_d[15:0]    =  eng_cmdo_afutag[15:0];
  assign  eng_cmdo_dl_d[1:0]         =  eng_cmdo_dl[1:0];
  assign  eng_cmdo_pl_d[2:0]         =  eng_cmdo_pl[2:0];
  assign  eng_cmdo_os_d              =  eng_cmdo_os;
  assign  eng_cmdo_be_d[63:0]        =  eng_cmdo_be[63:0];
  assign  eng_cmdo_flag_d[3:0]       =  eng_cmdo_flag[3:0];
  assign  eng_cmdo_endian_d          =  eng_cmdo_endian;
  assign  eng_cmdo_bdf_d[15:0]       =  eng_cmdo_bdf[15:0];
  assign  eng_cmdo_pasid_d[19:0]     =  eng_cmdo_pasid[19:0];
  assign  eng_cmdo_pg_size_d[5:0]    =  eng_cmdo_pg_size[5:0];

  assign  eng_cmdo_st_valid_d        =  eng_cmdo_st_valid;
  assign  eng_cmdo_st_data_d[1023:0] =  eng_cmdo_st_data[1023:0];

  assign  eng_cmdo_dl_ge_128B_d      =  eng_cmdo_dl[1];

  assign  eng_cmdo_st_valid_dly_d = { eng_cmdo_st_valid_q && ( eng_cmdo_dl_q[1:0] == 2'b11 ) };  // -- for beats 3, 4 of 256B op

  // -- NOTE: eng_cmdo_st_valid is only a single pulse indicating that there is data associated with the command
  // --       Must use the length field to determine how many cycle to drive afu_tlx_cdata_valid


  // -- ********************************************************************************************************************************
  // -- Align PASID to the Base
  // -- ********************************************************************************************************************************

  assign  eng_cmdo_pasid_aligned[19:0] =  ( cfg_afu_pasid_base[19:0] &  mmio_cmdo_pasid_mask[19:0] ) |
                                          (   eng_cmdo_pasid_q[19:0] & ~mmio_cmdo_pasid_mask[19:0] );


  // -- ********************************************************************************************************************************
  // -- Send latched (AFU clock domain) output to the Response logic to track outbound cmds vs incoming responses 
  // -- ********************************************************************************************************************************

  assign  cmdo_rspi_cmd_valid       =  eng_cmdo_valid_q;
  assign  cmdo_rspi_cmd_opcode[7:0] =  eng_cmdo_opcode_q[7:0];
  assign  cmdo_rspi_cmd_dl[1:0]     =  eng_cmdo_dl_q[1:0];


  // -- ********************************************************************************************************************************
  // -- Re-Latch into the TLX clock domain before driving to TLX
  // -- ********************************************************************************************************************************

  // -- use one "EVEN" repower latch to gate roughly 32 signals ... may need to adjust dependent upon timing results
  // -- depending upon timing, it might be possible to just drive gated signals directly to TLX without latching.
  // --       (May have to increase the number of gating signals to gate something less than 32 signals per gate)
  // -- Valid signals have dedicated gate (in the event that we want to try to drive gated signals directly to TLX 

  assign  cmd_is_128B_cpy =  (( eng_cmdo_dl_q[1:0] == 2'b10 ) && ( eng_cmdo_afutag_q[11] == 1'b0 ));

  always @*
    begin

      // -- Drive cmd valid in only 1st half of AFU clock cycle (unless splitting 128B ops)
      if ( ~mmio_cmdo_split_128B_cmds_q )
        afu_tlx_cmd_valid_d =  ( eng_cmdo_valid_q && even_q );
      else
        afu_tlx_cmd_valid_d =  ( eng_cmdo_valid_q );


      // -- Drive data valid on 1,2, or 4 clock cycles depending upon the op size                                                                    
      afu_tlx_cdata_valid_d = (( eng_cmdo_st_valid_q &&  even_q ) ||                      // -- 1st beat
                               ( eng_cmdo_st_valid_q && ~even_q && eng_cmdo_dl_q[1] ) ||  // -- 2nd beat
                                 eng_cmdo_st_valid_dly_q );                               // -- 3rd & 4th beat of 256

      // -- Use copies of the even latch to gate the cmd when moving from AFU to TLX clock domain
      if (( ~mmio_cmdo_split_128B_cmds_q || ( mmio_cmdo_split_128B_cmds_q && ~cmd_is_128B_cpy )) && even_q )
        begin
          afu_tlx_cmd_opcode_d[7:0]      =  eng_cmdo_opcode_q[7:0];
          afu_tlx_cmd_actag_d[11:0]      =  eng_cmdo_actag_q[11:0];
          afu_tlx_cmd_stream_id_d[3:0]   =  eng_cmdo_stream_id_q[3:0];
          afu_tlx_cmd_ea_or_obj_d[67:0]  =  eng_cmdo_ea_or_obj_q[67:0];
          afu_tlx_cmd_afutag_d[15:0]     =  eng_cmdo_afutag_q[15:0];
          afu_tlx_cmd_dl_d[1:0]          =  eng_cmdo_dl_q[1:0];
          afu_tlx_cmd_pl_d[2:0]          =  eng_cmdo_pl_q[2:0];
          afu_tlx_cmd_os_d               =  eng_cmdo_os_q;
          afu_tlx_cmd_be_d[63:0]         =  eng_cmdo_be_q[63:0];
          afu_tlx_cmd_flag_d[3:0]        =  eng_cmdo_flag_q[3:0];
          afu_tlx_cmd_endian_d           =  eng_cmdo_endian_q;
          afu_tlx_cmd_bdf_d[15:0]        =  eng_cmdo_bdf_q[15:0];
          afu_tlx_cmd_pasid_d[19:0]      =  eng_cmdo_pasid_aligned[19:0];
          afu_tlx_cmd_pg_size_d[5:0]     =  eng_cmdo_pg_size_q[5:0];
        end
      else if ( mmio_cmdo_split_128B_cmds_q && cmd_is_128B_cpy )
        begin
          afu_tlx_cmd_opcode_d[7:0]      =  eng_cmdo_opcode_q[7:0];
          afu_tlx_cmd_actag_d[11:0]      =  eng_cmdo_actag_q[11:0];
          afu_tlx_cmd_stream_id_d[3:0]   =  eng_cmdo_stream_id_q[3:0];
          if ( even_q )  // -- 1st half of 200MHz cycle
            begin
              afu_tlx_cmd_ea_or_obj_d[67:0]  =    eng_cmdo_ea_or_obj_q[67:0];        // -- Keep original offset for 1st 64B
              afu_tlx_cmd_afutag_d[15:0]     =  { 2'b01, eng_cmdo_afutag_q[13:0] };  // -- Change 128B orig length indicator in AFUTAG to 64B
              afu_tlx_cmd_dl_d[1:0]          =    2'b01;                             // -- Change 128B data length to 64B
            end
          else     // -- odd - 2nd half of 200MHz cycle
            begin
              afu_tlx_cmd_ea_or_obj_d[67:0]  =  { ( eng_cmdo_ea_or_obj_q[67:6] + 62'b1 ), eng_cmdo_ea_or_obj_q[5:0] };  // -- Increment EA to next 64B offset
              afu_tlx_cmd_afutag_d[15:0]     =  { 2'b01, eng_cmdo_afutag_q[13:5], ( eng_cmdo_afutag_q[4:0] + 5'b1 ) };  // -- Change 128B orig dl to 64B AND increment databuffer pointer in AFUTAG 
              afu_tlx_cmd_dl_d[1:0]          =    2'b01;                                                                // -- Change 128B data length to 64B
            end
          afu_tlx_cmd_pl_d[2:0]          =  eng_cmdo_pl_q[2:0];
          afu_tlx_cmd_os_d               =  eng_cmdo_os_q;
          afu_tlx_cmd_be_d[63:0]         =  eng_cmdo_be_q[63:0];
          afu_tlx_cmd_flag_d[3:0]        =  eng_cmdo_flag_q[3:0];
          afu_tlx_cmd_endian_d           =  eng_cmdo_endian_q;
          afu_tlx_cmd_bdf_d[15:0]        =  eng_cmdo_bdf_q[15:0];
          afu_tlx_cmd_pasid_d[19:0]      =  eng_cmdo_pasid_aligned[19:0];
          afu_tlx_cmd_pg_size_d[5:0]     =  eng_cmdo_pg_size_q[5:0];
        end
      else
        begin
          afu_tlx_cmd_opcode_d[7:0]      =   8'b0;
          afu_tlx_cmd_actag_d[11:0]      =  12'b0;
          afu_tlx_cmd_stream_id_d[3:0]   =   4'b0;
          afu_tlx_cmd_ea_or_obj_d[67:0]  =  68'b0;
          afu_tlx_cmd_afutag_d[15:0]     =  16'b0;
          afu_tlx_cmd_dl_d[1:0]          =   2'b0;
          afu_tlx_cmd_pl_d[2:0]          =   3'b0;
          afu_tlx_cmd_os_d               =   1'b0;
          afu_tlx_cmd_be_d[63:0]         =  64'b0;
          afu_tlx_cmd_flag_d[3:0]        =   4'b0;
          afu_tlx_cmd_endian_d           =   1'b0;
          afu_tlx_cmd_bdf_d[15:0]        =  16'b0;
          afu_tlx_cmd_pasid_d[19:0]      =  20'b0;
          afu_tlx_cmd_pg_size_d[5:0]     =   6'b0;
        end
    end  // -- always @*     



  always @*
    begin
      if ( even_q )
        afu_tlx_cdata_bus_d[511:0] =  eng_cmdo_st_data_q[511:0];
      else if ( eng_cmdo_dl_ge_128B_q || eng_cmdo_st_valid_dly_q )
        afu_tlx_cdata_bus_d[511:0] =  eng_cmdo_st_data_q[1023:512];
      else
        afu_tlx_cdata_bus_d[511:0] =  512'b0;

    end  // -- always @*     


  // -- ********************************************************************************************************************************
  // -- Drive the AFU_TLX cmd interface
  // -- ********************************************************************************************************************************

  assign  afu_tlx_cmd_valid           =  afu_tlx_cmd_valid_q; 
  assign  afu_tlx_cmd_opcode[7:0]     =  afu_tlx_cmd_opcode_q[7:0];
  assign  afu_tlx_cmd_actag[11:0]     =  afu_tlx_cmd_actag_q[11:0];
  assign  afu_tlx_cmd_stream_id[3:0]  =  afu_tlx_cmd_stream_id_q[3:0];
  assign  afu_tlx_cmd_ea_or_obj[67:0] =  afu_tlx_cmd_ea_or_obj_q[67:0];
  assign  afu_tlx_cmd_afutag[15:0]    =  afu_tlx_cmd_afutag_q[15:0];
  assign  afu_tlx_cmd_dl[1:0]         =  afu_tlx_cmd_dl_q[1:0];
  assign  afu_tlx_cmd_pl[2:0]         =  afu_tlx_cmd_pl_q[2:0];
  assign  afu_tlx_cmd_os              =  afu_tlx_cmd_os_q;
  assign  afu_tlx_cmd_be[63:0]        =  afu_tlx_cmd_be_q[63:0];
  assign  afu_tlx_cmd_flag[3:0]       =  afu_tlx_cmd_flag_q[3:0];
  assign  afu_tlx_cmd_endian          =  afu_tlx_cmd_endian_q;
  assign  afu_tlx_cmd_bdf[15:0]       =  afu_tlx_cmd_bdf_q[15:0];
  assign  afu_tlx_cmd_pasid[19:0]     =  afu_tlx_cmd_pasid_q[19:0];
  assign  afu_tlx_cmd_pg_size[5:0]    =  afu_tlx_cmd_pg_size_q[5:0];

  assign  afu_tlx_cdata_valid         =  afu_tlx_cdata_valid_q;
  assign  afu_tlx_cdata_bdi           =  1'b0;
  assign  afu_tlx_cdata_bus[511:0]    =  afu_tlx_cdata_bus_q[511:0];


  // -- ******************************************************************************************************************************************
  // -- Manage Cmd Credit
  // -- ******************************************************************************************************************************************

  assign  tlx_afu_cmd_credit_d =  tlx_afu_cmd_credit;  // -- Latch only for purpose of tracing the interface with trace array

  assign  decr_cmd_credit =  ( arb_cmdo_decr_cmd_credit && even_q );  // -- decrement credit count every cmd granted by arb 
  assign  incr_cmd_credit =  tlx_afu_cmd_credit;                          // -- TLX returning a credit back to us

  assign  available_cmd_credit_en =  ( reset || decr_cmd_credit || incr_cmd_credit );

  assign  available_cmd_credit_sel[2:0] = { reset, decr_cmd_credit, incr_cmd_credit };

  always @*
    begin
      casez ( available_cmd_credit_sel[2:0] )
        // --
        // --  reset
        // --  | decr_cmd_credit
        // --  | | incr_cmd_credit
        // --  | | |
        // -----------------------------------------------------------------------------------
            3'b1_?_? :  available_cmd_credit_d[4:0] =  { tlx_afu_cmd_initial_credit_x[4:4], tlx_afu_cmd_initial_credit[3:0] } ;
            3'b0_1_0 :  available_cmd_credit_d[4:0] =  ( available_cmd_credit_q[4:0] - 5'b1 );
            3'b0_0_1 :  available_cmd_credit_d[4:0] =  ( available_cmd_credit_q[4:0] + 5'b1 );
        // -----------------------------------------------------------------------------------
            default  :  available_cmd_credit_d[4:0] =    available_cmd_credit_q[4:0]         ;
        // -----------------------------------------------------------------------------------
      endcase

    end  // -- always @*

  assign  cmdo_arb_cmd_credit_ge_1 =  ( available_cmd_credit_q[4:0] != 5'b0 );
  assign  cmdo_arb_cmd_credit_ge_2 =  ( available_cmd_credit_q[4:1] != 4'b0 );


  // -- ******************************************************************************************************************************************
  // -- Manage Cmd Data Credit
  // -- ******************************************************************************************************************************************

  assign  tlx_afu_cmd_data_credit_d =  tlx_afu_cmd_data_credit;  // -- Latch only for purpose of tracing the interface with trace array

  assign  decr_data_credit_4 =  ( arb_cmdo_decr_data_credit_4 && even_q );  // -- decrement credit count as arb give grant for 256B store cmd
  assign  decr_data_credit_2 =  ( arb_cmdo_decr_data_credit_2 && even_q );  // -- decrement credit count as arb give grant for 128B store cmd
  assign  decr_data_credit_1 =  ( arb_cmdo_decr_data_credit_1 && even_q );  // -- decrement credit count as arb give grant for  64B or partial store cmd
  assign  incr_data_credit   =  tlx_afu_cmd_data_credit;                    // -- TLX returning a data credit back to AFU

  assign  available_cmd_data_credit_en =  ( reset || decr_data_credit_4 || decr_data_credit_2 || decr_data_credit_1 || incr_data_credit );

  assign  available_cmd_data_credit_sel[4:0] = { reset, decr_data_credit_4, decr_data_credit_2, decr_data_credit_1, incr_data_credit };

  always @*
    begin
      casez ( available_cmd_data_credit_sel[4:0] )
        // --
        // --  reset
        // --  | decr_data_credit_4
        // --  | | decr_data_credit_2
        // --  | | | decr_data_credit_1
        // --  | | | | incr_data_credit
        // --  | | | | |
        // -------------------------------------------------------------------------------------------------------------------------------
            5'b1_?_?_?_? :  available_cmd_data_credit_d =  { tlx_afu_cmd_data_initial_credit_x[6:6], tlx_afu_cmd_data_initial_credit[5:0] };  // -- Reset - Load initial Credit 
            5'b0_1_0_0_0 :  available_cmd_data_credit_d =                                 ( available_cmd_data_credit_q[6:0] - 7'b0000100 );  // -- -4                            
            5'b0_0_1_0_0 :  available_cmd_data_credit_d =                                 ( available_cmd_data_credit_q[6:0] - 7'b0000010 );  // -- -2                          
            5'b0_0_0_1_0 :  available_cmd_data_credit_d =                                 ( available_cmd_data_credit_q[6:0] - 7'b0000001 );  // -- -1
            5'b0_0_0_0_1 :  available_cmd_data_credit_d =                                 ( available_cmd_data_credit_q[6:0] + 7'b0000001 );  // --   +1                        
            5'b0_1_0_0_1 :  available_cmd_data_credit_d =                                 ( available_cmd_data_credit_q[6:0] - 7'b0000011 );  // -- -4+1
            5'b0_0_1_0_1 :  available_cmd_data_credit_d =                                 ( available_cmd_data_credit_q[6:0] - 7'b0000001 );  // -- -2+1
        // -------------------------------------------------------------------------------------------------------------------------------
            default      :  available_cmd_data_credit_d =                                   available_cmd_data_credit_q[6:0]               ;
        // -------------------------------------------------------------------------------------------------------------------------------
      endcase

    end  // -- always @*

  assign  cmdo_arb_data_credit_ge_4 =  (available_cmd_data_credit_q[6:2] != 5'b0 ); 
  assign  cmdo_arb_data_credit_ge_2 =  (available_cmd_data_credit_q[6:1] != 6'b0 ); 
  assign  cmdo_arb_data_credit_ge_1 =  (available_cmd_data_credit_q[6:0] != 7'b0 ); 


  // -- ********************************************************************************************************************************
  // -- Send latched interface signals to the trace array for debug
  // -- ********************************************************************************************************************************

  // -- capture signals in the 200MHz domain before sending to trace
  assign  trace_tlx_afu_cmd_credit_d[0]       =  tlx_afu_cmd_credit_q && odd_q;
  assign  trace_tlx_afu_cmd_credit_d[1]       =  tlx_afu_cmd_credit   && odd_q;

  assign  trace_tlx_afu_cmd_data_credit_d[0]  =  tlx_afu_cmd_data_credit_q && odd_q;
  assign  trace_tlx_afu_cmd_data_credit_d[1]  =  tlx_afu_cmd_data_credit   && odd_q;

  assign  trace_cmdo_avail_cmd_credit_d[4:0]      =  available_cmd_credit_q[4:0];
  assign  trace_cmdo_avail_cmd_data_credit_d[6:0] =  available_cmd_data_credit_q[6:0];

  // -- AFU_TLX Command Bus Trace inputs
  assign  trace_afu_tlx_cmd_valid             =  eng_cmdo_valid_q;          
  assign  trace_afu_tlx_cmd_opcode[7:0]       =  eng_cmdo_opcode_q[7:0];    
  assign  trace_afu_tlx_cmd_actag[5:0]        =  eng_cmdo_actag_q[5:0];     
//assign  trace_afu_tlx_cmd_stream_id[3:0]    =  eng_cmdo_stream_id_q[3:0]; 
  assign  trace_afu_tlx_cmd_ea_or_obj[67:0]   =  eng_cmdo_ea_or_obj_q[67:0];
  assign  trace_afu_tlx_cmd_afutag[15:0]      =  eng_cmdo_afutag_q[15:0];   
  assign  trace_afu_tlx_cmd_dl[1:0]           =  eng_cmdo_dl_q[1:0];        
  assign  trace_afu_tlx_cmd_pl[2:0]           =  eng_cmdo_pl_q[2:0];        
//assign  trace_afu_tlx_cmd_os                =  eng_cmdo_os_q;             
//assign  trace_afu_tlx_cmd_be[63:0]          =  eng_cmdo_be_q[63:0];       
  assign  trace_afu_tlx_cmd_flag[3:0]         =  eng_cmdo_flag_q[3:0];      
//assign  trace_afu_tlx_cmd_endian            =  eng_cmdo_endian_q;         
//assign  trace_afu_tlx_cmd_bdf[15:0]         =  eng_cmdo_bdf_q[15:0];      
  assign  trace_afu_tlx_cmd_pasid[9:0]        =  eng_cmdo_pasid_q[9:0];     
  assign  trace_afu_tlx_cmd_pg_size[5:0]      =  eng_cmdo_pg_size_q[5:0];   
                                                            
  assign  trace_afu_tlx_cdata_valid           =  eng_cmdo_st_valid_q;        
//assign  trace_afu_tlx_cdata_bdi             =  1'b0;          
//assign  trace_afu_tlx_cdata_bus[1023:0]     =  eng_cmdo_st_data_q[1023:0];  

  assign  trace_tlx_afu_cmd_credit[1:0]       =  trace_tlx_afu_cmd_credit_q[1:0]; 
  assign  trace_tlx_afu_cmd_data_credit[1:0]  =  trace_tlx_afu_cmd_data_credit_q[1:0];

  assign  trace_cmdo_avail_cmd_credit[4:0]      =  trace_cmdo_avail_cmd_credit_q[4:0];
  assign  trace_cmdo_avail_cmd_data_credit[6:0] =  trace_cmdo_avail_cmd_data_credit_q[6:0];


  // -- ********************************************************************************************************************************
  // -- Display Read Interface
  // -- ********************************************************************************************************************************

  // -- The copy engine always delivers display read request data on data bus bits [1023:512]

  always @*
    begin
      case ( mmio_cmdo_display_offset[2:0] )
        3'b111 :  cmdo_mmio_display_rddata[63:0] =  eng_cmdo_st_data_q[1023:960];
        3'b110 :  cmdo_mmio_display_rddata[63:0] =  eng_cmdo_st_data_q[959:896];
        3'b101 :  cmdo_mmio_display_rddata[63:0] =  eng_cmdo_st_data_q[895:832];
        3'b100 :  cmdo_mmio_display_rddata[63:0] =  eng_cmdo_st_data_q[831:768];
        3'b011 :  cmdo_mmio_display_rddata[63:0] =  eng_cmdo_st_data_q[767:704];
        3'b010 :  cmdo_mmio_display_rddata[63:0] =  eng_cmdo_st_data_q[703:640];
        3'b001 :  cmdo_mmio_display_rddata[63:0] =  eng_cmdo_st_data_q[639:576];
        3'b000 :  cmdo_mmio_display_rddata[63:0] =  eng_cmdo_st_data_q[575:512];
      endcase
    end  // -- always @*


  // -- ********************************************************************************************************************************
  // -- Sim Idle
  // -- ********************************************************************************************************************************

  assign  sim_idle_cmdo =  ( available_cmd_credit_q[4:0]      == { tlx_afu_cmd_initial_credit_x[4:4],      tlx_afu_cmd_initial_credit[3:0] } ) &&
                           ( available_cmd_data_credit_q[6:0] == { tlx_afu_cmd_data_initial_credit_x[6:6], tlx_afu_cmd_data_initial_credit[5:0] } ) &&
                            ~eng_cmdo_valid_q;


  // -- ********************************************************************************************************************************
  // -- Bugspray
  // -- ********************************************************************************************************************************

//!! Bugspray include : afp3_cmdo


  // -- ********************************************************************************************************************************
  // -- Latch Declarations
  // -- ********************************************************************************************************************************

  // -- Latches in the AFU Clock Domain
  always @ ( posedge clock_afu )
    begin
      toggle_q                             <= toggle_d;

      mmio_cmdo_split_128B_cmds_q          <= mmio_cmdo_split_128B_cmds_d;

      eng_cmdo_valid_q                     <= eng_cmdo_valid_d;             
      eng_cmdo_opcode_q[7:0]               <= eng_cmdo_opcode_d[7:0];       
      eng_cmdo_actag_q[11:0]               <= eng_cmdo_actag_d[11:0];       
      eng_cmdo_stream_id_q[3:0]            <= eng_cmdo_stream_id_d[3:0];    
      eng_cmdo_ea_or_obj_q[67:0]           <= eng_cmdo_ea_or_obj_d[67:0];   
      eng_cmdo_afutag_q[15:0]              <= eng_cmdo_afutag_d[15:0];      
      eng_cmdo_dl_q[1:0]                   <= eng_cmdo_dl_d[1:0];           
      eng_cmdo_pl_q[2:0]                   <= eng_cmdo_pl_d[2:0];           
      eng_cmdo_os_q                        <= eng_cmdo_os_d;                
      eng_cmdo_be_q[63:0]                  <= eng_cmdo_be_d[63:0];          
      eng_cmdo_flag_q[3:0]                 <= eng_cmdo_flag_d[3:0];         
      eng_cmdo_endian_q                    <= eng_cmdo_endian_d;            
      eng_cmdo_bdf_q[15:0]                 <= eng_cmdo_bdf_d[15:0];         
      eng_cmdo_pasid_q[19:0]               <= eng_cmdo_pasid_d[19:0];       
      eng_cmdo_pg_size_q[5:0]              <= eng_cmdo_pg_size_d[5:0];      
      eng_cmdo_st_valid_q                  <= eng_cmdo_st_valid_d;          
      eng_cmdo_st_data_q[1023:0]           <= eng_cmdo_st_data_d[1023:0];   
      eng_cmdo_st_valid_dly_q              <= eng_cmdo_st_valid_dly_d;      
      eng_cmdo_dl_ge_128B_q                <= eng_cmdo_dl_ge_128B_d;

      trace_tlx_afu_cmd_credit_q[1:0]      <= trace_tlx_afu_cmd_credit_d[1:0];  
      trace_tlx_afu_cmd_data_credit_q[1:0] <= trace_tlx_afu_cmd_data_credit_d[1:0];  

      trace_cmdo_avail_cmd_credit_q[4:0]       <= trace_cmdo_avail_cmd_credit_d[4:0];  
      trace_cmdo_avail_cmd_data_credit_q[6:0]  <= trace_cmdo_avail_cmd_data_credit_d[6:0];

    end   // -- always  @                     

  // -- Latches in the TLX Clock Domain
  always @ ( posedge clock_tlx )
    begin
      sample_q                             <= sample_d;                     
      odd_q                                <= odd_d;                        
      even_q                               <= even_d;                 

      afu_tlx_cmd_valid_q                  <= afu_tlx_cmd_valid_d;          
      afu_tlx_cmd_opcode_q[7:0]            <= afu_tlx_cmd_opcode_d[7:0];    
      afu_tlx_cmd_actag_q[11:0]            <= afu_tlx_cmd_actag_d[11:0];    
      afu_tlx_cmd_stream_id_q[3:0]         <= afu_tlx_cmd_stream_id_d[3:0]; 
      afu_tlx_cmd_ea_or_obj_q[67:0]        <= afu_tlx_cmd_ea_or_obj_d[67:0]; 
      afu_tlx_cmd_afutag_q[15:0]           <= afu_tlx_cmd_afutag_d[15:0];   
      afu_tlx_cmd_dl_q[1:0]                <= afu_tlx_cmd_dl_d[1:0];        
      afu_tlx_cmd_pl_q[2:0]                <= afu_tlx_cmd_pl_d[2:0];        
      afu_tlx_cmd_os_q                     <= afu_tlx_cmd_os_d;             
      afu_tlx_cmd_be_q[63:0]               <= afu_tlx_cmd_be_d[63:0];       
      afu_tlx_cmd_flag_q[3:0]              <= afu_tlx_cmd_flag_d[3:0];      
      afu_tlx_cmd_endian_q                 <= afu_tlx_cmd_endian_d;         
      afu_tlx_cmd_bdf_q[15:0]              <= afu_tlx_cmd_bdf_d[15:0];      
      afu_tlx_cmd_pasid_q[19:0]            <= afu_tlx_cmd_pasid_d[19:0];    
      afu_tlx_cmd_pg_size_q[5:0]           <= afu_tlx_cmd_pg_size_d[5:0];   
      afu_tlx_cdata_valid_q                <= afu_tlx_cdata_valid_d;        
      afu_tlx_cdata_bus_q[511:0]           <= afu_tlx_cdata_bus_d[511:0];   

      // -- Command Credit
      tlx_afu_cmd_credit_q                 <= tlx_afu_cmd_credit_d;
      if ( available_cmd_credit_en )
        available_cmd_credit_q[4:0]        <= available_cmd_credit_d[4:0];  

      // -- Data Credit
      tlx_afu_cmd_data_credit_q            <= tlx_afu_cmd_data_credit_d;
      if ( available_cmd_data_credit_en )
        available_cmd_data_credit_q[6:0]   <= available_cmd_data_credit_d[6:0]; 

    end   // -- always  @                     

endmodule
