/*
 * @Author: npuwth
 * @Date: 2021-03-29 14:36:47
 * @LastEditTime: 2021-07-27 15:50:59
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module EXT2 (
    input logic  [31:0]    WB_DMOut,   // WB_DMOut
    input logic  [31:0]    WB_ALUOut,  // WB_ALUOut
    input LoadType         WB_LoadType,
    input logic  [31:0]    reg_rt,     // rt_reg
    output logic [31:0]    WB_CacheRdData // resu;t after processing
    
); 
    logic [31:0] WB_DMResult;

    always_comb begin : LoadNotAlign_Data
        unique case (WB_LoadType.LeftOrRight)
        2'b10:begin  // LWL
            unique case (WB_ALUOut[1:0])
                2'b00 : WB_CacheRdData = {WB_DMOut[7:0]  , reg_rt[23:0]};
                2'b01 : WB_CacheRdData = {WB_DMOut[15:0] , reg_rt[15:0]};
                2'b10 : WB_CacheRdData = {WB_DMOut[23:0] , reg_rt[7:0] };
                2'b11 : WB_CacheRdData = {WB_DMOut[31:0] };
                default : WB_CacheRdData = 'x;
            endcase
        end
        2'b01:begin  // LWR
            unique case (WB_ALUOut[1:0])
                2'b00 : WB_CacheRdData = {WB_DMOut[31:0]};
                2'b01 : WB_CacheRdData = {reg_rt[31:24] , WB_DMOut[31:8] };
                2'b10 : WB_CacheRdData = {reg_rt[31:16] , WB_DMOut[31:16]};
                2'b11 : WB_CacheRdData = {reg_rt[31:8]  , WB_DMOut[31:24]};
                default : WB_CacheRdData = 'x;
            endcase
        end
        2'b00:begin
            WB_CacheRdData = WB_DMResult;
        end
        default :  WB_CacheRdData = '0;
        endcase
    end

    always_comb begin
        unique case({WB_LoadType.sign,WB_LoadType.size})
        `LOADTYPE_LW: begin
            WB_DMResult = WB_DMOut;  //LW
        end 
        `LOADTYPE_LH: begin
            WB_DMResult = (WB_ALUOut[1])?{{16{WB_DMOut[31]}},WB_DMOut[31:16]}:{{16{WB_DMOut[15]}},WB_DMOut[15:0]};
        end
        `LOADTYPE_LHU: begin
            WB_DMResult = (WB_ALUOut[1])?{16'b0,WB_DMOut[31:16]}:{16'b0,WB_DMOut[15:0]};
        end
        `LOADTYPE_LB: begin
            unique case(WB_ALUOut[1:0])
            2'b00  :WB_DMResult = {{24{WB_DMOut[7]}},WB_DMOut[7:0]};
            2'b01  :WB_DMResult = {{24{WB_DMOut[15]}},WB_DMOut[15:8]};
            2'b10  :WB_DMResult = {{24{WB_DMOut[23]}},WB_DMOut[23:16]};
            default:WB_DMResult = {{24{WB_DMOut[31]}},WB_DMOut[31:24]};
            endcase
        end
        `LOADTYPE_LBU: begin
            unique case(WB_ALUOut[1:0])
            2'b00  :WB_DMResult = {24'b0,WB_DMOut[7:0]};
            2'b01  :WB_DMResult = {24'b0,WB_DMOut[15:8]};
            2'b10  :WB_DMResult = {24'b0,WB_DMOut[23:16]};
            default:WB_DMResult = {24'b0,WB_DMOut[31:24]};
            endcase
        end
        default:WB_DMResult = 32'bx; 
        endcase
      end



endmodule