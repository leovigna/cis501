module lc4_shift(input  wire [15:0] A, B,
               output wire [15:0] SLL_24, SRA_25, SRL_26);

    wire [3:0] B_30;

    assign B_30 = B[3:0];
    assign SLL_24 = A << B_30;
    assign SRA_25 = A >>> B_30;
    assign SRL_26 = A >> B_30;

endmodule
