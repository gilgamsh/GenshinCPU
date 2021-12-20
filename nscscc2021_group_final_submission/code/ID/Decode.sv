/*
 * @Author: Juan Jiang
 * @Date: 2021-04-02 09:40:19
 * @LastEditTime: 2021-08-18 14:32:52
 * @LastEditors: Please set LastEditors
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CPU_Defines.svh"
`include "../CommonDefines.svh"
`define COMPILE_FULL_M
`define ENABLE_FPU      1
module Decode(
    input  logic[31:0] ID_Instr,
    input  ExceptinPipeType ID_ExceptType,
    input  logic       ID_Refetch,
    output logic [4:0] ID_ALUOp,	 		// ALUOp ALU符号
    output LoadType    ID_LoadType,	 		// Load信号 （用于判断是sw sh sb还是lb lbu lh lhu lw ）
    output StoreType   ID_StoreType,  		        // Store信号（用于判断是sw sh sb还是sb sbu sh shu sw ）
    output RegsWrType  ID_RegsWrType,		        // 寄存器写信号打包
    output logic [1:0] ID_WbSel,    		        // 写回信号选择
    //output logic ID_ReadMem,		 		// LoadType 指令在MEM级，产生数据冒险的指令在MEM级检测
    output logic [1:0] ID_DstSel,   		        // 寄存器写回信号选择（Dst）
    //output logic ID_DMWr,			 	// DataMemory 写信号
    output ExceptinPipeType ID_ExceptType_new,	        // 异常类型

    output logic       ID_ALUSrcA,
    output logic       ID_ALUSrcB,
    output logic [1:0] ID_RegsReadSel,
    output logic [1:0] ID_EXTOp,

    output logic       ID_IsAJumpCall,

    output BranchType  ID_BranchType,
    output CacheType   ID_CacheType,

    output logic [1:0] ID_rsrtRead,
    output logic       ID_IsTLBP,
    output logic       ID_IsTLBW,
    output logic       ID_IsTLBR,
    output logic       ID_TLBWIorR,
    output logic [2:0] ID_TrapOp,
    output logic       ID_IsMFC0,
    output logic       ID_IsBrchLikely,
    output logic       ID_IsBranch,
    output logic       ID_IsMOVN,
    output logic       ID_IsMOVZ
    );

    assign ID_IsTLBP   = (ID_Instr == 32'b010000_1_000_0000_0000_0000_0000_001000);
    assign ID_IsTLBW   = (ID_Instr == 32'b010000_1_000_0000_0000_0000_0000_000010 || ID_Instr == 32'b010000_1_000_0000_0000_0000_0000_000110);
    assign ID_IsTLBR   = (ID_Instr == 32'b010000_1_000_0000_0000_0000_0000_000001);
    assign ID_TLBWIorR = (ID_Instr == 32'b010000_1_000_0000_0000_0000_0000_000110);
    assign ID_IsMOVN   = (ID_Instr[31:26]=='0 && ID_Instr[5:0]==6'b001011);
    assign ID_IsMOVZ   = (ID_Instr[31:26]=='0 && ID_Instr[5:0]==6'b001010);

    logic [5:0]opcode;
    logic [5:0]funct;
    logic [4:0]rt;
    logic [4:0]rs;
    logic [4:0]rd;
    logic [4:0]shamt;
    InstrType instrType;
    logic IsReserved;
    logic [1:0] CpU1_instr_valid;

    assign opcode = ID_Instr[31:26];
    assign funct = ID_Instr[5:0];
    assign rs = ID_Instr[25:21];
    assign rt = ID_Instr[20:16];
    assign rd = ID_Instr[15:11];
    assign shamt = ID_Instr[10:6];
    // the  work before clasification 

    // always_comb begin
    //   if(rs == 5'b00000)begin
    //     ID_rsrtRead[1] = 1'b0;
    //   end
    //   else ID_rsrtRead[1] = 1'b1;
    // end

    // always_comb begin
    //   if(rt == 5'b00000)begin
    //     ID_rsrtRead[0] = 1'b0;
    //   end
    //   else ID_rsrtRead[0] = 1'b1;
    // end
    always_comb begin : ID_IsBranch_blockName
      casez (opcode)
        6'b000_000:begin
          if(funct[5:1] == 5'b00100) ID_IsBranch = 1'b1;
          else                       ID_IsBranch = 1'b0;
        end
        6'b000_001:begin
          if(rt[4:2] == 3'b000 || rt[4:2] == 3'b100) ID_IsBranch = 1'b1;
          else                                       ID_IsBranch = 1'b0;
        end
        6'b000_01?:begin
          ID_IsBranch = 1'b1;
        end 
        6'b000_1??:begin
          ID_IsBranch = 1'b1;
        end
        6'b010100,6'b010101,6'b010110,6'b010111:begin
          ID_IsBranch = 1'b1;
        end
        default: begin
          ID_IsBranch = 1'b0;
        end
      endcase
    end

    always_comb begin : rsrt_blockName
      case (opcode)
        6'b000_001:begin
           ID_rsrtRead[1] = 1'b1;
           ID_rsrtRead[0] = 1'b0;
        end
        6'b010_000:begin
           ID_rsrtRead[1] = 1'b0;
           ID_rsrtRead[0] = 1'b1;
        end
        default: begin
           ID_rsrtRead[1] = 1'b1;
           ID_rsrtRead[0] = 1'b1;
        end
      endcase
    end

    always_comb begin : ID_CacheType_blockname
      if (instrType == OP_CACHE) begin
        case (rt)//instr[20:16]是cache指令的op
          5'b00000:begin
            ID_CacheType.isCache   = 1'b1; 
            ID_CacheType.isIcache  = 1'b1;
            ID_CacheType.isDcache  = 1'b0;
            ID_CacheType.cacheCode = I_Index_Invalid; 
          end
          5'b01000:begin
            ID_CacheType.isCache = 1'b1; 
            ID_CacheType.isIcache  = 1'b1;
            ID_CacheType.isDcache  = 1'b0;
            ID_CacheType.cacheCode = I_Index_Store_Tag; 
          end
          5'b10000:begin
            ID_CacheType.isCache = 1'b1; 
            ID_CacheType.isIcache  = 1'b1;
            ID_CacheType.isDcache  = 1'b0;
            ID_CacheType.cacheCode = I_Hit_Invalid; 
          end
          5'b00001:begin
            ID_CacheType.isCache = 1'b1; 
            ID_CacheType.isIcache  = 1'b0;
            ID_CacheType.isDcache  = 1'b1;
            ID_CacheType.cacheCode = D_Index_Writeback_Invalid;
          end
          5'b01001:begin
            ID_CacheType.isCache = 1'b1;
            ID_CacheType.isIcache  = 1'b0;
            ID_CacheType.isDcache  = 1'b1;             
            ID_CacheType.cacheCode = D_Index_Store_Tag;
          end
          5'b10001:begin
            ID_CacheType.isCache = 1'b1;
            ID_CacheType.isIcache  = 1'b0;
            ID_CacheType.isDcache  = 1'b1; 
            ID_CacheType.cacheCode = D_Hit_Invalid; 
          end
          5'b10101:begin
            ID_CacheType.isCache = 1'b1;
            ID_CacheType.isIcache  = 1'b0;
            ID_CacheType.isDcache  = 1'b1; 
            ID_CacheType.cacheCode = D_Hit_Writeback_Invalid; 
          end
          default: begin
            ID_CacheType = '0;
          end
        endcase
      end else begin
        ID_CacheType = '0;
      end
    end

    always_comb begin : ID_IsMFC0_blockname
      if (instrType == OP_MFC0) begin
        ID_IsMFC0 =1'b1;
      end else begin
        ID_IsMFC0 = 1'b0;
      end
    end
    always_comb begin
        unique casez (opcode)
            6'b000_000:begin// register 
              unique case (funct)

                `EXE_ADD :instrType = OP_ADD;

                `EXE_ADDU:instrType = OP_ADDU;

                `EXE_SUB :instrType = OP_SUB;
                
                `EXE_SUBU:instrType = OP_SUBU;

                `EXE_SLT :instrType = OP_SLT;

                `EXE_SLTU:instrType = OP_SLTU;

                `EXE_DIV :instrType = OP_DIV;

                `EXE_DIVU:instrType = OP_DIVU;

                `EXE_MULT:instrType = OP_MULT;
 
                `EXE_MULTU:instrType = OP_MULTU;

              

                `EXE_AND :instrType = OP_AND;

                `EXE_NOR :instrType = OP_NOR;

                `EXE_OR  :instrType = OP_OR;

                `EXE_XOR :instrType = OP_XOR;



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


                `EXE_JR   :instrType = OP_JR;

                `EXE_JALR :instrType = OP_JALR;

                `EXE_MFHI :instrType = OP_MFHI;

                `EXE_MFLO :instrType = OP_MFLO;

                `EXE_MTHI :instrType = OP_MTHI;

                `EXE_MTLO :instrType = OP_MTLO;

                `EXE_BREAK:instrType = OP_BREAK;

                `EXE_SYSCALL:instrType = OP_SYSCALL;

                `EXE_TEQ  : instrType =  OP_TEQ;

                `EXE_TGE  : instrType =  OP_TGE;

                `EXE_TGEU : instrType =  OP_TGEU;

                `EXE_TLT  : instrType =  OP_TLT;

                `EXE_TLTU : instrType =  OP_TLTU;

                `EXE_TNE  : instrType =  OP_TNE;

                `EXE_SYNC : instrType =  OP_NOP; //SYNC实现为NOP

                `EXE_MOVZ : instrType =  OP_MOVZ;

                `EXE_MOVN : instrType =  OP_MOVN;
                default: begin
                  instrType = OP_INVALID;
                end
              endcase
              end // register

            6'b000_001:begin// some branch
              unique case(rt)
              `EXE_TEQI : instrType = OP_TEQI;

              `EXE_TGEI : instrType = OP_TGEI;

              `EXE_TGEIU: instrType = OP_TGEIU;

              `EXE_TLTI : instrType = OP_TLTI;

              `EXE_TLTIU: instrType = OP_TLTIU;

              `EXE_TNEI : instrType = OP_TNEI;

              `EXE_BLTZ : instrType = OP_BLTZ;

              `EXE_BGEZ : instrType = OP_BGEZ;

              `EXE_BLTZAL:instrType = OP_BLTZAL;

              `EXE_BGEZAL:instrType = OP_BGEZAL;
                
              default: begin
                instrType = OP_INVALID;
              end
              
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
				        		default  : instrType = OP_INVALID;
				        	endcase
				        end
				        default: instrType = OP_INVALID;
			          endcase
            end
            6'b010100:instrType = OP_BEQL;
            6'b010101:instrType = OP_BNEL;
            6'b110011:instrType = OP_NOP; //PREF实现为NOP
            6'b011100:begin
              unique case (funct)
                6'b100001:instrType = OP_CLO;
                6'b100000:instrType = OP_CLZ;
                6'b000000:instrType = OP_MADD;
                6'b000001:instrType = OP_MADDU;
                6'b000100:instrType = OP_MSUB;
                6'b000101:instrType = OP_MSUBU;
                6'b000010:instrType = OP_MUL;
                6'b110111:instrType = OP_FILTER;
                default:  instrType = OP_INVALID;
              endcase
            end
            default:begin
                instrType = OP_INVALID;
            end
        endcase
    end

`ifdef FPU_DETECT_EN

    always_comb begin : CpU_valid
      // CpU1_instr_valid = 1时需要报出CpU例外
      case (opcode)
        6'b000000 : begin  // MOCVI
          if (funct == 6'b000001) CpU1_instr_valid = `ISCOP1_INSTR;  
          else CpU1_instr_valid = `NOTCOP1_INSTR;  // 正常指令
        end
        6'b110101 : begin  // LDC1A
            CpU1_instr_valid = `ISCOP1_INSTR;  
        end
        6'b111101 : begin  // SDC1A
            CpU1_instr_valid = `ISCOP1_INSTR;
        end
        6'b110001: begin  //  LWC1
            CpU1_instr_valid = `ISCOP1_INSTR;
        end  
        6'b111001 : begin // SWC1
            CpU1_instr_valid = `ISCOP1_INSTR;
        end
        6'b010001: begin  // CPO1
          case (ID_Instr[25:21])
            5'b00000 : CpU1_instr_valid = `ISCOP1_INSTR;  // MFC1
            5'b00010 : CpU1_instr_valid = `ISCOP1_INSTR;  // CFC1
            5'b00100 : CpU1_instr_valid = `ISCOP1_INSTR;  // MTC1
            5'b00110 : CpU1_instr_valid = `ISCOP1_INSTR;  // CTC1
            5'b01000 : CpU1_instr_valid = `ISCOP1_INSTR;  // BC1
            5'b10000 : begin
              unique casez(funct) 
                6'b000000 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_ADD
                6'b000001 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_SUB
                6'b000010 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_MUL
                6'b000011 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_DIV
                6'b000100 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_SQRT
                6'b000101 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_ABS
                6'b000111 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_NEG
                6'b001100 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_ROUND
                6'b001101 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_TRUNC
                6'b001110 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_CEIL
                6'b001111 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_FLOOR
                6'b100100 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_CVTW
                6'b000110 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_MOV
                6'b010001 : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_CMOV
                6'b01001? : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_CMOV
                6'b11???? : CpU1_instr_valid = `ISCOP1_INSTR;  // OP_FPU_COND
                default   : CpU1_instr_valid = `FPU_Reserve_INSTR;  // 浮点指令的保留指令例外
              endcase
            end
            5'b10110 : begin
                unique casez(funct)
                    6'b100000  : CpU1_instr_valid = `ISCOP1_INSTR;  // CVTS.PU
                    6'b101000  : CpU1_instr_valid = `ISCOP1_INSTR;  // CVTS.PL
                    default    : CpU1_instr_valid = `FPU_Reserve_INSTR;  // 浮点指令的保留指令例外
                endcase
            end
            default : CpU1_instr_valid = `FPU_Reserve_INSTR;  // 保留指令例外
          endcase 
        end
        default : CpU1_instr_valid = `NOTCOP1_INSTR;  //正常指令
      endcase //opcode case
    end
`endif 

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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;    
        ID_BranchType = '0; 
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
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
        ID_EXTOp      = '0;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0; 
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt     
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt     
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;    
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt   
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;    
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt   
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;     
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
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
        ID_EXTOp      = '0;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt     
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0; 
        IsReserved    = 1'b0;      
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;    
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt   
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;      
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt 
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt       
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt     
      end

      OP_BEQ:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;   //rd,d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_BEQ,1'b1}; 
        IsReserved    = 1'b0;    
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt    
      end
      // Branch Likely decode
      OP_BEQL:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;   //rd,d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;  //ID级别的多选器
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
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
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_BNE,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
      end
      // Branch Likely decode
      OP_BNEL:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;//关于最后写回RF,d
        ID_DstSel     = `DstSel_rd;//rd,d
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall= `IsNotAJumpCall;
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
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_BGE,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_BGT,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_BLE,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_BLT,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_BGE,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_EXTOp      = `EXTOP_SIGN;          //EXT
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_BLT,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_J,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_J,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;    
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;    
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
      end
      OP_SRL:begin
        ID_ALUOp      = `EXE_ALUOp_SRL;    //ALU操作
        ID_LoadType   = '0;                 //访存相关 
        ID_StoreType  = '0;                 //存储相关
        ID_WbSel      = `WBSel_ALUOut;      //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_rd;         //Rtype选rd
        ID_RegsWrType = `RegsWrTypeRFEn;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Shamt; //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;    //ID级选择RF读取结果
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_JR,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end

      OP_JALR:begin
        ID_ALUOp      = `EXE_ALUOp_D;//ALU操作,d
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_PCAdd1;//关于最后写回RF
        ID_DstSel     = `DstSel_rd;//rd
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;//EXE阶段的两个多选器
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;      //ID级别的多选器
        ID_EXTOp      = '0;          //EXT
        ID_IsAJumpCall = `IsAJumpCall;
        ID_BranchType = '{`BRANCH_CODE_JR,1'b1};
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end
      
      //自陷指令
      OP_BREAK:begin
        ID_ALUOp      = '0;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = '0;
        ID_DstSel     = '0;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = '0;
        ID_ALUSrcB    = '0;
        ID_RegsReadSel= '0;//选择ID级别读出的数据
        ID_EXTOp      = '0;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end

      OP_SYSCALL:begin
        ID_ALUOp      = '0;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = '0;
        ID_DstSel     = '0;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = '0;
        ID_ALUSrcB    = '0;
        ID_RegsReadSel= '0;//选择ID级别读出的数据
        ID_EXTOp      = '0;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end

      //访存指令
      OP_LB:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign        = 1;//sign
        ID_LoadType.size        = 2'b10;//byte
        ID_LoadType.ReadMem     = 1;//loadmem
        ID_LoadType.LeftOrRight = '0;
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end

      OP_LBU:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign        = 0;//unsign
        ID_LoadType.size        = 2'b10;//byte
        ID_LoadType.ReadMem     = 1;//loadmem
        ID_LoadType.LeftOrRight = '0;
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end

      OP_LH:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign        = 1;//sign
        ID_LoadType.size        = 2'b01;//half
        ID_LoadType.ReadMem     = 1;//loadmem
        ID_LoadType.LeftOrRight = '0;
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end

      OP_LHU:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign        = 0;//unsign
        ID_LoadType.size        = 2'b01;//half
        ID_LoadType.ReadMem     = 1;//loadmem
        ID_LoadType.LeftOrRight = '0;
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;    
        IsReserved    = 1'b0;  
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end

      OP_LW:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign        = 1;//sign
        ID_LoadType.size        = 2'b00;//word
        ID_LoadType.ReadMem     = 1;//loadmem
        ID_LoadType.LeftOrRight = '0;
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;    
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end
      OP_LWL:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign        = 1;    //sign
        ID_LoadType.size        = 2'b00;//word
        ID_LoadType.ReadMem     = 1;    //loadmem
        ID_LoadType.LeftOrRight = 2'b10;
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;    
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end
      OP_LWR:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        //ID_LoadType 
        ID_LoadType.sign        = 1;    //sign
        ID_LoadType.size        = 2'b00;//word
        ID_LoadType.ReadMem     = 1;    //loadmem
        ID_LoadType.LeftOrRight = 2'b01;
        //ID_LoadType end
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_DMResult;
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsWrType = `RegsWrTypeRFEn;//写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel    = `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;  
        IsReserved    = 1'b0;    
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt
      end

      OP_SB:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        ID_LoadType   = '0;
        //ID_StoreType begin
        ID_StoreType.size  = `STORETYPE_SB;
        ID_StoreType.DMWr  = 1;
        ID_StoreType.LeftOrRight = '0;
        //ID_StoreType end
        ID_WbSel      = `WBSel_ALUOut;//选择输出的地址
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsReadSel    = `RegsReadSel_RF;//选寄存器
        ID_RegsWrType = `RegsWrTypeDisable;//不写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;    
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt      
      end


      OP_SH:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        ID_LoadType   = '0;
        //ID_StoreType begin
        ID_StoreType.size  = `STORETYPE_SH;
        ID_StoreType.DMWr  = 1;
        ID_StoreType.LeftOrRight = '0;
        //ID_StoreType end
        ID_WbSel      = `WBSel_ALUOut;//选择输出的地址
        ID_DstSel     = `DstSel_rt;//rt
        ID_RegsReadSel    = `RegsReadSel_RF;//选寄存器
        ID_RegsWrType = `RegsWrTypeDisable;//不写寄存器
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_EXTOp      = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;   
        IsReserved    = 1'b0;    
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt      
      end

      OP_SW:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        ID_LoadType   = '0;
        //ID_StoreType begin
        ID_StoreType.size  = `STORETYPE_SW;
        ID_StoreType.DMWr  = 1;
        ID_StoreType.LeftOrRight = '0;
        //ID_StoreType end
        ID_WbSel       = `WBSel_ALUOut;//选择输出的地址
        ID_DstSel      = `DstSel_rt;//rt
        ID_RegsReadSel = `RegsReadSel_RF;//选寄存器
        ID_RegsWrType  = `RegsWrTypeDisable;//不写寄存器
        ID_ALUSrcA     = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB     = `ALUSrcB_Sel_Imm;
        ID_EXTOp       = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType  = '0;    
        IsReserved     = 1'b0;    
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt     
      end

      OP_SWL:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        ID_LoadType   = '0;
        //ID_StoreType begin
        ID_StoreType.size  = `STORETYPE_SW;
        ID_StoreType.DMWr  = 1;
        ID_StoreType.LeftOrRight = 2'b10;
        //ID_StoreType end
        ID_WbSel       = `WBSel_ALUOut;//选择输出的地址
        ID_DstSel      = `DstSel_rt;//rt
        ID_RegsReadSel = `RegsReadSel_RF;//选寄存器
        ID_RegsWrType  = `RegsWrTypeDisable;//不写寄存器
        ID_ALUSrcA     = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB     = `ALUSrcB_Sel_Imm;
        ID_EXTOp       = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType  = '0;    
        IsReserved     = 1'b0;      
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt   
      end

      OP_SWR:begin
        ID_ALUOp      = `EXE_ALUOp_ADDU;
        ID_LoadType   = '0;
        //ID_StoreType begin
        ID_StoreType.size  = `STORETYPE_SW;
        ID_StoreType.DMWr  = 1;
        ID_StoreType.LeftOrRight = 2'b01;
        //ID_StoreType end
        ID_WbSel       = `WBSel_ALUOut;//选择输出的地址
        ID_DstSel      = `DstSel_rt;//rt
        ID_RegsReadSel = `RegsReadSel_RF;//选寄存器
        ID_RegsWrType  = `RegsWrTypeDisable;//不写寄存器
        ID_ALUSrcA     = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB     = `ALUSrcB_Sel_Imm;
        ID_EXTOp       = `EXTOP_SIGN;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType  = '0;    
        IsReserved     = 1'b0;      
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt   
      end

      //特权指令  
      OP_ERET:begin
        ID_ALUOp      = '0;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = '0;
        ID_DstSel     = '0;
        ID_RegsWrType = `RegsWrTypeDisable;
        ID_ALUSrcA    = '0;
        ID_ALUSrcB    = '0;
        ID_RegsReadSel= '0;//选择ID级别读出的数据
        ID_EXTOp      = '0;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt   
      end

      OP_MFC0:begin
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_WbSel      = `WBSel_OutB;
        ID_DstSel     = `DstSel_rt;//rt 
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_ALUSrcA    = '0;
        ID_ALUSrcB    = '0;
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_RegsReadSel= `RegsReadSel_CP0;//选择CP0进行读取
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
      end
    
      OP_MTC0:begin
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_WbSel      = `WBSel_OutB;
        ID_DstSel     = `DstSel_rd;//rd
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_ALUSrcA    = '0;
        ID_ALUSrcB    = '0;
        ID_RegsWrType = `RegsWrTypeCP0En;//写CP0
        ID_RegsReadSel= `RegsReadSel_RF;//选择RF进行读取
        ID_EXTOp      = '0;                 //R型无关
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt  
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt  
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt  
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt  
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt  
      end

      OP_MUL:begin
        ID_ALUOp      = `EXE_ALUOp_MUL;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_FILTER:begin
        ID_ALUOp      = `EXE_ALUOp_FILTER;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = `RegsWrTypeRFEn;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = '0;
        ID_IsAJumpCall = `IsNotAJumpCall;
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
      end

      OP_TLBWR:begin//search
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
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
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
      end
//**********************   trap类指令   ********************************//
      OP_TEQ , OP_TGE , OP_TGEU , OP_TLT , OP_TLTU , OP_TNE: begin
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = '0;
        ID_DstSel     = '0;  //rd
        ID_RegsWrType = '0;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;//选择ID级别读出的数据
        ID_EXTOp      = '0;
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b1; //rt  
      end

      OP_TEQI , OP_TGEI , OP_TGEIU , OP_TLTI , OP_TLTIU ,  OP_TNEI : begin
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = '0;
        ID_DstSel     = '0;//rt
        ID_RegsWrType = '0;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;
        ID_RegsReadSel= `RegsReadSel_RF;      
        ID_EXTOp      = `EXTOP_SIGN;   
        ID_IsAJumpCall = `IsNotAJumpCall;    
        ID_BranchType = '0; 
        IsReserved    = 1'b0;        
        //ID_rsrtRead[1]= 1'b1; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt  
      end

      OP_CACHE:begin//TODO: 修改cache指令的译码
        ID_ALUOp      = `EXE_ALUOp_ADDU;    //ALU操作
        ID_LoadType   = '0;    //访存相关 
        ID_StoreType  = '0;    //存储相关
        ID_WbSel      = '0;    //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_nop;    //Rtype选rd
        ID_RegsWrType = `RegsWrTypeDisable;    //写回哪里
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs; //MUXA选择regs
        ID_ALUSrcB    = `ALUSrcB_Sel_Imm;  //MUXB选择regs
        ID_RegsReadSel= `RegsReadSel_RF;        //ID级选择RF读取结果
        ID_EXTOp      = `EXTOP_SIGN;                 //R型无关
        ID_IsAJumpCall = `IsNotAJumpCall;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      OP_NOP:begin
        ID_ALUOp      = `EXE_ALUOp_D;    //ALU操作
        ID_LoadType   = '0;    //访存相关 
        ID_StoreType  = '0;    //存储相关
        ID_WbSel      = '0;    //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     = `DstSel_nop;    //Rtype选rd
        ID_RegsWrType = '0;    //写回哪里
        ID_ALUSrcA    = '0; //MUXA选择regs
        ID_ALUSrcB    = '0;  //MUXB选择regs
        ID_RegsReadSel= '0;        //ID级选择RF读取结果
        ID_EXTOp      = `EXTOP_NOP;                 //R型无关
        ID_IsAJumpCall= '0;
        ID_BranchType = '0;
        IsReserved    = 1'b0;   
      end

      OP_MOVZ,OP_MOVN:begin
        ID_ALUOp      = `EXE_ALUOp_D;
        ID_LoadType   = '0;
        ID_StoreType  = '0;
        ID_WbSel      = `WBSel_ALUOut;
        ID_DstSel     = `DstSel_rd;
        ID_RegsWrType = '0;
        ID_ALUSrcA    = `ALUSrcA_Sel_Regs;
        ID_ALUSrcB    = `ALUSrcB_Sel_Regs;
        ID_RegsReadSel= `RegsReadSel_RF;
        ID_EXTOp      = `EXTOP_NOP;
        ID_IsAJumpCall= '0;
        ID_BranchType = '0;
        IsReserved    = 1'b0;
      end

      default:begin
        ID_ALUOp      = `EXE_ALUOp_D;    //ALU操作
        ID_LoadType   = '0;    //访存相关 
        ID_StoreType  = '0;    //存储相关
        ID_WbSel      = '0;    //关于最后写回的是PC & ALU & RF ..
        ID_DstSel     =  `DstSel_nop;    //Rtype选rd
        ID_RegsWrType = '0;    //写回哪里
        ID_ALUSrcA    = '0; //MUXA选择regs
        ID_ALUSrcB    = '0;  //MUXB选择regs
        ID_RegsReadSel= '0;        //ID级选择RF读取结果
        ID_EXTOp      = `EXTOP_NOP;                 //R型无关
        ID_IsAJumpCall = '0;
        ID_BranchType = '0;
        IsReserved    = 1'b1;      
        //ID_rsrtRead[1]= 1'b0; //rs 
        //ID_rsrtRead[0]= 1'b0; //rt    
      end

    endcase
  end 

always_comb begin
  if(instrType == OP_BREAK) begin
    ID_ExceptType_new = '{
                            Interrupt:1'b0,
                            Break:1'b1,
                            WrongAddressinIF:1'b0,
                            ReservedInstruction:1'b0,
                            CoprocessorUnusable:1'b0,
                            Overflow:1'b0,
                            Syscall:1'b0,
                            Eret:1'b0,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefillinIF:ID_ExceptType.TLBRefillinIF,
                            TLBInvalidinIF:ID_ExceptType.TLBInvalidinIF,
                            RdTLBRefillinMEM:1'b0,
                            RdTLBInvalidinMEM:1'b0,
                            WrTLBRefillinMEM:1'b0,
                            WrTLBInvalidinMEM:1'b0,
                            TLBModified:1'b0,
                            Trap:1'b0,
                            Refetch:(ID_ExceptType.Refetch || ID_Refetch)
        };//关于Break异常
  end
  else if(instrType == OP_SYSCALL) begin
    ID_ExceptType_new = '{
                            Interrupt:1'b0,
                            Break:1'b0,
                            WrongAddressinIF:1'b0,
                            ReservedInstruction:1'b0,
                            CoprocessorUnusable:1'b0,
                            Overflow:1'b0,
                            Syscall:1'b1,
                            Eret:1'b0,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefillinIF:ID_ExceptType.TLBRefillinIF,
                            TLBInvalidinIF:ID_ExceptType.TLBInvalidinIF,
                            RdTLBRefillinMEM:1'b0,
                            RdTLBInvalidinMEM:1'b0,
                            WrTLBRefillinMEM:1'b0,
                            WrTLBInvalidinMEM:1'b0,
                            TLBModified:1'b0,
                            Trap:1'b0,
                            Refetch:(ID_ExceptType.Refetch || ID_Refetch)
        };//关于SYSCALL
  end
  else if(instrType == OP_ERET) begin
    ID_ExceptType_new = '{  
                            Interrupt:1'b0,
                            Break:1'b0,
                            WrongAddressinIF:1'b0,
                            ReservedInstruction:1'b0,
                            CoprocessorUnusable:1'b0,
                            Overflow:1'b0,
                            Syscall:1'b0,
                            Eret:1'b1,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefillinIF:ID_ExceptType.TLBRefillinIF,
                            TLBInvalidinIF:ID_ExceptType.TLBInvalidinIF,
                            RdTLBRefillinMEM:1'b0,
                            RdTLBInvalidinMEM:1'b0,
                            WrTLBRefillinMEM:1'b0,
                            WrTLBInvalidinMEM:1'b0,
                            TLBModified:1'b0,
                            Trap:1'b0,
                            Refetch:(ID_ExceptType.Refetch || ID_Refetch)
        };//关于ERET
  end
  `ifdef FPU_DETECT_EN
  else if (CpU1_instr_valid == `ISCOP1_INSTR) begin  // 浮点指令
    ID_ExceptType_new = '{  
                            Interrupt:1'b0,
                            Break:1'b0,
                            WrongAddressinIF:1'b0,
                            ReservedInstruction:1'b0,
                            CoprocessorUnusable:1'b1,
                            Overflow:1'b0,
                            Syscall:1'b0,
                            Eret:1'b0,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefillinIF:ID_ExceptType.TLBRefillinIF,
                            TLBInvalidinIF:ID_ExceptType.TLBInvalidinIF,
                            RdTLBRefillinMEM:1'b0,
                            RdTLBInvalidinMEM:1'b0,
                            WrTLBRefillinMEM:1'b0,
                            WrTLBInvalidinMEM:1'b0,
                            TLBModified:1'b0,
                            Trap:1'b0,
                            Refetch:(ID_ExceptType.Refetch || ID_Refetch)
        };//关于ERET
  end
  `endif 
  else begin
    ID_ExceptType_new = '{  
                            Interrupt:1'b0,
                            Break:1'b0,
                            WrongAddressinIF:1'b0,
                            `ifdef FPU_DETECT_EN
                            ReservedInstruction:(CpU1_instr_valid == `FPU_Reserve_INSTR || IsReserved == 1'b1),
                            `else
                            ReservedInstruction:IsReserved,
                            `endif 
                            CoprocessorUnusable:1'b0,
                            Overflow:1'b0,
                            Syscall:1'b0,
                            Eret:1'b0,
                            WrWrongAddressinMEM:1'b0,
                            RdWrongAddressinMEM:1'b0,
                            TLBRefillinIF:ID_ExceptType.TLBRefillinIF,
                            TLBInvalidinIF:ID_ExceptType.TLBInvalidinIF,
                            RdTLBRefillinMEM:1'b0,
                            RdTLBInvalidinMEM:1'b0,
                            WrTLBRefillinMEM:1'b0,
                            WrTLBInvalidinMEM:1'b0,
                            TLBModified:1'b0,
                            Trap:1'b0,
                            Refetch:(ID_ExceptType.Refetch || ID_Refetch)
        };//保留指令例外
  end
end
// trap的检测
`ifdef TRAP
always_comb begin
  case(instrType) 
    OP_TEQ  , OP_TEQI  : ID_TrapOp = `TRAP_OP_TEQ;
    OP_TGE  , OP_TGEI  : ID_TrapOp = `TRAP_OP_TGE;
    OP_TGEU , OP_TGEIU : ID_TrapOp = `TRAP_OP_TGEU;
    OP_TLT  , OP_TLTI  : ID_TrapOp = `TRAP_OP_TLT;
    OP_TLTU , OP_TLTIU : ID_TrapOp = `TRAP_OP_TLTU;
    OP_TNE  , OP_TNEI  : ID_TrapOp = `TRAP_OP_TNE;
    default : ID_TrapOp = `TRAP_OP_None;
  endcase
end
`endif
// Branch Likely的检测
always_comb begin
  unique case (instrType)
    OP_BEQL,OP_BNEL : ID_IsBrchLikely = 1'b1; 
    default : ID_IsBrchLikely = 1'b0; 
    endcase
end

endmodule
