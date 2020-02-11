module lc4_jmp(input  wire [15:0] A, B, i_pc,
               output wire [15:0] JMPP_34, JMP_35);

    wire [15:0] UIMM11;
    assign UIMM11 = $signed({{6{B[10]}}, B[9:0]});

    assign JMPP_34 = A;
    assign JMP_35 = i_pc + 16'd1 + UIMM11;

endmodule
