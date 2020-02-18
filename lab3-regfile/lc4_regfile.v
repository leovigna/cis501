/* TODO: Names of all group members
 * TODO: PennKeys of all group members
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`include "./register.v"

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );

    // make 8 output wires; one for each reg
    wire [n-1:0] regs [7:0];

    genvar i;
    for (i = 0; i < 8; i = i + 1) begin
        Nbit_reg #(n) r(
            .in(i_wdata),
            .out(regs[i]),
            .clk(clk),
            .we(i_rd_we & (i == i_rd)),
            .gwe(gwe),
            .rst(rst)
        );
    end

    assign o_rs_data = regs[i_rs];
    assign o_rt_data = regs[i_rt];

endmodule
