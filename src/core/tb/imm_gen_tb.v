`timescale 1ps/1ps

module imm_gen_tb;

reg [31:0] instr;
wire [31:0] imm_out;

imm_gen dut (
    .instr(instr),
    .imm_out(imm_out)
);

task check_imm_gen (
    input [31:0] test_instr,
    input [31:0] expected_imm_out
);
    begin
        instr = test_instr;
        #1;
        if (expected_imm_out == imm_out)
            $display("[PASS] instr=%h Got_imm=%h", test_instr, imm_out);
        else 
            $display("[FAIL] instr=%h Got_imm=%h Expected_imm=%h", instr, imm_out, expected_imm_out);
        #9;
    end
endtask

initial begin
    $dumpfile("imm_gen.vcd");                  
    $dumpvars();             
end

initial begin
    // ================= I-TYPE =================
    check_imm_gen(32'h00500093, 32'h00000005);   // addi x1,x0,5
    check_imm_gen(32'hFFF00093, 32'hFFFFFFFF);   // addi x1,x0,-1
    check_imm_gen(32'h80000093, 32'hFFFFF800);   // addi x1,x0,-2048
    check_imm_gen(32'h7FF00093, 32'h000007FF);   // addi x1,x0,2047

    // ================= LOAD (I-TYPE) =================
    check_imm_gen(32'h00412083, 32'h00000004);   // lw x1,4(x2)
    check_imm_gen(32'hFFC12083, 32'hFFFFFFFC);   // lw x1,-4(x2)

    // ================= S-TYPE =================
    check_imm_gen(32'h00512223, 32'h00000004);   // sw x5,4(x2)
    check_imm_gen(32'hFE512E23, 32'hFFFFFFFC);   // sw x5,-4(x2)
    check_imm_gen(32'h7E512FA3, 32'h000007FF);   // sw x5,2047(x2)
    check_imm_gen(32'h80512023, 32'hFFFFF800);   // sw x5,-2048(x2)

    // ================= B-TYPE =================
    check_imm_gen(32'h00208863, 32'h00000010);   // beq x1,x2,16
    check_imm_gen(32'hFE2088E3, 32'hFFFFFFF0);   // beq x1,x2,-16
    check_imm_gen(32'h7E208FE3, 32'h00000FFE);   // beq max positive offset
    check_imm_gen(32'h80208063, 32'hFFFFF000);   // beq large negative offset

    // ================= U-TYPE =================
    check_imm_gen(32'h123450B7, 32'h12345000);   // lui x1,0x12345
    check_imm_gen(32'hABCDE117, 32'hABCDE000);   // auipc x2,0xABCDE
    check_imm_gen(32'hFFFFF0B7, 32'hFFFFF000);   // lui upper negative
    check_imm_gen(32'h000000B7, 32'h00000000);   // lui zero

    // ================= J-TYPE =================
    check_imm_gen(32'h004000EF, 32'h00000004);   // jal x1,4
    check_imm_gen(32'hFFDFF0EF, 32'hFFFFFFFC);   // jal x1,-4
    check_imm_gen(32'h7FDFF0EF, 32'h000FFFFC);   // jal max positive
    check_imm_gen(32'h800000EF, 32'hFFF00000);   // jal large negative

    // ================= JALR =================
    check_imm_gen(32'h008100E7, 32'h00000008);   // jalr x1,8(x2)
    check_imm_gen(32'hFF8100E7, 32'hFFFFFFF8);   // jalr x1,-8(x2)

    // ================= DEFAULT =================
    check_imm_gen(32'h00000000, 32'h00000000);   // unknown opcode -> default
    $finish;
end

endmodule