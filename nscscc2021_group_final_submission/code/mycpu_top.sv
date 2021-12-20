/*
 * @Author: npuwth
 * @Date: 2021-06-28 18:45:50
 * @LastEditTime: 2021-08-15 22:31:33
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CPU_Defines.svh"
`include "CommonDefines.svh"
`include "Cache_options.svh"

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
    logic [31:0]               WB_Result;                 //来自WB级,用于Debug和旁路
    logic [4:0]                WB_Dst;                    //来自WB级,用于Debug和旁路
    logic                      Flush_Exception;           //来自MEM级的异常检测
    logic                      ID_EX_DH_Stall;            //来自DataHazard
    logic                      ID_MEM1_DH_Stall;          //来自DataHazard
    logic                      ID_MEM2_DH_Stall;          //来自DataHazard
    logic                      EXE_MULTDIVStall;          //来自EXE级的乘除法,用于阻塞
    logic                      EXE_Prediction_Failed;     //来自EXE级，分支预测错误
    logic                      EXE_PF_FlushAll;
    logic [31:0]               EXE_Correction_Vector;     //用于校正分支预测
    logic                      EXE_IsBrchLikely;
    logic                      EXE_IsTaken;
    logic [1:0]                EX_Entry_Sel;              //来自MEM级，表示有异常或异常返回
    logic [31:0]               Exception_Vector;          //传至PREIF，异常入口向量
    logic [31:0]               CP0_EPC;                   //传至PREIF,用于ERET返回
    BResult                    EXE_BResult;               //用于校正BPU
    CacheType                  MEM_CacheType;             //用于Cache指令
    logic [31:0]               MEM_ALUOut;                //用于Cache指令
    //-----------------------------流水线寄存器的写使能和flush------------------------------//
    logic                      PREIF_Wr;                  //来自Control
    logic                      IF_Wr;                     //来自Control
    logic                      ID_Wr;                     //来自Control
    logic                      EXE_Wr;                    //来自Control  
    logic                      MEM_Wr;                    //来自Control
    logic                      MEM2_Wr;                   //来自Control
    logic                      WB_Wr;                     //来自Control
    logic                      IF_Flush;                  //来自Control
    logic                      ID_Flush;                  //来自Control
    logic                      EXE_Flush;                 //来自Control
    logic                      MEM_Flush;                 //来自Control
    logic                      MEM2_Flush;                //来自Control
    logic                      WB_Flush;                  //来自Control
    //--------------------------------------------------------------------------------------//
    logic                      ID_DisWr;                  //来自Control
    logic                      EXE_DisWr;                 //来自Control
    logic                      MEM_DisWr;                 //来自Control
    logic                      WB_DisWr;                  //来自Control
    logic                      IReq_valid; 
    logic                      DReq_valid; 

    RegsWrType                 MEM2_RegsWrType;           //MEM2级的写使能
    logic [4:0]                MEM2_Dst;                  //MEM2级目标寄存器（用于旁路）
    logic [31:0]               MEM2_Result;               //MEM2级旁路的结果（用于旁路）
    LoadType                   MEM2_LoadType;             //用于ID级检测Load类型指令的数据冒险

    RegsWrType                 WB_RegsWrType;             //WB级的写使能
    RegsWrType                 WB_Final_Wr;               //WB级最终的写使能

    logic                      MEM_IsMFC0;                 //用于判断MFC0后的阻塞
    logic [31:0]               MEM_Result;                // 用于旁路数据
    logic [4:0]                MEM_Dst;
    RegsWrType                 MEM_RegsWrType;
    logic [31:0]               MEM_PC;                    //传至PREIF，用于TLB重取机制
    logic                      MEM_Refetch;               //用于TLB和Cache重取
    LoadType                   MEM_LoadType;              //用于Control & load指令的数据冒险
    StoreType                  MEM_StoreType;             //用于Control 
    //----------------------------------------------关于TLBMMU-----------------------------------------------------//
    logic                      MEM_IsTLBP;                //传至TLBMMU，用于判断是普通访存还是TLBP
    logic                      MEM_IsTLBW;                //传至TLBMMU，用于写TLB
    logic                      MEM_TLBWIorR;              //表示是TLBWI还是TLBWR
    logic                      I_IsTLBStall;              //表示是否需要阻塞，然后转为search tlb
    logic                      D_IsTLBStall;              //表示是否需要阻塞，然后转为search tlb
    logic                      TLBBuffer_Flush;           //在修改TLB或ASID后清空buffer
    TLB_Entry                  I_TLBEntry;                //Buffer与TLB交互
    TLB_Entry                  D_TLBEntry;                //Buffer与TLB交互
    logic                      s0_found;                  //Buffer与TLB交互
    logic                      s1_found;                  //Buffer与TLB交互
    logic [31:13]              I_VPN2;                    //Buffer与TLB交互
    logic [31:13]              D_VPN2;                    //Buffer与TLB交互
    logic [2:0]                CP0_Config_K0;
    
    //--------------------------------------用于golden trace-------------------------------------------------------//
    assign debug_wb_pc = WB_PC;                                                              //写回级的PC
    assign debug_wb_rf_wdata = WB_Result;                                                    //写回寄存器的数据
    assign debug_wb_rf_wen = (WB_Final_Wr.RFWr) ? 4'b1111 : 4'b0000;                         //4位字节写使能
    assign debug_wb_rf_wnum = WB_Dst;           
    
    // ila CPU_TOP_ILA(
    //     .clk(aclk),
    //     .probe0 (debug_wb_pc),
    //     .probe1 (debug_wb_rf_wdata),
    //     .probe2 (debug_wb_rf_wen),
    //     .probe3 (debug_wb_rf_wnum),
    //     .probe4 (M2WBus.MEM2_Instr),
    //     .probe5 (MM2Bus.MEM_ExcType),
    //     .probe6 (Exception_Vector)
    // );

    //---------------------------------------interface实例化-------------------------------------------------------//
    CPU_IBus_Interface          cpu_ibus();
    CPU_DBus_Interface          cpu_dbus();
    AXI_IBus_Interface          axi_ibus();
    AXI_DBus_Interface          axi_dbus();
    AXI_UNCACHE_Interface       axi_ubus();
    AXI_UNCACHE_Interface       axi_iubus();
    PREIF_IF_Interface          PIBus();
    IF_ID_Interface             IIBus();
    ID_EXE_Interface            IEBus();
    EXE_MEM_Interface           EMBus();
    MEM_MEM2_Interface          MM2Bus();
    MEM2_WB_Interface           M2WBus();
    CP0_TLB_Interface           CTBus();
    //--------------------------------------------------------------------------------------------------------------//
    Control U_Control (
        .Flush_Exception        (Flush_Exception ),
        .I_IsTLBStall           (I_IsTLBStall ),
        .D_IsTLBStall           (D_IsTLBStall ),
        .Icache_busy            (cpu_ibus.busy ),
        .Dcache_busy            (cpu_dbus.busy ),
        .ID_EX_DH_Stall         (ID_EX_DH_Stall),
        .ID_MEM1_DH_Stall       (ID_MEM1_DH_Stall),
        .ID_MEM2_DH_Stall       (ID_MEM2_DH_Stall),
        .EXE_PredictFailed      (EXE_Prediction_Failed),
        .EXE_PF_FlushAll        (EXE_PF_FlushAll),
        .EXE_IsBrchLikely       (EXE_IsBrchLikely),
        .EXE_IsTaken            (EXE_IsTaken),
        .DIVMULTBusy            (EXE_MULTDIVStall),
        //-------------------------------- output-----------------------------//
        .PREIF_Wr               (PREIF_Wr),
        .IF_Wr                  (IF_Wr),
        .ID_Wr                  (ID_Wr),
        .EXE_Wr                 (EXE_Wr),
        .MEM_Wr                 (MEM_Wr),
        .MEM2_Wr                (MEM2_Wr),
        .WB_Wr                  (WB_Wr),

        .IF_Flush               (IF_Flush ),
        .ID_Flush               (ID_Flush ),
        .EXE_Flush              (EXE_Flush ),
        .MEM_Flush              (MEM_Flush ),
        .MEM2_Flush             (MEM2_Flush ),
        .WB_Flush               (WB_Flush ),

        .ID_DisWr               (ID_DisWr),
        .EXE_DisWr              (EXE_DisWr ),
        .MEM_DisWr              (MEM_DisWr ),
        .WB_DisWr               (WB_DisWr ),

        .IReq_valid             (IReq_valid),
        .DReq_valid             (DReq_valid),
        .ICache_Stall           (cpu_ibus.stall),
        .DCache_Stall           (cpu_dbus.stall)
    );





    // control_ila control_ILA(
    //     .clk(aclk),
    //     .probe0 (Flush_Exception),
    //     .probe1 (I_IsTLBStall),
    //     .probe2 (D_IsTLBStall),
    //     .probe3 (cpu_ibus.busy),
    //     .probe4 (cpu_dbus.busy ),
    //     .probe5 (ID_EX_DH_Stall),
    //     .probe6 (ID_MEM1_DH_Stall),
    //     .probe7 (ID_MEM2_DH_Stall),
    //     .probe8 (EXE_Prediction_Failed),
    //     .probe9 (EXE_PF_FlushAll),
    //     .probe10(EXE_IsBrchLikely),
    //     .probe11(EXE_IsTaken),
    //     .probe12(EXE_MULTDIVStall),
    //     .probe13(MM2Bus.MEM_ExcType),
    //     .probe14(debug_wb_pc),
    //     .probe15(M2WBus.MEM2_Instr) 
    // );


    // pc_instr_ila PC_INSTR_ILA(
    //     .clk(aclk),
    //     .probe0 (PIBus.PREIF_PC),
    //     .probe1 (IIBus.IF_PC),
    //     .probe2 (IIBus.IF_Instr),
    //     .probe3 (IEBus.ID_PC),
    //     .probe4 (IEBus.ID_Instr ),
    //     .probe5 (EMBus.EXE_PC),
    //     .probe6 (EMBus.EXE_Instr),
    //     .probe7 (MM2Bus.MEM_PC),
    //     .probe8 (MM2Bus.MEM_Instr),
    //     .probe9 (M2WBus.MEM2_PC),
    //     .probe10(M2WBus.MEM2_Instr),
    //     .probe11(MM2Bus.MEM_ExcType),
    //     .probe12(debug_wb_pc),
    //     .probe13(M2WBus.MEM2_Instr) 
    // );

//------------------------AXI-----------------------//
    `ifdef NEW_BRIDGE
    AXIInteract  #(
        `ICACHE_LINE_WORD,
        `DCACHE_LINE_WORD
    )
    AXIInteract_dut
    (
        .clk                    (aclk ),
        .resetn                 (aresetn ),
        .dbus                   (axi_dbus.slave ),
        .ibus                   (axi_ibus.slave ),
        .udbus                  (axi_ubus.slave) ,
        .uibus                  (axi_iubus.slave),
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
    `else
    AXIInteract AXIInteract_dut
    (
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
    `endif 
    
    TOP_PREIF U_TOP_PREIF ( 
        .clk                       (aclk ),
        .resetn                    (aresetn ),
        .PREIF_Wr                  (PREIF_Wr ),//也就是PC写使能
        .MEM_CP0Epc                (CP0_EPC ),
        .EX_Entry_Sel              (EX_Entry_Sel ),
        .MEM_PC                    (MEM_PC ),
        .Exception_Vector          (Exception_Vector ),
        .I_TLBEntry                (I_TLBEntry ),
        .s0_found                  (s0_found ),
        .TLBBuffer_Flush           (TLBBuffer_Flush ),
        .IReq_valid                (IReq_valid),
        .EXE_Correction_Vector     (EXE_Correction_Vector),
        .EXE_Prediction_Failed     (EXE_Prediction_Failed),
        .EXE_PF_FlushAll           (EXE_PF_FlushAll),
        .CP0_Config_K0             (CP0_Config_K0 ),
        .MEM_CacheType             (MEM_CacheType),
        .MEM_ALUOut                (MEM_ALUOut),
        .MEM_Refetch               (MEM_Refetch),
        .PIBus                     (PIBus.PREIF ),
        .cpu_ibus                  (cpu_ibus ),
        .axi_ibus                  (axi_ibus ),
        .axi_iubus                 (axi_iubus),
        //-----------------------output-------------------------------//
        .I_VPN2                    (I_VPN2 ),
        .I_IsTLBStall              (I_IsTLBStall )
    );

    TOP_IF U_TOP_IF (
        .clk                       (aclk ),
        .resetn                    (aresetn ),
        .IF_Wr                     (IF_Wr ),
        .IF_Flush                  (IF_Flush ),
        .EXE_BResult               (EXE_BResult ),
        .MEM_Refetch               (MEM_Refetch),     
        .PIBus                     (PIBus.IF ),
        .IIBus                     (IIBus.IF ),
        .cpu_ibus                  (cpu_ibus)
    );

    TOP_ID U_TOP_ID ( 
        .clk                       (aclk ),
        .resetn                    (aresetn ),
        .ID_Flush                  (ID_Flush ),
        .ID_Wr                     (ID_Wr ),
        .MEM_rt                    (MEM_Dst),   
        .MEM_ReadMEM               (MEM_LoadType.ReadMem), // load信号用于数据冒险 TODO:连线
        .MEM2_rt                   (MEM2_Dst),
        .MEM2_ReadMEM              (MEM2_LoadType.ReadMem),
        .ID_DisWr                  (ID_DisWr),
        .MEM_Result                (MEM_Result ),
        .MEM_Dst                   (MEM_Dst ),
        .MEM_RegsWrType            (MEM_RegsWrType ), //用于旁路
        .MEM2_Result               (MEM2_Result ),      
        .MEM2_Dst                  (MEM2_Dst ),               
        .MEM2_RegsWrType           (MEM2_RegsWrType ),  
        .WB_Result                 (WB_Result ),
        .WB_Dst                    (WB_Dst ),
        .WB_RegsWrType             (WB_RegsWrType ),
        .MEM_IsMFC0                (MEM_IsMFC0),
        .MEM_Refetch               (MEM_Refetch),
        .IIBus                     (IIBus.ID ),
        .IEBus                     (IEBus.ID ),
        //-------------------------------output-------------------//
        .ID_EX_DH_Stall            (ID_EX_DH_Stall),
        .ID_MEM1_DH_Stall          (ID_MEM1_DH_Stall),
        .ID_MEM2_DH_Stall          (ID_MEM2_DH_Stall)
    );

    TOP_EXE U_TOP_EXE ( 
        .clk                       (aclk ),
        .resetn                    (aresetn ),
        .EXE_Flush                 (EXE_Flush ),
        .EXE_Wr                    (EXE_Wr ),
        .EXE_DisWr                 (EXE_DisWr),
        .MEM_Refetch               (MEM_Refetch),
        .IEBus                     (IEBus.EXE ),
        .EMBus                     (EMBus.EXE ),
        //--------------------------output-------------------------//
        .EXE_Prediction_Failed     (EXE_Prediction_Failed),
        .EXE_PF_FlushAll           (EXE_PF_FlushAll),
        .EXE_Correction_Vector     (EXE_Correction_Vector),
        .EXE_BResult               (EXE_BResult),
        .EXE_MULTDIVStall          (EXE_MULTDIVStall),
        .EXE_IsBrchLikely          (EXE_IsBrchLikely),
        .EXE_IsTaken               (EXE_IsTaken)
    );

    TOP_MEM U_TOP_MEM ( 
        .clk                       (aclk ),
        .resetn                    (aresetn ),
        .MEM_Flush                 (MEM_Flush ),
        .MEM_Wr                    (MEM_Wr ),

        .Interrupt                 (ext_int ),
        .MEM_DisWr                 (MEM_DisWr ),
        .D_TLBEntry                (D_TLBEntry ),
        .s1_found                  (s1_found ),
        .DReq_valid                (DReq_valid),
        .EMBus                     (EMBus.MEM ),
        .MM2Bus                    (MM2Bus.MEM ),
        .CTBus                     (CTBus ),
        .cpu_dbus                  (cpu_dbus),
        .axi_dbus                  (axi_dbus),
        .axi_ubus                  (axi_ubus),
        //--------------------------output-------------------------//
        .Flush_Exception           (Flush_Exception),
        .EX_Entry_Sel              (EX_Entry_Sel ),
        .MEM_IsTLBP                (MEM_IsTLBP ),
        .MEM_IsTLBW                (MEM_IsTLBW ),
        .MEM_TLBWIorR              (MEM_TLBWIorR),
        .MEM_PC                    (MEM_PC ),
        .CP0_EPC                   (CP0_EPC ),
        .MEM_LoadType              (MEM_LoadType ),
        .MEM_StoreType             (MEM_StoreType ),
        .Exception_Vector          (Exception_Vector ),
        .D_VPN2                    (D_VPN2 ),
        .D_IsTLBStall              (D_IsTLBStall ),
        .TLBBuffer_Flush_Final     (TLBBuffer_Flush),
        .MEM_Result                (MEM_Result),     
        .MEM_Dst                   (MEM_Dst),     
        .MEM_RegsWrType            (MEM_RegsWrType),
        .MEM_IsMFC0                (MEM_IsMFC0),
        .CP0_Config_K0             (CP0_Config_K0),
        .MEM_CacheType             (MEM_CacheType),
        .MEM_ALUOut                (MEM_ALUOut),
        .MEM_Refetch               (MEM_Refetch)
    );
    
    TOP_MEM2 U_TOP_MEM2 (
        .clk                       (aclk ),
        .resetn                    (aresetn ),
        .MEM2_Flush                (MEM2_Flush ),
        .MEM2_Wr                   (MEM2_Wr ),
        .MM2Bus                    (MM2Bus.MEM2 ),
        .M2WBus                    (M2WBus.MEM2 ),
        .cpu_dbus                  (cpu_dbus ),
        //--------------------------output-------------------------//
        .MEM2_Result               (MEM2_Result ),
        .MEM2_Dst                  (MEM2_Dst ),
        .MEM2_RegsWrType           (MEM2_RegsWrType),
        .MEM2_LoadType             (MEM2_LoadType)
    );


    TOP_WB U_TOP_WB ( 
        .clk                       (aclk ),
        .resetn                    (aresetn ),
        .WB_Flush                  (WB_Flush ),
        .WB_Wr                     (WB_Wr ),
        .WB_DisWr                  (WB_DisWr ),
        .M2WBus                    (M2WBus.WB ),
        //--------------------------output-------------------------//
        .WB_Result                 (WB_Result ),
        .WB_Dst                    (WB_Dst ),
        .WB_Final_Wr               (WB_Final_Wr ),
        .WB_RegsWrType             (WB_RegsWrType),
        .WB_PC                     (WB_PC )
    );
`ifdef EN_TLB
    TLB U_TLB( 
        .clk                       (aclk ),
        .rst                       (aresetn ),
        .I_VPN2                    (I_VPN2 ),
        .D_VPN2                    (D_VPN2 ),
        .MEM_IsTLBP                (MEM_IsTLBP ),
        .MEM_IsTLBW                (MEM_IsTLBW ),
        .MEM_TLBWIorR              (MEM_TLBWIorR ),
        .CTBus                     (CTBus.TLB ),
        //---------------output---------------//
        .s0_found                  (s0_found ),
        .I_TLBEntry                (I_TLBEntry ),
        .s1_found                  (s1_found ),
        .D_TLBEntry                ( D_TLBEntry)
    );
`endif

    // dcache_ila DCACHE_ILA(
    //     .clk(aclk),
    //     .probe0(cpu_dbus.valid),
    //     .probe1(cpu_dbus.op),
    //     .probe2({cpu_dbus.tag,cpu_dbus.index,cpu_dbus.offset}),
    //     .probe3(cpu_dbus.wstrb),
    //     .probe4(cpu_dbus.loadType),
    //     .probe5(cpu_dbus.wdata),
    //     .probe6(cpu_dbus.busy),
    //     .probe7(cpu_dbus.rdata),
    //     .probe8(cpu_dbus.stall),
    //     .probe9(cpu_dbus.origin_valid),
    //     .probe10(cpu_dbus.isCache),
    //     .probe11(cpu_dbus.cacheType),
    //     .probe12(MM2Bus.MEM_ExcType),
    //     .probe13(debug_wb_pc)
    // );

//     logic [31:0] count;

//     logic [31:0] din;
//     logic  wr_en;
//     logic  rd_en;

//     logic rd_rst_busy;
//     logic full;
//     logic empty;
//     logic [31:0] dout;
//     logic data_valid;
//     logic wr_ack;
//     logic wr_rst_busy;

//     always_ff @(posedge aclk) begin
//         if (!aresetn) begin
//             din<='0;
//         end else begin
//             din<=din+1;
//         end
//     end

//     always_ff @(posedge aclk) begin
//         if (!aresetn) begin
//             count<='0;
//         end else begin
//             count<=count+1;
//         end
//     end


//     assign rd_en = (rd_rst_busy || empty)? 1'b0:1'b1;

//     assign wr_en = (wr_rst_busy || full || count>100)? 1'b0:1'b1;
//     // always_ff @(posedge aclk) begin
//     // if (wr_rst_busy || full) begin
//     //     wr_en=1'b0;
//     // end else begin
//     //     wr_en=1'b1;
//     // end
//     // end

//   FIFO #(
//     .LATENCY (1)
//   )
//   FIFO_dut (
//     .clk (aclk ),
//     .rst (~aresetn ),
//     .din (din ),
//     .rd_en (rd_en ),
//     .wr_en (wr_en ),
//     //output
//     .rd_rst_busy (rd_rst_busy ),
//     .full (full ),
//     .empty (empty ),
//     .dout (dout ),
//     .data_valid (data_valid ),
//     .wr_ack (wr_ack ),
//     .wr_rst_busy  ( wr_rst_busy)
//   );





endmodule

  