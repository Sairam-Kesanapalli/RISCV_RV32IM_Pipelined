module register_file #(
    parameter REG_DEPTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = $clog2(REG_DEPTH)  // HERE C IS CEILING (OPPOSITE TO STEP)
)(
    input clk,
    input rst_n,                // Reset is included for safe initialization.
                                // In industry, datapath registers may avoid reset for area/power optimization,
                                // but control logic and PC typically use reset.

    input reg_write,
    input [ADDR_WIDTH-1:0] rd,              // DESTINATION REGISTER FOR WRITING DATA
    input [DATA_WIDTH-1:0] write_data,

    input [ADDR_WIDTH-1:0] rs1,             // SOURCE REGISTER 1 FOR READING DATA
    input [ADDR_WIDTH-1:0] rs2,             // SOURCE REGISTER 2 FOR READING DATA

    output [DATA_WIDTH-1:0] read_data1,
    output [DATA_WIDTH-1:0] read_data2
);

        // REGISTER
        reg [DATA_WIDTH-1:0] regs [0:REG_DEPTH-1];

        // WRITE LOGIC
        always @(posedge clk) begin
            if(!rst_n) begin
                for(integer i =0; i<REG_DEPTH; i++)
                    regs[i] <= {DATA_WIDTH{1'b0}};
            end
            else begin
                if(reg_write && rd!=0)
                    regs[rd] <= write_data;
            end
        end

        // READ LOGIC
        assign read_data1 = (rs1 == 0)? {DATA_WIDTH{1'b0}}: regs[rs1];
        assign read_data2 = (rs2 == 0)? {DATA_WIDTH{1'b0}}: regs[rs2];

endmodule
