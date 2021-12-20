/*
 * @Author: Seddon Shen
 * @Date: 2021-04-09 17:32:04
 * @LastEditTime: 2021-06-20 17:01:11
 * @LastEditors: npuwth
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \Code\EXT.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module EXT(
    EXE_EXTOp,
    ID_Imm16,
    ID_Imm32
);
    input logic [15:0] ID_Imm16;
    input logic [1:0] EXE_EXTOp;
    output logic [31:0] ID_Imm32;
    always_comb begin
        case (EXE_EXTOp)
            `EXTOP_ZERO:begin
                ID_Imm32 =  {{16{1'b0}},ID_Imm16[15:0]};
            end
            `EXTOP_SIGN:begin
                ID_Imm32 =  {{16{ID_Imm16[15]}},ID_Imm16[15:0]};
            end
            `EXTOP_LUI:begin
                ID_Imm32 =  {ID_Imm16[15:0],{16{1'b0}}};
            end
           default:begin
                ID_Imm32 =  'x;
           end
        endcase
    end
endmodule