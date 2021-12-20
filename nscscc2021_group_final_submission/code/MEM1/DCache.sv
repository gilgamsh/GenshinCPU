/*
 * @Author: your name
 * @Date: 2021-06-29 23:11:11
 * @LastEditTime: 2021-08-16 03:19:14
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\ICache.sv
 */
//重写之后的Cache Icache Dcache复用�?个设�?
`include "../Cache_Defines.svh"
`include "../CPU_Defines.svh"
//`define Dcache  //如果是DCache就在文件中使用这个宏
//`define DEBUG
//dcache只有在不busy的时候才会 处理在mem1的指令 cpu_bus.valid与cache指令无关
module Dcache #(
    //parameter bus_width = 4,//axi总线的id域有bus_width�?
    parameter STORE_BUFFER_SIZE = 32,
    parameter DATA_WIDTH        = 32,//cache和cpu 总线数据位宽为data_width
    parameter LINE_WORD_NUM     = 4,//cache line大小 �?块的字数
    parameter ASSOC_NUM         = 4,//assoc_num组相�?
    parameter WAY_SIZE          = 4*1024*8,//�?路cache 容量大小为way_size bit //4KB
    parameter SET_NUM           = WAY_SIZE/(LINE_WORD_NUM*DATA_WIDTH) //256

) (
    //external signals
    input logic clk,
    input logic resetn,

    //with TLBMMU
    //output VirtualAddressType virt_addr,
    // input  PhysicalAddressType phsy_addr,现在移到cpu_bus�?
    // input  logic isCache,


    AXI_UNCACHE_Interface axi_ubus,

    CPU_DBus_Interface cpu_bus,//slave
    AXI_DBus_Interface  axi_bus //master
    
    
);
//parameters
localparam int unsigned BYTES_PER_WORD = 4;
localparam int unsigned INDEX_WIDTH    = $clog2(SET_NUM) ;//8
localparam int unsigned OFFSET_WIDTH   = $clog2(LINE_WORD_NUM*BYTES_PER_WORD);//4
localparam int unsigned TAG_WIDTH      = 32-INDEX_WIDTH-OFFSET_WIDTH ;//20


//--definitions
typedef struct packed {
    logic valid;
    //logic dirty;//TODO: 记得把dirty从tagv lutram中分�? 因为会存�? 同时读写的情�? 且读写地�?不一�?
    logic [TAG_WIDTH-1:0] tag;  
} tagv_t; //每一�? �?个tag_t变量

typedef  logic dirty_t;

typedef struct packed {
    // logic valid;
    logic [31:0] address;
    logic [31:0] data;
    logic [3:0] wstrb;
} uncache_store_t;

typedef logic [ASSOC_NUM-1:0]                     hit_t;
typedef logic [TAG_WIDTH-1:0]                     tag_t;
typedef logic [INDEX_WIDTH-1:0]                   index_t;
typedef logic [OFFSET_WIDTH-1:0]                  offset_t;

typedef logic [ASSOC_NUM-1:0]                     we_t;//每一路的写使�?
typedef logic [DATA_WIDTH-1:0]                    data_t;//每一路一个cache_line

function index_t get_index( input logic [31:0] addr );
    return addr[OFFSET_WIDTH + INDEX_WIDTH - 1 : OFFSET_WIDTH];
endfunction

function tag_t get_tag( input logic [31:0] addr );
    return addr[31 : OFFSET_WIDTH + INDEX_WIDTH];
endfunction

function offset_t get_offset( input logic [31:0] addr );
    return addr[OFFSET_WIDTH - 1 : 0];
endfunction



function logic [31:0] mux_byteenable(
    input logic [31:0] rdata,
    input logic [31:0] wdata,
    input logic [3:0] sel 
);
    return { 
        sel[3] ? wdata[31:24] : rdata[31:24],
        sel[2] ? wdata[23:16] : rdata[23:16],
        sel[1] ? wdata[15:8] : rdata[15:8],
        sel[0] ? wdata[7:0] : rdata[7:0]
    };
endfunction



function logic  clog2(//TODO: 配置的时候需要改�?
    input logic [1:0] hit
);
    return{
        (hit[1])?1'b1:1'b0
    };
endfunction

typedef enum logic [2:0] { 

        MISSDIRTY,
        WRITEBACK,//之后加入fifo就不用这个装态了

        LOOKUP,
        MISSCLEAN,
        REFILL,
        REFILLDONE
} state_t;


typedef enum logic [0:0] { 
        WB_IDLE,
        WB_STORE
} wb_state_t;


typedef struct packed {
    logic             valid;
    logic             op;
    tag_t             tag;
    index_t           index;
    offset_t          offset;
    logic[3:0]        wstrb; //写使�?
    logic[31:0]       wdata; //store数据
    LoadType          loadType;//load类型
    logic             isCache;
    CacheType         cacheType;
} request_t;


typedef struct packed {//store指令在读数的时�?�根据写使能替换
    logic [ASSOC_NUM-1:0] hit;//命中的路数
    tag_t   tag;
    index_t index;//set号
    offset_t offset;//偏移
    data_t  wdata;
} store_t;

typedef enum logic [1:0]{ 
    UNCACHE_IDLE,//空闲态
    UNCACHE_READ_WAIT_AXI,//等待读握手
    // UNCACHE_WRITE_WAIT_AXI,//等待写握手
    UNCACHE_READ,//等待读数据
    UNCACHE_READ_DONE//读完成
    // UNCACHE_WAIT_BVALID,//等待写完成
    // UNCACHE_WAIT_BVALID_RW,//等待写完成同时 有了新的读写访存
    // UNCACHE_WAIT_RW
} uncache_state_t;

typedef enum logic [1:0] { 
    CACHE_IDLE,
    CACHE_LOOKUP,
    CACHE_WAIT_WRITE,
    CACHE_WRITEBACK
 } cache_state_t;//cache指令状态机
//declartion

uncache_state_t uncache_state,uncache_state_next;
store_t store_buffer; //如果有写冲突 直接阻塞
state_t state,state_next;
cache_state_t cache_state,cache_state_next;

wb_state_t wb_state,wb_state_next;
 
logic [31:0] uncache_rdata;

index_t read_addr,write_addr,tagv_addr;//read_addr 既是 查询的地�? 又是重填的地�?  write_addr是store的地�?

tagv_t [ASSOC_NUM-1:0] tagv_rdata;
tagv_t tagv_wdata;
we_t tagv_we;// 重填的时候写使能

index_t dirty_addr;
dirty_t [ASSOC_NUM-1:0]dirty_rdata;
dirty_t dirty_wdata;
we_t    dirty_we;



we_t wb_we;//store的写使能

data_t data_rdata[ASSOC_NUM-1:0][LINE_WORD_NUM-1:0];
logic [31:0] data_rdata_sel[ASSOC_NUM-1:0];
logic [31:0] data_rdata_final_;//经过store的旁路
logic [31:0] data_rdata_final;//
// logic [31:0] data_rdata_final2;//经过ext2的数�?
data_t data_wdata[LINE_WORD_NUM-1:0];
logic [ASSOC_NUM-1:0][LINE_WORD_NUM-1:0] data_we;//数据表的写使�? 因为现在store 是专门给某一个字用的
logic data_read_en;

request_t req_buffer;
logic req_buffer_en;

logic [$clog2(ASSOC_NUM)-1:0] lru[SET_NUM-1:0];
logic [ASSOC_NUM-1:0] hit;
logic cache_hit;

logic [ASSOC_NUM-1:0] pipe_hit;
logic pipe_cache_hit;

tagv_t [ASSOC_NUM-1:0] pipe_tagv_rdata;
logic pipe_wr;

logic busy_cache;// uncache 直到数据返回
logic busy_uncache_read;
logic busy_uncache_write;//这表示store_buffer满了
logic busy_cache_instr;
// logic busy_collision;
// logic busy_collision1;
// logic busy_collision2;


// logic [32-OFFSET_WIDTH:0] MEM2,WB;//用于判断是否写冲�?

logic busy;


uncache_store_t fifo_din;//input
logic fifo_wr_en;
logic fifo_rd_en;

logic fifo_rd_rst_busy;// output
logic fifo_full;
logic fifo_empty;
uncache_store_t fifo_dout;
logic fifo_data_valid;
logic fifo_wr_ack;
logic fifo_wr_rst_busy;

//连fifo接口
assign fifo_din   = {req_buffer.tag,req_buffer.index,req_buffer.offset,req_buffer.wdata,req_buffer.wstrb};
assign fifo_wr_en = (cpu_bus.stall || fifo_wr_rst_busy || fifo_full || (~(req_buffer.valid & req_buffer.op & (~req_buffer.isCache))) ) ?  1'b0 : 1'b1;//流水线停滞 不能写 fifo满 不是uncache写指令
assign fifo_rd_en = (axi_ubus.wr_rdy && (!fifo_empty) && (!fifo_rd_rst_busy)) ? 1'b1 :1'b0;//非空 能写 


//连cpu_bus接口
assign cpu_bus.busy   = busy;
assign cpu_bus.rdata  = (req_buffer.valid)?data_rdata_final:'0;

//连axi_bus接口
assign axi_bus.rd_req  = (state == MISSCLEAN) ? 1'b1:1'b0;
assign axi_bus.rd_addr = {req_buffer.tag , req_buffer.index, {OFFSET_WIDTH{1'b0}}};
assign axi_bus.wr_req  = (cache_state == CACHE_WAIT_WRITE  ||state == MISSDIRTY) ? 1'b1:1'b0;


// assign axi_bus.wr_addr = (){pipe_tagv_rdata[lru[req_buffer.index]].tag,req_buffer.index,{OFFSET_WIDTH{1'b0}}};
always_comb begin : axi_bus_wraddr_blockName
    if (req_buffer.cacheType.isDcache) begin
        case (req_buffer.cacheType.cacheCode)
            D_Index_Writeback_Invalid:begin
                axi_bus.wr_addr = {pipe_tagv_rdata[req_buffer.tag[0]].tag,req_buffer.index,{OFFSET_WIDTH{1'b0}}};//tag[0]为1 即指的是第一路
            end
            D_Hit_Writeback_Invalid:begin
                axi_bus.wr_addr = {req_buffer.tag,req_buffer.index,{OFFSET_WIDTH{1'b0}}};
            end
            default: begin
                axi_bus.wr_addr = '0;
            end
        endcase
    end else begin
        axi_bus.wr_addr = {pipe_tagv_rdata[lru[req_buffer.index]].tag,req_buffer.index,{OFFSET_WIDTH{1'b0}}};//要被替换的地址
    end
end
// assign axi_bus.wr_data = {data_rdata[lru[req_buffer.index]]};

logic[`DCACHE_LINE_WORD*32-1:0] wr_data1,wr_data2,wr_data3;

generate;
    for (genvar  i=0; i<LINE_WORD_NUM; ++i) begin
        assign wr_data1[32*(i+1)-1:32*(i)] = data_rdata[req_buffer.tag[0]][i];
    end
endgenerate
generate;
    for (genvar  i=0; i<LINE_WORD_NUM; ++i) begin
        assign wr_data2[32*(i+1)-1:32*(i)] = data_rdata[clog2(pipe_hit)][i];
    end
endgenerate
generate;
    for (genvar  i=0; i<LINE_WORD_NUM; ++i) begin
        assign wr_data3[32*(i+1)-1:32*(i)] = data_rdata[lru[req_buffer.index]][i];
    end
endgenerate

always_comb begin : axi_bus_wr_data_blockName
    if (req_buffer.cacheType.isCache==1) begin
        case (req_buffer.cacheType.cacheCode)
            D_Index_Writeback_Invalid:begin
                axi_bus.wr_data = wr_data1;
            end
            D_Hit_Writeback_Invalid:begin
                axi_bus.wr_data = wr_data2;
            end
            default: begin
               axi_bus.wr_data = '0;
            end
        endcase
    end else begin
        for (int i=0; i<LINE_WORD_NUM; i++) begin
                axi_bus.wr_data = wr_data3;
            end
    end    
end
// genvar i;
// generate;
//      for ( i=0; i<LINE_WORD_NUM; i++) begin
//          if (1) begin
//             case (req_buffer.cacheType.cacheCode)
//                 D_Index_Writeback_Invalid:begin
//                    assign  axi_bus.wr_data[32*(i+1)-1:32*(i)] = data_rdata[req_buffer.tag[0]][i];
//                 end
//                 D_Hit_Writeback_Invalid:begin
//                     assign axi_bus.wr_data[32*(i+1)-1:32*(i)] = data_rdata[clog2(hit)][i];
//                 end
//                 default: begin
//                     assign axi_bus.wr_data = '0;
//                 end
//             endcase
//          end
//          else begin
//             assign axi_bus.wr_data[32*(i+1)-1:32*(i)] = data_rdata[lru[req_buffer.index]][i];
//          end
//     end
// endgenerate

//连axi_ubus接口
assign axi_ubus.rd_req   = (uncache_state == UNCACHE_READ_WAIT_AXI) ? 1'b1:1'b0;
assign axi_ubus.rd_addr  = {req_buffer.tag , req_buffer.index, req_buffer.offset};
assign axi_ubus.wr_req   = (fifo_empty || fifo_rd_rst_busy) ? 1'b0:1'b1;//有隐患 fifo不empty 只是无法出栈 就会导致无法发出写请求那么可能就会让读先了 不过都resetn了 我该就没有读了
assign axi_ubus.wr_addr  = {fifo_dout.address}; //TODO:没有抹零
assign axi_ubus.wr_data  = {fifo_dout.data};
assign axi_ubus.wr_wstrb = fifo_dout.wstrb;
assign axi_ubus.loadType = req_buffer.loadType;

//generate
generate;
    for (genvar i = 0;i<ASSOC_NUM ;i++ ) begin
        simple_port_lutram #(
            .SIZE(SET_NUM),
            .dtype(dirty_t)
        )mem_dirty(
            .clka(clk),
            .rsta(~resetn),

            //端口信号
            .ena(1'b1),
            .wea(dirty_we[i]),
            .addra(dirty_addr),
            .dina(dirty_wdata),
            .douta(dirty_rdata[i])            
        );

        simple_port_lutram  #(
            .SIZE(SET_NUM),
            .dtype(tagv_t)
        ) mem_tag(
            .clka(clk),
            .rsta(~resetn),

            //端口信号
            .ena(1'b1),
            .wea(tagv_we[i]),
            .addra(tagv_addr),
            .dina(tagv_wdata),
            .douta(tagv_rdata[i])
        );
        for (genvar j=0; j<LINE_WORD_NUM; ++j) begin
        simple_port_ram #(
            .SIZE(SET_NUM)
        )mem_data(
            .clk(clk),
            .rst(~resetn),

            //写端�?
            .ena(1'b1),
            .wea(data_we[i][j]),
            .addra(write_addr),
            .dina(data_wdata[j]),

            //读端�?
            .enb(data_read_en),
            .addrb(read_addr),
            .doutb(data_rdata[i][j])
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
            .update(req_buffer.valid &&i[INDEX_WIDTH-1:0] == req_buffer.index),

            .lru(lru[i])
        );
    end
endgenerate

generate;//  判断命中
    for (genvar i=0; i<ASSOC_NUM; i++) begin
        assign hit[i] = (cpu_bus.stall) ? (tagv_rdata[i].valid & (req_buffer.tag == tagv_rdata[i].tag) & req_buffer.isCache) ? 1'b1:1'b0 : (tagv_rdata[i].valid & (cpu_bus.tag == tagv_rdata[i].tag) & cpu_bus.isCache) ? 1'b1:1'b0;
    end
endgenerate

generate;//根据offset片�?�？
    for (genvar i=0; i<ASSOC_NUM; i++) begin
        assign data_rdata_sel[i] = data_rdata[i][req_buffer.offset[OFFSET_WIDTH-1:2]];
    end
endgenerate
//旁路
                            //
assign data_rdata_final =   (uncache_state == UNCACHE_READ_DONE )? uncache_rdata: data_rdata_final_;

assign cache_hit        = |hit;

assign read_addr      = (state == REFILLDONE || state == REFILL )? req_buffer.index : cpu_bus.index;
assign write_addr     = (state == REFILL)?req_buffer.index : store_buffer.index;
assign tagv_addr      = (state == REFILLDONE || state == REFILL || cache_state == CACHE_LOOKUP ) ? req_buffer.index :cpu_bus.index;


assign busy_cache          = (req_buffer.valid & ~pipe_cache_hit & req_buffer.isCache) ? 1'b1:1'b0;
assign busy_uncache_read   = (uncache_state == UNCACHE_IDLE  || uncache_state == UNCACHE_READ_DONE) ? 1'b0 : 1'b1;
// assign busy_collision1     = (cpu_bus.origin_valid & cpu_bus.isCache & MEM2[32-OFFSET_WIDTH] & MEM2[31-OFFSET_WIDTH:0]=={cpu_bus.tag,cpu_bus.index})?1'b1:1'b0;
// assign busy_collision2     = (cpu_bus.origin_valid & cpu_bus.isCache &WB[32-OFFSET_WIDTH] & WB[31-OFFSET_WIDTH:0]=={cpu_bus.tag,cpu_bus.index})?1'b1:1'b0;
// assign busy_collision      = busy_collision1 | busy_collision2;
assign busy_uncache_write  = (fifo_full) ? 1'b1:1'b0;
assign busy_cache_instr    = (cache_state == CACHE_IDLE) ? 1'b0:1'b1;
assign busy                = busy_cache | busy_uncache_read | busy_uncache_write | busy_cache_instr ;

assign pipe_wr        = (state == REFILLDONE) ? 1'b1:(cpu_bus.stall)?1'b0:1'b1;

assign req_buffer_en  = (cpu_bus.stall)? 1'b0:1'b1 ;

generate;//
    for (genvar i=0; i<LINE_WORD_NUM; i++) begin
        assign data_wdata[i] = (state == REFILL) ? axi_bus.ret_data[32*(i+1)-1:32*(i)] : store_buffer.wdata;
    end
endgenerate
always_comb begin : tagv_wdata_blockName
    if(req_buffer.cacheType.isCache)begin
        tagv_wdata = '0;
    end else begin
        tagv_wdata = {1'b1,req_buffer.tag};
    end
end
assign data_read_en   = (state == REFILLDONE  ) ? 1'b1  : (cpu_bus.stall) ? 1'b0 : 1'b1;

assign dirty_wdata    = (cache_state == CACHE_LOOKUP || state == REFILL)? 1'b0 : 1'b1;
assign dirty_addr     = req_buffer.index;


//if not stall 更新     if stall check if hit & store & cache
// always_ff @( posedge clk ) begin : MEM2_blockName
//     if (  cpu_bus.stall & (~(busy_cache|busy_uncache_read|busy_uncache_write)) ) begin//如果全流水阻塞了 并且不是因为dcache的原因阻塞的
//         MEM2<='0;
//     end else if(~(cpu_bus.stall))begin
//         MEM2<={cpu_bus.valid&cpu_bus.op&cpu_bus.isCache,cpu_bus.tag,cpu_bus.index};
//     end else begin
//         MEM2<=MEM2;
//     end
// end

// always_ff @( posedge clk ) begin : WB_blockName
//     WB<= MEM2;
// end


// always_comb begin : data_rdata_final2_blockname
//     unique case({req_buffer.loadType.sign,req_buffer.loadType.size})
//           `LOADTYPE_LW: begin
//             data_rdata_final2 = data_rdata_final;  //LW
//           end 
//           `LOADTYPE_LH: begin
//             if(req_buffer.offset[1] == 1'b0) //LH
//               data_rdata_final2 = {{16{data_rdata_final[15]}},data_rdata_final[15:0]};
//             else
//               data_rdata_final2 = {{16{data_rdata_final[31]}},data_rdata_final[31:16]}; 
//           end
//           `LOADTYPE_LHU: begin
//             if(req_buffer.offset[1] == 1'b0) //LHU
//               data_rdata_final2 = {16'b0,data_rdata_final[15:0]};
//             else
//               data_rdata_final2 = {16'b0,data_rdata_final[31:16]};
//           end
//           `LOADTYPE_LB: begin
//             if(req_buffer.offset[1:0] == 2'b00) //LB
//               data_rdata_final2 = {{24{data_rdata_final[7]}},data_rdata_final[7:0]};
//             else if(req_buffer.offset[1:0] == 2'b01)
//               data_rdata_final2 = {{24{data_rdata_final[15]}},data_rdata_final[15:8]};
//             else if(req_buffer.offset[1:0] == 2'b10)
//               data_rdata_final2 = {{24{data_rdata_final[23]}},data_rdata_final[23:16]};
//             else
//               data_rdata_final2 = {{24{data_rdata_final[31]}},data_rdata_final[31:24]};
//           end
//           `LOADTYPE_LBU: begin
//             if(req_buffer.offset[1:0] == 2'b00) //LBU
//               data_rdata_final2 = {24'b0,data_rdata_final[7:0]};
//             else if(req_buffer.offset[1:0] == 2'b01)
//               data_rdata_final2 = {24'b0,data_rdata_final[15:8]};
//             else if(req_buffer.offset[1:0] == 2'b10)
//               data_rdata_final2 = {24'b0,data_rdata_final[23:16]};
//             else
//               data_rdata_final2 = {24'b0,data_rdata_final[31:24]};
//           end
//           default: begin
//             data_rdata_final2 = 32'bx;
//           end
//         endcase
// end



always_comb begin : dirty_we_block
    if (state == REFILL) begin
        dirty_we = '0;
        dirty_we[lru[req_buffer.index]] =1'b1;
    end else if(req_buffer.cacheType.isDcache && cache_state == CACHE_LOOKUP)begin
        case (req_buffer.cacheType.cacheCode)
            D_Index_Writeback_Invalid,D_Index_Store_Tag:begin
                dirty_we = (req_buffer.tag[0]) ? 2'b10 : 2'b01;
            end
            D_Hit_Invalid,D_Hit_Writeback_Invalid:begin
                dirty_we = (pipe_cache_hit) ? ( (pipe_hit[0]) ? 2'b01:2'b10 )  : '0;
            end
            default: begin
                dirty_we = '0;
            end
        endcase
    end else if(req_buffer.valid & req_buffer.op & req_buffer.isCache)begin
        dirty_we = pipe_hit;
    end else begin
        dirty_we = '0;
    end
end

// always_comb begin : dirty_we_block
//     if (state == REFILL) begin
//         dirty_we = '0;
//         dirty_we[lru[req_buffer.index]] =1'b1;
//     end else if(req_buffer.valid & req_buffer.op & req_buffer.isCache)begin
//         dirty_we = hit;
//     end else begin
//         dirty_we = '0;
//     end
// end

always_comb begin : data_rdata_final__blockname
    data_rdata_final_= (|data_we[clog2(store_buffer.hit)]  & store_buffer.hit == pipe_hit & {store_buffer.tag,store_buffer.index,store_buffer.offset[OFFSET_WIDTH-1:2]} == {req_buffer.tag,req_buffer.index,req_buffer.offset[OFFSET_WIDTH-1:2]}) ?store_buffer.wdata :data_rdata_sel[clog2(pipe_hit)];
end


always_comb begin : tagv_we_blockName
    if (state == REFILL) begin
        tagv_we = '0;
        tagv_we[lru[req_buffer.index]] =1'b1;
    end else if(req_buffer.cacheType.isDcache && cache_state == CACHE_LOOKUP)begin
        case (req_buffer.cacheType.cacheCode)
            D_Index_Writeback_Invalid,D_Index_Store_Tag:begin
                tagv_we = (req_buffer.tag[0]) ? 2'b10 : 2'b01;
            end
            D_Hit_Invalid,D_Hit_Writeback_Invalid:begin
                tagv_we = (pipe_cache_hit) ? ( (pipe_hit[0]) ? 2'b01:2'b10 )  : '0;
            end
            default: begin
                tagv_we = '0;
            end
        endcase
    end else begin
        tagv_we = '0;
    end
end
always_comb begin : data_we_blockName
        data_we = '0;
    if (state == REFILL) begin
        data_we[lru[req_buffer.index]] ='1;
    end else if(wb_state == WB_STORE)begin
        data_we[clog2(store_buffer.hit)][store_buffer.offset[OFFSET_WIDTH-1:2]] = 1'b1;
    end else begin
        data_we = '0;
    end   
end
always_ff @( posedge clk ) begin : store_buffer_blockName
    if ((resetn == `RstEnable) ) begin
        store_buffer <= '0;
    end else if(~cpu_bus.stall && req_buffer.valid==1'b1)begin//既是�? 又是有效�?
        store_buffer.hit   <= pipe_hit;
        store_buffer.tag   <= req_buffer.tag;
        store_buffer.index <= req_buffer.index;
        store_buffer.offset <= req_buffer.offset;
        store_buffer.wdata <= mux_byteenable(data_rdata_final_,req_buffer.wdata,req_buffer.wstrb);  
    end else if (~cpu_bus.stall && req_buffer.valid==1'b0) begin//在非停滞状态下需要更新 但是此时访存无效 所以清零
        store_buffer <= '0;
    end

end

always_ff @(posedge clk) begin : req_buffer_blockName
    if (resetn == `RstEnable) begin
        req_buffer <='0;
    end else if(req_buffer_en) begin
        req_buffer.valid    <=  cpu_bus.valid;
        req_buffer.op       <=  cpu_bus.op;
        req_buffer.tag      <=  cpu_bus.tag;
        req_buffer.index    <=  cpu_bus.index;
        req_buffer.offset   <=  cpu_bus.offset;
        req_buffer.wstrb    <=  cpu_bus.wstrb;
        req_buffer.wdata    <=  cpu_bus.wdata;
        req_buffer.loadType <=  cpu_bus.loadType;
        req_buffer.isCache  <=  cpu_bus.isCache;
        req_buffer.cacheType<=  cpu_bus.cacheType;
    end else begin
        req_buffer <= req_buffer;
    end
end

always_ff @( posedge clk ) begin : uncache_rdata_blockName//更新uncache读出来的�?
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
        end 
    end        
    end
endgenerate

always_ff @( posedge clk ) begin : pipe_hitblockName
    if (pipe_wr) begin
        pipe_cache_hit           <= cache_hit;
        pipe_hit                 <= hit;
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
            if ( req_buffer.valid) begin
                if (req_buffer.isCache == 1'b0 ) begin
                    state_next = LOOKUP;
                end else begin
                if (pipe_cache_hit) begin
                    state_next = LOOKUP;
                end else begin
                    if (dirty_rdata[lru[req_buffer.index]]) begin
                        state_next = MISSDIRTY ;
                    end else begin
                        state_next = MISSCLEAN ;
                    end
                end
                end      
            end else begin
                state_next = LOOKUP;
            end
        
        end
        MISSCLEAN:begin
            if (axi_bus.rd_rdy) begin//可以�?
                state_next = REFILL;
            end else begin
                state_next = MISSCLEAN;
            end
        end
        REFILL:begin
            if (axi_bus.ret_valid) begin//值合�?
                state_next = REFILLDONE;
            end else begin
                state_next = REFILL;
            end
        end
        REFILLDONE:begin
                state_next = LOOKUP;
        end
        MISSDIRTY:begin
            if (axi_bus.wr_rdy) begin
                state_next = WRITEBACK;
            end else begin
                state_next =  MISSDIRTY;
            end
        end
        WRITEBACK:begin
            if (axi_bus.wr_valid) begin
                state_next = MISSCLEAN;
            end else begin
                state_next = WRITEBACK;
            end
        end
        default: begin
            state_next =LOOKUP;
        end
    endcase
end
//wb_store_state
always_ff @(posedge clk) begin :wb_state_blockname
    if (resetn == `RstEnable) begin
        wb_state <= WB_IDLE;
    end else if(~cpu_bus.stall)begin
        wb_state <= wb_state_next;
    end
end

always_comb begin : wb_state_next_blockname
    if (req_buffer.valid & req_buffer.op & pipe_cache_hit & ~cpu_bus.stall ) begin
        wb_state_next = WB_STORE;
    end else begin
        wb_state_next = WB_IDLE;
    end

end
`ifdef DEBUG
logic victim_num;
assign victim_num = lru[req_buffer.index];
`endif 

//uncache 部分 削减为只有uncache读状态机



always_ff @( posedge clk ) begin : uncache_state_blockName
    if (resetn == `RstEnable) begin
        uncache_state <= UNCACHE_IDLE;
    end else begin
        uncache_state <= uncache_state_next;
    end
end

always_comb begin : uncache_state_next_blockName

    uncache_state_next = uncache_state;

    case (uncache_state)
        UNCACHE_IDLE:begin
            if (cpu_bus.valid & (~cpu_bus.isCache) & req_buffer_en) begin //如果可以接受下一个请求
                if (cpu_bus.op==1'b0) begin
                    uncache_state_next = UNCACHE_READ_WAIT_AXI;
                end else begin
                    uncache_state_next = UNCACHE_IDLE;
                end
            end 
        end
        UNCACHE_READ_WAIT_AXI:begin
            if (axi_ubus.rd_rdy) begin
                uncache_state_next = UNCACHE_READ;
            end
        end
        UNCACHE_READ:begin
            if (axi_ubus.ret_valid) begin
                uncache_state_next = UNCACHE_READ_DONE;
            end
        end
        UNCACHE_READ_DONE:begin//可以接受下一拍请求
            if (cpu_bus.stall) begin//如果有下一拍的数据
                uncache_state_next = UNCACHE_READ_DONE;
            end else begin
                if (cpu_bus.valid & (~cpu_bus.isCache) & req_buffer_en) begin //必然下一拍要发起访存
                    if (cpu_bus.op==1'b0) begin
                        uncache_state_next = UNCACHE_READ_WAIT_AXI;
                    end else begin
                        uncache_state_next = UNCACHE_IDLE;
                    end
                end
                else begin
                    uncache_state_next = UNCACHE_IDLE;
                end
            end
        end
        default:begin
                uncache_state_next = UNCACHE_IDLE;
        end
    endcase
end

always_ff @( posedge clk ) begin : cache_state_blockName
    if (resetn == `RstEnable) begin
        cache_state <= CACHE_IDLE;
    end else begin
        cache_state <= cache_state_next;
    end
end

always_comb begin : cache_state_next_blockName
    case (cache_state)
        CACHE_IDLE:begin
            if (~cpu_bus.stall && cpu_bus.cacheType.isDcache) begin
                cache_state_next = CACHE_LOOKUP;
            end else begin
                cache_state_next = CACHE_IDLE;
            end
        end
        CACHE_LOOKUP:begin//判命中
            case (req_buffer.cacheType.cacheCode)
                D_Index_Store_Tag:begin
                    cache_state_next = CACHE_IDLE;
                end
                D_Index_Writeback_Invalid:begin
                    if (req_buffer.tag[0]) begin//第一路
                        if (pipe_tagv_rdata[1].valid & dirty_rdata[1]) begin//命中且脏
                            cache_state_next = CACHE_WAIT_WRITE;
                        end else begin
                            cache_state_next = CACHE_IDLE;
                        end
                    end else begin
                        if (pipe_tagv_rdata[0].valid & dirty_rdata[0]) begin
                            cache_state_next = CACHE_WAIT_WRITE;
                        end else begin
                            cache_state_next = CACHE_IDLE;
                        end
                    end
                end
                D_Hit_Invalid:begin
                    cache_state_next = CACHE_IDLE;
                end
                D_Hit_Writeback_Invalid:begin
                    case (pipe_hit)
                        2'b01:begin
                            if (dirty_rdata[0]) begin
                                cache_state_next = CACHE_WAIT_WRITE;
                            end else begin
                                cache_state_next = CACHE_IDLE;
                            end
                        end
                        2'b10:begin
                            if (dirty_rdata[1]) begin
                                cache_state_next = CACHE_WAIT_WRITE;
                            end else begin
                                cache_state_next = CACHE_IDLE;
                            end                            
                        end
                        default: begin
                            cache_state_next = CACHE_IDLE;
                        end
                    endcase                  
                end
                default: begin
                    cache_state_next = CACHE_IDLE;
                end
            endcase
        end
        CACHE_WAIT_WRITE:begin
            if (axi_bus.wr_rdy) begin
                cache_state_next = CACHE_WRITEBACK;
            end else begin
                cache_state_next = CACHE_WAIT_WRITE;
            end
        end
        CACHE_WRITEBACK:begin
            if (axi_bus.wr_valid) begin
                cache_state_next = CACHE_IDLE;
            end else begin
                cache_state_next = CACHE_WRITEBACK;
            end            
        end
        default: begin
                cache_state_next = CACHE_IDLE;
        end
    endcase
end

  FIFO #(

    .SIZE(STORE_BUFFER_SIZE),

    .dtype(uncache_store_t),

    .LATENCY (0) //调整为0

  )

  FIFO_dut (

    .clk (clk ),

    .rst (~resetn),

    .din (fifo_din ),

    .rd_en (fifo_rd_en ),

    .wr_en (fifo_wr_en ),

    .rd_rst_busy (fifo_rd_rst_busy ),

    .full (fifo_full ),

    .empty (fifo_empty ),

    .dout (fifo_dout ),

    .data_valid (fifo_data_valid ),

    .wr_ack (fifo_wr_ack ),

    .wr_rst_busy  (fifo_wr_rst_busy)

  );

endmodule
