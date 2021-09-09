/*
 * @Author: Johnson Yang
 * @Date: 2021-03-27 17:12:06
 * @LastEditTime: 2021-07-06 22:34:26
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 协处理器CP0（实现了CP0中的 BadVAddr、Count、Compare、Status、Cause、EPC6个寄存器的部分功能）
 * 
 */
 

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module cp0_reg (  
    input logic             clk,
    input logic             rst,
    input logic  [5:0]      Interrupt,                 //6个外部硬件中断输入 
    // read port        
    input logic  [4:0]      CP0_RdAddr,                //要读取的CP0寄存器的地址
    output logic [31:0]     CP0_RdData,                //读出的CP0某个寄存器的值 
    //write port from reg
    input RegsWrType        MEM_RegsWrType,
    input logic  [4:0]      MEM_Dst,
    input logic  [31:0]     MEM_Result,
    //write port from tlb
    input                   MEM_IsTLBP,                //写index寄存器
    input logic             MEM_IsTLBR,                //写EntryHi，EntryLo0，EntryLo1
    CP0_MMU_Interface       CMBus, 
    //exception
    input ExceptinPipeType  WB_ExceptType,
    input logic  [31:0]     WB_PC,
    input logic             WB_IsInDelaySlot,
    input logic  [31:0]     WB_ALUOut
    );

    logic                   TimCount2;
    logic                   CP0_TimerInterrupt;         //是否有定时中断发生
    
    cp0_regs CP0;
    
    // always_ff @(posedge clk ) begin
    //     if(rst == `RstEnable) begin
    //         CP0.
    //     end
    // end



    //read port
    always_comb begin
        case(CP0_RdAddr)
            `CP0_REG_INDEX:      CP0_RdData = {CP0.Index.P,27'b0,CP0.Index.Index};
            `CP0_REG_ENTRYLO0:   CP0_RdData = {6'b0,CP0.EntryLo0.PFN0,CP0.EntryLo0.C0,CP0.EntryLo0.D0,CP0.EntryLo0.V0,CP0.EntryLo0.G0};
            `CP0_REG_ENTRYLO1:   CP0_RdData = {6'b0,CP0.EntryLo1.PFN1,CP0.EntryLo1.C1,CP0.EntryLo1.D1,CP0.EntryLo1.V1,CP0.EntryLo1.G1};
            `CP0_REG_BADVADDR:   CP0_RdData = CP0.BadVAddr;
            `CP0_REG_COUNT:      CP0_RdData = CP0.Count;
            `CP0_REG_ENTRYHI:    CP0_RdData = {CP0.EntryHi.VPN2,5'b0,CP0.EntryHi.ASID};
            `CP0_REG_COMPARE:    CP0_RdData = CP0.Compare;
            `CP0_REG_STATUS:     CP0_RdData = {9'b0,1'b1,6'b0,CP0.Status.IM7_0,6'b0,CP0.Status.EXL,CP0.Status.IE};
            `CP0_REG_CAUSE:      CP0_RdData = {CP0.Cause.BD,CP0.Cause.TI,14'b0,CP0.Cause.IP7_2,CP0.Cause.IP1_0,1'b0,CP0.Cause.ExcCode,2'b0};
            `CP0_REG_EPC:        CP0_RdData = CP0.EPC;
            default:             CP0_RdData = 'x;
        endcase
    end

    //与TLB交互
    assign CMBus.CP0_index      = CP0.Index.Index;
    assign CMBus.CP0_vpn2       = CP0.EntryHi.VPN2;
    assign CMBus.CP0_asid       = CP0.EntryHi.ASID;
    assign CMBus.CP0_pfn0       = CP0.EntryLo0.PFN0;
    assign CMBus.CP0_c0         = CP0.EntryLo0.C0;
    assign CMBus.CP0_d0         = CP0.EntryLo0.D0;
    assign CMBus.CP0_v0         = CP0.EntryLo0.V0;
    assign CMBus.CP0_g0         = CP0.EntryLo0.G0;
    assign CMBus.CP0_pfn1       = CP0.EntryLo1.PFN1;
    assign CMBus.CP0_c1         = CP0.EntryLo1.C1;
    assign CMBus.CP0_d1         = CP0.EntryLo1.D1;
    assign CMBus.CP0_v1         = CP0.EntryLo1.V1;
    assign CMBus.CP0_g1         = CP0.EntryLo1.G1;
endmodule
