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
    // =========================================================================
    // MEMORY ADDRESSING AND SUB-WORD ACCESSES (LB / LBU / LH / LHU / SB / SH)
    // =========================================================================
    //
    // Conceptual Layout:
    // ------------------
    // * 1 Byte = 8 bits
    // * 1 Halfword = 16 bits = 2 Bytes
    // * 1 Word = 32 bits = 4 Bytes
    //
    // The processor uses byte-addressing, meaning each unique address points to a 
    // single 8-bit byte. However, the physical memory array is organized as 32-bit 
    // words (`reg [31:0] memory [0:255]`).
    //
    // Word Alignment:
    // ---------------
    // To index this 32-bit array, we use `addr[ADDR_WIDTH+1:2]`.
    // Shifting the byte address right by 2 (dividing by 4) gives us the word-aligned 
    // index in physical memory (e.g., byte addresses 0, 1, 2, and 3 all map to word 0).
    //
    // How Sub-Word Writes (SB, SH, SW) are implemented:
    // -------------------------------------------------
    // We utilize a 4-bit byte-enable input (`byte_en[3:0]`). During the Execute (EX) 
    // stage of the processor, the byte-enable bits are generated based on the lower 
    // two address bits `addr[1:0]` and the instruction width (`funct3`):
    //   - SB (Store Byte): `byte_en` has exactly 1 bit active (e.g., `4'b0001 << addr[1:0]`).
    //   - SH (Store Halfword): `byte_en` has 2 adjacent bits active (e.g., `4'b0011 << {addr[1], 1'b0}`).
    //   - SW (Store Word): All 4 bits of `byte_en` are active (`4'b1111`).
    //
    // On the active clock edge, only the bytes with active `byte_en` bits are modified.
    //
    // How Sub-Word Reads (LB, LBU, LH, LHU, LW) are implemented:
    // ---------------------------------------------------------
    // 1. The data memory performs a combinational read of the entire 32-bit word 
    //    at the word-aligned index: `read_data = memory[addr[ADDR_WIDTH+1:2]]`.
    // 2. In the Memory (MEM) stage of the processor (`rv32im_pipelined.v`), the 
    //    unaligned 32-bit word is received. The processor uses the lower two bits of 
    //    the address (`ex_mem_alu_result[1:0]`) and the instruction type (`funct3`) 
    //    to extract, align, and sign/zero-extend the requested byte or halfword 
    //    into `aligned_read_data`.

endmodule

