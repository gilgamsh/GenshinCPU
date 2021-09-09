/*
 * @Author: npuwth
 * @Date: 2021-06-27 20:08:23
 * @LastEditTime: 2021-06-27 23:58:09
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

module tlb 
#(
    parameter TLBNUM = 16
)
(
    input  logic                       clk,
    //search port0
    input  logic  [18:0]               s0_vpn2,
    input  logic                       s0_odd_page,
    input  logic  [7:0]                s0_asid,
    output logic                       s0_found,
    output logic  [$clog2(TLBNUM)-1:0] s0_index,
    output logic  [19:0]               s0_pfn,
    output logic  [2:0]                s0_c,
    output logic                       s0_d,
    output logic                       s0_v,
    //search port1
    input  logic  [18:0]               s1_vpn2,
    input  logic                       s1_odd_page,
    input  logic  [7:0]                s1_asid,
    output logic                       s1_found,
    output logic  [$clog2(TLBNUM)-1:0] s1_index,
    output logic  [19:0]               s1_pfn,
    output logic  [2:0]                s1_c,
    output logic                       s1_d,
    output logic                       s1_v,
    //write port
    input  logic                       we,             //写使能
    input  logic  [$clog2(TLBNUM)-1:0] w_index,
    input  logic  [18:0]               w_vpn2,
    input  logic  [7:0]                w_asid,
    input  logic                       w_g,
    input  logic  [19:0]               w_pfn0,
    input  logic  [2:0]                w_c0,
    input  logic                       w_d0,
    input  logic                       w_v0,
    input  logic  [19:0]               w_pfn1,
    input  logic  [2:0]                w_c1,
    input  logic                       w_d1,
    input  logic                       w_v1,
    //read port
    input logic   [$clog2(TLBNUM)-1:0] r_index,
    output logic  [18:0]               r_vpn2,
    output logic  [7:0]                r_asid,
    output logic                       r_g,
    output logic  [19:0]               r_pfn0,
    output logic  [2:0]                r_c0,
    output logic                       r_d0,
    output logic                       r_v0,
    output logic  [19:0]               r_pfn1,
    output logic  [2:0]                r_c1,
    output logic                       r_d1,
    output logic                       r_v1
);
    
    logic [18:0]  tlb_vpn2             [TLBNUM-1:0];
    logic [7:0]   tlb_asid             [TLBNUM-1:0];
    logic         tlb_g                [TLBNUM-1:0];
    logic [19:0]  tlb_pfn0             [TLBNUM-1:0];
    logic [2:0]   tlb_c0               [TLBNUM-1:0];
    logic         tlb_d0               [TLBNUM-1:0];
    logic         tlb_v0               [TLBNUM-1:0];
    logic [19:0]  tlb_pfn1             [TLBNUM-1:0];
    logic [2:0]   tlb_c1               [TLBNUM-1:0];
    logic         tlb_d1               [TLBNUM-1:0];
    logic         tlb_v1               [TLBNUM-1:0];
    logic [TLBNUM-1:0]                 match0;
    logic [TLBNUM-1:0]                 match1;

    //write port
    always_ff @(posedge clk ) begin
        if(we) begin
            tlb_vpn2[w_index]          <= w_vpn2;
            tlb_asid[w_index]          <= w_asid;
            tlb_g[w_index]             <= w_g;
            tlb_pfn0[w_index]          <= w_pfn0;
            tlb_c0[w_index]            <= w_c0;
            tlb_d0[w_index]            <= w_d0;
            tlb_v0[w_index]            <= w_v0;
            tlb_pfn1[w_index]          <= w_pfn1;
            tlb_c1[w_index]            <= w_c1;
            tlb_d1[w_index]            <= w_d1;
            tlb_v1[w_index]            <= w_v1;
        end
    end
    //read port
    always_comb begin
        r_vpn2 =                   tlb_vpn2[r_index];
        r_asid =                   tlb_asid[r_index];
        r_g    =                   tlb_g[r_index];
        r_pfn0 =                   tlb_pfn0[r_index];
        r_c0   =                   tlb_c0[r_index];
        r_d0   =                   tlb_d0[r_index];
        r_v0   =                   tlb_v0[r_index];
        r_pfn1 =                   tlb_pfn1[r_index];
        r_c1   =                   tlb_c1[r_index];
        r_d1   =                   tlb_d1[r_index];
        r_v1   =                   tlb_v1[r_index];    
    end
    //search port1
    assign match0[ 0] = (s0_vpn2 == tlb_vpn2[ 0]) && ((s0_asid == tlb_asid[ 0]) || tlb_g[ 0]);
    assign match0[ 1] = (s0_vpn2 == tlb_vpn2[ 1]) && ((s0_asid == tlb_asid[ 1]) || tlb_g[ 1]);
    assign match0[ 2] = (s0_vpn2 == tlb_vpn2[ 2]) && ((s0_asid == tlb_asid[ 2]) || tlb_g[ 2]);
    assign match0[ 3] = (s0_vpn2 == tlb_vpn2[ 3]) && ((s0_asid == tlb_asid[ 3]) || tlb_g[ 3]);
    assign match0[ 4] = (s0_vpn2 == tlb_vpn2[ 4]) && ((s0_asid == tlb_asid[ 4]) || tlb_g[ 4]);
    assign match0[ 5] = (s0_vpn2 == tlb_vpn2[ 5]) && ((s0_asid == tlb_asid[ 5]) || tlb_g[ 5]);
    assign match0[ 6] = (s0_vpn2 == tlb_vpn2[ 6]) && ((s0_asid == tlb_asid[ 6]) || tlb_g[ 6]);
    assign match0[ 7] = (s0_vpn2 == tlb_vpn2[ 7]) && ((s0_asid == tlb_asid[ 7]) || tlb_g[ 7]);
    assign match0[ 8] = (s0_vpn2 == tlb_vpn2[ 8]) && ((s0_asid == tlb_asid[ 8]) || tlb_g[ 8]);
    assign match0[ 9] = (s0_vpn2 == tlb_vpn2[ 9]) && ((s0_asid == tlb_asid[ 9]) || tlb_g[ 9]);
    assign match0[10] = (s0_vpn2 == tlb_vpn2[10]) && ((s0_asid == tlb_asid[10]) || tlb_g[10]);
    assign match0[11] = (s0_vpn2 == tlb_vpn2[11]) && ((s0_asid == tlb_asid[11]) || tlb_g[11]);
    assign match0[12] = (s0_vpn2 == tlb_vpn2[12]) && ((s0_asid == tlb_asid[12]) || tlb_g[12]);
    assign match0[13] = (s0_vpn2 == tlb_vpn2[13]) && ((s0_asid == tlb_asid[13]) || tlb_g[13]);
    assign match0[14] = (s0_vpn2 == tlb_vpn2[14]) && ((s0_asid == tlb_asid[14]) || tlb_g[14]);
    assign match0[15] = (s0_vpn2 == tlb_vpn2[15]) && ((s0_asid == tlb_asid[15]) || tlb_g[15]);
    
    always_comb begin           //s0_found生成逻辑，port1是否hit
        if(match0 == 0)
            s0_found = 0;
        else
            s0_found = 1; 
    end

    always_comb begin
        if(s0_found == 0) begin//未命中
            s0_pfn   = 'x;
            s0_c     = 'x;
            s0_d     = 'x;
            s0_v     = 'x;
        end
        else begin             //根据oddpage，即地址第12位判断取 前半段 还是取 后半段
            if(s0_odd_page==0) begin
                s0_pfn = tlb_pfn0[s0_index];
                s0_c   = tlb_c0[s0_index];
                s0_d   = tlb_d0[s0_index];
                s0_v   = tlb_v0[s0_index];
            end
            else begin
                s0_pfn = tlb_pfn1[s0_index];
                s0_c   = tlb_c1[s0_index];
                s0_d   = tlb_d1[s0_index];
                s0_v   = tlb_v1[s0_index];
            end
        end
    end

    always_comb begin          //s0_index生成逻辑
        unique case(match0)
            16'b0000_0000_0000_0001:s0_index = 0;
            16'b0000_0000_0000_0010:s0_index = 1;
            16'b0000_0000_0000_0100:s0_index = 2;
            16'b0000_0000_0000_1000:s0_index = 3;
            16'b0000_0000_0001_0000:s0_index = 4;
            16'b0000_0000_0010_0000:s0_index = 5;
            16'b0000_0000_0100_0000:s0_index = 6;
            16'b0000_0000_1000_0000:s0_index = 7;
            16'b0000_0001_0000_0000:s0_index = 8;
            16'b0000_0010_0000_0000:s0_index = 9;
            16'b0000_0100_0000_0000:s0_index = 10;
            16'b0000_1000_0000_0000:s0_index = 11;
            16'b0001_0000_0000_0000:s0_index = 12;
            16'b0010_0000_0000_0000:s0_index = 13;
            16'b0100_0000_0000_0000:s0_index = 14;
            16'b1000_0000_0000_0000:s0_index = 15;
            default:s0_index = 'x;
        endcase
    end

    //search port2
    assign match1[ 0] = (s1_vpn2 == tlb_vpn2[ 0]) && ((s1_asid == tlb_asid[ 0]) || tlb_g[ 0]);
    assign match1[ 1] = (s1_vpn2 == tlb_vpn2[ 1]) && ((s1_asid == tlb_asid[ 1]) || tlb_g[ 1]);
    assign match1[ 2] = (s1_vpn2 == tlb_vpn2[ 2]) && ((s1_asid == tlb_asid[ 2]) || tlb_g[ 2]);
    assign match1[ 3] = (s1_vpn2 == tlb_vpn2[ 3]) && ((s1_asid == tlb_asid[ 3]) || tlb_g[ 3]);
    assign match1[ 4] = (s1_vpn2 == tlb_vpn2[ 4]) && ((s1_asid == tlb_asid[ 4]) || tlb_g[ 4]);
    assign match1[ 5] = (s1_vpn2 == tlb_vpn2[ 5]) && ((s1_asid == tlb_asid[ 5]) || tlb_g[ 5]);
    assign match1[ 6] = (s1_vpn2 == tlb_vpn2[ 6]) && ((s1_asid == tlb_asid[ 6]) || tlb_g[ 6]);
    assign match1[ 7] = (s1_vpn2 == tlb_vpn2[ 7]) && ((s1_asid == tlb_asid[ 7]) || tlb_g[ 7]);
    assign match1[ 8] = (s1_vpn2 == tlb_vpn2[ 8]) && ((s1_asid == tlb_asid[ 8]) || tlb_g[ 8]);
    assign match1[ 9] = (s1_vpn2 == tlb_vpn2[ 9]) && ((s1_asid == tlb_asid[ 9]) || tlb_g[ 9]);
    assign match1[10] = (s1_vpn2 == tlb_vpn2[10]) && ((s1_asid == tlb_asid[10]) || tlb_g[10]);
    assign match1[11] = (s1_vpn2 == tlb_vpn2[11]) && ((s1_asid == tlb_asid[11]) || tlb_g[11]);
    assign match1[12] = (s1_vpn2 == tlb_vpn2[12]) && ((s1_asid == tlb_asid[12]) || tlb_g[12]);
    assign match1[13] = (s1_vpn2 == tlb_vpn2[13]) && ((s1_asid == tlb_asid[13]) || tlb_g[13]);
    assign match1[14] = (s1_vpn2 == tlb_vpn2[14]) && ((s1_asid == tlb_asid[14]) || tlb_g[14]);
    assign match1[15] = (s1_vpn2 == tlb_vpn2[15]) && ((s1_asid == tlb_asid[15]) || tlb_g[15]);    
    
    always_comb begin           //s0_found生成逻辑，port1是否hit
        if(match1 == 0)
            s1_found = 0;
        else
            s1_found = 1; 
    end

    always_comb begin
        if(s1_found == 0) begin//未命中
            s1_pfn   = 'x;
            s1_c     = 'x;
            s1_d     = 'x;
            s1_v     = 'x;
        end
        else begin             //根据oddpage，即地址第12位判断取 前半段 还是取 后半段
            if(s1_odd_page==0) begin
                s1_pfn = tlb_pfn0[s1_index];
                s1_c   = tlb_c0[s1_index];
                s1_d   = tlb_d0[s1_index];
                s1_v   = tlb_v0[s1_index];
            end
            else begin
                s1_pfn = tlb_pfn1[s1_index];
                s1_c   = tlb_c1[s1_index];
                s1_d   = tlb_d1[s1_index];
                s1_v   = tlb_v1[s1_index];
            end
        end
    end

    always_comb begin          //s1_index生成逻辑
        unique case(match1)
            16'b0000_0000_0000_0001:s1_index = 0;
            16'b0000_0000_0000_0010:s1_index = 1;
            16'b0000_0000_0000_0100:s1_index = 2;
            16'b0000_0000_0000_1000:s1_index = 3;
            16'b0000_0000_0001_0000:s1_index = 4;
            16'b0000_0000_0010_0000:s1_index = 5;
            16'b0000_0000_0100_0000:s1_index = 6;
            16'b0000_0000_1000_0000:s1_index = 7;
            16'b0000_0001_0000_0000:s1_index = 8;
            16'b0000_0010_0000_0000:s1_index = 9;
            16'b0000_0100_0000_0000:s1_index = 10;
            16'b0000_1000_0000_0000:s1_index = 11;
            16'b0001_0000_0000_0000:s1_index = 12;
            16'b0010_0000_0000_0000:s1_index = 13;
            16'b0100_0000_0000_0000:s1_index = 14;
            16'b1000_0000_0000_0000:s1_index = 15;
            default:s1_index = 'x;
        endcase
    end

endmodule
