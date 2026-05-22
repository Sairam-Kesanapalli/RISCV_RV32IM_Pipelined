module test_lw_sw;
    reg clk;
    reg rst_n;
    rv32i_multi_cycle rv (
        .clk(clk),
        .rst_n(rst_n)
    );
    initial begin
        clk = 0;
        rst_n = 0;
        rv.imem.instr_memory[0] = 32'h00a00093; // ADDI x1, x0, 10
        rv.imem.instr_memory[1] = 32'h01002023; // SW x1, 16(x0)
        rv.imem.instr_memory[2] = 32'h01002103; // LW x2, 16(x0)
        #15 rst_n = 1;
        #60;
        $display("x1 = %d", rv.rf.regs[1]);
        $display("x2 = %d", rv.rf.regs[2]);
        $display("mem[0] = %d", rv.dm.memory[0]);
        $display("mem[4] = %d", rv.dm.memory[4]);
        $display("PC = %d", rv.PC);
        $finish;
    end
    always #5 clk = ~clk;
endmodule
