/*
 * @Author: 
 * @Date: 2021-03-31 15:16:20
 * @LastEditTime: 2021-08-18 14:31:56
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
 
`ifndef CPU_Defines_SVH
`define CPU_Defines_SVH
`include "CommonDefines.svh"
`include "Cache_options.svh"

// typedef struct packed {
//     logic HardwareInterrupt1;//硬件中断例外1
//     logic HardwareInterrupt2;//硬件中断例外2
//     logic HardwareInterrupt3;//硬件中断例外3
//     logic HardwareInterrupt4;//硬件中断例外4
//     logic HardwareInterrupt5;//硬件中断例外5
//     logic HardwareInterrupt6;//硬件中断例外6
// } AsynExceptType;//异步信号类型

typedef struct packed {
	logic Interrupt;	 	  	// 中断信号
    logic WrongAddressinIF;   	// 地址错例外——取指
    logic ReservedInstruction;	// 保留指令例外
	logic CoprocessorUnusable;  // 协处理器异常
    logic Overflow;           	// 整型溢出例外
    logic Syscall;            	// 系统调用例外
    logic Break;              	// 断点例外
    logic Eret;               	// 异常返回指令
    logic WrWrongAddressinMEM;  // 地址错例外——数据写
    logic RdWrongAddressinMEM;  // 地址错例外——数据读
	logic TLBRefillinIF;        // 取指TLB重填例外
	logic TLBInvalidinIF;       // 取指TLB无效例外
	logic RdTLBRefillinMEM;     // 取数TLB重填例外  
	logic RdTLBInvalidinMEM;    // 取数TLB无效例外  
	logic WrTLBRefillinMEM;     // 写数TLB重填例外     
	logic WrTLBInvalidinMEM;    // 写数TLB无效例外
	logic TLBModified;          // TLB 修改例外
	logic Trap;                 // Trap 例外
	logic Refetch;              // 重取（自己定义的，用于TLBR，TLBW，MTC0的EntryHi）
} ExceptinPipeType;    //在流水线寄存器之间流动的异常信号

typedef enum logic [6:0] {//之所以把OP_SLL的op都大写是因为enum的值某种意义上算是一种常量
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
	OP_TGEI, OP_TGEIU, OP_TLTI, OP_TLTIU, OP_TEQI, OP_TNEI,
	/* count bits */
	OP_CLZ, OP_CLO,OP_FILTER,
	/* branch */
	OP_BLTZ, OP_BGEZ, OP_BLTZAL, OP_BGEZAL,
	OP_BEQ, OP_BNE, OP_BLEZ, OP_BGTZ,OP_BEQL,OP_BNEL,
	/* set */
	OP_LUI,
	/* load */
	OP_LB, OP_LH, OP_LWL, OP_LW, OP_LBU, OP_LHU, OP_LWR,
	/* store */
	OP_SB, OP_SH, OP_SWL, OP_SW, OP_SWR,
	/* LL/SC */
	OP_LL, OP_SC,
	/* SYNC */ 
	OP_SYNC,
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
	/*Multi Core(NOP)*/
	/* invalid */
	OP_NOP,
	OP_INVALID
} InstrType;//一个枚举变量类型 你可以在译码这个过程中使用，这个我是照抄Tsinghua

typedef struct packed {
    logic 		    	sign;//使用0表示unsigned 1表示signed
    logic   [1:0]   	size;//这个表示�? 00 word 01 half  00 word
	logic               ReadMem;//只有Load才能触发ReadMem
	logic   [1:0]       LeftOrRight; // 10表示left 01 表示right
} LoadType;//

typedef struct packed {
    logic 	[1:0]   	size;//这个表示�? 00 byte 01 half  10 word
	logic               DMWr;//只有Store才能触发DMWr
	logic   [1:0]       LeftOrRight; // 10表示left 01 表示right
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

typedef enum logic [2:0] { 
	I_Index_Invalid,
	I_Index_Store_Tag,
	I_Hit_Invalid,

	D_Index_Writeback_Invalid,
	D_Index_Store_Tag,
	D_Hit_Invalid,
	D_Hit_Writeback_Invalid
} CacheCodeType;



typedef struct packed {
	CacheCodeType       	cacheCode;
	logic                   isCache;
	logic 					isIcache;
	logic 					isDcache;	
} CacheType;

// CP0 registers

typedef struct packed {
	logic    [31:31]	 P;
	logic    [2:0]       Index;
} CP0_Index;

typedef struct packed {
	logic    [2:0]       Random;
} CP0_Random;

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
	logic    [31:23]     PTEBase;
	logic    [22:4]      BadVPN2;
} CP0_Context;

typedef struct packed {
	logic    [2:0]       Wired;
} CP0_Wired;

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
	logic  [28:28]  CU0;
	logic  [22:22]  BEV;
	logic  [7:0]    IM7_0;
	logic  [4:4]    UM;
	logic  [3:3]    ERL;
	logic  [1:1]    EXL;
	logic  [0:0]    IE;
} CP0_Status;

typedef struct packed {
	// logic bd, zero30;
	// logic [3:0] zero27_24;
	// logic iv, wp;
	// logic [5:0] zero21_16;
	// logic [7:0] ip;
	// logic zero7;
	// logic [4:0] exc_code;
	// logic [1:0] zero1_0;
	logic [31:31] BD;
	logic [30:30] TI;
	logic [29:28] CE;
	logic [15:10] IP7_2;
	logic [9:8]   IP1_0;
	logic [6:2]   ExcCode;
} CP0_Cause;

typedef struct packed {
	logic [31:31] M;
	logic [30:25] MMUSize;  // 实际TLB项数-1
	logic [24:22] IS;       // I$  Icache 一路内的行数
	logic [21:19] IL;		// I$  Icacheline大小
	logic [18:16] IA;		// I$  Icache 相连度
	logic [15:13] DS;		// D$  Dcache 一路内的行数
	logic [12:10] DL;		// D$  Dcacheline大小
	logic [9:7]   DA;		// D$  Dcache 相连度
} CP1_Config1;

typedef struct packed {
	CP0_Index       Index;     // 0号
	CP0_Random		Random;    // 1号
	CP0_EntryLo0    EntryLo0;  // 2号
	CP0_EntryLo1    EntryLo1;  // 3号
	CP0_Context     Context;   // 4号
	logic [31:0]	PageMask;  // 5号
	CP0_Wired   	Wired;     // 6号
	logic [31:0]    BadVAddr;  // 8号
	logic [31:0]    Count;     // 9号
	CP0_EntryHi     EntryHi;   // 10号
	logic [31:0]    Compare;   // 11号
	CP0_Status      Status;    // 12号
	CP0_Cause  	    Cause;     // 13号
	logic [31:0]    EPC;       // 14号
	logic [31:0]    Prid;      // 15号 sel 0
	logic [31:0]    Ebase;     // 15号 sel 1
	logic [31:0]    Config0;   // 16号 sel 0 
	CP1_Config1     Config1;   // 16号 sel 1  只读寄存器
	logic [31:0]    ErrorEPC;
} cp0_regs;

typedef struct packed {  
	logic [31:13]   VPN2;
	logic [7:0]     ASID;
	logic           G;
	logic [25:6]    PFN0;
	logic [5:3]     C0;
	logic [2:2]     D0;
	logic [1:1]     V0;
	logic [25:6]    PFN1;
	logic [5:3]     C1;
	logic [2:2]     D1;
	logic [1:1]     V1;
	logic           IsInTLB;
	logic           Valid;
} TLB_Buffer;

typedef struct packed {  //一个TLB项
	logic [31:13]   VPN2;
	logic [7:0]     ASID;
	logic           G;
	logic [25:6]    PFN0;
	logic [5:3]     C0;
	logic [2:2]     D0;
	logic [1:1]     V0;
	logic [25:6]    PFN1;
	logic [5:3]     C1;
	logic [2:2]     D1;
	logic [1:1]     V1;
} TLB_Entry;

typedef struct packed {
    logic [2:0]                Type;     //表示预测的类型
    logic                      IsTaken;  //表示预测是否跳转
    logic [31:0]               Target;   //表示预测的跳转地址
    logic [1:0]                Count;    //表示预测时的计数器值
    logic                      Hit;      //表示预测时BHT是否命中
    logic                      Valid;    //表示预测是否有效
	// logic [1:0]                History;  //预测时的历史跳转信息
	// logic [7:0]                Index;
} PResult;

typedef struct packed {
    logic [2:0]                Type;     //表示实际的类型
    logic                      IsTaken;  //表示实际是否跳转
    logic [31:0]               Target;   //表示实际的跳转地址
    logic [31:0]               PC;       //需要校准的PC
    logic [1:0]                Count;    //预测该条指令时的Count
    logic                      Hit;      //预测该指令时的BHT_hit
    logic                      Valid;    //预测是否有效
	// logic [1:0]                History;  //预测时的历史跳转信息
	// logic                      RetnSuccess;//JR预测成功
	// logic [7:0]                Index;
} BResult;

typedef struct packed {
    logic [31:`SIZE_OF_INDEX+2]Tag;   //PC的Tag
    logic [31:0]               Target;
    logic [2:0]                Type;  //分支种类
    logic [1:0]                Count; //二位饱和计数器
} BHT_Entry;

typedef struct packed {
	logic                      Valid;
	logic [31:0]               Addr;
} RAS_EntryType;

typedef struct packed {
    logic [31:`SIZE_OF_INDEX+2]Tag;       //Tag in BHT
    logic [31:`SIZE_OF_INDEX+2]PCTag;     //Tag of PC
    logic [31:0]               BHT_Addr;  //Target Address in BHT
    RAS_EntryType              RAS_Entry; //Target Address in RAS
    logic [31:0]               PC_Add8;   //pc+8
    logic [2:0]                Type;      //Type in BHT
    logic [1:0]                Count;     //Count in BHT
	logic                      Valid;
	// logic [7:0]                Index;
} BPU_RegType;
//-------------------------------------------------------------------------------------------------//
//-----------------------------------Interface Definition------------------------------------------//
//-------------------------------------------------------------------------------------------------//
interface PREIF_IF_Interface();
	logic       [31:0]      PREIF_PC;
	ExceptinPipeType        PREIF_ExceptType;
	logic       [31:0]      IF_Target;
	logic                   IF_BPUValid;

	modport PREIF ( 
	output                  PREIF_PC,
	output                  PREIF_ExceptType,
	input                   IF_Target,
	input                   IF_BPUValid
	);

	modport IF ( 
	input                   PREIF_PC,
	input                   PREIF_ExceptType,
	output                  IF_Target,
	output                  IF_BPUValid
	);

endinterface

interface IF_ID_Interface();

	logic       [31:0]      IF_Instr;
	logic       [31:0]      IF_PC;
	ExceptinPipeType        IF_ExceptType;
	PResult                 IF_PResult;
	logic                   IF_Valid;
	logic                   ID_IsBranch;

	modport IF (
	output  				IF_Instr,
	output  			    IF_PC,
	output                  IF_ExceptType,
	output                  IF_PResult,
	output                  IF_Valid,
	input                   ID_IsBranch
    );

	modport ID ( 
	input                   IF_Instr,
    input                   IF_PC,
	input                   IF_ExceptType,
	input                   IF_PResult,
	input                   IF_Valid,
	output                  ID_IsBranch
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
	logic                   ID_TLBWIorR;
	logic 		[`ALUOpLen] ID_ALUOp;	 		// ALU操作符
  	LoadType        		ID_LoadType;	 	// LoadType信号 
  	StoreType       		ID_StoreType;  		// StoreType信号
	logic       [2:0]	    ID_TrapOp;
	logic        			ID_IsBrchLikely;
  	RegsWrType      		ID_RegsWrType;		// 寄存器写信号打包
  	logic 		[1:0]   	ID_WbSel;        	// 选择写回数据
  	logic 		[1:0]   	ID_DstSel;   		// 选择目标寄存器使能
  	ExceptinPipeType 		ID_ExceptType_new;		// 异常类型
	logic                   ID_ALUSrcA;
	logic                   ID_ALUSrcB;
	logic       [1:0]       ID_RegsReadSel;
	logic 					ID_IsAJumpCall;
	BranchType              ID_BranchType;
	PResult                 ID_PResult;
	logic                   ID_IsMFC0;
	// logic                   ID_Branch_Success;
	logic                   ID_J_Success;
	logic                   ID_PC8_Success;
	logic       [31:0]      ID_JumpAddr;
	logic       [31:0]      ID_BranchAddr;
	logic       [31:0]      ID_PCAdd8;
	CacheType               ID_CacheType;
	logic                   ID_IsMOVN;
	logic                   ID_IsMOVZ;
	logic                   ID_Valid;
	logic       [4:0]       EXE_rt;
	LoadType                EXE_LoadType;
	logic                   EXE_IsMFC0;
	RegsWrType              EXE_RegsWrType;
	logic       [4:0]       EXE_Dst;
	logic       [31:0]      EXE_Result;

	modport ID (
	output                  ID_BusA,            //从RF中读出的A数据
	output	                ID_BusB,            //从RF中读出的B数据
	output	                ID_Imm32,           //在ID 被extend的 立即数
	output	                ID_PC,
	output	                ID_Instr,
	output 	                ID_rs,	
	output 	                ID_rt,	
	output 	                ID_rd,	
	output	                ID_IsAJumpCall,
	output	                ID_ALUOp,	 		// ALU操作符
  	output	                ID_LoadType,	 	// LoadType信号 
  	output	                ID_StoreType,  	    // StoreType信号
	output   			    ID_TrapOp,          // 自陷异常
	output 			  	    ID_IsBrchLikely,    // 是否是branchlikely
  	output	                ID_RegsWrType,		// 寄存器写信号打包
  	output	                ID_WbSel,        	// 选择写回数据
  	output	                ID_DstSel,   		// 选择目标寄存器使能
  	output	                ID_ExceptType_new,		// 异常类型
	output	                ID_ALUSrcA,
	output	                ID_ALUSrcB,
	output	                ID_BranchType,
	output                  ID_RegsReadSel,
	output                  ID_IsTLBP,
	output                  ID_IsTLBW,
	output                  ID_IsTLBR,
	output                  ID_TLBWIorR,
	output                  ID_PResult,
	output                  ID_IsMFC0,
	output                  ID_J_Success,
	output                  ID_PC8_Success,
	output                  ID_JumpAddr,
	output                  ID_BranchAddr,	
	output                  ID_PCAdd8,
	output                  ID_CacheType,
	output                  ID_IsMOVN,
	output                  ID_IsMOVZ,
	output                  ID_Valid,
	input                   EXE_rt,
	input                   EXE_LoadType,
	input                   EXE_IsMFC0,
	input                   EXE_RegsWrType,
	input                   EXE_Dst,
	input                   EXE_Result
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
	input	                ID_IsAJumpCall,
	input	                ID_ALUOp,	 		// ALU操作符
  	input	                ID_LoadType,	 	// LoadType信号 
  	input	                ID_StoreType,  		// StoreType信号
	input   			    ID_TrapOp,          // 自陷异常
	input 					ID_IsBrchLikely,    // 是否为branch likely指令
  	input	                ID_RegsWrType,		// 寄存器写信号打包
  	input	                ID_WbSel,        	// 选择写回数据
  	input	                ID_DstSel,   		// 选择目标寄存器使能
  	input	                ID_ExceptType_new,		// 异常类型
	input	                ID_ALUSrcA,
	input	                ID_ALUSrcB,
	input	                ID_BranchType,
	input                   ID_RegsReadSel,
	input                   ID_IsTLBP,
	input                   ID_IsTLBW,
	input                   ID_IsTLBR,
	input                   ID_TLBWIorR,
	input                   ID_PResult,
	input                   ID_IsMFC0,
	input                   ID_J_Success,
	input                   ID_PC8_Success,
	input                   ID_JumpAddr,
	input                   ID_BranchAddr,
	input                   ID_PCAdd8,
	input                   ID_CacheType,
	input                   ID_IsMOVN,
	input                   ID_IsMOVZ,
	input                   ID_Valid,
	output                  EXE_rt,
	output                  EXE_LoadType,
	output                  EXE_IsMFC0,
	output                  EXE_RegsWrType,
	output                  EXE_Dst,
	output                  EXE_Result
	);
	
endinterface

interface EXE_MEM_Interface();
	
	logic 		[31:0]  	EXE_ALUOut;   		// RF 中读取到的数据A
	logic 		[31:0]  	EXE_OutB;	 		// RF 中读取到的数据B
  	logic 		[31:0] 	    EXE_PC; 		    // PC
	logic 		[31:0]   	EXE_Instr;
	BranchType              EXE_BranchType;
  	LoadType        		EXE_LoadType;	 	// LoadType信号 
  	StoreType       		EXE_StoreType;  	// StoreType信号
  	logic 		[4:0]    	EXE_Dst;  		    // 符号扩展之后�?32位立即数
  	RegsWrType      		EXE_RegsWrType;		// 寄存器写信号打包
  	logic 		[1:0]   	EXE_WbSel;        	// 选择写回数据
  	ExceptinPipeType 		EXE_ExceptType_final;// 异常类型
	logic                   EXE_IsTLBP;
	logic                   EXE_IsTLBW;
	logic                   EXE_IsTLBR;
	logic                   EXE_TLBWIorR;
	logic       [1:0]       EXE_RegsReadSel;
	logic       [4:0]       EXE_rd;
	logic       [31:0]      EXE_Result;
	logic                   EXE_IsMFC0;
	CacheType               EXE_CacheType;
	// logic       [4:0]       MEM_Dst;
	// logic                   MEM_IsTLBR;
	// logic                   MEM_IsTLBW;
	// logic                   MEM_RegsWrTypeCP0Wr;
	// CacheType               MEM_CacheType;

	modport EXE (
	output      	        EXE_ALUOut,   		// RF 中读取到的数据A
	output      	        EXE_OutB,	 		// RF 中读取到的数据B
  	output      	        EXE_Dst, 		    // 符号扩展之后�?32位立即数
  	output      	        EXE_PC, 		    // PC
	output      	        EXE_Instr,
  	output      	        EXE_LoadType,	 	// LoadType信号 
  	output      	        EXE_StoreType,  	// StoreType信号
   	output      	        EXE_RegsWrType,		// 寄存器写信号打包
  	output                  EXE_WbSel,        	// 选择写回数据
    output                  EXE_ExceptType_final,		// 异常类型
	output                  EXE_BranchType,
	output                  EXE_IsTLBP,
	output                  EXE_IsTLBW,
	output                  EXE_IsTLBR,
	output                  EXE_TLBWIorR,
	output                  EXE_RegsReadSel,
	output                  EXE_rd,
	output                  EXE_Result,
	output                  EXE_IsMFC0,
	output                  EXE_CacheType
	// input                   MEM_Dst,
	// input                   MEM_IsTLBR,
	// input                   MEM_IsTLBW,
	// input                   MEM_RegsWrTypeCP0Wr,
	// input                   MEM_CacheType
	);

	modport MEM (
	input      	            EXE_ALUOut,   		// RF 中读取到的数据A
	input      	            EXE_OutB,	 		// RF 中读取到的数据B
  	input      	            EXE_Dst, 		    // 符号扩展之后�?32位立即数
  	input      	            EXE_PC, 		    // PC
	input      	            EXE_Instr,
  	input      	            EXE_LoadType,	 	// LoadType信号 
  	input      	            EXE_StoreType,      // StoreType信号
   	input      	            EXE_RegsWrType,		// 寄存器写信号打包
  	input                   EXE_WbSel,        	// 选择写回数据
    input                   EXE_ExceptType_final,		// 异常类型
	input                   EXE_BranchType,
	input                   EXE_IsTLBP,
	input                   EXE_IsTLBW,
	input                   EXE_IsTLBR,
	input                   EXE_TLBWIorR,
	input                   EXE_RegsReadSel,
	input                   EXE_rd,
	input                   EXE_Result,
	input                   EXE_IsMFC0,
	input                   EXE_CacheType
	// output                  MEM_Dst,
	// output                  MEM_IsTLBR,
	// output                  MEM_IsTLBW,
	// output                  MEM_RegsWrTypeCP0Wr,
	// output                  MEM_CacheType
	);

endinterface

interface MEM_MEM2_Interface();
	logic		[31:0] 		MEM_ALUOut;		
    logic 		[31:0] 		MEM_PC;	
	logic       [31:0]      MEM_Instr;		
    logic 		[1:0]  		MEM_WbSel;				
    logic 		[4:0]  		MEM_Dst;
	logic       [31:0]      MEM_OutB;
	RegsWrType              MEM_RegsWrType;//经过exception solvement的新写使能
	logic       [4:0]  		MEM_ExcType;
	logic                   MEM_IsABranch;
	logic                   MEM_IsInDelaySlot;
	logic 				    MEM_Isincache;
	LoadType                MEM_LoadType;
	logic		[31:0] 		MEM2_ALUOut;		
    logic 		[31:0] 		MEM2_PC;	
	logic       [4:0]  		MEM2_ExcType;
	logic                   MEM2_IsABranch;
	logic                   MEM2_IsInDelaySlot;
	`ifdef DEBUG
	logic      [3:0]      	MEM_DCache_Wen;
	logic  	   [31:0]	    MEM_DataToDcache;
	`endif

	modport MEM(  // top MEM使用
		output  			MEM_ALUOut,		
		output  			MEM_PC,	
		output  			MEM_Instr,		
		output  			MEM_WbSel,			
		output  			MEM_Dst,
		output  			MEM_OutB,
		output  			MEM_RegsWrType,
		output  			MEM_ExcType,
		output  			MEM_IsABranch,
		output  			MEM_IsInDelaySlot,
		output              MEM_Isincache,
		`ifdef DEBUG
		output              MEM_DCache_Wen,
		output      		MEM_DataToDcache,
		`endif
		output              MEM_LoadType,
		input               MEM2_ALUOut,									
		input               MEM2_PC,
		input               MEM2_ExcType,
		input               MEM2_IsABranch,
		input               MEM2_IsInDelaySlot
	);

	modport MEM2 (  // top MEM2使用
		input  				MEM_ALUOut,		
		input  				MEM_PC,	
		input  				MEM_Instr,		
		input  				MEM_WbSel,			
		input  				MEM_Dst,
		input  				MEM_OutB,
		input  				MEM_RegsWrType,
		input  				MEM_ExcType,
		input  				MEM_IsABranch,
		input  				MEM_IsInDelaySlot,
		input               MEM_Isincache,
		`ifdef DEBUG
		input               MEM_DCache_Wen,
		input       	    MEM_DataToDcache,
		`endif
		input               MEM_LoadType,
		output       	 	MEM2_ALUOut,
		output              MEM2_PC,
		output   			MEM2_ExcType,
		output   			MEM2_IsABranch,
		output   			MEM2_IsInDelaySlot
	);
	
endinterface


interface MEM2_WB_Interface();

    logic		[31:0] 		MEM2_ALUOut;	
	LoadType                MEM2_LoadType;	
    logic 		[31:0] 		MEM2_PC;	
	logic       [31:0]      MEM2_Instr;		
    logic 		[1:0]  		MEM2_WbSel;				
    logic 		[4:0]  		MEM2_Dst;
	logic 		[31:0] 		MEM2_DMOut;
	logic       [31:0]      MEM2_OutB;
	RegsWrType              MEM2_RegsWrType;
	logic 					MEM2_Isincache;
	logic       [31:0]      MEM2_Result;
	`ifdef DEBUG
    // logic		[31:0] 		MEM2_ALUOut;		
	logic       [3:0]    	MEM2_DCache_Wen;
	logic  		[31:0]    	MEM2_DataToDcache;
	`endif
  
	modport MEM2 (  // top MEM2使用
    	output				MEM2_ALUOut,	
		output              MEM2_LoadType,	
    	output				MEM2_PC,		
		output              MEM2_Instr,	
    	output				MEM2_WbSel,				
    	output				MEM2_Dst,
		output				MEM2_DMOut,
		output              MEM2_OutB,
		output				MEM2_RegsWrType,
		output 				MEM2_Isincache,
		`ifdef DEBUG
    	// output				MEM2_ALUOut,		
		input               MEM2_DCache_Wen,
		input  			    MEM2_DataToDcache,
		`endif
		output				MEM2_Result
	);

	modport WB ( 
		input				MEM2_ALUOut,		//TODO:这个地方其实不用32位宽
    	input               MEM2_LoadType,
		input				MEM2_PC,		
		input               MEM2_Instr,	
    	input				MEM2_WbSel,				
    	input				MEM2_Dst,
		input				MEM2_DMOut,
		input               MEM2_OutB,
		input				MEM2_RegsWrType,
		input 				MEM2_Isincache,
		`ifdef DEBUG
		input               MEM2_DCache_Wen,
		input  			    MEM2_DataToDcache,
		`endif
		input				MEM2_Result
	);

endinterface


interface CP0_TLB_Interface ();
     
    logic [18:0]            CP0_vpn2;   //用于查TLB和写TLB  
	logic [7:0]             CP0_asid;   //用于查TLB和写TLB  
	logic [19:0]            CP0_pfn0;   //用于查TLB和写TLB  
	logic [2:0]             CP0_c0;     //用于查TLB和写TLB
	logic                   CP0_d0;     //用于查TLB和写TLB
	logic                   CP0_v0;     //用于查TLB和写TLB
	logic                   CP0_g0;     //用于查TLB和写TLB
	logic [19:0]            CP0_pfn1;   //用于查TLB和写TLB  
	logic [2:0]             CP0_c1;     //用于查TLB和写TLB
	logic                   CP0_d1;     //用于查TLB和写TLB
	logic                   CP0_v1;     //用于查TLB和写TLB
	logic                   CP0_g1;     //用于查TLB和写TLB
	logic [2:0]             CP0_index;  //16项的TLB，log16,所以位宽是4,现在改成8项了
	logic [2:0]             CP0_random; //同上
    logic [18:0]            TLB_vpn2;   //用于TLBR，写CP0    
	logic [7:0]             TLB_asid;   //用于TLBR，写CP0  
	logic [19:0]            TLB_pfn0;   //用于TLBR，写CP0  
	logic [2:0]             TLB_c0;     //用于TLBR，写CP0
	logic                   TLB_d0;     //用于TLBR，写CP0
	logic                   TLB_v0;     //用于TLBR，写CP0
	logic                   TLB_g0;     //用于TLBR，写CP0
	logic [19:0]            TLB_pfn1;   //用于TLBR，写CP0 
	logic [2:0]             TLB_c1;     //用于TLBR，写CP0
	logic                   TLB_d1;     //用于TLBR，写CP0
	logic                   TLB_v1;     //用于TLBR，写CP0
	logic                   TLB_g1;     //用于TLBR，写CP0
	logic [2:0]             TLB_index;  //用于TLBP，写CP0
	logic                   TLB_s1found;//用于TLBP，写CP0

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
	output                  CP0_random,
	input                   TLB_vpn2,
	input                   TLB_asid,
	input                   TLB_pfn0,
	input                   TLB_c0,
	input                   TLB_d0,
	input                   TLB_v0,
	input                   TLB_g0,
	input                   TLB_pfn1,
	input                   TLB_c1,
	input                   TLB_d1,
	input                   TLB_v1,
	input                   TLB_g1,
	input                   TLB_index,
	input                   TLB_s1found
	);

	modport TLB ( 
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
	input                   CP0_random,
	output                  TLB_vpn2,
	output                  TLB_asid,
	output                  TLB_pfn0,
	output                  TLB_c0,
	output                  TLB_d0,
	output                  TLB_v0,
	output                  TLB_g0,
	output                  TLB_pfn1,
	output                  TLB_c1,
	output                  TLB_d1,
	output                  TLB_v1,
	output                  TLB_g1,
	output                  TLB_index,
    output                  TLB_s1found
	);

endinterface
//-----------------------------------------------------------------------------------------//

`endif 