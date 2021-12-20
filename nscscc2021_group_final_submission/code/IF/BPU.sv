/*
 * @Author: npuwth
 * @Date: 2021-07-22 19:50:26
 * @LastEditTime: 2021-08-15 11:45:25
 * @LastEditors: Please set LastEditors
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module BPU ( 
    input logic                clk,
    input logic                rst,
    input logic                IF_Wr,
    input logic                IF_Flush,
    input logic [31:0]         PREIF_PC,
    input BResult              EXE_BResult,//来自EXE，用于校准
    input logic                ID_IsBranch,
    output logic [31:0]        Target,
    output PResult             IF_PResult,
    output logic               BPU_Valid   //给PCSel，当发生flush后，BPU_Reg无效，从PC+4取指
);

    RAS_EntryType [`SIZE_OF_RAS-1:0]   RAS;
    logic                              RAS_Wr;
    RAS_EntryType                      RAS_Data;    //旁路后的数据
    logic [$clog2(`SIZE_OF_RAS)-1:0]   RAS_Top;     //point to stack top
    logic [$clog2(`SIZE_OF_RAS)-1:0]   RAS_TopSub1;

    assign RAS_TopSub1 = RAS_Top + 3'b111;
    
    BHT_Entry                          W_BHT_Entry; //BHT write data for correction
    BHT_Entry                          R_BHT_Entry; //BHT read data
    // logic [7:0]                        History;
    // logic [7:0]                        Index;
    logic [31:0]                       PREIF_PCAdd8;
    logic                              BHT_hit;
    assign PREIF_PCAdd8 = PREIF_PC + 8;
    // assign Index = History^PREIF_PC[`SIZE_OF_INDEX+1:2];

    BPU_RegType                        BPU_Reg;

    simple_port_ram_without_bypass #(
                .LATENCY(0),
                .SIZE(`SIZE_OF_SET),
                .dtype(BHT_Entry)
            )mem_data(
                .clk(clk),
                .rst(~rst),
                //write port
                .ena(1'b1),
                .wea(EXE_BResult.Valid),
                // .addra(EXE_BResult.Index),
                .addra(EXE_BResult.PC[`SIZE_OF_INDEX+1:2]),
                .dina(W_BHT_Entry),
                //read port
                .enb(1'b1), 
                // .addrb(Index),
                .addrb(PREIF_PC[`SIZE_OF_INDEX+1:2]),
                .doutb(R_BHT_Entry)
            );

//----------------------------对W_BHT_Entry进行赋值----------------------//
    assign W_BHT_Entry.Tag    = EXE_BResult.PC[31:`SIZE_OF_INDEX+2];
    assign W_BHT_Entry.Target = EXE_BResult.Target; 
    assign W_BHT_Entry.Type   = EXE_BResult.Type;
    // -----------------------对饱和计数器进行更新----------------------//
    always_comb begin
        if(EXE_BResult.Hit == 1'b1) begin
            unique case(EXE_BResult.Count)
            `T: begin
                if(EXE_BResult.IsTaken == 1'b1) W_BHT_Entry.Count = EXE_BResult.Count;
                else                            W_BHT_Entry.Count = EXE_BResult.Count - 1;
            end
            `NT: begin
                if(EXE_BResult.IsTaken == 1'b1) W_BHT_Entry.Count = EXE_BResult.Count + 1;
                else                            W_BHT_Entry.Count = EXE_BResult.Count;
            end
            default: begin
                if(EXE_BResult.IsTaken == 1'b1) W_BHT_Entry.Count = EXE_BResult.Count + 1;
                else                            W_BHT_Entry.Count = EXE_BResult.Count - 1;
            end
            endcase
        end
        else begin
            if(EXE_BResult.IsTaken == 1'b1)     W_BHT_Entry.Count = `WT;
            else                                W_BHT_Entry.Count = `WNT;
        end
    end
//----------------------------对BPU_Reg进行赋值---------------------------//
    always_ff @(posedge clk) begin
        if(rst == `RstEnable || IF_Flush == 1'b1) begin
            BPU_Reg.Tag                <= '0;
            BPU_Reg.PCTag              <= '0;
            BPU_Reg.BHT_Addr           <= '0;
            BPU_Reg.RAS_Entry          <= '0;
            BPU_Reg.PC_Add8            <= '0;
            BPU_Reg.Type               <= '0;
            BPU_Reg.Count              <= '0;
            BPU_Reg.Valid              <= '0;
            // BPU_Reg.Index              <= '0;
        end
        else if(IF_Wr == 1'b1 ) begin
            BPU_Reg.Tag                <= R_BHT_Entry.Tag;
            BPU_Reg.PCTag              <= PREIF_PC[31:`SIZE_OF_INDEX+2];
            BPU_Reg.BHT_Addr           <= R_BHT_Entry.Target;
            BPU_Reg.RAS_Entry          <= RAS_Data;
            // BPU_Reg.RAS_Addr           <= RAS_Data;
            // BPU_Reg.RAS_Addr           <= R_BHT_Entry.Target;
            BPU_Reg.PC_Add8            <= PREIF_PCAdd8;
            BPU_Reg.Type               <= R_BHT_Entry.Type;
            BPU_Reg.Count              <= R_BHT_Entry.Count;
            BPU_Reg.Valid              <= 1'b1;
            // BPU_Reg.Index              <= Index;
        end
    end  

    assign BPU_Valid = BPU_Reg.Valid&&(~ID_IsBranch); //全0说明flush掉了，告诉PCSel BPU无效，要选择PC+4
    assign BHT_hit = (BPU_Reg.Tag == BPU_Reg.PCTag);  //判断BHT是否命中
//----------------------------Target生成逻辑--------------------------------------------------//
    always_comb begin                 
        if(BHT_hit == 1'b0) begin
            Target = BPU_Reg.PC_Add8;
            IF_PResult.IsTaken = 1'b0;
        end
        else begin
            unique case(BPU_Reg.Type) 
            `BIsCall: begin
                Target = BPU_Reg.BHT_Addr;
                IF_PResult.IsTaken = 1'b1;
            end
            `BIsRetn: begin
                Target = (BPU_Reg.RAS_Entry.Valid)?(BPU_Reg.RAS_Entry.Addr):BPU_Reg.PC_Add8;
                IF_PResult.IsTaken = 1'b1;
            end
            `BIsBran: begin //根据饱和计数器判断
                if(BPU_Reg.Count[1] == 1'b1) begin
                Target = BPU_Reg.BHT_Addr;
                IF_PResult.IsTaken = 1'b1;
                end
                else begin
                Target = BPU_Reg.PC_Add8;
                IF_PResult.IsTaken = 1'b0;
                end
            end 
            `BIsJump: begin
                Target = BPU_Reg.BHT_Addr;
                IF_PResult.IsTaken = 1'b1;
            end
            default: begin
                Target = BPU_Reg.PC_Add8;
                IF_PResult.IsTaken = 1'b0;
            end
            endcase
        end
    end
//----------------------------给IF_PResult进行赋值----------------------------------------//
    assign IF_PResult.Type         = (BHT_hit==1'b1)?BPU_Reg.Type:`BIsNone;
    assign IF_PResult.Target       = Target;
    assign IF_PResult.Count        = BPU_Reg.Count;
    assign IF_PResult.Hit          = BHT_hit;
    assign IF_PResult.Valid        = BPU_Valid;
    // assign IF_PResult.Index        = BPU_Reg.Index;
//-----------------------------RAS------------------------------------------------------//
    //更新RAS与RAS_Top
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            RAS_Top <= '0;
            RAS     <= '0;
        end
        else if(EXE_BResult.Valid) begin
            unique case(EXE_BResult.Type)
            `BIsCall: begin
                RAS[RAS_Top].Valid     <= 1'b1;
                RAS[RAS_Top].Addr      <= EXE_BResult.PC + 8;
                RAS_Top                <= RAS_Top + 1;
            end
            `BIsRetn: begin
                RAS_Top                <= RAS_TopSub1;
            end
            default: begin
                ;
            end
            endcase
        end
    end
//--------------------------RAS的旁路------------------------------------------------------------//
    assign RAS_Wr = EXE_BResult.Valid && (EXE_BResult.Type == `BIsCall);

    always_comb begin
        if(RAS_Wr) begin
            RAS_Data.Valid = 1'b1;
            RAS_Data.Addr  = EXE_BResult.PC + 8;
        end
        else begin
            RAS_Data = RAS[RAS_TopSub1];
        end
    end
//---------------------------------History Branch Table-----------------------------------------//
    // always_ff @(posedge clk) begin
    //     if(rst == `RstEnable) begin
    //         History <= '0;
    //     end
    //     else if(EXE_BResult.Valid && EXE_BResult.Type == `BIsBran )begin
    //         History <= {History[6:0],EXE_BResult.IsTaken};
    //     end
    // end

endmodule
