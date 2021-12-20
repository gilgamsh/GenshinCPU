/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-08-14 22:58:53
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
    
    input logic [31:0]       MEM_Result,  //写寄存器堆来自MEM
    input logic [4:0]        MEM_Dst,
    input RegsWrType         MEM_RegsWrType,
    input logic [31:0]       MEM2_Result, //写寄存器堆来自MEM2
    input logic [4:0]        MEM2_Dst,
    input RegsWrType         MEM2_RegsWrType,
    input logic [31:0]       WB_Result,   //写寄存器堆来自WB
    input logic [4:0]        WB_Dst,
    input RegsWrType         WB_RegsWrType,

    input logic [4:0]        MEM_rt,      //用于DataHazard检测
    input logic              MEM_ReadMEM, // MEM级的load信号     
    input logic [4:0]        MEM2_rt,
    input logic              MEM2_ReadMEM,
    input logic              ID_DisWr,   
    input logic              MEM_IsMFC0,
    input logic              MEM_Refetch,
    IF_ID_Interface          IIBus,
    ID_EXE_Interface         IEBus,
    //---------------------------output------------------------------//   
    output logic             ID_EX_DH_Stall,
    output logic             ID_MEM1_DH_Stall,
    output logic             ID_MEM2_DH_Stall
);
    logic [15:0]             ID_Imm16;
    logic [1:0]              ID_EXTOp;
    logic [31:0]             RF_BusA;  //从寄存器堆读出的数据
    logic [31:0]             RF_BusB;
    logic [1:0]              ID_rsrtRead;
    ExceptinPipeType         ID_ExceptType;
    logic [2: 0]             ID_ForwardA;
    logic [2: 0]             ID_ForwardB;
    logic [4:0]              ID_rs;
    logic [4:0]              ID_rt;

    LoadType                 ID_LoadType;
    StoreType                ID_StoreType;
    RegsWrType               ID_RegsWrType;

    logic [31:0]             ID_PCAdd4;
    logic [31:0]             ID_PCAdd8;
    logic [31:0]             JumpAddr;
    logic [31:0]             BranchAddr;
    logic [31:0]             BranchImme;
    logic                    ID_Refetch;
    logic                    ID_Valid;

    assign ID_Refetch = MEM_Refetch && IEBus.ID_Valid;

    assign ID_rs          = IEBus.ID_rs;
    assign ID_rt          = IEBus.ID_rt;
    assign IEBus.ID_LoadType   = (ID_DisWr) ? '0 : ID_LoadType; 
    assign IEBus.ID_StoreType  = (ID_DisWr) ? '0 : ID_StoreType; 
    assign IEBus.ID_RegsWrType = (ID_DisWr) ? '0 : ID_RegsWrType;  
    //将EXE中BranchSolve的部分任务在这里完成
    assign ID_PCAdd4      = IEBus.ID_PC + 4;
    assign ID_PCAdd8      = IEBus.ID_PC + 8;
    assign BranchImme     = {{16{ID_Imm16[15]}},ID_Imm16};
    assign JumpAddr       = {ID_PCAdd4[31:28],IEBus.ID_Instr[25:0],2'b0};
    assign BranchAddr     = ID_PCAdd4 + {BranchImme[29:0],2'b0};//TODO:给它单独进行扩展，不过译码Decode，不过EXT
    // assign IEBus.ID_Branch_Success = (IEBus.ID_PResult.Target == BranchAddr);
    assign IEBus.ID_J_Success      = (IEBus.ID_PResult.Target == JumpAddr);
    assign IEBus.ID_PC8_Success    = (IEBus.ID_PResult.Target == ID_PCAdd8);
    assign IEBus.ID_JumpAddr       = JumpAddr;
    assign IEBus.ID_BranchAddr     = BranchAddr;
    assign IEBus.ID_PCAdd8         = ID_PCAdd8;

    ID_Reg U_ID_REG ( 
        .clk                 (clk ),
        .rst                 (resetn ),
        .ID_Flush            (ID_Flush ),
        .ID_Wr               (ID_Wr ),
        .IF_Instr            (IIBus.IF_Instr ),
        .IF_PC               (IIBus.IF_PC ),
        .IF_ExceptType       (IIBus.IF_ExceptType),
        .IF_PResult          (IIBus.IF_PResult),
        .IF_Valid            (IIBus.IF_Valid),
    //------------------out----------------------------------------//        
        .ID_Instr            (IEBus.ID_Instr ),
        .ID_Imm16            (ID_Imm16 ),
        .ID_rs               (IEBus.ID_rs ),
        .ID_rt               (IEBus.ID_rt ),
        .ID_rd               (IEBus.ID_rd ),
        .ID_PC               (IEBus.ID_PC ),
        .ID_ExceptType       (ID_ExceptType),
        .ID_PResult          (IEBus.ID_PResult),
        .ID_Valid            (IEBus.ID_Valid)
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
    // ID级旁路MEM MEM2的数据
    MUX5to1 #(32) U_MUXA_L1 (
        .d0                   (RF_BusA),
        .d1                   (IEBus.EXE_Result),
        .d2                   (MEM_Result),
        .d3                   (MEM2_Result),       
        .d4                   (WB_Result),
        .sel5_to_1            (ID_ForwardA),     
        .y                    (IEBus.ID_BusA)
    );//EXE级旁路

    // ID级旁路MEM MEM2的数据
    MUX5to1 #(32) U_MUXB_L1 (
        .d0                   (RF_BusB),
        .d1                   (IEBus.EXE_Result),
        .d2                   (MEM_Result),
        .d3                   (MEM2_Result),       
        .d4                   (WB_Result),
        .sel5_to_1            (ID_ForwardB),      
        .y                    (IEBus.ID_BusB)
    );//EXE级旁路

    ForwardUnitInID U_ForwardUnitInID (
        .EXE_RegsWrType      (IEBus.EXE_RegsWrType ),
        .MEM_RegsWrType      (MEM_RegsWrType ),
        .MEM2_RegsWrType     (MEM2_RegsWrType ),
        .WB_RegsWrType       (WB_RegsWrType),
        .EXE_Dst             (IEBus.EXE_Dst ),
        .MEM_Dst             (MEM_Dst ),
        .MEM2_Dst            (MEM2_Dst ),
        .WB_Dst              (WB_Dst),
        .ID_rs               (ID_rs ),
        .ID_rt               (ID_rt ),
        .ID_ForwardA         (ID_ForwardA ),
        .ID_ForwardB         (ID_ForwardB)
    );

//-----------------------------------------------------------------//
    Decode U_Decode (
        .ID_Instr            (IEBus.ID_Instr),
        .ID_ExceptType       (ID_ExceptType),
        .ID_Refetch          (ID_Refetch),
//--------------------------out-------------------------------------//
        .ID_ALUOp            (IEBus.ID_ALUOp),
        .ID_LoadType         (ID_LoadType),
        .ID_StoreType        (ID_StoreType),
        .ID_RegsWrType       (ID_RegsWrType),
        .ID_WbSel            (IEBus.ID_WbSel),
        .ID_DstSel           (IEBus.ID_DstSel),
        .ID_ExceptType_new   (IEBus.ID_ExceptType_new),
        .ID_ALUSrcA          (IEBus.ID_ALUSrcA),
        .ID_ALUSrcB          (IEBus.ID_ALUSrcB),
        .ID_RegsReadSel      (IEBus.ID_RegsReadSel),
        .ID_EXTOp            (ID_EXTOp),
        .ID_IsAJumpCall      (IEBus.ID_IsAJumpCall),
        .ID_BranchType       (IEBus.ID_BranchType),
        .ID_rsrtRead         (ID_rsrtRead),
        .ID_IsTLBP           (IEBus.ID_IsTLBP),
        .ID_IsTLBW           (IEBus.ID_IsTLBW),
        .ID_IsTLBR           (IEBus.ID_IsTLBR),
        .ID_TLBWIorR         (IEBus.ID_TLBWIorR),
        .ID_TrapOp           (IEBus.ID_TrapOp),
        .ID_IsMFC0           (IEBus.ID_IsMFC0),
        .ID_IsBrchLikely     (IEBus.ID_IsBrchLikely),
        .ID_CacheType        (IEBus.ID_CacheType),
        .ID_IsBranch         (IIBus.ID_IsBranch),
        .ID_IsMOVN           (IEBus.ID_IsMOVN),
        .ID_IsMOVZ           (IEBus.ID_IsMOVZ)
    );
     

    DataHazard U_DataHazard ( 
        .ID_rs               (IEBus.ID_rs),
        .ID_rt               (IEBus.ID_rt),
        .ID_rsrtRead         (ID_rsrtRead),//这个信号在Control里的生成有问题
        .EXE_rt              (IEBus.EXE_rt),
        .EXE_ReadMEM         (IEBus.EXE_LoadType.ReadMem),
        .MEM_rt              (MEM_rt ),
        .MEM_ReadMEM         (MEM_ReadMEM ),
        .MEM2_rt             (MEM2_rt),
        .MEM2_ReadMEM        (MEM2_ReadMEM),
        .EXE_IsMFC0          (IEBus.EXE_IsMFC0),
        .MEM_IsMFC0          (MEM_IsMFC0),
        //-----------------------output-----------------------//
        .ID_EX_DH_Stall      (ID_EX_DH_Stall),
        .ID_MEM1_DH_Stall    (ID_MEM1_DH_Stall),
        .ID_MEM2_DH_Stall    (ID_MEM2_DH_Stall)
    );

endmodule  

