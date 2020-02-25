/*
    Leo Vigna: leovigna
    Nate Rush: narush
*/

`timescale 1ns / 1ps

`default_nettype wire
 
module mux #(parameter Nbits = 16, parameter n = 2, parameter m = 1)(
    input wire [Nbits-1:0][n - 1:0]in,
    input wire [$clog2(n) - 1:0][m - 1:0]selector, 
    input wire [Nbits-1:0][m - 1:0]out);

    genvar i;
  	generate
    for (i = 0; i < m; i = i + 1) begin
        assign out[i] = in[selector[i]];
	end
    endgenerate
endmodule

module mux3_1 #(parameter Nbits = 16)(
    input wire [Nbits-1:0] in1,
    input wire [Nbits-1:0] in2,
    input wire [Nbits-1:0] in3,
    input wire [1:0]selector, 
    input wire [Nbits-1:0]out);

    wire [3:0][Nbits-1]in;
    assign in[0] = in1;
    assign in[1] = in2;
    assign in[2] = in3;

    assign out[0] = in[selector[0]];
endmodule