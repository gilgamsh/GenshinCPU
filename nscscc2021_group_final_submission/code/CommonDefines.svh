/*
 * @Author: Johnson Yang
 * @Date: 2021-03-24 14:40:35
 * @LastEditTime: 2021-08-18 14:30:02
 * @LastEditors: Please set LastEditors
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`ifndef CommonDefines_svh
`define CommonDefines_svh
// 取消功能,需要将`define注释掉
`define FPU_DETECT_EN           // 定义则打开浮点检测功能
// `define DEBUG                       
`define NEW_BRIDGE          
// `define All_Uncache           // 定义则全走uncache  
`define TRAP                   
`define EN_TLB         
`define EN_TLBRST
`define MUL_Circle          3    //按照乘法IP核中的参数来设置，最大是8

`define ALUOpLen            4:0
`define InstrLen            31:0
`define RegBus              31:0

`define Ready               1'b1
`define Unready             1'b0

`define Enable              1'b1
`define Disable             1'b0

`define ISCOP1_INSTR        2'b11
`define NOTCOP1_INSTR       2'b00
`define FPU_Reserve_INSTR   2'b10

`define Valid               1'b1
`define Invalid             1'b0
`define WriteEnable         1'b1     // 打开写使能信号
`define WriteDisable        1'b0     // 关闭写使能信号
`define RstEnable           1'b0     // 打开复位信号(高有效)
`define RstDisable          1'b1     // 关闭复位信号
`define FlushEnable         1'b1     // 开启flush
`define FlushDisable        1'b0     // 关闭flush

//----------------------分支预测宏定义--------------------//
`define SIZE_OF_RAS 8
// `define SIZE_OF_TAG 22
`define SIZE_OF_INDEX 8
`define SIZE_OF_SET 256

`define BIsNone 3'b000  //不分支
`define BIsCall 3'b001  //jal,jalr
`define BIsRetn 3'b010  //jr
`define BIsBran 3'b011  //branch
`define BIsJump 3'b100  //jump

`define NT      2'b00  //not taken
`define WNT     2'b01  //weakly not taken
`define WT      2'b10  //weakly taken
`define T       2'b11  //taken

//*******************PCSel 的宏定义********************
`define PCSel_EPC        3'b000
`define PCSel_Except     3'b001
`define PCSel_MEMPC      3'b010
`define PCSel_Correct    3'b011   
`define PCSel_PC4        3'b100
`define PCSel_Target     3'b101


//用于选择storeleefine

//用于选择store类型
`define STORETYPE_SW        2'b00
`define STORETYPE_SH        2'b01
`define STORETYPE_SB        2'b10

//用于选择load类型
`define LOADTYPE_LW         3'b100
`define LOADTYPE_LH         3'b101
`define LOADTYPE_LHU        3'b001
`define LOADTYPE_LB         3'b110
`define LOADTYPE_LBU        3'b010

//用于选择将要WB的数据
`define WBSel_PCAdd1        2'b00
`define WBSel_ALUOut        2'b01
`define WBSel_OutB          2'b10
`define WBSel_DMResult      2'b11

//PC复位地址
`define PCRstAddr           32'hBFC0_0000
`define PCRstTag            22'b1011_1111_1100_0000_0000_00;

//**************************for the branch slove unit*****************************
`define BRANCH_CODE_BEQ     3'b000
`define BRANCH_CODE_BNE     3'b001
`define BRANCH_CODE_BGE     3'b010
`define BRANCH_CODE_BGT     3'b011
`define BRANCH_CODE_BLE     3'b100
`define BRANCH_CODE_BLT     3'b101
`define BRANCH_CODE_J       3'b110 
`define BRANCH_CODE_JR      3'b111    

//**************************for the trap slove unit*****************************
// 对于trap指令的立即数，都做有符号位的扩展
`define TRAP_OP_None    3'b000 // 没有trap
`define TRAP_OP_TEQ     3'b110 // 按照 有符号数 比较 ; 相等         即发生异常
`define TRAP_OP_TEQI    3'b110 // 按照 有符号数 比较 ; 相等         即发生异常
`define TRAP_OP_TGE     3'b001 // 按照 有符号数 比较 ; 大于或者相等 即发生异常
`define TRAP_OP_TGEI    3'b001 // 按照 有符号数 比较 ; 大于或者相等 即发生异常
`define TRAP_OP_TGEIU   3'b010 // 按照 无符号数 比较 ; 大于或者相等 即发生异常
`define TRAP_OP_TGEU    3'b010 // 按照 无符号数 比较 ; 大于或者相等 即发生异常
`define TRAP_OP_TLT     3'b011 // 按照 有符号数 比较 ; 小于        即发生异常
`define TRAP_OP_TLTI    3'b011 // 按照 有符号数 比较 ; 小于        即发生异常
`define TRAP_OP_TLTIU   3'b100 // 按照 无符号数 比较 ; 小于        即发生异常
`define TRAP_OP_TLTU    3'b100 // 按照 无符号数 比较 ; 小于        即发生异常
`define TRAP_OP_TNE     3'b101 // 按照 有符号数 比较 ; 不等于      即发生异常
`define TRAP_OP_TNEI    3'b101 // 按照 有符号数 比较 ; 不等于      即发生异常

//****************************有关译码的宏定义***************************

`define DonotReadMem        1'b0
`define DoReadMem           1'b1

`define DstSel_rd           2'b00
`define DstSel_rt           2'b01
`define DstSel_31           2'b10
`define DstSel_nop          2'b11

`define ALUSrcA_Sel_Regs    1'b0
`define ALUSrcA_Sel_Shamt   1'b1

`define ALUSrcB_Sel_Regs    1'b0
`define ALUSrcB_Sel_Imm     1'b1

`define RegsReadSel_RF      2'b00 //RF读出的数据
`define RegsReadSel_HI      2'b01 //HI寄存器读出的数据
`define RegsReadSel_LO      2'b10 //LO寄存器读出的数据
`define RegsReadSel_CP0     2'b11 //CP0读出的数据

`define IsAJumpCall         1'b1  //特指 j jal
`define IsNotAJumpCall      1'b0

`define IsABranch           1'b1  //比如bne jr 这种
`define IsNotABranch        1'b0

//*******************************EXT ***********************

`define EXTOP_ZERO          2'b00
`define EXTOP_SIGN          2'b01
`define EXTOP_LUI           2'b10
`define EXTOP_NOP           2'b11
//***************************  与CP0有关的宏定义  ***************************

`define InterruptNotAssert      1'b0     // 取消中断的声明
`define InterruptAssert         1'b1     // 开启中断的声明
`define IsInDelaySlot           1'b1     // 延迟槽指令
`define ZeroWord                32'h0    // 寄存器32位全0信号
//异常定义
//用于TLB输出
`define IF_TLBNoneEX            2'b00
`define IF_TLBRefill            2'b01
`define IF_TLBInvalid           2'b10
`define MEM_TLBNoneEX           3'b000
`define MEM_RdTLBRefill         3'b001
`define MEM_RdTLBInvalid        3'b010
`define MEM_WrTLBRefill         3'b011
`define MEM_WrTLBInvalid        3'b100
`define MEM_TLBModified         3'b101
//用于MEM级检测译码
`define EX_None                 5'b00000  //无异常，Refetch被认为不是异常，也包括在这里面
`define EX_Interrupt            5'b00001  //
`define EX_WrongAddressinIF     5'b00010
`define EX_ReservedInstruction  5'b00011
`define EX_Syscall              5'b00100
`define EX_Break                5'b00101
`define EX_Eret                 5'b00110
`define EX_Trap                 5'b00111
`define EX_Overflow             5'b01000
`define EX_WrWrongAddressinMEM  5'b01001
`define EX_RdWrongAddressinMEM  5'b01010
`define EX_TLBRefillinIF        5'b01011  //0b
`define EX_TLBInvalidinIF       5'b01100  //0c
`define EX_RdTLBRefillinMEM     5'b01101  //0d
`define EX_RdTLBInvalidinMEM    5'b01110  //0e
`define EX_WrTLBRefillinMEM     5'b01111  //0f
`define EX_WrTLBInvalidinMEM    5'b10000  //10
`define EX_TLBModified          5'b10001
`define EX_CpU                  5'b10010  // 浮点指令 协处理器异常
`define EX_Refetch              5'b10011
// CP0寄存器的宏定义  （序号定义）
`define CP0_REG_INDEX       5'd0
`define CP0_REG_RANDOM      5'd1
`define CP0_REG_ENTRYLO0    5'd2
`define CP0_REG_ENTRYLO1    5'd3
`define CP0_REG_CONTEXT     5'd4
`define CP0_REG_PAGEMASK    5'd5
`define CP0_REG_WIRED       5'd6
`define CP0_REG_BADVADDR    5'd8
`define CP0_REG_COUNT       5'd9
`define CP0_REG_ENTRYHI     5'd10
`define CP0_REG_COMPARE     5'd11
`define CP0_REG_STATUS      5'd12
`define CP0_REG_CAUSE       5'd13
`define CP0_REG_EPC         5'd14
`define CP0_REG_PRID        5'd15   // 15号 sel 0
`define CP0_REG_EBASE       5'd15   // 15号 sel 1
`define CP0_REG_CONFIG0     5'd16   // 16号 sel 0  只读寄存器
`define CP0_REG_CONFIG1     5'd16   // 16号 sel 1  只读寄存器
`define CP0_ERROR_EPC       5'd30 

`define IsNone              2'b00
`define IsRefetch           2'b01
`define IsEret              2'b10
`define IsException         2'b11
//***************************  与结构体有关的宏定义  ***************************
`define ExceptionTypeZero   {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}   //18个例外

//RegsWrType 
`define RegsWrTypeRFEn      '{1'b1,1'b0,1'b0,1'b0}
`define RegsWrTypeCP0En     '{1'b0,1'b1,1'b0,1'b0}
`define RegsWrTypeHIEn      '{1'b0,1'b0,1'b1,1'b0}
`define RegsWrTypeLOEn      '{1'b0,1'b0,1'b0,1'b1}
`define RegsWrTypeHILOEn    '{1'b0,1'b0,1'b1,1'b1}
`define RegsWrTypeDisable   '{1'b0,1'b0,1'b0,1'b0}



//***************************  与具体指令有关的宏定义  ***************************
//逻辑操作指令SPECIAL类的功能码
`define EXE_AND             6'b100100          //and指令功能码
`define EXE_OR              6'b100101          //or指令功能码
`define EXE_XOR             6'b100110          //xor指令功能码
`define EXE_NOR             6'b100111          //nor指令功能码

//逻辑操作指令其他指令码
`define EXE_ANDI            6'b001100          //andi指令码
`define EXE_ORI             6'b001101          //ori指令码
`define EXE_XORI            6'b001110          //xori指令码
`define EXE_LUI             6'b001111          //lui指令码

//移位操作指令功能码
`define EXE_SLL             6'b000000           //sll指令功能码
`define EXE_SLLV            6'b000100          //sllv指令功能码
`define EXE_SRL             6'b000010           //srl指令功能码
`define EXE_SRLV            6'b000110          //srlv指令功能码
`define EXE_SRA             6'b000011           //sra指令功能码
`define EXE_SRAV            6'b000111          //srav指令功能码

//移动操作指令功能码
`define EXE_MOVZ            6'b001010          //movz指令功能码
`define EXE_MOVN            6'b001011          //movn指令功能码
`define EXE_MFHI            6'b010000          //mfhi指令功能码
`define EXE_MTHI            6'b010001          //mthi指令功能码
`define EXE_MFLO            6'b010010          //mflo指令功能码
`define EXE_MTLO            6'b010011          //mtlo指令功能码

//算术操作指令
`define EXE_SLT             6'b101010           //slt指令功能码
`define EXE_SLTU            6'b101011          //sltu指令功能码
`define EXE_SLTI            6'b001010              //slti指令码
`define EXE_SLTIU           6'b001011             //sltiu指令码
`define EXE_ADD             6'b100000           //add指令功能码
`define EXE_ADDU            6'b100001          //addu指令功能码
`define EXE_SUB             6'b100010           //sub指令功能码
`define EXE_SUBU            6'b100011          //subu指令功能码
`define EXE_ADDI            6'b001000              //addi指令码
`define EXE_ADDIU           6'b001001             //addiu指令码
`define EXE_CLZ             6'b100000           //clz指令功能码
`define EXE_CLO             6'b100001           //clo指令功能码

`define EXE_MULT            6'b011000          //mult指令功能码
`define EXE_MULTU           6'b011001         //multu指令功能码
`define EXE_MUL             6'b000010           //mul指令功能码

`define EXE_MADD            6'b000000          //madd指令功能码
`define EXE_MADDU           6'b000001         //maddu指令功能码
`define EXE_MSUB            6'b000100          //msub指令功能码
`define EXE_MSUBU           6'b000101         //msubu指令功能码

`define EXE_DIV             6'b011010           //div指令功能码
`define EXE_DIVU            6'b011011          //divu指令功能码

//分支跳转指令
`define EXE_J               6'b000010             //j指令码
`define EXE_JAL             6'b000011           //jal指令码
`define EXE_JALR            6'b001001          //jalr功能码
`define EXE_JR              6'b001000            //jr功能码
`define EXE_BEQ             6'b000100           //beq指令码
`define EXE_BGEZ            5'b00001           //bgez功能码2
`define EXE_BGEZAL          5'b10001         //bgezal功能码2
`define EXE_BGTZ            6'b000111          //bgtz指令码
`define EXE_BLEZ            6'b000110          //blez指令码
`define EXE_BLTZ            5'b00000           //bltz功能码2
`define EXE_BLTZAL          5'b10000         //bltzal功能码2
`define EXE_BNE             6'b000101           //bne指令码

//加载存储指令
`define EXE_LB              6'b100000            //lb指令码
`define EXE_LBU             6'b100100           //lbu指令码
`define EXE_LH              6'b100001            //lh指令码
`define EXE_LHU             6'b100101           //Lhu指令码
`define EXE_LW              6'b100011            //lw指令码
`define EXE_LWL             6'b100010           //lwl指令码
`define EXE_LWR             6'b100110           //lwr指令码
`define EXE_SB              6'b101000            //sb指令码
`define EXE_SH              6'b101001            //sh指令码
`define EXE_SW              6'b101011            //sw指令码
`define EXE_SWL             6'b101010           //swl指令码
`define EXE_SWR             6'b101110           //swr指令码
`define EXE_LL              6'b110000            //ll指令码
`define EXE_SC              6'b111000            //sc指令码

//异常相关指令
//不包含立即数的自陷指令(指令码为SPECIAL类，根据功能码区分)
`define EXE_TEQ             6'b110100
`define EXE_TGE             6'b110000
`define EXE_TGEU            6'b110001
`define EXE_TLT             6'b110010
`define EXE_TLTU            6'b110011
`define EXE_TNE             6'b110110
//含立即数的自陷指令(指令码为REGIMM类，根据20～16bit区分)
`define EXE_TEQI            5'b01100
`define EXE_TGEI            5'b01000
`define EXE_TGEIU           5'b01001
`define EXE_TLTI            5'b01010
`define EXE_TLTIU           5'b01011
`define EXE_TNEI            5'b01110

`define EXE_BREAK           6'b001101
`define EXE_SYSCALL         6'b001100

`define EXE_ERET 32'b010000_1_0000_0000_0000_0000_000_011000

//空指令
`define EXE_NOP             6'b000000           //空指令功能码
`define SSNOP               32'h0000_0040         //SSNOP指令

//其他特殊指令
`define EXE_SYNC            6'b001111          //sync指令功能码
`define EXE_PREF            6'b110011          //pref指令码

`define EXE_SPECIAL_INST    6'b000000  //SPECIAL类指令的指令码
`define EXE_SPECIAL2_INST   6'b011100 //SPECIAL2类指令的指令码
`define EXE_REGIMM_INST     6'b000001   //REGIMM类转移指令



// ALUctr_signal_encoding 
`define EXE_ALUOp_D         5'b11111//无关项,现在变成了读rs
// ALUctr_signal_encoding 
//ADD 和 ADDI 共用了Opcode
`define EXE_ALUOp_ADD       5'b00000
`define EXE_ALUOp_ADDI      5'b00000
//ADDIU 和 ADDU 共用了Opcode
`define EXE_ALUOp_ADDIU     5'b00001
`define EXE_ALUOp_ADDU      5'b00001
//AND 和 ANDI 共用了Opcode
`define EXE_ALUOp_AND       5'b00010
`define EXE_ALUOp_ANDI      5'b00010

`define EXE_ALUOp_SUB       5'b00011

`define EXE_ALUOp_SUBU      5'b00100

//OR 和 ORI 共用了Opcode
`define EXE_ALUOp_OR        5'b00101//或
`define EXE_ALUOp_ORI       5'b00101//或立即数

`define EXE_ALUOp_NOR       5'b00110//或非

`define EXE_ALUOp_SLL       5'b00111//逻辑左移
`define EXE_ALUOp_SLLV      5'b01000//逻辑可变左移

`define EXE_ALUOp_SRL       5'b01001//逻辑右移
`define EXE_ALUOp_SRLV      5'b01010//逻辑可变右移

`define EXE_ALUOp_SRA       5'b01011//算数右移
`define EXE_ALUOp_SRAV      5'b01100//算数可变右移

//SLT 和 SLTI 共用了Opcode
`define EXE_ALUOp_SLT       5'b01101
`define EXE_ALUOp_SLTI      5'b01101

//SLTIU 和 SLTU 共用了Opcode
`define EXE_ALUOp_SLTIU     5'b01110
`define EXE_ALUOp_SLTU      5'b01110

//XOR 和 XORI 共用了Opcode
`define EXE_ALUOp_XOR       5'b01111
`define EXE_ALUOp_XORI      5'b01111//异或立即数

//乘除法
`define EXE_ALUOp_DIV       5'b10000
`define EXE_ALUOp_DIVU      5'b10001
`define EXE_ALUOp_MULT      5'b10010
`define EXE_ALUOp_MULTU     5'b10011
//count bits
`define EXE_ALUOp_CLZ       5'b10100
`define EXE_ALUOp_CLO       5'b10101
//MADD MADDU MSUB MSUBU MUL
`define EXE_ALUOp_MADD      5'b10110
`define EXE_ALUOp_MADDU     5'b10111
`define EXE_ALUOp_MSUB      5'b11000
`define EXE_ALUOp_MSUBU     5'b11001
`define EXE_ALUOp_MUL       5'b11010
`define EXE_ALUOp_FILTER    5'b11011
`endif
