/*
 * @Author: Juan Jiang
 * @Date: 2021-05-03 23:00:53
 * @LastEditTime: 2021-07-03 10:10:47
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\Code\Cache_Defines.svh
 */
`ifndef CACHE_DEFINES_SVH
`define CACHE_DEFINES_SVH

`define HIT               1'b1
`define MISS              1'b0

`define TAGBITNUM         20       //因为我们使用VIPT 所以Tag是实际地址（physical）
`define INDEXBITNUM       8        //
`define OFFSETNUM         4        //和书上说的不太一样 这里采用wdh的建议 一个cache line contains 16words
`define WordsPerCacheLine 4       //每个cache line 4 words
`define SetNUM            256      //有  sets

`define DATAREADY         1
`define CACHEBUSY         1
`define CACHEIDLE         0
`define BRANCKFAILED      1

        typedef struct packed {
          logic                    valid;  //cache line的valid域 表示数据是否有效
          logic [`TAGBITNUM-1  :0]   tag;  //cache line的tag域 在第一版中 tag应该是实地址
          logic [`INDEXBITNUM-1:0] index;  //cache line的index域的大小 index以虚地址为好 这样才能及时读出数据
          logic [`OFFSETNUM-1  :0] offset; //每个cache line 的偏执位
          logic                    dirty;  //

        } CacheLineType; //没用了呜呜

typedef logic [31:0]        VirtualAddressType; //虚拟地址
typedef logic [31:0]        PhysicalAddressType;//物理地址
typedef logic [31:0]        UInt32Type;         //无符号的32位

interface CPU_Bus_Interface();            // 只需要满足读的请求 icache的读 即使在命中的情况下 也需要两回合才能返回 就是在I回合其实发出读请求 在II回合的末尾才能给出是否命中
  logic 		    valid;     // CPU是否发生访存的请求
  logic         ready;     // CPU是否可以接收访存结果
  logic 		    op;        // 0 读 1 写
  logic [7:0] 	index;     //
  logic [19:0]  tag;       // 
  logic [3:0] 	offset;    //  
  logic [3:0] 	wstrb;     //  Icache 用不到
  StoreType     storeType;
  LoadType      loadType;
  logic [31:0]  wdata;     //  Icache 用不到
  logic     		addr_ok;   //  表示访存请求可以接受（空闲
  logic     		data_ok;   //  访存结果可以发送到CPU  (1 ok 0 NotOk)
  logic [31:0]  rdata;     //          
  logic         flush;

  modport master ( //cpu的接口
            output  valid,op,index,tag,ready,storeType,
            output  offset,wstrb,wdata,flush,loadType,
            input addr_ok,data_ok,rdata
          );

  modport slave ( //cache的接口
            input  valid,op,index,tag,ready,storeType,
            input  offset,wstrb,wdata,flush,loadType,
            output addr_ok,data_ok,rdata

          );

endinterface

interface AXI_Bus_Interface();
  //读请求通道
  logic 					rd_req;    // 未命中发请求
  // logic[2:0]      rd_type;   //    用不到
  logic[31:0]     rd_addr;   // 地址
  logic           rd_rdy;    // 空闲时给ready
  //读返回通道
  logic           ret_valid; // 突发读完一次之后（缓冲区满了）
  // logic[1:0]      ret_last;  //    用不到
  logic[127:0]     ret_data; // 数据
  //写请求通道
  logic           wr_req;    // dcache store未命中
  // logic[2:0]      wr_type;   //     用不到
  logic[31:0]     wr_addr;   // 写地址 
  
  logic[127:0]    wr_data;   // 写数据
  logic           wr_rdy; //就是说只要当slave axi模块可以接收之后才发出写请求
  //写返回通道
  logic           wr_valid;//表示已经写入
  modport master ( //cache的接口
            output  rd_req,rd_addr,
            output  wr_req,wr_addr,wr_data,
            input rd_rdy,ret_valid,ret_data,wr_rdy,wr_valid
          );

  modport slave ( //axi模块的接口
            input  rd_req,rd_addr,
            input  wr_req,wr_addr,wr_data,
            output rd_rdy,ret_valid,ret_data,wr_rdy,wr_valid
          );

endinterface

interface AXI_UNCACHE_Interface();
  //读请求通道
  logic           rd_req;
  logic[31:0]     rd_addr;
  logic           rd_rdy;
  LoadType        loadType;
  //读返回通道
  logic           ret_valid;
  logic[31:0]     ret_data;
  //写请求通道
  logic           wr_req;
  logic[31:0]     wr_addr;   // 写地址 
  logic[31:0]     wr_data;   // 写数据
  logic [3:0]     wr_wstrb;  //字节写使能
  logic           wr_rdy;    //就是说只要当slave axi模块可以接收之后才发出写请求    
  //写返回通道
  logic           wr_valid;  //表示已经写入


  modport master (//cache端口
  output rd_req,rd_addr,loadType,
  output wr_req,wr_addr,wr_data,wr_wstrb,
  input rd_rdy,ret_valid,ret_data,wr_rdy,wr_valid
  );

  modport slave (//axi端口
  input rd_req,rd_addr,loadType,
  input wr_req,wr_addr,wr_data,wr_wstrb,
  output rd_rdy,ret_valid,ret_data,wr_rdy,wr_valid
  );
endinterface

`endif 
