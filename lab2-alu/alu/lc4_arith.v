`include "./lc4_divider.v"
`include "../lc4_cla.v"

module lc4_arith(input wire [15:0] A, B, ALU_CTL,
               output wire [15:0]  ADD_0, MUL_1, SUB_2, DIV_3, MOD_4, ADDIMM_5, ADDIMM_6);


    assign MUL_1 = A * B;

    lc4_divider m1(.i_dividend(A), .i_divisor(B), .o_quotient(DIV_3), .o_remainder(MOD_4)); 
    
    wire in_carry;
    reg in_carry_reg;
    always @ (*) begin
        case(ALU_CTL) 
            16'd0 : in_carry_reg = 0;
            16'd2 : in_carry_reg = 1; // SUB
            16'd5 : in_carry_reg = 0;
            16'd6 : in_carry_reg = 0;
        endcase
    end

    wire [15:0] in_B;
    reg [15:0] in_B_reg;

    always @ (*) begin
        case(ALU_CTL) 
            16'd0 : begin
                in_carry_reg = 0;
                in_B_reg = B; // ADD
                end
            16'd2 : begin
                in_carry_reg = 1; 
                in_B_reg = ~B; // SUB
                end 
            16'd5 : begin
                in_carry_reg = 0; 
                in_B_reg = $signed(B[4:0]); // ADDIMM_5
                end
            16'd6 : begin
                in_carry_reg = 0; 
                in_B_reg = $signed(B[5:0]); // ADDIMM_6
                end
        endcase
    end

    assign in_B = in_B_reg;
    assign in_carry = in_carry_reg;

    wire [15:0] sum_out;
    cla16 m2(.a(A), .b(B), .cin(in_carry), .sum(sum_out));

    // Same output
    assign ADD_0 = sum_out;
    assign SUB_2 = sum_out;
    assign ADDIMM_5 = sum_out;
    assign ADDIMM_6 = sum_out;

endmodule
