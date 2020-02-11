
module lc4_alu_ctl(input  wire [15:0] i_insn
                  output wire [15:0] alu_ctl);

      case (i_insn[15:12]) 
            16'd0 : assign alu_ctl = 16'd32;
            16'd1 : begin
                  case (i_insn[5:3])
                        16'd0 : assign alu_ctl = 16'd0; // add
                        16'd1 : assign alu_ctl = 16'd1; // mul
                        16'd2 : assign alu_ctl = 16'd2; // sub
                        16'd3 : assign alu_ctl = 16'd3; // div
                        default : assign alu_ctl = 16'd6; // addi
                  endcase
                  end
            16'd2 : begin
                  case (i_insn[8:7])
                        16'd0 : assign alu_ctl = 16'd16; // cmp
                        16'd1 : assign alu_ctl = 16'd17; // cmpu
                        16'd2 : assign alu_ctl = 16'd18; // cmpi
                        16'd3 : assign alu_ctl = 16'd19; // cmpiu
                  endcase
                  end
            16'd4 : assign alu_ctl = 16'd6; 
            16'd5 : begin
                  case (i_insn[5:3])
                        16'd0 : assign alu_ctl = 16'd8; // add
                        16'd1 : assign alu_ctl = 16'd9; // not
                        16'd2 : assign alu_ctl = 16'd10; // or
                        16'd3 : assign alu_ctl = 16'd11; // xor
                        default : assign alu_ctl = 16'd12; // andi
                  endcase
                  end
            16'd6 : assign alu_ctl = 16'd6; 
            16'd7 : assign alu_ctl = 16'd6; 
            16'd8 : assign alu_ctl = 16'd36; 
            16'd9 : assign alu_ctl = 16'd32; 
            16'd10 : begin
                  case (i_insn[5:4])
                        16'd0 : assign alu_ctl = 16'd24; // sll
                        16'd1 : assign alu_ctl = 16'd25; // sra
                        16'd2 : assign alu_ctl = 16'd26; // srl
                        16'd3 : assign alu_ctl = 16'd4; // mod
                  endcase
                  end
            16'd12 : begin
                  case (i_insn[11])
                        16'd0 : assign alu_ctl = 16'd34; // jmpp
                        16'd1 : assign alu_ctl = 16'd34; // jmp
                  endcase
                  end
            16'd13 : assign alu_ctl = 16'd33;
      endcase

end module;
