/*
 * @Author: your name
 * @Date: 2021-06-29 23:11:11
 * @LastEditTime: 2021-08-16 03:14:31
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\ICache.sv
 */
//重写之后的Cache Icache Dcache复用一个设计
`include "../Cache_Defines.svh"
`include "../CPU_Defines.svh"
//`define Dcache  // 如果是DCache就在文件中使用这个宏


module Icache #(
    //parameter bus_width = 4,//axi总线的id域有bus_width位
    parameter DATA_WIDTH    = 32,//cache和cpu 总线数据位宽为data_width
    parameter LINE_WORD_NUM = 4,//cache line大小 一块的字数
    parameter ASSOC_NUM     = 4,//assoc_num组相连
    parameter WAY_SIZE      = 4*1024*8,//一路cache 容量大小为way_size bit
    parameter SET_NUM       = WAY_SIZE/(LINE_WORD_NUM*DATA_WIDTH) // 

) (
    //external signals
    input logic clk,
    input logic resetn,

    //with TLBMMU
    //output VirtualAddressType virt_addr,
    // input  PhysicalAddressType phsy_addr,现在移到cpu_bus中
    // input  logic isCache,


    AXI_UNCACHE_Interface axi_ubus,

    CPU_IBus_Interface cpu_bus,//slave
    AXI_IBus_Interface  axi_bus //master
    
    
);
//parameters
localparam int unsigned BYTES_PER_WORD = 4;
localparam int unsigned INDEX_WIDTH    = $clog2(SET_NUM) ;
localparam int unsigned OFFSET_WIDTH   = $clog2(LINE_WORD_NUM*BYTES_PER_WORD);//
localparam int unsigned TAG_WIDTH      = 32-INDEX_WIDTH-OFFSET_WIDTH ;


//--definitions
typedef struct packed {
    logic valid;
    logic [TAG_WIDTH-1:0] tag;  
} tagv_t; //每一路 一个tag_t变量




typedef logic [TAG_WIDTH-1:0]                     tag_t;
typedef logic [INDEX_WIDTH-1:0]                   index_t;
typedef logic [OFFSET_WIDTH-1:0]                  offset_t;

typedef logic [ASSOC_NUM-1:0]                     we_t;//每一路 每一个bank的写使能
typedef logic [DATA_WIDTH-1:0]                    data_t;//

function index_t get_index( input logic [31:0] addr );
    return addr[OFFSET_WIDTH + INDEX_WIDTH - 1 : OFFSET_WIDTH];
endfunction

function tag_t get_tag( input logic [31:0] addr );
    return addr[31 : OFFSET_WIDTH + INDEX_WIDTH];
endfunction

function offset_t get_offset( input logic [31:0] addr );
    return addr[OFFSET_WIDTH - 1 : 0];
endfunction



typedef enum logic [2:0] { 
        REQ,
        WAIT,
        UNCACHEDONE,

        LOOKUP,
        MISSCLEAN,
        REFILL,
        REFILLDONE
} state_t;




typedef struct packed {
    logic             valid;
    tag_t             tag;
    index_t           index;
    offset_t          offset;
    logic             isCache;
} request_t;

// typedef struct packed {
//     logic valid;
//     tag_t tag;  
//     index_t index;
// } tagvindex_t; //每一路 一个tag_t变量


function logic  clog2(//TODO: 配置的时候需要改�?
    input logic [1:0] hit
);
    return{
        (hit[1])?1'b1:1'b0
    };
endfunction



//declartion
state_t state,state_next;

logic [31:0] uncache_rdata;

index_t read_addr;//read_addr 既是 查询的地址 又是重填的地址  write_addr是store的地址

tagv_t tagv_rdata[ASSOC_NUM-1:0];
tagv_t tagv_wdata;
we_t tagv_we;// 重填的时候写使能


data_t data_rdata[ASSOC_NUM-1:0][LINE_WORD_NUM-1:0];
logic [31:0] data_rdata_sel[ASSOC_NUM-1:0];
logic [31:0] data_rdata_final;//

logic data_read_en;//读使能
data_t data_wdata[LINE_WORD_NUM-1:0];
we_t  data_we;//数据表的写使能



request_t req_buffer;
logic req_buffer_en;

logic [$clog2(ASSOC_NUM)-1:0] lru[SET_NUM-1:0];
logic [ASSOC_NUM-1:0] hit;
logic cache_hit;

logic [ASSOC_NUM-1:0] pipe_hit;
logic pipe_cache_hit;

tagv_t pipe_tagv_rdata[ASSOC_NUM-1:0];
logic pipe_wr;

logic busy_cache;// uncache 直到数据返回
logic busy_uncache;
logic busy;


//连cpu_bus接口
assign cpu_bus.busy   = busy;
assign cpu_bus.rdata  = (req_buffer.valid)?data_rdata_final:'0;

//连axi_bus接口
assign axi_bus.rd_req  = (state == MISSCLEAN) ? 1'b1:1'b0;
assign axi_bus.rd_addr = {req_buffer.tag , req_buffer.index, {OFFSET_WIDTH{1'b0}}};


//连axi_ubus接口
assign axi_ubus.rd_req   = (state == REQ) ? 1'b1:1'b0;
assign axi_ubus.rd_addr  = {req_buffer.tag , req_buffer.index, req_buffer.offset};

//generate
generate;
    for (genvar i = 0;i<ASSOC_NUM ;i++ ) begin
        simple_port_lutram  #(
            .SIZE(SET_NUM),
            .dtype(tagv_t)
        ) mem_tag(
            .clka(clk),
            .rsta(~resetn),

            //端口信号
            .ena(1'b1),
            .wea(tagv_we[i]),
            .addra(read_addr),
            .dina(tagv_wdata),
            .douta(tagv_rdata[i])
        );
        for (genvar j=0; j<LINE_WORD_NUM; ++j) begin
            simple_port_ram_without_bypass #(
            .SIZE(SET_NUM)
        )mem_data(
            .clk(clk),
            .rst(~resetn),

            //写端口
            .ena(1'b1),
            .wea(data_we[i]),//第i路 的写使能
            .addra(read_addr),
            .dina(data_wdata[j]),//因为要重填 所以还是要有的

            //读端口
            .enb(data_read_en),
            .addrb(read_addr),
            .doutb(data_rdata[i][j])//第i路 第j个bank
        );
        end
        
    end
endgenerate

generate;//PLRU 
    for (genvar  i=0; i<SET_NUM; i++) begin
        PLRU #(
            .ASSOC_NUM(ASSOC_NUM)
        ) plru_reg(
            .clk(clk),
            .resetn(resetn),
            .access(pipe_hit),
            .update(req_buffer.valid && i[INDEX_WIDTH-1:0] == req_buffer.index),

            .lru(lru[i])
        );
    end
endgenerate



generate;//判断命中
    for (genvar i=0; i<ASSOC_NUM; i++) begin
        assign hit[i] = (cpu_bus.stall) ? (tagv_rdata[i].valid & (req_buffer.tag == tagv_rdata[i].tag) & req_buffer.isCache) ? 1'b1:1'b0 : (tagv_rdata[i].valid & (cpu_bus.tag == tagv_rdata[i].tag) & cpu_bus.isCache) ? 1'b1:1'b0;
    end
endgenerate

generate;//根据offset片选？
    for (genvar i=0; i<ASSOC_NUM; i++) begin
        assign data_rdata_sel[i] = data_rdata[i][req_buffer.offset[OFFSET_WIDTH-1:2]];
    end
endgenerate
generate;//
    for (genvar i=0; i<LINE_WORD_NUM; i++) begin
        assign data_wdata[i] = axi_bus.ret_data[32*(i+1)-1:32*(i)];
    end
endgenerate
assign data_read_en     = (state == REFILLDONE) ? 1'b1 : (cpu_bus.stall)? 1'b0:1'b1;
//旁路
                            //
assign data_rdata_final = (req_buffer.valid)?  (state == UNCACHEDONE )? uncache_rdata:data_rdata_sel[clog2(pipe_hit)]: '0;
assign cache_hit = |hit;

assign read_addr      = (state == MISSCLEAN || state == REFILLDONE || state == REFILL )? req_buffer.index : cpu_bus.index;//


assign busy_cache     = (req_buffer.valid & ~pipe_cache_hit & req_buffer.isCache) ? 1'b1:1'b0;
assign busy_uncache   = (req_buffer.valid & (~req_buffer.isCache) & (state != UNCACHEDONE) ) ?1'b1 :1'b0;

assign busy           = busy_cache | busy_uncache;

assign pipe_wr        = (state == REFILLDONE) ? 1'b1:(cpu_bus.stall)?1'b0:1'b1;

assign req_buffer_en  = (cpu_bus.stall)? 1'b0:1'b1 ;

// assign data_wdata =  axi_bus.ret_data ;
assign tagv_wdata     = (~cpu_bus.stall && cpu_bus.cacheType.isIcache ) ? '0 : {1'b1,req_buffer.tag} ;




always_comb begin : tagv_we_blockName
    if (state == REFILL) begin
        tagv_we = '0;
        tagv_we[lru[req_buffer.index]] =1'b1;
    end else if(~cpu_bus.stall && cpu_bus.cacheType.isIcache )begin
        tagv_we = '1;
    end else begin
        tagv_we = '0;
    end
end
always_comb begin : data_we_blockName
    if (state == REFILL) begin
        data_we = '0;
        data_we[lru[req_buffer.index]] =1'b1;
    end else begin
        data_we = '0;
    end    
end


always_ff @(posedge clk) begin : req_buffer_blockName
    if (resetn == `RstEnable) begin
        req_buffer <='0;
    end else if(req_buffer_en) begin
        req_buffer.valid    <=  cpu_bus.valid;
        req_buffer.tag      <=  cpu_bus.tag;
        req_buffer.index    <=  cpu_bus.index;
        req_buffer.offset   <=  cpu_bus.offset;
        req_buffer.isCache  <=  cpu_bus.isCache;
    end else begin
        req_buffer <= req_buffer;
    end
end

always_ff @( posedge clk ) begin : uncache_rdata_blockName//更新uncache读出来的值
    if (axi_ubus.ret_valid) begin
        uncache_rdata <= axi_ubus.ret_data;
    end else begin
        uncache_rdata <= uncache_rdata;
    end
end

generate;//锁存读出的tag
    for (genvar  i=0; i<ASSOC_NUM; i++) begin
    always_ff @( posedge clk ) begin : pipe_tagv_rdata_blockName
        if (pipe_wr) begin
            pipe_tagv_rdata[i].tag   <= tagv_rdata[i].tag;
            pipe_tagv_rdata[i].valid <= tagv_rdata[i].valid ;
        end else begin
            pipe_tagv_rdata[i].tag   <= pipe_tagv_rdata[i].tag;
            pipe_tagv_rdata[i].valid <= pipe_tagv_rdata[i].valid ;        
        end
    end        
    end
endgenerate

always_ff @( posedge clk )begin : pipe_hit_blockname
    if (pipe_wr) begin
        pipe_cache_hit <= cache_hit;
        pipe_hit       <= hit;
    end
end


always_ff @( posedge clk ) begin : state_blockName
    if (resetn == `RstEnable) begin
        state <= LOOKUP;
    end else begin
        state <= state_next;
    end
end

always_comb begin : state_next_blockname
    state_next =LOOKUP;

    unique case (state)
        LOOKUP:begin
            if (req_buffer.isCache == 1'b0 && req_buffer.valid) begin
                state_next = REQ;
            end else begin
            if (~pipe_cache_hit & req_buffer.valid) begin
                state_next = MISSCLEAN;
            end else begin
                state_next = LOOKUP ;
            end
            end              
        end
        MISSCLEAN:begin
            if (axi_bus.rd_rdy) begin//可以读
                state_next = REFILL;
            end else begin
                state_next = MISSCLEAN;
            end
        end
        REFILL:begin
            if (axi_bus.ret_valid) begin//值合法
                state_next = REFILLDONE;
            end else begin
                state_next = REFILL;
            end
        end
        REFILLDONE:begin
                state_next = LOOKUP;
            
        end
        REQ:begin
            if (axi_ubus.rd_rdy) begin
                state_next = WAIT;
            end else begin
                state_next = REQ;
            end
        end
        WAIT:begin
            if (axi_ubus.ret_valid) begin
                state_next = UNCACHEDONE;
            end else begin
                state_next = WAIT;
            end
        end
        UNCACHEDONE:begin
            if (cpu_bus.stall) begin
                state_next = UNCACHEDONE;
            end else begin
                state_next = LOOKUP;
            end
             
        end
        default: begin
            state_next =LOOKUP;
        end
    endcase
end


endmodule
