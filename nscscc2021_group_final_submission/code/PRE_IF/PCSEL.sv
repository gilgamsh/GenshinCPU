/*
 * @Author: Juan Jiang
 * @Date: 2021-04-03 16:28:13
 * @LastEditTime: 2021-08-11 18:07:46
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: this is a module to produce the signal to choose which is  the next PC
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module PCSEL (
    input logic          BPU_Valid,
    input logic          EXE_Prediction_Failed,
    input logic          EXE_PF_FlushAll,
    input logic  [1:0]   EX_Entry_Sel,
    output logic [2:0]   PCSel
);

    always_comb begin 
        case(EX_Entry_Sel)
        `IsNone: begin
            if(EXE_Prediction_Failed||EXE_PF_FlushAll)      PCSel = `PCSel_Correct;
            else if(BPU_Valid == 1'b1) PCSel = `PCSel_Target;
            else                       PCSel = `PCSel_PC4;
        end
        `IsEret: begin
            PCSel = `PCSel_EPC;
        end
        `IsRefetch: begin
            PCSel = `PCSel_MEMPC;
        end
        default: begin
            PCSel = `PCSel_Except;
        end
        endcase
    end
    
endmodule 
