/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      wire [15:0] dividend_temp;
      wire [15:0] remainder_temp;
      wire [15:0] quotient_temp;
      
      lc4_divider_one_iter a0(
            .i_dividend(i_dividend), 
            .i_divisor(i_divisor), 
            .i_remainder(16'b0), 
            .i_quotient(16'b0), 
            .o_dividend(dividend_temp),
            .o_remainder(remainder_temp),
            .o_quotient(quotient_temp)
      );



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
      assign result = remainder_shift - i_divisor;

      // We know remainder partial is being selected
      // we know that remainder shift is being selected

      // calculate the remainder
      assign remainder_partial = (remainder_shift < i_divisor) ? remainder_shift : result;
      assign o_remainder = i_divisor == 16'b0 ? 16'b0 : remainder_partial;  

      // calculate the quotient
      assign quotient_partial = (i_quotient << 1) | (remainder_shift > i_divisor);
      assign o_quotient = i_divisor == 16'b0 ? 16'b0 : quotient_partial;
      
      // calculate the dividend
      assign o_dividend = i_dividend << 1;

endmodule
