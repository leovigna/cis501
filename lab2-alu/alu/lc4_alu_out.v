module lc4_alu_out(
    input wire [15:0] ADD_0, MUL_1, SUB_2, DIV_3, MOD_4, ADDIMM_5, ADDIMM_6, AND_8, NOT_9, OR_10, XOR_11, ANDIMM_12, CMP_16, CMPU_17, CMPI_18, CMPIU_19, SLL_24, SRA_25, SRL_26, CONST_32, HICONST_33, JMPP_34, JMP_35, TRAP_37, RTI_36, NOP_38, BR_39, ALU_CTL, 
    output wire [15:0] C);

    reg [15:0] c_reg;

    always @ (*) begin
        case(ALU_CTL) 
            16'd0 : c_reg = ADD_0;
            16'd1 : c_reg = MUL_1;
            16'd2 : c_reg = SUB_2;
            16'd3 : c_reg = DIV_3;
            16'd4 : c_reg = MOD_4;
            16'd5 : c_reg = ADDIMM_5;
            16'd6 : c_reg = ADDIMM_6;
            16'd7 : c_reg = AND_8;
            16'd9 : c_reg = NOT_9;
            16'd10 : c_reg = OR_10;
            16'd11 : c_reg = XOR_11;
            16'd12 : c_reg = ANDIMM_12;
            16'd16 : c_reg = CMP_16;
            16'd17 : c_reg = CMPU_17;
            16'd18 : c_reg = CMPI_18;
            16'd19 : c_reg = CMPIU_19;
            16'd24 : c_reg = SLL_24;
            16'd25 : c_reg = SRA_25;
            16'd26 : c_reg = SRL_26;
            16'd32 : c_reg = CONST_32;
            16'd33 : c_reg = HICONST_33;
            16'd34 : c_reg = JMPP_34;
            16'd35 : c_reg = JMP_35;
            16'd36 : c_reg = RTI_36;
            16'd37 : c_reg = TRAP_37;
            16'd38 : c_reg = NOP_38;
            16'd39 : c_reg = BR_39;
        endcase
    end

    assign C = c_reg;
    
endmodule