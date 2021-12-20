/*
 * @Author: Johnson Yang
 * @Date: 2021-07-12 18:10:55
 * @LastEditTime: 2021-08-15 23:11:21
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"

module TOP_PREIF ( 
    input logic                 clk,
    input logic                 resetn,
    input logic                 PREIF_Wr,

    input logic [31:0]          MEM_CP0Epc,
    input logic [1:0]           EX_Entry_Sel,
    // input BranchType            EXE_BranchType,
    input logic [31:0]          MEM_PC,
    input logic [31:0]          Exception_Vector,
    input TLB_Entry             I_TLBEntry,
    input logic                 s0_found,
    input logic                 TLBBuffer_Flush,
    input logic                 IReq_valid,
    input logic [31:0]          EXE_Correction_Vector,
    input logic                 EXE_Prediction_Failed,
    input logic                 EXE_PF_FlushAll,
    input logic [2:0]           CP0_Config_K0,
    input CacheType             MEM_CacheType,
    input logic [31:0]          MEM_ALUOut,
    input logic                 MEM_Refetch,
    PREIF_IF_Interface          PIBus,
    CPU_IBus_Interface          cpu_ibus,
    AXI_IBus_Interface          axi_ibus,
    AXI_UNCACHE_Interface       axi_iubus,
//---------------------------output----------------------------------//
    output logic [31:13]        I_VPN2,
    output logic                I_IsTLBStall
);
    logic   [31:0]              PREIF_PC;
    logic   [31:0]              PREIF_NPC;
    logic   [31:0]              PC_4;
    logic   [2:0]               PCSel;

    logic   [1:0]               IF_TLBExceptType;
    logic   [31:12]             Phsy_Iaddr;
    logic                       I_IsCached;
    logic                       I_IsTLBBufferValid;

    assign PC_4              =   PREIF_PC + 4;
    // assign ID_PCAdd4         =   ID_PC+4;
    // assign JumpAddr          =   {ID_PCAdd4[31:28],ID_Instr[25:0],2'b0};
    // assign BranchAddr        =   EXE_PC+4+{EXE_Imm32[29:0],2'b0};

    assign PIBus.PREIF_PC    = PREIF_PC;

    always_comb begin
        if(IF_TLBExceptType == `IF_TLBRefill) begin
            PIBus.PREIF_ExceptType = {10'b0,1'b1,7'b0,MEM_Refetch};
        end
        else if(IF_TLBExceptType == `IF_TLBInvalid) begin
            PIBus.PREIF_ExceptType = {11'b0,1'b1,6'b0,MEM_Refetch};
        end
        else begin
            PIBus.PREIF_ExceptType = {18'b0,MEM_Refetch};
        end
    end

    PC U_PC ( 
        .clk            (clk),
        .rst            (resetn),
        .PREIF_Wr       (PREIF_Wr),
        .PREIF_NPC      (PREIF_NPC),
        //---------------output----------------//
        .PREIF_PC       (PREIF_PC)
    );

    MUX6to1 U_PCMUX (
        .d0             (MEM_CP0Epc),            //Eret
        .d1             (Exception_Vector),      //异常处理的地址
        .d2             (MEM_PC),                //用于Refetch
        .d3             (EXE_Correction_Vector), //来自EXE的校正
        .d4             (PC_4),                  //PC+4
        .d5             (PIBus.IF_Target),
        .sel6_to_1      (PCSel),
        //---------------output----------------//
        .y              (PREIF_NPC)
    );

    PCSEL U_PCSEL(
        .BPU_Valid      (PIBus.IF_BPUValid),
        .EXE_Prediction_Failed(EXE_Prediction_Failed),
        .EXE_PF_FlushAll(EXE_PF_FlushAll),
        .EX_Entry_Sel   (EX_Entry_Sel),
        //---------------output-------------------//
        .PCSel          (PCSel)
    );

    //---------------------------------cache--------------------------------// 
    assign cpu_ibus.tag       = Phsy_Iaddr[31:12];
    assign {cpu_ibus.index,cpu_ibus.offset} = (MEM_CacheType.isIcache)?MEM_ALUOut[11:0]:PREIF_PC[11:0];    // 如果D$ busy 则将PC送给I$ ,否则送NPC
    assign cpu_ibus.isCache   = I_IsCached;
    assign cpu_ibus.valid     = IReq_valid && I_IsTLBBufferValid && (PREIF_PC[1:0] == 2'b0) && (MEM_CacheType.isIcache == 1'b0);//TODO:
    assign cpu_ibus.cacheType = MEM_CacheType;

`ifdef DEBUG  // compatible for verilator 
    Icache #(
        .DATA_WIDTH      (32),
        .LINE_WORD_NUM   (`ICACHE_LINE_WORD ),
        .ASSOC_NUM       (`ICACHE_SET_ASSOC ),
        .WAY_SIZE        (4*1024*8 )
    )
    U_Icache (
        .clk             (clk ),
        .resetn          (resetn ),
        .cpu_bus         (cpu_ibus),
        .axi_ubus        (axi_iubus),
        .axi_bus         ( axi_ibus)
    );

`else   // for vivado 
    Icache #(
        .DATA_WIDTH      (32),
        .LINE_WORD_NUM   (`ICACHE_LINE_WORD ),
        .ASSOC_NUM       (`ICACHE_SET_ASSOC ),
        .WAY_SIZE        (4*1024*8 )
    )
    U_Icache (
        .clk             (clk ),
        .resetn          (resetn ),
        .cpu_bus         (cpu_ibus.slave ),
        .axi_ubus        (axi_iubus.master ),
        .axi_bus         ( axi_ibus.master )
    );
`endif

    ITLB U_ITLB (
        .clk             (clk ),
        .rst             (resetn ),
        .Virt_Iaddr      (PREIF_PC[31:12] ),
        .TLBBuffer_Flush (TLBBuffer_Flush ),
        .I_TLBEntry      (I_TLBEntry ),
        .s0_found        (s0_found ),
        .CP0_Config_K0   (CP0_Config_K0),
    //--------------------output----------------------//    
        .Phsy_Iaddr      (Phsy_Iaddr ),
        .I_IsCached      (I_IsCached ),
        .I_IsTLBBufferValid(I_IsTLBBufferValid ),
        .I_IsTLBStall    (I_IsTLBStall ),
        .IF_TLBExceptType(IF_TLBExceptType ),
        .I_VPN2          ( I_VPN2)
  );


endmodule