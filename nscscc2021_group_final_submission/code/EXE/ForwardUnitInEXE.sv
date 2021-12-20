/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:03:56
 * @LastEditTime: 2021-07-19 23:07:39
 * @LastEditors: Johnson Yang
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \nontrival-cpu\Src\Code\ForwardUnit.sv
 * 
 */ 

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module ForwardUnitInEXE (
    input logic [4:0] EXE_rs,
    input logic [4:0] EXE_rt,
    input logic [4:0] MEM_Dst,
    input RegsWrType  MEM_RegsWrType,
    output logic      EXE_ForwardA,
    output logic      EXE_ForwardB
);
    // 0 选择的是 寄存器中的数据，没有旁路
    // 1 选择的是 MEM_Result中的数据,EXE级旁路
    
    always_comb begin
        if(MEM_RegsWrType.RFWr        && MEM_Dst !=5'd0 && EXE_rs == MEM_Dst )begin
            EXE_ForwardA = 1'b1;
        end
        else begin
            EXE_ForwardA = 1'b0;
        end
    end
    always_comb begin
        if(MEM_RegsWrType.RFWr        && MEM_Dst !=5'd0 && EXE_rt == MEM_Dst )begin
            EXE_ForwardB = 1'b1;
        end
        else begin
            EXE_ForwardB = 1'b0;
        end
    end

endmodule
