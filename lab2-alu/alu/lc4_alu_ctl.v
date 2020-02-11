
module lc4_alu_ctl(input  wire [15:0] i_insn,
                  output wire [15:0] alu_ctl);

      reg [15:0] alu_out;
      
      always @ * begin
        case (i_insn[15:12]) 
            4'd0 : alu_out = 16'd32;
            4'd1 : begin
                  case (i_insn[5:3])
                        3'd0 : alu_out = 16'd0; // add
                        3'd1 : alu_out = 16'd1; // mul
                        3'd2 : alu_out = 16'd2; // sub
                        3'd3 : alu_out = 16'd3; // div
                        default : alu_out = 16'd5; // addi
                  endcase
                  end
            4'd2 : begin
                  case (i_insn[8:7])
                        2'd0 : alu_out = 16'd16; // cmp
                        2'd1 : alu_out = 16'd17; // cmpu
                        2'd2 : alu_out = 16'd18; // cmpi
                        2'd3 : alu_out = 16'd19; // cmpiu
                  endcase
                  end
            4'd4 : alu_out = 16'd6; 
            4'd5 : begin
                  case (i_insn[5:3])
                        3'd0 : alu_out = 16'd8; // add
                        3'd1 : alu_out = 16'd9; // not
                        3'd2 : alu_out = 16'd10; // or
                        3'd3 : alu_out = 16'd11; // xor
                        default : alu_out = 16'd12; // andi
                  endcase
                  end
            4'd6 : alu_out = 16'd6; 
            4'd7 : alu_out = 16'd6; 
            4'd8 : alu_out = 16'd36; 
            4'd9 : alu_out = 16'd32; 
            4'd10 : begin
                  case (i_insn[5:4])
                        2'd0 : alu_out = 16'd24; // sll
                        2'd1 : alu_out = 16'd25; // sra
                        2'd2 : alu_out = 16'd26; // srl
                        2'd3 : alu_out = 16'd4; // mod
                  endcase
                  end
            4'd12 : begin
                  case (i_insn[11])
                        1'd0 : alu_out = 16'd34; // jmpp
                        1'd1 : alu_out = 16'd35; // jmp
                  endcase
                  end
            4'd13 : alu_out = 16'd33;
            4'd15 : alu_out = 16'd37; // trap
        endcase
    end

    assign alu_ctl = alu_out;

endmodule