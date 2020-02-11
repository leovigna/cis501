module lc4_const(input  wire [15:0] A, B,
               output wire [15:0] CONST_32, HICONST_33);

    assign CONST_32 = $signed({{8{B[8]}}, B[7:0]});
    assign HICONST_33 =  (A & 16'hFF) | (B[7:0] << 8);
    
endmodule
