/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:01:30
 * @LastEditTime: 2021-07-06 11:39:58
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module MEM_Reg ( 
//-------------------------------------------------------//
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    MEM_Flush,
    input  logic                    MEM_Wr,

    input  logic    [31:0]  	    EXE_ALUOut,   		
  	input  logic    [31:0]  	    EXE_OutB,	 		
		    
  	input  logic    [31:0] 	        EXE_PC, 		   
	input  logic    [31:0]	        EXE_Instr,
    
    input  BranchType               EXE_BranchType,
	input  logic 					EXE_IsAImmeJump,

  	input  LoadType        		    EXE_LoadType,	 	
  	input  StoreType       		    EXE_StoreType, 

    input  logic    [4:0]  	        EXE_Dst,
  	input  RegsWrType      		    EXE_RegsWrType,
  	input  logic 	[1:0]   	    EXE_WbSel,     

  	input  ExceptinPipeType 		EXE_ExceptType_final,	
	
    input  logic    [31:0]          EXE_Hi,
    input  logic    [31:0]          EXE_Lo,
    input  logic                    EXE_IsTLBP,
    input  logic                    EXE_IsTLBW,
    input  logic                    EXE_IsTLBR, 
    input  logic    [1:0]           EXE_RegsReadSel,
 //----------------------------------------------------------//   
    output logic	[31:0] 		    MEM_ALUOut,	
    output logic    [31:0]          MEM_OutB,	

    output logic 	[31:0] 		    MEM_PC,			
    output logic    [31:0]          MEM_Instr,
    
    output logic                    MEM_IsABranch,
	output logic                    MEM_IsAImmeJump,
    
	output LoadType    			    MEM_LoadType,
	output StoreType     		    MEM_StoreType,

    output logic 	[4:0]  		    MEM_Dst,
	output RegsWrType               MEM_RegsWrType,
    output logic 	[1:0]  		    MEM_WbSel,

	output ExceptinPipeType 		MEM_ExceptType,
	
    output logic    [31:0]          MEM_Hi,
    output logic    [31:0]          MEM_Lo,
    output logic                    MEM_IsTLBP,
    output logic                    MEM_IsTLBW,
    output logic                    MEM_IsTLBR,
    output logic    [1:0]           MEM_RegsReadSel
);

    always_ff @( posedge clk  ) begin
        if( ( rst == `RstEnable )|| ( MEM_Flush == `FlushEnable )) begin
            MEM_ALUOut              <= 32'b0;
            MEM_PC                  <= 32'b0;
            MEM_WbSel               <= 2'b0;
            MEM_Dst                 <= 5'b0;
            MEM_LoadType            <= '0;
            MEM_StoreType           <= '0;
            MEM_RegsWrType          <= '0;
            MEM_OutB                <= 32'b0;
            MEM_ExceptType          <= '0;
            MEM_IsABranch           <= 1'b0;
            MEM_IsAImmeJump         <= 1'b0;
            MEM_Instr               <= 32'b0;
            MEM_Hi                  <= 32'b0;
            MEM_Lo                  <= 32'b0;
            MEM_IsTLBP              <= 1'b0;
            MEM_IsTLBW              <= 1'b0;
            MEM_IsTLBR              <= 1'b0;
            MEM_RegsReadSel         <= 1'b0;
        end
        else if( MEM_Wr ) begin
            MEM_ALUOut              <= EXE_ALUOut;
            MEM_PC                  <= EXE_PC;
            MEM_WbSel               <= EXE_WbSel;
            MEM_Dst                 <= EXE_Dst;
            MEM_LoadType            <= EXE_LoadType;
            MEM_StoreType           <= EXE_StoreType;
            MEM_RegsWrType          <= EXE_RegsWrType;
            MEM_OutB                <= EXE_OutB;
            MEM_ExceptType          <= EXE_ExceptType_final;
            MEM_IsABranch           <= EXE_BranchType.isBranch;
            MEM_IsAImmeJump         <= EXE_IsAImmeJump;
            MEM_Instr               <= EXE_Instr;
            MEM_Hi                  <= EXE_Hi;
            MEM_Lo                  <= EXE_Lo;
            MEM_IsTLBP              <= EXE_IsTLBP;
            MEM_IsTLBW              <= EXE_IsTLBW;
            MEM_IsTLBR              <= EXE_IsTLBR;
            MEM_RegsReadSel         <= EXE_RegsReadSel;
        end
    end
endmodule
