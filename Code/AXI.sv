`include "Cache_Defines.svh"
`include "CPU_Defines.svh"
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
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
    always_ff @(posedge clk or negedge resetn) begin
        if (resetn == `RstEnable) begin
            AXI_U_RData  <= 32'b0; 
        end 
        else begin
            AXI_U_RData[31:0] <= ubus_rdata;
        end 
    end

// FSM -- Uncache WR
    always_ff @(posedge clk or negedge resetn) begin
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
