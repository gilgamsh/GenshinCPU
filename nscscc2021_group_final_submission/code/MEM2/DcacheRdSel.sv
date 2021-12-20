`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"
module DcacheRdataSel(
    input  LoadType      MEM2_LoadType,
    input  logic [31:0]  cache_rdata,
    input  logic [31:0]  reg_rt,
    input  logic [31:0]  RdAddr,
    output logic [31:0]  DcacheRdData
);
    logic [31:0] LoadByteData;
    always_comb begin : LoadByteData_blockname
        unique case({MEM2_LoadType.sign,MEM2_LoadType.size})
        `LOADTYPE_LB: begin
            unique case (RdAddr[1:0])
            2'b00 : LoadByteData = {{24{cache_rdata[7]}} ,cache_rdata[7:0]  };
            2'b01 : LoadByteData = {{24{cache_rdata[15]}},cache_rdata[15:8] };
            2'b10 : LoadByteData = {{24{cache_rdata[23]}},cache_rdata[23:16]};
            2'b11 : LoadByteData = {{24{cache_rdata[31]}},cache_rdata[31:24]};
            default : LoadByteData = 'x;
            endcase
        end
        `LOADTYPE_LBU: begin
            unique case (RdAddr[1:0])
            2'b00 : LoadByteData = {{24{1'b0}},cache_rdata[7:0]  };
            2'b01 : LoadByteData = {{24{1'b0}},cache_rdata[15:8] };
            2'b10 : LoadByteData = {{24{1'b0}},cache_rdata[23:16]};
            2'b11 : LoadByteData = {{24{1'b0}},cache_rdata[31:24]};
            default : LoadByteData = 'x;
            endcase
        end
        default : LoadByteData = 'x;
        endcase
    end

    always_comb begin
        unique case (MEM2_LoadType.LeftOrRight)
        2'b10:begin  // LWL
            unique case (RdAddr[1:0])
                2'b00 : DcacheRdData = {cache_rdata[7:0]  , reg_rt[23:0]};
                2'b01 : DcacheRdData = {cache_rdata[15:0] , reg_rt[15:0]};
                2'b10 : DcacheRdData = {cache_rdata[23:0] , reg_rt[7:0] };
                2'b11 : DcacheRdData = {cache_rdata[31:0] };
                default : DcacheRdData = 'x;
            endcase
        end
        2'b01:begin  // LWR
            unique case (RdAddr[1:0])
                2'b00 : DcacheRdData = {cache_rdata[31:0]};
                2'b01 : DcacheRdData = {reg_rt[31:24] , cache_rdata[31:8] };
                2'b10 : DcacheRdData = {reg_rt[31:16] , cache_rdata[31:16]};
                2'b11 : DcacheRdData = {reg_rt[31:8]  , cache_rdata[31:24]};
                default : DcacheRdData = 'x;
            endcase
        end
        2'b00:begin   // 正常访存数据
            unique case({MEM2_LoadType.sign,MEM2_LoadType.size})
            `LOADTYPE_LW : begin
                DcacheRdData = cache_rdata;
            end
            `LOADTYPE_LH : begin
                unique case (RdAddr[1]) 
                1'b0 : DcacheRdData = {{16{cache_rdata[15]}},cache_rdata[15:0]};
                1'b1 : DcacheRdData = {{16{cache_rdata[31]}},cache_rdata[31:16]}; 
                default : DcacheRdData = 'x;
                endcase
            end
             `LOADTYPE_LHU: begin
                unique case (RdAddr[1]) 
                1'b0 : DcacheRdData = {{16{1'b0}},cache_rdata[15:0]};
                1'b1 : DcacheRdData = {{16{1'b0}},cache_rdata[31:16]}; 
                default : DcacheRdData = 'x;
                endcase
             end
            `LOADTYPE_LB , `LOADTYPE_LBU:begin
                DcacheRdData = LoadByteData;
            end
            default : DcacheRdData = 'x;
        endcase
        end
    endcase
    end

endmodule