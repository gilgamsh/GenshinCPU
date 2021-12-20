/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-08-15 23:11:52
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */ 

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"
`include "../Cache_options.svh"

module TOP_MEM (
    input logic                  clk,
    input logic                  resetn,
    input logic                  MEM_Flush,
    input logic                  MEM_Wr,

    input logic  [5:0]           Interrupt,//中断
    input logic                  MEM_DisWr,
    input TLB_Entry              D_TLBEntry,
    input logic                  s1_found,
    input logic                  DReq_valid,
    
    EXE_MEM_Interface            EMBus,
    MEM_MEM2_Interface           MM2Bus,
    CP0_TLB_Interface            CTBus,
    CPU_DBus_Interface           cpu_dbus,
    AXI_DBus_Interface           axi_dbus,
    AXI_UNCACHE_Interface        axi_ubus,
    output logic                 Flush_Exception,
    output logic [1:0]           EX_Entry_Sel,
    output logic                 MEM_IsTLBP,
    output logic                 MEM_IsTLBW,
    output logic                 MEM_TLBWIorR,
    output logic [31:0]          MEM_PC,
    output logic [31:0]          CP0_EPC,
    output LoadType              MEM_LoadType,
    output StoreType             MEM_StoreType,
    output logic [31:0]          Exception_Vector,
    output logic [31:13]         D_VPN2,
    output logic                 D_IsTLBStall,
    output logic                 TLBBuffer_Flush_Final,
    output logic [31:0]          MEM_Result,  // 用于旁路数据
    output logic [4:0]           MEM_Dst,
    output RegsWrType            MEM_RegsWrType,
    output logic                 MEM_IsMFC0,
    output logic [2:0]           CP0_Config_K0,
    output CacheType             MEM_CacheType,
    output logic [31:0]          MEM_ALUOut,
    output logic                 MEM_Refetch
);
    ExceptinPipeType             MEM_ExceptType;
    logic [31:0]                 RFHILO_Bus;
    logic [1:0]                  MEM_RegsReadSel;
    logic [4:0]                  MEM_rd;               //用于读CP0
    logic [31:0]                 CP0_Bus;
    RegsWrType                   MEM_Final_Wr;
    StoreType                    MEM_Final_StoreType;
    logic                        MEM_IsTLBR;
    //传给Exception
    logic                        CP0_Status_BEV;
    logic [7:0]                  CP0_Status_IM7_0;
    logic                        CP0_Status_EXL;
    logic                        CP0_Status_IE;
    logic [7:2]                  CP0_Cause_IP7_2;
    logic [1:0]                  CP0_Cause_IP1_0;
    logic [31:0]                 CP0_Ebase;
    //用于TLB
    logic [2:0]                  MEM_TLBExceptType;
    logic [31:12]                Phsy_Daddr;
    logic                        D_IsCached;
    logic                        D_IsTLBBufferValid;
    logic                        TLBBuffer_Flush;
    //用于Dcache
    logic [3:0]                  MEM_DCache_Wen;
    logic [31:0]                 MEM_DataToDcache;
    logic                        MEM_Interrupt;
    logic                        TLB_Refetch;
    logic                        ICache_Refetch;
    // TLB_Buffer                   DTLBBuffer;

    //表示当前指令是否在延迟槽中，通过判断上一条指令是否是branch或jump实现
    assign MM2Bus.MEM_IsInDelaySlot = MM2Bus.MEM2_IsABranch; 
    assign MEM_Interrupt = (~MM2Bus.MEM_IsInDelaySlot) && (MM2Bus.MEM_PC != 32'b0) && (({CP0_Cause_IP7_2,CP0_Cause_IP1_0} & CP0_Status_IM7_0) != 8'b0) &&
                           (CP0_Status_EXL == 1'b0) && (CP0_Status_IE == 1'b1);

    //用于重取机制
    assign TLB_Refetch = (MEM_IsTLBR == 1'b1 || MEM_IsTLBW == 1'b1 || (MEM_RegsWrType.CP0Wr && MM2Bus.MEM_Dst == `CP0_REG_ENTRYHI));
    assign ICache_Refetch = MEM_CacheType.isIcache;
    assign MEM_Refetch = TLB_Refetch || ICache_Refetch;
    // assign MEM_Refetch = '0;
    assign MEM_PC                   = MM2Bus.MEM_PC;                // MEM_PC要输出用于重取机制
    assign TLBBuffer_Flush          = (MEM_IsTLBR == 1'b1 || MEM_IsTLBW == 1'b1 || (MEM_RegsWrType.CP0Wr && MM2Bus.MEM_Dst == `CP0_REG_ENTRYHI));
    
    assign MEM_Final_Wr             = (MEM_DisWr)? '0: MEM_RegsWrType; //当发生阻塞时，要关掉CP0写使能，防止提前写入软件中断
    assign MM2Bus.MEM_RegsWrType    = MEM_Final_Wr;
    //往后传的是DisWr选择后的Store信号
    assign MEM_Final_StoreType      = (MEM_DisWr)? '0 : MEM_StoreType;
    assign MM2Bus.MEM_LoadType      = (MEM_DisWr)? '0 : MEM_LoadType;
    assign TLBBuffer_Flush_Final    = (MEM_DisWr)? '0 : TLBBuffer_Flush;//当一条TLBW发生在MEM级时发生恰好阻塞，他就流不走，就会出现反复清空TLBBuffer，然后就会反复TLBStall
    // 用于旁路
    assign MEM_Dst                  = MM2Bus.MEM_Dst;
    // 用于MFC0型的阻塞
    // assign MEM_Instr                = MM2Bus.MEM_Instr;
    assign MEM_ALUOut               = MM2Bus.MEM_ALUOut;
    MEM_Reg U_MEM_Reg ( 
        .clk                     (clk ),
        .rst                     (resetn ),
        .MEM_Flush               (MEM_Flush ),
        .MEM_Wr                  (MEM_Wr ),

        .EXE_ALUOut              (EMBus.EXE_ALUOut ),
        .EXE_OutB                (EMBus.EXE_OutB ),
        .EXE_PC                  (EMBus.EXE_PC ),
        .EXE_Instr               (EMBus.EXE_Instr ),
        .EXE_BranchType          (EMBus.EXE_BranchType ),
        .EXE_LoadType            (EMBus.EXE_LoadType ),
        .EXE_StoreType           (EMBus.EXE_StoreType ),
        .EXE_Dst                 (EMBus.EXE_Dst ),
        .EXE_RegsWrType          (EMBus.EXE_RegsWrType ),
        .EXE_WbSel               (EMBus.EXE_WbSel ),
        .EXE_ExceptType_final    (EMBus.EXE_ExceptType_final ),
        .EXE_IsTLBP              (EMBus.EXE_IsTLBP),
        .EXE_IsTLBW              (EMBus.EXE_IsTLBW),
        .EXE_IsTLBR              (EMBus.EXE_IsTLBR),
        .EXE_TLBWIorR            (EMBus.EXE_TLBWIorR),
        .EXE_RegsReadSel         (EMBus.EXE_RegsReadSel),
        .EXE_rd                  (EMBus.EXE_rd),
        .EXE_Result              (EMBus.EXE_Result),
        .EXE_IsMFC0              (EMBus.EXE_IsMFC0),
        .EXE_CacheType           (EMBus.EXE_CacheType),
    //------------------------out--------------------------------------------------//
        .MEM_ALUOut              (MM2Bus.MEM_ALUOut ),  
        .MEM_OutB                (RFHILO_Bus ),
        .MEM_PC                  (MM2Bus.MEM_PC ),
        .MEM_Instr               (MM2Bus.MEM_Instr ),
        .MEM_IsABranch           (MM2Bus.MEM_IsABranch ),
        .MEM_LoadType            (MEM_LoadType ),
        .MEM_StoreType           (MEM_StoreType),
        .MEM_Dst                 (MM2Bus.MEM_Dst ),
        .MEM_RegsWrType          (MEM_RegsWrType ),//未经过Exception的
        .MEM_WbSel               (MM2Bus.MEM_WbSel ),
        .MEM_ExceptType          (MEM_ExceptType ),
        .MEM_IsTLBP              (MEM_IsTLBP),
        .MEM_IsTLBW              (MEM_IsTLBW),
        .MEM_IsTLBR              (MEM_IsTLBR),
        .MEM_TLBWIorR            (MEM_TLBWIorR),
        .MEM_RegsReadSel         (MEM_RegsReadSel),
        .MEM_rd                  (MEM_rd),
        .MEM_Result              (MEM_Result),
        .MEM_IsMFC0              (MEM_IsMFC0),
        .MEM_CacheType           (MEM_CacheType)
    );

    Exception U_Exception(             
        .MEM_ExceptType          (MEM_ExceptType),        
        .MEM_TLBExceptType       (MEM_TLBExceptType),
        .MEM_Interrupt           (MEM_Interrupt),
        // .MEM_PC                  (MM2Bus.MEM_PC),   
        .CP0_Status_BEV          (CP0_Status_BEV),                  
        // .CP0_Status_IM7_0        (CP0_Status_IM7_0 ),
        .CP0_Status_EXL          (CP0_Status_EXL ),
        // .CP0_Status_IE           (CP0_Status_IE ),
        // .CP0_Cause_IP7_2         (CP0_Cause_IP7_2 ),
        // .CP0_Cause_IP1_0         (CP0_Cause_IP1_0), 
        .CP0_Ebase               (CP0_Ebase),     
        // .MEM_IsInDelaySlot       (MM2Bus.MEM_IsInDelaySlot),
    //------------------------------out--------------------------------------------//         
        .Flush_Exception         (Flush_Exception),                         
        .EX_Entry_Sel            (EX_Entry_Sel),            
        .MEM_ExcType             (MM2Bus.MEM_ExcType),
        .Exception_Vector        (Exception_Vector)                          
    );

    cp0_reg U_CP0 (
        .clk                    (clk ),
        .rst                    (resetn ),
        .Interrupt              (Interrupt ),
        .CP0_Sel                (MM2Bus.MEM_Instr[2:0]),
        .CP0_RdAddr             (MEM_rd ),
        .CP0_RdData             (CP0_Bus ),
        .MEM_RegsWrType         (MEM_Final_Wr ),
        .MEM_Dst                (MM2Bus.MEM_Dst ),
        .MEM_Result             (MEM_Result ),
        .MEM_IsTLBP             (MEM_IsTLBP ),
        .MEM_IsTLBR             (MEM_IsTLBR ),
        .CTBus                  (CTBus.CP0 ),
        .MEM2_ExcType           (MM2Bus.MEM2_ExcType ),
        .MEM2_PC                (MM2Bus.MEM2_PC ),
        .MEM2_IsInDelaySlot     (MM2Bus.MEM2_IsInDelaySlot ),
        .MEM2_ALUOut            (MM2Bus.MEM2_ALUOut ),
        //---------------output----------------//
        .CP0_Status_BEV         (CP0_Status_BEV),
        .CP0_Status_IM7_0       (CP0_Status_IM7_0 ),
        .CP0_Status_EXL         (CP0_Status_EXL ),
        .CP0_Status_IE          (CP0_Status_IE ),
        .CP0_Cause_IP7_2        (CP0_Cause_IP7_2 ),
        .CP0_Cause_IP1_0        (CP0_Cause_IP1_0 ),
        .CP0_Ebase              (CP0_Ebase ),
        .CP0_EPC                (CP0_EPC ),
        .CP0_Config_K0          (CP0_Config_K0 )
    );

    //-----------------------------用于准备写往dcache的数据-----------------------//
    DCacheWen U_DCACHEWEN(
        .MEM_ALUOut           (MM2Bus.MEM_ALUOut[1:0]),
        .MEM_StoreType        (MEM_StoreType),
        .MEM_OutB             (RFHILO_Bus),
        //-----------------output-------------------------//
        .cache_wen            (MEM_DCache_Wen),      //给出dcache的写使能信号，
        .DataToDcache         (MEM_DataToDcache)           //给出dcache的写数据信号，
    );
    //------------------------------用于旁路的多选器-------------------------------//
    // MUX4to1 U_MUXINMEM ( //选择用于旁路的数据来自ALUOut还是OutB
    //     .d0                      (MM2Bus.MEM_PC + 8),
    //     .d1                      (MM2Bus.MEM_ALUOut),
    //     .d2                      (RFHILO_Bus       ), //这里使用的应该都是从寄存器出来的，而不是读取CP0后的MM2Bus.MEM_OutB,已经在dataHazard中对这种情况进行了阻塞
    //     .d3                      ('x               ),
    //     .sel4_to_1               (MM2Bus.MEM_WbSel ),
    //     .y                       (MEM_Result       )
    // );
    //---------------------------------------------------------------------------//
//-------------------------------------------TO Cache-------------------------------//
    assign cpu_dbus.wdata                                 = MEM_DataToDcache;
    assign cpu_dbus.tag                                   = Phsy_Daddr[31:12];
    assign {cpu_dbus.index,cpu_dbus.offset}               = MM2Bus.MEM_ALUOut[11:0];                 // inst_sram_addr_o 虚拟地址
    assign cpu_dbus.op                                    = (MEM_LoadType.ReadMem)? 1'b0 :
                                                            (MEM_StoreType.DMWr) ? 1'b1  :
                                                             1'bx;//TODO:不要有x
    assign cpu_dbus.wstrb                                 = MEM_DCache_Wen;
    assign cpu_dbus.loadType                              = MEM_LoadType;
    assign cpu_dbus.isCache                               = D_IsCached;
    // assign cpu_dbus.valid                                 = DReq_valid && D_IsTLBBufferValid && (MM2Bus.MEM_ExcType == `EX_None);
    assign cpu_dbus.valid                                 = DReq_valid && D_IsTLBBufferValid && (MEM_ExceptType == '0) && (~MEM_Interrupt);
    assign cpu_dbus.origin_valid                          = DReq_valid && (MEM_LoadType.ReadMem || MEM_StoreType.DMWr);
    assign cpu_dbus.cacheType                             = MEM_CacheType;

`ifdef DEBUG  // compatible for verialtor
    assign MM2Bus.MEM_DCache_Wen                          = (cpu_dbus.valid && MEM_StoreType.DMWr)? MEM_DCache_Wen:'0;
    assign MM2Bus.MEM_DataToDcache                        = MEM_DataToDcache;

    Dcache #(
        .DATA_WIDTH              (32 ),
        .LINE_WORD_NUM           (`DCACHE_LINE_WORD ),
        .ASSOC_NUM               (`DCACHE_SET_ASSOC ),
        .WAY_SIZE                (4*1024*8 )
    )
    U_Dcache (
        .clk                     (clk ),
        .resetn                  (resetn ),
        .axi_ubus                (axi_ubus ),
        .cpu_bus                 (cpu_dbus ),
        .axi_bus                 ( axi_dbus)
    );
`else  // for vivado 
    Dcache #(
        .DATA_WIDTH              (32 ),
        .LINE_WORD_NUM           (`DCACHE_LINE_WORD ),
        .ASSOC_NUM               (`DCACHE_SET_ASSOC ),
        .WAY_SIZE                (4*1024*8 )
    )
    U_Dcache (
        .clk                     (clk ),
        .resetn                  (resetn ),
        .axi_ubus                (axi_ubus.master ),
        .cpu_bus                 (cpu_dbus.slave ),
        .axi_bus                 ( axi_dbus.master)
    );
`endif
    MUX2to1 #(32) U_MUX_OutB2 ( //TODO:这里可以优化一下，换成2选1
        .d0                      (RFHILO_Bus),
        .d1                      (CP0_Bus),
        .sel2_to_1               (MEM_RegsReadSel == 2'b11),
        .y                       (MM2Bus.MEM_OutB)
    );

    DTLB U_DTLB (
        .clk                     (clk ),
        .rst                     (resetn ),
        .Virt_Daddr              (MM2Bus.MEM_ALUOut[31:12] ),
        .TLBBuffer_Flush         (TLBBuffer_Flush_Final ),
        .D_TLBEntry              (D_TLBEntry ),
        .s1_found                (s1_found ),
        .MEM_LoadType            (MEM_LoadType ),
        .MEM_StoreType           (MEM_StoreType ),
        .CP0_Config_K0           (CP0_Config_K0 ),
        //---------------------------------------output--------------------------//
        .Phsy_Daddr              (Phsy_Daddr ),
        .D_IsCached              (D_IsCached ),
        .D_IsTLBBufferValid      (D_IsTLBBufferValid ),
        .D_IsTLBStall            (D_IsTLBStall ),
        .MEM_TLBExceptType       (MEM_TLBExceptType ),
        .D_VPN2                  ( D_VPN2)
        // .DTLBBuffer              (DTLBBuffer)
    );

    // DTLB_ila DTLB_ILA(
    //     .clk(clk),
    //     .probe0 (TLBBuffer_Flush_Final),
    //     .probe1 (MEM_ALUOut),
    //     .probe2 (D_TLBEntry),
    //     .probe3 (s1_found), 
    //     .probe4 (MEM_LoadType),       // [4:0]
    //     .probe5 (MEM_StoreType ), // [4:0]
    //     .probe6 (Phsy_Daddr),    // [4:0]
    //     .probe7 (D_IsCached),     //[1:0]
    //     .probe8 (D_IsTLBBufferValid),      // [0:0]
    //     .probe9 (D_IsTLBStall),
    //     .probe10(MEM_TLBExceptType),
    //     .probe11(MM2Bus.MEM_PC),
    //     .probe12(MM2Bus.MEM_Instr ),
    //     .probe13(DTLBBuffer)
    // );


endmodule