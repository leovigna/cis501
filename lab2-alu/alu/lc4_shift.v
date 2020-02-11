module lc4_shift(input  wire [15:0] A, B,
               output wire [15:0] SLL_24, SRA_25, SRL_26);

    assign B_30 = B[3:0];
    assign SLL_24 = A << B_30;
    assign SLL_25 = A >>> B_30;
    assign SLL_26 = A >> B_30;

endmodule
