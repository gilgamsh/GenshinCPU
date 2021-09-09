/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:24:26
 * @LastEditTime: 2021-07-03 09:48:18
 * @LastEditors: Please set LastEditors
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module WB_Reg (
//-----------------------------------------------------------------//   
    input logic                         clk,
    input logic                         rst,
    input logic                         WB_Flush,
    input logic                         WB_Wr,
    
    input logic		  [31:0] 		          MEM_ALUOut,	
    input logic     [31:0]              MEM_Hi,
    input logic     [31:0]              MEM_Lo,		
    input logic 		[31:0] 		          MEM_PC,	
    input logic     [31:0]              MEM_Instr,		
    input logic 		[1:0]  		          MEM_WbSel,				
    input logic 		[4:0]  		          MEM_Dst,
	  input LoadType     			            MEM_LoadType,
	  input logic 		[31:0] 		          MEM_DMOut,
    input logic     [31:0]              MEM_OutB,
	  input RegsWrType                    MEM_RegsWrType_final,//经过exception solvement的新写使能
	  input ExceptinPipeType 		          MEM_ExceptType_final,
	  input logic                         MEM_IsABranch,
	  input logic                         MEM_IsAImmeJump,
	  input logic                         MEM_IsInDelaySlot,
    input logic                         MEM_IsTLBW,
    input logic                         MEM_IsTLBR,
//------------------------------------------------------------------//
    output logic		[31:0] 		          WB_ALUOut,	
    output logic    [31:0]              WB_Hi,
    output logic    [31:0]              WB_Lo,		
    output logic 		[31:0] 		          WB_PC,
    output logic    [31:0]              WB_Instr,			
    output logic 		[1:0]  		          WB_WbSel,				
    output logic 		[4:0]  		          WB_Dst,
	  output LoadType     			          WB_LoadType,
	  output logic 		[31:0] 		          WB_DMOut,
    output logic    [31:0]              WB_OutB,
	  output RegsWrType                   WB_RegsWrType,//经过exception solvement的新写使能
	  output ExceptinPipeType 		        WB_ExceptType,
	  output logic                        WB_IsABranch,
	  output logic                        WB_IsAImmeJump,
	  output logic                        WB_IsInDelaySlot,
    output logic                        WB_IsTLBW,
    output logic                        WB_IsTLBR
);

  always_ff @(posedge clk ) begin
    if( rst == `RstEnable || WB_Flush == `FlushEnable) begin
      WB_WbSel                          <= 2'b0;
      WB_PC                             <= 32'b0;
      WB_ALUOut                         <= 32'b0;
      WB_OutB                           <= 32'b0;
      WB_DMOut                          <= 32'b0;
      WB_Dst                            <= 5'b0;
      WB_LoadType                       <= '0;
      WB_RegsWrType                     <= '0;
      WB_ExceptType                     <= '0;
      WB_IsABranch                      <= 1'b0;
      WB_IsAImmeJump                    <= 1'b0;
      WB_IsInDelaySlot                  <= 1'b0;
      WB_Instr                          <= 32'b0;
      WB_Hi                             <= 32'b0;
      WB_Lo                             <= 32'b0;
      WB_IsTLBW                         <= 1'b0;
      WB_IsTLBR                         <= 1'b0;
    end
    else if( WB_Wr ) begin
      WB_WbSel                          <= MEM_WbSel;
      WB_PC                             <= MEM_PC;
      WB_ALUOut                         <= MEM_ALUOut;
      WB_OutB                           <= MEM_OutB;
      WB_DMOut                          <= MEM_DMOut;
      WB_Dst                            <= MEM_Dst;
      WB_LoadType                       <= MEM_LoadType;
      WB_RegsWrType                     <= MEM_RegsWrType_final;
      WB_ExceptType                     <= MEM_ExceptType_final;
      WB_IsABranch                      <= MEM_IsABranch;
      WB_IsAImmeJump                    <= MEM_IsAImmeJump;
      WB_IsInDelaySlot                  <= MEM_IsInDelaySlot;
      WB_Instr                          <= MEM_Instr;
      WB_Hi                             <= MEM_Hi;
      WB_Lo                             <= MEM_Lo;
      WB_IsTLBW                         <= MEM_IsTLBW;
      WB_IsTLBR                         <= MEM_IsTLBR;
    end
  end

endmodule