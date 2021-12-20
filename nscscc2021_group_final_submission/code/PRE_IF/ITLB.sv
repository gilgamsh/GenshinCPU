/*
 * @Author: npuwth
 * @Date: 2021-07-16 17:37:05
 * @LastEditTime: 2021-08-16 00:58:47
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CPU_Defines.svh"
`include "../CommonDefines.svh"

`define IDLE               1'b0
`define SEARCH             1'b1

module ITLB ( 
    input logic                   clk,
    input logic                   rst,
    input logic  [31:12]          Virt_Iaddr,
    input logic                   TLBBuffer_Flush,
    input TLB_Entry               I_TLBEntry,//来自TLB
    input logic                   s0_found,  //来自TLB
    input logic  [2:0]            CP0_Config_K0,
    output logic [31:12]          Phsy_Iaddr,
    output logic                  I_IsCached,
    output logic                  I_IsTLBBufferValid,
    output logic                  I_IsTLBStall,
    output logic [1:0]            IF_TLBExceptType,
    output logic [31:13]          I_VPN2
);

`ifdef  EN_TLB
    logic                         I_TLBState;
    logic                         I_TLBNextState;
    TLB_Buffer                    I_TLBBuffer;
    logic                         I_TLBBuffer_Wr;
    logic                         I_TLBBufferHit;
//----------------TLB Buffer Hit信号的生成-------------------------//
    always_comb begin //TLBI
        if(Virt_Iaddr[31:28] < 4'hC && Virt_Iaddr[31:28] > 4'h7) begin
            I_TLBBufferHit = 1'b1;
        end
        else if((Virt_Iaddr[31:13] == I_TLBBuffer.VPN2) && I_TLBBuffer.Valid) begin
            I_TLBBufferHit = 1'b1;
        end
        else begin
            I_TLBBufferHit = 1'b0;
        end
    end

    assign I_IsTLBStall    = ~ I_TLBBufferHit;         //在TLB Buffer miss时下一拍进行search，需要进行阻塞

//---------------状态机控制逻辑-------------------------------------//
    assign I_TLBBuffer_Wr  = (I_TLBState == `SEARCH);  //在search状态下打开TLB Buffer的写使能

    always_comb begin
        if(rst == `RstEnable) begin
            I_TLBNextState = `IDLE;
        end
        else if(I_TLBBufferHit == 1'b0) begin
            I_TLBNextState = `SEARCH;
        end
        else begin
            I_TLBNextState = `IDLE;
        end
    end

    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            I_TLBState     = `IDLE;
        end
        else begin
            I_TLBState     = I_TLBNextState;
        end
    end
//---------------------------根据TLB进行虚实地址转换---------------------//
    always_comb begin //TLBI
        if(Virt_Iaddr[31:28] < 4'hC && Virt_Iaddr[31:28] > 4'h9) begin
            Phsy_Iaddr        = {Virt_Iaddr[31:28] - 4'hA,Virt_Iaddr[27:12]}; 
        end
        else if(Virt_Iaddr[31:28] < 4'hA && Virt_Iaddr[31:28] > 4'h7) begin
            Phsy_Iaddr        = {Virt_Iaddr[31:28] - 4'h8,Virt_Iaddr[27:12]};
        end
        else if(Virt_Iaddr[12] == 1'b0) begin                            //根据TLB Buffer进行转换
            Phsy_Iaddr        = I_TLBBuffer.PFN0;
        end
        else begin
            Phsy_Iaddr        = I_TLBBuffer.PFN1;
        end
    end
//-----------------------------对Cache属性进行判断-----------------------//
`ifdef All_Uncache
    assign I_IsCached                                = 1'b0;
`else
    always_comb begin //TLBI
        if(Virt_Iaddr[31:28] < 4'hC && Virt_Iaddr[31:28] > 4'h9) begin
            I_IsCached                               = 1'b0;
        end
        else if(Virt_Iaddr[31:28] < 4'hA && Virt_Iaddr[31:28] > 4'h7) begin
            if(CP0_Config_K0 == 3'b011) begin
                I_IsCached                           = 1'b1;
            end
            else begin
                I_IsCached                           = 1'b0;
            end
        end
        else begin
            if(Virt_Iaddr[12] == 1'b0) begin
                if(I_TLBBuffer.C0 == 3'b011)  I_IsCached           = 1'b1;
                else                          I_IsCached           = 1'b0;
            end
            else begin
                if(I_TLBBuffer.C1 == 3'b011)  I_IsCached           = 1'b1;
                else                          I_IsCached           = 1'b0;
            end
        end
    end
`endif
    // assign I_IsCached                 = 1'b1;

//-----------------------------对TLB Buffer进行赋值----------------------、、
    always_ff @(posedge clk ) begin //TLBI
        if(rst == `RstEnable || TLBBuffer_Flush == 1'b1) begin
            I_TLBBuffer.VPN2          <= '0;
            I_TLBBuffer.ASID          <= '0;
            I_TLBBuffer.G             <= '0;
            I_TLBBuffer.PFN0          <= '0;
            I_TLBBuffer.C0            <= '0;
            I_TLBBuffer.D0            <= '0;
            I_TLBBuffer.V0            <= '0;
            I_TLBBuffer.PFN1          <= '0;
            I_TLBBuffer.C1            <= '0;
            I_TLBBuffer.D1            <= '0;
            I_TLBBuffer.V1            <= '0;
            I_TLBBuffer.Valid         <= '0;
            I_TLBBuffer.IsInTLB       <= '0;
        end
        else if(I_TLBBuffer_Wr ) begin
            I_TLBBuffer.VPN2          <= Virt_Iaddr[31:13];
            I_TLBBuffer.ASID          <= I_TLBEntry.ASID;
            I_TLBBuffer.G             <= I_TLBEntry.G;
            I_TLBBuffer.PFN0          <= I_TLBEntry.PFN0;
            I_TLBBuffer.C0            <= I_TLBEntry.C0;
            I_TLBBuffer.D0            <= I_TLBEntry.D0;
            I_TLBBuffer.V0            <= I_TLBEntry.V0;
            I_TLBBuffer.PFN1          <= I_TLBEntry.PFN1;
            I_TLBBuffer.C1            <= I_TLBEntry.C1;
            I_TLBBuffer.D1            <= I_TLBEntry.D1;
            I_TLBBuffer.V1            <= I_TLBEntry.V1;
            I_TLBBuffer.Valid         <= 1'b1;
            I_TLBBuffer.IsInTLB       <= s0_found;
        end
    end

    assign I_VPN2                     = Virt_Iaddr[31:13];
//------------------------------对异常和Valid信号进行赋值----------------------------------------------//
    always_comb begin //TLBI
        if(Virt_Iaddr[31:28] < 4'hC && Virt_Iaddr[31:28] > 4'h7) begin  //不走TLB，认为有效，没有异常
            I_IsTLBBufferValid                              = 1'b1; 
            IF_TLBExceptType                                = `IF_TLBNoneEX;
        end
        else if(I_TLBBufferHit == 1'b0) begin //TLB Buffer没有命中，下一拍是search，valid无效，但exception不赋值，因为还不知道是什么例外类型
            I_IsTLBBufferValid                              = 1'b0;
            IF_TLBExceptType                                = `IF_TLBNoneEX;
        end
        else if(I_TLBBuffer.IsInTLB == 1'b1 ) begin //说明TLB Buffer里面命中了，否则是缺页
            if(Virt_Iaddr[12] == 1'b0) begin
                if(I_TLBBuffer.V0 == 1'b0) begin //无效异常
                    I_IsTLBBufferValid                      = 1'b0; 
                    IF_TLBExceptType                        = `IF_TLBInvalid;
                end
                else begin
                    I_IsTLBBufferValid                      = 1'b1;
                    IF_TLBExceptType                        = `IF_TLBNoneEX;
                end
            end
            else begin
                if(I_TLBBuffer.V1 == 1'b0) begin
                    I_IsTLBBufferValid                      = 1'b0;
                    IF_TLBExceptType                        = `IF_TLBInvalid;
                end
                else begin
                    I_IsTLBBufferValid                      = 1'b1;
                    IF_TLBExceptType                        = `IF_TLBNoneEX;
                end                     
            end
        end
        else begin     //说明缺页异常
            I_IsTLBBufferValid                              = 1'b0;
            IF_TLBExceptType                                = `IF_TLBRefill;
        end
    end
`else 
    always_comb begin //TLBI
        if(Virt_Iaddr[31:28] < 4'hC && Virt_Iaddr[31:28] > 4'h9) begin
            Phsy_Iaddr        = {Virt_Iaddr[31:28] - 4'hA,Virt_Iaddr[27:12]}; 
        end
        else if(Virt_Iaddr[31:28] < 4'hA && Virt_Iaddr[31:28] > 4'h7) begin
            Phsy_Iaddr        = {Virt_Iaddr[31:28] - 4'h8,Virt_Iaddr[27:12]};
        end
        else begin
            Phsy_Iaddr        = Virt_Iaddr;
        end
    end
`ifdef All_Uncache
    assign I_IsCached         = 1'b0;
`else 
    always_comb begin
        if(Virt_Iaddr[31:28] < 4'hC && Virt_Iaddr[31:28] > 4'h9) begin
            I_IsCached                               = 1'b0;
        end
        else if(Virt_Iaddr[31:28] < 4'hA && Virt_Iaddr[31:28] > 4'h7) begin
            if(CP0_Config_K0 == 3'b011) begin
                I_IsCached                           = 1'b1;
            end
            else begin
                I_IsCached                           = 1'b0;
            end
        end
        else begin
            I_IsCached                               = 1'b1;
        end
    end
`endif
    assign I_IsTLBBufferValid = 1'b1;
    assign IF_TLBExceptType   = `IF_TLBNoneEX;
    assign I_IsTLBStall       = 1'b0;
`endif
endmodule
