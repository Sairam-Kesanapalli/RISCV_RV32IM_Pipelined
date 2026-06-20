`timescale 1ns/1ps
`define VERIFICATION

module svt_tb;
    reg clk;
    reg rst_n;

    // Processor Instantiation
    rv32im_pipelined #(
        .INIT_FILE("regression_tests/Svt_custom_tests/program.hex")
    ) rv (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Expected Values Arrays
    reg [31:0] expected_regs [0:31];
    reg [31:0] expected_mem  [0:15];
    reg [31:0] expected_pc   [0:0];

    // Clock Generation
    always #5 clk = ~clk;

    integer i;
    integer errors;
    integer rtl_trace_file;
    reg [63:0] sim_cycle;

    initial begin
        rtl_trace_file = $fopen("rtl_trace.log", "w");
        sim_cycle = 0;
        $dumpfile("SVT_verification.vcd");
        $dumpvars(0, svt_tb);
        
        // ---- Regression Framework Overlay ----
        begin : load_expected
            reg [8191:0] test_dir; // 1024 bytes string
            if (!$value$plusargs("TEST_DIR=%s", test_dir)) begin
                test_dir = "regression_tests/Svt_custom_tests"; // Default custom tests directory
            end
            $readmemh({test_dir, "/expected_regs.hex"}, expected_regs);
            $readmemh({test_dir, "/expected_mem.hex"}, expected_mem);
            $readmemh({test_dir, "/expected_pc.hex"}, expected_pc);
        end

        errors = 0;
        clk = 0;
        rst_n = 0;
        
        #10;
        rst_n = 1;
        
        // Wait sufficient time for pipelined execution
        // Under ideal conditions, CPI ≈ 1. With stalls and iterative mul/div (32 cycles each), #15000 is safe.
        #15000;  // Increased for iterative mul/div (32 cycles each)
        
        $display("\n=======================================================");
        $display("          SOFTWARE VERIFICATION TESTBENCH (SVT)          ");
        $display("=======================================================\n");

        // Check PC
        if (rv.PC !== expected_pc[0]) begin
            $display("[FAIL] PC Mismatch! Expected: %08x, Actual: %08x", expected_pc[0], rv.PC);
            errors = errors + 1;
        end else begin
            $display("[PASS] PC matches: %08x", rv.PC);
        end

        // Check Registers
        $display("\n--- Register Checks ---");
        for (i = 0; i < 32; i = i + 1) begin
            if (rv.rf.regs[i] !== expected_regs[i]) begin
                $display("[FAIL] Reg x%0d Mismatch! Expected: %08x, Actual: %08x", i, expected_regs[i], rv.rf.regs[i]);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("[PASS] All 32 Registers match expected values!");

        // Check Memory (First 16 words)
        $display("\n--- Memory Checks ---");
        for (i = 0; i < 16; i = i + 1) begin
            if (expected_mem[i] === 32'hxxxxxxxx && rv.dm.memory[i] === 32'hxxxxxxxx) begin
                // Both uninitialized — skip
            end else if (rv.dm.memory[i] !== expected_mem[i]) begin
                $display("[FAIL] Mem[%0d] Mismatch! Expected: %08x, Actual: %08x", i, expected_mem[i], rv.dm.memory[i]);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("[PASS] Memory entries match expected values!");

        $display("\n=======================================================");
        if (errors == 0) begin
            $display("                    [SVT PASS]                         ");
        end else begin
            $display("         [SVT FAIL] - Found %0d mismatches!            ", errors);
        end
        $display("=======================================================\n");

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

        // Dump final register signature
        begin : dump_signature
            integer sig_file;
            integer idx;
            sig_file = $fopen("rtl.signature", "w");
            for (idx = 0; idx < 32; idx = idx + 1) begin
                $fdisplay(sig_file, "x%0d: 0x%08h", idx, rv.rf.regs[idx]);
            end
            $fclose(sig_file);
            $fclose(rtl_trace_file); // Close execution trace file too
        end

        $finish;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            sim_cycle <= sim_cycle + 1;
            
            // Log retired instruction details at Write-Back (WB) stage
            if (rv.mem_wb_valid) begin
                $fdisplay(rtl_trace_file, "CYCLE: %0d", sim_cycle);
                $fdisplay(rtl_trace_file, "  ALWAYS: pc=0x%08h instr=0x%08h rd_addr=x%0d rd_wdata=0x%08h rf_wen=%0b pc_next=0x%08h",
                    rv.mem_wb_pc, rv.mem_wb_instr, rv.mem_wb_rd, rv.wb_write_data, rv.mem_wb_RegWrite, rv.mem_wb_pc_next);
                
                if (rv.mem_wb_is_branch || rv.mem_wb_is_jump) begin
                    $fdisplay(rtl_trace_file, "  BRANCH/JUMP: taken=%0b target=0x%08h",
                        rv.mem_wb_is_jump ? 1'b1 : rv.mem_wb_branch_taken, rv.mem_wb_pc_next);
                end
                
                if (rv.mem_wb_is_load) begin
                    $fdisplay(rtl_trace_file, "  LOAD: addr=0x%08h rdata=0x%08h rmask=0x%01h",
                        rv.mem_wb_alu_result, rv.mem_wb_read_data, rv.mem_wb_funct3);
                end
                
                if (rv.mem_wb_is_store) begin
                    $fdisplay(rtl_trace_file, "  STORE: addr=0x%08h wdata=0x%08h wmask=4'b%04b",
                        rv.mem_wb_alu_result, rv.mem_wb_write_data_in, rv.mem_wb_byte_en);
                end
                
                if (rv.mem_wb_is_mul_div) begin
                    $fdisplay(rtl_trace_file, "  MUL/DIV: result=0x%08h", rv.mem_wb_alu_result);
                end

                $fdisplay(rtl_trace_file, "  OPTIONAL: rs1_addr=x%0d rs1_rdata=0x%08h rs2_addr=x%0d rs2_rdata=0x%08h",
                    rv.mem_wb_rs1, rv.mem_wb_rs1_data, rv.mem_wb_rs2, rv.mem_wb_rs2_data);
                
                $fdisplay(rtl_trace_file, ""); // New line separator
            end
        end
    end
endmodule
