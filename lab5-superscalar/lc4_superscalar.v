`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

`include "lc4_alu.v"
`include "lc4_regfile_ss.v"

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

    // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   // pc wires attached to the PC register's ports
   wire [15:0]   pc_A;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc_A; // Next program counter (you compute this and feed it into next_pc)
   wire [15:0]   pc_B;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc_B; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   //Nbit_reg #(16, 16'h8200) pc_reg (.in(c), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


/*************** VARIABLES B ***************/
   wire [15:0] f_insn_A, d_insn_A, x_insn_A, m_insn_A, w_insn_A; // Instructions
   wire [15:0] f_pc_A, d_pc_A, x_pc_A, m_pc_A, w_pc_A; // program counters
   wire [1:0]  f_stall_A, d_stall_A, x_stall_A, m_stall_A, w_stall_A; // all the stall counters
   wire                 d_nzp_we_A, x_nzp_we_A, m_nzp_we_A, w_nzp_we_A; // write enable
   wire [2:0]           d_r1sel_A, x_r1sel_A;
   wire                 d_r1re_A, x_r1re_A, m_r1re_A;
   wire [2:0]           d_r2sel_A, x_r2sel_A, m_r2sel_A;
   wire                 d_r2re_A, x_r2re_A, m_r2re_A;
   wire [2:0]           d_wsel_A, x_wsel_A, m_wsel_A, w_wsel_A;
   wire                 d_regfile_we_A, x_regfile_we_A, m_regfile_we_A, w_regfile_we_A;
   wire                 d_select_pc_plus_one_A, x_select_pc_plus_one_A, m_select_pc_plus_one_A, w_select_pc_plus_one_A;
   wire                 d_is_load_A, x_is_load_A, m_is_load_A, w_is_load_A;
   wire                 d_is_store_A, x_is_store_A, m_is_store_A, w_is_store_A;
   wire                 d_is_branch_A, x_is_branch_A;
   wire                 d_is_control_insn_A, x_is_control_insn_A;
   wire [15:0]          d_rs_A, x_rs_A;
   wire [15:0]          d_rt_A, x_rtv, m_rt_A;
   wire [15:0]                x_alu_A, m_alu_A, w_alu_A;
   wire [15:0]                x_pc_plus_one_A, m_pc_plus_one_A, w_pc_plus_one_A;
   wire [2:0]                 x_nzp_A, m_nzp_A, w_nzp_A;
   wire [15:0]                x_wdata_A, m_wdata_A, w_wdata_A;
   wire        took_branch_A;

/*************** VARIABLES A ***************/
   wire [15:0] f_insn_B, d_insn_B, x_insn_B, m_insn_B, w_insn_B; // Instructions
   wire [15:0] f_pc_B, d_pc_B, x_pc_B, m_pc_B, w_pc_B; // program counters
   wire [1:0]  f_stall_B, d_stall_B, x_stall_B, m_stall_B, w_stall_B; // all the stall counters
   wire                 d_nzp_we_B, x_nzp_we_B, m_nzp_we_B, w_nzp_we_B; // write enable
   wire [2:0]           d_r1sel_B, x_r1sel_B;
   wire                 d_r1re_B, x_r1re_B, m_r1re_B;
   wire [2:0]           d_r2sel_B, x_r2sel_B, m_r2sel_B;
   wire                 d_r2re_B, x_r2re_B, m_r2re_B;
   wire [2:0]           d_wsel_B, x_wsel_B, m_wsel_B, w_wsel_B;
   wire                 d_regfile_we_B, x_regfile_we_B, m_regfile_we_B, w_regfile_we_B;
   wire                 d_select_pc_plus_one_B, x_select_pc_plus_one_B, m_select_pc_plus_one_B, w_select_pc_plus_one_B;
   wire                 d_is_load_B, x_is_load_B, m_is_load_B, w_is_load_B;
   wire                 d_is_store_B, x_is_store_B, m_is_store_B, w_is_store_B;
   wire                 d_is_branch_B, x_is_branch_B;
   wire                 d_is_control_insn_B, x_is_control_insn_B;
   wire [15:0]          d_rs_B, x_rs_B;
   wire [15:0]          d_rt_B, x_rtv, m_rt_B;
   wire [15:0]                x_alu_B, m_alu_B, w_alu_B;
   wire [15:0]                x_pc_plus_one_B, m_pc_plus_one_B, w_pc_plus_one_B;
   wire [2:0]                 x_nzp_B, m_nzp_B, w_nzp_B;
   wire [15:0]                x_wdata_B, m_wdata_B, w_wdata_B;
   wire        took_branch_B;



/*************** FETCH STAGE A ***************/
   wire is_not_stall_A, stall_default_A;

   assign stall_default_A = x_is_load_A && ((x_wsel_A == d_r1sel_A && d_r1re_A) || (x_wsel_A == d_r2sel_A && d_r2re_A)) && (!d_is_store_A || x_wsel_A == d_r1sel_A || x_wsel_A != d_r2sel_A);
   assign is_not_stall_A = (!x_is_load_A || !d_is_branch_A) && !stall_default_A;

   // Load in the instructions, stall values, and pc
   assign f_insn_A = took_branch_A ? 16'd0 : i_cur_insn_A;
   assign f_stall_A = took_branch_A ? 2'd2 : (is_not_stall_A ? 2'd0 : 2'd3);
   assign o_cur_pc_A = f_pc_A;

   // Single PC register for the fetch stage
   Nbit_reg #(16, 16'h8200) f_pc_reg(.in(next_pc_A), .out(f_pc_A), .we(is_not_stall_A), .clk(clk), .gwe(gwe), .rst(rst));

/*************** FETCH STAGE B ***************/
   wire is_not_stall_B, stall_default_B;

   assign stall_default_B = x_is_load_B && ((x_wsel_B == d_r1sel_B && d_r1re_B) || (x_wsel_B == d_r2sel_B && d_r2re_B)) && (!d_is_store_B || x_wsel_B == d_r1sel_B || x_wsel_B != d_r2sel_B);
   assign is_not_stall_B = (!x_is_load_B || !d_is_branch_B) && !stall_default_B;

   // Load in the instructions, stall values, and pc
   assign f_insn_B = took_branch_B ? 16'd0 : i_cur_insn_B;
   assign f_stall_B = took_branch_B ? 2'd2 : (is_not_stall_B ? 2'd0 : 2'd3);
   assign o_cur_pc_B = f_pc_B;

   // Single PC register for the fetch stage
   Nbit_reg #(16, 16'h8200) f_pc_reg(.in(next_pc_B), .out(f_pc_B), .we(is_not_stall_B), .clk(clk), .gwe(gwe), .rst(rst));

/*************** DECODE STAGE A ***************/
   wire [15:0] d_rs_default_A, d_rt_default_A;
   
   // decode registers
   Nbit_reg #(16, 16'b0) d_insn_reg(.in(f_insn_A), .out(d_insn_A), .we(is_not_stall_A), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) D_pc(.in(f_pc_A), .out(d_pc_A), .we(is_not_stall_A), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2)   d_stall_reg(.in(f_stall_A), .out(d_stall_A), .we(is_not_stall_A), .clk(clk), .gwe(gwe), .rst(rst));

   // Bypassing from WD (removed as not required)
   assign d_rs_A = d_rs_default_A;
   assign d_rt_A = d_rt_default_A;

   // Decode the instruction A
   lc4_decoder d_A(
      .insn(d_insn_A),
      .r1re(d_r1re_A),
      .r1sel(d_r1sel_A),
      .r2re(d_r2re_A),
      .r2sel(d_r2sel_A),
      .wsel(d_wsel_A),
      .regfile_we(d_regfile_we_A),
      .nzp_we(d_nzp_we_A),
      .select_pc_plus_one(d_select_pc_plus_one_A),
      .is_load(d_is_load_A),
      .is_store(d_is_store_A),
      .is_branch(d_is_branch_A),
      .is_control_insn(d_is_control_insn_A)
   );
   
   // read the registers
   lc4_regfile r(
      .clk(clk),
      .gwe(gwe),
      .rst(rst),
      .i_rs(d_r1sel_A),      // rs selector
      .o_rs_data(d_rs_default_A), // rs contents
      .i_rt(d_r2sel_A),      // rt selector
      .o_rt_data(d_rt_default_A), // rt contents
      .i_rd(w_wsel_A),      // rd selector (Write phase)
      .i_wdata(w_wdata_A),   // data to write (Write phase)
      .i_rd_we(w_regfile_we_A)  
   );

/*************** DECODE STAGE B ***************/
   wire [15:0] d_rs_default_B, d_rt_default_B;
   
   // decode registers
   Nbit_reg #(16, 16'b0) d_insn_reg(.in(f_insn_B), .out(d_insn_B), .we(is_not_stall_B), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) D_pc(.in(f_pc_B), .out(d_pc_B), .we(is_not_stall_B), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2)   d_stall_reg(.in(f_stall_B), .out(d_stall_B), .we(is_not_stall_B), .clk(clk), .gwe(gwe), .rst(rst));

   // Bypassing from WD (removed as not required)
   assign d_rs_B = d_rs_default_B;
   assign d_rt_B = d_rt_default_B;

   // Decode the instruction B
   lc4_decoder d_B(
      .insn(d_insn_B),
      .r1re(d_r1re_B),
      .r1sel(d_r1sel_B),
      .r2re(d_r2re_B),
      .r2sel(d_r2sel_B),
      .wsel(d_wsel_B),
      .regfile_we(d_regfile_we_B),
      .nzp_we(d_nzp_we_B),
      .select_pc_plus_one(d_select_pc_plus_one_B),
      .is_load(d_is_load_B),
      .is_store(d_is_store_B),
      .is_branch(d_is_branch_B),
      .is_control_insn(d_is_control_insn_B)
   );
   
   // read the registers
   lc4_regfile r(
      .clk(clk),
      .gwe(gwe),
      .rst(rst),
      .i_rs(d_r1sel_B),      // rs selector
      .o_rs_data(d_rs_default_B), // rs contents
      .i_rt(d_r2sel_B),      // rt selector
      .o_rt_data(d_rt_default_B), // rt contents
      .i_rd(w_wsel_B),      // rd selector (Write phase)
      .i_wdata(w_wdata_B),   // data to write (Write phase)
      .i_rd_we(w_regfile_we_B)  
   );

/*************** EXECUTE STAGE A ***************/

   // TODO: change to x!
   wire [15:0] x_insn_default_A;
   wire [2:0]  x_r1sel_default_A, x_r2sel_default_A, x_wsel_default_A;
   wire [1:0]  x_stall_default_A;
   wire x_regfile_we_default_A, x_nzp_we_default_A, x_select_pc_plus_one_default_A, x_is_load_default_A, x_is_store_default_A, x_is_branch_default_A, x_is_control_insn_default_A, zero_default_A;

   // Input should be null if we are stalled or took a branch
   assign zero_default_A = !is_not_stall_A || took_branch_A;
   assign x_insn_default_A = zero_default_A ? 16'b0 : d_insn_A;
   assign x_r1sel_default_A = zero_default_A ? 3'b0 : d_r1sel_A;
   assign x_r2sel_default_A = zero_default_A ? 3'b0 : d_r2sel_A;
   assign x_wsel_default_A = zero_default_A ? 3'b0 : d_wsel_A;
   assign x_regfile_we_default_A = zero_default_A ? 1'b0 : d_regfile_we_A;
   assign x_nzp_we_default_A = zero_default_A ? 1'b0 : d_nzp_we_A;
   assign x_select_pc_plus_one_default_A = zero_default_A ? 1'b0 : d_select_pc_plus_one_A;
   assign x_is_load_default_A = zero_default_A ? 1'b0 : d_is_load_A;
   assign x_is_store_default_A = zero_default_A ? 1'b0 : d_is_store_A;
   assign x_is_branch_default_A = zero_default_A ? 1'b0 : d_is_branch_A;
   assign x_is_control_insn_default_A = zero_default_A ? 1'b0 : d_is_control_insn_A;
   assign x_stall_default_A = took_branch_A ? 2'd2 : (is_not_stall_A ? d_stall_A : 2'd3);

   // Registers for execute stage
   Nbit_reg #(16, 16'h8200) x_pc_reg(.in(d_pc_A), .out(x_pc_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2) x_stall_reg(.in(x_stall_default_A), .out(x_stall_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_rs_data_reg(.in(d_rs_A), .out(x_rs_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_rt_data_reg(.in(d_rt_A), .out(x_rt_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   // including registers for all decoded signals
   Nbit_reg #(16, 16'b0) x_insn_reg(.in(x_insn_default_A), .out(x_insn_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) x_r1sel_reg(.in(x_r1sel_default_A), .out(x_r1sel_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) x_r2sel_reg(.in(x_r2sel_default_A), .out(x_r2sel_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) x_wsel_reg(.in(x_wsel_default_A), .out(x_wsel_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_regfile_we_reg(.in(x_regfile_we_default_A), .out(x_regfile_we_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_nzp_we_reg(.in(x_nzp_we_default_A), .out(x_nzp_we_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_select_pc_plus_one_reg(.in(x_select_pc_plus_one_default_A), .out(x_select_pc_plus_one_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));                      
   Nbit_reg #(1, 1'b0) x_is_load_reg(.in(x_is_load_default_A), .out(x_is_load_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_is_store_reg(.in(x_is_store_default_A), .out(x_is_store_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_is_branch_reg(.in(x_is_branch_default_A), .out(x_is_branch), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_is_control_insn_reg(.in(x_is_control_insn_default_A), .out(x_is_control_insn_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));

   // Bypasses
   wire [15: 0] mx_bypass_rs_A, mx_bypass_rt_A, wx_bypass_rs_A, wx_bypass_rt_A;

   assign wx_bypass_rs_A = (x_r1sel_A == w_wsel_A && w_regfile_we_A) ? w_wdata_A : x_rs_A;
   assign wx_bypass_rt_A = (x_r2sel_A == w_wsel_A && w_regfile_we_A) ? w_wdata_A : x_rt_A;

   assign mx_bypass_rs_A = (x_r1sel_A == m_wsel_A && m_regfile_we_A) ? m_alu_A : wx_bypass_rs_A;
   assign mx_bypass_rt_A = (x_r2sel_A == m_wsel_A && m_regfile_we_A) ? m_alu_A : wx_bypass_rt_A;

   // Increment PC
   cla16 c(.a(f_pc), .b(16'b0), .cin(1'b1), .sum(x_pc_plus_one_A));

   // Connect the ALU
   lc4_alu alu(
      .i_insn(x_insn_A), 
      .i_pc(x_pc_A), 
      .i_r1data(mx_bypass_rs_A), 
      .i_r2data(mx_bypass_rt_A), 
      .o_result(x_alu_A)
   );

   // put the correct data in the wdata pipe
   assign x_wdata_A = x_is_load_A ? i_cur_dmem_data_A : (x_select_pc_plus_one_A ? (x_is_control_insn_A ? w_pc_plus_one_A : x_pc_plus_one_A) : x_alu_A);

   // NZP updating
   wire neg_A, zero_A, pos_A;
   assign neg_A = x_wdata_A[15];
   assign zero_A = x_wdata_A == 16'b0;
   assign pos_A = !neg_A & !zero_A;
   assign x_nzp_A = (!x_is_load_A && x_nzp_we_A) ? {neg_A, zero_A, pos_A} : (m_nzp_we_A ? m_nzp_A : w_nzp_A);

   // Branch, if we need to, and remember if we branched
   wire nzp_result_A; 
   assign nzp_result_A = ((x_nzp_A[0] == x_insn_A[9] && x_nzp_A[0]) || (x_nzp_A[1] == x_insn_A[10] && x_nzp_A[1]) || (x_nzp_A[2] == x_insn_A[11] && x_nzp_A[2]));
   assign took_branch_A = (x_is_branch_A && nzp_result_A) || x_is_control_insn_A;
   assign next_pc_A = took_branch_A ? x_alu_A : x_pc_plus_one_A;

/*************** EXECUTE STAGE B ***************/

   // TODO: change to x!
   wire [15:0] x_insn_default_B;
   wire [2:0]  x_r1sel_default_B, x_r2sel_default_B, x_wsel_default_B;
   wire [1:0]  x_stall_default_B;
   wire x_regfile_we_default_B, x_nzp_we_default_B, x_select_pc_plus_one_default_B, x_is_load_default_B, x_is_store_default_B, x_is_branch_default_B, x_is_control_insn_default_B, zero_default_B;

   // Input should be null if we are stalled or took a branch
   assign zero_default_B = !is_not_stall_B || took_branch_B;
   assign x_insn_default_B = zero_default_B ? 16'b0 : d_insn_B;
   assign x_r1sel_default_B = zero_default_B ? 3'b0 : d_r1sel_B;
   assign x_r2sel_default_B = zero_default_B ? 3'b0 : d_r2sel_B;
   assign x_wsel_default_B = zero_default_B ? 3'b0 : d_wsel_B;
   assign x_regfile_we_default_B = zero_default_B ? 1'b0 : d_regfile_we_B;
   assign x_nzp_we_default_B = zero_default_B ? 1'b0 : d_nzp_we_B;
   assign x_select_pc_plus_one_default_B = zero_default_B ? 1'b0 : d_select_pc_plus_one_B;
   assign x_is_load_default_B = zero_default_B ? 1'b0 : d_is_load_B;
   assign x_is_store_default_B = zero_default_B ? 1'b0 : d_is_store_B;
   assign x_is_branch_default_B = zero_default_B ? 1'b0 : d_is_branch_B;
   assign x_is_control_insn_default_B = zero_default_B ? 1'b0 : d_is_control_insn_B;
   assign x_stall_default_B = took_branch_B ? 2'd2 : (is_not_stall_B ? d_stall_B : 2'd3);

   // Registers for execute stage
   Nbit_reg #(16, 16'h8200) x_pc_reg(.in(d_pc_B), .out(x_pc_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2) x_stall_reg(.in(x_stall_default_B), .out(x_stall_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_rs_data_reg(.in(d_rs_B), .out(x_rs_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_rt_data_reg(.in(d_rt_B), .out(x_rt_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   // including registers for all decoded signals
   Nbit_reg #(16, 16'b0) x_insn_reg(.in(x_insn_default_B), .out(x_insn_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) x_r1sel_reg(.in(x_r1sel_default_B), .out(x_r1sel_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) x_r2sel_reg(.in(x_r2sel_default_B), .out(x_r2sel_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) x_wsel_reg(.in(x_wsel_default_B), .out(x_wsel_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_regfile_we_reg(.in(x_regfile_we_default_B), .out(x_regfile_we_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_nzp_we_reg(.in(x_nzp_we_default_B), .out(x_nzp_we_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_select_pc_plus_one_reg(.in(x_select_pc_plus_one_default_B), .out(x_select_pc_plus_one_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));                      
   Nbit_reg #(1, 1'b0) x_is_load_reg(.in(x_is_load_default_B), .out(x_is_load_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_is_store_reg(.in(x_is_store_default_B), .out(x_is_store_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_is_branch_reg(.in(x_is_branch_default_B), .out(x_is_branch), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) x_is_control_insn_reg(.in(x_is_control_insn_default_B), .out(x_is_control_insn_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));

   // Bypasses
   wire [15: 0] mx_bypass_rs_B, mx_bypass_rt_B, wx_bypass_rs_B, wx_bypass_rt_B;

   assign wx_bypass_rs_B = (x_r1sel_B == w_wsel_B && w_regfile_we_B) ? w_wdata_B : x_rs_B;
   assign wx_bypass_rt_B = (x_r2sel_B == w_wsel_B && w_regfile_we_B) ? w_wdata_B : x_rt_B;

   assign mx_bypass_rs_B = (x_r1sel_B == m_wsel_B && m_regfile_we_B) ? m_alu_B : wx_bypass_rs_B;
   assign mx_bypass_rt_B = (x_r2sel_B == m_wsel_B && m_regfile_we_B) ? m_alu_B : wx_bypass_rt_B;

   // Increment PC
   cla16 c(.a(f_pc), .b(16'b0), .cin(1'b1), .sum(x_pc_plus_one_B));

   // Connect the ALU
   lc4_alu alu(
      .i_insn(x_insn_B), 
      .i_pc(x_pc_B), 
      .i_r1data(mx_bypass_rs_B), 
      .i_r2data(mx_bypass_rt_B), 
      .o_result(x_alu_B)
   );

   // put the correct data in the wdata pipe
   assign x_wdata_B = x_is_load_B ? i_cur_dmem_data_B : (x_select_pc_plus_one_B ? (x_is_control_insn_B ? w_pc_plus_one_B : x_pc_plus_one_B) : x_alu_B);

   // NZP updating
   wire neg_B, zero_B, pos_B;
   assign neg_B = x_wdata_B[15];
   assign zero_B = x_wdata_B == 16'b0;
   assign pos_B = !neg_B & !zero_B;
   assign x_nzp_B = (!x_is_load_B && x_nzp_we_B) ? {neg_B, zero_B, pos_B} : (m_nzp_we_B ? m_nzp_B : w_nzp_B);

   // Branch, if we need to, and remember if we branched
   wire nzp_result_B; 
   assign nzp_result_B = ((x_nzp_B[0] == x_insn_B[9] && x_nzp_B[0]) || (x_nzp_B[1] == x_insn_B[10] && x_nzp_B[1]) || (x_nzp_B[2] == x_insn_B[11] && x_nzp_B[2]));
   assign took_branch_B = (x_is_branch_B && nzp_result_B) || x_is_control_insn_B;
   assign next_pc_B = took_branch_B ? x_alu_B : x_pc_plus_one_B;

/*************** MEMORY STAGE A ***************/

   wire [15:0] m_pc_plus_one_default_A;

   assign m_pc_plus_one_default_A = x_is_control_insn_A ? w_pc_plus_one_A : x_pc_plus_one_A;

   // Registers for the memory stage
   Nbit_reg #(16, 16'b0) m_pc_reg(.in(x_pc_A), .out(m_pc_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2) m_stall_reg(.in(x_stall_A), .out(m_stall_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) m_alu_output_reg(.in(x_alu_A), .out(m_alu_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) m_nzp_reg(.in(x_nzp), .out(m_nzp_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) m_pc_plus_one_reg(.in(m_pc_plus_one_default_A), .out(m_pc_plus_one_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16)      m_rt_data_reg(.in(mx_bypass_rt_A), .out(m_rt_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   // Included decoded signals
   Nbit_reg #(16, 16'b0) m_insn_reg(.in(x_insn_A), .out(m_insn_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) m_r2sel_reg(.in(x_r2sel_A), .out(m_r2sel_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(3, 3'b0) m_wsel_reg(.in(x_wsel_A), .out(m_wsel_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_regfile_we_reg(.in(x_regfile_we_A), .out(m_regfile_we_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_nzp_we_reg(.in(x_nzp_we_A), .out(m_nzp_we_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_select_pc_plus_one_reg(.in(x_select_pc_plus_one_A), .out(m_select_pc_plus_one_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(1)       m_is_load_reg(.in(x_is_load_A), .out(m_is_load_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_is_store_reg(.in(x_is_store_A), .out(m_is_store_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));                     

   // Bypassing
   wire wm_bypass_rt_A;
   wire [15:0] wm_rt_A;
   assign wm_bypass_rt_A = w_regfile_we_A && m_is_store_A && m_r2sel_A == w_wsel_A; // Load, Store
   assign wm_rt_A = wm_bypass_rt_A ? w_wdata_A : m_rt_A;

   // Set output signals
   memory_unit mem_unit(
      .is_store(m_is_store_A), 
      .is_load(m_is_load_A), 
      .o_alu(m_alu_A), 
      .o_rt(wm_rt_A), 
      .o_dmem_we(o_dmem_we_A), 
      .o_dmem_addr(o_dmem_addr_A), 
      .o_dmem_towrite(o_dmem_towrite_A)
   );

/*************** MEMORY STAGE B ***************/

   wire [15:0] m_pc_plus_one_default_B;

   assign m_pc_plus_one_default_B = x_is_control_insn_B ? w_pc_plus_one_B : x_pc_plus_one_B;

   // Registers for the memory stage
   Nbit_reg #(16, 16'b0) m_pc_reg(.in(x_pc_B), .out(m_pc_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2) m_stall_reg(.in(x_stall_B), .out(m_stall_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) m_alu_output_reg(.in(x_alu_B), .out(m_alu_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) m_nzp_reg(.in(x_nzp), .out(m_nzp_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) m_pc_plus_one_reg(.in(m_pc_plus_one_default_B), .out(m_pc_plus_one_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16)      m_rt_data_reg(.in(mx_bypass_rt_B), .out(m_rt_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   // Included decoded signals
   Nbit_reg #(16, 16'b0) m_insn_reg(.in(x_insn_B), .out(m_insn_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) m_r2sel_reg(.in(x_r2sel_B), .out(m_r2sel_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(3, 3'b0) m_wsel_reg(.in(x_wsel_B), .out(m_wsel_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_regfile_we_reg(.in(x_regfile_we_B), .out(m_regfile_we_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_nzp_we_reg(.in(x_nzp_we_B), .out(m_nzp_we_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_select_pc_plus_one_reg(.in(x_select_pc_plus_one_B), .out(m_select_pc_plus_one_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(1)       m_is_load_reg(.in(x_is_load_B), .out(m_is_load_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1)       m_is_store_reg(.in(x_is_store_B), .out(m_is_store_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));                     

   // Bypassing
   wire wm_bypass_rt_B;
   wire [15:0] wm_rt_B;
   assign wm_bypass_rt_B = w_regfile_we_B && m_is_store_B && m_r2sel_B == w_wsel_B; // Load, Store
   assign wm_rt_B = wm_bypass_rt_B ? w_wdata_B : m_rt_B;

   // Set output signals
   memory_unit mem_unit(
      .is_store(m_is_store_B), 
      .is_load(m_is_load_B), 
      .o_alu(m_alu_B), 
      .o_rt(wm_rt_B), 
      .o_dmem_we(o_dmem_we_B), 
      .o_dmem_addr(o_dmem_addr_B), 
      .o_dmem_towrite(o_dmem_towrite_B)
   );


/*************** WRITEBACK STAGE A ***************/
   wire w_dmem_we_A;
   wire [15:0] w_dmem_towrite_A, w_dmem_addr_A, w_cur_dmem_data_A;

   // Registers for the writeback stage
   Nbit_reg #(16, 16'b0) w_pc_reg(.in(m_pc_A), .out(w_pc_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_alu_output_reg(.in(m_alu_A), .out(w_alu_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2) w_stall_reg(.in(m_stall_A), .out(w_stall_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));

   Nbit_reg #(16, 16'b0) w_insn_reg(.in(m_insn_A), .out(w_insn_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_pc_plus_one_reg(.in(m_pc_plus_one_A), .out(w_pc_plus_one_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) w_wsel_reg(.in(m_wsel_A), .out(w_wsel_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_regfile_we_reg(.in(m_regfile_we_A), .out(w_regfile_we_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_nzp_we_reg(.in(m_nzp_we_A), .out(w_nzp_we_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_select_pc_plus_one_reg(.in(m_select_pc_plus_one_A), .out(w_select_pc_plus_one_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(1, 1'b0) w_is_load_reg(.in(m_is_load_A), .out(w_is_load_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_is_store_reg(.in(m_is_store_A), .out(w_is_store), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));                     
   Nbit_reg #(3, 3'b0) w_nzp_reg(.in(m_nzp_A), .out(w_nzp_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_dmem_towrite_reg(.in(o_dmem_towrite_A), .out(w_dmem_towrite_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_dmem_addr_reg(.in(o_dmem_addr_A), .out(w_dmem_addr_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 16'b0) w_dmem_we_reg(.in(o_dmem_we_A), .out(w_dmem_we_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_cur_dmem_data_reg(.in(i_cur_dmem_data_A), .out(w_cur_dmem_data_A), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));

   assign w_wdata_A = w_is_load_A ? w_cur_dmem_data_A : (w_select_pc_plus_one_A ? w_pc_plus_one_A : w_alu_A);

   wire [2:0] w_nzp_update_A;
   
   wire w_neg_A, w_zero_A, w_pos_A;
   assign w_neg_A = w_wdata_A[15];
   assign w_zero_A = w_wdata_A == 16'b0;
   assign w_pos_A = !neg_A & !zero_A;
   assign w_nzp_update_A = (w_is_load_A && w_nzp_we_A) ? {w_neg_A, w_zero_A, w_pos_A} : w_nzp_A;

/*************** WRITEBACK STAGE B ***************/
   wire w_dmem_we_B;
   wire [15:0] w_dmem_towrite_B, w_dmem_addr_B, w_cur_dmem_data_B;

   // Registers for the writeback stage
   Nbit_reg #(16, 16'b0) w_pc_reg(.in(m_pc_B), .out(w_pc_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_alu_output_reg(.in(m_alu_B), .out(w_alu_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'h2) w_stall_reg(.in(m_stall_B), .out(w_stall_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));

   Nbit_reg #(16, 16'b0) w_insn_reg(.in(m_insn_B), .out(w_insn_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_pc_plus_one_reg(.in(m_pc_plus_one_B), .out(w_pc_plus_one_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0) w_wsel_reg(.in(m_wsel_B), .out(w_wsel_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_regfile_we_reg(.in(m_regfile_we_B), .out(w_regfile_we_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_nzp_we_reg(.in(m_nzp_we_B), .out(w_nzp_we_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_select_pc_plus_one_reg(.in(m_select_pc_plus_one_B), .out(w_select_pc_plus_one_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(1, 1'b0) w_is_load_reg(.in(m_is_load_B), .out(w_is_load_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) w_is_store_reg(.in(m_is_store_B), .out(w_is_store), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));                     
   Nbit_reg #(3, 3'b0) w_nzp_reg(.in(m_nzp_B), .out(w_nzp_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_dmem_towrite_reg(.in(o_dmem_towrite_B), .out(w_dmem_towrite_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_dmem_addr_reg(.in(o_dmem_addr_B), .out(w_dmem_addr_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 16'b0) w_dmem_we_reg(.in(o_dmem_we_B), .out(w_dmem_we_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) w_cur_dmem_data_reg(.in(i_cur_dmem_data_B), .out(w_cur_dmem_data_B), .we(1'b1), .clk(clk), .gwe(gwe), .rst(rst));

   assign w_wdata_B = w_is_load_B ? w_cur_dmem_data_B : (w_select_pc_plus_one_B ? w_pc_plus_one_B : w_alu_B);

   wire [2:0] w_nzp_update_B;
   
   wire w_neg_B, w_zero_B, w_pos_B;
   assign w_neg_B = w_wdata_B[15];
   assign w_zero_B = w_wdata_B == 16'b0;
   assign w_pos_B = !neg_B & !zero_B;
   assign w_nzp_update_B = (w_is_load_B && w_nzp_we_B) ? {w_neg_B, w_zero_B, w_pos_B} : w_nzp_B;



/*************** TESTBENCH SIGNALS A ***************/
   assign test_cur_pc = w_pc_A;
   assign test_cur_insn = w_insn_A;
   assign test_regfile_we = w_regfile_we_A;
   assign test_regfile_wsel = w_wsel_A;
   assign test_regfile_data = w_regfile_we_A ? w_wdata_A : 16'b0;
   assign test_nzp_we = w_nzp_we_A;
   assign test_nzp_new_bits = w_is_load_A ? w_nzp_update_A : w_nzp_A;
   assign test_dmem_we = w_dmem_we_A;
   assign test_dmem_addr = w_dmem_addr_A;
   assign test_dmem_data = w_is_store_A ? w_dmem_towrite_A : (w_is_load_A ? w_cur_dmem_data_A : 16'b0);
   assign test_stall = w_stall_A;

/*************** TESTBENCH SIGNALS B ***************/
   assign test_cur_pc = w_pc_B;
   assign test_cur_insn = w_insn_B;
   assign test_regfile_we = w_regfile_we_B;
   assign test_regfile_wsel = w_wsel_B;
   assign test_regfile_data = w_regfile_we_B ? w_wdata_B : 16'b0;
   assign test_nzp_we = w_nzp_we_B;
   assign test_nzp_new_bits = w_is_load_B ? w_nzp_update_B : w_nzp_B;
   assign test_dmem_we = w_dmem_we_B;
   assign test_dmem_addr = w_dmem_addr_B;
   assign test_dmem_data = w_is_store_B ? w_dmem_towrite_B : (w_is_load_B ? w_cur_dmem_data_B : 16'b0);
   assign test_stall = w_stall_B;

`ifndef NDEBUG
   always @(posedge gwe) begin
      $display("NZP IS %d %d %d", x_nzp, m_nzp, w_nzp);
      $display("x_wdata %d %d %d %d %d %d %d %d", x_is_load, i_cur_dmem_data, x_select_pc_plus_one, x_is_control_insn, w_pc_plus_one, x_pc_plus_one, x_alu, x_wdata);
      $display("select pc + 1 %d %d %d", d_select_pc_plus_one, x_select_pc_plus_one_default, x_select_pc_plus_one);

   end
endmodule
