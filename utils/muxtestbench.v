`timescale 1ns / 1ps

`define NULL 0

`default_nettype wire

// Testbench
module muxtestbench;

  reg clk;
  integer i, j, k;

  reg [15:0]in1; //4 inputs
  reg [15:0]in2; //4 inputs
  reg [15:0]in3; //4 inputs
  reg [15:0]in4; //4 inputs
  reg in[3:0]; //4 inputs

  reg [1:0]sel1; //2bit selectors
  reg [1:0]sel2;
  reg [1:0]sel;

  wire [15:0]out1; //2 outputs
  wire [15:0]out2;
  wire [1:0]out;
    
  mux3_1 #(.Nbits(16)) MUX(.in1(in1), .in2(in2), .in3(in3), .selector(sel1), .out(out1));
          
  initial begin
    // Dump wavess
    $dumpfile("dump.vcd");
    $dumpvars(1);
    in1 = 16'hF000;
    in2 = 16'h0F00;
    in3 = 16'h00F0;
    in4 = 16'h000F;
    sel1 = 2'b00;
    sel2 = 2'b11;

    in[0] = in1;
    in[1] = in1;
    in[2] = in1;
    
    //mux#(.Nbits(16),.n(4),.m(2)) MUX(.in(in)), .selector(sel), .out(out));
    /*
    #1;
    for (i = 0; i < 4; i = i + 1) begin
      $display ("in[%0d] 0x%h", i, in[i]);
	end
    #2;
    for (i = 0; i < 2; i = i + 1) begin
      $display ("sel[%0d] 0x%h", i, sel[i]);
	end
   	#3;
    for (i = 0; i < 2; i = i + 1) begin
      $display ("out[%0d] 0x%h", i, out[i]);
	end
            //

    */
    
    end

endmodule