/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:01:30
 * @LastEditTime: 2021-08-13 15:35:54
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
  	input  LoadType        		    EXE_LoadType,	 	
  	input  StoreType       		    EXE_StoreType, 

    input  logic    [4:0]  	        EXE_Dst,
  	input  RegsWrType      		    EXE_RegsWrType,
  	input  logic 	[1:0]   	    EXE_WbSel,     

  	input  ExceptinPipeType 		EXE_ExceptType_final,	
	// input  logic    [3:0]           EXE_DCache_Wen,
	// input  logic    [31:0]          EXE_DataToDcache,         //DCache的字节写使能
    input  logic                    EXE_IsTLBP,
    input  logic                    EXE_IsTLBW,
    input  logic                    EXE_IsTLBR, 
    input  logic                    EXE_TLBWIorR,
    input  logic    [1:0]           EXE_RegsReadSel,
    input  logic    [4:0]           EXE_rd,
    input  logic    [31:0]          EXE_Result, 
    input  logic                    EXE_IsMFC0,
    input  CacheType                EXE_CacheType,
 //----------------------------------------------------------//   
    output logic	[31:0] 		    MEM_ALUOut,	
    output logic    [31:0]          MEM_OutB,	

    output logic 	[31:0] 		    MEM_PC,			
    output logic    [31:0]          MEM_Instr,
    
    output logic                    MEM_IsABranch,
	output LoadType    			    MEM_LoadType,
	output StoreType     		    MEM_StoreType,

    output logic 	[4:0]  		    MEM_Dst,
	output RegsWrType               MEM_RegsWrType,
    output logic 	[1:0]  		    MEM_WbSel,

	output ExceptinPipeType 		MEM_ExceptType,
    output logic                    MEM_IsTLBP,
    output logic                    MEM_IsTLBW,
    output logic                    MEM_IsTLBR,
    output logic                    MEM_TLBWIorR,
    output logic    [1:0]           MEM_RegsReadSel,
    output logic    [4:0]           MEM_rd,
    output logic    [31:0]          MEM_Result,
    output logic                    MEM_IsMFC0,
    output CacheType                MEM_CacheType
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
            MEM_Instr               <= 32'b0;
            MEM_IsTLBP              <= '0;
            MEM_IsTLBW              <= '0;
            MEM_IsTLBR              <= '0;
            MEM_TLBWIorR            <= '0;
            MEM_RegsReadSel         <= '0;
            MEM_rd                  <= '0;
            MEM_Result              <= '0;
            MEM_IsMFC0              <= '0;
            MEM_CacheType           <= '0;
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
            MEM_Instr               <= EXE_Instr;
            MEM_IsTLBP              <= EXE_IsTLBP;
            MEM_IsTLBW              <= EXE_IsTLBW;
            MEM_IsTLBR              <= EXE_IsTLBR;
            MEM_TLBWIorR            <= EXE_TLBWIorR;
            MEM_RegsReadSel         <= EXE_RegsReadSel;
            MEM_rd                  <= EXE_rd;
            MEM_Result              <= EXE_Result;
            MEM_IsMFC0              <= EXE_IsMFC0;
            MEM_CacheType           <= EXE_CacheType;
        end
    end
endmodule
