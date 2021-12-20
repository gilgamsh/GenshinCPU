/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:24:26
 * @LastEditTime: 2021-08-13 15:33:53
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module MEM2_Reg (
//-----------------------------------------------------------------//   
    input logic                         clk,
    input logic                         rst,
    input logic                         MEM2_Flush,
    input logic                         MEM2_Wr,
    
    input logic		  [31:0] 		          MEM_ALUOut,		
    input logic 		[31:0] 	 	          MEM_PC,	
    input logic     [31:0]              MEM_Instr,		
    input logic 		[1:0]  		          MEM_WbSel,				
    input logic 		[4:0]  		          MEM_Dst,
    input logic     [31:0]              MEM_OutB,
	  input RegsWrType                    MEM_RegsWrType_final,//经过exception solvement的新写使能
	  input logic     [4:0]		            MEM_ExcType,
	  input logic                         MEM_IsABranch,
	  input logic                         MEM_IsInDelaySlot,
    input LoadType                      MEM_LoadType,
    `ifdef DEBUG
		input   logic   [3:0]               MEM_DCache_Wen,
		input   logic   [31:0]              MEM_DataToDcache,
		`endif
//------------------------------------------------------------------//
    output logic		[31:0] 		          MEM2_ALUOut,		
    output logic 		[31:0] 		          MEM2_PC,
    output logic    [31:0]              MEM2_Instr,			
    output logic 		[1:0]  		          MEM2_WbSel,				
    output logic 		[4:0]  		          MEM2_Dst,
    output logic    [31:0]              MEM2_OutB,
    output RegsWrType                   MEM2_RegsWrType,
    output logic    [4:0]		            MEM2_ExcType,
    output logic                        MEM2_IsABranch,
    output logic                        MEM2_IsInDelaySlot,
    `ifdef DEBUG
		output logic     [3:0]              MEM2_DCache_Wen,
		output logic     [31:0]             MEM2_DataToDcache,
		`endif
    output LoadType                     MEM2_LoadType
);

  always_ff @(posedge clk ) begin
    if( rst == `RstEnable || MEM2_Flush == `FlushEnable) begin
      MEM2_ALUOut                         <= 32'b0;
      MEM2_PC                             <= 32'b0;
      MEM2_Instr                          <= 32'b0;
      MEM2_WbSel                          <= 2'b0;
      MEM2_Dst                            <= 5'b0;
      MEM2_OutB                           <= 32'b0;
      MEM2_RegsWrType                     <= '0;
      MEM2_ExcType                        <= '0;
      MEM2_IsABranch                      <= 1'b0;
      MEM2_IsInDelaySlot                  <= 1'b0;
      MEM2_LoadType                       <= '0;
      `ifdef DEBUG
      MEM2_DCache_Wen                     <='0;
      MEM2_DataToDcache                   <='0;
      `endif
    end
    else if( MEM2_Wr ) begin
      MEM2_ALUOut                         <= MEM_ALUOut;
      MEM2_PC                             <= MEM_PC;
      MEM2_Instr                          <= MEM_Instr;
      MEM2_WbSel                          <= MEM_WbSel;
      MEM2_Dst                            <= MEM_Dst;
      MEM2_OutB                           <= MEM_OutB;
      MEM2_RegsWrType                     <= MEM_RegsWrType_final;
      MEM2_ExcType                        <= MEM_ExcType;
      MEM2_IsABranch                      <= MEM_IsABranch;
      MEM2_IsInDelaySlot                  <= MEM_IsInDelaySlot;
      MEM2_LoadType                       <= MEM_LoadType;
      `ifdef DEBUG
      MEM2_DCache_Wen                     <=MEM_DCache_Wen    ;
      MEM2_DataToDcache                   <=MEM_DataToDcache  ;
      `endif
    end
  end

endmodule