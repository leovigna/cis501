/* Leo Vigna leovigna
   Nate Rush narush
 */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      // Loop vars
      genvar j;
      wire [15:0]dividend[16:0];
      wire [15:0]remainder[16:0];
      wire [15:0]quotient[16:0];
      assign dividend[0] = i_dividend;
      assign remainder[0] = 16'b0;
      assign quotient[0] = 16'b0;
      // Generate
      generate
        for(j = 0; j < 16; j = j+1) begin
            lc4_divider_one_iter a(
            .i_dividend(dividend[j]), 
            .i_divisor(i_divisor), // Divisor no change
            .i_remainder(remainder[j]), 
            .i_quotient(quotient[j]), 
            .o_dividend(dividend[j+1]),
            .o_remainder(remainder[j+1]),
            .o_quotient(quotient[j+1])
      ); 
        end
      endgenerate

      assign o_remainder = remainder[16];
      assign o_quotient = quotient[16];
endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      // define intermediate variables
      wire [15:0] remainder_shift;
      wire [15:0] result;
      wire [15:0] quotient_partial;
      wire [15:0] remainder_partial;

      // intermediate results
      assign remainder_shift = (i_remainder << 1) | (i_dividend[15]);
      // We know remainder partial is being selected
      // we know that remainder shift is being selected
 
      // calculate the remainder
      assign remainder_partial = (remainder_shift < i_divisor) ? remainder_shift : (remainder_shift - i_divisor);
      assign o_remainder = (i_divisor == 16'b0) ? 16'b0 : remainder_partial;  

      // calculate the quotient
      assign quotient_partial = (i_quotient << 1) | (remainder_shift >= i_divisor);
      assign o_quotient = (i_divisor == 16'b0) ? 16'b0 : quotient_partial;
      
      // calculate the dividend
      assign o_dividend = i_dividend << 1;

endmodule
