/*
 * @Author: Seddon Shen
 * @Date: 2021-03-31 14:39:41
 * @LastEditTime: 2021-08-01 10:14:22
 * @LastEditors: npuwth
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
        else                    y_r = d0;
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

// mux7
module MUX7to1 #(
    parameter WIDTH=32
) (
    d0,d1,d2,d3,d4,d5,d6,sel7_to_1,y
);
    input  logic    [WIDTH-1:0]     d0,d1,d2,d3,d4,d5,d6;
    input  logic    [2:0]           sel7_to_1;
    output          [WIDTH-1:0]     y;
    logic           [WIDTH-1:0]     y_r;
    always_comb begin
        unique case (sel7_to_1)
            3'b000:y_r=d0;
            3'b001:y_r=d1;
            3'b010:y_r=d2;
            3'b011:y_r=d3;
            3'b100:y_r=d4;
            3'b101:y_r=d5;
            3'b110:y_r=d6;
            default : 
            y_r='x;
        endcase 
    end
assign y=y_r;
endmodule

// mux5
module MUX5to1 #(
    parameter WIDTH=32
) (
    d0,d1,d2,d3,d4,sel5_to_1,y
);
    input  logic    [WIDTH-1:0]     d0,d1,d2,d3,d4;
    input  logic    [2:0]           sel5_to_1;
    output          [WIDTH-1:0]     y;
    logic           [WIDTH-1:0]     y_r;
    always_comb begin
        unique case (sel5_to_1)
            3'b000:y_r=d0;
            3'b001:y_r=d1;
            3'b010:y_r=d2;
            3'b011:y_r=d3;
            3'b100:y_r=d4;
            default : 
            y_r='x;
        endcase 
    end
assign y=y_r;
endmodule

module MUX6to1 #(
    parameter WIDTH=32
) (
    d0,d1,d2,d3,d4,d5,sel6_to_1,y
);
    input  logic    [WIDTH-1:0]     d0,d1,d2,d3,d4,d5;
    input  logic    [2:0]           sel6_to_1;
    output          [WIDTH-1:0]     y;
    logic           [WIDTH-1:0]     y_r;
    always_comb begin
        unique case (sel6_to_1)
            3'b000:y_r=d0;
            3'b001:y_r=d1;
            3'b010:y_r=d2;
            3'b011:y_r=d3;
            3'b100:y_r=d4;
            3'b101:y_r=d5;
            default : 
            y_r='x;
        endcase 
    end
assign y=y_r;
endmodule