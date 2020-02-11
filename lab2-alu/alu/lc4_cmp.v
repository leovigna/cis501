module lc4_cmp(input  wire [15:0] A, B, i_insn,
               output wire [15:0] CMP_16, CMPU_17, CMPI_18, CMPIU_19);

    wire [3:0] CMP_sel, CMPU_sel, CMPI_sel, CMPIU_sel;
    wire [15:0] signedA, signedB, BIMM, signedBIMM;
    
    assign signedA = $signed(A);
    assign signedB = $signed(B);
    assign BIMM = {9'b0, i_insn[6:0]};
    assign signedBIMM  = $signed({{10{i_insn[6]}}, i_insn[5:0]});

    //Concatenate comparison results
    assign CMP_sel = { signedA > signedB, signedA == signedB, signedA < signedB };
    assign CMPU_sel = { A > B, A == B, A < B }; 
    assign CMPI_sel = { signedA > signedBIMM, signedA == signedBIMM, signedA < signedBIMM };
    assign CMPIU_sel = { A > BIMM, A == BIMM, A < BIMM };

    reg [15:0] CMP_16_reg, CMPU_17_reg, CMPI_18_reg, CMPIU_19_reg;

    always @ (CMP_sel) begin
        case(CMP_sel) 
            3'b100 : CMP_16_reg = 16'd1;
            3'b010 : CMP_16_reg = 16'd0;
            3'b001 : CMP_16_reg = -16'd1;
        endcase
    end

    always @ (CMPU_sel) begin
        case(CMPU_sel) 
            3'b100 : CMPU_17_reg = 16'd1;
            3'b010 : CMPU_17_reg = 16'd0;
            3'b001 : CMPU_17_reg = -16'd1;
        endcase
    end

    always @ (CMPI_sel) begin
        case(CMPI_sel) 
            3'b100 : CMPI_18_reg = 16'd1;
            3'b010 : CMPI_18_reg = 16'd0;
            3'b001 : CMPI_18_reg = -16'd1;
        endcase
    end

    //{ A > BIMM, A == BIMM, A < BIMM }
    always @ (CMPIU_sel) begin
        case(CMPIU_sel) 
            3'b100 : CMPIU_19_reg = B;
            3'b010 : CMPIU_19_reg = 16'd0;
            3'b001 : CMPIU_19_reg = -16'd1;
        endcase
    end

    assign CMP_16 = CMP_16_reg;
    assign CMPU_17 = CMPU_17_reg;
    assign CMPI_18 = CMPI_18_reg;
    assign CMPIU_19 = CMPIU_19_reg;

endmodule
