/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:03:56
 * @LastEditTime: 2021-07-20 22:28:45
 * @LastEditors: npuwth
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \nontrival-cpu\Src\Code\ForwardUnit.sv
 * 
 */ 

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module ForwardUnitInID (
    input RegsWrType   EXE_RegsWrType,
    input RegsWrType   MEM_RegsWrType,
    input RegsWrType   MEM2_RegsWrType,
    input RegsWrType   WB_RegsWrType,
    input logic [4:0]  EXE_Dst,
    input logic [4:0]  MEM_Dst,
    input logic [4:0]  MEM2_Dst,
    input logic [4:0]  WB_Dst,
    input logic [4:0]  ID_rs,
    input logic [4:0]  ID_rt,
    //-------------------output---------------//
    output logic [2:0] ID_ForwardA,
    output logic [2:0] ID_ForwardB
);
    // 00 选择的是 寄存器中的数据，没有旁路
    // 01 选择的是 MEM_Result中的数据,EXE级旁路
    // 10 选择的是 MEM2_RESULT中的数据，MEM2级旁路
    // 11 选择的是 WB_Result中的数据，WB级旁路
    
    always_comb begin
        if      (EXE_RegsWrType.RFWr  && EXE_Dst!=5'd0  && ID_rs == EXE_Dst) begin
            ID_ForwardA = 3'b001;
        end
        else if (MEM_RegsWrType.RFWr  && MEM_Dst !=5'd0 && ID_rs == MEM_Dst )begin
            ID_ForwardA = 3'b010;
        end
        else if (MEM2_RegsWrType.RFWr && MEM2_Dst!=5'd0 && ID_rs == MEM2_Dst) begin
            ID_ForwardA = 3'b011;
        end
        else if (  WB_RegsWrType.RFWr && WB_Dst  !=5'd0 && ID_rs == WB_Dst ) begin
            ID_ForwardA = 3'b100;
        end
        else begin
            ID_ForwardA = 3'b000;
        end
    end
    always_comb begin
        if      (EXE_RegsWrType.RFWr  && EXE_Dst!=5'd0  && ID_rt == EXE_Dst) begin
            ID_ForwardB = 3'b001;
        end
        else if (MEM_RegsWrType.RFWr  && MEM_Dst!=5'd0  && ID_rt == MEM_Dst )begin
            ID_ForwardB = 3'b010;
        end
        else if (MEM2_RegsWrType.RFWr && MEM2_Dst!=5'd0 && ID_rt == MEM2_Dst) begin
            ID_ForwardB = 3'b011;
        end
        else if (  WB_RegsWrType.RFWr && WB_Dst != 5'd0 && ID_rt == WB_Dst) begin
            ID_ForwardB = 3'b100;
        end
        else begin
            ID_ForwardB = 3'b000;
        end
    end

endmodule
