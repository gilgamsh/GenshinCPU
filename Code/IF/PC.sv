/*
 * @Author: npuwth
 * @Date: 2021-04-02 16:23:07
 * @LastEditTime: 2021-07-03 09:47:57
 * @LastEditors: Please set LastEditors
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module PC( 
    input logic           clk,
    input logic           rst,
    input logic           PC_Wr,
    input logic  [31:0]   IF_NPC,
    output logic [31:0]   IF_PC
);
  
  always_ff @( posedge clk ) begin
    if( rst == `RstEnable )
      IF_PC <= `PCRstAddr;
    else if( PC_Wr )
      IF_PC <= IF_NPC;
  end

endmodule