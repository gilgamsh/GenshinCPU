/*
 * @Author:Juan
 * @Date: 2021-06-16 16:11:20
 * @LastEditTime: 2021-07-06 11:55:30
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "Cache_Defines.svh"
`include "CPU_Defines.svh"
`include "CommonDefines.svh"
module WrFlushControl(
    input logic       ID_Flush_Exception ,  //异常产生在IF/ID级的flush 
    input logic       EXE_Flush_Exception,  //异常产生在ID/EXE级的flush
    input logic       MEM_Flush_Exception, //异常产生在EXE/MEM级的flush
    input logic       DH_PCWr,             // Load & R型的数据冒险 & （前load 后 store的冒险 —— 以删除）  1代表没有出现该异常，流水线可以流动
    input logic       DH_IDWr,             // Load & R型的数据冒险 & （前load 后 store的冒险 —— 以删除）
    input logic       EXE_Flush_DataHazard, // 数据冒险产生的flush  
    input logic       DIVMULTBusy,              // 乘除法状态机空闲  & 注意需要取反后使用
    input logic [1:0] IsExceptionorEret,      // 用于生成HILO的flush信号
    input logic       BranchFailed,             // 分支预测失败时，产生的flush
    input logic       ID_IsAImmeJump,           // ID级 的 J JAL指令
    input logic       Icache_data_ok,           // Icache信号 用于判断IF/ID写使能信号是否可以打开
    input logic       Icache_busy,              // Icache信号 表示Icache是否要暂停流水线
    input logic       Dcache_data_ok,           // Icache信号 用于判断IF/ID写使能信号是否可以打开
    input logic       Dcache_busy,              // Icache信号 表示Icache是否要暂停流水线
      

    output logic      PC_Wr,
    output logic      ID_Wr,
    output logic      EXE_Wr,
    output logic      MEM_Wr,
    output logic      WB_Wr,
     
    output logic      ID_Flush,
    output logic      EXE_Flush,
    output logic      MEM_Flush,
    output logic      WB_Flush,
    output logic      WB_DisWr,
    output logic      HiLo_Not_Flush,
    output logic      IcacheFlush, //给Icache的Flush
    output logic      DcacheFlush //给Icache的Flush
    

);

    logic Exception;
    // logic BranchFailed;
    // logic DIVMULTBusy;

    assign Exception = ID_Flush_Exception;            // 出现异常
    // assign BranchFailed = ID_Flush_BranchSolvement_o;   // 为1代表分支预测失败，会产生flush
    // assign DIVMULTBusy = EXE_MULTDIVStall;                // 乘除法器状态机的busy信号（stall为1，时busy信号为1）
    // Icache Flush
    always_comb begin
        if (Exception == `FlushEnable) begin
            IcacheFlush = 1'b1;
        end
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin
            IcacheFlush = 1'b0;
        end
        else if (BranchFailed == `BRANCKFAILED ) begin  // 分支跳转失败，J JAL指令 JALR指令需要给出Icache flush
            IcacheFlush = 1'b1;                                              // 在ID级给出的原因：防止I$ busy，收不进去数据           
        end else begin
            IcacheFlush = 1'b0;
        end
    end
    // Dcache Flush
    always_comb begin
        if (Exception == `FlushEnable) begin
            DcacheFlush = 1'b1;
        end
        else begin
            DcacheFlush = 1'b0;
        end
    end
    // PC_Wr
    always_comb begin
        if (Exception == `FlushEnable) begin
            PC_Wr   = 1'b1;
        end 
        else if (Dcache_busy == `CACHEBUSY|| Icache_busy == `CACHEBUSY) begin
            PC_Wr   = 1'b0;
        end
        else if (EXE_Flush_DataHazard == 1'b1) begin // Icache 的状态影响不到数据冒险的情况
                PC_Wr = 1'b0;
        end
        else if (BranchFailed == `BRANCKFAILED  ) begin // 在D$空闲的情况下，考虑分支跳转失败，J JAL指令 JALR指令需要给出PC写使能
            PC_Wr   = 1'b1;
        end
        else begin
            if (DH_PCWr == 1'b0 || DIVMULTBusy == 1'b1) begin  // 数据冒险 & 乘除法
                PC_Wr = 1'b0;
            end
            else begin
                PC_Wr = 1'b1;
            end
        end
    end
    // ID_Wr
    always_comb begin
        if (Exception == `FlushEnable) begin
            ID_Wr   = 1'bx;
        end
        else if (Dcache_busy == `CACHEBUSY|| Icache_busy == `CACHEBUSY) begin
            ID_Wr   = 1'b0;
        end 
        else if (EXE_Flush_DataHazard == 1'b1) begin // Icache 的状态影响不到数据冒险的情况
            ID_Wr = 1'b0;
        end
        else if (BranchFailed == `BRANCKFAILED ) begin // 分支跳转失败, JALR指令需要给出 IF/ID Flush（因此IF/ID写使能不重要）
            ID_Wr   = 1'b1;
        end
        else if (Icache_busy == `CACHEBUSY && ID_IsAImmeJump == 1'b1) begin  // J JAL指令(在ID级跳转的指令) 需要给出IF/IDWR
            ID_Wr   = 1'b0;
        end
        else begin
             if (DH_IDWr == 1'b0 || DIVMULTBusy == 1'b1) begin  // 数据冒险 & 乘除法
                ID_Wr = 1'b0;
            end
            else begin
                ID_Wr = 1'b1;
            end
        end
    end

    // EXE_Wr
    always_comb begin
        if (Exception == `FlushEnable) begin
            EXE_Wr   = 1'bx;
        end 
        else if ( Dcache_busy == `CACHEBUSY|| Icache_busy == `CACHEBUSY) begin  //Dcache busy停滞流水线 ， Icache busy 一个flush+继续流动后续流水线
            EXE_Wr   = 1'b0;
        end
        // else if (BranchFailed == `BRANCKFAILED) begin
        //     EXE_Wr   = 1'b1;       // 延迟槽继续流动
        // end
        else begin
             if (DIVMULTBusy == 1'b1) begin  // 数据冒险 & 乘除法
                EXE_Wr = 1'b0;
            end
            else begin
                EXE_Wr = 1'b1;
            end
        end
    end

    // MEM_Wr
    always_comb begin 
        if (Exception == `FlushEnable) begin
            MEM_Wr   = 1'bx;
        end 
        else if ( Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin  //Dcache busy停滞流水线 ， Icache busy 一个flush+继续流动后续流水线
            MEM_Wr   = 1'b0;
        end
        else begin
            MEM_Wr   = 1'b1;
        end
    end

    // WB_Wr
    always_comb begin
        if (Exception == `FlushEnable) begin
            WB_Wr   = 1'b1;  // 异常时MEM_WB写使能始终打开
        end 
        else if ( Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin   //Dcache busy停滞流水线 ， Icache busy 一个flush+继续流动后续流水线
            WB_Wr   = 1'b0;  // 停滞流水线时 wb级数据不能写入RF
        end
        else begin
            WB_Wr   = 1'b1;
        end
    end
    // ID_Flush
    always_comb begin
        if (ID_Flush_Exception == `FlushEnable ) begin
            ID_Flush = 1'b1;
        end 
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY)begin
            ID_Flush = 1'b0;
        end
        else if (BranchFailed == 1'b1) begin // Dcache空闲的状态下，才考虑分支失败对应的flush
             ID_Flush = 1'b1;
        end
        // else if (Icache_busy == `CACHEBUSY ) begin // 策略调整为 Icache busy时，指令继续流动 
        //      ID_Flush = 1'b1;                   // Dcache busy停滞流水线 ， Icache busy 一个flush+继续流动后续流水线
        // end
        else begin
            ID_Flush = 1'b0;
        end
    end

    // EXE_Flush
    // 对于存在数据冒险的情况，必须等到I & D$不busy的时候，再去考虑Data Hazard 
    always_comb begin
        if (EXE_Flush_Exception == `FlushEnable) begin
            EXE_Flush = 1'b1;
        end 
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin
            EXE_Flush = 1'b0;
        end
        else if  (EXE_Flush_DataHazard == 1'b1) begin   // Dcache 空闲的情况下，才考虑数据冒险的情况 
            EXE_Flush = 1'b1;
        end
        else begin
            EXE_Flush = 1'b0;
        end
    end

    // MEM_Flush
    always_comb begin
        if (MEM_Flush_Exception == `FlushEnable) begin
            MEM_Flush = 1'b1;
        end
        else begin
            MEM_Flush = 1'b0;
        end
    end

    // assign ID_Flush     =  ID_Flush_Exception  | BranchFailed; 
    // assign EXE_Flush    =  EXE_Flush_Exception | EXE_Flush_DataHazard;  
    // assign MEM_Flush   =  MEM_Flush_Exception;
    always_comb begin
        // if (MEM_Flush_Exception == `FlushEnable) begin
        //     WB_Flush = 1'b1;
        // end
        // else begin
        WB_Flush = 1'b0;
        // end
    end

    // Dcache 停滞流水线时 wb级数据不能写入RF
    always_comb begin
        if (MEM_Flush_Exception == `FlushEnable)begin  // 异常和D$busy同时出现，不需要关闭RF的写使能
            WB_DisWr =  1'b0;
        end
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin
            WB_DisWr =  1'b1;
        end else begin
            WB_DisWr =  1'b0;
        end
    end

    // HILO的flush
    always_comb begin
        HiLo_Not_Flush =  (IsExceptionorEret == `IsNone) ? 1'b1:1'b0;
    end


        // PC_Wr = (ID_Flush_Exception)? 1: DH_PCWr & DIVMULTBusy;    //在load & R型的时候 以及乘除法的时候产生
        // ID_Wr = DH_IDWr & DIVMULTBusy;    //在load & R型的时候 以及乘除法的时候产生
        // EXE_Wr = ~EXE_MULTDIVStall;
        // MEM_Wr = 1;
        // WB_Wr = 1;
endmodule