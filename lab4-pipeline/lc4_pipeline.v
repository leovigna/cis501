/* 
    Leo Vigna: leovigna
    Nate Rush: narush
*/

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module nzp_unit(
   input wire [15:0] i_wdata,
   input wire nzp_we,
   input wire [2:0] prev_nzp,
   output wire [2:0] next_nzp);

   wire neg = i_wdata[15];
   wire zero = (i_wdata == 16'b0);
   wire pos = (!neg & !zero);

   assign next_nzp = nzp_we ? {neg, zero, pos} : prev_nzp;
endmodule


module memory_unit
  (input wire is_store, is_load, 
   input wire [15:0] o_alu, o_rt,
   output wire o_dmem_we, 
   output wire [15:0] o_dmem_addr, o_dmem_towrite);

   assign o_dmem_we = is_store;
   assign o_dmem_addr = (is_store | is_load) ? o_alu : 16'b0;
   assign o_dmem_towrite = is_store ? o_rt : 16'b0;
endmodule



module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
      
   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   //Nbit_reg #(16, 16'h8200) pc_reg (.in(c), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   // VARIABLE DECLARATIONS
   wire [15:0] f_insn, d_insn, x_insn, m_insn, w_insn; // Instructions
   wire [15:0] f_pc, d_pc, x_pc, m_pc, w_pc; // program counters
   wire [1:0]  f_stall, d_stall, x_stall, m_stall, w_stall; // all the stall counters
   wire                 d_nzp_we, x_nzp_we, m_nzp_we, w_nzp_we; // write enable
   wire [2:0]           d_r1sel, x_r1sel;
   wire                 d_r1re, x_r1re, m_r1re;
   wire [2:0]           d_r2sel, x_r2sel, m_r2sel;
   wire                 d_r2re, x_r2re, m_r2re;
   wire [2:0]           d_wsel, x_wsel, m_wsel, w_wsel;
   wire                 d_regfile_we, x_regfile_we, m_regfile_we, w_regfile_we;
   wire                 d_select_pc_plus_one, x_select_pc_plus_one, m_select_pc_plus_one, w_select_pc_plus_one;
   wire                 d_is_load, x_is_load, m_is_load, w_is_load;
   wire                 d_is_store, x_is_store, m_is_store, w_is_store;
   wire                 d_is_branch, x_is_branch;
   wire                 d_is_control_insn, x_is_control_insn;
   wire [15:0]          d_rs, x_rs;
   wire [15:0]          d_rt, x_rt, m_rt;
   wire [15:0]                x_alu, m_alu, w_alu;
   wire [15:0]                x_pc_plus_one, m_pc_plus_one, w_pc_plus_one;
   wire [2:0]                 x_nzp, m_nzp, w_nzp;
   wire [15:0]                x_wdata, m_wdata, w_wdata;



   /*************** FETCH STAGE ***************/
   // TODO: LEO, can you check this is correct!
   wire is_not_stall_from_load;
   assign is_not_stall_from_load = (x_is_load & (((d_r1sel == x_wsel & d_r1re) | (d_r2sel == x_wsel & d_r2re)) & !d_is_store)) ? 0 : 1; 
   // Load in the instructions, stall values, and pc
   assign f_insn = i_cur_insn;
   assign f_stall = is_not_stall_from_load ? 2'd0 : 2'd3;
   assign o_cur_pc = f_pc; 

   // Single PC register for the fetch stage
   Nbit_reg #(16, 16'h8200) f_pc_reg(.in(next_pc), .out(f_pc), .we(is_not_stall_from_load), .clk(clk), .gwe(gwe), .rst(rst));

   
   /*************** DECODE STAGE ***************/
   wire [15:0] d_insn_default;
   wire [15:0] d_rs_default, d_rt_default;

   assign d_insn_default = (next_pc == x_pc_plus_one) ? i_cur_insn : 16'b0;
   
   // decode registers
   Nbit_reg #(16, 16'b0) d_insn_reg(.in(d_insn_default), .out(d_insn), .we(is_not_stall_from_load), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) D_pc(.in(f_pc), .out(d_pc), .we(is_not_stall_from_load), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2)   d_stall_reg(.in(f_stall), .out(d_stall), .we(is_not_stall_from_load), .clk(clk), .gwe(gwe), .rst(rst));

   // Bypassing from WD   
   wire wd_bypass_rs, wd_bypass_rt;
   assign wd_bypass_rs = (w_wsel == d_r1sel) && w_regfile_we;
   assign wd_bypass_rt = (w_wsel == d_r2sel) && w_regfile_we;
   assign d_rs = wd_bypass_rs ? w_wdata : d_rs_default;
   assign d_rt = wd_bypass_rt ? w_wdata : d_rt_default;

   // Decode the instruction
   lc4_decoder d(
      .insn(d_insn),
      .r1re(d_r1re),
      .r1sel(d_r1sel),
      .r2re(d_r2re),
      .r2sel(d_r2sel),
      .wsel(d_wsel),
      .regfile_we(d_regfile_we),
      .nzp_we(d_nzp_we),
      .select_pc_plus_one(d_select_pc_plus_one),
      .is_load(d_is_load),
      .is_store(d_is_store),
      .is_branch(d_is_branch),
      .is_control_insn(d_is_control_insn)
   );
   
   // read the registers
   lc4_regfile r(
      .clk(clk),
      .gwe(gwe),
      .rst(rst),
      .i_rs(d_r1sel),      // rs selector
      .o_rs_data(d_rs_default), // rs contents
      .i_rt(d_r2sel),      // rt selector
      .o_rt_data(d_rt_default), // rt contents
      .i_rd(w_wsel),      // rd selector (Write phase)
      .i_wdata(w_wdata),   // data to write (Write phase)
      .i_rd_we(w_regfile_we)  
   );


   /*************** EXECUTE STAGE ***************/

   // TODO: change to x!
   wire [15:0] x_insn_default;
   wire [1:0]  x_stall_default;

   // Check if it's a stall from load
   assign x_stall_default = is_not_stall_from_load ? d_stall : 2'd3;
   assign x_insn_default = (is_not_stall_from_load | next_pc == x_pc_plus_one) ? d_insn : 16'b0;

   // Registers for execute stage
   Nbit_reg #(16, 16'h8200) x_pc_reg(.in(d_pc), .out(x_pc), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2) x_stall_reg(.in(x_stall_default), .out(x_stall), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_rs_data_reg(.in(d_rs), .out(x_rs), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_rt_data_reg(.in(d_rt), .out(x_rt), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   // including registers for all decoded signals
   Nbit_reg #(16, 16'b0) x_insn_reg(.in(x_insn_default), .out(x_insn), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) x_r1sel_reg(.in(d_r1sel), .out(x_r1sel), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) x_r2sel_reg(.in(d_r2sel), .out(x_r2sel), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) x_wsel_reg(.in(d_wsel), .out(x_wsel), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_regfile_we_reg(.in(d_regfile_we), .out(x_regfile_we), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_nzp_we_reg(.in(d_nzp_we), .out(x_nzp_we), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_select_pc_plus_one_reg(.in(d_select_pc_plus_one), .out(x_select_pc_plus_one), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));                      
   Nbit_reg #(1, 1'b0) x_is_load_reg(.in(d_is_load), .out(x_is_load), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_is_store_reg(.in(d_is_store), .out(x_is_store), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_is_branch_reg(.in(d_is_branch), .out(x_is_branch), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_is_control_insn_reg(.in(d_is_control_insn), .out(x_is_control_insn), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));

   // Bypasses
   wire mx_bypass_rs, mx_bypass_rt, wx_bypass_rs, wx_bypass_rt;

   // TODO: LEO: can you check these conditions
   assign wx_bypass_rs = (x_r1sel == w_wsel && w_regfile_we) ? w_wdata : x_rs;
   assign wx_bypass_rt = (x_r2sel == w_wsel && w_regfile_we) ? w_wdata : x_rt;

   assign mx_bypass_rs = (x_r1sel == m_wsel && m_regfile_we) ? m_alu : wx_bypass_rs;
   assign mx_bypass_rt = (x_r2sel == m_wsel && m_regfile_we) ? m_alu : wx_bypass_rt;

   // Increment PC
   cla16 c(.a(f_pc), .b(16'b0), .cin(1'b1), .sum(x_pc_plus_one));

   // Connect the ALU
   lc4_alu alu(
      .i_insn(x_insn), 
      .i_pc(x_pc), 
      .i_r1data(mx_bypass_rs), 
      .i_r2data(mx_bypass_rt), 
      .o_result(x_alu)
   );

   // TODO: in the future when there are branching instructions, we have to branch!
   assign next_pc = x_pc_plus_one;

   assign x_wdata = x_is_load ? i_cur_dmem_data : (x_select_pc_plus_one ? x_pc_plus_one : x_alu);
   // TODO: might have to case on the fact that it's a load
   nzp_unit n(
      .i_wdata(x_wdata),
      .nzp_we(x_nzp_we),
      .prev_nzp(w_nzp),
      .next_nzp(x_nzp)
   );
 
   /*************** MEMORY STAGE ***************/

   // Registers for the memory stage
   Nbit_reg #(16, 16'b0) m_pc_reg(.in(x_pc), .out(m_pc), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2) m_stall_reg(.in(x_stall), .out(m_stall), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) m_alu_output_reg(.in(x_alu), .out(m_alu), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) m_nzp_reg(.in(x_nzp), .out(m_nzp), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) m_pc_plus_one_reg(.in(x_pc_plus_one), .out(m_pc_plus_one), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16)      m_rt_data_reg(.in(x_rt), .out(m_rt), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   // Included decoded signals
   Nbit_reg #(16, 16'b0) m_insn_reg(.in(x_insn), .out(m_insn), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) m_r2sel_reg(.in(x_r2sel), .out(m_r2sel), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(3, 3'b0) m_wsel_reg(.in(x_wsel), .out(m_wsel), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_regfile_we_reg(.in(x_regfile_we), .out(m_regfile_we), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_nzp_we_reg(.in(x_nzp_we), .out(m_nzp_we), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_select_pc_plus_one_reg(.in(x_select_pc_plus_one), .out(m_select_pc_plus_one), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(1)       m_is_load_reg(.in(x_is_load), .out(m_is_load), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_is_store_reg(.in(x_is_store), .out(m_is_store), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));                     


   // Bypassing
   wire wm_bypass_rt;
   wire [15: 0] wm_rt;
   assign wm_bypass_rt = w_regfile_we && (m_is_store && m_r2sel == w_wsel); //Load, Store
   assign wm_rt = wm_bypass_rt ? w_wdata : m_rt;

   // Set output signals
   memory_unit mem_unit(
      .is_store(m_is_store), 
      .is_load(m_is_load), 
      .o_alu(m_alu), 
      .o_rt(wm_rt), 
      .o_dmem_we(o_dmem_we), 
      .o_dmem_addr(o_dmem_addr), 
      .o_dmem_towrite(o_dmem_towrite)
   );

   /*************** WRITEBACK STAGE ***************/

   wire w_dmem_we;
   wire [15:0] w_dmem_towrite, w_dmem_addr, w_cur_dmem_data;

   // Registers for the writeback stage
   Nbit_reg #(16, 16'b0) w_pc_reg(.in(m_pc), .out(w_pc), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_alu_output_reg(.in(m_alu), .out(w_alu), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2) w_stall_reg(.in(m_stall), .out(w_stall), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));

   Nbit_reg #(16, 16'b0) w_insn_reg(.in(m_insn), .out(w_insn), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_pc_plus_one_reg(.in(m_pc_plus_one), .out(w_pc_plus_one), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) w_wsel_reg(.in(m_wsel), .out(w_wsel), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_regfile_we_reg(.in(m_regfile_we), .out(w_regfile_we), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_nzp_we_reg(.in(m_nzp_we), .out(w_nzp_we), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_select_pc_plus_one_reg(.in(m_select_pc_plus_one), .out(w_select_pc_plus_one), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(1, 1'b0) w_is_load_reg(.in(m_is_load), .out(w_is_load), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_is_store_reg(.in(m_is_store), .out(w_is_store), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));                     
   Nbit_reg #(3, 3'b0) w_nzp_reg(.in(m_nzp), .out(w_nzp), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_dmem_towrite_reg(.in(o_dmem_towrite), .out(w_dmem_towrite), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_dmem_addr_reg(.in(o_dmem_addr), .out(w_dmem_addr), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 16'b0) w_dmem_we_reg(.in(o_dmem_we), .out(w_dmem_we), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_cur_dmem_data_reg(.in(i_cur_dmem_data), .out(w_cur_dmem_data), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));

   assign w_wdata = w_is_load ? w_cur_dmem_data :(w_select_pc_plus_one ? w_pc_plus_one : w_alu);

   // TESTBENCH SIGNALS

   assign test_cur_pc = w_pc;
   assign test_cur_insn = w_insn;
   assign test_regfile_we = w_regfile_we;
   assign test_regfile_wsel = w_wsel;
   assign test_regfile_data = w_regfile_we ? w_wdata : 16'b0;
   assign test_nzp_we = w_nzp_we;
   assign test_nzp_new_bits = w_nzp;
   assign test_dmem_we = w_dmem_we;
   assign test_dmem_addr = w_dmem_addr;
   assign test_dmem_data = w_is_store ? w_dmem_towrite : (w_is_load ? w_cur_dmem_data : 16'b0);
   assign test_stall = w_stall;


   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      $display("%d PC: %h, Instruction: %h", $time, o_cur_pc, i_cur_insn);
      $display("%d Instructions: %h, %h, %h, %h, %h", $time, f_insn, d_insn, x_insn, m_insn, w_insn);
      $display("%d PCs: %h, %h, %h, %h, %h", $time, f_pc, d_pc, x_pc, m_pc, w_pc);
      $display("%d Stalls: %h, %h, %h, %h, %h", $time, f_stall, d_stall, x_stall, m_stall, w_stall);
      $display("%d regfile we: __, %h, %h, %h, %h", $time, d_regfile_we, x_regfile_we, m_regfile_we, w_regfile_we);
      $display("%d regfile_reg: __, %h, %h, %h, %h", $time, d_wsel, x_wsel, m_wsel, w_wsel);
      $display("%d nzp: __, __, __, %h, %h, %h", $time, x_nzp, m_nzp, w_nzp);
      $display("%d select PC plus 1: __, %h, %h, %h, %h", $time, d_select_pc_plus_one, x_select_pc_plus_one, m_select_pc_plus_one, w_select_pc_plus_one);
      $display("%d alu: __, __, %h, %h, %h", $time, x_alu, m_alu, w_alu);
      $display("%d is not stall from load: %h", $time, is_not_stall_from_load);
      $display("%d ALU Inputs: %h %h %h %h", $time, x_insn, x_pc, mx_bypass_rs, mx_bypass_rt);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display(); 
   end
`endif
endmodule
