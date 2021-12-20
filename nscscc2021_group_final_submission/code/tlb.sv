/*
 * @Author: npuwth
 * @Date: 2021-06-27 20:08:23
 * @LastEditTime: 2021-08-15 10:39:18
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module TLB
#(
    parameter TLBNUM = 8//16
)
(
    input  logic                       clk,
    input  logic                       rst,
    input  logic  [31:13]              I_VPN2,         //来自ITLB Buffer
    input  logic  [31:13]              D_VPN2,         //来自DTLB Buffer
    input  logic                       MEM_IsTLBP,
    input  logic                       MEM_IsTLBW, 
    input  logic                       MEM_TLBWIorR,
    CP0_TLB_Interface                  CTBus,
    output logic                       s0_found,       //输出给ITLB Buffer
    output TLB_Entry                   I_TLBEntry,     //输出给ITLB Buffer
    output logic                       s1_found,       //输出给DTLB Buffer
    output TLB_Entry                   D_TLBEntry      //输出给DTLB Buffer
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

    logic [2:0]                        w_index;
    logic [31:13]                      s1_vpn2;
    logic [2:0]                        s0_index;
    logic [2:0]                        s1_index;
//--------------------------------w_index生成逻辑-----------------------------------------//
    MUX2to1#(3) U_MUX_windex ( 
        .d0                   (CTBus.CP0_index),
        .d1                   (CTBus.CP0_random),
        .sel2_to_1            (MEM_TLBWIorR),
        .y                    (w_index)
    );
//--------------------------------复用访存实现TLBP----------------------------------------//
    MUX2to1#(19) U_MUX_s1vpn (
        .d0                   (D_VPN2),
        .d1                   (CTBus.CP0_vpn2),
        .sel2_to_1            (MEM_IsTLBP),//
        .y                    (s1_vpn2)
    );
//----------------------------------write port-------------------------------------------//
`ifdef  EN_TLBRST //开启TLB复位
    genvar i;
    generate
    	for(i = 0; i < TLBNUM; ++i)
    	begin: gen_for_tlb
    		always_ff @(posedge clk) begin
    			if(rst == `RstEnable) begin
    				tlb_vpn2[i] <= '0;
                    tlb_asid[i] <= '0;
                    tlb_g[i]    <= '0; 
                    tlb_pfn0[i] <= '0;
                    tlb_c0[i]   <= '0;
                    tlb_d0[i]   <= '0;
                    tlb_v0[i]   <= '0;
                    tlb_pfn1[i] <= '0;
                    tlb_c1[i]   <= '0;
                    tlb_d1[i]   <= '0;
                    tlb_v1[i]   <= '0;
    			end else begin
    				if( MEM_IsTLBW && i == w_index) begin
    				tlb_vpn2[i] <= CTBus.CP0_vpn2;
                    tlb_asid[i] <= CTBus.CP0_asid;
                    tlb_g[i]    <= CTBus.CP0_g0 & CTBus.CP0_g1;
                    tlb_pfn0[i] <= CTBus.CP0_pfn0;
                    tlb_c0[i]   <= CTBus.CP0_c0;
                    tlb_d0[i]   <= CTBus.CP0_d0;
                    tlb_v0[i]   <= CTBus.CP0_v0;
                    tlb_pfn1[i] <= CTBus.CP0_pfn1;
                    tlb_c1[i]   <= CTBus.CP0_c1;
                    tlb_d1[i]   <= CTBus.CP0_d1;
                    tlb_v1[i]   <= CTBus.CP0_v1;
                    end
    			end
    		end
    	end
    endgenerate
`endif
`ifndef EN_TLBRST //不开启TLB复位
    always_ff @(posedge clk ) begin
            if(MEM_IsTLBW) begin
                    tlb_vpn2[w_index] <= CTBus.CP0_vpn2;
                    tlb_asid[w_index] <= CTBus.CP0_asid;
                    tlb_g[w_index]    <= CTBus.CP0_g0 & CTBus.CP0_g1;
                    tlb_pfn0[w_index] <= CTBus.CP0_pfn0;
                    tlb_c0[w_index]   <= CTBus.CP0_c0;
                    tlb_d0[w_index]   <= CTBus.CP0_d0;
                    tlb_v0[w_index]   <= CTBus.CP0_v0;
                    tlb_pfn1[w_index] <= CTBus.CP0_pfn1;
                    tlb_c1[w_index]   <= CTBus.CP0_c1;
                    tlb_d1[w_index]   <= CTBus.CP0_d1;
                    tlb_v1[w_index]   <= CTBus.CP0_v1;
            end
        end
`endif 
//---------------------------------read port-------------------------------------------------------//
    always_comb begin
        CTBus.TLB_vpn2 = tlb_vpn2[CTBus.CP0_index];
        CTBus.TLB_asid = tlb_asid[CTBus.CP0_index];
        CTBus.TLB_pfn0 = tlb_pfn0[CTBus.CP0_index];
        CTBus.TLB_c0   = tlb_c0[CTBus.CP0_index];
        CTBus.TLB_d0   = tlb_d0[CTBus.CP0_index];
        CTBus.TLB_v0   = tlb_v0[CTBus.CP0_index];
        CTBus.TLB_g0   = tlb_g[CTBus.CP0_index];
        CTBus.TLB_pfn1 = tlb_pfn1[CTBus.CP0_index];
        CTBus.TLB_c1   = tlb_c1[CTBus.CP0_index];
        CTBus.TLB_d1   = tlb_d1[CTBus.CP0_index];
        CTBus.TLB_v1   = tlb_v1[CTBus.CP0_index];    
        CTBus.TLB_g1   = tlb_g[CTBus.CP0_index];
    end
//----------------------------------search port1-------------------------------------------------------//
    assign match0[ 0] = (I_VPN2 == tlb_vpn2[ 0]) && ((CTBus.CP0_asid == tlb_asid[ 0]) || tlb_g[ 0]);
    assign match0[ 1] = (I_VPN2 == tlb_vpn2[ 1]) && ((CTBus.CP0_asid == tlb_asid[ 1]) || tlb_g[ 1]);
    assign match0[ 2] = (I_VPN2 == tlb_vpn2[ 2]) && ((CTBus.CP0_asid == tlb_asid[ 2]) || tlb_g[ 2]);
    assign match0[ 3] = (I_VPN2 == tlb_vpn2[ 3]) && ((CTBus.CP0_asid == tlb_asid[ 3]) || tlb_g[ 3]);
    assign match0[ 4] = (I_VPN2 == tlb_vpn2[ 4]) && ((CTBus.CP0_asid == tlb_asid[ 4]) || tlb_g[ 4]);
    assign match0[ 5] = (I_VPN2 == tlb_vpn2[ 5]) && ((CTBus.CP0_asid == tlb_asid[ 5]) || tlb_g[ 5]);
    assign match0[ 6] = (I_VPN2 == tlb_vpn2[ 6]) && ((CTBus.CP0_asid == tlb_asid[ 6]) || tlb_g[ 6]);
    assign match0[ 7] = (I_VPN2 == tlb_vpn2[ 7]) && ((CTBus.CP0_asid == tlb_asid[ 7]) || tlb_g[ 7]);
    // assign match0[ 8] = (I_VPN2 == tlb_vpn2[ 8]) && ((CTBus.CP0_asid == tlb_asid[ 8]) || tlb_g[ 8]);
    // assign match0[ 9] = (I_VPN2 == tlb_vpn2[ 9]) && ((CTBus.CP0_asid == tlb_asid[ 9]) || tlb_g[ 9]);
    // assign match0[10] = (I_VPN2 == tlb_vpn2[10]) && ((CTBus.CP0_asid == tlb_asid[10]) || tlb_g[10]);
    // assign match0[11] = (I_VPN2 == tlb_vpn2[11]) && ((CTBus.CP0_asid == tlb_asid[11]) || tlb_g[11]);
    // assign match0[12] = (I_VPN2 == tlb_vpn2[12]) && ((CTBus.CP0_asid == tlb_asid[12]) || tlb_g[12]);
    // assign match0[13] = (I_VPN2 == tlb_vpn2[13]) && ((CTBus.CP0_asid == tlb_asid[13]) || tlb_g[13]);
    // assign match0[14] = (I_VPN2 == tlb_vpn2[14]) && ((CTBus.CP0_asid == tlb_asid[14]) || tlb_g[14]);
    // assign match0[15] = (I_VPN2 == tlb_vpn2[15]) && ((CTBus.CP0_asid == tlb_asid[15]) || tlb_g[15]);
    //--------------------s0_found生成逻辑，port0是否hit--------------------------------------------------// 
    always_comb begin          
        if(match0 == 0)
            s0_found = 0;
        else
            s0_found = 1; 
    end
    //--------------------s0查询结果数据生成逻辑-----------------------------------------------------------//
    assign I_TLBEntry.VPN2         = tlb_vpn2 [s0_index];
    assign I_TLBEntry.ASID         = tlb_asid [s0_index];
    assign I_TLBEntry.G            = tlb_g    [s0_index];
    assign I_TLBEntry.PFN0         = tlb_pfn0 [s0_index];
    assign I_TLBEntry.C0           = tlb_c0   [s0_index];
    assign I_TLBEntry.D0           = tlb_d0   [s0_index];    
    assign I_TLBEntry.V0           = tlb_v0   [s0_index];
    assign I_TLBEntry.PFN1         = tlb_pfn1 [s0_index];
    assign I_TLBEntry.C1           = tlb_c1   [s0_index];
    assign I_TLBEntry.D1           = tlb_d1   [s0_index];
    assign I_TLBEntry.V1           = tlb_v1   [s0_index];
    //-----------------------s0_index生成逻辑------------------------------------------------------------//
    always_comb begin          
        unique case(match0)
            8'b0000_0001:s0_index = 3'd0;
            8'b0000_0010:s0_index = 3'd1;
            8'b0000_0100:s0_index = 3'd2;
            8'b0000_1000:s0_index = 3'd3;
            8'b0001_0000:s0_index = 3'd4;
            8'b0010_0000:s0_index = 3'd5;
            8'b0100_0000:s0_index = 3'd6;
            8'b1000_0000:s0_index = 3'd7;
            // 16'b0000_0000_0000_0001:s0_index = 4'd0;
            // 16'b0000_0000_0000_0010:s0_index = 4'd1;
            // 16'b0000_0000_0000_0100:s0_index = 4'd2;
            // 16'b0000_0000_0000_1000:s0_index = 4'd3;
            // 16'b0000_0000_0001_0000:s0_index = 4'd4;
            // 16'b0000_0000_0010_0000:s0_index = 4'd5;
            // 16'b0000_0000_0100_0000:s0_index = 4'd6;
            // 16'b0000_0000_1000_0000:s0_index = 4'd7;
            // 16'b0000_0001_0000_0000:s0_index = 4'd8;
            // 16'b0000_0010_0000_0000:s0_index = 4'd9;
            // 16'b0000_0100_0000_0000:s0_index = 4'd10;
            // 16'b0000_1000_0000_0000:s0_index = 4'd11;
            // 16'b0001_0000_0000_0000:s0_index = 4'd12;
            // 16'b0010_0000_0000_0000:s0_index = 4'd13;
            // 16'b0100_0000_0000_0000:s0_index = 4'd14;
            // 16'b1000_0000_0000_0000:s0_index = 4'd15; 
            default:s0_index = '0;
        endcase
    end

//-----------------------------------search port2------------------------------------------------------//
    assign match1[ 0] = (s1_vpn2 == tlb_vpn2[ 0]) && ((CTBus.CP0_asid == tlb_asid[ 0]) || tlb_g[ 0]);
    assign match1[ 1] = (s1_vpn2 == tlb_vpn2[ 1]) && ((CTBus.CP0_asid == tlb_asid[ 1]) || tlb_g[ 1]);
    assign match1[ 2] = (s1_vpn2 == tlb_vpn2[ 2]) && ((CTBus.CP0_asid == tlb_asid[ 2]) || tlb_g[ 2]);
    assign match1[ 3] = (s1_vpn2 == tlb_vpn2[ 3]) && ((CTBus.CP0_asid == tlb_asid[ 3]) || tlb_g[ 3]);
    assign match1[ 4] = (s1_vpn2 == tlb_vpn2[ 4]) && ((CTBus.CP0_asid == tlb_asid[ 4]) || tlb_g[ 4]);
    assign match1[ 5] = (s1_vpn2 == tlb_vpn2[ 5]) && ((CTBus.CP0_asid == tlb_asid[ 5]) || tlb_g[ 5]);
    assign match1[ 6] = (s1_vpn2 == tlb_vpn2[ 6]) && ((CTBus.CP0_asid == tlb_asid[ 6]) || tlb_g[ 6]);
    assign match1[ 7] = (s1_vpn2 == tlb_vpn2[ 7]) && ((CTBus.CP0_asid == tlb_asid[ 7]) || tlb_g[ 7]);
    // assign match1[ 8] = (s1_vpn2 == tlb_vpn2[ 8]) && ((CTBus.CP0_asid == tlb_asid[ 8]) || tlb_g[ 8]);
    // assign match1[ 9] = (s1_vpn2 == tlb_vpn2[ 9]) && ((CTBus.CP0_asid == tlb_asid[ 9]) || tlb_g[ 9]);
    // assign match1[10] = (s1_vpn2 == tlb_vpn2[10]) && ((CTBus.CP0_asid == tlb_asid[10]) || tlb_g[10]);
    // assign match1[11] = (s1_vpn2 == tlb_vpn2[11]) && ((CTBus.CP0_asid == tlb_asid[11]) || tlb_g[11]);
    // assign match1[12] = (s1_vpn2 == tlb_vpn2[12]) && ((CTBus.CP0_asid == tlb_asid[12]) || tlb_g[12]);
    // assign match1[13] = (s1_vpn2 == tlb_vpn2[13]) && ((CTBus.CP0_asid == tlb_asid[13]) || tlb_g[13]);
    // assign match1[14] = (s1_vpn2 == tlb_vpn2[14]) && ((CTBus.CP0_asid == tlb_asid[14]) || tlb_g[14]);
    // assign match1[15] = (s1_vpn2 == tlb_vpn2[15]) && ((CTBus.CP0_asid == tlb_asid[15]) || tlb_g[15]);     
    //--------------------s1_found生成逻辑，port1是否hit--------------------------------------------------//    
    always_comb begin           
        if(match1 == 0)
            s1_found = 0;
        else
            s1_found = 1; 
    end
    //--------------------s1查询结果数据生成逻辑-----------------------------------------------------------//
    assign D_TLBEntry.VPN2         = tlb_vpn2 [s1_index];
    assign D_TLBEntry.ASID         = tlb_asid [s1_index];
    assign D_TLBEntry.G            = tlb_g    [s1_index];
    assign D_TLBEntry.PFN0         = tlb_pfn0 [s1_index];
    assign D_TLBEntry.C0           = tlb_c0   [s1_index];
    assign D_TLBEntry.D0           = tlb_d0   [s1_index];    
    assign D_TLBEntry.V0           = tlb_v0   [s1_index];
    assign D_TLBEntry.PFN1         = tlb_pfn1 [s1_index];
    assign D_TLBEntry.C1           = tlb_c1   [s1_index];
    assign D_TLBEntry.D1           = tlb_d1   [s1_index];
    assign D_TLBEntry.V1           = tlb_v1   [s1_index];

    assign CTBus.TLB_index         = s1_index;
    assign CTBus.TLB_s1found       = s1_found;
    //------------------------s1_index生成逻辑-----------------------------------------------------------//
    always_comb begin          
        unique case(match1)
            8'b0000_0001:s1_index = 3'd0;
            8'b0000_0010:s1_index = 3'd1;
            8'b0000_0100:s1_index = 3'd2;
            8'b0000_1000:s1_index = 3'd3;
            8'b0001_0000:s1_index = 3'd4;
            8'b0010_0000:s1_index = 3'd5;
            8'b0100_0000:s1_index = 3'd6;
            8'b1000_0000:s1_index = 3'd7;
            // 16'b0000_0000_0000_0001:s1_index = 4'd0;
            // 16'b0000_0000_0000_0010:s1_index = 4'd1;
            // 16'b0000_0000_0000_0100:s1_index = 4'd2;
            // 16'b0000_0000_0000_1000:s1_index = 4'd3;
            // 16'b0000_0000_0001_0000:s1_index = 4'd4;
            // 16'b0000_0000_0010_0000:s1_index = 4'd5;
            // 16'b0000_0000_0100_0000:s1_index = 4'd6;
            // 16'b0000_0000_1000_0000:s1_index = 4'd7;
            // 16'b0000_0001_0000_0000:s1_index = 4'd8;
            // 16'b0000_0010_0000_0000:s1_index = 4'd9;
            // 16'b0000_0100_0000_0000:s1_index = 4'd10;
            // 16'b0000_1000_0000_0000:s1_index = 4'd11;
            // 16'b0001_0000_0000_0000:s1_index = 4'd12;
            // 16'b0010_0000_0000_0000:s1_index = 4'd13;
            // 16'b0100_0000_0000_0000:s1_index = 4'd14;
            // 16'b1000_0000_0000_0000:s1_index = 4'd15;
            default:s1_index = '0;
        endcase
    end
//----------------------------------------------------------------------------------------------------------//
endmodule
