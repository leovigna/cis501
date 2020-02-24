module mux #(parameter Nbits = 16, parameter n = 2, parameter m = 1)(
    input wire [Nbits-1:0] in [n - 1:0],
    input wire [$clog2(n) - 1:0] selector [m - 1:0], 
    input wire [Nbits-1:0] out [m - 1:0]);

    assign out[0] = in[selector[0]];

    genvar i;
  	generate
    for (i = 0; i < m; i++) begin
        assign out[i] = in[selector[i]];
	end
    endgenerate
endmodule