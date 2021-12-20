/*
 * @Author: npuwth
 * @Date: 2021-04-07 14:52:54
 * @LastEditTime: 2021-08-14 00:21:15
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module HILO(
    input logic                rst,
    input logic                clk,
    input logic                MULT_DIV_finish,
    // input logic   [1:0]        EXE_MultiExtendOp,//MADD等指令的拓展信号，到HI LO
    //写端口
    input logic                HIWr,
    input logic                LOWr,
    input logic   [31:0]       Data_Wr,    //  MTLO MTHI
    input logic   [31:0]       EXE_MULTDIVtoLO,  // 乘除法写
    input logic   [31:0]       EXE_MULTDIVtoHI,  // 乘除法写
    //读端口   
    output logic  [31:0]       HI,
    output logic  [31:0]       LO
    );

    always @ ( posedge clk ) begin
        if(rst == `RstEnable) begin
            HI <= `ZeroWord;
        end else if (MULT_DIV_finish == 1'b1 ) begin
            HI <= EXE_MULTDIVtoHI;
        end else if (HIWr == `WriteEnable) begin
            HI <= Data_Wr;
        end 
    end
    always @ ( posedge clk ) begin
        if(rst == `RstEnable) begin
            LO <= `ZeroWord;
        end else if (MULT_DIV_finish == 1'b1 ) begin
            LO <= EXE_MULTDIVtoLO;
        end else if (LOWr == `WriteEnable) begin
            LO <= Data_Wr;
        end
    end
    
endmodule
