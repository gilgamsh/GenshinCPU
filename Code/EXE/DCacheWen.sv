/*
 * @Author: npuwth
 * @Date: 2021-03-29 15:27:17
 * @LastEditTime: 2021-07-04 12:00:18
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0 
 * @IO PORT:
 * @Description: 改成了组合逻辑
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module DCacheWen(
  input logic [31:0]       EXE_ALUOut,
  input StoreType          EXE_StoreType,
  input LoadType           EXE_LoadType,
  input ExceptinPipeType   EXE_ExceptType,
  
  output ExceptinPipeType  EXE_ExceptType_new,  
  output logic [3:0]       cache_wen        //字节信号写使能
);


  always_comb begin
      
    if(EXE_StoreType.DMWr) begin
      unique case(EXE_StoreType.size)
        `STORETYPE_SW: begin //SW
          cache_wen = 4'b1111;
        end
        `STORETYPE_SH: begin //SH
          if(EXE_ALUOut[1] == 1'b0)begin
            cache_wen = 4'b0011;
          end
          else begin
            cache_wen = 4'b1100;
          end
        end
        `STORETYPE_SB: begin //SB
          if(EXE_ALUOut[1:0] == 2'b00) begin
            cache_wen = 4'b0001;
          end
          else if(EXE_ALUOut[1:0] == 2'b01) begin
            cache_wen = 4'b0010;
          end
          else if(EXE_ALUOut[1:0] == 2'b10) begin
            cache_wen = 4'b0100;
          end
          else if(EXE_ALUOut[1:0] == 2'b11) begin
            cache_wen = 4'b1000;
          end
          else begin   // 其实应该不会出现
            cache_wen = 4'b0000; 
          end
        end
        default: begin
            cache_wen = 4'b0000;
        end
        
      endcase
    end else begin
      cache_wen = 4'b0000;
    end
      
  end

  assign EXE_ExceptType_new.Interrupt           = EXE_ExceptType.Interrupt;
  assign EXE_ExceptType_new.WrongAddressinIF    = EXE_ExceptType.WrongAddressinIF;
  assign EXE_ExceptType_new.ReservedInstruction = EXE_ExceptType.ReservedInstruction;
  assign EXE_ExceptType_new.Syscall             = EXE_ExceptType.Syscall;
  assign EXE_ExceptType_new.Break               = EXE_ExceptType.Break;
  assign EXE_ExceptType_new.Eret                = EXE_ExceptType.Eret;
  assign EXE_ExceptType_new.WrWrongAddressinMEM = EXE_StoreType.DMWr&&(((EXE_StoreType.size == `STORETYPE_SW)&&(EXE_ALUOut[1:0] != 2'b00))||((EXE_StoreType.size == `STORETYPE_SH)&&(EXE_ALUOut[0] != 1'b0)));
  assign EXE_ExceptType_new.RdWrongAddressinMEM = EXE_LoadType.ReadMem&&(((EXE_LoadType.size == 2'b00)&&(EXE_ALUOut[1:0] != 2'b00))||((EXE_LoadType.size == 2'b01)&&(EXE_ALUOut[0] != 1'b0)));
  assign EXE_ExceptType_new.Overflow            = EXE_ExceptType.Overflow;
  assign EXE_ExceptType_new.TLBRefill           = EXE_ExceptType.TLBRefill;
  assign EXE_ExceptType_new.TLBInvalid          = EXE_ExceptType.TLBInvalid;
  assign EXE_ExceptType_new.TLBModified         = EXE_ExceptType.TLBModified;
  assign EXE_ExceptType_new.Refetch             = EXE_ExceptType.Refetch;
  assign EXE_ExceptType_new.Trap                = EXE_ExceptType.Trap;

endmodule