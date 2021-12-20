/*
 * @Author: your name
 * @Date: 2021-08-08 11:23:21
 * @LastEditTime: 2021-08-13 20:08:20
 * @LastEditors: npuwth
 * @Description: In User Settings Edit
 * @FilePath: \gitlab\Src\refactor\Utils\Victim_Cache.sv
 */ 
module Victim_Cache #(
    parameter SIZE = 4,
    parameter INDEX_WIDTH = 6,
    parameter TAG_WIDTH  = 20,
    parameter ASSOC_NUM = 2,
    parameter LINE_WORD_NUM = 16
) (
    input logic clk,
    input logic resetn,
    input logic[INDEX_WIDTH-1:0] index,         //用于索引
    input logic data_read_en,
    input logic we,                             //用于替换时的写使能
    // input logic[INDEX_WIDTH-1:0] index_wdata,   //victim的index
    input logic[TAG_WIDTH+INDEX_WIDTH+1-1:0] tagvindex_wdata,    //victim的tagv
    input logic [LINE_WORD_NUM-1:0][31:0] data_wdata,//victim的data
    output logic [LINE_WORD_NUM-1:0][31:0] data_rdata,//读出的data
    output logic[TAG_WIDTH+INDEX_WIDTH+1-1:0] tagvindex_rdata //读出的tagv_rdata
);
    
typedef struct packed {
    logic valid;
    logic [TAG_WIDTH-1:0] tag;  
    logic [INDEX_WIDTH-1:0] index;
} tagvindex_t; //每一路 一个tag_t变量

//
simple_port_lutram  #(
    .SIZE(SIZE),
    .dtype(tagvindex_t)
) mem_tag(
    .clka(clk),
    .rsta(~resetn),

    //端口信号
    .ena(1'b1),
    .wea(we),
    .addra(index[$clog2(SIZE)-1:0]),
    .dina(tagvindex_wdata),
    .douta(tagvindex_rdata)
);
for (genvar  i=0; i<LINE_WORD_NUM; ++i) begin
        simple_port_ram #(
        .SIZE(SIZE)
    )mem_data(
        .clk(clk),
        .rst(~resetn),

        //写端�?
        .ena(1'b1),
        .wea(we),
        .addra(index[$clog2(SIZE)-1:0]),
        .dina(data_wdata[i]),

        //读端�?
        .enb(data_read_en),
        .addrb(index[$clog2(SIZE)-1:0]),
        .doutb(data_rdata[i])
    );
end


endmodule