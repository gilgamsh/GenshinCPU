/*
 * @Author: Juan Jiang
 * @Date: 2021-05-03 23:33:50
 * @LastEditTime: 2021-07-02 23:57:46
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\Code\Cache.sv
 */
`include "../Cache_Defines.svh"
`include "../CPU_Defines.svh"
module ICache(
    input logic clk,
    input logic resetn,
    input logic [31:0] Phsy_Iaddr,
    output logic [31:0] Virt_Iaddr,
    CPU_Bus_Interface  CPUBus,//slave
    AXI_Bus_Interface  AXIBus //master
  );

  assign Virt_Iaddr = {req_buffer.tag,req_buffer.index,req_buffer.offset};

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

  typedef enum logic [1:0] {
            LOOKUP,
            //HITWRITE,
            MISS,
            IDLE,
            
            REFILL
          } StateType;

  typedef struct packed {
    logic valid;
    logic op;
    logic[7:0] index;
    logic[19:0] tag;
    logic[3:0] offset;
    logic[3:0] wstrb;
    logic[31:0] wdata;
  } RequestType;

  

  RequestType req;//从cpu和request_buffer中选择出来的请求
  logic isAgain;  //是否是未命中 需要再次查找
  logic isAgain_new;//isAgain是reg isAgain_new是wire

  StateType state;
  StateType nextState;
  logic[255:0] Dirty0;//第0路的dirty域
  logic[255:0] Dirty1;//第1路的dirty域

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

  // logic way0_data;因为没写注释 我也不知道这是啥
  // logic way1_data;
//----------------------------对req的选择 如果isAgain高电平 那就引入 req_buffer的内容 不然就是
always_comb begin 
  if (CPUBus.flush == `FlushEnable) begin
    req = {CPUBus.valid , CPUBus.op,CPUBus.index ,CPUBus.tag ,CPUBus.offset ,CPUBus.wstrb , CPUBus.wdata};
  end
  else if(isAgain == 1'b1 || (state == LOOKUP && cache_hit == `MISS ))begin
    req = req_buffer;
  end
  else begin
    req = {CPUBus.valid , CPUBus.op,CPUBus.index ,CPUBus.tag ,CPUBus.offset ,CPUBus.wstrb , CPUBus.wdata };
  end
end



//------------------------对tagv input的赋值
assign tagV0.en      = req.valid;
assign tagV0.we      = way0_we;//当在refill状态 并且 ret_valid有效时 并且换的还是这一路
assign tagV0.addr    = req.index;
assign tagV0.tagin   = Phsy_Iaddr[31:12];
assign tagV0.validin = 1'b1;


assign tagV1.en      = req.valid;
assign tagV1.we      = way1_we;
assign tagV1.addr    = req.index;
assign tagV1.tagin   = Phsy_Iaddr[31:12];
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

//对 伪lru的计数器的赋值
always_ff @( posedge clk ) begin 
  if (state == LOOKUP && cache_hit == `HIT) begin
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

// logic[`WordsPerCacheLine-1:0] way0_banks_we;
// logic[`WordsPerCacheLine-1:0] way1_banks_we;
//-----------------------------------对写使能进行赋值



//------------------对data0 data1 的input的赋值
generate;
  for (genvar i=0; i<`WordsPerCacheLine ;i=i+1) begin
    assign data0[i].addr = req.index;
    assign data0[i].en = req.valid;
    assign data0[i].we = way0_we;
    assign data0[i].din = AXIBus.ret_data[(i+1)*32-1:i*32];
    

    assign data1[i].addr = req.index;
    assign data1[i].en = req.valid;
    assign data1[i].we = way1_we;
    assign data1[i].din = AXIBus.ret_data[(i+1)*32-1:i*32];
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
logic [31:0] way_word_r;//锁存下来正确的数据

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
  if(cache_hit == `HIT && state == LOOKUP)begin
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
    else if (state == LOOKUP && cache_hit == `HIT) begin
      CPUBus.addr_ok = `Ready;
    end
    else CPUBus.addr_ok = `Unready;
end

always_comb begin
  if (state == LOOKUP && cache_hit == `HIT) begin
    CPUBus.data_ok = `Valid;
  end
  else CPUBus.data_ok = `Invalid;
end

//对isAgain的赋值  
always_comb begin
  if(state == LOOKUP && cache_hit == `MISS)begin
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
assign AXIBus.rd_addr = {Phsy_Iaddr[31:12],req_buffer.index,4'b0000};
always_comb begin
  if (state == MISS) begin
    AXIBus.rd_req = `Enable;
  end
  else AXIBus.rd_req = `Disable;
end


//-----------------判断是否命中----------------------
  assign way0_hit = (tagV0.validout )& (tagV0.tagout == Phsy_Iaddr[31:12]);
  assign way1_hit = (tagV1.validout )& (tagV1.tagout == Phsy_Iaddr[31:12]);
  assign cache_hit = way0_hit | way1_hit;

// req_buffer
  logic req_buffer_en;
always_comb begin 
  if (CPUBus.flush == `FlushEnable) begin
    req_buffer_en = 1'b1;
  end
  else if ( (state == LOOKUP && cache_hit == `MISS) || isAgain ==1'b1 ) begin//如果未命中 保持req_buffer不变 或者需要再次LOOKUP时 保持req_buffer不变
    req_buffer_en = 1'b0;
  end
  else begin
    req_buffer_en = 1'b1;
  end
end

  assign req_buffer_new = req_buffer_en ? {CPUBus.valid , CPUBus.op,CPUBus.index ,CPUBus.tag ,CPUBus.offset ,CPUBus.wstrb , CPUBus.wdata } : req_buffer;
  always_ff @( posedge clk ) begin //request_buffer
    if(resetn == `RstEnable)begin
      req_buffer <='0;
    end
    else begin
      req_buffer <= req_buffer_new;
    end
  end
  
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

always_comb begin
  //if()
end

/*Icache状态机说明
IDLE->IDLE 该周期无访存请求
IDLE->LOOKUP 该周期有访存请求 下一周期可达到命中信息
LOOKUP->LOOKUP 该周期收到访存请求 且上周期的请求命中
LOOKUP->MISS 上周期的访存请求未命中 这周期的命中结果是未命中
MISS->MISS 如果不能发出读请求
MISS->REFILL 发出了读请求
REFILL->REFILL 等待AXI接口模块的数据
REFILL->IDLE  AXI接口模块数据有效
 如果外界的flush信号成立，那么以同周期的输入请求查询
*/

  always_comb //计算下一状态
  begin
    //如果复位
    if(resetn==`RstEnable )
    begin
      nextState=IDLE;
    end
    //如果不复位
    else if ( CPUBus.flush == `FlushEnable) begin
      nextState=LOOKUP;
    end
    else
    begin
      unique case (state)

               IDLE:
               begin
                 if(req.valid == `Valid)
                   nextState=LOOKUP;
                 else
                   nextState=IDLE;
               end

               LOOKUP:
               begin
                 if(cache_hit == `MISS) // cache_hit表示是否当前周期的查询命中
                 begin
                   nextState=MISS;
                 end
                 else if (req.valid ==`Valid)
                 begin
                   nextState=LOOKUP;
                 end
                 else
                   nextState=IDLE;
               end

               MISS:
               begin
                 if(AXIBus.rd_rdy == 1'b0)//如果读请求不能被接收
                 begin
                   nextState = MISS;
                 end
                 else                     //如果读请求被接受了
                 begin
                   nextState = REFILL;
                 end
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

              //  REFILL:
              //  begin
              //    if(AXIBus.ret_valid == `Valid && AXIBus.ret_last == `Valid)
              //    begin
              //      nextState = IDLE;
              //    end
              //    else
              //    begin
              //      nextState = REFILL;
              //    end
              //  end

               default:
               begin
                 nextState = IDLE;
               end
             endcase
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



        
         //        typedef enum logic  {
         //                  IDLE,
         //                  WRITE
         //                } WriteBufferType;

         // WriteBufferType writeState,nextWriteState;

         // always_ff @( posedge clk )
         // begin
         //   writeState <= nextWriteState;
         // end

         // always_comb
         // begin
         //   //复位
         //   if(rst == `RstEnable)
         //   begin
         //     nextWriteState <= IDLE;
         //   end
         //   //不复位
         //   else
         //   begin
         //     nextWriteState <= IDLE;
         //   end
         // end


       endmodule
