/*
 * @Author: npuwth
 * @Date: 2021-06-30 22:17:38
 * @LastEditTime: 2021-07-06 16:31:47
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module TLBMMU (
    input logic                  clk,
    input logic [31:0]           Virt_Iaddr,
    input logic [31:0]           Virt_Daddr,
    input logic [1:0]            MEM_Type,  //表示是load还是store,0表示无，1表示load，2表示store
    input ExceptinPipeType       IF_ExceptType,
    input ExceptinPipeType       MEM_ExceptType,
    input logic                  MEM_IsTLBP,//表示是否是TLBP指令
    input logic                  MEM_IsTLBW,
    CP0_MMU_Interface            CMBus,
    output logic [31:0]          Phsy_Iaddr,
    output logic [31:0]          Phsy_Daddr,
    output ExceptinPipeType      IF_ExceptType_new,
    output ExceptinPipeType      MEM_ExceptType_new
);
    logic                        s0_found;
    logic [3:0]                  s0_index;
    logic [19:0]                 s0_pfn;
    logic [2:0]                  s0_c;
    logic                        s0_d;
    logic                        s0_v;     

    logic [18:0]                 s1_vpn2;    //访存和指令TLBP复用
    logic                        s1_found;
    logic [3:0]                  s1_index;
    logic [19:0]                 s1_pfn;
    logic [2:0]                  s1_c;
    logic                        s1_d;
    logic                        s1_v; 

    logic                        r_g;

    assign CMBus.MMU_g0          = r_g; //读出的g存入g0和g1
    assign CMBus.MMU_g1          = r_g;
    assign CMBus.MMU_s1found     = s1_found;

    tlb U_TLB ( 
        .clk                     (clk ),
        //search port 0
        .s0_vpn2                 (Virt_Iaddr[31:13] ),
        .s0_odd_page             (Virt_Iaddr[12] ),
        .s0_asid                 (CMBus.CP0_asid ),
        .s0_found                (s0_found ),
        .s0_index                (s0_index ),
        .s0_pfn                  (s0_pfn ),
        .s0_c                    (s0_c ),
        .s0_d                    (s0_d ),
        .s0_v                    (s0_v ),
        //search port 1
        .s1_vpn2                 (s1_vpn2 ),
        .s1_odd_page             (Virt_Daddr[12] ),
        .s1_asid                 (CMBus.CP0_asid ),
        .s1_found                (s1_found ),
        .s1_index                (s1_index ),
        .s1_pfn                  (s1_pfn ),
        .s1_c                    (s1_c ),
        .s1_d                    (s1_d ),
        .s1_v                    (s1_v ),
        //write port
        .we                      (MEM_IsTLBW ),
        .w_index                 (CMBus.CP0_index ),
        .w_vpn2                  (CMBus.CP0_vpn2 ),
        .w_asid                  (CMBus.CP0_asid ),
        .w_g                     (CMBus.CP0_g0 & CMBus.CP0_g1 ), //写入的g是g0和g1的与
        .w_pfn0                  (CMBus.CP0_pfn0 ),
        .w_c0                    (CMBus.CP0_c0 ),
        .w_d0                    (CMBus.CP0_d0 ),
        .w_v0                    (CMBus.CP0_v0 ),
        .w_pfn1                  (CMBus.CP0_pfn1 ),
        .w_c1                    (CMBus.CP0_c1 ),
        .w_d1                    (CMBus.CP0_d1 ),
        .w_v1                    (CMBus.CP0_v1 ),
        //read port
        .r_index                 (CMBus.CP0_index ),
        .r_vpn2                  (CMBus.MMU_vpn2 ),
        .r_asid                  (CMBus.MMU_asid ),
        .r_g                     (r_g ),
        .r_pfn0                  (CMBus.MMU_pfn0 ),
        .r_c0                    (CMBus.MMU_c0 ),
        .r_d0                    (CMBus.MMU_d0 ),
        .r_v0                    (CMBus.MMU_v0 ),
        .r_pfn1                  (CMBus.MMU_pfn1 ),
        .r_c1                    (CMBus.MMU_c1 ),
        .r_d1                    (CMBus.MMU_d1 ),
        .r_v1                    (CMBus.MMU_v1)
    );

    always_comb begin
        if(Virt_Iaddr < 32'hC000_0000 && Virt_Iaddr > 32'h9FFF_FFFF) begin
            Phsy_Iaddr        = Virt_Iaddr - 32'hA000_0000; 
        end
        else if(Virt_Iaddr < 32'hA000_0000 && Virt_Iaddr > 32'h7FFF_FFFF) begin
            Phsy_Iaddr        = Virt_Iaddr - 32'h8000_0000;
        end
        else begin
            Phsy_Iaddr        = {s0_pfn,Virt_Iaddr[11:0]};
        end
    end

    always_comb begin
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h9FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'hA000_0000;
        end
        else if(Virt_Daddr < 32'hA000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'h8000_0000;
        end
        else begin
            Phsy_Daddr        = {s1_pfn,Virt_Daddr[11:0]};
        end
    end

    MUX2to1#(19) U_MUX_s1vpn (
        .d0                   (Virt_Daddr[31:13]),
        .d1                   (CMBus.CP0_vpn2),
        .sel2_to_1            (MEM_IsTLBP),//
        .y                    (s1_vpn2)
    );//EXE级四选一B之后的那个二选一

    assign IF_ExceptType_new.Interrupt              = IF_ExceptType.Interrupt;
    assign IF_ExceptType_new.WrongAddressinIF       = IF_ExceptType.WrongAddressinIF;
    assign IF_ExceptType_new.ReservedInstruction    = IF_ExceptType.ReservedInstruction;
    assign IF_ExceptType_new.Syscall                = IF_ExceptType.Syscall;
    assign IF_ExceptType_new.Break                  = IF_ExceptType.Break;
    assign IF_ExceptType_new.Eret                   = IF_ExceptType.Eret;
    assign IF_ExceptType_new.WrWrongAddressinMEM    = IF_ExceptType.WrWrongAddressinMEM;
    assign IF_ExceptType_new.RdWrongAddressinMEM    = IF_ExceptType.RdWrongAddressinMEM;
    assign IF_ExceptType_new.Overflow               = IF_ExceptType.Overflow;
    assign IF_ExceptType_new.Refetch                = IF_ExceptType.Refetch;
    assign IF_ExceptType_new.Trap                   = IF_ExceptType.Trap;
    assign IF_ExceptType_new.TLBModified            = IF_ExceptType.TLBModified;

    always_comb begin
        if(s0_found == 1'b0 && (Virt_Iaddr > 32'hbfff_ffff || Virt_Iaddr < 32'h8000_0000)) begin
            IF_ExceptType_new.TLBRefill             = 1'b1;
            IF_ExceptType_new.TLBInvalid            = 1'b0;  
        end          
        else if(s0_found == 1'b1 && s0_v == 1'b0 && (Virt_Iaddr > 32'hbfff_ffff || Virt_Iaddr < 32'h8000_0000)) begin
            IF_ExceptType_new.TLBRefill             = 1'b0;
            IF_ExceptType_new.TLBInvalid            = 1'b1; 
        end
        else begin
            IF_ExceptType_new.TLBRefill             = 1'b0;
            IF_ExceptType_new.TLBInvalid            = 1'b0; 
        end
    end

    assign MEM_ExceptType_new.Interrupt              = MEM_ExceptType.Interrupt;
    assign MEM_ExceptType_new.WrongAddressinIF       = MEM_ExceptType.WrongAddressinIF;
    assign MEM_ExceptType_new.ReservedInstruction    = MEM_ExceptType.ReservedInstruction;
    assign MEM_ExceptType_new.Syscall                = MEM_ExceptType.Syscall;
    assign MEM_ExceptType_new.Break                  = MEM_ExceptType.Break;
    assign MEM_ExceptType_new.Eret                   = MEM_ExceptType.Eret;
    assign MEM_ExceptType_new.WrWrongAddressinMEM    = MEM_ExceptType.WrWrongAddressinMEM;
    assign MEM_ExceptType_new.RdWrongAddressinMEM    = MEM_ExceptType.RdWrongAddressinMEM;
    assign MEM_ExceptType_new.Overflow               = MEM_ExceptType.Overflow;
    assign MEM_ExceptType_new.Refetch                = MEM_ExceptType.Refetch;
    assign MEM_ExceptType_new.Trap                   = MEM_ExceptType.Trap;
    
    always_comb begin
        if(s1_found == 1'b0 && MEM_Type != 2'b0 && (Virt_Daddr > 32'hbfff_ffff || Virt_Daddr < 32'h8000_0000)) begin
            MEM_ExceptType_new.TLBRefill             = 1'b1;
            MEM_ExceptType_new.TLBInvalid            = 1'b0;
            MEM_ExceptType_new.TLBModified           = 1'b0;
        end
        else if(s1_found == 1'b1 && s1_v == 1'b0 && MEM_Type != 2'b0 && (Virt_Daddr > 32'hbfff_ffff || Virt_Daddr < 32'h8000_0000)) begin
            MEM_ExceptType_new.TLBRefill             = 1'b0;
            MEM_ExceptType_new.TLBInvalid            = 1'b1;
            MEM_ExceptType_new.TLBModified           = 1'b0;
        end
        else if(s1_found == 1'b1 && s1_v == 1'b1 && s1_d == 1'b0 && MEM_Type == 2'b10 && (Virt_Daddr > 32'hbfff_ffff || Virt_Daddr < 32'h8000_0000)) begin
            MEM_ExceptType_new.TLBRefill             = 1'b0;
            MEM_ExceptType_new.TLBInvalid            = 1'b0;
            MEM_ExceptType_new.TLBModified           = 1'b1;
        end
        else begin
            MEM_ExceptType_new.TLBRefill             = 1'b0;
            MEM_ExceptType_new.TLBInvalid            = 1'b0;
            MEM_ExceptType_new.TLBModified           = 1'b0;
        end
    end
endmodule