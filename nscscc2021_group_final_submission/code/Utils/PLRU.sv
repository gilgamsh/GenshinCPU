/*
 * @Author: your name
 * @Date: 2021-06-29 23:14:40
 * @LastEditTime: 2021-08-03 10:58:27
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\Code\NewCache\plru.sv
 */
`include "../Cache_Defines.svh"
`include "../CPU_Defines.svh"
module PLRU #(
    parameter int unsigned ASSOC_NUM = 4
) (
    input clk,
    input resetn,

    input [ASSOC_NUM-1:0] access, //表示这次命中了哪一路 这是独热码 access的第i位 表示第i路命中
    input update,               //表示命中了  不然就没法表示没有访存导致的不需要更新lru的情况

    output [$clog2(ASSOC_NUM)-1:0] lru  //表示 这次如果替换 替换哪一路
);

logic [ASSOC_NUM-2:0] state, state_next;

// Assign output
generate
if(ASSOC_NUM == 2) begin
    assign lru = state;
end else begin
    assign lru = state[2] == 1'b0 ? state[2-:2] : {state[2], state[0]}; //state[2-:2] 即 state[2:1]
end
endgenerate

// Update
generate
if(ASSOC_NUM == 2) begin
    always_comb begin
        state_next = state;

        if(update && |access) begin
            if(access[0]) begin
                state_next[0] = 1;//如果这次命中的是第0路 那么下次不命中的时候替换的就是1路
            end else begin
                state_next[0] = 0;
            end
        end
    end
end else  begin
    always_comb begin
        state_next = state;    //好习惯啊

        casez(access)
            4'b1???: begin
                state_next[2] = 1'b0;
                state_next[0] = 1'b0;
            end
            4'b01??: begin
                state_next[2] = 1'b0;
                state_next[0] = 1'b1;
            end
            4'b001?: begin
                state_next[2] = 1'b1;
                state_next[1] = 1'b0;
            end
            4'b0001: begin
                state_next[2] = 1'b1;
                state_next[1] = 1'b1;
            end
        endcase
    end
end 
endgenerate

always_ff @(posedge clk) begin
    if(resetn == `RstEnable) begin
        state <= '0;
    end else if(update) begin
        state <= state_next;
    end
end

endmodule

