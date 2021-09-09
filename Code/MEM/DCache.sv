/*
 * @Author: Juan Jiang
 * @Date: 2021-05-03 23:33:50
 * @LastEditTime: 2021-07-04 09:07:56
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\Code\Cache.sv
 */
`include "../Cache_Defines.svh"
`include "../CPU_Defines.svh"
`include "../CommonDefines.svh"
module DCache(
    input logic clk,
    input logic resetn,
    input logic [31:0] Phsy_Daddr,
    output logic [31:0] Virt_Daddr,
    CPU_Bus_Interface  CPUBus,//slave
    AXI_Bus_Interface  AXIBus, //master
    AXI_UNCACHE_Interface UBus
  );

  assign Virt_Daddr = {req_buffer.tag,req_buffer.index,req_buffer.offset};

  typedef struct packed {
            logic en;
            logic we;
            logic[7:0] addr;
            logic[19:0] tagin;
            logic[19:0] tagout;
            logic validin;
            logic validout;
          } TagVType;//用于连到tag valid IP核上的线的结构体

  typedef struct packed {
            logic en;
            logic [3:0]we;
            logic[7:0] addr;
            logic[31:0] din;
            logic[31:0] dout;
          } DataType;//用于连到Data IP核上的线的结构体

  typedef enum logic [3:0] {
            LOOKUP,
            WRITEBACK,
            MISSCLEAN,
            MISSDIRTY,
            IDLE,
            REFILL,
            REQ,
            WAIT,
            STORE
          } StateType;

  // typedef enum logic  {
  //                  IDLE_STORE,
  //                  WRITE_STORE
  //                } WriteBufferType;
  // WriteBufferType writeState,nextWriteState;



  typedef struct packed {
    logic valid;
    logic op;
    logic[7:0] index;
    logic[19:0] tag;
    logic[3:0] offset;
    logic[3:0] wstrb;
    logic[31:0] wdata;
    StoreType  storeType;
    LoadType   loadType;
  } RequestType;

  typedef struct  packed{
    logic [3:0][31:0] bank;
    logic [`TAGBITNUM-1:0] tag;
    logic [`INDEXBITNUM-1:0] index;//保留要写入脏块的index号
    logic way0_hit;
    logic way1_hit;
    logic [3:0]wstrb;
    StoreType  storeType;
  } StoreBufferType;


  StoreBufferType store_buffer;
  RequestType req;//从cpu和request_buffer中选择出来的请求
  logic isAgain;  //是否是未命中 需要再次查找
  logic isAgain_new;//isAgain是reg isAgain_new是wire

  StateType state;
  StateType nextState;
  logic[255:0][0:0]  Dirty0;//第0路的dirty域
  logic[255:0][0:0]  Dirty1;//第1路的dirty域

  logic Count0;//第0路的计数器
  logic Count1;//第1路的计数器

  TagVType tagV0,tagV1;//对于tagv的赋值 datain 连入的是axi接口模块进来的值 en 是当有req.valid成立 we当axi接口模块来的valid成立

  DataType [`WordsPerCacheLine-1:0] data0;//第0路的data banks
  DataType [`WordsPerCacheLine-1:0] data1;//第1路的data banks

  RequestType req_buffer;
  RequestType req_buffer_new;
  
  logic way0_hit;
  logic way1_hit;
  logic cache_hit;

  logic [3:0]way0_we;
  logic [3:0]way1_we;

  logic [3:0]way0_web;
  logic [3:0]way1_web; //store的写使能

  logic isStore;//这个信号表征 在这个周期 是否将store buffer的数据写入对应的bank和tag
  logic isUncache;
  logic [31:0]unCache_rdata;//用来存放来自axi模块的数据
  logic unCache_rdata_en;
  logic [31:0]wdata;
  logic [31:0]dirty_addr;
  // logic way0_data;因为没写注释 我也不知道这是啥
  // logic way1_data;
//----------------------------对req的选择 如果isAgain高电平 那就引入 req_buffer的内容 不然就是
always_comb begin 
  if (CPUBus.flush == `FlushEnable) begin
    req = {CPUBus.valid , CPUBus.op,CPUBus.index ,CPUBus.tag ,CPUBus.offset ,CPUBus.wstrb , CPUBus.wdata, CPUBus.storeType,CPUBus.loadType };
  end
  else if(isAgain == 1'b1 || (state == LOOKUP && cache_hit== `MISS))begin
    req = req_buffer;
  end
  else begin
    req = {CPUBus.valid , CPUBus.op,CPUBus.index ,CPUBus.tag ,CPUBus.offset ,CPUBus.wstrb , CPUBus.wdata ,CPUBus.storeType,CPUBus.loadType};
  end
end



//------------------------对tagv input的赋值
assign tagV0.en      = req.valid | isStore;
assign tagV0.we      = (isStore)?way0_web:way0_we;//当在refill状态 并且 ret_valid有效时 并且换的还是这一路
assign tagV0.addr    = (isStore)?store_buffer.index : req.index;
assign tagV0.tagin   = (isStore)?store_buffer.tag : Phsy_Daddr[31:12];
assign tagV0.validin = 1'b1;


assign tagV1.en      = req.valid | isStore;
assign tagV1.we      = (isStore)?way1_web:way1_we;
assign tagV1.addr    = (isStore)?store_buffer.index :req.index;
assign tagV1.tagin   = (isStore)?store_buffer.tag :Phsy_Daddr[31:12];
assign tagV1.validin = 1'b1;

// 对tagV0/1_en的赋值 // 当在refill状态 并且 ret_valid有效时 并且换的还是这一路
always_comb begin
  if(nextState == IDLE && state == REFILL) begin
    if (Count0 == 1'b1) begin
      way0_we = 4'b1111;
      way1_we = 4'b0000;
    end
    else begin
      way0_we = 4'b0000;
      way1_we = 4'b1111;      
    end
  end
  else begin
    way0_we = 4'b0000;
    way1_we = 4'b0000;
  end
end



always_comb begin
   if (state == STORE) begin// 不用考虑此时的flush信号 因为在外部看来 store应该是在上一个时钟就完成的
    if (store_buffer.way0_hit == 1'b1) begin
      way0_web = store_buffer.wstrb;
      way1_web = 4'b0000;
    end
    else begin
      way0_web = 4'b0000;
      way1_web = store_buffer.wstrb;      
    end    
  end
  else begin
    way0_web = 4'b0000;
    way1_web = 4'b0000;        
  end
end

//对 伪lru的计数器的赋值
always_ff @( posedge clk ) begin 
  if (state == LOOKUP && cache_hit == `HIT && isUncache == 1'b0) begin
    if (way0_hit == `HIT) begin
      Count0 <= '0;
      Count1 <= '1;
    end
    else begin
      Count0 <= '1;
      Count1 <= '0;      
    end
  end
end

//对于dirty位的读写

always_ff @(posedge clk) begin
  if (resetn == `RstEnable) begin
  Dirty0 <= '0;
  Dirty1 <= '0;
  end
  else if ( state == LOOKUP && req_buffer.op == 1'b1 && cache_hit == `HIT && isUncache == 1'b0) begin//store指令的第二拍 store命中 写dirty
    if (way0_hit == `HIT) begin
      Dirty0[req_buffer.index]<=1'b1;
    end
    else begin
      Dirty1[req_buffer.index]<=1'b1;     
    end
  end
  else if (state == WRITEBACK ) begin
    if (Count0 == 1'b1) begin
      Dirty0[req_buffer.index]<=1'b0;
    end
    else  begin
      Dirty1[req_buffer.index]<=1'b0;
    end
  end
  else begin
    Dirty0 <= Dirty0;
    Dirty1 <= Dirty1;
  end
end

//TODO: storebuffer的赋值
always_ff @(posedge clk ) begin
  store_buffer.index <= req_buffer.index;
  store_buffer.tag <= Phsy_Daddr[31:12];
  store_buffer.way0_hit <= way0_hit;
  store_buffer.way1_hit <= way1_hit;
  store_buffer.wstrb   <= req_buffer.wstrb;
  store_buffer.storeType <=req_buffer.storeType;
end

  always_comb begin
   
     if(|req_buffer.wstrb) begin
       unique case(req_buffer.storeType.size)
         `STORETYPE_SW: begin //SW
           // Dmem[MEM_ALUOut[11:2]] <=req_buffer.wdata;
           wdata    =req_buffer.wdata;
         end
         `STORETYPE_SH: begin //SH
           if(req_buffer.offset[1] == 1'b0)begin
             wdata    = {16'b0,req_buffer.wdata[15:0]};
           end
             // Dmem[MEM_ALUOut[11:2]][15:0] <=req_buffer.wdata[15:0];
           else begin
             wdata    = {req_buffer.wdata[15:0],16'b0};
           end
             // Dmem[MEM_ALUOut[11:2]][31:16] <=req_buffer.wdata[15:0];
         end
         `STORETYPE_SB: begin //SB
           if(req_buffer.offset[1:0] == 2'b00) begin
             wdata    = {24'b0,req_buffer.wdata[7:0]};
           end
             // Dmem[MEM_ALUOut[11:2]][7:0] <=req_buffer.wdata[7:0];
           else if(req_buffer.offset[1:0] == 2'b01) begin
             wdata    = {16'b0,req_buffer.wdata[7:0],8'b0};
           end
             // Dmem[MEM_ALUOut[11:2]][15:8] <=req_buffer.wdata[7:0];
           else if(req_buffer.offset[1:0] == 2'b10) begin
             wdata    = {8'b0,req_buffer.wdata[7:0],16'b0};
           end
             // Dmem[MEM_ALUOut[11:2]][23:16] <=req_buffer.wdata[7:0];
           else if(req_buffer.offset[1:0] == 2'b11) begin
             wdata    = {req_buffer.wdata[7:0],24'b0};
           end
           else begin
             wdata    = {req_buffer.wdata[7:0],24'b0};
           end
             // Dmem[MEM_ALUOut[11:2]][31:24] <=req_buffer.wdata[7:0];
         end
         default: begin
             wdata    = 32'b0;
         end
     
       endcase
     end else begin
       wdata    = 32'b0;
     end
   
   end

always_ff @(posedge clk) begin                                                                                                                                                        
  if (req_buffer.op == 1'b1 ) begin
  unique case (req_buffer.offset[3:2])
    2'b00:begin
      store_buffer.bank[0] <=wdata;
      if (way0_hit == `HIT ) begin
        store_buffer.bank[1] <= data0[1].dout;
        store_buffer.bank[2] <= data0[2].dout;
        store_buffer.bank[3] <= data0[3].dout;
      end
      else begin
        store_buffer.bank[1] <= data1[1].dout;
        store_buffer.bank[2] <= data1[2].dout;
        store_buffer.bank[3] <= data1[3].dout;        
      end
    end
    2'b01:begin
      store_buffer.bank[1] <= wdata;
      if (way0_hit == `HIT ) begin
        store_buffer.bank[0] <= data0[0].dout;
        store_buffer.bank[2] <= data0[2].dout;
        store_buffer.bank[3] <= data0[3].dout;
      end
      else begin
        store_buffer.bank[0] <= data1[0].dout;
        store_buffer.bank[2] <= data1[2].dout;
        store_buffer.bank[3] <= data1[3].dout;        
      end
    end      
    2'b10:begin
      store_buffer.bank[2] <= wdata; 
      if (way0_hit == `HIT ) begin
        store_buffer.bank[0] <= data0[0].dout;
        store_buffer.bank[1] <= data0[1].dout;
        store_buffer.bank[3] <= data0[3].dout;
      end
      else begin
        store_buffer.bank[0] <= data1[0].dout;
        store_buffer.bank[1] <= data1[1].dout;
        store_buffer.bank[3] <= data1[3].dout;        
      end      
    end
    2'b11:begin
      store_buffer.bank[3] <= wdata;    
      if (way0_hit == `HIT ) begin
        store_buffer.bank[0] <= data0[0].dout;
        store_buffer.bank[2] <= data0[2].dout;
        store_buffer.bank[1] <= data0[1].dout;
      end
      else begin
        store_buffer.bank[0] <= data1[0].dout;
        store_buffer.bank[2] <= data1[2].dout;
        store_buffer.bank[1] <= data1[1].dout;        
      end   
    end
    default: begin
      store_buffer.bank <= '0; 
    end
  endcase
  end
  else begin
    store_buffer.bank <= '1; //TODO: 所以这到底是什么呢
  end
end



//------------------对data0 data1 的input的赋值
generate;
  for (genvar i=0; i<`WordsPerCacheLine ;i=i+1) begin
    assign data0[i].addr = (isStore)?store_buffer.index :req.index;
    assign data0[i].en = req.valid | (|way0_web);
    assign data0[i].we = (isStore)?way0_web: way0_we;
    assign data0[i].din =(isStore)?store_buffer.bank[i]: AXIBus.ret_data[(i+1)*32-1:i*32];
    

    assign data1[i].addr = (isStore)?store_buffer.index :req.index;
    assign data1[i].en = req.valid | (|way1_web);
    assign data1[i].we = (isStore)?way1_web: way1_we;
    assign data1[i].din = (isStore)?store_buffer.bank[i]:AXIBus.ret_data[(i+1)*32-1:i*32];
  end
endgenerate


//----------------选取读取到的数据-------------

logic [31:0] way0_word;
logic [31:0] way1_word;

always_comb begin//根据
  unique case (req_buffer.offset[3:2])//根据req_buffer里面的信息 因为 req_buffer里面的信息是和从ram读出的数据是同一拍的
      2'b00:begin
        way0_word = data0[0].dout;
        way1_word = data1[0].dout;
      end
      2'b01:begin
        way0_word = data0[1].dout;
        way1_word = data1[1].dout;       
      end
      2'b10:begin
        way0_word = data0[2].dout;
        way1_word = data1[2].dout;        
      end
      2'b11:begin
        way0_word = data0[3].dout;
        way1_word = data1[3].dout;      
      end
    default:begin
        way0_word = 'x;
        way1_word = 'x;      
    end
  endcase
end

logic [31:0] way_word;//读出的数据
logic [31:0] way_word_r;//所存下位接收的数据
logic choose;
always_ff @(posedge clk) begin
  if (CPUBus.data_ok == 1'b1 ) begin
    way_word_r <= way_word;
  end
  else begin
    way_word_r <= way_word_r;
  end
end

always_ff @(posedge clk) begin
  if (CPUBus.data_ok == 1'b1 && CPUBus.ready == 1'b0) begin
    choose <= 1'b1;
  end
  else if (CPUBus.ready == 1'b1) begin
    choose <= 1'b0;
  end
  else begin
    choose <= choose;
  end
end


always_comb begin // 读出数的always块
  if (state == IDLE) begin
    way_word = unCache_rdata;
  end
  else if(cache_hit == `HIT && state == LOOKUP && isUncache == 1'b0)begin
    if(way0_hit == `HIT) way_word = way0_word;
    else way_word = way1_word;
  end
  else begin//cache miss的情况
        way_word = '0;
  end
end



//对CPUBus 的output进行赋值
assign CPUBus.rdata = (CPUBus.data_ok == 1'b1 && CPUBus.ready == 1'b1)?way_word:(choose)?way_word_r:'0;
always_comb begin
    if (state ==IDLE && isAgain == 1'b0) begin
        CPUBus.addr_ok = `Ready;
    end
    else if (state == LOOKUP && cache_hit == `HIT && isUncache == 1'b0 && req_buffer.op==1'b0) begin//当处于look up 命中 并且不是uncache的
      CPUBus.addr_ok = `Ready;
    end
    else CPUBus.addr_ok = `Unready;
end

logic data_ok;
logic data_ok_r;
always_ff @(posedge clk) begin
  data_ok_r <=data_ok;
end

always_comb begin
  if ( state == LOOKUP && cache_hit == `HIT && isUncache == 1'b0) begin
    CPUBus.data_ok = `Valid;
  end
  else CPUBus.data_ok = data_ok_r;
end

always_comb begin
  if (state == WAIT ) begin
    unique case (req_buffer.op)
      1'b0:begin
        if (UBus.ret_valid == `Valid) begin
          data_ok = `Valid;
        end
        else begin
          data_ok = `Invalid;  
        end
      end
      1'b1:begin
        if (UBus.wr_valid == `Valid) begin
          data_ok = `Valid;
        end
        else begin
          data_ok = `Invalid;  
        end        
      end
      default: begin
        data_ok = `Invalid;
      end
    endcase
  end
  else begin
    data_ok = `Invalid;
  end
end
//对isAgain的赋值  
always_comb begin
  if(state == LOOKUP && cache_hit == `MISS && isUncache == 1'b0  )begin //在LOOKUP阶段 未命中
    isAgain_new = 1'b1; 
  end
  else isAgain_new = 1'b0;
end

always_ff @(posedge clk) begin
  if(resetn == `RstEnable || CPUBus.flush == `FlushEnable)begin
    isAgain <= '0;
  end
  else if (state == IDLE || state == LOOKUP) begin
    isAgain <= isAgain_new;
  end
  else begin
    isAgain <= isAgain;
  end
end

////对AXIBus 的output进行赋值
assign AXIBus.rd_addr = {Phsy_Daddr[31:12],req_buffer.index,4'b0000};
always_comb begin
  if (state == MISSCLEAN || state == WRITEBACK) begin
    AXIBus.rd_req = `Enable;
  end
  else AXIBus.rd_req = `Disable;
end

assign dirty_addr = (Count0 == 1'b1) ? {tagV0.tagout,req_buffer.index,4'b0000}
                                         : {tagV1.tagout,req_buffer.index,4'b0000}  ;


assign AXIBus.wr_addr = dirty_addr;
assign AXIBus.wr_data = (Count0 == 1'b1) ? {data0[3].dout,data0[2].dout,data0[1].dout,data0[0].dout}
                                         : {data1[3].dout,data1[2].dout,data1[1].dout,data1[0].dout}  ;
always_comb begin
  if (state == MISSDIRTY) begin
    AXIBus.wr_req = `Enable;
  end
  else begin
    AXIBus.wr_req = `Disable;
  end
end

//对 uncache的部分测试
always_comb begin
  if (state == REQ) begin
    unique case (req_buffer.op)
      1'b0:begin
        UBus.rd_req = `Enable;
        UBus.rd_addr = Phsy_Daddr;
        UBus.wr_req ='0;
        UBus.wr_addr = '0;
        UBus.wr_data ='0;
      end
      1'b1:begin
      UBus.rd_req ='0;
        UBus.rd_addr = '0;
        UBus.wr_req  = `Enable;
        UBus.wr_addr = {Phsy_Daddr[31:2],2'b00};
        UBus.wr_data = wdata;
      end
      default: begin
        UBus.rd_req ='0;
        UBus.rd_addr = '0;
        UBus.wr_req ='0;
        UBus.wr_addr = '0;
        UBus.wr_data ='0;
      end
    endcase
  end
  else begin
      UBus.rd_req ='0;
      UBus.rd_addr = '0;
      UBus.wr_req ='0;
      UBus.wr_addr = '0;
      UBus.wr_data ='0;  
  end
end



assign UBus.wr_wstrb = req_buffer.wstrb;
assign UBus.loadType = req_buffer.loadType;
always_comb begin
  if (state == WAIT && req_buffer.op == 1'b0 && UBus.ret_valid == `Valid) begin
    unCache_rdata_en = `WriteEnable;
    end
  else begin
    unCache_rdata_en = `WriteDisable;
  end
end

always_ff @(posedge clk) begin
  if (resetn == `RstEnable) begin
    unCache_rdata <= '0;
  end
  else if (unCache_rdata_en == `WriteEnable) begin
    unCache_rdata <= UBus.ret_data;
  end 
  else begin
    unCache_rdata <= unCache_rdata;
  end 
end

//-----------------判断是否命中----------------------
  assign way0_hit = (tagV0.validout )& (tagV0.tagout == Phsy_Daddr[31:12]);
  assign way1_hit = (tagV1.validout )& (tagV1.tagout == Phsy_Daddr[31:12]);
  assign cache_hit = way0_hit | way1_hit;

// req_buffer
  logic req_buffer_en;
always_comb begin 
  if (CPUBus.flush == `FlushEnable) begin
    req_buffer_en = 1'b1;
  end
  else if (~(state ==IDLE && isAgain == 1'b0) && ~(state == LOOKUP && cache_hit == `HIT && isUncache == 1'b0 ) ) begin//如果未命中 保持req_buffer不变 或者需要再次LOOKUP时 保持req_buffer不变
    req_buffer_en = 1'b0;
  end
  else begin
    req_buffer_en = 1'b1;
  end
end

  assign req_buffer_new = (req_buffer_en ? {CPUBus.valid , CPUBus.op,CPUBus.index ,CPUBus.tag ,CPUBus.offset ,CPUBus.wstrb , CPUBus.wdata,CPUBus.storeType,CPUBus.loadType } : req_buffer);
  always_ff @( posedge clk ) begin //request_buffer
    if(resetn == `RstEnable)begin
      req_buffer <='0;
    end
    else begin
      req_buffer <= req_buffer_new;
    end
  end

  MMU MMU_dut (
        .virt_addr ({req_buffer.tag,req_buffer.index,req_buffer.offset} ),
        .isUncache (isUncache )
      );//虚实地址转换



  inst_ram_TagV TagV0(//第一路的tag 使用最后一位作为valid
                  //input
                  .clka(clk),
                  .ena(tagV0.en),     //实际上在replace阶段也要读写 然后在判断命中的时候
                  .wea(tagV0.we),     // 在refill是写使能打开
                  .addra(tagV0.addr), //地址号 就是cache set的编号
                  .dina({tagV0.tagin,tagV0.validin} ),
                  //output
                  .douta({tagV0.tagout,tagV0.validout} )

                );

  inst_ram_TagV TagV1(//第二路的tag 使用最后一位作为valid
                  //input
                  .clka(clk),
                  .ena(tagV1.en),     //实际上在replace阶段也要读写 然后在判断命中的时候
                  .wea(tagV1.we),     // 在refill是写使能打开
                  .addra(tagV1.addr), //地址号 就是cache set的编号
                  .dina({tagV1.tagin,tagV1.validin} ),
                  //output
                  .douta({tagV1.tagout,tagV1.validout} )


                );

  generate
    for(genvar i=0;i < `WordsPerCacheLine; i = i+1)
    begin:gen_icache_ram
      inst_ram_data Data0(//第0路的data block ram
                      //input
                      .clka(clk),
                      .addra(data0[i].addr),
                      .dina(data0[i].din),
                      .ena(data0[i].en),
                      .wea(data0[i].we),
                      //output
                      .douta(data0[i].dout)

                
                    );

      inst_ram_data Data1(//第1路的data block ram
                      //input
                      //input
                      .clka(clk),
                      .addra(data1[i].addr),
                      .dina(data1[i].din),
                      .ena(data1[i].en),
                      .wea(data1[i].we),
                      //output
                      .douta(data1[i].dout)

  
                    );
    end
    
  endgenerate

  always_ff @( posedge clk )
  begin
    state<=nextState;
  end



/*Icache状态机说明
IDLE->IDLE 该周期无访存请求
IDLE->LOOKUP 该周期有访存请求 下一周期可达到命中信息
LOOKUP->LOOKUP 该周期收到访存请求 且上周期的请求命中
LOOKUP->MISS 上周期的访存请求未命中 这周期的命中结果是未命中
MISS->MISS 如果不能发出读请求
MISS->REPLACE 发出了读请求
REFILL->REFILL 等待AXI接口模块的数据
REFILL->IDLE  AXI接口模块数据有效
 如果外界的flush信号成立，那么以同周期的输入请求查询
*/

  always_comb //计算下一状态
  begin
    //如果复位
    if(resetn==`RstEnable || CPUBus.flush == `FlushEnable)
    begin
      nextState=IDLE;
    end
    //如果不复位
    else
    begin
      unique case (state)

               IDLE:
               begin
                 if(req.valid == `Valid  )
                   nextState=LOOKUP;
                 else
                   nextState=IDLE;
               end

               LOOKUP:
               begin
                 if (isUncache == 1'b1) begin
                   nextState = REQ;
                 end
                 else if(cache_hit == `MISS ) // cache_hit表示是否当前周期的查询命中
                 begin
                 if (Count0 == 1'b1) begin //如果需要替换的是第0路
                   if (Dirty0[req_buffer.index]==1'b1) begin //如果是dirty的
                     nextState=MISSDIRTY;
                   end
                   else begin
                     nextState=MISSCLEAN;
                   end
                 end
                 else begin//如果需要替换的是第1路
                   if (Dirty1[req_buffer.index]==1'b1) begin
                     nextState=MISSDIRTY;
                   end
                   else begin
                     nextState=MISSCLEAN;
                   end
                 end
                 end
                 else if (req_buffer.op == 1'b1) begin
                   nextState = STORE;
                 end
                 else if (req.valid ==`Valid )
                 begin
                   nextState=LOOKUP;
                 end
                 else
                   nextState=IDLE;
               end

               STORE:begin
                 nextState = IDLE;
               end

               MISSCLEAN:
               begin
                 if(AXIBus.rd_rdy == 1'b0)//如果读请求不能被接收
                 begin
                   nextState = MISSCLEAN;
                 end
                 else                     //如果读请求被接受了
                 begin
                   nextState = REFILL;
                 end
               end

               MISSDIRTY:
               begin
                 if (AXIBus.wr_rdy == 1'b0) begin
                   nextState = MISSDIRTY;
                 end
                 else begin
                   nextState = WRITEBACK;
                 end
               end

               WRITEBACK:
               begin
                 if(AXIBus.wr_valid == 1'b0)begin
                   nextState = WRITEBACK;
                 end
                 else begin
                   nextState = MISSCLEAN;
                 end
               end

              REQ:begin
                unique case (req_buffer.op)
                  1'b1:begin
                    if (UBus.wr_rdy == `Unready) begin
                      nextState = REQ;
                    end
                    else begin
                      nextState = WAIT;
                    end
                  end
                  1'b0:begin
                    if (UBus.rd_rdy == `Unready) begin
                      nextState = REQ;
                    end
                    else begin
                      nextState = WAIT;
                    end
                  end
                  default: begin
                    nextState = IDLE;
                  end
                endcase
              end

              WAIT:begin
                unique case (req_buffer.op)
                  1'b1:begin
                    if (UBus.wr_valid == `Valid) begin
                      nextState = IDLE;
                    end
                    else begin
                      nextState = WAIT;
                    end
                  end
                  1'b0:begin
                    if(UBus.ret_valid == `Valid)begin
                      nextState = IDLE;
                    end
                    else begin
                      nextState = WAIT; 
                    end
                  end
                  default:begin
                     nextState = WAIT;
                  end
                endcase
              end

               REFILL:
               begin
                 if(AXIBus.ret_valid == 1'b1)
                 begin
                   nextState = IDLE ;
                 end
                 else
                 begin
                   nextState = REFILL;
                 end
               end


               default:
               begin
                 nextState = IDLE;
               end
             endcase
           end
         end



         



          // always_ff @( posedge clk )
          // begin
          //   writeState <= nextWriteState;
          // end 

           
          // always_comb
          // begin
          //   //复位
          //   if(resetn == `RstEnable || CPUBus.flush == `FlushEnable) //如果flush了就停止写行为
          //   begin
          //     nextWriteState = IDLE_STORE;
          //   end
          //   //不复位
          //   else
          //   begin
          //     if (cache_hit == `HIT && req_buffer.op == 1'b1 && isUncache == 1'b0 && state == LOOKUP) begin //如果有命中了的写指令 那么在下一周期 跳转到WRITE_STORE 将数据写入
          //         nextWriteState = WRITE_STORE;
          //     end
          //    else begin 
          //           nextWriteState = IDLE_STORE;
          //         end
          //   end
          // end



           always_comb begin
             if (state == STORE) begin
               isStore = 1'b1;
             end
             else begin
               isStore = 1'b0;
             end
           end

  logic [31:0] req_count;
  logic [31:0] miss_count;
  logic flag;

  always_ff @( posedge clk) begin : miss_count_
    if (resetn == 1'b0) begin
      miss_count<='0;
    end else begin
      if (flag==1 && cache_hit==1'b0) begin
        miss_count <= miss_count+1; 
      end else begin
        miss_count <= miss_count;
      end
    end
  end 

    always_ff @( posedge clk) begin : req_count_
    if (resetn == 1'b0) begin
      req_count <='0;
      flag <=0;
    end else begin
      if (CPUBus.valid==1'b1 && CPUBus.addr_ok ==1'b1) begin
        req_count <= req_count+1; 
        flag<=1;
      end else begin
        req_count <= req_count;
        flag<=0;
      end
    end
  end 

       endmodule
