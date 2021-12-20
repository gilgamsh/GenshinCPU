/*
 * @Author: npuwth
 * @Date: 2021-03-29 15:27:17
 * @LastEditTime: 2021-07-21 11:36:34
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0 
 * @IO PORT:
 * @Description:  改成了组合逻辑
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module DCacheWen(
    input  logic [1:0]        MEM_ALUOut,    // 地址信息
    input  StoreType          MEM_StoreType, // store类型
    input  logic [31:0]       MEM_OutB,      // 即将给cache的写入的数据
    //----------------------------output---------------------------------//
    output logic [3:0]        cache_wen,     //字节信号写使能
    output logic [31:0]       DataToDcache
);
    logic [3:0]               StoreByteWen;
    logic [31:0]              StoreByteData; //为了优化写法，先进行一个计算

    always_comb begin
        case(MEM_ALUOut[1:0] ) 
        2'b00:begin
            StoreByteWen      = 4'b0001;
            StoreByteData     = {24'b0 , MEM_OutB [7:0]};
        end
        2'b01:begin
            StoreByteWen      = 4'b0010;
            StoreByteData     = {16'b0 , MEM_OutB [7:0] , 8'b0};
        end
        2'b10:begin
            StoreByteWen      = 4'b0100;
            StoreByteData     = {8'b0 , MEM_OutB [7:0] , 16'b0};
        end
        2'b11:begin
            StoreByteWen      = 4'b1000;
            StoreByteData     = {MEM_OutB [7:0] , 24'b0};
        end
        default:begin   // 其实应该不会出现
            StoreByteWen      = 4'b0000; 
            StoreByteData     = 'x;
        end
        endcase
    end

    always_comb begin  : Dcahce_Wen_Generate
        unique case(MEM_StoreType.LeftOrRight)
        2'b10:begin                          //SWL
            unique case (MEM_ALUOut[1:0])
                2'b00   : begin
                  cache_wen    = 4'b0001;
                  DataToDcache = {24'b0 , MEM_OutB[31:24]};
                end
                2'b01   : begin
                  cache_wen    = 4'b0011;
                  DataToDcache = {16'b0 , MEM_OutB[31:16]};
                end
                2'b10   : begin
                  cache_wen    = 4'b0111;
                  DataToDcache = {8'b0 , MEM_OutB[31:8]};
                end
                2'b11   : begin
                  cache_wen    = 4'b1111;
                  DataToDcache = MEM_OutB[31:0];
                end
                default :begin
                  cache_wen    = 4'b0000;
                  DataToDcache = 'x;
                end
            endcase
        end
        2'b01:begin                           //SWR
            unique case (MEM_ALUOut[1:0])
                2'b00   : begin
                  cache_wen    = 4'b1111;
                  DataToDcache = MEM_OutB [31:0];
                end
                2'b01   : begin
                  cache_wen    = 4'b1110;
                  DataToDcache = {MEM_OutB[23:0] , 8'b0 };
                end
                2'b10   : begin
                  cache_wen    = 4'b1100;
                  DataToDcache = {MEM_OutB[15:0] , 16'b0};
                end
                2'b11   : begin
                  cache_wen    = 4'b1000;
                  DataToDcache = {MEM_OutB[7:0]  , 24'b0};
                end
                default :begin
                  cache_wen    = 4'b0000;
                  DataToDcache = 'x;
                end
            endcase
        end
        default:begin                         //正常访存
            unique case(MEM_StoreType.size)
                `STORETYPE_SW: begin //SW
                  cache_wen        = 4'b1111;
                  DataToDcache     = MEM_OutB [31:0];
                end
                `STORETYPE_SH: begin //SH
                  if(MEM_ALUOut[1] == 1'b0)begin
                    cache_wen      = 4'b0011;
                    DataToDcache   = {16'b0 , MEM_OutB [15:0]};
                  end
                  else begin
                    cache_wen      = 4'b1100;
                    DataToDcache   = {MEM_OutB [15:0] , 16'b0};
                  end
                end
                `STORETYPE_SB: begin //SB
                  cache_wen        = StoreByteWen;
                  DataToDcache     = StoreByteData;
                end
                default: begin
                  cache_wen      = 4'b0000;
                  DataToDcache   = 'x;
                end
            endcase
        end
        endcase
    end
endmodule