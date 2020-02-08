module lc4_cmp(input  wire [15:0] A,
               input wire [15:0] B,
               output wire [15:0] CMP_16,
               output wire [15:0] CMPU_17,
               output wire [15:0] CMPI_18,
               output wire [15:0] CMPUI_19);

    wire CMPU_sel[3:0];
    wire signedA = $signed(A);
    wire signedB = $signed(B);

    wire BIMM = B[6:0];
    wire signedBIMM = $signed(B[6:0]);

    //Concatenate comparison results
    assign CMP_sel = { signedA > signedB, signedA == signedB, signedA < signedB };
    assign CMPU_sel = { A > B, A == B, A < B }; 
    assign CMPI_sel = { signedA > signedBIMM, signedA == signedBIMM, signedA < signedBIMM };
    assign CMPUI_sel = { A > BIMM, A == BIMM, A < BIMM };

    case(CMP_sel) 
        3'b100 : assign CMP_16 = 1;
        3'b010 : assign CMP_16 = 0;
        3'b001 : assign CMP_16 = -1;
    endcase

    case(CMPU_sel) 
        3'b100 : assign CMPU_17 = 1;
        3'b010 : assign CMPU_17 = 0;
        3'b001 : assign CMPU_17 = -1;
    endcase

    case(CMPI_sel) 
        3'b100 : assign CMPI_18 = 1;
        3'b010 : assign CMPI_18 = 0;
        3'b001 : assign CMPI_18 = -1;
    endcase

    case(CMPUI_sel) 
        3'b100 : assign CMPUI_19 = 1;
        3'b010 : assign CMPUI_19 = 0;
        3'b001 : assign CMPUI_19 = -1;
    endcase

endmodule
