module lc4_alu_out(
    input wire [15:0] ADD_0, MUL_1, SUB_2, DIV_3, MOD_4, ADDIMMM_5, ADDIMM_6, AND_8, NOT_9, OR_10, XOR_11, ANDIMM_12, CMP_16, CMPU_17, CMPI_18, CMPUI_19, SLL_24, SRA_25, SRL_26, CONST_32, HICONST_33, ALU_CTL
    output wire [15:0] C)

    case(ALU_CTL) 
        16'd0 : assign C = ADD_0;
        16'd1 : assign C = MUL_1;
        16'd2 : assign C = SUB_2;
        16'd3 : assign C = DIV_3;
        16'd4 : assign C = MOD_4;
        16'd5 : assign C = ADDIMMM_5;
        16'd6 : assign C = ADDIMM_6;
        16'd7 : assign C = AND_8;
        16'd9 : assign C = NOT_9;
        16'd10 : assign C = OR_10;
        16'd11 : assign C = XOR_11;
        16'd12 : assign C = ANDIMM_12;
        16'd16 : assign C = CMP_16;
        16'd17 : assign C = CMPU_17;
        16'd18 : assign C = CMPI_18;
        16'd19 : assign C = CMPUI_19;
        16'd24 : assign C = SLL_24;
        16'd25 : assign C = SRA_25;
        16'd26 : assign C = SRL_26;
        16'd32 : assign C = CONST_32;
        16'd33 : assign C = HICONST_33;
    endcase
