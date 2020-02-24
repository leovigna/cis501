// Testbench
module test;

  reg clk;

  reg [15:0]in[3:0]; //4 inputs
  reg [1:0]sel[1:0]; //2 2bit selectors
  wire [15:0]out[1:0]; //2 outputs
  
  // Instantiate design under test
  mux#(.Nbits(16),.n(4),.m(2)) MUX(.in(in), .selector(sel), .out(out));
          
  initial begin
    // Dump wavess
    $dumpfile("dump.vcd");
    $dumpvars(1);
    in[0] <= 16'hF000;
    in[1] <= 16'h0F00;
    in[2] <= 16'h00F0;
    in[3] <= 16'h000F;
    sel[0] <= 2'b00;
    sel[1] <= 2'b11;
    
    display;
  end
  
  task display;
    #1
    for (int i = 0; i < $size(in); i++) begin
      $display ("in[%0d] 0x%h", i, in[i]);
	end
    #2
    for (int i = 0; i < $size(sel); i++) begin
      $display ("sel[%0d] 0x%h", i, sel[i]);
	end
   	#3
    for (int i = 0; i < $size(out); i++) begin
      $display ("out[%0d] 0x%h", i, out[i]);
	end
  endtask

endmodule