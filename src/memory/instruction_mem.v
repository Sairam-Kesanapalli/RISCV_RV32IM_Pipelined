module instruction_memory #(
    parameter XLEN = 32,
    parameter DEPTH = 256,
    parameter INIT_FILE = ""
)(
    input [XLEN-1:0] addr,
    output [31:0] instr
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    // INSTRUCTION MEMORY (EACH INSTRUCTION = 32 BITS)
    reg [XLEN-1:0] instr_memory [0:DEPTH-1];


    initial begin
        // ---- Clean RV32IM Test Program ----
        // Phase 1: Setup registers with ADDI
        instr_memory[0]  = 32'h00a00093;  // ADDI x1,  x0, 10    => x1  = 10
        instr_memory[1]  = 32'h00300113;  // ADDI x2,  x0, 3     => x2  = 3
        instr_memory[2]  = 32'h00700193;  // ADDI x3,  x0, 7     => x3  = 7
        instr_memory[3]  = 32'hfff00213;  // ADDI x4,  x0, -1    => x4  = -1 (0xFFFFFFFF)
        instr_memory[4]  = 32'h00000293;  // ADDI x5,  x0, 0     => x5  = 0

        // Phase 2: R-Type (base RV32I) sanity check
        instr_memory[5]  = 32'h002081b3;  // ADD  x3,  x1, x2    => x3  = 10 + 3 = 13
        instr_memory[6]  = 32'h40208233;  // SUB  x4,  x1, x2    => x4  = 10 - 3 = 7

        // Phase 3: M-Extension instructions
        // MUL  x10, x1, x2  => x10 = 10 * 3 = 30
        instr_memory[7]  = {7'b0000001, 5'd2, 5'd1, 3'b000, 5'd10, 7'b0110011};
        // DIV  x11, x1, x2  => x11 = 10 / 3 = 3
        instr_memory[8]  = {7'b0000001, 5'd2, 5'd1, 3'b100, 5'd11, 7'b0110011};
        // REM  x12, x1, x2  => x12 = 10 % 3 = 1
        instr_memory[9]  = {7'b0000001, 5'd2, 5'd1, 3'b110, 5'd12, 7'b0110011};
        // DIVU x13, x1, x2  => x13 = 10 / 3 = 3 (unsigned)
        instr_memory[10] = {7'b0000001, 5'd2, 5'd1, 3'b101, 5'd13, 7'b0110011};
        // REMU x14, x1, x2  => x14 = 10 % 3 = 1 (unsigned)
        instr_memory[11] = {7'b0000001, 5'd2, 5'd1, 3'b111, 5'd14, 7'b0110011};
        // MULH x15, x1, x2  => x15 = upper32(10 * 3) = 0
        instr_memory[12] = {7'b0000001, 5'd2, 5'd1, 3'b001, 5'd15, 7'b0110011};
        // MULHU x16, x1, x2 => x16 = upper32(10 * 3) = 0 (unsigned)
        instr_memory[13] = {7'b0000001, 5'd2, 5'd1, 3'b011, 5'd16, 7'b0110011};

        // Phase 4: Division by zero edge case
        // ADDI x20, x0, 0   => x20 = 0
        instr_memory[14] = 32'h00000a13;
        // DIV  x21, x1, x20 => x21 = 10 / 0 = -1 (0xFFFFFFFF per RISC-V spec)
        instr_memory[15] = {7'b0000001, 5'd20, 5'd1, 3'b100, 5'd21, 7'b0110011};
        // REM  x22, x1, x20 => x22 = 10 % 0 = 10 (dividend, per RISC-V spec)
        instr_memory[16] = {7'b0000001, 5'd20, 5'd1, 3'b110, 5'd22, 7'b0110011};

        // NOP padding (ADDI x0, x0, 0) to let pipeline drain
        instr_memory[17] = 32'h00000013;
        instr_memory[18] = 32'h00000013;

        // ---- Regression Framework Overlay ----
        // If +TEST_DIR is provided, overwrite the hardcoded instructions above
        // with the specific regression test's program.hex
        begin : load_test
            reg [8191:0] test_dir; // 1024 bytes string
            integer i;
            if ($value$plusargs("TEST_DIR=%s", test_dir)) begin
                for (i = 0; i < DEPTH; i = i + 1) begin
                    instr_memory[i] = 32'hx;
                end
                $readmemh({test_dir, "/program.hex"}, instr_memory);
            end else if (INIT_FILE != "") begin
                for (i = 0; i < DEPTH; i = i + 1) begin
                    instr_memory[i] = 32'hx;
                end
                $readmemh(INIT_FILE, instr_memory);
            end
        end
    end

    assign instr = instr_memory[addr[ADDR_WIDTH+1:2]];

endmodule
