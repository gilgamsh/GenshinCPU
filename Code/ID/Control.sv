/*
 * @Author: Juan Jiang
 * @Date: 2021-04-02 09:40:19
 * @LastEditTime: 2021-07-04 13:11:17
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CPU_Defines.svh"
`define COMPILE_FULL_M

module Control(
    input  logic[31:0] ID_Instr,
    input  ExceptinPipeType IF_ExceptType,
    input  logic EXE_IsTLBR,
    input  logic EXE_IsTLBW,

    output logic [4:0] ID_ALUOp,	 		// ALUOp ALU符号
    output LoadType    ID_LoadType,	 		// Load信号 （用于判断是sw sh sb还是lb lbu lh lhu lw ）
    output StoreType   ID_StoreType,  		        // Store信号（用于判断是sw sh sb还是sb sbu sh shu sw ）
    output RegsWrType  ID_RegsWrType,		        // 寄存器写信号打包
    output logic [1:0] ID_WbSel,    		        // 写回信号选择
    //output logic ID_ReadMem,		 		// LoadType 指令在MEM级，产生数据冒险的指令在MEM级检测
    output logic [1:0] ID_DstSel,   		        // 寄存器写回信号选择（Dst）
    //output logic ID_DMWr,			 	// DataMemory 写信号
    output ExceptinPipeType ID_ExceptType,	        // 异常类型

    output logic       ID_ALUSrcA,
    output logic       ID_ALUSrcB,
    output logic [1:0] ID_RegsReadSel,
    output logic [1:0] ID_EXTOp,

    output logic       ID_IsAImmeJump,

    output BranchType  ID_BranchType,

    output logic [1:0] ID_rsrtRead,
    output logic       ID_IsTLBP,
    output logic       ID_IsTLBW,
    output logic       ID_IsTLBR
    );

    assign ID_IsTLBP = (ID_Instr == 32'b010000_1_000_0000_0000_0000_0000_001000);
    assign ID_IsTLBW = (ID_Instr == 32'b010000_1_000_0000_0000_0000_0000_000010);
    assign ID_IsTLBR = (ID_Instr == 32'b010000_1_000_0000_0000_0000_0000_000001);

    logic [5:0]opcode;
    logic [5:0]funct;
    logic [4:0]rt;
    logic [4:0]rs;
    logic [4:0]rd;
    logic [4:0]shamt;
    InstrType instrType;
    logic IsReserved;


    assign opcode = ID_Instr[31:26];
    assign funct = ID_Instr[5:0];
    assign rs = ID_Instr[25:21];
    assign rt = ID_Instr[20:16];
    assign rd = ID_Instr[15:11];
    assign shamt = ID_Instr[10:6];
    // the  work before clasification 

    always_comb begin
      if(rs == 5'b00000)begin
        ID_rsrtRead[1] = 1'b0;
      end
      else ID_rsrtRead[1] = 1'b1;
    end

    always_comb begin
      if(rt == 5'b00000)begin
        ID_rsrtRead[0] = 1'b0;
      end
      else ID_rsrtRead[0] = 1'b1;
    end



    always_comb begin
        unique casez (opcode)
            6'b000_000:begin// register 
              unique case (funct)

                `EXE_ADD:instrType = OP_ADD;

                `EXE_ADDU:instrType = OP_ADDU;

                `EXE_SUB:instrType = OP_SUB;
                
                `EXE_SUBU:instrType = OP_SUBU;

                `EXE_SLT:instrType = OP_SLT;

                `EXE_SLTU:instrType = OP_SLTU;

                `EXE_DIV:instrType = OP_DIV;

                `EXE_DIVU:instrType = OP_DIVU;

                `EXE_MULT:instrType = OP_MULT;

                `EXE_MULTU:instrType = OP_MULTU;

              

                `EXE_AND:instrType = OP_AND;

                `EXE_NOR:instrType = OP_NOR;

                `EXE_OR:instrType = OP_OR;

                `EXE_XOR:instrType = OP_XOR;



                `EXE_SLLV:begin 
                  if (shamt==5'b00000) begin
                    instrType = OP_SLLV;
                  end
                  else instrType = OP_INVALID;
                  
                end  

                `EXE_SLL:begin 
                  if (rs==5'b00000) begin
                    instrType = OP_SLL;
                  end
                  else instrType = OP_INVALID;
                end 

                `EXE_SRAV:begin 
                  if (shamt==5'b00000) begin
                    instrType = OP_SRAV;
                  end
                  else instrType = OP_INVALID;
                end 

                `EXE_SRA:begin 
                  if (rs==5'b00000) begin
                    instrType = OP_SRA;
                  end
                  else instrType = OP_INVALID;
                end 

                `EXE_SRLV:begin 
                  if (shamt==5'b00000) begin
                    instrType = OP_SRLV;
                  end
                  else instrType = OP_INVALID;
                end

                `EXE_SRL:begin 
                  if (rs==5'b00000) begin
                    instrType = OP_SRL;
                  end
                  else instrType = OP_INVALID;
                end


                `EXE_JR:instrType = OP_JR;

                `EXE_JALR:instrType = OP_JALR;


                `EXE_MFHI:instrType = OP_MFHI;

                `EXE_MFLO:instrType = OP_MFLO;

                `EXE_MTHI:instrType = OP_MTHI;

                `EXE_MTLO:instrType = OP_MTLO;

                `EXE_BREAK:instrType = OP_BREAK;

                `EXE_SYSCALL:instrType = OP_SYSCALL;

                default: begin
                  instrType = OP_INVALID;
                end
              endcase
              end // register

            6'b000_001:begin// some branch
              unique case(rt)

              `EXE_BLTZ:instrType = OP_BLTZ;

              `EXE_BGEZ:instrType = OP_BGEZ;

              `EXE_BLTZAL:instrType = OP_BLTZAL;

              `EXE_BGEZAL:instrType = OP_BGEZAL;
              endcase
              
            end// some branch

            6'b000_01?:begin// some j
              unique case(opcode[0])
                1'b0:instrType = OP_J;
                1'b1:instrType = OP_JAL;
              endcase
            end// some j

            6'b000_1??:begin//some branch 
              unique case(opcode[1:0])
                2'b00:instrType = OP_BEQ;
                2'b01:instrType = OP_BNE;
                2'b10:instrType = OP_BLEZ;
                2'b11:instrType = OP_BGTZ;
              endcase
            end//some branch

            6'b001_???:begin//I Type
              unique case(opcode[2:0])
                3'b000:instrType = OP_ADDI;
                3'b001:instrType = OP_ADDIU;
                3'b010:instrType = OP_SLTI;
                3'b011:instrType = OP_SLTIU;
                3'b100:instrType = OP_ANDI;
                3'b101:instrType = OP_ORI;
                3'b110:instrType = OP_XORI;
                3'b111:instrType = OP_LUI;
              endcase
            end//I Type

            6'b100_???: begin // load (Reg-Imm)

			        unique case(opcode[2:0])
				        3'b000: instrType = OP_LB;
				        3'b001: instrType = OP_LH;
				        3'b010: instrType = OP_LWL;
				        3'b011: instrType = OP_LW;
				        3'b100: instrType = OP_LBU;
				        3'b101: instrType = OP_LHU;
				        3'b110: instrType = OP_LWR;
				        3'b111: instrType = OP_INVALID;
			        endcase
		        end

            6'b101_???: begin // store (Reg-Imm)

			        unique case(opcode[2:0])
			        	3'b000:  instrType = OP_SB;
			        	3'b001:  instrType = OP_SH;
			        	3'b010:  instrType = OP_SWL;
			        	3'b011:  instrType = OP_SW;
			        	3'b110:  instrType = OP_SWR;
			        	3'b111:  instrType = OP_CACHE;
			        	default: instrType = OP_INVALID;
			        endcase
		        end

            6'b010_000:begin//特权指令
              unique case(rs)
				        5'b00000: begin
				        	instrType = OP_MFC0;
				        end
				        5'b00100: begin
				        	instrType  = OP_MTC0;
				        end
				        5'b10000: begin
				        	unique case(funct)
				        		`ifdef COMPILE_FULL_M
				        		6'b000001: instrType = OP_TLBR;
				        		6'b000010: instrType = OP_TLBWI;
				        		6'b000110: instrType = OP_TLBWR;
				        		6'b001000: instrType = OP_TLBP;
				        		6'b100000: instrType = OP_SLL;  // wait
				        		`endif
				        		6'b011000: instrType = OP_ERET;
				        		default: instrType = OP_INVALID;
				        	endcase
				        end
				        default: instrType = OP_INVALID;
			          endcase
            end
            6'b011100:begin
              unique case (funct)
                6'b100001:instrType = OP_CLO;
                6'b100000:instrType = OP_CLZ;
                6'b000000:instrType = OP_MADD;
                6'b000001:instrType = OP_MADDU;
                6'b000100:instrType = OP_MSUB;
                6'b000101:instrType = OP_MSUBU;
                6'b000010:instrType = OP_MUL;
                default:  instrType = OP_INVALID;
              endcase
            end
            default:begin
                instrType = OP_INVALID;
            end
        endcase
    end
    

  always_comb begin
    unique case (instrType)
      OP_ADD:begin
        ID_ALUOp      = `EXE_ALUOp_ADD;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;//rd
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end 

      OP_ADDI:begin
        ID_ALUOp      = `EXE_ALUOp_ADDI;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel= `RegsReadSel_RF;      
        ID_EXTOp      = `EXTOP_SIGN;   
        ID_IsAImmeJump = `IsNotAImmeJump;    
        ID_BranchType = '0; 
        IsReserved    = 1'b0;        
      end

      OP_ADDU:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rt
        ID_RegsWrType = `RegsWrTypeRFEn; 
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 'x;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_ADDIU:begin
        ID_ALUOp      = `EXE_ALUOp_ADDIU;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0; 
        IsReserved    = 1'b0;       
      end

      OP_SUB:begin
        ID_ALUOp      = `EXE_ALUOp_SUB;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;       
      end

      OP_SUBU:begin
        ID_ALUOp      = `EXE_ALUOp_SUBU;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;    
        IsReserved    = 1'b0;     
      end

      OP_SLT:begin
        ID_ALUOp      = `EXE_ALUOp_SLT;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;       
      end

      OP_SLTI:begin
        ID_ALUOp      = `EXE_ALUOp_SLTI;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;     
        IsReserved    = 1'b0;    
      end

      OP_SLTU:begin
        ID_ALUOp      = `EXE_ALUOp_SLTU;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 'x;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;       
      end

      OP_SLTIU:begin
        ID_ALUOp      = `EXE_ALUOp_SLTIU;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0; 
        IsReserved    = 1'b0;        
      end

      OP_DIV:begin
        ID_ALUOp      = `EXE_ALUOp_DIV;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回Regs 需要把ALU的输出扩张一个字
        ID_DstSel     = '0;//写入HILO寄存器中所以是无关
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;    
        IsReserved    = 1'b0;     
      end

      OP_DIVU:begin
        ID_ALUOp      = `EXE_ALUOp_DIVU;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回Regs 需要把ALU的输出扩张一个字
        ID_DstSel     = '0;//写入HILO寄存器中所以是无关
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;       
      end

      OP_MULT:begin
        ID_ALUOp      = `EXE_ALUOp_MULT;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回Regs 需要把ALU的输出扩张一个字
        ID_DstSel     = '0;//写入HILO寄存器中所以是无关
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;         
      end

      OP_MULTU:begin
        ID_ALUOp      = `EXE_ALUOp_MULTU;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回Regs 需要把ALU的输出扩张一个字
        ID_DstSel     = '0;//写入HILO寄存器中所以是无关
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;       
      end

      OP_BEQ:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;//rd,d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 1'b1;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_BEQ,1'b1}; 
        IsReserved    = 1'b0;        
      end

      OP_BNE:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;//rd,d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 1'b1;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_BNE,1'b1};
        IsReserved    = 1'b0;
      end

      OP_BGEZ:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;//rd,d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 1'b1;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_BGE,1'b1};
        IsReserved    = 1'b0;
      end

      OP_BGTZ:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;//rd,d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 1'b1;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_BGT,1'b1};
        IsReserved    = 1'b0;
      end

      OP_BLEZ:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;//rd,d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 1'b1;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_BLE,1'b1};
        IsReserved    = 1'b0;
      end

      OP_BLTZ:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;//rd,d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 1'b1;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_BLT,1'b1};
        IsReserved    = 1'b0;
      end

      OP_BGEZAL:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_PCAdd1;//关于最后写回RF
        ID_DstSel     = `DstSel_31;//31
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 1'b1;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_BGE,1'b1};
        IsReserved    = 1'b0;
      end

      OP_BLTZAL:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_PCAdd1;//关于最后写回RF
        ID_DstSel     = `DstSel_31;//31
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = 1'b1;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_BLT,1'b1};
        IsReserved    = 1'b0;
      end

      OP_J:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;//rd
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_JAL:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_PCAdd1;//关于最后写回RF
        ID_DstSel     = `DstSel_31;//31
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      /******* OP3.4  ******/
      OP_AND:begin
        ID_ALUOp      = `EXE_ALUOp_AND;     //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;  //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = '0;                 // 
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

       OP_ANDI:begin
        ID_ALUOp      = `EXE_ALUOp_AND;     //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rt;         //选rt
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;  //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;   //MUXB选择imm
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = `EXTOP_ZERO;        //imm16zero_extened
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_LUI:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;    //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rt;         //选rt
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;  //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;   //MUXB选择imm
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = `EXTOP_LUI;         //高位加载
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_NOR:begin
        ID_ALUOp      = `EXE_ALUOp_NOR;     //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;  //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_OR:begin
        ID_ALUOp      = `EXE_ALUOp_OR;      //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;  //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_ORI:begin
        ID_ALUOp      = `EXE_ALUOp_ORI;     //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rt;         //I型选rt
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;  //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;   //MUXB选择imm
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = `EXTOP_ZERO;        //imm16zero_extened
        ID_IsAImmeJump = `IsNotAImmeJump;    
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_XOR:begin
        ID_ALUOp      = `EXE_ALUOp_XOR;     //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;  //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_XORI:begin
        ID_ALUOp      = `EXE_ALUOp_XORI;    //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rt;         //I型选rt
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;  //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;   //MUXB选择imm
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = `EXTOP_ZERO;        //imm16zero_extened
        ID_IsAImmeJump = `IsNotAImmeJump;    
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_SLLV:begin
        ID_ALUOp      = `EXE_ALUOp_SLLV;    //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs; //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
      OP_SLL:begin
        ID_ALUOp      = `EXE_ALUOp_SLL;     //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Shamt; //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
      OP_SRAV:begin
        ID_ALUOp      = `EXE_ALUOp_SRAV;    //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs; //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
      OP_SRA:begin
        ID_ALUOp      = `EXE_ALUOp_SRA;    //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Shamt; //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
      OP_SRLV:begin
        ID_ALUOp      = `EXE_ALUOp_SRLV;    //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs; //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;    //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = 'x;
        IsReserved    = 1'b0;
      end
      OP_SRL:begin
        ID_ALUOp      = `EXE_ALUOp_SRL;    //ALU操作
        ID_LoadType   = 'x;                 //访存相关 
        ID_StoreType  = 'x;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Shamt; //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;    //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = 'x;
        IsReserved    = 1'b0;
      end

      OP_JR:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;//d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_JR,1'b1};
        IsReserved    = 1'b0;
      end

      OP_JALR:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_PCAdd1;//关于最后写回RF
        ID_DstSel     = `DstSel_31;//31
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '{`BRANCH_CODE_JR,1'b1};
        IsReserved    = 1'b0;
      end

      OP_MFHI:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_OutB;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rd
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_HI;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_MFLO:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_OutB;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rd
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_LO;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_MTHI:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rd,d
        ID_RegsWrType = `RegsWrTypeHIEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel = `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
    

      OP_MTLO:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;//ALU操作
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rd,d
        ID_RegsWrType = `RegsWrTypeLOEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel = `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
      
      //自陷指令
      OP_BREAK:begin
        ID_ALUOp      = 'x;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = 'x;
        ID_DstSel     = 'x;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = 'x;
        ID_ALUSrcB    = 'x;
        ID_RegsReadSel= 'x;//选择ID级别读出的数据
        ID_EXTOp      = 'x;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_SYSCALL:begin
        ID_ALUOp      = 'x;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = 'x;
        ID_DstSel     = 'x;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = 'x;
        ID_ALUSrcB    = 'x;
        ID_RegsReadSel= 'x;//选择ID级别读出的数据
        ID_EXTOp      = 'x;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      //访存指令
      OP_LB:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign = 1;//sign
        ID_LoadType.size = 2'b10;//byte
        ID_LoadType.ReadMem = 1;//loadmem
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_LBU:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign = 0;//unsign
        ID_LoadType.size = 2'b10;//byte
        ID_LoadType.ReadMem = 1;//loadmem
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_LH:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign = 1;//sign
        ID_LoadType.size = 2'b01;//half
        ID_LoadType.ReadMem = 1;//loadmem
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_LHU:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign = 0;//unsign
        ID_LoadType.size = 2'b01;//half
        ID_LoadType.ReadMem = 1;//loadmem
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;    
        IsReserved    = 1'b0;  
      end

      OP_LW:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign = 1;//sign
        ID_LoadType.size = 2'b00;//word
        ID_LoadType.ReadMem = 1;//loadmem
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;    
      end

      OP_SB:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        ID_LoadType   = '0;
        //ID_StoreType begin
        ID_StoreType.size  = `STORETYPE_SB;
        ID_StoreType.DMWr  = 1;
        //ID_StoreType end
        ID_WbSel      = `WBSel_ALUOut;//选择输出的地址
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsReadSel    = `RegsReadSel_RF;//选寄存器
        ID_RegsWrType = `RegsWrTypeDisable;//不写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;          
      end


      OP_SH:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        ID_LoadType   = '0;
        //ID_StoreType begin
        ID_StoreType.size  = `STORETYPE_SH;
        ID_StoreType.DMWr  = 1;
        //ID_StoreType end
        ID_WbSel      = `WBSel_ALUOut;//选择输出的地址
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsReadSel    = `RegsReadSel_RF;//选寄存器
        ID_RegsWrType = `RegsWrTypeDisable;//不写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;   
        IsReserved    = 1'b0;       
      end

      OP_SW:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        ID_LoadType   = '0;
        //ID_StoreType begin
        ID_StoreType.size  = `STORETYPE_SW;
        ID_StoreType.DMWr  = 1;
        //ID_StoreType end
        ID_WbSel      = `WBSel_ALUOut;//选择输出的地址
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsReadSel    = `RegsReadSel_RF;//选寄存器
        ID_RegsWrType = `RegsWrTypeDisable;//不写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;    
        IsReserved    = 1'b0;      
      end

      //特权指令  
      OP_ERET:begin
        ID_ALUOp      = 'x;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = 'x;
        ID_DstSel     = 'x;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = 'x;
        ID_ALUSrcB    = 'x;
        ID_RegsReadSel= 'x;//选择ID级别读出的数据
        ID_EXTOp      = 'x;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
      OP_MFC0:begin
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_WbSel      = `WBSel_OutB;
        ID_DstSel     = `DstSel_rt;//rt 
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_ALUSrcA    = 'x;
        ID_ALUSrcB    = 'x;
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_RegsReadSel= `RegsReadSel_CP0;//选择CP0进行读取
        ID_EXTOp      = 'x;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
    
      OP_MTC0:begin
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_WbSel      = `WBSel_OutB;
        ID_DstSel     = `DstSel_rd;//rd
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_ALUSrcA    = 'x;
        ID_ALUSrcB    = 'x;
        ID_RegsWrType = `RegsWrTypeCP0En;//写CP0
        ID_RegsReadSel= `RegsReadSel_RF;//选择RF进行读取
        ID_EXTOp      = 'x;                 //R型无关
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      //操作系统译码部分
      //CLO、CLZ、MADD、MADDU、MSUB、MSUBU、MUL
      OP_CLO:begin
        //GPR[rd] ← count_leading_ones GPR[rs]
        ID_ALUOp      = `EXE_ALUOp_CLO;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_CLZ:begin
        //GPR[rd] ← count_leading_zeros GPR[rs]
        ID_ALUOp      = `EXE_ALUOp_CLZ;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_MADD:begin//有符号乘
        ID_ALUOp      = `EXE_ALUOp_MADD;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_MADDU:begin//有符号乘
        ID_ALUOp      = `EXE_ALUOp_MADDU;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
      
      OP_MSUB:begin//有符号乘
        ID_ALUOp      = `EXE_ALUOp_MSUB;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
      
      OP_MSUBU:begin//有符号乘
        ID_ALUOp      = `EXE_ALUOp_MSUBU;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_TLBP:begin//search
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end
      
      OP_TLBWI:begin//search
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_TLBR:begin//search
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAImmeJump = `IsNotAImmeJump;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      default:begin
        ID_ALUOp      = 'X;    //ALU操作
        ID_LoadType   = 'X;    //访存相关 
        ID_StoreType  = 'X;    //存储相关
        ID_WbSel      = 'X;    //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = 'X;    //Rtype选rd
        ID_RegsWrType = 'X;    //写回哪里
        ID_ALUSrcA    = 'X; //MUXA选择regs
        ID_ALUSrcB    = 'X;  //MUXB选择regs
        ID_RegsReadSel= 'X;        //ID级选择RF读取结果
        ID_EXTOp      = 'X;                 //R型无关
        ID_IsAImmeJump = 'X;
        ID_BranchType = 'X;
        IsReserved    = 1'b1;        
      end

      

    endcase
  end 

always_comb begin
  if(instrType == OP_BREAK) begin
    ID_ExceptType = '{
                            Interrupt:1'b0,
                            Break:1'b1,
                            WrongAddressinIF:1'b0,
                            ReservedInstruction:1'b0,
                            Overflow:1'b0,
                            Syscall:1'b0,
                            Eret:1'b0,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefill:IF_ExceptType.TLBRefill,
                            TLBInvalid:IF_ExceptType.TLBInvalid,
                            TLBModified:1'b0,
                            Refetch:1'b0,
                            Trap:1'b0
        };//关于Break异常
  end
  else if(instrType == OP_SYSCALL) begin
    ID_ExceptType = '{
                            Interrupt:1'b0,
                            Break:1'b0,
                            WrongAddressinIF:1'b0,
                            ReservedInstruction:1'b0,
                            Overflow:1'b0,
                            Syscall:1'b1,
                            Eret:1'b0,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefill:IF_ExceptType.TLBRefill,
                            TLBInvalid:IF_ExceptType.TLBInvalid,
                            TLBModified:1'b0,
                            Refetch:1'b0,
                            Trap:1'b0
        };//关于SYSCALL
  end
  else if(instrType == OP_ERET) begin
    ID_ExceptType = '{  
                            Interrupt:1'b0,
                            Break:1'b0,
                            WrongAddressinIF:1'b0,
                            ReservedInstruction:1'b0,
                            Overflow:1'b0,
                            Syscall:1'b0,
                            Eret:1'b1,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefill:IF_ExceptType.TLBRefill,
                            TLBInvalid:IF_ExceptType.TLBInvalid,
                            TLBModified:1'b0,
                            Refetch:1'b0,
                            Trap:1'b0
        };//关于ERET
  end
  else begin
    if(EXE_IsTLBW == 1'b1 || EXE_IsTLBR == 1'b1) begin
      ID_ExceptType = '{  
                            Interrupt:1'b0,
                            Break:1'b0,
                            WrongAddressinIF:1'b0,
                            ReservedInstruction:1'b0,
                            Overflow:1'b0,
                            Syscall:1'b0,
                            Eret:1'b0,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefill:IF_ExceptType.TLBRefill,
                            TLBInvalid:IF_ExceptType.TLBInvalid,
                            TLBModified:1'b0,
                            Refetch:1'b1,
                            Trap:1'b0
        };//
    end
    else begin
      ID_ExceptType = '{  
                            Interrupt:1'b0,
                            Break:1'b0,
                            WrongAddressinIF:1'b0,
                            ReservedInstruction:IsReserved,
                            Overflow:1'b0,
                            Syscall:1'b0,
                            Eret:1'b0,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefill:IF_ExceptType.TLBRefill,
                            TLBInvalid:IF_ExceptType.TLBInvalid,
                            TLBModified:1'b0,
                            Refetch:1'b0,
                            Trap:1'b0
        };//
    end
  end
end 


endmodule
