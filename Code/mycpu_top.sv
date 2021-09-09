/*
 * @Author: npuwth
 * @Date: 2021-06-28 18:45:50
 * @LastEditTime: 2021-07-06 22:06:49
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CPU_Defines.svh"
`include "CommonDefines.svh"

module mycpu_top (
    input  logic  [ 5:0]       ext_int,
    input  logic               aclk,
    input  logic               aresetn,
    output logic  [ 3:0]       arid,
    output logic  [31:0]       araddr,
    output logic  [ 3:0]       arlen,
    output logic  [ 2:0]       arsize,
    output logic  [ 1:0]       arburst,
    output logic  [ 1:0]       arlock,
    output logic  [ 3:0]       arcache,
    output logic  [ 2:0]       arprot,
    output logic               arvalid,
    input  logic               arready,
    input  logic  [ 3:0]       rid,
    input  logic  [31:0]       rdata,
    input  logic  [ 1:0]       rresp,
    input  logic               rlast,
    input  logic               rvalid,
    output logic               rready,
    output logic  [ 3:0]       awid,
    output logic  [31:0]       awaddr,
    output logic  [ 3:0]       awlen,
    output logic  [ 2:0]       awsize,
    output logic  [ 1:0]       awburst,
    output logic  [ 1:0]       awlock,
    output logic  [ 3:0]       awcache,
    output logic  [ 2:0]       awprot,
    output logic               awvalid,
    input  logic               awready,
    output logic  [ 3:0]       wid,
    output logic  [31:0]       wdata,
    output logic  [ 3:0]       wstrb,
    output logic               wlast,
    output logic               wvalid,
    input  logic               wready,
    input  logic  [ 3:0]       bid,
    input  logic  [ 1:0]       bresp,
    input  logic               bvalid,
    output logic               bready,
    output [31:0]              debug_wb_pc,        
    output [31:0]              debug_wb_rf_wdata,  
    output [3:0]               debug_wb_rf_wen,    
    output [4:0]               debug_wb_rf_wnum   
);
    logic [31:0]               WB_PC;                     //来自WB级,用于Debug
    logic [31:0]               WB_Result;                 //来自WB级,用于Debug
    logic [4:0]                WB_Dst;                    //来自WB级,用于Debug
    RegsWrType                 WB_Final_Wr;               //来自
    logic                      ID_Flush_Exception;        //来自exception
    logic                      EXE_Flush_Exception;       //来自exception
    logic                      MEM_Flush_Exception;       //来自exception
    logic                      DH_PCWr;                   //来自DataHazard
    logic                      DH_IDWr;                   //来自DataHazard
    logic                      EXE_Flush_DataHazard;      //来自DataHazard
    logic                      EXE_MULTDIVStall;          //来自EXE级的乘除法,用于阻塞
    logic [1:0]                IsExceptionOrEret;         //来自MEM级，表示有异常或异常返回
    logic                      ID_Flush_BranchSolvement;  //来自EXE级的branchsolvement，清空ID寄存器
    logic                      ID_IsAImmeJump;            //来自ID级，表示是j，jal跳转
    //-----------------------------流水线寄存器的写使能和flush------------------------------//
    logic                      PC_Wr;                     //来自WRFlushControl
    logic                      ID_Wr;                     //来自WRFlushControl
    logic                      EXE_Wr;                    //来自WRFlushControl  
    logic                      MEM_Wr;                    //来自WRFlushControl
    logic                      WB_Wr;                     //来自WRFlushControl
    logic                      ID_Flush;                  //来自WRFlushControl
    logic                      EXE_Flush;                 //来自WRFlushControl
    logic                      MEM_Flush;                 //来自WRFlushControl
    logic                      WB_Flush;                  //来自WRFlushControl
    //--------------------------------------------------------------------------------------//
    logic                      WB_DisWr;                  //来自WRFlushControl,传至WB级，用于生成WB_Final_Wr
    logic                      HiLo_Not_Flush;            //来自WRFlushControl,传至HILO寄存器

    logic [31:0]               EXE_BusA_L1;               //来自EXE，用于MT指令写HiLo，也用于生成jr的npc
    
    RegsWrType                 WB_RegsWrType;             //WB级的写使能

    BranchType                 EXE_BranchType;            //来自EXE级，传至IF，用于生成NPC
    logic [31:0]               EXE_PC;                    //来自EXE级，传至IF，用于生成NPC
    logic [31:0]               EXE_Imm32;                 //来自EXE级，传至IF，用于生成NPC  
    //----------------------------------------------关于TLBMMU-----------------------------------------------------//
    logic                      MEM_IsTLBP;                //传至TLBMMU，用于判断是普通访存还是TLBP
    logic [31:0]               Virt_Daddr;                //传至TLBMMU，用于TLB转换
    logic [31:0]               Phsy_Daddr;                //传至TLBMMU，用于TLB转换
    logic [31:0]               Virt_Iaddr;                //传至TLBMMU，用于TLB转换
    logic [31:0]               Phsy_Iaddr;                //传至TLBMMU，用于TLB转换
    logic                      MEM_IsTLBW;                //传至TLBMMU，用于写TLB
    logic [31:0]               MEM_PC;                    //传至IF，用于TLB重取机制
    //--------------------------------------用于golden trace-------------------------------------------------------//
    assign debug_wb_pc = WB_PC;                                                              //写回级的PC
    assign debug_wb_rf_wdata = WB_Result;                                                    //写回寄存器的数据
    assign debug_wb_rf_wen = (WB_Final_Wr.RFWr) ? 4'b1111 : 4'b0000;                         //4位字节写使能
    assign debug_wb_rf_wnum = WB_Dst;                                                        //写回寄存器的地址
    //---------------------------------------interface实例化-------------------------------------------------------//
    CPU_Bus_Interface           cpu_ibus();
    CPU_Bus_Interface           cpu_dbus();
    AXI_Bus_Interface           axi_ibus();
    AXI_Bus_Interface           axi_dbus();
    AXI_UNCACHE_Interface       axi_ubus();
    IF_ID_Interface             IIBus();
    ID_EXE_Interface            IEBus();
    EXE_MEM_Interface           EMBus();
    MEM_WB_Interface            MWBus();
    WB_CP0_Interface            WCBus();
    CP0_MMU_Interface           CMBus();
    //--------------------------------------------------------------------------------------------------------------//
    WrFlushControl U_WRFlushControl (
        .ID_Flush_Exception     (ID_Flush_Exception),
        .EXE_Flush_Exception    (EXE_Flush_Exception),
        .MEM_Flush_Exception    (MEM_Flush_Exception),
        .DH_PCWr                (DH_PCWr),
        .DH_IDWr                (DH_IDWr),
        .EXE_Flush_DataHazard   (EXE_Flush_DataHazard), // 以上三个是数据冒险的3个控制信号
        .DIVMULTBusy            (EXE_MULTDIVStall),
        .IsExceptionorEret      (IsExceptionOrEret),
        .BranchFailed           (ID_Flush_BranchSolvement),
        .ID_IsAImmeJump         (ID_IsAImmeJump),
        .Icache_data_ok         (cpu_ibus.data_ok),
        .Icache_busy            (~cpu_ibus.addr_ok),  // addr_ok = 1表示cache空闲
        .Dcache_data_ok         (cpu_dbus.data_ok),
        .Dcache_busy            (~cpu_dbus.addr_ok),  // addr_ok = 1表示cache空闲
        //-------------------------------- output-----------------------------//
        .PC_Wr                  (PC_Wr),
        .ID_Wr                  (ID_Wr),
        .EXE_Wr                 (EXE_Wr),
        .MEM_Wr                 (MEM_Wr),
        .WB_Wr                  (WB_Wr),
        .ID_Flush               (ID_Flush),
        .EXE_Flush              (EXE_Flush),
        .MEM_Flush              (MEM_Flush),
        .WB_Flush               (WB_Flush),
        .WB_DisWr               (WB_DisWr),
        .HiLo_Not_Flush         (HiLo_Not_Flush),
        .IcacheFlush            (cpu_ibus.flush),
        .DcacheFlush            (cpu_dbus.flush)
    );

    //------------------------AXI-----------------------//
    AXIInteract AXIInteract_dut (
        .clk                    (aclk ),
        .resetn                 (aresetn ),
        .DcacheAXIBus           (axi_dbus.slave ),
        .IcacheAXIBus           (axi_ibus.slave ),
        .UncacheAXIBus          (axi_ubus.slave) ,
        .m_axi_arid             (arid ),
        .m_axi_araddr           (araddr ),
        .m_axi_arlen            (arlen ),
        .m_axi_arsize           (arsize ),
        .m_axi_arburst          (arburst ),
        .m_axi_arlock           (arlock ),
        .m_axi_arcache          (arcache ),
        .m_axi_arprot           (arprot ),
        .m_axi_arvalid          (arvalid ),
        .m_axi_arready          (arready ),
        .m_axi_rid              (rid ),
        .m_axi_rdata            (rdata ),
        .m_axi_rresp            (rresp ),
        .m_axi_rlast            (rlast ),
        .m_axi_rvalid           (rvalid ),
        .m_axi_rready           (rready ),
        .m_axi_awid             (awid ),
        .m_axi_awaddr           (awaddr ),
        .m_axi_awlen            (awlen ),
        .m_axi_awsize           (awsize ),
        .m_axi_awburst          (awburst ),
        .m_axi_awlock           (awlock ),
        .m_axi_awcache          (awcache ),
        .m_axi_awprot           (awprot ),
        .m_axi_awvalid          (awvalid ),
        .m_axi_awready          (awready ),
        .m_axi_wid              (wid ),
        .m_axi_wdata            (wdata ),
        .m_axi_wstrb            (wstrb ),
        .m_axi_wlast            (wlast ),
        .m_axi_wvalid           (wvalid ),
        .m_axi_wready           (wready ),
        .m_axi_bid              (bid ),
        .m_axi_bresp            (bresp ),
        .m_axi_bvalid           (bvalid ),
        .m_axi_bready           (bready)
    );

    TOP_IF U_TOP_IF ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .PC_Wr (PC_Wr ),
        .MEM_CP0Epc (CP0_EPC ),
        .EXE_BusA_L1 (EXE_BusA_L1 ),
        .ID_Flush_BranchSolvement (ID_Flush_BranchSolvement ),
        .ID_IsAImmeJump (ID_IsAImmeJump ),
        .IsExceptionOrEret (IsExceptionOrEret ),
        .EXE_BranchType (EXE_BranchType ),
        .ID_Wr (ID_Wr ),
        .ID_Flush_Exception (ID_Flush_Exception ),
        .EXE_Flush_DataHazard (EXE_Flush_DataHazard ),
        .EXE_PC (EXE_PC ),
        .EXE_Imm32 (EXE_Imm32 ),
        .Phsy_Iaddr(Phsy_Iaddr),
        .MEM_PC (MEM_PC),
        //--------------------output-----------------//
        .IIBus  ( IIBus.IF),
        .cpu_ibus (cpu_ibus),
        .axi_ibus (axi_ibus),
        .Virt_Iaddr(Virt_Iaddr)
    );

    TOP_ID U_TOP_ID ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .ID_Flush (ID_Flush ),
        .ID_Wr (ID_Wr ),
        .WB_Result (WB_Result ),
        .WB_Dst (WB_Dst ),
        .WB_RegsWrType (WB_RegsWrType ),
        .IIBus (IIBus.ID ),
        .IEBus (IEBus.ID ),
        //-------------------------------output-------------------//
        .ID_IsAImmeJump (ID_IsAImmeJump),
        .DH_PCWr(DH_PCWr),
        .DH_IDWr(DH_IDWr),
        .EXE_Flush_DataHazard(EXE_Flush_DataHazard)
    );

    TOP_EXE U_TOP_EXE ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .EXE_Flush (EXE_Flush ),
        .EXE_Wr (EXE_Wr ),
        .WB_RegsWrType (WB_RegsWrType ), //???
        .WB_Dst (WB_Dst ),
        .WB_Result (WB_Result ),
        .HiLo_Not_Flush (HiLo_Not_Flush ),
        .IEBus (IEBus.EXE ),
        .EMBus (EMBus.EXE ),
        //--------------------------output-------------------------//
        .ID_Flush_BranchSolvement (ID_Flush_BranchSolvement ),
        .EXE_MULTDIVStall  (EXE_MULTDIVStall),
        .EXE_BusA_L1 (EXE_BusA_L1),
        .EXE_BranchType (EXE_BranchType),
        .EXE_PC (EXE_PC),
        .EXE_Imm32 (EXE_Imm32)
    );

    TOP_MEM U_TOP_MEM ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .MEM_Flush (MEM_Flush ),
        .MEM_Wr (MEM_Wr ),
        .WB_Wr (WB_Wr),
        .Phsy_Daddr(Phsy_Daddr),
        .EMBus (EMBus.MEM ),
        .MWBus (MWBus.MEM ),
        .cpu_dbus (cpu_dbus),
        .axi_dbus (axi_dbus),
        .axi_ubus (axi_ubus),
        //--------------------------output-------------------------//
        .ID_Flush_Exception (ID_Flush_Exception ),
        .EXE_Flush_Exception (EXE_Flush_Exception ),
        .MEM_Flush_Exception (MEM_Flush_Exception ),
        .IsExceptionOrEret (IsExceptionOrEret ),
        .Virt_Daddr(Virt_Daddr),
        .MEM_IsTLBP(MEM_IsTLBP),
        .MEM_IsTLBW(MEM_IsTLBW),
        .MEM_PC(MEM_PC)
    );

    TOP_WB U_TOP_WB ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .WB_Flush (WB_Flush ),
        .WB_Wr (WB_Wr ),
        .WB_DisWr (WB_DisWr ),
        .MWBus (MWBus.WB ),
        //--------------------------output-------------------------//
        .WB_Result (WB_Result ),
        .WB_Dst (WB_Dst ),
        .WB_Final_Wr (WB_Final_Wr ),
        .WB_RegsWrType (WB_RegsWrType),
        .WB_PC(WB_PC )
    );

    TLBMMU U_TLBMMU ( 
        .clk (aclk ),
        .Virt_Iaddr (Virt_Iaddr ),
        .Virt_Daddr (Virt_Daddr ),
        .MEM_Type (MEM_Type),
        .IF_ExceptType(IF_ExceptType),
        .MEM_ExceptType(MEM_ExceptType),
        .MEM_IsTLBP (MEM_IsTLBP ),
        .MEM_IsTLBW (MEM_IsTLBW),
        .CMBus (CMBus.MMU ),
        .Phsy_Iaddr (Phsy_Iaddr ),
        .Phsy_Daddr  ( Phsy_Daddr),
        .IF_ExceptType_new(IF_ExceptType_new),
        .MEM_ExceptType_new(MEM_ExceptType_new)
    );


endmodule

