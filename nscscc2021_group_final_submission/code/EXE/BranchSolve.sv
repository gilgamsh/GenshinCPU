/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:25:55
 * @LastEditTime: 2021-08-14 23:48:17
 * @LastEditors: npuwth
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \Coded:\cpu\nontrival-cpu\nontrival-cpu\Src\Code\BranchSolve.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module BranchSolve (
    input BranchType      EXE_BranchType,
    input logic           EXE_IsAJumpCall,
    input logic [31:0]    EXE_OutA,
    input logic [31:0]    EXE_OutB,
    input logic [4:0]     EXE_rs,
    input logic [4:0]     EXE_rd,
    input logic [31:0]    EXE_PC,
    input logic           EXE_Wr,
    input PResult         EXE_PResult,    //随流水线流动的预测结果
    // input logic           EXE_Branch_Success,
    input logic           EXE_J_Success,
    input logic           EXE_PC8_Success,   
    input logic [31:0]    EXE_JumpAddr,
    input logic [31:0]    EXE_BranchAddr, 
    input logic [31:0]    EXE_PCAdd8,
    //---------------------output----------------------------------//
    output logic          EXE_Prediction_Failed,//表示预测失败
    output logic [31:0]   EXE_Correction_Vector,//用于校正的地址向量
    output BResult        EXE_BResult,          //用于校正BHT查找表的数据
    output logic          EXE_IsTaken,
    output logic          EXE_PF_FlushAll
);

    logic                 Branch_IsTaken; //实际是否应该跳转   （方向）
    logic [31:0]          Branch_Target;  //实际应该跳转的地址 （目标）
    logic [2:0]           Branch_Type;    //实际应该跳转的Type（种类）
    
    logic                 EXE_Branch_Success;
    logic                 Branch_Success;
    logic                 JR_Success;
    logic                 Prediction_Success;//表示预测成功
    //------------------用于Branch判断是否跳转---------------//
    logic                 equal,not_equal;
    logic                 not_equal_to_zero,equal_to_zero;
    logic                 greater_equal_to_zero;
    logic                 less_than_zero;

    assign EXE_IsTaken       = Branch_IsTaken;
    assign equal             = ~(|(EXE_OutA ^ EXE_OutB));
    assign not_equal         = |(EXE_OutA ^ EXE_OutB);
    assign not_equal_to_zero = |EXE_OutA;
    assign equal_to_zero     = ~(|EXE_OutA);
    assign greater_equal_to_zero = ~(EXE_OutA[31]);
    assign less_than_zero    = EXE_OutA[31];
//----------------------生成实际的跳转信号--------------------------------//
    always_comb begin
        if(EXE_BranchType.isBranch) begin
            unique case (EXE_BranchType.branchCode)
            `BRANCH_CODE_BEQ:
                Branch_IsTaken = equal;
            `BRANCH_CODE_BNE:
                Branch_IsTaken = not_equal;
            `BRANCH_CODE_BGE:
                Branch_IsTaken = greater_equal_to_zero;
            `BRANCH_CODE_BGT:
                Branch_IsTaken = greater_equal_to_zero & not_equal_to_zero;
            `BRANCH_CODE_BLE:
                Branch_IsTaken = equal_to_zero | less_than_zero;
            `BRANCH_CODE_BLT:
                Branch_IsTaken = less_than_zero;
            default: begin
                Branch_IsTaken = 1'b1; //J，JR型
             end
            endcase
        end
        else begin
            Branch_IsTaken = 1'b0;
        end
    end

    always_comb begin
        if(EXE_BranchType.isBranch) begin
            unique case (EXE_BranchType.branchCode)
            `BRANCH_CODE_J:begin
                if(EXE_IsAJumpCall) Branch_Type = `BIsCall;  //JAL
                else                Branch_Type = `BIsJump;  //J
                Branch_Target                   = EXE_JumpAddr;
            end 
            `BRANCH_CODE_JR:begin
                if(EXE_IsAJumpCall) begin
                    if(EXE_rd == 5'b11111)      Branch_Type = `BIsCall;  //JALR&&31
                    else if(EXE_rs == 5'b11111) Branch_Type = `BIsRetn;
                    else                        Branch_Type = `BIsJump;  //JALR
                end
                else begin
                    if(EXE_rs == 5'b11111)  Branch_Type = `BIsRetn; //JR&&31
                    else                    Branch_Type = `BIsJump; //JR
                end
                Branch_Target                   = EXE_OutA;
            end
            default: begin
                Branch_Type                       = `BIsBran;
                if(Branch_IsTaken)  Branch_Target = EXE_BranchAddr;
                else                Branch_Target = EXE_PCAdd8; 
            end               
            endcase
        end
        else begin
            Branch_Type   = `BIsNone;
            Branch_Target = EXE_PCAdd8;
        end                       
    end 
//------------------------对传回BPU的校正信息进行赋值-----------------------------//
    assign EXE_BResult.Type         = Branch_Type;
    assign EXE_BResult.IsTaken      = Branch_IsTaken;  
    assign EXE_BResult.Target       = Branch_Target;
    assign EXE_BResult.PC           = EXE_PC;
    assign EXE_BResult.Count        = EXE_PResult.Count;
    assign EXE_BResult.Hit          = EXE_PResult.Hit;
    assign EXE_BResult.Valid        = EXE_PResult.Valid && EXE_Wr && (Branch_Type != `BIsNone);
    // assign EXE_BResult.Index        = EXE_PResult.Index;
    // assign EXE_Correction_Vector    = Branch_Target;
    assign EXE_Correction_Vector    = (EXE_PF_FlushAll)?EXE_PC+4:Branch_Target;
    // assign EXE_BResult.RetnSuccess  = Prediction_Success;
//---------------------------判断预测是否成功---------------------------//
    assign Branch_Success    = (Branch_IsTaken)?EXE_Branch_Success:EXE_PC8_Success;
    assign JR_Success        = (EXE_PResult.Target == EXE_OutA);
    assign EXE_Branch_Success= (EXE_PResult.Target == EXE_BranchAddr);

    always_comb begin
        if(EXE_BranchType.isBranch) begin
            unique case (EXE_BranchType.branchCode)
            `BRANCH_CODE_J:begin
                Prediction_Success = EXE_J_Success;
            end 
            `BRANCH_CODE_JR:begin
                Prediction_Success = JR_Success;
            end
            default: begin
                Prediction_Success = Branch_Success;
            end               
            endcase
        end
        else begin
            Prediction_Success = EXE_PC8_Success;
        end                       
    end 

    assign EXE_Prediction_Failed = ~Prediction_Success && EXE_PResult.Valid; //阻塞的时候也可以发BranchFail，否则会有组合环

    assign EXE_PF_FlushAll = (EXE_PResult.Type != Branch_Type) && (Branch_Type == `BIsNone) && EXE_PResult.Valid;

endmodule
