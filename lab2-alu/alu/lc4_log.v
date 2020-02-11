module lc4_log(input  wire [15:0] A, B,
               output  wire [15:0] AND_8, NOT_9, OR_10, XOR_11, ANDIMM_12);

    wire [15:0] BIMM;

    // TODO SEXT
    assign BIMM = $signed(B[4:0]);

    assign AND_8 = A & B;
    assign NOT_9 = ~A;
    assign OR_10 = A | B;
    assign XOR_11 = A^B;
    assign ANDIMM_12 = A & BIMM;
    
endmodule
