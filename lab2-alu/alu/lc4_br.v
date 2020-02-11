module lc4_br(input  wire [15:0] i_insn, i_pc,
               output wire [15:0] NOP_38, BR_39);

    assign NOP_38 = i_pc + 1;
    assign BR_39 = i_pc + 1 + $signed({{8{i_insn[8]}}, i_insn[7:0]});


    
endmodule
