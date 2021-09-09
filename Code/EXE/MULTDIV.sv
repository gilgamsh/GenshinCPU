/*
 * @Author: Seddon Shen
 * @Date: 2021-03-27 15:31:34
 * @LastEditTime: 2021-07-03 09:49:07
 * @LastEditors: Please set LastEditors
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \nontrival-cpu\Src\Code\EXE\MULTDIV.sv
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
    output logic [31:0]   EXE_MULTDIVtoLO,
    output logic [31:0]   EXE_MULTDIVtoHI,
    output logic          EXE_Finish,
    output logic          EXE_MULTDIVStall,
    output logic [1:0]    EXE_MultiExtendOp//MADD等指令的拓展信号，到HI LO
    // 01 ADD
    // 10 SUB

    // output logic          Finish,
    // output logic [64:0]   DivOut
    );
parameter T = 2'b00;  //空闲
parameter S = 2'b01;  //等待握手
parameter Q = 2'b10;  //等待结果
// div -->  dividend_tdata / divisor_tdata 
// 除号后面的叫做除数（divisor_tdata）
logic  [31:0]   divisor_tdata;      // 除数
logic  [31:0]   dividend_tdata;     // 被除数
logic  [32:0]   Result_A33;         
logic  [32:0]   Result_B33;
logic  [65:0]   Prod;
logic           multi_finish;   
logic           div_finish;   

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



always_ff @(posedge clk ) begin
    if (!rst) begin
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

always_comb begin
    unique case (EXE_ALUOp)
        `EXE_ALUOp_MULT,`EXE_ALUOp_MADD,`EXE_ALUOp_MSUB:begin
            //Sign
            Result_A33 = {EXE_ResultA[31],EXE_ResultA};
            Result_B33 = {EXE_ResultB[31],EXE_ResultB};
            Prod = $signed(Result_A33) * $signed(Result_B33);
            if(EXE_ALUOp ==  `EXE_ALUOp_MULT)begin
                EXE_MultiExtendOp = 2'b00;
            end
            else if(EXE_ALUOp == `EXE_ALUOp_MADD)begin
                EXE_MultiExtendOp = 2'b01;
            end
            else if (EXE_ALUOp == `EXE_ALUOp_MSUB) begin
                EXE_MultiExtendOp = 2'b10;
            end
            else begin
                EXE_MultiExtendOp = 'x;
            end
        end
        `EXE_ALUOp_MULTU,`EXE_ALUOp_MADDU,`EXE_ALUOp_MSUBU:begin
            //Unsign
            Result_A33 = {1'b0,EXE_ResultA};
            Result_B33 = {1'b0,EXE_ResultB};
            Prod = $signed(Result_A33) * $signed(Result_B33);
            if(EXE_ALUOp ==  `EXE_ALUOp_MULTU)begin
                EXE_MultiExtendOp = 2'b00;
            end
            else if(EXE_ALUOp == `EXE_ALUOp_MADDU)begin
                EXE_MultiExtendOp = 2'b01;
            end
            else if (EXE_ALUOp == `EXE_ALUOp_MSUB) begin
                EXE_MultiExtendOp = 2'b10;
            end
            else begin
                EXE_MultiExtendOp = 'x;
            end
            end
        default:begin
            Result_A33        = 'x;
            Result_B33        = 'x;
            Prod              = 'x;
            EXE_MultiExtendOp = 'x;
        end 
    endcase
    
end 

// 除法的状态机
always_ff @(posedge clk ) begin
        if (!rst) prestate <= T;
        else      prestate <= nextstate;
end
//除法状态机的状态转移
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
// 除法状态机的控制信号
always_comb begin
        if (ExceptionAssert == `InterruptAssert)  // 前面流水级有异常，需要清空状态机状态
            nextstate = T;
        else begin
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
// always_comb begin 
//     EXE_ExceptType_new = EXE_ExceptType;
//     EXE_ExceptType_new.Overflow = ((!EXE_ResultA[31] && !EXE_ResultB[31]) && (EXE_ALUOut_r[31]))||((EXE_ResultA[31] && EXE_ResultB[31]) && (!EXE_ALUOut_r[31]));
// end
    //assign EXE_ALUOut = EXE_ALUOut_r;
    //assign EXE_ALUOut = Prod[63:0];
    assign div_finish   = Signed_div_finish | Unsigned_div_finish;                                  //除法完成信号
    assign multi_finish = (EXE_ALUOp == `EXE_ALUOp_MULT || EXE_ALUOp == `EXE_ALUOp_MULTU) ? 1 : 0;  //乘法完成信号
    assign EXE_Finish   = multi_finish | div_finish;                                                //总完成信号

    assign EXE_MULTDIVtoLO = (multi_finish        ) ? Prod[31:0] : 
                             (Signed_div_finish   ) ? Signed_dout_tdata[63:32]  : 
                             (Unsigned_div_finish ) ? Unsigned_dout_tdata[63:32]: 31'bx;

    assign EXE_MULTDIVtoHI = (multi_finish        ) ? Prod[63:32] : 
                             (Signed_div_finish   ) ? Signed_dout_tdata[31:0]   : 
                             (Unsigned_div_finish ) ? Unsigned_dout_tdata[31:0] : 31'bx;
    //assign EXE_ALUOut = ;
    assign EXE_MULTDIVStall = ((EXE_ALUOp == `EXE_ALUOp_DIV || EXE_ALUOp == `EXE_ALUOp_DIVU) && div_finish == 1'b0) ? 1 : 0 ;
endmodule