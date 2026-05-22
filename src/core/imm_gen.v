/*********************************************************************************
 * IMMEDIATE GENERATOR
 * -------------------------------------------------------------------------------
 * Instructions only have 32 bits. If we want to use a constant number (like
 * `addi x1, x0, -5`), that `-5` is squished into the instruction itself.
 *
 * But the ALU needs a full 32-bit number to do math! This module extracts that
 * squished number and "sign-extends" it to 32 bits.
 *********************************************************************************/
module imm_gen #(
    parameter XLEN = 32
)(
    input [31:0] instr,
    output reg [XLEN-1:0] imm_out
);
    // The lowest 7 bits tell us what type of instruction we have.
    wire [6:0] op_code = instr[6:0];

    always @(*) begin
        case(op_code)
            // =====================================================================
            // I-TYPE (e.g., ADDI, LW)
            // =====================================================================
            // The immediate is stored in the top 12 bits of the instruction.
            // We duplicate the sign bit (instr[31]) to fill the upper 20 bits.
            7'b0010011,     // ADDI
            7'b0000011:     // LW
                imm_out = {{(XLEN-12){instr[31]}}, instr[31:20]};

            // =====================================================================
            // S-TYPE (e.g., SW)
            // =====================================================================
            // Stores are tricky! The immediate is split into two pieces because
            // the `rs2` register field took up the middle bits. We glue the pieces
            // back together here.
            // Example: SW x5, 8(x1)  -> Address = x1 + 8
            7'b0100011:
                imm_out = {{(XLEN-12){instr[31]}}, instr[31:25], instr[11:7]};

            // =====================================================================
            // B-TYPE (Branches like BEQ, BNE)
            // =====================================================================
            // Similar to S-type, but the bits are scrambled slightly differently,
            // and the lowest bit is forced to 0 (because instructions are 2-byte aligned).
            7'b1100011:
                imm_out = {
                            {{(XLEN-13){instr[31]}}},
                            instr[31],
                            instr[7],
                            instr[30:25],
                            instr[11:8],
                            1'b0
                          };

            // =====================================================================
            // U-TYPE (LUI, AUIPC)
            // =====================================================================
            // These load a 20-bit immediate into the *upper* 20 bits of the register.
            // The lower 12 bits are filled with zeros.
            7'b0110111,     // LUI
            7'b0010111:     // AUIPC
                imm_out = {
                            instr[31:12],
                            12'b0
                          };

            // =====================================================================
            // J-TYPE (Jumps)
            // =====================================================================
            // JAL uses a massive 20-bit immediate to jump far away! Scrambled
            // similar to branches, with a forced 0 at the LSB.
            7'b1101111:     // JAL
                imm_out = {
                            {{(XLEN-21){instr[31]}}},
                            instr[31],
                            instr[19:12],
                            instr[20],
                            instr[30:21],
                            1'b0
                          };

            7'b1100111:
                imm_out = {
                            {{(XLEN-12){instr[31]}}},
                            instr[31:20]
                            };

            default:
                imm_out = {XLEN{1'b0}};
        endcase
    end
endmodule
