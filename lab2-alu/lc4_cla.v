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

   assign cout[0] = gin[0] | (pin[0] & cin);
   assign cout[1] = gin[1] | (pin[1] & cout[0]);
   assign cout[2] = gin[2] | (pin[2] & cout[1]);

   assign gout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
   assign pout = p[3] & p[2] & p[1] & p[0];
   
endmodule

/**
 * 4-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla4
  (input wire [3:0]  a, b,
   input wire cin,
   output wire [3:0] sum
   output wire cout);

   wire [3:0] gin, pin;
   wire [2:0] cout_tmp;
   wire gout, pout;

   gp1 g1(.a(a[0]), .b(b[0]), .g(gin[0]), .p(pin[0]));
   gp1 g2(.a(a[1]), .b(b[1]), .g(gin[1]), .p(pin[1]));
   gp1 g3(.a(a[2]), .b(b[2]), .g(gin[2]), .p(pin[2]));
   gp1 g4(.a(a[3]), .b(b[3]), .g(gin[3]), .p(pin[3]));

   gp4 g5(
      .gin(gin), 
      .pin(pin),
      .cin(cin),
      .gout(gout), 
      .pout(pout),
      .cout(cout_tmp)
   );

   assign sum[0] = (a[0] ^ b[0] ^ cin); // not sure about this
   assign sum[1] = (a[1] ^ b[1]) ^ cout_tmp[0];
   assign sum[2] = (a[2] ^ b[2]) ^ cout_tmp[1];
   assign sum[3] = (a[3] ^ b[3]) ^ cout_tmp[2];

   assign cout = gout | (pout & cin);

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

   wire cout_1, cout_2, cout_3, cout_4;

   cla4 c1(
      .a(a[3:0]),
      .b(b[3:0]),
      .cin(cin)
      .sum(sum[3:0]),
      .cout(cout_1)
   );

   cla4 c2(
      .a(a[7:4]),
      .b(b[7:4]),
      .cin(cout_1)
      .sum(sum[7:3]),
      .cout(cout_2)
   );

   cla4 c3(
      .a(a[11:8]),
      .b(b[11:8]),
      .cin(cout_2)
      .sum(sum[11:8]),
      .cout(cout_3)
   );

   cla4 c4(
      .a(a[15:12]),
      .b(b[15:12]),
      .cin(cout_3)
      .sum(sum[15:12]),
      .cout(cout_4)
   );

endmodule
