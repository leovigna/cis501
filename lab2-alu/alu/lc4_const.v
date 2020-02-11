module lc4_const(input  wire [15:0] A, B,
               output wire [15:0] CONST_32, HICONST_33);

    assign B_80 = B[8:0];
    assign B_70 = B[7:0];

    // TODO SEXT
    assign CONST_32 = $signed(B_80);
    assign HICONST_33 =  (B_70 << 8) | (A & 16'hFF);
    
endmodule
