`include "./lc4_divider.sv"
`include "../lc4_cla.sv"

module lc4_arith(input wire [15:0] A, B, ALU_CTL,
               output wire [15:0]  ADD_0, MUL_1, SUB_2, DIV_3, MOD_4, ADDIMM_5, ADDIMM_6);


    assign MUL_1 = A * B;

    lc4_divider m1(.i_dividend(A), .i_divisor(B), .o_quotient:(DIV_3), .o_remainder(MOD_4)); 
    

    wire in_carry;
    case(ALU_CTL) 
        16'd0 : assign in_carry = 0;
        16'd2 : assign in_carry = 1; // SUB
        16'd5 : assign in_carry = 0;
        16'd6 : assign in_carry = 0;
    endcase

    wire in_B[15:0];
    case(ALU_CTL) 
        16'd0 : assign in_carry = 0; assign in_B = B; // ADD
        16'd2 : assign in_carry = 1; assign in_B = ~B; // SUB
        16'd5 : assign in_carry = 0; assign in_B = $signed(B[4:0]); // ADDIMM_5
        16'd6 : assign in_carry = 0; assign in_B = $signed(B[5:0]); // ADDIMM_6
    endcase

    wire sum_out[15:0];
    cla16 m2(.a(A), .b(B), .cin(in_carry), .sum(sum_out));

    // Same output
    assign ADD_0 = sum_out;
    assign SUB_2 = sum_out;
    assign ADDIMM_5 = sum_out;
    assign ADDIMM_6 = sum_out;

endmodule
