/*
 * @Author: Seddon Shen
 * @Date: 2021-03-27 15:31:34
 * @LastEditTime: 2021-08-18 15:31:36
 * @LastEditors: Please set LastEditors
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \nontrival-cpu\Src\refactor\EXE\ALU.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module ALU (
    input  logic  [31:0]       EXE_ResultA,
    input  logic  [31:0]       EXE_ResultB,
    input  logic  [4:0]        EXE_ALUOp,
    input  logic  [31:0]       MUL_Out,
    input  logic  [31:0]       FIL_Out,
    //---------------------output------------------------//
    output logic  [31:0]       EXE_ALUOut,
    output logic               Overflow_valid
);
    logic [31:0] Countbit_Out;
    logic        Countbit_Opt; 
    assign       Countbit_Opt = (EXE_ALUOp == `EXE_ALUOp_CLO);
    logic [31:0] ADD_Out;
    logic [31:0] SUB_Out;
    logic [31:0] ORI_Out;
    logic [31:0] SLL_Out;
    logic [31:0] SRL_Out;
    logic [31:0] SRA_Out;
    logic [31:0] SLT_Out;
    logic [31:0] SLTU_Out;
    logic [31:0] XOR_Out;
    logic [31:0] AND_Out;
    
    Countbit U_Countbit (                 //CLO,CLZ
        .option(Countbit_Opt),
        .value(EXE_ResultA),
        .count(Countbit_Out)
    );

    assign ADD_Out = EXE_ResultA + EXE_ResultB;
    assign SUB_Out = EXE_ResultA - EXE_ResultB;
    assign ORI_Out = EXE_ResultA | EXE_ResultB;
    assign SLL_Out = EXE_ResultB << EXE_ResultA[4:0];
    assign SRL_Out = EXE_ResultB >> EXE_ResultA[4:0];
    assign SRA_Out = $signed(EXE_ResultB) >>> EXE_ResultA[4:0];
    assign SLT_Out = ($signed(EXE_ResultA) < $signed(EXE_ResultB))?32'b1:32'b0;
    assign SLTU_Out= ((EXE_ResultA) < (EXE_ResultB))?32'b1:32'b0;
    assign XOR_Out = EXE_ResultA ^ EXE_ResultB;
    assign AND_Out = EXE_ResultA & EXE_ResultB;

    always_comb begin
        unique case (EXE_ALUOp)
            `EXE_ALUOp_ADD,`EXE_ALUOp_ADDU :  EXE_ALUOut = ADD_Out;
            `EXE_ALUOp_SUB,`EXE_ALUOp_SUBU :  EXE_ALUOut = SUB_Out;
            `EXE_ALUOp_ORI  :                 EXE_ALUOut = ORI_Out;
            `EXE_ALUOp_NOR  :                 EXE_ALUOut = ~ORI_Out;
            `EXE_ALUOp_SLL,`EXE_ALUOp_SLLV :  EXE_ALUOut = SLL_Out;//这个时候EXE_Shamt本来就只剩最低四位了，而用Shamt之后其实就本致相同了
            `EXE_ALUOp_SRL,`EXE_ALUOp_SRLV :  EXE_ALUOut = SRL_Out;//这个时候EXE_Shamt本来就只剩最低四位了
            `EXE_ALUOp_SRA,`EXE_ALUOp_SRAV :  EXE_ALUOut = SRA_Out;//这样写也就导致了ResultA在移位时已经被置为可变长度或者s
            `EXE_ALUOp_SLT  :                 EXE_ALUOut = SLT_Out;  
            `EXE_ALUOp_SLTU :                 EXE_ALUOut = SLTU_Out;
            `EXE_ALUOp_XOR  :                 EXE_ALUOut = XOR_Out;
            `EXE_ALUOp_AND  :                 EXE_ALUOut = AND_Out;
            `EXE_ALUOp_MUL  :                 EXE_ALUOut = MUL_Out;
            `EXE_ALUOp_CLZ,`EXE_ALUOp_CLO  :  EXE_ALUOut = Countbit_Out;
            `EXE_ALUOp_FILTER :               EXE_ALUOut = FIL_Out;
            default :                         EXE_ALUOut = EXE_ResultA;//用于MOVZ，MOVN指令
        endcase
    end 

    assign Overflow_valid = (EXE_ALUOp == `EXE_ALUOp_ADD )&&( ( (!EXE_ResultA[31] && !EXE_ResultB[31]) && (EXE_ALUOut[31]) )||( (EXE_ResultA[31] && EXE_ResultB[31]) && (!EXE_ALUOut[31]) )) ||
                                         (EXE_ALUOp == `EXE_ALUOp_SUB)&&( ( (!EXE_ResultA[31] && EXE_ResultB[31]) && (EXE_ALUOut[31]) )||( (EXE_ResultA[31] && !EXE_ResultB[31]) && (!EXE_ALUOut[31]) ));
    // TODO: 针对EXE_ALUOP字段，当其为'x的时候，是否需要将overflow的异常置为'0 ,现在是'x
endmodule