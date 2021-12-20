/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-08-14 22:57:17
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"

module TOP_IF ( 
    input logic                 clk,
    input logic                 resetn,
    input logic                 IF_Wr,
    input logic                 IF_Flush,
    input BResult               EXE_BResult,
    input logic                 MEM_Refetch,
    PREIF_IF_Interface          PIBus,
    IF_ID_Interface             IIBus,
    CPU_IBus_Interface          cpu_ibus
);  
    
    ExceptinPipeType IF_ExceptType;
    // logic            IF_Valid;
    logic            IF_Refetch;

    IF_REG U_IF_REG (
        .clk                    (clk ),
        .rst                    (resetn ),
        .IF_Wr                  (IF_Wr ),
        .IF_Flush               (IF_Flush ),
        .PREIF_PC               (PIBus.PREIF_PC ),
        .PREIF_ExceptType       (PIBus.PREIF_ExceptType ),
//-----------------------------output-------------------------------------//
        .IF_PC                  (IIBus.IF_PC ),
        .IF_ExceptType          (IF_ExceptType),
        .IF_Valid               (IIBus.IF_Valid)
    );  

    assign IIBus.IF_Instr = cpu_ibus.rdata;
    assign IF_Refetch = MEM_Refetch && IIBus.IF_Valid;
    assign IIBus.IF_ExceptType = '{
                            Interrupt:IF_ExceptType.Interrupt,
                            Break:IF_ExceptType.Break,
                            WrongAddressinIF:IF_ExceptType.WrongAddressinIF,
                            ReservedInstruction:IF_ExceptType.ReservedInstruction,
                            CoprocessorUnusable:IF_ExceptType.CoprocessorUnusable,
                            Overflow:IF_ExceptType.Overflow,
                            Syscall:IF_ExceptType.Syscall,
                            Eret:IF_ExceptType.Eret,
                            WrWrongAddressinMEM:IF_ExceptType.WrWrongAddressinMEM,
                            RdWrongAddressinMEM:IF_ExceptType.RdWrongAddressinMEM,
                            TLBRefillinIF:IF_ExceptType.TLBRefillinIF,
                            TLBInvalidinIF:IF_ExceptType.TLBInvalidinIF,
                            RdTLBRefillinMEM:IF_ExceptType.RdTLBRefillinMEM,
                            RdTLBInvalidinMEM:IF_ExceptType.RdTLBInvalidinMEM,
                            WrTLBRefillinMEM:IF_ExceptType.WrTLBRefillinMEM,
                            WrTLBInvalidinMEM:IF_ExceptType.WrTLBInvalidinMEM,
                            TLBModified:IF_ExceptType.TLBModified,
                            Trap:IF_ExceptType.Trap,
                            Refetch:(IF_ExceptType.Refetch || IF_Refetch)
        };

    BPU U_BPU (
        .clk                        (clk ),
        .rst                        (resetn ),
        .IF_Wr                      (IF_Wr ),
        .IF_Flush                   (IF_Flush ),
        .PREIF_PC                   (PIBus.PREIF_PC ),
        .EXE_BResult                (EXE_BResult ),
        .ID_IsBranch                (IIBus.ID_IsBranch),
        //--------------------output-----------------------------------//
        .Target                     (PIBus.IF_Target ),
        .IF_PResult                 (IIBus.IF_PResult ),
        .BPU_Valid                  (PIBus.IF_BPUValid)
    );

endmodule