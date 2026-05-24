`timescale 1ps/1ps

module control_unit_tb;

reg [6:0] op_code;
wire [1:0] ALUSrcA_ctrl;
wire [1:0] ALUSrcB_ctrl;
wire [2:0] ALU_OP;
wire MemRead;
wire MemWrite;
wire Branch;
wire Jump;
wire RegWrite;
wire MemToReg;

control_unit cu (
    .ALUSrcA_ctrl(ALUSrcA_ctrl),
    .ALUSrcB_ctrl(ALUSrcB_ctrl),
    .ALU_OP(ALU_OP),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .Branch(Branch),
    .Jump(Jump),
    .RegWrite(RegWrite),
    .MemToReg(MemToReg),
    .op_code(op_code)
);

// Task to verify a specific opcode
task check_control_unit(
    input [6:0] test_op,
    input [1:0] exp_ALUSrcA_ctrl,
    input [1:0] exp_ALUSrcB_ctrl,
    input [2:0] exp_ALU_OP,
    input exp_MemRead,
    input exp_MemWrite,
    input exp_Branch,
    input exp_Jump,
    input exp_RegWrite,
    input exp_MemToReg
);
    begin
        op_code = test_op;
        #1; // Wait 1ps for combinational logic to settle
        if (
            (ALUSrcA_ctrl === exp_ALUSrcA_ctrl) &&
            (ALUSrcB_ctrl === exp_ALUSrcB_ctrl) &&
            (ALU_OP === exp_ALU_OP) &&
            (MemRead === exp_MemRead) &&
            (MemWrite === exp_MemWrite) &&
            (Branch === exp_Branch) &&
            (Jump === exp_Jump) &&
            (RegWrite === exp_RegWrite) &&
            (MemToReg === exp_MemToReg)
        ) begin
            $display("[PASS] op_code=7'b%07b matches expected signals", test_op);
        end else begin
            $display("[FAIL] op_code=7'b%07b mismatch!", test_op);
            $display("       ALUSrcA:  exp=%b, got=%b", exp_ALUSrcA_ctrl, ALUSrcA_ctrl);
            $display("       ALUSrcB:  exp=%b, got=%b", exp_ALUSrcB_ctrl, ALUSrcB_ctrl);
            $display("       ALU_OP:   exp=%d, got=%d", exp_ALU_OP, ALU_OP);
            $display("       MemRead:  exp=%b, got=%b", exp_MemRead, MemRead);
            $display("       MemWrite: exp=%b, got=%b", exp_MemWrite, MemWrite);
            $display("       Branch:   exp=%b, got=%b", exp_Branch, Branch);
            $display("       Jump:     exp=%b, got=%b", exp_Jump, Jump);
            $display("       RegWrite: exp=%b, got=%b", exp_RegWrite, RegWrite);
            $display("       MemToReg: exp=%b, got=%b", exp_MemToReg, MemToReg);
        end
        #9;
    end
endtask

initial begin
    $dumpfile("control_unit.vcd");                  
    $dumpvars();             
end


initial begin
    #10;
    
    // R-type / MUL
    check_control_unit(7'b0110011, 2'b01, 2'b00, 3'd2, 0, 0, 0, 0, 1, 0);
    
    // I-type
    check_control_unit(7'b0010011, 2'b01, 2'b10, 3'd0, 0, 0, 0, 0, 1, 0);
    
    // LW (Load)
    check_control_unit(7'b0000011, 2'b01, 2'b10, 3'd3, 1, 0, 0, 0, 1, 1);
    
    // SW (Store)
    check_control_unit(7'b0100011, 2'b01, 2'b10, 3'd3, 0, 1, 0, 0, 0, 0);
    
    // BEQ (Branch)
    check_control_unit(7'b1100011, 2'b01, 2'b00, 3'd1, 0, 0, 1, 0, 0, 0);
    
    // JAL
    check_control_unit(7'b1101111, 2'b00, 2'b01, 3'd3, 0, 0, 0, 1, 1, 0);
    
    // JALR
    check_control_unit(7'b1100111, 2'b00, 2'b01, 3'd3, 0, 0, 0, 1, 1, 0);
    
    // LUI
    check_control_unit(7'b0110111, 2'b10, 2'b10, 3'd3, 0, 0, 0, 0, 1, 0);
    
    // AUIPC
    check_control_unit(7'b0010111, 2'b00, 2'b10, 3'd3, 0, 0, 0, 0, 1, 0);
    
    // Default / Unknown opcode
    check_control_unit(7'b0000000, 2'b00, 2'b00, 3'd0, 0, 0, 0, 0, 0, 0);
    
    $finish;
end

endmodule
