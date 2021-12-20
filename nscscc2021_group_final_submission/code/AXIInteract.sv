/*
 * @Author: your name
 * @Date: 2021-07-06 19:58:31
 * @LastEditTime: 2021-10-04 23:24:03
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \refactor\AXIInteract.sv
 */
`include "Cache_Defines.svh"
`include "CPU_Defines.svh"
`ifdef NEW_BRIDGE
module AXIInteract #(
    parameter ICACHE_LINE_SIZE=4,//icache块大小
    parameter DCACHE_LINE_SIZE=4 //dcache块大小
) (
    //external signals
    input logic clk,
    input logic resetn,
    //interface with cache
    AXI_IBus_Interface ibus,
    AXI_DBus_Interface dbus,

    AXI_UNCACHE_Interface uibus,
    AXI_UNCACHE_Interface udbus,


    //signals with axi bus
    output logic [ 3: 0] m_axi_arid,
    output logic [31: 0] m_axi_araddr,
    output logic [ 3: 0] m_axi_arlen,
    output logic [ 2: 0] m_axi_arsize,
    output logic [ 1: 0] m_axi_arburst,
    output logic [ 1: 0] m_axi_arlock,
    output logic [ 3: 0] m_axi_arcache,
    output logic [ 2: 0] m_axi_arprot,
    output logic         m_axi_arvalid,
    input  logic         m_axi_arready,
    input  logic [ 3: 0] m_axi_rid,
    input  logic [31: 0] m_axi_rdata,
    input  logic [ 1: 0] m_axi_rresp,
    input  logic         m_axi_rlast,
    input  logic         m_axi_rvalid,
    output logic         m_axi_rready,
    output logic [ 3: 0] m_axi_awid,
    output logic [31: 0] m_axi_awaddr,
    output logic [ 3: 0] m_axi_awlen,
    output logic [ 2: 0] m_axi_awsize,
    output logic [ 1: 0] m_axi_awburst,
    output logic [ 1: 0] m_axi_awlock,
    output logic [ 3: 0] m_axi_awcache,
    output logic [ 2: 0] m_axi_awprot,
    output logic         m_axi_awvalid,
    input  logic         m_axi_awready,
    output logic [ 3: 0] m_axi_wid,
    output logic [31: 0] m_axi_wdata,
    output logic [ 3: 0] m_axi_wstrb,
    output logic         m_axi_wlast,
    output logic         m_axi_wvalid,
    input  logic         m_axi_wready,
    input  logic [ 3: 0] m_axi_bid,
    input  logic [ 1: 0] m_axi_bresp,
    input  logic         m_axi_bvalid,
    output logic         m_axi_bready
);
// Icache 
    logic [ 3: 0] ibus_arid;
    logic [31: 0] ibus_araddr;
    logic [ 3: 0] ibus_arlen;
    logic [ 2: 0] ibus_arsize;
    logic [ 1: 0] ibus_arburst;
    logic [ 1: 0] ibus_arlock;
    logic [ 3: 0] ibus_arcache;
    logic [ 2: 0] ibus_arprot;
    logic         ibus_arvalid;
    logic         ibus_arready;
    logic [ 3: 0] ibus_rid;
    logic [31: 0] ibus_rdata;
    logic [ 1: 0] ibus_rresp;
    logic         ibus_rlast;
    logic         ibus_rvalid;
    logic         ibus_rready;
    logic [ 3: 0] ibus_awid;
    logic [31: 0] ibus_awaddr;
    logic [ 3: 0] ibus_awlen;
    logic [ 2: 0] ibus_awsize;
    logic [ 1: 0] ibus_awburst;
    logic [ 1: 0] ibus_awlock;
    logic [ 3: 0] ibus_awcache;
    logic [ 2: 0] ibus_awprot;
    logic         ibus_awvalid;
    logic         ibus_awready;
    logic [ 3: 0] ibus_wid;
    logic [31: 0] ibus_wdata;
    logic [ 3: 0] ibus_wstrb;
    logic         ibus_wlast;
    logic         ibus_wvalid;
    logic         ibus_wready;
    logic [ 3: 0] ibus_bid;
    logic [ 1: 0] ibus_bresp;
    logic         ibus_bvalid;
    logic         ibus_bready;

// Dcache 
    logic [ 3: 0] dbus_arid;
    logic [31: 0] dbus_araddr;
    logic [ 3: 0] dbus_arlen;
    logic [ 2: 0] dbus_arsize;
    logic [ 1: 0] dbus_arburst;
    logic [ 1: 0] dbus_arlock;
    logic [ 3: 0] dbus_arcache;
    logic [ 2: 0] dbus_arprot;
    logic         dbus_arvalid;
    logic         dbus_arready;
    logic [ 3: 0] dbus_rid;
    logic [31: 0] dbus_rdata;
    logic [ 1: 0] dbus_rresp;
    logic         dbus_rlast;
    logic         dbus_rvalid;
    logic         dbus_rready;
    logic [ 3: 0] dbus_awid;
    logic [31: 0] dbus_awaddr;
    logic [ 3: 0] dbus_awlen;
    logic [ 2: 0] dbus_awsize;
    logic [ 1: 0] dbus_awburst;
    logic [ 1: 0] dbus_awlock;
    logic [ 3: 0] dbus_awcache;
    logic [ 2: 0] dbus_awprot;
    logic         dbus_awvalid;
    logic         dbus_awready;
    logic [ 3: 0] dbus_wid;
    logic [31: 0] dbus_wdata;
    logic [ 3: 0] dbus_wstrb;
    logic         dbus_wlast;
    logic         dbus_wvalid;
    logic         dbus_wready;
    logic [ 3: 0] dbus_bid;
    logic [ 1: 0] dbus_bresp;
    logic         dbus_bvalid;
    logic         dbus_bready;

// Uncache icache
    logic [ 3: 0] uibus_arid;
    logic [31: 0] uibus_araddr;
    logic [ 3: 0] uibus_arlen;
    logic [ 2: 0] uibus_arsize;
    logic [ 1: 0] uibus_arburst;
    logic [ 1: 0] uibus_arlock;
    logic [ 3: 0] uibus_arcache;
    logic [ 2: 0] uibus_arprot;
    logic         uibus_arvalid;
    logic         uibus_arready;
    logic [ 3: 0] uibus_rid;
    logic [31: 0] uibus_rdata;
    logic [ 1: 0] uibus_rresp;
    logic         uibus_rlast;
    logic         uibus_rvalid;
    logic         uibus_rready;
    logic [ 3: 0] uibus_awid;
    logic [31: 0] uibus_awaddr;
    logic [ 3: 0] uibus_awlen;
    logic [ 2: 0] uibus_awsize;
    logic [ 1: 0] uibus_awburst;
    logic [ 1: 0] uibus_awlock;
    logic [ 3: 0] uibus_awcache;
    logic [ 2: 0] uibus_awprot;
    logic         uibus_awvalid;
    logic         uibus_awready;
    logic [ 3: 0] uibus_wid;
    logic [31: 0] uibus_wdata;
    logic [ 3: 0] uibus_wstrb;
    logic         uibus_wlast;
    logic         uibus_wvalid;
    logic         uibus_wready;
    logic [ 3: 0] uibus_bid;
    logic [ 1: 0] uibus_bresp;
    logic         uibus_bvalid;
    logic         uibus_bready;

// Uncache 
    logic [ 3: 0] udbus_arid;
    logic [31: 0] udbus_araddr;
    logic [ 3: 0] udbus_arlen;
    logic [ 2: 0] udbus_arsize;
    logic [ 1: 0] udbus_arburst;
    logic [ 1: 0] udbus_arlock;
    logic [ 3: 0] udbus_arcache;
    logic [ 2: 0] udbus_arprot;
    logic         udbus_arvalid;
    logic         udbus_arready;
    logic [ 3: 0] udbus_rid;
    logic [31: 0] udbus_rdata;
    logic [ 1: 0] udbus_rresp;
    logic         udbus_rlast;
    logic         udbus_rvalid;
    logic         udbus_rready;
    logic [ 3: 0] udbus_awid;
    logic [31: 0] udbus_awaddr;
    logic [ 3: 0] udbus_awlen;
    logic [ 2: 0] udbus_awsize;
    logic [ 1: 0] udbus_awburst;
    logic [ 1: 0] udbus_awlock;
    logic [ 3: 0] udbus_awcache;
    logic [ 2: 0] udbus_awprot;
    logic         udbus_awvalid;
    logic         udbus_awready;
    logic [ 3: 0] udbus_wid;
    logic [31: 0] udbus_wdata;
    logic [ 3: 0] udbus_wstrb;
    logic         udbus_wlast;
    logic         udbus_wvalid;
    logic         udbus_wready;
    logic [ 3: 0] udbus_bid;
    logic [ 1: 0] udbus_bresp;
    logic         udbus_bvalid;
    logic         udbus_bready;
    //cache 状态机d
    typedef enum logic[3:0] { 
        IDLE,
        REQ,
        WAIT,
        FINISH
    }cache_rd_t;//通用的cache

    typedef enum logic[3:0] { 
        WB_IDLE,
        WB_REQ,
        WB_WAIT,
        WB_WAIT_RESP,
        WB_FINISH
    }cache_wb_t;//通用的写回cache 实际上只用dcache使用

    typedef enum logic[3:0] { 
        UNCACHE_IDLE,
        UNCACHE_RD,
        UNCACHE_WB,
        UNCACHE_WAIT_RD,
        UNCACHE_WAIT_WB,
        UNCACHE_WAIT_WBRESP,
        UNCACHE_FINISH
    } uncache_t;//通用的uncache机制 icache可能读 dcache会读会写



//TODO: 如果要实现预取 在这边改×2
    localparam int  ICACHE_CNT_WIDTH = $clog2(ICACHE_LINE_SIZE);//icache的计数器的位宽 
    localparam int  DCACHE_CNT_WIDTH = $clog2(DCACHE_LINE_SIZE);//dcache的计数器的位宽

    cache_rd_t istate,istate_next;//icache 读状态机
    cache_rd_t dstate,dstate_next;//dcache 读状态机
    
//  cache_wb_t istate_wb,istate_wb_next;
    cache_wb_t dstate_wb,dstate_wb_next;

//  uncache_t istate_uncache,istate_uncache_next; 暂时不实现 icache的uncache
    uncache_t dstate_uncache,dstate_uncache_next;
    uncache_t istate_uncache,istate_uncache_next;

    logic [ICACHE_CNT_WIDTH-1:0] iburst_cnt,iburst_cnt_next;//读计数器
    logic [DCACHE_CNT_WIDTH-1:0] dburst_cnt,dburst_cnt_next;//dcache计数器

    logic [DCACHE_CNT_WIDTH-1:0] wb_dburst_cnt,wb_dburst_cnt_next;//写计数器
//TODO: 如果要实现预取 这边下面的line_recv*2
//icache读 使用数据
    logic [31:0] icache_rd_addr;
    logic [ICACHE_LINE_SIZE-1:0][31:0] icache_line_recv;// 读的块大小为两倍的cache line size
//dcache读 使用数据
    logic [31:0] dcache_rd_addr;
    logic [DCACHE_LINE_SIZE-1:0][31:0] dcache_line_recv;
//dcache写 使用数据
    logic [31:0] dcache_wb_addr;
    logic [DCACHE_LINE_SIZE-1:0][31:0] dcache_line_wb;
//uncache读写 使用数据
    logic [31:0] uncache_addr_rd;
    logic [31:0] uncache_addr_wb;
    logic [31:0] uncache_line_rd;
    logic [31:0] uncache_line_wb;
    logic [3:0]    uncache_wstrb;
    LoadType    uncache_loadType; 
//uncache读 读取数据
    logic [31:0] uncache_i_addr;
    logic [31:0] uncache_i_line;

    always_ff @( posedge clk ) begin : istate_block
        if (resetn == `RstEnable) begin
            istate <= IDLE;
        end else begin
            istate <= istate_next;
        end
        
    end
    
    always_comb begin : istate_next_block
        unique case (istate)
            IDLE:begin
                if (ibus.rd_req) begin
                    istate_next = REQ;
                end else begin
                    istate_next = IDLE;
                end
            end
            REQ:begin
                if (ibus_arready) begin
                    istate_next = WAIT;
                end else begin
                    istate_next = REQ;
                end
            end
            WAIT:begin
                if (ibus_rlast &ibus_rvalid) begin
                    istate_next = FINISH;
                end else begin
                    istate_next = WAIT;
                end
            end
            FINISH:begin
                istate_next =IDLE;
            end
            default:begin
                istate_next = IDLE;
            end
        endcase
    end

// icache读计数器  如果不在req状态计数器将清零
    always_ff @(posedge clk ) begin : iburst_cnt_block
        if (resetn == `RstEnable | istate==REQ ) begin
            iburst_cnt <= '0;
        end else begin
            iburst_cnt <= iburst_cnt_next;
        end
    end

    always_comb begin : iburst_cnt_next_block
        if (ibus_rvalid) begin
            iburst_cnt_next = iburst_cnt +1;
        end else begin
            iburst_cnt_next = iburst_cnt;
        end
    end
//对于icache读地址的控制
    always_ff @(posedge clk ) begin : icache_rd_addr_block
        if (resetn == `RstEnable) begin
            icache_rd_addr <='0;
        end else if (~(istate == IDLE)) begin
            icache_rd_addr <= icache_rd_addr;
        end else begin
            icache_rd_addr <= ibus.rd_addr;
        end
    end
//对于icache读出数据的锁存
    always_ff @(posedge clk ) begin : icache_line_recv_block
        if (resetn == `RstEnable) begin
            icache_line_recv <='0;
        end else begin
            icache_line_recv[iburst_cnt] <= ibus_rdata;
        end
    end

//********************* ibus ******************/
    // master -> slave
    assign ibus_arid      = '0;
    assign ibus_arlen     = ICACHE_LINE_SIZE-1;      // 传输4拍
    assign ibus_arsize    = 3'b010;       // 每次传输4字节
    assign ibus_arburst   = 2'b01;
    assign ibus_arlock    = '0;
    assign ibus_arcache   = '1;
    assign ibus_arprot    = '0;
    

    // master -> slave
    assign ibus_awid      = 4'h1;           
    assign ibus_awlen     = '0;
    assign ibus_awsize    = '0;
    assign ibus_awburst   = '0;
    assign ibus_awlock    = '0;
    assign ibus_awcache   = '1;
    assign ibus_awprot    = '0;
    assign ibus_awvalid   = '0;
    assign ibus_awaddr    = '0;
    // master -> slave
    assign ibus_wid       = '0;
    assign ibus_wdata     = '0;
    assign ibus_wstrb     = '0;
    assign ibus_wlast     = '0;
    assign ibus_wvalid    = '0;
    assign ibus_bready    = '0;
    //发送命令
    assign ibus_arvalid   = (istate == REQ) ? 1'b1 : 1'b0;
    assign ibus_araddr    = icache_rd_addr;
    assign ibus_rready    = (istate == WAIT) ? 1'b1 : 1'b0;

    //ibus上的赋值
    assign ibus.ret_valid = (istate == FINISH) ? 1'b1 : 1'b0;
    assign ibus.ret_data  = icache_line_recv;


//dcache读状态机
     always_ff @( posedge clk ) begin : dstate_block
        if (resetn == `RstEnable) begin
            dstate <= IDLE;
        end else begin
            dstate <= dstate_next;
        end
        
    end
    
    always_comb begin : dstate_next_block
        unique case (dstate)
            IDLE:begin
                if (dbus.rd_req ) begin//TODO:增加了条件
                    dstate_next = REQ;
                end else begin
                    dstate_next = IDLE;
                end
            end
            REQ:begin
                if (dbus_arready) begin
                    dstate_next = WAIT;
                end else begin
                    dstate_next = REQ;
                end
            end
            WAIT:begin
                if (dbus_rlast &dbus_rvalid) begin
                    dstate_next = FINISH;
                end else begin
                    dstate_next = WAIT;
                end
            end
            FINISH:begin
                dstate_next =IDLE;
            end
            default:begin
                dstate_next = IDLE;
            end
        endcase
    end

// icache读计数器  如果不在req状态计数器将清零
    always_ff @(posedge clk ) begin : dburst_cnt_block
        if (resetn == `RstEnable || dstate==REQ ) begin
            dburst_cnt <= '0;
        end else begin
            dburst_cnt <= dburst_cnt_next;
        end
    end

    always_comb begin : dburst_cnt_next_block
        if (dbus_rvalid) begin
            dburst_cnt_next = dburst_cnt +1;
        end else begin
            dburst_cnt_next = dburst_cnt;
        end
    end
//对于dcache读地址的控制
    always_ff @(posedge clk ) begin : dcache_rd_addr_block
        if (resetn == `RstEnable) begin
            dcache_rd_addr <='0;
        end else if (~(dstate == IDLE)) begin
            dcache_rd_addr <= dcache_rd_addr;
        end else begin
            dcache_rd_addr <= dbus.rd_addr;
        end
    end
//对于dcache读出数据的锁存
    always_ff @(posedge clk ) begin : dcache_line_recv_block
        if (resetn == `RstEnable) begin
            dcache_line_recv <='0;
        end else begin
            dcache_line_recv[dburst_cnt] <= dbus_rdata;
        end
    end
/********************* dbus ******************/
    assign dbus_arid      = 4'h2;//TODO: 在有写缓冲的情况下 需要考虑id
    assign dbus_arlen     = DCACHE_LINE_SIZE-1;//一次读两个cache line
    assign dbus_arsize    = 3'b010;
    assign dbus_arburst   = 2'b01;
    assign dbus_arlock    = '0;
    assign dbus_arcache   = '1;
    assign dbus_arprot    = '0;


    assign dbus_awid      = 4'h3;
    assign dbus_awlen     = DCACHE_LINE_SIZE-1;        // 写的话还是一块一块写
    assign dbus_awsize    = 3'b010;         // 传输32bit 
    assign dbus_awburst   = 2'b01;          // increase模式
    assign dbus_awlock    = '0;
    assign dbus_awcache   = '1;
    assign dbus_awprot    = '0;


    assign dbus_wid       = 4'b0001;
    assign dbus_wstrb     = 4'b1111;
    assign dbus_bready    = 1'b1;

    //发送命令
    assign dbus_arvalid   = (dstate == REQ) ? 1'b1 :1'b0;
    assign dbus_araddr    = dcache_rd_addr;
    assign dbus_rready    = (dstate == WAIT) ? 1'b1 : 1'b0;
    assign dbus_wdata     = dcache_line_wb[wb_dburst_cnt];
    assign dbus_wlast     = (wb_dburst_cnt == { (DCACHE_CNT_WIDTH) {1'b1} } ) ? 1'b1 : 1'b0;
    assign dbus_awvalid   = (dstate_wb== WB_REQ)?1'b1:1'b0;
    assign dbus_awaddr    = dcache_wb_addr;
    assign dbus_wvalid    = (dstate_wb== WB_WAIT)?1'b1:1'b0;;
    //dbus上的赋值
    assign dbus.ret_valid = (dstate == FINISH)? 1'b1:1'b0;
    assign dbus.ret_data  = dcache_line_recv;
    assign dbus.wr_valid  = (dstate_wb == WB_FINISH)? 1'b1 :1'b0; 

//dcache写状态机 因为write buffer的存在 所以没法和uncache共用一个通道
    always_ff @( posedge clk ) begin : dstate_wb_block
        if (resetn == `RstEnable) begin
            dstate_wb <=  WB_IDLE;
        end else begin
            dstate_wb <= dstate_wb_next;
        end
    end

    always_comb begin : dstate_wb_next_block
        unique case (dstate_wb)
            WB_IDLE:begin
                if (dbus.wr_req && dbus.wr_rdy ) begin
                    dstate_wb_next = WB_REQ;
                end else begin
                    dstate_wb_next = WB_IDLE;
                end
            end
            WB_REQ:begin
                if (dbus_awready ) begin
                    dstate_wb_next = WB_WAIT;
                end else begin
                    dstate_wb_next = WB_REQ;
                end
            end
            WB_WAIT:begin
                if (dbus_wready == 1'b1 && dbus_wlast == 1'b1 ) begin
                    dstate_wb_next = WB_WAIT_RESP;
                end else begin
                    dstate_wb_next = WB_WAIT;
                end
            end
            WB_WAIT_RESP:begin
                if (dbus_bvalid) begin
                    dstate_wb_next = WB_FINISH;
                end else begin
                    dstate_wb_next = WB_WAIT_RESP;
                end
            end
            WB_FINISH:begin
                dstate_wb_next = WB_IDLE;
            end
            default:begin
                dstate_wb_next = WB_IDLE;
            end
        endcase
    end

//dcache 写计数器 如果不在req状态 计数器将被清零
    always_ff @( posedge clk ) begin : wb_dburst_cnt_block
        if (resetn == `RstEnable | dstate_wb==WB_REQ) begin
            wb_dburst_cnt <= '0;
        end else begin
            wb_dburst_cnt <= wb_dburst_cnt_next;
        end
    end

    always_comb begin : wb_dburst_cnt_next_block
        if (dbus_wready) begin
            wb_dburst_cnt_next = wb_dburst_cnt + 1;
        end else begin
            wb_dburst_cnt_next = wb_dburst_cnt;
        end
    end
//对dcache写地址的控制
    always_ff @( posedge clk ) begin : dcache_wb_addr_block
        if (resetn == `RstEnable) begin
            dcache_wb_addr <='0;
        end else if(~(dstate_wb == WB_IDLE)) begin
            dcache_wb_addr <= dcache_wb_addr;
        end else begin
            dcache_wb_addr <= dbus.wr_addr;
        end
    end
//对于dcache 写数据的控制
    always_ff @(posedge clk ) begin
        if (resetn == `RstEnable) begin
            dcache_line_wb <= '0;
        end else if(~(dstate_wb == WB_IDLE)) begin
            dcache_line_wb <= dcache_line_wb;
        end else begin
            dcache_line_wb <= dbus.wr_data;
        end
    end
/********************* uibus ******************/
    assign uibus_arid     = 4'h4;
    assign uibus_arlen    = 4'b0000; // 传输事件只有一个
    // assign ubus_arsize   = 3'b010; // 4字节
    assign uibus_arsize   = 3'b010;//lw          // 根据LB LH LW调整Uncache的arsize  
    assign uibus_arburst  = 2'b01;
    assign uibus_arlock   = '0;
    assign uibus_arcache  = '0;
    assign uibus_arprot   = '0;


    assign uibus_awid     = 4'h5;
    assign uibus_awlen    = 4'b0000;        // 传输1次
    assign uibus_awsize   = 3'b010;         // 传输32bit 
    assign uibus_awburst  = 2'b01;          // increase模式
    assign uibus_awlock   = '0;
    assign uibus_awcache  = '0;
    assign uibus_awprot   = '0;


    assign uibus_wid      = 4'b0001;
    assign uibus_wstrb    = '0;  // 使用所存下来的信号。以支持uncache的SB
    assign uibus_bready   = 1'b1;
 
    assign uibus_arvalid  = (istate_uncache==UNCACHE_RD)? 1'b1:1'b0;
    assign uibus_araddr   = uncache_i_addr;
    assign uibus_rready   = (istate_uncache==UNCACHE_WAIT_RD)? 1'b1:1'b0;

    assign uibus_wlast    = (istate_uncache==UNCACHE_WAIT_WB)? 1'b1:1'b0;
    assign uibus_wdata    = '0;
    assign uibus_awvalid  = (istate_uncache==UNCACHE_WB)?1'b1:1'b0;
    assign uibus_awaddr   = '0;
    assign uibus_wvalid   = (istate_uncache==UNCACHE_WAIT_WB)?1'b1:1'b0;

    //uibus的赋值
    assign uibus.wr_valid = (istate_uncache==UNCACHE_FINISH)?1'b1:1'b0;
    assign uibus.ret_valid= (istate_uncache==UNCACHE_FINISH)?1'b1:1'b0;
    assign uibus.ret_data = uncache_i_line;
/********************* udbus ******************/
    assign udbus_arid     = 4'h6;
    assign udbus_arlen    = 4'b0000; // 传输事件只有一个
    // assign ubus_arsize   = 3'b010; // 4字节
    assign udbus_arsize   = (udbus.loadType.size == 2'b10) ? 3'b000: // lb
                           (udbus.loadType.size == 2'b01) ? 3'b001: // lh
                           3'b010;//lw          // 根据LB LH LW调整Uncache的arsize  
    assign udbus_arburst  = 2'b01;
    assign udbus_arlock   = '0;
    assign udbus_arcache  = '0;
    assign udbus_arprot   = '0;


    assign udbus_awid     = 4'h6;
    assign udbus_awlen    = 4'b0000;        // 传输1次
    assign udbus_awsize   = 3'b010;         // 传输32bit 
    assign udbus_awburst  = 2'b01;          // increase模式
    assign udbus_awlock   = '0;
    assign udbus_awcache  = '0;
    assign udbus_awprot   = '0;


    assign udbus_wid      = 4'b0001;
    assign udbus_wstrb    = uncache_wstrb;  // 使用所存下来的信号。以支持uncache的SB
    assign udbus_bready   = 1'b1;
 
    assign udbus_arvalid  = (dstate_uncache==UNCACHE_RD)? 1'b1:1'b0;
    assign udbus_araddr   = uncache_addr_rd;
    assign udbus_rready   = (dstate_uncache==UNCACHE_WAIT_RD)? 1'b1:1'b0;

    assign udbus_wlast    = (dstate_uncache==UNCACHE_WAIT_WB)? 1'b1:1'b0;
    assign udbus_wdata    = uncache_line_wb;
    assign udbus_awvalid  = (dstate_uncache==UNCACHE_WB)?1'b1:1'b0;
    assign udbus_awaddr   = uncache_addr_wb;
    assign udbus_wvalid   = (dstate_uncache==UNCACHE_WAIT_WB)?1'b1:1'b0;

    //udbus的赋值
    assign udbus.wr_valid = (dstate_uncache==UNCACHE_FINISH)?1'b1:1'b0;
    assign udbus.ret_valid= (dstate_uncache==UNCACHE_FINISH)?1'b1:1'b0;
    assign udbus.ret_data = uncache_line_rd;


    //空闲信号的输出
    assign ibus.rd_rdy  = (istate == IDLE) ? 1'b1 : 1'b0;
    // assign ibus.wr_rdy  = 1'b0;
    assign dbus.rd_rdy  = (dstate == IDLE) ? 1'b1 : 1'b0;
    assign dbus.wr_rdy  = (dstate_wb == WB_IDLE) ? 1'b1 : 1'b0;
    assign udbus.rd_rdy = (dstate_uncache == UNCACHE_IDLE && udbus.wr_req == 1'b0 ) ? 1'b1 : 1'b0;
    assign udbus.wr_rdy = (dstate_uncache == UNCACHE_IDLE ) ? 1'b1 : 1'b0;
    assign uibus.rd_rdy = (istate_uncache == UNCACHE_IDLE ) ? 1'b1 : 1'b0;
    assign uibus.wr_rdy = 1'b0;

    always_ff @( posedge clk ) begin : istate_uncache_block_blockName
        if (resetn == `RstEnable) begin
            istate_uncache <=UNCACHE_IDLE;
        end else begin
            istate_uncache <= istate_uncache_next;
        end 
    end

    always_comb begin : istate_uncache_next_block
        unique case (istate_uncache)
            UNCACHE_IDLE:begin
                if (uibus.rd_req | uibus.wr_req) begin
                    if (uibus.rd_req) begin
                        istate_uncache_next =UNCACHE_RD;
                    end else begin
                        istate_uncache_next =UNCACHE_WB;
                    end
                end else begin
                    istate_uncache_next =UNCACHE_IDLE;
                end
            end 
            UNCACHE_RD:begin//发起读请求
                if (uibus_arready ) begin
                    istate_uncache_next =UNCACHE_WAIT_RD;
                end else begin
                    istate_uncache_next =UNCACHE_RD;
                end
            end
            UNCACHE_WB:begin//发起写请求
                if (uibus_awready ) begin
                    istate_uncache_next =UNCACHE_WAIT_WB;
                end else begin
                    istate_uncache_next =UNCACHE_WB;
                end                
            end
            UNCACHE_WAIT_RD:begin
                if (uibus_rvalid) begin
                    istate_uncache_next = UNCACHE_FINISH;
                end else begin
                    istate_uncache_next = UNCACHE_WAIT_RD;
                end
            end
            UNCACHE_WAIT_WB:begin
                if (uibus_wready) begin
                    istate_uncache_next = UNCACHE_WAIT_WBRESP;
                end else begin
                    istate_uncache_next = UNCACHE_WAIT_WB;
                end                
            end
            UNCACHE_WAIT_WBRESP:begin
                if (uibus_bvalid) begin
                    istate_uncache_next = UNCACHE_FINISH;
                end else begin
                    istate_uncache_next = UNCACHE_WAIT_WBRESP;
                end                    
            end
            UNCACHE_FINISH:begin
                istate_uncache_next = UNCACHE_IDLE;
            end
            default:begin
                istate_uncache_next = UNCACHE_IDLE;
            end
        endcase
    end


    always_ff @( posedge clk ) begin : dstate_uncache_block
        if (resetn == `RstEnable) begin
            dstate_uncache <=UNCACHE_IDLE;
        end else begin
            dstate_uncache <= dstate_uncache_next;
        end
    end

    always_comb begin : dstate_uncache_next_block
        unique case (dstate_uncache)
            UNCACHE_IDLE:begin
                if (udbus.rd_req | udbus.wr_req) begin
                    if (udbus.wr_req) begin
                        dstate_uncache_next =UNCACHE_WB;
                    end else if(udbus.rd_rdy)begin
                        dstate_uncache_next =UNCACHE_RD;
                    end
                    else begin
                        dstate_uncache_next =UNCACHE_IDLE;
                    end
                end else begin
                    dstate_uncache_next =UNCACHE_IDLE;
                end
            end 
            UNCACHE_RD:begin//发起读请求
                if (udbus_arready ) begin
                    dstate_uncache_next =UNCACHE_WAIT_RD;
                end else begin
                    dstate_uncache_next =UNCACHE_RD;
                end
            end
            UNCACHE_WB:begin//发起写请求
                if (udbus_awready ) begin
                    dstate_uncache_next =UNCACHE_WAIT_WB;
                end else begin
                    dstate_uncache_next =UNCACHE_WB;
                end                
            end
            UNCACHE_WAIT_RD:begin
                if (udbus_rvalid) begin
                    dstate_uncache_next = UNCACHE_FINISH;
                end else begin
                    dstate_uncache_next = UNCACHE_WAIT_RD;
                end
            end
            UNCACHE_WAIT_WB:begin
                if (udbus_wready) begin
                    dstate_uncache_next = UNCACHE_WAIT_WBRESP;
                end else begin
                    dstate_uncache_next = UNCACHE_WAIT_WB;
                end                
            end
            UNCACHE_WAIT_WBRESP:begin
                if (udbus_bvalid) begin
                    dstate_uncache_next = UNCACHE_FINISH;
                end else begin
                    dstate_uncache_next = UNCACHE_WAIT_WBRESP;
                end                    
            end
            UNCACHE_FINISH:begin
                dstate_uncache_next = UNCACHE_IDLE;
            end
            default:begin
                dstate_uncache_next = UNCACHE_IDLE;
            end
        endcase
    end

    always_ff @( posedge clk ) begin : uncache_i_addr_blockName
        if (resetn == `RstEnable) begin
            uncache_i_addr <= '0;
        end else if(istate_uncache != UNCACHE_IDLE)begin
            uncache_i_addr <= uncache_i_addr;
        end else begin
            uncache_i_addr <= uibus.rd_addr;
        end
    end

    //对于uncache_addr_rd
    always_ff @( posedge clk ) begin : uncache_addr_rd_block
        if (resetn == `RstEnable ) begin
            uncache_addr_rd <= '0;
        end else if(dstate_uncache != UNCACHE_IDLE)begin
            uncache_addr_rd <= uncache_addr_rd;
        end else begin
            uncache_addr_rd <= udbus.rd_addr;
        end
    end

    //对于uncache_line_wb
    always_ff @( posedge clk ) begin : uncache_line_wb_block
        if (resetn == `RstEnable) begin
            uncache_line_wb <= '0;
        end else if(dstate_uncache != UNCACHE_IDLE)begin
            uncache_line_wb <= uncache_line_wb;
        end else begin
            uncache_line_wb <= udbus.wr_data;
        end
    end

    //对于uncache_addr_wb
    always_ff @( posedge clk ) begin : uncache_addr_wb_block
        if (resetn == `RstEnable) begin
            uncache_addr_wb <= '0;
        end else if(dstate_uncache != UNCACHE_IDLE)begin
            uncache_addr_wb <= uncache_addr_wb;
        end else begin
            uncache_addr_wb <= udbus.wr_addr;
        end        
    end
    //对于uncache_wstrb
    always_ff @( posedge clk ) begin : uncache_wstrb_block
        if (resetn == `RstEnable) begin
            uncache_wstrb <= '0;
        end else if(dstate_uncache != UNCACHE_IDLE)begin
            uncache_wstrb <= uncache_wstrb;
        end else begin
            uncache_wstrb <= udbus.wr_wstrb;
        end           
    end
    //对于uncache_line_rd
    always_ff @( posedge clk ) begin : uncache_line_rd_block
         if (resetn == `RstEnable) begin
            uncache_line_rd <= '0;
        end else if(dstate_uncache != UNCACHE_WAIT_RD)begin
            uncache_line_rd <= uncache_line_rd;
        end else begin
            uncache_line_rd <= udbus_rdata;
        end        
    end
    always_ff @( posedge clk ) begin : uncache_i_line_blockName
        if (resetn == `RstEnable) begin
            uncache_i_line <= 0;
        end else if(istate_uncache != UNCACHE_WAIT_RD)begin
            uncache_i_line <= uncache_i_line;
        end else begin
            uncache_i_line <= uibus_rdata;
        end
    end


    axi_crossbar_cache biu (//TODO: ICACHE 的UNCACHE尚未实现
        .aclk             ( clk     ),
        .aresetn          ( resetn        ),
        
        .s_axi_arid       ( {ibus_arid   ,dbus_arid    ,udbus_arid      , uibus_arid  } ),
        .s_axi_araddr     ( {ibus_araddr ,dbus_araddr  ,udbus_araddr    , uibus_araddr} ),
        .s_axi_arlen      ( {ibus_arlen  ,dbus_arlen   ,udbus_arlen     , uibus_arlen } ),
        .s_axi_arsize     ( {ibus_arsize ,dbus_arsize  ,udbus_arsize    , uibus_arsize} ),
        .s_axi_arburst    ( {ibus_arburst,dbus_arburst ,udbus_arburst   , uibus_arburst} ),
        .s_axi_arlock     ( {ibus_arlock ,dbus_arlock  ,udbus_arlock    , uibus_arlock} ),
        .s_axi_arcache    ( {ibus_arcache,dbus_arcache ,udbus_arcache   , uibus_arcache} ),
        .s_axi_arprot     ( {ibus_arprot ,dbus_arprot  ,udbus_arprot    , uibus_arprot} ),
        .s_axi_arqos      ( 0                                         ),
        .s_axi_arvalid    ( {ibus_arvalid,dbus_arvalid ,udbus_arvalid   ,uibus_arvalid} ),
        .s_axi_arready    ( {ibus_arready,dbus_arready ,udbus_arready   ,uibus_arready} ),
        .s_axi_rid        ( {ibus_rid    ,dbus_rid     ,udbus_rid       ,uibus_rid    } ),
        .s_axi_rdata      ( {ibus_rdata  ,dbus_rdata   ,udbus_rdata     ,uibus_rdata  } ),
        .s_axi_rresp      ( {ibus_rresp  ,dbus_rresp   ,udbus_rresp     ,uibus_rresp  } ),
        .s_axi_rlast      ( {ibus_rlast  ,dbus_rlast   ,udbus_rlast     ,uibus_rlast  } ),
        .s_axi_rvalid     ( {ibus_rvalid ,dbus_rvalid  ,udbus_rvalid    ,uibus_rvalid } ),
        .s_axi_rready     ( {ibus_rready ,dbus_rready  ,udbus_rready    ,uibus_rready } ),
        .s_axi_awid       ( {ibus_awid   ,dbus_awid    ,udbus_awid      ,uibus_awid   } ),
        .s_axi_awaddr     ( {ibus_awaddr ,dbus_awaddr  ,udbus_awaddr    ,uibus_awaddr } ),
        .s_axi_awlen      ( {ibus_awlen  ,dbus_awlen   ,udbus_awlen     ,uibus_awlen  } ),
        .s_axi_awsize     ( {ibus_awsize ,dbus_awsize  ,udbus_awsize    ,uibus_awsize } ),
        .s_axi_awburst    ( {ibus_awburst,dbus_awburst ,udbus_awburst   ,uibus_awburst} ),
        .s_axi_awlock     ( {ibus_awlock ,dbus_awlock  ,udbus_awlock    ,uibus_awlock } ),
        .s_axi_awcache    ( {ibus_awcache,dbus_awcache ,udbus_awcache   ,uibus_awcache} ),
        .s_axi_awprot     ( {ibus_awprot ,dbus_awprot  ,udbus_awprot    ,uibus_awprot } ),
        .s_axi_awqos      ( 0                                         ),
        .s_axi_awvalid    ( {ibus_awvalid,dbus_awvalid ,udbus_awvalid   ,uibus_awvalid} ),
        .s_axi_awready    ( {ibus_awready,dbus_awready ,udbus_awready   ,uibus_awready} ),
        .s_axi_wid        ( {ibus_wid    ,dbus_wid     ,udbus_wid       ,uibus_wid    } ),
        .s_axi_wdata      ( {ibus_wdata  ,dbus_wdata   ,udbus_wdata     ,uibus_wdata  } ),
        .s_axi_wstrb      ( {ibus_wstrb  ,dbus_wstrb   ,udbus_wstrb     ,uibus_wstrb  } ),
        .s_axi_wlast      ( {ibus_wlast  ,dbus_wlast   ,udbus_wlast     ,uibus_wlast  } ),
        .s_axi_wvalid     ( {ibus_wvalid ,dbus_wvalid  ,udbus_wvalid    ,uibus_wvalid } ),
        .s_axi_wready     ( {ibus_wready ,dbus_wready  ,udbus_wready    ,uibus_wready } ),
        .s_axi_bid        ( {ibus_bid    ,dbus_bid     ,udbus_bid       ,uibus_bid    } ),
        .s_axi_bresp      ( {ibus_bresp  ,dbus_bresp   ,udbus_bresp     ,uibus_bresp  } ),
        .s_axi_bvalid     ( {ibus_bvalid ,dbus_bvalid  ,udbus_bvalid    ,uibus_bvalid } ),
        .s_axi_bready     ( {ibus_bready ,dbus_bready  ,udbus_bready    ,uibus_bready } ),
        
        .m_axi_arid       ( m_axi_arid          ),
        .m_axi_araddr     ( m_axi_araddr        ),
        .m_axi_arlen      ( m_axi_arlen         ),
        .m_axi_arsize     ( m_axi_arsize        ),
        .m_axi_arburst    ( m_axi_arburst       ),
        .m_axi_arlock     ( m_axi_arlock        ),
        .m_axi_arcache    ( m_axi_arcache       ),
        .m_axi_arprot     ( m_axi_arprot        ),
        .m_axi_arqos      (                     ),
        .m_axi_arvalid    ( m_axi_arvalid       ),
        .m_axi_arready    ( m_axi_arready       ),
        .m_axi_rid        ( m_axi_rid           ),
        .m_axi_rdata      ( m_axi_rdata         ),
        .m_axi_rresp      ( m_axi_rresp         ),
        .m_axi_rlast      ( m_axi_rlast         ),
        .m_axi_rvalid     ( m_axi_rvalid        ),
        .m_axi_rready     ( m_axi_rready        ),
        .m_axi_awid       ( m_axi_awid          ),
        .m_axi_awaddr     ( m_axi_awaddr        ),
        .m_axi_awlen      ( m_axi_awlen         ),
        .m_axi_awsize     ( m_axi_awsize        ),
        .m_axi_awburst    ( m_axi_awburst       ),
        .m_axi_awlock     ( m_axi_awlock        ),
        .m_axi_awcache    ( m_axi_awcache       ),
        .m_axi_awprot     ( m_axi_awprot        ),
        .m_axi_awqos      (                     ),
        .m_axi_awvalid    ( m_axi_awvalid       ),
        .m_axi_awready    ( m_axi_awready       ),
        .m_axi_wid        ( m_axi_wid           ),
        .m_axi_wdata      ( m_axi_wdata         ),
        .m_axi_wstrb      ( m_axi_wstrb         ),
        .m_axi_wlast      ( m_axi_wlast         ),
        .m_axi_wvalid     ( m_axi_wvalid        ),
        .m_axi_wready     ( m_axi_wready        ),
        .m_axi_bid        ( m_axi_bid           ),
        .m_axi_bresp      ( m_axi_bresp         ),
        .m_axi_bvalid     ( m_axi_bvalid        ),
        .m_axi_bready     ( m_axi_bready        )
    );


endmodule

`endif 

`ifndef NEW_BRIDGE
module AXIInteract(
    input logic clk,
    input logic resetn,
    AXI_Bus_Interface  DcacheAXIBus,  // AXI模块向外输出的接口
    AXI_Bus_Interface  IcacheAXIBus,  // AXI模块向外输出的接口
    AXI_UNCACHE_Interface UncacheAXIBus,

    output logic [ 3: 0] m_axi_arid,
    output logic [31: 0] m_axi_araddr,
    output logic [ 3: 0] m_axi_arlen,
    output logic [ 2: 0] m_axi_arsize,
    output logic [ 1: 0] m_axi_arburst,
    output logic [ 1: 0] m_axi_arlock,
    output logic [ 3: 0] m_axi_arcache,
    output logic [ 2: 0] m_axi_arprot,
    output logic         m_axi_arvalid,
    input  logic         m_axi_arready,
    input  logic [ 3: 0] m_axi_rid,
    input  logic [31: 0] m_axi_rdata,
    input  logic [ 1: 0] m_axi_rresp,
    input  logic         m_axi_rlast,
    input  logic         m_axi_rvalid,
    output logic         m_axi_rready,
    output logic [ 3: 0] m_axi_awid,
    output logic [31: 0] m_axi_awaddr,
    output logic [ 3: 0] m_axi_awlen,
    output logic [ 2: 0] m_axi_awsize,
    output logic [ 1: 0] m_axi_awburst,
    output logic [ 1: 0] m_axi_awlock,
    output logic [ 3: 0] m_axi_awcache,
    output logic [ 2: 0] m_axi_awprot,
    output logic         m_axi_awvalid,
    input  logic         m_axi_awready,
    output logic [ 3: 0] m_axi_wid,
    output logic [31: 0] m_axi_wdata,
    output logic [ 3: 0] m_axi_wstrb,
    output logic         m_axi_wlast,
    output logic         m_axi_wvalid,
    input  logic         m_axi_wready,
    input  logic [ 3: 0] m_axi_bid,
    input  logic [ 1: 0] m_axi_bresp,
    input  logic         m_axi_bvalid,
    output logic         m_axi_bready
  );

// Icache 
    logic [ 3: 0] ibus_arid;
    logic [31: 0] ibus_araddr;
    logic [ 3: 0] ibus_arlen;
    logic [ 2: 0] ibus_arsize;
    logic [ 1: 0] ibus_arburst;
    logic [ 1: 0] ibus_arlock;
    logic [ 3: 0] ibus_arcache;
    logic [ 2: 0] ibus_arprot;
    logic         ibus_arvalid;
    logic         ibus_arready;
    logic [ 3: 0] ibus_rid;
    logic [31: 0] ibus_rdata;
    logic [ 1: 0] ibus_rresp;
    logic         ibus_rlast;
    logic         ibus_rvalid;
    logic         ibus_rready;
    logic [ 3: 0] ibus_awid;
    logic [31: 0] ibus_awaddr;
    logic [ 3: 0] ibus_awlen;
    logic [ 2: 0] ibus_awsize;
    logic [ 1: 0] ibus_awburst;
    logic [ 1: 0] ibus_awlock;
    logic [ 3: 0] ibus_awcache;
    logic [ 2: 0] ibus_awprot;
    logic         ibus_awvalid;
    logic         ibus_awready;
    logic [ 3: 0] ibus_wid;
    logic [31: 0] ibus_wdata;
    logic [ 3: 0] ibus_wstrb;
    logic         ibus_wlast;
    logic         ibus_wvalid;
    logic         ibus_wready;
    logic [ 3: 0] ibus_bid;
    logic [ 1: 0] ibus_bresp;
    logic         ibus_bvalid;
    logic         ibus_bready;

// Dcache 
    logic [ 3: 0] dbus_arid;
    logic [31: 0] dbus_araddr;
    logic [ 3: 0] dbus_arlen;
    logic [ 2: 0] dbus_arsize;
    logic [ 1: 0] dbus_arburst;
    logic [ 1: 0] dbus_arlock;
    logic [ 3: 0] dbus_arcache;
    logic [ 2: 0] dbus_arprot;
    logic         dbus_arvalid;
    logic         dbus_arready;
    logic [ 3: 0] dbus_rid;
    logic [31: 0] dbus_rdata;
    logic [ 1: 0] dbus_rresp;
    logic         dbus_rlast;
    logic         dbus_rvalid;
    logic         dbus_rready;
    logic [ 3: 0] dbus_awid;
    logic [31: 0] dbus_awaddr;
    logic [ 3: 0] dbus_awlen;
    logic [ 2: 0] dbus_awsize;
    logic [ 1: 0] dbus_awburst;
    logic [ 1: 0] dbus_awlock;
    logic [ 3: 0] dbus_awcache;
    logic [ 2: 0] dbus_awprot;
    logic         dbus_awvalid;
    logic         dbus_awready;
    logic [ 3: 0] dbus_wid;
    logic [31: 0] dbus_wdata;
    logic [ 3: 0] dbus_wstrb;
    logic         dbus_wlast;
    logic         dbus_wvalid;
    logic         dbus_wready;
    logic [ 3: 0] dbus_bid;
    logic [ 1: 0] dbus_bresp;
    logic         dbus_bvalid;
    logic         dbus_bready;
// Uncache 
    logic [ 3: 0] ubus_arid;
    logic [31: 0] ubus_araddr;
    logic [ 3: 0] ubus_arlen;
    logic [ 2: 0] ubus_arsize;
    logic [ 1: 0] ubus_arburst;
    logic [ 1: 0] ubus_arlock;
    logic [ 3: 0] ubus_arcache;
    logic [ 2: 0] ubus_arprot;
    logic         ubus_arvalid;
    logic         ubus_arready;
    logic [ 3: 0] ubus_rid;
    logic [31: 0] ubus_rdata;
    logic [ 1: 0] ubus_rresp;
    logic         ubus_rlast;
    logic         ubus_rvalid;
    logic         ubus_rready;
    logic [ 3: 0] ubus_awid;
    logic [31: 0] ubus_awaddr;
    logic [ 3: 0] ubus_awlen;
    logic [ 2: 0] ubus_awsize;
    logic [ 1: 0] ubus_awburst;
    logic [ 1: 0] ubus_awlock;
    logic [ 3: 0] ubus_awcache;
    logic [ 2: 0] ubus_awprot;
    logic         ubus_awvalid;
    logic         ubus_awready;
    logic [ 3: 0] ubus_wid;
    logic [31: 0] ubus_wdata;
    logic [ 3: 0] ubus_wstrb;
    logic         ubus_wlast;
    logic         ubus_wvalid;
    logic         ubus_wready;
    logic [ 3: 0] ubus_bid;
    logic [ 1: 0] ubus_bresp;
    logic         ubus_bvalid;
    logic         ubus_bready;
    
    // I$ 读通道
    typedef enum logic [3:0] {
    I_RD_EMPTY ,
    I_RD_RECREQ,
    I_RD_WAIT1 ,
    I_RD_WAIT2 ,
    I_RD_WAIT3 ,
    I_RD_WAIT4 ,
    I_RD_FINISH
    } IcacheRD;

    // D$ 读通道
    typedef enum logic [3:0] {
    D_RD_EMPTY, 
    D_RD_RECREQ,
    D_RD_WAIT1, 
    D_RD_WAIT2, 
    D_RD_WAIT3, 
    D_RD_WAIT4, 
    D_RD_FINISH
    } DcacheRD;
 
    // D$ 写通道
    typedef enum logic [3:0] {
    D_WR_EMPTY, 
    D_WR_RECREQ,
    D_WR_WAIT1, 
    D_WR_WAIT2, 
    D_WR_WAIT3, 
    D_WR_WAIT4, 
    D_WR_S,     
    D_WR_FINISH
    } DcacheWR;
  
    // U$ 读通道
    typedef enum logic [2:0] {
    U_RD_EMPTY, 
    U_RD_RECREQ,
    U_RD_WAIT1, 
    U_RD_FINISH
    } UncacheRD;

    // U$ 写通道
    typedef enum logic [3:0] {
    U_WR_EMPTY, 
    U_WR_RECREQ,
    U_WR_WAIT1, 
    U_WR_S,     
    U_WR_FINISH
    } UncacheWR;

    IcacheRD      I_RD_pre_state;
    IcacheRD      I_RD_next_state;
    logic [2:0]   I_RD_DataReady;
    logic [31:0]  I_RD_Addr;
    logic [127:0] AXI_I_RData;
    // D$ 读通道
    DcacheRD      D_RD_pre_state;
    DcacheRD      D_RD_next_state;
    logic [2:0]   D_RD_DataReady;
    logic [31:0]  D_RD_Addr;
    logic [127:0] AXI_D_RData;
    // D$ 写通道
    DcacheWR      D_WR_pre_state;
    DcacheWR      D_WR_next_state;
    logic [31:0]  D_WR_Addr;
    logic [127:0] AXI_D_WData;

    // U$ 读通道
    UncacheRD      U_RD_pre_state;
    UncacheRD      U_RD_next_state;
    LoadType       U_RD_LoadType;
    logic [31:0]   U_RD_Addr;
    logic [31:0]   AXI_U_RData;
    // U$ 写通道
    logic [3:0]    U_WR_Wstrb;
    UncacheWR      U_WR_pre_state;
    UncacheWR      U_WR_next_state;

    logic [31:0]  U_WR_Addr;
    logic [31:0]  AXI_U_WData;
// 锁存请求时的数据
    // 锁存 I$ RD
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            I_RD_Addr <= '0;
        end 
        else begin  
            if (IcacheAXIBus.rd_req == 1'b1&& I_RD_pre_state == I_RD_EMPTY) begin
                I_RD_Addr <= IcacheAXIBus.rd_addr;
            end 
        end 
    end

    // 锁存 D$ RD
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            D_RD_Addr <= '0;
        end 
        else begin  
            if (DcacheAXIBus.rd_req == 1'b1 && D_RD_pre_state == D_RD_EMPTY) begin
                D_RD_Addr <= DcacheAXIBus.rd_addr;
            end
        end 
    end

    // 锁存 D$ WR
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            D_WR_Addr   <= '0;
            AXI_D_WData <= '0;
        end 
        else begin  
            if (DcacheAXIBus.wr_req && D_WR_pre_state == D_WR_EMPTY) begin
                D_WR_Addr   <= DcacheAXIBus.wr_addr;
                AXI_D_WData <= DcacheAXIBus.wr_data;
            end 
        end 
    end

    // 锁存 U$ RD
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            U_RD_Addr     <= '0;
            U_RD_LoadType <= '0;

        end 
        else begin  
            if (UncacheAXIBus.rd_req == 1'b1 && U_RD_pre_state == U_RD_EMPTY) begin
                U_RD_Addr     <= UncacheAXIBus.rd_addr;
                U_RD_LoadType <= UncacheAXIBus.loadType;
            end
        end 
    end

    // 锁存 U$ WR
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            U_WR_Addr   <= '0;
            AXI_U_WData <= '0;
            U_WR_Wstrb  <= '0;
        end 
        else begin  
            if (UncacheAXIBus.wr_req == 1'b1 && U_WR_pre_state == U_WR_EMPTY) begin
                U_WR_Addr   <= UncacheAXIBus.wr_addr;
                AXI_U_WData <= UncacheAXIBus.wr_data;
                U_WR_Wstrb  <= UncacheAXIBus.wr_wstrb;
            end 
        end 
    end

/********************* ibus ******************/
    // master -> slave
    assign ibus_arid     = 4'b0000;
    assign ibus_arlen    = 4'b0011;      // 传输4拍
    assign ibus_arsize   = 3'b010;       // 每次传输4字节
    assign ibus_arburst  = 2'b01;
    assign ibus_arlock   = 2'b00;
    assign ibus_arcache  = '0;
    assign ibus_arprot   = '0;
    

    // master -> slave
    assign ibus_awid     = '0;           
    assign ibus_awlen    = '0;
    assign ibus_awsize   = '0;
    assign ibus_awburst  = '0;
    assign ibus_awlock   = '0;
    assign ibus_awcache  = '0;
    assign ibus_awprot   = '0;
    assign ibus_awvalid  = '0;
    assign ibus_awaddr   = '0;
    // master -> slave
    assign ibus_wid      = '0;
    assign ibus_wdata    = '0;
    assign ibus_wstrb    = '0;
    assign ibus_wlast    = '0;
    assign ibus_wvalid   = '0;
    assign ibus_bready   = '0;


/********************* dbus ******************/
    assign dbus_arid     = 4'b0001;
    assign dbus_arlen    = 4'b0011;
    assign dbus_arsize   = 3'b010;
    assign dbus_arburst  = 2'b01;
    assign dbus_arlock   = '0;
    assign dbus_arcache  = '0;
    assign dbus_arprot   = '0;


    assign dbus_awid     = 4'b0001;
    assign dbus_awlen    = 4'b0011;        // 传输4次
    assign dbus_awsize   = 3'b010;         // 传输32bit 
    assign dbus_awburst  = 2'b01;          // increase模式
    assign dbus_awlock   = '0;
    assign dbus_awcache  = '0;
    assign dbus_awprot   = '0;


    assign dbus_wid     = 4'b0001;
    assign dbus_wstrb   = 4'b1111;
    assign dbus_bready  = 1'b1;

/********************* ubus ******************/
    assign ubus_arid     = 4'b0011;
    assign ubus_arlen    = 4'b0000; // 传输事件只有一个
    // assign ubus_arsize   = 3'b010; // 4字节
    assign ubus_arsize   = (U_RD_LoadType.size == 2'b10) ? 3'b000: // lb
                           (U_RD_LoadType.size == 2'b01) ? 3'b001: // lh
                           3'b010;//lw          // 根据LB LH LW调整Uncache的arsize  
    assign ubus_arburst  = 2'b01;
    assign ubus_arlock   = '0;
    assign ubus_arcache  = '0;
    assign ubus_arprot   = '0;


    assign ubus_awid     = 4'b0011;
    assign ubus_awlen    = 4'b0000;        // 传输1次
    assign ubus_awsize   = 3'b010;         // 传输32bit 
    assign ubus_awburst  = 2'b01;          // increase模式
    assign ubus_awlock   = '0;
    assign ubus_awcache  = '0;
    assign ubus_awprot   = '0;


    assign ubus_wid     = 4'b0001;
    assign ubus_wstrb   = U_WR_Wstrb;  // 使用所存下来的信号。以支持uncache的SB
    assign ubus_bready  = 1'b1;

    // 空闲信号的输出
    assign IcacheAXIBus. rd_rdy  = (I_RD_pre_state == I_RD_EMPTY ) ? 1'b1 : 1'b0;
    assign IcacheAXIBus. wr_rdy  = 1'b0;
    assign DcacheAXIBus. rd_rdy  = (D_RD_pre_state == D_RD_EMPTY ) ? 1'b1 : 1'b0;
    assign DcacheAXIBus. wr_rdy  = (D_WR_pre_state == D_WR_EMPTY )  ? 1'b1 : 1'b0;
    assign UncacheAXIBus.rd_rdy  = (U_RD_pre_state == U_RD_EMPTY ) ? 1'b1 : 1'b0;
    assign UncacheAXIBus.wr_rdy  = (U_WR_pre_state == U_WR_EMPTY )  ? 1'b1 : 1'b0;

// FSM -- Icache RD 
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            I_RD_pre_state  <= I_RD_EMPTY;
            //I_RD_next_state <= I_RD_EMPTY;
        end 
        else begin  
            I_RD_pre_state <= I_RD_next_state;
        end
    end

    // 状态转移
    // 因为AXI的握手在时钟沿上，所以在状态转移里面加入了I_RD_DataReady 用于burst数据的拼接
    always_comb begin
        unique case (I_RD_pre_state)
            I_RD_EMPTY:begin
                I_RD_DataReady  = '0;
                if (IcacheAXIBus.rd_req == 1'b1) begin
                    I_RD_next_state = I_RD_RECREQ;
                end
                else begin
                    I_RD_next_state = I_RD_EMPTY;
                end
            end
            I_RD_RECREQ:begin
                I_RD_DataReady  = '0;
                if (ibus_arvalid == 1'b1 && ibus_arready == 1'b1) begin
                    I_RD_next_state = I_RD_WAIT1;
                end else begin
                    I_RD_next_state = I_RD_RECREQ;

                end
            end
            I_RD_WAIT1:begin
                if (ibus_rvalid == 1'b1 && ibus_rready == 1'b1) begin
                    I_RD_next_state = I_RD_WAIT2;
                    I_RD_DataReady  = 3'd1;
                end
                else begin
                    I_RD_next_state = I_RD_WAIT1;
                    I_RD_DataReady  = '0;
                end
            end
            I_RD_WAIT2:begin
                if (ibus_rvalid == 1'b1 && ibus_rready == 1'b1) begin
                    I_RD_next_state = I_RD_WAIT3;
                    I_RD_DataReady  = 3'd2;
                end
                else begin
                    I_RD_next_state = I_RD_WAIT2;
                    I_RD_DataReady  = '0;
                end
            end
            I_RD_WAIT3:begin
                if (ibus_rvalid == 1'b1 && ibus_rready == 1'b1) begin
                    I_RD_next_state = I_RD_WAIT4;
                    I_RD_DataReady  = 3'd3;
                end
                else begin
                    I_RD_next_state = I_RD_WAIT3;
                    I_RD_DataReady  = '0;
                end
            end
            I_RD_WAIT4:begin
                if (ibus_rvalid == 1'b1 && ibus_rready == 1'b1 && ibus_rlast == 1'b1) begin
                    I_RD_next_state = I_RD_FINISH;
                    I_RD_DataReady  = 3'd4;
                end
                else begin
                    I_RD_next_state =I_RD_WAIT4;
                    I_RD_DataReady  = '0;
                end
            end
            I_RD_FINISH: begin
                I_RD_DataReady  = '0;
                I_RD_next_state     = I_RD_EMPTY;
            end
            default:begin
                I_RD_DataReady  = '0;
                I_RD_next_state     = I_RD_EMPTY;
            end

        endcase
    end

    // 状态转移产生的变化
    // araddr & arvalid
    always_comb begin
        if (I_RD_pre_state == I_RD_RECREQ ) begin
                ibus_arvalid = 1'b1;
                ibus_araddr  = I_RD_Addr;  // 传输地址
        end else begin
                ibus_arvalid = '0;
                ibus_araddr  = '0;  // 传输地址
        end
    end
    // rready 
    always_comb begin
        if (I_RD_pre_state == I_RD_WAIT1 || I_RD_pre_state == I_RD_WAIT2 ||I_RD_pre_state == I_RD_WAIT3 ||I_RD_pre_state == I_RD_WAIT4) begin
            if (ibus_rvalid == 1'b1) begin
                ibus_rready = 1'b1;
            end 
            else begin
                ibus_rready = '0;
            end
        end
        else begin
            ibus_rready = '0;
        end           
   end
    // finish 时产生的ret_valid & ret_rdata
    always_comb begin
        if (I_RD_pre_state == I_RD_FINISH) begin
            IcacheAXIBus.ret_valid = 1'b1;
            IcacheAXIBus.ret_data = AXI_I_RData;
        end
        else begin
            IcacheAXIBus.ret_valid = 1'b0;
            IcacheAXIBus.ret_data = '0;
        end
    end
    // AXI brust数据的获取
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            AXI_I_RData  <= 128'b0; 
        end 
        else if(I_RD_pre_state == I_RD_EMPTY) begin
            AXI_I_RData  <= 128'b0; 
        end
        else if (I_RD_DataReady != 3'd0) begin
            case (I_RD_DataReady)
                3'd1:begin
                    AXI_I_RData[31:0]   <= ibus_rdata;
                end
                3'd2:begin
                    AXI_I_RData[63:32]  <= ibus_rdata;
                end
                3'd3:begin
                    AXI_I_RData[95:64]  <= ibus_rdata;
                end
                3'd4:begin
                    AXI_I_RData[127:96] <= ibus_rdata;
                end
                default:
                    AXI_I_RData <= AXI_I_RData;
            endcase
        end 
    end

// FSM -- Dcache RD 
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            D_RD_pre_state  <= D_RD_EMPTY;
            //D_RD_next_state <= D_RD_EMPTY;
        end 
        else begin  
            D_RD_pre_state <= D_RD_next_state;
        end
    end

    // 状态转移
    // 因为AXI的握手在时钟沿上，所以在状态转移里面加入了D_RD_DataReady 用于burst数据的拼接
    always_comb begin
        unique case (D_RD_pre_state)
            D_RD_EMPTY:begin
                D_RD_DataReady  = '0;
                if (DcacheAXIBus.rd_req == 1'b1) begin
                    D_RD_next_state = D_RD_RECREQ;
                end
                else begin
                    D_RD_next_state = D_RD_EMPTY;
                end
            end
            D_RD_RECREQ:begin
                D_RD_DataReady  = '0;
                if (dbus_arvalid == 1'b1 && dbus_arready == 1'b1) begin
                    D_RD_next_state = D_RD_WAIT1;
                end else begin
                    D_RD_next_state = D_RD_RECREQ;

                end
            end
            D_RD_WAIT1:begin
                if (dbus_rvalid == 1'b1 && dbus_rready == 1'b1) begin
                    D_RD_next_state = D_RD_WAIT2;
                    D_RD_DataReady  = 3'd1;
                end
                else begin
                    D_RD_next_state = D_RD_WAIT1;
                    D_RD_DataReady  = '0;
                end
            end
            D_RD_WAIT2:begin
                if (dbus_rvalid == 1'b1 && dbus_rready == 1'b1) begin
                    D_RD_next_state = D_RD_WAIT3;
                    D_RD_DataReady  = 3'd2;
                end
                else begin
                    D_RD_next_state = D_RD_WAIT2;
                    D_RD_DataReady  = '0;
                end
            end
            D_RD_WAIT3:begin
                if (dbus_rvalid == 1'b1 && dbus_rready == 1'b1) begin
                    D_RD_next_state = D_RD_WAIT4;
                    D_RD_DataReady  = 3'd3;
                end
                else begin
                    D_RD_next_state = D_RD_WAIT3;
                    D_RD_DataReady  = '0;
                end
            end
            D_RD_WAIT4:begin
                if (dbus_rvalid == 1'b1 && dbus_rready == 1'b1 && dbus_rlast == 1'b1) begin
                    D_RD_next_state = D_RD_FINISH;
                    D_RD_DataReady  = 3'd4;
                end
                else begin
                    D_RD_next_state = D_RD_WAIT4;
                    D_RD_DataReady  = '0;
                end
            end
            D_RD_FINISH: begin
                D_RD_DataReady  = '0;
                D_RD_next_state     = D_RD_EMPTY;
            end
            default:begin
                D_RD_DataReady  = '0;
                D_RD_next_state     = D_RD_EMPTY;                
            end

        endcase
    end

    // 状态转移产生的变化
    // araddr & arvalid
    always_comb begin
        if (D_RD_pre_state == D_RD_RECREQ ) begin
                dbus_arvalid = 1'b1;
                dbus_araddr  = D_RD_Addr; // 传输地址
        end else begin
                dbus_arvalid = '0;
                dbus_araddr  = '0;  // 传输地址
        end
    end
    // rready 
    always_comb begin
        if (D_RD_pre_state == D_RD_WAIT1 || D_RD_pre_state == D_RD_WAIT2 ||D_RD_pre_state == D_RD_WAIT3 ||D_RD_pre_state == D_RD_WAIT4) begin
            if (dbus_rvalid == 1'b1) begin
                dbus_rready = 1'b1;
            end 
            else begin
                dbus_rready = '0;
            end
        end 
        else begin
            dbus_rready = '0;
        end          
   end
    // finish 时产生的ret_valid & ret_rdata
    always_comb begin
        if (D_RD_pre_state == D_RD_FINISH) begin
            DcacheAXIBus.ret_valid = 1'b1;
            DcacheAXIBus.ret_data = AXI_D_RData;
        end
        else begin
            DcacheAXIBus.ret_valid = 1'b0;
            DcacheAXIBus.ret_data = '0;
        end
    end
    // AXI brust数据的获取
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            AXI_D_RData  <= 128'b0; 
        end 
        else if(D_RD_pre_state == D_RD_EMPTY) begin
            AXI_D_RData  <= 128'b0; 
        end
        else if (D_RD_DataReady != 3'd0) begin
            case (D_RD_DataReady)
                3'd1:begin
                    AXI_D_RData[31:0]   <= dbus_rdata;
                end
                3'd2:begin
                    AXI_D_RData[63:32]  <= dbus_rdata;
                end
                3'd3:begin
                    AXI_D_RData[95:64]  <= dbus_rdata;
                end
                3'd4:begin
                    AXI_D_RData[127:96] <= dbus_rdata;
                end
                default:
                    AXI_D_RData <= AXI_D_RData; //TODO: 修改之前 右值是AXI＿Ｉ＿ＲＤＡＴＡ
            endcase
        end 
    end
// FSM -- Dcache WR
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            D_WR_pre_state  <= D_WR_EMPTY;
           //s D_WR_next_state = D_WR_EMPTY;
        end 
        else begin  
            D_WR_pre_state <= D_WR_next_state;
        end
    end

    // 状态转移
    // axi写模式下 同时置 valid & wdata 
    always_comb begin
        unique case (D_WR_pre_state)
            D_WR_EMPTY:begin
                dbus_wdata = '0;
                dbus_wlast = 1'b0;
                if (DcacheAXIBus.wr_req == 1'b1) begin
                    D_WR_next_state = D_WR_RECREQ;
                end
                else begin
                    D_WR_next_state = D_WR_EMPTY;
                end
            end
            D_WR_RECREQ:begin
                dbus_wdata = '0;
                dbus_wlast = 1'b0;
                if (dbus_awready == 1'b1) begin
                    D_WR_next_state = D_WR_WAIT1;
                end else begin
                    D_WR_next_state = D_WR_RECREQ;
                end
            end
            D_WR_WAIT1:begin
                dbus_wdata = AXI_D_WData[31:0];
                dbus_wlast = 1'b0;
                if ( dbus_wready == 1'b1) begin
                    D_WR_next_state = D_WR_WAIT2;
                end
                else begin
                    D_WR_next_state = D_WR_WAIT1;
                end
            end
            D_WR_WAIT2:begin
                dbus_wdata = AXI_D_WData[63:32];
                dbus_wlast = 1'b0;
                if (dbus_wready == 1'b1) begin
                    D_WR_next_state = D_WR_WAIT3;
                end
                else begin
                    D_WR_next_state = D_WR_WAIT2;
                end
            end
            D_WR_WAIT3:begin
                dbus_wdata = AXI_D_WData[95:64];
                dbus_wlast = 1'b0;
                if ( dbus_wready == 1'b1) begin
                    D_WR_next_state = D_WR_WAIT4;
                end
                else begin
                    D_WR_next_state =D_WR_WAIT3;
                end
            end
            D_WR_WAIT4:begin
                dbus_wdata = AXI_D_WData[127:96];
                dbus_wlast = 1'b1;
                if (dbus_wready == 1'b1 && dbus_wlast == 1'b1) begin
                    D_WR_next_state = D_WR_S;
                end
                else begin
                    D_WR_next_state = D_WR_WAIT4;
                end
            end
            D_WR_S: begin
                dbus_wdata      = '0;
                dbus_wlast      = 1'b0;
                if (dbus_bvalid == 1'b1) begin
                    D_WR_next_state = D_WR_FINISH;
                end
               else begin
                    D_WR_next_state = D_WR_S;
                end
            end
            D_WR_FINISH: begin
                dbus_wlast      = 1'b0;
                dbus_wdata      = '0;
                D_WR_next_state = D_WR_EMPTY;
            end
            default:begin
                dbus_wlast      = 1'b0;
                dbus_wdata      = '0;
                D_WR_next_state = D_WR_EMPTY;
            end
        endcase
    end

    // 状态转移产生的变化
    // awaddr & awvalid
    always_comb begin
        if (D_WR_pre_state == D_WR_RECREQ ) begin
                dbus_awvalid = 1'b1;
                dbus_awaddr  = D_WR_Addr;  // 传输地址
        end else begin
                dbus_awvalid = '0;
                dbus_awaddr  = '0;  // 传输地址
        end
    end
    // wvalid 
    always_comb begin
        if (D_WR_pre_state == D_WR_WAIT1 || D_WR_pre_state == D_WR_WAIT2 ||D_WR_pre_state == D_WR_WAIT3 ||D_WR_pre_state == D_WR_WAIT4) begin
            dbus_wvalid = 1'b1;
        end     
        else begin
            dbus_wvalid = '0;            
        end      
   end

    // finish 时产生的wr_valid
    always_comb begin
        if (D_WR_pre_state == D_WR_FINISH) begin
            DcacheAXIBus.wr_valid = 1'b1;
        end
        else begin
            DcacheAXIBus.wr_valid = 1'b0;
        end
    end

// FSM -- Uncache RD 
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            U_RD_pre_state  <= U_RD_EMPTY;
        end 
        else begin  
            U_RD_pre_state <= U_RD_next_state;
        end
    end

    // 状态转移
    always_comb begin
        unique case (U_RD_pre_state)
            U_RD_EMPTY:begin
                if (UncacheAXIBus.rd_req == 1'b1) begin
                    U_RD_next_state = U_RD_RECREQ;
                end
                else begin
                    U_RD_next_state = U_RD_EMPTY;
                end
            end
            U_RD_RECREQ:begin
                if (ubus_arvalid == 1'b1 && ubus_arready == 1'b1) begin
                    U_RD_next_state = U_RD_WAIT1;
                end else begin
                    U_RD_next_state = U_RD_RECREQ;

                end
            end
            U_RD_WAIT1:begin
                if (ubus_rvalid == 1'b1 && ubus_rready == 1'b1 && ubus_rlast == 1'b1) begin
                    U_RD_next_state = U_RD_FINISH;
                end
                else begin
                    U_RD_next_state = U_RD_WAIT1;
                end
            end
            U_RD_FINISH: begin
                U_RD_next_state     = U_RD_EMPTY;
            end
            default:begin
                U_RD_next_state     = U_RD_EMPTY;                
            end
        endcase
    end

    // 状态转移产生的变化
    // araddr & arvalid
    always_comb begin
        if (U_RD_pre_state == U_RD_RECREQ ) begin
                ubus_arvalid = 1'b1;
                ubus_araddr  = U_RD_Addr; // 传输地址
        end else begin
                ubus_arvalid = '0;
                ubus_araddr  = '0;  // 传输地址
        end
    end
    // rready 
    always_comb begin
        if (U_RD_pre_state == U_RD_WAIT1 ) begin
            if (ubus_rvalid == 1'b1) begin
                ubus_rready = 1'b1;
            end 
            else begin
                ubus_rready = '0;
            end
        end 
        else begin
            ubus_rready = '0;
        end          
   end
    // finish 时产生的ret_valid & ret_rdata
    always_comb begin
        if (U_RD_pre_state == U_RD_FINISH) begin
            UncacheAXIBus.ret_valid = 1'b1;
            UncacheAXIBus.ret_data  = AXI_U_RData;
        end
        else begin
            UncacheAXIBus.ret_valid = 1'b0;
            UncacheAXIBus.ret_data  = '0;
        end
    end
    // AXI brust数据的获取
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            AXI_U_RData  <= 32'b0; 
        end 
        else begin
            AXI_U_RData[31:0] <= ubus_rdata;
        end 
    end

// FSM -- Uncache WR
    always_ff @(posedge clk) begin
        if (resetn == `RstEnable) begin
            U_WR_pre_state  <= U_WR_EMPTY;
        end 
        else begin  
            U_WR_pre_state  <= U_WR_next_state;
        end
    end

    // 状态转移
    always_comb begin
        unique case (U_WR_pre_state)
            U_WR_EMPTY:begin
                ubus_wlast = 1'b0;
                if (UncacheAXIBus.wr_req == 1'b1) begin
                    U_WR_next_state = U_WR_RECREQ;
                end
                else begin
                    U_WR_next_state = U_WR_EMPTY;
                end
            end
            U_WR_RECREQ:begin
                ubus_wlast = 1'b0;
                if (ubus_awready == 1'b1) begin
                    U_WR_next_state = U_WR_WAIT1;
                end else begin
                    U_WR_next_state = U_WR_RECREQ;
                end
            end
            U_WR_WAIT1:begin
                ubus_wlast = 1'b1;
                if (ubus_wready == 1'b1 && ubus_wlast == 1'b1) begin
                    U_WR_next_state = U_WR_S;
                end
                else begin
                    U_WR_next_state = U_WR_WAIT1;
                end
            end
            U_WR_S: begin
                ubus_wlast = 1'b0;
                if (ubus_bvalid == 1'b1) begin
                    U_WR_next_state = U_WR_FINISH;
                end
               else begin
                    U_WR_next_state = U_WR_S;
                end
            end
            U_WR_FINISH: begin
                ubus_wlast = 1'b0;
                U_WR_next_state = U_WR_EMPTY;
            end
            default:begin
                ubus_wlast = 1'b0;
                U_WR_next_state = U_WR_EMPTY;
            end
        endcase
    end
    assign ubus_wdata = AXI_U_WData[31:0];
    // 状态转移产生的变化
    // awaddr & awvalid
    always_comb begin
        if (U_WR_pre_state == U_WR_RECREQ ) begin
                ubus_awvalid = 1'b1;
                ubus_awaddr  = U_WR_Addr;  // 传输地址
        end else begin
                ubus_awvalid = '0;
                ubus_awaddr  = '0;  // 传输地址
        end
    end
    // wvalid 
    always_comb begin
        if (U_WR_pre_state == U_WR_WAIT1 ) begin
            ubus_wvalid = 1'b1;
        end     
        else begin
            ubus_wvalid = '0;            
        end     
   end
    // finish 时产生的wr_valid
    always_comb begin
        if (U_WR_pre_state == U_WR_FINISH) begin
            UncacheAXIBus.wr_valid = 1'b1;
        end
        else begin
            UncacheAXIBus.wr_valid = 1'b0;
        end
    end

    axi_crossbar_cache biu (
        .aclk             ( clk     ),
        .aresetn          ( resetn        ),
        
        .s_axi_arid       ( {ibus_arid   ,dbus_arid    ,ubus_arid   } ),
        .s_axi_araddr     ( {ibus_araddr ,dbus_araddr  ,ubus_araddr } ),
        .s_axi_arlen      ( {ibus_arlen  ,dbus_arlen   ,ubus_arlen  } ),
        .s_axi_arsize     ( {ibus_arsize ,dbus_arsize  ,ubus_arsize } ),
        .s_axi_arburst    ( {ibus_arburst,dbus_arburst ,ubus_arburst} ),
        .s_axi_arlock     ( {ibus_arlock ,dbus_arlock  ,ubus_arlock } ),
        .s_axi_arcache    ( {ibus_arcache,dbus_arcache ,ubus_arcache} ),
        .s_axi_arprot     ( {ibus_arprot ,dbus_arprot  ,ubus_arprot } ),
        .s_axi_arqos      ( 0                                         ),
        .s_axi_arvalid    ( {ibus_arvalid,dbus_arvalid ,ubus_arvalid} ),
        .s_axi_arready    ( {ibus_arready,dbus_arready ,ubus_arready} ),
        .s_axi_rid        ( {ibus_rid    ,dbus_rid     ,ubus_rid    } ),
        .s_axi_rdata      ( {ibus_rdata  ,dbus_rdata   ,ubus_rdata  } ),
        .s_axi_rresp      ( {ibus_rresp  ,dbus_rresp   ,ubus_rresp  } ),
        .s_axi_rlast      ( {ibus_rlast  ,dbus_rlast   ,ubus_rlast  } ),
        .s_axi_rvalid     ( {ibus_rvalid ,dbus_rvalid  ,ubus_rvalid } ),
        .s_axi_rready     ( {ibus_rready ,dbus_rready  ,ubus_rready } ),
        .s_axi_awid       ( {ibus_awid   ,dbus_awid    ,ubus_awid   } ),
        .s_axi_awaddr     ( {ibus_awaddr ,dbus_awaddr  ,ubus_awaddr } ),
        .s_axi_awlen      ( {ibus_awlen  ,dbus_awlen   ,ubus_awlen  } ),
        .s_axi_awsize     ( {ibus_awsize ,dbus_awsize  ,ubus_awsize } ),
        .s_axi_awburst    ( {ibus_awburst,dbus_awburst ,ubus_awburst} ),
        .s_axi_awlock     ( {ibus_awlock ,dbus_awlock  ,ubus_awlock } ),
        .s_axi_awcache    ( {ibus_awcache,dbus_awcache ,ubus_awcache} ),
        .s_axi_awprot     ( {ibus_awprot ,dbus_awprot  ,ubus_awprot } ),
        .s_axi_awqos      ( 0                                         ),
        .s_axi_awvalid    ( {ibus_awvalid,dbus_awvalid ,ubus_awvalid} ),
        .s_axi_awready    ( {ibus_awready,dbus_awready ,ubus_awready} ),
        .s_axi_wid        ( {ibus_wid    ,dbus_wid     ,ubus_wid    } ),
        .s_axi_wdata      ( {ibus_wdata  ,dbus_wdata   ,ubus_wdata  } ),
        .s_axi_wstrb      ( {ibus_wstrb  ,dbus_wstrb   ,ubus_wstrb  } ),
        .s_axi_wlast      ( {ibus_wlast  ,dbus_wlast   ,ubus_wlast  } ),
        .s_axi_wvalid     ( {ibus_wvalid ,dbus_wvalid  ,ubus_wvalid } ),
        .s_axi_wready     ( {ibus_wready ,dbus_wready  ,ubus_wready } ),
        .s_axi_bid        ( {ibus_bid    ,dbus_bid     ,ubus_bid    } ),
        .s_axi_bresp      ( {ibus_bresp  ,dbus_bresp   ,ubus_bresp  } ),
        .s_axi_bvalid     ( {ibus_bvalid ,dbus_bvalid  ,ubus_bvalid } ),
        .s_axi_bready     ( {ibus_bready ,dbus_bready  ,ubus_bready } ),
        
        .m_axi_arid       ( m_axi_arid          ),
        .m_axi_araddr     ( m_axi_araddr        ),
        .m_axi_arlen      ( m_axi_arlen         ),
        .m_axi_arsize     ( m_axi_arsize        ),
        .m_axi_arburst    ( m_axi_arburst       ),
        .m_axi_arlock     ( m_axi_arlock        ),
        .m_axi_arcache    ( m_axi_arcache       ),
        .m_axi_arprot     ( m_axi_arprot        ),
        .m_axi_arqos      (                     ),
        .m_axi_arvalid    ( m_axi_arvalid       ),
        .m_axi_arready    ( m_axi_arready       ),
        .m_axi_rid        ( m_axi_rid           ),
        .m_axi_rdata      ( m_axi_rdata         ),
        .m_axi_rresp      ( m_axi_rresp         ),
        .m_axi_rlast      ( m_axi_rlast         ),
        .m_axi_rvalid     ( m_axi_rvalid        ),
        .m_axi_rready     ( m_axi_rready        ),
        .m_axi_awid       ( m_axi_awid          ),
        .m_axi_awaddr     ( m_axi_awaddr        ),
        .m_axi_awlen      ( m_axi_awlen         ),
        .m_axi_awsize     ( m_axi_awsize        ),
        .m_axi_awburst    ( m_axi_awburst       ),
        .m_axi_awlock     ( m_axi_awlock        ),
        .m_axi_awcache    ( m_axi_awcache       ),
        .m_axi_awprot     ( m_axi_awprot        ),
        .m_axi_awqos      (                     ),
        .m_axi_awvalid    ( m_axi_awvalid       ),
        .m_axi_awready    ( m_axi_awready       ),
        .m_axi_wid        ( m_axi_wid           ),
        .m_axi_wdata      ( m_axi_wdata         ),
        .m_axi_wstrb      ( m_axi_wstrb         ),
        .m_axi_wlast      ( m_axi_wlast         ),
        .m_axi_wvalid     ( m_axi_wvalid        ),
        .m_axi_wready     ( m_axi_wready        ),
        .m_axi_bid        ( m_axi_bid           ),
        .m_axi_bresp      ( m_axi_bresp         ),
        .m_axi_bvalid     ( m_axi_bvalid        ),
        .m_axi_bready     ( m_axi_bready        )
    );

endmodule
`endif 
