module lc4_log(input  wire [15:0] A,
               input wire [15:0] B,
               output  wire [15:0] AND_8,
               output wire [15:0] NOT_9,
               output wire [15:0] OR_10,
               output wire [15:0] XOR_11,
               output wire [15:0] ANDIMM_12);

    // TODO SEXT
    assign BIMM = $signed(B[4:0]);

    assign AND_8 = A & B;
    assign NOT_9 = ~A;
    assign OR_10 = A | B;
    assign XOR_11 = A^B;
    assign ANDIMM_12 = A & BIMM;
    
endmodule
