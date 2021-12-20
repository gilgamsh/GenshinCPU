
`include "../CPU_Defines.svh"

module RF (
    input logic clk,
    input logic rst,

    input logic [4:0] WB_Dst,
    input logic [31:0] WB_Result,
    input logic RFWr,// to write the RF

    input logic [4:0] ID_rs,
    input logic [4:0] ID_rt,
    output logic [31:0] ID_BusA,
    output logic [31:0] ID_BusB//to read the RF
);

logic [31:0][31:0] regs;



always_ff @(posedge clk) begin// write the RF
    if (rst == `RstEnable) begin
        regs <= '0;
    end
    else begin
        if (RFWr==1'b1 && WB_Dst != 5'b0) begin
            regs[WB_Dst] <= WB_Result;
        end
        // `ifdef DEBUG
        //     $display("Registers File:");
        //     $display("R[00-07]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X",regs[0], regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7]);
        //     $display("R[08-15]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", regs[8], regs[9], regs[10], regs[11], regs[12], regs[13], regs[14], regs[15]);
        //     $display("R[16-23]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", regs[16], regs[17], regs[18], regs[19], regs[20], regs[21], regs[22], regs[23]);
        //     $display("R[24-31]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", regs[24], regs[25], regs[26], regs[27], regs[28], regs[29], regs[30], regs[31]);
        // `endif
    end
end



always_comb begin // readData

    if (RFWr && WB_Dst == ID_rs) begin
        ID_BusA = WB_Result;
    end else begin
        ID_BusA = regs[ID_rs];
    end
end
    

always_comb begin // readData

    if (RFWr && WB_Dst == ID_rt) begin
        ID_BusB = WB_Result;
    end else begin
        ID_BusB = regs[ID_rt];
    end
end
endmodule

