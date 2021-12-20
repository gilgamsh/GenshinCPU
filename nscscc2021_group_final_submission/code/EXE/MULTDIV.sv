/*
 * @Author: Seddon Shen
 * @Date: 2021-03-27 15:31:34
 * @LastEditTime: 2021-08-14 00:25:39
 * @LastEditors: npuwth
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \undefinedd:\nontrival-cpu\Src\refactor\EXE\MULTDIV.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module MULTDIV(
    input logic           clk,    
    input logic           rst,             // 除法状态机的复位信号
    input logic  [4:0]    EXE_ALUOp,
    input logic  [31:0]   EXE_ResultA,
    input logic  [31:0]   EXE_ResultB,
    input logic           ExceptionAssert,
    input logic  [31:0]   EXE_Hi,
    input logic  [31:0]   EXE_Lo,
    //--------------------------output------------------------//
    output logic [31:0]   EXE_MULTDIVtoLO,
    output logic [31:0]   EXE_MULTDIVtoHI,
    // output logic          EXE_Finish,
    output logic          multi_finish,
    output logic          div_finish,
    output logic          EXE_MULTDIVStall
);

/////////////////////////////////////////////////////////////////////////////////////////////
//---------------------------------------------------除法-----------------------------------//
parameter T = 2'b00;  //空闲
parameter S = 2'b01;  //等待握手
parameter Q = 2'b10;  //等待结果
parameter W = 2'b11;  //结束
// div -->  dividend_tdata / divisor_tdata 
// 除号后面的叫做除数（divisor_tdata）
logic  [31:0]   divisor_tdata;      // 除数
logic  [31:0]   dividend_tdata;     // 被除数
// logic           div_finish;   
logic           Unsigned_divisor_tvalid;
logic           Unsigned_dividend_tvalid;
logic           Unsigned_divisor_tready;
logic           Unsigned_dividend_tready;
logic           Signed_divisor_tvalid;
logic           Signed_dividend_tvalid;
logic           Signed_divisor_tready;
logic           Signed_dividend_tready;
logic           Signed_div_finish;
logic           Unsigned_div_finish;
logic  [63:0]   Signed_dout_tdata;
logic  [63:0]   Unsigned_dout_tdata;
logic  [1:0]    nextstate;
logic  [1:0]    prestate; 
logic           EXE_DIVStall;
// 将除数，被除数锁存一拍
always_ff @(posedge clk ) begin
    if (rst == `RstEnable) begin
            dividend_tdata <= `ZeroWord;
            divisor_tdata  <= `ZeroWord;
    end
    else begin
        if (prestate == T && (EXE_ALUOp == `EXE_ALUOp_DIV || EXE_ALUOp == `EXE_ALUOp_DIVU) ) begin
            dividend_tdata <= EXE_ResultA;
            divisor_tdata  <= EXE_ResultB;
        end
    end
end
// 除法的状态机
always_ff @(posedge clk ) begin
    if (rst == `RstEnable || ExceptionAssert == 1'b1) begin
        prestate <= T;
    end 
    else begin
        prestate <= nextstate;
    end
end
// 除法状态机的控制信号
always_comb begin
    if (prestate == T) begin
        Signed_divisor_tvalid    = 1'b0;
        Signed_dividend_tvalid   = 1'b0;
        Unsigned_divisor_tvalid  = 1'b0;
        Unsigned_dividend_tvalid = 1'b0;
    end  
    else if (prestate == S) begin
       if (EXE_ALUOp == `EXE_ALUOp_DIV) begin
           Signed_divisor_tvalid    = 1'b1;
           Signed_dividend_tvalid   = 1'b1;
           Unsigned_divisor_tvalid  = 1'b0;
           Unsigned_dividend_tvalid = 1'b0;
           end 
       else if(EXE_ALUOp == `EXE_ALUOp_DIVU) begin
           Signed_divisor_tvalid    = 1'b0;
           Signed_dividend_tvalid   = 1'b0;
           Unsigned_divisor_tvalid  = 1'b1;
           Unsigned_dividend_tvalid = 1'b1;
           end
       else begin
           Signed_divisor_tvalid    = 1'b0;
           Signed_dividend_tvalid   = 1'b0;
           Unsigned_divisor_tvalid  = 1'b0;
           Unsigned_dividend_tvalid = 1'b0;
           end
       end
    else if (prestate == Q) begin
        Signed_divisor_tvalid      = 1'b0;
        Signed_dividend_tvalid     = 1'b0;
        Unsigned_divisor_tvalid    = 1'b0;
        Unsigned_dividend_tvalid   = 1'b0;
    end else begin
        Signed_divisor_tvalid      = 1'b0;
        Signed_dividend_tvalid     = 1'b0;
        Unsigned_divisor_tvalid    = 1'b0;
        Unsigned_dividend_tvalid   = 1'b0;
    end
    end
// 除法状态机的状态转移
always_comb begin
    case(prestate)
        T:begin
          if(EXE_ALUOp == `EXE_ALUOp_DIV || EXE_ALUOp == `EXE_ALUOp_DIVU)
            nextstate = S;
          else
            nextstate = T;
        end
        S:begin
          if(((Signed_dividend_tready == 1'b1 && Signed_divisor_tready == 1'b1) && EXE_ALUOp == `EXE_ALUOp_DIV ) ||
            ((Unsigned_dividend_tready == 1'b1 && Unsigned_divisor_tready == 1'b1) && EXE_ALUOp == `EXE_ALUOp_DIVU ))
            nextstate = Q;
          else
            nextstate = S;
        end
        Q:begin
          if(div_finish == 1'b1)
            nextstate = T;
          else
            nextstate = Q;
        end
        default:begin
            nextstate = T;
        end
    endcase
end

Signed_div U_SignedDIV (
    .aclk(clk),                                         // input wire clk
    .s_axis_divisor_tvalid (Signed_divisor_tvalid),      // input wire s_axis_divisor_tvalid
    .s_axis_divisor_tready (Signed_divisor_tready),      // output wire s_axis_divisor_tready
    .s_axis_divisor_tdata  (divisor_tdata),              // input wire [31 : 0] s_axis_divisor_tdata
    .s_axis_dividend_tvalid(Signed_dividend_tvalid),     // input wire s_axis_dividend_tvalid
    .s_axis_dividend_tready(Signed_dividend_tready),     // output wire s_axis_dividend_tready
    .s_axis_dividend_tdata (dividend_tdata),             // input wire [31 : 0] s_axis_dividend_tdata
    .m_axis_dout_tvalid    (Signed_div_finish),          // output wire m_axis_dout_tvalid
    .m_axis_dout_tdata     (Signed_dout_tdata)           // output wire [63 : 0] m_axis_dout_tdata
    );

Unsigned_div U_UnsignedDIV (
   .aclk(clk),                                          // input wire clk
   .s_axis_divisor_tvalid  (Unsigned_divisor_tvalid),    // input wire s_axis_divisor_tvalid
   .s_axis_divisor_tready  (Unsigned_divisor_tready),    // output wire s_axis_divisor_tready
   .s_axis_divisor_tdata   (divisor_tdata),              // input wire [31 : 0] s_axis_divisor_tdata
   .s_axis_dividend_tvalid (Unsigned_dividend_tvalid),   // input wire s_axis_dividend_tvalid
   .s_axis_dividend_tready (Unsigned_dividend_tready),   // output wire s_axis_dividend_tready
   .s_axis_dividend_tdata  (dividend_tdata),             // input wire [31 : 0] s_axis_dividend_tdata
   .m_axis_dout_tvalid     (Unsigned_div_finish),        // output wire m_axis_dout_tvalid
   .m_axis_dout_tdata      (Unsigned_dout_tdata)         // output wire [63 : 0] m_axis_dout_tdata
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------乘法--------------------------------------------------//
logic  [63:0]   Prod;//IP核输出
logic  [63:0]   mul_result;//乘法最终结果
// logic           multi_finish;   
logic  [1:0]    nextstate_mul;
logic  [1:0]    prestate_mul;                                                 
logic           EXE_MULTStall;
logic           ismulti;
logic           signflag;
logic           multi_save;
logic  [31:0]   MulHiSave;
logic  [31:0]   MulLoSave;
assign ismulti = (EXE_ALUOp == `EXE_ALUOp_MULT || EXE_ALUOp == `EXE_ALUOp_MULTU || EXE_ALUOp == `EXE_ALUOp_MADD || EXE_ALUOp == `EXE_ALUOp_MADDU || 
                EXE_ALUOp == `EXE_ALUOp_MSUB || EXE_ALUOp == `EXE_ALUOp_MSUBU || EXE_ALUOp == `EXE_ALUOp_MUL);
logic [31:0]    multiA;//乘数与被乘数
logic [31:0]    multiB;//乘数与被乘数
logic negative_result;
assign multiA = (signflag && EXE_ResultA[31]) ? -EXE_ResultA : EXE_ResultA;
assign multiB = (signflag && EXE_ResultB[31]) ? -EXE_ResultB : EXE_ResultB;
assign negative_result = signflag && (EXE_ResultA[31] ^ EXE_ResultB[31]);
assign mul_result = negative_result ? -Prod : Prod;
//乘法的有无符号生成逻辑
always_comb begin
    unique case (EXE_ALUOp)
        `EXE_ALUOp_MULT , `EXE_ALUOp_MADD , `EXE_ALUOp_MSUB , `EXE_ALUOp_MUL:begin
          signflag = 1'b1;
        end
        `EXE_ALUOp_MULTU , `EXE_ALUOp_MADDU , `EXE_ALUOp_MSUBU:begin
          signflag = 1'b0;
        end
        default: signflag = 1'b0;
    endcase
end 

UMult UMult(
    .CLK(clk),
    .A(multiA),
    .B(multiB),
    .P(Prod)
);

//乘法的状态机
always_ff @(posedge clk ) begin
    if (rst == `RstEnable || ExceptionAssert == 1'b1) begin
		prestate_mul <= T;
	end 
    else begin
		prestate_mul <= nextstate_mul;
	end    
end

logic [2:0] Count;//计数器

always_ff @(posedge clk ) begin
    if (prestate_mul == T && ismulti == 1'b1) begin
        Count <= 1;
    end
    else begin
        Count <= Count + 1;
    end
end

// 乘法状态机的状态转移
always_comb begin
    case(prestate_mul)
        T:begin
            if(ismulti) nextstate_mul = S;
            else        nextstate_mul = T;
        end
        S:begin
            if(Count == `MUL_Circle - 1) nextstate_mul = W;  // 暂存结果
            else                         nextstate_mul = S;
        end
        W:begin
            nextstate_mul = Q;  // 返回数据
        end
        Q:begin
            nextstate_mul = T;
        end
        default:begin
            nextstate_mul = T;
        end
    endcase
end

// 乘法状态机的控制信号
always_comb begin
        if (prestate_mul == Q) begin
            multi_finish = 1'b1;
        end
        else begin
            multi_finish = 1'b0;
        end
end
// 乘法状态机赞数数据
always_comb begin
    if (prestate_mul == W)begin
        multi_save = 1'b1;
    end
    else begin
        multi_save = 1'b0;
    end
end
always_ff @(posedge  clk ) begin
    if (multi_save)begin
        MulHiSave = mul_result[63:32];
        MulLoSave = mul_result[31:0];
    end
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//---------------------------------------------------乘法扩展----------------------------------------------------//
// logic [1:0]    EXE_MultiExtendOp;
logic [31:0]   Extend_MUL_Hi;
logic [31:0]   Extend_MUL_Lo;
//MADD MSUB指令支持
always_comb begin
    unique case (EXE_ALUOp)
        `EXE_ALUOp_MADD,`EXE_ALUOp_MADDU:begin
            {Extend_MUL_Hi,Extend_MUL_Lo} = {EXE_Hi,EXE_Lo} + {MulHiSave,MulLoSave};
        end
        `EXE_ALUOp_MSUB,`EXE_ALUOp_MSUBU:begin
            {Extend_MUL_Hi,Extend_MUL_Lo} = {EXE_Hi,EXE_Lo} - {MulHiSave,MulLoSave};
        end
        default:begin
            {Extend_MUL_Hi,Extend_MUL_Lo} = {MulHiSave,MulLoSave};
        end
    endcase
end 

assign div_finish   = Signed_div_finish | Unsigned_div_finish;        //除法完成信号
// assign EXE_Finish   = multi_finish | div_finish;                      //总完成信号

assign EXE_MULTDIVtoHI = (multi_finish        ) ? Extend_MUL_Hi             : 
                         (Signed_div_finish   ) ? Signed_dout_tdata[31:0]   : 
                         (Unsigned_div_finish ) ? Unsigned_dout_tdata[31:0] : 32'bx;

assign EXE_MULTDIVtoLO = (multi_finish        ) ? Extend_MUL_Lo             : 
                         (Signed_div_finish   ) ? Signed_dout_tdata[63:32]  : 
                         (Unsigned_div_finish ) ? Unsigned_dout_tdata[63:32]: 32'bx;
                             
assign EXE_DIVStall = ((EXE_ALUOp == `EXE_ALUOp_DIV || EXE_ALUOp == `EXE_ALUOp_DIVU) && div_finish == 1'b0) ? 1 : 0 ;
assign EXE_MULTStall= (ismulti&& multi_finish == 1'b0) ? 1 : 0;
assign EXE_MULTDIVStall = EXE_MULTStall || EXE_DIVStall;

endmodule