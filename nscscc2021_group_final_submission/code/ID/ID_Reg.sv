/*
 * @Author: npuwth
 * @Date: 2021-04-02 14:09:14
 * @LastEditTime: 2021-08-14 23:02:03
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module ID_Reg ( 
//-------------------------------------------------------------------//    
    input logic                        clk,
    input logic                        rst,
    input logic                        ID_Flush,
    input logic                        ID_Wr,

    input logic   [31:0]               IF_Instr,
    input logic   [31:0]               IF_PC,
    input ExceptinPipeType             IF_ExceptType,
    input PResult                      IF_PResult,
    input logic                        IF_Valid,
//-------------------------------------------------------------------//
    output logic  [31:0]               ID_Instr,
    output logic  [15:0]               ID_Imm16,
    output logic  [4:0]                ID_rs,
    output logic  [4:0]                ID_rt,
    output logic  [4:0]                ID_rd,
    output logic  [31:0]               ID_PC,
    output ExceptinPipeType            ID_ExceptType,      
    output PResult                     ID_PResult,
    output logic                       ID_Valid
);

  always_ff @( posedge clk  ) begin
    if( (rst == `RstEnable) || (ID_Flush == `FlushEnable) ) begin
      ID_Instr                         <= 32'b0;
      ID_Imm16                         <= 16'b0;
      ID_rs                            <= 5'b0;
      ID_rt                            <= 5'b0;
      ID_rd                            <= 5'b0;
      ID_PC                            <= 32'b0;
      ID_ExceptType                    <= '0;
      ID_PResult                       <= '0;
      ID_Valid                         <= '0;
    end
    else if( ID_Wr ) begin
      ID_Instr                         <= IF_Instr;
      ID_Imm16                         <= IF_Instr[15:0];
      ID_rs                            <= IF_Instr[25:21];
      ID_rt                            <= IF_Instr[20:16];
      ID_rd                            <= IF_Instr[15:11];
      ID_PC                            <= IF_PC;
      ID_ExceptType                    <= IF_ExceptType;
      ID_PResult                       <= IF_PResult;
      ID_Valid                         <= IF_Valid;
    end
  end
  
endmodule