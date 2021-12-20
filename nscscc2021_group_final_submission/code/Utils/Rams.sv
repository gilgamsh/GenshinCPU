/*
 * @Author: your name
 * @Date: 2021-07-06 11:14:04
 * @LastEditTime: 2021-08-16 06:20:19
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \NewCache\Rams.sv
 */
module simple_port_lutram #(
	// default data width if the fifo is of type logic
	parameter int unsigned DATA_WIDTH  = 32,
	// $bits(dtype) * SIZE = bits of the block RAM
	parameter int unsigned SIZE        = 1024, //指有多少块
	parameter type dtype               = logic [DATA_WIDTH-1:0],
	parameter int unsigned LATENCY     = 0,
	parameter int unsigned MEMORY_SIZE = $bits(dtype) * SIZE,
	parameter int unsigned ADDR_WIDTH  = $clog2(SIZE)
) (
	input  logic  clka,
	input  logic  rsta,
	input  logic  wea,
	input  logic  ena,
	input  logic  [$clog2(SIZE)-1:0] addra,
	input  dtype  dina,
	output dtype  douta
);

   xpm_memory_spram #(
      .ADDR_WIDTH_A(ADDR_WIDTH),               // DECIMAL
      .AUTO_SLEEP_TIME(0),                     // DECIMAL
      .BYTE_WRITE_WIDTH_A($bits(dtype)),       // DECIMAL
      //.CASCADE_HEIGHT(0),            		   // DECIMAL
      .ECC_MODE("no_ecc"),           		   // String
      .MEMORY_INIT_FILE("none"),     		   // String
      .MEMORY_INIT_PARAM("0"),       		   // String
      .MEMORY_OPTIMIZATION("true"),  		   // String
      .MEMORY_PRIMITIVE("auto"),     		   // String
      .MEMORY_SIZE(MEMORY_SIZE),     		   // DECIMAL
      .MESSAGE_CONTROL(0),           		   // DECIMAL
      .READ_DATA_WIDTH_A($bits(dtype)),        // DECIMAL
      .READ_LATENCY_A(LATENCY),            	   // DECIMAL
      .READ_RESET_VALUE_A("0"),      		   // String
      //.RST_MODE_A("SYNC"),           		   // String
      //.SIM_ASSERT_CHK(0),            		   // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_MEM_INIT(1),              		   // DECIMAL
      .WAKEUP_TIME("disable_sleep"), 		   // String
      .WRITE_DATA_WIDTH_A($bits(dtype)),       // DECIMAL
      .WRITE_MODE_A("read_first")    		   // String
   )
   xpm_memory_spram_inst (
      .dbiterra(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .douta(douta),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .sbiterra(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port A.

      .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .clka(clka),                     // 1-bit input: Clock signal for port A.
      .dina(dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regcea(1'b0),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rsta(rsta),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(wea)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );

endmodule

module simple_port_ram #(
	// default data width if the fifo is of type logic
	parameter int unsigned DATA_WIDTH = 32,
	parameter int unsigned LATENCY    = 1,
	// $bits(dtype) * SIZE = bits of the block RAM
	parameter int unsigned SIZE        = 1024, //指有多少块
	parameter type dtype               = logic [DATA_WIDTH-1:0],
	parameter int unsigned MEMORY_SIZE = $bits(dtype) * SIZE,
	parameter int unsigned ADDR_WIDTH  = $clog2(SIZE)
) (
	input  logic  clk,
	input  logic  rst,
	input  logic  wea,
	input  logic  ena,
	input  logic  enb,
	input  logic  [$clog2(SIZE)-1:0] addra,
	input  logic  [$clog2(SIZE)-1:0] addrb,
	input  dtype  dina,
	output dtype  doutb
);

// xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2019.2
   logic valid;
   dtype doutb_bypass;
   dtype doutb_byram ;
   always_ff @( posedge clk) begin : doutb_by_pass_blockName
      if (enb) begin//如果是读端口读使能打开
         if (wea & ena & addra == addrb) begin//那么检测是否需要写优先
            valid <= 1'b1;
            doutb_bypass <= dina;
         end else begin
            valid <= 1'b0;
         end
      end
   end
   assign doutb = (valid) ? doutb_bypass : doutb_byram;
   xpm_memory_sdpram #(
      .ADDR_WIDTH_A(ADDR_WIDTH),               // DECIMAL
      .ADDR_WIDTH_B(ADDR_WIDTH),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A($bits(dtype)),        // DECIMAL
      //.CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String distributed
      .MEMORY_SIZE(MEMORY_SIZE),             // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B($bits(dtype)),         // DECIMAL
      .READ_LATENCY_B(LATENCY),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      //.RST_MODE_A("SYNC"),            // String
      //.RST_MODE_B("SYNC"),            // String
      //.SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A($bits(dtype)),        // DECIMAL
      .WRITE_MODE_B("read_first")      // String
   )
   xpm_memory_sdpram_inst (
      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port B.

      .doutb(doutb_byram),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
      .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
      .clka(clk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when write operations are initiated. Pipelined internally.

      .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.

      .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regceb(1'b0),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rstb(rst),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(wea)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );

endmodule



module simple_port_ram_without_bypass #(
	// default data width if the fifo is of type logic
	parameter int unsigned DATA_WIDTH = 32,
	parameter int unsigned LATENCY    = 1,
	// $bits(dtype) * SIZE = bits of the block RAM
	parameter int unsigned SIZE        = 1024, //指有多少块
	parameter type dtype               = logic [DATA_WIDTH-1:0],
	parameter int unsigned MEMORY_SIZE = $bits(dtype) * SIZE,
	parameter int unsigned ADDR_WIDTH  = $clog2(SIZE)
) (
	input  logic  clk,
	input  logic  rst,
	input  logic  wea,
	input  logic  ena,
	input  logic  enb,
	input  logic  [$clog2(SIZE)-1:0] addra,
	input  logic  [$clog2(SIZE)-1:0] addrb,
	input  dtype  dina,
	output dtype  doutb
);

// xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2019.2

   xpm_memory_sdpram #(
      .ADDR_WIDTH_A(ADDR_WIDTH),               // DECIMAL
      .ADDR_WIDTH_B(ADDR_WIDTH),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A($bits(dtype)),        // DECIMAL
      //.CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String distributed
      .MEMORY_SIZE(MEMORY_SIZE),             // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B($bits(dtype)),         // DECIMAL
      .READ_LATENCY_B(LATENCY),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      //.RST_MODE_A("SYNC"),            // String
      //.RST_MODE_B("SYNC"),            // String
      //.SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A($bits(dtype)),        // DECIMAL
      .WRITE_MODE_B("read_first")      // String
   )
   xpm_memory_sdpram_inst (
      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port B.

      .doutb(doutb),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
      .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
      .clka(clk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when write operations are initiated. Pipelined internally.

      .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.

      .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regceb(1'b0),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rstb(rst),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(wea)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );

endmodule