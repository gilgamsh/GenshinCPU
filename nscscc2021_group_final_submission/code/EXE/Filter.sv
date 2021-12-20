 `include "../CPU_Defines.svh"
 `include "../CommonDefines.svh"

 module Filter(
     input logic [31:0] data_in,
     input logic isFilter,
     input logic stall,
     input logic clk,
     input logic resetn,
     input logic flush, //rd==rs==0
     output logic [31:0] data_out
 );
     
    logic [31:0] count;
    logic [31:0] sum ;
    logic [31:0] sum_nxt;
    logic [31:0] max1;//最大值
    logic [31:0] max2;//次大值
    logic [31:0] min1;//最小值
    logic [31:0] min2;//次小值

    logic [31:0] max1_nxt;
    logic [31:0] max2_nxt;
    logic [31:0] min1_nxt;
    logic [31:0] min2_nxt;

    logic        gt_max1;
    logic        gt_max2;
    logic        lt_min1;
    logic        lt_min2;   

    // logic   [3:0][31:0]     fifo_4;
    assign data_out = (count>=4)?  sum_nxt:'0;
    always_ff @( posedge clk ) begin : count_blockName
        if(resetn == `RstEnable || flush)begin
            count <= '0;
        end else if (~stall && isFilter) begin
            count <= count+1;
        end
    end

    // always_ff @(posedge clk ) begin
    //     if(resetn == `RstEnable || flush)begin
    //         fifo_4 <='0;
    //     end else if (~stall && isFilter) begin
    //         fifo_4[3] <= fifo_4[2];
    //         fifo_4[2] <= fifo_4[1];
    //         fifo_4[1] <= fifo_4[0];
    //         fifo_4[0] <= data_in;
    //     end
    // end

    always_comb begin
        if (data_in >= max1) begin
            max1_nxt = data_in;
            max2_nxt = max1;
            gt_max1  = 1'b1;
            gt_max2  = 1'b0;
        end else if(data_in >= max2) begin
            max1_nxt = max1;
            max2_nxt = data_in;          
            gt_max1  = 1'b0;
            gt_max2  = 1'b1;         
        end else begin
            max1_nxt = max1;
            max2_nxt = max2; 
            gt_max1  = 1'b0;
            gt_max2  = 1'b0;  
        end
    end
        
    always_comb begin
         if (data_in <= min1) begin
            min1_nxt = data_in;
            min2_nxt = min1;
            lt_min1  = 1'b1;
            lt_min2  = 1'b0; 
        end else if(data_in <= min2) begin
            min1_nxt = min1;
            min2_nxt = data_in;        
            lt_min1  = 1'b0;
            lt_min2  = 1'b1;     
        end else begin
            min1_nxt = min1;
            min2_nxt = min2;
            lt_min1  = 1'b0;
            lt_min2  = 1'b0;               
        end
    end

  



    always_comb begin
        if (count>=4 && isFilter  ) begin
            if (gt_max1) begin
                sum_nxt = sum + max2;
            end else if (gt_max2) begin
                sum_nxt = sum + max2;
            end else if (lt_min1) begin
                sum_nxt = sum + min2;
            end else if (lt_min2) begin
                sum_nxt = sum + min2;
            end else begin
                sum_nxt = sum + data_in;
            end
        end else begin
            sum_nxt = sum;
        end
    end

    always_ff @(posedge clk ) begin
        if (resetn == `RstEnable || flush) begin
            sum <= '0;
        end else if(~stall && isFilter)begin
            sum <=sum_nxt;
        end
    end

    always_ff @( posedge clk ) begin 
        if (resetn == `RstEnable || flush) begin
            max1 <='0;
            max2 <='0;
            min1 <=32'hffff_ffff;
            min2 <=32'hffff_ffff;
        end else if(~stall && isFilter)begin
            max1 <=max1_nxt;
            max2 <=max2_nxt;
            min1 <=min1_nxt;
            min2 <=min2_nxt;            
        end
    end

    


     
 endmodule