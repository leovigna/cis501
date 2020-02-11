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
