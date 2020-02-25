/* 
    Leo Vigna: leovigna
    Nate Rush: narush
*/
 
`timescale 1ns / 1ps

`default_nettype none

`include "./lc4_divider.v"
`include "./lc4_cla.v"

module lc4_alu_ctl(input  wire [15:0] i_insn,
                  output wire [15:0] alu_ctl);

      reg [15:0] alu_out;
      
      always @ * begin
        case (i_insn[15:12]) 
            4'd0 : begin
                  case (i_insn[11:9])
                        3'd0 : alu_out = 16'd38; // nop
                        default : alu_out = 16'd39; // BR_
                  endcase    
                  end
            4'd1 : begin
                  case (i_insn[5:3])
                        3'd0 : alu_out = 16'd0; // add
                        3'd1 : alu_out = 16'd1; // mul
                        3'd2 : alu_out = 16'd2; // sub
                        3'd3 : alu_out = 16'd3; // div
                        default : alu_out = 16'd5; // addi
                  endcase
                  end
            4'd2 : begin
                  case (i_insn[8:7])
                        2'd0 : alu_out = 16'd16; // cmp
                        2'd1 : alu_out = 16'd17; // cmpu
                        2'd2 : alu_out = 16'd18; // cmpi
                        2'd3 : alu_out = 16'd19; // cmpiu
                  endcase
                  end
            4'd4 : begin
                  case (i_insn[11])
                        1'd0 : alu_out = 16'd40; // jsrr
                        1'd1 : alu_out = 16'd41; // jsr
                  endcase            
                  end 
            4'd5 : begin
                  case (i_insn[5:3])
                        3'd0 : alu_out = 16'd8; // add
                        3'd1 : alu_out = 16'd9; // not
                        3'd2 : alu_out = 16'd10; // or
                        3'd3 : alu_out = 16'd11; // xor
                        default : alu_out = 16'd12; // andi
                  endcase
                  end
            4'd6 : alu_out = 16'd6; 
            4'd7 : alu_out = 16'd6; 
            4'd8 : alu_out = 16'd36; 
            4'd9 : alu_out = 16'd32; 
            4'd10 : begin
                  case (i_insn[5:4])
                        2'd0 : alu_out = 16'd24; // sll
                        2'd1 : alu_out = 16'd25; // sra
                        2'd2 : alu_out = 16'd26; // srl
                        2'd3 : alu_out = 16'd4; // mod
                  endcase
                  end
            4'd12 : begin
                  case (i_insn[11])
                        1'd0 : alu_out = 16'd34; // jmpp
                        1'd1 : alu_out = 16'd35; // jmp
                  endcase
                  end
            4'd13 : alu_out = 16'd33;
            4'd15 : alu_out = 16'd37; // trap
        endcase
    end

    assign alu_ctl = alu_out;

endmodule

module lc4_alu_out(
    input wire [15:0] ADD_0, MUL_1, SUB_2, DIV_3, MOD_4, ADDIMM_5, ADDIMM_6, AND_8, NOT_9, OR_10, XOR_11, ANDIMM_12, CMP_16, CMPU_17, CMPI_18, CMPIU_19, SLL_24, SRA_25, SRL_26, CONST_32, HICONST_33, JMPP_34, JMP_35, TRAP_37, RTI_36, NOP_38, BR_39, JSRR_40, JSR_41, ALU_CTL, 
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
            16'd8 : c_reg = AND_8;
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
            16'd40 : c_reg = JSRR_40;
            16'd41 : c_reg = JSR_41;
        endcase
    end

    assign C = c_reg;
    
endmodule

module lc4_arith(input wire [15:0] A, B, ALU_CTL, i_insn,
               output wire [15:0]  ADD_0, MUL_1, SUB_2, DIV_3, MOD_4, ADDIMM_5, ADDIMM_6);


    assign MUL_1 = A * B;
    lc4_divider m1(.i_dividend(A), .i_divisor(B), .o_quotient(DIV_3), .o_remainder(MOD_4)); 
    
    wire in_carry;
    reg in_carry_reg;
    wire [15:0] in_B;
    reg [15:0] in_B_reg;

    always @ (*) begin
        case(ALU_CTL) 
            16'd0 : begin
                in_carry_reg = 1'b0;
                in_B_reg = B; // ADD
                end
            16'd2 : begin
                in_carry_reg = 1'b1; 
                in_B_reg = ~B; // SUB
                end 
            16'd5 : begin
                in_carry_reg = 1'b0; 
                in_B_reg = {{12{i_insn[4]}}, i_insn[3:0]}; // ADDIMM_5
                end
            16'd6 : begin
                in_carry_reg = 1'b0; 
                in_B_reg = {{11{i_insn[5]}}, i_insn[4:0]}; // ADDIMM_6
                end
        endcase
    end

    assign in_B = in_B_reg;
    assign in_carry = in_carry_reg;

    wire [15:0] sum_out;
    cla16 m2(.a(A), .b(in_B), .cin(in_carry), .sum(sum_out));

    // Same output
    assign ADD_0 = sum_out;
    assign SUB_2 = sum_out;
    assign ADDIMM_5 = sum_out;
    assign ADDIMM_6 = sum_out;

endmodule

module lc4_cmp(input  wire [15:0] A, B, i_insn,
               output wire [15:0] CMP_16, CMPU_17, CMPI_18, CMPIU_19);

    wire [2:0] CMP_sel, CMPU_sel, CMPI_sel, CMPIU_sel;
    wire [6:0] UIMM7;    
    assign UIMM7 = i_insn[6:0];

    //Concatenate comparison results
    assign CMP_sel = { $signed(A) > $signed(B), $signed(A) == $signed(B), $signed(A) < $signed(B) };
    assign CMPU_sel = { A > B, A == B, A < B }; 
    assign CMPI_sel = { $signed(A) > $signed(UIMM7), $signed(A) == $signed(UIMM7), $signed(A) < $signed(UIMM7) };
    assign CMPIU_sel = { A > UIMM7, A == UIMM7, A < UIMM7 };

    reg [15:0] CMP_16_reg, CMPU_17_reg, CMPI_18_reg, CMPIU_19_reg;

    always @ (CMP_sel) begin
        case(CMP_sel) 
            3'b100 : CMP_16_reg = 16'd1;
            3'b010 : CMP_16_reg = 16'd0;
            3'b001 : CMP_16_reg = -16'd1;
        endcase
    end

    always @ (CMPU_sel) begin
        case(CMPU_sel) 
            3'b100 : CMPU_17_reg = 16'd1;
            3'b010 : CMPU_17_reg = 16'd0;
            3'b001 : CMPU_17_reg = -16'd1;
        endcase
    end

    always @ (CMPI_sel) begin
        case(CMPI_sel) 
            3'b100 : CMPI_18_reg = 16'd1;
            3'b010 : CMPI_18_reg = 16'd0;
            3'b001 : CMPI_18_reg = -16'd1;
        endcase
    end

    //{ A > UIMM7, A == UIMM7, A < UIMM7 }
    always @ (CMPIU_sel) begin
        case(CMPIU_sel) 
            3'b100 : CMPIU_19_reg = 16'd1;
            3'b010 : CMPIU_19_reg = 16'd0;
            3'b001 : CMPIU_19_reg = -16'd1;
        endcase
    end

    assign CMP_16 = CMP_16_reg;
    assign CMPU_17 = CMPU_17_reg;
    assign CMPI_18 = CMPI_18_reg;
    assign CMPIU_19 = CMPIU_19_reg;

endmodule


module lc4_const(input  wire [15:0] A, B,
               output wire [15:0] CONST_32, HICONST_33);

    assign CONST_32 = $signed({{8{B[8]}}, B[7:0]});
    assign HICONST_33 =  (A & 16'hFF) | (B[7:0] << 8);
    
endmodule

module lc4_log(input  wire [15:0] A, B, i_insn,
               output  wire [15:0] AND_8, NOT_9, OR_10, XOR_11, ANDIMM_12);

    wire [15:0] IMM5;
    assign IMM5 = {{12{i_insn[4]}}, i_insn[3:0]};
    
    assign AND_8 = A & B;
    assign NOT_9 = ~A;
    assign OR_10 = A | B;
    assign XOR_11 = A^B;
    assign ANDIMM_12 = A & IMM5;
    
endmodule

module lc4_shift(input  wire [15:0] A, B,
               output wire [15:0] SLL_24, SRA_25, SRL_26);

    wire [3:0] B_30;

    assign B_30 = B[3:0];
    assign SLL_24 = A << B_30;
    assign SRA_25 = $signed(A) >>> B_30;
    assign SRL_26 = A >> B_30;

endmodule

module lc4_trap(input  wire [15:0] i_insn,
               output wire [15:0] TRAP_37);

    assign TRAP_37 = (16'h8000 | {8'b0, i_insn[7:0]});

endmodule

module lc4_jmp(input  wire [15:0] A, B, i_pc,
               output wire [15:0] JMPP_34, JMP_35);

    wire [15:0] UIMM11;
    assign UIMM11 = $signed({{6{B[10]}}, B[9:0]});

    assign JMPP_34 = A;
    assign JMP_35 = i_pc + 16'd1 + UIMM11;

endmodule

module lc4_br(input  wire [15:0] i_insn, i_pc,
               output wire [15:0] NOP_38, BR_39);

    assign NOP_38 = i_pc + 1 + $signed({{8{i_insn[8]}}, i_insn[7:0]});
    assign BR_39 = i_pc + 1 + $signed({{8{i_insn[8]}}, i_insn[7:0]});

endmodule

module lc4_jsr(input  wire [15:0] A, i_insn, i_pc,
               output wire [15:0] JSRR_40, JSR_41);

    assign JSRR_40 = A;
    assign JSR_41 = (i_pc & 16'h8000) | ((i_insn[10:0]) << 4);

endmodule

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/
    wire [15:0] ADD_0, MUL_1, SUB_2, DIV_3, MOD_4, ADDIMM_5, ADDIMM_6, AND_8, NOT_9, OR_10, XOR_11, ANDIMM_12, CMP_16, CMPU_17, CMPI_18, CMPIU_19, SLL_24, SRA_25, SRL_26, CONST_32, HICONST_33, JMPP_34, JMP_35, TRAP_37, RTI_36, NOP_38, BR_39, JSRR_40, JSR_41, ALU_CTL;
    
    lc4_alu_ctl m1(.i_insn(i_insn), .alu_ctl(ALU_CTL));

    lc4_arith m2(.A(i_r1data), .B(i_r2data), .ALU_CTL(ALU_CTL), .i_insn(i_insn), .ADD_0(ADD_0), .MUL_1(MUL_1), .SUB_2(SUB_2), .DIV_3(DIV_3), .MOD_4(MOD_4), .ADDIMM_5(ADDIMM_5), .ADDIMM_6(ADDIMM_6));
    lc4_cmp m3(.A(i_r1data), .B(i_r2data), .i_insn(i_insn), .CMP_16(CMP_16), .CMPU_17(CMPU_17), .CMPI_18(CMPI_18), .CMPIU_19(CMPIU_19));
    lc4_const m4(.A(i_r1data), .B(i_insn), .CONST_32(CONST_32), .HICONST_33(HICONST_33));
    lc4_log m5(.A(i_r1data), .B(i_r2data), .i_insn(i_insn), .AND_8(AND_8), .NOT_9(NOT_9), .OR_10(OR_10), .XOR_11(XOR_11), .ANDIMM_12(ANDIMM_12));
    lc4_shift m6(.A(i_r1data), .B({12'd0, i_insn[3:0]}), .SLL_24(SLL_24), .SRA_25(SRA_25), .SRL_26(SRL_26));
    lc4_jmp m7(.A(i_r1data), .B(i_insn), .i_pc(i_pc), .JMPP_34(JMPP_34), .JMP_35(JMP_35));
    lc4_trap m8(.i_insn(i_insn), .TRAP_37(TRAP_37));
    lc4_br m9(.i_insn(i_insn), .i_pc(i_pc), .NOP_38(NOP_38), .BR_39(BR_39));
    lc4_jsr m10(.A(i_r1data), .i_insn(i_insn), .i_pc(i_pc), .JSRR_40(JSRR_40), .JSR_41(JSR_41));

    assign RTI_36 = i_r1data;

    lc4_alu_out m11(.ADD_0(ADD_0), .MUL_1(MUL_1), .SUB_2(SUB_2), .DIV_3(DIV_3), 
        .MOD_4(MOD_4), .ADDIMM_5(ADDIMM_5), .ADDIMM_6(ADDIMM_6), 
        .CMP_16(CMP_16), .CMPU_17(CMPU_17), .CMPI_18(CMPI_18), .CMPIU_19(CMPIU_19), 
        .CONST_32(CONST_32), .HICONST_33(HICONST_33), 
        .AND_8(AND_8), .NOT_9(NOT_9), .OR_10(OR_10), .XOR_11(XOR_11), .ANDIMM_12(ANDIMM_12), 
        .SLL_24(SLL_24), .SRA_25(SRA_25), .SRL_26(SRL_26),
        .JMPP_34(JMPP_34), .JMP_35(JMP_35),
        .TRAP_37(TRAP_37), .RTI_36(RTI_36),
        .NOP_38(NOP_38), .BR_39(BR_39),
        .JSRR_40(JSRR_40), .JSR_41(JSR_41),
        .ALU_CTL(ALU_CTL), .C(o_result));

endmodule
