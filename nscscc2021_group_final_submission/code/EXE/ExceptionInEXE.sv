`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module ExceptionInEXE(
    input  logic              Overflow_valid,
    input  logic              Trap_valid,
    input  ExceptinPipeType   EXE_ExceptType,
    // 用于产生TLB refetch & 取指令地址错例外
    input  LoadType           EXE_LoadType,
    // input  logic              MEM_IsTLBR,
    // input  logic              MEM_IsTLBW,
    // input  logic              MEM_RegsWrTypeCP0Wr,
    // input  logic [4:0]        MEM_Dst,
    input  logic [1:0]        EXE_ALUOut,    // 地址信息
    input  logic [31:0]       EXE_PC,
    input  StoreType          EXE_StoreType,
    // input  CacheType          MEM_CacheType,
    input  logic              EXE_Refetch,
//-------------------------output----------------------------------//
    output ExceptinPipeType   EXE_ExceptType_final
);

    logic  LoadAlign_valid;
    logic  StoreAlign_valid;
    assign LoadAlign_valid    = (EXE_LoadType.ReadMem && EXE_LoadType.LeftOrRight != 2'b01  &&  EXE_LoadType.LeftOrRight != 2'b10) ? 1'b1 : 1'b0;
    assign StoreAlign_valid   = (EXE_StoreType.DMWr && EXE_StoreType.LeftOrRight != 2'b01 && EXE_StoreType.LeftOrRight != 2'b10) ? 1'b1 : 1'b0;

// EXE级一共产生5种例外，溢出，trap ，TLBrefetch ， 数据访问地址错误
    assign EXE_ExceptType_final.Interrupt           =  EXE_ExceptType.Interrupt;
    assign EXE_ExceptType_final.WrongAddressinIF    =  (EXE_PC[1:0] != 2'b00 )?1'b1:1'b0;
    assign EXE_ExceptType_final.ReservedInstruction =  EXE_ExceptType.ReservedInstruction;
    assign EXE_ExceptType_final.CoprocessorUnusable =  EXE_ExceptType.CoprocessorUnusable;
    assign EXE_ExceptType_final.Syscall             =  EXE_ExceptType.Syscall;
    assign EXE_ExceptType_final.Break               =  EXE_ExceptType.Break;
    assign EXE_ExceptType_final.Eret                =  EXE_ExceptType.Eret;
                                                    // 非对其访存时不考虑load store地址错例外     
    assign EXE_ExceptType_final.WrWrongAddressinMEM =  StoreAlign_valid  &&
                                                       (((EXE_StoreType.size == `STORETYPE_SW)&&(EXE_ALUOut[1:0] != 2'b00))||((EXE_StoreType.size == `STORETYPE_SH)&&(EXE_ALUOut[0] != 1'b0)));
                                                    // 非对其访存时不考虑load store地址错例外 
    assign EXE_ExceptType_final.RdWrongAddressinMEM =  LoadAlign_valid   && 
                                                       (((EXE_LoadType.size == 2'b00)&&(EXE_ALUOut[1:0] != 2'b00))||((EXE_LoadType.size == 2'b01)&&(EXE_ALUOut[0] != 1'b0)));
    assign EXE_ExceptType_final.Overflow            =  Overflow_valid;
    assign EXE_ExceptType_final.TLBRefillinIF       =  EXE_ExceptType.TLBRefillinIF;
    assign EXE_ExceptType_final.TLBInvalidinIF      =  EXE_ExceptType.TLBInvalidinIF;
    assign EXE_ExceptType_final.RdTLBRefillinMEM    =  EXE_ExceptType.RdTLBRefillinMEM;
    assign EXE_ExceptType_final.RdTLBInvalidinMEM   =  EXE_ExceptType.RdTLBInvalidinMEM;
    assign EXE_ExceptType_final.WrTLBRefillinMEM    =  EXE_ExceptType.WrTLBRefillinMEM; 
    assign EXE_ExceptType_final.WrTLBInvalidinMEM   =  EXE_ExceptType.WrTLBInvalidinMEM;   
    assign EXE_ExceptType_final.TLBModified         =  EXE_ExceptType.TLBModified;
    assign EXE_ExceptType_final.Trap                =  Trap_valid;
    assign EXE_ExceptType_final.Refetch             =  (EXE_ExceptType.Refetch || EXE_Refetch);//TODO:这种用全零判断空泡的方法不好，最好用valid位判断
endmodule