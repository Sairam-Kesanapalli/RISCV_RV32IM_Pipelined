/*********************************************************************************
 * RV32I SINGLE-CYCLE PROCESSOR TOP MODULE
 * -------------------------------------------------------------------------------
 * This is the heart of the processor! It connects all the sub-modules together
 * to form a complete datapath. Because it is "single-cycle", every instruction
 * completely finishes in exactly one clock tick.
 *
 * HIGH-LEVEL DATAPATH FLOW:
 *
 *  [PC] ---> [Instruction Memory] ---> [Control Unit]
 *    |                 |                      |
 *    |                 v                      v
 *    |           [Registers] ---> [ALU] ---> [Data Memory]
 *    |                 |            |              |
 *    +-----------------+------------+--------------+---> Write Back to Registers
 *
 *********************************************************************************/
module rv32im_multi_cycle #(
    parameter XLEN = 32
)(
    input clk,
    input rst_n
);

    // =========================================================================
    // 1. INSTRUCTION FETCH (IF) & MULTI-CYCLE STATE REGISTERS
    // =========================================================================
    // The Program Counter (PC) holds the address of the current instruction.
    reg [XLEN-1:0] PC;
    wire [XLEN-1:0] PC_next;

    // Fetch the 32-bit instruction from memory using the PC.
    wire [XLEN-1:0] mem_instr;

    instruction_memory imem(
        .addr(PC),
        .instr(mem_instr)
    );

    // ---------------------------------------------------------
    // MULTI-CYCLE REGISTERS
    // ---------------------------------------------------------
    reg [XLEN-1:0] IR;      // Instruction Register
    reg [XLEN-1:0] MDR;     // Memory Data Register
    reg [XLEN-1:0] A;       // Register File Output 1
    reg [XLEN-1:0] B;       // Register File Output 2
    reg [XLEN-1:0] ALUOut;  // ALU Result Register

    // Pre-declare datapath wires used by state registers and control unit
    reg branch_taken;
    wire [XLEN-1:0] mem_data;
    wire [XLEN-1:0] read_data1;
    wire [XLEN-1:0] read_data2;
    wire [XLEN-1:0] alu_result;
    wire is_mul_div;
    wire [31:0] mul_div_result;

    // Control signals from FSM
    wire IRWrite;
    wire PCWrite;
    wire [1:0] ALUSrcA_ctrl;
    wire [1:0] ALUSrcB_ctrl;
    wire [1:0] PCSource_ctrl;

    always @(posedge clk) begin
        if (!rst_n) begin
            IR <= 32'b0;
            MDR <= 32'b0;
            A <= 32'b0;
            B <= 32'b0;
            ALUOut <= 32'b0;
        end else begin
            if (IRWrite) IR <= mem_instr;

            // Unconditionally update architectural state registers
            MDR <= mem_data;
            A <= read_data1;
            B <= read_data2;
            ALUOut <= (is_mul_div) ? mul_div_result : alu_result;
        end
    end

    // The Instruction Register (IR) holds the fetched instruction stable 
    // across all clock cycles of execution!
    wire [XLEN-1:0] instr = IR;

    // =========================================================================
    // 2. INSTRUCTION DECODE (ID) & CONTROL
    // =========================================================================
    // Slice the 32-bit instruction into its specific fields according to RISC-V.
    wire [6:0] opcode   = instr[6:0];
    wire [4:0] rd       = instr[11:7];      // Destination register
    wire [2:0] funct3   = instr[14:12];     // Function identifier (e.g., ADD vs SUB)
    wire [4:0] rs1      = instr[19:15];     // Source register 1
    wire [4:0] rs2      = instr[24:20];     // Source register 2
    wire [6:0] funct7   = instr[31:25];     // Secondary function identifier

    // The Control Unit acts as the "brain". It looks at the opcode and turns on
    // the correct signals to steer data through the datapath multiplexers.
    wire RegWrite, MemRead, MemWrite, MemToReg, Branch, Jump;
    wire [2:0] ALU_OP;
    wire busy;
    wire done;
    wire start;

    control_unit cu(
        .clk(clk),
        .rst_n(rst_n),
        .op_code(opcode),
        .branch_taken(branch_taken),
        .alu_done(~is_mul_div | done),
        .is_busy(busy),
        .PCWrite(PCWrite),
        .IRWrite(IRWrite),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .Jump(Jump),
        .ALUSrcA_ctrl(ALUSrcA_ctrl),
        .ALUSrcB_ctrl(ALUSrcB_ctrl),
        .PCSource_ctrl(PCSource_ctrl),
        .MemToReg(MemToReg),
        .ALU_OP(ALU_OP)
    );

    // =========================================================================
    // 3. REGISTER FILE & IMMEDIATE GENERATION
    // =========================================================================
    wire [XLEN-1:0] write_data;

    // Read values from rs1 and rs2. If the instruction writes back, it saves to rd.
    register_file rf(
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(RegWrite),
        .rd(rd),
        .write_data(write_data),
        .rs1(rs1),
        .rs2(rs2),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Extract and sign-extend the immediate value hidden inside the instruction.
    wire [XLEN-1:0] imm_out;
    imm_gen ig (
        .instr(instr),
        .imm_out(imm_out)
    );

    // =========================================================================
    // 4. EXECUTE (ALU)
    // =========================================================================
    // The ALU Control translates the generic ALU_OP from the main Control Unit
    // and the instruction's funct3/funct7 into a specific 4-bit ALU command.
    wire [2:0] md_op;   //Uses funct3
    wire [3:0] alu_op;
    alu_control ac(
        .ALU_OP(ALU_OP),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_op),
        .is_mul_div(is_mul_div),
        .md_op(md_op)
    );

    wire [XLEN-1:0] alu_input_b;
    wire [XLEN-1:0] alu_input_a;
    wire zero_flag, carry_out, negative, overflow;

    assign start = is_mul_div;

    mul_div md(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .md_op(md_op),
        .A(alu_input_a),
        .B(alu_input_b),
        .Result(mul_div_result),
        .busy(busy),
        .done(done)
    );

    // ---------------------------------------------------------
    // MULTI-CYCLE MUX: ALUSrcA
    // ---------------------------------------------------------
    // We define a 2-bit control signal (will eventually be generated by the FSM).
    // 2'b00 -> PC (For Fetching, Jumps, Branches)
    // 2'b01 -> A Register (For Arithmetic, Memory Addresses)
    // 2'b10 -> 0 (For LUI instruction)

    assign alu_input_a =
            (ALUSrcA_ctrl == 2'b00) ? PC :
            (ALUSrcA_ctrl == 2'b01) ? A :
            (ALUSrcA_ctrl == 2'b10) ? 32'b0 :
            A;

    // ---------------------------------------------------------
    // MULTI-CYCLE MUX: ALUSrcB
    // ---------------------------------------------------------
    // We define a 2-bit control signal (will eventually be generated by the FSM).
    // 2'b00 -> B Register (For R-Type instructions)
    // 2'b01 -> Constant 4 (For PC + 4 during Fetch stage)
    // 2'b10 -> Immediate (For I-Type, S-Type, Jumps, and Branches)

    assign alu_input_b =
            (ALUSrcB_ctrl == 2'b00) ? B :
            (ALUSrcB_ctrl == 2'b01) ? 32'd4 :
            (ALUSrcB_ctrl == 2'b10) ? imm_out :
            32'b0;

    // The main mathematical brain. It computes addresses, arithmetic, and branch conditions!
    ALU_n_bit #(
        .WIDTH(32)
    ) alu (
        .op_code(alu_op),
        .a(alu_input_a),
        .b(alu_input_b),
        .c_in(1'b0),
        .answer(alu_result),
        .c_out(carry_out),
        .zero(zero_flag),
        .negative(negative),
        .overflow(overflow)
    );

    // =========================================================================
    // 5. MEMORY ACCESS (MEM) & WRITE-BACK (WB)
    // =========================================================================

    // Memory module for Load/Store operations.
    // E.g., [SW x8, 4(x2)] => Memory[x2 + 4] = x8
    data_mem dm(
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .write_data(B),         // Use latched B register instead of combinational read_data2
        .addr(ALUOut),          // Address comes from ALU calculation in previous cycle
        .read_data(mem_data)
    );

    // Write-Back MUX: Multi-Cycle Design
    // We now write back from our saved State Registers instead of raw combinational outputs!
    assign write_data = (MemToReg)? MDR : ALUOut;

    // =========================================================================
    // 6. PC UPDATE (BRANCHING & JUMPING LOGIC)
    // =========================================================================
    
    always @(*) begin
        // Evaluate the branch condition based on the ALU flags.
        case(funct3)
            3'b000 : branch_taken = zero_flag;                      // BEQ
            3'b001 : branch_taken = ~zero_flag;                     // BNE
            3'b100 : branch_taken = negative ^ overflow;            // BLT  (Signed)
            3'b101 : branch_taken = ~(negative ^ overflow);         // BGE  (Signed)
            3'b110 : branch_taken = ~carry_out;                     // BLTU (Unsigned)
            3'b111 : branch_taken = carry_out;                      // BGEU (Unsigned)
            default: branch_taken = 0;
        endcase
    end

    // ---------------------------------------------------------
    // MULTI-CYCLE MUX: PCSource
    // ---------------------------------------------------------
    // The dedicated adders for PC+4 and Branches are gone! The ALU does it all.
    // 2'b00 -> alu_result (Used during Fetch to write PC+4 directly from the ALU)
    // 2'b01 -> ALUOut (Used for Jumps/Branches to write target calculated in previous cycle)
    // 2'b10 -> alu_result with LSB set to 0 (Specifically for JALR)

    assign PC_next =
            (PCSource_ctrl == 2'b00) ? alu_result :
            (PCSource_ctrl == 2'b01) ? ALUOut :
            (PCSource_ctrl == 2'b10) ? (alu_result & 32'hFFFFFFFE) : // JALR masking
            alu_result;

    // Update the PC sequentially on every clock edge, ONLY if PCWrite is enabled by FSM.
    always @(posedge clk) begin
        if(!rst_n)
            PC <= 0;
        else if (PCWrite)
            PC <= PC_next;
    end

endmodule
