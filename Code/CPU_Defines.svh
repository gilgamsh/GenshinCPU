/*
 * @Author: 
 * @Date: 2021-03-31 15:16:20
 * @LastEditTime: 2021-07-06 22:28:30
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
 
`ifndef CPU_Defines_SVH
`define CPU_Defines_SVH
`include "CommonDefines.svh"

typedef struct packed {
    logic HardwareInterrupt1;//硬件中断例外1
    logic HardwareInterrupt2;//硬件中断例外2
    logic HardwareInterrupt3;//硬件中断例外3
    logic HardwareInterrupt4;//硬件中断例外4
    logic HardwareInterrupt5;//硬件中断例外5
    logic HardwareInterrupt6;//硬件中断例外6
    // logic SoftwareInterrupt1;//软件中断例外1
    // logic SoftwareInterrupt2;//软件中断例外2

} AsynExceptType;//异步信号类型

typedef struct packed {
	logic Interrupt;	 	  	// 中断信号
    logic WrongAddressinIF;   	// 地址错例外——取�?
    logic ReservedInstruction;	// 保留指令例外
    logic Overflow;           	// 整型溢出例外
    logic Syscall;            	// 系统调用例外
    logic Break;              	// 断点例外
    logic Eret;               	// 异常返回指令
    logic WrWrongAddressinMEM;  // 地址错例外——数据写�?
    logic RdWrongAddressinMEM;  // 地址错例外——数据读�?
	logic TLBRefill;            // TLB 重填例外
	logic TLBInvalid;           // TLB 无效例外
	logic TLBModified;          // TLB 修改例外
	logic Refetch;              // 重取（自己定义的，用于TLBR，TLBR）
	logic Trap;                 // Trap 例外
} ExceptinPipeType;    //在流水线寄存器之间流动的异常信号

typedef enum logic [6:0] {//之所以把OP_SLL的op都大写是因为enum的值某种意义上算是一种常�?
	/* shift */
	OP_SLL, OP_SRL, OP_SRA, OP_SLLV, OP_SRLV, OP_SRAV,
	/* unconditional jump (reg) */
	OP_JALR,OP_JR,OP_J,
	/* conditional move */
	OP_MOVN, OP_MOVZ,
	/* breakpoint and syscall */
	OP_SYSCALL, OP_BREAK,
	/* HI/LO move */
	OP_MFHI, OP_MFLO, OP_MTHI, OP_MTLO,
	/* multiplication and division */
	OP_MULT, OP_MULTU, OP_DIV, OP_DIVU,
	OP_MADD, OP_MADDU, OP_MSUB, OP_MSUBU, OP_MUL,
	/* add and substract */
	OP_ADD, OP_ADDU, OP_SUB, OP_SUBU,OP_ADDI,OP_ADDIU,
	/* logical */
	OP_AND, OP_OR, OP_XOR, OP_NOR,OP_ANDI,OP_ORI,OP_XORI,
	/* compare and set */
	OP_SLT, OP_SLTU,OP_SLTI,OP_SLTIU,
	/* trap */
	OP_TGE, OP_TGEU, OP_TLT, OP_TLTU, OP_TEQ, OP_TNE,
	/* count bits */
	OP_CLZ, OP_CLO,
	/* branch */
	OP_BLTZ, OP_BGEZ, OP_BLTZAL, OP_BGEZAL,
	OP_BEQ, OP_BNE, OP_BLEZ, OP_BGTZ,
	/* set */
	OP_LUI,
	/* load */
	OP_LB, OP_LH, OP_LWL, OP_LW, OP_LBU, OP_LHU, OP_LWR,
	/* store */
	OP_SB, OP_SH, OP_SWL, OP_SW, OP_SWR,
	/* LL/SC */
	OP_LL, OP_SC,
	/* long jump */
	OP_JAL,
	/* privileged instructions */
	OP_CACHE, OP_ERET, OP_MFC0, OP_MTC0,
	OP_TLBP, OP_TLBR, OP_TLBWI, OP_TLBWR, OP_WAIT,
	/* ASIC */
	`ifdef ENABLE_ASIC
		OP_MFC2, OP_MTC2,
	`endif
	/* FPU */
	`ifdef ENABLE_FPU
		OP_MFC1, OP_MTC1, OP_CFC1, OP_CTC1,
		OP_BC1,
		OP_MOVCI,
		OP_LWC1, OP_SWC1,
		OP_LDC1A, OP_SDC1A, OP_LDC1B, OP_SDC1B,
		OP_FPU_ADD, OP_FPU_SUB, OP_FPU_COND, OP_FPU_NEG,
		OP_FPU_MUL, OP_FPU_DIV, OP_FPU_SQRT, OP_FPU_ABS,
		OP_FPU_CVTW, OP_FPU_CVTS,
		OP_FPU_TRUNC, OP_FPU_ROUND,
		OP_FPU_CEIL, OP_FPU_FLOOR,
		OP_FPU_MOV, OP_FPU_CMOV,
	`endif
	/* invalid */
	OP_INVALID
} InstrType;//一个枚举变量类�? 你可以在译码这个过程中使用，这个我是照抄Tsinghua�?

typedef struct packed {
    logic 		    	sign;//使用0表示unsigned 1表示signed
    logic   [1:0]   	size;//这个表示�? 00 word 01 half  00 word
	logic               ReadMem;//只有Load才能触发ReadMem
} LoadType;//

typedef struct packed {
    logic 	[1:0]   	size;//这个表示�? 00 byte 01 half  10 word
	logic               DMWr;//只有Store才能触发DMWr
} StoreType;//

typedef struct packed {
    logic 				RFWr;
    logic 				CP0Wr;
    logic 				HIWr;
	logic 				LOWr;
} RegsWrType;//三组寄存器的写信号的打包

typedef struct packed {
	logic 		[2:0] 		branchCode;
	logic 					isBranch;
} BranchType;

// CP0 registers

typedef struct packed {
	logic    [31:31]	 P;
	logic    [3:0]       Index;
} CP0_Index;

typedef struct packed {
	logic    [25:6]	     PFN0;
	logic    [5:3]       C0;
	logic    [2:2]       D0;
	logic    [1:1]       V0;
	logic    [0:0]       G0;
} CP0_EntryLo0;

typedef struct packed {
	logic    [25:6]	     PFN1;
	logic    [5:3]       C1;
	logic    [2:2]       D1;
	logic    [1:1]       V1;
	logic    [0:0]       G1;
} CP0_EntryLo1;

typedef struct packed {
	logic    [31:13]	 VPN2;
	logic    [7:0]       ASID;
} CP0_EntryHi;

typedef struct packed {
	// logic cu3, cu2, cu1, cu0;
	// logic rp, fr, re, mx;
	// logic px, bev, ts, sr;
	// logic nmi, zero;
	// logic [1:0] impl;
	// logic [7:0] im;
	// logic kx, sx, ux, um;
	// logic r0, erl, exl, ie;
	logic  [7:0] IM7_0;
	logic  [1:1] EXL;
	logic  [0:0] IE;
} CP0_Status;

typedef struct packed {
	// logic bd, zero30;
	// logic [1:0] ce;
	// logic [3:0] zero27_24;
	// logic iv, wp;
	// logic [5:0] zero21_16;
	// logic [7:0] ip;
	// logic zero7;
	// logic [4:0] exc_code;
	// logic [1:0] zero1_0;
	logic [31:31] BD;
	logic [30:30] TI;
	logic [15:10] IP7_2;
	logic [9:8]   IP1_0;
	logic [6:2]   ExcCode;
} CP0_Cause;

typedef struct packed {
	CP0_Index       Index;
	CP0_EntryLo0    EntryLo0;
	CP0_EntryLo1    EntryLo1;
	logic [31:0]    BadVAddr;
	logic [31:0]    Count;
	CP0_EntryHi     EntryHi;
	logic [31:0]    Compare;
	CP0_Status      Status;
	CP0_Cause  	    Cause;
} cp0_regs;
//-------------------------------------------------------------------------------------------------//
//-----------------------------------Interface Definition------------------------------------------//
//-------------------------------------------------------------------------------------------------//
interface IF_ID_Interface();

	logic       [31:0]      IF_Instr;
	logic       [31:0]      IF_PC;
	ExceptinPipeType        IF_ExceptType;
	logic       [31:0]      ID_Instr;
	logic       [31:0]      ID_PC;

	modport IF (
	output  				IF_Instr,
	output  			    IF_PC,
	output                  IF_ExceptType,
	input                   ID_Instr,
	input                   ID_PC
    );

	modport ID ( 
	input                   IF_Instr,
    input                   IF_PC,
	output                  IF_ExceptType,
	output                  ID_Instr,
	output                  ID_PC
	);
	
endinterface

interface ID_EXE_Interface();

	logic       [31:0]      ID_BusA;            //从RF中读出的A数据
	logic       [31:0]      ID_BusB;            //从RF中读出的B数据
	logic       [31:0]      ID_Imm32;           //在ID 被extend的 立即数
	logic 		[31:0]      ID_PC;
	logic       [31:0]      ID_Instr;
	logic 		[4:0]	    ID_rs;	
	logic 		[4:0]	    ID_rt;	
	logic 		[4:0]	    ID_rd;
	logic                   ID_IsTLBP;
	logic                   ID_IsTLBW;
	logic                   ID_IsTLBR;
	logic 		[`ALUOpLen] ID_ALUOp;	 		// ALU操作符
  	LoadType        		ID_LoadType;	 	// LoadType信号 
  	StoreType       		ID_StoreType;  		// StoreType信号
  	RegsWrType      		ID_RegsWrType;		// 寄存器写信号打包
  	logic 		[1:0]   	ID_WbSel;        	// 选择写回数据
  	logic 		[1:0]   	ID_DstSel;   		// 选择目标寄存器使能
  	ExceptinPipeType 		ID_ExceptType;		// 异常类型
	logic                   ID_ALUSrcA;
	logic                   ID_ALUSrcB;
	logic       [1:0]       ID_RegsReadSel;
	logic 					ID_IsAImmeJump;
	BranchType              ID_BranchType;
    logic                   EXE_IsTLBW;
    logic                   EXE_IsTLBR;
	logic                   EXE_rt;
	LoadType                EXE_LoadType;

	modport ID (
	output                  ID_BusA,            //从RF中读出的A数据
	output	                ID_BusB,            //从RF中读出的B数据
	output	                ID_Imm32,           //在ID 被extend的 立即数
	output	                ID_PC,
	output	                ID_Instr,
	output 	                ID_rs,	
	output 	                ID_rt,	
	output 	                ID_rd,	
	output	                ID_IsAImmeJump,
	output	                ID_ALUOp,	 		// ALU操作符
  	output	                ID_LoadType,	 	// LoadType信号 
  	output	                ID_StoreType,  	    // StoreType信号
  	output	                ID_RegsWrType,		// 寄存器写信号打包
  	output	                ID_WbSel,        	// 选择写回数据
  	output	                ID_DstSel,   		// 选择目标寄存器使能
  	output	                ID_ExceptType,		// 异常类型
	output	                ID_ALUSrcA,
	output	                ID_ALUSrcB,
	output	                ID_BranchType,
	output                  ID_RegsReadSel,
	output                  ID_IsTLBP,
	output                  ID_IsTLBW,
	output                  ID_IsTLBR,
	input                   EXE_IsTLBR,
	input                   EXE_IsTLBW,
	input                   EXE_rt,
	input                   EXE_LoadType
	);

	modport EXE (
	input                   ID_BusA,            //从RF中读出的A数据
	input	                ID_BusB,            //从RF中读出的B数据
	input	                ID_Imm32,           //在ID 被extend的 立即数
	input	                ID_PC,
	input	                ID_Instr,
	input 	                ID_rs,	
	input 	                ID_rt,	
	input 	                ID_rd,	
	input	                ID_IsAImmeJump,
	input	                ID_ALUOp,	 		// ALU操作符
  	input	                ID_LoadType,	 	// LoadType信号 
  	input	                ID_StoreType,  		// StoreType信号
  	input	                ID_RegsWrType,		// 寄存器写信号打包
  	input	                ID_WbSel,        	// 选择写回数据
  	input	                ID_DstSel,   		// 选择目标寄存器使能
  	input	                ID_ExceptType,		// 异常类型
	input	                ID_ALUSrcA,
	input	                ID_ALUSrcB,
	input	                ID_BranchType,
	input                   ID_RegsReadSel,
	input                   ID_IsTLBP,
	input                   ID_IsTLBW,
	input                   ID_IsTLBR,
	output                  EXE_IsTLBR,
	output                  EXE_IsTLBW,
	output                  EXE_rt,
	output                  EXE_LoadType
	);
	
endinterface

interface EXE_MEM_Interface();
	
	logic 		[31:0]  	EXE_ALUOut;   		// RF 中读取到的数据A
  	logic       [31:0]      EXE_Hi;
	logic       [31:0]      EXE_Lo;
	logic 		[31:0]  	EXE_OutB;	 		// RF 中读取到的数据B
  	logic 		[4:0]    	EXE_Dst;  		    // 符号扩展之后�?32位立即数
  	logic 		[31:0] 	    EXE_PC; 		    // PC
	logic 		[31:0]   	EXE_Instr;
	logic 					EXE_IsAImmeJump;
  	LoadType        		EXE_LoadType;	 	// LoadType信号 
  	StoreType       		EXE_StoreType;  	// StoreType信号
  	RegsWrType      		EXE_RegsWrType;		// 寄存器写信号打包
	RegsWrType              MEM_RegsWrType;
	logic       [4:0]       MEM_Dst;
	logic       [31:0]      MEM_Result;
  	logic 		[1:0]   	EXE_WbSel;        	// 选择写回数据
  	ExceptinPipeType 		EXE_ExceptType_final;		// 异常类型
	BranchType              EXE_BranchType;
	logic       [3:0]       DCache_Wen;
	logic                   EXE_IsTLBP;
	logic                   EXE_IsTLBW;
	logic                   EXE_IsTLBR;
	logic       [1:0]       EXE_RegsReadSel;

	modport EXE (
	output      	        EXE_ALUOut,   		// RF 中读取到的数据A
  	output                  EXE_Hi,
	output                  EXE_Lo,
	output      	        EXE_OutB,	 		// RF 中读取到的数据B
  	output      	        EXE_Dst, 		    // 符号扩展之后�?32位立即数
  	output      	        EXE_PC, 		    // PC
	output      	        EXE_Instr,
	output                  EXE_IsAImmeJump,
  	output      	        EXE_LoadType,	 	// LoadType信号 
  	output      	        EXE_StoreType,  	// StoreType信号
   	output      	        EXE_RegsWrType,		// 寄存器写信号打包
  	output                  EXE_WbSel,        	// 选择写回数据
    output                  EXE_ExceptType_final,		// 异常类型
	output                  EXE_BranchType,
	output                  DCache_Wen,         //DCache的字节写使能
	output                  EXE_IsTLBP,
	output                  EXE_IsTLBW,
	output                  EXE_IsTLBR,
	output                  EXE_RegsReadSel,
	input                   MEM_RegsWrType,     //下面三个是MEM级给EXE级的旁路
	input                   MEM_Dst,
	input                   MEM_Result          //
	);

	modport MEM (
	input      	            EXE_ALUOut,   		// RF 中读取到的数据A
  	input                   EXE_Hi,
	input                   EXE_Lo,
	input      	            EXE_OutB,	 		// RF 中读取到的数据B
  	input      	            EXE_Dst, 		    // 符号扩展之后�?32位立即数
  	input      	            EXE_PC, 		    // PC
	input      	            EXE_Instr,
	input                   EXE_IsAImmeJump,
  	input      	            EXE_LoadType,	 	// LoadType信号 
  	input      	            EXE_StoreType,      // StoreType信号
   	input      	            EXE_RegsWrType,		// 寄存器写信号打包
  	input                   EXE_WbSel,        	// 选择写回数据
    input                   EXE_ExceptType_final,		// 异常类型
	input                   EXE_BranchType,
	input                   DCache_Wen,
	input                   EXE_IsTLBP,
	input                   EXE_IsTLBW,
	input                   EXE_IsTLBR,
	input                   EXE_RegsReadSel,
	output                  MEM_RegsWrType,
	output                  MEM_Dst,
	output                  MEM_Result
	);

endinterface

interface MEM_WB_Interface();

    logic		[31:0] 		MEM_ALUOut;	
	logic       [31:0]      MEM_Hi;
	logic       [31:0]      MEM_Lo;		
    logic 		[31:0] 		MEM_PC;	
	logic       [31:0]      MEM_Instr;		
    logic 		[1:0]  		MEM_WbSel;				
    logic 		[4:0]  		MEM_Dst;
	LoadType     			MEM_LoadType;
	logic 		[31:0] 		MEM_DMOut;
	logic       [31:0]      MEM_OutB;
	RegsWrType              MEM_RegsWrType_final;//经过exception solvement的新写使能
	ExceptinPipeType 		MEM_ExceptType_final;
	logic                   MEM_IsABranch;
	logic                   MEM_IsAImmeJump;
	logic                   MEM_IsInDelaySlot;
	logic                   WB_IsABranch;
	logic                   WB_IsAImmeJump;
	logic                   MEM_IsTLBW;
	logic                   MEM_IsTLBR;
  
	modport MEM ( 
	input                   WB_IsABranch,
	input                   WB_IsAImmeJump,	
    output					MEM_ALUOut,		
	output                  MEM_Hi,
	output                  MEM_Lo,	
    output					MEM_PC,		
	output                  MEM_Instr,	
    output					MEM_WbSel,				
    output					MEM_Dst,
    output					MEM_LoadType,
	output					MEM_DMOut,
	output                  MEM_OutB,
	output					MEM_RegsWrType_final,//经过exception solvement的新写使能
	output					MEM_ExceptType_final,
	output					MEM_IsABranch,
	output					MEM_IsAImmeJump,
	output                  MEM_IsInDelaySlot,
	output                  MEM_IsTLBW,
	output                  MEM_IsTLBR
	);

	modport WB ( 
	input					MEM_ALUOut,		
	input                   MEM_Hi,
	input                   MEM_Lo,	
    input					MEM_PC,		
	input                   MEM_Instr,	
    input					MEM_WbSel,				
    input					MEM_Dst,
    input					MEM_LoadType,
	input					MEM_DMOut,
	input                   MEM_OutB,
	input					MEM_RegsWrType_final,//经过exception solvement的新写使能
	input					MEM_ExceptType_final,
	input					MEM_IsABranch,
	input					MEM_IsAImmeJump,
	input                   MEM_IsInDelaySlot,
	input                   MEM_IsTLBW,
	input                   MEM_IsTLBR,
	output                  WB_IsABranch,
	output                  WB_IsAImmeJump
	);

endinterface

// interface WB_CP0_Interface ();
    
// 	logic                   WB_CP0Wr_MTC0;
// 	logic                   WB_CP0Wr_TLBR;
// 	logic [4:0]             WB_Dst;
// 	logic [31:0]            WB_Result;
// 	ExceptinPipeType        WB_ExceptType;
// 	logic [31:0]            WB_PC;
// 	logic                   WB_IsInDelaySlot;
// 	logic [31:0]            WB_ALUOut;
// 	logic                   WB_IsTLBR;

// 	modport WB ( 
//     output                  WB_CP0Wr_MTC0,
// 	output                  WB_CP0Wr_TLBR,
// 	output                  WB_Dst,
// 	output                  WB_Result,
// 	output                  WB_ExceptType,
// 	output                  WB_PC,
// 	output                  WB_IsInDelaySlot,
// 	output                  WB_ALUOut,
// 	output                  WB_IsTLBR
// 	);

// 	modport CP0 ( 
//     input                   WB_CP0Wr_MTC0,
// 	input                   WB_CP0Wr_TLBR,
// 	input                   WB_Dst,
// 	input                   WB_Result,
// 	input                   WB_ExceptType,
// 	input                   WB_PC,
// 	input                   WB_IsInDelaySlot,
// 	input                   WB_ALUOut,
// 	input                   WB_IsTLBR
// 	);

// endinterface

interface CP0_MMU_Interface ();

    logic [18:0]            CP0_vpn2;
	logic [7:0]             CP0_asid;
	logic [19:0]            CP0_pfn0;
	logic [2:0]             CP0_c0;
	logic                   CP0_d0;
	logic                   CP0_v0;
	logic                   CP0_g0;
	logic [19:0]            CP0_pfn1;
	logic [2:0]             CP0_c1;
	logic                   CP0_d1;
	logic                   CP0_v1;
	logic                   CP0_g1;
	logic [3:0]             CP0_index; //16项的TLB，log16,所以位宽是4
    logic [18:0]            MMU_vpn2;
	logic [7:0]             MMU_asid;
	logic [19:0]            MMU_pfn0;
	logic [2:0]             MMU_c0;
	logic                   MMU_d0;
	logic                   MMU_v0;
	logic                   MMU_g0;
	logic [19:0]            MMU_pfn1;
	logic [2:0]             MMU_c1;
	logic                   MMU_d1;
	logic                   MMU_v1;
	logic                   MMU_g1;
	logic [3:0]             MMU_index;
	logic                   MMU_s1found;

	modport CP0 ( 
    output                  CP0_vpn2,
	output                  CP0_asid,
	output                  CP0_pfn0,
	output                  CP0_c0,
	output                  CP0_d0,
	output                  CP0_v0,
	output                  CP0_g0,
	output                  CP0_pfn1,
	output                  CP0_c1,
	output                  CP0_d1,
	output                  CP0_v1,
	output                  CP0_g1,
	output                  CP0_index,
	input                   MMU_vpn2,
	input                   MMU_asid,
	input                   MMU_pfn0,
	input                   MMU_c0,
	input                   MMU_d0,
	input                   MMU_v0,
	input                   MMU_g0,
	input                   MMU_pfn1,
	input                   MMU_c1,
	input                   MMU_d1,
	input                   MMU_v1,
	input                   MMU_g1,
	input                   MMU_index,
	input                   MMU_s1found
	);

	modport MMU ( 
    input                   CP0_vpn2,
	input                   CP0_asid,
	input                   CP0_pfn0,
	input                   CP0_c0,
	input                   CP0_d0,
	input                   CP0_v0,
	input                   CP0_g0,
	input                   CP0_pfn1,
	input                   CP0_c1,
	input                   CP0_d1,
	input                   CP0_v1,
	input                   CP0_g1,
	input                   CP0_index,
	output                  MMU_vpn2,
	output                  MMU_asid,
	output                  MMU_pfn0,
	output                  MMU_c0,
	output                  MMU_d0,
	output                  MMU_v0,
	output                  MMU_g0,
	output                  MMU_pfn1,
	output                  MMU_c1,
	output                  MMU_d1,
	output                  MMU_v1,
	output                  MMU_g1,
	output                  MMU_index,
    output                  MMU_s1found
	);

endinterface
//-----------------------------------------------------------------------------------------//

`endif 