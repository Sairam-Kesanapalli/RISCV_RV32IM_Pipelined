`timescale 1ns/1ps
module rv32im_tb;
reg clk;
reg rst_n;


rv32im_pipelined rv (
    .clk(clk),
    .rst_n(rst_n)
);

always #5 clk = ~clk;

    integer i;
    initial begin

       $dumpfile("RV32IM_verification.vcd");
       $dumpvars;
       for (i = 0; i < 32; i = i + 1) begin
           $dumpvars(0, rv32im_tb.rv.rf.regs[i]);
       end
        clk = 0;
        rst_n = 0;
         #10;
        rst_n = 1;
       #10000; // Enough time for iterative mul/div (32 cycles each)

       $display("===== Register File Dump =====");
       for (i = 0; i < 23; i = i + 1) begin
           $display("x%-2d = %0d (0x%08h)", i, $signed(rv.rf.regs[i]), rv.rf.regs[i]);
       end
       $display("==============================");

       // ---- Verification ----
       $display("");
       $display("===== RV32IM Base Checks =====");
       $display("x1  = %0d (expected 10)",  $signed(rv.rf.regs[1]));
       $display("x2  = %0d (expected 3)",   $signed(rv.rf.regs[2]));
       $display("x3  = %0d (expected 13)",  $signed(rv.rf.regs[3]));  // ADD x3, x1, x2
       $display("x4  = %0d (expected 7)",   $signed(rv.rf.regs[4]));  // SUB x4, x1, x2

       $display("");
       $display("===== M-Extension Checks =====");
       $display("x10 = %0d (expected 30: MUL)",   $signed(rv.rf.regs[10]));
       $display("x11 = %0d (expected 3:  DIV)",   $signed(rv.rf.regs[11]));
       $display("x12 = %0d (expected 1:  REM)",   $signed(rv.rf.regs[12]));
       $display("x13 = %0d (expected 3:  DIVU)",  $signed(rv.rf.regs[13]));
       $display("x14 = %0d (expected 1:  REMU)",  $signed(rv.rf.regs[14]));
       $display("x15 = %0d (expected 0:  MULH)",  $signed(rv.rf.regs[15]));
       $display("x16 = %0d (expected 0:  MULHU)", $signed(rv.rf.regs[16]));

       $display("");
       $display("===== Edge Case Checks =====");
       $display("x21 = %0d (expected -1: DIV by 0)",  $signed(rv.rf.regs[21]));
       $display("x22 = %0d (expected 10: REM by 0)",  $signed(rv.rf.regs[22]));
       $display("==============================");

       // Pass/Fail
       if (rv.rf.regs[1]  == 10 &&
           rv.rf.regs[2]  == 3  &&
           rv.rf.regs[3]  == 13 &&
           rv.rf.regs[4]  == 7  &&
           rv.rf.regs[10] == 30 &&
           rv.rf.regs[11] == 3  &&
           rv.rf.regs[12] == 1  &&
           rv.rf.regs[13] == 3  &&
           rv.rf.regs[14] == 1  &&
           rv.rf.regs[15] == 0  &&
           rv.rf.regs[16] == 0  &&
           rv.rf.regs[21] == 32'hFFFFFFFF &&
           rv.rf.regs[22] == 10)
           $display("\nRESULT: ALL TESTS PASSED!");
       else
           $display("\nRESULT: SOME TESTS FAILED!");

        // =========================================================================
        // PERFORMANCE COUNTER ANALYSIS REPORT
        // =========================================================================
        begin : print_performance_report
            real overall_cpi;
            real branch_taken_rate;
            real stall_rate;
            real flush_rate;
            
            overall_cpi       = (rv.total_instr > 0) ? ($itor(rv.total_cycles) / $itor(rv.total_instr)) : 0.0;
            branch_taken_rate = (rv.cnt_branch > 0)  ? ($itor(rv.cnt_branch_taken) * 100.0 / $itor(rv.cnt_branch)) : 0.0;
            stall_rate        = ($itor(rv.cnt_load_use_stalls + rv.cnt_mul_div_stalls) * 100.0 / $itor(rv.total_cycles));
            flush_rate        = ($itor(rv.cnt_flush_cycles) * 100.0 / $itor(rv.total_cycles));

            $display("\n=======================================================");
            $display("             PROCESSOR PERFORMANCE REPORT              ");
            $display("=======================================================");
            $display("  [Core Metrics]");
            $display("    Total Clock Cycles       : %0d", rv.total_cycles);
            $display("    Instructions Retired     : %0d", rv.total_instr);
            $display("    Overall CPI              : %0.3f (Ideal = 1.000)", overall_cpi);
            $display("");
            $display("  [Instruction Mix]");
            $display("    ALU Instructions         : %0d (%0.2f%%)", rv.cnt_alu,     (rv.total_instr > 0) ? ($itor(rv.cnt_alu) * 100.0 / $itor(rv.total_instr)) : 0.0);
            $display("    Mul/Div Instructions     : %0d (%0.2f%%)", rv.cnt_mul_div, (rv.total_instr > 0) ? ($itor(rv.cnt_mul_div) * 100.0 / $itor(rv.total_instr)) : 0.0);
            $display("    Load Instructions        : %0d (%0.2f%%)", rv.cnt_load,    (rv.total_instr > 0) ? ($itor(rv.cnt_load) * 100.0 / $itor(rv.total_instr)) : 0.0);
            $display("    Store Instructions       : %0d (%0.2f%%)", rv.cnt_store,   (rv.total_instr > 0) ? ($itor(rv.cnt_store) * 100.0 / $itor(rv.total_instr)) : 0.0);
            $display("    Branch Instructions      : %0d (%0.2f%%)", rv.cnt_branch,  (rv.total_instr > 0) ? ($itor(rv.cnt_branch) * 100.0 / $itor(rv.total_instr)) : 0.0);
            $display("    Jump Instructions        : %0d (%0.2f%%)", rv.cnt_jump,    (rv.total_instr > 0) ? ($itor(rv.cnt_jump) * 100.0 / $itor(rv.total_instr)) : 0.0);
            $display("");
            $display("  [Branch Predictor Metrics (Static Not-Taken)]");
            $display("    Branches Taken (Mispred) : %0d (%0.2f%%)", rv.cnt_branch_taken, branch_taken_rate);
            $display("    Branches Not-Taken (Pred): %0d (%0.2f%%)", rv.cnt_branch_not_taken, 100.0 - branch_taken_rate);
            $display("");
            $display("  [Pipeline Stall & Overhead Analysis]");
            $display("    Load-Use Stall Cycles    : %0d (%0.2f%% of cycles)", rv.cnt_load_use_stalls, $itor(rv.cnt_load_use_stalls) * 100.0 / $itor(rv.total_cycles));
            $display("    Multiplier Stall Cycles  : %0d (%0.2f%% of cycles)", rv.cnt_mul_div_stalls,  $itor(rv.cnt_mul_div_stalls) * 100.0 / $itor(rv.total_cycles));
            $display("    Control Hazard Flushes   : %0d (%0.2f%% of cycles)", rv.cnt_flush_cycles,     $itor(rv.cnt_flush_cycles) * 100.0 / $itor(rv.total_cycles));
            $display("    Total Wasted Cycles      : %0d (%0.2f%% overhead)",  (rv.cnt_load_use_stalls + rv.cnt_mul_div_stalls + rv.cnt_flush_cycles), stall_rate + flush_rate);
            $display("=======================================================\n");
        end

        $finish;
    end
endmodule
