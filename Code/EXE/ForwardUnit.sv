/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:03:56
 * @LastEditTime: 2021-07-06 09:20:32
 * @LastEditors: npuwth
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \nontrival-cpu\Src\Code\ForwardUnit.sv
 * 
 */ 

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module ForwardUnit (
    input RegsWrType  WB_RegsWrType,
    input RegsWrType  MEM_RegsWrType,
    input logic [4:0] EXE_rs,
    input logic [4:0] EXE_rt,
    input logic [4:0] MEM_Dst,
    input logic [4:0] WB_Dst,
    output logic [1:0] EXE_ForwardA,
    output logic [1:0] EXE_ForwardB
);
    // 00 选择的是 寄存器中的数据，没有旁路
    // 01 选择的是 MEM_Result中的数据,EXE级旁路
    // 10 选择的是 WB_Result中的数据,MEM级旁路
    
    always_comb begin
        if(MEM_RegsWrType.RFWr && MEM_Dst!=5'd0 && EXE_rs == MEM_Dst)begin
            EXE_ForwardA =2'b01;
        end
        else if (WB_RegsWrType.RFWr && WB_Dst!=5'd0 && EXE_rs == WB_Dst) begin
            EXE_ForwardA =2'b10;
        end
        else begin
            EXE_ForwardA =2'b00;
        end
    end
    always_comb begin
        if(MEM_RegsWrType.RFWr && MEM_Dst!=5'd0 && EXE_rt == MEM_Dst)begin
            EXE_ForwardB =2'b01;
        end
        else if (WB_RegsWrType.RFWr && WB_Dst!=5'd0 && EXE_rt == WB_Dst) begin
            EXE_ForwardB =2'b10;
        end
        else begin
            EXE_ForwardB =2'b00;
        end
    end

endmodule
