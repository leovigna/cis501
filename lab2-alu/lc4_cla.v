/* TODO: INSERT NAME AND PENNKEY HERE */

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * @param a first 2-bit input
 * @param b second 2-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp2(input wire [1:0] gin, pin,
           input wire cin,
           output wire gout, pout, cout);
   assign gout = gin[1] | (gin[0] & pin[1]);
   assign pout = pin[0] & pin[1];
   assign cout = gout | (pout & cin);
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
   wire [1:0] g_1_0, p_1_0, g_3_2, p_3_2;
   wire cout_1, cout_2, cout_3;

   gp2 h0(
      .gin(gin[1:0]), 
      .pin(pin[1:0]), 
      .cin(cin), 
      .gout(g_1_0), 
      .pout(p_1_0), 
      .cout(cout_1)
   );
   gp2 h1(
      .gin(gin[3:2]), 
      .pin(pin[3:2]), 
      .cin(cout_1), 
      .gout(g_3_2), 
      .pout(p_3_2), 
      .cout(cout_2)
   );

   assign gout = g_3_2 | (g_1_0 & p_3_2);
   assign pout = p_1_0 & p_3_2;
   assign cout_3 = gout | (pout & cin);
   assign cout = {cout_1, cout_2, cout_3};
   
endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);

endmodule
