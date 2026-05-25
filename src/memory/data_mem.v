module data_mem #(
    parameter XLEN = 32,
    parameter DEPTH = 256
    )(
        input clk,
        input MemRead,
        input MemWrite,
        input [XLEN-1:0] write_data,
        input [XLEN-1:0] addr,
        input [3:0] byte_en,
        output reg [XLEN-1:0] read_data
    );
    // BITS FOR ADDRESSING
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // MEMORY DECLARATION
    reg [XLEN-1:0] memory [0:DEPTH-1];

    // Zero-initialize data memory for simulation and ISA model alignment
    initial begin
        for (integer i = 0; i < DEPTH; i = i + 1) begin
            memory[i] = {XLEN{1'b0}};
        end
    end

    // SYNCHRONOUS WRITE
    always @(posedge clk) begin
        if(MemWrite) begin
            if (byte_en[0]) memory[addr[ADDR_WIDTH+1:2]][7:0]   <= write_data[7:0];
            if (byte_en[1]) memory[addr[ADDR_WIDTH+1:2]][15:8]  <= write_data[15:8];
            if (byte_en[2]) memory[addr[ADDR_WIDTH+1:2]][23:16] <= write_data[23:16];
            if (byte_en[3]) memory[addr[ADDR_WIDTH+1:2]][31:24] <= write_data[31:24];
        end
    end

    // COMBINATIONAL READ
    always @(*) begin
        if(MemRead)
            read_data = memory[addr[ADDR_WIDTH+1:2]];
        else
            read_data = {XLEN{1'b0}};
    end

                            // NOTE
    // 1 Byte = 8 bits
    // 1 Word = 32 Bits = 4 Bytes
    // Each Address points to 1 Byte
    // Addr 1000 is Byte 0
    //      1001 => Byte 1
    //      1002 => Byte 2
    //      1003 => Byte 3
    // Index = addr / 4
    // We use addr[31:2] because we currently support only word-aligned accesses (LW/SW).
    // Each memory entry is 32 bits (4 bytes), so we divide byte address by 4.
    // The lower 2 bits (addr[1:0]) are ignored since they are always 00 for word alignment.
    //
    // NOTE:
    // If we implement LB (Load Byte) or LH (Load Halfword),
    // we cannot ignore addr[1:0] anymore.
    // Those bits are required to select the correct byte or halfword inside the 32-bit word.

endmodule
