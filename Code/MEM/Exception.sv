 /*
 * @Author: Johnson Yang
 * @Date: 2021-03-31 15:22:23
 * @LastEditTime: 2021-07-02 15:51:30
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"  
`include "../CPU_Defines.svh"

 module Exception(
    input                      clk,
    input                      rst,
    input RegsWrType           MEM_RegsWrType,  
    input ExceptinPipeType     MEM_ExceptType,        //译码执行阶段收集到的异常信息
    input logic [31:0]         MEM_PC,                //用于判断取指令地址错例外
    input logic [31:0]         CP0_Status,            //CP0 status寄存器
    input logic [31:0]         CP0_Cause,             //CP0 cause寄存器
    output RegsWrType          MEM_RegsWrType_final,  //要向下一级传递的RegsWrType
    output logic               ID_Flush,              //Flush信号
    output logic               EXE_Flush,
    output logic               MEM_Flush,
    output logic [1:0]         IsExceptionOrEret,     //用于生成NPC
    output ExceptinPipeType    MEM_ExceptType_final   //最终的异常类型
 );

always_comb begin
    if (MEM_ExceptType_final != `ExceptionTypeZero )begin
        if (MEM_ExceptType.Refetch == 1'b1) begin
            IsExceptionOrEret  = `IsRefetch;
        end
        else if (MEM_ExceptType.Eret == 1'b1) begin
            IsExceptionOrEret  = `IsEret;
        end
        else begin
            IsExceptionOrEret  = `IsException;
        end
        ID_Flush               = `FlushEnable;
        EXE_Flush              = `FlushEnable;
        MEM_Flush              = `FlushEnable;
        MEM_RegsWrType_final   = `RegsWrTypeDisable;
    end 
    else begin
        IsExceptionOrEret      = `IsNone;
        ID_Flush               = `FlushDisable;
        EXE_Flush              = `FlushDisable;
        MEM_Flush              = `FlushDisable;
        MEM_RegsWrType_final   = MEM_RegsWrType;                
    end
end

assign MEM_ExceptType_final.Interrupt           = (((CP0_Cause[15:8] & CP0_Status[15:8]) != 8'b0) && (CP0_Status[1] == 1'b0) && (CP0_Status[0] == 1'b1)) ?1'b1:1'b0;
assign MEM_ExceptType_final.WrongAddressinIF    = (MEM_PC[1:0] != 2'b00 )?1'b1:1'b0;
assign MEM_ExceptType_final.ReservedInstruction = MEM_ExceptType.ReservedInstruction;
assign MEM_ExceptType_final.Syscall             = MEM_ExceptType.Syscall;
assign MEM_ExceptType_final.Break               = MEM_ExceptType.Break;
assign MEM_ExceptType_final.Eret                = MEM_ExceptType.Eret;
assign MEM_ExceptType_final.WrWrongAddressinMEM = MEM_ExceptType.WrWrongAddressinMEM;
assign MEM_ExceptType_final.RdWrongAddressinMEM = MEM_ExceptType.RdWrongAddressinMEM;
assign MEM_ExceptType_final.Overflow            = MEM_ExceptType.Overflow;
assign MEM_ExceptType_final.TLBRefill           = MEM_ExceptType.TLBRefill;
assign MEM_ExceptType_final.TLBInvalid          = MEM_ExceptType.TLBInvalid;
assign MEM_ExceptType_final.TLBModified         = MEM_ExceptType.TLBModified;
assign MEM_ExceptType_final.Refetch             = MEM_ExceptType.Refetch;
assign MEM_ExceptType_final.Trap                = MEM_ExceptType.Trap;
endmodule

