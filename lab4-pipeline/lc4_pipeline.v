/* 
    Leo Vigna: leovigna
    Nate Rush: narush
*/

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module nzp_unit(
   input wire [15:0] i_wdata,
   output wire [2:0] next_nzp);

   wire neg = i_wdata[15];
   wire zero = (i_wdata == 16'b0);
   wire pos = (!neg & !zero);

   assign next_nzp = {neg, zero, pos};
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

module insn_pipeline
    (
    input  wire [15:0] in_insn, in_pc, in_dmem_data, in_rs, in_rt, in_alu, in_wdata, in_jmp_tgt, in_next_pc,
    input  wire [2:0] in_r1sel, in_r2sel, in_wsel, in_nzp,
    input wire in_nzp_result,
    input  wire in_r1re, in_r2re, in_regfile_we, in_nzp_we, in_select_pc_plus_one, in_is_load, in_is_store, in_is_branch, in_is_control_insn,
    input wire in_dmem_we,
    input wire  [15:0] in_dmem_addr, in_dmem_towrite,
    input wire [2:0] in_stall,
    output  wire [15:0] out_insn, out_pc, out_dmem_data, out_rs, out_rt, out_alu, out_wdata, out_jmp_tgt, out_next_pc,
    output  wire [2:0] out_r1sel, out_r2sel, out_wsel, out_nzp,
    output wire out_nzp_result,
    output  wire out_r1re, out_r2re, out_regfile_we, out_nzp_we, out_select_pc_plus_one, out_is_load, out_is_store, out_is_branch, out_is_control_insn,
    output wire out_dmem_we,
    output wire [15:0] out_dmem_addr, out_dmem_towrite,
    output wire [2:0] out_stall,
    input  wire         clk,
    input  wire         we,
    input  wire         gwe,
    input  wire         rst
    );

   Nbit_reg #(16, 16'h0000) insn_reg (.in(in_insn), .out(out_insn), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) pc_reg (.in(in_pc), .out(out_pc), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) dmem_data_reg (.in(in_dmem_data), .out(out_dmem_data), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) rt_reg (.in(in_rs), .out(out_rs), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) rs_reg (.in(in_rt), .out(out_rt), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) alu_reg (.in(in_alu), .out(out_alu), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) wdata_reg (.in(in_wdata), .out(out_wdata), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) jmp_tgt_reg (.in(in_jmp_tgt), .out(out_jmp_tgt), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) next_pc_reg (.in(in_next_pc), .out(out_next_pc), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) dmem_addr_reg (.in(in_dmem_addr), .out(out_dmem_addr), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) dmem_towrite_reg (.in(in_dmem_towrite), .out(out_dmem_towrite), .clk(clk), .we(we), .gwe(gwe), .rst(rst));


   Nbit_reg #(3, 0) r1sel_reg (.in(in_r1sel), .out(out_r1sel), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r2sel_reg (.in(in_r2sel), .out(out_r2sel), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) wsel_reg (.in(in_wsel), .out(out_wsel), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) nzp_reg (.in(in_nzp), .out(out_nzp), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg nzp_result_reg (.in(in_nzp_result), .out(out_nzp_result), .clk(clk), .we(we), .gwe(gwe), .rst(rst));

   Nbit_reg r1re_reg (.in(in_r1re), .out(out_r1re), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg r2re_reg (.in(in_r2re), .out(out_r2re), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg regfile_we_reg (.in(in_regfile_we), .out(out_regfile_we), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   
   Nbit_reg nzp_we_reg (.in(in_nzp_we), .out(out_nzp_we), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg select_pc_plus_one_reg (.in(in_select_pc_plus_one), .out(out_select_pc_plus_one), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg is_load_reg (.in(in_is_load), .out(out_is_load), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg is_store_reg (.in(in_is_store), .out(out_is_store), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg is_branch_reg (.in(in_is_branch), .out(out_is_branch), .clk(clk), .we(we), .gwe(gwe), .rst(rst));
   Nbit_reg is_control_insn_reg (.in(in_is_control_insn), .out(out_is_control_insn), .clk(clk), .we(we), .gwe(gwe), .rst(rst));

   Nbit_reg dmem_we_reg (.in(in_dmem_we), .out(out_dmem_we), .clk(clk), .we(we), .gwe(gwe), .rst(rst));

   Nbit_reg #(2, 0) stall_reg (.in(in_stall), .out(out_stall), .clk(clk), .we(we), .gwe(gwe), .rst(rst));


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
   

/*************** FETCH ***************/
   // F: Fetch Stage
   wire [15:0] f_insn, f_pc, f_dmem_data;
   wire [2:0] f_nzp;
   //Test Signals
   assign o_cur_pc = f_pc; 

   insn_pipeline Input_F_pipeline( 
       .in_insn(i_cur_insn), .in_pc(w_next_pc), .in_dmem_data(i_cur_dmem_data),
       .in_nzp(w_next_nzp),
       .out_insn(f_insn), .out_pc(f_pc), .out_dmem_data(f_dmem_data),
       .out_nzp(f_nzp),
       .we(1'b1), .gwe(gwe), .rst(rst));

/*************** DECODE ***************/
   // Parse the instruction
   // D: Decode Stage
   // Previous stages
   wire [15:0] d_insn, d_pc, d_dmem_data;
   wire [2:0] d_nzp;
   
   // Computed in D
   wire [2:0] d_r1sel, d_r2sel, d_wsel;
   wire d_r1re, d_r2re, d_regfile_we, d_nzp_we, d_select_pc_plus_one, d_is_load, d_is_store, d_is_branch, d_is_control_insn;
   wire [15:0] d_rs, d_rt;
   wire [15:0] d_rs_default, d_rt_default;

   // Load Pipeline data
   insn_pipeline FD_pipeline( 
       .in_insn(f_insn), .in_pc(f_pc), .in_dmem_data(f_dmem_data), .in_nzp(f_nzp),
       .out_insn(d_insn), .out_pc(d_pc), .out_dmem_data(d_dmem_data), .out_nzp(d_nzp),
       .we(1'b1), .gwe(gwe), .rst(rst));

   //Bypassing
   // TODO: Test
   wire wd_bypass;
   assign wd_bypass_rs = (w_wsel == d_r1sel);
   assign wd_bypass_rt = (w_wsel == d_r2sel);
   assign d_rs = wd_bypass_rs ? w_rs : d_rs_default;
   assign d_rt = wd_bypass_rt ? w_rt : d_rt_default;
   
   // Compute
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


/*************** EXECUTE ***************/
   // X: Execute Stage
   // Previous stages
   wire [15:0] x_insn, x_pc, x_dmem_data;
   wire [2:0] x_nzp;
   wire [2:0] x_r1sel, x_r2sel, x_wsel;
   wire x_r1re, x_r2re, x_regfile_we, x_nzp_we, x_select_pc_plus_one, x_is_load, x_is_store, x_is_branch, x_is_control_insn; 
 
   // Computed during X
   wire [15:0] x_pc_plus_one, x_rs, x_rt, x_alu, x_wdata, x_next_pc;
   wire [15:0] x_rs_default, x_rt_default;
   wire [2:0] x_stall;
   wire [2:0] x_stall_default;

   //TODO
   // Load to use stall
   wire x_stall_ld, mx_bypass, wx_bypass, x_aluinA;
   // From slides
   assign x_stall_ld = x_is_load && ((d_r1sel == x_wsel) || ((d_r2sel == x_wsel) && !d_is_store));
   assign x_stall = x_stall_ld ? 2'b11 : x_stall_default;

   
   //assign x_aluinA = (x_rs == m_wsel) (x_rt == m_wsel)
   assign mx_bypass_rs = m_is_load && (m_wsel == x_r1sel);
   assign mx_bypass_rt = m_is_load && (m_wsel == x_r2sel);
   assign wx_bypass_rs = w_wsel == x_rs;
   assign wx_bypass_rt = w_wsel == x_rt;

   assign x_rs = (mx_bypass_rs ? m_wdata) : (wx_bypass_rs ? w_wdata : x_rs_default);
   assign x_rt = (mx_bypass_rt ? m_wdata) : (wx_bypass_rt ? w_wdata : x_rt_default);

   // Load Pipeline data
   insn_pipeline DX_pipeline( 
       .in_insn(d_insn), .in_pc(d_pc), .in_dmem_data(d_dmem_data), .in_nzp(d_nzp),
       .in_r1re(d_r1re), .in_r2re(d_r2re), .in_rs(d_rs), .in_rd(d_rd),
       .in_regfile_we(d_regfile_we), .in_nzp_we(d_nzp_we), 
       .in_select_pc_plus_one(d_select_pc_plus_one), 
       .in_is_load(d_is_load), .in_is_store(d_is_store), .in_is_branch(d_is_branch), 
       .in_is_control_insn(d_is_control_insn),
       .in_stall(d_stall),
       .out_insn(x_insn), .out_pc(x_pc), .out_dmem_data(x_dmem_data), .out_nzp(x_nzp),
       .out_r1re(x_r1re), .out_r2re(x_r2re), .out_rs(x_rs_default), .out_rd(x_rd_default),
       .out_regfile_we(x_regfile_we), .out_nzp_we(x_nzp_we), 
       .out_select_pc_plus_one(x_select_pc_plus_one), 
       .out_is_load(x_is_load), .out_is_store(x_is_store), .out_is_branch(x_is_branch), 
       .out_is_control_insn(x_is_control_insn),
       .out_stall(x_stall_default),
       .we(1'b1), .gwe(gwe), .rst(rst));

   // Increment PC
   cla16 a(.a(x_pc), .b(16'd0), .cin(1'b1), .sum(x_pc_plus_one));

   // Run the ALU
   lc4_alu alu(
      .i_insn(x_insn), 
      .i_pc(x_pc), 
      .i_r1data(x_rs), 
      .i_r2data(x_rt), 
      .o_result(x_alu)
   );

   // write to the register
   assign x_wdata = x_is_load ? x_dmem_data : (x_select_pc_plus_one ? x_pc_plus_one : x_alu);

   // branch logic!
   wire x_nzp_result = ((x_nzp & x_insn[11:9]) != 3'b0);
   // New
   wire [15:0] x_jmp_tgt = x_is_control_insn ? x_alu : x_pc_plus_one;
   assign x_next_pc = (x_is_branch & x_nzp_result) ? x_alu : x_jmp_tgt;
 
/*************** MEMORY ***************/
   // M: Memory
   // Previous Stages
   wire [15:0] m_insn, m_pc, m_dmem_data;
   wire [2:0] m_nzp;
   wire [2:0] m_r1sel, m_r2sel, m_wsel;
   wire m_r1re, m_r2re, m_regfile_we, m_nzp_we, m_select_pc_plus_one, m_is_load, m_is_store, m_is_branch, m_is_control_insn; 
   wire [15:0] m_rs, m_rt, m_alu, m_wdata, m_next_pc;
   wire m_nzp_result;
   wire [15:0] m_rs_default, m_rt_default;
   wire [2:0] m_stall;

   // Computed in M
   wire m_dmem_we;
   wire [15:0] m_dmem_addr, m_dmem_towrite;

   // Test Signals
   assign test_dmem_we = m_is_store;
   assign test_dmem_we = m_dmem_we;
   assign test_dmem_addr = m_dmem_addr;
   assign test_dmem_data = m_is_store ? m_dmem_towrite : (m_is_load ? m_dmem_data : 16'd0) ;
   
   //Bypassing
   // TODO
   wire wm_bypass_rt, wm_bypass_rs;
   assign wm_bypass_rs = = w_is_load && (m_is_load && m_rs == w_wsel) //Load, Load 
   assign wm_bypass_rt = w_is_load && (m_is_store && m_rt == w_wsel) //Load, Store
   assign m_rs = (wm_bypass_rs ? w_wdata) : m_rs_default;
   assign m_rt = (wm_bypass_rt ? w_wdata) : m_rt_default;

   insn_pipeline XM_pipeline( 
       .in_insn(x_insn), .in_pc(x_pc), .in_dmem_data(x_dmem_data), .in_nzp(x_nzp),
       .in_r1re(x_r1re), .in_r2re(x_r2re), 
       .in_regfile_we(x_regfile_we), .in_nzp_we(x_nzp_we), 
       .in_select_pc_plus_one(x_select_pc_plus_one), 
       .in_is_load(x_is_load), .in_is_store(x_is_store), .in_is_branch(x_is_branch), 
       .in_is_control_insn(x_is_control_insn),
       .in_rs(x_rs), .in_rt(x_rt), .in_alu(x_alu), .in_wdata(x_wdata), .in_next_pc(x_next_pc),
       .in_nzp_result(x_nzp_result),
       .in_stall(x_stall),
       .out_insn(m_insn), .out_pc(m_pc), .out_dmem_data(m_dmem_data), .out_nzp(m_nzp),
       .out_r1re(m_r1re), .out_r2re(m_r2re), 
       .out_regfile_we(m_regfile_we), .out_nzp_we(m_nzp_we), 
       .out_select_pc_plus_one(m_select_pc_plus_one), 
       .out_is_load(m_is_load), .out_is_store(m_is_store), .out_is_branch(m_is_branch), 
       .out_is_control_insn(m_is_control_insn),
       .out_rs(m_rs_default), .out_rt(m_rt_default), .out_alu(m_alu), .out_wdata(m_wdata), .out_next_pc(m_next_pc),
       .out_nzp_result(m_nzp_result),
       .out_stall(.m_stall),
       .we(1'b1), .gwe(gwe), .rst(rst));

    // Write to the memory
   memory_unit m(
      .is_store(m_is_store), .is_load(m_is_load), 
      .o_alu(m_alu),
      .o_dmem_we(m_dmem_we),
      .o_dmem_addr(m_dmem_addr), 
      .o_dmem_towrite(m_dmem_towrite), 
      .o_rt(m_rt)
   );

   //Test Signals Memory stage
   assign o_dmem_we = m_dmem_we;
   assign o_dmem_towrite = m_dmem_addr;
   assign o_dmem_addr = m_dmem_towrite;

/*************** WRITEBACK ***************/
   // W: Writeback
   // Previous Stages
   wire [15:0] w_insn, w_pc, w_dmem_data;
   wire [2:0] w_nzp;
   wire [2:0] w_r1sel, w_r2sel, w_wsel;
   wire w_r1re, w_r2re, w_regfile_we, w_nzp_we, w_select_pc_plus_one, w_is_load, w_is_store, w_is_branch, w_is_control_insn; 
   wire [15:0] w_rs, w_rt, w_alu, w_wdata, w_next_pc;
   wire w_nzp_result;
   wire w_dmem_we;
   wire [15:0] w_dmem_addr, w_dmem_towrite;
   wire [2:0] w_next_nzp;
   wire [2:0] w_stall;

   // Computed
   insn_pipeline MW_pipeline( 
       .in_insn(m_insn), .in_pc(m_pc), .in_dmem_data(m_dmem_data), .in_nzp(m_nzp),
       .in_r1re(m_r1re), .in_r2re(m_r2re), 
       .in_regfile_we(m_regfile_we), .in_nzp_we(m_nzp_we), 
       .in_select_pc_plus_one(m_select_pc_plus_one), 
       .in_is_load(m_is_load), .in_is_store(m_is_store), .in_is_branch(m_is_branch), 
       .in_is_control_insn(m_is_control_insn),
       .in_rs(m_rs), .in_rt(m_rt), .in_alu(m_alu), .in_wdata(m_wdata), .in_next_pc(m_next_pc),
       .in_nzp_result(m_nzp_result),
       .in_dmem_we(m_dmem_we), .in_dmem_addr(m_dmem_addr), .in_dmem_towrite(m_dmem_towrite),
       .in_stall(m_stall),
       .out_insn(w_insn), .out_pc(w_pc), .out_dmem_data(w_dmem_data), .out_nzp(w_nzp),
       .out_r1re(w_r1re), .out_r2re(w_r2re), 
       .out_regfile_we(w_regfile_we), .out_nzp_we(w_nzp_we), 
       .out_select_pc_plus_one(w_select_pc_plus_one), 
       .out_is_load(w_is_load), .out_is_store(w_is_store), .out_is_branch(w_is_branch), 
       .out_is_control_insn(w_is_control_insn),
       .out_rs(w_rs), .out_rt(w_rt), .out_alu(w_alu), .out_wdata(w_wdata), .out_next_pc(w_next_pc),
       .out_nzp_result(w_nzp_result),
       .out_dmem_we(w_dmem_we), .out_dmem_addr(w_dmem_addr), .out_dmem_towrite(w_dmem_towrite),
       .out_stall(w_stall),
       .we(1'b1), .gwe(gwe), .rst(rst));

   // Make the NZP register
   /*
   Nbit_reg #(3, 3'd0) nzp_reg (
      .in(w_nzp_result), 
      .out(w_nzp), 
      .clk(clk), 
      .we(w_nzp_we), 
      .gwe(gwe), 
      .rst(rst)
   );

   // Update the NZP bits from the ALU
   nzp_unit n(
      .i_wdata(w_wdata),
      .next_nzp(w_next_nzp)
   );*/

   // TEST SIGNALS
   //Stall
   assign test_stall = w_stall; 
   //assign test_cur_pc = 16'h9010;
   assign test_cur_pc = w_next_pc;
   assign test_cur_insn = w_insn;
   assign test_regfile_we = w_regfile_we;
   assign test_regfile_wsel = w_wsel;
   assign test_regfile_data = w_regfile_we ? w_wdata : 16'd0;
   assign test_nzp_we = w_nzp_we;
   //assign test_nzp_new_bits = w_nzp_result;

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
      $display("%d %h %h %h %h %h", $time, f_pc, d_pc, x_pc, m_pc, test_cur_pc);
      if (o_dmem_we)
         $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

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
