/* 
    Leo Vigna: leovigna
    Nate Rush: <INSERT HERE>
*/

`timescale 1ns / 1ps

`default_nettype none

`include "./alu/lc4_alu_ctl.v"
`include "./alu/lc4_alu_out.v"
`include "./alu/lc4_arith.v"
`include "./alu/lc4_cmp.v"
`include "./alu/lc4_const.v"
`include "./alu/lc4_log.v"
`include "./alu/lc4_shift.v"
`include "./alu/lc4_trap.v"


module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/
    wire [15:0] ADD_0, MUL_1, SUB_2, DIV_3, MOD_4, ADDIMM_5, ADDIMM_6, AND_8, NOT_9, OR_10, XOR_11, ANDIMM_12, CMP_16, CMPU_17, CMPI_18, CMPIU_19, SLL_24, SRA_25, SRL_26, CONST_32, HICONST_33, TRAP_37, ALU_CTL;
    
    lc4_alu_ctl m1(.i_insn(i_insn), .alu_ctl(ALU_CTL));

    lc4_arith m2(.A(i_r1data), .B(i_r2data), .ALU_CTL(ALU_CTL), .i_insn(i_insn), .ADD_0(ADD_0), .MUL_1(MUL_1), .SUB_2(SUB_2), .DIV_3(DIV_3), .MOD_4(MOD_4), .ADDIMM_5(ADDIMM_5), .ADDIMM_6(ADDIMM_6));
    lc4_cmp m3(.A(i_r1data), .B(i_r2data), .i_insn(i_insn), .CMP_16(CMP_16), .CMPU_17(CMPU_17), .CMPI_18(CMPI_18), .CMPIU_19(CMPIU_19));
    lc4_const m4(.A(i_r1data), .B(i_r2data), .CONST_32(CONST_32), .HICONST_33(HICONST_33));
    lc4_log m5(.A(i_r1data), .B(i_r2data), .i_insn(i_insn), .AND_8(AND_8), .NOT_9(NOT_9), .OR_10(OR_10), .XOR_11(XOR_11), .ANDIMM_12(ANDIMM_12));
    lc4_shift m6(.A(i_r1data), .B({12'd0, i_insn[3:0]}), .SLL_24(SLL_24), .SRA_25(SRA_25), .SRL_26(SRL_26));
    lc4_trap m7(.i_insn(i_insn), .TRAP_37(TRAP_37));

    lc4_alu_out m8(.ADD_0(ADD_0), .MUL_1(MUL_1), .SUB_2(SUB_2), .DIV_3(DIV_3), 
        .MOD_4(MOD_4), .ADDIMM_5(ADDIMM_5), .ADDIMM_6(ADDIMM_6), 
        .CMP_16(CMP_16), .CMPU_17(CMPU_17), .CMPI_18(CMPI_18), .CMPIU_19(CMPIU_19), 
        .CONST_32(CONST_32), .HICONST_33(HICONST_33), 
        .AND_8(AND_8), .NOT_9(NOT_9), .OR_10(OR_10), .XOR_11(XOR_11), .ANDIMM_12(ANDIMM_12), 
        .SLL_24(SLL_24), .SRA_25(SRA_25), .SRL_26(SRL_26),
        .TRAP_37(TRAP_37),
        .ALU_CTL(ALU_CTL), .C(o_result));

endmodule
