`timescale 1ns/1ps
module rv32i_tb;
reg clk;
reg rst_n;


rv32im_multi_cycle rv (
    .clk(clk),
    .rst_n(rst_n)
);

always #5 clk = ~clk;

    integer i;
    initial begin

       $dumpfile("RV32IM_verification.vcd");
       $dumpvars;
       for (i = 0; i < 32; i = i + 1) begin
           $dumpvars(0, rv32i_tb.rv.rf.regs[i]);
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
       $display("===== RV32I Base Checks =====");
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

        $finish;
    end
endmodule
