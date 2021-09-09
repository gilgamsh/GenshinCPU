/*
 * @Author: npuwth
 * @Date: 2021-03-29 14:36:47
 * @LastEditTime: 2021-06-28 21:54:52
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module EXT2 (
    input logic [31:0]    WB_DMOut,
    input logic [31:0]    WB_ALUOut,
    input LoadType        WB_LoadType,
    output logic [31:0]   WB_DMResult 
);
logic IsUncache;
assign IsUncache = (WB_ALUOut[31:16] == 16'hbfaf && WB_LoadType.ReadMem == 1'b1 ) ? 1'b1 : 1'b0;

    always_comb begin
        unique case({WB_LoadType.sign,WB_LoadType.size})
          `LOADTYPE_LW: begin
            WB_DMResult = WB_DMOut;  //LW
          end 
          `LOADTYPE_LH: begin
            if(WB_ALUOut[1] == 1'b0) //LH
              WB_DMResult = {{16{WB_DMOut[15]}},WB_DMOut[15:0]};
            else
              WB_DMResult = {{16{WB_DMOut[31]}},WB_DMOut[31:16]}; 
          end
          `LOADTYPE_LHU: begin
            if(WB_ALUOut[1] == 1'b0) //LHU
              WB_DMResult = {16'b0,WB_DMOut[15:0]};
            else
              WB_DMResult = {16'b0,WB_DMOut[31:16]};
          end
          `LOADTYPE_LB: begin
            if(WB_ALUOut[1:0] == 2'b00) //LB
              WB_DMResult = {{24{WB_DMOut[7]}},WB_DMOut[7:0]};
            else if(WB_ALUOut[1:0] == 2'b01)
              WB_DMResult = {{24{WB_DMOut[15]}},WB_DMOut[15:8]};
            else if(WB_ALUOut[1:0] == 2'b10)
              WB_DMResult = {{24{WB_DMOut[23]}},WB_DMOut[23:16]};
            else
              WB_DMResult = {{24{WB_DMOut[31]}},WB_DMOut[31:24]};
          end
          `LOADTYPE_LBU: begin
            if(WB_ALUOut[1:0] == 2'b00) //LBU
              WB_DMResult = {24'b0,WB_DMOut[7:0]};
            else if(WB_ALUOut[1:0] == 2'b01)
              WB_DMResult = {24'b0,WB_DMOut[15:8]};
            else if(WB_ALUOut[1:0] == 2'b10)
              WB_DMResult = {24'b0,WB_DMOut[23:16]};
            else
              WB_DMResult = {24'b0,WB_DMOut[31:24]};
          end
          default: begin
            WB_DMResult = 32'bx;
          end
        endcase
      end 


endmodule