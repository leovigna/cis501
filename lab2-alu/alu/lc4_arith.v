`include "./lc4_divider.sv"

module lc4_arith(input wire [15:0] A,
               input wire [15:0]  B,
               input wire [15:0]  ALU_CTL,
               output wire [15:0]  ADD_0,
               output wire [15:0]  MUL_1,
               output wire [15:0]  SUB_2,
               output wire [15:0]  DIV_3,
               output wire [15:0]  MOD_4,
               output wire [15:0] ADDIMM_5,
               output wire [15:0] ADDIMM_6);


    assign MUL_1 = A * B;

    m lc4_divider(i_dividend: A, i_divisor: B, o_quotient: DIV_3, o_remainder: MOD_4); 


    wire in_carry;
    case(ALU_CTL) 
        16'd0 : assign in_carry = 0;
        16'd2 : assign in_carry = 1; // SUB
        16'd5 : assign in_carry = 0;
        16'd6 : assign in_carry = 0;
    endcase


endmodule
