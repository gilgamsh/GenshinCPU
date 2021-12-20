/*
 * @Author: npuwth
 * @Date: 2021-04-02 16:23:07
 * @LastEditTime: 2021-08-13 20:38:55
 * @LastEditors: npuwth
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
    input logic           PREIF_Wr,
    input logic  [31:0]   PREIF_NPC,
    output logic [31:0]   PREIF_PC
);
  
  always_ff @( posedge clk ) begin
    if( rst == `RstEnable )
      PREIF_PC <= `PCRstAddr;
    else if( PREIF_Wr )
      PREIF_PC <= PREIF_NPC;
  end

endmodule