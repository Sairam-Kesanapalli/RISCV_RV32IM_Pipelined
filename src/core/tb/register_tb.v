`timescale 1ps/1ps

module register_tb;

reg clk;
reg rst_n;
reg reg_write;
reg [4:0] rd;
reg [31:0] write_data;
reg [4:0] rs1;
reg [4:0] rs2;
wire [31:0] read_data1;
wire [31:0] read_data2;

// Instantiated as register_file (matches register.v)
register_file rf (
    .clk(clk),
    .rst_n(rst_n),
    .reg_write(reg_write),
    .rd(rd),
    .write_data(write_data),
    .rs1(rs1),
    .rs2(rs2),
    .read_data1(read_data1),
    .read_data2(read_data2)
);

task check_register(
    input test_reg_write,
    input [4:0] test_rd,              
    input [31:0] test_write_data,
    input [4:0] test_rs1,             
    input [4:0] test_rs2,             
    input [31:0] expected_read_data1,
    input [31:0] expected_read_data2
);
begin
    @(posedge clk);
    reg_write <= test_reg_write;
    rd <= test_rd;
    write_data <= test_write_data;
    rs1 <= test_rs1;
    rs2 <= test_rs2;
    
    @(posedge clk);
    #1; // Delay 1ps to let reads settle in simulation
    if ((expected_read_data1 === read_data1) && (expected_read_data2 === read_data2)) begin
        $display("[PASS] wr=%b rd=%0d dat=0x%h rs1=%0d rs2=%0d -> got1=0x%h got2=0x%h", 
                 test_reg_write, test_rd, test_write_data, test_rs1, test_rs2, read_data1, read_data2);
    end else begin 
        $display("[FAIL] wr=%b rd=%0d dat=0x%h rs1=%0d rs2=%0d", 
                 test_reg_write, test_rd, test_write_data, test_rs1, test_rs2);
        $display("       Expected: data1=0x%h, data2=0x%h", expected_read_data1, expected_read_data2);
        $display("       Got:      data1=0x%h, data2=0x%h", read_data1, read_data2);
    end
    #9;
end
endtask

always #5 clk = ~clk;

initial begin
    $dumpfile("register.vcd");                  
    $dumpvars(0, register_tb);             
end

initial begin
    clk = 0;
    rst_n = 0;
    reg_write = 0;
    rd = 0;
    write_data = 0;
    rs1 = 0;
    rs2 = 0;
    
    #10;
    rst_n = 1;
    #10;
    
    // =========================================================================
    // 1. STANDARD WRITE & READ (No Bypass)
    // =========================================================================
    // Write 0x5555AAAA to x2 (needed for standard read case later)
    check_register(1, 5'd2, 32'h5555AAAA, 5'd0, 5'd0, 32'h00000000, 32'h00000000);
    
    // Read x2 in next cycle (reg_write is disabled, verifying array storage)
    check_register(0, 5'd0, 32'h00000000, 5'd2, 5'd0, 32'h5555AAAA, 32'h00000000);

    // =========================================================================
    // 2. USER TEST CASES (Bypassing / Forwarding & Hardwired x0 checks)
    // =========================================================================
    
    // Case 1: rs1 and rd same (forwarding on rs1 port)
    check_register(1, 5'd3, 32'hAAAA5555, 5'd3, 5'd0, 32'hAAAA5555, 32'h00000000);

    // Case 2: rs2 and rd same (forwarding on rs2 port)
    check_register(1, 5'd7, 32'h12345678, 5'd0, 5'd7, 32'h00000000, 32'h12345678);

    // Case 3: using rs1 and rs2 while calling rd
    check_register(1, 5'd10, 32'hCAFEBABE, 5'd10, 5'd10, 32'hCAFEBABE, 32'hCAFEBABE);

    // Case 4: read and write at same time (forwarding rs1, standard reading rs2)
    check_register(1, 5'd15, 32'hDEADBEEF, 5'd15, 5'd2, 32'hDEADBEEF, 32'h5555AAAA);

    // Case 5: writing to x0 after that reading x0
    check_register(1, 5'd0, 32'hFFFFFFFF, 5'd0, 5'd0, 32'h00000000, 32'h00000000);

    // =========================================================================
    // 3. ADDITIONAL EDGE CASES
    // =========================================================================
    
    // Case 6: Write Disable Test (reg_write = 0, verifying write-enable acts correctly)
    check_register(0, 5'd5, 32'h99999999, 5'd5, 5'd0, 32'h00000000, 32'h00000000);
    
    // Case 7: Reset Verification (Pulse reset, confirm values are cleared)
    @(posedge clk);
    rst_n <= 0;
    @(posedge clk);
    rst_n <= 1;
    check_register(0, 5'd0, 32'h00000000, 5'd2, 5'd3, 32'h00000000, 32'h00000000);

    $finish;
end

endmodule