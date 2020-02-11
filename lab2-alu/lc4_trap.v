module lc4_trap(input  wire [15:0] i_insn,
               output wire [15:0] TRAP_37);

    assign TRAP_37 = (16'h8000 | {8'b0, i_insn[7:0]});

endmodule
