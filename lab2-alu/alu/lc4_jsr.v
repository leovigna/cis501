module lc4_jsr(input  wire [15:0] A, i_insn, i_pc,
               output wire [15:0] JSRR_40, JSR_41);

    assign JSRR_40 = A;
    assign JSR_41 = (i_pc & 16'h8000) | ((i_insn[10:0]) << 4);

endmodule
