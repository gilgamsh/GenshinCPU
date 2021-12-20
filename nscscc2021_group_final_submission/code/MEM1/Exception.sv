 /*
 * @Author: Johnson Yang
 * @Date: 2021-03-31 15:22:23
 * @LastEditTime: 2021-08-13 16:35:09
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"  
`include "../CPU_Defines.svh"

 module Exception(
    input ExceptinPipeType     MEM_ExceptType,        //译码执行阶段收集到的异常信息
    input logic [2:0]          MEM_TLBExceptType,
    input logic                MEM_Interrupt,
    // input logic [31:0]         MEM_PC,                //用于判断取指令地址错例外
    input logic [22:22]        CP0_Status_BEV,
    // input logic [7:0]          CP0_Status_IM7_0,
    input logic                CP0_Status_EXL,
    // input logic                CP0_Status_IE,
    // input logic [7:2]          CP0_Cause_IP7_2,
    // input logic [1:0]          CP0_Cause_IP1_0,
    input logic [31:0]         CP0_Ebase,
    // input logic                MEM_IsInDelaySlot,
    //-------------------------------------output--------------------------//
    output logic [4:0]         MEM_ExcType,
    output logic [1:0]         EX_Entry_Sel,           //用于生成NPC
    output logic [31:0]        Exception_Vector,       // 异常处理的入口地址
    output logic               Flush_Exception
 );
    logic  [31:0]              base;
    logic  [31:0]              offset;
    ExceptinPipeType           MEM_ExceptType_final;

    always_comb begin  //优先级可以查看MIPS文档第三册56页
        if     (MEM_ExceptType_final.Refetch             == 1'b1)    MEM_ExcType = `EX_Refetch;           //Refetch的优先级在这比较合适
        else if(MEM_ExceptType_final.Interrupt           == 1'b1)    MEM_ExcType = `EX_Interrupt;
        else if(MEM_ExceptType_final.WrongAddressinIF    == 1'b1)    MEM_ExcType = `EX_WrongAddressinIF;
        else if(MEM_ExceptType_final.TLBRefillinIF       == 1'b1)    MEM_ExcType = `EX_TLBRefillinIF;
        else if(MEM_ExceptType_final.TLBInvalidinIF      == 1'b1)    MEM_ExcType = `EX_TLBInvalidinIF;
        else if(MEM_ExceptType_final.CoprocessorUnusable == 1'b1)    MEM_ExcType = `EX_CpU;
        else if(MEM_ExceptType_final.ReservedInstruction == 1'b1)    MEM_ExcType = `EX_ReservedInstruction;
        else if(MEM_ExceptType_final.Syscall             == 1'b1)    MEM_ExcType = `EX_Syscall;
        else if(MEM_ExceptType_final.Break               == 1'b1)    MEM_ExcType = `EX_Break;
        else if(MEM_ExceptType_final.Eret                == 1'b1)    MEM_ExcType = `EX_Eret;
        else if(MEM_ExceptType_final.Trap                == 1'b1)    MEM_ExcType = `EX_Trap;
        else if(MEM_ExceptType_final.Overflow            == 1'b1)    MEM_ExcType = `EX_Overflow;
        else if(MEM_ExceptType_final.WrWrongAddressinMEM == 1'b1)    MEM_ExcType = `EX_WrWrongAddressinMEM;
        else if(MEM_ExceptType_final.RdWrongAddressinMEM == 1'b1)    MEM_ExcType = `EX_RdWrongAddressinMEM;
        else if(MEM_ExceptType_final.RdTLBRefillinMEM    == 1'b1)    MEM_ExcType = `EX_RdTLBRefillinMEM;
        else if(MEM_ExceptType_final.WrTLBRefillinMEM    == 1'b1)    MEM_ExcType = `EX_WrTLBRefillinMEM;
        else if(MEM_ExceptType_final.RdTLBInvalidinMEM   == 1'b1)    MEM_ExcType = `EX_RdTLBInvalidinMEM;  
        else if(MEM_ExceptType_final.WrTLBInvalidinMEM   == 1'b1)    MEM_ExcType = `EX_WrTLBInvalidinMEM;
        else if(MEM_ExceptType_final.TLBModified         == 1'b1)    MEM_ExcType = `EX_TLBModified;
        else                                                         MEM_ExcType = `EX_None;              
    end

    assign Flush_Exception = (MEM_ExceptType_final != '0);

    always_comb begin
        case(MEM_ExcType)
            `EX_Refetch:  EX_Entry_Sel = `IsRefetch;
            `EX_Eret:     EX_Entry_Sel = `IsEret;
            `EX_None:     EX_Entry_Sel = `IsNone;
            default:      EX_Entry_Sel = `IsException;
        endcase
    end
    
    // 产生异常处理的新入口 -- offest
    always_comb begin
        case(MEM_ExcType)
            `EX_TLBRefillinIF,`EX_RdTLBRefillinMEM,`EX_WrTLBRefillinMEM:begin
                if (CP0_Status_EXL == 1'b1) begin
                    offset = 32'h180;
                end 
                else if (CP0_Status_EXL == 1'b0) begin
                    offset = 32'h0;
                end 
            end
            default:begin
                offset = 32'h180;
            end
        endcase
    end

// 产生异常处理的新入口 -- base
always_comb begin : PC_Exception_Ebase_Generate
    if (CP0_Status_BEV == 1'b1) begin
        base = 32'hbfc00200;
    end 
    else begin
        base = CP0_Ebase;
    end
end
assign Exception_Vector  = base + offset; //生成异常入口向量

//-----------------------------------------------生成MEM级的最终异常----------------------------------------------------------//
assign MEM_ExceptType_final.Interrupt           = MEM_Interrupt;
assign MEM_ExceptType_final.WrongAddressinIF    = MEM_ExceptType.WrongAddressinIF;
assign MEM_ExceptType_final.ReservedInstruction = MEM_ExceptType.ReservedInstruction;
assign MEM_ExceptType_final.CoprocessorUnusable = MEM_ExceptType.CoprocessorUnusable;
assign MEM_ExceptType_final.Syscall             = MEM_ExceptType.Syscall;
assign MEM_ExceptType_final.Break               = MEM_ExceptType.Break;
assign MEM_ExceptType_final.Eret                = MEM_ExceptType.Eret;
assign MEM_ExceptType_final.WrWrongAddressinMEM = MEM_ExceptType.WrWrongAddressinMEM;
assign MEM_ExceptType_final.RdWrongAddressinMEM = MEM_ExceptType.RdWrongAddressinMEM;
assign MEM_ExceptType_final.Overflow            = MEM_ExceptType.Overflow;
assign MEM_ExceptType_final.TLBRefillinIF       = MEM_ExceptType.TLBRefillinIF;
assign MEM_ExceptType_final.TLBInvalidinIF      = MEM_ExceptType.TLBInvalidinIF;
assign MEM_ExceptType_final.RdTLBRefillinMEM    = (MEM_TLBExceptType == `MEM_RdTLBRefill);
assign MEM_ExceptType_final.RdTLBInvalidinMEM   = (MEM_TLBExceptType == `MEM_RdTLBInvalid);
assign MEM_ExceptType_final.WrTLBRefillinMEM    = (MEM_TLBExceptType == `MEM_WrTLBRefill);
assign MEM_ExceptType_final.WrTLBInvalidinMEM   = (MEM_TLBExceptType == `MEM_WrTLBInvalid);  
assign MEM_ExceptType_final.TLBModified         = (MEM_TLBExceptType == `MEM_TLBModified);
assign MEM_ExceptType_final.Trap                = MEM_ExceptType.Trap;
assign MEM_ExceptType_final.Refetch             = MEM_ExceptType.Refetch;

endmodule

