/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-07-06 21:50:15
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module TOP_EXE ( 
    input logic               clk,
    input logic               resetn,
    input logic               EXE_Flush,
    input logic               EXE_Wr,
    input RegsWrType          WB_RegsWrType,
    input logic [4:0]         WB_Dst,
    input logic [31:0]        WB_Result,
    input logic               HiLo_Not_Flush,
    ID_EXE_Interface          IEBus,
    EXE_MEM_Interface         EMBus,
    output logic              ID_Flush_BranchSolvement,
    output logic              EXE_MULTDIVStall,
    output logic [31:0]       EXE_BusA_L1,//给IF
    output BranchType         EXE_BranchType,
    output logic [31:0]       EXE_PC,
    output logic [31:0]       EXE_Imm32
);

    logic [31:0]              EXE_BusA;
    logic [31:0]              EXE_BusB;
    logic [4:0]               EXE_rs;
    logic [4:0]               EXE_rd;
    logic [4:0]               EXE_ALUOp;
    logic [1:0]               EXE_DstSel;
    logic                     EXE_ALUSrcA;
    logic                     EXE_ALUSrcB;
    logic [1:0]               EXE_RegsReadSel;
    ExceptinPipeType          EXE_ExceptType;    //未经过alu的
    ExceptinPipeType          EXE_ExceptType_new;//经过ALU后的excepttype
    logic [1:0]               EXE_ForwardA;
    logic [1:0]               EXE_ForwardB;
    logic [4:0]               EXE_Shamt;
    logic [31:0]              EXE_BusB_L1;
    logic [31:0]              EXE_BusA_L2;
    logic [31:0]              EXE_BusB_L2;
    logic [1:0]               EXE_MultiExtendOp; //New add for MADD
    logic                     EXE_Finish;        //来自乘除法
    logic [31:0]              EXE_MULTDIVtoHI;
    logic [31:0]              EXE_MULTDIVtoLO;
    logic [4:0]               EXE_rt;

    assign EXE_BranchType     = EMBus.EXE_BranchType;
    assign EXE_PC             = EMBus.EXE_PC;
    assign IEBus.EXE_IsTLBR   = EMBus.EXE_IsTLBR;
    assign IEBUs.EXE_IsTLBW   = EMBus.EXE_IsTLBW;
    assign IEBus.EXE_rt       = EXE_rt;
    assign IEBus.EXE_LoadType = EMBus.EXE_LoadType; 

    EXE_Reg U_EXE_Reg ( 
        .clk                  (clk ),
        .rst                  (resetn ), 
        .EXE_Flush            (EXE_Flush ),
        .EXE_Wr               (EXE_Wr ),
        .ID_BusA              (IEBus.ID_BusA ),
        .ID_BusB              (IEBus.ID_BusB ),
        .ID_Imm32             (IEBus.ID_Imm32 ),
        .ID_PC                (IEBus.ID_PC ),
        .ID_Instr             (IEBus.ID_Instr ),
        .ID_rs                (IEBus.ID_rs ),
        .ID_rt                (IEBus.ID_rt ),
        .ID_rd                (IEBus.ID_rd ),
        .ID_ALUOp             (IEBus.ID_ALUOp ),
        .ID_LoadType          (IEBus.ID_LoadType ),
        .ID_StoreType         (IEBus.ID_StoreType ),
        .ID_RegsWrType        (IEBus.ID_RegsWrType ),
        .ID_WbSel             (IEBus.ID_WbSel ),
        .ID_DstSel            (IEBus.ID_DstSel ),
        .ID_ExceptType        (IEBus.ID_ExceptType ),
        .ID_ALUSrcA           (IEBus.ID_ALUSrcA ),
        .ID_ALUSrcB           (IEBus.ID_ALUSrcB ),
        .ID_RegsReadSel       (IEBus.ID_RegsReadSel ),
        .ID_IsAImmeJump       (IEBus.ID_IsAImmeJump ),
        .ID_BranchType        (IEBus.ID_BranchType ),
        .ID_IsTLBP            (IEBus.ID_IsTLBP),
        .ID_IsTLBW            (IEBus.ID_IsTLBW),
        .ID_IsTLBR            (IEBus.ID_IsTLBR),
        //------------------------output--------------------------//
        .EXE_BusA             (EXE_BusA ),
        .EXE_BusB             (EXE_BusB ),
        .EXE_Imm32            (EXE_Imm32 ),
        .EXE_PC               (EMBus.EXE_PC ),
        .EXE_Instr            (EMBus.EXE_Instr ),
        .EXE_rs               (EXE_rs ),
        .EXE_rt               (EXE_rt ),
        .EXE_rd               (EXE_rd ),
        .EXE_ALUOp            (EXE_ALUOp ),
        .EXE_LoadType         (EMBus.EXE_LoadType ),
        .EXE_StoreType        (EMBus.EXE_StoreType ),
        .EXE_RegsWrType       (EMBus.EXE_RegsWrType ),
        .EXE_WbSel            (EMBus.EXE_WbSel ),
        .EXE_DstSel           (EXE_DstSel ),
        .EXE_ExceptType       (EXE_ExceptType ),
        .EXE_ALUSrcA          (EXE_ALUSrcA ),
        .EXE_ALUSrcB          (EXE_ALUSrcB ),
        .EXE_RegsReadSel      (EMBus.EXE_RegsReadSel ),
        .EXE_IsAImmeJump      (EMBus.EXE_IsAImmeJump ),
        .EXE_BranchType       (EMBus.EXE_BranchType ),
        .EXE_Shamt            (EXE_Shamt ),
        .EXE_IsTLBP           (EMBus.EXE_IsTLBP),
        .EXE_IsTLBW           (EMBus.EXE_IsTLBW),
        .EXE_IsTLBR           (EMBus.EXE_IsTLBR)
    );


    ForwardUnit U_ForwardUnit (
        .WB_RegsWrType        (WB_RegsWrType),
        .MEM_RegsWrType       (EMBus.MEM_RegsWrType),
        .EXE_rs               (EXE_rs),
        .EXE_rt               (EXE_rt),
        .MEM_Dst              (EMBus.MEM_Dst),
        .WB_Dst               (WB_Dst),
        //-----------------output-----------------------------//
        .EXE_ForwardA         (EXE_ForwardA),
        .EXE_ForwardB         (EXE_ForwardB)
    );

    BranchSolve U_BranchSolve (
        .EXE_BranchType       (EMBus.EXE_BranchType),     
        .EXE_OutA             (EXE_BusA_L1),
        .EXE_OutB             (EXE_BusB_L1),
        //-----------------output----------------------------//
        .ID_Flush             (ID_Flush_BranchSolvement)
    );
    
    MUX3to1 #(32) U_MUXA_L1 (
        .d0                   (EXE_BusA),
        .d1                   (EMBus.MEM_Result),
        .d2                   (WB_Result),
        .sel3_to_1            (EXE_ForwardA),
        .y                    (EXE_BusA_L1)
    );//EXE级旁路
    
    MUX4to1 #(32) U_MUXB_L1 (
        .d0                   (EXE_BusB),
        .d1                   (EMBus.MEM_Result),
        .d2                   (WB_Result),
        .sel4_to_1            (EXE_ForwardB),
        .y                    (EXE_BusB_L1)
    );//EXE级旁路

    MUX2to1 #(32) U_MUXA_L2 (
        .d0                   (EXE_BusA_L1),
        .d1                   ({27'b0,EXE_Shamt}),
        .sel2_to_1            (EXE_ALUSrcA),
        .y                    (EXE_BusA_L2)
    );//EXE级三选一A之后的那个二选一

    MUX2to1 #(32) U_MUXB_L2 (
        .d0                   (EXE_BusB_L1),
        .d1                   (EXE_Imm32),
        .sel2_to_1            (EXE_ALUSrcB),//
        .y                    (EXE_BusB_L2)
    );//EXE级四选一B之后的那个二选一

    MUX4to1 #(32) U_MUX_OutB ( 
        .d0                   (EXE_BusB_L1),
        .d1                   (HI_Bus),
        .d2                   (LO_Bus),
        .sel4_to_1            (EMBus.EXE_RegsReadSel),
        .y                    (EMBus.EXE_OutB)
    );

    MUX3to1#(5) U_EXEDstSrc(
        .d0                   (EXE_rd),
        .d1                   (EXE_rt),
        .d2                   (5'd31),
        .sel3_to_1            (EXE_DstSel),
        .y                    (EMBus.EXE_Dst)
    );//EXE级Dst

    ALU U_ALU(
        .EXE_ExceptType       (EXE_ExceptType),
        .EXE_ResultA          (EXE_BusA_L2),
        .EXE_ResultB          (EXE_BusB_L2),
        .EXE_ALUOp            (EXE_ALUOp),
        //---------------------------output-----------------//
        .EXE_ALUOut           (EMBus.EXE_ALUOut),         
        .EXE_ExceptType_new   (EXE_ExceptType_new)
    );

    MULTDIV U_MULTDIV(
        .clk                  (clk),    
        .rst                  (resetn),            
        .EXE_ResultA          (EXE_BusA_L1),
        .EXE_ResultB          (EXE_BusB_L1),
        .ExceptionAssert      (~HiLo_Not_Flush),  // 如果产生flush信号，需要清除状态机
    //---------------------output--------------------------//
        .EXE_ALUOp            (EXE_ALUOp),
        .EXE_MULTDIVtoLO      (EMBus.EXE_Lo),
        .EXE_MULTDIVtoHI      (EMBus.EXE_Hi),
        .EXE_Finish           (EXE_Finish),
        .EXE_MULTDIVStall     (EXE_MULTDIVStall),
        .EXE_MultiExtendOp    (EXE_MultiExtendOp)
    );

    DCacheWen U_DCACHEWEN(
        .EXE_ALUOut(EMBus.EXE_ALUOut),
        .EXE_StoreType(EMBus.EXE_StoreType),
        .EXE_LoadType(EMBus.EXE_LoadType),
        .EXE_ExceptType(EXE_ExceptType_new),
        //-----------------output-------------------------//
        .EXE_ExceptType_new(EMBus.EXE_ExceptType_final),
        .cache_wen(EMBus.DCache_Wen)                   //给出dcache的写使能信号，
    );

    HILO U_HILO (
        .clk                   (clk),
        .rst                   (resetn),
        .MULT_DIV_finish       (EXE_Finish & HiLo_Not_Flush),
        .EXE_MultiExtendOp     (EXE_MultiExtendOp),
        .HIWr                  (EXE_RegsWrType.HIWr & HiLo_Not_Flush), //把写HI，LO统一在EXE级
        .LOWr                  (EXE_RegsWrType.LOWr & HiLo_Not_Flush),
        .Data_Wr               (EXE_BusA_L1),
        .EXE_MULTDIVtoLO       (EXE_MULTDIVtoLO),
        .EXE_MULTDIVtoHI       (EXE_MULTDIVtoHI),
        .HI_Rd                 (HI_Bus),
        .LO_Rd                 (LO_Bus)
    );
    
endmodule