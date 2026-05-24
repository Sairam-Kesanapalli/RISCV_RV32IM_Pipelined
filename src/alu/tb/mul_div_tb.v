`timescale 1ps/1ps

module tb;
localparam WIDTH = 32;

reg clk, rst_n, start;
reg [2:0] md_op;
reg [WIDTH-1:0] A, B;
wire [WIDTH-1:0] Result;
wire busy, done;

mul_div #(.WIDTH(WIDTH)) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .md_op(md_op),
    .A(A),
    .B(B),
    .Result(Result),
    .busy(busy),
    .done(done)
);

// Clock Generation
always #5 clk = ~clk;

initial begin
    $dumpfile("mul_div.vcd");                  
    $dumpvars(0, tb);             
end



task check_mul_div(
    input [2:0] c_md_op,
    input [WIDTH-1:0] c_A,
    input [WIDTH-1:0] c_B,
    input [WIDTH-1:0] Expected_Result
);
    begin
        @(posedge clk);
        A <= c_A;
        B <= c_B;
        md_op <= c_md_op;
        start <= 1'b1;
        
        @(posedge clk);
        start <= 1'b0;
        
        // Wait until done asserts
        while (!done) begin
            @(posedge clk);
        end
        
        #1; // Delay 1ps to let Result fully settle after non-blocking assignment
        
        // Check result
        if (Result === Expected_Result) begin
            $display("[PASS] md_op=%0b: A=0x%h, B=0x%h -> got=0x%h", c_md_op, c_A, c_B, Result);
        end else begin
            $display("[FAIL] md_op=%0b: A=0x%h, B=0x%h -> expected=0x%h, got=0x%h", c_md_op, c_A, c_B, Expected_Result, Result);
        end
        
        // Wait a couple of cycles before next test
        repeat (2) @(posedge clk);
    end
endtask

initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    A = 0;
    B = 0;
    md_op = 0;
    
    #10;
    rst_n = 1;
    #10;
    
    // Test cases
    check_mul_div(3'b000, 32'd5,           32'd3,            32'd15);
    check_mul_div(3'b000, 32'd10,          32'd20,           32'd200);
    check_mul_div(3'b000, 32'hFFFFFFFF,    32'd2,            32'hFFFFFFFE);
    check_mul_div(3'b000, 32'hFFFFFFFD,    32'd4,            32'hFFFFFFF4);
    check_mul_div(3'b001, 32'h00010000,    32'h00010000,     32'd1);
    check_mul_div(3'b001, 32'hFFFFFFFF,    32'hFFFFFFFF,     32'd0);
    check_mul_div(3'b001, 32'h80000000,    32'd2,            32'hFFFFFFFF);
    check_mul_div(3'b010, 32'hFFFFFFFF,    32'd2,            32'hFFFFFFFF);
    check_mul_div(3'b010, 32'h80000000,    32'd2,            32'hFFFFFFFF);
    check_mul_div(3'b010, 32'd100000,      32'd100000,       32'd2);
    check_mul_div(3'b011, 32'hFFFFFFFF,    32'hFFFFFFFF,     32'hFFFFFFFE);
    check_mul_div(3'b011, 32'h80000000,    32'd2,            32'd1);
    check_mul_div(3'b011, 32'd65536,       32'd65536,        32'd1);
    check_mul_div(3'b100, 32'd10,          32'd2,            32'd5);
    check_mul_div(3'b100, 32'd7,           32'd3,            32'd2);
    check_mul_div(3'b100, 32'hFFFFFFF6,    32'd2,            32'hFFFFFFFB);
    check_mul_div(3'b100, 32'd10,          32'hFFFFFFFE,     32'hFFFFFFFB);
    check_mul_div(3'b100, 32'hFFFFFFF6,    32'hFFFFFFFE,     32'd5);
    check_mul_div(3'b100, 32'd10,          32'd0,            32'hFFFFFFFF);
    check_mul_div(3'b101, 32'd10,          32'd2,            32'd5);
    check_mul_div(3'b101, 32'hFFFFFFFF,    32'd2,            32'h7FFFFFFF);
    check_mul_div(3'b101, 32'd100,         32'd30,           32'd3);
    check_mul_div(3'b101, 32'd15,          32'd0,            32'hFFFFFFFF);
    check_mul_div(3'b110, 32'd10,          32'd3,            32'd1);
    check_mul_div(3'b110, 32'd20,          32'd6,            32'd2);
    check_mul_div(3'b110, 32'hFFFFFFF6,    32'd3,            32'hFFFFFFFF);
    check_mul_div(3'b110, 32'd10,          32'hFFFFFFFD,     32'd1);
    check_mul_div(3'b110, 32'd10,          32'd0,            32'd10);
    check_mul_div(3'b111, 32'd10,          32'd3,            32'd1);
    check_mul_div(3'b111, 32'd100,         32'd30,           32'd10);
    check_mul_div(3'b111, 32'hFFFFFFFF,    32'd2,            32'd1);
    check_mul_div(3'b111, 32'd15,          32'd0,            32'd15);
    
    $finish;
end

endmodule
