/*
 * @Author: Seddon Shen
 * @Date: 2021-03-31 14:39:41
 * @LastEditTime: 2021-04-07 14:37:23
 * @LastEditors: Juan Jiang
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \undefinedd:\EXE\MUX.sv
 * 
 */
// mux2
module MUX2to1#(parameter WIDTH = 32)(d0,d1,sel2_to_1,y);
    input   logic   [WIDTH-1:0]       d0,d1;
    input   logic                     sel2_to_1;
    output  logic   [WIDTH-1:0]       y;
    logic           [WIDTH-1:0]       y_r;
    always_comb begin
        if (sel2_to_1 == 1'b1 ) y_r = d1;
        else if (sel2_to_1 == 1'b0) y_r = d0;
       
    end
    assign y=y_r;
endmodule

// mux3
module MUX3to1 #(
    parameter WIDTH=32
) (
    d0,d1,d2,sel3_to_1,y
);
    input   logic   [WIDTH-1:0]     d0,d1,d2;
    input   logic   [1:0]           sel3_to_1;
    output  logic   [WIDTH-1:0]     y;
    reg             [WIDTH-1:0]     y_r;
    always_comb begin
        unique case (sel3_to_1)
            2'b00:y_r=d0;
            2'b01:y_r=d1;
            2'b10:y_r=d2;
            default : 
            y_r={WIDTH{1'bx}};
        endcase 
    end
assign y=y_r;
endmodule



// mux4
module MUX4to1 #(
    parameter WIDTH=32
) (
    d0,d1,d2,d3,sel4_to_1,y
);
    input  logic    [WIDTH-1:0]     d0,d1,d2,d3;
    input  logic    [1:0]           sel4_to_1;
    output          [WIDTH-1:0]     y;
    logic           [WIDTH-1:0]     y_r;
    always_comb begin
        unique case (sel4_to_1)
            2'b00:y_r=d0;
            2'b01:y_r=d1;
            2'b10:y_r=d2;
            2'b11:y_r=d3;
            default : 
            y_r={WIDTH{1'bx}};
        endcase 
    end
assign y=y_r;
endmodule

// mux8
module MUX8to1 #(
    parameter WIDTH=32
) (
    d0,d1,d2,d3,d4,d5,d6,d7,sel8_to_1,y
);
    input  logic    [WIDTH-1:0]     d0,d1,d2,d3,d4,d5,d6,d7;
    input  logic    [2:0]           sel8_to_1;
    output          [WIDTH-1:0]     y;
    logic           [WIDTH-1:0]     y_r;
    always_comb begin
        unique case (sel8_to_1)
            3'b000:y_r=d0;
            3'b001:y_r=d1;
            3'b010:y_r=d2;
            3'b011:y_r=d3;
            3'b100:y_r=d4;
            3'b101:y_r=d5;
            3'b110:y_r=d6;
            3'b111:y_r=d7;
            default : 
            y_r={WIDTH{1'bx}};
        endcase 
    end
assign y=y_r;
endmodule
