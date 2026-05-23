/*********************************************************************************
 * PIPELINED CONTROL UNIT
 * -------------------------------------------------------------------------------
 * This generates single-cycle control signals for the decoded instructions
 * in the ID stage, which are then propagated through the pipeline registers
 * to control downstream execution stages.
 *********************************************************************************/
module control_unit (

    //Execute signals
    output reg [1:0] ALUSrcA_ctrl,
    output reg [1:0] ALUSrcB_ctrl,
    output reg [2:0] ALU_OP,

    //Memory signals
    output reg MemRead,
    output reg MemWrite,
    output reg Branch,
    output reg Jump,

    //Write-back signals
    output reg RegWrite,
    output reg MemToReg,

    input [6:0] op_code

    // input branch_taken,
    // input is_busy, // New input to indicate if the ALU is still processing
    // input alu_done, // New input to indicate ALU has finished processing

    // output reg PCWrite,
    // output reg IRWrite,
    // output reg [1:0] PCSource_ctrl,

);



    // =========================================================================
    // OUTPUT CONTROL LOGIC
    // =========================================================================
    always @(*) begin
        // PCSource_ctrl = 2'b00;
        // PCWrite       = 0;
        // IRWrite       = 0;

        //initializing all the default values to 0 to prevent latch interference
        ALUSrcA_ctrl = 2'b00; // A
        ALUSrcB_ctrl = 2'b00; // B
        ALU_OP       = 3'd0;  
        MemRead      = 0;
        MemWrite     = 0;
        Branch       = 0;
        Jump         = 0;
        RegWrite     = 0;
        MemToReg     = 0;

        case(op_code)
            7'b0110011:begin                                     // R-type or MUL 
                // ALUOut = A op B
                ALUSrcA_ctrl = 2'b01; // A
                ALUSrcB_ctrl = 2'b00; // B
                ALU_OP       = 3'd2;  // R-Type or M-Type
                MemRead      = 0;
                MemWrite     = 0;
                Branch       = 0;
                Jump         = 0;
                RegWrite     = 1;
                MemToReg     = 0;
            end
            7'b0010011:begin                                     // I-type
                // ALUOut = A op imm
                ALUSrcA_ctrl = 2'b01; // A
                ALUSrcB_ctrl = 2'b10; // imm
                ALU_OP       = 3'd0;  // I-Type
                MemRead      = 0;
                MemWrite     = 0;
                Branch       = 0;
                Jump         = 0;
                RegWrite     = 1;
                MemToReg     = 0;
            end
            7'b0000011:begin                 
                // ALUOut = A + imm (Address calculation)        // LW
                ALUSrcA_ctrl = 2'b01; // A
                ALUSrcB_ctrl = 2'b10; // imm
                ALU_OP       = 3'd3;  // ADD                    
                MemRead      = 1;
                MemWrite     = 0;   
                Branch       = 0;
                Jump         = 0;
                RegWrite     = 1;
                MemToReg     = 1;
            end
            7'b0100011:begin                                     // SW
                // ALUOut = A + imm (Address calculation)
                ALUSrcA_ctrl = 2'b01; // A
                ALUSrcB_ctrl = 2'b10; // imm
                ALU_OP       = 3'd3;  // ADD
                MemRead      = 0;
                MemWrite     = 1;
                Branch       = 0;
                Jump         = 0;
                RegWrite     = 0;
                MemToReg     = 0;
            end
            7'b1100011:begin                                    // B-type (BEQ) 
                // Compute A - B to set flags
                ALUSrcA_ctrl = 2'b01; // A
                ALUSrcB_ctrl = 2'b00; // B
                ALU_OP       = 3'd1;  // SUB for Branch
                MemRead      = 0;
                MemWrite     = 0;   
                Branch       = 1;    // Control signal to indicate this is a branch instruction
                Jump         = 0;
                RegWrite     = 0;
                MemToReg     = 0;
            end
            7'b1101111:begin                                       // JAL
                // PC = PC + imm (using ALU), Reg = PC+4 (from ALUOut)
                ALUSrcA_ctrl = 2'b00; // PC
                ALUSrcB_ctrl = 2'b01; // 4
                ALU_OP       = 3'd3;  // ADD 
                MemRead      = 0;
                MemWrite     = 0;
                Branch       = 0;
                Jump         = 1;
                RegWrite     = 1;
                MemToReg     = 0;     
            end
            7'b1100111:begin                                        // JALR
                // PC = (A + imm) & ~1, Reg = PC+4 (from ALUOut)
                ALUSrcA_ctrl = 2'b00; // PC
                ALUSrcB_ctrl = 2'b01; // 4
                ALU_OP       = 3'd3;  // ADD
                MemRead      = 0;
                MemWrite     = 0;
                Branch       = 0;
                Jump         = 1;
                RegWrite     = 1;
                MemToReg     = 0;
            end   

            7'b0110111: begin           // U-TYPE => LUI
                // LUI Optimization: Compute 0 + imm early in DECODE!
                ALUSrcA_ctrl = 2'b10; // 0
                ALUSrcB_ctrl = 2'b10; // imm
                ALU_OP       = 3'd3;  // ADD
                RegWrite     = 1;
                MemRead      = 0;
                MemWrite     = 0;
                MemToReg     = 0;
                Branch       = 0;
                Jump         = 0;
                ALU_OP       = 3'd3;
            end
            7'b0010111: begin           // U-TYPE => AUIPC
                // AUIPC, Branches, Memory: Compute target early! ALUOut = PC + imm
                ALUSrcA_ctrl = 2'b00; // PC
                ALUSrcB_ctrl = 2'b10; // imm
                ALU_OP       = 3'd3;  // ADD
                RegWrite     = 1;
                MemRead      = 0;
                MemWrite     = 0;
                MemToReg     = 0;
                Branch       = 0;
                Jump         = 0;
                ALU_OP       = 3'd3;
            end
            default: begin
                ALUSrcA_ctrl = 2'b00; // A
                ALUSrcB_ctrl = 2'b00; // B
                ALU_OP       = 3'd0;  
                MemRead      = 0;
                MemWrite     = 0;
                Branch       = 0;
                Jump         = 0;
                RegWrite     = 0;
                MemToReg     = 0;
            end
        endcase
    end
endmodule

