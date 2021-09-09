/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:25:55
 * @LastEditTime: 2021-06-30 20:07:16
 * @LastEditors: npuwth
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \Coded:\cpu\nontrival-cpu\nontrival-cpu\Src\Code\BranchSolve.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module BranchSolve (
    input BranchType      EXE_BranchType,
    input logic [31:0]    EXE_OutA,
    input logic [31:0]    EXE_OutB,
    output logic          ID_Flush,
    output logic          EXE_Flush
);

    always_comb begin
        unique case (EXE_BranchType.branchCode)
            `BRANCH_CODE_BEQ:
                if ($signed(EXE_OutA) == $signed(EXE_OutB) && EXE_BranchType.isBranch)  begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BNE:
                if ($signed(EXE_OutA) != $signed(EXE_OutB) && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BGE:
                if ($signed(EXE_OutA) >= 0 && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BGT:
                if ($signed(EXE_OutA) > 0 && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BLE:
                if ($signed(EXE_OutA) <= 0 && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BLT:
                if ($signed(EXE_OutA) < 0 && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_JR:
                if ( EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            default: begin
                ID_Flush = `FlushDisable;
             end
        endcase
    end

endmodule