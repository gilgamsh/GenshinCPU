/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-07-06 21:39:22
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module TOP_ID (
    input logic              clk,
    input logic              resetn,
    input logic              ID_Flush,
    input logic              ID_Wr,
    input logic [31:0]       WB_Result,  //写寄存器堆来自WB
    input logic [4:0]        WB_Dst,
    input RegsWrType         WB_RegsWrType,
    IF_ID_Interface          IIBus,//TODO: 不如改成IF_ID_Bus 
    ID_EXE_Interface         IEBus,
    //---------------------------output------------------------------//   
    output logic             ID_IsAImmeJump,  //用于PCSel，表示是j，jal跳转
    output logic             DH_IDWr,
    output logic             DH_PCWr,
    output logic             EXE_Flush_DataHazard
);
    logic [15:0]             ID_Imm16;
    logic [1:0]              ID_EXTOp;
    logic [31:0]             RF_BusA;  //从寄存器堆读出的数据
    logic [31:0]             RF_BusB;
    logic                    ID_RF_ForwardA;
    logic                    ID_RF_ForwardB;

    assign IIBus.ID_Instr = IEBus.ID_Instr;//用于IF级的NPC
    assign IIBus.ID_PC    = IEBus.ID_PC;   //用于IF级的NPC
    assign ID_IsAImmeJump = IEBus.ID_IsAImmeJump;

    ID_Reg U_ID_Reg ( 
        .clk                 (clk ),
        .rst                 (resetn ),
        .ID_Flush            (ID_Flush ),
        .ID_Wr               (ID_Wr ),
        .IF_Instr            (IIBus.IF_Instr ),
        .IF_PC               (IIBus.IF_PC ),
    //------------------out----------------------------------------//        
        .ID_Instr            (IEBus.ID_Instr ),
        .ID_Imm16            (ID_Imm16 ),
        .ID_rs               (IEBus.ID_rs ),
        .ID_rt               (IEBus.ID_rt ),
        .ID_rd               (IEBus.ID_rd ),
        .ID_PC               (IEBus.ID_PC )
    );

    EXT U_EXT ( 
        .EXE_EXTOp           (ID_EXTOp),
        .ID_Imm16            (ID_Imm16),
        .ID_Imm32            (IEBus.ID_Imm32)
    );

    RF U_RF (
        .clk                 (clk),
        .rst                 (resetn),
        .WB_Dst              (WB_Dst),
        .WB_Result           (WB_Result),
        .RFWr                (WB_RegsWrType.RFWr),
        .ID_rs               (IEBus.ID_rs),
        .ID_rt               (IEBus.ID_rt),
    //-------------------out--------------------------------------------//
        .ID_BusA             (RF_BusA),
        .ID_BusB             (RF_BusB)
    );
//---------------------------对RF读出的数据进行WB/ID级旁路------------//
    assign ID_RF_ForwardA = WB_RegsWrType.RFWr && (WB_Dst == IEBus.ID_rs);
    assign ID_RF_ForwardB = WB_RegsWrType.RFWr && (WB_Dst == IEBus.ID_rt);

    MUX2to1 #(32) U_MUX_RF_FORWARDA ( 
        .d0                  (RF_BusA),
        .d1                  (WB_Result),
        .sel2_to_1           (ID_RF_ForwardA),
        .y                   (IEBus.ID_BusA)
    );
    
    MUX2to1 #(32) U_MUX_RF_FORWARDB ( 
        .d0                  (RF_BusB),
        .d1                  (WB_Result),
        .sel2_to_1           (ID_RF_ForwardB),
        .y                   (IEBus.ID_BusB)
    );

//-----------------------------------------------------------------//
    Control U_Control (
        .ID_Instr            (IEBus.ID_Instr),
        .IF_ExceptType       (IIBus.IF_ExceptType),
        .EXE_IsTLBW          (IEBus.EXE_IsTLBW),
        .EXE_IsTLBR          (IEBus.EXE_IsTLBR),
//--------------------------out-------------------------------------//
        .ID_ALUOp            (IEBus.ID_ALUOp),
        .ID_LoadType         (IEBus.ID_LoadType),
        .ID_StoreType        (IEBus.ID_StoreType),
        .ID_RegsWrType       (IEBus.ID_RegsWrType),
        .ID_WbSel            (IEBus.ID_WbSel),
        .ID_DstSel           (IEBus.ID_DstSel),
        .ID_ExceptType       (IEBus.ID_ExceptType),
        .ID_ALUSrcA          (IEBus.ID_ALUSrcA),
        .ID_ALUSrcB          (IEBus.ID_ALUSrcB),
        .ID_RegsReadSel      (IEBus.ID_RegsReadSel),
        .ID_EXTOp            (ID_EXTOp),
        .ID_IsAImmeJump      (IEBus.ID_IsAImmeJump),
        .ID_BranchType       (IEBus.ID_BranchType),
        .ID_rsrtRead         (ID_rsrtRead),
        .ID_IsTLBP           (IEBus.ID_IsTLBP),
        .ID_IsTLBW           (IEBus.ID_IsTLBW),
        .ID_IsTLBR           (IEBus.ID_IsTLBR)
    );

    DataHazard U_DataHazard ( 
        .ID_rs               (ID_rs),
        .ID_rt               (ID_rt),
        .ID_rsrtRead         (ID_rsrtRead),//这个信号在Control里的生成有问题
        .EXE_rt              (IEBus.EXE_rt),
        .EXE_ReadMEM         (IEBus.EXE_LoadType.ReadMem),
        .EXE_Instr           (IEBus.EXE_Instr),
        //-----------------------output-----------------------//
        .PC_Wr               (DH_PCWr),
        .ID_Wr               (DH_IDWr),
        .EXE_Flush           (EXE_Flush_DataHazard)
    );

endmodule  