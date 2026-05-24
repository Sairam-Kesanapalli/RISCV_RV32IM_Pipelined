`timescale 1ps/1ps

module ALU_n_bit_tb;
localparam WIDTH = 32;
reg [3:0] op_code;
reg [WIDTH-1:0] a, b;
reg c_in;
wire [WIDTH-1:0] answer;
wire c_out, zero, negative, overflow;

ALU_n_bit #(.WIDTH(WIDTH)) dut (
    .op_code(op_code),
    .a(a),
    .b(b),
    .c_in(c_in),
    .answer(answer),
    .c_out(c_out),
    .zero(zero),
    .negative(negative),
    .overflow(overflow)
);

initial begin
    $dumpfile("wave.vcd");                  
    $dumpvars(0, ALU_n_bit_tb);             
end

// Task to run a single check
task check_alu(
    input [3:0] op,
    input [WIDTH-1:0] val_a,
    input [WIDTH-1:0] val_b,
    input cin,
    input [WIDTH-1:0] expected
);
    begin
        op_code = op;
        a = val_a;
        b = val_b;
        c_in = cin;
        #1; // Wait 1ps for combinational logic to settle
        if (answer === expected) begin
            $display("[PASS] op=%0d: a=0x%h, b=0x%h -> got=0x%h", op, val_a, val_b, answer);
        end else begin
            $display("[FAIL] op=%0d: a=0x%h, b=0x%h -> expected=0x%h, got=0x%h", op, val_a, val_b, expected, answer);
        end
        #9; // Finish the 10ps step
    end
endtask

initial begin
    #10;
    
    // Test cases
    check_alu(0,  5,                3,              0, 8);
    check_alu(0,  32'hFFFFFFFF,     1,              0, 0);
    check_alu(0,  32'h7FFFFFFF,     1,              0, 32'h80000000);
    check_alu(1,  9,                4,              0, 5);
    check_alu(1,  3,                5,              0, 32'hFFFFFFFE);
    check_alu(1,  32'h80000000,     1,              0, 32'h7FFFFFFF);
    check_alu(2,  10,               0,              0, 11);
    check_alu(2,  32'hFFFFFFFF,     0,              0, 0);
    check_alu(3,  10,               0,              0, 9);
    check_alu(3,  0,                0,              0, 32'hFFFFFFFF);
    check_alu(4,  32'hF0F0F0F0,     32'h0FF00FF0,   0, 32'h00F000F0);
    check_alu(4,  32'hAAAAAAAA,     32'h55555555,   0, 0);
    check_alu(5,  32'hF0F0F0F0,     32'h0FF00FF0,   0, 32'hFFF0FFF0);
    check_alu(5,  32'h00000000,     32'hFFFFFFFF,   0, 32'hFFFFFFFF);
    check_alu(6,  32'hAAAA5555,     32'hFFFF0000,   0, 32'h55555555);
    check_alu(6,  32'hFFFFFFFF,     32'hFFFFFFFF,   0, 0);
    check_alu(7,  32'hFFFF0000,     0,              0, 32'h0000FFFF);
    check_alu(7,  0,                0,              0, 32'hFFFFFFFF);
    check_alu(8,  1,                4,              0, 16);
    check_alu(8,  32'h00000003,     8,              0, 32'h00000300);
    check_alu(9,  32'h00000020,     2,              0, 8);
    check_alu(9,  32'h80000000,     31,             0, 1);
    check_alu(10, 32'hFFFFFFF0,     2,              0, 32'hFFFFFFFC);
    check_alu(10, 32'h80000000,     1,              0, 32'hC0000000);
    check_alu(11, 32'hFFFFFFFF,     1,              0, 1);
    check_alu(11, 5,                2,              0, 0);

    $finish;
end

endmodule
